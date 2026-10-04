--!strict
-- Keybinds (SHARED CANON, B112 -- deploy path StarterPlayer.StarterPlayerScripts.Client.Settings.Keybinds,
-- next to ClientSettings in BOTH Places). THE one place a script asks "which key does <action> use?".
--
-- ===== WHAT IS REMAPPABLE =====
-- KEYBOARD keys only. Each action is a `Key_<Action>` setting in SettingsConfig (Type "key"): an
-- Enum.KeyCode NAME, or "" = unbound. Gamepad buttons and the mobile touch buttons do NOT change -- console
-- players keep the fixed A/B/X/Y/L1/R1 layout every menu already teaches. Defaults are the keys that were
-- hard-coded before B112.
--
-- ===== HOW A SCRIPT USES IT =====
--   if Keybinds.Is(input, "SellUnit") then ... end          -- inside an existing InputBegan handler
--   Keybinds.Bind("OpenQuests", function() ... end)        -- a standalone hotkey (gameProcessed skipped)
--   Keybinds.Watch(function() rebind() end)                -- re-run when any key changes (CAS users)
--   Keybinds.Get("Dash")  -> Enum.KeyCode?    Keybinds.Label(code) -> "L Shift"
-- Never write `Enum.KeyCode.X` for a remappable action again -- that is how a rebind silently half-works.
--
-- ===== CLASHES =====
-- A rebind clears any OTHER action of the same `Group` (Global / Placement / Selected) whose Scope overlaps,
-- that already held the key -- one save, via ClientSettings.SetMany. Different Groups may share a key on
-- purpose (E = Place Unit while placing, Upgrade Unit while a unit is selected).
--
-- ===== CAPTURE =====
-- While the settings screen is waiting for "press a key", `Keybinds.Capturing` is true and Is()/Bind()
-- report nothing, so pressing F to bind it does not also open the Unit Manager.
--
-- The Interact key is applied here too: every ProximityPrompt whose authored KeyboardKeyCode was E follows
-- `Key_Interact` (its authored key is remembered in the attribute AD_AuthoredKey).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)
local ClientSettings = require(script.Parent:WaitForChild("ClientSettings"))

local Keybinds = {}
Keybinds.Capturing = false

local PREFIX = "Key_"

-- Short names for the keys whose enum names read badly on a small button.
local LABELS: { [string]: string } = {
	LeftShift = "L Shift", RightShift = "R Shift", LeftControl = "L Ctrl", RightControl = "R Ctrl",
	LeftAlt = "L Alt", RightAlt = "R Alt", Backquote = "`", Space = "Space", Backspace = "Bksp",
	CapsLock = "Caps", Zero = "0", One = "1", Two = "2", Three = "3", Four = "4", Five = "5", Six = "6",
	Seven = "7", Eight = "8", Nine = "9", Minus = "-", Equals = "=", LeftBracket = "[", RightBracket = "]",
	Semicolon = ";", Quote = "'", Comma = ",", Period = ".", BackSlash = "\\", Up = "Up", Down = "Down",
	Left = "Left", Right = "Right", PageUp = "PgUp", PageDown = "PgDn", Delete = "Del", Insert = "Ins",
}

local function fieldOf(action: string): any
	local key = PREFIX .. action
	for _, field in ipairs(SettingsConfig.Schema) do
		if field.Key == key then
			return field
		end
	end
	return nil
end

-- The KeyCode bound to `action`, or nil when unbound.
function Keybinds.Get(action: string): Enum.KeyCode?
	local name = ClientSettings.Get(PREFIX .. action)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local ok, code = pcall(function() return (Enum.KeyCode :: any)[name] end)
	return if ok then code else nil
end

-- Does this input press `action`'s key? (Keyboard only; false while the settings screen is capturing.)
function Keybinds.Is(input: InputObject, action: string): boolean
	if Keybinds.Capturing or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return false
	end
	local code = Keybinds.Get(action)
	return code ~= nil and input.KeyCode == code
end

-- Display text for a key (KeyCode or name). "" / nil -> "".
function Keybinds.Label(key: any): string
	local name = if typeof(key) == "EnumItem" then (key :: EnumItem).Name else key
	if type(name) ~= "string" or name == "" then
		return ""
	end
	return LABELS[name] or name
end

-- Label of an ACTION's current key ("" when unbound) -- for key hints painted on buttons.
function Keybinds.LabelOf(action: string): string
	return Keybinds.Label(ClientSettings.Get(PREFIX .. action))
end

local function scopesOverlap(a: string, b: string): boolean
	return a == "Both" or b == "Both" or a == b
end

-- Bind `action` to the key NAME `keyName` ("" = unbind). Clears a clashing action of the same Group.
-- Returns the Label of the action it took the key from (or nil), so the screen can say so.
function Keybinds.Set(action: string, keyName: string): string?
	local field = fieldOf(action)
	if field == nil or (keyName ~= "" and not SettingsConfig.IsBindableKey(keyName)) then
		return nil
	end
	local changes: { [string]: any } = { [field.Key] = keyName }
	local tookFrom: string? = nil
	if keyName ~= "" then
		local group, scope = field.Group or "Global", SettingsConfig.ScopeOf(field)
		for _, other in ipairs(SettingsConfig.Schema) do
			if other.Type == "key" and other.Key ~= field.Key and (other.Group or "Global") == group
				and scopesOverlap(scope, SettingsConfig.ScopeOf(other)) and ClientSettings.Get(other.Key) == keyName then
				changes[other.Key] = ""
				tookFrom = other.Label
			end
		end
	end
	ClientSettings.SetMany(changes)
	return tookFrom
end

-- Every key back to its default, one save.
function Keybinds.Reset()
	local changes: { [string]: any } = {}
	for _, field in ipairs(SettingsConfig.Schema) do
		if field.Type == "key" then
			changes[field.Key] = SettingsConfig.Defaults[field.Key]
		end
	end
	ClientSettings.SetMany(changes)
end

-- A standalone hotkey: fn() runs when `action`'s key is pressed and no TextBox / CAS bind took it.
function Keybinds.Bind(action: string, fn: () -> ()): RBXScriptConnection
	return UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and Keybinds.Is(input, action) then
			fn()
		end
	end)
end

-- fn() whenever ANY key binding changes (not on every unrelated setting change).
local function snapshot(): string
	local parts = {}
	for _, field in ipairs(SettingsConfig.Schema) do
		if field.Type == "key" then
			table.insert(parts, tostring(ClientSettings.Get(field.Key)))
		end
	end
	return table.concat(parts, ",")
end
function Keybinds.Watch(fn: () -> ())
	local last = snapshot()
	ClientSettings.Changed:Connect(function()
		local now = snapshot()
		if now ~= last then
			last = now
			fn()
		end
	end)
end

-- ===== Reset Keybinds (the settings screen's action row) =====
if not ClientSettings.HasAction("ResetKeybinds") then
	ClientSettings.RegisterAction("ResetKeybinds", Keybinds.Reset)
end

-- ===== Interact key -> ProximityPrompts =====
local function applyPrompt(prompt: ProximityPrompt)
	local authored = prompt:GetAttribute("AD_AuthoredKey")
	if authored == nil then
		authored = prompt.KeyboardKeyCode.Name
		prompt:SetAttribute("AD_AuthoredKey", authored)
	end
	if authored ~= "E" then
		return -- a prompt authored on another key keeps it
	end
	prompt.KeyboardKeyCode = Keybinds.Get("Interact") or Enum.KeyCode.Unknown
end
local function applyAllPrompts()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ProximityPrompt") then
			applyPrompt(d)
		end
	end
end
if Players.LocalPlayer then
	task.defer(applyAllPrompts)
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ProximityPrompt") then
			applyPrompt(d)
		end
	end)
	Keybinds.Watch(applyAllPrompts)
end

return Keybinds
