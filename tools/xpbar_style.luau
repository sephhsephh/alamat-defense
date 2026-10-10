-- tools/xpbar_style.luau (B135): authors the XP bar look into StarterGui.XPBarGui -- run in BOTH Places
-- (execute_luau, Edit). Idempotent. Real instances only (no runtime UI): the fill gets a gold -> violet
-- gradient (`Tint`), a glossy top highlight (`Gloss`), a glowing leading edge (`Tip`, pulsed by the
-- controller), a brighter/wider shine band (`Sheen.Sweep`), and the label a dark outline for legibility.
local bar = game.StarterGui:WaitForChild("XPBarGui"):WaitForChild("XPBar")
local fill = bar:WaitForChild("Fill")
local function kid(parent, class, name)
	local c = parent:FindFirstChild(name)
	if c and not c:IsA(class) then c:Destroy() c = nil end
	if not c then c = Instance.new(class) c.Name = name c.Parent = parent end
	return c
end
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new

-- dark track behind the fill
bar.BackgroundColor3 = Color3.fromRGB(26, 18, 44)

-- fill: white base so the gradient shows its true colours
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BackgroundTransparency = 0
local tint = kid(fill, "UIGradient", "Tint")
tint.Rotation = 0
tint.Color = CS({
	CK(0, Color3.fromRGB(255, 228, 128)),   -- light gold
	CK(0.35, Color3.fromRGB(255, 178, 60)), -- deep gold
	CK(0.7, Color3.fromRGB(206, 98, 222)),  -- orchid
	CK(1, Color3.fromRGB(136, 80, 255)),    -- violet
})

-- glossy highlight on the top half
local gloss = kid(fill, "Frame", "Gloss")
gloss.BackgroundColor3 = Color3.new(1, 1, 1)
gloss.BackgroundTransparency = 0
gloss.BorderSizePixel = 0
gloss.Position = UDim2.fromScale(0, 0)
gloss.Size = UDim2.fromScale(1, 0.5)
gloss.ZIndex = fill.ZIndex
kid(gloss, "UICorner", "UICorner")
local gg = kid(gloss, "UIGradient", "Fade")
gg.Rotation = 90
gg.Transparency = NS({ NK(0, 0.55), NK(1, 1) })

-- shine sweep: a bright narrow core inside a wider soft band
local sheen = fill:WaitForChild("Sheen")
sheen.BackgroundColor3 = Color3.fromRGB(255, 250, 230)
sheen.BackgroundTransparency = 0
sheen.ZIndex = fill.ZIndex + 1
local sweep = sheen:WaitForChild("Sweep")
sweep.Rotation = 20
sweep.Color = CS(Color3.new(1, 1, 1))
sweep.Transparency = NS({ NK(0, 1), NK(0.3, 1), NK(0.42, 0.55), NK(0.48, 0.05), NK(0.5, 0), NK(0.52, 0.05), NK(0.58, 0.55), NK(0.7, 1), NK(1, 1) })
sweep.Offset = Vector2.new(-1, 0)

-- glowing leading edge (height-driven, so it stays the same shape at any fill width)
local tip = kid(fill, "Frame", "Tip")
tip.AnchorPoint = Vector2.new(0.5, 0.5)
tip.Position = UDim2.fromScale(1, 0.5)
tip.Size = UDim2.fromScale(50, 1.9) -- wide X box: the aspect constraint shrinks it (X = 0 would collapse it)
tip.BackgroundColor3 = Color3.fromRGB(255, 244, 200)
tip.BackgroundTransparency = 0
tip.BorderSizePixel = 0
tip.ZIndex = fill.ZIndex + 1
local ar = kid(tip, "UIAspectRatioConstraint", "Shape")
ar.AspectRatio = 0.3
ar.DominantAxis = Enum.DominantAxis.Height
local tc = kid(tip, "UICorner", "UICorner")
tc.CornerRadius = UDim.new(1, 0)
local tg = kid(tip, "UIGradient", "Glow")
tg.Rotation = 0
tg.Transparency = NS({ NK(0, 1), NK(0.5, 0), NK(1, 1) })

-- label: dark outline so white text reads on the bright gold end
local label = bar:WaitForChild("Label")
label.ZIndex = fill.ZIndex + 2
local ls = kid(label, "UIStroke", "Outline")
ls.Color = Color3.fromRGB(28, 16, 48)
ls.Thickness = 1.5
ls.Transparency = 0.15
ls.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
return "XPBar styled"
