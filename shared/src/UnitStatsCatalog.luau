--!strict
-- UnitStatsCatalog.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.UnitStatsCatalog)
-- A slim, GENERATED cache of each tower's RESOLVED base stats (DMG/RNG/SPA), so the Lobby can fill
-- the Units screen's number slots WITHOUT pulling the full stat stack (TowerStatResolver +
-- MetaScalingConfig + TraitRegistry + all 8 tower configs) under drift control. See ADR-0003.
--
-- These are what TowerStatResolver PRODUCES at the reference below -- NOT raw BaseStats: SPA is
-- already inverted (lower = faster) and the resolver's ascension/roll handling has been applied.
-- The reference is tier 1, MetaLevel 1, no trait, NO roll (B108: rolls are a global % bonus from
-- StatGradeConfig, so the base is the unrolled stat), ascension 0 -- i.e. a unit's BASE stats. Per-unit level / roll quality / trait / ascension modify these in-match; the Lobby
-- shows the base number here and the grade letters (from the roll alone) beside it.
--
-- B141: regenerated after the starter retune + rarity-ladder pass (docs/proposals/2026-10-13-balance-overhaul.md).
-- !! GENERATED -- do NOT hand-edit the numbers. This is a cache; the truth is the tower configs in
-- the Game place. Whenever a tower's Damage/Range/SPA (or BaseStats) changes, REGENERATE: resolve
-- each tower at REFERENCE and paste the values, then boot the Game place -- the load-bearing
-- validator (`SSS.Server.UnitStatsCatalogValidate`) FAILS LOUDLY if these values no longer match
-- the live configs (a stale cache that lies about damage is worse than showing "--"; ADR-0003).
-- A changed hash is a manifest + PENDING event: the Lobby must redeploy like any shared module.

local UnitStatsCatalog = {}

-- The reference the numbers were generated at (the validator regenerates at exactly this point).
UnitStatsCatalog.REFERENCE = {
	Tier = 1,
	MetaLevel = 1,
	Trait = nil,
	StatRolls = nil, -- B108: base = unrolled (was mid-roll 0.5 against per-tower BaseStats ranges)
	Ascension = 0,
}

-- towerId -> { DMG?, RNG, SPA? }. Support towers (Lakapati) have no DMG/SPA -- those keys are absent.
UnitStatsCatalog.Stats = {
	Handyong    = { DMG = 9, RNG = 18, SPA = 2.4 },
	Bantong     = { DMG = 10, RNG = 12, SPA = 1.7 },
	Oryol       = { DMG = 14, RNG = 18, SPA = 2 },
	Lakapati    = { RNG = 18 },
	Babaylan    = { DMG = 19, RNG = 22, SPA = 2.5 },
	Bulalakaw   = { DMG = 13, RNG = 24, SPA = 1.4 },
	Urduja      = { DMG = 13, RNG = 18, SPA = 1 },
	Magwayen    = { DMG = 15, RNG = 22, SPA = 1.1 },
	Baltog      = { DMG = 8, RNG = 10, SPA = 1.05 },
	Duwende     = { DMG = 6, RNG = 16, SPA = 1 },
	Santelmo    = { DMG = 7, RNG = 20, SPA = 1.6 },
	Mangkukulam = { DMG = 8, RNG = 18, SPA = 1.5 },
	Siyokoy     = { DMG = 18, RNG = 11, SPA = 2 },
	Kapre       = { DMG = 24, RNG = 12, SPA = 2.2 },
	NunoSaPunso = { RNG = 14 },
	Sarimanok   = { DMG = 9, RNG = 20, SPA = 1.5 },
	Mambabarang = { DMG = 13, RNG = 18, SPA = 1.4 },
	Amomongo    = { DMG = 53, RNG = 9, SPA = 2.6 },
	Engkanto      = { DMG = 13, RNG = 20, SPA = 1.5 },
	Sigbin        = { DMG = 15, RNG = 18, SPA = 1.6 },
	LamAng        = { DMG = 49, RNG = 11, SPA = 2.2 },
	BernardoCarpio = { DMG = 65, RNG = 12, SPA = 3.2 },
	MariaMakiling = { DMG = 21, RNG = 18, SPA = 1.6 },
	Minokawa      = { DMG = 17, RNG = 24, SPA = 1.8 },
	Apolaki       = { DMG = 18, RNG = 24, SPA = 1.4 },
	Mayari        = { DMG = 22, RNG = 30, SPA = 2.2 },
	Sidapa        = { DMG = 20, RNG = 20, SPA = 1.3 },
	Tala          = { DMG = 19, RNG = 26, SPA = 1.4 },
	Lalahon       = { DMG = 37, RNG = 20, SPA = 2 },
	Bathala       = { DMG = 32, RNG = 26, SPA = 2 },
	Bakunawa      = { DMG = 43, RNG = 22, SPA = 2.2 },
	Tikbalang     = { DMG = 22, RNG = 11, SPA = 1.9 },
	AmanSinaya    = { DMG = 46, RNG = 14, SPA = 2 },
	Aswang        = { DMG = 62, RNG = 14, SPA = 1.9 },
	Tiyanak       = { DMG = 71, RNG = 13, SPA = 2 },
	Batibat       = { DMG = 50, RNG = 16, SPA = 1.8 },
	Mayari_LunarEclipse = { DMG = 28, RNG = 30, SPA = 2.2 },
	Apolaki_Zenith = { DMG = 23, RNG = 24, SPA = 1.4 },
	Bathala_Ascended = { DMG = 42, RNG = 26, SPA = 2 },
	Bakunawa_Eclipse = { DMG = 56, RNG = 22, SPA = 2.2 },
	Magwayen_Soulferry = { DMG = 20, RNG = 22, SPA = 1.1 },
	Sidapa_LastMeasure = { DMG = 26, RNG = 20, SPA = 1.3 },
	AmanSinaya_Riptide = { DMG = 60, RNG = 14, SPA = 2 },
	Tala_MorningStar = { DMG = 25, RNG = 26, SPA = 1.4 },
	Lalahon_Caldera = { DMG = 48, RNG = 20, SPA = 2 },
	Aswang_BloodMoon = { DMG = 80, RNG = 14, SPA = 1.9 },
	Tiyanak_Changeling = { DMG = 92, RNG = 13, SPA = 2 },
	Batibat_NightTerror = { DMG = 65, RNG = 16, SPA = 1.8 },
}

-- The resolved base stats for a tower, or nil if it is not in the catalog.
function UnitStatsCatalog.Get(towerId: string): { DMG: number?, RNG: number?, SPA: number? }?
	return UnitStatsCatalog.Stats[towerId]
end

-- ===== PLACEMENT COST (B67, user) =====
-- towerId -> what it costs to PLACE this tower, in match Gold.
--
-- WHY IT LIVES HERE. The hotbar is a SHARED controller drawn in BOTH Places, and the requirement is
-- that the price reads THE SAME in the Lobby and the Game at all times. The truth is
-- `TowerConfig.Cost` in the GAME's tower configs, which the Lobby cannot see -- so the only way to
-- be identical in both is ONE shared number, drift-checked by hash like every other shared module
-- and regenerated under the SAME load-bearing validator as the stats above. A remote that pushed
-- the cost from the Game would leave the Lobby with nothing to show before it answered, and the two
-- Places could disagree for as long as the round trip took.
--
-- SAFE TO CACHE BECAUSE PLACEMENT COST IS FLAT. `MetaScalingConfig.Cost` is 1.00 at level 1 AND at
-- level 100 -- its own comment reads "Explicitly flat. Listed rather than omitted so the intent is
-- unmistakable" -- and `PlacementValidator` spends `config.Cost` unmodified. There is no per-unit,
-- per-level or per-trait variation for this cache to miss.
-- ⚠ IF COST EVER STOPS BEING FLAT, THIS CACHE BECOMES A LIE and must be replaced by a resolved
-- lookup, exactly as the stats above would be.
--
-- !! GENERATED, like `Stats`: the truth is the Game's tower configs, NOT this table.
-- `SSS.Server.UnitStatsCatalogValidate` FAILS THE GAME'S BOOT if any value here disagrees with the
-- live `TowerConfig.Cost`, so a stale price cannot ship silently.
UnitStatsCatalog.Costs = {
	Handyong    = 150,
	Bantong     = 150,
	Oryol       = 520,
	Lakapati    = 520,
	Babaylan    = 780,
	Bulalakaw   = 1250,
	Urduja      = 1250,
	Magwayen    = 2000,
	Baltog      = 150,
	Duwende     = 350,
	Santelmo    = 350,
	Mangkukulam = 350,
	Siyokoy     = 350,
	Kapre       = 520,
	NunoSaPunso = 520,
	Sarimanok   = 520,
	Mambabarang = 780,
	Amomongo    = 780,
	Engkanto      = 780,
	Sigbin        = 780,
	LamAng        = 1250,
	BernardoCarpio = 1250,
	MariaMakiling = 1250,
	Minokawa      = 1250,
	Apolaki       = 2000,
	Mayari        = 2000,
	Sidapa        = 2000,
	Tala          = 2400,
	Lalahon       = 2400,
	Bathala       = 4000,
	Bakunawa      = 4000,
	Tikbalang     = 520,
	AmanSinaya    = 2000,
	Aswang        = 3200,
	Tiyanak       = 3200,
	Batibat       = 3200,
	Mayari_LunarEclipse = 2000,
	Apolaki_Zenith = 2000,
	Bathala_Ascended = 4000,
	Bakunawa_Eclipse = 4000,
	Magwayen_Soulferry = 2000,
	Sidapa_LastMeasure = 2000,
	AmanSinaya_Riptide = 2000,
	Tala_MorningStar = 2400,
	Lalahon_Caldera = 2400,
	Aswang_BloodMoon = 3200,
	Tiyanak_Changeling = 3200,
	Batibat_NightTerror = 3200,
}

-- The placement cost for a tower, or nil if it is not in the catalog. Callers HIDE on nil rather
-- than printing a 0 -- a zero is a claim that the tower is free; a hidden label claims nothing.
function UnitStatsCatalog.GetCost(towerId: string): number?
	return UnitStatsCatalog.Costs[towerId]
end

-- ===== PLACEMENT TYPE (B105, user) =====
-- towerId -> WHERE the unit may stand: "Ground" (beside the path), "Hill" (on hill zones) or
-- "Hybrid" (ground zones only, but can hit flying -- B106). Shown as a chip on the hotbar hover card in BOTH Places, so -- like Costs --
-- it has to be one shared number the Lobby can read. The truth is `TowerConfig.Placement` in the
-- Game (read through TowerPlacementRules.PlacementOf, which defaults to "Ground");
-- `SSS.Server.UnitStatsCatalogValidate` FAILS THE GAME'S BOOT if any value here disagrees.
-- !! GENERATED, like `Stats` and `Costs`.
UnitStatsCatalog.Placement = {
	Handyong    = "Ground",
	Bantong     = "Ground",
	Oryol       = "Hill",
	Lakapati    = "Hybrid",
	Babaylan    = "Hybrid",
	Bulalakaw   = "Hill",
	Urduja      = "Ground",
	Magwayen    = "Ground",
	Baltog      = "Ground",
	Duwende     = "Hybrid",
	Santelmo    = "Hill",
	Mangkukulam = "Hybrid",
	Siyokoy     = "Ground",
	Kapre       = "Ground",
	NunoSaPunso = "Ground",
	Sarimanok   = "Hill",
	Mambabarang = "Hill",
	Amomongo    = "Ground",
	Engkanto      = "Hybrid",
	Sigbin        = "Hybrid",
	LamAng        = "Ground",
	BernardoCarpio = "Ground",
	MariaMakiling = "Hybrid",
	Minokawa      = "Hill",
	Apolaki       = "Hill",
	Mayari        = "Hill",
	Sidapa        = "Hybrid",
	Tala          = "Hill",
	Lalahon       = "Hill",
	Bathala       = "Hybrid",
	Bakunawa      = "Hybrid",
	Tikbalang     = "Ground",
	AmanSinaya    = "Ground",
	Aswang        = "Ground",
	Tiyanak       = "Ground",
	Batibat       = "Ground",
	Mayari_LunarEclipse = "Hill",
	Apolaki_Zenith = "Hill",
	Bathala_Ascended = "Hybrid",
	Bakunawa_Eclipse = "Hybrid",
	Magwayen_Soulferry = "Ground",
	Sidapa_LastMeasure = "Hybrid",
	AmanSinaya_Riptide = "Ground",
	Tala_MorningStar = "Hill",
	Lalahon_Caldera = "Hill",
	Aswang_BloodMoon = "Ground",
	Tiyanak_Changeling = "Ground",
	Batibat_NightTerror = "Ground",
}

-- "Ground" | "Hill" | "Hybrid", or nil if the tower is not in the catalog (callers HIDE on nil).
function UnitStatsCatalog.GetPlacement(towerId: string): string?
	return UnitStatsCatalog.Placement[towerId]
end

-- B108: per-tower XP curve multiplier (TowerConfig.XPCurveMultiplier) so the LOBBY can level a unit
-- when it is FED (TowerProgressionConfig.ApplyXP needs it). Validated against the live configs by the
-- Game's UnitStatsCatalogValidate. Missing = 1.0.
UnitStatsCatalog.XPCurve = {
	Handyong             = 1,
	Bantong              = 1.15,
	Oryol                = 1.4,
	Lakapati             = 1,
	Babaylan             = 1.5,
	Bulalakaw            = 1.2,
	Urduja               = 1.15,
	Magwayen             = 1.25,
	Baltog               = 1.1,
	Duwende              = 1.1,
	Santelmo             = 1.2,
	Mangkukulam          = 1.2,
	Siyokoy              = 1.15,
	Kapre                = 1.25,
	NunoSaPunso          = 1.25,
	Sarimanok            = 1.25,
	Mambabarang          = 1.3,
	Amomongo             = 1.3,
	Engkanto             = 1.3,
	Sigbin               = 1.3,
	LamAng               = 1.35,
	BernardoCarpio       = 1.35,
	MariaMakiling        = 1.35,
	Minokawa             = 1.35,
	Apolaki              = 1.4,
	Mayari               = 1.4,
	Sidapa               = 1.4,
	Tala                 = 1.45,
	Lalahon              = 1.45,
	Bathala              = 1.6,
	Bakunawa             = 1.6,
	Tikbalang            = 1.25,
	AmanSinaya           = 1.4,
	Aswang               = 1.5,
	Tiyanak              = 1.5,
	Batibat              = 1.5,
	Mayari_LunarEclipse  = 1.4,
	Apolaki_Zenith       = 1.4,
	Bathala_Ascended     = 1.6,
	Bakunawa_Eclipse     = 1.6,
	Magwayen_Soulferry   = 1.25,
	Sidapa_LastMeasure   = 1.4,
	AmanSinaya_Riptide   = 1.4,
	Tala_MorningStar     = 1.45,
	Lalahon_Caldera      = 1.45,
	Aswang_BloodMoon     = 1.5,
	Tiyanak_Changeling   = 1.5,
	Batibat_NightTerror  = 1.5,
}

function UnitStatsCatalog.GetXPCurve(towerId: string): number
	return UnitStatsCatalog.XPCurve[towerId] or 1.0
end

return UnitStatsCatalog
