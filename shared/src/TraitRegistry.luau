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

-- Weighted random trait roll (for the Trait Reroll gacha item).
-- MUST only ever be called on the SERVER -- a client-side roll is a free legendary.
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

return TraitRegistry
