-- tools/build_keybind_row.luau (B112) -- AUTHORS StarterGui.Settings.KeybindRowTemplate, the SAME in BOTH Places.
-- Run via execute_luau (Edit datamodel) in the Game AND the Lobby, after tools/build_settings_gui.luau.
-- Clones ActionRowTemplate (same row card, title, desc) and swaps its Button for:
--   KeyButton{ Label }  -- the bound key ("L Shift" / "None" / "Press a key"), right side
--   Clear               -- red round X that unbinds, left of the key
-- Driven by the shared SettingsUI (buildKey). Re-running replaces the template.
local SG = game:GetService("StarterGui")
local FRED = Font.new("rbxasset://fonts/families/FredokaOne.json")
local C = Color3.fromRGB
local function mk(class, parent, props)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end
local function seq(a, b) return ColorSequence.new(a, b) end

local gui = SG:FindFirstChild("Settings")
assert(gui, "StarterGui.Settings missing -- run tools/build_settings_gui.luau first")
local action = gui:FindFirstChild("ActionRowTemplate")
assert(action, "Settings.ActionRowTemplate missing")
local old = gui:FindFirstChild("KeybindRowTemplate")
if old then old:Destroy() end

local row = action:Clone()
row.Name = "KeybindRowTemplate"
row.Visible = false
if row:FindFirstChild("Button") then row.Button:Destroy() end
row.Title.Size = UDim2.fromScale(0.5, 0.4)
row.Desc.Size = UDim2.fromScale(0.5, 0.38)

local key = mk("TextButton", row, { Name = "KeyButton", Text = "", AutoButtonColor = false, Selectable = true,
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.28, 0.66),
	BackgroundColor3 = C(52, 40, 74), ZIndex = 5 })
mk("UICorner", key, { CornerRadius = UDim.new(0.25, 0) })
mk("UIGradient", key, { Name = "Fill", Rotation = 90, Color = seq(Color3.new(1, 1, 1), C(170, 160, 190)) })
mk("UIStroke", key, { Name = "Edge", Thickness = 1.8, Color = C(255, 214, 120), ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
local lbl = mk("TextLabel", key, { Name = "Label", Text = "L Shift", BackgroundTransparency = 1, FontFace = FRED,
	TextColor3 = Color3.new(1, 1, 1), TextScaled = true, TextWrapped = true, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.88, 0.62), ZIndex = 6 })
mk("UITextSizeConstraint", lbl, { MaxTextSize = 22, MinTextSize = 7 })
mk("UIStroke", lbl, { Name = "TextStroke", Thickness = 1.5, Color = C(18, 8, 30), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })

local clr = mk("TextButton", row, { Name = "Clear", Text = "", AutoButtonColor = false, Selectable = true,
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.675, 0.5), Size = UDim2.fromScale(0.1, 0.52),
	BackgroundColor3 = C(205, 45, 55), ZIndex = 5 })
mk("UIAspectRatioConstraint", clr, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize })
mk("UICorner", clr, { CornerRadius = UDim.new(1, 0) })
mk("UIGradient", clr, { Name = "Fill", Rotation = 90, Color = seq(Color3.new(1, 1, 1), C(170, 160, 190)) })
mk("UIStroke", clr, { Name = "Edge", Thickness = 1.5, Color = C(255, 214, 120), ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
local x = mk("TextLabel", clr, { Name = "Cross", Text = "X", BackgroundTransparency = 1, FontFace = FRED,
	TextColor3 = Color3.new(1, 1, 1), TextScaled = true, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ZIndex = 6 })
mk("UIStroke", x, { Name = "TextStroke", Thickness = 1.5, Color = C(18, 8, 30), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })

row.Parent = gui
return "KeybindRowTemplate built (" .. #row:GetDescendants() .. " descendants)"
