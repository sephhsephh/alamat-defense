-- inventory_build.luau (B145) -- run with execute_luau in the LOBBY (Edit). Rebuilds StarterGui.ItemsGUI.Main as the
-- Alamat-style Items screen (user refs B145: category tabs, search + filters, owned-only grid with counts,
-- details with rarity/type line + showcase + stats + description + possible rewards, an amount stepper, the
-- Use/Feed/Open button, and a rail: Favourite / Lock / View / Obtainments / Discard; plus the View showcase overlay).
-- Old Main is kept in ServerStorage._UIBackup_B145. FilterPanel + Overlay + HoverPreview are untouched.
-- Everything is a real Instance; ItemsController only clones the *Template parts, fills and wires them.

local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")
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
	MagicCircle = "rbxassetid://113290594421442", Engraving = "rbxassetid://95270696231518", GlowRing = "rbxassetid://9864075653",
	Burst = "rbxassetid://7229481183", Streak = "rbxassetid://3052949762", Sparkle = "rbxassetid://6997866340",
	Inventory = "rbxassetid://93235033309096", Filter = "rbxassetid://7964618035", Search = "rbxassetid://15999597350",
	Star = "rbxassetid://3057073083", Lock = "rbxassetid://187897034", View = "rbxassetid://15875255096",
	Trash = "rbxassetid://106722143856313",
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
local function core(o, seq, rot) new("UIGradient", { Name = "Core", Rotation = rot or 90, Color = seq }, o) end
local function label(name, props, parent)
	local base = { Name = name, BackgroundTransparency = 1, TextScaled = true, FontFace = F_BODY, TextColor3 = C(236, 230, 250) }
	for k, v in pairs(props) do base[k] = v end
	local l = new("TextLabel", base, parent)
	return l
end
local function goldText(l, outline)
	new("UIGradient", { Name = "Gold", Rotation = 90, Color = LABEL_GOLD }, l)
	new("UIStroke", { Name = "Outline", Color = C(56, 24, 8), Thickness = outline or 2 }, l)
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
local function shine(o, z, r)
	local clip = new("CanvasGroup", { Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z }, o)
	corner(clip, r)
	local st = img("Streak", IMG.Streak, { Position = UDim2.fromScale(-0.6, 0.5), Size = UDim2.fromScale(1.6, 1.4),
		ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0.3, Rotation = -12, ZIndex = z }, clip)
	new("UIGradient", { Name = "Tint", Color = CS(C(255, 255, 255), C(255, 236, 170)) }, st)
end
local function inset(name, props, parent)
	local f = new("Frame", { Name = name, BackgroundColor3 = C(14, 9, 28), BackgroundTransparency = 0.15 }, parent)
	for k, v in pairs(props) do (f :: any)[k] = v end
	corner(f, 0.03)
	new("UIStroke", { Name = "Line", Color = C(150, 100, 230), Thickness = 1, Transparency = 0.45 }, f)
	return f
end
-- a gem pill button
local function pill(name, props, seq, text, parent)
	local b = new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = C(255, 255, 255), Selectable = true }, parent)
	for k, v in pairs(props) do (b :: any)[k] = v end
	corner(b, 0.32)
	core(b, seq)
	rim(b, 2)
	new("UIScale", { Name = "Pop" }, b)
	gloss(b, b.ZIndex + 1)
	if text then
		local t = label("ButtonText", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.62),
			Text = text, FontFace = F_LABEL, TextColor3 = C(255, 255, 255), ZIndex = b.ZIndex + 3 }, b)
		new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 2 }, t)
	end
	return b
end
-- a square gem icon button (rail / stepper)
local function gemButton(name, icon, seq, parent, z)
	local b = new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundColor3 = C(255, 255, 255),
		Size = UDim2.fromScale(1, 1), Selectable = true, ZIndex = z or 6 }, parent)
	aspect(b, 1, Enum.DominantAxis.Width)
	corner(b, 0.24)
	core(b, seq)
	rim(b, 1.8)
	new("UIScale", { Name = "Pop" }, b)
	gloss(b, b.ZIndex + 1)
	img("Icon", icon, { Size = UDim2.fromScale(0.6, 0.6), ZIndex = b.ZIndex + 2 }, b)
	return b
end

local gui = SG:FindFirstChild("ItemsGUI")
assert(gui, "StarterGui.ItemsGUI missing")
local bk = SS:FindFirstChild("_UIBackup_B145") or new("Folder", { Name = "_UIBackup_B145" }, SS)
local oldMain = gui:FindFirstChild("Main")
if oldMain and not bk:FindFirstChild("ItemsGUI_Main") then
	local c = oldMain:Clone(); c.Name = "ItemsGUI_Main"; c.Parent = bk
end
if oldMain then oldMain:Destroy() end
local oldView = gui:FindFirstChild("ViewOverlay")
if oldView then oldView:Destroy() end
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 5 -- above the HUD (1): the rail sits where the HUD side panels are

-- ===== Main =====
local main = new("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.49),
	Size = UDim2.fromScale(0.8, 0.76), BackgroundTransparency = 1, ZIndex = 2 }, gui)
aspect(main, 1.85)

local panel = new("Frame", { Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 1 }, main)
corner(panel, 0.03)
core(panel, CS({ CK(0, C(62, 40, 116)), CK(0.4, C(32, 20, 66)), CK(1, C(14, 9, 28)) }))
rim(panel, 3)
local inner = new("Frame", { Name = "Inner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.985, 0.972), BackgroundTransparency = 1, ZIndex = 1 }, panel)
corner(inner, 0.028)
new("UIStroke", { Name = "Line", Color = C(196, 140, 255), Thickness = 1, Transparency = 0.5 }, inner)
local eng = img("Engraving", IMG.Engraving, { Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(3, 0.95), ImageTransparency = 0.92, ZIndex = 1 }, panel)
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

-- Header ribbon + emblem (top-left, riding the edge)
local header = new("Frame", { Name = "Header", Position = UDim2.fromScale(0.012, -0.065), Size = UDim2.fromScale(0.3, 0.13),
	BackgroundTransparency = 1, ZIndex = 5 }, main)
local plate = new("Frame", { Name = "Plate", Position = UDim2.fromScale(0.16, 0.2), Size = UDim2.fromScale(0.84, 0.6),
	BackgroundColor3 = C(255, 255, 255), ZIndex = 5 }, header)
corner(plate, 0.5)
core(plate, CS(C(122, 70, 210), C(44, 20, 96)))
rim(plate, 3)
gloss(plate, 6)
local title = label("Title", { Position = UDim2.fromScale(0.28, 0.18), Size = UDim2.fromScale(0.68, 0.64), Text = "INVENTORY",
	FontFace = F_LABEL, TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, header)
goldText(title, 2.5)
local emblem = new("Frame", { Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.13, 0.5),
	Size = UDim2.fromScale(3, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 9 }, header)
aspect(emblem, 1, Enum.DominantAxis.Height)
corner(emblem, 1)
core(emblem, CS(C(255, 221, 128), C(206, 122, 30)))
rim(emblem, 3)
local rays = img("Rays", IMG.Burst, { Size = UDim2.fromScale(1.9, 1.9), ImageTransparency = 0.5, ZIndex = 8 }, emblem)
new("UIGradient", { Name = "Tint", Color = CS(C(255, 236, 170), C(255, 170, 60)) }, rays)
gloss(emblem, 10)
img("Icon", IMG.Inventory, { Size = UDim2.fromScale(0.68, 0.68), ZIndex = 11 }, emblem)

-- Top bar: search + filters
local topBar = new("Frame", { Name = "TopBar", Position = UDim2.fromScale(0.36, 0.028), Size = UDim2.fromScale(0.555, 0.072),
	BackgroundTransparency = 1, ZIndex = 5 }, main)
local search = new("TextBox", { Name = "SearchBar", Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.68, 1), Text = "",
	PlaceholderText = "Search items...", PlaceholderColor3 = C(150, 136, 180), ClearTextOnFocus = false, TextScaled = true,
	FontFace = F_BODY, TextColor3 = C(240, 236, 250), TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = C(16, 10, 32),
	BackgroundTransparency = 0.05, ZIndex = 6 }, topBar)
corner(search, 0.3)
new("UIStroke", { Name = "Line", Color = C(150, 100, 230), Thickness = 1.2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, search)
new("UIPadding", { PaddingLeft = UDim.new(0.1, 0), PaddingRight = UDim.new(0.04, 0), PaddingTop = UDim.new(0.24, 0), PaddingBottom = UDim.new(0.24, 0) }, search)
new("UITextSizeConstraint", { MaxTextSize = 22 }, search)
local sIcon = img("SearchIcon", IMG.Search, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.035, 0.5), Size = UDim2.fromScale(0.06, 0.55),
	ImageColor3 = C(200, 180, 240), ZIndex = 7 }, topBar)
aspect(sIcon, 1, Enum.DominantAxis.Height)
local filters = pill("FiltersButton", { Position = UDim2.fromScale(0.71, 0), Size = UDim2.fromScale(0.29, 1), ZIndex = 6 }, NIGHT, nil, topBar)
local fIcon = img("Icon", IMG.Filter, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.1, 0.5), Size = UDim2.fromScale(3, 0.56), ZIndex = 9 }, filters)
aspect(fIcon, 1, Enum.DominantAxis.Height)
local fText = label("ButtonText", { Position = UDim2.fromScale(0.36, 0.2), Size = UDim2.fromScale(0.56, 0.6), Text = "Filters",
	FontFace = F_LABEL, TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9 }, filters)
new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 1.5 }, fText)

-- Close (the ONLY way this screen closes; gamepad B = this button)
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

-- Tabs (left)
local tabs = new("Frame", { Name = "Tabs", Position = UDim2.fromScale(0.018, 0.13), Size = UDim2.fromScale(0.15, 0.84), BackgroundTransparency = 1, ZIndex = 4 }, main)
new("UIListLayout", { Padding = UDim.new(0.014, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, tabs)
local tab = new("TextButton", { Name = "TabTemplate", Visible = false, Size = UDim2.fromScale(1, 0.095), Text = "", AutoButtonColor = false,
	BackgroundColor3 = C(255, 255, 255), ZIndex = 5, Selectable = true }, tabs)
corner(tab, 0.28)
core(tab, NIGHT)
rim(tab, 1.5)
new("UIScale", { Name = "Pop" }, tab)
gloss(tab, 6)
local tIcon = img("Icon", IMG.Inventory, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(3, 0.7), ZIndex = 8 }, tab)
aspect(tIcon, 1, Enum.DominantAxis.Height)
local tLabel = label("Label", { Position = UDim2.fromScale(0.29, 0.2), Size = UDim2.fromScale(0.5, 0.6), Text = "All Items", FontFace = F_LABEL,
	TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8 }, tab)
new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 1.5 }, tLabel)
local tCount = label("Count", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.95, 0.5), Size = UDim2.fromScale(0.17, 0.52), Text = "0",
	FontFace = F_BOLD, TextColor3 = C(255, 236, 190), BackgroundTransparency = 0.25, BackgroundColor3 = C(10, 6, 22), ZIndex = 8 }, tab)
corner(tCount, 0.5)
local summary = label("Summary", { LayoutOrder = 999, Size = UDim2.fromScale(1, 0.05), Text = "0 items", FontFace = F_BOLD,
	TextColor3 = C(190, 176, 220), ZIndex = 5 }, tabs)
new("UITextSizeConstraint", { MaxTextSize = 16 }, summary)

-- Grid (middle)
local gridPlate = inset("GridPlate", { Position = UDim2.fromScale(0.18, 0.13), Size = UDim2.fromScale(0.445, 0.84), ZIndex = 3 }, main)
local grid = new("ScrollingFrame", { Name = "Grid", Position = UDim2.fromScale(0.02, 0.02), Size = UDim2.fromScale(0.96, 0.96),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, ScrollBarImageColor3 = C(230, 180, 90),
	CanvasSize = UDim2.fromScale(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 4, Selectable = false }, gridPlate)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0.02, 0),
	SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, grid)
new("UIPadding", { PaddingLeft = UDim.new(0.01, 0), PaddingTop = UDim.new(0.01, 0), PaddingRight = UDim.new(0.02, 0), PaddingBottom = UDim.new(0.02, 0) }, grid)
local empty = label("Empty", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.8, 0.08),
	Text = "No items here yet.", FontFace = F_BOLD, TextColor3 = C(170, 156, 200), Visible = false, ZIndex = 5 }, gridPlate)
new("UITextSizeConstraint", { MaxTextSize = 22 }, empty)
-- Card marks: cloned onto each card (favourite star / lock), top-right
local marks = new("Frame", { Name = "MarksTemplate", Visible = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.03),
	Size = UDim2.fromScale(0.5, 0.22), BackgroundTransparency = 1, ZIndex = 20 }, gridPlate)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }, marks)
local mFav = img("Fav", IMG.Star, { Size = UDim2.fromScale(3, 1), ImageColor3 = C(255, 214, 64), ZIndex = 21, LayoutOrder = 1 }, marks)
aspect(mFav, 1, Enum.DominantAxis.Height)
local mLock = img("Lock", IMG.Lock, { Size = UDim2.fromScale(3, 1), ImageColor3 = C(240, 236, 250), ZIndex = 21, LayoutOrder = 2 }, marks)
aspect(mLock, 1, Enum.DominantAxis.Height)

-- Details (right)
local det = inset("Detail", { Position = UDim2.fromScale(0.635, 0.13), Size = UDim2.fromScale(0.29, 0.84), ZIndex = 3 }, main)
label("TypeLine", { Position = UDim2.fromScale(0.05, 0.018), Size = UDim2.fromScale(0.9, 0.04), Text = "Mythic Reward Box", RichText = true,
	FontFace = F_BOLD, TextColor3 = C(220, 140, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, det)
local nm = label("NameLabel", { Position = UDim2.fromScale(0.05, 0.058), Size = UDim2.fromScale(0.9, 0.065), Text = "Infernal Chest",
	FontFace = F_LABEL, TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5 }, det)
goldText(nm, 2)
local show = new("CanvasGroup", { Name = "Showcase", Position = UDim2.fromScale(0.05, 0.135), Size = UDim2.fromScale(0.9, 0.355),
	BackgroundTransparency = 1, ZIndex = 4 }, det)
corner(show, 0.06)
-- the rarity gradient lives on a background layer: a UIGradient ON a CanvasGroup tints everything inside it (the icon too)
local showBg = new("Frame", { Name = "Bg", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 3 }, show)
new("UIGradient", { Name = "Tier", Rotation = 135, Color = CS(C(255, 90, 160), C(120, 30, 90)) }, showBg)
local shade = new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = 0.35, ZIndex = 4 }, show)
new("UIGradient", { Rotation = 90, Transparency = NS({ NK(0, 0.9), NK(0.6, 0.55), NK(1, 0.1) }) }, shade)
local pat = img("Pattern", IMG.MagicCircle, { Size = UDim2.fromScale(3, 1.25), ImageTransparency = 0.82, ZIndex = 4 }, show)
aspect(pat, 1, Enum.DominantAxis.Height)
local sRays = img("Rays", IMG.Burst, { Size = UDim2.fromScale(3, 1.5), ImageTransparency = 0.55, ZIndex = 4 }, show)
aspect(sRays, 1, Enum.DominantAxis.Height)
local sGlow = img("Glow", IMG.GlowRing, { Size = UDim2.fromScale(3, 0.8), ImageTransparency = 0.35, ZIndex = 4 }, show)
aspect(sGlow, 1, Enum.DominantAxis.Height)
local sIconImg = img("Icon", "", { Size = UDim2.fromScale(3, 0.72), ZIndex = 5 }, show)
aspect(sIconImg, 1, Enum.DominantAxis.Height)
new("UIScale", { Name = "Bob" }, sIconImg)
local showRim = new("Frame", { Name = "ShowcaseRim", Position = show.Position, Size = show.Size, BackgroundTransparency = 1, ZIndex = 6 }, det)
corner(showRim, 0.06)
rim(showRim, 2)
local stats = new("Frame", { Name = "Stats", Position = UDim2.fromScale(0.05, 0.505), Size = UDim2.fromScale(0.9, 0.055), BackgroundTransparency = 1, ZIndex = 5 }, det)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder }, stats)
local stat = new("Frame", { Name = "StatTemplate", Visible = false, Size = UDim2.fromScale(0.485, 1), BackgroundColor3 = C(30, 20, 58), ZIndex = 5 }, stats)
corner(stat, 0.3)
new("UIStroke", { Name = "Line", Color = C(150, 100, 230), Thickness = 1, Transparency = 0.5 }, stat)
label("Label", { Position = UDim2.fromScale(0.07, 0.18), Size = UDim2.fromScale(0.5, 0.64), Text = "Owned", TextColor3 = C(190, 176, 220),
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, stat)
label("Value", { Position = UDim2.fromScale(0.5, 0.18), Size = UDim2.fromScale(0.44, 0.64), Text = "20x", FontFace = F_BOLD,
	TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 6 }, stat)
local descPlate = new("Frame", { Name = "DescPlate", Position = UDim2.fromScale(0.05, 0.575), Size = UDim2.fromScale(0.9, 0.11),
	BackgroundColor3 = C(20, 13, 40), BackgroundTransparency = 0.1, ZIndex = 5 }, det)
corner(descPlate, 0.12)
local desc = label("Desc", { Position = UDim2.fromScale(0.05, 0.1), Size = UDim2.fromScale(0.9, 0.8), Text = "Open for a chance at...",
	TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C(225, 218, 240), ZIndex = 6 }, descPlate)
new("UITextSizeConstraint", { MaxTextSize = 17, MinTextSize = 8 }, desc)
local rewards = new("Frame", { Name = "Rewards", Position = UDim2.fromScale(0.05, 0.692), Size = UDim2.fromScale(0.9, 0.14), BackgroundTransparency = 1, ZIndex = 5, Visible = false }, det)
local rt = label("Title", { Size = UDim2.fromScale(1, 0.26), Text = "Possible Rewards", FontFace = F_BOLD, TextColor3 = C(255, 196, 96),
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, rewards)
new("UITextSizeConstraint", { MaxTextSize = 15 }, rt)
local rl = new("ScrollingFrame", { Name = "List", Position = UDim2.fromScale(0, 0.3), Size = UDim2.fromScale(1, 0.7), BackgroundColor3 = C(40, 10, 16),
	BackgroundTransparency = 0.45, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollingDirection = Enum.ScrollingDirection.X,
	AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = UDim2.fromScale(0, 0), ZIndex = 6, Selectable = false }, rewards)
corner(rl, 0.12)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center }, rl)
new("UIPadding", { PaddingLeft = UDim.new(0.02, 0), PaddingTop = UDim.new(0.08, 0), PaddingBottom = UDim.new(0.08, 0) }, rl)
-- Amount stepper
local amt = new("Frame", { Name = "Amount", Position = UDim2.fromScale(0.05, 0.84), Size = UDim2.fromScale(0.9, 0.055), BackgroundTransparency = 1, ZIndex = 5 }, det)
local function stepBtn(name, x, w, text)
	local b = pill(name, { Position = UDim2.fromScale(x, 0), Size = UDim2.fromScale(w, 1), ZIndex = 6 }, NIGHT, text, amt)
	return b
end
stepBtn("Minus", 0, 0.17, "-")
local val = label("Value", { Position = UDim2.fromScale(0.19, 0), Size = UDim2.fromScale(0.38, 1), Text = "1", FontFace = F_LABEL,
	BackgroundColor3 = C(14, 9, 28), BackgroundTransparency = 0.1, ZIndex = 6 }, amt)
corner(val, 0.32)
new("UIPadding", { PaddingTop = UDim.new(0.18, 0), PaddingBottom = UDim.new(0.18, 0) }, val)
stepBtn("Plus", 0.59, 0.17, "+")
stepBtn("Max", 0.78, 0.22, "MAX")
-- Use button
local use = pill("UseButton", { Position = UDim2.fromScale(0.05, 0.905), Size = UDim2.fromScale(0.9, 0.08), ZIndex = 6 },
	CS(C(156, 240, 122), C(28, 138, 72)), "Use Item", det)
shine(use, 9, 0.32)

-- Rail (far right)
local rail = new("Frame", { Name = "Rail", Position = UDim2.fromScale(0.935, 0.13), Size = UDim2.fromScale(0.048, 0.84), BackgroundTransparency = 1, ZIndex = 5 }, main)
new("UIListLayout", { Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, rail)
for i, row in ipairs({
	{ "FavButton", IMG.Star, "Favorite" }, { "LockButton", IMG.Lock, "Lock" }, { "ViewButton", IMG.View, "View Item" },
	{ "ObtainButton", IMG.Search, "View Obtainments" }, { "DiscardButton", IMG.Trash, "Discard" },
}) do
	local b = gemButton(row[1], row[2], if row[1] == "DiscardButton" then CS(C(150, 60, 70), C(60, 16, 26)) else NIGHT, rail, 6)
	b.LayoutOrder = i
	b:SetAttribute("Tip", row[3])
end
local tip = new("Frame", { Name = "RailTip", Visible = false, AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromScale(0.12, 0.05),
	BackgroundColor3 = C(16, 10, 32), BackgroundTransparency = 0.05, ZIndex = 30 }, main)
corner(tip, 0.4)
new("UIStroke", { Color = C(214, 170, 90), Thickness = 1.2 }, tip)
label("Text", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.88, 0.6), Text = "View Item",
	FontFace = F_BOLD, TextColor3 = C(255, 240, 210), ZIndex = 31 }, tip)

-- ===== View showcase overlay (a reveal: "click anywhere to close" is the allowed exception) =====
local view = new("Frame", { Name = "ViewOverlay", Visible = false, Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(6, 4, 14),
	BackgroundTransparency = 0.08, Active = true, ZIndex = 50 }, gui)
new("UIGradient", { Name = "Vignette", Rotation = 90, Transparency = NS({ NK(0, 0), NK(0.5, 0.22), NK(1, 0) }) }, view)
local vRays = img("Rays", IMG.Burst, { Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(3, 0.95), ImageTransparency = 0.35, ZIndex = 51 }, view)
aspect(vRays, 1, Enum.DominantAxis.Height)
local vCircle = img("Circle", IMG.MagicCircle, { Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(3, 0.6), ImageTransparency = 0.6, ZIndex = 51 }, view)
aspect(vCircle, 1, Enum.DominantAxis.Height)
local vGlow = img("Glow", IMG.GlowRing, { Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(3, 0.5), ImageTransparency = 0.2, ZIndex = 51 }, view)
aspect(vGlow, 1, Enum.DominantAxis.Height)
local vIcon = img("Icon", "", { Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(3, 0.4), ZIndex = 52 }, view)
aspect(vIcon, 1, Enum.DominantAxis.Height)
new("UIScale", { Name = "Bob" }, vIcon)
local vAmt = label("Amount", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.555, 0.66), Size = UDim2.fromScale(0.2, 0.11), Text = "20x",
	FontFace = F_LABEL, TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53 }, view)
new("UIStroke", { Name = "Outline", Color = C(20, 10, 30), Thickness = 3 }, vAmt)
local vTitle = label("Title", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.6, 0.075),
	Text = "Infernal Chest", FontFace = F_LABEL, TextColor3 = C(255, 255, 255), ZIndex = 53 }, view)
goldText(vTitle, 3)
label("Rarity", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.125), Size = UDim2.fromScale(0.4, 0.045),
	Text = "Mythic Reward Box", FontFace = F_LABEL, TextColor3 = C(220, 140, 255), ZIndex = 53 }, view)
local vInfo = new("Frame", { Name = "Info", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.24, 0.3),
	BackgroundColor3 = C(16, 10, 32), BackgroundTransparency = 0.08, ZIndex = 53 }, view)
corner(vInfo, 0.06)
rim(vInfo, 2)
label("Name", { Position = UDim2.fromScale(0.07, 0.06), Size = UDim2.fromScale(0.86, 0.13), Text = "Infernal Chest", FontFace = F_LABEL,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C(255, 236, 190), ZIndex = 54 }, vInfo)
label("Type", { Position = UDim2.fromScale(0.07, 0.2), Size = UDim2.fromScale(0.86, 0.09), Text = "Reward Box", FontFace = F_BOLD,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C(220, 140, 255), ZIndex = 54 }, vInfo)
local vd = label("Desc", { Position = UDim2.fromScale(0.07, 0.33), Size = UDim2.fromScale(0.86, 0.46), Text = "...", TextWrapped = true,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 54 }, vInfo)
new("UITextSizeConstraint", { MaxTextSize = 18 }, vd)
label("Owned", { Position = UDim2.fromScale(0.07, 0.82), Size = UDim2.fromScale(0.86, 0.11), Text = "20x Owned", FontFace = F_BOLD,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C(200, 190, 225), ZIndex = 54 }, vInfo)
local vHint = label("Hint", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.95), Size = UDim2.fromScale(0.4, 0.04),
	Text = "(Click anywhere to close)", FontFace = F_BOLD, TextColor3 = C(230, 225, 245), ZIndex = 53 }, view)
new("UIStroke", { Color = C(10, 6, 20), Thickness = 1.5 }, vHint)
local vSp = new("Frame", { Name = "Sparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 52 }, view)
for i, p in ipairs({ Vector2.new(0.4, 0.3), Vector2.new(0.61, 0.33), Vector2.new(0.63, 0.62), Vector2.new(0.38, 0.64), Vector2.new(0.5, 0.22) }) do
	local s = img("Spark" .. i, IMG.Sparkle, { Position = UDim2.fromScale(p.X, p.Y), Size = UDim2.fromScale(3, 0.05), ZIndex = 52 }, vSp)
	aspect(s, 1, Enum.DominantAxis.Height)
end
new("TextButton", { Name = "CloseCatch", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 60, Selectable = false }, view)

-- bring the existing filter panel above the new main
local fp = gui:FindFirstChild("FilterPanel")
if fp and fp:IsA("GuiObject") then fp.ZIndex = math.max(fp.ZIndex, 20) end
return "ItemsGUI rebuilt"
