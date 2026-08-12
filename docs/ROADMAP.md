# Roadmap

## Done (foundation task)

- Rojo project structure and mappings (`default.project.json`)
- `Loader` — shared `Init()`/`Start()` engine for services and controllers
- Server `ServiceLoader` + `Bootstrap.server.luau`
- Client `ControllerLoader` + `Bootstrap.client.luau`
- Networking layer: `RemoteDefs` catalog, server `RemoteManager` (create/lookup/
  validate/rate-limit), client `RemoteManager` (lookup only), `RateLimiter`
- `PlayerDataService`: `ProfileStore`-backed persistence, session locking, join/leave
  handling, reconciliation, migration foundation, safe accessor API
- `BreedConfig` + `BreedService`: 5 free starter breeds, ownership arbitration,
  data architecture for future premium breeds (no purchase flow)
- `DogProfileService`: dog creation (CRUD-level only) with server-side validation

## Done (Dog Character + Movement V1)

- Player's `Character` is their active dog — `DogCharacterService`,
  `Players.CharacterAutoLoads = false`, manual `player.Character` assignment. See
  CLAUDE.md's "Character control model".
- `DogRigFactory`: placeholder block-primitive rig built from `Part`s + `Humanoid` at
  runtime (no art asset exists yet). Legs are static — no walk animation.
- `DogProfileService.EnsureStarterDog`: new players are auto-granted a default
  starter dog (no selection UI exists yet).
- `TemporaryTestGround`: a flat placeholder part so the rig has somewhere to stand.
- Basic respawn: `Humanoid.Died` → re-spawn the same dog after a fixed delay.
- Rojo project fix: `$ignoreUnknownInstances: true` on `StarterPlayerScripts`,
  `StarterCharacterScripts`, `StarterGui`, `Workspace` — without this, connecting
  Rojo would have deleted Roblox's default camera/control scripts.

## Next up (unordered, unscoped — not commitments)

- **Real dog art**: replace `DogRigFactory`'s block primitives with an actual rig +
  walk/run/sit animations (`ServerStorage/Assets/Animations`). Swapping this out
  shouldn't require touching `DogCharacterService`.
- **Real world**: delete `TemporaryTestGround`, build actual level geometry.
- **Run toggle / stamina**: V1 has a single fixed `WalkSpeed`; no sprint exists.
- Memory/Discovery data shape + the systems that write into those arrays
- Trait and Bond progression from actual gameplay
- Life stage transitions (Puppy → Adult → Senior)
- Chat-safe name filtering (`TextService:FilterStringAsync`) — see
  `docs/SECURITY.md`
- Premium breed purchase flow (MarketplaceService / Robux products)
- UI: dog roster / selection (currently silently auto-assigned), breed picker, HUD
