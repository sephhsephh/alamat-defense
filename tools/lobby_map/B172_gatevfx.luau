-- B172 phase 2: light rays + rune circles at the Lobby gates. Paste into execute_luau (Lobby, Edit). Re-runnable:
-- rebuilds Workspace.Lobby.Map.Structures.GateVFX. Textures = B172Protos.VFXTex (white-on-alpha, tinted here).
-- Rune circles are Models tagged AL_Spin (Axis "Y") -> StarterPlayerScripts.LobbyAmbient turns them.
local CS = game:GetService("CollectionService")
local Map = workspace.Lobby.Map
local St = Map.Structures
local TEX = game.ServerStorage.DevTools.LobbyMap.B172Protos.VFXTex
local RUNE, RAY = TEX.rune.Value, TEX.ray.Value

local old = St:FindFirstChild("GateVFX")
if old then old:Destroy() end
local root = Instance.new("Folder")
root.Name = "GateVFX"
root.Parent = St

local GOLD = Color3.fromRGB(255, 214, 130)
local CYAN = Color3.fromRGB(150, 232, 255)
local SUN = Color3.fromRGB(255, 238, 200)

-- floor = terrain or the deck colliders (never a gate lintel, tree or keeper), but never below the gate's own base
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Terrain, Map.Core }
local function ground(x: number, z: number, top: number, base: number): number
	local r = workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -top - 50, 0), rp)
	return math.max(r and r.Position.Y or base, base)
end

local function ghost(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
end

-- flat spinning rune disc lying on the floor at pos
local function runeCircle(parent: Instance, name: string, pos: Vector3, diameter: number, color: Color3, rpm: number, light: boolean, lift: number?)
	local m = Instance.new("Model")
	m.Name = name
	local disc = Instance.new("Part")
	disc.Name = "Disc"
	disc.Size = Vector3.new(diameter, 0.2, diameter)
	disc.CFrame = CFrame.new(pos + Vector3.new(0, lift or 1.05, 0)) -- above terrain grass
	ghost(disc)
	disc.Parent = m
	local d = Instance.new("Decal")
	d.Texture = RUNE
	d.Face = Enum.NormalId.Top
	d.Color3 = color
	d.Transparency = 0
	d.Parent = disc
	if light then
		local l = Instance.new("PointLight")
		l.Color = color
		l.Range = math.min(diameter * 0.8, 50)
		l.Brightness = 1.2
		l.Shadows = false
		l.Parent = disc
	end
	m.PrimaryPart = disc
	m:SetAttribute("RPM", rpm)
	m:SetAttribute("Axis", "Y")
	m.Parent = parent
	CS:AddTag(m, "AL_Spin")
	return m
end

-- slanted god-ray beams: from high behind/above `top` down to the floor in front, spread sideways
local function rays(parent: Instance, name: string, top: Vector3, foot: Vector3, side: Vector3, count: number, spread: number, width: number, color: Color3)
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(top)
	ghost(anchor)
	anchor.Parent = parent
	for i = 1, count do
		local k = count == 1 and 0 or ((i - 1) / (count - 1) - 0.5) * 2
		local a0 = Instance.new("Attachment")
		a0.WorldPosition = top + side * (k * spread * 0.4)
		a0.Parent = anchor
		local a1 = Instance.new("Attachment")
		a1.WorldPosition = foot + side * (k * spread)
		a1.Parent = anchor
		local b = Instance.new("Beam")
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Texture = RAY
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureSpeed = 0.05 + i * 0.02
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = 1.5
		b.Color = ColorSequence.new(color)
		b.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(0.6, 0.7),
			NumberSequenceKeypoint.new(1, 1),
		})
		b.Width0 = width * (0.6 + 0.15 * (i % 3))
		b.Width1 = width * (1.3 + 0.2 * (i % 2))
		b.Segments = 1
		b.Parent = anchor
	end
	return anchor
end

local made = 0
local function site(name: string, model: Model, frontDist: number, runeD: number, color: Color3, rayCount: number, rayWidth: number, light: boolean, lift: number?)
	local cf, size = model:GetBoundingBox()
	local look = model:GetPivot().LookVector
	look = Vector3.new(look.X, 0, look.Z).Unit
	local side = look:Cross(Vector3.yAxis).Unit
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = root
	local fx, fz = cf.X + look.X * frontDist, cf.Z + look.Z * frontDist
	local fy = ground(fx, fz, cf.Y + size.Y, cf.Y - size.Y / 2)
	if runeD > 0 then
		runeCircle(folder, "RuneCircle", Vector3.new(fx, fy, fz), runeD, color, 2, light, lift)
	end
	local top = cf.Position + Vector3.new(0, size.Y * 0.55, 0) - look * (size.Z * 2)
	rays(folder, "Rays", top, Vector3.new(fx, fy, fz) + look * (runeD * 0.25), side, rayCount, size.X * 0.45, rayWidth, SUN)
	made += 1
end

-- Story Gate: cyan rune ring under the keeper + a smaller one inside the portal arch; warm rays through the arch
local story = St.StoryGate.AL_StoryGate
site("StoryGate", story, 34, 64, CYAN, 4, 26, true)
do
	local cf, size = story:GetBoundingBox()
	local look = story:GetPivot().LookVector
	local p = Vector3.new(cf.X + look.X * 2, 0, cf.Z + look.Z * 2)
	runeCircle(root.StoryGate, "ArchRune", Vector3.new(p.X, ground(p.X, p.Z, cf.Y, cf.Y - size.Y / 2), p.Z), 40, CYAN, -3, false)
end
-- Sun Gate on the spawn deck (faces the rotunda): gold rune just inside it
site("SpawnSunGate", St.Rotunda.AL_SunGate, 16, 26, GOLD, 3, 12, false, 0.15)
-- Citadel gate
site("CitadelGate", St.Citadel.AL_SunGate, 24, 34, GOLD, 3, 14, true)
-- Colossal Sun Gate in the far sea: rays only (no floor), huge
do
	local g = St.Colossal.AL_SunGate
	local cf, size = g:GetBoundingBox()
	local look = g:GetPivot().LookVector
	local side = Vector3.new(look.X, 0, look.Z).Unit:Cross(Vector3.yAxis).Unit
	local f = Instance.new("Folder")
	f.Name = "ColossalGate"
	f.Parent = root
	rays(f, "Rays", cf.Position + Vector3.new(0, size.Y * 0.5, 0) - look * 120, cf.Position + look * 260 + Vector3.new(0, -size.Y * 0.45, 0), side, 4, size.X * 0.5, 120, SUN)
	made += 1
end

local spins = 0
for _, m in root:GetDescendants() do
	if m:HasTag("AL_Spin") then spins += 1 end
end
return ("GateVFX: %d site(s), %d rune circle(s)"):format(made, spins)
