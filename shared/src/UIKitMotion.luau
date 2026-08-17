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
-- TierConfig DECIDES which colours a hover stroke should use; this module APPLIES that to the
-- actual Instances. Keeping the split means the config module never touches a GuiObject.
local TierConfig = require(game:GetService("ReplicatedStorage").Configs.Meta.TierConfig)

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
	-- ===== OPEN / CLOSE SLIDE (B28) =====
	-- Opening is the unhurried leg (like RestTime); closing gets out of the way faster than it
	-- arrived, because a screen you have dismissed should not make you wait for it.
	SlideInTime = 0.34,
	SlideOutTime = 0.20,
	-- Travel, as a fraction of the PARENT's axis. Deliberately parent-relative SCALE and not
	-- measured pixels -- see the note above Motion.slideIn.
	SlideDistance = 0.35,
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

-- ===== HOVER STROKE PAINT =====
-- Applies `TierConfig.HoverStrokePaint`. Two shapes, and the second is the B27d user rule:
--   * a TWO-colour tier (authored main + derived dark) -> one flat `stroke.Color`, the brightest.
--   * a THREE-OR-MORE colour tier (Mythic's rainbow, any future authored palette) -> ALL of them,
--     as a child `UIGradient` on the stroke, drifting on the same slow 45-degree idle as the card.
--
-- Two details that are easy to get wrong. **`stroke.Color` is forced to white in the gradient case**
-- because a UIStroke MULTIPLIES its Color with a child UIGradient -- leaving the old tier colour
-- there would tint the whole rainbow toward it. And **a stale gradient is destroyed** when a tier
-- falls back to two colours, or a card recycled from a Mythic to a Rare would keep outlining in
-- rainbow forever.
function Motion.paintHoverStroke(stroke: UIStroke?, tier: string)
	if not stroke then return end
	local color, seq = TierConfig.HoverStrokePaint(tier)
	local grad = stroke:FindFirstChildOfClass("UIGradient")
	if seq then
		if not grad then
			grad = Instance.new("UIGradient")
			grad.Parent = stroke
		end
		;(grad :: UIGradient).Color = seq
		stroke.Color = Color3.new(1, 1, 1)
		Motion.idleGradient(grad)
	else
		if grad then grad:Destroy() end
		stroke.Color = color or Color3.new(1, 1, 1)
	end
end

-- ===== OPEN / CLOSE SLIDE (B28) =====
-- The user's ask, verbatim (B27 queue): "I also need animations when opening in closing, Like
-- sliding up, not just popping visible and invisible."
--
-- It lives HERE, not in the screens, for the same reason hover does: a fourth animation dialect is
-- exactly what this module exists to prevent.
--
-- THREE THINGS MAKE THIS HARDER THAN IT LOOKS. All three are handled here so no screen repeats them:
--
--   1. EVERY screen in this project toggles `ScreenGui.Enabled`, and a DISABLED ScreenGui DOES NOT
--      LAY OUT -- everything under it reads `AbsoluteSize = 0`. So `slideIn` enables the gui BEFORE
--      it touches Position, and `slideOut` disables it only AFTER the close tween completes.
--   2. Because of (1), the travel is expressed in PARENT-RELATIVE SCALE and never in measured
--      pixels. A measured slide would have to wait a frame for AbsoluteSize to stop being zero, and
--      "a harness that reports 0 or 0x0 is usually the harness" is the most repeated false alarm in
--      this project's history. Scale needs no measurement and a disabled gui cannot fool it.
--   3. The designer's authored resting Position is CANON. It is captured ONCE into the
--      `UIKitRestPosition` attribute -- UDim2 is a real attribute type, so the value is visible in
--      Studio, survives a module reload, and is not re-derived from a frame that may already be
--      mid-slide. Every tween runs TO or FROM that stored value. No screen coordinate is ever
--      hardcoded in this module.
--
-- RE-ENTRANCY: a fast open/close/open must never strand a screen enabled-but-off-screen. Each call
-- takes a token; a completion callback holding a stale token does nothing. That is precisely what
-- stops a late slideOut from disabling a gui the user has already reopened.

local REST_ATTR = "UIKitRestPosition"

local slideTweens: { [GuiObject]: Tween } = {}
local slideTokens: { [GuiObject]: number } = {}
local slideState: { [GuiObject]: string } = {} -- "open" | "closed" | "opening" | "closing"

-- Unit vectors, scaled by Tuning.SlideDistance. "up" means the panel STARTS BELOW its rest position
-- and travels upward into place -- which is what the user asked for, so it is the default.
local SLIDE_DIRECTIONS: { [string]: Vector2 } = {
	up = Vector2.new(0, 1),
	down = Vector2.new(0, -1),
	left = Vector2.new(1, 0),
	right = Vector2.new(-1, 0),
}

-- The authored resting Position, captured once and never re-derived.
function Motion.restPosition(frame: GuiObject): UDim2
	local stored = frame:GetAttribute(REST_ATTR)
	if typeof(stored) == "UDim2" then
		return stored
	end
	frame:SetAttribute(REST_ATTR, frame.Position)
	return frame.Position
end

local function offsetFrom(rest: UDim2, direction: string?, distance: number?): UDim2
	local vec = SLIDE_DIRECTIONS[direction or "up"] or SLIDE_DIRECTIONS.up
	local d = distance or Motion.Tuning.SlideDistance
	return UDim2.new(
		rest.X.Scale + vec.X * d, rest.X.Offset,
		rest.Y.Scale + vec.Y * d, rest.Y.Offset
	)
end

local function screenGuiOf(frame: GuiObject, opts: { [string]: any }?): ScreenGui?
	local given = opts and opts.gui
	if given then return given end
	return frame:FindFirstAncestorWhichIsA("ScreenGui")
end

local function stopSlide(frame: GuiObject)
	local prev = slideTweens[frame]
	if prev then
		prev:Cancel()
		slideTweens[frame] = nil
	end
end

local function nextToken(frame: GuiObject): number
	local t = (slideTokens[frame] or 0) + 1
	slideTokens[frame] = t
	return t
end

-- opts: { gui: ScreenGui?, direction: string?, distance: number?, time: number?, onComplete: () -> ()? }
-- Returns the Tween so a caller can await `.Completed` or Cancel it.
function Motion.slideIn(frame: GuiObject, opts: { [string]: any }?): Tween?
	if not frame then return nil end
	opts = opts or {}
	local rest = Motion.restPosition(frame)
	local gui = screenGuiOf(frame, opts)

	stopSlide(frame)
	local token = nextToken(frame)
	slideState[frame] = "opening"

	-- ENABLE FIRST: a disabled ScreenGui does not lay out, so nothing under it can be positioned
	-- meaningfully until this line has run.
	if gui and not gui.Enabled then
		gui.Enabled = true
	end
	frame.Visible = true
	frame.Position = offsetFrom(rest, opts.direction, opts.distance)

	local tween = TweenService:Create(frame, info(opts.time or Motion.Tuning.SlideInTime), { Position = rest })
	slideTweens[frame] = tween
	tween.Completed:Connect(function()
		if slideTokens[frame] ~= token then return end -- superseded; the newer call owns the frame
		slideTweens[frame] = nil
		slideState[frame] = "open"
		frame.Position = rest
		if opts.onComplete then opts.onComplete() end
	end)
	tween:Play()
	return tween
end

-- Slides the panel away and only THEN disables its ScreenGui. Pass `{ keepEnabled = true }` when the
-- caller owns the gui's Enabled flag itself.
function Motion.slideOut(frame: GuiObject, opts: { [string]: any }?): Tween?
	if not frame then return nil end
	opts = opts or {}
	-- Already gone: do not re-run, or a second call would re-disable a gui somebody just reopened.
	if slideState[frame] == "closed" or slideState[frame] == "closing" then return nil end

	local rest = Motion.restPosition(frame)
	local gui = screenGuiOf(frame, opts)

	stopSlide(frame)
	local token = nextToken(frame)
	slideState[frame] = "closing"

	local away = offsetFrom(rest, opts.direction, opts.distance)
	local tween = TweenService:Create(frame, info(opts.time or Motion.Tuning.SlideOutTime), { Position = away })
	slideTweens[frame] = tween
	tween.Completed:Connect(function()
		if slideTokens[frame] ~= token then return end -- reopened mid-close; leave the gui alone
		slideTweens[frame] = nil
		slideState[frame] = "closed"
		-- Restore the authored Position so anything that hard-sets `.Enabled = true` without going
		-- through slideIn still shows the panel where the designer put it, not parked off-screen.
		frame.Position = rest
		if gui and not opts.keepEnabled then
			gui.Enabled = false
		end
		if opts.onComplete then opts.onComplete() end
	end)
	tween:Play()
	return tween
end

-- True while the panel is open or on its way open. Screens use this to make their toggle idempotent
-- and to answer a ScreenOpened announcement without double-closing.
function Motion.isOpen(frame: GuiObject): boolean
	local s = slideState[frame]
	return s == "open" or s == "opening"
end

-- Forget a frame's slide bookkeeping (call from a screen that destroys its panel).
function Motion.forgetSlide(frame: GuiObject)
	stopSlide(frame)
	slideTokens[frame] = nil
	slideState[frame] = nil
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
