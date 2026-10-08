--!strict
-- B34/B36 BOOT MARKER (start). Paired with the `true` at the bottom -- see ScreenBootWatchdog.
script:SetAttribute("BootComplete", false)

-- SettingsUI.client.lua (SHARED CANON, LocalScript -- deploy path
-- StarterPlayer.StarterPlayerScripts.Client.UI.SettingsUI)
--
-- The settings screen, ONE builder for BOTH Places ("same structure, same gui" -- user, B35). It asks
-- SettingsConfig what is in scope for this Place and draws exactly that; a Place difference is a `Scope`
-- field in the config, never an `if` in this file.
--
-- B111 REBUILD (user refs): a "Settings" title banner, a Search box, the close X, a category sidebar with
-- icons, and the content as SECTIONS (one per category, icon + title + divider) holding a 2-column grid of
-- rows. Each row = Title + Desc + control: a check / X toggle, a slider with a typed value box, or an action
-- button with an icon. The GUI is AUTHORED (StarterGui.Settings, the same tree in both Places -- built by the
-- B111 authoring script); this only clones templates:
--   Panel{ TitleBanner, Search.Input, CloseButton, CategoryPanel, Content }, Dim, CategoryButtonTemplate,
--   SectionTemplate{ Header{Icon, Label}, Grid }, ToggleRowTemplate{ Title, Desc, Toggle{Check, Cross} },
--   SliderRowTemplate{ Title, Desc, ValueBox, Track{Fill, Handle} }, ActionRowTemplate{ Title, Desc, Button{Icon} },
--   optional OpenButton (the Game's floating gear).
-- Motion: open pop, staggered row fade-in, toggle bump, handle glide; UIGradients named "Shimmer" loop
-- (UIKit.Motion). Only the X (or gamepad B) closes -- the dim never does (user rule).
-- Side effects of two settings live here so they work identically in both Places:
--   ScreenShake -> Player attribute "ReducedMotion" (read by the Game's HudFX and anything else that shakes).
--   UIScale     -> an `AD_UIScale` UIScale (B112, see "UI SCALE" below).
-- B112: Type "key" rows clone the optional KeybindRowTemplate{ Title, Desc, KeyButton{Label}, Clear }
-- (tools/build_keybind_row.luau); click the key, press a key; X unbinds. Logic lives in Settings.Keybinds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)
local Keybinds = require(script.Parent.Parent.Settings:WaitForChild("Keybinds")) -- B112 (also registers ResetKeybinds)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== B65: RESERVE THE HUD SETTINGS BUTTON NOW, AND RE-BIND IT TO EVERY HUD =====
-- Bound before any yield (LocalScript order is not deterministic and a click on an unwired button is
-- dropped), and re-bound on every HUD respawn. A Place whose HUD has no SettingsButton stays silent.
local requestOpen: (() -> ())? = nil
local pendingOpen = false
local function wireHudSettingsButton(hud: Instance)
	local right = hud:FindFirstChild("Right")
	local upper = right and right:FindFirstChild("UpperRight")
	local btn = upper and upper:FindFirstChild("SettingsButton")
	if btn and btn:IsA("GuiButton") then
		(btn :: GuiButton).MouseButton1Click:Connect(function()
			if requestOpen then
				requestOpen()
			else
				pendingOpen = true
			end
		end)
		print("[SettingsUI] HUD SettingsButton wired.")
	end
end
task.spawn(function()
	local hud = playerGui:FindFirstChild("HUD") or playerGui:WaitForChild("HUD", 10)
	if hud then
		wireHudSettingsButton(hud)
	end
end)
playerGui.ChildAdded:Connect(function(child: Instance)
	if child.Name == "HUD" and child:IsA("ScreenGui") then
		wireHudSettingsButton(child)
	end
end)

-- ScreenShake -> ReducedMotion, applied at boot and on every change (both Places).
local function applySideEffects(settings: any)
	player:SetAttribute("ReducedMotion", settings.ScreenShake == false)
end
ClientSettings.Changed:Connect(applySideEffects)
applySideEffects(ClientSettings.GetAll())

-- ===== UI SCALE (B112) =====
-- A UIScale parented to a ScreenGui does NOTHING (measured live, B112), so the scale goes on each TOP-LEVEL
-- panel as a UIScale named `AD_UIScale`. Skipped, on purpose:
--   * a panel that already has its OWN UIScale -- those are open/close pop animations (HudFX, Quests,
--     Achievements...), and a second UIScale on one object is not allowed (one per object);
--   * CONTAINERS -- anything spanning a whole screen axis. An invisible holder (menu roots, the HUD's
--     full-height Left / Right columns, full-width Top / Bottom strips) has its CHILDREN scaled instead (up
--     to 2 levels down); a VISIBLE full-axis panel (Unit Manager) keeps its authored size -- both because a
--     full-height column grown by 120% runs off the screen;
--   * templates (`*Template`) and retired (`*_Retired*`) objects.
-- A UIScale grows a frame AWAY from its AnchorPoint, so a top-left-anchored button on the right edge would
-- grow off-screen. Before its FIRST scale each object is re-anchored to the side of its parent it sits on
-- (thirds: left/centre/right, top/middle/bottom) with its Position compensated, so at 100% nothing moves
-- and when scaled it grows INWARD. Done once (attribute AD_Anchored). A script that later tweens such an
-- object's Position must read its AnchorPoint, not assume the authored one.
--   * the screens in UISCALE_SKIP: Settings itself (so a bad scale can always be undone), admin/dev tools.
-- At 100% nothing is created at all. A UIScale is a size modifier on an authored panel, not generated UI.
-- B127: panels tagged `AD_ScaleGroup` scale TOGETHER as one block (see SCALE GROUPS below). A panel's
-- `AD_ScaleMax` attribute caps ITS scale (e.g. 1 = a popup that keeps its designed size on phones, where
-- there is no room for it to grow).
-- B127 (user: "fix all ui to look good in all devices"): the EFFECTIVE scale = the UI Scale setting x a
-- DEVICE factor. Small screens (the viewport's short side under DEVICE_REF px -- phones) get up to
-- DEVICE_MAX more, because the HUD is authored at 1080p and its text drops to 3-8 px tall on a 375 px
-- phone. Tablets / PCs: factor 1, nothing changes. Recomputed when the viewport resizes (rotation, window).
-- A panel with its OWN UIScale (an open/close pop animation) cannot take a second one, so it is scaled by
-- SIZE instead: its authored Size is kept in the `AD_BaseSize` attribute and Size = base x scale (after the
-- same anchorInward). Pop animations only touch their UIScale, so nothing fights; a script that resizes the
-- panel itself (a fitPanel) is adopted as the new base. UIScales named `Responsive` are a screen's OWN
-- device scaling (DailyRewards, TraitReroll) -- left alone.
-- B131 (user: "some ui are zoomed ... use all scale ... so ui will look same on all device"): the phone boost
-- is OFF (DEVICE_MAX = 1). The authored UI is now SCALE (tools/ui_to_scale.luau), so it already keeps its
-- proportions on every screen; boosting it on phones is what made it look zoomed.
local DEVICE_REF, DEVICE_MAX = 560, 1
local function deviceFactor(): number
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local short = math.min(v.X, v.Y)
	if short <= 1 or short >= DEVICE_REF then return 1 end
	return math.clamp(DEVICE_REF / short, 1, DEVICE_MAX)
end
local UISCALE_SKIP = { Settings = true, Freecam = true, AdminPanel = true, AdminBroadcastGUI = true, ScreenFXLayer = true }
local uiScaleValue = 1
local watchedParents: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function isContainer(o: GuiObject): boolean
	return o.Size.X.Scale >= 0.95 or o.Size.Y.Scale >= 0.95
end
-- an invisible layout holder (no fill, no image): safe to look inside. A VISIBLE full-axis panel (Unit
-- Manager, Stage Info) is left at its authored size -- scaling its rows one by one spills them out of it.
local function isHolder(o: GuiObject): boolean
	if o.BackgroundTransparency < 0.99 then return false end
	if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "" and (o :: any).ImageTransparency < 0.99 then
		return false
	end
	return true
end
local function anchorInward(o: GuiObject)
	if o:GetAttribute("AD_Anchored") or o.AutomaticSize ~= Enum.AutomaticSize.None then return end
	local p = o.Parent :: any
	if p == nil or (not p:IsA("GuiBase2d")) or p:FindFirstChildWhichIsA("UIGridStyleLayout") then return end
	local ps, pp = p.AbsoluteSize, p.AbsolutePosition
	if ps.X < 1 or ps.Y < 1 or o.AbsoluteSize.X < 1 then return end -- not laid out (disabled screen): try next time
	o:SetAttribute("AD_Anchored", true)
	local c = o.AbsolutePosition + o.AbsoluteSize / 2
	local rx, ry = (c.X - pp.X) / ps.X, (c.Y - pp.Y) / ps.Y
	local ax = if rx < 0.34 then 0 elseif rx > 0.66 then 1 else 0.5
	local ay = if ry < 0.34 then 0 elseif ry > 0.66 then 1 else 0.5
	local dx, dy = ax - o.AnchorPoint.X, ay - o.AnchorPoint.Y
	if dx == 0 and dy == 0 then return end
	-- compensate in the Size's own units; with a size/aspect constraint the real size differs, so use pixels
	local constrained = o:FindFirstChildWhichIsA("UIAspectRatioConstraint") or o:FindFirstChildWhichIsA("UISizeConstraint")
	if constrained then
		o.Position += UDim2.fromOffset(o.AbsoluteSize.X * dx, o.AbsoluteSize.Y * dy)
	else
		o.Position += UDim2.new(o.Size.X.Scale * dx, o.Size.X.Offset * dx, o.Size.Y.Scale * dy, o.Size.Y.Offset * dy)
	end
	o.AnchorPoint = Vector2.new(ax, ay)
end
local scaleNode: (Instance, number) -> ()
-- B127: a panel on a screen that has never been shown (Enabled = false at boot) has no layout yet, so it
-- cannot be re-anchored; scale it the moment it is first laid out instead of growing it from the wrong side.
local waitingLayout: { [GuiObject]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local function whenLaidOut(o: GuiObject, fn: () -> ())
	if waitingLayout[o] then return end
	waitingLayout[o] = true
	local conn: RBXScriptConnection? = nil
	conn = o:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if o.AbsoluteSize.X >= 1 and conn then
			conn:Disconnect()
			waitingLayout[o] = nil
			fn()
		end
	end)
end
-- B127: Size-based scale for panels that own an animated UIScale (see the header).
local sizeExpected: { [GuiObject]: UDim2 } = setmetatable({}, { __mode = "k" }) :: any
-- B127: FIT. A scaled panel never outgrows the screen: the big menus are authored at 1080p and already
-- fill a phone (some even overflow it at 100%), so the device boost would push them off the edges. Given
-- the panel's UNSCALED pixel size, its factor is capped -- below 1 when needed -- so it fits the screen
-- with a margin, and on an IgnoreGuiInset screen clears the Roblox top bar above AND below (centred).
local FIT_MARGIN = 0.96
local function fitCap(o: Instance, basePx: Vector2): number
	local sg = o:FindFirstAncestorOfClass("ScreenGui")
	if sg == nil or basePx.X < 1 or basePx.Y < 1 then return math.huge end
	local avail = sg.AbsoluteSize
	local h = avail.Y
	if sg.IgnoreGuiInset then
		h = math.max(h - 2 * (game:GetService("GuiService"):GetGuiInset()).Y, avail.Y * 0.6)
	end
	return math.min(avail.X * FIT_MARGIN / basePx.X, h * FIT_MARGIN / basePx.Y)
end
local function scaleFor(o: Instance, basePx: Vector2?): number
	local cap = tonumber(o:GetAttribute("AD_ScaleMax"))
	local k = if cap then math.min(uiScaleValue, math.max(cap, 1)) else uiScaleValue
	if basePx then
		k = math.min(k, fitCap(o, basePx))
	end
	return math.floor(k * 100 + 0.5) / 100
end
local function applySize(o: GuiObject)
	local base = o:GetAttribute("AD_BaseSize")
	if typeof(base) ~= "UDim2" then return end
	local ps = (o.Parent :: any).AbsoluteSize :: Vector2
	local k = scaleFor(o, Vector2.new(base.X.Scale * ps.X + base.X.Offset, base.Y.Scale * ps.Y + base.Y.Offset))
	local want = UDim2.new(base.X.Scale * k, base.X.Offset * k, base.Y.Scale * k, base.Y.Offset * k)
	sizeExpected[o] = want
	o.Size = want
end
local function scaleBySize(o: GuiObject)
	if typeof(o:GetAttribute("AD_BaseSize")) ~= "UDim2" then
		if uiScaleValue == 1 then return end
		anchorInward(o)
		if not o:GetAttribute("AD_Anchored") then
			whenLaidOut(o, function() scaleBySize(o) end)
			return
		end
		o:SetAttribute("AD_BaseSize", o.Size)
		o:GetPropertyChangedSignal("Size"):Connect(function()
			local exp = sizeExpected[o]
			if exp and o.Size == exp then return end
			-- somebody else sized it (a layout script): that is the new authored base
			o:SetAttribute("AD_BaseSize", o.Size)
			applySize(o)
		end)
	end
	applySize(o)
end
-- ===== SCALE GROUPS (B127) =====
-- Panels sharing an `AD_ScaleGroup` attribute (across screens, e.g. "HUD.Bottom" = hotbar + XP bar + cash)
-- scale as ONE rigid block about the group's own anchor corner (thirds of the group's box, like
-- anchorInward): every member's centre moves away from that pivot by the same factor as its size, so the
-- GAPS grow with them and members can never collide (one-by-one scaling overlapped the HUD on phones).
-- Each member's authored AnchorPoint / Position (+ Size for an animated panel) are kept as attributes and
-- restored before every pass, so a viewport change re-lays it from the authored design. At scale 1 the
-- members are simply put back. A member may set `AD_GroupPivot` (a UDim2 in SCREEN space) to choose the
-- pivot instead -- the HUD's bottom row pivots on the hotbar's bottom edge so it stays above the hotbar.
-- Members on IgnoreGuiInset = false screens are measured in the same (whole-screen) space as the rest.
local function groupMembers(name: string): { GuiObject }
	local list = {}
	for _, d in ipairs(playerGui:GetDescendants()) do
		if d:IsA("GuiObject") and d:GetAttribute("AD_ScaleGroup") == name then
			table.insert(list, d :: GuiObject)
		end
	end
	return list
end
local groupBusy: { [string]: boolean } = {}
local function scaleGroup(name: string)
	if groupBusy[name] then return end
	groupBusy[name] = true
	local members = groupMembers(name)
	-- 1) authored state
	for _, m in ipairs(members) do
		if typeof(m:GetAttribute("AD_GBasePos")) ~= "UDim2" then
			m:SetAttribute("AD_GBasePos", m.Position)
			m:SetAttribute("AD_GBaseAnchor", m.AnchorPoint)
		end
		m.Position = m:GetAttribute("AD_GBasePos")
		m.AnchorPoint = m:GetAttribute("AD_GBaseAnchor")
		local base = m:GetAttribute("AD_BaseSize")
		if typeof(base) == "UDim2" then
			sizeExpected[m] = base
			m.Size = base
		end
		local u = m:FindFirstChild("AD_UIScale")
		if u and u:IsA("UIScale") then u.Scale = 1 end
	end
	-- 2) measure the authored layout (a member on a never-shown screen re-runs the group once it lays out)
	local k = uiScaleValue
	local boxes: { { m: GuiObject, c: Vector2 } } = {}
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	local screen: Vector2? = nil
	local GuiService = game:GetService("GuiService")
	local topInset = (GuiService:GetGuiInset())
	local function shift(o: Instance): Vector2
		local sg = o:FindFirstAncestorOfClass("ScreenGui")
		return if sg and not sg.IgnoreGuiInset then topInset else Vector2.zero
	end
	local pivotOverride: UDim2? = nil
	for _, m in ipairs(members) do
		local pv = m:GetAttribute("AD_GroupPivot")
		if typeof(pv) == "UDim2" then pivotOverride = pv end
		local p, sz = m.AbsolutePosition + shift(m), m.AbsoluteSize
		if sz.X < 1 then
			if k ~= 1 then whenLaidOut(m, function() scaleGroup(name) end) end
		else
			table.insert(boxes, { m = m, c = p + sz / 2 })
			x0, y0 = math.min(x0, p.X), math.min(y0, p.Y)
			x1, y1 = math.max(x1, p.X + sz.X), math.max(y1, p.Y + sz.Y)
			local sg = m:FindFirstAncestorOfClass("ScreenGui")
			screen = screen or (sg and (sg.AbsoluteSize + (if sg.IgnoreGuiInset then Vector2.zero else topInset)))
		end
	end
	if k == 1 or #boxes == 0 or screen == nil then
		groupBusy[name] = nil
		return
	end
	-- 3) pivot = the group box's corner / edge / centre by thirds of the screen
	local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
	local fx = if cx / screen.X < 0.34 then 0 elseif cx / screen.X > 0.66 then 1 else 0.5
	local fy = if cy / screen.Y < 0.34 then 0 elseif cy / screen.Y > 0.66 then 1 else 0.5
	local pivot = Vector2.new(x0 + (x1 - x0) * fx, y0 + (y1 - y0) * fy)
	if pivotOverride then
		pivot = Vector2.new(screen.X * pivotOverride.X.Scale + pivotOverride.X.Offset, screen.Y * pivotOverride.Y.Scale + pivotOverride.Y.Offset)
	end
	-- 4) place + size every member
	for _, b in ipairs(boxes) do
		local m = b.m
		local nc = pivot + (b.c - pivot) * k
		local par = m.Parent :: any
		local pp, ps = par.AbsolutePosition + shift(m), par.AbsoluteSize
		m.AnchorPoint = Vector2.new(0.5, 0.5)
		m.Position = UDim2.fromScale((nc.X - pp.X) / math.max(ps.X, 1), (nc.Y - pp.Y) / math.max(ps.Y, 1))
		local anim = m:FindFirstChildOfClass("UIScale")
		if anim and anim.Name ~= "AD_UIScale" then
			if anim.Name ~= "Responsive" then
				if typeof(m:GetAttribute("AD_BaseSize")) ~= "UDim2" then
					m:SetAttribute("AD_BaseSize", m.Size)
					m:GetPropertyChangedSignal("Size"):Connect(function()
						local exp = sizeExpected[m]
						if exp and m.Size == exp then return end
						m:SetAttribute("AD_BaseSize", m.Size)
						applySize(m)
					end)
				end
				applySize(m)
			end
		else
			local u = m:FindFirstChild("AD_UIScale") :: UIScale?
			if u == nil then
				u = Instance.new("UIScale")
				;(u :: UIScale).Name = "AD_UIScale"
				;(u :: UIScale).Parent = m
			end
			(u :: UIScale).Scale = scaleFor(m)
		end
	end
	groupBusy[name] = nil
end
local function watchChildren(parent: Instance, depth: number)
	if watchedParents[parent] then return end
	watchedParents[parent] = true
	parent.ChildAdded:Connect(function(child)
		task.defer(scaleNode, child, depth)
	end)
end
function scaleNode(o: Instance, depth: number)
	if not o:IsA("GuiObject") or o.Parent == nil or o.Name:find("Template$") or o.Name:find("_Retired") then return end
	local group = o:GetAttribute("AD_ScaleGroup")
	if type(group) == "string" and group ~= "" then
		scaleGroup(group) -- B127: scaled with its group, see SCALE GROUPS
		return
	end
	if scaleFor(o) == 1 and o:FindFirstChild("AD_UIScale") == nil and typeof(o:GetAttribute("AD_BaseSize")) ~= "UDim2" then
		return -- capped at 1 (AD_ScaleMax) and never scaled: nothing to do
	end
	local own = o:FindFirstChild("AD_UIScale")
	if own == nil then
		local anim = o:FindFirstChildOfClass("UIScale")
		if anim then
			if anim.Name ~= "Responsive" then
				scaleBySize(o :: GuiObject) -- B127: an animated panel, see the header
			end
			return
		end
		-- a LAYOUT ITEM (its parent has a UIListLayout / UIGridLayout) is always scaled as one unit, whatever
		-- its size -- the HUD's button column items are {1,0},{1,0} cells
		local inLayout = o.Parent ~= nil and (o.Parent :: Instance):FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
		if not inLayout and isContainer(o :: GuiObject) then
			if depth < 3 and isHolder(o :: GuiObject) then
				watchChildren(o, depth + 1)
				for _, c in ipairs(o:GetChildren()) do scaleNode(c, depth + 1) end
			end
			return
		end
		if uiScaleValue == 1 then return end
		anchorInward(o :: GuiObject)
		if not o:GetAttribute("AD_Anchored") and o.AutomaticSize == Enum.AutomaticSize.None then
			-- B127: not laid out yet (hidden screen) -- re-anchor + scale once it is, not from the wrong side
			whenLaidOut(o :: GuiObject, function() scaleNode(o, depth) end)
			return
		end
		own = Instance.new("UIScale")
		own.Name = "AD_UIScale"
		own.Parent = o
	end
	-- unscaled pixel size = what it shows now / the scale it has now (1 when just created)
	local cur = (own :: UIScale).Scale
	local g = o :: GuiObject
	-- (a panel on a hidden screen measures 0: reuse its last measure)
	local basePx: Vector2? = nil
	if cur > 0.01 and g.AbsoluteSize.X >= 1 then
		basePx = g.AbsoluteSize / cur
		o:SetAttribute("AD_BasePx", basePx)
	else
		local last = o:GetAttribute("AD_BasePx")
		basePx = if typeof(last) == "Vector2" then last else nil
	end
	(own :: UIScale).Scale = scaleFor(o, basePx)
end
local function scaleGui(g: Instance)
	if not g:IsA("ScreenGui") or UISCALE_SKIP[g.Name] or g.Name:find("_Retired") then return end
	watchChildren(g, 1)
	for _, c in ipairs(g:GetChildren()) do scaleNode(c, 1) end
end
local function applyUIScale(settings: any)
	local v = (tonumber(settings.UIScale) or 1) * deviceFactor()
	v = math.floor(v * 100 + 0.5) / 100
	if v == uiScaleValue then return end
	uiScaleValue = v
	for _, g in ipairs(playerGui:GetChildren()) do scaleGui(g) end
end
playerGui.ChildAdded:Connect(function(g) task.defer(scaleGui, g) end)
ClientSettings.Changed:Connect(applyUIScale)
uiScaleValue = 0 -- force the first pass to walk (and wire) every screen
applyUIScale(ClientSettings.GetAll())
-- B127: the device factor follows the viewport (phone rotation, window resize, camera swap).
do
	local function watchCam()
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applyUIScale(ClientSettings.GetAll())
			end)
		end
	end
	watchCam()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCam)
end

-- B131: authored text is TextScaled with a UITextSizeConstraint `AD_TextCap` whose cap is its 1080p size
-- (attribute AD_BaseTextSize, written by tools/ui_to_scale.luau). On a screen TALLER than 1080 the cap grows
-- with the screen, so text keeps its proportion there too instead of stopping at the 1080p size. (Smaller
-- screens need nothing: the text box itself shrinks.)
do
	local function capK(): number
		local cam = workspace.CurrentCamera
		local v = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
		return math.max(1, v.Y / 1080)
	end
	local function paintCap(c: Instance)
		if c:IsA("UITextSizeConstraint") and c.Name == "AD_TextCap" then
			local base = tonumber(c:GetAttribute("AD_BaseTextSize"))
			if base then
				c.MaxTextSize = math.clamp(math.floor(base * capK() + 0.5), 1, 100)
			end
		end
	end
	local function paintAll()
		for _, d in ipairs(playerGui:GetDescendants()) do paintCap(d) end
	end
	playerGui.DescendantAdded:Connect(paintCap)
	local function watch()
		local cam = workspace.CurrentCamera
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(paintAll) end
	end
	watch()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watch)
	task.defer(paintAll)
end

local gui = playerGui:FindFirstChild("Settings") or playerGui:WaitForChild("Settings", 10)
if gui == nil then
	warn("[SettingsUI] StarterGui.Settings is not in this Place yet -- the settings panel is unavailable here.")
	script:SetAttribute("BootComplete", true)
	return
end

local function need(parent: Instance?, name: string): any
	if parent == nil then return nil end
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 5)
end

local panel = need(gui, "Panel")
local dim = need(gui, "Dim")
local catTemplate = need(gui, "CategoryButtonTemplate")
local sectionTemplate = need(gui, "SectionTemplate")
local toggleTemplate = need(gui, "ToggleRowTemplate")
local sliderTemplate = need(gui, "SliderRowTemplate")
local actionTemplate = need(gui, "ActionRowTemplate")
local keybindTemplate = gui:FindFirstChild("KeybindRowTemplate") or gui:WaitForChild("KeybindRowTemplate", 3) -- B112, optional
if keybindTemplate == nil then
	warn("[SettingsUI] Settings.KeybindRowTemplate missing -- keybind rows hidden (run tools/build_keybind_row.luau).")
end
local closeBtn = need(panel, "CloseButton")
local catPanel = need(panel, "CategoryPanel")
local content = need(panel, "Content")
local searchFrame = need(panel, "Search")
local searchBox = searchFrame and need(searchFrame, "Input")
local openBtn = gui:FindFirstChild("OpenButton")

if not (panel and dim and catTemplate and sectionTemplate and toggleTemplate and sliderTemplate and actionTemplate
	and closeBtn and catPanel and content and searchBox) then
	warn("[SettingsUI] StarterGui.Settings is missing B111 parts (Panel/Search/Content/CategoryPanel/templates) -- panel disabled.")
	script:SetAttribute("BootComplete", true)
	return
end
for _, t in ipairs({ catTemplate, sectionTemplate, toggleTemplate, sliderTemplate, actionTemplate }) do
	t.Visible = false
end
if keybindTemplate then keybindTemplate.Visible = false end

local okI, IconCatalog = pcall(function() return require(ReplicatedStorage.Shared.IconCatalog) end)
local function icon(key: string?): string
	if not okI or type(IconCatalog) ~= "table" or not key then return "" end
	local ok, r = pcall(IconCatalog.get, key)
	return if ok and type(r) == "string" then r else ""
end
local okM, Motion = pcall(function() return require(ReplicatedStorage.Shared.UIKit.Motion) end)

local C = Color3.fromRGB
local ON_BG, OFF_BG = C(80, 200, 70), C(205, 45, 55)
local CAT_ON, CAT_OFF = C(255, 190, 60), C(52, 40, 74)
local ACTION_BG, DISABLED_BG = C(120, 80, 220), C(70, 66, 82)
local place = SettingsConfig.Place()

local function tween(o: Instance, t: number, props: any, style: Enum.EasingStyle?)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function scaleOf(o: Instance): UIScale
	local s = o:FindFirstChildOfClass("UIScale")
	if not s then
		s = Instance.new("UIScale")
		s.Parent = o
	end
	return s :: UIScale
end
local function bump(o: Instance)
	local s = scaleOf(o)
	s.Scale = 0.86
	tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- ===== rows =====
type Row = { row: GuiObject, category: string, text: string }
local rows: { Row } = {}
local refreshers: { [string]: (any) -> () } = {}
local actionPainters: { () -> () } = {}
local sections: { [string]: any } = {}

local function setText(row: any, field: any)
	row.Title.Text = field.Label
	row.Desc.Text = field.Desc or ""
end

local function buildToggle(field: any, parent: Instance, order: number)
	local row = toggleTemplate:Clone()
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	setText(row, field)
	local btn = row.Toggle
	row.Parent = parent
	local last: boolean? = nil
	refreshers[field.Key] = function(value)
		local on = value == true
		btn.BackgroundColor3 = if on then ON_BG else OFF_BG
		btn.Check.Visible = on
		btn.Cross.Visible = not on
		if last ~= nil and last ~= on then bump(btn) end
		last = on
	end
	btn.Activated:Connect(function()
		ClientSettings.Set(field.Key, not (ClientSettings.Get(field.Key) == true))
	end)
	return row
end

local function buildSlider(field: any, parent: Instance, order: number)
	local row = sliderTemplate:Clone()
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	setText(row, field)
	row.Parent = parent
	local track, box = row.Track, row.ValueBox
	local fill, handle = track.Fill, track.Handle
	local minV, maxV = field.Min or 0, field.Max or 1
	refreshers[field.Key] = function(value)
		local ratio = math.clamp(((value or 0) - minV) / math.max(maxV - minV, 1e-6), 0, 1)
		tween(fill, 0.12, { Size = UDim2.fromScale(ratio, 1) })
		tween(handle, 0.12, { Position = UDim2.fromScale(ratio, 0.5) })
		if not box:IsFocused() then
			-- B112: Display "Percent" shows the VALUE as a percent (UI Scale 75..125), else the 0..100 ratio
			box.Text = if field.Display == "Percent" then tostring(math.floor((value or 0) * 100 + 0.5)) else tostring(math.floor(ratio * 100 + 0.5))
		end
	end
	local dragging = false
	-- B112: a `Step` field snaps the value (UI Scale moves in 5% steps) and is the gamepad step
	local function snap(v: number): number
		if field.Step then
			v = minV + math.floor((v - minV) / field.Step + 0.5) * field.Step
		end
		return math.clamp(v, minV, maxV)
	end
	local function applyFromX(x: number)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = snap(minV + ratio * (maxV - minV))
		if field.Step and math.abs(v - (tonumber(ClientSettings.Get(field.Key)) or v)) < 1e-6 then return end
		ClientSettings.Set(field.Key, v)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			applyFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement
			and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			dragging = false -- B112: the release was missed (e.g. it landed outside the window); never drag unheld
			return
		end
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	-- gamepad / keyboard: the track is selectable; left/right step 5%
	track.SelectionGained:Connect(function() handle.BackgroundColor3 = CAT_ON end)
	track.SelectionLost:Connect(function() handle.BackgroundColor3 = C(240, 236, 250) end)
	UserInputService.InputBegan:Connect(function(input)
		if GuiService.SelectedObject ~= track then return end
		local step = if input.KeyCode == Enum.KeyCode.DPadRight or input.KeyCode == Enum.KeyCode.Right then 0.05
			elseif input.KeyCode == Enum.KeyCode.DPadLeft or input.KeyCode == Enum.KeyCode.Left then -0.05 else 0
		if step ~= 0 then
			local cur = tonumber(ClientSettings.Get(field.Key)) or minV
			local delta = if field.Step then math.sign(step) * field.Step else step * (maxV - minV)
			ClientSettings.Set(field.Key, snap(cur + delta))
		end
	end)
	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			if field.Display == "Percent" then
				ClientSettings.Set(field.Key, snap(n / 100))
			else
				ClientSettings.Set(field.Key, minV + math.clamp(n / 100, 0, 1) * (maxV - minV))
			end
		end
		refreshers[field.Key](ClientSettings.Get(field.Key))
	end)
	return row
end

-- An ACTION fires and persists nothing. WHAT it does is registered per Place (ClientSettings.RegisterAction);
-- with no handler the button is drawn disabled, because a button that silently does nothing is worse.
local function buildAction(field: any, parent: Instance, order: number)
	local row = actionTemplate:Clone()
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	setText(row, field)
	row.Parent = parent
	local btn = row.Button
	btn.Icon.Image = icon(field.Icon)
	local function paint()
		local wired = ClientSettings.HasAction(field.Key)
		btn.BackgroundColor3 = if wired then ACTION_BG else DISABLED_BG
		btn.Active = wired
		btn.Icon.ImageTransparency = if wired then 0 else 0.6
	end
	paint()
	table.insert(actionPainters, paint)
	btn.Activated:Connect(function()
		bump(btn)
		ClientSettings.RunAction(field.Key)
	end)
	return row
end

-- ===== KEY rows (B112) =====
-- Click the key button (or gamepad A on it) -> it reads "Press a key" and the NEXT keyboard key is bound
-- (Keybinds.Set clears a clashing action of the same Group and the row says which). Backspace or a second
-- click cancels; a reserved key (Escape, Slash, Tab, Enter, F9-F12) is refused. X unbinds.
local KEY_BG, KEY_WAIT, KEY_NONE = C(52, 40, 74), C(255, 190, 60), C(30, 24, 42)
local capturingRow: any = nil
local function stopCapture()
	capturingRow = nil
	task.delay(0.15, function()
		if capturingRow == nil then Keybinds.Capturing = false end
	end)
end
local function buildKey(field: any, parent: Instance, order: number)
	local row = keybindTemplate:Clone()
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	setText(row, field)
	row.Parent = parent
	local keyBtn, clear = row.KeyButton, row.Clear
	local label = keyBtn.Label
	local action = string.sub(field.Key, 5) -- "Key_Dash" -> "Dash"
	local note: string? = nil
	local function paint()
		if capturingRow == row then
			label.Text = "Press a key"
			keyBtn.BackgroundColor3 = KEY_WAIT
			return
		end
		local name = ClientSettings.Get(field.Key)
		label.Text = if note then note elseif name == "" or name == nil then "None" else Keybinds.Label(name)
		keyBtn.BackgroundColor3 = if name == "" or name == nil then KEY_NONE else KEY_BG
		clear.Visible = name ~= "" and name ~= nil
	end
	refreshers[field.Key] = function() paint() end
	paint()
	keyBtn.Activated:Connect(function()
		bump(keyBtn)
		if capturingRow == row then
			stopCapture()
		else
			local prev = capturingRow
			capturingRow = row
			Keybinds.Capturing = true
			if prev and prev.Parent and refreshers[prev.Name] then refreshers[prev.Name]() end
		end
		paint()
	end)
	UserInputService.InputBegan:Connect(function(input)
		if capturingRow ~= row or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		local name = input.KeyCode.Name
		if name == "Backspace" then
			stopCapture()
			paint()
			return
		end
		if not SettingsConfig.IsBindableKey(name) then
			note = "Can't use " .. Keybinds.Label(name)
		else
			local took = Keybinds.Set(action, name)
			note = if took then "Taken from " .. took else nil
		end
		stopCapture()
		paint()
		if note then
			task.delay(1.6, function()
				note = nil
				paint()
			end)
		end
	end)
	clear.Activated:Connect(function()
		bump(clear)
		if capturingRow == row then stopCapture() end
		Keybinds.Set(action, "")
		paint()
	end)
	return row
end

-- one section per category that has rows here, in config order
local categories = SettingsConfig.CategoriesFor(place)
local built = 0
local order = 0
for _, category in ipairs(categories) do
	if category ~= "All" then
		order += 1
		local sec = sectionTemplate:Clone()
		sec.Name = "Section_" .. category
		sec.LayoutOrder = order
		sec.Visible = true
		sec.Header.Label.Text = category
		sec.Header.Icon.Image = icon(SettingsConfig.CategoryIcons and SettingsConfig.CategoryIcons[category])
		sec.Parent = content
		sections[category] = sec
		for i, field in ipairs(SettingsConfig.EntriesFor(category, place)) do
			local row
			if SettingsConfig.KindOf(field) == "Action" then
				row = buildAction(field, sec.Grid, i)
			elseif field.Type == "key" then
				if keybindTemplate == nil then continue end
				row = buildKey(field, sec.Grid, i)
			elseif field.Type == "number" then
				row = buildSlider(field, sec.Grid, i)
			else
				row = buildToggle(field, sec.Grid, i)
			end
			table.insert(rows, { row = row, category = category, text = string.lower(field.Label .. " " .. (field.Desc or "")) })
			built += 1
		end
	end
end

-- grid cells in PIXELS from the real width (scale cells inside auto-sized frames collapse); 2 columns,
-- 1 on a narrow screen
local function sizeGrids()
	local w = content.AbsoluteSize.X - 18
	if w <= 0 then return end
	local cols = if w < 520 then 1 else 2
	local cw = math.floor((w - (cols - 1) * 8) / cols)
	for _, sec in pairs(sections) do
		local g = sec.Grid:FindFirstChildOfClass("UIGridLayout")
		if g then
			g.CellPadding = UDim2.fromOffset(8, 8)
			g.CellSize = UDim2.fromOffset(cw, math.max(54, math.floor(cw / 5.2)))
		end
	end
end
content:GetPropertyChangedSignal("AbsoluteSize"):Connect(sizeGrids)

-- ===== filtering: category tab + search =====
local activeCategory = "All"
local catButtons: { [string]: any } = {}
local function applyFilter(animate: boolean)
	local q = string.lower(searchBox.Text or "")
	local shown: { [string]: number } = {}
	for _, r in ipairs(rows) do
		local vis = (activeCategory == "All" or r.category == activeCategory) and (q == "" or string.find(r.text, q, 1, true) ~= nil)
		r.row.Visible = vis
		if vis then shown[r.category] = (shown[r.category] or 0) + 1 end
	end
	local n = 0
	for category, sec in sections do
		sec.Visible = (shown[category] or 0) > 0
	end
	if animate then
		for _, r in ipairs(rows) do
			if r.row.Visible then
				n += 1
				local s = scaleOf(r.row)
				s.Scale = 0.92
				task.delay(math.min(n, 14) * 0.018, function()
					tween(s, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
				end)
			end
		end
	end
	content.CanvasPosition = Vector2.new(0, 0)
end
local function selectCategory(category: string)
	activeCategory = category
	for name, b in pairs(catButtons) do
		local on = name == category
		tween(b, 0.15, { BackgroundColor3 = if on then CAT_ON else CAT_OFF })
		b.Label.TextColor3 = if on then C(255, 255, 255) else C(220, 210, 240)
		b.Icon.ImageColor3 = if on then C(255, 255, 255) else C(220, 210, 240)
	end
	applyFilter(true)
end
for i, category in ipairs(categories) do
	local b = catTemplate:Clone()
	b.Name = category
	b.LayoutOrder = i
	b.Visible = true
	b.Label.Text = category
	b.Icon.Image = icon(SettingsConfig.CategoryIcons and SettingsConfig.CategoryIcons[category])
	b.Parent = catPanel
	catButtons[category] = b
	b.Activated:Connect(function()
		bump(b)
		selectCategory(category)
	end)
end
searchBox:GetPropertyChangedSignal("Text"):Connect(function() applyFilter(false) end)

local function refreshAll(settings: any)
	for key, fn in pairs(refreshers) do
		fn(settings[key])
	end
end
ClientSettings.Changed:Connect(refreshAll)
refreshAll(ClientSettings.GetAll())

-- the gold shimmer on every gradient named "Shimmer" (same look as the match HUD, in both Places)
if okM and Motion and Motion.loopGradient then
	for _, d in ipairs(gui:GetDescendants()) do
		if d:IsA("UIGradient") and d.Name == "Shimmer" then
			pcall(Motion.loopGradient, d, 3.2)
		end
	end
end

-- ===== open / close =====
local isOpen = false
local function setOpen(open: boolean)
	if open == isOpen then return end
	isOpen = open
	if open then
		dim.Visible = true
		panel.Visible = true
		-- full-screen on narrow screens (phones)
		local cam = workspace.CurrentCamera
		local small = cam ~= nil and cam.ViewportSize.X < 900
		panel.Size = if small then UDim2.fromScale(1, 1) else UDim2.fromScale(0.74, 0.84)
		local s = scaleOf(panel)
		s.Scale = 0.7
		tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		dim.BackgroundTransparency = 1
		tween(dim, 0.25, { BackgroundTransparency = 0.45 })
		for _, paint in ipairs(actionPainters) do paint() end
		refreshAll(ClientSettings.GetAll())
		task.defer(sizeGrids)
		selectCategory(activeCategory)
		if UserInputService.GamepadEnabled then GuiService.SelectedObject = catButtons[activeCategory] end
	else
		searchBox:ReleaseFocus()
		local s = scaleOf(panel)
		local tw = tween(s, 0.18, { Scale = 0.8 }, Enum.EasingStyle.Quad)
		tween(dim, 0.18, { BackgroundTransparency = 1 })
		tw.Completed:Once(function()
			if not isOpen then
				panel.Visible = false
				dim.Visible = false
			end
		end)
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then GuiService.SelectedObject = nil end
	end
end

if openBtn and openBtn:IsA("GuiButton") then
	openBtn.Activated:Connect(function() setOpen(not isOpen) end)
end
closeBtn.Activated:Connect(function() setOpen(false) end)
-- B108 pt13b (user): only the close button closes Settings; the dim never does. Gamepad B = the close button.
UserInputService.InputBegan:Connect(function(input)
	if isOpen and input.KeyCode == Enum.KeyCode.ButtonB and not searchBox:IsFocused() then
		setOpen(false)
	end
end)

-- other screens open Settings through ClientEvents.OpenSettings (created here if the Place has none)
task.spawn(function()
	local ce = ReplicatedStorage:FindFirstChild("ClientEvents")
	if ce == nil then
		ce = Instance.new("Folder")
		ce.Name = "ClientEvents"
		ce.Parent = ReplicatedStorage
	end
	local ev = ce:FindFirstChild("OpenSettings")
	if ev == nil then
		ev = Instance.new("BindableEvent")
		ev.Name = "OpenSettings"
		ev.Parent = ce
	end
	(ev :: BindableEvent).Event:Connect(function() setOpen(true) end)
end)

requestOpen = function()
	setOpen(true)
end
if pendingOpen then
	pendingOpen = false
	task.spawn(function() setOpen(true) end)
end

panel.Visible = false
dim.Visible = false
print(string.format("[SettingsUI] Initialized (%s place, %d row(s), %d categor(ies)).", place, built, #categories))

script:SetAttribute("BootComplete", true)   -- B34 BOOT MARKER
