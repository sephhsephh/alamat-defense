--!strict
-- UnitStatsCatalog.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.UnitStatsCatalog)
-- A slim, GENERATED cache of each tower's RESOLVED base stats (DMG/RNG/SPA), so the Lobby can fill
-- the Units screen's number slots WITHOUT pulling the full stat stack (TowerStatResolver +
-- MetaScalingConfig + TraitRegistry + all 8 tower configs) under drift control. See ADR-0003.
--
-- These are what TowerStatResolver PRODUCES at the reference below -- NOT raw BaseStats: SPA is
-- already inverted (lower = faster) and the resolver's ascension/roll handling has been applied.
-- The reference is tier 1, MetaLevel 1, no trait, MID roll (0.5), ascension 0 -- i.e. a unit's
-- BASE stats. Per-unit level / roll quality / trait / ascension modify these in-match; the Lobby
-- shows the base number here and the grade letters (from the roll alone) beside it.
--
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
	StatRolls = { DMG = 0.5, RNG = 0.5, SPA = 0.5 },
	Ascension = 0,
}

-- towerId -> { DMG?, RNG, SPA? }. Support towers (Lakapati) have no DMG/SPA -- those keys are absent.
UnitStatsCatalog.Stats = {
	Handyong    = { DMG = 15, RNG = 20, SPA = 6 },
	Bantong     = { DMG = 35, RNG = 10, SPA = 1.4 },
	Oryol       = { DMG = 30, RNG = 18, SPA = 2 },
	Lakapati    = { RNG = 18 },
	Babaylan    = { DMG = 20, RNG = 22, SPA = 2.5 },
	Bulalakaw   = { DMG = 30, RNG = 24, SPA = 1.4 },
	Urduja      = { DMG = 25, RNG = 18, SPA = 1 },
	Magwayen    = { DMG = 28, RNG = 22, SPA = 1.1 },
	Baltog      = { DMG = 30, RNG = 9, SPA = 4.5 },
	Duwende     = { DMG = 8, RNG = 16, SPA = 1 },
	Santelmo    = { DMG = 16, RNG = 20, SPA = 1.6 },
	Mangkukulam = { DMG = 10, RNG = 18, SPA = 1.5 },
	Siyokoy     = { DMG = 20, RNG = 11, SPA = 2 },
	Kapre       = { DMG = 28, RNG = 12, SPA = 2.2 },
	NunoSaPunso = { RNG = 14 },
	Sarimanok   = { DMG = 12, RNG = 20, SPA = 1.5 },
	Mambabarang = { DMG = 24, RNG = 18, SPA = 1.4 },
	Amomongo    = { DMG = 40, RNG = 9, SPA = 2.6 },
	Engkanto      = { DMG = 26, RNG = 20, SPA = 1.5 },
	Sigbin        = { DMG = 30, RNG = 18, SPA = 1.6 },
	LamAng        = { DMG = 45, RNG = 11, SPA = 2.2 },
	BernardoCarpio = { DMG = 60, RNG = 12, SPA = 3.2 },
	MariaMakiling = { DMG = 15, RNG = 18, SPA = 1.6 },
	Minokawa      = { DMG = 36, RNG = 24, SPA = 1.8 },
	Apolaki       = { DMG = 45, RNG = 24, SPA = 1.4 },
	Mayari        = { DMG = 60, RNG = 30, SPA = 2.2 },
	Sidapa        = { DMG = 45, RNG = 20, SPA = 1.3 },
	Tala          = { DMG = 50, RNG = 26, SPA = 1.4 },
	Lalahon       = { DMG = 50, RNG = 20, SPA = 2 },
	Bathala       = { DMG = 70, RNG = 26, SPA = 2 },
	Bakunawa      = { DMG = 110, RNG = 22, SPA = 2.2 },
	Tikbalang     = { DMG = 30, RNG = 11, SPA = 1.9 },
	AmanSinaya    = { DMG = 70, RNG = 14, SPA = 2 },
	Aswang        = { DMG = 60, RNG = 14, SPA = 1.9 },
	Tiyanak       = { DMG = 70, RNG = 13, SPA = 2 },
	Batibat       = { DMG = 55, RNG = 16, SPA = 1.8 },
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
	Handyong    = 100,
	Bantong     = 150,
	Oryol       = 200,
	Lakapati    = 150,
	Babaylan    = 300,
	Bulalakaw   = 300,
	Urduja      = 350,
	Magwayen    = 400,
	Baltog      = 125,
	Duwende     = 175,
	Santelmo    = 200,
	Mangkukulam = 175,
	Siyokoy     = 175,
	Kapre       = 250,
	NunoSaPunso = 225,
	Sarimanok   = 250,
	Mambabarang = 325,
	Amomongo    = 300,
	Engkanto      = 300,
	Sigbin        = 300,
	LamAng        = 375,
	BernardoCarpio = 400,
	MariaMakiling = 350,
	Minokawa      = 400,
	Apolaki       = 450,
	Mayari        = 450,
	Sidapa        = 475,
	Tala          = 500,
	Lalahon       = 525,
	Bathala       = 700,
	Bakunawa      = 750,
	Tikbalang     = 250,
	AmanSinaya    = 475,
	Aswang        = 550,
	Tiyanak       = 525,
	Batibat       = 575,
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
	Handyong    = "Hybrid",
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
}

-- "Ground" | "Hill" | "Hybrid", or nil if the tower is not in the catalog (callers HIDE on nil).
function UnitStatsCatalog.GetPlacement(towerId: string): string?
	return UnitStatsCatalog.Placement[towerId]
end

return UnitStatsCatalog
