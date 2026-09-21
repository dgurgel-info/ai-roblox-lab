--!strict

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local GameConfig = require(Blackwood:WaitForChild("Shared"):WaitForChild("GameConfig"))
local remotes = Blackwood:WaitForChild("Remotes")
local dropBagRequest = remotes:WaitForChild(GameConfig.Remotes.DropBagRequest) :: RemoteEvent

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		dropBagRequest:FireServer()
	end
end)

