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

ProfileTemplate.SCHEMA_VERSION = 4
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

-- A player's stored pick on a Selection banner (schema v3, B29). Blueprint B4's shape, unchanged.
-- `ChosenAtDay` is a `MetaMath.Slot(86400, MetaConfig.ResetOffsetSec)` DAY NUMBER, **not a
-- timestamp** -- that is precisely what makes `Featured.ChoiceCooldown` agree across servers with
-- no stored clock (cross-phase invariant 3). The cooldown test is
-- `currentDay - ChosenAtDay >= cooldownDays`. Do not "improve" this into os.time().
export type BannerChoice = {
	TowerId: string,
	ChosenAtDay: number,
}

-- A per-EVENT daily-reward streak (schema v4, B39). Same two fields as the base `LoginStreak` and
-- the same rules from `DailyRewardConfig`, kept in a SEPARATE top-level key rather than nested
-- inside `LoginStreak` for one reason: a top-level additive key is unambiguously covered by
-- `Reconcile()`, which is what makes the v3 -> v4 migration a no-op. `LastClaimDayNumber` is a
-- `MetaMath.Slot` DAY NUMBER, never a timestamp (cross-phase invariant 3).
export type EventStreak = {
	Day: number,
	LastClaimDayNumber: number,
}

export type ProfileData = {
	SchemaVersion: number,
	PlayerXP: number,
	PlayerLevel: number,
	Currencies: { Gold: number, Silver: number, TraitRerolls: number, StatRerolls: number, EventTokens: { [string]: number } },
	Items: { [string]: number },
	Units: { [string]: UnitInstance },
	Loadout: { string },
	Pity: { [string]: { Legendary: number, Mythic: number, Secret: number } },
	BannerChoices: { [string]: BannerChoice }, -- v3: keyed by bannerId; Selection banners only
	Counters: { Global: { [string]: any }, PerUnit: { [string]: { [string]: number } } },
	Quests: { Progress: { [string]: any }, Claimed: { [string]: any }, PinnedQuestId: string? },
	LoginStreak: { Day: number, LastClaimDayNumber: number },
	-- v4 (B39), keyed by eventId. The base LoginStreak above is the NON-event 7-day track.
	EventLoginStreaks: { [string]: EventStreak },
	-- v4 (B39): redeemed promo codes, keyed by the UPPERCASED code, value = the MetaMath DAY NUMBER
	-- it was redeemed on. A DAY NUMBER and not a timestamp so "one per day" style codes agree across
	-- servers with no stored clock, exactly like BannerChoice.ChosenAtDay.
	RedeemedCodes: { [string]: number },
	-- v4 (B39): rewards granted while the player was NOT in a server, waiting to be REVEALED on
	-- their next join. The grant itself already happened and is already reflected in the balances
	-- above -- this queue is PRESENTATION ONLY, and draining it must never grant anything.
	-- `Dropped` counts rows the cap refused, so the drain can say "+N more" instead of lying by
	-- omission. See docs/systems/rewards.md.
	PendingReveals: { Queue: { any }, Dropped: number },
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
	BannerChoices = {},
	Counters = { Global = {}, PerUnit = {} },
	Quests = { Progress = {}, Claimed = {}, PinnedQuestId = nil },
	LoginStreak = { Day = 0, LastClaimDayNumber = 0 },
	EventLoginStreaks = {},
	RedeemedCodes = {},
	PendingReveals = { Queue = {}, Dropped = 0 },
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

-- v2 -> v3: add `BannerChoices`, the Selection banner's per-player stored pick (blueprint B4).
-- *** THIS STEP IS A DELIBERATE NO-OP AND MUST STAY ONE. ***
-- `BannerChoices` is an ADDITIVE-OPTIONAL key, and ProfileStore's `Reconcile()` runs BEFORE
-- `Migrate()`, so by the time this executes the key is already present as an empty table. There is
-- genuinely nothing to convert. The step exists anyway because `Migrate()` WARNS AND STOPS at a
-- missing step -- a silent gap at v2->v3 would strand every migration added after it. Do not delete
-- it, and do not "fill it in" later: a new shape change gets its OWN step (rule 3 above -- never
-- remove or repurpose an existing migration).
ProfileTemplate.Migrations[2] = function(_data)
	-- intentionally empty; see above
end

-- v3 -> v4: add `EventLoginStreaks`, `RedeemedCodes` and `PendingReveals` (B39).
-- *** ALSO A DELIBERATE NO-OP, FOR THE SAME REASON AS v2 -> v3. ***
-- All three are ADDITIVE-OPTIONAL top-level keys, and `Reconcile()` runs BEFORE `Migrate()`, so by
-- the time this executes each one is already present with its template default. There is nothing to
-- convert. The step exists because `Migrate()` WARNS AND STOPS at a missing step, so a gap here
-- would strand every migration added after it.
--
-- ONE BUMP, THREE SYSTEMS, ON PURPOSE. Event daily rewards, promo codes and the offline reveal queue
-- each needed a profile field. Three separate bumps would have meant three migration steps and three
-- both-Places publishes for changes that are individually free -- the cost of a schema bump is the
-- PUBLISH, not the field. If a fourth system needs a field before v4 ships, add it HERE rather than
-- opening v5.
ProfileTemplate.Migrations[3] = function(_data)
	-- intentionally empty; see above
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
