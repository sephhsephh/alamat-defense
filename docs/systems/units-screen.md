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
  `Tooltip` (one shared card), `CardHover` (grid hover card, B147 rebuild by `tools/units_hover_build.luau`, same in
  the Game copy: portrait on a rarity `PortraitBg`, name / rarity / chips (Frames) / level bar, three labelled stat tiles
  DMG / SPA / RNG with grade, footer pills trait / ascension stars / worth; all scale, placed in scale by `showPreview`). B150: chips show their icon (`pillIcon`: element / placement /
  MaxPlacement), Trait + Ascension pills HIDE when empty).

## Scripts
- `UnitsController` (data, grid, equip, sell mode, favourite/lock, Feed) -- at Luau's 200-local ceiling, so new state
  lives in tables (`Lazy`) and the new features live in **`UnitsHeroController`**, talking through **`UnitsState`**
  (views / loadout / selected + hooks `reload`, `selectUnit`, `sell.*`, `setLoadout`, `onPreview`, event `Changed`).
- Data: `Shared.UnitInfoCatalog` (shared canon, GENERATED from the Game's tower configs by `tools/unit_info_gen.luau`)
  + `UnitStatPreview` (per-unit final numbers; upgrade-tier numbers = catalog tier x the unit's final/base ratio).
  **Synced (B154):** the Game's `Server.UnitInfoCatalogValidate` compares every row (cost, limit, placement, element,
  ability, passives, every tier's DMG / RNG / SPA / upgrade cost / income / attack / shape / effects) with the live
  configs at each boot and errors `[CONTRACT] UnitInfoCatalog is STALE` -- retune a tower => rerun the generator.
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

## In the GAME (B123) -- J / the MatchHUD J button, loadout only
The user copied `StarterGui.UnitsGUI` into the Game. Same controllers, minimal Game-copy patches (each tagged
`B123 (GAME copy)`): rigs from `RS.TowerModels` (no `UnitModels` there), `ClientEvents.ToggleUnits` opens it (no
HudEntry), equip refusals toast, `match_running` text. Game-only differences live in `UnitsGUI.UnitsMatchMode`:
- **Loadout only** (user): Feed, Favourite, Lock, Sell, Quick Sell + sell bar, Swap Trait, buy slots are hidden and
  kept hidden. Server `Server.Units.UnitsScreenService` refuses them (`lobby_only`).
- **Change window**: every MatchState except `InProgress` (Preparing, the start vote / Countdown, results). While a wave
  runs the SellStatus line explains the lock and writes refuse with `match_running`.
- **Auto start waits**: `LocalPlayer.UnitsScreenOpen` holds WavePrepUI's AUTO ready vote; a manual vote and the start
  timer still work.
- A change goes through the SHARED `LoadoutRules` (the Lobby's exact rules, one copy), is SAVED to `Data.Loadout`,
  re-validated into the running match (`LoadoutValidator`) + its launch Config, then `LoadoutAssigned` repaints the
  hotbar. Replay / Next Act take the player's current saved loadout (`MatchActionHandler.startFromConfig`).
- Studio: the smoke test seeds all towers; it now starts with the loadout picked on this screen last session
  (remembered by TowerId because the seed issues fresh uuids every Play), else its `desired` list.
- Needs (all shared canon since B123): `UnitCapacityConfig`, `UnitFamilyConfig`, `UnitSort`, `ScreenFX` (+ the
  authored `StarterGui.ScreenFXLayer` and `Lighting.ScreenFXBlur`), `RS.ClientEvents` (Game folder of BindableEvents).

## B155 -- the HERO HALL (user pick "Hero Hall, full screen"), both Places
`tools/units_hall_build.luau` (Edit, each Place, re-runnable; backups `ServerStorage._UIBackup_B155`) re-lays the SAME
authored nodes (names + parents kept, so every `WaitForChild` holds) full screen and adds the hall's own nodes:
- **Left:** the roster grid, 6 per row (`UnitsContainer` attribute `CardWidth`, read by `UnitsController` per card
  slot; was a hard 0.2); tools row (capacity / Unequip All / Teams / Quick Sell); **TEAM strip** (`Bottom.TeamStrip.Slots.
  Slot1..6`: the equipped loadout, a locked slot shows its level; click = select that unit).
- **Right, the showcase:** four tab PLATES across the top (`sel.Tabs.Tab{Stats,Passives,Upgrades,Trait}`, `OnColor` /
  `OffColor` attributes, L1 / R1 cycle them): **Stats** = More Stats (now with a row icon where the catalog has one),
  **Passives** = the passives panel, **Upgrades** = the path bar + `UpgradesPage.TierList` (one row per tier: badge in the
  path colour, cost, THIS unit's DMG / SPA / RNG with the changed ones green, the attack line when it changes; click =
  preview on the stat pills), **Traits** = `TraitPage` (active trait + stored + Swap plate; ascension ladder + next cost).
  Under the tabs: name / tier / chips, the unit FULL BODY on a tier-tinted **stage** (`sel.Stage`: rays, aura, magic-circle
  floor, rune, glow; `Hall.frameFull` re-aims the viewport camera on every new rig), stars / trait / level / stat pills.
- **Actions:** the rail is a row of icon + label Plates (Feed / Passives / View / Favorite / Lock / Sell) + Equip.
  The tab and rail labels share one text size (authored `UITextSizeConstraint "Even"`, capped at runtime).
- **Veil:** opening and the player's own close (X, HUD / J toggle) go through the LoadingScreen (`Lazy.veil` /
  `Lazy.leave` in `UnitsController`; the Game copy says "Back to the battle"). A close forced by another screen is instant.
- **Phone:** every placed node carries `PcPos/PcSize` + `MobPos/MobSize`; `Hall.applyLayout` picks the set (touch-only
  or a screen under 500 px tall): 4 cards per row, taller rows / tabs / buttons. Harness `UnitsGUI.DevMobileLayout` (OFF).
- **Attack changes** = name, effects or shape KIND (`attackChanged`, also in the Lobby `EvolveController`): the B154 catalog
  grows a shape each tier (Circle 4 -> 4.1), which is not a new attack.
- Harness: `DevHero = "tab:Upgrades"` etc. The Game copy (B123 loadout-only mode) runs the identical hall code.
