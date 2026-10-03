# Quests + Achievements + Events overhaul (B109) -- USER DECISIONS, 2026-10-03

The user's 18 reference screenshots (Quests / Achievements / Events / Event Shop / Event Quests /
party invite) + a 7-round Q&A. This file is the CONTRACT for B109; change it only with the user.

## Decisions (user, verbatim intent)
- **Scope: everything** -- Quests window, Achievements, Events window, Event Shop + Event Coin, party invite toast.
- **Build order:** M1 Quests -> M2 Achievements -> M3 Events window + Event Coin + Event Shop -> M4 Headliner Hunt
  -> M5 Infernal Hunt (Game) -> M6 party toast -> M7 Game pinned panel. Each milestone verified live + committed.
- **Style:** the refs' layout, colours and per-tab accents (cyan Daily, purple Weekly, red Achievements), built with
  our UI kit + `IconCatalog` placeholders; user swaps header art later. Authored Instances, templates cloned.
- **Old `QuestsGUI` (B42 blockout):** retired (`*_RetiredB109`), HUD Quests button opens the new window.

### Quests window (M1)
- Tabs **All / Daily / Weekly / Trial**. Trial = unit-unlock quests (finish to get a unit + its evolution item);
  refs pending -> tab exists with a "Coming soon" empty state.
- **Fixed lists** (not rolled): same Daily list + Weekly list for everyone, drafted by Claude as placeholders.
- **Weekly reset Monday 00:00 UTC**; daily reset unchanged (`MetaConfig` daily slot).
- **Daily Infinite map quests:** each day picks **2 random Infinite maps** (deterministic per day, same for all);
  each map has wave **25 / 50 / 75** quests. Separate from "clear 100 waves in any Infinite". With 1 map (The
  Farm) only 1 map is picked until a second exists.
- **Rewards may pay Battlepass EXP** (the Battle Pass exists: `BattlepassService`, `ServerStorage.BattlepassAddXP`).
- **Spend counters added:** GoldSpent / SilverSpent (lifetime) in `GrantService`'s spend path -> "Spend X" quests.
- **Search box + filter** button: category (Daily, Weekly, Unit/Trial, Infinite) + Claimable / Incomplete /
  Pinned / Hide claimed.
- **Pins: unlimited**, one shared list across quests / achievements / event quests; HUD tracker shows them all.
- **Extras:** Claim All (current tab), HUD badge on the Quests button, toast on quest completion, clickable
  underlined links (e.g. "Infinite", "Challenge") that open that Play mode.
- Row: kind + timer pill, title, description, pin; selected row -> detail panel (title, timer, description,
  objective box with bar `x/y (p%)`, reward cards, Claim/Incomplete button, pin button).

### Achievements (M2)
- Opened from the Quests window's "Achievements" button (and back via "Quests").
- Categories: **Story** (per map: all acts cleared on **Hard**), **The Collector** (own N distinct units, ...),
  **Infinite + Challenge**, **Secrets** (hidden until done).
- **Category milestone rewards** at 25/50/75/100% of the category (gift button) + progress bar.
- Rewards: **items/currency only** (no titles/banners yet). Claimed rows strike through + check. Claim All.

### Events (M3-M5)
- **One shared Event Coin** (`Currencies.EventTokens.EventCoin`, field exists since v2 -> no schema bump), one
  Event Shop, **unlimited** buying. Coin hover card -> "View Obtainment Methods" popup listing paying events.
- **Timing: mixed** -- UTC windows (Starts in / Ends in, Active/Upcoming groups switch by clock) + an optional
  per-event label ("Ends Update 4", "Permanent").
- Sidebar: event cards with banner art, collapsible Active / Upcoming groups, Back + Calendar (**Calendar stays
  "coming soon"**).
- **Center: per-event unit model** (rig from `RS.UnitModels`, idle-animated).
- Starter events: **Beginner's Path** (quest event, permanent), **Weekend Rush** (buff event, existing window),
  **Headliner Hunt** (unit hunt), **Infernal Hunt** (boss/loot).
- **Headliner Hunt:** obtain-unit quests (only obtains INSIDE the event window count) paying Event Coins; Evolve
  Rewards (evolving a featured unit pays); carousel of featured units swaps the center model; button to its banner.
- **Infernal Hunt (GAME work):** while live, each Story/Infinite/Challenge match has a % chance a roaming Infernal
  boss spawns (placeholder = tinted `FarmBoss`); kill = +1 boss + 1 **Infernal Chest** (openable item with a drop
  table, hover shows possible rewards), **15 chests/day**; milestone track over bosses defeated during the event,
  every 10 bosses, claim once each.

### Party invite toast (M6)
- Ref 1: "<name> has sent you a party invite!", stage banner with mode + difficulty icon, 4 member slots,
  Accept / Decline.

## Data (no schema bump planned)
- `Data.Quests` (QuestService, the one writer) is reshaped on first touch:
  `{ Daily = { Slot, Base = {[id]=n}, Claimed = {[id]=true} }, Weekly = { same }, Pins = { "Q:id" | "A:id" |
  "E:event:quest" }, Ach = { Claimed = {[id]=true}, Milestones = {[cat]={[i]=true}} } }`.
- New Game-written counters (`RewardCalculator`, cross-Place contract, lifetime unless noted):
  `InfiniteWaves`, `InfiniteDayBest = { Day, [stageId] = wave }` (per day), `HardClears = { [actId] = n }`,
  later `InfernalBosses` / event-boss daily cap.
- Lobby counters (`LifetimeCounters`): `GoldSpent`, `SilverSpent`.
