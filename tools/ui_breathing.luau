-- tools/ui_breathing.luau (B115) -- the SPACING PASS (user: "objects / texts too clamped ... use paddings properly").
-- Run via execute_luau in Edit mode, in EACH Place. Set DRY_RUN = true first to see what it would change.
-- Rules (8pt-grid practice: internal space <= external space, consistent rhythm):
--   1. STACKED TEXT: two text elements stacked vertically in the same parent with < MIN_V of the parent's
--      height between them get pulled apart to MIN_V, each giving up half (its far edge stays put).
--   2. SIDE-BY-SIDE TEXT: two text elements side by side with < MIN_H of the parent's width between them
--      get pulled apart to MIN_H the same way.
--   3. BUTTON INSET: a real button (<= 3 children, all text) whose text starts at its very edge gets a
--      UIPadding (6% / 10%).
-- Only scale-positioned elements (Offset 0) are touched, only TextScaled text is resized (a fixed TextSize
-- label is never shrunk), layouts (UIListLayout/UIGridLayout) are left alone, and so are the Hotbar
-- (user rule: never touch it), admin/dev tools and *_Retired screens. Marks each changed instance with the
-- attribute B115Spaced so a re-run is a no-op.
local DRY_RUN = false
local MIN_V = 0.05   -- of the parent's height
local MIN_H = 0.03   -- of the parent's width
local SKIP = { Hotbar = true, AdminPanel = true, AdminBroadcastGUI = true, Freecam = true }

local log, changes = {}, 0
local function isText(o) return o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") end
local function pureScale(o)
	return o.Position.X.Offset == 0 and o.Position.Y.Offset == 0 and o.Size.X.Offset == 0 and o.Size.Y.Offset == 0
		and o.AutomaticSize == Enum.AutomaticSize.None
end
local function rect(o) -- in parent scale units
	local x = o.Position.X.Scale - o.AnchorPoint.X * o.Size.X.Scale
	local y = o.Position.Y.Scale - o.AnchorPoint.Y * o.Size.Y.Scale
	return x, y, x + o.Size.X.Scale, y + o.Size.Y.Scale
end
local function setRect(o, x0, y0, x1, y1)
	o.Size = UDim2.fromScale(x1 - x0, y1 - y0)
	o.Position = UDim2.fromScale(x0 + o.AnchorPoint.X * (x1 - x0), y0 + o.AnchorPoint.Y * (y1 - y0))
end
local function path(o) return (o:GetFullName():gsub("^StarterGui%.", "")) end

-- hand-tuned layouts this pass must not second-guess
local HAND_TUNED = { ["UnitManager.CardTemplate"] = true }
local function spaceParent(p)
	if p:FindFirstChildWhichIsA("UIGridStyleLayout") then return end
	for k in pairs(HAND_TUNED) do
		if string.find(path(p), k, 1, true) == 1 then return end
	end
	local kids = {}
	for _, c in ipairs(p:GetChildren()) do
		if isText(c) and c.TextScaled and pureScale(c) and c.Visible and not c:GetAttribute("B115Spaced") then
			table.insert(kids, c)
		end
	end
	for i = 1, #kids do
		for j = i + 1, #kids do
			local A, B = kids[i], kids[j]
			local ax0, ay0, ax1, ay1 = rect(A)
			local bx0, by0, bx1, by1 = rect(B)
			local overlapX = math.min(ax1, bx1) - math.max(ax0, bx0)
			local overlapY = math.min(ay1, by1) - math.max(ay0, by0)
			if overlapX > 0.02 then
				-- vertical neighbours
				local top, bot = A, B
				if by0 < ay0 then top, bot = B, A end
				local tx0, ty0, tx1, ty1 = rect(top)
				local bx0b, by0b, bx1b, by1b = rect(bot)
				local gap = by0b - ty1
				if gap > -0.08 and gap < MIN_V then
					local need = (MIN_V - gap) / 2
					if (ty1 - ty0) - need > 0.04 and (by1b - by0b) - need > 0.04 then
						table.insert(log, string.format("V %s: %s|%s gap %.3f -> %.3f", path(p), top.Name, bot.Name, gap, MIN_V))
						changes += 1
						if not DRY_RUN then
							setRect(top, tx0, ty0, tx1, ty1 - need)
							setRect(bot, bx0b, by0b + need, bx1b, by1b)
						end
					end
				end
			elseif overlapY > 0.02 then
				-- horizontal neighbours
				local left, right = A, B
				if bx0 < ax0 then left, right = B, A end
				local lx0, ly0, lx1, ly1 = rect(left)
				local rx0, ry0, rx1, ry1 = rect(right)
				local gap = rx0 - lx1
				if gap > -0.05 and gap < MIN_H then
					local need = (MIN_H - gap) / 2
					if (lx1 - lx0) - need > 0.06 and (rx1 - rx0) - need > 0.06 then
						table.insert(log, string.format("H %s: %s|%s gap %.3f -> %.3f", path(p), left.Name, right.Name, gap, MIN_H))
						changes += 1
						if not DRY_RUN then
							setRect(left, lx0, ly0, lx1 - need, ly1)
							setRect(right, rx0 + need, ry0, rx1, ry1)
						end
					end
				end
			end
		end
	end
end

local function insetButton(b)
	if b:FindFirstChildOfClass("UIPadding") or b:GetAttribute("B115Spaced") then return end
	-- only REAL buttons: at most 3 GuiObject children and all of them text. A big clickable container
	-- (a reveal overlay, a dialogue box, a card body) holds art that padding would shift.
	local gui = 0
	for _, c in ipairs(b:GetChildren()) do
		if c:IsA("GuiObject") then
			gui += 1
			if not isText(c) then return end
		end
	end
	if gui == 0 or gui > 3 then return end
	local touches = false
	for _, c in ipairs(b:GetChildren()) do
		if isText(c) and pureScale(c) and c.Visible then
			local x0, y0, x1, y1 = rect(c)
			if x0 < 0.03 or x1 > 0.97 or y0 < 0.03 or y1 > 0.97 then touches = true end
		end
	end
	if touches then
		table.insert(log, "P " .. path(b) .. ": UIPadding 6%/10%")
		changes += 1
		if not DRY_RUN then
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0.06, 0)
			pad.PaddingRight = UDim.new(0.06, 0)
			pad.PaddingTop = UDim.new(0.1, 0)
			pad.PaddingBottom = UDim.new(0.1, 0)
			pad.Parent = b
			b:SetAttribute("B115Spaced", true)
		end
	end
end

for _, g in ipairs(game:GetService("StarterGui"):GetChildren()) do
	if g:IsA("ScreenGui") and not SKIP[g.Name] and not g.Name:find("Retired") then
		for _, d in ipairs(g:GetDescendants()) do
			if d:IsA("GuiObject") and not d:GetFullName():find("Retired") then
				spaceParent(d)
				if d:IsA("GuiButton") then insetButton(d) end
			end
		end
	end
end
table.sort(log)
return (if DRY_RUN then "DRY RUN -- " else "") .. changes .. " change(s)\n" .. table.concat(log, "\n")
