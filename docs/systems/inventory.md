# Inventory (Items screen) -- LOBBY
<!-- owner: AD-Lobby (UI) / AD-Meta (ItemActionsService) | since: B145 (2026-10-13) | user refs B145 -->

Opens from HUD **Inventory**. Rebuilt at B145 from the user's reference screenshots into our own Alamat layout.

## Layout (`StarterGui.ItemsGUI`, built by `tools/inventory_build.luau`; old Main in `ServerStorage._UIBackup_B145`)
| Part | What |
|---|---|
| `Main.Header` | gold emblem (spinning rays) + "INVENTORY" ribbon |
| `Main.TopBar` | `SearchBar` (name/id search) + `FiltersButton` (shared `UIKit.FilterPanel`: Rarity, Favourites only, Locked only) |
| `Main.Tabs` | one `TabTemplate` clone per `InventoryConfig.Categories` (icon, name, owned count); `Summary` line |
| `Main.GridPlate.Grid` | **owned items only** (user rule: never show 0), shared `UIKit.ItemIcon` cards (rarity gradient, count); `MarksTemplate` (star / lock) cloned onto each card. Sort: favourites, rarity, name |
| `Main.Detail` | `TypeLine` ("Mythic Reward Box"), `NameLabel`, `Showcase` (CanvasGroup; rarity gradient on `Bg`, rays, magic circle, bobbing icon), `Stats` (Owned + Unit EXP / Max chips), `DescPlate.Desc`, `Rewards` (possible drops, chests), `Amount` stepper (- n + MAX), `UseButton` |
| `Main.Rail` | Favourite, Lock, View (showcase), Obtainments (`ClientEvents.OpenObtainment` -> ItemInfoGUI popup), Discard; `RailTip` on hover / gamepad select |
| `ViewOverlay` | the View showcase reveal (big icon, rays, sparkles, info card). "Click anywhere to close" = the allowed reveal exception |
`ItemsGUI.DisplayOrder = 5` (above the HUD's side panels). Only the X closes the screen; gamepad B = X (closes View first).

## What Use does -- `RS.Configs.Meta.InventoryConfig` (Lobby, edit freely)
- Chests (`Action = "OpenChest"`, amount stepper, max 50): `OpenInfernalChests(n)` -> `ShowRewards` reveal -> reload.
- **NPC items TRAVEL (B148, user):** a row with `Area` (an `AreasConfig` id) teleports to that NPC behind the veil
  (`AreaAction("Travel")`), closes Items and toasts its `Hint`: Trait token -> Trait Shrine, Stat/Focus chips -> Stat
  Forge, Scarecrow Crown -> Rune Circle, Mutya / Golden Seed -> Crafting, Silver -> Silver Shop. Button reads "Go to ...".
- Everything else jumps to the screen that spends it (`Event` = a ClientEvents BindableEvent; the Items screen closes
  itself): food -> Units (Feed, with a hint toast), Banner Ticket -> Summon, Gold -> Shop,
  Event Coin -> Events. No row = a disabled "Use Item".
- `Categories` (first match wins), `TypeLabel`, `ShownKinds`, `CurrencyField` (EventToken ids read
  `Currencies.EventTokens[id]`), `NoDiscard`.

## Server -- `SSS.Server.Meta.ItemActionsService` (Lobby Script)
`GetItemFlags()`, `SetItemFlag(id, "Fav"|"Lock", on)`, `DiscardItems(id, qty)` (refused: locked, currency, not owned;
spends through `GrantService.SpendItems`). Flags live in **`Counters.Global.ItemFlags = { [id] = { Fav, Lock } }`** --
no schema bump (same home as EventQuests / InfernalClaims). Counts still come from `GetUnitViews`.

## Verified B145 (Play)
7 owned types, tabs counted; Pandesal -> "Common Unit Food", Unit EXP chip, Feed Item; favourite star on card + rail;
View showcase; Open 1 Infernal Chest -> reward reveal, chest 3 -> 2, re-sorted; Discard -> red Danger confirm (cancelled).
