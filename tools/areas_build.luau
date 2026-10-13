-- areas_build.luau (B146) -- run with execute_luau in the LOBBY (Edit). Builds StarterGui.AreasGUI, the HUD "Areas"
-- screen (user refs B146): categories on the left + Add Waypoint, search, one scrolling list of category sections
-- (header with a glowing underline + picture cards with a favourite star), a waypoint marker template.
-- Real Instances only; AreasController clones the Templates and fills them from RS.Configs.AreasConfig.
-- LAYOUT TRICK (same as the Items grid, B108): Content is ONE wrapping UIListLayout -- a section header is a
-- full-width row, cards are 0.32 wide; both carry an aspect constraint so their height follows their width.

local SG = game:GetService("StarterGui")
local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local GOLD = CS({ CK(0, C(255, 246, 204)), CK(0.22, C(240, 184, 72)), CK(0.48, C(150, 88, 24)), CK(0.74, C(255, 226, 138)), CK(1, C(176, 108, 32)) })
local LABEL_GOLD = CS({ CK(0, C(255, 248, 214)), CK(0.5, C(255, 202, 92)), CK(1, C(214, 138, 46)) })
local NIGHT = CS(C(66, 44, 120), C(24, 15, 48))
local F_LABEL = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local F_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local F_BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local IMG = {
	Engraving = "rbxassetid://95270696231518", Burst = "rbxassetid://7229481183", GlowRing = "rbxassetid://9864075653",
	Compass = "rbxassetid://128162852510137", Search = "rbxassetid://15999597350", Star = "rbxassetid://3057073083",
	StarEmpty = "rbxassetid://130377121632515", Streak = "rbxassetid://3052949762",
}

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function aspect(o, r, axis) new("UIAspectRatioConstraint", { AspectRatio = r or 1, DominantAxis = axis or Enum.DominantAxis.Width }, o) end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(r, 0) }, o) end
local function rim(o, t, color)
	local s = new("UIStroke", { Name = "Rim", Thickness = t, Color = color or C(255, 255, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	if not color then new("UIGradient", { Name = "Gold", Color = GOLD, Rotation = 35 }, s) end
	return s
end
local function core(o, seq) new("UIGradient", { Name = "Core", Rotation = 90, Color = seq }, o) end
local function label(name, props, parent)
	local base = { Name = name, BackgroundTransparency = 1, TextScaled = true, FontFace = F_BODY, TextColor3 = C(236, 230, 250) }
	for k, v in pairs(props) do base[k] = v end
	return new("TextLabel", base, parent)
end
local function img(name, image, props, parent)
	local base = { Name = name, Image = image, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), ScaleType = Enum.ScaleType.Fit }
	for k, v in pairs(props) do base[k] = v end
	return new("ImageLabel", base, parent)
end
local function gloss(o, z)
	local g = new("Frame", { Name = "Gloss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.06),
		Size = UDim2.fromScale(0.92, 0.4), BackgroundColor3 = C(255, 255, 255), BackgroundTransparency = 0.8, ZIndex = z }, o)
	corner(g, 0.5)
	new("UIGradient", { Name = "Fade", Rotation = 90, Transparency = NS({ NK(0, 0.1), NK(1, 1) }) }, g)
end
local function pill(name, props, seq, text, parent)
	local b = new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = C(255, 255, 255), Selectable = true }, parent)
	for k, v in pairs(props) do (b :: any)[k] = v end
	corner(b, 0.32)
	core(b, seq)
	rim(b, 2)
	new("UIScale", { Name = "Pop" }, b)
	gloss(b, b.ZIndex + 1)
	if text then
		local t = label("ButtonText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.56),
			Text = text, FontFace = F_LABEL, TextColor3 = C(255, 255, 255), ZIndex = b.ZIndex + 3 }, b)
		new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 2 }, t)
	end
	return b
end

local old = SG:FindFirstChild("AreasGUI")
if old then old:Destroy() end
local gui = new("ScreenGui", { Name = "AreasGUI", Enabled = false, ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 5,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, SG)
new("Frame", { Name = "Overlay", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(8, 4, 18), BackgroundTransparency = 0.45,
	Visible = false, Active = true, ZIndex = 0 }, gui)

local main = new("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.49),
	Size = UDim2.fromScale(0.78, 0.76), BackgroundTransparency = 1, ZIndex = 2 }, gui)
aspect(main, 1.75)
local panel = new("Frame", { Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 1 }, main)
corner(panel, 0.03)
new("UIGradient", { Name = "Core", Rotation = 90, Color = CS({ CK(0, C(62, 40, 116)), CK(0.4, C(32, 20, 66)), CK(1, C(14, 9, 28)) }) }, panel)
rim(panel, 3)
local inner = new("Frame", { Name = "Inner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.985, 0.972), BackgroundTransparency = 1, ZIndex = 1 }, panel)
corner(inner, 0.028)
new("UIStroke", { Name = "Line", Color = C(196, 140, 255), Thickness = 1, Transparency = 0.5 }, inner)
local eng = img("Engraving", IMG.Engraving, { Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(3, 0.95), ImageTransparency = 0.93, ZIndex = 1 }, panel)
aspect(eng, 1, Enum.DominantAxis.Height)
for i, pos in ipairs({ Vector2.new(0.012, 0.022), Vector2.new(0.988, 0.022), Vector2.new(0.012, 0.978), Vector2.new(0.988, 0.978) }) do
	local stud = new("Frame", { Name = "Stud" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(pos.X, pos.Y),
		Size = UDim2.fromScale(3, 0.045), BackgroundColor3 = C(255, 255, 255), Rotation = 45, ZIndex = 3 }, panel)
	aspect(stud, 1, Enum.DominantAxis.Height)
	corner(stud, 0.25)
	new("UIGradient", { Name = "Gold", Color = GOLD, Rotation = 45 }, stud)
	local gem = new("Frame", { Name = "StudGem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.48, 0.48), BackgroundColor3 = C(255, 255, 255), ZIndex = 4 }, stud)
	corner(gem, 0.3)
	new("UIGradient", { Rotation = 90, Color = CS(C(198, 124, 255), C(92, 34, 176)) }, gem)
end

-- Header ribbon (its Core is recoloured to the active category by the controller)
local header = new("Frame", { Name = "Header", Position = UDim2.fromScale(0.012, -0.065), Size = UDim2.fromScale(0.27, 0.13),
	BackgroundTransparency = 1, ZIndex = 5 }, main)
local plate = new("Frame", { Name = "Plate", Position = UDim2.fromScale(0.16, 0.2), Size = UDim2.fromScale(0.84, 0.6),
	BackgroundColor3 = C(255, 255, 255), ZIndex = 5 }, header)
corner(plate, 0.5)
core(plate, CS(C(196, 110, 255), C(70, 28, 150)))
rim(plate, 3)
gloss(plate, 6)
local title = label("Title", { Position = UDim2.fromScale(0.3, 0.18), Size = UDim2.fromScale(0.64, 0.64), Text = "AREAS",
	FontFace = F_LABEL, TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, header)
new("UIGradient", { Name = "Gold", Rotation = 90, Color = LABEL_GOLD }, title)
new("UIStroke", { Name = "Outline", Color = C(56, 24, 8), Thickness = 2.5 }, title)
local emblem = new("Frame", { Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.14, 0.5),
	Size = UDim2.fromScale(3, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 9 }, header)
aspect(emblem, 1, Enum.DominantAxis.Height)
corner(emblem, 1)
core(emblem, CS(C(255, 221, 128), C(206, 122, 30)))
rim(emblem, 3)
local rays = img("Rays", IMG.Burst, { Size = UDim2.fromScale(1.9, 1.9), ImageTransparency = 0.5, ZIndex = 8 }, emblem)
new("UIGradient", { Name = "Tint", Color = CS(C(255, 236, 170), C(255, 170, 60)) }, rays)
gloss(emblem, 10)
img("Icon", IMG.Compass, { Size = UDim2.fromScale(0.7, 0.7), ZIndex = 11 }, emblem)

-- Search
local topBar = new("Frame", { Name = "TopBar", Position = UDim2.fromScale(0.33, 0.028), Size = UDim2.fromScale(0.59, 0.072),
	BackgroundTransparency = 1, ZIndex = 5 }, main)
local search = new("TextBox", { Name = "SearchBar", Size = UDim2.fromScale(1, 1), Text = "", PlaceholderText = "Search areas...",
	PlaceholderColor3 = C(150, 136, 180), ClearTextOnFocus = false, TextScaled = true, FontFace = F_BODY, TextColor3 = C(240, 236, 250),
	TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = C(16, 10, 32), BackgroundTransparency = 0.05, ZIndex = 6 }, topBar)
corner(search, 0.3)
new("UIStroke", { Name = "Line", Color = C(150, 100, 230), Thickness = 1.2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, search)
new("UIPadding", { PaddingLeft = UDim.new(0.06, 0), PaddingRight = UDim.new(0.03, 0), PaddingTop = UDim.new(0.24, 0), PaddingBottom = UDim.new(0.24, 0) }, search)
new("UITextSizeConstraint", { MaxTextSize = 22 }, search)
local sIcon = img("SearchIcon", IMG.Search, { Position = UDim2.fromScale(0.025, 0.5), Size = UDim2.fromScale(0.05, 0.55), ImageColor3 = C(200, 180, 240), ZIndex = 7 }, topBar)
aspect(sIcon, 1, Enum.DominantAxis.Height)

-- Close (the only way this screen closes; gamepad B = this button)
local close = new("TextButton", { Name = "CloseButton", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.982, 0.035),
	Size = UDim2.fromScale(3, 0.1), Text = "", AutoButtonColor = false, BackgroundColor3 = C(255, 255, 255), ZIndex = 9, Selectable = true }, main)
aspect(close, 1, Enum.DominantAxis.Height)
corner(close, 1)
core(close, CS(C(255, 130, 110), C(176, 30, 44)))
rim(close, 2.5)
new("UIScale", { Name = "Pop" }, close)
gloss(close, 10)
local cx = label("ButtonText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.56, 0.56),
	Text = "X", FontFace = F_LABEL, TextColor3 = C(255, 255, 255), ZIndex = 12 }, close)
new("UIStroke", { Name = "Outline", Color = C(70, 10, 16), Thickness = 2 }, cx)

-- Category tabs + Add Waypoint
local tabs = new("Frame", { Name = "Tabs", Position = UDim2.fromScale(0.018, 0.13), Size = UDim2.fromScale(0.17, 0.66), BackgroundTransparency = 1, ZIndex = 4 }, main)
new("UIListLayout", { Padding = UDim.new(0.018, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabs)
local tab = new("TextButton", { Name = "TabTemplate", Visible = false, Size = UDim2.fromScale(1, 0.13), Text = "", AutoButtonColor = false,
	BackgroundColor3 = C(255, 255, 255), ZIndex = 5, Selectable = true }, tabs)
corner(tab, 0.28)
core(tab, NIGHT)
rim(tab, 1.5)
new("UIScale", { Name = "Pop" }, tab)
gloss(tab, 6)
local tIcon = img("Icon", IMG.Compass, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.06, 0.5), Size = UDim2.fromScale(3, 0.62), ZIndex = 8 }, tab)
aspect(tIcon, 1, Enum.DominantAxis.Height)
local tLabel = label("Label", { Position = UDim2.fromScale(0.3, 0.2), Size = UDim2.fromScale(0.64, 0.6), Text = "Upgrade", FontFace = F_LABEL,
	TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, tab)
new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 1.5 }, tLabel)
new("UITextSizeConstraint", { MaxTextSize = 27, MinTextSize = 8 }, tLabel)
local hint = label("Hint", { Position = UDim2.fromScale(0.018, 0.8), Size = UDim2.fromScale(0.17, 0.05), Text = "Click an area to travel there.",
	FontFace = F_BOLD, TextColor3 = C(190, 176, 220), ZIndex = 5 }, main)
new("UITextSizeConstraint", { MaxTextSize = 15 }, hint)
local wp = pill("WaypointButton", { Position = UDim2.fromScale(0.018, 0.865), Size = UDim2.fromScale(0.17, 0.09), ZIndex = 6 },
	CS(C(156, 240, 122), C(28, 138, 72)), "Add Waypoint", main)

-- Content
local cPlate = new("Frame", { Name = "ContentPlate", Position = UDim2.fromScale(0.205, 0.13), Size = UDim2.fromScale(0.778, 0.84),
	BackgroundColor3 = C(14, 9, 28), BackgroundTransparency = 0.15, ZIndex = 3 }, main)
corner(cPlate, 0.03)
new("UIStroke", { Name = "Line", Color = C(150, 100, 230), Thickness = 1, Transparency = 0.45 }, cPlate)
local content = new("ScrollingFrame", { Name = "Content", Position = UDim2.fromScale(0.015, 0.02), Size = UDim2.fromScale(0.97, 0.96),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = C(230, 180, 90),
	CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 4, Selectable = false }, cPlate)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0.012, 0),
	SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, content)
new("UIPadding", { PaddingRight = UDim.new(0.015, 0), PaddingBottom = UDim.new(0.02, 0) }, content)
local empty = label("Empty", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.07),
	Text = "No area matches your search.", FontFace = F_BOLD, TextColor3 = C(170, 156, 200), Visible = false, ZIndex = 5 }, cPlate)
new("UITextSizeConstraint", { MaxTextSize = 22 }, empty)

-- ===== Templates =====
local T = new("Folder", { Name = "Templates" }, gui)
-- Section header: full-width row (height = width / 20) -- icon, title in the category colour, glowing underline
local hd = new("Frame", { Name = "HeaderTemplate", Visible = false, Size = UDim2.new(1, 0, 0, 4000), BackgroundTransparency = 1, ZIndex = 5 }, T)
aspect(hd, 20)
local hIcon = img("Icon", IMG.Compass, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.005, 0.45), Size = UDim2.fromScale(3, 0.72), ZIndex = 6 }, hd)
aspect(hIcon, 1, Enum.DominantAxis.Height)
local hT = label("Title", { Position = UDim2.fromScale(0.05, 0.08), Size = UDim2.fromScale(0.6, 0.74), Text = "Upgrade Areas", FontFace = F_LABEL,
	TextColor3 = C(196, 110, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, hd)
new("UIStroke", { Name = "Outline", Color = C(14, 8, 26), Thickness = 1.5 }, hT)
local line = new("Frame", { Name = "Line", Position = UDim2.fromScale(0.005, 0.86), Size = UDim2.fromScale(0.55, 0.07), BackgroundColor3 = C(196, 110, 255),
	BorderSizePixel = 0, ZIndex = 6 }, hd)
new("UIGradient", { Transparency = NS({ NK(0, 0), NK(0.6, 0.35), NK(1, 1) }) }, line)
-- Card: picture, name, description, favourite star, TRAVEL/OPEN tag (height = width / 2.25)
local card = new("TextButton", { Name = "CardTemplate", Visible = false, Size = UDim2.new(0.322, 0, 0, 4000), Text = "", AutoButtonColor = false,
	BackgroundColor3 = C(30, 20, 56), ZIndex = 5, Selectable = true }, T)
aspect(card, 2.25)
corner(card, 0.08)
rim(card, 2, C(196, 110, 255))
-- the picture layers live in a rounded CanvasGroup (ClipsDescendants would leave square corners)
local clip = new("CanvasGroup", { Name = "Clip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, card)
corner(clip, 0.08)
img("Image", "", { Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, ZIndex = 5 }, clip)
local cIcon = img("Icon", "", { Position = UDim2.fromScale(0.72, 0.42), Size = UDim2.fromScale(3, 0.62), ImageTransparency = 0.15, ZIndex = 5, Visible = false }, clip)
aspect(cIcon, 1, Enum.DominantAxis.Height)
local shade = new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(6, 3, 14), BorderSizePixel = 0, ZIndex = 6 }, clip)
new("UIGradient", { Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.38, 0.85), NK(0.7, 0.35), NK(1, 0.1) }) }, shade)
local cTitle = label("Title", { Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.9, 0.22), Text = "Ascension", FontFace = F_LABEL,
	TextColor3 = C(196, 110, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 }, card)
new("UIStroke", { Name = "Outline", Color = C(10, 6, 20), Thickness = 2 }, cTitle)
local cDesc = label("Desc", { Position = UDim2.fromScale(0.05, 0.73), Size = UDim2.fromScale(0.9, 0.22), Text = "Ascend units beyond their limits.",
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C(238, 232, 250), ZIndex = 7 }, card)
new("UITextSizeConstraint", { MaxTextSize = 15, MinTextSize = 7 }, cDesc)
local tag = label("Tag", { Position = UDim2.fromScale(0.04, 0.07), Size = UDim2.fromScale(0.2, 0.16), Text = "TRAVEL", FontFace = F_BOLD,
	TextColor3 = C(255, 255, 255), BackgroundColor3 = C(10, 6, 22), BackgroundTransparency = 0.3, ZIndex = 8 }, card)
corner(tag, 0.4)
new("UIPadding", { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) }, tag)
local star = new("TextButton", { Name = "Star", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.965, 0.07), Size = UDim2.fromScale(3, 0.24),
	Text = "", AutoButtonColor = false, BackgroundColor3 = C(14, 9, 28), BackgroundTransparency = 0.25, ZIndex = 8, Selectable = true }, card)
aspect(star, 1, Enum.DominantAxis.Height)
corner(star, 0.25)
new("UIStroke", { Color = C(255, 255, 255), Thickness = 1, Transparency = 0.6 }, star)
img("Icon", IMG.StarEmpty, { Size = UDim2.fromScale(0.66, 0.66), ImageColor3 = C(200, 194, 220), ZIndex = 9 }, star)
local sel = new("Frame", { Name = "Select", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 9, Visible = false }, card)
corner(sel, 0.08)
new("UIStroke", { Color = C(255, 236, 160), Thickness = 3 }, sel)

-- Waypoint marker: a BillboardGui adorned (by the controller) to an Attachment over the area. Sized in studs and
-- held at DistanceUpperLimit, so it stays readable from across the map without pixel sizing.
local wpm = new("BillboardGui", { Name = "WaypointTemplate", Enabled = false, Size = UDim2.fromScale(7, 3.2), AlwaysOnTop = true,
	LightInfluence = 0, MaxDistance = 100000, DistanceUpperLimit = 70, StudsOffsetWorldSpace = Vector3.new(0, 7, 0) }, T)
local disc = new("Frame", { Name = "Disc", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(3, 0.55),
	BackgroundColor3 = C(255, 255, 255) }, wpm)
aspect(disc, 1, Enum.DominantAxis.Height)
corner(disc, 1)
core(disc, CS(C(124, 204, 255), C(34, 82, 198)))
rim(disc, 2)
img("Icon", IMG.Compass, { Size = UDim2.fromScale(0.7, 0.7), ZIndex = 2 }, disc)
local wName = label("Name", { Position = UDim2.fromScale(0, 0.56), Size = UDim2.fromScale(1, 0.26), Text = "Sky Temple", FontFace = F_LABEL,
	TextColor3 = C(255, 240, 200) }, wpm)
new("UIStroke", { Color = C(10, 6, 20), Thickness = 2 }, wName)
local wDist = label("Distance", { Position = UDim2.fromScale(0, 0.82), Size = UDim2.fromScale(1, 0.18), Text = "120m", FontFace = F_BOLD,
	TextColor3 = C(220, 230, 255) }, wpm)
new("UIStroke", { Color = C(10, 6, 20), Thickness = 1.5 }, wDist)

return "AreasGUI built"
