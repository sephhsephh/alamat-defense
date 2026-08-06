--!strict
-- UIKit.ItemIcon - reusable item card controller (AD-UI kit, blueprint phase-a section 5)
-- The item counterpart of the unit card. Items have NO model, so this is a flat ImageLabel
-- icon (no ViewportFrame) plus a quantity badge and the same tier border/BG treatment the
-- Units screen uses (shared multi-colour TierConfig, seamless animated gradient).
--
-- The DESIGN lives on ReplicatedStorage.UITemplates.Kit.ItemIcon - edit it in Studio.
-- This module only clones it, fills the icon/badge, and paints the tier. It never builds UI.
--
-- Expected instance shape (every part optional - missing parts degrade gracefully):
--   ItemIcon (ImageButton)
--   `-- Main (Frame)
--        |-- BG (ImageLabel) -- UIGradient (tier BG) + UIStrokeWithGradient (tier border)
--        |-- IconImage (ImageLabel)
--        `-- QtyBadge (Frame) -- TextLabel
--
-- Usage:
--   local ItemIcon = require(ReplicatedStorage.Shared.UIKit.ItemIcon)
--   local handle = ItemIcon.create(container, "BannerTicket", 3)
--   handle.onHover(function(on) ... end); handle.onActivated(function() ... end)
--   handle.setQty(5); handle.setSelected(true); handle.destroy()

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local meta = RS:WaitForChild("Configs"):WaitForChild("Meta")
local ItemCatalog = require(meta:WaitForChild("ItemCatalog"))
local TierConfig = require(meta:WaitForChild("TierConfig"))

local ItemIcon = {}

local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "ItemIcon" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "ItemIcon" },
}

-- Icon assetids in the catalog are still placeholders ("rbxassetid://0"). Fall back to the
-- Studio placeholder texture so a card is never a blank square while art is pending.
local PLACEHOLDER = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local WHITE_SEQ = ColorSequence.new(Color3.new(1, 1, 1))
local HOVER_SCALE, PRESS_SCALE = 1.06, 0.93

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

-- Resolve a catalog Icon spec to an image string. Model icons (towers) have no flat art yet.
function ItemIcon.ImageFor(itemId: string): string
	local entry = ItemCatalog.Get(itemId)
	local icon = entry and entry.Icon
	if type(icon) == "table" and type(icon.Image) == "string" then
		local img = icon.Image
		if img ~= "" and img ~= "rbxassetid://0" then return img end
	end
	return PLACEHOLDER
end

local function strokeGradient(stroke: UIStroke): UIGradient
	local g = stroke:FindFirstChildOfClass("UIGradient")
	if not g then g = Instance.new("UIGradient"); g.Parent = stroke end
	return g
end

local function animateGradient(grad: UIGradient, speed: number)
	grad.Offset = Vector2.new(-1, 0)
	local info = TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
	local t = TweenService:Create(grad, info, { Offset = Vector2.new(1, 0) })
	t:Play()
	return t
end

-- Move a GuiObject's anchor to centre without moving it (so a UIScale scales from centre).
local function centerAnchor(obj: GuiObject)
	if obj.AnchorPoint == Vector2.new(0.5, 0.5) then return end
	local d = Vector2.new(0.5, 0.5) - obj.AnchorPoint
	local s = obj.Size
	obj.Position = UDim2.new(
		obj.Position.X.Scale + d.X * s.X.Scale, obj.Position.X.Offset + d.X * s.X.Offset,
		obj.Position.Y.Scale + d.Y * s.Y.Scale, obj.Position.Y.Offset + d.Y * s.Y.Offset
	)
	obj.AnchorPoint = Vector2.new(0.5, 0.5)
end

-- Attach behaviour to an existing ItemIcon instance. Returns a handle.
function ItemIcon.attach(card: GuiButton, itemId: string, qty: number?)
	local entry = ItemCatalog.Get(itemId)
	local tier = ItemCatalog.GetTier(itemId)

	local main = card:FindFirstChild("Main")
	local bg = main and main:FindFirstChild("BG")
	local bgGrad = bg and bg:FindFirstChildOfClass("UIGradient")
	local stroke = card:FindFirstChild("UIStrokeWithGradient", true)
	local image = card:FindFirstChild("IconImage", true)
	local badge = card:FindFirstChild("QtyBadge", true)
	local badgeText = badge and badge:FindFirstChildWhichIsA("TextLabel")

	if image and image:IsA("ImageLabel") then
		image.Image = ItemIcon.ImageFor(itemId)
	end

	-- Tier paint: BG gradient + border stroke, seamless multi-colour (rainbow Mythic etc).
	local gradTweens: { Tween } = {}
	if bgGrad then
		bgGrad.Color = TierConfig.seamlessSequence(tier)
		table.insert(gradTweens, animateGradient(bgGrad, 3))
	end
	if stroke and stroke:IsA("UIStroke") then
		stroke.Enabled = true
		stroke.Transparency = 0
		strokeGradient(stroke).Color = TierConfig.seamlessSequence(tier)
		table.insert(gradTweens, animateGradient(strokeGradient(stroke), 3))
	end

	local scaleObj: UIScale? = nil
	if main and main:IsA("GuiObject") then
		centerAnchor(main)
		local existing = main:FindFirstChildOfClass("UIScale")
		if not existing then
			existing = Instance.new("UIScale")
			existing.Parent = main
		end
		scaleObj = existing
	end

	local hovering, pressed, selected = false, false, false
	local hoverCallbacks: { (boolean) -> () } = {}
	local conns: { RBXScriptConnection } = {}

	local function refreshScale()
		if not scaleObj then return end
		local target = pressed and PRESS_SCALE or ((hovering or selected) and HOVER_SCALE or 1)
		TweenService:Create(scaleObj, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = target }):Play()
	end
	local function paintStroke()
		if not (stroke and stroke:IsA("UIStroke")) then return end
		strokeGradient(stroke).Color = (hovering or selected) and WHITE_SEQ
			or TierConfig.seamlessSequence(tier)
	end

	local function bind(sig: RBXScriptSignal, fn: (...any) -> ())
		table.insert(conns, sig:Connect(fn))
	end

	bind(card.MouseEnter, function()
		hovering = true; paintStroke(); refreshScale()
		for _, f in ipairs(hoverCallbacks) do task.spawn(f, true) end
	end)
	bind(card.MouseLeave, function()
		hovering = false; pressed = false; paintStroke(); refreshScale()
		for _, f in ipairs(hoverCallbacks) do task.spawn(f, false) end
	end)
	bind(card.InputBegan, function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			pressed = true; refreshScale()
		end
	end)
	bind(card.InputEnded, function(i: InputObject)
		if i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch then
			pressed = false; refreshScale()
		end
	end)

	local handle = {}
	handle.instance = card
	handle.itemId = itemId
	handle.tier = tier
	handle.entry = entry

	-- Qty 0 = owned none: the badge hides and the card dims, so the screen doubles as a
	-- compendium of everything obtainable without lying about what the player holds.
	function handle.setQty(n: number?)
		local count = n or 0
		if badgeText and badgeText:IsA("TextLabel") then
			badgeText.Text = "x" .. tostring(count)
		end
		if badge and badge:IsA("GuiObject") then
			badge.Visible = count > 0
		end
		if image and image:IsA("ImageLabel") then
			image.ImageTransparency = count > 0 and 0 or 0.6
		end
	end
	function handle.setSelected(on: boolean)
		selected = on and true or false
		paintStroke(); refreshScale()
	end
	function handle.onActivated(fn: (...any) -> ()): RBXScriptConnection
		local c = card.Activated:Connect(fn)
		table.insert(conns, c)
		return c
	end
	function handle.onHover(fn: (boolean) -> ()): () -> ()
		table.insert(hoverCallbacks, fn)
		return function()
			local i = table.find(hoverCallbacks, fn)
			if i then table.remove(hoverCallbacks, i) end
		end
	end
	function handle.destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, t in ipairs(gradTweens) do t:Cancel() end
		card:Destroy()
	end

	handle.setQty(qty)
	return handle
end

-- Clone the kit template and attach behaviour. Returns the same handle as attach().
function ItemIcon.create(parent: Instance, itemId: string, qty: number?)
	local template = resolveTemplate()
	assert(template, "UIKit.ItemIcon.create: no ItemIcon template found in " ..
		"ReplicatedStorage.UITemplates.Kit / Shared.UIKit.Templates")
	local clone = template:Clone()
	clone.Name = "ItemCard_" .. itemId
	clone.Visible = true
	clone.Parent = parent
	return ItemIcon.attach(clone :: any, itemId, qty)
end

return ItemIcon
