-- build_stage2_rigs.luau (B175) -- run with execute_luau in the GAME place (Edit), AFTER importing
-- Downloads\BakunawaCove_Map\glb\BC_EnemyRigs.glb with the 3D Importer (Insert Using Scene Position + Anchored).
-- Builds Stage 2's three model rigs -> ServerStorage.Enemies.Stage2.{SkeletonPirate, PirateBrute, CursedGull}
-- (BilgeRat is the recoloured Stage 1 FieldRat, built separately; see docs/systems/stage2-bakunawa.md).
--
-- HOW: the GLB holds each character split per R15 body part (`<Char>_<Part>__<Mat>`, tools/maps/pirate/
-- enemy_rigs.py) plus tiny joint marker cubes (`<Char>_J_<Joint>`). For each character this clones the blocky R15
-- Grunt (AnimationController rig, same as every enemy), MOVES every rig part and joint attachment onto the model's
-- own joints (so the Grunt's Walk/Run clips bend the real model at its real shoulders/hips/knees), hides the Grunt
-- body, welds the model pieces to their parts, then scales the whole rig to its final size.
-- The gull's wings sit on the ARM bones; its shoulder attachments are turned +-90 deg about the vertical axis so the
-- walk clip's mirrored arm swing becomes a synchronized up/down FLAP.
-- Re-runnable: replaces the three rigs; the imported model is deleted at the end (it lives on in the rigs).

local SS = game:GetService("ServerStorage")
local root = workspace:FindFirstChild("BC_EnemyRigs")
assert(root, "workspace.BC_EnemyRigs missing -- import BC_EnemyRigs.glb first (and name the root BC_EnemyRigs)")

local CHARS = {
	SkeletonPirate = { height = 2.3 },  -- final height in studs (Stage 1 grunt Dirt Imp: 1.9)
	PirateBrute = { height = 3.0 },     -- tank (Iron Ox: 2.8)
	CursedGull = { span = 2.6, flap = true }, -- flyer: wingspan in studs
}
local PARTS = { "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm",
	"RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot" }
-- part -> its segment (joint at the top = where it hangs from its parent, joint at the bottom)
local SEG = {
	Head = { "Neck", "HeadTop" }, UpperTorso = { "Waist", "Neck" }, LowerTorso = { "Root", "Waist" },
}
for _, s in ipairs({ "Left", "Right" }) do
	SEG[s .. "UpperArm"] = { s .. "Shoulder", s .. "Elbow" }
	SEG[s .. "LowerArm"] = { s .. "Elbow", s .. "Wrist" }
	SEG[s .. "Hand"] = { s .. "Wrist", s .. "HandEnd" }
	SEG[s .. "UpperLeg"] = { s .. "Hip", s .. "Knee" }
	SEG[s .. "LowerLeg"] = { s .. "Knee", s .. "Ankle" }
	SEG[s .. "Foot"] = { s .. "Ankle", s .. "Toe" }
end
-- rig joint (AnimationConstraint name) -> joint marker it must sit on
local JOINT = { Root = "Root", Waist = "Waist", Neck = "Neck" }
for _, s in ipairs({ "Left", "Right" }) do
	JOINT[s .. "Shoulder"] = s .. "Shoulder"; JOINT[s .. "Elbow"] = s .. "Elbow"; JOINT[s .. "Wrist"] = s .. "Wrist"
	JOINT[s .. "Hip"] = s .. "Hip"; JOINT[s .. "Knee"] = s .. "Knee"; JOINT[s .. "Ankle"] = s .. "Ankle"
end

local function setAnchored(m, on)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then p.Anchored = on end
	end
end

local report = {}
for name, opt in pairs(CHARS) do
	-- 1. collect this character's pieces and joint markers (the importer may wrap meshes in <name>_Node models)
	local pieces, J = {}, {}
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			local base = string.gsub(d.Name, "_Node$", "")
			if d.Parent and d.Parent:IsA("Model") and d.Parent ~= root then
				local pn = string.gsub(d.Parent.Name, "_Node$", "")
				if string.find(pn, name .. "_", 1, true) == 1 then base = pn end
			end
			local jn = string.match(base, "^" .. name .. "_J_(%w+)$")
			if jn then
				J[jn] = d.Position
			else
				local part = string.match(base, "^" .. name .. "_(%w+)__")
				if part then table.insert(pieces, { inst = d, part = part }) end
			end
		end
	end
	assert(J.Neck and J.Root and J.Front, name .. ": joint markers missing")

	-- 2. the model's frame: up = +Y, forward = toward the Front marker (the importer may turn it 180 deg)
	local up = Vector3.yAxis
	local fwd = (J.Front - J.Neck) * Vector3.new(1, 0, 1)
	fwd = fwd.Unit
	local right = fwd:Cross(up)
	if (J.LeftShoulder - J.Neck):Dot(right) > 0 then
		warn("[Stage2Rigs] " .. name .. ": Left joints sit on the model's RIGHT -- the import mirrored it")
	end
	local rot = CFrame.lookAt(Vector3.zero, fwd, up) -- rig parts face the model's front (-Z = forward)
	local minY = math.huge
	for _, pc in ipairs(pieces) do
		minY = math.min(minY, pc.inst.Position.Y - pc.inst.Size.Y / 2)
	end

	-- 3. the rig: a fresh Grunt, clothes/accessories off, every part moved onto the model's joints (full size)
	local rig = SS.Enemies.Common.Grunt:Clone()
	rig.Name = name
	for _, c in ipairs(rig:GetChildren()) do
		if c:IsA("Shirt") or c:IsA("Pants") or c:IsA("Accessory") or c:IsA("BodyColors") or c:IsA("ShirtGraphic") then c:Destroy() end
	end
	setAnchored(rig, true)
	for _, pn in ipairs(PARTS) do
		local p = rig[pn]
		local a, b = J[SEG[pn][1]], J[SEG[pn][2]]
		local len = math.max(0.2, (b - a).Magnitude)
		p.Size = Vector3.new(0.4, len, 0.4)
		p.CFrame = CFrame.new((a + b) / 2) * rot
		p.Transparency = 1
		p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		for _, d in ipairs(p:GetChildren()) do
			if d:IsA("Decal") then d:Destroy() end
		end
	end
	local hrp = rig.HumanoidRootPart
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.CFrame = CFrame.new(J.Root) * rot
	-- joints: both attachments of every AnimationConstraint sit exactly on the model's joint
	for _, ac in ipairs(rig:GetDescendants()) do
		if ac:IsA("AnimationConstraint") and JOINT[ac.Name] then
			local jp = J[JOINT[ac.Name]]
			for _, att in ipairs({ ac.Attachment0, ac.Attachment1 }) do
				att.CFrame = CFrame.new(att.Parent.CFrame:PointToObjectSpace(jp))
			end
			if opt.flap and string.find(ac.Name, "Shoulder") then
				-- turn the swing axis to the model's forward axis: the arm swing becomes a wing beat (mirrored per side)
				local yaw = if string.find(ac.Name, "Left") then math.rad(90) else math.rad(-90)
				for _, att in ipairs({ ac.Attachment0, ac.Attachment1 }) do
					att.CFrame = att.CFrame * CFrame.Angles(0, yaw, 0)
				end
			end
		end
	end

	-- 4. weld the model pieces to their parts
	local count = 0
	for _, pc in ipairs(pieces) do
		local host = rig:FindFirstChild(pc.part)
		if host then
			local m = pc.inst
			m.Parent = rig
			m.Name = pc.part .. "_" .. (string.match(m.Name, "__(%w+)") or "Mesh")
			m.Anchored = true
			m.CanCollide = false; m.CanQuery = false; m.CanTouch = false; m.Massless = true
			local w = Instance.new("WeldConstraint"); w.Part0 = host; w.Part1 = m; w.Parent = m
			count += 1
		end
	end

	-- 5. scale to the final size, ground it, store it
	local ext = rig:GetExtentsSize()
	local factor = if opt.span then opt.span / math.max(ext.X, ext.Z) else opt.height / (J.HeadTop.Y - minY)
	rig:PivotTo(CFrame.new(0, 50, 0))
	rig:ScaleTo(rig:GetScale() * factor)
	setAnchored(rig, false)
	hrp.Anchored = true -- same as the Grunt: the server moves the root by CFrame
	rig:SetAttribute("Placeholder", nil)
	local old = SS.Enemies.Stage2:FindFirstChild(name)
	if old then old:Destroy() end
	rig:PivotTo(CFrame.new(0, 2, 0))
	rig.Parent = SS.Enemies.Stage2
	table.insert(report, string.format("%s: %d pieces, size %s", name, count, tostring(rig:GetExtentsSize())))
end
root:Destroy()
return table.concat(report, "\n")
