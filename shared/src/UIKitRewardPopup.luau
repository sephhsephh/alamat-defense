--!strict
-- UIKit.RewardPopup - reusable "here is what you got" popup (AD-UI kit, blueprint section 5)
-- Dark overlay + a grid of reward cards cloned from RewardItemTemplate. The DESIGN lives on
-- ReplicatedStorage.UITemplates.Kit.RewardPopup - edit it in Studio; this module only clones,
-- fills and wires. It never builds UI.
--
-- Rewards are described by CATALOG ID, so the popup needs no per-caller art or naming logic:
-- name, tier and icon all come from the shared ItemCatalog + TierConfig, exactly like the
-- Items screen. An id that is not in the catalog still renders (falling back to the id itself
-- and Common) rather than erroring - a reward the player earned must never fail to display.
--
-- Expected instance shape (every part optional; missing parts degrade gracefully):
--   RewardPopup (Frame, Visible=false, full-screen)
--   |-- Overlay (TextButton)      dark scrim; clicking it closes
--   `-- Panel (Frame)
--        |-- Title / Subtitle (TextLabel)
--        |-- Grid (ScrollingFrame) -- RewardItemTemplate (Frame, Visible=false)
--        |                            |-- IconImage / NameLabel / QtyLabel
--        |                            `-- UIStrokeWithGradient  (tier border)
--        `-- CloseButton (GuiButton) [tagged UIKitButton]
--
-- Usage:
--   local RewardPopup = require(ReplicatedStorage.Shared.UIKit.RewardPopup)
--   local handle = RewardPopup.create(someScreenGui)
--   handle.show({ { Id = "Gold", Qty = 250 }, { Id = "BannerTicket", Qty = 2 } },
--               { Title = "VICTORY", Subtitle = "Stage 1 - Act 1" })
--   handle.onClosed(function() ... end)

local RS = game:GetService("ReplicatedStorage")

local meta = RS:WaitForChild("Configs"):WaitForChild("Meta")
local ItemCatalog = require(meta:WaitForChild("ItemCatalog"))
local TierConfig = require(meta:WaitForChild("TierConfig"))

local RewardPopup = {}

local TEMPLATE_PATHS = {
	{ "ReplicatedStorage", "UITemplates", "Kit", "RewardPopup" },
	{ "ReplicatedStorage", "Shared", "UIKit", "Templates", "RewardPopup" },
}

local PLACEHOLDER = "rbxasset://textures/ui/GuiImagePlaceholder.png"

local function resolveTemplate(): GuiObject?
	for _, path in ipairs(TEMPLATE_PATHS) do
		local node: Instance? = game
		for _, seg in ipairs(path) do
			node = node and node:FindFirstChild(seg)
		end
		if node and node:IsA("GuiObject") then return node end
	end
	return nil
end

local function imageFor(id: string): string
	local entry = ItemCatalog.Get(id)
	local icon = entry and entry.Icon
	if type(icon) == "table" and type(icon.Image) == "string" then
		local img = icon.Image
		if img ~= "" and img ~= "rbxassetid://0" then return img end
	end
	return PLACEHOLDER
end

local function setText(root: Instance, name: string, value: string)
	local l = root:FindFirstChild(name)
	if l and l:IsA("TextLabel") then l.Text = value end
end

-- Attach behaviour to an existing RewardPopup instance. Returns a handle.
function RewardPopup.attach(popup: GuiObject)
	assert(popup, "UIKit.RewardPopup.attach: popup is nil")
	local panel = popup:WaitForChild("Panel")
	local grid = panel:WaitForChild("Grid")
	local itemTemplate = grid:WaitForChild("RewardItemTemplate")
	-- Take the design out of the layout so it is never a stray cell.
	itemTemplate.Parent = script

	local overlay = popup:FindFirstChild("Overlay")
	local closeButton = panel:FindFirstChild("CloseButton")
	local closedCallbacks: { () -> () } = {}
	local cards: { GuiObject } = {}

	local handle = {}
	handle.instance = popup

	local function clear()
		for _, c in ipairs(cards) do c:Destroy() end
		table.clear(cards)
	end

	function handle.hide()
		popup.Visible = false
		for _, f in ipairs(closedCallbacks) do task.spawn(f) end
	end

	-- rewards: { { Id = catalogId, Qty = number? } } (a bare string id is also accepted)
	function handle.show(rewards: { any }, opts: { [string]: any }?)
		clear()
		opts = opts or {}
		setText(panel, "Title", (opts :: any).Title or "REWARDS")
		setText(panel, "Subtitle", (opts :: any).Subtitle or "")

		for i, reward in ipairs(rewards or {}) do
			local id = (type(reward) == "table") and tostring(reward.Id) or tostring(reward)
			local qty = (type(reward) == "table") and reward.Qty or 1
			local card = itemTemplate:Clone()
			card.Name = "Reward_" .. id
			card.Visible = true
			card.LayoutOrder = i

			setText(card, "NameLabel", ItemCatalog.GetName(id))
			setText(card, "QtyLabel", "x" .. tostring(qty or 1))
			local icon = card:FindFirstChild("IconImage")
			if icon and icon:IsA("ImageLabel") then icon.Image = imageFor(id) end

			-- Tier border, same treatment as every other card in the kit.
			local stroke = card:FindFirstChild("UIStrokeWithGradient", true)
			if stroke and stroke:IsA("UIStroke") then
				local g = stroke:FindFirstChildOfClass("UIGradient")
				if not g then g = Instance.new("UIGradient"); g.Parent = stroke end
				g.Color = TierConfig.seamlessSequence(ItemCatalog.GetTier(id))
			end

			card.Parent = grid
			table.insert(cards, card)
		end

		popup.Visible = true
	end

	function handle.onClosed(fn: () -> ()): () -> ()
		table.insert(closedCallbacks, fn)
		return function()
			local i = table.find(closedCallbacks, fn)
			if i then table.remove(closedCallbacks, i) end
		end
	end
	function handle.count(): number
		return #cards
	end
	function handle.destroy()
		clear()
		popup:Destroy()
	end

	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(handle.hide)
	end
	if overlay and overlay:IsA("GuiButton") then
		overlay.Activated:Connect(handle.hide)
	end

	popup.Visible = false
	return handle
end

-- Clone the kit template and attach behaviour. Returns the same handle as attach().
function RewardPopup.create(parent: Instance)
	local template = resolveTemplate()
	assert(template, "UIKit.RewardPopup.create: no RewardPopup template found in " ..
		"ReplicatedStorage.UITemplates.Kit / Shared.UIKit.Templates")
	local clone = template:Clone()
	clone.Parent = parent
	return RewardPopup.attach(clone)
end

return RewardPopup
