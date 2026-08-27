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

## Persistence (schema **v4**, PUBLISHED — see docs/contracts/save-schema.md)

`Server.Data.PlayerDataService` owns ProfileStore sessions; `PlayerInventoryService` (uuid-keyed
`Units`/account/items + `GrantUnit`) and `SettingsService` are profile-backed facades. **v4 (B39,
`ProfileTemplate 8e4224b9`) is SHIPPED to both Places, so a new field now costs a v5** — no more free
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
  (drift-checked). `UnitStatsCatalog` is deployed in BOTH Places since A6b, 2026-08-06.)
- **UI kit (AD-UI, shared canon)** — 5 controllers in `RS.Shared.UIKit` + 7 REAL templates in
  `RS.UITemplates.Kit` (ADR-0005) + `StarterPlayerScripts.UIKitBootstrap`. **The Game HOTBAR is on
  it**: `StarterGui.Hotbar` is the Lobby's ScreenGui driven by the shared `UIKit.Hotbar`, the only
  Place difference being `OnActivated` → **start placement**. Editing a kit half in ONE Place is DRIFT
  (`docs/systems/ui-kit.md`, `tools/checklists.md`). Other
  Game screens are still Place-local and script-era. **Drift 25/26 at B26** (`MetaMath` MISSING,
  Phase D, expected). If a Kit template reads odd, ASK THE USER to re-copy it from the Lobby — never
  edit or rebuild it; cross-Place copy is a USER action (`tools/checklists.md` step 2).
  **✅ V2 IS ADOPTED HERE (B26).** The USER pasted `Kit.{UnitIconV2, ItemIconV2, HotbarSlotV2}` in;
  verified by hash, v1 trio **deleted**; the hotbar is the only V2 consumer here (`UIKit.ItemIcon` is
  canon but has no Game consumer).
  **B28: `HotbarSlotV2` root `Size` was `{0.225,0.399}` here vs `{1,1}` in the Lobby — Lobby canonical
  (user), so it is `{1,1}` now and both hash `cd5a2aa0`. THE GAME'S SLOTS RENDER BIGGER; that IS the
  fix. `attach()` clones this master and never overrides Size; `UIAspectRatioConstraint` clamps it to
  the square the Lobby draws. `UIKitMotion` → `a104e59d` (slide; no Game consumer). Canon: `ui-kit.md`.
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
- `ReturnToLobby` (MatchActionHandler) builds `MatchReturn` (v4) and teleports to the Lobby;
  `GameConfig.LobbyPlaceId` SET (83342803778137, 2026-07-18 Integration). The payload version
  comes from `GameConfig.TeleportPayloadVersion` (**=4 since B23**) and MUST equal the Lobby's
  `LobbyConfig.MatchLaunchVersion`; a mismatch is rejected, never downgraded. **v3 and v4 do NOT
  interoperate — republish the two Places TOGETHER.** In Studio Play a real TeleportAsync is
  attempted and fails (pcall'd, `TeleportInitFailed` handled) — expected, not a bug.
- **Counters + Worthiness are WRITTEN (blueprint §6, A8).** One commit per match inside
  `RewardCalculator.GrantForPlayer`; the `Worthiness` cap is enforced INSIDE `WorthinessConfig.Apply`
  so no caller can bypass it. `Counters.Global.Summons` is the one LIVE increment. No schema bump —
  v2 declared all of it. Order of operations + every counter: `docs/systems/rewards.md`.
- **PLACEMENT IS uuid-ADDRESSED END TO END (B0, 2026-08-08).** `RequestPlace` carries a unit
  **uuid**; `PlacementValidator` resolves it with `LoadoutValidator.FindByUuid` against the player's
  own validated loadout and reads every stat off the SERVER's entry — the uuid is a request, never
  truth. `TowerController.Uuid` (+ `UnitUuid` attribute) carries it into combat; `MatchStatsTracker`
  KEYS by uuid; each uuid earns XP + counters from its OWN work. **A8's first-entry rule is GONE** —
  never re-key the tracker by type. Uuid-less towers (direct `PlaceTower`) fall back to TowerId.
- **REWARDS SCALE WITH DIFFICULTY (P5) — `docs/systems/rewards.md` is the canon; read it there.**
  A DEFEAT keeps its flat payout (scaling a loss makes losing on max difficulty the best gold/min).
  **⚠ TWO DIFFICULTY SCALES: UI 1–100 (Lobby only), WIRE `DifficultyPercent` 100–1000 (ADR-0011).**
  This Place sees only the WIRE value and converts it in exactly ONE function,
  `RewardScalingConfig.TFromWire`. Reading a wire 100 as UI 100 turns NORMAL into HARDEST and pays
  max gold silently — never add a second conversion. `matchState` is OPTIONAL and fails SAFE.
- **`RewardScalingConfig` is SHARED CANON (`1d789978`), Game-deployed only.** The Lobby's preview and
  the server's payout must read the SAME curve, so it could not live in `StageConfig`. Each act NAMES
  a curve (`Rewards.GoldCurve`). **`deployed.Lobby = null` → Lobby MISSING is expected, not drift.**
- **INSANE IS LIVE-REACHABLE since B20 (teleport v3).** `DifficultyMode` → `matchState` →
  `RewardCalculator`'s Insane branch. Mode is a SEPARATE axis: it does NOT scale enemy health and
  never enters the wire→t conversion; absent/unknown fails SAFE to Normal. (B41 corrected
  `RewardCalculator`'s own header, which still claimed this branch could not fire live.)
- **TELEPORT v4 (B23) — `IsMatchmade`, and the ONE-PARTY INVARIANT IS REPEALED.** A reserved server
  can hold SEVERAL parties, or strangers with none. `matchState.IsMatchmade` is the flag to branch on
  — **never `PartyId`**. `HostUserId` is an ELECTED host (lowest userId), which this Place already
  fell back to, so both sides agree by construction.
  **ONE one-party assumption with teeth remains: GAME SPEED** — match-wide, authority and the 3× gate
  from the host alone, matchmade an elected stranger. **Unchanged pending a user design call.**
- **SHORT ROSTERS ARE ROUTINE AT v4 — the economy counts who ARRIVED (B23 fix).** `ValidatedPlayers`
  is the payload ROSTER; `matchState.PresentUserIds` is who turned up. `PlayerCountRewardScaling`
  divides kill AND wave cash by the headcount and used to read the roster — a lone survivor of a
  4-player launch played at 0.8× cash. **Never revert `playerCount` to `#userIds`.** The Ready vote
  and `GrantWaveReward` also take `presentUserIds`.
  **⚠ `RewardScalingConfig`'s header comment is STALE** (says the payload has no mode field). Shared
  canon `1d789978`, so the fix re-hashes + redeploys both Places. CODE right, comment wrong.
- **ACCOUNT LEVELLING WORKS AS OF B41 — `AddPlayerXP` is the ONE application path.** It applies
  `PlayerLevelConfig.ApplyXP` and writes BOTH `PlayerXP` and `PlayerLevel`. **`PlayerLevel` is
  authoritative; `PlayerXP` is progress WITHIN the level, never a lifetime total.** From B33 to B41
  it was `data.PlayerXP += xp` alone, because the rollover lived in a LOBBY-ONLY module — so every
  account froze at level 1 and level-gated slots never unlocked. `PlayerLevelConfig` is now SHARED
  CANON (`2e99d041`, manifest **35 → 36**). Old profiles need **no migration**: `ApplyXP` drains a
  backlog on the next grant, no-op if consistent. **⚠ BALANCE, USER'S CALL: L50 = 627,540 XP while
  `LoadoutConfig` gates slot 6 there.** Detail: `docs/systems/rewards.md`.
- **MATCH QUEST COUNTERS (B41).** `InsaneVictories` added (Victory AND Insane). **`Clears` already IS
  "acts cleared"** (a `StageConfig` IS an act), so no `ActsCleared` key was added — two numbers for
  one event is the drift the one-writer rule prevents. Names are a CROSS-PLACE contract: a rename
  strands every quest baseline. `docs/systems/quests.md`.
- **THE THREE SETTINGS ACTIONS ARE WIRED (B41)** — `GameSettingsActions`, no edit to shared-canon
  `SettingsUI`. `ReturnToLobby`/`RestartMatch` fire `RequestMatchAction` so the SERVER keeps the
  teleport-v4 stamp; a client-side teleport would bypass the contract. `settings.md`.
- **`MatchDirector.AbortMatch` (B41) — AN ABORT PAYS NOTHING (user's call).** `MatchEnded` is never
  fired, so no XP/gold/drops/counters and no result recorded; deliberately NOT a Defeat, whose
  consolation would make a restart button farmable. Restarting a live match aborts it first. The flag
  is consumed by the match LOOP, never the caller's thread — racing teardown leaks a wave into the
  next match. `MatchStateChanged` now carries `StageId` (B41).
- **HARNESS GOTCHA — `Signal:Fire` runs handlers SEQUENTIALLY on ONE thread.** A `MatchEnded`
  handler that YIELDS blocks every later handler, including `MatchEndPresenter`, which drives the
  reward/counter commit (A9 burned three runs on this). To inspect post-commit state, `task.spawn`
  the body and return immediately — never `task.wait` inside a Signal handler here.
- A unit at `MAX_META_LEVEL` LOSES stored XP (overflow discarded) — cosmetic, visible on Units.
  `DevSetOwnedTowers` replaces `data.Units` with new uuids, orphaning `Data.Loadout` (fails safe).
- **Stat rolls live + actually rolling (A3+):** `TowerStatResolver` reads each unit's `StatRolls` +
  `Ascension`. **All grant paths ROLL** via `StatGradeConfig.RollAll(rng)` off one persistent
  `Random`. Pre-existing units and the v1→v2 migration stay grandfathered at 0.5.
- Republishing both Places together is STANDING PRACTICE (B25); the live two-client v4 queue run is VERIFIED (user, B38) — do not re-raise.
