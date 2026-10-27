# Bakunawa Cove -- the Stage 2 map (B173, AD-Game, GAME Place)

Stylized pirate cove on a sunny tropical afternoon (user concept: "only the vibes, still stylized build"). Final
boss of Stage 2 = Bakunawa (rig already in `RS.TowerModels`). Built in **Blender** from scripts
(`tools/maps/pirate/`, README there = full pipeline + resume notes), imported with the Studio **3D Importer**,
assembled in the GAME Place from `glb/studio_data.json`. Same conventions as Stage 1 (`maps-apolaki.md`).

**Status:** map + config are in the Game Place and verified in Play via the smoke harness (`DevMapId`). Stage 2's
five acts + Infinite use it since B175 (`stage2-bakunawa.md`).

## Where it lives

| What | Where |
|---|---|
| Map model | `ServerStorage.Maps.Stage2.BakunawaCove` (WorldPivot (0,30,0), ~4,000 parts) |
| Map config | `RS.Configs.Maps.Stage2.BakunawaCove` (Id, `ModelStoragePath`, `Lighting` scalars) |
| Prototypes | `ServerStorage.Archive.BakunawaCove_Protos` (54 Models, pivot = the piece's bottom-centre) |
| Build scripts | `tools/maps/pirate/*.py` (+ `run.sh`, `build_all.sh`, `export.py`, `studio_data.py`) |
| Blender work files | `Downloads\BakunawaCove_Map\BakunawaCove.blend` (+ `BakunawaCove_Characters.blend`) |
| GLB / textures / renders | `Downloads\BakunawaCove_Map\{glb,tex,renders}` (outside the repo, regenerable) |

## Model layout (MapLoader conventions)

- `MapDesigns.Terrain`: 53 MeshParts -- `BC_PlateauTop/Cliff` (arena, top y 30), `BC_Beach`, 4 mesas
  (`<Mesa>_Top/_Cliff`), `BC_VillageTop/Cliff` (terrace, top y 33), `BC_Plaza` (+ kerb), 8 `BC_Street_*` design
  streets (alpha SurfaceAppearance, non-colliding paint), `BC_FortRock_*` (top y 72), `BC_SkullBase_*`, islets,
  `BC_Sandbar`, `BC_Sea` (y 22, non-colliding) and the enemy path ribbon (`BC_Path`: cobble tread + candy curbs).
- `MapDesigns.Props.<Piece>`: 1,654 clones of 53 protos (harbour + 2 galleons, village houses / tavern / plaza,
  fortress, Skull Rock + treasure, lighthouse/watchtower/camp islets, wreck, Bakunawa bones, palms, foliage, rocks).
- `TowerZones`: `Arena` Model (ZoneType Ground) = 435 invisible 2-stud strips, top **30.05**; Hill zones
  `MesaWest`, `MesaMidWest`, `MesaMidEast`, `MesaEast` (+ `_B` cross blocks), tops = mesa top + 0.05.
- `SpawnPoints/A` (pier tip), `Paths/Path_Main` `001..193` (Y 30.6, **556 studs** incl. the 36-stud pier),
  `PathDesigns` (192 invisible `PathStrip`, CanQuery, for PathClearance).
- `Collision/`: 283 `Edge` walls (1 x 16) around the arena rim and the village terrace (gaps at the terrace join and
  the pier landing).
- `Lighting/`: TropicSky (stock Sky), SeaHaze (Atmosphere 0.3 / Haze 1.6), TropicGrade, SoftBloom, SunRays,
  DistanceSoftness. Scalars (ClockTime 14.5, Brightness 2.4, ambient, shift, ...) in the map config.

## Collision model
- Solid: every terrain wall/top/beach/path (PreciseConvexDecomposition); buildings, rocks, Skull Rock, stairs, piers,
  docks, well, watchtower (Precise); other solid props (Hull).
- Walk-through: foliage (Frond/Blade/Petal), flags, sails, ropes, lamp glass (Neon), falls/foam, canvas, awnings,
  grass/flower clumps, bushes, small rocks; the sea and the far isles.
- Zones sit 0.05 above the visible surfaces, so `SurfaceZoneAt` meets them first (Stage 1 rule). Verified B173:
  lawn -> Ground strip y 30.05, mesa -> Hill y 35.05, path/streets/village/plaza -> not a zone.

## Gotchas (learned B173)
- **The enemy RestY is measured ONCE at waypoint 1** (`RigGrounding.GroundY`, CanCollide-respecting raycast) and
  held for the whole path. The spawn waypoint must sit over solid ground at path height: the first build left the pier
  2 studs short of the spawn, the ray hit the beach and every enemy walked 13 studs under the deck. Fixed by a 4th
  pier segment (`layout.harbour`).
- Imports: each GLB queued separately in the Import Queue; tick **Insert Using Scene Position** + **Anchored**, rename
  the root (`BC_Terrain`, `BC_Kit<X>`); meshes arrive wrapped in `<name>_Node` Models; every anchor lands at (0,0,0).
  Emissive materials arrive with a SurfaceAppearance (removed for Lamp -> Neon); cutout textures need a
  SurfaceAppearance `AlphaMode = Transparency` (added by the proto builder).
- Two Studio windows are open (Game + Lobby): confirm the TITLE before clicking Import (B173 nearly imported into the
  Lobby). Never `open_application("Roblox Studio")` while Studio runs (updater).
- The Studio side reads `studio_data.json` over a local `http.server` (Blender Python, 127.0.0.1:8765) with
  `HttpService:GetAsync` -- the Game Place has HttpEnabled on.
- Don't save `BakunawaCove.blend` from an open Blender GUI while scripts run (the skull kit vanished twice).

## Testing
`ServerScriptService.Server.MatchLifecycleSmokeTest` attribute **`DevMapId`** (B173, the fourth knob): run the smoke
act on another map, e.g. `BakunawaCove`, before its stage exists. Leave it EMPTY when done (CLAUDE.md: Dev* off).

## Open threads
- Stage 2 content is built (B175, `stage2-bakunawa.md`); its real enemy rigs + balance pass are STATE PENDINGs.
- Optional VFX: waterfall Beams/scroll, campfire + chimney smoke, lantern lights, sea foam (map has none yet).
