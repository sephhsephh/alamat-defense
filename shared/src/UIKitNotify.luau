--!strict
-- UIKitNotify.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.Notify)
-- Kit CONTROLLER (toast notifications). Promoted to shared canon at B34.
--
-- Any client script:
--   local Notify = require(ReplicatedStorage.Shared.UIKit.Notify)
--   Notify.Error("You can only place 4 Archer")   Notify.Success("Tower placed")
--   Notify.Warning("...")   Notify.Info("...")    Notify.Notify(msg, "Error")
--
-- *** WHY THIS IS SHARED, AND WHY IT WAS NOT UNTIL B34. ***
-- The Game grew this first (Client.UI.NotificationController). At B33 the user copied it into the
-- Lobby and asked for it Lobby-wide, which left TWO copies, in DIFFERENT paths, in NEITHER manifest,
-- and only the Lobby's hardened -- a fork with no drift control, which is precisely what the
-- shared-canon system exists to prevent. Both copies are retired; this is the one.
-- It follows UIKit.Confirm's shape exactly: the MODULE is shared canon, the GUI it drives
-- (StarterGui.Notifications -- Container + CardTemplate) stays PER-PLACE AUTHORED ART, because art
-- cannot be scripted and copying a ScreenGui between Places is a USER action (B26).
--
-- *** THE RULE FOR CALLERS: TOAST EVENTS, LABEL STATE. *** (docs/systems/ui-feedback.md)
-- A card auto-dismisses after Duration. That makes it right for something that HAPPENED -- sold,
-- refused, failed, upgraded -- and WRONG for something that IS TRUE ("this banner is blocked",
-- "this unit cannot ascend"). Erasing a still-current condition off the screen after a few seconds
-- is worse than never having shown it: persistent state belongs on a label that keeps saying it.
--
-- CLIENT MODULE. There is no LocalPlayer on the server, so a server require degrades to print-only
-- rather than erroring -- a misplaced require should cost a toast, never a boot.
--
-- Cards pop in (UIScale), stack in the GUI's UIListLayout so they NEVER overlap, cap at MaxCards,
-- then fade and destroy themselves. Colour is coded by type. All visuals live in the authored GUI;
-- this module only clones CardTemplate and animates it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local NotifyKit = {}

local COLORS: { [string]: Color3 } = {
	Error = Color3.fromRGB(255, 90, 90),
	Success = Color3.fromRGB(110, 225, 140),
	Warning = Color3.fromRGB(255, 190, 70),
	Info = Color3.fromRGB(110, 190, 255),
}
NotifyKit.Colors = COLORS

-- The ONE place to retune how toasts feel, same reasoning as Motion.Tuning.
NotifyKit.Tuning = {
	Duration = 3.5,   -- seconds a card stays before dismissing
	MaxCards = 5,     -- older cards are dismissed early past this
	PopTime = 0.28,
	FadeTime = 0.25,
	PopFrom = 0.7,
	FadeToScale = 0.85,
}

-- ===== resolution =====
-- Bounded waits, never bare ones. This module is required by SCREEN CONTROLLERS at boot, so a bare
-- WaitForChild here would stop being "no toasts" and become "that screen never finishes booting" --
-- exactly how the Lobby's Units screen died at B33. If the authored GUI is absent, every call
-- degrades to a printed line and the CALLER CARRIES ON.
local container: Instance? = nil
local template: Instance? = nil
local disabled = true

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
end
resolve()

local seq = 0

local function dismiss(card: Instance?)
	if card == nil or card.Parent == nil then
		return
	end
	local frame = card :: Frame
	-- An attribute, not a table, so a card dismissed twice (cap eviction racing the timer) is a
	-- no-op rather than a double-destroy.
	if frame:GetAttribute("Dismissing") then
		return
	end
	frame:SetAttribute("Dismissing", true)

	local info = TweenInfo.new(NotifyKit.Tuning.FadeTime)
	TweenService:Create(frame, info, { BackgroundTransparency = 1 }):Play()
	for _, d in ipairs(frame:GetDescendants()) do
		if d:IsA("TextLabel") then
			TweenService:Create(d, info, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, info, { Transparency = 1 }):Play()
		end
	end
	local scale = frame:FindFirstChildWhichIsA("UIScale")
	if scale then
		TweenService:Create(scale, info, { Scale = NotifyKit.Tuning.FadeToScale }):Play()
	end
	task.delay(NotifyKit.Tuning.FadeTime + 0.03, function()
		if frame and frame.Parent then
			frame:Destroy()
		end
	end)
end

function NotifyKit.Notify(message: string, notifType: string?): Instance?
	local kind = notifType or "Info"
	-- Degraded mode still SAYS the thing, on the one channel that cannot be deleted.
	if disabled or container == nil or template == nil then
		print("[Notify:" .. kind .. "] " .. message)
		return nil
	end
	local color = COLORS[kind] or COLORS.Info

	seq += 1
	local card = (template :: Instance):Clone() :: any
	card.Name = "Notif"
	card.LayoutOrder = seq
	card.Visible = true
	card.Message.Text = message
	card.Message.TextColor3 = color
	card.Accent.BackgroundColor3 = color
	local stroke = card:FindFirstChild("AccentStroke")
	if stroke then
		(stroke :: UIStroke).Color = color
	end
	card.Parent = container

	local scale = card:FindFirstChildWhichIsA("UIScale")
	if scale then
		scale.Scale = NotifyKit.Tuning.PopFrom
		TweenService:Create(scale,
			TweenInfo.new(NotifyKit.Tuning.PopTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Scale = 1 }):Play()
	end

	-- Keep the stack bounded: dismiss the oldest SURVIVING card past the cap. Counting only cards
	-- that are not already dismissing is what stops a burst from evicting cards twice and leaving
	-- the stack shorter than the cap.
	local live = {}
	for _, c in ipairs((container :: Instance):GetChildren()) do
		if c:IsA("Frame") and not c:GetAttribute("Dismissing") then
			table.insert(live, c)
		end
	end
	if #live > NotifyKit.Tuning.MaxCards then
		table.sort(live, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		dismiss(live[1])
	end

	task.delay(NotifyKit.Tuning.Duration, function()
		dismiss(card)
	end)

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
