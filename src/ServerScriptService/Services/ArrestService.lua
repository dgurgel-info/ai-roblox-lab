--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local Services = script.Parent
local InventoryService = require(Services:WaitForChild("InventoryService"))
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local RoundService = require(Services:WaitForChild("RoundService"))

type Attempt = {
	unit: Model,
	startedAt: number,
	lastUpdate: number,
}

local ArrestService = {}
local attempts: { [Player]: Attempt } = {}
local breakCooldowns: { [Player]: number } = {}
local arrestStateChanged: RemoteEvent
local running = false

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end
	local existing = remotes:FindFirstChild(GameConfig.Remotes.ArrestStateChanged)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.ArrestStateChanged
	remote.Parent = remotes
	return remote
end

local function getPoliceUnits(): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild("PoliceUnits")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function getRoot(instance: Instance): BasePart?
	local root = instance:FindFirstChild("HumanoidRootPart") or instance:FindFirstChildWhichIsA("BasePart")
	return if root and root:IsA("BasePart") then root else nil
end

local function getPlayerRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isArrestState(): boolean
	local state = RoundService.GetState()
	return state == Enums.RoundState.PoliceResponse or state == Enums.RoundState.Escape
end

local function canMaintainAttempt(player: Player, unit: Model): boolean
	local playerRoot = getPlayerRoot(player)
	local unitRoot = getRoot(unit)
	if not playerRoot or not unitRoot or not unit:GetAttribute("Deployed") then
		return false
	end
	if (playerRoot.Position - unitRoot.Position).Magnitude > GameConfig.Arrest.StartDistance then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { unit, player.Character }
	local result = workspace:Raycast(unitRoot.Position + Vector3.new(0, 2, 0), playerRoot.Position - unitRoot.Position, params)
	return result == nil or result.Instance:IsDescendantOf(player.Character :: Model)
end

local function send(player: Player, payload)
	arrestStateChanged:FireClient(player, payload)
end

local function cancelAttempt(player: Player, reason: string)
	if not attempts[player] then
		return
	end
	attempts[player] = nil
	breakCooldowns[player] = os.clock() + GameConfig.Arrest.BreakCooldown
	send(player, { State = "Cancelled", Reason = reason, Progress = 0 })
	print(string.format("[ArrestService] Arrest attempt cancelled for %s (%s).", player.Name, reason))
end

local function getNearestOfficer(player: Player): Model?
	local folder = getPoliceUnits()
	local playerRoot = getPlayerRoot(player)
	if not folder or not playerRoot then
		return nil
	end
	local nearest: Model?
	local nearestDistance = GameConfig.Arrest.StartDistance
	for _, child in folder:GetChildren() do
		if child:IsA("Model") and child:GetAttribute("Deployed") == true then
			local root = getRoot(child)
			if root then
				local distance = (playerRoot.Position - root.Position).Magnitude
				if distance <= nearestDistance and canMaintainAttempt(player, child) then
					nearest = child
					nearestDistance = distance
				end
			end
		end
	end
	return nearest
end

local function getLobbyCFrame(): CFrame
	local spawn = workspace:FindFirstChild("SpawnLocation", true)
	if spawn and spawn:IsA("BasePart") then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local spawnPoints = estate and estate:FindFirstChild("SpawnPoints")
	local playerSpawn = spawnPoints and spawnPoints:FindFirstChild("PlayerSpawn")
	if playerSpawn and playerSpawn:IsA("BasePart") then
		return playerSpawn.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 8, 0)
end

local function returnToLobby(player: Player)
	local character = player.Character
	if character then
		character:PivotTo(getLobbyCFrame())
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = GameConfig.Player.BaseWalkSpeed
		end
	end
	player:SetAttribute("PlayerRoundStatus", "Busted")
end

local function completeArrest(player: Player, unit: Model)
	if not isArrestState() or player:GetAttribute("RoundBusted") == true then
		return
	end
	local snapshot = InventoryService.GetSnapshot(player)
	InventoryService.ClearRoundInventory(player)
	player:SetAttribute("RoundBusted", true)
	player:SetAttribute("RoundEscaped", false)
	player:SetAttribute("BustedLootValue", snapshot.Value)
	player:SetAttribute("LastExtractionValue", 0)
	player:SetAttribute("LastExtractionPoint", nil)
	PlayerDataService.IncrementStatistic(player, "TimesBusted", 1)
	attempts[player] = nil
	send(player, {
		State = "Busted",
		Police = unit.Name,
		LostValue = snapshot.Value,
		XPKept = true,
	})
	print(string.format("[ArrestService] %s BUSTED by %s. Loot lost: $%d.", player.Name, unit.Name, snapshot.Value))
	returnToLobby(player)
end

local function updateAttempt(player: Player, now: number)
	local attempt = attempts[player]
	if not attempt then
		return
	end
	if not canMaintainAttempt(player, attempt.unit) then
		cancelAttempt(player, "BROKE_DISTANCE_OR_COVER")
		return
	end
	local elapsed = now - attempt.startedAt
	local progress = math.clamp(elapsed / GameConfig.Arrest.CompletionDuration, 0, 1)
	if now - attempt.lastUpdate >= 0.1 then
		attempt.lastUpdate = now
		send(player, {
			State = "Attempt",
			Police = attempt.unit.Name,
			Progress = progress,
			Duration = GameConfig.Arrest.CompletionDuration,
		})
	end
	if progress >= 1 then
		completeArrest(player, attempt.unit)
	end
end

local function scanForAttempts(now: number)
	if not isArrestState() then
		return
	end
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("RoundBusted") ~= true
			and player:GetAttribute("RoundEscaped") ~= true then
			if attempts[player] then
				updateAttempt(player, now)
			elseif now >= (breakCooldowns[player] or 0) then
				local officer = getNearestOfficer(player)
				if officer then
					attempts[player] = {
						unit = officer,
						startedAt = now,
						lastUpdate = 0,
					}
					send(player, {
						State = "Attempt",
						Police = officer.Name,
						Progress = 0,
						Duration = GameConfig.Arrest.CompletionDuration,
					})
					print(string.format("[ArrestService] %s arrest attempt started by %s.", player.Name, officer.Name))
				end
			end
		end
	end
end

local function resetPlayer(player: Player)
	attempts[player] = nil
	breakCooldowns[player] = nil
	player:SetAttribute("RoundBusted", false)
	player:SetAttribute("BustedLootValue", 0)
	player:SetAttribute("PlayerRoundStatus", "Active")
end

function ArrestService.Start()
	if running then
		return
	end
	running = true
	arrestStateChanged = getOrCreateRemote()
	Players.PlayerAdded:Connect(resetPlayer)
	Players.PlayerRemoving:Connect(function(player)
		attempts[player] = nil
		breakCooldowns[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		resetPlayer(player)
	end
	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(function()
		local state = RoundService.GetState()
		if state == Enums.RoundState.Lobby then
			for _, player in Players:GetPlayers() do
				resetPlayer(player)
			end
		else
			for player in attempts do
				if state ~= Enums.RoundState.PoliceResponse and state ~= Enums.RoundState.Escape then
					cancelAttempt(player, "ROUND_STATE_CHANGED")
				end
			end
		end
	end)
	task.spawn(function()
		while running do
			scanForAttempts(os.clock())
			task.wait(GameConfig.Arrest.UpdateInterval)
		end
	end)
	print("[ArrestService] Arrest attempts and Busted recovery ready.")
end

return ArrestService
