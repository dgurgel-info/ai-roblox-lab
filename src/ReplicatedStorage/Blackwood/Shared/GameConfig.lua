--!strict

local GameConfig = {
	Round = {
		PreparationDuration = 45,
		InfiltrationDuration = 240,
		HeistDuration = 360,
		LockdownDuration = 5,
		ExtractionDuration = 120,
		PoliceInboundWarning = 10,
		PoliceResponseDuration = 5,
		EscapeDuration = 300,
	},

	Security = {
		MinimumLevel = 0,
		MaximumLevel = 5,
		LockdownThreshold = 4,
		CriticalThreshold = 5,
		CameraUpdateInterval = 0.1,
		CameraDetectionRange = 34,
		CameraDetectionAngle = 80,
		CameraDetectionRiseRate = 0.9,
		CameraDetectionFallRate = 0.35,
		CameraAlertThreshold = 1,
		LockdownGraceDuration = 5,
	},

	Guards = {
		UpdateInterval = 0.2,
		VisionRange = 30,
		VisionAngle = 110,
		RecognitionTime = 0.8,
		LoseSightTime = 1.5,
		PatrolSpeed = 9,
		ChaseSpeed = 13,
		SuspiciousDuration = 0.6,
		InvestigateTimeout = 6,
		SearchDuration = 8,
		SearchRadius = 12,
		ArrivalDistance = 3.5,
	},

	Police = {
		UpdateInterval = 0.25,
		VisionRange = 42,
		VisionAngle = 120,
		PatrolSpeed = 10,
		ChaseSpeed = 14,
		InterceptSpeed = 13,
		SearchSpeed = 9,
		LoseSightTime = 1.5,
		SearchDuration = 10,
		SearchRadius = 18,
		ArrivalDistance = 4,
		InterceptLeadTime = 1.2,
		MaxUnits = 6,
	},

	Player = {
		BaseWalkSpeed = 16,
		StarterCash = 0,
		StarterXP = 0,
	},

	Inventory = {
		StarterSlots = 6,
		StarterWeight = 15,
		PromptHoldDuration = 0.6,
		InteractionDistance = 12,
		WeightSpeedTiers = {
			{ MaxWeight = 10, Multiplier = 1.0 },
			{ MaxWeight = 20, Multiplier = 0.95 },
			{ MaxWeight = 30, Multiplier = 0.90 },
			{ MaxWeight = 40, Multiplier = 0.82 },
			{ MaxWeight = math.huge, Multiplier = 0.75 },
		},
	},

	Extraction = {
		PromptHoldDuration = 1.0,
		InteractionDistance = 14,
		MinimumLootValue = 1,
	},

	Escape = {
		PromptHoldDuration = 1.0,
		InteractionDistance = 14,
		MinimumLootValue = 1,
	},

	Arrest = {
		StartDistance = 5.5,
		CompletionDuration = 2.5,
		UpdateInterval = 0.1,
		BreakCooldown = 1.0,
	},

	Loot = {
		MaxActiveItems = 30,
		DefaultSpawnWeight = 1,
	},

	Remotes = {
		RoundStateChanged = "RoundStateChanged",
		SecurityLevelChanged = "SecurityLevelChanged",
		ExtractionTimerChanged = "ExtractionTimerChanged",
		InventoryUpdated = "InventoryUpdated",
		LootFeedback = "LootFeedback",
		ExtractionResult = "ExtractionResult",
		SecurityAlert = "SecurityAlert",
		GuardAlert = "GuardAlert",
		PoliceStateChanged = "PoliceStateChanged",
		PoliceAIAlert = "PoliceAIAlert",
		EscapeStateChanged = "EscapeStateChanged",
		DropBagRequest = "DropBagRequest",
		DropBagResult = "DropBagResult",
		ArrestStateChanged = "ArrestStateChanged",
	},

	Debug = {
		-- Studio-only smoke test. Published servers always use Round above.
		AutoAdvanceInStudio = true,
		TestDurations = {
			Lobby = 2,
			Preparation = 2,
			Infiltration = 20,
			Heist = 20,
			Lockdown = 4,
			Extraction = 20,
			PoliceInbound = 2,
			PoliceResponse = 2,
			Escape = 6,
			Completed = 2,
			Failed = 2,
		},
	},
}

return table.freeze(GameConfig)
