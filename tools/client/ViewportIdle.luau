--!strict
-- ViewportIdle (B157, both Places; StarterPlayerScripts.Client.UI) -- user: "play their idle animation anytime they are
-- inside a viewport frame. all that has viewport frame and previous characters, play their idle anim, default anim if
-- none." ONE watcher instead of a patch per screen: every rig that lands in a WorldModel inside a ViewportFrame under
-- PlayerGui (unit cards, the Hero Hall, hover cards, summon / index / evolve / ascension / starter / party / dialogue
-- portraits...) gets `UnitCard.playIdle` -- its own `IdleAnim` attribute, else the stock R15 idle.
-- A rig that is already animating (its screen played the idle itself) is left alone, so nothing double-plays.
-- A rig needs a Humanoid or an AnimationController, and a WorldModel parent (a model straight in a ViewportFrame
-- cannot animate; those are reported once with [DIAG] so the screen can get a WorldModel).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UnitCard = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("UnitCard")) :: any

local SETTLE = 0.35 -- seconds: let the owning screen play its own idle first

local function animatorOf(model: Model): Animator?
	local h = model:FindFirstChildOfClass("Humanoid")
	local host: Instance? = h or model:FindFirstChildOfClass("AnimationController")
	return host and host:FindFirstChildOfClass("Animator") or nil
end

local function isRig(model: Model): boolean
	return model:FindFirstChildOfClass("Humanoid") ~= nil or model:FindFirstChildOfClass("AnimationController") ~= nil
end

local reported: { [string]: boolean } = {}
local function consider(model: Instance)
	if not model:IsA("Model") or model:IsA("WorldModel") then return end
	local vf = model:FindFirstAncestorWhichIsA("ViewportFrame")
	if not vf then return end
	task.delay(SETTLE, function()
		if not model.Parent or not model:IsA("Model") then return end
		local m = model :: Model
		if not isRig(m) then return end
		local parent = m.Parent
		if not (parent and parent:IsA("WorldModel")) then
			-- a nested part of a rig (accessory model, a sub-model) is not a rig of its own
			if parent and parent:IsA("Model") and isRig(parent :: Model) then return end
			local key = vf:GetFullName()
			if not reported[key] then
				reported[key] = true
				print("[DIAG] ViewportIdle: a rig sits straight in " .. key .. " (no WorldModel) -- it cannot animate")
			end
			return
		end
		local a = animatorOf(m)
		if a and #a:GetPlayingAnimationTracks() > 0 then return end -- its screen already animates it
		pcall(UnitCard.playIdle, m)
	end)
end

playerGui.DescendantAdded:Connect(consider)
for _, d in ipairs(playerGui:GetDescendants()) do consider(d) end
print("[DIAG] ViewportIdle ready: every rig in a viewport plays its idle (IdleAnim, else the stock idle).")
