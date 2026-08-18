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

		-- ===== PLACEMENT PRICE: TEMPORARILY VISIBLE (B27c, user override) =====
		-- Placement cost lives in the GAME's tower configs, which the Lobby does not have, and this
		-- is a SHARED controller -- so there is still NO real data source and the label shows
		-- whatever the TEMPLATE AUTHORED. That is a design placeholder, **not a real cost**.
		-- The standing rule is hide-never-invent; the user explicitly suspended it to see the layout
		-- while testing. `Motion.SHOW_PLACEHOLDER_PRICES` is the single switch that puts every card
		-- in both Places back to honest. Only shown on a slot that actually HOLDS a unit -- a price
		-- floating on an empty slot would be noise on top of fiction.
		local price = btn:FindFirstChild("PlacementPrice", true)
		if price and price:IsA("GuiObject") then
			price.Visible = Motion.SHOW_PLACEHOLDER_PRICES and showTier or false
		end

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
