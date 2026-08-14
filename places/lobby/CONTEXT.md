# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-13 (B19/P6) -->

The social/meta Place: players land here, view their collection, roll banners, pick a stage +
difficulty, form parties, and teleport into the Game place.

## Current live state

- **Shared canon deployed & drift-free — 25/26 GREEN, re-verified B19.** Hashes live in
  `shared/manifest.json`; do not duplicate them. 19 modules + 7 templates. **TWO expected gaps, not
  drift:** `MetaMath` is Lobby-only (the Game reports MISSING) and `RewardScalingConfig` is Game-only
  until Integration copies it here. Every OTHER entry must match.
- **Trait rarity table arrived B12:** `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` are SHARED
  canon now — un-blocks C1/C2 and made **trait-on-summon LIVE** with no other Lobby change.
  API is `TraitRegistry.Roll(rng)`; there is no `RollTrait`.
- **`UnitStatsCatalog`** is a GENERATED read-only cache of each tower's resolved base DMG/RNG/SPA at
  tier 1 / ML 1 / no trait / mid-roll / asc 0 — **SPA is already inverted, not raw BaseStats**. Owner
  is AD-Game; the Lobby only consumes it. `Get(towerId)` returns nil for unknown ids and **Farm has
  no DMG/SPA keys**. Its validator is Game-only by design — do NOT port it here. See ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema
  v2** loads from **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**; intentional beta reset
  2026-07-31; DataStoreState=Access) — the Lobby shares the Game's profile (both at hash 63a0c98a).
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza. **Its presence is the Lobby Place assertion**
  (paired with `RS.Configs.Towers` being ABSENT — the Game has the tower configs, this Place does not).
- **Flow:**
  - **`GetUnitViews` (2026-08-01, the A4/A5 contract) is the SINGLE profile read path** (ADR-0004)
    and load-bearing for every screen: additive changes are free, a breaking one needs contract
    treatment. **`GetCollection` RETIRED A7** — handler + RemoteFunction both GONE; **do not add a
    second read path.** Per owned uuid it sends `Uuid, TowerId, Name, Tier` (from the shared
    `ItemCatalog`), `Level, XP, Trait, Shiny, Ascension, Worthiness, Locked, Favorited, Equipped`
    (uuid in `Loadout`), raw `StatRolls` and `Grades = {DMG,RNG,SPA}` letters from `StatGradeConfig`
    — plus `Loadout`, `Currencies`, `PlayerXP/PlayerLevel`, `MaxLoadout`, and (A5, additive) the
    `Items` map `{ [itemId] = count }`. **No resolved DMG/RNG/SPA and no XpPct** (deferred — see
    STATE PENDINGs). Clients never read profiles; render this view only. `RS.Remotes` holds **15**.
  - Stage select + difficulty = the `RS.Configs.StageRegistry` mirror + `GetStages`; captures
    (StageId, DifficultyPercent). **`StarterGui.StageSelectScreen` was DELETED at P6/B19** — PlayGUI
    covers stage select, difficulty and launch. `GetStages` SURVIVES (ReturnScreen calls it), but
    `ClientEvents.OpenStageSelect` lost its only listener — see the PENDING below.
    The mirror carries `StageNumber`/`StageName`/`ActNumber`/`ActName` copied VERBATIM from the
    Game's StageConfigs (P1): Stage 1 "The Farm"; acts 1 "Protecting the Fields", 2 "The Scarecrow
    Awakens", 3 "Harvest of Ruin". **`DisplayName` ≠ `ActName`** (Act 1 is both "The First Alamat"
    AND "Protecting the Fields"). Only the `Id` is re-validated Game-side, so a rename there goes
    stale **silently** — update both in one breath. Difficulty here is the **WIRE** scale 1–1000
    (100 = normal); PlayGUI's 1–100 is display-only (ADR-0011).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`, and since B19 PlayGUI's `StartButton`) — teleport contract **v2** (A2:
    `Loadout` carries unit **uuids**; version from `LobbyConfig.MatchLaunchVersion`, must equal the
    Game's `GameConfig.TeleportPayloadVersion`). `buildLoadout` = saved `Loadout` filtered to
    still-owned uuids, else auto by MetaLevel desc, capped at `MaxLoadoutSize`. `GamePlaceId` =
    **125430066355564**. Only the party HOST may launch; errors come back on `PartyState`.
  - **MatchReturn handling (2026-07-18; v2 since A2):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (expected version from `LobbyConfig`, not hardcoded;
    validates version/Outcome/stage; drops unknown `SuggestNextActId` — stale mirror fails safe),
    serves it via `Remotes.GetMatchReturn` (read-only). `StarterGui.ReturnScreen` = welcome-back
    banner; CONTINUE fires `ClientEvents.OpenStageSelect` — **inert since B19, see the PENDING**.
    Harness: `DevSimulateReturn`.
  - **Starter tower choice (2026-07-18):** dev-editable `RS.Configs.StarterTowerConfig`
    (Archer/Knight/Mage), `Server.Lobby.StarterChoiceService` +
    `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal `StarterGui.StarterChoiceScreen` (no
    dismiss; REAL instance tree — `Root.Panel.CardsRow.CardTemplate` is the card design).
    Eligibility = profile owns ZERO **units**. Grants a uuid `UnitInstance` mirroring the Game's
    `GrantUnit` (**StatRolls via shared `StatGradeConfig.RollAll` off one module-level Random**);
    never clobbers an existing instance. Harness = `DevSimulateFirstJoin`. `MaxLoadoutSize = 6`.

Run the bootstrap ritual + `tools/hash_shared.luau` every session; reconcile before any work on drift.

## UI kit + screens (AD-UI)

Three docs: **`ui-kit.md`** = the Place-neutral kit (5 controllers in `RS.Shared.UIKit` + 7 templates
in `RS.UITemplates.Kit`, all drift-controlled; was 6+8 until B2 retired the RewardPopup pair).
**`lobby-ui.md`** = this Place's SCREENS (Units, Items, Collection, Hotbar, CurrencyBar, HUD buttons,
legacy Party/Return/StarterChoice). **`play-menu.md`** = PlayGUI + LoadingScreen (split off at B15).
`StarterGui.UITemplates` was emptied into the Kit and deleted; `DevAutoOpen` harnesses all OFF.
**A7 finding:** the Units screen's cards are screen-local, NOT `Kit.UnitIcon` clones — and
`Kit_UnitIcon` is now ADOPTED for OTHER screens (ADR-0009), so do not delete or edit it.

**`ObtainRewardsGUI` — the reward-reveal surface (B1; animated B4). Detail in `lobby-ui.md`.** Fire
it, never rebuild it: `ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`.
Mixed units + items, grants QUEUE, **click 1 = SKIP, click 2 = CLOSE**. Its pop `UIScale` is on
runtime CLONES only — **never add one to `Kit_ItemIcon`, it is hashed canon.**

**`PlayGUI` + `LoadingScreen` — the Play menu, P1–P6 COMPLETE (B14–B19). Full doc:
`docs/systems/play-menu.md` — read it; law: `docs/blueprints/playgui.md`.** `HUD.Left.Buttons.Play`
(NOT HUD.Right) → veil → every other ScreenGui hidden → `Main.MainMenu`; `LeaveButton` restores each
screen's REMEMBERED state. Five things a Lobby session must not get wrong:
**(1)** `MainMenu`/`StoryModeFrame`/`LobbyFrame` are **CanvasGroups** (converted at P2 for §10's
`GroupTransparency` fade); the menu camera is Scriptable at `Workspace.PlayGUICamera.CFrame` —
**read it, never write it**. **(2)** `PlayGUI.DifficultyScale` is **THE ONE ADR-0011 conversion**
(UI 1–100 ↔ wire 100–1000; `StageRegistry` Min/Default/Max stay 1/100/1000) — **never write a
second**; P6 uses the published `DifficultyWire` VERBATIM and REFUSES to launch if it is absent.
**(3)** Selection travels as ATTRIBUTES on `StoryModeFrame.SelectedAct` (`SelectedActId`,
`SelectedStageNumber`, `RecommendedDifficultyWire`, plus P4's `DifficultyUI`/`DifficultyWire`/
`DifficultyMode`); edge-trigger on **`SelectionSerial`**, never on `SelectedActId` (an unchanged
attribute fires no signal), and add no second channel. **(4)** P6's `LobbyController` clones the
authored `PlayerRowTemplate` (avatars via non-yielding `rbxthumb://`), `InviteButton` → the existing
`PartyScreen` (new `OpenRequest` seam, DisplayOrder 0 → 30), `StartButton` → LoadingScreen → the
EXISTING `RequestLaunch`/`PartyService` path — **no second launch path**; every lookup there is
NON-RECURSIVE because `SelectedAct` exists under BOTH frames and `PlayersFrame` holds a
ScrollingFrame of the same name. **(5)** Labels with no data source are HIDDEN, not zeroed, and the
reward panel renders zero cells until `RewardScalingConfig` arrives. `LoadingScreen` is Lobby-local,
NOT drift-controlled (§4).

## Gacha — banner ENGINE built (B3, 2026-08-09). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*,
Meta.MetaConfig}`, driven by `RS.Remotes.RequestSummon`. UI shipped B6/B7/B8. Four rules:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies`
  inline. Its unit record stays byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is SHARED canon** (`6badac1d`), **not deployed to the Game** — MISSING there
  is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE** (client fires `ShowRewards` with `result.Rewards`). No push
  remote exists; `ObtainRewardsGUI` was consumed, never modified.
- Pity uses schema-v2 `Data.Pity[ref]` — **no schema bump**; pulls count on
  `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008 — A8 owns that key).

## v2 candidates (not built)

- Gacha UI: carousel (B6), Event (B7), Index (B8) SHIPPED; only **Selection** is left, blocked on the
  `BannerChoices` schema bump. Party polish: cross-server invites / persisted parties (today it is
  single-lobby-server and in-memory). Currency shop, player-level display, trading hub, loadout
  picker UI. Convert legacy script-built screens when next touched (rule 2026-07-18): **Party** and
  **Return** remain (StageSelect DELETED at B19, Collection converted at A5).

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

- **AD-UI (NEW, B19):** `ClientEvents.OpenStageSelect` has **no listener** since `StageSelectScreen`
  was deleted, so `ReturnScreen`'s CONTINUE is inert. Needs an "open PlayGUI on this act" seam in
  `PlayGUIController`/`StoryModeController` (AD-UI canon, so B19 filed a proposal instead):
  `docs/proposals/2026-08-13-openstageselect-after-stageselectscreen.md`.
- **AD-UI:** real per-unit models (all use `UnitModels.Placeholder`); Units action buttons are
  animation-only (equip works since B10). Hotbar hover TRIGGER unverified (tooling cannot fire
  `MouseEnter`); `Kit_ItemHoverCard`'s master/clone split means editing the master does not update it.
- **USER (BLOCKING):** **republish BOTH Places** (everything since A7 is Studio canon, not git), then
  run the **teleport v2 loop LIVE** once — only v1 was ever live-verified (2026-07-18). v1/v2 do not
  interoperate, so a partial publish breaks launches with `[CONTRACT] PayloadVersion mismatch`.
- **Unscheduled:** still no writer for `Data.Items` in NORMAL PLAY, so the Items screen shows zeroes.
  `GrantService` (B3) CAN write it and is verified doing so, but no shipping flow grants an item yet.
  (`Data.Loadout` HAS a writer since B10.)
- **AD-Integration:** the Game still grants through its own `PlayerInventoryService` /
  `RewardCalculator`, so invariant 1 holds in the Lobby ONLY. Converging them is cross-Place work.

## Ownership notes

- Lobby owns: teleport contract, lobby UI/scene. **AD-Gacha owns the banner catalog + grant
  pipeline** (`docs/systems/gacha.md`), home Place Lobby, built B3.
- Lobby consumes (never edits): save schema, tower configs, progression config, trait configs.
- Currency/XP/tower grants go through the same profile (never a second store) and, since B3, through
  **`GrantService`**, never inline.
