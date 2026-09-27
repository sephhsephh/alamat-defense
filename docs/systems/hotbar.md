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
---

## B79 — the slot is never still

**The viewports move now.** Every slot (and the hover preview) calls `UIKit.UnitCard.playIdle` on the
model it shows. The rigs stood still because none carried an `IdleAnim`, so nothing played; a rig
with no `IdleAnim` now plays `UnitCard.DefaultIdleAnim` (`rbxassetid://507766666`).
⚠ **CORRECTED B81:** B79 also added an `Animator:StepAnimations` loop, believing a ViewportFrame never
advances an Animator. It does, for a rig inside a `WorldModel` — and `StepAnimations` is plugin-only,
so it threw every frame in a real client. Removed (`UIKitUnitCard` `51f55122 -> 20f03a39`).

**⚠ The rigs must exist in BOTH Places (user rule).** The Lobby reads `RS.UnitModels`, the Game reads
`RS.TowerModels`. A unit present in one and missing in the other previews as `Placeholder` on that
side — which is exactly what every Lobby slot did until the user copied the real models across.

**The tier stroke is alive, and deliberately out of step** (user: "animate the uistroke with tier
colors, like rotating, at random speed so they dont look that synched. and unique animations of
colors"). At attach time each slot draws its own:

| | range | what it does |
| --- | --- | --- |
| Spin | 6–20 °/s, random direction | rotates the InnerStroke gradient |
| Scroll | 0.06–0.22 /s | **multi-stop tiers only** — travels the colours around the stroke |
| Breathe | 0.35–0.8 Hz, random phase, depth 0.22 | **flat tiers only** — lifts the colour toward white and back |

A flat one-colour tier scrolls invisibly, which is why it breathes instead; the choice is made from
the tier's own gradient, not from a list of tier names. **One `RenderStepped` connection drives all
six slots** (six would be six schedulers for one clock) and `handle.destroy` disconnects it.
**A hovered slot keeps spinning but stops writing colour** — the hover tween owns `Gradient.Color`
while the pointer is on it, and two writers on one property is a fight you see as flicker.

**Proven live (Lobby):** slot 1 Mage rot 177.0→187.5 with offset 0.713→0.991 and a limb travelling
0.3044 studs in 1.5s; slot 3 Meteor rotating the OTHER way (176.6→163.1); slot 2 Knight on its own
authored idle (`rbxassetid://125610139973073`), flat COMMON tier at offset 0.000 and breathing.

**Proven live (Game):** slot 1 Archer rot 304.7→317.9 while slot 2 Necromancer ran the OTHER way (108.6→95.8) and slot 3 Knight faster again (318.7→301.4) — three rates, two directions, in one 1.5s sample; Necromancer (multi-stop MYTHIC) scrolled its offset 0.605→0.328 while the two flat tiers held 0.000 and breathed; Archer's rig moved 0.087 studs in that window, Knight's barely at all on its own subtle authored idle.

## The selected slot lifts (B85, GAME only)

User: "when a slot is selected, the selected card will slight shift upwards, add animation when a
hotbar is selected and deselected."

The selected card rises **0.14 × its own height** (≈23px at 1080p), on `Back/Out` over 0.18s so it
overshoots a touch and settles, and drops back on `Quad/Out` over 0.12s — a little faster down than
up. It also takes `ZIndex + 1` while lifted, so it draws over its neighbours and over the "YOUR
UNITS" banner, and the authored ZIndex is restored on the way down. Nothing clips it: neither
`HotbarFrame`, `Slots` nor the slot itself has `ClipsDescendants` set.

It hangs off `PlacementController.StateChanged` — the same signal the B83 placed-unit counter uses —
so click, the 1–6 keys and every route out of placement all move it, and the counter and the lift can
never disagree about which slot is armed.

### ⚠ The `UIListLayout` owns slot positions, so the lift needs a bake first

**Writing `Position` on a slot does nothing while the authored `UIListLayout` is parented, and nor
does writing `AnchorPoint`** — both measured live, the slot stayed at the same `AbsolutePosition`
through each. A `UIScale` *does* grow the card, but the layout then reflows the row and shoves the
neighbours sideways (10px, measured), which is not a lift.

So `HotbarController.freeSlots()` **bakes the layout's own result** rather than replacing it:

1. wait until the row has actually been laid out (`AbsoluteSize > 0` — it is 0 for a frame or two at
   boot, and a GUI that boots mid-match must still get its turn, so it retries),
2. read each slot's laid-out centre and convert it to a **scale** position inside `Slots`,
3. **detach** the `UIListLayout` (kept in a local, never destroyed),
4. write the scale positions onto the slots — which only sticks once step 3 has happened.

At rest the row is **pixel-identical** to what the layout produced, and it stays responsive because
the layout was scale-based end to end (slots `0.15` wide, padding `0.01`): a scale position is
exactly what it was computing. Proven live — the bake produced `0.10 / 0.26 / 0.42 / 0.58 / 0.74 /
0.90`, and slots 2 and 3 landed on `672.72` and `818.64`, the same pixels they occupied before.

**The authored `UIListLayout` in StarterGui is never touched** — only the live PlayerGui copy's is
detached — so the design in Studio is still the thing that ships: change the padding or a slot's
width there and the next bake reads the new result. The lift *distance* is the one measured value,
so a resize recomputes that and nothing else; re-baking positions on resize would be wrong, because
a slot that happened to be lifted would bake its lifted position as its resting one.

**The Lobby does not get this** — it has no placement, so nothing ever selects a slot there, and its
`UIListLayout` is left alone. This is Game-local controller code; the shared `UIKit.Hotbar` is
untouched (it only ever *reads* `slotBtn.AbsolutePosition`, to park the hover preview — which means
the preview follows a lifted card for free).

**Proven live:** clicking the Archer lifted slot 1 by 23.1px to `ZIndex 2` with its counter showing a
maxed red `1/1`, while slots 2–6 stayed at `845.5`; the card visibly cleared the banner in a
screenshot, and everything returned to `845.5 / ZIndex 1` when placement ended.


## The framing is shared canon now (B87)

User: *"change the camera position of viewport frames to match the closeness and orientation of the
ones in hotbar. not a wholebody view."*

The hotbar's hand-posed camera is baked as `HotbarCamCFrame` / `HotbarCamFOV` / `HotbarModelPivot` on
the `Slots` frame (because a `Camera` inside `StarterGui` does not replicate — that story is above).
B87 lifted the reusable part of that pose into **`UIKit.UnitCard.Framing`**, so every rig preview in
both Places frames the same way:

```
Relative = HotbarModelPivot:ToObjectSpace(HotbarCamCFrame)   -- 1.16 studs out, 0.70 up
FieldOfView = 70
```

`UnitCard.viewport` pivots the model to an anchor and hangs the camera off it by `Relative` — exactly
what the hotbar's own `showModelKeepCamera` does. The old framing computed a distance that fitted the
whole bounding box, which is a full-body shot by construction.

⚠ **It is a fixed pose, not a fit.** A rig far from standard R15 proportions will frame differently.
The fix is the same one the hotbar already needs: re-pose the authored camera, re-bake, and paste the
new components into `UnitCard.Framing`.

**The hotbar itself is unaffected** — it keeps using its own baked camera directly and never called
`UnitCard.viewport`.

⚠ **Roblox's FOV is VERTICAL**, so a viewport's aspect ratio still changes how the same camera reads:
a wide frame shows the same unit with more empty room beside it. Match the slot's 0.83 aspect if you
want a card to look like a hotbar slot.
