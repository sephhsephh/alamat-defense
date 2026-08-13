# SYSTEM — Lobby UI (screens)

<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-09 (B10) -->

Split out of `places/lobby/CONTEXT.md` at A5; the KIT half moved to `docs/systems/ui-kit.md` at A7.
This file is the Lobby's SCREENS — read `ui-kit.md` first for the components they build on. Studio
is canon for the instances and controller code (ADR-0001); this describes what is there and why.

## `IndexScreen` — the unit index / codex (B8, 2026-08-09)

Blueprint Phase B task **"B5 Index/Codex"**: *"iterate ItemCatalog Towers → obtained silhouettes
(own any instance), source text, exact per-banner rates table (computed from configs, not
hand-written)."* `StarterGui.IndexScreen` + `IndexController`. All four are DERIVED:

| On screen | Derived from |
| --- | --- |
| which units exist | `ItemCatalog.Entries` where `Kind == "Tower"` |
| obtained? | `GetUnitViews` — the SINGLE profile read path (ADR-0004), own ANY instance |
| source text | `BannerRegistry.ResolvePool()` across `BannerRegistry.List()` |
| drop rates | `cfg.Rates` × the in-tier pick weight, per banner |

Catalog a tower or ship a banner file and this screen updates itself. No code change.

**The rate maths is the real deliverable** — a specific unit on a specific banner is TWO rolls:

```
P(unit) = (tierWeight / totalTierWeight) × (unitWeight / totalWeightInTier)
```

`unitWeight` is `Featured.Boost` for a featured id, else `1` — which is why a featured unit's number
**moves between rotations** and the row is tagged `★ featured` rather than quietly showing a figure
that will be wrong in an hour. **Pity is deliberately NOT folded in**: it is a floor on tier across
many pulls, not a per-pull probability, and blending them is honest about neither.

**Honesty rules — the point of a codex.** A tower in **no** pool says *"Not currently obtainable"*
(`0%` would imply merely rare). A banner that cannot be pulled right now **still lists its rates**,
dimmed and tagged with `BlockedReason` — hiding it would misrepresent the odds when it opens.
`Secret`/`Exclusive`/`Bathala` have no catalogued towers so produce **no entries at all**. Rates use
`SummonController`'s "don't round a rare tier into a lie" formatting, so Secret's 0.005% never
prints as 0.01%.

**Entries are clones of the shared `Kit.UnitIcon`** (invariant 2). **This screen is its second real
consumer and is what un-parked it — ADR-0009.** The silhouette is one property,
`ViewportFrame.ImageColor3` → black: no second template, no model mutation. Still no
`UIKit.UnitIcon` controller; entries are cloned and filled locally.

- **Entry point is an event: `RS.ClientEvents.OpenIndex:Fire()`.** The `RATES / INDEX` button on
  `SummonScreen.Main.Panel` fires it and has no other privilege, so an NPC or HUD button can open it
  later with no change here. **`IndexController` wires that button itself** — the same reach-across
  `SummonController` uses for the HUD's Summon button — which is why **B8 changed no AD-UI
  controller code**; only a new real instance appeared in their screen (user-authorised).
- `DisplayOrder = 60`: above `SummonScreen` (50), below `ObtainRewardsGUI` (100).
- **Harness:** `DevFakeUnobtained` forces one unit unowned so the **silhouette branch can be tested
  on a profile that owns everything** (same category as `DevSimulateFirstJoin`). See the harness
  section at the bottom for the rest.
- Plain but functional real-instance tree, **for the user to restyle**; the controller reads its
  metrics off the instances.

## `SummonScreen` — the banner carousel (B6, 2026-08-09)

Blueprint Phase B task **"B3 summon UI + RewardPopup wiring"**. `StarterGui.SummonScreen` +
`SummonController`. The engine underneath it is AD-Gacha's — see `docs/systems/gacha.md`.

**It is config-driven, not hand-written.** Everything on screen derives from
`RS.Configs.Banners` + `RS.Configs.Gacha`:

| On screen | Derived from |
| --- | --- |
| which banners exist, and their order | `BannerRegistry.List()` (auto-scans its own folder) |
| the featured units this rotation | `BannerRegistry.FeaturedFor(cfg)` — clock + config only |
| open / closed | `BannerRegistry.IsOpen(cfg)` |
| the rates table | `cfg.Rates`, normalised — **never typed out** |
| how many pull buttons exist | `GachaConfig.AllowedPullCounts` |

Drop in a banner file and it appears. Add `100` to `AllowedPullCounts` and a third button appears.
Neither needs a code change. `BannerRegistry` lives in ReplicatedStorage for exactly this (its own
header says so) — the client deriving the same featured set as the server is **not** a trust
problem, because the server re-derives everything at pull time. This screen's entire authority is
"a banner id and a pull count".

- **ENTRY POINT IS AN EVENT, NOT A CALL: `RS.ClientEvents.OpenSummon:Fire()`.** The HUD's `Summon`
  button fires it and has no other privilege — **which is what makes the blueprint's NPC a later
  drop-in**: give a model a `ProximityPrompt` and fire the same event, no change here.
- **The reveal is not ours.** `RequestSummon` is a RemoteFunction that RETURNS the granted views;
  the controller fires `ClientEvents.ShowRewards` with `result.Rewards` **unchanged** and touches
  nothing inside `ObtainRewardsGUI`. x10 = ONE call, ONE reveal with 10 entries.
- **Featured chips are clones of the SHARED `Kit.UnitIcon`** (invariant 2) — its FIRST real
  consumer; B8's index was the second, and ADR-0009 then adopted it. Cloned and filled locally, no
  controller. Chip size reads `FeaturedRow`'s `ChipWidth`/`ChipHeight` attributes.
- **Templates** (real, editable, `Visible = false`): `BannerCardTemplate` (with its own
  `RateRowTemplate`, `FeaturedRow`, `ClosedOverlay`) and `PullButtonTemplate`.
- **Balance** comes from `GetUnitViews` (the SINGLE read path, ADR-0004 — no second path for a
  currency number), then from `result.Currencies` after a pull, so no extra round trip.
- **Refusals are surfaced, not swallowed.** Server reason codes map to player-readable text;
  an UNKNOWN code prints the raw code rather than a friendly lie, so a new server reason is
  visible instead of "failed". Non-`Standard` banners and closed windows show `ClosedOverlay`
  rather than a dead button.
- Authored as a plain but functional real-instance tree, **for the user to restyle**; the controller
  reads its metrics off the instances. Harness hooks are listed at the bottom of this file.

**Known gap:** the HUD `CurrencyBar` does not refresh after a summon, so it shows stale Gold (the
SummonScreen's own balance IS correct). Wants a `CurrencyChanged` event — noted in `STATE.md`.

## `AscensionScreen` — NPC-opened (B11, ADR-0010)

Blueprint C3 put ascension in the Units detail pane and B9 built it there; **B11 moved it to its own
screen, reachable only from `Workspace.Lobby.NPC_Ascension`'s ProximityPrompt** — the Lobby's first
NPC. That makes Phase C consistent: the blueprint already specifies "NPC → UI" for C1 and C2.
It owns its own Mythic+ picker, so it needs nothing from the Units screen. Full detail:
`docs/systems/ascension.md`. `DisplayOrder 70`; entry point `ClientEvents.OpenAscension`.

## `ObtainRewardsGUI` — the reward-reveal surface

Built at **B1 (2026-08-08)**; animated at **B4 (2026-08-09)**.
**Entry point** (client-side, matching the `ClientEvents` house pattern):
`RS.ClientEvents.ShowRewards:Fire({ { Id = "Archer", Level = 12 }, { Id = "Gold", Qty = 250 } })` —
a bare string id also works. **First production caller = gacha (B3)**, which passes
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

> **Review status:** written by AD-Gacha inside AD-UI's canon on the user's authorisation; AD-UI
> re-tested every claim independently at B5 rather than trusting the changelog — **all PASS**. The
> only change was the padding fix below, which was a B1 defect, not a B4 one.

Cells reveal **one at a time** (pop-in, `UIScale` `RevealStartScale` → 1, Back/Out). Then
**click 1 = SKIP**, **click 2 = CLOSE**.

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
  canon** — adding anything to it would be drift. The controller already creates
  `UIGradient`/`WorldModel`/`Camera` on clones, so this matches its own practice.
- **Why it pops from the centre:** the `UIScale` goes on the cell's `Main` child after re-anchoring
  it to `(0.5,0.5)` at `(0.5,0.5)` — identical coverage, but it grows from the middle. **The
  grid-positioned ROOT is never re-anchored** — that would shift the cell out of its slot.
- **Keep the overshoot small.** `RewardsFrame.ClipsDescendants = true`, so Back/Out from 0.6 (peak
  measured live at **1.0400**) must fit inside the padding. A much lower start scale or a stronger
  easing **will clip** on the outer edges.
- **`UIPadding` is 15px, not the 8px it was built with — and the reason is not decoration.**
  `UnitTemplate.UnitLevel` overflows its own 150px cell by **10.8px to the left** (14.2px at peak
  overshoot), so at 8px the leftmost badge was permanently clipped. **Do not drop below ~15px**, and
  re-measure if `RevealStartScale` is lowered. Found by AD-UI's B5 review; it predated the animation.
  Fixed on the CONTAINER on purpose — `UnitTemplate` is the user's design, adopted under ADR-0007.
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

**Verified live at B4** (n=1/3/6/10/15/20): one-at-a-time stagger, cell 1 never moved, mid-reveal
skip → all instantly full-scale and still open, close refused during the dead period and accepted
after, queue animates each batch, layout numbers identical to B1's. Drift stayed 23/23 GREEN.

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

  - **B10 — EQUIPPING WORKS FROM THE UI AT LAST.** `LoadoutService`/`SetLoadoutSlot` shipped
    2026-08-06 and A7 proved the chain live, but only through a test harness — `UN/EquipButton` was
    referenced by no script, so **a player could not equip at all** for three days. Now wired: the
    button reads EQUIP / UNEQUIP / LOADOUT FULL, and a change re-runs `loadUnits()` and fires
    **`ClientEvents.LoadoutChanged`**, which `HotbarController` listens to.
    - **`Data.Loadout` must stay DENSE** — it is a schema-v2 `{ string }` the match launcher reads.
      Unequipping the middle slot makes the list CLOSE UP; re-equipping appends at the end. Never
      write a hole, and do not "fix" the left-to-right fill.
    - **Equipping into a full loadout is refused client-side**, not sent. `LoadoutService` would
      clamp the insert and silently drop whoever holds the last slot — that clamp is a dense-list
      SAFETY rail, not a designed swap. Explicit unequip first; no server behaviour was changed.
      (A same-FAMILY swap is exempt — it does not grow the list, so it is allowed at the cap.)
    - **B11 — ONE UNIT PER FAMILY.** Equipping a unit whose family is already equipped **REPLACES**
      the incumbent in its slot. Families group a base tower with its future evolved form
      (`Warchief` / `Warchief(Warlord)`) via `RS.Configs.Meta.UnitFamilyConfig`. Enforced
      SERVER-side in `LoadoutService`; the response carries `ReplacedUuid` so the UI can say a unit
      was swapped out instead of the player noticing it vanished.
    - **B11 — the button is GREEN for EQUIP, RED for UNEQUIP.** Both the gradient and the stroke are
      set on every refresh (never toggled), so it cannot strand on the wrong colour. Green runs
      **dark first**: `0 = rgb(0,62,0)` → `1 = rgb(0,170,0)`; red keeps its designed
      `rgb(170,0,0)` → `rgb(62,0,0)`.
    - Harness: `DevEquip` (a uuid) runs the same `doEquipToggle()` a press runs.
  - **A5/A6:** stat rows are dual-slot — `Stats.BaseStatsFrame.{DMG,RNG,SPA}` each carry a `Grade`
    label for the letter and a `TextLabel` for the number (rows without `Grade` keep the old
    single-label behaviour). The number comes from shared `UnitStatsCatalog.Get(towerId)`
    (ADR-0003) — resolver-PRODUCED, **SPA already inverted**. `formatStat` trims decimals and
    renders `--` for a missing value, so Farm or an unknown towerId **never prints "nil"**.
  - **Read this before "fixing" a bug report:** the number is **per-TOWER, not per-unit**. Two
    instances of one tower show the SAME number while their GRADE letters differ — the grade comes
    from that unit's roll, the number is the catalog's mid-roll reference (tier 1 / ML 1 / no
    trait / asc 0). ADR-0003's accepted trade; per-unit numbers would need the Min/Max ranges
    promoted too, which ADR-0003 deliberately rejected.
  - **The cards are NOT `Kit.UnitIcon` clones — SETTLED (ADR-0007, and ADR-0009 which adopted the
    kit icon for OTHER screens without touching this).** They are a screen-local design; the Units
    screen goes "through the kit" for its **FilterPanel** and the shared
    **TierConfig/StatGradeConfig/UnitStatsCatalog**, not for its cards. **Do not "fix" this by
    rebuilding them on `Kit.UnitIcon`** — if a shared unit CARD is ever built, THIS card is the one
    lifted into the kit; the user's design is the source of truth.
  - Still open: real per-unit models (everything uses `UnitModels.Placeholder`), and the
    `Upgrade` / `Lock` / `ViewPassives` buttons are still animation-only (equip works as of B10).
  - **Ascension is NO LONGER here.** B9 put an `AscensionPanel` in `SelectedUnitFrame`; **B11 moved
    it out** to its own NPC-opened `AscensionScreen` (ADR-0010). Do not put a reroll or feeding pane
    back into this frame either — copy the NPC pattern. See `docs/systems/ascension.md`.

- **Items screen** (`StarterGui.ItemsGUI.ItemsController`, A5) — opens from **HUD.Inventory**.
  Chrome cloned from the Units screen so the design matches. The LIST is every `ItemCatalog` entry
  with `Kind = "Item"|"Currency"` (a compendium of what exists); the COUNTS come from
  `GetUnitViews.Items` (+ `Currencies` for Gold/Silver). Cards are genuine `UIKit.ItemIcon` clones
  — verified A7: 5 cards, all `IconImage`+`QtyBadge`, **0 ViewportFrames**, Gold showing `x120`.
  Hover pops `HoverPreview` (the kit's `ItemHoverCard`) to the RIGHT; click fills
  `SelectedItemFrame`. Search + `UIKit.FilterPanel` (tier / kind / owned-only). Sort: owned first,
  then tier high→low, then name.
  **Every ITEM count reads 0** and that is correct — no shipping flow writes `Data.Items` (the
  Game's latent `RewardCalculator` → `AddItem` Victory drop has never fired).

- **Collection screen** (`StarterGui.CollectionScreen.Controller`, A5 rebuild) — REAL instances
  (`Panel.Grid.CardTemplate`) from `GetUnitViews`: one card per uuid with tier border/BG, `Lv N`,
  GRADE letters, a status line (EQUIPPED / FAVOURITED / LOCKED / ASC n) and a meta line. **A7 note:**
  it references **no kit component at all**; worth folding into the kit at a third card-grid screen.

- **StageSelect / Party / Return / StarterChoice** — legacy script-built, on the "convert when next
  touched" list (rule 2026-07-18). `ReturnScreen` builds its banner only when a `MatchReturn`
  payload is present, so **0 GuiObjects** on a normal boot is correct, not a fault.

- **CurrencyBar** (`StarterGui.HUD.Top.CurrencyBar` + controller, A6) — **Lobby-local on purpose**:
  a single-Place widget under drift control costs a cross-Place sync forever. Refresh is **one-shot
  on join**, which was fine when nothing spent currency — **it is now stale after a summon** (the
  SummonScreen's own balance is correct). Wants a `ClientEvents.CurrencyChanged`, the same shape as
  B10's `LoadoutChanged`; **do not poll.** Amounts abbreviate (`12.3K`, `1.2M`).

- **HUD buttons** (`HUD.Left.Buttons.{Play,Units,Inventory,Areas,Summon,Store}`) tagged
  `UIKitButton` + animated; hover = white stroke. (The sixth is `Store`, not `Shop`.)
  **`Play` opens PlayGUI as of P2** — `HUD.Right` holds Event/Profile/Quests and is NOT the entry.

- **PlayGUI + LoadingScreen → `docs/systems/play-menu.md`** (split out at B15/P2 on this file's
  300-line cap). Blueprint `playgui.md` is their law.

## Client events (the screens' shared nervous system)

`RS.ClientEvents`: `OpenStageSelect` · `OpenUnitsWithUuid` · `OpenSummon` · `OpenIndex` ·
`ShowRewards` · **`LoadoutChanged`** (B10). Screens are opened by FIRING an event, never by calling
another screen — that is what lets an NPC or a different button drive them later with no change.
**PlayGUI is the exception so far:** it has no Open event yet, only the HUD button + Dev harness.
Add one the day a second thing needs to open it.

## Studio harnesses (all left OFF/empty)

`DevAutoOpen` on `UnitsGUI`/`ItemsGUI`/`CollectionScreen`/`SummonScreen`/`IndexScreen`/**`PlayGUI`**
opens that screen on boot. Action hooks, each running the SAME function a real press runs (a
`GuiButton`'s `Activated` cannot be fired from tooling, and there is no `GuiButton:Activate()`):
**`DevEquip`** (UnitsGUI, a uuid) · `DevSelect` / `DevFakeUnobtained` (IndexScreen) · `DevPull` /
`DevPage` (SummonScreen) · `DevDismiss` (ObtainRewardsGUI) · **`DevGoto`** (PlayGUI, a frame name)
/ **`DevLeave`** (PlayGUI).

## Server read path

**`GetUnitViews` is the SINGLE profile read path** for every Lobby screen since A7 retired
`GetCollection` (ADR-0004). It is load-bearing: additive changes are free, a breaking one needs
contract treatment. Clients never read profiles directly — the server decides what a unit "is",
the client only renders it. See `places/lobby/CONTEXT.md` for the field list.
