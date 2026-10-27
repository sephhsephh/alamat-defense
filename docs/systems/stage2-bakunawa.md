# Stage 2 "Bakunawa Cove" — acts, waves, enemies (B175, GAME + Lobby mirror)
<!-- owner: AD-Game (content) + AD-Lobby (PlayConfig / StageRegistry mirror) | last-verified: 2026-10-28 (B175, Play) -->

Five acts + Infinite on the B173 map `BakunawaCove` (`maps-bakunawa.md`), built in the Stage 1 pattern
(`balance.md`): one StageConfig + one `WaveKit` wave file per act, a role roster, unit-rig act bosses.

## Acts (Game `RS.Configs.Stages.Stage2.*`, waves `RS.Configs.Waves.Stage2.*`)
| Act | ActName | Boss (unit rig) | Mini-boss w8 | New modifiers | Mode |
|---|---|---|---|---|---|
| 1 | Landfall | Magwayen, Ferrier of Souls | — | first FLYERS (w6), Fast | Normal |
| 2 | The Drowned Village | Sidapa, Keeper of Lifespans | — | + Splitter | Normal |
| 3 | Skull Rock (boss wall) | Aman Sinaya, Queen of the Deep | Sidapa 35% | + Shielded, Overshield | Hard |
| 4 | Fortress of Tides | Mayari, the Hunted Moon | Aman Sinaya 35% | + Commander, Regen | Hard |
| 5 | The Moon-Eater | BAKUNAWA, the Moon-Eater | Mayari 35% | + Bulwark, Explosive | Hard |
Infinite: `Stage2_Infinite_Waves` (generated: skeletons, brutes every 3rd wave, gulls from w4, an act boss every
10th wave in act order), unlock = Act 3, pays 250 gold + 60 XP per 5 waves and a Blue Mutya per 10.
Act 5 headliner: `HeadlinerDrop = { TowerId = "Bakunawa", 0.5% / 1.5% Hard, Pity 30 }`.

## Roster (`RS.Configs.Enemies.Stage2.*`, English names; rigs `ServerStorage.Enemies.Stage2.*`)
| Id | Name | Role | HpRatio | Speed | Rig |
|---|---|---|---|---|---|
| SkeletonPirate | Skeleton Pirate | Grunt | 1.0 | 2.0 | **stand-in** (recoloured Grunt, `Placeholder` attr) |
| PirateBrute | Pirate Brute | Tank | 1.6 | 1.5 | **stand-in** (recoloured Iron Ox) |
| BilgeRat | Bilge Rat | Sprinter (Run) | 0.7 | 3.4 | final: Field Rat rig, hue-shifted |
| CursedGull | Cursed Gull | Flyer (FlyHeight 7) | 0.8 | 2.4 | **stand-in** (Manananggal copy) |
Bosses: `Stage2Bosses` (one line each; Bakunawa walks on its own Idle clip). **Speeds are ~2x Stage 1's**: the
path is 556 studs (Stage 1: 206) -- a grunt crosses in ~4.6 min (Stage 1 ~3.4). `StageScale[2] = 4.5` does the HP.

## Real rigs (pending one USER import)
The Blender models (Skeleton Pirate, Captain = Pirate Brute) + a new **Cursed Gull** are split per R15 part by
`tools/maps/pirate/enemy_rigs.py` -> `Downloads\BakunawaCove_Map\glb\BC_EnemyRigs.glb` (+ `.json`; 0 z-fight hits).
To finish: **import the GLB into the GAME Place** (File > Import 3D, Insert Using Scene Position + Anchored, rename
the root `BC_EnemyRigs`), then run `tools/enemy_rigs/build_stage2_rigs.luau` (Edit): it moves a Grunt rig's joints
onto the model's joint markers, welds the pieces, scales (grunt 2.3 / brute 3.0 studs, gull 2.6 wingspan) and
replaces the stand-ins. The gull's shoulder frames are turned +-90 deg so the walk clip's arm swing flaps the wings.

## Rewards + missions
- Gold: named curve **`Stage2`** (shared `RewardScalingConfig`, x1.75 Standard). Victory XP 180/270/450/570/720.
- Drops add `MutyaBlue` (Purple on Act 4, Mayari) at 4-12% -- Mutya are Legendary evolution mats; keep it rare.
- Star missions (shared `StageMissionsConfig`): time limits ~1.35x Stage 1's; stars pay Trait token / Banner
  Ticket / Blue Mutya (`STAGE2_STAR_REWARDS`).

## Lobby side
- `RS.Configs.StageRegistry` mirror: Stage2_Act1..5 + Infinite, names VERBATIM, `Threats.Flying = true`, new
  optional field `GoldCurve` (PlayController's reward preview passes the act's curve to `GoldBand`).
- `PlayConfig.Maps[2]` = BakunawaCove (acts, Infinite, card art/theme); `UpcomingMaps` keeps only the ??? teaser.
- `PartyService`: maps chain server-side -- a map's Act 1 needs the previous map's last act cleared.
- ⚠ `MatchmakingService.enqueue` checks no unlocks at all (any act, Stage 1 too) -- STATE PENDING.

## Verified (B175, Play)
Game: `DevStageId = "Stage2_Act1"` -- map loads, `Balance: stage x act = 4.50`, wave 1 skeletons walk the pier at
deck height (HP 90); a temp wave (reverted) spawned gulls at +7 studs (HP 72) and Boss_Bakunawa (HP 4050, 1.6x,
boss bar "BAKUNAWA, THE MOON-EATER"). Lobby: carousel shows Bakunawa Cove as a real locked stage (Acts 0/5),
ENTER -> "Clear the previous island first."; Stage 1 preview gold unchanged (300). NOT run: a full act to the end
(balance pass), a real Stage 2 launch Lobby -> Game, the real rigs (import skipped by the user).
