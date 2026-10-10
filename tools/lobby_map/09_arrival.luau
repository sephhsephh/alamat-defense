-- B139 revamp: Arrival Plaza. Paste into execute_luau (Lobby, Edit). Idempotent (rebuilds Map.ArrivalPlaza.Revamp).
-- Needs 08_vfx_lib (VFX presets) + the AI meshes in DevTools.LobbyMap.Protos (M_*).
--[[REVAMP HELPERS (identical block at the top of every 09_* script)]]
local P = game.ServerStorage.DevTools.LobbyMap.Protos
local V = game.ServerStorage.DevTools.LobbyMap.VFX
local MAP = workspace.Lobby.Map
local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude; rp.RespectCanCollide = true
local function ground(x, z, from)
  local g = workspace:FindFirstChild("_Gallery")
  rp.FilterDescendantsInstances = g and {g} or {}
  local r = workspace:Raycast(Vector3.new(x, from or 450, z), Vector3.new(0, -900, 0), rp)
  return r and r.Position.Y or 0
end
local function sub(parent, name) local f = parent:FindFirstChild(name); if f then f:Destroy() end
  f = Instance.new("Folder"); f.Name = name; f.Parent = parent; return f end
local function mesh(name, parent, o)
  local c = P[name]:Clone(); local mp = c.PrimaryPart; local s = mp.Size
  if o.size then mp.Size = o.size elseif o.h then mp.Size = s * (o.h / s.Y) elseif o.w then mp.Size = s * (o.w / math.max(s.X, s.Z)) end
  local b = o.pos; if o.ground then b = Vector3.new(b.X, ground(b.X, b.Z, o.from), b.Z) end
  mp.CFrame = CFrame.new(b + Vector3.new(0, mp.Size.Y / 2 - (o.sink or 0), 0)) * CFrame.Angles(0, math.rad(o.yaw or 0), 0)
  mp.Anchored = true; mp.CanCollide = o.collide ~= false; mp.CastShadow = o.shadow ~= false
  if o.collide == false then mp.CanQuery = false; mp.CanTouch = false end
  if o.precise then pcall(function() mp.CollisionFidelity = Enum.CollisionFidelity.PreciseConvexDecomposition end) end
  c.Name = o.name or name:sub(3); c.Parent = parent; return c, mp
end
local function anchor(parent, name, pos, size)
  local p = Instance.new("Part"); p.Name = name; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
  p.Transparency = 1; p.Size = size or Vector3.new(1, 1, 1); p.Position = pos; p.Parent = parent; return p end
local function fx(preset, parent, pos, scale, size)
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
local function shaft(color, parent, base, height, scale)
  local p, a = fx("Shaft_"..color, parent, base, scale)
  local top = Instance.new("Attachment"); top.Name = "ShaftTop"; top.Position = Vector3.new(0, height, 0); top.Parent = p
  for _, b in ipairs(a:GetChildren()) do if b:IsA("Beam") then b.Attachment0 = a; b.Attachment1 = top end end
  return p
end
--[[END HELPERS]]

local AP = MAP.ArrivalPlaza
local C = Vector3.new(-330, 97.5, 772)
-- 1. strip the block-built look: lamp posts, banner poles, flat star/ring mosaic
for _, c in ipairs(AP:GetChildren()) do if c.Name == "LampPost" or c.Name == "BannerPole" then c:Destroy() end end
local plaza = AP.Plaza
for _, p in ipairs(plaza:GetChildren()) do
  if p.Name == "Floor" or p.Name == "Rim" then p.Transparency = 1 -- keep as the walk collider
  else p:Destroy() end
end
local R = sub(AP, "Revamp")
-- 2. the stylized sun-compass courtyard (AI mesh), visual only; the old cylinder still carries the players
mesh("M_PlazaFloor", R, {pos = C - Vector3.new(0, 1.15, 0), size = Vector3.new(72, 2.6, 72), collide = false, name = "CompassCourt", shadow = false})
-- 3. spawn sigil + rising motes over the courtyard
fx("Sigil_Gold", R, C + Vector3.new(0, 0.25, 0), 1.5)
fx("Motes_Gold", R, C + Vector3.new(0, 1, 0), 1, Vector3.new(56, 1, 56))
fx("Fireflies", R, C + Vector3.new(0, 10, 0), 1, Vector3.new(150, 18, 150))
-- 4. stone lanterns ring (8) with a warm flame in the window
for i = 0, 7 do
  local a = math.rad(22.5 + i * 45)
  local pos = C + Vector3.new(math.cos(a) * 31, 0, math.sin(a) * 31)
  local _, mp = mesh(i % 2 == 0 and "M_StoneLantern" or "M_StoneLantern2", R, {pos = pos, h = 8.5, ground = true, from = 140, yaw = -math.deg(a) + 90, name = "StoneLantern"})
  local p, at = fx("Fire_Gold", R, mp.Position + Vector3.new(0, mp.Size.Y * 0.08, 0), 0.32)
  at.Embers.Enabled = false; at.Light.Range = 16; at.Light.Brightness = 1.6
end
-- 5. great braziers flank the north road (replace the banner poles)
for _, x in ipairs({-314, -346}) do
  local _, mp = mesh("M_Brazier", R, {pos = Vector3.new(x, 0, 736), h = 9, ground = true, from = 160, name = "Brazier"})
  fx("Fire_Gold", R, mp.Position + Vector3.new(0, mp.Size.Y / 2 - 0.6, 0), 1.25)
end
return "Arrival revamp: "..#R:GetChildren().." objects"
