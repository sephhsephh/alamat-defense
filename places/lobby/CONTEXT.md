# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-06 -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place.

## Current live state

- **Data layer deployed & drift-free.** `ReplicatedStorage.Shared.{Signal, ProfileTemplate}`,
  `ServerScriptService.Server.Data.{ProfileStore, PlayerDataService}` — all four hashes match
  `shared/manifest.json` (Signal 91becf7a, **ProfileTemplate 63a0c98a**, PlayerDataService
  613f0d39, ProfileStore 1e3a6f3f). `Signal` was promoted into `shared/src` 2026-07-17.
- **All 9 shared modules deployed — drift GREEN 9/9 (A6b, 2026-08-06).** The five Meta configs
  live in `RS.Configs.Meta`: TierConfig a0d6e3a3, StatGradeConfig 49a6edfd, AscensionConfig
  59aa8e15, ItemCatalog 789dca4b, and **`UnitStatsCatalog` 3bb9b140** (deployed A6b). The latter
  is a GENERATED read-only cache of each tower's resolved base DMG/RNG/SPA at tier 1 / ML 1 /
  no trait / mid-roll / asc 0 — **SPA is already inverted, these are not raw BaseStats**. Owner
  is AD-Game; the Lobby only consumes it. `Get(towerId)` returns nil for unknown ids and **Farm
  has no DMG/SPA keys** (support tower). Its validator is Game-only canon by design — the Lobby
  has no tower configs to validate against, so do NOT port it here. See ADR-0003.
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
    legitimately empty today. Added by AD-UI with the user's authorisation; **AD-Lobby reviewed
    it at A6b and KEPT IT AS-IS** — the shape is right, so `ItemsController` needs no change.
    `GetUnitViews` is now the Lobby's SINGLE profile read path and load-bearing for every
    screen: additive changes are free, but a breaking one needs contract treatment (ADR-0004).
  - **`GetCollection` — DEAD CODE, retirement scheduled (ADR-0004).** Serves uuid-keyed `Units`
    + `Loadout` + `Currencies` + `PlayerXP`/`PlayerLevel`; the interim `Towers`/`Currency` compat
    fields were **DELETED at A6b (2026-08-06)** after a re-grep confirmed zero readers. It now has
    **zero callers of any kind** — every screen reads `GetUnitViews`. The handler + RemoteFunction
    are removed at **A7, after the user's republish**. **Do not build new readers on it.**
    (`StarterGui.CollectionScreen` renders from `GetUnitViews`, not this.)
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

- **AD-UI (A6, UNBLOCKED 2026-08-06):** fill the Units stat rows' `--` number slots from
  `UnitStatsCatalog.Get` (`Stats.BaseStatsFrame.{DMG,RNG,SPA}`) — the module is now deployed
  here and verified requireable. The `Grade` labels beside them already work from the roll and
  must keep working; **Farm returns no DMG/SPA, handle the nil**. Also still open: real per-unit
  models (everything uses `UnitModels.Placeholder`), functional Units action buttons, hotbar
  rebuild. Kit promotion to `shared/src` at Integration (A7).
- ~~**AD-Lobby (A5 handoff)**~~ **DONE 2026-08-06 (A6b)** — compat fields deleted (zero readers
  re-confirmed), `Items` reviewed and kept as-is; proposal RESOLVED.
- **A7:** retire `GetCollection` — delete the handler + the RemoteFunction (ADR-0004), after the
  user's republish.
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
