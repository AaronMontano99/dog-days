# Game Design — Dog Days

This is a first-draft design doc, scoped to explain what the current data model
implies and where it's headed. It will change as the game gets built — it is not a
locked spec. Where something is implemented today vs. only implied by the schema,
this doc says so explicitly.

## Core concept

The player raises one or more persistent dogs, starting as puppies. Dogs have a
name, a breed, a set of traits, and a bond with their owner that (by design intent —
not yet implemented) is meant to grow through play. Dogs accumulate **Memories** and
**Discoveries** over time — the current schema reserves empty arrays for both, but no
system populates them yet. The working idea (not committed) is that Memories capture
specific things that happened to a dog (a walk, a trick learned, a place visited) and
Discoveries capture places/items/interactions found while exploring, but the concrete
shape of an individual Memory/Discovery entry hasn't been designed yet — that's
scoped to whatever system first needs to write into those arrays.

## What exists today

- **You play as your dog.** There is no separate human avatar — a player's active
  dog IS their Roblox character, controlled with standard WASD + camera. Confirmed
  as the intended design (not assumed) before `DogCharacterService` was built.
- **Breeds**: 5 free starter breeds — Blue Heeler, Labrador Retriever, Beagle,
  German Shepherd, Siberian Husky. Every new player owns all 5 from profile
  creation (see `BreedConfig.luau`). Breed choice currently only affects
  `BreedId`/display metadata/coat color — no gameplay differences between breeds
  exist yet (e.g. no per-breed speed or stat differences).
- **Dog creation**: a player can request a dog be created with a chosen breed and
  name (`CreateDogRequest` → `DogProfileService.CreateDog`). Every new dog starts as
  a `Puppy` with neutral (50/100) `Traits` (`Loyalty`, `Energy`, `Curiosity`,
  `Obedience`), `Bond = 0`, and zeroed `Statistics`. A brand-new player is
  automatically given one starter dog (`EnsureStarterDog`) so there's something to
  spawn as — there's no dog-selection UI yet to make breed/name a real choice at
  signup.
- **Movement**: walking/running/jumping via a standard Roblox `Humanoid` on a
  placeholder block-primitive rig (no real dog art exists yet — see
  `docs/ROADMAP.md`). No breed-specific movement differences, no animations (legs
  don't move while walking), no stamina/sprint system.
- **Persistence**: dogs and player currency/settings persist via `ProfileStore`.
  There's a soft cap of `GameConfig.Dog.MaxDogsPerPlayer` (6) dogs per player.

## What's designed-for but not built

- **Life stages**: the schema supports `"Puppy" | "Adult" | "Senior"`, but nothing
  currently transitions a dog between stages.
- **Traits changing over time**: `Loyalty`/`Energy`/`Curiosity`/`Obedience` exist and
  start at a neutral value, but no gameplay system reads or writes them yet.
- **Bond**: same story — the field exists, starts at 0, nothing changes it yet.
- **Premium breeds**: `BreedConfig` entries carry `IsFree`/`PriceRobux` specifically
  so a premium breed is a data addition, not a schema change — but no premium breed
  is defined and no Robux purchase flow exists. This was explicitly out of scope for
  the foundation task that built this repo.
- **World/exploration**: `Workspace` has nothing but a flat placeholder testing
  surface (`TemporaryTestGround`) — no built environment yet. "Discoveries"
  presumably ties to exploring a world, but that world doesn't exist in source yet.

## Currency

`PlayerProfile.Currency` has `Coins` and `Gems` — two currencies, no defined use for
either yet (no shop, no sink). Everyone starts at 0/0.
