--!strict
-- AscensionConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.AscensionConfig)
-- Ascension = feed a unit an UNASCENDED duplicate of itself + its FOOD to raise it one star (max 3).
-- B108 (user, "match reference"): ANY tier may ascend; each level costs 1 dupe + 1 of the unit's own
-- food; bonuses are Ascension I +3% DMG, II +5% Range, III +7% DMG. Shiny and locked units are never
-- consumed as the dupe (Lobby AscensionService enforces it).
--
-- Mults are ABSOLUTE multipliers for being AT a level (not re-multiplied per level), applied to the
-- rollable stats by TowerStatResolver in the 'higher = stronger' direction (SPA would be DIVIDED):
--   A1 = DMG x1.03   A2 = DMG x1.03, RNG x1.05   A3 = DMG x1.10, RNG x1.05   (the three bonuses stack)
--
-- FoodFor: each unit's ascension food (user: "per unit"). A first pass by rarity -- edit any line.
-- Foods are ItemCatalog items (`ExpFood`) that also feed unit XP and drop from stage acts.
--
-- SHARED since 2026-08-01. The Game's TowerStatResolver requires it; the Lobby spends the Cost.

local AscensionConfig = {}

AscensionConfig.MaxLevel = 3
AscensionConfig.MinTier = nil :: string? -- B108: every tier may ascend (was "Mythic")

AscensionConfig.Levels = {
	[1] = { Cost = { Dupes = 1, Food = 1 }, Mults = { DMG = 1.03 },             Label = "Ascension I",   Bonus = "Increases damage by 3%" },
	[2] = { Cost = { Dupes = 1, Food = 1 }, Mults = { DMG = 1.03, RNG = 1.05 }, Label = "Ascension II",  Bonus = "Increases range by 5%" },
	[3] = { Cost = { Dupes = 1, Food = 1 }, Mults = { DMG = 1.10, RNG = 1.05 }, Label = "Ascension III", Bonus = "Increases damage by 7%" },
}

AscensionConfig.DefaultFood = "FoodLechon"
AscensionConfig.FoodFor = {
	Handyong             = "FoodPandesal",
	Bantong              = "FoodPandesal",
	Oryol                = "FoodBibingka",
	Lakapati             = "FoodBibingka",
	Babaylan             = "FoodAdobo",
	Bulalakaw            = "FoodSinigang",
	Urduja               = "FoodSinigang",
	Magwayen             = "FoodLechon",
	Baltog               = "FoodPandesal",
	Duwende              = "FoodTuron",
	Santelmo             = "FoodTuron",
	Mangkukulam          = "FoodTuron",
	Siyokoy              = "FoodTuron",
	Kapre                = "FoodBibingka",
	NunoSaPunso          = "FoodBibingka",
	Sarimanok            = "FoodBibingka",
	Mambabarang          = "FoodAdobo",
	Amomongo             = "FoodAdobo",
	Engkanto             = "FoodAdobo",
	Sigbin               = "FoodAdobo",
	LamAng               = "FoodSinigang",
	BernardoCarpio       = "FoodSinigang",
	MariaMakiling        = "FoodSinigang",
	Minokawa             = "FoodSinigang",
	Apolaki              = "FoodLechon",
	Mayari               = "FoodLechon",
	Sidapa               = "FoodLechon",
	Tala                 = "FoodLechon",
	Lalahon              = "FoodLechon",
	Bathala              = "FoodLechon",
	Bakunawa             = "FoodLechon",
	Tikbalang            = "FoodBibingka",
	AmanSinaya           = "FoodLechon",
	Aswang               = "FoodLechon",
	Tiyanak              = "FoodLechon",
	Batibat              = "FoodLechon",
	Mayari_LunarEclipse  = "FoodLechon",
	Apolaki_Zenith       = "FoodLechon",
	Bathala_Ascended     = "FoodLechon",
	Bakunawa_Eclipse     = "FoodLechon",
	Magwayen_Soulferry   = "FoodLechon",
	Sidapa_LastMeasure   = "FoodLechon",
	AmanSinaya_Riptide   = "FoodLechon",
	Tala_MorningStar     = "FoodLechon",
	Lalahon_Caldera      = "FoodLechon",
	Aswang_BloodMoon     = "FoodLechon",
	Tiyanak_Changeling   = "FoodLechon",
	Batibat_NightTerror  = "FoodLechon",
}

-- Optional per-tower overrides: PerTower = { [towerId] = { Levels = { [1] = {Mults={...}}, ... } } }
AscensionConfig.PerTower = {} :: { [string]: any }

local function levelsFor(towerId: string?): any
	if towerId then
		local over = AscensionConfig.PerTower[towerId]
		if over and over.Levels then
			return over.Levels
		end
	end
	return AscensionConfig.Levels
end

-- Absolute strength multiplier for a roll stat (DMG/RNG/SPA) at an ascension level.
function AscensionConfig.GetMult(rollKey: string, level: number?, towerId: string?): number
	local lv = math.floor(level or 0)
	if lv <= 0 then
		return 1.0
	end
	lv = math.clamp(lv, 0, AscensionConfig.MaxLevel)
	local entry = levelsFor(towerId)[lv]
	local mult = entry and entry.Mults and entry.Mults[rollKey]
	return mult or 1.0
end

function AscensionConfig.GetFood(towerId: string?): string
	return (towerId and AscensionConfig.FoodFor[towerId]) or AscensionConfig.DefaultFood
end

-- Cost to REACH `level` (1..MaxLevel): { Dupes, Items = { { Id, Qty } } } -- Items is the unit's food.
function AscensionConfig.GetCost(level: number, towerId: string?): any?
	local lv = math.floor(level or 0)
	if lv <= 0 or lv > AscensionConfig.MaxLevel then
		return nil
	end
	local entry = levelsFor(towerId)[lv]
	local c = entry and entry.Cost
	if not c then
		return nil
	end
	local items = {}
	if (c.Food or 0) > 0 then
		table.insert(items, { Id = AscensionConfig.GetFood(towerId), Qty = c.Food })
	end
	return { Dupes = c.Dupes or 1, Items = items }
end

return AscensionConfig
