--!strict
-- UnitSort (B108 pt16, Lobby-local) -- THE one order for every list of the player's units.
-- User: "All uis that has something to do with 'Select a unit to ...' make sure its sorted, equipped
-- units first, then favorited, then locked, then by tier" + tie-break pick "Level, then name":
--   equipped > favorited > locked > tier (highest first) > level (highest first) > shiny first > name A-Z
-- (uuid last, so the order never flickers between refreshes).
-- Takes unit VIEWS as GetUnitViews publishes them (Equipped / Favorited / Locked / Tier / Level /
-- Shiny / Name / TowerId / Uuid). Use `UnitSort.compare` directly, or `UnitSort.by(getView)` when a
-- list holds wrappers ({ v = view } / { View = view }).

local RS = game:GetService("ReplicatedStorage")
local TierConfig = require(RS:WaitForChild("Configs"):WaitForChild("Meta"):WaitForChild("TierConfig")) :: any

local UnitSort = {}

local function flag(x: any): number
	return if x == true then 1 else 0
end
local function tierRank(t: any): number
	local ok, n = pcall(TierConfig.GetSortOrder, tostring(t or ""))
	return if ok and type(n) == "number" then n else 0
end

function UnitSort.compare(a: any, b: any): boolean
	if a == nil or b == nil then return a ~= nil end
	local x, y
	x, y = flag(a.Equipped), flag(b.Equipped)
	if x ~= y then return x > y end
	x, y = flag(a.Favorited), flag(b.Favorited)
	if x ~= y then return x > y end
	x, y = flag(a.Locked), flag(b.Locked)
	if x ~= y then return x > y end
	x, y = tierRank(a.Tier), tierRank(b.Tier)
	if x ~= y then return x > y end
	x, y = tonumber(a.Level) or 1, tonumber(b.Level) or 1
	if x ~= y then return x > y end
	x, y = flag(a.Shiny), flag(b.Shiny)
	if x ~= y then return x > y end
	local na, nb = tostring(a.Name or a.TowerId or ""), tostring(b.Name or b.TowerId or "")
	if na ~= nb then return na < nb end
	return tostring(a.Uuid or "") < tostring(b.Uuid or "")
end

-- Comparator for lists of wrappers: UnitSort.by(function(e) return e.v end)
function UnitSort.by(getView: (any) -> any): (any, any) -> boolean
	return function(a, b)
		return UnitSort.compare(getView(a), getView(b))
	end
end

-- Sort a list in place and return it.
function UnitSort.sort(list: { any }, getView: ((any) -> any)?): { any }
	table.sort(list, if getView then UnitSort.by(getView) else UnitSort.compare)
	return list
end

return UnitSort
