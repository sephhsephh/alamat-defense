-- tools/unit_info_gen.luau (B154) -- run with execute_luau in the GAME (Edit). Regenerates the `D.<TowerId>=...` rows
-- of the shared UnitInfoCatalog from the LIVE tower configs (RS.Configs.Towers via TowerConfigRegistry) and RETURNS
-- them as text. Paste the rows over the old ones in shared/src/UnitInfoCatalog.luau, rehash, deploy to BOTH Places.
-- Run it after ANY tower retune; Server.UnitInfoCatalogValidate (Game boot) fails loud while the catalog is stale.
--
-- Row format (see the catalog header): { Element, Placement, PlacementLimit, Cost, CritChance, CritMultiplier,
--   { [attack] = hits }, Ability|false = { Name, Id, Cooldown, Params }, Passives = { { Id, Name, Params } },
--   Tiers = { { DMG, RNG, SPA, UpgradeCost [, Income, Attack, Shape, Effects] } } }
-- Attack / Shape / Effects are written on tier 1 and on every tier where one of them CHANGES.
-- Passive NAMES are not in the configs: they come from the catalog that is live in this Place (same Id at the
-- same index), else the passive's own Name / DisplayName, else its Id split into words.
local RS = game:GetService("ReplicatedStorage")
local Registry = require(RS.Configs.Towers.TowerConfigRegistry) :: any
local Rules = require(RS.Shared.TowerPlacementRules) :: any
local okOld, Old = pcall(function() return require(RS.Shared.UnitInfoCatalog) end)

local function num(v: number): string
	if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
	local s = string.format("%.4f", v):gsub("0+$", ""):gsub("%.$", "")
	return s
end
local function ser(v: any): string
	local t = type(v)
	if t == "number" then return num(v)
	elseif t == "string" then return string.format("%q", v)
	elseif t == "boolean" then return tostring(v)
	elseif t == "table" then
		if #v > 0 then
			local parts = {}
			for _, x in ipairs(v) do table.insert(parts, ser(x)) end
			return "{" .. table.concat(parts, ",") .. "}"
		end
		local keys = {}
		for k in pairs(v) do table.insert(keys, k) end
		table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
		local parts = {}
		for _, k in ipairs(keys) do
			local key = if type(k) == "string" and k:match("^[%a_][%w_]*$") then k else "[" .. ser(k) .. "]"
			table.insert(parts, key .. "=" .. ser(v[k]))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "nil"
end
local function shapeOf(u: any): string
	local s = u.AttackShape
	if s == "Box" then return string.format("Box %sx%s", num(u.ShapeWidth or 0), num(u.ShapeLength or 0))
	elseif s == "Circle" then return "Circle " .. num(u.ShapeRadius or 0)
	elseif s == "Cone" then return "Cone " .. num(u.ShapeAngle or 0)
	elseif s == "FullAoe" then return "FullAoe" end
	return "Single"
end
local function effectsOf(u: any): string
	local ids, seen = {}, {}
	for _, e in ipairs(u.OnHitEffects or {}) do
		if e.Id and not seen[e.Id] then seen[e.Id] = true table.insert(ids, e.Id) end
	end
	return table.concat(ids, "/")
end
local function words(id: string): string
	return (id:gsub("(%l)(%u)", "%1 %2"))
end

local ids = {}
for id in pairs(Registry.GetAll()) do table.insert(ids, id) end
table.sort(ids)
local lines = {}
for _, id in ipairs(ids) do
	local c = Registry.Get(id)
	local ups = c.Upgrades or {}
	local u1 = ups[1] or {}
	local hits = {}
	for name, a in pairs(c.Attacks or {}) do hits[name] = if type(a.Hits) == "table" then #a.Hits else 1 end
	local ab = c.Ability or (c.Abilities and c.Abilities[1])
	local abRow: any = false
	if ab then abRow = { ab.DisplayName or ab.Id, ab.Id, ab.Cooldown or 0, ab.Params or {} } end
	local old = okOld and Old.Get(id) or nil
	local passives = {}
	for i, p in ipairs(c.Passives or {}) do
		local name = p.Name or p.DisplayName
		if not name and old and old.Passives[i] and old.Passives[i].Id == p.Id then name = old.Passives[i].Name end
		table.insert(passives, { p.Id, name or words(p.Id), p.Params or {} })
	end
	local tiers = {}
	local attack, prevKey = "", nil
	for i, u in ipairs(ups) do
		if u.Attack then attack = u.Attack end
		local shape, fx = shapeOf(u), effectsOf(u)
		local row = { u.Damage or 0, u.Range or 0, u.SPA or 0, u.UpgradeCost or 0 }
		local key = attack .. "|" .. shape .. "|" .. fx
		if i == 1 or key ~= prevKey then
			table.insert(row, u.IncomePerWave or 0)
			table.insert(row, attack)
			table.insert(row, shape)
			table.insert(row, fx)
		elseif (u.IncomePerWave or 0) > 0 then
			table.insert(row, u.IncomePerWave)
		end
		prevKey = key
		table.insert(tiers, row)
	end
	local row = {
		c.Element or "Neutral", Rules.PlacementOf(c), c.PlacementLimit or 99, c.Cost or 0,
		u1.CritChance or c.CritChance or 0, u1.CritMultiplier or c.CritMultiplier or 0,
		hits, abRow, passives, tiers,
	}
	-- the hits map / passives / tiers must serialise as tables even when empty
	local parts = {}
	for k = 1, 10 do
		local v = row[k]
		if type(v) == "table" and next(v) == nil then table.insert(parts, "{}") else table.insert(parts, ser(v)) end
	end
	table.insert(lines, "D." .. id .. "={" .. table.concat(parts, ",") .. "}")
end
return table.concat(lines, "\n")
