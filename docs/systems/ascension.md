# SYSTEM — Ascension (dupe-fed power tiers)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-09 (B11, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md Phase C -->

Blueprint **Phase C task C3**, ascension half. Built at **B9 (2026-08-09)**.
**The sell-dupes half is NOT built** — see "Deferred" at the bottom.

Phase C's other tasks belong to **AD-Traits** (trait reroll C1, stat reroll C2 — the blueprint's own
Phase C header says so, as does `OWNERSHIP.md`). Ascension is AD-Gacha's row.

## Where everything lives

| Thing | Path | Notes |
|---|---|---|
| `AscensionRules` | `SSS.Server.Meta.AscensionRules` | ModuleScript — the DECISION logic |
| `AscensionService` | `SSS.Server.Meta.AscensionService` | Script — remotes, writes, spend |
| `AscensionController` | `StarterPlayer.StarterPlayerScripts` | LocalScript — the screen's behaviour |
| the screen | `StarterGui.AscensionScreen` | real instances, restylable (B11, ADR-0010) |
| the NPC | `Workspace.Lobby.NPC_Ascension` | placeholder model + `ProximityPrompt` (B11) |
| remotes | `RS.Remotes.{GetAscensionInfo, RequestAscend}` | RemoteFunctions (Remotes 13 → 15) |
| config | `RS.Configs.Meta.AscensionConfig` | **SHARED canon** (`59aa8e15`), owner AD-Game |

`AscensionConfig` was **read, never edited** — it is shared canon in both Places.

## The config says something different from the blueprint, and the config won

The blueprint says the cost is *"1 dupe … + items + Silver via AscensionConfig"*. The shipped
config carries `Cost = { Dupes = 1, Items = {} }` at every level and **has no Silver field at all**.

This system implements **the config**, because `AscensionConfig` is shared canon owned by AD-Game
and adding a Silver cost would be a shared-module change spanning both Places — not a Lobby-only
session's to make. The Items path IS implemented and tested; it is simply unexercised because every
level ships `Items = {}`. If a Silver cost is wanted, AD-Game adds it to the config and
`AscensionService` needs one more branch.

`MinTier = "Mythic"`, `MaxLevel = 3`, DMG multipliers A1 ×1.05 · A2 ×1.5 · A3 ×3.0 (absolute, not
cumulative). Tier eligibility is `TierConfig.GetSortOrder(tier) >= GetSortOrder(MinTier)`, so adding
a tier above Mythic needs no code change.

## The dupe rule is the dangerous part

**Ascending permanently destroys one of the player's units.** Everything about choosing it is
server-side and deliberately conservative. `AscensionRules.PickDupe` skips:

- the unit being ascended (obvious, and the first thing a bug would do)
- anything that is not the same `TowerId`
- anything **Locked**, **Favorited**, or **currently in `Data.Loadout`**

> The blueprint names locked and unfavourited. **Equipped was added here**: eating the unit someone
> is about to play with is the same class of mistake, and `Data.Loadout` is the only record of that
> intent.

Among survivors it takes the **OLDEST by `ObtainedAt`**, with **uuid as a stable tiebreak** — so two
units saved in the same second cannot make the pick differ between the preview and the commit.

**Confirmation is enforced server-side.** `RequestAscend(uuid, expectedDupeUuid)` re-derives its own
pick and **refuses with `dupe_changed`** if it no longer matches what the player was shown (they
favourited it in another tab, equipped it, the profile moved). Omitting the confirm entirely gives
`confirm_required`. The client's chosen uuid is never trusted — it is only ever compared.

Order of operations on commit: **items first, dupe second.** A shortfall on materials must not leave
the duplicate already destroyed.

## Why `AscensionRules` is split out of `AscensionService`

**`RemoteFunction.OnServerInvoke` is write-only** — you cannot read the handler back to call it, so
logic living inside a remote handler is unreachable from a `[Test]` harness. The most dangerous rule
in the feature is *"which unit do we permanently destroy"*, and it has to be testable directly.
Same split, same reason, as `SummonEngine` / `SummonService`.

It also guarantees **one implementation** shared by the preview and the commit. If each picked its
own dupe, a player could be shown one unit and charged another.

## `GrantService.SpendItems` (new at B9)

The inverse of an Item grant, added for the material cost. It lives in `GrantService` for the same
reason `Spend()` does: cross-phase invariant 1 says every grant flows through that module, and a
consumption that bypassed it is exactly the write the invariant's grep exists to catch.
All-or-nothing like `Grant`, and spending to zero stores **`nil`, not `0`**, so the map keeps
matching what a never-granted item looks like.

## The screen (B11 — moved out of the Units GUI, ADR-0010)

`StarterGui.AscensionScreen` + `StarterPlayerScripts.AscensionController`. **Reachable only by
walking up to `Workspace.Lobby.NPC_Ascension` and using its ProximityPrompt.**

B9 originally built this as a pane inside `UnitsGUI…SelectedUnitFrame`, per the blueprint. The user
moved it out at B11 — and it makes Phase C *consistent*, since the blueprint already says "NPC → UI"
for the trait reroll (C1) and stat reroll (C2). Ascension was the odd one out. See **ADR-0010**.

- **It owns its own picker** — Mythic+ only (`AscensionConfig.MinTier` via `TierConfig` ordering),
  sorted by ascension level then name, entries are `Kit.UnitIcon` clones with the `LevelBadge`
  repurposed to show `A0`–`A3`. Because the list is its own, ascending just rebuilds it: **B9's
  "reopen Units to refresh" caveat is gone.**
- **No re-binding.** `ResetOnSpawn = false`, so unlike the old pane (which lived inside
  `UnitsGUI`, the only meta screen with `ResetOnSpawn = true`) the instance persists for the session.
- **AD-UI's `UnitsController` is not involved any more.** B9's one-line selection publish
  (`selectedFrame:SetAttribute("Uuid"/"TowerId")`) **stays** — unused by ascension now, but C2 and
  C4's panes will want exactly it.
- **`ClientEvents.OpenAscension`** is the entry point; the prompt has no special privilege, so a
  second NPC or a HUD button is a drop-in. `DisplayOrder = 70`.
- The NPC is a **placeholder blockout** (pedestal + neon body + halo + nametag). Restyle it freely —
  the controller only looks for a `ProximityPrompt` anywhere under `NPC_Ascension`.
- **Studio harness:** `DevOpen` (opens with no walk-up), `DevSelect` (a uuid, through the same
  `select()` a click runs), `DevAscend`. All left OFF/empty.

## Verified live (B9, real Play, `[Test]` harnesses since deleted)

Dupe rule: oldest picked correctly · **Locked skipped** · **Favorited skipped** · **equipped
skipped** · never the unit itself · Common refused with *"Mythic+ units only"*.
Commit: **stale confirm → `dupe_changed`** (dupe still alive afterwards) · missing confirm →
`confirm_required` · real ascend consumed **exactly** the previewed uuid · A1→A2→A3 · further
attempts refused *"Fully ascended"* · consumed units gone from `GetUnitViews` · unit count −3 ·
`Counters.Global.Ascensions` incremented.
`SpendItems`: partial spend · insufficient leaves the count **unchanged** · atomic (good+bad) leaves
it **unchanged** · spend-to-zero stores `nil`.
Pane: renders for a Mythic, **hidden for a Common**, and a maxed unit reads **`DMG x3.00`**.

**Re-verified at B11 on the new screen:** the pane is gone from `UnitsGUI`; `AscensionScreen` exists
at `DisplayOrder 70`, closed by default; the NPC and its prompt exist (range 12, *"Ascend a unit"*);
opening lists **4 eligible Mythic+ units** and the detail pane reads `A3 / A3  DMG x3.00` with
*"This unit is fully ascended."*

> **Two bugs this session found in its own work, both worth remembering.**
> 1. `local a, b: T?, T?` is a **syntax error** in Luau — one type per declaration. It stopped the
>    whole controller compiling, and the only symptom was a pane that silently never appeared.
> 2. `BuildInfo` returned early at max level *before* computing `CurrentMult`, so a fully-ascended
>    unit displayed **`DMG x1.00`** — telling the player their three ascensions had done nothing.
>    What a unit is worth NOW does not depend on whether it can ascend again.

## Deferred

**Sell dupes** (the other half of blueprint C3) is **UNBLOCKED since B12 (2026-08-09)**:
`TierConfig.SellValueByTier` and `TierConfig.GetSellValue(tier)` are shared canon, deployed and
hash-matched in BOTH Places. Silver by tier — Common 10, Rare 25, Epic 60, Legendary 150,
Mythic 400, Secret 1000, Exclusive 1500, Bathala 3000; **retune that one table, never the callers**.
`GetSellValue` falls back to **0** for an unknown tier (deliberately unlike `GetColor`/`get`, which
fall back to Common) because this one pays currency and an unknown tier must never mint Silver.

Still to build: `UnitsGUI` has an unwired `QuickSellButton` waiting, plus a `GrantService` sell path,
with Locked / Favorited / in-Loadout units unselectable. Note the tension with ascension — a Mythic
dupe is ALSO the ascension material this system consumes, which is why its sell price is high enough
to make selling one a real decision rather than free money.
