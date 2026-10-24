-- tools/lobby_map/B172_city.luau (B172 phase 5) -- LUMINA, the holy city west of the plaza: a PLANNED layout (user: "arrange
-- them like a real city ... think like an actual architect ... create actual paths ... cool paths").
-- Paste into execute_luau (Lobby, Edit). SECTIONS = list of "clear" | "roads" | "landmarks" | "rows" | "street" (in order;
-- each is re-runnable: it owns Map.City.<Section> and rebuilds it).
--
-- PLAN (world studs, north = -Z; ground ~41 on the plain, hills rise north of z -300):
--   Sun Road      boulevard w36, plaza west rim (-470,-40) -> Sanctum Circus east (-822,-102); arch at its plaza end.
--   Sanctum Circus ring road r115 w24 round the Star Sanctum (-940,-120).
--   Gate Avenue   w32 processional, circus west (-1055,-135) -> Story Gate (-1420,-200); obelisks + lamps.
--   Pilgrim Way   w22 N-S street x -760 from the promenade (z 95) up to the Pagoda Terrace (-760,-500); arch at Sun Road.
--   Harbor Street w22 along z 25 from (-1380,25) to the circus south (-990,-8).
--   Promenade     w18 along the shore (z ~90) from the west lighthouse to Pilgrim Way.
--   Lanes         Observatory Lane (Pagoda Terrace -> observatory), Garden Lane (avenue -> stupa garden).
--   Civic Square  (Pavement) x -725..-575, z -45..78: city fountain centre, clock tower NW, market hall E side,
--                 the Moon Shrine (TraitReroll station + keeper) moved to its S side.
--   Temple Hill   library (W-facing) + bathhouse (E-facing) on Pilgrim Way north; Pagoda Terrace + observatory.
--   Garden Quarter stupas between Gate Avenue and the aqueduct (z -345).  Harbor Ward = row houses + bahay na bato.
local SECTIONS = { "clear", "roads" } -- then { "landmarks", "rows", "street" }

local CS = game:GetService("CollectionService")
local Map = workspace.Lobby.Map
local St = Map.Structures
local Kit = game.ServerStorage.DevTools.LobbyMap.B172Protos.Kit
local M = Enum.Material

local rpT = RaycastParams.new()
rpT.FilterType = Enum.RaycastFilterType.Include
rpT.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): (number, Enum.Material?)
	local r = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -900, 0), rpT)
	return if r then r.Position.Y else -99, if r then r.Material else nil
end
local function V2(x: number, z: number) return Vector2.new(x, z) end

local CITY = Map:FindFirstChild("City") or Instance.new("Folder")
CITY.Name = "City"; CITY.Parent = Map
local function folder(name: string): Folder
	local f = CITY:FindFirstChild(name); if f then f:Destroy() end
	f = Instance.new("Folder"); f.Name = name; f.Parent = CITY
	return f :: Folder
end

-- ===================================================================== the plan (data)
local ROADS = {
	{ name = "SunRoad", w = 36, mat = M.Cobblestone, pts = { V2(-470, -40), V2(-822, -102) } },
	{ name = "GateAvenue", w = 32, mat = M.Cobblestone, pts = { V2(-1055, -135), V2(-1420, -200) } },
	{ name = "PilgrimWay", w = 22, mat = M.Cobblestone, pts = { V2(-760, 92), V2(-760, -460) } },
	{ name = "HarborStreet", w = 22, mat = M.Cobblestone, pts = { V2(-1380, 25), V2(-1035, 25), V2(-990, -8) } },
	{ name = "Promenade", w = 18, mat = M.Pavement, pts = { V2(-1600, 96), V2(-1300, 90), V2(-1000, 90), V2(-771, 92) } },
	{ name = "ObservatoryLane", w = 14, mat = M.Cobblestone, pts = { V2(-790, -520), V2(-905, -560) } },
	{ name = "GardenLane", w = 14, mat = M.Cobblestone, pts = { V2(-1235, -170), V2(-1235, -250) } },
}
local RING = { c = V2(-940, -120), r = 115, w = 24, mat = M.Cobblestone }
local SQUARES = {
	{ name = "CivicSquare", rect = { V2(-725, -45), V2(-575, 78) }, mat = M.Pavement },
	{ name = "PagodaTerrace", circle = { V2(-760, -520), 58 }, mat = M.Pavement },
}
-- landmark = { kit piece, x, z, scale, facing (world dir the FRONT looks at), name }
local LANDMARKS = {
	{ "AL_ClockTower", -705, -28, 1.3, V2(1, 0.3), "ClockTower" },
	{ "AL_CityFountain", -650, 18, 1.4, V2(0, -1), "Fountain" },
	{ "AL_MarketHall", -548, 16, 1.2, V2(-1, 0), "MarketHall" },
	{ "AL_Library", -688, -250, 1.3, V2(-1, 0), "Library" },
	{ "AL_Bathhouse", -838, -262, 1.25, V2(1, 0), "Bathhouse" },
	{ "AL_Pagoda", -700, -538, 1.6, V2(-0.6, 1), "PagodaE" },
	{ "AL_Pagoda", -820, -538, 1.6, V2(0.6, 1), "PagodaW" },
	{ "AL_Pagoda", -760, -598, 1.7, V2(0, 1), "PagodaN" },
	{ "AL_Observatory", -935, -575, 1.6, V2(1, 0.4), "Observatory" },
	{ "AL_Stupa", -1340, -292, 1.5, V2(0, 1), "StupaW" },
	{ "AL_Stupa", -1235, -285, 1.6, V2(0, 1), "StupaC" },
	{ "AL_Stupa", -1130, -278, 1.5, V2(0, 1), "StupaE" },
	{ "AL_CornerHouse", -800, -40, 1.4, V2(0.5, -1), "CornerSunPilgrimSW" },
	{ "AL_CornerHouse", -1090, -95, 1.4, V2(0.2, -1), "CornerAvenueS" },
}
-- arches: { x, z, scale, along (street direction) }
local ARCHES = {
	{ -505, -46, 1.15, V2(-350, -62) },   -- Sun Road, at the plaza
	{ -760, -150, 0.8, V2(0, -1) },       -- Pilgrim Way, leaving Sun Road for Temple Hill
	{ -1085, -140, 1.05, V2(-365, -65) }, -- Gate Avenue, leaving the circus
}
-- streets lined with buildings: { road name, segment index, sides, skip zones {center, r} }
local ROWS = {
	{ "SunRoad", 1, { 1, -1 } },
	{ "PilgrimWay", 1, { 1, -1 } },
	{ "HarborStreet", 1, { 1, -1 } },
}
-- never build here (centre, radius): squares, landmarks, circus, stations, the plaza, the temple terrace stairs
local KEEP = {
	{ V2(-650, 16), 95 }, { V2(-940, -120), 132 }, { V2(-300, 0), 200 }, { V2(-520, -125), 40 }, { V2(-490, -25), 40 },
	{ V2(-1500, -200), 120 }, { V2(-760, -520), 75 },
}
local MOON_FROM, MOON_TO, MOON_FACE = Vector3.new(-700, 0, -110), V2(-650, 64), V2(0, -1) -- the Moon Shrine moves

-- ===================================================================== geometry helpers
local function segDist(p: Vector2, a: Vector2, b: Vector2): (number, number)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude, t
end
local function roadDist(p: Vector2): (number, any)
	local best, which = math.huge, nil
	for _, r in ipairs(ROADS) do
		for i = 1, #r.pts - 1 do
			local d = segDist(p, r.pts[i], r.pts[i + 1]) - r.w / 2
			if d < best then best, which = d, r end
		end
	end
	local dr = math.abs((p - RING.c).Magnitude - RING.r) - RING.w / 2
	if dr < best then best, which = dr, RING end
	return best, which
end
local function inSquare(p: Vector2): any
	for _, s in ipairs(SQUARES) do
		if s.rect and p.X >= s.rect[1].X and p.X <= s.rect[2].X and p.Y >= s.rect[1].Y and p.Y <= s.rect[2].Y then return s end
		if s.circle and (p - s.circle[1]).Magnitude <= s.circle[2] then return s end
	end
	return nil
end
local function place(name: string, parent: Instance, x: number, z: number, scale: number, face: Vector2, sink: number?): Model
	local m = (Kit:FindFirstChild(name) :: Model):Clone()
	m:ScaleTo(scale)
	local _, sz = m:GetBoundingBox()
	local r = math.max(sz.X, sz.Z) * 0.42
	local lo = math.huge
	for _, o in ipairs({ { 0, 0 }, { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r }, { r * 0.7, r * 0.7 }, { -r * 0.7, -r * 0.7 }, { r * 0.7, -r * 0.7 }, { -r * 0.7, r * 0.7 } }) do
		lo = math.min(lo, (ground(x + o[1], z + o[2])))
	end
	local p = Vector3.new(x, lo - (sink or 0.5), z)
	m:PivotTo(CFrame.lookAt(p, p + Vector3.new(face.X, 0, face.Y)))
	m.Parent = parent
	return m
end
local function removeTrees(pred: (Vector2) -> boolean): number
	local n = 0
	for _, t in ipairs(Map.Nature.Groves:GetDescendants()) do
		if t:IsA("Model") and t.Parent and t:FindFirstChildWhichIsA("BasePart") then
			local p = t:GetPivot().Position
			if pred(V2(p.X, p.Z)) then t:Destroy(); n += 1 end
		end
	end
	return n
end

local report = {}

-- ===================================================================== clear: random village + city-zone sanctuaries
local function clear()
	local n = 0
	for _, m in ipairs(St.Village:GetChildren()) do
		if m.Name ~= "AL_Aqueduct" and m.Name ~= "AL_Lighthouse" then m:Destroy(); n += 1 end
	end
	local s = 0
	for _, m in ipairs(St.Sanctuaries:GetChildren()) do
		local p = m:GetPivot().Position
		if p.X > -1460 and p.X < -460 and p.Z > -640 and p.Z < 110 then m:Destroy(); s += 1 end
	end
	table.insert(report, ("clear: %d village pieces, %d sanctuaries"):format(n, s))
end

-- ===================================================================== roads: paint terrain + clear trees off them
-- Painting = ONE ReadVoxels + WriteVoxels per street segment (B172 p5: per-cell ReplaceMaterial over thousands of cells
-- in one call CLOSED the place). Yield between segments.
local SOFT = { [M.Grass] = true, [M.LeafyGrass] = true, [M.Ground] = true, [M.Sand] = true, [M.Mud] = true, [M.Rock] = true }
local function paint(lo: Vector2, hi: Vector2, test: (Vector2) -> boolean, mat: Enum.Material): number
	local T = workspace.Terrain
	local ymin, ymax = math.huge, -math.huge
	for x = lo.X, hi.X, 12 do
		for z = lo.Y, hi.Y, 12 do
			local y = ground(x, z)
			if y > 2 then ymin = math.min(ymin, y); ymax = math.max(ymax, y) end
		end
	end
	if ymin > ymax then return 0 end
	local region = Region3.new(Vector3.new(lo.X, ymin - 10, lo.Y), Vector3.new(hi.X, ymax + 6, hi.Y)):ExpandToGrid(4)
	local mats, occ = T:ReadVoxels(region, 4)
	local size = mats.Size
	local corner = region.CFrame.Position - region.Size / 2
	local n = 0
	for i = 1, size.X do
		local x = corner.X + (i - 0.5) * 4
		for k = 1, size.Z do
			local z = corner.Z + (k - 0.5) * 4
			if test(V2(x, z)) then
				for j = 1, size.Y do
					if SOFT[mats[i][j][k]] then mats[i][j][k] = mat; n += 1 end
				end
			end
		end
	end
	T:WriteVoxels(region, 4, mats, occ)
	return n
end
local function roads()
	local out = {}
	for _, r in ipairs(ROADS) do
		for i = 1, #r.pts - 1 do
			local a, b = r.pts[i], r.pts[i + 1]
			local lo = V2(math.min(a.X, b.X) - r.w, math.min(a.Y, b.Y) - r.w)
			local hi = V2(math.max(a.X, b.X) + r.w, math.max(a.Y, b.Y) + r.w)
			table.insert(out, r.name .. i .. ":" .. paint(lo, hi, function(p) return segDist(p, a, b) <= r.w / 2 end, r.mat))
			task.wait()
		end
	end
	local e = V2(RING.r + RING.w, RING.r + RING.w)
	table.insert(out, "Circus:" .. paint(RING.c - e, RING.c + e, function(p) return math.abs((p - RING.c).Magnitude - RING.r) <= RING.w / 2 end, RING.mat))
	task.wait()
	for _, s in ipairs(SQUARES) do
		local lo = if s.rect then s.rect[1] else s.circle[1] - V2(s.circle[2], s.circle[2])
		local hi = if s.rect then s.rect[2] else s.circle[1] + V2(s.circle[2], s.circle[2])
		table.insert(out, s.name .. ":" .. paint(lo, hi, function(p) return inSquare(p) == s end, s.mat))
		task.wait()
	end
	workspace.Terrain:SetMaterialColor(M.Cobblestone, Color3.fromRGB(214, 198, 172))
	local t = removeTrees(function(p) return roadDist(p) < 4 or inSquare(p) ~= nil end)
	table.insert(report, ("roads: %s; %d trees off the streets"):format(table.concat(out, ", "), t))
end

-- ===================================================================== landmarks + arches + the Moon Shrine move
local function landmarks()
	local f = folder("Landmarks")
	for _, L in ipairs(LANDMARKS) do
		local m = place(L[1], f, L[2], L[3], L[4], L[5].Unit)
		m.Name = L[6]
	end
	for i, A in ipairs(ARCHES) do
		local m = place("AL_StreetArch", f, A[1], A[2], A[3], A[4].Unit, 0.3)
		m.Name = "StreetArch" .. i
	end
	-- the Moon Shrine (TraitReroll): station pieces + keeper + travel arrival + its beacon move as one group
	local moved = 0
	local dest3 = Vector3.new(MOON_TO.X, 0, MOON_TO.Y)
	local function shift(inst: Instance)
		local p = if inst:IsA("Model") then inst:GetPivot().Position else (inst :: BasePart).Position
		local rel = p - MOON_FROM
		local nx, nz = dest3.X + rel.X, dest3.Z + rel.Z
		local dy = ground(nx, nz) - ground(p.X, p.Z)
		local off = Vector3.new(nx - p.X, dy, nz - p.Z)
		if inst:IsA("Model") then inst:PivotTo(inst:GetPivot() + off) else (inst :: BasePart).CFrame += off end
		moved += 1
	end
	if Map:GetAttribute("MoonShrineMoved") ~= true then
		for _, m in ipairs(St.Stations:GetChildren()) do
			local p = if m:IsA("Model") then m:GetPivot().Position else nil
			if p and (V2(p.X, p.Z) - V2(MOON_FROM.X, MOON_FROM.Z)).Magnitude < 32 then shift(m) end
		end
		local npc = workspace:FindFirstChild("NPC_TraitReroll"); if npc then shift(npc) end
		local tr = Map.Travel:FindFirstChild("Stone_Shrine"); if tr then shift(tr) end
		local bc = Map:FindFirstChild("VFX2") and Map.VFX2:FindFirstChild("Beacons") and Map.VFX2.Beacons:FindFirstChild("NPC_TraitReroll")
		if bc then shift(bc) end
		Map:SetAttribute("MoonShrineMoved", true)
	end
	local t = removeTrees(function(p)
		for _, L in ipairs(LANDMARKS) do if (p - V2(L[2], L[3])).Magnitude < 40 * L[4] then return true end end
		return false
	end)
	table.insert(report, ("landmarks: %d + %d arches; moon shrine pieces moved %d; trees cleared %d"):format(#LANDMARKS, #ARCHES, moved, t))
end

-- ===================================================================== rows: houses lining the streets, fronts to the street
local TYPES = {
	{ "AL_RowHouse", 1.5, 24, 34 },     -- piece, scale, width along street, depth
	{ "AL_RowHouse", 1.5, 24, 34 },
	{ "AL_BahayNaBato", 1.15, 38, 30 },
	{ "AL_RowHouse", 1.5, 24, 34 },
	{ "AL_CornerHouse", 1.2, 39, 39 },
}
local function rows()
	local f = folder("Rows")
	local blocks = {}
	for _, L in ipairs(LANDMARKS) do table.insert(blocks, { V2(L[2], L[3]), 30 * L[4] }) end
	for _, m in ipairs(St:GetDescendants()) do
		if m:IsA("Model") and m.Parent and (m.Parent.Parent == St or m.Parent == St) and m.Name ~= "City" then
			local ok, cf, sz = pcall(function() return m:GetBoundingBox() end)
			if ok and sz.Magnitude < 600 then table.insert(blocks, { V2(cf.X, cf.Z), math.max(sz.X, sz.Z) / 2 }) end
		end
	end
	local function free(p: Vector2, r: number): boolean
		for _, k in ipairs(KEEP) do if (p - k[1]).Magnitude < k[2] + r then return false end end
		for _, b in ipairs(blocks) do if (p - b[1]).Magnitude < b[2] + r then return false end end
		if p.X > -625 and p.Y < -105 then return false end -- temple terrace wall strip
		if roadDist(p) < r * 0.85 then return false end      -- never on (or over the edge of) any road
		if inSquare(p) then return false end
		local lo, hi = math.huge, -math.huge
		for _, o in ipairs({ { 0, 0 }, { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r } }) do
			local y, mat = ground(p.X + o[1], p.Y + o[2])
			if mat == M.Water or y < 20 then return false end
			lo = math.min(lo, y); hi = math.max(hi, y)
		end
		return hi - lo < 7
	end
	local n, k = 0, 0
	for _, R in ipairs(ROWS) do
		local road
		for _, r in ipairs(ROADS) do if r.name == R[1] then road = r end end
		for seg = 1, #road.pts - 1 do
			local a, b = road.pts[seg], road.pts[seg + 1]
			local d = (b - a).Unit
			local nrm = V2(-d.Y, d.X)
			local len = (b - a).Magnitude
			for _, side in ipairs(R[3]) do
				local s = 14
				while s < len - 14 do
					k += 1
					local T = TYPES[(k % #TYPES) + 1]
					local off = road.w / 2 + 5 + T[4] / 2
					local p = a + d * (s + T[3] / 2) + nrm * side * off
					local r = math.max(T[3], T[4]) / 2
					if free(p, r * 0.9) then
						local face = -nrm * side
						place(T[1], f, p.X, p.Y, T[2], face).Name = T[1]:gsub("AL_", "")
						table.insert(blocks, { p, r * 0.95 })
						n += 1
						s += T[3] + 3
					else
						s += 8
					end
				end
			end
		end
	end
	local t = removeTrees(function(p) for _, b in ipairs(blocks) do if (p - b[1]).Magnitude < b[2] + 2 then return true end end return false end)
	table.insert(report, ("rows: %d buildings lining the streets; trees cleared %d"):format(n, t))
end

-- ===================================================================== street furniture: lamps, avenue trees, obelisks
local function street()
	local f = folder("Street")
	local pinkTree
	for _, t in ipairs(Map.Nature.Groves:GetDescendants()) do
		local sa = t:IsA("SurfaceAppearance") and t
		if sa and sa.Color.R > 0.99 and sa.Color.B > 0.8 then pinkTree = sa.Parent.Parent; break end
	end
	local function lamp(p: Vector2, face: Vector2)
		place("AL_LampPost", f, p.X, p.Y, 1.35, face, 0.3).Name = "Lamp"
	end
	local n, trees, obel = 0, 0, 0
	for _, r in ipairs(ROADS) do
		local every = if r.name == "SunRoad" or r.name == "GateAvenue" then 40 elseif r.name == "Promenade" then 45 else 55
		for i = 1, #r.pts - 1 do
			local a, b = r.pts[i], r.pts[i + 1]
			local d = (b - a).Unit
			local nrm = V2(-d.Y, d.X)
			local len = (b - a).Magnitude
			local s, k = 18, 0
			while s < len - 10 do
				k += 1
				for _, side in ipairs({ 1, -1 }) do
					local both = r.w >= 30 or r.name == "Promenade"
					if both or (k + (if side == 1 then 0 else 1)) % 2 == 0 then
						local p = a + d * s + nrm * side * (r.w / 2 + 2.5)
						if not inSquare(p) and (p - RING.c).Magnitude > RING.r + RING.w / 2 + 2 then lamp(p, -nrm * side); n += 1 end
					end
					-- Sun Road: blossom trees between the lamps; Gate Avenue: shard obelisks between the lamps
					local q = a + d * (s + every / 2) + nrm * side * (r.w / 2 + 6)
					if r.name == "SunRoad" and pinkTree and s + every / 2 < len - 10 then
						local t = pinkTree:Clone()
						t:SetAttribute("Sunk", nil)
						local y = ground(q.X, q.Y)
						local cf, sz = t:GetBoundingBox()
						local base = t:GetPivot().Y - (cf.Y - sz.Y / 2)
						t:PivotTo(CFrame.new(q.X, y + base - (sz.Y * 0.06 + 1.5), q.Y))
						t:SetAttribute("Sunk", sz.Y * 0.06 + 1.5)
						t.Name = "AvenueTree"; t.Parent = f; trees += 1
					elseif r.name == "GateAvenue" and s + every / 2 < len - 10 then
						place("AL_ShardObelisk", f, q.X, q.Y, 1.25, -nrm * side, 0.4).Name = "Obelisk"; obel += 1
					end
				end
				s += every
			end
		end
	end
	-- the circus: lamps round the outer rim every 30 degrees
	for k = 0, 11 do
		local a = k * math.pi / 6 + math.pi / 12
		local p = RING.c + V2(math.cos(a), math.sin(a)) * (RING.r + RING.w / 2 + 2.5)
		lamp(p, (RING.c - p).Unit); n += 1
	end
	table.insert(report, ("street: %d lamps, %d avenue trees, %d obelisks"):format(n, trees, obel))
end

local ALL = { clear = clear, roads = roads, landmarks = landmarks, rows = rows, street = street }
for _, sec in ipairs(SECTIONS) do ALL[sec]() end
return table.concat(report, " | ")
