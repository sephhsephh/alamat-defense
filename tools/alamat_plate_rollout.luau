-- tools/alamat_plate_rollout.luau (B151) -- run with execute_luau in a Place (Edit): converts that Place's rectangle
-- ACTION buttons to the universal Alamat Plate (ServerStorage.DevTools.AlamatPlate) in one go, with a theme picked
-- by intent: Gold = primary / confirm, Jade = claim, Ruby = destructive (sell, discard, disband, decline),
-- Stone = secondary (cancel, back, reset, filters, min/max), Violet = summon / special, Azure = navigation,
-- Ember = events. Buttons whose colour a script sets at runtime (claim green / incomplete grey ...) keep working:
-- the plate's colour IS the button's BackgroundColor3. Backups: ServerStorage._UIBackup_B151.<ScreenGui>.
-- NOT converted on purpose: rows / chips / tabs / filter toggles / grade grids / page + category templates / icon-only
-- rail + close buttons / the HUD Sun-gems / the confirm popup (its own Alamat design) / dev panels.
-- Paths are relative to StarterGui; a missing path is reported, never fatal (the two Places share one list).

local P = require(game:GetService("ServerStorage").DevTools.AlamatPlate:Clone())
local SG = game:GetService("StarterGui")
local SS = game:GetService("ServerStorage")

local LIST: { { string } } = {
	-- Units (Lobby + the Game's loadout copy)
	{ "UnitsGUI.Main.Bottom.UN/EquipButton", "Gold" }, { "UnitsGUI.Main.Bottom.UnequipAllButton", "Stone" },
	{ "UnitsGUI.Main.Bottom.TeamsButton", "Violet" }, { "UnitsGUI.Main.Bottom.QuickSellButton", "Ruby" },
	{ "UnitsGUI.Main.Bottom.SellButtons.SellButton", "Ruby" }, { "UnitsGUI.Main.Bottom.SellButtons.CancelButton", "Stone" },
	{ "UnitsGUI.Main.Bottom.SellButtons.ClearSelectionButton", "Stone" }, { "UnitsGUI.Main.Bottom.SellButtons.SelectAllByRarityButton", "Azure" },
	{ "UnitsGUI.Main.Top.FiltersButton", "Stone" }, { "UnitsGUI.Main.Bottom.SelectedUnitFrame.Stats.MoreStatsButton", "Night" },
	{ "UnitsGUI.FeedAmountPopup.ApplyButton", "Gold" }, { "UnitsGUI.FeedAmountPopup.CancelButton", "Stone" },
	{ "UnitsGUI.FeedAmountPopup.Presets.HalfButton", "Stone" }, { "UnitsGUI.FeedAmountPopup.Presets.MaxButton", "Stone" },
	{ "UnitsGUI.FeedAmountPopup.Presets.MinButton", "Stone" }, { "UnitsGUI.FeedPopup.List.RowTemplate.FeedAmountButton", "Azure" },
	{ "UnitsGUI.FeedPopup.List.RowTemplate.FeedMaxButton", "Gold" }, { "UnitsGUI.FilterSelectPopup.Footer.ApplyButton", "Gold" },
	{ "UnitsGUI.FilterSelectPopup.Footer.ResetButton", "Stone" }, { "UnitsGUI.TeamsPopup.List.TeamTemplate.LoadButton", "Gold" },
	{ "UnitsGUI.TeamsPopup.List.TeamTemplate.SaveButton", "Azure" },
	-- Quests / Achievements
	{ "QuestsGUI.Window.Detail.ClaimButton", "Jade" }, { "QuestsGUI.Window.Tabs.ClaimAllButton", "Jade" },
	{ "QuestsGUI.Window.AchievementsButton", "Azure" }, { "QuestsGUI.Window.FilterPopup.DoneButton", "Gold" },
	{ "QuestsGUI.Window.FilterPopup.ResetButton", "Stone" }, { "AchievementsGUI.Window.QuestsButton", "Azure" },
	{ "AchievementsGUI.Window.Sidebar.ClaimAllButton", "Jade" },
	-- Silver shop
	{ "SilverShopGUI.Main.Grid.CardTemplate.BuyButton", "Gold" }, { "SilverShopGUI.Main.Grid.CardTemplate.QtyRow.MaxButton", "Stone" },
	{ "SilverShopGUI.Main.Grid.CardTemplate.QtyRow.MinButton", "Stone" }, { "SilverShopGUI.Main.MultiBar.Buttons.ConfirmButton", "Gold" },
	{ "SilverShopGUI.Main.MultiBar.Buttons.ExitButton", "Stone" }, { "SilverShopGUI.Main.MultiBar.Buttons.SelectAllButton", "Azure" },
	{ "SilverShopGUI.AmountPopup.ApplyButton", "Gold" }, { "SilverShopGUI.AmountPopup.CancelButton", "Stone" },
	{ "SilverShopGUI.AmountPopup.Presets.HalfButton", "Stone" }, { "SilverShopGUI.AmountPopup.Presets.MaxButton", "Stone" },
	{ "SilverShopGUI.AmountPopup.Presets.MinButton", "Stone" }, { "SilverShopGUI.ChoicePopup.BuyAmountButton", "Azure" },
	{ "SilverShopGUI.ChoicePopup.BuyMaxButton", "Gold" }, { "SilverShopGUI.Packs.PackTemplate.BuyButton", "Jade" },
	-- Summon
	{ "SummonGUI.Main.Root.Dock.ActionRow.SummonOneButton", "Violet" }, { "SummonGUI.Main.Root.Dock.ActionRow.SummonManyButton", "Gold" },
	{ "SummonGUI.Main.Root.Dock.ActionRow.AutoSellButton", "Stone" }, { "SummonGUI.Main.Root.Dock.ActionRow.InfoButton", "Azure" },
	{ "SummonGUI.Main.Root.Dock.ActionRow.ShowChancesButton", "Azure" }, { "SummonGUI.Main.Root.Stage.ChooseButton", "Gold" },
	{ "SummonGUI.Main.InfoPopup.Card.BuyShinyHunterButton", "Jade" }, { "SummonGUI.Main.PickerPopup.Card.CancelButton", "Stone" },
	{ "SummonRevealGUI.Overlay.SkipButton", "Stone" },
	-- Events
	{ "EventsGUI.Main.Detail.Actions.ShopButton", "Ember" }, { "EventsGUI.Main.Detail.Actions.QuestsButton", "Azure" },
	{ "EventsGUI.Main.Detail.Actions.BannerButton", "Violet" }, { "EventsGUI.Main.Detail.LootBox.Chest.OpenButton", "Ember" },
	{ "EventsGUI.Main.Detail.LootBox.Chest.OpenAllButton", "Gold" }, { "EventsGUI.Main.Detail.LootBox.Track.ClaimButton", "Jade" },
	{ "EventsGUI.Main.Sidebar.BackButton", "Stone" }, { "EventsGUI.Main.Sidebar.CalendarButton", "Azure" },
	{ "EventsGUI.QuestsPopup.Window.ClaimAllButton", "Jade" }, { "EventsGUI.QuestsPopup.Window.Detail.ClaimButton", "Jade" },
	{ "EventsGUI.QuestsPopup.Window.Detail.GoButton", "Azure" }, { "EventsGUI.ShopPopup.Window.AmountButton", "Stone" },
	{ "EventsGUI.ShopPopup.Window.Grid.CardTemplate.BuyButton", "Gold" },
	-- Items / Areas / Daily / Battle Pass / Codes / misc
	{ "ItemsGUI.Main.Detail.UseButton", "Gold" }, { "ItemsGUI.Main.TopBar.FiltersButton", "Stone" }, { "ItemsGUI.Main.Detail.Amount.Max", "Stone" },
	{ "DailyRewards.Main.ClaimButton", "Jade" }, { "BattlePassGUI.Main.Header.ClaimAllButton", "Jade" },
	{ "BattlePassGUI.Main.Header.JumpButton", "Azure" }, { "BattlePassGUI.Main.PromoPanel.PurchaseButton", "Gold" },
	{ "RedeemCodes.Main.SubmitButton", "Gold" }, { "CurrencyConfigGUI.Alert.Box.OkButton", "Gold" },
	{ "PartyInviteGUI.Toast.AcceptButton", "Jade" }, { "PartyInviteGUI.Toast.DeclineButton", "Ruby" },
	{ "DialogueGUI.Choices.Template", "Night" }, { "StarterChoiceScreen.Main.SelectButton", "Gold" },
	{ "StarterChoiceScreen.Reveal.ContinueButton", "Gold" },
	-- Play menu
	{ "PlayGUI.Main.BottomBar.BackButton", "Stone" }, { "PlayGUI.Main.BottomBar.InviteButton", "Azure" },
	{ "PlayGUI.Main.BottomBar.JoinButton", "Jade" }, { "PlayGUI.Main.Content.Party.Buttons.ChangeMapButton", "Azure" },
	{ "PlayGUI.Main.Content.Party.Buttons.DisbandButton", "Ruby" }, { "PlayGUI.Main.JoinPopup.Window.List.RowTemplate.ActionButton", "Jade" },
	{ "PlayGUI.Main.InvitePopup.Window.List.RowTemplate.ActionButton", "Jade" },
	{ "PlayGUI.Main.StagePanel.Window.Details.Buttons.MatchmakingButton", "Azure" },
	{ "PlayGUI.Main.StagePanel.Window.Details.Buttons.SelectStageButton", "Gold" },
	{ "PlayGUI.Main.StagePanel.Window.Details.DifficultyRow.NormalButton", nil :: any }, { "PlayGUI.Main.StagePanel.Window.Details.DifficultyRow.HardButton", nil :: any },
	{ "PlayGUI.Main.StagePanel.Window.Details.StarRewards.Row.Reward1.ClaimButton", "Jade" },
	{ "PlayGUI.Main.StagePanel.Window.Details.StarRewards.Row.Reward2.ClaimButton", "Jade" },
	{ "PlayGUI.Main.StagePanel.Window.Details.StarRewards.Row.Reward3.ClaimButton", "Jade" },
	-- Upgrade screens
	{ "AscensionGUI.Main.ButtonRow.AscendButton", "Gold" }, { "AscensionGUI.Main.ButtonRow.QuickSynthButton", "Azure" },
	{ "AscensionGUI.PickerPopup.DeselectAllButton", "Stone" }, { "AscensionGUI.PickerPopup.FilterButton", "Stone" },
	{ "AscensionGUI.PickerPopup.FinishButton", "Gold" }, { "EvolveGUI.Main.Middle.EvolveButton", "Gold" },
	{ "EvolveGUI.Main.Middle.QuickCraftButton", "Azure" }, { "EvolveGUI.Main.LeftCard.Body.ExpandButton", "Night" },
	{ "EvolveGUI.Main.RightCard.Body.ExpandButton", "Night" }, { "EvolveGUI.PickerPopup.DeselectAllButton", "Stone" },
	{ "EvolveGUI.PickerPopup.FilterButton", "Stone" }, { "EvolveGUI.PickerPopup.FinishButton", "Gold" },
	{ "CraftingGUI.Main.RightPanel.CraftButton", "Gold" }, { "CraftingGUI.Main.BottomBar.CancelButton", "Stone" },
	{ "CraftingGUI.DismantlePopup.List.RowTemplate.DismantleButton", "Ruby" },
	{ "StatRerollGUI.Main.Panel.ButtonRow.RerollAllButton", "Gold" }, { "StatRerollGUI.Main.Panel.ButtonRow.InstantRollButton", "Violet" },
	{ "StatRerollGUI.Main.Panel.ButtonRow.FiltersButton", "Stone" }, { "StatRerollGUI.Main.Panel.ButtonRow.ShowChancesButton", "Azure" },
	{ "StatRerollGUI.Main.Panel.Stats.Row_DMG.FocusButton", "Gold" }, { "StatRerollGUI.Main.Panel.Stats.Row_RNG.FocusButton", "Gold" },
	{ "StatRerollGUI.Main.Panel.Stats.Row_SPA.FocusButton", "Gold" }, { "StatRerollGUI.Main.Panel.Stats.Row_DMG.InstantButton", "Violet" },
	{ "StatRerollGUI.Main.Panel.Stats.Row_RNG.InstantButton", "Violet" }, { "StatRerollGUI.Main.Panel.Stats.Row_SPA.InstantButton", "Violet" },
	{ "StatRerollGUI.FiltersPopup.ApplyButton", "Gold" }, { "StatRerollGUI.FiltersPopup.ResetButton", "Stone" },
	{ "StatRerollGUI.PickerPopup.DeselectAllButton", "Stone" }, { "StatRerollGUI.PickerPopup.FilterButton", "Stone" },
	{ "StatRerollGUI.PickerPopup.FinishButton", "Gold" }, { "StatRerollGUI.Main.Packs.List.PackTemplate.BuyButton", "Jade" },
	{ "TraitRerollScreen.Main.Panel.Buttons.BtnReroll", "Gold" }, { "TraitRerollScreen.Main.Panel.Buttons.BtnInstantRoll", "Violet" },
	{ "TraitRerollScreen.Main.Panel.Buttons.BtnFilters", "Stone" }, { "TraitRerollScreen.Main.Panel.Buttons.BtnShowChances", "Azure" },
	{ "TraitRerollScreen.Main.Panel.Detail.RerollButton", "Gold" }, { "TraitRerollScreen.Main.Panel.SlotButton.ClearButton", "Stone" },
	{ "TraitRerollScreen.Main.SlotsBar.SwapButton", "Azure" }, { "TraitRerollScreen.Main.ConfirmOverlay.Card.YesButton", "Gold" },
	{ "TraitRerollScreen.Main.ConfirmOverlay.Card.NoButton", "Stone" }, { "TraitRerollScreen.Main.FilterOverlay.Card.BackButton", "Stone" },
	{ "TraitRerollScreen.Main.InstantOverlay.Card.ApplyButton", "Gold" }, { "TraitRerollScreen.Main.InstantOverlay.Card.CancelButton", "Stone" },
	{ "TraitRerollScreen.Main.InstantOverlay.Card.Presets.BtnHalf", "Stone" }, { "TraitRerollScreen.Main.InstantOverlay.Card.Presets.BtnMax", "Stone" },
	{ "TraitRerollScreen.Main.InstantOverlay.Card.Presets.BtnMin", "Stone" },
	{ "SilverShopGUI.UnitSlotsButton", "Violet" }, { "SummonGUI.Main.Root.Drawer.Scroll.Grid.PackTemplate.BuyButton", "Jade" },
	-- GAME place screens (missing in the Lobby = reported, harmless)
	{ "MatchEnd.Panel.ButtonRow.LobbyButton", "Stone" }, { "MatchEnd.Panel.ButtonRow.NextActButton", "Gold" },
	{ "MatchEnd.Panel.ButtonRow.RestartButton", "Azure" }, { "MatchEnd.Results.Window.Left.Buttons.LobbyButton", "Stone" },
	{ "MatchEnd.Results.Window.Left.Buttons.NextButton", "Gold" }, { "MatchEnd.Results.Window.Left.Buttons.ReplayButton", "Azure" },
	{ "MatchEnd.ShowResultsButton", "Gold" },
	{ "MatchHUD.RightButtons.UnitManagerButton", "Violet" }, { "MatchHUD.RightButtons.StageInfoButton", "Gold" },
	{ "MatchHUD.RightButtons.AutoPlayButton", "Jade" }, { "MatchHUD.SpeedControl.Speed1", nil :: any }, { "MatchHUD.SpeedControl.Speed2", nil :: any },
	{ "MatchHUD.SpeedControl.Speed3", nil :: any }, { "WavePrep.Root.SkipButton", "Gold" },
	{ "PlacementControls.Panel.ButtonRow.CancelButton", "Stone" }, { "PlacementControls.Panel.ButtonRow.PlaceButton", "Jade" },
	{ "PlacementControls.Panel.ButtonRow.RotateButton", "Azure" },
	{ "AutoPlaySettings.Panel.PresetMenu.Delete", "Ruby" }, { "AutoPlaySettings.Panel.PresetMenu.Duplicate", "Azure" },
	{ "AutoPlaySettings.Panel.PresetMenu.Rename", "Stone" }, { "AutoPlaySettings.Panel.ZoneTile.Clear", "Stone" },
	{ "AutoPlaySettings.Panel.ZoneTile.Select", "Gold" }, { "AutoPlaySettings.RenamePopup.Window.Cancel", "Stone" },
	{ "AutoPlaySettings.RenamePopup.Window.Save", "Gold" },
}

local function resolve(path: string): Instance?
	local node: Instance? = SG
	-- names may contain "/" (UN/EquipButton): split on "." only
	for seg in string.gmatch(path, "[^%.]+") do
		node = node and node:FindFirstChild(seg)
	end
	return node
end

local bk = SS:FindFirstChild("_UIBackup_B151") or Instance.new("Folder")
bk.Name = "_UIBackup_B151"
bk.Parent = SS
local done, missing, guis = 0, {}, {}
for _, row in ipairs(LIST) do
	local b = resolve(row[1])
	if b and b:IsA("GuiButton") then
		local gui = string.match(row[1], "^[^%.]+")
		if gui and not guis[gui] and not bk:FindFirstChild(gui) then
			local g = SG:FindFirstChild(gui)
			if g then g:Clone().Parent = bk end
			guis[gui] = true
		end
		P.convert(b, row[2])
		done += 1
	else
		table.insert(missing, row[1])
	end
end
P.buildTemplate()
return string.format("converted %d; missing %d: %s", done, #missing, table.concat(missing, ", "))
