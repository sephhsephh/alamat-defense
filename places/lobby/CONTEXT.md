# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B39) -->

The social/meta Place: players land here, view their collection, roll banners, pick a stage + difficulty, form parties, and teleport
into the Game place.

## Current live state

- **Shared canon: 35/35 PRESENT here (28 modules + 7 templates), hashes in `shared/manifest.json`.** `MetaMath` stays Lobby-only, so
  the GAME reports 34/35 — expected, not drift.
- **Trait rarity table (B12):** `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` are SHARED canon; API is `TraitRegistry.Roll(rng)`.
- **`UnitStatsCatalog`** = GENERATED cache of each tower's resolved base DMG/RNG/SPA at tier 1 / ML 1 / no trait / mid-roll / asc 0 —
  **SPA already inverted**. AD-Game owns it, the Lobby consumes; **Farm has no DMG/SPA keys**. ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema v4** (B39, `8e4224b9`) from
  **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**) — shares the Game's profile.
- **Scene:** `Workspace.Lobby` blockout hub; spawn on the plaza. **Its presence is the Lobby Place assertion** (paired with
  `RS.Configs.Towers` being ABSENT — the Game has the tower configs, this Place does not).
- **Flow:** - **`GetUnitViews` is the SINGLE profile read path** (ADR-0004): additive changes are free, a breaking one needs contract
  treatment. **`GetCollection` is RETIRED; do not add a second read path.** Per owned uuid: `Uuid, TowerId, Name, Tier` (shared
  `ItemCatalog`), `Level, XP, Trait, Shiny, Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls`,
  `Grades = {DMG,RNG,SPA}` — plus `Loadout`, `Currencies`, `PlayerXP/PlayerLevel`, `MaxLoadout`, `Items {[itemId]=count}`. **No
  resolved DMG/RNG/SPA, no XpPct, NO cost and NO element** (B24). Clients never read profiles. `RS.Remotes` holds **27**.
  - Stage select + difficulty = the `RS.Configs.StageRegistry` mirror + `GetStages`. `StageSelectScreen` was DELETED at B19 — PlayGUI
  covers stage select, difficulty and launch; `GetStages` SURVIVES (ReturnScreen calls it). **`ClientEvents.OpenStageSelect` is
  PlayGUI's public open event** — fire it with an act id. The mirror copies `StageNumber`/`StageName`/`ActNumber`/`ActName` VERBATIM
  from the Game's StageConfigs.
  **`DisplayName` ≠ `ActName`**; only the `Id` is re-validated Game-side, so a rename goes stale **silently**. Difficulty here is the
  **WIRE** scale 1–1000 (100 = normal); PlayGUI's 1–100 is display-only (ADR-0011). - Parties +
  reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`, `StarterGui.PartyScreen`, and since B19 PlayGUI's
  `StartButton`) — teleport contract **v4** (`Loadout` carries unit **uuids**; `DifficultyMode` "Normal"/"Insane"; version from
  `LobbyConfig.MatchLaunchVersion`, must equal `GameConfig.TeleportPayloadVersion` — **v3 and v4 do NOT interoperate**). v4 adds
  `IsMatchmade` and widens `HostUserId` to the ELECTED host. - **`Server.Lobby.LaunchService`
  (B23) is THE launch body** — loadout, payload, reserve+teleport — required by BOTH `PartyService` and `MatchmakingService`. **ONE
  path with one more caller, NOT a second path**: `PartyService` is a `Script` and cannot be required, which is why the body moved.
  `Remotes.RequestLaunch` is still the only CLIENT entry. - **`Server.Lobby.{MatchmakingService, MatchmakingRules}` (P7, B23)
  — the GLOBAL QUEUE.** MemoryStore map keyed `actId|stageNumber|mode|difficultyBucket` off the attributes P4 publishes. **An entry is
  a PARTY, never a player**; packing only adds WHOLE entries, so "never split" holds by construction. Host = **lowest userId** (every
  server elects identically, no round trip). **The match runs at the host's EXACT wire value — never an average**, which would move
  everyone's `GoldBand` payout. `MatchmakingRules.BucketOf` is the ONE home for queue difficulty arithmetic and is **not** the
  ADR-0011 conversion. Timeout 45s **OFFERS** solo. **The mode joins the payload in `PartyService`, not the UI:** P4 publishes
  `DifficultyMode`, `LobbyController` passes it through `RequestLaunch` verbatim, `PartyService` validates it (anything but
  `"Insane"` → `"Normal"`). `buildLoadout` = saved `Loadout` filtered to still-owned uuids, else auto by MetaLevel desc. `GamePlaceId`
  = **125430066355564**. Only the party HOST may launch; errors come back on `PartyState`. -
  **MatchReturn (v3):** `Server.Lobby.MatchReturnService` reads `TeleportData.MatchReturn` on join (version from `LobbyConfig`, NOT
  hardcoded; drops an unknown `SuggestNextActId` — a stale mirror fails safe) and serves it via `Remotes.GetMatchReturn`.
  `ReturnScreen` = welcome-back banner; CONTINUE fires `OpenStageSelect`. Harness `DevSimulateReturn` **only fires on JOIN** — set it
  in the EDIT datamodel and restart Play. - **Starter tower choice:** `RS.Configs.StarterTowerConfig` (Archer/Knight/Mage),
  `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal `StarterGui.StarterChoiceScreen` (card =
  `Root.Panel.CardsRow.CardTemplate`). Eligible at ZERO **units**; grants a uuid `UnitInstance` mirroring `GrantUnit` (**StatRolls via
  shared `StatGradeConfig.RollAll`**). Harness `DevSimulateFirstJoin`. `MaxLoadoutSize = 6`.

## UI kit + screens (AD-UI)

**B39 — EVENT DAILIES + REDEEM CODES + THE PENDING-REVEAL QUEUE. Docs: `daily-rewards.md`, `redeem-codes.md`, `reward-push.md`.**
**SCHEMA v3 → v4** (`ProfileTemplate` `8e4224b9`, hash-matched BOTH Places): `EventLoginStreaks` + `RedeemedCodes` + `PendingReveals`
in **ONE bump** — a bump costs the both-Places PUBLISH, not the field. `Migrations[3]` is a no-op like `[2]`. `Remotes` **25 → 27**.
**`EventDailyConfig`** = the EVENT ladder, a DATE WINDOW and deliberately **NOT a banner** (ending a banner would delete a ladder
players are mid-way through). `DailyRewardService` also writes `Data.EventLoginStreaks`, extended **ADDITIVELY** so the deployed B38
controller kept working: top-level fields and `ClaimDaily()` still mean the PERMANENT track; the event is a new `Event` sub-table and
`ClaimDaily("Event")`. Event ladders **do NOT wrap**. **`CodeRegistry` + `CodeService`** (THE one `Data.RedeemedCodes` writer) — **every
code is PUBLIC** (the registry replicates), and **the rate limit is SECURITY, not UX**. **`PendingReveals`** (THE one
`Data.PendingReveals` writer) + `RewardPush.ToOrQueue`/`.Drain` + `RevealDrainService`: **DRAINING MUST NEVER GRANT**, and the drain is
a CLIENT-ANNOUNCED handshake because `FireClient` does not queue for a client that is not listening. **B37's "grant made while AWAY"
gap was MIS-STATED** — an offline player has no loaded profile, so no offline grant exists; true offline delivery needs `MessageAsync`.
**DRIFT REPAIRED:** `UIKitBootstrap` → **`9c9539c0`** in both Places. **PENDING (USER): two SCREENS**, specs in `docs/specs/`.


**B38 — DAILY REWARDS SHIPPED. FULL DOC: `docs/systems/daily-rewards.md`.** `Configs.Meta.DailyRewardConfig` (pure) +
`Server.Meta.DailyRewardService` (**THE one writer of `Data.LoginStreak`**) + `HUD.DailyRewardsController` + `DevDailyRewind`.
7-day cycle, **miss a day = reset to 1** (user); **PLACEHOLDER BALANCE**. **GRANT FIRST, MARK SECOND** — Grant can refuse, the mark
cannot. A claim is a CLICK, so it reveals via the RETURN VALUE, **not `RewardPush`**.


**B37 — THE SERVER CAN REVEAL A GRANT THE PLAYER NEVER ASKED FOR. FULL DOC: `docs/systems/reward-push.md`.** `Remotes.PushRewards` +
`Server.Meta.RewardPush` + `StarterPlayerScripts.RewardPushReceiver`. **IT IS OPT-IN — `GrantService` NEVER pushes**, so a double
reveal is impossible BY CONSTRUCTION, not by discipline. **Rule: player's click → the RETURN VALUE; server decided → `RewardPush`.**
`ObtainRewardsGUI` needed **zero** changes. Grant FIRST, push the SAME views, never push a refused grant.


**B36 — THE LOBBY SETTINGS SCREEN IS LIVE, AND THE WATCHDOG THAT NEVER RAN IS FIXED.** The user copied `StarterGui.Settings` across:
**6 rows / 5 tabs** here, 11 in the Game, from the SAME file. **`ScreenBootWatchdog` read `script.Source` at runtime — a LocalScript
CANNOT — so it threw at EVERY boot from B34; B34's "verified 19/19" ran the check inside `execute_luau`, WHICH HAS plugin capability,
so a re-implementation was tested rather than the deployed script.** Paired markers now, and **the start marker goes AFTER
`--!strict`** or Luau silently drops strict mode. `SettingsUI` → **`7e5a736a`**.


**B35 — ONE SETTINGS SYSTEM FOR BOTH PLACES. FULL DOC: `docs/systems/settings.md`.** 4 shared entries at IDENTICAL paths in both
Places (`SettingsConfig` `5f0dc44d`, `SettingsService` `8b3b1a72`, `ClientSettings` `a3a9d32f`, `SettingsUI` `7e5a736a`) — identical
paths are why it cost ZERO consumer edits. `Scope` + `Kind` mean **`SettingsUI` has no Place branch anywhere**. **`Sanitize` is
Scope-BLIND ON PURPOSE** — one profile serves both Places, so dropping out-of-scope keys would permanently lose the other Place's
prefs. Manifest **31 → 35**. `LobbySettingsActions` registers `TeleportToSpawn`.

**B32-B34 — THE FEEDBACK LAYER + ITS LESSONS. FULL DOC: `docs/systems/ui-feedback.md` — read it before touching any button, sound,
confirm or toast.** The user REBUILT `HUD.Left.Buttons`; all are tagged `UIKitButton` and **panel-style**, which `UIKit.Button`
DETECTS. **Audio = paste a SoundId onto a real `Sound` under `SoundService`.** ONE of each, do not add a second: `UIKit.Confirm`,
`UIKit.Notify`, `UIKit.UnitCard`, `Server.Meta.UnitFlagsService`. **The 0.05 `UIHoverStroke.Thickness` is the user's deliberate choice
(B35) — do not "fix" it.** **LESSON (B33):** a bare `WaitForChild` NEVER times out, so a deleted authored instance made a whole screen
silently never boot; authored lookups use `need()` and the 334 bare calls were NOT swept — the watchdog names hangs. **RULE (B33):
TOAST EVENTS, LABEL STATE.** **`StarterGui.Summon` is the user's UNFINISHED `SummonScreen` replacement — do not touch it.**
Which doc is which: `docs/INDEX.md`. All `DevAutoOpen` harnesses OFF. Units-screen cards ARE `Kit.UnitIconV2` clones since **B27b**.

**`ObtainRewardsGUI` — the reward-reveal surface (detail in `lobby-ui.md`). Fire it, never rebuild:**
`ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`. Grants QUEUE; click 1 = SKIP, 2 = CLOSE. Its pop
`UIScale` is on runtime CLONES only — **never add one to hashed canon.** Summon, sell, daily, event daily, codes AND the push path all
feed this ONE event.

**`PlayGUI` + `LoadingScreen` — the Play menu, P1–P7 COMPLETE (B14–B23). FULL DOC: `docs/systems/play-menu.md` — read it FIRST; law:
`blueprints/playgui.md`.** Entry is **`HUD.Left.Buttons.PlayButton`** → veil → other ScreenGuis hidden → `Main.MainMenu`. Not to
re-derive: the three frames are **CanvasGroups** and the menu camera is Scriptable (**read `Workspace.PlayGUICamera.CFrame`, never write
it**); **`PlayGUI.DifficultyScale` is THE ONE ADR-0011 conversion**; selection travels as ATTRIBUTES on `StoryModeFrame.SelectedAct`,
edge-triggered on **`SelectionSerial`**; every lookup is NON-RECURSIVE on purpose (duplicate names under both frames); labels with no
data source are HIDDEN, not zeroed. `LoadingScreen` is Lobby-local, NOT drift-controlled. **P7 SHIPPED at B23 on teleport v4**;
`FindMatchButton` is LIVE under **StoryModeFrame**. **`ReserveServer` is 403 in Studio**; the two-client run is **VERIFIED (user, B38)**.

## Gacha — banner ENGINE built (B3). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*, Meta.MetaConfig}`, driven by
`RS.Remotes.RequestSummon`. Rules:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies` inline; its unit record stays byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is SHARED canon** (`6badac1d`), **not deployed to the Game** — MISSING there is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE** for anything the player CLICKED. B37 added `RewardPush` for server-initiated grants only —
  summon must NOT use it. Pity uses `Data.Pity[ref]`; pulls count on `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008).
- **SELECTION banners LIVE at B30 (blueprint B4 COMPLETE) — FULL DOC: `docs/systems/gacha-selection.md`, read it first.**
  `SSS.Server.Meta.BannerChoiceService` + `Remotes.ChooseBannerUnit` are **the ONE writer of `Data.BannerChoices`**; **`ChosenAtDay`
  is a `MetaMath.Slot` DAY NUMBER, not a timestamp.**
- **SELL DUPES LIVE at B31 (blueprint C3 COMPLETE) — doc: `docs/systems/ascension.md`.** **`UnitConsumeRules` = THE ONE "may this unit
  be destroyed" rule**, shared with ascension's `PickDupe`; **`GrantService.SellUnits` is the ONLY `Data.Units` delete** and it CREDITS
  BEFORE DESTROYING. Prices are `TierConfig.GetSellValue` (0 for an unknown tier, so it can never mint Silver). Harness `DevSell`.

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

**`STATE.md` is the canon list — read it, not this.** **Not built (`docs/ROADMAP.md` has the rows):** **Party** and **Return** are
still script-built. Only the Lobby-specific detail lives here:

- **v3/v4 do NOT interoperate:** a partial publish breaks EVERY launch (version mismatch).
- **AD-UI:** unit models are all `UnitModels.Placeholder`; `ItemHoverCard` split. `QuickSellButton` wired B31; `FavoriteButton` +
  `LockUnitButon` (sic) wired B32 through `UnitFlagsService` (the ONE writer). **Unwired HUD buttons:** `UpperRight`'s `LeaderBoards`/
  `InviteFriends`/`Inbox` (only `Settings` is), `Buttons`' `BattlePass`/`Event`; **`RedeemCodes` needs only its screen, `DailyRewards`
  is wired but gets a fuller screen.**
- **V2 kit: ✅ ADOPTED BOTH PLACES AT B26, v1 RETIRED** (do not re-add). **Canon: `ui-kit.md`.** Not to re-derive: rarity is on the
  ROOT `UIGradient`, direct-children-only, **NO tier border** (user, B25); **no `ShinyBadge` in V2**.
- **B28 — SCREENS SLIDE** via **`Motion.slideIn`/`slideOut`**; test **`Motion.isOpen(main)`, not `gui.Enabled`** (still Enabled mid
  close-tween). Boot = `hideInstant()`; PlayGUI excluded (veil), `AscensionScreen` untouched.

## Ownership notes

- Lobby owns the teleport contract + the lobby UI/scene. **AD-Gacha owns the banner catalog + grant pipeline**, home Place Lobby.
  Lobby CONSUMES and never edits: save schema, tower/progression/trait configs, **`RewardScalingConfig`** (AD-Game's — read the curve,
  never re-author it). Grants go through the same profile and **`GrantService`**, never inline.
