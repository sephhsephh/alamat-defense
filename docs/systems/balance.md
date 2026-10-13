# Balance -- enemy HP/counts, Hard, co-op, economy, starters, rarity ladder (GAME + Lobby display)
<!-- owner: AD-Game (Lobby display: AD-Lobby) | since: B141 (2026-10-13) | design: docs/proposals/2026-10-13-balance-overhaul.md -->

## The files you tune (Game place, ReplicatedStorage.Configs)
| What | Where | Notes |
|---|---|---|
| Stage/act curve, Hard, co-op, kill-cash split, boss size, wave income | `Global.BalanceConfig` | every line commented |
| Grunt HP per wave, counts, mini-boss, boss | `Waves/Stage1/Stage1_ActN_Waves` | `WAVE_HP = { ... }` column + one `W(i, { grunt(6), tank(2) })` line per wave |
| Wave line helpers + group options (`every`, `delay`, `hp`, `mods`, `path`) | `Waves.WaveKit` | `WaveKit.Column(20, 1.10, 15)` prints a column |
| Enemy roles (HpRatio, speed, kill cash, model scale) | `Enemies/Stage1/{Lamanglupa,Kalabaw,DagangBukid}` | grunt / tank (x1.6, 0.75 speed) / sprinter (x0.7, 1.8 speed) |
| Act bosses (unit rigs walking the path) | `Enemies/Stage1/Stage1Bosses` | one line per boss: unit rig, name, HpRatio, speed, kill cash |
| Starting cash, sell refund | `Global.EconomyConfig` | start 800; wave income lives in the wave files (StartCash) |
| Act names, Recommended, headliner drop | `Stages/Stage1/Stage1_ActN` | Act 5: `HeadlinerDrop = { TowerId = "Apolaki", Chance, HardChance, Pity = 30 }` |

## The formula
`enemy HP = WAVE_HP[wave] x HpRatio x StageScale x ActScale x Mode HP x Co-op HP x BaseHealthScale x slider%`
`count = wave line count x Mode Count x Co-op Count` (floor, min 1; bosses never multiply -- they get CoopBossHp)
Wired in `MatchDirector` (ContentScale into EnemyHealthScale; `BalanceConfig.ScaleWaveList` once at match start;
`EnemySpawner.SetHealthScale` + `SetBossHealthExtra`), `WaveDirector` (passes group Health + Modifiers),
`EnemySpawner.Spawn(..., opts)` (group Health overrides the config + the old WaveScalingConfig curve; bosses scale
`BossModelScale` 1.6x; `TowerModel` = boss walks a unit rig). `[DIAG] Balance:` prints the live multipliers.

## Numbers (approved B141)
- StageScale 1 / 4.5 / 20 / 90 / 400 / 1800 / 8100 · ActScale 1.0 / 1.3 / 1.7 / 2.2 / 2.9.
- Hard ("Insane" on the wire): HP x2, count x1.5, kill cash x1.3. Co-op 2/3/4: count 1.25/1.5/1.75, HP 1.48/1.8/2.03,
  boss HP 1.85/2.7/3.55 (~0.9x the load per player vs solo). Kill cash: every present player gets cash/players x1.25.
- Economy: start 800; wave income 125 +8%/wave (boss wave x2) to EVERY player; kill cash 4/6/5, boss 150-300.
- Starters (Common Ground, cost 150, ups 120/180/260/360): Bantong 10 dmg/1.7 s/12 (damage), Baltog 8/1.05/10
  (speed), Handyong 9/2.4/18 (range). Sim ceilings at 4 towers: x2.96 / x3.00 / x3.04.
- Rarity ladder: power index `P = (DMG/SPA) x RNG^1.12` = 96 x {Common 1, Unc 1.35, Rare 1.8, Epic 2.5, Leg 3.4,
  Mythic 4.6, Limited 5.5, Secret/Alamat 6.5}, evolutions x1.3. Costs: 150/350/520/780/1250/2000/2400/3200/4000.
  Pre-B141 configs: `ServerStorage._TowerConfigs_PreB141`.

## Tools
`node tools/balance/sim.js` (one act, every starter) · `node tools/balance/sim.js ceiling` · `node tools/balance/tune.js '<json>'`
(try tier tables). The sim models the real Stage 1 path, targeting, splash, crits, the economy + buy policy, overlapping
waves, lives. It does NOT model stuns/slows/melee travel/meta levels. Verify with a Play run (MatchLifecycleSmokeTest +
AutoPlaceForEndScreenTest `DevSeed*`).

## Lobby side
`Configs.StageRegistry` (mirror) carries `RecommendedUnits`, `RecommendNote`, `Threats = { Flying, Boss }`; the Play
menu's Story panel shows them in `Details.Recommended` (authored) and warns (red line + toast on Select Stage) when
the loadout cannot answer a threat (Flying needs a Hill/Hybrid unit). `UnitStatsCatalog` (shared) regenerated B141.

## Enemy modifiers (B142)
Numbers:  (commented). Logic:  -- hooks called by
EnemyController: Apply (spawn), OnDamage (before armor; 0 = blocked, no min-1 chip), Step (Regen / Commander aura /
Bulwark), OnDeath (Explosive -> ; Splitter -> , counted via
 in WaveDirector). A wave line gives them: .
Set: Shielded 3 hits · Overshield 50% bar / 50% DR · Regen 1%/s (Burn stops it) · Explosive r8 stun 1.5 s · Fast x1.3 ·
Strong x1.5 HP · Splitter 2 x 35% · Commander r10 +20% speed · Immune (Stun/Slow/Sleep) · Bulwark 2 s every 10 s.
Model attributes for the client: Modifiers, Shields, Overshield(+Max), Bulwark; towers get Stunned.
Stage 1 schedule: Act 3 Shielded, Act 4 + Regen, Act 5 + Explosive. Verified B142 (shield/overshield/strong/fast/splitter math).

## Stage headliner drop (B142)
 -> RewardCalculator, Victory only, after the Weekend
Rush doubling (a unit is never doubled): pity counter , reset on a hit; routed
by ItemCatalog Kind "Tower" -> . Stage 1: Apolaki 0.5% / 1.5% Hard, pity 30.

## Not built yet
Client: modifier icons/shield count on enemy HP bars, an Explosive FX ( is fired if it exists),
a Stunned icon on units, the end screen's card for a UNIT drop, Lobby display of the pity counter. Boss abilities.
Stage 1 Infinite on the new roster. A farm-unit role.
