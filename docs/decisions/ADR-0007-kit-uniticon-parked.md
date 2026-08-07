# ADR-0007 — `Kit_UnitIcon` is PARKED, not adopted and not deleted; §8 reads pragmatically

<!-- decided: 2026-08-06 (USER, via AD-Integration) | status: ACCEPTED -->

## Context

`Kit_UnitIcon` (`24281a2b`, `RS.UITemplates.Kit.UnitIcon`, deployed byte-identically in both
Places) has **no consumer**. The A7 acceptance run confirmed it live: the only remaining reference
anywhere is the *disabled* `Hotbar_RETIRED` script in the Game place.

It became consumerless honestly rather than by neglect. It was built at A6 as the blueprint §5
UnitIcon and put to work as the Game hotbar's slot — then the user's request for one identical
hotbar in both Places replaced it with `Kit_HotbarSlot` (their own Lobby slot design, lifted into
the kit). The template survived the thing it was built for.

That left blueprint §8's *"hotbar + units + items screens all render through the kit"* in an
awkward state. A7 graded it:

- **Hotbar** → PASS (`UIKit.Hotbar` + `Kit_HotbarSlot`)
- **Items** → PASS (`UIKit.ItemIcon` cards, verified 0 ViewportFrames)
- **Units** → **PARTIAL**: it uses the kit's `FilterPanel` and the shared
  `TierConfig`/`StatGradeConfig`/`UnitStatsCatalog`, but its CARDS (`UnitCard_<uuid>`, carrying
  `PlacementPrice` and a level label) are a screen-local design, not `Kit.UnitIcon` clones.

Once A8 closed the counters/worthiness failure, this was the **last** §8 item not passing outright,
so it stood between the project and Phase A sign-off. The user was asked to decide rather than have
a chat act unilaterally — the template carries a rig, and the user had previously asked for it to be
kept.

## Decision (USER, 2026-08-06)

**1. PARK the template.** No code change, no template change, no deletion. `Kit_UnitIcon` stays
drift-controlled canon in both Places with its "no consumer" note intact. The question is deferred
to **Phase B**, where the gacha summon reveal and the unit index are the first features that will
genuinely need a unit card — and will therefore tell us what the component actually has to do.
Designing it now, against zero real consumers, is how you get a component that fits nothing.

**2. §8 reads PRAGMATICALLY — the Units screen PASSES.** "Renders through the kit" is satisfied by
the shared FilterPanel and the shared config stack. The card exception is recorded rather than
pretended away. **Phase A is therefore unblocked**, pending only a short AD-Integration §8 re-check.

**3. If a shared unit-card component is ever built, the USER'S design wins.** `Kit_UnitIcon` is
*not* the reference. The Units screen's actual shipping card is lifted into the kit as-is, exactly
as `Kit_HotbarSlot` was; any fields the kit icon has and the user's card lacks (`ShinyBadge`,
`CostLabel`, `KeyLabel`/`CountLabel`) are **added to the user's tree**, never used as grounds to
replace it. This is now the standing rule for kit promotion, not a one-off.

**4. The Collection screen is OUT OF SCOPE.** It renders its own `Panel.Grid.CardTemplate` with
zero kit references. It stays that way and adopts a shared card only opportunistically, under the
existing convert-on-touch rule. Folding two working screens into a Phase-A closing task was
rejected as unnecessary blast radius.

## Consequences

- **Phase A can be signed off** by AD-Integration without any UI work. The §8 verdict is
  PASS-with-a-recorded-exception, not a silent pass.
- `Kit_UnitIcon` keeps costing one drift-controlled entry (24 total) for something nothing uses.
  Accepted deliberately: the cost is a hash check, and the alternative destroys a rigged template
  that Phase B is likely to want within one phase.
- **Do not delete `Kit_UnitIcon`** without a fresh user decision. This ADR is that instruction's
  new home; the old "do not delete without asking" note in the manifest and `ui-kit.md` points here.
- **Do not build a `UIKit.UnitIcon` controller speculatively.** The first real consumer designs it.
- The precedent set in (3) — *the user's shipping design is the source of truth when promoting into
  the kit* — now applies to every future kit promotion, alongside `Kit_HotbarSlot`'s example.
- If Phase B's gacha reveal turns out to need something structurally different from the Units card,
  revisit this ADR rather than bending the Units card to fit.
