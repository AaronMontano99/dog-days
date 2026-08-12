--!strict

-- Registers every Service with the shared Loader, in dependency order. Registration
-- order IS initialization order — PlayerDataService must Init() before BreedService
-- or DogProfileService, since both require() PlayerDataService during their own
-- Init(). See CLAUDE.md's "Init() / Start() pattern".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Loader = require(ReplicatedStorage.Shared.Modules.Loader)

local ServiceLoader = Loader.new("ServiceLoader")

ServiceLoader:Register("PlayerDataService", require(script.Parent.Services.PlayerDataService))
ServiceLoader:Register("BreedService", require(script.Parent.Services.BreedService))
ServiceLoader:Register("DogProfileService", require(script.Parent.Services.DogProfileService))

return ServiceLoader
