-- B139: Lobby map VFX preset library. Paste into execute_luau (Lobby, Edit). Idempotent.
-- Authors real instances in ServerStorage.DevTools.LobbyMap.VFX: each preset is an Attachment (emitters/lights/
-- beams inside) that the district builders CLONE onto map attachments. Textures: Creator Store packs picked
-- visually (flipbook fire 11388840312, magic circles 564938805/564847326, soft beam 15270335786, streak beam
-- 3517446796, orbs 15268188662.., sparkle 6997866340, star 13001439251, glow 13001447859, smoke 14050565084)
-- + Roblox's waterfall tutorial textures (splash 16829556885/17082061238, mist 16830667309, foam 16811365086).
local DT = game.ServerStorage.DevTools.LobbyMap
local V = DT:FindFirstChild("VFX") or Instance.new("Folder"); V.Name = "VFX"; V.Parent = DT
local C = Color3.fromRGB
local function NS(t) local k = {} for i = 1, #t, 2 do table.insert(k, NumberSequenceKeypoint.new(t[i], t[i+1])) end return NumberSequence.new(k) end
local function CSq(t) local k = {} for i = 1, #t, 2 do table.insert(k, ColorSequenceKeypoint.new(t[i], t[i+1])) end return ColorSequence.new(k) end
local function preset(name) local o = V:FindFirstChild(name); if o then o:Destroy() end local a = Instance.new("Attachment"); a.Name = name; a.Parent = V; return a end
local function pe(parent, name, props) local e = Instance.new("ParticleEmitter"); e.Name = name; e.LightInfluence = 0
  for k, v in pairs(props) do e[k] = v end; e.Parent = parent; return e end

local PALETTE = {
  Gold   = {C(255,250,200), C(255,170,40),  C(255,90,20),  C(255,175,70)},
  Crimson= {C(255,230,200), C(255,70,40),   C(170,10,30),  C(255,80,50)},
  Violet = {C(250,220,255), C(190,90,255),  C(110,30,220), C(185,105,255)},
  Jade   = {C(230,255,220), C(90,255,140),  C(20,170,90),  C(100,255,150)},
  Azure  = {C(230,250,255), C(80,200,255),  C(30,90,230),  C(110,200,255)},
}

-- 1. FIRE (flipbook flame + hot core + embers + halo + light)
for key, p in pairs(PALETTE) do
  local core, mid, tip, glow = p[1], p[2], p[3], p[4]
  local a = preset("Fire_"..key)
  pe(a, "Flame", {Texture = "rbxassetid://11388840312", FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
    FlipbookMode = Enum.ParticleFlipbookMode.OneShot, Rate = 14, Lifetime = NumberRange.new(0.55, 0.8),
    Speed = NumberRange.new(3, 5), Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2.6, 0.4), NumberSequenceKeypoint.new(1, 1.6, 0.3)}),
    Color = CSq({0, core, 0.5, mid, 1, tip}), LightEmission = 1, Transparency = NS({0, 0.2, 0.8, 0.3, 1, 1}),
    Rotation = NumberRange.new(-15, 15), SpreadAngle = Vector2.new(6, 6), Acceleration = Vector3.new(0, 4, 0), ZOffset = 0.5})
  pe(a, "Core", {Texture = "rbxassetid://13001449381", Rate = 20, Lifetime = NumberRange.new(0.35, 0.5), Speed = NumberRange.new(2, 4),
    Size = NS({0, 1.6, 1, 0.4}), Color = CSq({0, C(255,255,230), 1, mid}), LightEmission = 1, Transparency = NS({0, 1, 0.2, 0.2, 1, 1}), ZOffset = 0.8})
  pe(a, "Embers", {Texture = "rbxassetid://13001439251", Rate = 6, Lifetime = NumberRange.new(1.2, 2.2), Speed = NumberRange.new(4, 8),
    SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 2, 0), Drag = 0.6, Size = NS({0, 0.35, 1, 0}),
    Color = CSq({0, tip, 1, mid}), LightEmission = 1, Transparency = NS({0, 0, 0.8, 0.2, 1, 1})})
  pe(a, "Glow", {Texture = "rbxassetid://13001447859", Rate = 3, Lifetime = NumberRange.new(1, 1.4), Speed = NumberRange.new(0, 0),
    Size = NumberSequence.new(5), Color = ColorSequence.new(glow), LightEmission = 1, Transparency = NS({0, 1, 0.5, 0.75, 1, 1}), LockedToPart = true, ZOffset = -0.5})
  local l = Instance.new("PointLight"); l.Name = "Light"; l.Color = glow; l.Brightness = 2.2; l.Range = 18; l.Shadows = false; l.Parent = a

  -- 2. MOTES: rising light motes over an area (emitter Shape = the parent part's box; builders use a flat part)
  local m = preset("Motes_"..key)
  pe(m, "Motes", {Texture = "rbxassetid://6997866340", Rate = 6, Lifetime = NumberRange.new(3, 5), Speed = NumberRange.new(1.5, 3),
    Size = NS({0, 0, 0.2, 0.55, 1, 0}), Color = ColorSequence.new(glow), LightEmission = 1, Transparency = NS({0, 0.2, 1, 1}),
    RotSpeed = NumberRange.new(-60, 60), Rotation = NumberRange.new(0, 360), Acceleration = Vector3.new(0, 0.6, 0), Drag = 0.2,
    Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, EmissionDirection = Enum.NormalId.Top})

  -- 3. SHAFT: a soft light pillar made of Beams (the old sky beams were neon bricks -- user hated them)
  local s = preset("Shaft_"..key)
  local function beam(n, tex, w0, w1, speed, len, tr)
    local b = Instance.new("Beam"); b.Name = n; b.Texture = tex; b.FaceCamera = true; b.LightEmission = 1; b.LightInfluence = 0
    b.Width0 = w0; b.Width1 = w1; b.TextureSpeed = speed; b.TextureLength = len; b.TextureMode = Enum.TextureMode.Stretch
    b.Color = CSq({0, glow, 1, mid}); b.Transparency = tr; b.Segments = 1; b.Parent = s; return b
  end
  -- tuned in Play (B139): the first pass blew out to white under bloom
  beam("Core", "rbxassetid://15270335786", 7, 2, 0.4, 1, NS({0, 0.5, 0.5, 0.8, 1, 1})).LightEmission = 0.8
  beam("Halo", "rbxassetid://15270335786", 22, 8, 0.2, 1, NS({0, 0.75, 0.5, 0.92, 1, 1})).LightEmission = 0.6
  beam("Rays", "rbxassetid://3517446796", 12, 4, 1.2, 1, NS({0, 0.6, 0.6, 0.9, 1, 1}))
  pe(s, "Rise", {Texture = "rbxassetid://6997866340", Rate = 10, Lifetime = NumberRange.new(2.5, 4), Speed = NumberRange.new(10, 18),
    Size = NS({0, 0.2, 0.3, 1.1, 1, 0}), Color = ColorSequence.new(glow), LightEmission = 1, Transparency = NS({0, 0.1, 1, 1}),
    SpreadAngle = Vector2.new(12, 12), RotSpeed = NumberRange.new(-90, 90), Rotation = NumberRange.new(0, 360)})
  -- builders add Attachment "ShaftTop" as a sibling and wire Beam.Attachment0 = this, Attachment1 = top

  -- 4. AURA: crystal / orb glow (big soft halo + sparkles + light)
  local au = preset("Aura_"..key)
  pe(au, "Halo", {Texture = "rbxassetid://13001447859", Rate = 2, Lifetime = NumberRange.new(2, 2.5), Speed = NumberRange.new(0, 0),
    Size = NumberSequence.new(16), Color = ColorSequence.new(glow), LightEmission = 1, Transparency = NS({0, 1, 0.5, 0.7, 1, 1}), LockedToPart = true, ZOffset = -2})
  pe(au, "Sparkle", {Texture = "rbxassetid://6997866340", Rate = 8, Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(0.5, 2),
    Size = NS({0, 0, 0.3, 0.9, 1, 0}), Color = ColorSequence.new(core), LightEmission = 1, SpreadAngle = Vector2.new(180, 180),
    Shape = Enum.ParticleEmitterShape.Sphere, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, RotSpeed = NumberRange.new(-120, 120)})
  local al = Instance.new("PointLight"); al.Name = "Light"; al.Color = glow; al.Brightness = 3; al.Range = 32; al.Shadows = false; al.Parent = au

  -- 5. SIGIL: a glowing magic circle on the ground (flat particle, slow spin, breathing)
  local sg = preset("Sigil_"..key)
  pe(sg, "Circle", {Texture = "rbxassetid://564938805", Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
    EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.001, 0.001), Rate = 0.5, Lifetime = NumberRange.new(4, 4),
    Size = NumberSequence.new(20), Color = ColorSequence.new(glow), LightEmission = 1, Transparency = NS({0, 1, 0.3, 0.35, 0.7, 0.35, 1, 1}),
    RotSpeed = NumberRange.new(12, 12), Rotation = NumberRange.new(0, 0), ZOffset = 0.1})
  pe(sg, "Ring", {Texture = "rbxassetid://564847326", Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
    EmissionDirection = Enum.NormalId.Top, Speed = NumberRange.new(0.001, 0.001), Rate = 0.5, Lifetime = NumberRange.new(4, 4),
    Size = NumberSequence.new(13), Color = ColorSequence.new(core), LightEmission = 1, Transparency = NS({0, 1, 0.3, 0.45, 0.7, 0.45, 1, 1}),
    RotSpeed = NumberRange.new(-20, -20), Rotation = NumberRange.new(0, 0), ZOffset = 0.2})
end

-- 6. FIREFLIES: wandering green-gold lights over an area (parent part's box)
local ff = preset("Fireflies")
pe(ff, "Flies", {Texture = "rbxassetid://6997866340", Rate = 5, Lifetime = NumberRange.new(6, 10), Speed = NumberRange.new(0.6, 1.6),
  SpreadAngle = Vector2.new(180, 180), Size = NS({0, 0, 0.15, 0.32, 0.5, 0.18, 0.6, 0.34, 0.9, 0.2, 1, 0}), Color = ColorSequence.new(C(240, 255, 150)),
  LightEmission = 1, Transparency = NS({0, 1, 0.1, 0, 0.9, 0, 1, 1}), Drag = 0.2, Acceleration = Vector3.new(0, 0.15, 0),
  Shape = Enum.ParticleEmitterShape.Box, ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume, RotSpeed = NumberRange.new(-30, 30)})

-- 7. VOLCANO: cartoon smoke plume + lava embers + crater glow
local vo = preset("VolcanoPlume")
pe(vo, "Smoke", {Texture = "rbxassetid://14050565084", FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
  FlipbookMode = Enum.ParticleFlipbookMode.Random, Rate = 4, Lifetime = NumberRange.new(9, 13), Speed = NumberRange.new(10, 14),
  Size = NS({0, 14, 1, 46}), Color = CSq({0, C(255,120,60), 0.15, C(90,70,80), 1, C(40,38,52)}), LightEmission = 0.1,
  Transparency = NS({0, 0.6, 0.2, 0.2, 1, 1}), SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(6, 1, 0),
  RotSpeed = NumberRange.new(-10, 10), Rotation = NumberRange.new(0, 360)})
pe(vo, "Embers", {Texture = "rbxassetid://13001439251", Rate = 25, Lifetime = NumberRange.new(2, 4), Speed = NumberRange.new(20, 40),
  SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, -14, 0), Size = NS({0, 1.4, 1, 0}),
  Color = CSq({0, C(255,240,150), 1, C(255,60,20)}), LightEmission = 1})
pe(vo, "Glow", {Texture = "rbxassetid://15268188662", Rate = 1.5, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(0, 0),
  Size = NumberSequence.new(70), Color = ColorSequence.new(C(255, 110, 40)), LightEmission = 1, Transparency = NS({0, 1, 0.5, 0.5, 1, 1}), LockedToPart = true})
local vl = Instance.new("PointLight"); vl.Color = C(255, 110, 40); vl.Brightness = 4; vl.Range = 60; vl.Parent = vo

-- 8. FOUNTAIN: spray up + droplets + ripple foam + mist (Roblox waterfall-tutorial textures)
local fo = preset("FountainSpray")
pe(fo, "Spray", {Texture = "rbxassetid://16808075391", Rate = 26, Lifetime = NumberRange.new(0.9, 1.2), Speed = NumberRange.new(14, 17),
  SpreadAngle = Vector2.new(9, 9), Acceleration = Vector3.new(0, -30, 0), Size = NS({0, 1, 1, 2.6}),
  Color = ColorSequence.new(C(200, 240, 255)), LightEmission = 0.6, Transparency = NS({0, 0.3, 0.7, 0.4, 1, 1}), RotSpeed = NumberRange.new(-40, 40)})
pe(fo, "Drops", {Texture = "rbxassetid://17082061238", Rate = 18, Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(9, 15),
  SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, -35, 0), Size = NS({0, 0.6, 1, 1.2}),
  Color = ColorSequence.new(C(220, 248, 255)), LightEmission = 0.7, Transparency = NS({0, 0.1, 1, 1})})
pe(fo, "Sparkle", {Texture = "rbxassetid://6997866340", Rate = 6, Lifetime = NumberRange.new(1, 1.6), Speed = NumberRange.new(6, 10),
  SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, -12, 0), Size = NS({0, 0, 0.3, 0.7, 1, 0}),
  Color = ColorSequence.new(C(200, 245, 255)), LightEmission = 1})
local fr = preset("WaterRipples")
pe(fr, "Foam", {Texture = "rbxassetid://16811365086", Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
  EmissionDirection = Enum.NormalId.Top, Rate = 3, Lifetime = NumberRange.new(1.4, 2), Speed = NumberRange.new(0.01, 0.01),
  Size = NS({0, 3, 1, 12}), Transparency = NS({0, 1, 0.15, 0.3, 1, 1}), Color = ColorSequence.new(C(220, 248, 255)), LightEmission = 0.4,
  RotSpeed = NumberRange.new(-15, 15), Rotation = NumberRange.new(0, 360)})
pe(fr, "Mist", {Texture = "rbxassetid://16830667309", Rate = 4, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(1, 3),
  Size = NS({0, 4, 1, 9}), Transparency = NS({0, 1, 0.2, 0.75, 1, 1}), Color = ColorSequence.new(C(210, 235, 255)), LightEmission = 0.3,
  SpreadAngle = Vector2.new(60, 60)})

-- 9. WATERFALL BASE: the tutorial's splash + white water + rising mist (sits at a plunge point)
local wb = preset("WaterfallBase")
pe(wb, "SplashDense", {Texture = "rbxassetid://16829556885", Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.6, 1.1), NumberSequenceKeypoint.new(1, 11.5, 2.6)}),
  Transparency = NS({0, 1, 0.5, 0.18, 1, 1}), Lifetime = NumberRange.new(0.25, 0.35), Rate = 30, Rotation = NumberRange.new(-45, 45),
  RotSpeed = NumberRange.new(-40, 40), Speed = NumberRange.new(20, 35), SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -40, 0), LightEmission = 0.5})
pe(wb, "Droplets", {Texture = "rbxassetid://17082061238", Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.6, 1.1), NumberSequenceKeypoint.new(1, 17, 2.6)}),
  Transparency = NS({0, 1, 0.1, 0.06, 0.43, 0.06, 1, 1}), Lifetime = NumberRange.new(0.15, 0.6), Rate = 20, Speed = NumberRange.new(20, 35),
  SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -40, 0), LightEmission = 0.5})
pe(wb, "RiseMist", {Texture = "rbxassetid://16830667309", Size = NS({0, 40, 1, 50}), Transparency = NS({0, 1, 0.1, 0.8, 1, 1}),
  Lifetime = NumberRange.new(4, 4), Rate = 3, RotSpeed = NumberRange.new(-10, 10), Speed = NumberRange.new(25, 25), Drag = 1, LightEmission = 0.3})
pe(wb, "Rainbow", {Texture = "rbxassetid://16828911033", Size = NumberSequence.new(50), Rotation = NumberRange.new(-20, -20),
  Speed = NumberRange.new(0, 0), Transparency = NS({0, 1, 0.5, 0.36, 1, 1}), Lifetime = NumberRange.new(2, 4), Rate = 0.25, LightEmission = 1})

return "VFX presets: "..#V:GetChildren()
