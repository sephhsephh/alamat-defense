-- tools/hash_shared.luau
-- TOOLVERSION: B34-1
-- DRIFT CHECK: run via execute_luau (Edit datamodel) in ANY Place at bootstrap.
-- Prints fnv1a32 hashes of the deployed shared canon; compare against shared/manifest.json.
-- Anything absent in this Place returns "MISSING" (expected before its first deploy).
--
-- TWO KINDS OF CANON (both first-class since 2026-08-06, ADR-0005):
--   MODULES   -- LuaSourceContainer: hash of the exact Source bytes. Unchanged since 2026-07-17,
--                so every historical module hash stays valid.
--   TEMPLATES -- GuiObject subtrees (the UI kit): hash of a CANONICAL SERIALISATION of the tree
--                (sorted children, whitelisted + sorted properties, attributes, tags).
--                See ADR-0005 for the format, the whitelist rationale and the known limits.

local CollectionService = game:GetService("CollectionService")

local function fnv1a(s: string): string
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		local lo = bit32.band(h, 0xFFFF)
		local hi = bit32.rshift(h, 16)
		h = bit32.band(lo * 16777619 + bit32.lshift(bit32.band(hi * 16777619, 0xFFFF), 16), 0xFFFFFFFF)
	end
	return string.format("%08x", h)
end

local function resolve(path: string): Instance?
	local node: Instance = game
	for seg in string.gmatch(path, "[^%.]+") do
		local child = node:FindFirstChild(seg)
		if not child then
			return nil
		end
		node = child
	end
	return node
end

-- ===== Canonical value formatting =====
-- Floats are printed at fixed precision so Studio's float noise cannot flip a hash.
local function num(n: number): string
	return string.format("%.4f", n)
end

local function fmt(v: any): string?
	local t = typeof(v)
	if t == "number" then
		return num(v)
	elseif t == "boolean" then
		return tostring(v)
	elseif t == "string" then
		return string.format("%q", v)
	elseif t == "EnumItem" then
		return tostring(v) -- "Enum.Font.GothamBold"
	elseif t == "UDim" then
		return "UDim(" .. num(v.Scale) .. "," .. num(v.Offset) .. ")"
	elseif t == "UDim2" then
		return "UDim2(" .. num(v.X.Scale) .. "," .. num(v.X.Offset) .. "," .. num(v.Y.Scale) .. "," .. num(v.Y.Offset) .. ")"
	elseif t == "Vector2" then
		return "V2(" .. num(v.X) .. "," .. num(v.Y) .. ")"
	elseif t == "Vector3" then
		return "V3(" .. num(v.X) .. "," .. num(v.Y) .. "," .. num(v.Z) .. ")"
	elseif t == "Color3" then
		-- 0-255 ints: the authoring unit, and immune to float round-tripping.
		return string.format("C3(%d,%d,%d)",
			math.round(v.R * 255), math.round(v.G * 255), math.round(v.B * 255))
	elseif t == "Rect" then
		return "Rect(" .. num(v.Min.X) .. "," .. num(v.Min.Y) .. "," .. num(v.Max.X) .. "," .. num(v.Max.Y) .. ")"
	elseif t == "ColorSequence" then
		local parts = {}
		for _, kp in ipairs(v.Keypoints) do
			table.insert(parts, string.format("%s:%d,%d,%d", num(kp.Time),
				math.round(kp.Value.R * 255), math.round(kp.Value.G * 255), math.round(kp.Value.B * 255)))
		end
		return "CS[" .. table.concat(parts, " ") .. "]"
	elseif t == "NumberSequence" then
		local parts = {}
		for _, kp in ipairs(v.Keypoints) do
			table.insert(parts, num(kp.Time) .. ":" .. num(kp.Value) .. "/" .. num(kp.Envelope))
		end
		return "NS[" .. table.concat(parts, " ") .. "]"
	elseif t == "Font" then
		return "Font(" .. tostring(v.Family) .. "," .. tostring(v.Weight) .. "," .. tostring(v.Style) .. ")"
	elseif t == "BrickColor" then
		return "BC(" .. tostring(v) .. ")"
	end
	return nil -- unsupported type: deliberately ignored (see ADR-0005)
end

-- ===== Property whitelist =====
-- By NAME, not by class: read attempts are pcall'd, so a name simply does not apply to a class
-- that lacks it. Add a property here when it starts carrying design intent -- and say so in the
-- changelog, because adding one CHANGES every template hash (ADR-0005 "extending the whitelist").
local PROPS = {
	-- GuiObject geometry / paint
	"Size", "Position", "AnchorPoint", "Rotation", "Visible", "ZIndex", "LayoutOrder",
	"ClipsDescendants", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency",
	"BorderSizePixel", "BorderColor3", "BorderMode", "GroupTransparency", "GroupColor3",
	-- Text
	"Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "TextTransparency",
	"TextXAlignment", "TextYAlignment", "TextStrokeColor3", "TextStrokeTransparency",
	"RichText", "LineHeight", "FontFace", "Font", "MaxVisibleGraphemes",
	-- Image
	"Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize",
	"ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode",
	-- Buttons
	"AutoButtonColor", "Active", "Selectable", "Modal",
	-- ScrollingFrame
	"CanvasSize", "CanvasPosition", "AutomaticCanvasSize", "ScrollBarThickness",
	"ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollingDirection",
	"ElasticBehavior", "VerticalScrollBarInset", "HorizontalScrollBarInset",
	-- ViewportFrame (its 3D CONTENTS are out of scope -- see ADR-0005)
	"Ambient", "LightColor", "LightDirection", "FieldOfView",
	-- UI modifiers
	"CornerRadius",                                            -- UICorner
	"Thickness", "Color", "Transparency", "ApplyStrokeMode", "LineJoinMode", "Enabled", -- UIStroke
	"Offset",                                                  -- UIGradient (Color/Rotation/Transparency covered above)
	"Padding", "PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight",
	"FillDirection", "SortOrder", "HorizontalAlignment", "VerticalAlignment",
	"HorizontalFlex", "VerticalFlex", "ItemLineAlignment", "Wraps",
	"CellSize", "CellPadding", "StartCorner", "FillDirectionMaxCells",
	"AspectRatio", "AspectType", "DominantAxis",
	"MaxTextSize", "MinTextSize",
	"Scale",                                                   -- UIScale
	"MaxSize", "MinSize",                                      -- UISizeConstraint
}

-- ===== Canonical serialisation of an instance subtree =====
local function serialise(inst: Instance, depth: number): string
	local fields = {}
	for _, prop in ipairs(PROPS) do
		local ok, value = pcall(function()
			return (inst :: any)[prop]
		end)
		if ok and value ~= nil then
			local s = fmt(value)
			if s then
				table.insert(fields, prop .. "=" .. s)
			end
		end
	end
	table.sort(fields) -- property ORDER must never affect the hash

	-- Attributes are design intent in this project (the kit is attribute-driven).
	local attrs = {}
	for k, v in pairs(inst:GetAttributes()) do
		local s = fmt(v)
		table.insert(attrs, k .. "=" .. (s or "?"))
	end
	table.sort(attrs)

	-- CollectionService tags too (e.g. "UIKitButton" is what wires a button to the kit).
	local tags = CollectionService:GetTags(inst)
	table.sort(tags)

	local head = string.format("%d|%s|%s|%s|{%s}|[%s]",
		depth, inst.ClassName, inst.Name,
		table.concat(fields, ";"), table.concat(attrs, ";"), table.concat(tags, ","))

	-- ViewportFrame 3D CONTENTS are deliberately NOT hashed: they are display rigs owned by
	-- AD-TowerModels and swapped at runtime by the controllers. Including them would make UI
	-- drift trip on every unrelated rig change. The ViewportFrame's own properties ARE hashed.
	local lines = { head }
	if not inst:IsA("ViewportFrame") then
		local kids = {}
		for _, child in ipairs(inst:GetChildren()) do
			table.insert(kids, serialise(child, depth + 1))
		end
		-- Sorting the SERIALISED children makes ordering independent of Studio's child order
		-- and still deterministic when two siblings share a name and class.
		table.sort(kids)
		for _, k in ipairs(kids) do
			table.insert(lines, k)
		end
	end
	return table.concat(lines, "\n")
end

-- Exposed so a deploy/verify script can diff two trees instead of only comparing hashes.
local function serialiseTree(inst: Instance): string
	return serialise(inst, 0)
end

-- ===== What is under drift control =====
-- Keep in sync with shared/manifest.json deployPath entries.
local MODULES = {
	ProfileTemplate = "ReplicatedStorage.Shared.ProfileTemplate",
	PlayerDataService = "ServerScriptService.Server.Data.PlayerDataService",
	ProfileStore = "ServerScriptService.Server.Data.ProfileStore",
	Signal = "ReplicatedStorage.Shared.Signal",
	-- Added B3 2026-08-09 (owner AD-Gacha): the meta-system shared algorithms (deterministic
	-- Slot + weighted Pick). LOBBY-ONLY SO FAR -- the Game place reports MISSING until Phase D's
	-- challenges need it, which is the expected state, not drift. See manifest deployed.Game.
	MetaMath = "ReplicatedStorage.Shared.MetaMath",
	-- Promoted to shared canon 2026-08-01 (A-phase Integration promotion):
	TierConfig = "ReplicatedStorage.Configs.Meta.TierConfig",
	StatGradeConfig = "ReplicatedStorage.Configs.Meta.StatGradeConfig",
	AscensionConfig = "ReplicatedStorage.Configs.Meta.AscensionConfig",
	ItemCatalog = "ReplicatedStorage.Configs.Meta.ItemCatalog",
	-- Added A6 2026-08-03 (owner AD-Game): generated resolved-stat cache (ADR-0003).
	UnitStatsCatalog = "ReplicatedStorage.Configs.Meta.UnitStatsCatalog",
	-- Added P5 2026-08-13 (owner AD-Game): the difficulty->gold curve + Insane item table. GAME-ONLY
	-- SO FAR -- the LOBBY reports MISSING until Integration deploys it for the reward preview, which
	-- is the expected state, not drift. See manifest deployed.Lobby = null.
	RewardScalingConfig = "ReplicatedStorage.Configs.Global.RewardScalingConfig",
	-- Kit CONTROLLERS, promoted 2026-08-06 (owner AD-UI). The kit's other half is TEMPLATES below.
	UIKitButton = "ReplicatedStorage.Shared.UIKit.Button",
	UIKitItemIcon = "ReplicatedStorage.Shared.UIKit.ItemIcon",
	UIKitFilterPanel = "ReplicatedStorage.Shared.UIKit.FilterPanel",
	UIKitBootstrap = "StarterPlayer.StarterPlayerScripts.UIKitBootstrap",
	-- RETIRED 2026-08-08 (B2): UIKitRewardPopup was built at A6 for Phase B gacha and never wired.
	-- The user's own StarterGui.ObtainRewardsGUI (Lobby) shipped at B1 and superseded it, so the
	-- controller AND its template were deleted in BOTH Places and dropped from the manifest
	-- (24 -> 22). Do not re-add: the catalog-resolution behaviour lives on in ObtainRewardsController.
	-- 2026-08-06: hotbar slot count + per-slot unlock levels. BOTH Places draw the same 6 slots
	-- and the same locks, so this cannot be Place-local.
	LoadoutConfig = "ReplicatedStorage.Configs.Meta.LoadoutConfig",
	-- 2026-08-06: ONE hotbar for both Places. Same look/hover/animation everywhere; each Place
	-- only supplies what a click does. Game deploy PENDING with Kit_HotbarSlot.
	UIKitHotbar = "ReplicatedStorage.Shared.UIKit.Hotbar",
	-- Added B27c 2026-08-16 (owner AD-UI): the kit's MOTION -- hover/press scaling, idle gradient
	-- drift, the tuning table behind both, and `isolate()`, the fixed-size wrapper that stops a
	-- scaling card from re-flowing its layout and shoving every sibling.
	UIKitMotion = "ReplicatedStorage.Shared.UIKit.Motion",
	-- Added B32 2026-08-19 (owner AD-UI): the kit's AUDIO. UI one-shots + music, resolved BY NAME
	-- from real `Sound` instances under SoundService, so assigning a sound is pasting an id in
	-- Studio and never a code change. CLIENT module -- the server plays sound for nobody.
	UIKitSound = "ReplicatedStorage.Shared.UIKit.Sound",
	-- Added B32 2026-08-19 (owner AD-UI): ONE confirmation dialog for the whole experience, both
	-- Places. The DESIGN is StarterGui.ConfirmationPopupUI; this is the behaviour, including the
	-- two-second grey->green gate on the Yes button for irreversible actions.
	UIKitConfirm = "ReplicatedStorage.Shared.UIKit.Confirm",
	-- Promoted B34 2026-08-20 (owner AD-UI): TOAST notifications. The GAME grew this first as
	-- Client.UI.NotificationController; B33 copied it into the Lobby for Lobby-wide use, which left
	-- TWO copies, in DIFFERENT paths, in NEITHER manifest, with only the Lobby's hardened -- a fork
	-- with no drift control. Both are retired (renamed *_RETIRED_2026-08-20) and this is the one.
	-- Same split as UIKitConfirm: the MODULE is canon, the GUI it drives (StarterGui.Notifications)
	-- stays per-Place authored art. CLIENT module; a server require degrades to print-only.
	UIKitNotify = "ReplicatedStorage.Shared.UIKit.Notify",
	-- Added B34 2026-08-20 (owner AD-UI): unit-card presentation -- the ViewportFrame camera
	-- framing and the tier paint. FOUR screens (Units, Summon, Index, Ascension) each carried
	-- their own copy; three of each were BYTE-IDENTICAL and Units differed only in where the
	-- model came from, which is a caller's concern. Four copies of a framing formula is four
	-- places for it to drift, and that drift is silent -- a card framed slightly differently on
	-- one screen just reads as an art bug.
	UIKitUnitCard = "ReplicatedStorage.Shared.UIKit.UnitCard",
	-- Promoted 2026-08-09 (Integration, owner AD-Traits): the trait rarity table. It was GAME-only,
	-- which is exactly why the Lobby could not build trait reroll (C1) or stat reroll (C2) and why
	-- trait-on-summon sat inert. The two promote TOGETHER -- TraitRegistry requires its sibling
	-- TraitDefinitions via script.Parent, so deploying one without the other breaks the require.
	TraitDefinitions = "ReplicatedStorage.Configs.Traits.TraitDefinitions",
	TraitRegistry = "ReplicatedStorage.Configs.Traits.TraitRegistry",
}

-- GuiObject subtrees. Promoted by AD-UI 2026-08-06; a Place that has not received the kit
-- reports MISSING.
local TEMPLATES = {
	Kit_Button = "ReplicatedStorage.UITemplates.Kit.Button",
	-- V2 ADOPTION (B26, 2026-08-16): the user's V2 templates REPLACED the v1 trio outright.
	-- Kit_UnitIcon / Kit_ItemIcon / Kit_HotbarSlot are RETIRED -- deleted in BOTH Places and dropped
	-- from the manifest, the same way the RewardPopup pair went at B2. Do NOT re-add them.
	-- Rarity is painted on each V2 root's UIGradient and there is NO tier border (user decision,
	-- B25); UIHoverStroke is hover-only. See docs/systems/ui-kit.md.
	Kit_ItemIconV2 = "ReplicatedStorage.UITemplates.Kit.ItemIconV2",
	Kit_ItemHoverCard = "ReplicatedStorage.UITemplates.Kit.ItemHoverCard",
	Kit_FilterPanel = "ReplicatedStorage.UITemplates.Kit.FilterPanel",
	Kit_UnitPreviewTemplate = "ReplicatedStorage.UITemplates.Kit.UnitPreviewTemplate",
	-- A6 2026-08-06: the former `Unit/ItemIconTemplate` (an A5 leftover with zero readers),
	-- RENAMED and formalised as the blueprint section 5 UnitIcon and now actually used --
	-- it is the Game hotbar's slot. Built by an IDENTICAL deterministic script in both Places
	-- and hash-matched, rather than copied.
	Kit_UnitIconV2 = "ReplicatedStorage.UITemplates.Kit.UnitIconV2",
	-- Kit_RewardPopup RETIRED 2026-08-08 (B2) alongside its controller -- see the MODULES note above.
	-- The USER'S OWN hotbar slot design, lifted from the Lobby (their design is the source of
	-- truth) so BOTH Places draw the identical slot. Game deploy PENDING until it is copied.
	Kit_HotbarSlotV2 = "ReplicatedStorage.UITemplates.Kit.HotbarSlotV2",
}

local out = {}

for name, path in pairs(MODULES) do
	local inst = resolve(path)
	if inst and inst:IsA("LuaSourceContainer") then
		table.insert(out, name .. "=" .. fnv1a((inst :: any).Source))
	else
		table.insert(out, name .. "=MISSING")
	end
end

for name, path in pairs(TEMPLATES) do
	local inst = resolve(path)
	if inst and inst:IsA("GuiObject") then
		table.insert(out, name .. "=" .. fnv1a(serialiseTree(inst)) .. "*")
	else
		table.insert(out, name .. "=MISSING")
	end
end

table.sort(out)
-- A trailing "*" marks a TEMPLATE hash (instance tree) rather than a MODULE hash (source text).
return table.concat(out, " | ")
