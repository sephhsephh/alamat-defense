--!strict
-- RewardScalingConfig.lua (SHARED CANON -- owner: AD-Game, added P5 2026-08-13)
-- How match GOLD scales with the player's chosen difficulty, and what INSANE mode adds.
-- Blueprint `docs/blueprints/playgui.md` section 8 is the source of these numbers.
--
-- ===== WHY THIS IS SHARED AND NOT PART OF StageConfig =====
-- Section 8: "the preview must not invent numbers ... the curve belongs in a config both sides can
-- read, and the SERVER remains the only thing that grants." Three concrete reasons it cannot live
-- in `StageConfig.Rewards`:
--   1. The Lobby's `StageRegistry` is a hand-maintained MIRROR that deliberately carries STRUCTURE
--      ONLY -- no reward table (docs/systems/play-menu.md). Putting gold numbers there would mean
--      two copies of the same figures in two Places with NO drift check on them.
--   2. The curve is IDENTICAL for every act. Triplicating it buys no tuning and creates three
--      places to desync.
--   3. `WorthinessConfig` is the counter-example and it does NOT apply: the Lobby reads worthiness
--      as a stored RESULT off the profile. The reward preview must compute its number BEFORE the
--      match exists, so there is nothing stored to read. That is a real cross-Place read.
-- Per-act tuning is preserved WITHOUT duplicating numbers: `StageConfig.Rewards.GoldCurve` NAMES a
-- curve below, so a future act points at a different curve instead of copying endpoints.
--
-- ===== THE TWO DIFFICULTY SCALES -- READ THIS BEFORE TOUCHING ANY NUMBER =====
-- There are TWO scales in this project and confusing them pays max rewards for a normal match:
--   * UI scale   1..100    -- what the PLAYER sees on the PlayGUI slider. 1 = normal, 100 = hardest.
--   * WIRE scale 100..1000 -- `DifficultyPercent`, the field in the teleport MatchLaunch payload.
--                             100 = normal (1x enemy health), 1000 = 10x. The field has kept its
--                             name, range and meaning through every contract bump to date.
-- ADR-0011: the remap is DISPLAY-ONLY and the wire format never changed. The Lobby converts
-- UI -> wire in exactly one place (`StarterGui.PlayGUI.DifficultyScale`). **This Place only ever
-- receives the WIRE value**, so it must do its own wire -> t conversion -- see `TFromWire` below.
-- Do NOT import the Lobby's module: it is Lobby-local by decision, and a client UI module has no
-- business being required by a server reward path.
--
-- NOTE the legal wire range is 1..1000 (`DifficultyConfig.MinPercent = 1`), which is WIDER than the
-- 100..1000 the slider can produce. Wire values below 100 are legal (older/dev payloads) and must
-- clamp to t = 0 rather than producing a negative t. `TFromWire` clamps; it never extrapolates.

local RewardScalingConfig = {}

-- Wire endpoints, mirroring ADR-0011's UI 1 -> 100 and UI 100 -> 1000.
RewardScalingConfig.WireAtNormal = 100
RewardScalingConfig.WireAtHardest = 1000

-- Named gold curves. Each band is { atNormal, atHardest } and is linear in t.
-- Section 8: goldMin = lerp(100, 300, t) and goldMax = lerp(300, 500, t).
RewardScalingConfig.Curves = {
	Standard = {
		GoldMin = { 100, 300 },
		GoldMax = { 300, 500 },
	},
}

RewardScalingConfig.DefaultCurve = "Standard"

-- ===== INSANE =====
-- Section 8: Insane runs the SAME gold curve and adds ITEM rewards on top. Mode is a separate axis
-- from the slider and never enters the conversion.
-- ⚠ COMMENT CORRECTED B43 2026-08-29 -- IT HAD BEEN WRONG SINCE B20.
-- This used to say the MatchLaunch payload "(v2) carries NO mode field, so in production this Place
-- always sees Normal", and that reaching Insane live still needed a v2 -> v3 change. That change
-- LANDED at B20 (2026-08-14) and was verified live end to end: the payload carries `DifficultyMode`,
-- v4 kept it unchanged, and the Insane branch fires in production. The table below is NOT
-- harness-only. The stale text survived two sessions that read it and believed it -- correcting it
-- re-hashes a shared module, which is exactly why it kept being deferred.
-- Mode remains a SEPARATE axis: it does not scale enemy health and never enters the wire -> t
-- conversion. An absent or unrecognised mode fails SAFE to Normal, the branch that pays no items.
RewardScalingConfig.ModeNormal = "Normal"
RewardScalingConfig.ModeInsane = "Insane"

-- ⚠ EVERY ItemId HERE MUST EXIST IN ItemCatalog, and a CURRENCY-kind id is credited to
-- Data.Currencies, not Data.Items -- RewardCalculator routes by the catalogue's Kind (B45). An
-- uncatalogued id is refused loudly and written nowhere, the same stance as GrantService's
-- invariant 4 in the Lobby.
RewardScalingConfig.InsaneItems = {
	{ ItemId = "BannerTicket", DisplayName = "Banner Ticket", Rarity = "Rare", Count = 1 },
	{ ItemId = "TraitRerollToken", DisplayName = "Trait Reroll Token", Rarity = "Epic", Count = 1 },
	-- B45: the ONE source of StatRerolls, which C2's stat reroll spends. Deliberately the same
	-- faucet TraitRerollToken already uses -- C1 was reachable and C2 was not purely because this
	-- line did not exist and the id was uncatalogued.
	{ ItemId = "StatRerolls", DisplayName = "Stat Reroll", Rarity = "Rare", Count = 1 },
}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- THE ONE CONVERSION IN THIS PLACE. WIRE (100..1000) -> t (0..1).
-- t = (wire - 100) / 900, clamped. Do NOT feed this a UI 1..100 value: UI 100 ("hardest") would
-- arrive as wire 100 and read as t = 0 ("normal"), and every hard run would pay minimum gold.
-- The inverse mistake is worse: treating the incoming wire 100 as if it were UI 100 reads NORMAL as
-- HARDEST and pays maximum gold for an easy match.
function RewardScalingConfig.TFromWire(wirePercent: any): number
	if type(wirePercent) ~= "number" or wirePercent ~= wirePercent then -- nil / NaN
		return 0
	end
	local span = RewardScalingConfig.WireAtHardest - RewardScalingConfig.WireAtNormal
	local t = (wirePercent - RewardScalingConfig.WireAtNormal) / span
	return math.clamp(t, 0, 1)
end

function RewardScalingConfig.GetCurve(curveId: string?): any
	return RewardScalingConfig.Curves[curveId or RewardScalingConfig.DefaultCurve]
		or RewardScalingConfig.Curves[RewardScalingConfig.DefaultCurve]
end

-- The gold BAND a match at this wire difficulty pays. Returns (min, max), both integers.
-- This is what the Lobby's reward PREVIEW renders and what the server rolls inside -- one function,
-- so the preview can never show a number the server would not pay.
function RewardScalingConfig.GoldBand(wirePercent: any, curveId: string?): (number, number)
	local curve = RewardScalingConfig.GetCurve(curveId)
	local t = RewardScalingConfig.TFromWire(wirePercent)
	local lo = math.floor(lerp(curve.GoldMin[1], curve.GoldMin[2], t) + 0.5)
	local hi = math.floor(lerp(curve.GoldMax[1], curve.GoldMax[2], t) + 0.5)
	if hi < lo then
		hi = lo
	end
	return lo, hi
end

-- Rolls the actual payout inside the band. SERVER ONLY -- the client is shown the outcome.
-- `rng` is passed in so the caller owns one advancing Random rather than seeding a fresh one per
-- match (the same reason PlayerInventoryService keeps a persistent statRng).
function RewardScalingConfig.RollGold(wirePercent: any, curveId: string?, rng: Random): number
	local lo, hi = RewardScalingConfig.GoldBand(wirePercent, curveId)
	if hi <= lo then
		return lo
	end
	return rng:NextInteger(lo, hi)
end

function RewardScalingConfig.IsInsane(mode: any): boolean
	return mode == RewardScalingConfig.ModeInsane
end

-- The items Insane adds on top of the normal drop roll. Returns a FRESH list every call so a
-- caller mutating its result cannot corrupt the config table.
function RewardScalingConfig.ItemsForMode(mode: any): { any }
	local out = {}
	if not RewardScalingConfig.IsInsane(mode) then
		return out
	end
	for _, item in ipairs(RewardScalingConfig.InsaneItems) do
		table.insert(out, {
			ItemId = item.ItemId,
			DisplayName = item.DisplayName,
			Rarity = item.Rarity,
			Count = item.Count or 1,
		})
	end
	return out
end

return RewardScalingConfig
