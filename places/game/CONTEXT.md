# CONTEXT — Game place ("Alamat Defense")
<!-- owner: game | scope: game | last-verified: 2026-08-01 -->

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
  `Meta.{TierConfig, StatGradeConfig, AscensionConfig, ItemCatalog}` = rarity / roll-grade /
  ascension / grantable catalog — **shared canon since 2026-08-01** (drift-checked, both Places))
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
  payload is present, so the two never double-start. `AutoPlaceForEndScreenTest` / `MatchEndVerify`
  exist but are `ENABLED=false`.

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
- Real-DataStore round-trip test still PENDING (mock verified only).
- **Stat rolls live + actually rolling (A3 + 2026-08-03):** `TowerStatResolver` reads each unit's
  `StatRolls` + `Ascension`; Archer + Mage are the `BaseStats` quality-range pilots. Grants now
  ROLL — `PlayerInventoryService.GrantUnit` (explicit `opts.StatRolls` wins) and `DevSetOwnedTowers`
  call `StatGradeConfig.RollAll(rng)` off one persistent `Random` (was hardcoded 0.5). The Lobby's
  `StarterChoiceService` still writes 0.5 until its PENDING lands (proposal 2026-08-03). Existing
  units + the v1→v2 migration stay grandfathered at 0.5 (append-only). Client stat PREVIEWS still
  resolve at rollMult 1.0 until the UI wire-up (A4–A6); server gameplay is roll-correct.
- **USER (BLOCKING):** the A1 service refactors, A2 version flip, and A3 Meta configs + resolver
  are all Studio-canon — publish this Place together with the Lobby (v1/v2 do not interoperate).
