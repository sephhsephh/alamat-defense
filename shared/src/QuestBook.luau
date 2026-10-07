--!strict
-- QuestBook (SHARED CANON, both Places) -- B123. Deploy path ReplicatedStorage.Shared.QuestBook.
--
-- The `Data.Quests` BOOKKEEPING -- box reshape, period boxes, baselines, claim marking, pins -- extracted
-- verbatim from the Lobby's QuestService (B109) so the GAME's Quests screen (K, B123 user: "view, pin and
-- claim") keeps exactly the same `Data.Quests` shape. The RULES (which quests are current, progress,
-- claimed?) were already shared in `Configs.Meta.QuestRegistry`. What stays per Place:
--   * the GRANT   -- Lobby: GrantService.Grant;  Game: Server.Meta.MatchQuestService's PlayerInventoryService path
--   * the counter BUMP (DailyQuestsClaimed) and the pin display META (Lobby knows achievements / events)
--   * the remotes, the in-flight guard and the [DATA] logging
-- Shape (B109): Data.Quests = { Daily = { Slot, Base, Claimed }, Weekly = { ... }, Pins = { keys }, PinMeta, Ach }.
-- Baselines are taken ONCE per quest per period and never rewritten. Claims: GRANT FIRST, MARK SECOND.

local RS = game:GetService("ReplicatedStorage")
local QuestRegistry = require(RS:WaitForChild("Configs"):WaitForChild("Meta"):WaitForChild("QuestRegistry")) :: any

local QuestBook = {}

QuestBook.MAX_PINS = 100

function QuestBook.Box(data: any): any
	local box = data.Quests
	if type(box) ~= "table" then
		box = {}
		data.Quests = box
	end
	-- B40 -> B109 reshape: the old daily-roll fields mean nothing now.
	box.Progress, box.Claimed, box.PinnedQuestId = nil, nil, nil
	if type(box.Pins) ~= "table" then box.Pins = {} end
	return box
end

function QuestBook.Period(box: any, period: string, slot: number): any
	local p = box[period]
	if type(p) ~= "table" or tonumber(p.Slot) ~= slot then
		p = { Slot = slot, Base = {}, Claimed = {} }
		box[period] = p
	end
	if type(p.Base) ~= "table" then p.Base = {} end
	if type(p.Claimed) ~= "table" then p.Claimed = {} end
	return p
end

-- Record a baseline for every counter quest of the current day + week that has none yet.
function QuestBook.EnsureBaselines(data: any)
	local box = QuestBook.Box(data)
	local day, week = QuestRegistry.CurrentDay(), QuestRegistry.CurrentWeek()
	local d = QuestBook.Period(box, "Daily", day)
	for _, q in ipairs(QuestRegistry.DailyList(day)) do
		if q.Counter and d.Base[q.Id] == nil then
			d.Base[q.Id] = QuestRegistry.Counter(data, q.Counter)
		end
	end
	local w = QuestBook.Period(box, "Weekly", week)
	for _, q in ipairs(QuestRegistry.WeeklyList(week)) do
		if q.Counter and w.Base[q.Id] == nil then
			w.Base[q.Id] = QuestRegistry.Counter(data, q.Counter)
		end
	end
end

-- Claim one CURRENT quest. `grant(rewards) -> (ok, views, err)` pays it; `bump(counterKey, n)` ticks a
-- lifetime counter. Returns (ok, views | reason, quest?, progress?, grantErr?).
function QuestBook.Claim(data: any, questId: string, grant: (any) -> (boolean, any, any), bump: (string, number) -> ()): (boolean, any, any, number?, any)
	local q, slot = QuestRegistry.FindCurrent(questId)
	if q == nil or slot == nil then
		return false, "not_current"
	end
	if QuestRegistry.IsClaimed(data, q, slot) then
		return false, "already_claimed"
	end
	local progress = QuestRegistry.ProgressOf(data, q, slot)
	if progress < q.Target then
		return false, "not_complete"
	end
	local ok, views, err = grant(q.Reward)
	if not ok then
		return false, "grant_failed", q, progress, err
	end
	local box = QuestBook.Box(data)
	QuestBook.Period(box, q.Period, slot).Claimed[q.Id] = true
	if q.Period == "Daily" and q.Counter ~= "DailyQuestsClaimed" then
		bump("DailyQuestsClaimed", 1)
	end
	-- Claiming a quest unpins it (pt18 rule, kept).
	local key = "Q:" .. q.Id
	for i = #box.Pins, 1, -1 do
		if box.Pins[i] == key then table.remove(box.Pins, i) end
	end
	return true, views, q, progress
end

-- Claim every claimable quest in a tab ("All" | "Daily" | "Weekly"). Loops until nothing more is claimable,
-- so "Complete 6 daily quests" is collected in the same click as the quests that finish it.
-- `claimOne(questId) -> (ok, views)`. Returns (count, rewards).
function QuestBook.ClaimAll(data: any, tab: any, claimOne: (string) -> (boolean, any)): (number, { any })
	local want = if tab == "Daily" or tab == "Weekly" then tab else "All"
	local rewards, count = {}, 0
	for _ = 1, 4 do
		local st = QuestRegistry.State(data)
		local claimedAny = false
		for _, period in ipairs({ "Daily", "Weekly" }) do
			if want == "All" or want == period then
				for _, v in ipairs(st[period]) do
					if v.CanClaim then
						local ok, views = claimOne(v.Id)
						if ok then
							count += 1
							claimedAny = true
							for _, r in ipairs(views) do table.insert(rewards, r) end
						end
					end
				end
			end
		end
		if not claimedAny then break end
	end
	return count, rewards
end

-- Pin / unpin one key ("Q:id", "A:id", "E:event:quest"). Unlimited (user), capped for profile size.
-- `metaFor(key) -> record?` = the Place's display record for non-quest pins (Data.Quests.PinMeta).
function QuestBook.SetPin(data: any, key: any, on: any, metaFor: (string) -> any): any
	if type(key) ~= "string" or #key > 80 or not (key:match("^Q:") or key:match("^A:") or key:match("^E:")) then
		return { ok = false, reason = "bad_key" }
	end
	local box = QuestBook.Box(data)
	local pins = box.Pins
	if type(box.PinMeta) ~= "table" then box.PinMeta = {} end
	local idx = table.find(pins, key)
	if on == true and idx == nil then
		if #pins >= QuestBook.MAX_PINS then
			return { ok = false, reason = "too_many_pins" }
		end
		table.insert(pins, key)
		box.PinMeta[key] = metaFor(key)
	elseif on ~= true and idx ~= nil then
		table.remove(pins, idx)
		box.PinMeta[key] = nil
	end
	return { ok = true, Pins = table.clone(pins) }
end

-- PinMeta follows Pins -- backfill records for older pins, drop records whose pin is gone (claimed).
function QuestBook.SyncPinMeta(data: any, metaFor: (string) -> any)
	local box = QuestBook.Box(data)
	if type(box.PinMeta) ~= "table" then box.PinMeta = {} end
	local live = {}
	for _, key in ipairs(box.Pins) do
		live[key] = true
		if box.PinMeta[key] == nil and string.sub(key, 1, 2) ~= "Q:" then box.PinMeta[key] = metaFor(key) end
	end
	for key in pairs(box.PinMeta) do
		if not live[key] then box.PinMeta[key] = nil end
	end
end

return QuestBook
