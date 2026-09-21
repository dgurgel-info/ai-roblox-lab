--!strict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local GameConfig = require(game:GetService("ReplicatedStorage").Blackwood.Shared.GameConfig)

type PlayerData = {
	Version: number,
	Cash: number,
	XP: number,
	Level: number,
	OwnedTools: { string },
	OwnedCosmetics: { string },
	Loadouts: { string },
	Statistics: { [string]: number },
	Collections: { string },
	Settings: { [string]: any },
	SeasonProgress: number,
}

local PlayerDataService = {}
local profiles: { [Player]: PlayerData } = {}
local dataStore = DataStoreService:GetDataStore("BlackwoodHeist_PlayerData_v1")

local function createDefaultData(): PlayerData
	return {
		Version = 1,
		Cash = GameConfig.Player.StarterCash,
		XP = GameConfig.Player.StarterXP,
		Level = 1,
		OwnedTools = { "Lockpick", "Flashlight", "BasicBag" },
		OwnedCosmetics = {},
		Loadouts = {},
		Statistics = {
			SuccessfulHeists = 0,
			PerfectHeists = 0,
			PoliceEscapes = 0,
			TimesBusted = 0,
			HighestLoot = 0,
		},
		Collections = {},
		Settings = {},
		SeasonProgress = 0,
	}
end

local function getKey(player: Player): string
	return string.format("Player_%d", player.UserId)
end

local function loadPlayer(player: Player)
	local data = createDefaultData()
	if RunService:IsStudio() then
		profiles[player] = data
		player:SetAttribute("Cash", data.Cash)
		return
	end

	local success, storedData = pcall(function()
		return dataStore:GetAsync(getKey(player))
	end)

	if success and type(storedData) == "table" then
		for key, value in storedData do
			(data :: any)[key] = value
		end
	elseif not success then
		warn(string.format("[PlayerDataService] Load failed for %s; using defaults.", player.Name))
	end

	profiles[player] = data
	player:SetAttribute("Cash", data.Cash)
end

local function savePlayer(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	if RunService:IsStudio() then
		profiles[player] = nil
		return
	end

	local success = pcall(function()
		dataStore:SetAsync(getKey(player), data)
	end)
	if not success then
		warn(string.format("[PlayerDataService] Save failed for %s.", player.Name))
	end
	profiles[player] = nil
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(loadPlayer)
	Players.PlayerRemoving:Connect(savePlayer)

	for _, player in Players:GetPlayers() do
		task.spawn(loadPlayer, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			savePlayer(player)
		end
	end)
end

function PlayerDataService.Get(player: Player): PlayerData?
	return profiles[player]
end

function PlayerDataService.AddCash(player: Player, amount: number): boolean
	local data = profiles[player]
	if not data or amount < 0 then
		return false
	end

	data.Cash += amount
	player:SetAttribute("Cash", data.Cash)
	return true
end

function PlayerDataService.IncrementStatistic(player: Player, statistic: string, amount: number)
	local data = profiles[player]
	if not data then
		return
	end
	data.Statistics[statistic] = (data.Statistics[statistic] or 0) + amount
end

return PlayerDataService
