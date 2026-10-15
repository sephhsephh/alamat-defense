-- tools/units_hall_reparent.luau (B160) -- run with execute_luau in EACH Place (Edit). Re-runnable.
-- User: "components should be parented to a frame they actually are in place with ... the stats frame consumes
-- whole screen when it should only be consuming the selected unit frame.BG's size."
-- Moves every Units-hall element into the frame it visually sits in, WITHOUT moving anything on screen
-- (each element's absolute rect is re-expressed in its new parent's scale space), then shrinks the old
-- full-screen layers to the area they actually cover:
--   RosterPanel <- SearchBar, FiltersButton, UnitsContainer, CapacityBar, UnequipAllButton, QuickSellButton,
--                  SellStatus, SellButtons
--   NavBar      <- Tabs, UN/EquipButton, TeamsButton
--   SelectedUnitFrame.BG (the info panel) <- Stats (now exactly BG's size), ActionRail, Divider, PassivesPanel,
--                  UpgradePath, UpgradesPage, TraitPage, the hall's CloseButton
--   SelectedUnitFrame -> shrunk to the union of the stage + info panel; the empty `Top` layer is removed.
-- Verifies every GuiObject's on-screen rect before/after (prints any that moved more than 1 px).
-- Backup: ServerStorage._UIBackup_B160.UnitsGUI. The layout itself is the USER's (Studio) -- never re-lay it here.
local SS = game:GetService("ServerStorage")
local gui = game:GetService("StarterGui"):WaitForChild("UnitsGUI")
local main = gui:WaitForChild("Main")
local bottom = main:WaitForChild("Bottom")
local sel = bottom:WaitForChild("SelectedUnitFrame")
local bg = sel:WaitForChild("BG")
local roster = bottom:WaitForChild("RosterPanel")
local nav = bottom:WaitForChild("NavBar")
local top = main:FindFirstChild("Top")

local bk = SS:FindFirstChild("_UIBackup_B160") or Instance.new("Folder")
bk.Name = "_UIBackup_B160"
bk.Parent = SS
if not bk:FindFirstChild("UnitsGUI") then gui:Clone().Parent = bk end

-- every GuiObject's absolute rect, keyed by the object itself
local function snapshot(): { [Instance]: { Vector2 } }
	local t = {}
	for _, d in ipairs(main:GetDescendants()) do
		if d:IsA("GuiObject") then t[d] = { d.AbsolutePosition, d.AbsoluteSize } end
	end
	return t
end

-- the axis bases a size is measured against (SizeConstraint)
local function bases(o: GuiObject, parentSize: Vector2): (number, number)
	local sc = o.SizeConstraint
	if sc == Enum.SizeConstraint.RelativeXX then return parentSize.X, parentSize.X end
	if sc == Enum.SizeConstraint.RelativeYY then return parentSize.Y, parentSize.Y end
	return parentSize.X, parentSize.Y
end

-- Re-express `o` (scale-only) for a parent whose rect changes from (op, os) to (np, ns); same on-screen rect.
local function rebase(o: GuiObject, op: Vector2, os: Vector2, np: Vector2, ns: Vector2)
	local p, s = o.Position, o.Size
	local anchorAbs = Vector2.new(op.X + p.X.Scale * os.X + p.X.Offset, op.Y + p.Y.Scale * os.Y + p.Y.Offset)
	o.Position = UDim2.fromScale((anchorAbs.X - np.X) / ns.X, (anchorAbs.Y - np.Y) / ns.Y)
	local obx, oby = bases(o, os)
	local nbx, nby = bases(o, ns)
	o.Size = UDim2.fromScale((s.X.Scale * obx + s.X.Offset) / nbx, (s.Y.Scale * oby + s.Y.Offset) / nby)
end

-- Move `o` under `newParent` keeping its rect.
local function move(o: GuiObject?, newParent: GuiObject)
	if not o or o.Parent == newParent then return end
	local old = o.Parent :: GuiObject
	rebase(o, old.AbsolutePosition, old.AbsoluteSize, newParent.AbsolutePosition, newParent.AbsoluteSize)
	o.Parent = newParent
end

-- Give container `c` the rect (np, ns) [absolute], keeping every child where it is.
local function refit(c: GuiObject, np: Vector2, ns: Vector2)
	local op, os = c.AbsolutePosition, c.AbsoluteSize
	local par = c.Parent :: GuiObject
	for _, ch in ipairs(c:GetChildren()) do
		if ch:IsA("GuiObject") then rebase(ch, op, os, np, ns) end
	end
	local pp, ps = par.AbsolutePosition, par.AbsoluteSize
	local ap = c.AnchorPoint
	c.Position = UDim2.fromScale((np.X + ap.X * ns.X - pp.X) / ps.X, (np.Y + ap.Y * ns.Y - pp.Y) / ps.Y)
	local bx, by = bases(c, ps)
	c.Size = UDim2.fromScale(ns.X / bx, ns.Y / by)
end

local before = snapshot()

for _, n in ipairs({ "SearchBar", "FiltersButton" }) do move(top and top:FindFirstChild(n) :: GuiObject?, roster) end
move(top and top:FindFirstChild("CloseButton") :: GuiObject?, bg)
for _, n in ipairs({ "UnitsContainer", "CapacityBar", "UnequipAllButton", "QuickSellButton", "SellStatus", "SellButtons" }) do
	move(bottom:FindFirstChild(n) :: GuiObject?, roster)
end
for _, n in ipairs({ "Tabs", "UN/EquipButton", "TeamsButton" }) do move(bottom:FindFirstChild(n) :: GuiObject?, nav) end
move(bottom:FindFirstChild("ActionRail") :: GuiObject?, bg)
for _, n in ipairs({ "Stats", "Divider", "PassivesPanel", "UpgradePath", "UpgradesPage", "TraitPage" }) do
	move(sel:FindFirstChild(n) :: GuiObject?, bg)
end

-- Stats: exactly the info panel's size
local stats = bg:FindFirstChild("Stats") :: GuiObject?
if stats then refit(stats, bg.AbsolutePosition, bg.AbsoluteSize) end

-- SelectedUnitFrame: the union of what it holds (stage column + info panel), not the whole screen
local lo, hi = Vector2.new(math.huge, math.huge), Vector2.new(-math.huge, -math.huge)
for _, ch in ipairs(sel:GetChildren()) do
	if ch:IsA("GuiObject") then
		lo = Vector2.new(math.min(lo.X, ch.AbsolutePosition.X), math.min(lo.Y, ch.AbsolutePosition.Y))
		local e = ch.AbsolutePosition + ch.AbsoluteSize
		hi = Vector2.new(math.max(hi.X, e.X), math.max(hi.Y, e.Y))
	end
end
if lo.X < hi.X then refit(sel, lo, hi - lo) end

-- the old full-screen `Top` layer is empty now
if top and #top:GetChildren() == 0 then top:Destroy() end

-- the B155/B156 runtime re-layout data is retired (B160: the layout is authored in Studio, never by a script)
for _, d in ipairs(gui:GetDescendants()) do
	for _, a in ipairs({ "PcPos", "PcSize", "MobPos", "MobSize", "PcCardWidth", "MobCardWidth" }) do
		if d:GetAttribute(a) ~= nil then d:SetAttribute(a, nil) end
	end
end

task.wait() -- let the absolute rects settle
local moved = {}
for o, r in pairs(before) do
	if o.Parent then
		local dp = (o.AbsolutePosition - r[1]).Magnitude
		local ds = (o.AbsoluteSize - r[2]).Magnitude
		if dp > 1 or ds > 1 then table.insert(moved, string.format("%s dPos=%.1f dSize=%.1f", o:GetFullName(), dp, ds)) end
	end
end
return string.format("reparented; %d GuiObjects checked, %d moved >1px%s", #(function() local t = {} for k in pairs(before) do table.insert(t, k) end return t end)(), #moved,
	#moved > 0 and ("\n" .. table.concat(moved, "\n", 1, math.min(#moved, 30))) or "")
