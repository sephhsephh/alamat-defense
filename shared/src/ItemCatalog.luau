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

	-- ===== Currencies =====
	-- StatRerolls added B45 (AD-Game, user-approved): C2's stat reroll SPENDS Currencies.StatRerolls,
	-- but GrantService.Grant refuses any uncatalogued id (invariant 4), so nothing could MINT it and
	-- the sink had no faucet. Catalogued here it becomes grantable; RewardScalingConfig.InsaneItems
	-- is its one source, exactly as TraitRerollToken is C1's.
	-- ⚠ ICON IS A PLACEHOLDER (rbxassetid://0) -- FOR THE USER TO AUTHOR, same as the five entries
	-- they filled at B22. It renders as a blank square until then; nothing else breaks.
	Gold        = { Kind = "Currency", Tier = "Common", Name = "Gold",        Description = "Gacha / banner roll currency.",       Icon = { Image = "rbxassetid://128910310881167" }, Tradeable = false },
	Silver      = { Kind = "Currency", Tier = "Common", Name = "Silver",      Description = "Soft currency from dupes / sells.",   Icon = { Image = "rbxassetid://119213648374305" }, Tradeable = false },
	StatRerolls = { Kind = "Currency", Tier = "Rare",   Name = "Stat Reroll", Description = "Rerolls a unit's three stat rolls.",  Icon = { Image = "rbxassetid://0" }, Tradeable = false },

	-- ===== Items (existing stage drops) =====
	BannerTicket     = { Kind = "Item", Tier = "Rare",      Name = "Banner Ticket",      Description = "A free banner pull.",       Icon = { Image = "rbxassetid://6731922404" }, MaxOwned = 9999, Tradeable = false },
	TraitRerollToken = { Kind = "Item", Tier = "Epic",      Name = "Trait Reroll Token", Description = "Reroll a unit's trait.",     Icon = { Image = "rbxassetid://12590248124" }, MaxOwned = 9999, Tradeable = false },
	GoldenSeed       = { Kind = "Item", Tier = "Legendary", Name = "Golden Seed",        Description = "Rare crafting material.",    Icon = { Image = "rbxassetid://124757602236693" }, MaxOwned = 9999, Tradeable = false },

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
