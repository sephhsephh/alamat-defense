--!strict
-- QuestRegistry (SHARED CANON -- ReplicatedStorage.Configs.Meta.QuestRegistry). Added B40, promoted B81,
-- REWRITTEN B109 (docs/specs/2026-10-03-quests-events-overhaul.md).
--
-- PURE rules + PURE progress math for Daily / Weekly quests. The Lobby's `Server.Meta.QuestService` is the
-- ONE writer of `Data.Quests`; the Game's HudInfoService only READS through `QuestRegistry.State`.
--
-- B109 (user): FIXED lists -- every player gets the same Daily list and the same Weekly list (no roll), plus
-- each day 2 random Infinite maps (same for everyone) with wave 25 / 50 / 75 quests.
-- Weekly resets Monday 00:00 PH time (= Sunday 16:00 UTC), MetaConfig.WeeklyResetOffsetSec.
--
-- >>> COUNTER QUESTS ARE A DELTA AGAINST A BASELINE <<<
-- `Counter` is a LIFETIME key under Data.Counters.Global. QuestService records the counter's value the
-- first time a period's quest is seen (`Data.Quests.Daily.Base[id]`), progress = current - baseline.
-- >>> INFINITE MAP QUESTS READ A PER-DAY BEST <<<
-- `Counters.Global.InfiniteDayBest = { Day = <daily slot>, [stageId] = best wave }`, written by the GAME's
-- RewardCalculator. A quest's progress is that day's best wave on its map (no baseline).
--
-- EDIT CONTENT HERE: Daily / Weekly / InfiniteDaily. *** PLACEHOLDER numbers + rewards (user edits). ***
-- `Desc` may contain ONE `{Word}` -- the screen underlines it and clicking opens `Link` (Story / Infinite /
-- Challenge / Summon / Units / Shop / Craft).
-- `Reward` rows are GrantService's contract ({ Id, Qty }); `BattlepassXP` pays Battle Pass EXP.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetaMath = require(ReplicatedStorage.Shared.MetaMath)
local MetaConfig = require(ReplicatedStorage.Configs.Meta.MetaConfig)

local QuestRegistry = {}

-- Counters that something actually writes (a quest on any other counter is reported at boot, never shown).
QuestRegistry.LiveCounters = {
	GachaPulls = true, Ascensions = true,                                  -- Lobby (Summon / Ascension)
	Feeds = true, TraitRerolls = true, StatRerollsDone = true, Crafts = true, Evolutions = true, ShopBuys = true, -- Lobby LifetimeCounters
	GoldSpent = true, SilverSpent = true,                                  -- Lobby GrantService.Spend (B109)
	DailyQuestsClaimed = true,                                             -- Lobby QuestService (B109)
	Clears = true, InsaneVictories = true, ChallengeClears = true, Waves = true, -- Game RewardCalculator
	InfiniteWaves = true,                                                  -- Game RewardCalculator (B109)
}

local function R(gold: number?, silver: number?, bp: number?, extra: { any }?): { any }
	local out = {}
	if gold and gold > 0 then table.insert(out, { Id = "Gold", Qty = gold }) end
	if silver and silver > 0 then table.insert(out, { Id = "Silver", Qty = silver }) end
	if bp and bp > 0 then table.insert(out, { Id = "BattlepassXP", Qty = bp }) end
	for _, e in ipairs(extra or {}) do table.insert(out, e) end
	return out
end

QuestRegistry.Daily = {
	{ Id = "D_Clears", Name = "Complete Stages", Desc = "Complete any {Story} stage 10 times", Link = "Story", Counter = "Clears", Target = 10, Reward = R(50, 250, 100) },
	{ Id = "D_Hard", Name = "Hard Victories", Desc = "Win any {Story} stage on Hard 3 times", Link = "Story", Counter = "InsaneVictories", Target = 3, Reward = R(60, 200, 100) },
	{ Id = "D_InfWaves", Name = "Clear Infinite Waves", Desc = "Clear 100 waves in any {Infinite}", Link = "Infinite", Counter = "InfiniteWaves", Target = 100, Reward = R(50, 250, 100) },
	{ Id = "D_Challenge", Name = "Complete Challenges", Desc = "Complete any {Challenge} 2 times", Link = "Challenge", Counter = "ChallengeClears", Target = 2, Reward = R(50, 200, 100) },
	{ Id = "D_Summon", Name = "Summon", Desc = "{Summon} 10 units", Link = "Summon", Counter = "GachaPulls", Target = 10, Reward = R(0, 300, 100) },
	{ Id = "D_Feed", Name = "Feed Units", Desc = "Feed your {Units} 3 times", Link = "Units", Counter = "Feeds", Target = 3, Reward = R(0, 200, 80) },
	{ Id = "D_SpendSilver", Name = "Spend Silver", Desc = "Spend 1,000 silver in the {Shop}", Link = "Shop", Counter = "SilverSpent", Target = 1000, Reward = R(40, 0, 80) },
	{ Id = "D_All", Name = "Complete Daily Quests", Desc = "Complete 6 daily quests", Counter = "DailyQuestsClaimed", Target = 6, Reward = R(150, 500, 200, { { Id = "StatRerolls", Qty = 1 } }) },
}

QuestRegistry.Weekly = {
	{ Id = "W_Clears", Name = "Complete Stages", Desc = "Complete any {Story} stage 50 times", Link = "Story", Counter = "Clears", Target = 50, Reward = R(300, 1500, 500) },
	{ Id = "W_Hard", Name = "Hard Victories", Desc = "Win any {Story} stage on Hard 15 times", Link = "Story", Counter = "InsaneVictories", Target = 15, Reward = R(300, 1000, 500) },
	{ Id = "W_InfWaves", Name = "Clear Infinite Waves", Desc = "Clear 500 waves in any {Infinite}", Link = "Infinite", Counter = "InfiniteWaves", Target = 500, Reward = R(300, 1500, 500) },
	{ Id = "W_Challenge", Name = "Complete Regular Challenge", Desc = "Complete any {Challenge} 10 times", Link = "Challenge", Counter = "ChallengeClears", Target = 10, Reward = R(300, 1000, 500) },
	{ Id = "W_Summon", Name = "Summon", Desc = "{Summon} 100 units", Link = "Summon", Counter = "GachaPulls", Target = 100, Reward = R(250, 2000, 500) },
	{ Id = "W_SpendGold", Name = "Spend Gold", Desc = "Spend 5,000 gold", Counter = "GoldSpent", Target = 5000, Reward = R(0, 2500, 500) },
	{ Id = "W_SpendSilver", Name = "Spend Silver", Desc = "Spend 10,000 silver", Counter = "SilverSpent", Target = 10000, Reward = R(400, 0, 500) },
	{ Id = "W_Craft", Name = "Craft Items", Desc = "{Craft} 5 times", Link = "Craft", Counter = "Crafts", Target = 5, Reward = R(200, 1000, 400, { { Id = "TraitRerollToken", Qty = 1 } }) },
}

-- Daily Infinite map quests: `MapsPerDay` maps drawn (same for everyone) from `Maps`, one quest per wave.
-- Add a map here when its Infinite exists (StageId = the Game's Infinite StageConfig id).
QuestRegistry.InfiniteDaily = {
	MapsPerDay = 2,
	Maps = {
		{ StageId = "Stage1_Infinite", Name = "The Farm" },
	},
	Waves = {
		{ Wave = 25, Reward = R(30, 150, 50) },
		{ Wave = 50, Reward = R(60, 300, 100) },
		{ Wave = 75, Reward = R(100, 500, 150) },
	},
}

-- ===== time =====
function QuestRegistry.CurrentDay(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Daily, MetaConfig.ResetOffsetSec, nowSec)
end

function QuestRegistry.CurrentWeek(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Weekly, MetaConfig.WeeklyResetOffsetSec, nowSec)
end

function QuestRegistry.SecondsUntilReset(nowSec: number?): number
	local period = MetaConfig.Periods.Daily
	local now = nowSec or os.time()
	return period - ((now + MetaConfig.ResetOffsetSec) % period)
end

function QuestRegistry.SecondsUntilWeeklyReset(nowSec: number?): number
	local period = MetaConfig.Periods.Weekly
	local now = nowSec or os.time()
	return period - ((now + MetaConfig.WeeklyResetOffsetSec) % period)
end

-- ===== lists =====
-- The day's Infinite maps (deterministic per day, the same for every player and server).
function QuestRegistry.InfiniteMapsForDay(day: number): { any }
	local cfg = QuestRegistry.InfiniteDaily
	local pool = {}
	for _, m in ipairs(cfg.Maps) do
		table.insert(pool, { v = m, w = 1 })
	end
	local rng = MetaMath.RngForSlot(day, "InfiniteQuests")
	return MetaMath.PickDistinct(rng, pool, math.min(cfg.MapsPerDay, #pool))
end

local function counterQuest(q: any, period: string): any
	return {
		Id = q.Id, Period = period, Kind = period, Name = q.Name, Desc = q.Desc, Link = q.Link,
		Counter = q.Counter, Target = q.Target, Reward = q.Reward,
	}
end

-- Today's Daily list: the fixed list (live counters only) + the day's Infinite map quests.
function QuestRegistry.DailyList(day: number): { any }
	local out = {}
	for _, q in ipairs(QuestRegistry.Daily) do
		if QuestRegistry.LiveCounters[q.Counter] then
			table.insert(out, counterQuest(q, "Daily"))
		end
	end
	for _, m in ipairs(QuestRegistry.InfiniteMapsForDay(day)) do
		for i, w in ipairs(QuestRegistry.InfiniteDaily.Waves) do
			table.insert(out, {
				Id = string.format("Inf_%s_%d", m.StageId, w.Wave), Period = "Daily", Kind = "Infinite",
				Name = string.format("%s Infinite #%d", m.Name, i),
				Desc = string.format("Clear Wave %d of {%s}", w.Wave, m.Name), Link = "Infinite",
				StageId = m.StageId, Target = w.Wave, Reward = w.Reward,
			})
		end
	end
	return out
end

function QuestRegistry.WeeklyList(_week: number): { any }
	local out = {}
	for _, q in ipairs(QuestRegistry.Weekly) do
		if QuestRegistry.LiveCounters[q.Counter] then
			table.insert(out, counterQuest(q, "Weekly"))
		end
	end
	return out
end

-- B81 compatibility (the Game's HudInfoService called this): today's Daily list.
function QuestRegistry.RollDaily(_userId: number, day: number): { any }
	return QuestRegistry.DailyList(day)
end

-- Quests that would never progress (counter with no writer). Reported at boot, never shown.
function QuestRegistry.Orphans(): { string }
	local out = {}
	for _, list in ipairs({ QuestRegistry.Daily, QuestRegistry.Weekly }) do
		for _, q in ipairs(list) do
			if not QuestRegistry.LiveCounters[q.Counter] then
				table.insert(out, string.format("%s(%s)", q.Id, tostring(q.Counter)))
			end
		end
	end
	return out
end

-- ===== progress (PURE; both Places) =====
function QuestRegistry.Counter(data: any, key: string): number
	local c = type(data) == "table" and data.Counters or nil
	local g = type(c) == "table" and c.Global or nil
	return (type(g) == "table" and tonumber(g[key])) or 0
end

local function periodBox(data: any, period: string): any
	local q = type(data) == "table" and data.Quests or nil
	local box = type(q) == "table" and q[period] or nil
	return type(box) == "table" and box or nil
end

-- Raw progress of one quest (not clamped to Target). `slot` = the period's current slot.
function QuestRegistry.ProgressOf(data: any, q: any, slot: number): number
	if q.Kind == "Infinite" then
		local c = type(data) == "table" and data.Counters or nil
		local g = type(c) == "table" and c.Global or nil
		local best = type(g) == "table" and g.InfiniteDayBest or nil
		if type(best) == "table" and tonumber(best.Day) == slot then
			return tonumber(best[q.StageId]) or 0
		end
		return 0
	end
	local box = periodBox(data, q.Period)
	if not box or tonumber(box.Slot) ~= slot or type(box.Base) ~= "table" or box.Base[q.Id] == nil then
		return 0 -- no baseline yet (the Lobby has not opened this period): honest 0
	end
	return math.max(0, QuestRegistry.Counter(data, q.Counter) - (tonumber(box.Base[q.Id]) or 0))
end

function QuestRegistry.IsClaimed(data: any, q: any, slot: number): boolean
	local box = periodBox(data, q.Period)
	return box ~= nil and tonumber(box.Slot) == slot and type(box.Claimed) == "table" and box.Claimed[q.Id] == true
end

-- Display view of one quest.
function QuestRegistry.View(data: any, q: any, slot: number, secondsLeft: number): any
	local progress = QuestRegistry.ProgressOf(data, q, slot)
	local claimed = QuestRegistry.IsClaimed(data, q, slot)
	return {
		Id = q.Id, Period = q.Period, Kind = q.Kind, Name = q.Name, Desc = q.Desc, Link = q.Link,
		Target = q.Target, Progress = math.min(progress, q.Target), Complete = progress >= q.Target,
		Claimed = claimed, CanClaim = progress >= q.Target and not claimed, Reward = q.Reward,
		SecondsLeft = secondsLeft,
	}
end

-- Every current quest as views: { Daily = {...}, Weekly = {...}, Day, Week, DailyReset, WeeklyReset }.
function QuestRegistry.State(data: any, nowSec: number?): any
	local day = QuestRegistry.CurrentDay(nowSec)
	local week = QuestRegistry.CurrentWeek(nowSec)
	local dLeft = QuestRegistry.SecondsUntilReset(nowSec)
	local wLeft = QuestRegistry.SecondsUntilWeeklyReset(nowSec)
	local daily, weekly = {}, {}
	for _, q in ipairs(QuestRegistry.DailyList(day)) do
		table.insert(daily, QuestRegistry.View(data, q, day, dLeft))
	end
	for _, q in ipairs(QuestRegistry.WeeklyList(week)) do
		table.insert(weekly, QuestRegistry.View(data, q, week, wLeft))
	end
	return { Daily = daily, Weekly = weekly, Day = day, Week = week, DailyReset = dLeft, WeeklyReset = wLeft }
end

-- Find a CURRENT quest by id (claims must name one of this period's quests).
function QuestRegistry.FindCurrent(questId: string, nowSec: number?): (any?, number?)
	local day = QuestRegistry.CurrentDay(nowSec)
	for _, q in ipairs(QuestRegistry.DailyList(day)) do
		if q.Id == questId then return q, day end
	end
	local week = QuestRegistry.CurrentWeek(nowSec)
	for _, q in ipairs(QuestRegistry.WeeklyList(week)) do
		if q.Id == questId then return q, week end
	end
	return nil, nil
end

return QuestRegistry
