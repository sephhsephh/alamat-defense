# CHANGELOG (append-only; newest first)
<!-- Holds the newest 10 entries only. Older: archive/CHANGELOG-archive.md (history -- grep it, never read at bootstrap). Entry budget: 600 chars. -->
## 2026-10-28 [game+lobby] B175 pt2 -- **Stage 2 balance (sim), matchmaking unlocks, SFX generator.**
- Sim on the cove path (`SIM_PATH=stage2`): 2x speeds made Stage 2 ~10x Stage 1 -> enemies 1.3x Stage 1 speed, bosses
  0.65-0.8; StageMissionsConfig eaabd4d1 (TimeUnder 880/1050/1140), both Places. `PlayConfig.LockReason` = ONE unlock
  rule for PartyService + MatchmakingService. `tools/audio/sfx_gen.py` (synth/ElevenLabs/upload) + skill game-sfx.
## 2026-10-28 [game+lobby] B175 -- **Stage 2 Bakunawa Cove: 5 acts + Infinite, roster, bosses, Lobby mirror.**
- Game: Stage2 StageConfigs/waves, Skeleton Pirate/Pirate Brute/Bilge Rat/Cursed Gull (first flyers), bosses Magwayen ->
  Bakunawa (headliner, pity 30). Real rigs await a GLB import (stand-ins now). Lobby: mirror, PlayConfig map, PartyService map gate.
- Shared: StageMissionsConfig 21b05f5a, RewardScalingConfig d39c3d6d (`Stage2` curve), both Places. `stage2-bakunawa.md`.
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
