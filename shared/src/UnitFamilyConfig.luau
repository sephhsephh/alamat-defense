--!strict
-- UnitFamilyConfig (LOBBY-LOCAL canon, owner AD-Lobby -- see docs/systems/lobby-ui.md)
--
-- Groups a base tower with its EVOLVED forms so the loadout can enforce **one unit per FAMILY**
-- (user rule, 2026-08-09): a Warchief and a "Warchief(Warlord)" are the same fighter at different
-- power levels, and fielding both at once is not a team, it is a duplicate.
--
-- ===== WHY THIS EXISTS AT ALL =====
-- Evolutions are Phase F (`Configs/Evolutions/<TowerId>.luau` with a `ResultTowerId`), so the real
-- base->evolved linkage DOES NOT EXIST YET. Rather than block the loadout rule on Phase F, or bake
-- a guess into `ItemCatalog` (SHARED canon -- changing it makes the Game place stale and needs a
-- both-Places deploy), the mapping lives here, Lobby-local, where the only writer of `Data.Loadout`
-- can read it.
--
-- **WHEN PHASE F LANDS:** point `FamilyOf` at the Evolutions registry and delete `Overrides`. That
-- is the whole migration -- every caller already goes through `FamilyOf`.
--
-- ===== RESOLUTION ORDER =====
--   1. `Overrides[towerId]`  -- explicit wins, always
--   2. the naming convention -- everything before a "(" or a "_", trimmed
--   3. the towerId itself    -- a tower with no evolution is its own family
--
-- The convention is a CONVENIENCE so "Warchief(Warlord)" groups correctly the moment it is
-- catalogued, without anyone remembering to edit this file. It is NOT authoritative: if a tower id
-- ever legitimately contains a bracket for another reason, add an Override and it wins.

local UnitFamilyConfig = {}

-- Explicit towerId -> family. The family key is conventionally the BASE tower's id.
-- Empty today because no evolved tower is catalogued yet -- the convention covers the named
-- example ("Warchief(Warlord)" -> "Warchief") without an entry.
UnitFamilyConfig.Overrides = {} :: { [string]: string }

function UnitFamilyConfig.FamilyOf(towerId: string): string
	if type(towerId) ~= "string" or towerId == "" then
		return ""
	end
	local override = UnitFamilyConfig.Overrides[towerId]
	if override then
		return override
	end
	-- "Warchief(Warlord)" -> "Warchief";  "Warchief_Warlord" -> "Warchief"
	local base = string.match(towerId, "^([^%(_]+)")
	if base then
		base = string.gsub(base, "%s+$", "")
		if base ~= "" then
			return base
		end
	end
	return towerId
end

-- Do these two towers occupy the same loadout family?
function UnitFamilyConfig.SameFamily(a: string, b: string): boolean
	return UnitFamilyConfig.FamilyOf(a) == UnitFamilyConfig.FamilyOf(b)
end

return UnitFamilyConfig
