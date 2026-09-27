--!strict
-- UIKitUnitCard.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.UnitCard)
-- Kit CONTROLLER (unit-card presentation). Added B34; the PLACEMENT PRICE joined it at B68.
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
-- B68: the ONE source of a unit's placement cost, for every card in BOTH Places. Optional like the
-- other two -- a Place caught mid-deploy must cost the PRICE, never the whole card.
local UnitStatsCatalog = loadOptional(
	optional(optional(optional(ReplicatedStorage, "Configs"), "Meta"), "UnitStatsCatalog"), "UnitStatsCatalog")

-- ===== camera framing =====
-- The ONE definition of how a unit is framed in a ViewportFrame. Tune here and every screen follows.
-- ===== FRAMING (B87: the hotbar's close-up, everywhere) =====
-- User: "change the camera position of viewport frames to match the closeness and orientation of the
-- ones in hotbar. not a wholebody view."
--
-- The old framing FITTED THE WHOLE BOUNDING BOX -- it solved for a distance that put the entire rig
-- on screen, which is a full-body shot by construction and drew every unit as a tiny doll. The
-- hotbar never did that: the user posed ONE camera by hand and B77 baked its placement as attributes
-- (`HotbarCamCFrame` / `HotbarCamFOV` / `HotbarModelPivot` on the Slots frame, because a Camera
-- inside StarterGui does not replicate -- see UIKit.Hotbar for that whole story).
--
-- `Relative` below is that baked pose reduced to the only part worth reusing: where the camera sits
-- RELATIVE TO THE MODEL'S PIVOT (`HotbarModelPivot:ToObjectSpace(HotbarCamCFrame)`). 1.16 studs out,
-- 0.70 up, angled in -- a head-and-shoulders shot rather than a fit. Because it is relative, it
-- reproduces the hotbar's look on any rig without caring where the viewport's world happens to be.
--
-- ⚠ IT IS A FIXED POSE, NOT A FIT. A rig much larger or smaller than a standard R15 body will frame
-- differently -- that is the same deal the hotbar already lives with, and the fix is the same one:
-- re-pose the hotbar camera and re-bake, then paste the new components here.
UnitCard.Framing = {
	FieldOfView = 70,
	Relative = CFrame.new(
		-0.376606, 0.698460, -0.848190,
		-0.913143, 0.096428, -0.396071,
		0.000000, 0.971619, 0.236551,
		0.407640, 0.216005, -0.887227
	),
	-- Where the model is put inside the viewport's own little world. Any anchor works (a WorldModel
	-- has no relationship to the real Workspace); it exists so the camera has something to sit
	-- relative to, and so two cards never disagree about where "here" is.
	Anchor = CFrame.new(0, 0, 0),
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

	local f = UnitCard.Framing

	-- Park the model on the anchor, then hang the camera off it by the baked relative pose. This is
	-- exactly what the hotbar does (`m:PivotTo(anchor)` + the baked camera) -- the model's own pivot
	-- is the reference point, so a rig is framed the same way wherever it was standing before.
	model:PivotTo(f.Anchor)

	-- A ViewportFrame has NO camera by default, so one is created on demand and reused. Without this
	-- the frame renders empty and it looks exactly like a missing model.
	local cam = vf:FindFirstChildWhichIsA("Camera")
	if cam == nil then
		cam = Instance.new("Camera")
		cam.Parent = vf
	end
	cam.FieldOfView = f.FieldOfView
	cam.CFrame = f.Anchor * f.Relative
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

-- ===== PLACEMENT PRICE (B68) =====
-- ONE definition of what a placement cost LOOKS LIKE, for every surface in both Places: the hotbar
-- slot in the Game, and the Units / Index / Summon / Ascension / trait-reroll / stat-reroll cards in
-- the Lobby. It lives here for exactly the reason `viewport` and `paintTier` do -- SEVEN painters of
-- the same field is seven places for it to drift, and "150" on one screen against "\u{20B1}150" on the next
-- is the kind of drift nobody ever files a bug for.
--
-- THE NUMBER is `UnitStatsCatalog.Costs` (B67): shared canon, hash-checked in BOTH Places, and
-- regenerated against the Game's live `TowerConfig.Cost` by its boot validator. That is what makes
-- "the same price everywhere" ENFORCED rather than promised -- the Lobby has no tower configs of its
-- own to read, so nothing else could give the same guarantee.
--
-- ===== HIDE, NEVER INVENT -- THIS IS THE RULE B27c SUSPENDED, NOW BACK IN FORCE =====
-- From B27c until B68 these screens showed `PlacementPrice` filled with **the number the artist
-- typed into the template** -- the same figure for every unit, in both Places, wrong for all of
-- them -- gated behind `Motion.SHOW_PLACEHOLDER_PRICES`. That flag is DELETED at B68 along with the
-- last of its readers. A nil towerId, a non-tower id (Summon chips can be items), or a tower with no
-- catalog entry now renders NOTHING: not a 0, and never the authored placeholder. A zero would claim
-- the tower is free; a hidden label claims nothing at all.
function UnitCard.formatCost(n: number): string
	local s = tostring(math.floor(n))
	-- A comma every three digits from the right. Runs at most twice for this game's values;
	-- gsub-with-a-count is the standard Lua idiom for it.
	while true do
		local replaced
		s, replaced = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then break end
	end
	return "\u{20B1}" .. s
end

-- Paint (or hide) `root`'s PlacementPrice for `towerId`. Pass nil to hide -- that is how an empty or
-- locked hotbar slot, and a card with no unit, ask for nothing rather than for a zero.
function UnitCard.paintPrice(root: Instance?, towerId: string?)
	if root == nil then
		return
	end
	local node = root:FindFirstChild("PlacementPrice", true)
	if node == nil or not node:IsA("GuiObject") then
		return
	end
	local cost: number? = nil
	if UnitStatsCatalog ~= nil and type(towerId) == "string" and towerId ~= "" then
		cost = tonumber(UnitStatsCatalog.GetCost(towerId))
	end
	node.Visible = cost ~= nil
	if cost == nil then
		return
	end
	-- `PlacementPrice` is a Frame WRAPPING a TextLabel on both V2 templates, but resolve either shape:
	-- and do it from the node itself, never by name from the card root. `FindFirstChild(name, true)`
	-- walks DESCENDANTS ONLY and never matches the instance it is called on -- the exact trap that
	-- left the authored "LVL 100" on every hotbar slot at B26.
	local label: TextLabel? = nil
	if node:IsA("TextLabel") then
		label = node
	else
		label = node:FindFirstChildWhichIsA("TextLabel")
	end
	if label ~= nil then
		label.Text = UnitCard.formatCost(cost :: number)
	end
end

-- ===== IDLE IN A VIEWPORT (B78; default idle B79; stepper REMOVED B81) =====
--
-- *** WHY THE UNITS JUST STOOD THERE (B79, user) -- AND THE WRONG FIX THAT SHIPPED WITH IT ***
-- The rigs stood still because none of them carried an `IdleAnim`, so `playIdle` returned early and
-- nothing played at all. The DEFAULT IDLE below is the fix. B79 ALSO added a RenderStepped loop
-- calling the Animator's StepAnimations method, on the belief that a ViewportFrame never advances an
-- Animator. That was wrong twice over: a rig inside a `WorldModel` (which `viewport()` creates, and
-- the hotbar slots use) is animated by the engine like any Workspace rig, and StepAnimations is a
-- PLUGIN-ONLY API -- in a real client it throws "lacking capability Plugin" EVERY FRAME. It was
-- caught in the B81 console and removed. Do not bring it back: a rig that will not animate in a
-- viewport is missing its WorldModel, not a stepper.

-- Roblox's stock R15 idle, used when a model has no `IdleAnim` of its own (user, B79: "or just load
-- a default idle animation if they dont have one"). Override it here the day there is a house idle.
UnitCard.DefaultIdleAnim = "rbxassetid://507766666"

-- ===== IDLE IN A VIEWPORT (B78, user) =====
-- "The idle animations will be played on all the viewport frames that previews a unit."
--
-- THE ID TRAVELS ON THE MODEL, NOT IN A CONFIG. The Game's `TowerConfig.Idle.Anim` is copied onto
-- the spawned rig as the `IdleAnim` attribute, and the display rigs in `TowerModels`/`UnitModels`
-- carry the same attribute -- so a preview asks the MODEL what its idle is. That is what lets the
-- LOBBY animate a unit it has no TowerConfig for (it has none, by design), with one authored id.
--
-- The rig must sit inside a WorldModel in the ViewportFrame (`viewport()` makes one) -- that is
-- what lets the engine animate it -- and needs an AnimationController or a Humanoid. The track is
-- loaded on the rig's own Animator.
--
-- Silent by design: no attribute, no animator, or an unauthored id simply means a still model.
function UnitCard.playIdle(model: Instance?, animId: any): AnimationTrack?
	if model == nil then
		return nil
	end
	if animId == nil then
		animId = model:GetAttribute("IdleAnim")
	end
	if animId == nil then
		-- No authored idle on this rig: fall back to the stock one so a preview is never a statue.
		animId = UnitCard.DefaultIdleAnim
	end
	if type(animId) == "number" then
		animId = "rbxassetid://" .. tostring(math.floor(animId))
	elseif type(animId) == "string" and animId:match("^%d+$") then
		animId = "rbxassetid://" .. animId
	end
	if type(animId) ~= "string" or animId == "" then
		return nil
	end

	local animator: Animator? = nil
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	else
		local controller = model:FindFirstChildOfClass("AnimationController")
		if controller then
			animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", controller)
		end
	end
	if animator == nil then
		return nil
	end

	local ok, track = pcall(function()
		local animation = Instance.new("Animation")
		animation.AnimationId = animId
		local t = (animator :: Animator):LoadAnimation(animation)
		t.Looped = true
		t.Priority = Enum.AnimationPriority.Idle
		t:Play(0)
		return t
	end)
	if ok and track then
		return track
	end
	return nil
end

return UnitCard
