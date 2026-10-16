--!strict
-- UnitInfoCatalog (SHARED CANON, both Places) -- B108 pt14.
-- Per-tower PRESENTATION data for the Lobby Units screen: element, placement, the in-match upgrade
-- path (per-tier DMG / RNG / SPA / cost / attack), the unit's passives and its active ability.
-- GENERATED from the Game's RS.Configs.Towers.* by tools/unit_info_gen.luau (run in the Game, Edit; B154 regen);
-- the Game's tower configs stay the source of truth -- regenerate after retuning a tower; Server.UnitInfoCatalogValidate
-- (Game boot) fails loud while these rows are stale.
-- The Lobby has no tower configs, which is why this exists (same reason UnitStatsCatalog does).
--
-- Data row: D.<TowerId> = { Element, Placement, PlacementLimit, Cost, CritChance, CritMultiplier,
--   { [attackName] = hitsPerAttack }, Ability|false = { Name, Id, Cooldown, Params },
--   Passives = { { Id, Name, Params } }, Tiers = { { DMG, RNG, SPA, UpgradeCost [, Income, Attack, Shape, Effects] } } }
-- A tier row carries Attack/Shape/Effects only when they CHANGE (the accessor carries them forward).
-- `UpgradeCost` on tier i is the price of tier i+1 (0 on the last tier); tier 1 costs the placement Cost.

local UnitInfoCatalog = {}
local D: { [string]: any } = {}
-- B161: I.<TowerId> = the unit's idle clip, GENERATED from its config's `Idle.Anim` (the ONE source of a unit's
-- animation). Every viewport in both Places plays it through UIKit.UnitCard.playIdle.
local I: { [string]: string } = {}
D.AmanSinaya={"Water","Ground",2,2000,0.05,2,{Tsunami=2,Wave=1},{"Great Wave","Nuke",40,{Mult=6,Scope="Range"}},{{"Knockback","Tide",{Chance=1,StudsByTier={2,2,2.5,2.5,3,3,3.5,3.5,4,4}}}},{{46,14,2,675,0,"Wave","Box 6x14","Slow"},{52,15,1.98,865,0,"Wave","Box 6.3x15","Slow"},{58,15,1.96,1095,0,"Wave","Box 6.7x15","Slow"},{66,16,1.93,1410,0,"Wave","Box 7x16","Slow"},{75,17,1.91,1810,0,"Wave","Box 7.3x17","Slow"},{85,17,1.89,2315,0,"Wave","Box 7.7x17","Slow"},{96,18,1.87,2970,0,"Wave","Box 8x18","Slow"},{108,19,1.84,3790,0,"Wave","Box 8.3x19","Slow"},{122,19,1.82,4865,0,"Wave","Box 8.7x19","Slow"},{138,20,1.8,0,0,"Tsunami","Box 9x20","Slow"}}}
D.AmanSinaya_Riptide={"Water","Ground",2,2000,0.05,2,{Tsunami=2,Wave=1},{"Great Wave","Nuke",40,{Mult=6,Scope="Map"}},{{"Knockback","Tide",{Chance=1,StudsByTier={2,2,2.5,2.5,3,3,3.5,3.5,4,4}}}},{{60,14,2,675,0,"Wave","Box 6x14","Slow"},{68,15,1.98,865,0,"Wave","Box 6.3x15","Slow"},{76,15,1.96,1095,0,"Wave","Box 6.7x15","Slow"},{86,16,1.93,1410,0,"Wave","Box 7x16","Slow"},{97,17,1.91,1810,0,"Wave","Box 7.3x17","Slow"},{110,17,1.89,2315,0,"Wave","Box 7.7x17","Slow"},{125,18,1.87,2970,0,"Wave","Box 8x18","Slow"},{141,19,1.84,3790,0,"Wave","Box 8.3x19","Slow"},{159,19,1.82,4865,0,"Wave","Box 8.7x19","Slow"},{179,20,1.8,0,0,"Tsunami","Box 9x20","Slow"}}}
D.Amomongo={"Nature","Ground",3,780,0.07,2,{Claw=1,Rend=2},false,{{"KillFrenzy","Frenzy",{Duration=6,Kills=10,Mult=0.7,Stat="SPA"}}},{{53,9,2.6,340,0,"Claw","Box 4x5",""},{64,10,2.54,455,0,"Claw","Box 4.3x5.3",""},{77,10,2.49,610,0,"Claw","Box 4.6x5.6",""},{93,11,2.43,830,0,"Claw","Box 4.9x5.9",""},{113,12,2.37,1120,0,"Claw","Box 5.1x6.1",""},{137,12,2.31,1520,0,"Claw","Box 5.4x6.4",""},{165,13,2.26,2040,0,"Claw","Box 5.7x6.7",""},{200,14,2.2,0,0,"Rend","Box 6x7",""}}}
D.Apolaki={"Fire","Hill",2,2000,0.06,2,{SolarFlare=1,Sunbeam=1},{"High Noon","TempStatBuff",40,{Duration=10,Mult=0.6,Stat="SPA"}},{{"PerWaveRamp","Rising Sun",{Max=0.48,PerWave=0.06}},{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Mayari"}}},{{18,24,1.4,710,0,"Sunbeam","Box 4x24",""},{20,25,1.38,910,0,"Sunbeam","Box 4.2x25",""},{22,26,1.36,1155,0,"Sunbeam","Box 4.4x26",""},{25,27,1.33,1490,0,"Sunbeam","Box 4.7x27",""},{28,28,1.31,1910,0,"Sunbeam","Box 4.9x28",""},{31,28,1.29,2445,0,"Sunbeam","Box 5.1x28",""},{35,29,1.27,3135,0,"Sunbeam","Box 5.3x29",""},{39,30,1.24,4000,0,"Sunbeam","Box 5.6x30",""},{44,31,1.22,5135,0,"Sunbeam","Box 5.8x31",""},{49,32,1.2,0,0,"SolarFlare","FullAoe","Burn"}}}
D.Apolaki_Zenith={"Fire","Hill",2,2000,0.06,2,{SolarFlare=1,Sunbeam=1},{"High Noon","TempStatBuff",40,{Duration=10,Mult=0.6,Stat="SPA"}},{{"PerWaveRamp","Rising Sun",{Max=0.8,PerWave=0.08}},{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Mayari"}}},{{23,24,1.4,710,0,"Sunbeam","Box 4x24",""},{25,25,1.38,910,0,"Sunbeam","Box 4.2x25",""},{29,26,1.36,1155,0,"Sunbeam","Box 4.4x26",""},{32,27,1.33,1490,0,"Sunbeam","Box 4.7x27",""},{36,28,1.31,1910,0,"Sunbeam","Box 4.9x28",""},{40,28,1.29,2445,0,"Sunbeam","Box 5.1x28",""},{45,29,1.27,3135,0,"Sunbeam","Box 5.3x29",""},{50,30,1.24,4000,0,"Sunbeam","Box 5.6x30",""},{57,31,1.22,5135,0,"Sunbeam","Box 5.8x31",""},{64,32,1.2,0,0,"SolarFlare","FullAoe","Burn"}}}
D.Aswang={"Dark","Ground",1,3200,0.06,2,{Bird=3,Dog=1,Human=1},false,{{"FormCycle","Form Cycle",{Forms={{Attack="Dog",CanHitFlying=false,Name="Dog"},{Attack="Bird",CanHitFlying=true,Name="Bird"},{Attack="Human",CanHitFlying=false,Name="Human"}}}},{"KillStack","Feeding",{Max=0.4,PerKill=0.02}}},{{62,14,1.9,1045,0,"Human","Circle 4",""},{71,15,1.88,1310,0,"Human","Circle 4.1",""},{80,15,1.86,1630,0,"Human","Circle 4.3",""},{93,16,1.85,2035,0,"Human","Circle 4.4",""},{105,16,1.83,2560,0,"Human","Circle 4.5",""},{120,17,1.81,3200,0,"Human","Circle 4.7",""},{138,17,1.79,3985,0,"Human","Circle 4.8",""},{157,18,1.77,5005,0,"Human","Circle 5",""},{179,18,1.75,6255,0,"Human","Circle 5.1",""},{205,19,1.74,7795,0,"Human","Circle 5.2",""},{234,19,1.72,9745,0,"Human","Circle 5.4",""},{267,20,1.7,0,0,"Human","Circle 5.5",""}}}
D.Aswang_BloodMoon={"Dark","Ground",1,3200,0.06,2,{Bird=3,Dog=1,Human=1},false,{{"FormCycle","Form Cycle",{Forms={{Attack="Dog",CanHitFlying=false,Name="Dog"},{Attack="Bird",CanHitFlying=true,Name="Bird"},{Attack="Human",CanHitFlying=false,Name="Human"}}}},{"KillStack","Feeding",{Max=0.8,PerKill=0.02}}},{{80,14,1.9,1045,0,"Human","Circle 4",""},{93,15,1.88,1310,0,"Human","Circle 4.1",""},{104,15,1.86,1630,0,"Human","Circle 4.3",""},{120,16,1.85,2035,0,"Human","Circle 4.4",""},{137,16,1.83,2560,0,"Human","Circle 4.5",""},{156,17,1.81,3200,0,"Human","Circle 4.7",""},{179,17,1.79,3985,0,"Human","Circle 4.8",""},{205,18,1.77,5005,0,"Human","Circle 5",""},{232,18,1.75,6255,0,"Human","Circle 5.1",""},{266,19,1.74,7795,0,"Human","Circle 5.2",""},{304,19,1.72,9745,0,"Human","Circle 5.4",""},{348,20,1.7,0,0,"Human","Circle 5.5",""}}}
D.Babaylan={"Neutral","Hybrid",2,780,0.04,2,{Pulse=5},false,{},{{19,22,2.5,260,0,"Pulse","FullAoe",""},{24,23,2.44,365},{31,24,2.39,480},{40,25,2.33,650},{52,27,2.27,885,0,"Pulse","FullAoe","Slow"},{66,28,2.21,1195},{85,29,2.16,1610},{109,30,2.1,0}}}
D.Bakunawa={"Cosmic","Hybrid",1,4000,0.06,2,{Lunge=1},{"Devour","Nuke",60,{Mult=8,Scope="Map"}},{{"EveryNthAttack","Moon Hunger",{MapStrike=3,N=7}},{"BonusVs","Serpent of the Deep",{Condition="Element",Element="Water",Mult=1.25}}},{{43,22,2.2,1065,0,"Lunge","Box 6x22",""},{48,23,2.18,1335,0,"Lunge","Box 6.2x23",""},{53,24,2.17,1680,0,"Lunge","Box 6.3x24",""},{59,25,2.15,2080,0,"Lunge","Box 6.5x25",""},{65,25,2.13,2615,0,"Lunge","Box 6.7x25",""},{72,26,2.12,3255,0,"Lunge","Box 6.8x26",""},{80,27,2.1,4080,0,"Lunge","Box 7x27",""},{89,28,2.08,5095,0,"Lunge","Box 7.2x28",""},{98,29,2.07,6345,0,"Lunge","Box 7.3x29",""},{109,30,2.05,7945,0,"Lunge","Box 7.5x30",""},{121,30,2.03,9945,0,"Lunge","Box 7.7x30",""},{134,31,2.02,12425,0,"Lunge","Box 7.8x31",""},{149,32,2,0,0,"Lunge","Box 8x32",""}}}
D.Bakunawa_Eclipse={"Cosmic","Hybrid",1,4000,0.06,2,{Lunge=1},{"Devour","Nuke",60,{Mult=8,Scope="Map"}},{{"EveryNthAttack","Moon Hunger",{MapStrike=3,N=5}},{"BonusVs","Serpent of the Deep",{Condition="Element",Element="Water",Mult=1.25}}},{{56,22,2.2,1065,0,"Lunge","Box 6x22",""},{62,23,2.18,1335,0,"Lunge","Box 6.2x23",""},{69,24,2.17,1680,0,"Lunge","Box 6.3x24",""},{76,25,2.15,2080,0,"Lunge","Box 6.5x25",""},{85,25,2.13,2615,0,"Lunge","Box 6.7x25",""},{94,26,2.12,3255,0,"Lunge","Box 6.8x26",""},{104,27,2.1,4080,0,"Lunge","Box 7x27",""},{115,28,2.08,5095,0,"Lunge","Box 7.2x28",""},{128,29,2.07,6345,0,"Lunge","Box 7.3x29",""},{142,30,2.05,7945,0,"Lunge","Box 7.5x30",""},{157,30,2.03,9945,0,"Lunge","Box 7.7x30",""},{175,31,2.02,12425,0,"Lunge","Box 7.8x31",""},{193,32,2,0,0,"Lunge","Box 8x32",""}}}
D.Baltog={"Neutral","Ground",4,150,0.05,2,{Grapple=1},false,{{"BonusVs","Bare Hands",{Condition="Boss",Mult=1.4}}},{{8,10,1.05,120,0,"Grapple","Circle 1.5",""},{10,10.5,1,180},{14,11,0.95,260},{18,11.5,0.9,360,0,"Grapple","Circle 1.75",""},{23,12,0.85,0,0,"Grapple","Circle 2",""}}}
D.Bantong={"Neutral","Ground",4,150,0.05,2,{Slash=1},false,{{"BonusVs","Bonus Vs",{Condition="FirstHit",Mult=1.6}}},{{10,12,1.7,120,0,"Slash","Circle 2.5",""},{13,12.5,1.65,180},{17,13,1.6,260,0,"Slash","Circle 2.75",""},{22,13.5,1.55,360,0,"Slash","Circle 3",""},{29,14,1.5,0,0,"Slash","Cone 120","Stun"}}}
D.Bathala={"Holy","Hybrid",1,4000,0.06,2,{Pulse=5},{"Word of Bathala","Nuke",60,{Mult=10,Scope="Map"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.15,Range=9999,Stat="Damage"}},{"EnemyStatusAura","Divine Judgement",{Duration=2,Interval=1,Range=9999,Status="Judged"}}},{{32,26,2,1145,0,"Pulse","FullAoe",""},{37,27,1.98,1430},{41,28,1.97,1800},{46,29,1.95,2230},{52,30,1.93,2800},{58,31,1.92,3485},{66,32,1.9,4370},{74,33,1.88,5455},{83,34,1.87,6800},{94,35,1.85,8515},{106,36,1.83,10655},{119,37,1.82,13315},{134,38,1.8,0}}}
D.Bathala_Ascended={"Holy","Hybrid",1,4000,0.06,2,{Pulse=5},{"Word of Bathala","Nuke",60,{Mult=10,Scope="Map"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.15,Range=9999,Stat="Damage"}},{"AllyDamageAura","Ascended Will",{Interval=0.5,Mult=0.9,Range=9999,Stat="SPA"}},{"EnemyStatusAura","Divine Judgement",{Duration=2,Interval=1,Range=9999,Status="Judged"}}},{{42,26,2,1145,0,"Pulse","FullAoe",""},{48,27,1.98,1430},{54,28,1.97,1800},{60,29,1.95,2230},{68,30,1.93,2800},{76,31,1.92,3485},{86,32,1.9,4370},{96,33,1.88,5455},{109,34,1.87,6800},{122,35,1.85,8515},{137,36,1.83,10655},{154,37,1.82,13315},{173,38,1.8,0}}}
D.Batibat={"Dark","Ground",1,3200,0.05,2,{Crush=1},false,{{"EnemyStatusAura","Nightmare Weight",{Duration=1,Interval=0.5,Potency=0.8,Status="Slow"}},{"SleepAura","Bangungot",{Duration=3,Interval=3}}},{{50,16,1.8,1000,0,"Crush","Circle 4",""},{58,17,1.79,1250,0,"Crush","Circle 4.1",""},{66,17,1.77,1560,0,"Crush","Circle 4.3",""},{75,18,1.76,1950,0,"Crush","Circle 4.4",""},{86,18,1.75,2450,0,"Crush","Circle 4.5",""},{98,19,1.73,3060,0,"Crush","Circle 4.7",""},{113,19,1.72,3810,0,"Crush","Circle 4.8",""},{128,20,1.7,4785,0,"Crush","Circle 5",""},{147,20,1.69,5985,0,"Crush","Circle 5.1",""},{168,21,1.68,7455,0,"Crush","Circle 5.2",""},{192,21,1.66,9320,0,"Crush","Circle 5.4",""},{220,22,1.65,0,0,"Crush","Circle 5.5",""}}}
D.Batibat_NightTerror={"Dark","Ground",1,3200,0.05,2,{Crush=1},false,{{"EnemyStatusAura","Nightmare Weight",{Duration=1,Interval=0.5,Potency=0.8,Status="Slow"}},{"SleepAura","Bangungot",{Duration=3,Interval=3}},{"BonusVs","Rude Awakening",{Condition="Status",Mult=2,Status="Sleep"}}},{{65,16,1.8,1000,0,"Crush","Circle 4",""},{75,17,1.79,1250,0,"Crush","Circle 4.1",""},{85,17,1.77,1560,0,"Crush","Circle 4.3",""},{97,18,1.76,1950,0,"Crush","Circle 4.4",""},{111,18,1.75,2450,0,"Crush","Circle 4.5",""},{126,19,1.73,3060,0,"Crush","Circle 4.7",""},{145,19,1.72,3810,0,"Crush","Circle 4.8",""},{165,20,1.7,4785,0,"Crush","Circle 5",""},{190,20,1.69,5985,0,"Crush","Circle 5.1",""},{217,21,1.68,7455,0,"Crush","Circle 5.2",""},{248,21,1.66,9320,0,"Crush","Circle 5.4",""},{284,22,1.65,0,0,"Crush","Circle 5.5",""}}}
D.BernardoCarpio={"Neutral","Ground",2,1250,0.05,2,{Slam=1},{"Lindol","Nuke",30,{Mult=4,Scope="Range"}},{{"EveryNthAttack","Held Mountains",{Duration=1,N=5,Status="Stun"}}},{{65,12,3.2,440,0,"Slam","FullAoe",""},{75,13,3.14,565},{89,13,3.08,735},{104,14,3.01,970},{123,15,2.95,1250},{144,15,2.89,1625},{169,16,2.83,2110},{198,16,2.76,2750},{233,17,2.7,0}}}
D.Bulalakaw={"Fire","Hill",3,1250,0.05,2,{Barrage=3,Cataclysm=1},{"Meteor Strike","Nuke",15,{Mult=6,Scope="Map"}},{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}}},{{13,24,1.4,440,0,"Barrage","Circle 5",""},{15,25,1.38,585,0,"Barrage","Circle 5.2",""},{18,26,1.35,790,0,"Barrage","Circle 5.4",""},{20,27,1.32,1085,0,"Barrage","Circle 5.6",""},{24,28,1.3,1460,0,"Barrage","Circle 5.8",""},{28,30,1.27,1960,0,"Barrage","Circle 6",""},{33,31,1.25,2645,0,"Barrage","Circle 6.2",""},{38,32,1.22,3565,0,"Barrage","Circle 6.4",""},{44,33,1.2,0,0,"Cataclysm","FullAoe","Burn"}}}
D.Duwende={"Nature","Hybrid",4,350,0.05,2,{Pebble=1},false,{{"CashOnKill","Lucky Find",{Cash=10,Chance=0.2}}},{{6,16,1,180,0,"Pebble","Circle 2.5",""},{7,17,0.98,240,0,"Pebble","Circle 2.7",""},{9,18,0.96,330,0,"Pebble","Circle 2.9",""},{11,19,0.94,440,0,"Pebble","Circle 3.1",""},{14,20,0.92,600,0,"Pebble","Circle 3.3",""},{17,21,0.9,0,0,"Pebble","Circle 3.5",""}}}
D.Engkanto={"Light","Hybrid",3,780,0.15,2,{Arrow=1,Volley=3},false,{{"BonusVs","First Glance",{Condition="FirstHit",Mult=1.5}},{"StatusOnCrit","Allure",{Duration=0.5,Status="Stun"}}},{{13,20,1.5,310,0,"Arrow","Circle 3",""},{15,21,1.48,415,0,"Arrow","Circle 3.2",""},{17,22,1.46,545,0,"Arrow","Circle 3.4",""},{20,23,1.44,715,0,"Arrow","Circle 3.6",""},{24,24,1.41,950,0,"Arrow","Circle 3.9",""},{28,25,1.39,1250,0,"Arrow","Circle 4.1",""},{33,26,1.37,1650,0,"Arrow","Circle 4.3",""},{39,27,1.35,0,0,"Volley","Circle 4.5",""}}}
D.Handyong={"Fire","Ground",4,150,0.05,2,{},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"BonusVs","Monster Hunter",{Condition="Flying",Mult=1.3}}},{{9,18,2.4,120,0,"","Circle 3",""},{12,18.5,2.35,180},{15,19,2.3,260,0,"","Circle 3.25","Burn"},{20,19.5,2.25,360,0,"","Circle 3.5","Burn"},{26,20,2.2,0,0,"","Circle 3.75","Burn"}}}
D.Kapre={"Nature","Ground",3,520,0.05,2,{Smoke=1},false,{{"CrowdScaling","Looming",{Max=0.4,PerEnemy=0.05}}},{{24,12,2.2,250,0,"Smoke","Cone 70","Slow"},{28,13,2.15,335,0,"Smoke","Cone 75","Slow"},{33,14,2.1,460,0,"Smoke","Cone 80","Slow"},{39,15,2.05,615,0,"Smoke","Cone 85","Slow"},{45,16,2,830,0,"Smoke","Cone 90","Slow"},{54,17,1.95,1125,0,"Smoke","Cone 95","Slow"},{64,18,1.9,0,0,"Smoke","Cone 100","Slow"}}}
D.Lakapati={"Nature","Hybrid",6,520,0,0,{},false,{{"FarmIncome","Farm Income",{}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.1,Stat="Damage"}}},{{0,18,0,275,50,"","Single",""},{0,19,0,365,65},{0,20,0,485,90},{0,21,0,660,120},{0,22,0,900,165},{0,23,0,1215,220},{0,24,0,0,300}}}
D.Lalahon={"Fire","Hill",2,2400,0.05,2,{Eruption=1},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"CashOnKill","Harvest Fire",{Cash=15,Chance=0.25,RequireStatus="Burn"}}},{{37,20,2,775,0,"Eruption","FullAoe","Burn"},{43,21,1.98,985},{49,22,1.96,1255},{57,22,1.94,1600},{66,23,1.92,2010},{77,24,1.9,2560},{90,25,1.88,3270},{104,26,1.86,4135},{121,26,1.84,5255},{140,27,1.82,6675},{162,28,1.8,0}}}
D.Lalahon_Caldera={"Fire","Hill",2,2400,0.05,2,{Eruption=1},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"CashOnKill","Harvest Fire",{Cash=15,Chance=0.25,RequireStatus="Burn"}},{"StatusSpreadOnKill","Pyroclast",{Count=3,Duration=3,Radius=12,RequireCarrier=true,Status="Burn"}}},{{48,20,2,775,0,"Eruption","FullAoe","Burn"},{55,21,1.98,985},{64,22,1.96,1255},{74,22,1.94,1600},{86,23,1.92,2010},{101,24,1.9,2560},{117,25,1.88,3270},{135,26,1.86,4135},{157,26,1.84,5255},{182,27,1.82,6675},{211,28,1.8,0}}}
D.LamAng={"Neutral","Ground",2,1250,0.08,2,{Strike=1},{"Rooster's Crow","StatusBurst",30,{Duration=2,Scope="Range",Status="Stun"}},{{"BonusVs","Avenger",{Condition="Boss",Mult=1.5}},{"PerWaveRamp","Prodigy",{Max=0.3,PerWave=0.03}}},{{49,11,2.2,465,0,"Strike","Cone 80",""},{59,12,2.16,600,0,"Strike","Cone 83.8",""},{71,12,2.13,785,0,"Strike","Cone 87.5",""},{84,13,2.09,1035,0,"Strike","Cone 91.3",""},{100,14,2.05,1335,0,"Strike","Cone 95",""},{121,14,2.01,1735,0,"Strike","Cone 98.8",""},{145,15,1.98,2250,0,"Strike","Cone 102.5",""},{173,15,1.94,2935,0,"Strike","Cone 106.3",""},{207,16,1.9,0,0,"Strike","Cone 110",""}}}
D.Magwayen={"Dark","Ground",3,2000,0.05,2,{},false,{{"SummonOnKill","Summon On Kill",{HealthMode="EnemyHealthPct",HealthValue=0.6,MaxAlive=400,SummonId="Charger"}}},{{15,22,1.1,550,0,"","Circle 4",""},{17,23,1.08,725,0,"","Circle 4.1",""},{20,24,1.06,975,0,"","Circle 4.2",""},{23,25,1.03,1325,0,"","Circle 4.3",""},{27,26,1.01,1800,0,"","Circle 4.4",""},{32,26,0.99,2425,0,"","Circle 4.6",""},{36,27,0.97,3250,0,"","Circle 4.7",""},{42,28,0.94,4400,0,"","Circle 4.8",""},{49,29,0.92,5950,0,"","Circle 4.9",""},{57,30,0.9,0,0,"","Circle 5",""}}}
D.Magwayen_Soulferry={"Dark","Ground",3,2000,0.05,2,{},false,{{"SummonOnKill","Summon On Kill",{HealthMode="EnemyHealthPct",HealthValue=1,MaxAlive=400,SummonId="Charger"}}},{{20,22,1.1,550,0,"","Circle 4",""},{23,23,1.08,725,0,"","Circle 4.1",""},{26,24,1.06,975,0,"","Circle 4.2",""},{31,25,1.03,1325,0,"","Circle 4.3",""},{36,26,1.01,1800,0,"","Circle 4.4",""},{41,26,0.99,2425,0,"","Circle 4.6",""},{48,27,0.97,3250,0,"","Circle 4.7",""},{56,28,0.94,4400,0,"","Circle 4.8",""},{64,29,0.92,5950,0,"","Circle 4.9",""},{74,30,0.9,0,0,"","Circle 5",""}}}
D.Mambabarang={"Dark","Hill",3,780,0.04,2,{Hive=1,Plague=3},false,{{"StatusSpreadOnKill","Status Spread On Kill",{CountByTier={2,2,2,3,3,3,4,4},DamagePerTickByTier={2,2,3,3,4,5,6,8},Duration=4,Radius=12,Status="Swarm"}}},{{13,18,1.4,290,0,"Hive","Circle 4","Swarm"},{15,19,1.39,385,0,"Hive","Circle 4.3","Swarm"},{18,20,1.37,530,0,"Hive","Circle 4.6","Swarm"},{21,21,1.36,710,0,"Hive","Circle 4.9","Swarm"},{24,22,1.34,960,0,"Hive","Circle 5.1","Swarm"},{29,23,1.33,1295,0,"Hive","Circle 5.4","Swarm"},{33,24,1.31,1740,0,"Hive","Circle 5.7","Swarm"},{38,25,1.3,0,0,"Plague","Circle 6","Swarm"}}}
D.Mangkukulam={"Dark","Hybrid",3,350,0.03,2,{Hex=1},false,{},{{8,18,1.5,180,0,"Hex","Circle 4","Sumpa"},{10,19,1.48,240,0,"Hex","Circle 4.3","Sumpa"},{13,20,1.46,330,0,"Hex","Circle 4.6","Sumpa"},{17,21,1.44,440,0,"Hex","Circle 4.9","Sumpa"},{22,22,1.42,600,0,"Hex","Circle 5.2","Sumpa"},{29,23,1.4,0,0,"Hex","Circle 5.5","Sumpa"}}}
D.MariaMakiling={"Nature","Hybrid",2,1250,0.04,2,{Blessing=1},{"Mountain Mist","StatusBurst",40,{Duration=3,Scope="Map",Status="Slow"}},{{"FarmIncome","Golden Ginger",{}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.08,1.08,1.09,1.1},Stat="Damage"}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,MultByTier={1.04,1.04,1.05,1.05,1.06,1.06,1.07,1.07,1.08},Stat="Range"}}},{{21,18,1.6,500,60,"Blessing","Circle 3",""},{25,19,1.58,645,75,"Blessing","Circle 3.1",""},{29,20,1.55,840,95,"Blessing","Circle 3.3",""},{34,21,1.53,1105,115,"Blessing","Circle 3.4",""},{41,22,1.5,1430,145,"Blessing","Circle 3.5",""},{49,23,1.48,1855,185,"Blessing","Circle 3.6",""},{57,24,1.45,2410,230,"Blessing","Circle 3.8",""},{68,25,1.42,3145,290,"Blessing","Circle 3.9",""},{82,26,1.4,0,360,"Blessing","Circle 4",""}}}
D.Mayari={"Light","Hill",2,2000,0.2,2.25,{Crescent=2,Moonshot=1},{"Lunar Veil","StatusBurst",40,{Duration=4,Scope="Map",Status="Slow"}},{{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Apolaki"}}},{{22,30,2.2,710,0,"Moonshot","Circle 2.5",""},{25,31,2.18,910,0,"Moonshot","Circle 2.6",""},{29,33,2.16,1155,0,"Moonshot","Circle 2.7",""},{35,34,2.13,1490,0,"Moonshot","Circle 2.8",""},{41,35,2.11,1910,0,"Moonshot","Circle 2.9",""},{48,37,2.09,2445,0,"Moonshot","Circle 3.1",""},{56,38,2.07,3135,0,"Moonshot","Circle 3.2",""},{65,39,2.04,4000,0,"Moonshot","Circle 3.3",""},{76,41,2.02,5135,0,"Moonshot","Circle 3.4",""},{90,42,2,0,0,"Crescent","Circle 3.5",""}}}
D.Mayari_LunarEclipse={"Light","Hill",2,2000,0.2,2.25,{Crescent=2,Moonshot=1},{"Lunar Veil","StatusBurst",40,{Duration=4,Scope="Map",Status="Slow"}},{{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Apolaki"}},{"StatusOnCrit","Eclipse Light",{Duration=3,Status="Weaken"}}},{{28,30,2.2,710,0,"Moonshot","Circle 2.5",""},{33,31,2.18,910,0,"Moonshot","Circle 2.6",""},{38,33,2.16,1155,0,"Moonshot","Circle 2.7",""},{45,34,2.13,1490,0,"Moonshot","Circle 2.8",""},{53,35,2.11,1910,0,"Moonshot","Circle 2.9",""},{62,37,2.09,2445,0,"Moonshot","Circle 3.1",""},{72,38,2.07,3135,0,"Moonshot","Circle 3.2",""},{85,39,2.04,4000,0,"Moonshot","Circle 3.3",""},{99,41,2.02,5135,0,"Moonshot","Circle 3.4",""},{117,42,2,0,0,"Crescent","Circle 3.5",""}}}
D.Minokawa={"Cosmic","Hill",2,1250,0.06,2,{Beaks=4},{"Swallow the Moon","Nuke",45,{Mult=5,Scope="Map"}},{{"BonusVs","Moon Eater",{Condition="Boss",Mult=1.6}},{"BonusVs","Sky Hunter",{Condition="Flying",Mult=1.3}}},{{17,24,1.8,440,0,"Beaks","Circle 3",""},{20,25,1.78,565,0,"Beaks","Circle 3.1",""},{24,26,1.75,735,0,"Beaks","Circle 3.3",""},{28,27,1.73,970,0,"Beaks","Circle 3.4",""},{33,28,1.7,1250,0,"Beaks","Circle 3.5",""},{40,29,1.68,1625,0,"Beaks","Circle 3.6",""},{47,30,1.65,2110,0,"Beaks","Circle 3.8",""},{56,31,1.63,2750,0,"Beaks","Circle 3.9",""},{67,32,1.6,0,0,"Beaks","Circle 4",""}}}
D.NunoSaPunso={"Nature","Ground",2,520,0,0,{},false,{{"EnemyStatusAura","Enemy Status Aura",{Duration=1,Interval=0.5,PotencyByTier={1,1.1,1.2,1.3,1.4,1.5,1.7},Status="Weaken"}}},{{0,14,0,255,0,"","Single",""},{0,15,0,345},{0,16,0,460},{0,17,0,625},{0,18,0,845},{0,20,0,1145},{0,22,0,0}}}
D.Oryol={"Neutral","Hill",3,520,0.03,2,{Cast=1},false,{},{{14,18,2,285,0,"Cast","Circle 8","Slow"},{16,19,1.93,375,0,"Cast","Circle 9.2","Slow"},{18,20,1.87,520,0,"Cast","Circle 10.3","Slow"},{21,22,1.8,700,0,"Cast","Circle 11.5","Slow"},{24,23,1.73,935,0,"Cast","Circle 12.7","Slow/Weaken"},{28,24,1.67,1275,0,"Cast","Circle 13.8","Slow/Weaken"},{33,25,1.6,0,0,"Cast","Circle 15","Slow/Weaken"}}}
D.Santelmo={"Fire","Hill",3,350,0.04,2,{Wisps=2},false,{{"BonusVs","Wandering Flame",{Condition="Status",Mult=1.25,Status="Burn"}}},{{7,20,1.6,175,0,"Wisps","Circle 3","Burn"},{9,21,1.58,235,0,"Wisps","Circle 3.2","Burn"},{11,22,1.56,315,0,"Wisps","Circle 3.4","Burn"},{14,23,1.54,430,0,"Wisps","Circle 3.6","Burn"},{18,24,1.52,580,0,"Wisps","Circle 3.8","Burn"},{22,25,1.5,0,0,"Wisps","Circle 4","Burn"}}}
D.Sarimanok={"Light","Hill",2,520,0.05,2,{Peck=1},false,{{"AllyDamageAura","Good Fortune",{AddByTier={0.05,0.06,0.07,0.08,0.09,0.1,0.12},Interval=0.5,Stat="CritChance"}}},{{9,20,1.5,230,0,"Peck","Circle 2.5",""},{11,21,1.47,310,0,"Peck","Circle 2.7",""},{14,22,1.43,415,0,"Peck","Circle 2.8",""},{17,23,1.4,560,0,"Peck","Circle 3",""},{20,24,1.37,760,0,"Peck","Circle 3.2",""},{25,25,1.33,1030,0,"Peck","Circle 3.3",""},{30,26,1.3,0,0,"Peck","Circle 3.5",""}}}
D.Sidapa={"Dark","Hybrid",2,2000,0.06,2,{Reap=1,Toll=2},{"Death's Toll","StatusBurst",45,{Duration=5,Scope="Map",Status="Weaken"}},{{"Execute","Measured Life",{ThresholdByTier={0.1,0.1,0.11,0.12,0.13,0.14,0.15,0.16,0.17,0.18}}},{"KillStack","Harvest",{Max=0.3,PerKill=0.01}}},{{20,20,1.3,675,0,"Reap","Circle 4",""},{23,21,1.28,865,0,"Reap","Circle 4.1",""},{25,22,1.26,1095,0,"Reap","Circle 4.2",""},{28,23,1.23,1410,0,"Reap","Circle 4.3",""},{32,24,1.21,1810,0,"Reap","Circle 4.4",""},{36,24,1.19,2315,0,"Reap","Circle 4.6",""},{41,25,1.17,2970,0,"Reap","Circle 4.7",""},{46,26,1.14,3790,0,"Reap","Circle 4.8",""},{52,27,1.12,4865,0,"Reap","Circle 4.9",""},{58,28,1.1,0,0,"Toll","Circle 5",""}}}
D.Sidapa_LastMeasure={"Dark","Hybrid",2,2000,0.06,2,{Reap=1,Toll=2},{"Death's Toll","StatusBurst",45,{Duration=5,Scope="Map",Status="Weaken"}},{{"Execute","Measured Life",{ThresholdByTier={0.15,0.15,0.16,0.17,0.18,0.19,0.2,0.21,0.22,0.23}}},{"KillStack","Harvest",{Max=0.3,PerKill=0.01}}},{{26,20,1.3,675,0,"Reap","Circle 4",""},{29,21,1.28,865,0,"Reap","Circle 4.1",""},{33,22,1.26,1095,0,"Reap","Circle 4.2",""},{37,23,1.23,1410,0,"Reap","Circle 4.3",""},{41,24,1.21,1810,0,"Reap","Circle 4.4",""},{46,24,1.19,2315,0,"Reap","Circle 4.6",""},{52,25,1.17,2970,0,"Reap","Circle 4.7",""},{59,26,1.14,3790,0,"Reap","Circle 4.8",""},{67,27,1.12,4865,0,"Reap","Circle 4.9",""},{75,28,1.1,0,0,"Toll","Circle 5",""}}}
D.Sigbin={"Dark","Hybrid",3,780,0.05,2,{Devour=2,Shadow=1},false,{{"ConsecutiveHits","Shadow Feeding",{Max=0.3,PerHit=0.02}}},{{15,18,1.6,310,0,"Shadow","Circle 2.5",""},{18,19,1.57,415,0,"Shadow","Circle 2.6",""},{21,20,1.54,545,0,"Shadow","Circle 2.8",""},{24,21,1.51,715,0,"Shadow","Circle 2.9",""},{28,21,1.49,950,0,"Shadow","Circle 3.1",""},{33,22,1.46,1250,0,"Shadow","Circle 3.2",""},{39,23,1.43,1650,0,"Shadow","Circle 3.4",""},{45,24,1.4,0,0,"Devour","Circle 3.5",""}}}
D.Siyokoy={"Water","Ground",4,350,0.05,2,{Grasp=1},false,{{"BonusVs","Undertow",{Condition="Status",Mult=1.3,Status="Slow"}}},{{18,11,2,180,0,"Grasp","Box 4x11","Slow"},{22,12,1.96,240,0,"Grasp","Box 4.4x12","Slow"},{27,12,1.92,330,0,"Grasp","Box 4.8x12","Slow"},{34,13,1.88,440,0,"Grasp","Box 5.2x13","Slow"},{42,14,1.84,600,0,"Grasp","Box 5.6x14","Slow"},{53,15,1.8,0,0,"Grasp","Box 6x15","Slow"}}}
D.Tala={"Cosmic","Hill",2,2400,0.06,2,{Starfall=5},false,{{"AllyDamageAura","Guiding Star",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.07,1.08,1.08,1.09,1.09,1.1},Stat="Range"}},{"EveryNthAttack","Constellation",{Mult=2,N=3}}},{{19,26,1.4,815,0,"Starfall","Circle 3",""},{22,27,1.39,1030,0,"Starfall","Circle 3.1",""},{25,28,1.37,1320,0,"Starfall","Circle 3.2",""},{28,29,1.36,1680,0,"Starfall","Circle 3.3",""},{32,30,1.34,2110,0,"Starfall","Circle 3.4",""},{35,31,1.33,2690,0,"Starfall","Circle 3.5",""},{40,32,1.31,3430,0,"Starfall","Circle 3.6",""},{45,33,1.3,4345,0,"Starfall","Circle 3.7",""},{51,34,1.28,5520,0,"Starfall","Circle 3.8",""},{58,35,1.26,7010,0,"Starfall","Circle 3.9",""},{65,36,1.25,0,0,"Starfall","Circle 4",""}}}
D.Tala_MorningStar={"Cosmic","Hill",2,2400,0.06,2,{Starfall=5},false,{{"AllyDamageAura","Guiding Star",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.07,1.08,1.08,1.09,1.09,1.1},Stat="Range"}},{"EveryNthAttack","Constellation",{Mult=2,N=2}}},{{25,26,1.4,815,0,"Starfall","Circle 3",""},{28,27,1.39,1030,0,"Starfall","Circle 3.1",""},{32,28,1.37,1320,0,"Starfall","Circle 3.2",""},{36,29,1.36,1680,0,"Starfall","Circle 3.3",""},{41,30,1.34,2110,0,"Starfall","Circle 3.4",""},{46,31,1.33,2690,0,"Starfall","Circle 3.5",""},{52,32,1.31,3430,0,"Starfall","Circle 3.6",""},{59,33,1.3,4345,0,"Starfall","Circle 3.7",""},{67,34,1.28,5520,0,"Starfall","Circle 3.8",""},{75,35,1.26,7010,0,"Starfall","Circle 3.9",""},{85,36,1.25,0,0,"Starfall","Circle 4",""}}}
D.Tikbalang={"Neutral","Ground",3,520,0.06,2,{Kick=1},false,{{"Knockback","Lead Astray",{Chance=0.2,Duration=0.6,Status="Stun",Studs=6}}},{{22,11,1.9,250,0,"Kick","Circle 3",""},{27,12,1.87,335,0,"Kick","Circle 3.2",""},{31,12,1.83,460,0,"Kick","Circle 3.3",""},{37,13,1.8,615,0,"Kick","Circle 3.5",""},{45,14,1.77,830,0,"Kick","Circle 3.7",""},{53,14,1.73,1125,0,"Kick","Circle 3.8",""},{63,15,1.7,0,0,"Kick","Circle 4",""}}}
D.Tiyanak={"Dark","Ground",2,3200,0.06,2,{Bite=1},false,{{"EnterRangeStatus","Lost Child's Cry",{Duration=1,Status="Stun"}},{"ArmorPierce","Bite",{Fraction=1}}},{{71,13,2,1065,0,"Bite","Circle 3.5",""},{81,14,1.99,1340,0,"Bite","Circle 3.6",""},{92,14,1.97,1675,0,"Bite","Circle 3.8",""},{104,15,1.96,2070,0,"Bite","Circle 3.9",""},{118,15,1.95,2590,0,"Bite","Circle 4",""},{135,16,1.93,3260,0,"Bite","Circle 4.2",""},{153,16,1.92,4085,0,"Bite","Circle 4.3",""},{174,17,1.9,5090,0,"Bite","Circle 4.5",""},{199,17,1.89,6370,0,"Bite","Circle 4.6",""},{226,18,1.88,7955,0,"Bite","Circle 4.7",""},{257,18,1.86,9935,0,"Bite","Circle 4.9",""},{292,19,1.85,0,0,"Bite","Circle 5",""}}}
D.Tiyanak_Changeling={"Dark","Ground",2,3200,0.06,2,{Bite=1},false,{{"EnterRangeStatus","Lost Child's Cry",{Duration=1,Status="Stun"}},{"ArmorPierce","Bite",{Fraction=1}},{"BonusVs","Prey",{Condition="Status",Mult=1.4,Status="Stun"}}},{{92,13,2,1065,0,"Bite","Circle 3.5",""},{105,14,1.99,1340,0,"Bite","Circle 3.6",""},{119,14,1.97,1675,0,"Bite","Circle 3.8",""},{135,15,1.96,2070,0,"Bite","Circle 3.9",""},{153,15,1.95,2590,0,"Bite","Circle 4",""},{175,16,1.93,3260,0,"Bite","Circle 4.2",""},{200,16,1.92,4085,0,"Bite","Circle 4.3",""},{227,17,1.9,5090,0,"Bite","Circle 4.5",""},{258,17,1.89,6370,0,"Bite","Circle 4.6",""},{293,18,1.88,7955,0,"Bite","Circle 4.7",""},{335,18,1.86,9935,0,"Bite","Circle 4.9",""},{380,19,1.85,0,0,"Bite","Circle 5",""}}}
D.Urduja={"Neutral","Ground",2,1250,0.05,2,{},{"War Cry","TempStatBuff",25,{Duration=12,Mult=1.6,Stat="Damage"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.08,Stat="Damage"}}},{{13,18,1,445,0,"","Circle 3",""},{15,19,0.97,605,0,"","Circle 3.1",""},{17,19,0.95,820,0,"","Circle 3.2",""},{19,20,0.93,1105,0,"","Circle 3.4",""},{22,20,0.9,1480,0,"","Circle 3.5",""},{25,21,0.88,2020,0,"","Circle 3.6",""},{28,22,0.85,2715,0,"","Circle 3.8",""},{32,22,0.83,3660,0,"","Circle 3.9",""},{37,23,0.8,0,0,"","Circle 4",""}}}
I.Amomongo="rbxassetid://125610139973073"
I.Apolaki="rbxassetid://100485253004120"
I.Apolaki_Zenith="rbxassetid://100485253004120"
I.Baltog="rbxassetid://103516829310806"
I.Bantong="rbxassetid://125610139973073"
I.Kapre="rbxassetid://125610139973073"
I.LamAng="rbxassetid://125610139973073"
I.Siyokoy="rbxassetid://125610139973073"
I.Tikbalang="rbxassetid://125610139973073"
UnitInfoCatalog.Data = D

UnitInfoCatalog.ElementColors = {
	Fire = Color3.fromRGB(255, 120, 60),
	Water = Color3.fromRGB(70, 170, 255),
	Nature = Color3.fromRGB(110, 220, 90),
	Light = Color3.fromRGB(255, 225, 90),
	Dark = Color3.fromRGB(165, 95, 235),
	Holy = Color3.fromRGB(255, 245, 200),
	Cosmic = Color3.fromRGB(120, 110, 255),
	Neutral = Color3.fromRGB(190, 190, 200),
}

UnitInfoCatalog.StatLabels = { Damage = "DMG", SPA = "SPA", Range = "RNG" }

local cache: { [string]: any } = {}

local function pct(x: number): string
	local r = math.floor(x * 1000 + 0.5) / 10
	if r == math.floor(r) then return tostring(math.floor(r)) .. "%" end
	return string.format("%.1f%%", r)
end
local function n(x: number?): string
	if type(x) ~= "number" then return "?" end
	local r = math.floor(x * 100 + 0.5) / 100
	if r == math.floor(r) then return tostring(math.floor(r)) end
	return tostring(r)
end

-- Decoded entry, cached. nil for an unknown tower.
function UnitInfoCatalog.Get(towerId: string?): any?
	if type(towerId) ~= "string" then return nil end
	local hit = cache[towerId]
	if hit then return hit end
	local row = D[towerId]
	if row == nil then return nil end
	local ab = row[8]
	local e = {
		Id = towerId,
		Element = row[1], Placement = row[2], PlacementLimit = row[3], Cost = row[4],
		CritChance = row[5], CritMultiplier = row[6], Hits = row[7],
		Ability = if ab then { Name = ab[1], Id = ab[2], Cooldown = ab[3], Params = ab[4] } else nil,
		Passives = {},
		Tiers = {},
	}
	for _, p in ipairs(row[9]) do
		table.insert(e.Passives, { Id = p[1], Name = p[2], Params = p[3] })
	end
	local attack, shape, effects = "", "Single", ""
	for i, t in ipairs(row[10]) do
		if t[6] ~= nil then attack, shape, effects = t[6], t[7], t[8] end
		local prevCost = if i == 1 then row[4] else row[10][i - 1][4]
		table.insert(e.Tiers, {
			Index = i, Damage = t[1], Range = t[2], SPA = t[3],
			Cost = prevCost, UpgradeCost = t[4], Income = t[5] or 0,
			Attack = attack, Shape = shape, Effects = effects,
			HitCount = (row[7] and row[7][attack]) or 1,
		})
	end
	cache[towerId] = e
	return e
end

-- B161: the unit's idle animation id (from its config's Idle.Anim), or nil when the config sets none.
function UnitInfoCatalog.IdleAnim(towerId: string?): string?
	return if type(towerId) == "string" then I[towerId] else nil
end

function UnitInfoCatalog.TierCount(towerId: string?): number
	local e = UnitInfoCatalog.Get(towerId)
	return if e then #e.Tiers else 0
end

-- "Box 6x22" -> "a Box (6 x 22)"; the shape words players read.
local function shapeWords(shape: string): string
	local w, l = string.match(shape, "^Box ([%d%.]+)x([%d%.]+)$")
	if w then return string.format("a Line (%s x %s)", w, l) end
	local r = string.match(shape, "^Circle ([%d%.]+)$")
	if r then return string.format("a Circle AoE (Size %s)", r) end
	local a = string.match(shape, "^Cone ([%d%.]+)$")
	if a then return string.format("a Cone (%s deg)", a) end
	if shape == "FullAoe" then return "every enemy in range" end
	return "a single target"
end

-- One line for an upgrade-path tooltip / the Attack row.
function UnitInfoCatalog.DescribeAttack(tier: any): string
	if tier == nil then return "" end
	if (tier.Income or 0) > 0 and (tier.Damage or 0) <= 0 then
		return string.format("Earns %s cash every wave.", n(tier.Income))
	end
	local hits = tier.HitCount or 1
	local s = string.format("Deals %s%s to %s every %ss.",
		if hits > 1 then tostring(hits) .. " hits" else "1 hit",
		"", shapeWords(tier.Shape or "Single"), n(tier.SPA))
	if tier.Effects and tier.Effects ~= "" then
		s ..= " Applies " .. string.gsub(tier.Effects, "/", ", ") .. "."
	end
	if (tier.Income or 0) > 0 then
		s ..= string.format(" Earns %s cash per wave.", n(tier.Income))
	end
	return s
end

local function scope(sc: string?): string
	return if sc == "Map" then "on the whole map" else "in range"
end
local function byTier(p: any, key: string, plain: string): any
	local list = p[key .. "ByTier"]
	if type(list) == "table" and #list > 0 then return list[1], list[#list] end
	return p[plain], nil
end

-- A plain-language sentence for a passive ({ Id, Name, Params }).
function UnitInfoCatalog.DescribePassive(ps: any): string
	local id, p = ps.Id, ps.Params or {}
	if id == "FarmIncome" then return "Earns cash at the end of every wave."
	elseif id == "AllyDamageAura" then
		local where = if (p.Range or 0) >= 9999 then "All allies" else "Allies in range"
		local add, addHi = byTier(p, "Add", "Add")
		if add then
			return string.format("%s get +%s %s%s.", where, pct(add), if p.Stat == "CritChance" then "crit chance" else string.lower(tostring(p.Stat)), if addHi and addHi ~= add then " (up to +" .. pct(addHi) .. ")" else "")
		end
		local lo, hi = byTier(p, "Mult", "Mult")
		lo = lo or 1
		if p.Stat == "SPA" and lo < 1 then
			return string.format("%s attack %s faster.", where, pct(1 - lo))
		end
		return string.format("%s get +%s %s%s.", where, pct(lo - 1), string.lower(p.Stat or "damage"), if hi and hi ~= lo then " (up to +" .. pct(hi - 1) .. ")" else "")
	elseif id == "BonusVs" then
		if p.Condition == "FirstHit" then
			return string.format("+%s damage on the first hit against each enemy.", pct((p.Mult or 1) - 1))
		end
		local who = if p.Condition == "Flying" then "flying enemies"
			elseif p.Condition == "Boss" then "bosses"
			elseif p.Condition == "Element" then tostring(p.Element) .. " enemies"
			elseif p.Condition == "Status" then "enemies with " .. tostring(p.Status)
			else "marked enemies"
		return string.format("+%s damage vs %s.", pct((p.Mult or 1) - 1), who)
	elseif id == "CashOnKill" then
		return string.format("%s chance to earn %s cash per kill%s.", pct(p.Chance or 0), n(p.Cash),
			if p.RequireStatus then " on enemies with " .. tostring(p.RequireStatus) else "")
	elseif id == "CrowdScaling" then return string.format("+%s damage per enemy in range (max +%s).", pct(p.PerEnemy or 0), pct(p.Max or 0))
	elseif id == "EnemyStatusAura" then
		return string.format("Applies %s to enemies %s every %ss.", tostring(p.Status), if (p.Range or 0) >= 9999 then "on the whole map" else "in range", n(p.Interval))
	elseif id == "KillFrenzy" then
		local what = if p.Stat == "SPA" then string.format("attacks %s faster", pct(1 - (p.Mult or 1))) else string.format("+%s %s", pct((p.Mult or 1) - 1), string.lower(tostring(p.Stat)))
		return string.format("Every %s kills: %s for %ss.", n(p.Kills), what, n(p.Duration))
	elseif id == "StatusSpreadOnKill" then
		local c = byTier(p, "Count", "Count")
		return string.format("Kills spread %s to up to %s nearby enemies.", tostring(p.Status), n(c))
	elseif id == "ConsecutiveHits" then return string.format("+%s damage per hit on the same target (max +%s).", pct(p.PerHit or 0), pct(p.Max or 0))
	elseif id == "EveryNthAttack" then
		local what = if p.MapStrike then string.format("hits EVERY enemy on the map for %s damage", pct(p.MapStrike))
			elseif p.Status then string.format("applies %s for %ss", tostring(p.Status), n(p.Duration))
			else string.format("deals x%s damage", n(p.Mult))
		return string.format("Every %s attack %s.", n(p.N) .. (if p.N == 2 then "nd" elseif p.N == 3 then "rd" else "th"), what)
	elseif id == "StatusOnCrit" then return string.format("Critical hits apply %s for %ss.", tostring(p.Status), n(p.Duration))
	elseif id == "PerWaveRamp" then return string.format("+%s damage every wave (max +%s).", pct(p.PerWave or 0), pct(p.Max or 0))
	elseif id == "SiblingBonus" then return string.format("+%s damage while %s is placed.", pct((p.Mult or 1) - 1), tostring(p.Partner))
	elseif id == "Execute" then
		local lo, hi = byTier(p, "Threshold", "Threshold")
		return string.format("Instantly defeats non-boss enemies below %s HP%s.", pct(lo or 0), if hi then " (up to " .. pct(hi) .. ")" else "")
	elseif id == "KillStack" then return string.format("+%s damage per kill (max +%s).", pct(p.PerKill or 0), pct(p.Max or 0))
	elseif id == "Knockback" then
		local lo = byTier(p, "Studs", "Studs")
		return string.format("%s chance to knock enemies back %s studs%s.", pct(p.Chance or 1), n(lo), if p.Status then " and " .. tostring(p.Status) .. " them" else "")
	elseif id == "FormCycle" then
		local names = {}
		for _, f in ipairs(p.Forms or {}) do table.insert(names, tostring(f.Name)) end
		return "Changes form every wave: " .. table.concat(names, " > ") .. "."
	elseif id == "EnterRangeStatus" then return string.format("Enemies entering range get %s for %ss.", tostring(p.Status), n(p.Duration))
	elseif id == "ArmorPierce" then return string.format("Ignores %s of enemy armor.", pct(p.Fraction or 0))
	elseif id == "SleepAura" then return string.format("Every %ss, puts enemies in range to sleep for %ss.", n(p.Interval), n(p.Duration))
	elseif id == "SummonOnKill" then return string.format("Defeated enemies rise as a %s ally.", tostring(p.SummonId))
	end
	return tostring(ps.Name or id)
end

function UnitInfoCatalog.DescribeAbility(a: any): string
	if a == nil then return "" end
	local p = a.Params or {}
	local body
	if a.Id == "Nuke" then body = string.format("Deals x%s damage to every enemy %s.", n(p.Mult), scope(p.Scope))
	elseif a.Id == "StatusBurst" then body = string.format("Applies %s to every enemy %s for %ss.", tostring(p.Status), scope(p.Scope), n(p.Duration))
	elseif a.Id == "TempStatBuff" then
		body = if p.Stat == "SPA" then string.format("Attacks %s faster for %ss.", pct(1 - (p.Mult or 1)), n(p.Duration))
			else string.format("+%s %s for %ss.", pct((p.Mult or 1) - 1), string.lower(tostring(p.Stat)), n(p.Duration))
	else body = tostring(a.Name) end
	return body .. string.format(" Cooldown %ss.", n(a.Cooldown))
end

return UnitInfoCatalog
