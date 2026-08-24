# Rewards — match-end payouts (AD-Game canon)

<!-- owner: game | scope: game (+ one SHARED config the Lobby preview reads) | last-verified: 2026-08-14 (B20) -->

Everything a player earns for finishing a match. **The server is the only thing that grants** —
the client is shown the outcome and never performs a roll. Rolling drops client-side would let
anyone reroll until a Legendary landed.

## The pieces

| Thing | Where | Owns |
| --- | --- | --- |
| `RewardCalculator` | `SSS.Server.Rewards` | computes AND commits everything below |
| `MatchEndPresenter` | `SSS.Server` | calls it once per player on `MatchEnded`, then fires `MatchResults` |
| `StageConfig.Rewards` | `RS.Configs.Stages.Stage1.*` | per-act XP, defeat consolation, drop table, and the **name** of a gold curve |
| `RewardScalingConfig` | `RS.Configs.Global` — **SHARED CANON** | the difficulty→gold curve, the wire→t conversion, the Insane item table |
| `TowerProgressionConfig` | `RS.Configs.Global` | per-unit XP from damage/kills |
| `WorthinessConfig` | `RS.Configs.Global` | worthiness per kill (A8) |

## Gold scales with difficulty (P5, blueprint `playgui.md` §8)

`goldMin = lerp(100, 300, t)`, `goldMax = lerp(300, 500, t)`, and the server rolls an integer
inside that band. Victory only.

**A DEFEAT keeps its flat `StageConfig.Rewards.Defeat.Currency`.** §8's curve describes what a
CLEAR pays; scaling the loss reward would make losing on max difficulty the best gold-per-minute in
the game.

`Victory.Currency` still exists in every act but is **FALLBACK ONLY** — used only if the named
curve cannot be resolved. Do not tune it expecting it to be what players receive.

## ⚠ THE TWO DIFFICULTY SCALES

This is the single most dangerous thing in this file.

| Scale | Range | Where | Meaning |
| --- | --- | --- | --- |
| **UI** | 1–100 | PlayGUI slider, Lobby only | 1 = normal, 100 = hardest |
| **WIRE** | 100–1000 | `DifficultyPercent` in the teleport `MatchLaunch` payload (v2) | 100 = normal (1× enemy HP), 1000 = 10× |

ADR-0011: the 1–100 remap is **DISPLAY-ONLY** and the wire format never changed. The Lobby converts
UI→wire in exactly one module (`StarterGui.PlayGUI.DifficultyScale`).

**The Game only ever receives the WIRE value**, so it does its own conversion in exactly one
function: `RewardScalingConfig.TFromWire`, `t = (wire - 100) / 900`, **clamped, never
extrapolating** (the legal wire range is 1–1000, wider than the 100–1000 the slider can produce, so
values below 100 must land on t = 0 rather than going negative).

Getting this backwards is silent and expensive: treating an incoming wire `100` as if it were UI
`100` reads **normal as hardest** and pays maximum gold for an easy match. There is no error, no
`[CONTRACT]` line — just wrong numbers forever. Do not add a second conversion anywhere.

`RewardCalculator` reads the difficulty from `matchState.DifficultyPercent` (sanitised by
`MatchDirector`). The `matchState` argument is **optional and fails SAFE**: absent, the match is
treated as normal (t = 0, bottom of the band). The opposite default would pay maximum gold to every
caller that forgot to pass it.

## Why the curve is SHARED and not in `StageConfig`

§8: *"the preview must not invent numbers … the curve belongs in a config both sides can read."*
The Lobby's reward preview must show what the server will actually pay.

**The curve reached the Lobby at B20** (`deployed.Lobby = 1d789978`, copied byte-identical, drift
**26/26 GREEN** in that Place). Both Places were proven to compute the SAME band from the SAME
function at wire 100 → `100-300`, 550 → `200-400`, 1000 → `300-500`, and 500 server rolls all landed
inside the previewed band.

**The preview UI itself is still NOT wired**, and that is a reported gate rather than an oversight:
`StoryModeController.renderRewards()` renders `x<qty>` per cell so it cannot express a min–max BAND,
and it only re-runs on act selection while P4 republishes `DifficultyWire` on every slider move — so
a one-call wiring would freeze at the act's opening difficulty and then contradict the slider, which
is exactly the lie §8 bans. That file is AD-UI canon, so B20 filed
`docs/proposals/2026-08-14-reward-preview-wiring.md` instead of editing it.

It could **not** live in `StageConfig.Rewards`, for three reasons:

1. The Lobby's `StageRegistry` is a hand-maintained **MIRROR carrying structure only** — no reward
   table, and nothing drift-checks it (`docs/systems/play-menu.md`). Gold numbers there would be
   two uncheckable copies of the same figures in two Places.
2. The curve is **identical for every act**. Triplicating it buys no tuning and creates three
   places to desync.
3. `WorthinessConfig` is the obvious counter-example and it does **not** apply: the Lobby reads
   worthiness as a **stored result** off the profile. A pre-match preview has nothing stored to
   read. This is a genuine cross-Place read, which is what shared canon is for.

Per-act tuning survives without duplicating numbers: `StageConfig.Rewards.GoldCurve` **names** a
curve, so a future act points at a different one instead of copying endpoints.

## Insane mode — REACHABLE since teleport v3 (B20, 2026-08-14)

§8: Insane runs the **same** gold curve and adds item rewards on top. Mode is a separate axis from
the slider and never enters the difficulty conversion.

**The `MatchLaunch` payload carries `DifficultyMode` as of contract v3** (`docs/contracts/teleport.md`).
The chain is: `DifficultyController` (P4) publishes `DifficultyMode` on `SelectedAct` →
`LobbyController` (P6) passes it through `RequestLaunch` verbatim → `PartyService` validates it and
puts it on the wire → `MatchEntryService` normalises it onto `rawConfig` → `MatchDirector` puts it on
`matchState` → `RewardCalculator` reads `matchState.DifficultyMode`. It was bumped as a HARD version
change, not an additive field: a Game that ignored an unknown mode while the Lobby believed it sent
Insane would pay the wrong rewards silently, so v2 and v3 do not interoperate.

**It still fails SAFE at every hop.** `matchState` is optional and an absent or unrecognised mode
resolves to Normal — the branch that pays NO bonus items. The opposite default would pay bonus items
to every caller that forgot the argument.

**Insane is now the first real writer for `Data.Items` in normal play** (see the standing PENDING) —
before this, only the Victory drop-roll could write items, and nothing triggered it. Verified live at
B20: an Insane Victory committed `BannerTicket` 0→1 and `TraitRerollToken` 0→1; the same Victory on
Normal committed neither, and both landed inside the same gold band.

**⚠ ONE STALE COMMENT, deliberately NOT edited.** `RewardScalingConfig`'s own header still says the
payload "(v2) carries NO mode field" and that Insane cannot fire live. That module is SHARED CANON at
hash `1d789978` and B20's whole job was to copy it byte-identical, so correcting the comment would
have changed the hash and required a re-deploy to both Places inside a session that was already
doing a contract bump. It is **AD-Game's** module; the fix is a comment-only re-hash + both-Place
redeploy in a future AD-Game session. The CODE is correct — only the comment is out of date.

## Order of operations in `GrantForPlayer`

1. XP + gold (gold scaled; defeat flat) → `PerfectClearBonus` if the clear was flawless
2. Drop-table roll (Victory only) → plus Insane items if the mode says so
3. Commit account rewards: `AddPlayerXP`, `AddCurrency`, `AddItem` per drop
4. Per-unit tower XP **by uuid**, from that unit's own damage/kills (B0)
5. `CommitUnitKills` per unit — `Counters.PerUnit[uuid].Kills` + worthiness, one write (A8)
6. Global counters: `Clears` + `ClearsByStage` **on Victory only**, `Waves` on any outcome

Steps 4–6 are covered by `docs/blueprints/phase-a-foundations.md` §6 and the A8/A9/B0 changelog
entries; do not change their attribution rules without reading those.

## Invariant 1 does NOT hold here yet

Every grant in the **Lobby** flows through `GrantService`. The **Game** still grants through
`PlayerInventoryService` / `RewardCalculator`. Converging them is a separate cross-Place task
(standing PENDING) — do not start it inside a rewards change, but do not make it worse either.

## Verifying a change

`execute_luau` caches requires and will happily report a stale pre-edit module. Verify from a REAL
Script + `get_console_output`. `RewardCalculator` prints one `[DATA] Rewards:` line per grant with
outcome, mode, wire, t, band and the rolled gold — that line is usually all the evidence you need.
Assert on the **gold delta**, not the absolute, so a dirty dev profile cannot make a red test green.

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
