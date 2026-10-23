-- tools/lobby_map/B172_groves.luau (B172) -- tree groves on the outer lands (Yasu's Stylized Tree Pack, inserted
-- from the Creator Store into ServerStorage.DevTools.LobbyMap.B172Protos.YasuTreePack). Groves, not a carpet:
-- meadows stay open. Leaves are colourless textures tinted with SurfaceAppearance.Color (white-tint rule):
-- mostly green, accent groves of holy white-gold and pale pink. Rebuilds Workspace.Lobby.Map.Nature.Groves.
local pack = game.ServerStorage.DevTools.LobbyMap.B172Protos.YasuTreePack.Models_Trees.Models
local map = workspace.Lobby.Map
local nature = map:FindFirstChild("Nature") or Instance.new("Folder")
nature.Name = "Nature"; nature.Parent = map
local old = nature:FindFirstChild("Groves"); if old then old:Destroy() end
local groves = Instance.new("Folder"); groves.Name = "Groves"; groves.Parent = nature

local MAIN_C, MAIN_R = Vector2.new(-300, -300), Vector2.new(1250, 760)
local KEEP_CLEAR = { -- {x, z, radius}: plaza, temple row, stations, mesa top
	{ -300, 0, 215 }, { -300, -210, 150 }, { -520, -190, 70 }, { -80, -190, 70 }, { -700, -110, 70 },
	{ -530, -20, 70 }, { -70, -15, 80 }, { 300, -330, 110 },
}
local TINTS = {
	green = { Color3.fromRGB(70, 150, 62), Color3.fromRGB(96, 168, 70), Color3.fromRGB(54, 128, 74) },
	gold = { Color3.fromRGB(255, 236, 170), Color3.fromRGB(255, 222, 130) },
	pink = { Color3.fromRGB(255, 196, 214), Color3.fromRGB(255, 214, 226) },
}
local BARK = Color3.fromRGB(122, 86, 60)
local SPECIES = { "Tree_03", "Tree_04", "Tree_05", "Tree_06", "Tree_07", "Tree_09", "Tree_13", "Tree_15", "Tree_17", "Tree_18", "Tree_19" }

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
local function surface(x: number, z: number): (number?, Enum.Material?)
	local r = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -700, 0), rayParams)
	if not r then return nil, nil end
	return r.Position.Y, r.Material
end
local function allowed(x: number, z: number): boolean
	local ex, ez = (x - MAIN_C.X) / MAIN_R.X, (z - MAIN_C.Y) / MAIN_R.Y
	if math.sqrt(ex * ex + ez * ez) > 0.78 then return false end
	for _, k in ipairs(KEEP_CLEAR) do
		if (Vector2.new(x, z) - Vector2.new(k[1], k[2])).Magnitude < k[3] then return false end
	end
	local y, mat = surface(x, z)
	return y ~= nil and y > 30 and (mat == Enum.Material.Grass or mat == Enum.Material.LeafyGrass)
end

local function plant(rnd: Random, x: number, z: number, scale: number, tint: Color3)
	local y = surface(x, z)
	if not y then return false end
	local src = pack:FindFirstChild(SPECIES[rnd:NextInteger(1, #SPECIES)])
	local tree = src:Clone()
	tree:ScaleTo(scale)
	for _, p in ipairs(tree:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CastShadow = true
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa then
				if p.Name:match("^Canopy") then sa.Color = tint else sa.Color = BARK end
			end
		end
	end
	local cf, size = tree:GetBoundingBox()
	local pivot = tree:GetPivot()
	local bottomOffset = (cf.Position.Y - size.Y / 2) - pivot.Position.Y
	tree:PivotTo(CFrame.new(x, y - bottomOffset - 1.5, z) * CFrame.Angles(0, rnd:NextNumber(0, 2 * math.pi), 0))
	tree.Parent = groves
	return true
end

local rnd = Random.new(1720)
local planted, grovesMade = 0, 0
local tries = 0
while grovesMade < 34 and tries < 600 do
	tries += 1
	local gx = rnd:NextNumber(-1450, 850)
	local gz = rnd:NextNumber(-950, 120)
	if allowed(gx, gz) then
		grovesMade += 1
		local roll = rnd:NextNumber()
		local family = if roll < 0.18 then "gold" elseif roll < 0.32 then "pink" else "green"
		local palette = TINTS[family]
		local radius = rnd:NextNumber(55, 110)
		local count = rnd:NextInteger(6, 13)
		for _ = 1, count do
			local a, d = rnd:NextNumber(0, 2 * math.pi), radius * math.sqrt(rnd:NextNumber())
			local x, z = gx + math.cos(a) * d, gz + math.sin(a) * d
			if allowed(x, z) and plant(rnd, x, z, rnd:NextNumber(0.9, 1.7), palette[rnd:NextInteger(1, #palette)]) then
				planted += 1
			end
		end
	end
end
return string.format("%d groves, %d trees", grovesMade, planted)
