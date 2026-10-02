# Units screen (Lobby) -- B108 pt14 rebuild

User brief (2026-10-02): rebuild from the reference screenshots, unique layout, keep every feature, hover info everywhere,
best UI/UX + animations, "upgrade unit" = the Feed system, optimised. User picks: **Hero-left** layout, **5 cards per row**,
features **upgrade path, View Unit inspect, Teams save/load, Select-by-Filter sell** + every hover shown in the references.

## Layout (StarterGui.UnitsGUI, all authored)
- **Hero (left, `Main.Bottom.SelectedUnitFrame`)**: `UpgradePath` (segment per tower tier), `BG` + animated tier border
  (`TierStroke`), `ViewportFrame` model, `Stats`: `ChipsRow` (Element / Placement / Max), `TierName` "<Tier> Unit", `UnitName`,
  `TraitRow` (`TraitChip` + `SwapTraitButton`), `AscRow.AscChip` (stars), `LevelBar` (Lvl + XP left), `BaseStatsFrame`
  pills (DMG / SPA / RNG with grade), `MoreStatsButton` -> `MoreStats` list, `PassivesPanel`.
- **Action rail (`Main.Bottom.ActionRail`)**: Feed (`UpgradeUnitButton`), Passives, View Unit, Favorite, Lock, Sell This Unit.
  Each carries a `Tooltip` attribute.
- **Grid (`UnitsContainer`)**: 5 per row, auto canvas, lazy viewports (pt13e).
- **Bottom bar**: `UN/EquipButton` | `CapacityBar` (+ slots) | `UnequipAllButton` | `TeamsButton` | `QuickSellButton`;
  in sell mode `SellButtons` (Sell N Units / Select by Filter / Clear / Cancel) replaces Unequip All + Teams.
- Popups: `TeamsPopup`, `FilterSelectPopup` (+ `*Scrim`, which never closes anything), `Inspect` (full screen),
  `Tooltip` (one shared card), `CardHover` (grid hover card: portrait, chips, level, pills, trait / asc / worth).

## Scripts
- `UnitsController` (data, grid, equip, sell mode, favourite/lock, Feed) -- at Luau's 200-local ceiling, so new state
  lives in tables (`Lazy`) and the new features live in **`UnitsHeroController`**, talking through **`UnitsState`**
  (views / loadout / selected + hooks `reload`, `selectUnit`, `sell.*`, `setLoadout`, `onPreview`, event `Changed`).
- Data: `Shared.UnitInfoCatalog` (new shared canon, generated from the Game's tower configs) + `UnitStatPreview`
  (per-unit final numbers; upgrade-tier numbers = catalog tier x the unit's final/base ratio).
- Server: `Server.Lobby.LoadoutService` adds `SetLoadout(list)` (Unequip All / load), and `Data.UnitTeams` (schema v10):
  `GetUnitTeams`, `SaveUnitTeam(i)` (= current loadout), `LoadUnitTeam(i)` (re-cleaned: owned, one per family, unlocked
  slots), `RenameUnitTeam(i, name)` (TextService filtered, max 20 chars). 5 teams.

## Interaction
- Tooltips: mouse hover, gamepad selection, touch long-press (auto-hides after 3 s). Hide is owned (B29 race).
- Upgrade path: hover = "Placement"/"Upgrade N", cost, attack change + description, DMG/SPA/RNG before -> after for THIS
  unit; click = preview that tier on the stat pills (green); click again to clear.
- View Unit: drag / Q-E / buttons rotate, wheel zoom, R reset, X / B / Esc close (only-close-button rule kept).
- Gamepad B / Escape backs out one layer (Inspect > Filter > Teams > Passives).
- Studio harness: `UnitsGUI:SetAttribute("DevHero", "teams"|"filter"|"inspect"|"passives"|"more")`.
