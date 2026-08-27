--!strict
-- B34/B36 BOOT MARKER (start). Paired with the `true` at the bottom -- see ScreenBootWatchdog.
-- Two markers, not one, because the watchdog CANNOT read `script.Source` at runtime (that needs
-- plugin/Open Cloud capability, and trying threw on every boot from B34 until B36). The tri-state
-- nil / false / true tells `never instrumented` from `started and hung` from `finished` using only
-- attributes, which a LocalScript can always read.
script:SetAttribute("BootComplete", false)

-- UIKitBootstrap - one script that gives EVERY tagged button the kit's animations.
--
-- HOW TO ADD A BUTTON: tag any GuiButton with the CollectionService tag "UIKitButton"
-- (Studio: select it > Properties/Tag Editor > add "UIKitButton"). It instantly gets the
-- kit hover (stroke + text grow, icon rotate), press animation, and animated gradient - no
-- per-button script. Tags copy to Clones, so cloning a tagged template auto-animates too.
--
-- Tune per button via Attributes (see UIKit.Button for the full list):
--   HoverScale, HoverStrokeMult, HoverIconRotation, PressScale, TweenTime,
--   GradientAnimate, GradientSpeed, GlowStrokeName, StrokeHiddenUntilHover.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Button = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("Button"))

local TAG = "UIKitButton"
local attached: { [Instance]: any } = {}

local function tryAttach(inst: Instance)
	if attached[inst] or not inst:IsA("GuiButton") then return end
	attached[inst] = Button.attach(inst)
end

for _, inst in ipairs(CollectionService:GetTagged(TAG)) do
	tryAttach(inst)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(tryAttach)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(inst)
	local h = attached[inst]
	if h then
		h.destroy()
		attached[inst] = nil
	end
end)

print(string.format("[DIAG] UIKitBootstrap: %d '%s' button(s) at start", #CollectionService:GetTagged(TAG), TAG))


-- ===== B34 BOOT MARKER =====
-- Read by StarterPlayerScripts.ScreenBootWatchdog. Reaching this line means this script finished
-- its top-level boot; NOT reaching it means it is still stuck somewhere above -- almost always a
-- bare `WaitForChild` on an instance a designer renamed or deleted, which NEVER times out.
-- That is how the whole Units screen died silently at B33: no error, no stack, just a screen that
-- never appeared. The marker is what lets the watchdog NAME the stuck script instead of leaving a
-- single 'Infinite yield possible' line to be spotted in a wall of healthy boot output.
script:SetAttribute("BootComplete", true)
