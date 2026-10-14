--!strict
-- AlamatUI.AlamatButton (B138) -- THE animator for every Alamat button (CollectionService tag "AlamatButton").
-- The look is AUTHORED (RS.AlamatUI.Templates.*, built by tools/alamat_ui_build.luau + tools/alamat_plate.luau);
-- a button differs from another only by its attributes: Theme (a Theme.Palettes name) and Variant
-- (Tile | Hero | Banner | Gem | Pill | Plate). This module builds nothing; it only moves what is there.
-- SHARED CANON since B151 (both Places, ReplicatedStorage.AlamatUI.AlamatButton). docs/systems/alamat-ui.md.
--
-- MOTION
--   idle   : the gold rim's light travels round (gradient rotation), the engraved seal drifts, and every few
--            seconds a shine streak sweeps the gem and a sparkle twinkles (heroes more often).
--   hover  : (mouse) or gamepad SELECTION -- lift + slight tilt, rune ring fades in and turns, icon pops,
--            a sparkle burst. Touch has no hover: press feedback + idle carry it.
--   press  : squash, then on Activated a glow-ring pulse + a radial burst flash.
--   hero   : magic circle always turning, glow breathing.
--   attention (M.setAttention): faster shines + a pulse every 1.6 s (e.g. a claimable daily reward).
--   PLATE (B151, the universal rectangle button): hover lifts x1.05 (no tilt), the rim brightens, a shine
--            sweeps and two corner sparkles twinkle; press sinks x0.94; Activated flashes white + a tinted burst.
--            A TextButton's own Text is mirrored into its `PlateText` label (scripts keep writing btn.Text).
-- Stroke widths follow the button's on-screen size so the look is identical on every device.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local Theme = require(script.Parent:WaitForChild("Theme")) :: any

local M = {}
M.TAG = "AlamatButton"

local Q, BACK = Enum.EasingStyle.Quad, Enum.EasingStyle.Back
local OUT, IN = Enum.EasingDirection.Out, Enum.EasingDirection.In
local HOVER_SCALE = { Tile = 1.08, Hero = 1.06, Banner = 1.03, Gem = 1.12, Pill = 1.04, Plate = 1.05 }

local Sound: any = nil
pcall(function() Sound = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("Sound", 5)) end)
local function sfx(name: string)
	if Sound then pcall(function() Sound.play(name, "UI") end) end
end

local function tw(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local x = TweenService:Create(o, TweenInfo.new(t, style or Q, dir or OUT), props)
	x:Play()
	return x
end

-- ===== theme =====
function M.applyTheme(btn: Instance, name: string?)
	local variant = btn:GetAttribute("Variant")
	if variant == "Plate" and btn:IsA("GuiObject") then
		-- the root IS the colour; the Core gradient on it is a luminance ramp and stays as authored
		btn.BackgroundColor3 = Theme.plateColor(name)
	end
	local core = if variant == "Banner" then Theme.bannerCore(name) else Theme.core(name)
	local tint = Theme.tint(name)
	local glow = Theme.palette(name).Glow
	for _, d in ipairs(btn:GetDescendants()) do
		if d:IsA("UIGradient") then
			if d.Name == "Core" and variant ~= "Plate" then d.Color = core
			elseif d.Name == "Tint" then d.Color = tint end
		elseif d:IsA("Frame") and d.Name == "StudGem" then
			d.BackgroundColor3 = glow
		end
	end
end

-- ===== state =====
local entries: { [GuiButton]: any } = {}
local selector: GuiObject? = nil

local function find(root: Instance?, path: { string }): any
	local node: Instance? = root
	for _, n in ipairs(path) do
		node = node and node:FindFirstChild(n)
	end
	return node
end

function M.twinkle(s: ImageLabel?, dur: number?)
	if s == nil then return end
	local d = dur or 0.6
	local target = tonumber(s:GetAttribute("S")) or 0.2
	s.Size = UDim2.fromScale(50, 0)
	s.ImageTransparency = 0
	local r = math.random(0, 90)
	s.Rotation = r
	tw(s, d * 0.45, { Size = UDim2.fromScale(50, target), Rotation = r + 45 }, Q, OUT)
	task.delay(d * 0.45, function()
		tw(s, d * 0.55, { Size = UDim2.fromScale(50, 0), ImageTransparency = 1, Rotation = r + 90 }, Q, IN)
	end)
end

function M.shine(e: any)
	local s = e.streak
	if s == nil then return end
	s.Position = UDim2.fromScale(-0.5, 0.5)
	s.ImageTransparency = 0.05
	tw(s, if e.variant == "Plate" then 0.55 else 0.75, { Position = UDim2.fromScale(1.5, 0.5) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

function M.pulse(e: any)
	local p = e.pulseImg
	if p then
		p.Size = UDim2.fromScale(0.55, 0.55)
		p.ImageTransparency = 0.1
		tw(p, 0.55, { Size = UDim2.fromScale(1.25, 1.25), ImageTransparency = 1 }, Q, OUT)
	end
end

-- stroke widths are pixels: scale them with the button's on-screen size
local function fit(e: any)
	local a = e.btn.AbsoluteSize
	local s = math.min(a.X, a.Y)
	if s <= 0 then return end
	if e.variant == "Plate" then
		if e.rim then e.rim.Thickness = math.clamp(s * (if e.hovered then 0.1 else 0.075), 1.5, 5) end
		if e.outline then e.outline.Thickness = math.clamp(s * 0.035, 1, 2.5) end
		return
	end
	if e.rim then e.rim.Thickness = math.clamp(s * (if e.variant == "Hero" then 0.035 else 0.042), 1.2, 7) end
	if e.edge then e.edge.Thickness = math.clamp(s * 0.018, 1, 3) end
	if e.outline then e.outline.Thickness = math.clamp(s * 0.016, 1, 3) end
end

local function hover(e: any, on: boolean)
	if e.hovered == on then return end
	e.hovered = on
	if on then sfx("Hover") end
	if e.pop then tw(e.pop, 0.24, { Scale = if on then (HOVER_SCALE[e.variant] or 1.06) else 1 }, BACK, OUT) end
	if e.main and e.variant ~= "Banner" and e.variant ~= "Pill" then
		tw(e.main, 0.24, { Rotation = if on then -2.5 else 0 }, BACK, OUT)
	end
	if e.rune then tw(e.rune, 0.3, { ImageTransparency = if on then 0.2 else 1 }) end
	if e.bob then tw(e.bob, 0.26, { Scale = if on then 1.12 else 1 }, BACK, OUT) end
	if e.variant == "Plate" then
		fit(e)
		if e.glossF then tw(e.glossF, 0.2, { BackgroundTransparency = if on then 0 else 0.15 }) end
	end
	if on then
		for i, s in ipairs(e.sparks) do
			task.delay((i - 1) * 0.07, function() M.twinkle(s, 0.55) end)
		end
		M.shine(e)
	end
end

local function press(e: any, down: boolean)
	if e.pop == nil then return end
	if down then
		tw(e.pop, 0.08, { Scale = if e.variant == "Plate" then 0.94 else 0.92 }, Q, OUT)
	else
		tw(e.pop, 0.28, { Scale = if e.hovered then (HOVER_SCALE[e.variant] or 1.06) else 1 }, BACK, OUT)
	end
end

local function activated(e: any)
	sfx("Click")
	M.pulse(e)
	local b = e.burst
	if b then
		b.ImageTransparency = if e.variant == "Plate" then 0.1 else 0.25
		b.Rotation = math.random(0, 360)
		tw(b, 0.45, { ImageTransparency = 1, Rotation = b.Rotation + 60 }, Q, OUT)
	end
	local f = e.flashF
	if f then
		f.BackgroundTransparency = 0.45
		tw(f, 0.35, { BackgroundTransparency = 1 }, Q, OUT)
	end
	if e.bob then
		e.bob.Scale = 1.25
		tw(e.bob, 0.35, { Scale = if e.hovered then 1.12 else 1 }, BACK, OUT)
	end
end

function M.bind(btn: GuiButton)
	if entries[btn] then return end
	local main = btn:FindFirstChild("Main")
	local variant = tostring(btn:GetAttribute("Variant") or "Tile")
	local plate = variant == "Plate"
	local e: any = {
		btn = btn,
		variant = variant,
		pop = btn:FindFirstChild("Pop"),
		main = main,
		-- a converted Plate re-uses the button's own UIStroke (scripts may hold it by name): `PlateRim` names it
		rim = if plate then (btn:FindFirstChild(tostring(btn:GetAttribute("PlateRim") or "Rim")) or btn:FindFirstChildOfClass("UIStroke"))
			else (main and main:FindFirstChild("Rim")),
		edge = find(btn, { "Label", "Edge" }),
		outline = if plate then find(btn, { "PlateText", "Outline" }) else find(btn, { "Label", "Text", "Outline" }),
		rune = find(btn, { "Aura", "RuneRing" }),
		circle = find(btn, { "Aura", "Circle" }),
		glow = find(btn, { "Aura", "Glow" }),
		pulseImg = find(btn, { "Aura", "Pulse" }),
		burst = if plate then btn:FindFirstChild("Burst") else find(btn, { "Aura", "Burst" }),
		engraving = main and main:FindFirstChild("Engraving"),
		bob = find(main, { "Icon", "Bob" }),
		streak = if plate then find(btn, { "ShineClip", "Streak" }) else find(main, { "ShineClip", "Streak" }),
		flashF = if plate then btn:FindFirstChild("Flash") else nil,
		glossF = if plate then btn:FindFirstChild("Gloss") else nil,
		sparks = {},
		hovered = false,
		attention = false,
		nextIdle = os.clock() + 1.5 + math.random() * 5,
		nextPulse = 0,
		phase = math.random() * 6.28,
	}
	e.rimGrad = e.rim and e.rim:FindFirstChild("Gold")
	local sp = btn:FindFirstChild("Sparkles")
	if sp then
		for _, s in ipairs(sp:GetChildren()) do
			if s:IsA("ImageLabel") then table.insert(e.sparks, s) end
		end
	end
	-- a Plate TextButton keeps its own Text as the source of truth: mirror it into the styled label
	local plateText = if plate then btn:FindFirstChild("PlateText") else nil
	if plateText and plateText:IsA("TextLabel") and btn:IsA("TextButton") then
		local tb = btn :: TextButton
		local function sync()
			plateText.Text = tb.Text
			tb.TextTransparency = 1
		end
		sync()
		tb:GetPropertyChangedSignal("Text"):Connect(sync)
	end
	entries[btn] = e
	btn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() fit(e) end)
	fit(e)
	btn.MouseEnter:Connect(function() hover(e, true) end)
	btn.MouseLeave:Connect(function() hover(e, false) press(e, false) end)
	btn.SelectionGained:Connect(function() hover(e, true) end)
	btn.SelectionLost:Connect(function() hover(e, false) end)
	btn.MouseButton1Down:Connect(function() press(e, true) end)
	btn.MouseButton1Up:Connect(function() press(e, false) end)
	btn.Activated:Connect(function() activated(e) end)
	btn.Destroying:Connect(function() entries[btn] = nil end)
	if selector == nil then
		local t = script.Parent:FindFirstChild("Templates")
		selector = t and t:FindFirstChild("Selector") :: GuiObject?
	end
	if selector and btn.SelectionImageObject == nil then btn.SelectionImageObject = selector end
end

-- bind every tagged button under `root` now and as they appear (HUD re-clones on respawn)
function M.bindAll(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiButton") and CollectionService:HasTag(d, M.TAG) then M.bind(d) end
	end
	root.DescendantAdded:Connect(function(d)
		if d:IsA("GuiButton") and CollectionService:HasTag(d, M.TAG) then M.bind(d) end
	end)
end

function M.setAttention(btn: GuiButton, on: boolean)
	local e = entries[btn]
	if e then e.attention = on end
end

function M.flash(btn: GuiButton)
	local e = entries[btn]
	if e then activated(e) end
end

-- a silent shine + sparkle (e.g. a currency pill whose amount just went up)
function M.glint(btn: GuiButton)
	local e = entries[btn]
	if e == nil then return end
	M.shine(e)
	if #e.sparks > 0 then M.twinkle(e.sparks[math.random(1, #e.sparks)], 0.6) end
	if e.pop then
		e.pop.Scale = 1.08
		tw(e.pop, 0.35, { Scale = 1 }, BACK, OUT)
	end
end

-- ===== one loop drives every button =====
local started = false
function M.start()
	if started then return end
	started = true
	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for btn, e in pairs(entries) do
			if btn.Parent == nil then
				entries[btn] = nil
				continue
			end
			local sg = btn:FindFirstAncestorWhichIsA("ScreenGui")
			if sg and not sg.Enabled then continue end
			if not btn.Visible then continue end
			if e.rimGrad then e.rimGrad.Rotation = (e.rimGrad.Rotation + dt * (if e.variant == "Plate" then 30 else 38)) % 360 end
			if e.engraving then e.engraving.Rotation = (e.engraving.Rotation + dt * 5) % 360 end
			if e.rune and e.hovered then e.rune.Rotation = (e.rune.Rotation + dt * 50) % 360 end
			if e.variant == "Hero" then
				if e.circle then e.circle.Rotation = (e.circle.Rotation + dt * 12) % 360 end
				if e.glow then e.glow.ImageTransparency = 0.5 + 0.22 * math.sin(now * 2.2 + e.phase) end
			end
			if e.attention and now >= e.nextPulse then
				e.nextPulse = now + 1.6
				M.pulse(e)
				if e.variant == "Plate" then M.shine(e) end
			end
			if now >= e.nextIdle then
				local fast = e.variant == "Hero" or e.attention
				e.nextIdle = now + (if fast then 1.8 + math.random() * 2 else 3.5 + math.random() * 5)
				M.shine(e)
				if #e.sparks > 0 and math.random() < (if fast then 0.9 else 0.55) then
					M.twinkle(e.sparks[math.random(1, #e.sparks)], 0.7)
				end
			end
		end
	end)
end

return M
