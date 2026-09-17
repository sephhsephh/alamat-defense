# Unit capacity — how many units a player may hold (Lobby meta)

<!-- owner: game (AD-Game, crossing AD-Lobby with the user's go-ahead) | scope: lobby | last-verified: 2026-09-17 (B72) -->

A player may hold **200 units** by default. Each upgrade adds **+50 slots** for **50,000 Silver**, repeatable
with no ceiling. At the cap a **SUMMON is refused** ("you don't have enough space") and **nothing is spent**;
every other grant **overflows** past the cap and is never lost. (User decisions, 2026-09-16 — do not re-ask.)

| piece | what it is |
|---|---|
| `RS.Configs.Meta.UnitCapacityConfig` | PURE, Lobby-local. `BaseCap` / `SlotsPerUpgrade` / `UpgradePrice` / `Currency`; `CapFor(n)`, **`CountUnits(units)` (THE one pairs-count)**, `HasRoom(used, n, incoming)`, `Snapshot(units, n)`. Client-safe. |
| `SSS.Server.Meta.UnitCapacityService` | **THE one writer of `Data.UnitSlotsPurchased`**; owns `Remotes.BuyUnitSlots` (created at boot by `ensure()`). |
| `SSS.Server.Meta.SummonService` step 1b | **THE one enforcement point** — before the spend. |
| `LobbyServices` → `GetUnitViews().UnitCapacity` | the read, per ADR-0004 (no second read path). |

## Rules that bite

- **The profile stores a COUNT of upgrades (schema v8), never the cap.** A re-tune of the config re-prices
  every player consistently.
- **`Data.Units` is a uuid-keyed dict — `#units` is always 0.** Count with `UnitCapacityConfig.CountUnits`,
  never an inline loop.
- **The whole batch must fit**: an x10 with 5 free slots is refused whole (never half-served). The count is
  taken **before auto-sell** (step 12) — a unit that will be auto-sold still has to land first.
- **Do NOT add the check to `GrantService.Grant` or the Game's `PlayerInventoryService`** — that would make
  quest/mail/code/match rewards disappear at the cap, the opposite of decision 3.
- **Not a Shop stock row.** `ShopStock` is day-rolled with 4 slots and `Bought` flags; a permanent repeatable
  upgrade does not fit. The Shop gets a dedicated row calling the same remote.
- Order: **PRE-CHECK → `GrantService.Spend` → write**. The client sends no price.

## Wire shapes

`BuyUnitSlots:InvokeServer()` → `{ ok, reason?, Used, Cap, Purchased, SlotsPerUpgrade, Price, Currency, Balance, Need?, Have? }`
(`reason`: `insufficient_funds` / `busy` / `profile_not_loaded` / `server_error`). The snapshot is returned on
refusals too, so a screen can re-render from any reply.

`RequestSummon` refusal: `{ ok = false, reason = "unit_capacity_full", Used, Cap, Need }`. `SummonController`
maps it to the status line **and** a `UIKit.Notify` error.

## Status

- **B72 (backend) — PROVEN LIVE.** Unfunded buy refused at 0 Silver; seeded 120,000 → buy 200→250 (70,000),
  250→300 (20,000), third refused `insufficient_funds` with nothing written. With `BaseCap` TEMPORARILY -91
  (cap 9, 8 units): x10 refused (gold unchanged), x1 granted (9/9), next x1 refused (gold unchanged). Reverted to 200.
- The client's refusal line/notification was **not click-tested** (the capability sandbox blocks opening the
  screen from the MCP thread); the remote path underneath it was.
- **B74 (UI) — BUILT.** Authored, tag `B74Built`:
  - **Units screen:** `UnitsGUI.Main.Bottom.CapacityBar` = `CapacityLabel` ("UNITS 49 / 350", red when full) +
    `UpgradeSlotsButton` (a restyled clone of QuickSell, blue). Painted from `GetUnitViews().UnitCapacity` in
    `loadUnits`; click -> `UIKit.Confirm` -> `BuyUnitSlots` -> repaint from the RETURN VALUE + toast.
    **Proven by real clicks:** 300 -> 350, Silver 140,000 -> 90,000, label updated.
  - **Shop:** `ShopGUI.Main.UnitSlotsRow` (title / capacity / price / BuyButton) under the daily grid (the
    grid shrank 60px; its one 300px row still fits). Counts via `GetUnitViews` on open; same Confirm + remote.
    Proven: row renders "Units 49 / 350" and the Confirm opens. ⚠ The final BUY click in the shop was NOT
    registered -- Studio stopped accepting mouse input mid-test (same symptom as B73); the server call is the
    same one the Units screen proved.
  - ⚠ Opening `UIKit.Confirm` from the Shop CLOSES the Shop screen behind it (seen live) -- the purchase
    still completes from the popup; flagged, not changed.
