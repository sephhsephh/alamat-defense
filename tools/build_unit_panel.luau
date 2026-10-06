-- tools/build_unit_panel.luau (B114) -- AUTHORS the selected-unit panel (StarterGui.TowerSelection) in the
-- Alamat violet/gold style, laid out like the user's references. Run via execute_luau in the GAME (Edit mode).
-- Re-runnable: restyles the existing B86 instances IN PLACE (names unchanged, so TowerSelectionUI keeps
-- working) and creates the B114 pieces. Uses ServerStorage.DevTools.AlamatTheme (edit-time helpers).
--
-- New authored pieces (driven by TowerSelectionUI):
--   Root.CloseButton                         red X -- the ONLY way to close the panel (user rule)
--   Root.PortraitCard.Badges.TraitBadge.Icon the trait's real icon (TraitDefinitions.Icon)
--   Root.AbilityColumn{ UIListLayout, AutoButton, PassivesButton }   ability buttons are cloned in between
--   Templates.AbilityButtonTemplate{ Icon, Shade, CdText, Ring }
--   PassivesWindow{ Header{Title, Tab}, List(Scrolling), CloseButton }  + Templates.PassiveRowTemplate{ Name, Body }
--   BreakdownPanel{ Tabs, PermHeader, PermGrid, TempHeader, TempList, Total{Label, Sub, Value}, CloseButton }
--     + Templates.BreakdownTabTemplate{ Icon, Label }, SourceTileTemplate{ Icon, Name, Kind, Value },
--       TempRowTemplate{ Name, Left, Value }
local T = loadstring(game.ServerStorage.DevTools.AlamatTheme.Source)()
local C = Color3.fromRGB
local CS = game:GetService("CollectionService")
local IC = loadstring(game.ReplicatedStorage.Shared.IconCatalog.Source)()
local gui = game.StarterGui.TowerSelection
local root = gui.Root
local tpl = gui.Templates

local function place(o, pos, size, anchor)
	o.Position = pos
	o.Size = size
	if anchor then o.AnchorPoint = anchor end
end
local function dark(o, tr)
	T.strip(o)
	o.BackgroundColor3 = Color3.new(1, 1, 1)
	o.BackgroundTransparency = tr or 0.1
	T.mk("UIGradient", o, { Name = "Glass", Rotation = 90, Color = T.seq({ C(34, 20, 56), C(18, 10, 32) }) })
	T.corner(o, 0.18)
	T.mk("UIStroke", o, { Name = "Edge", Thickness = 1.5, Color = C(110, 80, 160), Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function circleBadge(b)
	T.strip(b)
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.BackgroundTransparency = 0
	b.AutoButtonColor = false
	T.mk("UIGradient", b, { Name = "Fill", Rotation = 90, Color = T.seq({ C(70, 44, 112), C(30, 16, 52) }) })
	T.corner(b, 1)
	T.goldStroke(b, "Gold", 1.8)
	T.square(b)
	if b:FindFirstChild("Glyph") then b.Glyph.TextColor3 = C(255, 220, 140) end
end

-- ===== ROOT: left side, mid-height (user's refs) =====
root.AnchorPoint = Vector2.new(0, 0.5)
root.Position = UDim2.fromScale(0.006, 0.52)
root.Size = UDim2.fromScale(0.56, 0.56)
root.BackgroundTransparency = 1
for _, c in ipairs(root:GetChildren()) do if c:IsA("UIStroke") or c:IsA("UIGradient") or c:IsA("UICorner") then c:Destroy() end end
gui.DisplayOrder = 2 -- above the match HUD (both were 0 = undefined order)
T.mk("UIAspectRatioConstraint", root, { Name = "UIAspectRatioConstraint", AspectRatio = 1.72, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width })

-- ===== PORTRAIT CARD =====
local pc = root.PortraitCard
place(pc, UDim2.fromScale(0, 0), UDim2.fromScale(0.34, 0.74), Vector2.new(0, 0))
local tierStroke = pc:FindFirstChild("UIStroke") -- UnitCard.tierStroke animates this one; keep it
for _, c in ipairs(pc:GetChildren()) do if c:IsA("UIGradient") or c:IsA("UICorner") then c:Destroy() end end
T.glass(pc, "Violet", 0.04)
T.corner(pc, 0.07)
if tierStroke then tierStroke.Thickness = 3 end

local name = pc.NameLabel
place(name, UDim2.fromScale(0.5, 0.015), UDim2.fromScale(0.94, 0.11), Vector2.new(0.5, 0))
name.FontFace = T.FRED
name.TextXAlignment = Enum.TextXAlignment.Center
name.TextScaled = true
T.goldText(name)

local vp = pc.Viewport
place(vp, UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.66, 0.46), Vector2.new(0.5, 0))
vp.BackgroundTransparency = 1

local badges = pc.Badges
place(badges, UDim2.fromScale(0.03, 0.14), UDim2.fromScale(0.15, 0.44), Vector2.new(0, 0))
for _, b in ipairs(badges:GetChildren()) do
	if b:IsA("GuiButton") then
		circleBadge(b)
		b.Size = UDim2.fromScale(1, 0.3)
	end
end
-- the trait's REAL icon (the old badge showed the first letter)
local tb = badges.TraitBadge
T.icon(tb, "Icon", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.78, 0.78), Image = "", ZIndex = tb.ZIndex + 1 })

local strip = pc.IconStrip
place(strip, UDim2.fromScale(0.97, 0.14), UDim2.fromScale(0.15, 0.44), Vector2.new(1, 0))
local stripIcons = { RangeToggle = "Search", VfxToggle = "View", InfoButton = "Info" }
for _, b in ipairs(strip:GetChildren()) do
	if b:IsA("GuiButton") then
		circleBadge(b)
		b.Size = UDim2.fromScale(1, 0.3)
		local key = stripIcons[b.Name]
		if key then
			T.icon(b, "Icon", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), Image = IC.get(key), ZIndex = b.ZIndex + 1 })
			if b:FindFirstChild("Glyph") then b.Glyph.Visible = false end
		end
	end
end

local pr = pc.PriorityRow
place(pr, UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.94, 0.17), Vector2.new(0.5, 0))
pr.PriorityCaption.Text = "Unit Priority:"
pr.PriorityCaption.FontFace = T.FRED
pr.PriorityValue.FontFace = T.FRED
for _, n in ipairs({ "PrevButton", "NextButton" }) do
	local b = pr[n]
	T.strip(b)
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.AutoButtonColor = false
	T.mk("UIGradient", b, { Name = "Fill", Rotation = 90, Color = T.seq({ C(90, 60, 140), C(46, 26, 80) }) })
	T.corner(b, 0.25)
	T.goldStroke(b, "Gold", 1.5)
	T.mk("UIScale", b, { Name = "Press", Scale = 1 })
	CS:AddTag(b, "AlamatPress")
	-- a UIGradient tints the button's OWN text, so the arrow is a child label
	b.Text = ""
	T.text(b, "Arrow", if n == "PrevButton" then "<" else ">", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), ZIndex = b.ZIndex + 1, _max = 24 })
end

local function bigButton(b, accent, key)
	T.strip(b)
	local a = T.ACCENT[accent]
	b.BackgroundColor3 = Color3.new(1, 1, 1)
	b.BackgroundTransparency = 0
	b.AutoButtonColor = false
	T.mk("UIGradient", b, { Name = "Fill", Rotation = 90, Color = T.seq({ a[1], a[2] }) })
	T.corner(b, 0.18)
	T.goldStroke(b, "Gold", 2)
	T.mk("UIScale", b, { Name = "Press", Scale = 1 })
	CS:AddTag(b, "AlamatPress")
	b.Caption.FontFace = T.FRED
	b.Value.FontFace = T.FRED
	-- hotkey chip in the corner, like the ref (painted with the player's key by KeyHints)
	local chip = T.mk("Frame", b, { Name = "KeyChip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 4, 1, 4), Size = UDim2.fromScale(0.22, 0.42), BackgroundColor3 = C(250, 246, 236), ZIndex = b.ZIndex + 2 })
	T.corner(chip, 0.25)
	T.square(chip)
	T.mk("UIStroke", chip, { Name = "Edge", Thickness = 1.5, Color = C(30, 20, 40) })
	T.text(chip, "Key", key, { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), TextColor3 = C(30, 20, 40), ZIndex = b.ZIndex + 3, _max = 20 })
	chip.Key:FindFirstChild("TextStroke").Enabled = false
end
place(pc.SellButton, UDim2.fromScale(0.03, 0.97), UDim2.fromScale(0.45, 0.17), Vector2.new(0, 1))
place(pc.UpgradeButton, UDim2.fromScale(0.97, 0.97), UDim2.fromScale(0.45, 0.17), Vector2.new(1, 1))
bigButton(pc.SellButton, "Crimson", "X")
bigButton(pc.UpgradeButton, "Jade", "E")

-- ===== STATS CARD + TILES =====
local sc = root.StatsCard
place(sc, UDim2.fromScale(0.355, 0), UDim2.fromScale(0.395, 0.47), Vector2.new(0, 0))
T.strip(sc)
T.panel(sc, "Gold", { Corner = 0.08, Thick = 2.5, Transparency = 0.04 })
local tiles = root.TilesRow
place(tiles, UDim2.fromScale(0.355, 0.5), UDim2.fromScale(0.395, 0.24), Vector2.new(0, 0))
tiles.BackgroundTransparency = 1
local tile = tpl.TileTemplate
dark(tile, 0.05)

-- ===== CLOSE (the ONLY way to close the panel) =====
local close = T.button("TextButton", root, "CloseButton", "Crimson", "X", {
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.75, 0.01), Size = UDim2.fromScale(0.07, 0.12), ZIndex = 20,
})
T.corner(close, 1)
T.square(close)

-- ===== ABILITY COLUMN =====
local col = root.AbilityColumn
place(col, UDim2.fromScale(0.765, 0), UDim2.fromScale(0.105, 0.74), Vector2.new(0, 0))
col.BackgroundTransparency = 1
T.mk("UIListLayout", col, { Name = "UIListLayout", FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.02, 0), HorizontalAlignment = Enum.HorizontalAlignment.Center })
for _, old in ipairs({ "AbilityButton", "AbilityAutoButton" }) do
	local o = col:FindFirstChild(old)
	if o then o.Name = old .. "_RetiredB114"; o.Visible = false; o.Parent = tpl end
end
local ab = T.mk("TextButton", tpl, { Name = "AbilityButtonTemplate", Text = "", AutoButtonColor = false, Visible = false, Size = UDim2.fromScale(1, 0.19), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
T.mk("UIGradient", ab, { Name = "Fill", Rotation = 135, Color = T.seq({ C(80, 50, 130), C(28, 14, 50) }) })
T.corner(ab, 0.14)
T.goldStroke(ab, "Violet", 2.2, "Ring")
T.square(ab)
T.mk("UIScale", ab, { Name = "Press", Scale = 1 })
CS:AddTag(ab, "AlamatPress")
T.icon(ab, "Icon", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), ZIndex = 6, ScaleType = Enum.ScaleType.Crop })
local shade = T.mk("Frame", ab, { Name = "Shade", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = C(8, 4, 16), BackgroundTransparency = 0.35, ZIndex = 7 })
T.corner(shade, 0.14)
T.text(ab, "CdText", "", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.85, 0.45), ZIndex = 8, _max = 28 })

local auto = T.button("TextButton", col, "AutoButton", "Violet", "AUTO", { Size = UDim2.fromScale(1, 0.085), LayoutOrder = 90, ZIndex = 5 })
local pass = T.mk("TextButton", col, { Name = "PassivesButton", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(1, 0.19), LayoutOrder = 100, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 5 })
T.mk("UIGradient", pass, { Name = "Fill", Rotation = 90, Color = T.seq({ C(120, 60, 200), C(40, 16, 80) }) })
T.corner(pass, 0.14)
T.goldStroke(pass, "Gold", 2.2)
T.square(pass)
T.mk("UIScale", pass, { Name = "Press", Scale = 1 })
CS:AddTag(pass, "AlamatPress")
T.icon(pass, "Icon", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.38), Size = UDim2.fromScale(0.55, 0.55), Image = IC.get("Sparkle"), ImageTransparency = 0.35, ZIndex = 6 })
T.text(pass, "Label", "Passives", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.94), Size = UDim2.fromScale(0.92, 0.32), ZIndex = 7, _max = 20 })

-- ===== HOTKEY ROW + UPGRADE BAR =====
local hk = root.HotkeyRow
place(hk, UDim2.fromScale(0, 0.77), UDim2.fromScale(0.62, 0.075), Vector2.new(0, 0))
for _, h in ipairs(hk:GetChildren()) do
	if h:IsA("Frame") then dark(h, 0.15) end
end
local bar = root.UpgradeBar
place(bar, UDim2.fromScale(0, 0.875), UDim2.fromScale(0.75, 0.065), Vector2.new(0, 0))

-- ===== PASSIVES WINDOW =====
local pw = T.mk("Frame", gui, { Name = "PassivesWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.36, 0.52), Visible = false, ZIndex = 30 })
T.strip(pw)
T.panel(pw, "Gold", { Corner = 0.04, Thick = 2.5, Transparency = 0.02 })
T.mk("UIAspectRatioConstraint", pw, { Name = "UIAspectRatioConstraint", AspectRatio = 1.15, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Height })
local head = T.mk("Frame", pw, { Name = "Header", Position = UDim2.fromScale(0.04, 0.03), Size = UDim2.fromScale(0.92, 0.09), BackgroundTransparency = 1, ZIndex = 31 })
T.goldText(T.text(head, "Title", "PASSIVES", { Size = UDim2.fromScale(0.5, 1), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32, _max = 32 }))
local tab = T.button("TextButton", head, "Tab", "Violet", "Unit", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5), Size = UDim2.fromScale(0.3, 0.8), ZIndex = 32 })
local list = T.mk("ScrollingFrame", pw, { Name = "List", Position = UDim2.fromScale(0.04, 0.14), Size = UDim2.fromScale(0.92, 0.82), BackgroundTransparency = 1, ScrollBarThickness = 6, ScrollBarImageColor3 = C(255, 205, 90), AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 31 })
T.mk("UIListLayout", list, { Name = "UIListLayout", SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) })
local pclose = T.button("TextButton", pw, "CloseButton", "Crimson", "X", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.985, 0.015), Size = UDim2.fromScale(0.11, 0.11), ZIndex = 40 })
T.corner(pclose, 1)
T.square(pclose)
local prow = T.mk("Frame", tpl, { Name = "PassiveRowTemplate", Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Visible = false, ZIndex = 32 })
T.mk("UIListLayout", prow, { Name = "UIListLayout", SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), HorizontalAlignment = Enum.HorizontalAlignment.Center })
T.mk("UIPadding", prow, { Name = "UIPadding", PaddingBottom = UDim.new(0, 10) })
local pn = T.text(prow, "Title", "Passive", { Size = UDim2.new(1, 0, 0, 34), TextColor3 = C(120, 220, 255), LayoutOrder = 1, ZIndex = 33, TextWrapped = false, _max = 26 })
local pb = T.text(prow, "Body", "", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextScaled = false, TextSize = 24, FontFace = T.GB, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2, ZIndex = 33 })
local div = T.mk("Frame", prow, { Name = "Divider", Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.2, LayoutOrder = 3, ZIndex = 33 })
T.mk("UIGradient", div, { Name = "Fade", Color = T.seq({ C(160, 80, 255), C(255, 205, 90), C(160, 80, 255) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })

-- ===== STAT BREAKDOWN PANEL =====
local bd = T.mk("Frame", gui, { Name = "BreakdownPanel", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.505, 0.5), Size = UDim2.fromScale(0.42, 0.42), Visible = false, ZIndex = 25 })
T.strip(bd)
T.panel(bd, "Gold", { Corner = 0.05, Thick = 2.2, Transparency = 0.03 })
T.mk("UIAspectRatioConstraint", bd, { Name = "UIAspectRatioConstraint", AspectRatio = 1.85, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width })
local tabs = T.mk("Frame", bd, { Name = "Tabs", Position = UDim2.fromScale(0.02, 0.03), Size = UDim2.fromScale(0.96, 0.11), BackgroundTransparency = 1, ZIndex = 26 })
T.mk("UIListLayout", tabs, { Name = "UIListLayout", FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0.006, 0), VerticalAlignment = Enum.VerticalAlignment.Center })
local tt = T.mk("TextButton", tpl, { Name = "BreakdownTabTemplate", Text = "", AutoButtonColor = false, Size = UDim2.fromScale(0.137, 1), BackgroundColor3 = C(40, 26, 64), BackgroundTransparency = 1, Visible = false, ZIndex = 27 })
T.corner(tt, 0.2)
T.icon(tt, "Icon", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.05, 0.5), Size = UDim2.fromScale(0.22, 0.6), ZIndex = 28 })
T.text(tt, "Label", "Damage", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.3, 0.5), Size = UDim2.fromScale(0.68, 0.55), FontFace = T.GB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28, _max = 15 })
T.mk("Frame", tt, { Name = "Underline", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 1), Size = UDim2.new(0.9, 0, 0, 3), BackgroundColor3 = C(255, 190, 60), Visible = false, ZIndex = 28 })
local function header(n, y, txt)
	local h = T.text(bd, n, txt, { Position = UDim2.fromScale(0.03, y), Size = UDim2.fromScale(0.3, 0.065), FontFace = T.GB, TextColor3 = C(255, 205, 90), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 26, _max = 16 })
	local line = T.mk("Frame", bd, { Name = n .. "Line", Position = UDim2.fromScale(0.2, y + 0.032), Size = UDim2.new(0.77, 0, 0, 2), BackgroundColor3 = C(255, 205, 90), BackgroundTransparency = 0.6, ZIndex = 26 })
	return h, line
end
header("PermHeader", 0.17, "PERMANENT")
local grid = T.mk("ScrollingFrame", bd, { Name = "PermGrid", Position = UDim2.fromScale(0.03, 0.25), Size = UDim2.fromScale(0.94, 0.3), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 26 })
T.mk("UIGridLayout", grid, { Name = "UIGridLayout", CellSize = UDim2.new(0.49, 0, 0, 40), CellPadding = UDim2.new(0.02, 0, 0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
header("TempHeader", 0.57, "TEMPORARY")
local tl = T.mk("ScrollingFrame", bd, { Name = "TempList", Position = UDim2.fromScale(0.03, 0.65), Size = UDim2.fromScale(0.94, 0.12), BackgroundTransparency = 1, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 26 })
T.mk("UIListLayout", tl, { Name = "UIListLayout", SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
local total = T.mk("Frame", bd, { Name = "Total", Position = UDim2.fromScale(0.03, 0.8), Size = UDim2.fromScale(0.94, 0.17), ZIndex = 26 })
T.strip(total)
T.panel(total, "Gold", { Corner = 0.2, Thick = 1.8, Tint = "Crimson", Transparency = 0.05 })
T.text(total, "Label", "TOTAL DAMAGE", { Position = UDim2.fromScale(0.03, 0.1), Size = UDim2.fromScale(0.5, 0.45), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 27, _max = 22 })
T.text(total, "Sub", "", { Position = UDim2.fromScale(0.03, 0.58), Size = UDim2.fromScale(0.5, 0.32), FontFace = T.GB, TextColor3 = C(190, 180, 210), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 27, _max = 14 })
T.text(total, "Value", "", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.45, 0.7), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C(255, 90, 100), ZIndex = 27, _max = 30 })
local bclose = T.button("TextButton", bd, "CloseButton", "Crimson", "X", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.99, 0.02), Size = UDim2.fromScale(0.07, 0.13), ZIndex = 35 })
T.corner(bclose, 1)
T.square(bclose)
local st = T.mk("Frame", tpl, { Name = "SourceTileTemplate", BackgroundColor3 = C(70, 20, 30), Visible = false, ZIndex = 27 })
T.strip(st)
dark(st, 0.05)
T.icon(st, "Icon", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(0.12, 0.75), ZIndex = 28 })
T.text(st, "Title", "Source", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.16, 0.5), Size = UDim2.fromScale(0.42, 0.5), FontFace = T.GB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28, _max = 16 })
T.text(st, "Kind", "trait", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.58, 0.5), Size = UDim2.fromScale(0.14, 0.4), FontFace = T.GB, TextColor3 = C(170, 160, 190), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28, _max = 12 })
T.text(st, "Value", "+0%", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.97, 0.5), Size = UDim2.fromScale(0.26, 0.5), TextColor3 = C(120, 240, 140), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 28, _max = 18 })
local trw = T.mk("Frame", tpl, { Name = "TempRowTemplate", Size = UDim2.new(1, -6, 0, 30), Visible = false, ZIndex = 27 })
dark(trw, 0.1)
T.text(trw, "Title", "Buff", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5), Size = UDim2.fromScale(0.5, 0.6), FontFace = T.GB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 28, _max = 16 })
T.text(trw, "Left", "", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.62, 0.5), Size = UDim2.fromScale(0.2, 0.6), FontFace = T.GB, TextColor3 = C(170, 160, 190), ZIndex = 28, _max = 14 })
T.text(trw, "Value", "+0%", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.98, 0.5), Size = UDim2.fromScale(0.25, 0.6), TextColor3 = C(120, 240, 140), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 28, _max = 16 })

-- ===== ABILITY CARD (inside Root; positioned next to the hovered ability by TowerSelectionUI) =====
local card = T.mk("Frame", root, { Name = "AbilityCard", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.88, 0.2), Size = UDim2.fromScale(0.42, 0.36), Visible = false, ZIndex = 60 })
T.strip(card)
T.panel(card, "Violet", { Corner = 0.06, Thick = 2.2, Transparency = 0.02 })
T.mk("UIAspectRatioConstraint", card, { Name = "UIAspectRatioConstraint", AspectRatio = 1.75, AspectType = Enum.AspectType.ScaleWithParentSize, DominantAxis = Enum.DominantAxis.Width })
T.goldText(T.text(card, "Title", "Ability", { Position = UDim2.fromScale(0.05, 0.04), Size = UDim2.fromScale(0.9, 0.18), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61, _max = 26 }))
T.text(card, "Cooldown", "Cooldown: 0s", { Position = UDim2.fromScale(0.05, 0.23), Size = UDim2.fromScale(0.9, 0.13), TextColor3 = C(110, 210, 255), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 61, _max = 22 })
T.mk("Frame", card, { Name = "Line", Position = UDim2.fromScale(0.05, 0.39), Size = UDim2.new(0.9, 0, 0, 2), BackgroundColor3 = C(255, 205, 90), BackgroundTransparency = 0.5, ZIndex = 61 })
T.text(card, "Body", "", { Position = UDim2.fromScale(0.05, 0.43), Size = UDim2.fromScale(0.9, 0.33), FontFace = T.GB, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 61, _max = 18 })
local foot = T.mk("Frame", card, { Name = "Footer", Position = UDim2.fromScale(0.05, 0.8), Size = UDim2.fromScale(0.9, 0.15), BackgroundColor3 = C(10, 6, 18), BackgroundTransparency = 0.15, ZIndex = 61 })
T.corner(foot, 0.25)
T.mk("UIStroke", foot, { Name = "Edge", Thickness = 1.5, Color = C(200, 200, 220), Transparency = 0.4 })
T.text(foot, "Label", "Local Cooldown", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.75), ZIndex = 62, _max = 18 })

return "unit panel authored"
