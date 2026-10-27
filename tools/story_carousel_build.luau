-- tools/story_carousel_build.luau  (B174, AD-UI/AD-Lobby, LOBBY Place, run via execute_luau in the EDIT datamodel)
-- Builds the Story stage carousel (user concept "Alamat Defense UI Scroller", Figma node 23:1420) as REAL
-- authored instances under PlayGUI.Main.Content.StoryMap.Carousel:
--   Stage.Slot_m3 .. Slot_p3       authored slot frames (Visible=false): the ONLY layout the cards ever take.
--                                  Attributes: Z (ZIndex), Dim (GroupColor brightness), Fade (GroupTransparency).
--   Stage.StageCardTemplate        ONE CanvasGroup template (Visible=false) cloned per stage by StoryCarousel.
--     Glow / Flame                 white halo + flame tongues (Tint) -- the fake glow, tweened per state
--     Frame.{Art, Shade, InfoShade, Body, Gems, Gold, Info, Lock, Sparkles, Hit}
--   Themes.<Name>                  per-stage frame colours as Color3 attributes (BodyColor, GemColor) -- edit here
--   ArrowLeft / ArrowRight         gold chevrons (Glow + White(Tint) + Gold); Left = Rotation 180
--   Track (+ Studs.StudTemplate)   ornate scroll track; one stud per card, the selected one lights
--   EnterButton                    Alamat Plate (ENTER) = open the centred stage
-- WHITE-TINT RULE: Body, Gems, Glow, Flame, Shade, stud gems, arrow inlay are white art + UIGradient `Tint`.
-- The old island list (StoryMap.Maps + MapCardTemplate) is moved to ServerStorage._UIBackup_B174. Re-run = rebuild.
-- Art + scripts: `Claude outputs/story-carousel/` (split_card.py, split_parts.py, make_card_art.py, asset_ids.txt).

local CS = game:GetService("CollectionService")
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local story = game.StarterGui.PlayGUI.Main.Content.StoryMap
local Theme = require(RS.AlamatUI.Theme)

local IMG = {
	Gold = "rbxassetid://121202360359745", Body = "rbxassetid://97746465183180", Gems = "rbxassetid://108061357271162",
	Window = "rbxassetid://77731422860594", Glow = "rbxassetid://97039444594378", Flame = "rbxassetid://80291048486104",
	TrackGold = "rbxassetid://114149161230824", TrackWhite = "rbxassetid://86339013910801",
	StudGold = "rbxassetid://132081552993167", StudWhite = "rbxassetid://78311671300825",
	ArrowGold = "rbxassetid://107519285664610", ArrowWhite = "rbxassetid://127949554162475",
	ArrowGlow = "rbxassetid://91511426660526", Sparkle = "rbxassetid://102797481207638",
}
local SERIF = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Heavy)
local SANS = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Bold)
local rgb = Color3.fromRGB
local CARD_ASPECT = 896 / 1237 -- the glow canvas (frame art + halo room)
local FRAME_W, FRAME_H = 683 / 896, 1024 / 1237 -- the frame inside the glow canvas

-- ---------------------------------------------------------------- backup + clear
local bk = SS:FindFirstChild("_UIBackup_B174") or Instance.new("Folder")
bk.Name = "_UIBackup_B174"
bk.Parent = SS
local old = story:FindFirstChild("Maps")
if old then
	old.Name = "StoryMap_Maps"
	old.Parent = bk
end
local prev = story:FindFirstChild("Carousel")
if prev then prev:Destroy() end

-- ---------------------------------------------------------------- helpers
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function img(name: string, image: string, parent: Instance, props: { [string]: any }?): ImageLabel
	local p = { Name = name, Image = image, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ScaleType = Enum.ScaleType.Stretch }
	for k, v in pairs(props or {}) do p[k] = v end
	return new("ImageLabel", p, parent)
end
local function tint(parent: Instance, c: any, rot: number?)
	local seq = if typeof(c) == "ColorSequence" then c else ColorSequence.new(c)
	return new("UIGradient", { Name = "Tint", Color = seq, Rotation = rot or 0 }, parent)
end
local function aspect(parent: Instance, r: number)
	return new("UIAspectRatioConstraint", { AspectRatio = r }, parent)
end
local function label(name: string, parent: Instance, props: { [string]: any }): TextLabel
	local p = { Name = name, BackgroundTransparency = 1, TextScaled = true, TextWrapped = true, FontFace = SANS,
		TextColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0) }
	for k, v in pairs(props) do p[k] = v end
	local l = new("TextLabel", p, parent)
	new("UIStroke", { Name = "TextStroke", Color = rgb(14, 8, 26), Thickness = 1.5 }, l)
	return l
end

-- ---------------------------------------------------------------- carousel root
local car = new("Frame", { Name = "Carousel", BackgroundTransparency = 1, Position = UDim2.fromScale(0, 0.12),
	Size = UDim2.fromScale(1, 0.88), ClipsDescendants = true }, story)
local stage = new("Frame", { Name = "Stage", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.8), Active = true }, car)

-- slots: centre, +-1, +-2, +-3 (off-stage). Cards tween to these AUTHORED values only.
local SLOTS = {
	{ "Slot_0", 0, 0.5, 1.0, 10, 1.0, 0 },
	{ "Slot_p1", 0.265, 0.53, 0.78, 8, 0.62, 0 },
	{ "Slot_p2", 0.43, 0.56, 0.6, 6, 0.42, 0.35 },
	{ "Slot_p3", 0.62, 0.58, 0.5, 4, 0.3, 1 },
}
for _, s in ipairs(SLOTS) do
	for _, side in ipairs(if s[2] == 0 then { 1 } else { 1, -1 }) do
		local nm = if side == 1 then s[1] else (string.gsub(s[1], "_p", "_m"))
		local f = new("Frame", { Name = nm, Visible = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + side * s[2], s[3]), Size = UDim2.fromScale(0.6, s[4]) }, stage)
		f:SetAttribute("Z", s[5])
		f:SetAttribute("Dim", s[6])
		f:SetAttribute("Fade", s[7])
	end
end

-- ---------------------------------------------------------------- the card template
local card = new("CanvasGroup", { Name = "StageCardTemplate", Visible = false, BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.6, 1) }, stage)
aspect(card, CARD_ASPECT)
new("UIScale", { Name = "Pop" }, card)
local glow = img("Glow", IMG.Glow, card, { ImageTransparency = 1, ZIndex = 1 })
tint(glow, rgb(255, 150, 40))
local flame = img("Flame", IMG.Flame, card, { ImageTransparency = 1, ZIndex = 2 })
local fl = tint(flame, ColorSequence.new(rgb(255, 222, 130), rgb(255, 126, 30)), 90)
fl.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.4),
	NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 0.3) })

local fr = new("Frame", { Name = "Frame", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(FRAME_W, FRAME_H), ZIndex = 3 }, card)
local art = img("Art", "", fr, { ZIndex = 1 })
art:SetAttribute("Doc", "masked stage art (make_card_art.py) -- PlayConfig map CardArt")
local shade = img("Shade", IMG.Window, fr, { ZIndex = 2, ImageTransparency = 1 })
tint(shade, rgb(12, 8, 26))
-- window = x .261-.739, y .147-.781 of the frame; the info block sits at its foot
local infoShade = new("Frame", { Name = "InfoShade", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.5, 0.79), Size = UDim2.fromScale(0.5, 0.34), ZIndex = 3 }, fr)
local isg = tint(infoShade, rgb(10, 6, 24), 90)
isg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.45, 0.35), NumberSequenceKeypoint.new(1, 0.08) })
local body = img("Body", IMG.Body, fr, { ZIndex = 4 })
tint(body, rgb(96, 58, 24))
local gems = img("Gems", IMG.Gems, fr, { ZIndex = 5 })
tint(gems, rgb(255, 196, 90))
img("Gold", IMG.Gold, fr, { ZIndex = 6 })

local info = new("Frame", { Name = "Info", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.fromScale(0.5, 0.765), Size = UDim2.fromScale(0.42, 0.25), ZIndex = 7 }, fr)
label("StageLabel", info, { Text = "STAGE 1", Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(1, 0.13),
	TextColor3 = rgb(255, 228, 160), ZIndex = 7 })
local nm = label("NameLabel", info, { Text = "Stage Name", FontFace = SERIF, Position = UDim2.fromScale(0.5, 0.17),
	Size = UDim2.fromScale(1, 0.42), ZIndex = 7 })
new("UITextSizeConstraint", { MaxTextSize = 30 }, nm)
local bar = new("Frame", { Name = "ProgressBar", BackgroundColor3 = rgb(28, 18, 54), BorderSizePixel = 0,
	AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.fromScale(0.86, 0.08), ZIndex = 7 }, info)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
new("UIStroke", { Color = rgb(201, 154, 70), Thickness = 1 }, bar)
local fill = new("Frame", { Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	Size = UDim2.fromScale(0.4, 1), ZIndex = 7 }, bar)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
tint(fill, ColorSequence.new(rgb(255, 214, 122), rgb(233, 138, 42)))
label("ProgressLabel", info, { Text = "Acts 0/5", Position = UDim2.fromScale(0.5, 0.8), Size = UDim2.fromScale(1, 0.15),
	TextColor3 = rgb(241, 230, 255), ZIndex = 7 })

local lock = new("Frame", { Name = "Lock", Visible = false, BackgroundColor3 = rgb(40, 28, 72), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromScale(0.2, 0.2), ZIndex = 8 }, fr)
aspect(lock, 1)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, lock)
new("UIStroke", { Color = rgb(217, 169, 78), Thickness = 2 }, lock)
img("Icon", "", lock, { Size = UDim2.fromScale(0.58, 0.58), ZIndex = 8, ImageColor3 = rgb(255, 214, 122) })

local sp = new("Frame", { Name = "Sparkles", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 9 }, fr)
for i, s in ipairs({ { 0.24, 0.13, 0.12 }, { 0.8, 0.5, 0.09 }, { 0.3, 0.86, 0.08 }, { 0.72, 0.2, 0.07 } }) do
	local k = img("Spark" .. i, IMG.Sparkle, sp, { Position = UDim2.fromScale(s[1], s[2]), Size = UDim2.fromScale(s[3], s[3]),
		ImageTransparency = 1, ZIndex = 9 })
	aspect(k, 1)
	tint(k, rgb(255, 224, 150))
end
new("TextButton", { Name = "Hit", Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Selectable = true,
	AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.47), Size = UDim2.fromScale(0.72, 0.78), ZIndex = 10 }, fr)
-- Hit.SelectionImageObject: deliberately empty -- the selected card's glow is the gamepad cue
new("Frame", { Name = "SelectionCue", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, fr)

-- ---------------------------------------------------------------- themes (edit colours here in Studio)
local themes = new("Folder", { Name = "Themes" }, car)
for name, c in pairs({
	Gold = { rgb(96, 58, 24), rgb(255, 196, 90) }, Purple = { rgb(58, 32, 100), rgb(196, 120, 255) },
	Blue = { rgb(24, 52, 112), rgb(110, 200, 255) }, Red = { rgb(104, 26, 32), rgb(255, 92, 80) },
}) do
	local f = new("Folder", { Name = name }, themes)
	f:SetAttribute("BodyColor", c[1])
	f:SetAttribute("GemColor", c[2])
end
themes:SetAttribute("SelectedGemColor", rgb(255, 236, 190))
themes:SetAttribute("LockedArtColor", rgb(180, 178, 200))

-- ---------------------------------------------------------------- arrows
for _, side in ipairs({ "Left", "Right" }) do
	local b = new("TextButton", { Name = "Arrow" .. side, Text = "", BackgroundTransparency = 1, AutoButtonColor = false,
		Selectable = false, AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 20,
		Position = UDim2.fromScale(if side == "Left" then 0.05 else 0.95, 0.42), Size = UDim2.fromScale(0.09, 0.2) }, car)
	aspect(b, 395 / 520)
	new("UIScale", { Name = "Pop" }, b)
	local rot = if side == "Left" then 180 else 0
	local g = img("Glow", IMG.ArrowGlow, b, { Size = UDim2.fromScale(575 / 395, 700 / 520), ImageTransparency = 1, Rotation = rot, ZIndex = 20 })
	tint(g, rgb(255, 160, 50))
	local w = img("White", IMG.ArrowWhite, b, { Rotation = rot, ZIndex = 21 })
	tint(w, rgb(255, 214, 140))
	img("Gold", IMG.ArrowGold, b, { Rotation = rot, ZIndex = 22 })
end

-- ---------------------------------------------------------------- track + studs
local track = new("Frame", { Name = "Track", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.835), Size = UDim2.fromScale(0.7, 0.1), ZIndex = 15 }, car)
aspect(track, 1024 / 104)
tint(img("White", IMG.TrackWhite, track, { ZIndex = 15 }), rgb(52, 36, 96))
img("Gold", IMG.TrackGold, track, { ZIndex = 16 })
local studs = new("Frame", { Name = "Studs", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.72, 0.62), ZIndex = 17 }, track)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0.08, 0), SortOrder = Enum.SortOrder.LayoutOrder }, studs)
local stud = new("Frame", { Name = "StudTemplate", Visible = false, BackgroundTransparency = 1, Size = UDim2.fromScale(0.08, 1), ZIndex = 17 }, studs)
aspect(stud, 52 / 60)
local sw = img("Gem", IMG.StudWhite, stud, { ZIndex = 17 })
tint(sw, rgb(52, 36, 96))
img("Gold", IMG.StudGold, stud, { ZIndex = 18 })
local sg = img("Glow", IMG.Sparkle, stud, { Size = UDim2.fromScale(2.4, 2.4), ImageTransparency = 1, ZIndex = 16 })
tint(sg, rgb(255, 196, 90))

-- ---------------------------------------------------------------- ENTER (Alamat Plate)
local plate = RS.AlamatUI.Templates.AlamatPlate:Clone()
plate.Name = "EnterButton"
plate.Visible = true
plate.Text = "ENTER"
plate.AnchorPoint = Vector2.new(0.5, 0.5)
plate.Position = UDim2.fromScale(0.5, 0.945)
plate.Size = UDim2.fromScale(0.26, 0.085)
plate.ZIndex = 20
plate:SetAttribute("Theme", "Gold")
plate.BackgroundColor3 = Theme.plateColor("Gold")
local pt = plate:FindFirstChild("PlateText")
if pt then pt.Text = "ENTER" end
CS:AddTag(plate, "AlamatButton")
plate.Parent = car

return "built Carousel: " .. #car:GetDescendants() .. " instances; backup " .. #bk:GetChildren()
