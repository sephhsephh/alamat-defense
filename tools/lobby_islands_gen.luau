--!strict
-- tools/lobby_islands_gen.luau (B130) -- the LOBBY ISLAND LAYOUT generator (terrain only).
-- Deployed as ServerStorage.DevTools.LobbyIslandsGen (Lobby). Run from execute_luau in Edit:
--   local G = require(game.ServerStorage.DevTools.LobbyIslandsGen:Clone())
--   G.Check()            -> lists any parts inside the build box (it must be empty water)
--   G.Build(band)        -> resets one Z band (1..G.BANDS) to the water baseline, then writes its islands
--   G.Markers()          -> Workspace.LobbyIslandMarkers: one invisible named part on each island top
-- Layout = the user's "Map Concept" image (B130): islands only -- no paths / bridges / structures / mood.
-- Local frame: +X = the image's right, +Z = toward the viewer (front), origin = ORIGIN in world.
-- Heights are studs above the water surface (Y ~ 4); the tiers roughly match the old lobby (~90/120/165/200).
-- Re-running a band rewrites it from the island list, so the layout can be tuned here and rebuilt.

local G = {}

G.ORIGIN = Vector3.new(-300, 0, 650)
local RES = 4
local Y0, Y1 = -12, 276 -- vertical span written (water layer is Y -4..4)
local X0, X1 = -1120, 560 -- world X span (multiples of 4)
local Z0, Z1 = -540, 1080 -- world Z span
G.BANDS = 8
G.STRETCH_X = 1.2 -- the concept is ~2.4x wider than deep: island centres AND shapes are stretched left-right

type Circle = { number }
type Island = { name: string, H: number, edge: number?, beach: number?, kind: string?, circles: { Circle } }

-- kind: "cliff" (default: rock walls, grass top) | "low" (grass top + sand ring) | "sand" | "cone" | "stack"
G.ISLANDS = {
	{ name = "TempleTerrace", H = 200, edge = 10, circles = { { -120, -285, 62 }, { -70, -292, 45 } } },
	{ name = "TemplePlateau", H = 165, circles = { { -150, -250, 120 }, { -60, -255, 100 }, { -235, -215, 85 }, { -120, -180, 90 } } },
	{ name = "AltarTerrace", H = 112, circles = { { -40, -110, 90 }, { 40, -120, 62 }, { -110, -120, 60 } } },
	{ name = "LeftJungleBack", H = 150, circles = { { -470, -300, 90 }, { -560, -230, 70 } } },
	{ name = "LeftJungle", H = 125, circles = { { -420, -140, 105 }, { -330, -120, 85 }, { -500, -75, 75 }, { -400, -200, 80 } } },
	{ name = "LeftJungleStep", H = 80, circles = { { -320, -40, 62 }, { -410, -30, 60 } } },
	{ name = "VillageBeach", H = 12, edge = 8, beach = 28, kind = "low", circles = { { -480, 70, 80 }, { -400, 95, 60 }, { -530, 20, 55 } } },
	{ name = "BlueBeaconRock", H = 72, edge = 8, circles = { { -265, 160, 48 } } },
	{ name = "FrontLeftBeach", H = 8, edge = 8, beach = 26, kind = "sand", circles = { { -330, 240, 70 }, { -250, 265, 50 } } },
	{ name = "FrontCenter", H = 92, circles = { { -50, 120, 100 }, { 55, 155, 80 }, { -135, 80, 58 }, { 10, 60, 60 } } },
	{ name = "RightGate", H = 118, circles = { { 310, -40, 105 }, { 420, -20, 110 }, { 530, 10, 90 }, { 230, -70, 70 }, { 600, 40, 60 } } },
	{ name = "PurpleShrine", H = 135, circles = { { 470, -270, 85 }, { 550, -245, 70 }, { 410, -290, 55 } } },
	{ name = "GreenBeacon", H = 96, circles = { { 240, 170, 92 }, { 320, 145, 70 } } },
	{ name = "GreenBeaconLedge", H = 45, edge = 8, circles = { { 255, 265, 55 } } },
	{ name = "SeaStack", H = 48, edge = 5, kind = "stack", circles = { { 40, 340, 32 } } },
	{ name = "RockLeft", H = 18, edge = 4, kind = "stack", circles = { { -170, 300, 16 } } },
	{ name = "RockRight", H = 14, edge = 4, kind = "stack", circles = { { 120, 262, 12 } } },
	-- background, far out at sea (the cone keeps its round shape: only its centre is stretched)
	{ name = "Volcano", H = 240, kind = "cone", circles = { { 220, -950, 170 } } },
	{ name = "VolcanoShore", H = 10, edge = 8, beach = 24, kind = "low", circles = { { 220, -950, 150 } } },
	-- (left of the volcano, not right as in the concept: the right side is the old lobby's floating props)
	{ name = "IsletBig", H = 40, edge = 6, circles = { { -120, -880, 48 } } },
	{ name = "IsletSmall", H = 28, edge = 6, circles = { { -40, -810, 32 } } },
} :: { Island }

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

-- surface height + material class for one column (local coords)
local function column(lx: number, lz: number): (number, string, number)
	local wx = (lx + math.noise(lx / 110, lz / 110, 1.3) * 30) / G.STRETCH_X
	local wz = lz + math.noise(lx / 110, lz / 110, 7.7) * 30
	local fine = math.noise(lx / 35, lz / 35, 3.1) * 6
	local bestH, bestCls, bestD = -math.huge, "none", 0
	for _, isl in ipairs(G.ISLANDS) do
		local kind = isl.kind or "cliff"
		if kind == "cone" then
			local c = isl.circles[1]
			local dd = math.sqrt((lx - c[1] * G.STRETCH_X) ^ 2 + (lz - c[2]) ^ 2) + fine
			if dd < c[3] then
				local h = isl.H * (1 - dd / c[3]) ^ 1.35
				local crater = c[3] * 0.12
				if dd < crater then h -= (crater - dd) * 1.6 end
				h += math.noise(lx / 25, lz / 25, 9.1) * 6
				if h > bestH then bestH, bestCls, bestD = h, "cone", dd end
			end
		else
			local d = -math.huge
			for _, c in ipairs(isl.circles) do
				local dx, dz = wx - c[1], wz - c[2]
				d = math.max(d, c[3] - math.sqrt(dx * dx + dz * dz))
			end
			d += fine
			local edge = isl.edge or 12
			local beach = isl.beach or 0
			local h = -math.huge
			if d >= 0 then
				local s = smooth(d / edge)
				-- rolling tops: a broad swell + small bumps (the concept's tops are never dead flat)
				local top = isl.H + (if kind == "stack" then math.noise(lx / 60, lz / 60, 5.5) * 2
					else math.noise(lx / 90, lz / 90, 5.5) * 9 + math.noise(lx / 28, lz / 28, 4.4) * 2.5)
				local foot = if beach > 0 then 7 else -8
				h = foot + (top - foot) * s
			elseif beach > 0 and d > -beach then
				h = -8 + 15 * smooth((d + beach) / beach) -- sand shelf rising to ~Y 7 at the island edge
			end
			if h > bestH then
				local cls = kind
				if d < 0 then cls = "sand" end
				bestH, bestCls, bestD = h, cls, d
			end
		end
	end
	return bestH, bestCls, bestD
end

local M = Enum.Material
local function material(cls: string, d: number, y: number, h: number, lx: number, lz: number): Enum.Material
	if cls == "sand" then return M.Sand end
	if cls == "cone" then
		if y > h - 8 then return M.Basalt end
		return M.Rock
	end
	local isTop = y > h - 4
	local edge = 9
	if isTop and d >= edge and cls ~= "stack" then
		if math.noise(lx / 40, lz / 40, 2.2) > 0.25 then return M.LeafyGrass end
		return M.Grass
	end
	if cls == "low" and isTop then return M.Grass end
	if math.noise(lx / 70, y / 18, lz / 70) > 0.2 then return M.Slate end
	return M.Rock
end

function G.Check(): string
	local box = workspace:GetPartBoundsInBox(
		CFrame.new((X0 + X1) / 2, (Y0 + Y1) / 2, (Z0 + Z1) / 2),
		Vector3.new(X1 - X0, Y1 - Y0, Z1 - Z0)
	)
	local names = {}
	for _, p in ipairs(box) do
		if p ~= workspace.Terrain and not p:IsDescendantOf(workspace:FindFirstChild("LobbyIslandMarkers") or workspace.Terrain) then
			local top = p:FindFirstAncestorOfClass("Model") or p
			names[top:GetFullName()] = true
		end
	end
	local t = {}
	for k in pairs(names) do table.insert(t, k) end
	return #t .. " object(s) in the build box" .. (if #t > 0 then ": " .. table.concat(t, ", ") else "")
end

function G.Build(band: number): string
	local T = workspace.Terrain
	local span = (Z1 - Z0) / G.BANDS
	local zA = Z0 + math.floor((band - 1) * span / RES) * RES
	local zB = if band == G.BANDS then Z1 else Z0 + math.floor(band * span / RES) * RES
	local written, land = 0, 0
	local CH = 256
	for xA = X0, X1 - 1, CH do
		local xB = math.min(xA + CH, X1)
		local region = Region3.new(Vector3.new(xA, Y0, zA), Vector3.new(xB, Y1, zB))
		local mats, occs = T:ReadVoxels(region, RES)
		local sx, sy, sz = mats.Size.X, mats.Size.Y, mats.Size.Z
		local touched = false
		for ix = 1, sx do
			local wxC = xA + (ix - 0.5) * RES
			for iz = 1, sz do
				local wzC = zA + (iz - 0.5) * RES
				local lx, lz = wxC - G.ORIGIN.X, wzC - G.ORIGIN.Z
				-- reset to the lobby's water baseline (two full Water cells, Y -4..4) so a rebuild leaves no old land
				for iy = 1, sy do
					local yC = Y0 + (iy - 0.5) * RES
					local isWater = yC > -4 and yC < 4
					if mats[ix][iy][iz] ~= (if isWater then M.Water else M.Air) then
						mats[ix][iy][iz] = if isWater then M.Water else M.Air
						occs[ix][iy][iz] = if isWater then 1 else 0
						touched = true
					end
				end
				local h, cls, d = column(lx, lz)
				if cls ~= "none" and h > Y0 then
					land += 1
					local surf = h + 4 -- heights are above the water surface (Y ~ 4)
					for iy = 1, sy do
						local yBot = Y0 + (iy - 1) * RES
						if yBot >= surf then break end
						local occ = math.clamp((surf - yBot) / RES, 0, 1)
						local yC = yBot + RES / 2
						mats[ix][iy][iz] = material(cls, d, yC, surf, lx, lz)
						occs[ix][iy][iz] = occ
						written += 1
						touched = true
					end
				end
			end
		end
		if touched then T:WriteVoxels(region, RES, mats, occs) end
		task.wait()
	end
	return string.format("band %d/%d (Z %d..%d): %d land column(s), %d voxel(s) written", band, G.BANDS, zA, zB, land, written)
end

function G.Markers(): string
	local old = workspace:FindFirstChild("LobbyIslandMarkers")
	if old then old:Destroy() end
	local f = Instance.new("Folder")
	f.Name = "LobbyIslandMarkers"
	for _, isl in ipairs(G.ISLANDS) do
		local c = isl.circles[1]
		local p = Instance.new("Part")
		p.Name = isl.name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.new(4, 4, 4)
		p.Position = G.ORIGIN + Vector3.new(c[1] * G.STRETCH_X, isl.H + 8, c[2])
		p:SetAttribute("TopHeight", isl.H + 4)
		p.Parent = f
	end
	f.Parent = workspace
	return "markers: " .. #f:GetChildren()
end

return G
