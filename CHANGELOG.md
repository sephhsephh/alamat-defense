# CHANGELOG (append-only; newest first)

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
