--!strict
-- TraitRegistry.lua
-- Trait id -> TraitConfig lookup, plus the weighted roll used by the Lobby's Trait Reroll
-- item. The roll lives here (not in the Lobby) so the Game place and Lobby share ONE
-- definition of trait rarity -- otherwise the two places would inevitably drift apart.

local TraitDefinitions = require(script.Parent.TraitDefinitions)

local TraitRegistry = {}

function TraitRegistry.Get(traitId: string?): any
	if not traitId then
		return TraitDefinitions.None
	end
	return TraitDefinitions[traitId] or TraitDefinitions.None
end

function TraitRegistry.GetAll(): { [string]: any }
	return TraitDefinitions
end

-- Returns the effective placement limit for a tower given its trait.
-- Trait override wins; otherwise fall back to the tower's own default.
function TraitRegistry.GetEffectivePlacementLimit(towerConfig: any, traitId: string?): number
	local trait = TraitRegistry.Get(traitId)
	if trait.PlacementLimitOverride then
		return trait.PlacementLimitOverride
	end
	return towerConfig.PlacementLimit or 99
end

-- Weighted random trait roll over the WHOLE table, "None" included. Kept for any caller that wants
-- the old behaviour; the Lobby's reroll uses `RollReroll` below (B73). SERVER ONLY.
function TraitRegistry.Roll(randomGenerator: Random?): string
	local rng = randomGenerator or Random.new()

	local totalWeight = 0
	for _, trait in pairs(TraitDefinitions) do
		totalWeight += (trait.Weight or 0)
	end

	local roll = rng:NextNumber(0, totalWeight)
	local cumulative = 0

	for traitId, trait in pairs(TraitDefinitions) do
		cumulative += (trait.Weight or 0)
		if roll <= cumulative then
			return traitId
		end
	end

	return "None"
end

-- ===== REROLLS ALWAYS LAND A TRAIT (B73, user) =====
-- "a trait should be guaranteed whenever using" -- spending a Trait Reroll must never hand back
-- "None". So the reroll pool is every trait EXCEPT "None", at its own Weight; "None" stays in the
-- table because it is still what an un-traited unit HAS. The odds are simply each Weight over the
-- rerollable total, so a trait added to TraitDefinitions later joins the pool (and dilutes the
-- others) with no code change -- which is what the user plans to do.
-- One definition used by the server roll AND the Trait Index, so the screen cannot advertise odds
-- the roll does not use.
TraitRegistry.NO_TRAIT = "None"

function TraitRegistry.IsRerollable(traitId: string?): boolean
	if traitId == nil or traitId == TraitRegistry.NO_TRAIT then
		return false
	end
	local def = TraitDefinitions[traitId]
	return def ~= nil and (def.Weight or 0) > 0
end

function TraitRegistry.RerollWeightTotal(): number
	local total = 0
	for id, def in pairs(TraitDefinitions) do
		if TraitRegistry.IsRerollable(id) then
			total += def.Weight
		end
	end
	return total
end

-- 0..1 chance that ONE reroll lands `traitId` (before Luck / pity).
function TraitRegistry.RerollChance(traitId: string?): number
	if not TraitRegistry.IsRerollable(traitId) then
		return 0
	end
	local total = TraitRegistry.RerollWeightTotal()
	if total <= 0 then
		return 0
	end
	return TraitDefinitions[traitId :: string].Weight / total
end

-- The reroll's weighted pick. Never returns "None" unless the table has NO rerollable trait at all,
-- which is a broken config -- warned loudly rather than silently spending a token on nothing.
-- MUST only ever be called on the SERVER -- a client-side roll is a free legendary.
function TraitRegistry.RollReroll(randomGenerator: Random?): string
	local rng = randomGenerator or Random.new()
	local total = TraitRegistry.RerollWeightTotal()
	if total <= 0 then
		warn("[CONTRACT] TraitRegistry.RollReroll: no rerollable trait has Weight > 0 -- returning None")
		return TraitRegistry.NO_TRAIT
	end
	local roll = rng:NextNumber(0, total)
	local cumulative = 0
	local last: string? = nil
	for id, def in pairs(TraitDefinitions) do
		if TraitRegistry.IsRerollable(id) then
			cumulative += def.Weight
			last = id
			if roll <= cumulative then
				return id
			end
		end
	end
	-- Float edge (roll == total after rounding): the last rerollable id visited, never "None".
	return last :: string
end

-- A "GOOD" trait (user, B73) = one with a pity meter. Landing one plays the special reveal.
function TraitRegistry.IsSpecial(traitId: string?): boolean
	local def = traitId and TraitDefinitions[traitId]
	return def ~= nil and type(def.PityCap) == "number" and def.PityCap > 0
end

-- The trait's logo asset id, or nil when none is set yet (the UI then shows the name instead).
function TraitRegistry.Icon(traitId: string?): string?
	local def = traitId and TraitDefinitions[traitId]
	local icon = def and def.Icon
	if type(icon) == "string" and icon ~= "" and icon ~= "rbxassetid://0" then
		return icon
	end
	return nil
end

-- ===== PITY (B69) =====
-- A trait with a `TraitDefinitions.PityCap` is GUARANTEED on the Nth consecutive reroll of a unit
-- that has not landed it. The counter lives on the UNIT INSTANCE (`UnitInstance.TraitPity`, schema
-- v7), never on the player, so grinding one tower never advances another's -- and the SERVICE owns
-- the write, exactly as it owns the trait write. These functions are PURE.

-- Pitied ids, RAREST FIRST. **The order is load-bearing**: if two caps fill on the same reroll the
-- rarer one must win, or a Godly guarantee could be eaten by a Deadeye one. Sorted by Weight with a
-- name tiebreak because `pairs()` order is NOT deterministic in Luau -- without the tiebreak this
-- list could differ between two servers running identical code.
local PITIED: { string } = {}
do
	for id, def in pairs(TraitDefinitions) do
		if type(def.PityCap) == "number" and def.PityCap > 0 then
			table.insert(PITIED, id)
		end
	end
	table.sort(PITIED, function(a, b)
		local wa = TraitDefinitions[a].Weight or math.huge
		local wb = TraitDefinitions[b].Weight or math.huge
		if wa ~= wb then
			return wa < wb
		end
		return a < b
	end)
end

-- Ids that show a pity bar, rarest first. A COPY -- a caller must not be able to reorder the table
-- the guarantee reads.
function TraitRegistry.PitiedTraits(): { string }
	return table.clone(PITIED)
end

function TraitRegistry.PityCap(traitId: string?): number?
	local def = traitId and TraitDefinitions[traitId]
	return def and def.PityCap or nil
end

-- Would this unit's next reroll be a GUARANTEE, and of what? Pure lookahead: it writes nothing.
-- `cap` counts REROLLS, so a counter already at `cap - 1` means this one is the guaranteed roll --
-- i.e. `PityCap = 75` reads honestly as "at worst, 75 rerolls".
function TraitRegistry.PendingGuarantee(pity: { [string]: number }?): string?
	local p = pity or {}
	for _, id in ipairs(PITIED) do
		local cap = TraitDefinitions[id].PityCap
		if cap and ((p[id] or 0) + 1) >= cap then
			return id
		end
	end
	return nil
end

-- The rarer of two ids (smaller Weight wins). Used to combine a pity guarantee with the Luck buff's
-- best-of-N so that NEITHER can make the other worse: a guarantee is a FLOOR, not a ceiling, so a
-- lucky Godly still beats a guaranteed Deadeye.
function TraitRegistry.Rarer(a: string?, b: string?): string?
	if a == nil then return b end
	if b == nil then return a end
	local wa = TraitRegistry.Get(a).Weight or math.huge
	local wb = TraitRegistry.Get(b).Weight or math.huge
	if wa <= wb then return a end
	return b
end

-- Move a unit's pity table on by one reroll. MUTATES and returns it.
-- Every pitied trait that did NOT land moves one closer; the one that DID land resets to 0 --
-- whether it was guaranteed or came up naturally, because either way the player just received it.
-- Call this ONCE PER REROLL (one token spent = one tick), never once per best-of-N candidate.
function TraitRegistry.AdvancePity(pity: { [string]: number }, landedTraitId: string): { [string]: number }
	for _, id in ipairs(PITIED) do
		if id == landedTraitId then
			pity[id] = 0
		else
			pity[id] = (pity[id] or 0) + 1
		end
	end
	return pity
end

return TraitRegistry
