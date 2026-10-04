-- tools/build_settings_gui.luau (B111) -- AUTHORS StarterGui.Settings, the SAME tree in BOTH Places.
-- Run via execute_luau (Edit datamodel) in the Game AND the Lobby. Self-contained (no DevTools helpers) so
-- the result is byte-for-byte the same design everywhere. The old screen is kept as Settings_RetiredB111
-- (disabled); the Game's floating gear (OpenButton) is moved into the new screen.
-- Driven by the shared SettingsUI (see its header for the template names).
-- B112: then run tools/build_keybind_row.luau (adds KeybindRowTemplate for the Keybinds tab).
local CS = game:GetService("CollectionService")
local SG = game:GetService("StarterGui")
local FRED = Font.new("rbxasset://fonts/families/FredokaOne.json")
local GB = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local GM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local C = Color3.fromRGB
local function seq(list)
	local k = {}
	for i, c in ipairs(list) do table.insert(k, ColorSequenceKeypoint.new((i - 1) / math.max(1, #list - 1), c)) end
	return ColorSequence.new(k)
end
local function mk(class, parent, props)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
	for k, v in pairs(props or {}) do o[k] = v end
	o.Parent = parent
	return o
end
local function corner(p, s) return mk("UICorner", p, { CornerRadius = UDim.new(s or 0.2, 0) }) end
local function stroke(p, th, col, name) return mk("UIStroke", p, { Name = name or "UIStroke", Thickness = th, Color = col, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
local function shimmer(p, th)
	local s = stroke(p, th or 2.5, Color3.new(1, 1, 1), "GoldStroke")
	mk("UIGradient", s, { Name = "Shimmer", Rotation = 25, Color = seq({ C(255, 222, 130), C(255, 168, 50), C(255, 244, 200), C(255, 168, 50), C(255, 222, 130) }) })
	return s
end
local function glass(p, tr)
	p.BackgroundColor3 = Color3.new(1, 1, 1)
	p.BackgroundTransparency = tr or 0.04
	mk("UIGradient", p, { Name = "Glass", Rotation = 90, Color = seq({ C(52, 28, 88), C(26, 14, 46), C(14, 8, 26) }) })
end
local function text(parent, name, t, props, max)
	local l = mk("TextLabel", parent, { Name = name, Text = t, BackgroundTransparency = 1, FontFace = FRED, TextColor3 = Color3.new(1, 1, 1), TextScaled = true, TextWrapped = true })
	for k, v in pairs(props or {}) do l[k] = v end
	mk("UITextSizeConstraint", l, { MaxTextSize = max or 24, MinTextSize = 7 })
	mk("UIStroke", l, { Name = "TextStroke", Thickness = 1.5, Color = C(18, 8, 30), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
	return l
end
local function square(o) mk("UIAspectRatioConstraint", o, { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize }) end
local function shade(b) mk("UIGradient", b, { Name = "Fill", Rotation = 90, Color = seq({ Color3.new(1, 1, 1), C(170, 160, 190) }) }) end

-- retire the old screen, keep its OpenButton
local old = SG:FindFirstChild("Settings")
local openButton = nil
if old then
	openButton = old:FindFirstChild("OpenButton")
	old.Name = "Settings_RetiredB111"
	old.Enabled = false
	for _, d in ipairs(old:GetDescendants()) do CS:RemoveTag(d, "GamepadMenu") end
	CS:RemoveTag(old, "GamepadMenu")
end
local gui = mk("ScreenGui", nil, { Name = "Settings", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = true })
if openButton then openButton.Parent = gui end

mk("TextButton", gui, { Name = "Dim", Text = "", AutoButtonColor = false, Selectable = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(6, 2, 12), BackgroundTransparency = 0.45, Visible = false, ZIndex = 1 })

local panel = mk("Frame", gui, { Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53), Size = UDim2.fromScale(0.74, 0.84), Visible = false, ZIndex = 2 })
glass(panel)
corner(panel, 0.03)
shimmer(panel, 3)
CS:AddTag(panel, "GamepadMenu")

-- title banner sticking out top-left
local tb = mk("Frame", panel, { Name = "TitleBanner", Position = UDim2.fromScale(-0.025, -0.065), Size = UDim2.fromScale(0.3, 0.11), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
mk("UIGradient", tb, { Name = "Fill", Rotation = 90, Color = seq({ C(255, 214, 110), C(220, 130, 30) }) })
corner(tb, 0.3)
stroke(tb, 3, C(40, 16, 60))
local sun = mk("ImageLabel", tb, { Name = "Emblem", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.08, 0.5), Size = UDim2.fromScale(0.5, 1.5), ZIndex = 6, ScaleType = Enum.ScaleType.Fit })
square(sun)
text(tb, "Title", "Settings", { Position = UDim2.fromScale(0.2, 0.1), Size = UDim2.fromScale(0.75, 0.8), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, 40)

-- search
local sr = mk("Frame", panel, { Name = "Search", Position = UDim2.fromScale(0.3, 0.025), Size = UDim2.fromScale(0.6, 0.07), BackgroundColor3 = C(8, 4, 14), ZIndex = 3 })
corner(sr, 0.3)
stroke(sr, 1.5, C(110, 90, 150))
local input = mk("TextBox", sr, { Name = "Input", Text = "", PlaceholderText = "Search...", ClearTextOnFocus = false, BackgroundTransparency = 1, Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.94, 0.76), FontFace = GM, TextColor3 = C(240, 236, 250), PlaceholderColor3 = C(140, 130, 160), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 4 })
mk("UITextSizeConstraint", input, { MaxTextSize = 20, MinTextSize = 8 })

-- close X (round, red)
local cb = mk("TextButton", panel, { Name = "CloseButton", Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.985, 0.01), Size = UDim2.fromScale(0.09, 0.12), BackgroundColor3 = C(205, 40, 50), AutoButtonColor = false, ZIndex = 6 })
square(cb)
corner(cb, 0.5)
shade(cb)
shimmer(cb, 2.5)
text(cb, "X", "X", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6), ZIndex = 7 }, 34)
cb:SetAttribute("GamepadDefault", false)

-- sidebar
local side = mk("Frame", panel, { Name = "CategoryPanel", Position = UDim2.fromScale(0.02, 0.12), Size = UDim2.fromScale(0.2, 0.85), BackgroundColor3 = C(10, 6, 18), BackgroundTransparency = 0.25, ZIndex = 3 })
corner(side, 0.04)
mk("UIPadding", side, { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
mk("UIListLayout", side, { Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder })

-- content
local content = mk("ScrollingFrame", panel, { Name = "Content", Position = UDim2.fromScale(0.24, 0.12), Size = UDim2.fromScale(0.745, 0.85), BackgroundColor3 = C(6, 3, 12), BackgroundTransparency = 0.3, ScrollBarThickness = 6, ScrollBarImageColor3 = C(255, 200, 90), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y, Selectable = false, ZIndex = 3 })
corner(content, 0.02)
mk("UIPadding", content, { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) })
mk("UIListLayout", content, { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })

-- ===== templates =====
local cat = mk("TextButton", gui, { Name = "CategoryButtonTemplate", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 0.085), BackgroundColor3 = C(52, 40, 74), Visible = false, ZIndex = 4 })
corner(cat, 0.2)
shade(cat)
stroke(cat, 1.5, C(130, 100, 170))
local ci = mk("ImageLabel", cat, { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromScale(0.06, 0.2), Size = UDim2.fromScale(0.2, 0.6), ScaleType = Enum.ScaleType.Fit, ZIndex = 5 })
square(ci)
text(cat, "Label", "All", { Position = UDim2.fromScale(0.28, 0.15), Size = UDim2.fromScale(0.68, 0.7), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, 22)

local sec = mk("Frame", gui, { Name = "SectionTemplate", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, ZIndex = 4 })
mk("UIListLayout", sec, { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
local hd = mk("Frame", sec, { Name = "Header", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, ZIndex = 4 })
local hi = mk("ImageLabel", hd, { Name = "Icon", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.1), Size = UDim2.fromScale(0.05, 0.8), ImageColor3 = C(255, 205, 90), ScaleType = Enum.ScaleType.Fit, ZIndex = 5 })
square(hi)
local hl = text(hd, "Label", "Audio", { Position = UDim2.new(0, 34, 0, 0), Size = UDim2.new(0.4, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, 26)
mk("UIGradient", hl, { Name = "GoldText", Rotation = 90, Color = seq({ C(255, 246, 200), C(255, 205, 90), C(255, 160, 40) }) })
local line = mk("Frame", hd, { Name = "Line", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.22, 0, 0.55, 0), Size = UDim2.new(0.7, 0, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4 })
mk("UIGradient", line, { Name = "Fade", Color = seq({ C(255, 205, 90), C(160, 80, 255) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) })
local grid = mk("Frame", sec, { Name = "Grid", LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 4 })
mk("UIGridLayout", grid, { CellSize = UDim2.fromOffset(300, 60), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder })

local function rowBase(name)
	local r = mk("Frame", gui, { Name = name, BackgroundColor3 = C(28, 20, 40), BackgroundTransparency = 0.05, Visible = false, ZIndex = 4 })
	corner(r, 0.12)
	stroke(r, 1.2, C(80, 66, 110), "Edge")
	text(r, "Title", "Setting", { Position = UDim2.fromScale(0.04, 0.12), Size = UDim2.fromScale(0.62, 0.4), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, 20)
	text(r, "Desc", "Description", { Position = UDim2.fromScale(0.04, 0.52), Size = UDim2.fromScale(0.62, 0.38), TextXAlignment = Enum.TextXAlignment.Left, FontFace = GM, TextColor3 = C(185, 175, 205), ZIndex = 5 }, 15)
	return r
end
local function squareButton(r, name, bg)
	local b = mk("TextButton", r, { Name = name, Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.2, 0.72), BackgroundColor3 = bg, ZIndex = 5 })
	mk("UIAspectRatioConstraint", b, { AspectRatio = 1.25, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize })
	corner(b, 0.2)
	shade(b)
	stroke(b, 1.8, C(255, 214, 120), "Edge")
	return b
end

local tr = rowBase("ToggleRowTemplate")
local tg = squareButton(tr, "Toggle", C(80, 200, 70))
local ck = mk("ImageLabel", tg, { Name = "Check", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.6), ScaleType = Enum.ScaleType.Fit, ZIndex = 6 })
local cx = text(tg, "Cross", "X", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 0.7), Visible = false, ZIndex = 6 }, 30)

local srow = rowBase("SliderRowTemplate")
srow.Title.Size = UDim2.fromScale(0.4, 0.4)
srow.Desc.Size = UDim2.fromScale(0.4, 0.38)
local vb = mk("TextBox", srow, { Name = "ValueBox", Text = "100", ClearTextOnFocus = true, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.45, 0.5), Size = UDim2.fromScale(0.12, 0.62), BackgroundColor3 = C(8, 4, 14), FontFace = FRED, TextColor3 = Color3.new(1, 1, 1), TextScaled = true, ZIndex = 5 })
corner(vb, 0.2)
stroke(vb, 1.5, C(110, 90, 150))
mk("UIPadding", vb, { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) })
local track = mk("TextButton", srow, { Name = "Track", Text = "", AutoButtonColor = false, Selectable = true, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.6, 0.5), Size = UDim2.fromScale(0.36, 0.2), BackgroundColor3 = C(44, 34, 60), ZIndex = 5 })
corner(track, 1)
local fl = mk("Frame", track, { Name = "Fill", Size = UDim2.fromScale(0.5, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 })
corner(fl, 1)
mk("UIGradient", fl, { Name = "Fill", Color = seq({ C(160, 90, 255), C(255, 200, 90) }) })
local hn = mk("Frame", track, { Name = "Handle", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0, 2.4), BackgroundColor3 = C(240, 236, 250), ZIndex = 7 })
mk("UIAspectRatioConstraint", hn, { AspectRatio = 0.6, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize })
corner(hn, 0.3)
stroke(hn, 1.5, C(40, 20, 60))

local ar = rowBase("ActionRowTemplate")
local ab = squareButton(ar, "Button", C(120, 80, 220))
mk("ImageLabel", ab, { Name = "Icon", BackgroundTransparency = 1, Image = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), ScaleType = Enum.ScaleType.Fit, ZIndex = 6 })

gui.Parent = SG

-- icons from the shared IconCatalog (sun emblem on the banner, check on the toggle)
local ok, IC = pcall(function() return loadstring(game.ReplicatedStorage.Shared.IconCatalog.Source)() end)
if ok and IC then
	ck.Image = IC.get("Check")
	sun.Image = IC.get("Sparkle")
end
return "Settings GUI built (" .. #gui:GetDescendants() .. " descendants)"
