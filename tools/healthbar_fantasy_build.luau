-- healthbar_fantasy_build.luau (B149) -- run with execute_luau in the GAME (Edit).
-- User: "make the billboard health gui of normal enemies and bosses thinner, more fantasy looks, the healthbar
-- billboard gui is too fluffy / fat. Also fix the healthbar, when depleted near to 0 it overlaps on the left side."
-- Reshapes RS.UITemplates.EnemyHealthbar and RS.UITemplates.BossHealthbar IN PLACE (node names kept):
--   * the bar is about HALF as thick: a dark jewel track, thin gold edge, a static Gloss over everything, quarter
--     ticks, and a gold diamond CAP with a gem at each end (CapL / CapR);
--   * Fill / DamageTrail / Overshield are FULL SIZE and flagged `MaskFill` with a rotation-0 UIGradient `Mask`:
--     HealthBarFX / FloatingHealthbars / BossHealthUI cut them with the mask instead of shrinking the width, so a
--     nearly empty bar can no longer bulge out past the rounded left end;
--   * the HP number moves OUT of the thin bar to the end of the name line (HealthText, found by name).
-- Old templates: ServerStorage._UIBackup_B149.

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

local T = RS:WaitForChild("UITemplates")
local bk = SS:FindFirstChild("_UIBackup_B149") or new("Folder", { Name = "_UIBackup_B149" }, SS)
for _, n in ipairs({ "EnemyHealthbar", "BossHealthbar" }) do
	if not bk:FindFirstChild(n) then T[n]:Clone().Parent = bk end
end

local RADIUS = UDim.new(0.5, 0)

-- a full-size layer cut by its own `Mask` gradient (see HealthBarFX.frameMask)
local function maskify(layer: Frame, color: Color3?, transparency: number?)
	layer.AnchorPoint = Vector2.new(0, 0.5)
	layer.Position = UDim2.fromScale(0, 0.5)
	layer.Size = UDim2.fromScale(1, 1)
	if color then layer.BackgroundColor3 = color end
	if transparency then layer.BackgroundTransparency = transparency end
	for _, c in ipairs(layer:GetChildren()) do
		if c:IsA("UIGradient") or c:IsA("UIStroke") or c.Name == "Shine" then c:Destroy() end
	end
	local corner = layer:FindFirstChildOfClass("UICorner") or new("UICorner", {}, layer)
	corner.CornerRadius = RADIUS
	new("UIGradient", { Name = "Mask", Rotation = 0 }, layer)
	layer:SetAttribute("MaskFill", true)
end

local function cap(bg: Frame, name: string, x: number, gem: Color3)
	local old = bg:FindFirstChild(name)
	if old then old:Destroy() end
	local c = new("Frame", { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5),
		Size = UDim2.fromScale(3, 2), Rotation = 45, BackgroundColor3 = C(255, 255, 255), ZIndex = 8 }, bg)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, c)
	new("UICorner", { CornerRadius = UDim.new(0.18, 0) }, c)
	new("UIGradient", { Rotation = -45, Color = CS(C(255, 240, 180), C(196, 124, 46)) }, c)
	new("UIStroke", { Color = C(48, 26, 8), Thickness = 1, Transparency = 0.1 }, c)
	local g = new("Frame", { Name = "Gem", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = gem, ZIndex = 9 }, c)
	new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, g)
	new("UIGradient", { Rotation = -45, Color = CS(gem:Lerp(Color3.new(1, 1, 1), 0.55), gem:Lerp(Color3.new(0, 0, 0), 0.35)) }, g)
end

local function reshapeBar(bg: Frame, opt: any)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.Position = UDim2.fromScale(0.5, opt.Y)
	bg.Size = UDim2.fromScale(opt.W, opt.H)
	bg.BackgroundColor3 = C(255, 255, 255)
	bg.BackgroundTransparency = 0
	local corner = bg:FindFirstChildOfClass("UICorner") or new("UICorner", {}, bg)
	corner.CornerRadius = RADIUS
	-- the dark jewel track
	local glass = bg:FindFirstChild("Glass")
	if not (glass and glass:IsA("UIGradient")) then
		for _, g in ipairs(bg:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
		glass = new("UIGradient", { Name = "Glass" }, bg)
	end
	glass.Rotation = 90
	glass.Color = CS({ CK(0, C(58, 40, 88)), CK(0.5, C(26, 16, 44)), CK(1, C(12, 7, 22)) })
	glass.Transparency = NS(0)
	local edge = bg:FindFirstChild("Edge") or bg:FindFirstChildOfClass("UIStroke")
	if not edge then edge = new("UIStroke", {}, bg) end
	edge.Name = "Edge"
	edge.Color = C(255, 208, 118)
	edge.Thickness = opt.Edge
	edge.Transparency = 0
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	for _, g in ipairs(edge:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end

	maskify(bg:FindFirstChild("DamageTrail") :: Frame, C(255, 228, 168), 0.1)
	bg.DamageTrail.ZIndex = 2
	maskify(bg:FindFirstChild("Fill") :: Frame, nil, 0)
	bg.Fill.ZIndex = 3
	local os = bg:FindFirstChild("Overshield")
	if os then
		maskify(os :: Frame, C(160, 232, 255), 0)
		os.ZIndex = 4
	end

	-- the gloss: static, so it needs no mask -- it lights the filled part and the empty track alike
	local gl = bg:FindFirstChild("Gloss")
	if gl then gl:Destroy() end
	gl = new("Frame", { Name = "Gloss", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C(255, 255, 255), ZIndex = 5 }, bg)
	new("UICorner", { CornerRadius = RADIUS }, gl)
	new("UIGradient", { Rotation = 90, Transparency = NS({ NK(0, 0.45), NK(0.4, 0.8), NK(0.5, 1), NK(1, 1) }) }, gl)

	-- quarter ticks (scale widths -- the old ones were 2 px offsets)
	local ticks = bg:FindFirstChild("Ticks")
	if ticks then
		ticks.ZIndex = 6
		for _, t in ipairs(ticks:GetChildren()) do
			if t:IsA("Frame") then
				t.Size = UDim2.fromScale(0.006, 0.62)
				t.BackgroundTransparency = 0.5
				t.ZIndex = 6
			end
		end
	end

	cap(bg, "CapL", 0, opt.Gem)
	cap(bg, "CapR", 1, opt.Gem)
end

-- the HP number: out of the bar, onto the end of the name line
local function moveHealthText(bg: Frame, nameRow: Frame)
	local ht = bg:FindFirstChild("HealthText") or nameRow:FindFirstChild("HealthText")
	if not ht then return end
	ht.Parent = nameRow
	ht.AnchorPoint = Vector2.new(0, 0)
	ht.Position = UDim2.fromScale(0, 0)
	ht.Size = UDim2.fromScale(0.3, 0.78)
	ht.LayoutOrder = 100
	ht.TextScaled = true
	ht.FontFace = BOLD
	ht.TextXAlignment = Enum.TextXAlignment.Right
	ht.TextColor3 = C(255, 236, 196)
	ht.BackgroundTransparency = 1
	ht.ZIndex = 5
	local st = ht:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, ht)
	st.Color = C(16, 8, 26)
	st.Thickness = 1.2
end

-- ===== enemy =====
local eb = T.EnemyHealthbar
eb.Size = UDim2.new(4.4, 0, 1.9, 0)
eb.NameRow.Position = UDim2.fromScale(0, 0)
eb.NameRow.Size = UDim2.fromScale(1, 0.34)
eb.StatusRow.Position = UDim2.fromScale(0, 0.62)
eb.StatusRow.Size = UDim2.fromScale(1, 0.34)
reshapeBar(eb.Background, { Y = 0.47, W = 0.86, H = 0.13, Edge = 1, Gem = C(230, 60, 72) })
moveHealthText(eb.Background, eb.NameRow)
eb.NameRow.NameText.LayoutOrder = 50 -- name first, then the HP number (modifier diamonds sit before both)
eb.NameRow.HealthText.LayoutOrder = 200

-- ===== boss (over the head) =====
local bb = T.BossHealthbar
bb.Size = UDim2.new(12, 0, 2.6, 0)
bb.NameRow.Position = UDim2.fromScale(0.02, 0)
bb.NameRow.Size = UDim2.fromScale(0.96, 0.36)
bb.StatusRow.Position = UDim2.fromScale(0.02, 0.64)
bb.StatusRow.Size = UDim2.fromScale(0.96, 0.32)
reshapeBar(bb.BarBG, { Y = 0.48, W = 0.9, H = 0.15, Edge = 1.6, Gem = C(176, 92, 255) })
moveHealthText(bb.BarBG, bb.NameRow)
bb.NameRow.BossName.LayoutOrder = 50
bb.NameRow.HealthText.LayoutOrder = 200

-- the SCREEN boss bar (StarterGui.BossHealth.BarTemplate): its Fill is an IMAGE (already masked); its frame
-- DamageTrail + Overshield get the same MaskFill treatment, keeping their authored channel box.
local tpl = game:GetService("StarterGui").BossHealth:FindFirstChild("BarTemplate", true)
if not bk:FindFirstChild("BossHealthBarTemplate") then local c = tpl:Clone() c.Name = "BossHealthBarTemplate" c.Parent = bk end
for _, n in ipairs({ "DamageTrail", "Overshield" }) do
	local layer = tpl.Body.BarBG:FindFirstChild(n)
	for _, c in ipairs(layer:GetChildren()) do
		if c:IsA("UIGradient") or c:IsA("UIStroke") then c:Destroy() end
	end
	if n == "Overshield" then layer.BackgroundColor3 = C(160, 232, 255) end
	new("UIGradient", { Name = "Mask" }, layer)
	layer:SetAttribute("MaskFill", true)
end

return "health bars reshaped"
