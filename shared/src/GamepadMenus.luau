--!strict
-- GamepadMenus (SHARED CANON -- deploy path StarterPlayer.StarterPlayerScripts.Client.GamepadMenus)
-- Added B97. A LocalScript, hashed as source. The console foundation for EVERY menu, in both Places.
--
-- HOW A MENU OPTS IN: tag its root (a ScreenGui, or the Frame that shows/hides) with the
-- CollectionService tag "GamepadMenu" in Studio. That is all. While a player is on a GAMEPAD:
--   * the moment a tagged menu OPENS (Visible / Enabled all the way up), its first button is
--     selected, so the stick navigates it at once -- no hunting for the Select button;
--   * when it CLOSES with the selection inside it, the focus goes back to the menu still open under
--     it, or is cleared (no ghost focus -- B103: also when Roblox already jumped it to a HUD button);
--   * switching TO a gamepad while a menu is open focuses that menu.
-- A button with attribute GamepadDefault = true is chosen first (e.g. a menu's main action).
-- Menus that are NOT tagged still work through Roblox's own Select-button navigation.
--
-- B101: THE HUD. Press Y (with no tagged menu open) to put the pad's focus on the root tagged
-- "GamepadHud" (the Lobby's left button column, the match's right buttons) -- then the stick walks
-- every HUD button. Y again, or B, leaves it. Y is skipped while a tagged menu is open, which is
-- also what keeps the Game's tower panel (Y = cycle targeting) working.
-- B127: with SEVERAL HUD roots open, Y steps through them in `GamepadHudOrder` order before leaving
-- (the match: right buttons -> the bottom-left J / K corner, which the stick could not reach).
--
-- B102: KEY HINTS. Tag a keycap TextLabel "KeyHint" and it follows the device: keyboard shows its
-- AUTHORED text, a pad shows its `Pad` attribute (e.g. "L1"; missing/empty = hidden on a pad), touch
-- hides it. `HideParent = true` hides/shows the label's parent instead (a whole chip or hint row).
--
-- Polled (every 0.15 s) rather than wired to every Visible/Enabled signal up each ancestor chain:
-- a menu can be opened by toggling ANY ancestor, and a poll over a couple of dozen roots is cheap.

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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

-- B103: when the selected button is hidden, Roblox itself jumps the selection to the NEAREST visible
-- button (a closing menu handed focus to the HUD's speed buttons, and every "only while nothing is
-- selected" pad shortcut then went dead). So remember the selection the jump came FROM: a menu that
-- closes while it held the focus, or whose button was the LAST place the focus moved from (a close
-- tween can outlast the jump by a second), clears the selection.
local prevSel: Instance? = nil
local curSel: Instance? = GuiService.SelectedObject
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	prevSel = curSel
	curSel = GuiService.SelectedObject
end)

local function step()
	for _, root in ipairs(CollectionService:GetTagged(TAG)) do
		if root:IsDescendantOf(playerGui) then
			local open = isOpen(root)
			if open and not wasOpen[root] then
				wasOpen[root] = true
				table.insert(openOrder, root)
				local first = InputMode.FocusFirst(root)
				-- B103: many menus build their cards AFTER they show (the Units grid, a picker) -- so
				-- look again shortly (a grid behind a server call can take a couple of seconds), unless
				-- the player has already moved the focus themselves.
				for _, t in ipairs({ 0.3, 1, 2.5 }) do
					task.delay(t, function()
						if wasOpen[root] and GuiService.SelectedObject == first then
							first = InputMode.FocusFirst(root) or first
						end
					end)
				end
			elseif not open and wasOpen[root] then
				forget(root)
				local sel = GuiService.SelectedObject
				local jumpedOut = prevSel ~= nil
					and (prevSel :: Instance):IsDescendantOf(root)
				if sel and (sel:IsDescendantOf(root) or jumpedOut) then
					-- B103: hand the focus back to the menu underneath (e.g. the between-waves prompt
					-- popped over an open Unit Manager), otherwise clear it.
					local top = openOrder[#openOrder]
					if not (top and top.Parent and InputMode.FocusFirst(top)) then
						GuiService.SelectedObject = nil
					end
				end
			end
		end
	end
end

CollectionService:GetInstanceRemovedSignal(TAG):Connect(forget)

local HUD_TAG = "GamepadHud"
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed or input.KeyCode ~= Enum.KeyCode.ButtonY or #openOrder > 0 then
		return
	end
	-- B127: several HUD roots (the match: right column, then the J / K corner) -- Y walks them in
	-- `GamepadHudOrder` order (number attribute, default 0; ties by path), and leaves after the last.
	local roots = {}
	for _, root in ipairs(CollectionService:GetTagged(HUD_TAG)) do
		if root:IsDescendantOf(playerGui) and isOpen(root) then
			table.insert(roots, root)
		end
	end
	table.sort(roots, function(a: Instance, b: Instance): boolean
		local oa = tonumber(a:GetAttribute("GamepadHudOrder")) or 0
		local ob = tonumber(b:GetAttribute("GamepadHudOrder")) or 0
		if oa ~= ob then
			return oa < ob
		end
		return a:GetFullName() < b:GetFullName()
	end)
	local sel = GuiService.SelectedObject
	if sel ~= nil then
		for i, root in ipairs(roots) do
			if sel:IsDescendantOf(root) then
				local nxt = roots[i + 1]
				if nxt and InputMode.FocusFirst(nxt, true) then
					return
				end
				break
			end
		end
		GuiService.SelectedObject = nil -- Y again: leave the HUD
		return
	end
	for _, root in ipairs(roots) do
		if InputMode.FocusFirst(root, true) then
			return
		end
	end
end)

local HINT_TAG = "KeyHint"
local function paintHint(label: Instance)
	if not label:IsA("TextLabel") or not label:IsDescendantOf(playerGui) then
		return
	end
	if label:GetAttribute("Keyboard") == nil then
		label:SetAttribute("Keyboard", label.Text) -- remember the authored keyboard cap once
	end
	local mode = InputMode.Get()
	local pad = label:GetAttribute("Pad")
	local show = true
	if mode == "Touch" then
		show = false
	elseif mode == "Gamepad" then
		show = type(pad) == "string" and pad ~= ""
		if show then
			label.Text = pad :: string
		end
	else
		label.Text = tostring(label:GetAttribute("Keyboard"))
	end
	local target: Instance? = if label:GetAttribute("HideParent") == true then label.Parent else label
	if target and target:IsA("GuiObject") then
		-- Only ever undo a hide WE did, so a chip a controller script hides on purpose stays hidden.
		if show and target:GetAttribute("HintHidden") == true then
			target.Visible = true
			target:SetAttribute("HintHidden", nil)
		elseif not show and target.Visible then
			target.Visible = false
			target:SetAttribute("HintHidden", true)
		end
	end
end
local function paintAllHints()
	for _, label in ipairs(CollectionService:GetTagged(HINT_TAG)) do
		paintHint(label)
	end
end
CollectionService:GetInstanceAddedSignal(HINT_TAG):Connect(function(label)
	task.defer(paintHint, label) -- a GUI cloned into PlayerGui arrives tagged
end)
task.defer(paintAllHints)

InputMode.Changed:Connect(function(mode: string)
	paintAllHints()
	if mode == "Gamepad" then
		local top = openOrder[#openOrder]
		if top and top.Parent then
			InputMode.FocusFirst(top)
		end
	elseif mode == "Touch" then
		-- B103: a pad focus left behind would keep drawing its selection frame under a thumb. (Not on
		-- KeyboardMouse: a bumped mouse must not throw away a controller player's place in a menu.)
		GuiService.SelectedObject = nil
	end
end)

task.spawn(function()
	while true do
		step()
		task.wait(0.15)
	end
end)

print("[GamepadMenus] Ready (tag a menu root \"GamepadMenu\" to get focus-on-open for controllers).")
