--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Blackwood = ReplicatedStorage:WaitForChild("Blackwood")
local Shared = Blackwood:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Enums = require(Shared:WaitForChild("Enums"))

local Services = script.Parent
local RoundService = require(Services:WaitForChild("RoundService"))

type CameraState = {
	Meters: { [Player]: number },
	Triggered: { [Player]: boolean },
}

local SecurityService = {}
local cameraStates: { [Model]: CameraState } = {}
local securityAlert: RemoteEvent
local running = false

local function getOrCreateRemote(): RemoteEvent
	local remotes = Blackwood:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = Blackwood
	end

	local existing = remotes:FindFirstChild(GameConfig.Remotes.SecurityAlert)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end

	local remote = Instance.new("RemoteEvent")
	remote.Name = GameConfig.Remotes.SecurityAlert
	remote.Parent = remotes
	return remote
end

local function getCameraFolder(): Folder?
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local folder = estate and estate:FindFirstChild("SecurityDevices")
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function getLens(camera: Model): BasePart?
	local lens = camera:FindFirstChild("Lens")
	if lens and lens:IsA("BasePart") then
		return lens
	end
	return nil
end

local function isCameraActive(): boolean
	local state = RoundService.GetState()
	return state == Enums.RoundState.Infiltration or state == Enums.RoundState.Heist
end

local function isVisible(camera: Model, lens: BasePart, character: Model, targetPosition: Vector3): boolean
	local offset = targetPosition - lens.Position
	local distance = offset.Magnitude
	if distance > (camera:GetAttribute("DetectionRange") or GameConfig.Security.CameraDetectionRange) then
		return false
	end

	local direction = offset.Unit
	local dot = math.clamp(lens.CFrame.LookVector:Dot(direction), -1, 1)
	local angle = math.deg(math.acos(dot))
	local halfAngle = (camera:GetAttribute("DetectionAngle") or GameConfig.Security.CameraDetectionAngle) / 2
	if angle > halfAngle then
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignored: { Instance } = { camera }
	local estate = workspace:FindFirstChild("BlackwoodEstate")
	local markers = estate and estate:FindFirstChild("AreaMarkers")
	if markers then
		table.insert(ignored, markers)
	end
	params.FilterDescendantsInstances = ignored
	params.IgnoreWater = true
	local result = workspace:Raycast(lens.Position, offset, params)
	return result == nil or result.Instance:IsDescendantOf(character)
end

local function sendAlert(camera: Model, player: Player)
	local reason = camera:GetAttribute("DisplayName") or camera.Name
	local nextLevel = math.min(
		GameConfig.Security.MaximumLevel,
		RoundService.GetSecurityLevel() + 1
	)
	RoundService.SetSecurityLevel(nextLevel)
	Blackwood:SetAttribute("LastSecurityEvent", "Camera:" .. reason)
	Blackwood:SetAttribute("LastSecurityEventTime", os.clock())
	securityAlert:FireAllClients({
		Type = "CameraDetected",
		Source = reason,
		Player = player.Name,
		Level = nextLevel,
	})
	print(string.format("[SecurityService] Camera %s detected %s. Security -> %d", reason, player.Name, nextLevel))
end

local function updateCamera(camera: Model, state: CameraState)
	local lens = getLens(camera)
	if not lens or camera:GetAttribute("Enabled") == false then
		return
	end

	local detectedHighest = 0
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local current = state.Meters[player] or 0
		local visible = false
		if character and root and root:IsA("BasePart") then
			visible = isVisible(camera, lens, character, root.Position + Vector3.new(0, 1.2, 0))
		end

		if visible then
			current = math.min(
				GameConfig.Security.CameraAlertThreshold,
				current + (camera:GetAttribute("DetectionRiseRate") or GameConfig.Security.CameraDetectionRiseRate) * GameConfig.Security.CameraUpdateInterval
			)
		else
			current = math.max(
				0,
				current - (camera:GetAttribute("DetectionFallRate") or GameConfig.Security.CameraDetectionFallRate) * GameConfig.Security.CameraUpdateInterval
			)
		end

		state.Meters[player] = current
		detectedHighest = math.max(detectedHighest, current)
		if current >= GameConfig.Security.CameraAlertThreshold and not state.Triggered[player] then
			state.Triggered[player] = true
			sendAlert(camera, player)
		elseif current <= 0.2 then
			state.Triggered[player] = false
		end
	end

	camera:SetAttribute("DetectionMeter", detectedHighest)
end

local function bindCamera(camera: Model)
	if cameraStates[camera] then
		return
	end
	if camera:GetAttribute("DeviceType") ~= "Camera" then
		return
	end
	cameraStates[camera] = {
		Meters = {},
		Triggered = {},
	}
	end

function SecurityService.AddSecurity(amount: number, reason: string): number
	local nextLevel = math.min(
		GameConfig.Security.MaximumLevel,
		RoundService.GetSecurityLevel() + math.max(0, amount)
	)
	RoundService.SetSecurityLevel(nextLevel)
	Blackwood:SetAttribute("LastSecurityEvent", reason)
	Blackwood:SetAttribute("LastSecurityEventTime", os.clock())
	securityAlert:FireAllClients({
		Type = "SecurityEvent",
		Source = reason,
		Level = nextLevel,
	})
	return nextLevel
end

function SecurityService.Start()
	if running then
		return
	end
	running = true
	securityAlert = getOrCreateRemote()

	local folder = getCameraFolder()
	if not folder then
		warn("[SecurityService] SecurityDevices folder not found.")
		return
	end
	for _, child in folder:GetChildren() do
		if child:IsA("Model") then
			bindCamera(child)
		end
	end
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			bindCamera(child)
		end
	end)

	task.spawn(function()
		while running do
			if isCameraActive() then
				for camera, state in cameraStates do
					updateCamera(camera, state)
				end
			end
			task.wait(GameConfig.Security.CameraUpdateInterval)
		end
	end)

	print(string.format("[SecurityService] Bound %d security cameras.", #folder:GetChildren()))
end

return SecurityService
