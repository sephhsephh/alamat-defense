--!strict
-- ViewportIdle (B157, both Places; StarterPlayerScripts.Client.UI) -- user: "play their idle animation anytime they are
-- inside a viewport frame. all that has viewport frame and previous characters, play their idle anim, default anim if
-- none." ONE watcher instead of a patch per screen: every rig that lands in a WorldModel inside a ViewportFrame under
-- PlayerGui (unit cards, the Hero Hall, hover cards, summon / index / evolve / ascension / starter / party / dialogue
-- portraits...) gets `UnitCard.playIdle` -- the idle in the unit's CONFIG (B161), else the stock R15 idle.
-- A rig that is already animating (its screen played the idle itself) is left alone, so nothing double-plays.
-- A rig needs a Humanoid or an AnimationController, and a WorldModel parent (a model straight in a ViewportFrame
-- cannot animate; those are reported once with [DIAG] so the screen can get a WorldModel).
--
-- B161 (user: "fix the stage display unit lagging ... the unit roster panel can be lagging its okay. the stage
-- viewportframe should be smooth"): Roblox re-renders only so many CHANGING ViewportFrames per frame, so 40+ animating
-- roster cards starved the hall's stage. A rig in a LIST card (its ViewportFrame sits in a ScrollingFrame -- the
-- roster, Index, inventory...) now steps its idle LIST_FPS times a second instead of every frame, and not at all
-- while scrolled out of view. Single portraits (the stage, hotbar, hover cards, reveals) keep full-rate motion.
-- A ViewportFrame can override: attribute `IdleFps` (number; 0 = full rate) -- set it in Studio.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local UnitCard = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"):WaitForChild("UnitCard")) :: any

local SETTLE = 0.35 -- seconds: let the owning screen play its own idle first
local LIST_FPS = 8  -- idle steps per second for a rig in a list card

local function animatorOf(model: Model): Animator?
	local h = model:FindFirstChildOfClass("Humanoid")
	local host: Instance? = h or model:FindFirstChildOfClass("AnimationController")
	return host and host:FindFirstChildOfClass("Animator") or nil
end

local function isRig(model: Model): boolean
	return model:FindFirstChildOfClass("Humanoid") ~= nil or model:FindFirstChildOfClass("AnimationController") ~= nil
end

-- ===== low-rate stepping for list cards =====
type Stepped = { model: Model, vf: ViewportFrame, list: GuiObject?, fps: number, acc: number }
local stepped: { Stepped } = {}

local function rateFor(vf: ViewportFrame): (number, GuiObject?)
	local list = vf:FindFirstAncestorWhichIsA("ScrollingFrame")
	local override = vf:GetAttribute("IdleFps")
	if type(override) == "number" then return override, list end
	return if list then LIST_FPS else 0, list
end

-- on screen = inside the screen and inside the scrolling list's window
local function onScreen(vf: ViewportFrame, list: GuiObject?): boolean
	local p, s = vf.AbsolutePosition, vf.AbsoluteSize
	if s.X <= 0 or s.Y <= 0 then return false end
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	if p.X > vp.X or p.Y > vp.Y or p.X + s.X < 0 or p.Y + s.Y < 0 then return false end
	if list then
		local lp, ls = list.AbsolutePosition, list.AbsoluteSize
		if p.X > lp.X + ls.X or p.Y > lp.Y + ls.Y or p.X + s.X < lp.X or p.Y + s.Y < lp.Y then return false end
	end
	return true
end

RunService.Heartbeat:Connect(function(dt)
	for i = #stepped, 1, -1 do
		local e = stepped[i]
		if not e.model.Parent or not e.vf.Parent then
			table.remove(stepped, i)
			continue
		end
		local a = animatorOf(e.model)
		if not a then continue end
		local tracks = a:GetPlayingAnimationTracks()
		for _, t in ipairs(tracks) do
			if t.Speed ~= 0 then t:AdjustSpeed(0) end -- the engine stops advancing it; we step it below
		end
		e.acc += dt
		if e.acc >= 1 / e.fps then
			if onScreen(e.vf, e.list) then
				for _, t in ipairs(tracks) do
					if t.Length > 0 then t.TimePosition = (t.TimePosition + e.acc) % t.Length end
				end
			end
			e.acc = 0
		end
	end
end)

local function throttle(m: Model, vf: ViewportFrame)
	local fps, list = rateFor(vf)
	if fps <= 0 then return end
	for _, e in ipairs(stepped) do if e.model == m then return end end
	table.insert(stepped, { model = m, vf = vf, list = list, fps = fps, acc = math.random() / fps })
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
		if not (a and #a:GetPlayingAnimationTracks() > 0) then -- its screen may already animate it
			pcall(UnitCard.playIdle, m)
		end
		throttle(m, vf)
	end)
end

playerGui.DescendantAdded:Connect(consider)
for _, d in ipairs(playerGui:GetDescendants()) do consider(d) end
print(string.format("[DIAG] ViewportIdle ready: every rig in a viewport plays its config idle (else the stock idle); list cards step at %d fps, portraits full rate.", LIST_FPS))
