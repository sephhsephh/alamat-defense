--!strict
-- ProfileTemplate.lua (SHARED CONTRACT -- owner: Game place)
-- THE save-schema contract for the entire Experience. Every Place (Game, future Lobby,
-- Tutorial, ...) must use THIS module as the single definition of what lives inside a
-- player profile. ProfileStore deep-copies Template for new players and Reconcile()
-- fills missing keys on old profiles.
--
-- CHANGE PROTOCOL (do not skip):
--   1. Any shape change bumps SCHEMA_VERSION by exactly 1.
--   2. Add a Migrations[oldVersion] step that upgrades data in place.
--   3. Never remove or repurpose an existing migration step.
--   4. Update docs/contracts/save-schema.md and mark PENDING for other Places.
--
-- DATA RULES (ProfileStore requirements): JSON-safe only -- no Instances, no userdata
-- (Vector3/Color3/CFrame), no mixed or gappy numeric tables, string/number keys only.

local ProfileTemplate = {}

ProfileTemplate.SCHEMA_VERSION = 2
ProfileTemplate.STORE_NAME = "Beta1_PlayerData" -- one store for the whole Experience (production)

-- Live store name. In Studio ALL data goes to a separate dev store, so playtests and
-- dev seeds can never touch production player data. Same rule in every Place.
function ProfileTemplate.GetStoreName(): string
	if game:GetService("RunService"):IsStudio() then
		return ProfileTemplate.STORE_NAME .. "Dev1"
	end
	return ProfileTemplate.STORE_NAME
end

-- A single owned tower INSTANCE (schema v2). Units are keyed by uuid, so a player can own
-- several of the same TowerId, each with its own rolls / trait / ascension.
export type UnitInstance = {
	TowerId: string,
	MetaLevel: number,
	XP: number,
	Trait: string?,
	Shiny: boolean,
	StatRolls: { DMG: number, RNG: number, SPA: number }, -- each a 0..1 position in the stat range (A3 resolver)
	Ascension: number,   -- 0..3, Mythic+ only (AscensionConfig, phase C)
	Worthiness: number,  -- 0..100 (phase C)
	Locked: boolean,
	Favorited: boolean,
	SpiritUuid: string?,
	ObtainedAt: number,
}

-- Alias kept for readers that still think in the v1 record shape (MetaLevel / XP / Trait).
export type OwnedTower = UnitInstance

export type ProfileData = {
	SchemaVersion: number,
	PlayerXP: number,
	PlayerLevel: number,
	Currencies: { Gold: number, Silver: number, TraitRerolls: number, StatRerolls: number, EventTokens: { [string]: number } },
	Items: { [string]: number },
	Units: { [string]: UnitInstance },
	Loadout: { string },
	Pity: { [string]: { Legendary: number, Mythic: number, Secret: number } },
	Counters: { Global: { [string]: any }, PerUnit: { [string]: { [string]: number } } },
	Quests: { Progress: { [string]: any }, Claimed: { [string]: any }, PinnedQuestId: string? },
	LoginStreak: { Day: number, LastClaimDayNumber: number },
	ShopStock: { DayNumber: number, Bought: { [string]: any } },
	Titles: { Owned: { [string]: any }, Equipped: string? },
	Spirits: { [string]: { SpiritId: string, ObtainedAt: number } },
	Battlepass: { SeasonId: string, XP: number, Owned: boolean, ClaimedFree: { [string]: any }, ClaimedPaid: { [string]: any } },
	Settings: { [string]: any },
}

-- New players start with NO units. The Lobby's first-join starter choice grants the first
-- unit (eligibility = profile owns zero units), so Units MUST stay empty or the picker never
-- fires. See docs/proposals/2026-07-18-starter-choice-template.md.
ProfileTemplate.Template = {
	SchemaVersion = ProfileTemplate.SCHEMA_VERSION,
	PlayerXP = 0,
	PlayerLevel = 1,
	Currencies = { Gold = 0, Silver = 0, TraitRerolls = 0, StatRerolls = 0, EventTokens = {} },
	Items = {},
	Units = {},
	Loadout = {},
	Pity = {},
	Counters = { Global = {}, PerUnit = {} },
	Quests = { Progress = {}, Claimed = {}, PinnedQuestId = nil },
	LoginStreak = { Day = 0, LastClaimDayNumber = 0 },
	ShopStock = { DayNumber = 0, Bought = {} },
	Titles = { Owned = {}, Equipped = nil },
	Spirits = {},
	Battlepass = { SeasonId = "", XP = 0, Owned = false, ClaimedFree = {}, ClaimedPaid = {} },
	Settings = {},
}

-- Migrations[fromVersion] mutates data from fromVersion to fromVersion + 1.
ProfileTemplate.Migrations = {} :: { [number]: (data: any) -> () }

-- v1 -> v2: Currency scalar -> Currencies map; towerId-keyed Towers -> uuid-keyed Units
-- instances (mid stat rolls); add empty Loadout (auto-loadout rebuilds it). Reconcile() has
-- already filled every other new v2 key before this runs.
ProfileTemplate.Migrations[1] = function(data)
	local HttpService = game:GetService("HttpService")

	data.Currencies = {
		Gold = data.Currency or 0,
		Silver = 0,
		TraitRerolls = 0,
		StatRerolls = 0,
		EventTokens = {},
	}
	data.Currency = nil

	local units = {}
	for towerId, rec in pairs(data.Towers or {}) do
		local uuid = HttpService:GenerateGUID(false)
		units[uuid] = {
			TowerId = towerId,
			MetaLevel = rec.MetaLevel or 1,
			XP = rec.XP or 0,
			Trait = rec.Trait,
			Shiny = false,
			StatRolls = { DMG = 0.5, RNG = 0.5, SPA = 0.5 },
			Ascension = 0,
			Worthiness = 0,
			Locked = false,
			Favorited = false,
			SpiritUuid = nil,
			ObtainedAt = os.time(),
		}
	end
	data.Units = units
	data.Towers = nil

	data.Loadout = {}
end

-- Walks data forward to SCHEMA_VERSION. Returns the number of steps applied.
-- Reconcile() must run BEFORE this (it guarantees SchemaVersion exists on old profiles).
function ProfileTemplate.Migrate(data: any): number
	local steps = 0
	local v = data.SchemaVersion or 1
	while v < ProfileTemplate.SCHEMA_VERSION do
		local step = ProfileTemplate.Migrations[v]
		if not step then
			warn(string.format("[DATA] Missing migration step v%d -> v%d; data left at v%d", v, v + 1, v))
			break
		end
		step(data)
		v += 1
		data.SchemaVersion = v
		steps += 1
	end
	return steps
end

return ProfileTemplate
