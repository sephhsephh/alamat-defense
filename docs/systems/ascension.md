# SYSTEM — Ascension (dupe-fed power tiers)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-09 (B9, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md Phase C -->

Blueprint **Phase C task C3**, ascension half. Built at **B9 (2026-08-09)**.
**The sell-dupes half is NOT built** — see "Deferred" at the bottom.

Phase C's other tasks belong to **AD-Traits** (trait reroll C1, stat reroll C2 — the blueprint's own
Phase C header says so, as does `OWNERSHIP.md`). Ascension is AD-Gacha's row.

## Where everything lives

| Thing | Path | Notes |
|---|---|---|
| `AscensionRules` | `SSS.Server.Meta.AscensionRules` | ModuleScript — the DECISION logic |
| `AscensionService` | `SSS.Server.Meta.AscensionService` | Script — remotes, writes, spend |
| `AscensionController` | `StarterPlayer.StarterPlayerScripts` | LocalScript — the pane's behaviour |
| the pane | `UnitsGUI…SelectedUnitFrame.AscensionPanel` | real instances, restylable |
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

## The pane

Real instances at `UnitsGUI.Main.Bottom.SelectedUnitFrame.AscensionPanel` (plain and restylable —
the controller reads nothing but text out of them). **Hidden entirely for a non-Mythic+ unit**: an
always-visible "you can't do this" on every Common is noise.

- **ONE line was added to AD-UI's `UnitsController`** (user-authorised): `selectUnit` now publishes
  `selectedFrame:SetAttribute("Uuid", uuid)` (+ `TowerId`). `selectedId` was a private local, so no
  pane could know which unit was on screen. It is the same idiom `loadUnits` already uses on every
  card, and it pays for Phase C's remaining panes too — stat reroll and feeding need the same thing.
  **That attribute is this controller's entire coupling to the Units screen.**
- **The controller lives in `StarterPlayerScripts`, not in UnitsGUI**, so AD-UI's ScreenGui holds no
  AD-Gacha script. Same split B8 used for the index's button on SummonScreen.
- **It re-binds, and that is not defensive padding.** `UnitsGUI.ResetOnSpawn = true` — it is the
  **only** meta screen set that way (SummonScreen, IndexScreen, ObtainRewardsGUI, ItemsGUI are all
  false), so Roblox destroys and re-clones the PlayerGui copy on every character spawn. A reference
  captured at startup goes stale. Fixing it here rather than flipping AD-UI's property, because that
  property is their screen's behaviour. Confirmed in the live run: `bound to UnitsGUI` printed twice.
- **Known gap:** ascending destroys a card the Units grid is still showing, and this controller must
  not reach into AD-UI's list to refresh it. The status line says *"reopen Units to refresh the
  list"* rather than leaving a ghost card looking real.

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

> **Two bugs this session found in its own work, both worth remembering.**
> 1. `local a, b: T?, T?` is a **syntax error** in Luau — one type per declaration. It stopped the
>    whole controller compiling, and the only symptom was a pane that silently never appeared.
> 2. `BuildInfo` returned early at max level *before* computing `CurrentMult`, so a fully-ascended
>    unit displayed **`DMG x1.00`** — telling the player their three ascensions had done nothing.
>    What a unit is worth NOW does not depend on whether it can ascend again.

## Deferred

**Sell dupes** (the other half of blueprint C3) needs `SellValueByTier` in `TierConfig` — which does
not exist, and `TierConfig` is **shared canon**, so adding it spans both Places. `UnitsGUI` already
has an unwired `QuickSellButton` waiting for it. PENDING in `STATE.md`.
