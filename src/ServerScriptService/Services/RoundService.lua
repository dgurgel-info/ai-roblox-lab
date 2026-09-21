--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local RoundService = {}
local currentState: Enums.RoundState = Enums.RoundState.Lobby
local securityLevel = GameConfig.Security.MinimumLevel
local extractionRemaining = 0
local running = false
local extractionGeneration = 0

local remotesFolder: Folder
local roundStateChanged: RemoteEvent
local securityLevelChanged: RemoteEvent
local extractionTimerChanged: RemoteEvent

local function ensureRemote(name: string): RemoteEvent
	local existing = remotesFolder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotesFolder
	return remote
end

local function setupRemotes()
	remotesFolder = Blackwood:FindFirstChild("Remotes") :: Folder
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = Blackwood
	end

	roundStateChanged = ensureRemote(GameConfig.Remotes.RoundStateChanged)
	securityLevelChanged = ensureRemote(GameConfig.Remotes.SecurityLevelChanged)
	extractionTimerChanged = ensureRemote(GameConfig.Remotes.ExtractionTimerChanged)
end

local function publishState()
	Blackwood:SetAttribute("RoundState", currentState)
	roundStateChanged:FireAllClients(currentState)
end

local function publishSecurity()
	Blackwood:SetAttribute("SecurityLevel", securityLevel)
	securityLevelChanged:FireAllClients(securityLevel)
end

local function publishExtractionTimer()
	Blackwood:SetAttribute("ExtractionRemaining", extractionRemaining)
	extractionTimerChanged:FireAllClients(extractionRemaining)
end

local function setState(nextState: Enums.RoundState)
	currentState = nextState
	if nextState == Enums.RoundState.Lobby then
		securityLevel = GameConfig.Security.MinimumLevel
		publishSecurity()
	end
	publishState()
	print(string.format("[RoundService] State -> %s", nextState))
end

function RoundService.GetState(): Enums.RoundState
	return currentState
end

function RoundService.GetSecurityLevel(): number
	return securityLevel
end

function RoundService.BeginExtraction(): boolean
	if currentState ~= Enums.RoundState.Lockdown then
		return false
	end

	extractionGeneration += 1
	local generation = extractionGeneration
	setState(Enums.RoundState.Extraction)
	extractionRemaining = if RunService:IsStudio()
		then GameConfig.Debug.TestDurations.Extraction
		else GameConfig.Round.ExtractionDuration

	task.spawn(function()
		while extractionRemaining > 0
			and currentState == Enums.RoundState.Extraction
			and generation == extractionGeneration do
			publishExtractionTimer()
			task.wait(1)
			extractionRemaining -= 1
		end

		if currentState == Enums.RoundState.Extraction and generation == extractionGeneration then
			publishExtractionTimer()
			setState(Enums.RoundState.PoliceInbound)
		end
	end)
	return true
end

function RoundService.BeginPoliceResponse(): boolean
	if currentState ~= Enums.RoundState.PoliceInbound then
		return false
	end
	setState(Enums.RoundState.PoliceResponse)
	return true
end

function RoundService.SetSecurityLevel(level: number)
	securityLevel = math.clamp(level, GameConfig.Security.MinimumLevel, GameConfig.Security.MaximumLevel)
	publishSecurity()

	local canEnterLockdown = currentState == Enums.RoundState.Infiltration or currentState == Enums.RoundState.Heist
	if securityLevel >= GameConfig.Security.LockdownThreshold and canEnterLockdown then
		setState(Enums.RoundState.Lockdown)
		task.delay(GameConfig.Security.LockdownGraceDuration, function()
			RoundService.BeginExtraction()
		end)
	end
end

function RoundService.Start()
	if running then
		return
	end

	running = true
	setupRemotes()
	securityLevel = GameConfig.Security.MinimumLevel
	extractionRemaining = 0
	publishState()
	publishSecurity()
	publishExtractionTimer()

	if RunService:IsStudio() and GameConfig.Debug.AutoAdvanceInStudio then
		task.spawn(RoundService.RunStudioSmokeTest)
	end
end

function RoundService.RunStudioSmokeTest()
	local durations = GameConfig.Debug.TestDurations
	local sequence: { { state: Enums.RoundState, duration: number } } = {
		{ state = Enums.RoundState.Lobby, duration = durations.Lobby },
		{ state = Enums.RoundState.Preparation, duration = durations.Preparation },
		{ state = Enums.RoundState.Infiltration, duration = durations.Infiltration },
		{ state = Enums.RoundState.Heist, duration = durations.Heist },
		{ state = Enums.RoundState.Lockdown, duration = durations.Lockdown },
	}

	for _, entry in sequence do
		setState(entry.state)
		task.wait(entry.duration)
	end

	setState(Enums.RoundState.Extraction)
	extractionRemaining = GameConfig.Debug.TestDurations.Extraction
	while extractionRemaining > 0 do
		publishExtractionTimer()
		task.wait(1)
		extractionRemaining -= 1
	end
	publishExtractionTimer()

	setState(Enums.RoundState.PoliceInbound)
	task.wait(durations.PoliceInbound)
	setState(Enums.RoundState.PoliceResponse)
	task.wait(durations.PoliceResponse)
	setState(Enums.RoundState.Escape)
	task.wait(durations.Escape)
	setState(Enums.RoundState.Completed)
	task.wait(durations.Completed)
	setState(Enums.RoundState.Failed)
	task.wait(durations.Failed)
	setState(Enums.RoundState.Lobby)
end

return RoundService
