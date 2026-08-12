--!strict

-- The single source of truth for every RemoteEvent in the game: its name, direction,
-- expected argument shape, and (for client->server remotes) its rate limit. Nothing
-- creates or names a remote anywhere outside of this file — see CLAUDE.md's
-- "Networking" section.
--
-- ArgTypes describes the Lua `type()` of each positional argument a client is allowed
-- to send on a ClientToServer remote. This is a shape check, not business-logic
-- validation — each Service still validates values (ranges, ownership, etc.) itself.

export type Direction = "ServerToClient" | "ClientToServer"

export type RemoteDef = {
	Name: string,
	Direction: Direction,
	ArgTypes: { string }?, -- only meaningful for ClientToServer
	RateLimit: { MaxCalls: number, PerSeconds: number }?, -- only meaningful for ClientToServer
}

local RemoteDefs: { [string]: RemoteDef } = {
	PlayerDataSync = {
		Name = "PlayerDataSync",
		Direction = "ServerToClient",
	},

	CreateDogRequest = {
		Name = "CreateDogRequest",
		Direction = "ClientToServer",
		ArgTypes = { "string", "string" }, -- BreedId, Name
		RateLimit = { MaxCalls = 5, PerSeconds = 60 },
	},

	CreateDogResult = {
		Name = "CreateDogResult",
		Direction = "ServerToClient",
	},
}

return RemoteDefs
