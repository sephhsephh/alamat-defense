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
- [ ] Kit D Blender script written + exported (+ VFX carrier)
- [ ] user import
- [ ] harvest D, Story NPC + gate, grove sanctuaries + tree spread, VFX, LobbyAmbient script, precise collision
- [ ] verify + docs + commit
