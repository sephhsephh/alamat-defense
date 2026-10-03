# Events screen + Event Coin + Event Shop (Lobby) -- B109 M3 (rebuilt from pt18 Part G)

<!-- owner: lobby | scope: lobby | last-verified: 2026-10-03 (B109 M3) -->

Decisions: `docs/specs/2026-10-03-quests-events-overhaul.md`. pt18's window = `EventsGUI_RetiredB109` (disabled).

## Pieces
| Piece | Where | Job |
|---|---|---|
| `Configs.EventQuestConfig` | RS (Lobby) | **Every event.** Id, Name, Type (Quest/Buff/UnitHunt/Loot), TypeLabel, Featured, Window `{StartUtc,EndUtc}` or `WindowSource = "WeekendRush"`, Label (replaces the countdown, e.g. "Permanent"), Color, Art, Unit (centre model), Description, Coin, Buff `{Title,Text}`, Banner, Pages (quests). `Status(ev)` -> Active/Upcoming/Ended + seconds. Goals = `Configs.Meta.GoalEval`. |
| `EventQuestService` | SSS.Server.Meta | `GetEventQuests`, `ClaimEventQuest` (grant first, mark second; page unlock). Claims in `Counters.Global.EventQuests` (no schema bump). Its old single pin (`EventPinned`, `PinEventQuest`) is LEGACY -- pins are now `Data.Quests.Pins` `"E:<event>:<quest>"` via `SetQuestPin`. |
| `Configs.Meta.EventShopConfig` + `EventShopService` | RS / SSS | Event Shop rows `{Id, Qty, Price}`, **unlimited** (user). `GetEventShop`, `BuyEventShop(index, times<=100)`: pre-check -> `GrantService.Spend` -> Grant (refund on a refused grant). |
| `EventCoin` | shared `ItemCatalog` (Kind `EventToken`) | ONE shared event currency in `Currencies.EventTokens.EventCoin` (field since v2). `GrantService` grants + spends it; `LobbyServices` views carry `Currencies.EventTokens`; the item hover card counts it; `ObtainmentCatalog` lists every event that pays it + the Event Shop. |
| `EventsGUI` + `EventsController` | StarterGui (authored) | Full-screen: sidebar (Featured cards, collapsible Active / Upcoming groups, Back, Calendar = coming soon), centre unit model (`UnitCard.viewport` + `playIdle`), right detail (type, name, timer pill, description, buff box, Event Shop / Event Quests / Event Banner). Popups `QuestsPopup` (page tabs + locks, rows, detail, Claim, Pin, Go to Quest) and `ShopPopup` (grid, Buy x1/x10, balance with the coin hover card). |
| `EventTracker` + `PinTrackerController` | StarterGui (authored) | HUD pin tracker = EVERY pin (quests, achievements, event quests), bottom-right, 2 cards tall then scrolls. Refresh: 15 s, `ClientEvents.PinsChanged`, after rewards. Click opens the source. |

## Rules
- Ended events are hidden; Featured events sit on top; the rest group by Active / Upcoming (collapsible).
- Theme follows the selected event's `Color` (backdrop, title, popups). Only Back / X / gamepad B close; scrims never.
- Beginner's Path quests each pay 10 Event Coins (placeholder `BEGINNER_COINS`). Weekend Rush = Buff event (`WindowSource`).
- Studio harness: `EventsGUI` attribute `DevOpen = "<eventId>"`; server `RS:SetAttribute("DevEventQuests","reset")`.

## Verified live (B109 M3, Lobby, real clicks)
HUD Event -> screen (Featured Beginner's Path, Active Weekend Rush "Ends in 1d, 2h"); Event Quests popup (page 2 of 5,
3-5 locked), claim -> Gold + Bibingka + Event Coin x10; Event Shop grid, buy Trait Reroll Token for 10 (balance 10 -> 0,
buttons grey); pin from detail + row; HUD tracker shows quest + event pins. Gamepad paths code-only.

## Headliner Hunt (UnitHunt, B109 M4)
- Config: `Units` (carousel; click swaps the centre model), `EvolveRewards = { {TowerId = <evolved form>, Reward} }`,
  quests with goal `ObtainSince` (`GoalEval`): obtains AFTER the player first saw the event (baseline =
  `Counters.Global.EventQuests[ev].Base[towerId]` = lifetime `Obtained_<id>` at first sight; EventQuestService writes it
  once, on join / GetEventQuests / claim, only while the event is Active). Selling/feeding never lowers progress.
- Evolve Rewards: gift button -> `ClaimEventEvolve(eventId)` claims every done + unclaimed one (`Claimed["Evolve_<id>"]`).
- Claims refuse while an event is Upcoming (`event_not_started`). Placeholder units: Tala, Lalahon, Aswang, Tiyanak
  (+ evolved forms), 40 Event Coins each; banner button -> EventFirstLight.
- Verified live: carousel + evolve box; DevPushRewards "Tala:1" -> "Obtain Tala" 1/1 -> claim 40 coins. Evolve gift with a
  real evolution: code-path only.

## Not yet
Infernal Hunt (M5, Game), Calendar, the Game's pinned panel (M7). The HUD EVENT card text is the
user's static authored text (not driven).
