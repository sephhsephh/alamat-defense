--!strict
-- StageMissionsConfig (B108 pt17, SHARED CANON -- byte-identical in Game, Lobby and shared/src/).
-- Deploy path: ReplicatedStorage.Configs.Global.StageMissionsConfig
--
-- The 3 STAR MISSIONS and the 3 STAR REWARDS of every act. EDIT HERE (user: "3 star missions where i
-- can easily edit later for each act"). Both Places read this one table:
--   * the GAME evaluates the missions at match end and saves which ones were done
--     (ProfileTemplate v11 `StageProgress[stageId].Missions`, writer PlayerInventoryService);
--   * the LOBBY shows them in the Play menu and pays the star rewards (StarRewardService), once each.
--
-- A star = one mission done (ever, on any difficulty). Missions are kept across runs, so a player can
-- earn star 2 on one run and star 3 on another.
--
-- MISSION TYPES (all need a Victory):
--   { Type = "Clear" }                     win the act
--   { Type = "NoLivesLost" }               win without losing a life
--   { Type = "TimeUnder", Seconds = n }    win in under n seconds (match clear time)
--   { Type = "MaxUnits", Count = n }       win having placed n units or fewer (your own placements)
-- STAR REWARDS: { Stars = 1|2|3, ItemId = <ItemCatalog id>, Qty = n } -- claimable once each.

local StageMissionsConfig = {}

local DEFAULT_STAR_REWARDS = {
	{ Stars = 1, ItemId = "TraitRerollToken", Qty = 1 },
	{ Stars = 2, ItemId = "TraitRerollToken", Qty = 1 },
	{ Stars = 3, ItemId = "TraitRerollToken", Qty = 1 },
}

StageMissionsConfig.Acts = {
	Stage1_Act1 = {
		Missions = { { Type = "Clear" }, { Type = "NoLivesLost" }, { Type = "TimeUnder", Seconds = 600 } },
		StarRewards = DEFAULT_STAR_REWARDS,
	},
	Stage1_Act2 = {
		Missions = { { Type = "Clear" }, { Type = "NoLivesLost" }, { Type = "MaxUnits", Count = 4 } },
		StarRewards = DEFAULT_STAR_REWARDS,
	},
	Stage1_Act3 = {
		Missions = { { Type = "Clear" }, { Type = "TimeUnder", Seconds = 720 }, { Type = "MaxUnits", Count = 3 } },
		StarRewards = DEFAULT_STAR_REWARDS,
	},
	Stage1_Act4 = {
		Missions = { { Type = "Clear" }, { Type = "NoLivesLost" }, { Type = "TimeUnder", Seconds = 780 } },
		StarRewards = DEFAULT_STAR_REWARDS,
	},
	Stage1_Act5 = {
		Missions = { { Type = "Clear" }, { Type = "NoLivesLost" }, { Type = "MaxUnits", Count = 3 } },
		StarRewards = DEFAULT_STAR_REWARDS,
	},
}

function StageMissionsConfig.Get(stageId: string?): any
	return stageId and StageMissionsConfig.Acts[stageId] or nil
end

function StageMissionsConfig.MissionText(m: any): string
	if type(m) ~= "table" then return "" end
	if m.Type == "Clear" then return "Clear the act" end
	if m.Type == "NoLivesLost" then return "Clear without losing a life" end
	if m.Type == "TimeUnder" then
		local s = tonumber(m.Seconds) or 0
		return string.format("Clear in under %d:%02d", s // 60, s % 60)
	end
	if m.Type == "MaxUnits" then return string.format("Clear placing %d units or fewer", tonumber(m.Count) or 0) end
	return tostring(m.Type)
end

-- ctx = { Victory: boolean, LivesLost: number, ClearTime: number?, UnitsPlaced: number }
-- Returns { [1] = bool, [2] = bool, [3] = bool } -- which of the act's missions THIS run completed.
function StageMissionsConfig.Evaluate(stageId: string, ctx: any): { boolean }
	local act = StageMissionsConfig.Get(stageId)
	local out = {}
	for i, m in ipairs(act and act.Missions or {}) do
		local ok = false
		if ctx.Victory == true then
			if m.Type == "Clear" then
				ok = true
			elseif m.Type == "NoLivesLost" then
				ok = (tonumber(ctx.LivesLost) or 1) <= 0
			elseif m.Type == "TimeUnder" then
				local t = tonumber(ctx.ClearTime)
				ok = t ~= nil and t > 0 and t < (tonumber(m.Seconds) or 0)
			elseif m.Type == "MaxUnits" then
				ok = (tonumber(ctx.UnitsPlaced) or math.huge) <= (tonumber(m.Count) or 0)
			end
		end
		out[i] = ok
	end
	return out
end

-- Stars earned on an act from a saved StageProgress entry (count of missions ever done).
function StageMissionsConfig.StarsOf(entry: any): number
	local n = 0
	if type(entry) == "table" and type(entry.Missions) == "table" then
		for i = 1, 3 do
			if entry.Missions["M" .. i] == true then n += 1 end
		end
	end
	return n
end

return StageMissionsConfig
