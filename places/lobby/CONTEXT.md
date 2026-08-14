# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-14 (B21) -->

The social/meta Place: players land here, view their collection, roll banners, pick a stage +
difficulty, form parties, and teleport into the Game place.

## Current live state

- **Shared canon deployed & drift-free — 26/26 GREEN, NO GAPS, re-verified B20.** Hashes live in
  `shared/manifest.json`; do not duplicate them. 19 modules + 7 templates. **`RewardScalingConfig`
  landed here at B20** (`1d789978`, copied byte-identical from the Game — its deployPath needed a new
  `RS.Configs.Global` FOLDER, which this Place did not have). `MetaMath` stays Lobby-only, so it is
  the GAME that still reports 25/26 — expected, not drift. Every entry here must match.
- **Trait rarity table arrived B12:** `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` are SHARED
  canon — un-blocks C1/C2 and made **trait-on-summon LIVE**. API is `TraitRegistry.Roll(rng)`;
  there is no `RollTrait`.
- **`UnitStatsCatalog`** = GENERATED read-only cache of each tower's resolved base DMG/RNG/SPA at
  tier 1 / ML 1 / no trait / mid-roll / asc 0 — **SPA already inverted, not raw BaseStats**. AD-Game
  owns it; the Lobby only consumes. `Get(towerId)` → nil for unknown ids; **Farm has no DMG/SPA
  keys**. Validator is Game-only by design — do NOT port it. ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema
  v2** from **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**; beta reset 2026-07-31;
  DataStoreState=Access) — the Lobby shares the Game's profile (both at `63a0c98a`).
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza. **Its presence is the Lobby Place assertion**
  (paired with `RS.Configs.Towers` being ABSENT — the Game has the tower configs, this Place does not).
- **Flow:**
  - **`GetUnitViews` (2026-08-01, the A4/A5 contract) is the SINGLE profile read path** (ADR-0004)
    and load-bearing for every screen: additive changes are free, a breaking one needs contract
    treatment. **`GetCollection` RETIRED A7** — handler + RemoteFunction both GONE; **do not add a
    second read path.** Per owned uuid: `Uuid, TowerId, Name, Tier` (shared `ItemCatalog`), `Level,
    XP, Trait, Shiny, Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw
    `StatRolls`, `Grades = {DMG,RNG,SPA}` from `StatGradeConfig` — plus `Loadout`, `Currencies`,
    `PlayerXP/PlayerLevel`, `MaxLoadout` and (A5, additive) `Items {[itemId]=count}`. **No resolved
    DMG/RNG/SPA, no XpPct** (deferred). Clients never read profiles. `RS.Remotes` holds **15**.
  - Stage select + difficulty = the `RS.Configs.StageRegistry` mirror + `GetStages`; captures
    (StageId, DifficultyPercent). **`StarterGui.StageSelectScreen` was DELETED at P6/B19** — PlayGUI
    covers stage select, difficulty and launch. `GetStages` SURVIVES (ReturnScreen calls it), and
    **`ClientEvents.OpenStageSelect` got its listener back at B21 — it is now PlayGUI's public open
    event** (fire it with an act id; ReturnScreen's CONTINUE does exactly that).
    The mirror carries `StageNumber`/`StageName`/`ActNumber`/`ActName` copied VERBATIM from the
    Game's StageConfigs (P1). **`DisplayName` ≠ `ActName`** (Act 1 is both "The First Alamat" AND
    "Protecting the Fields"). Only the `Id` is re-validated Game-side, so a rename there goes stale
    **silently** — update both in one breath. Difficulty here is the **WIRE** scale 1–1000 (100 =
    normal); PlayGUI's 1–100 is display-only (ADR-0011).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`, and since B19 PlayGUI's `StartButton`) — teleport contract **v3**
    (`Loadout` carries unit **uuids** since A2; **`DifficultyMode` "Normal"/"Insane" since B20**;
    version from `LobbyConfig.MatchLaunchVersion`, must equal the Game's
    `GameConfig.TeleportPayloadVersion` — **v2 and v3 do NOT interoperate**).
    **The mode joins the payload in `PartyService`, not in the UI:** P4 publishes `DifficultyMode` on
    `SelectedAct`, P6's `LobbyController` passes it through `RequestLaunch` verbatim, and
    `PartyService` validates it (anything but `"Insane"` becomes `"Normal"`) and builds the payload. `buildLoadout` = saved `Loadout` filtered to
    still-owned uuids, else auto by MetaLevel desc, capped at `MaxLoadoutSize`. `GamePlaceId` =
    **125430066355564**. Only the party HOST may launch; errors come back on `PartyState`.
  - **MatchReturn handling (2026-07-18; v3 since B20):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (expected version from `LobbyConfig`, NOT hardcoded, so the
    v3 bump carried automatically; validates version/Outcome/stage; drops unknown `SuggestNextActId`
    — stale mirror fails safe), serves it via `Remotes.GetMatchReturn` (read-only).
    `StarterGui.ReturnScreen` = welcome-back banner; CONTINUE fires `ClientEvents.OpenStageSelect`,
    **live again since B21** (PlayGUI opens on the suggested act). Harness: `DevSimulateReturn`.
  - **Starter tower choice (2026-07-18):** `RS.Configs.StarterTowerConfig` (Archer/Knight/Mage),
    `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal
    `StarterGui.StarterChoiceScreen` (no dismiss; REAL tree — `Root.Panel.CardsRow.CardTemplate` is
    the card). Eligible when the profile owns ZERO **units**. Grants a uuid `UnitInstance` mirroring
    the Game's `GrantUnit` (**StatRolls via shared `StatGradeConfig.RollAll`, one module-level
    Random**); never clobbers an existing one. Harness `DevSimulateFirstJoin`. `MaxLoadoutSize = 6`.

Run the bootstrap ritual + `tools/hash_shared.luau` every session; reconcile before any work on drift.

## UI kit + screens (AD-UI)

Three docs: **`ui-kit.md`** = the Place-neutral kit (5 controllers in `RS.Shared.UIKit` + 7 templates
in `RS.UITemplates.Kit`, drift-controlled; was 6+8 until B2 retired the RewardPopup pair).
**`lobby-ui.md`** = this Place's SCREENS (Units, Items, Collection, Hotbar, CurrencyBar, HUD buttons,
legacy Party/Return/StarterChoice). **`play-menu.md`** = PlayGUI + LoadingScreen (split at B15).
`StarterGui.UITemplates` was emptied into the Kit and deleted; `DevAutoOpen` harnesses all OFF.
**A7:** Units-screen cards are screen-local, NOT `Kit.UnitIcon` clones — and `Kit_UnitIcon` is
ADOPTED for OTHER screens (ADR-0009), so do not delete or edit it.

**`ObtainRewardsGUI` — the reward-reveal surface (B1; animated B4). Detail in `lobby-ui.md`.** Fire
it, never rebuild it: `ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`.
Mixed units + items, grants QUEUE, **click 1 = SKIP, click 2 = CLOSE**. Its pop `UIScale` is on
runtime CLONES only — **never add one to `Kit_ItemIcon`, it is hashed canon.**

**`PlayGUI` + `LoadingScreen` — the Play menu, P1–P6 COMPLETE (B14–B19). FULL DOC:
`docs/systems/play-menu.md` — read it before touching any of this; law: `blueprints/playgui.md`.**
`HUD.Left.Buttons.Play` (NOT HUD.Right) → veil → other ScreenGuis hidden → `Main.MainMenu`.
Five things a Lobby session must not get wrong (detail in play-menu.md):
**(1)** the three frames are **CanvasGroups**; the menu camera is Scriptable at
`Workspace.PlayGUICamera.CFrame` — **read it, never write it**. **(2)** `PlayGUI.DifficultyScale` is
**THE ONE ADR-0011 conversion** (UI 1–100 ↔ wire 100–1000) — **never write a second**; P6 uses the
published `DifficultyWire` VERBATIM and REFUSES to launch if it is absent. **(3)** selection travels
as ATTRIBUTES on `StoryModeFrame.SelectedAct`; edge-trigger on **`SelectionSerial`**, never on
`SelectedActId`, and add no second channel. **(4)** every PlayGUI lookup is NON-RECURSIVE on purpose
— `SelectedAct` exists under BOTH frames and `PlayersFrame` holds a ScrollingFrame of the same name;
`StartButton` uses the EXISTING `RequestLaunch`/`PartyService` path, **never a second one**.
**(5)** labels with no data source are HIDDEN, not zeroed — but the **reward preview is LIVE since
B21**: it reads the shared `RewardScalingConfig.GoldBand` off the published `DifficultyWire` (never
re-derived from `DifficultyUI`) and re-renders on every slider move, so it can never contradict the
payout. Insane ADDS 2 item cells without changing the band. `LoadingScreen` is Lobby-local, NOT
drift-controlled (§4).

## Gacha — banner ENGINE built (B3, 2026-08-09). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*,
Meta.MetaConfig}`, driven by `RS.Remotes.RequestSummon`. UI shipped B6/B7/B8. Four rules:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies` inline;
  its unit record stays byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is SHARED canon** (`6badac1d`), **not deployed to the Game** — MISSING there
  is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE**; no push remote exists. Pity uses `Data.Pity[ref]` (no
  schema bump); pulls count on `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008).

## v2 candidates (not built)

Gacha UI: carousel (B6), Event (B7), Index (B8) SHIPPED; only **Selection** is left, blocked on the
`BannerChoices` schema bump. Party polish (cross-server invites / persisted parties — today
single-server, in-memory), currency shop, player-level display, trading hub, loadout picker UI.
Convert legacy script-built screens when next touched (rule 2026-07-18): **Party** and **Return**
remain (StageSelect DELETED at B19, Collection converted at A5).

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

- **AD-UI:** real per-unit models (all use `UnitModels.Placeholder`); Units action buttons are
  animation-only (equip works since B10). Hotbar hover TRIGGER unverified (tooling cannot fire
  `MouseEnter`); `Kit_ItemHoverCard`'s master/clone split means editing the master does not update
  it. **Small follow-up:** `LobbyFrame.RewardsFrame` still shows nothing — mirror the Story panel's
  `refreshRewards` off the SAME published attributes; do not add a second `GoldBand` call site.
- **USER (BLOCKING, now URGENT):** **republish BOTH Places TOGETHER**, then run the **teleport v3
  loop LIVE** once. B20 bumped the contract to **v3** and **v2/v3 do not interoperate** — publishing
  one Place without the other breaks EVERY launch with `[CONTRACT] PayloadVersion mismatch`. Not just
  an unverified path any more: a partial publish is a live break.
- **Unscheduled:** `Data.Items` finally has a shipping writer — **an INSANE Victory** (teleport v3,
  B20) pays `BannerTicket` + `TraitRerollToken` through the Game's `RewardCalculator`. Until a player
  actually clears one, Lobby item counts still read 0. (`Data.Loadout` has had a writer since B10.)
- **AD-Integration:** the Game still grants via `PlayerInventoryService`/`RewardCalculator`, so
  invariant 1 holds in the Lobby ONLY. Converging them is cross-Place work.

## Ownership notes

- Lobby owns: teleport contract, lobby UI/scene. **AD-Gacha owns the banner catalog + grant
  pipeline** (`docs/systems/gacha.md`), home Place Lobby, built B3.
- Lobby consumes (never edits): save schema, tower configs, progression config, trait configs,
  and **`RewardScalingConfig`** (AD-Game's — read the curve, never re-author or retune it here).
- Currency/XP/tower grants go through the same profile (never a second store) and, since B3, through
  **`GrantService`**, never inline.
