# CONTEXT — Game place ("Alamat Defense")
<!-- owner: game | scope: game | last-verified: 2026-07-17 -->

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

## Persistence (schema v1 — see docs/contracts/save-schema.md)

`Server.Data.PlayerDataService` owns ProfileStore sessions; `PlayerInventoryService`
(towers/account/items, + `GrantTower`) and `SettingsService` are profile-backed facades.
Boot order in `ReplicationBridge`: data services first. `[DATA]`/`[CONTRACT]` log lines
confirm profile load + schema version on every boot.

## Key paths

- Server: `SSS.Server.{MatchDirector, MatchEntryService, MatchActionHandler, Data, Towers,
  Enemies, Waves, Economy, Inventory, Rewards, Stats, Networking, Map, GameSpeed, Summons,
  StatusEffects, Settings, Physics}`
- Shared: `RS.Shared.{Signal, Enums, Schema, ProfileTemplate, TowerStatResolver, AttackShapes}`
- Configs: `RS.Configs.{Towers, Enemies, Waves, Stages, Maps, Traits, StatusEffects, Summons, Global}`
  (`Global.GameConfig` = cross-Place ids: `LobbyPlaceId`, `TeleportPayloadVersion`)
- Remotes: `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}`
- Rich legacy docs: `ServerStorage.Documentation.*` (AIState, SystemIndex, HowTo, ...) —
  still valid; migrating to repo `docs/systems/` on touch.

## Entry paths (how a match starts)

- **Production:** `MatchEntryService` (SSS.Server, booted by `ReplicationBridge`) reads
  `TeleportData.MatchLaunch` (teleport contract v1), validates PayloadVersion/StageId/players
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
- `ReturnToLobby` (MatchActionHandler) builds `MatchReturn` v1 and teleports to the Lobby;
  `GameConfig.LobbyPlaceId` SET (83342803778137, 2026-07-18 Integration). NOTE: in Studio
  Play, pressing Lobby now attempts a real TeleportAsync, which fails (pcall'd +
  TeleportInitFailed handled) — expected; real teleports need the published client.
- Enemies.Behaviors (Flying/Splitting/...) is an empty extension point.
- Real-DataStore round-trip test still PENDING (mock verified only).
