--!strict

-- Creates and reads persistent dog profiles (stored inside the owning player's
-- PlayerProfile.Dogs). This is CRUD-level foundation only — no gameplay (movement,
-- stat changes, memories/discoveries being populated) happens here. See CLAUDE.md's
-- DogProfile schema and "Dog Character + Movement V1" in docs/ROADMAP.md for what's
-- deliberately not built yet.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Types = require(ReplicatedStorage.Shared.Types.Types)
local RemoteManager = require(script.Parent.Parent.Net.RemoteManager)

type DogProfile = Types.DogProfile

local DogProfileService = {}

-- Set during Init() — see BreedService for why this avoids a require cycle.
local PlayerDataService: any = nil
local BreedService: any = nil

local function isValidName(name: string): boolean
	if type(name) ~= "string" then
		return false
	end
	local length = utf8.len(name) or -1
	if length < GameConfig.Dog.NameMinLength or length > GameConfig.Dog.NameMaxLength then
		return false
	end
	return string.match(name, GameConfig.Dog.NamePattern) ~= nil
end

local function buildDogProfile(player: Player, breedId: string, name: string): DogProfile
	return {
		DogId = HttpService:GenerateGUID(false),
		OwnerUserId = player.UserId,
		Name = name,
		BreedId = breedId,
		CreatedAt = os.time(),
		LifeStage = "Puppy",
		Appearance = {
			CoatColorHex = "8B5A2B",
			PatternId = "Default",
			AccessoryIds = {},
		},
		Memories = {},
		Discoveries = {},
		Traits = {
			Loyalty = GameConfig.Traits.StarterValue,
			Energy = GameConfig.Traits.StarterValue,
			Curiosity = GameConfig.Traits.StarterValue,
			Obedience = GameConfig.Traits.StarterValue,
		},
		Bond = 0,
		Statistics = {
			AgeDays = 0,
			DistanceTraveled = 0,
			PlayTimeSeconds = 0,
		},
	}
end

-- Returns (true, dogId) on success, or (false, errorReason) on failure. Every
-- rejection reason is safe to show the client — none of them leak server internals.
function DogProfileService.CreateDog(player: Player, breedId: string, name: string): (boolean, string)
	local data = PlayerDataService.GetData(player)
	if data == nil then
		return false, "ProfileNotLoaded"
	end

	if not BreedService.CanPlayerUseBreed(player, breedId) then
		return false, "BreedNotAllowed"
	end

	if not isValidName(name) then
		return false, "InvalidName"
	end

	local dogCount = 0
	for _ in data.Dogs do
		dogCount += 1
	end
	if dogCount >= GameConfig.Dog.MaxDogsPerPlayer then
		return false, "TooManyDogs"
	end

	local dog = buildDogProfile(player, breedId, name)
	data.Dogs[dog.DogId] = dog
	if data.ActiveDogId == nil then
		data.ActiveDogId = dog.DogId
	end

	return true, dog.DogId
end

function DogProfileService.GetDog(player: Player, dogId: string): DogProfile?
	local data = PlayerDataService.GetData(player)
	if data == nil then
		return nil
	end
	return data.Dogs[dogId]
end

function DogProfileService.GetDogsForPlayer(player: Player): { [string]: DogProfile }
	local data = PlayerDataService.GetData(player)
	if data == nil then
		return {}
	end
	return data.Dogs
end

function DogProfileService.Init()
	PlayerDataService = require(script.Parent.PlayerDataService)
	BreedService = require(script.Parent.BreedService)

	RemoteManager.Connect("CreateDogRequest", function(player: Player, breedId: string, name: string)
		local ok, result = DogProfileService.CreateDog(player, breedId, name)

		if ok then
			PlayerDataService.SyncToClient(player)
			RemoteManager.FireClient("CreateDogResult", player, { Success = true, DogId = result })
		else
			RemoteManager.FireClient("CreateDogResult", player, { Success = false, Error = result })
		end
	end)
end

return DogProfileService
