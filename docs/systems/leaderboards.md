# leaderboards — Alamat Defense
<!-- owner: AD-Meta/AD-Gacha | scope: lobby | added: 2026-09-02 (B47) -->

The GLOBAL account-LEVEL leaderboard: a worldwide top-N board ranked by `Data.PlayerLevel`.
Built B47. **Lobby-local, no schema bump, no shared canon, no Game change, no contract.**

## The decision (USER, B47)

Ranked metric = **account level** (`Data.PlayerLevel`); scope = **global top N**. Chosen over
stage-cleared / kills / clear-time because those are match-derived (the GAME writes them) and would
make this cross-Place; PlayerLevel already lives on the profile, so the whole system is Lobby-local.

## Why this needs no Game change and no schema bump

`Data.PlayerLevel` is written by the GAME (`PlayerInventoryService.AddPlayerXP`) at match end. A
player **cannot change level while in the Lobby** (no Lobby XP source), and they return to the Lobby
after any level-up. So publishing each player's CURRENT level on the Lobby's `ProfileLoaded` is always
up to date, with zero Game-side writes and no cross-Place contract. `PlayerLevel` has been on the
schema (v2+) forever, so no v5.

**KNOWN LIMIT (documented, not a bug):** a player who levels up and quits from the GAME without
returning to the Lobby publishes that level on their NEXT lobby visit. Acceptable for a level board;
the honest cost of staying Lobby-local. Closing it would mean a Game-side publish (cross-Place).

## Pieces (all Lobby-local, built B47)

- `RS.Configs.Meta.LeaderboardConfig` — PURE. `StoreName()` (Studio-aware, same rule as
  `ProfileTemplate.GetStoreName` — Studio writes to a SEPARATE ordered store, `...Dev1`), `TopN` (100),
  `CacheSeconds` (30), `ClientRefreshSeconds` (60).
- `SSS.Server.Meta.LeaderboardService` — a self-running Script (same shape as every Server.Meta
  service). **THE one publisher/reader of the level OrderedDataStore.** Publishes on
  `PlayerDataService.ProfileLoaded` **plus a boot-race sweep** of players already present (the same
  sweep LoadoutService / RevealDrainService run — a profile loaded before the script booted never
  fires ProfileLoaded). Serves `GetLeaderboard`.
- `RS.Remotes.GetLeaderboard` — RemoteFunction (authored instance; Remotes 35 → 36).
- `StarterGui.LeaderBoards` + `.LeaderBoardsController` — blockout screen + controller. Opens from
  `HUD.Right.UpperRight.LeaderBoardsButton` (was **unwired**) and `ClientEvents.OpenLeaderBoards`.

## OrderedDataStore specifics

Stores **integers keyed by userId**. `SetAsync(tostring(userId), level)` on publish;
`GetSortedAsync(false, TopN)` (descending) on read. Every store call yields and can throttle, so all
are pcall'd. The sorted read is **CACHED server-side** (`CacheSeconds`) so opening the screen never
hammers the GetSortedAsync budget, and a throttle is served from the last good cache rather than an
error. Names resolve via `GetNameFromUserIdAsync` (cached; a player in THIS server skips the web call).

## Server contract

```
GetLeaderboard() -> { ok = true, TopN, Entries = { { Rank, UserId, Name, Level, IsYou } } }
                  |  { ok = false, reason = "store_unavailable" }
```

Read-only: no claim, no grant, no reveal. `IsYou` marks the viewer's own row (highlighted client-side)
when they are within the top N.

## Screen contract (the controller reads ONLY these names)

Blockout art authored as real instances — replacing it with finished art costs ZERO code as long as
the names survive:

`Main` (panel) · `Overlay` (click-to-close) · `Main.CloseButton` · `Main.List` (ScrollingFrame) ·
`Main.List.RowTemplate` (Visible=false) with `RankLabel` / `PlayerName` / `LevelLabel` / `YouTag`
(Visible=false, shown when `IsYou`) / `YouStroke` (a UIStroke, thickened when `IsYou`) ·
`Main.EmptyLabel` (Visible=false) · `Main.Header` (column titles).

## Verified live (B47)

Seeded four fake ranks into the dev store + the real dev player (Lv 1); `GetLeaderboard` returned them
sorted descending (#1 Lv 88 … #5 the dev player Lv 1, `IsYou=true`); the screen rendered all five rows
with the viewer highlighted; seeds removed afterward. The publish (ProfileLoaded → SetAsync → the
dev player at Lv 1) was confirmed by reading it back.

## Future (not built — deliberate)

- **"+ your rank" when off-page:** the chosen scope is top-N only; showing a player's own rank when
  they are past rank N needs a second lookup (a per-user OrderedDataStore GetAsync + a count query).
- **Friends scope:** would need friend-list integration.
- **Other metrics** (highest stage cleared, total kills, fastest clear): all match-derived, so they
  would need a GAME-side publish and become cross-Place — a different, larger task.

## Cross-refs

`economy-map.md` (currencies) · the profile read path is ADR-0004's `GetUnitViews` (this board does
NOT use it — it reads the OrderedDataStore, a separate global store).
