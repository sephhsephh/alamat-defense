-- combat_bars_build.luau (B143) -- run ONCE with execute_luau in the GAME place (Edit). Idempotent.
-- Authors (as real, editable Instances -- no UI is generated at runtime):
--   RS.UITemplates.CombatIcons.{ModifierIcon, StatusIcon, MoreIcon}   badge templates (scripts clone + fill)
--   RS.UITemplates.EnemyHealthbar   -> NameRow (modifier diamonds + name) / bar (+ Overshield layer) / StatusRow
--   RS.UITemplates.BossHealthbar    -> same three rows over the boss's head
--   StarterGui.BossHealth.BarTemplate -> Portrait (ViewportFrame) + Body{NameRow, BarBG(+Overshield), StatusRow}
--   StarterGui.BossHealth.IconTip   -> hover/tap tooltip for the boss bar's badges
-- Layout rule (user, B143): MODIFIERS on the name line, STATUS EFFECTS under the bar. Scale-only sizes.

local RS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local T = RS.UITemplates

local C = Color3.fromRGB
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function square(f)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize }, f)
end
local function row(parent, name, pos, size, align)
	local old = parent:FindFirstChild(name)
	if old then old:Destroy() end
	local r = new("Frame", { Name = name, BackgroundTransparency = 1, Position = pos, Size = size }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.015, 0),
	}, r)
	return r
end
local BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)

-- ===== 1. Badge templates =====
local icons = T:FindFirstChild("CombatIcons") or new("Folder", { Name = "CombatIcons" }, T)
icons:ClearAllChildren()

local mod = new("Frame", { Name = "ModifierIcon", BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1) }, icons)
square(mod)
local dia = new("Frame", { Name = "Diamond", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.7, 0.7), Rotation = 45, BackgroundColor3 = C(255, 255, 255) }, mod)
new("UICorner", { CornerRadius = UDim.new(0.22, 0) }, dia)
new("UIStroke", { Name = "Rim", Color = C(225, 60, 60), Thickness = 1.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, dia)
new("UIGradient", { Rotation = 45, Color = ColorSequence.new(C(70, 40, 58), C(20, 10, 18)) }, dia)
new("ImageLabel", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78),
	BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 2 }, mod)
local mg = new("TextLabel", { Name = "Glyph", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.52, 0.52),
	BackgroundTransparency = 1, Text = "SH", TextScaled = true, FontFace = BOLD, TextColor3 = C(255, 235, 235), ZIndex = 3 }, mod)
new("UIStroke", { Thickness = 1, Color = C(0, 0, 0) }, mg)
local mc = new("TextLabel", { Name = "Count", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1.08, 1.08), Size = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Text = "3", TextScaled = true, FontFace = BOLD, TextColor3 = C(255, 222, 120), ZIndex = 4, Visible = false }, mod)
new("UIStroke", { Thickness = 1.2, Color = C(0, 0, 0) }, mc)

local st = new("Frame", { Name = "StatusIcon", BackgroundTransparency = 1, Size = UDim2.fromScale(0, 1) }, icons)
square(st)
local disc = new("Frame", { Name = "Disc", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(0.9, 0.9), BackgroundColor3 = C(255, 120, 40) }, st)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, disc)
new("UIStroke", { Name = "Ring", Color = C(255, 255, 255), Thickness = 1.4, Transparency = 0.15, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, disc)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(255, 255, 255), C(150, 150, 150)) }, disc)
new("ImageLabel", { Name = "Icon", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.72),
	BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = "", ZIndex = 2 }, st)
local sg = new("TextLabel", { Name = "Glyph", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.56, 0.56),
	BackgroundTransparency = 1, Text = "BU", TextScaled = true, FontFace = BOLD, TextColor3 = C(255, 255, 255), ZIndex = 3 }, st)
new("UIStroke", { Thickness = 1, Color = C(0, 0, 0) }, sg)
local ss = new("TextLabel", { Name = "Stack", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1.1, 1.1), Size = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Text = "3", TextScaled = true, FontFace = BOLD, TextColor3 = C(255, 255, 255), ZIndex = 4, Visible = false }, st)
new("UIStroke", { Thickness = 1.2, Color = C(0, 0, 0) }, ss)

local more = new("TextLabel", { Name = "MoreIcon", BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0.8), Text = "+2",
	TextScaled = true, FontFace = BOLD, TextColor3 = C(235, 235, 245) }, icons)
square(more)
new("UIStroke", { Thickness = 1, Color = C(0, 0, 0) }, more)

-- an Overshield layer: a pale-cyan bar laid OVER the health fill; it empties first (EnemyModifiers.OnDamage).
local function overshield(bg, box, z, corner)
	local old = bg:FindFirstChild("Overshield")
	if old then old:Destroy() end
	local o = new("Frame", { Name = "Overshield", AnchorPoint = box.AnchorPoint, Position = box.Position, Size = box.Size,
		BackgroundColor3 = C(150, 225, 255), ZIndex = z, Visible = false }, bg)
	if corner then new("UICorner", { CornerRadius = corner }, o) end
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C(235, 250, 255)), ColorSequenceKeypoint.new(0.5, C(150, 225, 255)), ColorSequenceKeypoint.new(1, C(70, 150, 230)) }) }, o)
	new("UIStroke", { Color = C(255, 255, 255), Thickness = 1, Transparency = 0.35 }, o)
	return o
end

-- ===== 2. Enemy billboard: [◆ ◆ Name] / [bar] / [● ● ●] =====
local eb = T.EnemyHealthbar
eb.Size = UDim2.new(4.4, 0, 2.1, 0)
local ebg = eb.Background
ebg.AnchorPoint = Vector2.new(0, 0)
ebg.Position = UDim2.fromScale(0, 0.34)
ebg.Size = UDim2.fromScale(1, 0.28)
overshield(ebg, ebg.Fill, 4, UDim.new(1, 0)).Position = UDim2.fromScale(0, 0.5)
ebg.Overshield.AnchorPoint = ebg.Fill.AnchorPoint
local ename = eb:FindFirstChild("NameText") or eb.NameRow:FindFirstChild("NameText")
local enr = row(eb, "NameRow", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.3))
ename.Parent = enr
ename.AnchorPoint = Vector2.new(0, 0)
ename.Position = UDim2.fromScale(0, 0)
ename.Size = UDim2.fromScale(0, 1)
ename.TextXAlignment = Enum.TextXAlignment.Left
ename.LayoutOrder = 100
new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, ename)
row(eb, "StatusRow", UDim2.fromScale(0, 0.66), UDim2.fromScale(1, 0.3))

-- ===== 3. Boss billboard over the head =====
local bb = T.BossHealthbar
bb.Size = UDim2.new(12, 0, 3.1, 0)
local bname = bb:FindFirstChild("BossName") or bb.NameRow:FindFirstChild("BossName")
local bnr = row(bb, "NameRow", UDim2.fromScale(0.02, 0), UDim2.fromScale(0.96, 0.32))
bname.Parent = bnr
bname.AnchorPoint = Vector2.new(0, 0)
bname.Position = UDim2.fromScale(0, 0)
bname.Size = UDim2.fromScale(0, 1)
bname.LayoutOrder = 1
new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, bname)
local bbg = bb.BarBG
bbg.AnchorPoint = Vector2.new(0.5, 0)
bbg.Position = UDim2.fromScale(0.5, 0.34)
bbg.Size = UDim2.fromScale(0.96, 0.3)
overshield(bbg, bbg.Fill, 3, UDim.new(1, 0))
row(bb, "StatusRow", UDim2.fromScale(0.02, 0.68), UDim2.fromScale(0.96, 0.28))

-- ===== 4. Boss screen bar: Portrait | Body{ NameRow, BarBG, StatusRow } =====
local bh = SG.BossHealth
local prev = bh.Container:FindFirstChild("_Preview")
if prev then prev:Destroy() end
bh.Container.Size = UDim2.fromScale(0.3, bh.Container.Size.Y.Scale)
local tpl = bh.BarTemplate
tpl.Size = UDim2.fromScale(1, 0.34)
local body = tpl:FindFirstChild("Body") or new("Frame", { Name = "Body", BackgroundTransparency = 1 }, tpl)
body.Position = UDim2.fromScale(0.21, 0)
body.Size = UDim2.fromScale(0.79, 1)
local pv = tpl:FindFirstChild("Portrait")
if pv then pv:Destroy() end
pv = new("ViewportFrame", { Name = "Portrait", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0),
	Size = UDim2.fromScale(0, 1), Ambient = C(200, 200, 210), LightColor = C(255, 245, 230), LightDirection = Vector3.new(-0.4, -1, -0.6) }, tpl)
square(pv)
local cam = new("Camera", { Name = "PortraitCam", FieldOfView = 30 }, pv)
pv.CurrentCamera = cam
new("WorldModel", { Name = "World" }, pv)
local tname = tpl:FindFirstChild("BossName") or (body:FindFirstChild("NameRow") and body.NameRow:FindFirstChild("BossName"))
local tnr = row(body, "NameRow", UDim2.fromScale(0, 0), UDim2.fromScale(1, 0.27))
tname.Parent = tnr
tname.AnchorPoint = Vector2.new(0, 0)
tname.Position = UDim2.fromScale(0, 0)
tname.Size = UDim2.fromScale(0, 1)
tname.TextXAlignment = Enum.TextXAlignment.Left
tname.LayoutOrder = 1
new("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, tname)
local tbg = tpl:FindFirstChild("BarBG") or body.BarBG
tbg.Parent = body
tbg.AnchorPoint = Vector2.new(0, 0)
tbg.Position = UDim2.fromScale(0, 0.29)
tbg.Size = UDim2.fromScale(1, 0.45)
overshield(tbg, tbg.DamageTrail, 3, UDim.new(1, 0))
row(body, "StatusRow", UDim2.fromScale(0.04, 0.76), UDim2.fromScale(0.94, 0.24))
-- Portrait + Body sit side by side, centred as a group; Body's aspect (3.6 = 8:1 bar x 0.45 height) makes the
-- name line and the status row exactly as wide as the bar art (its own 8:1 constraint would otherwise shrink it).
local lay = tpl:FindFirstChildOfClass("UIListLayout") or new("UIListLayout", {}, tpl)
lay.FillDirection = Enum.FillDirection.Horizontal; lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
lay.VerticalAlignment = Enum.VerticalAlignment.Center; lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Padding = UDim.new(0.012, 0)
pv.LayoutOrder = 1
body.LayoutOrder = 2
body.Size = UDim2.fromScale(0, 1)
new("UIAspectRatioConstraint", { AspectRatio = 3.6, DominantAxis = Enum.DominantAxis.Height, AspectType = Enum.AspectType.ScaleWithParentSize }, body)
new("UIGradient", { Name = "Fade", Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.72, 0), NumberSequenceKeypoint.new(1, 1) }) }, pv)

-- ===== 5. Badge tooltip (boss bar; hover on PC, tap on mobile) =====
local tip = bh:FindFirstChild("IconTip")
if tip then tip:Destroy() end
tip = new("Frame", { Name = "IconTip", Visible = false, AnchorPoint = Vector2.new(0, 0), Size = UDim2.fromScale(0.16, 0.075),
	BackgroundColor3 = C(24, 16, 38), BackgroundTransparency = 0.05, ZIndex = 20 }, bh)
new("UICorner", { CornerRadius = UDim.new(0.18, 0) }, tip)
new("UIStroke", { Color = C(214, 170, 90), Thickness = 1.5 }, tip)
new("UIPadding", { PaddingLeft = UDim.new(0.05, 0), PaddingRight = UDim.new(0.05, 0), PaddingTop = UDim.new(0.1, 0), PaddingBottom = UDim.new(0.1, 0) }, tip)
new("TextLabel", { Name = "Title", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.42), TextScaled = true, FontFace = BOLD,
	TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = C(255, 222, 140), Text = "Shielded", ZIndex = 21 }, tip)
new("TextLabel", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.46), Size = UDim2.fromScale(1, 0.54),
	TextScaled = true, TextWrapped = true, FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = C(230, 225, 240),
	Text = "Blocks the next hits completely.", ZIndex = 21 }, tip)

return "combat bars built"
