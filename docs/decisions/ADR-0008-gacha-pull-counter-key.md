# ADR-0008 — gacha pulls count on `GachaPulls`, not `Summons`

<!-- owner: gacha | scope: global | status: ACCEPTED (user, 2026-08-09, B3) -->

## Context

The Phase B blueprint's summon algorithm ends with "increment `Counters.Global.Summons`", and
Phase D's quest spec reads counters by name (`Counter = "Summons"`).

That key was already taken. **A8 (AD-Game, 2026-08-06)** wired `Counters.Global.Summons` to the
Game place's `SummonManager` — it counts **in-match minion summons** (Necromancer's summon-on-kill
chargers). A8 verified real values on it: `Summons 111` after one 15-wave match, `Summons 255`
cumulative after two. The live dev profile read `1152` at the start of this session.

The blueprint was written before A8 existed, so it could not have known the collision.

## Decision

**Gacha pulls increment `Counters.Global.GachaPulls`. `Counters.Global.Summons` keeps its A8
meaning (minion summons) and gacha never touches it.**

Deviation from the blueprint's literal wording, accepted by the user at B3.

## Why not the alternatives

- **Follow the blueprint literally.** Banner pulls and minion summons become indistinguishable in
  one number. A8's verified totals silently stop meaning what they were verified to mean, and any
  Phase D quest reading `Summons` counts both — a "summon 100 minions" task would be completable
  by pulling a banner. Corrupting a verified counter to match a doc written before that counter
  existed is the wrong trade.
- **Rename A8's counter to `MinionSummons` and give gacha the `Summons` key.** Most faithful to
  the blueprint long-term, but `Counters` is AD-Game canon under `docs/OWNERSHIP.md`; AD-Gacha
  does not get to rewrite the meaning of another chat's field. It would also need a migration
  for existing profiles. Available later as an AD-Game proposal if the naming ever grates.

## Consequences

- **No schema bump.** `Counters.Global` is an open `{ [string]: any }` map in schema v2, so a new
  key is purely additive — Reconcile is not even involved. Profiles written before B3 simply have
  no `GachaPulls` key; `SummonService` treats absent as 0.
- **Phase D quests must target `GachaPulls`** for anything meaning "banner pulls", and `Summons`
  for anything meaning "minions summoned in a match". Whoever writes `QuestConfig` reads this ADR.
- The blueprint text at `docs/blueprints/phases-b-f-meta.md` is **not** edited — blueprints are
  law and stay as written; this ADR is the recorded exception, which is the mechanism the
  constitution provides for exactly this case.

## Verified

B3, live Play in the Lobby: 11 real pulls moved `Counters.Global.GachaPulls` from absent to `11`
while `Counters.Global.Summons` held at `1152`, unchanged.
