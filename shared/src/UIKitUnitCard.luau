--!strict
-- UIKitUnitCard.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.UnitCard)
-- Kit CONTROLLER (unit-card presentation). Added B34.
--
-- The two things every screen that shows a `Kit.UnitIconV2` had to do for itself: frame a model in a
-- ViewportFrame, and paint the card in its tier's colours. FOUR screens each carried their own copy
-- (Units, Summon, Index, Ascension) and it was measured at B34 before this module existed:
--   * `setViewportModel` -- Summon / Index / Ascension were BYTE-IDENTICAL to each other; Units
--     differed in exactly one way, the SOURCE of the model (a `modelFor` helper instead of an inline
--     clone). That is a caller's concern, so `viewport()` takes the MODEL and the difference vanishes.
--   * `paintTier` -- Summon / Index / Ascension were again byte-identical; Units additionally ran the
--     idle sheen and forced the hover stroke off. Those are the two `opts` flags below.
-- Four copies of a camera-framing formula is four places for it to drift, and the drift would be
-- silent: a card that frames its model slightly differently on one screen reads as an art bug.
--
-- CLIENT module (ViewportFrames and cameras are a client concern), and it deliberately owns NO state.
--
-- Dependencies are resolved with BOUNDED lookups, never bare waits -- the B32/B33 lesson: a bare
-- WaitForChild in a module required by screen controllers stops being "this feature is missing" and
-- becomes "that screen never finishes booting", with no error to read.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UnitCard = {}

local function optional(parent: Instance?, name: string): Instance?
	if parent == nil then
		return nil
	end
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 10)
end

local function loadOptional(inst: Instance?, label: string): any
	if inst == nil then
		warn("[UIKit.UnitCard] " .. label .. " not found -- that part of card painting is skipped.")
		return nil
	end
	local ok, m = pcall(require, inst)
	if not ok then
		warn("[UIKit.UnitCard] " .. label .. " failed to load: " .. tostring(m))
		return nil
	end
	return m
end

local Motion = loadOptional(optional(script.Parent, "Motion"), "Motion")
local TierConfig = loadOptional(
	optional(optional(optional(ReplicatedStorage, "Configs"), "Meta"), "TierConfig"), "TierConfig")

-- ===== camera framing =====
-- The ONE definition of how a unit is framed in a ViewportFrame. Tune here and every screen follows.
UnitCard.Framing = {
	FieldOfView = 40,
	-- Pull back a little past the exact fit so a model never kisses the frame edge, plus a small
	-- constant so a TINY model does not end up with the camera inside it.
	DistancePadding = 1.3,
	DistanceBias = 2,
	-- Lift the camera a touch so the model is seen very slightly from above rather than dead-on.
	HeightFraction = 0.05,
}

-- Put `model` in `vf` and frame it. The caller owns WHERE the model came from -- that is the single
-- difference the four copies had, and keeping it out here is what let them merge.
-- Returns true when something was framed, false when there was nothing to frame.
function UnitCard.viewport(vf: ViewportFrame?, model: Model?): boolean
	if vf == nil then
		return false
	end
	local wm = vf:FindFirstChildWhichIsA("WorldModel")
	if wm == nil then
		wm = Instance.new("WorldModel")
		wm.Parent = vf
	end
	-- Clear FIRST, unconditionally: a recycled card must not stack the new model on the old one, and
	-- that has to happen even when `model` is nil or the card would keep showing the previous unit.
	for _, c in ipairs(wm:GetChildren()) do
		c:Destroy()
	end
	if model == nil then
		return false
	end
	model.Parent = wm

	local cf, size = model:GetBoundingBox()
	local center = cf.Position
	-- Face the model the way it faces in the world. HumanoidRootPart first, PrimaryPart as the
	-- fallback, and a fixed forward vector if it has neither -- a model with no root is still worth
	-- showing from a sane angle rather than not at all.
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
	local facing = root and (root :: any).CFrame.LookVector or Vector3.new(0, 0, -1)

	local f = UnitCard.Framing
	local maxExtent = math.max(size.X, size.Y, size.Z)
	local dist = (maxExtent * 0.5) / math.tan(math.rad(f.FieldOfView / 2)) * f.DistancePadding
		+ f.DistanceBias

	-- A ViewportFrame has NO camera by default, so one is created on demand and reused. Without this
	-- the frame renders empty and it looks exactly like a missing model.
	local cam = vf:FindFirstChildWhichIsA("Camera")
	if cam == nil then
		cam = Instance.new("Camera")
		cam.Parent = vf
	end
	cam.FieldOfView = f.FieldOfView
	cam.CFrame = CFrame.lookAt(center + facing * dist + Vector3.new(0, size.Y * f.HeightFraction, 0), center)
	vf.CurrentCamera = cam
	return true
end

export type PaintOpts = {
	Idle: boolean?,        -- run Motion's idle sheen on the card gradient (Units' grid does)
	StrokeOff: boolean?,   -- leave the hover stroke disabled after painting (hover-only strokes)
}

-- Paint `root` in `tier`'s colours.
-- The UIGradient lookup is a DIRECT-CHILD lookup on purpose and must stay one: V2 nests further
-- UIGradients under UnitLevel / PlacementPrice / TraitIcon, so a recursive find would repaint one of
-- those instead of the card, which is a bug you have to squint to see.
function UnitCard.paintTier(root: Instance?, tier: string, opts: PaintOpts?)
	if root == nil or TierConfig == nil then
		return
	end
	local o = opts or {}
	local g = root:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = TierConfig.seamlessSequence(tier)
		if o.Idle and Motion then
			-- The kit's period and angle, not any one screen's timing -- the whole point of Motion.
			Motion.idleGradient(g)
		end
	end
	-- THE HOVER STROKE TAKES THE TIER'S BRIGHTEST COLOUR (user rule, B27), chosen by relative
	-- luminance -- never the derived dark secondary, which reads as a shadow instead of a highlight.
	-- B27d: 2-colour tiers outline in that one colour, 3+ colour tiers outline in ALL of them via a
	-- child UIGradient on the stroke. One call; TierConfig decides which.
	local hs = root:FindFirstChild("UIHoverStroke")
	if hs and hs:IsA("UIStroke") then
		if Motion then
			Motion.paintHoverStroke(hs, tier)
		end
		if o.StrokeOff then
			-- Hover-only strokes must go back off after painting, or every card in the grid draws an
			-- outline at rest and the hover says nothing.
			hs.Enabled = false
		end
	end
end

return UnitCard
