--!strict
-- Configs.Meta.GoalEval (SHARED CANON since B109 M7; added B109 M2) -- the ONE evaluator for LIFETIME goals
-- (achievements, event quests). PURE: reads the profile, writes nothing. Progress(data, goal) -> (current clamped,
-- target). Shared so the GAME's match HUD can show live progress for pinned achievements / event quests.
--
-- GOAL TYPES:
--   { Type = "Counter", Key = <Counters.Global key>, Target = n }        lifetime counter (quests.md lists them)
--   { Type = "Level", Target = n }                                       player level
--   { Type = "StageClear", StageId = id }                                cleared that act at least once
--   { Type = "HardActs", Acts = { actId, ... } }                         every act cleared on Hard (HardClearsByStage)
--   { Type = "Stars", Target = n, Acts = {...}? }                        star missions done (all acts, or only these)
--   { Type = "InfiniteBest", StageId = id, Target = wave }               best wave ever in that Infinite
--   { Type = "UnitsOwned", Target = n }                                  unit instances owned now
--   { Type = "UnitsDistinct", Target = n }                               different units EVER obtained (Obtained_<id>)
--   { Type = "UnitLevel", Target = n }                                   any unit at that level or higher
--   { Type = "Shiny", Target = n }                                       shiny units owned
--   { Type = "Ascension", Target = n }                                   any unit at that ascension or higher
--   { Type = "Equipped", Target = n }                                    units in the hotbar loadout
--   { Type = "Codes", Target = n }                                       codes redeemed
--   { Type = "ObtainSince", TowerId = id, Event = eventId, Target = n }  units of that id obtained SINCE the event's
--        baseline (Counters.Global.EventQuests[event].Base[id], written by EventQuestService when the player first
--        sees the event). Uses the lifetime Obtained_<id> counter, so selling/feeding never lowers it. (B109 M4)

local GoalEval = {}

local function global(data: any): any
	local c = type(data) == "table" and data.Counters or nil
	return (type(c) == "table" and type(c.Global) == "table") and c.Global or {}
end

local function units(data: any): any
	return (type(data) == "table" and type(data.Units) == "table") and data.Units or {}
end

function GoalEval.Target(goal: any): number
	if goal.Type == "StageClear" then return 1 end
	if goal.Type == "HardActs" then return #(goal.Acts or {}) end
	return tonumber(goal.Target) or 1
end

function GoalEval.Progress(data: any, goal: any): (number, number)
	local g = global(data)
	local t = GoalEval.Target(goal)
	local cur = 0
	local kind = goal.Type
	if kind == "Counter" then
		cur = tonumber(g[goal.Key]) or 0
	elseif kind == "Level" then
		cur = tonumber(data.PlayerLevel) or 1
	elseif kind == "StageClear" then
		local by = g.ClearsByStage
		cur = (type(by) == "table" and (tonumber(by[goal.StageId]) or 0) > 0) and 1 or 0
	elseif kind == "HardActs" then
		local by = type(g.HardClearsByStage) == "table" and g.HardClearsByStage or {}
		for _, a in ipairs(goal.Acts or {}) do
			if (tonumber(by[a]) or 0) > 0 then cur += 1 end
		end
	elseif kind == "Stars" then
		local sp = type(data.StageProgress) == "table" and data.StageProgress or {}
		local only = nil
		if type(goal.Acts) == "table" then
			only = {}
			for _, a in ipairs(goal.Acts) do only[a] = true end
		end
		for id, e in pairs(sp) do
			if (only == nil or only[id]) and type(e) == "table" and type(e.Missions) == "table" then
				for _, v in pairs(e.Missions) do if v == true then cur += 1 end end
			end
		end
	elseif kind == "InfiniteBest" then
		local sp = type(data.StageProgress) == "table" and data.StageProgress or {}
		local e = sp[goal.StageId]
		cur = type(e) == "table" and (tonumber(e.HighestWave) or 0) or 0
	elseif kind == "UnitsOwned" then
		for _ in pairs(units(data)) do cur += 1 end
	elseif kind == "UnitsDistinct" then
		for k, v in pairs(g) do
			if type(k) == "string" and string.sub(k, 1, 9) == "Obtained_" and (tonumber(v) or 0) > 0 then cur += 1 end
		end
	elseif kind == "UnitLevel" then
		for _, u in pairs(units(data)) do cur = math.max(cur, tonumber(u.MetaLevel) or 1) end
	elseif kind == "Shiny" then
		for _, u in pairs(units(data)) do if u.Shiny == true then cur += 1 end end
	elseif kind == "Ascension" then
		for _, u in pairs(units(data)) do cur = math.max(cur, tonumber(u.Ascension) or 0) end
	elseif kind == "Equipped" then
		cur = #(type(data.Loadout) == "table" and data.Loadout or {})
	elseif kind == "ObtainSince" then
		local eq = type(g.EventQuests) == "table" and g.EventQuests[goal.Event] or nil
		local base = type(eq) == "table" and type(eq.Base) == "table" and eq.Base[goal.TowerId] or nil
		if base ~= nil then
			cur = math.max(0, (tonumber(g["Obtained_" .. goal.TowerId]) or 0) - (tonumber(base) or 0))
		end
	elseif kind == "Codes" then
		for _ in pairs(type(data.RedeemedCodes) == "table" and data.RedeemedCodes or {}) do cur += 1 end
	end
	return math.min(cur, t), t
end

return GoalEval
