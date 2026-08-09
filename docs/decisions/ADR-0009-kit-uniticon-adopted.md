# ADR-0009 — `Kit_UnitIcon` is ADOPTED as the shared unit icon, with no controller

<!-- decided: 2026-08-09 (USER, via AD-Gacha at B8) | status: ACCEPTED -->
<!-- supersedes the "PARKED" status in ADR-0007; ADR-0007's other four clauses still stand -->

## Context

**ADR-0007 parked `Kit_UnitIcon`** (`24281a2b`, `RS.UITemplates.Kit.UnitIcon`, drift-controlled in
both Places) with no consumer, and said the question would be settled in Phase B — *"where the
gacha summon reveal and the unit index are the first features that will genuinely need a unit card,
and will therefore tell us what the component actually has to do."*

Phase B has now answered it, twice, and not the way anyone guessed:

- **B1 (reveal)** declined it. The user's own `UnitTemplate` shipped as the reveal card instead.
- **B6 (summon UI)** used it for the banner's featured chips — its first real consumer — but
  explicitly did **not** settle this ADR.
- **B8 (this index)** is its second real consumer: every codex entry is a `Kit_UnitIcon` clone.

Two independent consumers, both of which clone it and fill it locally, and **neither of which
wanted a controller.** That is the evidence ADR-0007 was waiting for.

## Decision (USER, 2026-08-09)

**1. UN-PARK it. `Kit_UnitIcon` is ADOPTED** as the shared unit ICON — the small,
grid-cell-sized representation of a tower. It stays drift-controlled canon in both Places, and the
"no consumer" note in the manifest and `ui-kit.md` is retired: it has two.

**2. Still NO `UIKit.UnitIcon` controller.** ADR-0007 said *"do not build one speculatively — the
first real consumer designs it."* Two consumers later, neither has asked for one: both do
`clone → paintTier → setViewportModel → hide the fields they don't need`, and the *fields they
don't need are different each time* (the summon chip hides `LevelBadge`/`CostLabel`, the index
hides those plus `ShinyBadge`/`TraitIcon` and repurposes `CountLabel`). A controller would have to
be configured into doing nothing in slightly different ways. **Revisit only when a third consumer
wants the same behaviour**, not merely the same template.

**3. It is an ICON, not the unit CARD. ADR-0007 clause 3 is untouched.** If a shared unit *card*
(the large, detailed Units-screen style) is ever built, the user's shipping design still wins and
`Kit_UnitIcon` is still not the reference. These are two different components and adopting one says
nothing about the other.

## Consequences

- The manifest entry and `docs/systems/ui-kit.md` drop "NO CONSUMER — PARKED"; the
  **"do not delete without a fresh user decision"** instruction stands, and this ADR is now its home.
- **No shared canon changed.** Adoption here means *being used*, not *being edited* —
  `Kit_UnitIcon` still hashes `24281a2b` in both Places, verified at B8's landing. Adoption cost
  zero drift and needed no Integration session.
- The silhouette state costs nothing extra: `ViewportFrame.ImageColor3` on the clone turns an
  entry into a silhouette with one property, so a codex needs no second template.
- A future kit consumer should clone and fill, matching `ObtainRewardsController` (with
  `Kit_ItemIcon`), `SummonController` and `IndexController`. That is now the house pattern for kit
  templates without controllers, not an accident.
