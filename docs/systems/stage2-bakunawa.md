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
| SkeletonPirate | Skeleton Pirate | Grunt | 1.0 | 1.3 | **stand-in** (recoloured Grunt, `Placeholder` attr) |
| PirateBrute | Pirate Brute | Tank | 1.6 | 1.0 | **stand-in** (recoloured Iron Ox) |
| BilgeRat | Bilge Rat | Sprinter (Run) | 0.7 | 2.3 | final: Field Rat rig, hue-shifted |
| CursedGull | Cursed Gull | Flyer (FlyHeight 7) | 0.8 | 1.6 | **stand-in** (Manananggal copy) |
Bosses: `Stage2Bosses` (speed 0.65-0.8; Bakunawa walks on its own Idle clip). `StageScale[2] = 4.5` does the HP.

## Balance pass (B175, `tools/balance/sim.js`, `SIM_PATH=stage2 SPEED=x node tools/balance/sim.js ceiling`)
The cove path is 556 studs of LONG STRAIGHT lanes (Stage 1: 206, tightly folded), so each unit covers less of it.
4-tower starter ceilings (max act HP multiplier beaten): Stage 1 x2.7-3.6; Stage 2 at 2x speed x1.25-1.5 (would make
Stage 2 ~10x Stage 1, not the planned 4.5x); 1x speed x2.6-3.1 but clears take 22+ min. **Chosen: 1.3x Stage 1
speeds** -- ceilings x2.0-2.4 (~75% of Stage 1: x4.5 stage scale becomes ~6x effective = "Rares + an Epic",
`BalanceConfig`), a solid clear ~1.46x Stage 1's time (~19-20 min) -> TimeUnder missions 880 / 1050 / 1140 s.
Not modelled: flyers (starters are Ground: a Stage 2 team NEEDS a Hill/Hybrid unit from Act 1 wave 6, by design),
modifiers, real Rare/Epic stats. A full-act Play run is still the final check.

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
- Star missions (shared `StageMissionsConfig`, eaabd4d1): time limits ~1.46x Stage 1's (sim); stars pay Trait token / Banner
  Ticket / Blue Mutya (`STAGE2_STAR_REWARDS`).

## Lobby side
- `RS.Configs.StageRegistry` mirror: Stage2_Act1..5 + Infinite, names VERBATIM, `Threats.Flying = true`, new
  optional field `GoldCurve` (PlayController's reward preview passes the act's curve to `GoldBand`).
- `PlayConfig.Maps[2]` = BakunawaCove (acts, Infinite, card art/theme); `UpcomingMaps` keeps only the ??? teaser.
- `PartyService`: maps chain server-side -- a map's Act 1 needs the previous map's last act cleared.
- ONE unlock rule `PlayConfig.LockReason(stageId, difficulty, clears)` (maps chain, act chain, Infinite, Hard): used
  by `PartyService` (launch) AND `MatchmakingService.enqueue` (B175; it checked nothing before). Verified: queueing
  Stage2_Act5 -> "Clear Act 4 first.", Stage2_Act1 -> "Clear Apolaki's Sun Terraces first."

## Verified (B175, Play)
Game: `DevStageId = "Stage2_Act1"` -- map loads, `Balance: stage x act = 4.50`, wave 1 skeletons walk the pier at
deck height (HP 90); a temp wave (reverted) spawned gulls at +7 studs (HP 72) and Boss_Bakunawa (HP 4050, 1.6x,
boss bar "BAKUNAWA, THE MOON-EATER"). Lobby: carousel shows Bakunawa Cove as a real locked stage (Acts 0/5),
ENTER -> "Clear the previous island first."; Stage 1 preview gold unchanged (300). NOT run: a full act to the end
(balance pass), a real Stage 2 launch Lobby -> Game, the real rigs (import skipped by the user).
