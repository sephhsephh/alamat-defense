# CONTEXT — Game place ("Alamat Defense")
<!-- owner: game | scope: game | last-verified: 2026-08-16 (B23, teleport v4) -->

The match Place: loads a map, runs waves, towers fight, rewards commit to the profile.
Server-authoritative, registry/config-driven, signal-decoupled. `--!strict` throughout.

## Architecture in one paragraph

`MatchDirector` (SSS.Server) is the lifecycle state machine (WaitingForData → Preparing → Countdown
→ InProgress → Victory/Defeat → Cleanup). It delegates: maps to `MapLoader`, waves to `WaveDirector`
(virtual clock via `GameSpeed.Scheduler`), enemies to `EnemySpawner`/`EnemyController`, towers to
`TowerManager`/`TowerController` (per-tier attacks, passives/abilities/summons), economy to
`EconomyManager`, replication through the single `MatchReplicator` surface wired in
`ReplicationBridge` (the only script that knows clients exist). Configs are data modules under
`RS.Configs.*` with auto-scanning registries.

## Persistence (schema v2 — see docs/contracts/save-schema.md)

`Server.Data.PlayerDataService` owns ProfileStore sessions; `PlayerInventoryService` (uuid-keyed
`Units`/account/items + `GrantUnit`) and `SettingsService` are profile-backed facades. Schema v2 =
uuid unit instances + `Currencies` map; `Migrations[1]` converts v1 on load. Each unit carries
`StatRolls` + `Ascension`; `TowerStatResolver` folds them into DMG/RNG/SPA as a per-unit quality
multiplier over the tier×meta×trait pipeline.
Boot order in `ReplicationBridge`: data services first. `[DATA]`/`[CONTRACT]` log lines
confirm profile load + schema version on every boot.

## Key paths

- Server: `SSS.Server.{MatchDirector, MatchEntryService, MatchActionHandler, Data, Towers,
  Enemies, Waves, Economy, Inventory, Rewards, Stats, Networking, Map, GameSpeed, Summons,
  StatusEffects, Settings, Physics}`
- Shared: `RS.Shared.{Signal, Enums, Schema, ProfileTemplate, TowerStatResolver, AttackShapes}`
- Configs: `RS.Configs.{Towers, Enemies, Waves, Stages, Maps, Traits, StatusEffects, Summons, Global, Meta}`
  (`Global.GameConfig` = cross-Place ids: `LobbyPlaceId`, `TeleportPayloadVersion`;
  `Global.WorthinessConfig` = worthiness per kill + the 100 cap, A8 — a per-unit progression rate,
  sibling to `TowerProgressionConfig`, Game-computed and Lobby-displayed so NOT shared canon;
  `Meta.{TierConfig, StatGradeConfig, AscensionConfig, ItemCatalog, UnitStatsCatalog}` = rarity /
  roll-grade / ascension / grantable catalog / generated resolved-stat cache — **shared canon**
  (drift-checked). `UnitStatsCatalog` is deployed in BOTH Places since A6b, 2026-08-06.)
- **UI kit (AD-UI, shared canon)** — 5 controllers in `RS.Shared.UIKit` + 7 REAL templates in
  `RS.UITemplates.Kit` (hashed as instance trees, ADR-0005) + `StarterPlayerScripts.UIKitBootstrap`.
  **The Game HOTBAR is on it**: `StarterGui.Hotbar` is the Lobby's own ScreenGui, driven by the
  shared `UIKit.Hotbar`; the only Place difference is `OnActivated` → **start placement**. Editing
  any kit half in one Place only is DRIFT — `docs/systems/ui-kit.md`, `tools/checklists.md`. Other
  Game screens are still Place-local and script-era. **Drift here is 25/26 at B23** — only `MetaMath`
  MISSING (Phase D, expected); `ItemCatalog` caught up to the Lobby at B23 (`fc4b8023`). If
  `Kit_ItemIcon` ever reads odd, copy it from the Lobby rather than editing it.
- Remotes: `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}`
- Rich legacy docs: `ServerStorage.Documentation.*` (AIState, SystemIndex, HowTo, ...) —
  still valid; migrating to repo `docs/systems/` on touch.

## Entry paths (how a match starts)

- **Production:** `MatchEntryService` (SSS.Server, booted by `ReplicationBridge`) reads
  `TeleportData.MatchLaunch` (teleport contract **v4** — `Loadout` = unit uuids; `DifficultyMode`
  since B20; **`IsMatchmade` since B23**), validates PayloadVersion/StageId/players (resolves
  map/mode/difficulty from the stage; converts the JSON string userId keys → numeric; sanitizes
  DifficultyPercent; normalises DifficultyMode and IsMatchmade, anything unrecognised failing SAFE),
  and calls `MatchDirector.StartMatch` exactly once after the roster assembles. Loadout ownership + host authority are re-checked downstream — TeleportData is a
  request, never truth. Its pure `BuildRawConfig(payload)` is exported for unit testing.
- **Studio fallback:** `MatchLifecycleSmokeTest` (Studio-only) seeds 8 towers and starts Stage1_Act1
  ~3s after join — standing down when a MatchLaunch payload is present or `ColdProfileMatchTest` is
  enabled, so the paths never double-start.
- **Cold-profile harness:** `ColdProfileMatchTest` (Studio-only, `Enabled` default OFF) starts a
  match from the REAL profile's units — no dev seed — exercising the cold path the smoke test hides.
  `MatchDirector.StartMatch` waits for every profile BEFORE validating loadouts, so the empty-hotbar
  guard covers every caller. `AutoPlaceForEndScreenTest`/`MatchEndVerify` are `ENABLED=false`.

## Current state / known gaps

- Content: Stage 1 (3 acts), 1 map (TestMap), 8 towers, 2 enemies, Classic only. Attack
  anim/VFX/sound asset ids are placeholders (slots exist and tolerate nil).
- `ReturnToLobby` (MatchActionHandler) builds `MatchReturn` (v3) and teleports to the Lobby;
  `GameConfig.LobbyPlaceId` SET (83342803778137, 2026-07-18 Integration). The payload version
  comes from `GameConfig.TeleportPayloadVersion` (**=4 since B23**) and MUST equal the Lobby's
  `LobbyConfig.MatchLaunchVersion`; a mismatch is rejected, never downgraded. **v3 and v4 do NOT
  interoperate — the two Places must be republished TOGETHER.** NOTE: in Studio
  Play, pressing Lobby now attempts a real TeleportAsync, which fails (pcall'd +
  TeleportInitFailed handled) — expected; real teleports need the published client.
- Enemies.Behaviors (Flying/Splitting/…) is an empty extension point.
- **Counters + Worthiness are WRITTEN (blueprint §6, A8).** One commit per match inside
  `RewardCalculator.GrantForPlayer`: `CommitUnitKills` adds `Counters.PerUnit[uuid].Kills` and
  advances `Worthiness` (`WorthinessConfig`, 0.02/kill, cap 100 enforced INSIDE `Apply` so no future
  caller can bypass it); `Clears`/`ClearsByStage` move **on Victory only**, `Waves` on any outcome;
  `Counters.Global.Summons` is the one LIVE increment (`SummonManager.SpawnForTower`). No schema
  bump — v2 declared all of it. Full order of operations: `docs/systems/rewards.md`.
- **PLACEMENT IS uuid-ADDRESSED END TO END (B0, 2026-08-08).** `RequestPlace` carries a unit
  **uuid**; `PlacementValidator` resolves it with `LoadoutValidator.FindByUuid` against the player's
  own validated loadout and reads every stat off the SERVER's entry — the uuid is a request, never
  truth. `TowerController.Uuid` (+ `UnitUuid` attribute) carries it into combat; `MatchStatsTracker`
  KEYS by uuid; limits count per uuid; each uuid earns XP + counters from its OWN work. **A8's
  first-entry rule is GONE** — do not reintroduce a TowerId lookup in `FindByUuid` or re-key the
  tracker by type. Uuid-less towers (harnesses calling `PlaceTower` direct) fall back to TowerId.
- `LoadoutAssigned` carries the whole validated `LoadoutEntry` (incl. `Uuid`) and
  `PlacementCountsChanged` is keyed by uuid. A9 re-verified the counters path independently across
  three 15-wave Victories, persisted through real ProfileStore round trips. Detail: CHANGELOG A9/B0.
- **REWARDS SCALE WITH DIFFICULTY (P5, 2026-08-13) — `docs/systems/rewards.md` is the canon.**
  Victory gold is rolled from a band: `min = lerp(100,300,t)`, `max = lerp(300,500,t)`. A DEFEAT
  keeps its flat `Rewards.Defeat.Currency` (scaling a loss would make losing on max difficulty the
  best gold/minute). `Victory.Currency` survives as FALLBACK ONLY. **⚠ TWO DIFFICULTY SCALES: the
  UI is 1–100 (Lobby only) and the WIRE `DifficultyPercent` is 100–1000 (ADR-0011).** This Place
  only ever sees the WIRE value and converts it in exactly ONE function,
  `RewardScalingConfig.TFromWire` (`t = (wire-100)/900`, clamped). Reading a wire 100 as if it were
  UI 100 turns NORMAL into HARDEST and pays max gold silently — never add a second conversion.
  `matchState` is an OPTIONAL arg to `GrantForPlayer` and fails SAFE to normal.
- **`RewardScalingConfig` is SHARED CANON (`RS.Configs.Global`, hash `1d789978`), Game-deployed
  only.** §8 requires the Lobby's reward PREVIEW and the server's payout to read the SAME curve, and
  the Lobby's `StageRegistry` is a structure-only mirror with no drift check — so the curve could
  not live in `StageConfig`. Each act NAMES a curve (`Rewards.GoldCurve = "Standard"`) instead of
  copying endpoints. **`deployed.Lobby = null` → the Lobby reports MISSING until Integration copies
  it; that is expected, not drift.**
- **INSANE IS LIVE-REACHABLE since B20 (teleport v3).** The payload carries `DifficultyMode` →
  `rawConfig` → `matchState.DifficultyMode` → `RewardCalculator`'s Insane branch. Mode is a SEPARATE
  axis: it does NOT scale enemy health and never enters the wire→t conversion. Absent/unknown fails
  SAFE to Normal. Verified: Insane Victory paid both items, Normal paid neither, same gold band.
- **TELEPORT v4 (B23) — `IsMatchmade`, and the ONE-PARTY INVARIANT IS REPEALED.** A reserved server
  can now hold SEVERAL parties, or strangers with none, assembled by the Lobby's global queue across
  lobby servers. `matchState.IsMatchmade` is the flag to branch on — **never `PartyId`**, which is
  per-player, optional and read by NOTHING here. `HostUserId` is now an ELECTED host (lowest userId);
  this Place already fell back to lowest-userId, so both sides agree by construction.
  **A B23 survey found exactly ONE one-party assumption with teeth: GAME SPEED.** It is match-wide,
  and both the authority and the 3× gamepass gate come from the host alone — matchmade, an elected
  stranger. **B23 deliberately changed nothing** (a user design call, not a contract-bump edit) and
  logs `[CONTRACT] MATCHMADE match: speed authority ...`. `PartyId` and end-of-match (per-player)
  needed no change.
- **SHORT ROSTERS ARE ROUTINE AT v4 — and the economy now counts who ARRIVED (B23 fix).**
  `ValidatedPlayers` is the payload ROSTER; `matchState.PresentUserIds` is who actually turned up.
  `EconomyConfig.PlayerCountRewardScaling` ({1=1.0,…,4=0.8}) divides kill AND wave cash by the
  headcount, and it used to read the roster — so a lone survivor of a 4-player launch played the
  whole match at 0.8× cash. **Never revert `playerCount` to `#userIds`.** The Ready-phase vote and
  `GrantWaveReward` also take `presentUserIds`. Logged as `[CONTRACT] SHORT ROSTER: n of m`.
  **⚠ `RewardScalingConfig`'s own header comment still says the payload has no mode field — STALE.**
  It is shared canon at `1d789978`; correcting the comment changes the hash, so it needs an AD-Game
  comment-only re-hash + both-Place redeploy. The CODE is right; only the comment is wrong.
- **HARNESS GOTCHA — `Signal:Fire` runs handlers SEQUENTIALLY on ONE thread.** A `MatchEnded`
  handler that YIELDS blocks every later handler, including `MatchEndPresenter`, which drives the
  reward/counter commit (A9 burned three runs on this). To inspect post-commit state, `task.spawn`
  the body and return immediately — never `task.wait` inside a Signal handler here.
- A unit at `MAX_META_LEVEL` LOSES stored XP (`ApplyXP` discards overflow): Archer Lv100 went
  `XP 400 → 0` at A7. Cosmetic but visible on the Units screen.
- `DevSetOwnedTowers` REPLACES `data.Units` with new uuids, orphaning the Lobby's saved
  `Data.Loadout`. Fails safe, but the hotbar reports a stale "N equipped" count until the next equip.
- Real-DataStore round-trip for the PLAYER profile still PENDING (A7 used a scratch key: it
  exercised Reconcile + Migrate, not the player join path).
- **Stat rolls live + actually rolling (A3+):** `TowerStatResolver` reads each unit's `StatRolls` +
  `Ascension`; Archer + Mage are the `BaseStats` pilots. **All grant paths ROLL** — `GrantUnit`,
  `DevSetOwnedTowers` and the Lobby's `StarterChoiceService` all call `StatGradeConfig.RollAll(rng)`
  off one persistent `Random`. Existing units + the v1→v2 migration stay grandfathered at 0.5.
- **USER (BLOCKING): both Places must be republished TOGETHER for v4** — see STATE.md. v3's
  republish was confirmed done at B23; a live end-to-end run of the loop is still unconfirmed.
