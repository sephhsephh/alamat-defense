--!strict
-- Server.Admin.AdminGlobal (SHARED CANON, both Places) -- B108 pt12 (user: admin panel + "admin abuse").
--
-- The CROSS-SERVER half of the admin tools. Everything that must reach every running server lives here:
--   * ANNOUNCEMENTS  -- MessagingService topic `AlamatAdmin_v1`; each server that hears one fires
--                       Remotes.AdminBroadcast to its own players (the banner). Also used for a buff start/stop.
--   * GLOBAL BUFFS   -- MemoryStore sorted map `AlamatAdminBuffs_v1`, one key per kind ("Luck", "Rewards"),
--                       stored with an EXPIRATION equal to the buff's duration, so a buff ends by itself even if
--                       every server restarts. Each server caches the map (refresh every 20s + on a message).
--   * GLOBAL GIFTS   -- MemoryStore sorted map `AlamatAdminGifts_v1`: "everyone in every server gets X" for a
--                       window. The LOBBY's AdminService grants each gift once per player (on join or when the
--                       gift is announced) and records it; the Game only reads buffs and shows announcements.
--
-- SECURITY: this module is SERVER-ONLY (ServerScriptService, never replicated) and exposes no remote. The
-- only client-facing object is Remotes.AdminBroadcast, which the server FIRES and never listens to. Who may
-- CALL the write functions below is decided by the Lobby's AdminService (UserId allowlist), not here.
-- Incoming MessagingService payloads come only from this universe's own servers, but are still type-checked.

local MessagingService = game:GetService("MessagingService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local TOPIC = "AlamatAdmin_v1"
local REFRESH_SEC = 20

local AdminGlobal = {}

-- Buff kinds an admin can start globally. `Min`/`Max` bound the value the server will accept.
--   Luck    -- +N% summon luck (added on top of a player's own Luck buff; LuckService reads LuckPercent()).
--   Rewards -- xN match rewards, XP and drops (the Game's RewardCalculator reads RewardMult()).
AdminGlobal.Kinds = {
	Luck = { Title = "Admin Abuse: Luck", Min = 10, Max = 1000, Format = "+%d%% Luck" },
	Rewards = { Title = "Admin Abuse: Rewards", Min = 1.5, Max = 10, Format = "x%s Rewards" },
}
AdminGlobal.MaxMinutes = 240

local buffMap: any = nil
local giftMap: any = nil
pcall(function() buffMap = MemoryStoreService:GetSortedMap("AlamatAdminBuffs_v1") end)
pcall(function() giftMap = MemoryStoreService:GetSortedMap("AlamatAdminGifts_v1") end)

local broadcast: RemoteEvent? = nil
do
	local remotes = RS:WaitForChild("Remotes", 10)
	local ev = remotes and remotes:WaitForChild("AdminBroadcast", 10)
	if ev and ev:IsA("RemoteEvent") then broadcast = ev end
end

-- ===== local signals (server-side only) =====
local giftAdded = Instance.new("BindableEvent")
AdminGlobal.GiftAdded = giftAdded.Event -- (giftId)
local buffsChanged = Instance.new("BindableEvent")
AdminGlobal.BuffsChanged = buffsChanged.Event

-- ===== buff cache =====
local cache: { [string]: any } = {}

local function refreshBuffs()
	if buffMap == nil then return end
	local ok, items = pcall(function() return buffMap:GetRangeAsync(Enum.SortDirection.Ascending, 20) end)
	if not ok or type(items) ~= "table" then return end
	local fresh = {}
	local now = os.time()
	for _, it in ipairs(items) do
		local v = it.value
		if type(v) == "table" and AdminGlobal.Kinds[it.key] and tonumber(v.EndsAt) and v.EndsAt > now then
			fresh[it.key] = v
		end
	end
	cache = fresh
	buffsChanged:Fire()
end

function AdminGlobal.ActiveBuffs(): { any }
	local out = {}
	local now = os.time()
	for kind, v in pairs(cache) do
		if (tonumber(v.EndsAt) or 0) > now then
			table.insert(out, { Kind = kind, Value = v.Value, EndsAt = v.EndsAt, SecondsLeft = v.EndsAt - now, By = v.By, Title = AdminGlobal.Kinds[kind].Title })
		end
	end
	table.sort(out, function(a, b) return a.Kind < b.Kind end)
	return out
end

local function valueOf(kind: string): number?
	local v = cache[kind]
	if v and (tonumber(v.EndsAt) or 0) > os.time() then return tonumber(v.Value) end
	return nil
end

-- +N percent summon luck from an active global Luck buff (0 when none).
function AdminGlobal.LuckPercent(): number
	return valueOf("Luck") or 0
end

-- The reward multiplier from an active global Rewards buff (1 when none).
function AdminGlobal.RewardMult(): number
	return valueOf("Rewards") or 1
end

-- ===== publishing =====
local function publish(payload: any): (boolean, string?)
	local okEnc, json = pcall(HttpService.JSONEncode, HttpService, payload)
	if not okEnc then return false, "encode_failed" end
	if #json > 1000 then return false, "message_too_long" end
	local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, json) end)
	if not ok then
		warn("[AdminGlobal] PublishAsync failed: " .. tostring(err))
		return false, "publish_failed"
	end
	return true
end

local function fireLocal(payload: any)
	if broadcast then broadcast:FireAllClients(payload) end
end

-- scope "server" shows it here only; "global" reaches every server (this one included, via the topic).
function AdminGlobal.Announce(text: string, color: string, seconds: number, scope: string, by: string): (boolean, string?)
	local payload = { k = "announce", text = text, color = color, seconds = seconds, by = by, scope = scope }
	if scope == "global" then
		local ok, why = publish(payload)
		if not ok then
			fireLocal(payload) -- at least this server sees it
			return false, why
		end
		return true
	end
	fireLocal(payload)
	return true
end

function AdminGlobal.StartBuff(kind: string, value: number, minutes: number, by: string): (boolean, string?)
	if buffMap == nil then return false, "memorystore_unavailable" end
	local now = os.time()
	local entry = { Value = value, EndsAt = now + math.floor(minutes * 60), StartedAt = now, By = by }
	local ok, err = pcall(function() buffMap:SetAsync(kind, entry, math.floor(minutes * 60)) end)
	if not ok then
		warn("[AdminGlobal] StartBuff failed: " .. tostring(err))
		return false, "memorystore_failed"
	end
	cache[kind] = entry
	publish({ k = "buffs" })
	return true
end

function AdminGlobal.StopBuff(kind: string): (boolean, string?)
	if buffMap == nil then return false, "memorystore_unavailable" end
	local ok, err = pcall(function() buffMap:RemoveAsync(kind) end)
	if not ok then return false, "memorystore_failed: " .. tostring(err) end
	cache[kind] = nil
	publish({ k = "buffs" })
	return true
end

-- ===== gifts =====
-- gift = { Id = "<guid>", Rewards = { {Id=,Qty=} | {TowerId=,Qty=,Shiny=,Trait=} }, EndsAt = os.time()+window, By = name }
function AdminGlobal.PublishGift(gift: any, windowSec: number): (boolean, string?)
	if giftMap == nil then return false, "memorystore_unavailable" end
	local ok, err = pcall(function() giftMap:SetAsync(gift.Id, gift, math.floor(windowSec)) end)
	if not ok then return false, "memorystore_failed: " .. tostring(err) end
	publish({ k = "gift", id = gift.Id })
	return true
end

function AdminGlobal.ActiveGifts(): { any }
	if giftMap == nil then return {} end
	local ok, items = pcall(function() return giftMap:GetRangeAsync(Enum.SortDirection.Ascending, 50) end)
	if not ok or type(items) ~= "table" then return {} end
	local out = {}
	local now = os.time()
	for _, it in ipairs(items) do
		local v = it.value
		if type(v) == "table" and type(v.Id) == "string" and type(v.Rewards) == "table" and (tonumber(v.EndsAt) or 0) > now then
			table.insert(out, v)
		end
	end
	return out
end

-- ===== subscription =====
task.spawn(function()
	local ok, err = pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(msg)
			local okDec, p = pcall(HttpService.JSONDecode, HttpService, msg.Data)
			if not okDec or type(p) ~= "table" then return end
			if p.k == "announce" and type(p.text) == "string" then
				fireLocal({
					k = "announce",
					text = string.sub(p.text, 1, 300),
					color = if type(p.color) == "string" then p.color else "Gold",
					seconds = math.clamp(tonumber(p.seconds) or 8, 3, 30),
					by = if type(p.by) == "string" then string.sub(p.by, 1, 40) else "Admin",
					scope = "global",
				})
			elseif p.k == "buffs" then
				refreshBuffs()
				fireLocal({ k = "buffs" })
			elseif p.k == "gift" and type(p.id) == "string" then
				giftAdded:Fire(p.id)
			end
		end)
	end)
	if not ok then warn("[AdminGlobal] SubscribeAsync failed: " .. tostring(err)) end
end)

task.spawn(function()
	while true do
		refreshBuffs()
		task.wait(REFRESH_SEC)
	end
end)

print("[DATA] AdminGlobal ready (topic " .. TOPIC .. "; global buffs + gifts in MemoryStore; announcements via Remotes.AdminBroadcast).")

return AdminGlobal
