# Proposal: `TraitDefinitions` has no icon field, so the V2 unit icon cannot show a trait

<!-- from: AD-UI (B24, 2026-08-16) | to: AD-Traits (owner of the trait table) | status: OPEN -->

## The gap

`Kit.UnitIconV2` (authored by the user at B24) has a `TraitIcon` ImageLabel. There is nothing to
put in it.

`RS.Configs.Traits.TraitDefinitions` is shared canon (promoted at B12, hash `56e81e37`, byte-identical
in both Places). Each entry carries:

```lua
{ Id = "None", DisplayName = "None", Rarity = "Common", Weight = 1000, StatMultipliers = {} }
```

Grepped at B24: the module contains **no `Icon`, no `Image`, no `assetid` and no `rbxassetid`** —
not on any entry, not as a lookup table, nowhere.

The trait itself IS available per unit: `GetUnitViews` serves `Trait` (a trait id, or nil after
B12 normalised `"None"` → nil). So the Lobby knows *which* trait a unit has and can already show its
`DisplayName` and `Rarity`. It just cannot show a picture of it.

## Proposed shape (AD-Traits' call)

Add one optional field per entry:

```lua
{ Id = "Godly", DisplayName = "Godly", Rarity = "Legendary", Weight = 5,
  StatMultipliers = { ... }, Icon = "rbxassetid://<id>" },
```

- **Optional on purpose.** `None` needs no icon, and the UI already hides the ImageLabel when the
  unit has no trait. A missing `Icon` on a real trait should hide the label, not render a broken
  image.
- **The asset ids are the USER's**, like the `ItemCatalog` icons they supplied at B22/B23. AD-Traits
  should add the field and leave the ids to them rather than guessing.

## Cost of the change

`TraitDefinitions` is shared canon deployed in BOTH Places, so this is the standard drift procedure,
not a local edit: change → re-hash → copy to the other Place → update `shared/manifest.json`
(`tools/checklists.md`). It is additive and optional, so **no consumer breaks** — `TraitRegistry.Roll`
and the stat multipliers are untouched, and the Game reads none of the new field.

Note it also unblocks a nicety elsewhere: the Units screen and the summon reveal both currently show
a trait by name only.

## What AD-UI did in the meantime

`UnitIconV2.TraitIcon` is **hidden** until the field exists. Same rule as the placement price and
the element icons in the sibling proposal: a hidden element is honest, a wrong one is not.
