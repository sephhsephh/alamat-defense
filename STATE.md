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

- **PENDING (AD-UI — A3 landed 2026-08-01, ready to wire):** the UI kit shipped interim on v1-shaped view data
  (`UIKit.Button`, hotbar preview, UnitsGUI, TierConfig/UnitCatalog — built + live-verified
  2026-07-31). At the A3 wire-up: real per-unit models (replace `UnitModels.Placeholder`),
  resolved DMG/RNG/SPA (replace UnitCatalog placeholders), real `Loadout`(equipped) +
  `UnitInstance.Favorited` (replace the interim flags driving grid sort + hotbar preview), and
  functional action buttons (Quick Sell / Unequip All / Upgrade / Lock / Equip / View Passives).
  Promote `UIKit`/`TierConfig`/`UnitCatalog` into `shared/src` at A7 if the Game place needs them.

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
2. **A4 [AD-UI]:** icon-kit UnitIcon/ItemIcon/Hover controllers in the Lobby (view-model remotes
   in `LobbyServices`); then A5 Units/Items screens on the kit. A3 landed 2026-08-01 — resolved
   DMG/RNG/SPA + tiers/grades are available now; passing real rolls to the client also fixes the
   interim flat stat previews.
3. Lobby v2 candidates: gacha/banners (gated on Phase A schema v2), party polish, currency
   shop, player-level display, loadout picker UI (replaces the interim auto-loadout).
4. Real art/anim asset ids for tower attacks (Game chat).
5. Progressive doc migration from Studio to this repo.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

