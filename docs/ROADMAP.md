# Roadmap

## Done (this foundation task)

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

## Next task: Dog Character + Movement V1

Explicitly **not** part of this foundation task. Scope, when picked up:

- A physical dog character rig (model/rig TBD — currently no asset exists under
  `ServerStorage/Assets/Dogs`)
- Spawning a dog character in `Workspace` tied to a player's `ActiveDogId`
- Basic movement (walk/run), likely via `Humanoid` or a custom controller depending
  on how "dog-like" movement needs to feel
- Whatever animation assets that requires, added under
  `ServerStorage/Assets/Animations`

## After that (unordered, unscoped — not commitments)

- World/exploration space for Discoveries to exist in
- Memory/Discovery data shape + the systems that write into those arrays
- Trait and Bond progression from actual gameplay
- Life stage transitions (Puppy → Adult → Senior)
- Chat-safe name filtering (`TextService:FilterStringAsync`) — see
  `docs/SECURITY.md`
- Premium breed purchase flow (MarketplaceService / Robux products)
- UI: breed selection, dog roster, HUD
