# Match architecture (GAME place) -- the big picture

<!-- owner: AD-Game | scope: game | migrated B123 (2026-10-07) from the retired in-Studio
     ServerStorage.Documentation (Architecture, GameFlow, GameplaySystems, CodingStandards), written
     2026-07-14..17 and corrected where later sessions changed it. Module-by-module detail:
     match-modules.md. Remotes: match-networking.md. Content recipes: content-howto.md. -->

## Core principles (still binding)
1. **Server-authoritative.** The client asks, the server decides. Ownership, funds, zones, MetaLevel,
   Trait and rewards are resolved on the server (PlayerInventoryService / the profile) -- never trusted
   from a teleport payload or a client request. A payload says WHICH units a player brings; the server
   decides what they are (`LoadoutValidator` is the single choke point).
2. **Data-driven registries.** Towers, enemies, waves, traits, status effects, stages, maps, summons and
   attack shapes are plain config ModuleScripts under `RS.Configs`, each domain fronted by a
   `<Domain>Registry` (Get / Register / GetAll). Adding content = a config + (usually) one registry line.
3. **Signal-decoupled.** Gameplay systems fire `RS.Shared.Signal`s; they never call UI or VFX.
   `ReplicationBridge` is the ONE place gameplay signals are wired to the network, so the whole UI/VFX
   layer can be disabled without touching gameplay.
4. **Single replication surface.** Match state leaves through `MatchReplicator` (one snapshot,
   `MatchStateChanged`, plus `GetMatchSnapshot` for late joiners). Exception by design: enemy health
   rides Instance Attributes (native, delta-compressed) -- a remote per enemy per tick would not scale.
5. **Virtual clock.** All gameplay timing goes through `GameSpeedService.Heartbeat` / `Scheduler`
   (Delay / Interval / Wait), never `task.wait`, so 2x/3x speeds movement, cooldowns, spawns, DoTs and
   countdowns uniformly.
6. **Central step loops.** `EnemySpawner`, `TowerManager` and `SummonManager` each keep one registry and
   step every member once per virtual frame -- not N Heartbeat connections. Spatial partitioning, when
   needed, goes behind these unchanged APIs.

## Subsystems and ownership
| System | Owns |
|---|---|
| MatchDirector | the lifecycle STATE MACHINE + shared team Lives; delegates rules to the GameMode, maps to MapLoader, waves to WaveDirector |
| MapLoader | map clone lifecycle; folder-convention discovery of SpawnPoints / Paths / TowerZones (B120: a Model in TowerZones is a zone); per-map Lighting + Music, snapshot-and-RESTORE on unload |
| WaveDirector / WavePrepService | the wave timeline (overlapping waves, countdown, next-wave info, skip vote -- B116, `match-hud.md`) |
| EnemySpawner / EnemyController | active-enemy registry + step loop / one enemy (movement, health Attribute, effects, death/leak) |
| TowerManager / TowerController | placed-tower registry + step loop, placement limits, footprint overlap / one tower (targeting, attacks, upgrades, buffs, passives, abilities) |
| AttackSequencer / AttackResolver / MeleeMover | the attack timeline (anim, hit markers, projectiles) / damage math / melee model teleport (B119) -- see `tower-authoring.md` |
| RigAnimator | the one place that touches Animators (server-owned rigs replicate natively) |
| CollisionGroups | Towers / Enemies / Players groups, mutually non-colliding; stamps every spawned rig + player |
| EconomyManager | per-player match cash (kill / wave rewards, spend, refunds) |
| StatusEffectManager | Burn / Slow / Stun / Weaken... and their tick loop |
| SummonManager / SummonController | friendly summons walking the REVERSED path (proximity interaction, no physics) |
| PlayerInventoryService | the Game's account writer: units, MetaLevel / XP, traits, currencies, items, counters (ProfileStore profile, shared schema) |
| RewardCalculator / MatchStatsTracker | match-end rewards + Battle Pass EXP accumulator (applied in the Lobby) / per-tower stats, MVP |
| SettingsService | per-player settings (shared canon, `settings.md`) |
| GameSpeedService / Scheduler | the virtual clock + speed |
| NetworkService / MatchReplicator / VFXBroadcaster | remote guard / the snapshot / cosmetic VFX broadcast |

## Boot order
Server: Scripts under `SSS.Server` auto-run. `ReplicationBridge` is the wiring entry point: it calls
`CollisionGroups.Init()` first (groups exist before any rig spawns), requires the systems, `Init()`s the
request handlers (PlacementValidator, TowerRequestHandler, WavePrepService, SettingsService,
AutoUpgradeService -- each binds its own remotes), then connects gameplay Signals to MatchReplicator.
Other handler Scripts (MatchActionHandler, GameSpeedRequestHandler, MatchEndPresenter, UnitsScreenService,
MatchQuestService...) bind their own remotes. A match starts with `MatchDirector.StartMatch(config)`:
in production from `MatchEntryService` (the Lobby's MatchLaunch teleport payload, contract
`docs/contracts/teleport.md`), on Replay / Next Act from `MatchActionHandler`, and in plain Studio Play
from the `MatchLifecycleSmokeTest` harness (seeds every tower into the dev profile).
Client: LocalScripts / modules under `StarterPlayerScripts.Client` + controllers inside StarterGui
screens. They are pure subscribers / requesters with no authority.

## Match lifecycle
`WaitingForData -> Preparing` (profiles awaited, loadouts validated, MapLoader loads the map, economy
init, wave list + health scale resolved) `-> Countdown` (the READY wait -- B125: NO placing; teleporting players arrive, loadouts change on
the Units screen; no timer until the first vote, B124) `-> InProgress` (towers + status effects start; WaveDirector runs;
win/lose polled every 0.25 virtual s) `-> Victory | Defeat` (MatchEnded) `-> Cleanup` (clear enemies /
towers / effects, reset economy, unload map + restore lighting) `-> WaitingForData`.
Lives are SHARED team-wide; only leaks change them; the GameMode lose condition just reads Lives.

## Gameplay behaviour (summary)
- **Towers**: config (`RS.Configs.Towers.<Id>`) + cosmetic rig (`RS.TowerModels.<Id>`, cloned by the server
  and the placement ghost). Attacks are the B78 attack-profile framework -- `tower-authoring.md` is canon
  (the old per-tier `Phases` / `ReleaseTime` model in the Studio docs is superseded). SPA = Seconds Per
  Attack (lower = faster, an INVERTED stat); real cadence = max(SPA, animation length). Range and shapes
  use HORIZONTAL (XZ) distance so tall rigs are never measured out of range.
- **Auto upgrade**: per-tower opt-in + priority, mirrored to Attributes; `AutoUpgradeService` performs at
  most ONE affordable upgrade per player per ~0.5 virtual s via `EconomyManager.TrySpend`.
- **Enemies**: config + rig in `ServerStorage.Enemies`. Health = base x WaveScale(wave) x BaseHealthScale x
  difficulty (x match modifiers). Movement is XZ at a per-rig RestY (feet raycast onto CanCollide ground
  + the model's foot offset) so big and small rigs both stand correctly; facing eases at TurnSpeed.
- **Economy**: per-player wallets on a shared map. Income = kills (to the killer), wave income, Farm
  (`FarmIncome` passive) income; spending = placement + upgrades; selling refunds.
- **Passives / buffs / abilities / elements / support / summons**: opt-in config. Runtime stat changes go
  through `TowerController:AddBuff` (source-keyed, self-expiring) -- never mutate resolved stats.
  Element damage = `Configs.Global.ElementConfig`. `Role = "Support"` towers never fire. Recipes:
  `content-howto.md`; the passive / ability catalogue: `tower-authoring.md`.
- **Progression**: unit MetaLevel 1-100 (`TowerProgressionConfig`, per-tower XPCurveMultiplier; a maxed
  unit BANKS XP since B122); account XP / currencies / items; match-end rewards via RewardCalculator.

## Extension points
New GameMode (implement GetWaveList / GetWinCondition / GetLoseCondition / ModifyEnemyStats /
ModifyRewards / OnMatchStart / OnWaveComplete / StartingLives + a GameModeRegistry line) -- only Classic
exists today. New tower / enemy / trait / status / stage / wave: config + registry line. New map:
duplicate `ServerStorage.Maps._Template` + a MapConfig (auto-registers). New targeting mode: a module in
`Towers.TargetingModes`. New attack shape: `Shared.AttackShapes` + `AttackShapeRegistry`.
`Server.Enemies.Behaviors` is the (still mostly empty) hook folder for enemy behaviours.

## Conventions that bite (from the old CodingStandards; still true)
- `--!strict`, one responsibility per module, a header comment saying what it owns and does NOT own.
- PascalCase modules / functions / public fields, camelCase locals. Logs carry a `[System]` prefix.
- Deep-copy a shared config before a per-instance change; never mutate the shared table.
- Remote handlers go through `NetworkService` (rate limit + validate); RemoteFunctions return a
  `{ Success, Reason }` / `{ ok, reason }` table rather than erroring across the boundary.
- `pcall` around mode hooks and authored callbacks so one bad config cannot crash the match loop.
- Dependency rules: Shared depends on nothing project-specific; Configs are data; the client never
  requires a server module; no gameplay module reaches into UI.
- RIG PIVOT RULE: a moving rig's model pivot must coincide with its PrimaryPart (`PivotOffset =
  identity`) -- controllers read `PrimaryPart.Position` but move with `PivotTo`; a mismatch makes rigs
  climb or sink every frame. Rig prep: `content-howto.md`.

## Communication map
Gameplay system --Signal--> ReplicationBridge --MatchReplicator--> client UI (subscriber).
Client request --Remote--> NetworkService (rate limit + validate) --> handler --> gameplay system -->
Signal --> replication. Enemy health: EnemyController sets an Attribute -> client healthbars read it.
