--!strict

-- Registers every Controller with the shared Loader, in dependency order (see
-- ServiceLoader.luau's server-side equivalent for the same rationale).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Shared.Modules.Loader)

local ControllerLoader = Loader.new("ControllerLoader")

ControllerLoader:Register("PlayerDataController", require(script.Parent.Controllers.PlayerDataController))

return ControllerLoader
