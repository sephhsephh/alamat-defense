# CONTEXT — Game place ("Alamat Defense - Game")
<!-- owner: game | scope: game | last-verified: 2026-10-21 (B170) | BUDGET 6,000 chars: what the Place IS NOW.
     No history here -- that is CHANGELOG + archive/game-CONTEXT-history.md. -->

The match Place: loads a map, runs waves, towers fight, rewards commit to the profile, teleports back.
Server-authoritative, config-driven, signal-decoupled, `--!strict` throughout.

## Architecture
`SSS.Server.MatchDirector` = lifecycle state machine (WaitingForData → Preparing → Countdown → InProgress →
Victory/Defeat → Cleanup). It delegates maps to `MapLoader`, waves to `WaveDirector` (virtual clock,
`GameSpeed.Scheduler`), enemies to `EnemySpawner`/`EnemyController`, towers to `TowerManager`/`TowerController`,
economy to `EconomyManager`. `ReplicationBridge` boots data services first and is the only script that knows clients
exist (`MatchReplicator`). Big picture: `docs/systems/match-architecture.md`; module map: `match-modules.md`.

## Where things live
- Server: `SSS.Server.{MatchDirector, MatchEntryService, MatchActionHandler, Data, Towers, Enemies, Waves, Economy,
  Inventory, Rewards, Stats, Networking, Map, GameSpeed, Summons, StatusEffects, Settings, Physics, Placement, Meta,
  Events, Admin}`.
- Shared: `RS.Shared.{Signal, Enums, Schema, ProfileTemplate, TowerStatResolver, AttackShapes, PathClearance,
  UnitScale, UnitStatPreview, UIKit.*, VFXLibrary}` + `RS.AlamatUI`. Shared canon list: `shared/manifest.json`.
- Configs: `RS.Configs.{Towers, Enemies, Waves, Stages, Maps, Traits, StatusEffects, Summons, Global, Meta}`
  (`Global.GameConfig` = `LobbyPlaceId`, `TeleportPayloadVersion`). New tower = copy `Configs.Towers._Template`.
- Art: `RS.TowerModels` (full-size rigs, `GameScale`), `ServerStorage.Enemies.Stage1`, `VFXTemplates.Towers.<Id>`,
  `RS.CharacterFX`, `RS.EnemyDeathFX`.
- Remotes: `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}` (+ `CharacterFX`, `AdminBroadcast`).
- UI (authored in StarterGui): `Hotbar`, `HUD` (reference layout), `TowerSelection`, `UnitManager`, Stage Info,
  `BossHealth`, `MatchEndUI`, `UnitsGUI` (Hero Hall, loadout-only), Settings, `LoadingScreen`, `AdminBroadcastGUI`.

## Entry paths
- **Production:** `MatchEntryService` reads `TeleportData.MatchLaunch` (contract v4), validates, starts the match once
  the roster assembles. TeleportData is a request, never truth. `docs/contracts/teleport.md`.
- **Studio:** `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` / `AutoPlaceForEndScreenTest`
  (`docs/systems/studio-testing.md`).
- **Return:** `MatchActionHandler.ReturnToLobby` builds `MatchReturn` v4 and teleports; Replay/Next are votes
  (`match-end.md`).

## Systems → docs
Towers + attacks + passives `tower-authoring.md` · VFX `tower-vfx.md` · hotbar `hotbar.md` · HUD `match-hud.md` ·
selected unit `unit-selection.md` · unit manager `unit-manager.md` · stage info `stage-info.md` · match end
`match-end.md` · audio `match-audio.md` · rewards `rewards.md` · balance + settled calls `balance.md` · challenges
`challenges.md` · map `maps-apolaki.md` · movement `movement.md` · settings `settings.md` · Units screen
`units-screen.md` · loading `loading-screen.md` · Alamat UI `alamat-ui.md` · persistence `save-schema.md`.

## Hazards (one line each; detail in the linked doc)
- `execute_luau` can't `require`, can't press 1-6, has its own service copies → `studio-testing.md`.
- Two difficulty scales: this Place sees only the WIRE 100–1000; ONE conversion `RewardScalingConfig.TFromWire`
  (ADR-0011, `rewards.md`).
- Placement is uuid-addressed; stats come from the SERVER's validated loadout entry; `PlacementValidator.TryPlace` is
  THE placement path (remote + Auto Play) (`match-hud.md`).
- Rewards: a DEFEAT keeps flat pay; a drop routes by `ItemCatalog` `Kind`; uncatalogued ids refused; abort pays
  nothing (`rewards.md`, `balance.md`).
- `PlayerInventoryService.SCALAR_CURRENCIES` mirrors the Lobby's `GrantService` list — add a currency to BOTH
  (`rewards.md`).
- This Place NEVER writes `Data.Battlepass`; BP XP is cleared only after `TeleportAsync` succeeds (`teleport.md`).
- Grants here are UNCAPPED on purpose; unit capacity is the Lobby's `SummonService` only (`unit-capacity.md`).
- Game speed is the one remaining one-party assumption (host-elected) — pending a user design call (`teleport.md`).
- Cash scales by `PresentUserIds` (who arrived), never the roster (`balance.md`).
- A tower `Cost` change = regenerate + re-hash `UnitStatsCatalog` in BOTH Places (`hotbar.md`).
- `StarterGui.Hotbar.ResetOnSpawn` is FALSE on purpose; the slot `UIListLayout` owns positions (`hotbar.md`).
- Tier with no `Attack` inherits the one below; attack weights sum to 1.0; configs name no VFX ids
  (`tower-authoring.md`, `tower-vfx.md`).
- Rigs are stored full R15 size and scaled by `GameScale`; a new unit lives in BOTH Places (CLAUDE.md, §6).
- Knight/Bantong `AnimationTrack limit of 64` spam is pre-existing — ask the user (`tower-authoring.md` §8).
- Keys: binding in the shared `MovementController` requires grepping BOTH Places; hotkeys read `Settings.Keybinds`
  (`movement.md`, `settings.md`).
- `Signal:Fire` handlers run sequentially — never yield in a `MatchEnded` handler; the map survives a match
  (`match-architecture.md`).
- Enemy rigs are server-side, so Stage Info portraits are blank; no stage-pity system exists (`stage-info.md`).
- `UnitManager.Root` position is script-owned at boot; closed positions derive from panel width (`unit-manager.md`).
- Migrations `[2]`/`[3]`/`[4]` are deliberate no-ops; `Reconcile()` does not descend into `Units[uuid]`
  (`save-schema.md`).
