--!strict
-- TraitDefinitions.lua
-- Traits: permanent per-tower modifiers earned via Lobby reroll gacha. One per tower.
-- See architecture doc section 15.
--
-- Two distinct kinds of effect, deliberately separated:
--   StatMultipliers        -- pure numbers, fed into TowerStatResolver's third layer
--   PlacementLimitOverride -- a NON-stat property; this is why traits can't just be a
--                             multiplier table (Godly makes a tower stronger but rarer)
--
-- Multipliers are expressed as FINAL multipliers, not percentages:
--   "+300% damage" = 4.0   (original 100% + 300% more)
--   "+100% attack speed" = 2.0
--   "+50% range" = 1.5
--
-- SPA (Seconds Per Attack) is INVERTED in TowerStatResolver (stored as seconds-between-attacks),
-- so an SPA multiplier of 2.0 correctly means "attacks twice as fast," not "twice the delay."
-- (Note the real floor is the attack animation length -- Blitz can't push cadence below it.)

local TraitDefinitions = {

	None = {
		Id = "None",
		DisplayName = "None",
		Rarity = "Common",
		Weight = 1000, -- reroll weight; overwhelmingly the default outcome
		StatMultipliers = {},
	},

	Blitz = {
		Id = "Blitz",
		DisplayName = "Blitz",
		Rarity = "Rare",
		Weight = 80,
		Description = "+100% attack speed.",
		StatMultipliers = {
			SPA = 2.0,
		},
	},

	Sniper = {
		Id = "Sniper",
		DisplayName = "Sniper",
		Rarity = "Rare",
		Weight = 80,
		Description = "+80% range, +25% damage, but -20% attack speed.",
		StatMultipliers = {
			Range = 1.8,
			Damage = 1.25,
			SPA = 0.8,
		},
	},

	Deadeye = {
		Id = "Deadeye",
		DisplayName = "Deadeye",
		Rarity = "Epic",
		Weight = 25,
		Description = "+150% crit chance, +50% crit damage.",
		StatMultipliers = {
			CritChance = 2.5,
			CritMultiplier = 1.5,
		},
	},

	Godly = {
		Id = "Godly",
		DisplayName = "Godly",
		Rarity = "Legendary",
		Weight = 3,
		Description = "+300% damage, +50% range, +100% crit chance -- but you may only place ONE.",
		StatMultipliers = {
			Damage = 4.0,
			Range = 1.5,
			CritChance = 2.0,
		},
		-- The defining trade-off: massive power, but this tower's placement limit becomes 1
		-- regardless of what TowerConfig.PlacementLimit says.
		PlacementLimitOverride = 1,
	},
}

return TraitDefinitions
