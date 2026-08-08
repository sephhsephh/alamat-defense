--!strict
-- MetaMath.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.MetaMath)
-- The algorithms every meta system shares, implemented ONCE (blueprint
-- docs/blueprints/phases-b-f-meta.md, preamble "Shared algorithms used everywhere").
--
--   Slot(period, offsetSec)    deterministic time bucket. Every server in the Experience
--                              computes the SAME integer from the clock alone, so featured
--                              rotations, daily resets and shop stock agree across servers
--                              with NO MessagingService and no stored state.
--   RngForSlot(slot, salt)     a Random seeded from a slot -- same slot, same draws everywhere.
--   Pick(rng, entries)         weighted choice over { { v = any, w = number }, ... }.
--                              Used by tier rolls, featured picks and (later) trait tables.
--   PickDistinct(rng, e, n)    n distinct Picks without replacement (Featured.Count > 1).
--
-- CROSS-PHASE INVARIANT 3: every reset/rotation goes through Slot(). No os.date math
-- anywhere else in the Experience.
--
-- PURE by design: no services, no state, no config reads, no os.time() unless you let it
-- default. The "8am PST" knob lives in MetaConfig.ResetOffsetSec and is passed IN as
-- offsetSec, so this module stays Place-neutral and is safe to deploy anywhere.

local MetaMath = {}

export type WeightedEntry = { v: any, w: number }

-- 32-bit FNV-1a, split lo/hi so the multiply never leaves float-exact range. Same technique
-- as tools/hash_shared.luau: a plain `h * 16777619` reaches ~2^56 and silently loses bits.
local function mix32(h: number): number
	local lo = bit32.band(h, 0xFFFF)
	local hi = bit32.rshift(h, 16)
	return bit32.band(lo * 16777619 + bit32.lshift(bit32.band(hi * 16777619, 0xFFFF), 16), 0xFFFFFFFF)
end

local function hashString(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = mix32(bit32.bxor(h, string.byte(s, i)))
	end
	return h
end

MetaMath.HashString = hashString

-- floor((now + offset) / period). period 3600 = hourly, 86400 = daily.
-- offsetSec shifts the boundary: the bucket rolls over when (now + offsetSec) crosses a
-- multiple of period, so offsetSec = -57600 puts a DAILY reset at 16:00 UTC.
-- nowSec is for tests only -- production callers omit it.
function MetaMath.Slot(period: number, offsetSec: number?, nowSec: number?): number
	assert(type(period) == "number" and period > 0, "MetaMath.Slot: period must be a positive number")
	local now = nowSec or os.time()
	return math.floor((now + (offsetSec or 0)) / period)
end

-- A Random seeded from a slot number. `salt` MATTERS: without it, two banners sharing a
-- RotationPeriod would draw the identical featured set every rotation, because the seed
-- would be nothing but the slot. Pass the banner id (or any stable per-consumer string).
function MetaMath.RngForSlot(slotNumber: number, salt: string?): Random
	local seed = slotNumber
	if salt ~= nil and salt ~= "" then
		-- bit32 keeps this inside 32 bits; the sum stays float-exact.
		seed = bit32.bxor(bit32.band(slotNumber, 0xFFFFFFFF), hashString(salt))
	end
	return Random.new(seed)
end

-- Weighted choice. Entries with a missing / non-positive / NaN weight are ignored.
-- Returns nil when nothing has positive weight (callers must handle it).
function MetaMath.Pick(rng: Random, entries: { WeightedEntry }): any
	local total = 0
	for _, e in ipairs(entries) do
		local w = e.w
		if type(w) == "number" and w == w and w > 0 then
			total += w
		end
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber(0, total)
	local acc = 0
	for _, e in ipairs(entries) do
		local w = e.w
		if type(w) == "number" and w == w and w > 0 then
			acc += w
			if roll < acc then
				return e.v
			end
		end
	end

	-- Float tail: NextNumber(0, total) can land exactly on `total`. Fall back to the last
	-- positively-weighted entry rather than returning nil on a one-in-a-billion rounding.
	for i = #entries, 1, -1 do
		local w = entries[i].w
		if type(w) == "number" and w == w and w > 0 then
			return entries[i].v
		end
	end
	return nil
end

-- n distinct values, drawn without replacement and still weight-respecting. Returns fewer
-- than n when the pool runs out -- callers decide whether that is acceptable.
function MetaMath.PickDistinct(rng: Random, entries: { WeightedEntry }, count: number): { any }
	local pool = table.clone(entries)
	local out = {}
	while #out < count and #pool > 0 do
		local v = MetaMath.Pick(rng, pool)
		if v == nil then
			break
		end
		table.insert(out, v)
		for i = #pool, 1, -1 do
			if pool[i].v == v then
				table.remove(pool, i)
				break
			end
		end
	end
	return out
end

return MetaMath
