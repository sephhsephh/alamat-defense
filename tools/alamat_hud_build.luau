-- tools/alamat_hud_build.luau (B138): rebuilds the Lobby HUD (StarterGui.HUD) in the Alamat UI style, "Command
-- Rails" layout (user pick): left 2x3 tile grid, PLAY + SUMMON hero buttons bottom-right (thumb zone), live banner
-- cards right-top, utility gems top-right, gold currency pills top-centre. Every button is a clone of
-- RS.AlamatUI.Templates.AlamatButton -- only Theme (colours) and Variant (layout) differ.
-- KEEPS every name the game looks up: HUD.Left.Buttons.<X>Button, HUD.Right.Buttons.{BattlePass,Event,
-- DailyRewards}Button (+ Main.Texts.ResetTime / EventName / EventTime), HUD.Right.UpperRight.<X>Button,
-- HUD.Top.CurrencyBar.{CurrencyTemplate (IconImage, AmountLabel), ConfigButton (Tooltip)}, NotifBadgeTemplate (Count),
-- BuffStrip.{ChipTemplate (Accent, Label, Timer), ViewAllButton}. MOVED: PlayButton + SummonButton now live in
-- HUD.Right.Hero (HudEntry paths updated in PlayController / SummonGUIController / LobbyHotkeys).
-- Scale-only. Old HUD: ServerStorage._UIBackup_B138.HUD. Idempotent. Run in execute_luau (Lobby, Edit).
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local kit = RS:WaitForChild("AlamatUI")
local Theme = require(kit.Theme)
local AB = require(kit.AlamatButton)
local master = kit.Templates.AlamatButton
local hud = game.StarterGui.HUD
local CS, CK, NS, NK = ColorSequence.new, ColorSequenceKeypoint.new, NumberSequence.new, NumberSequenceKeypoint.new
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if (class:find("Frame") or class:find("Label") or class:find("Button")) and props.BorderSizePixel == nil then o.BorderSizePixel = 0 end
	o.Parent = parent
	return o
end
local function aspect(p, r, dom) return new("UIAspectRatioConstraint", { AspectRatio = r, DominantAxis = dom or Enum.DominantAxis.Height }, p) end
local function clearKids(f, keep)
	for _, c in ipairs(f:GetChildren()) do
		if not (keep and keep[c.Name]) and not c:IsA("LuaSourceContainer") then c:Destroy() end
	end
end
local function textLabel(parent, name, text, font, props)
	local l = new("TextLabel", { Name = name, Text = text, FontFace = font, TextScaled = true, BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6 }, parent)
	for k, v in pairs(props or {}) do l[k] = v end
	new("UIStroke", { Name = "Outline", Color = Color3.fromRGB(16, 8, 28), Thickness = 1.4 }, l)
	return l
end

-- one button from the master
local function make(parent, name, variant, theme, label, icon, order)
	local b = master:Clone()
	b.Name = name
	b.LayoutOrder = order or 0
	b:SetAttribute("Variant", variant)
	b:SetAttribute("Theme", theme)
	b:SetAttribute("Label", label or "")
	local main, aura, lab, sp = b.Main, b.Aura, b.Label, b.Sparkles
	lab.Text.Text = label or ""
	if icon then main.Icon.Image = icon end
	if variant == "Hero" then
		aura.Size = UDim2.fromScale(50, 1.55)
		aura.Circle.ImageTransparency = 0.5
		aura.Glow.ImageTransparency = 0.55
		lab.Size = UDim2.fromScale(1.14, 0.26)
		main.Icon.Size = UDim2.fromScale(0.66, 0.66)
	elseif variant == "Gem" then
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.Position = UDim2.fromScale(0.5, 0.5)
		main.Size = UDim2.fromScale(50, 1)
		main.UICorner.CornerRadius = UDim.new(1, 0)
		main.Depth.UICorner.CornerRadius = UDim.new(1, 0)
		main.Gloss.UICorner.CornerRadius = UDim.new(1, 0)
		main.Gloss.Size = UDim2.fromScale(0.76, 0.42)
		main.Gloss.Position = UDim2.fromScale(0.5, 0.06)
		main.Icon.Size = UDim2.fromScale(0.6, 0.6)
		main.Engraving.Size = UDim2.fromScale(0.86, 0.86)
		for i = 1, 4 do main["Stud" .. i].Visible = false end
		lab.Visible = false
		aura.Position = UDim2.fromScale(0.5, 0.5)
		aura.Size = UDim2.fromScale(50, 1.7)
		for _, s in ipairs(sp:GetChildren()) do s:SetAttribute("S", (s:GetAttribute("S") or 0.2) * 0.8) end
	elseif variant == "Banner" then
		main.Square:Destroy()
		main.AnchorPoint = Vector2.new(0, 0)
		main.Position = UDim2.fromScale(0, 0)
		main.Size = UDim2.fromScale(1, 1)
		main.Core.Rotation = 0
		main.Gloss.Size = UDim2.fromScale(0.97, 0.42)
		main.Gloss.Position = UDim2.fromScale(0.5, 0.06)
		main.Icon.Position = UDim2.fromScale(0.13, 0.5)
		main.Icon.Size = UDim2.fromScale(50, 0.74)
		aspect(main.Icon, 1)
		main.Engraving.Position = UDim2.fromScale(0.13, 0.5)
		main.Engraving.Size = UDim2.fromScale(50, 1.2)
		aspect(main.Engraving, 1)
		main.ShineClip.Streak.Size = UDim2.fromScale(0.55, 1.6)
		main.ShineClip.Streak.Rotation = 24
		for i, p in ipairs({ { 0.015, 0.1 }, { 0.985, 0.1 }, { 0.015, 0.9 }, { 0.985, 0.9 } }) do
			local st = main["Stud" .. i]
			st.Position = UDim2.fromScale(p[1], p[2])
			st.Size = UDim2.fromScale(50, 0.2)
		end
		lab.Visible = false
		aura.Position = UDim2.fromScale(0.13, 0.5)
		aura.Size = UDim2.fromScale(50, 1.5)
		for i, p in ipairs({ { 0.05, 0.12 }, { 0.6, 0.08 }, { 0.95, 0.8 } }) do sp["Spark" .. i].Position = UDim2.fromScale(p[1], p[2]) end
		local texts = new("Frame", { Name = "Texts", Position = UDim2.fromScale(0.27, 0.1), Size = UDim2.fromScale(0.69, 0.8), BackgroundTransparency = 1, ZIndex = 6 }, main)
		new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.04, 0) }, texts)
		local t = textLabel(texts, "Label", label, Theme.Fonts.Label, { Size = UDim2.fromScale(1, 0.38), LayoutOrder = 1 })
		new("UIGradient", { Name = "Gold", Rotation = 90, Color = Theme.LabelGold }, t)
		t.Outline.Color = Color3.fromRGB(40, 20, 6)
	elseif variant == "Pill" then
		main.Square:Destroy()
		main.AnchorPoint = Vector2.new(0, 0)
		main.Position = UDim2.fromScale(0, 0)
		main.Size = UDim2.fromScale(1, 1)
		main.Core.Rotation = 0
		for _, n in ipairs({ "UICorner" }) do main[n].CornerRadius = UDim.new(1, 0) end
		main.Depth.UICorner.CornerRadius = UDim.new(1, 0)
		main.Gloss.UICorner.CornerRadius = UDim.new(1, 0)
		main.Gloss.Size = UDim2.fromScale(0.92, 0.45)
		main.Engraving.Visible = false
		main.Icon.Visible = false
		main.ShineClip.Streak.Size = UDim2.fromScale(0.5, 1.8)
		main.ShineClip.Streak.Rotation = 24
		for i = 1, 4 do main["Stud" .. i].Visible = false end
		lab.Visible = false
		aura.Visible = false
		sp.Visible = false
	end
	b.Parent = parent
	AB.applyTheme(b, theme)
	return b
end

local PH = Theme.Images.PlaceholderIcon

-- ===== LEFT: 2 x 3 tile grid =====
local left = hud:FindFirstChild("Left") or new("Frame", { Name = "Left" }, hud)
clearKids(left)
left.AnchorPoint = Vector2.new(0, 0.5)
left.Position = UDim2.fromScale(0.012, 0.5)
left.Size = UDim2.fromScale(0.3, 0.5)
left.BackgroundTransparency = 1
CollectionService:AddTag(left, "GamepadHud")
left:SetAttribute("GamepadHudOrder", 1)
local lb = new("Frame", { Name = "Buttons", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, left)
aspect(lb, 0.6)
new("UIGridLayout", { CellSize = UDim2.fromScale(0.47, 0.3), CellPadding = UDim2.fromScale(0.06, 0.05), FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder }, lb)
for i, t in ipairs({ { "UnitsButton", "Azure", "Units" }, { "InventoryButton", "Teal", "Inventory" }, { "QuestsButton", "Ember", "Quests" },
	{ "IndexButton", "Indigo", "Index" }, { "ShopButton", "Jade", "Shop" }, { "ProfileButton", "Rose", "Profile" } }) do
	make(lb, t[1], "Tile", t[2], t[3], PH, i)
end

-- ===== RIGHT =====
local right = hud:FindFirstChild("Right") or new("Frame", { Name = "Right" }, hud)
clearKids(right)
right.AnchorPoint = Vector2.new(1, 0)
right.Position = UDim2.fromScale(1, 0)
right.Size = UDim2.fromScale(0.42, 1)
right.BackgroundTransparency = 1
-- utility gems (top-right)
local oldIcons = {
	RedeemCodesButton = "rbxassetid://118591553275491", LeaderBoardsButton = "rbxassetid://91555090198099",
	InviteFriendsButton = "rbxassetid://97434582381047", InboxButton = "rbxassetid://95706773261398", SettingsButton = "rbxassetid://7059346373",
}
local ur = new("Frame", { Name = "UpperRight", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.985, 0.018), Size = UDim2.fromScale(0.95, 0.072), BackgroundTransparency = 1 }, right)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0.018, 0), SortOrder = Enum.SortOrder.LayoutOrder }, ur)
CollectionService:AddTag(ur, "GamepadHud")
ur:SetAttribute("GamepadHudOrder", 4)
for i, n in ipairs({ "RedeemCodesButton", "LeaderBoardsButton", "InviteFriendsButton", "InboxButton", "SettingsButton" }) do
	local g = make(ur, n, "Gem", "Night", "", oldIcons[n], i)
	g.Size = UDim2.fromScale(0.16, 1)
	aspect(g, 1)
end
-- live banner cards (right-top)
local cards = new("Frame", { Name = "Buttons", AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(0.985, 0.125), Size = UDim2.fromScale(0.95, 0.34), BackgroundTransparency = 1 }, right)
aspect(cards, 1.3)
new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0.04, 0) }, cards)
CollectionService:AddTag(cards, "GamepadHud")
cards:SetAttribute("GamepadHudOrder", 3)
local function cardSize(c) c.Size = UDim2.fromScale(1, 0.3) end
local bp = make(cards, "BattlePassButton", "Banner", "Gold", "BATTLE PASS", PH, 1)
cardSize(bp)
local bt = bp.Main.Texts
textLabel(bt, "TierText", "Season 1  -  Tier 0", Theme.Fonts.BodyMedium, { Size = UDim2.fromScale(1, 0.26), LayoutOrder = 2, TextColor3 = Color3.fromRGB(226, 214, 255) })
local bar = new("Frame", { Name = "Progress", Size = UDim2.fromScale(0.94, 0.2), LayoutOrder = 3, BackgroundColor3 = Color3.fromRGB(14, 8, 28), ZIndex = 6 }, bt)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
local bs = new("UIStroke", { Name = "Edge", Color = Color3.new(1, 1, 1), Thickness = 1.2 }, bar)
new("UIGradient", { Name = "Gold", Color = Theme.Gold }, bs)
local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 }, bar)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
new("UIGradient", { Name = "Tint", Color = CS({ CK(0, Color3.fromRGB(255, 228, 128)), CK(0.4, Color3.fromRGB(255, 178, 60)), CK(0.75, Color3.fromRGB(206, 98, 222)), CK(1, Color3.fromRGB(136, 80, 255)) }) }, fill)
local bpt = textLabel(bar, "Text", "0 / 100", Theme.Fonts.Body, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 1.1), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 8 })
local ev = make(cards, "EventButton", "Banner", "Ember", "EVENTS", PH, 2)
cardSize(ev)
textLabel(ev.Main.Texts, "EventName", "Featured events", Theme.Fonts.Body, { Size = UDim2.fromScale(1, 0.27), LayoutOrder = 2, TextColor3 = Color3.fromRGB(255, 214, 170) })
textLabel(ev.Main.Texts, "EventTime", "", Theme.Fonts.BodyMedium, { Size = UDim2.fromScale(1, 0.22), LayoutOrder = 3, TextColor3 = Color3.fromRGB(230, 220, 245) })
local dr = make(cards, "DailyRewardsButton", "Banner", "Azure", "DAILY REWARDS", PH, 3)
cardSize(dr)
textLabel(dr.Main.Texts, "ResetTime", "Resets in 00:00:00", Theme.Fonts.BodyMedium, { Size = UDim2.fromScale(1, 0.28), LayoutOrder = 2, TextColor3 = Color3.fromRGB(205, 232, 255) })
-- hero buttons (bottom-right thumb zone)
local hero = new("Frame", { Name = "Hero", AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(0.985, 0.835), Size = UDim2.fromScale(0.95, 0.2), BackgroundTransparency = 1 }, right)
aspect(hero, 1.95)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Padding = UDim.new(0.04, 0), SortOrder = Enum.SortOrder.LayoutOrder }, hero)
CollectionService:AddTag(hero, "GamepadHud")
hero:SetAttribute("GamepadHudOrder", 2)
for i, t in ipairs({ { "SummonButton", "Violet", "SUMMON" }, { "PlayButton", "Gold", "PLAY" } }) do
	local h = make(hero, t[1], "Hero", t[2], t[3], PH, i)
	h.Size = UDim2.fromScale(0.48, 1)
	if t[1] == "PlayButton" then h:SetAttribute("GamepadDefault", true) end
end

-- ===== TOP: currency pills =====
local top = hud:FindFirstChild("Top")
local cbar = top and top:FindFirstChild("CurrencyBar")
if cbar then
	local oldCfg = cbar:FindFirstChild("ConfigButton")
	local tip = oldCfg and oldCfg:FindFirstChild("Tooltip")
	if tip then tip.Parent = nil end
	clearKids(cbar)
	cbar.Position = UDim2.fromScale(0.5, 0.06)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.02, 0), SortOrder = Enum.SortOrder.LayoutOrder }, cbar)
	local pill = make(cbar, "CurrencyTemplate", "Pill", "Night", "", nil, 0)
	pill.Visible = false
	pill.Size = UDim2.fromScale(1, 1)
	aspect(pill, 3.3)
	local ic = new("ImageLabel", { Name = "IconImage", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.04, 0.5), Size = UDim2.fromScale(50, 0.86),
		BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Image = PH, ZIndex = 7 }, pill)
	aspect(ic, 1)
	local amt = textLabel(pill, "AmountLabel", "0", Theme.Fonts.Body, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.34, 0.5), Size = UDim2.fromScale(0.58, 0.58), ZIndex = 7 })
	new("UIGradient", { Name = "Gold", Rotation = 90, Color = CS(Color3.new(1, 1, 1), Color3.fromRGB(255, 226, 150)) }, amt)
	local cfg = make(cbar, "ConfigButton", "Gem", "Gold", "", "rbxassetid://7059346373", 99)
	cfg.Size = UDim2.fromScale(1, 0.9)
	aspect(cfg, 1)
	if tip then
		tip.Parent = cfg
		tip.Visible = false
	end
end

-- ===== notification badge: a crimson gem with a gold rim =====
local badge = hud:FindFirstChild("NotifBadgeTemplate")
if badge then
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.9, 0.08)
	badge.Size = UDim2.fromScale(50, 0.3)
	if not badge:FindFirstChild("Square") then local a = aspect(badge, 1) a.Name = "Square" end
	badge.BackgroundColor3 = Color3.fromRGB(226, 44, 70)
	badge.ZIndex = 20
	local st = badge:FindFirstChildOfClass("UIStroke")
	if st then st.Color = Color3.fromRGB(255, 214, 120) st.Thickness = 2 end
	local cnt = badge:FindFirstChild("Count")
	if cnt then cnt.FontFace = Theme.Fonts.Body cnt.TextScaled = true cnt.ZIndex = 21 end
end

-- ===== buff strip: night chips with a gold edge =====
local strip = hud:FindFirstChild("BuffStrip")
if strip then
	local chip = strip:FindFirstChild("ChipTemplate")
	if chip then
		chip.Size = UDim2.fromScale(0.27, 0.9)
		chip.BackgroundColor3 = Theme.Night
		chip.BackgroundTransparency = 0.08
		local st = chip:FindFirstChildOfClass("UIStroke")
		if st then
			st.Color = Color3.new(1, 1, 1)
			st.Thickness = 1.5
			if not st:FindFirstChild("Gold") then new("UIGradient", { Name = "Gold", Color = Theme.Gold }, st) end
		end
		for _, n in ipairs({ "Label", "Timer" }) do
			local l = chip:FindFirstChild(n)
			if l then l.FontFace = if n == "Label" then Theme.Fonts.Body else Theme.Fonts.BodyMedium end
		end
	end
	local va = strip:FindFirstChild("ViewAllButton")
	if va then
		va.BackgroundColor3 = Color3.fromRGB(46, 30, 86)
		va.TextColor3 = Color3.fromRGB(255, 226, 150)
		va.FontFace = Theme.Fonts.Body
		if not va:FindFirstChildOfClass("UIStroke") then
			local st = new("UIStroke", { Name = "Edge", Color = Color3.new(1, 1, 1), Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, va)
			new("UIGradient", { Name = "Gold", Color = Theme.Gold }, st)
		end
	end
end
local n = 0
for _, d in ipairs(hud:GetDescendants()) do if CollectionService:HasTag(d, "AlamatButton") then n += 1 end end
return "HUD rebuilt: " .. n .. " Alamat buttons"
