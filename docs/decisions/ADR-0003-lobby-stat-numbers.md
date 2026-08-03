# ADR-0003: the Lobby gets resolved stat numbers from a generated UnitStatsCatalog

**Date:** 2026-08-03 · **Status:** Accepted (user decision) · **Implementer:** AD-Game, due at A6

## Context

The Lobby shows units but cannot resolve their DMG/RNG/SPA. `TowerStatResolver.Resolve` takes a
whole `towerConfig` (`Upgrades[tier]`, `BaseStats`, `Attack`) and internally requires
`MetaScalingConfig` + `TraitRegistry` + `TraitDefinitions`. Making the Lobby resolve numbers the
way the Game does therefore means putting **~12 modules, including all 8 tower configs**, under
drift control — AD-Game's most frequently tuned files.

This was raised at A4 (2026-08-01), deferred by the user, and shipped around twice: A4 and A5 both
display **grades** only (grades come from the roll alone and need no tower config). The A5 Units
stats panel renders `--` in its number slot as a visible placeholder.

## Decision

**AD-Game exports a slim, generated `UnitStatsCatalog` into `shared/src`, plus a boot validator
that asserts the generated values still match the live tower configs.**

Rejected alternatives:

- *Promote the full stat stack.* Exact by construction and no divergence risk, but it makes every
  balance tweak a two-Place deploy and puts the Game's hottest files under the drift check. The
  coupling cost is permanent; the accuracy benefit is obtainable more cheaply.
- *Keep deferring.* Cheapest, but the stats panel stays visibly incomplete and the decision just
  moves to A7 with more UI built on top of the gap.

## Consequences

- The Lobby gains **one** drift-tracked module instead of twelve. Balance tuning stays a
  Game-place-only edit until someone regenerates.
- **The validator is the load-bearing part.** A generated catalog is a cache, and a stale cache
  that lies about damage numbers is worse than showing `--`. It must fail loudly at boot in the
  Game place (where the real configs live), not warn quietly.
- Regeneration becomes a step in AD-Game's tuning loop, and a manifest/PENDING event when the hash
  changes — the Lobby must redeploy like any other shared module.
- SPA stays inverted (lower is better) and Ascension multipliers still apply; the catalog must
  carry whatever the resolver would have produced, not raw `BaseStats`.
- The A5 `--` placeholder in `Stats.BaseStatsFrame.{DMG,RNG,SPA}.TextLabel` is the seam this fills;
  the `Grade` labels beside it are unaffected and keep working from the roll alone.
