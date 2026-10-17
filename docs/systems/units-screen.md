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

## The HERO HALL (B155, re-laid B156 from the user's reference) -- both Places
`tools/units_hall_build.luau` (Edit, each Place, re-runnable from the pristine screen or any older build; backups
`ServerStorage._UIBackup_B155`) re-lays the SAME authored nodes (names + parents kept, so every `WaitForChild` holds).
`Top`, `Bottom`, `SelectedUnitFrame` and `Stats` span the screen, so every position is a fraction of the screen.
Three columns + a bottom bar (the user's reference: roster left, hero centre, info right, section tabs + PLAY):
- **Left -- `Bottom.RosterPanel`:** ribbon "UNITS", search + filters, the grid 4 per row (`UnitsContainer.CardWidth`,
  read by `UnitsController` per card slot), footer capacity / Unequip All / **Sell**. In sell mode the sell row
  (Sell N / Select by Filter / Clear / Cancel) takes the whole footer.
- **Centre:** the unit FULL BODY on the tier-tinted `sel.Stage` (rays, aura, magic-circle floor, rune, glow);
  `Hall.frameFull` re-aims the viewport camera on every new rig.
- **Right -- the info panel (= the hero `BG`, its `TierStroke` wears the unit's tier):** name, tier, chips, stars +
  trait chip, level bar, stat pills, the open tab's PAGE, and ROUND icon buttons (Feed / View / Favorite / Lock).
- **Bottom -- `Bottom.NavBar`:** tab Plates `Bottom.Tabs.Tab{Stats,Passives,Upgrades,Trait}` (+ `OnColor`/`OffColor`;
  L1 / R1 cycle them) and **Teams**, then the big **Equip** (the reference's PLAY).
- **Pages:** Stats = More Stats (row icons where the catalog has one), Passives = the passives panel, Upgrades = the path
  bar + `UpgradesPage.TierList` (one row per tier: path-colour badge, cost, this unit's DMG / SPA / RNG with the changed
  ones green, the attack line when it changes; click = preview on the pills), Traits = `TraitPage` (trait + stored +
  the ONE Swap, ascension ladder + next cost).
- **One control per job (B156 user: "reduce duplicate buttons"):** gone -- the rail's Passives (= the Passives tab),
  the rail's Sell (Sell now PRE-TICKS the shown unit; `QuickSellButton.IdleText = "Sell"`), the trait chip's Swap
  (= the Traits page Swap), the team strip (= the equipped checkmarks + Teams).
- **Veil:** opening and the player's own close go through the LoadingScreen (`Lazy.veil` / `Lazy.leave`, Game copy
  "Back to the battle"); a close forced by another screen is instant.
- **Layout = the user's, in Studio (B160).** No runtime re-layout: `Hall.applyLayout` and the `PcPos/MobPos` sets are gone
  (user rule). Hierarchy: `Bottom.RosterPanel` holds search / filters / grid / capacity / Unequip All / Sell / sell row;
  `SelectedUnitFrame` = stage + `BG` (the info panel) which holds `Stats` (exactly BG's size), `ActionRail`, `Divider`,
  the tab pages + path bar and the CloseButton; `Bottom.NavBar` holds `Tabs`, Equip, Teams. No `Top` layer. Card width =
  the `UnitsContainer.CardWidth` attribute (edit it in Studio).
- Tab + Teams labels share one size, the round buttons' captions another (`UITextSizeConstraint "Even"`, capped at
  runtime to the smallest VISIBLE label). `attackChanged` = name, effects or shape KIND (also the Lobby `EvolveController`).
- Harness: `DevHero = "tab:Upgrades"` etc. The Game copy (B123 loadout-only mode) runs the identical hall code.

## B157 polish (both Places)
- **Pills fit their words:** `Hall.fitRow` sets the chip/trait row labels' TextSize from the row height (x0.5) and
  shrinks them together if the row overflows; the labels are `TextWrapped = false` ("Max 1" never wraps).
- **Lists scroll to the end:** `Hall.fitCanvas` (TierList, MoreStats) drives `CanvasSize` from the UIListLayout's
  content (AutomaticCanvasSize ignores aspect-ratio rows -- it stopped one row short).
- **Sell row:** four EQUAL fixed-width buttons (Sell / By Filter / Clear / Cancel); they were AutomaticSize X and overlapped.
- **Status words in passives:** a status id or name in a passive's text (`CombatIconConfig.Status`, shared to the
  Lobby B157) is bold, underlined and coloured, and its icon sits on the LEFT (`EntryTemplate.BodyRow.StatusIconTemplate`
  clones, up to 3; `Body.IconPad` makes room).
- **Card gradients swing diagonally:** `UIKit.UnitCard.paintTier` loops the tier gradient at Rotation 35 +/- 20
  (`Motion.loopGradient` opts `Rotation` / `Sway`), not straight vertical.
- **Every rig in a viewport idles:** `Client.UI.ViewportIdle` (both Places) plays `UnitCard.playIdle` (Game: the config idle; Lobby: the rig's `IdleAnim`
  attribute; else the default idle, B162) on any rig placed in a WorldModel under a ViewportFrame that has no track playing.
- **B162:** the roster grid (`UnitsContainer`, attribute `NoIdle = true`) keeps its rigs STILL; only the stage animates. The
  stage shows the unit at its ORIGINAL scale (Hall.frameFull scales it to 1; it measures the box at game scale first --
  a viewport never re-solves limbs after ScaleTo -- and stores it as `StageFitSize/StageFitOffset` on the rig).
- **No walking behind a menu:** `Client.UI.MenuMovementLock` (both Places) sets the `MenuLocked` player attribute,
  disables the controls + proximity prompts while UnitsGUI / PlayGUI / EventsGUI (+ `ExtraScreens` attr) is enabled;
  the shared `MovementController` treats it like a focused TextBox.
- **Inventory Feed** opens through `screenOpened` first (closes Inventory), then the veil, then picks the unit.
