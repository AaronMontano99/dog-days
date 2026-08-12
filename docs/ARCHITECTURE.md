# Architecture

This document explains the *why* behind what's in `CLAUDE.md`. If you just need the
schemas/conventions, read `CLAUDE.md`. If you want to understand how the pieces fit
together, read this.

## Boot sequence

**Server** (`ServerScriptService/Server/Bootstrap.server.luau`):

1. `RemoteManager.Init()` — creates `ReplicatedStorage.Remotes.*` from `RemoteDefs`.
2. `ServiceLoader:Init()` — runs `Init()` on every registered Service, in
   registration order: `PlayerDataService` → `BreedService` → `DogProfileService`.
3. `ServiceLoader:Start()` — runs `Start()` on every Service, same order.

**Client** (`StarterPlayerScripts/Client/Bootstrap.client.luau`):

1. `ControllerLoader:Init()` — runs `Init()` on every registered Controller
   (currently just `PlayerDataController`).
2. `ControllerLoader:Start()` — runs `Start()` on every Controller.

Neither Bootstrap script wraps its calls in `pcall`. If any Service/Controller's
`Init` or `Start` throws, `Loader` aggregates every failure from that phase into one
`error()` call, which propagates all the way out of Bootstrap and shows up as a real
error with a stack trace in the Output panel. This is intentional — see
`CLAUDE.md`'s "Init() / Start() pattern": a service that silently failed to load is
worse than a server that visibly refuses to start.

## Why two phases (Init then Start), not one

Services depend on each other (`BreedService` and `DogProfileService` both need
`PlayerDataService`). A single-phase load would make correctness depend on
registration order in a way that's easy to get subtly wrong — a Service's top-level
code running before a dependency has finished setting up its own state.

Splitting into `Init()` (self-contained setup only) and `Start()` (safe to call other
services) means: by the time *any* module's `Start()` runs, *every* module has
already finished `Init()`. So even if `Start()` order matters, at least the
precondition "everyone has finished Init" is uniform. Registration order still
matters for one reason: a module's `Init()` may `require()` and use another module
directly — see `BreedService.Init()`, which does `require(PlayerDataService)` and
calls `PlayerDataService.GetData()` at runtime (not during `Init()` itself, only
inside handlers that run later) — this is why `PlayerDataService` is registered
first, even though the actual cross-service *calls* only happen after both are fully
initialized.

## Networking flow (example: creating a dog)

```
Client                          Server
------                          ------
RemoteManager.FireServer(
  "CreateDogRequest",
  breedId, name
)
        ───────────────────►
                                RemoteManager.Connect wrapper:
                                  1. arg count/type check vs RemoteDefs.ArgTypes
                                  2. RateLimiter.Allow(userId, "CreateDogRequest")
                                  3. pcall(handler, player, breedId, name)

                                DogProfileService handler:
                                  - PlayerDataService.GetData(player)  [nil? -> reject]
                                  - BreedService.CanPlayerUseBreed(player, breedId)
                                  - isValidName(name)
                                  - dog count vs GameConfig.Dog.MaxDogsPerPlayer
                                  - on success: mutate profile.Data.Dogs[dogId]
                                  - PlayerDataService.SyncToClient(player)
                                  - RemoteManager.FireClient("CreateDogResult", ...)
        ◄───────────────────
RemoteManager.Connect(
  "CreateDogResult", handler
)
```

Every validation happens server-side. The client's role is only to ask and then
render whatever the server decides. See `docs/SECURITY.md` for the failure modes
this is meant to close off.

## Player data lifecycle

`PlayerDataService` wraps `ProfileStore` (vendored, see
`ServerScriptService/Server/Packages/ProfileStore.luau`):

- **Join**: `store:StartSessionAsync(userId, {Cancel = ...})` — this is where
  ProfileStore's session locking lives; if another server still holds the lock and
  doesn't release it before the player leaves that server, `Cancel` fires and
  `StartSessionAsync` returns `nil`. A `nil` result kicks the player rather than
  letting them play unpersisted.
- **Migration + reconciliation**: `applyMigrations(profile.Data)` runs first (no-op
  today — see `CLAUDE.md`'s migration foundation), then `profile:Reconcile()` fills
  in any field present in the template but missing from the loaded data. This is how
  a schema addition reaches existing players without a hand-written migration.
- **First-session detection**: `Meta.CreatedAt` starts at `0` in the template; if
  it's still `0` after load, this is the player's first-ever session, so it's set to
  `os.time()`. `Meta.LastLoginAt` is set unconditionally every session.
  `Meta.CreatedAt` can't be a template-time `os.time()` call because the template is
  a single static table shared by every new profile — a per-profile creation
  timestamp has to be set after the fact.
- **Leave**: `Players.PlayerRemoving` calls `profile:EndSession()`. The actual
  cleanup (`profiles[player] = nil`, rate-limiter bucket clear) happens in the
  `OnSessionEnd` listener, not inline — `EndSession()` triggers session end
  asynchronously, so doing cleanup inline would leave a window where `profiles[player]`
  is stale.
- **Shutdown**: `game:BindToClose` ends every active session and blocks (via
  `task.wait()` polling) until `profiles` is empty, giving ProfileStore's final save
  a chance to flush before the server process exits.
- **Accessor**: every other Service reads player data via
  `PlayerDataService.GetData(player)`, which returns `nil` unless the profile is
  loaded *and* `profile:IsActive()` is still true. No Service caches a `Profile`
  reference itself — that would let it keep reading/writing after a session had
  already ended elsewhere.

## Why `CoatColorHex` is a string, not a `Color3`

ProfileStore's own documentation is explicit: don't store Roblox userdata
(`Color3`, `Vector3`, `CFrame`, ...) in profile data — only numbers, strings,
booleans, and nested tables of those. `DogProfile.Appearance.CoatColorHex` is a hex
string for this reason; any client-side rendering code converts it to a `Color3` at
the point of use, not before.

## What's deliberately not here yet

- No gameplay: no dog movement, no world, no stat progression from play.
- No Robux purchase flow for premium breeds (the *data shape* — `IsFree`,
  `PriceRobux` — exists; nothing populates or spends it).
- No delta-sync for player data — `PlayerDataSync` sends a full snapshot every time
  it fires (on join, and after `CreateDog`). Fine at this data size; revisit if the
  snapshot grows large enough that this matters.
- No chat/name filtering (`TextService:FilterStringAsync`) — dog names are currently
  only shape-validated (length + character allow-list). See `docs/SECURITY.md`.
