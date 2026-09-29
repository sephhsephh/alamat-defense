# Unit Roster — design (B106, DRAFT for approval)
<!-- owner: AD-Game (towers) + AD-Gacha (tiers/banners) | status: DRAFT, nothing built | 2026-09-28 -->

The design is written here first; nothing gets built until the user approves the roster.
**Canon is this file.** A Claude Docs copy exists for reading/commenting, and changes are merged back here.

---

## 0. Decisions already made (user, B106)

- **Size:** ~28 new units (27 below + the renamed 8), one mythic being per tier. No duplicate
  beings across tiers — "Bathala" exists once; its stronger version is an EVOLVED FORM.
- **Names are NAMED figures, not generic words or translations** ("Bantong", not "Mandirigma" / "Warrior").
  Creature TYPES (Tikbalang, Kapre) are fine as names because the being itself is the legend.
- **The 8 old towers are renamed, Ids included** (user: no live players yet, so no save migration —
  the dev profile is simply reset). See §2.
- **Evolved forms exist, Mythic tier and up only.** Evolving costs fragments + items from a specific
  stage/act, quest items or a specific boss's drops. Display rule already in canon (B87): `Name (Form)`.
- **Upgrade tiers have a MINIMUM per rarity** (user, B106): Common 5, then +1 per tier up —
  Uncommon 6, Rare 7, Epic 8, Legendary 9, Mythic 10, Limited 11, Secret 12, Alamat 13. It is only a
  floor: a Common MAY have as many tiers as an Alamat.
- **Placement rule (user, B106):** Ground = ground zones only, cannot hit flying. **Hill = hill zones
  only.** **Hybrid = GROUND zones only, but CAN hit flying.** (Until now Hybrid could stand on either —
  `TowerPlacementRules.Allows` changes.)
- **Secret tier has 3 units:** Aswang, Tiyanak AND Batibat.
- **`BonusVsStatus` is replaced by one generic `BonusVs`.** Babaylan keeps its name. Necromancer's
  `MaxAlive = 400` and Archer tier 1's `ReleaseTime = 1` are the user's own values — kept.
- **Babaylan and Oryol are retuned into their tier bands** in the rename batch (numbers posted first).
- **Myth honesty:** anything I could not confirm is marked ⚠ in the Myth column. Fix it before it
  goes on a unit card.

## 1. Legend used in this doc

**Build tags** (what a unit or passive costs to make):
- **C** — config only. Existing passives, abilities, statuses and shapes cover it.
- **P** — one small new module on an EXISTING hook (passive/status module + one registry line). No engine change.
- **S#** — needs a new system (listed in §6).

**Existing hooks** (`PassiveHost`): `OnPlaced`, `OnStep`, `ModifyOutgoingDamage` (per enemy hit),
`OnKill`, `OnWaveIncome`, `OnRemoved`.
**Existing modules:** passives `FarmIncome`, `AllyDamageAura`, `BonusVsStatus`, `SummonOnKill`;
abilities `Nuke`, `TempStatBuff`, `StatusBurst`; statuses `Slow`, `Burn`, `Stun`, `Weaken`.
**Enemy facts that matter:** bosses have `IsBoss = true` and are **immune to Stun**; enemies have
`Armor`; `Manananggal` flies (Ground units can't hit it).

---

## 2. The 8 existing towers — renamed (Ids change, mechanics kept)

| Old Id | New Id / name | Tier | Myth source | Why it fits |
| --- | --- | --- | --- | --- |
| Archer | **Handyong** | Common | Bicol, *Ibalong* epic — the hero who cleared Ibalon of monsters | Ranged monster-hunter. ⚠ I could not confirm he used a bow; he is known as a monster slayer. New passive: +30% vs flying (P). |
| Knight | **Bantong** | Common | *Ibalong* — killed the half-man half-beast Rabot with one bolo strike | Melee dash. New passive *One Strike*: first hit on an enemy it has never hit +60% (P). |
| Mage | **Oryol** | Rare | *Ibalong* — the cunning shapeshifting serpent-woman, Handyong's rival and then ally | A Slow + Weaken trickster. |
| Farm | **Lakapati** | Rare | Tagalog deity of fertility and cultivated fields | Income. |
| Babaylan | **Babaylan** (kept, user) | Epic | The spiritual leader/healer role | Retuned into the Epic band. |
| Meteor | **Bulalakaw** | Legendary | Visayan/Bukidnon — the shooting star / fiery omen-bird | Barrage → Cataclysm is literally a falling star. |
| Warchief | **Urduja** | Legendary | Pangasinan — legendary warrior princess who led the Kinalakian women warriors | War Cry + ally aura = a commander. |
| Necromancer | **Magwayen** | Mythic | Visayan — sea deity who ferries souls to Sulad | Souls come back as summons. ⚠ confirm the soul-ferrier detail. |

**A rename touches** (both Places): the config module + `Id`, `TowerConfigRegistry`, `ItemCatalog`
(shared), `UnitStatsCatalog` (shared — regenerate + re-hash both Places + manifest), the rig in the
Game's `RS.TowerModels` AND the Lobby's `RS.UnitModels`, `VFXTemplates.Towers.<Id>`, banner pools,
harness seeds (`MatchLifecycleSmokeTest`, `DevSetOwnedTowers`), quest/challenge references, the dev profile (reset).

---

## 3. Balance intent per tier

Numbers are the **max-upgrade tier at reference** (MetaLevel 1, roll 0.5, no trait, ascension 0).
"DPS" = Damage ÷ SPA on the PRIMARY target — the same theoretical DPS the unit panel shows (B86).
AoE-wide units sit at the LOW end of their band, small-circle / single-focus ones at the HIGH end.
Support units are judged by the buff they give, not their DPS.

| Tier | DPS band | Cost | Limit | Min upgrade tiers | What this tier must do that the one below cannot |
| --- | --- | --- | --- | --- | --- |
| Common | 18–25 | 100–150 | 4–5 | 5 | One clear identity. 0–1 simple passive. |
| Uncommon | 25–35 | 150–200 | 4 | 6 | Carries ONE status effect, or a tiny economy trick. |
| Rare | 35–55 | 200–275 | 3 | 7 | A conditional passive (vs a status / flyer / boss), or a real support role. |
| Epic | 55–75 | 275–350 | 3 | 8 | A passive + an attack that CHANGES at the top tier, or two roles at once. |
| Legendary | 75–100 | 300–400 | 2–3 | 9 | 2 passives + an ACTIVE ability. |
| Mythic | 100–130 | 400–500 | 2 | 10 | 2–3 passives + ability + attack change; can EVOLVE. |
| Limited | 110–140 | 400–550 | 2 | 11 | Mythic power, a mechanic no other unit has; event-only. |
| Secret | 130–160 | 500–600 | 1–2 | 12 | **Breaks a normal rule** (hits flyers from Ground, ignores armor, changes form...). |
| Alamat | 160–200 | 600+ | 1 | 13 | **Map-level presence** — affects every ally or the whole map. |
| Evolved form | base +25–35% | same | same | same | The base unit + one NEW mechanic. |

⚠ **Existing units are already out of band:** Mage/Oryol (Rare) does **53**, while Babaylan (Epic) does 24
FullAoe. It's FullAoe so it's partly fair, but Babaylan reads weak for Epic. Retune while renaming? (§8)

**BUILT for the 8 existing towers at B106 pt2** (see CHANGELOG for the table). **Tier minimums are decided (§0).** Every unit has 3 today, so each existing tower gains tiers in the
rename batch (Handyong/Bantong 5, Oryol/Lakapati 7, Babaylan 8, Bulalakaw/Urduja 9, Magwayen 10). The DPS
band applies to the LAST tier; earlier tiers climb to it.

---

## 4. The roster

Columns: **Place** = placement (G Ground / H Hill / Hy Hybrid). **Shape** = the top-tier attack shape.
Passives list the build tag after each.

### COMMON (1 new; Handyong + Bantong are Common too)

| Unit | Myth | Place / Element | Shape / attack | Passives | Worth its tier |
| --- | --- | --- | --- | --- | --- |
| **Baltog** | Bicol, *Ibalong* — wrestled and broke the jaw of the giant boar Tandayag with his bare hands | G / Neutral | Short Box, melee dash | *Bare Hands*: +40% vs bosses (P) | The cheap anti-boss body. The Ibalong trio (Handyong/Bantong/Baltog) = the starter set. |

### UNCOMMON (4)

| Unit | Myth | Place / Element | Shape / attack | Passives | Worth its tier |
| --- | --- | --- | --- | --- | --- |
| **Duwende** | Widespread — small house/mound spirits that bring luck or misfortune | Hy / Nature | Small Circle, fast SPA | *Lucky Find*: 15% chance on a kill for bonus pesos (P) | An economy unit that still fights. |
| **Santelmo** | Widespread — the floating fireball (St. Elmo's fire), said to be a wandering soul | H / Fire | 2 `Fresh` hits, small Circles | Burn on hit (C); *Wandering Flame*: +25% vs burning (C, BonusVsStatus) | Burn spread across two targets. |
| **Mangkukulam** | Tagalog — the witch who curses through an effigy | Hy / Dark | Circle, pin projectile | Applies **Sumpa** (new status: +8% damage taken per stack, 5 stacks) (P) | A stacking debuff that makes every other unit better. |
| **Siyokoy** | Widespread — scaly sea creatures that drown people | G / Water | Forward Box | Slow on hit (C); *Undertow*: +30% vs slowed (C) | Slow + payoff in one body. |

### RARE (4)

| Unit | Myth | Place / Element | Shape / attack | Passives | Worth its tier |
| --- | --- | --- | --- | --- | --- |
| **Tikbalang** | Tagalog — horse-headed trickster that leads travellers astray | G / Neutral | Circle, **Teleport** melee (C) | *Lead Astray*: 20% chance a hit makes the enemy walk BACKWARD 1.5s; not bosses (S2) | The first CC that undoes enemy progress. |
| **Kapre** | Widespread — cigar-smoking tree giant of the balete/acacia | G / Nature | Cone (smoke) | Slow on hit (C); *Looming*: +5% damage per enemy in range, max +40% (P) | Gets stronger the thicker the wave. |
| **Nuno sa Punso** | Tagalog — the old dwarf of the anthill ("tabi-tabi po") | G / Nature, **Support** | none — never attacks | *Tabi-tabi Po*: every 0.5s, enemies in range get Weaken (P, "EnemyStatusAura") | The only debuffer that needs no hits. |
| **Sarimanok** | Maranao — the legendary bird of good fortune | H / Light | Small Circle, weak | *Good Fortune*: allies in range +10% crit chance (P — AllyDamageAura only multiplies; needs an `Add`) | The first crit support. |

### EPIC (4)

| Unit | Myth | Place / Element | Shape / attack | Passives | Worth its tier |
| --- | --- | --- | --- | --- | --- |
| **Engkanto** | Widespread — beautiful spirits that enchant and lure mortals | Hy / Light | Circle arrow → top tier **Volley**: 3 `Fresh` arrows (C) | *First Glance*: the first hit on each enemy always crits (P, see note); *Allure*: crits Stun 0.5s (S1) | Crit burst + attack change at the top. |
| **Mambabarang** | Visayan — the sorcerer who commands insects | H / Dark | Circle | Applies **Swarm** (new stacking DoT) (P); *Spread*: on a kill, Swarm jumps to the 2 nearest enemies (P) | Snowballing DoT across a wave. |
| **Amomongo** | Negros — ape-like creature with long claws. ⚠ Mostly a modern (2000s) sighting story, not old myth | G / Nature | Box claws, melee dash | *Frenzy*: every 10 kills, SPA −30% for 6s (P) | Burst windows on crowded waves. |
| **Sigbin** | Visayan — walks backward with its head between its legs, feeds through shadows | Hy / Dark | Circle | *Shadow Feeding*: +2% damage per consecutive hit on the same target, max +30% (S1) | The single-target ramp unit. |

Note on *First Glance*: crit is rolled in `AttackResolver` BEFORE the passive chain, so a passive can
multiply the damage but can't set the crit flag (no crit number pops). A true "forced crit" is a small
S1-style change.

### LEGENDARY (4) — 2 passives + an active

| Unit | Myth | Place / Element | Shape / attack | Passives | Active | Worth its tier |
| --- | --- | --- | --- | --- | --- | --- |
| **Lam-ang** | Ilocano, *Biag ni Lam-ang* — spoke at birth, avenged his father, killed the water monster Berkakan; his rooster's crow toppled a house | G / Neutral | Cone, melee dash | *Avenger*: +50% vs bosses (P); *Prodigy*: +3% damage per wave, max +30% (P) | *Rooster's Crow*: Stun everything in range 2s (C, StatusBurst — bosses immune) | The hero boss-killer. |
| **Bernardo Carpio** | Tagalog — the giant who holds two mountains apart; his struggle causes earthquakes | G / Neutral | FullAoe slam, slow and heavy | *Held Mountains*: every 5th attack is a quake that Stuns the whole range 1s (S1); *Unmoved*: immune to challenge `SpaMult` (S, small) | *Lindol*: Range Nuke ×4 (C) | The frontline crowd-lock. |
| **Maria Makiling** | Laguna — the diwata of Mt. Makiling; gave ginger to the poor that turned to gold | Hy / Nature, **Support** | weak Circle | *Golden Ginger*: per-wave income (C, FarmIncome); *Mountain's Blessing*: allies in range +10% Damage AND +8% Range (C, AllyDamageAura ×2) | *Mountain Mist*: Slow the whole map 3s (C) | **All config.** The best support in the game. |
| **Minokawa** | Bagobo — the giant bird that swallows the moon | H / Cosmic | 4 `Fresh` beak strikes | *Moon Eater*: +60% vs bosses (P); *Sky Hunter*: +30% vs flying (P) | *Swallow the Moon*: Map Nuke ×5 (C) | Anti-boss + anti-air carry. |

### MYTHIC (4 new + Magwayen) — can evolve

| Unit | Myth | Place / Element | Shape / attack | Passives | Active | Worth its tier |
| --- | --- | --- | --- | --- | --- | --- |
| **Apolaki** | Tagalog — god of the sun and war | H / Fire | Long Box beam from the tower → top tier **Solar Flare** (FullAoe + Burn) | *Rising Sun*: +6% damage per wave, max +48% (P); *Sibling Rivalry*: +15% if Mayari is on the field (P) | *High Noon*: SPA ×0.6 for 10s (C, TempStatBuff) | Late-game scaling carry. |
| **Mayari** | Tagalog — goddess of the moon, Apolaki's sister. ⚠ The "lost an eye fighting Apolaki" story is mostly from modern retellings | H / Light | Small Circle sniper, huge Range | *Moonlight Aim*: +20% crit chance (C, stat); *Sibling Rivalry* (P) | *Lunar Veil*: Slow the whole map 4s (C) | The precision boss-sniper; pairs with Apolaki. |
| **Aman Sinaya** | Tagalog — goddess of the sea | G / Water | Wide Box wave from the tower | *Tide*: hits push non-boss enemies back 3 studs (S2); *Deep Current*: Slow on hit (C) | *Great Wave*: Range Nuke ×6 (C) | Delay king — buys time. |
| **Sidapa** | Visayan — god of death, said to measure lifespans on a tree on Mt. Madya-as. ⚠ confirm details | Hy / Dark | Circle projectile | *Measured Life*: non-boss enemies below 15% HP are executed on hit (P); *Harvest*: +1% damage per kill this match, max +30% (P) | *Death's Toll*: Weaken the whole map 5s (C) | The executioner. |

### LIMITED (2) — event banners only

| Unit | Myth | Place / Element | Shape / attack | Passives | Novel mechanic |
| --- | --- | --- | --- | --- | --- |
| **Tala** | Tagalog — goddess of the stars. ⚠ Her family ties differ between tellings | H / Cosmic | 5-hit `Fresh` starfall (C) | *Guiding Star*: allies in range +10% Range (C); *Constellation*: every 3rd star hits all 5 targets at once (S1) | The only unit that buffs Range. |
| **Lalahon** | Visayan — goddess of fire/volcanoes (linked to Mt. Kanlaon) and harvest. ⚠ confirm | H / Fire | FullAoe eruption, stacking Burn | *Harvest Fire*: burning enemies you kill give bonus pesos (P); +50% vs burning (C) | Burn that pays out. |

### SECRET (3) — breaks a normal rule

| Unit | Myth | Place / Element | Shape / attack | Passives | The rule it breaks |
| --- | --- | --- | --- | --- | --- |
| **Aswang** | Widespread — the shapeshifting ghoul (dog, bird, human forms) | G / Dark | Changes every wave: **Dog** (melee dash Box) → **Bird** (3 `Fresh` hits, CAN hit flyers) → **Human** (ranged Circle) | *Shapeshift* (S7); *Feeding*: +2% damage per kill, max +40% (P) | A Ground unit that hits flyers in bird form. |
| **Tiyanak** | Tagalog — the demon that cries like a lost baby to lure people | G / Dark | Circle | *Lost Child's Cry*: an enemy entering range is Stunned once, not bosses (P, OnStep tracks who is new); *Bite*: hits ignore Armor (S, small) | Ignores armor. |
| **Batibat** | Ilocano — the tree spirit that sits on a sleeper's chest when her tree was cut for a house post (bangungot) | G / Dark | Circle crush | *Nightmare Weight*: enemies in range are Slowed 40% — **bosses too** (P, EnemyStatusAura with a boss-piercing flag); *Bangungot*: the slowest enemy in range falls **Asleep** (a stun that breaks when it takes damage; not bosses) (S, small) | Its CC works on bosses. |

⚠ **Manananggal is already an ENEMY**, so it isn't a Secret unit.

### ALAMAT (2) — map-level presence, limit 1

| Unit | Myth | Place / Element | Shape / attack | Passives | Active |
| --- | --- | --- | --- | --- | --- |
| **Bathala** | Tagalog — the supreme god, creator | Hy / Holy | FullAoe divine pulse | *Creator*: EVERY tower you own, anywhere on the map, +15% Damage (C, AllyDamageAura with a map-size Range); *Divine Judgement*: every enemy on the map takes +10% damage (P, EnemyStatusAura + new status "Judged") | *Word of Bathala*: Map Nuke ×10 (C) |
| **Bakunawa** | Visayan — the sea serpent that swallows the moon (eclipses); people bang pots to make it spit the moon out | Hy / Cosmic | Long Box lunge | *Moon Hunger*: every 7th attack is an **Eclipse** — the whole map takes 300% (S1 + a "Map" scope); *Serpent of the Deep*: +25% vs Water enemies (P) | *Devour*: Map Nuke ×8 (C) |

---

## 5. Evolved forms (Mythic tier and up)

**Requirements (user, B106).** EVERY evolution costs the **Rainbow** crafting item (⚠ the catalog has a
`ArtifactRainbow`, no "Rainbow Fragment" — assumed to be that) **plus a set number of one specific
fragment colour**. On top, each evolution picks ONE OR MORE extra gates:
- **Takedowns** — the unit instance has killed N enemies;
- **Owns unit** — you must own a specific other unit;
- **Sacrifice** — consume another owned unit (goes through `UnitConsumeRules`, the one "may this be destroyed" rule);
- **Max level** — the unit is at `MAX_META_LEVEL`.
Plus stage/act, quest or boss items where the design names them.

**Rule:** `Name (Form)` — the parenthesis is reserved for this (B87). An evolved form is its OWN
tower Id with an underscore (e.g. `Mayari_LunarEclipse`), which the Lobby's `UnitFamilyConfig` already
groups with its base (one unit per FAMILY in a loadout). **The blueprint is LAW here**
(`phases-b-f-meta.md` Phase F): `Configs/Evolutions/<TowerId>.luau = { Requires = { Items, Counters =
{ PerUnitKills }, Silver }, ResultTowerId }`; evolving CONSUMES the unit and grants the result instance
PRESERVING Trait/Shiny/StatRolls/Worthiness/Ascension; per-act rare drops with per-drop pity live in the
stage drop tables (`Counters.Global.DropPity[itemId]`). The user's extra gates (owns unit, sacrifice,
max level) EXTEND `Requires` — a blueprint extension approved by the user at B106.

| Evolved form | From | Adds | Materials (proposal) | Extra gate (proposal) |
| --- | --- | --- | --- | --- |
| **Mayari (Lunar Eclipse)** | Mayari | Crits during *Lunar Veil* chain to a 2nd target | Rainbow + 20 Violet + a *Moon Shard* (act boss) | Owns **Apolaki** |
| **Apolaki (Zenith)** | Apolaki | *Rising Sun* cap +48% → +80% | Rainbow + 20 Orange + a *Sun Relic* (act) | **Max level** |
| **Bathala (Ascended)** | Bathala | *Creator* also gives −10% SPA | Rainbow + 30 Yellow + a relic from EACH stage boss | **Sacrifice** a Mythic |
| **Bakunawa (Eclipse)** | Bakunawa | Eclipse every 5th attack, not 7th | Rainbow + 30 Blue + the eclipse event boss drop | **5,000 takedowns** |
| **B107 (built)** | Magwayen (Soulferry), Sidapa (Last Measure), Aman Sinaya (Riptide), Tala (Morning Star), Lalahon (Caldera), Aswang (Blood Moon), Tiyanak (Changeling), Batibat (Night Terror) — recipes + mechanics in `docs/systems/evolution.md` | | |

⚠ **Content gap:** only Stage 1 (3 acts, ONE boss — the Scarecrow King) exists, so "specific
boss/act drops" needs new stages/bosses first. The first evolution can use Stage 1 Act 3.

---

## 6. New systems this roster needs

| # | System | Unlocks | Size |
| --- | --- | --- | --- |
| **P-pack** | Generic passives on existing hooks: **BonusVs** (condition = Status / Flying / Boss / FirstHit / Element — replaces BonusVsStatus), **EnemyStatusAura**, **PerWaveRamp**, **KillStack**, **CashOnKill**, **StatusSpreadOnKill**, **Execute**, **SiblingBonus**, **EnemyEntersRange**; AllyDamageAura gets `Add`; new statuses **Sumpa**, **Swarm**, **Judged** (data) | ~20 of the 27 units | small modules, no engine change |
| **S1** | **On-attack hook + counters**: `OnAttack(n)` / every-Nth-attack / consecutive-hit stacks / forced crit | Sigbin, Bernardo, Engkanto, Tala, Bakunawa | medium — `AttackSequencer` + `PassiveHost` |
| **S2** | **Forced movement**: push back / walk backward (path-progress rewind) | Tikbalang, Aman Sinaya | medium — `EnemyController` (maybe just a status with a negative Speed — to test) |
| **S7** | **Per-wave attack swap** (the attack chosen by a passive, not the tier) | Aswang | small — `AttackProfile` override |
| S-small | Armor-pierce flag; immunity to `SpaMult`; "Map" hit scope | Tiyanak, Bernardo, Bakunawa | small each |
| **S-Evo** | **Evolution**: shared `EvolutionConfig` (base → form + recipe), a Lobby `EvolutionService` (the one writer, spends via `GrantService`), an NPC screen (authored UI), `ItemCatalog` relic items, drop-table entries | §5 | large, both Places |
| **S-Gacha** | Standard banner has **no Uncommon rate**; Limited banners for Tala/Lalahon; Secret pool finally non-empty | tiers | small config |
| later | Enemy shields / dodge (for "ignores shield" passives) | none in this roster | — |

---

## 7. Build order (after approval)

**Status (B106 pt3):** step 0 DONE (renames), tier expansion DONE, P-pack STARTED (`BonusVs`, `CashOnKill`, status `Sumpa`), units BUILT with placeholder rigs: **Baltog, Duwende, Santelmo, Mangkukulam, Siyokoy** (pt3) and **Kapre, Nuno sa Punso, Sarimanok, Mambabarang, Amomongo** (pt4; live-verified pt5 except the two Hill units, which TestMap's far hills cannot test). P-pack so far: BonusVs, CashOnKill, CrowdScaling, EnemyStatusAura, KillFrenzy, StatusSpreadOnKill, AllyDamageAura `Add`/ByTier; statuses Sumpa, Swarm. **pt7: S1 BUILT** (OnAttack + OnHitLanded hooks; ConsecutiveHits, EveryNthAttack, StatusOnCrit, PerWaveRamp, SiblingBonus, Execute, KillStack; status Judged) and units **Engkanto, Sigbin, Lam-ang, Bernardo Carpio, Maria Makiling, Minokawa, Apolaki, Mayari, Sidapa, Tala, Lalahon, Bathala, Bakunawa**. **pt8: S2 + S7 BUILT** and Tikbalang, Aman Sinaya, Aswang, Tiyanak, Batibat -- **all 27 roster units now exist**. **pt9: S-Evo BUILT** (4 forms; `docs/systems/evolution.md`). Remaining: real rigs/anims/VFX, more relic stages, the other Mythic+ forms.

0. **Renames** (§2) — one mechanical batch, both Places, dev profile reset. No new mechanics.
1. **P-pack + all-config units** — Baltog, Duwende, Santelmo, Mangkukulam, Siyokoy, Kapre, Nuno sa Punso,
   Sarimanok, Mambabarang, Amomongo, Maria Makiling, Lam-ang, Minokawa, Apolaki, Mayari, Sidapa, Lalahon,
   Bathala. Batches of 3–4 units per session, each verified live.
2. **S1** → Sigbin, Engkanto, Bernardo Carpio, Tala, Bakunawa.
3. **S2** → Tikbalang, Aman Sinaya. **S7** → Aswang. **Armor-pierce** → Tiyanak.
4. **S-Gacha** — Uncommon rate, Limited banners, Secret pool.
5. **S-Evo** — plus the stage/boss content its materials come from.

**Every new unit needs, in BOTH Places** (user rule — reminder each time):
Game: config + `TowerConfigRegistry` line, rig in `RS.TowerModels` with `IdleAnim`, `VFXTemplates.Towers.<Id>`
(optional at first). Shared: `ItemCatalog` (Tier), `UnitStatsCatalog` Stats + Costs + Placement →
regenerate, re-hash in BOTH Places + manifest. Lobby: the SAME rig in `RS.UnitModels`, same `IdleAnim`;
banner pools.

---

## 8. Open questions

All seven B106 questions are answered (§0). Still open:
1. **Cuts/swaps** — the user decides after seeing the units in game.
2. **"Rainbow fragment"** = `ArtifactRainbow`? (assumed)
3. **Takedowns** = the blueprint's `Counters.PerUnitKills` — confirm a per-instance kill counter exists before building S-Evo.
