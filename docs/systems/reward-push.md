# Reward push + the pending-reveal queue (Lobby, AD-Gacha canon)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B39) -->

How the **server** shows a player a grant they did not ask for, and what happens when it cannot reach
them. Split out of `rewards.md` (match-end payouts, AD-Game) at B39 on that file's 300-line cap.

**The rule everything here serves, and it greps:** if the player's own click caused the grant, the
**return value** reveals it. If the server decided, call **`RewardPush`**.

## B37 — the push path: how the SERVER reveals something the player did not ask for

Every reveal before B37 worked one way: the **client** invoked a remote, the remote **returned**
reward views, and the client fired `ClientEvents.ShowRewards` with them. That is right for
player-initiated grants — summon, sell, ascend — and it is deliberately untouched.

It cannot serve anything the **server** starts. Daily rewards, redeemed codes, quest completions and
inbox gifts have no invocation to return from. That single gap is why four HUD buttons could not be
built, and it is the whole of what B37 closes.

**Three pieces, all Lobby-local. Shared canon did not change.**

| piece | what it is |
|---|---|
| `RS.Remotes.PushRewards` | RemoteEvent, server → client (Remotes 22 → **23**) |
| `Server.Meta.RewardPush` | `RewardPush.To(player \| userId, views, reason?) -> ok, why?` |
| `StarterPlayerScripts.RewardPushReceiver` | listens, fires `ClientEvents.ShowRewards`, nothing else |

### ⚠ It is OPT-IN. `GrantService` never calls it.

The tempting design is to have `GrantService` reveal every grant automatically. It was considered and
rejected (the user's call at B37): summon and sell would then reveal **twice** — once from the return
value, once from the push — so every existing caller would need a suppression flag, and *a
suppression flag someone forgets is a double popup in a player's face*.

Opt-in makes the double reveal **impossible by construction rather than by discipline**, and that is
verifiable rather than asserted — at B37 the only live caller of `RewardPush.To` in the entire server
tree was the test harness, with `SummonService` still revealing through `Rewards = views` exactly as
before.

**The rule, and it greps:** if the player's own click caused the grant, the **return value** reveals
it. If the server decided, call **`RewardPush`**.

### Why `ObtainRewardsGUI` did not change at all

A server-initiated reward is not a new *kind* of reveal — it is the same reveal with a different
origin. So the correct amount of new code inside the reveal surface is **zero**. `RewardPushReceiver`
is the adapter that keeps it that way: remote in, BindableEvent out. The reveal surface stays a pure
consumer of one BindableEvent with no idea a network exists, which is its contract from B4 ("fire it,
never rebuild it").

The surface already **queues** batches, so a push landing mid-reveal is safe with no handling.

### Rules `RewardPush` enforces

- **Grant first, push second.** Callers grant through `GrantService` (invariant 1) and hand the
  **same `views` array `Grant` returned**, unchanged. One view shape, one producer — `RewardPush`
  builds no reward rows and must not start.
- **Never reveal a grant that failed.** The harness demonstrates the ordering: when `Grant` refused,
  nothing was pushed. A reveal for a grant that did not happen is a lie to the player.
- **Oversized lists are SPLIT, never truncated** (`MaxPerMessage = 25`). Silently dropping rewards a
  player has already been granted would leave them permanently unaware of something they own.
- **Malformed rows are dropped loudly**, naming the caller's `reason`. A row needs a string `Id` and
  `Kind` or the popup opens on a blank cell — a bug that reads as the game's fault, not the caller's.
- **Player not in the server → `false, "player_not_in_server"`.** The grant is already safe on the
  profile; only the *reveal* is lost, and they will see the balance next time they look.

### Known gap: rewards granted while a player is away are never revealed

Persisting unseen reveals for a later session is a real feature and is **not built**. It needs a
queue on the profile (a schema change) plus a decision about what happens when it overflows. Do not
improvise one inside `RewardPush` — it is presentation transport and owns no storage.

### Harness

`Server.Meta.DevRewardPush` (Studio-gated). There is no real caller yet, and testing the path by
calling `RewardPush` from tooling would exercise a **fresh copy of the module in a different, more
privileged VM** rather than the deployed one — the exact mistake that cost B34 a non-working watchdog
and two sessions of false confidence.

```lua
ReplicatedStorage:SetAttribute("DevPushRewards", "Gold:250,Silver:100")   -- from the SERVER
```

It grants through `GrantService`, then pushes the returned views — the real flow a daily reward will
use. Note it must be set **server-side**: an attribute a client writes on `ReplicatedStorage` does not
replicate to the server, which is worth knowing before debugging a harness that appears inert.

It also earned its keep immediately by catching a wrong assumption: `Grant`'s public contract is
`{ Id = "Gold", Qty = 250 }` — **capitalised**, with `kind` derived from `ItemCatalog` and never
passed. The lowercase `id`/`kind`/`qty` visible inside `Grant` are its post-validation internals.

## Daily rewards live in their own doc

`docs/systems/daily-rewards.md` (B38). This file was on its 300-line cap and daily rewards are a
**Lobby** meta system, not a match-end payout — same split `gacha.md` took at B30. It is the first
system built on the reveal machinery above, and it is the worked example of **why it does NOT use
`RewardPush`**.

## B39 — the pending-reveal queue, and what B37's "known gap" actually was

| piece | what it is |
|---|---|
| `SSS.Server.Meta.PendingReveals` | **THE one writer of `Data.PendingReveals`**; Enqueue / Peek / Take |
| `RewardPush.ToOrQueue` | push, and if that fails for a DELIVERY reason, keep it for next join |
| `RewardPush.Drain` | deliver everything owed, then clear — **push first, clear second** |
| `SSS.Server.Meta.RevealDrainService` | the handshake listener |
| `Remotes.ReadyForReveals` | RemoteEvent, client → server (Remotes 25 → **26**) |

### ⚠ B37's gap was mis-stated, and the correction changes what can be claimed

B37 recorded it as *"a grant made while the player is AWAY is never revealed"*. Reading the data
layer at B39 shows that cannot happen:

> `PlayerDataService.profiles` only ever holds players in **this** server. `GetData(userId)` returns
> nil for anyone else. So a grant to a genuinely offline player **cannot happen in the first place** —
> `GrantService.Grant` has no data to write to. There is no unrevealed offline grant to recover,
> because there is no offline grant.

So B39 does **not** close that gap as worded. What it actually fixes is real but narrower:

- the player **leaves between the grant and the push** (their profile is still loaded, so the write
  lands and they see the reveal next join instead of never);
- `Remotes.PushRewards` is missing, or the push fails for another transport reason;
- a push is attempted **before the client's receiver is listening**.

Delivering to a player in **no** server needs ProfileStore's **`MessageAsync`** global-update channel
(present in the vendored copy, ~line 1249): a message is written to the profile key and handled when
they next load, at which point *the grant itself* runs. That is mail/compensation, it owns a grant
path, and it must not be improvised inside a reveal queue. `PendingReveals` is the reveal half and
would be reused by it unchanged.

### ⚠ It is PRESENTATION ONLY. Draining must never grant.

Every queued row describes a grant that **already happened** and is **already in the player's
balances**. If draining ever calls `GrantService`, a player who rejoins is paid twice — the single
most dangerous mistake available in this code.

**Proven by enumeration, not asserted:** `PendingReveals`, `RewardPush`, `RevealDrainService` and
`RewardPushReceiver` contain **zero** non-comment references to `GrantService`. The only server
modules that require it are `AscensionService`, `DailyRewardService`, `SellService`, `SummonService`
and the two Studio harnesses. That is one grep, and it is worth more than this paragraph.

### ⚠ Why the drain is a client-announced handshake, not a `ProfileLoaded` hook

The obvious implementation — drain when the profile loads — is wrong, and silently.
`RewardPushReceiver` connects `PushRewards.OnClientEvent` during the client's boot, and
**`FireClient` does not queue for a client that is not yet listening**. The server would report a
successful push, clear the queue, and the player would see nothing: the exact failure the feature
exists to prevent, reintroduced at the last step.

So the client says when it is ready and only then does the server deliver. In `RewardPushReceiver`
the `FireServer()` sits **after** the `OnClientEvent` connect, and that order is the whole point —
moving it above would look like it worked.

### `To` still owns no storage

B37 promised that and it is load-bearing, so `RewardPush.To` is unchanged. The persistence lives in
`PendingReveals`; only the two composed functions touch it, opt-in per call site like the push
itself. `ToOrQueue` queues **only** on `player_not_in_server` / `no_remote` — `empty` and
`no_valid_rows` mean a caller bug, and persisting one into a player's profile helps nobody.

### Overflow REFUSES rather than evicting

`MaxQueued = 100`. Evicting would churn the queue and make which rewards a player is shown depend on
arrival order in a way nobody can reason about. Refusing is stable, and `Dropped` records how many
were refused so the drain can say "+N more" instead of lying by omission — the same reasoning that
makes an oversized push **split** rather than truncate.

### Push first, clear second

`PendingReveals.Take` clears on the way out, so taking before delivering would lose the queue if the
push then failed. `RewardPush.Drain` restores the rows on a failed push and retries next join, so no
call site has to get that ordering right by hand.

### Verified live, across a real session boundary

| case | result |
|---|---|
| grant + queue without pushing | `PendingReveals +2 ... queued=2`, balances moved, **no reveal shown** |
| overflow | offered 115, stored 98, refused 17, `Dropped now 17` — cap refuses, does not evict |
| rejoin | `RewardPush -> ... 2 reward(s) (reason=pending_reveals)` → `ObtainRewards SHOW n=2` → `REVEALED` |
| after the drain | `0 queued, 0 dropped` |
| balances during the drain | unchanged — the grant had happened in the previous session |

Harness: `Server.Meta.DevPendingReveals` (Studio only) —
`ReplicatedStorage:SetAttribute("DevPendingReveals", "queue:Gold:250" | "peek" | "flood" | "clear")`,
**server-side**. It has to be a real Script for the same reason `DevDailyRewind` does: `execute_luau`
runs in a separate VM whose `PlayerDataService` copy holds no profiles.
