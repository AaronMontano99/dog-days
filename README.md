# Dog Days

A Roblox dog-raising/exploration game, built with [Rojo](https://rojo.space/) so the
source lives in git instead of only inside Roblox Studio.

This repo has the **technical foundation** (service/controller loaders, a
networking layer, persistent player + dog data, the free-breed catalog) plus a first
pass at **Dog Character + Movement V1** — you play as your dog directly, currently a
placeholder block-primitive rig on a flat test surface (no real art or world yet).
See [`docs/ROADMAP.md`](docs/ROADMAP.md) for what's next.

Read [`CLAUDE.md`](CLAUDE.md) first — it's the architecture contract every file in
this repo is built to match.

## Setup

1. Install [Aftman](https://github.com/LPGhatguy/aftman) (toolchain manager), then run:
   ```
   aftman install
   ```
   This installs the pinned Rojo version from `aftman.toml`.

2. Start the Rojo server:
   ```
   rojo serve
   ```

3. In Roblox Studio, install the [Rojo plugin](https://create.roblox.com/store/asset/13916111004), then click **Connect** to sync `src/` into your place.

## Project layout

```
src/
  ReplicatedStorage/
    Shared/
      Modules/        -- Loader, DogRigFactory (placeholder rig builder), HexColor
      Types/           -- shared Luau types
      Config/          -- GameConfig, BreedConfig (shared, non-secret)
      Net/              -- RemoteDefs (the remote catalog)
  ServerScriptService/
    Server/
      Bootstrap.server.luau
      ServiceLoader.luau
      Services/        -- PlayerDataService, BreedService, DogProfileService,
                          DogCharacterService
      Net/               -- RemoteManager, RateLimiter (server-side)
      Packages/          -- vendored ProfileStore
  StarterPlayer/
    StarterPlayerScripts/
      Client/
        Bootstrap.client.luau
        ControllerLoader.luau
        Controllers/     -- PlayerDataController
        Net/               -- RemoteManager (client-side, lookup only)
  ServerStorage/
    Assets/              -- Dogs, Breeds, Environments, Animations (empty — no art yet)
docs/
  ARCHITECTURE.md
  GAME_DESIGN.md
  ROADMAP.md
  TESTING.md
  SECURITY.md
```

See `CLAUDE.md` for the full architecture contract, including the exact
`PlayerProfile` / `DogProfile` data schemas.
