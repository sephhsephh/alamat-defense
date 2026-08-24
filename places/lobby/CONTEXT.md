# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-21 (B36) -->

The social/meta Place: players land here, view their collection, roll banners, pick a stage + difficulty, form parties, and teleport
into the Game place.

## Current live state

- **Shared canon: 27/27 PRESENT here (20 modules + 7 templates), hashes in `shared/manifest.json`.** `MetaMath` stays Lobby-only, so
  the GAME reports 26/27 — expected, not drift. Every other entry matches (`ItemCatalog`'s real icon assetids included, since B23).
  History: CHANGELOG.
- **Trait rarity table (B12):** `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` are SHARED canon; API is
  `TraitRegistry.Roll(rng)`, there is no `RollTrait`.
- **`UnitStatsCatalog`** = GENERATED cache of each tower's resolved base DMG/RNG/SPA at tier 1 / ML 1 / no trait / mid-roll / asc 0 —
  **SPA already inverted**. AD-Game owns it, the Lobby only consumes; `Get(towerId)` → nil for unknown ids, **Farm has no DMG/SPA
  keys**, validator Game-only. ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema v3** (B29, `72d3944f`) from
  **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**) — shares the Game's profile. v3's `BannerChoices` is what Selection banners
  (B30) store their pick in.
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall, COLLECTION/PLAY pedestals); spawn on the plaza.
  **Its presence is the Lobby Place assertion** (paired with `RS.Configs.Towers` being ABSENT — the Game has the tower configs, this
  Place does not).
- **Flow:** - **`GetUnitViews` is the SINGLE profile read path** (ADR-0004): additive changes are free, a breaking one needs contract
  treatment. **`GetCollection` is RETIRED; do not add a second read path.** Per owned uuid: `Uuid, TowerId, Name, Tier` (shared
  `ItemCatalog`), `Level, XP, Trait, Shiny, Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls`,
  `Grades = {DMG,RNG,SPA}` — plus `Loadout`, `Currencies`, `PlayerXP/PlayerLevel`, `MaxLoadout`, `Items {[itemId]=count}`. **No
  resolved DMG/RNG/SPA, no XpPct, NO cost and NO element** (B24). Clients never read profiles. `RS.Remotes` holds **19** (B30
  `ChooseBannerUnit`, B31 `SellUnits`). - Stage select + difficulty = the `RS.Configs.StageRegistry` mirror + `GetStages`; captures
  (StageId, DifficultyPercent). `StageSelectScreen` was DELETED at B19 — PlayGUI covers stage select, difficulty and launch;
  `GetStages` SURVIVES (ReturnScreen calls it). **`ClientEvents .OpenStageSelect` is PlayGUI's public open event** — fire it with an
  act id. The mirror carries `StageNumber`/`StageName`/`ActNumber`/`ActName` copied VERBATIM from the Game's StageConfigs.
  **`DisplayName` ≠ `ActName`**; only the `Id` is re-validated Game-side, so a rename there goes stale **silently** — update both in
  one breath. Difficulty here is the **WIRE** scale 1–1000 (100 = normal); PlayGUI's 1–100 is display-only (ADR-0011). - Parties +
  reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`, `StarterGui.PartyScreen`, and since B19 PlayGUI's
  `StartButton`) — teleport contract **v4** (`Loadout` carries unit **uuids** since A2; **`DifficultyMode` "Normal"/"Insane" since
  B20**; version from `LobbyConfig.MatchLaunchVersion`, must equal the Game's `GameConfig.TeleportPayloadVersion` — **v3 and v4 do NOT
  interoperate**). v4 (B23) adds `IsMatchmade` and widens `HostUserId` to the ELECTED match host. - **`Server.Lobby.LaunchService`
  (B23) is THE launch body** — loadout, payload, reserve+teleport — required by BOTH `PartyService` and `MatchmakingService`. **ONE
  path with one more caller, NOT a second path** (§12): `PartyService` is a `Script` and cannot be required, which is why the body had
  to move. `Remotes.RequestLaunch` is still the only CLIENT entry. - **`Server.Lobby.{MatchmakingService, MatchmakingRules}` (P7, B23)
  — the GLOBAL QUEUE.** MemoryStore map keyed `actId|stageNumber|mode|difficultyBucket` off the attributes P4 publishes. **An entry is
  a PARTY, never a player**; packing only adds WHOLE entries, so "never split" holds by construction. Host = **lowest userId** (every
  server elects identically, no round trip). **The match runs at the host's EXACT wire value — never an average**, which would move
  everyone's `GoldBand` payout. `MatchmakingRules.BucketOf` is the ONE home for queue difficulty arithmetic and is **not** the
  ADR-0011 conversion. Timeout 45s **OFFERS** solo. **The mode joins the payload in `PartyService`, not the UI:** P4 publishes
  `DifficultyMode`, P6's `LobbyController` passes it through `RequestLaunch` verbatim, `PartyService` validates it (anything but
  `"Insane"` → `"Normal"`). `buildLoadout` = saved `Loadout` filtered to still-owned uuids, else auto by MetaLevel desc, capped at
  `MaxLoadoutSize`. `GamePlaceId` = **125430066355564**. Only the party HOST may launch; errors come back on `PartyState`. -
  **MatchReturn (v3):** `Server.Lobby.MatchReturnService` reads `TeleportData.MatchReturn` on join (version from `LobbyConfig`, NOT
  hardcoded; validates version/Outcome/stage; drops an unknown `SuggestNextActId` — a stale mirror fails safe) and serves it via
  `Remotes.GetMatchReturn`. `ReturnScreen` = welcome-back banner; CONTINUE fires `OpenStageSelect`. Harness `DevSimulateReturn` **only
  fires on JOIN** — set it in the EDIT datamodel and restart Play. - **Starter tower choice:** `RS.Configs.StarterTowerConfig`
  (Archer/Knight/Mage), `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal
  `StarterGui.StarterChoiceScreen` (REAL tree, card = `Root.Panel.CardsRow.CardTemplate`). Eligible at ZERO **units**; grants a uuid
  `UnitInstance` mirroring `GrantUnit` (**StatRolls via shared `StatGradeConfig.RollAll`**), never clobbering an existing one. Harness
  `DevSimulateFirstJoin`. `MaxLoadoutSize = 6`.

## UI kit + screens (AD-UI)

**B36 — THE LOBBY SETTINGS SCREEN IS LIVE, AND THE WATCHDOG THAT WAS NEVER RUNNING IS FIXED.** The user copied `StarterGui.Settings`
across, so B35's deployed-and-waiting code now builds here: **6 rows / 5 tabs** (the Game draws 11 from the SAME file).
**`ScreenBootWatchdog` read `script.Source` at runtime — a LocalScript CANNOT (plugin capability) — so it threw at EVERY boot from B34
and reported nothing. B34's "verified 19/19" ran the check inside `execute_luau`, WHICH HAS plugin capability: a re-implementation was
tested, not the deployed script.** Now a PAIRED marker (`BootComplete=false` first executable line, `true` last) gives nil/false/true
with no `Source` read. **The start marker goes AFTER `--!strict`** — the directive must stay on line 1 or Luau silently drops strict
mode, and prepending it broke all 21 scripts at once. `SettingsUI` → **`7e5a736a`**. First real run: `21/21 finished after 15s`.


**B35 — ONE SETTINGS SYSTEM FOR BOTH PLACES. FULL DOC: `docs/systems/settings.md`.** 4 shared entries at IDENTICAL paths in both
Places (`SettingsConfig` `5f0dc44d`, `SettingsService` `8b3b1a72`, `ClientSettings` `a3a9d32f`, `SettingsUI` `7e5a736a`) — identical
paths are why it cost ZERO consumer edits in the Game. Entries declare `Scope` + `Kind`, so **`SettingsUI` has no Place branch
anywhere**. **`Sanitize` is Scope-BLIND ON PURPOSE** — one profile serves both Places, so dropping out-of-scope keys would permanently
lose the other Place's prefs. Manifest **31 → 35**, `Remotes` **21 → 22**. Two real bugs fixed: the volume slider drove a `MasterSFX`
group that never existed, and the join-time fetch could beat the profile load and cache DEFAULTS for the session.
`StarterPlayerScripts.LobbySettingsActions` registers this Place's only action, `TeleportToSpawn`.

**B32-B34 — THE FEEDBACK LAYER + ITS LESSONS. FULL DOC: `docs/systems/ui-feedback.md` — read it before touching any button, sound,
confirm or toast.** The user REBUILT `HUD.Left.Buttons`, renaming every screen's entry point to **`UnitsButton`/`SummonButton`/
`PlayButton`/`InventoryButton`/`QuestsButton`/`ProfileButton`** (`Play` had vanished; `ShopButton` became it). All six are tagged
`UIKitButton` and **panel-style**, which `UIKit.Button` DETECTS. **Audio = paste a SoundId onto a real `Sound` under `SoundService`.**
ONE of each, do not add a second: `UIKit.Confirm` (confirm dialog), `UIKit.Notify` `5e2b09d4` (toasts), `UIKit.UnitCard` `bd2421c5`
(card viewport + tier paint for all four card screens), `Server.Meta.UnitFlagsService` (`Favorited`/`Locked`).
**The 0.05 `UIHoverStroke.Thickness` is the user's deliberate choice (B35) — do not "fix" it.**
**LESSON (B33):** a retired `SellConfirm` was deleted while six bare `WaitForChild` calls still pointed at it; **a bare
`WaitForChild` NEVER times out**, so the controller stopped at its first declaration and the screen SILENTLY never booted. Authored
lookups now use `need()`; the 334 bare calls were deliberately NOT swept — the watchdog names hangs instead.
**RULE (B33): TOAST EVENTS, LABEL STATE** — toasts self-erase, so a still-true condition stays on a label. `CurrencyChanged` carries
no payload; `Configs.Meta.PlayerLevelConfig` is the ONE XP curve and drives `ExpBar`. **`StarterGui.Summon` is the user's UNFINISHED
replacement for `SummonScreen` — do not touch it.**

Four docs: **`ui-kit.md`** = the Place-neutral kit (9 controllers in `RS.Shared.UIKit` + 7 templates, drift-controlled).
**`ui-feedback.md`** = buttons/sound/confirm/toasts. **`settings.md`** = the cross-Place settings system. **`lobby-ui.md`** = this
Place's SCREENS; **`play-menu.md`** = PlayGUI + LoadingScreen. All `DevAutoOpen` harnesses OFF. Units-screen cards ARE
`Kit.UnitIconV2` clones since **B27b** — ADR-0009's screen-local `UnitTemplate` is gone and any stray copy is destroyed at boot.

**`ObtainRewardsGUI` — the reward-reveal surface (detail in `lobby-ui.md`). Fire it, never rebuild:**
`ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`. Grants QUEUE; click 1 = SKIP, 2 = CLOSE. Its pop
`UIScale` is on runtime CLONES only — **never add one to hashed canon.**

**`PlayGUI` + `LoadingScreen` — the Play menu, **P1–P7 COMPLETE** (B14–B23). FULL DOC: `docs/systems/play-menu.md` — read it FIRST;
law: `blueprints/playgui.md`.** Entry is **`HUD.Left.Buttons.PlayButton`** (renamed from `Play` at B32) → veil → other ScreenGuis
hidden → `Main.MainMenu`. Five things not to re-derive: the three frames are **CanvasGroups** and the menu camera is Scriptable
(**read `Workspace.PlayGUICamera.CFrame`, never write it**); **`PlayGUI.DifficultyScale` is THE ONE ADR-0011 conversion** — never
write a second; selection travels as ATTRIBUTES on `StoryModeFrame.SelectedAct`, edge-triggered on **`SelectionSerial`**; every
lookup is NON-RECURSIVE on purpose (duplicate names under both frames); labels with no data source are HIDDEN, not zeroed, except
the **live B21 reward preview**, mirrored into `LobbyFrame` from ONE `GoldBand` computation. `LoadingScreen` is Lobby-local, NOT
drift-controlled (§4). **P7 (the global queue, §11) SHIPPED at B23 on teleport v4.** `FindMatchButton` — under **StoryModeFrame**,
not MainMenu — is LIVE: `PlayGUIController` no longer disables it and the new `MatchmakingController` (the FIFTH PlayGUI script)
owns it; its `InactiveOverlay` stays authored but hidden. **MemoryStore works from Studio; `ReserveServer` is 403 here**, so the cross-server handoff needs a live two-client run.

## Gacha — banner ENGINE built (B3, 2026-08-09). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*, Meta.MetaConfig}`, driven by
`RS.Remotes.RequestSummon`. UI shipped B6/B7/B8. Rules:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies` inline; its unit record stays
  byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is SHARED canon** (`6badac1d`), **not deployed to the Game** — MISSING there is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE**; no push remote. Pity uses `Data.Pity[ref]` (no schema bump); pulls count on
  `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008).
- **SELECTION banners LIVE at B30 (blueprint B4 COMPLETE) — FULL DOC: `docs/systems/gacha-selection.md`, read it first.**
  `SSS.Server.Meta.BannerChoiceService` + `Remotes.ChooseBannerUnit` are **the ONE writer of `Data.BannerChoices`**; **`ChosenAtDay`
  is a `MetaMath.Slot` DAY NUMBER, not a timestamp.**
- **SELL DUPES LIVE at B31 (blueprint C3 COMPLETE) — doc: `docs/systems/ascension.md`.** **`UnitConsumeRules` = THE ONE "may this unit
  be destroyed" rule** (Locked/Favorited/equipped/spirit), shared with ascension's `PickDupe`; **`GrantService.SellUnits` is the ONLY
  `Data.Units` delete** and it CREDITS BEFORE DESTROYING. Prices are shared `TierConfig.GetSellValue` (0 for an unknown tier, so it
  can never mint Silver). UI = multi-select in Units; the confirm goes through `UIKit.Confirm`, messages through toasts (B32/B33).
  Harness `UnitsGUI.DevSell`.

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

**Not built (`docs/ROADMAP.md` has the rows):** **Party** and **Return** are still script-built.

**`STATE.md` is the canon list — read it, not this.** Only the Lobby-specific detail lives here:

- **v3/v4 do NOT interoperate:** a partial publish breaks EVERY launch (version mismatch).
- **AD-UI:** unit models are all `UnitModels.Placeholder`; `ItemHoverCard` split. `QuickSellButton` wired B31; `FavoriteButton` +
  `LockUnitButon` (sic) wired B32 through `UnitFlagsService` (the ONE writer). **`HUD.Right.UpperRight`'s five buttons
  (`RedeemCodes`/`LeaderBoards`/`InviteFriends`/`Inbox`/`Settings`) are the user's, tagged at B35 — only `Settings` is wired.**
- **V2 kit: ✅ ADOPTED BOTH PLACES AT B26, v1 RETIRED** (do not re-add). **Canon: `ui-kit.md`.** Not to re-derive: rarity is on the
  ROOT `UIGradient`, direct-children-only, **NO tier border** (user, B25); **no `ShinyBadge` in V2**.
- **B28 — SCREENS SLIDE** via **`Motion.slideIn`/`slideOut`**; test **`Motion.isOpen(main)`, not `gui.Enabled`** (still Enabled
  mid close-tween). Boot = `hideInstant()`; PlayGUI excluded (veil), `AscensionScreen` untouched.

## Ownership notes

- Lobby owns the teleport contract + the lobby UI/scene. **AD-Gacha owns the banner catalog + grant pipeline**
  (`docs/systems/gacha.md`, `gacha-selection.md`), home Place Lobby. Lobby CONSUMES and never edits: save schema, tower/progression/
  trait configs, **`RewardScalingConfig`** (AD-Game's — read the curve, never re-author it). Currency/XP/tower grants go through the
  same profile (never a second store) and **`GrantService`**, never inline.
