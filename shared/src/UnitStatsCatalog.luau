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

-- towerId -> { DMG?, RNG, SPA? }. Support towers (Farm) have no DMG/SPA -- those keys are absent.
UnitStatsCatalog.Stats = {
	Archer      = { DMG = 15, RNG = 20, SPA = 6 },
	Knight      = { DMG = 35, RNG = 10, SPA = 1.4 },
	Mage        = { DMG = 30, RNG = 18, SPA = 2 },
	Farm        = { RNG = 18 },
	Babaylan    = { DMG = 20, RNG = 22, SPA = 2.5 },
	Meteor      = { DMG = 30, RNG = 24, SPA = 1.4 },
	Warchief    = { DMG = 25, RNG = 18, SPA = 1 },
	Necromancer = { DMG = 28, RNG = 22, SPA = 1.1 },
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
	Archer      = 100,
	Knight      = 150,
	Mage        = 200,
	Farm        = 150,
	Babaylan    = 300,
	Meteor      = 300,
	Warchief    = 350,
	Necromancer = 400,
}

-- The placement cost for a tower, or nil if it is not in the catalog. Callers HIDE on nil rather
-- than printing a 0 -- a zero is a claim that the tower is free; a hidden label claims nothing.
function UnitStatsCatalog.GetCost(towerId: string): number?
	return UnitStatsCatalog.Costs[towerId]
end

return UnitStatsCatalog
