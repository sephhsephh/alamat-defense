-- B139 revamp: every district after the Arrival Plaza, as run in Studio (Lobby, Edit). Each district is its own
-- function; run the HELPERS block + the functions you need (each rebuilds <District>.Revamp, idempotent EXCEPT that
-- it deletes the B134 block-built parts it replaces -- re-running needs the B134 builders 01-07 first).
-- Needs 08_vfx_lib + the AI meshes in ServerStorage.DevTools.LobbyMap.Protos (M_*; see docs/systems/lobby-map.md).
--[[HELPERS]]
local P = game.ServerStorage.DevTools.LobbyMap.Protos
local V = game.ServerStorage.DevTools.LobbyMap.VFX
local MAP = workspace.Lobby.Map
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
local function ground(x, z, from) local r = workspace:Raycast(Vector3.new(x, from or 450, z), Vector3.new(0, -900, 0), rp); return r and r.Position.Y or 0 end
local function mesh(name, parent, o) -- o: pos (base centre) | cf, size | h | w, ground+from, yaw, collide, shadow, name
  local c = P[name]:Clone(); local mp = c.PrimaryPart; local s = mp.Size
  if o.size then mp.Size = o.size elseif o.h then mp.Size = s * (o.h / s.Y) elseif o.w then mp.Size = s * (o.w / math.max(s.X, s.Z)) end
  if o.cf then mp.CFrame = o.cf else
    local b = o.pos; if o.ground then b = Vector3.new(b.X, ground(b.X, b.Z, o.from), b.Z) end
    mp.CFrame = CFrame.new(b + Vector3.new(0, mp.Size.Y / 2 - (o.sink or 0), 0)) * CFrame.Angles(0, math.rad(o.yaw or 0), 0) end
  mp.Anchored = true; mp.CanCollide = o.collide ~= false; mp.CastShadow = o.shadow ~= false
  if o.collide == false then mp.CanQuery = false; mp.CanTouch = false end
  c.Name = o.name or name:sub(3); c.Parent = parent; return c, mp
end
local function anchor(parent, name, pos, size)
  local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
  p.Transparency = 1; p.Size = size or Vector3.new(1, 1, 1); p.Position = pos; p.Parent = parent; return p end
local function fx(preset, parent, pos, scale, size) -- clone a VFX preset; scale multiplies particle size/speed, light range, beam width
  local p = anchor(parent, preset, pos, size); local a = V[preset]:Clone(); a.Parent = p
  scale = scale or 1
  if scale ~= 1 then for _, e in ipairs(a:GetChildren()) do
    if e:IsA("ParticleEmitter") then local k = {}
      for _, kp in ipairs(e.Size.Keypoints) do table.insert(k, NumberSequenceKeypoint.new(kp.Time, kp.Value * scale, kp.Envelope * scale)) end
      e.Size = NumberSequence.new(k); e.Speed = NumberRange.new(e.Speed.Min * scale, e.Speed.Max * scale); e.Acceleration *= scale
    elseif e:IsA("PointLight") then e.Range *= math.sqrt(scale)
    elseif e:IsA("Beam") then e.Width0 *= scale; e.Width1 *= scale end end end
  return p, a
end
local function shaft(color, parent, base, height, scale) -- soft Beam light pillar (replaces the B134 neon SkyBeam bricks)
  local p, a = fx("Shaft_"..color, parent, base, scale)
  local top = Instance.new("Attachment"); top.Name = "ShaftTop"; top.Position = Vector3.new(0, height, 0); top.Parent = p
  for _, b in ipairs(a:GetChildren()) do if b:IsA("Beam") then b.Attachment0 = a; b.Attachment1 = top end end
  return p
end
local function revamp(d) local R = d:FindFirstChild("Revamp"); if R then R:Destroy() end
  R = Instance.new("Folder"); R.Name = "Revamp"; R.Parent = d; return R end
-- B134 plazas keep their Floor/Rim cylinders as INVISIBLE walk colliders; the AI floor disc is visual only.
local function plazaSwap(pm, meshName, R, extra)
  local floor = pm:FindFirstChild("Floor"); local rim = pm:FindFirstChild("Rim")
  if not floor then return nil end
  local top = floor.Position.Y + floor.Size.X / 2
  local d = (rim or floor).Size.Y + (extra or 1)
  for _, p in ipairs(pm:GetChildren()) do if p:IsA("BasePart") then p.Transparency = 1 else p:Destroy() end end
  if meshName then mesh(meshName, R, {pos = Vector3.new(floor.Position.X, top - 2.3, floor.Position.Z), size = Vector3.new(d, 2.6, d), collide = false, shadow = false, name = "Floor"}) end
  return Vector3.new(floor.Position.X, top, floor.Position.Z), d
end
local function lanternAt(parent, pos, color) -- stone lantern + glow: replaces every B134 stick torch
  local _, mp = mesh("M_StoneLantern2", parent, {pos = pos, h = 6, ground = true, from = pos.Y + 12, name = "StoneLantern"})
  local _, a = fx("Fire_"..(color or "Gold"), parent, mp.Position + Vector3.new(0, mp.Size.Y * 0.08, 0), 0.26)
  a.Embers.Enabled = false; a.Flame.Enabled = false; a.Light.Range = 14; a.Light.Brightness = 1.8
end
local function tiki(R, pos, from, col)
  local _, mp = mesh("M_Tiki", R, {pos = pos, h = 8.5, ground = true, from = from, name = "TikiTorch"})
  local _, a = fx("Fire_"..(col or "Gold"), R, mp.Position + Vector3.new(0, mp.Size.Y / 2 - 0.3, 0), 0.6); a.Light.Range = 16
end
--[[END HELPERS]]

local function Temple() -- AI pagoda on Base1; guardians, steps, terrace stairs kept
  local T = MAP.Temple
  local keep = {Base1 = true, Base1Trim = true, FrontStep = true, LowerStep = true, TerraceStairs = true, Guardian = true, GuardianPlinth = true}
  for _, c in ipairs(T:GetChildren()) do if not keep[c.Name] and c.Name ~= "Revamp" then
    if c.Name == "GuardianUplight" then fx("Aura_Azure", T, c.Position + Vector3.new(0, 2, 0), 0.5) end
    c:Destroy() end end
  local R = revamp(T)
  local _, tm = mesh("M_Temple", R, {pos = Vector3.new(-420, 208.1, 356), size = P.M_Temple.PrimaryPart.Size * 1.15, name = "SkyTemple"})
  local topY = tm.Position.Y + tm.Size.Y / 2
  shaft("Azure", R, Vector3.new(-420, topY + 1, 356), 160, 1.2)
  fx("Aura_Azure", R, Vector3.new(-420, topY - 3, 356), 0.8)
  for _, x in ipairs({-441, -399}) do
    local _, mp = mesh("M_Brazier", R, {pos = Vector3.new(x, 0, 388), h = 9, ground = true, from = 240, name = "Brazier"})
    fx("Fire_Azure", R, mp.Position + Vector3.new(0, mp.Size.Y / 2 - 0.6, 0), 1.2)
  end
  fx("Motes_Azure", R, Vector3.new(-420, 210, 375), 1, Vector3.new(60, 1, 50))
  fx("Fireflies", R, Vector3.new(-420, 220, 380), 1, Vector3.new(90, 16, 90))
  for _, sx in ipairs({-1, 1}) do
    local _, lp = mesh("M_LanternPost", R, {pos = Vector3.new(-420 + sx * (tm.Size.X * 0.5 - 3), tm.Position.Y - tm.Size.Y * 0.06 - 4, 356 + tm.Size.Z * 0.42 - 4), h = 3.2, collide = false, name = "PaperLantern"})
    local _, a = fx("Fire_Gold", R, lp.Position, 0.25); a.Flame.Enabled = false; a.Embers.Enabled = false; a.Light.Range = 12
  end
  for _, l in ipairs(R:GetDescendants()) do if l:IsA("PointLight") then l.Brightness = math.min(l.Brightness, 1.1); l.Range = math.min(l.Range, 16) end end
end

local function RuneCircle() -- Evolve
  local E = MAP.EvolveCircle; local C = Vector3.new(-560, 168.81, 462); local mono = {}
  for _, c in ipairs(E:GetChildren()) do
    if c.Name == "Monolith" then table.insert(mono, c.Position) end
    if c.Name == "Rune" or c.Name == "Monolith" or c.Name == "MonolithGlyph" then c:Destroy() end
  end
  for _, p in ipairs(E.RunePlaza:GetChildren()) do if p:IsA("BasePart") then p.Transparency = 1 end end
  local R = revamp(E)
  mesh("M_RunePlatform", R, {pos = C - Vector3.new(0, 2.1, 0), size = Vector3.new(38, 2.6, 38), collide = false, name = "RuneDais", shadow = false})
  fx("Sigil_Azure", R, C + Vector3.new(0, 0.6, 0), 1.25)
  fx("Motes_Azure", R, C + Vector3.new(0, 1, 0), 1, Vector3.new(30, 1, 30))
  for _, pos in ipairs(mono) do
    local _, mp = mesh("M_Monolith", R, {pos = Vector3.new(pos.X, 0, pos.Z), h = 14, ground = true, from = 200, yaw = math.deg(math.atan2(C.X - pos.X, C.Z - pos.Z)), name = "RuneStone"})
    local _, a = fx("Aura_Azure", R, mp.Position + Vector3.new(0, 2, 0), 0.4); a.Light.Range = 14
  end
  fx("Fireflies", R, C + Vector3.new(0, 8, 0), 1, Vector3.new(70, 14, 70))
end

local function AltarBeaconShrine()
  -- Sun Altar
  local FA = MAP.FlameAltar; local pillars = {}
  for _, c in ipairs(FA:GetChildren()) do
    if c.Name == "Pillar" then table.insert(pillars, c.Position) end
    if c.Name ~= "AltarPlaza" and c.Name ~= "Revamp" then c:Destroy() end
  end
  local R = revamp(FA)
  local C, D = plazaSwap(FA.AltarPlaza, "M_FloorSun", R, 2)
  local _, alt = mesh("M_FireAltar", R, {pos = C, w = 24, name = "SunAltar"})
  fx("Fire_Gold", R, alt.Position + Vector3.new(0, alt.Size.Y / 2 - 2, 0), 2.6)
  fx("Motes_Gold", R, C + Vector3.new(0, 1, 0), 1, Vector3.new(D - 6, 1, D - 6))
  for _, pos in ipairs(pillars) do
    local _, mp = mesh("M_Brazier", R, {pos = Vector3.new(pos.X, C.Y, pos.Z), h = 10, name = "Brazier"})
    fx("Fire_Gold", R, mp.Position + Vector3.new(0, mp.Size.Y / 2 - 0.6, 0), 1.3)
  end
  for _, x in ipairs({-311, -289}) do mesh("M_Banner", R, {pos = Vector3.new(x, 0, 588), h = 15, ground = true, from = 200, name = "Banner"}) end
  -- Blue Beacon
  local BB = MAP.BlueBeacon; local ring = {}
  for _, c in ipairs(BB:GetChildren()) do
    if c.Name == "RingPillar" then table.insert(ring, c.Position) end
    if ({Shard = 1, RingCap = 1, RingPillar = 1, SkyBeam = 1, Crystal = 1})[c.Name] then c:Destroy() end
  end
  R = revamp(BB); C, D = plazaSwap(BB.BeaconPlaza, "M_FloorWave", R, 2)
  local _, cr = mesh("M_CrystalBlue", R, {pos = C, w = 15, name = "BeaconCrystal"})
  fx("Aura_Azure", R, cr.Position, 1.1); shaft("Azure", R, cr.Position + Vector3.new(0, cr.Size.Y / 2, 0), 130, 1)
  for _, pos in ipairs(ring) do
    local _, mp = mesh("M_StoneLantern2", R, {pos = Vector3.new(pos.X, C.Y, pos.Z), h = 6.5, yaw = math.deg(math.atan2(C.X - pos.X, C.Z - pos.Z)), name = "StoneLantern"})
    local _, a = fx("Fire_Azure", R, mp.Position + Vector3.new(0, mp.Size.Y * 0.08, 0), 0.3); a.Embers.Enabled = false; a.Light.Range = 12
  end
  -- Crystal Shrine
  local PS = MAP.PurpleShrine; local cols = {}
  for _, c in ipairs(PS:GetChildren()) do
    if c.Name == "RuneColumn" then table.insert(cols, {c.Position, c.Size.Y}) end
    if ({CrystalSpire = 1, Shard = 1, RuneColumn = 1, RuneGlow = 1, SkyBeam = 1})[c.Name] then c:Destroy() end
  end
  R = revamp(PS); C, D = plazaSwap(PS.ShrinePlaza, "M_FloorMoon", R, 2)
  local _, pc = mesh("M_CrystalPurple", R, {pos = C, w = 17, name = "ShrineCrystal"})
  fx("Aura_Violet", R, pc.Position, 1.2); shaft("Violet", R, pc.Position + Vector3.new(0, pc.Size.Y / 2, 0), 140, 1)
  fx("Motes_Violet", R, C + Vector3.new(0, 1, 0), 1, Vector3.new(D - 6, 1, D - 6))
  for _, it in ipairs(cols) do
    local _, mp = mesh("M_ShrinePillar", R, {pos = Vector3.new(it[1].X, C.Y, it[1].Z), h = it[2] + 2, name = "ShrinePillar"})
    local _, a = fx("Aura_Violet", R, mp.Position + Vector3.new(0, mp.Size.Y * 0.38, 0), 0.3); a.Light.Range = 12
  end
end

local function StairsAndBridges()
  for _, s in ipairs(MAP:GetDescendants()) do -- stairs: stylized stone MaterialVariant + lanterns for torches
    if s:IsA("Model") and s.Name:sub(1, 7) == "Stairs_" then
      local R = revamp(s); local torches = {}
      for _, d in ipairs(s:GetChildren()) do if d.Name == "Torch" then table.insert(torches, d:GetBoundingBox().Position); d:Destroy() end end
      for _, d in ipairs(s:GetDescendants()) do if d:IsA("BasePart") and (d.Name == "Step" or d.Name == "Wall") then
        d.Material = Enum.Material.Slate; d.MaterialVariant = "Alamat_StylizedStone"
        d.Color = d.Name == "Step" and Color3.fromRGB(214, 204, 186) or Color3.fromRGB(150, 146, 140) end end
      for _, pos in ipairs(torches) do lanternAt(R, pos) end
    end
  end
  for _, b in ipairs(MAP:GetDescendants()) do -- bridges: AI rope-bridge segment tiled along the (invisible, colliding) planks
    if b:IsA("Model") and b.Name:sub(1, 7) == "Bridge_" then
      local R = revamp(b); local planks, torches = {}, {}
      for _, d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Plank" then table.insert(planks, d) end end
      for _, d in ipairs(b:GetChildren()) do if d.Name == "Torch" then table.insert(torches, d:GetBoundingBox().Position); d:Destroy() end end
      for _, d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") and (d.Name == "Post" or d.Name == "Rope") then d:Destroy() end end
      for _, d in ipairs(b:GetDescendants()) do if d:IsA("BasePart") and d.Name == "Pier" then
        d.Material = Enum.Material.Slate; d.MaterialVariant = "Alamat_StylizedStone"; d.Color = Color3.fromRGB(168, 160, 150) end end
      local a0 = planks[1].Position; local axis = (planks[#planks].Position - a0).Unit
      table.sort(planks, function(p, q) return (p.Position - a0):Dot(axis) < (q.Position - a0):Dot(axis) end)
      local p0, p1 = planks[1], planks[#planks]; local up = p0.CFrame.UpVector
      local s0, s1 = p0.Position - up * 0.3, p1.Position - up * 0.3; local dir = s1 - s0
      local along = dir.Magnitude + p0.Size.Z; local n = math.max(1, math.floor(along / 10.5 + 0.5)); local segLen = along / n
      local start = s0 - dir.Unit * (p0.Size.Z / 2)
      for i = 0, n - 1 do
        local mid = start + dir.Unit * (segLen * (i + 0.5))
        mesh("M_BridgeSeg", R, {cf = CFrame.lookAt(mid, mid + dir.Unit, up) * CFrame.new(0, 2.4, 0), size = Vector3.new(p0.Size.X + 1.2, 6, segLen + 0.15), collide = false, name = "Deck"})
      end
      for _, p in ipairs(planks) do p.Transparency = 1 end
      for _, pos in ipairs(torches) do lanternAt(R, pos) end
    end
  end
  for _, d in ipairs(MAP.Stairs_Temple:GetDescendants()) do -- the grand temple stairs (GrandStairs model)
    if d:IsA("BasePart") and d.Transparency < 1 and (d.Material == Enum.Material.Limestone or d.Material == Enum.Material.Slate or d.Material == Enum.Material.Sandstone) then
      d.Material = Enum.Material.Slate; d.MaterialVariant = "Alamat_StylizedStone"
      d.Color = d.Name == "Step" and Color3.fromRGB(214, 204, 186) or Color3.fromRGB(150, 146, 140) end
  end
  for _, t in ipairs(MAP:GetDescendants()) do -- any torch left anywhere -> stone lantern
    if t:IsA("Model") and t.Name == "Torch" and t.Parent and not t:FindFirstAncestor("Revamp") then
      local host = t.Parent; local R = host:FindFirstChild("Revamp") or revamp(host)
      local pos = t:GetBoundingBox().Position; t:Destroy(); lanternAt(R, pos)
    end
  end
end

local function RedGateAndArena()
  local RG = MAP.RedGate; local R = revamp(RG); local pillars, braz = {}, {}
  for _, c in ipairs(RG:GetChildren()) do
    if c.Name == "GatePillar" then table.insert(pillars, c.Position) end
    if c.Name == "GateBrazier" then table.insert(braz, c.Position - Vector3.new(0, c.Size.Y / 2, 0)) end
    if c.Name:sub(1, 4) == "Gate" then c:Destroy() end
  end
  local mid = (pillars[1] + pillars[2]) / 2; local dv = pillars[2] - pillars[1]
  mesh("M_Torii", R, {pos = Vector3.new(mid.X, 120.9, mid.Z), h = 31, yaw = math.deg(math.atan2(-dv.Z, dv.X)), collide = false, name = "CrimsonTorii"})
  for _, b in ipairs(braz) do
    local _, mp = mesh("M_Brazier", R, {pos = b, h = 7.5, ground = true, from = b.Y + 10, name = "Brazier"})
    fx("Fire_Crimson", R, mp.Position + Vector3.new(0, mp.Size.Y / 2 - 0.6, 0), 1.1)
  end
  local cb = RG.CrimsonBrazier; local cbPos = cb:GetBoundingBox().Position; cb:Destroy()
  local _, gb = mesh("M_Brazier", R, {pos = Vector3.new(cbPos.X, 0, cbPos.Z), h = 14, ground = true, from = cbPos.Y + 30, name = "GreatBrazier"})
  fx("Fire_Crimson", R, gb.Position + Vector3.new(0, gb.Size.Y / 2 - 1, 0), 2.3)
  shaft("Crimson", R, gb.Position + Vector3.new(0, gb.Size.Y / 2 + 2, 0), 120, 0.9)
  local wt = RG.Watchtower; local wtPos = wt:GetBoundingBox().Position; wt:Destroy()
  local _, pt = mesh("M_PagodaTower", R, {pos = Vector3.new(wtPos.X, 0, wtPos.Z), h = 40, ground = true, from = wtPos.Y + 40, name = "PagodaTower"})
  fx("Aura_Crimson", R, pt.Position + Vector3.new(0, pt.Size.Y * 0.2, 0), 0.6)
  local F = RG.Forge; for _, c in ipairs(F:GetChildren()) do if c.Name ~= "ForgeYard" then c:Destroy() end end
  local C = plazaSwap(F.ForgeYard, "M_FloorSun", R, 2) or Vector3.new(100, ground(100, 620, 200), 620)
  local _, fg = mesh("M_Forge", R, {pos = Vector3.new(100, C.Y, 617), w = 22, name = "ForgeWorkshop"})
  fx("Fire_Crimson", R, fg.Position + Vector3.new(0, -fg.Size.Y * 0.18, fg.Size.Z * 0.3), 0.9)
  local _, sa = fx("VolcanoPlume", R, fg.Position + Vector3.new(fg.Size.X * 0.05, fg.Size.Y / 2 + 1, -1), 0.12)
  sa.Embers.Rate = 4; sa.Glow.Enabled = false; sa:FindFirstChildWhichIsA("PointLight").Enabled = false; sa.Smoke.Rate = 2
  -- Green Arena: AI colosseum is visual; the B134 floor + 3-stud walls stay as invisible colliders
  local GA = MAP.GreenArena; R = revamp(GA); local banners = {}
  for _, c in ipairs(GA:GetChildren()) do
    if c.Name == "BannerPole" then table.insert(banners, c.Position - Vector3.new(0, c.Size.Y / 2, 0)) end
    if ({BannerPole = 1, BannerCloth = 1, BeaconBase = 1, SkyBeam = 1, GreenFlame = 1})[c.Name] then c:Destroy() end
    if c.Name == "ArenaWall" then c.Transparency = 1 end
  end
  local AC, AD = plazaSwap(GA.ArenaFloor, nil, R)
  mesh("M_Arena", R, {pos = AC - Vector3.new(0, 1.8, 0), size = Vector3.new(AD + 6, 8.5, AD + 6), collide = false, name = "Colosseum"})
  local _, br = mesh("M_Brazier", R, {pos = AC, h = 8, name = "JadeBrazier"})
  fx("Fire_Jade", R, br.Position + Vector3.new(0, br.Size.Y / 2 - 0.6, 0), 1.5)
  shaft("Jade", R, br.Position + Vector3.new(0, br.Size.Y / 2 + 2, 0), 120, 0.9)
  fx("Motes_Jade", R, AC + Vector3.new(0, 1, 0), 1, Vector3.new(AD - 8, 1, AD - 8))
  for _, b in ipairs(banners) do
    local flat = Vector3.new(b.X, 0, b.Z)
    mesh("M_Banner", R, {pos = flat + (flat - Vector3.new(AC.X, 0, AC.Z)).Unit * 3, h = 15, ground = true, from = b.Y + 20, yaw = math.deg(math.atan2(b.X - AC.X, b.Z - AC.Z)), name = "Banner"})
  end
end

local function Village()
  local VL = MAP.Village; local R = revamp(VL)
  local MC, MD = plazaSwap(VL.MarketSquare, "M_FloorWave", R, 2)
  local function swapStall(name, proto)
    local m = VL[name]; local cf = m:GetBoundingBox(); m:Destroy()
    local _, mp = mesh(proto, R, {pos = Vector3.new(cf.Position.X, 0, cf.Position.Z), w = 13.5, ground = true, from = cf.Position.Y + 15, name = name}); return mp
  end
  swapStall("ShopStall", "M_MarketStall")
  local cs = swapStall("CraftForge", "M_ForgeStall"); fx("Fire_Crimson", R, cs.Position + Vector3.new(0, -1, 0), 0.55)
  for _, c in ipairs(VL:GetChildren()) do if ({Anvil = 1, ForgeCoals = 1, FireStone = 1, Campfire = 1})[c.Name] then c:Destroy() end end
  local _, cf = mesh("M_Campfire", R, {pos = Vector3.new(-846, 0, 754), w = 5.5, ground = true, from = 40, name = "Campfire"})
  fx("Fire_Gold", R, cf.Position + Vector3.new(0, 0.6, 0), 1.0)
  for _, c in ipairs(VL:GetChildren()) do if c.Name == "Torch" then local p = c:GetBoundingBox().Position; c:Destroy(); tiki(R, Vector3.new(p.X, 0, p.Z), p.Y + 8) end end
  for _, c in ipairs(VL:GetChildren()) do if c.Name == "Bangka" then
    local bcf, bsz = c:GetBoundingBox(); c:Destroy(); local _, y = bcf:ToOrientation()
    mesh("M_Bangka", R, {pos = Vector3.new(bcf.Position.X, 3.2, bcf.Position.Z), w = 21, yaw = math.deg(y) + (bsz.Z > bsz.X and 0 or 90), name = "Bangka"}) end end
  for _, c in ipairs(VL:GetChildren()) do if c:IsA("BasePart") and (c.Name == "PierPost" or c.Name == "PierDeck") then
    c.Material = Enum.Material.WoodPlanks; c.MaterialVariant = "Alamat_StylizedPlanks"; c.Color = Color3.fromRGB(196, 150, 104) end end
  fx("Fireflies", R, MC + Vector3.new(0, 8, 0), 1, Vector3.new(120, 14, 120))
  for i = 0, 5 do local a = math.rad(i * 60 + 30); tiki(R, MC + Vector3.new(math.cos(a) * (MD / 2 + 2), 0, math.sin(a) * (MD / 2 + 2)), MC.Y + 20) end
end

local function JungleSeaVolcano()
  local J = MAP.Jungle; local R = revamp(J)
  local lt = J.LookoutTower; local ltcf, ltsz = lt:GetBoundingBox(); local ltBase = ltcf.Position - Vector3.new(0, ltsz.Y / 2, 0); lt:Destroy()
  local _, lk = mesh("M_Lookout", R, {pos = Vector3.new(ltBase.X, 0, ltBase.Z), h = 36, ground = true, from = ltBase.Y + 30, name = "LookoutTower"})
  local _, a = fx("Fire_Gold", R, lk.Position + Vector3.new(0, lk.Size.Y * 0.22, 0), 0.5); a.Flame.Enabled = false; a.Light.Range = 24
  for _, c in ipairs(J:GetChildren()) do if c.Name == "BannerPole" then local p = c:GetBoundingBox().Position; c:Destroy(); tiki(R, Vector3.new(p.X, 0, p.Z), p.Y + 20, "Jade") end end
  for i, s in ipairs({{-850, 470}, {-880, 520}, {-820, 430}, {-905, 410}, {-790, 500}, {-760, 560}, {-700, 470}, {-860, 600}}) do
    local _, mp = mesh("M_Mushrooms", R, {pos = Vector3.new(s[1], 0, s[2]), h = 3 + (i % 3), ground = true, from = 260, yaw = i * 47, collide = false, name = "GlowShrooms"})
    local _, qa = fx("Aura_Azure", R, mp.Position, 0.18); qa.Light.Range = 10; qa.Light.Brightness = 1.4
  end
  fx("Fireflies", R, Vector3.new(-840, 160, 480), 1.2, Vector3.new(180, 30, 200))
  local ra = J.RuinedArch; local cf, sz = ra:GetBoundingBox(); local _, yaw = cf:ToOrientation(); ra:Destroy()
  local _, am = mesh("M_RuinArch", R, {pos = cf.Position - Vector3.new(0, sz.Y / 2 + 0.5, 0), h = 26, yaw = math.deg(yaw) + (sz.X > sz.Z and 0 or 90), collide = false, name = "RuinedArch"})
  for _, sx in ipairs({-1, 1}) do local col = anchor(R, "ArchCollider", Vector3.zero, Vector3.new(am.Size.X * 0.2, am.Size.Y, am.Size.Z * 0.8))
    col.CanCollide = true; col.CFrame = am.CFrame * CFrame.new(sx * am.Size.X * 0.36, 0, 0) end
  local S = MAP.Sea; R = revamp(S)
  local lh = S.Lighthouse; local lcf, lsz = lh:GetBoundingBox(); local lBase = lcf.Position - Vector3.new(0, lsz.Y / 2, 0); lh:Destroy()
  local _, lm = mesh("M_Lighthouse", R, {pos = Vector3.new(lBase.X, 0, lBase.Z), h = 48, ground = true, from = lBase.Y + 60, name = "Lighthouse"})
  local _, la = fx("Aura_Gold", R, lm.Position + Vector3.new(0, lm.Size.Y * 0.33, 0), 0.9); la.Light.Range = 60; la.Light.Brightness = 3
  local VO = MAP.Volcano; R = revamp(VO)
  local crater = Vector3.new(-24, 211, -312)
  for _, c in ipairs(VO:GetChildren()) do if c:IsA("BasePart") then c:Destroy() end end
  fx("VolcanoPlume", R, crater + Vector3.new(0, 2, 0), 1); fx("Fire_Crimson", R, crater + Vector3.new(0, 1, 0), 4)
  local rng = Random.new(7)
  for i = 1, 9 do local an = i / 9 * math.pi * 2 + rng:NextNumber(-0.2, 0.2); local r = rng:NextNumber(14, 24)
    local x, z = crater.X + math.cos(an) * r, crater.Z + math.sin(an) * r
    local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -200, 0), rp)
    if hit then local _, cp = mesh("M_LavaRocks", R, {pos = hit.Position, size = P.M_LavaRocks.PrimaryPart.Size * rng:NextNumber(0.8, 1.6), name = "LavaRocks"})
      cp.CFrame = CFrame.new(hit.Position + Vector3.new(0, cp.Size.Y * 0.3, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.3), 0) end end
end

local function Nature() -- the 33 part-built palms (~2.3k parts) -> AI palm mesh; + flowering trees / bushes per district
  local N = MAP.Nature; local rng = Random.new(139)
  for _, isl in ipairs(N:GetChildren()) do for _, c in ipairs(isl:GetChildren()) do
    if c:IsA("Model") and c.Name:lower():find("palm") and c.Name ~= "Palm" then
      local cf, sz = c:GetBoundingBox(); local base = cf.Position - Vector3.new(0, sz.Y / 2, 0); c:Destroy()
      local hit = workspace:Raycast(base + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0), rp); local gy = hit and hit.Position.Y or base.Y
      local h = math.clamp(sz.Y, 18, 34) * rng:NextNumber(0.9, 1.1)
      local m, mp = mesh("M_Palm", isl, {pos = Vector3.new(base.X, gy - 0.6, base.Z), h = h, yaw = rng:NextNumber(0, 360), name = "Palm"})
    end end end
  local D = N:FindFirstChild("RevampDecor"); if D then D:Destroy() end
  D = Instance.new("Folder"); D.Name = "RevampDecor"; D.Parent = N
  rng = Random.new(1390); local placed = {}
  local function scatter(center, r0, r1, count, proto, hmin, hmax, minD)
    local n, tries = 0, 0
    while n < count and tries < count * 30 do tries += 1
      local an = rng:NextNumber(0, math.pi * 2); local r = rng:NextNumber(r0, r1)
      local hit = workspace:Raycast(Vector3.new(center.X + math.cos(an) * r, center.Y + 80, center.Z + math.sin(an) * r), Vector3.new(0, -200, 0))
      local far = true; if hit then for _, q in ipairs(placed) do if (q - hit.Position).Magnitude < minD then far = false end end end
      if hit and far and hit.Instance == workspace.Terrain and hit.Normal.Y > 0.85 and (hit.Material == Enum.Material.Grass or hit.Material == Enum.Material.LeafyGrass)
        and math.abs(hit.Position.Y - center.Y) < 25 then
        local _, mp = mesh(proto, D, {pos = hit.Position - Vector3.new(0, 0.4, 0), h = rng:NextNumber(hmin, hmax), yaw = rng:NextNumber(0, 360), collide = proto ~= "M_Bush", shadow = proto ~= "M_Bush"})
        table.insert(placed, hit.Position); n += 1
      end
    end
  end
  for _, s in ipairs({{Vector3.new(-330, 97, 772), 44, 80}, {Vector3.new(-300, 118, 560), 32, 60}, {Vector3.new(-420, 207, 380), 40, 75},
    {Vector3.new(-560, 168, 462), 24, 55}, {Vector3.new(292, 143, 352), 26, 60}, {Vector3.new(40, 104, 815), 36, 70},
    {Vector3.new(100, 124, 630), 20, 55}, {Vector3.new(-612, 82, 815), 20, 45}}) do
    scatter(s[1], s[2], s[3], 3, "M_TreeBloom", 18, 26, 16); scatter(s[1], s[2] - 8, s[3], 8, "M_Bush", 3, 5, 5)
  end
end

-- Temple(); RuneCircle(); AltarBeaconShrine(); StairsAndBridges(); RedGateAndArena(); Village(); JungleSeaVolcano(); Nature()
return "pick the district functions to run"
