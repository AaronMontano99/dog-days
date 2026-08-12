--!strict

-- The breed catalog. Shared because the client needs display metadata to render a
-- breed-selection UI — but `IsFree` / `PriceRobux` here only describe what the breed
-- IS, never what a specific player owns. Ownership lives server-side in
-- PlayerProfile.OwnedBreeds and is arbitrated by BreedService. See CLAUDE.md's
-- "Breed architecture" section.
--
-- Every entry has IsFree + PriceRobux so a premium breed is a data change (IsFree =
-- false, PriceRobux = N) plus a purchase flow, not a schema change. No premium breeds
-- or purchase flow exist yet — this task is foundation only.

local Types = require(script.Parent.Parent.Types.Types)

type BreedDefinition = Types.BreedDefinition

local BreedConfig = {}

local Breeds: { [string]: BreedDefinition } = {
	BlueHeeler = {
		Id = "BlueHeeler",
		DisplayName = "Blue Heeler",
		Description = "An alert, high-energy herding dog with a mottled blue-grey coat.",
		IsFree = true,
		PriceRobux = nil,
		AssetIds = { Icon = 0, Model = "" },
	},
	LabradorRetriever = {
		Id = "LabradorRetriever",
		DisplayName = "Labrador Retriever",
		Description = "A friendly, outgoing retriever and one of the most popular breeds.",
		IsFree = true,
		PriceRobux = nil,
		AssetIds = { Icon = 0, Model = "" },
	},
	Beagle = {
		Id = "Beagle",
		DisplayName = "Beagle",
		Description = "A small, curious scent hound with a famously good nose.",
		IsFree = true,
		PriceRobux = nil,
		AssetIds = { Icon = 0, Model = "" },
	},
	GermanShepherd = {
		Id = "GermanShepherd",
		DisplayName = "German Shepherd",
		Description = "A confident, loyal working dog known for trainability.",
		IsFree = true,
		PriceRobux = nil,
		AssetIds = { Icon = 0, Model = "" },
	},
	SiberianHusky = {
		Id = "SiberianHusky",
		DisplayName = "Siberian Husky",
		Description = "An athletic, vocal sled dog built for endurance.",
		IsFree = true,
		PriceRobux = nil,
		AssetIds = { Icon = 0, Model = "" },
	},
}

-- Deterministic ordering for UI (table iteration order isn't guaranteed).
local FreeStarterBreedOrder: { string } = {
	"BlueHeeler",
	"LabradorRetriever",
	"Beagle",
	"GermanShepherd",
	"SiberianHusky",
}

BreedConfig.Breeds = Breeds
BreedConfig.FreeStarterBreedOrder = FreeStarterBreedOrder

return BreedConfig
