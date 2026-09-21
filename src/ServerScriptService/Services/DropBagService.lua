--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local Services = script.Parent
local InventoryService = require(Services:WaitForChild("InventoryService"))
local RoundService = require(Services:WaitForChild("RoundService"))

type DroppedBag = {
	Items: { any },
	Value: number,
	Weight: number,
	OwnerUserId: number,
}

local DropBagService = {}
local droppedBags: { [Model]: DroppedBag } = {}
local dropCooldowns: { [Player]: number } = {}
local dropRequest: RemoteEvent
local dropResult: RemoteEvent
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

local function getBagFolder(): Folder
	local estate = workspace:WaitForChild("BlackwoodEstate")
	local folder = estate:FindFirstChild("DroppedBags")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = "DroppedBags"
	created.Parent = estate
	return created
end

local function canDropInRound(): boolean
	local state = RoundService.GetState()
	return state == "Heist"
		or state == "Lockdown"
		or state == "Extraction"
		or state == "PoliceInbound"
		or state == "PoliceResponse"
		or state == "Escape"
end

local function sendResult(player: Player, success: boolean, action: string, reason: string?, value: number, weight: number)
	dropResult:FireClient(player, {
		Success = success,
		Action = action,
		Reason = reason,
		Value = value,
		Weight = weight,
	})
end

local function getRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function inRange(player: Player, position: Vector3): boolean
	local root = getRoot(player)
	return root ~= nil and (root.Position - position).Magnitude <= GameConfig.Inventory.InteractionDistance + 2
end

local function createBag(player: Player, snapshot): Model
	local root = getRoot(player)
	local spawnPosition = if root then root.Position + root.CFrame.LookVector * 3 else Vector3.zero
	local folder = getBagFolder()
	local model = Instance.new("Model")
	model.Name = string.format("DroppedBag_%d", math.floor(os.clock() * 1000))
	model:SetAttribute("BagValue", snapshot.Value)
	model:SetAttribute("BagWeight", snapshot.Weight)
	model:SetAttribute("OwnerUserId", player.UserId)
	model.Parent = folder

	local bag = Instance.new("Part")
	bag.Name = "BagHandle"
	bag.Shape = Enum.PartType.Ball
	bag.Size = Vector3.new(2.4, 1.6, 2.4)
	bag.Position = spawnPosition + Vector3.new(0, 1.2, 0)
	bag.Color = Color3.fromRGB(42, 28, 22)
	bag.Material = Enum.Material.Fabric
	bag.Anchored = true
	bag.CanCollide = false
	bag.Parent = model

	local strap = Instance.new("Part")
	strap.Name = "Strap"
	strap.Size = Vector3.new(2.5, 0.18, 0.22)
	strap.Position = bag.Position + Vector3.new(0, 0.55, 0)
	strap.Color = Color3.fromRGB(178, 126, 54)
	strap.Material = Enum.Material.Metal
	strap.Anchored = true
	strap.CanCollide = false
	strap.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BagPrompt"
	prompt.ActionText = "Pick Up Bag"
	prompt.ObjectText = string.format("Dropped Loot $%d", snapshot.Value)
	prompt.HoldDuration = GameConfig.Inventory.PromptHoldDuration
	prompt.MaxActivationDistance = GameConfig.Inventory.InteractionDistance
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = bag

	model.PrimaryPart = bag
	droppedBags[model] = {
		Items = snapshot.Items,
		Value = snapshot.Value,
		Weight = snapshot.Weight,
		OwnerUserId = player.UserId,
	}
	prompt.Triggered:Connect(function(picker: Player)
		local record = droppedBags[model]
		if not record or not model.Parent then
			return
		end
		if RoundService.GetState() == "Lobby" or RoundService.GetState() == "Preparation" then
			sendResult(picker, false, "PickedUp", "BAG_NOT_AVAILABLE", 0, 0)
			return
		end
		if not inRange(picker, bag.Position) then
			sendResult(picker, false, "PickedUp", "TOO_FAR", 0, 0)
			return
		end
		local accepted, reason = InventoryService.TryAddItems(picker, record.Items)
		if not accepted then
			sendResult(picker, false, "PickedUp", reason, 0, 0)
			return
		end
		droppedBags[model] = nil
		model:Destroy()
		sendResult(picker, true, "PickedUp", nil, record.Value, record.Weight)
		print(string.format("[DropBagService] %s picked up dropped bag worth $%d.", picker.Name, record.Value))
	end)
	return model
end

local function dropBag(player: Player)
	if not canDropInRound() then
		sendResult(player, false, "Dropped", "DROP_NOT_AVAILABLE", 0, 0)
		return
	end
	local now = os.clock()
	if now - (dropCooldowns[player] or 0) < 1 then
		return
	end
	dropCooldowns[player] = now
	local snapshot = InventoryService.GetSnapshot(player)
	if snapshot.Value <= 0 or #snapshot.Items == 0 then
		sendResult(player, false, "Dropped", "NO_LOOT", 0, 0)
		return
	end
	createBag(player, snapshot)
	InventoryService.ClearRoundInventory(player)
	player:SetAttribute("LastDroppedBagValue", snapshot.Value)
	player:SetAttribute("DroppedBagActive", true)
	sendResult(player, true, "Dropped", nil, snapshot.Value, snapshot.Weight)
	print(string.format("[DropBagService] %s dropped bag worth $%d and %.1f kg.", player.Name, snapshot.Value, snapshot.Weight))
end

local function clearBags()
	for model in droppedBags do
		if model.Parent then
			model:Destroy()
		end
		droppedBags[model] = nil
	end
	for _, child in getBagFolder():GetChildren() do
		child:Destroy()
	end
end

function DropBagService.Start()
	if running then
		return
	end
	running = true
	dropRequest = getOrCreateRemote(GameConfig.Remotes.DropBagRequest)
	dropResult = getOrCreateRemote(GameConfig.Remotes.DropBagResult)
	dropRequest.OnServerEvent:Connect(dropBag)
	Players.PlayerRemoving:Connect(function(player)
		dropCooldowns[player] = nil
	end)
	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(function()
		local state = RoundService.GetState()
		if state == "Lobby" or state == "Completed" or state == "Failed" then
			clearBags()
		end
	end)
	print("[DropBagService] Drop bag and bag recovery ready.")
end

return DropBagService
