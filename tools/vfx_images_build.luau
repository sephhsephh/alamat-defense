-- tools/vfx_images_build.luau (B158) -- run with execute_luau in EACH Place (Edit). Re-runnable (done nodes skip).
-- User: "i see effects built on frame instead of images / animated images. find all vfx that has that
-- structure, i hate vfx built on frames." Swaps every frame-built EFFECT (rounded-square "rays", stroke
-- circles, flat glow discs, white flash rectangles, bar sunbursts) for the Alamat IMAGE kit. Each node keeps
-- its name, place and size, so its controller only changes Background* -> Image* (B158 code edits):
--   STAR  = Theme.Images.Sparkles[1]  4 long thin rays; crossed copies make a sunburst
--   SOFT  = Theme.Images.Sparkles[3]  a soft fat 4-point glow
--   FLARE = Theme.Images.Flare        soft bloom + streaks: glows, orbs, flashes
--   RING  = Theme.Images.GlowRing     a thin glowing ring: shockwaves
--   RUNE  = Theme.Images.RuneRing     a rune circle: spinners, frames
--   MAGIC = Theme.Images.MagicCircle
-- NOT Theme.Images.Burst: it is black-and-white with a dark body and paints a dark disc over the scene (GUI
-- has no additive blending). The shared ScreenFX burst is rebuilt by tools/screenfx_layer_build.luau.
-- LEFT AS FRAMES on purpose: the Alamat Plate press `Flash` layers, card shine SWEEPS (a gradient sliding
-- across a card), bar fills, the Summon stage backdrop, screen dims/tints, and the two Philippine-sun LOGOS
-- (LoadingScreen Root.Emblem, ObtainRewards Main.Header.Sun) -- a logo needs real emblem art (user to make).
-- Backup: ServerStorage._UIBackup_B158.<ScreenGui>.
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local SG = game:GetService("StarterGui")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any
local Img = Theme.Images
local STAR, SOFT, FLARE, RING, RUNE, MAGIC = Img.Sparkles[1], Img.Sparkles[3], Img.Flare, Img.GlowRing, Img.RuneRing, Img.MagicCircle
local S, V2, C = UDim2.fromScale, Vector2.new, Color3.fromRGB
local GOLD = C(255, 202, 92)
local KEEP_GRADIENTS = { TierGradient = true, Tier = true } -- colour gradients a controller paints; others were shape fades
local log: { string } = {}

local bk = SS:FindFirstChild("_UIBackup_B158") or Instance.new("Folder")
bk.Name = "_UIBackup_B158"
bk.Parent = SS
local function backup(screen: Instance)
	if not bk:FindFirstChild(screen.Name) then screen:Clone().Parent = bk end
end
local function at(root: Instance?, path: string): Instance?
	local o = root
	for _, n in ipairs(string.split(path, ".")) do o = o and o:FindFirstChild(n) end
	return o
end

-- Replace Frame `old` with an ImageLabel of the same name / place / size / attributes. Colour and
-- transparency come from its stroke (a ring) or its fill unless `opts` says otherwise.
-- opts: Image, Size?, AnchorPoint?, Position?, Rot?, Z?, Color?, Tr?, Square? (DominantAxis)
local function swap(old: Instance?, opts: { [string]: any }): ImageLabel?
	if not (old and old:IsA("Frame")) then return nil end -- missing, or already an image (re-run)
	local st = old:FindFirstChildOfClass("UIStroke")
	local img = Instance.new("ImageLabel")
	img.Name = old.Name
	img.Image = opts.Image
	img.BackgroundTransparency = 1
	img.AnchorPoint = opts.AnchorPoint or old.AnchorPoint
	img.Position = opts.Position or old.Position
	img.Size = opts.Size or old.Size
	img.SizeConstraint = old.SizeConstraint
	img.Rotation = opts.Rot or old.Rotation
	img.ZIndex = opts.Z or old.ZIndex
	img.LayoutOrder = old.LayoutOrder
	img.Visible = old.Visible
	img.ImageColor3 = opts.Color or (if st then st.Color else old.BackgroundColor3)
	img.ImageTransparency = opts.Tr or (if st then st.Transparency else old.BackgroundTransparency)
	for k, v in pairs(old:GetAttributes()) do img:SetAttribute(k, v) end
	for _, c in ipairs(old:GetChildren()) do
		if c:IsA("UICorner") or c:IsA("UIStroke") then continue end
		if c:IsA("UIGradient") and not KEEP_GRADIENTS[c.Name] then continue end
		c.Parent = img
	end
	if opts.Square and not img:FindFirstChildOfClass("UIAspectRatioConstraint") then
		local ar = Instance.new("UIAspectRatioConstraint")
		ar.DominantAxis = opts.Square
		ar.Parent = img
	end
	img.Parent = old.Parent
	old:Destroy()
	table.insert(log, img:GetFullName())
	return img
end

-- A bar sunburst (N thin rotated Frames named <prefix><n>) -> crossed STAR images.
-- spec = { { rotation, size, transparency }, ... }; `tier` adds a TierGradient the controller paints.
local function sunburst(box: Instance?, prefix: string, color: Color3, z: number, spec: { { number } }, tier: boolean?)
	if not box then return end
	local bars = {}
	for _, c in ipairs(box:GetChildren()) do
		if c:IsA("Frame") and string.match(c.Name, "^" .. prefix .. "%d+$") then table.insert(bars, c) end
	end
	if #bars == 0 then return end -- done already
	for _, b in ipairs(bars) do b:Destroy() end
	for i, s in ipairs(spec) do
		local img = Instance.new("ImageLabel")
		img.Name = prefix .. tostring(i)
		img.Image = STAR
		img.BackgroundTransparency = 1
		img.AnchorPoint = V2(0.5, 0.5)
		img.Position = S(0.5, 0.5)
		img.Size = S(s[2], s[2])
		img.Rotation = s[1]
		img.ZIndex = z
		img.ImageColor3 = color
		img.ImageTransparency = s[3]
		if tier then
			local g = Instance.new("UIGradient")
			g.Name = "TierGradient"
			g.Parent = img
		end
		img.Parent = box
	end
	table.insert(log, box:GetFullName() .. " (" .. #bars .. " bars -> " .. #spec .. " stars)")
end

-- An art layer added inside a frame that stays a container (the code anchors / parents things to it).
local function art(parent: Instance, name: string, image: string, size: UDim2, color: Color3, tr: number, z: number)
	if parent:FindFirstChild(name) then return end
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.Image = image
	img.BackgroundTransparency = 1
	img.AnchorPoint = V2(0.5, 0.5)
	img.Position = S(0.5, 0.5)
	img.Size = size
	img.ImageColor3 = color
	img.ImageTransparency = tr
	img.ZIndex = z
	img.Parent = parent
	table.insert(log, img:GetFullName())
end

-- a white flash: a soft flare bloom (the code fades ImageTransparency 0 -> 1), centred, square by width
local function flashOpts(size: number): { [string]: any }
	return { Image = FLARE, AnchorPoint = V2(0.5, 0.5), Position = S(0.5, 0.5), Size = S(size, size),
		Square = Enum.DominantAxis.Width, Tr = 1, Color = C(255, 250, 235) }
end
local SUNBURST = { { 0, 1, 0.05 }, { 22.5, 0.72, 0.3 }, { 45, 0.95, 0.1 }, { 67.5, 0.72, 0.3 } } -- 16 rays

-- 1. Trait reroll reel (TraitRerollController colours Ray*/Glow through ImageColor3)
local trs = SG:FindFirstChild("TraitRerollScreen")
if trs then
	backup(trs)
	local card = at(trs, "Main.RollOverlay.Card")
	local ih = card and card:FindFirstChild("IconHolder")
	swap(ih and ih:FindFirstChild("Ray1"), { Image = STAR, Size = S(1.6, 1.6), Tr = 0.1 })
	swap(ih and ih:FindFirstChild("Ray2"), { Image = RUNE, Size = S(1.2, 1.2), Tr = 0.15 })
	swap(ih and ih:FindFirstChild("Glow"), { Image = FLARE, Size = S(1.7, 1.7), Tr = 0.25 })
	swap(card and card:FindFirstChild("Flash"), flashOpts(1.3))
end

-- 2. AL stat reveal (StatRerollController)
local al = SG:FindFirstChild("ALRevealScreen")
if al then
	backup(al)
	local ctr = at(al, "Overlay.Center")
	swap(ctr and ctr:FindFirstChild("Ray1"), { Image = RUNE, Size = S(0.85, 0.85), Tr = 0.15 })
	swap(ctr and ctr:FindFirstChild("Ray2"), { Image = STAR, Size = S(1.5, 1.5), Tr = 0.15 })
	swap(ctr and ctr:FindFirstChild("Ray3"), { Image = MAGIC, Size = S(1.05, 1.05), Tr = 0.35 })
	swap(ctr and ctr:FindFirstChild("Glow"), { Image = FLARE, Size = S(1.3, 1.3), Tr = 0.2 })
	swap(at(al, "Overlay.Flash"), flashOpts(1.4))
end

-- 3. Summon reveal (SummonReveal): rays fade in per image, the orb is a flare with a rune + glow ring
local sr = SG:FindFirstChild("SummonRevealGUI")
if sr then
	backup(sr)
	local ov = sr:FindFirstChild("Overlay")
	sunburst(ov and ov:FindFirstChild("Rays"), "Ray", C(255, 255, 255), 1, { { 0, 1, 0.45 }, { 30, 0.8, 0.45 }, { 60, 0.9, 0.45 } }, true)
	local orb = swap(ov and ov:FindFirstChild("Orb"), { Image = FLARE, Tr = 0 }) or (ov and ov:FindFirstChild("Orb"))
	if orb then
		swap(orb:FindFirstChild("Core"), { Image = SOFT, Tr = 0.1 })
		swap(orb:FindFirstChild("Ring1"), { Image = RUNE })
		swap(orb:FindFirstChild("Ring2"), { Image = RING })
	end
	swap(ov and ov:FindFirstChild("Flash"), flashOpts(1.4))
end

-- 4. Obtain rewards (ObtainRewardsController): sunburst, centre glows, the card's shockwave / glow / flash
local orw = SG:FindFirstChild("ObtainRewardsGUI")
if orw then
	backup(orw)
	local rays = at(orw, "Main.Rays")
	sunburst(rays, "Ray", GOLD, 2, SUNBURST)
	swap(rays and rays:FindFirstChild("Glow1"), { Image = FLARE, Size = S(0.62, 0.62), Tr = 0.45 })
	swap(rays and rays:FindFirstChild("Glow2"), { Image = FLARE, Size = S(0.42, 0.42), Tr = 0.4 })
	swap(rays and rays:FindFirstChild("Glow3"), { Image = SOFT, Size = S(0.26, 0.26), Tr = 0.3 })
	local card = at(orw, "Main.Templates.RewardCard")
	swap(card and card:FindFirstChild("Burst"), { Image = RING, Tr = 1, Color = C(255, 255, 255) })
	swap(at(card, "Main.Glow"), { Image = FLARE, Tr = 0.8 })
	swap(at(card, "Main.Flash"), flashOpts(1.4))
end

-- 5. Loading screen (both Places; LoadingScreenController only rotates these)
local ls = SG:FindFirstChild("LoadingScreen")
if ls then
	backup(ls)
	local rays = at(ls, "Root.Rays")
	sunburst(rays, "Ray", GOLD, 4, SUNBURST)
	swap(rays and rays:FindFirstChild("Halo"), { Image = FLARE, Size = S(0.45, 0.45), Tr = 0.55 })
	swap(at(ls, "Root.Emblem.Ring"), { Image = RUNE, Tr = 0.1, Color = C(255, 225, 150) })
end

-- 6. Crafting ring: stays the container (big card parent + ScreenFX anchor); the stroke circle -> art
local cg = SG:FindFirstChild("CraftingGUI")
local cring = cg and at(cg, "Main.Ring")
if cg and cring and cring:IsA("Frame") and not cring:FindFirstChild("RingArt") then
	backup(cg)
	cring.BackgroundTransparency = 1
	for _, c in ipairs(cring:GetChildren()) do
		if c:IsA("UIStroke") or c:IsA("UICorner") then c:Destroy() end
	end
	art(cring, "GlowArt", FLARE, S(1.35, 1.35), C(255, 220, 120), 0.55, 1)
	art(cring, "RingArt", RUNE, S(1.02, 1.02), C(255, 220, 120), 0.15, 1)
end

-- 7. Daily rewards: the ready card's turning shine -> star rays behind it
local dr = SG:FindFirstChild("DailyRewards")
if dr then
	backup(dr)
	swap(at(dr, "Main.Track.DayCardTemplate.Shine"), { Image = STAR, Size = S(1.35, 1.35), Square = Enum.DominantAxis.Width, Tr = 0.3 })
end

-- 8. Starter choice: slot glows + the reveal aura (StarterPickController colours Aura via ImageColor3)
local sc = SG:FindFirstChild("StarterChoiceScreen")
if sc then
	backup(sc)
	for i = 1, 3 do swap(at(sc, "Main.Units.Slot" .. i .. ".Glow"), { Image = FLARE, Tr = 0.3 }) end
	swap(at(sc, "Reveal.Aura"), { Image = FLARE, Tr = 0.15 })
end

return #log .. " swapped:\n" .. table.concat(log, "\n")
