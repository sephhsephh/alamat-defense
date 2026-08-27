--!strict
-- PlayerLevelConfig.luau (SHARED CANON -- deploy path ReplicatedStorage.Configs.Meta.PlayerLevelConfig
-- in BOTH Places, byte-identical. Lobby-local from B33; PROMOTED B41 2026-08-27.)
-- THE ONE definition of how much XP an account level costs, and THE ONE rollover rule.
--
-- *** WHY THIS IS SHARED CANON AS OF B41. ***
-- It was Lobby-local for as long as nothing in the Game granted player XP, on the reasoning that
-- promoting a config with exactly one consumer buys a permanent drift obligation for no present
-- benefit. That reasoning expired the moment the Game turned out to grant XP after all: since B33
-- `RewardCalculator` -> `PlayerInventoryService.AddPlayerXP` had been adding to `Data.PlayerXP`
-- while the rollover lived HERE, in a module the Game could not see. So `PlayerLevel` never moved,
-- and every level-gated `LoadoutConfig` slot was permanently unreachable.
--
-- The GAME is now the primary consumer -- it applies the curve. The LOBBY remains the display
-- consumer -- the ExpBar. Two Places, one curve, one rollover rule, hash-matched.
--
-- *** THE CONTRACT, because two stored fields could otherwise disagree. ***
-- `Data.PlayerLevel` is AUTHORITATIVE -- it is what LoadoutConfig already keys slot unlocks off.
-- `Data.PlayerXP` is PROGRESS WITHIN THE CURRENT LEVEL, not a lifetime total. That is the reading the
-- user's own authored label states ("Level 1 (0 / 100)XP"), and it is the one that cannot desync:
-- a lifetime total plus a stored level gives you two numbers free to contradict each other.
-- So whatever GRANTS xp must roll over -- while xp >= RequiredForLevel(level): subtract,
-- level += 1 -- and it must do it through `ApplyXP` below so the rollover rule has ONE definition.
-- `PlayerInventoryService.AddPlayerXP` (Game) is that ONE caller. Do not add a second.
--
-- CURVE: user's call at B33 -- "gentle exponential", Base * Growth^(level-1), rounded to RoundTo.
-- Quick levels early, a real grind at the top. Retune by editing the three numbers below; nothing
-- else in the project hardcodes a threshold. BALANCE, OPEN FOR THE USER (B33, restated B41): at
-- Growth 1.15, reaching level 50 costs 627,540 lifetime XP -- and LoadoutConfig gates slot 6 at
-- level 50. Retuning is the user's call, not this file's to make quietly.

local PlayerLevelConfig = {}

PlayerLevelConfig.Base = 100      -- XP for level 1 -> 2
PlayerLevelConfig.Growth = 1.15   -- each level costs 15% more than the one before
PlayerLevelConfig.RoundTo = 10    -- thresholds land on tens, so the number a player sees is legible

-- XP needed to go from `level` to `level + 1`.
-- Clamped at level 1: a level below 1 is not a balance question, it is a bug upstream, and returning
-- the level-1 cost keeps the bar drawable instead of dividing by zero somewhere later.
function PlayerLevelConfig.RequiredForLevel(level: number): number
	local n = math.max(1, math.floor(level or 1))
	local raw = PlayerLevelConfig.Base * (PlayerLevelConfig.Growth ^ (n - 1))
	local step = PlayerLevelConfig.RoundTo
	return math.max(step, math.round(raw / step) * step)
end

-- What the bar needs, in one call: xp into this level, what the level costs, and the fraction.
-- Returns the fraction CLAMPED to 0..1 -- a bar wider than its track is a rendering bug, and if xp
-- ever exceeds the requirement the honest reading is "full", not "160% full".
function PlayerLevelConfig.Progress(playerLevel: number?, playerXp: number?): (number, number, number)
	local required = PlayerLevelConfig.RequiredForLevel(playerLevel or 1)
	local xp = math.max(0, playerXp or 0)
	return xp, required, math.clamp(xp / required, 0, 1)
end

-- THE ONE rollover rule. Its caller is `PlayerInventoryService.AddPlayerXP` in the GAME (B41).
-- Returns the NEW (level, xpIntoLevel, levelsGained). Pure: it reads and returns, it never writes.
--
-- Called with `gained = 0` it is a REPAIR: it drains any excess a pre-B41 profile banked while the
-- rollover was unreachable, and is a no-op on a profile that was already consistent. That property
-- is why fixing old profiles needs no migration and no new schema field -- see AddPlayerXP.
function PlayerLevelConfig.ApplyXP(level: number, xpIntoLevel: number, gained: number): (number, number, number)
	local lv = math.max(1, math.floor(level or 1))
	local xp = math.max(0, (xpIntoLevel or 0)) + math.max(0, (gained or 0))
	local levelsGained = 0
	-- Bounded on purpose: a bad grant (or a retune that shrinks the curve) must not spin forever.
	while levelsGained < 1000 do
		local need = PlayerLevelConfig.RequiredForLevel(lv)
		if xp < need then
			break
		end
		xp -= need
		lv += 1
		levelsGained += 1
	end
	return lv, xp, levelsGained
end

return PlayerLevelConfig
