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
--
-- ===== PityCap (B69) -- ONLY on the top two rarities =====
-- A trait with a `PityCap` is GUARANTEED on the Nth consecutive reroll of a unit that has not landed
-- it. The counter is PER UNIT INSTANCE and per trait (`UnitInstance.TraitPity`), so grinding one
-- tower never advances another's, and it RESETS to 0 the moment that trait lands -- pitied or not.
--
-- It lives HERE, beside `Weight`, because this file is already the single definition of trait rarity
-- (see TraitRegistry's header): a cap stored anywhere else could drift from the weight it exists to
-- compensate for, and the two only make sense read together.
--
-- *** THESE TWO NUMBERS ARE PLACEHOLDERS AND ARE THE USER'S CALL. ***
-- Set at B69 as ~1.5x the expected rolls when "None" was still in the reroll pool (1188 weight).
-- B73 (user): a reroll ALWAYS lands a trait now, so the pool is 188 and the odds are
--   Deadeye  25/188 = 13.3%  -> ~7.5 rolls expected   (cap 75 kept)
--   Godly     3/188 = 1.60%  -> ~63 rolls expected    (cap 600 kept)
-- The caps were KEPT on purpose (user, B73: "i will be adding more traits in the future") -- every new
-- trait dilutes these odds, so the caps are left for the user to retune once the table is final.
-- Retune by editing the one number; nothing else changes. A longer cap makes the trait rarer in
-- PRACTICE without touching Weight (which would also move the odds shown on the Trait Index).
-- Blitz and Sniper deliberately have NO cap: they are the common outcomes, and a pity bar on a common
-- outcome is noise.
--
-- ===== Weight and "None" (B73) =====
-- `None` keeps its entry (it is what an un-traited unit HAS) but is EXCLUDED from rerolls -- see
-- TraitRegistry.RollReroll. Its Weight only matters to the legacy full-table `Roll`.
--
-- ===== Icon (B73) =====
-- The trait's logo, shown by the special "good trait" reveal and the Trait Index. Paste an
-- `rbxassetid://...` here. EMPTY = no logo yet: the UI shows the trait NAME in its rarity colour
-- instead, so an empty Icon is never a broken screen.
-- "Good" traits (the special reveal) are exactly the ones with a PityCap.

local TraitDefinitions = {

	None = {
		Id = "None",
		DisplayName = "None",
		Rarity = "Common",
		Weight = 1000, -- legacy full-table Roll only; rerolls NEVER land None (B73)
		StatMultipliers = {},
	},

	Blitz = {
		Id = "Blitz",
		DisplayName = "Blitz",
		Rarity = "Rare",
		Weight = 80,
		Icon = "", -- B73: paste a logo asset id
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
		Icon = "", -- B73: paste a logo asset id
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
		PityCap = 75,   -- PLACEHOLDER (B69, user's call); ~7.5 rolls expected since B73 (25/188)
		Icon = "", -- B73: paste a logo asset id (special reveal shows the name until then)
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
		PityCap = 600,  -- PLACEHOLDER (B69, user's call); ~63 rolls expected since B73 (3/188)
		Icon = "", -- B73: paste a logo asset id (special reveal shows the name until then)
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
