--!strict
-- MetaScalingConfig.lua
-- How a tower's LOBBY meta level (1-100) scales its stats at EVERY in-match upgrade tier.
-- See architecture doc section 14.
--
-- Deliberately a sparse keyframe curve + interpolation, NOT 100 hand-authored rows per
-- tower -- that would be unmaintainable and miserable to rebalance. Tune the anchors here.
--
-- Per-stat rules matter a lot:
--   * Damage scales meaningfully -- this is the main progression reward.
--   * SPA (attack speed) scales gently. It MULTIPLIES with damage, so scaling both aggressively
--     compounds into a far steeper power curve than the numbers suggest at a glance.
--     (Real cadence is floored by the attack animation length -- see TowerStatResolver.)
--   * Range scales barely (or not at all). Range creep breaks map/path balance much faster
--     than damage creep does -- a longer-range tower covers more of the path, which is a
--     bigger deal than it hitting harder.
--   * Cost does NOT scale. A maxed player should not be punished for their progression.

local MetaScalingConfig = {}

-- Keyframes: metaLevel -> multiplier. Levels between anchors are linearly interpolated.
-- Level 1 is always 1.0 (baseline); level 100 is the max-progression payoff.
local CURVES: { [string]: { { Level: number, Multiplier: number } } } = {
	Damage = {
		{ Level = 1,   Multiplier = 1.00 },
		{ Level = 25,  Multiplier = 1.60 },
		{ Level = 50,  Multiplier = 2.40 },
		{ Level = 75,  Multiplier = 3.30 },
		{ Level = 100, Multiplier = 4.50 },
	},
	SPA = {
		-- Multiplier here means "attacks faster by this factor" -- applied as a DIVISOR on
		-- the cooldown, so 1.25 = 25% faster. Kept gentle on purpose (see note above).
		{ Level = 1,   Multiplier = 1.00 },
		{ Level = 50,  Multiplier = 1.12 },
		{ Level = 100, Multiplier = 1.25 },
	},
	Range = {
		-- Almost flat by design. 10% at max level is a nice-to-have, not a power spike.
		{ Level = 1,   Multiplier = 1.00 },
		{ Level = 100, Multiplier = 1.10 },
	},
	Cost = {
		-- Explicitly flat. Listed rather than omitted so the intent is unmistakable.
		{ Level = 1,   Multiplier = 1.00 },
		{ Level = 100, Multiplier = 1.00 },
	},
}

-- Stats with no curve defined are left unscaled (multiplier 1.0).
local function interpolate(curve: { { Level: number, Multiplier: number } }, level: number): number
	if #curve == 0 then
		return 1.0
	end

	if level <= curve[1].Level then
		return curve[1].Multiplier
	end
	if level >= curve[#curve].Level then
		return curve[#curve].Multiplier
	end

	for i = 1, #curve - 1 do
		local a = curve[i]
		local b = curve[i + 1]
		if level >= a.Level and level <= b.Level then
			local span = b.Level - a.Level
			if span == 0 then
				return a.Multiplier
			end
			local alpha = (level - a.Level) / span
			return a.Multiplier + (b.Multiplier - a.Multiplier) * alpha
		end
	end

	return 1.0
end

-- Returns the multiplier for a single stat at a given meta level.
-- towerConfig may optionally provide MetaScalingOverride = { Damage = {...} } to override
-- the global curve for that tower only.
function MetaScalingConfig.GetMultiplier(statName: string, metaLevel: number, towerConfig: any?): number
	local curve = nil

	if towerConfig and towerConfig.MetaScalingOverride then
		curve = towerConfig.MetaScalingOverride[statName]
	end
	if not curve then
		curve = CURVES[statName]
	end
	if not curve then
		return 1.0 -- unscaled stat
	end

	return interpolate(curve, metaLevel)
end

MetaScalingConfig.Curves = CURVES

return MetaScalingConfig
