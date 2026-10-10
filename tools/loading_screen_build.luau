-- tools/loading_screen_build.luau (B136): authors the Alamat loading screen into StarterGui.LoadingScreen (run in
-- the LOBBY, then copy the ScreenGui to the Game -- the same instances + LoadingScreenController serve both).
-- Real instances only; the controller tweens and fills them. Keeps the user's BackgroundImage asset. Scale-only.
local gui = game.StarterGui:FindFirstChild("LoadingScreen") :: ScreenGui
local oldRoot = gui:FindFirstChild("Root")
local bgImage = "rbxassetid://109387997998085"
if oldRoot and oldRoot:FindFirstChild("BackgroundImage") then bgImage = (oldRoot :: any).BackgroundImage.Image end
for _, c in ipairs(gui:GetChildren()) do
	if not c:IsA("LuaSourceContainer") then c:Destroy() end
end
gui.DisplayOrder = 200
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
for k, v in pairs({ FadeInTime = 0.35, FadeOutTime = 0.45, MinShowTime = 0.6, TipPeriod = 4.5 }) do gui:SetAttribute(k, v) end

local GOLD_L, GOLD, GOLD_D = Color3.fromRGB(255, 240, 196), Color3.fromRGB(255, 202, 92), Color3.fromRGB(190, 120, 40)
local VIOLET, LILAC = Color3.fromRGB(150, 95, 255), Color3.fromRGB(222, 208, 255)
local SERIF = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local SANS_B = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local SANS_M = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local CS, CK, NS, NK = ColorSequence.new, ColorSequenceKeypoint.new, NumberSequence.new, NumberSequenceKeypoint.new
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if (class:find("Frame") or class:find("Label") or class == "CanvasGroup") and props.BorderSizePixel == nil then o.BorderSizePixel = 0 end
	o.Parent = parent
	return o
end
local function corner(p, s) return new("UICorner", { CornerRadius = UDim.new(s or 1, 0) }, p) end
-- square elements: a WIDE X box (50) the constraint shrinks -- an X of 0 collapses to nothing
local function square(p) return new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, p) end
local function grad(p, name, props) props.Name = name return new("UIGradient", props, p) end
local function stroke(p, name, color, th, tr) return new("UIStroke", { Name = name, Color = color, Thickness = th, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, p) end
local function label(p, name, text, font, color, props)
	local l = new("TextLabel", { Name = name, Text = text, FontFace = font, TextColor3 = color, TextScaled = true, BackgroundTransparency = 1 }, p)
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end
local goldText = CS({ CK(0, Color3.fromRGB(255, 248, 214)), CK(0.5, GOLD), CK(1, Color3.fromRGB(214, 138, 46)) })

local root = new("CanvasGroup", { Name = "Root", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, Visible = false }, gui)
new("Frame", { Name = "Backdrop", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 8, 18), ZIndex = 1 }, root)
local img = new("ImageLabel", { Name = "BackgroundImage", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = bgImage, ScaleType = Enum.ScaleType.Crop, ZIndex = 2 }, root)
new("UIScale", { Name = "Zoom" }, img)
local shade = new("Frame", { Name = "Shade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 }, root)
grad(shade, "Night", { Rotation = 90, Color = CS(Color3.fromRGB(26, 16, 52), Color3.fromRGB(6, 4, 14)), Transparency = NS({ NK(0, 0.62), NK(0.5, 0.5), NK(1, 0.12) }) })

local rays = new("Frame", { Name = "Rays", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(50, 1.1), BackgroundTransparency = 1, ZIndex = 4 }, root)
square(rays)
for i = 0, 7 do
	local r = new("Frame", { Name = "Ray" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(i % 2 == 0 and 0.06 or 0.03, 1), Rotation = i * 22.5, BackgroundColor3 = GOLD, ZIndex = 4 }, rays)
	grad(r, "Fade", { Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.3, 0.94), NK(0.5, 0.8), NK(0.7, 0.94), NK(1, 1) }) })
end
local halo = new("Frame", { Name = "Halo", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.3, 0.3), BackgroundColor3 = GOLD, BackgroundTransparency = 0.9, ZIndex = 4 }, rays)
corner(halo)

-- soft dark band behind the centre text so it reads over the key art
local band = new("Frame", { Name = "Band", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.6), Size = UDim2.fromScale(1, 0.46), BackgroundColor3 = Color3.fromRGB(8, 5, 18), ZIndex = 5 }, root)
grad(band, "Fade", { Rotation = 90, Transparency = NS({ NK(0, 1), NK(0.2, 0.55), NK(0.5, 0.42), NK(0.8, 0.55), NK(1, 1) }) })

-- spinning Philippine-sun emblem
local emblem = new("Frame", { Name = "Emblem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(50, 0.13), BackgroundTransparency = 1, ZIndex = 6 }, root)
square(emblem)
new("UIScale", { Name = "Pop" }, emblem)
for i = 0, 3 do
	local r = new("Frame", { Name = "SunRay" .. i, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.15, 1), Rotation = i * 45, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 6 }, emblem)
	corner(r, 0.5)
	grad(r, "Shade", { Rotation = 90, Color = CS({ CK(0, GOLD_D), CK(0.5, GOLD_L), CK(1, GOLD_D) }) })
end
local core = new("Frame", { Name = "Core", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 }, emblem)
corner(core)
grad(core, "Shade", { Rotation = 90, Color = CS(GOLD_L, GOLD_D) })
stroke(core, "Rim", Color3.fromRGB(90, 50, 14), 2)
local ring = new("Frame", { Name = "Ring", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.35, 1.35), BackgroundTransparency = 1, ZIndex = 5 }, emblem)
corner(ring)
local rs = stroke(ring, "Arc", Color3.new(1, 1, 1), 3)
grad(rs, "Sweep", { Color = CS(GOLD, VIOLET), Transparency = NS({ NK(0, 0), NK(0.45, 0), NK(0.55, 1), NK(1, 1) }) })

local kicker = label(root, "Kicker", "", SANS_B, GOLD, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.425), Size = UDim2.fromScale(0.5, 0.032), ZIndex = 6 })
stroke(kicker, "Outline", Color3.fromRGB(20, 10, 4), 1.5)
local title = label(root, "TitleLabel", "LOADING", SERIF, Color3.new(1, 1, 1), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.49), Size = UDim2.fromScale(0.86, 0.095), ZIndex = 6 })
grad(title, "Gold", { Rotation = 90, Color = goldText })
stroke(title, "Outline", Color3.fromRGB(56, 28, 8), 3)
new("UIScale", { Name = "Pop" }, title)
local sub = label(root, "Subtitle", "", SANS_M, LILAC, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.555), Size = UDim2.fromScale(0.6, 0.036), ZIndex = 6 })
stroke(sub, "Outline", Color3.fromRGB(10, 6, 20), 1.5)

local chips = new("Frame", { Name = "Chips", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.612), Size = UDim2.fromScale(0.8, 0.042), BackgroundTransparency = 1, ZIndex = 6 }, root)
new("UIListLayout", { Name = "Row", FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
local templates = new("Folder", { Name = "Templates" }, root)
local chip = new("Frame", { Name = "ChipTemplate", Size = UDim2.fromScale(0.15, 1), BackgroundColor3 = Color3.fromRGB(30, 22, 54), BackgroundTransparency = 0.12, Visible = false, ZIndex = 6 }, templates)
corner(chip)
local cs = stroke(chip, "Rim", Color3.new(1, 1, 1), 1.5)
grad(cs, "Gold", { Rotation = 0, Color = CS({ CK(0, GOLD), CK(0.5, GOLD_L), CK(1, VIOLET) }) })
new("UIScale", { Name = "Pop" }, chip)
label(chip, "Text", "Chip", SANS_B, Color3.fromRGB(245, 238, 255), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.86, 0.62), ZIndex = 7 })

local div = new("Frame", { Name = "Divider", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.672), Size = UDim2.fromScale(0.42, 0.003), BackgroundColor3 = GOLD, ZIndex = 6 }, root)
grad(div, "Fade", { Transparency = NS({ NK(0, 1), NK(0.25, 0.5), NK(0.5, 0), NK(0.75, 0.5), NK(1, 1) }) })
local gem = new("Frame", { Name = "Gem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(50, 5), Rotation = 45, BackgroundColor3 = VIOLET, ZIndex = 7 }, div)
square(gem)
stroke(gem, "Rim", GOLD, 1.5)

local status = label(root, "StatusLabel", "Loading...", SANS_M, Color3.fromRGB(236, 230, 250), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.715), Size = UDim2.fromScale(0.5, 0.03), ZIndex = 6 })
stroke(status, "Outline", Color3.fromRGB(10, 6, 20), 1.5)
local track = new("Frame", { Name = "ProgressTrack", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.758), Size = UDim2.fromScale(0.34, 0.013), BackgroundColor3 = Color3.fromRGB(26, 18, 44), BackgroundTransparency = 0.05, ClipsDescendants = true, ZIndex = 6 }, root)
corner(track)
local ts = stroke(track, "Rim", Color3.new(1, 1, 1), 1.5)
grad(ts, "Gold", { Color = CS(GOLD_D, GOLD_L, GOLD_D) })
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 }, track)
corner(fill)
grad(fill, "Tint", { Color = CS({ CK(0, Color3.fromRGB(255, 228, 128)), CK(0.35, Color3.fromRGB(255, 178, 60)), CK(0.7, Color3.fromRGB(206, 98, 222)), CK(1, Color3.fromRGB(136, 80, 255)) }) })
local sheen = new("Frame", { Name = "Sheen", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 8 }, fill)
corner(sheen)
grad(sheen, "Sweep", { Rotation = 20, Offset = Vector2.new(-1, 0), Transparency = NS({ NK(0, 1), NK(0.38, 1), NK(0.48, 0.2), NK(0.5, 0), NK(0.52, 0.2), NK(0.62, 1), NK(1, 1) }) })
local pct = label(root, "PercentLabel", "0%", SANS_B, GOLD_L, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.68, 0.758), Size = UDim2.fromScale(0.06, 0.026), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 })
stroke(pct, "Outline", Color3.fromRGB(20, 10, 4), 1.2)

local tipBox = new("Frame", { Name = "TipBox", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.89), Size = UDim2.fromScale(0.62, 0.05), BackgroundColor3 = Color3.fromRGB(14, 10, 26), BackgroundTransparency = 0.3, ZIndex = 6 }, root)
corner(tipBox, 0.5)
local tbs = stroke(tipBox, "Rim", Color3.new(1, 1, 1), 1.2, 0.3)
grad(tbs, "Gold", { Color = CS(GOLD, VIOLET) })
local tag = new("Frame", { Name = "TipTag", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.015, 0.5), Size = UDim2.fromScale(0.08, 0.62), BackgroundColor3 = GOLD, ZIndex = 7 }, tipBox)
corner(tag)
label(tag, "Text", "TIP", SANS_B, Color3.fromRGB(60, 30, 6), { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.75), ZIndex = 8 })
label(tipBox, "TipLabel", "", SANS_M, Color3.fromRGB(230, 222, 248), { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.11, 0.5), Size = UDim2.fromScale(0.86, 0.55), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })

return "LoadingScreen authored: " .. #gui:GetDescendants() .. " instances"
