--!strict
-- UIKitConfirm.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.Confirm)
-- ONE confirmation dialog for the WHOLE experience, both Places. Added B32 2026-08-19.
--
-- ===== WHY THIS IS SHARED AND NOT A SCREEN =====
-- "Are you sure?" is asked by things that have nothing else in common: selling units, leaving a
-- match, spending a premium currency, resetting settings. Every one of those growing its own popup
-- is how four dialogs end up with four different button orders and three different meanings for
-- the greyed-out state. So the DESIGN is one authored ScreenGui (`StarterGui.ConfirmationPopupUI`)
-- and the BEHAVIOUR is this module.
--
-- ===== THE ASK IS A FUNCTION CALL THAT YIELDS =====
--   local Confirm = require(ReplicatedStorage.Shared.UIKit.Confirm)
--   if Confirm.ask({ Title = "SELL UNITS", Text = "Sell 3 units for 170 Silver?", Tone = "Danger" }) then ... end
-- It returns a boolean, so a caller reads top-to-bottom instead of splitting itself across two
-- callbacks. It YIELDS, so callers must already be on their own thread -- every screen in this
-- project does its remote work inside `task.spawn`, so that costs them nothing.
--
-- ===== THE TWO-SECOND GATE (user's spec) =====
-- `YesButton` starts GREY and NOT clickable, fills its `Gate` bar / counts down in its own label, then
-- turns its Tone colour and becomes clickable. That is a deliberate speed bump on irreversible actions --
-- B31's sell path destroys units permanently, and the whole point is that the player cannot muscle-memory
-- their way through it. `NoButton` is live IMMEDIATELY: backing out is never the dangerous direction.
--
-- ===== B144: THE ALAMAT LOOK (user: "better effects, animation, vfx, alamat defense style") =====
-- The GUI was rebuilt by tools/confirm_popup_build.luau (same script in both Places). This module ANIMATES
-- whatever optional parts the GUI carries -- every one is optional, so an older GUI still works as before:
--   ConfirmationFrame.Pop (UIScale)              pop in (Back) / pop out; without it, UIKit.Motion slides
--   ConfirmationFrame.Aura.{Rays,Circle,Glow}    spin + breathe while open
--   ConfirmationFrame.Emblem.{Core,Glyph}        "?" or "!" on a gem coloured by the Tone
--   <part>.ShineClip.Streak                      a light sweep (the panel on open, YES when it unlocks)
--   ConfirmationFrame.Sparkles.*                 twinkle
--   Yes/NoButton.Core (UIGradient)               the button colour (locked grey -> Tone) -- else ImageColor3/BG
--   YesButton.Gate (Frame) / .Burst (ImageLabel) the gate filling left to right / a flash when it opens
-- opts.Tone: "Normal" (green, default) | "Danger" (red: selling, deleting, resetting) | "Premium" (gold: gems, Robux).
-- Platforms: mouse + touch press the buttons; a GAMEPAD gets NO selected on open and ButtonB answers NO (it is
-- the close button -- the only way a UI closes, user rule). The scrim never closes the dialog.
--
-- Instance shape (resolved fresh on every ask, because the ScreenGui is ResetOnSpawn):
--   ConfirmationPopupUI (ScreenGui)
--   `-- Background (Frame)                 the scrim
--        `-- ConfirmationFrame (GuiObject)   pops / slides in
--             `-- Main (Frame)
--                  |-- ConfirmationLabel (TextLabel)   the title
--                  |-- ConfirmationText (TextLabel)    the question
--                  |-- YesButton (GuiButton) > ButtonText
--                  `-- NoButton  (GuiButton) > ButtonText
-- Every part is optional and degrades with a single warn -- a missing label must not be able to
-- stop a player answering a dialog that is already on screen.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Same non-blocking sibling rule as `UIKit.Button`, for the same reason: a `WaitForChild` with no
-- timeout blocks forever, and a Place caught mid-deploy would hang the first screen that asked for a
-- confirmation rather than showing one without a slide or a sound.
local function optionalSibling(name: string, stub: any): any
	local inst = script.Parent:FindFirstChild(name) or script.Parent:WaitForChild(name, 10)
	if inst == nil then
		warn("[UIKit.Confirm] no sibling module '" .. name .. "' after 10s -- carrying on without it.")
		return stub
	end
	local ok, mod = pcall(require, inst)
	if not ok then
		warn("[UIKit.Confirm] sibling module '" .. name .. "' failed to load: " .. tostring(mod))
		return stub
	end
	return mod
end
local Motion = optionalSibling("Motion", {
	slideIn = function(frame) if frame then frame.Visible = true end end,
	slideOut = function(frame, opts)
		if frame then frame.Visible = false end
		if opts and opts.gui then opts.gui.Enabled = false end
		if opts and opts.onComplete then opts.onComplete() end
	end,
})
local Sound = optionalSibling("Sound", { play = function() end, Names = {} })

local Confirm = {}

local function rgb(r: number, g: number, b: number): Color3 return Color3.fromRGB(r, g, b) end

Confirm.Tuning = {
	-- Old-GUI fallback (a button with no `Core` gradient): "grey, then green" (user's B32 spec).
	LockedColor = rgb(92, 92, 100),
	ReadyColor = rgb(76, 175, 80),
	-- Seconds the Yes button stays locked. Callers may override per ask.
	Delay = 2,
	ColorTime = 0.25,
	-- B144: gem palettes (Top -> Bottom of the button's `Core` gradient), same family as AlamatUI.Theme.
	Locked = { Top = rgb(140, 138, 152), Bottom = rgb(58, 56, 70) },
	Cancel = { Top = rgb(112, 82, 184), Bottom = rgb(34, 20, 70) },
	Tones = {
		Normal = { Top = rgb(156, 240, 122), Bottom = rgb(28, 138, 72), Emblem = { rgb(255, 221, 128), rgb(206, 122, 30) }, Glyph = "?" },
		Danger = { Top = rgb(255, 164, 92), Bottom = rgb(192, 50, 58), Emblem = { rgb(255, 150, 110), rgb(176, 36, 48) }, Glyph = "!" },
		Premium = { Top = rgb(255, 221, 128), Bottom = rgb(206, 122, 30), Emblem = { rgb(255, 236, 160), rgb(214, 140, 40) }, Glyph = "?" },
	} :: { [string]: any },
	ScrimTransparency = 0.15, -- the scrim's edge vignette (authored UIGradient) darkens the corners further
	PopFrom = 0.72,
	PopTime = 0.34,
	CloseTime = 0.16,
	SpinRays = 10,     -- degrees per second
	SpinCircle = -16,
}

local GUI_NAME = "ConfirmationPopupUI"
local ACTION_NO = "UIKitConfirm_No"

local warned: { [string]: boolean } = {}
local function warnOnce(key: string, msg: string)
	if warned[key] then return end
	warned[key] = true
	warn("[UIKit.Confirm] " .. msg)
end

-- ONE dialog at a time. A second ask while one is open is a caller bug, not a queue to service:
-- two stacked "are you sure?" prompts is how a player answers the wrong one.
local busy = false

function Confirm.isOpen(): boolean
	return busy
end

type Parts = {
	gui: ScreenGui,
	background: GuiObject,
	frame: GuiObject,
	title: TextLabel?,
	text: TextLabel?,
	yes: GuiButton,
	no: GuiButton,
	yesLabel: TextLabel?,
}

local function resolve(): Parts?
	local lp = Players.LocalPlayer
	local pg = lp and lp:FindFirstChildOfClass("PlayerGui")
	local gui = pg and pg:WaitForChild(GUI_NAME, 10)
	if not (gui and gui:IsA("ScreenGui")) then
		warnOnce("gui", "no PlayerGui." .. GUI_NAME ..
			" in this Place -- run tools/confirm_popup_build.luau there. Confirms will auto-answer NO.")
		return nil
	end
	local background = gui:FindFirstChild("Background")
	local frame = background and background:FindFirstChild("ConfirmationFrame")
	local main = frame and frame:FindFirstChild("Main")
	local yes = main and main:FindFirstChild("YesButton")
	local no = main and main:FindFirstChild("NoButton")
	if not (background and background:IsA("GuiObject") and frame and frame:IsA("GuiObject")
		and main and yes and yes:IsA("GuiButton") and no and no:IsA("GuiButton")) then
		warnOnce("shape", GUI_NAME .. " is missing Background/ConfirmationFrame/Main/YesButton/NoButton " ..
			"-- confirms will auto-answer NO rather than block the player.")
		return nil
	end
	local yesLabel = yes:FindFirstChild("ButtonText")
	return {
		gui = gui,
		background = background :: GuiObject,
		frame = frame :: GuiObject,
		title = (main:FindFirstChild("ConfirmationLabel") :: any),
		text = (main:FindFirstChild("ConfirmationText") :: any),
		yes = yes :: GuiButton,
		no = no :: GuiButton,
		yesLabel = (yesLabel and yesLabel:IsA("TextLabel")) and yesLabel or nil,
	}
end

local function setText(label: TextLabel?, value: string?)
	if label and value ~= nil then label.Text = value end
end

local function tween(inst: Instance?, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween?
	if inst == nil then return nil end
	local tw = TweenService:Create(inst, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

-- The button's colour. A `Core` UIGradient (the B144 gem look) takes the palette; an older ImageButton is
-- tinted through ImageColor3 and a plain TextButton through BackgroundColor3 (`flat` colour).
local function paint(btn: GuiButton, pal: any, flat: Color3, instant: boolean?)
	local core = btn:FindFirstChild("Core")
	if core and core:IsA("UIGradient") then
		core.Color = ColorSequence.new(pal.Top, pal.Bottom)
		return
	end
	local prop = if btn:IsA("ImageButton") then "ImageColor3" else "BackgroundColor3"
	if instant then
		(btn :: any)[prop] = flat
		return
	end
	tween(btn, Confirm.Tuning.ColorTime, { [prop] = flat })
end

-- A light sweep across `part` (its ShineClip.Streak), left to right.
local function sweep(part: Instance?, time: number?)
	local clip = part and part:FindFirstChild("ShineClip")
	local streak = clip and clip:FindFirstChild("Streak")
	if not (streak and streak:IsA("GuiObject")) then return end
	streak.Position = UDim2.fromScale(-0.6, 0.5)
	tween(streak, time or 0.7, { Position = UDim2.fromScale(1.6, 0.5) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
end

local function popScale(part: Instance?): UIScale?
	local s = part and part:FindFirstChild("Pop")
	return if s and s:IsA("UIScale") then s else nil
end

-- opts = { Title, Text, YesText, NoText, Delay, Tone }
-- Returns true only if the player pressed Yes. Every failure path returns FALSE, because the safe
-- answer to a question nobody could actually see is "no".
function Confirm.ask(opts: { [string]: any }?): boolean
	opts = opts or {}
	if busy then
		warnOnce("busy", "a confirmation is already open -- the second ask was refused (answered NO). " ..
			"Two stacked dialogs is how a player answers the wrong one.")
		return false
	end
	local p = resolve()
	if p == nil then return false end

	busy = true
	local answer: boolean? = nil
	local conns: { RBXScriptConnection } = {}
	local T = Confirm.Tuning
	local tone = T.Tones[tostring(opts.Tone or "Normal")] or T.Tones.Normal

	setText(p.title, opts.Title or "CONFIRMATION")
	setText(p.text, opts.Text or "Are you sure?")
	local baseYes = if p.yesLabel then p.yesLabel.Text else "YES"
	if opts.YesText ~= nil then baseYes = tostring(opts.YesText) end
	local noLabel = p.no:FindFirstChild("ButtonText")
	if opts.NoText ~= nil and noLabel and noLabel:IsA("TextLabel") then noLabel.Text = tostring(opts.NoText) end

	-- Emblem: "?" / "!" on a gem in the Tone's colours.
	local emblem = p.frame:FindFirstChild("Emblem")
	if emblem then
		local core = emblem:FindFirstChild("Core")
		if core and core:IsA("UIGradient") then core.Color = ColorSequence.new(tone.Emblem[1], tone.Emblem[2]) end
		local glyph = emblem:FindFirstChild("Glyph")
		if glyph and glyph:IsA("TextLabel") then glyph.Text = tone.Glyph end
	end

	-- LOCKED state, applied INSTANTLY: a Yes that fades in from its colour would be clickable-looking
	-- during the very window the gate exists to protect.
	p.yes.Active = false
	paint(p.yes, T.Locked, T.LockedColor, true)
	paint(p.no, T.Cancel, p.no:IsA("ImageButton") and (p.no :: any).ImageColor3 or (p.no :: any).BackgroundColor3, true)
	p.no.Active = true
	local gate = p.yes:FindFirstChild("Gate")
	if gate and gate:IsA("GuiObject") then
		gate.Size = UDim2.fromScale(0, 1)
		gate.BackgroundTransparency = 0.72
	end

	conns[#conns + 1] = p.yes.Activated:Connect(function()
		if not p.yes.Active then return end -- belt and braces; Activated should not fire anyway
		answer = true
	end)
	conns[#conns + 1] = p.no.Activated:Connect(function()
		answer = false
	end)
	-- hover / select lift on both buttons
	for _, b in ipairs({ p.yes, p.no }) do
		local s = popScale(b)
		if s then
			s.Scale = 1
			conns[#conns + 1] = b.MouseEnter:Connect(function() if b.Active then tween(s, 0.12, { Scale = 1.05 }) end end)
			conns[#conns + 1] = b.MouseLeave:Connect(function() tween(s, 0.12, { Scale = 1 }) end)
			conns[#conns + 1] = b.SelectionGained:Connect(function() tween(s, 0.12, { Scale = 1.05 }) end)
			conns[#conns + 1] = b.SelectionLost:Connect(function() tween(s, 0.12, { Scale = 1 }) end)
		end
	end

	-- OPEN: the scrim fades in, the card pops (Back), the panel's shine sweeps once.
	p.gui.Enabled = true
	local pop = popScale(p.frame)
	if pop then
		p.background.BackgroundTransparency = 1
		p.background.Visible = true
		p.frame.Visible = true
		pop.Scale = T.PopFrom
		tween(p.background, 0.2, { BackgroundTransparency = T.ScrimTransparency })
		tween(pop, T.PopTime, { Scale = 1 }, Enum.EasingStyle.Back)
		task.delay(0.15, function() if answer == nil then sweep(p.frame:FindFirstChild("Panel"), 0.8) end end)
	else
		p.background.Visible = true
		Motion.slideIn(p.frame, { gui = p.gui })
	end
	Sound.play(Sound.Names.Open, "UI")

	-- While open: the aura spins + breathes, the sparkles twinkle. ONE RenderStepped, gone at close.
	local aura = p.frame:FindFirstChild("Aura")
	local sparkles = p.frame:FindFirstChild("Sparkles")
	local clock = 0
	conns[#conns + 1] = RunService.RenderStepped:Connect(function(dt: number)
		clock += dt
		if aura then
			local rays = aura:FindFirstChild("Rays")
			local circle = aura:FindFirstChild("Circle")
			local glow = aura:FindFirstChild("Glow")
			if rays and rays:IsA("GuiObject") then rays.Rotation = (rays.Rotation + T.SpinRays * dt) % 360 end
			if circle and circle:IsA("GuiObject") then circle.Rotation = (circle.Rotation + T.SpinCircle * dt) % 360 end
			if glow and glow:IsA("ImageLabel") then glow.ImageTransparency = 0.25 + 0.15 * math.sin(clock * 2.4) end
		end
		if sparkles then
			for i, s in ipairs(sparkles:GetChildren()) do
				if s:IsA("ImageLabel") then
					local k = 0.5 + 0.5 * math.sin(clock * 2.2 + i * 1.7)
					s.ImageTransparency = 1 - k
					s.Rotation = (clock * 40 + i * 30) % 360
				end
			end
		end
	end)

	-- GAMEPAD: start on NO (the safe answer); B answers NO -- it is the close button.
	local prevSelected = GuiService.SelectedObject
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = p.no
	end
	ContextActionService:BindActionAtPriority(ACTION_NO, function(_, state)
		if state == Enum.UserInputState.Begin then answer = false end
		return Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 10, Enum.KeyCode.ButtonB)

	-- The gate: the bar fills and the label counts down, so the wait reads as a fuse, not a dead button.
	-- Bails out early if the player answers NO first.
	local delay = tonumber(opts.Delay) or T.Delay
	local gateTween: Tween? = nil
	if gate and gate:IsA("GuiObject") and delay > 0 then
		gateTween = tween(gate, delay, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
	end
	task.spawn(function()
		local remaining = math.ceil(delay)
		while remaining > 0 and answer == nil do
			setText(p.yesLabel, string.format("%s (%d)", baseYes, remaining))
			task.wait(1)
			remaining -= 1
		end
		if answer ~= nil then return end
		setText(p.yesLabel, baseYes)
		p.yes.Active = true
		paint(p.yes, tone, T.ReadyColor)
		-- unlock flourish: the gate fades, a burst flashes, the button pops, a shine sweeps across it
		if gate and gate:IsA("GuiObject") then tween(gate, 0.2, { BackgroundTransparency = 1 }) end
		local burst = p.yes:FindFirstChild("Burst")
		if burst and burst:IsA("ImageLabel") then
			burst.Size = UDim2.fromScale(1.2, 2)
			burst.ImageTransparency = 0.15
			tween(burst, 0.45, { Size = UDim2.fromScale(2, 3.4), ImageTransparency = 1 })
		end
		local ys = popScale(p.yes)
		if ys then
			ys.Scale = 1.12
			tween(ys, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		sweep(p.yes, 0.55)
	end)

	while answer == nil do
		task.wait()
	end

	if gateTween then gateTween:Cancel() end
	for _, c in ipairs(conns) do c:Disconnect() end
	ContextActionService:UnbindAction(ACTION_NO)
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = if prevSelected and prevSelected.Parent then prevSelected else nil
	end
	setText(p.yesLabel, baseYes)
	Sound.play(if answer then Sound.Names.Confirm else Sound.Names.Cancel, "UI")
	if pop then
		tween(pop, T.CloseTime, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local fade = tween(p.background, T.CloseTime, { BackgroundTransparency = 1 })
		local gui, bg = p.gui, p.background
		if fade then
			fade.Completed:Once(function()
				if busy then return end -- a new ask already reopened it
				bg.Visible = false
				gui.Enabled = false
			end)
		end
	else
		Motion.slideOut(p.frame, { gui = p.gui, onComplete = function()
			p.background.Visible = false
		end })
	end
	busy = false
	return answer :: boolean
end

return Confirm
