# SYSTEM — Gacha (banner engine + the grant pipeline)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby (MetaMath is shared) -->
<!-- last-verified: 2026-08-09 (B3, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md -->

Built at **B3 (2026-08-09)** — the blueprint's B1 (MetaMath + GrantService + PityConfig) and B2
(banner registry + summon service + odds harness) session-tasks, done together by user decision.
**Summon UX / NPC / carousel (blueprint B3), Selection + Event flows (B4) and the Index/Codex (B5)
are NOT built.** There is no gacha UI at all yet — the engine is driven by a remote.

## Where everything lives

| Thing | Path | Canon |
|---|---|---|
| `MetaMath` | `RS.Shared.MetaMath` | **SHARED** (`shared/src/MetaMath.luau`, hash `6badac1d`) |
| `MetaConfig` | `RS.Configs.Meta.MetaConfig` | Lobby-local |
| `PityConfig` | `RS.Configs.Gacha.PityConfig` | Lobby-local |
| `GachaConfig` | `RS.Configs.Gacha.GachaConfig` | Lobby-local |
| `BannerRegistry` | `RS.Configs.Banners.BannerRegistry` | Lobby-local |
| banner files | `RS.Configs.Banners.<Name>` | Lobby-local (one file per banner) |
| `GrantService` | `SSS.Server.Meta.GrantService` | Lobby-local (ModuleScript) |
| `SummonEngine` | `SSS.Server.Meta.SummonEngine` | Lobby-local (ModuleScript) |
| `SummonService` | `SSS.Server.Meta.SummonService` | Lobby-local (Script) |
| remote | `RS.Remotes.RequestSummon` | RemoteFunction (Remotes 12 → 13) |

Only `MetaMath` is under drift control. The rest is Place-local on purpose: a module in
`shared/manifest.json` costs a cross-Place sync forever (the CurrencyBar precedent, A6), and
nothing in the Game place reads any of this.

## MetaMath (shared, the "implement ONCE" algorithms)

- `Slot(period, offsetSec, nowSec?)` — `floor((now + offset) / period)`. Every server computes the
  same integer from the clock alone, so rotations and resets agree with **no MessagingService and
  no stored state**. Cross-phase invariant 3: every reset/rotation goes through this. No `os.date`
  math anywhere else.
- `RngForSlot(slot, salt)` — `Random` seeded from a slot. **The salt is load-bearing**: without it
  two banners sharing a `RotationPeriod` would draw the identical featured set forever. Pass the
  banner id.
- `Pick(rng, {{v,w},...})` — weighted choice. Ignores non-positive/NaN weights, returns nil when
  nothing has weight, and has a float-tail fallback so a roll landing exactly on `total` still
  returns a value.
- `PickDistinct(rng, entries, n)` — n draws without replacement; returns fewer if the pool runs out.

Pure: no services, no state, no config reads. The reset-hour knob is passed IN, which is what keeps
it Place-neutral. `MetaConfig.ResetOffsetSec = -57600` → daily boundary at **16:00 UTC** (08:00 PST).
Fixed offset, **no DST** — deliberate; a DST-aware reset moves the boundary twice a year and
re-rolls every rotation on the changeover day.

## GrantService — THE one grant path

Blueprint: *"EVERY system grants through this ONE function. Never grant inline."*
Cross-phase invariant 1 greps for direct `Currencies.` writes outside it — which is why **`Spend()`
lives here too**, not in the caller.

```lua
GrantService.Grant(userId, {
  { Id = "Gold", Qty = 500 },                    -- Currency
  { Id = "BannerTicket", Qty = 2 },              -- Item (MaxOwned-capped)
  { Id = "Archer", Qty = 3 },                    -- 3 SEPARATE Archer instances
  { TowerId = "Necromancer", MetaLevel = 40, Shiny = true, StatRolls = {...} },
}) --> (ok, views, reason)

GrantService.Spend(userId, "Gold", 100) --> (ok, reason, newTotal)
```

- **Routing by `ItemCatalog.Kind`**: `Tower`→uuid UnitInstance · `Item`→`Data.Items` ·
  `Currency`→`Data.Currencies` · `Title`→`Data.Titles.Owned` · `Spirit`→`Data.Spirits`.
  Title/Spirit are shape-correct but **UNEXERCISED** — no such catalog entry exists yet.
- **All-or-nothing**: every entry is validated before anything is written, so a bad entry at
  index 7 cannot leave 1–6 already banked. Verified.
- **Invariant 4 enforced here**: an id absent from `ItemCatalog` is REFUSED
  (`uncatalogued_id_<id>`) rather than silently creating a profile field.
- **Unit instance shape** must stay byte-compatible with the Game's
  `PlayerInventoryService.GrantUnit` and `Server.Lobby.StarterChoiceService` — all three write the
  same schema-v2 record. StatRolls via shared `StatGradeConfig.RollAll` off **one module-level
  `Random`** (a fresh `Random.new()` per grant correlates inside a frame, which an x10 hits every
  time).
- Non-yielding: callers must have the profile loaded (`WaitForData`) first.
- **It is the FIRST WRITER of `Data.Items` in the codebase.** The long-standing "no writer" note is
  *not* closed: the capability exists and is verified, but no shipping flow grants an item yet
  (summons pay Gold and grant units only).

**Scope, honestly:** this is the LOBBY's grant path. The Game still grants through AD-Game's
`PlayerInventoryService` / `RewardCalculator`. Invariant 1 holds **within the Lobby only** until
those converge — PENDING in `STATE.md` for AD-Integration.

## Banners

One file per banner in `RS.Configs.Banners`; `BannerRegistry` **auto-scans its own parent folder**,
so shipping a banner is dropping in a file. Shape is the blueprint's, and `Validate()` runs at
`SummonService` boot so a malformed banner is loud immediately, not at a player's first pull.

Shipped: **`Standard`** — Gold, 100/pull, `Pool = "AllSummonable"` (every `Kind == "Tower"` catalog
entry, grouped by tier), `PityRef = "Default"`, `LuckMult = 1`, always open.
Rates: Common .60 · Rare .25 · Epic .10 · Legendary .04 · Mythic .00995 · **Secret .00005**.

`Featured = { Count = 3, RotationPeriod = 3600, Boost = 5 }` — 3 ids redrawn hourly, deterministic
from `Slot` + `RngForSlot(slot, bannerId)`, **secrets excluded** (blueprint). Server and client
derive the identical set from config + clock; the server re-derives at pull time and never takes
the client's word for anything.

> **Boost = 5 is aggressive.** With 2 Commons and Archer featured, Archer takes ~83% of the Common
> tier — measured 49.6% of ALL pulls over 10k. Tune `Boost` in the banner file; nothing else moves.

`BannerType` `Selection` and `Event` are **recognised and validated but refused at summon**
(`banner_type_not_supported_yet`) until B4, rather than half-served with Standard behaviour.

## Summon algorithm

Order is the blueprint's, exactly. Steps 3–8 are `SummonEngine.RollOne` (pure, no profile, no
yielding); 1–2 and 9–11 are `SummonService`.

1. validate currency + window → 2. **spend the whole batch atomically, before any roll** →
3. roll tier (weights × luck) → 4. pity override → 5. pick unit in tier (featured ×Boost) →
6. Shiny → 7. trait-on-summon → 8. StatRolls → 9. `GrantService` → 10. update pity →
11. `Counters.Global.GachaPulls`.

**Why `SummonEngine` is split out of `SummonService`:** the blueprint's B2 requires a 10k dry-roll
odds harness, and a harness can only assert the REAL algorithm if it is requireable. A Script is
not. The split is what stops the harness from becoming a second copy of the logic that drifts.

- **Pity** (`PityConfig.Refs.Default = { Legendary 50, Mythic 400, Secret 15000 }`) — checked
  **Secret → Mythic → Legendary**; if `counter + 1 >= threshold` and the rolled tier is lower, it
  upgrades, highest-priority hit wins. Update is the blueprint taken literally: **reset the hit
  tier, increment the others** — a Mythic does NOT reset the Legendary counter. Counters persist in
  the schema-v2 `Data.Pity[PityRef]` field — **gacha inherited it free, no schema bump**.
- **Empty-pool fallback.** There is no Secret-tier tower, so a Secret roll has nowhere to land. It
  falls to the nearest **lower** stocked tier (down first, up only as a last resort) and is logged.
  The **pity ledger records the AWARDED tier, pre-fallback** — otherwise the Secret counter could
  never reset and every later pull would re-trigger it. `Validate()` reports this as a **content
  gap note**, not an error; it disappears the day a Secret tower is catalogued.
- **Trait-on-summon is INERT in the Lobby.** The trait rarity table is AD-Traits canon in the GAME
  place (`RS.Configs.Traits`); this Place has none, so the lookup finds nothing and units get
  `Trait = nil` — exactly what the starter grant has always done. The RNG draw is still **consumed**
  so the stream does not shift the day the table lands. Do NOT invent a local trait table.
- **`LuckMult` interpretation (recorded — the blueprint declares the key, not its semantics):** it
  multiplies the weight of the **pity tiers only** (Legendary/Mythic/Secret). Multiplying every
  weight would be a no-op, since `Pick` normalises. Shipped at `1` = inert, so nothing observable
  depends on it; confirm before shipping a banner with `LuckMult ~= 1`.
- x1 / x10 only, enforced server-side (`GachaConfig.AllowedPullCounts`). Per-player `busy` guard.
- If a roll cannot resolve a unit at all, the spend is **refunded** and `[CONTRACT]` logged.

## How the reveal happens (user decision, B3)

`RequestSummon` is a **RemoteFunction that RETURNS the granted views**. The client fires the
existing client-side `RS.ClientEvents.ShowRewards` with `result.Rewards` **unchanged** — the views
already carry `Id` + `Level`/`Qty` + explicit `Kind`, which is exactly what B1's reveal reads.

**There is deliberately NO server→client ShowRewards RemoteEvent.** B1 chose client-side-only,
summons are always player-initiated, and a return value needs no new remote surface.
`ObtainRewardsGUI` / `ObtainRewardsController` are **consumed, never modified**.

x10 = ONE remote call, ONE reveal with 10 entries (blueprint: *"one RewardPopup"*).

> **Unsolicited grants (quest completion, daily login, codes) have no answer yet.** They cannot use
> a return value because nobody asked. Do not quietly add a push remote to `SummonService` to serve
> them — it is a real design decision for the session that ships the first one.

## Verified live (B3, real Play, `[Test]`/`[DIAG]` prints in real Scripts)

- **10k dry rolls, `0` distribution failures.** Every tier inside 4σ: Common 5967/6000, Rare
  2557/2500, Epic 992/1000, Legendary 404/400, Mythic 80/99.5, Secret 0/0.5. Shiny 0.870% vs 1.000%
  configured. 60 pity upgrades, 0 pool fallbacks in that seed.
- GrantService: currency, item, **MaxOwned cap** (99999 tickets → granted 9996, total 9999,
  `Capped=true`), tower with opts (L40 shiny Necromancer), **duplicates in one call** (Archer ×2,
  distinct uuids), uncatalogued id refused, negative qty refused, **atomicity** (good+bad → gold
  delta 0), spend + insufficient_funds.
- Pity: forced 49/50 upgraded a Rare roll to Legendary; all-three-due awarded **Secret** and fell
  back to the Mythic pool; `ApplyPity` 10/20/30 → 11/0/31 → 12/1/32.
- End-to-end: x1 and x10 through the real remote → real reveal.
  `ObtainRewards SHOW n=10 cols=5 rows=2 scrollbar=false` — 10 in 2 rows, no scroll.
  Refusals: unknown banner, count 7, count 999999.
- Persisted: units 8 → 22, Gold 50000 → 48800 (100 spend test + 100 + 1000), `GachaPulls` 11,
  **`Summons` unchanged at 1152** (ADR-0008), `Pity.Default` L11/M11/S11.
- Drift **23/23 GREEN** in the Lobby at landing.

## Open

- No gacha UI (blueprint B3) · no Selection/Event flows (B4) · no Index/Codex (B5).
- Trait-on-summon inert until AD-Traits promotes the rarity table.
- Game-side `GrantService` convergence (invariant 1 is Lobby-only today).
- No Secret/Exclusive/Bathala tower exists, so those tiers are unreachable content.
