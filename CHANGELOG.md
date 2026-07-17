# CHANGELOG (append-only; newest first)

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
