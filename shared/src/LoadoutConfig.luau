--!strict
-- LoadoutConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.LoadoutConfig)
-- How many hotbar slots a player has, and what account level each one needs.
--
-- SHARED because BOTH Places need it: the Lobby decides which slots you can equip into, and the
-- Game draws the same locked slots on the match hotbar. If only one Place knew, the two hotbars
-- would disagree about how many slots you have -- which is exactly the kind of split-brain the
-- shared-canon system exists to prevent.
--
-- The hotbar ALWAYS draws MaxSlots slots (user rule 2026-08-06): a slot is never hidden, it is
-- either filled, empty, or locked. Players should be able to see what they are working toward.

local LoadoutConfig = {}

-- Every player always sees this many slots.
LoadoutConfig.MaxSlots = 6

-- Account level required per slot index. Slots 1-3 are free from level 1.
-- Tune freely -- this table is the single source of truth for both Places.
LoadoutConfig.SlotUnlockLevel = { 1, 1, 1, 5, 20, 50 }

-- How many slots the player can actually use at this account level.
-- Counts from slot 1 upward and stops at the first locked slot, so the table stays meaningful
-- even if someone later writes it out of order.
function LoadoutConfig.UnlockedSlots(playerLevel: number?): number
	local level = playerLevel or 1
	local unlocked = 0
	for i = 1, LoadoutConfig.MaxSlots do
		local required = LoadoutConfig.SlotUnlockLevel[i] or 1
		if level >= required then
			unlocked = i
		else
			break
		end
	end
	return unlocked
end

-- Is this slot index usable at this level?
function LoadoutConfig.IsSlotUnlocked(slotIndex: number, playerLevel: number?): boolean
	if slotIndex < 1 or slotIndex > LoadoutConfig.MaxSlots then
		return false
	end
	return (playerLevel or 1) >= (LoadoutConfig.SlotUnlockLevel[slotIndex] or 1)
end

-- Level needed for a slot, for the "Lv 5" label on a locked slot.
function LoadoutConfig.RequiredLevel(slotIndex: number): number
	return LoadoutConfig.SlotUnlockLevel[slotIndex] or 1
end

return LoadoutConfig
