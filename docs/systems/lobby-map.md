# Lobby map -- the Holy Coast (Lobby)
<!-- owner: AD-Lobby | scope: Lobby | last-verified: 2026-10-24 (B172 phase 3) -->

B172 rebuild of the user's coastline + island reference (Anime-Vanguards-style lobby) as a **holy** Alamat version:
white marble, painted gold, turquoise scale tile, sun halos, golden-hour haze. Build method = the canon in
`docs/design/stylized-environment.md` (terrain is the floor, reused mesh kits on top). The old night-island map
(B134/B139) is archived, not deleted. Build history + resume checklist: `tools/lobby_map/B172_PLAN.md`.

## Layout (world studs; north = -Z; sea surface Y 4)
| Area | Where | Notes |
|---|---|---|
| Isle of Light (spawn) | rotunda centre (-300, 42, 420), deck r 56 | 24 tall arcade bays in the water, sun mandala, 4 gazebos, Sun Gate on the north edge, Guide |
| Grand Bridge | x -300, deck 42, z 364 -> 154 | 7 arched spans; invisible `BridgeDeck` floor + rails |
| Coast plaza | disc (-300, 42, 0) r 178 | arched sea wall + balustrade, twin waterfalls (+-24 deg), fountain on a mandala, gazebos, lamps |
| Temple terrace | Y 62 for z <= -120 | terrace wall + 3 stairways (invisible wedge ramps) at x -520 / -300 / -80 |
| Temple of Bathala | (-300, 62, -232) | old Summon prompt at the door still works (`OpensEvent = OpenSummon`) |
| Star Sanctum | (-940, 41.7, -120), faces east, x1.4 | THE summon place: `Structures.SummonSanctum` + `NPC_Summon`; ~185 wide, halo ~170 tall |
| Village | map-wide | `Structures.Village`: 3 pagodas, 6 bahay na bato, 2 observatories, 3 stupas, 3 aqueducts, 1 lighthouse |
| Stations | see the table below | each keeper = a tower rig |
| Arena of Dawn | deck (140, 42, 400) r 56 | colosseum ring on an arcade + bridge from the rotunda's east side |
| Sun Citadel | NE mesa (300, ~78, -330) | spire x2.2 + 4 spires + halo + gate; framed by `PersistentScene.PlayGUICamera` |
| Colossus | (-300, ~62, -640), 433 tall | winged sun goddess (AI mesh) behind the temple |
| Story Gate | (-660, 40.5, 20), faces east, 218 tall | AL_StoryGate x1.8 + spinning AL_PortalRing/Veil (cyan Neon + portal decals), sparkles, glow, light; `NPC_Story` in front |
| Sanctuaries | in the groves map-wide | `Structures.Sanctuaries`: shrines, colonnades, bell towers, shard obelisks, watchtowers, lantern arches; floating gem shards |
| Map end | rim of ellipse C (-300,-300) R (1250,760) | near white cliffs (warm tint) + far peaks (lavender), sea stacks, colossal Sun Gate + column ruins in the far sea |

**Terrain gotcha:** tiers written at Y 40 / 60 SURFACE (render + collide) at **42 / 62**. Everything sits on 42 / 62.

## Stations (NPC keepers are tower rigs)
| NPC model | Rig (RS.UnitModels) | Place | Structure |
|---|---|---|---|
| `NPC_Guide` | Bathala | spawn deck, by the Sun Gate | -- |
| `NPC_Ascension` | Bathala_Ascended | (-520, 62, -190) | Sky Spire + dais |
| `NPC_Evolve` | Apolaki_Zenith | (-80, 62, -190) | Sun Rotunda (pavilion x1.6) + gold sigil |
| `NPC_StatReroll` | Babaylan | (-530, ~43, -20) | Star Forge: dais, halo, columns, gold aura |
| `NPC_TraitReroll` | Lakapati | (-700, ~40, -110) | Moon Shrine: dais, column ring, crystals, azure sigil + aura |
| `NPC_Shop` / `NPC_Craft` | Magwayen / Handyong | (-70, ~41, 10) / (-70, ~41, -40) | Bay Bazaar: 4 market stalls, parasols, planters |
| `NPC_Challenge` | Urduja | arena deck | Arena of Dawn |
| `NPC_Summon` | Tala | (-908, 54.3, -120) | Star Sanctum top floor; `OpensEvent = OpenSummon` (router fallback) |
| `NPC_Story` | Apolaki | (-626, ~41, 20) | Story Gate; no ROUTES row -- prompt attribute `OpensEvent = OpenStageSelect` (router fallback) |
- Each `NPC_*` = `Root` + `Body` (now invisible; holds the prompt + `NameTag`) + `Unit` (rig clone x1.25, anchored root,
  no collision). `NpcPromptRouter` routes by the MODEL NAME (unchanged), so keep the names. Rigs idle via
  `SSS.Server.Lobby.NpcIdle` (the rig's `IdleAnim`, else the stock R15 idle).
- Swap a keeper: replace `NPC_<X>.Unit` with another `RS.UnitModels` rig clone (same scale/anchoring), keep `Body`.

## Where things live
- `Workspace.Lobby.Map`: `Core` (SpawnDeck, BridgeDeck colliders), `Travel` (arrivals), `Structures.{Rotunda, Bridge,
  SeaWall, Plaza, Terrace, Temple, Stations, Arena, Citadel, Colossal, Falls}`, `Backdrop.{Mountains, SeaStacks, Holy}`,
  `Nature.{Groves (22 groves, 160 Yasu trees), CoastRocks (215)}`, `Dressing` (bushes, planters, fountain water, VFX anchors).
  `Workspace.Lobby` MUST stay (SettingsConfig.Place() detects the Lobby by it).
- Prototypes: `ServerStorage.DevTools.LobbyMap.B172Protos.{Kit (24 holy kit pieces), Rocks (29), YasuTreePack (Creator
  Store 79689531752352), AIGen (M_Colossus, M_SkyIsland)}`; old `LobbyMap.VFX` presets are reused.
- Backups: `ServerStorage._OldLobby_B139` = old `Map`, `RootDressing`, `Terrain_B139` (TerrainRegion; PasteRegion at its
  `CornerCell` attribute), `Lighting_B134` (night lighting). The user's own south area (workspace root, z < -1450) is untouched.

## Builders (paste into execute_luau, Lobby, Edit; each re-runnable)
`tools/lobby_map/`: `B172_terrain.luau` (WriteVoxels coast/terrace/mesa/rim/seabed), `B172_backdrop.luau` (mountains +
sea stacks), `B172_groves.luau`, `B172_harvest.luau` (imported GLBs -> `B172Protos.Kit` + sky), `B172_assemble.luau`
(SECTIONS list), `B172_dress.luau`. Blender kit: `tools/maps/lobby/` (README = piece specs; run with
`blender.exe -b <blend> --python-expr "exec(open(r'<script>').read())"`; outputs in `Downloads\Alamat_Lobby`).
The 3D Importer names each imported root `Scene`; the sky carrier planes arrive as `Plane`, `Plane.001`, `Plane.002`.

## Animation + VFX (B172 phase 2)
- `StarterPlayerScripts.LobbyAmbient` (client, Lobby-local): CollectionService tags, RenderStepped, culled past 600 studs.
  `AL_Float` = bob + slow yaw (attrs `Amp`, `Speed`); `AL_Spin` = turn (attrs `RPM`, `Axis` "Look" | "Y"). Base = the pivot
  when tagged, so tagged Models need a CENTRED pivot (`PrimaryPart.PivotOffset`, not `WorldPivot`).
- 41 floating `AL_GemShard`s (sanctuaries, 3 over the fountain, 6 round the temple dome), each with a PointLight (range 18,
  no shadows). New lights: Shadows off, range <= 60.

## Star Sanctum = the summon rig (for the summon animation)
`Structures.SummonSanctum` (attr `SummonRig`): `Dais` (static, walkable, precise), `RingOuter` (AL_Spin Y 3 rpm),
`RingInner` (AL_Spin Look -5), `Crown` (AL_Spin Y -2), `Halo` (AL_Spin Look 1), `Heart` (AL_Float; holds `HeartCore` with
attachment **`SummonFocus`**, light + glow), `VFX` (`Altar` with attachment **`SummonPoint`** = where a unit appears, light
pillar + rising sparkles; `FloorRune`/`AltarRune` spinning decals; 8 `PylonTip` lights + `Tether` beams to SummonFocus;
`HaloCore` glow). Pivots are centred. To animate a part: set its `AmbientPaused = true` (LobbyAmbient lets go), tween it,
set false to resume. Builder: `tools/lobby_map/B172_summon.luau` (SECTION post / sanctum / buildings).
- HUD Summon button (+ hotkey) and the Areas Summon card TRAVEL to `Area_Summon`; the screen opens at the keeper. The
  HUD hook lives in AD-UI's `SummonGUIController` (user-asked crossing, B172 p3; falls back to opening the screen).

## Travel, Areas, water rescue
- `Map.Travel` keeps every AreasConfig target name (`Plaza`, `Stone_Temple`, `Stone_RuneCircle`, `Stone_Forge`,
  `Stone_Shrine`, `Stone_Village`, `Stone_Arena`, `Area_SunAltar`, `Area_Waterfall`, `Area_BlueBeacon`, `Area_Jungle`,
  `Area_Lighthouse`, `Area_Story` = in front of the Story Gate, `Area_Summon` = the sanctum's east stairs), each an invisible `Arrival` part at its new place; AreasConfig names/descs were renamed to the new
  places (Isle of Light, Temple of Bathala, Sun Citadel, Blossom Groves, Grand Bridge, ...). The card IMAGES still show the
  old map -- the user retakes them.
- No travel waystones yet (`LobbyMapService` reports 0 travel prompts); travel = the HUD Areas screen.
- Water rescue unchanged: swimming 4 s below Y 6 -> `Plaza` arrival ("ISLE OF LIGHT"). Verified B172.

## Lighting (holy golden-hour haze)
LightingStyle Realistic (by hand). ClockTime 16.2, latitude 22, Brightness 2.4, Ambient 92,84,96, OutdoorAmbient
168,150,140, EnvDiffuse/Specular 0, ShadowSoftness 0.15. `HolyHaze` Density 0.21, Offset 0.32, Haze 0.55, Glare 0.15,
Color 222,232,242, Decay 255,236,214. `HolyGrade` C 0.15 / S 0.18 / tint 255,238,212. `HolyBloom` 0.45 / 36 / 2.2.
SunRays 0.18 / 0.8. `DistanceSoftness` DoF far 0.12, radius 140. `HolySoftness` Blur 2. `HolySky` = the seamless
elevation-gradient sky (carrier images) + `Terrain.Clouds` (cover 0.55). Terrain: Pavement override `AL_HolyPlaza2`,
decks `AL_HolyMarble2` (AI-generated MaterialVariants); Sand/Pavement/Rock colours brightened.

## Rules
- **`PersistentScene.PlayGUICamera` is the USER'S framing -- never move it**; keep its foreground clear (groves there removed).
- Structures: walk surfaces are invisible colliders or Hull floors; solid kit meshes PreciseConvexDecomposition (465;
  setting it stalls Studio ~3 min -- batch it, then wait); small decor CanCollide off; the backdrop
  is CanCollide/CanQuery off, CastShadow off.
- **Z-fighting (user rule):** kits pass `C.zfight_report` (0 hits) before export; decal discs >= 0.25 above floors. Gate VFX:
  `Structures.GateVFX` (rune circles + ray beams; `tools/lobby_map/B172_gatevfx.luau`).
- Strip scripts from anything copied in from reference places (backdoors were found there, B172 study).
- Perf (B172 pass): kit = ONE TextureID per material (keep it so when adding pieces: copy from `B172Protos.Kit`);
  backdrop = 40 Models with `LevelOfDetail = StreamingMesh` (Atomic), far meshes RenderFidelity Performance + no shadows;
  160 trees (shadowless). Studio join veil 2.6 s after phase 2 (6.7 s pt3, 9.3 s before). SettingsUI's 10 s wait can still expire on a slow
  join -- PENDING for AD-UI (`docs/proposals/2026-10-23-settingsui-boot-timeout.md`).
- A new unit still needs its rig in `RS.UnitModels` here; keepers use existing rigs only.
