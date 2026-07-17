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

- Server: `SSS.Server.{MatchDirector, Data, Towers, Enemies, Waves, Economy, Inventory,
  Rewards, Stats, Networking, Map, GameSpeed, Summons, StatusEffects, Settings, Physics}`
- Shared: `RS.Shared.{Signal, Enums, Schema, ProfileTemplate, TowerStatResolver, AttackShapes}`
- Configs: `RS.Configs.{Towers, Enemies, Waves, Stages, Maps, Traits, StatusEffects, Summons, Global}`
- Remotes: `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}`
- Rich legacy docs: `ServerStorage.Documentation.*` (AIState, SystemIndex, HowTo, ...) —
  still valid; migrating to repo `docs/systems/` on touch.

## Dev harness

`MatchLifecycleSmokeTest` (Studio-only) seeds 8 towers via `DevSetOwnedTowers` (writes into
the profile — mock store unless Studio API access is on) and starts Stage1_Act1 ~3s after
join. `AutoPlaceForEndScreenTest` / `MatchEndVerify` exist but are `ENABLED=false`.

## Current state / known gaps

- Content: Stage 1 (3 acts), 1 map (TestMap), 8 towers, 2 enemies, Classic mode only.
- Attack anim/VFX/sound asset ids are placeholders (slots exist and tolerate nil).
- `ReturnToLobby` only logs — real teleport comes with the Lobby (contract: teleport.md v0).
- Enemies.Behaviors (Flying/Splitting/...) is an empty extension point.
- Real-DataStore round-trip test still PENDING (mock verified only).
