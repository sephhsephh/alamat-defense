# CHANGELOG (append-only; newest first)

## 2026-08-01 [integration/hotfix] LIVE BUG: empty hotbar in production matches — profile-load race before loadout validation

**Symptom (user, first live teleport-v2 run):** teleported into the match with NO units in any
hotbar slot, could not place anything, lost the match.

**Root cause — a race, not bad data.** `MatchEntryService` waited only for the party to be
*present* (`Players:GetPlayerByUserId`) and then called `MatchDirector.StartMatch`, which
validates loadouts SYNCHRONOUSLY via `LoadoutValidator` → `PlayerInventoryService.GetUnit` →
`getData(userId)`. When a profile has not finished loading, `getData` returns a deep copy of the
EMPTY `ProfileTemplate.Template` (`Units = {}`) — indistinguishable from "this player owns
nothing". So every loadout uuid was dropped as `NotOwned` and the player entered with an empty
hotbar. In a **reserved server the players are already present when the service boots**, while
ProfileStore still needs a DataStore round-trip — so losing this race is the DEFAULT live
outcome, not an edge case.

**Why Studio never caught it (A1/A2/A3 all passed):** the Studio entry path is
`MatchLifecycleSmokeTest`, which calls `DevSetOwnedTowers` — that populates the in-memory
stand-in synchronously *before* starting, so the profile is never actually raced. Every Studio
verification exercised a pre-seeded path. The production path had never once run with a real
cold profile. Note this is the SECOND live-only failure of the same symptom (2026-07-18 was
`Loadout={}` from the Lobby); both were invisible to Studio for the same structural reason.

- **Fix (`MatchEntryService`):** new `waitForProfiles(userIds)` runs AFTER `waitForParty` and
  BEFORE `StartMatch`, awaiting `PlayerDataService.WaitForData` per player
  (`PROFILE_LOAD_TIMEOUT = 20`). Logs `[MatchEntry] [DATA] All N profile(s) loaded (waited Xs)`.
  On timeout it does NOT wedge the match — it starts anyway but `warn`s loudly with the affected
  userIds (old behavior, now audible).
- **Fix (`PlayerInventoryService.getData`):** the silent empty-template fallback now `warn`s
  once per userId outside Studio (`profile NOT loaded … ownership check WILL report zero units`),
  so this failure class can never be invisible again. Diagnostic only — no behavior change; the
  Studio dev-seed path deliberately still uses the fallback.
- **Verified (Studio):** Game boots clean, `MetaConfig OK`, smoke-test path unchanged (the new
  wait is only on the MatchLaunch entry path), match reaches Countdown, no errors. **The real
  proof is the next live run** — Studio structurally cannot reproduce the race.
- **OWNERSHIP NOTE:** `MatchEntryService` + `PlayerInventoryService` are **AD-Game** canon
  (`Match lifecycle` row). Edited from the AD-Integration chat on explicit user instruction
  ("fix that") because the bug was blocking live play and was surfaced by the v2 rollout this
  chat landed. **PENDING for AD-Game: review this hotfix.** Design question left open for the
  owner: whether the wait belongs in `MatchDirector.StartMatch` itself (protecting every caller)
  rather than only the production entry path.
- **Contract impact:** none. No schema, payload, or shared-module change; manifest untouched.
- **Studio noise seen once:** client `WaitForChild` "Infinite yield possible" lines on one Play
  start; all ten StarterGui screens verified present + Enabled — Studio replication lag, not a
  regression.

## 2026-08-01 [game] Schema v2 wiring (blueprint A3): Meta configs + BaseStats pilots + resolver reads StatRolls

- **New `RS.Configs.Meta` (Game canon; promote to shared at A7):** `TierConfig` (Common→…→Bathala
  order + colors/sortorder), `StatGradeConfig` (D C B A S SS SSS Apex thresholds + `RollStat`/`RollAll`),
  `AscensionConfig` (MaxLevel 3, MinTier Mythic, absolute per-level DMG mults A1 ×1.05 → A3 ×3 +
  `PerTower` override + `GetMult`/`GetCost`), `ItemCatalog` (13 entries: 8 towers tier-assigned +
  Gold/Silver + BannerTicket/TraitRerollToken/GoldenSeed, `Tradeable=false`, `Validate()`).
  New Studio-only `MetaConfigTest` runs `ItemCatalog.Validate()` at boot.
- **BaseStats pilots:** Archer + Mage gain top-level `BaseStats = { DMG/RNG/SPA = {Min,Max} }`
  quality-multiplier ranges (strength; higher = stronger). Other towers have none (flat 1.0).
- **`TowerStatResolver` reads rolls (the A3 fix):** new optional `statRolls` + `ascension` params.
  For DMG/RNG/SPA it folds a per-unit quality multiplier `rollStrength (Min+(Max-Min)*roll) ×
  AscensionMult` into the existing tier×meta×trait pipeline — multiplied for normal stats, DIVIDED
  for the inverted SPA (so roll 1.0 = fastest). Default (no BaseStats / nil roll / asc 0) = 1.0, so
  scalar towers are byte-identical. Threaded: `LoadoutValidator` entry (+Uuid already; now +StatRolls
  +Ascension from the unit) → `PlacementValidator` → `TowerManager.PlaceTower` → `TowerController`
  (stored; re-resolved on upgrade). `ResolveNextTier` passes them through.
- **Scope (blueprint-faithful):** compose model chosen with the user = quality multiplier (least
  invasive, preserves balance). NOT in A3 (later phases): teleport/loadout already v2 (A2); Counters/
  Worthiness increments; UI kit wiring (A4–A6) — so client stat PREVIEWS still resolve at rollMult 1.0
  for now (server gameplay is roll-correct). Combat/placement/`MatchStatsTracker` unchanged (§7).
- **Verified:** resolver unit tests — scalar tower (Knight) asc 0 byte-identical with/without rolls;
  Archer roll 0.5 == old; roll 0/1 moves DMG ±15% and SPA (roll 1 faster); ascension 3 = ×3 DMG;
  Necromancer asc 2 = ×1.5 DMG; `ItemCatalog.Validate` ok (0 errors). Play-test — `schema v2` boot,
  `[Test] MetaConfig OK (13 entries, 8 tiers)`, profile v2 loaded, match to Countdown, no errors.
- **Contract impact:** none — save schema stays **v2** (StatRolls already in the v2 shape; A3 only
  reads them). No shared-module (manifest) change; all A3 code is Game Studio canon.
- **PENDINGs:** A3 CLEARED. Next: A4/A5 (AD-UI) wire the kit to resolved stats + real rolls. The
  BLOCKING user publish PENDING now also covers A3's Game changes (publish Game + Lobby together).

## 2026-08-01 [integration] A2: schema v2 to the Lobby + teleport contract v2 (uuid loadouts) — Phase A unblocked

Blueprint `phase-a-foundations.md` §2 + §9 A2. Both Places driven in one session (AD-Integration).

- **ProfileTemplate v2 → Lobby:** deployed verbatim from `shared/src` (`184cdfad → 63a0c98a`,
  hash computed in-Studio == manifest == Game). `manifest.deployed.Lobby` updated;
  **drift check now GREEN in BOTH Places** for all four shared modules.
- **Lobby v2 reads (Studio canon):**
  - `LobbyServices.GetCollection` serves uuid-keyed `Units` (TowerId/MetaLevel/XP/Trait/Shiny/
    StatRolls/Ascension/Worthiness/Locked/Favorited/ObtainedAt), `Loadout`, `Currencies` and
    `PlayerLevel`. **Interim compat:** it also still returns `Towers` (collapsed to the highest-
    MetaLevel instance per TowerId) and `Currency` (= Gold) so the not-yet-rebuilt CollectionScreen
    + UnitsGUI keep working — **remove both at A5** (new PENDING; they are the only readers).
  - `StarterChoiceService`: eligibility is now `Units` empty; the grant writes a uuid
    `UnitInstance` mirroring the Game's `PlayerInventoryService.GrantUnit` (mid rolls 0.5 until
    A3), returns the `Uuid`, and the sim-tower self-heal scans by `TowerId`.
  - `PartyService.buildLoadout`: returns **uuids** — the saved profile `Loadout` filtered to
    still-owned uuids (deduped, capped at `MaxLoadoutSize`), else auto-loadout by MetaLevel desc.
- **Teleport contract v1 → v2** (`docs/contracts/teleport.md`, version history + shapes updated).
  Only change: `Players[uid].Loadout` carries unit uuids. `LobbyConfig.MatchLaunchVersion = 2`
  and `GameConfig.TeleportPayloadVersion = 2`; `MatchReturnService` now READS its expected version
  from `LobbyConfig` instead of a hardcoded `1` (one integer covers both directions).
  **Hard cutover, no migration:** both Places deploy together, so v1 is rejected, never fallen back
  to. Game-side code needed no logic change — `MatchEntryService` already passed `Loadout` through
  to `LoadoutValidator` (uuid-aware since A1); only the version constant + comments moved.
- **Verified (Studio, both Places):**
  - Game boot: `[DATA] PlayerDataService ready (schema v2)`, `[CONTRACT] Profile v2 loaded`
    (Beta1_PlayerDataDev1, Access), `[MatchEntry] Ready`, match reaches Countdown, no errors.
  - `BuildRawConfig` unit tests: v2 accepted (uuids preserved, string→numeric userId keys), **v1
    rejected** (`[CONTRACT] PayloadVersion mismatch: got 1, expected 2`), unknown stage rejected,
    difficulty 999999 → 1000.
  - Lobby boot: `[CONTRACT] Lobby boot: save-schema v2`, `MatchReturn v2 receiver`, `teleport
    contract v2`, UI kit + hotbar + Units controllers all init clean, no compile errors.
  - Live remote reads: `GetCollection` → 8 uuid Units (rolls present) + compat layer intact;
    real `RequestLaunch` → `[DIAG] Launch loadout: [6 uuids]` then `[Teleport] launch failed:
    HTTP 403` (expected — Studio cannot ReserveServer).
  - Starter grant path (`DevSimulateFirstJoin`): offer eligible → granted uuid
    `945f74d5-…` with the exact GrantUnit field set; next clean boot self-healed the sim unit
    (`[Test] removed leftover SimTestTower`) and correctly reported ineligible. Sim attribute OFF.
- **Contract impact:** teleport **v1 → v2** (no migration — atomic cutover). Save schema
  unchanged at v2; shared module deployed, not edited (manifest `deployed.Lobby` only).
- **PENDINGs:** A2 CLEARED. NEW — **USER must publish BOTH Places together** (live is mid-cutover;
  a partial publish breaks launches with a version mismatch). NEW — A5 removes the compat fields.
  Carried: A3 (resolver reads StatRolls), persistence round-trip, Studio-doc migration.
- **Note:** STATE.md was over its 100-line cap; resolved PENDINGs were trimmed out (history lives
  here) — now 102 lines.

## 2026-08-01 [game] Schema v2 (blueprint A1): uuid unit instances + Currencies map + migration

- **Contract change — save schema v1 → v2** (owner AD-Game, `docs/blueprints/phase-a-foundations.md`
  A1). `ProfileTemplate` (SCHEMA_VERSION=2): towerId-keyed `Towers` → uuid-keyed `Units`
  (UnitInstance: TowerId/MetaLevel/XP/Trait/Shiny/StatRolls/Ascension/Worthiness/Locked/Favorited/
  SpiritUuid/ObtainedAt); scalar `Currency` → `Currencies` map (Gold/Silver/TraitRerolls/StatRerolls/
  EventTokens); added PlayerLevel/Loadout/Pity/Counters/Quests/LoginStreak/ShopStock/Titles/Spirits/
  Battlepass. `Migrations[1]` converts v1→v2 (Currency→Gold, each Towers entry→a Units instance with
  mid rolls 0.5, Loadout={}); Reconcile fills the rest; account XP/items/settings preserved. STORE_NAME
  stays Beta1_PlayerData(Dev1).
- **Game service uuid refactor (Studio canon):** `PlayerInventoryService` now Units/uuid-keyed
  (`GetUnit`/`GetAllUnits`/`GrantUnit`/`GetFirstUnitId`, `Owns` by TowerId across instances,
  `AddTowerXP(userId, uuid)`, `AddCurrency`→`Currencies.Gold`, `DevSetOwnedTowers` seeds instances +
  returns a towerId→uuid map; back-compat `GetOwnedTower`/`GrantTower` shims kept). `LoadoutValidator`
  validates **uuid** lists (entry now carries `Uuid`; `FindEntry` stays by TowerId). `RewardCalculator`
  commits tower XP by **uuid** + reads `Currencies.Gold`. Smoke test + `MatchActionHandler` build uuid
  loadouts; `MatchEndVerify` updated. **Combat / placement / MatchStatsTracker unchanged** (§7): stats
  stay towerId-keyed and the uuid is resolved from the loadout at the commit boundary.
- **NOT in A1 (later phases, by blueprint):** StatRolls resolver + BaseStats ranges (A3), teleport v2
  uuid loadouts (A2), Counters/Worthiness increments + UI (later). StatRolls persist now but the
  resolver ignores them until A3.
- **Deploy/verify:** drift-clean before edit (Game+disk `184cdfad`). ProfileTemplate edited Studio +
  `shared/src` byte-identical → new hash **`63a0c98a`** (python fnv1a == Studio). `manifest.json`:
  hash + `deployed.Game` → `63a0c98a`; **`deployed.Lobby` left `184cdfad` (STALE)**. Verified:
  migration unit test (Currency 80→Gold 80, 2 Towers→2 Units mid-rolls, Loadout={}, XP/items kept);
  Play-test — `[DATA] PlayerDataService ready (schema v2)`, smoke seeded 8 Units, `[DIAG]` loadout
  5 uuids → 5 validated / 0 rejected, `AddTowerXP` by uuid ok, match to Countdown, no errors. Temp
  `[DIAG]` removed after.
- **Contract impact:** save schema **v1 → v2** (migration shipped).
- **PENDINGs:** NEW (A2 / AD-Integration): deploy ProfileTemplate v2 to Lobby (Lobby drift FAILS
  until then), fix Lobby compile to read Units/Loadout, flip teleport v2 (uuid loadouts) both sides,
  e2e. THEN USER republishes both Places. Note: Game service refactors are Studio-canon (not git) —
  **USER must save/publish the Game place**.

## 2026-07-31 [lobby] AD-UI: reusable Button kit + hotbar preview + Units screen + Tier system

- **`UIKit.Button`** (`ReplicatedStorage.Shared.UIKit.Button`, client) — ONE reusable button
  controller replacing per-button scripts. Hover (scale from centre via `centerAnchor`, stroke
  thicken OR `HoverStrokeColor`, icon rotate), press animation, seamless (tiled) animated
  gradient. Attribute-driven; API attach/create/onActivated/onHover/setHovered/setText/setIcon/
  setStrokeColor/setEnabled. Tag-based bootstrap `StarterPlayerScripts.UIKitBootstrap` attaches
  any `UIKitButton`-tagged GuiButton (tags copy to clones).
- **Hotbar** rebuilt on the kit (`Hotbar.HotbarController`): single controller, old duplicated
  per-slot scripts disabled; fixes the random-glow bug (root cause: N copied scripts + overlap).
  Shows `Hotbar.Templates.UnitPreviewTemplate` on hover.
- **Units screen** (`StarterGui.UnitsGUI.UnitsController`): opens from HUD Units; loads owned
  units (v1 `GetCollection`); tier-coloured card border + BG (animated seamless); hover → white
  border + centre-scale + right-side `UnitPreviewTemplate` popup (name/tier/DMG-RNG-SPA + model);
  click → `SelectedUnitFrame` framed viewport + Stats (reusing the preview design); sort
  equipped>favourited>tier(high→low)>name; live search; placeholder model
  `ReplicatedStorage.UnitModels.Placeholder`. Action buttons animation-only.
- **Tier system (editable):** `RS.Configs.Meta.TierConfig` (tier → colour list; one = solid,
  many = seamless animated gradient — Mythic rainbow, Secret red→dark-red) + `UnitCatalog`
  (towerId → Tier + placeholder DMG/RNG/SPA + optional Equipped/Favorited). Verified live in Play.
- **HUD buttons** (`HUD.Left.Buttons.*`) tagged + animated; `Frame.BorderDesignInside` hidden;
  hover = white stroke (no thicken).
- **Constitution compliance:** all UI is REAL instances (Studio-editable); controllers only
  clone/fill/wire. UI kit + configs are **Studio (Lobby) canon** for now (per hybrid model);
  documented here + in `places/lobby/CONTEXT.md`. Proposal `docs/proposals/2026-07-31-ui-kit-button-primitive.md`
  (Button primitive) is now IMPLEMENTED interim; user-directed (approved live).
- **Contract impact:** none (no schema/teleport change; reads existing `GetCollection`).
- **PENDINGs:** deferred to schema v2 / A3 — real per-unit models, resolved DMG/RNG/SPA, real
  Loadout(equipped)+Favorited, functional action buttons; promote `UIKit`/`TierConfig`/`UnitCatalog`
  to `shared/src` at Integration if the Game place needs them. **USER: save + republish the Lobby.**
- **Open threads:** commit is LOCAL (push pending). Studio place must be saved by the user
  (Studio-canon code is not in git).

## 2026-07-31 [lobby] Drift reconcile: ProfileTemplate store rename (Beta1 reset) — Lobby+disk done, Game PENDING

- **Bootstrap drift check (AD-UI session, Lobby active) caught a mismatch:** live Lobby
  `ProfileTemplate` = `184cdfad`, disk/manifest = `8ac5d3e9`. STOPPED per constitution.
- **Cause (user-confirmed):** intentional **beta data reset** — `STORE_NAME` changed
  `"PlayerData" → "Beta1_PlayerData"` and the Studio dev suffix `"_Dev" → "Dev1"` (dev store
  `PlayerData_Dev → Beta1_PlayerDataDev1`), done directly in the Lobby Studio. No other diff;
  `SCHEMA_VERSION` stays 1, `Towers = {}` unchanged — store target change, no data-shape
  change, no migration.
- **Reconciled the ledger to reality:** disk `shared/src/ProfileTemplate.luau` edited to the
  beta store name (re-hashed to **`184cdfad`**, python fnv1a32 == the Studio drift hash, i.e.
  byte-identical to the live Lobby source). `manifest.json` hash → `184cdfad`,
  `deployed.Lobby → 184cdfad`. `docs/contracts/save-schema.md` store-name line updated with a
  dated note. `deployed.Game` LEFT at `8ac5d3e9` (stale) on purpose — see below.
- **Ownership note:** `ProfileTemplate` is AD-Game canon; this reconcile was done by the AD-UI
  chat under an explicit user directive ("do whatever prevents future problems") to correct a
  stale/dangerous ledger. AD-Game still owns the formal contract re-verification.
- **Contract impact:** save schema stays **v1** (store target only). **CRITICAL PENDING
  (AD-Game + USER):** the Game place was NOT connected this session, so its store name is
  UNVERIFIED. If Game still points at `PlayerData` while Lobby points at `Beta1_PlayerData`,
  the two Places read DIFFERENT stores (split-brain — lobby and match see different profiles).
  AD-Game must open the Game place, deploy the same store name, verify `184cdfad`, set
  `manifest.deployed.Game = 184cdfad`.
- **Open threads:** UI-kit Button/PlayerLevelBar proposal (2026-07-31) still FOR REVIEW.
  Hotbar glow bug not yet investigated (read-only inspection to follow this reconcile).

## 2026-07-18 [game] ProfileTemplate: remove seeded starter Archer (Towers = {}) — starter choice unblocked

- **Shared-module change (owner AD-Game):** `ProfileTemplate.Template.Towers` seed
  `{ Archer = { MetaLevel = 1, XP = 0 } }` → `{}`, per proposal
  `docs/proposals/2026-07-18-starter-choice-template.md`. Fresh accounts now own zero towers, so
  the Lobby's first-join starter choice (eligibility = zero owned) actually fires.
- **No `SCHEMA_VERSION` bump** — default-value change only, no shape change, no migration.
  Existing profiles keep their `Towers.Archer` (`Reconcile()` only ADDS missing keys, never removes).
- **Scope decision:** the blueprint (phase-a A1) had folded this into the schema-v2 session and
  marked the standalone proposal "superseded"; **user explicitly chose the standalone unblock now**
  (this session). A1 will re-touch `Towers` when it migrates to uuid `Units` — no conflict.
- **Drift/deploy:** disk canon + `manifest.json` updated to new hash **`8ac5d3e9`**; source edited
  byte-identical in both Places. Deployed to **BOTH Game and Lobby** (both live sources verified
  `8ac5d3e9` via `.Source`; cache-free "no Archer seed / `Towers = {}`" source check on Game).
  `manifest.json` `deployed` = both `8ac5d3e9`; drift-clean, no stale Place.
  - **Place-binding note (process):** the Studio instances had restarted between sessions and the
    active instance was **Lobby** at the start of this task; the first edit landed on the Lobby
    before I re-resolved binding. Caught via the doc-mirror step, re-confirmed both instances by
    name + PlaceId, then deployed the identical change to Game. Net result is a valid both-Places
    deploy (AD-Game owns shared-module deploys to both), so no rework beyond correcting the manifest
    `deployed` map. Lesson: re-resolve Place binding at the TOP of every task, not just first boot.
- **Docs:** `save-schema.md` new-profile defaults + version history updated (still v1).
- **Contract impact:** save schema stays **v1** (default change only).
- **PENDINGs:** starter-seed PENDING CLEARED. No Lobby redeploy needed (already deployed).
  USER: republish both Places + re-run the live loop (fresh-account picker + towers-in-match).

## 2026-07-18 [repo] Implementation blueprints for all meta phases + blueprint discipline

- NEW `docs/blueprints/phase-a-foundations.md`: schema v2 EXACT shape (unit instances,
  Currencies, Counters, ...) + 1→2 migration steps + starter-seed removal folded in +
  teleport v2 + TierConfig/StatGradeConfig/AscensionConfig/ItemCatalog shapes + base-stat
  ranges & resolver formula (SPA inverted) + icon-kit templates/controller APIs + counters
  pipeline + phase acceptance + session plan A1–A7 with owners.
- NEW `docs/blueprints/phases-b-f-meta.md`: MetaMath (deterministic slot rotation),
  GrantService (single grant pipeline), exact summon algorithm order, per-phase config
  shapes + session plans (B1–F5) + cross-phase invariants checked at Integration.
- Constitution: new "Blueprint discipline" section (blueprints are law; one session-task
  per session; no improvisation; proposal when blocked). Feature prompt updated to match.
- ROADMAP + INDEX link the blueprints.
- **Contract impact:** none yet — blueprints PRE-authorize schema v2 & teleport v2 shapes;
  the A1/A2 sessions execute them under the normal contract protocol.
- **Open threads:** starter-seed PENDING is folded into blueprint task A1 (supersedes the
  standalone proposal); persistence round-trip test still open.

## 2026-07-18 [lobby+repo] Constitution: no UI in scripts; StarterChoiceScreen rebuilt as instances

- **New constitution rule (USER-ordered; recorded here as the authorization for an AD-Lobby
  session touching AD-Integration's repo canon):** NEVER generate UI in scripts. UI = real
  Instances in StarterGui (Studio-editable); dynamic lists = designed `*Template` instance
  (Visible=false) cloned by the controller; controllers do behavior only. Added to
  CLAUDE.md editing rules. Legacy script-built screens are converted when next touched.
- **StarterChoiceScreen converted first:** static tree now real instances —
  `Root{Dim, Panel{Title, Subtitle, CardsRow{CardTemplate}, ConfirmButton}}`; CardTemplate
  is the designed card (NameLabel/TaglineLabel/DescLabel/SelectButton + Sel stroke).
  Controller rewritten to clone/fill/wire only (no Instance.new for visuals).
- **Verified live (Play):** sim ON — Root visible, 4 cards cloned from template
  (Archer/Knight/Mage/SimTestTower), grant path OK; sim OFF — silent boot, sim tower
  auto-cleaned. Sim left OFF.
- **Legacy screens still script-built** (convert when next touched): CollectionScreen,
  StageSelectScreen, PartyScreen, ReturnScreen (Lobby); Game-place screens per AD-Game/AD-UI.
- **Contract impact:** none. **PENDINGs:** unchanged (AD-Game ProfileTemplate starter-seed
  removal still open — user confirmed live test still auto-grants Archer, as expected).

## 2026-07-18 [lobby] Starter tower choice (first join) + launch loadout fix; LIVE e2e confirmed by user

- **LIVE e2e CONFIRMED (user, production client):** lobby → reserved match → return →
  MatchReturn Defeat banner all worked. The Integration session's live-e2e USER PENDING is
  **CLEARED**. The defeat exposed a real bug (below).
- **Launch loadout fix:** `PartyService` sent `Loadout = {}` in every `MatchLaunch`, so
  players entered matches with ZERO placeable towers (Game-side the loadout is the hotbar
  cap — LoadoutValidator, max 6, read-only peek at Game). Now `buildLoadout(userId)` sends
  owned towers (highest MetaLevel first, then alphabetical), capped by new
  `LobbyConfig.MaxLoadoutSize = 6`. Interim until a loadout-picker UI lands. `[DIAG]` logs
  each player's sent loadout at launch.
- **Starter tower choice (first join):** new dev-editable `RS.Configs.StarterTowerConfig`
  (Archer/Knight/Mage; edit that one file to change the offer), new
  `SSS.Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`,
  new modal `StarterGui.StarterChoiceScreen` (3 cards, select + confirm, no dismiss).
  Eligibility = profile owns ZERO towers. Grants `{MetaLevel=1, XP=0}` straight into the
  shared profile; never clobbers an existing record; rejects ineligible/unknown picks.
- **[Test] harness:** `DevSimulateFirstJoin` attribute forces the offer in Studio + adds a
  sim-only "SimTestTower" card to exercise the real grant path; leftover sim tower is
  auto-removed on any non-sim boot. Left OFF.
- **Verified live (Play, dev store):** sim ON — offer shown (4 cards), SimTestTower granted
  (`[DATA] granted starter`), owned Archer pick skipped (no clobber), out-of-offer
  Necromancer rejected, launch `[DIAG]` loadout = 6 towers (Archer first), real teleport
  attempt failed handled in Studio (expected). Sim OFF — silent boot, leftover sim tower
  auto-removed (`[Test]`).
- **Contract impact:** none — teleport stays v1 (payload shape unchanged; Loadout now
  actually populated). Save schema untouched THIS session, but see PENDING.
- **PENDINGs:** NEW (AD-Game): remove seeded starter Archer from `ProfileTemplate`
  (`docs/proposals/2026-07-18-starter-choice-template.md`) — until it lands, fresh accounts
  auto-own Archer and the picker stays inert (by design, data-driven eligibility).
  Integration live-e2e PENDING cleared (above).

## 2026-07-18 [integration] First Integration session: drift-clean both Places, LobbyPlaceId verified, teleport loop config-complete

- **Drift check BOTH Places:** all four shared modules (ProfileTemplate, PlayerDataService,
  ProfileStore, Signal) hash-match `shared/manifest.json` in Game AND Lobby. Zero drift.
- **PENDING cleared — `GameConfig.LobbyPlaceId`:** found already set to **83342803778137**
  in the Game Place; verified equal to the live Lobby instance's `game.PlaceId`. Stale
  "STUBBED 0" comment cleaned (comment-only edit, mirrors last session's Lobby cleanup).
  Teleport loop is now CONFIG-COMPLETE on both sides (Game=125430066355564, Lobby=83342803778137).
- **`[CONTRACT]` verification, Game (Play):** `[MatchEntry] Ready (waiting for MatchLaunch
  teleport data)`, smoke-test fallback single-started Stage1_Act1, `[DATA] [CONTRACT] Profile
  v1 loaded` (PlayerData_Dev, DataStoreState=Access), no contract warnings.
- **`[CONTRACT]` verification, Lobby (Play, DevSimulateReturn ON→OFF):** `[CONTRACT] Lobby
  boot: save-schema v1`, `[DATA] [CONTRACT] MatchReturn v1 accepted (Victory Stage1_Act1 →
  suggest Stage1_Act2)`, ReturnScreen banner + StageSelect pre-select `[DIAG]`s all fired.
  Sim attribute returned to OFF.
- **Cross-Place e2e:** NOT run — real TeleportAsync is impossible in Studio. New USER-ACTION
  PENDING: publish both Places, run the live loop in the Roblox client (lobby → reserved
  match → return → banner).
- **Note (Game, Studio Play):** with LobbyPlaceId set, pressing Lobby in Studio Play now
  attempts a real teleport and fails handled (pcall + TeleportInitFailed) — expected.
- **Contract impact:** none. Teleport stays v1; no shared-module changes; manifest untouched.
- **Open threads:** live e2e (user, above); persistence round-trip test (Game); progressive
  Studio-doc migration. Push pending (commit is local).

## 2026-07-18 [lobby] MatchReturn v1 handling + GamePlaceId set (teleport loop Lobby-side complete)

- **GamePlaceId set:** `RS.Configs.LobbyConfig.GamePlaceId = 125430066355564` (found already set
  in Studio this session — stale STUB comment cleaned). The Lobby-side USER-ACTION PENDING is
  **CLEARED**; real launches now go all the way through ReserveServer + TeleportAsync.
- **MatchReturn v1 receiver:** new `SSS.Server.Lobby.MatchReturnService` (Script). Reads
  `Player:GetJoinData().TeleportData.MatchReturn` on join, validates PayloadVersion==1 /
  LastStageId / Outcome∈{Victory,Defeat,Abandoned} (`[CONTRACT]` warn + ignore on mismatch),
  drops `SuggestNextActId` unknown to the Lobby's StageRegistry mirror (stale mirror fails
  safe), serves per-player via new `Remotes.GetMatchReturn` RemoteFunction. Display-only:
  never mutates the profile (rewards were committed Game-side per the contract).
- **Welcome-back UI:** new `StarterGui.ReturnScreen` banner — outcome (Victory/Defeat/
  Abandoned), stage name, CONTINUE button (only on Victory with a valid successor) + BACK TO
  LOBBY. CONTINUE fires new client bus `RS.ClientEvents.OpenStageSelect` (BindableEvent).
- **StageSelect pre-select:** `StageSelectScreen.Controller` now listens to `OpenStageSelect`
  (opens panel + selects stage) and silently pre-selects `SuggestNextActId` after loading
  stages, so the picker lands on "continue the campaign".
- **Studio harness:** `DevSimulateReturn` attribute on MatchReturnService fabricates a
  Victory/Stage1_Act1→Act2 payload in Studio (`[Test]` log) since real return teleports can't
  happen in Studio. Left OFF.
- **Verified live (Play):** with sim ON — `[Test]` + `[DATA] [CONTRACT] MatchReturn v1 accepted`,
  `[DIAG] StageSelect: pre-selected suggested next act Stage1_Act2`, `[DIAG] ReturnScreen:
  showing MatchReturn banner (Victory)`; CONTINUE path → `[DIAG] StageSelect: OpenStageSelect
  pre-selecting Stage1_Act2`, panel visible, button text "CONTINUE: Rising Legend (Stage 1 -
  Act 2)". With sim OFF — clean boot, no banner, no [DIAG] (silent path confirmed).
- **Contract impact:** none — teleport stays **v1** (Lobby now consumes `MatchReturn`; no shape
  change). No shared-module change; manifest untouched (drift check clean at bootstrap).
- **PENDINGs:** Lobby GamePlaceId CLEARED. Remaining for end-to-end: USER sets
  `GameConfig.LobbyPlaceId` (Game side), then the first AD-Integration session
  (lobby → reserved match → return → banner).

## 2026-07-18 [game] Teleport handoff Game-side: MatchLaunch receiver + real ReturnToLobby

- **Production entry receiver:** new `SSS.Server.MatchEntryService` (ModuleScript, booted by
  `ReplicationBridge` after the data services). Reads `TeleportData.MatchLaunch` (teleport
  contract **v1**) off join data, validates PayloadVersion==1 / StageId∈StageRegistry / Players,
  converts JSON string userId keys → numeric, sanitizes DifficultyPercent (`DifficultyConfig`),
  resolves map/mode/difficulty from the stage, waits for the party to assemble (10s timeout),
  and calls `MatchDirector.StartMatch` **exactly once**. Trust stance per contract: TeleportData
  is a request — loadout ownership + host authority are re-checked downstream (LoadoutValidator /
  MatchDirector). Pure `BuildRawConfig(payload)` exported + unit-tested (valid/reject/clamp cases).
- **Smoke test → Studio fallback:** `MatchLifecycleSmokeTest` still auto-starts Stage1_Act1 in
  Studio, but now stands down when a MatchLaunch payload is present, so the two never double-start.
- **Real ReturnToLobby:** `MatchActionHandler` now builds the `MatchReturn` v1 payload
  (PayloadVersion, LastStageId, Outcome, SuggestNextActId — next act only on a Victory with a
  successor) and `TeleportService:TeleportAsync` back to the Lobby. Guarded on
  `GameConfig.LobbyPlaceId==0` (logs `[Teleport]` + skips, mirroring the Lobby's GamePlaceId guard);
  wrapped in pcall + listens to `TeleportInitFailed`.
- **New `RS.Configs.Global.GameConfig`** — cross-Place counterpart to LobbyConfig:
  `TeleportPayloadVersion=1`, `LobbyPlaceId=0` (stubbed), `HasLobbyPlace()`.
- **Verified:** BuildRawConfig unit tests pass (string→numeric keys, [CONTRACT] rejects for bad
  version / unknown stage / no players, difficulty clamp 999999→1000 & nil→100, MatchReturn
  next-act rule). Play-test: `MatchEntryService` boots + stands down with no teleport data, smoke
  fallback starts the match, single start, no warnings.
- **This Game place id = `125430066355564`** (for the Lobby's `LobbyConfig.GamePlaceId`).
- **Contract impact:** none — teleport stays **v1** (Game is the consumer; no shape change).
- **PENDINGs:** receiver PENDING CLEARED. NEW (USER ACTION): set `GameConfig.LobbyPlaceId` to the
  real Lobby place id. Still open: user sets `LobbyConfig.GamePlaceId=125430066355564` (Lobby side);
  persistence round-trip test; Studio Documentation migration.

## 2026-07-18 [repo] Meta-systems design approved + ROADMAP v2 + constitution advisory

- Meta-systems proposal (docs/proposals/2026-07-18-meta-systems-design.md) reviewed and
  APPROVED with decisions: apex tier **Bathala**; secret rate ~0.005%; dupes → **Ascension**
  (1 dupe + artifacts, or sell for Silver); stat grades **D C B A S SS SSS + Apex**;
  everything untradeable at launch.
- ROADMAP.md rewritten: current Game/Lobby/Cross-Place status + phased meta roadmap
  (A Foundations: schema v2/unit instances + ItemCatalog + icon kit → B Gacha → C Unit
  depth → D Economy loops → E Seasonal → F Endgame/social).
- OWNERSHIP.md: added AD-UI (ItemCatalog/TierConfig/icon kit), AD-Meta, expanded
  AD-Gacha/AD-Traits rows.
- CLAUDE.md landing checklist step 8: mandatory session-end USER ADVISORY (new PENDINGs +
  which chat acts next, other-Place staleness, git push reminder, user personal actions).
- **Contract impact:** none yet — but Phase A = schema v2 + teleport v2 (unit-instance
  uuids); AD-Game owns that migration; no meta work may start before it lands.
- **Open threads:** MatchLaunch receiver + GamePlaceId PENDINGs still open (unchanged).

## 2026-07-17 [lobby] Lobby v1 scene/flow: blockout, collection, stage select, party teleport

- **Blockout:** `Workspace.Lobby` hub (gold plaza + "alamat" sun emblem, pillars, title wall,
  COLLECTION/PLAY wayfinding pedestals); spawn repositioned onto the plaza; modest lighting/atmosphere.
- **Read-only collection screen** (proves profile sharing end-to-end): `Server.Lobby.LobbyServices`
  wires `GetCollection`/`GetStages` RemoteFunctions (READ-ONLY against the profile). Client
  `StarterGui.CollectionScreen` lists owned towers (MetaLevel/XP/Trait). Verified live: returned the
  same PlayerData_Dev profile the Game seeded (8 towers incl. Archer Lv100/Godly, Mage/Blitz, ...).
- **Stage select + difficulty:** Lobby-local mirror `RS.Configs.StageRegistry` (Stage1_Act1..Act3,
  NextActId chaining, difficulty 1–1000). `StarterGui.StageSelectScreen` = stage list + draggable
  difficulty slider capturing (StageId, DifficultyPercent).
- **Teleport handoff (contract v1):** finalized `docs/contracts/teleport.md` v0→v1 — reserved
  (private) server per party, party assembly carried in the `MatchLaunch` payload, `PayloadVersion=1`.
  `RS.Configs.LobbyConfig.GamePlaceId` **stubbed 0** (user to fill). `Server.Lobby.PartyService`:
  in-memory parties (invite/accept/leave, host-only launch, max 4) + `ReserveServer` +
  `TeleportToPrivateServerAsync`; guarded on GamePlaceId==0. `StarterGui.PartyScreen` = party UI
  (members, invite, incoming-invite prompt, leave). Verified live: solo party assembles, launch
  path validates stage + sanitizes difficulty and hits the guard (logs `[Teleport]` would-launch).
- **Contract impact:** teleport payload **v0 draft → v1** (owner AD-Lobby). Save schema unchanged (v1).
- **PENDINGs opened:** (1) user sets `LobbyConfig.GamePlaceId`; (2) AD-Game builds the production
  receiver: read `TeleportData.MatchLaunch` (v1) → validate → `MatchDirector.StartMatch` (replaces
  the Studio-gated smoke test as the non-Studio entry path).

## 2026-07-17 [lobby] First AD-Lobby session: shared-module deploy + boot + Signal promotion

- **Shared deploy (Lobby):** created `ReplicatedStorage.Shared` (Signal, ProfileTemplate) and
  `ServerScriptService.Server.Data` (ProfileStore, PlayerDataService). Sources deployed
  verbatim from `shared/src/`; hashes verified against the manifest via `tools/hash_shared.luau`
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39, ProfileStore 1e3a6f3f, Signal 91becf7a).
  `manifest.json` `deployed.Lobby` filled for all four. No drift.
- **Signal promoted to shared canon:** Signal (a `PlayerDataService` dependency) previously
  lived only in the Game place. Added `shared/src/Signal.luau` (byte-identical to the live
  Game source, 91becf7a), registered it in `manifest.json` (owner: game, covered by the
  shared/src deploys row in OWNERSHIP.md), and added it to `tools/hash_shared.luau`'s MODULE
  list so drift checks now cover it. Game already runs this exact Signal (deployed 91becf7a,
  re-verified live this session).
- **Boot:** new `Server.Bootstrap` (Script) requires ProfileTemplate + PlayerDataService,
  asserts the save contract, and calls `PlayerDataService.Init()`. Verified live in Play mode:
  `[CONTRACT] Lobby boot: save-schema v1, store=PlayerData_Dev` and
  `[DATA] [CONTRACT] Profile v1 loaded for SuperiorBeing_S (store=PlayerData_Dev, DataStoreState=Access)`.
  Confirms the Lobby shares the same schema-v1 profile + dev store as the Game place.
- **Contract impact:** none — save schema still v1 (no shape change); teleport still v0 draft.
- **Open threads:** Lobby v1 scene work next (blockout spawn → read-only collection screen →
  stage select + difficulty → teleport handoff, which finalizes `teleport.md` v0→v1 and adds a
  PENDING for the AD-Game receiver). The Lobby shared-module deploy PENDING is now CLEARED.

## 2026-07-17 [game+repo] Dev-store separation + multi-chat constitution + GitHub prep

- **Dev store:** `ProfileTemplate.GetStoreName()` → "PlayerData_Dev" whenever
  `RunService:IsStudio()`; PlayerDataService uses it. Studio playtests/dev seeds can no
  longer touch production data. Verified live with API access ON:
  `store=PlayerData_Dev, DataStoreState=Access`. Shared canon + manifest rehashed
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39; Game deployed, Lobby still PENDING).
- **Constitution v2:** chats now bound to SYSTEMS (not Places); Place binding resolved at
  bootstrap via `list_roblox_studios` + name confirmation ("Alamat Defense - Game" /
  "Alamat Defense - Lobby"); new multi-chat sync rules (changelog = event bus, re-read
  STATE+changelog before landing, single-writer, no simultaneous same-Place editing).
  New `docs/OWNERSHIP.md` registry (UI, Gacha, PlayerLevel, TowerModels, Enemies, Traits...).
- **Places:** Lobby place created on Roblox (empty); Studios renamed accordingly.
- **Contract impact:** save-schema doc updated with the dev-store rule (still v1 — shape
  unchanged, only store selection).
- **Open threads:** Lobby shared-module deploy still PENDING; persistence round-trip test.

## 2026-07-17 [game] ProfileStore adoption (schema v1) + bug fixes + repo bootstrap

- **Persistence:** adopted ProfileStore (loleris). New `Shared.ProfileTemplate` (SCHEMA_VERSION=1,
  store "PlayerData"; Data = {SchemaVersion, PlayerXP, Currency, Items, Towers, Settings};
  starter Archer Lv1). New `Server.Data.PlayerDataService` (session lock, Reconcile+Migrate,
  ProfileLoaded/Released signals, kick on failed session). `PlayerInventoryService` and
  `SettingsService` rewritten profile-backed with unchanged public APIs; new
  `GrantTower(userId, towerId, trait?)`. Old `PlayerSettings_v1` DataStore retired.
  `ReplicationBridge` boots data services first. Verified live (mock store; clean boot,
  dev-seed merge, match start).
- **Fixes:** MatchDirector `---__--!strict` typo (strict now active); WaveDirector
  unknown-PathId now releases `waveOutstanding` + ForceResolve (auto-advance can't wedge);
  `MatchLifecycleSmokeTest` gated `RunService:IsStudio()`.
- **Cleanup:** Workspace clutter (sample rigs, template, imports) → `ServerStorage.Archive`;
  ProfileStore module Workspace → `Server.Data`.
- **Repo bootstrap:** this repository created; shared canon seeded (ProfileTemplate,
  PlayerDataService, ProfileStore) with verified matching hashes (see `shared/manifest.json`);
  constitution, contracts, contexts, ADRs 0001–0002 written.
- **Contract impact:** save schema v1 established (first version — no migration needed).
  PENDING: Lobby deploy on creation; real-DataStore round-trip test.
- **Open threads:** in-Studio Documentation set still to migrate; teleport contract at v0 draft.
