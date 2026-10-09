-- tools/lobby_map/02_temple.luau (B134): Temple district -- terrace temple, plateau->terrace stairs, Evolve
-- rune circle, glowing waterfall off the plateau's south-west cliff.
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local out = {}
local roofCol = Color3.fromRGB(110, 46, 36)
local wallCol = Color3.fromRGB(176, 160, 132)

local F = Lib.folder("Temple")
local tx, tz = -420, 362
local gy = Lib.ground(tx, tz) or 204
local function blk(name, size, pos, color, mat, extra)
	local p = { Name = name, Size = size, Pos = pos, Color = color, Material = mat }
	if extra then for k, v in pairs(extra) do p[k] = v end end
	return Lib.part(F, p)
end
-- stepped base (front = +Z, facing the altar and the spawn)
blk("Base1", Vector3.new(54, 10, 50), Vector3.new(tx, gy - 3, tz), C.stone, M.Limestone)
blk("Base1Trim", Vector3.new(55, 0.8, 51), Vector3.new(tx, gy + 2.2, tz), C.stoneDark, M.Slate)
blk("Base2", Vector3.new(42, 4, 38), Vector3.new(tx, gy + 4, tz - 2), wallCol, M.Limestone)
blk("Base2Trim", Vector3.new(43, 0.6, 39), Vector3.new(tx, gy + 6.2, tz - 2), C.gold, M.Foil)
local floor = gy + 6
-- front stairs down to the terrace: flight 1 = base2 top (gy+6) -> base1 top (gy+2), flight 2 = base1 -> ground
for i = 1, 5 do
	local topY = gy + 6 - 0.8 * i
	local hgt = topY - (gy + 2) + 0.2
	blk("FrontStep", Vector3.new(14, hgt, 1.7), Vector3.new(tx, topY - hgt / 2, tz + 17 + 1.6 * (i - 0.5)), wallCol, M.Limestone)
end
local gFront = Lib.ground(tx, tz + 34) or (gy - 2)
local n2 = math.max(2, math.ceil((gy + 2 - gFront) / 1))
for i = 1, n2 do
	local topY = gy + 2 - (gy + 2 - gFront) * i / n2
	local hgt = topY - gFront + 3
	blk("LowerStep", Vector3.new(18, hgt, 1.9), Vector3.new(tx, topY - hgt / 2, tz + 25 + 1.8 * (i - 0.5)), C.stone, M.Limestone)
end
-- hall: back + side walls, front wall with a glowing doorway
local hallH = 18
blk("BackWall", Vector3.new(28, hallH, 2), Vector3.new(tx, floor + hallH / 2, tz - 14), wallCol, M.Limestone)
blk("SideWallL", Vector3.new(2, hallH, 26), Vector3.new(tx - 13, floor + hallH / 2, tz - 2), wallCol, M.Limestone)
blk("SideWallR", Vector3.new(2, hallH, 26), Vector3.new(tx + 13, floor + hallH / 2, tz - 2), wallCol, M.Limestone)
blk("FrontWallL", Vector3.new(9, hallH, 2), Vector3.new(tx - 8.5, floor + hallH / 2, tz + 10), wallCol, M.Limestone)
blk("FrontWallR", Vector3.new(9, hallH, 2), Vector3.new(tx + 8.5, floor + hallH / 2, tz + 10), wallCol, M.Limestone)
blk("Lintel", Vector3.new(10, 5, 2), Vector3.new(tx, floor + hallH - 2.5, tz + 10), C.gold, M.Foil)
local glow = blk("DoorGlow", Vector3.new(8, 13, 0.4), Vector3.new(tx, floor + 6.5, tz + 9.4), Color3.fromRGB(110, 190, 255), M.Neon, { CanCollide = false, Transparency = 0.25 })
Lib.light(glow, Color3.fromRGB(110, 190, 255), 26, 2, false)
blk("InnerDark", Vector3.new(24, hallH - 1, 22), Vector3.new(tx, floor + hallH / 2, tz - 2), Color3.fromRGB(30, 26, 30), M.Slate, { CanCollide = true })
-- front colonnade (6 pillars with gold capitals) under a porch roof
for i = -2.5, 2.5, 1 do
	local px = tx + i * 5
	blk("Pillar", Vector3.new(2.2, hallH, 2.2), Vector3.new(px, floor + hallH / 2, tz + 16), C.stone, M.Limestone)
	blk("Capital", Vector3.new(3.2, 1.2, 3.2), Vector3.new(px, floor + hallH - 0.2, tz + 16), C.gold, M.Foil)
	blk("PillarBase", Vector3.new(3, 1, 3), Vector3.new(px, floor + 0.5, tz + 16), C.stoneDark, M.Slate)
end
blk("PorchBeam", Vector3.new(30, 2, 9), Vector3.new(tx, floor + hallH + 1, tz + 13), C.woodDark, M.Wood)
-- three flared roof tiers + gold eaves + upturned corner horns
local rY = floor + hallH + 2
local tiers = { { 40, 36, 3 }, { 30, 26, 3 }, { 20, 16, 3 }, { 10, 8, 2.5 } }
for k, t in ipairs(tiers) do
	local w, d, h = t[1], t[2], t[3]
	blk("Roof" .. k, Vector3.new(w, h, d), Vector3.new(tx, rY + h / 2, tz - 1), roofCol, M.Slate)
	blk("Eave" .. k, Vector3.new(w + 1.2, 0.6, d + 1.2), Vector3.new(tx, rY + 0.3, tz - 1), C.gold, M.Foil)
	if k <= 3 then
		for _, sx in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local horn = Lib.part(F, { Name = "Horn", Class = "WedgePart", Size = Vector3.new(1.2, 3.5, 4),
					CFrame = CFrame.new(tx + sx * (w / 2 + 0.6), rY + 1.6, tz - 1 + sz * (d / 2 + 0.6)) * CFrame.Angles(0, math.atan2(sx, sz), 0) * CFrame.Angles(math.rad(-20), 0, 0),
					Color = C.gold, Material = M.Foil, CastShadow = false })
				horn.CanCollide = false
			end
		end
	end
	rY += h + 1.6
end
-- spire + blue beacon above the temple (the concept's blue light)
Lib.part(F, { Name = "Spire", Shape = CYL, Size = Vector3.new(10, 1.6, 1.6), CFrame = CFrame.new(tx, rY + 5, tz - 1) * CFrame.Angles(0, 0, math.rad(90)), Color = C.gold, Material = M.Foil })
local orb = Lib.part(F, { Name = "SpireOrb", Shape = BALL, Size = Vector3.new(4, 4, 4), Pos = Vector3.new(tx, rY + 11, tz - 1), Color = Color3.fromRGB(110, 190, 255), Material = M.Neon, CanCollide = false, CastShadow = false })
Lib.light(orb, Color3.fromRGB(110, 190, 255), 50, 2.5, false)
Lib.motes(orb, Color3.fromRGB(140, 210, 255), 10, 5)
local beam = Lib.part(F, { Name = "SkyBeam", Shape = CYL, Size = Vector3.new(160, 2.4, 2.4), CFrame = CFrame.new(tx, rY + 11 + 80, tz - 1) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(110, 190, 255), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.55 })
-- braziers at the front corners + torches on the base corners
for _, sx in ipairs({ -1, 1 }) do
	local bx, bz = tx + sx * 22, tz + 22
	blk("BrazierStand", Vector3.new(2.6, 5, 2.6), Vector3.new(bx, gy + 4.5, bz), C.stoneDark, M.Slate)
	local bowl = Lib.part(F, { Name = "BrazierBowl", Shape = CYL, Size = Vector3.new(1.4, 5, 5), CFrame = CFrame.new(bx, gy + 7.6, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = C.gold, Material = M.Foil })
	local fl = Lib.part(F, { Name = "BrazierFlame", Size = Vector3.new(2.6, 2, 2.6), Pos = Vector3.new(bx, gy + 9, bz), Color = C.flame, Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(fl, nil, 1.6)
	Lib.light(fl, C.flameLight, 30, 2, false)
	Lib.torch(F, Vector3.new(tx + sx * 26, gy + 2, tz - 23), 6)
end
table.insert(out, string.format("temple at (%d, %.1f, %d), roof top %.1f", tx, gy, tz, rY + 11))

-- ===== stairs: plateau -> terrace (temple axis) =====
local s0, s1 = Vector3.new(tx, 0, 492), Vector3.new(tx, 0, tz + 40)
local g0, g1 = Lib.ground(s0.X, s0.Z), Lib.ground(s1.X, s1.Z)
if g0 and g1 then
	Lib.stairs(F, Vector3.new(s0.X, g0, s0.Z), Vector3.new(s1.X, g1, s1.Z), 12, { Name = "TerraceStairs" })
	table.insert(out, string.format("terrace stairs %.1f -> %.1f", g0, g1))
	Lib.path({ Vector3.new(-372, 0, 462), Vector3.new(-400, 0, 480), s0 }, 8)
end

-- ===== EVOLVE rune circle (plateau, west) =====
local E = Lib.folder("EvolveCircle")
local ex, ez = -560, 462
local _, ey = Lib.plaza(E, ex, ez, 16, { Name = "RunePlaza", Color = C.stoneMid })
for i = 0, 11 do
	local ang = math.rad(i * 30)
	local r = Lib.part(E, { Name = "Rune", Size = Vector3.new(1, 0.25, 4), CFrame = CFrame.new(ex + math.sin(ang) * 11, ey + 0.55, ez + math.cos(ang) * 11) * CFrame.Angles(0, ang, 0),
		Color = Color3.fromRGB(255, 200, 90), Material = M.Neon, CanCollide = false, CastShadow = false })
end
for i = 0, 3 do
	local ang = math.rad(i * 90 + 45)
	local px, pz = ex + math.sin(ang) * 15, ez + math.cos(ang) * 15
	Lib.part(E, { Name = "Monolith", Size = Vector3.new(2.6, 12, 1.6), CFrame = CFrame.new(px, ey + 6, pz) * CFrame.Angles(0, ang, math.rad(4)), Color = C.stoneDark, Material = M.Slate })
	local g = Lib.part(E, { Name = "MonolithGlyph", Size = Vector3.new(0.6, 6, 0.2), CFrame = CFrame.new(px, ey + 7, pz) * CFrame.Angles(0, ang, math.rad(4)) * CFrame.new(0, 0, -0.9),
		Color = Color3.fromRGB(255, 200, 90), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.light(g, Color3.fromRGB(255, 190, 100), 14, 1, false)
end
Lib.path({ Vector3.new(-400, 0, 480), Vector3.new(-480, 0, 470), Vector3.new(ex + 16, 0, ez) }, 7)

-- ===== glowing waterfall off the plateau's south-west cliff =====
local W = Lib.folder("Waterfall")
local from = Vector3.new(-440, 0, 520)
local lip = Lib.edge(from, Vector3.new(-500, 0, 600), 12, 0)
if lip then
	local dir = (Vector3.new(-500, 0, 600) - from).Unit
	local topY = lip.Y
	local x0 = lip + dir * 3
	local h = topY - 2
	for k, off in ipairs({ -4, 0, 4 }) do
		local right = Vector3.new(-dir.Z, 0, dir.X)
		local p = x0 + right * off + dir * (k == 2 and 1 or 0)
		local sheet = Lib.part(W, { Name = "Fall", Size = Vector3.new(5, h, 0.6), CFrame = CFrame.lookAt(Vector3.new(p.X, topY - h / 2 + 1, p.Z), Vector3.new(p.X, topY - h / 2 + 1, p.Z) + dir),
			Color = Color3.fromRGB(120, 210, 255), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = (k == 2) and 0.35 or 0.5 })
		if k == 2 then Lib.light(sheet, Color3.fromRGB(110, 200, 255), 40, 1.6, false) end
	end
	-- the spring pool on the lip + the splash at the bottom
	Lib.part(W, { Name = "Spring", Shape = CYL, Size = Vector3.new(0.6, 14, 14), CFrame = CFrame.new(lip.X - dir.X * 6, topY + 0.2, lip.Z - dir.Z * 6) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(120, 210, 255), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.4 })
	local splash = Lib.part(W, { Name = "Splash", Shape = CYL, Size = Vector3.new(1, 22, 22), CFrame = CFrame.new(x0.X, 4.5, x0.Z) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(200, 240, 255), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.6 })
	local mist = Instance.new("ParticleEmitter")
	mist.Texture = "rbxasset://textures/particles/smoke_main.dds"
	mist.Color = ColorSequence.new(Color3.fromRGB(210, 240, 255))
	mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 14) })
	mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	mist.Lifetime = NumberRange.new(2, 4)
	mist.Rate = 8
	mist.Speed = NumberRange.new(2, 5)
	mist.SpreadAngle = Vector2.new(60, 60)
	mist.LightEmission = 0.3
	mist.Parent = splash
	Lib.light(splash, Color3.fromRGB(110, 200, 255), 40, 1.5, false)
	table.insert(out, string.format("waterfall lip %s, drop %.0f", tostring(lip), h))
end
return table.concat(out, "\n")
