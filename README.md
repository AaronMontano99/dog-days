# Born a Go

A Roblox game, built with [Rojo](https://rojo.space/) so the source lives in git instead of only inside Roblox Studio.

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
  ServerScriptService/          server-side scripts
  ReplicatedStorage/            shared modules/assets
  StarterPlayer/
    StarterPlayerScripts/       client scripts
    StarterCharacterScripts/    per-character scripts
  StarterGui/                   UI
  Workspace/                    world objects
```
