# Security

This documents the security review done at the end of the foundation task, covering
every client/server pathway that exists in the repo right now: `PlayerDataSync`,
`CreateDogRequest`, `CreateDogResult`. Re-run this review whenever a new remote is
added — this file should describe the pathways that actually exist, not just the
ones that existed when it was written.

## Server owns persistence

`ProfileStore` (and `PlayerDataService`, which wraps it) live under
`ServerScriptService/Server/`. This isn't just convention — `ServerScriptService`
never replicates to the client, so client-side Luau **cannot** `require()` it even if
it tried. There is no code path, today, where the client writes to
`PlayerProfile`/`DogProfile` directly; every mutation goes through a server-side
handler that validates first.

## No client controls permanent state

Walking through the one mutation pathway that exists (`CreateDogRequest` →
`DogProfileService.CreateDog`):

| Field | Set by |
|---|---|
| `DogId` | `HttpService:GenerateGUID(false)` on the server |
| `OwnerUserId` | `player.UserId`, where `player` is the `Player` Roblox itself hands to the `OnServerEvent` listener — not a client-supplied argument, so it can't be spoofed to claim another player's dog |
| `Name` | client-supplied, but shape-validated server-side (see "Name filtering" below) before use |
| `BreedId` | client-supplied, but rejected server-side unless `BreedService.CanPlayerUseBreed` returns true |
| `CreatedAt`, `LifeStage`, `Appearance`, `Memories`, `Discoveries`, `Traits`, `Bond`, `Statistics` | all server-assigned defaults, no client input at all |

The client picks *which* breed and *what* name to request. Everything else about a
new dog is server-decided.

## No breed can be falsely granted

`BreedService.CanPlayerUseBreed(player, breedId)` is the only path anything in this
codebase uses to decide "can this player make a dog of this breed" — it checks
`BreedConfig` (does the breed exist, is it free) and, for non-free breeds,
`PlayerDataService.GetData(player).OwnedBreeds` (server-held state, not a client
argument). There is currently no remote that writes to `OwnedBreeds` at all — the
only breeds anyone owns are the free starter breeds seeded into the profile template
at creation. When a purchase flow is eventually built, it must grant ownership from
a server-verified purchase receipt (`MarketplaceService` callback), never from a
client-fired remote argument.

## No arbitrary profile modifications are accepted

The only client → server remote today is `CreateDogRequest`, and its handler
(`DogProfileService.Init`'s `RemoteManager.Connect` callback) only ever calls
`DogProfileService.CreateDog`, which only ever inserts one new entry into
`data.Dogs` after full validation. There is no remote that accepts a raw table to
merge into a profile, no remote that lets a client specify a `Traits`/`Bond`/
`Currency` value directly, and no remote that lets a client specify someone else's
`Player`/`UserId`.

## Remote spam mitigation

Every `ClientToServer` remote is rate-limited via a per-`(UserId, remoteName)` token
bucket (`RateLimiter.Allow`). `RemoteDefs.CreateDogRequest` sets an explicit limit
(5 calls / 60s). **Found during this review and fixed**: the original implementation
only rate-limited a remote if `RemoteDefs` explicitly set a `RateLimit` table — a
future remote added without one would have been completely unlimited. `RemoteManager`
now falls back to `DEFAULT_RATE_LIMIT` (10 calls / 10s) for any `ClientToServer`
remote with no explicit limit, so "forgot to set a rate limit" degrades to "generic
default" instead of "no limit at all".

What this foundation does **not** cover: no cross-remote throttling (a player
spamming multiple different remotes at their individual limits simultaneously isn't
caught by anything), no anomaly/ban system, no server-wide rate limiting (only
per-player). Argument shape (`ArgTypes`) is checked before the handler runs, but
that's a `typeof()` check, not deep payload validation — each Service is still
responsible for validating the *values* it receives (see `DogProfileService`'s
`isValidName` and `BreedService.CanPlayerUseBreed` for examples of that layer).

## Known gap: no chat/name filtering yet

`DogProfileService.isValidName` only checks **shape** — length
(`GameConfig.Dog.NameMinLength`/`NameMaxLength`) and character class
(`GameConfig.Dog.NamePattern`, letters/spaces/apostrophes/hyphens only). It does
**not** run Roblox's `TextService:FilterStringAsync`, so a name built entirely from
allowed characters (including real words) can currently reach persisted storage
un-moderated. Any text a player enters that another player (or that same player,
depending on Roblox's policies) might see must go through Roblox's text filtering
before display — this is both a safety and a Roblox Terms of Service requirement,
not optional polish. This must be added before dog names are ever rendered in any
UI, and ideally before this ships at all. Tracked in `docs/ROADMAP.md`.

## Known gap: no request/response timeout on the client

If a `CreateDogRequest` handler throws after being `pcall`-wrapped, the error is
logged server-side but no `CreateDogResult` is ever fired back — a client naively
waiting for a response with no timeout would hang. Not a security issue by itself,
but worth fixing before UI is built on top of this remote.
