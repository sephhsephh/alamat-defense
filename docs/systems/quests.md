# Quests — Daily / Weekly / Infinite (Lobby meta; rules shared with the Game)

<!-- owner: lobby | scope: lobby+game (rules shared) | last-verified: 2026-10-03 (B109 M1) -->

B109 rebuild from the user's references. Decisions: `docs/specs/2026-10-03-quests-events-overhaul.md`.
History (B40 random daily roll, B42 blockout screen): CHANGELOG.

| piece | what it is |
|---|---|
| `RS.Configs.Meta.QuestRegistry` | **SHARED CANON** (both Places). PURE content + progress math: `Daily`, `Weekly`, `InfiniteDaily`, `State(data)`, `ProgressOf`, `FindCurrent`. **Edit quests HERE.** |
| `SSS.Server.Meta.QuestService` | Lobby. **THE one writer of `Data.Quests`.** Remotes `GetQuests`, `ClaimQuest(id)`, `ClaimAllQuests(tab)`, `SetQuestPin(key,on)`. |
| `StarterGui.QuestsGUI` + `QuestsController` | Lobby. AUTHORED window (RowTemplate cloned). Old B42 blockout = `QuestsGUI_RetiredB109` (disabled). |
| `StarterGui.HUD.NotificationController` | HUD badge = claimable Daily + Weekly; "Quest complete" toast (first poll only seeds). |
| Game `HudInfoService` + `HudPanels` | Read-only match HUD panel: B109 M7 `Pins` = every pin with live progress (quests via `QuestRegistry.State`, achievements / event quests via `Data.Quests.PinMeta[key] = {Label,Name,Goal}` (Lobby QuestService writes it on pin; synced on join/60 s) + shared `GoalEval`); rotates every 6 s; no pins = first unfinished daily quest. |

## The lists (user, B109)
- **Fixed lists:** everyone gets the same `Daily` (8) and `Weekly` (8). Placeholder numbers — the user edits.
- **Daily Infinite map quests:** each day `InfiniteMapsForDay(day)` draws `MapsPerDay` (2) maps from
  `InfiniteDaily.Maps` (deterministic, same for everyone), each with wave **25 / 50 / 75** quests
  (`Inf_<stageId>_<wave>`). Only The Farm exists, so 1 map/day until a second `Maps` row is added.
- **Resets:** daily = `MetaConfig.ResetOffsetSec` (16:00 UTC = 00:00 PH). **Weekly = Monday 00:00 PH**
  (`MetaConfig.WeeklyResetOffsetSec = 288000`); the weekly CHALLENGE limit uses the same boundary.
- `Desc` may hold one `{Word}`: underlined + clickable, opening `Link` (Story / Infinite / Challenge via
  `ClientEvents.OpenStageSelect(mode|actId)`, Summon, Units, Shop, Craft).
- Rewards are `GrantService` rows; **`BattlepassXP`** (ItemCatalog Kind `BattlepassXP`) is routed by
  GrantService to `ServerStorage.BattlepassAddXP` — BattlepassService stays the one Battle Pass writer.

## ⚠ Counter quests are a DELTA against a baseline
Counters under `Data.Counters.Global` are LIFETIME totals. `QuestService` records each quest's baseline
ONCE per period (`Data.Quests.Daily/Weekly.Base[id]`) — on join, every 60 s for online players, and on
any read — and never rewrites it. Progress = current − baseline. Re-baselining on read is the classic
"my quest keeps going back to zero" bug. No baseline yet ⇒ honest 0 (the Game panel shows that too).

**Infinite map quests** have no baseline: they read `Counters.Global.InfiniteDayBest = { Day, [stageId] = wave }`
(the Game's per-day best).

## Counters (cross-Place contract: lifetime, monotonic, never renamed)
| counter | writer |
|---|---|
| `GachaPulls`, `Ascensions` | SummonService, AscensionService |
| `Feeds`, `TraitRerolls`, `StatRerollsDone`, `Crafts`, `Evolutions`, `ShopBuys` | Lobby `LifetimeCounters.Bump` |
| `GoldSpent`, `SilverSpent` (B109) | `GrantService.Spend` (the one spend path) |
| `DailyQuestsClaimed` (B109) | QuestService (claims of other daily quests) |
| `Clears`, `ClearsByStage`, `InsaneVictories` (= Lobby "Hard"), `ChallengeClears`, `Waves` | Game RewardCalculator |
| `InfiniteWaves`, `InfiniteDayBest`, `HardClearsByStage` (B109) | Game RewardCalculator |

`QuestRegistry.LiveCounters` lists what is written; a quest on any other counter is hidden and NAMED at boot.

## Data (`Data.Quests`, free-form since v2 — no schema bump)
`{ Daily = { Slot, Base, Claimed }, Weekly = { Slot, Base, Claimed }, Pins = { "Q:id" | "A:id" | "E:event:quest" } }`.
The B40 fields (`Progress`, `Claimed`, `PinnedQuestId`) are dropped on first touch. Pins are **unlimited**
(user; capped at 100 for profile size); claiming a quest unpins it.

## Claims: GRANT FIRST, MARK SECOND
A claim must name a CURRENT quest (`FindCurrent`), be complete and unclaimed; then `GrantService.Grant`,
then mark. Reveal = the RETURN VALUE (`ShowRewards`). `ClaimAllQuests` loops until nothing is claimable so
"Complete 6 daily quests" is collected in the same click. Reasons: `not_current`, `already_claimed`,
`not_complete`, `grant_failed`, `nothing_to_claim`, `busy`, `profile_not_loaded`, `bad_key`, `too_many_pins`.

## The window (B109, refs = Quests screenshots)
Title banner + Search + Filter (category Daily/Weekly/Unit/Infinite; Claimable/Incomplete/Pinned/Hide
claimed) + Achievements button; tabs All / Daily / Weekly / **Trial** ("coming soon": unit-unlock quests,
refs pending) + Claim All; list rows (kind + timer pill, title, desc link, pin, CLAIM chip, claimed check +
strike) sorted claimable → in progress → claimed; detail panel (objective bar, reward cards, Claim/Incomplete,
pin). Per-tab theme colour. Gamepad: B close (filter first), L1/R1 tabs, X claim, Y Claim All; window tagged
`GamepadMenu`. Studio harness: `QuestsGUI` attribute `DevOpen = "All" | "Daily" | "Weekly" | "Trial"`.

## Verified live (B109 M1, Lobby, real clicks)
Open from HUD; Weekly theme + 1d 3h timer; filter (Infinite) + Reset; pin (gold); 10x summon → `Summon`
claimable → Claim → reveal Silver x300 + Battlepass EXP x100, server `[DATA] Battlepass +100 XP` +
`Quest CLAIMED D_Summon`; GoldSpent 1300/5000 on the weekly quest; search "spend"; Story link → Play menu.
**Not yet observed live:** the completion toast; the Game-side Infinite/Hard counters (code-read only —
the Game is not play-tested, user rule).

## In the GAME (B123) -- K / the MatchHUD K button: view, pin and claim
The user copied `StarterGui.QuestsGUI` into the Game. Bookkeeping is the SHARED `RS.Shared.QuestBook` (box reshape,
baselines, claim marks, pins -- extracted from QuestService, which now calls it), rules stay in the shared
QuestRegistry, so both Places write the identical `Data.Quests`. Game server: `Server.Meta.MatchQuestService` (remotes
GetQuests / ClaimQuest / ClaimAllQuests / SetQuestPin). Only the GRANT differs (GrantService is Lobby-only):
- Currency -> `PlayerInventoryService.AddScalarCurrency`; Item -> `AddItem` (MaxOwned-capped);
  BattlepassXP -> `RewardCalculator.AddPendingBattlepassXP` (rides MatchReturn; BattlepassService stays its one writer).
- Anything else (unit / title / event token) refuses the WHOLE claim with `claim_in_lobby`; nothing is written.
- Achievements stay Lobby-only (button hidden by `QuestsGUI.QuestsMatchMode`, which also turns `ShowRewards` into a toast).
- Game-copy patches in QuestsController: `claim_in_lobby` text, Lobby-only links toast "Open that from the Lobby",
  `ClientEvents.ToggleQuests` (K toggles).
- Studio harness: `MatchQuestService:SetAttribute("DevBumpCounter", "Clears,10")` during Play.
- Known limit (same as match BP XP): Battle Pass EXP from an in-match claim is lost if the player leaves without the
  return teleport.
