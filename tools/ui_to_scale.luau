--!strict
-- tools/ui_to_scale.luau (B131) -- convert authored UI from OFFSET to SCALE (user: "use all scale, not offset,
-- never use offset, so ui will look same on all device").
-- Deployed as ServerStorage.DevTools.UIToScale in each Place. Run from execute_luau in Edit:
--   local C = require(game.ServerStorage.DevTools.UIToScale:Clone())
--   C.Run("MatchHUD", { dry = true })   -- report what would change, change nothing
--   C.Run("MatchHUD")                   -- back up to ServerStorage._UIBackup_B131, convert, verify
--   C.RunAll({ dry = true })             -- every ScreenGui in StarterGui (SKIP list excluded)
--   C.Restore("MatchHUD")               -- put the backup back
-- Reference = the authored 1920x1080 layout: every value is converted so the screen looks IDENTICAL at
-- 1080p (each run re-lays the screen out at 1920x1080 before and after and reports any element that
-- moved more than 1.5 px). What it converts:
--   * GuiObject Size / Position offsets -> scale of the parent (SizeConstraint respected);
--     an element that was sized purely in offset gets a UIAspectRatioConstraint `AD_Aspect` (keeps its shape)
--   * UICorner, UIPadding, UIListLayout.Padding, UIGridLayout CellSize/CellPadding offsets -> scale
--     (a grid that was pure offset also gets `AD_Aspect` under the layout, so cells stay their shape)
--   * fixed-size text -> TextScaled + a UITextSizeConstraint `AD_TextCap` (MaxTextSize = the authored size,
--     attribute AD_BaseTextSize; SettingsUI grows the cap on screens taller than 1080)
-- LEFT IN OFFSET on purpose (they measure in pixels, scale would break them):
--   * items placed DIRECTLY in a ScrollingFrame or a UIGridLayout (the canvas / the cell decides their size;
--     everything INSIDE an item is converted, relative to the item)
--   * anything under an AutomaticSize frame (it sizes to its content's pixels)
--   * `*Template*` roots (their clones go into lists/canvases); their insides are converted
--   * a panel that owns a UIScale named `Responsive` AND EVERYTHING INSIDE IT (its own script already fits it
--     to the screen; converting its insides would fight that fit -- TraitReroll would shrink ~1.5x at 1080p)
--   * ScrollingFrame CanvasSize, UISizeConstraint limits, UIStroke thickness

local Conv = {}

local REF = Vector2.new(1920, 1080)
local INSET = 58 -- Roblox top bar: an IgnoreGuiInset = false screen lays out in 1080 - 58
local SKIP = { Hotbar = true, ScreenFXLayer = true, AdminPanel = true, AdminBroadcastGUI = true, Freecam = true, _PhonePreview = true, _UIAuditProbe = true, _UIToScaleProbe = true }
local TOL = 1.5

local function isText(o: Instance): boolean
	return o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
end

local function stageFor(screen: ScreenGui): (ScreenGui, Frame)
	local SG = game:GetService("StarterGui")
	local probe = Instance.new("ScreenGui")
	probe.Name = "_UIToScaleProbe"
	probe.IgnoreGuiInset = true
	probe.Parent = SG
	local stage = Instance.new("Frame")
	stage.BackgroundTransparency = 1
	stage.Size = UDim2.fromOffset(REF.X, if screen.IgnoreGuiInset then REF.Y else REF.Y - INSET)
	stage.Parent = probe
	for _, c in ipairs(screen:GetChildren()) do
		local cl = c:Clone()
		for _, d in ipairs(cl:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then d:Destroy() end
		end
		if cl:IsA("LuaSourceContainer") then cl:Destroy() else cl.Parent = stage end
	end
	return probe, stage
end

local function settle()
	local RS = game:GetService("RunService")
	RS.Heartbeat:Wait()
	RS.Heartbeat:Wait()
end

-- rects of every GuiObject, keyed by its path inside the screen
local function rects(stage: Frame): { [string]: { Vector2 } }
	local out = {}
	for _, d in ipairs(stage:GetDescendants()) do
		if d:IsA("GuiObject") then
			local parts = {}
			local n: Instance? = d
			while n and n ~= stage do
				table.insert(parts, 1, n.Name)
				n = n.Parent
			end
			local key = table.concat(parts, ".")
			if out[key] == nil then
				out[key] = { d.AbsolutePosition - stage.AbsolutePosition, d.AbsoluteSize }
			else
				out[key] = { Vector2.new(-1e9, -1e9), Vector2.zero } -- duplicate path: not comparable
			end
		end
	end
	return out
end

-- walk original + its layout clone in parallel (Clone keeps child order); returns false on a mismatch
local function pair(orig: Instance, clone: Instance, fn: (Instance, Instance) -> ()): boolean
	local a, b = orig:GetChildren(), clone:GetChildren()
	-- scripts were stripped from the clone: skip them in the original too
	local fa = {}
	for _, x in ipairs(a) do
		if not x:IsA("LuaSourceContainer") then table.insert(fa, x) end
	end
	if #fa ~= #b then return false end
	for i, x in ipairs(fa) do
		if x.Name ~= b[i].Name or x.ClassName ~= b[i].ClassName then return false end
		fn(x, b[i])
		if not pair(x, b[i], fn) then return false end
	end
	return true
end

local function autoAncestor(o: Instance, screen: Instance): boolean
	local n = o.Parent
	while n and n ~= screen do
		if n:IsA("GuiObject") and (n :: GuiObject).AutomaticSize ~= Enum.AutomaticSize.None then return true end
		n = n.Parent
	end
	return false
end

local function hasResponsive(o: Instance): boolean
	local u = o:FindFirstChildOfClass("UIScale")
	return u ~= nil and u.Name == "Responsive"
end

-- inside (or being) a panel with its own `Responsive` screen fit
local function inResponsive(o: Instance, screen: Instance): boolean
	local n: Instance? = o
	while n and n ~= screen do
		if n:IsA("GuiObject") and hasResponsive(n) then return true end
		n = n.Parent
	end
	return false
end

function Conv.Run(screenName: string, opts: any?): string
	local o = opts or {}
	local SG = game:GetService("StarterGui")
	local screen = SG:FindFirstChild(screenName)
	if not (screen and screen:IsA("ScreenGui")) then return screenName .. ": not a ScreenGui" end
	local probe, stage = stageFor(screen)
	settle()
	local before = rects(stage)
	local stageSize = stage.AbsoluteSize
	local n = { size = 0, pos = 0, aspect = 0, corner = 0, pad = 0, list = 0, grid = 0, text = 0, keptScroll = 0, keptAuto = 0, keptTpl = 0 }
	local edits: { () -> () } = {}

	local ok = pair(screen, stage, function(x: Instance, c: Instance)
		if inResponsive(x, screen) then
			return
		end
		if x:IsA("GuiObject") then
			local g, cg = x :: GuiObject, c :: GuiObject
			-- layout parent = the nearest GuiObject (a Folder is transparent to layout), else the screen
			local par: Instance? = c.Parent
			while par and par ~= stage and not par:IsA("GuiObject") do par = par.Parent end
			local pAbs: Vector2 = if par == nil or par == stage then stageSize else (par :: GuiObject).AbsoluteSize
			local parentIsScroll = x.Parent and x.Parent:IsA("ScrollingFrame")
			local parentIsGrid = x.Parent and x.Parent:FindFirstChildWhichIsA("UIGridLayout") ~= nil
			local underAuto = autoAncestor(x, screen)
			local isTpl = x.Name:find("Template") ~= nil
			local keep = parentIsScroll or parentIsGrid or underAuto or isTpl or hasResponsive(x)
			local s, p = g.Size, g.Position
			local hasOff = s.X.Offset ~= 0 or s.Y.Offset ~= 0 or p.X.Offset ~= 0 or p.Y.Offset ~= 0
			if keep then
				if hasOff then
					if underAuto then n.keptAuto += 1 elseif isTpl then n.keptTpl += 1 else n.keptScroll += 1 end
				end
			elseif hasOff and pAbs.X > 0 and pAbs.Y > 0 then
				local sc = g.SizeConstraint
				local refX = if sc == Enum.SizeConstraint.RelativeYY then pAbs.Y else pAbs.X
				local refY = if sc == Enum.SizeConstraint.RelativeXX then pAbs.X else pAbs.Y
				local ax, ay = g.AutomaticSize == Enum.AutomaticSize.X or g.AutomaticSize == Enum.AutomaticSize.XY,
					g.AutomaticSize == Enum.AutomaticSize.Y or g.AutomaticSize == Enum.AutomaticSize.XY
				local newS = UDim2.new(
					if ax then s.X.Scale else s.X.Scale + s.X.Offset / refX, if ax then s.X.Offset else 0,
					if ay then s.Y.Scale else s.Y.Scale + s.Y.Offset / refY, if ay then s.Y.Offset else 0)
				local newP = UDim2.new(p.X.Scale + p.X.Offset / pAbs.X, 0, p.Y.Scale + p.Y.Offset / pAbs.Y, 0)
				local pureOffset = s.X.Scale == 0 and s.Y.Scale == 0 and s.X.Offset > 0 and s.Y.Offset > 0
				local addAspect = pureOffset and not ax and not ay and x:FindFirstChildOfClass("UIAspectRatioConstraint") == nil
					and cg.AbsoluteSize.Y > 0
				if newS ~= s then n.size += 1 end
				if newP ~= p then n.pos += 1 end
				if addAspect then n.aspect += 1 end
				local ratio = if cg.AbsoluteSize.Y > 0 then cg.AbsoluteSize.X / cg.AbsoluteSize.Y else 1
				table.insert(edits, function()
					g.Size = newS
					g.Position = newP
					if addAspect then
						local a = Instance.new("UIAspectRatioConstraint")
						a.Name = "AD_Aspect"
						a.AspectRatio = ratio
						a.Parent = g
					end
				end)
			end
			-- fixed-size text -> scaled, capped at the authored size
			if isText(x) and not (x :: any).TextScaled and g.AutomaticSize == Enum.AutomaticSize.None and not underAuto then
				n.text += 1
				local ts = (x :: any).TextSize
				table.insert(edits, function()
					(x :: any).TextScaled = true
					if x:FindFirstChildOfClass("UITextSizeConstraint") == nil then
						local cap = Instance.new("UITextSizeConstraint")
						cap.Name = "AD_TextCap"
						cap.MaxTextSize = math.max(1, math.floor(ts + 0.5))
						cap:SetAttribute("AD_BaseTextSize", cap.MaxTextSize)
						cap.Parent = x
					end
				end)
			end
		elseif x:IsA("UICorner") then
			local own = c.Parent :: any
			local r = x.CornerRadius
			if r.Offset ~= 0 and own and own:IsA("GuiObject") then
				local m = math.min(own.AbsoluteSize.X, own.AbsoluteSize.Y)
				if m > 0 then
					n.corner += 1
					local v = UDim.new(r.Scale + r.Offset / m, 0)
					table.insert(edits, function() x.CornerRadius = v end)
				end
			end
		elseif x:IsA("UIPadding") then
			local own = c.Parent :: any
			if own and own:IsA("GuiObject") and not own:IsA("ScrollingFrame") and not autoAncestor(x, screen)
				and (own :: GuiObject).AutomaticSize == Enum.AutomaticSize.None then
				local w, h = own.AbsoluteSize.X, own.AbsoluteSize.Y
				local pl, pr, pt, pb = x.PaddingLeft, x.PaddingRight, x.PaddingTop, x.PaddingBottom
				if w > 0 and h > 0 and (pl.Offset ~= 0 or pr.Offset ~= 0 or pt.Offset ~= 0 or pb.Offset ~= 0) then
					n.pad += 1
					table.insert(edits, function()
						x.PaddingLeft = UDim.new(pl.Scale + pl.Offset / w, 0)
						x.PaddingRight = UDim.new(pr.Scale + pr.Offset / w, 0)
						x.PaddingTop = UDim.new(pt.Scale + pt.Offset / h, 0)
						x.PaddingBottom = UDim.new(pb.Scale + pb.Offset / h, 0)
					end)
				end
			end
		elseif x:IsA("UIListLayout") then
			local own = c.Parent :: any
			local pd = x.Padding
			if pd.Offset ~= 0 and own and own:IsA("GuiObject") and not own:IsA("ScrollingFrame") and not autoAncestor(x, screen)
				and (own :: GuiObject).AutomaticSize == Enum.AutomaticSize.None then
				local axis = if x.FillDirection == Enum.FillDirection.Vertical then own.AbsoluteSize.Y else own.AbsoluteSize.X
				if axis > 0 then
					n.list += 1
					table.insert(edits, function() x.Padding = UDim.new(pd.Scale + pd.Offset / axis, 0) end)
				end
			end
		elseif x:IsA("UIGridLayout") then
			local own = c.Parent :: any
			local cs, cp = x.CellSize, x.CellPadding
			if own and own:IsA("GuiObject") and not own:IsA("ScrollingFrame") and not autoAncestor(x, screen)
				and (own :: GuiObject).AutomaticSize == Enum.AutomaticSize.None
				and (cs.X.Offset ~= 0 or cs.Y.Offset ~= 0 or cp.X.Offset ~= 0 or cp.Y.Offset ~= 0) then
				local w, h = own.AbsoluteSize.X, own.AbsoluteSize.Y
				if w > 0 and h > 0 then
					n.grid += 1
					local pure = cs.X.Scale == 0 and cs.Y.Scale == 0 and cs.X.Offset > 0 and cs.Y.Offset > 0
					table.insert(edits, function()
						x.CellSize = UDim2.new(cs.X.Scale + cs.X.Offset / w, 0, cs.Y.Scale + cs.Y.Offset / h, 0)
						x.CellPadding = UDim2.new(cp.X.Scale + cp.X.Offset / w, 0, cp.Y.Scale + cp.Y.Offset / h, 0)
						if pure and x:FindFirstChildOfClass("UIAspectRatioConstraint") == nil then
							local a = Instance.new("UIAspectRatioConstraint")
							a.Name = "AD_Aspect"
							a.AspectRatio = cs.X.Offset / cs.Y.Offset
							a.Parent = x
						end
					end)
				end
			end
		end
	end)
	if not ok then
		probe:Destroy()
		return screenName .. ": tree mismatch between the screen and its layout clone -- NOT converted"
	end

	local summary = string.format("%s: size %d, pos %d (+aspect %d), corner %d, pad %d, list %d, grid %d, text %d | kept offset: in list/grid %d, under auto-size %d, templates %d",
		screenName, n.size, n.pos, n.aspect, n.corner, n.pad, n.list, n.grid, n.text, n.keptScroll, n.keptAuto, n.keptTpl)
	if o.dry then
		probe:Destroy()
		return "[dry] " .. summary
	end

	-- back up, convert, verify at 1080p
	local SS = game:GetService("ServerStorage")
	local bk = SS:FindFirstChild("_UIBackup_B131") or Instance.new("Folder")
	bk.Name = "_UIBackup_B131"
	bk.Parent = SS
	if bk:FindFirstChild(screenName) == nil then
		local copy = screen:Clone()
		copy.Parent = bk
	end
	for _, e in ipairs(edits) do e() end
	probe:Destroy()
	local probe2, stage2 = stageFor(screen)
	settle()
	local after = rects(stage2)
	probe2:Destroy()
	local moved = {}
	for key, r0 in pairs(before) do
		local r1 = after[key]
		if r1 and r0[1].X > -1e8 then
			local dp = (r1[1] - r0[1]).Magnitude
			local ds = (r1[2] - r0[2]).Magnitude
			if dp > TOL or ds > TOL then
				table.insert(moved, string.format("  %s moved %.1f / resized %.1f px", key, dp, ds))
			end
		end
	end
	table.sort(moved)
	local tail = if #moved == 0 then "  1080p check: nothing moved" else string.format("  1080p check: %d element(s) changed:\n%s", #moved, table.concat(moved, "\n", 1, math.min(#moved, 25)))
	return summary .. "\n" .. tail
end

function Conv.RunAll(opts: any?): string
	local out = {}
	for _, s in ipairs(game:GetService("StarterGui"):GetChildren()) do
		if s:IsA("ScreenGui") and not SKIP[s.Name] and not s.Name:find("Retired") then
			local ok, r = pcall(Conv.Run, s.Name, opts)
			table.insert(out, if ok then r else (s.Name .. ": ERROR " .. tostring(r)))
		end
	end
	return table.concat(out, "\n")
end

function Conv.Restore(screenName: string): string
	local bk = game:GetService("ServerStorage"):FindFirstChild("_UIBackup_B131")
	local copy = bk and bk:FindFirstChild(screenName)
	if not copy then return "no backup for " .. screenName end
	local SG = game:GetService("StarterGui")
	local cur = SG:FindFirstChild(screenName)
	local fresh = copy:Clone()
	if cur then cur:Destroy() end
	fresh.Parent = SG
	return screenName .. " restored from _UIBackup_B131"
end

return Conv
