# Quests — daily quests (Lobby meta, AD-Gacha canon)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B40) -->

| piece | what it is |
|---|---|
| `RS.Configs.Meta.QuestRegistry` | PURE: the quest table, the deterministic daily roll |
| `SSS.Server.Meta.QuestService` | **THE one writer of `Data.Quests`**; owns `GetQuests` + `ClaimQuest` |

`RS.Remotes` **29 → 31**. **No schema bump:** `Quests { Progress, Claimed, PinnedQuestId }` has been
in the template since v2 with no writer.

## ⚠ Progress is a DELTA against a baseline, not a counter read

`Data.Counters.Global.*` are **lifetime** totals maintained by `SummonService` and
`AscensionService`. A daily quest that read one directly would be **instantly complete for any
established player, forever** — a player with 900 pulls finishes "summon 10 times" before they see it.

So when a quest is assigned, the service records the counter's value as a **`Baseline`**, and progress
is `current - baseline`.

That is what lets quests work **today** against counters nobody wrote for quests: **no service that
owns a counter was touched, and nothing was added to any hot path.**

- **Baselines are written once per quest per day and never rewritten.** Re-baselining on read would
  reset progress every time the player opened the screen — the easiest way to get this wrong, and
  invisible until someone reports "my quest keeps going back to zero".
- Progress is clamped at 0. A counter only goes up, but a profile edit must not render a negative bar.
- `Progress` and `Claimed` are **pruned** to today, so neither grows without bound on a profile.

## ⚠ Only two counters exist, and a quest on a third is REFUSED

| counter | written by |
|---|---|
| `GachaPulls` | `SummonService` |
| `Ascensions` | `AscensionService` |

A quest naming a counter with no writer would sit at 0 forever and read as a bug in the quest system,
so:

- `QuestRegistry.LiveCounters` lists what is actually written;
- `Assignable()` filters to those, and **orphans are never assigned**;
- `QuestService` **names them at boot** in a warning.

The two obvious match quests were left **commented out in the registry** rather than shipped broken.
**SHIPPED at B42** now that the Game writes their counters (see the B41 section below): a one-line
`LiveCounters` change plus the two entries, no service edit.

## ⚠ B41 (AD-Game): the match counters exist now — and one of them always did

The claim above that "none of it exists" was **wrong when written**. `RewardCalculator` has been
writing global counters at match end since A8:

| counter | written by | moves when |
|---|---|---|
| `Clears` | `RewardCalculator` (Game) | **a Victory** — and a `StageConfig` **IS an act** (`Stage1_Act1..3`, chained by `NextActId`), so this already *is* "acts cleared" |
| `ClearsByStage[stageId]` | `RewardCalculator` (Game) | a Victory, per act |
| `Waves` | `RewardCalculator` (Game) | any outcome, by waves survived |
| `Summons` | `SummonManager` (Game) | live, per spawn — the one counter that does not wait for match end |
| `InsaneVictories` | `RewardCalculator` (Game) | **added B41** — a Victory that was *also* Insane |

**So `ClearThree` needs no Game work.** Point it at **`Clears`**, not a new `ActsCleared` key: the
Game deliberately did **not** add a second key for an event `Clears` already counts, because two
stored numbers for one event is exactly the drift the one-writer rule exists to prevent (user's
call, B41). `WinInsane` was the only one genuinely blocked, and `InsaneVictories` now exists.

**SHIPPED at B42 (AD-Gacha, Lobby).** `Clears` + `InsaneVictories` were added to
`QuestRegistry.LiveCounters`; `ClearThree` (Target 3) reads **`Clears`** and `WinInsane` (Target 1)
reads `InsaneVictories`. **6 assignable of 6, 0 orphans**; claim verified live (PullOne → Silver x120).
AD-Game supplied the counters and only the Lobby side of the quest system was edited, as intended.

**⚠ Names are a cross-Place contract.** A counter read by a baseline delta must be lifetime and
monotonic — never reset, never per-day. Renaming one silently strands every baseline already written
against the old key, which is why `Clears` was not renamed to match the quest's wording.

## The daily set is DERIVED

`RollDaily(userId, day)` uses `MetaMath.RngForSlot(day, "Quests:"..userId)` — same mechanism as the
shop, same reason: every server agrees with no stored roll.

## ⚠ A claim must be one of TODAY'S quests, not merely a real quest id

Otherwise a client could claim any quest in the registry by name. `claim` re-rolls the day's set
server-side and checks membership.

## GRANT FIRST, MARK SECOND

`Grant` validates and can refuse; the mark cannot. Marking first would burn the claim and pay nothing.
Same rule as daily rewards, codes and the shop. Reveal is the **return value** (B37).

## Reason codes

`bad_quest_id` · `not_assigned_today` · `already_claimed` · `not_complete` · `grant_failed` ·
`profile_not_loaded` · `busy`

## Verified live

| case | result |
|---|---|
| assignment on an established profile | all three read **0/N** — the baseline works |
| claim while incomplete | `not_complete` (`Progress: 0`) |
| one **real** summon through `RequestSummon` | all three advanced by exactly 1; `PullOne` → 1/1, `CanClaim` |
| claim `PullOne` | `ok=true`, Silver x120 granted |
| claim again | `already_claimed` |
| claim a quest not rolled today | `not_assigned_today` |
| claim `123` | `bad_quest_id` |

Quest content and rewards are **PLACEHOLDER**, labelled in the file.

## The screen (B42)

Built as **BLOCKOUT** art scripted to `docs/specs/2026-08-28-quests-screen.md` — the same call as
DailyRewards at B40 (server + spec finished, only art blocking). `StarterGui.QuestsGUI` +
`QuestsController`; `HUD.Left.Buttons.QuestsButton` fires `ClientEvents.OpenQuests` (self-wired, the
SummonController shape). Renders a card per daily quest — name, progress bar, first reward icon+qty
(with `+N`), Claim → `ClaimQuest` → `ShowRewards` reveal (return value, B37). The spec is the
CONTRACT: the user re-authors the tree keeping the names and the controller needs zero edits.
