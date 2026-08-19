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
--   if Confirm.ask({ Title = "SELL UNITS", Text = "Sell 3 units for 170 Silver?" }) then ... end
-- It returns a boolean, so a caller reads top-to-bottom instead of splitting itself across two
-- callbacks. It YIELDS, so callers must already be on their own thread -- every screen in this
-- project does its remote work inside `task.spawn`, so that costs them nothing.
--
-- ===== THE TWO-SECOND GATE (user's spec) =====
-- `YesButton` starts GREY and NOT clickable, counts down in its own label, then turns GREEN and
-- becomes clickable. That is a deliberate speed bump on irreversible actions -- B31's sell path
-- destroys units permanently, and the whole point is that the player cannot muscle-memory their
-- way through it. `NoButton` is live IMMEDIATELY: backing out is never the dangerous direction.
--
-- Instance shape (resolved fresh on every ask, because the ScreenGui is ResetOnSpawn):
--   ConfirmationPopupUI (ScreenGui)
--   `-- Background (Frame)                 the scrim
--        `-- ConfirmationFrame (ImageLabel)  slides in
--             `-- Main (Frame)
--                  |-- ConfirmationLabel (TextLabel)   the title
--                  |-- ConfirmationText (TextLabel)    the question
--                  |-- YesButton (ImageButton) > ButtonText
--                  `-- NoButton  (ImageButton) > ButtonText
-- Every part is optional and degrades with a single warn -- a missing label must not be able to
-- stop a player answering a dialog that is already on screen.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

Confirm.Tuning = {
	-- The user's spec is "grey, then green". Both live here so a re-skin is one edit, not a hunt.
	LockedColor = Color3.fromRGB(92, 92, 100),
	ReadyColor = Color3.fromRGB(76, 175, 80),
	-- Seconds the Yes button stays locked. Callers may override per ask.
	Delay = 2,
	ColorTime = 0.25,
}

local GUI_NAME = "ConfirmationPopupUI"

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
			" in this Place -- copy the ScreenGui across from the Lobby's StarterGui. Confirms will auto-answer NO.")
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

-- ImageButton art is tinted through ImageColor3; a plain TextButton has no image to tint, so its
-- BackgroundColor3 is used instead. Handling both means the dialog can be re-skinned either way.
local function tint(btn: GuiButton, colour: Color3, instant: boolean?)
	local prop = if btn:IsA("ImageButton") then "ImageColor3" else "BackgroundColor3"
	if instant then
		(btn :: any)[prop] = colour
		return
	end
	TweenService:Create(btn, TweenInfo.new(Confirm.Tuning.ColorTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ [prop] = colour }):Play()
end

-- opts = { Title, Text, YesText, NoText, Delay }
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

	setText(p.title, opts.Title or "CONFIRMATION")
	setText(p.text, opts.Text or "Are you sure?")
	local baseYes = if p.yesLabel then p.yesLabel.Text else "YES"
	if opts.YesText ~= nil then baseYes = tostring(opts.YesText) end
	local noLabel = p.no:FindFirstChild("ButtonText")
	if opts.NoText ~= nil and noLabel and noLabel:IsA("TextLabel") then noLabel.Text = tostring(opts.NoText) end

	-- LOCKED state, applied INSTANTLY: a Yes that fades in from green would be clickable-looking
	-- during the very window the gate exists to protect.
	p.yes.Active = false
	tint(p.yes, Confirm.Tuning.LockedColor, true)
	p.no.Active = true

	conns[#conns + 1] = p.yes.Activated:Connect(function()
		if not p.yes.Active then return end -- belt and braces; Activated should not fire anyway
		answer = true
	end)
	conns[#conns + 1] = p.no.Activated:Connect(function()
		answer = false
	end)

	p.background.Visible = true
	Motion.slideIn(p.frame, { gui = p.gui })
	Sound.play(Sound.Names.Open, "UI")

	-- Countdown in the button's own label, so the wait is legible instead of reading as a dead
	-- button. Bails out early if the player answers NO first.
	local delay = tonumber(opts.Delay) or Confirm.Tuning.Delay
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
		tint(p.yes, Confirm.Tuning.ReadyColor)
	end)

	while answer == nil do
		task.wait()
	end

	for _, c in ipairs(conns) do c:Disconnect() end
	setText(p.yesLabel, baseYes)
	Sound.play(if answer then Sound.Names.Confirm else Sound.Names.Cancel, "UI")
	Motion.slideOut(p.frame, { gui = p.gui, onComplete = function()
		p.background.Visible = false
	end })
	busy = false
	return answer :: boolean
end

return Confirm
