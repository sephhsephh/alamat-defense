-- tools/lobby_map/B172_harvest.luau (B172) -- step 1 after the user's 3D Importer run of AL_KitA/B/C.glb +
-- AL_SkyCarrier.glb: turn the imported MeshParts into one prototype Model per kit piece in
-- ServerStorage.DevTools.LobbyMap.B172Protos.Kit.<Piece> (pivot = bottom-centre, identity rotation, front = -Z),
-- set per-material looks + collision, and point the HolySky at the carrier's uploaded images.
-- Object names from Blender are `<Piece>__<Mat>[_n]` (tools/maps/lobby/README.md).
local pr = game.ServerStorage.DevTools.LobbyMap.B172Protos
local kit = pr:FindFirstChild("Kit") or Instance.new("Folder")
kit.Name = "Kit"; kit.Parent = pr

local SOLID = { Marble = true, MarbleBlock = true, Pave = true }
local WALKON = { AL_Mandala = true, AL_Dais = true } -- flat floors: hull collision, players stand on them
local NOCOLLIDE = { AL_Stairs = true, AL_BridgeSpan = true } -- walked via invisible colliders placed by the assembler

local found, pieces = 0, {}
local roots = {}
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name:match("^AL_Kit") or c.Name:match("^AL_Sky") then table.insert(roots, c) end
end
local sky = {}
for _, root in ipairs(roots) do
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("MeshPart") then
			local piece, mat = d.Name:match("^(AL_%w+)__(%a+)")
			if d.Name:match("^AL_Sky") then
				sky[d.Name:match("^(AL_Sky%a+)")] = d.TextureID
			elseif piece then
				pieces[piece] = pieces[piece] or {}
				table.insert(pieces[piece], { part = d, mat = mat })
				found += 1
			end
		end
	end
end

for piece, list in pairs(pieces) do
	local old = kit:FindFirstChild(piece); if old then old:Destroy() end
	local m = Instance.new("Model"); m.Name = piece
	for _, e in ipairs(list) do
		local p: MeshPart = e.part
		p.Parent = m
		p.Anchored = true
		p.CastShadow = true
		p.CanTouch = false
		local mat = e.mat
		if mat == "Crystal" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(170, 235, 255); p.Transparency = 0.1
		elseif mat == "Capiz" then
			p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 232, 196)
		elseif mat == "Mandala" then
			-- TextureID ignores alpha: the cut-out disc needs a SurfaceAppearance (maps-apolaki.md gotcha)
			local sa = p:FindFirstChildOfClass("SurfaceAppearance") or Instance.new("SurfaceAppearance")
			sa.ColorMap = p.TextureID; sa.AlphaMode = Enum.AlphaMode.Transparency; sa.Parent = p
		end
		local solid = SOLID[mat] and not NOCOLLIDE[piece]
		if WALKON[piece] then solid = true end
		p.CanCollide = solid
		p.CanQuery = solid
		p.CollisionFidelity = if solid then Enum.CollisionFidelity.Hull else Enum.CollisionFidelity.Box
		if mat == "Gold" or mat == "Crystal" then p.CastShadow = p.Size.Magnitude > 6 end
	end
	local cf, size = m:GetBoundingBox()
	local root = Instance.new("Part")
	root.Name = "Root"; root.Size = Vector3.new(1, 1, 1); root.Transparency = 1
	root.Anchored = true; root.CanCollide = false; root.CanQuery = false; root.CanTouch = false
	root.CFrame = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	root.Parent = m
	m.PrimaryPart = root
	m:SetAttribute("KitSize", size)
	m.Parent = kit
end
for _, r in ipairs(roots) do if #r:GetDescendants() == 0 or r.Name:match("^AL_Sky") then r:Destroy() end end
local s = game.Lighting:FindFirstChild("HolySky")
if s and sky.AL_SkySide and sky.AL_SkySide ~= "" then
	s.SkyboxBk = sky.AL_SkySide; s.SkyboxFt = sky.AL_SkySide; s.SkyboxLf = sky.AL_SkySide; s.SkyboxRt = sky.AL_SkySide
	s.SkyboxUp = sky.AL_SkyUp or s.SkyboxUp; s.SkyboxDn = sky.AL_SkyDn or s.SkyboxDn
end
local names = {}
for piece in pairs(pieces) do table.insert(names, piece) end
table.sort(names)
return string.format("%d meshparts -> %d pieces: %s | sky side %s", found, #names, table.concat(names, ", "), tostring(sky.AL_SkySide))
