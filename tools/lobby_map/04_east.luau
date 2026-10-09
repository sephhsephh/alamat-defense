-- tools/lobby_map/04_east.luau (B134): east side -- Red Gate fortress (forge, crimson brazier, watchtower) + bridge
-- from the altar, Purple crystal shrine + bridge from the fortress, Green beacon arena + bridge from the plaza, stairs
-- arena -> fortress and arena -> lower ledge (dock).
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local out = {}
local function g(x, z) return Lib.ground(x, z) end
local function beamUp(parent, x, y, z, color, h)
	return Lib.part(parent, { Name = "SkyBeam", Shape = CYL, Size = Vector3.new(h, 1.8, 1.8), CFrame = CFrame.new(x, y + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.6 })
end

-- ===== RED GATE FORTRESS =====
local R = Lib.folder("RedGate")
local a = Lib.edge(Vector3.new(-250, 0, 560), Vector3.new(-40, 0, 585), 8, 2)
local b = Lib.edge(Vector3.new(-30, 0, 590), Vector3.new(-250, 0, 560), 8, 2)
local gateAt = nil
if a and b then
	Lib.bridge(R, a, b, 9, { Name = "Bridge_Altar_RedGate" })
	table.insert(out, string.format("altar->redgate bridge %.0f long (%.1f -> %.1f)", (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude, a.Y, b.Y))
	Lib.path({ Vector3.new(-300, 0, 560), a }, 7)
	local dir = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Unit
	gateAt = Vector3.new(b.X, 0, b.Z) + dir * 14
end
-- torii-style red gate across the path
if gateAt then
	local gy = g(gateAt.X, gateAt.Z) or 124
	local dir = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Unit
	local cf = CFrame.lookAt(Vector3.new(gateAt.X, gy, gateAt.Z), Vector3.new(gateAt.X, gy, gateAt.Z) + dir)
	for _, s in ipairs({ -1, 1 }) do
		Lib.part(R, { Name = "GatePillar", Size = Vector3.new(3, 28, 3), CFrame = cf * CFrame.new(s * 9, 14, 0), Color = C.red, Material = M.SmoothPlastic })
		Lib.part(R, { Name = "GateFoot", Size = Vector3.new(4.4, 2, 4.4), CFrame = cf * CFrame.new(s * 9, 1, 0), Color = Color3.fromRGB(40, 34, 32), Material = M.Slate })
		local bz = Lib.part(R, { Name = "GateFlame", Size = Vector3.new(2, 2, 2), CFrame = cf * CFrame.new(s * 14, 7, -3), Color = C.crimson, Material = M.Neon, CanCollide = false, CastShadow = false })
		Lib.part(R, { Name = "GateBrazier", Size = Vector3.new(2.6, 6, 2.6), CFrame = cf * CFrame.new(s * 14, 3, -3), Color = Color3.fromRGB(40, 34, 32), Material = M.Slate })
		Lib.flame(bz, C.crimson, 1.2)
		Lib.light(bz, C.crimson, 26, 2, false)
	end
	Lib.part(R, { Name = "GateTopBeam", Size = Vector3.new(28, 2.6, 4), CFrame = cf * CFrame.new(0, 28.6, 0), Color = Color3.fromRGB(36, 28, 28), Material = M.Wood })
	Lib.part(R, { Name = "GateTopCurve", Size = Vector3.new(30, 1, 4.4), CFrame = cf * CFrame.new(0, 30.1, 0), Color = Color3.fromRGB(36, 28, 28), Material = M.Wood })
	Lib.part(R, { Name = "GateTieBeam", Size = Vector3.new(22, 1.8, 2.6), CFrame = cf * CFrame.new(0, 23, 0), Color = C.red, Material = M.SmoothPlastic })
	Lib.part(R, { Name = "GatePlaque", Size = Vector3.new(4, 4, 0.6), CFrame = cf * CFrame.new(0, 25.6, -1.4), Color = C.gold, Material = M.Foil })
end
-- forge (Stat Reroll)
local fx, fz = 100, 628
local fy = g(fx, fz)
if fy then
	local F = Lib.sub(R, "Forge")
	Lib.plaza(F, fx, fz, 15, { Name = "ForgeYard", Color = Color3.fromRGB(120, 110, 100), Material = M.Cobblestone })
	Lib.part(F, { Name = "Hearth", Size = Vector3.new(10, 7, 7), Pos = Vector3.new(fx, fy + 3.5, fz - 9), Color = Color3.fromRGB(90, 80, 76), Material = M.Brick })
	local mouth = Lib.part(F, { Name = "HearthFire", Size = Vector3.new(5, 3, 0.4), Pos = Vector3.new(fx, fy + 3, fz - 5.4), Color = Color3.fromRGB(255, 110, 40), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(mouth, Color3.fromRGB(255, 120, 50), 1)
	Lib.light(mouth, Color3.fromRGB(255, 110, 50), 30, 2.4, true)
	Lib.part(F, { Name = "Chimney", Size = Vector3.new(3.4, 14, 3.4), Pos = Vector3.new(fx + 2.5, fy + 14, fz - 10), Color = Color3.fromRGB(80, 70, 66), Material = M.Brick })
	local smoke = Lib.part(F, { Name = "SmokeVent", Size = Vector3.new(2, 0.4, 2), Pos = Vector3.new(fx + 2.5, fy + 21.2, fz - 10), Color = Color3.fromRGB(40, 40, 40), Material = M.Slate, CanCollide = false })
	local sm = Instance.new("ParticleEmitter")
	sm.Texture = "rbxasset://textures/particles/smoke_main.dds"
	sm.Color = ColorSequence.new(Color3.fromRGB(70, 70, 76))
	sm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 8) })
	sm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	sm.Lifetime = NumberRange.new(4, 7)
	sm.Rate = 3
	sm.Speed = NumberRange.new(3, 5)
	sm.Parent = smoke
	Lib.part(F, { Name = "AnvilBase", Size = Vector3.new(1.6, 2.6, 1.6), Pos = Vector3.new(fx + 6, fy + 1.3, fz - 1), Color = Color3.fromRGB(70, 50, 36), Material = M.Wood })
	Lib.part(F, { Name = "Anvil", Size = Vector3.new(3.4, 1.4, 1.6), Pos = Vector3.new(fx + 6, fy + 3.3, fz - 1), Color = Color3.fromRGB(60, 60, 66), Material = M.Metal })
	Lib.part(F, { Name = "Rack", Size = Vector3.new(8, 0.6, 0.6), Pos = Vector3.new(fx - 8, fy + 5, fz - 2), Color = C.woodDark, Material = M.Wood })
	for k = -3, 3, 2 do
		Lib.part(F, { Name = "Blade", Size = Vector3.new(0.4, 5, 0.9), CFrame = CFrame.new(fx - 8 + k, fy + 3, fz - 1.6) * CFrame.Angles(0, 0, math.rad(6)), Color = Color3.fromRGB(190, 196, 210), Material = M.Metal, CanCollide = false })
	end
	table.insert(out, string.format("forge at (%d, %.1f, %d)", fx, fy, fz))
end
-- crimson brazier landmark (the concept's red flame)
local cx, cz = 200, 652
local cy = g(cx, cz)
if cy then
	local K = Lib.sub(R, "CrimsonBrazier")
	Lib.plaza(K, cx, cz, 12, { Name = "BrazierDais", Color = Color3.fromRGB(70, 56, 56), Material = M.Slate })
	Lib.part(K, { Name = "Pedestal", Shape = CYL, Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(cx, cy + 3, cz) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(56, 44, 44), Material = M.Slate })
	Lib.part(K, { Name = "Bowl", Shape = CYL, Size = Vector3.new(1.6, 9, 9), CFrame = CFrame.new(cx, cy + 6.6, cz) * CFrame.Angles(0, 0, math.rad(90)), Color = C.gold, Material = M.Foil })
	local fl = Lib.part(K, { Name = "CrimsonFlame", Shape = BALL, Size = Vector3.new(5, 6, 5), Pos = Vector3.new(cx, cy + 9.6, cz), Color = C.crimson, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.15 })
	Lib.flame(fl, C.crimson, 2.6)
	Lib.motes(fl, Color3.fromRGB(255, 90, 70), 10, 5)
	Lib.light(fl, C.crimson, 55, 3, true)
	for i = 0, 3 do
		local ang = math.rad(i * 90 + 45)
		Lib.part(K, { Name = "RuinPillar", Size = Vector3.new(2.6, 10 + (i % 2) * 6, 2.6), Pos = Vector3.new(cx + math.sin(ang) * 14, cy + 5 + (i % 2) * 3, cz + math.cos(ang) * 14), Color = Color3.fromRGB(120, 40, 36), Material = M.Brick })
	end
end
-- stone watchtower at the east end
local wx, wz = 395, 690
local wy = g(wx, wz)
if wy then
	local W = Lib.sub(R, "Watchtower")
	Lib.part(W, { Name = "TowerBody", Size = Vector3.new(11, 34, 11), Pos = Vector3.new(wx, wy + 17, wz), Color = Color3.fromRGB(120, 112, 104), Material = M.Cobblestone })
	Lib.part(W, { Name = "TowerTop", Size = Vector3.new(14, 2, 14), Pos = Vector3.new(wx, wy + 35, wz), Color = Color3.fromRGB(90, 84, 80), Material = M.Slate })
	for i = -1, 1, 2 do
		for _, axis in ipairs({ "x", "z" }) do
			for k = -1, 1 do
				local off = axis == "x" and Vector3.new(i * 6.4, 0, k * 4.4) or Vector3.new(k * 4.4, 0, i * 6.4)
				Lib.part(W, { Name = "Merlon", Size = Vector3.new(1.6, 2.4, 1.6), Pos = Vector3.new(wx, wy + 37.2, wz) + off, Color = Color3.fromRGB(110, 102, 96), Material = M.Cobblestone })
			end
		end
	end
	local f = Lib.part(W, { Name = "TowerFlame", Size = Vector3.new(2.2, 2, 2.2), Pos = Vector3.new(wx, wy + 37, wz), Color = C.crimson, Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(f, C.crimson, 1.4)
	Lib.light(f, C.crimson, 40, 2, false)
	Lib.part(W, { Name = "Banner", Size = Vector3.new(5, 12, 0.3), Pos = Vector3.new(wx, wy + 26, wz + 5.7), Color = C.red, Material = M.Fabric, CanCollide = false })
	Lib.part(W, { Name = "BannerEmblem", Size = Vector3.new(2.6, 2.6, 0.32), Pos = Vector3.new(wx, wy + 27, wz + 5.75), Color = C.gold, Material = M.Foil, CanCollide = false })
end
Lib.path({ gateAt or Vector3.new(-20, 0, 595), Vector3.new(fx - 15, 0, fz), Vector3.new(cx - 12, 0, cz), Vector3.new(wx - 12, 0, wz) }, 7)

-- ===== PURPLE CRYSTAL SHRINE =====
local P = Lib.folder("PurpleShrine")
local pa = Lib.edge(Vector3.new(230, 0, 610), Vector3.new(250, 0, 400), 8, 2)
local pb = Lib.edge(Vector3.new(260, 0, 390), Vector3.new(235, 0, 610), 8, 2)
if pa and pb then
	Lib.bridge(P, pa, pb, 8, { Name = "Bridge_RedGate_Purple" })
	table.insert(out, string.format("redgate->purple bridge %.0f long (%.1f -> %.1f)", (Vector3.new(pb.X, 0, pb.Z) - Vector3.new(pa.X, 0, pa.Z)).Magnitude, pa.Y, pb.Y))
	Lib.path({ Vector3.new(fx + 15, 0, fz), pa }, 7)
	Lib.path({ pb, Vector3.new(285, 0, 380) }, 7)
end
local sx, sz = 292, 352
local _, sy = Lib.plaza(P, sx, sz, 18, { Name = "ShrinePlaza", Color = Color3.fromRGB(72, 64, 88), Material = M.Slate })
local purple = C.purple
local spire = Lib.part(P, { Name = "CrystalSpire", Size = Vector3.new(4, 26, 4), CFrame = CFrame.new(sx, sy + 13, sz) * CFrame.Angles(0, math.rad(45), math.rad(3)), Color = purple, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.05 })
Lib.light(spire, purple, 60, 3, false)
Lib.motes(spire, Color3.fromRGB(210, 140, 255), 16, 5)
local rng = Random.new(11)
for k = 1, 9 do
	local ang = math.rad(k * 40)
	local r = 4 + rng:NextNumber() * 4
	local h = 6 + rng:NextNumber() * 10
	Lib.part(P, { Name = "Shard", Size = Vector3.new(1.6 + rng:NextNumber(), h, 1.6 + rng:NextNumber()), CFrame = CFrame.new(sx + math.sin(ang) * r, sy + h / 2 - 1, sz + math.cos(ang) * r) * CFrame.Angles(0, ang, 0) * CFrame.Angles(math.rad(14 + rng:NextNumber() * 14), 0, 0),
		Color = (k % 3 == 0) and Color3.fromRGB(240, 170, 255) or purple, Material = M.Neon, CanCollide = false, CastShadow = false })
end
for i = 0, 5 do
	local ang = math.rad(i * 60 + 30)
	local px, pz = sx + math.sin(ang) * 15, sz + math.cos(ang) * 15
	local h = (i % 2 == 0) and 14 or 8
	Lib.part(P, { Name = "RuneColumn", Size = Vector3.new(2.4, h, 2.4), Pos = Vector3.new(px, sy + h / 2, pz), Color = Color3.fromRGB(56, 48, 70), Material = M.Slate })
	Lib.part(P, { Name = "RuneGlow", Size = Vector3.new(0.4, h * 0.6, 0.2), CFrame = CFrame.lookAt(Vector3.new(px, sy + h / 2, pz), Vector3.new(sx, sy + h / 2, sz)) * CFrame.new(0, 0, -1.3), Color = purple, Material = M.Neon, CanCollide = false, CastShadow = false })
end
beamUp(P, sx, sy + 26, sz, purple, 120)
table.insert(out, string.format("purple shrine at (%d, %.1f, %d)", sx, sy, sz))

-- ===== GREEN BEACON ARENA =====
local G = Lib.folder("GreenArena")
local gx, gz = 40, 815
local _, gyy = Lib.plaza(G, gx, gz, 26, { Name = "ArenaFloor", Color = Color3.fromRGB(150, 146, 130), Material = M.Cobblestone })
for i = 0, 11 do
	if i % 3 ~= 0 then
		local ang = math.rad(i * 30)
		Lib.part(G, { Name = "ArenaWall", Size = Vector3.new(12, 3, 2), CFrame = CFrame.new(gx + math.sin(ang) * 27, gyy + 1.5, gz + math.cos(ang) * 27) * CFrame.Angles(0, ang, 0), Color = Color3.fromRGB(110, 106, 98), Material = M.Cobblestone })
	end
end
for i = 0, 3 do
	local ang = math.rad(i * 90)
	local px, pz = gx + math.sin(ang) * 30, gz + math.cos(ang) * 30
	Lib.part(G, { Name = "BannerPole", Size = Vector3.new(0.8, 16, 0.8), Pos = Vector3.new(px, gyy + 8, pz), Color = C.woodDark, Material = M.Wood })
	Lib.part(G, { Name = "BannerCloth", Size = Vector3.new(4, 8, 0.25), CFrame = CFrame.lookAt(Vector3.new(px, gyy + 11, pz), Vector3.new(gx, gyy + 11, gz)) * CFrame.new(0, 0, -0.6), Color = Color3.fromRGB(40, 140, 70), Material = M.Fabric, CanCollide = false })
end
Lib.part(G, { Name = "BeaconBase", Shape = CYL, Size = Vector3.new(2, 12, 12), CFrame = CFrame.new(gx, gyy + 1.2, gz) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 90, 80), Material = M.Slate })
local gf = Lib.part(G, { Name = "GreenFlame", Size = Vector3.new(3, 9, 3), CFrame = CFrame.new(gx, gyy + 6.5, gz) * CFrame.Angles(0, math.rad(45), 0), Color = C.green, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.1 })
Lib.flame(gf, C.green, 1.8)
Lib.motes(gf, C.green, 14, 5)
Lib.light(gf, C.green, 50, 3, false)
beamUp(G, gx, gyy + 11, gz, C.green, 120)
table.insert(out, string.format("green arena at (%d, %.1f, %d)", gx, gyy, gz))
-- bridge plaza -> arena
local ga = Lib.edge(Vector3.new(-300, 0, 782), Vector3.new(40, 0, 812), 8, 2)
local gb = Lib.edge(Vector3.new(10, 0, 812), Vector3.new(-300, 0, 782), 8, 2)
if ga and gb then
	Lib.bridge(G, ga, gb, 9, { Name = "Bridge_Plaza_Arena" })
	table.insert(out, string.format("plaza->arena bridge %.0f long (%.1f -> %.1f)", (Vector3.new(gb.X, 0, gb.Z) - Vector3.new(ga.X, 0, ga.Z)).Magnitude, ga.Y, gb.Y))
	Lib.path({ Vector3.new(-298, 0, 780), ga }, 7)
	Lib.path({ gb, Vector3.new(gx - 26, 0, gz) }, 7)
end
-- stairs arena -> fortress, arena -> ledge (+ dock)
for _, s in ipairs({ { "Stairs_Arena_RedGate", Vector3.new(50, 0, 748), Vector3.new(70, 0, 700) }, { "Stairs_Arena_Ledge", Vector3.new(30, 0, 958), Vector3.new(30, 0, 878) } }) do
	local g0, g1 = g(s[2].X, s[2].Z), g(s[3].X, s[3].Z)
	if g0 and g1 then
		local lo, hi = s[2], s[3]
		local glo, ghi = g0, g1
		if g0 > g1 then lo, hi, glo, ghi = s[3], s[2], g1, g0 end
		Lib.stairs(G, Vector3.new(lo.X, glo, lo.Z), Vector3.new(hi.X, ghi, hi.Z), 8, { Name = s[1] })
		table.insert(out, string.format("%s %.1f -> %.1f", s[1], glo, ghi))
	else
		table.insert(out, s[1] .. " SKIPPED")
	end
end
return table.concat(out, "\n")
