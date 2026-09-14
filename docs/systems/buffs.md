# Buffs — the active-buff layer (B57)

**Owner:** AD-Meta (Lobby). The two StarterGui surfaces were built by AD-Meta with the user's
go-ahead and are **AD-UI's to restyle** (ownership crossing, changelog B57). **Home Place: Lobby.**

## What it is

One read path + two display surfaces for "which buffs are active on this player right now".

- **`SSS.Server.Meta.BuffService`** (Script) — `RS.Remotes.GetActiveBuffs` (RemoteFunction).
  **READ-ONLY**; it writes nothing. Composes:
  - the timed **Luck** buff from `LuckService.State` (profile-backed, `Data.LuckBuff`), and
  - the **Weekend Rush** window from `WeekendRushConfig` (time-derived, no profile field),
  into one ordered list (most-recent first: a fresh Luck purchase leads, then the always-on
  Weekend Rush). Each buff carries its own `Title` / `Subtitle` / `Description` + `SecondsLeft`
  and a `Kind` (`"Luck"` / `"WeekendRush"`), so the client renders a card without knowing what a
  buff means. **New buff types plug in HERE** — add a branch in `activeBuffsFor`.
- **`StarterGui.HUD.BuffStrip` + `BuffStripController`** — always-visible strip, top-3 buffs as
  chips (short label + live timer), plus a **View All** button that fires `ClientEvents.OpenBuffs`.
- **`StarterGui.BuffsScreen` + `BuffsController`** — the dedicated screen: every active buff as a
  card (Title / Subtitle / Description + a countdown pill). Opens on `ClientEvents.OpenBuffs`.

Both controllers: `ChipTemplate` / `BuffCardTemplate` are `Visible=false` and parked under the
script; the controller only reads `GetActiveBuffs`, clones the template, sets text + accent, and
ticks the timer down locally each second (re-fetching on expiry + every 15s). Both are
boot-instrumented for `ScreenBootWatchdog` (paired `BootComplete` markers).

## Weekend Rush (`RS.Configs.Meta.WeekendRushConfig`, Lobby-local, PURE)

A time WINDOW, not a stored buff: active **Friday 00:00 -> Monday 00:00** in `TimezoneOffsetHours`
(default **UTC**), `RewardMultiplier = 2`. `IsActive(now?)` / `SecondsLeft(now?)` are pure and
derived from `os.time()` — the same "expiry is a comparison, never a write" shape as the Luck buff.

**The Lobby only DISPLAYS Weekend Rush.** The actual x2 on rewards + exp is BUILT in the Game (B57c: `RewardCalculator` doubles gold + all XP on a Victory; drops not doubled), currently via a byte-identical Game-LOCAL copy:
`docs/proposals/2026-09-10-weekend-rush-game-doubling.md`. When the Game consumes it, promote
`WeekendRushConfig` to shared canon (both Places byte-identical + manifest) so both read one window.

## The luck buff itself

Lives in `summon-screen.md` (`LuckConfig` pure + `LuckService`, the one writer of `Data.LuckBuff`).
Bought via gem packs, or the B57 **luck-only passes** (`LuckPackConfig` + `LuckPackService`). Luck
currently affects summon AND (B57b) trait + stat rerolls via best-of-N (`RerollLuckConfig`, Lobby-local; see `docs/proposals/2026-09-10-luck-on-rerolls.md`).
