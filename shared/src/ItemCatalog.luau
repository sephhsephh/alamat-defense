--!strict
-- ItemCatalog.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.ItemCatalog)
-- THE registry of every grantable thing (towers, items, currencies, and later spirits/titles/
-- skins). One entry per id. Icon assetids are placeholders until the icon kit lands; Model
-- icons point at the existing tower rigs. Everything is Tradeable=false at launch.
--
-- SHARED since 2026-08-01 (A-phase Integration promotion). The Lobby reads Name/Tier/Icon per
-- unit for the collection + hover UI, which is why this had to leave Game-only canon. It also
-- REPLACES the Lobby's interim `UnitCatalog` (deleted at promotion) as the source of a unit's
-- display name and tier.
--
-- PLACE-DEPENDENT VALIDATION: Validate()'s "every Tower entry has a TowerConfig" cross-check
-- needs `RS.Configs.Towers.TowerConfigRegistry`, which exists ONLY in the Game place. The
-- require is therefore LAZY + OPTIONAL: in the Game the check runs (MetaConfigTest asserts it
-- at boot); in the Lobby it is skipped and reported, so this module loads cleanly in a Place
-- that has no tower configs. Every other check runs everywhere.

local ItemCatalog = {}

local TierConfig = require(script.Parent.TierConfig)

-- Tier assignment for the 8 existing towers per blueprint phase-a-foundations.md section 3 (tunable).
ItemCatalog.Entries = {
	-- ===== Towers =====
	Handyong    = { Kind = "Tower", Tier = "Common",    Name = "Handyong",      Description = "Baseline small-circle AoE archer.",     Icon = { Model = { "TowerModels", "Handyong" } },      Tradeable = false },
	Bantong     = { Kind = "Tower", Tier = "Common",    Name = "Bantong",      Description = "Melee box/cone bruiser.",              Icon = { Model = { "TowerModels", "Bantong" } },      Tradeable = false },
	Oryol       = { Kind = "Tower", Tier = "Rare",      Name = "Oryol",        Description = "Ranged burst caster.",                Icon = { Model = { "TowerModels", "Oryol" } },        Tradeable = false },
	Lakapati    = { Kind = "Tower", Tier = "Rare",      Name = "Lakapati",        Description = "Support: per-wave income + range aura.", Icon = { Model = { "TowerModels", "Lakapati" } },       Tradeable = false },
	Babaylan    = { Kind = "Tower", Tier = "Epic",      Name = "Babaylan",    Description = "Full-AoE support attacker.",           Icon = { Model = { "TowerModels", "Babaylan" } },    Tradeable = false },
	Bulalakaw   = { Kind = "Tower", Tier = "Legendary", Name = "Bulalakaw",      Description = "Map-wide Nuke ability.",              Icon = { Model = { "TowerModels", "Bulalakaw" } },      Tradeable = false },
	Urduja      = { Kind = "Tower", Tier = "Legendary", Name = "Urduja",    Description = "War Cry self-buff + ally damage aura.", Icon = { Model = { "TowerModels", "Urduja" } },   Tradeable = false },
	Magwayen    = { Kind = "Tower", Tier = "Mythic",    Name = "Magwayen", Description = "Summon-on-kill chargers.",            Icon = { Model = { "TowerModels", "Magwayen" } }, Tradeable = false },
	-- B106 roster (docs/design/unit-roster.md) -- placeholder rigs until the real ones land.
	Baltog      = { Kind = "Tower", Tier = "Common",    Name = "Baltog",      Description = "Melee grappler; +40% vs bosses.",        Icon = { Model = { "TowerModels", "Baltog" } },      Tradeable = false },
	Duwende     = { Kind = "Tower", Tier = "Uncommon",  Name = "Duwende",     Description = "Fast pebbles; lucky pesos on kills.",    Icon = { Model = { "TowerModels", "Duwende" } },     Tradeable = false },
	Santelmo    = { Kind = "Tower", Tier = "Uncommon",  Name = "Santelmo",    Description = "Two burning wisps per attack.",          Icon = { Model = { "TowerModels", "Santelmo" } },    Tradeable = false },
	Mangkukulam = { Kind = "Tower", Tier = "Uncommon",  Name = "Mangkukulam", Description = "Stacks Sumpa: enemies take more damage.", Icon = { Model = { "TowerModels", "Mangkukulam" } }, Tradeable = false },
	Siyokoy     = { Kind = "Tower", Tier = "Uncommon",  Name = "Siyokoy",     Description = "Drowning grab; slows, punishes slowed.", Icon = { Model = { "TowerModels", "Siyokoy" } },     Tradeable = false },
	Kapre       = { Kind = "Tower", Tier = "Rare",      Name = "Kapre",       Description = "Smoke cone; stronger in a crowd.",       Icon = { Model = { "TowerModels", "Kapre" } },       Tradeable = false },
	NunoSaPunso = { Kind = "Tower", Tier = "Rare",      Name = "Nuno sa Punso", Description = "Support: weakens every enemy in range.", Icon = { Model = { "TowerModels", "NunoSaPunso" } }, Tradeable = false },
	Sarimanok   = { Kind = "Tower", Tier = "Rare",      Name = "Sarimanok",   Description = "Support: allies in range crit more.",    Icon = { Model = { "TowerModels", "Sarimanok" } },   Tradeable = false },
	Mambabarang = { Kind = "Tower", Tier = "Epic",      Name = "Mambabarang", Description = "Insect swarm DoT that spreads on kills.", Icon = { Model = { "TowerModels", "Mambabarang" } }, Tradeable = false },
	Amomongo    = { Kind = "Tower", Tier = "Epic",      Name = "Amomongo",    Description = "Melee claws; frenzies every 10 kills.",  Icon = { Model = { "TowerModels", "Amomongo" } },    Tradeable = false },
	Engkanto      = { Kind = "Tower", Tier = "Epic", Name = "Engkanto", Description = "Crit archer; crits stun, first hits hurt.", Icon = { Model = { "TowerModels", "Engkanto" } }, Tradeable = false },
	Sigbin        = { Kind = "Tower", Tier = "Epic", Name = "Sigbin", Description = "Ramps on the same target, +30% max.", Icon = { Model = { "TowerModels", "Sigbin" } }, Tradeable = false },
	LamAng        = { Kind = "Tower", Tier = "Legendary", Name = "Lam-ang", Description = "Melee hero; anti-boss; Rooster's Crow stun.", Icon = { Model = { "TowerModels", "LamAng" } }, Tradeable = false },
	BernardoCarpio = { Kind = "Tower", Tier = "Legendary", Name = "Bernardo Carpio", Description = "Field slam; every 5th attack a quake stun.", Icon = { Model = { "TowerModels", "BernardoCarpio" } }, Tradeable = false },
	MariaMakiling = { Kind = "Tower", Tier = "Legendary", Name = "Maria Makiling", Description = "Support: income + ally damage and range.", Icon = { Model = { "TowerModels", "MariaMakiling" } }, Tradeable = false },
	Minokawa      = { Kind = "Tower", Tier = "Legendary", Name = "Minokawa", Description = "Four beaks; anti-boss, anti-air.", Icon = { Model = { "TowerModels", "Minokawa" } }, Tradeable = false },
	Apolaki       = { Kind = "Tower", Tier = "Mythic", Name = "Apolaki", Description = "Sun beam that grows every wave.", Icon = { Model = { "TowerModels", "Apolaki" } }, Tradeable = false },
	Mayari        = { Kind = "Tower", Tier = "Mythic", Name = "Mayari", Description = "Long-range crit sniper.", Icon = { Model = { "TowerModels", "Mayari" } }, Tradeable = false },
	Sidapa        = { Kind = "Tower", Tier = "Mythic", Name = "Sidapa", Description = "Executes weakened enemies.", Icon = { Model = { "TowerModels", "Sidapa" } }, Tradeable = false },
	Tala          = { Kind = "Tower", Tier = "Limited", Name = "Tala", Description = "Five-star starfall; allies gain range.", Icon = { Model = { "TowerModels", "Tala" } }, Tradeable = false },
	Lalahon       = { Kind = "Tower", Tier = "Limited", Name = "Lalahon", Description = "Volcanic field burn; burning kills pay.", Icon = { Model = { "TowerModels", "Lalahon" } }, Tradeable = false },
	Bathala       = { Kind = "Tower", Tier = "Alamat", Name = "Bathala", Description = "The creator: buffs every ally, judges every enemy.", Icon = { Model = { "TowerModels", "Bathala" } }, Tradeable = false },
	Bakunawa      = { Kind = "Tower", Tier = "Alamat", Name = "Bakunawa", Description = "Moon-eater; every 7th attack eclipses the map.", Icon = { Model = { "TowerModels", "Bakunawa" } }, Tradeable = false },
	Tikbalang     = { Kind = "Tower", Tier = "Rare", Name = "Tikbalang", Description = "Teleporting trickster; throws enemies back.", Icon = { Model = { "TowerModels", "Tikbalang" } }, Tradeable = false },
	AmanSinaya    = { Kind = "Tower", Tier = "Mythic", Name = "Aman Sinaya", Description = "Sea goddess; waves push enemies back.", Icon = { Model = { "TowerModels", "AmanSinaya" } }, Tradeable = false },
	Aswang        = { Kind = "Tower", Tier = "Secret", Name = "Aswang", Description = "Shapeshifter: dog, bird, human each wave.", Icon = { Model = { "TowerModels", "Aswang" } }, Tradeable = false },
	Tiyanak       = { Kind = "Tower", Tier = "Secret", Name = "Tiyanak", Description = "Stuns newcomers; bites ignore armor.", Icon = { Model = { "TowerModels", "Tiyanak" } }, Tradeable = false },
	Batibat       = { Kind = "Tower", Tier = "Secret", Name = "Batibat", Description = "Slows even bosses; puts enemies to sleep.", Icon = { Model = { "TowerModels", "Batibat" } }, Tradeable = false },
	-- B106 EVOLVED FORMS -- never summoned (`Summonable = false`, honoured by the Lobby's BannerRegistry);
	-- reached only through Configs/Evolutions/<BaseId> in the Lobby. `EvolvedFrom` names the base unit.
	Mayari_LunarEclipse = { Kind = "Tower", Tier = "Mythic", Name = "Mayari (Lunar Eclipse)", Description = "Evolved Mayari: +30% damage; crits Weaken.", Icon = { Model = { "TowerModels", "Mayari_LunarEclipse" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Mayari" },
	Apolaki_Zenith = { Kind = "Tower", Tier = "Mythic", Name = "Apolaki (Zenith)", Description = "Evolved Apolaki: +30% damage; Rising Sun to +80%.", Icon = { Model = { "TowerModels", "Apolaki_Zenith" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Apolaki" },
	Bathala_Ascended = { Kind = "Tower", Tier = "Alamat", Name = "Bathala (Ascended)", Description = "Evolved Bathala: +30% damage; all your towers 10% faster.", Icon = { Model = { "TowerModels", "Bathala_Ascended" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Bathala" },
	Bakunawa_Eclipse = { Kind = "Tower", Tier = "Alamat", Name = "Bakunawa (Eclipse)", Description = "Evolved Bakunawa: +30% damage; Eclipse every 5th attack.", Icon = { Model = { "TowerModels", "Bakunawa_Eclipse" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Bakunawa" },
	Magwayen_Soulferry = { Kind = "Tower", Tier = "Mythic", Name = "Magwayen (Soulferry)", Description = "Evolved Magwayen: +30% damage; raised souls return at full strength.", Icon = { Model = { "TowerModels", "Magwayen_Soulferry" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Magwayen" },
	Sidapa_LastMeasure = { Kind = "Tower", Tier = "Mythic", Name = "Sidapa (Last Measure)", Description = "Evolved Sidapa: +30% damage; executes 5 points higher.", Icon = { Model = { "TowerModels", "Sidapa_LastMeasure" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Sidapa" },
	AmanSinaya_Riptide = { Kind = "Tower", Tier = "Mythic", Name = "Aman Sinaya (Riptide)", Description = "Evolved Aman Sinaya: +30% damage; Great Wave floods the whole map.", Icon = { Model = { "TowerModels", "AmanSinaya_Riptide" } }, Tradeable = false, Summonable = false, EvolvedFrom = "AmanSinaya" },
	Tala_MorningStar = { Kind = "Tower", Tier = "Limited", Name = "Tala (Morning Star)", Description = "Evolved Tala: +30% damage; Constellation every 2nd attack.", Icon = { Model = { "TowerModels", "Tala_MorningStar" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Tala" },
	Lalahon_Caldera = { Kind = "Tower", Tier = "Limited", Name = "Lalahon (Caldera)", Description = "Evolved Lalahon: +30% damage; burning kills spread Burn to 3.", Icon = { Model = { "TowerModels", "Lalahon_Caldera" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Lalahon" },
	Aswang_BloodMoon = { Kind = "Tower", Tier = "Secret", Name = "Aswang (Blood Moon)", Description = "Evolved Aswang: +30% damage; Feeding caps at +80%.", Icon = { Model = { "TowerModels", "Aswang_BloodMoon" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Aswang" },
	Tiyanak_Changeling = { Kind = "Tower", Tier = "Secret", Name = "Tiyanak (Changeling)", Description = "Evolved Tiyanak: +30% damage; +40% vs Stunned enemies.", Icon = { Model = { "TowerModels", "Tiyanak_Changeling" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Tiyanak" },
	Batibat_NightTerror = { Kind = "Tower", Tier = "Secret", Name = "Batibat (Night Terror)", Description = "Evolved Batibat: +30% damage; the waking hit deals x2.", Icon = { Model = { "TowerModels", "Batibat_NightTerror" } }, Tradeable = false, Summonable = false, EvolvedFrom = "Batibat" },

	-- ===== Currencies =====
	-- StatRerolls added B45 (AD-Game, user-approved): C2's stat reroll SPENDS Currencies.StatRerolls,
	-- but GrantService.Grant refuses any uncatalogued id (invariant 4), so nothing could MINT it and
	-- the sink had no faucet. Catalogued here it becomes grantable; RewardScalingConfig.InsaneItems
	-- is its one source, exactly as TraitRerollToken is C1's.
	-- ⚠ ICON IS A PLACEHOLDER (rbxassetid://0) -- FOR THE USER TO AUTHOR, same as the five entries
	-- they filled at B22. It renders as a blank square until then; nothing else breaks.
	Gold        = { Kind = "Currency", Tier = "Common", Name = "Gold",        Description = "Gacha / banner roll currency.",       Icon = { Image = "rbxassetid://128910310881167" }, Tradeable = false },
	Silver      = { Kind = "Currency", Tier = "Common", Name = "Silver",      Description = "Soft currency from dupes / sells.",   Icon = { Image = "rbxassetid://119213648374305" }, Tradeable = false },
	-- B109: Battle Pass EXP as a REWARD (quests/achievements). Not a stored currency: GrantService routes Kind
	-- "BattlepassXP" to BattlepassService (ServerStorage.BattlepassAddXP), the one writer of Data.Battlepass.
	BattlepassXP = { Kind = "BattlepassXP", Tier = "Rare", Name = "Battlepass EXP", Description = "Experience for the Battle Pass.", Icon = { Image = "rbxassetid://3057073083" }, Tradeable = false },
	StatRerolls = { Kind = "Currency", Tier = "Rare",   Name = "Stat Chip",   Description = "Rerolls all three of a unit's stats.", Icon = { Image = "rbxassetid://0" }, Tradeable = false },

	-- ===== Items (existing stage drops) =====
	BannerTicket     = { Kind = "Item", Tier = "Rare",      Name = "Banner Ticket",      Description = "A free banner pull.",       Icon = { Image = "rbxassetid://6731922404" }, MaxOwned = 9999, Tradeable = false },
	TraitRerollToken = { Kind = "Item", Tier = "Epic",      Name = "Trait Reroll Token", Description = "Reroll a unit's trait.",     Icon = { Image = "rbxassetid://12590248124" }, MaxOwned = 9999, Tradeable = false },
	GoldenSeed       = { Kind = "Item", Tier = "Legendary", Name = "Golden Seed",        Description = "Rare crafting material.",    Icon = { Image = "rbxassetid://124757602236693" }, MaxOwned = 9999, Tradeable = false },
	-- B106: evolution relic. Drops from the Stage 1 boss act (Stage1_Act3 DropTable). Icon PLACEHOLDER (user).
	ScarecrowCrown   = { Kind = "Item", Tier = "Legendary", Name = "Scarecrow Crown",    Description = "Relic of the Scarecrow King; used to evolve units.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	-- B108: the second stat-reroll chip (user: "second chip is used to reroll only a specific stat"). An ITEM, not a
	-- currency, so no ProfileTemplate change. The first chip is the StatRerolls currency ("Stat Chip"). Icon PLACEHOLDER (user).
	FocusChip        = { Kind = "Item", Tier = "Epic",      Name = "Focus Chip",         Description = "Rerolls ONE chosen stat of a unit.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },

	-- ===== B108: MUTYA stones (user-approved crafting economy, the reference's model) =====
	-- ONE base stone (Green Mutya) + Silver crafts each colour Mutya; Rainbow = 1 of each colour + 1 Green
	-- + Silver. Dismantle turns a stone back into Green Mutya and COSTS Silver (user). Recipes + dismantle
	-- table: RS.Configs.Meta.CraftingRecipes (Lobby). Icons PLACEHOLDER (user authors art).
	-- B108 pt11 (user): every Mutya uses the ONE white MutyaIcon asset; `Icon.Gradient` (hex stops) is the
	-- tint UIKit.ItemIcon.applyTint lays over it as an animated UIGradient.
	MutyaGreen   = { Kind = "Item", Tier = "Epic",      Name = "Green Mutya",   Description = "The base Mutya stone. Crafts every colour Mutya.",          Icon = { Image = "rbxassetid://72082627938021", Gradient = { "3CFF6E", "C8FFD6", "14A546" } }, MaxOwned = 9999, Tradeable = false },
	MutyaRed     = { Kind = "Item", Tier = "Legendary", Name = "Red Mutya",     Description = "A Mutya stone used to evolve units.",                       Icon = { Image = "rbxassetid://72082627938021", Gradient = { "FF3C46", "FFB4A0", "A8141E" } }, MaxOwned = 9999, Tradeable = false },
	MutyaBlue    = { Kind = "Item", Tier = "Legendary", Name = "Blue Mutya",    Description = "A Mutya stone used to evolve units.",                       Icon = { Image = "rbxassetid://72082627938021", Gradient = { "3C8CFF", "B4DCFF", "143CBE" } }, MaxOwned = 9999, Tradeable = false },
	MutyaYellow  = { Kind = "Item", Tier = "Legendary", Name = "Yellow Mutya",  Description = "A Mutya stone used to evolve units.",                       Icon = { Image = "rbxassetid://72082627938021", Gradient = { "FFD732", "FFF5AA", "D2960A" } }, MaxOwned = 9999, Tradeable = false },
	MutyaPurple  = { Kind = "Item", Tier = "Legendary", Name = "Purple Mutya",  Description = "A Mutya stone used to evolve units.",                       Icon = { Image = "rbxassetid://72082627938021", Gradient = { "AA50FF", "DCB4FF", "641EB4" } }, MaxOwned = 9999, Tradeable = false },
	MutyaPink    = { Kind = "Item", Tier = "Legendary", Name = "Pink Mutya",    Description = "A Mutya stone used to evolve units.",                       Icon = { Image = "rbxassetid://72082627938021", Gradient = { "FF6EC8", "FFC8EB", "C8328C" } }, MaxOwned = 9999, Tradeable = false },
	MutyaRainbow = { Kind = "Item", Tier = "Mythic",    Name = "Rainbow Mutya", Description = "Made from one of every colour Mutya. Needed for evolutions.", Icon = { Image = "rbxassetid://72082627938021", Gradient = { "FF3C46", "FF9628", "FFE132", "3CFF6E", "3C8CFF", "AA50FF" } }, MaxOwned = 9999, Tradeable = false },

	-- ===== B108: EXP FOOD (user). Feed a unit for XP (`ExpFood` = XP per item); each unit also needs its
	-- own food to ASCEND (AscensionConfig.FoodFor). Drop from stage acts + the shop Food tab. Icons PLACEHOLDER. =====
	FoodPandesal = { Kind = "Item", Tier = "Common", Name = "Pandesal", Description = "Warm bread roll. Grants 20 EXP to a unit.", ExpFood = 20, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FoodTuron    = { Kind = "Item", Tier = "Uncommon", Name = "Turon", Description = "Sweet banana roll. Grants 45 EXP to a unit.", ExpFood = 45, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FoodBibingka = { Kind = "Item", Tier = "Rare", Name = "Bibingka", Description = "Rice cake from the clay oven. Grants 75 EXP to a unit.", ExpFood = 75, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FoodAdobo    = { Kind = "Item", Tier = "Epic", Name = "Adobo", Description = "The house classic. Grants 150 EXP to a unit.", ExpFood = 150, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FoodSinigang = { Kind = "Item", Tier = "Legendary", Name = "Sinigang", Description = "Sour tamarind stew. Grants 280 EXP to a unit.", ExpFood = 280, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FoodLechon   = { Kind = "Item", Tier = "Mythic", Name = "Lechon", Description = "The feast centrepiece. Grants 300 EXP to a unit.", ExpFood = 300, Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },

	-- ===== LEGACY (B50-B107) crafting materials -- RETIRED at B108. Kept catalogued ONLY so an old reward
	-- still sitting in a queue (PendingReveals / mail) can be granted; the Lobby converts them to Mutya on
	-- profile load (UnitDiscoveryService.migrateCrafting). Nothing new drops or costs these. =====
	-- ===== Crafting materials (Phase D / D1): fragments -> colour artifacts (2:1) -> Rainbow (all 7). =====
	-- 7 ROYGBIV fragment colours. 2 fragments of a colour craft that colour's artifact; all 7 colour
	-- artifacts craft the Rainbow. Recipes: RS.Configs.Meta.CraftingRecipes (Lobby). Icons PLACEHOLDER
	-- rbxassetid://0 (author later). Source: interim Lobby drop now, the D2 challenge stage later.
	FragmentRed = { Kind = "Item", Tier = "Rare", Name = "Red Fragment", Description = "Crafting fragment; 2 craft a Red Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentOrange = { Kind = "Item", Tier = "Rare", Name = "Orange Fragment", Description = "Crafting fragment; 2 craft an Orange Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentYellow = { Kind = "Item", Tier = "Rare", Name = "Yellow Fragment", Description = "Crafting fragment; 2 craft a Yellow Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentGreen = { Kind = "Item", Tier = "Rare", Name = "Green Fragment", Description = "Crafting fragment; 2 craft a Green Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentBlue = { Kind = "Item", Tier = "Rare", Name = "Blue Fragment", Description = "Crafting fragment; 2 craft a Blue Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentIndigo = { Kind = "Item", Tier = "Rare", Name = "Indigo Fragment", Description = "Crafting fragment; 2 craft an Indigo Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	FragmentViolet = { Kind = "Item", Tier = "Rare", Name = "Violet Fragment", Description = "Crafting fragment; 2 craft a Violet Artifact.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactRed = { Kind = "Item", Tier = "Epic", Name = "Red Artifact", Description = "Crafted from 2 Red Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactOrange = { Kind = "Item", Tier = "Epic", Name = "Orange Artifact", Description = "Crafted from 2 Orange Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactYellow = { Kind = "Item", Tier = "Epic", Name = "Yellow Artifact", Description = "Crafted from 2 Yellow Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactGreen = { Kind = "Item", Tier = "Epic", Name = "Green Artifact", Description = "Crafted from 2 Green Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactBlue = { Kind = "Item", Tier = "Epic", Name = "Blue Artifact", Description = "Crafted from 2 Blue Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactIndigo = { Kind = "Item", Tier = "Epic", Name = "Indigo Artifact", Description = "Crafted from 2 Indigo Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactViolet = { Kind = "Item", Tier = "Epic", Name = "Violet Artifact", Description = "Crafted from 2 Violet Fragments; part of the Rainbow set.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	ArtifactRainbow = { Kind = "Item", Tier = "Mythic", Name = "Rainbow Artifact", Description = "The pinnacle craft, made from all 7 colour artifacts.", Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
}

function ItemCatalog.Get(id: string): any?
	return ItemCatalog.Entries[id]
end

-- Display name for an id, falling back to the id itself so UI never renders an empty label.
function ItemCatalog.GetName(id: string): string
	local e = ItemCatalog.Entries[id]
	return (e and e.Name) or id
end

-- Tier for an id, falling back to Common so UI never nil-errors on an unlisted id.
function ItemCatalog.GetTier(id: string): string
	local e = ItemCatalog.Entries[id]
	return (e and e.Tier) or "Common"
end

local function iconResolves(icon: any): boolean
	if type(icon) ~= "table" then return false end
	if type(icon.Image) == "string" then return true end
	if type(icon.Model) == "table" then return true end
	return false
end

-- Present only in the Game place; see the header note. Returns nil in the Lobby.
local function findTowerConfigRegistry(): any?
	local configs = game:GetService("ReplicatedStorage"):FindFirstChild("Configs")
	local towers = configs and configs:FindFirstChild("Towers")
	local registry = towers and towers:FindFirstChild("TowerConfigRegistry")
	if not registry then
		return nil
	end
	local ok, mod = pcall(require, registry)
	return ok and mod or nil
end

-- Structural validation: every entry has a valid Kind/Tier/Icon, nothing is tradeable at
-- launch, and (Game place only) every Tower entry has a real TowerConfig.
-- Returns (ok, errors, notes) -- `notes` records checks that were SKIPPED for this Place.
function ItemCatalog.Validate(): (boolean, { string }, { string })
	local errs = {}
	local notes = {}

	local registry = findTowerConfigRegistry()
	if not registry then
		table.insert(notes, "TowerConfigRegistry absent (expected in the Lobby) - skipped the Tower->TowerConfig cross-check")
	end

	for id, e in pairs(ItemCatalog.Entries) do
		if type(e.Kind) ~= "string" then
			table.insert(errs, id .. ": missing Kind")
		end
		if type(e.Tier) ~= "string" or not TierConfig.IsValid(e.Tier) then
			table.insert(errs, id .. ": invalid Tier '" .. tostring(e.Tier) .. "'")
		end
		if not iconResolves(e.Icon) then
			table.insert(errs, id .. ": Icon does not resolve (needs Image or Model)")
		end
		if e.Kind == "Tower" and registry and not registry.Get(id) then
			table.insert(errs, id .. ": Tower entry has no TowerConfig")
		end
		if e.Tradeable ~= false then
			table.insert(errs, id .. ": must be Tradeable = false at launch")
		end
	end

	return #errs == 0, errs, notes
end

return ItemCatalog
