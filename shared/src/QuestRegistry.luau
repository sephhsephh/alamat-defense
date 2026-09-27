--!strict
-- QuestRegistry.lua (SHARED CANON since B81 -- deploy path ReplicatedStorage.Configs.Meta.QuestRegistry) -- added B40.
--
-- B81: promoted from Lobby-local so the GAME's Pinned Quests panel reads the SAME day's quests the
-- Lobby assigns. Read-only there: the Lobby's QuestService stays the ONE writer of Data.Quests.
-- Needs Shared.MetaMath + Configs.Meta.MetaConfig, both already shared canon.
--
-- Daily quests. PURE rules; `Server.Meta.QuestService` owns every write.
--
-- >>> HOW PROGRESS IS MEASURED, AND WHY IT IS A DELTA <<<
-- A quest counts a `Counter` -- a key under `Data.Counters.Global`, which several services already
-- maintain as LIFETIME totals. A daily quest cannot read a lifetime total directly (a player with
-- 900 pulls would complete "pull 10 times" instantly, forever), so when a quest is ASSIGNED the
-- service records the counter's value at that moment as a BASELINE, and progress is
-- `current - baseline`.
--
-- That choice is what lets quests work TODAY against counters nobody wrote for quests, with no
-- changes to the services that own them and no new writes on any hot path.
--
-- >>> ONLY TWO COUNTERS ACTUALLY EXIST RIGHT NOW <<<
--   GachaPulls   written by SummonService
--   Ascensions   written by AscensionService
-- Everything match-shaped (waves survived, stages cleared, enemies defeated) is the GAME place's to
-- write and none of it exists yet. Quests naming a counter with no writer would sit at 0 forever and
-- look like a bug in the quest system, so `QuestService` REFUSES to assign them and says so by name
-- at boot. Add the quest here the day AD-Game adds the counter -- that is the only change needed.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MetaMath = require(ReplicatedStorage.Shared.MetaMath)
local MetaConfig = require(ReplicatedStorage.Configs.Meta.MetaConfig)

local QuestRegistry = {}

-- How many daily quests a player is given.
QuestRegistry.DailyCount = 3

-- Counters this Experience actually writes today. `QuestService` checks against this so a quest on a
-- counter nobody increments is caught at boot instead of by a confused player.
QuestRegistry.LiveCounters = {
	GachaPulls = true,
	Ascensions = true,
	-- Match counters, written by the GAME place's RewardCalculator: `Clears` (a Victory -- and a
	-- StageConfig IS an act) and `InsaneVictories` (a Victory that was also Insane; added B41).
	-- Names are a cross-Place contract: lifetime, monotonic, never renamed.
	Clears = true,
	InsaneVictories = true,
}

-- *** PLACEHOLDER CONTENT -- NOT A CONSIDERED ECONOMY OR DIFFICULTY DECISION. ***
-- `Reward` rows are GrantService's PUBLIC contract ({ Id, Qty }, capitalised).
-- `Counter` must be a key under Data.Counters.Global. `Target` is the DELTA required since assignment.
QuestRegistry.Quests = {
	{
		Id = "PullThree",
		Name = "Summon 3 times",
		Counter = "GachaPulls",
		Target = 3,
		Reward = { { Id = "Silver", Qty = 300 } },
		Weight = 10,
	},
	{
		Id = "PullTen",
		Name = "Summon 10 times",
		Counter = "GachaPulls",
		Target = 10,
		Reward = { { Id = "Gold", Qty = 250 }, { Id = "Silver", Qty = 200 } },
		Weight = 6,
	},
	{
		Id = "AscendOnce",
		Name = "Ascend a unit",
		Counter = "Ascensions",
		Target = 1,
		Reward = { { Id = "GoldenSeed", Qty = 1 } },
		Weight = 4,
	},
	{
		Id = "PullOne",
		Name = "Summon once",
		Counter = "GachaPulls",
		Target = 1,
		Reward = { { Id = "Silver", Qty = 120 } },
		Weight = 12,
	},
	-- Match quests. UNBLOCKED B41: the GAME place's RewardCalculator now writes both counters.
	-- ClearThree reads `Clears`, NOT a new `ActsCleared` key -- the Game deliberately did not add a
	-- second stored number for an event `Clears` already counts (user's call, B41). *** PLACEHOLDER
	-- rewards/weights, same as the rest of this table -- not a considered economy decision. ***
	{
		Id = "ClearThree",
		Name = "Clear 3 acts",
		Counter = "Clears",
		Target = 3,
		Reward = { { Id = "Silver", Qty = 300 }, { Id = "StatRerolls", Qty = 1 } },  -- B46: StatRerolls everyday source (effort-gated)
		Weight = 8,
	},
	{
		Id = "WinInsane",
		Name = "Win on Insane",
		Counter = "InsaneVictories",
		Target = 1,
		Reward = { { Id = "Gold", Qty = 250 }, { Id = "Silver", Qty = 200 } },
		Weight = 5,
	},
}

function QuestRegistry.CurrentDay(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Daily, MetaConfig.ResetOffsetSec, nowSec)
end

function QuestRegistry.SecondsUntilReset(nowSec: number?): number
	local period = MetaConfig.Periods.Daily
	local now = nowSec or os.time()
	return period - ((now + MetaConfig.ResetOffsetSec) % period)
end

function QuestRegistry.Get(questId: string): any?
	for _, q in ipairs(QuestRegistry.Quests) do
		if q.Id == questId then
			return q
		end
		end
	return nil
end

-- Only quests whose counter is actually written by something.
function QuestRegistry.Assignable(): { any }
	local out = {}
	for _, q in ipairs(QuestRegistry.Quests) do
		if QuestRegistry.LiveCounters[q.Counter] then
			table.insert(out, q)
		end
	end
	return out
end

-- Quests that would never progress. Reported at boot, never assigned.
function QuestRegistry.Orphans(): { string }
	local out = {}
	for _, q in ipairs(QuestRegistry.Quests) do
		if not QuestRegistry.LiveCounters[q.Counter] then
			table.insert(out, string.format("%s(%s)", q.Id, tostring(q.Counter)))
		end
	end
	return out
end

-- The day's quest set for one player. DETERMINISTIC and PURE, same mechanism the shop uses: derived
-- from (userId, day) so every server agrees with no stored roll and no coordination.
function QuestRegistry.RollDaily(userId: number, day: number): { any }
	local pool = {}
	for _, q in ipairs(QuestRegistry.Assignable()) do
		table.insert(pool, { v = q, w = q.Weight or 1 })
	end
	local rng = MetaMath.RngForSlot(day, "Quests:" .. tostring(userId))
	return MetaMath.PickDistinct(rng, pool, QuestRegistry.DailyCount)
end

return QuestRegistry
