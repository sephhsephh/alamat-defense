-- units_hover_build.luau (B147) -- run with execute_luau in the LOBBY (Edit). Rebuilds StarterGui.UnitsGUI.CardHover,
-- the hover card over a unit in the Units grid (user: "overlapping layouts, design improvement, cleaning up buttons").
-- KEEPS every node name the two controllers fill (UnitsController.fillStats/showPreview + UnitsHeroController.onPreview):
--   direct children: UIStroke(+UIGradient), Pop, ViewportFrame, UnitName, TierName, ChipsRow{ElementChip,PlacementChip,
--   LimitChip}, LevelRow{LevelText, XPText, Track.Fill}, BaseStatsFrame{DMG,SPA,RNG}{ImageIcon, TextLabel, Grade},
--   Footer{TraitChip{Dot,Icon,Label}, AscChip{Label, Dot, Stars.Star1..3}, WorthChip{Dot,Label}}
-- New look: portrait on a rarity backdrop (PortraitBg, painted by onPreview), roomy header, three labelled stat tiles,
-- a footer of info pills. Chips are FRAMES now (they were TextButtons that did nothing). Old card: _UIBackup_B147.

local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")
local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local F_LABEL = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local F_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local F_BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local ICON = { DMG = "rbxassetid://2252732140", SPA = "rbxassetid://4034150594", RNG = "rbxassetid://125143421594685",
	StarEmpty = "rbxassetid://130377121632515", Engraving = "rbxassetid://95270696231518" }

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(r, 0) }, o) end
local function aspect(o, r, axis) new("UIAspectRatioConstraint", { AspectRatio = r or 1, DominantAxis = axis or Enum.DominantAxis.Width }, o) end
local function label(name, props, parent)
	local base = { Name = name, BackgroundTransparency = 1, TextScaled = true, FontFace = F_BODY, TextColor3 = C(236, 230, 250), ZIndex = 62 }
	for k, v in pairs(props) do base[k] = v end
	return new("TextLabel", base, parent)
end
-- an info pill: Dot + Label (+ optional Icon), a FRAME with a soft outline
local function pill(name, width, parent, order)
	local p = new("Frame", { Name = name, Size = UDim2.fromScale(width, 1), BackgroundColor3 = C(28, 18, 52), LayoutOrder = order, ZIndex = 62 }, parent)
	corner(p, 0.5)
	new("UIStroke", { Color = C(120, 90, 190), Thickness = 1.2, Transparency = 0.15 }, p)
	local dot = new("Frame", { Name = "Dot", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.08, 0.5), Size = UDim2.fromScale(3, 0.36),
		BackgroundColor3 = C(255, 255, 255), ZIndex = 63 }, p)
	aspect(dot, 1, Enum.DominantAxis.Height)
	corner(dot, 1)
	label("Label", { Position = UDim2.fromScale(0.2, 0.18), Size = UDim2.fromScale(0.74, 0.64), Text = "Label", FontFace = F_BOLD,
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63 }, p)
	return p
end

local gui = SG:FindFirstChild("UnitsGUI")
assert(gui, "UnitsGUI missing")
local old = gui:FindFirstChild("CardHover")
local bk = SS:FindFirstChild("_UIBackup_B147") or new("Folder", { Name = "_UIBackup_B147" }, SS)
if old and not bk:FindFirstChild("CardHover") then old:Clone().Parent = bk end
if old then old:Destroy() end

local card = new("Frame", { Name = "CardHover", Visible = false, Size = UDim2.fromScale(0.235, 0.29), BackgroundColor3 = C(255, 255, 255), ZIndex = 60 }, gui)
aspect(card, 1.32)
corner(card, 0.06)
new("UIGradient", { Name = "Core", Rotation = 90, Color = CS({ CK(0, C(58, 38, 108)), CK(0.45, C(30, 19, 62)), CK(1, C(14, 9, 28)) }) }, card)
local stroke = new("UIStroke", { Thickness = 2.5, Color = C(255, 255, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
new("UIGradient", { Color = CS(C(255, 214, 120), C(196, 110, 255)) }, stroke) -- recoloured to the tier by the controllers
new("UIScale", { Name = "Pop" }, card)
local eng = new("ImageLabel", { Name = "Engraving", Image = ICON.Engraving, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.fromScale(1.05, -0.08), Size = UDim2.fromScale(3, 0.75), ImageTransparency = 0.9, ZIndex = 60 }, card)
aspect(eng, 1, Enum.DominantAxis.Height)

-- Portrait on a rarity backdrop (PortraitBg's UIGradient "Tier" is painted by onPreview)
local pbg = new("Frame", { Name = "PortraitBg", Position = UDim2.fromScale(0.035, 0.05), Size = UDim2.fromScale(0.29, 0.385), BackgroundColor3 = C(255, 255, 255), ZIndex = 61 }, card)
corner(pbg, 0.12)
new("UIGradient", { Name = "Tier", Rotation = 135, Color = CS(C(196, 110, 255), C(60, 24, 110)) }, pbg)
new("UIStroke", { Color = C(255, 236, 190), Thickness = 1.5, Transparency = 0.3 }, pbg)
local pshade = new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = 0.25, ZIndex = 61 }, pbg)
corner(pshade, 0.12)
new("UIGradient", { Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.55, 0.7), NK(1, 0.15) }) }, pshade)
local vf = new("ViewportFrame", { Name = "ViewportFrame", Position = pbg.Position, Size = pbg.Size, BackgroundTransparency = 1, ZIndex = 62,
	Ambient = C(200, 200, 200), LightColor = C(140, 140, 140), LightDirection = Vector3.new(-1, -1, -1) }, card)
new("WorldModel", { Name = "WorldModel" }, vf)

-- Name / rarity / chips / level
label("UnitName", { Position = UDim2.fromScale(0.36, 0.05), Size = UDim2.fromScale(0.6, 0.105), Text = "Unit Name", FontFace = F_LABEL,
	TextColor3 = C(255, 244, 220), TextXAlignment = Enum.TextXAlignment.Left }, card)
new("UIStroke", { Name = "Outline", Color = C(20, 10, 34), Thickness = 1.5 }, card.UnitName)
label("TierName", { Position = UDim2.fromScale(0.36, 0.158), Size = UDim2.fromScale(0.6, 0.065), Text = "Mythic Unit", FontFace = F_BOLD,
	TextColor3 = C(220, 140, 255), TextXAlignment = Enum.TextXAlignment.Left }, card)
local chips = new("Frame", { Name = "ChipsRow", Position = UDim2.fromScale(0.36, 0.24), Size = UDim2.fromScale(0.6, 0.075), BackgroundTransparency = 1, ZIndex = 61 }, card)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.025, 0), SortOrder = Enum.SortOrder.LayoutOrder,
	VerticalAlignment = Enum.VerticalAlignment.Center }, chips)
pill("ElementChip", 0.33, chips, 1)
pill("PlacementChip", 0.35, chips, 2)
pill("LimitChip", 0.27, chips, 3)
local lr = new("Frame", { Name = "LevelRow", Position = UDim2.fromScale(0.36, 0.335), Size = UDim2.fromScale(0.6, 0.1), BackgroundTransparency = 1, ZIndex = 61 }, card)
label("LevelText", { Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(0.45, 0.5), Text = "Lvl 1", FontFace = F_LABEL,
	TextColor3 = C(255, 236, 190), TextXAlignment = Enum.TextXAlignment.Left }, lr)
label("XPText", { Position = UDim2.fromScale(0.45, 0.05), Size = UDim2.fromScale(0.55, 0.42), Text = "150 XP Left", FontFace = F_BOLD,
	TextColor3 = C(190, 176, 220), TextXAlignment = Enum.TextXAlignment.Right }, lr)
local track = new("Frame", { Name = "Track", Position = UDim2.fromScale(0, 0.64), Size = UDim2.fromScale(1, 0.26), BackgroundColor3 = C(16, 10, 32), ZIndex = 62 }, lr)
corner(track, 1)
new("UIStroke", { Color = C(120, 90, 190), Thickness = 1, Transparency = 0.3 }, track)
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.4, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 63 }, track)
corner(fill, 1)
new("UIGradient", { Color = CS(C(255, 214, 110), C(255, 150, 60)) }, fill)

local div = new("Frame", { Name = "Divider", Position = UDim2.fromScale(0.05, 0.475), Size = UDim2.fromScale(0.9, 0.006), BackgroundColor3 = C(255, 214, 120),
	BorderSizePixel = 0, ZIndex = 61 }, card)
new("UIGradient", { Transparency = NS({ NK(0, 1), NK(0.2, 0.2), NK(0.8, 0.2), NK(1, 1) }) }, div)

-- Stat tiles: icon, value, grade badge, caption
local bsf = new("Frame", { Name = "BaseStatsFrame", Position = UDim2.fromScale(0.035, 0.51), Size = UDim2.fromScale(0.93, 0.215), BackgroundTransparency = 1, ZIndex = 61 }, card)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center }, bsf)
for i, row in ipairs({ { "DMG", "Damage", C(255, 120, 90) }, { "SPA", "Speed", C(120, 200, 255) }, { "RNG", "Range", C(130, 230, 140) } }) do
	local t = new("Frame", { Name = row[1], Size = UDim2.fromScale(0.32, 1), BackgroundColor3 = C(24, 15, 46), LayoutOrder = i, ZIndex = 62 }, bsf)
	corner(t, 0.16)
	new("UIStroke", { Color = row[3], Thickness = 1.2, Transparency = 0.35 }, t)
	local ic = new("ImageLabel", { Name = "ImageIcon", Image = ICON[row[1]], BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.07, 0.4), Size = UDim2.fromScale(3, 0.42), ScaleType = Enum.ScaleType.Fit, ImageColor3 = row[3], ZIndex = 63 }, t)
	aspect(ic, 1, Enum.DominantAxis.Height)
	label("TextLabel", { Position = UDim2.fromScale(0.38, 0.12), Size = UDim2.fromScale(0.58, 0.5), Text = "80", FontFace = F_LABEL,
		TextColor3 = C(255, 255, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63 }, t)
	local g = label("Grade", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.97, 0.04), Size = UDim2.fromScale(0.3, 0.3), Text = "S",
		FontFace = F_LABEL, ZIndex = 64 }, t)
	new("UIStroke", { Color = C(10, 6, 20), Thickness = 1.2 }, g)
	label("Caption", { Position = UDim2.fromScale(0.07, 0.66), Size = UDim2.fromScale(0.86, 0.26), Text = row[2], FontFace = F_BOLD,
		TextColor3 = C(170, 158, 205), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 63 }, t)
end

-- Footer: trait / ascension / worth pills
local foot = new("Frame", { Name = "Footer", Position = UDim2.fromScale(0.035, 0.76), Size = UDim2.fromScale(0.93, 0.095), BackgroundTransparency = 1, ZIndex = 61 }, card)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder,
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center }, foot)
local trait = pill("TraitChip", 0.4, foot, 1)
local ti = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5),
	Size = UDim2.fromScale(3, 0.8), ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 64 }, trait)
aspect(ti, 1, Enum.DominantAxis.Height)
local asc = pill("AscChip", 0.27, foot, 2)
local starsRow = new("Frame", { Name = "Stars", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.72),
	BackgroundTransparency = 1, ZIndex = 63 }, asc)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }, starsRow)
for i = 1, 3 do
	local s = new("ImageLabel", { Name = "Star" .. i, Image = ICON.StarEmpty, BackgroundTransparency = 1, Size = UDim2.fromScale(3, 1),
		ScaleType = Enum.ScaleType.Fit, LayoutOrder = i, ZIndex = 64 }, starsRow)
	aspect(s, 1, Enum.DominantAxis.Height)
end
pill("WorthChip", 0.29, foot, 3)

label("Hint", { Position = UDim2.fromScale(0.05, 0.88), Size = UDim2.fromScale(0.9, 0.065), Text = "Select for full details",
	FontFace = F_BOLD, TextColor3 = C(150, 138, 186) }, card)

return "CardHover rebuilt"
