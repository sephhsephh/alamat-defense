--!strict
-- MetaConfig (LOBBY-LOCAL canon, owner AD-Gacha -- see docs/systems/gacha.md)
-- The one-number knobs every meta rotation/reset shares. Blueprint phases-b-f-meta.md,
-- preamble: "Config: MetaConfig.ResetOffsetSec (your '8am PST' knob, one number)".
--
-- NOT under drift control on purpose. Nothing in the Game place reads it today, and a module
-- in shared/manifest.json costs a cross-Place sync forever (the CurrencyBar precedent, A6).
-- Phase D's challenges are the first Game-side consumer -- promote it THEN, via the shared
-- module procedure in tools/checklists.md, not speculatively now.

local MetaConfig = {}

-- Shifts every daily/periodic boundary computed with MetaMath.Slot.
-- The bucket rolls over when (os.time() + ResetOffsetSec) crosses a multiple of the period,
-- so a DAILY reset happens at UTC time (-ResetOffsetSec mod 86400).
--   -57600  -> 16:00 UTC = 08:00 PST (= 09:00 PDT)
--        0  -> 00:00 UTC
-- FIXED OFFSET, NO DST: this is deliberate. A daylight-saving-aware reset would need a
-- timezone database and would move the boundary twice a year, which silently re-rolls every
-- rotation on the changeover day. Players get a fixed wall-clock reset in UTC terms instead.
MetaConfig.ResetOffsetSec = -57600

-- Common periods, named so callers never sprinkle magic numbers.
MetaConfig.Periods = {
	Hourly = 3600,
	Daily = 86400,
	Weekly = 604800,
}

return MetaConfig
