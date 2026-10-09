-- tools/lobby_map/03_west.luau (B134): west side -- Blue Beacon rock (+ bridge to the plaza, stairs to the beach),
-- Village beach (market with Shop + Craft stalls, nipa huts, piers, bangka boats, campfire), Jungle (stair chain
-- village -> step -> jungle -> plateau, back-hill stairs, lookout tower, ruined arch).
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local CYL, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball
local out = {}
workspace.Terrain:SetMaterialColor(M.Sandstone, Color3.fromRGB(198, 178, 140))
local function g(x, z) return Lib.ground(x, z) end

-- ===== reusable pieces =====
local function hut(parent, x, z, yaw)
	local gy = g(x, z)
	if not gy then return end
	local m = Lib.sub(parent, "NipaHut")
	local cf = CFrame.new(x, gy, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local function at(px, py, pz) return cf * CFrame.new(px, py, pz) end
	for _, sx in ipairs({ -4.5, 4.5 }) do
		for _, sz in ipairs({ -3.5, 3.5 }) do
			Lib.part(m, { Name = "Stilt", Size = Vector3.new(0.8, 6, 0.8), CFrame = at(sx, 2.5, sz), Color = C.woodDark, Material = M.Wood })
		end
	end
	Lib.part(m, { Name = "Floor", Size = Vector3.new(11, 0.6, 9), CFrame = at(0, 5.3, 0), Color = C.woodLight, Material = M.WoodPlanks })
	Lib.part(m, { Name = "Walls", Size = Vector3.new(9.5, 5.5, 7.5), CFrame = at(0, 8.3, 0), Color = Color3.fromRGB(196, 168, 112), Material = M.WoodPlanks })
	Lib.part(m, { Name = "Door", Size = Vector3.new(2.4, 4, 0.2), CFrame = at(0, 7.6, 3.8), Color = Color3.fromRGB(40, 28, 20), Material = M.Wood })
	local win = Lib.part(m, { Name = "Window", Size = Vector3.new(2, 1.6, 0.2), CFrame = at(-3, 8.8, 3.8), Color = Color3.fromRGB(255, 190, 110), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.light(win, Color3.fromRGB(255, 170, 90), 12, 1, false)
	for _, s in ipairs({ -1, 1 }) do
		Lib.part(m, { Name = "Thatch", Size = Vector3.new(13, 0.8, 7), CFrame = at(0, 12.4, s * 2.6) * CFrame.Angles(math.rad(-s * 38), 0, 0), Color = C.thatch, Material = M.Grass })
	end
	Lib.part(m, { Name = "Ridge", Size = Vector3.new(13.4, 0.8, 0.8), CFrame = at(0, 14.4, 0), Color = Color3.fromRGB(140, 110, 60), Material = M.Grass })
	-- ladder
	for k = 0, 4 do
		Lib.part(m, { Name = "Rung", Size = Vector3.new(2.4, 0.3, 0.3), CFrame = at(0, 1 + k, 5.3 + k * 0.1), Color = C.woodDark, Material = M.Wood, CastShadow = false })
	end
	return m
end

local function boat(parent, pos, yaw)
	local m = Lib.sub(parent, "Bangka")
	local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	Lib.part(m, { Name = "Hull", Size = Vector3.new(3, 1.6, 16), CFrame = cf * CFrame.new(0, 0.6, 0), Color = Color3.fromRGB(150, 60, 40), Material = M.WoodPlanks })
	Lib.part(m, { Name = "Trim", Size = Vector3.new(3.2, 0.3, 16.2), CFrame = cf * CFrame.new(0, 1.5, 0), Color = Color3.fromRGB(230, 220, 190), Material = M.Wood })
	for _, s in ipairs({ -1, 1 }) do
		Lib.part(m, { Name = "Bow", Size = Vector3.new(2, 1.2, 3), CFrame = cf * CFrame.new(0, 1.1, s * 9) * CFrame.Angles(math.rad(s * 20), 0, 0), Color = Color3.fromRGB(150, 60, 40), Material = M.WoodPlanks })
		Lib.cyl(m, (cf * CFrame.new(-1.5, 1.6, s * 3)).Position, (cf * CFrame.new(-7, 1.2, s * 3)).Position, 0.3, { Name = "Boom", Color = C.woodDark, Material = M.Wood })
		Lib.cyl(m, (cf * CFrame.new(1.5, 1.6, s * 3)).Position, (cf * CFrame.new(7, 1.2, s * 3)).Position, 0.3, { Name = "Boom", Color = C.woodDark, Material = M.Wood })
	end
	for _, sx in ipairs({ -7, 7 }) do
		Lib.part(m, { Name = "Float", Shape = CYL, Size = Vector3.new(12, 0.8, 0.8), CFrame = cf * CFrame.new(sx, 0.9, 0) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(200, 190, 160), Material = M.Wood })
	end
	return m
end

local function stall(parent, x, z, yaw, cloth, name)
	local gy = g(x, z)
	if not gy then return end
	local m = Lib.sub(parent, name)
	local cf = CFrame.new(x, gy, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local function at(px, py, pz) return cf * CFrame.new(px, py, pz) end
	for _, sx in ipairs({ -5.5, 5.5 }) do
		for _, sz in ipairs({ -3, 3 }) do
			Lib.part(m, { Name = "Post", Size = Vector3.new(0.7, 9, 0.7), CFrame = at(sx, 4.5, sz), Color = C.woodDark, Material = M.Wood })
		end
	end
	Lib.part(m, { Name = "Counter", Size = Vector3.new(11, 3, 2.4), CFrame = at(0, 1.5, 2.2), Color = C.wood, Material = M.WoodPlanks })
	Lib.part(m, { Name = "CounterTop", Size = Vector3.new(11.6, 0.4, 2.8), CFrame = at(0, 3.2, 2.2), Color = C.woodLight, Material = M.Wood })
	Lib.part(m, { Name = "Awning", Size = Vector3.new(13, 0.3, 8.5), CFrame = at(0, 9.4, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), Color = cloth, Material = M.Fabric })
	for i = -2, 2 do
		Lib.part(m, { Name = "AwningStripe", Size = Vector3.new(1.2, 0.32, 8.6), CFrame = at(i * 2.6, 9.42, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(240, 226, 196), Material = M.Fabric, CanCollide = false, CastShadow = false })
	end
	local lamp = Lib.part(m, { Name = "Lantern", Shape = BALL, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = at(4.8, 7.6, 3.4), Color = Color3.fromRGB(255, 190, 110), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.light(lamp, Color3.fromRGB(255, 170, 90), 16, 1.2, false)
	return m, at
end

-- ===== BLUE BEACON (rock) =====
local B = Lib.folder("BlueBeacon")
local bx, bz = -612, 815
local _, by = Lib.plaza(B, bx, bz, 13, { Name = "BeaconPlaza", Color = C.stoneMid })
for i = 0, 5 do
	local ang = math.rad(i * 60)
	local px, pz = bx + math.sin(ang) * 10, bz + math.cos(ang) * 10
	Lib.part(B, { Name = "RingPillar", Size = Vector3.new(1.6, 5, 1.6), Pos = Vector3.new(px, by + 2.8, pz), Color = C.stoneDark, Material = M.Slate })
	local cap = Lib.part(B, { Name = "RingCap", Shape = BALL, Size = Vector3.new(1.4, 1.4, 1.4), Pos = Vector3.new(px, by + 6, pz), Color = C.blue, Material = M.Neon, CanCollide = false, CastShadow = false })
end
local core = Lib.part(B, { Name = "Crystal", Size = Vector3.new(3, 12, 3), CFrame = CFrame.new(bx, by + 7, bz) * CFrame.Angles(0, math.rad(45), 0), Color = C.blue, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.1 })
for k = 1, 3 do
	Lib.part(B, { Name = "Shard", Size = Vector3.new(1.4, 6, 1.4), CFrame = CFrame.new(bx, by + 3.5, bz) * CFrame.Angles(0, math.rad(k * 120), 0) * CFrame.new(0, 0, 2.6) * CFrame.Angles(math.rad(22), 0, 0),
		Color = C.blue, Material = M.Neon, CanCollide = false, CastShadow = false })
end
Lib.light(core, C.blue, 50, 3, false)
Lib.motes(core, C.blue, 16, 5)
Lib.part(B, { Name = "SkyBeam", Shape = CYL, Size = Vector3.new(120, 1.8, 1.8), CFrame = CFrame.new(bx, by + 13 + 60, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = C.blue, Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.6 })
table.insert(out, string.format("blue beacon at (%d, %.1f, %d)", bx, by, bz))
-- bridge to the plaza island + stairs down to the beach
local a = Lib.edge(Vector3.new(bx + 8, 0, bz - 4), Vector3.new(-430, 0, 790), 8, 2)
local b = Lib.edge(Vector3.new(-430, 0, 790), Vector3.new(bx, 0, bz), 8, 2)
if a and b then
	Lib.bridge(B, a, b, 8, { Name = "Bridge_Beacon_Plaza" })
	Lib.path({ b, Vector3.new(-362, 0, 776) }, 7)
	table.insert(out, string.format("beacon bridge %.0f long", (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude))
end
do
	local s0, s1 = Vector3.new(-615, 0, 932), Vector3.new(-615, 0, 838)
	local g0, g1 = g(s0.X, s0.Z), g(s1.X, s1.Z)
	if g0 and g1 then
		Lib.stairs(B, Vector3.new(s0.X, g0, s0.Z), Vector3.new(s1.X, g1, s1.Z), 8, { Name = "Stairs_Beacon_Beach" })
		table.insert(out, string.format("beacon->beach stairs %.1f -> %.1f", g0, g1))
	end
end

-- ===== VILLAGE BEACH =====
local V = Lib.folder("Village")
local mx, mz = -846, 748
local _, my = Lib.plaza(V, mx, mz, 22, { Name = "MarketSquare", Color = Color3.fromRGB(170, 160, 140), Material = M.Cobblestone })
stall(V, mx - 12, mz - 12, 200, Color3.fromRGB(60, 120, 200), "ShopStall")
local _, forgeAt = stall(V, mx + 12, mz - 12, 160, Color3.fromRGB(170, 70, 40), "CraftForge")
if forgeAt then
	local coals = Lib.part(V, { Name = "ForgeCoals", Size = Vector3.new(4, 1, 3), CFrame = forgeAt(0, 3.6, -1.2), Color = Color3.fromRGB(255, 110, 40), Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(coals, Color3.fromRGB(255, 130, 50), 0.8)
	Lib.light(coals, Color3.fromRGB(255, 120, 50), 22, 2, false)
	Lib.part(V, { Name = "Anvil", Size = Vector3.new(2.6, 1.6, 1.4), CFrame = forgeAt(-4, 4, 4.2), Color = Color3.fromRGB(60, 60, 66), Material = M.Metal })
end
-- campfire in the middle of the square
do
	for i = 0, 7 do
		local ang = math.rad(i * 45)
		Lib.part(V, { Name = "FireStone", Shape = BALL, Size = Vector3.new(1.6, 1.2, 1.6), Pos = Vector3.new(mx + math.sin(ang) * 2.6, my + 0.8, mz + 6 + math.cos(ang) * 2.6), Color = C.stoneDark, Material = M.Slate })
	end
	local fire = Lib.part(V, { Name = "Campfire", Size = Vector3.new(1.6, 1.2, 1.6), Pos = Vector3.new(mx, my + 1, mz + 6), Color = C.flame, Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(fire, nil, 1.4)
	Lib.light(fire, C.flameLight, 26, 2, true)
end
local huts = { { -930, 700, 30 }, { -900, 790, 120 }, { -790, 800, 200 }, { -955, 750, 80 }, { -760, 712, 250 }, { -880, 660, 10 } }
local nh = 0
for _, h in ipairs(huts) do if hut(V, h[1], h[2], h[3]) then nh += 1 end end
-- piers + boats on the west / south shore
local piers = 0
for _, p in ipairs({ { Vector3.new(-940, 0, 720), Vector3.new(-1060, 0, 720) }, { Vector3.new(-860, 0, 820), Vector3.new(-880, 0, 900) } }) do
	local shore = Lib.edge(p[1], p[2], 6, 0)
	if shore then
		local dir = (Vector3.new(p[2].X, 0, p[2].Z) - Vector3.new(p[1].X, 0, p[1].Z)).Unit
		local s0 = Vector3.new(shore.X, 6.2, shore.Z) - dir * 4
		local s1 = s0 + dir * 46
		Lib.beam(V, s0, s1, 7, 0.6, { Name = "PierDeck", Color = C.wood, Material = M.WoodPlanks })
		for k = 0, 46, 9 do
			local p0 = s0 + dir * k
			for _, sd in ipairs({ -1, 1 }) do
				local r = Vector3.new(-dir.Z, 0, dir.X) * sd * 3.2
				Lib.part(V, { Name = "PierPost", Size = Vector3.new(0.9, 10, 0.9), Pos = p0 + r - Vector3.new(0, 4, 0), Color = C.woodDark, Material = M.Wood })
			end
		end
		Lib.torch(V, s1 + Vector3.new(0, 0.3, 0), 5)
		boat(V, Vector3.new(s1.X, 3.6, s1.Z) + Vector3.new(-dir.Z, 0, dir.X) * 9 - dir * 8, math.deg(math.atan2(dir.X, dir.Z)))
		piers += 1
	end
end
table.insert(out, string.format("village: market at (%d, %.1f, %d), %d huts, %d piers", mx, my, mz, nh, piers))
Lib.path({ Vector3.new(mx, 0, mz + 22), Vector3.new(-780, 0, 820), Vector3.new(-700, 0, 880), Vector3.new(-640, 0, 915) }, 7)

-- ===== JUNGLE: stair chain + lookout tower + ruined arch =====
local J = Lib.folder("Jungle")
local chain = {
	{ "Stairs_Village_Step", Vector3.new(-800, 0, 716), Vector3.new(-800, 0, 630) },
	{ "Stairs_Step_Jungle", Vector3.new(-760, 0, 622), Vector3.new(-760, 0, 576) },
	{ "Stairs_Jungle_Plateau", Vector3.new(-706, 0, 470), Vector3.new(-636, 0, 470) },
	{ "Stairs_Jungle_Back", Vector3.new(-880, 0, 458), Vector3.new(-880, 0, 416) },
}
for _, s in ipairs(chain) do
	local g0, g1 = g(s[2].X, s[2].Z), g(s[3].X, s[3].Z)
	if g0 and g1 then
		Lib.stairs(J, Vector3.new(s[2].X, g0, s[2].Z), Vector3.new(s[3].X, g1, s[3].Z), 8, { Name = s[1] })
		table.insert(out, string.format("%s %.1f -> %.1f", s[1], g0, g1))
	else
		table.insert(out, s[1] .. " SKIPPED (no ground)")
	end
end
Lib.path({ Vector3.new(-760, 0, 576), Vector3.new(-740, 0, 520), Vector3.new(-706, 0, 470) }, 7)
Lib.path({ Vector3.new(-740, 0, 520), Vector3.new(-860, 0, 500), Vector3.new(-880, 0, 458) }, 6)
-- lookout tower
do
	local tx, tz = -900, 540
	local ty = g(tx, tz)
	if ty then
		local T = Lib.sub(J, "LookoutTower")
		for _, sx in ipairs({ -4, 4 }) do
			for _, sz in ipairs({ -4, 4 }) do
				Lib.part(T, { Name = "Leg", Size = Vector3.new(1.2, 30, 1.2), CFrame = CFrame.new(tx + sx, ty + 15, tz + sz) * CFrame.Angles(math.rad(-sz * 0.6), 0, math.rad(sx * 0.6)), Color = C.woodDark, Material = M.Wood })
			end
		end
		for _, hgt in ipairs({ 10, 20 }) do
			Lib.part(T, { Name = "Brace", Size = Vector3.new(9.4, 0.6, 0.6), Pos = Vector3.new(tx, ty + hgt, tz - 4), Color = C.wood, Material = M.Wood })
			Lib.part(T, { Name = "Brace", Size = Vector3.new(9.4, 0.6, 0.6), Pos = Vector3.new(tx, ty + hgt, tz + 4), Color = C.wood, Material = M.Wood })
		end
		Lib.part(T, { Name = "Deck", Size = Vector3.new(12, 0.8, 12), Pos = Vector3.new(tx, ty + 30, tz), Color = C.woodLight, Material = M.WoodPlanks })
		for _, s in ipairs({ -1, 1 }) do
			Lib.part(T, { Name = "Rail", Size = Vector3.new(12, 2.4, 0.5), Pos = Vector3.new(tx, ty + 31.6, tz + s * 5.8), Color = C.wood, Material = M.WoodPlanks })
			Lib.part(T, { Name = "Rail", Size = Vector3.new(0.5, 2.4, 12), Pos = Vector3.new(tx + s * 5.8, ty + 31.6, tz), Color = C.wood, Material = M.WoodPlanks })
			Lib.part(T, { Name = "Thatch", Size = Vector3.new(14, 0.8, 8), CFrame = CFrame.new(tx, ty + 38.5, tz + s * 3.2) * CFrame.Angles(math.rad(-s * 34), 0, 0), Color = C.thatch, Material = M.Grass })
		end
		for _, s in ipairs({ -1, 1 }) do
			for _, s2 in ipairs({ -1, 1 }) do
				Lib.part(T, { Name = "RoofPost", Size = Vector3.new(0.6, 6, 0.6), Pos = Vector3.new(tx + s * 5.5, ty + 33.4, tz + s2 * 5.5), Color = C.woodDark, Material = M.Wood })
			end
		end
		local beacon = Lib.part(T, { Name = "Signal", Size = Vector3.new(1.6, 1.4, 1.6), Pos = Vector3.new(tx, ty + 31.2, tz), Color = C.flame, Material = M.Neon, CanCollide = false, CastShadow = false })
		Lib.flame(beacon, nil, 1.2)
		Lib.light(beacon, C.flameLight, 34, 2, false)
		Lib.place(J, "BannerPole", tx + 10, tz + 6, 30, 1.2)
		table.insert(out, string.format("lookout tower at (%d, %.1f, %d)", tx, ty, tz))
	end
end
-- ruined arch on the back hill
do
	local rx, rz = -890, 380
	local ry = g(rx, rz)
	if ry then
		local R = Lib.sub(J, "RuinedArch")
		Lib.part(R, { Name = "ArchL", Size = Vector3.new(3.4, 20, 3.4), Pos = Vector3.new(rx - 8, ry + 9, rz), Color = C.stoneMid, Material = M.Cobblestone })
		Lib.part(R, { Name = "ArchR", Size = Vector3.new(3.4, 14, 3.4), Pos = Vector3.new(rx + 8, ry + 6, rz), Color = C.stoneMid, Material = M.Cobblestone })
		Lib.part(R, { Name = "Lintel", Size = Vector3.new(12, 3, 3.6), CFrame = CFrame.new(rx - 3, ry + 19.5, rz) * CFrame.Angles(0, 0, math.rad(-6)), Color = C.stoneMid, Material = M.Cobblestone })
		Lib.part(R, { Name = "Rubble", Size = Vector3.new(4, 2.4, 3.4), CFrame = CFrame.new(rx + 9, ry + 1, rz + 4) * CFrame.Angles(0.3, 0.6, 0.2), Color = C.stoneMid, Material = M.Cobblestone })
		Lib.place(J, "BannerPole", rx - 14, rz + 6, 10, 1.3)
		Lib.torch(R, Vector3.new(rx - 4, ry, rz + 6), 6)
		Lib.torch(R, Vector3.new(rx + 4, ry, rz + 6), 6)
	end
end
return table.concat(out, "\n")
