--!strict

-- Owns every player's persistent profile. This is the only Service allowed to touch
-- ProfileStore directly, and the only source of truth for "is this player's data
-- loaded and safe to read/write right now". See CLAUDE.md's PlayerProfile schema.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(script.Parent.Parent.Packages.ProfileStore)
local RemoteManager = require(script.Parent.Parent.Net.RemoteManager)
local RateLimiter = require(script.Parent.Parent.Net.RateLimiter)
local BreedConfig = require(ReplicatedStorage.Shared.Config.BreedConfig)
local Types = require(ReplicatedStorage.Shared.Types.Types)

type PlayerProfile = Types.PlayerProfile

local CURRENT_SCHEMA_VERSION = 1

-- Freshly-created profiles start from a deep copy of this table (ProfileStore does
-- the copying). Existing profiles get missing fields backfilled from this same table
-- via :Reconcile() — that's how additive schema changes reach existing players.
local function buildTemplate(): PlayerProfile
	local ownedBreeds: { [string]: boolean } = {}
	for breedId, breed in BreedConfig.Breeds do
		if breed.IsFree then
			ownedBreeds[breedId] = true
		end
	end

	return {
		SchemaVersion = CURRENT_SCHEMA_VERSION,
		Currency = {
			Coins = 0,
			Gems = 0,
		},
		OwnedBreeds = ownedBreeds,
		Dogs = {},
		ActiveDogId = nil,
		Settings = {
			MusicEnabled = true,
			SfxEnabled = true,
		},
		Meta = {
			CreatedAt = 0,
			LastLoginAt = 0,
		},
	}
end

-- Migration foundation: keyed by the SchemaVersion a profile is migrating FROM.
-- Nothing here yet because CURRENT_SCHEMA_VERSION has only ever been 1. When it
-- becomes 2, add Migrations[1] = function(data) ... mutate data in place ... end,
-- run every applicable migration in order, then bump data.SchemaVersion, all BEFORE
-- :Reconcile() runs.
local Migrations: { [number]: (data: PlayerProfile) -> () } = {}

local function applyMigrations(data: PlayerProfile)
	while data.SchemaVersion < CURRENT_SCHEMA_VERSION do
		local migrate = Migrations[data.SchemaVersion]
		if migrate == nil then
			error(
				string.format(
					"[PlayerDataService] No migration registered from schema version %d to %d",
					data.SchemaVersion,
					data.SchemaVersion + 1
				),
				0
			)
		end
		migrate(data)
		data.SchemaVersion += 1
	end
end

local PlayerDataService = {}

local store: typeof(ProfileStore.New("_", buildTemplate())) = nil :: any
local profiles: { [Player]: any } = {}

local function buildSyncPayload(data: PlayerProfile)
	return {
		Currency = data.Currency,
		OwnedBreeds = data.OwnedBreeds,
		Dogs = data.Dogs,
		ActiveDogId = data.ActiveDogId,
		Settings = data.Settings,
	}
end

-- Pushes this player's current state to their own client. Safe to call any number of
-- times (e.g. after a mutation) — it's a full snapshot, not a delta.
function PlayerDataService.SyncToClient(player: Player)
	local profile = profiles[player]
	if profile == nil then
		return
	end
	RemoteManager.FireClient("PlayerDataSync", player, buildSyncPayload(profile.Data))
end

-- Safe accessor: returns the profile's Data table only if the profile is loaded and
-- the session is still active, nil otherwise. Every other Service must go through
-- this instead of caching a reference themselves, so a mid-session profile release
-- (e.g. from a duplicate session elsewhere) can't be worked around accidentally.
function PlayerDataService.GetData(player: Player): PlayerProfile?
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return nil
	end
	return profile.Data
end

function PlayerDataService.IsLoaded(player: Player): boolean
	return PlayerDataService.GetData(player) ~= nil
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Session couldn't be started (e.g. locked by another server and it didn't
		-- release in time, or DataStore failure). Do NOT let the player play with no
		-- persistence — kick them so they can retry, per ProfileStore's intended usage.
		player:Kick("Failed to load your save data. Please rejoin in a moment.")
		return
	end

	applyMigrations(profile.Data)
	profile:Reconcile()

	profile:AddUserId(player.UserId)

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		RateLimiter.ClearPlayer(player.UserId)
		player:Kick("Your save data session ended. Please rejoin.")
	end)

	if player.Parent ~= Players then
		-- Player left while the session was loading.
		profile:EndSession()
		return
	end

	if profile.Data.Meta.CreatedAt == 0 then
		profile.Data.Meta.CreatedAt = os.time()
	end
	profile.Data.Meta.LastLoginAt = os.time()

	profiles[player] = profile

	PlayerDataService.SyncToClient(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
	-- profiles[player] is cleared by the OnSessionEnd handler above, not here —
	-- EndSession() triggers it asynchronously and we don't want a window where
	-- profiles[player] is stale-but-present.
end

function PlayerDataService.Init()
	store = ProfileStore.New("PlayerData_v1", buildTemplate())
end

function PlayerDataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle players already in the game if this Service somehow starts after them
	-- (defensive; normal boot order has Start() run before any player joins).
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			local profile = profiles[player]
			if profile ~= nil then
				profile:EndSession()
			end
		end
		-- Give ProfileStore a moment to flush final saves before the server closes.
		while next(profiles) ~= nil do
			task.wait()
		end
	end)
end

return PlayerDataService
