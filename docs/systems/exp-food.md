# EXP food (B108)

**LOBBY + shared canon.** Owner: AD-Meta. User decisions: `claude/B108-ascension-shop-decisions.md`.

## Items

Six foods in the shared `ItemCatalog`, each with an `ExpFood` field (XP per item):
Pandesal 20 / Turon 45 / Bibingka 75 / Adobo 150 / Sinigang 280 / Lechon 300.
Sources: stage act drops (Game `Stage1_Act1/2/3` DropTables) and the Silver shop Food tab. Foods are also the
ascension material (`AscensionConfig.FoodFor`).

## Server

`SSS.Server.Meta.FeedService` -- `Remotes.FeedUnit(uuid, foodId, qty)`:
- refuses `not_food`, `not_owned`, `max_level`, `not_enough_food`;
- clamps qty to what the unit can still absorb before `TowerProgressionConfig.MaxLevel` (no wasted food);
- spends through `GrantService.SpendItems`, levels with the SHARED `TowerProgressionConfig.ApplyXP` and the
  tower's `UnitStatsCatalog.GetXPCurve` -- the same curve the Game uses at match end;
- returns `{ok, Fed, XPGained, OldLevel, Level, XP, XPNext, LevelsGained, Left}`.

`GetUnitViews` carries `Level`, `XP` and `XPNext`.

## Screen (Units screen, user's choice)

`StarterGui.UnitsGUI.Main.Bottom.SelectedUnitFrame.UpgradeUnitButton` (the authored, previously unused
"Upgrade" button, now labelled **Feed**) opens the AUTHORED `UnitsGUI.FeedPopup` (+ `FeedScrim`):
- left: one row per food (kit item card, `+N EXP each`, `Owned: N`, **Feed x1**, **Feed Max**);
- right `Info`: unit name, `Lv a -> Lv b` preview, XP bar with a gold preview fill, `x / y XP`, status line.
- Hover (mouse) or gamepad focus on a Feed button previews the result with the same shared curve.
- Owned counts come from `GetCraftInfo().Items`.
- Closes with X, a click outside the popup box, gamepad B, or closing the Units screen. Card hover previews are
  suppressed while it is open. Console: focus lands on the first Feed x1.
- Harness: `UnitsGUI.DevFeed` = `"open"` or `"FoodTuron:3"` (real remote).
