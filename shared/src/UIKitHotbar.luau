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
-- B68: the placement price is painted by `UIKit.UnitCard`, not here. B67 put the LOOKUP and the
-- formatting in this file, and then six Lobby screens needed the identical pair -- so it moved to
-- the kit module that already exists to stop card code being copied. This slot and a Lobby Units
-- card now run the SAME function over the SAME shared catalog, which is the only way "identical in
-- both Places at all times" survives the next screen that wants a price.
local UnitCard = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("UnitCard"))
local Button = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("Button"))
-- Motion: one hover/press curve for the kit, the 45-degree idle sheen, and the wrapper that keeps a
-- scaling slot from shoving its neighbours along the hotbar row.
local Motion = require(RS.Shared.UIKit:WaitForChild("Motion"))

local Hotbar = {}

local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "HotbarSlotV2" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "HotbarSlotV2" },
}

-- Hover preview. Uses the SHARED `Kit.UnitPreviewTemplate`, so both Places pop the same card and
-- editing that one template restyles both. Optional: if it is missing, hover still scales/glows
-- and the preview is simply skipped.
local PREVIEW_TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "UnitPreviewTemplate" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "UnitPreviewTemplate" },
}

local KEY_FOR_SLOT = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
}

local function resolveFrom(paths: { { string } }): GuiObject?
	for _, path in ipairs(paths) do
		local node: Instance? = game
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and node:IsA("GuiObject") then return node end
	end
	return nil
end

local function resolveTemplate(): GuiObject?
	return resolveFrom(TEMPLATE_PATHS)
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

-- ===== B77: THE USER'S AUTHORED HOTBAR (the "V3" slot shape) =====
-- The user rebuilt the hotbar by hand in the Game Place and will paste the SAME ScreenGui into the
-- Lobby, so the DESIGN lives in each Place's GUI rather than in a kit template -- and this file stays
-- the one BEHAVIOUR for both, which is the whole point of the kit.
--
-- A V3 container is recognised by holding `HotbarSlot1`; anything else falls through to the V2 path
-- (the Lobby, until its copy arrives). Keep both until the Lobby is migrated, then delete V2.
--
-- What a V3 slot carries, and what fills it:
--   InnerStroke.UIGradient ... the TIER, from `TierConfig.GradientFor` -- stops AND rotation as authored
--   ViewportFrame ............ the tower's display model
--   BottomInfoFrame .......... UnitNameLabel / TierLabel (+ its own gradient) / TraitIcon
--   UnitLevel ................ "Lv. N"
--   DeploymentPriceLabel ..... the REAL placement cost from `UnitStatsCatalog` (never a placeholder)
--   Overlay .................. the dim: locked, empty, and whatever the Place layers on (`setOverlay`)
--
-- HOVER (user's spec): the InnerStroke gradient tweens smoothly to WHITE and back. A ColorSequence
-- cannot be tweened, so a NumberValue is tweened and every keypoint is lerped toward white on its
-- Changed -- one tween per slot, no RunService loop, and it lands exactly on white or exactly on the
-- authored tier gradient rather than somewhere in between.
local TweenService = game:GetService("TweenService")
local UnitStatsCatalog = require(meta:WaitForChild("UnitStatsCatalog"))
local StatGradeConfig = require(meta:WaitForChild("StatGradeConfig"))
local traitsFolder = RS:FindFirstChild("Configs") and RS.Configs:FindFirstChild("Traits")
local TraitRegistry = (traitsFolder and traitsFolder:FindFirstChild("TraitRegistry"))
	and require(traitsFolder.TraitRegistry) or nil

local HOVER_TIME = 0.18
local HOVER_INFO = TweenInfo.new(HOVER_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ===== THE LIVING TIER STROKE (B79, user) =====
-- "animate the uistroke with tier colors, like rotating, at random speed so they dont look that
-- synched. and unique animations of colors."
--
-- Every slot gets its OWN randomised spin speed, direction and phase, so a row of six never marches
-- in lockstep -- that synchronised look is what makes an animated UI read as cheap. On top of the
-- spin, the motion DIFFERS BY WHAT THE TIER IS:
--   multi-stop tiers (Rare, Legendary, Mythic, Limited, Secret, Alamat) SCROLL their gradient, so
--       the bands travel around the card and the tier reads as alive
--   flat tiers (Common, Uncommon, Epic) have nothing to scroll, so they BREATHE instead: the colour
--       lifts toward white and back on a slow sine, each at its own rate
-- One RenderStepped connection drives all six slots; the per-slot numbers live on the slot.
local RunService = game:GetService("RunService")

local SPIN_MIN, SPIN_MAX = 6, 20        -- degrees per second
local SCROLL_MIN, SCROLL_MAX = 0.06, 0.22 -- gradient offsets per second
local BREATHE_MIN, BREATHE_MAX = 0.35, 0.8 -- cycles per second
local BREATHE_DEPTH = 0.22              -- how far a flat tier lifts toward white

-- The tier's authored gradient, lerped `t` of the way to white.
local function whitened(tierName: string, t: number): ColorSequence
	local kps = {}
	for _, stop in ipairs(TierConfig.get(tierName).Stops) do
		table.insert(kps, ColorSequenceKeypoint.new(stop[1], stop[2]:Lerp(Color3.new(1, 1, 1), t)))
	end
	return ColorSequence.new(kps)
end

-- 1000 -> "\u{20B1}1,000". The peso sign is the game's currency mark; thousands are separated because a
-- price is read at a glance mid-match and "12000" vs "120000" is one glance too many.
local function peso(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	out = out:gsub("^,", "")
	return "\u{20B1}" .. out
end

local function short(n: number): string
	if n >= 1e6 then return string.format("%.2fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.2fk", n / 1e3) end
	return string.format("%.4g", n)
end

-- ===== V3 MODEL SWAP: THE AUTHORED CAMERA IS NOT OURS TO TOUCH (user, B77) =====
-- `showModel` above builds a Camera and frames it itself. That is right for the V2 kit slot, whose
-- viewport ships empty -- and WRONG here: the user set these viewports up, so the rule is "the one
-- already set up should be the one used". This loader therefore NEVER creates, moves or assigns a
-- Camera; it only swaps the model.
--
-- What it does preserve is WHERE the model stands. The authored placeholder rig sits at a specific
-- pivot and the framing is built around that spot, so the first swap records that pivot on the
-- ViewportFrame (an attribute, so it survives the placeholder being gone) and every model after it
-- is pivoted to the same place. Without that, a tower whose model was built at a different origin
-- would drift out of frame and look like the camera broke.
-- The camera a viewport is already using: its `CurrentCamera`, or a Camera child that was authored
-- but never assigned (a Camera sitting in a ViewportFrame renders NOTHING until CurrentCamera
-- points at it -- an easy thing to miss in the explorer).
local function cameraFrom(vf: ViewportFrame?): Camera?
	if vf == nil then return nil end
	return vf.CurrentCamera or vf:FindFirstChildWhichIsA("Camera")
end

-- ===== THE USER'S FRAMING, AND WHY IT IS STORED AS ATTRIBUTES =====
-- The user positioned ONE camera, `HotbarSlot1.ViewportFrame.VPCamera`, and asked for that framing.
--
-- WARNING, AND IT COST A PLAYTEST: **A `Camera` INSIDE `StarterGui` DOES NOT REACH `PlayerGui`.**
-- Cameras do not replicate, so the authored VPCamera is simply absent from the copy the player gets --
-- `CurrentCamera` reads nil on every slot at runtime and the viewport falls back to Roblox's default
-- framing (model tiny and low). Cloning "the reference camera" therefore cannot work at runtime: by
-- then there is nothing to clone.
--
-- So the framing travels as ATTRIBUTES, which do replicate and do survive the paste into the other
-- Place: `HotbarCamCFrame` + `HotbarCamFOV` on the Slots container (`tools/bake_hotbar_camera` in the
-- session notes -- re-bake after MOVING the authored camera). A viewport that somehow has a live
-- camera keeps it untouched; otherwise one is built from those numbers.
local function ensureCamera(vf: ViewportFrame, cf: CFrame?, fov: number?)
	local own = cameraFrom(vf)
	if own ~= nil then
		vf.CurrentCamera = own -- a Camera child that was never assigned renders nothing
		return
	end
	if cf == nil then return end
	local cam = Instance.new("Camera")
	cam.Name = "VPCamera"
	cam.CFrame = cf
	cam.FieldOfView = fov or 70
	cam.Parent = vf
	vf.CurrentCamera = cam
end

-- `anchorOverride` is the WHERE that goes with the baked camera. The two must travel together: a
-- shared camera pointed at slot 1's spot, with each slot dropping its model wherever ITS own old
-- placeholder happened to stand, put five of six models ~59 studs out of frame (caught live, B77).
local function showModelKeepCamera(vf: ViewportFrame, modelSource: Instance?, towerId: string?, cf: CFrame?, fov: number?, anchorOverride: CFrame?)
	ensureCamera(vf, cf, fov)
	local wm = vf:FindFirstChildWhichIsA("WorldModel")
	if wm == nil then
		wm = Instance.new("WorldModel")
		wm.Parent = vf
	end
	local anchor: any = anchorOverride
	if typeof(anchor) ~= "CFrame" then
		anchor = vf:GetAttribute("HotbarModelPivot")
	end
	if typeof(anchor) ~= "CFrame" then
		local existing = (wm :: Instance):FindFirstChildWhichIsA("Model")
		if existing then
			anchor = existing:GetPivot()
			vf:SetAttribute("HotbarModelPivot", anchor)
		end
	end
	for _, c in ipairs((wm :: Instance):GetChildren()) do
		c:Destroy()
	end
	if not (modelSource and towerId) then return end
	local src = modelSource:FindFirstChild(towerId) or modelSource:FindFirstChild("Placeholder")
	if not src then return end
	local m = src:Clone()
	-- A display rig must never run code inside a ViewportFrame.
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
	m.Parent = wm
	if typeof(anchor) == "CFrame" and m:IsA("Model") then
		m:PivotTo(anchor)
	end
	-- B78: the unit breathes in its slot. The id comes off the MODEL (`IdleAnim` attribute), so this
	-- works in both Places and needs no config the Lobby does not have.
	UnitCard.playIdle(m, nil)
end

local function attachV3(container: GuiObject, opts: { [string]: any })
	local screen = container:FindFirstAncestorWhichIsA("ScreenGui")

	-- The authored slots ARE the design, so they are painted in place rather than replaced by kit
	-- clones (the V2 path's `Kit.HotbarSlotV2` does not exist in this shape). Sorted by the number in
	-- the name; a GUI shipping fewer than MaxSlots gets clones of slot 1 so the row never has a hole.
	local authored: { GuiButton } = {}
	for _, c in ipairs(container:GetChildren()) do
		if c:IsA("GuiButton") and string.match(c.Name, "^HotbarSlot%d+$") then
			table.insert(authored, c)
		end
	end
	table.sort(authored, function(a, b)
		return (tonumber(string.match(a.Name, "%d+")) or 0) < (tonumber(string.match(b.Name, "%d+")) or 0)
	end)
	assert(#authored > 0, "UIKit.Hotbar: a V3 container must hold at least HotbarSlot1")

	-- The user's framing: a live camera if one somehow exists (Edit mode, or a Place that builds its
	-- own), else the baked attributes. Read from the container first so one bake covers every slot.
	local firstViewport = authored[1]:FindFirstChildWhichIsA("ViewportFrame")
	local liveCamera = cameraFrom(firstViewport)
	local camCFrame: CFrame? = if liveCamera then liveCamera.CFrame else nil
	local camFOV: number? = if liveCamera then liveCamera.FieldOfView else nil
	if camCFrame == nil then
		local a = container:GetAttribute("HotbarCamCFrame") or (firstViewport and firstViewport:GetAttribute("HotbarCamCFrame"))
		local f = container:GetAttribute("HotbarCamFOV") or (firstViewport and firstViewport:GetAttribute("HotbarCamFOV"))
		if typeof(a) == "CFrame" then
			camCFrame = a
			camFOV = if type(f) == "number" then f else 70
		end
	end
	if camCFrame == nil then
		warn("[UIKit.Hotbar] no viewport framing found -- set HotbarCamCFrame/HotbarCamFOV on the Slots " ..
			"frame (a Camera authored in StarterGui does NOT reach PlayerGui). Falling back to Roblox's default.")
	end

	-- ...and the spot that camera is aimed at, so every slot stands its model where slot 1's authored
	-- one stands. Baked as `HotbarModelPivot` on the same container; in Edit mode (or before a bake) it
	-- is read live from slot 1's authored model.
	local camAnchor: any = container:GetAttribute("HotbarModelPivot")
	if typeof(camAnchor) ~= "CFrame" then
		local wm = firstViewport and firstViewport:FindFirstChildWhichIsA("WorldModel")
		local authoredModel = wm and wm:FindFirstChildWhichIsA("Model")
		camAnchor = authoredModel and authoredModel:GetPivot() or nil
	end

	local rng = Random.new()
	local slots: { any } = {}
	for i = 1, LoadoutConfig.MaxSlots do
		local btn = authored[i]
		if btn == nil then
			btn = authored[1]:Clone()
			btn.Name = "HotbarSlot" .. i
			btn.Parent = container
		end
		btn.LayoutOrder = i
		btn.Visible = true
		-- WARNING: THE AUTHORED BUTTONS SHIP WITH `Active = false`, AND A GuiButton THAT IS NOT ACTIVE
		-- NEVER FIRES `Activated` -- clicking did nothing while keys 1-6 still worked, because the keys
		-- come from UserInputService and never touch the button (user, B77). Forced on here rather than
		-- fixed by hand in the GUI, so the Lobby's pasted copy cannot inherit the same dead click.
		btn.Active = true
		local info = btn:FindFirstChild("BottomInfoFrame")
		local stroke = btn:FindFirstChild("InnerStroke")
		slots[i] = {
			Button = btn,
			Stroke = stroke,
			Gradient = stroke and stroke:FindFirstChildOfClass("UIGradient") or nil,
			Viewport = btn:FindFirstChildWhichIsA("ViewportFrame"),
			Name = info and info:FindFirstChild("UnitNameLabel") or nil,
			Tier = info and info:FindFirstChild("TierLabel") or nil,
			Trait = info and info:FindFirstChild("TraitIcon") or nil,
			Level = btn:FindFirstChild("UnitLevel"),
			Price = btn:FindFirstChild("DeploymentPriceLabel"),
			Overlay = btn:FindFirstChild("Overlay"),
			TierName = "Common",
			-- B79: this slot's own motion. Randomised per slot AND per session, so two players' hotbars
			-- are not in step either.
			Spin = rng:NextNumber(SPIN_MIN, SPIN_MAX) * (if rng:NextInteger(0, 1) == 0 then 1 else -1),
			Scroll = rng:NextNumber(SCROLL_MIN, SCROLL_MAX) * (if rng:NextInteger(0, 1) == 0 then 1 else -1),
			Breathe = rng:NextNumber(BREATHE_MIN, BREATHE_MAX),
			Phase = rng:NextNumber(0, math.pi * 2),
			BaseRotation = 0,
			Multi = false,
			Hovered = false,
			Proxy = Instance.new("NumberValue"),
			Tween = nil :: Tween?,
			Conns = {} :: { RBXScriptConnection },
		}
	end
	-- Anything past MaxSlots is a PALETTE SAMPLE the user left in the GUI, not a usable slot.
	for i = LoadoutConfig.MaxSlots + 1, #authored do
		authored[i].Visible = false
	end

	local entries: { [number]: any } = {}
	local playerLevel = 1

	-- ===== the hover preview =====
	local preview: GuiObject? = nil
	local previewSource = screen and screen:FindFirstChild("UnitHoverPreviewTemplate", true)
	if previewSource and previewSource:IsA("GuiObject") and screen then
		previewSource.Visible = false -- the master is a design, never a live card
		preview = previewSource:Clone()
		;(preview :: GuiObject).Name = "HotbarHoverPreview"
		;(preview :: GuiObject).Visible = false
		;(preview :: GuiObject).ZIndex = 50
		;(preview :: GuiObject).Parent = screen
	end

	-- B29's rule, kept: a hide must prove it still OWNS the preview, because MouseLeave(previous) is
	-- NOT guaranteed to arrive before MouseEnter(next) and a stale leave would blank the card the new
	-- slot just filled.
	local previewOwner: GuiObject? = nil
	local function hidePreview(requester: GuiObject?)
		if requester ~= nil and previewOwner ~= nil and previewOwner ~= requester then
			return
		end
		previewOwner = nil
		if preview then preview.Visible = false end
	end

	local function label(root: Instance?, name: string): TextLabel?
		local n = root and root:FindFirstChild(name, true)
		return (n and n:IsA("TextLabel")) and n or nil
	end

	local function paintTierGradient(holder: Instance?, tierName: string)
		if holder == nil then return end
		local g = holder:FindFirstChildOfClass("UIGradient")
		if g == nil then return end
		local seq, rotation = TierConfig.GradientFor(tierName)
		g.Color = seq
		g.Rotation = rotation
	end

	local function showPreview(slotBtn: GuiObject, entry: any)
		if not (preview and entry) then return end
		previewOwner = slotBtn
		local towerId = entry.TowerId
		local tierName = entry.Tier or ItemCatalog.GetTier(towerId)
		local name = entry.Name or ItemCatalog.GetName(towerId)
		local ascension = tonumber(entry.Ascension) or 0

		local nameLabel = label(preview, "UnitNameLabel")
		if nameLabel then
			nameLabel.Text = if ascension > 0 then string.format("%s (A%d)", name, ascension) else name
		end
		local tierHolder = preview:FindFirstChild("TierLabel", true)
		local tierLabel = label(tierHolder, "TierLabel") or label(preview, "TierLabel")
		if tierLabel then
			tierLabel.Text = string.upper(tierName)
			paintTierGradient(tierLabel, tierName)
		end
		local levelLabel = label(tierHolder, "UnitLevel") or label(preview, "UnitLevel")
		if levelLabel then
			levelLabel.Text = "Lv. " .. tostring(entry.Level or entry.MetaLevel or 1)
		end

		-- BASE stats (tier 1 / ML 1 / mid-roll / ascension 0) from the shared catalog, plus THIS
		-- unit's own roll grades. Resolved in-match numbers are deliberately not shown: only the Game
		-- can compute them, and a card that means two different things in the two Places is worse than
		-- one that always means "the unit's base line".
		local base = UnitStatsCatalog.Get(towerId) or {}
		local rolls = entry.StatRolls or {}
		local grades = entry.Grades
		for _, stat in ipairs({ "DMG", "SPA", "RNG" }) do
			local frame = preview:FindFirstChild(stat .. "StatFrame", true)
			if frame then
				local value = (base :: any)[stat]
				local valueLabel = label(frame, "StatLabel")
				if valueLabel then
					valueLabel.Text = if type(value) == "number" then short(value) else "-"
				end
				local gradeLabel = label(frame, "StatTier")
				if gradeLabel then
					local grade = grades and grades[stat] or nil
					local colour: Color3? = nil
					if grade == nil and type((rolls :: any)[stat]) == "number" then
						grade, colour = StatGradeConfig.GradeForRoll((rolls :: any)[stat])
					end
					gradeLabel.Text = grade or "-"
					if colour then gradeLabel.TextColor3 = colour end
				end
			end
		end

		-- Chips. TRAIT shows the trait's name, SHINY only for a shiny unit, and ELEMENT reads "None"
		-- until the element system lands (user: "I'm adding elements soon") -- it is wired to
		-- `entry.Element` already, so the day that field exists the chip fills itself.
		local chips = preview:FindFirstChild("ElementsTraitsFrame", true)
		if chips then
			local traitChip = chips:FindFirstChild("Trait")
			local traitName = entry.Trait or entry.ActiveTrait
			if traitChip and traitChip:IsA("GuiObject") then
				traitChip.Visible = traitName ~= nil and traitName ~= "None"
				local l = traitChip:FindFirstChildWhichIsA("TextLabel")
				if l then l.Text = tostring(traitName) end
			end
			local elementChip = chips:FindFirstChild("Element")
			if elementChip and elementChip:IsA("GuiObject") then
				local l = elementChip:FindFirstChildWhichIsA("TextLabel")
				if l then l.Text = tostring(entry.Element or "None") end
			end
			local shinyChip = chips:FindFirstChild("Shiny")
			if shinyChip and shinyChip:IsA("GuiObject") then
				shinyChip.Visible = entry.Shiny == true
			end
		end

		local vf = preview:FindFirstChildWhichIsA("ViewportFrame", true)
		if vf then
			showModelKeepCamera(vf, opts.ModelSource, towerId, camCFrame, camFOV, camAnchor)
			-- B79: the hover card's unit idles too, not just the slot.
			local wm = vf:FindFirstChildWhichIsA("WorldModel")
			local shown = wm and wm:FindFirstChildWhichIsA("Model")
			if shown then UnitCard.playIdle(shown, nil) end
		end
		-- THE TIER COLOUR GOES ON `UnitFrame.UIStroke` ONLY (user, B77). The card's own outer strokes are
		-- the design's frame and stay exactly as authored -- painting them tinted the whole card.
		local unitFrame = preview:FindFirstChild("UnitFrame", true)
		local unitStroke = unitFrame and unitFrame:FindFirstChildWhichIsA("UIStroke")
		if unitStroke then paintTierGradient(unitStroke, tierName) end

		-- Sit ABOVE the hovered slot, clamped so it never runs off either edge.
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local pw = preview.AbsoluteSize.X > 0 and preview.AbsoluteSize.X or vp.X * 0.22
		local ph = preview.AbsoluteSize.Y > 0 and preview.AbsoluteSize.Y or vp.Y * 0.28
		local x = slotBtn.AbsolutePosition.X + slotBtn.AbsoluteSize.X * 0.5 - pw * 0.5
		local y = slotBtn.AbsolutePosition.Y - ph - 12
		preview.Position = UDim2.fromOffset(math.clamp(x, 8, math.max(8, vp.X - pw - 8)), math.max(8, y))
		preview.Visible = true
	end

	-- ===== painting one slot =====
	local function paint(i: number)
		local s = slots[i]
		if s == nil then return end
		local entry = entries[i]
		local unlocked = LoadoutConfig.IsSlotUnlocked(i, playerLevel)
		local filled = unlocked and entry ~= nil

		local tierName = "Common"
		if filled then
			tierName = entry.Tier or ItemCatalog.GetTier(entry.TowerId)
		end
		s.TierName = tierName
		if s.Gradient then
			local seq, rotation = TierConfig.GradientFor(tierName)
			s.Gradient.Color = seq
			s.Gradient.Rotation = rotation
			-- B79: the authored rotation is where this tier's spin STARTS from, and whether the tier has
			-- more than one colour decides whether it scrolls or breathes.
			s.BaseRotation = rotation
			s.Multi = TierConfig.isMultiColor(tierName)
			s.Gradient.Offset = Vector2.new(0, 0)
		end

		if s.Viewport then showModelKeepCamera(s.Viewport, opts.ModelSource, filled and entry.TowerId or nil, camCFrame, camFOV, camAnchor) end

		local nameLabel = s.Name and (s.Name :: any)
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = if filled then (entry.Name or ItemCatalog.GetName(entry.TowerId))
				elseif unlocked then ""
				else "LOCKED"
		end
		if s.Tier and s.Tier:IsA("TextLabel") then
			s.Tier.Text = if filled then string.upper(tierName) else ""
			paintTierGradient(s.Tier, tierName)
		end
		if s.Level and s.Level:IsA("TextLabel") then
			-- A locked slot shows the level it OPENS at, which is the one number that makes a locked
			-- slot useful instead of merely dark.
			s.Level.Text = if filled then "Lv. " .. tostring(entry.MetaLevel or entry.Level or 1)
				elseif unlocked then ""
				else "Lv. " .. tostring(LoadoutConfig.RequiredLevel(i))
			s.Level.Visible = filled or not unlocked
		end
		if s.Price and s.Price:IsA("TextLabel") then
			local cost = filled and UnitStatsCatalog.GetCost(entry.TowerId) or nil
			s.Price.Text = if type(cost) == "number" then peso(cost) else ""
			s.Price.Visible = type(cost) == "number"
		end
		if s.Trait and s.Trait:IsA("ImageLabel") then
			local traitName = filled and (entry.Trait or entry.ActiveTrait) or nil
			local icon = (TraitRegistry and traitName) and TraitRegistry.Icon(traitName) or nil
			s.Trait.Image = icon or s.Trait.Image
			s.Trait.Visible = icon ~= nil
		end
		if s.Overlay and s.Overlay:IsA("GuiObject") then
			-- The kit owns LOCKED and EMPTY; a Place layers its own states on top with `setOverlay`.
			s.Overlay.Visible = true
			s.Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
			s.Overlay.BackgroundTransparency = if not unlocked then 0.25 elseif entry == nil then 0.55 else 1
		end
	end

	-- ===== hover: the gradient goes white and comes back (user's spec) =====
	local function hover(i: number, on: boolean)
		local s = slots[i]
		if s == nil or s.Gradient == nil then return end
		if s.Tween then s.Tween:Cancel() end
		local tween = TweenService:Create(s.Proxy, HOVER_INFO, { Value = if on then 1 else 0 })
		s.Tween = tween
		tween:Play()
	end

	for i = 1, LoadoutConfig.MaxSlots do
		local s = slots[i]
		s.Proxy.Value = 0
		table.insert(s.Conns, s.Proxy.Changed:Connect(function(v: number)
			if s.Gradient then s.Gradient.Color = whitened(s.TierName, v) end
		end))
		local btn = s.Button :: GuiButton
		table.insert(s.Conns, btn.MouseEnter:Connect(function()
			s.Hovered = true
			hover(i, true)
			local entry = entries[i]
			if entry and LoadoutConfig.IsSlotUnlocked(i, playerLevel) then
				showPreview(btn, entry)
			end
		end))
		table.insert(s.Conns, btn.MouseLeave:Connect(function()
			s.Hovered = false
			hover(i, false)
			hidePreview(btn)
		end))
		-- Both events, debounced: `Activated` covers touch and gamepad, `MouseButton1Click` fires even
		-- on a button whose `Active` was left false somewhere upstream. The 0.05s gate is what stops a
		-- healthy button (which fires both) from starting placement twice.
		local lastFire = 0
		local function click()
			if os.clock() - lastFire < 0.05 then return end
			lastFire = os.clock()
			if not LoadoutConfig.IsSlotUnlocked(i, playerLevel) then return end
			if type(opts.OnActivated) == "function" then opts.OnActivated(i, entries[i]) end
		end
		table.insert(s.Conns, btn.Activated:Connect(click))
		table.insert(s.Conns, btn.MouseButton1Click:Connect(click))
	end

	local keyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local i = KEY_FOR_SLOT[input.KeyCode]
		if i and LoadoutConfig.IsSlotUnlocked(i, playerLevel) and type(opts.OnActivated) == "function" then
			opts.OnActivated(i, entries[i])
		end
	end)

	-- The one clock for every slot's stroke. A hovered slot is skipped for COLOUR only -- the hover
	-- tween owns `Color` while the mouse is on it -- but keeps spinning, so hovering does not freeze
	-- the card.
	local clock = 0
	local spinConn = RunService.RenderStepped:Connect(function(dt)
		clock += dt
		for i = 1, LoadoutConfig.MaxSlots do
			local s = slots[i]
			local gradient = s and s.Gradient
			if gradient then
				gradient.Rotation = (s.BaseRotation + clock * s.Spin) % 360
				if s.Multi then
					-- Bands travel along the stroke. Offset wraps at 1, so this loops seamlessly.
					gradient.Offset = Vector2.new((clock * s.Scroll) % 1, 0)
				elseif not s.Hovered then
					local lift = (math.sin(clock * s.Breathe * math.pi * 2 + s.Phase) * 0.5 + 0.5) * BREATHE_DEPTH
					gradient.Color = whitened(s.TierName, lift)
				end
			end
		end
	end)

	local handle = {}
	handle.container = container
	handle.version = 3
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
	function handle.previewInstance(): GuiObject?
		return preview
	end
	-- A Place's own state on top of the kit's: transparency 1 clears it. The Game uses this for
	-- "can't afford" and "at placement limit", which only exist mid-match.
	function handle.setOverlay(i: number, transparency: number, colour: Color3?)
		local s = slots[i]
		if s == nil or s.Overlay == nil or not s.Overlay:IsA("GuiObject") then return end
		s.Overlay.Visible = true
		s.Overlay.BackgroundTransparency = transparency
		if colour then s.Overlay.BackgroundColor3 = colour end
	end
	function handle.destroy()
		keyConn:Disconnect()
		spinConn:Disconnect()
		if preview then preview:Destroy(); preview = nil end
		for _, s in ipairs(slots) do
			for _, c in ipairs(s.Conns) do c:Disconnect() end
			if s.Tween then s.Tween:Cancel() end
			s.Proxy:Destroy()
		end
		table.clear(slots)
	end

	handle.setData({}, playerLevel)
	print(string.format("[UIKit.Hotbar] V3 attached: %d slot(s) painted from the authored design, %d palette sample(s) hidden.",
		LoadoutConfig.MaxSlots, math.max(0, #authored - LoadoutConfig.MaxSlots)))
	return handle
end

-- Attach the hotbar to a container Frame. Returns a handle.
function Hotbar.attach(container: GuiObject, opts: { [string]: any })
	assert(container, "UIKit.Hotbar.attach: container is nil")
	opts = opts or {}

	-- B77: the user's authored shape drives itself; everything else keeps the V2 kit-clone path.
	if container:FindFirstChild("HotbarSlot1") then
		return attachV3(container, opts)
	end
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

	-- ===== Hover preview (restored 2026-08-06) =====
	-- The Lobby hotbar used to pop a unit card on hover and the first version of this shared
	-- controller dropped it. It lives here now so BOTH Places get it from one place.
	local screen = container:FindFirstAncestorWhichIsA("ScreenGui")
	local previewTemplate = resolveFrom(PREVIEW_TEMPLATE_PATHS)
	local preview: GuiObject? = nil
	if previewTemplate and screen then
		preview = previewTemplate:Clone()
		;(preview :: GuiObject).Name = "HotbarHoverPreview"
		;(preview :: GuiObject).Visible = false
		;(preview :: GuiObject).ZIndex = 50
		;(preview :: GuiObject).Parent = screen
	end

	-- ===== WHY THE HIDE IS OWNED (B29) =====
	-- Roblox does NOT guarantee that MouseLeave(previous) fires before MouseEnter(next). Sweeping
	-- quickly across the row delivers them out of order often enough to see, and the old
	-- UNCONDITIONAL hide then blanked the preview the NEW slot had just shown -- so nothing was on
	-- screen while the mouse sat genuinely hovering a real slot. Reported by the user at B29:
	-- "it doesnt show even when mouse is still hovered on the card ... especially when moving fast
	-- in between slots and cards."
	-- A hide must therefore prove it still OWNS the preview. A stale leave is dropped; the current
	-- owner's own leave still hides normally, so the guard can never strand the preview visible.
	local previewOwner: GuiObject? = nil
	local staleHides = 0
	local function hidePreview(requester: GuiObject?)
		if requester ~= nil and previewOwner ~= nil and previewOwner ~= requester then
			staleHides += 1
			-- Evidence, not decoration: this line printing IS the race, caught in the act. THROTTLED
			-- because B29's first instrumented run logged ~70 suppressions in ONE play session --
			-- the race is not occasional, it is most of a fast sweep, and every one of those would
			-- previously have blanked the preview. Unthrottled it buries every other console line.
			if staleHides == 1 or staleHides % 50 == 0 then
				print(("[DIAG] hotbar hover: suppressed %d stale hide(s); latest from %s (owner %s)")
					:format(staleHides, requester.Name, (previewOwner :: GuiObject).Name))
			end
			return
		end
		previewOwner = nil
		if preview then preview.Visible = false end
	end

	-- Fill from whatever the Place's entry happens to carry: the Lobby passes a unitView
	-- (Name/Tier/Level/Grades), the Game passes a loadout row (TowerId/MetaLevel/Trait). Anything
	-- absent is simply skipped rather than printed as nil.
	local function showPreview(slotBtn: GuiObject, entry: any)
		if not (preview and entry) then return end
		-- Claim ownership BEFORE any work below, so a MouseLeave from the slot we just left is
		-- already recognisable as stale by the time it arrives.
		previewOwner = slotBtn
		local towerId = entry.TowerId
		local name = entry.Name or ItemCatalog.GetName(towerId)
		local tier = entry.Tier or ItemCatalog.GetTier(towerId)
		setText(preview, "UnitName", name)
		setText(preview, "TierName", tier)

		-- ===== THE LEVEL BAR (B27 fix) =====
		-- This looked for `UnitLevelBar`, WHICH HAS NEVER EXISTED ON THIS TEMPLATE. The Kit master
		-- shipped the bar as a node literally named `CanvasGroup`, so the lookup found nothing and
		-- the hotbar's hover preview has silently shown the authored placeholder level since the
		-- preview was restored at B6. Same class of dead branch as `IndexController`'s `CountLabel`.
		-- B27 renamed the master's node to `EXPLevelBar` in BOTH Places (the user's own name for it),
		-- and this now reads that. The old name is NOT kept as a fallback: nothing in either Place
		-- has ever had it, so a fallback would only preserve the illusion that it once worked.
		local level = entry.Level or entry.MetaLevel
		local bar = preview:FindFirstChild("EXPLevelBar", true)
		if bar and level then
			local l = bar:FindFirstChild("Text") or bar:FindFirstChildWhichIsA("TextLabel")
			if l and l:IsA("TextLabel") then l.Text = "LVL: " .. tostring(level) end
		end

		-- Grades only exist on the Lobby's unitView; the Game has none, so leave those rows alone
		-- rather than blanking a row the designer filled in.
		local grades = entry.Grades
		local bsf = preview:FindFirstChild("BaseStatsFrame", true)
		if grades and bsf then
			local function row(names: { string }, value: string)
				for _, n in ipairs(names) do
					local r = bsf:FindFirstChild(n)
					if r then
						local g = r:FindFirstChild("Grade")
						local target = (g and g:IsA("TextLabel")) and g or r:FindFirstChildWhichIsA("TextLabel")
						if target then target.Text = value end
						return
					end
				end
			end
			row({ "DMG", "Attack" }, grades.DMG or "-")
			row({ "RNG", "Element" }, grades.RNG or "-")
			row({ "SPA", "MaxPlacement" }, grades.SPA or "-")
		end

		-- Border matches the tier, like every other card in the kit.
		local st = preview:FindFirstChildWhichIsA("UIStroke")
		if st then
			local g = st:FindFirstChildOfClass("UIGradient")
			if not g then g = Instance.new("UIGradient"); g.Parent = st end
			g.Color = TierConfig.seamlessSequence(tier)
		end

		-- Sit ABOVE the hovered slot, clamped so it never runs off either edge.
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
		local pw = preview.AbsoluteSize.X > 0 and preview.AbsoluteSize.X or vp.X * 0.2
		local ph = preview.AbsoluteSize.Y > 0 and preview.AbsoluteSize.Y or vp.Y * 0.25
		local p, s = slotBtn.AbsolutePosition, slotBtn.AbsoluteSize
		local x = math.clamp(p.X + s.X / 2 - pw / 2, 8, math.max(8, vp.X - pw - 8))
		local y = math.max(8, p.Y - ph - 10)
		preview.AnchorPoint = Vector2.new(0, 0)
		preview.Position = UDim2.fromOffset(x, y)
		preview.Visible = true
	end

	for i = 1, LoadoutConfig.MaxSlots do
		local btn = template:Clone()
		btn.Name = "Slot" .. i
		btn.LayoutOrder = i
		btn.Visible = true
		btn:SetAttribute("SlotIndex", i)
		btn.Parent = container
		setText(btn, "SlotNumber", tostring(i))
		-- Fixed-size wrapper between the row's layout and the slot, so hovering slot 3 does not slide
		-- slots 4-6 sideways. `Button.attach` below finds/creates its UIScale on the slot itself,
		-- which now sits inside that wrapper.
		Motion.isolate(btn)
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
		-- ===== V2 KIT (B26): ONE PAINT SURFACE, NOT TWO. =====
		-- v1 painted a BORDER (`UIStrokeWithGradient`'s gradient) AND a BACKGROUND (`BG`'s own
		-- gradient) and the comment below used to warn at length about keeping them apart. **In V2
		-- neither instance exists** -- there is one gradient, on the slot's ROOT. User decision, B25:
		-- the tier border is dropped. That deletes the whole two-gradient hazard rather than
		-- re-creating it, so do NOT reintroduce a second surface.
		--
		-- DIRECT-CHILDREN-ONLY is still load-bearing: V2 nests UIGradients under `UnitLevel`,
		-- `PlacementPrice` and `TraitIcon`, and a recursive find would tint one of those instead.
		local rootGrad = btn:FindFirstChildOfClass("UIGradient")

		local towerId = entry and entry.TowerId or nil
		if vf then showModel(vf, opts.ModelSource, unlocked and towerId or nil) end

		-- Empty or locked: hide the per-unit details rather than showing stale ones.
		if trait and trait:IsA("GuiObject") then
			trait.Visible = (entry ~= nil) and unlocked and (entry.Trait ~= nil and entry.Trait ~= "None")
		end

		local showTier = (entry ~= nil) and unlocked
		local tierSeq = showTier
			and TierConfig.seamlessSequence(entry.Tier or ItemCatalog.GetTier(entry.TowerId))
			or nil

		-- THE slot colour. Empty/locked slots fall back to the neutral grey v1 used for its
		-- background, so an empty slot still reads as empty rather than inheriting a stale tier.
		if rootGrad then
			rootGrad.Color = tierSeq or ColorSequence.new(Color3.fromRGB(70, 66, 82))
		end

		-- HOVER STROKE TAKES THE TIER'S **BRIGHTEST** COLOUR (user rule, B27). Not `Colors[1]`, and
		-- never the derived dark secondary -- a stroke in the dark shade reads as a shadow instead of
		-- a highlight. `BrightestColor` ranks by relative luminance, so Mythic's slot outlines in its
		-- yellow rather than whichever rainbow entry sits first. An empty or locked slot keeps a
		-- neutral outline, for the same reason its gradient falls back to grey: no unit, no tier.
		local hoverStroke = btn:FindFirstChild("UIHoverStroke", true)
		if hoverStroke and hoverStroke:IsA("UIStroke") then
			if showTier then
				-- B27d: two-colour tiers outline in their brightest single colour; three-or-more
				-- colour tiers outline in ALL of them via a child UIGradient on the stroke.
				Motion.paintHoverStroke(hoverStroke, entry.Tier or ItemCatalog.GetTier(entry.TowerId))
			else
				-- Empty / locked: neutral outline, and any rainbow gradient left by a previous
				-- occupant of this slot must go with it, or the slot keeps outlining as Mythic.
				local stale = hoverStroke:FindFirstChildOfClass("UIGradient")
				if stale then stale:Destroy() end
				hoverStroke.Color = Color3.fromRGB(150, 150, 165)
			end
		end

		-- V2-only fields.
		-- `UnitLevel` renders ONLY when the entry actually carries a level. The Game and the Lobby
		-- build entries from different sources (validated LoadoutEntry vs `GetUnitViews`), so this
		-- reads whichever field is present and HIDES rather than printing a 0 for a unit whose level
		-- this Place does not know. A zero is a claim; a hidden label is not.
		local levelFrame = btn:FindFirstChild("UnitLevel", true)
		if levelFrame and levelFrame:IsA("GuiObject") then
			local lvl = entry and (entry.MetaLevel or entry.Level) or nil
			levelFrame.Visible = (lvl ~= nil) and unlocked
			-- SEARCH FROM THE SLOT ROOT, NOT FROM `levelFrame`. `setText` does
			-- `root:FindFirstChild(name, true)`, which walks DESCENDANTS ONLY and never matches `root`
			-- itself -- so `setText(levelFrame, levelFrame.Name, ...)` found nothing and silently left the
			-- template's authored placeholder ("LVL 100") on screen for every unit. Caught by the B26
			-- acceptance run, which printed "LVL 100" for an entry whose MetaLevel was 7.
			if lvl ~= nil then setText(btn, "UnitLevel", "LVL " .. tostring(lvl)) end
		end

		-- ===== PLACEMENT PRICE: REAL DATA SINCE B67, PAINTED BY THE KIT SINCE B68 =====
		-- Until B67 this was the template's AUTHORED PLACEHOLDER ("\u{20B1}67,000"), visible only because
		-- the user suspended hide-never-invent at B27c to judge the layout. The real source is
		-- `UnitStatsCatalog.Costs`: shared canon, hash-checked in BOTH Places, regenerated under the
		-- Game's load-bearing validator -- so the two Places show the same number by construction.
		-- B68 moved the lookup, the peso formatting and the hide rule into `UIKit.UnitCard` so the six
		-- Lobby card screens share them with this slot instead of each growing their own copy.
		-- Passing nil is how an EMPTY or LOCKED slot asks for nothing: no unit, no price, and never a 0
		-- (a zero would claim the tower is free).
		UnitCard.paintPrice(btn, (showTier and entry ~= nil) and entry.TowerId or nil)

		-- `Placed/MaxPlacement` is a MATCH-RUNTIME count (how many of this unit are on the board).
		-- The Game HAS that data (`PlacementCountsChanged`), the Lobby never will -- but nothing
		-- feeds it here yet, so it stays hidden in both rather than showing a fake "0/4".
		-- NOTE the "/" in the instance name: it needs FindFirstChild, never dot notation.
		local placed = btn:FindFirstChild("Placed/MaxPlacement", true)
		if placed and placed:IsA("GuiObject") then placed.Visible = false end
	end

	local function activate(i: number)
		if not LoadoutConfig.IsSlotUnlocked(i, playerLevel) then return end
		if type(opts.OnActivated) == "function" then
			opts.OnActivated(i, entries[i])
		end
	end

	for i = 1, LoadoutConfig.MaxSlots do
		slots[i].Handle.onActivated(function() activate(i) end)
		-- Preview only for a slot that actually holds a unit and is unlocked; hovering an empty
		-- or locked slot must not pop a card full of stale data.
		slots[i].Handle.onHover(function(on: boolean)
			local entry = entries[i]
			if on and entry and LoadoutConfig.IsSlotUnlocked(i, playerLevel) then
				showPreview(slots[i].Button, entry)
			else
				hidePreview(slots[i].Button)
			end
		end)
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
	function handle.previewInstance(): GuiObject?
		return preview
	end
	function handle.destroy()
		keyConn:Disconnect()
		if preview then preview:Destroy(); preview = nil end
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
