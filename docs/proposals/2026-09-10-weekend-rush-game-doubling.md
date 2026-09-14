# Proposal: Weekend Rush — the actual x2 (GAME side)

- Date: 2026-09-10 (B57)
- Raised by: AD-Meta (Lobby)
- Owner to action: **AD-Game** (rewards + XP are computed in the Game place), with the shared-canon
  owners for the config promotion.
- Status: **CLOSED — LANDED AND VERIFIED B58 (2026-09-14).** Every open thread in this proposal is
  resolved; nothing here is outstanding. Original plan below, kept as the decision record.
  - **The doubling** (B57c): `RewardCalculator.GrantForPlayer` applies a Victory-only scalar to gold +
    account XP + tower XP + battlepass XP. **Verified live B58** on a real 15/15 Victory:
    `gold 628` against a 100-300 band, `BP XP +250`, `WeekendRush x2`.
  - **Drops + challenge fragments: DOUBLED (user's call, B58).** The open scope question is closed YES.
    Applied at the one point where the stage drop roll, the Insane items and the day's challenge
    fragments are all already in `drops`, scaling each `Count`; ids and `ItemCatalog` Kind routing
    untouched. **Verified live B58** on an Insane Victory: `[DATA] Drop: StatRerolls x2 ->
    Currencies.StatRerolls = 2` (Insane grants x1), still routed to `Currencies`, not `Items`.
  - **Shared-canon promotion: DONE B58.** `shared/src/WeekendRushConfig.luau`, manifest 41 -> **42**,
    byte-identical `44c549f0` in both Places and on disk, drift **42/42** in each, checked
    field-by-field against both `hash` and `deployed.<Place>`.
  - **Timezone: DECIDED B58 — `TimezoneOffsetHours = 8` (UTC+8, Asia/Manila)**, not UTC. Edges
    verified: opens Fri 00:00 Manila, shut one second before, open through Sun 23:59, shut Mon 00:00.
  - **Battlepass XP question (item 3 below): answered YES** — BP XP doubles, built that way at B57c.
  - Follow-up noted, NOT part of this proposal: only CURRENCY drops print a `[DATA] Drop:` line; the
    Item branch grants silently, so doubled `BannerTicket`/`TraitRerollToken` are invisible in the log.

## What already exists (Lobby, B57)

`RS.Configs.Meta.WeekendRushConfig` (Lobby-local, PURE) defines the window and the copy:

- Active **Friday 00:00 -> Monday 00:00**, measured in `TimezoneOffsetHours` (default **UTC / 0**).
- `RewardMultiplier = 2`.
- `IsActive(now?)` and `SecondsLeft(now?)` are pure, time-derived (no profile field, no writer, no
  schedule) — the same "expiry is a comparison, never a write" shape as the Luck buff.
- Title "Weekend Rush", Subtitle "x2 Rewards and Exp", Description "Earn double rewards when clearing
  challenges and story modes."

The Lobby shows this as a card in the Buffs screen + a HUD-strip chip while active (`BuffService`).
**That is display only.** Nothing doubles yet.

## The task (Game)

When `WeekendRushConfig.IsActive()` is true **server-side in the Game place**, multiply by
`RewardMultiplier` (2):

1. Match-end **rewards** (currency + item drops) for **challenge** and **story** clears —
   `RewardCalculator` is the place, alongside the existing challenge/difficulty scaling.
2. Account **XP** (the "Exp" in "x2 Rewards and Exp") — the `AddPlayerXP` path.
3. **Open question for the user:** does "Exp" also mean **Battlepass XP**? Default assumption: yes,
   double BP XP too (it is "exp" the player earns by clearing). Confirm before shipping.

Rules:
- **Server-authoritative.** The Game computes `IsActive()` itself; never trust a client flag.
- Apply as the LAST scalar over the computed reward, the same way `Scarcity`/`LeanStart` economy
  modifiers and difficulty scaling already compose — do not bake it into base tables.
- Abandoned/aborted matches pay nothing regardless (the B41 rule) — x2 of nothing is nothing.

## Shared-canon promotion (required)

`WeekendRushConfig` is Lobby-local right now. The Game needs the SAME window, so promote it to shared
canon in ONE session:

- move to `shared/src/WeekendRushConfig.luau`, deploy byte-identical to BOTH Places,
- add it to `shared/manifest.json` (41 -> 42 entries), re-verify the drift hash 42/42 in each Place,
- the Lobby then requires the shared copy (drop the Lobby-local one).

## Timezone decision (user)

The window is currently **UTC**. For a global playerbase "the weekend" is ambiguous; `TimezoneOffsetHours`
exists so the user can pin it (e.g. +8 for Asia/Manila). Confirm the intended anchor before promotion —
both Places must read the identical value once shared.
