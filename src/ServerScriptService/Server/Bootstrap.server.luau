--!strict

-- Server entry point. Order matters and is deliberate:
--   1. RemoteManager.Init()   — creates every RemoteEvent from RemoteDefs. Must run
--      before any Service, since Services connect remote handlers during their Init().
--   2. ServiceLoader:Init()   — every Service wires up its own state.
--   3. ServiceLoader:Start()  — every Service is now safe to call into other Services.
--
-- Deliberately NOT wrapped in pcall: an Init/Start failure must surface as a real
-- Roblox script error with a traceback in the Output panel, not get swallowed. See
-- CLAUDE.md's "Init() / Start() pattern".

local RemoteManager = require(script.Parent.Net.RemoteManager)
local ServiceLoader = require(script.Parent.ServiceLoader)

RemoteManager.Init()
ServiceLoader:Init()
ServiceLoader:Start()

print("[Bootstrap] Dog Days server started — all services initialized.")
