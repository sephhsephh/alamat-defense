-- tools/obtain_rewards_build.luau (B135): authors the NEW StarterGui.ObtainRewardsGUI (Lobby) as real instances --
-- the user edits them in Studio; ObtainRewardsController only clones `Main.Templates.RewardCard`, sizes the board
-- and animates. Everything is scale-sized (the controller turns the grid cell size into pixels from the screen
-- size, the one accepted grid exception in responsive-ui.md). Re-running rebuilds the look; the controller
-- LocalScript is kept. Old screen: ServerStorage._UIBackup_B135.ObtainRewardsGUI. Run in Lobby, Edit.
local gui = game.StarterGui:FindFirstChild("ObtainRewardsGUI") :: ScreenGui
for _, c in ipairs(gui:GetChildren()) do
	if not c:IsA("LuaSourceContainer") then c:Destroy() end
end
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
for k, v in pairs({ InputDeadSeconds = 0.35, RevealStaggerSeconds = 0.09, RevealPopSeconds = 0.38,
	RevealMaxTotalSeconds = 1.6, MaxColumns = 6, MaxVisibleRows = 2 }) do
	gui:SetAttribute(k, v)
end

local GOLD_L, GOLD, GOLD_D = Color3.fromRGB(255, 240, 196), Color3.fromRGB(255, 202, 92), Color3.fromRGB(190, 120, 40)
local PANEL, VIOLET, LILAC = Color3.fromRGB(24, 19, 40), Color3.fromRGB(150, 95, 255), Color3.fromRGB(214, 200, 255)
local SERIF = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local SANS_B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local SANS_M = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local CS, CK, NS, NK = ColorSequence.new, ColorSequenceKeypoint.new, NumberSequence.new, NumberSequenceKeypoint.new

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	if class:find("Frame") or class:find("Label") or class:find("Button") then
		if props.BorderSizePixel == nil then (o :: any).BorderSizePixel = 0 end
	end
	o.Parent = parent
	return o
end
local function corner(p, s) return new("UICorner", { CornerRadius = UDim.new(s or 1, 0) }, p) end
-- square elements use a WIDE X box (50): the constraint (FitWithinMaxSize) shrinks it -- an X of 0 collapses to nothing
local function square(p) return new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, p) end
local function grad(p, name, props) props.Name = name return new("UIGradient", props, p) end
local function stroke(p, name, color, th, tr) return new("UIStroke", { Name = name, Color = color, Thickness = th, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, p) end
local function label(p, name, text, font, color, props)
	local l = new("TextLabel", { Name = name, Text = text, FontFace = font, TextColor3 = color, TextScaled = true, BackgroundTransparency = 1 }, p)
	for k, v in pairs(props or {}) do (l :: any)[k] = v end
	return l
end
local goldText = CS({ CK(0, Color3.fromRGB(255, 248, 214)), CK(0.5, GOLD), CK(1, Color3.fromRGB(214, 138, 46)) })

local main = new("Frame", { Name = "Main", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, gui)

-- backdrop (Active: blocks clicks to the screens underneath)
local dim = new("Frame", { Name = "Dim", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 6, 18), BackgroundTransparency = 0, Active = true, ZIndex = 1 }, main)
grad(dim, "Vignette", { Rotation = 90, Transparency = NS({ NK(0, 0.02), NK(0.5, 0.32), NK(1, 0.02) }) })

-- sunburst behind the board (rotated by the controller)
local rays = new("Frame", { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(50, 1.35), BackgroundTransparency = 1, ZIndex = 2 }, main)
square(rays)
new("UIScale", { Name = "Pop" }, rays)
for i = 0, 7 do
	local r = new("Frame", { Name = "Ray" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(i % 2 == 0 and 0.07 or 0.035, 1), Rotation = i * 22.5, BackgroundColor3 = GOLD, ZIndex = 2 }, rays)
	grad(r, "Fade", { Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.18, 0.78), NK(0.5, 0.3), NK(0.82, 0.78), NK(1, 1) }) })
end
for i, s in ipairs({ 0.5, 0.34, 0.2 }) do
	local g = new("Frame", { Name = "Glow" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = i == 1 and VIOLET or GOLD, BackgroundTransparency = ({ 0.82, 0.8, 0.72 })[i], ZIndex = 2 }, rays)
	corner(g)
end

-- header: Philippine-sun emblem, gold serif title, divider with a gem, count line
local header = new("Frame", { Name = "Header", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromScale(0.7, 0.17), BackgroundTransparency = 1, ZIndex = 5 }, main)
new("UIScale", { Name = "Pop" }, header)
local sun = new("Frame", { Name = "Sun", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.16), Size = UDim2.fromScale(50, 0.46), BackgroundTransparency = 1, ZIndex = 5 }, header)
square(sun)
for i = 0, 3 do
	local r = new("Frame", { Name = "SunRay" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.16, 1), Rotation = i * 45, BackgroundColor3 = GOLD, ZIndex = 5 }, sun)
	corner(r, 0.5)
	grad(r, "Shade", { Rotation = 90, Color = CS({ CK(0, GOLD_D), CK(0.5, GOLD_L), CK(1, GOLD_D) }) })
end
local core = new("Frame", { Name = "Core", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.52), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, sun)
corner(core)
grad(core, "Shade", { Rotation = 90, Color = CS({ CK(0, GOLD_L), CK(1, GOLD_D) }) })
stroke(core, "Rim", Color3.fromRGB(90, 50, 14), 2)
local title = label(header, "Title", "REWARDS OBTAINED", SERIF, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.62), Size = UDim2.fromScale(1, 0.4), ZIndex = 6 })
grad(title, "Gold", { Rotation = 90, Color = goldText })
stroke(title, "Outline", Color3.fromRGB(56, 28, 8), 2.5)
new("UIScale", { Name = "Pop" }, title)
local div = new("Frame", { Name = "Divider", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.9), Size = UDim2.fromScale(0.62, 0.035), BackgroundColor3 = GOLD, ZIndex = 5 }, header)
grad(div, "Fade", { Transparency = NS({ NK(0, 1), NK(0.25, 0.45), NK(0.5, 0), NK(0.75, 0.45), NK(1, 1) }) })
local gem = new("Frame", { Name = "Gem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(50, 4.5), Rotation = 45, BackgroundColor3 = VIOLET, ZIndex = 6 }, div)
square(gem)
stroke(gem, "Rim", GOLD, 1.5)
label(header, "Subtitle", "", SANS_M, LILAC, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 1.02), Size = UDim2.fromScale(0.6, 0.17), ZIndex = 5 })

-- the board that holds the cards (sized by the controller for the batch)
local board = new("Frame", { Name = "Board", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.56), Size = UDim2.fromScale(0.5, 0.36), BackgroundColor3 = PANEL, BackgroundTransparency = 0.06, ZIndex = 4 }, main)
corner(board, 0.07)
grad(board, "Back", { Rotation = 90, Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(176, 164, 206)) })
local bs = stroke(board, "Frame", Color3.new(1, 1, 1), 3)
grad(bs, "FrameGradient", { Rotation = 45, Color = CS({ CK(0, GOLD), CK(0.35, Color3.fromRGB(255, 240, 200)), CK(0.65, VIOLET), CK(1, GOLD) }) })
new("UIScale", { Name = "Pop" }, board)
new("UIPadding", { Name = "Pad" }, board)
for _, c in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
	local g = new("Frame", { Name = "CornerGem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(c[1], c[2]), Size = UDim2.fromScale(50, 0.075), Rotation = 45, BackgroundColor3 = GOLD, ZIndex = 6 }, board)
	square(g)
	grad(g, "Shade", { Rotation = 90, Color = CS(GOLD_L, GOLD_D) })
	stroke(g, "Rim", Color3.fromRGB(60, 32, 10), 1.5)
end
local list = new("ScrollingFrame", { Name = "RewardsFrame", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 6, ScrollBarImageColor3 = GOLD, ScrollingDirection = Enum.ScrollingDirection.Y, CanvasSize = UDim2.fromScale(0, 0), ElasticBehavior = Enum.ElasticBehavior.Never, ZIndex = 5 }, board)
new("UIGridLayout", { Name = "Grid", SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top, FillDirectionMaxCells = 6 }, list)

-- hint (skip while revealing / continue after) -- the reveal-overlay "click anywhere" exception
local hint = label(main, "Hint", "Click anywhere to continue", SANS_M, LILAC, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.91), Size = UDim2.fromScale(0.5, 0.034), ZIndex = 6 })
stroke(hint, "Outline", Color3.fromRGB(10, 6, 20), 1.5)

-- ===== the card template =====
local templates = new("Folder", { Name = "Templates" }, main)
local card = new("Frame", { Name = "RewardCard", Size = UDim2.fromScale(0.1, 0.2), BackgroundTransparency = 1, Visible = false }, templates)
local burst = new("Frame", { Name = "Burst", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(50, 0.9), BackgroundTransparency = 1, ZIndex = 1 }, card)
square(burst)
corner(burst)
stroke(burst, "Ring", Color3.new(1, 1, 1), 0, 1)
local m = new("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(28, 22, 46), ClipsDescendants = true, ZIndex = 2 }, card)
corner(m, 0.1)
new("UIScale", { Name = "Pop" }, m)
local ts = stroke(m, "TierStroke", Color3.new(1, 1, 1), 2.5)
grad(ts, "Tier", { Rotation = 45 })
local wash = new("Frame", { Name = "Wash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 1 }, m)
corner(wash, 0.1)
grad(wash, "Tier", { Rotation = 90, Transparency = NS({ NK(0, 0.25), NK(0.6, 0.68), NK(1, 0.92) }) })
local glow = new("Frame", { Name = "Glow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(50, 0.6), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, ZIndex = 2 }, m)
square(glow)
corner(glow)
grad(glow, "Tier", { Rotation = 90 })
new("ImageLabel", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromScale(0.74, 0.54), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, m)
new("ViewportFrame", { Name = "Viewport", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(1, 0.8), BackgroundTransparency = 1, Visible = false, ZIndex = 3 }, m)
local tag = new("Frame", { Name = "TierTag", Position = UDim2.fromScale(0.06, 0.05), Size = UDim2.fromScale(0.52, 0.12), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 }, m)
corner(tag)
grad(tag, "Tier", { Rotation = 0 })
local tt = label(tag, "Text", "COMMON", SANS_B, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.78), ZIndex = 6 })
stroke(tt, "Outline", Color3.fromRGB(20, 12, 30), 1.2)
local shinyTag = new("Frame", { Name = "ShinyTag", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.95, 0.05), Size = UDim2.fromScale(0.36, 0.12), BackgroundColor3 = Color3.fromRGB(255, 238, 160), Visible = false, ZIndex = 5 }, m)
corner(shinyTag)
label(shinyTag, "Text", "SHINY", SANS_B, Color3.fromRGB(90, 52, 6), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.78), ZIndex = 6 })
local amount = label(m, "Amount", "x1", SANS_B, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.94, 0.79), Size = UDim2.fromScale(0.8, 0.15), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5 })
grad(amount, "Gold", { Rotation = 90, Color = goldText })
stroke(amount, "Outline", Color3.fromRGB(40, 22, 6), 1.6)
local trait = label(m, "TraitTag", "", SANS_B, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0.05, 0.79), Size = UDim2.fromScale(0.5, 0.11), BackgroundTransparency = 0.15, BackgroundColor3 = Color3.fromRGB(70, 44, 120), Visible = false, ZIndex = 5 })
corner(trait, 0.3)
local strip = new("Frame", { Name = "NameStrip", Position = UDim2.fromScale(0, 0.8), Size = UDim2.fromScale(1, 0.2), BackgroundColor3 = Color3.fromRGB(10, 8, 18), BackgroundTransparency = 0.25, ZIndex = 4 }, m)
local nm = label(strip, "NameLabel", "Reward", SANS_B, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.7), ZIndex = 5 })
stroke(nm, "Outline", Color3.new(0, 0, 0), 1)
local shine = new("Frame", { Name = "Shine", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, m)
grad(shine, "Sweep", { Rotation = 25, Offset = Vector2.new(-1, 0), Transparency = NS({ NK(0, 1), NK(0.38, 1), NK(0.5, 0.3), NK(0.62, 1), NK(1, 1) }) })
local sold = new("Frame", { Name = "Sold", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 7 }, m)
local st = label(sold, "Text", "AUTO-SOLD", SANS_B, Color3.fromRGB(255, 96, 96), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.9, 0.16), Rotation = -14, ZIndex = 8 })
stroke(st, "Outline", Color3.new(0, 0, 0), 1.5)
new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, ZIndex = 9 }, m)
return "ObtainRewardsGUI authored: " .. #gui:GetDescendants() .. " instances"
