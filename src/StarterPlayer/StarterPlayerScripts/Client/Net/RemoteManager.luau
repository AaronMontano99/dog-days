--!strict

-- Client-side remote lookup ONLY — this module never creates a RemoteEvent. If a
-- remote is missing, that means the server bootstrap hasn't created it yet (or
-- something is wrong with load order); we wait briefly and then fail loudly rather
-- than returning nil, since a silent nil here turns into a confusing error far away
-- from the actual cause.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefs = require(ReplicatedStorage.Shared.Net.RemoteDefs)

local REMOTE_WAIT_TIMEOUT = 10

local RemoteManager = {}

function RemoteManager.Get(name: string): RemoteEvent
	local def = RemoteDefs[name]
	if def == nil then
		error(string.format("[RemoteManager] Unknown remote '%s' — not present in RemoteDefs", name), 2)
	end

	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", REMOTE_WAIT_TIMEOUT)
	if remotesFolder == nil then
		error("[RemoteManager] ReplicatedStorage.Remotes never appeared — server bootstrap likely failed", 2)
	end

	local remote = remotesFolder:WaitForChild(name, REMOTE_WAIT_TIMEOUT)
	if remote == nil then
		error(string.format("[RemoteManager] Remote '%s' never appeared under ReplicatedStorage.Remotes", name), 2)
	end
	if not remote:IsA("RemoteEvent") then
		error(string.format("[RemoteManager] '%s' exists but is not a RemoteEvent", name), 2)
	end

	return remote
end

function RemoteManager.FireServer(name: string, ...: any)
	local def = RemoteDefs[name]
	if def == nil or def.Direction ~= "ClientToServer" then
		error(string.format("[RemoteManager] '%s' is not a ClientToServer remote", name), 2)
	end
	RemoteManager.Get(name):FireServer(...)
end

function RemoteManager.Connect(name: string, handler: (...any) -> ()): RBXScriptConnection
	local def = RemoteDefs[name]
	if def == nil or def.Direction ~= "ServerToClient" then
		error(string.format("[RemoteManager] '%s' is not a ServerToClient remote", name), 2)
	end
	return RemoteManager.Get(name).OnClientEvent:Connect(handler)
end

return RemoteManager
