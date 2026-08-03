# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-03 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the match Place. Healthy, live.
  Persistence on **Beta1_PlayerData** (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `MatchEntryService` is the production entry (reads `TeleportData.MatchLaunch`, waits for
  profiles, then `StartMatch`); `MatchLifecycleSmokeTest` is the Studio fallback and stands down
  when a payload is present. `ReturnToLobby` sends `MatchReturn`. Cross-place ids set both ways
  (`LobbyPlaceId` 83342803778137). Owns tower configs, combat, the stat resolver, match runtime.
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place, live.
  Scene `Workspace.Lobby`; flow = collection → stage select + difficulty → party →
  reserved-server launch, plus `MatchReturn` welcome-back banner + next-act pre-select and the
  first-join starter picker. Serves `GetCollection` (compat fields now UNREAD) and
  **`GetUnitViews`** (the A4/A5 contract: per-uuid tier/level/grades/equipped/favorited, plus
  `Items` counts since A5). `PartyService.buildLoadout` sends unit uuids. UI: Units + Items +
  Collection screens all on the kit / view-model (A4+A5) — see `docs/systems/lobby-ui.md`.
- **Shared canon** (`shared/src` + `manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **9 modules** — `ProfileTemplate`, `PlayerDataService`, `ProfileStore`, `Signal`, `TierConfig`,
  `StatGradeConfig`, `AscensionConfig`, `ItemCatalog` (2026-08-01), and `UnitStatsCatalog`
  (A6, 2026-08-03 — `deployed.Game` only, **Lobby deploy PENDING**, `deployed.Lobby=null`).
  First 8 drift GREEN in both Places.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only).

- **PENDING (USER, BLOCKING):** republish **BOTH** Places — the entire A-phase promotion
  (4 shared Meta configs, the reconciled multi-colour `TierConfig`, `GetUnitViews`) is Studio
  canon and not in git. Live currently runs the pre-promotion build.

- ~~PENDING (AD-Game, review): empty-hotbar hotfix + no-dev-seed harness.~~ **DONE 2026-08-03 (A6)**
  — the profile-wait MOVED from `MatchEntryService` into `MatchDirector.StartMatch` (the one place
  that validates loadouts), so it now guards EVERY caller (entry, restart/next-act, harness, future
  relaunch); `MatchEntryService` simplified. New Studio-only `ColdProfileMatchTest` (attribute
  `Enabled`, default OFF; smoke test stands down when on) starts a match from the REAL loaded
  profile's units — NO dev seed — closing the cold-path blind spot. Both verified live.

- **PENDING (AD-Lobby, A5 handoff):** `docs/proposals/2026-08-03-drop-getcollection-compat.md` —
  (a) delete the `Towers`/`Currency` compat fields from `GetCollection`; as of A5 they have
  **zero readers** (UnitsGUI moved at A4, CollectionScreen rebuilt at A5). (b) Review the
  `Items` field **AD-UI added to `GetUnitViews`** — AD-Lobby canon, edited by AD-UI with the
  user's explicit authorisation because the Items screen had no other count source. Additive,
  read-only, no contract bump.

- **PENDING (NEEDS SCHEDULING — two profile fields have no WRITER):**
  - `Data.Loadout` — nothing ever writes it, so `Equipped` is always false and launches always
    fall through to auto-loadout (top 6 by MetaLevel). Needs a loadout picker UI.
  - `Data.Items` — nothing writes it either (no drop/grant/shop path). The A5 Items screen
    therefore shows every catalog item at count 0. Correct, but the screen is inert until an
    item economy exists.

- ~~PENDING (AD-Game — build the generated `UnitStatsCatalog`, A6).~~ **DONE 2026-08-03** — shared
  `UnitStatsCatalog` (hash `3bb9b140`) carries per-tower resolved base DMG/RNG/SPA; load-bearing
  validator `SSS.Server.UnitStatsCatalogValidate` errors loudly in the Game place on drift
  (verified — caught an injected `Archer.DMG 15→99`). ADR-0003 implemented.
- **PENDING (AD-Lobby / AD-Integration — deploy `UnitStatsCatalog` to the Lobby):** the new 9th
  shared module (`3bb9b140`) is `deployed.Game` only (`deployed.Lobby=null`) — the Lobby drift check
  FAILS until it deploys. THEN AD-UI fills the A5 Units `--` slots from `UnitStatsCatalog.Get`
  (`Stats.BaseStatsFrame.{DMG,RNG,SPA}`); the `Grade` labels beside them already work from the roll.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** persistence round-trip test (never run; profile shape has changed since it
  was raised) and progressive `ServerStorage.Documentation` → `docs/systems/` migration.

## Contracts (current versions)

- Save schema: **v2** (`shared/src/ProfileTemplate.luau`, hash `63a0c98a`) — store
  "Beta1_PlayerData"/"Beta1_PlayerDataDev1". v2 (A1, 2026-08-01) = uuid unit `Units` +
  `Currencies` map + meta fields; `Migrations[1]` converts v1→v2. **Deployed + drift-green in
  BOTH Places** (Game A1, Lobby A2 — both `63a0c98a`).
- Teleport payload: **v2** (`docs/contracts/teleport.md`) — implemented BOTH sides + BOTH
  directions: Lobby sends `MatchLaunch` and consumes `MatchReturn` (banner + next-act pre-select);
  Game receives `MatchLaunch` and returns `MatchReturn`. v2 (A2, 2026-08-01) = `Loadout` carries
  unit uuids; **hard cutover, no migration** — v1 is rejected with `[CONTRACT]`. Version lives in
  `LobbyConfig.MatchLaunchVersion` == `GameConfig.TeleportPayloadVersion` (must always be equal).
  Verified in Studio both sides; both Places **published 2026-08-01** — live re-verification of
  the v2 loop is the open user action (v1 was live-verified end-to-end 2026-07-18).

## Current focus

1. **USER: republish both Places** (A-phase promotion is Studio canon). Live is fine on the
   previous build — the hotfix run was confirmed working — so this is not urgent, but nothing
   from this session reaches players until it happens.
2. ~~**A4 + A5 [AD-UI]**~~ **DONE 2026-08-03** — Units, Items and Collection screens all run on
   the kit + `GetUnitViews`; `UIKit.ItemIcon` + `UIKit.FilterPanel` added; templates consolidated
   into `RS.UITemplates.Kit`; `UnitCatalog` and `StarterGui.UITemplates` deleted. Details in
   `docs/systems/lobby-ui.md`. Compat-field removal handed to AD-Lobby (PENDING above).
3. **A6:** AD-Game portion DONE 2026-08-03 (UnitStatsCatalog + validator, hotfix review,
   cold-profile harness). Remaining: **deploy `UnitStatsCatalog` to the Lobby** (PENDING), then
   AD-UI fills the Units `--` number slots from it + rebuilds the hotbar on the kit.
4. Then A7 (full Phase A acceptance, Integration) → Phase B gacha.
5. Unscheduled but wanted: loadout picker (equipping), an item economy that writes `Data.Items`,
   real art/anim asset ids.

