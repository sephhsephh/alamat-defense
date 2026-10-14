--!strict
-- tools/alamat_plate.luau (B151) -- THE universal rectangle button of Alamat Defense: the Sun-Gem PLATE.
-- Deployed as ServerStorage.DevTools.AlamatPlate in BOTH Places. EDIT-TIME ONLY (it authors instances; runtime
-- motion lives in RS.AlamatUI.AlamatButton, which binds anything tagged "AlamatButton" with Variant "Plate").
--
-- User (B148 batch): "a universal button template ... all rectangle-ish buttons ... universal style / effect but
-- still customizable / modifiable color ... similar hover / click effects ... alamat defense fantasy magical style".
-- RULE (CLAUDE.md + alamat-ui.md): every rectangle action button in every new UI = a Plate. Use:
--   local P = require(game.ServerStorage.DevTools.AlamatPlate:Clone())
--   P.convert(button, "Jade")      -- restyle an EXISTING button in place (names / children scripts use are kept)
--   P.make(parent, "BuyButton", "BUY", "Gold")  -- a new one (or clone RS.AlamatUI.Templates.AlamatPlate)
--   P.buildTemplate()              -- (re)author RS.AlamatUI.Templates.AlamatPlate + Templates.Selector
-- Theme = a Theme.Palettes name (Gold Violet Azure Teal Ember Indigo Rose Jade Night Ruby Stone) or nil to KEEP the
-- button's own BackgroundColor3 (any custom colour). The root IS the colour; `Core` is a luminance ramp on it, so a
-- script that recolours or dims the button keeps working.

local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Theme = require(RS:WaitForChild("AlamatUI"):WaitForChild("Theme")) :: any

local P = {}
local PLATE_LAYERS = { "Inner", "Gloss", "Lip", "ShineClip", "Flash", "Burst", "Sparkles", "PlateText", "Pop" }
local LABEL_NAMES = { ButtonText = true, Label = true, Text = true, TextLabel = true, Title = true, Amount = true }

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in pairs(props) do (o :: any)[k] = v end
	o.Parent = parent
	return o
end

local function corner(o: Instance, r: UDim?)
	local c = o:FindFirstChildOfClass("UICorner") or new("UICorner", {}, o)
	c.CornerRadius = r or Theme.Plate.Corner
end

local function tintGrad(o: Instance, name: string?)
	local g = o:FindFirstChild("Tint") or new("UIGradient", { Name = "Tint" }, o)
	g.Color = Theme.tint(name or "Gold")
end

-- restyle an existing button in place
-- B157 (user: "it looks like there's a button inside a button"): a UIPadding on the button ROOT also insets the
-- Plate's own layers (Gloss / Lip / Inner / Flash), so the face drew as a smaller rectangle inside the rim. The
-- padding moves onto the CONTENT instead: every non-layer child is remapped into the padded rectangle, then the
-- UIPadding goes. A button whose children a UIListLayout / UIGridLayout places is left alone (and reported).
local PAD_LAYERS = { Inner = true, Gloss = true, Lip = true, ShineClip = true, Flash = true, Burst = true, Sparkles = true }
function P.unpad(btn: GuiObject): boolean
	local pad = btn:FindFirstChildOfClass("UIPadding")
	if not pad then return false end
	if btn:FindFirstChildWhichIsA("UIGridStyleLayout") then
		warn("[AlamatPlate] unpad skipped (a layout places its children): " .. btn:GetFullName())
		return false
	end
	local abs = btn.AbsoluteSize
	local function frac(u: UDim, axis: number): number
		return u.Scale + (if axis > 0 then u.Offset / axis else 0)
	end
	local L, R = frac(pad.PaddingLeft, abs.X), frac(pad.PaddingRight, abs.X)
	local T, B = frac(pad.PaddingTop, abs.Y), frac(pad.PaddingBottom, abs.Y)
	local w, h = math.max(0.05, 1 - L - R), math.max(0.05, 1 - T - B)
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("GuiObject") and not PAD_LAYERS[c.Name] then
			c.Position = UDim2.new(L + c.Position.X.Scale * w, c.Position.X.Offset, T + c.Position.Y.Scale * h, c.Position.Y.Offset)
			c.Size = UDim2.new(c.Size.X.Scale * w, c.Size.X.Offset, c.Size.Y.Scale * h, c.Size.Y.Offset)
		end
	end
	pad:Destroy()
	return true
end

function P.convert(btn: GuiButton, themeName: string?): GuiButton
	assert(btn and btn:IsA("GuiButton"), "AlamatPlate.convert: not a GuiButton")
	P.unpad(btn) -- B157: content keeps its inset, the Plate's layers span the whole button
	for _, n in ipairs(PLATE_LAYERS) do
		local old = btn:FindFirstChild(n)
		if old then old:Destroy() end
	end
	local base = btn.ZIndex
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ClipsDescendants = false
	if btn.BackgroundTransparency >= 0.99 then btn.BackgroundTransparency = 0 end
	if btn:IsA("ImageButton") then
		local ib = btn :: ImageButton
		if ib.Image ~= "" and ib.ImageTransparency < 1 then ib:SetAttribute("PlateOldImage", ib.Image) end
		ib.Image = ""
	end
	btn:SetAttribute("Variant", "Plate")
	if themeName then
		btn:SetAttribute("Theme", themeName)
		btn.BackgroundColor3 = Theme.plateColor(themeName)
	elseif btn:GetAttribute("Theme") == nil then
		btn:SetAttribute("Theme", "Custom")
	end
	local tint = if themeName then themeName else "Gold"
	corner(btn)

	-- the core shade: re-use the first UIGradient (scripts may hold it by name), drop any others
	local core: UIGradient? = nil
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("UIGradient") then
			if core == nil then core = c else warn("[AlamatPlate] dropped extra UIGradient '" .. c.Name .. "' on " .. btn:GetFullName() .. " -- check scripts that use it") c:Destroy() end
		end
	end
	if core == nil then core = new("UIGradient", { Name = "Core" }, btn) end
	local cg = core :: UIGradient
	cg.Color = Theme.Plate.CoreShade
	cg.Transparency = NumberSequence.new(0)
	cg.Rotation = 90
	cg.Offset = Vector2.zero
	cg.Enabled = true

	-- the gold rim: re-use the first UIStroke (kept by name for scripts), drop any others
	local rim: UIStroke? = nil
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("UIStroke") then
			if rim == nil then rim = c else warn("[AlamatPlate] dropped extra UIStroke '" .. c.Name .. "' on " .. btn:GetFullName() .. " -- a script may use it (B157: Play's SelectedStroke)") c:Destroy() end
		end
	end
	if rim == nil then rim = new("UIStroke", { Name = "Rim" }, btn) end
	local r = rim :: UIStroke
	r.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	r.Color = Color3.new(1, 1, 1)
	r.Thickness = 2
	r.Transparency = 0
	r.LineJoinMode = Enum.LineJoinMode.Round
	-- a re-used stroke may be ScaledSize (thickness = a FRACTION of the button): 3.6 became a 176 px ellipse
	pcall(function() (r :: any).StrokeSizingMode = Enum.StrokeSizingMode.FixedSize end)
	r.Enabled = true
	for _, g in ipairs(r:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
	new("UIGradient", { Name = "Gold", Color = Theme.Gold }, r)
	btn:SetAttribute("PlateRim", r.Name)

	-- layers
	local inner = new("Frame", { Name = "Inner", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.965, 0.84), BackgroundTransparency = 1, ZIndex = base + 1 }, btn)
	corner(inner, UDim.new(0.28, 0))
	new("UIStroke", { Name = "Line", Color = Color3.new(1, 1, 1), Transparency = 0.72, Thickness = 1 }, inner)
	local gloss = new("Frame", { Name = "Gloss", Position = UDim2.fromScale(0.03, 0.05), Size = UDim2.fromScale(0.94, 0.46),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = base + 1 }, btn)
	corner(gloss, UDim.new(0.5, 0))
	new("UIGradient", { Rotation = 90, Transparency = Theme.Plate.Gloss }, gloss)
	local lip = new("Frame", { Name = "Lip", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.34),
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = base + 1 }, btn)
	corner(lip)
	new("UIGradient", { Rotation = 90, Transparency = Theme.Plate.Lip }, lip)
	local clip = new("Frame", { Name = "ShineClip", Position = UDim2.fromScale(0.025, 0.06), Size = UDim2.fromScale(0.95, 0.88),
		BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = base + 2 }, btn)
	new("ImageLabel", { Name = "Streak", Image = Theme.Images.Streak, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(-0.5, 0.5), Size = UDim2.fromScale(0.5, 2.4), Rotation = 18, ImageTransparency = 1,
		ZIndex = base + 2 }, clip)
	local flash = new("Frame", { Name = "Flash", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = base + 3 }, btn)
	corner(flash)

	-- content (labels, icons, coins, badges) sits above the layers
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("GuiObject") and c ~= inner and c ~= gloss and c ~= lip and c ~= clip and c ~= flash then
			if c.ZIndex < base + 4 then c.ZIndex = base + 4 end
			for _, d in ipairs(c:GetDescendants()) do
				if d:IsA("GuiObject") and d.ZIndex < base + 4 then d.ZIndex = base + 4 end
			end
			if c:IsA("TextLabel") and LABEL_NAMES[c.Name] then
				c.FontFace = Theme.Fonts.Label
				c.TextColor3 = Theme.Plate.TextColor
				for _, g in ipairs(c:GetChildren()) do if g:IsA("UIGradient") then g:Destroy() end end
				local o = c:FindFirstChildOfClass("UIStroke") or new("UIStroke", { Name = "Outline" }, c)
				o.Color = Theme.Plate.TextStroke
				o.Thickness = 1.5
				o.Transparency = 0.1
				o.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				pcall(function() (o :: any).StrokeSizingMode = Enum.StrokeSizingMode.FixedSize end)
			end
		end
	end
	-- a TextButton's own VISIBLE text moves to a styled label (AlamatButton mirrors btn.Text into it at runtime).
	-- Not when the button already shows a label child (its own Text is then a hidden duplicate -- two texts overlap).
	local hasLabel = false
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("TextLabel") and LABEL_NAMES[c.Name] then hasLabel = true end
	end
	if btn:IsA("TextButton") and (btn :: TextButton).Text ~= "" and not hasLabel
		and ((btn :: TextButton).TextTransparency < 1 or btn:GetAttribute("PlateMirror") == true) then
		local tb = btn :: TextButton
		tb:SetAttribute("PlateMirror", true) -- re-running convert keeps mirroring (the own text is hidden by then)
		local cap = tb:FindFirstChildOfClass("UITextSizeConstraint")
		local pt = new("TextLabel", { Name = "PlateText", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.88, 0.62), Text = tb.Text, TextScaled = true,
			FontFace = Theme.Fonts.Label, TextColor3 = Theme.Plate.TextColor, ZIndex = base + 5, RichText = tb.RichText }, tb)
		new("UIStroke", { Name = "Outline", Color = Theme.Plate.TextStroke, Thickness = 1.5, Transparency = 0.1 }, pt)
		new("UITextSizeConstraint", { MaxTextSize = if cap then cap.MaxTextSize else 32, MinTextSize = 8 }, pt)
		tb.TextTransparency = 1
	end

	-- VFX art (white, tinted)
	local burst = new("ImageLabel", { Name = "Burst", Image = Theme.Images.Burst, BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(3, 2.4),
		ImageTransparency = 1, ZIndex = base + 6 }, btn)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, burst)
	tintGrad(burst, tint)
	local sp = new("Frame", { Name = "Sparkles", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = base + 6 }, btn)
	for i, at in ipairs({ Vector2.new(0.035, 0.1), Vector2.new(0.965, 0.9) }) do
		local s = new("ImageLabel", { Name = "Spark" .. i, Image = Theme.Images.Sparkles[i], BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(at.X, at.Y), Size = UDim2.fromScale(50, 0),
			ImageTransparency = 1, ZIndex = base + 6 }, sp)
		s:SetAttribute("S", 0.5) -- twinkle height (fraction of the button): small, so it never hides the label
		new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, s)
		tintGrad(s, tint)
	end
	new("UIScale", { Name = "Pop" }, btn)
	-- one animator per button: the older UIKit.Button (tag "UIKitButton") and ScreenFX.juice step aside
	CollectionService:RemoveTag(btn, "UIKitButton")
	btn:SetAttribute("NoFX", true)
	CollectionService:AddTag(btn, "AlamatButton")
	return btn
end

-- a brand-new Plate TextButton
function P.make(parent: Instance, name: string, text: string, themeName: string?): TextButton
	local b = new("TextButton", { Name = name, Size = UDim2.fromScale(0.2, 0.08), Text = text, TextScaled = true,
		FontFace = Theme.Fonts.Label, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Theme.plateColor(themeName or "Gold") }, parent)
	P.convert(b, themeName or "Gold")
	return b
end

-- the authored master every future screen clones (+ the gamepad Selector the animator assigns)
function P.buildTemplate(): TextButton
	local A = RS:WaitForChild("AlamatUI")
	local T = A:FindFirstChild("Templates") or new("Folder", { Name = "Templates" }, A)
	local old = T:FindFirstChild("AlamatPlate")
	if old then old:Destroy() end
	local b = P.make(T, "AlamatPlate", "BUTTON", "Gold")
	b.Visible = false
	if not T:FindFirstChild("Selector") then
		local s = new("ImageLabel", { Name = "Selector", Image = Theme.Images.GlowRing, BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.35, 1.6),
			ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(64, 64, 64, 64) }, T)
		tintGrad(s, "Gold")
	end
	return b
end

return P
