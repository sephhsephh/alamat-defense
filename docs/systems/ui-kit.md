# SYSTEM — UI kit (shared canon, BOTH Places)

<!-- owner: AD-UI | scope: global | last-verified: 2026-08-06 (A7) -->

Split out of `docs/systems/lobby-ui.md` at A7 (2026-08-06). That file described the kit from a
Lobby-only viewpoint, which stopped being true on 2026-08-06 when the Game place's hotbar was
rebuilt on it. **This file is Place-neutral: it describes the kit itself.** `lobby-ui.md` now
describes only the Lobby's screens. Studio remains canon for the actual instances and controller
source (ADR-0001); this doc says what exists and why.

## What the kit is

Two halves, both under drift control — **22 manifest entries (15 modules + 7 templates), all GREEN
in both Places.** Was 24 until B2 (2026-08-08) retired `UIKitRewardPopup` + `Kit_RewardPopup`.

- **CONTROLLERS** — client ModuleScripts in `ReplicatedStorage.Shared.UIKit`, with `shared/src`
  files as disk canon. Hashed as SOURCE.
- **TEMPLATES** — REAL instance trees in `ReplicatedStorage.UITemplates.Kit`. **No `shared/src`
  file exists: the INSTANCE is the canon** (ADR-0005). Hashed as a canonical serialisation of the
  subtree, printed with a trailing `*` by `tools/hash_shared.luau`.

**Editing either half in ONE Place is DRIFT.** Change → re-hash → mirror to the other Place →
update `shared/manifest.json`. Both deploy procedures are in `tools/checklists.md`. Templates are
COPIED (Studio copy/paste, prove equality by hash) or built by one identical deterministic script
run in both Places — **never rebuilt by hand or by eye**.

## Controllers (`RS.Shared.UIKit`) — 5 manifest entries

| Manifest key | Deploy path | What it does |
| --- | --- | --- |
| `UIKitButton` | `Shared.UIKit.Button` | ONE behaviour controller for every GuiButton: hover scale-from-centre + stroke thicken or `HoverStrokeColor`, icon rotate, press animation, seamless animated gradient. Entirely attribute-driven. |
| `UIKitBootstrap` | `StarterPlayerScripts.UIKitBootstrap` | LocalScript (hashed as source). Attaches `UIKit.Button` to every instance tagged **`UIKitButton`**, including clones added later. Without it in a Place, tagged buttons are inert. |
| `UIKitItemIcon` | `Shared.UIKit.ItemIcon` | Item card. Flat `IconImage` ImageLabel — **no ViewportFrame, items have no model** — `QtyBadge` that hides at qty 0, tier border/BG from the shared `TierConfig`. |
| `UIKitFilterPanel` | `Shared.UIKit.FilterPanel` | Reusable filter panel. Clones `GroupTemplate`/`ToggleTemplate`; Apply commits pending→applied, Cancel reverts, Reset clears. `handle.selected(groupId)` returns nil when a group is unconstrained, so "no filters" means "show everything". |
| `UIKitHotbar` | `Shared.UIKit.Hotbar` | ONE hotbar for BOTH Places. See below. |

Attribute vocabulary for `UIKitButton`: `HoverScale`, `HoverStrokeMult`, `HoverStrokeColor`,
`HoverIconRotation`, `PressScale`, `TweenTime`, `GradientAnimate`, `GradientSpeed`,
`GlowStrokeName`, `StrokeHiddenUntilHover`.

## Templates (`RS.UITemplates.Kit`) — 7 manifest entries

`Button`, `ItemIcon`, `ItemHoverCard`, `FilterPanel`, `UnitPreviewTemplate`, `UnitIcon`,
`HotbarSlot`.

## RETIRED (2026-08-08, B2) — `UIKitRewardPopup` + `Kit_RewardPopup`

Built at A6 for Phase B gacha, smoke-tested, **never wired to a caller**. The user hand-built
`StarterGui.ObtainRewardsGUI` in the Lobby, which shipped and was verified live at B1, so the kit
pair was retired: controller and template deleted in **both** Places, both manifest entries dropped
(**24 → 22**), and `shared/src/UIKitRewardPopup.luau` deleted. Both Places were re-grepped for
callers first (zero, in both) and re-verified booting afterwards with no errors and no
`Infinite yield`. **Do not re-add it.** Its one genuinely valuable behaviour — catalog-id
resolution where *an id absent from the catalog still renders* rather than erroring — was carried
over into `ObtainRewardsController`. An independent confirmation the template really went: the
Lobby's `UIKitBootstrap` tagged-button count dropped 34 → 33, which is `Kit_RewardPopup`'s
`CloseButton`.

- **`HotbarSlot`** — the **user's own Lobby slot design**, lifted into the kit so both Places draw
  an identical slot (user rule 2026-08-06: same look, different action). Carries `BG`,
  `ViewportFrame`, `TraitIcon`, `LockOverlay` (dark + lock icon + "Lv N") and `SlotNumber`.
- **`UnitIcon`** — the blueprint §5 UnitIcon: `ViewportFrame` + `BG`/tier border + `TraitIcon` +
  `LevelBadge` + `CostLabel` + `NameLabel` + `ShinyBadge`, plus `KeyLabel`/`CountLabel` that
  default **hidden**. **STATUS: NO CONSUMER — PARKED by user decision (ADR-0007, 2026-08-06).**
  The Game hotbar used it until the move to `HotbarSlot`; the only remaining mention is the
  *disabled* `Hotbar_RETIRED` script. It is neither adopted nor deleted — the question is deferred
  to **Phase B**, where the gacha reveal / unit index are the first real consumers.
  - **2026-08-08 (B1): the first consumer ARRIVED and `Kit_UnitIcon` was NOT adopted and NOT
    deleted — it remains PARKED, alongside the card that shipped.** The Lobby's `ObtainRewardsGUI`
    reveal grid uses the user's own `RewardsFrame.UnitTemplate` (150×150, locked by its own
    `UISizeConstraint`), adopted as-is per ADR-0007. **AD-UI'S CALL, stated plainly: that adopted
    card stays LOBBY-LOCAL — it is NOT promoted to shared canon and gets NO manifest entry.**
    Reasoning: the reveal screen is Lobby-only by user decision, so promoting the card would add a
    25th drift-controlled entry and a mirror obligation into a Place with no consumer for it —
    pure drift surface for zero benefit. ADR-0007's own logic (build the component when a real
    consumer needs it) says promote on the SECOND consumer, not the first. The unit index, when it
    ships, is that second consumer and the natural moment to promote — and it is also the moment
    to settle `Kit_UnitIcon`'s fate for good.
  - **Do NOT delete it** without a fresh user decision (it carries a rig).
  - **Do NOT build a `UIKit.UnitIcon` controller speculatively** — the first real consumer designs
    it. The absence of a controller for this template is intentional, not an oversight.
  - **When a unit card IS built, this template is NOT the reference.** The Lobby's shipping Units
    card is lifted into the kit as-is (same move as `HotbarSlot`); fields this icon has and that
    card lacks are ADDED to the user's tree, never used to replace it. See ADR-0007.
- **`ItemIcon`** — **CANON BUMPED `ee1ccd33` → `c5e81264` (2026-08-08, B1). The LOBBY is canon; the
  GAME is STALE.** AD-UI's bootstrap drift check caught the Lobby copy diverging in 7 properties
  across 3 nodes (root `Size`/`Position`/`Visible`, `QtyBadge` `Size`/`Position` including −150/−210
  px offsets, `IconImage.Image` + `Position`). The user was shown each change with its risks and
  confirmed **all of it intentional**, so the divergence was recorded as a canon bump rather than
  reverted. **B2 then mirrored it to the Game and bumped again: `c5e81264` → `5623f4b4`, the
  CURRENT canon, GREEN in both Places.**
  - **The second bump reverted `QtyBadge.Position`** from `(0.8565, −150), (0.96, −210)` back to
    `(0.96, 0), (0.96, 0)` in BOTH Places. **Why: negative PIXEL offsets do not scale with the
    card.** Measured live in the reward grid, every badge landed at offset `(−72, −99)` from its
    own 150×150 cell — `INSIDE_ITS_CELL=false` on all four — so `x7` painted on the *neighbouring*
    card and `x500`/`x2` were clipped away entirely. After the revert all badges measure
    `(94, 111)`, `INSIDE=true`. `QtyBadge.Size` keeps the user's smaller `0.3365`; only the
    position was reverted.
  - **Lesson worth keeping:** a scale-anchored element carrying large negative pixel offsets looks
    right at the size it was dragged at and breaks at every other size. On a template that gets
    reused at different footprints, prefer scale offsets.
  - The master sits at `Visible = true`, unusual for a template. Harmless while it lives in
    `ReplicatedStorage` (nothing renders there) and every consumer clones it — but do not parent
    the master itself into a ScreenGui.
- **`ItemHoverCard`** — **no runtime lookup.** `ItemsGUI.HoverPreview` is a CLONE taken once at
  build time, so **editing this master does NOT update the deployed screen**. Re-clone or edit
  both. This master/clone split is a known sharp edge of template canon; it already caused a
  stale-size bug at A5.
- **`UnitPreviewTemplate`** — unit hover panel, cloned by `UIKitHotbar` for its hover preview in
  both Places. **Has no `UnitLevelBar`** (the Lobby's separate `UnitsGUI.HoverPreview` does), so
  the hotbar preview shows name/tier/stats but NOT level. The code skips it gracefully rather than
  printing nil. Add one to this template if level is wanted there.

ViewportFrame **3D contents are deliberately not hashed** (ADR-0005) — they are display rigs owned
by AD-TowerModels and swapped at runtime, so including them would trip UI drift on every unrelated
rig change. The ViewportFrame's own properties ARE hashed.

## The shared hotbar (`UIKitHotbar` + `Kit_HotbarSlot`)

One component, both Places, so they look and feel identical: same slot design, hover, press
animation and locked/empty states. **A Place supplies only `OnActivated`.**

- **Lobby** click → fires `ClientEvents.OpenUnitsWithUuid`; `UnitsController` opens the Units
  screen focused on that unit. An EMPTY slot fires with `nil` and opens Units unselected, so the
  click always goes somewhere useful (user decision).
- **Game** click → starts **placement**.

Always draws `LoadoutConfig.MaxSlots` (6) slots; a slot is never hidden, only **filled** (model in
viewport, tier border, trait dot) / **empty** (viewport cleared, per-unit details hidden — never
left showing stale data) / **locked** (dark overlay + lock + "Lv N", `Active=false`, genuinely
unclickable).

- **Tier painting:** a slot has **TWO different `UIGradient` instances** — `BG.UIGradient` (the
  background) and `BG.UIStrokeWithGradient.UIGradient` (the border). Both are driven from one
  `tierSeq`. The lookup uses `BG:FindFirstChildOfClass("UIGradient")`, **not** a recursive find,
  which would return the stroke's gradient and make the two fight over one instance. Do not
  "simplify" this. Empty/locked slots get neutral grey `(70,66,82)`.
- **Locks are a LOBBY concern; the Game shows none.** You equip in the Lobby, and the Game has no
  `PlayerLevel` to hand (`LoadoutAssigned` carries TowerId/MetaLevel/Trait only). In-match, slots
  the player did not bring render **EMPTY, not LOCKED**. Real in-match locks would need AD-Game to
  send `PlayerLevel` — a payload change, not a UI fix.
- **Hover preview** clones `Kit.UnitPreviewTemplate`, shown **only for a FILLED, UNLOCKED slot**,
  positioned above the slot and clamped to both screen edges. It fills defensively from whatever
  the Place's entry carries (Lobby: a unitView with Name/Tier/Level/Grades; Game: a loadout row
  with TowerId/MetaLevel/Trait) and **leaves grade rows untouched when absent** rather than
  blanking them.
- **UNVERIFIED (carried forward):** the hover *trigger* itself. `MouseEnter` cannot be fired from
  tooling and `VirtualInputManager` is blocked, so "the card appears on a real hover" remains
  code-inspection-only in BOTH Places. One manual hover in each Place closes this.

## Configs the kit depends on (all shared canon)

`Configs.Meta.TierConfig` (8 tiers, per-tier `Colors` list — Mythic rainbow, Secret red→dark-red;
helpers `get`/`colorSequence`/`seamlessSequence`/`isMultiColor`), `ItemCatalog` (the authority on
a grantable's Name/Tier/Icon), `StatGradeConfig` (roll 0..1 → D..Apex), `AscensionConfig`, and
`LoadoutConfig` (`MaxSlots = 6`, `SlotUnlockLevel = {1,1,1,5,20,50}` — shared because if only one
Place knew, the two hotbars would disagree).

## Rules that keep the kit healthy

- **NEVER generate UI in scripts** (user rule, 2026-07-18). Templates are real Instances the user
  can edit in Studio; controllers only clone, fill and wire. Dynamic lists use a designed
  `*Template` instance with `Visible = false`.
- **No scripts inside templates.** The legacy per-slot `Unit/ItemIconTemplateLocalScript` (a
  syntax error on line 30, `ocal Preview`) was removed from the kit at A5 but survived in the live
  Lobby slots until 2026-08-06, throwing 6× on every Lobby load. Verify clones carry no scripts.
- **When you resize a Kit template, re-sync any already-deployed clone.** See `ItemHoverCard`.
- Adding a property to `tools/hash_shared.luau`'s whitelist **changes every template hash** — say
  so in the changelog (ADR-0005).
