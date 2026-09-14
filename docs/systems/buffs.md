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

## Weekend Rush (`RS.Configs.Meta.WeekendRushConfig`, **SHARED CANON** `44c549f0`, PURE)

A time WINDOW, not a stored buff: active **Friday 00:00 -> Monday 00:00** measured in
`TimezoneOffsetHours` = **8 (UTC+8, Asia/Manila — the user's call at B58)**, `RewardMultiplier = 2`.
`IsActive(now?)` / `SecondsLeft(now?)` are pure and derived from `os.time()` — the same "expiry is a
comparison, never a write" shape as the Luck buff. Window edges verified at B58: open exactly at
Fri 00:00 Manila, shut one second before, open through Sun 23:59, shut at Mon 00:00.

**PROMOTED TO SHARED CANON AT B58** (manifest 41 -> 42, `deployPath RS.Configs.Meta.WeekendRushConfig`,
owner AD-Meta, 42/42 verified in both Places). It was Lobby-local plus a byte-identical Game copy
through B57/B57c only because the repo shell was down and the promotion could not be committed safely.
**Both Places must read ONE window**: the Lobby draws the card and its countdown, the GAME applies the
x2. Two copies of one clock pays double in one Place while the other says the buff is over.

**What the GAME doubles on a VICTORY** (`RewardCalculator.GrantForPlayer`, gated on
`WeekendRushConfig.IsActive()`, server-authoritative): gold, account XP, tower XP, battlepass XP
(B57c) **and — since B58, the user's call — every DROP: stage drop-table items, Insane items and the
day's challenge FRAGMENTS.** The drop scaling multiplies each drop's `Count` at the single point where
all three sources are already in the `drops` list, so there is never a second place to keep in step;
the id and its `ItemCatalog` Kind routing are untouched, so a doubled CURRENCY still lands in
`Data.Currencies` (B45). A DEFEAT is never inflated — and a defeat rolls no drops at all.

**Verified live B58** on a real 15/15 Victory: `gold 628` against a 100-300 band (a 314 roll doubled),
`BP XP +250`, `WeekendRush x2`; and on an Insane Victory, `[DATA] Drop: StatRerolls x2 ->
Currencies.StatRerolls = 2` where Insane grants x1. Record: `docs/proposals/2026-09-10-weekend-rush-game-doubling.md`.

> ⚠ **Only CURRENCY drops are logged.** `RewardCalculator` prints `[DATA] Drop: ...` in the currency
> branch; the Item branch calls `AddItem` silently. Doubled `BannerTicket`/`TraitRerollToken` grants
> are therefore invisible in the console. They ride the same list and the same `Count`, so they are
> covered — but a silent grant path is one you cannot verify from a log, which is exactly how B45's
> mis-routed faucet came to "look wired". A print there is a cheap follow-up.

## The luck buff itself

Lives in `summon-screen.md` (`LuckConfig` pure + `LuckService`, the one writer of `Data.LuckBuff`).
Bought via gem packs, or the B57 **luck-only passes** (`LuckPackConfig` + `LuckPackService`). Luck
currently affects summon AND (B57b) trait + stat rerolls via best-of-N (`RerollLuckConfig`, Lobby-local; see `docs/proposals/2026-09-10-luck-on-rerolls.md`). **Best-of-N VERIFIED LIVE at B58** — `DevLuck=100`, real
`RerollTrait`/`RerollStats` remotes on a real owned unit, `bestOf=3` in both `[DATA] TraitReroll` and
`[DATA] StatReroll`. ⚠ **Best-of-N picks the best of N NEW candidates; it does not compare against what
the unit already had**, so a reroll at 100% Luck can still downgrade a good unit (observed at B58:
`DMG D->B RNG SS->C SPA A->D`). That is by design — the same way a trait reroll can land back on `None`
— but "Luck helps rerolls" reads to a player as "I cannot get worse". Open tuning question, user
decided at B58 to KEEP best-of-2/3 as built.
