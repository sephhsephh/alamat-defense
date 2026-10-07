--!strict
-- UnitCapacityConfig (LOBBY-LOCAL, pure) -- added B72. Owner AD-Game (crossing AD-Lobby, user go-ahead).
--
-- How many units a player may hold before a SUMMON is refused, and what it costs to raise that.
-- User decisions, 2026-09-16 (do not re-ask):
--   1. The cap starts at 200. Each upgrade adds +50 and costs 50,000 Silver. Repeatable, no ceiling.
--   2. The upgrade is sold from BOTH the Units screen and the Shop (one remote, two buttons).
--   3. At the cap a SUMMON is refused ("you don't have enough space") and NOTHING is spent. Every
--      OTHER grant -- quests, mail, codes, dailies, the starter pick, match rewards -- OVERFLOWS past
--      the cap and is never lost. So the cap is checked in ONE place (SummonService), never inside
--      GrantService or the Game's PlayerInventoryService.
--
-- The stored field is `Data.UnitSlotsPurchased` (schema v8): a COUNT of upgrades, never the cap
-- itself. Storing the count means a future re-tune of BaseCap / SlotsPerUpgrade re-prices every
-- player's cap consistently, instead of freezing whatever number was true on the day they bought.
--
-- Pure: no services, no profile access. Safe to require from the client (the Units screen and the
-- Shop row draw "187 / 200" and the price from HERE, so the number on the button and the number the
-- server charges cannot disagree).

local UnitCapacityConfig = {}

UnitCapacityConfig.BaseCap = 200
UnitCapacityConfig.SlotsPerUpgrade = 50
UnitCapacityConfig.UpgradePrice = 50000
UnitCapacityConfig.Currency = "Silver" -- must be one of GrantService's SCALAR_CURRENCIES

-- A purchased-count that is missing, negative, fractional or NaN reads as 0. Defensive: the field
-- is new at v8 and Reconcile() fills it, but a hand-edited dev profile should not crash a summon.
function UnitCapacityConfig.Purchased(raw: any): number
	if type(raw) ~= "number" or raw ~= raw or raw < 0 then
		return 0
	end
	return math.floor(raw)
end

-- The effective cap for a stored purchase count.
function UnitCapacityConfig.CapFor(purchased: any): number
	return UnitCapacityConfig.BaseCap + UnitCapacityConfig.SlotsPerUpgrade * UnitCapacityConfig.Purchased(purchased)
end

-- THE ONE unit count. `Data.Units` (and the client's `GetUnitViews().Units`) is a uuid-KEYED
-- dictionary, so `#units` is always 0 -- count with pairs, here, once. Every caller uses this.
function UnitCapacityConfig.CountUnits(units: any): number
	if type(units) ~= "table" then
		return 0
	end
	local n = 0
	for _ in pairs(units) do
		n += 1
	end
	return n
end

-- Does a batch of `incoming` new units fit? A batch is all-or-nothing: an x10 with 5 free slots is
-- refused whole rather than half-served, matching SummonService's "refuse before the spend, never
-- half-serve" rule. Note the count is taken BEFORE auto-sell, which runs after the grant -- a unit
-- that will be auto-sold still needs a slot to land in first.
function UnitCapacityConfig.HasRoom(used: number, purchased: any, incoming: number): boolean
	return used + incoming <= UnitCapacityConfig.CapFor(purchased)
end

-- The snapshot every surface renders (GetUnitViews, the purchase return value).
function UnitCapacityConfig.Snapshot(units: any, purchased: any): { Used: number, Cap: number, Purchased: number, SlotsPerUpgrade: number, Price: number, Currency: string }
	return {
		Used = UnitCapacityConfig.CountUnits(units),
		Cap = UnitCapacityConfig.CapFor(purchased),
		Purchased = UnitCapacityConfig.Purchased(purchased),
		SlotsPerUpgrade = UnitCapacityConfig.SlotsPerUpgrade,
		Price = UnitCapacityConfig.UpgradePrice,
		Currency = UnitCapacityConfig.Currency,
	}
end

return UnitCapacityConfig
