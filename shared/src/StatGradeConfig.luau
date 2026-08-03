--!strict
-- StatGradeConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.StatGradeConfig)
-- Maps a 0..1 stat roll to a letter grade (D..Apex). Grades ascend; a roll earns the FIRST
-- grade whose Max it does not exceed. Tune the thresholds freely, but the ORDER
-- (D C B A S SS SSS Apex) is law. Used by the UI to badge a unit's rolls; the resolver reads
-- the raw roll, not the grade.
--
-- SHARED since 2026-08-01 (A-phase Integration promotion) -- byte-identical to the A3 original;
-- the Lobby needs it to grade rolls WITHOUT any tower configs (grades come from the roll alone).

local StatGradeConfig = {}

StatGradeConfig.Grades = {
	{ Name = "D",    Max = 0.40,   Color = Color3.fromRGB(150, 150, 150) },
	{ Name = "C",    Max = 0.65,   Color = Color3.fromRGB(150, 200, 150) },
	{ Name = "B",    Max = 0.82,   Color = Color3.fromRGB(120, 200, 255) },
	{ Name = "A",    Max = 0.92,   Color = Color3.fromRGB(180, 120, 255) },
	{ Name = "S",    Max = 0.975,  Color = Color3.fromRGB(255, 200, 60) },
	{ Name = "SS",   Max = 0.995,  Color = Color3.fromRGB(255, 130, 60) },
	{ Name = "SSS",  Max = 0.9995, Color = Color3.fromRGB(255, 70, 90) },
	{ Name = "Apex", Max = 1.0,    Color = Color3.fromRGB(255, 240, 150) },
}

-- The grade (name, color) a roll earns.
function StatGradeConfig.GradeForRoll(roll: number): (string, Color3)
	local r = math.clamp(roll or 0, 0, 1)
	for _, g in ipairs(StatGradeConfig.Grades) do
		if r <= g.Max then
			return g.Name, g.Color
		end
	end
	local last = StatGradeConfig.Grades[#StatGradeConfig.Grades]
	return last.Name, last.Color
end

-- Roll a fresh stat position in 0..1. Uniform for now; `luck` is reserved for a future
-- luck-multiplier hook (banners / worthiness) and is currently ignored.
function StatGradeConfig.RollStat(rng: Random?, luck: number?): number
	local r = rng or Random.new()
	return r:NextNumber(0, 1)
end

-- Convenience: roll all three unit stats at once.
function StatGradeConfig.RollAll(rng: Random?, luck: number?): { DMG: number, RNG: number, SPA: number }
	return {
		DMG = StatGradeConfig.RollStat(rng, luck),
		RNG = StatGradeConfig.RollStat(rng, luck),
		SPA = StatGradeConfig.RollStat(rng, luck),
	}
end

return StatGradeConfig
