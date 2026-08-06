--!strict
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
