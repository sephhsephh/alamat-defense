# CHANGELOG (append-only; newest first)

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
