# Studio + MCP testing hazards and harnesses (both Places)
<!-- owner: AD-Integration | scope: both Places | created B170 from the retired STATE/CONTEXT notes (archive/) -->

The traps a session hits when it VERIFIES something in Studio through the MCP tools. CLAUDE.md "Editing rules"
holds the short rules; this is the detail. History of each finding: `archive/CHANGELOG-archive.md` (grep the B-number).

## execute_luau

- **`require` from `execute_luau` is DEAD (B64).** Studio's capability sandbox refuses every `require` from the
  MCP/Assistant thread (the scripts' own `Capabilities` enumerate EMPTY). Nothing in the repo caused it or can fix it.
  Reading `.Source` and instance properties still works.
- **Drift check without require:** paste the WHOLE of `tools/hash_shared.luau` as the `execute_luau` body (it uses
  `bit32`, no require). It is plain **FNV-1a 32-bit over `.Source`** for modules. Compare each live hash to BOTH
  `hash` AND `deployed.<Place>` in `shared/manifest.json`, **in code, field by field**: eyeballing missed real drift
  for two sessions (B39) and once the TOOL itself was stale (B58: it lacked five modules; a promotion updates the
  repo tool AND both in-Studio copies in the same session).
- ⚠ A naive `h * 16777619` overflows a double past 2^53 and reads as dozens of FALSE mismatches; multiply in 16-bit
  halves, as the tool does.
- ⚠ Kit **TEMPLATES** hash as INSTANCE TREES (ADR-0005), not Source.
- `execute_luau` has plugin capability, its own require cache and its own copy of every SERVICE: a
  `PlayerDataService` / `ClientSettings` reached from it is NOT the live one (B36, B55). Prove behaviour from a REAL
  Script (`[DIAG]` + `get_console_output`), a `Dev*` attribute, or `user_mouse_input` on the real control.
- A scripted camera cannot be HELD from `execute_luau` (the hold dies with the command); verify GUI by live
  property reads instead (B84).
- The boot marker goes AFTER `--!strict`, or Luau silently drops strict mode (B36).

## Input + Play

- **`user_keyboard_input` cannot send the 1-6 keys** (CoreGUI-bound). Click a hotbar slot with `user_mouse_input` +
  `instance_path` (B85).
- **Stale script on Play (B78, Knight):** Play once ran an OLD copy of `Configs.Towers.Knight` (2577 bytes) while
  Edit held the new one (2672). Suspect an open script-editor tab overwriting Source on Play. If Play behaves like
  the old code, compare `#Source` in Edit vs Play and ASK THE USER before re-testing.
- **Authored instances vanished once after a "Target is not reachable" Studio error** while every script edit
  survived (B87): suspect a rolled-back write. Re-check authored instances after that error.
- Under `StreamingEnabled`, **never block top-level boot on a Workspace instance** (B56: `WaitForChild(..., 30)` cost
  30s and returned nil). Persistent things live under `Workspace.PersistentScene` (`ModelStreamingMode = Persistent`).
- A bare `WaitForChild` never times out: a deleted authored instance makes a whole screen silently never boot
  (B33). Authored lookups use `need()`; the Lobby boot watchdog names hangs (`ui-feedback.md`).
- `ReserveServer` / `TeleportAsync` fail in Studio (403 / `TeleportInitFailed`, pcall'd): expected, not a bug.

## Dev profile

- Both Places share the dev store **`Beta1_PlayerDataDev1`** (prod `Beta1_PlayerData`). The Game's
  `MatchLifecycleSmokeTest` runs a match on every Play, so starting the Game right after the Lobby saved can reset
  the Lobby's dev currency (B55: Gold 49000 -> 15). Don't trust dev currency across a Place switch.

## Harnesses (all ship OFF; leave every `Dev*` attribute off when done)

- **Game `MatchLifecycleSmokeTest`** (Studio-only): seeds 8 towers, starts Stage1_Act1 ~3s after join; stands down
  when a MatchLaunch payload is present or `ColdProfileMatchTest` is on. Knobs `DevMatchModifiers`,
  `DevDifficultyMode` (`"Insane"` reaches the guaranteed Insane item grants -- the stage drop table is all chance).
- **Game `ColdProfileMatchTest`** (default OFF): a match from the REAL profile's units, no dev seed.
- **Game `AutoPlaceForEndScreenTest`**: `DevSeedCount` / `DevSeedMeta` / `DevSeedAscension` / `DevSeedRolls`
  (unset = old ceiling 24 / 50 / 3 / perfect; count takes EVENLY SPACED slots; guard is `>= 0` because ascension 0 is
  realistic) and `DevStageId` (empty = Act 1, unknown falls back LOUDLY). ⚠ `devStageId` sits BELOW the requires
  on purpose (it reads `StageRegistry`). `MatchEndVerify` ships `ENABLED=false`.
- **Game `ServerStorage` attribute `DevDebugAttacks`**: attack debug prints (`tower-authoring.md`).
- **Lobby `DevSimulateReturn` fires only on JOIN** -- set it in EDIT and restart Play. `DevSimulateFirstJoin` for
  the starter choice. `DevReceiptTest` drives `ReceiptService`. All `DevAutoOpen` harnesses OFF.
- **`Signal:Fire` runs handlers SEQUENTIALLY on ONE thread** (Game): a `MatchEnded` handler that yields blocks
  `MatchEndPresenter` and the reward commit. To inspect post-commit state, `task.spawn` the body; never `task.wait`
  inside a Signal handler (`match-architecture.md`).
