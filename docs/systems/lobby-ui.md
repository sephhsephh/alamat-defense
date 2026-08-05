# SYSTEM — Lobby UI (kit + screens)
<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-03 (A5) -->

Split out of `places/lobby/CONTEXT.md` at A5 (2026-08-03) when that file passed its 150-line
cap. This is the AD-UI canon description of the Lobby's UI kit and screens. `CONTEXT.md` keeps
only a pointer. Studio remains canon for the actual instances and controller code; this doc
describes what is there and why.

## UI kit + screens (AD-UI, 2026-07-31; A4 view-model 2026-08-03; A5 kit + screens 2026-08-03)

**Kit layout (A5):** REAL instance templates live in **`ReplicatedStorage.UITemplates.Kit`**
(the blueprint §5 home) — `Button`, `UnitPreviewTemplate`, `Unit/ItemIconTemplate`, and the new
`ItemIcon` / `ItemHoverCard` / `FilterPanel`. `StarterGui.UITemplates` was emptied into it and
deleted. Controllers are client ModuleScripts in `ReplicatedStorage.Shared.UIKit`
(`Button`, `ItemIcon`, `FilterPanel`); each resolves its template by path with fallbacks.
Removed at the move: the legacy per-slot `Unit/ItemIconTemplateLocalScript`, which had a
**syntax error on line 30** (`ocal Preview`) and had been erroring on every replication.

- **`UIKit.ItemIcon`** (A5) — item card controller. `ItemIcon.create(parent, itemId, qty)`;
  flat `IconImage` ImageLabel (**no ViewportFrame — items have no model**), `QtyBadge` that
  hides at qty 0 (and dims the icon), tier border + BG from the shared multi-colour `TierConfig`,
  hover/press scale + white border, `onHover`/`onActivated`/`setQty`/`setSelected`/`destroy`.
  `ItemIcon.ImageFor(id)` falls back to the Studio placeholder while catalog art is `rbxassetid://0`.
**Hover-card placement (both screens, hardened A5).** `showPreview` anchors the card at
`(0, 0.5)` beside the hovered card, flipping to the LEFT when it would overflow right. It
**measures `hoverPreview.AbsoluteSize`** rather than assuming a scale — A4 assumed `0.2 × 0.36`
of the viewport when the real frame is ~`0.19 × 0.19`, which made the flip fire twice as early
as needed. The vertical `math.clamp` is guarded because it ERRORS when max < min (preview taller
than the viewport, or a degenerate `ViewportSize`), falling back to vertical centre.
**When you resize a Kit template, re-sync any already-deployed clone** — `ItemsGUI.HoverPreview`
silently kept an old footprint this way until it was caught.

- **`UIKit.FilterPanel`** (A5) — reusable filter panel, used by BOTH the Units and Items screens.
  Clones `GroupTemplate` / `ToggleTemplate`; Apply commits pending→applied and fires `OnApply`,
  Cancel reverts, Reset clears. `handle.selected(groupId)` returns nil when a group is
  unconstrained, so "no filters" means "show everything".
- **`UIKit.Button`** (`ReplicatedStorage.Shared.UIKit.Button`) — ONE reusable controller for
  every button (no per-button scripts). Hover = scale from centre (`centerAnchor` fix) + stroke
  thicken OR `HoverStrokeColor` (e.g. white) + icon rotate; press animation; seamless (tiled)
  animated gradient. All attribute-driven (`HoverScale/HoverStrokeMult/HoverStrokeColor/
  HoverIconRotation/PressScale/TweenTime/GradientAnimate/GradientSpeed/GlowStrokeName/
  StrokeHiddenUntilHover`). API: attach/create/onActivated/onHover/setHovered/setText/setIcon/
  setStrokeColor/setEnabled. **Tag any GuiButton `UIKitButton`** → `StarterPlayerScripts.UIKitBootstrap`
  attaches it (tags copy to clones).
- **Hotbar** (`StarterGui.Hotbar.HotbarController`) — single controller replaces the old
  duplicated per-slot scripts (disabled); glow on hover + `Hotbar.Templates.UnitPreviewTemplate`
  shown above the hovered slot.
- **Units screen** (`StarterGui.UnitsGUI.UnitsController`) — **A4 (2026-08-03): now reads the
  `LobbyServices.GetUnitViews` view-model**, keyed by **uuid** (one card per unit instance).
  Per card from the view: `Name`+`Tier` (ItemCatalog), tier-coloured border **and** BG (shared
  `TierConfig`, seamless multi-colour), per-stat **GRADE** letters in the Stats panel + hover
  preview (`view.Grades` from `StatGradeConfig`), real `Level`/`XP` on the preview level bar, and
  `Favorited`/`Equipped` driving the sort (equipped > favourited > tier high→low > name). Hover =
  white border + scale + `UITemplates.UnitPreviewTemplate` popup (fake element chips hidden);
  click → `SelectedUnitFrame`. Live SearchBar (by name). **Resolved DMG/RNG/SPA NUMBERS deferred
  to A6** (grades only for now — TowerStatResolver not in the Lobby). Placeholder model
  `UnitModels.Placeholder` (real models later). Action buttons still **animation-only**.
  **A5:** stat rows are dual-slot — the user added a `Grade` TextLabel to each of
  `Stats.BaseStatsFrame.{DMG,RNG,SPA}`, so the GRADE letter renders in `Grade` and the NUMBER
  slot (`TextLabel`) carries the value. Rows WITHOUT a `Grade` child (the hover preview's
  Attack/Element/MaxPlacement) keep the old behaviour and show the letter in their single label.
  FILTERS button → shared `UIKit.FilterPanel` (tier + equipped/favourited/locked).
  **A6 (2026-08-06):** the number slot is now filled from the shared `UnitStatsCatalog.Get(towerId)`
  (ADR-0003) — resolver-PRODUCED base values, SPA already inverted, not raw `BaseStats`.
  `formatStat` trims decimals (`15`, `1.4`, `2.5`) and renders `--` for a missing value, so a
  support tower (Farm has no DMG/SPA keys) or an unknown towerId **never prints "nil"**.

  **Read this before "fixing" a bug report:** the number is **per-TOWER, not per-unit**. Two
  instances of the same tower show the SAME number while their GRADE letters differ — the grade
  comes from that unit's roll, the number is fixed at the catalog's mid-roll reference (tier 1 /
  ML 1 / no trait / asc 0). That is the sanctioned ADR-0003 trade: the Lobby cannot resolve a
  per-unit number without the ~12-module full stat stack. It reads correctly because the panel is
  titled *BaseStatsFrame*, but it is a real thing players may query. Per-unit numbers would need
  the Min/Max ranges promoted too, which ADR-0003 deliberately rejected.
- **Items screen** (`StarterGui.ItemsGUI.ItemsController`, A5) — opens from **HUD.Inventory**.
  Chrome cloned from the Units screen so the design matches. The LIST is every `ItemCatalog`
  entry with `Kind = "Item"|"Currency"` (a compendium of what exists); the COUNTS come from
  `GetUnitViews.Items` (+ `Currencies` for Gold/Silver). Cards are `UIKit.ItemIcon`; hover pops
  `HoverPreview` (the kit's `ItemHoverCard`) to the RIGHT, click fills `SelectedItemFrame`
  (name/tier/description/owned x/max). Search + `UIKit.FilterPanel` (tier / kind / owned-only).
  Sort: owned first, then tier high→low, then name. **All counts read 0 today** — no writer.
- **Collection screen** (`StarterGui.CollectionScreen.Controller`, A5 rebuild) — was
  script-built, now REAL instances (`Panel.Grid.CardTemplate`, editable in Studio) filled from
  `GetUnitViews`: one card per uuid with tier border/BG, `Lv N`, the three GRADE letters, and a
  status line (EQUIPPED / FAVOURITED / LOCKED / ASC n). Meta line shows unit count + Gold/Silver
  + account level. **This removed the last reader of `GetCollection`'s compat fields.**
- **Studio harness (A5):** each of `UnitsGUI` / `ItemsGUI` / `CollectionScreen` honours a
  `DevAutoOpen` **attribute** — set it true to open that screen on boot with no HUD click, so a
  Play session can be verified without synthetic input (`VirtualInputManager` is blocked for
  tooling). Same pattern as `DevSimulateReturn` / `DevSimulateFirstJoin`. **All three left OFF.**
- **Configs:** `RS.Configs.Meta.TierConfig` + `ItemCatalog` + `StatGradeConfig` + `AscensionConfig`
  are **SHARED CANON** (`shared/src`, deployed both Places, drift-checked). `TierConfig` = 8 tiers,
  per-tier `Colors` list (Mythic rainbow + Secret red→dark-red), helpers
  `get`/`colorSequence`/`seamlessSequence`/`isMultiColor`. `ItemCatalog` = authority on Name+Tier.
  **`UnitCatalog` DELETED at A4 (2026-08-03)** — the Units screen no longer reads any placeholder.
- **HUD buttons** (`HUD.Left.Buttons.{Play,Units,Inventory,Areas,Summon,Store}`) tagged +
  animated; `Frame.BorderDesignInside` hidden; hover = white stroke (no thicken).
  (The sixth button is `Store`, not `Shop` — this doc said Shop until A5.)
