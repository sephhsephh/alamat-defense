--!strict
-- tools/ui_phone_preview.luau (B127) -- render the GAME HUD at any screen size inside Studio's Edit
-- viewport, scaled EXACTLY the way SettingsUI scales it at runtime (device factor, AD_ScaleGroup groups,
-- AD_GroupPivot, AD_ScaleMax, anchorInward, size-scaling of panels that own an animated UIScale), so a
-- phone layout can be judged with screen_capture -- no device, no Play.
-- Deployed as ServerStorage.DevTools.UIPhonePreview (Game). Usage via execute_luau (Edit):
--   require(game.ServerStorage.DevTools.UIPhonePreview).Show(667, 375)   -- builds StarterGui._PhonePreview
--   require(game.ServerStorage.DevTools.UIPhonePreview).Hide()
-- Keep the scaling rules here in step with SettingsUI's "UI SCALE" section (DEVICE_REF / DEVICE_MAX).
-- (SettingsUI's FIT cap is not modelled: no HUD element is big enough to hit it.)
-- Shows the busiest match state: vote panel + next-wave info + placement bar + one toast.

local Preview = {}

local DEVICE_REF, DEVICE_MAX = 560, 1 -- B131: the phone boost is off in SettingsUI
local SCREENS = { "MatchHUD", "Hotbar", "XPBarGui", "WavePrep", "Notifications", "PlacementControls", "BossHealth" }

function Preview.Hide()
	local old = game:GetService("StarterGui"):FindFirstChild("_PhonePreview")
	if old then old:Destroy() end
end

function Preview.Show(W: number, H: number, kOverride: number?): string
	local SG = game:GetService("StarterGui")
	Preview.Hide()
	local K = kOverride or math.clamp(DEVICE_REF / math.min(W, H), 1, DEVICE_MAX)
	if math.min(W, H) >= DEVICE_REF and not kOverride then K = 1 end
	local probe = Instance.new("ScreenGui")
	probe.Name = "_PhonePreview"
	probe.IgnoreGuiInset = true
	probe.DisplayOrder = 999999
	probe.Parent = SG
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
	bg.BorderSizePixel = 0
	bg.Parent = probe
	local stage = Instance.new("Frame")
	stage.Name = "Phone"
	stage.Position = UDim2.fromOffset(20, 20)
	stage.Size = UDim2.fromOffset(W, H)
	stage.BackgroundColor3 = Color3.fromRGB(70, 95, 70)
	stage.BorderSizePixel = 0
	stage.ClipsDescendants = true
	stage.Parent = probe
	for _, name in ipairs(SCREENS) do
		local src = SG:FindFirstChild(name)
		if src then
			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.fromScale(1, 1)
			holder.BackgroundTransparency = 1
			holder.Parent = stage
			for _, c in ipairs(src:GetChildren()) do
				if not c:IsA("LuaSourceContainer") then
					local cl = c:Clone()
					for _, d in ipairs(cl:GetDescendants()) do
						if d:IsA("LuaSourceContainer") then d:Destroy() end
					end
					cl.Parent = holder
				end
			end
		end
	end
	local function hide(path: { string })
		local n: Instance? = stage
		for _, seg in ipairs(path) do n = n and n:FindFirstChild(seg) end
		if n and n:IsA("GuiObject") then n.Visible = false end
	end
	local function show(path: { string })
		local n: Instance? = stage
		for _, seg in ipairs(path) do n = n and n:FindFirstChild(seg) end
		if n and n:IsA("GuiObject") then n.Visible = true end
	end
	for _, n in ipairs({ "BossWarning", "ScreenFlash", "WaveBanner", "StageInfoPanel", "Clock" }) do hide({ "MatchHUD", n }) end
	show({ "WavePrep", "Root" }); show({ "WavePrep", "Preview" }); hide({ "WavePrep", "Countdown" })
	show({ "PlacementControls", "Panel" })
	local nt = stage:FindFirstChild("Notifications")
	local tpl = nt and nt:FindFirstChild("CardTemplate")
	local cont = nt and nt:FindFirstChild("Container")
	if tpl and cont then
		local card = tpl:Clone() :: any
		card.Name = "Toast"
		card.Visible = true
		card.Parent = cont
	end
	task.wait()

	local function capK(o: Instance): number
		local c = tonumber(o:GetAttribute("AD_ScaleMax"))
		return if c then math.min(K, math.max(c, 1)) else K
	end
	local function isContainer(o: GuiObject): boolean
		return o.Size.X.Scale >= 0.95 or o.Size.Y.Scale >= 0.95
	end
	local function isHolder(o: GuiObject): boolean
		if o.BackgroundTransparency < 0.99 then return false end
		if (o:IsA("ImageLabel") or o:IsA("ImageButton")) and (o :: any).Image ~= "" and (o :: any).ImageTransparency < 0.99 then return false end
		return true
	end
	local function anchorInward(o: GuiObject)
		if o.AutomaticSize ~= Enum.AutomaticSize.None then return end
		local p = o.Parent :: any
		if p:FindFirstChildWhichIsA("UIGridStyleLayout") then return end
		local ps, pp = p.AbsoluteSize, p.AbsolutePosition
		local c = o.AbsolutePosition + o.AbsoluteSize / 2
		local rx, ry = (c.X - pp.X) / ps.X, (c.Y - pp.Y) / ps.Y
		local ax = if rx < 0.34 then 0 elseif rx > 0.66 then 1 else 0.5
		local ay = if ry < 0.34 then 0 elseif ry > 0.66 then 1 else 0.5
		local dx, dy = ax - o.AnchorPoint.X, ay - o.AnchorPoint.Y
		if dx == 0 and dy == 0 then return end
		local constrained = o:FindFirstChildWhichIsA("UIAspectRatioConstraint") or o:FindFirstChildWhichIsA("UISizeConstraint")
		if constrained then
			o.Position += UDim2.fromOffset(o.AbsoluteSize.X * dx, o.AbsoluteSize.Y * dy)
		else
			o.Position += UDim2.new(o.Size.X.Scale * dx, o.Size.X.Offset * dx, o.Size.Y.Scale * dy, o.Size.Y.Offset * dy)
		end
		o.AnchorPoint = Vector2.new(ax, ay)
	end
	local function sizeMul(o: GuiObject, k: number)
		local b = o.Size
		o.Size = UDim2.new(b.X.Scale * k, b.X.Offset * k, b.Y.Scale * k, b.Y.Offset * k)
	end
	local done: { [string]: boolean } = {}
	local function scaleGroup(name: string)
		if done[name] then return end
		done[name] = true
		local boxes, x0, y0, x1, y1 = {}, math.huge, math.huge, -math.huge, -math.huge
		local pov: UDim2? = nil
		for _, d in ipairs(stage:GetDescendants()) do
			if d:IsA("GuiObject") and d:GetAttribute("AD_ScaleGroup") == name then
				local pv = d:GetAttribute("AD_GroupPivot")
				if typeof(pv) == "UDim2" then pov = pv end
				local p, sz = d.AbsolutePosition - stage.AbsolutePosition, d.AbsoluteSize
				if sz.X >= 1 then
					table.insert(boxes, { m = d, c = p + sz / 2 })
					x0, y0 = math.min(x0, p.X), math.min(y0, p.Y)
					x1, y1 = math.max(x1, p.X + sz.X), math.max(y1, p.Y + sz.Y)
				end
			end
		end
		if #boxes == 0 then return end
		local cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
		local fx = if cx / W < 0.34 then 0 elseif cx / W > 0.66 then 1 else 0.5
		local fy = if cy / H < 0.34 then 0 elseif cy / H > 0.66 then 1 else 0.5
		local pivot = Vector2.new(x0 + (x1 - x0) * fx, y0 + (y1 - y0) * fy)
		if pov then pivot = Vector2.new(W * pov.X.Scale + pov.X.Offset, H * pov.Y.Scale + pov.Y.Offset) end
		for _, b in ipairs(boxes) do
			local m = b.m
			local nc = pivot + (b.c - pivot) * K
			m.AnchorPoint = Vector2.new(0.5, 0.5)
			m.Position = UDim2.fromScale(nc.X / W, nc.Y / H)
			if m:FindFirstChildOfClass("UIScale") then
				sizeMul(m, capK(m))
			else
				local u = Instance.new("UIScale")
				u.Name = "AD_UIScale"
				u.Scale = capK(m)
				u.Parent = m
			end
		end
	end
	local function scaleNode(o: Instance, depth: number)
		if not o:IsA("GuiObject") or o.Name:find("Template$") or o.Name:find("_Retired") then return end
		local g = o:GetAttribute("AD_ScaleGroup")
		if type(g) == "string" and g ~= "" then scaleGroup(g) return end
		if capK(o) == 1 then return end
		local anim = o:FindFirstChildOfClass("UIScale")
		if anim then
			if anim.Name ~= "Responsive" then anchorInward(o :: GuiObject) sizeMul(o :: GuiObject, capK(o)) end
			return
		end
		local inLayout = (o.Parent :: Instance):FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
		if not inLayout and isContainer(o :: GuiObject) then
			if depth < 3 and isHolder(o :: GuiObject) then
				for _, c in ipairs(o:GetChildren()) do scaleNode(c, depth + 1) end
			end
			return
		end
		anchorInward(o :: GuiObject)
		local u = Instance.new("UIScale")
		u.Name = "AD_UIScale"
		u.Scale = capK(o)
		u.Parent = o
	end
	if K > 1 then
		for _, holder in ipairs(stage:GetChildren()) do
			for _, c in ipairs(holder:GetChildren()) do scaleNode(c, 1) end
		end
	end
	return string.format("preview %dx%d at x%.2f", W, H, K)
end

return Preview
