# Hotbar + the 9-tier palette (B77)

**Owner:** AD-UI. **Scope:** SHARED (`UIKit.Hotbar`, `TierConfig`) + one authored ScreenGui per Place.
No schema change, no new remote.

## The tiers are the user's, and they live in TierConfig

The user authored nine gradients as `HotbarSlot1..9.InnerStroke.UIGradient` in the new hotbar GUI and
asked for those to BE the tier colours everywhere. `TierConfig` now carries, per tier:

- `Stops` — the authored keypoints, **times included** (`{ Time, Color3 }`)
- `Rotation` — the authored gradient angle (45 for the five top tiers, 0 for the flat four)
- `Colors` — DERIVED from `Stops` at load (duplicates collapsed), so every existing caller
  (`colorSequence`, `BrightestColor`, `HoverStrokePaint`, `seamlessSequence`, `GetColor`) is unchanged.

Order, low → high: **Common, Uncommon, Rare, Epic, Legendary, Mythic, Limited, Secret, Alamat.**

| Tier | Rot | Stops (RGB) |
| --- | --- | --- |
| Common | 0 | 167,167,167 (flat) |
| Uncommon | 0 | 0,255,127 (flat) |
| Rare | 0 | 0,0,127 → 0,85,255 |
| Epic | 0 | 85,0,255 (flat) |
| Legendary | 45 | 255,255,0 → .50 255,170,0 → 255,255,127 |
| Mythic | 45 | 0,0,127 → .51 85,170,255 → 170,85,255 |
| Limited | 45 | 170,0,127 → .46 170,255,255 → 85,0,127 |
| Secret | 45 | 170,0,0 → .50 255,85,0 → 85,0,0 |
| Alamat | 45 | 255,255,0 → .48 170,0,255 → 255,170,0 |

**Retired:** `Exclusive` and `Bathala` (no banner weight, no catalogued unit, no code reference outside
comments). **Retired rule:** B27's "every tier gets a derived darker second colour" — the user authored
four tiers FLAT on purpose, and auto-darkening would overwrite a palette they just tuned. `Darken` is
still exported for UI that wants a shadow.

`SellValueByTier` gained Uncommon 15, Limited 700, Alamat 2500 (the ~x2.5-per-tier curve).
`TierConfig.GradientFor(tier)` returns `(ColorSequence, rotation)` — the one call that paints a slot.

## The hotbar

The DESIGN is the user's authored ScreenGui (`Hotbar.HotbarFrame.Slots.HotbarSlot1..6` +
`UnitHoverPreviewTemplate`), pasted into each Place; the BEHAVIOUR stays the shared `UIKit.Hotbar`,
which grew a **V3 path** recognised by the container holding `HotbarSlot1`. **Both Places run V3 as of B77.** The old V2 kit-clone path is still in the file but nothing reaches
it any more (the dispatch takes the V3 branch immediately); removing it, and the kit templates it
used, is a clean-up pass of its own.

⚠ **A pasted ScreenGui brings its scripts with it.** The Lobby's copy arrived carrying the GAME's
`HotbarController`, which requires `PlacementController` and waits on `Remotes.Match.LoadoutAssigned`
— neither exists in the Lobby, so it would have hung on a WaitForChild with no error. Each Place
keeps its own controller: the Game starts placement, the Lobby opens the Units screen on that unit.

Per slot, filled by the kit:

| Node | Filled with |
| --- | --- |
| `InnerStroke.UIGradient` | the unit's tier, via `TierConfig.GradientFor` (stops AND rotation) |
| `ViewportFrame` | the tower's display model (scripts stripped) |
| `BottomInfoFrame.UnitNameLabel` / `.TierLabel` / `.TraitIcon` | name, TIER (own gradient), trait icon (hidden when none) |
| `UnitLevel` | "Lv. N" — on a LOCKED slot, the level it opens at |
| `DeploymentPriceLabel` | the REAL cost from `UnitStatsCatalog.GetCost`, ₱ with separators |
| `Overlay` | the dim: locked 0.25, empty 0.55, filled clear |

**Hover (user's spec):** the InnerStroke gradient tweens smoothly to WHITE and back. A ColorSequence
cannot be tweened, so a per-slot `NumberValue` is tweened and every keypoint is lerped toward white on
its `Changed` — one tween per slot, no RunService loop.

**Hover preview** (`UnitHoverPreviewTemplate`): name (+ `(A2)` when ascended), tier, level, DMG/SPA/RNG
with BASE values (`UnitStatsCatalog`) and this unit's roll GRADES (`StatGradeConfig.GradeForRoll`),
plus Trait / Element / Shiny chips. B29's stale-hide guard is kept: a hide must still own the preview,
because `MouseLeave(previous)` is not guaranteed to arrive before `MouseEnter(next)`.

**Element is a known gap:** there is no element system yet, so the chip reads "None". It already reads
`entry.Element`, so it fills itself the day that field exists (user: "I'm adding elements soon").

## Gotchas paid for live

- **`Active = false` on the authored buttons.** A GuiButton that is not Active NEVER fires `Activated`,
  so clicking a slot did nothing while keys 1-6 still worked (they come from UserInputService and
  never touch the button). V3 forces `Active = true` on every slot it wires and also connects
  `MouseButton1Click`, debounced 0.05s so a healthy button firing both does not double-start.
- **The preview's tier colour belongs to `UnitFrame.UIStroke`** (user). The card's own outer strokes
  are part of the design; painting them tinted the whole card.
- **Viewport cameras are not the kit's to touch** (user). `showModelKeepCamera` swaps the model and
  nothing else -- no Camera is created, moved or assigned. The authored placeholder's pivot is stored
  on the ViewportFrame as the `HotbarModelPivot` attribute the first time it is cleared, and every
  model after it is pivoted there, so whatever framing is set up keeps pointing at the right spot.
- **⚠ A `Camera` inside `StarterGui` does NOT reach `PlayerGui` — Cameras do not replicate.** The user's
  `HotbarSlot1.ViewportFrame.VPCamera` is simply absent at runtime, which is why every slot read
  `CurrentCamera = nil` and rendered with Roblox's default framing. The framing therefore travels as
  ATTRIBUTES, which do replicate and survive the paste into the other Place:
  **`HotbarCamCFrame`, `HotbarCamFOV` and `HotbarModelPivot` on the `Slots` frame**, baked from the
  authored camera and from the model slot 1 is framed on. The anchor is part of the bake, not an
  afterthought: a shared camera with each slot standing its model on its OWN old placeholder's pivot
  put five of six models ~59 studs out of frame.
  `ensureCamera` builds a Camera from them for any viewport that has none, and never touches one that
  does. **Re-bake those two attributes after moving the authored camera** — nothing else reads it.
  Move the authored camera (or the model it is framed on) and re-bake all three; nothing else reads them.

- The Game's controller used to clear a slot's dim for any slot holding an entry — which wiped the
  LOCK dim off slots 5-6, because the Lobby's auto-loadout fallback can hand a player more units than
  they have unlocked slots (B43's standing note). It now skips locked slots.
- The old dimming poked `Main.BackgroundTransparency` and a `BG` ImageLabel; neither exists on the new
  slot. It goes through `handle.setOverlay` now, which also closes the user's own TODO in the old code
  ("the background transparency becomes 0 on start, ruining the visual") — the overlay starts CLEAR.
- The nine authored slots were a PALETTE, not nine usable slots: slots 7-9 were deleted and the row
  draws `LoadoutConfig.MaxSlots` (6). Anything past MaxSlots is hidden rather than drawn.

## Proven live (Game Place, real clicks)

**Lobby:** Farm/RARE ₱150, Babaylan/EPIC ₱300, Meteor/LEGENDARY ₱300 with the right gradients and
rotations, locked slots showing their unlock level, hover preview reading Babaylan EPIC Lv.100
DMG 20 (D) / SPA 2.5 (A) / RNG 22 (B) with its Godly chip, click opens the Units screen. `RS.UnitModels`
there holds only `Placeholder` (pre-existing), so Lobby viewports draw the placeholder rig.

**Game:** 6 slots painted from the authored design; Archer/COMMON ₱100, Necromancer/MYTHIC ₱400,
Warchief/LEGENDARY ₱350, Farm/RARE ₱150 with the exact authored gradients (Common flat grey rot 0,
Mythic rot 45 three-stop…); slots 5-6 LOCKED at 0.25 showing "Lv. 20"/"Lv. 50"; hover turned slot 3's
gradient fully white; the preview showed Necromancer MYTHIC Lv.20 DMG 28 (D) / SPA 1.1 (B) / RNG 22 (D)
and Archer with its "Godly" trait chip; clicking slot 1 started placement (ghost + controls up).
