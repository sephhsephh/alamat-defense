# Areas screen -- LOBBY (HUD "Areas")
<!-- owner: AD-Lobby | since: B146 (2026-10-13) | user refs B146 (another TD game's Areas window) -->

Every place a player can jump to, grouped like the reference: categories on the left (+ Add Waypoint), search,
one scrolling list of category sections (coloured header + glowing underline, picture cards with a favourite star).

## Pieces
| Part | Where |
|---|---|
| HUD button | `HUD.Left.Buttons.AreasButton` (clone of the Index tile, Theme Azure, 4th grid row; the grid grew to 4 rows at the same cell size; old grid in `ServerStorage._UIBackup_B146`). Icon = placeholder compass (`rbxassetid://128162852510137`) -- prompt `HUD_Areas` in `icon-art-style.md` |
| Screen | `StarterGui.AreasGUI` (DisplayOrder 5) built by `tools/areas_build.luau`: `Main{Header, TopBar.SearchBar, CloseButton, Tabs.TabTemplate, Hint, ContentPlate.Content}` + `Templates{HeaderTemplate, CardTemplate}` (authored HIDDEN -- a Folder does not hide GUI) |
| Controller | `AreasGUI.AreasController` |
| Data | `RS.Configs.AreasConfig` -- Categories (Upgrade / Game Modes / Lobby / Shop & Summon, colour + icon) and Areas (`Travel` = a model in `Workspace.Lobby.Map.Travel`, or `Open` = a ClientEvents screen; `Image` = the card picture) |
| Server | `Server.Lobby.LobbyMapService` -> `Remotes.AreaAction`: `"Info"` (map positions + favourites), `"Travel", id` (validated against the config; the B136 travel veil), `"Fav", id, on` (`Counters.Global.AreaFavs`, no schema bump) |
| New map spots | `Map.Travel.Area_{SunAltar, Waterfall, BlueBeacon, Jungle, Lighthouse}` -- an invisible `Arrival` part each (placed on raycast-checked ground) |

## Behaviour
- Click a card: TRAVEL cards close the screen and teleport behind the veil; OPEN cards open their screen (Story -> Play
  menu, Events, Index, Summon). The tab of the section at the top lights up while scrolling; a tab click scrolls to it
  and the header ribbon takes the category colour. Favourites get their own section on top.
- **No waypoints** (B148, user: "useless") -- the Add Waypoint button, its marker template and the controller code are gone
  (old instances in `ServerStorage._UIBackup_B148`). Gamepad B closes.
- Card pictures: in-Studio captures of each district uploaded as images (B146); Story/Events/Index/Summon use an icon.

## Verified B146 (Play)
Opened from the HUD; 17 areas, 13 with map spots; travel to Crystal Shrine + Sky Temple landed on the arrivals;
waypoint on Stat Forge (567 m, label + distance, button state). No client errors.
