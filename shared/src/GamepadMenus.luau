--!strict
-- GamepadMenus (SHARED CANON -- deploy path StarterPlayer.StarterPlayerScripts.Client.GamepadMenus)
-- Added B97. A LocalScript, hashed as source. The console foundation for EVERY menu, in both Places.
--
-- HOW A MENU OPTS IN: tag its root (a ScreenGui, or the Frame that shows/hides) with the
-- CollectionService tag "GamepadMenu" in Studio. That is all. While a player is on a GAMEPAD:
--   * the moment a tagged menu OPENS (Visible / Enabled all the way up), its first button is
--     selected, so the stick navigates it at once -- no hunting for the Select button;
--   * when it CLOSES with the selection inside it, the selection is cleared (no ghost focus);
--   * switching TO a gamepad while a menu is open focuses that menu.
-- A button with attribute GamepadDefault = true is chosen first (e.g. a menu's main action).
-- Menus that are NOT tagged still work through Roblox's own Select-button navigation.
--
-- Polled (every 0.15 s) rather than wired to every Visible/Enabled signal up each ancestor chain:
-- a menu can be opened by toggling ANY ancestor, and a poll over a couple of dozen roots is cheap.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputMode = require(ReplicatedStorage.Shared.InputMode)

local TAG = "GamepadMenu"
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local wasOpen: { [Instance]: boolean } = {}
local openOrder: { Instance } = {} -- most recently opened last

local function isOpen(root: Instance): boolean
	if root:IsA("ScreenGui") then
		return root.Enabled
	elseif root:IsA("GuiObject") then
		return InputMode.IsShown(root)
	end
	return false
end

local function forget(root: Instance)
	wasOpen[root] = nil
	local i = table.find(openOrder, root)
	if i then
		table.remove(openOrder, i)
	end
end

local function step()
	for _, root in ipairs(CollectionService:GetTagged(TAG)) do
		if root:IsDescendantOf(playerGui) then
			local open = isOpen(root)
			if open and not wasOpen[root] then
				wasOpen[root] = true
				table.insert(openOrder, root)
				InputMode.FocusFirst(root)
			elseif not open and wasOpen[root] then
				forget(root)
				local sel = GuiService.SelectedObject
				if sel and sel:IsDescendantOf(root) then
					GuiService.SelectedObject = nil
				end
			end
		end
	end
end

CollectionService:GetInstanceRemovedSignal(TAG):Connect(forget)

InputMode.Changed:Connect(function(mode: string)
	if mode == "Gamepad" then
		local top = openOrder[#openOrder]
		if top and top.Parent then
			InputMode.FocusFirst(top)
		end
	end
end)

task.spawn(function()
	while true do
		step()
		task.wait(0.15)
	end
end)

print("[GamepadMenus] Ready (tag a menu root \"GamepadMenu\" to get focus-on-open for controllers).")
