# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B40) -->

The social/meta Place: collection, banners, stage + difficulty select, parties, and the teleport into the Game place.

## Current live state

- **Shared canon: 35/35 PRESENT here**, hashes in `shared/manifest.json`. `MetaMath` stays Lobby-only, so the GAME reports 34/35 —
  expected, not drift. **Compare live hashes to BOTH `hash` and `deployed.<Place>` field by field**, or real drift hides (B39).
- **Trait rarity table (B12):** `RS.Configs.Traits.*` are SHARED canon; API is `TraitRegistry.Roll(rng)`, not `RollTrait`.
- **`UnitStatsCatalog`** = GENERATED cache of resolved base DMG/RNG/SPA at tier 1 / ML 1 / mid-roll / asc 0, **SPA already inverted**.
  AD-Game owns it; **Farm has no DMG/SPA keys**. ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema v4** (`8e4224b9`, PUBLISHED B40)
  from **Beta1_PlayerDataDev1** (prod **Beta1_PlayerData**) — shares the Game's profile.
- **Scene:** `Workspace.Lobby` blockout hub. **Its presence is the Lobby Place assertion**, paired with `RS.Configs.Towers` being ABSENT.
- **Flow:** - **`GetUnitViews` is the SINGLE profile read path** (ADR-0004): additive changes are free, a breaking one needs contract
  treatment. **`GetCollection` is RETIRED; do not add a second read path.** Per owned uuid: `Uuid, TowerId, Name, Tier` (shared
  `ItemCatalog`), `Level, XP, Trait, Shiny, Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls`,
  `Grades = {DMG,RNG,SPA}` — plus `Loadout`, `Currencies`, `PlayerXP/PlayerLevel`, `MaxLoadout`, `Items {[itemId]=count}`. **No
  resolved DMG/RNG/SPA, no XpPct, NO cost and NO element** (B24). Clients never read profiles. `RS.Remotes` holds **31**.
  - Stage select = the `RS.Configs.StageRegistry` mirror + `GetStages` (`StageSelectScreen` was DELETED at B19; PlayGUI covers it, and
  `GetStages` SURVIVES for ReturnScreen). **`ClientEvents.OpenStageSelect` is PlayGUI's public open event.** The mirror copies
  `StageNumber`/`StageName`/`ActNumber`/`ActName` VERBATIM from the Game's StageConfigs; **`DisplayName` ≠ `ActName`**, and only the
  `Id` is re-validated Game-side, so a rename goes stale **silently**. Difficulty here is the **WIRE** scale 1–1000 (100 = normal);
  PlayGUI's 1–100 is display-only (ADR-0011). - Parties +
  reserved-server launch (`PartyService`, `LobbyConfig`, `StarterGui.PartyScreen`, PlayGUI's `StartButton`) — teleport contract **v4**
  (`Loadout` carries unit **uuids**; `DifficultyMode`; version from `LobbyConfig.MatchLaunchVersion`, must equal
  `GameConfig.TeleportPayloadVersion` — **v3 and v4 do NOT interoperate**; v4 adds `IsMatchmade` and widens `HostUserId` to the ELECTED
  host). - **`Server.Lobby.LaunchService`
  (B23) is THE launch body** — required by BOTH `PartyService` and `MatchmakingService`. **ONE path with one more caller, NOT a second
  path.** `Remotes.RequestLaunch` is still the only CLIENT entry. - **`Server.Lobby.{MatchmakingService, MatchmakingRules}` (P7)
  — the GLOBAL QUEUE.** MemoryStore map keyed `actId|stageNumber|mode|difficultyBucket`. **An entry is a PARTY, never a player**;
  packing adds WHOLE entries, so "never split" holds by construction. Host = **lowest userId** (every server elects identically, no
  round trip). **The match runs at the host's EXACT wire value — never an average**, which would move everyone's `GoldBand` payout.
  `MatchmakingRules.BucketOf` is the ONE home for queue difficulty arithmetic and is **not** the ADR-0011 conversion. Timeout 45s
  **OFFERS** solo. **The mode joins the payload in `PartyService`, not the UI.** `buildLoadout` = saved `Loadout` filtered to
  still-owned uuids, else auto by MetaLevel desc, capped to unlocked slots (B44). `GamePlaceId` = **125430066355564**. Only the party HOST may launch. -
  **MatchReturn (v3):** `MatchReturnService` reads `TeleportData.MatchReturn` on join (version from `LobbyConfig`, NOT hardcoded; drops
  an unknown `SuggestNextActId` — a stale mirror fails safe) and serves `Remotes.GetMatchReturn`. `ReturnScreen` = welcome-back banner.
  Harness `DevSimulateReturn` **only fires on JOIN** — set it in EDIT and restart Play. - **Starter tower choice:**
  `StarterTowerConfig` + `StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`, modal `StarterChoiceScreen`. Eligible
  at ZERO **units**; grants a uuid `UnitInstance` mirroring `GrantUnit`. Harness `DevSimulateFirstJoin`. `MaxLoadoutSize = 6`.

## UI kit + screens (AD-UI)

**B40 — THE TWO SCREENS, MAIL, THE SHOP AND QUESTS. Docs: `shop.md`, `quests.md`, `reward-push.md`.** `Remotes` **27 → 31**. NO schema
bump: `ShopStock` and `Quests` were BOTH in the template since v2 unwritten, like `LoginStreak` at B38 — **check the schema before
designing.** **SCREENS:** `StarterGui.DailyRewards` (2 tabs) + `StarterGui.RedeemCodes` are BLOCKOUT ART I scripted to the published
specs (user reversed "you author it"); **the specs stay the CONTROLLER'S CONTRACT**, so replacing the art costs ZERO code.
**`DailyRewardsButton` OPENS the screen now — it no longer claims**, via `ClientEvents.OpenDailyRewards` resolved LAZILY at click time
(the controllers boot in an unspecified order). **MAIL** (`MailService` + `MailDeliveryService`) closes B37's gap for real via
ProfileStore **`MessageAsync`** — no remote, no schema field, **no shared-canon edit**. **GRANT FIRST, THEN `processed()`** — both
persist in the SAME save, which makes at-least-once deliver exactly once; reveal via **`ToOrQueue`**, since mail often reaches someone
who IS online.
**SHOP** (`ShopConfig` + `ShopService`, THE one `Data.ShopStock` writer) is the game's **FIRST SILVER SINK** — verified first that
nothing spent Silver while B31 mints it. Stock DERIVED from `MetaMath.RngForSlot`, never stored; `Bought` RESETS on rollover;
**PRE-CHECK → SPEND → GRANT → MARK**; **the client sends a slot INDEX, never a price.** **QUESTS** (`QuestRegistry` + `QuestService`,
THE one `Data.Quests` writer): **progress is a DELTA against a baseline** taken at assignment, written ONCE per quest per day — a
lifetime counter read would finish every quest instantly for an established player. **Only `GachaPulls` + `Ascensions` counters exist**;
match-shaped quests are REFUSED and NAMED at boot until the GAME place writes its own.


**B39 — SCHEMA v3 → v4 + EVENT DAILIES + CODES + THE REVEAL QUEUE. Docs: `daily-rewards.md`, `redeem-codes.md`, `reward-push.md`.**
`ProfileTemplate` **`8e4224b9`**, hash-matched BOTH Places, PUBLISHED at B40: `EventLoginStreaks` + `RedeemedCodes` + `PendingReveals`
in **ONE bump** — a bump costs the both-Places PUBLISH, not the field. `Migrations[3]` is a no-op like `[2]`. **v4 is shipped, so a new
field now costs v5.** `Remotes` **25 → 27**. **`EventDailyConfig`** = a DATE WINDOW, deliberately **NOT a banner**; ladders **do NOT
wrap**; the service was extended **ADDITIVELY** so a deployed screen kept working. **`CodeService`** = THE one `Data.RedeemedCodes`
writer; **every code is PUBLIC** and **the rate limit is SECURITY, not UX**. **`PendingReveals`** = THE one `Data.PendingReveals`
writer; **DRAINING MUST NEVER GRANT**. **DRIFT REPAIRED:** `UIKitBootstrap` → **`9c9539c0`** in both Places, caught by comparing hashes
FIELD BY FIELD against the manifest rather than eyeballing the tool output.


**B38 — DAILY REWARDS. FULL DOC: `daily-rewards.md`.** `DailyRewardConfig` (pure) + `DailyRewardService` (**THE one writer of
`Data.LoginStreak`**). 7-day cycle, **miss a day = reset to 1** (user); **PLACEHOLDER BALANCE**. **GRANT FIRST, MARK SECOND** — now the
rule for daily, event, codes, shop AND quests.


**B37 — THE SERVER CAN REVEAL A GRANT THE PLAYER NEVER ASKED FOR. FULL DOC: `reward-push.md`.** **OPT-IN — `GrantService` NEVER
pushes**, so a double reveal is impossible BY CONSTRUCTION, not by discipline. **Rule: player's click → the RETURN VALUE; server
decided → `RewardPush`.** `ObtainRewardsGUI` needed **zero** changes.


**B36 — THE WATCHDOG THAT NEVER RAN IS FIXED, AND ITS LESSON GOVERNS ALL TESTING HERE.** It read `script.Source` at runtime — a
LocalScript CANNOT — so it threw at EVERY boot from B34, while B34's "verified 19/19" had run the check inside `execute_luau`, **WHICH
HAS plugin capability AND its own require cache**: a re-implementation was tested, not the deployed script. **Clone a module to exercise
a fresh copy.** Paired markers now, and **the start marker goes AFTER `--!strict`** or Luau silently drops strict mode. The Lobby
settings screen is live (6 rows / 5 tabs here, 11 in the Game, same file); `SettingsUI` → **`7e5a736a`**.


**B35 — ONE SETTINGS SYSTEM FOR BOTH PLACES. FULL DOC: `settings.md`.** 4 shared entries at **IDENTICAL paths** in both Places, which
is why it cost ZERO consumer edits. `Scope` + `Kind` mean **`SettingsUI` has no Place branch anywhere**. **`Sanitize` is Scope-BLIND ON
PURPOSE** — one profile serves both Places, so dropping out-of-scope keys would permanently lose the other Place's prefs. Manifest
**31 → 35**. `LobbySettingsActions` registers `TeleportToSpawn`.

**B32-B34 — THE FEEDBACK LAYER + ITS LESSONS. FULL DOC: `ui-feedback.md` — read it before touching any button, sound, confirm or
toast.** `HUD.Left.Buttons` are tagged `UIKitButton` and **panel-style**, which `UIKit.Button` DETECTS. **Audio = paste a SoundId onto a
real `Sound` under `SoundService`** (all 13 are empty ON PURPOSE — the user fills them at RELEASE; do not re-raise it). ONE of each, do
not add a second: `UIKit.Confirm`, `UIKit.Notify`, `UIKit.UnitCard`, `UnitFlagsService`. **The 0.05 `UIHoverStroke.Thickness` is the
user's deliberate choice — do not "fix" it.** **LESSON (B33):** a bare `WaitForChild` NEVER times out, so a deleted authored instance
made a whole screen silently never boot; authored lookups use `need()` and the 334 bare calls were NOT swept — the watchdog names hangs.
**RULE (B33): TOAST EVENTS, LABEL STATE.** **`StarterGui.Summon` is the user's UNFINISHED replacement — do not touch it.**
Which doc is which: `docs/INDEX.md`. All `DevAutoOpen` harnesses OFF.

**`ObtainRewardsGUI` — the reward-reveal surface (detail in `lobby-ui.md`). Fire it, never rebuild:**
`ClientEvents.ShowRewards:Fire({{Id="Archer",Level=12},{Id="Gold",Qty=250}})`. Grants QUEUE; click 1 = SKIP, 2 = CLOSE. Its pop
`UIScale` is on runtime CLONES only — **never add one to hashed canon.** Summon, sell, daily, event, codes, shop, quests, mail AND the
push path all feed this ONE event.

**`PlayGUI` + `LoadingScreen` — the Play menu, P1–P7 COMPLETE. FULL DOC: `play-menu.md` — read it FIRST; law: `blueprints/playgui.md`.**
Entry `HUD.Left.Buttons.PlayButton` → veil → other ScreenGuis hidden → `Main.MainMenu`. Not to re-derive: the three frames are
**CanvasGroups**; the menu camera is Scriptable (**read `Workspace.PlayGUICamera.CFrame`, never write it**); **`DifficultyScale` is THE
ONE ADR-0011 conversion**; selection travels as ATTRIBUTES on `StoryModeFrame.SelectedAct`, edge-triggered on **`SelectionSerial`**;
lookups are NON-RECURSIVE on purpose. **`ReserveServer` is 403 in Studio**; the two-client run is **VERIFIED (user, B38)**.

## Gacha — banner ENGINE built (B3). **Full doc: `docs/systems/gacha.md` — read it**

`SSS.Server.Meta.{GrantService, SummonEngine, SummonService}` + `RS.Configs.{Gacha.*, Banners.*, Meta.MetaConfig}`, driven by
`RS.Remotes.RequestSummon`. Rules:

- **`GrantService` is THE one grant path** (invariant 1) — never write `Currencies` inline; `Spend` is the one debit.
- **`RS.Shared.MetaMath` is SHARED canon**, **not deployed to the Game** — MISSING there is EXPECTED, not drift; it is what every per-day derivation (dailies, event, codes, shop, quests) agrees through.
- **Reveal = the remote's RETURN VALUE** for anything the player CLICKED; `RewardPush` is for server-initiated grants only. Pity uses
  `Data.Pity[ref]`; pulls count on `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008) — **and B40's quests read that counter.**
- **SELECTION banners LIVE at B30 — FULL DOC: `gacha-selection.md`.** `BannerChoiceService` + `Remotes.ChooseBannerUnit` are **the ONE
  writer of `Data.BannerChoices`**; **`ChosenAtDay` is a DAY NUMBER, not a timestamp.**
- **SELL DUPES LIVE at B31 — doc: `ascension.md`.** **`UnitConsumeRules` = THE ONE "may this unit be destroyed" rule**, shared with
  ascension's `PickDupe`; **`GrantService.SellUnits` is the ONLY `Data.Units` delete** and it CREDITS BEFORE DESTROYING. Prices are
  `TierConfig.GetSellValue` — **the Silver faucet B40's shop finally drains.**
- **REROLL CURRENCIES economy (B46):** `StatRerolls` now has everyday sources — `DailyRewardConfig`[4], `ShopConfig` (450 Silver, wt5), `BattlepassConfig` FREE tier 25, `QuestRegistry` ClearThree — plus Insane drops (B45); reachable in the normal loop, no longer Insane-only. Faucet↔sink table: **`economy-map.md`**. `Currencies.TraitRerolls` is a DEAD scalar (no faucet/sink; remove at v5).

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

**`STATE.md` is the canon list — read it, not this.** **Party** and **Return** are still script-built. Lobby-specific detail only:

- **Teleport v3/v4 do NOT interoperate:** a partial publish breaks EVERY launch.
- **AD-UI:** unit models are all `UnitModels.Placeholder`; `ItemHoverCard` split. `QuickSellButton` wired B31; `FavoriteButton` +
  `LockUnitButon` (sic) wired B32 through `UnitFlagsService`. **HUD button names all END IN `Button`** — B40 lost a live run looking up
  `RedeemCodes` because this list used to abbreviate them. **Unwired:** `LeaderBoards`/`InviteFriends`/`Inbox`/`BattlePass`/`Event`/
  `Quests`Button. **Wired:** `Settings`, `RedeemCodes` (B40), `DailyRewards` (B38/B40).
- **V2 kit: ✅ ADOPTED BOTH PLACES AT B26, v1 RETIRED.** **Canon: `ui-kit.md`.** Rarity is on the ROOT `UIGradient`,
  direct-children-only, **NO tier border** (user, B25); **no `ShinyBadge` in V2**.
- **B28 — SCREENS SLIDE** via **`Motion.slideIn`/`slideOut`** (opts is a TABLE, and `slideOut` owns BOTH flags); test
  **`Motion.isOpen(main)`, not `gui.Enabled`**. Boot teardown is INSTANT and each screen writes its own — **there is no
  `Motion.hideInstant`**. PlayGUI excluded (veil).

## Ownership notes

- Lobby owns the teleport contract + the lobby UI/scene. **AD-Gacha owns the banner catalog + grant pipeline**, home Place Lobby.
  Lobby CONSUMES and never edits: save schema, tower/progression/trait configs, **`RewardScalingConfig`** (AD-Game's — read the curve,
  never re-author it). Grants go through the same profile and **`GrantService`**, never inline.
