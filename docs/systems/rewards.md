# Rewards — match-end payouts (AD-Game canon)

<!-- owner: game | scope: game (+ one SHARED config the Lobby preview reads) | last-verified: 2026-08-13 (P5/B18) -->

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

## Insane mode — implemented, but UNREACHABLE in production

§8: Insane runs the **same** gold curve and adds item rewards on top. Mode is a separate axis from
the slider and never enters the difficulty conversion.

**The teleport `MatchLaunch` payload (v2) has NO mode field.** The Lobby publishes `DifficultyMode`
on `SelectedAct` for its own UI, but nothing puts it on the wire, so this Place always sees Normal
and the Insane branch never fires live. `RewardCalculator` reads `matchState.DifficultyMode` and
defaults to Normal, so the day a mode arrives it is already wired.

Making Insane reachable is a **teleport contract v2 → v3 change**: both Places, ONE session, a
synchronised republish, under the contract protocol in `CLAUDE.md`. It is not a field you can quietly
add — the Places publish separately, and a Game that ignores an unknown field while the Lobby
believes it is sending Insane pays the wrong rewards with nothing erroring.

Note this also makes Insane the **first real writer for `Data.Items` in normal play** once it ships
(see the standing PENDING) — today only the Victory drop-roll can write items.

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
