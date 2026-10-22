# Stylized environment guide -- how Alamat Defense maps (incl. the Lobby) are built
<!-- owner: AD-Lobby | scope: every map + the Lobby | last-verified: 2026-10-22 (B172) -->

User direction (B172): "that's the kind of build style I want" -- the reference places **town.rbxl** (lighting
favourite), **rpg map.rbxl** (build-method favourite) and Roman Battleground. Measured facts + asset ids:
`reference-maps.md`; raw study notes (long, untracked): `Claude outputs/reference-maps/*.md`.
This guide is the canon for HOW to build; the layout of each map comes from the user.

## 1. The look in six lines
1. **Terrain is the floor, meshes are everything vertical.** Flat-ish terrain tiers (grass, sand paths, water);
   every cliff face, mountain, wall and landmark is a mesh. Mountains are NOT terrain.
2. **A small mesh kit, used hundreds of times.** 5-8 rock meshes make every boulder, slab, cliff and mountain
   (rpg: 506 rocks from 43 meshes, 8 meshes = 75 %). Variety comes from scale, rotation and flipping.
3. **Buildings are many meshes (and Parts) in one Model**, never one baked mesh: shell pieces split by material +
   a shared library of window/door/railing/bracket modules + plain Parts for boxes.
4. **Tiling stylized MaterialVariants + Color tints** carry most surfaces; SurfaceAppearance is for rocks,
   foliage and hero props.
5. **Chunky, saturated, warm**: 2-3x real-world proportions, orange tile roofs, green/yellow/red trees, glowing
   Neon windows, cream-tinted grade.
6. **Atmosphere haze dissolves the distance** into a teal-milky sky; a tiny global Blur softens it all.

## 2. Lighting recipe -- "town haze" (the user's favourite; exact town values)
| Knob | Value | What it does |
|---|---|---|
| LightingStyle / PrioritizeLightingQuality | Realistic / true | = old Future. **Not scriptable -- set by hand in Studio.** |
| Brightness | 2 | sun strength |
| Ambient / OutdoorAmbient | 65,65,65 / 128,128,128 | high outdoor fill = lifted, readable shadows |
| EnvironmentDiffuseScale / SpecularScale | 0 / 0 | no sky IBL, no reflections -> textures read matte, hand-painted |
| GlobalShadows / ShadowSoftness | true / 0 | crisp sun shadows (rpg uses 0.2) |
| ClockTime / GeographicLatitude | 12.4 / -1.97 | sun ~64 deg up; keep ClockTime STATIC (moving sun breaks the shadow cache) |
| Atmosphere | Density 0.286, Offset 0, Color 110,170,165, Decay 248,255,254, Glare 0.06, Haze 1 | **THE haze**: teal mist, milky-white away from the sun, far objects fully dissolve |
| Sky | 6 painted faces 11832302094 / 01800 / 01591 / 01424 / 01165 / 08453, SunTextureId 0 | blue sky, soft cumulus, no sun disc |
| ColorCorrection | Brightness 0, Contrast 0.2, Saturation 0.2, Tint 255,241,192 | warm cream "storybook" grade + punchy colour |
| Bloom | Intensity 0.25, Size 50, Threshold 3.25 | faint wide halo on Neon windows / lamps only |
| SunRays | 0.25 / 1 | god-rays through canopies |
| **Blur** | **Size 4** | the "slightly blurry" softness |
| Fog | ignored | Fog* is hidden/ignored whenever an Atmosphere exists |

**Why distant things look hazy AND slightly blurry (measured, B172):** the haze is 100 % Atmosphere (Density +
Haze 1 + Offset 0). The blur is the global `Lighting.Blur` Size 4 -- a uniform screen blur, not distance-based. It
reads as distance blur because far objects are small and already low-contrast, so 4 px erases their detail while
near shapes survive. The `DepthOfField` in town's Workspace is disabled AND outside Lighting -> renders nothing.
rpg map has the same Atmosphere/grade but Atmosphere Color 206,236,255 (paler, bluer), Brightness 3, Ambient
70/70, EnvDiffuse/Specular 1, ShadowSoftness 0.2, ClockTime 14, and **no Blur** -- crisper.

**Our variant (recommended, test it):** keep the town stack but swap the global blur for a distance blur so the
tower-model stations, nameplates and prompts up close stay crisp: `Blur` 0-2 + a `DepthOfFieldEffect` UNDER
Lighting with FocusDistance 0.05, InFocusRadius 60-120, FarIntensity 0.1-0.2, NearIntensity 0. Blur probably also
softens SurfaceGui/BillboardGui text -- check.
- **Device rule:** Atmosphere + ColorCorrection survive on every device; DoF, Bloom, SunRays and shadows (off below
  quality 4) are PC/console bonuses. The map must read well with them gone. Never rely on DoF for readability.
- **Map size:** town's buildings/mountains sit 300-1500 studs from the camera. A compact lobby (~300-600 studs)
  needs Density ~0.32-0.38 for the same falloff; raise Offset 0.1-0.3 if the far skyline vanishes.
- **Day vs night is the user's call:** the current Lobby is NIGHT (B134, `lobby-map.md`). Town haze = day.
  Lit windows still sell "life" at noon: Neon 255,255,0 / 239,184,56 panes + Bloom threshold 3.25.

## 3. Terrain + mesh composition rules
1. Terrain in **flat tiers** (rpg: y 3 / 70 / 100-140 / 270 / 340): Grass + LeafyGrass, Sand/Pavement for paths,
   Water. Terrain Rock only as a few scree patches (1 % of rpg's surface).
2. **Rocks cover every tier step**: line the step with rocks, sink 40-70 % below the upper surface, terrain grass
   runs straight into them (no Rock-material blend). To make a cliff-topped plateau, fill terrain grass up to the
   rock tops: rock = wall, terrain = floor.
3. **Seams are hidden by props, not blending**: bushes at every rock foot and trunk base (rpg: 157 bushes within 15
   studs of a trunk, 111 hugging rocks), flat leaf piles under canopies, leaf-clump "moss caps" on boulders.
4. Terrain material overrides go through MaterialService (`GetBaseMaterialOverride`): rpg/town override Rock,
   Sand, Pavement (+ Cobblestone, Ground, Limestone, Sandstone, Snow in rpg); grass keeps Roblox's default with a
   strong tint (rpg 0,85,0; town 122,138,68). Terrain grass decoration ON.
5. **Water**: big still water = terrain water (WaterColor 12,84,92 to 65,98,98, Transparency 0.3, Reflectance 1,
   WaveSize 0.15, Speed 10). Town also fakes a stylized canal with 4 stacked translucent layers (Neon 45,69,98 T0.5 /
   SmoothPlastic 27,42,53 T0.7 / Foil 13,105,172 T0.5 / Glass + SA T0.15). **The Lobby keeps its terrain water.**
6. Layout boundary = mountains/cliffs and the sea; distant backdrop pieces can sit in the void past the terrain edge.

## 4. Rock kit + mountains (the user's theory -- CONFIRMED with numbers)
- **Kit:** 6-8 meshes sharing ONE texture set (ColorMap + NormalMap, near-white albedo so `SurfaceAppearance.Color`
  tints per biome: 145 grey cliffs, 255,251,221 warm). Shapes: chunky boulder (~1:0.8:1.2), tall rock (~0.6:1:0.65
  -- also squashed into slabs), faceted column, wide cliff chunk, stackable pillar segment (flat top/bottom), one big
  mountain mass with a strong silhouette, one low flat slab.
- **Variety from transforms:** scale 0.3x-6x of native; squash the tall rock to Y ~0.2 of XZ for ledges/steps (rpg
  did this to 55 of 109 copies); stretch columns x2-2.5; flip 180 deg on Z for a new silhouette (29 of 65 SM_Rocks);
  random yaw always; tilt only small rocks; mountains/cliffs never tilted.
- **Piles:** big upright core (2-6 pieces) + flat slabs spilling forward + 3-8 small chunks at the tail; pieces
  interpenetrate (centre spacing 0.5-0.9x radius); copy-paste of identical sizes is fine.
- **Mountains:** ONE big mesh copied 15-30x, each a different yaw, overlapping ~40 %, 2-3 tiers rising to the
  back, ~50 % buried below ground/sea, nothing inside (shells). rpg north hill = 31 copies of `aa`.
- **Spires:** stack 4 copies of the pillar segment, the 2 middle ones flipped 180 deg, base 5 % wider.
- Town does the same with faceted low-poly `stone*` meshes stacked vertically into crags (38 pieces).
- Settings: Anchored, Material Plastic, SA AlphaMode Overlay; CastShadow on foreground, OFF on huge distant walls;
  CollisionFidelity Hull where walked on, Box elsewhere, invisible Box blockers for big walkable faces.

## 5. Trees + foliage
- **2 MeshParts per tree**: `Trunk` (trunk + main branches, collides) and `Leaves` (ALL clumps merged, CanCollide/
  CanQuery/CanTouch false, CollisionFidelity Box). That is how both reference packs are built.
- **Leaves = alpha cutout**: SurfaceAppearance AlphaMode **Transparency**, MeshPart.Transparency 0 (stays in the
  opaque pass). Card-cluster canopies need DoubleSided true; Yasu-style blob shells don't.
- **Colourless textures tinted by `SurfaceAppearance.Color`** (= our white-tint rule, `white-tint-art.md`). Town's
  colourful look is ONE leaf texture (Yasu 13255359293) tinted green 0,104,0, yellow 255,255,0, orange 255,85,0;
  bark = Yasu Bark_Chestnut tinted 110,70,45. rpg uses darker greens (0,63,0 / 0,85,0 / olive 93,107,28).
- **Stylized shading:** in Blender transfer normals from a smooth proxy hull onto the leaf cards (Data Transfer ->
  Custom Normals) so a crown shades as one soft volume. rpg also puts a white-square image (5168609593) in the leaf
  SA's Normal/Rough/Metal slots, which yields soft, dark, matte crowns -- A/B test before adopting.
- **Variety:** 3-5 crown shapes x 3 scale steps x random yaw (rpg forgot yaw on its 81 IHasAdamsApple trees);
  a few tint variants per mesh, not one per copy.
- **Dressing:** bushes (rpg New_Bush3: 300 stamped with Brushtool 2 -- random yaw, scale 0.8-1.1, align to surface
  normal, ~30 % sunk), leaf piles (flat 0.12-thick card, several tints), hedge blobs on balconies/roof edges, flower
  pots by NPC stands, falling-petal emitter (rate 50, life 8-12, accel 0.5,-1,0.5) for accent trees.
- **Scale for the Lobby** (R15 = 5 studs): hero tree 50-80, framing trees 25-45, background giants 100-160, bushes
  6-12 wide. (The references are epic-scale: median tree 180 studs.)
- **Wind:** none in the references (WindShake tags left without the module). Optional later: boatbomber's WindShake
  client module + `WindShake` tag, WindSpeed ~15, WindPower 0.1-0.2.
- Best source: **Yasu's Stylized Tree Pack** (Creator Store 79689531752352, free, no scripts) -- insert it from the
  Toolbox, never paste it from a reference file.

## 6. Buildings = modular multi-mesh kits (three layers, one Model)
1. **Shell split by material**: model the hero building in one Blender scene, export ONE object per material ->
   MeshParts sharing a pivot (rpg HOUSE2 = wall body, timber frame, windows, 5 glass, roof, roof-stone trim, door).
   Each piece = Material Plastic + a MaterialVariant + a Color tint.
2. **Shared module library** reused and scaled per building: window (frame + pane as separate meshes), door (frame
   + leaf + dark interior plane), railing + damaged railing, bracket, dormer, bevelled cube/cylinder/beam/arch,
   lamp. rpg: one window frame mesh used 134x across 24 buildings; one bracket 90x. Town: one bracket 411x.
3. **Plain Parts for boxes**: wall slabs, floor plates, 1.2-stud posts, 45 deg roof planes, gable Wedges, all with
   MaterialVariants (the half-timber look is Parts in a bark-textured variant).
- **Stylise:** storey 12-15 studs, door 10-11 (2x the character), jettied upper floors 2-3 studs wider, steep roofs
  with overhangs, a stone skirt at the base, Neon-lit + dark Glass panes mixed, greenery under windows, slightly
  crooked planks, an all-face grime Texture overlay (tint 186,207,205, 20-stud tiles) on stone.
- **MaterialVariant trick:** most structural variants sit on BaseMaterial **Plastic** with descriptive names (WOOD1,
  CONCRETE WALL, ...); a variant applies ONLY when Part.Material == its BaseMaterial. Part.Color multiplies the
  texture: 248 = as painted, default 163 = 35 % darker, any tint = a new look (CONCRETE WALL + 255,255,204 = cream
  stucco). Walls/wood StudsPerTile 10, floors 20-30, roof tiles 40.
- Filipino adaptation: bahay na bato (stone ground floor + jettied timber upper + capiz windows), bahay kubo
  (bamboo/nipa kit), baybayin rune pillars (rpg's rune pillar with Neon glyph strips), parol street lamps.

## 7. Props, lights, VFX
- Existing user rule stands: props are stylized meshes, light sources get particle VFX (`lobby-map.md` presets),
  never part-built poles/neon bricks/discs.
- Lamps: post + lantern meshes, Neon bulb, PointLight Brightness 1, warm 255,241,161 or slightly random oranges,
  Range 24-40, **Shadows off on most** (the references' 43-83 shadowed r120 lights are too expensive).
- Roman Battleground: ground-fog = huge flat slabs (2048x7x2048) at Transparency 0.95 laid over the valley; torches
  = 65 flame emitters (rates 5 + 20). Mountains = 7 giant terrain-chunk meshes. Borrow the fog slab for low mist
  over the Lobby water; skip its part-built arenas.

## 8. Blender pipeline (summary; importer gotchas in `docs/systems/maps-apolaki.md`)
1. Kits first: rock kit, tree kit, building module kit, then hero shells. Each mesh <= 20k tris (repeated props
   <= ~4k; trees 1-4k trunk+leaves), bevel 2-3 segments for chunky edges, one material + one UV set per mesh.
2. Textures: hand-painted/stylized, near-white where tintable (white-tint rule), 512-1024 (leaf atlas 1024 with
   alpha). Trim sheets/tiling MaterialVariants for buildings.
3. Export each unique mesh ONCE; build mountains/forests/towns in Studio by duplicating (identical MeshId + same SA
   = instanced into one draw call). Scale in Studio; Blender scale doesn't matter.
4. Hero shells export split by material (FBX, one object per material slot) via the 3D Importer.
5. Studio AI mesh generation remains fine for one-off props (`lobby-map.md` working notes: <= 4 jobs at once).

## 9. Performance budget (mobile + console + PC; every feature ships on all three)
- Target <= ~500 draw calls and <= ~500k scene triangles on phones (Shift+F2 at lowest and highest quality).
- Decor: Anchored, CanCollide/CanTouch/CanQuery false, CollisionFidelity Box (collision memory exists even when
  CanCollide is off), CastShadow false on small/distant items, RenderFidelity Automatic (never Precise).
- Reuse meshes and textures; vary with MeshPart.Color; few tint variants. Few Decals/Textures (they don't batch).
- Particles: low rates (mobile caps 100/s per emitter), each emitter ~1 draw call.
- Background mountains: `Model.LevelOfDetail = StreamingMesh` if streaming is on.

## 10. Asset reuse rules
- **SECURITY:** rpg map (3 copies) and town (13 copies) contain a free-model **backdoor** Script named `<null?>` in
  `window1.003.Cube.074` (remote `require` via HttpService on live servers). Before pasting ANYTHING from a reference
  place, delete every LuaSourceContainer in it; never copy the "curve" towers or `window1.003` as-is.
- Pasted assets keep their ids; they load only if Open Use (most pre-Oct-2025 uploads) -- Play-test and watch Output
  for permission errors. Loading is not licence: the rpg/town building kit + MaterialVariants are TETRA9K uploads
  and the round-crown trees IHasAdamsApple's (unpublished pack) -- **ask the user about provenance before shipping**.
- Prefer: Creator Store inserts from the Toolbox (Yasu pack), our own Blender uploads, Studio-generated meshes.
- Cliff04/05 carry CollectionService tags `CLIMABLE`/`AREA_SURFACE` -- strip on copy. Audio never carries over.

## 11. Lobby rebuild checklist (waiting on the user's layout)
1. Archive the current `Workspace.Lobby.Map` (like `_OldLobby_B134`); keep `Workspace.Lobby` itself
   (`SettingsConfig.Place()` detects the Lobby by it), the terrain WATER, `PersistentScene` + PlayGUICamera
   (user's framing), SpawnLocation, `LobbyMapService` (water rescue needs terrain Water + plaza target).
2. Build from the user's layout: terrain tiers -> rock kit edges/mountain ring behind the water -> trees + bushes
   -> stations.
3. NPC stations (Shop, Craft, Trait, Stat, Evolve, Ascension, Challenge, Guide...) become **tower models from
   `RS.UnitModels`** (full R15 size, `IdleAnim` attribute) -- every NPC lookup is by name and `NpcPromptRouter`
   routes the prompts, so keep the `NPC_*` names/prompts when swapping the rig.
4. Lighting: choose day (town haze) or keep night; set LightingStyle by hand.
5. Update `lobby-map.md` (it describes the B134/B139 night map) and `areas.md` travel spots when the new map lands.

## 12. Open questions for the user
- Where did the three .rbxl files come from (licence to reuse their meshes/textures)?
- Day haze (town) or keep the night lobby? Global Blur 4 or the crisp-near DoF variant?
- Which reference assets to reuse directly (Yasu trees via Toolbox are safe) vs rebuild in Blender?
- Should the 3+13 backdoor scripts be deleted from the reference files (recommended)?
