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
	Archer      = { Kind = "Tower", Tier = "Common",    Name = "Archer",      Description = "Baseline small-circle AoE archer.",     Icon = { Model = { "TowerModels", "Archer" } },      Tradeable = false },
	Knight      = { Kind = "Tower", Tier = "Common",    Name = "Knight",      Description = "Melee box/cone bruiser.",              Icon = { Model = { "TowerModels", "Knight" } },      Tradeable = false },
	Mage        = { Kind = "Tower", Tier = "Rare",      Name = "Mage",        Description = "Ranged burst caster.",                Icon = { Model = { "TowerModels", "Mage" } },        Tradeable = false },
	Farm        = { Kind = "Tower", Tier = "Rare",      Name = "Farm",        Description = "Support: per-wave income + range aura.", Icon = { Model = { "TowerModels", "Farm" } },       Tradeable = false },
	Babaylan    = { Kind = "Tower", Tier = "Epic",      Name = "Babaylan",    Description = "Full-AoE support attacker.",           Icon = { Model = { "TowerModels", "Babaylan" } },    Tradeable = false },
	Meteor      = { Kind = "Tower", Tier = "Legendary", Name = "Meteor",      Description = "Map-wide Nuke ability.",              Icon = { Model = { "TowerModels", "Meteor" } },      Tradeable = false },
	Warchief    = { Kind = "Tower", Tier = "Legendary", Name = "Warchief",    Description = "War Cry self-buff + ally damage aura.", Icon = { Model = { "TowerModels", "Warchief" } },   Tradeable = false },
	Necromancer = { Kind = "Tower", Tier = "Mythic",    Name = "Necromancer", Description = "Summon-on-kill chargers.",            Icon = { Model = { "TowerModels", "Necromancer" } }, Tradeable = false },

	-- ===== Currencies =====
	Gold   = { Kind = "Currency", Tier = "Common", Name = "Gold",   Description = "Gacha / banner roll currency.",       Icon = { Image = "rbxassetid://0" }, Tradeable = false },
	Silver = { Kind = "Currency", Tier = "Common", Name = "Silver", Description = "Soft currency from dupes / sells.",    Icon = { Image = "rbxassetid://0" }, Tradeable = false },

	-- ===== Items (existing stage drops) =====
	BannerTicket     = { Kind = "Item", Tier = "Rare",      Name = "Banner Ticket",      Description = "A free banner pull.",       Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	TraitRerollToken = { Kind = "Item", Tier = "Epic",      Name = "Trait Reroll Token", Description = "Reroll a unit's trait.",     Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
	GoldenSeed       = { Kind = "Item", Tier = "Legendary", Name = "Golden Seed",        Description = "Rare crafting material.",    Icon = { Image = "rbxassetid://0" }, MaxOwned = 9999, Tradeable = false },
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
