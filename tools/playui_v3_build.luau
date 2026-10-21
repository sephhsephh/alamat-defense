-- tools/playui_v3_build.luau  (B171, AD-UI/AD-Lobby, LOBBY Place, run via execute_luau in the EDIT datamodel)
-- Builds the Play UI v3 look (user reference, Figma node 17:1420) as REAL authored instances:
--   PlayGUI.Main.PlayerCard            avatar / name / level / XP (PlayController fills it)
--   PlayGUI.Main.Content.Modes.Cards   Card_Story / Card_Raid / Card_Challenge / Card_Expedition (ornate)
--   PlayGUI.Main.Content.Modes.SpecialEvents.List.EventCardTemplate  (ONE template, Visible=false; cloned)
--   PartyPreview: PARTY divider, hex invite slots, nameplates
-- WHITE-TINT RULE (docs/design/white-tint-art.md): gold layers keep their colour; every white layer (gems, fills)
-- has a UIGradient child named `Tint` -> recolour in Studio by editing Tint.Color.
-- Ornate borders = 9-slice ImageLabels tagged `OrnateSlice` (+ attribute BaseSliceScale, the 1080p value);
-- StarterPlayerScripts.OrnateSliceScaler scales SliceScale with screen height (art detail only, never layout).
-- Old Modes content is backed up to ServerStorage._UIBackup_B171 first. Re-running rebuilds from scratch.

local CS = game:GetService("CollectionService")
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local gui = game.StarterGui.PlayGUI
local main = gui.Main
local content = main.Content
local modes = content.Modes
local preview = main.PartyPreview

local IMG = {
	FrameGold = "rbxassetid://93434482949078", FrameGem = "rbxassetid://126509180564408",
	CrestTop = "rbxassetid://107894179347515", CrestBottom = "rbxassetid://110147531554593",
	RibbonGold = "rbxassetid://91279820451744", RibbonGem = "rbxassetid://127179845630114",
	HexGold = "rbxassetid://70674120323568", HexGem = "rbxassetid://134933819566915", HexFill = "rbxassetid://118196360703535",
	DivLeft = "rbxassetid://112213643824322", DivRight = "rbxassetid://135816570577245",
}
local SLICE = Rect.new(210, 210, 814, 814)
local SERIF = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold)
local SERIF_HEAVY = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Heavy)
local SANS = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
local SANS_BOLD = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local rgb = Color3.fromRGB

local THEME = {
	Azure = { fillTop = rgb(14, 34, 80), gem = rgb(110, 180, 255), ribbon = rgb(40, 100, 210), glow = rgb(62, 155, 255), plate = "Azure" },
	Ruby = { fillTop = rgb(66, 12, 22), gem = rgb(255, 90, 105), ribbon = rgb(180, 36, 52), glow = rgb(226, 56, 74), plate = "Ruby" },
	Violet = { fillTop = rgb(38, 18, 80), gem = rgb(196, 130, 255), ribbon = rgb(126, 64, 226), glow = rgb(165, 91, 255), plate = "Violet" },
	Jade = { fillTop = rgb(10, 52, 34), gem = rgb(90, 226, 140), ribbon = rgb(32, 150, 84), glow = rgb(63, 203, 106), plate = "Jade" },
	Gold = { fillTop = rgb(48, 34, 10), gem = rgb(196, 130, 255), ribbon = rgb(200, 140, 40), glow = rgb(242, 179, 61), plate = "Gold" },
}
local FILL_BOTTOM = rgb(6, 8, 20)

-- ---------------------------------------------------------------- helpers
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function tint(parent: Instance, c0: Color3, c1: Color3?, rot: number?)
	new("UIGradient", {
		Name = "Tint", Rotation = rot or 90,
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(1, c1 or c0) }),
	}, parent)
end
local function label(parent: Instance, name: string, text: string, pos: UDim2, size: UDim2, font: Font, color: Color3, align: Enum.TextXAlignment?, z: number?)
	local l = new("TextLabel", {
		Name = name, Text = text, Position = pos, Size = size, FontFace = font, TextColor3 = color,
		TextScaled = true, BackgroundTransparency = 1, TextXAlignment = align or Enum.TextXAlignment.Left,
		ZIndex = z or 5, TextWrapped = true,
	}, parent)
	new("UIStroke", { Name = "Outline", Color = rgb(8, 6, 18), Thickness = 1.2, Transparency = 0.25, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, l)
	return l
end
local function fill(parent: Instance, top: Color3, z: number?)
	local f = new("Frame", {
		Name = "Fill", Position = UDim2.fromScale(0.012, 0.018), Size = UDim2.fromScale(0.976, 0.964),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = z or 1,
	}, parent)
	new("UICorner", { CornerRadius = UDim.new(0.03, 0) }, f)
	tint(f, top, FILL_BOTTOM)
	return f
end
-- ornate 9-slice border: k = corner scale at 1080p, wPx/hPx = the card's design size in px (for the overflow)
local function border(parent: Instance, k: number, wPx: number, hPx: number, gem: Color3, crests: boolean)
	local m = 49 * k -- px of art outside the frame line
	local pos = UDim2.fromScale(-m / wPx, -m / hPx)
	local size = UDim2.fromScale(1 + 2 * m / wPx, 1 + 2 * m / hPx)
	for _, layer in ipairs({ "Gold", "Gem" }) do
		local img = new("ImageLabel", {
			Name = "Border" .. layer, Image = if layer == "Gold" then IMG.FrameGold else IMG.FrameGem,
			ScaleType = Enum.ScaleType.Slice, SliceCenter = SLICE, SliceScale = k,
			Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = 6, Active = false,
		}, parent)
		img:SetAttribute("BaseSliceScale", k)
		CS:AddTag(img, "OrnateSlice")
		if layer == "Gem" then tint(img, gem) end
	end
	if crests then
		local cw, ch = 164 * k / wPx, 210 * k / hPx
		new("ImageLabel", { Name = "CrestTop", Image = IMG.CrestTop, AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, -m / hPx), Size = UDim2.fromScale(cw, ch), BackgroundTransparency = 1, ZIndex = 6 }, parent)
		new("ImageLabel", { Name = "CrestBottom", Image = IMG.CrestBottom, AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1 + m / hPx), Size = UDim2.fromScale(cw, ch), BackgroundTransparency = 1, ZIndex = 6 }, parent)
	end
end
local function ribbon(parent: Instance, text: string, th: any, pos: UDim2, size: UDim2)
	local r = new("Frame", { Name = "TitleRibbon", Position = pos, Size = size, BackgroundTransparency = 1, ZIndex = 7 }, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1024 / 212 }, r)
	local f = new("Frame", { Name = "RibbonFill", Position = UDim2.fromScale(0.09, 0.36), Size = UDim2.fromScale(0.82, 0.56),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 7 }, r)
	tint(f, th.ribbon, th.fillTop)
	new("ImageLabel", { Name = "RibbonGold", Image = IMG.RibbonGold, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, r)
	local g = new("ImageLabel", { Name = "RibbonGem", Image = IMG.RibbonGem, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 8 }, r)
	tint(g, th.gem)
	label(r, "RibbonTitle", text, UDim2.fromScale(0.14, 0.38), UDim2.fromScale(0.72, 0.5), SERIF, rgb(255, 241, 194), Enum.TextXAlignment.Center, 9)
	return r
end
local plateTemplate = RS.AlamatUI.Templates.AlamatPlate
local function plate(parent: Instance, name: string, text: string, theme: string, pos: UDim2, size: UDim2)
	local p = plateTemplate:Clone()
	p.Name = name
	p.Text = text
	local pt = p:FindFirstChild("PlateText")
	if pt then pt.Text = text end
	p:SetAttribute("Theme", theme)
	p.BackgroundColor3 = require(RS.AlamatUI.Theme).plateColor(theme) -- the root IS the colour (alamat-ui.md)
	p.Position, p.Size, p.ZIndex = pos, size, 7
	p.Visible = true -- the master template is authored hidden
	p.Parent = parent
	return p
end

-- ---------------------------------------------------------------- backup + clear
local backup = SS:FindFirstChild("_UIBackup_B171") or new("Folder", { Name = "_UIBackup_B171" }, SS)
if not backup:FindFirstChild("Modes") then modes:Clone().Parent = backup end
if not backup:FindFirstChild("PartyPreview") then preview:Clone().Parent = backup end
if not backup:FindFirstChild("LayoutB170") then -- the pre-B171 positions, to restore by hand if wanted
	local f = new("Folder", { Name = "LayoutB170" }, backup)
	f:SetAttribute("Content", tostring(content.Position) .. " | " .. tostring(content.Size))
	f:SetAttribute("PartyPreview", tostring(preview.Position) .. " | " .. tostring(preview.Size))
	f:SetAttribute("TopBanner", tostring(main.TopBanner.Position) .. " | " .. tostring(main.TopBanner.Size))
end
for _, n in ipairs({ "Progressive", "Competitive", "ProgressiveHeader", "CompetitiveHeader", "Cards", "SpecialEvents" }) do
	local c = modes:FindFirstChild(n)
	if c then c:Destroy() end
end
for _, n in ipairs({ "PlayerCard" }) do
	local c = main:FindFirstChild(n)
	if c then c:Destroy() end
end

-- ---------------------------------------------------------------- layout (authored here, never moved at runtime)
content.Position, content.Size = UDim2.fromScale(0.448, 0.1), UDim2.fromScale(0.536, 0.71)
preview.Position, preview.Size = UDim2.fromScale(0.02, 0.2), UDim2.fromScale(0.36, 0.66)
main.TopBanner.Position, main.TopBanner.Size = UDim2.fromScale(0.616, 0.012), UDim2.fromScale(0.2, 0.07)

-- ---------------------------------------------------------------- mode cards
local cards = new("Frame", { Name = "Cards", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, modes)
local TALL = { w = 500, h = 290, k = 0.34 }
local WIDE = { w = 500, h = 200, k = 0.30 }
local function card(name: string, th: any, dims: any, pos: UDim2, ribbonText: string, btnText: string): TextButton
	local c = new("TextButton", {
		Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = pos,
		Size = UDim2.fromScale(dims.w / 1029, dims.h / 767), ZIndex = 1, Selectable = true,
	}, cards)
	new("UIScale", { Name = "Pop" }, c)
	fill(c, th.fillTop)
	new("ImageLabel", { Name = "Art", Image = "", ScaleType = Enum.ScaleType.Crop, BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.4, 0.018), Size = UDim2.fromScale(0.588, 0.964), ZIndex = 2 }, c)
	local glow = new("Frame", { Name = "ArtGlow", Position = UDim2.fromScale(0.4, 0.018), Size = UDim2.fromScale(0.588, 0.964),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3 }, c)
	new("UICorner", { CornerRadius = UDim.new(0.03, 0) }, glow)
	new("UIGradient", { Name = "Tint", Rotation = 0, Color = ColorSequence.new(th.glow),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.5) }) }, glow)
	border(c, dims.k, dims.w, dims.h, th.gem, true)
	ribbon(c, ribbonText, th, UDim2.fromScale(0.12, -36 / dims.h), UDim2.fromScale(0.6, 62 / dims.h))
	local by = 1 - (if dims == TALL then 80 else 74) / dims.h
	plate(c, "PlayButton", btnText, th.plate, UDim2.fromScale(0.58, by), UDim2.fromScale(0.37, 56 / dims.h))
	return c
end
local function rewardsRow(c: Instance, dims: any)
	local by = 1 - (if dims == TALL then 80 else 74) / dims.h
	local r = new("Frame", { Name = "Rewards", Position = UDim2.fromScale(0.05, by), Size = UDim2.fromScale(0.5, 56 / dims.h),
		BackgroundTransparency = 1, ZIndex = 5 }, c)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0.03, 0), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center }, r)
end
local GOLD_TXT, BODY_TXT, HEAD_TXT = rgb(255, 210, 122), rgb(232, 228, 216), rgb(247, 242, 230)

-- Story (controller fills MapLabel, ClearedLabel, ProgressLabel, ProgressBar.Fill, Rewards; hides Timer)
local story = card("Card_Story", THEME.Azure, TALL, UDim2.fromScale(0, 22 / 767), "STORY", "PLAY")
label(story, "Kicker", "DEFEND THE ANCESTRAL REALM", UDim2.fromScale(0.06, 0.17), UDim2.fromScale(0.55, 0.065), SERIF, GOLD_TXT)
label(story, "MapLabel", "Apolaki's Sun Terraces", UDim2.fromScale(0.06, 0.25), UDim2.fromScale(0.55, 0.22), SERIF_HEAVY, HEAD_TXT)
label(story, "ClearedLabel", "Acts Cleared 0/5", UDim2.fromScale(0.06, 0.49), UDim2.fromScale(0.5, 0.07), SANS, BODY_TXT)
label(story, "ProgressLabel", "Total Progress 0%", UDim2.fromScale(0.06, 0.575), UDim2.fromScale(0.34, 0.055), SANS, rgb(201, 194, 216))
local pb = new("Frame", { Name = "ProgressBar", Position = UDim2.fromScale(0.06, 0.645), Size = UDim2.fromScale(0.34, 0.03),
	BackgroundColor3 = rgb(6, 10, 24), BorderSizePixel = 0, ZIndex = 5 }, story)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pb)
new("UIStroke", { Color = rgb(122, 94, 42), Thickness = 1 }, pb)
local pf = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.02, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, pb)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pf)
tint(pf, rgb(206, 122, 30), rgb(255, 221, 128), 0)
new("Frame", { Name = "Timer", Visible = false, BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0) }, story)
rewardsRow(story, TALL)

-- Raid (disabled in PlayConfig -> PLAY shows the "coming soon" notification)
local raid = card("Card_Raid", THEME.Ruby, TALL, UDim2.fromScale(530 / 1029, 22 / 767), "RAID", "PLAY")
label(raid, "Kicker", "FACE POWERFUL ENEMIES", UDim2.fromScale(0.06, 0.26), UDim2.fromScale(0.55, 0.065), SERIF, GOLD_TXT)
label(raid, "Headline", "SPIRIT CITADEL", UDim2.fromScale(0.06, 0.34), UDim2.fromScale(0.6, 0.13), SERIF_HEAVY, HEAD_TXT)
label(raid, "Meta", "Recommended Lv. 25", UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.5, 0.065), SANS, BODY_TXT)

-- Challenges (controller fills MapLabel = today's challenge, ClearedLabel, Timer.Label, Rewards)
local chal = card("Card_Challenge", THEME.Violet, WIDE, UDim2.fromScale(0, 362 / 767), "CHALLENGES", "ENTER")
label(chal, "Kicker", "REGULAR · DAILY · WEEKLY", UDim2.fromScale(0.06, 0.2), UDim2.fromScale(0.5, 0.09), SERIF, GOLD_TXT)
label(chal, "MapLabel", "Daily Challenge", UDim2.fromScale(0.06, 0.31), UDim2.fromScale(0.52, 0.13), SERIF_HEAVY, HEAD_TXT)
label(chal, "ClearedLabel", "Challenges Cleared 0", UDim2.fromScale(0.06, 0.465), UDim2.fromScale(0.45, 0.085), SANS, BODY_TXT)
local timer = new("Frame", { Name = "Timer", Position = UDim2.fromScale(0.6, 0.2), Size = UDim2.fromScale(0.34, 0.1), BackgroundTransparency = 1, ZIndex = 5 }, chal)
local ic = new("ImageLabel", { Name = "Icon", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 5 }, timer)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, ic)
label(timer, "Label", "0:00:00", UDim2.fromScale(0.22, 0), UDim2.fromScale(0.78, 1), SANS_BOLD, BODY_TXT)
local cpb = new("Frame", { Name = "ProgressBar", Visible = false, BackgroundTransparency = 1, Size = UDim2.fromScale(0, 0) }, chal)
new("Frame", { Name = "Fill", BackgroundTransparency = 1 }, cpb)
rewardsRow(chal, WIDE)

-- Expeditions (disabled -> notification)
local exp = card("Card_Expedition", THEME.Jade, WIDE, UDim2.fromScale(530 / 1029, 362 / 767), "EXPEDITIONS", "ENTER")
label(exp, "Kicker", "SEND YOUR UNITS INTO UNEXPLORED TERRITORIES", UDim2.fromScale(0.06, 0.2), UDim2.fromScale(0.52, 0.2), SERIF, GOLD_TXT)

-- ---------------------------------------------------------------- special events
local se = new("Frame", { Name = "SpecialEvents", Position = UDim2.fromScale(0, 582 / 767), Size = UDim2.fromScale(1, 185 / 767),
	BackgroundTransparency = 1 }, modes)
local div = new("Frame", { Name = "Divider", Size = UDim2.fromScale(1, 36 / 185), BackgroundTransparency = 1 }, se)
new("ImageLabel", { Name = "Left", Image = IMG.DivLeft, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
	Size = UDim2.fromScale(0.37, 3), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit }, div)
new("ImageLabel", { Name = "Right", Image = IMG.DivRight, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
	Size = UDim2.fromScale(0.37, 3), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit }, div)
label(div, "Title", "SPECIAL EVENTS", UDim2.fromScale(0.37, 0.05), UDim2.fromScale(0.26, 0.9), SERIF, GOLD_TXT, Enum.TextXAlignment.Center)
local list = new("Frame", { Name = "List", Position = UDim2.fromScale(0, 53 / 185), Size = UDim2.fromScale(1, 132 / 185), BackgroundTransparency = 1 }, se)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(20 / 1029, 0), SortOrder = Enum.SortOrder.LayoutOrder }, list)
local EV = { w = 330, h = 132, k = 0.25 }
local ev = new("TextButton", { Name = "EventCardTemplate", Visible = false, Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
	Size = UDim2.fromScale(330 / 1029, 1), Selectable = true }, list)
new("UIScale", { Name = "Pop" }, ev)
fill(ev, THEME.Ruby.fillTop)
new("ImageLabel", { Name = "Art", Image = "", ScaleType = Enum.ScaleType.Crop, BackgroundTransparency = 1,
	Position = UDim2.fromScale(0.55, 0.03), Size = UDim2.fromScale(0.43, 0.94), ZIndex = 2 }, ev)
border(ev, EV.k, EV.w, EV.h, THEME.Ruby.gem, false)
label(ev, "TitleLabel", "BOSS EVENT", UDim2.fromScale(0.07, 0.15), UDim2.fromScale(0.62, 0.17), SERIF, rgb(255, 110, 120))
label(ev, "DescLabel", "Defeat the mighty boss for exclusive rewards!", UDim2.fromScale(0.07, 0.38), UDim2.fromScale(0.55, 0.3), SANS, BODY_TXT)
label(ev, "TimerLabel", "Ends in: 2d 11h", UDim2.fromScale(0.07, 0.74), UDim2.fromScale(0.5, 0.13), SANS_BOLD, Color3.new(1, 1, 1))

-- ---------------------------------------------------------------- player card (top-left)
local PC = { w = 500, h = 140, k = 0.27 }
local pc = new("Frame", { Name = "PlayerCard", Position = UDim2.fromScale(0.0208, 0.03), Size = UDim2.fromScale(500 / 1920, 140 / 1080),
	BackgroundTransparency = 1, ZIndex = 2 }, main)
fill(pc, THEME.Gold.fillTop)
border(pc, PC.k, PC.w, PC.h, THEME.Gold.gem, false)
local av = new("ImageLabel", { Name = "Avatar", Position = UDim2.fromScale(0.03, 0.12), Size = UDim2.fromScale(0.2, 0.76),
	BackgroundColor3 = rgb(34, 48, 94), ZIndex = 5, Image = "" }, pc)
new("UIAspectRatioConstraint", { AspectRatio = 1 }, av)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
new("UIStroke", { Color = rgb(217, 164, 65), Thickness = 3 }, av)
label(pc, "NameLabel", "Player", UDim2.fromScale(0.27, 0.13), UDim2.fromScale(0.62, 0.26), SERIF, HEAD_TXT)
label(pc, "LevelLabel", "Lv. 1", UDim2.fromScale(0.27, 0.48), UDim2.fromScale(0.2, 0.2), SERIF, HEAD_TXT)
label(pc, "XPLabel", "0 / 100 XP", UDim2.fromScale(0.5, 0.51), UDim2.fromScale(0.36, 0.15), SANS, BODY_TXT)
local xb = new("Frame", { Name = "XPBar", Position = UDim2.fromScale(0.27, 0.75), Size = UDim2.fromScale(0.52, 0.065),
	BackgroundColor3 = rgb(6, 10, 24), BorderSizePixel = 0, ZIndex = 5 }, pc)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, xb)
new("UIStroke", { Color = rgb(90, 62, 18), Thickness = 1 }, xb)
local xf = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0.02, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 5 }, xb)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, xf)
tint(xf, rgb(206, 122, 30), rgb(255, 221, 128), 0)

-- ---------------------------------------------------------------- party (PartyPreview restyle)
local old = preview:FindFirstChild("PartyHeader")
if old then old:Destroy() end
local ph = new("Frame", { Name = "PartyHeader", Position = UDim2.fromScale(0, 0), Size = UDim2.fromScale(1, 0.06), BackgroundTransparency = 1, ZIndex = 4 }, preview)
new("ImageLabel", { Name = "Left", Image = IMG.DivLeft, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.02, 0.5),
	Size = UDim2.fromScale(0.36, 3), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 4 }, ph)
new("ImageLabel", { Name = "Right", Image = IMG.DivRight, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.98, 0.5),
	Size = UDim2.fromScale(0.36, 3), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ZIndex = 4 }, ph)
label(ph, "Title", "PARTY", UDim2.fromScale(0.38, 0), UDim2.fromScale(0.24, 1), SERIF, GOLD_TXT, Enum.TextXAlignment.Center, 4)
for _, sp in ipairs(preview.Spots:GetChildren()) do
	local plus = sp:FindFirstChild("PlusButton")
	if plus then
		for _, c in ipairs(plus:GetChildren()) do
			if c:IsA("UIGradient") or c:IsA("UIStroke") or c:IsA("UICorner") or c.Name == "ButtonText" or c.Name:sub(1, 3) == "Hex" or c.Name == "InviteLabel" then c:Destroy() end
		end
		plus.Text, plus.BackgroundTransparency, plus.AutoButtonColor = "", 1, false
		local hf = new("ImageLabel", { Name = "HexFill", Image = IMG.HexFill, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = plus.ZIndex }, plus)
		tint(hf, rgb(16, 20, 54), rgb(6, 8, 20))
		new("ImageLabel", { Name = "HexGold", Image = IMG.HexGold, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = plus.ZIndex + 1 }, plus)
		local hg = new("ImageLabel", { Name = "HexGem", Image = IMG.HexGem, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = plus.ZIndex + 1 }, plus)
		tint(hg, rgb(196, 130, 255))
		label(plus, "InviteLabel", "Invite", UDim2.fromScale(0, 1.02), UDim2.fromScale(1, 0.2), SERIF, rgb(255, 231, 166), Enum.TextXAlignment.Center, plus.ZIndex + 1)
	end
	local tag = sp:FindFirstChild("NameTag")
	if tag then
		tag.BackgroundColor3 = Color3.new(1, 1, 1)
		tag.BackgroundTransparency = 0.08
		local t = tag:FindFirstChild("Tint") or new("UIGradient", { Name = "Tint", Rotation = 90 }, tag)
		t.Color = ColorSequence.new(rgb(26, 20, 70), rgb(8, 8, 24))
		local cr = tag:FindFirstChildOfClass("UICorner") or new("UICorner", {}, tag)
		cr.CornerRadius = UDim.new(0.5, 0)
		local st = tag:FindFirstChildOfClass("UIStroke") or new("UIStroke", {}, tag)
		st.Color, st.Thickness = rgb(217, 164, 65), 1.5
	end
end
return "PlayUI v3 built: cards=" .. #cards:GetChildren() .. " events tpl=" .. tostring(list:FindFirstChild("EventCardTemplate") ~= nil)
