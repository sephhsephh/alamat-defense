# Daily rewards — the login streak (Lobby meta, AD-Gacha canon)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B38) -->

The daily login reward: one claim per day from `HUD.Right.Buttons.DailyRewardsButton`, a 7-day cycle,
and a streak that **resets to day 1 if a day is missed**. Split out of `rewards.md` (match-end
payouts, AD-Game) at B38 on that file's 300-line cap — the reveal machinery it sits on is documented
there.


**Entirely Lobby-local. Shared canon unchanged at 35; save schema unchanged at v3.**

| piece | what it is |
|---|---|
| `RS.Configs.Meta.DailyRewardConfig` | PURE rules — the 7-day table, the day number, the streak arithmetic |
| `SSS.Server.Meta.DailyRewardService` | **THE one writer of `Data.LoginStreak`**; owns `GetDailyState` + `ClaimDaily` |
| `StarterGui.HUD.DailyRewardsController` | the button: live countdown, click to claim, reveal |
| `SSS.Server.Meta.DevDailyRewind` | Studio-gated harness — rewinds `LastClaimDayNumber` only |

`RS.Remotes` **23 → 25** (`GetDailyState`, `ClaimDaily`, both RemoteFunctions). **No schema bump was
needed and that was found by READING:** `ProfileTemplate` has carried
`LoginStreak = { Day, LastClaimDayNumber }` since **v2** with no writer. Designing first would have
produced a pointless v3 → v4 migration and a both-Places publish for a field already there.

### ⚠ It deliberately does NOT use `RewardPush`

B38 was pitched partly as the first real caller for B37's push path. It is not one. **The user chose
click-to-claim**, and B37's own rule decides it: *player's click → the return value; server decided →
`RewardPush`*. So `ClaimDaily` returns `Rewards = views` and the CLIENT fires `ShowRewards`, exactly
like summon and sell. Pushing here would reveal twice the day anything else starts pushing.
**The push path therefore still has no production caller** — the harness note above predicts the
daily flow would be it; that prediction was wrong. A *login* grant, an inbox gift or a redeemed code
will be its first.

### The rules live in the config, not the service

Pure and total, so the service, the HUD countdown and a future 7-day track screen can never disagree
about which day a player is on.

- **The day number is `MetaMath.Slot(Daily, ResetOffsetSec)`** — the same cross-phase invariant
  `BannerRegistry.CurrentDay()` uses. The client never computes it; one that disagreed would show
  "ready" against a server saying "already claimed".
- **Miss a day and the streak resets to 1** (the user's call at B38). `NextDay` returns `(day % 7)+1`
  only when `last == today - 1`; every other case returns 1 — which also covers a first claim and a
  corrupt stored streak, because a bad value must not hand out day 7 forever.
- **`Rewards` is PLACEHOLDER BALANCE**, marked as such in the file. The user accepted it to unblock
  the build and will retune it.

### Ordering: GRANT FIRST, MARK SECOND

`Grant` validates and can refuse; the mark cannot, so marking first would let a refused grant burn
the player's day. Same rule as `GrantService.SellUnits` (credit before destroy): **do the fallible
thing first.** An `inFlight` guard is belt-and-braces — `Grant` is documented non-yielding, so if a
yield is ever introduced there a double-click becomes a refusal instead of a double grant.

### The label says state; the toast says events

`Main.Texts.ResetTime` reads `Ready to claim!` or `Resets in HH:MM:SS`, ticking off one
server-supplied `SecondsUntilReset` plus the local clock and re-syncing at zero. "Already claimed
today" is a **condition** that holds until the reset, so it lives on the label; a refusal is an
**event**, so it toasts (`ui-feedback.md`).

### A bug the verification found: `Day` is not always `NextDay`

`stateFor` first returned `NextDay(...)` unconditionally, which reports **1** for a player who has
already claimed today — whatever day they actually took. `NextDay` is correct and answering a
different question: its `last == today - 1` test cannot hold when `last == today`, so a same-day call
falls through to "start the cycle over". Right answer to *what comes next*, wrong to *which day am I
on* — a track screen would have lit day 1 for someone who just claimed day 5. `Day` now means **the
day the track should highlight**. Invisible to reading; it showed up only as a live
`{Streak: 2, ClaimedToday: true, Day: 1}`.

### Harness, and why it must be a real server Script

`Server.Meta.DevDailyRewind` (Studio only) rewinds `LastClaimDayNumber` and **nothing else** — never
`Day`, never a grant, never a claim mark — so every rule under test still comes from the config and
the service.

```lua
ReplicatedStorage:SetAttribute("DevDailyRewind", 1)   -- claimed YESTERDAY   (server-side!)
ReplicatedStorage:SetAttribute("DevDailyRewind", 2)   -- MISSED a day
```

It cannot be done from `execute_luau`: that runs in a separate Lua VM with its **own require cache**,
so requiring `PlayerDataService` there yields a second, empty copy holding no profiles. Rewinding
that copy would be testing a re-implementation — the B36 mistake exactly.

### Verified live, through the real server

| case | result |
|---|---|
| first claim | day 1, Gold x100, Gold 265 → 365, reveal ran |
| double claim | `{ok=false, reason="already_claimed"}` |
| streak advance (claimed yesterday) | day 1 → **day 2**, Silver x150, `Streak` 2 |
| **missed a day** (streak was 2) | resets to **day 1**, Gold x100 |
| `Day` after the fix | `{Streak: 2, ClaimedToday: true, Day: 2}` |
| deployed label | `"Ready to claim!"` on a claimable join; `"Resets in 11:30:18"` → `11:30:15` 3s later |

The **day-7 → day-1 wrap** is verified at the CONFIG layer only (`NextDay(7, today-1, today) = 1`);
walking a live profile through seven days was not worth the round trips, and the service passes
`streak.Day` straight through.
