# Testing

There is **no automated test runner wired into this repo yet** (no TestEZ, no CI).
Everything below either happened during this foundation task (manual/static checks)
or describes what real testing would require going forward.

## What was actually verified during this task

- **JSON validity**: `default.project.json` parses as valid JSON (checked with
  `python3 -m json.tool`).
- **Path existence**: every `$path` in `default.project.json` was confirmed to exist
  on disk.
- **File-suffix conventions**: confirmed every server-only script uses
  `.server.luau`, every client-only script uses `.client.luau`, and every
  ModuleScript uses plain `.luau` — checked directory-by-directory, not just
  spot-checked.
- **Require graph**: every `require(...)` call in every new file was manually traced
  to confirm the target path/module actually exists at that relative location.
- **ProfileStore API usage**: `PlayerDataService`'s calls
  (`ProfileStore.New`, `:StartSessionAsync(key, {Cancel = ...})`, `profile.Data`,
  `:Reconcile()`, `:AddUserId()`, `.OnSessionEnd:Connect()`, `:IsActive()`,
  `:EndSession()`) were checked line-by-line against the actual vendored source in
  `ServerScriptService/Server/Packages/ProfileStore.luau`, not against
  memory/documentation alone.

None of this is a substitute for running the game. No Luau syntax/type checker
(`luau-analyze`) or Rojo CLI was available in the environment this was built in — see
the final report's "Studio Validation Required" section for the concrete list of
things that can only be confirmed by opening this in Roblox Studio.

## What's not tested and has no framework yet

- No unit tests exist for pure logic that would benefit from them, e.g.:
  - `RateLimiter.Allow` (token bucket refill math)
  - `DogProfileService`'s `isValidName` (length/charset edge cases)
  - `Loader`'s failure-aggregation behavior (does it actually run every module's
    `Init`/`Start` even after an earlier one throws, and does it correctly refuse to
    run `Start` after a failed `Init`?)
- No integration test exists for the full `CreateDogRequest` → `CreateDogResult`
  round trip, or for `ProfileStore` session-lock contention (e.g. rejoining a
  different server quickly).

## Recommended next step for this area

Pick a Luau test framework (TestEZ is the common choice for Rojo projects) before
the codebase grows past this foundation — retrofitting tests onto services that
already have real players' data flowing through them is much more expensive than
adding a test runner now, while `PlayerDataService`/`BreedService`/
`DogProfileService` are still small and mostly pure logic plus one `ProfileStore`
dependency that TestEZ can run against Roblox's Studio-side mock DataStore.
