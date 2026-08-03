--!strict
-- AscensionConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.AscensionConfig)
-- Dupe-fed power tiers for Mythic+ units (phase C spends the Cost; A3 only wires the stat
-- MULTIPLIERS into the resolver). Mults are ABSOLUTE strength multipliers for being AT that
-- level (A1 x1.05 -> A3 x3, not cumulative), applied to the rollable stats (DMG/RNG/SPA) by
-- TowerStatResolver in the same 'higher = stronger' direction as meta/trait (so SPA is
-- DIVIDED). Only DMG scales by default; use PerTower for others.
--
-- SHARED since 2026-08-01 (A-phase Integration promotion) -- byte-identical to the A3 original.
-- The Game's TowerStatResolver requires it; the Lobby needs it to display ascension levels.

local AscensionConfig = {}

AscensionConfig.MaxLevel = 3
AscensionConfig.MinTier = "Mythic" -- only Mythic+ units may ascend (enforced by phase-C spend UI)

AscensionConfig.Levels = {
	[1] = { Cost = { Dupes = 1, Items = {} }, Mults = { DMG = 1.05 } },
	[2] = { Cost = { Dupes = 1, Items = {} }, Mults = { DMG = 1.5 } },
	[3] = { Cost = { Dupes = 1, Items = {} }, Mults = { DMG = 3.0 } },
}

-- Optional per-tower overrides: PerTower = { [towerId] = { Levels = { [1] = {Mults={...}}, ... } } }
AscensionConfig.PerTower = {} :: { [string]: any }

-- Absolute strength multiplier for a roll stat (DMG/RNG/SPA) at an ascension level.
-- level 0 (or missing) -> 1.0. Unlisted stats -> 1.0.
function AscensionConfig.GetMult(rollKey: string, level: number?, towerId: string?): number
	local lv = math.floor(level or 0)
	if lv <= 0 then
		return 1.0
	end
	lv = math.clamp(lv, 0, AscensionConfig.MaxLevel)

	local levels = AscensionConfig.Levels
	if towerId then
		local over = AscensionConfig.PerTower[towerId]
		if over and over.Levels then
			levels = over.Levels
		end
	end

	local entry = levels[lv]
	local mult = entry and entry.Mults and entry.Mults[rollKey]
	return mult or 1.0
end

function AscensionConfig.GetCost(level: number, towerId: string?): any?
	local lv = math.floor(level or 0)
	if lv <= 0 or lv > AscensionConfig.MaxLevel then
		return nil
	end
	local levels = AscensionConfig.Levels
	if towerId then
		local over = AscensionConfig.PerTower[towerId]
		if over and over.Levels then
			levels = over.Levels
		end
	end
	local entry = levels[lv]
	return entry and entry.Cost
end

return AscensionConfig
