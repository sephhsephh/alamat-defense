# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-19 (B31) -->

The social/meta Place: players land here, view their collection, roll banners, pick a stage +
difficulty, form parties, and teleport into the Game place.

## Current live state

- **Shared canon: 27/27 PRESENT here (20 modules + 7 templates), hashes in `shared/manifest.json`.**
  `MetaMath` stays Lobby-only, so the GAME reports 26/27 — expected, not drift. Every other entry
  matches (`ItemCatalog`'s real icon assetids included, since B23). History: CHANGELOG.
- **Trait rarity table (B12):** `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` are SHARED canon; API is `TraitRegistry.Roll(rng)`, there is no `RollTrait`.
- **`UnitStatsCatalog`** = GENERATED cache of each tower's resolved base DMG/RNG/SPA at tier 1 / ML 1
  / no trait / mid-roll / asc 0 — **SPA already inverted**. AD-Game owns it, the Lobby only consumes;
  `Get(towerId)` → nil for unknown ids, **Farm has no DMG/SPA keys**, validator Game-only. ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema
  v3** (B29, `72d3944f`) from **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**) — shares the
  Game's profile. v3's `BannerChoices` is what Selection banners (B30) store their pick in.
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza. **Its presence is the Lobby Place assertion**
  (paired with `RS.Configs.Towers` being ABSENT — the Game has the tower configs, this Place does not).
- **Flow:**
  - **`GetUnitViews` is the SINGLE profile read path** (ADR-0004): additive changes are free, a
    breaking one needs contract treatment. **`GetCollection` is RETIRED; do not add a second read
    path.** Per owned uuid: `Uuid, TowerId, Name, Tier` (shared `ItemCatalog`), `Level, XP, Trait,
    Shiny, Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls`,
    `Grades = {DMG,RNG,SPA}` — plus `Loadout`, `Currencies`, `PlayerXP/PlayerLevel`, `MaxLoadout`,
    `Items {[itemId]=count}`. **No resolved DMG/RNG/SPA, no XpPct, NO cost and NO element** (B24).
    Clients never read profiles. `RS.Remotes` holds **19** (B30 `ChooseBannerUnit`, B31 `SellUnits`).
  - Stage select + difficulty = the `RS.Configs.StageRegistry` mirror + `GetStages`; captures
    (StageId, DifficultyPercent). `StageSelectScreen` was DELETED at B19 — PlayGUI covers stage
    select, difficulty and launch; `GetStages` SURVIVES (ReturnScreen calls it). **`ClientEvents
    .OpenStageSelect` is PlayGUI's public open event** — fire it with an act id.
    The mirror carries `StageNumber`/`StageName`/`ActNumber`/`ActName` copied VERBATIM from the
    Game's StageConfigs. **`DisplayName` ≠ `ActName`**; only the `Id` is re-validated Game-side, so a
    rename there goes stale **silently** — update both in one breath. Difficulty here is the **WIRE**
    scale 1–1000 (100 = normal); PlayGUI's 1–100 is display-only (ADR-0011).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`, and since B19 PlayGUI's `StartButton`) — teleport contract **v4**
    (`Loadout` carries unit **uuids** since A2; **`DifficultyMode` "Normal"/"Insane" since B20**;
    version from `LobbyConfig.MatchLaunchVersion`, must equal the Game's
    `GameConfig.TeleportPayloadVersion` — **v3 and v4 do NOT interoperate**). v4 (B23) adds
    `IsMatchmade` and widens `HostUserId` to the ELECTED match host.
  - **`Server.Lobby.LaunchService` (B23) is THE launch body** — loadout, payload, reserve+teleport —
    required by BOTH `PartyService` and `MatchmakingService`. **ONE path with one more caller, NOT a
    second path** (§12): `PartyService` is a `Script` and cannot be required, which is why the body had
    to move. `Remotes.RequestLaunch` is still the only CLIENT entry.
  - **`Server.Lobby.{MatchmakingService, MatchmakingRules}` (P7, B23) — the GLOBAL QUEUE.** MemoryStore
    map keyed `actId|stageNumber|mode|difficultyBucket` off the attributes P4 publishes. **An entry is a
    PARTY, never a player**; packing only adds WHOLE entries, so "never split" holds by construction.
    Host = **lowest userId** (every server elects identically, no round trip). **The match runs at the
    host's EXACT wire value — never an average**, which would move everyone's `GoldBand` payout.
    `MatchmakingRules.BucketOf` is the ONE home for queue difficulty arithmetic and is **not** the
    ADR-0011 conversion. Timeout 45s **OFFERS** solo. **The mode joins the payload in `PartyService`,
    not the UI:** P4 publishes `DifficultyMode`, P6's `LobbyController` passes it through
    `RequestLaunch` verbatim, `PartyService` validates it (anything but `"Insane"` → `"Normal"`).
    `buildLoadout` = saved `Loadout` filtered to still-owned uuids, else auto by MetaLevel desc, capped
    at `MaxLoadoutSize`. `GamePlaceId` = **125430066355564**. Only the party HOST may launch; errors
    come back on `PartyState`.
  - **MatchReturn (v3):** `Server.Lobby.MatchReturnService` reads `TeleportData.MatchReturn` on join
    (version from `LobbyConfig`, NOT hardcoded; validates version/Outcome/stage; drops an unknown
    `SuggestNextActId` — a stale mirror fails safe) and serves it via `Remotes.GetMatchReturn`.
    `ReturnScreen` = welcome-back banner; CONTINUE fires `OpenStageSelect`. Harness `DevSimulateReturn`
    **only fires on JOIN** — set it in the EDIT datamodel and restart Play.
  - **Starter tower choice:** `RS.Configs.StarterTowerConfig` (Archer/Knight/Mage),
    `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal
    `StarterGui.StarterChoiceScreen` (REAL tree, card = `Root.Panel.CardsRow.CardTemplate`). Eligible
    at ZERO **units**; grants a uuid `UnitInstance` mirroring `GrantUnit` (**StatRolls via shared
    `StatGradeConfig.RollAll`**), never clobbering an existing one. Harness `DevSimulateFirstJoin`.
    `MaxLoadoutSize = 6`.

## UI kit + screens (AD-UI)

Three docs: **`ui-kit.md`** = the Place-neutral kit (5 controllers in `RS.Shared.UIKit` + 7 templates in
`RS.UITemplates.Kit`, drift-controlled). **`lobby-ui.md`** = this Place's SCREENS (Units, Items,
Collection, Hotbar, CurrencyBar, HUD buttons, legacy Party/Return/StarterChoice). **`play-menu.md`** =
PlayGUI + LoadingScreen. All `DevAutoOpen` harnesses OFF.
Units-screen cards ARE `Kit.UnitIconV2` clones since **B27b** — ADR-0009's screen-local `UnitTemplate` is gone, and any stray copy left in `UnitsContainer` is destroyed at boot. (This line claimed the opposite until B31.)

**`ObtainRewardsGUI` — the reward-reveal surface. Detail in `lobby-ui.md`.** Fire it, never rebuild:
`ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`. Grants QUEUE, click 1 =
SKIP, click 2 = CLOSE. Its pop `UIScale` is on runtime CLONES only — **never add one to
`Kit_ItemIconV2`, it is hashed canon.**

**`PlayGUI` + `LoadingScreen` — the Play menu, **P1–P7 COMPLETE** (B14–B23). FULL DOC:
`docs/systems/play-menu.md` — read it first; law: `blueprints/playgui.md`.** `HUD.Left.Buttons.Play`
(NOT HUD.Right) → veil → other ScreenGuis hidden → `Main.MainMenu`. Five things not to get wrong:
**(1)** the three frames are **CanvasGroups**; the menu camera is Scriptable at
`Workspace.PlayGUICamera.CFrame` — **read it, never write it**. **(2)** `PlayGUI.DifficultyScale` is
**THE ONE ADR-0011 conversion** (UI 1–100 ↔ wire 100–1000) — **never write a second**; the launch and
queue paths both use the published `DifficultyWire` VERBATIM and REFUSE to act if it is absent.
**(3)** selection travels as ATTRIBUTES on `StoryModeFrame.SelectedAct`; edge-trigger on
**`SelectionSerial`**, and add no second channel. **(4)** every PlayGUI lookup is NON-RECURSIVE on
purpose — `SelectedAct` exists under BOTH frames, `PlayersFrame` holds a ScrollingFrame of the same
name, and there are THREE `SelectedDifficultyLable`s. **(5)** labels with no data source are HIDDEN,
not zeroed — but the **reward preview is LIVE since B21** (`RewardScalingConfig.GoldBand` off the
published wire, re-rendered every slider move, so it cannot contradict the payout) and **B24 mirrors
it into `LobbyFrame` from that ONE computation — never add a second `GoldBand` call site.**
`LoadingScreen` is Lobby-local, NOT drift-controlled (§4).
**P7 (the global queue, §11) SHIPPED at B23 on teleport v4.** `FindMatchButton` — under
**StoryModeFrame**, not MainMenu — is LIVE: `PlayGUIController` no longer disables it and the new
`MatchmakingController` (the FIFTH PlayGUI script) owns it; its `InactiveOverlay` stays authored but
hidden. **MemoryStore works from Studio; `ReserveServer` is 403 here**, so the cross-server handoff
and every multi-client §11 clause need a live two-client run.

## Gacha — banner ENGINE built (B3, 2026-08-09). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*,
Meta.MetaConfig}`, driven by `RS.Remotes.RequestSummon`. UI shipped B6/B7/B8. Rules:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies` inline;
  its unit record stays byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is SHARED canon** (`6badac1d`), **not deployed to the Game** — MISSING there
  is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE**; no push remote. Pity uses `Data.Pity[ref]` (no schema
  bump); pulls count on `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008).
- **SELECTION banners LIVE at B30 (blueprint B4 COMPLETE) — FULL DOC: `docs/systems/gacha-selection.md`,
  read it first.** `SSS.Server.Meta.BannerChoiceService` + `Remotes.ChooseBannerUnit` are **the ONE
  writer of `Data.BannerChoices`**; **`ChosenAtDay` is a `MetaMath.Slot` DAY NUMBER, not a timestamp.**
- **SELL DUPES LIVE at B31 (blueprint C3 COMPLETE) — doc: `docs/systems/ascension.md`.**
  **`Server.Meta.UnitConsumeRules` is THE ONE definition of "may this unit be destroyed"** (Locked /
  Favorited / equipped / has-spirit), shared with ascension's `PickDupe`; **`GrantService.SellUnits` is
  the ONLY code that deletes a `Data.Units` record** and it CREDITS BEFORE DESTROYING. Prices are
  shared `TierConfig.GetSellValue` (0 for an unknown tier, so it can never mint Silver).
  `Remotes.SellUnits` + `Server.Meta.SellService`; UI = multi-select in the Units screen
  (`QuickSellButton` → authored `SellConfirm` → `ShowRewards`). Harness `UnitsGUI.DevSell`.

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

**Not built (`docs/ROADMAP.md` has the rows):** **Party** and **Return** are still script-built.

**`STATE.md` is the canon list — read it, not this.** Only the Lobby-specific detail lives here:

- **v3/v4 do NOT interoperate:** a partial publish breaks EVERY launch (version mismatch).
- **AD-UI:** unit models are all `UnitModels.Placeholder`; `LockUnitButon` (sic) is still UNWIRED and
  nothing writes `Locked`/`Favorited`. **`QuickSellButton` IS wired now (B31).** `ItemHoverCard` split.
- **V2 kit: ✅ ADOPTED BOTH PLACES AT B26, v1 RETIRED** (do not re-add). **Canon: `ui-kit.md`.** Not to
  re-derive: rarity is on the ROOT `UIGradient`, direct-children-only, **NO tier border** (user, B25);
  **no `ShinyBadge` in V2** — shiny is unmarked on an ascension card.
- **B28 — SCREENS SLIDE.** `UnitsGUI`/`ItemsGUI`/`SummonScreen`/`IndexScreen` open/close through
  **`Motion.slideIn`/`slideOut`** and test **`Motion.isOpen(main)`, not `gui.Enabled`** (still Enabled
  mid close-tween); boot = `hideInstant()`; PlayGUI excluded (veil), `AscensionScreen` untouched.

## Ownership notes

- Lobby owns the teleport contract + the lobby UI/scene. **AD-Gacha owns the banner catalog + grant
  pipeline** (`docs/systems/gacha.md`, `gacha-selection.md`), home Place Lobby. Lobby CONSUMES and
  never edits: save schema, tower configs, progression config, trait configs, **`RewardScalingConfig`**
  (AD-Game's — read the curve, never re-author it here). Currency/XP/tower grants go through the same
  profile (never a second store) and **`GrantService`**, never inline.
