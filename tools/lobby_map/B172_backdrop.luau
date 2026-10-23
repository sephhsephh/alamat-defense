-- tools/lobby_map/B172_backdrop.luau (B172) -- THE END OF THE MAP: giant kitbashed mountains on the land rim
-- and colossal sea stacks across the southern horizon (user: "huge, huge structures around it for depth").
-- Method = docs/design/stylized-environment.md section 4: a few rock meshes, copied, scaled 5-20x, yawed,
-- clumped (core peak + flank peaks + foothills), sunk into the ridge/sea. Haze does the rest.
-- Paste into execute_luau (Lobby, Edit). Re-running rebuilds Workspace.Lobby.Map.Backdrop.{Mountains,SeaStacks}.
-- Prototypes: ServerStorage.DevTools.LobbyMap.B172Protos.Rocks (clones of the rock packs already in the place).
local SS = game:GetService("ServerStorage")
local map = workspace.Lobby.Map
local protos = SS.DevTools.LobbyMap.B172Protos.Rocks
local backdrop = map:FindFirstChild("Backdrop") or Instance.new("Folder")
backdrop.Name = "Backdrop"; backdrop.Parent = map

local MAIN_C, MAIN_R = Vector2.new(-300, -300), Vector2.new(1250, 760)
local BAY_C = Vector2.new(-300, 420)
local TALL = { "SM_Rocks_09", "Rocks_07", "SM_Rocks_05", "SM_Rocks_08", "SM_Rocks_11" }
local WIDE = { "SM_Rocks_03", "SM_Rocks_02", "SM_Rocks_03", "Rocks_05" }
-- aerial perspective: SurfaceAppearance rocks get a tint per depth layer (SM_Rocks keep their pale painted texture)
local NEAR_TINT, FAR_TINT, SEA_TINT = Color3.fromRGB(232, 222, 206), Color3.fromRGB(176, 184, 214), Color3.fromRGB(190, 200, 222)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): number
	local r = workspace:Raycast(Vector3.new(x, 1200, z), Vector3.new(0, -1300, 0), rayParams)
	return if r then r.Position.Y else 0
end

-- one rock: `name` scaled so its HEIGHT is h (proportional), yaw, bottom sunk `sink` of h below baseY
local function rock(folder: Folder, name: string, x: number, z: number, h: number, yaw: number, baseY: number, sink: number, flip: boolean, tint: Color3?)
	local src = protos:FindFirstChild(name)
	if not src then return end
	local p = src:Clone()
	local k = h / src.Size.Y
	local size = src.Size * k
	if size.X > 2048 or size.Z > 2048 then size *= 2048 / math.max(size.X, size.Z) end
	p.Size = size
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.CastShadow = false
	p.CollisionFidelity = Enum.CollisionFidelity.Box
	local cy = baseY - sink * size.Y + size.Y / 2
	p.CFrame = CFrame.new(x, cy, z) * CFrame.Angles(if flip then math.pi else 0, yaw, 0)
	local sa = p:FindFirstChildOfClass("SurfaceAppearance")
	if sa and tint then sa.Color = tint end
	p.Parent = folder
end

local function clump(folder: Folder, rnd: Random, cx: number, cz: number, H: number, tangent: Vector2, inward: Vector2, tint: Color3, foothills: boolean)
	local gy = ground(cx, cz)
	-- core peak
	rock(folder, TALL[rnd:NextInteger(1, #TALL)], cx, cz, H, rnd:NextNumber(0, 2 * math.pi), gy, 0.32, false, tint)
	-- flank peaks along the ridge
	for i = 1, rnd:NextInteger(2, 3) do
		local side = if i % 2 == 0 then -1 else 1
		local off = tangent * side * H * rnd:NextNumber(0.35, 0.7) + inward * rnd:NextNumber(-0.1, 0.15) * H
		local x, z = cx + off.X, cz + off.Y
		rock(folder, TALL[rnd:NextInteger(1, #TALL)], x, z, H * rnd:NextNumber(0.45, 0.72), rnd:NextNumber(0, 2 * math.pi), ground(x, z), 0.3, rnd:NextNumber() < 0.3, tint)
	end
	-- foothills on the inner side
	if not foothills then return end
	for _ = 1, rnd:NextInteger(2, 3) do
		local off = inward * H * rnd:NextNumber(0.25, 0.55) + tangent * rnd:NextNumber(-0.6, 0.6) * H
		local x, z = cx + off.X, cz + off.Y
		rock(folder, WIDE[rnd:NextInteger(1, #WIDE)], x, z, H * rnd:NextNumber(0.12, 0.22), rnd:NextNumber(0, 2 * math.pi), ground(x, z), 0.5, false, tint)
	end
end

-- Mountains: along the land rim from the west arm, over the north, to the east arm
local mtn = backdrop:FindFirstChild("Mountains"); if mtn then mtn:Destroy() end
mtn = Instance.new("Folder"); mtn.Name = "Mountains"; mtn.Parent = backdrop
local rnd = Random.new(172)
local n = 0
for deg = 158, 382, 8 do
	local t = math.rad(deg)
	local k = rnd:NextNumber(0.88, 0.95)
	local cx = MAIN_C.X + MAIN_R.X * math.cos(t) * k
	local cz = MAIN_C.Y + MAIN_R.Y * math.sin(t) * k
	-- tallest behind the temple (north, deg ~270), lower toward the sea ends
	local north = math.clamp(-math.sin(t), 0, 1)
	local H = (400 + 350 * north) * rnd:NextNumber(0.85, 1.15)
	local tangent = Vector2.new(-MAIN_R.X * math.sin(t), MAIN_R.Y * math.cos(t)).Unit
	local inward = (MAIN_C - Vector2.new(cx, cz)).Unit
	clump(mtn, rnd, cx, cz, H, tangent, inward, NEAR_TINT, true)
	n += 1
end
-- far range: a second, taller, cooler ring out past the rim (parallax depth through the haze)
for deg = 162, 378, 12 do
	local t = math.rad(deg + rnd:NextNumber(-4, 4))
	local k = rnd:NextNumber(1.12, 1.25)
	local cx = MAIN_C.X + MAIN_R.X * math.cos(t) * k
	local cz = MAIN_C.Y + MAIN_R.Y * math.sin(t) * k
	local north = math.clamp(-math.sin(t), 0, 1)
	local H = (850 + 450 * north) * rnd:NextNumber(0.85, 1.1)
	-- keep clear of the user's own south area (Workspace root, x -700..200, z < -1450)
	if cx > -950 and cx < 450 and cz < -1000 then cz = -1000; H = math.min(H, 1000) end
	local tangent = Vector2.new(-MAIN_R.X * math.sin(t), MAIN_R.Y * math.cos(t)).Unit
	local inward = (MAIN_C - Vector2.new(cx, cz)).Unit
	clump(mtn, rnd, cx, cz, H, tangent, inward, FAR_TINT, false)
	n += 1
end

-- Sea stacks: a broken ring of colossal pillars across the southern horizon (the sea-side end of the map)
local sea = backdrop:FindFirstChild("SeaStacks"); if sea then sea:Destroy() end
sea = Instance.new("Folder"); sea.Name = "SeaStacks"; sea.Parent = backdrop
local m = 0
for deg = 8, 172, 11 do
	local t = math.rad(deg)
	local r = rnd:NextNumber(1350, 1750)
	local cx, cz = BAY_C.X + math.cos(t) * r * 1.25, BAY_C.Y + math.sin(t) * r
	local H = rnd:NextNumber(320, 640)
	local inward = (BAY_C - Vector2.new(cx, cz)).Unit
	local tangent = Vector2.new(-inward.Y, inward.X)
	rock(sea, TALL[rnd:NextInteger(1, #TALL)], cx, cz, H, rnd:NextNumber(0, 2 * math.pi), 4, 0.18, false, SEA_TINT)
	for _ = 1, rnd:NextInteger(1, 3) do
		local off = tangent * rnd:NextNumber(-0.6, 0.6) * H + inward * rnd:NextNumber(-0.2, 0.3) * H
		rock(sea, TALL[rnd:NextInteger(1, #TALL)], cx + off.X, cz + off.Y, H * rnd:NextNumber(0.35, 0.7), rnd:NextNumber(0, 2 * math.pi), 4, 0.15, rnd:NextNumber() < 0.35, SEA_TINT)
	end
	rock(sea, WIDE[rnd:NextInteger(1, #WIDE)], cx + inward.X * H * 0.25, cz + inward.Y * H * 0.25, H * 0.18, rnd:NextNumber(0, 2 * math.pi), 4, 0.4, false, SEA_TINT)
	m += 1
end
return string.format("mountain clumps %d (%d rocks), sea stacks %d (%d rocks)", n, #mtn:GetChildren(), m, #sea:GetChildren())
