--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ItemDefinitions = require(Shared:WaitForChild("ItemDefinitions"))

local Services = script.Parent
local InteractionService = require(Services:WaitForChild("InteractionService"))
local InventoryService = require(Services:WaitForChild("InventoryService"))
local RoundService = require(Services:WaitForChild("RoundService"))

local LootService = {}
local lootFeedback: RemoteEvent

local function getLootFolder(): Folder
	local estate = workspace:WaitForChild("BlackwoodEstate")
	local folder = estate:FindFirstChild("LootSpawns")
	if folder and folder:IsA("Folder") then
		return folder
	end

	local created = Instance.new("Folder")
	created.Name = "LootSpawns"
	created.Parent = estate
	return created
end

local function getFeedbackRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end

	local existing = remotes:FindFirstChild(GameConfig.Remotes.LootFeedback)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.LootFeedback
	remote.Parent = remotes
	return remote
end

local function getTargetPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		return instance.PrimaryPart or instance:FindFirstChildWhichIsA("BasePart")
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function setLootVisible(instance: Instance, visible: boolean)
	for _, child in instance:GetDescendants() do
		if child:IsA("BasePart") then
			child.Transparency = visible and 0 or 1
			child.CanCollide = visible
			child.CanTouch = visible
		end
		if child:IsA("ProximityPrompt") then
			child.Enabled = visible
		end
	end
	if instance:IsA("BasePart") then
		instance.Transparency = visible and 0 or 1
		instance.CanCollide = visible
		instance.CanTouch = visible
	end
end

local function validRoundState(): boolean
	local state = RoundService.GetState()
	return state == "Infiltration" or state == "Heist" or state == "Lockdown"
end

local function bindLoot(instance: Instance)
	local itemId = instance:GetAttribute("ItemId")
	local lootId = instance:GetAttribute("LootId")
	if typeof(itemId) ~= "string" or typeof(lootId) ~= "string" then
		return
	end

	local definition = ItemDefinitions[itemId]
	local target = getTargetPart(instance)
	if not definition or not target then
		return
	end

	instance:SetAttribute("Taken", false)
	local prompt = InteractionService.CreateLootPrompt(target, definition.Name)
	prompt.Triggered:Connect(function(player: Player)
		if not validRoundState() then
			lootFeedback:FireClient(player, false, "LOOT_NOT_AVAILABLE")
			return
		end
		if instance:GetAttribute("Taken") == true then
			lootFeedback:FireClient(player, false, "ALREADY_TAKEN")
			return
		end
		if not InteractionService.IsPlayerInRange(player, target) then
			lootFeedback:FireClient(player, false, "TOO_FAR")
			return
		end

		local accepted, reason = InventoryService.AddItem(player, {
			LootId = lootId,
			ItemId = definition.Id,
			Name = definition.Name,
			Value = definition.BaseValue,
			Weight = definition.Weight,
			CarryType = definition.CarryType,
		})
		if accepted then
			instance:SetAttribute("Taken", true)
			setLootVisible(instance, false)
			lootFeedback:FireClient(player, true, definition.Name, definition.BaseValue, definition.Weight)
		else
			lootFeedback:FireClient(player, false, reason)
		end
	end)
end

function LootService.Start()
	lootFeedback = getFeedbackRemote()
	local folder = getLootFolder()
	local active = 0
	for _, child in folder:GetChildren() do
		if active >= GameConfig.Loot.MaxActiveItems then
			break
		end
		if child:GetAttribute("ItemId") then
			bindLoot(child)
			active += 1
		end
	end
	print(string.format("[LootService] Bound %d loot items.", active))
end

return LootService
