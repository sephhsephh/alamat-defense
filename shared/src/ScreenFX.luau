--!strict
-- Client.UI.ScreenFX (LOBBY, owner AD-UI, B108 pt13c -- docs/systems/screen-fx.md)
--
-- ONE juice layer for the NPC screens (Stat Reroll, Silver Shop, Evolve, Ascension, Crafting) so they
-- open, react and celebrate the same way. Controllers keep ALL of their logic; they call in here at
-- four moments only: open, close, "the server said yes" (success) and "the server said no" (fail).
--
--   ScreenFX.open(gui, panels, opts?)      blur the world, pop the panels in (staggered, tilt + rise)
--   ScreenFX.close(gui, panels, done?)     quick shrink-out, then gui.Enabled = false, blur released
--   ScreenFX.juice(root)                   hover / press / gamepad-select springs on every button
--   ScreenFX.watchGrid(container)          cards that get (re)rendered pop in, staggered
--   ScreenFX.gradients(root)               animate every UIGradient carrying an Anim attribute
--   ScreenFX.charge(anchor, tier?) -> stop pulsing ring around a slot while a remote is in flight
--   ScreenFX.success(anchor, opts)         burst + sparks + flash + big text (+ shake a panel)
--   ScreenFX.fail(anchor)                  red shake
--   ScreenFX.pop(obj, amount?)             one scale punch (a value just changed)
--
-- No layout is created here (user rule): every effect is a CLONE of an authored template in
-- StarterGui.ScreenFXLayer.Templates, and the blur is the authored Lighting.ScreenFXBlur. The only
-- thing made in code is a UIScale modifier (the Motion.isolate precedent), named "FXScale".

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local UIKit = RS:WaitForChild("Shared"):WaitForChild("UIKit")
local Motion = require(UIKit:WaitForChild("Motion")) :: any
local TierConfig = require(RS:WaitForChild("Configs"):WaitForChild("Meta"):WaitForChild("TierConfig")) :: any
local SoundKit: any = nil
do
	local ok, m = pcall(require, UIKit:WaitForChild("Sound"))
	if ok then SoundKit = m end
end

local ScreenFX = {}

ScreenFX.Tuning = {
	BlurSize = 14,
	OpenTime = 0.42,
	OpenStagger = 0.07,
	CloseTime = 0.16,
	GridStagger = 0.025,
	GridMaxDelay = 0.45,
	HoverScale = 1.05,
	PressScale = 0.92,
}

local layer: ScreenGui? = nil
local function getLayer(): ScreenGui?
	if layer and layer.Parent then return layer end
	local pg = player:FindFirstChild("PlayerGui")
	local l = pg and pg:FindFirstChild("ScreenFXLayer")
	layer = (l and l:IsA("ScreenGui")) and l or nil
	return layer
end
local function template(name: string): GuiObject?
	local l = getLayer()
	local t = l and l:FindFirstChild("Templates")
	local o = t and t:FindFirstChild(name)
	if not (o and o:IsA("GuiObject")) then return nil end
	local c = o:Clone() :: GuiObject
	c.Visible = true -- templates are authored hidden so the layer never shows them
	return c
end

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?, delay: number?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, 0, false, delay or 0), props)
	tw:Play()
	return tw
end
local function sfx(name: string)
	if SoundKit then pcall(SoundKit.play, name, "UI") end
end

-- The one UIScale this module owns on an object. An object that already carries somebody else's
-- UIScale (Motion.isolate, a designer's) is left alone -- two scales would multiply.
local function scaleOf(obj: GuiObject): UIScale?
	local mine = obj:FindFirstChild("FXScale")
	if mine and mine:IsA("UIScale") then return mine end
	if obj:FindFirstChildOfClass("UIScale") then return nil end
	local s = Instance.new("UIScale")
	s.Name = "FXScale"
	s.Parent = obj
	return s
end

local function tierSeq(tier: string?): ColorSequence
	if tier then
		local ok, seq = pcall(TierConfig.GradientFor, tier)
		if ok and typeof(seq) == "ColorSequence" then return seq end
		local okc, c = pcall(TierConfig.GetColor, tier)
		if okc and typeof(c) == "Color3" then return ColorSequence.new(c) end
	end
	return ColorSequence.new(Color3.fromRGB(255, 226, 120), Color3.fromRGB(255, 255, 255))
end
local function paint(root: Instance, seq: ColorSequence)
	if root:IsA("UIGradient") and root.Name == "TierGradient" then root.Color = seq end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("UIGradient") and d.Name == "TierGradient" then d.Color = seq end
	end
end
local function seqFor(opts: any): ColorSequence
	if typeof(opts.Color) == "ColorSequence" then return opts.Color end
	if typeof(opts.Color) == "Color3" then return ColorSequence.new(opts.Color) end
	return tierSeq(opts.Tier)
end

-- centre of `anchor` in the FX layer's space (every NPC screen and the layer ignore the inset)
local function centreOf(anchor: GuiObject): Vector2
	local p, s = anchor.AbsolutePosition, anchor.AbsoluteSize
	local c = p + s / 2
	local sg = anchor:FindFirstAncestorOfClass("ScreenGui")
	local l = getLayer()
	if sg and l and sg.IgnoreGuiInset ~= l.IgnoreGuiInset then
		local inset = game:GetService("GuiService"):GetGuiInset()
		c += if l.IgnoreGuiInset then inset else -inset
	end
	return c
end

-- ===== blur (ref-counted: two screens open = still blurred until both close) =====
local blurUsers: { [ScreenGui]: boolean } = {}
local function refreshBlur()
	local blur = Lighting:FindFirstChild("ScreenFXBlur")
	if not (blur and blur:IsA("BlurEffect")) then return end
	local any = next(blurUsers) ~= nil
	tween(blur, any and 0.35 or 0.2, { Size = any and ScreenFX.Tuning.BlurSize or 0 })
end

-- ===== animated gradients =====
local animated: { [UIGradient]: boolean } = {}
local function animateOne(g: Instance)
	if not g:IsA("UIGradient") or animated[g] then return end
	local mode = g:GetAttribute("Anim")
	if mode == nil then return end
	animated[g] = true
	local period = tonumber(g:GetAttribute("Period")) or 4
	if mode == "Loop" then
		Motion.loopGradient(g, period)
	elseif mode == "Spin" then
		Motion.spinGradient(g, period)
	end
end
function ScreenFX.gradients(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do animateOne(d) end
	root.DescendantAdded:Connect(animateOne)
end

-- ===== button juice =====
local juiced: { [GuiButton]: boolean } = {}
local function juiceOne(b: Instance)
	if not b:IsA("GuiButton") or juiced[b] then return end
	if b:GetAttribute("NoFX") or CollectionService:HasTag(b, "UIKitButton") then return end
	if b.Name == "Overlay" or b.Name == "PopupScrim" or b.Name == "Scrim" or b.Name == "DimButton" then return end
	local s = scaleOf(b)
	if not s then return end
	juiced[b] = true
	local hovered = false
	local function to(v: number, t: number, style: Enum.EasingStyle?)
		tween(s, t, { Scale = v }, style or Enum.EasingStyle.Quad)
	end
	b.MouseEnter:Connect(function() hovered = true if b.Active then to(ScreenFX.Tuning.HoverScale, 0.12) end end)
	b.MouseLeave:Connect(function() hovered = false to(1, 0.14) end)
	b.MouseButton1Down:Connect(function() if b.Active then to(ScreenFX.Tuning.PressScale, 0.06) end end)
	b.MouseButton1Up:Connect(function() to(if hovered then ScreenFX.Tuning.HoverScale else 1, 0.22, Enum.EasingStyle.Back) end)
	b.SelectionGained:Connect(function() to(ScreenFX.Tuning.HoverScale, 0.12) end)
	b.SelectionLost:Connect(function() to(1, 0.12) end)
	b.Activated:Connect(function()
		if not b.Active then return end
		to(ScreenFX.Tuning.PressScale, 0.05)
		task.delay(0.05, function() to(if hovered then ScreenFX.Tuning.HoverScale else 1, 0.25, Enum.EasingStyle.Back) end)
	end)
end
function ScreenFX.juice(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do juiceOne(d) end
	root.DescendantAdded:Connect(function(d)
		-- Filter BEFORE deferring: a grid build adds ~35 descendants per card, and only buttons matter.
		if d:IsA("GuiButton") then task.defer(juiceOne, d) end
	end)
end

-- ===== grid pop-in =====
-- A card RE-rendered under the same name within 4s (a buy, a filter, a refresh) does NOT pop again --
-- only a fresh render (opening the screen, a new tab) gets the cascade.
function ScreenFX.watchGrid(container: Instance)
	local batch, last = 0, 0
	local seen: { [string]: number } = {}
	container.ChildAdded:Connect(function(c)
		if not c:IsA("GuiObject") then return end
		local now = os.clock()
		local prev = seen[c.Name]
		seen[c.Name] = now
		if prev and now - prev < 4 then return end
		if now - last > 0.25 then batch = 0 end
		last = now
		batch += 1
		local delay = math.min(batch * ScreenFX.Tuning.GridStagger, ScreenFX.Tuning.GridMaxDelay)
		task.defer(function()
			if not c.Parent or not c.Visible then return end
			local s = scaleOf(c)
			if not s then return end
			s.Scale = 0.35
			tween(s, 0.32, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out, delay)
		end)
	end)
end

-- ===== open / close =====
local REST = "FXRestPosition"
local openState: { [ScreenGui]: boolean } = {}
local function rest(p: GuiObject): UDim2
	local r = p:GetAttribute(REST)
	if typeof(r) ~= "UDim2" then
		r = p.Position
		p:SetAttribute(REST, r)
	end
	return r :: UDim2
end

-- `panels` = the screen's top-level frames, in the order they should land. `opts.Dim` = an overlay
-- whose authored transparency fades in. `opts.NoBlur` skips the blur (full-screen layouts).
-- One NPC screen at a time: a registered screen's own close() runs when ANOTHER registered screen
-- opens (walking from the Evolve NPC to the Ascension NPC used to stack both).
local closers: { [ScreenGui]: () -> () } = {}
function ScreenFX.register(gui: ScreenGui, closeFn: () -> ())
	closers[gui] = closeFn
end

function ScreenFX.open(gui: ScreenGui, panels: { GuiObject }, opts: any?)
	local o = opts or {}
	for other, fn in pairs(closers) do
		if other ~= gui and openState[other] then
			task.spawn(fn)
		end
	end
	gui.Enabled = true
	openState[gui] = true
	if not o.NoBlur then
		blurUsers[gui] = true
		refreshBlur()
	end
	if o.Dim and o.Dim:IsA("GuiObject") then
		local dim = o.Dim :: GuiObject
		local target = dim:GetAttribute("FXRestTransparency")
		if type(target) ~= "number" then
			target = dim.BackgroundTransparency
			dim:SetAttribute("FXRestTransparency", target)
		end
		dim.BackgroundTransparency = 1
		tween(dim, 0.3, { BackgroundTransparency = target })
	end
	-- NO UIScale on open: several controllers size their grids from AbsoluteSize while rendering on
	-- open, and a scaled-down panel made them lay out shrunken cards (seen on the Silver Shop). The
	-- drama is a drop-in from below with an alternating tilt, staggered per panel, over the blur.
	local i = 0
	for _, p in ipairs(panels) do
		if p and p.Parent then
			local r = rest(p)
			local d = i * ScreenFX.Tuning.OpenStagger
			i += 1
			-- B108 pt13e: a controller that used UIKit.Motion hid its Main at boot (Motion owned Visible);
			-- ScreenFX only moves panels, so every ancestor up to the ScreenGui is shown here. (StatReroll
			-- opened to a bare dim because of exactly this.)
			local anc = p.Parent
			while anc and anc ~= gui do
				if anc:IsA("GuiObject") then anc.Visible = true end
				anc = anc.Parent
			end
			local fs = p:FindFirstChild("FXScale") -- a close() interrupted by this open leaves it shrunk
			if fs and fs:IsA("UIScale") then fs.Scale = 1 end
			p.Position = r + UDim2.fromScale(0, 0.12)
			p.Rotation = if i % 2 == 0 then 4 else -4
			tween(p, ScreenFX.Tuning.OpenTime, { Position = r, Rotation = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out, d)
		end
	end
	sfx("Open")
end

function ScreenFX.close(gui: ScreenGui, panels: { GuiObject }, done: (() -> ())?)
	openState[gui] = nil
	blurUsers[gui] = nil
	refreshBlur()
	local t = ScreenFX.Tuning.CloseTime
	for _, p in ipairs(panels) do
		if p and p.Parent then
			local r = rest(p)
			local s = scaleOf(p)
			tween(p, t, { Position = r + UDim2.fromScale(0, 0.04) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			if s then tween(s, t, { Scale = 0.7 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
		end
	end
	sfx("Close")
	task.delay(t, function()
		if openState[gui] then return end -- re-opened during the tween
		gui.Enabled = false
		for _, p in ipairs(panels) do
			if p and p.Parent then
				p.Position = rest(p)
				p.Rotation = 0
				local s = p:FindFirstChild("FXScale")
				if s and s:IsA("UIScale") then s.Scale = 1 end
			end
		end
		if done then done() end
	end)
end

-- Popups (pickers, confirm cards...) spring in whenever their own controller makes them Visible.
function ScreenFX.popOnShow(frames: { GuiObject })
	for _, f in ipairs(frames) do
		if f then
			f:GetPropertyChangedSignal("Visible"):Connect(function()
				if not f.Visible then return end
				-- slide + tilt, not scale (same AbsoluteSize reason as open)
				local r = rest(f)
				f.Position = r + UDim2.fromScale(0, 0.06)
				f.Rotation = -2
				tween(f, 0.3, { Position = r, Rotation = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
				sfx("Open")
			end)
		end
	end
end

function ScreenFX.isOpen(gui: ScreenGui): boolean
	return openState[gui] == true
end

-- ===== reactions =====
function ScreenFX.pop(obj: GuiObject?, amount: number?)
	if not obj then return end
	local s = scaleOf(obj)
	if not s then return end
	s.Scale = amount or 1.25
	tween(s, 0.35, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

function ScreenFX.shake(obj: GuiObject?, strength: number?, time: number?)
	if not obj then return end
	local r = obj.Position
	local k = strength or 8
	local dur = time or 0.3
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e >= dur or not obj.Parent then
			conn:Disconnect()
			obj.Position = r
			return
		end
		local f = k * (1 - e / dur)
		obj.Position = r + UDim2.fromOffset((math.random() - 0.5) * 2 * f, (math.random() - 0.5) * 2 * f)
	end)
end

-- A ring that pulses around `anchor` until the returned stop() is called (or 8s pass).
function ScreenFX.charge(anchor: GuiObject?, tier: string?): () -> ()
	local l = getLayer()
	local ring = anchor and l and template("Charge")
	if not (anchor and l and ring) then return function() end end
	paint(ring, tierSeq(tier))
	local c = centreOf(anchor)
	local base = anchor.AbsoluteSize
	ring.Position = UDim2.fromOffset(c.X, c.Y)
	ring.Size = UDim2.fromOffset(base.X + 10, base.Y + 10)
	ring.Parent = l
	local grad = ring:FindFirstChildWhichIsA("UIGradient", true)
	local t0 = os.clock()
	local alive = true
	local conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		local k = 1 + 0.06 * math.sin(e * 14)
		ring.Size = UDim2.fromOffset((base.X + 10) * k, (base.Y + 10) * k)
		if grad then grad.Rotation = (e * 360) % 360 end
		if e > 8 then alive = false end
	end)
	local function stop()
		if conn then conn:Disconnect() end
		if ring.Parent then ring:Destroy() end
	end
	task.delay(8, function() if not alive then stop() end end)
	return stop
end

-- opts = { Text, Tier | Color (Color3/ColorSequence), Shake (GuiObject), Big (bool), Sound }
function ScreenFX.success(anchor: GuiObject?, opts: any?)
	local o = opts or {}
	local l = getLayer()
	if not (anchor and l) then return end
	local seq = seqFor(o)
	local c = centreOf(anchor)
	local size = math.max(anchor.AbsoluteSize.X, anchor.AbsoluteSize.Y)
	local big = o.Big == true

	local burst = template("Burst")
	if burst then
		paint(burst, seq)
		burst.Position = UDim2.fromOffset(c.X, c.Y)
		burst.Size = UDim2.fromOffset(size * 0.4, size * 0.4)
		burst.Parent = l
		local target = size * (big and 3.2 or 2.2)
		tween(burst, 0.55, { Size = UDim2.fromOffset(target, target) }, Enum.EasingStyle.Quart)
		local rays = burst:FindFirstChild("Rays") :: GuiObject
		if rays then tween(rays, 0.9, { Rotation = 90 }, Enum.EasingStyle.Quad) end
		for _, d in ipairs(burst:GetDescendants()) do
			if d:IsA("Frame") then
				tween(d, 0.6, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0.3)
			elseif d:IsA("UIStroke") then
				tween(d, 0.6, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0.3)
			end
		end
		task.delay(1, function() burst:Destroy() end)
	end

	for i = 1, (big and 18 or 10) do
		local sp = template("Spark")
		if sp then
			paint(sp, seq)
			sp.Position = UDim2.fromOffset(c.X, c.Y)
			local s0 = math.random(8, big and 18 or 13)
			sp.Size = UDim2.fromOffset(s0, s0)
			sp.Parent = l
			local a = (i / (big and 18 or 10)) * math.pi * 2 + math.random() * 0.4
			local dist = size * (0.8 + math.random() * (big and 1.4 or 0.8))
			tween(sp, 0.6 + math.random() * 0.3, {
				Position = UDim2.fromOffset(c.X + math.cos(a) * dist, c.Y + math.sin(a) * dist),
				Rotation = sp.Rotation + 180,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(2, 2),
			}, Enum.EasingStyle.Quart)
			task.delay(1, function() sp:Destroy() end)
		end
	end

	local flash = l:FindFirstChild("Flash") :: Frame
	if flash then
		flash.BackgroundTransparency = big and 0.35 or 0.7
		tween(flash, big and 0.5 or 0.3, { BackgroundTransparency = 1 })
	end

	if type(o.Text) == "string" and o.Text ~= "" then
		local rt = template("ResultText") :: TextLabel?
		if rt then
			paint(rt, seq)
			rt.Text = o.Text
			local w = big and 620 or 420
			rt.Size = UDim2.fromOffset(w, w * 0.17)
			-- keep the words on screen even when the anchor sits at an edge (Day 1, a corner card)
			local vw = l.AbsoluteSize.X
			local tx = math.clamp(c.X, w / 2 + 8, math.max(w / 2 + 8, vw - w / 2 - 8))
			c = Vector2.new(tx, c.Y)
			rt.Position = UDim2.fromOffset(c.X, c.Y - size * 0.15)
			rt.Parent = l
			local s = scaleOf(rt)
			if s then
				s.Scale = 0.2
				tween(s, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
			end
			tween(rt, 1.4, { Position = UDim2.fromOffset(c.X, c.Y - size * 0.15 - 70) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0.2)
			tween(rt, 0.4, { TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 1.2)
			local st = rt:FindFirstChildOfClass("UIStroke")
			if st then tween(st, 0.4, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 1.2) end
			task.delay(1.7, function() rt:Destroy() end)
		end
	end

	ScreenFX.pop(anchor, big and 1.35 or 1.2)
	if o.Shake then ScreenFX.shake(o.Shake, big and 12 or 6, big and 0.4 or 0.25) end
	sfx(o.Sound or (big and "LevelUp" or "RewardPop"))
end

function ScreenFX.fail(anchor: GuiObject?)
	if not anchor then return end
	ScreenFX.shake(anchor, 7, 0.28)
	sfx("Error")
end

return ScreenFX
