--!strict
-- SettingsUI.client.lua (SHARED CANON, LocalScript -- deploy path
-- StarterPlayer.StarterPlayerScripts.Client.UI.SettingsUI)
--
-- The settings panel. Builds one row per in-scope SettingsConfig entry (toggle, slider or action)
-- by cloning the templates in StarterGui.Settings -- no hardcoded row list here, so adding a
-- setting is a config edit. All preference state lives in ClientSettings; this script just reflects
-- and edits it.
--
-- *** SHARED CANON AT B35: ONE SCREEN BUILDER FOR BOTH PLACES. ***
-- The user's requirement was "same structure, same gui" in the Game and the Lobby, with some
-- entries only available in one of them. That is served WITHOUT any Place-specific branch in here:
-- the script asks SettingsConfig what is in scope and draws exactly that. A Place difference is a
-- `Scope` field in the config, never an `if` in this file. Hashed as source, same as UIKitBootstrap.
--
-- The GUI it drives (StarterGui.Settings) is PER-PLACE AUTHORED ART -- copying a ScreenGui between
-- Places is a USER action (B26), so this script degrades to a warning when the art is not there yet.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)
local ClientSettings = require(script.Parent.Parent.Settings.ClientSettings)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Bounded, never bare (B33). If this Place has no Settings screen yet the whole script stands down
-- quietly instead of hanging forever on a ScreenGui that may never arrive.
local gui = playerGui:FindFirstChild("Settings") or playerGui:WaitForChild("Settings", 10)
if gui == nil then
	warn("[SettingsUI] StarterGui.Settings is not in this Place yet -- the settings panel is"
		.. " unavailable here. Copy the ScreenGui across (B26: art is a user action) and it will"
		.. " build itself from SettingsConfig with no code change.")
	script:SetAttribute("BootComplete", true)
	return
end

local function need(parent: Instance, name: string): Instance?
	return parent:FindFirstChild(name) or parent:WaitForChild(name, 5)
end

local panel = need(gui, "Panel")
local dim = need(gui, "Dim")
local toggleTemplate = need(gui, "ToggleRowTemplate")
local sliderTemplate = need(gui, "SliderRowTemplate")
local catButtonTemplate = need(gui, "CategoryButtonTemplate")
local closeBtn = panel and need(panel, "CloseButton")
local catPanel = panel and need(panel, "CategoryPanel")
local content = panel and need(panel, "Content") -- ScrollingFrame
local openBtn = gui:FindFirstChild("OpenButton") -- optional: the Game's floating gear

if panel == nil or dim == nil or content == nil or catPanel == nil
	or toggleTemplate == nil or sliderTemplate == nil or catButtonTemplate == nil then
	warn("[SettingsUI] StarterGui.Settings is missing required parts (Panel/Dim/Content/"
		.. "CategoryPanel/ToggleRowTemplate/SliderRowTemplate/CategoryButtonTemplate) -- panel disabled.")
	script:SetAttribute("BootComplete", true)
	return
end

-- Bound ONCE, after the nil-guard above proved they exist. Two reasons this matters more than
-- style: a statement beginning with `(` parses as a call to the previous line (Luau calls it
-- ambiguous syntax and refuses the file), and a leading `;` is not a legal way to start a block in
-- Luau at all. Both of those took this script down on first deploy at B35.
local panelFrame = panel :: GuiObject
local dimButton = dim :: GuiButton
local dimFrame = dim :: GuiObject
local contentFrame = content :: ScrollingFrame
local closeButton = closeBtn :: GuiButton

local CAT_ON_BG = Color3.fromRGB(120, 200, 255)
local CAT_ON_TEXT = Color3.fromRGB(15, 25, 35)
local CAT_OFF_BG = Color3.fromRGB(40, 44, 56)
local CAT_OFF_TEXT = Color3.fromRGB(150, 155, 175)
local ACTION_BG = Color3.fromRGB(90, 150, 220)
local ACTION_TEXT = Color3.fromRGB(15, 25, 35)
local DISABLED_BG = Color3.fromRGB(70, 74, 86)
local DISABLED_TEXT = Color3.fromRGB(140, 145, 160)

local refreshers: { [string]: (any) -> () } = {}
-- Action buttons are repainted every time the panel OPENS, not just when they are built. Handlers
-- are registered by SEPARATE scripts (each Place registers its own), and LocalScript run order is
-- not guaranteed -- so a build-time-only paint would show "N/A" forever whenever the registrar
-- happened to run second. By the time a human opens settings, every boot script has long finished.
local actionRefreshers: { () -> () } = {}
local rowEntries: { { row: Instance, category: string } } = {}
local catButtons: { [string]: TextButton } = {}
local activeCategory = "All"
local place = SettingsConfig.Place()

local function setToggleVisual(button: TextButton, on: boolean)
	button.Text = on and "ON" or "OFF"
	button.BackgroundColor3 = on and Color3.fromRGB(90, 200, 120) or Color3.fromRGB(90, 96, 112)
	button.TextColor3 = on and Color3.fromRGB(20, 30, 20) or Color3.fromRGB(220, 220, 230)
end

local function buildToggle(field: any, order: number)
	local row = (toggleTemplate :: Instance):Clone() :: any
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	row.Label.Text = field.Label
	local button = row.Toggle
	row.Parent = content

	refreshers[field.Key] = function(value)
		setToggleVisual(button, value == true)
	end
	button.MouseButton1Click:Connect(function()
		ClientSettings.Set(field.Key, not (ClientSettings.Get(field.Key) == true))
	end)
	table.insert(rowEntries, { row = row, category = field.Category or "Game" })
end

local function buildSlider(field: any, order: number)
	local row = (sliderTemplate :: Instance):Clone() :: any
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	row.Label.Text = field.Label
	local track, valueLabel = row.Track, row.ValueLabel
	local fill, handle = track.Fill, track.Handle
	row.Parent = content

	local minV = field.Min or 0
	local maxV = field.Max or 1

	refreshers[field.Key] = function(value)
		local ratio = math.clamp(((value or 0) - minV) / math.max(maxV - minV, 1e-6), 0, 1)
		fill.Size = UDim2.fromScale(ratio, 1)
		handle.Position = UDim2.fromScale(ratio, 0.5)
		valueLabel.Text = tostring(math.floor(ratio * 100 + 0.5)) .. "%"
	end

	local dragging = false
	local function applyFromX(x: number)
		local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		ClientSettings.Set(field.Key, minV + ratio * (maxV - minV))
	end

	track.MouseButton1Down:Connect(function()
		dragging = true
		applyFromX(UserInputService:GetMouseLocation().X)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			applyFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	table.insert(rowEntries, { row = row, category = field.Category or "Game" })
end

-- An ACTION fires and persists nothing, so it reuses the toggle row's shape (label + button) with
-- the button repurposed. WHAT it does is registered per Place by that Place's own code; if nothing
-- registered a handler the button is drawn DISABLED and says so, because a button that silently
-- does nothing is worse than one that visibly cannot be pressed.
local function buildAction(field: any, order: number)
	local row = (toggleTemplate :: Instance):Clone() :: any
	row.Name = field.Key
	row.LayoutOrder = order
	row.Visible = true
	row.Label.Text = field.Label
	local button = row.Toggle
	row.Parent = content

	local function paint()
		local wired = ClientSettings.HasAction(field.Key)
		button.Text = wired and "RUN" or "N/A"
		button.BackgroundColor3 = wired and ACTION_BG or DISABLED_BG
		button.TextColor3 = wired and ACTION_TEXT or DISABLED_TEXT
		button.Active = wired
		button.AutoButtonColor = wired
	end
	paint()
	table.insert(actionRefreshers, paint)

	-- Connected unconditionally: RunAction itself refuses and warns when nothing is registered, so
	-- there is no window where a late-registered handler is drawn live but wired to nothing.
	button.MouseButton1Click:Connect(function()
		ClientSettings.RunAction(field.Key)
	end)
	table.insert(rowEntries, { row = row, category = field.Category or "Actions" })
end

-- Build rows for what THIS Place shows. No Place branch here -- Scope decides.
local built = 0
for i, field in ipairs(SettingsConfig.EntriesFor("All", place)) do
	if SettingsConfig.KindOf(field) == "Action" then
		buildAction(field, i)
	elseif field.Type == "number" then
		buildSlider(field, i)
	else
		buildToggle(field, i)
	end
	built += 1
end

local function refreshAll(settings: any)
	for key, fn in pairs(refreshers) do
		fn(settings[key])
	end
end

local function selectCategory(category: string)
	activeCategory = category
	for name, btn in pairs(catButtons) do
		local on = (name == category)
		btn.BackgroundColor3 = on and CAT_ON_BG or CAT_OFF_BG
		btn.TextColor3 = on and CAT_ON_TEXT or CAT_OFF_TEXT
	end
	for _, entry in ipairs(rowEntries) do
		entry.row.Visible = (category == "All") or (entry.category == category)
	end
	contentFrame.CanvasPosition = Vector2.new(0, 0)
end

-- Only tabs that actually have a row here, so a Place never draws an empty category.
for i, category in ipairs(SettingsConfig.CategoriesFor(place)) do
	local btn = (catButtonTemplate :: Instance):Clone() :: TextButton
	btn.Name = category
	btn.LayoutOrder = i
	btn.Text = category
	btn.Visible = true
	btn.Parent = catPanel
	catButtons[category] = btn
	btn.MouseButton1Click:Connect(function()
		selectCategory(category)
	end)
end

ClientSettings.Changed:Connect(refreshAll)
refreshAll(ClientSettings.GetAll())
selectCategory("All")

-- ===== Open / close =====
local function setOpen(open: boolean)
	dimFrame.Visible = open
	panelFrame.Visible = open
	if open then
		for _, paint in ipairs(actionRefreshers) do
			paint()
		end
		refreshAll(ClientSettings.GetAll())
		selectCategory(activeCategory)
	end
end

if openBtn and openBtn:IsA("GuiButton") then
	openBtn.MouseButton1Click:Connect(function()
		setOpen(true)
	end)
end
closeButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)
dimButton.MouseButton1Click:Connect(function()
	setOpen(false)
end)

-- The Lobby opens settings from its HUD rather than a floating gear. Wired here, optionally, so the
-- two Places share one screen and one builder while each keeps its own entry point.
task.spawn(function()
	local hud = playerGui:FindFirstChild("HUD") or playerGui:WaitForChild("HUD", 10)
	local right = hud and hud:FindFirstChild("Right")
	local upper = right and right:FindFirstChild("UpperRight")
	local btn = upper and upper:FindFirstChild("SettingsButton")
	if btn and btn:IsA("GuiButton") then
		btn.MouseButton1Click:Connect(function()
			setOpen(true)
		end)
		print("[SettingsUI] HUD SettingsButton wired.")
	end
end)

setOpen(false)
print(string.format("[SettingsUI] Initialized (%s place, %d row(s), %d categor(ies)).",
	place, built, #SettingsConfig.CategoriesFor(place)))

script:SetAttribute("BootComplete", true)   -- B34 BOOT MARKER
