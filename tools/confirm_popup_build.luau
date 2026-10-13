-- confirm_popup_build.luau (B144) -- run with execute_luau (Edit) in EACH Place: same script, same result.
-- Rebuilds StarterGui.ConfirmationPopupUI in the Alamat UI look (night-violet gem panel, gold rim, sun rays +
-- magic circle behind a top emblem, sparkles, gem pill buttons with gloss + shine, a fill bar for the 2 s gate).
-- KEEPS the contract the shared UIKit.Confirm resolves:
--   Background > ConfirmationFrame > Main > ConfirmationLabel / ConfirmationText / YesButton / NoButton (> ButtonText)
-- New optional parts the module animates when present: ConfirmationFrame.Pop (UIScale), .Aura{Rays,Circle,Glow},
-- .Panel.ShineClip.Streak, .Emblem{Core,Glyph}, .Sparkles, Yes/No .Core (UIGradient) .Gate .ShineClip.Streak .Burst.
-- The previous GUI is kept in ServerStorage._UIBackup_B144. Scale-only sizes. Nothing here is generated at runtime.

local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")

local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local GOLD = CS({ CK(0, C(255, 246, 204)), CK(0.22, C(240, 184, 72)), CK(0.48, C(150, 88, 24)), CK(0.74, C(255, 226, 138)), CK(1, C(176, 108, 32)) })
local LABEL_GOLD = CS({ CK(0, C(255, 248, 214)), CK(0.5, C(255, 202, 92)), CK(1, C(214, 138, 46)) })
local F_LABEL = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local F_BODY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local IMG = {
	MagicCircle = "rbxassetid://113290594421442", Engraving = "rbxassetid://95270696231518", GlowRing = "rbxassetid://9864075653",
	Burst = "rbxassetid://7229481183", Streak = "rbxassetid://3052949762",
	Sparkles = { "rbxassetid://6997866340", "rbxassetid://71639137167582", "rbxassetid://81834701835654", "rbxassetid://6997866340" },
}

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function square(o) new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1 }, o) end
local function tintGrad(o, top, bottom) new("UIGradient", { Name = "Tint", Color = CS(top, bottom) }, o) end
local function image(name, img, props, parent)
	local base = { Name = name, Image = img, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), ScaleType = Enum.ScaleType.Fit }
	for k, v in pairs(props) do base[k] = v end
	return new("ImageLabel", base, parent)
end
local function goldRim(o, thickness)
	local s = new("UIStroke", { Name = "Rim", Thickness = thickness, Color = C(255, 255, 255), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	new("UIGradient", { Name = "Gold", Color = GOLD, Rotation = 35 }, s)
	return s
end
local function gloss(o, z)
	local g = new("Frame", { Name = "Gloss", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05),
		Size = UDim2.fromScale(0.94, 0.42), BackgroundColor3 = C(255, 255, 255), BackgroundTransparency = 0.78, ZIndex = z }, o)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, g)
	new("UIGradient", { Name = "Fade", Rotation = 90, Transparency = NS({ NK(0, 0.1), NK(1, 1) }) }, g)
end
local function shine(o, z, corner)
	local clip = new("CanvasGroup", { Name = "ShineClip", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z }, o)
	new("UICorner", { CornerRadius = corner }, clip)
	local st = image("Streak", IMG.Streak, { Position = UDim2.fromScale(-0.6, 0.5), Size = UDim2.fromScale(1.6, 1.4),
		ScaleType = Enum.ScaleType.Stretch, ImageTransparency = 0.25, Rotation = -12, ZIndex = z }, clip)
	tintGrad(st, C(255, 255, 255), C(255, 236, 170))
end

-- ===== Back up, then rebuild =====
local gui = SG:FindFirstChild("ConfirmationPopupUI")
assert(gui, "StarterGui.ConfirmationPopupUI missing")
local bk = SS:FindFirstChild("_UIBackup_B144") or new("Folder", { Name = "_UIBackup_B144" }, SS)
if not bk:FindFirstChild("ConfirmationPopupUI") then gui:Clone().Parent = bk end
for _, c in ipairs(gui:GetChildren()) do c:Destroy() end
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = math.max(gui.DisplayOrder, 100)

local bg = new("Frame", { Name = "Background", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(10, 6, 24),
	BackgroundTransparency = 0.15, Visible = false, Active = true }, gui) -- Active: clicks never fall through (no dismiss)
new("UIGradient", { Name = "Vignette", Rotation = 90, Transparency = NS({ NK(0, 0), NK(0.5, 0.25), NK(1, 0) }) }, bg)

local frame = new("Frame", { Name = "ConfirmationFrame", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromScale(0.34, 0.42), BackgroundTransparency = 1 }, bg)
new("UIAspectRatioConstraint", { Name = "AD_Aspect", AspectRatio = 1.5 }, frame)
new("UIScale", { Name = "Pop", Scale = 1 }, frame)

-- Aura: sun rays + magic circle + glow behind the top emblem (the module spins + pulses them)
local aura = new("Frame", { Name = "Aura", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.03),
	Size = UDim2.fromScale(0.6, 0.6), BackgroundTransparency = 1, ZIndex = 1 }, frame)
square(aura)
local rays = image("Rays", IMG.Burst, { Size = UDim2.fromScale(1.5, 1.5), ImageTransparency = 0.45, ZIndex = 1 }, aura)
tintGrad(rays, C(255, 236, 170), C(255, 170, 60))
local circle = image("Circle", IMG.MagicCircle, { Size = UDim2.fromScale(1.05, 1.05), ImageTransparency = 0.35, ZIndex = 1 }, aura)
tintGrad(circle, C(255, 240, 200), C(255, 190, 90))
local glow = image("Glow", IMG.GlowRing, { Size = UDim2.fromScale(0.7, 0.7), ImageTransparency = 0.15, ZIndex = 1 }, aura)
tintGrad(glow, C(255, 250, 230), C(255, 200, 100))

-- Panel: the gem plate
local panel = new("Frame", { Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 2 }, frame)
new("UICorner", { CornerRadius = UDim.new(0.07, 0) }, panel)
new("UIGradient", { Name = "Core", Rotation = 90, Color = CS({ CK(0, C(70, 44, 128)), CK(0.45, C(36, 22, 74)), CK(1, C(16, 10, 32)) }) }, panel)
goldRim(panel, 3)
local inner = new("Frame", { Name = "Inner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.965, 0.95), BackgroundTransparency = 1, ZIndex = 2 }, panel)
new("UICorner", { CornerRadius = UDim.new(0.065, 0) }, inner)
new("UIStroke", { Name = "Line", Color = C(196, 140, 255), Thickness = 1, Transparency = 0.45 }, inner)
local eng = image("Engraving", IMG.Engraving, { Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.8, 0.8), ImageTransparency = 0.88, ZIndex = 2 }, panel)
square(eng)
tintGrad(eng, C(210, 170, 255), C(150, 95, 255))
gloss(panel, 3)
panel.Gloss.Size = UDim2.fromScale(0.95, 0.2)
panel.Gloss.Position = UDim2.fromScale(0.5, 0.025)
panel.Gloss.BackgroundTransparency = 0.88
panel.Gloss:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0.4, 0)
shine(panel, 3, UDim.new(0.07, 0))
for i, pos in ipairs({ Vector2.new(0.035, 0.05), Vector2.new(0.965, 0.05), Vector2.new(0.035, 0.95), Vector2.new(0.965, 0.95) }) do
	local stud = new("Frame", { Name = "Stud" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(pos.X, pos.Y),
		Size = UDim2.fromScale(0.07, 0.07), BackgroundColor3 = C(255, 255, 255), Rotation = 45, ZIndex = 4 }, panel)
	square(stud)
	new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, stud)
	new("UIGradient", { Name = "Gold", Color = GOLD, Rotation = 45 }, stud)
	local gem = new("Frame", { Name = "StudGem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.48, 0.48), BackgroundColor3 = C(255, 255, 255), ZIndex = 5 }, stud)
	new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, gem)
	new("UIGradient", { Rotation = 90, Color = CS(C(198, 124, 255), C(92, 34, 176)) }, gem)
end

-- Emblem: a gold-rimmed gem disc riding the top edge; Glyph = "?" / "!" / a star, set per ask (Tone)
local emblem = new("Frame", { Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.03),
	Size = UDim2.fromScale(0.17, 0.17), BackgroundColor3 = C(255, 255, 255), ZIndex = 6 }, frame)
square(emblem)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, emblem)
new("UIGradient", { Name = "Core", Rotation = 90, Color = CS(C(255, 221, 128), C(206, 122, 30)) }, emblem)
goldRim(emblem, 3)
gloss(emblem, 7)
local glyph = new("TextLabel", { Name = "Glyph", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.53),
	Size = UDim2.fromScale(0.7, 0.7), BackgroundTransparency = 1, Text = "?", TextScaled = true, FontFace = F_LABEL,
	TextColor3 = C(255, 255, 255), ZIndex = 8 }, emblem)
new("UIStroke", { Name = "Outline", Color = C(90, 40, 10), Thickness = 2 }, glyph)

-- Main: the contract parts
local main = new("Frame", { Name = "Main", Position = UDim2.fromScale(0.07, 0.15), Size = UDim2.fromScale(0.86, 0.79),
	BackgroundTransparency = 1, ZIndex = 4 }, frame)
local title = new("TextLabel", { Name = "ConfirmationLabel", Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.19),
	BackgroundTransparency = 1, Text = "CONFIRMATION", TextScaled = true, FontFace = F_LABEL, TextColor3 = C(255, 255, 255), ZIndex = 5 }, main)
new("UIGradient", { Name = "Gold", Rotation = 90, Color = LABEL_GOLD }, title)
new("UIStroke", { Name = "Outline", Color = C(60, 26, 8), Thickness = 2 }, title)
local div = new("Frame", { Name = "Divider", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.235),
	Size = UDim2.fromScale(0.7, 0.012), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 5 }, main)
new("UIGradient", { Color = GOLD, Transparency = NS({ NK(0, 1), NK(0.2, 0), NK(0.8, 0), NK(1, 1) }) }, div)
local dia = new("Frame", { Name = "Diamond", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.235),
	Size = UDim2.fromScale(0.035, 0.045), BackgroundColor3 = C(255, 214, 120), Rotation = 45, ZIndex = 6 }, main)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, dia)
local body = new("TextLabel", { Name = "ConfirmationText", Position = UDim2.fromScale(0.03, 0.29), Size = UDim2.fromScale(0.94, 0.34),
	BackgroundTransparency = 1, Text = "Are you sure you want to do this?", TextScaled = true, TextWrapped = true, FontFace = F_BODY,
	TextColor3 = C(238, 230, 255), ZIndex = 5 }, main)
new("UITextSizeConstraint", { MaxTextSize = 30, MinTextSize = 10 }, body)
new("UIStroke", { Name = "Outline", Color = C(20, 10, 40), Thickness = 1.5, Transparency = 0.2 }, body)

local function pill(name, x, top, bottom, label, z)
	local b = new("TextButton", { Name = name, Position = UDim2.fromScale(x, 0.7), Size = UDim2.fromScale(0.44, 0.22), Text = "",
		AutoButtonColor = false, BackgroundColor3 = C(255, 255, 255), ZIndex = z, Selectable = true }, main)
	new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, b)
	new("UIGradient", { Name = "Core", Rotation = 90, Color = CS(top, bottom) }, b)
	goldRim(b, 2.5)
	new("UIScale", { Name = "Pop", Scale = 1 }, b)
	local depth = new("Frame", { Name = "Depth", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(0, 0, 0), BackgroundTransparency = 0.55, ZIndex = z }, b)
	new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, depth)
	new("UIGradient", { Name = "Shade", Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.55, 1), NK(1, 0.2) }) }, depth)
	local gate = new("Frame", { Name = "Gate", Size = UDim2.fromScale(0, 1), BackgroundColor3 = C(255, 255, 255), BackgroundTransparency = 0.72, ZIndex = z + 1 }, b)
	new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, gate)
	gloss(b, z + 1)
	shine(b, z + 2, UDim.new(0.35, 0))
	local burst = image("Burst", IMG.Burst, { Size = UDim2.fromScale(1.6, 2.6), ImageTransparency = 1, ScaleType = Enum.ScaleType.Stretch, ZIndex = z - 1 }, b)
	tintGrad(burst, C(255, 255, 255), C(150, 255, 150))
	local t = new("TextLabel", { Name = "ButtonText", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.64), BackgroundTransparency = 1, Text = label, TextScaled = true, FontFace = F_LABEL,
		TextColor3 = C(255, 255, 255), ZIndex = z + 3 }, b)
	new("UIStroke", { Name = "Outline", Color = C(20, 12, 30), Thickness = 2 }, t)
	return b
end
pill("YesButton", 0.03, C(156, 240, 122), C(28, 138, 72), "CONFIRM", 6)
pill("NoButton", 0.53, C(112, 82, 184), C(34, 20, 70), "CANCEL", 6)

-- Sparkles twinkling round the panel (the module pulses them while open)
local sp = new("Frame", { Name = "Sparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 9 }, frame)
for i, p in ipairs({ Vector2.new(0.06, 0.12), Vector2.new(0.95, 0.2), Vector2.new(0.9, 0.9), Vector2.new(0.1, 0.86) }) do
	local s = image("Spark" .. i, IMG.Sparkles[i], { Position = UDim2.fromScale(p.X, p.Y), Size = UDim2.fromScale(0.08, 0.08), ZIndex = 9 }, sp)
	square(s)
	tintGrad(s, C(255, 255, 255), C(255, 214, 120))
end

return "ConfirmationPopupUI rebuilt (Background hidden; UIKit.Confirm shows it per ask)"
