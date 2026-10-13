-- hotbar_hover_fix.luau (B150) -- run with execute_luau in EACH Place (Edit): the Hotbar hover card is the user's
-- authored `StarterGui.Hotbar.UnitHoverPreviewTemplate`, identical in the Game and the Lobby.
-- User: "Fix overlapping in the hotbar hover card ... theres also cases when all 4 pills are present, it overflows"
-- + "If an item or something has an icon, display it beside the pill".
--   * UnitInfoFrame's vertical list added up to 108% (name 0.18 + tier 0.10 + stats 0.70 + 2 x 0.05 padding), so the
--     stats ran into the pill row -> Stats is 0.62; each row's ActualStats hung 8.7% past the right edge -> 1.0.
--   * every pill gets an `Icon` (Trait's TraitIcon moves INSIDE the pill -- it sat outside its left edge) and a
--     UIFlexItem (Shrink): pills keep their width when there is room and shrink together when all four show.
-- UIKit.Hotbar (ea2e37f5) fills the icons and hides empty pills. Backup: ServerStorage._UIBackup_B150.

local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")

local tpl = SG:FindFirstChild("Hotbar") and SG.Hotbar:FindFirstChild("UnitHoverPreviewTemplate", true)
assert(tpl, "Hotbar.UnitHoverPreviewTemplate missing")
local bk = SS:FindFirstChild("_UIBackup_B150") or Instance.new("Folder")
bk.Name = "_UIBackup_B150"
bk.Parent = SS
if not bk:FindFirstChild("UnitHoverPreviewTemplate") then tpl:Clone().Parent = bk end

-- 1) the info column fits its frame
local info = tpl:FindFirstChild("UnitInfoFrame")
local stats = info and info:FindFirstChild("Stats")
if stats then stats.Size = UDim2.fromScale(1, 0.62) end
for _, row in ipairs(stats and stats:GetChildren() or {}) do
	local actual = row:FindFirstChild("ActualStats")
	if actual and actual:IsA("GuiObject") then
		actual.AnchorPoint = Vector2.new(1, 0.5)
		actual.Position = UDim2.fromScale(1, 0.5)
		actual.Size = UDim2.fromScale(0.68, 1)
	end
end

-- 2) pills: an icon inside each, and a row that shrinks to fit
local chips = tpl:FindFirstChild("ElementsTraitsFrame")
for _, chip in ipairs(chips and chips:GetChildren() or {}) do
	if chip:IsA("Frame") then
		chip.Size = UDim2.fromScale(0.3, chip.Size.Y.Scale)
		local flex = chip:FindFirstChildOfClass("UIFlexItem") or Instance.new("UIFlexItem")
		flex.FlexMode = Enum.UIFlexMode.Shrink
		flex.Parent = chip
		local icon = chip:FindFirstChild("TraitIcon") or chip:FindFirstChild("Icon")
		if chip.Name ~= "Shiny" then
			if not icon then
				icon = Instance.new("ImageLabel")
				icon.Name = "Icon"
				icon.Image = ""
				icon.Parent = chip
				local a = Instance.new("UIAspectRatioConstraint")
				a.AspectRatio = 1
				a.DominantAxis = Enum.DominantAxis.Height
				a.Parent = icon
			end
			icon.BackgroundTransparency = 1
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.Position = UDim2.fromScale(0.06, 0.5)
			icon.Size = UDim2.fromScale(3, 0.78)
			icon.ScaleType = Enum.ScaleType.Fit
			icon.ZIndex = 3
			icon.Visible = false
			local asp = icon:FindFirstChildOfClass("UIAspectRatioConstraint")
			if asp then asp.DominantAxis = Enum.DominantAxis.Height end
		end
	end
end
local lay = chips and chips:FindFirstChildOfClass("UIListLayout")
if lay then lay.VerticalAlignment = Enum.VerticalAlignment.Center end

return "hotbar hover card fixed"
