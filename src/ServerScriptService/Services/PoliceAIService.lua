--!strict

local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local Services = script.Parent
local RoundService = require(Services:WaitForChild("RoundService"))

type UnitRecord = {
	model: Model,
	root: BasePart,
	humanoid: Humanoid,
	role: string,
	spawnCFrame: CFrame,
	state: Enums.PoliceAIState,
	target: Player?,
	lastSeenAt: number,
	lastSeenPosition: Vector3?,
	searchStartedAt: number,
	searchIndex: number,
	pathGoal: Vector3?,
	pathWaypoints: { PathWaypoint },
	waypointIndex: number,
	nextPathAt: number,
	visible: boolean,
}

local PoliceAIService = {}
local units: { UnitRecord } = {}
local running = false
local blackboardRemote: RemoteEvent
local updateThread: thread?

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end
	local existing = remotes:FindFirstChild(GameConfig.Remotes.PoliceAIAlert)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.PoliceAIAlert
	remote.Parent = remotes
	return remote
end

local function getMapFolder(name: string): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	local primary = model.PrimaryPart
	return if primary and primary:IsA("BasePart") then primary else nil
end

local function setVisible(unit: UnitRecord, value: boolean)
	unit.visible = value
	unit.model:SetAttribute("Deployed", value)
	for _, instance in unit.model:GetDescendants() do
		if instance:IsA("BasePart") then
			if instance ~= unit.root then
				instance.Transparency = if value then 0 else 1
			end
			instance.CanCollide = value
		elseif instance:IsA("BillboardGui") then
			instance.Enabled = value
		end
	end
	unit.root.Transparency = 1
	unit.root.CanCollide = false
	unit.humanoid.AutoRotate = value
	end

local function setState(unit: UnitRecord, state: Enums.PoliceAIState)
	if unit.state == state then
		return
	end
	unit.state = state
	unit.model:SetAttribute("PoliceAIState", state)
	local tag = unit.model:FindFirstChild("StateTag", true)
	if tag and tag:IsA("TextLabel") then
		tag.Text = unit.role .. " | " .. state
	end
	print(string.format("[PoliceAIService] %s -> %s", unit.model.Name, state))
	blackboardRemote:FireAllClients({ Unit = unit.model.Name, Role = unit.role, State = state })
end

local function getNearestSpawn(unit: UnitRecord): Vector3
	local spawns = getMapFolder("PoliceSpawns")
	if spawns then
		local spawn = spawns:FindFirstChild(unit.model.Name)
		if spawn and spawn:IsA("BasePart") then
			return spawn.Position
		end
		local roleSpawn = spawns:FindFirstChild(unit.role)
		if roleSpawn and roleSpawn:IsA("BasePart") then
			return roleSpawn.Position
		end
	end
	return unit.spawnCFrame.Position
end

local function canSee(unit: UnitRecord, player: Player): boolean
	local character = player.Character
	local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not targetRoot or not targetRoot:IsA("BasePart") then
		return false
	end
	local offset = targetRoot.Position - unit.root.Position
	local distance = offset.Magnitude
	if distance > GameConfig.Police.VisionRange or distance < 0.01 then
		return false
	end
	local direction = offset.Unit
	local facing = unit.root.CFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(facing:Dot(direction), -1, 1)))
	if angle > GameConfig.Police.VisionAngle / 2 then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { unit.model, getMapFolder("AreaMarkers") }
	local result = workspace:Raycast(unit.root.Position + Vector3.new(0, 2, 0), offset, params)
	return result == nil or result.Instance:IsDescendantOf(character)
end

local function setBlackboard(player: Player, position: Vector3)
	Blackwood:SetAttribute("PoliceLastKnownPlayer", player.Name)
	Blackwood:SetAttribute("PoliceLastKnownPosition", position)
	Blackwood:SetAttribute("PoliceLastKnownTime", os.clock())
	Blackwood:SetAttribute("PoliceAlertLevel", "High")
	end

local function getPlayerPosition(player: Player): Vector3?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

local function getTargetPlayers(): { Player }
	local result = {}
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("RoundBusted") ~= true
			and player:GetAttribute("RoundEscaped") ~= true
			and getPlayerPosition(player) then
			table.insert(result, player)
		end
	end
	return result
end

local function targetLoad(target: Player): number
	local inventory = target:GetAttribute("InventoryWeight")
	return if typeof(inventory) == "number" then inventory else 0
end

local function chooseTarget(unit: UnitRecord): Player?
	local candidates = getTargetPlayers()
	local assigned: { [Player]: number } = {}
	for _, other in units do
		if other.target then
			assigned[other.target] = (assigned[other.target] or 0) + 1
		end
	end
	table.sort(candidates, function(a, b)
		local aLoad = assigned[a] or 0
		local bLoad = assigned[b] or 0
		if aLoad ~= bLoad then
			return aLoad < bLoad
		end
		return targetLoad(a) > targetLoad(b)
	end)
	for _, player in candidates do
		local count = assigned[player] or 0
		if unit.role == "Interceptor" or count < 2 then
			return player
		end
	end
	return candidates[1]
end

local function computePath(unit: UnitRecord, goal: Vector3): boolean
	if os.clock() < unit.nextPathAt and unit.pathGoal then
		return true
	end
	unit.nextPathAt = os.clock() + 0.7
	unit.pathGoal = goal
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 5 })
	local ok = pcall(function()
		path:ComputeAsync(unit.root.Position, goal)
	end)
	if not ok or path.Status ~= Enum.PathStatus.Success then
		unit.pathWaypoints = {}
		unit.waypointIndex = 0
		return false
	end
	unit.pathWaypoints = path:GetWaypoints()
	unit.waypointIndex = 2
	return #unit.pathWaypoints >= 2
end

local function moveTo(unit: UnitRecord, goal: Vector3, speed: number)
	unit.humanoid.WalkSpeed = speed
	if not computePath(unit, goal) then
		unit.humanoid:MoveTo(goal)
		return
	end
	local waypoint = unit.pathWaypoints[unit.waypointIndex]
	if waypoint then
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			unit.humanoid.Jump = true
		end
		if (unit.root.Position - waypoint.Position).Magnitude <= GameConfig.Police.ArrivalDistance then
			unit.waypointIndex += 1
			waypoint = unit.pathWaypoints[unit.waypointIndex]
		end
		if waypoint then
			unit.humanoid:MoveTo(waypoint.Position)
		end
	end
end

local function searchPoint(unit: UnitRecord): Vector3
	local center = unit.lastSeenPosition or getNearestSpawn(unit)
	local index = unit.searchIndex % 8
	local angle = (math.pi * 2 / 8) * index
	return center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * GameConfig.Police.SearchRadius
	end

local function updateUnit(unit: UnitRecord, now: number)
	if not unit.visible then
		return
	end
	local players = getTargetPlayers()
	local visibleTarget: Player? = nil
	for _, player in players do
		if canSee(unit, player) then
			visibleTarget = player
			break
		end
	end
	if visibleTarget then
		unit.target = visibleTarget
		unit.lastSeenAt = now
		unit.lastSeenPosition = getPlayerPosition(visibleTarget)
		if unit.lastSeenPosition then
			setBlackboard(visibleTarget, unit.lastSeenPosition)
		end
		if unit.role == "Interceptor" then
			setState(unit, Enums.PoliceAIState.Intercept)
		else
			setState(unit, Enums.PoliceAIState.Chase)
		end
	end

	if unit.state == Enums.PoliceAIState.Deploy then
		moveTo(unit, getNearestSpawn(unit), GameConfig.Police.PatrolSpeed)
		if (unit.root.Position - getNearestSpawn(unit)).Magnitude <= GameConfig.Police.ArrivalDistance then
			setState(unit, Enums.PoliceAIState.Idle)
		end
	elseif unit.state == Enums.PoliceAIState.Idle then
		if not unit.target then
			unit.target = chooseTarget(unit)
		end
	elseif unit.state == Enums.PoliceAIState.Chase then
		local target = unit.target
		local position = target and getPlayerPosition(target)
		if target and position and canSee(unit, target) then
			unit.lastSeenPosition = position
			unit.lastSeenAt = now
			setBlackboard(target, position)
			moveTo(unit, position, GameConfig.Police.ChaseSpeed)
		elseif now - unit.lastSeenAt > GameConfig.Police.LoseSightTime then
			setState(unit, Enums.PoliceAIState.Investigate)
		end
	elseif unit.state == Enums.PoliceAIState.Intercept then
		local target = unit.target
		local position = target and getPlayerPosition(target)
		if target and position and canSee(unit, target) then
			local character = target.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local velocity = if root and root:IsA("BasePart") then root.AssemblyLinearVelocity else Vector3.zero
			moveTo(unit, position + velocity * GameConfig.Police.InterceptLeadTime, GameConfig.Police.InterceptSpeed)
		elseif now - unit.lastSeenAt > GameConfig.Police.LoseSightTime then
			setState(unit, Enums.PoliceAIState.Block)
		end
	elseif unit.state == Enums.PoliceAIState.Investigate then
		if unit.lastSeenPosition then
			moveTo(unit, unit.lastSeenPosition, GameConfig.Police.SearchSpeed)
			if (unit.root.Position - unit.lastSeenPosition).Magnitude <= GameConfig.Police.ArrivalDistance then
				unit.searchStartedAt = now
				unit.searchIndex = 0
				setState(unit, Enums.PoliceAIState.Search)
			end
		else
			setState(unit, Enums.PoliceAIState.Return)
		end
	elseif unit.state == Enums.PoliceAIState.Search then
		if now - unit.searchStartedAt >= GameConfig.Police.SearchDuration then
			unit.target = nil
			setState(unit, Enums.PoliceAIState.Return)
		else
			local goal = searchPoint(unit)
			moveTo(unit, goal, GameConfig.Police.SearchSpeed)
			if (unit.root.Position - goal).Magnitude <= GameConfig.Police.ArrivalDistance then
				unit.searchIndex += 1
			end
		end
	elseif unit.state == Enums.PoliceAIState.Block then
		local block = getMapFolder("PoliceRoutes")
		local route = block and block:FindFirstChild("PoliceGardenRoute")
		local point = route and route:FindFirstChildWhichIsA("BasePart")
		moveTo(unit, if point then point.Position else getNearestSpawn(unit), GameConfig.Police.InterceptSpeed)
		if unit.target == nil then
			setState(unit, Enums.PoliceAIState.Return)
		end
	elseif unit.state == Enums.PoliceAIState.Return then
		moveTo(unit, getNearestSpawn(unit), GameConfig.Police.PatrolSpeed)
		if (unit.root.Position - getNearestSpawn(unit)).Magnitude <= GameConfig.Police.ArrivalDistance then
			setState(unit, Enums.PoliceAIState.Idle)
		end
	end

	if unit.target and now - unit.lastSeenAt > GameConfig.Police.LoseSightTime and (unit.state == Enums.PoliceAIState.Chase or unit.state == Enums.PoliceAIState.Intercept) then
		setState(unit, if unit.state == Enums.PoliceAIState.Chase then Enums.PoliceAIState.Investigate else Enums.PoliceAIState.Block)
	end
end

local function hideAll()
	for _, unit in units do
		unit.target = nil
		unit.lastSeenPosition = nil
		unit.pathWaypoints = {}
		setState(unit, Enums.PoliceAIState.Idle)
		setVisible(unit, false)
		unit.root.CFrame = unit.spawnCFrame
	end
	Blackwood:SetAttribute("PoliceAlertLevel", "Off")
end

local function deployAll()
	Blackwood:SetAttribute("PoliceAlertLevel", "High")
	for _, unit in units do
		setVisible(unit, true)
		unit.root.CFrame = unit.spawnCFrame
		unit.target = chooseTarget(unit)
		unit.lastSeenAt = os.clock()
		setState(unit, Enums.PoliceAIState.Deploy)
	end
end

local function bindUnits()
	local folder = getMapFolder("PoliceUnits")
	if not folder then
		warn("[PoliceAIService] PoliceUnits folder not found.")
		return
	end
	local count = 0
	for _, child in folder:GetChildren() do
		if count >= GameConfig.Police.MaxUnits then
			break
		end
		if child:IsA("Model") then
			local root = getRoot(child)
			local humanoid = child:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				local role = child:GetAttribute("Role")
				local resolvedRole = if typeof(role) == "string" then role else "PatrolOfficer"
				local record: UnitRecord = {
					model = child,
					root = root,
					humanoid = humanoid,
					role = resolvedRole,
					spawnCFrame = root.CFrame,
					state = Enums.PoliceAIState.Idle,
					target = nil,
					lastSeenAt = 0,
					lastSeenPosition = nil,
					searchStartedAt = 0,
					searchIndex = 0,
					pathGoal = nil,
					pathWaypoints = {},
					waypointIndex = 0,
					nextPathAt = 0,
					visible = false,
				}
				table.insert(units, record)
				child:SetAttribute("PoliceAIState", Enums.PoliceAIState.Idle)
				child:SetAttribute("PoliceRole", resolvedRole)
				setVisible(record, false)
				count += 1
			end
		end
	end
	print(string.format("[PoliceAIService] Bound %d police units.", count))
end

local function onRoundStateChanged()
	local state = RoundService.GetState()
	if state == Enums.RoundState.PoliceResponse then
		deployAll()
	elseif state == Enums.RoundState.Escape then
		for _, unit in units do
			if unit.state == Enums.PoliceAIState.Idle then
				unit.target = chooseTarget(unit)
				setState(unit, Enums.PoliceAIState.Chase)
			end
		end
	elseif state == Enums.RoundState.Lobby or state == Enums.RoundState.Completed or state == Enums.RoundState.Failed then
		hideAll()
	end
end

function PoliceAIService.Start()
	if running then
		return
	end
	running = true
	blackboardRemote = getOrCreateRemote()
	bindUnits()
	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(onRoundStateChanged)
	onRoundStateChanged()
	updateThread = task.spawn(function()
		while running do
			if RoundService.GetState() == Enums.RoundState.PoliceResponse or RoundService.GetState() == Enums.RoundState.Escape then
				local now = os.clock()
				for _, unit in units do
					updateUnit(unit, now)
				end
			end
			task.wait(GameConfig.Police.UpdateInterval)
		end
	end)
	print("[PoliceAIService] Patrol Officer, Searcher and Interceptor AI ready.")
end

return PoliceAIService
