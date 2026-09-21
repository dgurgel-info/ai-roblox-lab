--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local shared = blackwood:WaitForChild("Shared")
local config = require(shared:WaitForChild("GameConfig"))
local remotes = blackwood:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "BlackwoodFoundationHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.Size = UDim2.fromOffset(320, 284)
panel.Position = UDim2.fromOffset(24, 24)
panel.BackgroundColor3 = Color3.fromRGB(17, 20, 27)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local function createLabel(name: string, y: number, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, -24, 0, 24)
	label.Position = UDim2.fromOffset(12, y)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.TextColor3 = Color3.fromRGB(232, 236, 242)
	label.TextSize = 16
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = text
	label.Parent = panel
	return label
end

local title = createLabel("Title", 8, "BLACKWOOD HEIST")
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(220, 174, 94)
local stateLabel = createLabel("RoundState", 38, "Round State: Lobby")
local securityLabel = createLabel("SecurityLevel", 66, "Security Level: 0 / 5")
local timerLabel = createLabel("ExtractionTimer", 94, "Extraction Timer: --:--")
local lootValueLabel = createLabel("LootValue", 122, "Loot Value: $0")
local lootWeightLabel = createLabel("LootWeight", 150, "Weight: 0.0 / 15 kg")
local cashLabel = createLabel("Cash", 178, "Cash: $0")
local speedLabel = createLabel("CarrySpeed", 206, "Movement Speed: 100%")
local feedbackLabel = createLabel("ExtractionFeedback", 234, "Status: Ready")
feedbackLabel.TextColor3 = Color3.fromRGB(163, 205, 190)

local function formatTime(seconds: number): string
	local minutes = math.floor(seconds / 60)
	local remainder = seconds % 60
	return string.format("%02d:%02d", minutes, remainder)
end

local function updateState(state: string)
	stateLabel.Text = "Round State: " .. state
end

local function updateSecurity(level: number)
	securityLabel.Text = string.format(
		"Security Level: %d / %d",
		level,
		config.Security.MaximumLevel
	)
end

local function updateTimer(seconds: number)
	if seconds <= 0 then
		timerLabel.Text = "Extraction Timer: --:--"
	else
		timerLabel.Text = "Extraction Timer: " .. formatTime(seconds)
	end
end

local function updateInventory(snapshot)
	if typeof(snapshot) ~= "table" then
		return
	end
	lootValueLabel.Text = string.format("Loot Value: $%d", snapshot.Value or 0)
	lootWeightLabel.Text = string.format("Weight: %.1f / %.1f kg", snapshot.Weight or 0, snapshot.WeightCapacity or 15)
end

local function updateCash()
	cashLabel.Text = string.format("Cash: $%d", player:GetAttribute("Cash") or 0)
end

local function updateCarrySpeed()
	local multiplier = player:GetAttribute("CarrySpeedMultiplier") or 1
	speedLabel.Text = string.format("Movement Speed: %d%%", math.floor(multiplier * 100 + 0.5))
	if multiplier < 0.9 then
		speedLabel.TextColor3 = Color3.fromRGB(255, 170, 120)
	elseif multiplier < 1 then
		speedLabel.TextColor3 = Color3.fromRGB(244, 205, 122)
	else
		speedLabel.TextColor3 = Color3.fromRGB(163, 205, 190)
	end
end

local function updateExtractionFeedback(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.Success then
		if result.Reason == "ESCAPED" then
			feedbackLabel.Text = string.format("ESCAPED VIA %s: +$%d", tostring(result.Route or "EMERGENCY"), result.Value or 0)
		else
			feedbackLabel.Text = string.format("Extracted: +$%d", result.Value or 0)
		end
		feedbackLabel.TextColor3 = Color3.fromRGB(121, 231, 168)
	else
		feedbackLabel.Text = "Status: " .. tostring(result.Reason or "Unavailable")
		feedbackLabel.TextColor3 = Color3.fromRGB(242, 170, 132)
	end
end

local function updateEscapeState(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.Active then
		feedbackLabel.Text = "ESCAPE ROUTES: FOREST / SEWER"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 195, 100)
	end
end

local function updateDropBagFeedback(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.Success then
		if result.Action == "Dropped" then
			feedbackLabel.Text = string.format("DROP BAG: -$%d / %.1f kg", result.Value or 0, result.Weight or 0)
		else
			feedbackLabel.Text = string.format("BAG RECOVERED: +$%d", result.Value or 0)
		end
		feedbackLabel.TextColor3 = Color3.fromRGB(244, 205, 122)
	else
		feedbackLabel.Text = "BAG: " .. tostring(result.Reason or "Unavailable")
		feedbackLabel.TextColor3 = Color3.fromRGB(242, 170, 132)
	end
end

local function updateArrestState(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.State == "Attempt" then
		local progress = math.floor((result.Progress or 0) * 100 + 0.5)
		feedbackLabel.Text = string.format("ARREST ATTEMPT %d%% - BREAK AWAY!", progress)
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
	elseif result.State == "Cancelled" then
		feedbackLabel.Text = "ARREST AVOIDED"
		feedbackLabel.TextColor3 = Color3.fromRGB(121, 231, 168)
	elseif result.State == "Busted" then
		feedbackLabel.Text = string.format("BUSTED - LOOT LOST: $%d", result.LostValue or 0)
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	end
end

local function updateSecurityAlert(result)
	if typeof(result) ~= "table" then
		return
	end
	feedbackLabel.Text = "ALERT: " .. tostring(result.Source or "Security event")
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 137, 112)
end

local function updateGuardAlert(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.Type == "Noise" then
		feedbackLabel.Text = "GUARD INVESTIGATING: " .. tostring(result.Source or "noise")
		feedbackLabel.TextColor3 = Color3.fromRGB(244, 196, 105)
	else
		feedbackLabel.Text = string.format("GUARD: %s %s", tostring(result.Guard or ""), tostring(result.State or ""))
		feedbackLabel.TextColor3 = Color3.fromRGB(244, 196, 105)
	end
end

local function updatePoliceState(result)
	if typeof(result) ~= "table" then
		return
	end
	if result.State == "Inbound" then
		feedbackLabel.Text = "POLICE RESPONSE INBOUND"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 195, 100)
	elseif result.State == "Response" then
		feedbackLabel.Text = "POLICE HAVE ARRIVED"
		feedbackLabel.TextColor3 = Color3.fromRGB(255, 110, 110)
	else
		feedbackLabel.Text = "Status: Ready"
		feedbackLabel.TextColor3 = Color3.fromRGB(163, 205, 190)
	end
end

remotes:WaitForChild(config.Remotes.RoundStateChanged).OnClientEvent:Connect(updateState)
remotes:WaitForChild(config.Remotes.SecurityLevelChanged).OnClientEvent:Connect(updateSecurity)
remotes:WaitForChild(config.Remotes.ExtractionTimerChanged).OnClientEvent:Connect(updateTimer)
remotes:WaitForChild(config.Remotes.InventoryUpdated).OnClientEvent:Connect(updateInventory)
remotes:WaitForChild(config.Remotes.ExtractionResult).OnClientEvent:Connect(updateExtractionFeedback)
remotes:WaitForChild(config.Remotes.SecurityAlert).OnClientEvent:Connect(updateSecurityAlert)
remotes:WaitForChild(config.Remotes.GuardAlert).OnClientEvent:Connect(updateGuardAlert)
remotes:WaitForChild(config.Remotes.PoliceStateChanged).OnClientEvent:Connect(updatePoliceState)
remotes:WaitForChild(config.Remotes.EscapeStateChanged).OnClientEvent:Connect(updateEscapeState)
remotes:WaitForChild(config.Remotes.DropBagResult).OnClientEvent:Connect(updateDropBagFeedback)
remotes:WaitForChild(config.Remotes.ArrestStateChanged).OnClientEvent:Connect(updateArrestState)
player:GetAttributeChangedSignal("Cash"):Connect(updateCash)
player:GetAttributeChangedSignal("CarrySpeedMultiplier"):Connect(updateCarrySpeed)

updateState((blackwood:GetAttribute("RoundState") :: string?) or "Lobby")
updateSecurity((blackwood:GetAttribute("SecurityLevel") :: number?) or 0)
updateTimer((blackwood:GetAttribute("ExtractionRemaining") :: number?) or 0)
updateInventory({
	Value = player:GetAttribute("LootValue") or 0,
	Weight = player:GetAttribute("LootWeight") or 0,
	WeightCapacity = player:GetAttribute("LootWeightCapacity") or 15,
})
updateCash()
updateCarrySpeed()
