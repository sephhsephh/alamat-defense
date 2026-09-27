--!strict
-- AuthoredFX (SHARED CANON -- deploy path ReplicatedStorage.Shared.AuthoredFX)
-- Added B100. The ONE player for designer-authored effects: a folder holding a `Sound` and a `VFX`
-- folder, edited in Studio, fired by code that never names an asset. Used by MovementController
-- (RS.CharacterFX: jump / double jump / dash, both Places) and the Game's EnemyDeathFX
-- (RS.EnemyDeathFX). Before B100 each carried its own ~60-line copy of this.
--
-- AN EFFECT FOLDER (`def`):
--   Sound  (Sound)  -- cloned onto the root and played. Empty SoundId = silent, by design.
--   VFX    (Folder) -- cloned per play. Each Attachment goes to the character part named by its `Part`
--                     attribute (default: the root); anything else (Trail / Beam) goes to the root. A
--                     ParticleEmitter with an `EmitCount` attribute bursts that many particles; one
--                     without it, and every Trail / Beam, is switched ON for `ActiveTime` seconds.
--   attributes on `def`:
--     ActiveTime (number, default 0.2)  -- how long continuous emitters / trails stay on
--     MuteStockSound (string)           -- a Roblox character sound under the root to silence while a
--                                          custom SoundId is set (Jump uses "Jumping")
-- Everything cloned cleans itself up. A missing Sound, an empty SoundId or an empty VFX folder is
-- normal and plays nothing.

local Debris = game:GetService("Debris")

local AuthoredFX = {}

-- Plays `def` on `root` (a BasePart). `character` (optional) lets an Attachment's `Part` attribute
-- pick a body part. Returns how many seconds until everything it made is gone.
function AuthoredFX.Play(def: Instance, root: BasePart, character: Instance?): number
	local activeTime = tonumber(def:GetAttribute("ActiveTime")) or 0.2
	local lifetime = activeTime

	local template = def:FindFirstChild("Sound")
	local sound = if template and template:IsA("Sound") then template else nil
	if sound and sound.SoundId ~= "" then
		local stockName = def:GetAttribute("MuteStockSound")
		if typeof(stockName) == "string" then
			local stock = root:FindFirstChild(stockName)
			if stock and stock:IsA("Sound") then
				stock.Volume = 0
			end
		end
		local s = sound:Clone()
		s.Parent = root
		s:Play()
		local soundLife = math.max(s.TimeLength, 3) + 0.5
		Debris:AddItem(s, soundLife)
		lifetime = math.max(lifetime, soundLife)
	end

	local vfx = def:FindFirstChild("VFX")
	if vfx == nil or #vfx:GetChildren() == 0 then
		return lifetime
	end
	local clone = vfx:Clone()
	local placed = {}
	for _, child in ipairs(clone:GetChildren()) do
		local target: Instance = root
		if child:IsA("Attachment") and character then
			local partName = child:GetAttribute("Part")
			local part = if typeof(partName) == "string" then character:FindFirstChild(partName) else nil
			if part and part:IsA("BasePart") then
				target = part
			end
		end
		child.Parent = target
		table.insert(placed, child)
	end
	clone:Destroy()

	local linger = 0
	local switched = {}
	for _, item in ipairs(placed) do
		local all = item:GetDescendants()
		table.insert(all, item)
		for _, d in ipairs(all) do
			if d:IsA("ParticleEmitter") then
				linger = math.max(linger, d.Lifetime.Max)
				local count = tonumber(d:GetAttribute("EmitCount"))
				if count and count > 0 then
					d:Emit(count)
				else
					d.Enabled = true
					table.insert(switched, d)
				end
			elseif d:IsA("Trail") then
				linger = math.max(linger, d.Lifetime)
				d.Enabled = true
				table.insert(switched, d)
			elseif d:IsA("Beam") then
				d.Enabled = true
				table.insert(switched, d)
			end
		end
	end
	task.delay(activeTime, function()
		for _, d in ipairs(switched) do
			if d.Parent then
				(d :: any).Enabled = false
			end
		end
	end)
	local vfxLife = activeTime + linger + 0.25
	for _, item in ipairs(placed) do
		Debris:AddItem(item, vfxLife)
	end
	return math.max(lifetime, vfxLife)
end

return AuthoredFX
