--!strict

-- Client entry point. Same two-phase pattern as the server (see
-- Server/Bootstrap.server.luau): Init() every Controller, then Start() every
-- Controller. Deliberately not wrapped in pcall — a failure here should surface as a
-- real script error, not run the client in a half-initialized state silently.

local ControllerLoader = require(script.Parent.ControllerLoader)

ControllerLoader:Init()
ControllerLoader:Start()

print("[Bootstrap] Dog Days client started — all controllers initialized.")
