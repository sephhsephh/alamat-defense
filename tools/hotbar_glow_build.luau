-- tools/hotbar_glow_build.luau (B152) -- run with execute_luau in EACH Place (Edit). Authors the rarity-glow art the
-- shared UIKit.Hotbar (739ce0a9) clones behind Legendary+ cards: StarterGui.Hotbar.<Slots parent>.TierGlows (Z0 =
-- under the cards and the frame decor, over the frame's own background) holding GlowTemplate (Visible = false):
--   Aura (GlowRing) · Rays (Burst) · Circle (MagicCircle) · Rune (RuneRing) · Flare (X flare) · Spark1..3
-- every image white, tinted by its `Tint` UIGradient (the module paints the tier colours and drives the motion).
local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

local slots = SG.Hotbar:FindFirstChild("Slots", true) :: GuiObject
local frame = slots.Parent :: GuiObject
local old = frame:FindFirstChild("TierGlows")
if old then old:Destroy() end
-- Z: the frame's decor (DesignsFrameDontTouch, Z1) < TierGlows (Z2) < Slots (Z3): over the decor, under the cards
slots.ZIndex = 3
local layer = new("Frame", { Name = "TierGlows", AnchorPoint = slots.AnchorPoint, Position = slots.Position, Size = slots.Size,
	BackgroundTransparency = 1, ZIndex = 2, ClipsDescendants = false }, frame)
local t = new("Frame", { Name = "GlowTemplate", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(10, 1), BackgroundTransparency = 1, Visible = false, ZIndex = 2 }, layer)
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, t)

local function img(name: string, image: string, size: number, z: number): ImageLabel
	local i = new("ImageLabel", { Name = name, Image = image, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(size, size), ImageTransparency = 1, ZIndex = 2 }, t)
	new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, i)
	return i
end
img("Rays", Theme.Images.Burst, 1, 0)
img("Aura", Theme.Images.GlowRing, 0.95, 0)
img("Circle", Theme.Images.MagicCircle, 0.9, 0)
img("Rune", Theme.Images.RuneRing, 0.78, 0)
img("Flare", Theme.Images.Flare, 1.1, 0)
for k = 1, 3 do
	local s = img("Spark" .. k, Theme.Images.Sparkles[k], 0.14, 0)
	s.ImageTransparency = 0.05
end
return "TierGlows built under " .. frame:GetFullName()
