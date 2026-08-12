--!strict

-- Shared type declarations. Kept in sync with the schemas documented in CLAUDE.md —
-- if you change a shape here, update CLAUDE.md (and vice versa).

export type PlayerCurrency = {
	Coins: number,
	Gems: number,
}

export type PlayerSettings = {
	MusicEnabled: boolean,
	SfxEnabled: boolean,
}

export type PlayerMeta = {
	CreatedAt: number,
	LastLoginAt: number,
}

export type DogAppearance = {
	CoatColorHex: string,
	PatternId: string,
	AccessoryIds: { string },
}

export type DogTraits = {
	Loyalty: number,
	Energy: number,
	Curiosity: number,
	Obedience: number,
}

export type DogStatistics = {
	AgeDays: number,
	DistanceTraveled: number,
	PlayTimeSeconds: number,
}

export type LifeStage = "Puppy" | "Adult" | "Senior"

export type DogProfile = {
	DogId: string,
	OwnerUserId: number,
	Name: string,
	BreedId: string,
	CreatedAt: number,
	LifeStage: LifeStage,
	Appearance: DogAppearance,
	Memories: { any },
	Discoveries: { any },
	Traits: DogTraits,
	Bond: number,
	Statistics: DogStatistics,
}

export type PlayerProfile = {
	SchemaVersion: number,
	Currency: PlayerCurrency,
	OwnedBreeds: { [string]: boolean },
	Dogs: { [string]: DogProfile },
	ActiveDogId: string?,
	Settings: PlayerSettings,
	Meta: PlayerMeta,
}

export type BreedAssetIds = {
	Icon: number,
	Model: string,
}

export type BreedDefinition = {
	Id: string,
	DisplayName: string,
	Description: string,
	IsFree: boolean,
	PriceRobux: number?,
	AssetIds: BreedAssetIds,
}

return {}
