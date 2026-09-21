--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local InventoryService = {}

type InventoryItem = {
	LootId: string,
	ItemId: string,
	Name: string,
	Value: number,
	Weight: number,
	CarryType: string,
}

type Inventory = {
	Items: { InventoryItem },
	Value: number,
	Weight: number,
}

local inventories: { [Player]: Inventory } = {}
local inventoryUpdated: RemoteEvent

local function getSpeedMultiplier(weight: number): number
	for _, tier in GameConfig.Inventory.WeightSpeedTiers do
		if weight <= tier.MaxWeight then
			return tier.Multiplier
		end
	end
	return 0.75
end

local function applyMovementSpeed(player: Player, weight: number)
	local multiplier = getSpeedMultiplier(weight)
	player:SetAttribute("CarrySpeedMultiplier", multiplier)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = GameConfig.Player.BaseWalkSpeed * multiplier
	end
end

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end

	local existing = remotes:FindFirstChild(GameConfig.Remotes.InventoryUpdated)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.InventoryUpdated
	remote.Parent = remotes
	return remote
end

local function publish(player: Player)
	local inventory = inventories[player]
	if not inventory then
		return
	end

	player:SetAttribute("LootValue", inventory.Value)
	player:SetAttribute("LootWeight", inventory.Weight)
	player:SetAttribute("LootSlots", #inventory.Items)
	player:SetAttribute("LootCapacity", GameConfig.Inventory.StarterSlots)
	player:SetAttribute("LootWeightCapacity", GameConfig.Inventory.StarterWeight)
	applyMovementSpeed(player, inventory.Weight)
	inventoryUpdated:FireClient(player, {
		Items = inventory.Items,
		Value = inventory.Value,
		Weight = inventory.Weight,
		Slots = #inventory.Items,
		SlotCapacity = GameConfig.Inventory.StarterSlots,
		WeightCapacity = GameConfig.Inventory.StarterWeight,
	})
end

local function ensureInventory(player: Player): Inventory
	local inventory = inventories[player]
	if inventory then
		return inventory
	end

	inventory = {
		Items = {},
		Value = 0,
		Weight = 0,
	}
	inventories[player] = inventory
	return inventory
end

function InventoryService.GetSnapshot(player: Player)
	local inventory = ensureInventory(player)
	return {
		Items = table.clone(inventory.Items),
		Value = inventory.Value,
		Weight = inventory.Weight,
		Slots = #inventory.Items,
		SlotCapacity = GameConfig.Inventory.StarterSlots,
		WeightCapacity = GameConfig.Inventory.StarterWeight,
	}
end

function InventoryService.AddItem(player: Player, item: InventoryItem): (boolean, string)
	return InventoryService.TryAddItems(player, { item })
end

function InventoryService.TryAddItems(player: Player, items: { InventoryItem }): (boolean, string)
	local inventory = ensureInventory(player)
	if #inventory.Items + #items > GameConfig.Inventory.StarterSlots then
		return false, "SLOTS_FULL"
	end
	local addedWeight = 0
	for _, item in items do
		addedWeight += item.Weight
	end
	if inventory.Weight + addedWeight > GameConfig.Inventory.StarterWeight then
		return false, "WEIGHT_FULL"
	end

	for _, item in items do
		table.insert(inventory.Items, table.clone(item))
		inventory.Value += item.Value
		inventory.Weight += item.Weight
	end
	publish(player)
	return true, "PICKED_UP"
end

function InventoryService.ClearRoundInventory(player: Player)
	local inventory = ensureInventory(player)
	table.clear(inventory.Items)
	inventory.Value = 0
	inventory.Weight = 0
	publish(player)
end

function InventoryService.Start()
	inventoryUpdated = getOrCreateRemote()
	Players.PlayerAdded:Connect(function(player)
		ensureInventory(player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				local inventory = ensureInventory(player)
				applyMovementSpeed(player, inventory.Weight)
			end)
		end)
		publish(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		ensureInventory(player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				local inventory = ensureInventory(player)
				applyMovementSpeed(player, inventory.Weight)
			end)
		end)
		publish(player)
	end
end

return InventoryService
