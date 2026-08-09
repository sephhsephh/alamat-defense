# SYSTEM — Lobby UI (screens)

<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-09 (B4) -->

Split out of `places/lobby/CONTEXT.md` at A5 when that file passed its 150-line cap. **At A7
(2026-08-06) the KIT half moved out to `docs/systems/ui-kit.md`** — the kit is used by both Places
now, so describing it from a Lobby viewpoint had become wrong. This file is the Lobby's SCREENS.
Read `ui-kit.md` first for the components they build on.

Studio is canon for the actual instances and controller code (ADR-0001); this describes what is
there and why.

## `ObtainRewardsGUI` — the reward-reveal surface

Built at **B1 (2026-08-08)**; animated at **B4 (2026-08-09)**. Moved here from
`places/lobby/CONTEXT.md` at B4 — this is a Lobby SCREEN, and CONTEXT.md was over its cap.

**Entry point** (client-side, Lobby-local, matching the `ClientEvents` house pattern):

```lua
RS.ClientEvents.ShowRewards:Fire({ { Id = "Archer", Level = 12 }, { Id = "Gold", Qty = 250 } })
```

A bare string id also works. **First production caller = gacha (B3)**, which passes
`RequestSummon`'s returned views straight through unchanged.

- **ONE grid, MIXED units + items.** Unit cell = this screen's own `RewardsFrame.UnitTemplate`
  (150×150, locked by its own `UISizeConstraint`, adopted as-is per ADR-0007, kept **Lobby-local,
  NOT shared canon**). Anything else = a FRESH clone of shared `Kit.ItemIcon` on every show
  (deliberately not baked in at build time — that is what caused `Kit_ItemHoverCard`'s stale-master
  bug). Kind is inferred from `ItemCatalog` (`Kind == "Tower"` → unit), forceable with `Kind`. An id
  absent from the catalog **still renders** (name falls back to the id, tier Common).
- **Layout:** 5 columns; `cols = min(n, maxCols)` so 3 rewards make a 3-wide frame, not a 5-wide one
  with gaps. Rows 1–3 grow the frame; row 4+ freezes Y at the 3-row height and scrolls with
  `CanvasSize` still covering every row. **Every metric is READ from the instances**
  (`UIGridLayout.CellSize`/`CellPadding`/`FillDirectionMaxCells`, `UIPadding`,
  `RewardsFrame:GetAttribute("MaxVisibleRows")`) — retune spacing in Studio, no code change.
- **Back-to-back grants QUEUE, never merge**, so each reward source stays visually distinct.

### Reveal animation + two-stage click (B4, 2026-08-09 — REVIEWED + APPROVED by AD-UI at B5)

> **Review status:** B4 was written by AD-Gacha inside AD-UI's canon on the user's explicit
> authorisation. AD-UI re-tested every claim independently at B5 (2026-08-09) rather than trusting
> the changelog — stagger, no-reflow, overshoot magnitude, skip, gated close, layout invariance,
> n=1, click-catcher integrity and shared-canon cleanliness **all PASS**. Approved as written; the
> only change was the padding fix below, which was a B1 defect, not a B4 one.


Cells reveal **one at a time** (pop-in, `UIScale` `RevealStartScale` → 1, Back/Out) instead of the
whole grid appearing at once. Then **click 1 = SKIP**, **click 2 = CLOSE**.

- **Skip is NOT dead-period gated; close is.** Skipping only ever shows you *more*, so a stray click
  cannot rob you of a rare pull — but the close click is gated by `InputDeadSeconds` measured **from
  when the reveal FINISHED**, not from when the popup opened. With an animation, "seen" happens at
  the end of the reveal. Letting the animation finish on its own lands in the identical state as a
  skip, because both go through one `finishReveal()`.
- **Tunables are attributes on the ScreenGui** (same philosophy as the layout metrics):
  `RevealStaggerSeconds` (0.08), `RevealPopSeconds` (0.22), `RevealStartScale` (0.60),
  `RevealMaxTotalSeconds` (1.20 — caps the whole stagger so a 20-cell batch compresses instead of
  crawling), plus the existing `InputDeadSeconds` (0.35).
- **Why `UIScale` and not `Size`:** `UIGridLayout` FORCES `CellSize` onto every child, so a `Size`
  tween is overwritten every frame. `UIScale` is the only size animation that survives a grid.
- **It is created on the runtime CLONE, never on a template.** `Kit_ItemIcon` is hashed **shared
  canon** (`5623f4b4`, also used by the Items screen) — adding anything to it would be drift.
  The controller already creates `UIGradient`/`WorldModel`/`Camera` on clones, so this matches its
  own established practice rather than inventing one.
- **Why it pops from the centre:** the `UIScale` goes on the cell's `Main` child after re-anchoring
  it to `(0.5,0.5)` at position `(0.5,0.5)` — geometrically identical coverage (Main is
  `{1,0},{1,0}` at anchor `(0,0)`), but it now grows from the middle instead of the top-left corner.
  **The grid-positioned ROOT is never re-anchored** — that would shift the cell out of its slot.
- **Keep the overshoot small.** `RewardsFrame.ClipsDescendants = true`, so Back/Out from 0.6 (peak
  measured live at **1.0400**) must fit inside the padding. A much lower start scale or a stronger
  easing **will clip** on the outer edges.
- **`UIPadding` is 15px, not the 8px it was built with — and the reason is not decoration.**
  `UnitTemplate.UnitLevel` sits at x `−0.072`, i.e. the level badge **overflows its own 150px cell
  by 10.8px to the left**, and at peak overshoot by 14.2px. With 8px padding the leftmost column's
  badge was permanently cut by **2.8px at rest** and **6.2px during the pop**. 15px clears both
  (measured after: **−4.2px** at rest, **−0.8px** through the reveal — negative means clearance).
  **Do not drop it back below ~15px**, and if `RevealStartScale` is lowered or the easing
  strengthened, re-measure. Found by AD-UI's B5 review; it predated the animation (B1 shipped it)
  and B4 only made it briefly more visible. Fixed on the CONTAINER on purpose — `UnitTemplate` is
  the user's design, adopted as-is under ADR-0007, so it is not the place to fix this.
- **Cells are hidden until their turn, and this does NOT reflow.** `UIGridLayout` skips invisible
  children, but because cells reveal in ascending `LayoutOrder` each one lands in the next free slot
  and the ones already shown never move. Asserted live, not assumed: cell 1 held its
  `AbsolutePosition` across the whole reveal at n=10 and n=20.
- **A `revealToken` guards the queue.** It is bumped on every render, and an in-flight reveal loop
  from a previous batch checks it and bails — so walking the queue quickly can never leave an old
  loop animating the new batch's cells.
- The `ClickToCloseLbl` hint stays hidden until closing is *actually* possible (reveal finished AND
  dead period passed). During the reveal a click skips rather than closes, so showing a close hint
  then would be a lie.
- **Studio harness:** the `DevDismiss` attribute routes through the **same `advance()`** a real click
  does, so it skips while revealing and closes afterwards, dead-period check included
  (`MouseButton1` cannot be fired from tooling). Left OFF.

**Verified live at B4** (n=1/3/6/10/15/20): stagger observed one cell at a time (`0→1→…→20`); cell 1
never moved; skip mid-reveal at 2 visible → all 15 instantly at full scale and **still open**; close
during the dead period **refused**; close after it worked; queue animates each batch; and the layout
numbers are **identical to B1's** — n=10 `798×324`, n=15 `798×482`, n=20 `806×482` canvas 640 with
the last cell's bottom at 599 inside a frame bottom of 607. Drift stayed **23/23 GREEN**.

## Screens

- **Hotbar** (`StarterGui.Hotbar.HotbarController`) — the shared `UIKit.Hotbar` (see `ui-kit.md`).
  Lobby action: click or key 1-6 fires `ClientEvents.OpenUnitsWithUuid` and `UnitsController`
  opens the Units screen on that unit. Verified A7: 6 slots, 3 filled with correct tier colours
  (Archer/Common `(205,205,215)`, Babaylan/Epic `(168,70,235)`, Farm/Rare `(55,130,255)`), slots
  4/5/6 locked at Lv 5/20/50, 0 scripts in any viewport.

- **Units screen** (`StarterGui.UnitsGUI.UnitsController`) — reads the `GetUnitViews` view-model,
  **one card per uuid** (`UnitsContainer.UnitCard_<uuid>`). Per card: `Name`+`Tier` from
  `ItemCatalog`, tier-coloured border **and** BG from the shared `TierConfig`, per-stat GRADE
  letters, real `Level`/`XP` on the preview level bar, and `Favorited`/`Equipped` driving the sort
  (equipped > favourited > tier high→low > name). Hover = white border + scale +
  `UnitPreviewTemplate` popup; click → `SelectedUnitFrame`. Live SearchBar. FILTERS button → the
  shared `UIKit.FilterPanel` (tier + equipped/favourited/locked).

  - **A5:** stat rows are dual-slot — each of `Stats.BaseStatsFrame.{DMG,RNG,SPA}` has a `Grade`
    TextLabel for the letter and a `TextLabel` for the number. Rows WITHOUT a `Grade` child (the
    hover preview's Attack/Element/MaxPlacement) keep the old single-label behaviour.
  - **A6:** the number slot is filled from the shared `UnitStatsCatalog.Get(towerId)` (ADR-0003) —
    resolver-PRODUCED base values, **SPA already inverted**, not raw `BaseStats`. `formatStat`
    trims decimals (`15`, `1.4`, `2.5`) and renders `--` for a missing value, so Farm (no DMG/SPA)
    or an unknown towerId **never prints "nil"**. Verified live A7: `20 / 22 / 2.5` with grades.
  - **Read this before "fixing" a bug report:** the number is **per-TOWER, not per-unit**. Two
    instances of one tower show the SAME number while their GRADE letters differ — the grade comes
    from that unit's roll, the number is the catalog's mid-roll reference (tier 1 / ML 1 / no
    trait / asc 0). ADR-0003's accepted trade; per-unit numbers would need the Min/Max ranges
    promoted too, which ADR-0003 deliberately rejected.
  - **The cards are NOT `Kit.UnitIcon` clones — and that is now a SETTLED decision (ADR-0007).**
    They are a screen-local design (`PlacementPrice` + a level `TextLabel`); the kit's
    `NameLabel`/`LevelBadge`/`CostLabel`/`ShinyBadge` are absent. So the Units screen goes "through
    the kit" for its **FilterPanel** and the shared **TierConfig/StatGradeConfig/UnitStatsCatalog**,
    but not for its cards. A7 flagged this as the last §8 PARTIAL; the user decided 2026-08-06 to
    **PARK it**: §8 reads pragmatically and this screen **PASSES**, `Kit_UnitIcon` is neither
    adopted nor deleted, and the unit-card question moves to Phase B. **Do not "fix" this by
    rebuilding the cards on `Kit.UnitIcon`.** If a shared card is ever built, THIS card is the one
    lifted into the kit — the user's design is the source of truth.
  - Still open: real per-unit models (everything uses `UnitModels.Placeholder`) and functional
    action buttons (animation-only today).

- **Items screen** (`StarterGui.ItemsGUI.ItemsController`, A5) — opens from **HUD.Inventory**.
  Chrome cloned from the Units screen so the design matches. The LIST is every `ItemCatalog` entry
  with `Kind = "Item"|"Currency"` (a compendium of what exists); the COUNTS come from
  `GetUnitViews.Items` (+ `Currencies` for Gold/Silver). Cards are genuine `UIKit.ItemIcon` clones
  — verified A7: 5 cards, all `IconImage`+`QtyBadge`, **0 ViewportFrames**, Gold showing `x120`.
  Hover pops `HoverPreview` (the kit's `ItemHoverCard`) to the RIGHT; click fills
  `SelectedItemFrame`. Search + `UIKit.FilterPanel` (tier / kind / owned-only). Sort: owned first,
  then tier high→low, then name.
  **Every ITEM count reads 0** and that is correct — `Data.Items` has no writer in either Place.
  (A drop path exists in the Game's `RewardCalculator` → `AddItem`, but it only fires on a
  **Victory** roll against the stage drop table, which has never landed. Confirmed empty at A7.)

- **Collection screen** (`StarterGui.CollectionScreen.Controller`, A5 rebuild) — was script-built,
  now REAL instances (`Panel.Grid.CardTemplate`) filled from `GetUnitViews`: one card per uuid with
  tier border/BG, `Lv N`, the three GRADE letters, and a status line (EQUIPPED / FAVOURITED /
  LOCKED / ASC n). Meta line shows unit count + Gold/Silver + account level. This removed the last
  reader of `GetCollection`'s compat fields. **A7 note:** its controller references **no kit
  component at all** — it is entirely screen-local. Fine today; worth folding into the kit if a
  third card-grid screen ever appears.

- **StageSelect / Party / Return / StarterChoice** — still legacy script-built screens, on the
  "convert to instance trees when next touched" list (rule 2026-07-18). `ReturnScreen` builds its
  banner only when a `MatchReturn` payload is present, so it legitimately has **0 GuiObjects** on a
  normal boot — that is not a fault.

- **CurrencyBar** (`StarterGui.HUD.Top.CurrencyBar` + controller, A6) — **Lobby-local on purpose**,
  not shared: a single-Place widget under drift control costs a cross-Place sync forever for
  something the Game never renders. Refresh is deliberately **one-shot on join** — nothing in the
  Lobby SPENDS Gold or Silver yet, so there is no change event to subscribe to. Wire a RemoteEvent
  when a shop or gacha lands; **do not poll.** Amounts abbreviate (`12.3K`, `1.2M`). Promote it
  into the Kit the day the Game place wants one.

- **HUD buttons** (`HUD.Left.Buttons.{Play,Units,Inventory,Areas,Summon,Store}`) tagged
  `UIKitButton` + animated; `Frame.BorderDesignInside` hidden; hover = white stroke (no thicken).
  (The sixth button is `Store`, not `Shop`.) 34 tagged buttons attach at boot.

## Studio harnesses (all left OFF)

`UnitsGUI` / `ItemsGUI` / `CollectionScreen` each honour a **`DevAutoOpen` attribute** — set it
true to open that screen on boot with no HUD click, so a Play session can be verified without
synthetic input (`VirtualInputManager` is blocked for tooling). Same pattern as
`DevSimulateReturn` (MatchReturnService) and `DevSimulateFirstJoin` (StarterChoiceService).

## Server read path

**`GetUnitViews` is the SINGLE profile read path** for every Lobby screen since A7 retired
`GetCollection` (ADR-0004). It is load-bearing: additive changes are free, a breaking one needs
contract treatment. Clients never read profiles directly — the server decides what a unit "is",
the client only renders it. See `places/lobby/CONTEXT.md` for the field list.
