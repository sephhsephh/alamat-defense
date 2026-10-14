-- tools/screenfx_layer_build.luau (B158) -- run with execute_luau in EACH Place (Edit). Re-runnable.
-- User: "i see effects built on frame instead of images / animated images ... i hate vfx built on frames".
-- Rebuilds StarterGui.ScreenFXLayer's effect art -- the burst / sparks / charge ring / flash behind EVERY
-- ScreenFX.success (trait gained, daily claim, shop buy, craft, ascend, evolve, battle pass, quests...) -- as
-- WHITE IMAGES (the Alamat image kit) tinted by `TierGradient`, same names, so the shared ScreenFX keeps working:
--   Templates.Burst  = Frame container { Glow (GlowRing), Rays { RayA, RayB (Sparkles[1]) }, Ring (RuneRing), Flare }
--   Templates.Spark  = ImageLabel (a sparkle)          Templates.Charge = Frame container { Glow (GlowRing) }
--   Flash            = ImageLabel (a huge soft Flare bloom, not a flat white rectangle)
-- ResultText is text and stays. Backup: ServerStorage._UIBackup_B158.ScreenFXLayer.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any
local S, V2 = UDim2.fromScale, Vector2.new

local layer = SG:WaitForChild("ScreenFXLayer")
local bk = SS:FindFirstChild("_UIBackup_B158") or Instance.new("Folder")
bk.Name = "_UIBackup_B158"
bk.Parent = SS
if not bk:FindFirstChild("ScreenFXLayer") then layer:Clone().Parent = bk end

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function tinted(name: string, image: string, parent: Instance, props: { [string]: any }): ImageLabel
	local i = new("ImageLabel", { Name = name, Image = image, BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0.5),
		Position = S(0.5, 0.5), Size = S(1, 1) }, parent)
	for k, v in pairs(props) do (i :: any)[k] = v end
	new("UIGradient", { Name = "TierGradient", Color = Theme.tint("Gold") }, i)
	return i
end

local templates = layer:FindFirstChild("Templates") or new("Folder", { Name = "Templates" }, layer)
for _, n in ipairs({ "Burst", "Spark", "Charge" }) do
	local old = templates:FindFirstChild(n)
	if old then old:Destroy() end
end

-- the burst: a transparent square the code sizes in pixels; the art inside is scale
local burst = new("Frame", { Name = "Burst", AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1),
	BackgroundTransparency = 1, Visible = false, ZIndex = 50 }, templates)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, burst)
tinted("Glow", Theme.Images.GlowRing, burst, { Size = S(1.05, 1.05), ImageTransparency = 0.3, ZIndex = 50 })
-- Rays = two crossed sparkle stars (8 thin rays). NOT Theme.Images.Burst: that one is black-and-white with a
-- dark body (made for dark backdrops) and paints a dark disc over the scene -- GUI has no additive blending.
local rays = new("Frame", { Name = "Rays", AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(1, 1),
	BackgroundTransparency = 1, ZIndex = 51 }, burst)
tinted("RayA", Theme.Images.Sparkles[1], rays, { Size = S(1.15, 1.15), ImageTransparency = 0.05, ZIndex = 51 })
tinted("RayB", Theme.Images.Sparkles[1], rays, { Size = S(0.8, 0.8), Rotation = 45, ImageTransparency = 0.2, ZIndex = 51 })
tinted("Ring", Theme.Images.RuneRing, burst, { Size = S(0.62, 0.62), ImageTransparency = 0.1, ZIndex = 52 })
tinted("Flare", Theme.Images.Flare, burst, { Size = S(0.8, 0.8), ImageTransparency = 0, ZIndex = 53 })

-- a spark: one twinkle (the code moves / spins / fades it)
tinted("Spark", Theme.Images.Sparkles[1], templates, { AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromScale(0.02, 0.02),
	Visible = false, ZIndex = 54 })

-- the charge ring: a glowing ring the code pulses around the anchor while a roll is pending. The code sizes
-- the container to the anchor's rectangle, so the glow image inside overhangs it to circle the button.
local charge = new("Frame", { Name = "Charge", AnchorPoint = V2(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1),
	BackgroundTransparency = 1, Visible = false, ZIndex = 49 }, templates)
tinted("Glow", Theme.Images.GlowRing, charge, { Size = S(1.45, 1.7), ImageTransparency = 0.1, ZIndex = 49 })

-- the flash: a soft screen-wide flare bloom instead of a flat white rectangle (GlowRing here read as a hard
-- circle across the screen)
local oldFlash = layer:FindFirstChild("Flash")
if oldFlash then oldFlash:Destroy() end
local flash = new("ImageLabel", { Name = "Flash", Image = Theme.Images.Flare, BackgroundTransparency = 1,
	AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(1.25, 1.25), ImageTransparency = 1, ZIndex = 1 }, layer)
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, flash)
new("UIGradient", { Name = "Tint", Color = ColorSequence.new(Color3.fromRGB(255, 250, 230), Color3.fromRGB(255, 220, 140)) }, flash)

return "ScreenFXLayer art rebuilt as images in " .. layer:GetFullName()
