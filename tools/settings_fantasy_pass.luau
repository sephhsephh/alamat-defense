-- tools/settings_fantasy_pass.luau (B152) -- run with execute_luau in EACH Place (Edit). The Settings screen is ONE
-- design shared by both Places (settings.md: "same structure, same gui"); this restyles its AUTHORED templates in
-- place -- node names untouched, so the shared SettingsUI (which clones and fills them) keeps working.
-- User: "fix settings layout in the lobby, all are cramped to the left. use white themed images use ui gradients,
-- vfx etc.., not just frames laid out." (the cramping itself = the SettingsUI grid fix, e27f5dd9).
--   rows      : violet -> night card gradient, gold-gradient edge, a gold Accent bar, a faint white Rune watermark
--               behind the control (Theme.Images.Engraving, tinted), titles in the gold-serif Label font
--   controls  : Toggle + action Button become Alamat PLATES (their green / red / violet still comes from SettingsUI)
--   slider    : night track, gold -> violet fill, a gold GEM handle with a glow
--   sections  : gold header label, gold line fading out, gold-tinted icon
--   panel     : gold gradient on the frame stroke, a huge faint Engraving seal behind the content, two sparkles
-- Backup: ServerStorage._UIBackup_B152.Settings.

local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any
local P = require(SS.DevTools.AlamatPlate:Clone())
local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new

local gui = SG:WaitForChild("Settings")
local bk = SS:FindFirstChild("_UIBackup_B152") or Instance.new("Folder")
bk.Name = "_UIBackup_B152"
bk.Parent = SS
if not bk:FindFirstChild("Settings") then gui:Clone().Parent = bk end

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function grad(o: Instance, name: string, props: { [string]: any })
	local g = o:FindFirstChild(name) or new("UIGradient", { Name = name }, o)
	for k, v in pairs(props) do (g :: any)[k] = v end
	return g
end
local function drop(o: Instance, name: string)
	local c = o:FindFirstChild(name)
	if c then c:Destroy() end
end

-- ===== rows =====
for _, n in ipairs({ "ToggleRowTemplate", "SliderRowTemplate", "ActionRowTemplate", "KeybindRowTemplate" }) do
	local row = gui:FindFirstChild(n)
	if row and row:IsA("GuiObject") then
		row.BackgroundColor3 = C(255, 255, 255)
		row.BackgroundTransparency = 0
		row.ClipsDescendants = true
		for _, g in ipairs(row:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
		grad(row, "Card", { Rotation = 0, Color = CS({ CK(0, C(52, 34, 92)), CK(0.55, C(30, 20, 56)), CK(1, C(18, 12, 34)) }) })
		local edge = row:FindFirstChild("Edge") :: UIStroke?
		if edge then
			edge.Color = C(255, 255, 255)
			edge.Transparency = 0.35
			edge.Thickness = 1.2
			grad(edge, "Gold", { Color = Theme.Gold })
		end
		drop(row, "Accent")
		local acc = new("Frame", { Name = "Accent", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.012, 0.5),
			Size = UDim2.fromScale(0.008, 0.66), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 4 }, row)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, acc)
		grad(acc, "Gold", { Rotation = 90, Color = CS(C(255, 236, 170), C(214, 140, 46)) })
		drop(row, "Rune")
		local rune = new("ImageLabel", { Name = "Rune", Image = Theme.Images.Engraving, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.86, 0.5), Size = UDim2.fromScale(3, 1.7),
			ImageTransparency = 0.86, ZIndex = 2 }, row)
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, rune)
		grad(rune, "Tint", { Color = Theme.tint("Violet") })
		local title = row:FindFirstChild("Title") :: TextLabel?
		if title then
			title.FontFace = Theme.Fonts.Label
			title.TextColor3 = C(255, 240, 206)
			title.Position = UDim2.new(0.045, 0, title.Position.Y.Scale, 0)
		end
		local desc = row:FindFirstChild("Desc") :: TextLabel?
		if desc then
			desc.TextColor3 = C(196, 182, 228)
			desc.Position = UDim2.new(0.045, 0, desc.Position.Y.Scale, 0)
		end
		-- the row's control becomes a Plate (colour still painted by SettingsUI)
		for _, cn in ipairs({ "Toggle", "Button" }) do
			local b = row:FindFirstChild(cn)
			if b and b:IsA("GuiButton") then P.convert(b, nil) end
		end
		local key = row:FindFirstChild("KeyButton")
		if key and key:IsA("GuiButton") then P.convert(key, "Night") end
	end
end

-- ===== slider =====
local slider = gui:FindFirstChild("SliderRowTemplate")
local track = slider and slider:FindFirstChild("Track")
if track and track:IsA("GuiObject") then
	track.BackgroundColor3 = C(14, 9, 26)
	local ts = track:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, track)
	ts.Color = C(255, 255, 255)
	ts.Thickness = 1
	ts.Transparency = 0.4
	grad(ts, "Gold", { Color = Theme.Gold })
	local fill = track:FindFirstChild("Fill")
	if fill and fill:IsA("GuiObject") then
		fill.BackgroundColor3 = C(255, 255, 255)
		for _, g in ipairs(fill:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
		grad(fill, "Glow", { Color = CS({ CK(0, C(255, 214, 110)), CK(0.6, C(236, 140, 255)), CK(1, C(150, 96, 255)) }) })
		if not fill:FindFirstChildOfClass("UICorner") then new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill) end
	end
	local handle = track:FindFirstChild("Handle")
	if handle and handle:IsA("GuiObject") then
		handle.Rotation = 45
		handle.BackgroundColor3 = C(255, 255, 255)
		for _, g in ipairs(handle:GetChildren()) do if g:IsA("UIGradient") or g:IsA("UICorner") then g:Destroy() end end
		new("UICorner", { CornerRadius = UDim.new(0.22, 0) }, handle)
		grad(handle, "Gem", { Rotation = -45, Color = CS(C(255, 246, 204), C(206, 132, 40)) })
		local hs = handle:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, handle)
		hs.Color = C(60, 32, 8)
		hs.Thickness = 1.2
		drop(handle, "Glow")
		local glow = new("ImageLabel", { Name = "Glow", Image = Theme.Images.GlowRing, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(2.2, 2.2),
			ImageTransparency = 0.35, ZIndex = handle.ZIndex - 1 }, handle)
		grad(glow, "Tint", { Color = Theme.tint("Gold") })
	end
end

-- ===== section header =====
local sec = gui:FindFirstChild("SectionTemplate")
local header = sec and sec:FindFirstChild("Header")
if header then
	local label = header:FindFirstChild("Label") :: TextLabel?
	if label then
		label.FontFace = Theme.Fonts.Label
		label.TextColor3 = C(255, 255, 255)
		grad(label, "Gold", { Rotation = 90, Color = Theme.LabelGold })
	end
	local line = header:FindFirstChild("Line") :: Frame?
	if line then
		line.BackgroundColor3 = C(255, 255, 255)
		grad(line, "Fade", { Color = CS(C(255, 222, 140), C(196, 120, 255)), Transparency = NS({ NK(0, 0), NK(0.7, 0.4), NK(1, 1) }) })
	end
	local icon = header:FindFirstChild("Icon") :: ImageLabel?
	if icon then icon.ImageColor3 = C(255, 214, 120) end
end

-- ===== category tabs =====
local cat = gui:FindFirstChild("CategoryButtonTemplate")
if cat then
	local st = cat:FindFirstChildOfClass("UIStroke")
	if st then grad(st, "Gold", { Color = Theme.Gold }) end
	local label = cat:FindFirstChild("Label") :: TextLabel?
	if label then label.FontFace = Theme.Fonts.Label end
end

-- ===== panel =====
local panel = gui:FindFirstChild("Panel")
if panel then
	local gs = panel:FindFirstChild("GoldStroke") :: UIStroke?
	if gs then
		gs.Color = C(255, 255, 255)
		grad(gs, "Gold", { Color = Theme.Gold })
	end
	drop(panel, "Seal")
	local seal = new("ImageLabel", { Name = "Seal", Image = Theme.Images.MagicCircle, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.56), Size = UDim2.fromScale(3, 0.95),
		ImageTransparency = 0.93, ZIndex = 2 }, panel)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, seal)
	grad(seal, "Tint", { Color = Theme.tint("Violet") })
	for i, at in ipairs({ Vector2.new(0.31, 0.03), Vector2.new(0.97, 0.97) }) do
		drop(panel, "Sparkle" .. i)
		local sp = new("ImageLabel", { Name = "Sparkle" .. i, Image = Theme.Images.Sparkles[i], BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(at.X, at.Y), Size = UDim2.fromScale(3, 0.07),
			ImageTransparency = 0.15, ZIndex = 7 }, panel)
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, sp)
		grad(sp, "Tint", { Color = Theme.tint("Gold") })
	end
	local content = panel:FindFirstChild("Content")
	if content and content:IsA("GuiObject") then
		content.BackgroundTransparency = 0.45
		content.BackgroundColor3 = C(255, 255, 255)
		grad(content, "Depth", { Rotation = 90, Color = CS(C(30, 20, 56), C(10, 6, 20)) })
	end
end

return "settings fantasy pass done"
