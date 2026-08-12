--!strict

-- Authority on breed existence and ownership. The client never decides whether it
-- owns a breed — it can only ask, via this Service, which itself reads from
-- PlayerDataService (server-held state) rather than trusting anything from a remote
-- argument. See CLAUDE.md's "Breed architecture" and "Security principles".

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BreedConfig = require(ReplicatedStorage.Shared.Config.BreedConfig)
local Types = require(ReplicatedStorage.Shared.Types.Types)

type BreedDefinition = Types.BreedDefinition

local BreedService = {}

-- Set during Init() to avoid a require cycle: PlayerDataService's template building
-- reads BreedConfig directly (not through BreedService), so BreedService can safely
-- depend on PlayerDataService instead of the other way around.
local PlayerDataService: any = nil

function BreedService.Init()
	PlayerDataService = require(script.Parent.PlayerDataService)
end

function BreedService.GetAllBreeds(): { BreedDefinition }
	local result = {}
	for _, breedId in BreedConfig.FreeStarterBreedOrder do
		table.insert(result, BreedConfig.Breeds[breedId])
	end
	return result
end

function BreedService.GetBreed(breedId: string): BreedDefinition?
	return BreedConfig.Breeds[breedId]
end

function BreedService.BreedExists(breedId: string): boolean
	return BreedConfig.Breeds[breedId] ~= nil
end

function BreedService.IsFree(breedId: string): boolean
	local breed = BreedConfig.Breeds[breedId]
	return breed ~= nil and breed.IsFree
end

function BreedService.PlayerOwnsBreed(player: Player, breedId: string): boolean
	local data = PlayerDataService.GetData(player)
	if data == nil then
		return false
	end
	return data.OwnedBreeds[breedId] == true
end

-- The single check every purchase/creation pathway should call: does this breed
-- exist, and is this player allowed to create/use a dog of it right now?
function BreedService.CanPlayerUseBreed(player: Player, breedId: string): boolean
	if not BreedService.BreedExists(breedId) then
		return false
	end
	if BreedService.IsFree(breedId) then
		return true
	end
	return BreedService.PlayerOwnsBreed(player, breedId)
end

function BreedService.GetDisplayMetadata(breedId: string): BreedDefinition?
	return BreedConfig.Breeds[breedId]
end

return BreedService
