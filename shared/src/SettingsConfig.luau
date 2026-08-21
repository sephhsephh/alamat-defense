--!strict
-- SettingsConfig.lua (SHARED CANON -- deploy path ReplicatedStorage.Configs.Global.SettingsConfig)
-- Shared source of truth for player settings: defaults, the UI schema, and a Sanitize() used on
-- BOTH sides -- the client for optimistic display, the server as the trust boundary before anything
-- is written to the profile. Never persist a raw client payload directly.
--
-- *** PROMOTED TO SHARED CANON AT B35, TO SERVE BOTH PLACES FROM ONE SCHEMA. ***
-- The user's requirement: "there will be one settings system for both game and lobby. But some
-- settings will only be available while in game, and some only in lobby. But both should use same
-- structure, same gui." So each entry now declares TWO extra things:
--
--   Scope = "Both" | "GameOnly" | "LobbyOnly"   -- where the entry is SHOWN
--   Kind  = "Preference" | "Action"             -- whether it PERSISTS or just fires
--
-- *** THE TRAP, AND IT IS THE WHOLE REASON Sanitize IGNORES Scope: ***
-- One profile serves both Places. If Sanitize dropped out-of-scope keys, then the moment a player
-- changed any setting in the LOBBY, every GameOnly preference they had (AutoSkipWave, LowDetail...)
-- would be sanitized out of the payload and PERMANENTLY LOST -- and the reverse in the Game. So
-- Sanitize processes EVERY Preference entry regardless of Scope, always. Scope decides what the
-- SCREEN RENDERS, and nothing else. Do not "optimise" Scope into Sanitize.
--
-- Actions persist NOTHING and have no Default, so Sanitize skips them entirely -- storing a button
-- press as a preference is how a "Restart Match" ends up saved to a profile.

local SettingsConfig = {}

SettingsConfig.Defaults = {
	EnableVFX = true,      -- combat particles, tracers, damage numbers
	LowDetail = false,     -- trims heavy client visuals (shadows, cone segments, dmg numbers)
	SoundVolume = 1,       -- 0..1 SFX volume (0 = muted). SEE THE KEY-NAME NOTE BELOW.
	MusicVolume = 0.5,     -- 0..1 BGM volume; quieter than SFX by default so music sits under play
	UIVolume = 1,          -- 0..1 button clicks/hovers
	AutoSkipWave = false,  -- auto-cast the skip vote as soon as the button appears
	ShowHealthBar = true,      -- show floating health bars over non-boss enemies
	SimplifyHealthBar = false, -- when on: no health text, no tween/damage-trail (instant bars)
	SkipRevealAnim = false,    -- skip the reward reveal animation and show the result at once
}

-- *** KEY-NAME NOTE: `SoundVolume` IS THE SFX SLIDER. DO NOT RENAME IT TO `SFXVolume`. ***
-- It shipped as the only volume setting and players have real saved values under that key. The
-- LABEL changed at B35 when Music and UI got their own sliders; the KEY did not, because renaming
-- it would silently reset every existing player's volume to the default. A slightly-off key name is
-- a much smaller cost than that.

-- Category tabs for the settings side-panel, in order. "All" is special (shows everything).
-- Add a category here + tag schema entries with it to expand -- the UI builds itself from this.
SettingsConfig.Categories = { "All", "Sounds", "Game", "Performance", "Actions" }

SettingsConfig.Scopes = { Both = "Both", GameOnly = "GameOnly", LobbyOnly = "LobbyOnly" }

-- Drives the settings panel rows. Each entry's Category files it under a tab; order within a tab
-- follows this list. Type/range here is what Sanitize enforces.
-- Scope defaults to "Both" and Kind defaults to "Preference" when omitted (see normalise below).
SettingsConfig.Schema = {
	-- ===== Sounds: one slider per SoundGroup created at B32 =====
	{ Key = "MusicVolume", Type = "number", Label = "Music Volume", Min = 0, Max = 1, Category = "Sounds" },
	{ Key = "SoundVolume", Type = "number", Label = "SFX Volume", Min = 0, Max = 1, Category = "Sounds" },
	{ Key = "UIVolume", Type = "number", Label = "UI Volume", Min = 0, Max = 1, Category = "Sounds" },

	-- ===== Game =====
	{ Key = "AutoSkipWave", Type = "boolean", Label = "Auto Skip Wave", Category = "Game", Scope = "GameOnly" },
	{ Key = "ShowHealthBar", Type = "boolean", Label = "Show Health Bar", Category = "Game", Scope = "GameOnly" },
	-- The reward reveal lives in the Lobby (ObtainRewardsGUI), so the toggle belongs there. This is
	-- blueprint B3's original "skip-anim toggle in Settings" ask, finally given a home.
	{ Key = "SkipRevealAnim", Type = "boolean", Label = "Skip Reward Animation", Category = "Game", Scope = "LobbyOnly" },

	-- ===== Performance =====
	{ Key = "EnableVFX", Type = "boolean", Label = "Enable VFX", Category = "Performance", Scope = "GameOnly" },
	{ Key = "LowDetail", Type = "boolean", Label = "Low Detail Mode", Category = "Performance" },
	{ Key = "SimplifyHealthBar", Type = "boolean", Label = "Simplify Health Bar", Category = "Performance", Scope = "GameOnly" },

	-- ===== Actions (persist NOTHING) =====
	-- Scoping confirmed with the user at B35: the Game shows all three, the Lobby shows only
	-- "Teleport to Spawn". An Action with no registered handler renders DISABLED rather than
	-- pretending to work -- see ClientSettings.RegisterAction.
	{ Key = "RestartMatch", Kind = "Action", Label = "Restart Match", Category = "Actions", Scope = "GameOnly" },
	{ Key = "ReturnToLobby", Kind = "Action", Label = "Return to Lobby", Category = "Actions", Scope = "GameOnly" },
	{ Key = "TeleportToSpawn", Kind = "Action", Label = "Teleport to Spawn", Category = "Actions" },
}

-- ===== which Place are we in? =====
-- ONE definition of the assertion every script in this project makes for itself. `Workspace.Lobby`
-- is the Lobby's scene folder and exists in no other Place; it is the same test the session
-- checklists use before any write.
local cachedPlace: string? = nil
function SettingsConfig.Place(): string
	if cachedPlace == nil then
		cachedPlace = if workspace:FindFirstChild("Lobby") ~= nil then "Lobby" else "Game"
	end
	return cachedPlace :: string
end

function SettingsConfig.ScopeOf(entry: any): string
	return entry.Scope or "Both"
end

function SettingsConfig.KindOf(entry: any): string
	return entry.Kind or "Preference"
end

-- Should this entry be RENDERED in `place`? (Rendering only -- never persistence. See the trap.)
function SettingsConfig.InScope(entry: any, place: string?): boolean
	local scope = SettingsConfig.ScopeOf(entry)
	if scope == "Both" then
		return true
	end
	local p = place or SettingsConfig.Place()
	return (scope == "GameOnly" and p == "Game") or (scope == "LobbyOnly" and p == "Lobby")
end

-- Entries to draw, in schema order, for a category ("All" = everything in scope).
function SettingsConfig.EntriesFor(category: string, place: string?): { any }
	local list = {}
	for _, entry in ipairs(SettingsConfig.Schema) do
		if SettingsConfig.InScope(entry, place)
			and (category == "All" or entry.Category == category) then
			table.insert(list, entry)
		end
	end
	return list
end

-- Categories that actually have something to show here, so a Place never draws an empty tab.
function SettingsConfig.CategoriesFor(place: string?): { string }
	local list = {}
	for _, category in ipairs(SettingsConfig.Categories) do
		if #SettingsConfig.EntriesFor(category, place) > 0 then
			table.insert(list, category)
		end
	end
	return list
end

-- Returns a clean settings table: every PREFERENCE key present and type-correct, numbers clamped to
-- range, unknown keys dropped, Actions never stored. Accepts any garbage and never errors.
-- Deliberately Scope-BLIND -- see the trap at the top of this file.
function SettingsConfig.Sanitize(raw: any): { [string]: any }
	local clean = {}
	local rawTable = type(raw) == "table" and raw or {}
	for _, field in ipairs(SettingsConfig.Schema) do
		if SettingsConfig.KindOf(field) == "Preference" then
			local key = field.Key
			local value = rawTable[key]
			local default = SettingsConfig.Defaults[key]
			if field.Type == "boolean" then
				clean[key] = (type(value) == "boolean") and value or default
			elseif field.Type == "number" then
				if type(value) == "number" and value == value then -- reject NaN
					clean[key] = math.clamp(value, field.Min or 0, field.Max or 1)
				else
					clean[key] = default
				end
			else
				clean[key] = value ~= nil and value or default
			end
		end
	end
	return clean
end

return SettingsConfig
