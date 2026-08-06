--!strict
-- UIKit.Hotbar - the shared hotbar (AD-UI kit, 2026-08-06)
--
-- ONE controller so the Lobby and the Game hotbars look and feel IDENTICAL (user rule): same
-- slot design, same hover, same press animation, same locked/empty states. The only thing each
-- Place supplies is WHAT A CLICK DOES, via `OnActivated`. Lobby opens the Units screen on that
-- unit; the Game starts placement. Nothing else should differ.
--
-- ALWAYS draws `LoadoutConfig.MaxSlots` slots (user rule): a slot is never hidden, only
--   FILLED  - has a unit: model in the viewport, tier border, trait dot
--   EMPTY   - unlocked but nothing equipped: viewport cleared, details hidden, still clickable
--   LOCKED  - account level too low: dark overlay + lock + "Lv N", NOT clickable
-- Showing locked slots is deliberate: the player can see what they are working toward.
--
-- The DESIGN lives on `RS.UITemplates.Kit.HotbarSlot` (the user's own Lobby slot, promoted to
-- the kit). Edit it in Studio -- but it is SHARED, so edit it in one Place only and that is
-- drift; re-hash and mirror it (tools/checklists.md).
--
-- Usage:
--   local Hotbar = require(ReplicatedStorage.Shared.UIKit.Hotbar)
--   local hb = Hotbar.attach(gui.Slots, {
--       ModelSource = ReplicatedStorage.TowerModels,
--       OnActivated = function(slotIndex, entry) ... end,   -- entry is nil for an empty slot
--   })
--   hb.setData({ [1] = entryA, [2] = entryB }, playerLevel)
--
-- `entry` is whatever the Place already has, as long as it carries TowerId (+ optionally
-- Name / Tier / Level / Trait). The Lobby passes a unitView; the Game passes a loadout row.

local RS = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local meta = RS:WaitForChild("Configs"):WaitForChild("Meta")
local ItemCatalog = require(meta:WaitForChild("ItemCatalog"))
local TierConfig = require(meta:WaitForChild("TierConfig"))
local LoadoutConfig = require(meta:WaitForChild("LoadoutConfig"))
local Button = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("Button"))

local Hotbar = {}

local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "HotbarSlot" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "HotbarSlot" },
}

local KEY_FOR_SLOT = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
}

local function resolveTemplate(): GuiObject?
	for _, path in ipairs(TEMPLATE_PATHS) do
		local node: Instance? = game
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and node:IsA("GuiObject") then return node end
	end
	return nil
end

local function setText(root: Instance, name: string, value: string)
	local h = root:FindFirstChild(name, true)
	if not h then return end
	local l = h:IsA("TextLabel") and h or h:FindFirstChildWhichIsA("TextLabel")
	if l then l.Text = value end
end

-- Put a display rig in the slot's viewport. Scripts are stripped: a display rig must never run
-- code inside a ViewportFrame.
local function showModel(vf: ViewportFrame, modelSource: Instance?, towerId: string?)
	local wm = vf:FindFirstChildWhichIsA("WorldModel")
	if not wm then wm = Instance.new("WorldModel"); wm.Parent = vf end
	for _, c in ipairs(wm:GetChildren()) do c:Destroy() end
	if not (modelSource and towerId) then return end
	local src = modelSource:FindFirstChild(towerId) or modelSource:FindFirstChild("Placeholder")
	if not src then return end
	local m = src:Clone()
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	m.Parent = wm
	local cf, size = m:GetBoundingBox()
	local centre = cf.Position
	local hrp = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	local facing = hrp and hrp.CFrame.LookVector or Vector3.new(0, 0, -1)
	local fov = 40
	local dist = (math.max(size.X, size.Y, size.Z) * 0.5) / math.tan(math.rad(fov / 2)) * 1.25 + 2
	local cam = vf:FindFirstChildWhichIsA("Camera")
	if not cam then cam = Instance.new("Camera"); cam.Parent = vf end
	cam.FieldOfView = fov
	cam.CFrame = CFrame.lookAt(centre + facing * dist + Vector3.new(0, size.Y * 0.06, 0), centre)
	vf.CurrentCamera = cam
end

-- Attach the hotbar to a container Frame. Returns a handle.
function Hotbar.attach(container: GuiObject, opts: { [string]: any })
	assert(container, "UIKit.Hotbar.attach: container is nil")
	opts = opts or {}
	local template = resolveTemplate()
	assert(template, "UIKit.Hotbar.attach: no HotbarSlot template found in " ..
		"ReplicatedStorage.UITemplates.Kit / Shared.UIKit.Templates")

	-- Clear whatever was there (old per-slot instances from before the kit).
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiButton") then c:Destroy() end
	end

	local slots: { any } = {}
	local entries: { [number]: any } = {}
	local playerLevel = 1

	for i = 1, LoadoutConfig.MaxSlots do
		local btn = template:Clone()
		btn.Name = "Slot" .. i
		btn.LayoutOrder = i
		btn.Visible = true
		btn:SetAttribute("SlotIndex", i)
		btn.Parent = container
		setText(btn, "SlotNumber", tostring(i))
		local handle = Button.attach(btn)
		slots[i] = { Button = btn, Handle = handle }
	end

	local function paint(i: number)
		local slot = slots[i]
		if not slot then return end
		local btn = slot.Button
		local entry = entries[i]
		local unlocked = LoadoutConfig.IsSlotUnlocked(i, playerLevel)

		local lock = btn:FindFirstChild("LockOverlay", true)
		if lock and lock:IsA("GuiObject") then
			lock.Visible = not unlocked
			if not unlocked then
				setText(lock, "RequirementLabel", "Lv " .. tostring(LoadoutConfig.RequiredLevel(i)))
			end
		end
		slot.Handle.setEnabled(unlocked)

		local vf = btn:FindFirstChildWhichIsA("ViewportFrame", true)
		local trait = btn:FindFirstChild("TraitIcon", true)
		local stroke = btn:FindFirstChild("UIStrokeWithGradient", true)

		local towerId = entry and entry.TowerId or nil
		if vf then showModel(vf, opts.ModelSource, unlocked and towerId or nil) end

		-- Empty or locked: hide the per-unit details rather than showing stale ones.
		if trait and trait:IsA("GuiObject") then
			trait.Visible = (entry ~= nil) and unlocked and (entry.Trait ~= nil and entry.Trait ~= "None")
		end
		if stroke and stroke:IsA("UIStroke") then
			local g = stroke:FindFirstChildOfClass("UIGradient")
			if not g then g = Instance.new("UIGradient"); g.Parent = stroke end
			if entry and unlocked then
				local tier = entry.Tier or ItemCatalog.GetTier(entry.TowerId)
				g.Color = TierConfig.seamlessSequence(tier)
			else
				g.Color = ColorSequence.new(Color3.fromRGB(90, 84, 104))
			end
		end
	end

	local function activate(i: number)
		if not LoadoutConfig.IsSlotUnlocked(i, playerLevel) then return end
		if type(opts.OnActivated) == "function" then
			opts.OnActivated(i, entries[i])
		end
	end

	for i = 1, LoadoutConfig.MaxSlots do
		slots[i].Handle.onActivated(function() activate(i) end)
	end

	local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local i = KEY_FOR_SLOT[input.KeyCode]
		if i then activate(i) end
	end)

	local handle = {}
	handle.container = container

	-- entriesBySlot: { [slotIndex] = entry }; anything absent renders as EMPTY.
	function handle.setData(entriesBySlot: { [number]: any }?, level: number?)
		entries = entriesBySlot or {}
		playerLevel = level or playerLevel
		for i = 1, LoadoutConfig.MaxSlots do paint(i) end
	end
	function handle.refresh()
		for i = 1, LoadoutConfig.MaxSlots do paint(i) end
	end
	function handle.unlockedSlots(): number
		return LoadoutConfig.UnlockedSlots(playerLevel)
	end
	function handle.slotInstance(i: number): GuiObject?
		return slots[i] and slots[i].Button or nil
	end
	function handle.destroy()
		keyConn:Disconnect()
		for _, s in ipairs(slots) do
			s.Handle.destroy()
			s.Button:Destroy()
		end
		table.clear(slots)
	end

	handle.setData({}, playerLevel)
	return handle
end

return Hotbar
