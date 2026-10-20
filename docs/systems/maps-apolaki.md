# Apolaki Sun Terraces — the Stage 1 map (B166, AD-Game, GAME Place)

Stylized "anime" map (Anime-Vanguards-like look, not cartoony, not realistic): a golden-hour
sun-shrine meadow with rice terraces climbing behind it, a river valley, a waterfall and
painted mountains. Built in **Blender** from scripts, imported with the Studio **3D Importer**,
assembled in the GAME Place. Every Stage 1 act (`Stage1_Act1..Act5`, `Stage1_Infinite`) has
`MapId = "ApolakiSunTerraces"`. `TestMap` and its config are KEPT. They are unused, so delete them only on request.

## Where it lives

| What | Where |
|---|---|
| Map model | `ServerStorage.Maps.Stage1.ApolakiSunTerraces` (WorldPivot (0,30,0)) |
| Map config | `RS.Configs.Maps.Stage1.ApolakiSunTerraces` (Id, `ModelStoragePath`, `Lighting` scalars) |
| Prototypes | `ServerStorage.Archive.ApolakiSunTerraces_Protos` (one Model per asset: `Root` + parts + FX attachments) |
| Build scripts | `tools/maps/apolaki/*.py` (this repo) |
| Blender work file | `Downloads\Apolaki_Map\ApolakiSunTerraces.blend`, scene `ApolakiMap` (outside the repo) |
| Generated textures / GLB / renders | `Downloads\Apolaki_Map\{tex,glb,renders}` (outside the repo, regenerable) |

## Model layout (MapLoader conventions)

- `MapDesigns.Terrain`: about 53 MeshParts: `AST_MeadowTop/Cliff`, the three mesas (`<Mesa>_Top/_Cliff`),
  paddies, `AST_TerraceStones_1..8` (stacked fieldstones) + `AST_TerraceEarth_1..8`, the valley, river, 10 mountains,
  the falls rock, and `AST_Path` (the dark rims are RAISED geometry, not paint).
- `MapDesigns.Props.<Asset>`: about 2.6k parts. SunGate, Shrine (stacked blocks/drums), Banner, Torch, trees,
  palms, bamboo, bushes, huts, rocks/rock piles/cliff boulders/river rocks, pebbles, grass, flowers.
- `MapDesigns.VFX`: MeadowMotes, Blossoms, Waterfall (3 scrolling Beams + Mist/Foam), GodRays (9 Beams on the sun line).
- `TowerZones`: `Meadow` Model (ZoneType Ground) = 66 invisible 2-stud strips; Hill zones `MesaWest`,
  `MesaEast`, `SunRock` (+ `<name>_B`). Each mesa is a CROSS of two blocks inside the rounded (n=3.2) mesa outline.
- `SpawnPoints/A` (path start, by the gate), `Paths/Path_Main` `01..76` (Y 30.6, 206 studs; TestMap is about 155),
  `PathDesigns` (75 invisible `PathStrip`, CanQuery, for PathClearance).
- `Lighting/`: ApolakiSky (painted cubemap), GoldenAir (Atmosphere), AnimeGrade, SoftBloom, SunRays, DistanceSoftness.
  Scalars (ClockTime 16.7, latitude 24, ambient, colour shift, …) live in the map config's `Lighting` table.
- `Collision/`: 120 invisible `Edge` walls (1 x 16 tall) ringing the meadow. The worst joint gap is 0.6 studs.

## Collision model (B166, user: "precise collision on all objects")

- **Solid, `PreciseConvexDecomposition`:** all terrain walls (`AST_Path`, `AST_MeadowCliff`, mesa cliffs,
  terrace stones), `AST_MeadowTop` + the three `<Mesa>_Top` (the visible surfaces ARE the floor), and every
  solid prop part (Trunk, Rock, Stone, Gold, Wood, Roof, Pole, Bowl, Culms).
- **Bushes:** an invisible upright CYLINDER `Collider` inside each bush (0.72 × the narrower width, 0.88 × height).
  The leaf cards stay non-colliding. A rounded hull let the humanoid ride UP onto the bush, so we use a cylinder.
- **Walk-through by design:** tree canopies / fronds / bamboo leaves (overhead), grass tufts, flowers, pebbles,
  banner cloth, emblems.
- **Placement stays correct because the ZONES sit 0.05 above the visible surfaces.** That covers the meadow strips
  (top 30.05) and the mesa blocks (top + 0.05). `SurfaceZoneAt` meets the zone first. Anywhere off the strips,
  the ray meets the solid meadow/mesa mesh, which is not a zone, so placement is refused (unchanged behaviour).
- Verified in Play (B166):
  - A 1-stud raycast scan inside the Edge ring finds no hole.
  - Dropping the character on the old holes (mesa rims, the back rim by the terrace stones) lands it on the surface.
  - Forced 70 stud/s pushes stop at the cliffs and Edge walls.
  - A bush stops the walker.
  - 4-stud placement survey: about 640–670 Ground + 16 Hill points.
- History: the 2-stud strips left GAPS (the mesa footprint + pad, and a 28×2 band at the back rim by the
  terrace stones). The meadow mesh was non-colliding, so a dash dropped the player under the map.

## Rebuild pipeline (Blender 5.x, run each with `exec(open(r"<repo>/tools/maps/apolaki/<f>.py").read())`)

1. `textures.py`: about 26 painted textures (domain-warped value noise → posterized cel bands). `ONLY = [...]` runs a subset.
2. `terrain.py`: meadow, mesas, terraces, valley, river, path, mountains. Writes `glb/layout_terrain.json`.
3. `assets.py`: first-pass prototypes (trees, palms, bamboo, bushes, grass, flowers, huts, fence, torch, banner).
4. `masonry.py`: REAL stone geometry. Terrace stones/earth, the raised-rim path, SunGate, Shrine, RockA/B/C,
   RockPile1-3, Pebbles. Deletes the first-pass gate/shrine/rock prototypes first.
5. `layout.py`: scatters the placements and writes `glb/layout_props.json` (`a`, `p`, `yaw`, `s`).
6. `sky.py`: seam-safe painted cubemap. `preview.py`: EEVEE preview renders. `export.py`: writes GLBs with an `AST_Anchor` cube.

`common.py` holds the noise and scene helpers. ⚠ The noise lattice is cached and capped at P ≤ 512: an uncached 4096²
lattice per call crashed Blender (out of memory). ⚠ Seeds use `sum(map(ord, name))`. Python's `hash()` is randomized per run.

## Studio import + assembly gotchas (all learned the hard way)

- **3D Importer** (GUI): Import Queue `+`, tick **Insert Using Scene Position**, then Import. Meshes upload to the creator
  (SuperLazy Devworks). Name suffixes like `.001` are stripped; keep prototype names unique in Blender.
- **The importer turns the scene 180° about Y.** The real mapping is Roblox = (-x, z, y) about the anchor. The JSON layouts are in
  the pre-rotation frame (x, z, -y), so the assembly applies
  `CFrame.new(OFFSET) * CFrame.Angles(0, math.pi, 0) * CFrame.new(-OFFSET)` to every placement, zone and waypoint.
- **OFFSET = (0, 30, 0).** The Place's Baseplate top is Y = 0 and cut through the valley at Y 0.
- **MeshPart `TextureID` ignores alpha.** Leaf/frond/grass/flower cards need a `SurfaceAppearance` with ColorMap = the
  texture and `AlphaMode = Transparency`. It is script-settable, and about 765 parts have it.
- `CollisionFidelity` IS script-settable in Edit, but it applies ASYNC: read it back after a short wait.
  `CanQuery` is forced true while `CanCollide` is true.
- Pressing **Q** in the Game is the DASH, not "cancel placement".

## Asset ids

- Sky: Bk 83122416907409 · Dn 135420030838273 · Ft 74960463999440 · Lf 135849041610625 · Rt 94344798368683 · Up 84235423470962
- VFX: fx_flame 102236980269824 · fx_petal 83846852850468 · fx_falls 99665237359416 · fx_ray 113692410770434
  (reused: soft 124244326249601, star 70950184156700, ring 99590764470565)
- The first-pass gate/shrine/rock meshes (before `masonry.py`) are uploaded but UNUSED.

## Open threads

- Balance: the path is 206 studs (TestMap was about 155), so enemies spend longer on the map.
  Re-check the wave timings and the lives/difficulty feel per act.
- New maps: copy this folder's pipeline (`tools/maps/<map>/`), keep the zone-above-surface rule and the collision list.
