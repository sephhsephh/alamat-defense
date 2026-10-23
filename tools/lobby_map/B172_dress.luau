-- tools/lobby_map/B172_dress.luau (B172) -- dressing after B172_assemble: bushes hide the feet of structures and cliff-top
-- rocks (stylized-environment.md section 3.3), fountain water + spray, gold motes over the plaza/spawn, station VFX.
-- Re-runnable: rebuilds Workspace.Lobby.Map.Dressing. Paste into execute_luau (Lobby, Edit).
local LM = game.ServerStorage.DevTools.LobbyMap
local bushes = LM.B172Protos.YasuTreePack.Models_Bushes.Models
local VFX = LM.VFX
local map = workspace.Lobby.Map
local old = map:FindFirstChild("Dressing"); if old then old:Destroy() end
local dress = Instance.new("Folder"); dress.Name = "Dressing"; dress.Parent = map
local rnd = Random.new(17299)
local GREEN = { Color3.fromRGB(70, 150, 62), Color3.fromRGB(96, 168, 70), Color3.fromRGB(58, 136, 70) }
local GOLD = Color3.fromRGB(255, 230, 150)

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
local function ground(x: number, z: number): number?
	local r = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -700, 0), rayParams)
	return if r then r.Position.Y else nil
end

local function bush(x: number, z: number, scale: number?)
	local y = ground(x, z)
	if not y or y < 6 then return end
	local b = bushes:GetChildren()[rnd:NextInteger(1, 3)]:Clone()
	b:ScaleTo((scale or 1) * rnd:NextNumber(0.9, 1.5))
	local tint = if rnd:NextNumber() < 0.15 then GOLD else GREEN[rnd:NextInteger(1, #GREEN)]
	for _, p in ipairs(b:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.CollisionFidelity = Enum.CollisionFidelity.Box
			local sa = p:FindFirstChildOfClass("SurfaceAppearance")
			if sa and p.Name:match("Canopy") then sa.Color = tint end
		end
	end
	local cf, size = b:GetBoundingBox()
	local bottom = (cf.Position.Y - size.Y / 2) - b:GetPivot().Position.Y
	b:PivotTo(CFrame.new(x, y - bottom - size.Y * 0.25, z) * CFrame.Angles(0, rnd:NextNumber(0, 6.28), 0))
	b.Parent = dress
end
local function ringOfBushes(cx: number, cz: number, r: number, n: number, scale: number?)
	for i = 1, n do
		local a = rnd:NextNumber(0, 6.28)
		bush(cx + math.cos(a) * r * rnd:NextNumber(0.85, 1.15), cz + math.sin(a) * r * rnd:NextNumber(0.85, 1.15), scale)
	end
end
local function anchor(name: string, cf: CFrame, size: Vector3): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true; p.Transparency = 1
	p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Parent = dress
	return p
end
local function vfx(preset: string, host: BasePart)
	local src = VFX:FindFirstChild(preset)
	if not src then return end
	for _, c in ipairs(if src:IsA("Attachment") then { src } else src:GetChildren()) do c:Clone().Parent = host end
end

-- 1) bushes at structure feet
for _, o in ipairs({ { -415, 85 }, { -185, 85 }, { -425, -60 }, { -175, -60 } }) do ringOfBushes(o[1], o[2], 15, 3) end
for x = -600, 0, 28 do
	if math.abs(x + 300) > 26 and math.abs(x + 520) > 26 and math.abs(x + 80) > 26 then bush(x + rnd:NextNumber(-6, 6), -112, 1.1) end
end
for _, sx in ipairs({ -1, 1 }) do for k = 0, 2 do bush(-300 + sx * (54 + k * 6), -205 - k * 12, 1.2) end end
ringOfBushes(-530, -20, 20, 4)
ringOfBushes(-700, -110, 28, 6)
for _, z in ipairs({ 35, -15, -65 }) do bush(-40, z, 1.1) end
for _, part in ipairs(map.Nature.CoastRocks:GetChildren()) do
	if part:IsA("BasePart") and part.Position.Y > 18 and rnd:NextNumber() < 0.4 then
		bush(part.Position.X + rnd:NextNumber(-8, 8), part.Position.Z - part.Size.Z * 0.5 - 4, 1.2)
	end
end
-- 2) rotunda planters
local kit = LM.B172Protos.Kit
for _, o in ipairs({ { -326, 392 }, { -274, 392 }, { -340, 452 }, { -260, 452 } }) do
	local m = kit.AL_Planter:Clone(); m:ScaleTo(1.6); m:PivotTo(CFrame.new(o[1], 42, o[2])); m.Parent = dress
end
-- 3) fountain water + spray
local water = anchor("FountainWater", CFrame.new(-300, 46.8, 40) * CFrame.Angles(0, 0, math.rad(90)), Vector3.new(0.6, 38, 38))
water.Shape = Enum.PartType.Cylinder; water.Transparency = 0.25; water.Material = Enum.Material.Glass
water.Color = Color3.fromRGB(120, 215, 230)
vfx("WaterRipples", water)
vfx("FountainSpray", anchor("FountainSpray", CFrame.new(-300, 66, 40), Vector3.new(2, 2, 2)))
-- 4) holy motes over the plaza + spawn deck, station VFX
vfx("Motes_Gold", anchor("PlazaMotes", CFrame.new(-300, 60, 20), Vector3.new(300, 30, 260)))
vfx("Motes_Gold", anchor("SpawnMotes", CFrame.new(-300, 56, 420), Vector3.new(100, 20, 100)))
vfx("Sigil_Gold", anchor("EvolveSigil", CFrame.new(-80, 62.3, -196), Vector3.new(30, 0.2, 30)))
vfx("Sigil_Azure", anchor("MoonSigil", CFrame.new(-700, (ground(-700, -110) or 40) + 3.4, -110), Vector3.new(26, 0.2, 26)))
vfx("Aura_Azure", anchor("MoonAura", CFrame.new(-710, (ground(-700, -110) or 40) + 12, -110), Vector3.new(4, 4, 4)))
vfx("Aura_Gold", anchor("ForgeAura", CFrame.new(-539, (ground(-530, -20) or 40) + 24, -20), Vector3.new(4, 4, 4)))
local n = 0
for _, c in ipairs(dress:GetChildren()) do if c:IsA("Model") then n += 1 end end
return string.format("dressing: %d models, %d anchors", n, #dress:GetChildren() - n)
