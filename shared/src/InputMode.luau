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

-- ===== Studio harness (leave OFF) =====
-- B103: attribute `DevForceMode` on THIS ModuleScript ("Gamepad" / "Touch" / "KeyboardMouse"; empty
-- = off) pins the mode, so the console / mobile paths can be exercised from Studio tooling, which can
-- only send pad keys AS keyboard input. Set it on the CLIENT copy during Play. Ships empty.
local function effective(): string
	local f = script:GetAttribute("DevForceMode")
	if f == "Gamepad" or f == "Touch" or f == "KeyboardMouse" then
		return f
	end
	return current :: string
end

-- Changed fires only when the EFFECTIVE mode moves (a real input change, or the harness).
local lastEffective = effective()
local function publish()
	local now = effective()
	if now ~= lastEffective then
		lastEffective = now
		InputMode.Changed:Fire(now)
	end
end

UserInputService.LastInputTypeChanged:Connect(function(t: Enum.UserInputType)
	local m = classify(t)
	if m and m ~= current then
		current = m
		publish()
	end
end)
script:GetAttributeChangedSignal("DevForceMode"):Connect(publish)

function InputMode.Get(): string
	return effective()
end

function InputMode.IsGamepad(): boolean
	return effective() == "Gamepad"
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
	if effective() ~= "Gamepad" and not force then
		return nil
	end
	-- Top-left-most wins; a button marked GamepadDefault beats every unmarked one (B103: and among
	-- several marked ones -- e.g. every cloned card -- the top-left one wins, not a random clone).
	-- B103: a Close/Back/Leave button only wins when there is nothing else (B already backs out), and a
	-- full-screen click-catcher (an Overlay/Dim/Scrim "click outside to close") is never focused --
	-- A on it would just close the menu.
	local cam = workspace.CurrentCamera
	local view = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	local function rank(g: GuiObject): number
		if g:GetAttribute("GamepadDefault") == true then
			return 2
		end
		local n = g.Name
		if string.find(n, "Close") or string.find(n, "Back") or string.find(n, "Leave") then
			return 0
		end
		return 1
	end
	local function better(a: GuiObject, b: GuiObject?): boolean
		if b == nil then
			return true
		end
		local ar, br = rank(a), rank(b)
		if ar ~= br then
			return ar > br
		end
		return a.AbsolutePosition.Y < b.AbsolutePosition.Y - 1
			or (math.abs(a.AbsolutePosition.Y - b.AbsolutePosition.Y) <= 1 and a.AbsolutePosition.X < b.AbsolutePosition.X)
	end
	local best: GuiObject? = nil
	for _, d in ipairs(root:GetDescendants()) do
		if
			d:IsA("GuiButton")
			and d.Selectable
			and shown(d)
			and not (d.AbsoluteSize.X >= view.X * 0.9 and d.AbsoluteSize.Y >= view.Y * 0.9)
			and better(d, best)
		then
			best = d
		end
	end
	if best then
		GuiService.SelectedObject = best
	end
	return best
end

InputMode.IsShown = shown

return InputMode
