--!strict
-- InfernalHuntConfig (SHARED CANON -- ReplicatedStorage.Configs.Meta.InfernalHuntConfig). B109 M5.
-- The Infernal Hunt LOOT EVENT (docs/systems/events.md): while the event runs, each eligible match has a
-- `SpawnChance` of a roaming Infernal boss appearing at a random wave in [WaveMin, WaveMax]. Killing it gives
-- every player in the match +1 boss and +1 Infernal Chest, up to `DailyLimit` per day. Bosses defeated during
-- the event feed a milestone track (claimed in the Lobby).
--   GAME  reads it to spawn the boss + credit kills (Server.Events.InfernalHuntService).
--   LOBBY reads it for the event card, the milestone track and opening chests (Server.Meta.InfernalHuntService).
-- Counters (cross-Place contract): Counters.Global.InfernalHunt = { Key, Total, Day, DayChests } (GAME writes);
-- Counters.Global.InfernalClaims = { Key, Claimed = { [i] = true } } (LOBBY writes). A new `EventKey` starts a
-- fresh track (old totals are ignored, never migrated).
-- *** PLACEHOLDER numbers + rewards (user edits). ***

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MetaMath = require(ReplicatedStorage.Shared.MetaMath)
local MetaConfig = require(ReplicatedStorage.Configs.Meta.MetaConfig)

local InfernalHuntConfig = {}

InfernalHuntConfig.Enabled = true
InfernalHuntConfig.EventKey = "InfernalHunt1"            -- change to start a new event track
InfernalHuntConfig.Window = nil :: { StartUtc: number?, EndUtc: number? }? -- nil = always on while Enabled

InfernalHuntConfig.BossEnemyId = "InfernalBoss"          -- Game EnemyConfigRegistry id
InfernalHuntConfig.SpawnChance = 0.35                    -- per eligible match
InfernalHuntConfig.WaveMin = 3
InfernalHuntConfig.WaveMax = 10
InfernalHuntConfig.Modes = { Story = true, Infinite = true, Challenge = true } -- user: Story/Infinite/Challenge

InfernalHuntConfig.DailyLimit = 15                       -- chests (and counted bosses) per day, per player
InfernalHuntConfig.ChestId = "InfernalChest"

-- Milestones over bosses defeated during the event (every 10, claim once each).
InfernalHuntConfig.Milestones = {
	{ Bosses = 10, Reward = { { Id = "EventCoin", Qty = 20 } } },
	{ Bosses = 20, Reward = { { Id = "InfernalChest", Qty = 1 } } },
	{ Bosses = 30, Reward = { { Id = "EventCoin", Qty = 30 } } },
	{ Bosses = 40, Reward = { { Id = "InfernalChest", Qty = 2 } } },
	{ Bosses = 50, Reward = { { Id = "EventCoin", Qty = 40 } } },
	{ Bosses = 60, Reward = { { Id = "InfernalChest", Qty = 2 } } },
	{ Bosses = 70, Reward = { { Id = "EventCoin", Qty = 45 } } },
	{ Bosses = 80, Reward = { { Id = "EventCoin", Qty = 50 } } },
	{ Bosses = 90, Reward = { { Id = "InfernalChest", Qty = 3 } } },
	{ Bosses = 100, Reward = { { Id = "EventCoin", Qty = 100 } } },
}

-- What one Infernal Chest rolls (one weighted pick per chest).
InfernalHuntConfig.ChestDrops = {
	{ Id = "TraitRerollToken", Qty = 1, Weight = 30 },
	{ Id = "StatRerolls", Qty = 2, Weight = 30 },
	{ Id = "FocusChip", Qty = 1, Weight = 15 },
	{ Id = "EventCoin", Qty = 5, Weight = 20 },
	{ Id = "MutyaRainbow", Qty = 1, Weight = 5 },
}

function InfernalHuntConfig.IsActive(nowSec: number?): boolean
	if not InfernalHuntConfig.Enabled then return false end
	local w = InfernalHuntConfig.Window
	if type(w) ~= "table" then return true end
	local now = nowSec or os.time()
	if w.StartUtc and now < w.StartUtc then return false end
	if w.EndUtc and now >= w.EndUtc then return false end
	return true
end

function InfernalHuntConfig.Day(nowSec: number?): number
	return MetaMath.Slot(MetaConfig.Periods.Daily, MetaConfig.ResetOffsetSec, nowSec)
end

-- The player's track for the CURRENT event key: total, today's chests (0 on a new day).
function InfernalHuntConfig.Track(data: any, nowSec: number?): (number, number)
	local c = type(data) == "table" and data.Counters or nil
	local g = type(c) == "table" and c.Global or nil
	local t = type(g) == "table" and g.InfernalHunt or nil
	if type(t) ~= "table" or t.Key ~= InfernalHuntConfig.EventKey then return 0, 0 end
	local today = if tonumber(t.Day) == InfernalHuntConfig.Day(nowSec) then tonumber(t.DayChests) or 0 else 0
	return tonumber(t.Total) or 0, today
end

return InfernalHuntConfig
