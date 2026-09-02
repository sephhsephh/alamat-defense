# economy-map — Alamat Defense
<!-- owner: AD-Meta/AD-Gacha | scope: economy (both Places, faucets span Lobby + Game) | added: 2026-09-02 (B46) -->

The one place that answers, for every spendable resource: **what GRANTS it (faucet) and what
SPENDS it (sink).** Written B46 because two reroll sinks (C1 trait, C2 stat) landed in B44 and the
next economy change should be a table lookup, not archaeology.

## How to read this

- All Lobby grants/spends flow through **`GrantService`** (invariant 1 — never write `Currencies`
  inline). Match-end grants flow through the **Game**'s `RewardCalculator`/`PlayerInventoryService`.
- A drop/reward is routed by its **`ItemCatalog.Kind`** (B45): `Kind="Currency"` → `Data.Currencies`,
  else `Data.Items`. A `{ Id, Qty }` row is `GrantService`'s public grant contract.
- **PLACEHOLDER BALANCE everywhere.** Every quantity in the config tables is provisional and the
  user's to tune; retuning is a one-file config edit, no code change.
- Config homes are all `RS.Configs.Meta.*` (Lobby-local) unless noted.

## The map

| Resource | Kind | Faucets (what grants it) | Sinks (what spends it) |
|---|---|---|---|
| **Gold** | Currency (scalar) | Match-end payout (Game `RewardCalculator`, the GoldBand curve in shared `RewardScalingConfig`) — the primary faucet · `DailyRewardConfig` day 1 · `ShopConfig` Gold-for-Silver slots (250@300, 600@650) · `QuestRegistry` (PullTen, WinInsane) · `BattlepassConfig` free even tiers + paid non-milestone tiers | **Gacha summons** — every banner `CostPerPull = 100`, `Currency = "Gold"` (`gacha.md`) |
| **Silver** | Currency (scalar) | **Selling duplicate units** (`GrantService.SellUnits` → `TierConfig.GetSellValue`) — the primary faucet (`ascension.md`) · `DailyRewardConfig` days 2, 6 · `QuestRegistry` (PullThree, PullOne, ClearThree, +PullTen/WinInsane) · `BattlepassConfig` free odd tiers | **The daily shop** (`ShopConfig`/`ShopService`, priced in Silver) — the only Silver sink (`shop.md`) |
| **TraitRerollToken** | Item | `DailyRewardConfig` day 5 · `ShopConfig` (550 Silver, wt 5) · `BattlepassConfig` paid milestone rotation (every 5th tier: TraitRerollToken/GoldenSeed/BannerTicket) · Insane wins (`RewardScalingConfig.InsaneItems`) | **C1 trait reroll** (`TraitRerollService`, 1 token/reroll — spends the ITEM, not `Currencies.TraitRerolls`) (`trait-reroll.md`) |
| **StatRerolls** | Currency (scalar) | `DailyRewardConfig` day 4 · `ShopConfig` (450 Silver, wt 5) · `BattlepassConfig` **free** tier 25 · `QuestRegistry` ClearThree · Insane wins (`RewardScalingConfig`, B45) — **the four everyday sources added B46** | **C2 stat reroll** (`StatRerollService`, `StatRerollConfig.Cost` = 1/reroll) (`stat-reroll.md`) |
| **EventTokens** | Currency (nested map) | **NONE yet** — reserved schema field; `GrantService` defers it to the B4 event track | **NONE yet** |
| **TraitRerolls** | Currency (scalar) | **NONE — DEAD FIELD** | **NONE** |

## Notes that bite

- **`Currencies.TraitRerolls` is a dead scalar.** The blueprint's C1 line said "spend
  `Currencies.TraitRerolls`", but C1 spends the `TraitRerollToken` ITEM instead (B44,
  `TraitRerollConfig` header). So this scalar has **no faucet and no sink** — it stays `0` forever.
  It is still surfaced read-only (`LobbyServices`, `SummonService` currency payloads) but is HIDDEN
  in the currency bar and items screen (`CurrencyBarController` ~L38, `ItemsController` ~L48), so
  there is no live UI confusion. **Removing it costs a v5 schema bump + both-Places publish +
  migration**, so it is documented-dead now and flagged for removal at the next schema bump — do not
  bump the schema for this alone.
- **`StatRerolls` vs `TraitRerolls`:** the schema shipped BOTH scalar reroll currencies in v2.
  `StatRerolls` is now fully alive (C2's cost + the sources above). `TraitRerolls` is the dead one.
- **Shop Gold slots are a Silver→Gold conversion** — a Gold faucet that is simultaneously a Silver
  sink. The shop is the only place the two scalar currencies meet.
- **EventTokens** is a nested `{ [string]: number }` map, not a scalar; `GrantService`'s
  `SCALAR_CURRENCIES` does not include it and its grant/spend path is unbuilt until the event track.
- **Stale-log watch (B46):** `StatRerollService`'s boot print still says StatRerolls has "no source
  yet — SINK only". That string is now false (the faucet opened B45 + B46). Cosmetic only; it is
  AD-Traits' service to correct — noted here so it does not read as an "unbuilt" claim next session.

## Cross-refs

`gacha.md` (the one grant path) · `shop.md` · `daily-rewards.md` · `quests.md` · `battlepass.md` ·
`trait-reroll.md` · `stat-reroll.md` · `ascension.md` (the Silver faucet) · `rewards.md` (AD-Game
match payouts, the Gold faucet).
