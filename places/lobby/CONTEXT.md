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
  - **`GetCollection` — RETIRED A7 (2026-08-06, ADR-0004).** The handler in `LobbyServices` and
    the `RS.Remotes.GetCollection` RemoteFunction are both **GONE**; `RS.Remotes` holds 12 entries.
    Both Places were re-grepped first (zero callers, zero field readers) and all 7 screens were
    re-verified loading afterwards with no errors and no infinite-yield warning. **`GetUnitViews`
    is now the SINGLE profile read path** and is load-bearing for every screen: additive changes
    are free, a breaking one needs contract treatment. **Do not add a second read path.**
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

Two docs since A7 (2026-08-06): **`docs/systems/ui-kit.md`** is the Place-neutral kit (6 shared
controllers in `RS.Shared.UIKit` + 8 real instance templates in `RS.UITemplates.Kit`, all under
drift control); **`docs/systems/lobby-ui.md`** is this Place's SCREENS — **Units** (uuid cards +
grades + numbers + filters), **Items** (catalog + counts + filters), **Collection**, **Hotbar**
(the shared component), **CurrencyBar** (Lobby-local by design), plus the legacy script-built
StageSelect / Party / Return / StarterChoice. `StarterGui.UITemplates` was emptied into the Kit
and deleted. Each of Units/Items/Collection honours a `DevAutoOpen` Studio harness (all left OFF).
**A7 finding:** the Units screen's cards are screen-local, NOT `Kit.UnitIcon` clones — see
`lobby-ui.md`; that template still has no consumer and its fate is a user decision.

**`ObtainRewardsGUI` — the reward-reveal surface (B1, 2026-08-08, AD-UI). BUILT + verified live.**
One grid, MIXED units + items. Entry point is client-side and Lobby-local:
`RS.ClientEvents.ShowRewards:Fire({ { Id = "Archer", Level = 12 }, { Id = "Gold", Qty = 250 } })`
(a bare string id also works). Cell = unit → this screen's own `RewardsFrame.UnitTemplate`
(150×150, locked by its own `UISizeConstraint`, adopted as-is per ADR-0007 and kept **Lobby-local**,
NOT promoted to shared canon); anything else → a FRESH clone of shared `Kit.ItemIcon`. Kind is
inferred from `ItemCatalog` (`Kind == "Tower"` → unit) and can be forced with `Kind`. An id absent
from the catalog still renders (name falls back to the id, tier Common). Layout is 5 columns;
rows 1–3 grow the frame, row 4+ freezes Y at the 3-row height and scrolls. **Every metric is READ
from the instances** (`UIGridLayout.CellSize`/`CellPadding`/`FillDirectionMaxCells`, `UIPadding`,
`RewardsFrame:GetAttribute("MaxVisibleRows")`, `ObtainRewardsGUI:GetAttribute("InputDeadSeconds")`)
— retune spacing in Studio, no code change. Dismiss = click ANYWHERE (`Main` is the full-screen
catcher, `Active = true`) after a 0.35s input-dead period; back-to-back grants QUEUE, never merge.
Studio harness: flip the `DevDismiss` attribute (same `dismiss()` path a click takes). Left OFF.
**No production caller yet** — each system wires itself in as it ships (user decision).

## v2 candidates (not built)

- Gacha/banners (uses `GrantUnit` semantics + Items tickets) — schema v2 has landed, so this
  is now gated only on A3's catalog/tier configs.
- Party polish: cross-server invites / persisted parties (currently single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub, loadout picker UI (replaces the
  interim auto-loadout).
- Convert legacy script-built screens to instance trees when next touched (rule 2026-07-18):
  ~~CollectionScreen~~ (done A5), StageSelectScreen, PartyScreen, ReturnScreen.

## Phase A: SIGNED OFF (A9, 2026-08-06)

Every §8 item passes; nothing here is outstanding for Phase A. Two A9 results worth keeping: all
**7 screens** still load after A7 removed `GetCollection`, and **`Worthiness` shows REAL values
here with zero Lobby changes** because `GetUnitViews` already carried the field — the contract
paying for itself. Full evidence in the A9 changelog entry.

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

- **AD-UI:** real per-unit models (everything uses `UnitModels.Placeholder`) and functional Units
  action buttons (animation-only today). `Kit_UnitIcon` has no consumer — user decision.
- **AD-Integration (NEW, B1):** `Kit_ItemIcon` canon bumped `ee1ccd33` → **`c5e81264`**; the LOBBY
  is canon and the **GAME is STALE**. Copy Lobby → Game, set `deployed.Game`. Until then the Game
  reads 23/24 — expected, not new drift. Also still open: retire `UIKitRewardPopup` +
  `Kit_RewardPopup` (24 → 22), now that a working replacement exists.
- **AD-UI (small):** the hotbar hover TRIGGER is unverified (tooling cannot fire `MouseEnter`);
  `Kit_ItemHoverCard`'s master/clone split means editing the master does not update the screen.
- **USER (BLOCKING):** save + **republish BOTH Places** — A7 deleted `GetCollection` here, which
  is Studio canon and not in git. Schema v2 + teleport v2 also do not interoperate with v1, so a
  partial publish breaks live launches with `[CONTRACT] PayloadVersion mismatch`.
- **USER:** run the teleport v2 loop LIVE once (only v1 was ever live-verified, 2026-07-18).
- **Unscheduled:** no writer for `Data.Items` in normal play, so the Items screen shows all zeroes.
  (`Data.Loadout` now HAS a writer — `LoadoutService`, 2026-08-06 — so `Equipped` is real.)

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
