# Match modules + folders (GAME place) -- where things live

<!-- owner: AD-Game | scope: game | migrated B123 (2026-10-07) from the retired in-Studio
     ServerStorage.Documentation (SystemIndex + FolderStructure, 2026-07), condensed. APIs listed are
     the stable ones; grep the module before relying on a signature. SSS = ServerScriptService.Server,
     RS = ReplicatedStorage, SP = StarterPlayerScripts.Client. Newer systems have their own docs
     (docs/INDEX.md). -->

## Folders (rule of thumb)
Authored data + anything the client needs -> `RS.Configs` / `RS.TowerModels`; server logic ->
`SSS/<domain>`; server-only models (maps, enemies, summon rigs) -> `ServerStorage`; UI -> authored
ScreenGuis in StarterGui + clone-only templates in `RS.UITemplates`; world VFX templates ->
`RS.VFXTemplates` (`tower-vfx.md`).
- `RS.Shared`: Signal, Enums (the string-id vocabulary every registry is keyed by), Schema (trust-boundary
  validation), TowerStatResolver, AttackShapes/* + AttackShapeRegistry, TowerPlacementRules, AbilityList,
  UIKit/*, shared canon modules (`shared/manifest.json`).
- `RS.Configs`: Maps (auto-scanned; `_`-prefixed skipped), Waves, Enemies, Towers, Traits, StatusEffects,
  Stages, Summons, Meta, Global (EconomyConfig, MetaScalingConfig, TowerProgressionConfig, WavePrepConfig,
  SettingsConfig, DifficultyConfig, WaveScalingConfig, PerformanceConfig, ElementConfig...).
- `RS.Remotes/<Domain>`: `match-networking.md`. `RS.ClientEvents`: client-only BindableEvents (B123).
- `ServerStorage`: Maps (per-stage MODELS, `_Template`), Enemies, SummonModels, DevTools, Archive,
  `Documentation_Retired` (the old in-Studio doc set, kept read-only for history since B123).

## Match core (SSS)
- **MatchDirector** -- lifecycle state machine + shared Lives. API: `StartMatch(config)`, `AbortMatch`,
  `GetState`, `GetActiveMatchState` (Config, ValidatedPlayers[uid].Loadout, MapContext, Lives...),
  `IsRunning`; Signals StateChanged / MatchEnded / CountdownTick.
- **ReplicationBridge** (Script) -- boot wiring; also serves `Match.GetLoadout` and fires LoadoutAssigned at Countdown.
- **MatchEntryService** -- production entry from the Lobby's MatchLaunch payload. **MatchActionHandler**
  (Script) -- Return / Restart / Replay / Next (votes); Replay + Next use each player's current saved
  loadout (B123). **MatchEndPresenter** (Script) -- MatchResults. **GameSpeedRequestHandler** (Script).
- **MapLoader** -- `LoadMap`, `UnloadMap`, `GetActiveMapContext` -> `{ MapId, RootModel, SpawnPoints,
  Paths, TowerZones }`. **MapConfigRegistry** auto-scans `Configs.Maps`.
- **MatchLifecycleSmokeTest** (Script, Studio only) -- seeds every tower into the dev profile and starts
  a match; knobs `DevStageId` / `DevDifficultyMode` / `DevMatchModifiers`; loadout = last Units-screen pick.

## Waves / enemies / towers (SSS)
- **WaveDirector** (Signals WaveStarted / WaveIncomePaid / WaveCompleted / AllWavesCompleted /
  EnemyLeaked, UpcomingWave) and **WavePrepService** (countdown + votes, `RequestWaveSkipVote`).
- **EnemySpawner** (`Spawn`, `GetActiveEnemies`, `ClearAll`, `SetHealthScale`) / **EnemyController**
  (`Step`, `Destroy`, Signals Died(ctrl, killerUserId) / ReachedGoal; fields IsDead, Model, Health...).
- **TowerManager** (`PlaceTower`, `SellTower`, `CanPlaceTower`, `WouldOverlap`, `GetActiveTowers`,
  Signals TowerPlaced / TowerSold / TowerUpgraded) / **TowerController** (targeting, attacks, `Upgrade`,
  buffs `AddBuff` / `RecomputeStats`, PassiveHost, abilities `TryActivateAbility(index)`, `OnKill`,
  `HomeCFrame` + `GetPosition()` = placement, never the moving model).
- **AttackProfile / AttackSequencer / AttackResolver / MeleeMover / RigAnimator** -- `tower-authoring.md`.
- **TargetingSystem** + `TargetingModes/*` (First, Last, Strongest, Weakest, Closest, Furthest, Boss,
  HighestHealth, LowestHealth); horizontal (XZ) range gate.
- **PassiveHost / PassiveRegistry**, **AbilityRegistry**, **SummonManager / SummonController**,
  **AutoUpgradeService**, **UpgradeQueueService**, **TowerCombatStats**, **StatSources**.
- **TowerRequestHandler** -- every `Remotes.Towers` request, ownership re-checked.
- **PlacementValidator** -- `Validate`, `TryPlace` (THE placement path for the remote and Auto Play),
  `PushCounts`; zones via `TowerPlacementRules`. **AutoPlayService** places + upgrades for a player.

## Economy / progression / data (SSS)
- **EconomyManager** -- per-player match cash (`AddCash`, `TrySpend`, kill / wave rewards, `Reset`).
- **PlayerInventoryService** -- the Game's account writer: `GetUnit`, `GetAllUnits`, `GrantUnit`,
  `AddTowerXP`, `AddPlayerXP`, `AddCurrency` (Gold), `AddScalarCurrency`, `AddItem`,
  `IncrementGlobalCounter`, `CommitUnitKills`, `GetAccount`, `DevSetOwnedTowers` (Studio).
- **LoadoutValidator** -- `Validate(userId, uuids)` -> entries `{ Uuid, TowerId, MetaLevel, Trait,
  StatRolls, Ascension }`; `FindByUuid`.
- **RewardCalculator** -- match-end compute + commit; Battle Pass EXP accumulator (`TakePending...`,
  `PeekPending...`, `AddPendingBattlepassXP` B123). **MatchStatsTracker** -- per-tower stats, MVP.
- **StatusEffectManager**, **SettingsService** (shared), **UnitsScreenService** (B123), **MatchQuestService** (B123).

## Speed / network (SSS)
**GameSpeedService** (Heartbeat(virtualDt), SpeedChanged, `SetSpeed`), **Scheduler** (`Delay`,
`Interval`, `Wait` on the virtual clock), **NetworkService** (`BindRemoteEvent` / `BindRemoteFunction`,
`GetOrCreateRemote`), **MatchReplicator** (`Push`, `PushCash`, `GetSnapshot`, `Reset`),
**VFXBroadcaster** (cosmetic VFXEvent: TowerFired, AttackShape, DamageNumber, AttackVFX, Projectile,
TowerLifecycle).

## Client (SP) -- pure subscribers / requesters
`Placement/PlacementController` (ghost feet-on-ground at the true cursor point, smoothed display; same
zone rules as the server), `Indicators/*` (RangeIndicator, AttackShapeIndicator, BaseIndicator),
`UI/*` (HUD, HudPanels, TowerSelectionUI, UnitManagerUI, MatchEndUI, WavePrepUI, SpeedControlUI,
BossHealthUI, EnemyHealthbars / SummonHealthbars via FloatingHealthbars, SidePanelBus, SelectionBus,
ScreenFX, UnitSort...), `VFX/*`, `Settings/*` (ClientSettings, Keybinds), `Audio/*`, MovementController.
Screens copied from the Lobby keep their controllers inside their ScreenGui (UnitsGUI, QuestsGUI).
