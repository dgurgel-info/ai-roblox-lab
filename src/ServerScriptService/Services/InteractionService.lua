--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local InteractionService = {}

function InteractionService.CreateLootPrompt(parent: Instance, displayName: string): ProximityPrompt
	local existing = parent:FindFirstChild("LootPrompt")
	if existing and existing:IsA("ProximityPrompt") then
		return existing
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LootPrompt"
	prompt.ActionText = "Take"
	prompt.ObjectText = displayName
	prompt.HoldDuration = GameConfig.Inventory.PromptHoldDuration
	prompt.MaxActivationDistance = GameConfig.Inventory.InteractionDistance
	prompt.RequiresLineOfSight = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = parent
	return prompt
end

function InteractionService.IsPlayerInRange(player: Player, target: BasePart): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end

	return (root.Position - target.Position).Magnitude <= GameConfig.Inventory.InteractionDistance + 2
end

return InteractionService
