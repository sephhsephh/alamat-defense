# Collection Index (Units + Enemies dictionary) -- Lobby, B108 pt4

User spec (B108): a NEW screen with its own HUD button; Units tab lists every unit of every
rarity, undiscovered ones locked; Enemies tab per stage / raid / boss / event; clicking a card
shows portrait, name and description. Style follows the user's reference image.

## Pieces
| Piece | Where |
|---|---|
| Screen (authored) | `StarterGui.CollectionGUI` (DisplayOrder 12, `Main` tagged `GamepadMenu`) |
| HUD entry | `StarterGui.HUD.Left.Buttons.IndexButton` (Quests logo until an icon is authored) |
| Open event | `ReplicatedStorage.ClientEvents.OpenCollection` (BindableEvent) |
| Driver | `CollectionGUI.CollectionController` (LocalScript, boot markers) |
| Lore | `ReplicatedStorage.Configs.Meta.IndexLore` -- `Units[id] = {Origin, Description, Confirm?}`, `Enemies[id] = {Name, Group, Stages, Boss?, Description, Origin, Abilities}`; accessors `IndexLore.Unit(id)` / `IndexLore.Enemy(id)` |
| Discovery | `GetUnitViews` -> `Discovered` (`Counters.Global.Obtained_<TowerId>`, lifetime, never decremented; `Server.Meta.UnitDiscovery`) and `EnemiesSeen` (`Counters.Global.Seen_<enemyId>`, written by the Game) |
| Portraits | units: `RS.UnitModels[id]` (fallback `Placeholder`); enemies: `RS.EnemyModels[id]` via `UIKit.UnitCard.viewport` |

## Behaviour
- Units = every tower in `ItemCatalog`, ordered by `TierConfig.Order`, then name. Filters: All + each tier (left list and chip row are the same state).
- Locked card: darkened rig, "?" + LOCKED, name "???". The detail pane still shows the entry, status "Not Yet Obtained".
- Enemies grouped Story / Raids / Bosses / Events; Bosses painted red. Status "Encountered xN" / "Not Yet Encountered".
- Progress box: "Total Units Unlocked n / 48" or "Total Enemies Encountered".
- Tier colours too dark to read as text are lifted toward white (`readable`); strokes/dots keep the true colour.

## Adding content
- New unit: nothing to do here beyond the usual (ItemCatalog + both Places' rigs); add an `IndexLore.Units` entry for its text.
- New enemy: add an `IndexLore.Enemies` entry (Group = Story/Raids/Bosses/Events) and copy its rig into the Lobby's `RS.EnemyModels`.

## Dev harness (ScreenGui attributes)
`DevOpen=true`, `DevMode="Units"|"Enemies"`, `DevFilter=<key>`, `DevSelect=<id>`, `DevForget=true` (Studio only: pretend nothing is discovered).
