-- tools/units_hall_build.luau (B155, v2 = B156) -- run with execute_luau in EACH Place (Edit). Re-runnable, from the
-- pristine screen or from v1. User (B156, with a reference screenshot): "i like the layout of this, apply that for
-- units, fit the buttons, reduce duplicate buttons". THREE COLUMNS + a bottom bar:
--   LEFT   : the roster panel (ribbon "UNITS", search + filters, 4 per row, footer capacity / Unequip All / Sell;
--            in sell mode the sell row takes the whole footer)
--   CENTRE : the unit, big, full body on its tier-tinted stage
--   RIGHT  : the info panel = the hero BG (its TierStroke wears the unit's tier): name, tier, chips, stars + trait,
--            level, stat pills, the open TAB page, and a row of ROUND icon buttons (Feed / View / Favorite / Lock)
--   BOTTOM : nav bar = tabs Stats / Passives / Upgrades / Traits + Teams, and the big EQUIP button (the ref's PLAY)
-- Duplicates removed: the rail's Passives (= the Passives tab), the rail's Sell (= Sell, which now pre-ticks the
-- shown unit), the trait chip's Swap (= the Traits page Swap), the team strip (= equipped checkmarks + Teams).
-- Every node the controllers resolve keeps its NAME and PARENT; Top / Bottom / SelectedUnitFrame / Stats become
-- full-screen transparent frames so every position below is a fraction of the SCREEN.
-- PC / console = Pc*; phone = Mob* (taller rows / bar, 3 per row), picked by UnitsHeroController.Hall.applyLayout.
-- Scale only; rectangle buttons are Alamat Plates; round icon buttons are discs. Backup: _UIBackup_B155 (pristine).
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any
local P = require(SS.DevTools.AlamatPlate:Clone())
local Icons = require(RS.Shared.IconCatalog) :: any
local C = Color3.fromRGB
local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local S, V2 = UDim2.fromScale, Vector2.new

local gui = SG:WaitForChild("UnitsGUI")
local bk = SS:FindFirstChild("_UIBackup_B155") or Instance.new("Folder")
bk.Name = "_UIBackup_B155"
bk.Parent = SS
if not bk:FindFirstChild("UnitsGUI") then gui:Clone().Parent = bk end

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function drop(o: Instance?, name: string) local c = o and o:FindFirstChild(name) if c then c:Destroy() end end
-- place() authors the PC / console layout AND records it (PcPos / PcSize); mob() records the PHONE layout.
local function place(o: Instance?, pos: UDim2, size: UDim2, anchor: Vector2?)
	if not o or not o:IsA("GuiObject") then return end
	o.AnchorPoint = anchor or V2(0, 0)
	o.Position = pos
	o.Size = size
	o:SetAttribute("PcPos", pos)
	o:SetAttribute("PcSize", size)
end
local function mob(o: Instance?, pos: UDim2, size: UDim2)
	if not o then return end
	o:SetAttribute("MobPos", pos)
	o:SetAttribute("MobSize", size)
end
local function corner(o: Instance, r: number?) return new("UICorner", { CornerRadius = UDim.new(r or 0.12, 0) }, o) end
local function goldStroke(o: Instance, t: number?, a: number?)
	local s = new("UIStroke", { Name = "Rim", Color = C(255, 255, 255), Thickness = t or 1.5, Transparency = a or 0.2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
	new("UIGradient", { Name = "Gold", Color = Theme.Gold }, s)
	return s
end
local function img(name: string, image: string, parent: Instance, props: { [string]: any }?): ImageLabel
	local i = new("ImageLabel", { Name = name, Image = image, BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0.5),
		Position = S(0.5, 0.5), Size = S(1, 1) }, parent)
	for k, v in pairs(props or {}) do (i :: any)[k] = v end
	return i
end
local function label(name: string, text: string, parent: Instance, props: { [string]: any }?): TextLabel
	local l = new("TextLabel", { Name = name, Text = text, BackgroundTransparency = 1, TextScaled = true,
		FontFace = Theme.Fonts.Label, TextColor3 = C(255, 240, 206), TextXAlignment = Enum.TextXAlignment.Left }, parent)
	for k, v in pairs(props or {}) do (l :: any)[k] = v end
	return l
end
local function nightPanel(o: GuiObject, alpha: number?)
	o.BackgroundColor3 = C(255, 255, 255)
	o.BackgroundTransparency = alpha or 0.1
	for _, g in ipairs(o:GetChildren()) do if g:IsA("UIGradient") and g.Name == "Night" then g:Destroy() end end
	new("UIGradient", { Name = "Night", Rotation = 90, Color = CS(C(40, 26, 74), C(16, 10, 32)) }, o)
end
local function even(l: TextLabel?)
	if not l then return end
	for _, k in ipairs(l:GetChildren()) do if k:IsA("UITextSizeConstraint") then k:Destroy() end end
	new("UITextSizeConstraint", { Name = "Even", MaxTextSize = 100, MinTextSize = 1 }, l) -- capped to the set's smallest at runtime
end
-- a framed panel: night gradient, gold rim, a thin inner line, four corner sparkles
local function framePanel(name: string, parent: Instance, z: number): Frame
	drop(parent, name)
	local f = new("Frame", { Name = name, ZIndex = z, BorderSizePixel = 0 }, parent)
	nightPanel(f, 0.12)
	corner(f, 0.03)
	goldStroke(f, 2, 0.1)
	local inner = new("Frame", { Name = "Inner", AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.97, 0.975),
		BackgroundTransparency = 1, ZIndex = z }, f)
	corner(inner, 0.03)
	new("UIStroke", { Name = "Line", Color = C(255, 214, 140), Thickness = 1, Transparency = 0.7 }, inner)
	for i, at in ipairs({ V2(0, 0), V2(1, 0), V2(0, 1), V2(1, 1) }) do
		local sp = img("Corner" .. i, Theme.Images.Sparkles[(i - 1) % 3 + 1], f, { Position = S(at.X, at.Y), Size = S(1, 0.05),
			ImageTransparency = 0.15, ZIndex = z + 1 })
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, sp)
		new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, sp)
	end
	return f
end

local main = gui:WaitForChild("Main") :: ImageLabel
local top = main:WaitForChild("Top") :: Frame
local bottom = main:WaitForChild("Bottom") :: Frame
local sel = bottom:WaitForChild("SelectedUnitFrame") :: Frame
local stats = sel:WaitForChild("Stats") :: Frame

-- a re-run starts clean: no layout set from an older build survives
for _, d in ipairs(gui:GetDescendants()) do
	for _, a in ipairs({ "PcPos", "PcSize", "MobPos", "MobSize" }) do
		if d:GetAttribute(a) ~= nil then d:SetAttribute(a, nil) end
	end
end
drop(top, "Crest") -- v1
drop(bottom, "TeamStrip") -- v1: the equipped checkmarks + the Teams screen already say this
drop(sel, "Tabs") -- v1 (the tabs live in the bottom bar now)

-- ===== the hall: full screen =====
local ar = main:FindFirstChildOfClass("UIAspectRatioConstraint")
if ar then ar:Destroy() end
if main.Image ~= "" and main:GetAttribute("HallOldImage") == nil then main:SetAttribute("HallOldImage", main.Image) end
main.ImageTransparency = 1
main.BackgroundTransparency = 1
place(main, S(0.5, 0.5), S(1, 1), V2(0.5, 0.5))
local pad = main:FindFirstChildOfClass("UIPadding")
if pad then pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(), UDim.new(), UDim.new(), UDim.new() end
drop(main, "HallBG")
local bg = new("Frame", { Name = "HallBG", Size = S(1, 1), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 0 }, main)
new("UIGradient", { Name = "Night", Rotation = 90, Color = CS({ CK(0, C(34, 20, 64)), CK(0.55, C(20, 12, 40)), CK(1, C(8, 5, 18)) }) }, bg)
local glow = img("Glow", Theme.Images.GlowRing, bg, { Position = S(0.5, 0.42), Size = S(1.2, 1.15), ImageTransparency = 0.78, ZIndex = 0 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, glow)
new("UIGradient", { Name = "Tint", Color = Theme.tint("Violet") }, glow)
local seal = img("Seal", Theme.Images.MagicCircle, bg, { Position = S(0.5, 0.46), Size = S(1, 0.95), ImageTransparency = 0.93, ZIndex = 0 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, seal)
new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, seal)

-- Top, Bottom, the showcase and Stats span the screen: positions below are fractions of the screen
place(top, S(0, 0), S(1, 1))
place(bottom, S(0, 0), S(1, 1))
place(sel, S(0, 0), S(1, 1))
place(stats, S(0, 0), S(1, 1))
top.BackgroundTransparency, bottom.BackgroundTransparency, sel.BackgroundTransparency, stats.BackgroundTransparency = 1, 1, 1, 1
for _, f in ipairs({ top, bottom, sel }) do
	for _, c in ipairs(f:GetChildren()) do if c:IsA("UIStroke") then c.Enabled = false end end
end
stats.ZIndex = 4
top.ZIndex = 5 -- search / filters / X draw over the panels (both frames span the screen; transparent, so no input is eaten)

-- ===== LEFT: the roster panel =====
local roster = framePanel("RosterPanel", bottom, 1)
place(roster, S(0.012, 0.055), S(0.315, 0.79))
mob(roster, S(0.012, 0.04), S(0.315, 0.8))
local ribbon = new("Frame", { Name = "Ribbon", AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0), Size = S(0.42, 0.055),
	BackgroundColor3 = C(255, 255, 255), ZIndex = 3 }, roster)
corner(ribbon, 0.35)
new("UIGradient", { Name = "Night", Rotation = 90, Color = CS(C(70, 46, 120), C(30, 18, 56)) }, ribbon)
goldStroke(ribbon, 2, 0)
local rt = label("Title", "UNITS", ribbon, { AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.8, 0.72),
	TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C(255, 255, 255), ZIndex = 4 })
new("UIGradient", { Name = "Gold", Rotation = 90, Color = Theme.LabelGold }, rt)
new("UIStroke", { Name = "Outline", Color = C(40, 20, 6), Thickness = 1.5 }, rt)

place(top:FindFirstChild("SearchBar"), S(0.025, 0.088), S(0.19, 0.045))
mob(top:FindFirstChild("SearchBar"), S(0.025, 0.07), S(0.19, 0.07))
place(top:FindFirstChild("FiltersButton"), S(0.22, 0.088), S(0.098, 0.045))
mob(top:FindFirstChild("FiltersButton"), S(0.22, 0.07), S(0.098, 0.07))
for _, d in ipairs((top:FindFirstChild("FiltersButton") :: Instance):GetDescendants()) do
	if d:IsA("TextLabel") then -- a taller phone button wrapped "Filter / s"; the Game copy had a fixed 14 px label
		d.TextWrapped = false
		d.TextScaled = true
	end
end

local grid = bottom:WaitForChild("UnitsContainer") :: ScrollingFrame
place(grid, S(0.022, 0.142), S(0.296, 0.632))
mob(grid, S(0.022, 0.15), S(0.296, 0.585))
grid.BackgroundTransparency = 1
drop(grid, "Rim")
for _, g in ipairs(grid:GetChildren()) do if g:IsA("UIGradient") and g.Name == "Night" then g:Destroy() end end
grid.ZIndex = 2
for _, c in ipairs(grid:GetChildren()) do
	if c:IsA("GuiObject") and c.Name == "UnitIconV2" then c.Size = S(0.26, 0) end
end
grid:SetAttribute("CardWidth", 0.25) -- UnitsController sizes each card's layout slot from this
grid:SetAttribute("PcCardWidth", 0.25) -- 4 per row
grid:SetAttribute("MobCardWidth", 0.333) -- 3 per row on a phone: bigger touch targets

-- footer: capacity / Unequip All / Sell; the sell row takes the whole footer in sell mode
local FOOT_Y, FOOT_H, MFOOT_Y, MFOOT_H = 0.785, 0.05, 0.75, 0.075
place(bottom:FindFirstChild("CapacityBar"), S(0.025, FOOT_Y), S(0.093, FOOT_H))
mob(bottom:FindFirstChild("CapacityBar"), S(0.025, MFOOT_Y), S(0.093, MFOOT_H))
place(bottom:FindFirstChild("UnequipAllButton"), S(0.123, FOOT_Y), S(0.095, FOOT_H))
mob(bottom:FindFirstChild("UnequipAllButton"), S(0.123, MFOOT_Y), S(0.095, MFOOT_H))
local qs = bottom:FindFirstChild("QuickSellButton") :: GuiObject?
place(qs, S(0.223, FOOT_Y), S(0.095, FOOT_H))
mob(qs, S(0.223, MFOOT_Y), S(0.095, MFOOT_H))
if qs then
	qs:SetAttribute("IdleText", "Sell") -- ONE sell button (the rail's "Sell this unit" is gone): it pre-ticks the shown unit
	local t = qs:FindFirstChild("ButtonText") :: TextLabel?
	if t then t.Text = "Sell" end
end
place(bottom:FindFirstChild("SellButtons"), S(0.025, FOOT_Y), S(0.293, FOOT_H))
mob(bottom:FindFirstChild("SellButtons"), S(0.025, MFOOT_Y), S(0.293, MFOOT_H))
local ss = bottom:FindFirstChild("SellStatus") :: GuiObject?
place(ss, S(0.025, 0.73), S(0.293, 0.045))
for _, n in ipairs({ "UnequipAllButton", "QuickSellButton", "TeamsButton" }) do
	local b = bottom:FindFirstChild(n)
	if b then b.ZIndex = 3 end
end
for _, n in ipairs({ "CapacityBar", "SellButtons" }) do
	local b = bottom:FindFirstChild(n)
	if b then b.ZIndex = 3 end
end

-- ===== CENTRE: the unit on its stage =====
drop(sel, "Stage")
local stage = new("Frame", { Name = "Stage", BackgroundTransparency = 1, ZIndex = 2 }, sel)
place(stage, S(0.335, 0.055), S(0.33, 0.79))
mob(stage, S(0.335, 0.04), S(0.33, 0.8))
local function stageImg(name: string, image: string, pos: UDim2, size: UDim2, alpha: number, square: boolean)
	local i = img(name, image, stage, { Position = pos, Size = size, ImageTransparency = alpha, ZIndex = 2 })
	if square then new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, i) end
	new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, i)
	return i
end
stageImg("Rays", Theme.Images.Burst, S(0.5, 0.42), S(1.25, 1.25), 0.55, true)
stageImg("Aura", Theme.Images.GlowRing, S(0.5, 0.44), S(1, 1), 0.35, true)
stageImg("Floor", Theme.Images.MagicCircle, S(0.5, 0.86), S(1, 0.16), 0.2, false)
stageImg("Rune", Theme.Images.RuneRing, S(0.5, 0.86), S(0.72, 0.11), 0.3, false)
stageImg("Glow", Theme.Images.GlowRing, S(0.5, 0.88), S(0.9, 0.07), 0.15, false)
local vf = sel:FindFirstChild("ViewportFrame")
place(vf, S(0.335, 0.075), S(0.33, 0.73))
mob(vf, S(0.335, 0.06), S(0.33, 0.74))
if vf and vf:IsA("GuiObject") then vf.ZIndex = 3 end

-- ===== RIGHT: the info panel (the hero BG; its TierStroke wears the unit's tier) =====
local selBG = sel:FindFirstChild("BG") :: GuiObject?
place(selBG, S(0.673, 0.055), S(0.315, 0.79))
mob(selBG, S(0.673, 0.04), S(0.315, 0.8))
if selBG then
	selBG.ZIndex = 1
	nightPanel(selBG, 0.12)
	local cr = selBG:FindFirstChildOfClass("UICorner") or new("UICorner", {}, selBG)
	cr.CornerRadius = UDim.new(0.03, 0)
end
local function right(n: string, pc: { number }, mb: { number }, center: boolean?)
	local o = stats:FindFirstChild(n)
	place(o, S(pc[1], pc[2]), S(pc[3], pc[4]))
	mob(o, S(mb[1], mb[2]), S(mb[3], mb[4]))
	if center and o and o:IsA("TextLabel") then o.TextXAlignment = Enum.TextXAlignment.Center end
	return o
end
right("UnitName", { 0.685, 0.075, 0.29, 0.05 }, { 0.685, 0.055, 0.29, 0.065 }, true)
right("TierName", { 0.685, 0.124, 0.29, 0.028 }, { 0.685, 0.12, 0.29, 0.035 }, true)
right("ChipsRow", { 0.69, 0.16, 0.28, 0.032 }, { 0.69, 0.16, 0.28, 0.045 })
right("AscRow", { 0.69, 0.2, 0.13, 0.03 }, { 0.69, 0.212, 0.13, 0.04 })
right("TraitRow", { 0.825, 0.198, 0.15, 0.034 }, { 0.825, 0.21, 0.15, 0.045 })
right("LevelBar", { 0.69, 0.24, 0.28, 0.028 }, { 0.69, 0.262, 0.28, 0.04 })
right("BaseStatsFrame", { 0.69, 0.276, 0.28, 0.05 }, { 0.69, 0.308, 0.28, 0.075 })
local chips = stats:FindFirstChild("ChipsRow")
local cl = chips and chips:FindFirstChildOfClass("UIListLayout")
if cl then cl.HorizontalAlignment = Enum.HorizontalAlignment.Center end
local moreBtn = stats:FindFirstChild("MoreStatsButton") :: GuiObject?
if moreBtn then moreBtn.Visible = false end -- the Stats tab IS More Stats
drop(sel, "Divider")
local div = new("Frame", { Name = "Divider", BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 5 }, sel)
place(div, S(0.69, 0.333), S(0.28, 0.002))
mob(div, S(0.69, 0.39), S(0.28, 0.002))
new("UIGradient", { Color = CS(C(255, 222, 140), C(214, 140, 46)), Transparency = NS({ NK(0, 1), NK(0.2, 0.2), NK(0.8, 0.2), NK(1, 1) }) }, div)

-- the open tab's page
local PG, MPG = { 0.685, 0.342, 0.29, 0.4 }, { 0.685, 0.397, 0.29, 0.33 }
local function page(o: Instance?)
	place(o, S(PG[1], PG[2]), S(PG[3], PG[4]))
	mob(o, S(MPG[1], MPG[2]), S(MPG[3], MPG[4]))
end
local more = stats:FindFirstChild("MoreStats") :: ScrollingFrame?
if more then
	page(more)
	more.ZIndex = 6
	nightPanel(more, 0.35)
	local row = more:FindFirstChild("RowTemplate") :: Frame?
	if row then
		row.Size = S(1, 0)
		drop(row, "Shape")
		-- ScaleWithParentSize: a zero-height row in an auto canvas would otherwise fit to 0 x 0
		new("UIAspectRatioConstraint", { Name = "Shape", AspectRatio = 11, DominantAxis = Enum.DominantAxis.Width,
			AspectType = Enum.AspectType.ScaleWithParentSize }, row)
		for _, n in ipairs({ "Key", "Value" }) do -- one text height for every row
			local l = row:FindFirstChild(n) :: GuiObject?
			if l then
				l.Position = S(l.Position.X.Scale, 0.18)
				l.Size = S(l.Size.X.Scale, 0.64)
			end
		end
		drop(row, "Icon")
		local ric = img("Icon", "", row, { AnchorPoint = V2(0, 0.5), Position = S(0.02, 0.5), Size = S(0.1, 0.7),
			ZIndex = row.ZIndex + 1, Visible = false })
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ric)
		local key = row:FindFirstChild("Key") :: GuiObject?
		if key then
			key.Position = S(0.1, key.Position.Y.Scale)
			key.Size = S(0.52, key.Size.Y.Scale)
		end
	end
	local ll = more:FindFirstChildOfClass("UIListLayout")
	if ll then ll.Padding = UDim.new(0.012, 0) end
end
local pp = sel:FindFirstChild("PassivesPanel") :: Frame?
if pp then
	page(pp)
	nightPanel(pp, 0.35)
	local pc = pp:FindFirstChild("CloseButton") :: GuiObject?
	if pc then pc.Visible = false end -- a TAB page; the hall's X is the one close button
	pp.AnchorPoint = V2(0, 0)
	local t = pp:FindFirstChild("Title") :: GuiObject?
	if t then t.Position, t.Size = S(0.05, 0.02), S(0.9, 0.07) end
	local l = pp:FindFirstChild("List") :: GuiObject?
	if l then l.Position, l.Size = S(0.03, 0.11), S(0.94, 0.87) end
end
local path = sel:FindFirstChild("UpgradePath") :: GuiObject?
place(path, S(0.685, 0.342), S(0.29, 0.04))
mob(path, S(0.685, 0.397), S(0.29, 0.05))
if path then path.ZIndex = 6 path.Visible = false end

drop(sel, "UpgradesPage")
local up = new("Frame", { Name = "UpgradesPage", Visible = false, ZIndex = 6 }, sel)
place(up, S(0.685, 0.388), S(0.29, 0.354))
mob(up, S(0.685, 0.452), S(0.29, 0.275))
nightPanel(up, 0.35)
corner(up, 0.04)
local list = new("ScrollingFrame", { Name = "TierList", Position = S(0.03, 0.02), Size = S(0.94, 0.96), BackgroundTransparency = 1,
	CanvasSize = S(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 7,
	ScrollBarImageColor3 = C(255, 214, 120), BorderSizePixel = 0 }, up)
new("UIListLayout", { Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local tr = new("TextButton", { Name = "TierRowTemplate", Size = S(0.97, 0), Text = "", AutoButtonColor = false, Visible = false,
	BackgroundColor3 = C(30, 20, 56), ZIndex = 7 }, list)
new("UIAspectRatioConstraint", { AspectRatio = 4.6, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize }, tr)
corner(tr, 0.14)
new("UIStroke", { Name = "SelStroke", Color = C(255, 214, 120), Thickness = 2, Enabled = false }, tr)
local badge = new("Frame", { Name = "Badge", Position = S(0.025, 0.14), Size = S(0.13, 0.72), BackgroundColor3 = C(70, 175, 60), ZIndex = 8 }, tr)
corner(badge, 0.25)
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, badge)
label("Num", "1", badge, { AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.7, 0.7), ZIndex = 9,
	TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C(255, 255, 255) })
label("Title", "Upgrade 1", tr, { Position = S(0.19, 0.08), Size = S(0.5, 0.3), ZIndex = 8 })
label("Cost", "", tr, { Position = S(0.62, 0.08), Size = S(0.35, 0.3), ZIndex = 8, TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = C(255, 214, 120) })
label("Stats", "", tr, { Position = S(0.19, 0.4), Size = S(0.78, 0.26), ZIndex = 8, RichText = true,
	FontFace = Theme.Fonts.Body or Theme.Fonts.Label, TextColor3 = C(226, 218, 245) })
label("Attack", "", tr, { Position = S(0.19, 0.68), Size = S(0.78, 0.24), ZIndex = 8, RichText = true,
	FontFace = Theme.Fonts.Body or Theme.Fonts.Label, TextColor3 = C(255, 186, 120) })

drop(sel, "TraitPage")
local tp = new("Frame", { Name = "TraitPage", BackgroundTransparency = 1, Visible = false, ZIndex = 6 }, sel)
page(tp)
local function card(name: string, pos: UDim2, size: UDim2): Frame
	local f = new("Frame", { Name = name, Position = pos, Size = size, ZIndex = 6 }, tp)
	nightPanel(f, 0.35)
	corner(f, 0.06)
	goldStroke(f, 1.2)
	return f
end
local tc = card("TraitCard", S(0, 0), S(1, 0.5))
label("Header", "TRAIT", tc, { Position = S(0.05, 0.04), Size = S(0.5, 0.1), ZIndex = 7, TextColor3 = C(196, 170, 255) })
local tIcon = img("Icon", "", tc, { AnchorPoint = V2(0, 0), Position = S(0.05, 0.17), Size = S(0.3, 0.3), ZIndex = 7 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, tIcon)
label("TraitName", "No Trait", tc, { Position = S(0.26, 0.17), Size = S(0.7, 0.14), ZIndex = 7, TextColor3 = C(255, 255, 255) })
label("Rarity", "", tc, { Position = S(0.26, 0.31), Size = S(0.7, 0.09), ZIndex = 7, TextColor3 = C(255, 214, 120) })
label("Desc", "", tc, { Position = S(0.05, 0.5), Size = S(0.9, 0.24), ZIndex = 7, RichText = true, TextYAlignment = Enum.TextYAlignment.Top,
	FontFace = Theme.Fonts.Body or Theme.Fonts.Label, TextColor3 = C(226, 218, 245) })
label("Stored", "", tc, { Position = S(0.05, 0.76), Size = S(0.5, 0.09), ZIndex = 7, TextColor3 = C(170, 160, 200) })
local swap = new("TextButton", { Name = "SwapButton", AnchorPoint = V2(1, 1), Position = S(0.95, 0.94), Size = S(0.38, 0.16),
	Text = "", ZIndex = 7, BackgroundColor3 = Theme.plateColor("Violet") }, tc)
label("ButtonText", "Swap Slots", swap, { AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.86, 0.6), ZIndex = 8,
	TextXAlignment = Enum.TextXAlignment.Center })
P.convert(swap, "Violet")
swap:SetAttribute("Tooltip", "Swap the active and stored trait")
local ac = card("AscCard", S(0, 0.53), S(1, 0.47))
label("Header", "ASCENSION", ac, { Position = S(0.05, 0.05), Size = S(0.5, 0.11), ZIndex = 7, TextColor3 = C(196, 170, 255) })
label("Stars", "", ac, { Position = S(0.05, 0.19), Size = S(0.9, 0.16), ZIndex = 7, RichText = true, TextColor3 = C(255, 214, 64) })
label("Desc", "", ac, { Position = S(0.05, 0.38), Size = S(0.9, 0.34), ZIndex = 7, RichText = true, TextYAlignment = Enum.TextYAlignment.Top,
	FontFace = Theme.Fonts.Body or Theme.Fonts.Label, TextColor3 = C(226, 218, 245) })
label("Next", "", ac, { Position = S(0.05, 0.76), Size = S(0.9, 0.16), ZIndex = 7, RichText = true, TextColor3 = C(255, 214, 120) })

-- round icon buttons at the foot of the info panel (the ref's three discs): Feed / View / Favorite / Lock
local rail = bottom:WaitForChild("ActionRail") :: Frame
place(rail, S(0.685, 0.752), S(0.29, 0.085))
mob(rail, S(0.685, 0.735), S(0.29, 0.1))
rail.BackgroundTransparency = 1
rail.ZIndex = 4
local rl = rail:FindFirstChildOfClass("UIListLayout")
if rl then
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.Padding = UDim.new(0.04, 0)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rl.VerticalAlignment = Enum.VerticalAlignment.Center
end
local PLATE_LAYERS = { "Inner", "Gloss", "Lip", "ShineClip", "Flash", "Burst", "Sparkles", "Disc" }
local DISCS = { UpgradeUnitButton = { "Feed", 1 }, ViewUnitButton = { "View", 2 }, FavoriteButton = { "Favorite", 3 }, LockUnitButon = { "Lock", 4 } }
for _, b in ipairs(rail:GetChildren()) do
	if b:IsA("GuiButton") then
		local spec = DISCS[b.Name]
		if not spec then
			b.Visible = false -- ViewPassivesButton (= the Passives tab) and SellUnitButton (= Sell) are duplicates now
		else
			-- un-plate: a transparent hit area holding a gold-rimmed night disc, the icon, a caption under it
			for _, n in ipairs(PLATE_LAYERS) do drop(b, n) end
			for _, c in ipairs(b:GetChildren()) do
				if c:IsA("UIGradient") or c:IsA("UIStroke") or c:IsA("UICorner") or (c:IsA("UIScale") and c.Name == "Pop") then c:Destroy() end
			end
			CollectionService:RemoveTag(b, "AlamatButton")
			for _, a in ipairs({ "Variant", "Theme", "PlateRim", "NoFX", "PlateOldImage", "PlateMirror" }) do b:SetAttribute(a, nil) end
			b.BackgroundTransparency = 1
			b.AutoButtonColor = false
			b.LayoutOrder = spec[2]
			b.Size = S(0.2, 1)
			b.ZIndex = 4
			local disc = new("Frame", { Name = "Disc", AnchorPoint = V2(0.5, 0), Position = S(0.5, 0), Size = S(1, 0.68),
				BackgroundColor3 = C(255, 255, 255), ZIndex = 4 }, b)
			new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, disc)
			corner(disc, 1)
			new("UIGradient", { Name = "Night", Rotation = 90, Color = CS(C(70, 46, 120), C(22, 14, 42)) }, disc)
			goldStroke(disc, 2, 0)
			local ic = b:FindFirstChild("Icon") :: GuiObject?
			if ic then
				ic.AnchorPoint = V2(0.5, 0.5)
				ic.Position = S(0.5, 0.34)
				ic.Size = S(1, 0.42)
				ic.ZIndex = 5
				drop(ic, "Square")
				new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
			end
			local t = b:FindFirstChild("ButtonText") :: TextLabel?
			if not t then t = label("ButtonText", spec[1], b, {}) end
			local tl = t :: TextLabel
			tl.Text = spec[1]
			tl.Visible = true
			tl.TextScaled = true
			tl.FontFace = Theme.Fonts.Label
			tl.TextColor3 = C(255, 240, 206)
			tl.TextXAlignment = Enum.TextXAlignment.Center
			tl.AnchorPoint = V2(0.5, 0)
			tl.Position = S(0.5, 0.72)
			tl.Size = S(1.4, 0.28)
			tl.ZIndex = 5
			for _, k in ipairs(tl:GetChildren()) do if k:IsA("UIPadding") then k:Destroy() end end -- the old rail padding
			even(tl)
		end
	end
end

-- ===== BOTTOM: the nav bar (tabs + Teams) and the big Equip =====
local nav = framePanel("NavBar", bottom, 1)
place(nav, S(0.012, 0.858), S(0.976, 0.124))
mob(nav, S(0.012, 0.85), S(0.976, 0.14))
drop(bottom, "Tabs")
local tabs = new("Frame", { Name = "Tabs", BackgroundTransparency = 1, ZIndex = 3 }, bottom)
place(tabs, S(0.02, 0.87), S(0.555, 0.1))
mob(tabs, S(0.02, 0.862), S(0.555, 0.116))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.018, 0),
	VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
local bsf = stats:FindFirstChild("BaseStatsFrame")
local dmgIcon = bsf and bsf:FindFirstChild("DMG") and bsf.DMG:FindFirstChild("ImageIcon") :: ImageLabel?
local TABS = {
	{ "Stats", "Stats", if dmgIcon then dmgIcon.Image else Icons.get("Info") },
	{ "Passives", "Passives", Icons.get("Passives") },
	{ "Upgrades", "Upgrades", Icons.get("Arrow") },
	{ "Trait", "Traits", Icons.get("Sparkle") },
}
local ON, OFF = Theme.plateColor("Gold"), Theme.plateColor("Night")
local function navLabels(b: GuiObject, icon: string)
	drop(b, "Icon")
	local ic = img("Icon", icon, b, { AnchorPoint = V2(0, 0.5), Position = S(0.08, 0.5), Size = S(0.3, 0.56), ZIndex = b.ZIndex + 5 })
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
	local t = b:FindFirstChild("Label") or b:FindFirstChild("ButtonText")
	local tl = (t or label("Label", "", b, {})) :: TextLabel
	tl.AnchorPoint = V2(0, 0)
	tl.Position, tl.Size = S(0.3, 0.22), S(0.64, 0.56)
	tl.TextXAlignment = Enum.TextXAlignment.Center
	tl.TextScaled = true
	even(tl)
end
for i, t in ipairs(TABS) do
	local b = new("TextButton", { Name = "Tab" .. t[1], LayoutOrder = i, Size = S(0.235, 0.9), Text = "", ZIndex = 3,
		BackgroundColor3 = if i == 1 then ON else OFF }, tabs)
	label("Label", t[2], b, { ZIndex = 8 })
	navLabels(b, t[3])
	P.convert(b, nil)
	b:SetAttribute("OnColor", ON)
	b:SetAttribute("OffColor", OFF)
	b:SetAttribute("Tooltip", if t[1] == "Trait" then "Trait & Ascension" else t[2])
end
local teams = bottom:FindFirstChild("TeamsButton") :: GuiObject?
place(teams, S(0.585, 0.875), S(0.125, 0.09))
mob(teams, S(0.585, 0.866), S(0.125, 0.108))
if teams then
	teams.BackgroundColor3 = OFF -- the nav bar's colour
	teams:SetAttribute("Theme", "Night")
	navLabels(teams, Icons.get("Players"))
	local t = teams:FindFirstChild("ButtonText") :: TextLabel?
	if t then t.Text = "Teams" end
end
local equip = bottom:FindFirstChild("UN/EquipButton") :: GuiObject?
place(equip, S(0.735, 0.87), S(0.245, 0.1))
mob(equip, S(0.735, 0.862), S(0.245, 0.116))
if equip then equip.ZIndex = 3 end

-- the close X sits on the info panel's top-right corner
local close = top:FindFirstChild("CloseButton") :: GuiObject?
if close then
	place(close, S(0.985, 0.052), S(0.06, 0.075), V2(0.5, 0.5))
	mob(close, S(0.982, 0.04), S(0.08, 0.1))
	close.ZIndex = 8
	drop(close, "Square")
	new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, close)
end

return "Hero Hall v2 built in " .. gui:GetFullName()
