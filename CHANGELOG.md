# CHANGELOG (append-only; newest first)
<!-- Holds the newest 10 entries only. Older: archive/CHANGELOG-archive.md (history -- grep it, never read at bootstrap). Entry budget: 600 chars. -->
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
## 2026-10-21 [repo] B170 pt2 -- **Bootstrap tightened again: CLAUDE.md ~9.5k, STATE/CONTEXTs ~4.1-4.3k.**
- Wording only; every rule kept (keyword parity checked vs the pre-B170 CLAUDE.md). Ownership merged into sync;
  UI rules grouped; contract protocol one line. Bootstrap ~31.5k -> ~24.2k chars. Docs only, no contract impact.
## 2026-10-21 [repo] B170 -- **Slim bootstrap: history archived, char budgets.**
- STATE/CONTEXT rewritten as current state; old versions + changelog B160 and older moved verbatim to `archive/`.
- CLAUDE.md: char budgets (12k/6k/6k/600), history rule, read newest 3 entries. Bootstrap ~118k -> ~31k chars.
- Orphan hazards moved to system docs; new `studio-testing.md`. All 5 PENDINGs kept. Docs only.
## 2026-10-21 [game+lobby] B169 -- **Units stage: smooth at graphics 1 (rendered in the 3D world, not a ViewportFrame) + zoom.**
- Research: Roblox staff confirm ViewportFrames redraw at a reduced rate on low graphics by design ("not optimized for ... serving as the main component of a scene"); RenderStepped stepping / camera nudges do not undo it. So the user's second option was built: while the Units screen shows the stage, `UnitsGUI.UnitsShowcase` draws the selected unit with the REAL camera (local clone at y 4000, camera copies the stage ViewportFrame's camera skewed onto the frame, HallBG + stage art mirrored live onto a camera-facing backdrop `RS.UnitShowcase`, lower ScreenGuis hidden, everything restored on close). Both Places.
- Proven: showcase rig poses 120/121 frames (Bakunawa bones and Aswang AnimationConstraint rig); layout identical to the viewport version once the 58px top-bar inset is added; close restores Custom camera + Humanoid subject + HUD. Game verified with its window in front (Studio draws 3D only in the front window).
- Zoom: wheel over the stage / pinch / R2-L2, 0.4-1.8x (`Hall.zoomBy`). `ViewportIdle` budget skips a viewport with ImageTransparency 1.
- Place-local only, no shared canon, no contract change. Docs: `docs/systems/units-screen.md` B168/B169.
