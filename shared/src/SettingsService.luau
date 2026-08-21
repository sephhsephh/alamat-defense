--!strict
-- SettingsService.lua (SHARED CANON -- deploy path
-- ServerScriptService.Server.Settings.SettingsService)
--
-- Persists per-player client settings inside the ProfileStore profile (Data.Settings -- schema
-- contract: Shared.ProfileTemplate). The client owns the UI; the server owns the truth and the write.
--
-- Trust boundary: every incoming payload runs through SettingsConfig.Sanitize before it is stored,
-- so a malformed/hostile SaveSettings call can never poison the profile. Sanitize also drops Action
-- entries, so a button press can never be persisted as if it were a preference.
--
-- Persistence rides ProfileStore's session autosave: writing to Data.Settings IS the save.
--
-- *** PROMOTED TO SHARED CANON AT B35 SO BOTH PLACES WRITE SETTINGS THE SAME WAY. ***
-- ONE profile serves both Places, so two independently-written services would eventually sanitize
-- differently and each quietly clobber the other's keys. The only change needed to promote it was
-- the PlayerDataService require: it was `script.Parent.Parent.Data.PlayerDataService`, a RELATIVE
-- path that happens to resolve in the Game's folder layout. It is now absolute, and it resolves in
-- both Places because PlayerDataService is itself shared canon at a fixed path.
--
-- Save-schema note: NO version bump was needed. `Data.Settings` has been a free-form
-- `{ [string]: any }` since v1, so new keys are additive by construction.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)
local PlayerDataService = require(ServerScriptService.Server.Data.PlayerDataService)

local SettingsService = {}

-- Writes that arrive before the profile finishes loading; merged in on ProfileLoaded.
local pendingWrites: { [number]: { [string]: any } } = {}

function SettingsService.Get(userId: number): { [string]: any }
	local data = PlayerDataService.GetData(userId)
	if data then
		return data.Settings
	end
	return pendingWrites[userId] or SettingsConfig.Sanitize(nil)
end

function SettingsService.Set(userId: number, rawSettings: any)
	local clean = SettingsConfig.Sanitize(rawSettings)
	local data = PlayerDataService.GetData(userId)
	if data then
		data.Settings = clean -- autosaved by ProfileStore
	else
		pendingWrites[userId] = clean
	end
end

local initialized = false
function SettingsService.Init()
	if initialized then
		return
	end
	initialized = true

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local folder = remotes and remotes:FindFirstChild("Settings")
	local getSettings = folder and folder:FindFirstChild("GetSettings")
	local saveSettings = folder and folder:FindFirstChild("SaveSettings")
	if getSettings == nil or saveSettings == nil then
		-- Loud and specific: without these the client silently falls back to defaults every join,
		-- which reads exactly like "settings do not save" with nothing in the log to explain it.
		warn("[SettingsService] ReplicatedStorage.Remotes.Settings.{GetSettings,SaveSettings} are"
			.. " MISSING in this Place -- settings cannot be loaded or saved. Nothing else is affected.")
		return
	end

	PlayerDataService.ProfileLoaded:Connect(function(player: Player, profile: any)
		local userId = player.UserId
		-- Sanitize even our own stored data -- a schema change shouldn't hand back stale shapes.
		-- A write that raced the load wins over the saved copy.
		profile.Data.Settings = SettingsConfig.Sanitize(pendingWrites[userId] or profile.Data.Settings)
		pendingWrites[userId] = nil
	end)

	Players.PlayerRemoving:Connect(function(player)
		pendingWrites[player.UserId] = nil
	end)

	-- Bound to typed locals FIRST. A statement starting with `(` after a preceding `end)` parses as
	-- a call to whatever came before it -- Luau flags it as ambiguous syntax and refuses to load the
	-- module, which takes the whole service down. Naming them sidesteps the ambiguity entirely.
	local getFn = getSettings :: RemoteFunction
	local saveEvent = saveSettings :: RemoteEvent

	-- Client asks for its settings on join; hand back the sanitized, persisted copy.
	-- *** IT WAITS FOR THE PROFILE, AND THAT IS NOT OPTIONAL. *** The client fetches once at boot
	-- and caches the answer for the whole session. Without this wait that fetch regularly lands
	-- BEFORE ProfileStore finishes loading, Get() falls through to Sanitize(nil) = DEFAULTS, and the
	-- player spends the session with their real settings on the server and default ones on screen --
	-- experienced as "my settings reset every time I join", with nothing in the log to explain it.
	-- Found at B35 in the Lobby: the server held MusicVolume 0.25 while the SoundGroup sat at 0.5.
	getFn.OnServerInvoke = function(player)
		PlayerDataService.WaitForData(player.UserId, 20)
		return SettingsService.Get(player.UserId)
	end

	saveEvent.OnServerEvent:Connect(function(player, rawSettings)
		SettingsService.Set(player.UserId, rawSettings)
	end)

	print(string.format("[SettingsService] Ready (profile-backed, %s place, %d preference(s) in scope).",
		SettingsConfig.Place(), #SettingsConfig.EntriesFor("All")))
end

return SettingsService
