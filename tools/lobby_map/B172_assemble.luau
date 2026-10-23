-- tools/lobby_map/B172_assemble.luau (B172) -- step 2: place the holy kit (ServerStorage.DevTools.LobbyMap.B172Protos.Kit,
-- made by B172_harvest.luau) per tools/lobby_map/B172_PLAN.md "Assembly layout". Paste into execute_luau (Lobby, Edit).
-- SECTIONS lists what to (re)build; each section clears and rebuilds its own folder under Workspace.Lobby.Map.Structures.
-- Kit pivots: bottom-centre, front = -Z, so CFrame.lookAt(pos, pos + dir) makes a piece FACE `dir`.
local SECTIONS = { "Rotunda", "Bridge", "SeaWall", "Plaza", "Terrace", "Temple", "Stations", "Arena", "Citadel", "Colossal", "Falls" }

local kit = game.ServerStorage.DevTools.LobbyMap.B172Protos.Kit
local map = workspace.Lobby.Map
local structures = map:FindFirstChild("Structures") or Instance.new("Folder")
structures.Name = "Structures"; structures.Parent = map
local S, P = Vector3.new(-300, 0, 420), Vector3.new(-300, 0, 0)
local ARENA = Vector3.new(140, 0, 400)
local DECK = 40
local deckVariant = "AL_HolyMarble2"

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): number
	local r = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -700, 0), rayParams)
	return if r then r.Position.Y else 0
end
local function section(name: string): Folder
	local f = structures:FindFirstChild(name); if f then f:Destroy() end
	f = Instance.new("Folder"); f.Name = name; f.Parent = structures
	return f
end
local function faceCF(pos: Vector3, dir: Vector3): CFrame
	dir = Vector3.new(dir.X, 0, dir.Z)
	return CFrame.lookAt(pos, pos + (if dir.Magnitude > 1e-3 then dir.Unit else Vector3.new(0, 0, -1)))
end
-- stretch a model along its own Y about its Root (arcades/walls fitted to a height)
local function scaleY(m: Model, k: number)
	local root = m.PrimaryPart :: BasePart
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p ~= root then
			local rel = root.CFrame:ToObjectSpace(p.CFrame)
			p.Size = Vector3.new(p.Size.X, p.Size.Y * k, p.Size.Z)
			p.CFrame = root.CFrame * CFrame.new(rel.Position * Vector3.new(1, k, 1)) * rel.Rotation
		end
	end
end
local function put(folder: Instance, piece: string, cf: CFrame, scale: number?, yScale: number?, decor: boolean?): Model?
	local src = kit:FindFirstChild(piece)
	if not src then warn("[B172] missing kit piece " .. piece); return nil end
	local m = src:Clone()
	if scale and scale ~= 1 then m:ScaleTo(scale) end
	if yScale and yScale ~= 1 then scaleY(m, yScale) end
	if decor then
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false; p.CanQuery = false; p.CastShadow = false end
		end
	end
	m:PivotTo(cf)
	m.Parent = folder
	return m
end
local function collider(folder: Instance, name: string, size: Vector3, cf: CFrame, wedge: boolean?)
	local p = if wedge then Instance.new("WedgePart") else Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true; p.Transparency = 1
	p.CanCollide = true; p.CanQuery = true; p.CanTouch = false; p.CastShadow = false
	p.Parent = folder
	return p
end
local function angDiff(a: number, b: number): number
	return math.abs((a - b + math.pi) % (2 * math.pi) - math.pi)
end
-- ring of straight pieces of width w around `c`; dir(theta) = (sin, 0, cos); skip(theta) -> true leaves a gap
local function ring(folder: Instance, piece: string, c: Vector3, radius: number, n: number, baseY: number, skip: ((number) -> boolean)?, scale: number?)
	for i = 0, n - 1 do
		local th = 2 * math.pi * (i + 0.5) / n
		if not (skip and skip(th)) then
			local dir = Vector3.new(math.sin(th), 0, math.cos(th))
			put(folder, piece, faceCF(Vector3.new(c.X, baseY, c.Z) + dir * radius, dir), scale)
		end
	end
end
local NORTH, EAST = math.pi, math.pi / 2
-- move a station NPC (Root / Body prompt holder / Unit rig, as placed by the B172 station pass) to stand at (x, y, z) facing dir
local function moveNPC(name: string, x: number, y: number, z: number, dir: Vector3)
	local npc = workspace:FindFirstChild(name)
	if not npc then return end
	local look = faceCF(Vector3.new(x, y, z), dir)
	local unit, root, body = npc:FindFirstChild("Unit"), npc:FindFirstChild("Root"), npc:FindFirstChild("Body")
	if unit then local _, size = unit:GetBoundingBox(); unit:PivotTo(look * CFrame.new(0, size.Y / 2, 0)) end
	if root then root.CFrame = look * CFrame.new(0, 0.5, 0) end
	if body then body.CFrame = look * CFrame.new(0, 2.5, 0) end
end

local B = {}

function B.Rotunda()
	local f = section("Rotunda")
	local function gap(th) return angDiff(th, NORTH) < 0.36 or angDiff(th, EAST) < 0.36 end
	ring(f, "AL_ArcBayTall", S, 53.2, 24, 0, gap)
	for _, a in ipairs({ NORTH - 0.40, NORTH + 0.40, EAST - 0.40, EAST + 0.40 }) do
		local d = Vector3.new(math.sin(a), 0, math.cos(a))
		put(f, "AL_Pier", faceCF(Vector3.new(S.X, 0, S.Z) + d * 54, d), 1.34)
	end
	ring(f, "AL_Balustrade", S, 54.6, 28, DECK, function(th) return angDiff(th, NORTH) < 0.3 or angDiff(th, EAST) < 0.3 end)
	put(f, "AL_Mandala", CFrame.new(S.X, DECK, S.Z), 1.5)
	put(f, "AL_SunGate", faceCF(Vector3.new(S.X, DECK, S.Z - 52), Vector3.new(0, 0, 1)))
	for k = 0, 3 do
		local a = math.pi / 4 + k * math.pi / 2
		put(f, "AL_DomePavilion", CFrame.new(S + Vector3.new(math.sin(a), 0, math.cos(a)) * 38 + Vector3.new(0, DECK, 0)), 0.75)
	end
	for k = 0, 7 do
		local a = math.pi / 8 + k * math.pi / 4
		if angDiff(a, NORTH) > 0.45 and angDiff(a, EAST) > 0.45 then
			put(f, "AL_LampPost", CFrame.new(S + Vector3.new(math.sin(a), 0, math.cos(a)) * 47 + Vector3.new(0, DECK, 0)), 1.25)
		end
	end
	moveNPC("NPC_Guide", S.X - 16, DECK, S.Z - 34, Vector3.new(0.3, 0, 1))
end

function B.Bridge()
	local f = section("Bridge")
	for k = 0, 6 do put(f, "AL_BridgeSpan", CFrame.new(S.X, 4, 349 - 30 * k)) end
	local deck = map.Core:FindFirstChild("BridgeDeck"); if deck then deck.Transparency = 1 end
	for _, sx in ipairs({ -12.8, 12.8 }) do collider(f, "Rail", Vector3.new(1, 5, 212), CFrame.new(S.X + sx, DECK + 2.5, 259)) end
end

function B.SeaWall()
	local f = section("SeaWall")
	local step = 2 * math.asin(7 / 181.8)
	local th = -math.pi / 2 + step / 2
	while th < math.pi / 2 do
		if math.abs(th) > 0.05 then
			local dir = Vector3.new(math.sin(th), 0, math.cos(th))
			local pos = Vector3.new(P.X, 0, P.Z) + dir * 181.8
			local base = math.max(-2, ground(pos.X + dir.X * 6, pos.Z + dir.Z * 6))
			local need = DECK - base
			if need > 4 then
				if need > 30 then put(f, "AL_ArcBayTall", faceCF(Vector3.new(pos.X, base, pos.Z), dir), 1, need / 40)
				else put(f, "AL_ArcBay", faceCF(Vector3.new(pos.X, base, pos.Z), dir), 1, need / 24) end
			end
		end
		th += step
	end
	local bstep = 2 * math.asin(6 / 175)
	th = -math.pi / 2 + bstep / 2
	while th < math.pi / 2 do
		if math.abs(th) > 0.075 then
			local dir = Vector3.new(math.sin(th), 0, math.cos(th))
			put(f, "AL_Balustrade", faceCF(Vector3.new(P.X, DECK, P.Z) + dir * 175, dir))
		end
		th += bstep
	end
end

function B.Plaza()
	local f = section("Plaza")
	put(f, "AL_Mandala", CFrame.new(P.X, DECK, 40), 2.4)
	put(f, "AL_Fountain", CFrame.new(P.X, DECK + 0.5, 40), 2.5)
	for _, o in ipairs({ { -115, 85 }, { 115, 85 }, { -125, -60 }, { 125, -60 } }) do
		put(f, "AL_DomePavilion", CFrame.new(P.X + o[1], DECK, o[2]), 1.2)
	end
	for k = 0, 19 do
		local a = (k + 0.5) * math.pi / 10
		if math.abs(math.sin(a)) > 0.12 or math.cos(a) < 0 then
			put(f, "AL_LampPost", CFrame.new(P + Vector3.new(math.sin(a), 0, math.cos(a)) * 150 + Vector3.new(0, DECK, 0)), 1.3)
		end
	end
	for _, sx in ipairs({ -17, 17 }) do put(f, "AL_Banner", faceCF(Vector3.new(P.X + sx, DECK, 166), Vector3.new(0, 0, 1)), 1.4) end
end

function B.Terrace()
	local f = section("Terrace")
	local gaps = { -300, -520, -80 }
	for x = -613, 13, 14 do
		local inGap = false
		for _, g in ipairs(gaps) do if math.abs(x - g) < 22 then inGap = true end end
		if not inGap then put(f, "AL_WallSeg", faceCF(Vector3.new(x, DECK, -118.4), Vector3.new(0, 0, 1)), 1, 1.7) end
	end
	for _, g in ipairs(gaps) do
		put(f, "AL_Stairs", faceCF(Vector3.new(g, DECK, -106.5), Vector3.new(0, 0, 1)), 1.42)
		collider(f, "StairRamp", Vector3.new(34, 20, 27), CFrame.new(g, DECK + 10, -106.5) * CFrame.Angles(0, math.pi, 0), true)
	end
end

function B.Temple()
	local f = section("Temple")
	put(f, "AL_Temple", faceCF(Vector3.new(P.X, 60, -232), Vector3.new(0, 0, 1)))
	local pp = collider(f, "SummonPoint", Vector3.new(6, 6, 2), CFrame.new(P.X, 64, -199))
	pp.CanCollide = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SummonPrompt"; prompt.ActionText = "Summon"; prompt.ObjectText = "Temple of Bathala"
	prompt.MaxActivationDistance = 16; prompt.RequiresLineOfSight = false
	prompt:SetAttribute("OpensEvent", "OpenSummon")
	prompt.Parent = pp
end

function B.Stations()
	local f = section("Stations")
	-- Ascension: Sky Spire behind the keeper
	put(f, "AL_SpireTower", faceCF(Vector3.new(-520, 60, -234), Vector3.new(0, 0, 1)))
	put(f, "AL_Dais", CFrame.new(-520, 60, -190))
	-- Evolve: the Sun Rotunda (pavilion around the keeper)
	put(f, "AL_DomePavilion", CFrame.new(-80, 60, -196), 1.6)
	-- Stat reroll: the Star Forge (dais + halo behind + two columns)
	local sx, sz = -530, -20
	local sg = ground(sx, sz)
	put(f, "AL_Dais", CFrame.new(sx, sg, sz), 1.1)
	put(f, "AL_HaloRing", faceCF(Vector3.new(sx - 9, sg + 1, sz), Vector3.new(1, 0, 0)), 1.6)
	for _, oz in ipairs({ -15, 15 }) do put(f, "AL_Column", CFrame.new(sx - 6, sg, sz + oz), 1.3) end
	-- Trait reroll: the Moon Shrine (dais, column ring open to the east, crystals + halo behind)
	local tx, tz = -700, -110
	local tg = ground(tx, tz)
	put(f, "AL_Dais", CFrame.new(tx, tg, tz), 1.3)
	for k = 0, 5 do
		local a = k * math.pi / 3 + math.pi / 6
		if angDiff(a, EAST) > 0.6 then put(f, "AL_Column", CFrame.new(tx + math.sin(a) * 18, tg, tz + math.cos(a) * 18), 1.15) end
	end
	for _, o in ipairs({ { -12, -6 }, { -13, 7 }, { -8, 0 } }) do
		put(f, "AL_Crystal", CFrame.new(tx + o[1], tg + 1, tz + o[2]) * CFrame.Angles(0, o[2], 0), 2.4)
	end
	put(f, "AL_HaloRing", faceCF(Vector3.new(tx - 16, tg, tz), Vector3.new(1, 0, 0)), 1.25)
	-- Bay Bazaar (Shop + Craft): stalls behind the keepers, parasols + planters in front
	for _, z in ipairs({ 10, -40, 60, -90 }) do put(f, "AL_MarketStall", faceCF(Vector3.new(-54, ground(-54, z), z), Vector3.new(-1, 0, 0)), 1.4) end
	for _, o in ipairs({ { -100, 30 }, { -112, -15 }, { -98, -70 }, { -120, 70 } }) do put(f, "AL_Parasol", CFrame.new(o[1], ground(o[1], o[2]), o[2]), 1.3) end
	for _, o in ipairs({ { -84, 22 }, { -84, -28 }, { -84, -52 }, { -84, 0 } }) do put(f, "AL_Planter", CFrame.new(o[1], ground(o[1], o[2]), o[2]), 1.5) end
end

function B.Arena()
	local f = section("Arena")
	local deck = collider(f, "ArenaDeck", Vector3.new(2, 112, 112), CFrame.new(ARENA.X, DECK - 1, ARENA.Z) * CFrame.Angles(0, 0, math.rad(90)))
	deck.Shape = Enum.PartType.Cylinder; deck.Transparency = 0; deck.Material = Enum.Material.Marble; deck.MaterialVariant = deckVariant
	deck.Color = Color3.fromRGB(255, 252, 245)
	local WEST = 3 * math.pi / 2
	ring(f, "AL_ArcBayTall", ARENA, 53.2, 24, 0, function(th) return angDiff(th, WEST) < 0.36 end)
	ring(f, "AL_ArcBay", ARENA, 50, 22, DECK, function(th) return angDiff(th, WEST) < 0.5 end)
	put(f, "AL_Dais", CFrame.new(ARENA.X, DECK, ARENA.Z), 1.4)
	-- bridge: rotunda east edge -> arena west edge, deck 40
	local a, b = Vector3.new(S.X + 56, 4, S.Z), Vector3.new(ARENA.X - 56, 4, ARENA.Z)
	local dir = (b - a).Unit
	local len = (b - a).Magnitude
	local n = math.ceil(len / 30)
	for k = 0, n - 1 do put(f, "AL_BridgeSpan", CFrame.lookAt(a + dir * (15 + 30 * k), a + dir * (16 + 30 * k))) end
	local mid = (a + b) / 2
	collider(f, "ArenaBridgeDeck", Vector3.new(24, 1, len + 4), CFrame.lookAt(Vector3.new(mid.X, DECK - 0.5, mid.Z), Vector3.new(b.X, DECK - 0.5, b.Z)))
	for _, side in ipairs({ -12.8, 12.8 }) do
		local off = Vector3.new(-dir.Z, 0, dir.X) * side
		collider(f, "Rail", Vector3.new(1, 5, len), CFrame.lookAt(Vector3.new(mid.X, DECK + 2.5, mid.Z) + off, Vector3.new(b.X, DECK + 2.5, b.Z) + off))
	end
	moveNPC("NPC_Challenge", ARENA.X + 12, DECK, ARENA.Z, Vector3.new(-1, 0, 0))
	local arr = map.Travel:FindFirstChild("Stone_Arena")
	if arr and arr:FindFirstChild("Arrival") then arr.Arrival.CFrame = faceCF(Vector3.new(ARENA.X - 30, DECK + 3.5, ARENA.Z), Vector3.new(1, 0, 0)) end
end

function B.Citadel()
	local f = section("Citadel")
	local cx, cz = 300, -330
	local g = ground(cx, cz)
	put(f, "AL_SpireTower", faceCF(Vector3.new(cx, g, cz), Vector3.new(-1, 0, 0.3)), 2.2)
	for _, o in ipairs({ { 44, 44 }, { -44, 44 }, { 44, -44 }, { -44, -44 } }) do
		put(f, "AL_SpireTower", faceCF(Vector3.new(cx + o[1], ground(cx + o[1], cz + o[2]), cz + o[2]), Vector3.new(-1, 0, 0.3)), 0.9)
	end
	put(f, "AL_HaloRing", faceCF(Vector3.new(cx, g + 120, cz), Vector3.new(-1, 0, 0.3)), 5, nil, true)
	put(f, "AL_SunGate", faceCF(Vector3.new(cx - 80, g, cz + 10), Vector3.new(-1, 0, 0.3)), 1.2)
end

function B.Colossal()
	local f = section("Colossal")
	put(f, "AL_SunGate", faceCF(Vector3.new(S.X, -40, 2100), Vector3.new(0, 0, -1)), 8, nil, true)
	local rnd = Random.new(1727)
	for k = 0, 13 do
		local a = math.rad(22 + k * 10.5 + rnd:NextNumber(-3, 3))
		local r = rnd:NextNumber(1450, 1650)
		local pos = Vector3.new(S.X + math.cos(a) * r * 1.3, -20, S.Z + math.sin(a) * r)
		local broken = k % 3 == 1
		local m = put(f, "AL_Column", CFrame.new(pos) * CFrame.Angles(math.rad(if broken then rnd:NextNumber(-9, 9) else 0), rnd:NextNumber(0, 6.28), 0), if broken then rnd:NextNumber(6, 9) else rnd:NextNumber(11, 16), nil, true)
		if m and k % 4 == 0 then put(f, "AL_HaloRing", faceCF(pos + Vector3.new(0, 22 * 13 + 40, 0), Vector3.new(S.X, 0, S.Z) - pos), 7, nil, true) end
	end
end

function B.Falls()
	local f = section("Falls")
	local src = game.ServerStorage._OldLobby_B139.Map.Waterfall.MainFalls
	for _, deg in ipairs({ -24, 24 }) do
		local th = math.rad(deg)
		local dir = Vector3.new(math.sin(th), 0, math.cos(th))
		local m = src:Clone()
		local s0, p0 = m.Source, m.Plunge
		local f0 = CFrame.lookAt(s0.Position, s0.Position + Vector3.new(0, 0, 1))
		local top = Vector3.new(P.X, DECK + 1, P.Z) + dir * 178
		local f1 = CFrame.lookAt(top, top + dir)
		for _, part in ipairs({ s0, p0 }) do part.CFrame = f1 * f0:Inverse() * part.CFrame end
		p0.CFrame = CFrame.new(top + dir * 16 + Vector3.new(0, 3 - top.Y, 0)) * p0.CFrame.Rotation
		m.Parent = f
	end
end

local done = {}
for _, name in ipairs(SECTIONS) do
	local ok, err = pcall(B[name])
	table.insert(done, name .. (if ok then "" else (" FAILED: " .. tostring(err))))
end
return table.concat(done, " | ")
