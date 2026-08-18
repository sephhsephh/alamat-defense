# SYSTEM — Gacha (banner engine + the grant pipeline)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby (MetaMath is shared) -->
<!-- last-verified: 2026-08-18 (B30, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md -->

Engine built at **B3** (the blueprint's B1 + B2 session-tasks, done together by user decision).
The **summon UI** landed at **B6** (`docs/systems/lobby-ui.md` — this doc was left stale by that
session and was corrected at B7). **Event banners went live at B7.**

Blueprint status: B1 ✅ · B2 ✅ · B3 (summon UI) ✅ · **B4 ✅ COMPLETE — Event B7, Selection B30** ·
B5 (Index/Codex) ✅ (B8).

**Selection banners went live at B30**, once schema v3 (B29) gave the player's pick somewhere to
live. Turning them on really was the one line the B7 note promised — `Selection` into
`SUPPORTED_TYPES`. The rest of that flow has its own doc: `docs/systems/gacha-selection.md`.

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
| Selection-only pieces | `BannerChoiceService`, `ChooseBannerUnit`, `SelectionAncestors` | see `docs/systems/gacha-selection.md` |

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

> **Boost = 5 is aggressive.** With 2 Commons and Archer featured, Archer takes ~83% of its tier —
> measured 49.6% of ALL pulls over 10k. Tune `Boost` in the banner file; nothing else moves.

### Which banner types are summonable — ONE source of truth (B7)

`BannerRegistry.SUPPORTED_TYPES` (**all three since B30**: `Standard`, `Selection`, `Event`) is read by **both**
`SummonService` (to refuse) and `SummonController` (to grey the card out), so the server and the
screen can never disagree about what is pullable. `BannerRegistry.BlockedReason(cfg)` returns the
single player-facing string for *why*, and the screen delegates to it — B7 removed the hardcoded
`BannerType ~= "Standard"` test from the UI (AD-UI canon, changed with the user's authorisation).
**Adding a banner type is now a registry change and nothing else** — B30 turning Selection on
really was this one line, with no change to the service's refusal path or the screen's card.

## Event banners (B7) — a banner with a `Window`

There is no separate "event system". An Event banner is an ordinary banner that carries a `Window`,
and **running an event is editing two numbers**:

```lua
Window = { StartUtc = 1785542400, EndUtc = 1788220800 }  -- absent or {} = always open
```

Every server opens and closes it at the same instant off the clock alone — no scheduler, no
MessagingService, no deploy. Dropping in another file makes a second event, with no code change.

- `BannerRegistry.WindowState(cfg, nowSec?)` → `"Open" | "NotStarted" | "Ended"` plus seconds until
  the next change. `IsOpen` is now a thin wrapper on it.
- `SummonService` refuses with **`banner_not_started`** (carrying `SecondsUntilOpen`) or
  **`banner_ended`** — two different situations to a player, so two codes rather than one flat
  `banner_closed`.
- `BannerRegistry.EndsInText(cfg)` gives an open, time-limited banner its *"Ends in 22d"* countdown.
- `Validate()` rejects a malformed window at boot (non-number bounds, `EndUtc <= StartUtc`) and
  *notes* a valid banner that is currently outside its window — that looks identical to a broken
  one otherwise.

**Shipped: `EventFirstLight` ("Festival of First Light")** — Gold at 120/pull, 2 featured on a
**daily** rotation with Boost 4, `PityRef = "Default"` (shared with Standard on purpose: a player
grinding an event should not have hard-pity progress stranded when it ends), window
2026-08-01 → 2026-09-01. Rates are richer than Standard at the top (Mythic 2% vs 0.995%), which is
what justifies the higher cost.

**It is also the first CURATED pool** — the explicit `Pool = { [tier] = { ids } }` form, which
Standard's `"AllSummonable"` never exercised. It **excludes Farm on purpose** (a support tower is a
dud as a prize) and carries no `Secret` weight, so it avoids Standard's empty-pool content-gap note.

> **Currency:** Gold, not an event token. `Currency = { Event = tokenId }` parses and validates, but
> nothing can spend it — a token needs a catalogued id and `ItemCatalog` is SHARED canon — so
> `SummonService` refuses a table currency with `unsupported_currency` rather than half-serving it.

### Rotation slots use the configured reset hour (B7 fix)

`FeaturedFor` offsets its slot by `MetaConfig.ResetOffsetSec`, not `0`, so a **daily** rotation flips
at the game's 16:00 UTC day boundary rather than at midnight UTC. Verified. (B3 passed `0`, which was
invisible while every banner was hourly; the fix moved Standard's trio once. See CHANGELOG B7.)

## Selection banners (B30) — LIVE, full doc: `docs/systems/gacha-selection.md`

A **Selection** banner (`Featured.PlayerChoice = true`) is the one banner whose featured set is NOT
derivable from config + the clock: it contains **the player's own stored pick**, save-schema v3's
`BannerChoices[bannerId] = { TowerId, ChosenAtDay }`. `ChosenAtDay` is a `MetaMath.Slot` DAY NUMBER,
never a timestamp. `Server.Meta.BannerChoiceService` (via `RS.Remotes.ChooseBannerUnit`) is its ONE
writer; `BannerRegistry.FeaturedForPlayer` resolves the set and `SummonService` hands it to
`BuildContext` as an override. Shipped: **`SelectionAncestors`**. Everything else — the API, the
refusal codes, the UI, the cooldown rule — is in the split doc above.

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
- **Trait-on-summon is LIVE since B12 (2026-08-09).** The trait rarity table
  (`RS.Configs.Traits.{TraitRegistry,TraitDefinitions}`) was promoted to SHARED canon, so the Lobby
  can finally roll traits. The lookup stays lazy + optional, and the RNG draw is still **consumed
  unconditionally**, so the stream does not shift with the table's presence. Do NOT invent a local
  trait table.
  - **API is `TraitRegistry.Roll(rng)`. There is NO `RollTrait`** — this module assumed that name
    from B3, and because the call sits inside a `pcall` it failed **SILENTLY**: every summon got
    `Trait = nil` and nothing ever reported it. The failure path now `warn`s once per server.
  - **Measured over 20k rolls:** 15% enter the trait branch (`GachaConfig.TraitOnSummonChance`), but
    the table is ~84% `None`, so a REAL trait lands on **~2.4% of all summons** — Blitz/Sniper ~1%
    each, Deadeye ~0.33%, Godly ~0.045%. Tune `TraitOnSummonChance` knowing it is multiplied by
    that ~16%, not applied to the real-trait rate directly.
  - A `"None"` roll is normalised to **nil**, not stored. Otherwise ~12.7% of all summons would
    persist the sentinel STRING while every other grant path writes nil, and `Trait ~= nil` would
    quietly stop meaning "has a trait".
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

## Verified live

**B3** (real Play, `[Test]`/`[DIAG]` prints in real Scripts): 10k dry rolls, **0 distribution
failures**, every tier inside 4σ; GrantService across currency/item/MaxOwned-cap/tower-with-opts/
duplicates-in-one-call/atomicity/spend; pity forcing and `ApplyPity`; x1 and x10 through the real
remote into a real reveal; persistence (`GachaPulls` counted, `Summons` untouched — ADR-0008).
**B30** (Selection): server refuses `choice_required` with nothing stored, `not_in_pool` for Farm,
writes `nil → Necromancer` at day 20682 and the value lands in the PROFILE, a re-pick returns
`Unchanged` **without** rewriting `ChosenAtDay`, a different unit the same day is refused
`choice_on_cooldown` `DaysLeft=1`, client and server featured lists **MATCH** on every read, and a
real x10 pull spent 1300 Gold and tagged `FEATURED` on the boosted ids.
Full figures: `CHANGELOG.md` (B3, B30). Drift GREEN in the Lobby at both landings.

## The UI on top of this (B6 — blueprint task B3 DONE)

`StarterGui.SummonScreen` + `SummonController` (AD-UI, `docs/systems/lobby-ui.md`). It reads
`BannerRegistry` / `GachaConfig` **directly** — which is what this module's ReplicatedStorage
placement was for — and sends only a banner id and a pull count. Opened by firing
`RS.ClientEvents.OpenSummon`, so the blueprint's NPC is a later drop-in with no screen change. It
consumes `RequestSummon`'s return value and passes `result.Rewards` to `ShowRewards` unchanged,
exactly as the reveal contract above specifies.

## Open

- ~~No gacha UI~~ **built at B6** · ~~no Selection/Event flows~~ **both DONE** (Event B7,
  Selection B30) · ~~no Index/Codex~~ **built at B8**. Blueprint task B4 is COMPLETE.
- Trait-on-summon: **DONE at B12** — rarity table promoted to shared canon, traits roll for real.
- Game-side `GrantService` convergence (invariant 1 is Lobby-only today).
- No Secret/Exclusive/Bathala tower exists, so those tiers are unreachable content.
