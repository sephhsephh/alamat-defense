# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B40) -->

The social/meta Place: collection, banners, stage + difficulty select, parties, and the teleport into the Game place.

## Current live state

- **Shared canon: 42/42 PRESENT here** (B58; `MetaMath` reached the GAME at B51, so it is no longer a Game gap). Hashes in `shared/manifest.json`.
  **B58 caught real drift here:** `MovementConfig` read `19421017` against a manifest of `9c7cbd32` — the USER's own `SprintSpeed` 26→56 /
  `DashSpeed` 70→300 re-tune, confirmed by them and RECORDED as canon (B22 precedent), then mirrored to the Game. All three now `19421017`. **Compare live hashes to BOTH `hash` and `deployed.<Place>` field by field**, or real drift hides (B39).
- **Trait rarity table (B12):** `RS.Configs.Traits.*` are SHARED canon; API is `TraitRegistry.Roll(rng)`, not `RollTrait`.
- **`UnitStatsCatalog`** = GENERATED cache of resolved base DMG/RNG/SPA at tier 1 / ML 1 / mid-roll / asc 0, **SPA already inverted**.
  AD-Game owns it; **Farm has no DMG/SPA keys**. ADR-0003. **B67 `3bb9b140` -> `ff870013`: it also carries `Costs`/`GetCost(towerId)` -- the PLACEMENT price the shared hotbar renders HERE, since this Place has no `TowerConfig` to read. The Game's `UnitStatsCatalogValidate` checks `Costs` against the live configs at boot, so this Place can never sit on a stale price; `UIKitHotbar` `ef691df9` -> `5b9f9260` reads it (peso + separators, label HIDDEN when a unit has no entry), retiring B27d's placeholder price. Verified here: Meteor 300 / Farm 150 / Warchief 350 -- Farm and Warchief identical to the Game.** **B68 SWEPT THE OTHER SIX SCREENS HERE** (Units, Index, Summon selection chips, Ascension, TraitReroll, StatReroll): all six still drew the TEMPLATE'S AUTHORED number via `Motion.SHOW_PLACEHOLDER_PRICES`, now **DELETED** (`UIKitMotion` `2d217ede` -> `ed85d82c`) along with every reader -- the Game had none left after B67, so the flag was alive only in THIS Place. The lookup + peso format + hide rule live in **`UIKit.UnitCard.paintPrice(root, towerId)`** (`bd2421c5` -> `bedb105e`); `UIKitHotbar` (`5b9f9260` -> `b2287846`) calls it too, so a Units card and the Game's hotbar slot are ONE function, not two that agree. `paintPrice(root, nil)` HIDES. **Ascension/TraitReroll/StatReroll no longer require `Motion` at all** -- that flag was its only use in them. Verified live: Units 16 cards (Necromancer 400 / Meteor 300 / Warchief 350 / Babaylan 300 / Farm 150 / Mage 200), Index all 8 towers, Ascension + both rerolls; watchdog 40/40. WARNING: the Summon CHIPS were NOT exercised -- the banner's "Change featured unit" button did not open the choice overlay on that profile (no refusal printed). **B68 did not touch that button**; observation for the user, not a diagnosis. **B70: `TraitRerollScreen` REBUILT** (Lobby-local; no shared canon touched). Flow: "+" slot → single-select picker → Trait Index (odds from `TraitDefinitions.Weight`, pity bars per UNIT) / filter grid (green = HUNTING) / Reroll (confirms if the ACTIVE trait is hunted) / Instant Roll / free ACTIVE↔STORED swap. `TraitRerollService` gained `rollOnce` (ONE roll path shared by both reroll routes so they cannot drift) + remotes `InstantRollTrait`, `SwapTraitSlots`, `SetTraitFilters` — **+3, created at boot by `ensure()` so they are absent from the saved tree.** ⚠ **The Edit datamodel holds 43 authored `Remotes` entries, which does NOT match the “47” earlier docs assert; the delta is measured, the total is not — recount before quoting it.** `LobbyServices` now returns `TraitFilters` on `GetUnitViews` — a second read path is what ADR-0004 exists to prevent. ⚠ **Instant Roll refuses with `no_filters`** and is ceilinged at 1000/call. **167 authored Instances tagged `B70Built`** (idempotent builder); the old `Grid`/`Detail`/`EmptyLabel`/`Subtitle` are HIDDEN, never deleted — remove by hand when happy. ⚠ **A modal `Card` needs `Active = true`** or clicks fall through to the scrim; **`UIListLayout.SortOrder` defaults to NAME**; and **click-outside-to-close is gone from this screen** because `input.Position` carries the 58px topbar inset and `AbsolutePosition` does not — the same latent bug still sits in Ascension/StatReroll/Index controllers. **B71: `StarterGui.ReturnScreen` is DELETED** (user: the post-match victory popup is unnecessary). Safe to delete outright because the whole banner was **BUILT IN SCRIPT** — `Instance.new` for the frame, title, subtitle and both buttons — so the ScreenGui held NO authored art, only the LocalScript; removing it also retires a standing violation of the never-generate-UI-in-scripts rule. A sweep confirmed its Controller was the ONLY `GetMatchReturn` consumer here. **`MatchReturnService` is deliberately KEPT** — it receives the Game→Lobby teleport payload (contract v4) and still serves the remote, so the data survives if a different presentation is ever wanted. Boot scripts 40 → 39. `UIKitSound` re-hashed `108ef36e` -> `46ab4d7f` (shared; the BGM fallback fix — Lobby behaviour unchanged, its `BGM.Lobby` id was already set).
- **Boot:** `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()`. **Schema v8** (`d3d4e63c`, B72: +`UnitSlotsPurchased`, `Migrations[7]` a no-op). **B72 UNIT CAPACITY lives HERE:** `RS.Configs.Meta.UnitCapacityConfig` (200 +50 per 50,000 Silver; `CountUnits` = THE one pairs-count) + `SSS.Server.Meta.UnitCapacityService` (one writer; `BuyUnitSlots`, `ensure()`d at boot) + `SummonService` step 1b (refuses `unit_capacity_full` BEFORE the spend; other grants overflow) + `GetUnitViews.UnitCapacity` + `SummonController` refusal line/Notify. UI surfaces = B73. `unit-capacity.md`. Was v7 (`8f6520b4`, B69; user republishes both — this line said v5 until B69, having missed B55's v6 entirely). **v7: `UnitInstance.Trait` -> `ActiveTrait` + `StoredTrait`, + per-unit `TraitPity`, + `TraitFilters`.** Only ACTIVE is ever read; the bench moves only on an explicit swap. ⚠ **`Migrations[6]` is the first step since v1→v2 that does real work — `Reconcile()` does NOT descend into `Units[uuid]`, so per-unit fields are written by hand.** THIS Place's writers were migrated: `GrantService.newUnitInstance` + its view, `LobbyServices` (the `GetUnitViews` row), `StarterChoiceService`, `TraitRerollService`. **`SummonEngine`/`SummonService` needed NO change** — their `Trait` is a GRANT-OPTS key (a call argument), not a saved shape. The WIRE field keeps the name `Trait` and always carries the ACTIVE trait
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

**B57 — MONETISATION + BUFFS (AD-Meta; UI crosses AD-UI, user go-ahead).** Battlepass gamepass `1975634753` live (`Owned=true` VERIFIED). Gem packs wired + **NEW luck-only passes** (`LuckPackConfig`/`LuckPackService`, luck via `LuckService`, no currency) sell in a **LUCK BOOSTS** scroll below the gems on the summon screen. `ReceiptService` PROVEN (8 products; idempotency/unknown/refusal via `DevReceiptTest`; a real Robux charge UNTESTED). **Buffs:** `BuffService.GetActiveBuffs` (READ-ONLY) + always-visible HUD `BuffStrip` (top-3 + View All → `ClientEvents.OpenBuffs`) + `BuffsScreen` cards. **B58: `WeekendRushConfig` is now SHARED CANON** (`44c549f0`, manifest entry 42, byte-identical in both Places; window **Fri 00:00–Mon 00:00 UTC+8**, user's call). Still DISPLAY-ONLY here — the GAME applies the x2 (gold + all XP + every drop). Remotes **44→47**. Docs: `buffs.md`, `summon-screen.md`. **Luck-on-rerolls VERIFIED LIVE B58** (`bestOf=3` at `DevLuck=100` through the real `RerollTrait`/`RerollStats` remotes); best-of-N does NOT compare against the unit's current values, so a reroll can still downgrade. See STATE.md.

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
made a whole screen silently never boot; authored lookups use `need()` and the 334 bare calls were NOT swept — the watchdog names hangs. **B66: DOUBLE JUMP here and in the Game** (ordinary jump input via `JumpRequest` -- no new binding, so Space/gamepad A/mobile all work; one per airborne stretch, 0.2s re-arm because the key repeats, impulse from the Humanoid's own jump strength). Dash is unchanged HERE but now exists in the GAME too (user override of B54); `MovementConfig` `19421017`->`3598e7d0`, `MovementController` `e2668274`->`8e995f32`, both mirrored byte-identical. **⚠ The Game had to move Ability Q->V and Return-to-Lobby Q->L to free Q** -- a CAS bind sinks the key and marks it `gameProcessed`; **grep BOTH Places before binding any key in the shared controller.** **⚠ TWO WAYS A HUD BUTTON DIES SILENTLY (B65, both fixed).** (1) **BOOT RACE** -- the HUD is clickable from frame ONE but each controller wired its button at the END of its own file, and Roblox starts LocalScripts in a NON-DETERMINISTIC order, so a random subset was unconnected each join; **Roblox DROPS a click on an unconnected button, it does not queue it.** (2) **RESPAWN** -- `HUD.ResetOnSpawn = true`, so the HUD is re-cloned and every connection against the old copy dies; **only `PlayGUIController` re-bound**, so everything else stayed dead until rejoin (UnitsGUI/Hotbar/ExpBar survived by accident -- their own ScreenGui is ResetOnSpawn=true so the controller re-runs). FIX: `StarterPlayerScripts.HudEntry` -- `reserve({path})` at the TOP connects + buffers, `entry:bind(fn)` where the wiring used to be installs the handler and replays a buffered click, and it re-binds to every new HUD. Converted: Quests, Inbox, LeaderBoards, RedeemCodes, BattlePass, Units, Items, Summon. NOT converted on purpose: PlayGUI (self-rebinds) + the HUD-local scripts (DailyRewards/EventButton/InviteFriends/BuffStrip re-run with the HUD). `SettingsUI` is SHARED CANON so it carries the same logic INLINE (`7e5a736a`->`10f3d48c`, both Places). **⚠ `ProfileButton` is wired to NOTHING** -- never has been. **⚠ `StarterChoiceScreen` used to stay ENABLED at DisplayOrder 10 for every returning player** (100%-screen `Dim` authored Visible, held off only by `Root.Visible=false`) -- now disabled when there is no offer. RULED OUT, do not re-investigate: the LoadingScreen veil (clean at rest), the Settings dim (closes cleanly), boot hangs (watchdog 40/40).
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
  `RedeemCodes` because this list used to abbreviate them. **Unwired:** `InviteFriends`/`BattlePass`/`Event`/
  `Quests`Button. **Wired:** `Settings`, `RedeemCodes` (B40), `DailyRewards` (B38/B40), `LeaderBoards` (B47), `Inbox` (B48, v5). **HUD notification badges** (B49) on Inbox/Daily/Event/Quests/BP — counts from existing remotes, `notifications.md`.
- **V2 kit: ✅ ADOPTED BOTH PLACES AT B26, v1 RETIRED.** **Canon: `ui-kit.md`.** Rarity is on the ROOT `UIGradient`,
  direct-children-only, **NO tier border** (user, B25); **no `ShinyBadge` in V2**.
- **B28 — SCREENS SLIDE** via **`Motion.slideIn`/`slideOut`** (opts is a TABLE, and `slideOut` owns BOTH flags); test
  **`Motion.isOpen(main)`, not `gui.Enabled`**. Boot teardown is INSTANT and each screen writes its own — **there is no
  `Motion.hideInstant`**. PlayGUI excluded (veil).

## Ownership notes

- Lobby owns the teleport contract + the lobby UI/scene. **AD-Gacha owns the banner catalog + grant pipeline**, home Place Lobby.
  Lobby CONSUMES and never edits: save schema, tower/progression/trait configs, **`RewardScalingConfig`** (AD-Game's — read the curve,
  never re-author it). Grants go through the same profile and **`GrantService`**, never inline.
