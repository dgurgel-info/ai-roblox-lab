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

local ExtractionService = {}
local extracted: { [Player]: boolean } = {}
local boundPoints: { [BasePart]: RBXScriptConnection } = {}
local boundPrompts: { [BasePart]: ProximityPrompt } = {}
local extractionResult: RemoteEvent

local VALID_STATES: { [Enums.RoundState]: boolean } = {
	[Enums.RoundState.Lockdown] = true,
	[Enums.RoundState.Extraction] = true,
}

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end

	local existing = remotes:FindFirstChild(GameConfig.Remotes.ExtractionResult)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.ExtractionResult
	remote.Parent = remotes
	return remote
end

local function getExtractionFolder(): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild("ExtractionPoints")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function isNormalPoint(point: Instance): boolean
	return point:IsA("BasePart") and point:GetAttribute("ExtractionType") == "Normal"
end

local function normalExtractionOpen(): boolean
	local state = RoundService.GetState()
	return state == Enums.RoundState.Lockdown or state == Enums.RoundState.Extraction
end

local function updateNormalPointAvailability()
	local enabled = normalExtractionOpen()
	for point, prompt in boundPrompts do
		point:SetAttribute("Enabled", enabled)
		prompt.Enabled = enabled
	end
end

local function sendResult(player: Player, success: boolean, reason: string, value: number, pointName: string)
		extractionResult:FireClient(player, {
			Success = success,
			Reason = reason,
			Value = value,
			Point = pointName,
		})
end

local function resetPlayerRoundState(player: Player)
	extracted[player] = false
	player:SetAttribute("RoundExtracted", false)
	player:SetAttribute("LastExtractionValue", 0)
	player:SetAttribute("LastExtractionPoint", nil)
end

local function isPlayerInRange(player: Player, point: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - point.Position).Magnitude <= GameConfig.Extraction.InteractionDistance + 2
end

local function tryExtract(player: Player, point: BasePart)
	if extracted[player] then
		sendResult(player, false, "ALREADY_EXTRACTED", 0, point.Name)
		return
	end

	local state = RoundService.GetState()
	if not VALID_STATES[state] then
		sendResult(player, false, "EXTRACTION_NOT_OPEN", 0, point.Name)
		return
	end

	if not isPlayerInRange(player, point) then
		sendResult(player, false, "TOO_FAR", 0, point.Name)
		return
	end

	local snapshot = InventoryService.GetSnapshot(player)
	if snapshot.Value < GameConfig.Extraction.MinimumLootValue then
		sendResult(player, false, "NO_LOOT", 0, point.Name)
		return
	end

	if not PlayerDataService.AddCash(player, snapshot.Value) then
		sendResult(player, false, "PAYMENT_FAILED", 0, point.Name)
		return
	end

	extracted[player] = true
	InventoryService.ClearRoundInventory(player)
	player:SetAttribute("RoundExtracted", true)
	player:SetAttribute("LastExtractionValue", snapshot.Value)
	player:SetAttribute("LastExtractionPoint", point.Name)
	sendResult(player, true, "EXTRACTED", snapshot.Value, point.Name)
	print(string.format("[ExtractionService] %s extracted $%d at %s.", player.Name, snapshot.Value, point.Name))
end

local function bindPoint(point: BasePart)
	if boundPoints[point] then
		return
	end

	point:SetAttribute("Enabled", true)
	local prompt = point:FindFirstChild("ExtractionPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ExtractionPrompt"
		prompt.ActionText = "Extract Loot"
		prompt.ObjectText = point:GetAttribute("DisplayName") or point.Name
		prompt.HoldDuration = GameConfig.Extraction.PromptHoldDuration
		prompt.MaxActivationDistance = GameConfig.Extraction.InteractionDistance
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.Parent = point
	end
	prompt.Enabled = normalExtractionOpen()
	point:SetAttribute("Enabled", prompt.Enabled)
	boundPrompts[point] = prompt

	boundPoints[point] = prompt.Triggered:Connect(function(player: Player)
		tryExtract(player, point)
	end)
end

function ExtractionService.Start()
	if extractionResult then
		return
	end

	extractionResult = getOrCreateRemote()
	local folder = getExtractionFolder()
	if not folder then
		warn("[ExtractionService] ExtractionPoints folder not found.")
		return
	end

	for _, point in folder:GetChildren() do
		if isNormalPoint(point) then
			bindPoint(point :: BasePart)
		end
	end

	folder.ChildAdded:Connect(function(child)
		if isNormalPoint(child) then
			bindPoint(child :: BasePart)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		resetPlayerRoundState(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		extracted[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		resetPlayerRoundState(player)
	end

	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(function()
		updateNormalPointAvailability()
		if RoundService.GetState() == Enums.RoundState.Lobby then
			for _, player in Players:GetPlayers() do
				resetPlayerRoundState(player)
			end
		end
	end)

	print("[ExtractionService] Bound normal extraction points.")
end

return ExtractionService
