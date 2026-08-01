# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-01 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the playable match Place. Healthy.
  Persistence live; Studio saves go to the separate **PlayerData_Dev** store (verified
  with API access ON, DataStoreState=Access). **Production entry receiver `MatchEntryService`
  built 2026-07-18** (reads `TeleportData.MatchLaunch` → StartMatch); `MatchLifecycleSmokeTest`
  is now the Studio fallback (stands down when a MatchLaunch payload is present). `ReturnToLobby`
  now sends `MatchReturn` v1 + teleports to the Lobby — **`GameConfig.LobbyPlaceId` set
  (83342803778137, verified vs live Lobby PlaceId, 2026-07-18 Integration)**. **Schema v2 landed
  2026-08-01 (A1):** profile `Units` are uuid instances (was towerId `Towers`), `Currencies` map
  (was scalar `Currency`); PlayerInventoryService / LoadoutValidator / RewardCalculator / DevSeed
  refactored to uuids; v1→v2 migration verified. ProfileTemplate hash `63a0c98a`. **Teleport v2
  (A2, 2026-08-01):** `GameConfig.TeleportPayloadVersion = 2` — MatchLaunch loadouts are unit
  uuids; v1 payloads hard-rejected with `[CONTRACT]`. **A3 (2026-08-01):** `RS.Configs.Meta.*`
  (TierConfig / StatGradeConfig / AscensionConfig / ItemCatalog) + Archer/Mage `BaseStats` pilots +
  `TowerStatResolver` reads `StatRolls` × `Ascension`.
- **Lobby** (Studio: "Alamat Defense - Lobby") — **v1 built 2026-07-17**. Data layer drift-free
  (`RS.Shared.{Signal,ProfileTemplate}`, `SSS.Server.Data.{ProfileStore,PlayerDataService}`) +
  `Server.Bootstrap`. Scene: `Workspace.Lobby` blockout hub. Flow: read-only collection screen
  (`LobbyServices` GetCollection/GetStages), stage select + difficulty (`RS.Configs.StageRegistry`
  mirror), party system + reserved-server teleport (`PartyService`, `RS.Configs.LobbyConfig`,
  teleport contract **v2**), **GamePlaceId set (125430066355564, 2026-07-18)**. **MatchReturn
  handling built 2026-07-18** (`MatchReturnService` + `ReturnScreen` banner + StageSelect
  pre-select of `SuggestNextActId`; verified via `[Test]` sim + `[DIAG]`). **Starter tower
  choice + launch-loadout fix 2026-07-18** (`StarterTowerConfig` [dev-editable] +
  `StarterChoiceService` + modal picker). **Schema v2 + teleport v2 landed 2026-08-01 (A2):**
  `ProfileTemplate` v2 deployed (`63a0c98a`, drift-green); `LobbyServices` serves uuid `Units` +
  `Loadout` + `Currencies` (interim `Towers`/`Currency` compat for the not-yet-rebuilt screens,
  remove at A5); `StarterChoiceService` grants uuid UnitInstances; `PartyService.buildLoadout`
  sends uuids (saved `Loadout` first, else auto by MetaLevel).

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only).

- **PENDING (USER ACTION, BLOCKING — before any live play):** save + publish **BOTH** Places
  together. The Game's A1 service refactors and all of A2's Lobby work are Studio-canon, not in
  git. **The live game is mid-cutover:** published servers still run schema v1 + teleport v1, and
  v1/v2 do not interoperate (hard reject by design), so a partial publish breaks live launches
  with `[CONTRACT] PayloadVersion mismatch`.

- ~~PENDING (A3 / AD-Game): Meta configs + BaseStats + resolver reads StatRolls.~~ **DONE
  2026-08-01** — `RS.Configs.Meta.{TierConfig, StatGradeConfig, AscensionConfig, ItemCatalog}`
  created (Game canon; `ItemCatalog.Validate()` at boot via `MetaConfigTest`); Archer + Mage carry
  `BaseStats` quality-range pilots; `TowerStatResolver` folds `StatRolls × Ascension` into
  DMG/RNG/SPA (SPA inverted). Scalar/no-BaseStats towers byte-identical (regression verified).
  Client stat previews still flat (rollMult 1.0) until the UI wire-up (A4–A6).

- **PENDING (A5 / AD-UI):** remove the interim `Towers` / `Currency` compat fields from
  `LobbyServices.GetCollection` once CollectionScreen + UnitsGUI are rebuilt on the kit — they
  are the only remaining readers.

- **PENDING (AD-Integration, BLOCKS A4/A5):** promote `TowerStatResolver` + `StatGradeConfig` +
  `AscensionConfig` + `ItemCatalog` + `TierConfig` from Game canon into `shared/src` (deploy BOTH
  Places, drift-green); reconcile `TierConfig` to A3's shape **+ multi-colour** (Colors list +
  colorSequence/seamlessSequence/isMultiColor + Mythic rainbow / Secret palettes — user-chosen
  2026-08-01); **retire the Lobby interim `UnitCatalog` + interim `TierConfig`**; add the
  `LobbyServices` unitView (resolved DMG/RNG/SPA + grades + tier + equipped/favorited per uuid) and
  remove the interim `Towers`/`Currency` compat. Full spec:
  `docs/proposals/2026-08-01-a4-promote-meta-and-tierconfig-multicolor.md`. Verified this session:
  those 4 modules are ABSENT in the Lobby, so the Lobby cannot resolve stats until this lands.

- **PENDING (AD-UI, AFTER the Integration promotion above):** A4/A5 wire `UnitsController` +
  `HotbarController` to the `LobbyServices` unitView — real DMG/RNG/SPA + grades (replace
  `UnitCatalog` placeholders), tier border from the shared multi-colour `TierConfig`, real
  `Equipped`/`Favorited` driving the grid sort, real per-unit models (replace
  `UnitModels.Placeholder`), and functional action buttons. Formalise kit templates (A5).

- **PENDING (Game):** persistence round-trip test — play, earn rewards, stop, play again, confirm
  the dev profile restored (API access ON; writes verified).

- **PENDING (Game):** in-Studio `ServerStorage.Documentation` is still the richer doc set; migrate
  it into `docs/systems/` progressively (doc-gardening), then retire it to a pointer.

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
  Verified in Studio both sides; **live re-verification pending the user's republish of both
  Places** (v1 was live-verified end-to-end 2026-07-18).

## Current focus

1. **USER: publish BOTH Places together** (A2 landed 2026-08-01 — schema v2 + teleport v2 are
   Studio-canon in both). The live cutover is atomic: v1 and v2 do not interoperate. Then run
   the live loop once (lobby → reserved match → return) and report the console.
2. **AD-INTEGRATION (next session — HARD PREREQUISITE for A4/A5):** execute
   `docs/proposals/2026-08-01-a4-promote-meta-and-tierconfig-multicolor.md` — promote
   `TowerStatResolver` + `StatGradeConfig` + `AscensionConfig` + `ItemCatalog` + `TierConfig`
   into `shared/src`, deploy + drift-green BOTH Places; reconcile `TierConfig` to A3's shape
   PLUS multi-colour (Mythic rainbow, Secret red+dark-red, `seamlessSequence` helper lifted from
   the Lobby interim module); retire the Lobby's interim `TierConfig`/`UnitCatalog`; add the
   `LobbyServices` unitView (resolved DMG/RNG/SPA + grades + tier + equipped/favorited per uuid).
   **Open decision that session must settle with AD-Game** (proposal §1): whether the resolver
   reads `BaseStats` from Lobby-readable tower configs, or a slim BaseStats table is promoted
   alongside it.
3. **A4/A5 [AD-UI]:** only AFTER the above — kit controllers + Units/Items screens consume the
   unitView (real stats/grades/tier, real Equipped/Favorited), which also retires the interim
   `Towers`/`Currency` compat fields.
4. Lobby v2 candidates: gacha/banners (schema v2 + A3 configs have landed — now gated only on
   the promotion above), party polish, currency shop, player-level display, loadout picker UI
   (replaces the interim auto-loadout).
5. Real art/anim asset ids for tower attacks (Game chat).
6. Progressive doc migration from Studio to this repo.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

