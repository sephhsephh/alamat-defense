--!strict
-- UIKit.FilterPanel - reusable filter panel controller (AD-UI kit, blueprint phase-a section 5)
-- ONE controller for every filter panel. The DESIGN lives on the template instance
-- (ReplicatedStorage.UITemplates.Kit.FilterPanel - edit it in Studio); this module only
-- clones GroupTemplate/ToggleTemplate, fills their text, and wires clicks. It never builds UI.
--
-- Expected instance shape (built as REAL instances in the Kit):
--   FilterPanel (Frame, Visible=false)
--   |-- Title (TextLabel)
--   |-- Groups (ScrollingFrame)
--   |   `-- GroupTemplate (Frame, Visible=false)
--   |        |-- GroupTitle (TextLabel)
--   |        `-- Toggles (Frame)
--   |             `-- ToggleTemplate (TextButton, Visible=false)  [tagged UIKitButton]
--   `-- Buttons (Frame)
--        |-- ResetButton  |-- CancelButton  `-- ApplyButton       [tagged UIKitButton]
--
-- Apply/Cancel semantics: clicking toggles mutates a PENDING state. Apply commits pending ->
-- applied and fires OnApply(state). Cancel reverts pending to the last applied state and
-- closes. Reset clears pending (nothing selected = no constraint).
--
-- Usage:
--   local FilterPanel = require(ReplicatedStorage.Shared.UIKit.FilterPanel)
--   local handle = FilterPanel.attach(gui.FilterPanel, {
--     Title = "FILTERS",
--     Groups = {
--       { Id = "Tier", Title = "TIER", Options = { { Id = "Common", Text = "Common" }, ... } },
--       { Id = "Flags", Title = "SHOW", Options = { { Id = "Favorited", Text = "Favourited" } } },
--     },
--     OnApply = function(state) refreshList() end,
--   })
--   handle.toggle()
--   local tiers = handle.selected("Tier")   -- set of ids, or nil when the group is unconstrained

local TweenService = game:GetService("TweenService")

local FilterPanel = {}

-- Where FilterPanel.create() clones from, tried in order (same convention as UIKit.Button).
local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "FilterPanel" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "FilterPanel" },
}

local ON_STROKE = Color3.fromRGB(196, 158, 92)
local OFF_STROKE = Color3.fromRGB(90, 84, 104)
local ON_FILL = Color3.fromRGB(84, 72, 48)
local TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function resolveTemplate(): GuiObject?
	for _, path in ipairs(TEMPLATE_PATHS) do
		local node: Instance? = game
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and node:IsA("GuiObject") then
			return node
		end
	end
	return nil
end

local function copyState(src: { [string]: { [string]: boolean } }): { [string]: { [string]: boolean } }
	local out = {}
	for groupId, set in pairs(src) do
		local c = {}
		for id, on in pairs(set) do c[id] = on end
		out[groupId] = c
	end
	return out
end

-- Attach behaviour to an existing FilterPanel instance. Returns a handle.
function FilterPanel.attach(panel: GuiObject, config: { [string]: any })
	assert(panel, "UIKit.FilterPanel.attach: panel is nil")
	config = config or {}

	local groupsHost = panel:WaitForChild("Groups")
	local groupTemplate = groupsHost:WaitForChild("GroupTemplate")
	local buttonsRow = panel:WaitForChild("Buttons")

	local titleLabel = panel:FindFirstChild("Title")
	if titleLabel and titleLabel:IsA("TextLabel") and config.Title then
		titleLabel.Text = config.Title
	end

	-- Take the design templates OUT of the layout so they never render as a stray row.
	groupTemplate.Parent = script
	local toggleTemplate = groupTemplate:WaitForChild("Toggles"):WaitForChild("ToggleTemplate")
	toggleTemplate.Parent = script

	local applied: { [string]: { [string]: boolean } } = {}
	local pending: { [string]: { [string]: boolean } } = {}
	local chips: { { instance: TextButton, groupId: string, optionId: string } } = {}

	local function paintChip(chip: TextButton, on: boolean)
		local stroke = chip:FindFirstChild("UIStrokeWithGradient")
			or chip:FindFirstChildOfClass("UIStroke")
		if stroke and stroke:IsA("UIStroke") then
			local grad = stroke:FindFirstChildOfClass("UIGradient")
			if grad then
				grad.Color = ColorSequence.new(on and ON_STROKE or OFF_STROKE)
			else
				stroke.Color = on and ON_STROKE or OFF_STROKE
			end
		end
		TweenService:Create(chip, TWEEN, {
			BackgroundColor3 = on and ON_FILL or Color3.fromRGB(54, 50, 64),
		}):Play()
	end

	local function repaint()
		for _, c in ipairs(chips) do
			local set = pending[c.groupId]
			paintChip(c.instance, (set ~= nil) and set[c.optionId] == true)
		end
	end

	-- Build the group/toggle rows ONCE from the config (clone + fill + wire only).
	for gi, group in ipairs(config.Groups or {}) do
		local groupFrame = groupTemplate:Clone()
		groupFrame.Name = "Group_" .. tostring(group.Id)
		groupFrame.Visible = true
		groupFrame.LayoutOrder = gi
		local gt = groupFrame:FindFirstChild("GroupTitle")
		if gt and gt:IsA("TextLabel") then gt.Text = group.Title or group.Id end
		local togglesHost = groupFrame:WaitForChild("Toggles")
		groupFrame.Parent = groupsHost

		for oi, option in ipairs(group.Options or {}) do
			local chip = toggleTemplate:Clone() :: TextButton
			chip.Name = "Toggle_" .. tostring(option.Id)
			chip.Visible = true
			chip.LayoutOrder = oi
			local frame = chip:FindFirstChild("Frame")
			local text = frame and frame:FindFirstChild("Text")
			if text and text:IsA("TextLabel") then text.Text = option.Text or option.Id end
			chip.Parent = togglesHost
			table.insert(chips, { instance = chip, groupId = group.Id, optionId = option.Id })

			chip.Activated:Connect(function()
				local set = pending[group.Id]
				if not set then set = {}; pending[group.Id] = set end
				set[option.Id] = (set[option.Id] ~= true) or nil
				if next(set) == nil then pending[group.Id] = nil end
				repaint()
			end)
		end
	end

	local function fireApply()
		if type(config.OnApply) == "function" then
			task.spawn(config.OnApply, copyState(applied))
		end
	end

	local handle = {}
	handle.instance = panel

	function handle.isOpen(): boolean
		return panel.Visible
	end
	function handle.open()
		pending = copyState(applied)
		repaint()
		panel.Visible = true
	end
	function handle.close()
		panel.Visible = false
	end
	function handle.toggle()
		if panel.Visible then handle.close() else handle.open() end
	end
	-- Selected ids for a group, or nil when the group is unconstrained (nothing ticked).
	function handle.selected(groupId: string): { [string]: boolean }?
		local set = applied[groupId]
		if set == nil or next(set) == nil then return nil end
		return set
	end
	function handle.getState(): { [string]: { [string]: boolean } }
		return copyState(applied)
	end
	function handle.reset()
		pending = {}
		repaint()
	end

	local apply = buttonsRow:FindFirstChild("ApplyButton")
	local reset = buttonsRow:FindFirstChild("ResetButton")
	local cancel = buttonsRow:FindFirstChild("CancelButton")
	if apply and apply:IsA("GuiButton") then
		apply.Activated:Connect(function()
			applied = copyState(pending)
			handle.close()
			fireApply()
		end)
	end
	if reset and reset:IsA("GuiButton") then
		reset.Activated:Connect(handle.reset)
	end
	if cancel and cancel:IsA("GuiButton") then
		cancel.Activated:Connect(function()
			pending = copyState(applied)
			repaint()
			handle.close()
		end)
	end

	repaint()
	panel.Visible = false
	return handle
end

-- Clone the kit template and attach behaviour. Returns the same handle as attach().
function FilterPanel.create(parent: Instance, config: { [string]: any })
	local template = resolveTemplate()
	assert(template, "UIKit.FilterPanel.create: no FilterPanel template found in " ..
		"ReplicatedStorage.UITemplates.Kit / Shared.UIKit.Templates")
	local clone = template:Clone()
	clone.Parent = parent
	return FilterPanel.attach(clone, config)
end

return FilterPanel
