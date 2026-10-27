# CONTEXT — Game place ("Alamat Defense - Game")
<!-- owner: game | last-verified: 2026-10-28 (B175) | BUDGET 6k chars: what the Place IS NOW; history lives in
     CHANGELOG + archive/game-CONTEXT-history.md -->

The match Place: load a map, run waves, towers fight, rewards commit to the profile, teleport back.
Server-authoritative, config-driven, signal-decoupled, `--!strict`.

## Architecture
`SSS.Server.MatchDirector` = lifecycle (WaitingForData → Preparing → Countdown → InProgress → Victory/Defeat →
Cleanup), delegating to `MapLoader`, `WaveDirector` (`GameSpeed.Scheduler` clock), `EnemySpawner`/`EnemyController`,
`TowerManager`/`TowerController`, `EconomyManager`. `ReplicationBridge` boots data services first and is the only
script that knows clients exist. `match-architecture.md`, `match-modules.md`.

## Where things live
- Server `SSS.Server.*` (MatchDirector, MatchEntryService, MatchActionHandler, Data, Towers, Enemies, Waves, Economy,
  Rewards, Placement, Meta, Events, Admin, ...). Shared `RS.Shared.*` (TowerStatResolver, PathClearance, UnitScale,
  UIKit, VFXLibrary, ...) + `RS.AlamatUI`; canon list `shared/manifest.json`.
- Configs `RS.Configs.{Towers, Enemies, Waves, Stages, Maps, Traits, StatusEffects, Summons, Global, Meta}`
  (`Global.GameConfig` = `LobbyPlaceId`, `TeleportPayloadVersion`). New tower = copy `Configs.Towers._Template`.
- Art: `RS.TowerModels` (full-size rigs), `ServerStorage.Enemies.Stage1`, `VFXTemplates.Towers.<Id>`, `RS.CharacterFX`.
- Remotes `RS.Remotes.{Placement, Towers, Match, Economy, Combat, Settings}`.
- Authored UI: `Hotbar`, `HUD`, `TowerSelection`, `UnitManager`, Stage Info, `BossHealth`, `MatchEndUI`, `UnitsGUI`
  (Hero Hall, loadout-only), Settings, `LoadingScreen`.

## Entry paths
- Production: `MatchEntryService` reads `TeleportData.MatchLaunch` (v4) — a request, never truth (`teleport.md`).
- Studio: `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` / `AutoPlaceForEndScreenTest` (`studio-testing.md`).
- Return: `MatchActionHandler.ReturnToLobby` → `MatchReturn` v4; Replay/Next are votes (`match-end.md`).

## Docs
Towers `tower-authoring.md` · VFX `tower-vfx.md` · hotbar `hotbar.md` · HUD `match-hud.md` · selection
`unit-selection.md` · manager `unit-manager.md` · stage info `stage-info.md` · audio `match-audio.md` · rewards
`rewards.md` · balance `balance.md` · challenges `challenges.md` · maps `maps-apolaki.md` (Stage 1), `maps-bakunawa.md`
(Stage 2 map; smoke knob `DevMapId`) · Stage 2 acts/roster `stage2-bakunawa.md` · movement `movement.md`.

## Hazards (detail in the linked doc)
- `execute_luau` can't `require` or press 1-6 and has its own service copies (`studio-testing.md`).
- Only the WIRE difficulty 100–1000 reaches here; ONE conversion, `RewardScalingConfig.TFromWire` (`rewards.md`).
- Placement is uuid-addressed off the server's loadout; `PlacementValidator.TryPlace` is THE path (`match-hud.md`).
- Drops route by `ItemCatalog` `Kind`; DEFEAT pays flat; abort pays nothing (`rewards.md`, `balance.md`).
- `SCALAR_CURRENCIES` mirrors the Lobby's `GrantService` list — add a currency to BOTH (`rewards.md`).
- Never write `Data.Battlepass`; BP XP clears only after `TeleportAsync` succeeds (`teleport.md`).
- Grants are UNCAPPED here; unit capacity is the Lobby's `SummonService` only (`unit-capacity.md`).
- Game speed is the last one-party (host) assumption, pending a user call (`teleport.md`).
- Cash scales by `PresentUserIds`, never the roster (`balance.md`).
- Tower `Cost` change = regenerate + re-hash `UnitStatsCatalog` in BOTH Places (`hotbar.md`).
- Hotbar `ResetOnSpawn` is FALSE on purpose; its `UIListLayout` owns slot positions (`hotbar.md`).
- A tier with no `Attack` inherits; weights sum to 1.0; configs name no VFX ids (`tower-authoring.md`).
- New unit = both Places, full R15 size, `GameScale` (CLAUDE.md). Knight 64-track spam: ask the user.
- Binding a key in the shared `MovementController` = grep BOTH Places first (`movement.md`).
- Never yield in a `Signal` handler; the map survives a match (`match-architecture.md`).
- Enemy rigs are server-side (blank Stage Info portraits); no stage pity exists (`stage-info.md`).
- `UnitManager.Root` position is script-owned at boot (`unit-manager.md`).
- `Migrations[2..4]` are deliberate no-ops; `Reconcile()` skips `Units[uuid]` (`save-schema.md`).
