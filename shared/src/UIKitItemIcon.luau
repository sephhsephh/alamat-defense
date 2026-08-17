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
-- Motion owns hover/press curves, the 45-degree idle sheen, and the wrapper that stops a scaling
-- card from shoving its neighbours along the grid.
local Motion = require(script.Parent:WaitForChild("Motion"))

local ItemIcon = {}

local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "ItemIconV2" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "ItemIconV2" },
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
	-- ===== V2 KIT (B26) =====
	-- RARITY LIVES ON THE ROOT `UIGradient`, AND THERE IS NO TIER BORDER.
	-- v1 painted two surfaces -- `Main.BG`'s gradient (fill) and `UIStrokeWithGradient` (border).
	-- NEITHER exists in `ItemIconV2`. User decision, B25: one paint surface, one call site.
	-- **Do not re-add a tier stroke** (its absence is a deliberate, accepted restyle) and **do not
	-- write a second gradient animator** -- `animateGradient` below is the seamless one every screen
	-- already shares.
	--
	-- `FindFirstChildOfClass` on the CARD is DIRECT-CHILDREN-ONLY and that is LOAD-BEARING: V2 nests
	-- UIGradients inside `Main.Amount`, and a recursive search would animate the quantity badge
	-- instead of the card.
	local rootGrad = card:FindFirstChildOfClass("UIGradient")
	-- `UIHoverStroke` ships authored `Enabled = false` and is HOVER ONLY -- it is not a tier border.
	local stroke = card:FindFirstChild("UIHoverStroke")
	local image = card:FindFirstChild("ItemIcon", true)
	local badge = card:FindFirstChild("Amount", true)
	local badgeText = badge and badge:FindFirstChildWhichIsA("TextLabel")
	local nameLabel = card:FindFirstChild("ItemName", true)

	if image and image:IsA("ImageLabel") then
		image.Image = ItemIcon.ImageFor(itemId)
	end
	-- V2 shows the item's NAME on the card; v1 had nowhere to put it.
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = ItemCatalog.GetName(itemId)
	end

	-- Tier paint: the ROOT gradient, seamless multi-colour (rainbow Mythic etc).
	local gradTweens: { Tween } = {}
	if rootGrad then
		rootGrad.Color = TierConfig.seamlessSequence(tier)
		local t = Motion.idleGradient(rootGrad)
		if t then table.insert(gradTweens, t) end
	end
	if stroke and stroke:IsA("UIStroke") then
		stroke.Enabled = false -- authored state; hover is what turns it on
		-- Hover-stroke paint, one call (B27d): a two-colour tier outlines in its BRIGHTEST single
		-- colour (never the derived dark half, which would read as a shadow); a tier with THREE OR
		-- MORE authored colours outlines in ALL of them via a child UIGradient. See
		-- `TierConfig.HoverStrokePaint` for the reasoning and `Motion.paintHoverStroke` for the
		-- two Instance-level traps it handles.
		Motion.paintHoverStroke(stroke, tier)
	end

	-- ===== THE WHOLE CARD SCALES ON HOVER/PRESS, NOT JUST `Main` (user rule, B27) =====
	-- This used to put the UIScale on `Main`, so the artwork grew while the card's own `UICorner`
	-- and `UIHoverStroke` -- both on the ROOT, both sized from it -- stayed put, and the card came
	-- apart at its edges on every hover. The UIScale now lives on the ROOT.
	--
	-- Centre-anchoring the root is layout-safe and that was MEASURED, not assumed: a `UIGridLayout`
	-- child and a `UIListLayout` child were sampled before and after `AnchorPoint = (0.5, 0.5)` and
	-- neither moved -- the layout overrides the anchor offset when it assigns `Position`.
	-- `centerAnchor` compensates `Position` for the free-positioned case, so both are covered.
	-- `Motion.isolate` puts a FIXED-SIZE wrapper between the layout and this card and moves the
	-- UIScale onto the card inside it. Without that the grid re-measures the hovered card and every
	-- neighbour slides -- measured at 30px of shove for a 150px card. The card still scales whole,
	-- carrying its own UICorner and UIHoverStroke, which is the B27 rule.
	local _, scaleObj = Motion.isolate(card)
	do
		-- Neutralise any UIScale the template shipped on `Main`; two would multiply.
		local innerScale = main and main:IsA("GuiObject") and main:FindFirstChildOfClass("UIScale")
		if innerScale then innerScale.Scale = 1 end
	end

	local hovering, pressed, selected = false, false, false
	local hoverCallbacks: { (boolean) -> () } = {}
	local conns: { RBXScriptConnection } = {}

	local function refreshScale()
		-- One curve for the whole kit (Motion.Tuning): Quint ease-out, unhurried in, slower back.
		Motion.scaleTo(scaleObj, pressed and "press" or ((hovering or selected) and "hover" or "rest"))
		-- Lift the hovered card above its neighbours so the growth is never drawn underneath one.
		Motion.lift(card, hovering or selected)
	end
	-- V2: hover TOGGLES the authored `UIHoverStroke` instead of recolouring a tier border (there is
	-- no tier border any more). Same trigger points, same feel, one instance.
	local function paintStroke()
		if not (stroke and stroke:IsA("UIStroke")) then return end
		stroke.Enabled = hovering or selected
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
		-- Destroys the Motion wrapper too; destroying only the card would leave an empty
		-- fixed-size slot silently padding the grid.
		Motion.destroy(card)
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
