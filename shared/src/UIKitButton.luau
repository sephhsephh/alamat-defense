--!strict
-- UIKit.Button - reusable button behaviour controller (AD-UI kit)
-- ONE controller for every button. No per-button scripts. The DESIGN lives on the
-- template instance (edit it in Studio); this module only reads config + animates.
--
-- Expected instance shape (every part is OPTIONAL - missing parts degrade gracefully,
-- the button still works, it just skips that one animation):
--   Button (GuiButton: ImageButton or TextButton)
--   |-- Frame          content holder that scales on hover   [optional; falls back to the Button]
--   |   |-- Text (TextLabel)   grows with the frame scale
--   |   `-- Icon (ImageLabel)  rotates on hover
--   |-- UIStroke             thickens on hover (the "glow")
--   |   `-- UIGradient       scrolled/animated if present
--   `-- UIGradient           body gradient (animated if present)
--
-- Per-button tuning via ATTRIBUTES on the Button instance (all optional; defaults shown).
-- Set these in Studio's Properties > Attributes to customise each button with no code:
--   HoverScale        number  1.06   frame scale on hover
--   HoverStrokeMult   number  1.6    stroke thickness multiplier on hover
--   HoverIconRotation number  45     icon rotation (degrees) on hover
--   PressScale        number  0.94   frame scale while pressed
--   TweenTime         number  0.15   hover/press tween seconds
--   GradientAnimate   bool    true   scroll the UIGradient offset in a seamless loop
--   GradientSpeed     number  3      seconds per gradient loop
--   UseAutoButtonColor bool   false  Roblox built-in image darken (off by default)
--
-- Usage:
--   local Button = require(ReplicatedStorage.Shared.UIKit.Button)
--   local handle = Button.attach(someButtonInstance)          -- wire an existing button
--   local h2 = Button.create(parent, { Text = "PLAY", Icon = 123 }) -- clone the template
--   handle.onActivated(function() print("clicked") end)
--   handle:setText("GO"); handle:setEnabled(false); handle:destroy()

local TweenService = game:GetService("TweenService")

local Button = {}

-- Where Button.create() clones from, tried in order. Edit the design in Studio here.
local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "Button" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "Button" },
	{ "StarterGui", "UITemplates", "Button" },
}

local DEFAULTS = {
	HoverScale = 1.06,
	HoverStrokeMult = 1.6,
	HoverIconRotation = 45,
	PressScale = 0.94,
	TweenTime = 0.15,
	GradientAnimate = true,
	GradientSpeed = 3,
	UseAutoButtonColor = false,
	GlowStrokeName = "UIStrokeWithGradient", -- preferred glow stroke name (falls back to any UIStroke)
	StrokeHiddenUntilHover = false,          -- true = stroke invisible until hover (unit-slot glow style)
	HoverStrokeColor = false,                -- Color3 = on hover set the stroke to this colour (e.g. white)
	                                         -- instead of/in addition to thickening (set HoverStrokeMult=1)
}

local function cfg(inst: Instance, key: string)
	local v = inst:GetAttribute(key)
	if v == nil then
		return DEFAULTS[key]
	end
	return v
end

local function resolveTemplate(): GuiObject?
	for _, path in ipairs(TEMPLATE_PATHS) do
		local node: Instance? = game
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and node:IsA("GuiObject") then
			return node
		end
	end
	return nil
end

-- Move a GuiObject's AnchorPoint to the centre WITHOUT moving it, so a UIScale scales from
-- the middle instead of drifting toward the bottom-right.
local function centerAnchor(obj: GuiObject)
	local a = obj.AnchorPoint
	if a == Vector2.new(0.5, 0.5) then return end
	local d = Vector2.new(0.5, 0.5) - a
	local s = obj.Size
	obj.Position = UDim2.new(
		obj.Position.X.Scale + d.X * s.X.Scale, obj.Position.X.Offset + d.X * s.X.Offset,
		obj.Position.Y.Scale + d.Y * s.Y.Scale, obj.Position.Y.Offset + d.Y * s.Y.Offset
	)
	obj.AnchorPoint = Vector2.new(0.5, 0.5)
end

-- Rewrite a gradient's ColorSequence as a tiled + wrapped loop so scrolling the Offset is
-- perfectly seamless (end meets start) - important for multi-colour tiers (rainbow/secret).
local function makeSeamless(grad: UIGradient)
	local colors = {}
	for _, kp in ipairs(grad.Color.Keypoints) do
		table.insert(colors, kp.Value)
	end
	if #colors == 0 then return end
	local ext = {}
	for _, c in ipairs(colors) do table.insert(ext, c) end
	for _, c in ipairs(colors) do table.insert(ext, c) end
	table.insert(ext, colors[1])
	if #ext > 20 then return end -- ColorSequence hard cap
	local kps = {}
	for i, c in ipairs(ext) do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#ext - 1), c))
	end
	grad.Color = ColorSequence.new(kps)
end

-- Attach reusable behaviour to an existing GuiButton. Returns a handle.
function Button.attach(btn: GuiButton, opts: { [string]: any }?)
	opts = opts or {}
	local function opt(key: string)
		local o = (opts :: any)[key]
		if o ~= nil then return o end
		return cfg(btn, key)
	end

	-- Parts (all optional). Content holder is "Frame" (standard button) or "Main" (icon slot).
	local content = btn:FindFirstChild("Frame") or btn:FindFirstChild("Main")
	local scaleTarget: GuiObject = (content and content:IsA("GuiObject") and content) or btn
	-- Text/Icon by convention: "Text"/"Icon" (Frame-style) or "ButtonText"/"ButtonImgIcon".
	local textLabel = scaleTarget:FindFirstChild("Text") or scaleTarget:FindFirstChild("ButtonText")
		or btn:FindFirstChild("ButtonText", true)
	local icon = scaleTarget:FindFirstChild("Icon") or scaleTarget:FindFirstChild("ButtonImgIcon")
		or btn:FindFirstChild("ButtonImgIcon", true)
	-- Glow stroke: prefer the named one anywhere under the button, else any UIStroke.
	local glowName = opt("GlowStrokeName")
	local stroke = (glowName and btn:FindFirstChild(glowName, true))
		or btn:FindFirstChildOfClass("UIStroke")
		or btn:FindFirstChildWhichIsA("UIStroke", true)
	local bodyGradient = btn:FindFirstChildOfClass("UIGradient")
		or (content and content:FindFirstChildOfClass("UIGradient"))
	local strokeGradient = stroke and stroke:FindFirstChildOfClass("UIGradient")

	if btn:IsA("ImageButton") or btn:IsA("TextButton") then
		(btn :: any).AutoButtonColor = opt("UseAutoButtonColor") and true or false
	end

	-- UIScale on the scale target (create one if absent); centre it so it scales from the middle.
	if scaleTarget ~= btn then centerAnchor(scaleTarget) end
	local uiScale = scaleTarget:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = scaleTarget
	end

	-- Cached base values
	local baseScale = uiScale.Scale
	local baseThickness = stroke and stroke.Thickness or 0
	local baseRotation = (icon and icon:IsA("GuiObject")) and icon.Rotation or 0
	local hideStroke = opt("StrokeHiddenUntilHover") and true or false
	local baseTransparency = stroke and stroke.Transparency or 0
	if stroke and hideStroke then
		baseTransparency = 1
		stroke.Transparency = 1
	end
	local baseStrokeColor = (stroke and stroke.Color) or Color3.new(1, 1, 1)
	local baseStrokeSeq: ColorSequence? = strokeGradient and strokeGradient.Color or nil

	local tweens: { [string]: Tween } = {}
	local function play(name: string, target: Instance, props: { [string]: any }, time: number?)
		if tweens[name] then tweens[name]:Cancel() end
		local info = TweenInfo.new(time or opt("TweenTime"), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local t = TweenService:Create(target, info, props)
		tweens[name] = t
		t:Play()
		return t
	end

	local function setHover(on: boolean)
		local scale = on and (baseScale * opt("HoverScale")) or baseScale
		play("scale", uiScale, { Scale = scale })
		if stroke then
			local thick = on and (baseThickness * opt("HoverStrokeMult")) or baseThickness
			local tr = on and (hideStroke and 0 or baseTransparency) or baseTransparency
			play("stroke", stroke, { Thickness = thick, Transparency = tr })
			local hc = opt("HoverStrokeColor")
			if typeof(hc) == "Color3" then
				if strokeGradient then
					strokeGradient.Color = on and ColorSequence.new(hc)
						or (baseStrokeSeq or ColorSequence.new(baseStrokeColor))
				else
					play("strokeColor", stroke, { Color = on and hc or baseStrokeColor })
				end
			end
		end
		if icon and icon:IsA("GuiObject") then
			local rot = on and (baseRotation + opt("HoverIconRotation")) or baseRotation
			play("icon", icon, { Rotation = rot })
		end
	end

	local hovering = false
	local pressed = false
	local hoverCallbacks: { (boolean) -> () } = {}
	local function fireHover(on: boolean)
		for _, f in ipairs(hoverCallbacks) do task.spawn(f, on) end
	end
	local function refresh()
		if pressed then
			play("scale", uiScale, { Scale = baseScale * opt("PressScale") }, opt("TweenTime") * 0.6)
		else
			setHover(hovering)
		end
	end

	local conns: { RBXScriptConnection } = {}
	local function bind(sig: RBXScriptSignal, fn: (...any) -> ())
		table.insert(conns, sig:Connect(fn))
	end

	bind(btn.MouseEnter, function() hovering = true; refresh(); fireHover(true) end)
	bind(btn.MouseLeave, function() hovering = false; pressed = false; refresh(); fireHover(false) end)
	bind(btn.InputBegan, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = true; refresh()
		end
	end)
	bind(btn.InputEnded, function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			pressed = false; refresh()
		end
	end)
	-- Safety: if the button (or an ancestor) hides, drop hover state so it can't stick
	bind(btn:GetPropertyChangedSignal("Visible"), function()
		if not btn.Visible then hovering = false; pressed = false; refresh() end
	end)

	-- Animated gradient (seamless offset scroll)
	local gradTweens: { Tween } = {}
	local function startGradient()
		for _, t in ipairs(gradTweens) do t:Cancel() end
		table.clear(gradTweens)
		if not opt("GradientAnimate") then return end
		local info = TweenInfo.new(opt("GradientSpeed"), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0)
		for _, g in ipairs({ strokeGradient, bodyGradient }) do
			if g then
				makeSeamless(g)
				g.Offset = Vector2.new(-1, 0)
				local t = TweenService:Create(g, info, { Offset = Vector2.new(1, 0) })
				t:Play()
				table.insert(gradTweens, t)
			end
		end
		if strokeGradient then baseStrokeSeq = strokeGradient.Color end
	end
	startGradient()

	setHover(false)

	local handle = {}
	handle.instance = btn

	function handle.onActivated(fn: (...any) -> ()): RBXScriptConnection
		local c = btn.Activated:Connect(fn)
		table.insert(conns, c)
		return c
	end
	function handle.setText(s: string)
		if textLabel and textLabel:IsA("TextLabel") then textLabel.Text = s end
	end
	function handle.setIcon(assetId: (string | number)?)
		if icon and icon:IsA("ImageLabel") then
			icon.Image = assetId and ("rbxassetid://" .. tostring(assetId)) or ""
		end
	end
	function handle.setStrokeColor(c: Color3)
		if stroke then stroke.Color = c end
	end
	-- Programmatic hover (keyboard/gamepad selection, tests). Mirrors a real mouse hover.
	function handle.setHovered(on: boolean)
		hovering = on and true or false
		refresh()
		fireHover(hovering)
	end
	-- React to hover changes (e.g. show a preview card). Returns a disconnect function.
	function handle.onHover(fn: (boolean) -> ()): () -> ()
		table.insert(hoverCallbacks, fn)
		return function()
			local i = table.find(hoverCallbacks, fn)
			if i then table.remove(hoverCallbacks, i) end
		end
	end
	function handle.setEnabled(on: boolean)
		btn.Active = on
		btn.AutoButtonColor = false
		btn.Interactable = on
	end
	function handle.destroy()
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, t in ipairs(gradTweens) do t:Cancel() end
		for _, t in pairs(tweens) do t:Cancel() end
	end

	return handle
end

-- Clone the template design and attach behaviour. Returns the same handle as attach().
function Button.create(parent: Instance, opts: { [string]: any }?)
	local template = resolveTemplate()
	assert(template, "UIKit.Button.create: no Button template found in " ..
		"ReplicatedStorage.UITemplates.Kit / Shared.UIKit.Templates / StarterGui.UITemplates")
	local clone = template:Clone()
	clone.Visible = true
	clone.Parent = parent
	local handle = Button.attach(clone :: any, opts)
	if opts then
		if opts.Text then handle.setText(opts.Text) end
		if opts.Icon then handle.setIcon(opts.Icon) end
	end
	return handle
end

return Button
