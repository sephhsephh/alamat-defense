-- tools/lobby_map/Lib.luau (B134) -- builder library for the Lobby island map (Workspace.Lobby.Map).
-- Deployed as ServerStorage.DevTools.LobbyMap.Lib. District scripts (tools/lobby_map/*.luau) require a
-- clone of it from execute_luau (Edit) and build into Workspace.Lobby.Map.<District>; re-running a district
-- clears and rebuilds only that district. Everything is plain anchored parts / clones of the archived props
-- in ServerStorage._OldLobby_B134, so the user can edit any piece in Studio afterwards.
-- NOTE: Workspace.Lobby must exist -- SettingsConfig.Place() detects the Lobby Place by it.

local Lib = {}

local T = workspace.Terrain
local SS = game:GetService("ServerStorage")

Lib.C = {
	stone = Color3.fromRGB(196, 184, 160), stoneDark = Color3.fromRGB(104, 98, 96), stoneMid = Color3.fromRGB(150, 140, 126),
	wood = Color3.fromRGB(112, 74, 46), woodDark = Color3.fromRGB(74, 48, 32), woodLight = Color3.fromRGB(150, 108, 68),
	gold = Color3.fromRGB(232, 186, 84), red = Color3.fromRGB(168, 40, 36), redDark = Color3.fromRGB(96, 24, 24),
	thatch = Color3.fromRGB(176, 146, 86), rope = Color3.fromRGB(150, 122, 82), cloth = Color3.fromRGB(70, 60, 140),
	flame = Color3.fromRGB(255, 170, 70), flameLight = Color3.fromRGB(255, 160, 80),
	blue = Color3.fromRGB(80, 170, 255), green = Color3.fromRGB(90, 255, 120), purple = Color3.fromRGB(190, 90, 255),
	crimson = Color3.fromRGB(255, 60, 50),
}
local M = Enum.Material

function Lib.root(): Folder
	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		lobby = Instance.new("Folder")
		lobby.Name = "Lobby"
		lobby.Parent = workspace
	end
	local map = lobby:FindFirstChild("Map")
	if not map then
		map = Instance.new("Folder")
		map.Name = "Map"
		map.Parent = lobby
	end
	return map
end

-- a fresh (cleared) district folder
function Lib.folder(name: string): Folder
	local root = Lib.root()
	local old = root:FindFirstChild(name)
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f
end

function Lib.sub(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
terrainOnly.FilterDescendantsInstances = { T }
terrainOnly.IgnoreWater = true

-- terrain surface height at (x, z) (nil = no land; water ignored)
function Lib.ground(x: number, z: number, fromY: number?): (number?, Enum.Material?)
	local r = workspace:Raycast(Vector3.new(x, fromY or 400, z), Vector3.new(0, -460, 0), terrainOnly)
	if r then return r.Position.Y, r.Material end
	return nil, nil
end

function Lib.part(parent: Instance, p: { [string]: any }): BasePart
	local cls = p.Class or "Part"
	local x = Instance.new(cls) :: BasePart
	x.Anchored = true
	x.TopSurface = Enum.SurfaceType.Smooth
	x.BottomSurface = Enum.SurfaceType.Smooth
	x.Material = p.Material or M.SmoothPlastic
	x.Color = p.Color or Lib.C.stone
	x.Size = p.Size or Vector3.new(4, 1, 4)
	x.CFrame = p.CFrame or CFrame.new(p.Pos or Vector3.zero)
	if p.Shape and x:IsA("Part") then (x :: Part).Shape = p.Shape end
	if p.CanCollide == false then x.CanCollide = false end
	if p.CastShadow == false then x.CastShadow = false end
	if p.Transparency then x.Transparency = p.Transparency end
	if p.Reflectance then x.Reflectance = p.Reflectance end
	x.Name = p.Name or "Part"
	x.Parent = parent
	return x
end

-- a cylinder between two points
function Lib.cyl(parent: Instance, a: Vector3, b: Vector3, d: number, p: { [string]: any }?): BasePart
	local q = p or {}
	local len = (b - a).Magnitude
	q.Shape = Enum.PartType.Cylinder
	q.Size = Vector3.new(len, d, d)
	q.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return Lib.part(parent, q)
end

-- a block spanning two points (a beam / rail / plank run)
function Lib.beam(parent: Instance, a: Vector3, b: Vector3, w: number, h: number, p: { [string]: any }?): BasePart
	local q = p or {}
	q.Size = Vector3.new(w, h, (b - a).Magnitude)
	q.CFrame = CFrame.lookAt((a + b) / 2, b)
	return Lib.part(parent, q)
end

function Lib.light(host: BasePart, color: Color3, range: number, brightness: number, shadows: boolean?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = shadows == true
	l.Parent = host
	return l
end

-- flickering flame particles (built-in fire texture)
function Lib.flame(host: BasePart, color: Color3?, size: number?)
	local s = size or 1
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/fire_main.dds"
	e.Color = ColorSequence.new(color or Lib.C.flame, Color3.fromRGB(255, 80, 30))
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2 * s), NumberSequenceKeypoint.new(1, 0.1) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Rate = 18
	e.Speed = NumberRange.new(2 * s, 4 * s)
	e.SpreadAngle = Vector2.new(8, 8)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = host
	return e
end

-- glowing motes rising (beacons / shrines)
function Lib.motes(host: BasePart, color: Color3, rate: number?, speed: number?)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(2, 4)
	e.Rate = rate or 10
	e.Speed = NumberRange.new(speed or 4, (speed or 4) * 2)
	e.SpreadAngle = Vector2.new(25, 25)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = host
	return e
end

-- a standing torch (wooden pole + iron cup + flame + warm light); pos = ground point
function Lib.torch(parent: Instance, pos: Vector3, h: number?, lightOn: boolean?): Model
	local m = Lib.sub(parent, "Torch")
	local H = h or 7
	Lib.part(m, { Name = "Pole", Size = Vector3.new(0.7, H, 0.7), Pos = pos + Vector3.new(0, H / 2, 0), Color = Lib.C.woodDark, Material = M.Wood, CastShadow = false })
	Lib.part(m, { Name = "Cup", Size = Vector3.new(1.6, 0.8, 1.6), Pos = pos + Vector3.new(0, H + 0.2, 0), Color = Color3.fromRGB(50, 46, 44), Material = M.Metal, CastShadow = false })
	local f = Lib.part(m, { Name = "Flame", Size = Vector3.new(0.9, 1.1, 0.9), Pos = pos + Vector3.new(0, H + 1, 0), Color = Lib.C.flame, Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.flame(f, nil, 0.8)
	if lightOn ~= false then Lib.light(f, Lib.C.flameLight, 20, 1.6, false) end
	return m
end

-- prototype from the archive (first match by name, recursive)
function Lib.proto(name: string): Instance?
	local protos = SS:FindFirstChild("DevTools") and SS.DevTools:FindFirstChild("LobbyMap") and SS.DevTools.LobbyMap:FindFirstChild("Protos")
	local p = protos and protos:FindFirstChild(name)
	if p then return p end
	local arch = SS:FindFirstChild("_OldLobby_B134")
	return arch and arch:FindFirstChild(name, true) or nil
end

local function stripScripts(x: Instance)
	for _, d in ipairs(x:GetDescendants()) do
		if d:IsA("LuaSourceContainer") then d:Destroy() end
	end
end

-- clone a prop and stand it on the ground at (x, z): yaw in degrees, optional uniform scale
function Lib.place(parent: Instance, protoName: string, x: number, z: number, yaw: number?, scale: number?, sink: number?): Instance?
	local proto = Lib.proto(protoName)
	if not proto then return nil end
	local gy = Lib.ground(x, z)
	if not gy then return nil end
	local c = proto:Clone()
	stripScripts(c)
	if c:IsA("Model") then
		local cm = c :: Model
		if scale and scale ~= 1 then pcall(function() cm:ScaleTo(cm:GetScale() * scale) end) end
		local cf, size = cm:GetBoundingBox()
		local pivot = cm:GetPivot()
		local bottomOffset = (cf.Position.Y - size.Y / 2) - pivot.Position.Y
		local rot = CFrame.Angles(0, math.rad(yaw or 0), 0)
		cm:PivotTo(CFrame.new(x, gy - bottomOffset - (sink or 0.5), z) * rot)
	elseif c:IsA("BasePart") then
		if scale and scale ~= 1 then c.Size *= scale end
		c.CFrame = CFrame.new(x, gy + c.Size.Y / 2 - (sink or 0.5), z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	end
	c.Parent = parent
	return c
end

-- carve air (for stairs cut into a cliff)
function Lib.carve(cf: CFrame, size: Vector3)
	T:FillBlock(cf, size, M.Air)
end

-- repaint the terrain surface along a polyline (a footpath): grass -> material
function Lib.path(points: { Vector3 }, width: number, mat: Enum.Material?)
	local m = mat or M.Sandstone
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local d = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z))
		local steps = math.max(1, math.floor(d.Magnitude / 3))
		for s = 0, steps do
			local p = a:Lerp(b, s / steps)
			local gy = Lib.ground(p.X, p.Z)
			if gy then
				local reg = Region3.new(Vector3.new(p.X - width / 2, gy - 6, p.Z - width / 2), Vector3.new(p.X + width / 2, gy + 2, p.Z + width / 2)):ExpandToGrid(4)
				T:ReplaceMaterial(reg, 4, M.Grass, m)
				T:ReplaceMaterial(reg, 4, M.LeafyGrass, m)
			end
		end
	end
end

-- stone stairs from a (bottom, on the ground) to b (top, on the ground); terrain above the flight is carved
function Lib.stairs(parent: Instance, a: Vector3, b: Vector3, width: number, opts: { [string]: any }?): Model
	local o = opts or {}
	local m = Lib.sub(parent, o.Name or "Stairs")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local run = flat.Magnitude
	local rise = b.Y - a.Y
	local n = math.max(2, math.ceil(math.abs(rise) / (o.Step or 1.25)))
	local dir = flat.Unit
	local look = CFrame.lookAt(Vector3.zero, dir)
	local stepRun = run / n
	-- carve a clean notch first (only above the flight)
	if o.Carve ~= false then
		for i = 0, n, 2 do
			local p = a + dir * (stepRun * i) + Vector3.new(0, rise * i / n, 0)
			Lib.carve(CFrame.new(p + Vector3.new(0, 9, 0)) * look, Vector3.new(width + 4, 16, stepRun * 2 + 2))
		end
	end
	for i = 1, n do
		local p = a + dir * (stepRun * (i - 0.5)) + Vector3.new(0, rise * i / n, 0)
		local h = math.max(1.2, rise * i / n + 6)
		Lib.part(m, { Name = "Step", Size = Vector3.new(width, h, stepRun + 0.05), CFrame = CFrame.new(p - Vector3.new(0, h / 2, 0)) * look,
			Color = o.Color or Color3.fromRGB(140, 128, 110), Material = o.Material or M.Limestone })
	end
	-- side walls with torches at both ends
	if o.Walls ~= false then
		for _, side in ipairs({ -1, 1 }) do
			local off = look.RightVector * side * (width / 2 + 0.6)
			Lib.beam(m, a + off + Vector3.new(0, 1.2, 0), b + off + Vector3.new(0, 1.2, 0), 1.2, 2.4, { Name = "Wall", Color = Lib.C.stoneDark, Material = M.Slate })
		end
	end
	if o.Torches ~= false then
		for _, side in ipairs({ -1, 1 }) do
			local off = look.RightVector * side * (width / 2 + 1.8)
			Lib.torch(m, a + off, 6)
			Lib.torch(m, b + off, 6)
		end
	end
	return m
end

-- a wooden rope bridge from a to b (ground points); sags in the middle, rope rails, posts, stone piers if long
function Lib.bridge(parent: Instance, a: Vector3, b: Vector3, width: number?, opts: { [string]: any }?): Model
	local o = opts or {}
	local W = width or 8
	local m = Lib.sub(parent, o.Name or "Bridge")
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = flat.Magnitude
	local dir = flat.Unit
	local right = Vector3.new(-dir.Z, 0, dir.X)
	local sag = o.Sag or math.min(4, len / 30)
	local n = math.max(4, math.floor(len / 2.2))
	local function at(t: number): Vector3
		local p = a:Lerp(b, t)
		return p - Vector3.new(0, sag * 4 * t * (1 - t), 0)
	end
	for i = 0, n - 1 do
		local p0, p1 = at(i / n), at((i + 1) / n)
		local mid = (p0 + p1) / 2
		local plank = Lib.part(m, { Name = "Plank", Size = Vector3.new(W, 0.6, (p1 - p0).Magnitude * 0.92), CFrame = CFrame.lookAt(mid, mid + (p1 - p0)),
			Color = (i % 3 == 0) and Lib.C.woodLight or Lib.C.wood, Material = M.WoodPlanks })
		plank.CastShadow = true
	end
	-- side stringers (walkable edge) + rope rails on posts
	local posts = math.max(2, math.floor(len / 10))
	for _, side in ipairs({ -1, 1 }) do
		local prevTop: Vector3? = nil
		for k = 0, posts do
			local t = k / posts
			local base = at(t) + right * side * (W / 2 - 0.3)
			local top = base + Vector3.new(0, 3.6, 0)
			Lib.part(m, { Name = "Post", Size = Vector3.new(0.6, 4.2, 0.6), Pos = base + Vector3.new(0, 1.6, 0), Color = Lib.C.woodDark, Material = M.Wood, CastShadow = false })
			if prevTop then Lib.cyl(m, prevTop, top, 0.25, { Name = "Rope", Color = Lib.C.rope, Material = M.Fabric, CanCollide = false, CastShadow = false }) end
			prevTop = top
		end
		-- invisible guard rail so nobody walks off the side
		Lib.beam(m, a + right * side * (W / 2) + Vector3.new(0, 2.5, 0), b + right * side * (W / 2) + Vector3.new(0, 2.5, 0), 0.4, 5,
			{ Name = "Guard", Transparency = 1, CastShadow = false })
	end
	-- stone piers down to the water for long spans
	if len > 70 and o.Piers ~= false then
		local count = math.floor(len / 60)
		for k = 1, count do
			local t = k / (count + 1)
			local p = at(t)
			local h = p.Y + 6
			Lib.part(m, { Name = "Pier", Size = Vector3.new(W + 2, h, 6), CFrame = CFrame.lookAt(p - Vector3.new(0, h / 2 + 0.4, 0), p - Vector3.new(0, h / 2 + 0.4, 0) + dir),
				Color = Lib.C.stoneDark, Material = M.Slate })
		end
	end
	-- torches at both ends
	if o.Torches ~= false then
		for _, side in ipairs({ -1, 1 }) do
			Lib.torch(m, a - dir * 1.5 + right * side * (W / 2 + 1.5), 7)
			Lib.torch(m, b + dir * 1.5 + right * side * (W / 2 + 1.5), 7)
		end
	end
	return m
end

-- walk from a toward b over land; returns the last land point before the ground drops by more than `drop`
function Lib.edge(a: Vector3, b: Vector3, drop: number?, inset: number?): Vector3?
	local d = drop or 6
	local startY = Lib.ground(a.X, a.Z)
	if not startY then return nil end
	local flat = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dir = flat.Unit
	local last = Vector3.new(a.X, startY, a.Z)
	for s = 2, flat.Magnitude, 2 do
		local p = a + dir * s
		local gy = Lib.ground(p.X, p.Z)
		if not gy or gy < startY - d or gy > startY + d then break end
		last = Vector3.new(p.X, gy, p.Z)
	end
	return last - dir * (inset or 3)
end

-- seat a round plaza (radius r, surface `top`) cleanly in the terrain: carve a shallow bowl -- 2 studs under it inside r + 2
-- (smooth-terrain rounding otherwise pokes ~1 stud through the rim), rising 0.22 per stud to the natural ground by r + 14 --
-- and turn the grass under it to Ground (terrain decoration blades grow straight through parts)
function Lib.seat(x: number, z: number, r: number, top: number)
	local T = workspace.Terrain
	for rr = r + 14, r + 2, -2 do
		local cut = if rr == r + 2 then top - 2.3 else top - 0.3 + (rr - (r + 2)) * 0.22
		T:FillCylinder(CFrame.new(x, cut + 10, z), 20, rr, M.Air)
	end
	local region = Region3.new(Vector3.new(x - r - 6, top - 14, z - r - 6), Vector3.new(x + r + 6, top + 10, z + r + 6)):ExpandToGrid(4)
	local mats, occ = T:ReadVoxels(region, 4)
	local minC = region.CFrame.Position - region.Size / 2
	for i = 1, mats.Size.X do
		for j = 1, mats.Size.Y do
			for k = 1, mats.Size.Z do
				local d = (Vector2.new(minC.X + (i - 0.5) * 4, minC.Z + (k - 0.5) * 4) - Vector2.new(x, z)).Magnitude
				local mat = mats[i][j][k]
				if d <= r + 2 and (mat == M.Grass or mat == M.LeafyGrass) then mats[i][j][k] = M.Ground end
			end
		end
	end
	T:WriteVoxels(region, 4, mats, occ)
end

-- a round paved plaza (cylinder disc + rim) flush with the ground at (x, z); seated in the terrain unless NoSeat
function Lib.plaza(parent: Instance, x: number, z: number, r: number, opts: { [string]: any }?): Model
	local o = opts or {}
	local m = Lib.sub(parent, o.Name or "Plaza")
	local gy = o.Y or Lib.ground(x, z) or 0
	if not o.NoSeat then Lib.seat(x, z, r, gy + 0.4) end
	Lib.part(m, { Name = "Floor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, r * 2, r * 2),
		CFrame = CFrame.new(x, gy - 1.6, z) * CFrame.Angles(0, 0, math.rad(90)), Color = o.Color or Lib.C.stone, Material = o.Material or M.Limestone })
	Lib.part(m, { Name = "Rim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4.4, r * 2 + 3, r * 2 + 3),
		CFrame = CFrame.new(x, gy - 1.9, z) * CFrame.Angles(0, 0, math.rad(90)), Color = o.RimColor or Lib.C.stoneDark, Material = M.Slate })
	return m, gy
end

local noTerrain = OverlapParams.new()
noTerrain.FilterType = Enum.RaycastFilterType.Exclude
noTerrain.FilterDescendantsInstances = { workspace.Terrain }

-- scatter archived props in a ring/area (min spacing), skipping water / steep spots
function Lib.scatter(parent: Instance, names: { string }, cx: number, cz: number, radius: number, count: number, opts: { [string]: any }?): number
	local o = opts or {}
	local rng = Random.new(o.Seed or 7)
	local placed = {}
	local n = 0
	for _ = 1, count * 6 do
		if n >= count then break end
		local ang = rng:NextNumber(0, math.pi * 2)
		local dist = (o.MinR or 0) + rng:NextNumber() * (radius - (o.MinR or 0))
		local x, z = cx + math.cos(ang) * dist, cz + math.sin(ang) * dist
		local ok = true
		for _, q in ipairs(placed) do
			if (q - Vector2.new(x, z)).Magnitude < (o.Spacing or 14) then ok = false break end
		end
		for _, av in ipairs(o.Avoid or {}) do
			if (Vector2.new(av.X, av.Z) - Vector2.new(x, z)).Magnitude < (av.R or 20) then ok = false break end
		end
		local gy, gm = nil, nil
		if ok then gy, gm = Lib.ground(x, z) end
		-- o.Mats: allowed ground materials (keeps props off the paved paths); o.Clear: no built part within this radius
		if gy and o.Mats and not o.Mats[gm] then gy = nil end
		if gy and o.Clear and #workspace:GetPartBoundsInRadius(Vector3.new(x, gy + 4, z), o.Clear, noTerrain) > 0 then gy = nil end
		if gy and (not o.MinY or gy > o.MinY) and (not o.MaxY or gy < o.MaxY) then
			-- flat enough? (sample 4 neighbours)
			local flatOk = true
			for _, off in ipairs({ Vector2.new(4, 0), Vector2.new(-4, 0), Vector2.new(0, 4), Vector2.new(0, -4) }) do
				local g2 = Lib.ground(x + off.X, z + off.Y)
				if not g2 or math.abs(g2 - gy) > (o.MaxSlope or 3) then flatOk = false break end
			end
			if flatOk then
				local name = names[rng:NextInteger(1, #names)]
				local s = (o.ScaleMin or 0.8) + rng:NextNumber() * ((o.ScaleMax or 1.15) - (o.ScaleMin or 0.8))
				if Lib.place(parent, name, x, z, rng:NextNumber(0, 360), s) then
					table.insert(placed, Vector2.new(x, z))
					n += 1
				end
			end
		end
	end
	return n
end

return Lib
