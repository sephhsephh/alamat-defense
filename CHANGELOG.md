# CHANGELOG (append-only; newest first)

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
