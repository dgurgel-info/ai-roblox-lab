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
local SecurityService = require(Services:WaitForChild("SecurityService"))

type GuardRecord = {
	Model: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	HomePosition: Vector3,
	RouteNodes: { BasePart },
	PatrolIndex: number,
	State: Enums.GuardState,
	Target: Player?,
	LastKnownPosition: Vector3?,
	LastSeenAt: number,
	InvestigatePosition: Vector3?,
	StateStartedAt: number,
	Recognition: { [Player]: number },
	Path: { PathWaypoint },
	PathIndex: number,
	PathGoal: Vector3?,
	PathComputedAt: number,
	SearchIndex: number,
}

local GuardService = {}
local guards: { GuardRecord } = {}
local guardAlert: RemoteEvent
local running = false

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end
	local existing = remotes:FindFirstChild(GameConfig.Remotes.GuardAlert)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.GuardAlert
	remote.Parent = remotes
	return remote
end

local function getEstateFolder(name: string): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function getNodes(routeName: string): { BasePart }
	local paths = getEstateFolder("GuardPaths")
	local route = paths and paths:FindFirstChild(routeName)
	local nodes: { BasePart } = {}
	if route and route:IsA("Folder") then
		for _, child in route:GetChildren() do
			if child:IsA("BasePart") then
				table.insert(nodes, child)
			end
		end
		table.sort(nodes, function(a, b)
			return (a:GetAttribute("PathIndex") or 0) < (b:GetAttribute("PathIndex") or 0)
		end)
	end
	return nodes
end

local function setState(guard: GuardRecord, state: Enums.GuardState)
	if guard.State == state then
		return
	end
	guard.State = state
	guard.StateStartedAt = os.clock()
	guard.Path = {}
	guard.PathIndex = 0
	guard.PathGoal = nil
	guard.Model:SetAttribute("GuardState", state)
	local tag = guard.Model:FindFirstChild("StateTag", true)
	local label = tag and tag:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = state:upper()
	end
	guardAlert:FireAllClients({ Guard = guard.Model.Name, State = state })
	print(string.format("[GuardService] %s -> %s", guard.Model.Name, state))
end

local function getPlayerRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function canSee(guard: GuardRecord, player: Player): boolean
	local root = getPlayerRoot(player)
	local character = player.Character
	if not root or not character or player:GetAttribute("Hidden") == true then
		return false
	end

	local offset = root.Position + Vector3.new(0, 1.2, 0) - guard.Root.Position
	local distance = offset.Magnitude
	if distance > GameConfig.Guards.VisionRange then
		return false
	end
	local dot = math.clamp(guard.Root.CFrame.LookVector:Dot(offset.Unit), -1, 1)
	if math.deg(math.acos(dot)) > GameConfig.Guards.VisionAngle / 2 then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { guard.Model }
	params.IgnoreWater = true
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local markers = estate and estate:FindFirstChild("AreaMarkers")
	if markers then
		params:AddToFilter(markers)
	end
	local result = workspace:Raycast(guard.Root.Position, offset, params)
	return result == nil or result.Instance:IsDescendantOf(character)
end

local function nearestVisiblePlayer(guard: GuardRecord): (Player?, number)
	local selected: Player? = nil
	local selectedDistance = math.huge
	for _, player in Players:GetPlayers() do
		if canSee(guard, player) then
			local root = getPlayerRoot(player)
			local distance = root and (root.Position - guard.Root.Position).Magnitude or math.huge
			if distance < selectedDistance then
				selected = player
				selectedDistance = distance
			end
		end
	end
	return selected, selectedDistance
end

local function computePath(guard: GuardRecord, goal: Vector3): boolean
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = false,
		WaypointSpacing = 4,
	})
	local success = pcall(function()
		path:ComputeAsync(guard.Root.Position, goal)
	end)
	if not success or path.Status ~= Enum.PathStatus.Success then
		guard.Path = {}
		guard.PathIndex = 0
		return false
	end
	guard.Path = path:GetWaypoints()
	guard.PathIndex = 1
	guard.PathGoal = goal
	guard.PathComputedAt = os.clock()
	return true
end

local function moveTo(guard: GuardRecord, goal: Vector3)
	local changedGoal = not guard.PathGoal or (guard.PathGoal - goal).Magnitude > 4
	local stale = os.clock() - guard.PathComputedAt > 2
	if changedGoal or stale or guard.PathIndex == 0 then
		if not computePath(guard, goal) then
			guard.Humanoid:MoveTo(guard.Root.Position)
			return
		end
	end

	local waypoint = guard.Path[guard.PathIndex]
	if not waypoint then
		guard.Path = {}
		guard.PathIndex = 0
		return
	end
	if (guard.Root.Position - waypoint.Position).Magnitude <= GameConfig.Guards.ArrivalDistance then
		guard.PathIndex += 1
		waypoint = guard.Path[guard.PathIndex]
	end
	if waypoint then
		guard.Humanoid:MoveTo(waypoint.Position)
	end
end

local function searchPosition(guard: GuardRecord): Vector3
	local origin = guard.LastKnownPosition or guard.HomePosition
	local radius = GameConfig.Guards.SearchRadius
	local offsets = {
		Vector3.new(radius, 0, 0),
		Vector3.new(0, 0, radius),
		Vector3.new(-radius, 0, 0),
		Vector3.new(0, 0, -radius),
	}
	return origin + offsets[(guard.SearchIndex % #offsets) + 1]
end

local function stepGuard(guard: GuardRecord)
	if not guard.Model.Parent or guard.Humanoid.Health <= 0 then
		return
	end

	local visiblePlayer, distance = nearestVisiblePlayer(guard)
	if visiblePlayer and guard.State ~= Enums.GuardState.Chase then
		guard.Target = visiblePlayer
		guard.LastKnownPosition = getPlayerRoot(visiblePlayer) and getPlayerRoot(visiblePlayer).Position or guard.Root.Position
		setState(guard, Enums.GuardState.Chase)
		SecurityService.AddSecurity(1, "Guard:" .. guard.Model.Name)
	elseif visiblePlayer and guard.State == Enums.GuardState.Chase then
		guard.Target = visiblePlayer
		guard.LastKnownPosition = getPlayerRoot(visiblePlayer) and getPlayerRoot(visiblePlayer).Position or guard.LastKnownPosition
		guard.LastSeenAt = os.clock()
	end

	if guard.State == Enums.GuardState.Patrol then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		local node = guard.RouteNodes[guard.PatrolIndex]
		if not node then
			setState(guard, Enums.GuardState.Idle)
			return
		end
		if (guard.Root.Position - node.Position).Magnitude <= GameConfig.Guards.ArrivalDistance then
			guard.PatrolIndex = guard.PatrolIndex % #guard.RouteNodes + 1
		end
		moveTo(guard, node.Position)
	elseif guard.State == Enums.GuardState.Idle then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		if os.clock() - guard.StateStartedAt >= 1 then
			guard.PatrolIndex = math.max(1, guard.PatrolIndex)
			setState(guard, Enums.GuardState.Patrol)
		end
	elseif guard.State == Enums.GuardState.Suspicious then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		if guard.InvestigatePosition then
			moveTo(guard, guard.InvestigatePosition)
		end
		if os.clock() - guard.StateStartedAt >= GameConfig.Guards.SuspiciousDuration then
			setState(guard, Enums.GuardState.Investigate)
		end
	elseif guard.State == Enums.GuardState.Investigate then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		if guard.InvestigatePosition then
			moveTo(guard, guard.InvestigatePosition)
		end
		if os.clock() - guard.StateStartedAt >= GameConfig.Guards.InvestigateTimeout
			or (guard.InvestigatePosition and (guard.Root.Position - guard.InvestigatePosition).Magnitude <= GameConfig.Guards.ArrivalDistance) then
			guard.SearchIndex = 0
			setState(guard, Enums.GuardState.Search)
		end
	elseif guard.State == Enums.GuardState.Search then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		if os.clock() - guard.StateStartedAt >= GameConfig.Guards.SearchDuration then
			guard.Target = nil
			setState(guard, Enums.GuardState.ReturnToPost)
		else
			local destination = searchPosition(guard)
			moveTo(guard, destination)
			if (guard.Root.Position - destination).Magnitude <= GameConfig.Guards.ArrivalDistance then
				guard.SearchIndex += 1
			end
		end
	elseif guard.State == Enums.GuardState.Chase then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.ChaseSpeed
		if guard.Target and canSee(guard, guard.Target) then
			guard.LastSeenAt = os.clock()
			local root = getPlayerRoot(guard.Target)
			if root then
				guard.LastKnownPosition = root.Position
				moveTo(guard, root.Position)
			end
		elseif os.clock() - guard.LastSeenAt >= GameConfig.Guards.LoseSightTime then
			guard.InvestigatePosition = guard.LastKnownPosition or guard.HomePosition
			setState(guard, Enums.GuardState.Investigate)
		end
	elseif guard.State == Enums.GuardState.ReturnToPost then
		guard.Humanoid.WalkSpeed = GameConfig.Guards.PatrolSpeed
		moveTo(guard, guard.HomePosition)
		if (guard.Root.Position - guard.HomePosition).Magnitude <= GameConfig.Guards.ArrivalDistance then
			guard.PatrolIndex = 1
			setState(guard, Enums.GuardState.Patrol)
		end
	end
	if distance == math.huge then
		guard.Model:SetAttribute("GuardTarget", "")
	elseif visiblePlayer then
		guard.Model:SetAttribute("GuardTarget", visiblePlayer.Name)
	end
end

function GuardService.EmitNoise(position: Vector3, radius: number, source: string)
	for _, guard in guards do
		if (guard.Root.Position - position).Magnitude <= radius and guard.State ~= Enums.GuardState.Chase then
			guard.InvestigatePosition = position
			setState(guard, Enums.GuardState.Suspicious)
		end
	end
	guardAlert:FireAllClients({ Type = "Noise", Source = source, Position = position })
	print(string.format("[GuardService] Noise heard: %s", source))
end

local function bindGuard(model: Model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or not root:IsA("BasePart") then
		warn(string.format("[GuardService] Invalid guard model: %s", model:GetFullName()))
		return
	end
	local routeName = model:GetAttribute("RouteName") or ""
	local nodes = getNodes(routeName)
	local guard: GuardRecord = {
		Model = model,
		Humanoid = humanoid,
		Root = root,
		HomePosition = root.Position,
		RouteNodes = nodes,
		PatrolIndex = 1,
		State = Enums.GuardState.Idle,
		Target = nil,
		LastKnownPosition = nil,
		LastSeenAt = 0,
		InvestigatePosition = nil,
		StateStartedAt = os.clock(),
		Recognition = {},
		Path = {},
		PathIndex = 0,
		PathGoal = nil,
		PathComputedAt = 0,
		SearchIndex = 0,
	}
	model:SetAttribute("GuardState", guard.State)
	model:SetAttribute("GuardTarget", "")
	table.insert(guards, guard)
	setState(guard, if #nodes > 0 then Enums.GuardState.Patrol else Enums.GuardState.Idle)
end

function GuardService.Start()
	if running then
		return
	end
	running = true
	guardAlert = getOrCreateRemote()
	local folder = getEstateFolder("Guards")
	if not folder then
		warn("[GuardService] Guards folder not found.")
		return
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			bindGuard(child)
		end
	end
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			bindGuard(child)
		end
	end)
	task.spawn(function()
		while running do
			local state = RoundService.GetState()
			if state == Enums.RoundState.Infiltration or state == Enums.RoundState.Heist then
				for _, guard in guards do
					stepGuard(guard)
				end
			end
			task.wait(GameConfig.Guards.UpdateInterval)
		end
	end)
	print(string.format("[GuardService] Bound %d guards.", #guards))
end

return GuardService
