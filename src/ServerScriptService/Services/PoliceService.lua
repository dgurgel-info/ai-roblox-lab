--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local Services = script.Parent
local RoundService = require(Services:WaitForChild("RoundService"))

local PoliceService = {}
local policeStateChanged: RemoteEvent
local visuals: Folder?
local running = false
local visualGeneration = 0

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end
	local existing = remotes:FindFirstChild(GameConfig.Remotes.PoliceStateChanged)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.PoliceStateChanged
	remote.Parent = remotes
	return remote
end

local function getVisuals(): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild("PoliceResponseVisuals")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function publish(state: string, message: string)
	Blackwood:SetAttribute("PoliceState", state)
	Blackwood:SetAttribute("PoliceMessage", message)
	policeStateChanged:FireAllClients({ State = state, Message = message })
	print(string.format("[PoliceService] %s: %s", state, message))
end

local function setStaticVisuals(phase: string)
	if not visuals then
		return
	end
	for _, instance in visuals:GetDescendants() do
		if instance:IsA("PointLight") or instance:IsA("SurfaceLight") then
			instance.Enabled = phase ~= "Off"
			if phase == "Inbound" then
				instance.Brightness = 1.2
				instance.Range = 18
			elseif phase == "Response" then
				instance.Brightness = 3
				instance.Range = 32
			else
				instance.Enabled = false
			end
		end
		if instance:IsA("BasePart") and instance:GetAttribute("PoliceBeacon") == true then
			instance.Transparency = phase == "Off" and 1 or 0.15
		end
	end
end

local function setSirenPlaying(playing: boolean)
	if not visuals then
		return
	end
	local sound = visuals:FindFirstChild("PoliceSirenSoundEffect")
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "PoliceSirenSoundEffect"
		sound.SoundId = "rbxassetid://127714289075929"
		sound.Volume = 0.45
		sound.Looped = true
		sound.Parent = visuals
	end
	if sound:IsA("Sound") then
		sound.Playing = playing
	end
end

local function animateLights(phase: string)
	visualGeneration += 1
	local generation = visualGeneration
	setStaticVisuals(phase)
	if phase == "Off" or not visuals then
		return
	end

	task.spawn(function()
		local flip = false
		while running and generation == visualGeneration and RoundService.GetState() == (phase == "Inbound" and Enums.RoundState.PoliceInbound or Enums.RoundState.PoliceResponse) do
			flip = not flip
			for _, instance in visuals:GetDescendants() do
				if instance:IsA("PointLight") or instance:IsA("SurfaceLight") then
					local role = instance:GetAttribute("PoliceRole")
					instance.Enabled = role == (flip and "Red" or "Blue")
				end
			end
			task.wait(if phase == "Inbound" then 0.75 else 0.35)
		end
	end)
end

local function startInbound()
	if RoundService.GetState() ~= Enums.RoundState.PoliceInbound then
		return
	end
	Blackwood:SetAttribute("PoliceInboundStartedAt", os.clock())
	Blackwood:SetAttribute("SirenActive", true)
	setSirenPlaying(true)
	publish("Inbound", "POLICE RESPONSE INBOUND")
	animateLights("Inbound")
	local duration = if RunService:IsStudio()
		then GameConfig.Debug.TestDurations.PoliceInbound
		else GameConfig.Round.PoliceInboundWarning
	task.delay(duration, function()
		if RoundService.GetState() == Enums.RoundState.PoliceInbound then
			RoundService.BeginPoliceResponse()
		end
	end)
end

local function startResponse()
	if RoundService.GetState() ~= Enums.RoundState.PoliceResponse then
		return
	end
	Blackwood:SetAttribute("SirenActive", true)
	setSirenPlaying(true)
	publish("Response", "POLICE HAVE ARRIVED")
	animateLights("Response")
end

local function stopResponse()
	Blackwood:SetAttribute("SirenActive", false)
	setSirenPlaying(false)
	visualGeneration += 1
	setStaticVisuals("Off")
	publish("Off", "")
end

local function onRoundStateChanged()
	local state = RoundService.GetState()
	if state == Enums.RoundState.PoliceInbound then
		startInbound()
	elseif state == Enums.RoundState.PoliceResponse then
		startResponse()
	elseif state == Enums.RoundState.Lobby
		or state == Enums.RoundState.Completed
		or state == Enums.RoundState.Failed then
		stopResponse()
	end
end

function PoliceService.Start()
	if running then
		return
	end
	running = true
	policeStateChanged = getOrCreateRemote()
	visuals = getVisuals()
	if not visuals then
		warn("[PoliceService] PoliceResponseVisuals folder not found.")
	end
	Blackwood:GetAttributeChangedSignal("RoundState"):Connect(onRoundStateChanged)
	onRoundStateChanged()
	print("[PoliceService] Inbound and response sequence ready.")
end

return PoliceService
