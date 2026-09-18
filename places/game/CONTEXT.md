# CONTEXT — Game place ("Alamat Defense")
<!-- owner: game | scope: game | last-verified: 2026-08-17 (B28) -->

The match Place: loads a map, runs waves, towers fight, rewards commit to the profile.
Server-authoritative, registry/config-driven, signal-decoupled. `--!strict` throughout.

## Architecture in one paragraph

`MatchDirector` (SSS.Server) is the lifecycle state machine (WaitingForData → Preparing → Countdown
→ InProgress → Victory/Defeat → Cleanup). It delegates: maps to `MapLoader`, waves to `WaveDirector`
(virtual clock via `GameSpeed.Scheduler`), enemies to `EnemySpawner`/`EnemyController`, towers to
`TowerManager`/`TowerController` (per-tier attacks, passives/abilities/summons), economy to
`EconomyManager`, replication through the single `MatchReplicator` surface wired in `ReplicationBridge`
(the only script that knows clients exist). Configs are data modules under `RS.Configs.*`, auto-scanned.

## Persistence (schema **v8** since B72 — see docs/contracts/save-schema.md)

`Server.Data.PlayerDataService` owns ProfileStore sessions; `PlayerInventoryService` (uuid-keyed
`Units`/account/items + `GrantUnit`) and `SettingsService` are profile-backed facades. **v4 (B39,
`ProfileTemplate 8e4224b9`) is SHIPPED to both Places, so a new field now costs a v5** — **now at v7 (`8f6520b4`, B69): `UnitInstance.Trait` SPLIT into `ActiveTrait` + `StoredTrait`, + per-unit `TraitPity`, + `TraitFilters`. ONLY `ActiveTrait` reaches this Place** — `LoadoutValidator` sends it as the loadout entry's `Trait`, so neither the stat resolver nor `TraitRegistry.GetEffectivePlacementLimit` can ever see a bench trait the player has not equipped. `PlayerInventoryService` migrated 4 sites (`GetUnit`, `GetTrait` -> reads ACTIVE, `GrantUnit`, the dev-seed path); `opts.Trait` stays the caller-facing name because opts is a call argument, not a saved shape. ⚠ **`Migrations[6]` is the first step since v1→v2 with real work: `Reconcile()` does NOT descend into `Units[uuid]`.** **v8 (B72, `d3d4e63c`): top-level `UnitSlotsPurchased` (unit capacity), `Migrations[7]` a NO-OP — proven here `Migrated ... forward 1 step(s) to v8`. The cap is enforced ONLY by the Lobby's `SummonService`; this Place's `PlayerInventoryService` grants stay UNCAPPED on purpose (match rewards overflow).** B73 re-hashed shared `TraitRegistry`/`TraitDefinitions`/`SettingsConfig` here too (Lobby reroll changes; no Game behaviour change — `Icon` is ignored here and the new setting is LobbyOnly). — no more free
additions. **`Migrations[2]` AND `[3]` are DELIBERATE NO-OPs and must stay ones** — `Migrate()` warns
and STOPS at a missing step, stranding every later one. `Migrations[1]` converts v1 on load.
Each unit's `StatRolls` + `Ascension` fold into DMG/RNG/SPA over tier×meta×trait.
Boot order in `ReplicationBridge`: data services first; `[DATA]`/`[CONTRACT]` lines confirm it.

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
  (drift-checked). `UnitStatsCatalog` is deployed in BOTH Places since A6b, 2026-08-06. **B67 `3bb9b140` -> `ff870013`: it now also carries `Costs`/`GetCost(towerId)` = the PLACEMENT price,** because the Lobby has no `TowerConfig` and the shared hotbar must show the same number in both Places. `UnitStatsCatalogValidate` regenerates `Costs` from the live `TowerConfig.Cost` at boot here and errors LOUD on drift -- **change a tower's `Cost` and you MUST regenerate + re-hash the cache in BOTH Places.**)
- **UI kit (AD-UI, shared canon)** — 5 controllers in `RS.Shared.UIKit` + 7 REAL templates in
  `RS.UITemplates.Kit` (ADR-0005) + `StarterPlayerScripts.UIKitBootstrap`. **The Game HOTBAR is on
  it**: `StarterGui.Hotbar` is the Lobby's ScreenGui driven by the shared `UIKit.Hotbar`, the only
  Place difference being `OnActivated` → **start placement**. Other Game screens are still
  Place-local and script-era. **Editing a kit half in ONE Place is DRIFT** — if a Kit template reads
  odd, ASK THE USER to re-copy it from the Lobby, never edit or rebuild it; cross-Place copy is a
  USER action (`ui-kit.md`, `tools/checklists.md` step 2). **V2 IS ADOPTED HERE (B26)** and the v1
  trio is DELETED — do not re-add; the hotbar is its only Game consumer. **THE GAME'S SLOTS RENDER
  BIGGER THAN THE LOBBY'S AND THAT IS THE FIX** (B28): `HotbarSlotV2` root `Size` is `{1,1}`, Lobby
  canonical, `attach()` never overrides Size and `UIAspectRatioConstraint` clamps it. (B26/B28 detail
  + the old 25/26 drift note: CHANGELOG.) **`SettingsUI` re-hashed B65 `7e5a736a` -> `10f3d48c`** (shared canon, mirrored byte-identical here): its HUD `SettingsButton` is reserved before the file's own boot work and **RE-BOUND on every HUD**, because `HUD.ResetOnSpawn = true` re-clones the HUD on respawn and silently kills the old connection. A Lobby-facing bug, but the file is SHARED -- this Place's HUD has no `SettingsButton`, so the lookup never matches and stays silent, exactly as before. **KEYMAP CHANGED B66 (user):** the shared `MovementController` now binds a **DASH to Q in THIS Place**, and a `ContextActionService` bind SINKS the key and marks it `gameProcessed` -- which every `UserInputService` handler here checks. Q was taken TWICE, so it moved: **tower Ability Q -> V** (`TowerSelectionUI`) and **end-screen Return to Lobby Q -> L** (`MatchEndUI`; on-screen buttons unchanged). Game keymap now: Upgrade **E** / Sell **X** / Targeting **T** / AutoUpgrade **Z** / Ability **V** / AutoCast **C** / Rotate-place **R** / Skip wave **G** / Units **F** / hotbar **1-6** / dash **Q** / sprint **Shift**. **⚠ Binding any key in the SHARED controller requires grepping BOTH Places first.** **DOUBLE JUMP is live here too** (both Places, B66). ⚠ B54's rationale for no-dash-in-the-Game (it lets players cross placement zones the match was never balanced for) still stands as the argument against and is kept verbatim in `MovementConfig`; **revert = `DashPlaces.Game = nil`**. **`UIKitHotbar` re-hashed B67 `ef691df9` -> `5b9f9260`:** the slot's `PlacementPrice` is the REAL cost from `UnitStatsCatalog.GetCost` (peso + thousands separators), which **RETIRES B27d's `Motion.SHOW_PLACEHOLDER_PRICES`** -- that showed the TEMPLATE's authored number, identical for every unit and wrong for all of them. No cost entry => the label HIDES; empty/locked slots still show nothing. Verified here: Archer 100 / Necromancer 400 / Warchief 350 / Farm 150. **B68 `5b9f9260` -> `b2287846`: the price PAINTING moved to `UIKit.UnitCard.paintPrice`** (with `UIKitUnitCard` `bd2421c5` -> `bedb105e`) because six LOBBY screens needed the identical lookup + format; this slot now calls the SAME function they do, over the same shared catalog, instead of a second copy that merely agrees. `formatCost` and the `UnitStatsCatalog` require left this file; new dep `Shared.UIKit.UnitCard` (no cycle). Re-proved live after the refactor, same four numbers, and locked slots 5-6 show NO price (the nil path). **`Motion.SHOW_PLACEHOLDER_PRICES` is DELETED (`UIKitMotion` `2d217ede` -> `ed85d82c`) -- this Place's last reader was the line above.** **B71: THE MAP SURVIVES A MATCH.** `MatchDirector` CLEANUP no longer calls `MapLoader.UnloadMap()` (the ERROR path still does — a crashed lifecycle gets a clean slate); `LoadMap` reuses the resident map when the same id is requested and unloads only for a DIFFERENT one. ⚠ **That reuse also prevents a lighting bug**: `snapshotLighting()` captures CURRENT Lighting as the restore baseline, so re-loading a map whose mood is already applied would bake the grade one layer deeper every replay — the fast path skips the snapshot entirely. Proven: after a full match, no `Unloaded map` line, `ActiveMap` still resident (656 descendants), `ActiveEnemies` 0, 6 lighting effects still applied. ⚠ the REUSE branch itself is unproven (no route to a 2nd StartMatch in one session survives the capability sandbox) — it prints `Reusing RESIDENT map` when it fires. **B71 BGM: this Place now has music.** `UIKitSound` `108ef36e` -> `46ab4d7f` — `playBGM` now falls back to `BGM.Default` on an UNASSIGNED id, not just a missing instance (every act slot exists with an empty SoundId, so the old fallback could never fire). `BGM.Default` carries the user's existing track; `Stage1_Act1..3` stay EMPTY and take over when ids are pasted. Verified `BGM 'Stage1_Act1' PLAYING`.
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

- Content: Stage 1 (3 acts), 1 map, 8 towers, 2 enemies, Classic only. Attack anim/VFX/sound asset ids
  are placeholders (slots exist and tolerate nil). Enemies.Behaviors is an empty extension point.
- **B77: THE HOTBAR IS THE USER'S AUTHORED `StarterGui.Hotbar`** (their `NEW Hotbar`, renamed; the old kit hotbar and `Hotbar - old` are DELETED). `HotbarFrame.Slots.HotbarSlot1..6` + `UnitHoverPreviewTemplate` are painted in place by the shared `UIKit.Hotbar`'s new **V3 path** (`b2287846` -> `55c3df63`), and the tier colours come from `TierConfig` (`eee2b3ad` -> `4aa53b25`), which now carries the user's **nine** tiers with the `Stops`/`Rotation` they authored. Hover tweens `InnerStroke`'s gradient to white. Afford/limit dimming goes through `handle.setOverlay`, never `Main`/`BG` (those nodes are gone). ⚠ a LOCKED slot can still hold an entry (the Lobby's auto-loadout fallback over-fills) — the controller must not clear its dim. `docs/systems/hotbar.md`.
- `ReturnToLobby` (MatchActionHandler) builds `MatchReturn` (v4) and teleports to the Lobby (**B75: Replay/Next are VOTES over the finished match's own config, remote `MatchEndVotes`; item preview + results screen in `MatchEndUI` — `docs/systems/match-end.md`**);
  `GameConfig.LobbyPlaceId` SET (83342803778137, 2026-07-18 Integration). The payload version
  comes from `GameConfig.TeleportPayloadVersion` (**=4 since B23**) and MUST equal the Lobby's
  `LobbyConfig.MatchLaunchVersion`; a mismatch is rejected, never downgraded. **v3 and v4 do NOT
  interoperate — republish the two Places TOGETHER.** In Studio Play a real TeleportAsync is
  attempted and fails (pcall'd, `TeleportInitFailed` handled) — expected, not a bug.
- **Counters + Worthiness are WRITTEN (blueprint §6, A8) — AND THE WORTHINESS METER IS NOT A GAP.**
  One commit per match inside `RewardCalculator.GrantForPlayer`; the cap is enforced INSIDE
  `WorthinessConfig.Apply`. Verified A8 AND re-verified A9 (Archer 198 kills → 3.96). Several later
  docs called kills→Worthiness unbuilt; **it has run since A8.** Reaching 100 is TUNING, not a missing
  writer: `PointsPerKill` 0.02 (user's call, reaffirmed B45) ≈ 25–50 matches for a favourite.
  `Counters.Global.Summons` is the one LIVE increment. Full order: `docs/systems/rewards.md`.
- **PLACEMENT IS uuid-ADDRESSED END TO END (B0).** `RequestPlace` carries a **uuid**;
  `PlacementValidator` resolves it against the player's own validated loadout and reads every stat off
  the SERVER's entry — the uuid is a request, never truth. `MatchStatsTracker` KEYS by uuid; each uuid
  earns XP + counters from its OWN work. **A8's first-entry rule is GONE** — never re-key by type.
- **REWARDS SCALE WITH DIFFICULTY (P5) — `docs/systems/rewards.md` is the canon; read it there.**
  A DEFEAT keeps its flat payout (scaling a loss makes losing on max difficulty the best gold/min).
  **⚠ TWO DIFFICULTY SCALES: UI 1–100 (Lobby only), WIRE `DifficultyPercent` 100–1000 (ADR-0011).**
  This Place sees only the WIRE value and converts it in exactly ONE function,
  `RewardScalingConfig.TFromWire`. Reading a wire 100 as UI 100 turns NORMAL into HARDEST and pays
  max gold silently — never add a second conversion. `matchState` is OPTIONAL and fails SAFE.
- **`RewardScalingConfig` is SHARED CANON (`1d789978`), Game-deployed only.** The Lobby's preview and the server's payout must read the SAME curve, so it could not live in `StageConfig`. Each act NAMES
  a curve (`Rewards.GoldCurve`). **`deployed.Lobby = null` → Lobby MISSING is expected, not drift.**
- **INSANE IS LIVE-REACHABLE since B20 (teleport v3).** `DifficultyMode` → `matchState` → `RewardCalculator`'s Insane branch. Mode is a SEPARATE axis: it does NOT scale enemy health and never enters the wire→t conversion; absent/unknown fails SAFE to Normal. (B41 corrected
  `RewardCalculator`'s own header, which still claimed this branch could not fire live.)
- **TELEPORT v4 (B23) — `IsMatchmade`, and the ONE-PARTY INVARIANT IS REPEALED.** A reserved server can hold SEVERAL parties, or strangers with none. `matchState.IsMatchmade` is the flag to branch on
  — **never `PartyId`**. `HostUserId` is an ELECTED host (lowest userId), which this Place already used.
  **ONE one-party assumption with teeth remains: GAME SPEED** — match-wide, authority and the 3× gate
  from the host alone, matchmade an elected stranger. **Unchanged pending a user design call.**
- **SHORT ROSTERS ARE ROUTINE AT v4 — the economy counts who ARRIVED (B23 fix).** `ValidatedPlayers` is the payload ROSTER; `matchState.PresentUserIds` is who turned up. `PlayerCountRewardScaling` divides kill AND wave cash by the headcount and used to read the roster — a lone survivor of a
  4-player launch played at 0.8× cash. **Never revert `playerCount` to `#userIds`.**
  **✅ `RewardScalingConfig`'s stale header FIXED at B43** — `1d789978` → **`5a4cf793`**, comment-only,
  mirrored byte-identical to both Places with the manifest updated. Deferred three times because a
  comment fix in canon costs a re-hash; meanwhile two sessions read it and believed it.
- **ACCOUNT LEVELLING WORKS AS OF B41 — `AddPlayerXP` is the ONE application path.** Applies
  `PlayerLevelConfig.ApplyXP` (SHARED `2e99d041`), writes BOTH fields. **`PlayerLevel` is
  authoritative; `PlayerXP` is progress WITHIN the level, never a lifetime total.** No migration —
  `ApplyXP` self-heals. **⚠ BALANCE, USER'S CALL: L50 = 627,540 XP, slot 6 gates there.**
- **MATCH QUEST COUNTERS (B41).** `InsaneVictories` added (Victory AND Insane). **`Clears` already IS
  "acts cleared"** (a `StageConfig` IS an act), so no `ActsCleared` key was added — two numbers for
  one event is the drift the one-writer rule prevents. Names are a CROSS-PLACE contract: a rename
  strands every quest baseline. `docs/systems/quests.md`.
- **THE THREE SETTINGS ACTIONS ARE WIRED (B41)** — `GameSettingsActions`, no edit to shared-canon
  `SettingsUI`. `ReturnToLobby`/`RestartMatch` fire `RequestMatchAction` so the SERVER keeps the
  teleport-v4 stamp; a client-side teleport would bypass the contract. `settings.md`.
- **`MatchDirector.AbortMatch` (B41) — AN ABORT PAYS NOTHING (user's call).** `MatchEnded` is never fired, so no XP/gold/drops/counters and no result recorded; deliberately NOT a Defeat, whose
  consolation would make a restart button farmable. Restarting a live match aborts it first. The flag
  is consumed by the match LOOP, never the caller's thread — racing teardown leaks a wave into the next match. `MatchStateChanged` now carries `StageId` (B41).
- **BATTLEPASS XP IS EARNED HERE AND APPLIED IN THE LOBBY (B43).** `RewardCalculator` computes it from
  `BattlepassXpConfig` and **ACCUMULATES** across chained acts — it does NOT grant. **THIS PLACE MUST
  NEVER WRITE `Data.Battlepass`** (the Lobby's `BattlepassService` is its one writer). `Abandoned` pays
  0. **Cleared only after `TeleportAsync` SUCCEEDS**, so a failed teleport keeps it. `teleport.md`.
- **THE IN-MATCH HOTBAR DRAWS REAL LOCKS (B43).** `LoadoutAssigned` carries `PlayerLevel`, read from
  the SERVER's profile (a client-supplied level would unlock slot 6 for free); `HotbarController`
  defaults to 1, which LOCKS rather than unlocks if absent. The auto-loadout fallback this exposed
  was **capped to unlocked slots at B44** (`LaunchService.BuildLoadout`).
- **A DROP IS ROUTED BY ITS CATALOGUE `Kind` (B45).** Every drop used to go to `AddItem`
  (`Data.Items[id]`), which is wrong for a CURRENCY — those live in `Data.Currencies[id]`, so one
  would land where nothing reads or spends it and the faucet would merely LOOK wired. `ItemCatalog`
  is the ONE thing that knows which an id is; an **uncatalogued** drop id is refused loudly and
  written NOWHERE (the stance of `GrantService.Grant`'s invariant 4). **`StatRerolls` is catalogued
  (`9be86a5f`) and drops from Insane wins (`e0a3bc2d`)** — C2's faucet, the same one
  `TraitRerollToken` uses. ⚠ `PlayerInventoryService.SCALAR_CURRENCIES` is MIRRORED from the Lobby's
  `GrantService` list and CANNOT be shared — add a scalar currency and **both lists must learn it**.
- **HARNESS GOTCHA — `Signal:Fire` runs handlers SEQUENTIALLY on ONE thread.** A `MatchEnded` handler that YIELDS blocks every later handler, including `MatchEndPresenter`, which drives the
  reward/counter commit (A9 burned three runs on this). To inspect post-commit state, `task.spawn`
  the body and return immediately — never `task.wait` inside a Signal handler here.
- A unit at `MAX_META_LEVEL` LOSES stored XP (overflow discarded) — cosmetic, visible on Units. `DevSetOwnedTowers` replaces `data.Units` with new uuids, orphaning `Data.Loadout` (fails safe).
- **Stat rolls live + actually rolling (A3+):** `TowerStatResolver` reads each unit's `StatRolls` +
  `Ascension`. **All grant paths ROLL** via `StatGradeConfig.RollAll(rng)` off one persistent
  `Random`. Pre-existing units and the v1→v2 migration stay grandfathered at 0.5.
- **WEEKEND RUSH x2 IS APPLIED HERE (B57c, extended B58).** `RewardCalculator.GrantForPlayer` reads the now-SHARED `WeekendRushConfig` (`44c549f0`, manifest 42) and applies `RewardMultiplier` as a FINAL scalar on a **Victory only**: gold + account XP + tower XP + battlepass XP, **and since B58 every DROP's `Count`** -- stage drop-table items, Insane items and the day's challenge FRAGMENTS. The drop scaling sits at the ONE point where all three sources are already in `drops`; ids and `ItemCatalog` Kind routing are untouched, so a doubled CURRENCY still lands in `Data.Currencies` (B45). A DEFEAT is never inflated and rolls no drops. Window is **UTC+8** (user, B58) and SHARED -- changing it means both Places + manifest + re-hash. **B59: THE ITEM BRANCH PRINTS TOO** -- `[DATA] Drop: <id> x<n> -> Data.Items.<id> = <bal>`, the currency line's shape with `Data.Items` named instead; `PlayerInventoryService.AddItem` returns the new stack total so the line can exist (additive, as `AddCurrency`/`AddScalarCurrency` already did). Until then that branch granted SILENTLY and B58 could only prove the drop doubling through `StatRerolls`, the one drop that happens to be a currency -- a grant path invisible in the log is exactly what let B45's mis-routed drop "look wired". Verified live on a 15/15 Insane Victory in the window: `BannerTicket x2`, `TraitRerollToken x2`, `StatRerolls x2`.
- **HARNESSES (B58), both ship OFF.** **B61 made its seed a VARIABLE** -- `DevSeedCount`/`DevSeedMeta`/`DevSeedAscension`/`DevSeedRolls`, each defaulting to the old ceiling (24 / 50 / 3 / perfect) so an unset harness behaves exactly as before. Count takes slots EVENLY SPACED across the 24, never the first N; the guard is `>= 0` because **ascension 0 is the realistic value** and `> 0` would silently seed the default 3. `AutoPlaceForEndScreenTest`'s tower positions were ~260 studs off the path -- the documented cause of A7's "0 damage", sitting in `KnownIssues` uncorrected; fixed to the real `Path_Main` line (z = -250). **B60 gave it `DevStageId`** -- the THIRD knob of that shape, naming the act to run (`"Stage1_Act2"`; empty = Act 1, an unknown id falls back to Act 1 LOUDLY). It had hardcoded `Stage1_Act1` since it was written, so Acts 2/3 were Lobby-launch-only -- exactly the two acts B59 changed, which is how they shipped unplayed. ⚠ `devStageId` sits BELOW the requires unlike its siblings: it is the first to touch a required module (`StageRegistry`) and defined above that `local` it would capture it as a nil GLOBAL. Its start line prints `[lives N | healthScale N]`, and `MatchEndPresenter`'s end line now prints `lives R/M` too -- "Victory" alone cannot tell 3/3 from a 1/3 scrape. `MatchLifecycleSmokeTest` also has **`DevDifficultyMode`** (same shape as `DevMatchModifiers`): set `"Insane"` to reach `RewardScalingConfig.ItemsForMode`'s GUARANTEED item grants without a Lobby launch -- the stage drop table is all chance rolls (0.25/0.08/0.02) and can never prove a drop change. Seeding a WIN on Stage1_Act1 took 24 towers at max meta/ascension/rolls; eight at level 20 cleared 12/15 waves and still lost on lives.
- **`StartingLives` IS 3 FOR EVERY ACT (USER, B59) -- IT IS THE DESIGN, NOT A TEST VALUE.** Three leaked enemies lose the run and ONE leaked boss loses it outright; that falls straight out of the enemy configs (`Grunt.Damage = 1`, `FarmBoss.Damage = 99999` against a 3-life bar) and needs no code. Acts 1/2/3 are **3 / 3 / 3** (Act 1 unchanged; Act 2 `15 -> 3`, Act 3 `10 -> 3`) and `ClassicGameMode.StartingLives` -- the fallback a stage with no field of its own inherits, so the literal default -- went **20 -> 3**, or the next act authored without the field would quietly get seven times every other act's margin. **The reading carried since P5 was BACKWARDS:** the `3` was never the outlier, the `15` and `10` were. `MatchDirector`'s `stageConfig.StartingLives or gameModeModule.StartingLives or 10` is the ONE read and is untouched. **An act is made harder by `BaseHealthScale` (1.0 / 1.6 / 2.4) and its wave list -- never by taking the margin away.** **PLAYED AT 3 LIVES AND BOTH CLEAR (B60):** Act 2 (scale 1.6) and Act 3 (scale 2.4) each went Victory 15/15 **losing NOT ONE life** (3/3; 196,790 and 434,750 damage) at the 24-tower ceiling. No regression -- but that IS the ceiling; **B61 ANSWERED THAT AND IT WAS THE WRONG QUESTION: Act 3 is decided by the BOSS, not by lives.** A realistic loadout leaks NOT ONE grunt in 15 waves, then loses to a single `FarmBoss.Damage = 99999` hit -- every defeat logged exactly ONE `Enemy leaked!` line reading `Lives: 0`. **`StartingLives` is therefore INERT on Act 3 and B59's 10->3 there risked nothing.** 12 twr/meta20/asc0/avg -> Defeat 351,738 dmg | 18/20/0/avg -> Defeat 350,528 (count barely registers) | 12/50/0/avg -> Defeat 366,169 (meta alone does not close it) | 24/50/asc3/perfect -> Victory 3/3 434,750. **B62 ISOLATED IT: ASCENSION IS THE GATE.** vs the 12/50/0/avg baseline (366,169): **+ascension3 -> VICTORY 3/3, 431,153 (+17.7%)**; +perfect rolls -> Defeat, 376,137 (+2.7%). Ascension is worth **6.5x** perfect rolls and is the ONLY single change that converts an Act 3 loss to a win -- Run A won on HALF the towers with AVERAGE rolls, within **0.8%** of B60's max-everything ceiling, so the ceiling was almost all ascension. Ladder off the weakest seed (351,738): meta 20->50 +4.1% (loss) | perfect rolls +2.7% (loss) | **ascension 0->3 +17.7% (WIN)** | 12->24 towers + perfect on top +0.8% (noise). **⚠ ASCENSION DOMINATES EVERY OTHER POWER AXIS COMBINED** (~18% vs ~7%): no ascension = no Act 3 clear, at any level or roll luck, which makes meta levelling and C1/C2 rerolls close to cosmetic against this content. **USER SETTLED IT (B63): INTENDED.** Ascension is meant to be the hard gate and the main chase, with levelling and the C1/C2 rerolls as refinement on top -- **do NOT flatten it**; B62's numbers are the design, not a bug. **Act 3 being a BOSS WALL is also intended (B63)** -- the 15 waves are the warm-up, the Scarecrow King is the test; `FarmBoss.Health`/`Armor`/`99999` stay as they are and the B61 PENDING is closed. It does not change the loss MODE -- it kills the boss before it arrives. Open design question: is Act 3 meant to be a boss check at a ~max-power gate? Levers are `FarmBoss.Health`/`Armor` or the 99999, never lives.
- Republishing both Places together is STANDING PRACTICE (B25); the live two-client v4 queue run is VERIFIED (user, B38) — do not re-raise. 