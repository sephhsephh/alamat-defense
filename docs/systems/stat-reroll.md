# SYSTEM — Stat reroll (currency-fed stat gacha + the Worthiness commit)

<!-- owner: AD-Traits | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-30 (B44, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md Phase C -->

Blueprint **Phase C task C2**. Built at **B44 (2026-08-30)**, the same session as C1. AD-Traits' row
(`OWNERSHIP.md`). Sibling of the trait reroll (`trait-reroll.md`); it copies **ADR-0010's
NPC-opened-screen shape** exactly.

## Where everything lives

| Thing | Path | Notes |
|---|---|---|
| `StatRerollConfig` | `RS.Configs.Meta.StatRerollConfig` | ModuleScript — cost + worthiness threshold/boost. **Lobby-local** |
| `StatRerollService` | `SSS.Server.Meta.StatRerollService` | Script — the remote, the spend, the write |
| `StatRerollController` | `StarterPlayer.StarterPlayerScripts` | LocalScript — the screen's behaviour |
| the screen | `StarterGui.StatRerollScreen` | Image-based blockout, restylable (ADR-0010) |
| the NPC | `Workspace.Lobby.NPC_StatReroll` | placeholder model + `ProximityPrompt` ("Stat Diviner") |
| the remote | `RS.Remotes.RerollStats` | RemoteFunction |
| grades | `RS.Configs.Meta.StatGradeConfig` | **SHARED canon** (read, never edited) — the ONE letter+colour authority |

## The cost is `Currencies.StatRerolls` — and why that DIFFERS from C1

C1's trait reroll spends the `TraitRerollToken` **item**, because `Currencies.TraitRerolls` cannot be
spent the blueprint's way and, more importantly, the token has a live source (Insane wins drop it).
C2 has **no live source either way**, so it follows the blueprint literally — *"reroll spends
StatRerolls"* — and `StatRerolls` **is** a `SCALAR_CURRENCY`, so `GrantService.Spend` debits it with
**no ItemCatalog entry and no shared-canon change.** `Spend` checks only the `SCALAR_CURRENCIES`
whitelist and the balance, never the catalogue, so a source-less currency still debits cleanly.

> **>>> THE FAUCET IS DEFERRED <<<** Nothing grants `StatRerolls` today — it is not even catalogued,
> so `GrantService.Grant` cannot mint it. This reroll is therefore economically **dormant**: the SINK
> is built and verified, the FAUCET is a later cross-Place task, exactly the shape the battlepass XP
> source had before B43. To open the faucet, a future session either catalogues `StatRerolls` as
> `Kind="Currency"` (AD-UI shared canon) so shop/BP/quests/Insane drops can hand it out, or adds a
> `StatRerollToken` item the way `TraitRerollToken` exists for C1.

**⚠ FAUCET OPENED B45.** `StatRerolls` is catalogued (`ItemCatalog`, `Kind="Currency"`) and drops
from **Insane wins** (`RewardScalingConfig.InsaneItems`) — the same faucet `TraitRerollToken` uses.
Before B45 this was a sink with no source: `GrantService.Grant` refuses any uncatalogued id
(invariant 4), so nothing could mint it. See `docs/systems/rewards.md`.

`StatRerollConfig` = `{ CurrencyId = "StatRerolls", Cost = 1, WorthinessThreshold = 100,
TopGradeBoost = 1.0 }` — all PLACEHOLDER.

## What a reroll does, and the order

`RerollStats(uuid)` on the server: **PRE-CHECK owned → SPEND → ROLL → WRITE.** It rerolls all three
`StatRolls` (DMG/RNG/SPA, raw 0..1) with `StatGradeConfig.RollAll`, writes them, and returns
`{ ok, Uuid, OldRolls, NewRolls, OldGrades, NewGrades, Worthy, Balance }`. The client sends only the
uuid; a per-user in-flight flag guards it. **A reroll grants nothing** (it consumes), so it never
touches `ShowRewards` — the new grades ARE the return value. Grades and their colours come from
`StatGradeConfig` ONLY (blueprint: *"Letter derivation + colors: StatGradeConfig only"*); the service
grades the raw roll exactly as `LobbyServices.buildUnitView` does.

Refusal codes: `bad_uuid`, `not_owned`, `profile_not_loaded`, `busy`, `insufficient_rerolls` (mapped
from `Spend`'s `insufficient_funds`).

## Worthiness — the commit half of the meter (blueprint C2)

Blueprint: *"at Worthiness==100: floor each roll at the 'A' threshold + TopGradeBoost luck mult; ANY
reroll sets Worthiness=0."* This service implements exactly that:

- It reads `unit.Worthiness`. At `>= WorthinessThreshold` (100) the reroll is **worthy**: every rolled
  stat is floored so it grades at least **A**, and `RollAll` is passed the `TopGradeBoost` luck mult.
- The **A floor is DERIVED from `StatGradeConfig`**, not hardcoded — it is the Max of the grade just
  below "A" (the exclusive boundary), nudged past it so `GradeForRoll` returns A (0.8201 today).
- **Any** reroll — worthy or not — sets `Worthiness = 0`.

> **Two writers, by design.** The **Game place writes `Worthiness`** during a match (A8, kills → the
> meter); the **Lobby reads it and this reroll RESETS it.** That split is the blueprint's contract,
> not drift — the same shape as the battlepass XP loop, inverted. `TopGradeBoost` is dormant until
> `StatGradeConfig.RollStat` honours its `luck` argument (it ignores it today); the **floor** is the
> concrete, tested effect.
>
> **⚠ CORRECTED B45: the METER IS BUILT, and was already built when this was written.** The line
> here used to call kills → Worthiness "a separate 🔲 on the roadmap", contradicting the sentence
> directly above it. `RewardCalculator.GrantForPlayer` → `PlayerInventoryService.CommitUnitKills` →
> `WorthinessConfig.Apply` has committed it once per match since **A8**, and A9 re-verified it
> independently (Archer 198 kills → 3.96, Necromancer 86 → 1.72). Reaching 100 is a **tuning**
> question, not a missing writer: `PointsPerKill` is 0.02 (the user's choice at A8, reaffirmed at
> B45), so ~5,000 kills caps a unit and a favourite maxes over roughly 25–50 matches. That is the
> intended long-term goal, not a gap.

## The screen (B44 — Image-based blockout, ADR-0010)

`StarterGui.StatRerollScreen` + `StarterPlayerScripts.StatRerollController`, reachable only through
`Workspace.Lobby.NPC_StatReroll` ("Stat Diviner"), which fires `ClientEvents.OpenStatReroll`. Full
instance contract: `docs/specs/2026-08-30-stat-reroll-screen.md`.

- Frames/backgrounds are **ImageLabel/ImageButton with a blank `Image`** — drop art in later, the
  controller reads only the spec'd names.
- **Owns its own picker** (every owned unit), `Kit.UnitIconV2` clones, rarest-first; the level badge
  shows the unit's **DMG grade** at a glance. `ResetOnSpawn = false`.
- **Everything comes off `GetUnitViews`** (ADR-0004): `res.Currencies.StatRerolls` (balance), and per
  unit the raw `StatRolls`, `Grades` and `Worthiness`. No second remote. The detail pane shows the
  three grades (coloured by `StatGradeConfig`), the worthiness meter (with a "next reroll is FLOORED"
  hint at 100), the cost, and a REROLL button that **disables when the balance is below the cost.**
- After a reroll the picker rebuilds keeping the selection, and the result line shows `DMG old→new
  RNG old→new SPA old→new`.
- The NPC is a **placeholder blockout** (cloned from `NPC_Ascension`, retinted). Restyle freely.
- **Studio harness:** `DevOpen` / `DevSelect` (uuid) / `DevReroll`. Left OFF/empty.

## Verified live (B44, real Play)

Backend, through the real `RerollStats` remote from a real client: a normal reroll changed the three
grades and spent 1 `StatRerolls` (5→4); refusals `bad_uuid` / `not_owned` / `insufficient_rerolls`
(balance 0) each changed nothing; with `Worthiness=100` a reroll floored all three raw rolls to
0.8201 → **A/A/A** and reset Worthiness to 0. Screen: opened to 8 units, rendered grades + the
worthiness hint, REROLL updated the per-stat result live, the worthiness label read "FLOORED at grade
A" at 100 and the reroll delivered A/A/A, and the button **disabled at balance 0**. Boot clean
(`StatRerollService ready`; `StatRerollController ready`; NPC prompt "Stat Diviner"); watchdog 32/32.
Config + service + controller each parse-pre-flighted.

Lobby-local; no shared canon changed, **no schema bump** (`StatRolls` and `Worthiness` both pre-existed).

## B108 (2026-09-30) -- grade model v2, two chips, filtered Instant Roll

**Supersedes the D..Apex letters and the per-tower BaseStats ranges above.**

| Grade | Chance | DMG bonus | RNG / SPA bonus |
|---|---|---|---|
| AL (Alamat) | 0.1% | 23-25% | 11.5-12.5% |
| Z+ | 0.2% | 20-22.99% | 10-11.49% |
| Z | 0.85% | 17-19.99% | 8.5-9.99% |
| S | 1% | 14-16.99% | 7-8.49% |
| A | 4.35% | 11-13.99% | 5.5-6.99% |
| B | 23.5% | 8-10.99% | 4-5.49% |
| C | 30% | 5-7.99% | 2.5-3.99% |
| D | 40% | 0-4.99% | 0-2.49% |

- A stored roll (0..1) is a quantile: its grade is the band it falls in (cumulative chances), its % is linear inside that band. `StatGradeConfig.PercentForRoll(stat, roll)`, `RollForPercent(stat, pct)`, `Multiplier(stat, roll)`, `GradeIndex(name)`.
- In match: Damage x(1+p), Range x(1+p), SPA x(1-p) -- the same for every unit (Game `TowerStatResolver`).
- **Stat Chip** = `Currencies.StatRerolls` (rerolls all three). **Focus Chip** = `Items.FocusChip` (rerolls one stat).
- Remotes: `RerollStats(uuid, stat?)`; `InstantRollStats(uuid, stat?, { StopGrade?, MinPct = {DMG?, RNG?, SPA?} }, budget?)` -> `{ ok, OldRolls, NewRolls, OldGrades, NewGrades, Spent, Stopped = hit_filter|out_of_chips|budget, Balance, FocusBalance }`. Refusals: `bad_uuid`, `bad_stat`, `not_owned`, `profile_not_loaded`, `busy`, `no_filters`, `insufficient_rerolls`, `insufficient_focus`.
- Goal rule (pt6, user: ANY): stop when any rolled stat reaches `StopGrade`, OR any rolled stat reaches its `MinPct` (SPA may be sent negative; its magnitude is used).
- Worthiness at >= 100 still floors each rolled stat at grade A (roll 0.9351) and any reroll resets it.
- **Screen (pt6):** `StarterGui.StatRerollGUI` + its `StatRerollController` (authored; see CHANGELOG B108 pt6). Opens from the Stat Diviner NPC or `ClientEvents.OpenStatReroll`. Old B44 controller disabled, `StatRerollScreen` hidden.
- **Chip packs:** `RS.Configs.Meta.ChipPackConfig` (StatChips10/50/100, FocusChips10/50/100; ProductId 0 = shown, not purchasable) + `Server.Meta.ChipPackService` (`GetChipPacks`, `BuyChipPack`; grant via ReceiptService -> GrantService).
- Dev harness on `StatRerollGUI`: `DevOpen`, `DevSelect` ("first"|uuid), `DevAction` ("all"|"focus:DMG"|"instant"|"instant:RNG"), `DevPopup` ("picker"|"chances"|"filters"|"none"), `DevFilters` ("Stop=S;DMG=10").
- ⚠ Any reroll resets Worthiness, and Evolution reads takedowns FROM Worthiness -- so a reroll also resets evolution takedown progress (pre-existing B44 rule; flagged to the user).


## B108 pt11
- Filter grade letters are MULTI-select: `filters.Stops` set -> payload `StopGrades = { ... }`; the server stops Instant
  Roll when any rolled stat's grade is exactly one of them (old `StopGrade` "at or above" still accepted).
- Rerolling a stat that already matches the active filters asks first ("Would you like to reroll S on Damage?").
- Old `StatRerollScreen` + `StarterPlayerScripts.StatRerollController` DELETED.

## B108 pt11c -- AL reveal
Any reroll / instant roll that lands AL on a rolled stat plays `StarterGui.ALRevealScreen` (modal, no skip, ~3.3s,
sound `SoundService.UI.ALReveal`). Grade letters use `UnitCard.paintGrade` (AL animated).
