--!strict

-- Caches the latest PlayerDataSync snapshot from the server. This is a read-only
-- mirror for UI to consume — nothing here is authoritative, and nothing here writes
-- back to the server directly (that only ever happens via a *Request remote, handled
-- server-side). See CLAUDE.md's "Security principles".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteManager = require(script.Parent.Parent.Net.RemoteManager)
local Types = require(ReplicatedStorage.Shared.Types.Types)

type PlayerProfile = Types.PlayerProfile

local PlayerDataController = {}

local latestSnapshot: any = nil

function PlayerDataController.GetSnapshot(): any?
	return latestSnapshot
end

function PlayerDataController.Init()
	RemoteManager.Connect("PlayerDataSync", function(snapshot: any)
		latestSnapshot = snapshot
	end)
end

return PlayerDataController
