# Proposal: the V2 unit icon needs PLACEMENT COST and ELEMENT, and neither exists in the Lobby

<!-- from: AD-UI (B24, 2026-08-16) | to: AD-Game (owner of tower configs) | status: OPEN -->

## What triggered this

The user authored three V2 kit templates at B24 — `Kit.UnitIconV2`, `Kit.ItemIconV2`,
`Kit.HotbarSlotV2` — and asked for the unit icon to show, per unit: placement price, name, element
icons, trait icon and level.

Four of those are already wireable. **Two are not, and no amount of UI work fixes that.**

| Element on `UnitIconV2` | Source | Status |
| --- | --- | --- |
| `UnitName` | `ItemCatalog.GetName(towerId)` | ✅ |
| `UnitLevel` | `GetUnitViews` → `Level` | ✅ |
| `EquipFavoriteLockIcons` | `GetUnitViews` → `Equipped`/`Favorited`/`Locked` | ✅ read-only |
| `PlacementPrice` | **nothing** | ❌ |
| `ElementIcons` (`Element1`, `Element2`) | **nothing** | ❌ |
| `TraitIcon` | **nothing** — see the sibling proposal | ❌ |

## The evidence

Grepped in the Lobby at B24:

- `UnitStatsCatalog` — the only per-tower numeric source this Place has — is literally
  `Archer = { DMG = 15, RNG = 20, SPA = 6 }`. **No `Cost`, `PlacementCost`, `Price` or `Placement`
  key of any kind**, and no `Element`.
- `ItemCatalog` carries `Name`/`Tier`/`Icon`/`Kind`/`Description`/`MaxOwned` — **no cost, no element.**
- `RS.Configs.Towers` does not exist in the Lobby at all; it is the Place assertion's *negative*
  half. Tower configs are Game-only by design.

So the Lobby cannot compute or look up either number. This is the same shape as the reward preview
before B20: the rendering was AD-UI's job, but the *numbers* lived in AD-Game's canon and had to be
promoted to shared canon before the preview could be honest.

## Why AD-UI did not just add them

Three reasons, in order of weight:

1. **Tower configs are AD-Game's canon.** CLAUDE.md's single-writer rule: a non-owner writes a
   proposal, not an edit.
2. **A made-up price is the exact failure mode blueprint §8 exists to prevent.** The reward preview
   was left blank for two sessions rather than show a plausible-looking gold figure. A placement
   price the Game would not charge is the same lie in a different panel.
3. **`UnitStatsCatalog` is GENERATED** (ADR-0003) — regenerated from the live tower configs by a
   Game-only validator that errors loud on drift. Hand-adding a field here would be overwritten.

## Proposed shape (AD-Game's call, not AD-UI's)

The cheapest option that matches the existing precedent is to **extend the generated
`UnitStatsCatalog`**, since it is already shared canon, already per-tower, and already regenerated
from the real configs:

```lua
Archer = { DMG = 15, RNG = 20, SPA = 6, Cost = 250, Elements = { "Wind" } },
```

- `Cost` — the placement cost the Game actually charges. One number, per tower.
- `Elements` — an ORDERED list. The V2 icon has exactly two slots (`Element1`, `Element2`), so a
  unit with one element hides the second and a unit with three would need a design answer first.

Whatever shape is chosen, the regeneration step and its validator must produce it, or it will drift
the moment a tower is retuned.

**Element icon assets are a separate question** and are the user's: the config should carry an
element *id*, and the id → image mapping belongs next to the other icon ids (the user supplied the
`ItemCatalog` icon assetids at B22/B23).

## What AD-UI did in the meantime

`UnitIconV2` renders everything that has a real source and **hides `PlacementPrice` and
`ElementIcons`**, exactly as `LevelsClearedLabel`/`ProgressPercentLabel` are hidden on the stage
rows. A hidden label is not a claim; a fabricated ₱67,000 is.

Unhide them here once the fields exist — do not invent a placeholder economy in the UI.
