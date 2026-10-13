-- build_stage1_rigs.luau (B143) -- run with execute_luau in the GAME place (Edit).
-- Builds Stage 1's three enemy rigs from the blocky R15 Grunt (same AnimationController rig as the towers):
--   DirtImp (grunt), IronOx (tank), FieldRat (sprinter) -> ServerStorage.Enemies.Stage1.<Id>
-- Needs the AI accessory meshes in workspace._EnemyRigStage (Acc_ImpHelm, Acc_OxHelm, Acc_OxArmor, Acc_RatMask,
-- Acc_RatTail) and the face decals Face_EvilGrin / Face_Angry (image ids below). After the build the stage folder
-- can be deleted; the accessories live inside the rigs.
-- WHY anchored while scaling: the rig's joints are AnimationConstraints -- in Edit nothing solves them, so
-- ScaleTo on UNANCHORED parts shrinks the parts but leaves them where they were.

local SS = game:GetService("ServerStorage")
local stage = workspace:FindFirstChild("_EnemyRigStage")
assert(stage, "workspace._EnemyRigStage missing")

local FACES = { EvilGrin = "rbxassetid://164202174", Angry = "rbxassetid://304904077" }
local C = Color3.fromRGB

local function setAnchored(m, on)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = on end
	end
end

local function attach(m, accName, partName, offset, rot, scale)
	local mesh = stage[accName]:FindFirstChildWhichIsA("MeshPart", true):Clone()
	mesh.Name = string.gsub(accName, "^Acc_", "")
	mesh.Size = mesh.Size * scale
	mesh.CanCollide = false; mesh.CanQuery = false; mesh.CanTouch = false; mesh.Massless = true
	mesh.Anchored = true
	local host = m[partName]
	mesh.CFrame = host.CFrame * CFrame.new(offset) * rot
	mesh.Parent = m
	local w = Instance.new("WeldConstraint"); w.Part0 = host; w.Part1 = mesh; w.Parent = mesh
end

local function build(name, finalScale, colors, faceId, accs)
	local m = SS.Enemies.Common.Grunt:Clone()
	m.Name = name
	for _, c in ipairs(m:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("Accessory") or c:IsA("BodyColors") or c:IsA("ShirtGraphic") then c:Destroy() end
	end
	setAnchored(m, true)
	m:ScaleTo(1)
	m:PivotTo(CFrame.new(0, 50, 0))
	for _, p in ipairs(m:GetChildren()) do
		if p:IsA("MeshPart") then
			p.TextureID = ""
			p.Color = colors[p.Name] or colors.default
		end
	end
	if faceId then
		local d = Instance.new("Decal"); d.Name = "face"; d.Face = Enum.NormalId.Front; d.Texture = faceId; d.Parent = m.Head
	end
	for _, a in ipairs(accs) do attach(m, a[1], a[2], a[3], a[4], a[5]) end
	m:ScaleTo(finalScale)
	setAnchored(m, false)
	m.HumanoidRootPart.Anchored = true -- same as the Grunt: the server moves the root by CFrame
	local old = SS.Enemies.Stage1:FindFirstChild(name)
	if old then old:Destroy() end
	m:PivotTo(CFrame.new(0, 2, 0))
	m.Parent = SS.Enemies.Stage1
	return m
end

local LEGS = { "LowerTorso", "LeftUpperLeg", "RightUpperLeg" }
local function withLegs(t, c) for _, n in ipairs(LEGS) do t[n] = c end return t end

-- Dirt Imp: mossy-green goblin, brown loincloth, clay-pot helm with pointy ears, evil grin.
build("DirtImp", 0.31, withLegs({ default = C(112, 128, 62), LeftFoot = C(70, 48, 30), RightFoot = C(70, 48, 30) }, C(92, 62, 38)),
	FACES.EvilGrin, { { "Acc_ImpHelm", "Head", Vector3.new(0, 0.55, 0), CFrame.new(), 0.62 } })

-- Iron Ox: dark hide, iron legs, horned iron helm + riveted pauldrons. Built ~1.3x a grunt.
build("IronOx", 0.43, withLegs({ default = C(84, 56, 40), LeftHand = C(50, 36, 28), RightHand = C(50, 36, 28),
	LeftFoot = C(40, 30, 24), RightFoot = C(40, 30, 24) }, C(60, 60, 66)),
	FACES.Angry, {
		{ "Acc_OxHelm", "Head", Vector3.new(0, 0.42, 0), CFrame.new(), 0.9 },
		{ "Acc_OxArmor", "UpperTorso", Vector3.new(0, 0.15, 0), CFrame.new(), 1.32 },
	})

-- Field Rat: grey fur, pink paws, rat-head mask (snout = mesh -X, turned to face front) + curly tail. ~0.75x a grunt.
build("FieldRat", 0.27, withLegs({ default = C(128, 116, 108), LeftHand = C(232, 160, 165), RightHand = C(232, 160, 165),
	LeftFoot = C(232, 160, 165), RightFoot = C(232, 160, 165) }, C(110, 84, 60)),
	nil, {
		{ "Acc_RatMask", "Head", Vector3.new(0, 0.1, -0.15), CFrame.Angles(0, math.pi / 2, 0), 0.6 },
		{ "Acc_RatTail", "LowerTorso", Vector3.new(0, -0.2, 1.05), CFrame.Angles(0, math.pi / 2, 0), 2.4 },
	})

return "built"
