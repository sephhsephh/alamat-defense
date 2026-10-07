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
	AlwaysSprint = false,      -- B54: pin sprint ON so the sprint key never has to be pressed
	SkipTraitRerollAnim = false, -- B73: skip the trait-reroll spin AND the good-trait reveal
	SkipSummonAnim = false, -- B108 pt13: skip the summon orb + unit showcases, straight to the rewards grid
	-- B87: the Unit Manager's AUTOMATION row. These are the four standing rules the player sets
	-- once and expects the match to obey without touching a unit again. They live HERE rather than
	-- in a match-scoped table precisely so they SURVIVE the match -- "auto-upgrade new units" that
	-- forgets itself every wave is worse than not having it.
	StrictUpgradeOrder = false,     -- auto-upgrade waits for priority 1 instead of skipping to 2
	StrictQueueOrder = false,       -- queued targets are served one tower at a time, in order
	AutoUpgradeNewUnits = false,    -- a newly placed unit starts with Auto Upgrade already on
	AutoAbilitiesNewUnits = false,  -- a newly placed unit starts with auto-cast already on
	-- B111 (settings rebuild, user refs): four more, each wired in its Place.
	AutoVoteStart = false,          -- Game: auto-cast the READY vote (AutoSkipWave now covers only skips)
	ShowMatchEndRewards = true,     -- Game: the item-by-item reward reveal before the results screen
	ShowPinnedQuests = true,        -- both: the pinned-quest panel (match HUD / Lobby tracker)
	ScreenShake = true,             -- both: camera shake + screen flashes (off = Player attr ReducedMotion)
	-- B112: UI Scale (the user's refs, Misc). Applied by SettingsUI as an `AD_UIScale` UIScale on every
	-- top-level panel that has no UIScale of its own (see SettingsUI "UI SCALE").
	UIScale = 1,
	-- B112: keybinds. One flat `Key_<Action>` string per action = an Enum.KeyCode NAME, "" = unbound.
	-- Flat keys (not a nested map) so the B35 Scope trap rule holds per row and Sanitize stays per-entry.
	-- Defaults = the keys that were HARD-CODED before B112, so nobody's muscle memory changes.
	-- KEYBOARD ONLY: gamepad buttons and touch buttons stay fixed (Keybinds module header).
	Key_Sprint = "LeftShift",
	Key_Dash = "Q",
	Key_Interact = "E",
	Key_PlaceUnit = "E",
	Key_RotateUnit = "R",
	Key_CancelPlacement = "X",
	Key_UpgradeUnit = "E",
	Key_AutoUpgradeUnit = "Z",
	Key_SellUnit = "X",
	Key_TargetingUnit = "T",
	Key_UseAbility = "V",
	Key_AutoAbility = "C",
	Key_UnitManager = "F",
	Key_StageInfo = "C",
	Key_VoteSkip = "G",
	Key_ToggleAutoSkip = "",
	Key_OpenPlay = "",
	Key_OpenQuests = "K", -- B123: both Places (Game: the HUD K button)
	Key_OpenSummon = "",
	Key_OpenUnits = "J", -- B123: both Places (Game: the HUD J button; loadout locked once wave 1 starts)
	Key_OpenInventory = "",
}

-- *** KEY-NAME NOTE: `SoundVolume` IS THE SFX SLIDER. DO NOT RENAME IT TO `SFXVolume`. ***
-- It shipped as the only volume setting and players have real saved values under that key. The
-- LABEL changed at B35 when Music and UI got their own sliders; the KEY did not, because renaming
-- it would silently reset every existing player's volume to the default. A slightly-off key name is
-- a much smaller cost than that.

-- Category tabs for the settings side-panel, in order. "All" is special (shows everything, grouped by
-- category with a header each). B111: the user's reference layout -- Audio / Gameplay / Graphics / Units /
-- Enemies / Misc. `CategoryIcons` names an IconCatalog key per tab.
SettingsConfig.Categories = { "All", "Audio", "Gameplay", "Graphics", "Units", "Enemies", "Misc", "Keybinds" }
SettingsConfig.CategoryIcons = {
	All = "Gear", Audio = "Wave", Gameplay = "Sparkle", Graphics = "View",
	Units = "Players", Enemies = "Skull", Misc = "Info", Keybinds = "Bookmark",
}

SettingsConfig.Scopes = { Both = "Both", GameOnly = "GameOnly", LobbyOnly = "LobbyOnly" }

-- Drives the settings panel rows. Each entry's Category files it under a tab; order within a tab
-- follows this list. Type/range here is what Sanitize enforces.
-- Scope defaults to "Both" and Kind defaults to "Preference" when omitted (see normalise below).
SettingsConfig.Schema = {
	-- B111: every row carries a one-line `Desc` (shown under the title), Actions an `Icon` (IconCatalog key).
	-- ===== Audio: one slider per SoundGroup created at B32 =====
	{ Key = "MusicVolume", Type = "number", Label = "Music Volume", Desc = "Adjusts all game music volume", Min = 0, Max = 1, Category = "Audio" },
	{ Key = "SoundVolume", Type = "number", Label = "SFX Volume", Desc = "Adjusts all game sound effect volume", Min = 0, Max = 1, Category = "Audio" },
	{ Key = "UIVolume", Type = "number", Label = "UI Volume", Desc = "Adjusts button and menu sounds", Min = 0, Max = 1, Category = "Audio" },

	-- ===== Gameplay =====
	-- Actions persist NOTHING. An Action with no registered handler renders DISABLED rather than
	-- pretending to work -- see ClientSettings.RegisterAction.
	{ Key = "RestartMatch", Kind = "Action", Label = "Restart Game", Desc = "End your current game and restart", Icon = "Hourglass", Category = "Gameplay", Scope = "GameOnly" },
	{ Key = "ReturnToLobby", Kind = "Action", Label = "Back To Lobby", Desc = "Leave your current game and return to lobby", Icon = "Arrow", Category = "Gameplay", Scope = "GameOnly" },
	{ Key = "TeleportToSpawn", Kind = "Action", Label = "Teleport To Spawn", Desc = "Go to your current map's spawn point", Icon = "Players", Category = "Gameplay" },
	{ Key = "AutoSkipWave", Type = "boolean", Label = "Auto Skip Waves", Desc = "Automatically vote to skip waves", Category = "Gameplay", Scope = "GameOnly" },
	{ Key = "AutoVoteStart", Type = "boolean", Label = "Auto Vote Start", Desc = "Automatically vote to start games", Category = "Gameplay", Scope = "GameOnly" },
	{ Key = "ShowMatchEndRewards", Type = "boolean", Label = "Show Match End Rewards", Desc = "Show reward pop-ups after matches", Category = "Gameplay", Scope = "GameOnly" },
	{ Key = "ShowPinnedQuests", Type = "boolean", Label = "Display Pinned Quests", Desc = "Display all pinned quests on screen", Category = "Gameplay" },
	-- B54: sprint is a TOGGLE in both Places; this pins it on.
	{ Key = "AlwaysSprint", Type = "boolean", Label = "Auto Sprint", Desc = "Automatically sprint without holding the sprint key", Category = "Gameplay" },

	-- ===== Graphics =====
	{ Key = "ScreenShake", Type = "boolean", Label = "Show Camera Shake", Desc = "Show camera shake and screen flash effects", Category = "Graphics" },
	{ Key = "LowDetail", Type = "boolean", Label = "Low Detail Mode", Desc = "Greatly reduce game visual details", Category = "Graphics" },
	{ Key = "EnableVFX", Type = "boolean", Label = "Show Unit VFX", Desc = "Show unit attack effects and damage numbers", Category = "Graphics", Scope = "GameOnly" },

	-- ===== Units -- B87 AUTOMATION. The Unit Manager carries its own buttons for these four; the rows
	-- here are THE SAME SAVED KEYS, so the two surfaces can never disagree. =====
	{ Key = "StrictUpgradeOrder", Type = "boolean", Label = "Strict Auto-Upgrade Priority", Desc = "Fully upgrade higher-priority units before lower-priority ones", Category = "Units", Scope = "GameOnly" },
	{ Key = "StrictQueueOrder", Type = "boolean", Label = "Strict Queue Order", Desc = "Buy queued upgrades one unit at a time, in order", Category = "Units", Scope = "GameOnly" },
	{ Key = "AutoUpgradeNewUnits", Type = "boolean", Label = "Auto-Upgrade Placed Units", Desc = "Automatically enable auto-upgrade for placed units", Category = "Units", Scope = "GameOnly" },
	{ Key = "AutoAbilitiesNewUnits", Type = "boolean", Label = "Auto Abilities on Placement", Desc = "Enable auto abilities on placed units", Category = "Units", Scope = "GameOnly" },

	-- ===== Enemies =====
	{ Key = "ShowHealthBar", Type = "boolean", Label = "Display Health Bars", Desc = "Display enemy health bars", Category = "Enemies", Scope = "GameOnly" },
	{ Key = "SimplifyHealthBar", Type = "boolean", Label = "Simple Health Bars", Desc = "No health text or damage trail on enemy bars", Category = "Enemies", Scope = "GameOnly" },

	-- ===== Misc (Lobby animations) =====
	{ Key = "SkipSummonAnim", Type = "boolean", Label = "Fast Summon", Desc = "Skip the summon animation and show results at once", Category = "Misc", Scope = "LobbyOnly" },
	{ Key = "SkipRevealAnim", Type = "boolean", Label = "Skip Reward Animation", Desc = "Show claimed rewards without the reveal animation", Category = "Misc", Scope = "LobbyOnly" },
	{ Key = "SkipTraitRerollAnim", Type = "boolean", Label = "Skip Trait Reroll Animation", Desc = "Skip the trait spin and reveal", Category = "Misc", Scope = "LobbyOnly" },
	-- B112: `Display = "Percent"` makes the slider's box show the VALUE x100 (75..125) instead of the 0..100
	-- ratio; `Step` is the gamepad / arrow-key step in VALUE units.
	{ Key = "UIScale", Type = "number", Label = "UI Scale", Desc = "Adjust the size of the HUD and on-screen panels", Min = 0.75, Max = 1.25, Step = 0.05, Display = "Percent", Category = "Misc" },

	-- ===== Keybinds (B112). Type "key" = a KeybindRowTemplate row (key button + X clear).
	-- `Group` = where the key is LIVE: a rebind clears any other key of the SAME Group (and overlapping Scope)
	-- that held it. Placement keys only work while placing, Selected keys only while a unit is selected,
	-- so E can be both "Place Unit" and "Upgrade Unit" -- exactly as it was hard-coded before. =====
	{ Key = "ResetKeybinds", Kind = "Action", Label = "Reset Keybinds", Desc = "Reset all keybinds to their defaults", Icon = "Hourglass", Category = "Keybinds" },
	{ Key = "Key_Dash", Type = "key", Group = "Global", Label = "Dash", Desc = "Dash forward", Category = "Keybinds" },
	{ Key = "Key_Sprint", Type = "key", Group = "Global", Label = "Sprint", Desc = "Toggle sprinting", Category = "Keybinds" },
	{ Key = "Key_Interact", Type = "key", Group = "Global", Label = "Interact Prompt", Desc = "Use NPCs and interaction prompts", Category = "Keybinds" },
	{ Key = "Key_PlaceUnit", Type = "key", Group = "Placement", Label = "Place Unit", Desc = "Confirm placing the held unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_RotateUnit", Type = "key", Group = "Placement", Label = "Rotate Unit", Desc = "Rotate the unit being placed", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_CancelPlacement", Type = "key", Group = "Placement", Label = "Cancel Unit Placement", Desc = "Stop placing the held unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_UpgradeUnit", Type = "key", Group = "Selected", Label = "Upgrade Unit", Desc = "Upgrade the selected unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_AutoUpgradeUnit", Type = "key", Group = "Selected", Label = "Auto Upgrade Unit", Desc = "Toggle auto upgrade on the selected unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_SellUnit", Type = "key", Group = "Selected", Label = "Sell Unit", Desc = "Sell the selected unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_TargetingUnit", Type = "key", Group = "Selected", Label = "Change Unit Targeting", Desc = "Cycle the selected unit's targeting", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_UseAbility", Type = "key", Group = "Selected", Label = "Use Ability", Desc = "Activate the selected unit's ability", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_AutoAbility", Type = "key", Group = "Selected", Label = "Auto Ability", Desc = "Toggle auto ability on the selected unit", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_UnitManager", Type = "key", Group = "Global", Label = "Toggle Unit Manager", Desc = "Open or close the Unit Manager", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_StageInfo", Type = "key", Group = "Global", Label = "Toggle Stage Info", Desc = "Open or close the Stage Info panel", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_VoteSkip", Type = "key", Group = "Global", Label = "Vote Start / Skip", Desc = "Vote to start the game or skip the wave", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_ToggleAutoSkip", Type = "key", Group = "Global", Label = "Toggle Auto Skip Waves", Desc = "Turn Auto Skip Waves on or off", Category = "Keybinds", Scope = "GameOnly" },
	{ Key = "Key_OpenPlay", Type = "key", Group = "Global", Label = "Open Play Menu", Desc = "Open the Play menu", Category = "Keybinds", Scope = "LobbyOnly" },
	{ Key = "Key_OpenQuests", Type = "key", Group = "Global", Label = "Open Quests Menu", Desc = "Open the Quests menu", Category = "Keybinds" },
	{ Key = "Key_OpenSummon", Type = "key", Group = "Global", Label = "Open Summon Menu", Desc = "Open the Summon menu", Category = "Keybinds", Scope = "LobbyOnly" },
	{ Key = "Key_OpenUnits", Type = "key", Group = "Global", Label = "Open Units Menu", Desc = "Open the Units menu", Category = "Keybinds" },
	{ Key = "Key_OpenInventory", Type = "key", Group = "Global", Label = "Open Inventory", Desc = "Open the Inventory", Category = "Keybinds", Scope = "LobbyOnly" },
}

-- B112: is `name` a KEYBOARD Enum.KeyCode name a player may bind? Gamepad / mouse / touch codes are
-- refused (those inputs are not remappable), and so are keys Roblox itself owns (Escape = menu, Slash =
-- chat, F9 = console...). Used by Sanitize on BOTH sides, so a doctored payload cannot store junk.
local RESERVED_KEYS = { Escape = true, Slash = true, Tab = true, Return = true, Unknown = true, F9 = true, F10 = true, F11 = true, F12 = true }
function SettingsConfig.IsBindableKey(name: any): boolean
	if type(name) ~= "string" or name == "" or RESERVED_KEYS[name] then
		return false
	end
	if name:find("^Button") or name:find("^DPad") or name:find("^Thumbstick") or name:find("^Mouse")
		or name:find("^Touch") or name:find("^Trackpad") then
		return false
	end
	local ok, code = pcall(function() return (Enum.KeyCode :: any)[name] end)
	return ok and code ~= nil
end

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
				-- B111 FIX: the old `(type(value) == "boolean") and value or default` turned a saved FALSE back into
				-- the default whenever the default was true (ShowHealthBar / EnableVFX could never stay off).
				if type(value) == "boolean" then
					clean[key] = value
				else
					clean[key] = default
				end
			elseif field.Type == "key" then
				-- B112: "" (unbound) or a bindable keyboard key name; anything else falls back to the default.
				if value == "" or SettingsConfig.IsBindableKey(value) then
					clean[key] = value
				else
					clean[key] = default
				end
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
