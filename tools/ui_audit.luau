--!strict
-- tools/ui_audit.luau (B127) -- the ALL-DEVICES LAYOUT AUDIT, as a module.
-- Deployed as ServerStorage.DevTools.UIAudit in each Place. Usage via execute_luau (Edit):
--   return require(game.ServerStorage.DevTools.UIAudit:Clone()).Run({ only = nil, hud = {...} })
-- Lays every StarterGui screen out at real device sizes (clones into a fixed-size frame, so scale / offset /
-- aspect / size constraints / list layouts resolve exactly as on that device) and reports:
--   OFF   an element sticking out of the screen by > 3px (authored-visible elements only)
--   CLIP  fixed-size text that does not fit its box (TextFits = false, not wrapped)
--   TINY  scaled text whose box is under MIN_TEXT_PX tall at that size (before the B127 phone boost)
--   TOP   a screen-level element under Roblox's top-bar buttons (IgnoreGuiInset screens, top-left 170x58)
--   OVER  two HUD elements (from opts.hud, across screens) overlapping each other
-- Not reported (by design): panels PARKED off-screen for a slide-in (authored X.Scale >= 1 or <= -0.5),
-- full-screen dims / scrims (>= 90% of the screen), elements authored at exactly 0,0 (positioned at
-- runtime: tooltips, hover cards), `*Template*` / `*Retired*` objects, ScrollingFrame contents, SKIP screens.
-- Screens are audited as if OPEN: Enabled is ignored and each screen's top-level children are forced visible.
-- Nothing in StarterGui is modified; the probe is destroyed before returning.

local Audit = {}

local DEVICES = {
	{ "phone-SE", 667, 375 }, { "phone-14", 844, 390 }, { "tablet", 1024, 768 }, { "laptop", 1366, 768 },
	{ "1080p", 1920, 1080 }, { "1440p", 2560, 1440 }, { "ultrawide", 2560, 1080 },
}
local MIN_TEXT_PX = 9
local TOPBAR_H, TOPBAR_L = 58, 170
local SKIP = { AdminPanel = true, AdminBroadcastGUI = true, Freecam = true, ScreenFXLayer = true, LoadingScreen = true, _PhonePreview = true, _UIAuditProbe = true }

local function skipName(n: string): boolean
	return n:find("Template") ~= nil or n:find("Retired") ~= nil
end

function Audit.Run(opts: any?): string
	local o = opts or {}
	local only: string? = o.only
	local hudSet: { [string]: boolean } = {}
	for _, p in ipairs(o.hud or {}) do hudSet[p] = true end
	local devices = o.devices or DEVICES
	local SG = game:GetService("StarterGui")
	local RunService = game:GetService("RunService")
	local probe = Instance.new("ScreenGui")
	probe.Name = "_UIAuditProbe"
	probe.IgnoreGuiInset = true
	probe.Parent = SG
	local report: { [string]: { string } } = {}
	local seen: { [string]: boolean } = {}
	local function add(dev: string, line: string)
		if seen[dev .. line] then return end
		seen[dev .. line] = true
		report[dev] = report[dev] or {}
		table.insert(report[dev], line)
	end
	local function rel(root: Instance, x: Instance): string
		local parts = {}
		local n: Instance? = x
		while n and n ~= root do
			table.insert(parts, 1, n.Name)
			n = n.Parent
		end
		return table.concat(parts, ".")
	end
	local function shown(x: GuiObject, stage: Instance): boolean
		local n: Instance? = x
		while n and n ~= stage do
			if n:IsA("GuiObject") and not (n :: GuiObject).Visible then return false end
			if n:IsA("ScrollingFrame") and n ~= x then return false end
			if skipName(n.Name) then return false end
			n = n.Parent
		end
		return true
	end
	for _, dev in ipairs(devices) do
		local name, W, H = dev[1], dev[2], dev[3]
		local hudBoxes = {}
		for _, screen in ipairs(SG:GetChildren()) do
			if screen:IsA("ScreenGui") and not SKIP[screen.Name] and not skipName(screen.Name)
				and (only == nil or screen.Name == only) then
				local stage = Instance.new("Frame")
				stage.Name = screen.Name
				stage.Size = UDim2.fromOffset(W, H)
				stage.BackgroundTransparency = 1
				stage.Parent = probe
				for _, c in ipairs(screen:GetChildren()) do
					if not c:IsA("LuaSourceContainer") then
						local ok, cl = pcall(function() return c:Clone() end)
						if ok and cl then
							for _, d in ipairs(cl:GetDescendants()) do
								if d:IsA("LuaSourceContainer") then d:Destroy() end
							end
							if cl:IsA("GuiObject") and not skipName(cl.Name) then (cl :: GuiObject).Visible = true end
							cl.Parent = stage
						end
					end
				end
				RunService.Heartbeat:Wait()
				RunService.Heartbeat:Wait()
				for _, d in ipairs(stage:GetDescendants()) do
					if d:IsA("GuiObject") and shown(d, stage) then
						local g = d :: GuiObject
						local p, s = g.AbsolutePosition - stage.AbsolutePosition, g.AbsoluteSize
						local path = screen.Name .. "." .. rel(stage, g)
						local parked = g.Position.X.Scale >= 1 or g.Position.X.Scale <= -0.5
						local fullScreen = s.X * s.Y >= W * H * 0.9
						local atOrigin = g.Parent == stage and g.Position == UDim2.new() and g.AnchorPoint == Vector2.zero and not fullScreen
						if s.X > 2 and s.Y > 2 and not parked and not atOrigin then
							local out = math.max(-p.X, -p.Y, p.X + s.X - W, p.Y + s.Y - H)
							if out > 3 then
								local par = g.Parent :: any
								local parOut = 0
								if par and par:IsA("GuiObject") and par ~= stage then
									local pp, ps = par.AbsolutePosition - stage.AbsolutePosition, par.AbsoluteSize
									parOut = math.max(-pp.X, -pp.Y, pp.X + ps.X - W, pp.Y + ps.Y - H)
								end
								if parOut <= 3 and not (par and par:IsA("GuiObject") and (par.Position.X.Scale >= 1 or par.Position.X.Scale <= -0.5)) then
									add(name, string.format("OFF  %s  by %dpx  (rect %d,%d %dx%d)", path, math.floor(out), p.X, p.Y, s.X, s.Y))
								end
							end
						end
						if (g:IsA("TextLabel") or g:IsA("TextButton") or g:IsA("TextBox")) and (g :: any).Text ~= "" and (g :: any).TextTransparency < 1 then
							local t = g :: any
							if t.TextScaled then
								if s.Y > 0 and s.Y < MIN_TEXT_PX then
									add(name, string.format("TINY %s  %dpx tall '%s'", path, s.Y, string.sub(t.Text, 1, 24)))
								end
							elseif not t.TextFits and not t.TextWrapped then
								add(name, string.format("CLIP %s  size %d in %dx%d '%s'", path, t.TextSize, s.X, s.Y, string.sub(t.Text, 1, 24)))
							end
						end
						if screen.IgnoreGuiInset and g.Parent == stage and not fullScreen and not atOrigin and not parked
							and p.Y < TOPBAR_H and p.X < TOPBAR_L and s.X > 2 then
							add(name, string.format("TOP  %s under the Roblox top-bar buttons (rect %d,%d %dx%d)", path, p.X, p.Y, s.X, s.Y))
						end
						local key = screen.Name .. "." .. rel(stage, g)
						if hudSet[key] then
							table.insert(hudBoxes, { path = key, p = p, s = s })
						end
					end
				end
				stage:Destroy()
			end
		end
		for i = 1, #hudBoxes do
			for j = i + 1, #hudBoxes do
				local a, b = hudBoxes[i], hudBoxes[j]
				local ox = math.min(a.p.X + a.s.X, b.p.X + b.s.X) - math.max(a.p.X, b.p.X)
				local oy = math.min(a.p.Y + a.s.Y, b.p.Y + b.s.Y) - math.max(a.p.Y, b.p.Y)
				if ox > 4 and oy > 4 then
					add(name, string.format("OVER %s  x  %s  (%dx%dpx)", a.path, b.path, math.floor(ox), math.floor(oy)))
				end
			end
		end
	end
	probe:Destroy()
	local out = {}
	for _, dev in ipairs(devices) do
		local lines = report[dev[1]]
		if lines then
			table.sort(lines)
			table.insert(out, string.format("===== %s (%dx%d): %d issue(s)", dev[1], dev[2], dev[3], #lines))
			for _, l in ipairs(lines) do table.insert(out, l) end
		end
	end
	return if #out == 0 then "no issues" else table.concat(out, "\n")
end

return Audit
