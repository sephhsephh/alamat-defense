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

ProfileTemplate.SCHEMA_VERSION = 1
ProfileTemplate.STORE_NAME = "PlayerData" -- one store for the whole Experience

export type OwnedTower = {
	MetaLevel: number,
	XP: number,
	Trait: string?,
}

export type ProfileData = {
	SchemaVersion: number,
	PlayerXP: number,
	Currency: number,
	Items: { [string]: number },
	Towers: { [string]: OwnedTower },
	Settings: { [string]: any },
}

-- New players start with a level-1 Archer so a fresh account can always field a loadout.
ProfileTemplate.Template = {
	SchemaVersion = ProfileTemplate.SCHEMA_VERSION,
	PlayerXP = 0,
	Currency = 0,
	Items = {},
	Towers = {
		Archer = { MetaLevel = 1, XP = 0 },
	},
	Settings = {},
}

-- Migrations[fromVersion] mutates data from fromVersion to fromVersion + 1.
-- Example for a future v1 -> v2 change:
--   ProfileTemplate.Migrations[1] = function(data)
--       data.Pity = { BannerRolls = 0 }
--   end
ProfileTemplate.Migrations = {} :: { [number]: (data: any) -> () }

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
