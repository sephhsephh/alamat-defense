-- tools/lobby_map/06_nature.luau (B134): vegetation + rocks + bushes + fireflies per region. Uses Lib.scatter with
-- Clear (no built part nearby) + Mats (never on the paved Sandstone paths). Idempotent (Lib.folder clears "Nature").
-- Palms are heavy (58-118 parts each) so they stay on beaches / the two low islands; trees + rocks are 2 parts each.
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local M = Enum.Material
local N = Lib.folder("Nature")
local out = {}

-- bush protos (3 overlapping leafy balls), created once in Protos
local protos = game.ServerStorage.DevTools.LobbyMap.Protos
for i, tint in ipairs({ Color3.fromRGB(58, 102, 52), Color3.fromRGB(72, 116, 58) }) do
	local name = "Bush" .. i
	if not protos:FindFirstChild(name) then
		local m = Instance.new("Model")
		m.Name = name
		for k, o in ipairs({ { 0, 1.6, 0, 4.4 }, { 2, 1.2, 1, 3.4 }, { -1.8, 1.1, -0.8, 3.2 } }) do
			local p = Instance.new("Part")
			p.Name = "Leaf" .. k
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(o[4], o[4] * 0.8, o[4])
			p.Position = Vector3.new(o[1], o[2], o[3])
			p.Color = tint
			p.Material = M.LeafyGrass
			p.Anchored = true
			p.CanCollide = false
			p.CastShadow = false
			p.Parent = m
		end
		m.WorldPivot = CFrame.new(0, 0, 0)
		m.Parent = protos
	end
end

local GRASS = { [M.Grass] = true, [M.LeafyGrass] = true, [M.Ground] = true, [M.Mud] = true }
local BEACH = { [M.Sand] = true, [M.Grass] = true, [M.LeafyGrass] = true }
local PALMS = { "Palm tree", "Trimmed Palm Tree", "Palm tree", "Tall Palm tree" }
local TREES = { "Tree_01", "Tree_02", "Tree_03", "Tree_04", "Tree_09", "Tree_17", "Tree_18" }
local ROCKS = { "SM_Rocks_01", "SM_Rocks_02", "SM_Rocks_07", "Rock_Preset_01", "Rock_Preset_04" }
local BUSH = { "Bush1", "Bush2" }

-- name, cx, cz, radius, minY, maxY, layers { names, count, scaleMin, scaleMax, spacing, clear, mats, minR, avoid }
local regions = {
	{ "FrontIsland", -330, 790, 175, 70, 125, {
		{ PALMS, 9, 0.42, 0.58, 30, 9, GRASS, 46 },
		{ TREES, 8, 0.38, 0.5, 24, 9, GRASS, 46 },
		{ ROCKS, 6, 0.12, 0.22, 20, 6, GRASS, 40 },
		{ BUSH, 22, 0.9, 1.4, 9, 4, GRASS, 40 } } },
	{ "AltarIsland", -330, 545, 135, 95, 145, {
		{ TREES, 12, 0.42, 0.58, 24, 9, GRASS, 36 },
		{ ROCKS, 6, 0.12, 0.25, 20, 6, GRASS, 32 },
		{ BUSH, 18, 0.9, 1.4, 9, 4, GRASS, 32 } } },
	{ "TemplePlateau", -480, 410, 170, 158, 245, {
		{ TREES, 14, 0.48, 0.66, 24, 10, GRASS, 0, { { X = -420, Z = 362, R = 58 }, { X = -560, Z = 462, R = 30 }, { X = -461, Z = 548, R = 22 } } },
		{ ROCKS, 8, 0.14, 0.3, 20, 6, GRASS, 0, { { X = -420, Z = 362, R = 50 } } },
		{ BUSH, 20, 1, 1.5, 9, 4, GRASS, 0, { { X = -420, Z = 362, R = 50 } } } } },
	{ "WestJungle", -850, 430, 210, 105, 205, {
		{ TREES, 38, 0.5, 0.78, 17, 8, GRASS, 0 },
		{ ROCKS, 12, 0.14, 0.32, 18, 6, GRASS, 0 },
		{ BUSH, 40, 1, 1.7, 8, 3, GRASS, 0 } } },
	{ "VillageBeach", -860, 800, 175, 4, 45, {
		{ PALMS, 11, 0.42, 0.6, 28, 12, BEACH, 30 },
		{ ROCKS, 6, 0.1, 0.2, 16, 6, BEACH, 30 },
		{ BUSH, 14, 0.9, 1.3, 9, 5, BEACH, 30 } } },
	{ "RedGate", 180, 640, 290, 112, 150, {
		{ TREES, 16, 0.44, 0.6, 26, 12, GRASS, 0 },
		{ ROCKS, 8, 0.14, 0.28, 20, 6, GRASS, 0 },
		{ BUSH, 18, 0.9, 1.4, 9, 4, GRASS, 0 } } },
	{ "PurpleIsle", 300, 385, 115, 128, 175, {
		{ { "Tree_09", "Tree_17", "Tree_03" }, 7, 0.4, 0.52, 22, 10, GRASS, 24 },
		{ ROCKS, 6, 0.12, 0.24, 18, 6, GRASS, 22 },
		{ BUSH, 10, 0.9, 1.3, 9, 4, GRASS, 22 } } },
	{ "ArenaIsle", 40, 830, 135, 80, 114, {
		{ { "Palm tree", "Trimmed Palm Tree" }, 6, 0.42, 0.55, 26, 10, GRASS, 34 },
		{ ROCKS, 5, 0.12, 0.22, 18, 6, GRASS, 32 },
		{ BUSH, 12, 0.9, 1.3, 9, 4, GRASS, 32 } } },
	{ "SouthBeach", -700, 900, 95, 4, 40, {
		{ { "Palm tree", "Trimmed Palm Tree", "Tall Palm tree" }, 7, 0.42, 0.58, 26, 10, BEACH, 0 },
		{ { "SM_Rocks_01", "SM_Rocks_02", "Rock_Preset_01" }, 5, 0.1, 0.2, 16, 6, BEACH, 0 } } },
}
local seed = 100
for _, r in ipairs(regions) do
	local F = Lib.sub(N, r[1])
	local counts = {}
	for _, L in ipairs(r[7]) do
		seed += 1
		local n = Lib.scatter(F, L[1], r[2], r[3], r[4], L[2], { Seed = seed, MinY = r[5], MaxY = r[6], ScaleMin = L[3], ScaleMax = L[4], Spacing = L[5], Clear = L[6], Mats = L[7], MinR = L[8], Avoid = L[9], MaxSlope = 3.5 })
		table.insert(counts, n .. "/" .. L[2])
	end
	table.insert(out, r[1] .. ": " .. table.concat(counts, " "))
end

-- fireflies (night mood): slow warm-green sparkles drifting over the jungle, the village and the temple garden
local FF = Lib.sub(N, "Fireflies")
for _, f in ipairs({ { -850, 430, 60 }, { -780, 520, 50 }, { -930, 330, 50 }, { -860, 760, 55 }, { -480, 450, 50 }, { -330, 560, 40 }, { -330, 800, 45 } }) do
	local gy = Lib.ground(f[1], f[2])
	if gy then
		local host = Lib.part(FF, { Name = "FireflyCloud", Size = Vector3.new(f[3] * 2, 10, f[3] * 2), Pos = Vector3.new(f[1], gy + 8, f[2]), Transparency = 1, CanCollide = false, CastShadow = false })
		host.CanQuery = false
		host.CanTouch = false
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(220, 255, 140))
		e.LightEmission = 1
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.8, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Lifetime = NumberRange.new(4, 7)
		e.Rate = 6
		e.Speed = NumberRange.new(0.4, 1.2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.RotSpeed = NumberRange.new(-30, 30)
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = host
	end
end

-- the archived rocks read pale blue-white under the moon: textured ones become dark slate, SurfaceAppearance ones tinted
for _, d in ipairs(N:GetDescendants()) do
	if d:IsA("MeshPart") and (d.Name:find("Rock") or (d.Parent and d.Parent.Name:find("Rock"))) then
		if d.TextureID ~= "" then
			d.TextureID = ""
			d.Material = M.Slate
			d.Color = Color3.fromRGB(112, 106, 102)
		else
			local sa = d:FindFirstChildOfClass("SurfaceAppearance")
			if sa then pcall(function() sa.Color = Color3.fromRGB(150, 144, 138) end) end
		end
	end
end

local parts = 0
for _, d in ipairs(N:GetDescendants()) do if d:IsA("BasePart") then parts += 1 end end
table.insert(out, "nature parts: " .. parts)
return table.concat(out, "\n")
