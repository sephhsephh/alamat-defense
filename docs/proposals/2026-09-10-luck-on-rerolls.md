# Proposal: Luck affects trait + stat rerolls

- Date: 2026-09-10 (B57)
- Raised by: AD-Meta (Lobby)
- Owner to action: **AD-Traits** (owns `TraitRerollService` / `StatRerollService`), plus the
  shared-canon owners if the weight-bias option is chosen.
- Status: OPEN — deliberately NOT built in B57. It is a balance change that touches shared canon;
  the constitution says propose + decide the mechanic first.

## What the user asked (B57)

"The luck buff will affect anything that has rng, like the summon, trait rerolls, stat rerolls."
Summon already honours Luck (`SummonEngine` reads `LuckService.ActiveMult`). Rerolls do NOT — today:

- `TraitRerollService` calls `TraitRegistry.Roll()` (no luck).
- `StatRerollService` rolls grades from `StatGradeConfig` (no luck).

## Why it wasn't just built

`TraitRegistry` (`56e81e37`/`eca681ad`) and `StatGradeConfig` (`49a6edfd`) are **SHARED canon in both
Places**. Making Luck bias their weights is a shared-canon change (mirror byte-identical to both Places
+ manifest + re-verify in each) AND it is a balance decision the user has not specified a magnitude for.
Rushing that late in a long session is exactly the failure the drift/single-writer rules guard against.

## Two mechanics to choose between

**Option A — weight bias (consistent with summon).** Luck multiplies the rarer outcomes' weights before
the roll, the same shape summon uses. Cleanest player-facing story ("Luck helps everywhere the same
way"). COST: changes `TraitRegistry.Roll` to accept a luck/mult arg and biases `StatGradeConfig` grade
weights -> SHARED-canon change in both Places + `TraitRerollService`/`StatRerollService` pass the mult.
Cross-place, needs the traits + schema owners.

**Option B — best-of-N (Lobby-local, contained).** The reroll SERVICE rolls K candidates and keeps the
rarest, K derived from Luck (e.g. K = 1 + floor(ActivePercent/50): 0-49% -> 1 roll, 50-99% -> 2, 100% -> 3).
No shared-canon change; needs only a rarity ranking exposed (trait rarity from `TraitDefinitions`,
grade order from `StatGradeConfig`). Approximate, reversible, entirely inside AD-Traits' Lobby services.

## Decisions needed from the user

1. Which mechanic (A weight-bias / B best-of-N).
2. The magnitude — how much a given Luck % should help a reroll (the K table above, or the weight curve).
3. Whether Luck should touch BOTH rerolls or just one.

Once decided, AD-Traits implements it (with the shared-canon owners for Option A). `LuckService.ActiveMult`
/ `LuckService.ActivePercent` are the read; they are already the summon path, so the number stays one formula.
