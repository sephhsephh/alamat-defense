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
	-- ===== BUTTON HOVER / IDLE / CLICK (B32) =====
	-- The user's HUD-button spec, in the one place the kit's feel is retuned.
	--   * the hover stroke GROWS FROM NOTHING to its authored thickness -- it does not thicken from
	--     a base, which is what `HoverStrokeMult` does for the older buttons.
	--   * its gradient SPINS (Rotation) rather than scrolling (Offset). A spin reads as a rotating
	--     light source on a border; a scroll reads as a progress bar, which is wrong on a frame.
	--   * a click DIPS, then OVERSHOOTS on release, then settles. A click that only dips feels like
	--     nothing happened; the overshoot is what makes it read as a button being pushed.
	StrokeGrowTime = 0.22,
	GradientSpinPeriod = 4,    -- seconds for one full 360-degree turn
	ClickDipScale = 0.93,
	ClickPopScale = 1.10,
	ClickDipTime = 0.06,
	ClickPopTime = 0.10,
	ClickSettleTime = 0.16,
}

-- ===== B68: `SHOW_PLACEHOLDER_PRICES` IS DELETED, AND THAT IS THE POINT =====
-- From B27c until B68 this module carried an off-topic boolean: the user had suspended the standing
-- hide-never-invent rule FOR TESTING (*"show the prices for now, even if its just made it just to
-- see it visually when testing"*), so `PlacementPrice` rendered whatever the TEMPLATE AUTHORED -- a
-- design placeholder, the same invented figure on every card, in both Places. It was parked here
-- because every card consumer already required Motion, which made it the one switch back.
--
-- The instruction attached to it was: "when real prices land, delete this block and fill the label
-- from the real source". B67 landed the source (`UnitStatsCatalog.Costs`) and B68 took the switch
-- out along with its last seven readers. The field is gone rather than set false, deliberately: a
-- dormant flag is an invitation to show a fabricated number again, and `UIKit.UnitCard.paintPrice`
-- now hides a price it cannot substantiate. DO NOT REINTRODUCE IT.

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

-- ===== CLICK: dip -> overshoot -> settle (B32) =====
-- Three short legs on ONE UIScale, sharing `activeScaleTweens` with `scaleTo` so a click and a hover
-- can never fight over the same scale. `onComplete` hands control back to the caller, which then
-- re-asserts its own hover/rest state -- this function deliberately does not guess where to land,
-- because by the time a click finishes the button may have closed the screen it lived on.
function Motion.pressPop(uiScale: UIScale?, baseScale: number?, onComplete: (() -> ())?)
	if not uiScale then return end
	local base = baseScale or 1
	local t = Motion.Tuning
	local prev = activeScaleTweens[uiScale]
	if prev then prev:Cancel() end

	local function leg(scale: number, time: number, style: Enum.EasingStyle, after: (() -> ())?)
		local tween = TweenService:Create(
			uiScale,
			TweenInfo.new(time, style, Enum.EasingDirection.Out),
			{ Scale = scale }
		)
		activeScaleTweens[uiScale] = tween
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			-- A cancelled leg means something else (a hover, another click) has taken the scale over.
			-- Abandoning the chain here is what stops two clicks from interleaving their legs.
			if state ~= Enum.PlaybackState.Completed then return end
			if activeScaleTweens[uiScale] ~= tween then return end
			if after then after() end
		end)
		tween:Play()
	end

	leg(base * t.ClickDipScale, t.ClickDipTime, Enum.EasingStyle.Quad, function()
		-- Back/Out is what produces the overshoot; it is the only place in the kit that is not Quint.
		leg(base * t.ClickPopScale, t.ClickPopTime, Enum.EasingStyle.Back, function()
			if onComplete then onComplete() end
		end)
	end)
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

-- ===== THE SEAMLESS COLOUR LOOP (B108, user: "seamless continuous loop ... perfect continuous
-- synched loop of its colors moving") =====
-- WHY THE OLD DRIFT HAD A SEAM: it slid `UIGradient.Offset` from -1 to 1. A UIGradient CLAMPS to its
-- end colours outside 0..1, so for a large part of every cycle a flat end colour filled the stroke,
-- and at the wrap the bands snapped back. No palette tiling can hide that -- the clamp is the seam.
--
-- THE FIX: never move Offset. Treat the palette as PERIODIC (its last colour meets its first) and
-- shift the colour STOPS themselves by a phase each frame, wrapping the ones that fall off one end
-- back onto the other. The picture at phase 1 is exactly the picture at phase 0, so the loop has no
-- seam at all, at any speed, forever.
--
-- `loopStops(seq)`  -> the periodic stop list for any ColorSequence. A sequence whose first and last
--                      colours already match (TierConfig.seamlessSequence) is used as-is; any other
--                      (an authored 2-3 stop tier) is mirrored -- there and back -- so the authored
--                      colours and their order are kept and the ends meet without a hard edge.
-- `phased(stops, p)`-> the ColorSequence for phase p in [0, 1). At most #stops + 1 keypoints.
type Stop = { t: number, c: Color3 }

local function sameColor(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) < 1e-3 and math.abs(a.G - b.G) < 1e-3 and math.abs(a.B - b.B) < 1e-3
end

function Motion.loopStops(seq: ColorSequence): { Stop }
	local kps = seq.Keypoints
	local stops: { Stop } = {}
	if sameColor(kps[1].Value, kps[#kps].Value) then
		for _, kp in ipairs(kps) do table.insert(stops, { t = kp.Time, c = kp.Value }) end
	else
		for _, kp in ipairs(kps) do table.insert(stops, { t = kp.Time * 0.5, c = kp.Value }) end
		for i = #kps - 1, 1, -1 do table.insert(stops, { t = 1 - kps[i].Time * 0.5, c = kps[i].Value }) end
	end
	return stops
end

-- Colour of the periodic palette at x in [0, 1).
local function sampleStops(stops: { Stop }, x: number): Color3
	for i = 1, #stops - 1 do
		local a, b = stops[i], stops[i + 1]
		if x >= a.t and x <= b.t then
			local span = b.t - a.t
			return if span <= 0 then b.c else a.c:Lerp(b.c, (x - a.t) / span)
		end
	end
	return stops[#stops].c
end

function Motion.phased(stops: { Stop }, phase: number): ColorSequence
	local moved: { Stop } = {}
	-- Every stop but the closing one (it is the same colour as the first, one period on).
	for i = 1, #stops - 1 do
		table.insert(moved, { t = (stops[i].t + phase) % 1, c = stops[i].c })
	end
	table.sort(moved, function(x, y) return x.t < y.t end)
	-- The edges: whatever colour the shifted palette shows at 0 is, by periodicity, also its colour at 1.
	local edge = sampleStops(stops, (1 - phase) % 1)
	local kps = { ColorSequenceKeypoint.new(0, edge) }
	for _, st in ipairs(moved) do
		if st.t > 1e-4 and st.t < 1 - 1e-4 then
			table.insert(kps, ColorSequenceKeypoint.new(st.t, st.c))
		end
	end
	table.insert(kps, ColorSequenceKeypoint.new(1, edge))
	return ColorSequence.new(kps)
end

-- ===== idle gradient drift =====
-- ONE RenderStepped connection drives every looping gradient in the Place. Each gradient keeps its
-- own period; a gradient that is gone (unparented) drops out on its own, and one whose screen is
-- hidden is skipped (no work for what nobody can see). If a caller REPAINTS the gradient (a new tier
-- on a reused card), the driver notices its Color is no longer what it last wrote and adopts the new
-- palette on the next frame -- so no caller needs to know the loop exists.
--
-- Returns a handle with `:Cancel()` (the old return was a Tween; `Cancel` is the only method any
-- caller used, so every existing call site keeps working unchanged).
type Loop = { stops: { Stop }, speed: number, phase: number, written: ColorSequence? }
local loops: { [UIGradient]: Loop } = {}
local loopConn: RBXScriptConnection? = nil
local loopClock = 0

local function visible(grad: UIGradient): boolean
	local layer = grad:FindFirstAncestorWhichIsA("LayerCollector")
	if layer and layer:IsA("ScreenGui") and not layer.Enabled then return false end
	local host = grad.Parent
	while host and host:IsA("UIStroke") do host = host.Parent end
	if host and host:IsA("GuiObject") and not host.Visible then return false end
	return true
end

local function ensureLoopDriver()
	if loopConn or not game:GetService("RunService"):IsClient() then return end
	loopConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
		loopClock += dt
		for grad, e in pairs(loops) do
			if grad.Parent == nil then
				loops[grad] = nil
			elseif visible(grad) then
				local current = grad.Color
				if e.written ~= nil and current ~= e.written then
					e.stops = Motion.loopStops(current) -- repainted by its owner: adopt the new palette
				end
				local seq = Motion.phased(e.stops, (loopClock * e.speed + e.phase) % 1)
				grad.Color = seq
				e.written = seq
			end
		end
	end)
end

-- Loop `grad`'s CURRENT colours. `periodOverride` = seconds per full loop (default Tuning).
-- `opts.Phase` (0..1) staggers a gradient; `opts.Reverse` runs it the other way.
function Motion.loopGradient(grad: UIGradient?, periodOverride: number?, opts: { Phase: number?, Reverse: boolean? }?): { Cancel: (any) -> () }?
	if not grad then return nil end
	grad.Offset = Vector2.new(0, 0)
	local period = math.max(0.1, periodOverride or Motion.Tuning.IdleGradientPeriod)
	local o = opts or {}
	loops[grad] = {
		stops = Motion.loopStops(grad.Color),
		speed = (1 / period) * (if o.Reverse then -1 else 1),
		phase = o.Phase or 0,
		written = nil,
	}
	ensureLoopDriver()
	return {
		Cancel = function(_self)
			loops[grad] = nil
		end,
	}
end

function Motion.idleGradient(grad: UIGradient?, periodOverride: number?): { Cancel: (any) -> () }?
	if not grad then return nil end
	grad.Rotation = Motion.Tuning.GradientRotation
	return Motion.loopGradient(grad, periodOverride)
end

-- ===== SPINNING GRADIENT (B32) =====
-- The idle animation for a bordered button: rotate the gradient forever. Distinct from
-- `idleGradient` above, which slides Offset across a card face -- both exist because they read
-- completely differently, and a button border wants the spin.
--
-- The base Rotation is stored in an ATTRIBUTE for the same reason `UIKitRestPosition` is: the
-- designer's authored value is canon, it stays visible in Studio, it survives a module reload, and
-- it is never re-derived from an instance that may already be mid-spin.
--
-- Idempotent: spinning an already-spinning gradient returns the existing tween rather than stacking
-- a second one, so a controller that re-runs on every hover cannot pile up tweens.
local spinTweens: { [UIGradient]: Tween } = {}
local BASE_ROTATION_ATTR = "UIKitBaseRotation"

function Motion.spinGradient(grad: UIGradient?, periodOverride: number?): Tween?
	if not grad then return nil end
	local existing = spinTweens[grad]
	if existing then return existing end

	local base = grad:GetAttribute(BASE_ROTATION_ATTR)
	if type(base) ~= "number" then
		base = grad.Rotation
		grad:SetAttribute(BASE_ROTATION_ATTR, base)
	end
	grad.Rotation = base :: number

	-- Linear, or the border would visibly stall once per turn. The loop point is invisible because a
	-- full 360 lands exactly where it started.
	local tween = TweenService:Create(
		grad,
		TweenInfo.new(periodOverride or Motion.Tuning.GradientSpinPeriod, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = (base :: number) + 360 }
	)
	spinTweens[grad] = tween
	tween:Play()
	return tween
end

function Motion.stopSpin(grad: UIGradient?)
	if not grad then return end
	local t = spinTweens[grad]
	if t then
		t:Cancel()
		spinTweens[grad] = nil
	end
	local base = grad:GetAttribute(BASE_ROTATION_ATTR)
	if type(base) == "number" then grad.Rotation = base end
end

-- ===== A STROKE THAT GROWS FROM NOTHING (B32) =====
-- `Motion.growStroke(stroke, on, target)` tweens Thickness 0 <-> target and owns `.Enabled`:
-- enabled BEFORE growing, disabled only AFTER shrinking. That ordering is the B27c lesson --
-- a DISABLED UIStroke tweening its Thickness animates nothing at all, which is exactly why the
-- hotbar appeared to have no hover for a whole session.
--
-- Thickness is zeroed only when the stroke was actually off, so re-hovering mid-shrink grows from
-- wherever it had got to instead of snapping back to nothing first.
local strokeTweens: { [UIStroke]: Tween } = {}

function Motion.growStroke(stroke: UIStroke?, on: boolean, target: number, timeOverride: number?): Tween?
	if not stroke then return nil end
	local prev = strokeTweens[stroke]
	if prev then prev:Cancel() end

	if on and not stroke.Enabled then
		stroke.Thickness = 0
		stroke.Enabled = true
	end

	local tween = TweenService:Create(
		stroke,
		info(timeOverride or Motion.Tuning.StrokeGrowTime),
		{ Thickness = if on then target else 0 }
	)
	strokeTweens[stroke] = tween
	if not on then
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed then return end
			if strokeTweens[stroke] ~= tween then return end
			stroke.Enabled = false
			stroke.Thickness = target -- leave the AUTHORED value on the instance, not a tweened 0
			strokeTweens[stroke] = nil
		end)
	end
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
