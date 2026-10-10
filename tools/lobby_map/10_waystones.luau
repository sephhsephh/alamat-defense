-- B139 revamp: travel waystones -> AI waystone mesh + colour aura + ground sigil. Keeps the runtime contract:
-- Shaft (holds TravelPrompt, now invisible), Arrival, Label. Paste the HELPERS block from 09_arrival.luau first.
local T = MAP.Travel
local function palette(c)
  local best, bd = "Gold", 1e9
  for name, col in pairs({Gold = Color3.fromRGB(255, 220, 90), Crimson = Color3.fromRGB(255, 60, 60), Violet = Color3.fromRGB(200, 90, 255),
    Jade = Color3.fromRGB(90, 255, 120), Azure = Color3.fromRGB(80, 220, 255)}) do
    local d = (c.R - col.R) ^ 2 + (c.G - col.G) ^ 2 + (c.B - col.B) ^ 2
    if d < bd then best, bd = name, d end
  end
  return best
end
local n = 0
for _, s in ipairs(T:GetChildren()) do
  local shaft, base = s:FindFirstChild("Shaft"), s:FindFirstChild("Base")
  if shaft and base then
    local crystal = s:FindFirstChild("Crystal")
    local col = s:GetAttribute("Palette") or palette(crystal and crystal.Color or Color3.new(1, 1, 1))
    s:SetAttribute("Palette", col)
    local label = s:FindFirstChild("Label", true); if label then label.Parent = shaft end
    local basePos = base.Position - Vector3.new(0, base.Size.Y / 2, 0)
    for _, c in ipairs(s:GetChildren()) do
      if c.Name ~= "Shaft" and c.Name ~= "Arrival" and c.Name ~= "Label" then c:Destroy() end
    end
    shaft.Transparency = 1; shaft.CanCollide = false
    local _, mp = mesh("M_Waystone", s, {pos = basePos, h = 11, ground = true, from = basePos.Y + 30, name = "Waystone",
      yaw = math.deg(math.atan2(shaft.Position.X - basePos.X, shaft.Position.Z - basePos.Z))})
    local top = mp.Position + Vector3.new(0, mp.Size.Y * 0.28, 0)
    local p, a = fx("Aura_"..col, s, top, 0.45); a.Light.Range = 18; a.Light.Brightness = 2
    fx("Sigil_"..col, s, Vector3.new(basePos.X, mp.Position.Y - mp.Size.Y / 2 + 0.2, basePos.Z), 0.42)
    n += 1
  end
end
return "waystones: "..n
