-- tools/lobby_map/B172_summon.luau (B172 phase 3) -- paste into execute_luau (Lobby, Edit) AFTER the user's 3D Importer
-- run of AL_KitE.glb + B172_harvest.luau. Set SECTION below and run once per section (each is re-runnable):
--   "post"      Kit E protos: one shared TextureID per material (copied from the Kit A-D protos), solids
--               PreciseConvexDecomposition, everything that floats/spins non-colliding.
--   "sanctum"   the Star Sanctum (summon) at SITE: dais + 5 animatable parts + VFX -> Map.Structures.SummonSanctum.
--   "buildings" new building types placed on open flat land -> Map.Structures.Village (trees in their way removed).
-- Setting CollisionFidelity stalls Studio for a while (B172): wait, then re-check; never re-run blindly mid-stall.
local SECTION = "post"

local CS = game:GetService("CollectionService")
local Map = workspace.Lobby.Map
local St = Map.Structures
local Protos = game.ServerStorage.DevTools.LobbyMap.B172Protos
local Kit = Protos.Kit
local TEX = Protos.VFXTex

local SANCTUM = { "AL_SummonDais", "AL_SummonRingOuter", "AL_SummonRingInner", "AL_SummonHeart", "AL_SummonCrown", "AL_SummonHalo" }
local BUILDINGS = { "AL_Pagoda", "AL_BahayNaBato", "AL_Observatory", "AL_Aqueduct", "AL_Lighthouse", "AL_Stupa" }
local FLOATING = { AL_SummonRingOuter = true, AL_SummonRingInner = true, AL_SummonHeart = true, AL_SummonCrown = true, AL_SummonHalo = true }

local SITE = Vector3.new(-940, 0, -120) -- Star Sanctum centre (flat, open, far in the PlayGUICamera's haze)
local FACE = Vector3.new(1, 0, 0) -- front of the sanctum faces east, toward spawn; the halo stands behind (west)
local SCALE = 1.4 -- "huge" (user): ~185 studs across, halo ~170 tall

local rpT = RaycastParams.new()
rpT.FilterType = Enum.RaycastFilterType.Include
rpT.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): (number, Enum.Material?)
	local r = workspace:Raycast(Vector3.new(x, 500, z), Vector3.new(0, -600, 0), rpT)
	return if r then r.Position.Y else -99, if r then r.Material else nil
end

local function place(name: string, parent: Instance, cf: CFrame, scale: number?): Model
	local m = (Kit:FindFirstChild(name) :: Model):Clone()
	if scale and scale ~= 1 then m:ScaleTo(scale) end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

-- pivot at the bounding-box centre (LobbyAmbient spins/bobs about the pivot; GetPivot uses PrimaryPart * PivotOffset)
local function centrePivot(m: Model)
	local cf = m:GetBoundingBox()
	local pp = m.PrimaryPart :: BasePart
	m.PrimaryPart.PivotOffset = pp.CFrame:ToObjectSpace(CFrame.new(cf.Position) * pp.CFrame.Rotation)
end

local function ghost(p: BasePart)
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Transparency = 1
end

local function removeTreesNear(pos: Vector3, r: number): number
	local n = 0
	for _, g in ipairs(Map.Nature.Groves:GetChildren()) do
		for _, t in ipairs(g:GetChildren()) do
			local p = t:GetPivot().Position
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < r then t:Destroy(); n += 1 end
		end
	end
	return n
end

-- ===================================================================== post
local function post(): string
	local canon: { [string]: string } = {}
	for _, piece in ipairs(Kit:GetChildren()) do
		if not table.find(SANCTUM, piece.Name) and not table.find(BUILDINGS, piece.Name) then
			for _, p in ipairs(piece:GetDescendants()) do
				local mat = p:IsA("MeshPart") and p.Name:match("__(%a+)")
				if mat and not canon[mat] and p.TextureID ~= "" then canon[mat] = p.TextureID end
			end
		end
	end
	local parts, precise = 0, 0
	for _, list in ipairs({ SANCTUM, BUILDINGS }) do
		for _, name in ipairs(list) do
			local piece = Kit:FindFirstChild(name)
			assert(piece, "Kit E piece missing (import AL_KitE.glb + run B172_harvest first): " .. name)
			for _, p in ipairs(piece:GetDescendants()) do
				if p:IsA("MeshPart") then
					parts += 1
					local mat = p.Name:match("__(%a+)")
					if mat and canon[mat] and mat ~= "Mandala" then p.TextureID = canon[mat] end
					if FLOATING[name] then
						p.CanCollide = false; p.CanQuery = false
						p.CollisionFidelity = Enum.CollisionFidelity.Box
					elseif p.CanCollide then
						p.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition
						precise += 1
					end
				end
			end
		end
	end
	return ("post: %d meshparts, %d precise, canon textures for %d materials"):format(parts, precise, (function()
		local c = 0 for _ in pairs(canon) do c += 1 end return c end)())
end

-- ===================================================================== sanctum
local function runeDisc(parent: Instance, name: string, pos: Vector3, d: number, color: Color3, rpm: number): Model
	local m = Instance.new("Model"); m.Name = name
	local disc = Instance.new("Part"); disc.Name = "Disc"; disc.Size = Vector3.new(d, 0.2, d); disc.CFrame = CFrame.new(pos)
	ghost(disc); disc.Parent = m
	local dc = Instance.new("Decal"); dc.Texture = TEX.rune.Value; dc.Face = Enum.NormalId.Top; dc.Color3 = color; dc.Parent = disc
	m.PrimaryPart = disc
	m:SetAttribute("RPM", rpm); m:SetAttribute("Axis", "Y")
	m.Parent = parent
	CS:AddTag(m, "AL_Spin")
	return m
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do (e :: any)[k] = v end
	e.Parent = parent
	return e
end

local function sanctum(): string
	local old = St:FindFirstChild("SummonSanctum"); if old then old:Destroy() end
	local root = Instance.new("Model"); root.Name = "SummonSanctum"
	root:SetAttribute("SummonRig", true) -- the parts below are the hooks for the user's summon animation (lobby-map.md)
	root.Parent = St
	local G = ground(SITE.X, SITE.Z)
	local C = Vector3.new(SITE.X, G, SITE.Z)
	local look = function(p: Vector3) return CFrame.lookAt(p, p + FACE) end
	local s = SCALE
	local TOP = G + 9 * s

	local dais = place("AL_SummonDais", root, look(C), s); dais.Name = "Dais"
	-- heights keep the vertical inner ring (+ its crystal studs) clear of the floor and inside the crown/pylons
	local heartBase = Vector3.new(C.X, TOP + 19 * s, C.Z)
	local heart = place("AL_SummonHeart", root, look(heartBase), s); heart.Name = "Heart"
	local focusY = TOP + 19 * s + 12 * s
	local inner = place("AL_SummonRingInner", root, look(Vector3.new(C.X, focusY - 25 * s, C.Z)), s); inner.Name = "RingInner"
	local outer = place("AL_SummonRingOuter", root, look(Vector3.new(C.X, focusY - 2.6 * s, C.Z)), s); outer.Name = "RingOuter"
	local crown = place("AL_SummonCrown", root, look(Vector3.new(C.X, TOP + 70 * s - 6 * s, C.Z)), s); crown.Name = "Crown"
	local haloPos = C - FACE * 73 * s -- just behind the west stairs (r 66 * s)
	local halo = place("AL_SummonHalo", root, look(Vector3.new(haloPos.X, ground(haloPos.X, haloPos.Z) - 1, haloPos.Z)), s); halo.Name = "Halo"

	local spin = { [outer] = { 3, "Y" }, [inner] = { -5, "Look" }, [crown] = { -2, "Y" }, [halo] = { 1, "Look" } }
	for m, cfg in pairs(spin) do
		centrePivot(m); m:SetAttribute("RPM", cfg[1]); m:SetAttribute("Axis", cfg[2]); CS:AddTag(m, "AL_Spin")
	end
	centrePivot(heart); heart:SetAttribute("Amp", 2); heart:SetAttribute("Speed", 0.25); CS:AddTag(heart, "AL_Float")

	-- ===== VFX
	local vfx = Instance.new("Folder"); vfx.Name = "VFX"; vfx.Parent = root
	local GOLD, CYAN, WHITE = Color3.fromRGB(255, 214, 130), Color3.fromRGB(150, 232, 255), Color3.fromRGB(235, 250, 255)
	runeDisc(vfx, "FloorRune", Vector3.new(C.X, TOP + 0.5, C.Z), 78, GOLD, 1.5) -- decal >= 0.25 over the mandala (z-fight rule)
	runeDisc(vfx, "AltarRune", Vector3.new(C.X, TOP + 3.6 * s + 0.35, C.Z), 22, CYAN, -4)

	-- altar point: the light pillar + rising sparkles; SummonPoint = where a summoned unit appears
	local altar = Instance.new("Part"); altar.Name = "Altar"; altar.Size = Vector3.new(2, 2, 2)
	altar.CFrame = CFrame.new(C.X, TOP + 4.2 * s, C.Z); ghost(altar); altar.Parent = vfx
	local sp = Instance.new("Attachment"); sp.Name = "SummonPoint"; sp.Parent = altar
	local skyA = Instance.new("Attachment"); skyA.Name = "Sky"; skyA.Position = Vector3.new(0, 320, 0); skyA.Parent = altar
	local pillar = Instance.new("Beam"); pillar.Name = "LightPillar"
	pillar.Attachment0 = skyA; pillar.Attachment1 = sp; pillar.Texture = TEX.ray.Value; pillar.TextureMode = Enum.TextureMode.Stretch
	pillar.FaceCamera = true; pillar.LightEmission = 1; pillar.LightInfluence = 0; pillar.Brightness = 2
	pillar.Width0 = 26; pillar.Width1 = 12; pillar.Segments = 1; pillar.Color = ColorSequence.new(WHITE, CYAN)
	pillar.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.75), NumberSequenceKeypoint.new(1, 0.35) })
	pillar.Parent = altar
	emitter(sp, { Name = "Rise", Texture = TEX.sparkle.Value, Rate = 14, Lifetime = NumberRange.new(4, 6),
		Speed = NumberRange.new(6, 11), SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Top,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) }),
		LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(GOLD, CYAN),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90) })

	-- heart: glow + light + SummonFocus (moves with the floating heart)
	local hcf = heart:GetBoundingBox()
	local core = Instance.new("Part"); core.Name = "HeartCore"; core.Size = Vector3.new(2, 2, 2); core.CFrame = CFrame.new(hcf.Position)
	ghost(core); core.Parent = heart -- inside the Heart model, so it bobs with it
	local focus = Instance.new("Attachment"); focus.Name = "SummonFocus"; focus.Parent = core
	local lt = Instance.new("PointLight"); lt.Color = CYAN; lt.Range = 60; lt.Brightness = 2.2; lt.Shadows = false; lt.Parent = core
	emitter(focus, { Name = "Glow", Texture = TEX.glow.Value, Rate = 2, Lifetime = NumberRange.new(2.5, 2.5), Speed = NumberRange.new(0, 0),
		LockedToPart = true, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 30), NumberSequenceKeypoint.new(0.5, 38), NumberSequenceKeypoint.new(1, 30) }),
		LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(CYAN),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.55), NumberSequenceKeypoint.new(1, 1) }) })
	emitter(focus, { Name = "Motes", Texture = TEX.sparkle.Value, Rate = 8, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(2, 4),
		Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) }),
		LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(WHITE, CYAN) })

	-- tethers: each pylon crystal -> the heart (energy beams); pylon tips get small lights
	-- the 8 pylon crystals are ONE mesh, so the tips come from the kit layout (kit_summon.py: r 45, crystal centre 54.5
	-- up, angles pi/8 + k*pi/4 -- symmetric, so the Blender->Roblox axis flip does not matter)
	local tips = 0
	for k = 0, 7 do
		local a = math.pi / 8 + k * math.pi / 4
		local w = CFrame.lookAt(C, C + FACE):PointToWorldSpace(Vector3.new(math.sin(a) * 45, 54.5, math.cos(a) * 45) * s)
		local tip = Instance.new("Part"); tip.Name = "PylonTip" .. (k + 1); tip.Size = Vector3.new(1, 1, 1); tip.CFrame = CFrame.new(w)
		ghost(tip); tip.Parent = vfx
		local a0 = Instance.new("Attachment"); a0.Parent = tip
		local l = Instance.new("PointLight"); l.Color = CYAN; l.Range = 16; l.Brightness = 1.5; l.Shadows = false; l.Parent = tip
		local b = Instance.new("Beam"); b.Name = "Tether"; b.Attachment0 = a0; b.Attachment1 = focus
		b.Texture = TEX.sparkle.Value; b.TextureMode = Enum.TextureMode.Wrap; b.TextureLength = 6; b.TextureSpeed = 1.5
		b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0; b.Width0 = 1.6; b.Width1 = 3; b.CurveSize0 = 8; b.CurveSize1 = -4
		b.Color = ColorSequence.new(CYAN, WHITE); b.Transparency = NumberSequence.new(0.35)
		b.Parent = tip
		tips += 1
	end

	-- halo glow
	local hcf2 = halo:GetBoundingBox()
	local hc = Instance.new("Part"); hc.Name = "HaloCore"; hc.Size = Vector3.new(2, 2, 2); hc.CFrame = CFrame.new(hcf2.Position); ghost(hc); hc.Parent = vfx
	emitter(hc, { Name = "Glow", Texture = TEX.glow.Value, Rate = 1, Lifetime = NumberRange.new(4, 4), Speed = NumberRange.new(0, 0), LockedToPart = true,
		Size = NumberSequence.new(110), LightEmission = 1, LightInfluence = 0, Color = ColorSequence.new(GOLD),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.78), NumberSequenceKeypoint.new(1, 1) }) })

	for _, m in ipairs(root:GetDescendants()) do
		if m:IsA("Model") then m.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled end
	end
	local cleared = removeTreesNear(C, 80 * s) + removeTreesNear(haloPos, 62 * s)
	return ("sanctum at %.0f,%.2f,%.0f top %.2f; heart focus y %.1f; %d tethers; %d trees cleared"):format(C.X, G, C.Z, TOP, focusY, tips, cleared)
end

-- ===================================================================== buildings
-- Each type: count, footprint radius, scale, where ("land" = flat open ground, "coast" = land within 45 studs of water).
local PLAN = {
	{ "AL_Pagoda", 3, 22, 1.0, "land" },
	{ "AL_BahayNaBato", 6, 22, 1.0, "land" },
	{ "AL_Observatory", 2, 24, 1.0, "land" },
	{ "AL_Stupa", 3, 24, 1.0, "land" },
	{ "AL_Lighthouse", 2, 16, 1.0, "coast" },
	{ "AL_Aqueduct", 3, 36, 1.0, "land" },
}
-- never build here: spawn isle, bridge, plaza, temple, the sanctum, arena, citadel, Story Gate, PlayGUI camera foreground
local KEEP = {
	{ Vector3.new(-300, 0, 420), 110 }, { Vector3.new(-300, 0, 260), 70 }, { Vector3.new(-300, 0, 0), 200 },
	{ Vector3.new(-300, 0, -232), 150 }, { SITE, 190 }, { Vector3.new(140, 0, 400), 90 }, { Vector3.new(300, 0, -330), 150 },
	{ Vector3.new(-640, 0, 20), 90 },
}

local function buildings(): string
	local old = St:FindFirstChild("Village"); if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = "Village"; folder.Parent = St
	local vcam = workspace.CurrentCamera
	local saved = vcam.CFrame
	vcam.FieldOfView = 70
	vcam.CFrame = (workspace:FindFirstChild("PersistentScene") :: any).PlayGUICamera.CFrame :: CFrame
	local blocks = {}
	for _, f in ipairs(St:GetChildren()) do
		for _, m in ipairs(f:GetChildren()) do
			if m:IsA("Model") or m:IsA("BasePart") then
				local cf, sz
				if m:IsA("Model") then cf, sz = m:GetBoundingBox() else cf, sz = m.CFrame, m.Size end
				if sz.Magnitude < 1500 then table.insert(blocks, { cf.Position, math.max(sz.X, sz.Z) / 2 }) end
			end
		end
	end
	for _, n in ipairs(workspace:GetChildren()) do
		if n.Name:match("^NPC_") then table.insert(blocks, { n:GetPivot().Position, 12 }) end
	end
	local function free(p: Vector3, r: number): boolean
		for _, k in ipairs(KEEP) do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(k[1].X, 0, k[1].Z)).Magnitude < k[2] + r then return false end
		end
		for _, b in ipairs(blocks) do
			if (Vector3.new(p.X, 0, p.Z) - Vector3.new(b[1].X, 0, b[1].Z)).Magnitude < b[2] + r + 12 then return false end
		end
		-- the user's PlayGUI framing: nothing new may show on screen within 700 studs (centre, top and 4 edges tested
		-- through the real viewport with the camera parked on PlayGUICamera)
		for _, o in ipairs({ Vector3.new(0, 0, 0), Vector3.new(0, 90, 0), Vector3.new(r, 20, 0), Vector3.new(-r, 20, 0), Vector3.new(0, 20, r), Vector3.new(0, 20, -r) }) do
			local q = p + o
			local v, onScreen = vcam:WorldToViewportPoint(q)
			if onScreen and v.Z < 700 then return false end
		end
		return true
	end
	local function flat(p: Vector3, r: number): (boolean, number)
		local lo, hi = math.huge, -math.huge
		for _, o in ipairs({ { 0, 0 }, { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r }, { r * 0.7, r * 0.7 }, { -r * 0.7, r * 0.7 }, { r * 0.7, -r * 0.7 }, { -r * 0.7, -r * 0.7 } }) do
			local y, m = ground(p.X + o[1], p.Z + o[2])
			if m == Enum.Material.Water or y < 30 then return false, 0 end
			lo = math.min(lo, y); hi = math.max(hi, y)
		end
		return hi - lo < 4, lo
	end
	local function nearWater(p: Vector3): boolean
		for a = 0, 7 do
			local d = Vector3.new(math.cos(a * math.pi / 4), 0, math.sin(a * math.pi / 4)) * 45
			local y, m = ground(p.X + d.X, p.Z + d.Z)
			if m == Enum.Material.Water or y < 10 then return true end
		end
		return false
	end
	-- rock / cliff / backdrop AABBs (backdrop is CanQuery off, so no spatial query -- plain box overlap)
	local rocks = {}
	for _, f in ipairs({ Map.Nature.CoastRocks, Map:FindFirstChild("Backdrop") }) do
		for _, d in ipairs(f and f:GetDescendants() or {}) do
			if d:IsA("BasePart") then
				local c, e = d.CFrame, d.Size / 2
				local ext = Vector3.new(
					math.abs(c.RightVector.X) * e.X + math.abs(c.UpVector.X) * e.Y + math.abs(c.LookVector.X) * e.Z,
					math.abs(c.RightVector.Y) * e.X + math.abs(c.UpVector.Y) * e.Y + math.abs(c.LookVector.Y) * e.Z,
					math.abs(c.RightVector.Z) * e.X + math.abs(c.UpVector.Z) * e.Y + math.abs(c.LookVector.Z) * e.Z)
				table.insert(rocks, { c.Position - ext * 0.8, c.Position + ext * 0.8 }) -- 0.8: meshes are rounder than boxes
			end
		end
	end
	local rnd = Random.new(1172)
	local made, trees, report = 0, 0, {}
	for _, row in ipairs(PLAN) do
		local name, count, r, scale, where = row[1], row[2], row[3], row[4], row[5]
		local n, tries = 0, 0
		while n < count and tries < 4000 do
			tries += 1
			local p = Vector3.new(rnd:NextNumber(-1150, 750), 0, rnd:NextNumber(-850, 650))
			local ok, y = flat(p, r)
			if ok and free(p, r) and (where ~= "coast" or nearWater(p)) then
				p = Vector3.new(p.X, y - 0.3, p.Z)
				-- face the plaza (houses/aqueducts read best side-on to the spawn view)
				local toPlaza = (Vector3.new(-300, p.Y, 0) - p)
				local m = place(name, folder, CFrame.lookAt(p, p + toPlaza.Unit), scale)
				-- never into a rock / cliff / backdrop mesh (box test on the placed model, a little shrunk)
				local cf, sz = m:GetBoundingBox()
				local lo, hi = cf.Position - sz * 0.42 + Vector3.new(0, 3, 0), cf.Position + sz * 0.42
				local hit = false
				for _, rk in ipairs(rocks) do
					if lo.X < rk[2].X and hi.X > rk[1].X and lo.Y < rk[2].Y and hi.Y > rk[1].Y and lo.Z < rk[2].Z and hi.Z > rk[1].Z then hit = true; break end
				end
				if hit then m:Destroy(); continue end
				table.insert(blocks, { p, r })
				trees += removeTreesNear(p, r + 6)
				n += 1; made += 1
			end
		end
		table.insert(report, ("%s %d/%d"):format(name, n, count))
	end
	vcam.CFrame = saved
	return ("buildings: %d placed (%s); %d trees cleared"):format(made, table.concat(report, ", "), trees)
end

if SECTION == "post" then return post() end
if SECTION == "sanctum" then return sanctum() end
if SECTION == "buildings" then return buildings() end
return "unknown SECTION " .. SECTION
