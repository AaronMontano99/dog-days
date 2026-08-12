--!strict

-- Creates and looks up RemoteEvents from the RemoteDefs catalog, and wraps
-- server-side listeners with argument-shape validation + rate limiting. This is a
-- thin layer over real RemoteEvent instances — RemoteManager.Get() hands back the
-- actual Instance, nothing is hidden. See CLAUDE.md's "Networking" section.
--
-- RemoteManager.Init() must run before any Service's Init(), since Services connect
-- to remotes during their own Init(). Bootstrap.server.luau is responsible for that
-- ordering — it is not a registered Service itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefs = require(ReplicatedStorage.Shared.Net.RemoteDefs)
local RateLimiter = require(script.Parent.RateLimiter)

local RemoteManager = {}

local DEFAULT_RATE_LIMIT = { MaxCalls = 10, PerSeconds = 10 }

local remotesFolder: Folder? = nil
local remoteInstances: { [string]: RemoteEvent } = {}
local initialized = false

function RemoteManager.Init()
	if initialized then
		return
	end

	local folder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	remotesFolder = folder

	for name, _def in RemoteDefs do
		local existing = folder:FindFirstChild(name)
		if existing == nil then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
			remoteInstances[name] = remote
		elseif existing:IsA("RemoteEvent") then
			remoteInstances[name] = existing
		else
			error(string.format("[RemoteManager] '%s' exists under ReplicatedStorage.Remotes but is not a RemoteEvent", name), 0)
		end
	end

	initialized = true
end

function RemoteManager.Get(name: string): RemoteEvent
	local remote = remoteInstances[name]
	if remote == nil then
		error(
			string.format(
				"[RemoteManager] Unknown remote '%s' — not present in RemoteDefs, or RemoteManager.Init() hasn't run yet",
				name
			),
			2
		)
	end
	return remote
end

function RemoteManager.FireClient(name: string, player: Player, ...: any)
	local def = RemoteDefs[name]
	if def == nil or def.Direction ~= "ServerToClient" then
		error(string.format("[RemoteManager] '%s' is not a ServerToClient remote", name), 2)
	end
	RemoteManager.Get(name):FireClient(player, ...)
end

-- Connects `handler(player, ...)` to a ClientToServer remote. The wrapper validates
-- argument count/type against RemoteDefs, applies the remote's rate limit, then pcalls
-- the handler so one bad request can't take down the listener for other players.
function RemoteManager.Connect(name: string, handler: (player: Player, ...any) -> ()): RBXScriptConnection
	local def = RemoteDefs[name]
	if def == nil then
		error(string.format("[RemoteManager] Unknown remote '%s'", name), 2)
	end
	if def.Direction ~= "ClientToServer" then
		error(string.format("[RemoteManager] '%s' is not a ClientToServer remote", name), 2)
	end

	local remote = RemoteManager.Get(name)

	return remote.OnServerEvent:Connect(function(player: Player, ...: any)
		local args = { ... }

		if def.ArgTypes then
			if #args ~= #def.ArgTypes then
				warn(string.format("[RemoteManager] '%s' from %s: expected %d args, got %d", name, player.Name, #def.ArgTypes, #args))
				return
			end
			for i, expectedType in def.ArgTypes do
				if typeof(args[i]) ~= expectedType then
					warn(
						string.format(
							"[RemoteManager] '%s' from %s: arg %d expected %s, got %s",
							name,
							player.Name,
							i,
							expectedType,
							typeof(args[i])
						)
					)
					return
				end
			end
		end

		-- Every ClientToServer remote is rate-limited, even if RemoteDefs didn't set
		-- one explicitly — a forgotten RateLimit entry should degrade to a
		-- conservative default, never to "unlimited".
		local rateLimit = def.RateLimit or DEFAULT_RATE_LIMIT
		if not RateLimiter.Allow(player.UserId, name, rateLimit.MaxCalls, rateLimit.PerSeconds) then
			return
		end

		local ok, err = pcall(handler, player, table.unpack(args))
		if not ok then
			warn(string.format("[RemoteManager] handler for '%s' errored: %s", name, tostring(err)))
		end
	end)
end

return RemoteManager
