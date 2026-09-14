--!strict
-- WeekendRushConfig (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.WeekendRushConfig)
-- The "Weekend Rush" buff window (B57, user). PURE: no services, no state, no requires.
--
-- A time WINDOW, not a stored buff: active for everyone during the weekend, so it needs no profile
-- field, no writer and no schedule. Active state and the countdown are DERIVED from os.time(), exactly
-- like the Luck buff's expiry is a comparison and never a write.
--
-- ===== WHY SHARED (promoted B58) =====
-- BOTH Places read this window and they must agree to the second: the LOBBY draws the Buffs card and
-- its countdown, the GAME applies the actual x2 in RewardCalculator.GrantForPlayer. Two copies of one
-- clock is a bug waiting for a Friday -- a Place difference here pays double in one Place while the
-- other says the buff is over. B57/B57c shipped it as a Lobby-local module plus a byte-identical Game
-- copy ONLY because the repo shell was down and the promotion could not be committed safely.
--
-- ===== THE WINDOW (user, B57): Friday -> Monday =====
-- Active from Friday 00:00 up to (not including) Monday 00:00, measured in the configured timezone.
-- os.time() is UTC; TimezoneOffsetHours shifts the clock the window is measured against.

local WeekendRushConfig = {}

WeekendRushConfig.Title = "Weekend Rush"
WeekendRushConfig.Subtitle = "x2 Rewards and Exp"
WeekendRushConfig.Description = "Earn double rewards when clearing challenges and story modes."
WeekendRushConfig.RewardMultiplier = 2       -- what the GAME applies to rewards, XP AND drops (its read)
WeekendRushConfig.TimezoneOffsetHours = 8     -- UTC+8 (Manila) since B58 -- the window follows the user's clock

-- Days as os.date wday numbers: Sunday = 1 ... Saturday = 7. Friday = 6, Monday = 2 (exclusive end).
WeekendRushConfig.StartDay = 6   -- Friday 00:00
WeekendRushConfig.EndDay = 2     -- Monday 00:00 (exclusive)

local DAY = 86400
local WEEK = 7 * DAY

-- Seconds since the start of the configured-local week (Sunday 00:00). PURE.
local function secondsIntoLocalWeek(now: number): number
	local shifted = now + WeekendRushConfig.TimezoneOffsetHours * 3600
	local t = os.date("!*t", shifted) -- read the shifted UTC stamp as the "local" clock
	return (t.wday - 1) * DAY + t.hour * 3600 + t.min * 60 + t.sec
end

-- The window as [startSec, endSec) into the week. A window that ends on an earlier weekday than it
-- starts (Fri -> Mon) wraps past Sunday, so endSec gets a WEEK added.
local function windowBounds(): (number, number)
	local startSec = (WeekendRushConfig.StartDay - 1) * DAY
	local endSec = (WeekendRushConfig.EndDay - 1) * DAY
	if endSec <= startSec then
		endSec += WEEK
	end
	return startSec, endSec
end

function WeekendRushConfig.IsActive(now: number?): boolean
	local n = now or os.time()
	local s = secondsIntoLocalWeek(n)
	local a, b = windowBounds()
	-- The window may wrap the week boundary, so test the point both in-week and shifted a week forward.
	return (s >= a and s < b) or (s + WEEK >= a and s + WEEK < b)
end

-- Whole seconds until the window closes (Monday 00:00). 0 when not active.
function WeekendRushConfig.SecondsLeft(now: number?): number
	local n = now or os.time()
	if not WeekendRushConfig.IsActive(n) then
		return 0
	end
	local s = secondsIntoLocalWeek(n)
	local a, b = windowBounds()
	local left
	if s >= a and s < b then
		left = b - s
	else
		left = b - (s + WEEK)
	end
	return math.max(0, left)
end

return WeekendRushConfig
