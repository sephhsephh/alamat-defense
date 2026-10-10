# Lobby map -- night islands, stylized districts, travel waystones (Lobby)
<!-- owner: AD-Lobby | scope: Lobby | last-verified: 2026-10-10 (B139 stylized revamp) -->

The Lobby is the user's "Map Concept" image built for real: a night archipelago on the terrain islands from B130
(`tools/lobby_islands_gen.luau`). Every NPC lives in its own themed district; glowing waystones make the long
walks optional. **Design canon = this doc + `tools/lobby_map/*.luau`; the built map is Studio (Lobby).**

## Art direction (B139, user: "no bland blocks called a plaza / pole / beam")
Anime-tower-defense hub look (Anime Vanguards / Anime Expeditions / Anime Defenders lobbies): every landmark is a
**stylized hand-painted MESH** (Studio AI mesh generator), every light source has **real particle VFX**, district
beacons are **soft Beam light pillars**, never neon bricks. Rules for any future edit:
- **No part-built landmarks, poles, torches, sky-beam bricks or flat discs.** Need a new prop? Generate it
  (prompt suffix: `stylized hand-painted anime fantasy game asset`), harvest it into `Protos` as `M_<Name>`.
- Light = a VFX preset (below), never a Neon part. Neon is only allowed INSIDE a mesh's texture.
- Plain parts that must stay (steps, piers, deck colliders) wear the generated MaterialVariants
  `Alamat_StylizedStone` (Slate) / `Alamat_StylizedPlanks` (WoodPlanks) in `MaterialService`.

## Where things live
- **`Workspace.Lobby.Map.<District>`** -- everything built; each district's B139 work is in its `Revamp` folder.
  `Workspace.Lobby` MUST stay: `SettingsConfig.Place()` detects the Lobby by it. Kept untouched at the workspace
  root: `NPC_*`, `SpawnLocation`, `PersistentScene`, `Terrain` and the user's south area (`Workspace.Model` etc.).
- **Builders** (paste into `execute_luau`, Lobby, Edit): B134 `Lib.luau` + `01`..`07` built the layout;
  B139 `08_vfx_lib` (VFX presets), `09_arrival`, `10_waystones`, `11_districts` (one function per district).
  B139 scripts DELETE the B134 block parts they replace, so a full rebuild = 01-07 then 08-11.
- **Prototypes:** `ServerStorage.DevTools.LobbyMap.Protos` -- 44 models; the B139 AI meshes are `M_*` (one
  MeshPart `Mesh` = PrimaryPart, pivot at origin): PlazaFloor, FloorSun, FloorMoon, FloorWave, RunePlatform, Temple,
  FireAltar, Arena, Torii, PagodaTower, Forge, ForgeStall, MarketStall, Lookout, Lighthouse, RuinArch, BridgeSeg,
  Brazier, StoneLantern, StoneLantern2, LanternPost, Tiki, Banner, Waystone, Monolith, ShrinePillar, CrystalBlue,
  CrystalPurple, Fountain, Campfire, Barrels, Bangka, Palm, TreeBloom, Bush, Mushrooms, Boulder, LavaRocks,
  LanternString (unused). `Lib.proto` still falls back to `ServerStorage._OldLobby_B134` (keep that archive).
- **VFX presets:** `ServerStorage.DevTools.LobbyMap.VFX` -- Attachments cloned onto invisible anchor parts:
  `Fire_<C>` (flipbook flame + core + embers + halo + light), `Motes_<C>` / `Fireflies` (area = the anchor part's
  box), `Shaft_<C>` (3 Beams to a `ShaftTop` attachment + rising sparkles), `Aura_<C>` (crystal halo + sparkles +
  light), `Sigil_<C>` (flat spinning magic circle), `VolcanoPlume`, `FountainSpray`, `WaterRipples`, `WaterfallBase`.
  `<C>` = Gold / Crimson / Violet / Jade / Azure. Textures are Creator Store ids (no packs kept in the place).
- **Runtime:** `ServerScriptService.Server.Lobby.LobbyMapService` (travel + water rescue, below).

## Districts (world coords; the plaza faces north = -Z)
| District | Centre | NPC | B139 look |
|---|---|---|---|
| Arrival Plaza (spawn) | (-330, 97.5, 772) | Guide | sun-compass court, gold spawn sigil + motes, 8 stone lanterns, 2 great braziers |
| Sun Altar | (-300, 118, 560) | -- | 3-tier fire altar + giant flame, 4 braziers, sun floor, purple banners |
| Sky Temple | (-420, 207, 362) | Ascension (forecourt) | blue 3-roof pagoda (x1.15) on Base1, azure braziers + light pillar, paper lanterns |
| Rune Circle | (-560, 169, 462) | Evolve | rune dais, azure sigil, 4 carved runestones with auras |
| Waterfall | lip (-478, 171, 543) | -- | **the user's original waterfall model restored** (beams + mist, from `_OldLobby_B134`) |
| Blue Beacon | (-612, 82, 815) | -- | blue crystal cluster + light pillar, wave floor, 6 azure lanterns |
| Beach Village | market (-846, 15, 748) | Shop, Craft (stalls) | AI market + forge stalls, campfire, 8 tiki torches, bangka boats, nipa huts |
| Jungle | (-850, ~150, 430) | -- | AI lookout tower, ruined vine arch (+2 invisible pillar colliders), glow mushrooms |
| Red Gate Fortress | gate ~(-78, 121, 584) | Stat Reroll (forge, (100, 628)) | lacquered torii, crimson braziers, great brazier + pillar, forge workshop, pagoda tower |
| Crystal Shrine | (292, 143, 352) | Trait Reroll | amethyst cluster + violet pillar, moon floor, marble crystal pillars |
| Green Arena | (40, 104, 815) | Challenge | colosseum ring (visual), jade brazier + pillar, banners |
| Sea / volcano | lighthouse (-262, 56, 980), crater (-24, 211, -312) | -- | AI lighthouse + glow; smoke plume, embers, lava rocks |

Bridges: the AI rope-bridge segment tiled along each bridge's planks (planks stay as INVISIBLE colliders; piers
re-skinned). Stairs: stylized stone re-skin. Every old stick torch is now a stone lantern or tiki torch.

## Collision rules (B139)
- **Floor discs are visual** (`collide = false`); the B134 `Floor`/`Rim` cylinders are invisible walk colliders.
- Gates / arches / colosseum meshes are `collide = false` (a mesh hull would block the passage); the arena keeps
  its 3-stud B134 walls as invisible colliders, the jungle arch has 2 `ArchCollider` parts.
- `CollisionFidelity` can NOT be set from `execute_luau` (silently stays Default = hull). Monuments with hulls
  (temple, altar, forge, stalls, towers) are fine because nobody walks inside them.

## Travel waystones (`Map.Travel`)
- `Plaza_<District>` x6 on the plaza's south arc (r 44) and `Stone_<District>` x6. Each model = invisible `Shaft`
  holding **ProximityPrompt `TravelPrompt`** (attribute **`TravelTo`**) + `Label` + invisible `Arrival`, plus the
  B139 visuals (`Waystone` mesh, `Aura_<Palette>`, `Sigil_<Palette>`; the model's `Palette` attribute).
- `LobbyMapService` does the teleport (`RequestStreamAroundAsync` first). `NpcPromptRouter` ignores these prompts.

## Water rescue
A player swimming for 4 s (root below Y 6 AND a terrain ray hits Water) is put back on `Plaza`.

## Lighting + terrain (B134; unchanged by B139)
Night: ClockTime 0.5, Brightness 3, ExposureCompensation 0.55, Atmosphere density 0.24, Bloom 0.55 / 28 / threshold
1.5, ColorCorrection +0.04 / 0.14 / 0.18. **`Lighting.Technology` must be set to `Future` BY HAND.**

## Working notes (B139, hard-won)
- **AI mesh generator: at most ~4 jobs at once** (8 concurrent = most fail "Unable to generate Model"). Results land
  at the workspace root with the prompt as name and usually SMALLER than the requested size -- scale after.
- **`screen_capture` with camera_position renders the scene wrong** (clipping); set `workspace.CurrentCamera.CFrame`
  from `execute_luau`, then capture with no camera args. Particles need a second capture to show.
- `ShowDevelopmentGui = false` also hides SurfaceGuis; preload images (`ContentProvider:PreloadAsync`) before
  previewing texture boards.

## Rules
- **`PersistentScene.PlayGUICamera` is the USER'S framing -- never move it** (`play-menu.md`).
- NPCs are free to move: every lookup is by name. They are `ModelStreamingMode = Persistent`.
- Budget (B139): map ~1.9k parts (was 4.5k -- palms are 1 mesh now), ~610 meshes, ~540 emitters (mostly low-rate),
  23 beams, ~150 lights (none new with shadows). Keep new lights shadowless.
- A new unit still needs its rig in `RS.UnitModels` here -- unrelated to the map, but the rule stands.
