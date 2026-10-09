# Lobby map -- night islands, themed districts, travel waystones (Lobby)
<!-- owner: AD-Lobby | scope: Lobby | last-verified: 2026-10-10 (B134) -->

The Lobby is the user's "Map Concept" image built for real: a night archipelago on the terrain islands from B130
(`tools/lobby_islands_gen.luau`). Every NPC lives in its own themed district; glowing waystones make the long
walks optional. **Design canon = this doc + `tools/lobby_map/*.luau`; the built map is Studio (Lobby).**

## Where things live
- **`Workspace.Lobby.Map.<District>`** -- everything built. `Workspace.Lobby` MUST stay: `SettingsConfig.Place()`
  detects the Lobby by it. Kept untouched at the workspace root: `NPC_*`, `SpawnLocation`, `PersistentScene`,
  `Terrain` and the user's south area (`Workspace.Model` = Yasu's tree pack etc., the user's "keep untouched").
- **Builders:** `tools/lobby_map/Lib.luau` (mirrored at `ServerStorage.DevTools.LobbyMap.Lib` -- keep the two
  byte-identical) + `01_arrival_altar` .. `07_npcs_travel`. Paste a step into `execute_luau` (Lobby, Edit). Every
  step is idempotent (`Lib.folder` clears its district first). Order matters: 06 scatters around what 01-05 built.
- **Prototypes:** `ServerStorage.DevTools.LobbyMap.Protos` (AI meshes `AI_NipaHut`, `AI_Statue`, `AI_Ship` -- made
  with Studio's mesh generator, anchored -- + `Bush1/2`). `Lib.proto` falls back to **`ServerStorage._OldLobby_B134`**
  (the archived old lobby: LampPost, BannerPole, palms, `Tree_*`, rocks). **Do not delete that archive while the
  scripts may be re-run** -- move the protos you still want into `Protos` first.
- **Runtime:** `ServerScriptService.Server.Lobby.LobbyMapService` (travel + water rescue, below).

## Districts (world coords; the plaza faces north = -Z)
| District | Centre | NPC | Colour / landmark |
|---|---|---|---|
| Arrival Plaza (spawn) | (-330, 97.5, 772) | Guide | gold compass mosaic, 8 lamps, 6 waystones |
| Golden Flame Altar | (-300, 118, 560) | -- | 3-tier altar, great gold brazier |
| Sky Temple | (-420, 207, 362) | Ascension (forecourt) | blue door glow + sky beam, twin AI guardians |
| Rune Circle | (-560, 169, 462) | Evolve | 12 runes, 4 glyph monoliths |
| Waterfall | lip (-462, 166, 549) | -- | neon sheets, mist |
| Blue Beacon | (-612, 82, 815) | -- | crystal + sky beam |
| Beach Village | market (-846, 15, 748) | Shop, Craft (stalls) | 6 AI nipa huts, piers, bangkas, campfire |
| Jungle | (-850, ~150, 430) | -- | stair chain, lookout tower, ruined arch |
| Red Gate Fortress | gate ~(-90, 120, 580) | Stat Reroll (forge, (100, 628)) | torii gate, crimson brazier, watchtower |
| Crystal Shrine | (292, 143, 352) | Trait Reroll | purple crystal spire + sky beam |
| Green Arena | (40, 104, 815) | Challenge | green beacon + sky beam, ledge stairs |
| Sea / volcano | lagoon ship (-115, 662), sea ship, lighthouse (-262, 56, 980), crater (-24, 210, -312) | -- | |

Bridges (`Lib.bridge`: planks, rope rails, invisible guard rails, piers over 70 studs) and stairs (`Lib.stairs`)
link every district; paths are terrain `Sandstone` strips (`Lib.path`).

## Travel waystones (`Map.Travel`)
- `Plaza_<District>` x6 on the plaza's south arc (r 44) and `Stone_<District>` x6 (one per district, near its
  NPC). Each `Shaft` holds a **ProximityPrompt `TravelPrompt`** ("Travel", hold 0.25 s, range 9 -- keyboard E,
  gamepad X, tap on mobile) with attribute **`TravelTo` = destination stone name**; district stones go to
  `Plaza`. The destination's invisible **`Arrival`** part is where the player lands.
- Labels are BillboardGuis cloned from `NPC_Guide.Body.NameTag`, sized in studs (scale 7 x 1.7, MaxDistance 60).
- `LobbyMapService` does the teleport (`RequestStreamAroundAsync` first -- StreamingEnabled is on). `NpcPromptRouter`
  ignores these prompts (no NPC ancestor, no `OpensEvent`).

## Water rescue
The sea is a thin terrain band (Y -4..4) under sheer cliffs -- a swimmer cannot climb out. `LobbyMapService` puts a
player swimming for 4 s (root below Y 6 AND a terrain ray hits Water -- piers and boats sit higher) on `Plaza`.

## Plaza seating (why `Lib.plaza` carves)
Smooth terrain poked 0.3-2.9 studs through flat discs and grass decoration grew through them. `Lib.seat` (called by
`Lib.plaza` unless `NoSeat`) carves 2 studs under the disc inside r+2, a shallow bowl out to r+14, and turns the
grass under it into `Ground`. Props inside a bowl must be re-seated (06 does).

## Lighting + terrain (B134; previous values in attributes `Lighting.B134_Before`, `Terrain.B134_BeforeColors`)
- Night: ClockTime 0.5, Brightness 3, ExposureCompensation 0.55, Ambient (78,84,118), OutdoorAmbient
  (128,142,196), Env diffuse/specular 0.7. Atmosphere density 0.24, offset 0.1, colour (110,130,190), decay
  (52,66,120), glare 0.15, haze 1.1. Bloom 0.55 / 28 / threshold 1.5 (only neon glows). ColorCorrection
  +0.04 / contrast 0.14 / saturation 0.18 / tint (228,234,255). Sky kept (user: "the skybox is good").
- Warm point lights (flames, lamps, huts) against cool moonlight; only 4 lights cast shadows.
- **`Lighting.Technology` must be set to `Future` BY HAND** -- scripts cannot write it.
- Terrain: Grass (62,112,44), LeafyGrass (46,92,34), Sand (176,154,112), Sandstone paths (198,178,140), Rock
  (86,84,88), Slate (70,72,80), Ground (122,98,70); water (14,96,128), transparency 0.45.

## Rules
- **`PersistentScene.PlayGUICamera` is the USER'S framing -- never move it** (`play-menu.md`). It still frames the
  pre-island view (volcano); re-framing it is the user's call.
- NPCs are free to move: every lookup is by name (`NpcPromptRouter`, `WaypointController`, `DialogueConfig`,
  quests). They are `ModelStreamingMode = Persistent`. Stand them with a parts-aware raycast (07's `floorAt`).
- Budget (B134): map 4.5k parts (nature 3.1k; palms are 58-118 parts each, trees/rocks 2), 132 lights (4 shadowed
  after the lamp fix), 91 emitters. Prefer trees/rocks over palms; no new shadowed lights without a reason.
- A new unit still needs its rig in `RS.UnitModels` here -- unrelated to the map, but the rule stands.
