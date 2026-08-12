--!strict

-- Non-secret, shared game configuration. Anything here is readable by the client by
-- definition (it lives in ReplicatedStorage) — do not put balance-sensitive or
-- server-authoritative values here that the client shouldn't be able to inspect.

local GameConfig = {
	SchemaVersion = 1,

	Dog = {
		MaxDogsPerPlayer = 6,
		NameMinLength = 2,
		NameMaxLength = 20,
		-- Conservative allow-list for a name typed before Roblox chat filtering runs.
		-- See docs/SECURITY.md — this is a shape check, not a moderation system.
		NamePattern = "^[%a][%a%s'-]*$",
	},

	Traits = {
		Min = 0,
		Max = 100,
		StarterValue = 50,
	},
}

return GameConfig
