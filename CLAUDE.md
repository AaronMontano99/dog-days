# CLAUDE.md — Dog Days

This file is the architecture contract for **Dog Days** (repo: `dog-days`), a
Roblox dog-raising/exploration game. It existed nowhere before this foundation task —
this document was authored as part of establishing the technical foundation, and the
rest of the codebase is built to match it exactly. Treat it as binding: if code and
this file disagree, that's a bug in one of them, not a judgment call.

## Tech stack

- **Engine**: Roblox
- **Sync tool**: Rojo (`aftman.toml` pins the version)
- **Language**: Luau, using `.luau` file extensions throughout
- **Persistence**: [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) by
  Mad Studio (vendored source, not a Wally dependency — see
  `src/ServerScriptService/Server/Packages/ProfileStore.luau`)
- **Networking**: raw `RemoteEvent`s under a thin, auditable wrapper (no third-party
  networking library)

## Directory structure

```
default.project.json
aftman.toml
src/
  ReplicatedStorage/
    Shared/
      Modules/        -- engine-agnostic shared code (e.g. Loader)
      Types/           -- Luau `export type` declarations, shared server+client
      Config/          -- shared, non-secret configuration (GameConfig, BreedConfig)
      Net/             -- RemoteDefs (remote catalog) — shared contract only
  ServerScriptService/
    Server/
      Bootstrap.server.luau
      ServiceLoader.luau
      Services/
        PlayerDataService.luau
        BreedService.luau
        DogProfileService.luau
      Net/
        RemoteManager.luau
        RateLimiter.luau
      Packages/
        ProfileStore.luau      -- vendored, server-only
  StarterPlayer/
    StarterPlayerScripts/
      Client/
        Bootstrap.client.luau
        ControllerLoader.luau
        Controllers/
        Net/
          RemoteManager.luau
    StarterCharacterScripts/
  StarterGui/
  ServerStorage/
    Assets/
      Dogs/            -- future dog models
      Breeds/          -- future breed-specific assets
      Environments/    -- future world assets
      Animations/       -- future animation assets
  Workspace/
docs/
  ARCHITECTURE.md
  GAME_DESIGN.md
  ROADMAP.md
  TESTING.md
  SECURITY.md
```

`ServerStorage/Assets/*` directories are placeholders for binary Roblox assets
(models, animations) that don't yet exist — each contains a `README.md` explaining
its purpose instead of `.gitkeep`, since empty dirs aren't tracked by git.

## File naming conventions

- `Foo.server.luau` → a `Script` instance named `Foo` (server-only execution)
- `Foo.client.luau` → a `LocalScript` instance named `Foo` (client-only execution)
- `Foo.luau` → a `ModuleScript` instance named `Foo` (`require`-only, no
  server/client suffix, safe to require from either side unless it touches
  server-only APIs like `DataStoreService`)

## Init() / Start() pattern

Every Service (server) and Controller (client) module exposes up to two functions:

- `Init()` — synchronous setup only: create state tables, connect to signals that
  don't require other services yet to exist. **Must not** call into another
  service/controller's runtime behavior.
- `Start()` — runs after **every** module's `Init()` has completed. Safe to call into
  other services/controllers here, since the two-phase split guarantees they've all
  finished wiring themselves up first.

`Loader` (`ReplicatedStorage/Shared/Modules/Loader.luau`) is the shared engine behind
both `ServiceLoader` and `ControllerLoader`. Modules are registered in explicit order
(not `pairs()` iteration order, which is undefined) — **registration order is
initialization order**. Current server order: `PlayerDataService` → `BreedService` →
`DogProfileService`, because breed/dog logic reads player profile state.

`Loader:Init()` and `Loader:Start()` `pcall` each module individually, collect every
failure (not just the first), and if any occurred, raise a single aggregated `error()`
after the phase completes — that error is **not** caught by Bootstrap, so it surfaces
as a real Roblox script error in the Output panel with a traceback. Init failures
block the Start phase entirely: `Bootstrap` does not call `Loader:Start()` if
`Loader:Init()` threw.

## Networking

- **Remote catalog**: `ReplicatedStorage/Shared/Net/RemoteDefs.luau` is the single
  source of truth for every remote's name, direction, argument shape, and rate limit.
  Nothing creates or names a remote anywhere else.
- **Server**: `Server/Net/RemoteManager.luau` creates each `RemoteEvent` (idempotently,
  under `ReplicatedStorage.Remotes`) from `RemoteDefs` and exposes `:Connect(name, fn)`
  which wraps `fn` with argument-shape validation and rate limiting before it runs.
- **Client**: `Client/Net/RemoteManager.luau` only *looks up* remotes by name — it
  never creates them. If a remote is missing, that's a bug in the server bootstrap
  order, and this fails loudly (errors) rather than silently returning nil.
- **No abstraction theater**: the wrapper is a thin lookup + validate + rate-limit
  layer. `RemoteManager.Get(name)` returns the real `RemoteEvent` instance. Nothing
  hides that RemoteEvents are underneath.
- **Rate limiting**: per-`(UserId, remoteName)` token bucket. Limits are normally
  defined per-remote in `RemoteDefs`; a `ClientToServer` remote with no `RateLimit`
  entry falls back to a conservative default (`RemoteManager.DEFAULT_RATE_LIMIT`)
  rather than being unlimited — a forgotten rate limit degrades safely instead of
  silently. This is a foundation, not a full anti-abuse system — see
  `docs/SECURITY.md`.

## Data schema — PlayerProfile (SchemaVersion 1)

Owned by `PlayerDataService`. Template lives in that module (server-only; no reason
for the client to see the raw template).

```lua
{
    SchemaVersion = 1,

    Currency = {
        Coins = 0,
        Gems = 0,
    },

    OwnedBreeds = {
        -- [BreedId] = true. Seeded with the free starter breeds at profile creation.
        BlueHeeler = true,
        LabradorRetriever = true,
        Beagle = true,
        GermanShepherd = true,
        SiberianHusky = true,
    },

    Dogs = {}, -- [DogId: string] = DogProfile (see below)

    ActiveDogId = nil,

    Settings = {
        MusicEnabled = true,
        SfxEnabled = true,
    },

    Meta = {
        CreatedAt = 0,   -- os.time(), set once on first-ever session (0 means "unset")
        LastLoginAt = 0, -- os.time(), set every session
    },
}
```

Migration foundation: `SchemaVersion` is a plain integer. `ProfileStore`'s
`:Reconcile()` non-destructively fills in any field present in the template but
missing from a loaded profile (this is how new fields get backfilled for existing
players). Any change that isn't additive (renaming/restructuring a field) requires a
migration function keyed by version in `PlayerDataService.Migrations`, run before
`:Reconcile()`. No such migration exists yet because there's only ever been version 1.

## Data schema — DogProfile

Owned by `DogProfileService`, stored inside `PlayerProfile.Dogs[DogId]`.

```lua
{
    DogId = "…",           -- HttpService:GenerateGUID(false)
    OwnerUserId = 0,
    Name = "…",             -- player-chosen, length/charset-validated (not yet chat-filtered — see SECURITY.md)
    BreedId = "…",
    CreatedAt = 0,          -- os.time()

    LifeStage = "Puppy",    -- only "Puppy" is reachable right now

    Appearance = {
        CoatColorHex = "8B5A2B", -- hex string, NOT a Color3 — ProfileStore forbids storing userdata
        PatternId = "Default",
        AccessoryIds = {},
    },

    Memories = {},     -- empty; populated by future gameplay systems
    Discoveries = {},  -- empty; populated by future gameplay systems

    Traits = {
        Loyalty = 50,
        Energy = 50,
        Curiosity = 50,
        Obedience = 50,
    },

    Bond = 0,

    Statistics = {
        AgeDays = 0,
        DistanceTraveled = 0,
        PlayTimeSeconds = 0,
    },
}
```

## Breed architecture

`ReplicatedStorage/Shared/Config/BreedConfig.luau` is shared (client needs display
metadata to render a selection UI) and lists **only real, currently-offered breeds**.
Every entry has an `IsFree: boolean` field and a `PriceRobux: number?` field — that's
the full extension point for premium breeds later. No premium breed entries exist yet
and no purchase flow exists yet; adding a premium breed later is a data change
(`IsFree = false, PriceRobux = N`) plus a purchase service, not a schema change.

`BreedService` (server) is the authority on ownership — it cross-references
`BreedConfig` (what exists, what's free) against `PlayerDataService`'s
`OwnedBreeds` (what this specific player owns). The client never decides ownership.

## Security principles

1. **Server owns persistence.** The client never writes to `PlayerProfile` or
   `DogProfile` directly — it can only send a `RemoteEvent` *request*, which the
   server validates and either applies or rejects.
2. **No implicit trust of client payloads.** Every server-side remote handler
   validates argument shape (via `RemoteDefs`) before touching game state.
3. **Ownership is derived server-side only.** `BreedService` computes "can this
   player use this breed" from server-held state; there is no code path where a
   client argument alone grants a breed.
4. **Rate limiting is foundational, not complete.** See `docs/SECURITY.md` for what's
   covered (per-remote token buckets) and what isn't (no anomaly detection, no
   cross-remote throttling).

See `docs/ARCHITECTURE.md` and `docs/SECURITY.md` for the full picture.
