# Events window + Beginner's Path (Lobby) -- B108 pt18 Part G

## Pieces
| Piece | Where | Job |
|---|---|---|
| `Configs.EventQuestConfig` | ReplicatedStorage.Configs (Lobby) | **Every event + quest.** Groups (Starter / Featured / Active), events (Name, Tag, Description, Banner, Giver, Pages), quests (Id, Text, Goal, Rewards, Go), `Progress(data, goal)`. 25 drafted Beginner's Path quests on 5 pages -- placeholder balance, edit freely. |
| `EventQuestService` | ServerScriptService.Server.Meta | `GetEventQuests`, `ClaimEventQuest` (grant first, mark second), `PinEventQuest`. One writer of `Counters.Global.EventQuests` + `Counters.Global.EventPinned` (no schema bump -- same home as ChallengeLimits). Studio: `RS:SetAttribute("DevEventQuests","reset")` server-side wipes claims + pin. |
| `LifetimeCounters` | ServerScriptService.Server.Meta | `Bump(userId, key, n)` -- new lifetime counters: Feeds, TraitRerolls, StatRerollsDone, Crafts, Evolutions, ShopBuys (wired into Feed/TraitReroll/StatReroll/Crafting/GrantService.EvolveUnit/Shop). |
| `EventsGUI` + `EventsController` | StarterGui (authored) | Window: sidebar groups, event header + Permanent pill + description, page tabs 1-5 (lock icon), page counter x/5, 5 quest rows, locked overlay, Back / Calendar (soon) / Event Banner. |
| `EventTracker` | StarterGui (authored) | The pinned quest on the HUD (right side). Click = open Events. Refreshes every 20 s. |

## Rules
- Goals are LIFETIME: Counter / Level / StageClear / Stars / UnitsOwned / UnitLevel / Equipped / Codes.
- Page N unlocks when every quest on page N-1 is claimed (server-checked).
- Row: Pin (one pinned quest; claiming it unpins) | Go to Quest (closes the window, fires `Go.Open(Arg)` and the walk arrow to `Go.Npc`) | X (not done) -> Claim (done) -> check (claimed).
- Entry: HUD Event button (was the DailyRewards event tab), the guide NPC's dialogue choice, the tracker. `ClientEvents.OpenEvents(eventId?)`.
- Event Banner -> `ClientEvents.OpenSummon(bannerId)` (SummonGUI now accepts a banner id) -- Beginner's Path uses `EventFirstLight`.

## Not yet
- The GAME's pinned-quest panel does not show event quests (Lobby tracker only).
- Featured / Active groups are empty until the user's event references arrive. Calendar = "coming soon".
