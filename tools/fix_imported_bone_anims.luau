--!strict
-- tools/fix_imported_bone_anims.luau (B165) -- run with execute_luau in the EDIT datamodel.
--
-- WHY: Studio's 3D Importer turns a skinned (Bone) rig's glTF clips into KeyframeSequences that do NOT
-- play right on the imported rig: every bone comes out rolled around its own length (Bakunawa: upper
-- spine 139 deg, head 91 deg off Blender), so the mesh twists and reads as "inside out" in a match.
-- Measured (B165): the importer's key P relates to the true per-bone Transform T by
--     T = (C^-1 * mirrorY(C * P)).Rotation        C = the bone's rest CFrame on the imported rig
-- (a Y-axis mirror of the parent space), with no translation for non-root bones (they never move in
-- Blender), and for the ROOT bone: keep P's translation, rotation = C.Rotation^-1 * P.Rotation (strips
-- the 180 deg facing turn the importer bakes into the root). Verified against Blender world deltas and
-- a side-by-side render. A root bone's Transform translation (hover) is ignored by Roblox.
--
-- USE: import the GLB, then set RIG + SOURCE below (SOURCE = the importer's RBX_ANIMSAVES folder for that
-- import), run, and publish the *_Fixed sequences (Save to Roblox; "Overwrite an existing asset" keeps ids).

local RIG = workspace:FindFirstChild("Scene") -- the freshly imported rig (bones at rest)
local SOURCE = game.ServerStorage.RBX_ANIMSAVES:FindFirstChild("Scene")
local DEST = SOURCE
local CLIPS = { "Idle", "Attack", "Eclipse" }

assert(RIG and SOURCE, "set RIG and SOURCE")

local rest: { [string]: CFrame } = {}
for _, d in RIG:GetDescendants() do
	if d:IsA("Bone") then
		rest[d.Name] = d.CFrame
	end
end

local function mirrorY(cf: CFrame): CFrame
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return CFrame.new(x, -y, z, r00, -r01, r02, -r10, r11, -r12, r20, -r21, r22)
end

local made = {}
for _, name in CLIPS do
	local src = SOURCE:FindFirstChild(name)
	if src then
		local old = DEST:FindFirstChild(name .. "_Fixed")
		if old then old:Destroy() end
		local ks = src:Clone()
		ks.Name = name .. "_Fixed"
		for _, p in ks:GetDescendants() do
			if p:IsA("Pose") then
				local C = rest[p.Name]
				if C == nil then
					p:Destroy() -- non-bone nodes (VFX planes etc.)
				elseif p.Name == "Root" then
					p.CFrame = CFrame.new(p.CFrame.Position) * (C.Rotation:Inverse() * p.CFrame.Rotation)
				else
					p.CFrame = (C:Inverse() * mirrorY(C * p.CFrame)).Rotation
				end
			end
		end
		ks.Parent = DEST
		table.insert(made, ks.Name)
	end
end
return "made " .. table.concat(made, ", ") .. " -- set Loop/Priority + markers, then publish"
