--!strict
-- UnitScale (SHARED CANON, B159 -- deploy path ReplicatedStorage.Shared.UnitScale, both Places)
-- Unit rigs are STORED at their full R15 size and SHOWN at their in-game size.
-- User: "retain their original sizes and the game just automatically makes them smaller when placement
-- mode and live game. same with unit models."
--
-- Every rig in RS.TowerModels (Game) / RS.UnitModels (Lobby) carries a `GameScale` attribute: the Model
-- scale it plays at (0.34 = the standard ~2-stud unit). A CLONE is ScaleTo(GameScale)'d before anything
-- measures or places it -- the placed tower, the placement ghost, the auto-play ground offset, a unit-rig
-- boss, and every viewport (UnitCard.viewport / UIKit.Hotbar) -- so the match and every portrait look
-- exactly as they did when the rigs were stored shrunk, and no camera is ever re-tuned per unit.
--   * New unit: drop the FULL-SIZE rig in. It plays at DEFAULT. A bigger / smaller unit: set its GameScale.
--   * `Server.UnitScaleTagger` (both Places) writes GameScale = DEFAULT at boot on any rig without one, so
--     the attribute is what marks a model as a unit rig. Enemy and avatar models never carry it, which is
--     why viewports use `applyIfUnit` (UnitCard.viewport frames enemy portraits too).
local UnitScale = {}

-- The scale 41 of the 48 rigs were authored at before B159 restored them to full size.
UnitScale.DEFAULT = 0.34

-- The in-game scale of a rig (or of a clone of one).
function UnitScale.of(model: Instance?): number
	local s = if model then model:GetAttribute("GameScale") else nil
	return if type(s) == "number" and s > 0 then s else UnitScale.DEFAULT
end

-- Scale a unit-rig CLONE to its in-game size. Idempotent. Call it BEFORE PivotTo / GetBoundingBox.
function UnitScale.apply(model: Instance?): Instance?
	if model and model:IsA("Model") then
		local m = model :: Model
		local target = UnitScale.of(m)
		if math.abs(m:GetScale() - target) > 1e-4 then
			pcall(function() m:ScaleTo(target) end)
		end
	end
	return model
end

-- Viewports: scale only a model that IS a unit rig (carries GameScale); enemy / avatar models pass through.
function UnitScale.applyIfUnit(model: Instance?): Instance?
	if model and model:GetAttribute("GameScale") ~= nil then
		return UnitScale.apply(model)
	end
	return model
end

-- ⚠ MEASURE A SCALED CLONE, never "the stored rig x (GameScale / its scale)": a layered-clothing cage (a
-- WrapLayer accessory Handle -- Bathala's, Aswang's) is NOT resized by ScaleTo, so the stored rig's bounding
-- box does not shrink in proportion (Bathala's pivot-to-feet: 2.53 in game vs 0.94 from the ratio).

-- Server boot: give every rig in `folder` that has no GameScale the DEFAULT. Returns how many were defaulted.
function UnitScale.tagFolder(folder: Instance?): number
	local n = 0
	if folder then
		for _, m in ipairs(folder:GetChildren()) do
			if m:IsA("Model") and m:GetAttribute("GameScale") == nil then
				m:SetAttribute("GameScale", UnitScale.DEFAULT)
				n += 1
			end
		end
	end
	return n
end

return UnitScale
