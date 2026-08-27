# Shop — the daily Silver sink (Lobby meta, AD-Gacha canon)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-27 (B40) -->

A per-player, per-day rotating stock priced in **Silver**.

| piece | what it is |
|---|---|
| `RS.Configs.Meta.ShopConfig` | PURE: the catalogue, the prices, the deterministic stock roll |
| `SSS.Server.Meta.ShopService` | **THE one writer of `Data.ShopStock`**; owns `GetShopStock` + `BuyShopItem` |

`RS.Remotes` **27 → 29**. No schema bump: `ShopStock { DayNumber, Bought }` has been in the template
since v2 with no writer — the same free ride `LoginStreak` gave B38 and `Quests` gave B40.

## ⚠ Why this exists: Silver had a faucet and no drain

B31 made selling duplicate units **mint** Silver. Nothing had ever spent it, and that was verified
rather than assumed before building:

- every banner costs **Gold** (`Currency = "Gold"`, `CostPerPull = 100`);
- `GrantService.Spend` — the one debit path — was **never called with `"Silver"`** anywhere in the
  server tree;
- so Silver only ever accumulated.

A currency with no sink only inflates, and **a reward that buys nothing is not a reward**. The shop is
the drain. `ShopConfig.Currency` names it once so a second shop currency stays a config change.

## The stock is DERIVED, not stored

`ShopConfig.RollStock(userId, day)` computes it from `MetaMath.RngForSlot(day, "Shop:"..userId)`, so
every server produces the same stock for the same player on the same day with **no stored roll and no
MessagingService** — the mechanism MetaMath's own header names "shop stock" as its purpose
(cross-phase invariant 3). Only `Bought` is persisted, because it is the only part that cannot be
recomputed.

- **The salt includes the userId** so two players do not see identical shops. Leaving it out would
  give the whole game one shared shop — a legitimate design, but it would be an accident rather than a
  choice.
- **`PickDistinct`**, so one slot cannot appear twice in a day. Fewer slots than `StockSize` when the
  catalogue is short is correct, not an error.

## ⚠ The day rollover RESETS `Bought`, it does not merge

Slot 2 yesterday and slot 2 today are different items. Carrying the flag over would make today's
purchase look already-made.

## Ordering: PRE-CHECK, SPEND, GRANT, then MARK

Four steps, and each is where it is for a reason:

1. **Pre-check the id against `ItemCatalog`.** `Grant` refuses an uncatalogued id, and discovering
   that *after* the debit would charge a player for nothing because of a typo in a config file.
2. **`Spend`.** The reverse order would hand over the item before payment cleared.
3. **`Grant`.** If it somehow still fails, **refund through `GrantService`** (invariant 1 — every
   credit goes through it) and warn loudly. A silent refund looks like a theft.
4. **Mark the slot bought** — only once paid *and* delivered.

## ⚠ The client sends a SLOT INDEX and nothing else

The id, the quantity and above all the **price** come from the server's own re-roll of the stock. A
client that could name its own price is the whole reason none of that is a parameter.

## Reveal: the RETURN VALUE

The player clicked, so `BuyShopItem` returns `Rewards = views` and the client fires `ShowRewards`
(B37's rule). Not `RewardPush`.

## Reason codes

`bad_slot` · `no_such_slot` · `already_bought` · `insufficient_funds` · `item_not_catalogued` ·
`grant_failed_refunded` · `profile_not_loaded` · `busy`

## Verified live

| case | result |
|---|---|
| stock | 4 slots with catalogue Name/Tier, `restockIn 1.9h` |
| buy the cheapest | Silver **1450 → 1150** (−300), Gold +250, `ok=true` |
| same slot again | `already_bought` |
| slot 99 / slot `"x"` | `no_such_slot` / `bad_slot` |
| **insufficient funds** (1900 vs 1150) | refused, **balance unchanged at 1150** |
| determinism | same user+day identical; other user differs; next day differs; slots distinct |

Prices and the catalogue are **PLACEHOLDER**, labelled in the file. They should eventually be set
against `TierConfig.GetSellValue`, which is what pays Silver in.

## Not built

The **screen**. `ShopService` is complete and tested; a shop UI (and the NPC the blueprint wants)
needs authored art.
