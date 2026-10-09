-- tools/lobby_map/07_npcs_travel.luau (B134): NPCs into their themed districts, the SpawnLocation onto the Arrival
-- Plaza centre (invisible pad, facing the temple), and the travel waystones: 6 on the plaza's south arc (one per
-- district) + a return stone in each district. Each stone's ProximityPrompt carries TravelTo = destination stone name;
-- the destination's invisible "Arrival" part marks where the player lands (ServerScriptService.Server.Lobby.
-- LobbyMapService does the teleport). Billboard labels are cloned from NPC_Guide's NameTag (real instances, scale-
-- sized in studs). Idempotent. Never touches PersistentScene.PlayGUICamera (the user's framing). Run in Lobby, Edit.
local Lib = require(game.ServerStorage.DevTools.LobbyMap.Lib:Clone())
local C, M = Lib.C, Enum.Material
local Map = Lib.root()
local out = {}

-- ground under (x, z) including built parts (plazas, stalls), ignoring props, NPCs, stones and non-colliders
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Exclude
rp.RespectCanCollide = true
local function floorAt(x: number, z: number, exclude: { Instance }): number?
	local ex = { Map:FindFirstChild("Nature"), Map:FindFirstChild("Travel") }
	for _, c in ipairs(workspace:GetChildren()) do if c.Name:sub(1, 4) == "NPC_" then table.insert(ex, c) end end
	for _, e in ipairs(exclude) do table.insert(ex, e) end
	rp.FilterDescendantsInstances = ex
	local r = workspace:Raycast(Vector3.new(x, 600, z), Vector3.new(0, -800, 0), rp)
	return r and r.Position.Y or nil
end
local function flatLook(pos: Vector3, x: number, z: number): CFrame
	return CFrame.lookAt(pos, Vector3.new(x, pos.Y, z))
end

-- ===== NPCs =====
local npcs = {
	NPC_Guide = { -326, 754, -330, 772 },
	NPC_Shop = { -853.9, 739.9, -846, 750 },
	NPC_Craft = { -838.1, 739.9, -846, 750 },
	NPC_Evolve = { -560, 462, -500, 462 },
	NPC_Ascension = { -410, 393, -415, 430 },
	NPC_TraitReroll = { 288, 368, 282, 400 },
	NPC_StatReroll = { 95, 632, 75, 630 },
	NPC_Challenge = { 22, 808, -5, 812 },
}
for name, s in pairs(npcs) do
	local npc = workspace:FindFirstChild(name) :: Model?
	if npc then
		local y = floorAt(s[1], s[2], {})
		if y then
			local bb, size = npc:GetBoundingBox()
			local bottomOffset = (bb.Position.Y - size.Y / 2) - npc:GetPivot().Position.Y
			npc:PivotTo(flatLook(Vector3.new(s[1], y - bottomOffset, s[2]), s[3], s[4]))
			table.insert(out, string.format("%s -> (%.0f, %.1f, %.0f)", name, s[1], y, s[2]))
		end
	end
end

-- ===== SPAWN: invisible pad on the plaza centre, facing north (the altar flame + temple) =====
local plazaFloor = Map.ArrivalPlaza.Plaza.Floor :: BasePart
local plazaTop = plazaFloor.Position.Y + plazaFloor.Size.X / 2
local sp = workspace:FindFirstChild("SpawnLocation") :: SpawnLocation?
if sp then
	sp.CFrame = CFrame.new(-330, plazaTop + 0.35 - sp.Size.Y / 2, 772)
	sp.Transparency = 1
	for _, d in ipairs(sp:GetChildren()) do if d:IsA("Decal") then d.Transparency = 1 end end
	table.insert(out, string.format("spawn at (-330, %.2f, 772)", sp.Position.Y))
end

-- ===== TRAVEL WAYSTONES =====
local T = Lib.folder("Travel")
local tagProto = workspace.NPC_Guide.Body:FindFirstChild("NameTag")
local function arrival(parent: Instance, cf: CFrame)
	local a = Lib.part(parent, { Name = "Arrival", Size = Vector3.new(2, 1, 2), CFrame = cf, Transparency = 1, CanCollide = false, CastShadow = false })
	a.CanQuery = false
	a.CanTouch = false
	return a
end
local function stone(name: string, x: number, z: number, fx: number, fz: number, color: Color3, title: string, sub: string, travelTo: string)
	local gy = floorAt(x, z, {}) or Lib.ground(x, z)
	if not gy then return nil end
	local m = Lib.sub(T, name)
	local base = flatLook(Vector3.new(x, gy, z), fx, fz)
	Lib.part(m, { Name = "Base", Size = Vector3.new(4.4, 1, 4.4), CFrame = base * CFrame.new(0, 0.3, 0), Color = Color3.fromRGB(64, 60, 66), Material = M.Slate })
	local shaft = Lib.part(m, { Name = "Shaft", Size = Vector3.new(2.2, 8, 2.2), CFrame = base * CFrame.new(0, 4.8, 0), Color = Color3.fromRGB(52, 48, 58), Material = M.Slate })
	Lib.part(m, { Name = "Rune", Size = Vector3.new(0.35, 5.2, 0.12), CFrame = base * CFrame.new(0, 4.6, -1.13), Color = color, Material = M.Neon, CanCollide = false, CastShadow = false })
	local gem = Lib.part(m, { Name = "Crystal", Size = Vector3.new(1.4, 2.4, 1.4), CFrame = base * CFrame.new(0, 10.2, 0) * CFrame.Angles(0, math.rad(45), 0), Color = color, Material = M.Neon, CanCollide = false, CastShadow = false })
	Lib.light(gem, color, 14, 1.4, false)
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "TravelPrompt"
	pp.ActionText = "Travel"
	pp.ObjectText = title
	pp.HoldDuration = 0.25
	pp.MaxActivationDistance = 9
	pp.RequiresLineOfSight = false
	pp:SetAttribute("TravelTo", travelTo)
	pp.Parent = shaft
	if tagProto then
		local tag = tagProto:Clone()
		tag.Name = "Label"
		tag.Size = UDim2.fromScale(7, 1.7)
		tag.StudsOffset = Vector3.new(0, 7.2, 0)
		tag.MaxDistance = 60
		tag.AlwaysOnTop = false
		local t1, t2 = tag:FindFirstChild("TextLabel") :: TextLabel?, tag:FindFirstChild("Subtitle") :: TextLabel?
		if t1 then t1.Text = title end
		if t2 then t2.Text = sub end
		tag.Parent = shaft
	end
	arrival(m, base * CFrame.new(0, 3, -6))
	return m
end

-- district return stones (each district's arrival point is in front of its stone)
local districts = {
	{ "Stone_Village", -830, 765, -846, 748, Color3.fromRGB(255, 170, 70), "Beach Village", "Shop & Craft" },
	{ "Stone_Temple", -404, 410, -415, 380, C.blue, "Sky Temple", "Ascension" },
	{ "Stone_RuneCircle", -536, 470, -560, 462, Color3.fromRGB(90, 230, 220), "Rune Circle", "Evolve" },
	{ "Stone_Forge", 78, 640, 100, 628, C.crimson, "Red Gate Forge", "Stat Reroll" },
	{ "Stone_Shrine", 276, 382, 292, 352, C.purple, "Crystal Shrine", "Trait Reroll" },
	{ "Stone_Arena", 0, 826, 40, 815, C.green, "Green Arena", "Challenges" },
}
for _, d in ipairs(districts) do
	stone(d[1], d[2], d[3], d[4], d[5], d[6], "Arrival Plaza", "Travel back", "Plaza")
end
-- the plaza destination: just north of the spawn pad, facing the temple
local P = Lib.sub(T, "Plaza")
arrival(P, CFrame.new(-330, plazaTop + 3, 760))
-- plaza stones on the south arc just outside the rim (r 44, on the grass bowl), facing the centre
local ax, az = -330, 772
for i, d in ipairs(districts) do
	local ang = math.rad(-75 + (i - 1) * 30)
	local x, z = ax + math.sin(ang) * 44, az + math.cos(ang) * 44
	stone("Plaza_" .. d[1]:sub(7), x, z, ax, az, d[6], d[7], d[8], d[1])
end
local n = 0
for _, c in ipairs(T:GetChildren()) do if c:FindFirstChild("Arrival", true) then n += 1 end end
table.insert(out, "travel: " .. n .. " stones/destinations")
return table.concat(out, "\n")
