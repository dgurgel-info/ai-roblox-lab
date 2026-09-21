--!strict

local RoundState = table.freeze({
	Lobby = "Lobby",
	Preparation = "Preparation",
	Infiltration = "Infiltration",
	Heist = "Heist",
	Lockdown = "Lockdown",
	Extraction = "Extraction",
	PoliceInbound = "PoliceInbound",
	PoliceResponse = "PoliceResponse",
	Escape = "Escape",
	Completed = "Completed",
	Failed = "Failed",
})

export type RoundState =
	"Lobby"
	| "Preparation"
	| "Infiltration"
	| "Heist"
	| "Lockdown"
	| "Extraction"
	| "PoliceInbound"
	| "PoliceResponse"
	| "Escape"
	| "Completed"
	| "Failed"

local RoundStateOrder: { RoundState } = table.freeze({
	RoundState.Lobby,
	RoundState.Preparation,
	RoundState.Infiltration,
	RoundState.Heist,
	RoundState.Lockdown,
	RoundState.Extraction,
	RoundState.PoliceInbound,
	RoundState.PoliceResponse,
	RoundState.Escape,
	RoundState.Completed,
	RoundState.Failed,
})

local GuardState = table.freeze({
	Patrol = "Patrol",
	Idle = "Idle",
	Suspicious = "Suspicious",
	Investigate = "Investigate",
	Search = "Search",
	Chase = "Chase",
	ReturnToPost = "ReturnToPost",
})

export type GuardState =
	"Patrol"
	| "Idle"
	| "Suspicious"
	| "Investigate"
	| "Search"
	| "Chase"
	| "ReturnToPost"

local PoliceAIState = table.freeze({
	Idle = "Idle",
	Deploy = "Deploy",
	Chase = "Chase",
	Intercept = "Intercept",
	Investigate = "Investigate",
	Search = "Search",
	Block = "Block",
	Return = "Return",
})

export type PoliceAIState =
	"Idle"
	| "Deploy"
	| "Chase"
	| "Intercept"
	| "Investigate"
	| "Search"
	| "Block"
	| "Return"

return table.freeze({
	RoundState = RoundState,
	RoundStateOrder = RoundStateOrder,
	GuardState = GuardState,
	PoliceAIState = PoliceAIState,
})
