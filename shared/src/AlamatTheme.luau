--!strict
-- AlamatUI.Theme (B138) -- THE Alamat Defense UI brand in one place: the gold frame, the button palettes,
-- the label fonts and the image-based VFX (white art, tinted per button with a UIGradient named "Tint").
-- SHARED CANON since B151 (both Places, ReplicatedStorage.AlamatUI.Theme). docs/systems/alamat-ui.md.
local Theme = {}

local CS, CK = ColorSequence.new, ColorSequenceKeypoint.new
local NS, NK = NumberSequence.new, NumberSequenceKeypoint.new
local function rgb(r: number, g: number, b: number): Color3 return Color3.fromRGB(r, g, b) end

-- the signature bevelled gold frame (rotated slowly by the animator, so the light travels round the rim)
Theme.Gold = CS({ CK(0, rgb(255, 246, 204)), CK(0.22, rgb(240, 184, 72)), CK(0.48, rgb(150, 88, 24)),
	CK(0.74, rgb(255, 226, 138)), CK(1, rgb(176, 108, 32)) })
-- gold serif label text
Theme.LabelGold = CS({ CK(0, rgb(255, 248, 214)), CK(0.5, rgb(255, 202, 92)), CK(1, rgb(214, 138, 46)) })
Theme.Night = rgb(18, 12, 34)

-- Button palettes: Top -> Bottom is the gem core, Glow tints the VFX art and the corner-stud gems.
Theme.Palettes = {
	Gold = { Top = rgb(255, 221, 128), Bottom = rgb(206, 122, 30), Glow = rgb(255, 204, 96) },
	Violet = { Top = rgb(198, 124, 255), Bottom = rgb(92, 34, 176), Glow = rgb(196, 120, 255) },
	Azure = { Top = rgb(124, 204, 255), Bottom = rgb(34, 82, 198), Glow = rgb(120, 190, 255) },
	Teal = { Top = rgb(112, 242, 214), Bottom = rgb(16, 122, 138), Glow = rgb(96, 232, 210) },
	Ember = { Top = rgb(255, 164, 92), Bottom = rgb(192, 50, 58), Glow = rgb(255, 128, 84) },
	Indigo = { Top = rgb(156, 150, 255), Bottom = rgb(50, 38, 168), Glow = rgb(146, 136, 255) },
	Rose = { Top = rgb(255, 152, 206), Bottom = rgb(172, 48, 126), Glow = rgb(255, 126, 194) },
	Jade = { Top = rgb(156, 240, 122), Bottom = rgb(28, 138, 72), Glow = rgb(126, 232, 112) },
	Night = { Top = rgb(112, 82, 184), Bottom = rgb(34, 20, 70), Glow = rgb(176, 126, 255) },
	-- B151 Plate extras: Ruby (danger / sell), Stone (neutral / secondary)
	Ruby = { Top = rgb(255, 110, 120), Bottom = rgb(150, 20, 40), Glow = rgb(255, 96, 110) },
	Stone = { Top = rgb(150, 144, 170), Bottom = rgb(58, 52, 78), Glow = rgb(210, 200, 240) },
}

Theme.Fonts = {
	Label = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold),
	Body = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
	BodyMedium = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
}

-- Image VFX (Creator Store, white on transparent; tinted by UIGradient "Tint"). Picked visually at B138.
Theme.Images = {
	RuneRing = "rbxassetid://108844775186607",   -- sparse rune ring (hover halo)
	MagicCircle = "rbxassetid://113290594421442", -- detailed magic seal (hero buttons)
	Engraving = "rbxassetid://95270696231518",   -- fine magic circle engraved in every gem (brand motif)
	GlowRing = "rbxassetid://9864075653",        -- soft glowing ring (pulse / breathing / gamepad selector)
	Burst = "rbxassetid://7229481183",           -- radial burst (press flash)
	Flare = "rbxassetid://124607288176561",      -- X flare
	Streak = "rbxassetid://3052949762",          -- thin lens streak (shine sweep)
	Sparkles = { "rbxassetid://6997866340", "rbxassetid://71639137167582", "rbxassetid://81834701835654" },
	PlaceholderIcon = "rbxassetid://101838893546724",
}

-- ===== B151: the PLATE -- THE universal rectangle button (Equip, Claim, Buy, Summon x1, Teams ...) =====
-- The button ROOT is the coloured core: its BackgroundColor3 is the colour (Theme palette, or any custom colour
-- picked in Studio), and the `Core` UIGradient on it is a LUMINANCE ramp (white -> grey) that shades it. So a
-- screen that recolours its button (green "Claim", grey "Incomplete") or dims it (BackgroundTransparency) still
-- works unchanged. Gold rim, gloss, lip, shine, sparkles and the click burst are authored children.
Theme.Plate = {
	Corner = UDim.new(0.3, 0),
	CoreShade = CS({ CK(0, rgb(255, 255, 255)), CK(0.48, rgb(232, 232, 232)), CK(1, rgb(150, 150, 150)) }),
	Gloss = NS({ NK(0, 0.55), NK(0.7, 0.92), NK(1, 1) }),
	Lip = NS({ NK(0, 1), NK(1, 0.55) }),
	TextColor = rgb(255, 255, 255),
	TextStroke = rgb(26, 14, 8),
}

function Theme.palette(name: string?): any
	return Theme.Palettes[name or ""] or Theme.Palettes.Violet
end

-- the gem core, top -> bottom (UIGradient rotation 90)
function Theme.core(name: string?): ColorSequence
	local p = Theme.palette(name)
	return CS(p.Top, p.Bottom)
end

-- a banner card's core: the colour lives behind the icon on the left and fades into the night plate
function Theme.bannerCore(name: string?): ColorSequence
	local p = Theme.palette(name)
	return CS({ CK(0, p.Top), CK(0.3, p.Bottom), CK(0.6, rgb(30, 20, 56)), CK(1, Theme.Night) })
end

-- a plate's root colour for a palette (the Core luminance ramp does the shading)
function Theme.plateColor(name: string?): Color3
	local p = Theme.palette(name)
	return p.Bottom:Lerp(p.Top, 0.55)
end

-- VFX tint: white art -> the palette's glow
function Theme.tint(name: string?): ColorSequence
	local p = Theme.palette(name)
	return CS(Color3.new(1, 1, 1), p.Glow)
end

return Theme
