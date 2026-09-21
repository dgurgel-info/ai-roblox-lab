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

local EscapeService = {}
local escaped: { [Player]: boolean } = {}
local boundPoints: { [BasePart]: ProximityPrompt } = {}
local extractionResult: RemoteEvent
local escapeStateChanged: RemoteEvent
local running = false

local function getOrCreateRemote(name: string): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
	return remote
end

local function getEmergencyFolder(): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild("EmergencyExtractionPoints")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function isEmergencyPoint(point: Instance): boolean
	return point:IsA("BasePart") and point:GetAttribute("ExtractionType") == "Emergency"
end

local function isInRange(player: Player, point: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - point.Position).Magnitude <= GameConfig.Escape.InteractionDistance + 2
end

local function publish(active: boolean)
	Blackwood:SetAttribute("EscapeModeActive", active)
	Blackwood:SetAttribute("EscapeRoutesAvailable", if active then "Forest,Sewer" else "")
	escapeStateChanged:FireAllClients({
		Active = active,
		Routes = if active then { "Forest", "Sewer" } else {},
		Message = if active then "ESCAPE THE ESTATE" else "",
	})
	end

local function setPointsEnabled(enabled: boolean)
	for point, prompt in boundPoints do
		point:SetAttribute("Enabled", enabled)
		prompt.Enabled = enabled
	end
	publish(enabled)
end

local function resetPlayer(player: Player)
	escaped[player] = false
	player:SetAttribute("RoundEscaped", false)
	player:SetAttribute("EscapeRoute", nil)
end

local function sendResult(player: Player, success: boolean, reason: string, value: number, point: BasePart)
	extractionResult:FireClient(player, {
		Success = success,
		Reason = reason,
		Value = value,
		Point = point.Name,
		Route = point:GetAttribute("EscapeRoute") or point.Name,
	})
end

local function tryEscape(player: Player, point: BasePart)
	if RoundService.GetState() ~= Enums.RoundState.Escape then
		sendResult(player, false, "EMERGENCY_ESCAPE_NOT_OPEN", 0, point)
		return
	end
	if escaped[player] then
		sendResult(player, false, "ALREADY_ESCAPED", 0, point)
		return
	end
	if not isInRange(player, point) then
		sendResult(player, false, "TOO_FAR", 0, point)
		return
	end

	local snapshot = InventoryService.GetSnapshot(player)
	if snapshot.Value < GameConfig.Escape.MinimumLootValue then
		sendResult(player, false, "NO_LOOT", 0, point)
		return
	end
	if not PlayerDataService.AddCash(player, snapshot.Value) then
		sendResult(player, false, "PAYMENT_FAILED", 0, point)
		return
	end

	escaped[player] = true
	InventoryService.ClearRoundInventory(player)
	player:SetAttribute("RoundEscaped", true)
	player:SetAttribute("RoundExtracted", true)
	player:SetAttribute("LastExtractionValue", snapshot.Value)
	player:SetAttribute("LastExtractionPoint", point.Name)
	player:SetAttribute("EscapeRoute", point:GetAttribute("EscapeRoute") or point.Name)
	sendResult(player, true, "ESCAPED", snapshot.Value, point)
	print(string.format("[EscapeService] %s escaped via %s with $%d.", player.Name, point.Name, snapshot.Value))
end

local function bindPoint(point: BasePart)
	if boundPoints[point] then
		return
	end
	local prompt = point:FindFirstChild("EscapePrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "EscapePrompt"
		prompt.ActionText = "Escape"
		prompt.ObjectText = point:GetAttribute("DisplayName") or point.Name
		prompt.HoldDuration = GameConfig.Escape.PromptHoldDuration
		prompt.MaxActivationDistance = GameConfig.Escape.InteractionDistance
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Parent = point
	end
	prompt.Enabled = false
	point:SetAttribute("Enabled", false)
	boundPoints[point] = prompt
	prompt.Triggered:Connect(function(player: Player)
		tryEscape(player, point)
	end)
end

local function onRoundStateChanged()
	local state = RoundService.GetState()
	if state == Enums.RoundState.Escape then
		setPointsEnabled(true)
	else
		setPointsEnabled(false)
	end
	if state == Enums.RoundState.Lobby then
		for _, player in Players:GetPlayers() do
			resetPlayer(player)
		end
	end
end

function EscapeService.Start()
	if running then
		return
	end
	running = true
	extractionResult = getOrCreateRemote(GameConfig.Remotes.ExtractionResult)
	escapeStateChanged = getOrCreateRemote(GameConfig.Remotes.EscapeStateChanged)
	local folder = getEmergencyFolder()
	if not folder then
		warn("[EscapeService] EmergencyExtractionPoints folder not found.")
		return
	end
	for _, point in folder:GetChildren() do
		if isEmergencyPoint(point) then
			bindPoint(point :: BasePart)
		end
	end
	folder.ChildAdded:Connect(function(child)
		if isEmergencyPoint(child) then
			bindPoint(child :: BasePart)
		end
	end)
	Players.PlayerAdded:Connect(resetPlayer)
	Players.PlayerRemoving:Connect(function(player)
		escaped[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		resetPlayer(player)
	end
	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(onRoundStateChanged)
	onRoundStateChanged()
	print("[EscapeService] Forest Escape and Sewer Escape ready.")
end

return EscapeService
