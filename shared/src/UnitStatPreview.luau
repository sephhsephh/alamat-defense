--!strict
-- Shared.UnitStatPreview (SHARED CANON, both Places) -- B108 pt11 (user: "display the final calculated stat
-- after calculating the bonuses in trait and stat reroll, level and others" in every unit hover preview).
--
-- The FINAL DMG / SPA / RNG of ONE unit instance, as a card shows it: the unit's placed (tier 1) stats with
-- its level, stat grades, active trait and ascension applied. The SAME composition as
-- TowerStatResolver.Resolve, but over the shared UnitStatsCatalog reference numbers (tier 1, Lv 1, no trait,
-- no roll, A0) instead of the Game-only TowerConfigs -- so the Lobby and the Game print the same number:
--
--   DMG = base.DMG * Meta(Damage, level) * trait.Damage * grade(DMG) * asc(DMG)   (+ trait StatAdds.Damage)
--   RNG = base.RNG * Meta(Range, level)  * trait.Range  * grade(RNG) * asc(RNG)   (+ trait StatAdds.Range)
--   SPA = base.SPA / (Meta(SPA, level)   * trait.SPA    * grade(SPA) * asc(SPA))   (lower = faster)
--
-- Pure: no remotes, no profile reads. `view` is a unit view (GetUnitViews / hotbar entry) or any table with
-- TowerId, Level (or MetaLevel), StatRolls, ActiveTrait (or Trait) and Ascension.

local RS = game:GetService("ReplicatedStorage")
local Configs = RS:WaitForChild("Configs")
local UnitStatsCatalog = require(Configs:WaitForChild("Meta"):WaitForChild("UnitStatsCatalog")) :: any
local StatGradeConfig = require(Configs.Meta:WaitForChild("StatGradeConfig")) :: any
local AscensionConfig = require(Configs.Meta:WaitForChild("AscensionConfig")) :: any
local MetaScalingConfig = require(Configs:WaitForChild("Global"):WaitForChild("MetaScalingConfig")) :: any
local TraitRegistry = require(Configs:WaitForChild("Traits"):WaitForChild("TraitRegistry")) :: any

local UnitStatPreview = {}

-- roll key -> the config stat name the meta curve and trait multipliers use
local CONFIG_NAME = { DMG = "Damage", RNG = "Range", SPA = "SPA" }

local function traitOf(view: any): any
	local id = view.ActiveTrait or view.Trait or view.TraitId
	if type(id) ~= "string" or id == "" then return nil end
	local ok, t = pcall(TraitRegistry.Get, id)
	return if ok then t else nil
end

-- Returns { DMG, SPA, RNG } (a missing stat stays nil -- a support tower has no DMG/SPA), plus
-- `Base` = the same numbers at the reference (so a card can show base -> final).
function UnitStatPreview.Final(view: any): any
	local towerId = view and (view.TowerId or view.UnitId)
	local base = towerId and UnitStatsCatalog.Get(towerId)
	if not base then return { Base = {} } end
	local level = math.max(1, math.floor(tonumber(view.Level) or tonumber(view.MetaLevel) or 1))
	local asc = math.floor(tonumber(view.Ascension) or 0)
	local rolls = type(view.StatRolls) == "table" and view.StatRolls or nil
	local trait = traitOf(view)
	local tMult = (trait and trait.StatMultipliers) or {}
	local tAdd = (trait and trait.StatAdds) or {}

	local out: any = { Base = { DMG = base.DMG, SPA = base.SPA, RNG = base.RNG } }
	for _, key in ipairs({ "DMG", "RNG", "SPA" }) do
		local b = base[key]
		if type(b) == "number" then
			local cfgName = CONFIG_NAME[key]
			local meta = MetaScalingConfig.GetMultiplier(cfgName, level, nil)
			local tm = tonumber(tMult[cfgName]) or 1
			local grade = if rolls and type(rolls[key]) == "number" then StatGradeConfig.Multiplier(key, rolls[key]) else 1
			local am = AscensionConfig.GetMult(key, asc, towerId)
			local v
			if key == "SPA" then
				v = b / (meta * tm * grade * am)
			else
				v = b * meta * tm * grade * am
			end
			local add = tonumber(tAdd[cfgName])
			if add then v += add end
			out[key] = v
		end
	end
	return out
end

-- Display formatting shared by every card (user, B108 pt11: "always round off 1 decimal places"):
-- rounded to ONE decimal, a whole number drops the ".0", thousands get separators
-- (1830 -> "1,830", 68.16 -> "68.2", 1.793 -> "1.8"). nil -> "--" (never "nil").
function UnitStatPreview.Format(n: number?): string
	if type(n) ~= "number" then return "--" end
	local r = math.floor(n * 10 + 0.5) / 10
	local s = if r == math.floor(r) then tostring(math.floor(r)) else string.format("%.1f", r)
	local int, frac = string.match(s, "^(%d+)(.*)$")
	if int and #int > 3 then
		int = (string.reverse(int):gsub("(%d%d%d)", "%1,")):reverse()
		int = (string.gsub(int, "^,", ""))
		s = int .. frac
	end
	return s
end

return UnitStatPreview
