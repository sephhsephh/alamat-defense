--!strict
-- MovementConfig (SHARED CANON -- deploy path ReplicatedStorage.Configs.Global.MovementConfig)
-- The movement-feel knobs BOTH Places share: walk vs sprint speed, and the LOBBY-only dash.
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

-- ===== Dash (LOBBY only) =====
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
-- Keyed by the Place name SettingsConfig.Place() returns ("Lobby" / "Game"). The Game deliberately
-- has NO dash: it is a tower-defence match where the player is a cursor, not a fighter, and a dash
-- there would let players cross placement zones in ways the match was never balanced for.
MovementConfig.DashPlaces = { Lobby = true }

function MovementConfig.DashAllowed(place: string?): boolean
	return place ~= nil and MovementConfig.DashPlaces[place] == true
end

return MovementConfig
