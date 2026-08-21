--!strict
-- ClientSettings.lua (SHARED CANON -- deploy path
-- StarterPlayer.StarterPlayerScripts.Client.Settings.ClientSettings)
--
-- One in-memory home for the local player's settings. Every client system that cares about a
-- setting (VFXController, WavePrepUI, the healthbars, the settings panel) requires THIS module and
-- reads/subscribes here -- so there's a single source of truth on the client, mirroring how the
-- server keeps one authoritative copy.
--
-- Persistence is the server's job: Set() fires SaveSettings; the server sanitizes + stores.
-- On startup we pull the saved copy back with GetSettings so settings survive across sessions.
--
-- *** PROMOTED TO SHARED CANON AT B35. THE PATH DELIBERATELY DID NOT MOVE. ***
-- Five Game scripts require this as `script.Parent.Parent.Settings.ClientSettings`. Keeping the
-- deploy path identical in both Places means promotion cost ZERO consumer edits -- the Lobby simply
-- grew the same Client/Settings folders. Moving it to ReplicatedStorage.Shared would have been
-- tidier and would have meant editing five working files in another owner's Place for no behaviour.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local Signal = require(ReplicatedStorage.Shared.Signal)
local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)

-- Bounded lookups, never bare waits (the B33 lesson: a bare WaitForChild in a module required by
-- screen controllers stops being "settings are missing" and becomes "that screen never boots").
local function remote(name: string): Instance?
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	folder = folder and (folder:FindFirstChild("Settings") or folder:WaitForChild("Settings", 10))
	if folder == nil then
		return nil
	end
	return folder:FindFirstChild(name) or folder:WaitForChild(name, 5)
end

local getSettings = remote("GetSettings")
local saveSettings = remote("SaveSettings")
if getSettings == nil or saveSettings == nil then
	warn("[ClientSettings] Remotes.Settings.{GetSettings,SaveSettings} missing in this Place --"
		.. " settings will work in memory but NOTHING WILL PERSIST.")
end

local ClientSettings = {}

ClientSettings.Changed = Signal.new() -- (settings)

local current = SettingsConfig.Sanitize(nil) -- start from defaults

-- ===== side effects =====
-- Volume drives the SoundGroups authored at B32 (SoundService.Groups.Master > UI/SFX/BGM).
-- *** THIS WAS A REAL BUG UNTIL B35: *** the old code drove a group called `MasterSFX`, which has
-- never existed in either Place, so the volume slider controlled precisely nothing. Groups are
-- looked up by their real path and a missing one is skipped rather than created -- inventing audio
-- routing behind the player's back is worse than a slider that visibly does nothing.
local function setGroupVolume(groupName: string, volume: number)
	local groups = SoundService:FindFirstChild("Groups")
	local master = groups and groups:FindFirstChild("Master")
	local group = master and master:FindFirstChild(groupName)
	if group and group:IsA("SoundGroup") then
		group.Volume = volume
	end
end

local function applySideEffects()
	-- Low detail: kill dynamic shadows, the cheapest big visual win. VFXController also reads
	-- LowDetail to trim damage numbers and cone segments.
	Lighting.GlobalShadows = not current.LowDetail

	setGroupVolume("BGM", current.MusicVolume)
	setGroupVolume("SFX", current.SoundVolume)   -- `SoundVolume` IS the SFX key; see SettingsConfig.
	setGroupVolume("UI", current.UIVolume)

	-- Published as attributes too, so any sound code that is not group-routed can still honour them.
	SoundService:SetAttribute("MusicVolume", current.MusicVolume)
	SoundService:SetAttribute("SFXVolume", current.SoundVolume)
	SoundService:SetAttribute("UIVolume", current.UIVolume)
end

function ClientSettings.GetAll(): { [string]: any }
	return current
end

function ClientSettings.Get(key: string): any
	return current[key]
end

-- Apply an incoming settings table WITHOUT saving (used for the server's loaded copy).
function ClientSettings.ApplyLocal(newSettings: any)
	current = SettingsConfig.Sanitize(newSettings)
	applySideEffects()
	ClientSettings.Changed:Fire(current)
end

-- Change one setting from the UI: update locally, apply, and persist to the server.
function ClientSettings.Set(key: string, value: any)
	current[key] = value
	current = SettingsConfig.Sanitize(current)
	applySideEffects()
	if saveSettings then
		(saveSettings :: RemoteEvent):FireServer(current)
	end
	ClientSettings.Changed:Fire(current)
end

-- ===== actions =====
-- An Action is a button, not a preference: it fires and persists nothing. WHAT it does is
-- Place-specific (Restart Match means nothing in the Lobby), so each Place registers its own
-- handlers and the shared UI only knows how to draw and invoke them.
-- An action with NO registered handler renders DISABLED -- a button that silently does nothing is
-- worse than one that visibly cannot be pressed.
local actions: { [string]: () -> () } = {}

function ClientSettings.RegisterAction(id: string, handler: () -> ())
	if actions[id] ~= nil then
		warn("[ClientSettings] action '" .. id .. "' registered twice -- the second wins.")
	end
	actions[id] = handler
end

function ClientSettings.HasAction(id: string): boolean
	return actions[id] ~= nil
end

function ClientSettings.RunAction(id: string): boolean
	local handler = actions[id]
	if handler == nil then
		warn("[ClientSettings] action '" .. id .. "' has no handler in this Place -- ignored.")
		return false
	end
	-- Spawned: an action that yields (a teleport, a confirm dialog) must not block the click that
	-- started it, and an action that errors must not take the settings panel down with it.
	task.spawn(function()
		local ok, err = pcall(handler)
		if not ok then
			warn("[ClientSettings] action '" .. id .. "' errored: " .. tostring(err))
		end
	end)
	return true
end

local loaded = false
function ClientSettings.Load()
	if loaded then
		return
	end
	loaded = true
	if getSettings == nil then
		applySideEffects()
		return
	end
	local ok, saved = pcall(function()
		return (getSettings :: RemoteFunction):InvokeServer()
	end)
	if ok and saved then
		ClientSettings.ApplyLocal(saved)
	else
		applySideEffects()
	end
end

-- Auto-load once, whichever system requires us first.
task.spawn(ClientSettings.Load)

return ClientSettings
