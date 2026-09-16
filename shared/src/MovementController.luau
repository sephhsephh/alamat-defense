--!strict
script:SetAttribute("BootComplete", false)
-- MovementController (SHARED CANON -- deploy path
-- StarterPlayer.StarterPlayerScripts.Client.MovementController)
-- Sprint + dash + double jump, ALL in BOTH Places. Added B54 (sprint + Lobby dash); B66 extended the
-- dash to the Game and added the double jump, both at the user's request.
--
-- ===== ONE BINDING SERVES THREE PLATFORMS =====
-- Everything goes through ContextActionService -- the FIRST use of CAS in this project. BindAction
-- takes the keyboard key AND the gamepad button in the same call, and `createTouchButton = true`
-- makes the mobile button for free. That is why there is no `if UserInputService.TouchEnabled` branch
-- anywhere below: PC, console and mobile are one code path, and a fourth platform costs one KeyCode.
--   Sprint      : LeftShift / RightShift / gamepad ButtonL3 (thumbstick click -- console convention)
--   Dash        : Q / gamepad ButtonR1                      (BOTH Places since B66)
--   Double jump : the ORDINARY jump input, second press while airborne (BOTH Places, B66)
--
-- ⚠ B54's header used to say "Q is safe: the GAME binds Q to a tower Ability, but the dash is never
-- bound in the Game, so the two never coexist." THAT IS NO LONGER TRUE. B66 gave the Game a dash on
-- Q, and a ContextActionService bind SINKS the key (it also marks the input gameProcessed, which the
-- Game's UserInputService handlers all check), so Q would have silently killed the tower Ability AND
-- the end screen's Return to Lobby. At the user's call the GAME moved Ability Q -> V and Return to
-- Lobby Q -> L. Q is now dash-only in both Places. Before binding ANY key here, grep the OTHER
-- Place for it -- this is the second time a shared binding nearly ate a Place-local one.
--
-- The double jump deliberately adds NO binding: it listens to UserInputService.JumpRequest, which
-- already fires for Space, gamepad A and the mobile jump button, so it inherits all three platforms
-- for free -- the same one-code-path principle the CAS bindings follow.
--
-- ===== SPRINT IS A TOGGLE, NOT A HOLD (user, B54) =====
-- Tap to flip; it stays flipped, and survives respawn. The `AlwaysSprint` setting PINS it on -- while
-- pinned the toggle is inert rather than letting a player fight their own setting, and the speed is
-- re-applied whenever settings change so flipping the setting takes effect immediately.
--
-- ===== WHY THE CLIENT OWNS THIS =====
-- WalkSpeed is a client-authoritative Humanoid property in Roblox: a server that "validated" it would
-- be validating a number the client can set anyway. The Lobby is a social space with nothing to win,
-- and the Game gets sprint only -- no dash -- so nothing here can cross a placement zone it shouldn't.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MovementConfig = require(ReplicatedStorage.Configs.Global.MovementConfig)
local SettingsConfig = require(ReplicatedStorage.Configs.Global.SettingsConfig)
-- Sibling module: `optionalSibling` rules (B32) -- never a bare WaitForChild on a sibling, which
-- would hang this script forever if the folder were ever renamed.
local settingsFolder = script.Parent:FindFirstChild("Settings") or script.Parent:WaitForChild("Settings", 10)
local ClientSettings = settingsFolder and require(settingsFolder:WaitForChild("ClientSettings", 10)) or nil

local player = Players.LocalPlayer
local PLACE = SettingsConfig.Place()
local DASH_ENABLED = MovementConfig.DashAllowed(PLACE)
local DOUBLE_JUMP_ENABLED = MovementConfig.DoubleJumpAllowed(PLACE)

local ACTION_SPRINT = "AD_Sprint"
local ACTION_DASH = "AD_Dash"

local sprinting = false            -- the toggle state; survives respawn on purpose
local dashing = false
local lastDashAt = -math.huge
local humanoid: Humanoid? = nil
local rootPart: BasePart? = nil

-- Double-jump state. Reset per character AND on every landing, never trusted across a respawn.
local doubleJumpUsed = false
local lastJumpAt = -math.huge
local humanoidConns: { RBXScriptConnection } = {}

local function alwaysSprint(): boolean
	return ClientSettings ~= nil and ClientSettings.Get("AlwaysSprint") == true
end

-- The ONE place WalkSpeed is written. It always writes an ABSOLUTE value from MovementConfig rather
-- than adding/subtracting a delta, so nothing else that touches WalkSpeed can strand the player at
-- sprint speed (the classic sprint bug).
local function applySpeed()
	local h = humanoid
	if h == nil or h.Health <= 0 then
		return
	end
	local fast = sprinting or alwaysSprint()
	h.WalkSpeed = fast and MovementConfig.SprintSpeed or MovementConfig.WalkSpeed
end

-- Tint the mobile button so the toggle has a visible state. GetButton returns nil on PC/console,
-- which is why every use is guarded -- this is cosmetic, never load-bearing.
local function paintSprintButton()
	local btn = ContextActionService:GetButton(ACTION_SPRINT)
	if btn == nil then
		return
	end
	local on = sprinting or alwaysSprint()
	btn.BackgroundTransparency = on and 0.15 or 0.5
	btn.BackgroundColor3 = on and Color3.fromRGB(90, 190, 120) or Color3.fromRGB(0, 0, 0)
end

-- Typing in a chat/text box must not sprint or dash the character.
local function typing(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

local function setSprint(on: boolean)
	sprinting = on
	applySpeed()
	paintSprintButton()
end

local function onSprintAction(_action: string, state: Enum.UserInputState): Enum.ContextActionResult
	if state ~= Enum.UserInputState.Begin or typing() then
		return Enum.ContextActionResult.Pass
	end
	if alwaysSprint() then
		-- Pinned on by the setting: the toggle would be a lie, so it does nothing but re-assert.
		applySpeed()
		paintSprintButton()
		return Enum.ContextActionResult.Sink
	end
	setSprint(not sprinting)
	return Enum.ContextActionResult.Sink
end

-- Horizontal burst in the direction the player is MOVING, falling back to the way they FACE when
-- standing still (a dash that does nothing because you were idle feels broken).
local function dashDirection(): Vector3?
	local h, root = humanoid, rootPart
	if h == nil or root == nil then
		return nil
	end
	local dir = h.MoveDirection
	if dir.Magnitude < 0.05 then
		dir = root.CFrame.LookVector
	end
	if MovementConfig.DashHorizontalOnly then
		dir = Vector3.new(dir.X, 0, dir.Z)
	end
	if dir.Magnitude < 0.05 then
		return nil
	end
	return dir.Unit
end

-- The burst re-asserts the horizontal velocity every Heartbeat for DashDuration and leaves Y alone,
-- so gravity still applies and the dash cannot launch the player off the lobby floor. Deliberately
-- no BodyVelocity/LinearVelocity instance: nothing to leak if the character dies mid-dash.
local function doDash()
	local root = rootPart
	local dir = dashDirection()
	if root == nil or dir == nil then
		return
	end
	dashing = true
	lastDashAt = os.clock()
	local speed = MovementConfig.DashSpeed
	local until_ = os.clock() + MovementConfig.DashDuration
	local conn: RBXScriptConnection? = nil
	conn = RunService.Heartbeat:Connect(function()
		local r = rootPart
		if r == nil or r.Parent == nil or os.clock() >= until_ then
			if conn then conn:Disconnect() end
			dashing = false
			return
		end
		local v = r.AssemblyLinearVelocity
		r.AssemblyLinearVelocity = Vector3.new(dir.X * speed, v.Y, dir.Z * speed)
	end)
end

local function onDashAction(_action: string, state: Enum.UserInputState): Enum.ContextActionResult
	if not DASH_ENABLED then
		-- The Place gate lives HERE as well as at the BindAction below, so the only way to dash in a
		-- Place that forbids it is to change MovementConfig.DashPlaces. Reaching this line means
		-- something called the handler directly (the Studio harness, or a future mis-binding).
		return Enum.ContextActionResult.Pass
	end
	if state ~= Enum.UserInputState.Begin or typing() then
		return Enum.ContextActionResult.Pass
	end
	local h = humanoid
	if h == nil or h.Health <= 0 or dashing then
		return Enum.ContextActionResult.Sink
	end
	if os.clock() - lastDashAt < MovementConfig.DashCooldown then
		return Enum.ContextActionResult.Sink
	end
	doDash()
	return Enum.ContextActionResult.Sink
end

-- ===== double jump =====
-- One extra jump per airborne stretch. Roblox characters use EITHER JumpPower or JumpHeight, so the
-- impulse is derived from whichever this Humanoid actually uses rather than hardcoded -- a fixed
-- velocity would feel wrong the moment either property is retuned.
local function jumpVelocity(h: Humanoid): number
	if h.UseJumpPower then
		return h.JumpPower
	end
	-- v = sqrt(2 * g * h) -- the launch speed that reaches JumpHeight under the current gravity.
	return math.sqrt(2 * workspace.Gravity * math.max(h.JumpHeight, 0))
end

local function tryDoubleJump()
	if not DOUBLE_JUMP_ENABLED or typing() then
		return
	end
	local h, root = humanoid, rootPart
	if h == nil or root == nil or h.Health <= 0 or doubleJumpUsed then
		return
	end
	-- Only while genuinely airborne. Freefall also covers walking off a ledge without jumping, which
	-- is the forgiving behaviour players expect from an air jump.
	if h:GetState() ~= Enum.HumanoidStateType.Freefall then
		return
	end
	-- The jump key REPEATS while held and JumpRequest fires on every repeat, so without this gap one
	-- press would spend the first jump and the double instantly and read as a single tall jump.
	if os.clock() - lastJumpAt < MovementConfig.DoubleJumpRearmSeconds then
		return
	end
	doubleJumpUsed = true
	local v = root.AssemblyLinearVelocity
	-- REPLACE the Y component rather than adding to it: adding to a fast fall gives a limp jump and
	-- adding to a rising one gives a rocket. A flat set makes the second jump feel identical however
	-- it was entered.
	root.AssemblyLinearVelocity = Vector3.new(v.X, jumpVelocity(h) * MovementConfig.DoubleJumpPowerScale, v.Z)
end

-- ===== character lifecycle =====
local function onCharacter(character: Model)
	-- Drop the previous character's connections: these are per-Humanoid and the old one is gone.
	for _, c in ipairs(humanoidConns) do
		c:Disconnect()
	end
	table.clear(humanoidConns)

	humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	rootPart = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	dashing = false
	doubleJumpUsed = false
	lastJumpAt = -math.huge

	local h = humanoid
	if h then
		table.insert(humanoidConns, h.Jumping:Connect(function(active: boolean)
			if active then
				lastJumpAt = os.clock()
			end
		end))
		table.insert(humanoidConns, h.StateChanged:Connect(function(_old, new)
			-- Re-arm the moment the player is supported again. Seated/Climbing count: leaving either
			-- is a fresh airborne stretch, and not re-arming there strands the double jump.
			if new == Enum.HumanoidStateType.Landed
				or new == Enum.HumanoidStateType.Running
				or new == Enum.HumanoidStateType.RunningNoPhysics
				or new == Enum.HumanoidStateType.Seated
				or new == Enum.HumanoidStateType.Climbing
			then
				doubleJumpUsed = false
			end
		end))
	end

	applySpeed() -- re-assert the toggle the player already chose
	paintSprintButton()
end

if player.Character then
	task.spawn(onCharacter, player.Character)
end
player.CharacterAdded:Connect(onCharacter)

-- The double jump rides the ORDINARY jump input -- no binding of its own, so Space, gamepad A and
-- the mobile jump button all work with no per-platform branch.
if DOUBLE_JUMP_ENABLED then
	UserInputService.JumpRequest:Connect(tryDoubleJump)
end

-- A settings change (AlwaysSprint flipped in the panel) takes effect immediately.
if ClientSettings then
	ClientSettings.Changed:Connect(function()
		applySpeed()
		paintSprintButton()
	end)
end

-- ===== bindings =====
ContextActionService:BindAction(ACTION_SPRINT, onSprintAction, true,
	Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle(ACTION_SPRINT, "Sprint")
ContextActionService:SetPosition(ACTION_SPRINT, UDim2.new(1, -140, 1, -190))

if DASH_ENABLED then
	ContextActionService:BindAction(ACTION_DASH, onDashAction, true,
		Enum.KeyCode.Q, Enum.KeyCode.ButtonR1)
	ContextActionService:SetTitle(ACTION_DASH, "Dash")
	ContextActionService:SetPosition(ACTION_DASH, UDim2.new(1, -140, 1, -290))
end

paintSprintButton()

-- ===== Studio harness (leave OFF) =====
-- Tooling cannot synthesise a key press (VirtualInputManager is not available to it), so each of
-- these runs the SAME function a real key / gamepad button / touch button runs -- the DevStart /
-- DevOpen precedent every screen controller already uses. Never a shipping path.
script:SetAttribute("DevSprintToggle", false)
script:SetAttribute("DevDash", false)
script:SetAttribute("DevDoubleJump", false)
script:GetAttributeChangedSignal("DevDoubleJump"):Connect(function()
	if script:GetAttribute("DevDoubleJump") ~= true then return end
	script:SetAttribute("DevDoubleJump", false)
	-- Same function a real JumpRequest runs. Note it still requires the character to BE airborne and
	-- past the re-arm window, so firing this on the ground correctly does nothing.
	tryDoubleJump()
end)
script:GetAttributeChangedSignal("DevSprintToggle"):Connect(function()
	if script:GetAttribute("DevSprintToggle") ~= true then return end
	script:SetAttribute("DevSprintToggle", false)
	onSprintAction(ACTION_SPRINT, Enum.UserInputState.Begin)
end)
script:GetAttributeChangedSignal("DevDash"):Connect(function()
	if script:GetAttribute("DevDash") ~= true then return end
	script:SetAttribute("DevDash", false)
	onDashAction(ACTION_DASH, Enum.UserInputState.Begin)
end)

print(string.format("[DIAG] MovementController ready (%s): sprint TOGGLE on LeftShift/ButtonL3 (walk %d -> sprint %d,"
	.. " AlwaysSprint honoured); dash %s; double jump %s. Mobile buttons via ContextActionService.",
	PLACE, MovementConfig.WalkSpeed, MovementConfig.SprintSpeed,
	DASH_ENABLED and string.format("on Q/ButtonR1 (%d studs/s for %.2fs, %.1fs cooldown)",
		MovementConfig.DashSpeed, MovementConfig.DashDuration, MovementConfig.DashCooldown)
		or "DISABLED in this Place",
	DOUBLE_JUMP_ENABLED and string.format("ON (x%.2f jump strength, %.2fs re-arm, ordinary jump input)",
		MovementConfig.DoubleJumpPowerScale, MovementConfig.DoubleJumpRearmSeconds)
		or "DISABLED in this Place"))

-- ===== B34 BOOT MARKER =====
-- Read by StarterPlayerScripts.ScreenBootWatchdog, which reported this script as NOT INSTRUMENTED on
-- its first run. Reaching this line means top-level boot finished; not reaching it means it is stuck
-- above, almost always on a bare WaitForChild that never times out.
script:SetAttribute("BootComplete", true)
