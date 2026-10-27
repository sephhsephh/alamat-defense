# CHANGELOG (append-only; newest first)
<!-- Holds the newest 10 entries only. Older: archive/CHANGELOG-archive.md (history -- grep it, never read at bootstrap). Entry budget: 600 chars. -->
## 2026-10-28 [lobby] B174 -- **Story stage carousel ("UI Scroller") replaces the island list.**
- `StoryMap.Carousel` (tools/story_carousel_build.luau) + `PlayController.StoryCarousel`: ornate cards (Figma AI art, white-tint
  layers), Idle/Hover/Selected fake glow + flame, slots, parallax, arrows, track studs, ENTER plate; PC/console/mobile input.
- `PlayConfig` Maps `CardArt`/`CardTheme` + display-only `UpcomingMaps` (Bakunawa Cove, ??? teaser). No contract impact.
  `story-carousel.md`. Figma board node 23:1420.
## 2026-10-27 [game+lobby] B173 pt2 -- **9 real tower rigs replace placeholders (user's "modeled npcs").**
- Duwende, Santelmo, Mayari, Mayari_LunarEclipse, Sidapa, Sidapa_LastMeasure, Magwayen, Magwayen_Soulferry,
  AmanSinaya: `RS.TowerModels` (Game) + `RS.UnitModels` (Lobby), GameScale kept, Placeholder flags gone, Humanoid
  names hidden. Old rigs in `ServerStorage.Archive.*_Replaced_B173`. Scaled render checked in Play. No contract impact.
## 2026-10-27 [game] B173 -- **Stage 2 map Bakunawa Cove (pirate cove) built in Blender + assembled in the Game.**
- `tools/maps/pirate`: smooth painted textures, 7 kits (53 pieces: harbour + galleon hero, village + tavern, fortress,
  Skull Rock, islets), arena + village terrace, 556-stud path. `ServerStorage.Maps.Stage2.BakunawaCove` + config;
  verified in Play via new smoke knob `DevMapId`. No Stage 2 acts yet. No contract impact. `maps-bakunawa.md`.
## 2026-10-24 [lobby] B172 pt6 -- **Bigger map + Lumina city + map-wide VFX + summon cutscene.**
- West/NW terrain pushed out, Story Gate to the plain's end, builds scaled up, trees sunk. Planned city: cobbled streets,
  Kit F (row/corner houses, market hall, library, bathhouse, clock tower, arches, fountain), Moon Shrine moved. VFX kit 2.
- SummonCutscene: camera takeover + hidden GUI before SummonReveal (SummonGUIController crossing). Lighting pass
  (natural grass, depth haze, env light, no blur). No contract impact.
## 2026-10-24 [lobby] B172 pt5 -- **Star Sanctum (summon) + keeper, HUD Summon travels there, new building kit, z-fight rule.**
- Kit E: 6-part animatable sanctum (dais, gyro rings, heart, crown, halo; SummonPoint/SummonFocus hooks, AmbientPaused) +
  pagoda/bahay/observatory/stupa/aqueduct/lighthouse (18 placed). NPC_Summon (Tala). HUD Summon + Areas Summon/Story = Travel
  (SummonGUIController crossing, user-asked). Gate rune/ray VFX. C.zfight_report; Kits A-D flush faces fixed in Studio.
## 2026-10-24 [lobby] B172 pt4 -- **Lobby phase 2: Story Gate + keeper, grove sanctuaries, floating shards, precise collision.**
- Blender Kit D (10 wonders) + VFX textures. Story Gate (portal ring/veil spin, glow) + `NPC_Story` (Apolaki; OpensEvent
  OpenStageSelect, verified). 22 groves/160 trees + 63 sanctuaries; 41 lit AL_Float shards; client `LobbyAmbient` animates
  AL_Float/AL_Spin. 465 kit meshes precise collision. Join veil 2.6 s, 50/50 boot. No contract impact.
## 2026-10-23 [lobby] B172 pt3 -- **Lobby perf pass: join veil 9.3 s -> 6.7 s (Studio).**
- Kit textures 22 -> 11 (one TextureID per material); backdrop = 40 StreamingMesh-LOD Models, far meshes Performance
  fidelity + no shadows; trees 282 -> 203. New PENDING (AD-UI): SettingsUI's 10 s GUI wait expires on slow joins.
## 2026-10-23 [lobby] B172 pt2 -- **Lobby rebuilt: the Holy Coast (user's coastline+island reference, holy version).**
- Terrain coast/terrace/mesa/rim + seabed; Blender holy kit (24 pieces, 3D-imported) assembled: rotunda spawn, bridge, plaza
  sea wall + twin falls, Temple (Summon prompt), stations, arena, citadel; mountain ring + colossus; groves, rocks, dressing.
- Keepers = tower rigs (NpcIdle). Old map archived (_OldLobby_B139). Verified: 9 prompts, travel, rescue. No contract impact.
## 2026-10-22 [repo] B172 -- **Reference-map study: the stylized build canon for every map + the Lobby rebuild.**
- Read-only study of town / rpg map / Roman Battleground (user's style references). New `docs/design/stylized-environment.md`
  (lighting "town haze" recipe, rock kit, trees, multi-mesh buildings, terrain+mesh rules, Lobby checklist) + `reference-maps.md`.
- SECURITY: rpg map + town carry a `<null?>` backdoor Script in window1.003 -- strip scripts before copying. No contract impact.
## 2026-10-21 [lobby] B171 -- **Play menu v3: ornate AI-painted borders, mode cards, special events, party hex slots, player card.**
- Built by `tools/playui_v3_build.luau` (backup `_UIBackup_B171`); PlayController: Cards lookup, plate = card click, player
  card, events from EventQuestConfig (ONE template), per-spot poses; `OrnateSliceScaler`; GetPlayState +PlayerXP (additive).
- New user rule: tintable art is WHITE + UIGradient `Tint` (`docs/design/white-tint-art.md`). Verified live. No contract impact.
- Doc: `play-menu-v3.md`. Art/scripts in `Claude outputs/play-ui-v3/` (untracked).
