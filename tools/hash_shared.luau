-- tools/hash_shared.luau
-- DRIFT CHECK: run via execute_luau (Edit datamodel) in ANY Place at bootstrap.
-- Prints fnv1a32 hashes of the deployed shared modules; compare against shared/manifest.json.
-- A missing module in this Place returns "MISSING" (expected before first deploy).

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

-- Keep in sync with shared/manifest.json deployPath entries:
local MODULES = {
	ProfileTemplate = "ReplicatedStorage.Shared.ProfileTemplate",
	PlayerDataService = "ServerScriptService.Server.Data.PlayerDataService",
	ProfileStore = "ServerScriptService.Server.Data.ProfileStore",
	Signal = "ReplicatedStorage.Shared.Signal",
	-- Promoted to shared canon 2026-08-01 (A-phase Integration promotion):
	TierConfig = "ReplicatedStorage.Configs.Meta.TierConfig",
	StatGradeConfig = "ReplicatedStorage.Configs.Meta.StatGradeConfig",
	AscensionConfig = "ReplicatedStorage.Configs.Meta.AscensionConfig",
	ItemCatalog = "ReplicatedStorage.Configs.Meta.ItemCatalog",
	-- Added A6 2026-08-03 (owner AD-Game): generated resolved-stat cache (ADR-0003).
	UnitStatsCatalog = "ReplicatedStorage.Configs.Meta.UnitStatsCatalog",
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
table.sort(out)
return table.concat(out, " | ")
