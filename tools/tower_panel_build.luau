-- tools/tower_panel_build.luau (B153) -- run with execute_luau in the GAME (Edit). Re-lays out the in-match
-- SELECTED-UNIT panel (StarterGui.TowerSelection) and the UNIT MANAGER (StarterGui.UnitManager), node names kept.
-- User: "Make the selected unit ui mobile friendly. theres no auto upgrade toggle. add an auto upgrade all button in
-- unit manager ... Revamp that whole selected unit ui ... not all details are present ... make sure everything is placed."
-- User pick (B148 Q): SIDE PANEL on PC / console, BOTTOM SHEET on mobile.
--   * every re-placed node carries its two layouts as ATTRIBUTES -- PcPos/PcSize/PcAnchor/PcVisible and the Mob* twins
--     (UIGridLayout PcCell/MobCell, UIListLayout PcVAlign/MobVAlign, the Root's UIAspectRatioConstraint PcRatio/MobRatio)
--     -- TowerSelectionUI.applyLayout picks one set by device. Tweak a layout in Studio by editing those attributes.
--   * PC stack: portrait card (name, portrait, element / placement / trait badges, range / VFX / breakdown icons,
--     targeting, SELL | AUTO UPGRADE | UPGRADE) -> stats -> EFFECTS & PASSIVES chips -> 4 tiles -> upgrade bar -> key hints;
--     the ability column docks on the panel's right edge.
--   * new: PortraitCard.AutoUpgradeButton, PortraitCard.ReadOnlyBanner (B149 read-only towers), Root.EffectsCard{Header,
--     Chips}, Templates.EffectChipTemplate{Icon, Label}; UnitManager.Root.AutoAllButton.
--   * buttons become Alamat PLATES. Backups: ServerStorage._UIBackup_B153.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any
local P = require(SS.DevTools.AlamatPlate:Clone())
local C = Color3.fromRGB

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end
local function drop(o: Instance, name: string) local c = o:FindFirstChild(name) if c then c:Destroy() end end

-- write a node's two layouts and apply the PC one now
local function lay(o: GuiObject, pc: { any }, mob: { any }?)
	o:SetAttribute("PcAnchor", pc[1]) o:SetAttribute("PcPos", pc[2]) o:SetAttribute("PcSize", pc[3])
	o:SetAttribute("PcVisible", if pc[4] == nil then true else pc[4])
	local m = mob or pc
	o:SetAttribute("MobAnchor", m[1]) o:SetAttribute("MobPos", m[2]) o:SetAttribute("MobSize", m[3])
	o:SetAttribute("MobVisible", if m[4] == nil then true else m[4])
	o.AnchorPoint = pc[1]
	o.Position = pc[2]
	o.Size = pc[3]
end
local V2, S = Vector2.new, UDim2.fromScale

local bk = SS:FindFirstChild("_UIBackup_B153") or new("Folder", { Name = "_UIBackup_B153" }, SS)
for _, n in ipairs({ "TowerSelection", "UnitManager" }) do
	if not bk:FindFirstChild(n) then SG[n]:Clone().Parent = bk end
end

-- ===================================================================== SELECTED-UNIT PANEL
local gui = SG.TowerSelection
local root = gui.Root
local card = root.PortraitCard
local templates = gui.Templates

-- the Root: a tall side panel (PC) / a wide bottom sheet (mobile)
lay(root, { V2(0, 0.5), S(0.006, 0.465), S(0.25, 0.74) }, { V2(0.5, 1), S(0.5, 0.985), S(0.98, 0.45) }) -- PC: clear of the bottom-left HUD
local ar = root:FindFirstChildOfClass("UIAspectRatioConstraint") or new("UIAspectRatioConstraint", {}, root)
ar:SetAttribute("PcRatio", 0.56) ar:SetAttribute("PcAxis", "Height")
ar:SetAttribute("MobRatio", 4.7) ar:SetAttribute("MobAxis", "Width") -- a low strip on a phone (about 45% of its height)
ar.AspectRatio = 0.56
ar.DominantAxis = Enum.DominantAxis.Height

-- sections
lay(card, { V2(0, 0), S(0, 0), S(1, 0.37) }, { V2(0, 0), S(0, 0), S(0.36, 1) })
lay(root.StatsCard, { V2(0, 0), S(0, 0.385), S(1, 0.235) }, { V2(0, 0), S(0.37, 0), S(0.36, 0.6) })
drop(root, "EffectsCard")
local fx = new("Frame", { Name = "EffectsCard", BackgroundColor3 = C(255, 255, 255), ZIndex = 1 }, root)
lay(fx, { V2(0, 0), S(0, 0.632), S(1, 0.12) }, { V2(0, 0), S(0.37, 0.62), S(0.36, 0.38) })
new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, fx)
new("UIGradient", { Name = "Glass", Rotation = 90, Color = ColorSequence.new(C(46, 30, 82), C(20, 13, 38)) }, fx)
local fxs = new("UIStroke", { Name = "Edge", Color = C(255, 255, 255), Thickness = 1.2, Transparency = 0.35 }, fx)
new("UIGradient", { Name = "Gold", Color = Theme.Gold }, fxs)
local hdr = new("TextLabel", { Name = "Header", BackgroundTransparency = 1, Position = S(0.03, 0.04), Size = S(0.94, 0.26),
	Text = "EFFECTS & PASSIVES", TextScaled = true, FontFace = Theme.Fonts.Label, TextColor3 = C(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2 }, fx)
new("UIGradient", { Name = "Gold", Rotation = 90, Color = Theme.LabelGold }, hdr)
new("UITextSizeConstraint", { MaxTextSize = 18 }, hdr)
local chips = new("Frame", { Name = "Chips", BackgroundTransparency = 1, Position = S(0.03, 0.34), Size = S(0.94, 0.62), ZIndex = 2 }, fx)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0.015, 0),
	SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top }, chips)

lay(root.TilesRow, { V2(0, 0), S(0, 0.765), S(1, 0.12) }, { V2(0, 0), S(0.74, 0), S(0.26, 0.6) })
local grid = root.TilesRow:FindFirstChildOfClass("UIGridLayout")
grid:SetAttribute("PcCell", S(0.235, 0.92)) grid:SetAttribute("MobCell", S(0.48, 0.46))
grid:SetAttribute("PcPad", S(0.02, 0)) grid:SetAttribute("MobPad", S(0.04, 0.08))
grid.CellSize = S(0.235, 0.92)
grid.CellPadding = S(0.02, 0)
lay(root.UpgradeBar, { V2(0, 0), S(0, 0.897), S(1, 0.04) }, { V2(0, 0), S(0.74, 0.66), S(0.26, 0.12) })
lay(root.HotkeyRow, { V2(0, 0), S(0, 0.95), S(1, 0.05) }, { V2(0, 0), S(0, 0), S(0, 0), false })
lay(root.AbilityColumn, { V2(0, 0), S(1.03, 0), S(0.17, 0.62) }, { V2(0, 1), S(0, -0.03), S(0.075, 1.3) })
local al = root.AbilityColumn:FindFirstChildOfClass("UIListLayout")
al:SetAttribute("PcVAlign", "Top") al:SetAttribute("MobVAlign", "Bottom")
lay(root.CloseButton, { V2(0.5, 0.5), S(0.97, 0.015), S(0.1, 0.06) }, { V2(0.5, 0.5), S(0.99, 0.02), S(0.04, 0.16) })
if not root.CloseButton:FindFirstChildOfClass("UIAspectRatioConstraint") then
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, root.CloseButton)
end

-- portrait card insides (one layout: the card keeps its proportions on both devices)
card.NameLabel.AnchorPoint = V2(0.5, 0) card.NameLabel.Position = S(0.5, 0.03) card.NameLabel.Size = S(0.92, 0.12)
card.Viewport.AnchorPoint = V2(0, 0) card.Viewport.Position = S(0.03, 0.17) card.Viewport.Size = S(0.4, 0.57)
for _, row in ipairs({ card.Badges, card.IconStrip }) do
	row.AnchorPoint = V2(0, 0)
	row.Size = S(0.51, 0.16)
	local l = row:FindFirstChildOfClass("UIListLayout")
	l.FillDirection = Enum.FillDirection.Horizontal
	l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	l.VerticalAlignment = Enum.VerticalAlignment.Center
	l.Padding = UDim.new(0.04, 0)
	for _, b in ipairs(row:GetChildren()) do
		if b:IsA("GuiObject") then
			b.Size = S(3, 1)
			local a = b:FindFirstChildOfClass("UIAspectRatioConstraint")
			if a then a.DominantAxis = Enum.DominantAxis.Height end
		end
	end
end
card.Badges.Position = S(0.46, 0.17)
card.IconStrip.Position = S(0.46, 0.36)
card.PriorityRow.AnchorPoint = V2(0.5, 0) card.PriorityRow.Position = S(0.715, 0.53) card.PriorityRow.Size = S(0.51, 0.22)
card.SellButton.Position = S(0.03, 0.97) card.SellButton.Size = S(0.29, 0.19)
card.UpgradeButton.Position = S(0.97, 0.97) card.UpgradeButton.Size = S(0.29, 0.19)
drop(card, "AutoUpgradeButton")
local auto = new("TextButton", { Name = "AutoUpgradeButton", AnchorPoint = V2(0.5, 1), Position = S(0.5, 0.97), Size = S(0.33, 0.19),
	Text = "", BackgroundColor3 = Theme.plateColor("Stone"), ZIndex = card.SellButton.ZIndex }, card)
local cap = new("TextLabel", { Name = "Caption", BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0), Position = S(0.5, 0.06),
	Size = S(0.9, 0.4), Text = "Auto Upgrade", TextScaled = true, FontFace = Theme.Fonts.Label, TextColor3 = C(255, 255, 255) }, auto)
new("UITextSizeConstraint", { MaxTextSize = 18 }, cap)
local val = new("TextLabel", { Name = "Value", BackgroundTransparency = 1, AnchorPoint = V2(0.5, 0), Position = S(0.5, 0.5),
	Size = S(0.9, 0.42), Text = "OFF", TextScaled = true, FontFace = Theme.Fonts.Label, TextColor3 = C(255, 255, 255) }, auto)
new("UITextSizeConstraint", { MaxTextSize = 22 }, val)
local kc = card.UpgradeButton:FindFirstChild("KeyChip")
if kc then
	local k = kc:Clone()
	k.Key.Text = "Z"
	k.Parent = auto
end
drop(card, "ReadOnlyBanner")
-- a UIGradient tints a TextLabel's TEXT too (the first build rendered it invisible), so: Frame (gradient) + Label
local roZ = card.SellButton.ZIndex + 6
local ro = new("Frame", { Name = "ReadOnlyBanner", AnchorPoint = V2(0.5, 1), Position = S(0.5, 0.97), Size = S(0.94, 0.19),
	BackgroundColor3 = C(255, 255, 255), Visible = false, ZIndex = roZ }, card)
new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, ro)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(C(70, 46, 120), C(30, 18, 56)) }, ro)
local ros = new("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = C(255, 255, 255), Thickness = 1.5 }, ro)
new("UIGradient", { Color = Theme.Gold }, ros)
new("TextLabel", { Name = "Label", AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(0.92, 0.64),
	BackgroundTransparency = 1, Text = "MATCH OVER  -  read only", TextScaled = true, FontFace = Theme.Fonts.Label,
	TextColor3 = C(255, 236, 196), ZIndex = roZ + 1 }, ro)

-- plates
P.convert(card.SellButton, "Ruby")
P.convert(card.UpgradeButton, "Jade")
P.convert(auto, "Stone")
P.convert(card.PriorityRow.PrevButton, "Night")
P.convert(card.PriorityRow.NextButton, "Night")
local ab = root.AbilityColumn.AutoButton
ab.BackgroundColor3 = C(255, 255, 255)
P.convert(ab, nil)
P.convert(root.AbilityColumn.PassivesButton, "Violet")

-- the chip template (effects + passives)
drop(templates, "EffectChipTemplate")
local chip = new("Frame", { Name = "EffectChipTemplate", Size = S(0.32, 0.46), BackgroundColor3 = C(255, 255, 255), Visible = false }, templates)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, chip)
new("UIGradient", { Name = "Glass", Rotation = 90, Color = ColorSequence.new(C(70, 48, 118), C(34, 22, 64)) }, chip)
new("UIStroke", { Name = "Edge", Color = C(255, 214, 120), Thickness = 1.2, Transparency = 0.2 }, chip)
local ic = new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, AnchorPoint = V2(0, 0.5), Position = S(0.04, 0.5),
	Size = S(3, 0.8), ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, chip)
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, ic)
local gl = new("TextLabel", { Name = "Glyph", BackgroundTransparency = 1, AnchorPoint = V2(0, 0.5), Position = S(0.04, 0.5),
	Size = S(3, 0.8), Text = "", TextScaled = true, FontFace = Theme.Fonts.Body, TextColor3 = C(255, 255, 255), ZIndex = 4 }, chip)
new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, gl)
local cl = new("TextLabel", { Name = "Label", BackgroundTransparency = 1, Position = S(0.28, 0.14), Size = S(0.68, 0.72),
	Text = "Slow 2s", TextScaled = true, FontFace = Theme.Fonts.Body, TextColor3 = C(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, chip)
new("UITextSizeConstraint", { MaxTextSize = 16 }, cl)

-- ===================================================================== UNIT MANAGER
local um = SG.UnitManager.Root
um.BackButton.Size = S(0.29, um.BackButton.Size.Y.Scale)
um.SellAllButton.Position = S(0.68, um.SellAllButton.Position.Y.Scale)
um.SellAllButton.Size = S(0.29, um.SellAllButton.Size.Y.Scale)
drop(um, "AutoAllButton")
local all = um.SellAllButton:Clone()
for _, c in ipairs(all:GetChildren()) do
	if c:IsA("UIGradient") or c:IsA("UIStroke") or table.find({ "Inner", "Gloss", "Lip", "ShineClip", "Flash", "Burst", "Sparkles", "PlateText", "Pop" }, c.Name) then c:Destroy() end
end
all.Name = "AutoAllButton"
all.Text = "Auto Upgrade All"
all.Position = S(0.355, um.SellAllButton.Position.Y.Scale)
all.Parent = um
P.convert(all, "Jade")
P.convert(um.BackButton, "Stone")
P.convert(um.SellAllButton, "Ruby")
for _, n in ipairs({ "StrictUpgradeOrder", "StrictQueueOrder", "AutoUpgradeNewUnits", "AutoAbilitiesNewUnits", "MoreSettings" }) do
	local b = um.AutomationRow:FindFirstChild(n)
	if b and b:IsA("GuiButton") then P.convert(b, if n == "MoreSettings" then "Night" else nil) end
end
local ct = SG.UnitManager.CardTemplate
P.convert(ct.UpgradeButton, nil)
P.convert(ct.TargetButton, "Azure")
P.convert(ct.ButtonRow.SellButton, "Ruby")
P.convert(ct.AutoRow.AutoToggle, nil)

return "tower panel + unit manager rebuilt"
