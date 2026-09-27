# Stage Info (GAME)

<!-- owner: AD-UI + AD-Game | scope: game | rebuilt: B88 -->

Opens with **C** (or the HUD's STAGE INFO button) during a match. Rebuilt at **B88** from the user's
reference: seven sections instead of the single rich-text blob it used to be.

The old `Content.Body` label is hidden and tagged `RetiredB88`, not deleted. Sections are built from
authored templates under `StageInfoPanel` — `SectionTemplate`, `StatTemplate`, `EnemyTemplate` (all
tagged `B88Built`) — so a section can carry tiles and portraits rather than only lines of text.

## What comes from where

**The client composes most of it from configs it already holds.** The act's name, mode, lives, wave
count, enemy roster, boss waves and drop table are all in `StageRegistry` / `WaveListRegistry` /
`EnemyConfigRegistry` on the client. Asking the server for them would be a round trip for data
already in memory.

**Only history comes from the server**, through `Match.GetStageInfo` → `Server.Meta.StageInfoService`:
how this session has gone, and which enemies this account has ever met.

The panel **draws immediately from configs and redraws when the server's answer lands**. Waiting for
the round trip would blank the panel for a beat every single time it opens, and most of it does not
depend on that answer at all.

## The sections

| Section | Source |
| --- | --- |
| Session Statistics | server — matches played / won / lost, session time |
| Total Rewards Gained | server — gold, player XP and items accumulated this session |
| Stage *n* – Act *n* | configs — stage/act names, mode, lives, waves, plus your run count |
| Stage Bosses | configs — a tile per boss, and the waves it appears on |
| Rewards | configs — victory/defeat XP and the act's drop table with its real percentages |
| Enemy Index | configs + server — every enemy in the act, locked until you have met it |
| Chosen Modifiers | server — the live match's modifier list |

## Session vs profile — two lifetimes, stored differently

- **Session stats** live in **memory** and die with the server. "Session" here honestly means *this
  server visit*. There is no cross-server play-session identity in this game, and inventing one out
  of a timestamp would be a guess dressed up as a fact.
- **Enemies seen** and **run counts** live on the **profile**, because "have I ever met this thing"
  is an account fact, and an index that forgot itself on rejoin would be pointless.

### ⚠ No save-schema bump was needed

`Counters.Global` is already typed `{ [string]: any }` in `ProfileTemplate`, and
`PlayerInventoryService.IncrementGlobalCounter` is already its writer. So this needed no new field,
no migration and no version bump — keys are namespaced `Seen_<enemyId>` and `Runs_<actId>`.

This is STATE's standing note in action: *check whether the profile field already exists before
designing one.* Three bumps were spent before that habit stuck.

## Enemies seen

Written **once per enemy id per match**, not once per spawn — a wave of forty Grunts is one fact, and
forty profile writes to record it would be forty writes to learn nothing new. The per-match set
resets when `MatchDirector` goes `InProgress`.

An unmet enemy shows **`???` and no portrait**. Rendering its model greyed out would still give away
the silhouette, which is the one thing an index exists to withhold.

## ⚠ Enemy portraits are blank, and why

Only `TowerModels` lives in `ReplicatedStorage`. The **enemy rigs are server-side**, so
`ModelStoragePath` resolves to nothing on the client and there is no portrait to draw. The tile
detects that and hides its `ViewportFrame`, centring the name instead — an empty black box reads as
a broken tile, which is worse than no box at all.

Moving the enemy rigs into `ReplicatedStorage` would light these up. That is a content and
replication-cost decision for the owner, not something to do quietly from a UI batch.

## ⚠ There is no stage pity, because there is nothing to be pitied

The reference shows `Stage Pity — Demon Leader 10 / 38`, a **unit** drop from a stage. This game's
acts drop **items only** (`Rewards.DropTable`: Banner Ticket 25%, Trait Reroll Token 8%, Golden Seed
2%) — there is no unit-drop-from-stage system at all, and no pity mechanic anywhere near it.

So what shipped is the honest half: **"Your runs on this act"**, a real counter persisted on the
profile. A `10 / 38` bar that guaranteed nothing would be a lie about the odds, and a pity
*guarantee* is a design decision rather than a UI one. The counter is already in place if that
decision gets made.

## Proven live (B88)

All seven sections built and read back from the live client:

- `Session Statistics`: Matches Played / Won / Lost / Session Time `0:01:00`.
- `Stage 1 - Act 1`: The Farm → Protecting the Fields, Normal Mode, Lives 3, Waves 15.
- `Stage Bosses`: one tile plus `Scarecrow King = wave 5, 15`.
- `Rewards`: `Victory 120 XP | Defeat 30 XP | Banner Ticket 25% | Trait Reroll Token 8% | Golden Seed 2%`.
- `Enemy Index`: read `Met on this act = 1 / 2` mid-match with the boss still showing `???`, then
  **`2 / 2` in a later match** once the boss had been met — the profile counter surviving the match.
- `Chosen Modifiers (0)`: "None for this run."
