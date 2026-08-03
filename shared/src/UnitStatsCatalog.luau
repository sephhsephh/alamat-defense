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

return UnitStatsCatalog
