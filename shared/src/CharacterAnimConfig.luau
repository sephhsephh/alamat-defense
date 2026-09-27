--!strict
-- CharacterAnimConfig (SHARED CANON -- deploy path ReplicatedStorage.Configs.Global.CharacterAnimConfig)
-- The PLAYER character's own animations, one field per clip. Added B91. PURE: no services, no state,
-- no requires -- safe to deploy anywhere. MovementController (shared, both Places) is its only reader.
--
-- ===== TO SWAP OR ADD A CLIP: EDIT ONE `Id` BELOW. NOTHING ELSE. =====
-- Paste the number ("140055950289677"), or "rbxassetid://...", or a plain number -- all three are
-- accepted. Then re-hash this file and copy it to the OTHER Place (it is shared canon, so it must be
-- byte-identical in the Game, the Lobby and shared/src/).
--
-- ===== AN EMPTY Id IS NORMAL, NOT AN ERROR =====
--   * Walk / Run-less sprint / Jump / Fall / Idle with Id = "" keep ROBLOX'S DEFAULT clip, because
--     the controller simply never writes that slot into the stock `Animate` script.
--   * Dash / DoubleJump with Id = "" play NOTHING (user, B91) -- Roblox has no default for them.
--   * An Id that fails to load is treated exactly like an empty one: one [DIAG] warning per id per
--     session, then the slot falls back. A broken id never T-poses or freezes the character.
--
-- ===== THE RIG =====
-- Both Places spawn R15 (measured live, B91). An R6 clip on an R15 rig loads fine and then moves
-- NOTHING -- a silent no-op that looks like a script bug. Author every clip on an R15 rig. If the
-- character's rig ever differs from `RigType`, the controller writes no clip at all and says so once.
--
-- ===== PRIORITY: the published priority does not matter here =====
-- MEASURED B91: Roblox's Animate plays every clip it owns at CORE priority, whatever the clip was
-- published at (the B91 walk was published at Action and still plays at Core). Dash / DoubleJump /
-- sprint-Run are played by our own code at the `Priority` below, which likewise overrides it.
--
-- ===== WHERE EACH CLIP GOES (user, B91 -- "Walk = normal, Run = sprint") =====
-- Roblox's stock R15 Animate BLENDS its walk and run slots by speed: walk only below ~6.7 studs/s,
-- run only above ~13.5. Our normal WalkSpeed is 16, so the stock "walk" slot is almost never seen.
-- Therefore:
--   Walk       -> BOTH Animate slots (walk.WalkAnim AND run.RunAnim): this is what you see at speed 16.
--   Run        -> NOT an Animate slot. Played by MovementController only while SPRINT is on (toggle or
--                 AlwaysSprint), grounded and moving, at `Speed` -- so Animate's ~3.7x time-warp at
--                 sprint speed does not apply to it. Empty = sprint keeps showing the Walk clip.
--   Jump       -> jump.JumpAnim (the take-off; Roblox switches to Fall after ~0.3 s).
--   Fall       -> fall.FallAnim (airborne / falling).
--   Idle       -> idle.Animation1 AND idle.Animation2 (Roblox's two idle variants).
--   DoubleJump -> played once when the double jump fires.
--   Dash       -> played once when the dash fires. `FitToDash = true` time-scales the clip so it
--                 lasts exactly MovementConfig.DashDuration (0.22 s) -- a 1 s clip on a 0.22 s dash
--                 reads as a bug.

local CharacterAnimConfig = {}

CharacterAnimConfig.RigType = "R15"

export type Clip = {
	Id: string | number,
	Speed: number?,       -- owned clips only (Run / DoubleJump / Dash): playback speed, 1 = as authored;
	                      -- ignored by Dash while FitToDash is on
	Priority: string?,    -- owned clips only: an Enum.AnimationPriority name
	FitToDash: boolean?,  -- Dash only: stretch/squeeze the clip to the dash's duration
}

CharacterAnimConfig.Clips = {
	-- Animate slots (empty = Roblox default)
	Walk = { Id = "140055950289677" } :: Clip,
	Jump = { Id = "" } :: Clip,
	Fall = { Id = "" } :: Clip,
	Idle = { Id = "" } :: Clip,

	-- Played by MovementController (empty = nothing extra plays)
	-- Action2 so the sprint clip sits above Animate's Core walk (and anything at Action); Action3 so a
	-- dash / double jump beats the sprint clip.
	Run = { Id = "120571919442157", Speed = 1.5, Priority = "Action2" } :: Clip,
	DoubleJump = { Id = "", Speed = 1.0, Priority = "Action3" } :: Clip,
	Dash = { Id = "89258902903203", Speed = 1.0, Priority = "Action3", FitToDash = false } :: Clip,
}

-- "rbxassetid://<digits>" for a filled slot, nil for an empty or unreadable one. The ONE place an Id
-- is interpreted, so a new accepted format is a change here and nowhere else.
function CharacterAnimConfig.AssetId(slot: string): string?
	local clip = (CharacterAnimConfig.Clips :: any)[slot] :: Clip?
	if clip == nil then
		return nil
	end
	local digits = string.match(tostring(clip.Id), "(%d+)%s*$")
	if digits == nil or tonumber(digits) == 0 then
		return nil
	end
	return "rbxassetid://" .. digits
end

return CharacterAnimConfig
