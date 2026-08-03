# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-03 -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place.

## Current live state

- **Data layer deployed & drift-free.** `ReplicatedStorage.Shared.{Signal, ProfileTemplate}`,
  `ServerScriptService.Server.Data.{ProfileStore, PlayerDataService}` — all four hashes match
  `shared/manifest.json` (Signal 91becf7a, **ProfileTemplate 63a0c98a**, PlayerDataService
  613f0d39, ProfileStore 1e3a6f3f). `Signal` was promoted into `shared/src` 2026-07-17.
- **Boot:** `Server.Bootstrap` asserts the save contract and runs `PlayerDataService.Init()`.
  **Schema v2** profile loads from **Beta1_PlayerDataDev1** (prod store **Beta1_PlayerData**;
  intentional beta reset 2026-07-31; DataStoreState=Access) — the Lobby shares the Game
  place's profile (both Places verified at hash 63a0c98a, A2 2026-08-01).
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza.
- **Flow:**
  - **`GetUnitViews` (2026-08-01, the A4/A5 contract):** per owned uuid the server sends
    `Uuid, TowerId, Name, Tier` (both from the shared `ItemCatalog`), `Level, XP, Trait, Shiny,
    Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls` and
    `Grades = {DMG,RNG,SPA}` letters from `StatGradeConfig` — plus `Loadout`, `Currencies`,
    `PlayerXP/PlayerLevel`, `MaxLoadout`. **No resolved DMG/RNG/SPA and no XpPct** (deferred —
    see STATE PENDINGs). Clients never read profiles; render this view only.
  - **`GetUnitViews.Items` (A5, 2026-08-03):** the same remote also returns the profile's
    `{ [itemId] = count }` map (copied, defensive if absent) for the Items screen. Additive and
    read-only; no contract bump. **Nothing WRITES `Data.Items` in either Place**, so it is
    legitimately empty today. Added by AD-UI with the user's authorisation — it is AD-Lobby
    canon, flagged for review in `docs/proposals/2026-08-03-drop-getcollection-compat.md`.
  - Collection (`Server.Lobby.LobbyServices` `GetCollection`, `StarterGui.CollectionScreen`) —
    READ-ONLY owned units. **Schema v2 (A2):** serves uuid-keyed `Units` + `Loadout` +
    `Currencies` + `PlayerLevel`. It ALSO still returns interim `Towers` + `Currency`, but as of
    **A5 those have ZERO readers** (UnitsGUI moved at A4, CollectionScreen at A5) — deleting them
    is AD-Lobby's call, see the proposal above + the PENDING in STATE.md.
  - Stage select + difficulty (`RS.Configs.StageRegistry` mirror, `GetStages`,
    `StarterGui.StageSelectScreen`) — captures (StageId, DifficultyPercent).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`) — teleport contract **v2** (A2, 2026-08-01: `Loadout` carries unit
    **uuids**; version from `LobbyConfig.MatchLaunchVersion`, must equal the Game's
    `GameConfig.TeleportPayloadVersion`). `buildLoadout` = saved profile `Loadout` filtered to
    still-owned uuids, else auto by MetaLevel desc, capped at `MaxLoadoutSize`.
    `GamePlaceId` = **125430066355564** (set 2026-07-18); launch path complete and verified.
  - **MatchReturn handling (2026-07-18; v2 since A2):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (expected version read from `LobbyConfig`, not hardcoded;
    validates version / Outcome / stage; drops
    unknown `SuggestNextActId` — stale mirror fails safe), serves it via `Remotes.GetMatchReturn`
    (read-only). `StarterGui.ReturnScreen` = welcome-back banner (outcome + stage; CONTINUE on
    Victory-with-successor fires `RS.ClientEvents.OpenStageSelect`). `StageSelectScreen` listens
    and pre-selects the suggested next act (also silently on load). Studio harness: toggle the
    `DevSimulateReturn` attribute on MatchReturnService (`[Test]` log).
  - **Starter tower choice (2026-07-18):** dev-editable `RS.Configs.StarterTowerConfig`
    (currently Archer/Knight/Mage — edit that file to change the offer),
    `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`,
    modal `StarterGui.StarterChoiceScreen` (no dismiss; REAL instance tree per the
    no-UI-in-scripts rule — `Root.Panel.CardsRow.CardTemplate` is the editable card design,
    controller clones/fills/wires only). Eligibility = profile owns ZERO **units** (v2 template
    ships no starter, so fresh accounts always see it). Grants a uuid `UnitInstance` mirroring
    the Game's `PlayerInventoryService.GrantUnit` (MetaLevel/XP from config; **StatRolls via
    shared `StatGradeConfig.RollAll` off one module-level Random, 2026-08-03** — grant log
    prints rolls + grades) and returns its `Uuid`; never clobbers an existing instance;
    Studio harness = `DevSimulateFirstJoin` attribute (sim-only grant-path card,
    self-cleaning by TowerId).
  - **Loadout at launch (v2 since A2):** `PartyService.buildLoadout` sends unit **uuids** —
    the saved profile `Loadout` (filtered to still-owned uuids, deduped) if any, else
    auto-loadout by MetaLevel desc, capped at `LobbyConfig.MaxLoadoutSize=6`. Auto is interim
    until a loadout-picker UI writes `Data.Loadout`; `[DIAG]` logs the sent loadout.

Run the constitution's bootstrap ritual + `tools/hash_shared.luau` at the start of every
session; reconcile before any work if a shared hash drifts.

## UI kit + screens (AD-UI)

Full detail moved to **`docs/systems/lobby-ui.md`** at A5 (2026-08-03) — this file hit its
150-line cap. Short version: REAL instance templates in `ReplicatedStorage.UITemplates.Kit`
(`Button`, `ItemIcon`, `ItemHoverCard`, `FilterPanel`, `UnitPreviewTemplate`,
`Unit/ItemIconTemplate`); controllers in `ReplicatedStorage.Shared.UIKit`
(`Button`, `ItemIcon`, `FilterPanel`). Screens: **Units** (uuid cards + grades + filters),
**Items** (catalog + counts + filters, A5), **Collection** (rebuilt on real instances, A5),
**Hotbar**. `StarterGui.UITemplates` was emptied into the Kit and deleted.
Each screen honours a `DevAutoOpen` attribute as a Studio harness (all left OFF).

## v2 candidates (not built)

- Gacha/banners (uses `GrantUnit` semantics + Items tickets) — schema v2 has landed, so this
  is now gated only on A3's catalog/tier configs.
- Party polish: cross-server invites / persisted parties (currently single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub, loadout picker UI (replaces the
  interim auto-loadout).
- Convert legacy script-built screens to instance trees when next touched (rule 2026-07-18):
  ~~CollectionScreen~~ (done A5), StageSelectScreen, PartyScreen, ReturnScreen.

## Open PENDINGs (see STATE.md)

- **AD-UI (A6):** resolved DMG/RNG/SPA NUMBERS (the Units stat rows' number slot shows `--`),
  real per-unit models (everything uses `UnitModels.Placeholder`), functional Units action
  buttons, hotbar rebuild. Kit promotion to `shared/src` at Integration (A7).
- **AD-Lobby (A5 handoff):** delete the now-unread `Towers`/`Currency` compat fields from
  `GetCollection`, and review the `Items` field AD-UI added to `GetUnitViews` —
  `docs/proposals/2026-08-03-drop-getcollection-compat.md`.
- **Unscheduled:** no writer for `Data.Items` (Items screen shows all zeroes) and none for
  `Data.Loadout` (`Equipped` is always false).
- **USER (BLOCKING):** save + republish **BOTH** Places together — schema v2 + teleport v2 are
  Studio-canon on both sides and v1/v2 do not interoperate. A partial publish breaks live
  launches with `[CONTRACT] PayloadVersion mismatch`. (LIVE v1 loop was verified 2026-07-18.)

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
