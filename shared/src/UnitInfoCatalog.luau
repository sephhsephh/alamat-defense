--!strict
-- UnitInfoCatalog (SHARED CANON, both Places) -- B108 pt14.
-- Per-tower PRESENTATION data for the Lobby Units screen: element, placement, the in-match upgrade
-- path (per-tier DMG / RNG / SPA / cost / attack), the unit's passives and its active ability.
-- GENERATED from the Game's RS.Configs.Towers.* by a Studio tool pass (see docs/systems/units-screen.md);
-- the Game's tower configs stay the source of truth -- regenerate this file after retuning a tower.
-- The Lobby has no tower configs, which is why this exists (same reason UnitStatsCatalog does).
--
-- Data row: D.<TowerId> = { Element, Placement, PlacementLimit, Cost, CritChance, CritMultiplier,
--   { [attackName] = hitsPerAttack }, Ability|false = { Name, Id, Cooldown, Params },
--   Passives = { { Id, Name, Params } }, Tiers = { { DMG, RNG, SPA, UpgradeCost [, Income, Attack, Shape, Effects] } } }
-- A tier row carries Attack/Shape/Effects only when they CHANGE (the accessor carries them forward).
-- `UpgradeCost` on tier i is the price of tier i+1 (0 on the last tier); tier 1 costs the placement Cost.

local UnitInfoCatalog = {}
local D: { [string]: any } = {}
D.AmanSinaya={"Water","Ground",2,475,0.05,2,{Tsunami=2,Wave=1},{"Great Wave","Nuke",40,{Mult=6,Scope="Range"}},{{"Knockback","Tide",{Chance=1,StudsByTier={2,2,2.5,2.5,3,3,3.5,3.5,4,4}}}},{{70,14,2,160,0,"Wave","Box 6x14","Slow"},{79,15,1.98,205},{89,15,1.96,260},{101,16,1.93,335},{114,17,1.91,430},{129,17,1.89,550},{146,18,1.87,705},{165,19,1.84,900},{186,19,1.82,1155},{210,20,1.8,0,0,"Tsunami","Box 9x20","Slow"}}}
D.AmanSinaya_Riptide={"Water","Ground",2,475,0.05,2,{Tsunami=2,Wave=1},{"Great Wave","Nuke",40,{Mult=6,Scope="Map"}},{{"Knockback","Tide",{Chance=1,StudsByTier={2,2,2.5,2.5,3,3,3.5,3.5,4,4}}}},{{91,14,2,160,0,"Wave","Box 6x14","Slow"},{103,15,1.98,205},{116,15,1.96,260},{131,16,1.93,335},{148,17,1.91,430},{168,17,1.89,550},{190,18,1.87,705},{215,19,1.84,900},{242,19,1.82,1155},{273,20,1.8,0,0,"Tsunami","Box 9x20","Slow"}}}
D.Amomongo={"Nature","Ground",3,300,0.07,2,{Claw=1,Rend=2},false,{{"KillFrenzy","Frenzy",{Duration=6,Kills=10,Mult=0.7,Stat="SPA"}}},{{40,9,2.6,130,0,"Claw","Box 4x5",""},{48,10,2.54,175},{58,10,2.49,235},{70,11,2.43,320},{85,12,2.37,430},{103,12,2.31,585},{124,13,2.26,785},{150,14,2.2,0,0,"Rend","Box 6x7",""}}}
D.Apolaki={"Fire","Hill",2,450,0.06,2,{SolarFlare=1,Sunbeam=1},{"High Noon","TempStatBuff",40,{Duration=10,Mult=0.6,Stat="SPA"}},{{"PerWaveRamp","Rising Sun",{Max=0.48,PerWave=0.06}},{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Mayari"}}},{{45,24,1.4,160,0,"Sunbeam","Box 4x24",""},{50,25,1.38,205},{57,26,1.36,260},{63,27,1.33,335},{71,28,1.31,430},{80,28,1.29,550},{89,29,1.27,705},{100,30,1.24,900},{112,31,1.22,1155},{126,32,1.2,0,0,"SolarFlare","FullAoe","Burn"}}}
D.Apolaki_Zenith={"Fire","Hill",2,450,0.06,2,{SolarFlare=1,Sunbeam=1},{"High Noon","TempStatBuff",40,{Duration=10,Mult=0.6,Stat="SPA"}},{{"PerWaveRamp","Rising Sun",{Max=0.8,PerWave=0.08}},{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Mayari"}}},{{59,24,1.4,160,0,"Sunbeam","Box 4x24",""},{65,25,1.38,205},{74,26,1.36,260},{82,27,1.33,335},{92,28,1.31,430},{104,28,1.29,550},{116,29,1.27,705},{130,30,1.24,900},{146,31,1.22,1155},{164,32,1.2,0,0,"SolarFlare","FullAoe","Burn"}}}
D.Aswang={"Dark","Ground",1,550,0.06,2,{Bird=3,Dog=1,Human=1},false,{{"FormCycle","Form Cycle",{Forms={{Attack="Dog",CanHitFlying=false,Name="Dog"},{Attack="Bird",CanHitFlying=true,Name="Bird"},{Attack="Human",CanHitFlying=false,Name="Human"}}}},{"KillStack","Feeding",{Max=0.4,PerKill=0.02}}},{{60,14,1.9,180,0,"Human","Circle 4",""},{69,15,1.88,225},{78,15,1.86,280},{90,16,1.85,350},{102,16,1.83,440},{117,17,1.81,550},{134,17,1.79,685},{153,18,1.77,860},{174,18,1.75,1075},{199,19,1.74,1340},{228,19,1.72,1675},{260,20,1.7,0}}}
D.Aswang_BloodMoon={"Dark","Ground",1,550,0.06,2,{Bird=3,Dog=1,Human=1},false,{{"FormCycle","Form Cycle",{Forms={{Attack="Dog",CanHitFlying=false,Name="Dog"},{Attack="Bird",CanHitFlying=true,Name="Bird"},{Attack="Human",CanHitFlying=false,Name="Human"}}}},{"KillStack","Feeding",{Max=0.8,PerKill=0.02}}},{{78,14,1.9,180,0,"Human","Circle 4",""},{90,15,1.88,225},{101,15,1.86,280},{117,16,1.85,350},{133,16,1.83,440},{152,17,1.81,550},{174,17,1.79,685},{199,18,1.77,860},{226,18,1.75,1075},{259,19,1.74,1340},{296,19,1.72,1675},{338,20,1.7,0}}}
D.Babaylan={"Neutral","Hybrid",2,300,0.04,2,{Pulse=5},false,{},{{20,22,2.5,100,0,"Pulse","FullAoe",""},{26,23,2.44,140},{33,24,2.39,185},{42,25,2.33,250},{55,27,2.27,340,0,"Pulse","FullAoe","Slow"},{70,28,2.21,460},{90,29,2.16,620},{116,30,2.1,0}}}
D.Bakunawa={"Cosmic","Hybrid",1,750,0.06,2,{Lunge=1},{"Devour","Nuke",60,{Mult=8,Scope="Map"}},{{"EveryNthAttack","Moon Hunger",{MapStrike=3,N=7}},{"BonusVs","Serpent of the Deep",{Condition="Element",Element="Water",Mult=1.25}}},{{110,22,2.2,200,0,"Lunge","Box 6x22",""},{122,23,2.18,250},{135,24,2.17,315},{150,25,2.15,390},{166,25,2.13,490},{184,26,2.12,610},{204,27,2.1,765},{227,28,2.08,955},{251,29,2.07,1190},{279,30,2.05,1490},{309,30,2.03,1865},{343,31,2.02,2330},{380,32,2,0}}}
D.Bakunawa_Eclipse={"Cosmic","Hybrid",1,750,0.06,2,{Lunge=1},{"Devour","Nuke",60,{Mult=8,Scope="Map"}},{{"EveryNthAttack","Moon Hunger",{MapStrike=3,N=5}},{"BonusVs","Serpent of the Deep",{Condition="Element",Element="Water",Mult=1.25}}},{{143,22,2.2,200,0,"Lunge","Box 6x22",""},{159,23,2.18,250},{176,24,2.17,315},{195,25,2.15,390},{216,25,2.13,490},{239,26,2.12,610},{265,27,2.1,765},{295,28,2.08,955},{326,29,2.07,1190},{363,30,2.05,1490},{402,30,2.03,1865},{446,31,2.02,2330},{494,32,2,0}}}
D.Baltog={"Neutral","Ground",4,125,0.06,2,{Grapple=1},false,{{"BonusVs","Bare Hands",{Condition="Boss",Mult=1.4}}},{{30,9,4.5,85,0,"Grapple","Box 4x5",""},{41,10,4.38,115},{55,11,4.25,155},{74,12,4.12,210},{100,13,4,0}}}
D.Bantong={"Neutral","Ground",4,150,0.07,2,{Slash=1},false,{{"BonusVs","Bonus Vs",{Condition="FirstHit",Mult=1.6}}},{{35,10,5.4,115,0,"Slash","Circle 3",""},{45,11,5.08,155},{59,12,4.75,210},{76,14,4.42,280},{98,15,4.1,0,0,"Slash","Cone 120","Stun"}}}
D.Bathala={"Holy","Hybrid",1,700,0.06,2,{Pulse=5},{"Word of Bathala","Nuke",60,{Mult=10,Scope="Map"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.15,Range=9999,Stat="Damage"}},{"EnemyStatusAura","Divine Judgement",{Duration=2,Interval=1,Range=9999,Status="Judged"}}},{{70,26,2,200,0,"Pulse","FullAoe",""},{79,27,1.98,250},{89,28,1.97,315},{100,29,1.95,390},{112,30,1.93,490},{126,31,1.92,610},{142,32,1.9,765},{160,33,1.88,955},{180,34,1.87,1190},{202,35,1.85,1490},{228,36,1.83,1865},{256,37,1.82,2330},{288,38,1.8,0}}}
D.Bathala_Ascended={"Holy","Hybrid",1,700,0.06,2,{Pulse=5},{"Word of Bathala","Nuke",60,{Mult=10,Scope="Map"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.15,Range=9999,Stat="Damage"}},{"AllyDamageAura","Ascended Will",{Interval=0.5,Mult=0.9,Range=9999,Stat="SPA"}},{"EnemyStatusAura","Divine Judgement",{Duration=2,Interval=1,Range=9999,Status="Judged"}}},{{91,26,2,200,0,"Pulse","FullAoe",""},{103,27,1.98,250},{116,28,1.97,315},{130,29,1.95,390},{146,30,1.93,490},{164,31,1.92,610},{185,32,1.9,765},{208,33,1.88,955},{234,34,1.87,1190},{263,35,1.85,1490},{296,36,1.83,1865},{333,37,1.82,2330},{374,38,1.8,0}}}
D.Batibat={"Dark","Ground",1,575,0.05,2,{Crush=1},false,{{"EnemyStatusAura","Nightmare Weight",{Duration=1,Interval=0.5,Potency=0.8,Status="Slow"}},{"SleepAura","Bangungot",{Duration=3,Interval=3}}},{{55,16,1.8,180,0,"Crush","Circle 4",""},{63,17,1.79,225},{72,17,1.77,280},{82,18,1.76,350},{94,18,1.75,440},{107,19,1.73,550},{123,19,1.72,685},{140,20,1.7,860},{161,20,1.69,1075},{184,21,1.68,1340},{210,21,1.66,1675},{240,22,1.65,0}}}
D.Batibat_NightTerror={"Dark","Ground",1,575,0.05,2,{Crush=1},false,{{"EnemyStatusAura","Nightmare Weight",{Duration=1,Interval=0.5,Potency=0.8,Status="Slow"}},{"SleepAura","Bangungot",{Duration=3,Interval=3}},{"BonusVs","Rude Awakening",{Condition="Status",Mult=2,Status="Sleep"}}},{{72,16,1.8,180,0,"Crush","Circle 4",""},{82,17,1.79,225},{94,17,1.77,280},{107,18,1.76,350},{122,18,1.75,440},{139,19,1.73,550},{160,19,1.72,685},{182,20,1.7,860},{209,20,1.69,1075},{239,21,1.68,1340},{273,21,1.66,1675},{312,22,1.65,0}}}
D.BernardoCarpio={"Neutral","Ground",2,400,0.05,2,{Slam=1},{"Lindol","Nuke",30,{Mult=4,Scope="Range"}},{{"EveryNthAttack","Held Mountains",{Duration=1,N=5,Status="Stun"}}},{{60,12,3.2,140,0,"Slam","FullAoe",""},{70,13,3.14,180},{83,13,3.08,235},{97,14,3.01,310},{114,15,2.95,400},{134,15,2.89,520},{157,16,2.83,675},{184,16,2.76,880},{216,17,2.7,0}}}
D.Bulalakaw={"Fire","Hill",3,300,0.05,2,{Barrage=3,Cataclysm=1},{"Meteor Strike","Nuke",15,{Mult=6,Scope="Map"}},{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}}},{{30,24,1.4,105,0,"Barrage","Circle 5",""},{35,25,1.38,140},{41,26,1.35,190},{47,27,1.32,260},{55,28,1.3,350},{64,30,1.27,470},{75,31,1.25,635},{88,32,1.22,855},{102,33,1.2,0,0,"Cataclysm","FullAoe","Burn"}}}
D.Duwende={"Nature","Hybrid",4,175,0.05,2,{Pebble=1},false,{{"CashOnKill","Lucky Find",{Cash=10,Chance=0.2}}},{{8,16,1,90,0,"Pebble","Circle 2.5",""},{10,17,0.98,120},{12,18,0.96,165},{15,19,0.94,220},{19,20,0.92,300},{24,21,0.9,0}}}
D.Engkanto={"Light","Hybrid",3,300,0.15,2,{Arrow=1,Volley=3},false,{{"BonusVs","First Glance",{Condition="FirstHit",Mult=1.5}},{"StatusOnCrit","Allure",{Duration=0.5,Status="Stun"}}},{{26,20,1.5,120,0,"Arrow","Circle 3",""},{31,21,1.48,160},{36,22,1.46,210},{42,23,1.44,275},{49,24,1.41,365},{58,25,1.39,480},{68,26,1.37,635},{80,27,1.35,0,0,"Volley","Circle 4.5",""}}}
D.Handyong={"Fire","Hybrid",4,100,0.05,2,{},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"BonusVs","Monster Hunter",{Condition="Flying",Mult=1.3}}},{{15,20,6,70,0,"","Circle 3",""},{20,22,5,90},{27,24,4,125,0,"","Circle 4.2","Burn"},{36,25,3,165},{48,27,2,0}}}
D.Kapre={"Nature","Ground",3,250,0.05,2,{Smoke=1},false,{{"CrowdScaling","Looming",{Max=0.4,PerEnemy=0.05}}},{{28,12,2.2,120,0,"Smoke","Cone 70","Slow"},{33,13,2.15,160},{39,14,2.1,220},{46,15,2.05,295},{54,16,2,400},{64,17,1.95,540},{76,18,1.9,0}}}
D.Lakapati={"Nature","Hybrid",6,150,0,0,{},false,{{"FarmIncome","Farm Income",{}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.1,Stat="Damage"}}},{{0,18,0,80,50,"","Single",""},{0,19,0,105,65},{0,20,0,140,90},{0,21,0,190,120},{0,22,0,260,165},{0,23,0,350,220},{0,24,0,0,300}}}
D.Lalahon={"Fire","Hill",2,525,0.05,2,{Eruption=1},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"CashOnKill","Harvest Fire",{Cash=15,Chance=0.25,RequireStatus="Burn"}}},{{50,20,2,170,0,"Eruption","FullAoe","Burn"},{58,21,1.98,215},{67,22,1.96,275},{78,22,1.94,350},{90,23,1.92,440},{105,24,1.9,560},{122,25,1.88,715},{141,26,1.86,905},{164,26,1.84,1150},{190,27,1.82,1460},{220,28,1.8,0}}}
D.Lalahon_Caldera={"Fire","Hill",2,525,0.05,2,{Eruption=1},false,{{"BonusVs","Bonus Vs",{Condition="Status",Mult=1.5,Status="Burn"}},{"CashOnKill","Harvest Fire",{Cash=15,Chance=0.25,RequireStatus="Burn"}},{"StatusSpreadOnKill","Pyroclast",{Count=3,Duration=3,Radius=12,RequireCarrier=true,Status="Burn"}}},{{65,20,2,170,0,"Eruption","FullAoe","Burn"},{75,21,1.98,215},{87,22,1.96,275},{101,22,1.94,350},{117,23,1.92,440},{137,24,1.9,560},{159,25,1.88,715},{183,26,1.86,905},{213,26,1.84,1150},{247,27,1.82,1460},{286,28,1.8,0}}}
D.LamAng={"Neutral","Ground",2,375,0.08,2,{Strike=1},{"Rooster's Crow","StatusBurst",30,{Duration=2,Scope="Range",Status="Stun"}},{{"BonusVs","Avenger",{Condition="Boss",Mult=1.5}},{"PerWaveRamp","Prodigy",{Max=0.3,PerWave=0.03}}},{{45,11,2.2,140,0,"Strike","Cone 80",""},{54,12,2.16,180},{65,12,2.13,235},{77,13,2.09,310},{92,14,2.05,400},{111,14,2.01,520},{133,15,1.98,675},{159,15,1.94,880},{190,16,1.9,0}}}
D.Magwayen={"Dark","Ground",3,400,0.05,2,{},false,{{"SummonOnKill","Summon On Kill",{HealthMode="EnemyHealthPct",HealthValue=0.6,MaxAlive=400,SummonId="Charger"}}},{{28,22,1.1,110,0,"","Circle 4",""},{32,23,1.08,145},{37,24,1.06,195},{43,25,1.03,265},{50,26,1.01,360},{58,26,0.99,485},{67,27,0.97,650},{78,28,0.94,880},{90,29,0.92,1190},{104,30,0.9,0}}}
D.Magwayen_Soulferry={"Dark","Ground",3,400,0.05,2,{},false,{{"SummonOnKill","Summon On Kill",{HealthMode="EnemyHealthPct",HealthValue=1,MaxAlive=400,SummonId="Charger"}}},{{36,22,1.1,110,0,"","Circle 4",""},{42,23,1.08,145},{48,24,1.06,195},{56,25,1.03,265},{65,26,1.01,360},{75,26,0.99,485},{87,27,0.97,650},{101,28,0.94,880},{117,29,0.92,1190},{135,30,0.9,0}}}
D.Mambabarang={"Dark","Hill",3,325,0.04,2,{Hive=1,Plague=3},false,{{"StatusSpreadOnKill","Status Spread On Kill",{CountByTier={2,2,2,3,3,3,4,4},DamagePerTickByTier={2,2,3,3,4,5,6,8},Duration=4,Radius=12,Status="Swarm"}}},{{24,18,1.4,120,0,"Hive","Circle 4","Swarm"},{28,19,1.39,160},{33,20,1.37,220},{38,21,1.36,295},{44,22,1.34,400},{52,23,1.33,540},{60,24,1.31,725},{70,25,1.3,0,0,"Plague","Circle 6","Swarm"}}}
D.Mangkukulam={"Dark","Hybrid",3,175,0.03,2,{Hex=1},false,{},{{10,18,1.5,90,0,"Hex","Circle 4","Sumpa"},{13,19,1.48,120},{17,20,1.46,165},{22,21,1.44,220},{29,22,1.42,300},{38,23,1.4,0}}}
D.MariaMakiling={"Nature","Hybrid",2,350,0.04,2,{Blessing=1},{"Mountain Mist","StatusBurst",40,{Duration=3,Scope="Map",Status="Slow"}},{{"FarmIncome","Golden Ginger",{}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.08,1.08,1.09,1.1},Stat="Damage"}},{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,MultByTier={1.04,1.04,1.05,1.05,1.06,1.06,1.07,1.07,1.08},Stat="Range"}}},{{15,18,1.6,140,60,"Blessing","Circle 3",""},{18,19,1.58,180,75},{21,20,1.55,235,95},{25,21,1.53,310,115},{30,22,1.5,400,145},{36,23,1.48,520,185},{42,24,1.45,675,230},{50,25,1.42,880,290},{60,26,1.4,0,360}}}
D.Mayari={"Light","Hill",2,450,0.2,2.25,{Crescent=2,Moonshot=1},{"Lunar Veil","StatusBurst",40,{Duration=4,Scope="Map",Status="Slow"}},{{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Apolaki"}}},{{60,30,2.2,160,0,"Moonshot","Circle 2.5",""},{70,31,2.18,205},{82,33,2.16,260},{97,34,2.13,335},{113,35,2.11,430},{133,37,2.09,550},{155,38,2.07,705},{182,39,2.04,900},{213,41,2.02,1155},{250,42,2,0,0,"Crescent","Circle 3.5",""}}}
D.Mayari_LunarEclipse={"Light","Hill",2,450,0.2,2.25,{Crescent=2,Moonshot=1},{"Lunar Veil","StatusBurst",40,{Duration=4,Scope="Map",Status="Slow"}},{{"SiblingBonus","Sibling Rivalry",{Mult=1.15,Partner="Apolaki"}},{"StatusOnCrit","Eclipse Light",{Duration=3,Status="Weaken"}}},{{78,30,2.2,160,0,"Moonshot","Circle 2.5",""},{91,31,2.18,205},{107,33,2.16,260},{126,34,2.13,335},{147,35,2.11,430},{173,37,2.09,550},{202,38,2.07,705},{237,39,2.04,900},{277,41,2.02,1155},{325,42,2,0,0,"Crescent","Circle 3.5",""}}}
D.Minokawa={"Cosmic","Hill",2,400,0.06,2,{Beaks=4},{"Swallow the Moon","Nuke",45,{Mult=5,Scope="Map"}},{{"BonusVs","Moon Eater",{Condition="Boss",Mult=1.6}},{"BonusVs","Sky Hunter",{Condition="Flying",Mult=1.3}}},{{36,24,1.8,140,0,"Beaks","Circle 3",""},{43,25,1.78,180},{51,26,1.75,235},{61,27,1.73,310},{72,28,1.7,400},{86,29,1.68,520},{102,30,1.65,675},{121,31,1.63,880},{144,32,1.6,0}}}
D.NunoSaPunso={"Nature","Ground",2,225,0,0,{},false,{{"EnemyStatusAura","Enemy Status Aura",{Duration=1,Interval=0.5,PotencyByTier={1,1.1,1.2,1.3,1.4,1.5,1.7},Status="Weaken"}}},{{0,14,0,110,0,"","Single",""},{0,15,0,150},{0,16,0,200},{0,17,0,270},{0,18,0,365},{0,20,0,495},{0,22,0,0}}}
D.Oryol={"Neutral","Hill",3,200,0.03,2,{Cast=1},false,{},{{30,18,2,110,0,"Cast","Circle 8","Slow"},{35,19,1.93,145},{40,20,1.87,200},{46,22,1.8,270},{54,23,1.73,360,0,"Cast","Circle 12.7","Slow/Weaken"},{62,24,1.67,490},{72,25,1.6,0}}}
D.Santelmo={"Fire","Hill",3,200,0.04,2,{Wisps=2},false,{{"BonusVs","Wandering Flame",{Condition="Status",Mult=1.25,Status="Burn"}}},{{16,20,1.6,100,0,"Wisps","Circle 3","Burn"},{20,21,1.58,135},{25,22,1.56,180},{31,23,1.54,245},{39,24,1.52,330},{48,25,1.5,0}}}
D.Sarimanok={"Light","Hill",2,250,0.05,2,{Peck=1},false,{{"AllyDamageAura","Good Fortune",{AddByTier={0.05,0.06,0.07,0.08,0.09,0.1,0.12},Interval=0.5,Stat="CritChance"}}},{{12,20,1.5,110,0,"Peck","Circle 2.5",""},{15,21,1.47,150},{18,22,1.43,200},{22,23,1.4,270},{27,24,1.37,365},{33,25,1.33,495},{40,26,1.3,0}}}
D.Sidapa={"Dark","Hybrid",2,475,0.06,2,{Reap=1,Toll=2},{"Death's Toll","StatusBurst",45,{Duration=5,Scope="Map",Status="Weaken"}},{{"Execute","Measured Life",{ThresholdByTier={0.1,0.1,0.11,0.12,0.13,0.14,0.15,0.16,0.17,0.18}}},{"KillStack","Harvest",{Max=0.3,PerKill=0.01}}},{{45,20,1.3,160,0,"Reap","Circle 4",""},{51,21,1.28,205},{57,22,1.26,260},{64,23,1.23,335},{72,24,1.21,430},{81,24,1.19,550},{91,25,1.17,705},{103,26,1.14,900},{116,27,1.12,1155},{130,28,1.1,0,0,"Toll","Circle 5",""}}}
D.Sidapa_LastMeasure={"Dark","Hybrid",2,475,0.06,2,{Reap=1,Toll=2},{"Death's Toll","StatusBurst",45,{Duration=5,Scope="Map",Status="Weaken"}},{{"Execute","Measured Life",{ThresholdByTier={0.15,0.15,0.16,0.17,0.18,0.19,0.2,0.21,0.22,0.23}}},{"KillStack","Harvest",{Max=0.3,PerKill=0.01}}},{{59,20,1.3,160,0,"Reap","Circle 4",""},{66,21,1.28,205},{74,22,1.26,260},{83,23,1.23,335},{94,24,1.21,430},{105,24,1.19,550},{118,25,1.17,705},{134,26,1.14,900},{151,27,1.12,1155},{169,28,1.1,0,0,"Toll","Circle 5",""}}}
D.Sigbin={"Dark","Hybrid",3,300,0.05,2,{Devour=2,Shadow=1},false,{{"ConsecutiveHits","Shadow Feeding",{Max=0.3,PerHit=0.02}}},{{30,18,1.6,120,0,"Shadow","Circle 2.5",""},{35,19,1.57,160},{41,20,1.54,210},{48,21,1.51,275},{56,21,1.49,365},{66,22,1.46,480},{77,23,1.43,635},{90,24,1.4,0,0,"Devour","Circle 3.5",""}}}
D.Siyokoy={"Water","Ground",4,175,0.05,2,{Grasp=1},false,{{"BonusVs","Undertow",{Condition="Status",Mult=1.3,Status="Slow"}}},{{20,11,2,90,0,"Grasp","Box 4x11","Slow"},{25,12,1.96,120},{31,12,1.92,165},{39,13,1.88,220},{48,14,1.84,300},{60,15,1.8,0}}}
D.Tala={"Cosmic","Hill",2,500,0.06,2,{Starfall=5},false,{{"AllyDamageAura","Guiding Star",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.07,1.08,1.08,1.09,1.09,1.1},Stat="Range"}},{"EveryNthAttack","Constellation",{Mult=2,N=3}}},{{50,26,1.4,170,0,"Starfall","Circle 3",""},{57,27,1.39,215},{64,28,1.37,275},{72,29,1.36,350},{82,30,1.34,440},{92,31,1.33,560},{104,32,1.31,715},{118,33,1.3,905},{133,34,1.28,1150},{150,35,1.26,1460},{170,36,1.25,0}}}
D.Tala_MorningStar={"Cosmic","Hill",2,500,0.06,2,{Starfall=5},false,{{"AllyDamageAura","Guiding Star",{Interval=0.5,MultByTier={1.05,1.05,1.06,1.06,1.07,1.07,1.08,1.08,1.09,1.09,1.1},Stat="Range"}},{"EveryNthAttack","Constellation",{Mult=2,N=2}}},{{65,26,1.4,170,0,"Starfall","Circle 3",""},{74,27,1.39,215},{83,28,1.37,275},{94,29,1.36,350},{107,30,1.34,440},{120,31,1.33,560},{135,32,1.31,715},{153,33,1.3,905},{173,34,1.28,1150},{195,35,1.26,1460},{221,36,1.25,0}}}
D.Tikbalang={"Neutral","Ground",3,250,0.06,2,{Kick=1},false,{{"Knockback","Lead Astray",{Chance=0.2,Duration=0.6,Status="Stun",Studs=6}}},{{30,11,1.9,120,0,"Kick","Circle 3",""},{36,12,1.87,160},{42,12,1.83,220},{50,13,1.8,295},{60,14,1.77,400},{71,14,1.73,540},{84,15,1.7,0}}}
D.Tiyanak={"Dark","Ground",2,525,0.06,2,{Bite=1},false,{{"EnterRangeStatus","Lost Child's Cry",{Duration=1,Status="Stun"}},{"ArmorPierce","Bite",{Fraction=1}}},{{70,13,2,175,0,"Bite","Circle 3.5",""},{80,14,1.99,220},{91,14,1.97,275},{103,15,1.96,340},{117,15,1.95,425},{134,16,1.93,535},{152,16,1.92,670},{173,17,1.9,835},{197,17,1.89,1045},{224,18,1.88,1305},{255,18,1.86,1630},{290,19,1.85,0}}}
D.Tiyanak_Changeling={"Dark","Ground",2,525,0.06,2,{Bite=1},false,{{"EnterRangeStatus","Lost Child's Cry",{Duration=1,Status="Stun"}},{"ArmorPierce","Bite",{Fraction=1}},{"BonusVs","Prey",{Condition="Status",Mult=1.4,Status="Stun"}}},{{91,13,2,175,0,"Bite","Circle 3.5",""},{104,14,1.99,220},{118,14,1.97,275},{134,15,1.96,340},{152,15,1.95,425},{174,16,1.93,535},{198,16,1.92,670},{225,17,1.9,835},{256,17,1.89,1045},{291,18,1.88,1305},{332,18,1.86,1630},{377,19,1.85,0}}}
D.Urduja={"Neutral","Ground",2,350,0.05,2,{},{"War Cry","TempStatBuff",25,{Duration=12,Mult=1.6,Stat="Damage"}},{{"AllyDamageAura","Ally Damage Aura",{Interval=0.5,Mult=1.08,Stat="Damage"}}},{{25,18,1,125,0,"","Circle 3",""},{29,19,0.97,170},{33,19,0.95,230},{37,20,0.93,310},{42,20,0.9,415},{48,21,0.88,565},{55,22,0.85,760},{63,22,0.83,1025},{72,23,0.8,0}}}
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
