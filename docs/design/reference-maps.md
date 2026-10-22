# Reference maps -- measured facts (town.rbxl, rpg map.rbxl, Roman Battleground.rbxl)
<!-- owner: AD-Lobby | scope: all maps + Lobby | last-verified: 2026-10-22 (B172) -->

Read-only study (B172) of the three user-supplied reference places (local files, not Alamat Defense Places).
The HOW-TO is `stylized-environment.md`; this doc holds the numbers and ids. Long raw notes (every id, cluster
tables, MaterialVariant maps): `Claude outputs/reference-maps/*.md` (untracked). All ids are `rbxassetid://<n>`.
**Both town and rpg map contain a backdoor Script `<null?>` inside `window1.003.Cube.074` -- strip scripts first.**

## 1. Lighting side by side
| | town (user's favourite) | rpg map | Roman Battleground |
|---|---|---|---|
| LightingStyle / Prioritize | Realistic / true (was Future) | Realistic / true (was ShadowMap) | Soft |
| Brightness | 2 | 3 | 1 |
| Ambient / OutdoorAmbient | 65 / 128 grey | 70 / 70 grey | 30,30,60 / 40,40,60 (blue) |
| EnvDiffuse / EnvSpecular | 0 / 0 | 1 / 1 | 1 / 1 |
| ShadowSoftness | 0 | 0.2 | 0.2 |
| ClockTime / latitude | 12.4 / -1.97 | 14 / -24.5 | 6.7 (dawn) / 0 |
| Atmosphere | D 0.286, Off 0, Color 110,170,165, Decay 248,255,254, Glare 0.06, Haze 1 | same but Color 206,236,255 | none |
| ColorCorrection | C 0.2, S 0.2, Tint 255,241,192 | same | none |
| Bloom | 0.25 / 50 / 3.25 | same | none |
| SunRays | 0.25 / 1 | same | none |
| Blur | **4** | none | 5 |
| Sky | 11832302094 (Bk) 01800 (Dn) 01591 (Ft) 01424 (Lf) 01165 (Rt) 08453 (Up), sun 0, moon 4774580371 (FlipGalaxy) | same skybox | Bk 15502525195, Up 15502526102, default sun |
| Inactive extras | Workspace.DepthOfField (disabled, wrong parent): Far 0.1, Focus 0.05, Radius 30 | Workspace.Lighting Folder (DOF/Bloom/CC/SunRays, inert) | -- |
| Scripts touching lighting | none | none | -- |
Lights: town 83 PointLights (B1, 255,241,161, r30/120, shadows on) in STREETLIGHTs; rpg 54 PointLights + 4
SpotLights (43 lamps, warm 255,170,0-ish, r36-120). Lamp bulb = Neon 239,184,56 (mesh 126585791252274).

## 2. rpg map -- rocks (user theory confirmed)
506 rock instances from 43 meshes; 8 meshes = 75 % of instances; Cliff04 + `aa` + SM_Rocks_03 = 98 % of rock
volume. Terrain covers only 18 % of the footprint; surface Grass 81 %, Sand 7 %, LeafyGrass 6 %, Rock 1 %.
| Family | MeshId | native size | n | use / textures |
|---|---|---|---|---|
| Stone_1_Low | 114234508497426 | 34x26x40 | 59 | boulders, scale 0.4-6.1 |
| Stone_2_Low | 94937447553034 | 58x43x58 | 1 | |
| Stone_3_Low | 140671655633285 | 54x98x33 | 3 | thin slab |
| Stone_4_Low | 71879767155599 | 55x117x65 | 21 | spire, often squashed |
| Stone_5_Low | 128054050953031 | 104x166x107 | 109 | 55 squashed to slabs |
| (Stone kit SA) | -- | -- | -- | Color 126792963829366, Normal 73061542094917, Overlay |
| `aa` mountain | 118750485888168 | 1654x2048x1666 | 51 | scaled 0.1-0.4; SA A 100937791108436/N 135515246668044; SA B 9314699815/N 9314699352 tint 145 |
| Cliff04 | 9299306835 | 22x15x25 | 44 | border walls ~346 cube, scale 11-52; Tex 9299307138 + SA 9314695918/N 9314695381 tint 145; CastShadow off; DoubleSided |
| Cliff05 | 9299306242 | 28x15x22 | 34 | pillar segments, stretched x2.2-2.6, 12 flipped; SA 9314699815 |
| SM_Rocks_03/05/09 | 104571432189116 / 89689849404094 / 114549160373620 | 218x89x161 / 90x115x90 / 88x160x74 | 24/13/14 | baked Tex 127729096235698, 29 of 65 flipped |
| Rocks_07 column | 17719603894 | 307x485x292 | 39 | canyon walls, PBR SA 17719604008/038/3977/3883 tint 255,251,221 |
| Rock_Preset_01..05 | 17723512087+135, 077+089, 253, 215+073, 173+178 | -- | 45 | ready 2-piece combos, uniform scale |
| Pebbles | 118496447203890 ... 80212625707398 | 11-16 studs | 16 | Tex 87985955355745 |
Mountain/cluster facts: north hill = 31 copies of `aa` (18 at identical 248x245x303, 13 yaws), median 48 % buried;
west wall = 19 Cliff04 all yaw 147; Cliff05 spire = 4 stacked copies (2 middle flipped) ~330 tall. Foreground piles:
pieces interpenetrate (NN 0.46-0.87), sunk median 41-88 % into terrain, 1.5x-80x size spread per cluster.
61 % of Stone_Low rocks sit on a terrain step; rocks are not blended with terrain Rock -- bushes hide the seams.

## 3. rpg map -- trees and foliage
- 99 trees, each = 2 MeshParts (trunk collides; one merged leaf mesh, no collide/query/touch).
- **IHasAdamsApple round-crown trees** (81, `Workspace.Folder.treeN`, unpublished pack): leaves/trunk mesh pairs
  tree4 15052636611/648, tree7 15052623614/527, tree13 15052613747/737, tree6 15086052406/403, tree5 15052630407/421,
  tree11 15052604728/692, tree8 15086067636/654, tree9 15052619575/523, tree2 15086058565/551, tree10
  15086078640/691, tree12 15052585352/370. Leaf SA Color 14723149780 + 5168609593 (white square) in N/R/M,
  Transparency, DoubleSided true. All share one yaw (no rotation variety).
- **Yasu's Stylized Tree Pack** (Creator Store 79689531752352, mvyasu, free; 20 trees, 3 bushes, 5 roots, 5 leaf
  meshes, 128 colourless leaf textures, 5 bark variants): Tree_17 canopy 18720368719 / trunk 18720368738,
  Tree_20 18720382214/207, Tree_09 18720274956/962, Tree_08 18720273012/005, Tree_11 18720340885/897. Canopy
  Material LeafyGrass, DoubleSided false, Box. Original leaf tex Leaves_01_4 13255359293 (+Rough 13244568809).
- Bark SAs: Chestnut 18718140279/141790/141344 tint 110,70,45; Grooved 18718123628/124198/124854 tint 106,80,65.
  Bark MaterialVariants (Birch/Cracked/Grooved/Walnut/Chestnut, base Wood) sit inert in the pack folder.
- Dressing: New_Bush3 15052907163 (x300, ~19x10x18, Brushtool-stamped), New_Bush4 15052964966 (x15),
  Bush_Canopy_03 18721169682 (x195, hedge blobs on balconies/roof edges, flipped 180), Leaves_Pile_01 14398344679
  (x48, flat card, tints 0,85,0 / 0,63,0 / 93,107,28 / 255,170,0), Leaves_Shape_01 13280943200 + _03 13330737475
  (moss caps on rocks, tint 0,63,0), flowers Pink 17588266286 (SA 17599236876) / Blue 17588266283 (SA
  17599217757), mushrooms 17610161213/235/247, logs 17600162684/689, roots 18720918946 / 18720932524.
- Brushtool 2 settings survive in `ServerStorage.Brushtool2_Plugin_Storage` (stamp: yaw 0-360, scale 0.8-1.1,
  orientation Normal). FallingPetals emitter: tex 243660364, pink->white, rate 50, life 8-12, speed 2-4, accel
  0.5,-1,0.5, drag 0.5, on a 100x1x100 invisible part. Terrain grass decoration ON; no wind script.

## 4. rpg map -- buildings and materials
- 401 MeshIds; building meshes are a custom Blender kit by TETRA9K (2025-09..2026-03). 4,710 built BaseParts:
  2,439 MeshParts, 2,171 Blocks, 79 Wedges, 16 Unions.
- Methods: (A) shell split by material -- HOUSE2 (11 meshes: wall body BRICKWALL, Wood Frame WOOD2, Windows, 5
  Neon/dark glass, Roof 86,66,54, Roof Rocks RED CONCRETE, Door); HOUSE4/HOUSE5/GATE/welll/STREETLIGHT likewise.
  (B) Parts + modules -- timber house: Block storeys 26.2 / 32.0 / 35.0 wide (jettied), 12.7-15.3 tall, WOOD2 tint
  152,194,219 timber Parts, 45 deg RoofShingles/`stylized roof` planes, 17 window modules, 2 door modules.
  (C) shell meshes + modules + 30-35 hedge blobs under windows (stucco/tower halls). (D) one bevelled cube
  135986399393687 scaled into pillars and 136 stepping stones. (E) pure Parts for stairs, plank bridges
  (each plank pitched -2..-10 deg), crates (avoid: 225 parts + 1,080 decals).
- Reused modules: window frame 134492809058773 + pane 108202581954183 (134 uses, 24 buildings); bracket
  116718367483062 (90); opened-square window set 120002811232221, 139074093511012, 111620697221566,
  136028260532995, 134533993012582, 129326119012228; tall window set 93644918273381, 93955004623392,
  135547290892650, 72108316229235, 102241241859731, 135828648292597; door 126892940562365 / 128147169514001 /
  140688442117046; railing 129009353349722 (+ damaged 75311836090438 / 90300018514414); beam 132257754125609.
- Other props: market stall (Cube.042 group, 16x13x20, blue awning 4,175,236), welll, flowerpot, fountain
  86768077492076 (SA 111254036124650), rune pillar (MOSS BRICKWALL + 5 Neon 0,255,0 glyph strips).
- Overlay grime Texture 101357393903068 (Color 186,207,205, 20x20 studs, all faces) on stone; paving Texture
  93743169690770.
- **MaterialVariants (40, TETRA9K stylized 2k PBR sets).** Plastic-based: WOOD1 123810991813559 (bark_01, 504
  parts), WOOD2 76737748571584 (bark_05, 636), wood3 134989588023101 (243), wood plank 135645455601251, CONCRETE
  WALL 138336571039209 (840), CONCRETE FLOOR 113490938270736, BRICKWALL 133252653525922, MOSS BRICKWALL
  132688548790841, bluebrick 101681420848018, floortiles 108926294879902, marble tiles 107846221979768. Others:
  `stylized roof` RoofShingles 70432103514666 (StudsPerTile 40), roof1 73994935562315, RED CONCRETE (Concrete)
  99228171540697, cobblestone2 77018700280612, log2 (Wood) 86159966258823, brick3/brick4/floor (Cobblestone,
  Gemini-generated). Terrain overrides: Rock->rock1 130005232060347 (30 spt), Sand->sand 87976912053299,
  Pavement->pebble 134423037907388, Cobblestone->test, Ground->ground2, Limestone, Sandstone, Snow, Salt.
- Palette: default grey 163 (texture shows darker), brown 86,66,54, timber tint 152,194,219, white 248, dark iron
  27,42,53, cream stucco 255,255,204, ochre 239,184,56, lit window 255,255,0, green shutters 75,151,75.
- Scale: door 10-11, storey 13-15, timber house 52-59, tower hall 164, GATE 267, streetlight 17.5 (R15 = 5).

## 5. town -- what differs from rpg map
- Same builder kit as rpg (identical window/door/railing/bracket/STREETLIGHT MeshIds and the same MaterialVariant
  library); 328 MeshIds, ~9,000 BaseParts; ground y ~900-940, footprint X -1252..289, Z 101..835 (core).
- **Trees = Yasu pack, recoloured**: Canopy_01/03/04/07/15/17 + Trunk_01/03/04/07/15/17, leaf tex 13255359293
  tinted **0,104,0 (green), 255,255,0 (yellow), 255,85,0 (orange-red)**; bark Chestnut 18718140279 tint 110,70,45;
  canopies 80-425 studs. New_Bush4 x21 (tint 110,140,44), Bush_Canopy_03 x35, Leaves_Pile_01 x52.
- Rocks/mountains: faceted low-poly `stone*` meshes (stone10/15/18/19/39/43/47, StonePile3; 38 pieces, 250-1250
  studs) stacked vertically into crags at the map edge; `Rocks_Stylized` SM_Rocks_01..11 (tex 116625740935129) as
  mid-ground boulders. Terrain surface: Grass 76 %, Pavement 9 %, Water 7 %, Sand 4 %, LeafyGrass 2 %, Rock 2 %.
- Terrain overrides: Rock->rock1, Sand->sand, Pavement->pebble; Grass colour 122,138,68, LeafyGrass 106,134,64.
- Canal water model: 4 stacked translucent layers (section 3.5 of the guide); terrain water 12,84,92.
- Look (screenshots, B172): orange-red chunky tile roofs, cream/tan half-timber walls, yellow-lit windows,
  saturated green/yellow/red round trees, grey faceted crags, teal-milky horizon that swallows the sea and the
  far skyline; everything slightly soft.

## 6. Roman Battleground (lower priority)
- Soft lighting at dawn (ClockTime 6.7), bluish ambient + ColorShift, Blur 5, no Atmosphere.
- Mountains: 7 giant meshes (up to 2048x1026x2048) with SA 11386647751 / 11386606249 -- whole terrain chunks.
- Ground fog: 7 flat MeshParts 2048x7x2048 at Transparency 0.90-0.95, y 93, over the valley.
- Main Arena: 65 torch flames (emitters tex 242461088 rate 20 + 242255193 rate 5), candle fill lights; arenas
  are part-built (1,800+ Parts, 2,051 WeldConstraints) -- not our style.

## 7. Worth reusing (after stripping scripts; check licence + Play-test for permission errors)
| What | Where | Note |
|---|---|---|
| Yasu's Stylized Tree Pack | Toolbox insert 79689531752352 | safest: free, no scripts, colourless leaves |
| Stone_1..5_Low rock kit | rpg Workspace (loose Models/Folder) | foreground rocks, slabs, path borders |
| `aa`, Cliff04, Cliff05 | rpg Workspace.aa / Workspace.world | mountains, border walls, spires |
| Rock presets / Rocks_07 | rpg Workspace.Rocks | quick boulder combos, columns |
| Bushes / leaf piles / moss caps | rpg New_Bush3/4, Leaves_Pile_01, Leaves_Shape_01/03 | seam dressing |
| Window/door/railing/bracket modules | rpg timber house Model (75,157,2710) | building kit |
| Market stall, welll, flowerpot, rune pillar | rpg | station dressing |
| MaterialVariants (WOOD1/2, wood3, CONCRETE WALL, stylized roof, ...) | rpg MaterialService | tiling building surfaces |
| Town lighting stack + skybox | town Lighting | exact values in section 1 |
| FallingPetals emitter | rpg Workspace.FallingPetals | recolour for accent trees |
Do NOT copy: the "curve" towers / `window1.003` (backdoor), crates+barrels (225 parts), Roman part-built arenas.
