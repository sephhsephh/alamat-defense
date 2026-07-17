--!strict
-- PlayerDataService.lua (Server.Data)
-- SOLE owner of ProfileStore sessions. Everything that reads or writes persistent player
-- state goes through the profile this service loads; no other module touches DataStores.
--
-- Lifecycle: PlayerAdded -> StartSessionAsync (session-locked) -> AddUserId + Reconcile +
-- Migrate -> ProfileLoaded fires. PlayerRemoving -> EndSession -> autosaved by ProfileStore.
-- If another server still holds the session (teleport race), ProfileStore negotiates the
-- handoff; a nil profile means it could not, and we kick rather than run unsaved.
--
-- Studio note: with DataStore API access off, ProfileStore automatically uses an internal
-- mock store -- instant loads, nothing persists. Check the [DATA] boot line for the state.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Signal)
local ProfileTemplate = require(ReplicatedStorage.Shared.ProfileTemplate)
local ProfileStore = require(script.Parent.ProfileStore)

local PlayerDataService = {}

PlayerDataService.ProfileLoaded = Signal.new()   -- (player, profile)
PlayerDataService.ProfileReleased = Signal.new() -- (player)

local STORE_NAME = ProfileTemplate.GetStoreName() -- "PlayerData" live, "PlayerData_Dev" in Studio
local PlayerStore = ProfileStore.New(STORE_NAME, ProfileTemplate.Template)
local profiles: { [number]: any } = {} -- userId -> Profile

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync("u_" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Session could not be acquired (another server refused to release it, or the
		-- player left mid-load and the request was cancelled).
		if player.Parent == Players then
			player:Kick("Your data is still saving from another session. Please rejoin in a moment.")
		end
		return
	end

	profile:AddUserId(player.UserId) -- GDPR association
	profile:Reconcile()              -- fill keys added to the template since this profile was made
	local steps = ProfileTemplate.Migrate(profile.Data)
	if steps > 0 then
		print(string.format("[DATA] Migrated %s's profile forward %d step(s) to v%d",
			player.Name, steps, profile.Data.SchemaVersion))
	end

	profile.OnSessionEnd:Connect(function()
		profiles[player.UserId] = nil
		PlayerDataService.ProfileReleased:Fire(player)
		if player.Parent == Players then
			player:Kick("Data session ended. Please rejoin.")
		end
	end)

	if player.Parent == Players then
		profiles[player.UserId] = profile
		print(string.format("[DATA] [CONTRACT] Profile v%d loaded for %s (store=%s, DataStoreState=%s)",
			profile.Data.SchemaVersion, player.Name, STORE_NAME, ProfileStore.DataStoreState))
		PlayerDataService.ProfileLoaded:Fire(player, profile)
	else
		profile:EndSession() -- player left while the session was loading
	end
end

function PlayerDataService.GetProfile(userId: number): any?
	return profiles[userId]
end

-- The live, autosaved data table (ProfileTemplate.ProfileData shape), or nil if not loaded.
function PlayerDataService.GetData(userId: number): any?
	local profile = profiles[userId]
	return profile and profile.Data
end

-- Yields until the player's profile is loaded (or timeout). For code paths that can run
-- before the join flow finishes.
function PlayerDataService.WaitForData(userId: number, timeout: number?): any?
	local deadline = os.clock() + (timeout or 10)
	repeat
		local profile = profiles[userId]
		if profile then
			return profile.Data
		end
		task.wait(0.1)
	until os.clock() >= deadline
	return nil
end

local initialized = false
function PlayerDataService.Init()
	if initialized then
		return
	end
	initialized = true

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player.UserId]
		if profile then
			profile:EndSession()
		end
	end)

	print("[DATA] PlayerDataService ready (schema v" .. ProfileTemplate.SCHEMA_VERSION .. ").")
end

return PlayerDataService
