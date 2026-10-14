-- tools/units_hall_build.luau (B155) -- run with execute_luau in EACH Place (Edit). Re-runnable.
-- User pick "Hero Hall, full screen": the Units screen becomes a full-screen hall --
--   LEFT  : the roster grid (6 per row), a tools row (capacity / Unequip All / Teams / Quick Sell) and the TEAM
--           STRIP (the equipped loadout, 6 slots, locked ones show their level)
--   RIGHT : the SHOWCASE -- name / tier / chips, the unit on a tier-tinted STAGE (rays, aura, magic-circle floor),
--           stars / trait / level / stat pills under it, and four TABS: Stats (More Stats list), Passives,
--           Upgrades (the path bar + one row per tier) and Traits (trait + swap, ascension)
--           with the action PLATES (Feed / Passives / View / Favorite / Lock / Sell) and Equip under it.
-- Every node the controllers already resolve keeps its NAME and PARENT (UnitsController / UnitsHeroController
-- WaitForChild them), so this only re-places them and adds new authored nodes the B155 controller code drives:
--   Main.HallBG, Main.Top.Crest, Bottom.TeamStrip{Label, Slots.Slot1..6}, sel.Stage{Rays, Aura, Floor, Rune, Glow},
--   sel.Tabs{TabStats, TabPassives, TabUpgrades, TabTrait}, sel.UpgradesPage.TierList{TierRowTemplate},
--   sel.TraitPage{TraitCard, AscCard}. Tab plates carry OnColor / OffColor attributes.
-- Scale only, every rectangle action button an Alamat Plate. Backup: ServerStorage._UIBackup_B155.UnitsGUI.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
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
local function drop(o: Instance, name: string) local c = o:FindFirstChild(name) if c then c:Destroy() end end
-- place() authors the PC / console layout AND records it (PcPos / PcSize); mob() records the PHONE layout
-- (MobPos / MobSize). UnitsHeroController picks the set at runtime (touch-only or a short screen = phone).
local function place(o: GuiObject?, pos: UDim2, size: UDim2, anchor: Vector2?)
	if not o then return end
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
local function goldStroke(o: Instance, t: number?)
	local s = new("UIStroke", { Name = "Rim", Color = C(255, 255, 255), Thickness = t or 1.5, Transparency = 0.25,
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

local main = gui:WaitForChild("Main") :: ImageLabel
local top = main:WaitForChild("Top") :: Frame
local bottom = main:WaitForChild("Bottom") :: Frame
local sel = bottom:WaitForChild("SelectedUnitFrame") :: Frame
local stats = sel:WaitForChild("Stats") :: Frame

-- ===== the hall: full screen =====
local ar = main:FindFirstChildOfClass("UIAspectRatioConstraint")
if ar then ar:Destroy() end -- 16:9 lock; the hall fills any screen (the backup keeps it)
if main.Image ~= "" and main:GetAttribute("HallOldImage") == nil then main:SetAttribute("HallOldImage", main.Image) end
main.ImageTransparency = 1
main.BackgroundTransparency = 1
place(main, S(0.5, 0.5), S(1, 1), V2(0.5, 0.5))
local pad = main:FindFirstChildOfClass("UIPadding")
if pad then
	pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(), UDim.new(), UDim.new(), UDim.new()
end
drop(main, "HallBG")
local bg = new("Frame", { Name = "HallBG", Size = S(1, 1), BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 0 }, main)
new("UIGradient", { Name = "Night", Rotation = 90, Color = CS({ CK(0, C(34, 20, 64)), CK(0.55, C(20, 12, 40)), CK(1, C(8, 5, 18)) }) }, bg)
local glow = img("Glow", Theme.Images.GlowRing, bg, { Position = S(0.79, 0.45), Size = S(1.2, 1.2), ImageTransparency = 0.82, ZIndex = 0 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, glow)
new("UIGradient", { Name = "Tint", Color = Theme.tint("Violet") }, glow)
local seal = img("Seal", Theme.Images.MagicCircle, bg, { Position = S(0.29, 0.5), Size = S(1, 1.1), ImageTransparency = 0.95, ZIndex = 0 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, seal)
new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, seal)
for i, y in ipairs({ 0.097, 0.993 }) do
	local rule = new("Frame", { Name = "Rule" .. i, AnchorPoint = V2(0.5, 0.5), Position = S(0.5, y), Size = S(0.96, 0.003),
		BackgroundColor3 = C(255, 255, 255), BorderSizePixel = 0, ZIndex = 0 }, bg)
	new("UIGradient", { Color = CS(C(255, 222, 140), C(214, 140, 46)),
		Transparency = NS({ NK(0, 1), NK(0.15, 0.2), NK(0.85, 0.2), NK(1, 1) }) }, rule)
end

-- ===== header =====
place(top, S(0.02, 0.018), S(0.96, 0.07))
mob(top, S(0.02, 0.012), S(0.96, 0.085))
top.BackgroundTransparency = 1
drop(top, "Crest")
local crest = new("Frame", { Name = "Crest", Position = S(0, 0), Size = S(0.2, 1), BackgroundTransparency = 1 }, top)
local cIcon = img("Icon", Theme.Images.MagicCircle, crest, { AnchorPoint = V2(0, 0.5), Position = S(0, 0.5), Size = S(1, 1.15), ZIndex = 2 })
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, cIcon)
new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, cIcon)
label("Kicker", "HERO HALL", crest, { Position = S(0.2, 0.02), Size = S(0.8, 0.32), TextColor3 = C(196, 170, 255), ZIndex = 2 })
local title = label("Title", "UNITS", crest, { Position = S(0.2, 0.32), Size = S(0.8, 0.68), TextColor3 = C(255, 255, 255), ZIndex = 2 })
new("UIGradient", { Name = "Gold", Rotation = 90, Color = Theme.LabelGold }, title)
new("UIStroke", { Name = "Outline", Color = C(40, 20, 6), Thickness = 1.5 }, title)
place(top:FindFirstChild("SearchBar") :: GuiObject, S(0.215, 0.5), S(0.235, 0.8), V2(0, 0.5))
place(top:FindFirstChild("FiltersButton") :: GuiObject, S(0.46, 0.5), S(0.105, 0.8), V2(0, 0.5))
local close = top:FindFirstChild("CloseButton") :: GuiObject?
if close then
	place(close, S(1, 0.5), S(0.06, 0.95), V2(1, 0.5))
	drop(close, "Square")
	new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, close)
end

-- ===== the body =====
place(bottom, S(0.02, 0.105), S(0.96, 0.88))
mob(bottom, S(0.02, 0.11), S(0.96, 0.88))
bottom.BackgroundTransparency = 1
for _, c in ipairs(bottom:GetChildren()) do if c:IsA("UIStroke") then c.Enabled = false end end

-- roster grid: 6 per row (UIListLayout wraps; padding is -0.015 of the width)
local grid = bottom:WaitForChild("UnitsContainer") :: ScrollingFrame
place(grid, S(0, 0), S(0.565, 0.835))
mob(grid, S(0, 0), S(0.5, 0.78))
nightPanel(grid, 0.25)
drop(grid, "Rim")
goldStroke(grid, 1.5)
for _, c in ipairs(grid:GetChildren()) do
	if c:IsA("GuiObject") and c.Name == "UnitIconV2" then c.Size = S(0.1783, 0) end
end
grid:SetAttribute("CardWidth", 0.1667) -- UnitsController sizes each card's layout slot from this (6 per row)
grid:SetAttribute("PcCardWidth", 0.1667)
grid:SetAttribute("MobCardWidth", 0.25) -- 4 per row on a phone: bigger touch targets

-- tools row
place(bottom:FindFirstChild("CapacityBar") :: GuiObject, S(0, 0.85), S(0.125, 0.065))
place(bottom:FindFirstChild("UnequipAllButton") :: GuiObject, S(0.135, 0.85), S(0.135, 0.065))
place(bottom:FindFirstChild("TeamsButton") :: GuiObject, S(0.28, 0.85), S(0.135, 0.065))
place(bottom:FindFirstChild("QuickSellButton") :: GuiObject, S(0.425, 0.85), S(0.14, 0.065))
place(bottom:FindFirstChild("SellButtons") :: GuiObject, S(0.135, 0.85), S(0.43, 0.065))
mob(bottom:FindFirstChild("CapacityBar"), S(0, 0.795), S(0.11, 0.095))
mob(bottom:FindFirstChild("UnequipAllButton"), S(0.12, 0.795), S(0.12, 0.095))
mob(bottom:FindFirstChild("TeamsButton"), S(0.25, 0.795), S(0.12, 0.095))
mob(bottom:FindFirstChild("QuickSellButton"), S(0.38, 0.795), S(0.12, 0.095))
mob(bottom:FindFirstChild("SellButtons"), S(0.12, 0.795), S(0.38, 0.095))
local sellStatus = bottom:FindFirstChild("SellStatus") :: TextLabel?
if sellStatus then
	place(sellStatus, S(0, 0.785), S(0.565, 0.05))
	mob(sellStatus, S(0, 0.72), S(0.5, 0.06))
	sellStatus.ZIndex = 8
end

-- team strip (the equipped loadout)
drop(bottom, "TeamStrip")
local strip = new("Frame", { Name = "TeamStrip", ZIndex = 3 }, bottom)
place(strip, S(0, 0.925), S(0.565, 0.075))
mob(strip, S(0, 0.9), S(0.5, 0.1))
nightPanel(strip, 0.15)
corner(strip, 0.25)
goldStroke(strip, 1.2)
local stripLbl = label("Label", "TEAM", strip, { Position = S(0.015, 0.15), Size = S(0.08, 0.7), ZIndex = 4,
	TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C(255, 255, 255) })
new("UIGradient", { Name = "Gold", Rotation = 90, Color = Theme.LabelGold }, stripLbl)
local slots = new("Frame", { Name = "Slots", Position = S(0.105, 0.08), Size = S(0.885, 0.84), BackgroundTransparency = 1, ZIndex = 4 }, strip)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.012, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder }, slots)
for i = 1, 6 do
	local s = new("TextButton", { Name = "Slot" .. i, LayoutOrder = i, Size = S(0.155, 1), Text = "", AutoButtonColor = false,
		BackgroundColor3 = C(24, 15, 44), BackgroundTransparency = 0.1, ZIndex = 5, Selectable = true }, slots)
	corner(s, 0.2)
	local st = new("UIStroke", { Name = "Rim", Color = C(255, 255, 255), Thickness = 1, Transparency = 0.5 }, s)
	new("UIGradient", { Name = "Gold", Color = Theme.Gold }, st)
	label("Empty", "EMPTY", s, { AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.8, 0.4), ZIndex = 6,
		TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = C(150, 136, 186) })
	local lk = img("Lock", Icons.get("Lock"), s, { Position = S(0.5, 0.36), Size = S(0.5, 0.42), ZIndex = 6, Visible = false,
		ImageColor3 = C(255, 214, 120) })
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, lk)
end

-- ===== the showcase =====
place(sel, S(0.58, 0), S(0.42, 0.835))
mob(sel, S(0.51, 0), S(0.49, 0.78))
local selBG = sel:FindFirstChild("BG") :: GuiObject?
place(selBG, S(0, 0), S(1, 1))
if selBG then selBG.ZIndex = 1 end
place(stats, S(0, 0), S(1, 1))
stats.ZIndex = 4

-- the stage behind the unit (white art, tinted by the controller in the tier's colours)
drop(sel, "Stage")
local stage = new("Frame", { Name = "Stage", BackgroundTransparency = 1, ZIndex = 2 }, sel)
place(stage, S(0.02, 0.235), S(0.47, 0.51))
mob(stage, S(0.02, 0.29), S(0.47, 0.43))
local function stageImg(name: string, image: string, pos: UDim2, size: UDim2, alpha: number, square: boolean)
	local i = img(name, image, stage, { Position = pos, Size = size, ImageTransparency = alpha, ZIndex = 2 })
	if square then new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Width }, i) end
	new("UIGradient", { Name = "Tint", Color = Theme.tint("Gold") }, i)
	return i
end
stageImg("Rays", Theme.Images.Burst, S(0.5, 0.44), S(1.15, 1.15), 0.55, true)
stageImg("Aura", Theme.Images.GlowRing, S(0.5, 0.46), S(0.95, 0.95), 0.35, true)
stageImg("Floor", Theme.Images.MagicCircle, S(0.5, 0.88), S(0.95, 0.2), 0.25, false)
stageImg("Rune", Theme.Images.RuneRing, S(0.5, 0.88), S(0.66, 0.13), 0.35, false)
stageImg("Glow", Theme.Images.GlowRing, S(0.5, 0.9), S(0.85, 0.09), 0.2, false)
local vf = sel:FindFirstChild("ViewportFrame") :: GuiObject?
place(vf, S(0.02, 0.235), S(0.47, 0.51))
mob(vf, S(0.02, 0.29), S(0.47, 0.43))
if vf then vf.ZIndex = 3 end

-- glance column (left, under / over the unit)
place(stats:FindFirstChild("TierName") :: GuiObject, S(0.04, 0.1), S(0.45, 0.035))
place(stats:FindFirstChild("UnitName") :: GuiObject, S(0.04, 0.132), S(0.47, 0.06)) -- the controller tweens it home from here
place(stats:FindFirstChild("ChipsRow") :: GuiObject, S(0.04, 0.198), S(0.46, 0.038))
place(stats:FindFirstChild("AscRow") :: GuiObject, S(0.04, 0.748), S(0.3, 0.038))
place(stats:FindFirstChild("TraitRow") :: GuiObject, S(0.04, 0.792), S(0.46, 0.044))
place(stats:FindFirstChild("LevelBar") :: GuiObject, S(0.04, 0.846), S(0.45, 0.038))
place(stats:FindFirstChild("BaseStatsFrame") :: GuiObject, S(0.04, 0.898), S(0.45, 0.075))
mob(stats:FindFirstChild("TierName"), S(0.04, 0.115), S(0.45, 0.045))
mob(stats:FindFirstChild("UnitName"), S(0.04, 0.155), S(0.47, 0.07))
mob(stats:FindFirstChild("ChipsRow"), S(0.04, 0.23), S(0.46, 0.05))
mob(stats:FindFirstChild("AscRow"), S(0.04, 0.725), S(0.3, 0.045))
mob(stats:FindFirstChild("TraitRow"), S(0.04, 0.775), S(0.46, 0.05))
mob(stats:FindFirstChild("LevelBar"), S(0.04, 0.835), S(0.45, 0.05))
mob(stats:FindFirstChild("BaseStatsFrame"), S(0.04, 0.892), S(0.45, 0.09))
local moreBtn = stats:FindFirstChild("MoreStatsButton") :: GuiObject?
if moreBtn then moreBtn.Visible = false end -- the Stats tab IS More Stats in the hall

-- tabs (right)
drop(sel, "Tabs")
local tabs = new("Frame", { Name = "Tabs", BackgroundTransparency = 1, ZIndex = 6 }, sel)
place(tabs, S(0.02, 0.018), S(0.96, 0.065))
mob(tabs, S(0.02, 0.012), S(0.96, 0.09))
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.016, 0),
	HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, tabs)
local bsf = stats:FindFirstChild("BaseStatsFrame")
local dmgIcon = bsf and bsf:FindFirstChild("DMG") and bsf.DMG:FindFirstChild("ImageIcon") :: ImageLabel?
local TABS = {
	{ "Stats", "Stats", if dmgIcon then dmgIcon.Image else Icons.get("Info") },
	{ "Passives", "Passives", Icons.get("Passives") },
	{ "Upgrades", "Upgrades", Icons.get("Arrow") },
	{ "Trait", "Traits", Icons.get("Sparkle") },
}
local ON, OFF = Theme.plateColor("Gold"), Theme.plateColor("Night")
for i, t in ipairs(TABS) do
	local b = new("TextButton", { Name = "Tab" .. t[1], LayoutOrder = i, Size = S(0.235, 1), Text = "", ZIndex = 6,
		BackgroundColor3 = if i == 1 then ON else OFF }, tabs)
	local ic = img("Icon", t[3], b, { AnchorPoint = V2(0, 0.5), Position = S(0.07, 0.5), Size = S(0.3, 0.62), ZIndex = 7 })
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
	local tl = label("Label", t[2], b, { Position = S(0.3, 0.2), Size = S(0.64, 0.6), ZIndex = 7, TextXAlignment = Enum.TextXAlignment.Center })
	new("UITextSizeConstraint", { Name = "Even", MaxTextSize = 100, MinTextSize = 1 }, tl) -- capped to the set's smallest at runtime
	P.convert(b, nil)
	b:SetAttribute("OnColor", ON)
	b:SetAttribute("OffColor", OFF)
	b:SetAttribute("Tooltip", if t[1] == "Trait" then "Trait & Ascension" else t[2])
end

-- pages (right): Stats = More Stats, Passives = the passives panel, Upgrades = path + tier rows, Traits
local PAGE_POS, PAGE_SIZE = S(0.52, 0.1), S(0.46, 0.875)
local MOB_POS, MOB_SIZE = S(0.52, 0.115), S(0.46, 0.865)
local more = stats:FindFirstChild("MoreStats") :: ScrollingFrame?
if more then
	place(more, PAGE_POS, PAGE_SIZE)
	mob(more, MOB_POS, MOB_SIZE)
	more.ZIndex = 6
	nightPanel(more, 0.08)
	local row = more:FindFirstChild("RowTemplate") :: Frame?
	if row then
		row.Size = S(1, 0)
		drop(row, "Shape")
		-- ScaleWithParentSize: a zero-height row in an auto canvas would otherwise fit to 0 x 0
		new("UIAspectRatioConstraint", { Name = "Shape", AspectRatio = 9, DominantAxis = Enum.DominantAxis.Width,
			AspectType = Enum.AspectType.ScaleWithParentSize }, row)
		-- the row's icon (filled by renderMore when the catalog has one); the key label moves right of it
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
	place(pp, PAGE_POS, PAGE_SIZE)
	mob(pp, MOB_POS, MOB_SIZE)
	nightPanel(pp, 0.08)
	local pc = pp:FindFirstChild("CloseButton") :: GuiObject?
	if pc then pc.Visible = false end -- a TAB page; the hall's X is the one close button
	place(pp:FindFirstChild("Title") :: GuiObject, S(0.05, 0.02), S(0.9, 0.06))
	place(pp:FindFirstChild("List") :: GuiObject, S(0.04, 0.1), S(0.92, 0.88))
end
local path = sel:FindFirstChild("UpgradePath") :: GuiObject?
place(path, S(0.52, 0.1), S(0.46, 0.055))
mob(path, S(0.52, 0.115), S(0.46, 0.07))
if path then path.ZIndex = 6 path.Visible = false end

drop(sel, "UpgradesPage")
local up = new("Frame", { Name = "UpgradesPage", Visible = false, ZIndex = 6 }, sel)
place(up, S(0.52, 0.165), S(0.46, 0.81))
mob(up, S(0.52, 0.195), S(0.46, 0.785))
nightPanel(up, 0.08)
corner(up, 0.04)
goldStroke(up, 1.2)
local list = new("ScrollingFrame", { Name = "TierList", Position = S(0.03, 0.02), Size = S(0.94, 0.96), BackgroundTransparency = 1,
	CanvasSize = S(0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ZIndex = 7,
	ScrollBarImageColor3 = C(255, 214, 120), BorderSizePixel = 0 }, up)
new("UIListLayout", { Padding = UDim.new(0.012, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local tr = new("TextButton", { Name = "TierRowTemplate", Size = S(0.97, 0), Text = "", AutoButtonColor = false, Visible = false,
	BackgroundColor3 = C(30, 20, 56), ZIndex = 7 }, list)
new("UIAspectRatioConstraint", { AspectRatio = 4.6, DominantAxis = Enum.DominantAxis.Width, AspectType = Enum.AspectType.ScaleWithParentSize }, tr)
corner(tr, 0.14)
local trs = new("UIStroke", { Name = "SelStroke", Color = C(255, 214, 120), Thickness = 2, Enabled = false }, tr)
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
place(tp, PAGE_POS, PAGE_SIZE)
mob(tp, MOB_POS, MOB_SIZE)
local function card(name: string, pos: UDim2, size: UDim2): Frame
	local f = new("Frame", { Name = name, Position = pos, Size = size, ZIndex = 6 }, tp)
	nightPanel(f, 0.08)
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

-- ===== actions under the showcase =====
local rail = bottom:WaitForChild("ActionRail") :: Frame
place(rail, S(0.58, 0.85), S(0.42, 0.065))
mob(rail, S(0.51, 0.795), S(0.49, 0.095))
rail.BackgroundTransparency = 1
local rl = rail:FindFirstChildOfClass("UIListLayout")
if rl then
	rl.FillDirection = Enum.FillDirection.Horizontal
	rl.Padding = UDim.new(0.012, 0)
	rl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rl.VerticalAlignment = Enum.VerticalAlignment.Center
end
local RAIL = {
	UpgradeUnitButton = { "Feed", "Jade" }, ViewPassivesButton = { "Passives", "Violet" }, ViewUnitButton = { "View", "Azure" },
	FavoriteButton = { "Favorite", "Night" }, LockUnitButon = { "Lock", "Night" }, SellUnitButton = { "Sell", "Ruby" },
}
for name, spec in pairs(RAIL) do
	local b = rail:FindFirstChild(name) :: GuiButton?
	if b then
		b.Size = S(0.155, 1)
		local ic = b:FindFirstChild("Icon") :: GuiObject?
		if ic then
			place(ic, S(0.06, 0.5), S(0.36, 0.62), V2(0, 0.5))
			drop(ic, "Square")
			new("UIAspectRatioConstraint", { Name = "Square", AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
		end
		local t = b:FindFirstChild("ButtonText") :: TextLabel?
		if not t then t = label("ButtonText", spec[1], b, { TextXAlignment = Enum.TextXAlignment.Center }) end
		local tl = t :: TextLabel
		tl.Text = spec[1]
		tl.Visible = true
		tl.TextScaled = true
		tl.TextXAlignment = Enum.TextXAlignment.Center
		place(tl, S(0.38, 0.2), S(0.58, 0.6))
		for _, k in ipairs(tl:GetChildren()) do if k:IsA("UITextSizeConstraint") then k:Destroy() end end
		new("UITextSizeConstraint", { Name = "Even", MaxTextSize = 100, MinTextSize = 1 }, tl)
		P.convert(b, spec[2])
	end
end
place(bottom:FindFirstChild("UN/EquipButton") :: GuiObject, S(0.58, 0.925), S(0.42, 0.075))
mob(bottom:FindFirstChild("UN/EquipButton"), S(0.51, 0.9), S(0.49, 0.1))

return "Hero Hall built in " .. gui:GetFullName()
