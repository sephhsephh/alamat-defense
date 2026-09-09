--!strict
-- MatchModifiersConfig.lua (Game-local canon, owner AD-Game -- see docs/systems/challenges.md)
-- The registry of MATCH MODIFIERS: opaque string ids (the teleport contract's MatchModifiers: {string})
-- resolved to a small effects table the match flow applies. Modifiers make a match HARDER -- they are
-- the "challenge" in a D2 challenge stage (blueprint Phase D). Added B51 2026-09-04.
--
-- WHERE EACH EFFECT IS APPLIED (all in MatchDirector.buildValidatedMatchState, the ONE place):
--   EnemyHpMult  -> folded into matchState.EnemyHealthScale (every enemy at spawn)
--   LivesMult    -> multiplies the resolved starting lives
--   LivesCap     -> hard cap on the resolved starting lives (a MINIMUM against it)
--   IncomeMult   -> scales in-match cash (kill + wave + wave-start), via EconomyManager.SetIncomeScale [B53]
--   StartingCashMult -> scales the starting cash, via MatchDirector's EconomyManager.InitPlayer call [B53]
--   RangeMult    -> scales every tower's resolved Range, via TowerController.SetStatScales [B56]
--   SpaMult      -> scales every tower's resolved SPA,   via TowerController.SetStatScales [B56]
-- Resolve() folds a list into one effects table; unknown ids are WARNED and skipped -- a modifier that
-- does nothing is safe, because a modifier can only ever REMOVE difficulty, never invent a reward.
--
-- EVERY effect this file names is now APPLIED. The B51 registry deliberately named RangeMult/SpaMult
-- without applying them; B56 built the seam it had predicted (a module-level scale on TowerController
-- folded over self.BaseStats after Resolve, set by MatchDirector exactly like SetHealthScale) and
-- turned them on. The ECONOMY seam went live at B53 (IncomeMult / StartingCashMult), covering the old
-- "NoFarm" intent. See challenges.md.
--
-- ===== SPA IS SECONDS PER ATTACK: BIGGER IS SLOWER =====
-- Modifiers may only ever make a match HARDER. So a range modifier is < 1 (see less) and an SPA
-- modifier is > 1 (attack less often). A `SpaMult` below 1 would be a BUFF and must never ship.

local MatchModifiersConfig = {}

export type Effects = { EnemyHpMult: number, LivesMult: number, LivesCap: number, IncomeMult: number, StartingCashMult: number, RangeMult: number, SpaMult: number }

-- id -> { effect fields..., Label = human string }. Only fields the match flow applies TODAY.
local MODIFIERS: { [string]: any } = {
	EnemyHpX1_5 = { EnemyHpMult = 1.5, Label = "Tough enemies (+50% HP)" },
	EnemyHpX2   = { EnemyHpMult = 2.0, Label = "Brutal enemies (2x HP)" },
	HalfLives   = { LivesMult = 0.5,   Label = "Fragile (half lives)" },
	OneLife     = { LivesCap = 1,      Label = "Sudden death (1 life)" },
	-- B53: economy modifiers (applied in EconomyManager / MatchDirector, see the header).
	Scarcity    = { IncomeMult = 0.5, StartingCashMult = 0.5, Label = "Scarce resources (half economy)" },
	LeanStart   = { StartingCashMult = 0.5, Label = "Lean start (half starting cash)" },
	-- B56: tower-stat modifiers. RangeMult < 1 and SpaMult > 1 are both HARDER (SPA is seconds per
	-- attack). Tuned deliberately mild: range and fire rate are the two stats a player has built
	-- their whole placement plan around, so a heavy hand here does not read as "challenging", it
	-- reads as "my towers are broken".
	ShortSight  = { RangeMult = 0.75, Label = "Short sight (-25% tower range)" },
	SlowHands   = { SpaMult = 1.25,   Label = "Slow hands (+25% attack interval)" },
}

function MatchModifiersConfig.IsKnown(id: string): boolean
	return MODIFIERS[id] ~= nil
end

function MatchModifiersConfig.Label(id: string): string
	local m = MODIFIERS[id]
	return (m and m.Label) or id
end

-- Fold a list of modifier ids into one effects table. Defaults are the IDENTITY (no change), so an
-- empty list resolves to a normal match. EnemyHpMult and LivesMult MULTIPLY across modifiers; LivesCap
-- takes the MINIMUM cap seen. Unknown ids are warned and skipped.
function MatchModifiersConfig.Resolve(list: { string }?): Effects
	local eff: Effects = { EnemyHpMult = 1.0, LivesMult = 1.0, LivesCap = math.huge, IncomeMult = 1.0, StartingCashMult = 1.0, RangeMult = 1.0, SpaMult = 1.0 }
	if type(list) ~= "table" then
		return eff
	end
	for _, id in ipairs(list) do
		local m = MODIFIERS[id]
		if m == nil then
			warn(("[MatchModifiers] unknown modifier %q -- skipped"):format(tostring(id)))
		else
			if m.EnemyHpMult then eff.EnemyHpMult *= m.EnemyHpMult end
			if m.RangeMult then eff.RangeMult *= m.RangeMult end
			if m.SpaMult then eff.SpaMult *= m.SpaMult end
			if m.LivesMult then eff.LivesMult *= m.LivesMult end
			if m.LivesCap then eff.LivesCap = math.min(eff.LivesCap, m.LivesCap) end
			if m.IncomeMult then eff.IncomeMult *= m.IncomeMult end
			if m.StartingCashMult then eff.StartingCashMult *= m.StartingCashMult end
		end
	end
	return eff
end

-- Apply the resolved lives effects to a base starting-lives number. Floored at 1 -- a challenge can
-- make lives scarce but never zero (a 0-life match is unwinnable and would end instantly).
function MatchModifiersConfig.ApplyLives(baseLives: number, eff: Effects): number
	local lives = math.floor(baseLives * eff.LivesMult)
	lives = math.min(lives, eff.LivesCap)
	return math.max(1, lives)
end

-- Human list for logs / a future UI.
function MatchModifiersConfig.Describe(list: { string }?): { string }
	local out = {}
	if type(list) == "table" then
		for _, id in ipairs(list) do
			table.insert(out, MatchModifiersConfig.Label(id))
		end
	end
	return out
end

return MatchModifiersConfig
