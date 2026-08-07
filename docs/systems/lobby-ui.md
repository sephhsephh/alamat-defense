# SYSTEM — Lobby UI (screens)

<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-06 (A7) -->

Split out of `places/lobby/CONTEXT.md` at A5 when that file passed its 150-line cap. **At A7
(2026-08-06) the KIT half moved out to `docs/systems/ui-kit.md`** — the kit is used by both Places
now, so describing it from a Lobby viewpoint had become wrong. This file is the Lobby's SCREENS.
Read `ui-kit.md` first for the components they build on.

Studio is canon for the actual instances and controller code (ADR-0001); this describes what is
there and why.

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
