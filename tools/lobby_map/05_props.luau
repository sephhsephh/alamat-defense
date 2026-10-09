-- tools/lobby_map/05_props.luau (B134): AI-mesh props + landmarks. Anchors the AI protos, warms the beach sand, swaps
-- the village part-huts for AI_NipaHut (+ warm light), twin AI_Statue guardians at the temple forecourt, AI_Ship in
-- the east lagoon + one at sea (stern lanterns), volcano crater glow + smoke, lighthouse on the south sea stack.
-- Idempotent: re-running replaces everything it made. Run in execute_luau (Lobby, Edit).
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local CYL = Enum.PartType.Cylinder
local WATER_TOP = 4
local out = {}

for _, d in ipairs(game.ServerStorage.DevTools.LobbyMap.Protos:GetDescendants()) do
	if d:IsA("BasePart") then d.Anchored = true end
end
workspace.Terrain:SetMaterialColor(M.Sand, Color3.fromRGB(176, 154, 112))

local function warmLight(parent, cf, range, brightness)
	local p = Lib.part(parent, { Name = "LightHost", Size = Vector3.new(0.4, 0.4, 0.4), CFrame = cf, Transparency = 1, CanCollide = false, CastShadow = false })
	Lib.light(p, Color3.fromRGB(255, 170, 90), range, brightness, false)
	return p
end
-- clone a proto onto the water: scale, yaw, the hull sunk `sink` below the surface
local function float(parent, protoName, x, z, yaw, scale, sink)
	local proto = Lib.proto(protoName)
	if not proto then return nil end
	local c = proto:Clone() :: Model
	c:ScaleTo(c:GetScale() * scale)
	local bb, size = c:GetBoundingBox()
	local bottomOffset = (bb.Position.Y - size.Y / 2) - c:GetPivot().Position.Y
	c:PivotTo(CFrame.new(x, WATER_TOP - sink - bottomOffset, z) * CFrame.Angles(0, math.rad(yaw), 0))
	c.Parent = parent
	return c, size
end

-- ===== VILLAGE: AI nipa huts =====
local V = Lib.root():FindFirstChild("Village")
if V then
	for _, h in ipairs(V:GetChildren()) do
		if h.Name == "NipaHut" or h.Name == "NipaHutAI" then h:Destroy() end
	end
	local n = 0
	for _, h in ipairs({ { -930, 700, 30 }, { -900, 790, 120 }, { -790, 800, 200 }, { -955, 750, 80 }, { -760, 712, 250 }, { -880, 660, 10 } }) do
		local c = Lib.place(V, "AI_NipaHut", h[1], h[2], h[3], 0.85, 0.6)
		if c then
			c.Name = "NipaHutAI"
			local bb, size = (c :: Model):GetBoundingBox()
			warmLight(c, CFrame.new(bb.Position + Vector3.new(0, size.Y * 0.1, 0)), 16, 1.3)
			n += 1
		end
	end
	table.insert(out, "village: " .. n .. " AI nipa huts")
end

-- ===== TEMPLE: twin guardian statues on the forecourt =====
local T = Lib.root():FindFirstChild("Temple")
if T then
	for _, s in ipairs(T:GetChildren()) do
		if s.Name == "Guardian" or s.Name == "GuardianPlinth" or s.Name == "GuardianUplight" then s:Destroy() end
	end
	for _, sx in ipairs({ -1, 1 }) do
		local x, z = -420 + sx * 25, 398
		local gy = Lib.ground(x, z)
		if gy then
			Lib.part(T, { Name = "GuardianPlinth", Size = Vector3.new(11, 3, 9), Pos = Vector3.new(x, gy + 1, z), Color = C.stoneDark, Material = M.Slate })
			local st = Lib.place(T, "AI_Statue", x, z, 180, 1.2, 0)
			if st then
				st.Name = "Guardian"
				local cm = st :: Model
				cm:PivotTo(cm:GetPivot() + Vector3.new(0, 2.5, 0))
				local bb, size = cm:GetBoundingBox()
				local up = Lib.part(T, { Name = "GuardianUplight", Size = Vector3.new(0.6, 0.4, 0.6), Pos = Vector3.new(x, gy + 2.7, z + 5.5), Color = Color3.fromRGB(120, 190, 255), Material = M.Neon, CanCollide = false, CastShadow = false })
				local sl = Instance.new("SpotLight")
				sl.Face = Enum.NormalId.Top
				sl.Angle = 70
				sl.Range = size.Y + 6
				sl.Brightness = 2.2
				sl.Color = Color3.fromRGB(130, 190, 255)
				sl.Parent = up
				table.insert(out, string.format("guardian at (%d, %.1f, %d) h=%.1f", x, gy, z, size.Y))
			end
		end
	end
end

-- ===== SEA: ships =====
local S = Lib.folder("Sea")
for _, sh in ipairs({ { "LagoonShip", -115, 662, 115, 3.2 }, { "SeaShip", -470, 1075, 70, 2.2 } }) do
	local c, size = float(S, "AI_Ship", sh[2], sh[3], sh[4], sh[5], 5)
	if c then
		c.Name = sh[1]
		local bb = c:GetBoundingBox()
		warmLight(c, bb * CFrame.new(0, -size.Y * 0.15, size.Z * 0.42), 26, 1.6)
		warmLight(c, bb * CFrame.new(0, -size.Y * 0.15, -size.Z * 0.42), 20, 1.2)
		table.insert(out, string.format("%s at (%d, %d) size %.0fx%.0fx%.0f", sh[1], sh[2], sh[3], size.X, size.Y, size.Z))
	end
end

-- lighthouse on the south sea stack
do
	local best, bx, bz = -1, -252, 990
	for x = -290, -210, 4 do
		for z = 960, 1030, 4 do
			local y = Lib.ground(x, z)
			if y and y > best then best, bx, bz = y, x, z end
		end
	end
	if best > 0 then
		local L = Lib.sub(S, "Lighthouse")
		local white, red = Color3.fromRGB(226, 220, 206), Color3.fromRGB(170, 44, 40)
		Lib.part(L, { Name = "Footing", Shape = CYL, Size = Vector3.new(4, 16, 16), CFrame = CFrame.new(bx, best + 0.5, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = C.stoneDark, Material = M.Slate })
		for k = 0, 5 do
			local d = 11 - k * 0.8
			Lib.part(L, { Name = "Band", Shape = CYL, Size = Vector3.new(5, d, d), CFrame = CFrame.new(bx, best + 5 + k * 5, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = (k % 2 == 0) and white or red, Material = M.SmoothPlastic })
		end
		local top = best + 32.5
		Lib.part(L, { Name = "Gallery", Shape = CYL, Size = Vector3.new(1, 11, 11), CFrame = CFrame.new(bx, top, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 40, 46), Material = M.Metal })
		local lamp = Lib.part(L, { Name = "Lamp", Shape = CYL, Size = Vector3.new(4.5, 5, 5), CFrame = CFrame.new(bx, top + 2.7, bz) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 226, 150), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.1 })
		Lib.light(lamp, Color3.fromRGB(255, 220, 150), 60, 2.4, false)
		Lib.part(L, { Name = "Cap", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 5, 7), Pos = Vector3.new(bx, top + 6, bz), Color = red, Material = M.SmoothPlastic })
		table.insert(out, string.format("lighthouse at (%d, %.1f, %d)", bx, best, bz))
	end
end

-- ===== VOLCANO: crater glow + smoke =====
local Vo = Lib.folder("Volcano")
do
	local best, px, pz = -1, -36, -300
	for x = -90, 30, 3 do
		for z = -360, -240, 3 do
			local y = Lib.ground(x, z, 400)
			if y and y > best then best, px, pz = y, x, z end
		end
	end
	local glow = Lib.part(Vo, { Name = "CraterGlow", Shape = CYL, Size = Vector3.new(1.2, 26, 26), CFrame = CFrame.new(px, best + 1, pz) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 90, 30), Material = M.Neon, CanCollide = false, CastShadow = false, Transparency = 0.15 })
	Lib.light(glow, Color3.fromRGB(255, 100, 40), 80, 4, false)
	Lib.motes(glow, Color3.fromRGB(255, 140, 60), 8, 10)
	local sm = Instance.new("ParticleEmitter")
	sm.Texture = "rbxasset://textures/particles/smoke_main.dds"
	sm.Color = ColorSequence.new(Color3.fromRGB(150, 70, 50), Color3.fromRGB(40, 38, 46))
	sm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 40) })
	sm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	sm.Lifetime = NumberRange.new(8, 12)
	sm.Rate = 2
	sm.Speed = NumberRange.new(6, 9)
	sm.LightEmission = 0.2
	sm.Parent = glow
	-- lava rivulets down the near face
	for i = 0, 2 do
		local ang = math.rad(150 + i * 30)
		local a = Vector3.new(px + math.sin(ang) * 10, 0, pz + math.cos(ang) * 10)
		local b = Vector3.new(px + math.sin(ang) * 46, 0, pz + math.cos(ang) * 46)
		local ya, yb = Lib.ground(a.X, a.Z, 400), Lib.ground(b.X, b.Z, 400)
		if ya and yb then
			Lib.beam(Vo, Vector3.new(a.X, ya + 0.2, a.Z), Vector3.new(b.X, yb + 0.2, b.Z), 2.2 - i * 0.3, 0.4, { Name = "LavaFlow", Color = Color3.fromRGB(255, 80, 20), Material = M.Neon, CanCollide = false, CastShadow = false })
		end
	end
	table.insert(out, string.format("volcano crater at (%d, %.1f, %d)", px, best, pz))
end
return table.concat(out, "\n")
