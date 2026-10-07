--!strict
-- LoadoutRules (SHARED CANON, both Places) -- B123. Deploy path ReplicatedStorage.Shared.LoadoutRules.
--
-- THE rules for writing `Data.Loadout` and `Data.UnitTeams`, extracted verbatim from the Lobby's
-- LoadoutService so the GAME's pre-wave Units screen (B123, user: "players are able to change units
-- while game hasnt started yet") writes the loadout by the SAME rules instead of a second copy:
--   * a dense list of OWNED uuids, no duplicates, never past LoadoutConfig.MaxSlots
--   * slots must be unlocked at the player's CURRENT account level
--   * ONE UNIT PER FAMILY (user rule, 2026-08-09): a same-family newcomer REPLACES the incumbent in its slot
--   * saved teams: exactly MAX_TEAMS rows of { Name, Units }
-- `Data.Loadout` is a schema-v2 CONTRACT field (`{ string }`, dense) read by the match launcher -- see the
-- SCHEMA SAFETY note in Server.Lobby.LoadoutService before changing anything here.
--
-- Pure: no services, no remotes, no prints. Every function takes the profile `data` table (or parts of
-- it) and the caller (LoadoutService in the Lobby, UnitsScreenService in the Game) owns logging, the
-- profile lookup and the busy guard. Requires LoadoutConfig + UnitFamilyConfig (both shared canon).

local RS = game:GetService("ReplicatedStorage")
local LoadoutConfig = require(RS:WaitForChild("Configs"):WaitForChild("Meta"):WaitForChild("LoadoutConfig")) :: any
local UnitFamilyConfig = require(RS:WaitForChild("Configs"):WaitForChild("Meta"):WaitForChild("UnitFamilyConfig")) :: any

local LoadoutRules = {}

LoadoutRules.MAX_TEAMS = 5
LoadoutRules.TEAM_NAME_MAX = 20

-- Dense list in, dense list out. Strings only -- anything else is dropped rather than stored.
function LoadoutRules.Clean(list: { any }?, ownedUnits: { [string]: any }): { string }
	local out = {}
	local seen: { [string]: boolean } = {}
	for _, v in ipairs(list or {}) do
		if type(v) == "string" and v ~= "" and ownedUnits[v] ~= nil and not seen[v] then
			seen[v] = true
			table.insert(out, v)
			if #out >= LoadoutConfig.MaxSlots then
				break
			end
		end
	end
	return out
end

-- One slot. Returns the RESULT table the client renders; on ok it has already written data.Loadout.
-- `ReplacedUuid` is set when a same-family unit was swapped out, so the UI can SAY so.
function LoadoutRules.SetSlot(data: any, slotIndex: any, uuid: any): any
	if type(slotIndex) ~= "number" or slotIndex % 1 ~= 0
		or slotIndex < 1 or slotIndex > LoadoutConfig.MaxSlots then
		return { ok = false, reason = "bad_slot" }
	end

	local level = data.PlayerLevel or 1
	local unlocked = LoadoutConfig.UnlockedSlots(level)
	if not LoadoutConfig.IsSlotUnlocked(slotIndex, level) then
		return {
			ok = false, reason = "slot_locked",
			RequiredLevel = LoadoutConfig.RequiredLevel(slotIndex),
			PlayerLevel = level,
		}
	end

	-- Start from the stored list, dropping anything no longer owned (units can be sold later).
	local slots = LoadoutRules.Clean(data.Loadout, data.Units)
	local replacedUuid: string? = nil
	local family: string? = nil

	if uuid == nil or uuid == false then
		-- clear: remove whatever currently sits at this position, if anything
		if slots[slotIndex] ~= nil then
			table.remove(slots, slotIndex)
		end
	else
		if type(uuid) ~= "string" then
			return { ok = false, reason = "bad_uuid" }
		end
		if data.Units[uuid] == nil then
			return { ok = false, reason = "not_owned" }
		end
		-- ONE PER FAMILY: if another unit of the same family is equipped, the newcomer takes ITS
		-- slot. Done BEFORE the self-removal below so `replacedAt` is the incumbent's real index.
		family = UnitFamilyConfig.FamilyOf(data.Units[uuid].TowerId)
		local replacedAt: number? = nil
		for i = #slots, 1, -1 do
			local other = slots[i]
			if other ~= uuid then
				local rec = data.Units[other]
				if rec and UnitFamilyConfig.FamilyOf(rec.TowerId) == family then
					replacedAt, replacedUuid = i, other
					table.remove(slots, i)
				end
			end
		end
		-- a unit lives in exactly one slot: remove it from wherever it was first
		for i = #slots, 1, -1 do
			if slots[i] == uuid then
				table.remove(slots, i)
			end
		end
		-- dense list: never write past the end, and never past what the level allows.
		-- A family replacement lands in the slot it freed, so the swap looks like a swap.
		local target = math.min(replacedAt or slotIndex, #slots + 1, unlocked)
		table.insert(slots, target, uuid)
		while #slots > unlocked do
			table.remove(slots)
		end
	end

	data.Loadout = slots
	return {
		ok = true,
		Loadout = slots,
		UnlockedSlots = unlocked,
		PlayerLevel = level,
		MaxSlots = LoadoutConfig.MaxSlots,
		ReplacedUuid = replacedUuid,
		Family = family,
	}
end

-- A whole list (UNEQUIP ALL, LOAD TEAM): owned + de-duplicated, ONE PER FAMILY (the first of a family
-- wins -- a saved team cannot sneak two of the same unit in), capped at the unlocked slots. Writes
-- data.Loadout and returns (list, unlocked, level).
function LoadoutRules.ApplyList(data: any, list: { any }?): ({ string }, number, number)
	local level = data.PlayerLevel or 1
	local unlocked = LoadoutConfig.UnlockedSlots(level)
	local out, families = {}, {}
	for _, u in ipairs(LoadoutRules.Clean(list, data.Units)) do
		local fam = UnitFamilyConfig.FamilyOf(data.Units[u].TowerId)
		if not families[fam] then
			families[fam] = true
			table.insert(out, u)
			if #out >= unlocked then break end
		end
	end
	data.Loadout = out
	return out, unlocked, level
end

-- `Data.UnitTeams` (schema v10): dense, exactly MAX_TEAMS rows, each { Name, Units } -- JSON-safe.
function LoadoutRules.TeamsOf(data: any): { any }
	if type(data.UnitTeams) ~= "table" then data.UnitTeams = {} end
	for i = 1, LoadoutRules.MAX_TEAMS do
		local t = data.UnitTeams[i]
		if type(t) ~= "table" then
			data.UnitTeams[i] = { Name = "", Units = {} }
		else
			if type(t.Name) ~= "string" then t.Name = "" end
			if type(t.Units) ~= "table" then t.Units = {} end
		end
	end
	for i = #data.UnitTeams, LoadoutRules.MAX_TEAMS + 1, -1 do table.remove(data.UnitTeams, i) end
	return data.UnitTeams
end

-- What the client sees: names defaulted, and every team re-cleaned against the units the player
-- still owns (a sold unit simply drops out of the saved team's view).
function LoadoutRules.TeamsView(data: any): { any }
	local out = {}
	for i, t in ipairs(LoadoutRules.TeamsOf(data)) do
		out[i] = { Name = if t.Name ~= "" then t.Name else ("Team #" .. i), Units = LoadoutRules.Clean(t.Units, data.Units) }
	end
	return out
end

function LoadoutRules.TeamIndex(i: any): number?
	if type(i) ~= "number" or i % 1 ~= 0 or i < 1 or i > LoadoutRules.MAX_TEAMS then return nil end
	return i
end

-- Control characters stripped and trimmed; nil when too long. The caller still runs the Roblox text
-- FILTER (it yields) before storing.
function LoadoutRules.TrimTeamName(name: any): string?
	if type(name) ~= "string" then return nil end
	name = string.gsub(string.gsub(name, "[%c]", ""), "^%s*(.-)%s*$", "%1")
	local n = utf8.len(name)
	if n == nil or n > LoadoutRules.TEAM_NAME_MAX then return nil end
	return name
end

return LoadoutRules
