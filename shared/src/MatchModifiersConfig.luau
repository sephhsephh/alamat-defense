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
-- Resolve() folds a list into one effects table; unknown ids are WARNED and skipped -- a modifier that
-- does nothing is safe, because a modifier can only ever REMOVE difficulty, never invent a reward.
--
-- NOT-YET-APPLIED (named for the roadmap, deliberately absent from every live modifier so nothing
-- silently claims to do something it doesn't): RangeMult / SpaMult (need a tower-stat seam) and
-- NoFarm (needs an EconomyManager seam). Add one here AND at its seam together -- see challenges.md.

local MatchModifiersConfig = {}

export type Effects = { EnemyHpMult: number, LivesMult: number, LivesCap: number }

-- id -> { effect fields..., Label = human string }. Only fields the match flow applies TODAY.
local MODIFIERS: { [string]: any } = {
	EnemyHpX1_5 = { EnemyHpMult = 1.5, Label = "Tough enemies (+50% HP)" },
	EnemyHpX2   = { EnemyHpMult = 2.0, Label = "Brutal enemies (2x HP)" },
	HalfLives   = { LivesMult = 0.5,   Label = "Fragile (half lives)" },
	OneLife     = { LivesCap = 1,      Label = "Sudden death (1 life)" },
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
	local eff: Effects = { EnemyHpMult = 1.0, LivesMult = 1.0, LivesCap = math.huge }
	if type(list) ~= "table" then
		return eff
	end
	for _, id in ipairs(list) do
		local m = MODIFIERS[id]
		if m == nil then
			warn(("[MatchModifiers] unknown modifier %q -- skipped"):format(tostring(id)))
		else
			if m.EnemyHpMult then eff.EnemyHpMult *= m.EnemyHpMult end
			if m.LivesMult then eff.LivesMult *= m.LivesMult end
			if m.LivesCap then eff.LivesCap = math.min(eff.LivesCap, m.LivesCap) end
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
