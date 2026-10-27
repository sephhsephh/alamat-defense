# Bakunawa Cove -- Stage 2 map (AD-Game, GAME Place) -- Blender build + resume plan (B173)

Pirate-island tower-defense map, final boss Bakunawa. The user's concept image gave the VIBE only ("no need to follow
the idea, only the vibes. Still stylized build"). Same pipeline as Stage 1 (`tools/maps/apolaki`,
`docs/systems/maps-apolaki.md`) + the Lobby kit helpers (`tools/maps/lobby/common.py`, executed into `common.py` here).

## Status (2026-10-27)
- **Approved + exported + assembled in the Game (B173)**: `ServerStorage.Maps.Stage2.BakunawaCove`, config
  `RS.Configs.Maps.Stage2.BakunawaCove`, verified in Play (`docs/systems/maps-bakunawa.md`). No Stage 2 acts yet.
- Map id **`BakunawaCove`** (user OK'd the name). Studio targets once approved: `ServerStorage.Maps.Stage2.BakunawaCove`,
  `RS.Configs.Maps.Stage2.BakunawaCove`, every Stage 2 act `MapId = "BakunawaCove"`.

## Files
- Work dir (outside the repo, regenerable): `Downloads\BakunawaCove_Map\` = `BakunawaCove.blend` (scene
  `BakunawaCove`), `tex\`, `glb\` (kit manifests `BC_Kit<X>.json`, `layout_terrain.json`, `layout_props.json`), `renders\`.
- The user's older `Downloads\PirateAdventureMap.blend` is THEIRS -- never touch it.
- Scripts (run each headless: `sh tools/maps/pirate/run.sh <script.py> [save]`, extra python via `PRE='ONLY={...}'`):

| Script | Does |
|---|---|
| `common.py` | lobby helpers + pirate paths/materials (`MATS`, `BC_<Mat>`), terrain helpers, `tube`, `hull_rock`, `leaf`, `flower_head`, `ship_hull`, `sail`, `flag_card`, `instance`, `export_kit` |
| `textures.py` | ~30 smooth painted textures (style target below) |
| `terrain.py` | `BC_Terrain`: plateau, beach, mesas, fort rock, skull base, islets, sandbar, sea, path ribbon; `layout_terrain.json` |
| `kit_nature.py` (N) | palms x3, grass clumps, flower patch, bushes, rocks x4, sea stack |
| `kit_harbour.py` (H) | pier segment, pirate ship (Bakunawa figurehead), rowboat, crane, crate, barrel, cannon |
| `kit_village.py` (V) | stilt shack, tall house, 2 market stalls, lamp post, flag pole, stairs, fence |
| `kit_landmarks.py` (L) | fort tower / wall / keep, treasure, shipwreck, serpent bones (Bakunawa spine + skull), waterfall |
| `kit_village2.py` (W) | tavern, lighthouse, watchtower, well, signpost, table set, bench, weapon rack, cannonball pile, anchor, rope coil, campfire, tent, laundry line, dock, market cart, footbridge, chest |
| `kit_skull.py` (S) | Skull Rock: parts -> voxel remesh -> boolean orbits/nose/mouth -> displace -> decimate; dark cavities, moss, teeth |
| `layout.py` | places ~970 instances into `BC_Placed`; writes `layout_props.json` (`a`, `p`, `yaw`, `s`, `r` footprint) |
| `preview.py` / `closeup.py` | map renders (`SHOTS=[...]`) / close-ups of kit pieces (`PIECES=[...]`) |

Rebuild everything in order: `sh tools/maps/pirate/build_all.sh [notex]`. Manual order: `textures` -> `terrain save` ->
`kit_nature save` -> `kit_harbour save` -> `kit_village save` -> `kit_village2 save` ->
`kit_landmarks save` -> `kit_skull save` -> `layout save` -> `preview`. Every kit returns `zfight` = 0 (user rule).

## Layout (Blender frame: x east, y north = away from the camera, z up; plateau top z 0, sea z -8)
- Island plateau superellipse a 124 x b 78 (n 4), grass, low cliffs on a sand beach ring; turquoise sea with shore foam.
- **Path** (`PATH_POINTS`): pier tip (-160,-12) -> 4 serpentine switchbacks -> Skull Rock cave (84,72). **556 studs**
  (Stage 1: 206) -- user asked for a longer path; wave timings need a balance pass in Studio.
- Hill zones = 4 rock mesas, one inside each switchback (`MESAS`). Ground zones = the open lawns (Studio: strips,
  minus path band, mesas, and every `layout_props.json` footprint `r`).
- Rim: harbour + 2 pirate ships west (enemy spawn on the pier), village row north, Fortress Rock (z 38) with two
  waterfalls behind, Skull Rock (x1.3) NE = the base, wreck on a sandbar SE, Bakunawa bones in the sea, islets.

## Style target (user references, B173 -- memory `td-map-art-style`)
Anime-Vanguards-style TD maps: smooth hand-painted textures (soft colour pools, painted AO/grime, few cracks, no busy
noise); grass detail = 3D leafy clumps/flowers; cobble or dirt path between raised rounded curbs; dense colourful
edges (layered tile roofs, lanterns, banners); coloured atmospheric haze, waterfalls, bloom. Skull refs: a weathered
stone skull embedded in rubble, deep dark orbits under a heavy brow, broken teeth, moss.

## Resume steps (after the user approves the renders)
1. Apply any requested changes, re-run the affected scripts, re-render.
2. Export: `export_kit` per kit (`BC_KitN/H/V/L/S` -> `glb/BC_Kit<X>.glb` + anchor) and the terrain collection
   (anchor `BC_AnchorT`); split anything > 20k tris.
3. Studio (GAME Place, confirm the name first): 3D Importer, "Insert Using Scene Position", roots come in as
   "Scene"; never `open_application("Roblox Studio")` while Studio is open. Protos -> `ServerStorage.Archive.BakunawaCove_Protos`.
4. Assemble `ServerStorage.Maps.Stage2.BakunawaCove` from the JSONs with the Stage 1 transform
   (`CFrame.new(OFFSET) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-OFFSET)`, OFFSET (0,30,0) -- check
   `maps-apolaki.md`): MapDesigns.Terrain/Props/VFX, TowerZones (zones 0.05 above surfaces), SpawnPoints/A,
   Paths/Path_Main waypoints, PathDesigns strips, Collision edges, Lighting (town-haze + coloured Atmosphere).
5. Alpha cards (fronds, waterfall) need SurfaceAppearance AlphaMode Transparency; Falls scroll as Beams/texture.
6. `RS.Configs.Maps.Stage2.BakunawaCove` + Stage 2 acts `MapId`; Bakunawa boss already in `RS.TowerModels`.
7. Verify in Play (placement survey, path walk, collision), then land (CLAUDE.md checklist; docs/systems/maps-bakunawa.md).

## B173 pt3 (user: expand, structured village, design paths, no empty islands, nothing on the enemy path)
- **Village terrace** (`VILLAGE`, z 3) north of the arena: 8 design streets (`STREETS`; packed-earth ribbons with a
  ragged alpha edge = "painted ground", each 0.1 higher than the last so overlaps never z-fight) + a raised sandstone
  plaza (`PLAZA`, well + stalls + carts). Houses face their street; tavern on the plaza corner; stairs (0, -46,69)
  climb from the arena's harbour/garden roads. Fortress Rock moved behind the village (cy 236, top 42).
- **Islets** each tell a story: lighthouse + jetty, castaway camp, buried treasure, lookout watchtower, flotsam,
  fisher's hut + jetty, ruined tower; palms ring them; far isles get big groves (+ a tower).
- **Enemy path stays clear** (`layout.clear_path`): any prop whose footprint reaches the path band (tread + curb +
  0.4) is dropped and reported (`dropped_for_path`); pier + skull/treasure (the goal) are exempt.
  `street_gap_to_enemy_path` = smallest street-edge to path-band gap (5.6 studs).
- **Hero asset** = the pirate galleon (`galleon_details`): strakes, framed gun ports with lids, gunwale balusters,
  stern gallery, wheel, lanterns, gold Bakunawa-coil transom, catheads + anchors, capstan, grates, cargo, ratlines.
- Class-project note: the user's Blender class (Texture and Mapping) also wants this map. These assets are
  script-generated by Claude; the user was told they must not be presented as the group's original work under the
  course rules. Class-only deliverables (characters, renders/screenshots for the docs, video) are on hold until the
  user discloses the AI assistance or the instructor allows it.

## Characters (B173): `characters.py` -> `Downloads\BakunawaCove_Map\BakunawaCove_Characters.blend`
- `BLEND_FILE=<that file> sh tools/maps/pirate/run.sh characters.py save` builds collection `BC_Characters`, writes
  `glb/BC_KitC.json` and renders `char_front/_34/_back.png`. 0 z-fight hits, ~18k tris for both.
- **BC_Captain** (~7.4H, NPC): tricorn + skull badge, eyepatch, beard, crimson long coat (open front), gold trim +
  epaulettes, belt + flintlock, scabbard, cuffed boots, cutlass in hand.
- **BC_SkeletonPirate** (~6.4H, Stage 2 enemy, English name per the naming rule): glowing-eyed skull, red bandana,
  ribcage/spine/pelvis, knobbed joints, ragged vest + shorts, raised cutlass.
- Static poses, no rig yet: Roblox use needs an R15-style rig + the Game's enemy model conventions (later step).
