--!strict
-- UIKitMotion.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.Motion)
-- ONE home for how the kit MOVES: hover/press scaling, idle gradient drift, and the tuning numbers
-- behind both. Added B27c 2026-08-16 because four screens plus three kit controllers had each grown
-- their own copy of the same three effects, with three different durations.
--
-- ===== WHY A CARD MUST BE WRAPPED BEFORE IT CAN SCALE =====
-- A `UIScale` on a child of a `UIListLayout`/`UIGridLayout` CHANGES THAT CHILD'S MEASURED SIZE, so
-- the layout re-flows and every sibling slides sideways while you hover one card. That was measured,
-- not assumed: a 150px card at scale 1.2 under a horizontal UIListLayout pushed its neighbour 30px.
--
-- The fix is `isolate()`: the LAYOUT gets a fixed-size wrapper that never changes, and the card
-- lives inside it with the UIScale. Same measurement with the wrapper in place moved the neighbour
-- **0 px** while the card still visibly grew (150 -> 195). The wrapper must never set
-- `ClipsDescendants` (it defaults false) or it would crop the very growth it exists to allow.
--
-- This keeps B27's rule intact -- the WHOLE card scales, carrying its own `UICorner` and
-- `UIHoverStroke` with it -- while costing the neighbours nothing.

local TweenService = game:GetService("TweenService")

local Motion = {}

-- ===== THE TUNING TABLE -- retune the kit's feel HERE, never per screen =====
-- B27c: the user asked for "smoother and cooler, more modern", and for a slower idle.
--   * hover/press use a QUINT ease-out: a long, soft settle instead of Quad's abrupt stop, and it is
--     the curve most modern UI reads as "expensive". Press is deliberately faster than hover --
--     a press must feel immediate, a hover must feel unhurried.
--   * the idle gradient was 3s, which reads as a nervous flicker on a card you are staring at.
--     9s is a slow sheen you notice without it demanding attention.
Motion.Tuning = {
	HoverScale = 1.07,
	PressScale = 0.95,
	HoverTime = 0.26,
	PressTime = 0.09,
	RestTime = 0.30,          -- returning to rest is the slowest leg: nothing snaps back
	Easing = Enum.EasingStyle.Quint,
	Direction = Enum.EasingDirection.Out,
	IdleGradientPeriod = 9,   -- seconds for one seamless pass (was 3 -- too fast)
	-- 45 degrees, per the user: a diagonal sheen reads as light falling across the card, where a
	-- horizontal one reads as a loading bar.
	GradientRotation = 45,
	-- How far a hovered card is lifted above its neighbours, so a scaled card is never clipped
	-- UNDER the sibling that happens to be drawn after it.
	HoverZIndexLift = 5,
}

-- ===== TEMPORARY (B27c, USER-REQUESTED): PLACEHOLDER PRICES ARE VISIBLE =====
-- The standing rule is HIDE, NEVER INVENT -- a fabricated price is exactly the class of lie the
-- acceptance rules exist to prevent. The user has explicitly overridden that FOR TESTING: *"show
-- the prices for now, even if its just made it just to see it visually when testing"*.
--
-- So `PlacementPrice` renders with whatever the TEMPLATE AUTHORED, which is a design placeholder and
-- **is not a real cost** -- no Lobby data source for placement cost exists (it lives in the Game's
-- tower configs; proposal `2026-08-16-tower-display-fields-for-uniticon-v2.md`).
--
-- It is parked in this module, off-topic though it is, for one reason: every card consumer already
-- requires Motion, so this is the single switch that flips ALL of them back. When real prices land,
-- set this false, delete this block, and fill the label from the real source.
Motion.SHOW_PLACEHOLDER_PRICES = true

local function info(time: number): TweenInfo
	return TweenInfo.new(time, Motion.Tuning.Easing, Motion.Tuning.Direction)
end

-- ===== isolate: make a card scalable without disturbing its siblings =====
-- Returns (wrapper, uiScale). Idempotent -- calling it twice on the same card returns the existing
-- wrapper rather than nesting a second one, so a controller that re-runs is harmless.
--
-- The wrapper inherits the card's layout-relevant properties (`Size`, `LayoutOrder`, `Visible`) and
-- the card is pinned to fill it. `Visible` is the subtle one: every screen toggles card visibility
-- for search/filter, and those toggles address the instance the layout sees -- so the WRAPPER has to
-- be what carries it. `Motion.setVisible` below is the honest way to do that from a controller that
-- only holds the card.
function Motion.isolate(card: GuiObject): (GuiObject, UIScale)
	local existing = card.Parent
	if existing and existing:IsA("GuiObject") and existing:GetAttribute("UIKitMotionWrapper") then
		local s = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		s.Parent = card
		return existing, s
	end

	local parent = card.Parent
	local wrapper = Instance.new("Frame")
	wrapper.Name = card.Name .. "_Slot"
	wrapper:SetAttribute("UIKitMotionWrapper", true)
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel = 0
	-- NEVER clip: the whole point is to let the card grow beyond these bounds.
	wrapper.ClipsDescendants = false
	wrapper.Size = card.Size
	wrapper.Position = card.Position
	wrapper.AnchorPoint = card.AnchorPoint
	wrapper.LayoutOrder = card.LayoutOrder
	wrapper.ZIndex = card.ZIndex
	wrapper.Visible = card.Visible

	-- ===== THE WRAPPER MUST INHERIT THE CARD'S SIZE CONSTRAINTS =====
	-- Copy `UIAspectRatioConstraint` / `UISizeConstraint` across. Without this the wrapper takes the
	-- card's raw `Size` -- typically {1,0},{1,0} -- while the CARD's own aspect constraint squares it
	-- off, so the layout slot ends up far taller than the card it holds. Measured: a 175x175 unit
	-- card produced a 175x405 slot, and every card then floated vertically centred in dead space
	-- that was not there before. The card keeps its own copy too, so both agree on the shape.
	for _, c in ipairs(card:GetChildren()) do
		if c:IsA("UIAspectRatioConstraint") or c:IsA("UISizeConstraint") then
			c:Clone().Parent = wrapper
		end
	end

	wrapper.Parent = parent

	-- The card now fills the wrapper and is centre-anchored, so its UIScale grows it about its own
	-- middle instead of its top-left corner.
	card.Size = UDim2.fromScale(1, 1)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Visible = true
	card.Parent = wrapper

	local uiScale = card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	uiScale.Parent = card
	return wrapper, uiScale
end

-- The instance the LAYOUT sees for this card -- the wrapper when isolated, else the card itself.
-- Show/hide and re-order through this, never through the card, or a filtered-out card will leave a
-- visible hole where its wrapper still sits.
function Motion.layoutNode(card: GuiObject): GuiObject
	local p = card.Parent
	if p and p:IsA("GuiObject") and p:GetAttribute("UIKitMotionWrapper") then
		return p
	end
	return card
end

function Motion.setVisible(card: GuiObject, visible: boolean)
	Motion.layoutNode(card).Visible = visible
end

function Motion.setLayoutOrder(card: GuiObject, order: number)
	Motion.layoutNode(card).LayoutOrder = order
end

-- Destroy a card AND its wrapper, so repeated rebuilds cannot leave orphaned empty slots behind
-- that silently pad the layout.
function Motion.destroy(card: GuiObject)
	local node = Motion.layoutNode(card)
	if node ~= card then
		node:Destroy()
	else
		card:Destroy()
	end
end

-- ===== scaling =====
local activeScaleTweens: { [UIScale]: Tween } = {}

-- state: "hover" | "press" | "rest"
function Motion.scaleTo(uiScale: UIScale?, state: string, baseScale: number?)
	if not uiScale then return end
	local base = baseScale or 1
	local t = Motion.Tuning
	local target, time
	if state == "press" then
		target, time = base * t.PressScale, t.PressTime
	elseif state == "hover" then
		target, time = base * t.HoverScale, t.HoverTime
	else
		target, time = base, t.RestTime
	end
	local prev = activeScaleTweens[uiScale]
	if prev then prev:Cancel() end
	local tween = TweenService:Create(uiScale, info(time), { Scale = target })
	activeScaleTweens[uiScale] = tween
	tween:Play()
end

-- Lift a hovered card above its neighbours. Applied to the WRAPPER when there is one, because that
-- is the instance the layout stacks.
function Motion.lift(card: GuiObject, on: boolean)
	local node = Motion.layoutNode(card)
	local base = node:GetAttribute("UIKitBaseZIndex")
	if base == nil then
		base = node.ZIndex
		node:SetAttribute("UIKitBaseZIndex", base)
	end
	node.ZIndex = on and ((base :: number) + Motion.Tuning.HoverZIndexLift) or (base :: number)
end

-- ===== idle gradient drift =====
-- Seamless because `TierConfig.seamlessSequence` tiles the palette and wraps it, so sliding Offset
-- from -1 to 1 has no visible seam to hitch on. Linear on purpose: any eased curve would make the
-- sheen visibly slow down and speed up once per loop.
--
-- Returns the Tween so a caller that destroys the card can Cancel it.
function Motion.idleGradient(grad: UIGradient?, periodOverride: number?): Tween?
	if not grad then return nil end
	grad.Rotation = Motion.Tuning.GradientRotation
	grad.Offset = Vector2.new(-1, 0)
	local period = periodOverride or Motion.Tuning.IdleGradientPeriod
	local tween = TweenService:Create(
		grad,
		TweenInfo.new(period, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Offset = Vector2.new(1, 0) }
	)
	tween:Play()
	return tween
end

-- Convenience for the common card: isolate it, start its idle sheen, and return the UIScale plus
-- the idle tween. Callers still bind their own MouseEnter/Leave, because what a hover MEANS differs
-- per screen (preview popup, selection, placement) even though the motion does not.
function Motion.prepareCard(card: GuiObject, gradient: UIGradient?): (UIScale, Tween?)
	local _, uiScale = Motion.isolate(card)
	local idle = Motion.idleGradient(gradient)
	return uiScale, idle
end

return Motion
