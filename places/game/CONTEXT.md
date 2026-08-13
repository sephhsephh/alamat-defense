# CONTEXT — Game place ("Alamat Defense")
<!-- owner: game | scope: game | last-verified: 2026-08-06 -->
<!-- 2026-08-06 (AD-UI): added the UI-kit line below (AD-UI's own system) and corrected three
     STALE facts flagged the previous session — the USER publish is done, the Lobby's starter
     grant no longer writes 0.5, and UnitStatsCatalog is deployed in BOTH Places. Everything
     else in this file is AD-Game's canon and was left untouched. -->

The match Place: loads a map, runs waves, towers fight, rewards commit to the profile.
Server-authoritative, registry/config-driven, signal-decoupled. `--!strict` throughout.

## Architecture in one paragraph

`MatchDirector` (SSS.Server) is the lifecycle state machine (WaitingForData → Preparing →
Countdown → InProgress → Victory/Defeat → Cleanup). It delegates: maps to `MapLoader`
(folder-convention discovery, per-map lighting/music), waves to `WaveDirector` (virtual
clock via `GameSpeed.Scheduler`, overlapping waves), enemies to `EnemySpawner`/
`EnemyController`, towers to `TowerManager`/`TowerController` (per-tier attacks via
`AttackSequencer`, passives/abilities/summons), economy to `EconomyManager`, replication
through the single `MatchReplicator` surface wired in `ReplicationBridge` (the only
script that knows clients exist). Configs are data modules under `RS.Configs.*` with
auto-scanning registries. UI is scale-based under StarterGui, one controller per screen.

## Persistence (schema v2 — see docs/contracts/save-schema.md)

`Server.Data.PlayerDataService` owns ProfileStore sessions; `PlayerInventoryService`
(uuid-keyed `Units`/account/items, + `GrantUnit`) and `SettingsService` are profile-backed
facades. Schema v2 (A1, 2026-08-01) = uuid unit instances + `Currencies` map; `Migrations[1]`
converts v1 profiles on load. Each unit carries `StatRolls` + `Ascension`; `TowerStatResolver`
folds them into DMG/RNG/SPA (A3, 2026-08-01) as a per-unit quality multiplier over the
tier×meta×trait pipeline.
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
- **UI kit (AD-UI, shared canon since 2026-08-06)** — **5** controllers in `RS.Shared.UIKit` +
  **7** REAL instance templates in `RS.UITemplates.Kit` (hashed as instance trees per ADR-0005) +
  `StarterPlayerScripts.UIKitBootstrap`. **The Game HOTBAR is on it**: `StarterGui.Hotbar` is the
  Lobby's own ScreenGui (user-copied), driven by the shared `UIKit.Hotbar` with `Kit.HotbarSlot`
  clones; the only Place difference is `OnActivated` → **start placement**. The old
  `StarterPlayerScripts.Client.UI.Hotbar` is disabled/renamed `Hotbar_RETIRED_2026-08-06`, and
  `"Hotbar - old"` is kept as a disabled backup. Editing any kit half in one Place only is DRIFT
  — see `docs/systems/ui-kit.md` and `tools/checklists.md`. The Game's OTHER screens are still
  Place-local and script-era (`MatchEnd.RewardRowTemplate`, `Notifications.CardTemplate`, ...).
  **B2 (2026-08-08): drift is 22/22 GREEN here** (was 24). `UIKitRewardPopup` + `Kit_RewardPopup`
  were RETIRED in both Places — they had zero callers here (re-grepped live first) and the Lobby's
  `ObtainRewardsGUI` superseded them. Match-end keeps its own `RewardRowTemplate` list and is
  UNAFFECTED. `Kit_ItemIcon` also moved to `5623f4b4` and was mirrored here from the Lobby; if you
  ever see 21/22 with `Kit_ItemIcon` odd, copy it from the Lobby rather than editing it.
- Remotes: `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}`
- Rich legacy docs: `ServerStorage.Documentation.*` (AIState, SystemIndex, HowTo, ...) —
  still valid; migrating to repo `docs/systems/` on touch.

## Entry paths (how a match starts)

- **Production:** `MatchEntryService` (SSS.Server, booted by `ReplicationBridge`) reads
  `TeleportData.MatchLaunch` (teleport contract **v2** — `Loadout` = unit uuids), validates
  PayloadVersion/StageId/players
  (resolves map/mode/difficulty from the stage; converts the JSON string userId keys → numeric;
  sanitizes DifficultyPercent), and calls `MatchDirector.StartMatch` exactly once after the party
  assembles. Loadout ownership + host authority are re-checked downstream — TeleportData is a
  request, never truth. Its pure `BuildRawConfig(payload)` is exported for unit testing.
- **Studio fallback:** `MatchLifecycleSmokeTest` (Studio-only) seeds 8 towers via
  `DevSetOwnedTowers` and starts Stage1_Act1 ~3s after join — but stands down when a MatchLaunch
  payload is present, or when `ColdProfileMatchTest` is enabled, so the paths never double-start.
- **Cold-profile harness:** `ColdProfileMatchTest` (Studio-only, attribute `Enabled` default OFF)
  starts a match from the REAL loaded profile's units — **no dev seed** — to exercise the production
  cold path the synchronous smoke test hides (two live-only empty-hotbar failures came from that
  blind spot). `MatchDirector.StartMatch` now waits for every player's profile BEFORE validating
  loadouts (moved from `MatchEntryService` 2026-08-03), so the empty-hotbar guard covers every
  caller. `AutoPlaceForEndScreenTest` / `MatchEndVerify` exist but are `ENABLED=false`.

## Current state / known gaps

- Content: Stage 1 (3 acts), 1 map (TestMap), 8 towers, 2 enemies, Classic mode only.
- Attack anim/VFX/sound asset ids are placeholders (slots exist and tolerate nil).
- `ReturnToLobby` (MatchActionHandler) builds `MatchReturn` (v2) and teleports to the Lobby;
  `GameConfig.LobbyPlaceId` SET (83342803778137, 2026-07-18 Integration). The payload version
  comes from `GameConfig.TeleportPayloadVersion` (=2) and MUST equal the Lobby's
  `LobbyConfig.MatchLaunchVersion`; a mismatch is rejected, never downgraded. NOTE: in Studio
  Play, pressing Lobby now attempts a real TeleportAsync, which fails (pcall'd +
  TeleportInitFailed handled) — expected; real teleports need the published client.
- Enemies.Behaviors (Flying/Splitting/...) is an empty extension point.
- **Counters + Worthiness are WRITTEN (blueprint §6, A8).** One commit per match inside
  `RewardCalculator.GrantForPlayer`: `CommitUnitKills` adds `Counters.PerUnit[uuid].Kills` and
  advances `Worthiness` (`WorthinessConfig`, 0.02/kill, cap 100 enforced INSIDE `Apply` so no future
  caller can bypass it); `Clears`/`ClearsByStage` move **on Victory only**, `Waves` on any outcome;
  `Counters.Global.Summons` is the one LIVE increment (`SummonManager.SpawnForTower`). No schema
  bump — v2 declared all of it. Full order of operations: `docs/systems/rewards.md`.
- **PLACEMENT IS uuid-ADDRESSED END TO END (B0, 2026-08-08).** `RequestPlace` carries a unit
  **uuid**; `PlacementValidator` resolves it with `LoadoutValidator.FindByUuid` against the player's
  own validated loadout and reads every stat off the SERVER's entry — the uuid is a request, never
  truth. `TowerController.Uuid` (+ `UnitUuid` attribute) carries the instance into combat;
  `AttackResolver.DamageDealt` and `StatusEffectManager.EffectTicked` emit it; `MatchStatsTracker`
  KEYS by uuid; limits count per uuid (`CountPlayerTowersOfUnit`); each uuid earns XP + counters
  from its OWN work. **A8's first-entry rule is GONE.** Do not reintroduce a TowerId lookup in
  `FindByUuid` or re-key the tracker by type — both make duplicates silently wrong again. Uuid-less
  towers (harnesses calling `PlaceTower` direct) fall back to TowerId keying.
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
- **INSANE is implemented but UNREACHABLE live**: the teleport payload (v2) has no mode field, so
  this Place always sees Normal. Reaching it = contract v2→v3 (both Places, ONE session).
- **HARNESS GOTCHA — `Signal:Fire` runs handlers SEQUENTIALLY on ONE thread.** A `MatchEnded`
  handler that YIELDS blocks every later handler, including `MatchEndPresenter`, which is what
  drives the reward/counter commit. A9 burned three runs "observing" a late commit that its own
  waiting handler was causing. If you need to inspect post-commit state, `task.spawn` the body and
  return immediately — never `task.wait` inside a Signal handler here.
- A unit at `MAX_META_LEVEL` LOSES stored XP (`ApplyXP` discards overflow rather than preserving
  it): Archer Lv100 went `XP 400 → 0` at A7. Cosmetic but visible on the Units screen.
- `DevSetOwnedTowers` (smoke test) REPLACES `data.Units` with new uuids, which orphans the Lobby's
  saved `Data.Loadout`. It fails safe (readers filter unowned uuids) but the hotbar will report a
  stale "N equipped" count until the next equip. Disable the smoke test when testing the real
  cold path.
- Real-DataStore round-trip test for the PLAYER profile still PENDING (A7 did a real ProfileStore
  round trip on a scratch key, which exercised Reconcile + Migrate but not the player join path).
- **Stat rolls live + actually rolling (A3 + 2026-08-03):** `TowerStatResolver` reads each unit's
  `StatRolls` + `Ascension`; Archer + Mage are the `BaseStats` quality-range pilots. Grants now
  ROLL — `PlayerInventoryService.GrantUnit` (explicit `opts.StatRolls` wins) and `DevSetOwnedTowers`
  call `StatGradeConfig.RollAll(rng)` off one persistent `Random` (was hardcoded 0.5). The Lobby's
  `StarterChoiceService` ALSO rolls since 2026-08-03 — **all grant paths now roll.** Existing
  units + the v1→v2 migration stay grandfathered at 0.5 (append-only).
- ~~USER (BLOCKING) publish~~ **DONE 2026-08-06** — both Places were republished together, so the
  whole A-phase is the live build. Still open: a live end-to-end run of the **teleport v2 loop**
  (publishing v2 is not the same as exercising it).
