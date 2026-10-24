# B172 Lobby rebuild -- "Holy Coast" -- PLAN + PROGRESS (resume file)
<!-- owner: AD-Lobby | READ THIS FIRST when the user says "continue" after a usage-limit reset.
     Update the STATUS list after every milestone (usage limits WILL cut sessions short). -->

## The ask (user, B172)
- Rebuild the Lobby like their reference screenshots (Anime-Vanguards-style coastline + island: arched rotunda
  spawn island in a bay, grand bridge, terraced coast plaza ringed by big buildings, cliffs/waterfalls, rocks in
  shallow water) but a **HOLY version** in our own Alamat style (white marble, gold, turquoise tile, sun halos).
- Build style = `docs/design/stylized-environment.md` (terrain floor + reused mesh kits, town-haze lighting).
- KEEP the terrain water. NPC stations = tower models (RS.UnitModels). Blender + Studio both allowed.
- Mid-task (B172): "make the land larger, and at the end of it huge mountains or structures ... for depth".
- Expect usage limits: keep this file current; commit often.

## Coordinates (Roblox studs; north = -Z; sea surface Y 4; water band Y -4..4, deeper basin in the bay)
| Thing | Where |
|---|---|
| Spawn rotunda ("Isle of Light") | centre (-300, deck 40, 420), deck r 56 (Part `Map.Core.SpawnDeck`); SpawnLocation (-300,40.5,448) |
| Grand bridge | x -300, deck 40, z 364 -> 154 (Part `Map.Core.BridgeDeck` collider, 24 wide) |
| Coast plaza | disc centre (-300, 40, 0) r 178 (terrain Pavement = AL_HolyPlaza2); front edge = sea wall |
| Temple terrace | Y 60 for z <= -120, abs(x+300) < 320; terrace wall line z = -120 |
| Temple of Bathala (Summon) | (-300, 60, -230) facing south; prompt OpensEvent=OpenSummon |
| Ascension (Bathala_Ascended) | NPC (-520, 62, -190); Spire behind at z -235 |
| Evolve (Apolaki_Zenith) | NPC (-80, 62, -190); Sun Rotunda pavilion |
| Stat reroll (Babaylan) | NPC (-530, 43, -20) faces east; Star Forge |
| Trait reroll (Lakapati) | NPC (-700, 40, -110) faces east; Moon Shrine |
| Shop (Magwayen) / Craft (Handyong) | NPCs (-70, 41, 10) / (-70, 41, -40) face west; Bay Bazaar stalls east of them |
| Guide (Bathala) | NPC (-322, 40, 398) on the rotunda |
| Challenge (Urduja) | arena: PLAN = raised arena on an arcade at (140, deck 40, 400) + bridge from the rotunda east edge; NPC now at (140,12,380) -> move to deck |
| Sun Citadel (scenic, framed by PersistentScene.PlayGUICamera) | NE mesa (300, 78, -330) |
| Colossus (winged sun goddess, AI mesh) | (-300, ~62, -640), 433 tall, `Map.Backdrop.Holy.Colossus` |
| Sky islands (AI mesh) | `Map.Backdrop.Holy.SkyIsland_*` NW/NE/W/E |
| Mountains | ellipse rim MAIN_C (-300,-300) R (1250,760): near ring k .88-.95 (warm), far ring k 1.12-1.25 (lavender) |
| Sea stacks | arc r 1350-1750 around the bay centre (-300,420), south horizon |
| User's own south area | Workspace root x -700..200, z < -1450 -- DO NOT TOUCH |

## Tools (repo) -- all paste into execute_luau (Lobby, Edit) unless noted
- `B172_terrain.luau` terrain (WriteVoxels, CHUNK loop) · `B172_backdrop.luau` mountains + sea stacks ·
  `B172_groves.luau` Yasu groves · coast rocks were inline (Map.Nature.CoastRocks, 215) ·
  `B172_harvest.luau` imported GLBs -> `B172Protos.Kit.<Piece>` + sky · `B172_assemble.luau` (TO WRITE/RUN).
- Blender (outside repo output `Downloads\Alamat_Lobby\{tex,glb,renders,blend}`): `tools/maps/lobby/{common,textures,
  kit_arcade,kit_sacred,kit_ground,split_heavy}.py`. Run: `"/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
  -b <blend> --python-expr "exec(open(r'<script>').read()); ..."` (execute_blender_code_for_cli is BROKEN: no BLENDER_PATH).
- Kit pieces + sizes: `Downloads\Alamat_Lobby\glb\AL_Kit{A,B,C}.json` (A arcade/pier/column/balustrade/bridge/wall,
  B sungate/dome pavilion/temple/spire/halo/finial/sundisc/crystal, C stairs/dais/mandala/lamp/parasol/planter/banner/stall/fountain).

## Backups (everything reversible)
- `ServerStorage._OldLobby_B139`: old `Map`, `RootDressing` (old palms/torii/etc.), `Terrain_B139` (TerrainRegion;
  PasteRegion at attribute CornerCell), `Lighting_B134` (old night lighting children + scalars as attributes).

## STATUS (update every milestone)
- [x] Old map archived; new `Workspace.Lobby.Map` with `Travel` (all AreasConfig arrival names kept), `Core` decks
- [x] Terrain v4 (larger land, rim ridge, beaches, seabed shallows, sea extended to the horizon)
- [x] Lighting "holy day": HolyHaze / HolyGrade / HolyBloom / SunRays / DistanceSoftness(DoF) / HolySoftness(Blur 2);
      EnvDiffuse/Specular 0; Sky = Roblox default + Terrain.Clouds (until the seamless carrier sky is imported)
- [x] Materials AL_HolyPlaza2 (terrain Pavement override), AL_HolyMarble2 (decks)
- [x] Mountains (near+far rings) + sea stacks, SM_Rocks given tintable SA; coast rocks; 282 trees (Yasu pack in Protos)
- [x] NPC stations = tower rigs (Server.Lobby.NpcIdle plays idles); AreasConfig names/descs updated; LobbyMapService text
- [x] Colossus + 4 sky islands (AI meshes, protos in B172Protos.AIGen)
- [x] Blender kit A/B/C exported (all meshes < 20k tris) + AL_SkyCarrier.glb (seamless elevation-gradient sky)
- [x] USER imported the 4 GLBs (importer names roots "Scene"; sky planes = Plane/.001/.002)
- [x] B172_harvest.luau + B172_assemble.luau WRITTEN (not run yet; assemble has SECTIONS list, re-runnable per section)
- [x] Harvest run (24 pieces in B172Protos.Kit, HolySky = carrier images) + assemble run (all 11 sections OK)
- [x] Re-run with DECK=42 / TER=62 (terrain tiers written at 40/60 SURFACE at 42/62); Core decks + spawn +2; plaza mandala visible;
      haze lightened (HolyHaze D .21 H .55 Off .32); sky islands NW/NE removed (orange undersides). Screens: spawn, plaza, aerial OK
- [x] Dressing (`B172_dress.luau` -> Map.Dressing): 90 bushes/planters, fountain water + spray, gold motes, station sigils/auras
- [ ] Twin waterfalls from the plaza sea wall (clone `_OldLobby_B139.Map.Waterfall.MainFalls`, move Source/Plunge)
- [ ] Plaza dressing (bushes at rock/structure feet, planters, parasols, banners), arena bridge, waystones (optional)
- [x] Play test 1 (after assembly): spawn on deck (Y 46), walk path continuous (deck/bridge/plaza/stair ramp/terrace/arena
      bridge/arena all stand-able), 9 prompts (8 NPC + Summon). WATCH: first join was slow (7.7k parts + new meshes
      downloading): ScreenBootWatchdog 24/50 at 15s and SettingsUI/UIKit.Notify printed "not in this Place" (both DO
      exist in StarterGui) -- re-test; if it repeats, raise those WaitForChild timeouts or cut part count.
- [x] Click-test: all 8 NPC prompts -> StartDialogue, Temple prompt -> OpenSummon; every AreasConfig arrival has a floor;
      water rescue returns to Plaza. Play 2: Settings/Notify OK; watchdog still 24/50 at 15 s (all finish later), join 9.3 s
- [x] Perf pass (inline, B172): kit textures 22 -> 11 unique (one TextureID per material); backdrop grouped into 11 sector
      Models + Holy/Colossal/Citadel = 40 Models with LevelOfDetail StreamingMesh, Atomic; 380 far meshes RenderFidelity
      Performance + CastShadow off; trees 282 -> 203 (far half thinned, far trees shadowless). Re-measured: join veil 9.3 s -> 6.7 s; watchdog stragglers 26 -> 11; SettingsUI 10 s wait still
      expired once -> PENDING (AD-UI) docs/proposals/2026-10-23-settingsui-boot-timeout.md
- [ ] Areas card images (user); optional waystones
- [x] lobby-map.md rewritten, CHANGELOG B172 pt2, STATE/INDEX/ROADMAP updated, committed

## Assembly layout (B172_assemble.luau)
- Rotunda: 24 x AL_ArcBayTall around r 53.2 (base Y 0, top 40), skip the 3 bays facing north (bridge) + 2 AL_Pier at
  the gap; 28 x AL_Balustrade on r 54 (skip +-16 deg north); AL_Mandala x1.5 at the deck centre; AL_SunGate at
  (-300,40,370) facing south; 4 AL_DomePavilion x0.75 at r 36 diagonals; 8 AL_LampPost.
- Bridge: 7 x AL_BridgeSpan (deck 36 above base) base Y 4 at z 349..169; BridgeDeck -> Transparency 1; invisible
  side rails x = -300 +- 12.5.
- Plaza sea wall: AL_ArcBayTall on r 178 over the southern half-circle (40 bays, skip +-4 deg at the bridge);
  balustrade r 175; Fountain x2.5 + Mandala x2.4 at (-300,40,40); 4 DomePavilion x1.2; LampPosts r 150; Banners.
- Terrace: AL_WallSeg (Y-scaled to 20.4) along z -120, x -620..20, gaps at x -520/-300/-80 with AL_Stairs x1.42
  (bottom south, rising north) + invisible WedgePart ramps.
- Temple x1 (-300,60,-230); Spire behind Ascension; DomePavilion x1.6 Sun Rotunda for Evolve; Dais + columns +
  halo for Star Forge; Dais + crystals + columns + halo for Moon Shrine; 3-4 MarketStall x1.4 + parasols (Bazaar).
- Arena: deck disc r 56 at (140, 40, 400) on 24 ArcBayTall; ArcBay ring r 50 on top (gap west); bridge from the
  rotunda's east edge; NPC_Challenge + Stone_Arena arrival onto the deck.
- Citadel: AL_SpireTower x2.2 + 4 x1.0 + AL_HaloRing x5 on the mesa.
- Colossal: AL_SunGate x8 far south sea (-300, -40, 2100) facing north; ~14 AL_Column x8-16 broken arc r ~1500.

---------------------------------------------------------------------------------------------------------------
# PHASE 2 (user, 2026-10-24) -- "more life": variety, massive structures, own VFX, animations, Story NPC, precise collision
User ask (verbatim gist): more variety of structures + cooler buildings; own VFX (portals, gates, glow, point lights);
more MASSIVE structures; spread trees across the map and put structures in the groves; fix collision = PRECISE collision;
animate buildings (floating gem shards, etc.); a "Story" mode NPC with its own structure (massive portal / gate); more life
overall; create + import all new structures and VFX.

## Plan
1. Blender Kit D (`tools/maps/lobby/kit_wonders.py`, reuse common.py + textures; split-by-material; <20k tris/object):
   - AL_StoryGate: MASSIVE portal gate ~90W x 120H: twin pylons, pointed arch, a free ring `AL_StoryGate__Ring`-style
     separate piece AL_PortalRing (torus R30 with runes) to SPIN, an inner disc plane AL_PortalVeil (gets portal texture).
   - AL_ShardObelisk (tall obelisk with sockets) + AL_GemShard (separate crystal shard mesh to FLOAT/SPIN, Crystal mat).
   - AL_HolyPagoda / AL_BellTower (tiered tower with open bell arch), AL_Colonnade (ruined 3-column + lintel, broken var),
     AL_Watchtower, AL_LanternArch (gate arch over paths with hanging capiz lanterns), AL_StatuePlinth (pedestal + sun),
     AL_GardenShrine (small grove shrine: roof on 4 posts + altar), AL_SkyBridgeRing (halo arch for groves).
   - VFX textures (white, tintable, alpha PNG 512-1024) exported in a carrier GLB like the sky: portal_swirl, glow_soft,
     sparkle_star, light_ray, rune_circle, mist. Carrier planes named by MESH name order -> map in harvest.
2. USER imports AL_KitD.glb + AL_VfxCarrier.glb (3D Importer; desktop control blocked while Valorant/Vanguard runs).
3. Studio:
   - harvest D (extend B172_harvest: Kit D pieces; VFX carrier -> `B172Protos.VFXTex` StringValues of image ids).
   - **Story NPC**: new `Workspace.NPC_Story` (Root/Body/TalkPrompt like others; rig e.g. Apolaki or Tala_MorningStar
     if real) at the Story Gate; prompt attribute OpensEvent = "OpenStageSelect" (router fallback). Add NpcPromptRouter
     ROUTES/DialogueConfig only if owner rules allow (AD-Lobby owns router? check OWNERSHIP); else OpensEvent attribute.
     Story Gate placement: massive, visible from spawn -- e.g. west headland (-900, ~40, -150) or north meadow behind the
     colossus; plus an Areas row "Story" Travel target (AreasConfig is Lobby-owned).
   - Grove sanctuaries: spread trees across the WHOLE map (re-run groves with wider area, ~250-300 trees but LOD-safe) and
     put Kit D structures inside groves (garden shrines, colonnade ruins, bell tower, pagoda, obelisks, lantern arches).
   - Own VFX: ParticleEmitters/Beams using the VFX textures: portal swirl (spinning disc + particles), glow halos,
     sparkles, light rays; PointLights (Shadows OFF, range 16-30) on crystals/lanterns/portal.
   - Animations: client LocalScript `StarterPlayerScripts.LobbyAmbient` (Lobby-local): CollectionService tags
     `AL_Float` (bob + slow spin, attrs Amp/Speed), `AL_Spin` (rotate about Y, attr RPM); runs only on client, uses
     anchored-CFrame tweens via RenderStepped with distance culling (skip > 400 studs).
   - Precise collision: kit solids CollisionFidelity = PreciseConvexDecomposition (set in Edit, applies async -- read back),
     decor stays Box/non-colliding; keep invisible colliders for stairs/bridges.
4. Verify in Play (Story prompt opens stage select, animations run, perf join time), docs (lobby-map.md), changelog, commit.

## PHASE 2 STATUS
- [x] Kit D exported (kit_wonders.py; 10 pieces 28k tris; veil UVs striped -> Studio puts the portal VFX texture on it) + AL_VfxCarrier.glb (parts named AL_Vfx_portal|glow|sparkle|ray|rune)
- [x] user import; Kit D harvested (shared textures, solids PreciseConvexDecomposition); VFX ids in B172Protos.VFXTex
- [x] Story Gate x1.8 (218 tall) at (-660,~42,20) facing east, PortalRing/Veil tagged AL_Spin (attr RPM, Axis=Look), decal swirl,
      sparkles, glow, PointLight; NPC_Story (Apolaki rig, TalkPrompt OpensEvent=OpenStageSelect), Travel.Area_Story
- [x] Groves rebuilt map-wide: 22 groves / 160 trees + Structures.Sanctuaries (65 models: shrines, colonnades, bell towers,
      shard obelisks, watchtowers, lantern arches w/ lights); 41 AL_Float shards (+fountain, +temple dome ring) with PointLights;
      StarterPlayerScripts.LobbyAmbient (client; AL_Float/AL_Spin; cull 600); pivots centred via PrimaryPart.PivotOffset;
      465 solid kit meshes -> PreciseConvexDecomposition (Studio stalls ~3 min recomputing)
- [ ] verify + docs + commit
- [x] Play-verified 2026-10-24: Story prompt -> OpenStageSelect (PlayGUI), floats/spins animate, spawn OK, join veil 2.6 s,
      ScreenBootWatchdog 50/50. 2 hillside shrines removed, 1 colonnade lifted (were buried). Docs + CHANGELOG pt4 landed.
- [ ] Optional next: AreasConfig Story row -> Travel Area_Story; ray/rune VFX (VFXTex) at gates; retake Areas card images.

## PHASE 3 (user 2026-10-24): Summon sanctum + NPC, HUD Summon -> travel, more building variety, gate VFX
User: "structure and npc for summon screen ... clicking summon in gui should just teleport the player to the summon npc
... unique cool animatable structure (summon animation soon), cool vfx, huge ... perfect for summoning rituals ...
variety of buildings." Earlier same day: Story Areas card -> travel to the gate; light-ray + rune-circle VFX at gates.
### STATUS
- [x] AreasConfig: Story -> `Travel = "Area_Story"`; Summon -> `Travel = "Area_Summon"` (Lobby-local config).
- [x] `B172_gatevfx.luau` run: Map.Structures.GateVFX (Story Gate floor + arch runes, spawn Sun Gate, citadel gate,
      colossal gate rays). Runes = AL_Spin Models (Axis Y), lifted 1.05 above grass.
- [x] Kit E built: `tools/maps/lobby/kit_summon.py` -> Downloads\Alamat_Lobby\glb\AL_KitE.glb (12 pieces, 89k tris,
      max 10k/object): AL_SummonDais/RingOuter/RingInner/Heart/Crown/Halo + AL_Pagoda, AL_BahayNaBato, AL_Observatory,
      AL_Aqueduct, AL_Lighthouse, AL_Stupa. Render: renders\AL_KitE.png.
- [x] Site chosen: Star Sanctum centre (-940, 41.7, -120), faces +X (east), scale 1.15, top floor y 52.08.
      (East site 220,-80 rejected: mid-frame in PersistentScene.PlayGUICamera's shot.)
- [x] `Workspace.NPC_Summon` (Tala x1.25, prompt "Summon"/"Keeper of the Stars", OpensEvent=OpenSummon) at
      (-914, 52.08, -120) facing +X; `Map.Travel.Area_Summon` arrival (-844, 46.2, -120).
- [x] SummonGUIController (AD-UI file, user-asked crossing): HUD Summon button -> AreaAction("Travel","Summon"),
      falls back to opening the screen. LobbyAmbient: `AmbientPaused` attribute skips a model.
- [x] USER imported AL_KitE.glb; harvested + "post" run -- then the user found an inside-out pagoda roof + stupa
      z-fighting (NEW RULE: always check z-fighting). kit_summon.py fixed (roof winding, trims, steps, mandala +0.12,
      spire poles), `C.zfight_report` added (0 hits), Kits A-D audited + fixed in Studio (tools/maps/lobby/README.md).
- [x] USER re-imported the fixed AL_KitE.glb.
- [x] harvest + post + sanctum (scale raised to 1.4 for "huge"; keeper moved to (-908, 54.3), arrival x -826) + buildings
      (18 placed; viewport test keeps the PlayGUICamera shot unchanged; rock/backdrop AABB test). Lighthouse 1/2 (few coast spots).
- [x] Verified: keeper feet on the dais floor; Play: Summon travel ok, prompt -> OpenSummon (SummonGUI open), 5 parts
      animate, player stands on the dais (precise), join veil 2.7 s, no errors.
- [x] Docs: lobby-map.md, CHANGELOG pt5, OWNERSHIP note, STATE.
- [ ] Optional next: summon animation (user), Areas card pictures (user), 2nd lighthouse on a sea stack by hand.

## PHASE 4 (user 2026-10-24): space + scale + VFX + lighting (then the summon cutscene)
User: "story gate feels so out of place, placed in the middle, find new spot where it fits perfectly. scale all the builds
up (houses, pagodas, pavilions too small). move the mountains back and further, more space, decently massive not
cramped map, massive buildings. more cooler vfx everywhere, create/browse different kinds (Blender ok), make all vfx
noticeable. improve lighting. trees look tip-toeing: bury them deeper. then we proceed with summon cutscene animation."
### STATUS
- [x] 1 terrain WEST half rewritten (B172_terrain.luau: asymmetric ellipse RX_W 1800, north radius -> 1000 west of
      x -700, west coast to -1650; east + user's north area untouched); 690 objects re-grounded via _G0 stamps (91 moved,
      8 inland beach rocks removed). Backdrop: Range_1/10/2 moved west, Range_6 +260x, Range_7 +180/+180, SkyIsland_W
      -500x, Stacks_5 -300x; Range_3/4 (user's area) + Range_5 (PlayGUI shot) kept.
- [x] 2 Story Gate -> (-1500, 40.6, -200), x2.2, faces east at the end of the west plain, mountains behind; keeper
      (-1458,-200), arrival (-1427,-200), GateVFX scaled along. Rune circles (all 6, gates + sanctum) are now GLOWING
      PARTICLES (flat VelocityPerpendicular, Speed 0.25, Size = width, LightEmission 1, 2 counter-rotating) -- decals went
      dark in shadow.
- [x] 3 Sanctuaries x1.6 in place (31 bases; 30 shards ride their base, offset scaled); Village re-placed x1.8 (B172_summon
      buildings: 4 pagoda, 8 bahay, 3 observatory, 4 stupa) + a 3-segment aqueduct at z -345 (x -1400..-1050, level y 45.2)
      + 2 lighthouses on beaches (-1625,125) (-900,100); pavilions: Rotunda 0.75->1.1 (+6 out), Plaza 1.2->1.8.
- [x] 4 trees sunk as wholes (6% height + 1.5, attr `Sunk` guards re-runs). GOTCHA: trees are Models holding Trunk +
      Canopy parts, mostly LOOSE under Groves -- iterate models that hold parts, never grove:GetChildren() (that split
      trees into parts once; repaired). 28 empty shells removed; 132 trees left -> the new west needs more trees (step 5).
- [ ] 5 VFX kit 2 (Blender/numpy textures) + map-wide noticeable VFX
- [ ] 6 lighting pass
- [ ] 7 Play verify (join time, prompts, travel), docs, CHANGELOG pt6, commit
- NEXT after phase 4: summon cutscene animation (hooks: SummonSanctum SummonPoint/SummonFocus, AmbientPaused).
- [x] 5a VFX kit 2: tools/maps/lobby/vfx_kit2.py (12 textures, uploaded via local http + upload_image; ids in
      B172Protos.VFXTex) + tools/lobby_map/B172_vfx2.luau (map-wide: tree petals/leaves, fireflies, butterflies, gulls,
      god rays, station beacons, falls mist, shard auras, sanctum/story wisps + mist, holy snow, sea glints; ~7.7k live
      particles after trimming). 43 trees planted in the west; canopies re-tinted (41 pink, 20 white-gold, greens lighter).

## PHASE 5 (user 2026-10-24, mid phase 4): a REAL CITY layout + paths + more building variety + mountains back
User: "arrange them properly like a real city / reasonable layout, think like an actual architect, don't just place them
randomly, then create actual paths via textures or real models, push the mountains further at the back (not just
left/right) for more space, more variety of buildings, and cool paths". North: user chose "push AROUND my area"
(back mountains out in the NW/NE; the stretch behind the temple, x -700..160, stays).
### STATUS
- [x] A NW terrain: ryN -> 1250 west of x -1150 (B172_terrain.luau, chunks x -2400..-700, z from -1600); Range_2 -> (-1353,-1225), Range_1 -> (-2105,-1077) (east edges clear of x -700)
- [x] B Kit F (tools/maps/lobby/kit_city.py, zfight 0, 55k tris): RowHouse, CornerHouse, MarketHall, Library, StreetArch,
      Bathhouse, ClockTower, CityFountain -> imported MYSELF (computer-use: Home > Import, type the path, Import), harvested
      (canon textures, solids precise). GOTCHA: open_application("Roblox Studio") runs the INSTALLER when an update is
      pending and closed Studio -- never call it while Studio is open; just click into the window.
- [!] 2026-10-24 ~09:50: running B172_city.luau SECTIONS {clear, roads} CLOSED the Lobby (Studio stayed open, place
      unloaded) -- the road paint = ReplaceMaterial x6 materials per 4x4 cell over thousands of cells in ONE call. ON
      RESUME: user reopens the Lobby; VERIFY first (Kit F protos in B172Protos.Kit? Village still there? City folder?
      roads painted?) -- autosave may have lost the Kit F harvest (re-import AL_KitF.glb + harvest if missing). Then
      run "clear" alone, and paint roads ONE ROAD PER CALL (add a ROAD filter) with fewer source materials.
- [ ] C city plan (tools/lobby_map/B172_city.luau, data-driven): boulevard plaza -> market square -> sanctum -> Story
      Gate; side streets + blocks of row houses facing streets; civic square (clock tower, market hall, library);
      temple-hill quarter (pagodas/stupas/observatory) on a north road; aqueduct along the north edge; coastal
      promenade to the lighthouses. Village (random) replaced by the plan.
- [ ] D paths: terrain ReplaceMaterial (Cobblestone/Pavement) along streets + lamp posts, tree rows, street arches
- [ ] E lighting pass; F verify (PlayGUI shot unchanged, prompts, travel, join time), docs, CHANGELOG, commit
