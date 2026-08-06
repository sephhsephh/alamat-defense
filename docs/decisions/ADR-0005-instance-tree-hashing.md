# ADR-0005 — Drift-checking UI templates by hashing a canonical instance-tree serialisation

<!-- status: ACCEPTED 2026-08-06 | owner: AD-Integration (tools/) | supersedes nothing -->

## Context

The drift system (`shared/manifest.json` + `tools/hash_shared.luau` + the bootstrap drift check)
was **source-text based**: it hashed `inst.Source` and reported `MISSING` for anything that was
not a `LuaSourceContainer`.

The UI kit breaks that assumption. It is two different kinds of thing:

| Part | Examples | Source text? |
|---|---|---|
| Controllers (ModuleScripts) | `UIKit.Button`, `UIKit.ItemIcon`, `UIKit.FilterPanel` | yes |
| Templates (GuiObjects) | `Kit.Button`, `Kit.ItemIcon`, `Kit.ItemHoverCard`, `Kit.FilterPanel`, `Kit.UnitPreviewTemplate` | **no** |

The constitution's no-UI-in-scripts rule (2026-07-18) means templates *must* be real Instances,
so this is permanent, not a transitional state. Copying templates between Places would create a
divergence surface invisible to the drift check — the exact failure class this repo exists to
prevent. It already bit once: at A5 `ItemsGUI.HoverPreview` silently kept a stale size after its
template was resized, caught only by manual comparison.

Blueprint §9 A6 (Game-place hotbar "on kit") is blocked behind this, and every future shared UI
component — `RewardPopup`, `CurrencyBar`, `UnitHoverCard`, `ViewportPreview`, `NPCPrompt` — has
the same problem. User decision 2026-08-06: **fix the mechanism first**
(`docs/proposals/2026-08-06-kit-promotion-blocks-a6.md`, option B).

## Decision

Templates become **first-class manifest entries**, hashed by serialising the subtree to a
canonical string and running the same `fnv1a32` over it. Module hashing is untouched, so every
historical module hash stays valid.

### Canonical format

One line per instance, depth-first:

```
<depth>|<ClassName>|<Name>|<prop=value;...>|{<attr=value;...>}|[<tag,...>]
```

- **Properties** come from a single whitelist **by name** (not per class); reads are `pcall`'d, so
  a name simply does not apply to a class that lacks it. Sorted alphabetically — property order
  can never affect the hash.
- **Attributes** are included. The kit is attribute-driven (`HoverScale`, `HoverStrokeColor`, …),
  so they carry real design intent.
- **CollectionService tags** are included — `UIKitButton` is what wires a button to the kit at all.
- **Children** are serialised recursively and then **sorted by their serialised text**. Studio's
  child ordering is therefore irrelevant, and ordering stays deterministic even if two siblings
  ever share a name and class.
- **Numbers** print at `%.4f`; **Color3** prints as 0–255 integers (the authoring unit). Both
  choices exist so float round-tripping cannot flip a hash.

Template hashes are printed with a trailing `*` to distinguish them from module hashes at a glance.

### Deliberately NOT hashed

- **ViewportFrame 3D contents.** The kit's viewports contain display rigs (`Humanoid`, `MeshPart`,
  112 `Attachment`s, 150 `Vector3Value`s — 679 instances across the kit, vs 167 once excluded).
  Those rigs are **AD-TowerModels canon** and are swapped at runtime by the controllers. Hashing
  them would make UI drift trip on every unrelated rig change. The ViewportFrame's own properties
  (Ambient, LightColor, LightDirection, FieldOfView, geometry) ARE hashed.
- Instance references (`CurrentCamera`), engine bookkeeping (`Archivable`, `RobloxLocked`), and any
  value type not in the formatter — unsupported types are skipped rather than guessed at.

## Consequences

**Good.** Templates can be deployed between Places and verified byte-for-byte like modules. The
kit can be promoted once, correctly, with every part covered. The failure class is closed for all
future shared UI.

**Cost / limits — read before trusting a green check:**

1. **The whitelist is the contract.** A property that is not listed is invisible to the check. If
   a new design-bearing property starts being used, add it — and note it in the changelog, because
   **adding a property changes every template hash at once**. Treat that like a schema bump: land
   it in one Integration session and redeploy, don't let it look like drift.
2. **3D content is unverified** by construction (above). If a viewport's rig contents ever become
   design-bearing rather than swapped-at-runtime, this ADR needs revisiting.
3. **Hash equality proves the serialisation matches, not that the trees are identical** in every
   respect. That is the point — but it means "drift green" is a statement about the whitelisted
   surface, not a pixel guarantee.
4. `fnv1a32` is a 32-bit non-cryptographic hash. Collisions are not a practical concern for a
   handful of tracked artefacts, and it is deliberately the same function the modules already use.

## Verification performed (2026-08-06, Lobby place, all reverted)

| Change | Expected | Result |
|---|---|---|
| Re-run with no edits | identical | stable ✅ |
| `Size` +1px | hash moves | ✅ then restored exactly |
| Nested `UIStroke.Color` deep in tree | hash moves | ✅ restored |
| Attribute added | hash moves | ✅ restored |
| CollectionService tag added | hash moves | ✅ restored |
| Child reparented to end (order change) | **unchanged** | ✅ unchanged |
| Child renamed | hash moves | ✅ restored |
| All 9 existing module hashes | unchanged vs manifest | ✅ 9/9 exact |
| Kit read in the Game place (absent) | `MISSING` | ✅ 5/5 MISSING |

## How to put a template under drift control

1. Add it to `TEMPLATES` in `tools/hash_shared.luau` (entries for the 5 kit templates are present,
   commented out, awaiting AD-UI's promotion session).
2. Deploy it to every Place that needs it, then run the tool in each.
3. Add a `shared/manifest.json` entry with `"kind": "template"`, the hash, and `deployed` per Place.
4. From then on it is bootstrap-checked exactly like a module.

Because a template cannot be written from a text file the way a module can, **deploying one means
copying the Instance between Places in Studio** and then confirming the hashes match. The hash is
what makes that copy verifiable — it does not automate it.
