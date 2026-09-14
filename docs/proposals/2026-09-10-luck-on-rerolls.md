# Proposal: Luck affects trait + stat rerolls

- Date: 2026-09-10 (B57)
- Raised by: AD-Meta (Lobby)
- Owner to action: **AD-Traits** (owns `TraitRerollService` / `StatRerollService`), plus the
  shared-canon owners if the weight-bias option is chosen.
- Status: **CLOSED — IMPLEMENTED B57b, VERIFIED LIVE B58 (2026-09-14).** Best-of-N (Option B),
  Lobby-local, no shared-canon change (`RerollLuckConfig` + edits to
  `TraitRerollService`/`StatRerollService`). Option A (weight-bias, summon-consistent) remains
  available below if the user later wants it. The rest of this doc is the original decision record.
  - **Verified live B58**, closing B57b's one remaining gap (it had only been proven on pure modules,
    never driven in-game): `DevLuck=100`, the real `RerollTrait` / `RerollStats` remotes, a real owned
    unit and a real spent token -> `bestOf=3` in three `[DATA] TraitReroll` lines and three
    `[DATA] StatReroll` lines.
  - **Decision 2 (magnitude) ANSWERED B58: keep best-of-2/3 as built.** `RollCount`: 1 with no buff,
    2 at 25/50/75%, 3 at 100%.
  - **Decision 3 ANSWERED: BOTH rerolls** — trait keeps the rarest of N, stat the highest-total of N.
  - ⚠ **Known feel issue, deliberately accepted at B58.** Best-of-N picks the best of N **new**
    candidates and does NOT compare against the unit's current values, so a reroll at 100% Luck can
    still downgrade a good unit -- observed live: `DMG D->B RNG SS->C SPA A->D`. Consistent with a
    trait reroll landing back on `None`, but "Luck helps rerolls" reads to a player as "I cannot get
    worse". If that complaint ever arrives, the contained fix is to seed the candidate list with the
    CURRENT stat set so a stat reroll can only hold or improve -- a real change to AD-Traits' canon
    and a separate proposal, not a tweak.

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
