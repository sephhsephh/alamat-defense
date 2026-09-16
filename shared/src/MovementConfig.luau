--!strict
-- MovementConfig (SHARED CANON -- deploy path ReplicatedStorage.Configs.Global.MovementConfig)
-- The movement-feel knobs BOTH Places share: walk vs sprint speed, dash, and double jump.
-- Added B54. PURE: no services, no state, no requires -- safe to deploy anywhere.
--
-- WHY SHARED: sprint exists in both Places and must feel identical, so the numbers live once. The
-- DASH is Lobby-only, but its numbers still live here rather than in a second Lobby-local config --
-- the same reason SettingsConfig carries GameOnly/LobbyOnly entries in one shared schema: a Place
-- difference is a FIELD, never a second file to drift.
--
-- SPRINT IS A TOGGLE, NOT A HOLD (user, B54). Tapping the sprint key flips it and it STAYS flipped;
-- the `AlwaysSprint` setting (SettingsConfig) pins it on so the key never has to be pressed.

local MovementConfig = {}

-- ===== Sprint (BOTH Places) =====
-- WalkSpeed is Roblox's default 16. The controller restores exactly this on un-sprint rather than
-- assuming the Humanoid still holds it, so anything else that touches WalkSpeed cannot strand a
-- player at sprint speed.
MovementConfig.WalkSpeed = 16
MovementConfig.SprintSpeed = 56

-- ===== Dash (BOTH Places since B66) =====
-- A short horizontal burst in the direction the player is moving (or facing, when standing still).
-- DashSpeed is studs/second applied for DashDuration, then released; the cooldown starts at the
-- moment the dash BEGINS, so the usable gap is (DashCooldown - DashDuration).
MovementConfig.DashSpeed = 300
MovementConfig.DashDuration = 0.22
MovementConfig.DashCooldown = 1.5

-- Keep the burst horizontal. A dash that inherits the camera's pitch launches the player off the
-- lobby floor or drills them into it, which reads as a bug rather than a dash.
MovementConfig.DashHorizontalOnly = true

-- ===== Where the dash is allowed =====
-- Keyed by the Place name SettingsConfig.Place() returns ("Lobby" / "Game").
--
-- *** B66: THE GAME NOW DASHES TOO -- THE USER OVERRODE THEIR OWN B54 CALL. ***
-- B54's reasoning is kept here verbatim because it is still the argument AGAINST, and whoever tunes
-- this next should see it rather than rediscover it: "The Game deliberately has NO dash: it is a
-- tower-defence match where the player is a cursor, not a fighter, and a dash there would let
-- players cross placement zones in ways the match was never balanced for." The user asked for Q-dash
-- in the Game at B66 and was shown that reasoning first. **Reverting is ONE field: set Game = nil.**
-- That is exactly why B54 made this a FIELD rather than a second Lobby-local file.
--
-- ⚠ THE KEY COST: Q was ALREADY TAKEN in the Game -- tower Ability (TowerSelectionUI) and
-- "Return to Lobby" on the end screen (MatchEndUI). A ContextActionService bind SINKS the key and
-- marks it gameProcessed, which would have killed BOTH silently. At the user's call the Game's
-- Ability moved Q -> V and the end screen's Return to Lobby moved Q -> L, so dash owns Q in both
-- Places and nothing shares it. B54's header claim that "the two never coexist" is now obsolete.
MovementConfig.DashPlaces = { Lobby = true, Game = true }

function MovementConfig.DashAllowed(place: string?): boolean
	return place ~= nil and MovementConfig.DashPlaces[place] == true
end

-- ===== Double jump (BOTH Places, B66 -- user) =====
-- One extra jump per airborne stretch, on the SAME input as the first (Space / gamepad A / the
-- mobile jump button) via UserInputService.JumpRequest -- so it costs no new binding and works on
-- every platform for free, the same reason sprint and dash go through ContextActionService.
--
-- Allowed in BOTH Places (user, B66). The placement-zone worry recorded above for dash is much
-- weaker here: this is a vertical hop, not a 300 studs/s horizontal burst, so it does not carry a
-- player ACROSS anything. If it ever needs restricting, it restricts the same way dash does.
MovementConfig.DoubleJumpPlaces = { Lobby = true, Game = true }

-- Scale on the character's OWN jump strength, never an absolute number: Roblox characters may use
-- either JumpPower or JumpHeight, and a hardcoded velocity would feel wrong the moment either is
-- retuned. 1.0 = the second jump is as strong as the first.
MovementConfig.DoubleJumpPowerScale = 1.0

-- The jump key REPEATS while held, and JumpRequest fires on every repeat. Without a re-arm window
-- one press would spend the first jump AND the double instantly, which reads as a single tall jump.
-- This is the minimum gap after leaving the ground before a double jump may be spent.
MovementConfig.DoubleJumpRearmSeconds = 0.2

function MovementConfig.DoubleJumpAllowed(place: string?): boolean
	return place ~= nil and MovementConfig.DoubleJumpPlaces[place] == true
end

return MovementConfig
