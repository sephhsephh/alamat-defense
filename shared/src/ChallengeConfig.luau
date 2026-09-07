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

-- The seven crafting colours (ItemCatalog: Fragment<Colour>, Artifact<Colour>). Kept local so this
-- module stays pure and does not force an ItemCatalog require at load.
local COLOURS = { "Red", "Orange", "Yellow", "Green", "Blue", "Indigo", "Violet" }
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
}

-- Deterministic reward for a day Slot: a rotating colour's fragments, with a small bonus chance. Same
-- Slot -> same rewards on every server and at every call, which is what lets match-end recompute them.
function ChallengeConfig.RewardsForSlot(slot: number): ({ any }, string)
	local rng = MetaMath.RngForSlot(slot, "challenge_reward")
	local colour = COLOURS[rng:NextInteger(1, #COLOURS)]
	local qty = 2
	if rng:NextNumber() < 0.20 then qty = 3 end
	local rewards = { { Id = "Fragment" .. colour, Qty = qty } }
	-- Occasionally the day's challenge also drops the finished ARTIFACT of that colour.
	if rng:NextNumber() < 0.10 then
		table.insert(rewards, { Id = "Artifact" .. colour, Qty = 1 })
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
		for _, id in ipairs({ "Fragment" .. colour, "Artifact" .. colour }) do
			if ItemCatalog.Get(id) == nil then
				table.insert(issues, ("reward id not catalogued: %s"):format(id))
			end
		end
	end
	return #issues == 0, issues
end

return ChallengeConfig
