--!strict
-- InputMode (SHARED CANON -- deploy path ReplicatedStorage.Shared.InputMode)
-- Added B97. Client-only helper: which device the player is USING RIGHT NOW, so every screen can
-- adapt without its own copy of this logic.
--
-- PLATFORM RULE (user, 2026-09-27): every feature ships for PC + console + mobile; PC is the main
-- platform. Read the mode from HERE -- never from a TouchEnabled / GamepadEnabled check, which only
-- says a device EXISTS (a laptop with a touchscreen is not a phone; a PC with a pad plugged in may be
-- using the mouse).
--
--   InputMode.Get()        -> "KeyboardMouse" | "Gamepad" | "Touch"   (last input wins)
--   InputMode.IsGamepad()  -> boolean
--   InputMode.Changed      -> Signal (newMode)
--   InputMode.FocusFirst(root, force?) -> on a gamepad (or always, with force), select the first
--                                  visible button under `root` (a button with attribute
--                                  GamepadDefault = true wins). Returns it.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Signal = require(ReplicatedStorage.Shared.Signal)

local InputMode = {}
InputMode.Changed = Signal.new()

local GAMEPAD = {
	[Enum.UserInputType.Gamepad1] = true, [Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true, [Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true, [Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true, [Enum.UserInputType.Gamepad8] = true,
}

local function classify(t: Enum.UserInputType): string?
	if GAMEPAD[t] then
		return "Gamepad"
	elseif t == Enum.UserInputType.Touch then
		return "Touch"
	elseif t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.MouseButton2 or t == Enum.UserInputType.MouseButton3
		or t == Enum.UserInputType.MouseMovement or t == Enum.UserInputType.MouseWheel
	then
		return "KeyboardMouse"
	end
	return nil -- focus / accelerometer etc. change nothing
end

local current = classify(UserInputService:GetLastInputType())
if current == nil then
	-- No input yet: a phone with no keyboard starts in Touch, everything else in KeyboardMouse.
	current = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "Touch" else "KeyboardMouse"
end

UserInputService.LastInputTypeChanged:Connect(function(t: Enum.UserInputType)
	local m = classify(t)
	if m and m ~= current then
		current = m
		InputMode.Changed:Fire(m)
	end
end)

function InputMode.Get(): string
	return current :: string
end

function InputMode.IsGamepad(): boolean
	return current == "Gamepad"
end

local function shown(g: GuiObject): boolean
	local node: Instance? = g
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	if node and node:IsA("ScreenGui") and not node.Enabled then
		return false
	end
	return g.AbsoluteSize.X > 0 and g.AbsoluteSize.Y > 0
end

function InputMode.FocusFirst(root: Instance, force: boolean?): GuiObject?
	if current ~= "Gamepad" and not force then
		return nil
	end
	local best: GuiObject? = nil
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("GuiButton") and d.Selectable and shown(d) then
			if d:GetAttribute("GamepadDefault") == true then
				best = d
				break
			end
			if best == nil
				or d.AbsolutePosition.Y < best.AbsolutePosition.Y - 1
				or (math.abs(d.AbsolutePosition.Y - best.AbsolutePosition.Y) <= 1 and d.AbsolutePosition.X < best.AbsolutePosition.X)
			then
				best = d
			end
		end
	end
	if best then
		GuiService.SelectedObject = best
	end
	return best
end

InputMode.IsShown = shown

return InputMode
