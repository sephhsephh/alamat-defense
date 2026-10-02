--!strict
-- UIKitNotify.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.Notify)
-- Kit CONTROLLER (toast notifications). Promoted to shared canon at B34. Re-skinned B108 pt13d.
--
-- Any client script:
--   local Notify = require(ReplicatedStorage.Shared.UIKit.Notify)
--   Notify.Error("You can only place 4 Archer")   Notify.Success("Tower placed")
--   Notify.Warning("...")   Notify.Info("...")    Notify.Notify(msg, "Error")
--
-- The MODULE is shared canon; the GUI it drives (StarterGui.Notifications -- Container + CardTemplate)
-- is PER-PLACE AUTHORED ART, copied between Places by the USER (B26), same shape as UIKit.Confirm.
--
-- *** THE RULE FOR CALLERS: TOAST EVENTS, LABEL STATE. *** (docs/systems/ui-feedback.md)
-- A card auto-dismisses, so it is right for something that HAPPENED and wrong for something that IS TRUE.
--
-- B108 pt13d (user: "improve the looks of the notification system"):
--   * NEWEST ON TOP, older cards slide down; cap MaxCards, oldest leaves first.
--   * Type badge (glyph), type title, white message, colour wash + animated accent stroke, and a TIMER
--     BAR that drains over the card's life. Hovering a card PAUSES its timer; clicking/tapping it
--     dismisses it early (a toast is not a screen -- the close-button rule is for screens).
--   * DEDUPE: the same message + type while its card is still up bumps an "x2, x3..." counter and
--     restarts the timer instead of stacking copies (spam-clicking a refused button used to fill the stack).
--   * Enter: pop + tilt + a light sheen sweep, the badge spins in; Error cards shake. Exit: shrink + fade.
--   * Optional sound per type through UIKit.Sound (silent if the slot is empty).
--   * BACKWARD COMPATIBLE with the pre-pt13d CardTemplate (Message + Accent + AccentStroke only): every new
--     part is looked up optionally, so a Place still holding the old art keeps working unchanged.
--
-- CLIENT MODULE. A server require degrades to print-only rather than erroring.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local NotifyKit = {}

local COLORS: { [string]: Color3 } = {
	Error = Color3.fromRGB(255, 90, 100),
	Success = Color3.fromRGB(110, 230, 140),
	Warning = Color3.fromRGB(255, 196, 70),
	Info = Color3.fromRGB(110, 190, 255),
}
NotifyKit.Colors = COLORS

local GLYPHS: { [string]: string } = { Error = "X", Success = "\u{2713}", Warning = "!", Info = "i" }
local TITLES: { [string]: string } = { Error = "ERROR", Success = "SUCCESS", Warning = "WARNING", Info = "INFO" }
local SOUNDS: { [string]: string } = { Error = "Error", Success = "Confirm", Warning = "Error", Info = "Click" }

-- The ONE place to retune how toasts feel, same reasoning as Motion.Tuning.
NotifyKit.Tuning = {
	Duration = 3.5,   -- seconds a card stays (each dedupe bump restarts it)
	MaxCards = 5,     -- older cards are dismissed early past this
	PopTime = 0.32,
	FadeTime = 0.22,
	PopFrom = 0.6,
	FadeToScale = 0.8,
	EnterTilt = -5,
	SheenTime = 0.6,
	PlaySounds = true,
}

-- ===== resolution (bounded waits: a missing GUI must cost a toast, never a screen's boot) =====
local container: Instance? = nil
local template: Instance? = nil
local disabled = true
local SoundKit: any = nil

local function resolve()
	if RunService:IsServer() then
		warn("[UIKit.Notify] required on the SERVER -- toasts are print-only there (no LocalPlayer).")
		return
	end
	local player = Players.LocalPlayer
	if player == nil then
		warn("[UIKit.Notify] no LocalPlayer -- toasts are print-only.")
		return
	end
	local playerGui = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 10)
	local gui = playerGui and (playerGui:FindFirstChild("Notifications")
		or playerGui:WaitForChild("Notifications", 10))
	container = gui and (gui:FindFirstChild("Container") or gui:WaitForChild("Container", 5))
	template = gui and (gui:FindFirstChild("CardTemplate") or gui:WaitForChild("CardTemplate", 5))
	if gui == nil or container == nil or template == nil then
		warn("[UIKit.Notify] StarterGui.Notifications (or its Container/CardTemplate) is missing in this"
			.. " Place -- toasts are DISABLED and messages will print instead. No screen is affected.")
		return
	end
	disabled = false
	local parent = script.Parent
	local sm = parent and parent:FindFirstChild("Sound")
	if sm and sm:IsA("ModuleScript") then
		local ok, mod = pcall(require, sm)
		if ok then SoundKit = mod end
	end
end
resolve()

local function tween(o: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function find(card: Instance, name: string): any
	return card:FindFirstChild(name)
end

local seq = 0
-- live card -> its timer state
type Timer = { left: number, total: number, paused: boolean }
local timers: { [Instance]: Timer } = {}

local function dismiss(card: Instance?)
	if card == nil or card.Parent == nil then
		return
	end
	local frame = card :: Frame
	if frame:GetAttribute("Dismissing") then
		return
	end
	frame:SetAttribute("Dismissing", true)
	timers[frame] = nil

	local t = NotifyKit.Tuning.FadeTime
	tween(frame, t, { BackgroundTransparency = 1, Rotation = 3 })
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") then
			tween(d, t, { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 })
		elseif d:IsA("Frame") then
			tween(d, t, { BackgroundTransparency = 1 })
		elseif d:IsA("UIStroke") then
			tween(d, t, { Transparency = 1 })
		end
	end
	local scale = frame:FindFirstChild("UIScale")
	if scale and scale:IsA("UIScale") then
		tween(scale, t, { Scale = NotifyKit.Tuning.FadeToScale }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	task.delay(t + 0.03, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

-- One heartbeat drives every timer bar, so a dozen cards cost one connection.
local timerConn: RBXScriptConnection? = nil
local function ensureTimerLoop()
	if timerConn then return end
	timerConn = RunService.Heartbeat:Connect(function(dt)
		local any = false
		for card, tm in pairs(timers) do
			any = true
			if card.Parent == nil then
				timers[card] = nil
			elseif not tm.paused then
				tm.left -= dt
				local bar = find(card, "TimerBar")
				local fill = bar and find(bar, "Fill")
				if fill then
					fill.Size = UDim2.fromScale(math.clamp(tm.left / tm.total, 0, 1), 1)
				end
				if tm.left <= 0 then
					dismiss(card)
				end
			end
		end
		if not any and timerConn then
			timerConn:Disconnect()
			timerConn = nil
		end
	end)
end

local function playEnter(card: Frame, kind: string)
	local scale = card:FindFirstChild("UIScale")
	if scale and scale:IsA("UIScale") then
		scale.Scale = NotifyKit.Tuning.PopFrom
		tween(scale, NotifyKit.Tuning.PopTime, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	card.Rotation = NotifyKit.Tuning.EnterTilt
	tween(card, NotifyKit.Tuning.PopTime, { Rotation = 0 }, Enum.EasingStyle.Back)
	local badge = find(card, "IconBadge")
	if badge then
		badge.Rotation = -180
		tween(badge, 0.45, { Rotation = 0 }, Enum.EasingStyle.Back)
		local bs = badge:FindFirstChild("UIScale")
		if bs and bs:IsA("UIScale") then
			bs.Scale = 0.2
			tween(bs, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	local sheen = find(card, "Sheen")
	if sheen then
		sheen.Position = UDim2.fromScale(-0.2, 0.5)
		tween(sheen, NotifyKit.Tuning.SheenTime, { Position = UDim2.fromScale(1.2, 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	end
	if kind == "Error" then
		task.spawn(function()
			for i = 1, 6 do
				card.Rotation = (if i % 2 == 0 then 1 else -1) * (4 - i * 0.6)
				task.wait(0.035)
			end
			card.Rotation = 0
		end)
	end
	local grad = find(card, "AccentStroke")
	grad = grad and grad:FindFirstChild("AccentGradient")
	if grad and grad:IsA("UIGradient") then
		tween(grad, 1.2, { Rotation = grad.Rotation + 360 }, Enum.EasingStyle.Linear)
	end
end

local function paint(card: any, kind: string, message: string)
	local color = COLORS[kind] or COLORS.Info
	card.Message.Text = message
	-- The new art carries a Kind title: the message stays white and the TYPE colour goes on the chrome.
	-- The old art had no title, so its message keeps the type colour.
	local kindLabel = find(card, "Kind")
	if kindLabel then
		kindLabel.Text = TITLES[kind] or string.upper(kind)
		kindLabel.TextColor3 = color
	else
		card.Message.TextColor3 = color
	end
	local accent = find(card, "Accent")
	if accent then accent.BackgroundColor3 = color end
	local wash = find(card, "Wash")
	if wash then wash.BackgroundColor3 = color end
	local badge = find(card, "IconBadge")
	if badge then
		badge.BackgroundColor3 = color
		local glyph = find(badge, "Glyph")
		if glyph then glyph.Text = GLYPHS[kind] or "i" end
	end
	local bar = find(card, "TimerBar")
	local fill = bar and find(bar, "Fill")
	if fill then fill.BackgroundColor3 = color end
	local stroke = find(card, "AccentStroke")
	if stroke then
		stroke.Color = color
		local g = find(stroke, "AccentGradient")
		if g then
			g.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, color),
				ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, color),
			})
			-- the gradient tints the stroke's own colour, so keep the base white under it
			stroke.Color = Color3.new(1, 1, 1)
		end
	end
end

local function sound(kind: string)
	if SoundKit and NotifyKit.Tuning.PlaySounds then
		pcall(SoundKit.play, SOUNDS[kind] or "Click", "UI")
	end
end

-- The same message + type is already up: bump its counter and restart its clock.
local function bump(card: Frame)
	local n = (tonumber(card:GetAttribute("Count")) or 1) + 1
	card:SetAttribute("Count", n)
	local cnt = find(card, "Count")
	if cnt then
		cnt.Text = "x" .. n
		cnt.Visible = true
		local cs = cnt:FindFirstChild("UIScale")
		if cs and cs:IsA("UIScale") then
			cs.Scale = 1.6
			tween(cs, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	end
	local scale = card:FindFirstChild("UIScale")
	if scale and scale:IsA("UIScale") then
		scale.Scale = 1.06
		tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
	end
	local tm = timers[card]
	if tm then
		tm.left = tm.total
	end
end

function NotifyKit.Notify(message: string, notifType: string?): Instance?
	local kind = notifType or "Info"
	if disabled or container == nil or template == nil then
		print("[Notify:" .. kind .. "] " .. message)
		return nil
	end

	for _, c in ipairs((container :: Instance):GetChildren()) do
		if c:IsA("Frame") and not c:GetAttribute("Dismissing")
			and c:GetAttribute("Msg") == message and c:GetAttribute("Kind") == kind then
			bump(c)
			sound(kind)
			return c
		end
	end

	seq += 1
	local card = (template :: Instance):Clone() :: any
	card.Name = "Notif"
	card.LayoutOrder = -seq -- newest on top
	card.Visible = true
	card:SetAttribute("Msg", message)
	card:SetAttribute("Kind", kind)
	card:SetAttribute("Count", 1)
	paint(card, kind, message)
	card.Parent = container

	local total = NotifyKit.Tuning.Duration
	timers[card] = { left = total, total = total, paused = false }
	ensureTimerLoop()

	-- hover pauses, click/tap dismisses (only the new art is Active; the old art ignores input)
	if card:IsA("GuiObject") then
		card.MouseEnter:Connect(function()
			local tm = timers[card]
			if tm then tm.paused = true end
		end)
		card.MouseLeave:Connect(function()
			local tm = timers[card]
			if tm then tm.paused = false end
		end)
		card.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dismiss(card)
			end
		end)
	end

	playEnter(card, kind)
	sound(kind)

	-- Keep the stack bounded: dismiss the oldest SURVIVING card past the cap.
	local live = {}
	for _, c in ipairs((container :: Instance):GetChildren()) do
		if c:IsA("Frame") and not c:GetAttribute("Dismissing") then
			table.insert(live, c)
		end
	end
	if #live > NotifyKit.Tuning.MaxCards then
		table.sort(live, function(a, b)
			return a.LayoutOrder > b.LayoutOrder -- most negative = newest; the largest is the oldest
		end)
		dismiss(live[1])
	end

	return card
end

function NotifyKit.Error(m: string): Instance?
	return NotifyKit.Notify(m, "Error")
end
function NotifyKit.Success(m: string): Instance?
	return NotifyKit.Notify(m, "Success")
end
function NotifyKit.Warning(m: string): Instance?
	return NotifyKit.Notify(m, "Warning")
end
function NotifyKit.Info(m: string): Instance?
	return NotifyKit.Notify(m, "Info")
end

-- Diagnostic, same spirit as Sound.report(): says whether toasts will actually appear in this Place.
function NotifyKit.IsAvailable(): boolean
	return not disabled
end

return NotifyKit
