--!strict
-- StatGradeConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.StatGradeConfig)
-- THE one authority for a unit's stat grades: letter, colour, chance, and the % bonus a roll gives.
--
-- B108 (user-approved model): eight grades, D C B A S Z Z+ AL ("AL" = Alamat, the top grade).
-- A stored roll is still a raw 0..1 number (UnitInstance.StatRolls, unchanged -- NO migration):
-- it is read as a QUANTILE. The grade bands below are cumulative `Chance`s, so a uniform roll
-- lands in D 40% of the time, ... AL 0.1%. Inside its band the roll is interpolated linearly
-- across that grade's % range, so a higher roll is always a (weakly) better stat.
--
-- The bonus is GLOBAL (user, B108: "Global %, replace ranges"): the same grade gives the same %
-- on every unit. Per-tower BaseStats ranges are no longer read by the resolver.
--   DMG x(1 + p)   RNG x(1 + p)   SPA x(1 - p)  (faster; returned as a STRENGTH 1/(1-p) so the
--   resolver's inverted-SPA division yields base*(1-p), the trait convention).
--
-- SHARED since 2026-08-01 -- the Lobby grades rolls without any tower configs.

local StatGradeConfig = {}

StatGradeConfig.STATS = { "DMG", "RNG", "SPA" }

-- Ascending. Chance in percent (sums to 100). Pct = { lo, hi } in PERCENT for each stat.
StatGradeConfig.Grades = {
	{ Name = "D",  Chance = 40,   Color = Color3.fromRGB(150, 150, 150), Pct = { DMG = { 0, 4.99 },  RNG = { 0, 2.49 },    SPA = { 0, 2.49 } } },
	{ Name = "C",  Chance = 30,   Color = Color3.fromRGB(150, 200, 150), Pct = { DMG = { 5, 7.99 },  RNG = { 2.5, 3.99 },  SPA = { 2.5, 3.99 } } },
	{ Name = "B",  Chance = 23.5, Color = Color3.fromRGB(120, 200, 255), Pct = { DMG = { 8, 10.99 }, RNG = { 4, 5.49 },    SPA = { 4, 5.49 } } },
	{ Name = "A",  Chance = 4.35, Color = Color3.fromRGB(180, 120, 255), Pct = { DMG = { 11, 13.99 }, RNG = { 5.5, 6.99 }, SPA = { 5.5, 6.99 } } },
	{ Name = "S",  Chance = 1,    Color = Color3.fromRGB(255, 200, 60),  Pct = { DMG = { 14, 16.99 }, RNG = { 7, 8.49 },   SPA = { 7, 8.49 } } },
	{ Name = "Z",  Chance = 0.85, Color = Color3.fromRGB(255, 130, 60),  Pct = { DMG = { 17, 19.99 }, RNG = { 8.5, 9.99 }, SPA = { 8.5, 9.99 } } },
	{ Name = "Z+", Chance = 0.2,  Color = Color3.fromRGB(255, 70, 90),   Pct = { DMG = { 20, 22.99 }, RNG = { 10, 11.49 }, SPA = { 10, 11.49 } } },
	{ Name = "AL", Chance = 0.1,  Color = Color3.fromRGB(255, 240, 150), Pct = { DMG = { 23, 25 },    RNG = { 11.5, 12.5 }, SPA = { 11.5, 12.5 } } },
}

-- Derived: cumulative quantile bands. Min (exclusive except for D) .. Max (inclusive).
do
	local acc = 0
	for i, g in ipairs(StatGradeConfig.Grades) do
		local row: any = g
		row.Min = acc / 100
		acc += row.Chance
		row.Max = if i == #StatGradeConfig.Grades then 1.0 else acc / 100
		row.Index = i
	end
end

local byName: { [string]: any } = {}
for _, g in ipairs(StatGradeConfig.Grades) do byName[g.Name] = g end

function StatGradeConfig.GetGrade(name: string): any?
	return byName[name]
end
function StatGradeConfig.GradeIndex(name: string): number
	local g = byName[name]
	return g and g.Index or 0
end

local function gradeRow(roll: number): any
	local r = math.clamp(roll or 0, 0, 1)
	for _, g in ipairs(StatGradeConfig.Grades) do
		if r <= (g :: any).Max then return g end
	end
	return StatGradeConfig.Grades[#StatGradeConfig.Grades]
end

-- The grade (name, color) a roll earns.
function StatGradeConfig.GradeForRoll(roll: number): (string, Color3)
	local g = gradeRow(roll)
	return g.Name, g.Color
end

-- The % bonus (e.g. 12.34 = +12.34%) a roll gives for a stat ("DMG"/"RNG"/"SPA").
function StatGradeConfig.PercentForRoll(stat: string, roll: number): number
	local g = gradeRow(roll)
	local range = g.Pct[stat] or g.Pct.DMG
	local span = (g :: any).Max - (g :: any).Min
	local t = if span > 0 then math.clamp((math.clamp(roll or 0, 0, 1) - (g :: any).Min) / span, 0, 1) else 1
	return range[1] + (range[2] - range[1]) * t
end

-- The roll (0..1) that gives exactly `pct` for a stat, or nil if no grade covers it. Used by
-- filters ("at least X%") so the server compares rolls, never floats of floats.
function StatGradeConfig.RollForPercent(stat: string, pct: number): number?
	for _, g in ipairs(StatGradeConfig.Grades) do
		local range = g.Pct[stat] or g.Pct.DMG
		if pct <= range[2] then
			local t = if range[2] > range[1] then math.clamp((pct - range[1]) / (range[2] - range[1]), 0, 1) else 0
			return (g :: any).Min + ((g :: any).Max - (g :: any).Min) * t
		end
	end
	return nil
end

-- The STRENGTH multiplier the resolver folds in ("higher = stronger"; SPA is divided by it).
function StatGradeConfig.Multiplier(stat: string, roll: number): number
	local p = StatGradeConfig.PercentForRoll(stat, roll) / 100
	if stat == "SPA" then
		return 1 / (1 - p)
	end
	return 1 + p
end

-- Roll a fresh stat position in 0..1. Uniform: the grade bands carry the odds. `luck` is
-- reserved for a future luck hook and is currently ignored.
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
