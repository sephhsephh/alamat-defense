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

---

## B39 — the EVENT track

A second, time-boxed ladder beside the permanent one, on its own tab of `StarterGui.DailyRewards`.

| piece | what it is |
|---|---|
| `RS.Configs.Meta.EventDailyConfig` | PURE rules: the event table, its date window, its streak arithmetic |
| `DailyRewardService` (extended) | now **also THE one writer of `Data.EventLoginStreaks`** |

### ⚠ Every addition is ADDITIVE ON THE WIRE, and that was the constraint

The B38 `HUD.DailyRewardsController` is **deployed and working**. It reads `CanClaim` / `Day` /
`SecondsUntilReset` at the **top level** of `GetDailyState` and invokes `ClaimDaily` with **no
arguments**. So:

- every top-level field still means exactly what it meant, describing the **permanent** track;
- the event track hangs off a new `Event` sub-table the old controller never looks at;
- `ClaimDaily(nil)` still claims the permanent track; `ClaimDaily("Event")` claims the event one.

Reshaping the response into `{ Normal = ..., Event = ... }` would have been tidier and would have
broken a live screen for no player-visible gain. **Verified rather than assumed:** with the event
track live, the deployed HUD label was still counting down (`"Resets in 09:53:33"`) and the
top-level fields still read `CanClaim=false Day=3 Streak=3 CycleLength=7`.

### A date window, not a banner

The rejected alternative was to drive the event track off whichever gacha banner is live. Coupling
them means **an event daily track cannot exist without a banner**, and ending a banner would silently
delete a ladder players are part-way through. A window is what actually defines an event, so the
window lives in `EventDailyConfig`. (The user's call at B39.)

- **Only one event may be live at a time, and that is ENFORCED, not assumed.** `ActiveEvent` sorts
  ids and returns the first live one, **warning by name** if another overlaps — two ladders sharing
  one claim button have no defined answer to "which am I claiming".
- Ids are sorted so **every server picks the same event with no coordination**, the same reasoning
  that makes the matchmaking host "lowest userId".
- The cycle length is **however many rows `Rewards` has** — not fixed at 7. That is the point of a
  separate config: a two-week event can run a 14-rung ladder.

### The one rule that differs from the permanent track: it does NOT wrap

`DailyRewardConfig.NextDay` wraps `(day % 7) + 1`, because the permanent ladder repeats forever.
An event ladder **stops at its last rung**: `IsComplete` becomes true and `CanClaim` goes false, even
on a new day. Without that, a limited-time event would pay its final row out every day until it
expired. Missing a day still resets to 1, identical to the permanent track — kept the same
deliberately, because two ladders on one screen behaving differently is a rule players must learn
twice. Making an event forgiving instead is a **one-line change in the config**, not the service.

### `Data.EventLoginStreaks` is keyed by eventId

So a second event later starts its own ladder rather than inheriting a finished one's progress.

### Verified live

| case | result |
|---|---|
| boot | `active event = HarvestMoon (5 rungs, 89 day(s) left)` |
| event claim | day **1/5**, Silver x200, `Track="Event"` |
| event double-claim | `already_claimed` |
| permanent track after an event claim | **unchanged** (`Day=3 Streak=3`) — the ladders are independent |
| `NextDay` at the last rung | stays at 5, `Complete=true` — **no wrap** |
| missed days / corrupt streak | both reset to 1 |

`Rewards` and the `HarvestMoon` window are **PLACEHOLDER CONTENT**, labelled as such in the file.

---

## B40 — the screen exists

`StarterGui.DailyRewards` + `DailyRewards.DailyRewardsScreenController`. The user's call at B40
reversed "you author it, I wire it": both servers were finished and only art was blocking, so B40
**scripted a blockout tree to the published spec** and wired it. `docs/specs/` is still the contract —
the controller reads only spec'd names, so replacing the art costs zero code changes.

Two tabs (DAILY / EVENT), a card per rung with tier border, tick on claimed rungs, glow on the
claimable one, a dimmed-not-hidden claim button, and the live countdown.

**`HUD.Right.Buttons.DailyRewardsButton` no longer claims — it OPENS the screen.** At B38 there was no
screen so click-to-claim was the whole feature; two ways to claim one reward from one button would be
a coin-flip about which fires. The claim **moved** (identical `ClaimDaily` → `ShowRewards` sequence);
the HUD script keeps only the label, because a countdown you must open something to read is useless.
They talk through `ClientEvents.OpenDailyRewards`, resolved **lazily at click time** — the two
controllers boot in an unspecified order and the screen is the one that creates the event, so looking
it up at click removes the race instead of guessing the winner.

`OpenDailyRewards:Fire(tab?)` takes an optional `"Normal"`/`"Event"` to deep-link a tab (the HUD's
`EventButton` is the obvious future caller).

**Verified live:** DAILY renders 7 rungs `100/150/1/300/1/500/3` with rungs 1–3 ticked and the button
dimmed (already claimed today); EVENT renders `Harvest Moon`, 5 rungs, `Ends in 89d`; tabs switch and
the header shows/hides; 25/25 boot scripts.
