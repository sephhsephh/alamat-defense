# Proposal: V2 kit adoption — the field gaps, and the one decision already made

<!-- author: AD-Integration (B25, 2026-08-16) | scope: BOTH Places | status: OPEN -->
<!-- Outcome of the B25 adoption session: GAP ANALYSIS + ONE USER DECISION LANDED. Nothing migrated,
     nothing copied to the Game, no template or consumer touched. Drift unchanged in both Places. -->

## Why this document exists

B25 was briefed to adopt `Kit.{UnitIconV2, ItemIconV2, HotbarSlotV2}`, replacing v1 outright. The
brief's own stop condition was: *"STOP AND ASK IF the migration turns out to need a v1 field the V2
template lacks, or if any consumer would visibly regress — a proposal + PENDING is the correct
outcome over a half-migration."*

**It fired, on all three templates.** The audit is below so the next session does not repeat it.

## ✅ DECIDED BY THE USER AT B25 — do not re-derive this

**Rarity colour in V2 goes on the ROOT `UIGradient`, and the tier BORDER is dropped.**

v1 paints tier colour onto **two** instances: `BG` (an ImageLabel whose `UIGradient` is the fill) and
`UIStrokeWithGradient` (the border). Neither exists in any V2 template. V2 has one root `UIGradient`
plus `UIHoverStroke`, and that stroke is reserved for the hover behaviour (authored `Enabled = false`,
driven from MouseEnter/MouseLeave) — painting rarity onto it would collide with hover.

The user chose **root `UIGradient` only**. So in V2:

* `TierConfig.seamlessSequence(tier)` → the **root** `UIGradient.Color`. One surface, one call site.
* **There is no tier border in V2.** This is an accepted, deliberate visible restyle across summon
  chips, index entries, the items grid, the reward grid and both hotbars. It is not a bug and must
  not be "fixed" by re-adding a stroke.
* `UIHoverStroke` stays hover-only. **Do not write a second gradient animator** — the seamless
  animated sequence every other screen already uses is the one to reuse.

## ⛔ STILL BLOCKING — three consumers lose a field with no V2 equivalent

Each needs an instance authored on the V2 template (the user's design, so the user's call, exactly
as B24 handled the missing data sources). None can be faked in script without inventing UI, which
the 2026-07-18 rule bans.

| Template | Missing | Consumer + the exact call | What breaks |
| --- | --- | --- | --- |
| `HotbarSlotV2` | **`SlotNumber`** | `UIKit.Hotbar`: `setText(btn, "SlotNumber", tostring(i))` | the **1–6 key number on every hotbar slot, in BOTH Places**. This is the Game's placement hotbar too. |
| `UnitIconV2` | **`CountLabel`** | `IndexController`: `cell:FindFirstChild("CountLabel", true)` | the owned-count on every codex entry |
| `ItemIconV2` | **`UIAspectRatioConstraint`** | `ObtainRewardsController` documents it **twice** as the reason reward art is never stretched in the 150×150 grid | item art stretches in the reward grid |

**Suggested shape** (plain and functional, so restyling needs no code change):
`SlotNumber` a TextLabel on `HotbarSlotV2.Main`; `CountLabel` a Frame+TextLabel on `UnitIconV2.Main`
mirroring `UnitLevel`; `UIAspectRatioConstraint` AspectRatio 1, `FitWithinMaxSize`, on `ItemIconV2`'s
root — matching v1's.

## The rename map (mechanical — no decision needed)

| v1 | V2 | Consumers |
| --- | --- | --- |
| `CostLabel` | `PlacementPrice` | SummonController (hides it), AscensionController |
| `LevelBadge` | `UnitLevel` → `.TextLabel` | AscensionController |
| `NameLabel` | `UnitName` | — |
| `IconImage` | `ItemIcon` | `UIKit.ItemIcon`, ObtainRewardsController |
| `QtyBadge` | `Amount` → `.TextLabel` | `UIKit.ItemIcon`, ObtainRewardsController |
| `BG` + `UIStrokeWithGradient` | root `UIGradient` | **all** — see the decision above |
| `ShinyBadge` | *(none)* | **no consumer found — safe to drop** |

## The full consumer list — THREE `Kit.UnitIcon` consumers, not two

The brief listed two. There is a third:

* `SummonScreen.SummonController` — featured chips
* `IndexScreen.IndexController` — codex entries (**+ `CountLabel`**)
* **`StarterPlayerScripts.AscensionController` — the dupe-picker grid** (uses `LevelBadge`). Missed
  by the brief; it clones `Kit.UnitIcon` at its line 199.
* `Kit.ItemIcon`: the shared **`UIKit.ItemIcon` controller** (→ ItemsController) **and**
  `ObtainRewardsController`, which clones the master directly rather than going through the kit.
* `Kit.HotbarSlot`: the shared **`UIKit.Hotbar`** controller — **this is what makes adoption
  cross-Place**, since the Game's hotbar renders through it.

`StoryModeController` is **not** a consumer: its `ItemIconTemplate` is a screen-local instance and it
only calls `UIKit.ItemIcon.ImageFor` (a function). It is unaffected.

## Fields with no data source — unchanged from B24, restated so they are not re-litigated

`PlacementPrice` and `ElementIcons` (`docs/proposals/2026-08-16-tower-display-fields-for-uniticon-v2.md`)
and `TraitIcon` (`2026-08-16-trait-icons.md`) have **no data source in the Lobby**. Render them
**HIDDEN**, never zeroed and never invented — a fabricated price is the same class of lie §8 exists to
prevent. `HotbarSlotV2.Placed/MaxPlacement` is a MATCH-runtime number: **Game place only, hidden in
the Lobby**. (Note its name contains a `/`, so it needs `FindFirstChild`, not dot notation.)

**Favourite and Lock stay READ-ONLY.** They are in the profile and in `GetUnitViews`, but none of the
17 remotes writes them, and `AscensionRules` treats both as protection from being consumed as a dupe
— making them togglable is a gameplay change needing the user's call. `LockUnitButon` (sic) is
authored and unwired; leave it.

## Recommended order for the build session

**AD-Integration, both Places open.** Once the three instances above are authored:

1. Migrate the five consumers to the V2 names + the root-`UIGradient` rarity rule.
2. Copy the three V2 templates to the GAME (copy, never rebuild — `tools/checklists.md`).
3. Re-hash; ADD the V2 entries to `shared/manifest.json`; RETIRE the v1 entries the way the
   RewardPopup pair was retired at B2 (delete in both Places, drop from the manifest and from
   `tools/hash_shared.luau`).
4. Verify BOTH Places drift-green, and prove every consumer still renders from a REAL script.

**Do not copy the V2 templates to the Game before step 1.** They would sit unused there, and the
manifest would describe a kit neither Place actually uses.
