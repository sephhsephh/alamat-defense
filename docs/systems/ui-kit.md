# SYSTEM — UI kit (shared canon, BOTH Places)

<!-- owner: AD-UI | scope: global | last-verified: 2026-08-16 (B25) -->

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

## Controllers (`RS.Shared.UIKit`) — 6 manifest entries

| Manifest key | Deploy path | What it does |
| --- | --- | --- |
| `UIKitButton` | `Shared.UIKit.Button` | ONE behaviour controller for every GuiButton: hover scale-from-centre + stroke thicken or `HoverStrokeColor`, icon rotate, press animation, seamless animated gradient. Entirely attribute-driven. |
| `UIKitBootstrap` | `StarterPlayerScripts.UIKitBootstrap` | LocalScript (hashed as source). Attaches `UIKit.Button` to every instance tagged **`UIKitButton`**, including clones added later. Without it in a Place, tagged buttons are inert. |
| `UIKitItemIcon` | `Shared.UIKit.ItemIcon` | Item card on `Kit.ItemIconV2` (B26). Flat `ItemIcon` ImageLabel — **no ViewportFrame, items have no model** — `Amount` badge that hides at qty 0, `ItemName`, rarity on the ROOT `UIGradient` from the shared `TierConfig`. |
| `UIKitFilterPanel` | `Shared.UIKit.FilterPanel` | Reusable filter panel. Clones `GroupTemplate`/`ToggleTemplate`; Apply commits pending→applied, Cancel reverts, Reset clears. `handle.selected(groupId)` returns nil when a group is unconstrained, so "no filters" means "show everything". |
| `UIKitHotbar` | `Shared.UIKit.Hotbar` | ONE hotbar for BOTH Places. See below. |
| `UIKitMotion` | `Shared.UIKit.Motion` | The kit's ONE animation home (B27c, extended B28). Hover/press scaling, the idle gradient sheen, `isolate()`'s fixed-size wrapper, `lift()`, and the **open/close slide**. See below. |

Attribute vocabulary for `UIKitButton`: `HoverScale`, `HoverStrokeMult`, `HoverStrokeColor`,
`HoverIconRotation`, `PressScale`, `TweenTime`, `GradientAnimate`, `GradientSpeed`,
`GlowStrokeName`, `StrokeHiddenUntilHover`.

## Templates (`RS.UITemplates.Kit`) — 7 manifest entries

`Button`, `ItemIconV2`, `ItemHoverCard`, `FilterPanel`, `UnitPreviewTemplate`, `UnitIconV2`,
`HotbarSlotV2` (the v1 trio was RETIRED at B26 — see the V2 section below).

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
  default **hidden**. **STATUS: ADOPTED as the shared unit ICON — user decision 2026-08-09,
  ADR-0009, which un-parks ADR-0007.** Two real consumers, both in the Lobby:
  `SummonScreen`'s featured chips (B6) and every `IndexScreen` codex entry (B8).
  - **There is still NO `UIKit.UnitIcon` controller, deliberately.** Both consumers clone and fill
    it locally (`clone → paintTier → setViewportModel → hide what they don't need`), and the fields
    they hide are *different each time* — a controller would have to be configured into doing
    nothing in two slightly different ways. Revisit on a third consumer that wants the same
    BEHAVIOUR, not merely the same template. Cloning and filling is the house pattern for kit
    templates without controllers (`ObtainRewardsController` does it with `Kit_ItemIcon` too).
  - **Adoption changed no bytes.** It means *being used*, not *being edited*: the template still
    hashes `24281a2b` in both Places, verified at B8's landing. Zero drift, no Integration needed.
  - **It is an ICON, not the unit CARD.** ADR-0007 clause 3 still stands: if a shared unit *card*
    (the large Units-screen style) is ever built, the **user's shipping design wins** and this is
    not the reference. The Lobby's `ObtainRewardsGUI` reveal card (`RewardsFrame.UnitTemplate`,
    150×150) remains **Lobby-local with no manifest entry** — B1's call, unchanged: promoting it
    would buy a mirror obligation into a Place with no consumer.
  - **Do NOT delete it** without a fresh user decision (it carries a rig). ADR-0009 is that
    instruction's home now.
  - Handy: `ViewportFrame.ImageColor3` turns a clone into a **silhouette** with one property —
    which is how the index shows unobtained units without a second template.
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

## The shared hotbar (`UIKitHotbar` + `Kit_HotbarSlotV2`)

One component, both Places, so they look and feel identical: same slot design, hover, press
animation and locked/empty states. **A Place supplies only `OnActivated`.**

- **Lobby** click → fires `ClientEvents.OpenUnitsWithUuid`; `UnitsController` opens the Units
  screen focused on that unit. An EMPTY slot fires with `nil` and opens Units unselected, so the
  click always goes somewhere useful (user decision).
- **Game** click → starts **placement**.

Always draws `LoadoutConfig.MaxSlots` (6) slots; a slot is never hidden, only **filled** (model in
viewport, tier colour, trait dot) / **empty** (viewport cleared, per-unit details hidden — never
left showing stale data) / **locked** (dark overlay + lock + "Lv N", `Active=false`, genuinely
unclickable). `SlotNumber` carries the 1–6 key number in both Places.

- **Tier painting (B26): ONE gradient, on the slot ROOT.** v1 had **two** — `BG.UIGradient` (fill)
  and `BG.UIStrokeWithGradient.UIGradient` (border) — and a long warning about keeping them apart.
  `HotbarSlotV2` has neither instance, so the whole hazard is **deleted, not re-created**: do not
  reintroduce a second paint surface. The lookup is `btn:FindFirstChildOfClass("UIGradient")` and
  **direct-children-only is still load-bearing** — V2 nests gradients under `UnitLevel`,
  `PlacementPrice` and `TraitIcon`. Empty/locked slots get neutral grey `(70,66,82)`.
- **`UnitLevel` shows only when the entry carries `MetaLevel` or `Level`, and HIDES otherwise** — the
  Game and Lobby build entries from different sources and a zero would be a claim. Write it as
  `setText(btn, "UnitLevel", …)` from the **slot root**: see the `setText` trap below.
  `PlacementPrice` and `Placed/MaxPlacement` are present-but-HIDDEN — nothing feeds either yet.
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
  code-inspection-only in BOTH Places. One manual hover in each Place closes this. B26 did prove the
  *effect*: `paintStroke()` toggles `UIHoverStroke`, and the stroke is authored off at rest.

## Configs the kit depends on (all shared canon)

`Configs.Meta.TierConfig` (8 tiers, per-tier `Colors` list — Mythic rainbow, Secret red→dark-red;
helpers `get`/`colorSequence`/`seamlessSequence`/`isMultiColor`), `ItemCatalog` (the authority on
a grantable's Name/Tier/Icon), `StatGradeConfig` (roll 0..1 → D..Apex), `AscensionConfig`, and
`LoadoutConfig` (`MaxSlots = 6`, `SlotUnlockLevel = {1,1,1,5,20,50}` — shared because if only one
Place knew, the two hotbars would disagree).

## The V2 templates — **ADOPTED IN BOTH PLACES, v1 RETIRED (B26, 2026-08-16)**

`Kit.{UnitIconV2, ItemIconV2, HotbarSlotV2}` are the USER's own redesigns and are now the **only**
unit/item/slot templates. `Kit_UnitIcon` / `Kit_ItemIcon` / `Kit_HotbarSlot` were **deleted in both
Places and dropped from `shared/manifest.json` + `tools/hash_shared.luau`** — the same retirement the
RewardPopup pair got at B2. **Do not re-add them.** Both Kits hold 7 children; the manifest is still
26 entries. Hashes: `UnitIconV2 8e6ab2ad`, `ItemIconV2 0b8cb83d`, `HotbarSlotV2 41c3c9e3`.

**Shared V2 structure:** root `ImageButton` + `UIGradient` + `UICorner` + `UIHoverStroke` (a UIStroke
authored `Enabled = false`, driven from MouseEnter/MouseLeave) + `Main`.

**RARITY IS PAINTED ON THE ROOT `UIGradient` AND THERE IS NO TIER BORDER** (user decision, B25). v1
painted TWO instances — `BG`'s gradient (fill) and `UIStrokeWithGradient` (border) — and carried a
long comment warning not to confuse them. **Neither instance exists in V2**, so that hazard is
deleted rather than re-created: one paint surface, one call site, `TierConfig.seamlessSequence` as
always. Do not write a second gradient animator, and do not "restore" a tier border.

**`FindFirstChildOfClass` on the ROOT is load-bearing, and it is DIRECT-CHILDREN-ONLY.** V2 nests
`UIGradient`s under `UnitLevel`, `PlacementPrice`, `TraitIcon` and `Amount`. A recursive find
repaints the badge instead of the card. Every consumer looks the root gradient up this way.

### Three instances the USER authored at B26, and what each unbroke

| Template | Authored | Why |
| --- | --- | --- |
| `HotbarSlotV2` | `SlotNumber` (TextLabel) | the SHARED `UIKit.Hotbar` does `setText(btn,"SlotNumber",i)` — without it every slot loses its 1–6 key number in **BOTH** Places |
| `UnitIconV2` | `CountLabel` **as a TextLabel** | v1's was a **Frame** while `IndexController` guards `IsA("TextLabel")` — the index owned-count had **never rendered once**. The branch is live for the first time |
| `ItemIconV2` | `UIAspectRatioConstraint` (1 / FitWithinMaxSize / Width) | `ObtainRewardsController` documents it twice as why reward art is not stretched in the 150×150 grid |

**Copying a template into the other Place is a USER action**, not a tool action — `execute_luau` is
scoped to one datamodel. Pause, give the exact paths and the expected hash, wait, then verify by
hash. (User rule, B26.) Procedure: `tools/checklists.md` step 2.

### The rename map (applied everywhere)

`NameLabel`→`UnitName`, `LevelBadge`→`UnitLevel`, `CostLabel`→`PlacementPrice`,
`IconImage`→`ItemIcon`, `QtyBadge`→`Amount`. `ItemIconV2` adds an `ItemName` label v1 had nowhere
to put. **`ShinyBadge` is GONE** — `AscensionController` drove it from `view.Shiny`, so **shiny is no
longer marked on an ascension card**: an accepted, recorded regression, not an oversight.

### ⚠ `setText(root, name, …)` NEVER MATCHES `root` ITSELF

It does `root:FindFirstChild(name, true)`, which walks **descendants only**. `UIKit.Hotbar` wrote the
level as `setText(levelFrame, levelFrame.Name, …)`, found nothing, returned silently, and left
`HotbarSlotV2`'s authored placeholder **`"LVL 100"` on screen for every unit in both Places**. Always
pass the SLOT ROOT: `setText(btn, "UnitLevel", …)`. Two lessons worth keeping: an assertion that
checked only `.Visible` passed the bug — **print the TEXT** — and it was invisible in the Game, whose
dev seed genuinely runs three units at MetaLevel 100, identical to the placeholder.

**Three fields have NO DATA SOURCE and render HIDDEN, never invented:** `PlacementPrice` and
`ElementIcons` (proposal `2026-08-16-tower-display-fields-for-uniticon-v2.md`) and `TraitIcon`
(`2026-08-16-trait-icons.md`). `HotbarSlotV2.Placed/MaxPlacement` is a MATCH-runtime number that
nothing feeds yet, hidden in both (its name contains a `/`, so it needs `FindFirstChild`, never dot
notation). `UnitLevel` shows **only** when the entry carries `MetaLevel` or `Level`; a zero is a claim.

### Consumers (six, and one is cross-Place)

`UnitIconV2` has **THREE**: `SummonController` (featured chips), `IndexController` (codex entries)
and `AscensionController` (dupe picker). `ItemIconV2` has **two**: the shared `UIKit.ItemIcon`
controller and `ObtainRewardsController`, which clones the master directly — **its `paintTier`
deliberately handles BOTH shapes**, because it also paints the user's Lobby-local `UnitTemplate`,
which is still v1-shaped and was not migrated. `HotbarSlotV2` has **one**, the shared `UIKit.Hotbar`
— **and that one is what made this adoption cross-Place.**

**Hover: what is actually proven.** `MouseEnter` cannot be fired from tooling. B26 proved that
`paintStroke()` — the function both `MouseEnter` and `MouseLeave` call — toggles `UIHoverStroke` on
and off, and that the stroke is authored `Enabled = false` at rest. In the live Items grid exactly
one card had it on, and that was the **selected** card (`paintStroke` is `hovering or selected`).
The engine-side trigger remains on an open PENDING.

## `UIKit.Motion` — the kit's ONE animation home (B27c; slide added B28)

It exists so a fourth animation dialect is never born. Everything with a curve or a duration in it
belongs here, and `Motion.Tuning` is where the kit's feel is retuned — **never per screen**.

`Tuning`: Quint ease-out · hover 1.07 / 0.26s · press 0.95 / 0.09s · rest 0.30s · idle gradient 9s
at 45° · hover Z lift 5 · **slide in 0.34s / out 0.20s / distance 0.35**.

API: `isolate` · `layoutNode` · `setVisible` · `setLayoutOrder` · `destroy` · `scaleTo` · `lift` ·
`idleGradient` · `paintHoverStroke` · `prepareCard` · **`slideIn` · `slideOut` · `isOpen` ·
`restPosition` · `forgetSlide`**.

### The open/close slide (B28) — three traps handled ONCE

The user's ask: *"I also need animations when opening in closing, Like sliding up, not just popping
visible and invisible."* `slideIn(frame, opts)` / `slideOut(frame, opts)` return the Tween, so a
caller can await `.Completed`. `opts`: `gui` · `direction` (`up` default, `down`/`left`/`right`) ·
`distance` · `time` · `keepEnabled` · `onComplete`.

1. **Enable before you animate.** Every screen toggles `ScreenGui.Enabled`, and a DISABLED ScreenGui
   does not lay out — everything under it reads `AbsoluteSize = 0`. `slideIn` enables FIRST;
   `slideOut` disables only after the tween completes. A screen must therefore call `slideIn`
   *before* it clones its cards, or every card is built against a zero-size parent.
2. **The travel is parent-relative SCALE, never measured pixels.** A measured slide would have to
   wait a frame for `AbsoluteSize` to go non-zero — and "a harness that reports 0 or 0x0 is usually
   the harness" is this project's most repeated false alarm. Scale needs no measurement.
3. **The authored resting Position is canon.** Captured ONCE into the `UIKitRestPosition` attribute
   (UDim2 is a real attribute type, so it is visible in Studio and survives a reload); every tween
   runs to or from that value. No screen coordinate is hardcoded in the module, and `slideOut`
   restores it on completion so a hard `Enabled = true` elsewhere still shows the panel in place.

**Screens ask `Motion.isOpen(main)`, not `gui.Enabled`.** During a close tween the gui is still
Enabled, so an `Enabled`-based toggle reads "open" and closes a second time — swallowing the click
of a player reopening mid-slide. Re-entrancy is a per-frame token: a completion callback holding a
stale token does nothing, which is what stops a late `slideOut` from disabling a gui just reopened.

**Boot teardown must NOT slide.** A controller that hides itself at boot uses a direct
`gui.Enabled = false` (`hideInstant()` in Summon/Index), or the screen flashes on every join.

**`PlayGUI` is deliberately excluded** — it opens behind a `LoadingScreen` veil with a camera
capture, and a slide would fight the veil.

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
- **A new template beside an old one is an ADDITION and does not move any hash.** That is why the V2
  set can sit in the Lobby with drift green. Adoption is what costs: it moves consumers, adds
  manifest entries, retires the v1 rows and must land in BOTH Places in ONE session.
