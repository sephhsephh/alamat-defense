--!strict
-- TowerProgressionConfig.lua (Shared)
-- The tower LEVELLING curve: how much XP each level costs, and how much XP a tower earns.
--
-- Shared because the match-end screen must draw XP bars and predict level-ups. It's pure
-- math over static config -- the SERVER still owns the actual XP totals and the writes.
--
-- ===== THE CURVE =====
--   XPRequired(level) = BaseXP * (level ^ Exponent) * TowerCurveMultiplier
--
-- Exponent > 1 means later levels cost progressively more -- the standard shape for a 1-100
-- grind. A LINEAR curve would make level 99->100 as cheap as 1->2, and the whole progression
-- would feel flat at the top.
--
-- ===== PER-TOWER SCALING =====
-- TowerCurveMultiplier lets a powerful/rare tower level SLOWER than a common one, so rarity
-- is a real tradeoff rather than a pure upgrade. Set it in each tower's config as
-- `XPCurveMultiplier`. Defaults to 1.0.

local TowerProgressionConfig = {}

TowerProgressionConfig.MaxLevel = 100

TowerProgressionConfig.BaseXP = 100
TowerProgressionConfig.Exponent = 1.55

-- XP needed to go FROM `level` TO `level + 1`.
function TowerProgressionConfig.GetXPForNextLevel(level: number, towerConfig: any?): number
	if level >= TowerProgressionConfig.MaxLevel then
		return math.huge -- already maxed
	end

	local curveMult = (towerConfig and towerConfig.XPCurveMultiplier) or 1.0

	return math.floor(
		TowerProgressionConfig.BaseXP
		* (level ^ TowerProgressionConfig.Exponent)
		* curveMult
	)
end

-- Total XP to get from level 1 all the way to `targetLevel`. Useful for progress displays.
function TowerProgressionConfig.GetTotalXPToLevel(targetLevel: number, towerConfig: any?): number
	local total = 0
	for lvl = 1, math.min(targetLevel, TowerProgressionConfig.MaxLevel) - 1 do
		total += TowerProgressionConfig.GetXPForNextLevel(lvl, towerConfig)
	end
	return total
end

-- Applies `xpGained` to a tower and rolls it forward through as many levels as it earns.
-- Pure function: returns the RESULT rather than mutating anything, so the client can preview
-- the same computation the server will perform.
--
-- Returns: newLevel, newXP (XP carried into the new level), levelsGained, xpForNext
function TowerProgressionConfig.ApplyXP(
	currentLevel: number, currentXP: number, xpGained: number, towerConfig: any?
): (number, number, number, number)

	local level = math.clamp(currentLevel, 1, TowerProgressionConfig.MaxLevel)
	local xp = currentXP + xpGained
	local levelsGained = 0

	while level < TowerProgressionConfig.MaxLevel do
		local needed = TowerProgressionConfig.GetXPForNextLevel(level, towerConfig)
		if xp < needed then
			break
		end
		-- Carry the OVERFLOW into the next level rather than discarding it. Throwing away
		-- excess XP on level-up quietly punishes players for big single-match hauls.
		xp -= needed
		level += 1
		levelsGained += 1
	end

	-- B122 (user): a MAXED unit BANKS its XP instead of discarding it. The XP stays on the unit and the
	-- loop above spends it automatically the day MaxLevel rises. At max, xpForNext is math.huge, so a
	-- display must show "MAX", never xp / xpForNext.

	local xpForNext = TowerProgressionConfig.GetXPForNextLevel(level, towerConfig)
	return level, xp, levelsGained, xpForNext
end

-- How much XP a tower earned this match, from the stage's TowerXP block.
function TowerProgressionConfig.CalculateEarnedXP(
	stageConfig: any, outcome: string, damageDealt: number, kills: number
): number
	local rules = stageConfig.TowerXP
	if not rules then
		return 0
	end

	local base = (outcome == "Victory") and rules.BaseOnVictory or rules.BaseOnDefeat

	local fromDamage = damageDealt * (rules.PerDamage or 0)
	local fromKills = kills * (rules.PerKill or 0)

	return math.floor(base + fromDamage + fromKills)
end

return TowerProgressionConfig
