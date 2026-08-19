--!strict
-- UIKitSound.lua (SHARED CANON -- deploy path ReplicatedStorage.Shared.UIKit.Sound)
-- ONE home for audio: UI clicks, gameplay SFX, and music. Added B32 2026-08-19.
--
-- ===== ASSIGNING A SOUND IS PASTING AN ID IN STUDIO. THERE IS NO CONFIG FILE. =====
-- Every sound is a REAL `Sound` instance under `SoundService`, in a folder named after its
-- category, and this module resolves it BY NAME:
--
--   SoundService
--     Groups (Folder)
--       Master (SoundGroup)
--         UI (SoundGroup)  ·  SFX (SoundGroup)  ·  BGM (SoundGroup)
--     UI  (Folder)   Hover · Click · Confirm · Cancel · Sell · Error · Open · Close
--     SFX (Folder)   gameplay one-shots
--     BGM (Folder)   Lobby · Default · <actId>   (e.g. Stage1_Act1)
--
-- To add or change a sound: drop a `Sound` in the right folder, name it, paste a `SoundId`. No code
-- change, in either Place. **To give a stage its own music, name a Sound EXACTLY the act id** --
-- `playBGM(actId)` falls back to `Default` when there is no match, so an unnamed stage is silent
-- rather than broken.
--
-- WHY INSTANCES AND NOT A CONFIG TABLE: a `Sound` carries Volume, Looped, TimePosition,
-- PlaybackSpeed and PlayOnRemove as AUTHORED properties a designer can hear while tuning. A config
-- table would push every one of those through code and separate the ids from the volumes.
--
-- WHY SoundGroups: one Volume per category is exactly what a settings screen needs (there is a
-- standing PENDING for a unified settings system), and it is the only way to duck music under SFX
-- later without touching every Sound.
--
-- ===== THIS IS A CLIENT MODULE =====
-- Playing a `Sound` on the server plays it for nobody in particular; UI feedback and music are
-- per-player. Every caller is a LocalScript. The server must not require this.
--
-- EVERY LOOKUP DEGRADES QUIETLY. A missing name warns ONCE per name and does nothing. An EMPTY
-- `SoundId` is "not assigned yet" -- the normal state of a fresh project -- so it is reported ONCE
-- at boot as a `[DIAG]` list instead of warning on every single click.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sound = {}

-- Canonical UI sound names, so a caller cannot typo one into silence.
Sound.Names = {
	Hover = "Hover",
	Click = "Click",
	Confirm = "Confirm",
	Cancel = "Cancel",
	Sell = "Sell",
	Error = "Error",
	Open = "Open",
	Close = "Close",
}

Sound.Categories = { "UI", "SFX", "BGM" }

Sound.Tuning = {
	-- Music crossfade. Out is faster than in: silence between two tracks reads as a bug, overlap
	-- reads as a transition.
	BgmFadeOut = 0.8,
	BgmFadeIn = 1.6,
}

-- The authored Volume is canon and is captured ONCE into an attribute -- same reasoning as
-- `Motion`'s `UIKitRestPosition` and `UIKitBaseRotation`: it stays visible in Studio, survives a
-- reload, and is never re-derived from an instance that may already be mid-fade.
local BASE_VOLUME_ATTR = "UIKitBaseVolume"

local warned: { [string]: boolean } = {}
local function warnOnce(key: string, message: string)
	if warned[key] then return end
	warned[key] = true
	warn("[UIKitSound] " .. message)
end

local function folder(category: string): Instance?
	local f = SoundService:FindFirstChild(category)
	if f == nil then
		warnOnce("folder:" .. category, "no SoundService." .. category ..
			" folder -- create it in Studio and drop Sound instances in it. Nothing is playing from that category.")
		return nil
	end
	return f
end

-- Resolve a Sound by name. `category` narrows the search; omitted, UI is tried then SFX (music is
-- never a one-shot, so BGM is deliberately excluded from the implicit search).
local function findSound(name: string, category: string?): Sound?
	local order = if category then { category } else { "UI", "SFX" }
	for _, cat in ipairs(order) do
		local f = SoundService:FindFirstChild(cat)
		local s = f and f:FindFirstChild(name)
		if s and s:IsA("Sound") then return s end
	end
	warnOnce("sound:" .. tostring(category) .. ":" .. name,
		"no Sound named '" .. name .. "' in " .. table.concat(order, "/") ..
		" -- add one in Studio (SoundService." .. order[1] .. "." .. name .. ").")
	return nil
end

local function baseVolume(s: Sound): number
	local v = s:GetAttribute(BASE_VOLUME_ATTR)
	if type(v) ~= "number" then
		v = s.Volume
		s:SetAttribute(BASE_VOLUME_ATTR, v)
	end
	return v :: number
end

-- ===== one-shots =====
-- Restarting rather than cloning is deliberate: a hover sound that overlaps itself on a fast sweep
-- across six buttons turns into a smear, and B29a already established that a fast sweep across a
-- row is a real thing players do. Restart also creates no instances to leak.
function Sound.play(name: string, category: string?): Sound?
	local s = findSound(name, category)
	if s == nil then return nil end
	if s.SoundId == "" then return nil end -- not assigned yet; silence is correct, not an error
	s.TimePosition = 0
	s:Play()
	return s
end

-- ===== music =====
local currentBgm: Sound? = nil
local currentBgmName: string? = nil
local fadeTweens: { [Sound]: Tween } = {}

local function fade(s: Sound, target: number, time: number, stopAfter: boolean?)
	local prev = fadeTweens[s]
	if prev then prev:Cancel() end
	local tween = TweenService:Create(s, TweenInfo.new(time, Enum.EasingStyle.Linear), { Volume = target })
	fadeTweens[s] = tween
	if stopAfter then
		tween.Completed:Connect(function(state: Enum.PlaybackState)
			if state ~= Enum.PlaybackState.Completed then return end
			if fadeTweens[s] ~= tween then return end
			s:Stop()
			s.Volume = baseVolume(s) -- leave the AUTHORED volume on the instance, not a faded 0
			fadeTweens[s] = nil
		end)
	end
	tween:Play()
end

-- Crossfade to a BGM track by name, falling back to `Default`. Re-requesting the track that is
-- already playing is a NO-OP, so a screen that calls this on every open cannot restart the music.
function Sound.playBGM(name: string, opts: { [string]: any }?): boolean
	opts = opts or {}
	if currentBgmName == name and currentBgm ~= nil and currentBgm.IsPlaying and opts.restart ~= true then
		return true
	end
	local f = folder("BGM")
	if f == nil then return false end
	local track = f:FindFirstChild(name)
	if not (track and track:IsA("Sound")) then
		local fallback = f:FindFirstChild("Default")
		if fallback and fallback:IsA("Sound") then
			track = fallback
		else
			warnOnce("bgm:" .. name, "no BGM named '" .. name ..
				"' and no SoundService.BGM.Default -- add one in Studio. Music is off.")
			return false
		end
	end
	local s = track :: Sound
	if s.SoundId == "" then return false end -- unassigned; stay silent rather than fake it

	if currentBgm ~= nil and currentBgm ~= s then
		fade(currentBgm, 0, tonumber(opts.fadeOut) or Sound.Tuning.BgmFadeOut, true)
	end
	-- Looped is an AUTHORED property, not forced here: a designer may deliberately want a one-shot
	-- sting as a stage's "music". Whatever they set in Studio is what plays.
	local target = baseVolume(s)
	s.Volume = 0
	s:Play()
	fade(s, target, tonumber(opts.fadeIn) or Sound.Tuning.BgmFadeIn)
	currentBgm, currentBgmName = s, name
	return true
end

function Sound.stopBGM(fadeTime: number?)
	if currentBgm == nil then return end
	fade(currentBgm, 0, fadeTime or Sound.Tuning.BgmFadeOut, true)
	currentBgm, currentBgmName = nil, nil
end

function Sound.currentBGM(): string?
	return currentBgmName
end

-- ===== category volume (for the future settings screen) =====
function Sound.setCategoryVolume(category: string, volume: number)
	local groups = SoundService:FindFirstChild("Groups")
	local g = groups and groups:FindFirstChild(category, true)
	if g and g:IsA("SoundGroup") then
		g.Volume = math.clamp(volume, 0, 1)
	else
		warnOnce("group:" .. category, "no SoundGroup '" .. category .. "' under SoundService.Groups.")
	end
end

-- ===== what is actually assigned =====
-- Printed once at boot by whoever owns audio in this Place. An empty SoundId is not a bug, it is
-- work outstanding -- so this reports it as a list instead of pretending everything is wired.
function Sound.report(): string
	local lines = {}
	local unassigned = 0
	local total = 0
	for _, cat in ipairs(Sound.Categories) do
		local f = SoundService:FindFirstChild(cat)
		if f == nil then
			table.insert(lines, cat .. ": FOLDER MISSING")
		else
			local names, blanks = {}, {}
			for _, c in ipairs(f:GetChildren()) do
				if c:IsA("Sound") then
					total += 1
					table.insert(names, c.Name)
					if c.SoundId == "" then
						unassigned += 1
						table.insert(blanks, c.Name)
					end
				end
			end
			table.sort(names)
			table.sort(blanks)
			table.insert(lines, string.format("%s: %d sound(s) [%s]%s", cat, #names,
				table.concat(names, ", "),
				if #blanks > 0 then "  UNASSIGNED: " .. table.concat(blanks, ", ") else ""))
		end
	end
	return string.format("%d sound(s), %d still unassigned\n  %s", total, unassigned,
		table.concat(lines, "\n  "))
end

return Sound
