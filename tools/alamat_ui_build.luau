-- tools/alamat_ui_build.luau (B138): authors the Alamat UI kit's MASTER button into
-- ReplicatedStorage.AlamatUI.Templates -- the one "Sun-gem" button every HUD button is cloned from (only the
-- Theme colours and the Variant layout differ). Real instances, scale-only (the square parts use a wide-X box +
-- an aspect constraint). Also the gamepad Selector. Idempotent. Run in execute_luau (Lobby, Edit).
--
-- MASTER TREE (Variant = Tile)
--   AlamatButton (ImageButton, transparent, tag AlamatButton, attrs Theme / Variant / Label)
--     Pop (UIScale)                        hover / press scale
--     Aura                                 VFX behind the gem (all white art, UIGradient "Tint")
--       Circle   magic seal (heroes)       Glow   breathing ring (heroes)
--       RuneRing hover halo                Pulse  activation ring    Burst  press flash
--     Main (gem)  Core gradient + Rim (gold UIStroke, gradient "Gold") + Depth shade + Engraving seal + Gloss
--                 + Icon (Bob UIScale) + ShineClip/Streak + 4 gold Studs with a StudGem
--     Label      gold-edged night ribbon with the gold serif Text
--     Sparkles   3 twinkling stars (attr S = target size)
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local kit = RS:WaitForChild("AlamatUI")
local Theme = require(kit:WaitForChild("Theme"))
local templates = kit:FindFirstChild("Templates") or Instance.new("Folder")
templates.Name = "Templates"
templates.Parent = kit
for _, n in ipairs({ "AlamatButton", "Selector" }) do
	local o = templates:FindFirstChild(n)
	if o then o:Destroy() end
end

local CS, CK, NS, NK = ColorSequence.new, ColorSequenceKeypoint.new, NumberSequence.new, NumberSequenceKeypoint.new
local IMG = Theme.Images
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	if (class:find("Frame") or class:find("Label") or class:find("Button")) and props.BorderSizePixel == nil then (o :: any).BorderSizePixel = 0 end
	o.Parent = parent
	return o
end
local function corner(p, s) return new("UICorner", { CornerRadius = UDim.new(s or 1, 0) }, p) end
local function square(p) return new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, p) end
local function grad(p, name, props) props.Name = name return new("UIGradient", props, p) end
local function vfx(parent, name, image, size, transp, z)
	local i = new("ImageLabel", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(size, size),
		BackgroundTransparency = 1, Image = image, ImageTransparency = transp, ZIndex = z or 1 }, parent)
	grad(i, "Tint", { Rotation = 90, Color = Theme.tint("Violet") })
	return i
end

local btn = new("ImageButton", { Name = "AlamatButton", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = "",
	AutoButtonColor = false, Selectable = true }, templates)
btn:SetAttribute("Theme", "Violet")
btn:SetAttribute("Variant", "Tile")
btn:SetAttribute("Label", "Button")
CollectionService:AddTag(btn, "AlamatButton")
new("UIScale", { Name = "Pop" }, btn)

local aura = new("Frame", { Name = "Aura", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.fromScale(50, 1.28),
	BackgroundTransparency = 1, ZIndex = 1 }, btn)
square(aura)
vfx(aura, "Circle", IMG.MagicCircle, 1, 1)
vfx(aura, "Glow", IMG.GlowRing, 0.8, 1)
vfx(aura, "RuneRing", IMG.RuneRing, 0.92, 1)
vfx(aura, "Pulse", IMG.GlowRing, 0.55, 1)
vfx(aura, "Burst", IMG.Burst, 1, 1)

local main = new("Frame", { Name = "Main", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(50, 0.8),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 }, btn)
square(main)
corner(main, 0.22)
grad(main, "Core", { Rotation = 90, Color = Theme.core("Violet") })
local rim = new("UIStroke", { Name = "Rim", Color = Color3.new(1, 1, 1), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, LineJoinMode = Enum.LineJoinMode.Round }, main)
grad(rim, "Gold", { Rotation = 45, Color = Theme.Gold })
local depth = new("Frame", { Name = "Depth", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 6, 24), ZIndex = 2 }, main)
corner(depth, 0.22)
grad(depth, "Shade", { Rotation = 90, Transparency = NS({ NK(0, 0.8), NK(0.5, 0.5), NK(1, 0.12) }) })
vfx(main, "Engraving", IMG.Engraving, 0.9, 0.72, 3)
local gloss = new("Frame", { Name = "Gloss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(0.9, 0.42),
	BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 4 }, main)
corner(gloss, 0.3)
grad(gloss, "Fade", { Rotation = 90, Transparency = NS({ NK(0, 0.76), NK(1, 1) }) })
local icon = new("ImageLabel", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62),
	BackgroundTransparency = 1, Image = IMG.PlaceholderIcon, ScaleType = Enum.ScaleType.Fit, ZIndex = 5 }, main)
new("UIScale", { Name = "Bob" }, icon)
local clip = new("Frame", { Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6 }, main)
local streak = new("ImageLabel", { Name = "Streak", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-0.5, 0.5), Size = UDim2.fromScale(1.8, 0.7),
	Rotation = 62, BackgroundTransparency = 1, Image = IMG.Streak, ImageTransparency = 0.05, ZIndex = 6 }, clip)
grad(streak, "Tint", { Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(255, 236, 190)) })
for i, p in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
	local stud = new("Frame", { Name = "Stud" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.07 + p[1] * 0.86, 0.07 + p[2] * 0.86),
		Size = UDim2.fromScale(50, 0.15), Rotation = 45, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 }, main)
	square(stud)
	grad(stud, "Gold", { Rotation = 90, Color = Theme.Gold })
	new("UIStroke", { Name = "Edge", Color = Color3.fromRGB(70, 36, 8), Thickness = 1 }, stud)
	new("Frame", { Name = "StudGem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.46, 0.46),
		BackgroundColor3 = Theme.palette("Violet").Glow, ZIndex = 8 }, stud)
end

local label = new("Frame", { Name = "Label", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1.04, 0.25),
	BackgroundColor3 = Theme.Night, BackgroundTransparency = 0.04, ZIndex = 3 }, btn)
corner(label, 0.45)
local edge = new("UIStroke", { Name = "Edge", Color = Color3.new(1, 1, 1), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, label)
grad(edge, "Gold", { Color = Theme.Gold })
local text = new("TextLabel", { Name = "Text", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.78),
	BackgroundTransparency = 1, Text = "Button", FontFace = Theme.Fonts.Label, TextScaled = true, TextColor3 = Color3.new(1, 1, 1), ZIndex = 4 }, label)
grad(text, "Gold", { Rotation = 90, Color = Theme.LabelGold })
new("UIStroke", { Name = "Outline", Color = Color3.fromRGB(40, 20, 6), Thickness = 1.5 }, text)

local sparkles = new("Frame", { Name = "Sparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, btn)
for i, p in ipairs({ { 0.08, 0.06, 0.22 }, { 0.94, 0.16, 0.16 }, { 0.82, 0.7, 0.2 } }) do
	local s = new("ImageLabel", { Name = "Spark" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(p[1], p[2]), Size = UDim2.fromScale(50, 0),
		BackgroundTransparency = 1, Image = IMG.Sparkles[i], ImageTransparency = 1, ZIndex = 8 }, sparkles)
	s:SetAttribute("S", p[3])
	square(s)
	grad(s, "Tint", { Rotation = 90, Color = Theme.tint("Violet") })
end

-- the gamepad selection look (assigned as SelectionImageObject by the animator)
local sel = new("ImageLabel", { Name = "Selector", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.3, 1.3),
	BackgroundTransparency = 1, Image = IMG.GlowRing, ImageColor3 = Color3.fromRGB(255, 214, 110) }, templates)
return "AlamatUI master built: " .. #btn:GetDescendants() .. " parts"
