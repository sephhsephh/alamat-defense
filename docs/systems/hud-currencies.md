# HUD currency bar — "Display Currencies" (B76)

**Owner:** AD-UI (crossing AD-Lobby / AD-Game for the schema). **Place:** LOBBY only — the Game Place
shows in-match Cash, not meta balances. **Schema v9.** +1 remote (`SetHudCurrencies`).

## What the player sees

The HUD's currency bar shows up to **3** balances plus a gear. The gear opens **Display Currencies**:
a two-column list of every offerable id with an on/off toggle, a search box, a slot counter
("Showing 2 of 3 on your HUD." / "All 3 slots used - turn one off to swap.") and a fill bar.
Turning on a 4th raises an **ALERT** ("You can't display more than 3 currencies!") and the toggle
stays off — the user chose refuse-over-swap, so nothing ever leaves the bar by itself.

## Rules (one source each)

| Question | Answer lives in |
| --- | --- |
| Which ids may be pinned, in what order | `Configs.Meta.HudCurrencyConfig.Options()` |
| How many at once | `HudCurrencyConfig.MaxSlots` = 3 (user, B76) |
| Where a given id's number is read | `HudCurrencyConfig.AmountOf(currencies, items, id)` |
| What is pinned right now | `GetUnitViews().HudCurrencies` = `{ Selected, Max }` (ADR-0004) |
| Name / icon / tier | shared `ItemCatalog` |

**Offerable = any `ItemCatalog` entry with `Kind` "Currency" or "Item"** (21 today: Gold, Silver,
Stat Reroll, Banner Ticket, Trait Reroll Token, Golden Seed, 7 fragments, 7 artifacts). Adding a
catalog entry is enough to offer it — there is no second list. Order = `HudCurrencyConfig.Order`
first, then everything else alphabetically, so a new entry lands in a stable place.

**`Data.Currencies.TraitRerolls` is deliberately NOT offered.** It has no catalog entry and the
trait-reroll screen spends the `TraitRerollToken` ITEM (C1, B44); offering both would put two
different "trait rerolls" numbers on one bar.

## Pieces

- `Configs.Meta.HudCurrencyConfig` (Lobby-local, pure) — the table above + `Sanitize`.
- `Server.Meta.HudCurrencyService` — **the one writer of `Data.HudCurrencies`**; owns
  `Remotes.SetHudCurrencies`, re-Sanitizes every payload (client is a request, never truth),
  **REFUSES** a list longer than `MaxSlots` instead of truncating, cleans a stale list on join, and
  fires `CurrencyChanged` at the caller so the bar repaints through the one read path.
- `HUD.Top.CurrencyBar.ConfigButton` + `StarterGui.CurrencyConfigGUI` (authored, tag `B76Built`).
- `CurrencyBarController` — pills are created per id and REUSED (unpinning hides, never destroys).
- `CurrencyConfigController` — rebuilds rows on every open; the save is optimistic then corrected by
  the server's returned list.

## Schema

`HudCurrencies: { string }`, default `{ "Gold", "Silver" }` (what the bar showed before it was
configurable, so nobody's HUD changes under them). `Migrations[8]` is a deliberate no-op — a
top-level key, so `Reconcile()` fills it before `Migrate()` runs. `ProfileTemplate` `d3d4e63c` →
`461fed3e`, byte-identical in both Places and on disk.

## Gotchas paid for live

- `AutomaticCanvasSize` is a PROPERTY; its enum is `Enum.AutomaticSize`. `Enum.AutomaticCanvasSize`
  does not exist and THROWS, killing the rest of the thread.
- Grid cells inside a ScrollingFrame are sized in **pixels** (scale collapses — B75's lesson), so the
  two-column cell width is measured from the frame and recomputed on resize.
- **An item grant did not move the bar** until B76 added `announceCurrency` to `GrantService`'s Item
  branch and to `SpendItems`. Before that only currencies pinged `CurrencyChanged`, so a pinned
  `TraitRerollToken` sat on a stale count until the next rejoin. Verified: push 2 tokens → pill 6 → 8.
- `StatRerolls` and the fragments have `Icon.Image = "rbxassetid://0"`, so their rows and pills draw
  the placeholder square until art is assigned.

## Proven live (Lobby, real clicks)

Gear opens the picker; 4th toggle raises the ALERT and stays off; Stat Reroll off + Trait Reroll
Token on repainted the bar immediately; search "frag" filtered 21 rows to the 7 fragments; close
works; the choice survived a full stop/start (`Gold, Silver, TraitRerollToken`); schema migrated with
`Migrated ... forward 1 step(s) to v9`; boot watchdog 40/40.
