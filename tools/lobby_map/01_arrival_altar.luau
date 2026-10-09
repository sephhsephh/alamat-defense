-- tools/lobby_map/01_arrival_altar.luau (B134): Arrival Plaza (spawn hub) + Golden Flame Altar + the bridge
-- between them + the grand stairs from the altar up to the temple plateau. Run in execute_luau (Lobby, Edit).
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local CYL = Enum.PartType.Cylinder
local function disc(parent, x, y, z, d, h, color, mat, name)
	return Lib.part(parent, { Name = name or "Disc", Shape = CYL, Size = Vector3.new(h, d, d), CFrame = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat })
end
local out = {}

-- ===== ARRIVAL PLAZA (front island) =====
local A = Lib.folder("ArrivalPlaza")
local ax, az = -330, 772
local plaza, ay = Lib.plaza(A, ax, az, 34, { Name = "Plaza" })
local top = ay + 0.4
disc(plaza, ax, top + 0.05, az, 30, 0.2, C.stoneMid, M.Slate, "Mosaic")
disc(plaza, ax, top + 0.1, az, 22, 0.2, C.gold, M.Foil, "GoldRing")
disc(plaza, ax, top + 0.15, az, 20, 0.2, C.stone, M.Limestone, "Inner")
-- compass star (N points at the temple)
for i = 0, 7 do
	local long = (i % 2 == 0)
	local len = long and 26 or 15
	Lib.part(plaza, { Name = "Star", Size = Vector3.new(1.4, 0.25, len), CFrame = CFrame.new(ax, top + 0.22, az) * CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, -len / 2),
		Color = long and C.gold or C.stoneMid, Material = long and M.Foil or M.Slate, CanCollide = false })
end
-- lamp posts on the rim (archived LampPost) + banners flanking the north exit
for i = 0, 7 do
	local ang = math.rad(i * 45 + 22.5)
	Lib.place(A, "LampPost", ax + math.sin(ang) * 31, az + math.cos(ang) * 31, i * 45, 1.25)
end
for _, d in ipairs(A:GetDescendants()) do
	if d:IsA("Light") then d.Shadows = false end -- 8 shadowed lamps on one plaza is too much for mobile
end
Lib.place(A, "BannerPole", ax - 12, az - 37, 0, 1.2)
Lib.place(A, "BannerPole", ax + 12, az - 37, 0, 1.2)
table.insert(out, string.format("plaza at (%d, %.1f, %d)", ax, ay, az))

-- ===== GOLDEN FLAME ALTAR (centre terrace) =====
local L = Lib.folder("FlameAltar")
local lx, lz = -300, 560
local ly = Lib.ground(lx, lz) or 120
local base, _ = Lib.plaza(L, lx, lz, 26, { Name = "AltarPlaza", Y = ly })
local t1 = ly + 0.4
disc(L, lx, t1 + 0.9, lz, 34, 1.8, C.stone, M.Limestone, "Tier1")
disc(L, lx, t1 + 2.7, lz, 24, 1.8, C.stoneMid, M.Limestone, "Tier2")
disc(L, lx, t1 + 4.5, lz, 15, 1.8, C.stone, M.Limestone, "Tier3")
disc(L, lx, t1 + 5.45, lz, 15.6, 0.3, C.gold, M.Foil, "Tier3Trim")
-- brazier: stem + gold bowl + great flame
Lib.part(L, { Name = "Stem", Shape = CYL, Size = Vector3.new(5, 3, 3), CFrame = CFrame.new(lx, t1 + 7.9, lz) * CFrame.Angles(0, 0, math.rad(90)), Color = C.stoneDark, Material = M.Slate })
disc(L, lx, t1 + 10.8, lz, 8, 1.6, C.gold, M.Foil, "Bowl")
disc(L, lx, t1 + 10.2, lz, 6, 1.2, C.gold, M.Foil, "BowlBase")
local fire = Lib.part(L, { Name = "Flame", Shape = Enum.PartType.Ball, Size = Vector3.new(5, 5, 5), Pos = Vector3.new(lx, t1 + 13, lz), Color = Color3.fromRGB(255, 196, 90), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.15 })
Lib.flame(fire, Color3.fromRGB(255, 200, 90), 3.2)
Lib.motes(fire, Color3.fromRGB(255, 210, 120), 14, 6)
Lib.light(fire, Color3.fromRGB(255, 190, 100), 60, 3, true)
-- four gold-capped pillars + torches on the rim
for i = 0, 3 do
	local ang = math.rad(45 + i * 90)
	local px, pz = lx + math.sin(ang) * 21, lz + math.cos(ang) * 21
	Lib.part(L, { Name = "Pillar", Size = Vector3.new(3, 16, 3), Pos = Vector3.new(px, t1 + 8, pz), Color = C.stone, Material = M.Limestone })
	Lib.part(L, { Name = "PillarCap", Size = Vector3.new(4, 1.2, 4), Pos = Vector3.new(px, t1 + 16.6, pz), Color = C.gold, Material = M.Foil })
	local orb = Lib.part(L, { Name = "Orb", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Pos = Vector3.new(px, t1 + 18.2, pz), Color = Color3.fromRGB(255, 210, 120), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.light(orb, Color3.fromRGB(255, 190, 110), 18, 1.4, false)
end
table.insert(out, string.format("altar at (%d, %.1f, %d)", lx, ly, lz))

-- ===== BRIDGE: plaza -> altar =====
local Br = Lib.folder("Bridges_Central")
local a = Lib.edge(Vector3.new(ax, 0, az - 30), Vector3.new(lx, 0, lz), 6, 2)
local b = Lib.edge(Vector3.new(lx, 0, lz + 20), Vector3.new(ax, 0, az), 6, 2)
if a and b then
	Lib.bridge(Br, a, b, 9, { Name = "Bridge_Arrival_Altar" })
	table.insert(out, string.format("bridge %s -> %s (%.0f long)", tostring(a), tostring(b), (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude))
	Lib.path({ Vector3.new(ax, 0, az - 34), Vector3.new(a.X, 0, a.Z) }, 8)
	Lib.path({ Vector3.new(b.X, 0, b.Z), Vector3.new(lx, 0, lz + 26) }, 8)
end

-- ===== GRAND STAIRS: altar -> temple plateau =====
local S = Lib.folder("Stairs_Temple")
local s0 = Vector3.new(-352, 0, 538)
local s1 = Vector3.new(-372, 0, 462)
local g0, g1 = Lib.ground(s0.X, s0.Z), Lib.ground(s1.X, s1.Z)
if g0 and g1 then
	Lib.stairs(S, Vector3.new(s0.X, g0, s0.Z), Vector3.new(s1.X, g1, s1.Z), 12, { Name = "GrandStairs" })
	table.insert(out, string.format("grand stairs %.1f -> %.1f", g0, g1))
	Lib.path({ Vector3.new(lx - 20, 0, lz - 10), s0 }, 8)
end
return table.concat(out, "\n")
