--!strict
-- TierConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.TierConfig)
-- Rarity tiers for units/items. `Order` is LAW: it drives sort order and the tier index.
--
-- SHARED since 2026-08-01 (A-phase Integration promotion). This module reconciles two
-- predecessors and REPLACES both:
--   * the Game's A3 TierConfig  -- contributed Order/SortOrder + the PascalCase API
--   * the Lobby's interim TierConfig (AD-UI 2026-07-31) -- contributed the multi-colour
--     palettes and the ColorSequence helpers, lifted verbatim
--
-- COLOURS (edit freely): every tier declares a `Colors` LIST. One colour = solid glow;
-- several = animated gradient (Mythic rainbow, Secret red -> dark red). `Color` is DERIVED
-- from Colors[1] at load, so there is exactly ONE authored source of truth per tier and the
-- older `GetColor` contract still works.
--
-- Palette note: Common..Secret use the Lobby's tuned UI values (the ones actually seen on
-- screen); Exclusive + Bathala keep A3's values since they had no Lobby counterpart.

local TierConfig = {}

-- Low -> high. Add a tier by adding it here AND to Tiers.
TierConfig.Order = { "Common", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Exclusive", "Bathala" }

TierConfig.Tiers = {
	Common    = { Colors = { Color3.fromRGB(205, 205, 215) }, SortOrder = 1 },
	Rare      = { Colors = { Color3.fromRGB(55, 130, 255) },  SortOrder = 2 }, -- blue
	Epic      = { Colors = { Color3.fromRGB(168, 70, 235) },  SortOrder = 3 }, -- purple
	Legendary = { Colors = { Color3.fromRGB(255, 205, 55) },  SortOrder = 4 }, -- yellow
	Mythic    = { Colors = {                                                   -- rainbow
		Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 170, 40), Color3.fromRGB(250, 240, 60),
		Color3.fromRGB(70, 220, 90), Color3.fromRGB(60, 150, 255), Color3.fromRGB(170, 80, 240),
	}, SortOrder = 5 },
	Secret    = { Colors = { Color3.fromRGB(255, 45, 45), Color3.fromRGB(90, 0, 0) }, SortOrder = 6 }, -- red + dark red
	Exclusive = { Colors = { Color3.fromRGB(0, 220, 200) },   SortOrder = 7 },
	Bathala   = { Colors = { Color3.fromRGB(255, 240, 150) }, SortOrder = 8 },
}

-- Derive the single representative Color from each tier's authored Colors list, so callers
-- of GetColor (and any older `.Color` reader) keep working without a second authored field.
for _, tier in pairs(TierConfig.Tiers) do
	tier.Color = tier.Colors[1]
end

-- ===== SELL VALUE (blueprint Phase C, C3 sell-dupes half) =====
-- SILVER paid for selling ONE duplicate unit of this tier. Blueprint: "multi-select in Units
-- screen -> Silver by tier (`SellValueByTier` in TierConfig)". Lives here rather than in a
-- Lobby-local module because the Game place will also need it the day match rewards or an
-- auto-sell option pay out by tier, and two copies of a price list is how the two Places
-- start quoting different prices for the same unit.
--
-- RETUNE HERE -- this table is the single authored source. Roughly x2.5 per tier: a Common
-- dupe is pocket change, a Mythic dupe is a real decision because it is ALSO ascension fodder
-- (AscensionConfig consumes one dupe per level), so selling it has to feel like giving that up.
TierConfig.SellValueByTier = {
	Common    = 10,
	Rare      = 25,
	Epic      = 60,
	Legendary = 150,
	Mythic    = 400,
	Secret    = 1000,
	Exclusive = 1500,
	Bathala   = 3000,
}

local FALLBACK_TIER = "Common"

-- ===== A3 API (strict lookups; Get returns nil for an unknown tier) =====

function TierConfig.Get(tier: string): any?
	return TierConfig.Tiers[tier]
end

function TierConfig.IsValid(tier: string): boolean
	return TierConfig.Tiers[tier] ~= nil
end

function TierConfig.GetColor(tier: string): Color3
	local t = TierConfig.Tiers[tier]
	return (t and t.Color) or TierConfig.Tiers[FALLBACK_TIER].Color
end

function TierConfig.GetSortOrder(tier: string): number
	local t = TierConfig.Tiers[tier]
	return (t and t.SortOrder) or 0
end

-- Silver paid for one duplicate of this tier.
-- DELIBERATELY falls back to 0, NOT to Common, unlike GetColor/`get`. Those fall back so the UI
-- never nil-errors on a bad tier; this one pays CURRENCY, and a typo'd or unknown tier quietly
-- minting Silver is far worse than one that pays nothing. A 0 payout is visible and reportable.
function TierConfig.GetSellValue(tier: string): number
	return TierConfig.SellValueByTier[tier] or 0
end

-- ===== UI helpers (lifted from the Lobby interim module) =====
-- NOTE: `get` differs from `Get` on purpose -- UI code must never nil-error on a bad tier,
-- so this one FALLS BACK to Common. Kept as-is so the AD-UI controllers work unchanged.

function TierConfig.get(tierName: string)
	return TierConfig.Tiers[tierName] or TierConfig.Tiers[FALLBACK_TIER]
end

-- Build a ColorSequence for a tier (a single colour still yields a valid flat sequence).
function TierConfig.colorSequence(tierName: string): ColorSequence
	local colors = TierConfig.get(tierName).Colors
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end
	local kps = {}
	for i, c in ipairs(colors) do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c))
	end
	return ColorSequence.new(kps)
end

-- Whether a tier animates its gradient (more than one colour).
function TierConfig.isMultiColor(tierName: string): boolean
	return #TierConfig.get(tierName).Colors > 1
end

-- Tiled + wrapped ColorSequence so an Offset scroll loops perfectly (end meets start).
-- Use this for animated gradients (esp. multi-colour tiers) instead of colorSequence().
function TierConfig.seamlessSequence(tierName: string): ColorSequence
	local colors = TierConfig.get(tierName).Colors
	local ext = {}
	for _, c in ipairs(colors) do table.insert(ext, c) end
	for _, c in ipairs(colors) do table.insert(ext, c) end
	table.insert(ext, colors[1])
	if #ext > 20 then return TierConfig.colorSequence(tierName) end
	local kps = {}
	for i, c in ipairs(ext) do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#ext - 1), c))
	end
	return ColorSequence.new(kps)
end

return TierConfig
