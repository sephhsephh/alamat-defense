-- tools/lobby_map/B172_vfx2.luau (B172 phase 4) -- map-wide, NOTICEABLE VFX for the Holy Coast lobby (user: "more cooler
-- vfx around the map everywhere ... make all vfx noticeable"). Paste into execute_luau (Lobby, Edit); re-runnable:
-- rebuilds Workspace.Lobby.Map.VFX2 (+ the per-tree / per-shard / per-keeper emitters it owns, all named "VFX2_*").
-- Textures: ServerStorage.DevTools.LobbyMap.B172Protos.VFXTex (white-on-alpha; tools/maps/lobby/vfx_kit2.py).
-- Tricks: flat glowing decals = particles with Orientation VelocityPerpendicular + Speed 0.25 + LockedToPart (shadow
-- proof); Size = full width; LightEmission 1 + LightInfluence 0 = self-lit. Flipbooks are Grid2x2.
local SECTION = "all" -- or one of: trees, motes, butterflies, birds, godrays, beacons, falls, shards, sanctum, story, snow, glints
local Map = workspace.Lobby.Map
local TEXF = game.ServerStorage.DevTools.LobbyMap.B172Protos.VFXTex
local function T(n: string): string return (TEXF:FindFirstChild(n) :: StringValue).Value end
local rnd = Random.new(4172)

local rpT = RaycastParams.new()
rpT.FilterType = Enum.RaycastFilterType.Include
rpT.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): (number, Enum.Material?)
	local r = workspace:Raycast(Vector3.new(x, 700, z), Vector3.new(0, -900, 0), rpT)
	return if r then r.Position.Y else -99, if r then r.Material else nil
end

local root = Map:FindFirstChild("VFX2") or Instance.new("Folder")
root.Name = "VFX2"; root.Parent = Map
local function folder(name: string): Folder
	local f = root:FindFirstChild(name); if f then f:Destroy() end
	f = Instance.new("Folder"); f.Name = name; f.Parent = root
	return f :: Folder
end
local function anchor(parent: Instance, name: string, cf: CFrame, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size or Vector3.new(1, 1, 1); p.CFrame = cf
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false; p.Transparency = 1
	p.Parent = parent
	return p
end
local function emitter(parent: Instance, name: string, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.LightInfluence = 0
	for k, v in pairs(props) do (e :: any)[k] = v end
	e.Parent = parent
	return e
end
local function NS(...: number): NumberSequence
	local v = { ... }
	if #v == 1 then return NumberSequence.new(v[1]) end
	local kp = {}
	for i, x in ipairs(v) do table.insert(kp, NumberSequenceKeypoint.new((i - 1) / (#v - 1), x)) end
	return NumberSequence.new(kp)
end
local function clearNamed(container: Instance, prefix: string)
	for _, d in ipairs(container:GetDescendants()) do
		if d.Name:sub(1, #prefix) == prefix then d:Destroy() end
	end
end
-- land sample points: open ground (terrain y 30..90), away from the plaza/spawn decks
local function landPoints(step: number, jitter: number): { Vector3 }
	local pts = {}
	for x = -1850, 760, step do
		for z = -1000, 300, step do
			local px, pz = x + rnd:NextNumber(-jitter, jitter), z + rnd:NextNumber(-jitter, jitter)
			local y, m = ground(px, pz)
			if y > 30 and y < 95 and m ~= Enum.Material.Water then table.insert(pts, Vector3.new(px, y, pz)) end
		end
	end
	return pts
end

local PINK, GOLD, WARM, CYAN, WHITE = Color3.fromRGB(255, 190, 215), Color3.fromRGB(255, 220, 140), Color3.fromRGB(255, 236, 190), Color3.fromRGB(150, 232, 255), Color3.fromRGB(245, 250, 255)
local report = {}

-- ===================================================================== trees: petals / golden leaves / green leaves
local function trees()
	clearNamed(Map.Nature.Groves, "VFX2_")
	local n = { petal = 0, gold = 0, leaf = 0 }
	for _, t in ipairs(Map.Nature.Groves:GetDescendants()) do
		if t:IsA("BasePart") and t.Name:match("^Canopy") then
			local sa = t:FindFirstChildOfClass("SurfaceAppearance")
			local c = sa and sa.Color or Color3.new(0.3, 0.6, 0.3)
			local kind = if c.R > 0.9 and c.B > 0.8 then "petal" elseif c.R > 0.9 then "gold" else "leaf"
			emitter(t, "VFX2_Fall", {
				Texture = T(if kind == "leaf" then "leaf" else "petal"), Shape = Enum.ParticleEmitterShape.Box,
				EmissionDirection = Enum.NormalId.Bottom, Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(40, 40),
				Acceleration = Vector3.new(1.2, -1.6, 0.6), Drag = 0.6, Lifetime = NumberRange.new(7, 11),
				Rate = if kind == "leaf" then 0.6 else 2.4, Size = NS(1.3, 1.1),
				Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
				Color = ColorSequence.new(if kind == "petal" then PINK elseif kind == "gold" then GOLD else Color3.fromRGB(150, 200, 110)),
				LightInfluence = 0.6, Transparency = NS(0, 0, 0.1, 1),
			})
			n[kind] += 1
		end
	end
	table.insert(report, ("trees: %d petal, %d gold, %d leaf"):format(n.petal, n.gold, n.leaf))
end

-- ===================================================================== motes: golden fireflies drifting up over the land
local function motes()
	local f = folder("Motes")
	local pts = landPoints(150, 50)
	for i, p in ipairs(pts) do
		local a = anchor(f, "Motes" .. i, CFrame.new(p + Vector3.new(0, 8, 0)), Vector3.new(120, 14, 120))
		emitter(a, "Fireflies", {
			Texture = T("firefly"), Shape = Enum.ParticleEmitterShape.Box, Rate = 5,
			Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.6, 2), SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 0.4, 0), Size = NS(0, 1.6, 1.4, 0), LightEmission = 1, Brightness = 4,
			Color = ColorSequence.new(GOLD, WARM), Transparency = NS(1, 0, 0.1, 1),
		})
	end
	table.insert(report, ("motes: %d fields"):format(#pts))
end

-- ===================================================================== butterflies (flipbook) over the grass
local function butterflies()
	local f = folder("Butterflies")
	local pts = landPoints(260, 90)
	local tints = { WHITE, PINK, CYAN, GOLD, Color3.fromRGB(200, 170, 255) }
	for i, p in ipairs(pts) do
		local a = anchor(f, "Butterflies" .. i, CFrame.new(p + Vector3.new(0, 5, 0)), Vector3.new(70, 6, 70))
		emitter(a, "Butterflies", {
			Texture = T("butterfly"), FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop, FlipbookFramerate = NumberRange.new(10, 14),
			Shape = Enum.ParticleEmitterShape.Box, Rate = 0.7, Lifetime = NumberRange.new(8, 12),
			Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(180, 60), Acceleration = Vector3.new(0, 0.3, 0),
			Size = NS(1.6), LightEmission = 0.4, LightInfluence = 0.5, Color = ColorSequence.new(tints[(i % #tints) + 1]),
			Transparency = NS(1, 0, 0, 1), Rotation = NumberRange.new(-20, 20),
		})
	end
	table.insert(report, ("butterflies: %d fields"):format(#pts))
end

-- ===================================================================== seabirds gliding over the sea
local function birds()
	local f = folder("Birds")
	local spots = { Vector3.new(-300, 120, 650), Vector3.new(-1100, 140, 520), Vector3.new(400, 130, 650), Vector3.new(-800, 160, 900), Vector3.new(-1700, 150, 300) }
	for i, p in ipairs(spots) do
		local a = anchor(f, "Birds" .. i, CFrame.new(p) * CFrame.Angles(0, rnd:NextNumber(0, math.pi * 2), 0), Vector3.new(500, 40, 500))
		emitter(a, "Gulls", {
			Texture = T("bird"), FlipbookLayout = Enum.ParticleFlipbookLayout.Grid2x2,
			FlipbookMode = Enum.ParticleFlipbookMode.Loop, FlipbookFramerate = NumberRange.new(5, 7),
			Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Right, Rate = 0.25,
			Lifetime = NumberRange.new(22, 30), Speed = NumberRange.new(16, 24), SpreadAngle = Vector2.new(12, 4),
			Size = NS(5), LightEmission = 0, LightInfluence = 1, Color = ColorSequence.new(WHITE),
			Transparency = NS(1, 0, 0, 1),
		})
	end
	table.insert(report, ("birds: %d flocks"):format(#spots))
end

-- ===================================================================== god rays: huge warm shafts from the sky
local function godrays()
	local f = folder("GodRays")
	local spots = {
		Vector3.new(-300, 0, -232), Vector3.new(-940, 0, -120), Vector3.new(-1500, 0, -200), Vector3.new(300, 0, -330),
		Vector3.new(-300, 0, 420), Vector3.new(-700, 0, -500), Vector3.new(-1250, 0, -480), Vector3.new(-1150, 0, 40),
		Vector3.new(140, 0, 400), Vector3.new(-520, 0, 120), Vector3.new(-60, 0, -560), Vector3.new(-1650, 0, -600),
	}
	local sunDir = Vector3.new(0.45, 1, 0.25).Unit -- shafts lean like the late-afternoon sun
	for i, s in ipairs(spots) do
		local y = math.max(ground(s.X, s.Z), 4)
		local foot = Vector3.new(s.X, y, s.Z)
		local top = foot + sunDir * 650
		local a = anchor(f, "Ray" .. i, CFrame.new(top))
		local a0 = Instance.new("Attachment"); a0.Parent = a
		local a1 = Instance.new("Attachment"); a1.Parent = a; a1.WorldPosition = foot
		local b = Instance.new("Beam")
		b.Attachment0 = a0; b.Attachment1 = a1; b.Texture = T("godray"); b.TextureMode = Enum.TextureMode.Stretch
		b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0; b.Brightness = 1.6; b.Segments = 1
		b.Width0 = 150; b.Width1 = 230; b.Color = ColorSequence.new(WARM)
		b.Transparency = NS(0.9, 0.62, 0.72)
		b.Parent = a
	end
	table.insert(report, ("godrays: %d"):format(#spots))
end

-- ===================================================================== station beacons: glyph floor, pulse rings, sparkle column, light pillar
local BEACON = {
	NPC_Summon = CYAN, NPC_Story = Color3.fromRGB(190, 240, 255), NPC_Shop = GOLD, NPC_Craft = Color3.fromRGB(255, 170, 90),
	NPC_Ascension = Color3.fromRGB(200, 160, 255), NPC_Evolve = Color3.fromRGB(255, 205, 90), NPC_StatReroll = Color3.fromRGB(120, 180, 255),
	NPC_TraitReroll = Color3.fromRGB(190, 225, 255), NPC_Challenge = Color3.fromRGB(255, 120, 90), NPC_Guide = WHITE,
}
local function beacons()
	local f = folder("Beacons")
	local n = 0
	for name, col in pairs(BEACON) do
		local npc = workspace:FindFirstChild(name) or Map.Parent:FindFirstChild(name)
		if npc and npc:FindFirstChild("Root") then
			n += 1
			local base = (npc.Root :: BasePart).Position - Vector3.new(0, 0.5, 0)
			local a = anchor(f, name, CFrame.new(base + Vector3.new(0, 0.6, 0)))
			for i = 0, 1 do
				emitter(a, "Glyph" .. i, {
					Texture = T(if n % 2 == 0 then "glyph_sun" else "glyph_hex"), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
					EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.25), LockedToPart = true,
					Lifetime = NumberRange.new(8), Rate = 0.125, Size = NS(26), LightEmission = 1, Brightness = 3,
					Color = ColorSequence.new(col), Transparency = NS(1, 0.05, 0.05, 1), ZOffset = 0.5,
					Rotation = NumberRange.new(i * 30), RotSpeed = NumberRange.new(if i == 0 then 14 else -9),
				})
			end
			emitter(a, "Pulse", {
				Texture = T("pulse"), Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
				EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.25), LockedToPart = true,
				Lifetime = NumberRange.new(2.6), Rate = 0.5, Size = NS(6, 40), LightEmission = 1, Brightness = 3,
				Color = ColorSequence.new(col), Transparency = NS(0.1, 0.4, 1), ZOffset = 0.6,
			})
			emitter(a, "Rise", {
				Texture = T("sparkle"), Shape = Enum.ParticleEmitterShape.Cylinder, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
				EmissionDirection = Enum.NormalId.Top, Rate = 10, Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(5, 9),
				Size = NS(1.4, 0), LightEmission = 1, Brightness = 3, Color = ColorSequence.new(col, WHITE),
				Transparency = NS(0, 1), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-90, 90),
			})
			a.Size = Vector3.new(14, 1, 14) -- the Rise cylinder's radius
			if name == "NPC_Summon" then -- B172 p5: the summon beacon streams with the sanctum (the cutscene pulses it)
				local S = Map.Structures:FindFirstChild("SummonSanctum")
				local fx = S and S:FindFirstChild("AmbientFX")
				if fx then local old = fx:FindFirstChild("Beacon"); if old then old:Destroy() end; a.Name = "Beacon"; a.Parent = fx end
			end
			local sky = Instance.new("Attachment"); sky.Name = "Sky"; sky.Position = Vector3.new(0, 300, 0); sky.Parent = a
			local foot = Instance.new("Attachment"); foot.Name = "Foot"; foot.Parent = a
			local b = Instance.new("Beam")
			b.Attachment0 = foot; b.Attachment1 = sky; b.Texture = T("ray"); b.TextureMode = Enum.TextureMode.Stretch
			b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0; b.Brightness = 2.5; b.Segments = 1
			b.Width0 = 8; b.Width1 = 3; b.Color = ColorSequence.new(col); b.Transparency = NS(0.25, 0.65, 1)
			b.Parent = a
		end
	end
	table.insert(report, ("beacons: %d keepers"):format(n))
end

-- ===================================================================== waterfalls: mist + spray glints at the plunge
local function falls()
	local f = folder("Falls")
	local n = 0
	for _, p in ipairs((Map.Structures:FindFirstChild("Falls") or Instance.new("Folder")):GetDescendants()) do
		if p:IsA("BasePart") and p.Name == "Plunge" then
			n += 1
			local a = anchor(f, "Mist" .. n, CFrame.new(p.Position + Vector3.new(0, 2, 0)), Vector3.new(p.Size.X, 2, p.Size.Z))
			emitter(a, "Mist", {
				Texture = T("mist"), Shape = Enum.ParticleEmitterShape.Box, Rate = 14, Lifetime = NumberRange.new(3, 5),
				Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, 1.5, 0),
				Size = NS(8, 22), LightEmission = 0.35, LightInfluence = 0.6, Color = ColorSequence.new(WHITE),
				Transparency = NS(0.55, 0.75, 1), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
			})
			emitter(a, "Spray", {
				Texture = T("flare"), Shape = Enum.ParticleEmitterShape.Box, Rate = 10, Lifetime = NumberRange.new(0.4, 0.8),
				Speed = NumberRange.new(6, 12), SpreadAngle = Vector2.new(70, 70), Size = NS(2.5, 0), LightEmission = 1,
				Brightness = 3, Color = ColorSequence.new(WHITE), Transparency = NS(0, 1),
			})
		end
	end
	table.insert(report, ("falls: %d plunges"):format(n))
end

-- ===================================================================== floating shards: sparkle aura + glints
local function shards()
	local CS = game:GetService("CollectionService")
	local n = 0
	for _, m in ipairs(CS:GetTagged("AL_Float")) do
		local pp = m:IsA("Model") and m.PrimaryPart
		local host = pp or m:FindFirstChildWhichIsA("BasePart", true)
		if host then
			clearNamed(host, "VFX2_")
			emitter(host, "VFX2_Aura", {
				Texture = T("sparkle"), Shape = Enum.ParticleEmitterShape.Sphere, Rate = 4, Lifetime = NumberRange.new(1.5, 2.5),
				Speed = NumberRange.new(1, 3), Size = NS(1.2, 0), LightEmission = 1, Brightness = 3,
				Color = ColorSequence.new(CYAN, WHITE), Transparency = NS(0, 1), LockedToPart = false,
			})
			emitter(host, "VFX2_Glint", {
				Texture = T("flare"), Rate = 0.4, Lifetime = NumberRange.new(0.6), Speed = NumberRange.new(0),
				Size = NS(0, 9, 0), LightEmission = 1, Brightness = 4, Color = ColorSequence.new(WHITE),
				Rotation = NumberRange.new(0, 60), LockedToPart = true,
			})
			n += 1
		end
	end
	table.insert(report, ("shards: %d"):format(n))
end

-- ===================================================================== sanctum: spirit wisps spiralling up the dais
local function sanctum()
	-- B172 p5: lives INSIDE the sanctum (AmbientFX) so it streams with it (Persistent) for the summon cutscene
	local S = Map.Structures:FindFirstChild("SummonSanctum")
	if not S then return end
	local f = S:FindFirstChild("AmbientFX") or Instance.new("Folder")
	f.Name = "AmbientFX"; f.Parent = S
	for _, n in ipairs({ "Wisps", "Halo" }) do local o = f:FindFirstChild(n); if o then o:Destroy() end end
	local cf, sz = (S:FindFirstChild("Dais") :: Model):GetBoundingBox()
	local a = anchor(f, "Wisps", CFrame.new(cf.X, cf.Y - sz.Y / 2 + 14, cf.Z), Vector3.new(110, 1, 110))
	emitter(a, "Wisps", {
		Texture = T("wisp"), Shape = Enum.ParticleEmitterShape.Cylinder, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Orientation = Enum.ParticleOrientation.VelocityParallel, EmissionDirection = Enum.NormalId.Top, Rate = 8,
		Lifetime = NumberRange.new(3.5, 5), Speed = NumberRange.new(10, 16), Size = NS(3, 5, 0), LightEmission = 1,
		Brightness = 3, Color = ColorSequence.new(CYAN, WHITE), Transparency = NS(1, 0, 0.2, 1),
	})
	local g = anchor(f, "Halo", CFrame.new(cf.X, cf.Y - sz.Y / 2 + 1, cf.Z), Vector3.new(200, 2, 200))
	emitter(g, "GroundMist", {
		Texture = T("mist"), Shape = Enum.ParticleEmitterShape.Box, Rate = 6, Lifetime = NumberRange.new(6, 9),
		Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 10), Size = NS(26, 40), LightEmission = 0.5,
		Color = ColorSequence.new(CYAN), Transparency = NS(1, 0.82, 1), Rotation = NumberRange.new(0, 360),
	})
	table.insert(report, "sanctum: wisps + ground mist")
end

-- ===================================================================== story gate: wisps out of the veil + ground mist
local function story()
	local f = folder("Story")
	local veil = Map.Structures.StoryGate:FindFirstChild("AL_PortalVeil")
	if not veil then return end
	local cf, sz = veil:GetBoundingBox()
	local look = (Map.Structures.StoryGate.AL_StoryGate :: Model):GetPivot().LookVector
	local a = anchor(f, "VeilWisps", CFrame.lookAt(cf.Position, cf.Position + look), Vector3.new(sz.X * 0.8, sz.Y * 0.8, 2))
	emitter(a, "Wisps", {
		Texture = T("wisp"), Shape = Enum.ParticleEmitterShape.Box, Orientation = Enum.ParticleOrientation.VelocityParallel,
		EmissionDirection = Enum.NormalId.Front, Rate = 10, Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(10, 18),
		SpreadAngle = Vector2.new(25, 25), Size = NS(3, 5, 0), LightEmission = 1, Brightness = 3,
		Color = ColorSequence.new(CYAN, WHITE), Transparency = NS(1, 0, 0.2, 1),
	})
	local base = Vector3.new(cf.X, ground(cf.X, cf.Z) + 1, cf.Z) + look * 40
	local m = anchor(f, "GateMist", CFrame.new(base), Vector3.new(140, 2, 140))
	emitter(m, "GroundMist", {
		Texture = T("mist"), Shape = Enum.ParticleEmitterShape.Box, Rate = 6, Lifetime = NumberRange.new(6, 9),
		Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 10), Size = NS(26, 40), LightEmission = 0.5,
		Color = ColorSequence.new(Color3.fromRGB(200, 240, 255)), Transparency = NS(1, 0.82, 1), Rotation = NumberRange.new(0, 360),
	})
	table.insert(report, "story: veil wisps + ground mist")
end

-- ===================================================================== holy snow: slow falling light over plaza + spawn
local function snow()
	local f = folder("HolySnow")
	for i, c in ipairs({ Vector3.new(-300, 230, 0), Vector3.new(-300, 230, 400), Vector3.new(-300, 250, -260), Vector3.new(-940, 240, -120) }) do
		local a = anchor(f, "Snow" .. i, CFrame.new(c), Vector3.new(380, 2, 380))
		emitter(a, "Motes", {
			Texture = T("firefly"), Shape = Enum.ParticleEmitterShape.Box, EmissionDirection = Enum.NormalId.Bottom,
			Rate = 22, Lifetime = NumberRange.new(40, 55), Speed = NumberRange.new(3, 5), SpreadAngle = Vector2.new(15, 15),
			Acceleration = Vector3.new(0.4, 0, 0.2), Size = NS(0.9, 1.1, 0.6), LightEmission = 1, Brightness = 3,
			Color = ColorSequence.new(WARM), Transparency = NS(1, 0.1, 0.2, 1),
		})
	end
	table.insert(report, "snow: 4 fields")
end

-- ===================================================================== sea glints: sparkling water around the spawn bay
local function glints()
	local f = folder("SeaGlints")
	for i, c in ipairs({ Vector3.new(-300, 4.4, 300), Vector3.new(-650, 4.4, 330), Vector3.new(50, 4.4, 300), Vector3.new(-1000, 4.4, 300), Vector3.new(-300, 4.4, 620) }) do
		local a = anchor(f, "Glints" .. i, CFrame.new(c), Vector3.new(320, 0.5, 260))
		emitter(a, "Glints", {
			Texture = T("flare"), Shape = Enum.ParticleEmitterShape.Box, Rate = 26, Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(0), Size = NS(0, 3, 0), LightEmission = 1, Brightness = 4,
			Color = ColorSequence.new(WHITE), Rotation = NumberRange.new(0, 60),
		})
	end
	table.insert(report, "glints: 5 sea fields")
end

local ALL = { trees = trees, motes = motes, butterflies = butterflies, birds = birds, godrays = godrays, beacons = beacons,
	falls = falls, shards = shards, sanctum = sanctum, story = story, snow = snow, glints = glints }
if SECTION == "all" then
	for _, k in ipairs({ "trees", "motes", "butterflies", "birds", "godrays", "beacons", "falls", "shards", "sanctum", "story", "snow", "glints" }) do ALL[k]() end
else
	ALL[SECTION]()
end
return table.concat(report, " | ")
