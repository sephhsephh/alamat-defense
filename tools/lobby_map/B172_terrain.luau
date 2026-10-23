-- tools/lobby_map/B172_terrain.luau (B172) -- the "Holy Coast" lobby terrain: mainland coast to the north,
-- the spawn rotunda bay to the south, an arena isle east, the Sun Citadel mesa on the NE headland.
-- Terrain is only the FLOOR (docs/design/stylized-environment.md): flat tiers + beaches + a seabed;
-- every cliff face / wall / landmark is a mesh placed on top. Paste into execute_luau (Lobby, Edit),
-- set CHUNK = 1..CHUNKS and run once per chunk. The sea band (water Y -4..4) and water colours are kept.
-- Old terrain: ServerStorage._OldLobby_B139.Terrain_B139 (PasteRegion at its CornerCell attribute).
local CHUNK, CHUNKS = 1, 14
local T = workspace.Terrain
local M = Enum.Material

local X0, X1, Z0, Z1, Y0, Y1 = -1600, 1000, -1100, 1060, -40, 280
local PLAZA_C, PLAZA_R = Vector2.new(-300, 0), 178
local SPAWN_C = Vector2.new(-300, 420)
local ARENA_C, ARENA_R = Vector2.new(140, 400), 80
local MESA_C, MESA_R = Vector2.new(300, -330), 105
local MAIN_C, MAIN_R = Vector2.new(-300, -300), Vector2.new(1250, 760)

local function smooth(e0, e1, x)
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
local function lerp(a, b, t) return a + (b - a) * t end

-- inland is SMALLER z (north). coastZ(x) = the shoreline.
local function coastZ(x: number): number
	local base = 140
	if x < -1150 then base = 140 - (-1150 - x) * 1.2 end
	if x > 480 then base = 140 - (x - 480) * 1.6 end
	base += 30 * math.noise(x / 180, 1.7) + 12 * math.noise(x / 60, 3.1)
	local dx = x - PLAZA_C.X
	if math.abs(dx) < PLAZA_R then base = math.max(base, PLAZA_C.Y + math.sqrt(PLAZA_R * PLAZA_R - dx * dx)) end
	return base
end

-- returns surface height, top material (nil = no land here)
local function land(x: number, z: number): (number?, Enum.Material?)
	local p = Vector2.new(x, z)
	-- arena isle
	local da = (p - ARENA_C).Magnitude
	if da < ARENA_R then
		local h = lerp(10, 3, smooth(ARENA_R - 22, ARENA_R, da))
		return h, if da < ARENA_R - 22 then M.Grass else M.Sand
	end
	local cz = coastZ(x)
	if z > cz then return nil, nil end
	-- the mainland is a rounded ellipse; d = studs inland from the nearest shore (south coast or ellipse rim)
	local ex, ez = (x - MAIN_C.X) / MAIN_R.X, (z - MAIN_C.Y) / MAIN_R.Y
	local e = math.sqrt(ex * ex + ez * ez)
	if e >= 1 then return nil, nil end
	local d = math.min(cz - z, (1 - e) * MAIN_R.Y)
	local h, mat
	local dp = (p - PLAZA_C).Magnitude
	if dp <= PLAZA_R and z > -120 then
		return 40, M.Pavement
	end
	if d < 45 then
		h, mat = 4 + d * 0.12, M.Sand
	elseif d < 72 then
		h, mat = lerp(9.4, 40, smooth(45, 72, d)), M.Rock
	else
		h = 40 + 3 * math.noise(x / 90, z / 90, 0.4)
		mat = if math.noise(x / 70, z / 70, 9.1) > 0.15 then M.LeafyGrass else M.Grass
	end
	-- upper terrace behind the plaza (temple row)
	if math.abs(x - PLAZA_C.X) < 320 and z <= -120 then
		h = math.max(h, 60); mat = if z > -300 then M.Pavement else mat
	end
	-- inland rolling hills behind the temple terrace
	if z < -300 then
		local t = smooth(-300, -420, z)
		local hh = lerp(h, 64 + 26 * math.noise(x / 260, z / 260, 2.2) + 10 * math.noise(x / 80, z / 80, 5.5), t)
		if hh > h then h = hh end
	end
	-- THE END OF THE MAP: a mountain ridge around the land rim (giant rock meshes dress it)
	if e > 0.74 then
		local t = smooth(0.74, 0.93, e)
		local hr = lerp(h, 250 + 40 * math.noise(x / 300, z / 300, 7.7), t)
		if hr > h then h = hr; mat = if t > 0.55 then M.Rock else mat end
	end
	-- NE headland mesa (Sun Citadel)
	local dm = (p - MESA_C).Magnitude
	if dm < MESA_R + 30 then
		local hm = lerp(78, h, smooth(MESA_R - 15, MESA_R + 30, dm))
		if hm > h then h = hm; mat = if dm < MESA_R - 15 then M.Grass else M.Rock end
	end
	-- near any shore every raised tier falls away into the beach (no box walls at the rim)
	local cap = if d < 45 then 4 + d * 0.12 else 9.4 + (d - 45) * 3.2
	if h > cap then
		h = cap
		mat = if d < 45 then M.Sand else M.Rock
	end
	return h, mat
end

local function seabed(x: number, z: number): number
	local ex, ez = (x - MAIN_C.X) / MAIN_R.X, (z - MAIN_C.Y) / MAIN_R.Y
	local off = math.max(z - coastZ(x), (math.sqrt(ex * ex + ez * ez) - 1) * MAIN_R.Y)
	local near = math.min(off, (Vector2.new(x, z) - SPAWN_C).Magnitude - 60, (Vector2.new(x, z) - ARENA_C).Magnitude - ARENA_R)
	return lerp(-2, -34, smooth(20, 220, near))
end

local cols = (X1 - X0) / 4
local per = math.ceil(cols / CHUNKS)
local cx0 = X0 + (CHUNK - 1) * per * 4
local cx1 = math.min(X1, cx0 + per * 4)
local region = Region3.new(Vector3.new(cx0, Y0, Z0), Vector3.new(cx1, Y1, Z1)):ExpandToGrid(4)
local nx, ny, nz = (cx1 - cx0) / 4, (Y1 - Y0) / 4, (Z1 - Z0) / 4
local mats, occs = table.create(nx), table.create(nx)
for i = 1, nx do
	local x = cx0 + (i - 0.5) * 4
	local mi, oi = table.create(ny), table.create(ny)
	for j = 1, ny do mi[j] = table.create(nz, M.Air); oi[j] = table.create(nz, 0) end
	for k = 1, nz do
		local z = Z0 + (k - 0.5) * 4
		local h, top = land(x, z)
		local sb = seabed(x, z)
		local solidTop = h or sb
		for j = 1, ny do
			local yb = Y0 + (j - 1) * 4
			local occ = math.clamp((solidTop - yb) / 4, 0, 1)
			if occ > 0 then
				mi[j][k] = if h then (if solidTop - yb <= 4 then top else (if top == M.Pavement then M.Rock else top)) else M.Sand
				oi[j][k] = occ
			elseif yb < 4 then
				mi[j][k] = M.Water; oi[j][k] = 1
			end
		end
	end
	mats[i], occs[i] = mi, oi
end
T:WriteVoxels(region, 4, mats, occs)
return string.format("chunk %d/%d x %d..%d written (%dx%dx%d)", CHUNK, CHUNKS, cx0, cx1, nx, ny, nz)
