--!strict
-- ChallengeConfig.lua (Game-local canon, owner AD-Game -- see docs/systems/challenges.md)
-- Phase D / D2: the daily-rotating CHALLENGE. A deterministic pick (MetaMath.Slot) of a base stage +
-- MATCH MODIFIERS (MatchModifiersConfig) + a FRAGMENT reward, so a player has a real daily reason to
-- fight a harder match -- and the real SOURCE the crafting loop (D1, B50) was built for. Added B51.
--
-- SERVER-AUTHORITATIVE. The Lobby only asks to launch "the challenge" (GameMode="Challenge"); the Game
-- resolves the stage, the modifiers AND the reward from THIS config off the day's Slot -- never from the
-- (client-forgeable) teleport payload. So a forged payload cannot pick an easier stage or a richer reward.
--
-- DETERMINISTIC: everything is a pure function of the day Slot, so entry and match-end agree even though
-- they run minutes apart. The day Slot is stashed on the match config at entry and re-read at grant (see
-- RewardCalculator), so a match that straddles the daily reset still pays the day it STARTED.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MetaMath = require(ReplicatedStorage.Shared.MetaMath)
local MetaConfig = require(ReplicatedStorage.Configs.Meta.MetaConfig)
local MatchModifiersConfig = require(ReplicatedStorage.Configs.Global.MatchModifiersConfig)

local ChallengeConfig = {}

-- B108: the Mutya colours (ItemCatalog: Mutya<Colour>). The day's reward is the BASE stone (Green Mutya)
-- plus a small chance of that day's colour Mutya. Kept local so this module stays pure.
local COLOURS = { "Red", "Blue", "Yellow", "Purple", "Pink" }
ChallengeConfig.Colours = COLOURS

-- The challenge POOL. Each entry names a BASE stage (its map + wave list + gold curve are reused) and a
-- list of MatchModifiers ids. The day's Slot rotates through the pool. Base stages are existing acts --
-- the challenge is the MODIFIERS + the fragment reward, not new wave content (varied base stages + bespoke
-- wave lists are a tuning follow-up; see challenges.md).
local POOL = {
	{ Id = "tough_fields",  Name = "Tough Fields",  StageId = "Stage1_Act1", Modifiers = { "EnemyHpX1_5" } },
	{ Id = "sudden_fields", Name = "Sudden Death",  StageId = "Stage1_Act1", Modifiers = { "OneLife" } },
	{ Id = "brutal_fields", Name = "Brutal Fields", StageId = "Stage1_Act1", Modifiers = { "EnemyHpX2", "HalfLives" } },
	{ Id = "scarce_fields", Name = "Scarce Fields", StageId = "Stage1_Act1", Modifiers = { "EnemyHpX1_5", "Scarcity" } },
	-- B56: the first challenges to use the TOWER-STAT modifiers. Kept to ONE stat modifier each,
	-- paired with a mild HP bump: range and fire rate are what a player's whole placement plan is
	-- built on, so stacking both at once reads as broken towers rather than a challenge.
	{ Id = "blind_fields",  Name = "Blind Fields",  StageId = "Stage1_Act1", Modifiers = { "ShortSight", "EnemyHpX1_5" } },
	{ Id = "sluggish_fields", Name = "Sluggish Fields", StageId = "Stage1_Act1", Modifiers = { "SlowHands", "EnemyHpX1_5" } },
}

-- Deterministic reward for a day Slot: a rotating colour's fragments, with a small bonus chance. Same
-- Slot -> same rewards on every server and at every call, which is what lets match-end recompute them.
function ChallengeConfig.RewardsForSlot(slot: number): ({ any }, string)
	local rng = MetaMath.RngForSlot(slot, "challenge_reward")
	local colour = COLOURS[rng:NextInteger(1, #COLOURS)]
	local qty = 2
	if rng:NextNumber() < 0.20 then qty = 3 end
	local rewards = { { Id = "MutyaGreen", Qty = qty } }
	-- Occasionally the day's challenge also drops that day's COLOUR Mutya (B108).
	if rng:NextNumber() < 0.10 then
		table.insert(rewards, { Id = "Mutya" .. colour, Qty = 1 })
	end
	return rewards, colour
end

-- The full challenge for a day Slot. PURE -- callers pass the slot (or use GetDaily).
function ChallengeConfig.GetForSlot(slot: number): any
	local template = POOL[(slot % #POOL) + 1]
	local rewards, colour = ChallengeConfig.RewardsForSlot(slot)
	return {
		Id = template.Id,
		Name = template.Name,
		DaySlot = slot,
		StageId = template.StageId,
		Modifiers = table.clone(template.Modifiers),
		Rewards = rewards,
		Colour = colour,
	}
end

-- Today's challenge. nowSec is for tests only.
function ChallengeConfig.GetDaily(nowSec: number?): any
	local slot = MetaMath.Slot(MetaConfig.Periods.Daily, MetaConfig.ResetOffsetSec, nowSec)
	return ChallengeConfig.GetForSlot(slot)
end

-- ===== B108 pt17 Part C: REGULAR + WEEKLY challenges (user: Regular / Daily / Weekly tabs) =====
-- REGULAR: a set of `RegularCount` challenges that ROTATES every `RegularPeriod` seconds, with a shared
-- limit of `RegularDailyLimit` clears per day (resets with the daily reset). Small reward.
-- WEEKLY: ONE harder challenge per week (two modifiers stacked on a later act), ONE paid clear per week,
-- bigger reward. DAILY is the original GetDaily above, unchanged.
-- All PURE functions of a slot number, exactly like the daily: the Lobby shows them, the Game re-resolves
-- them from the kind + slot + index it stashed at entry -- a forged payload cannot pick the reward.
ChallengeConfig.RegularPeriod = 1800 -- 30 minutes
ChallengeConfig.RegularCount = 3
ChallengeConfig.RegularDailyLimit = 10
ChallengeConfig.WeeklyLimit = 1
ChallengeConfig.RegularRewards = { { Id = "Gold", Qty = 400 }, { Id = "MutyaGreen", Qty = 1 } }
ChallengeConfig.WeeklyRewards = { { Id = "MutyaRainbow", Qty = 1 }, { Id = "StatRerolls", Qty = 3 }, { Id = "Gold", Qty = 3000 } }
-- Weekly stages + modifier pairs (harder than any daily). Rotates by week.
local WEEKLY = {
	{ Id = "weekly_harvest", Name = "Harvest of Ruin", StageId = "Stage1_Act3", Modifiers = { "EnemyHpX2", "Scarcity" } },
	{ Id = "weekly_scarecrow", Name = "The Scarecrow's Wrath", StageId = "Stage1_Act2", Modifiers = { "EnemyHpX2", "HalfLives" } },
	{ Id = "weekly_blind", Name = "Blind Harvest", StageId = "Stage1_Act3", Modifiers = { "ShortSight", "EnemyHpX2" } },
}

function ChallengeConfig.RegularSlot(nowSec: number?): number
	return MetaMath.Slot(ChallengeConfig.RegularPeriod, MetaConfig.ResetOffsetSec, nowSec)
end
function ChallengeConfig.WeeklySlot(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Weekly, MetaConfig.ResetOffsetSec, nowSec)
end
function ChallengeConfig.DaySlot(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Daily, MetaConfig.ResetOffsetSec, nowSec)
end

-- The index-th (1..RegularCount) regular challenge of a slot: distinct pool entries, deterministic.
function ChallengeConfig.GetRegularForSlot(slot: number, index: number): any?
	if index < 1 or index > ChallengeConfig.RegularCount then return nil end
	local rng = MetaMath.RngForSlot(slot, "challenge_regular")
	local order = {}
	for i = 1, #POOL do order[i] = i end
	for i = #order, 2, -1 do
		local j = rng:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	local t = POOL[order[((index - 1) % #POOL) + 1]]
	return {
		Id = t.Id, Name = t.Name, Kind = "Regular", Index = index, Slot = slot,
		StageId = t.StageId, Modifiers = table.clone(t.Modifiers), Rewards = table.clone(ChallengeConfig.RegularRewards),
	}
end
function ChallengeConfig.GetRegular(nowSec: number?): { any }
	local slot = ChallengeConfig.RegularSlot(nowSec)
	local out = {}
	for i = 1, ChallengeConfig.RegularCount do
		table.insert(out, ChallengeConfig.GetRegularForSlot(slot, i))
	end
	return out
end

function ChallengeConfig.GetWeeklyForSlot(slot: number): any
	local t = WEEKLY[(slot % #WEEKLY) + 1]
	return {
		Id = t.Id, Name = t.Name, Kind = "Weekly", Index = 1, Slot = slot,
		StageId = t.StageId, Modifiers = table.clone(t.Modifiers), Rewards = table.clone(ChallengeConfig.WeeklyRewards),
	}
end
function ChallengeConfig.GetWeekly(nowSec: number?): any
	return ChallengeConfig.GetWeeklyForSlot(ChallengeConfig.WeeklySlot(nowSec))
end

-- One entry point for the Game: kind + slot (+ index) -> the challenge. Unknown kind = the daily.
function ChallengeConfig.Resolve(kind: any, slot: number?, index: any): any
	if kind == "Regular" then
		return ChallengeConfig.GetRegularForSlot(slot or ChallengeConfig.RegularSlot(), tonumber(index) or 1)
			or ChallengeConfig.GetRegularForSlot(slot or ChallengeConfig.RegularSlot(), 1)
	elseif kind == "Weekly" then
		return ChallengeConfig.GetWeeklyForSlot(slot or ChallengeConfig.WeeklySlot())
	end
	local d = ChallengeConfig.GetForSlot(slot or ChallengeConfig.DaySlot())
	d.Kind = "Daily"
	d.Slot = d.DaySlot
	return d
end

-- Limits, read from the profile's Counters.Global.ChallengeLimits = { RegularDay, RegularClears, WeeklyWeek }
-- (written by the Game at a paid challenge clear). Returns (used, limit) for the CURRENT period.
function ChallengeConfig.LimitUsed(limits: any, kind: string, nowSec: number?): (number, number)
	limits = type(limits) == "table" and limits or {}
	if kind == "Regular" then
		local used = if limits.RegularDay == ChallengeConfig.DaySlot(nowSec) then (tonumber(limits.RegularClears) or 0) else 0
		return used, ChallengeConfig.RegularDailyLimit
	elseif kind == "Weekly" then
		return (if limits.WeeklyWeek == ChallengeConfig.WeeklySlot(nowSec) then 1 else 0), ChallengeConfig.WeeklyLimit
	end
	return 0, math.huge
end

-- Boot-time sanity: every template names a stage-shaped id and known modifiers, and every colour's
-- reward ids are catalogued. Returns (ok, issues). Cheap; call from a harness, not the hot path.
function ChallengeConfig.Validate(): (boolean, { string })
	local issues = {}
	local ItemCatalog = require(ReplicatedStorage.Configs.Meta.ItemCatalog)
	for _, t in ipairs(POOL) do
		if type(t.StageId) ~= "string" or t.StageId == "" then
			table.insert(issues, ("template %s: bad StageId"):format(tostring(t.Id)))
		end
		for _, mid in ipairs(t.Modifiers) do
			if not MatchModifiersConfig.IsKnown(mid) then
				table.insert(issues, ("template %s: unknown modifier %s"):format(tostring(t.Id), tostring(mid)))
			end
		end
	end
	for _, colour in ipairs(COLOURS) do
		for _, id in ipairs({ "MutyaGreen", "Mutya" .. colour }) do
			if ItemCatalog.Get(id) == nil then
				table.insert(issues, ("reward id not catalogued: %s"):format(id))
			end
		end
	end
	return #issues == 0, issues
end

return ChallengeConfig
