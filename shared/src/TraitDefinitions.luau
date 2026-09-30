--!strict
-- TraitDefinitions.lua (SHARED CANON)
-- Traits: permanent per-unit modifiers earned via the Lobby's trait reroll (and, rarely, on summon).
--
-- ===== B108: THE TRAIT SET WAS REPLACED (user-approved) =====
-- Our own 11 traits (three of them RANKED I/II/III), modelled on a reference list but with our own
-- names and shifted numbers. The four B12-era traits map onto them through `TraitRegistry.LEGACY`
-- (Blitz -> Tempest, Sniper -> Hawkeye, Deadeye -> Sharpshot, Godly -> Anointed), so a unit that still
-- stores an old id reads as its new trait everywhere, and the Lobby rewrites stored ids on load.
--
-- ===== WEIGHT =====
-- Rerollable weights are in HUNDREDTHS OF A PERCENT and sum to 10,000, so `Weight / 100` IS the
-- percent the Trait Index shows (Might I = 1560 -> 15.6%). A ranked family rolls Rank I 60% / II 30%
-- / III 10% of its share (Might 26% -> 15.6 / 7.8 / 2.6).
-- `None` is only used by the full-table `TraitRegistry.Roll` (trait-on-summon). Its weight keeps a
-- summon's trait chance where it was before B108: 10000 / (10000 + 53191) = 15.8% (was 188/1188).
--
-- ===== EFFECT FIELDS (every one optional) =====
--   StatMultipliers  FINAL multipliers fed into TowerStatResolver's trait layer. SPA is INVERTED there
--                    (stored as seconds between attacks), so "-20% SPA" is written `1 / 0.8`.
--   StatAdds         ADDED after multipliers: CritChance +0.40 = +40 percentage points of crit.
--   XPMult           unit XP earned from a match (RewardCalculator).
--   CashMult         cash from enemies THIS unit kills (MatchDirector -> EconomyManager).
--   UpgradeCostMult  in-match upgrade cost of a NON-support unit (TowerController:GetStepCost).
--   IncomeMult       a support unit's IncomePerWave (TowerStatResolver).
--   PlacementLimitOverride  a NON-stat property: the unit may only be placed this many times.
--   PityCap          guaranteed on the Nth consecutive reroll of a unit that has not landed it (per
--                    unit, per trait -- `UnitInstance.TraitPity`). Only the top three have one; those
--                    are also the "good" traits that play the special reveal. PLACEHOLDERS, ~1.5x the
--                    expected rolls; the user's call.
--   Family / Rank    ranked traits (Might/Keen/Hasty). Display only; each rank is its own id.
--   Icon             `rbxassetid://...`; EMPTY = the UI shows the name in the Rarity colour instead.
--   Rarity           a TierConfig tier name, used for the trait's COLOUR only.

local function spa(pctFaster: number): number
	-- "-X% SPA" (seconds between attacks shrink by X%) as the resolver's inverted multiplier.
	return 1 / (1 - pctFaster)
end

local TraitDefinitions: { [string]: any } = {

	None = {
		Id = "None",
		DisplayName = "None",
		Rarity = "Common",
		Weight = 53191, -- full-table Roll (summon) only; rerolls NEVER land None (B73)
		StatMultipliers = {},
	},

	-- ===== RANKED (26% each family) =====
	Might1 = { Id = "Might1", DisplayName = "Might I", Family = "Might", Rank = 1, Rarity = "Common", Weight = 1560, Icon = "rbxassetid://128848080905727",
		Description = "+5% Damage.", StatMultipliers = { Damage = 1.05 } },
	Might2 = { Id = "Might2", DisplayName = "Might II", Family = "Might", Rank = 2, Rarity = "Uncommon", Weight = 780, Icon = "rbxassetid://128848080905727",
		Description = "+9% Damage.", StatMultipliers = { Damage = 1.09 } },
	Might3 = { Id = "Might3", DisplayName = "Might III", Family = "Might", Rank = 3, Rarity = "Rare", Weight = 260, Icon = "rbxassetid://128848080905727",
		Description = "+14% Damage.", StatMultipliers = { Damage = 1.14 } },

	Keen1 = { Id = "Keen1", DisplayName = "Keen I", Family = "Keen", Rank = 1, Rarity = "Common", Weight = 1560, Icon = "rbxassetid://85244356889755",
		Description = "+5% Range.", StatMultipliers = { Range = 1.05 } },
	Keen2 = { Id = "Keen2", DisplayName = "Keen II", Family = "Keen", Rank = 2, Rarity = "Uncommon", Weight = 780, Icon = "rbxassetid://85244356889755",
		Description = "+9% Range.", StatMultipliers = { Range = 1.09 } },
	Keen3 = { Id = "Keen3", DisplayName = "Keen III", Family = "Keen", Rank = 3, Rarity = "Rare", Weight = 260, Icon = "rbxassetid://85244356889755",
		Description = "+14% Range.", StatMultipliers = { Range = 1.14 } },

	Hasty1 = { Id = "Hasty1", DisplayName = "Hasty I", Family = "Hasty", Rank = 1, Rarity = "Common", Weight = 1560, Icon = "rbxassetid://72795334642359",
		Description = "-5% SPA (attacks faster).", StatMultipliers = { SPA = spa(0.05) } },
	Hasty2 = { Id = "Hasty2", DisplayName = "Hasty II", Family = "Hasty", Rank = 2, Rarity = "Uncommon", Weight = 780, Icon = "rbxassetid://72795334642359",
		Description = "-8% SPA (attacks faster).", StatMultipliers = { SPA = spa(0.08) } },
	Hasty3 = { Id = "Hasty3", DisplayName = "Hasty III", Family = "Hasty", Rank = 3, Rarity = "Rare", Weight = 260, Icon = "rbxassetid://72795334642359",
		Description = "-12% SPA (attacks faster).", StatMultipliers = { SPA = spa(0.12) } },

	-- ===== SINGLE TRAITS =====
	Sage = { Id = "Sage", DisplayName = "Sage", Rarity = "Rare", Weight = 1000, Icon = "rbxassetid://76191901925331",
		Description = "+50% unit XP from matches.", StatMultipliers = {}, XPMult = 1.5 },

	Hawkeye = { Id = "Hawkeye", DisplayName = "Hawkeye", Rarity = "Epic", Weight = 650, Icon = "rbxassetid://134004064855692",
		Description = "+30% Range, +5% crit chance.", StatMultipliers = { Range = 1.3 }, StatAdds = { CritChance = 0.05 } },

	Bountiful = { Id = "Bountiful", DisplayName = "Bountiful", Rarity = "Epic", Weight = 250, Icon = "rbxassetid://73887426996333",
		Description = "+20% cash from this unit's kills and -10% upgrade cost. Farms: +15% income instead.",
		StatMultipliers = {}, CashMult = 1.2, UpgradeCostMult = 0.9, IncomeMult = 1.15 },

	Tempest = { Id = "Tempest", DisplayName = "Tempest", Rarity = "Legendary", Weight = 185, Icon = "rbxassetid://105162859618337",
		Description = "-20% SPA (attacks much faster).", StatMultipliers = { SPA = spa(0.20) } },

	Anito = { Id = "Anito", DisplayName = "Anito", Rarity = "Mythic", Weight = 50, Icon = "rbxassetid://91779879828312",
		Description = "+12% Damage, -5% SPA, +15% Range.",
		StatMultipliers = { Damage = 1.12, SPA = spa(0.05), Range = 1.15 } },

	Sharpshot = { Id = "Sharpshot", DisplayName = "Sharpshot", Rarity = "Mythic", Weight = 37.5, PityCap = 400, Icon = "rbxassetid://139698554665612",
		Description = "+40% crit chance, +50% crit damage.",
		StatMultipliers = {}, StatAdds = { CritChance = 0.40, CritMultiplier = 0.5 } },

	Diwata = { Id = "Diwata", DisplayName = "Diwata", Rarity = "Secret", Weight = 17.5, PityCap = 850, Icon = "rbxassetid://83505277431419",
		Description = "+20% Damage, -18% SPA, +8% Range.",
		StatMultipliers = { Damage = 1.2, SPA = spa(0.18), Range = 1.08 } },

	Anointed = { Id = "Anointed", DisplayName = "Anointed", Rarity = "Alamat", Weight = 10, PityCap = 1500, Icon = "rbxassetid://115489031932695",
		Description = "+250% Damage, -10% SPA, +10% Range -- but you may only place ONE.",
		StatMultipliers = { Damage = 3.5, SPA = spa(0.10), Range = 1.1 },
		-- The defining trade-off (as Godly before it): massive power, but this unit's placement limit
		-- becomes 1 regardless of what its TowerConfig says.
		PlacementLimitOverride = 1 },
}

return TraitDefinitions
