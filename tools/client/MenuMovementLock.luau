--!strict
-- MenuMovementLock (B157, both Places) -- user: "disable movement of player while on events, units ui, and play ui"
-- + "while in play ui, some ui in the lobby can still be clicked".
-- While any of the LOCK screens is open (its ScreenGui Enabled): the PlayerModule controls are off (walk + jump, every
-- device), the player attribute `MenuLocked` is true (the shared MovementController treats it like typing: no
-- sprint / dash / air jump) and ProximityPrompts are hidden, so a world prompt can't be triggered through the menu.
-- Add a screen = add its ScreenGui name below (or set the comma list attribute `ExtraScreens` on this script).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LOCK_SCREENS = { "UnitsGUI", "PlayGUI", "EventsGUI" }

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local controls: any = nil
local function getControls(): any
	if controls then return controls end
	local ps = player:FindFirstChild("PlayerScripts")
	local pm = ps and ps:FindFirstChild("PlayerModule")
	if pm then
		local ok, mod = pcall(require, pm)
		if ok and mod and mod.GetControls then controls = mod:GetControls() end
	end
	return controls
end

local function screenNames(): { string }
	local list = table.clone(LOCK_SCREENS)
	local extra = script:GetAttribute("ExtraScreens")
	if type(extra) == "string" then
		for n in string.gmatch(extra, "[^,%s]+") do table.insert(list, n) end
	end
	return list
end

local locked = false
local function apply()
	local any = false
	for _, n in ipairs(screenNames()) do
		local g = playerGui:FindFirstChild(n)
		if g and g:IsA("ScreenGui") and g.Enabled then any = true break end
	end
	if any == locked then return end
	locked = any
	player:SetAttribute("MenuLocked", any)
	local c = getControls()
	if c then
		if any then c:Disable() else c:Enable() end
	end
	ProximityPromptService.Enabled = not any
	local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if h and any then h:Move(Vector3.zero) end -- stop the stride already in progress
end

local watched: { [Instance]: boolean } = {}
local function watch(g: Instance)
	if watched[g] or not g:IsA("ScreenGui") then return end
	if not table.find(screenNames(), g.Name) then return end
	watched[g] = true
	g:GetPropertyChangedSignal("Enabled"):Connect(apply)
	g.AncestryChanged:Connect(function()
		if not g:IsDescendantOf(playerGui) then watched[g] = nil apply() end
	end)
	apply()
end
for _, g in ipairs(playerGui:GetChildren()) do watch(g) end
playerGui.ChildAdded:Connect(watch)
-- a respawn rebuilds the controls' character hooks: re-assert the lock on the new character
player.CharacterAdded:Connect(function()
	task.defer(function()
		local was = locked
		locked = not was
		apply()
	end)
end)
apply()
print("[DIAG] MenuMovementLock ready (" .. table.concat(screenNames(), ", ") .. "): no walk / jump / dash / prompts while open.")
