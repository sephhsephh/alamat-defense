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
-- COLOURS (edit freely): every tier declares a `Colors` LIST. `Color` is DERIVED from Colors[1]
-- at load, so there is exactly ONE authored source of truth per tier and the older `GetColor`
-- contract still works.
--
-- *** EVERY TIER HAS AT LEAST TWO COLOURS (user rule, B27 2026-08-16). ***
-- "there should not be a single colored tier, there will be minimum of two colors each rarity.
-- A Main color and a secondary color, the secondary color is a much darker version of the main
-- color when it only has 1 color." A tier that authors ONE colour gets its second entry DERIVED
-- at load (see `SecondaryValueScale` below) rather than hand-typed, so the authored table stays
-- the single source of truth and nobody has to keep a light/dark pair in sync by eye.
--
-- ===== B77 (2026-09-18): THE PALETTE IS THE USER'S, AND SO IS THE TIER LIST =====
-- The user authored nine tiers as nine `HotbarSlot#.InnerStroke.UIGradient`s in the new hotbar GUI
-- and asked for those gradients to BE the tier colours, everywhere, in both Places. So each tier now
-- carries `Stops` (the authored keypoints, TIMES INCLUDED) and `Rotation` (the authored gradient
-- angle) -- copying only the colours would have flattened a 45-degree three-stop sheen into an even
-- left-to-right fade and the hotbar would not have matched the design it was copied from.
--
-- `Colors` is DERIVED from `Stops` at load, so every existing caller (colorSequence, BrightestColor,
-- HoverStrokePaint, seamlessSequence, GetColor...) keeps working with no call-site change.
--
-- WARNING: B27's "every tier has at least two colours" DERIVATION IS RETIRED HERE, on purpose.
-- Common, Uncommon and Epic are authored FLAT by the user; auto-appending a darker shade would have
-- silently overridden a palette they just hand-tuned. `Darken` stays exported -- it is still the
-- right tool for a UI that wants a shadow -- it simply no longer edits this table behind their back.
--
-- RETIRED TIERS: `Exclusive` and `Bathala` are gone (user, B77). Neither had a weight on any banner,
-- a catalogued unit or a code reference outside comments, so nothing lost a tier it was using.

local TierConfig = {}

-- Low -> high. Add a tier by adding it here AND to Tiers.
TierConfig.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Limited", "Secret", "Alamat" }

-- Each tier: `Stops` = the user's authored UIGradient keypoints ({ Time, Color3 }, first 0, last 1),
-- `Rotation` = that gradient's angle. Transcribed from HotbarSlot1..9 in the B77 hotbar GUI, where
-- slot 1 was Alamat (highest) down to slot 9 Common (lowest).
TierConfig.Tiers = {
	Common    = { SortOrder = 1, Rotation = 0,  Stops = {
		{ 0.00, Color3.fromRGB(167, 167, 167) }, { 1.00, Color3.fromRGB(167, 167, 167) },
	} },
	Uncommon  = { SortOrder = 2, Rotation = 0,  Stops = {
		{ 0.00, Color3.fromRGB(0, 255, 127) },   { 1.00, Color3.fromRGB(0, 255, 127) },
	} },
	Rare      = { SortOrder = 3, Rotation = 0,  Stops = {
		{ 0.00, Color3.fromRGB(0, 0, 127) },     { 1.00, Color3.fromRGB(0, 85, 255) },
	} },
	Epic      = { SortOrder = 4, Rotation = 0,  Stops = {
		{ 0.00, Color3.fromRGB(85, 0, 255) },    { 1.00, Color3.fromRGB(85, 0, 255) },
	} },
	Legendary = { SortOrder = 5, Rotation = 45, Stops = {
		{ 0.00, Color3.fromRGB(255, 255, 0) },   { 0.50, Color3.fromRGB(255, 170, 0) },
		{ 1.00, Color3.fromRGB(255, 255, 127) },
	} },
	Mythic    = { SortOrder = 6, Rotation = 45, Stops = {
		{ 0.00, Color3.fromRGB(0, 0, 127) },     { 0.51, Color3.fromRGB(85, 170, 255) },
		{ 1.00, Color3.fromRGB(170, 85, 255) },
	} },
	Limited   = { SortOrder = 7, Rotation = 45, Stops = {
		{ 0.00, Color3.fromRGB(170, 0, 127) },   { 0.46, Color3.fromRGB(170, 255, 255) },
		{ 1.00, Color3.fromRGB(85, 0, 127) },
	} },
	Secret    = { SortOrder = 8, Rotation = 45, Stops = {
		{ 0.00, Color3.fromRGB(170, 0, 0) },     { 0.50, Color3.fromRGB(255, 85, 0) },
		{ 1.00, Color3.fromRGB(85, 0, 0) },
	} },
	Alamat    = { SortOrder = 9, Rotation = 45, Stops = {
		{ 0.00, Color3.fromRGB(255, 255, 0) },   { 0.48, Color3.fromRGB(170, 0, 255) },
		{ 1.00, Color3.fromRGB(255, 170, 0) },
	} },
}

-- ===== THE TWO-COLOUR MINIMUM =====
-- How dark the DERIVED secondary is, as a fraction of the main colour's HSV value. This is the
-- one knob -- retune it here, never per tier.
--
-- The derivation preserves HUE AND SATURATION and scales only VALUE, because a "much darker
-- version" of Rare must still read as blue; dropping saturation too would slide every tier
-- toward the same charcoal and the gradients would stop being distinguishable at a glance.
--
-- RETUNED 0.32 -> 0.62 at B27c: the user's verdict on 0.32 was "the dark is too dark, it should be a
-- SLIGHTLY darker version of its main color". At 0.32 Rare's secondary was (18,42,82) -- close enough
-- to black that the card read as a fade-to-nothing rather than a two-tone sheen. At 0.62 it is
-- (34,81,158): unmistakably the same blue, just in shadow, which is what a gradient wants.
TierConfig.SecondaryValueScale = 0.62

-- A much darker version of `color`, same hue and saturation.
function TierConfig.Darken(color: Color3, valueScale: number?): Color3
	local h, sat, v = color:ToHSV()
	return Color3.fromHSV(h, sat, math.clamp(v * (valueScale or TierConfig.SecondaryValueScale), 0, 1))
end

-- Tiers that ALREADY author several colours (Mythic's rainbow, Secret's red -> dark red) are left
-- EXACTLY as authored -- they already satisfy the rule and their palettes are deliberate. Only a
-- single-colour tier gains a derived entry.
--
-- Appending into `Colors` rather than adding a separate `Secondary` field is the whole point:
-- `colorSequence`, `seamlessSequence` and `isMultiColor` are unchanged and every tier now animates
-- instead of sitting flat, with ZERO call-site changes anywhere in either Place.
-- `Colors` is derived from the authored `Stops`, in order, DUPLICATES COLLAPSED -- a flat tier
-- authors the same colour twice (a UIGradient needs two keypoints to exist at all), and carrying
-- that duplicate into `Colors` would make `isMultiColor` claim a flat tier animates.
for _, tier in pairs(TierConfig.Tiers) do
	tier.Colors = {}
	for _, stop in ipairs(tier.Stops) do
		local colour = stop[2]
		local last = tier.Colors[#tier.Colors]
		if last == nil or last ~= colour then
			table.insert(tier.Colors, colour)
		end
	end
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
	Uncommon  = 15,
	Rare      = 25,
	Epic      = 60,
	Legendary = 150,
	Mythic    = 400,
	Limited   = 700,
	Secret    = 1000,
	Alamat    = 2500,
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

-- The tier's SECONDARY colour -- the last entry in `Colors`. For a single-authored tier that is
-- the derived dark shade; for Secret it is the authored dark red; for Mythic it is violet.
function TierConfig.GetSecondaryColor(tier: string): Color3
	local colors = TierConfig.get(tier).Colors
	return colors[#colors]
end

-- Relative luminance (Rec. 709). Used to pick the BRIGHTEST colour below; exposed because
-- "which of these reads brighter" comes up anywhere UI has to sit legibly on a tier colour.
function TierConfig.Luminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

-- THE BRIGHTEST colour in the tier's palette. **This is what a hover stroke is tinted with**
-- (user rule, B27): a stroke drawn in the tier's dark secondary reads as a shadow rather than a
-- highlight, and blindly taking `Colors[1]` would make Mythic's stroke red for no reason.
--
-- Brightness here is RELATIVE LUMINANCE, not HSV value, and the difference is not academic: by
-- HSV value Mythic's red, orange and blue all tie at 1.0 and the first one wins arbitrarily, while
-- by luminance the yellow correctly wins -- which is what the eye calls "the brightest one".
-- Ties resolve to the EARLIEST entry, so a tier's authored main colour wins a genuine tie.
-- WHICH COLOURS A HOVER STROKE SHOULD USE for this tier. Returns (color, sequence) -- exactly one
-- is non-nil, and the caller applies whichever it gets.
--
-- USER RULE, B27d: **a tier with THREE OR MORE colours outlines in ALL of them.** Only a tier whose
-- palette is the two-colour minimum (an authored main plus the derived dark secondary) collapses to
-- a single `BrightestColor`. The reasoning is that the two cases are not the same kind of palette:
-- the derived pair is ONE colour and its shadow, so the shadow half carries no information and a
-- stroke drawn in it reads as a smudge; Mythic's rainbow and any future multi-colour tier are
-- authored, and flattening them to one colour throws away the exact thing that identifies the tier.
--
-- This function only DECIDES. Applying it -- creating the stroke's child UIGradient, or removing a
-- stale one when a tier drops back to two colours -- belongs to the UI layer (`UIKitMotion`),
-- because this module must stay pure config and touch no Instances.
function TierConfig.HoverStrokePaint(tier: string): (Color3?, ColorSequence?)
	local colors = TierConfig.get(tier).Colors
	if #colors >= 3 then
		return nil, TierConfig.seamlessSequence(tier)
	end
	return TierConfig.BrightestColor(tier), nil
end

function TierConfig.BrightestColor(tier: string): Color3
	local colors = TierConfig.get(tier).Colors
	local best, bestLum = colors[1], -1
	for _, c in ipairs(colors) do
		local lum = TierConfig.Luminance(c)
		if lum > bestLum then
			best, bestLum = c, lum
		end
	end
	return best
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
-- B77: built from the AUTHORED `Stops`, so the times the user set are preserved -- Limited's pale
-- band sits at 0.46 because they put it there, not at the midpoint an even spread would invent.
function TierConfig.colorSequence(tierName: string): ColorSequence
	local tier = TierConfig.get(tierName)
	local kps = {}
	for _, stop in ipairs(tier.Stops) do
		table.insert(kps, ColorSequenceKeypoint.new(stop[1], stop[2]))
	end
	return ColorSequence.new(kps)
end

-- The tier's gradient exactly as authored: (sequence, rotation). This is what paints a hotbar
-- slot's InnerStroke, and it is the reason a slot in the Lobby and the same slot in the Game are
-- the same picture -- both read this, neither hard-codes a colour.
function TierConfig.GradientFor(tierName: string): (ColorSequence, number)
	local tier = TierConfig.get(tierName)
	return TierConfig.colorSequence(tierName), tier.Rotation or 0
end

-- Whether a tier animates its gradient (more than one colour).
-- NOTE since B27 this is TRUE FOR EVERY TIER -- the two-colour minimum guarantees it. It is kept
-- because it is the honest expression of the question, and because a future tier could in
-- principle opt out. It had no callers outside this module when the minimum landed.
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
