# Proposal: production balance overhaul (Stage 1 first)
<!-- owner: AD-Game (+ AD-Lobby for the Play-menu parts) | status: DRAFT for user approval | 2026-10-13 (B141) -->

User decisions already taken (B140 chat): co-op-friendly scaling · small start numbers (early enemies 20-30 HP,
late game millions-billions) · starters = Handyong / Bantong / Baltog, all Common GROUND · Hard = HP x2, count
x1.5 · co-op kill cash split to everyone · one mythic headliner per stage (= last act's boss, stage-exclusive
drop with pity) · acts 1-4 bosses = lower units of the same myth (banner units) · bosses spawn visibly larger.

## 1. Today (measured B140) -- why it needs a redo
- Stage 1 path = 160 studs; Grunt = 45 HP at speed 1 stud/s (160 s to cross). Waves grow x1.15 per wave
  (W15 = 7.1x). Acts differ only by `BaseHealthScale`. Act 1 already spawns FLYERS (W3/7/11/14) and THREE
  Scarecrow Kings on waves 5 and 15.
- Starter offer = Handyong (Common, Hybrid) / Bantong (Common, Ground) / Oryol (RARE, Hill).
- Units 15-110 dmg; nothing ties a unit's numbers to its rarity, so balancing one unit is guesswork.

## 2. ONE health formula (every factor is one number in one config)
```
enemy HP  = Roster HP ratio x WAVE_HP[wave] x StageScale x ActScale x Mode (Normal 1 / Hard 2) x CoopHP(players)
enemy count = wave line count x Mode (Normal 1 / Hard 1.5) x CoopCount(players)      (rounded down, min 1)
boss HP   = Boss.HPx x WAVE_HP[wave] x StageScale x ActScale x Mode x CoopBossHP(players)   (count never scales)
```
**WAVE_HP is written out in each act's wave file** -- the HP of the act's GRUNT on every wave, so "how strong is
wave 9" is a number you can read and edit, not a formula:
```lua
-- Stage1_Act1_Waves.lua
local WAVE_HP = { 20, 22, 24, 27, 30, 33, 36, 40, 44, 48, 53, 58, 64, 70, 77 }  -- grunt HP per wave (edit freely)
W(1, { grunt(6), tank(2) }),          -- 6 grunts (20 hp), 2 tanks (20 x 1.6 = 32 hp)
W(2, { grunt(8), sprinter(3) }),      -- sprinter = 20 x 0.7 = 14 hp, 1.8x speed
...
W(15, { grunt(12), boss() }),         -- boss = WAVE_HP[15] x the boss's HPx
```
(The default column is +10%/wave = x3.8 by W15, gentler than today's x7.1 because acts/stages now carry the
long-term growth. A helper prints the column for any curve so you can paste-and-tweak.)

## 3. Enemy roster (ratios to the grunt -- tune in each enemy's config)
| Role | HP x | Speed | Threat (HP x speed) | Notes |
|---|---|---|---|---|
| Grunt | 1.0 | 1.0 | 1.0 | the baseline |
| Tank | 1.6 | 0.75 | 1.2 | slow wall |
| Sprinter | 0.7 | 1.8 | 1.26 | rushes past slow towers |
| Flyer (Stage 2+) | 0.9 | 1.2 | 1.08 | only Hill/Hybrid can hit |
**Threat = HP x speed** is what a wave really costs the player (a fast enemy spends less time in range). It is
what the wave budget, Recommended units and the loadout warning are computed from. With your numbers
(grunt 12 / tank 20 / sprinter 8 @ 2x) tank and sprinter are both 1.33x -- your instinct was balanced.

## 4. Enemy modifiers (data-driven; a spawn group lists them: `grunt(6, { "Shielded" })`)
v1 set, from Anime Vanguards / Anime Expeditions (numbers are per-modifier config):
| Modifier | Effect | First seen |
|---|---|---|
| Shielded | blocks the next 3 hits (shield count shown over the HP bar) | S1 A3 |
| Regen | heals 1% max HP / s; burn/bleed stops it | S1 A4 |
| Explosive | on death, stuns units within 8 studs for 1.5 s | S1 A5 |
| Fast / Strong | +30% speed / +50% HP | S2 |
| Overshield | extra bar = 50% HP, -50% damage taken until it breaks | S2 bosses |
| Splitter | on death, 2 copies at 35% HP | S2 |
| Commander | aura: allies within 10 studs +20% speed, +20% HP | S3 |
| Immune | ignores stun / slow | S3 |
| Bulwark | immune to damage 2 s every 10 s | S3+ |
| Summoner (boss) | spawns 3 grunts every 12 s | S2+ bosses |
Each modifier = one small module under `Server.Enemies.Modifiers` (same shape as the existing StatusEffects).

## 4b. Match economy (research B141 -- Anime Vanguards / Anime Defenders / Anime Last Stand)
Reference points: AV story start ~800 yen (user), wave 1 clear paid +125 yen in one recorded AV story run;
farm units cost 550 (Epic, 250 -> 2,550 / wave over 4 upgrades, ~9k total) and 800 (Legendary, 250 -> 10,000 /
wave over 6 upgrades, ~39k total); ALS Speedcart 600 (350 -> 15,500 / wave); AD Bloomer 550 (-> 2,500 / wave).
Cash is its OWN scale (it does not follow enemy HP): the sink is UPGRADES, ~8-12x a unit's placement cost.
| Knob | Value | Why |
|---|---|---|
| Starting cash (story, every mode) | **800** | AV-like; 3-4 starters or 1 farm + 1-2 fighters on wave 1 |
| Wave income | **125 on W1, +8% per wave** (W15 ~ 370), boss waves x2 | the main income, paid to EVERY player |
| Kill cash | grunt 4 / tank 6 / sprinter 5 / mini-boss 60 / boss 150, SPLIT to all players x1.25 | small on purpose -- waves + farms carry the economy |
| Placement cost by rarity | Common 150-250 · Unc 300-400 · Rare 450-600 · Epic 650-900 · Leg 1,000-1,500 · Mythic 1,600-2,500 · Secret/Alamat 3,000-5,000 | |
| Full upgrade cost | ~8-12x placement | upgrades are where the cash goes |
| Farm role (new, later) | Uncommon farm: 400 to place, 100 -> 1,200 / wave over 4 upgrades; Legendary farm: 800, 250 -> 8,000 / wave over 6 | the AV pattern, scaled to our wave count |
| Sell refund | 60% (unchanged) | |

## 5. Starters (Common, Ground, cost 150-200 each, start cash 800)
| Unit | Role | DMG | SPA | RNG | DPS | Coverage idea |
|---|---|---|---|---|---|---|
| Bantong | best DAMAGE (heavy single hits, small cone) | 10 | 1.8 | 12 | 5.6 | hits hard where it stands |
| Baltog | best SPEED (fast jabs) | 8 | 1.1 | 10 | 7.3 | short reach, fastest |
| Handyong | best RANGE (small-circle AoE) | 9 | 2.2 | 19 | 4.1 | covers the most path |
Balanced on **damage per enemy pass** (DPS x path in range, straight-path estimate 2 x RNG): Bantong 134,
Baltog 146, Handyong 156 -- within ~15%, and the map's zig-zags favour long range a little more, which is
Handyong's identity. The AutoPlay harness confirms on the real path before ship. Wave 1 (6x 20 hp grunts): two starters clear it with
time to spare; the 3rd placement matters by wave 5.

## 6. Rarity power ladder (the rule every other unit is retuned to)
Damage-per-slot vs a Common at the same level: Uncommon 1.35x · Rare 1.8x · Epic 2.5x · Legendary 3.4x ·
Mythic 4.6x · Limited 5.5x · Secret / Alamat 6.5x (evolutions +30%). Placement limits and cost rise with rarity,
so a full team still scales roughly x1.4 per rarity step. All 48 towers get re-numbered to this ladder in ONE
pass (+ UnitStatsCatalog regenerated, Lobby redeploy = shared-canon PENDING).

## 7. Progression curve: what the player is assumed to own
| Content | Assumed team | StageScale x ActScale (acts 1-5) |
|---|---|---|
| Stage 1 | starters + 1-2 Uncommon/Rare from summons, Lv 1-15 | 1.0 x {1.0, 1.3, 1.7, 2.2, 2.9} |
| Stage 2 | Rares + an Epic, first flyers -> needs Hill/Hybrid | 4.5 x same act column |
| Stage 3 | Epics + a Legendary, Lv 20-40 | 20 x ... |
| Stage 4 | Legendary core + a Mythic | 90 x ... |
| Stage 5+ | Mythics / evolutions / ascension | x4.5 per stage -> millions by Stage 7, billions in endgame/Infinite |
Rule of thumb: each act ~x1.3, each stage ~x4.5 -- the same ratio as the rarity ladder x levels the player
gains there. Infinite mode keeps the +10%/wave column forever.

## 8. Co-op (chosen: co-op-friendly, kill cash split)
| Players | CoopCount | CoopHP | Total load vs solo | Boss HP |
|---|---|---|---|---|
| 1 | 1.00 | 1.00 | 1.00 | 1.00 |
| 2 | 1.25 | 1.48 | 1.85 | 1.85 |
| 3 | 1.50 | 1.80 | 2.70 | 2.70 |
| 4 | 1.75 | 2.03 | 3.55 | 3.55 |
Per player that is ~0.9x solo -- playing together is a little easier (the social incentive AV/TDS use).
Kill cash: every kill pays EVERY player `KillCash / players x 1.25` (sharing beats kill-stealing).

## 9. Hard mode + rewards (research: AV Normal 160 gems vs Nightmare 240 per run; AE gives Hard its own
## first-clear set; UTD-style pity on unit drops)
- Hard unlocks per act after its Normal clear. HP x2, count x1.5 (= 3x load), +30% enemy kill cash.
- Rewards: Hard = x1.5 gold / XP, its OWN first-clear reward (gems + a Trait Reroll), x2 drop chances.
- **Headliner (final-act boss) unit drop:** Normal 0.5% / Hard 1.5% per clear; PITY by rarity --
  Mythic 30 clears, Limited 60, Secret 90, Alamat 120 (counter per player per stage, shown in the Play menu).
- Acts 1-4 bosses: banner units (no drop); their act drops their ascension food more often.

## 10. Bosses
- One per act, wave 15 (and a MINI-boss = previous act's boss at 50% HP on wave 8, from Act 2 on).
- Spawn at **1.6x** their unit model's scale (`BossScale`, per boss), gold name plate, own HP bar.
- Boss = the unit's rig + `Boss.HPx` (Act 1 = 25x grunt, +5x per act) + 1 ability from the modifier list.

## 11. Lobby: Recommended + loadout warning
- Each StageConfig gains `Recommended = { Units = { "Bantong", "Baltog" }, Note = "Ground units are enough" }`.
- The wave files are scanned once into `Threats = { Flying = true, Shielded = 3, Boss = "Apolaki" }`.
- Creating a lobby / starting an act: if Threats.Flying and no loadout unit `CanHitFlying` -> warning
  "This act has flying enemies -- none of your units can hit them" (Start anyway / Change loadout). Same idea for
  Shielded (needs fast hitters) and Immune.

## 12. Build order (each step verified with the AutoPlay harness: `DevSeedCount/Meta/Rolls`)
1. Balance config + formula wiring (no number changes yet) -> 2. roster + Stage 1 waves rewritten (no flyers)
-> 3. starters + rarity ladder pass (UnitStatsCatalog regen + Lobby PENDING) -> 4. modifiers -> 5. co-op +
Hard + cash split -> 6. bosses (scale, mini-boss, drop + pity) -> 7. Lobby Recommended + warning.

## Answered (user, B141)
1. Stage 1 headliner = **Apolaki** (sun god; rice-terrace sun temple). Act bosses: 1 Duwende, 2 Santelmo,
   3 Kapre, 4 Lam-Ang, 5 Apolaki (stage-exclusive drop, pity 30).
2. Rarity ladder (section 6) + stage/act curve (section 7): **approved**.
3. Economy: research-based (section 4b) -- start 800, wave income 125 +8%/wave, small split kill cash.
