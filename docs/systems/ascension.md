# SYSTEM — Ascension (dupe-fed power tiers)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-09 (B11, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md Phase C -->

Blueprint **Phase C task C3**, ascension half. Built at **B9 (2026-08-09)**.
**The sell-dupes half shipped at B31** — see the section at the bottom.

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

## Sell dupes (blueprint C3's other half) — BUILT at B31, 2026-08-19

Prices are SHARED canon: `TierConfig.SellValueByTier` + `GetSellValue(tier)`, deployed and
hash-matched in BOTH Places (`eee2b3ad`). Silver by tier — Common 10, Rare 25, Epic 60,
Legendary 150, Mythic 400, Secret 1000, Exclusive 1500, Bathala 3000. **Retune that one table, never
the callers.** `GetSellValue` falls back to **0** for an unknown tier, deliberately unlike
`GetColor`/`get` which fall back to Common, because this one pays currency and an unknown tier must
never mint Silver — `UnitConsumeRules` refuses a 0-value unit rather than destroying one for nothing.

**`Server.Meta.UnitConsumeRules` is now THE ONE DEFINITION of "may this unit be destroyed."** Both
destroyers call it: ascension's `PickDupe` (which used to carry the condition inline) and the sell
path. A second copy is how "locked means safe" quietly stops being true on one of the two paths.
It is a requireable ModuleScript for the same reason `AscensionRules` is split from its Script —
`RemoteFunction.OnServerInvoke` is write-only, so a rule inside a handler cannot be called from a
`[Test]` harness, and "which unit do we permanently destroy" must be directly testable.

- `Reason(data, uuid, equipped?)` → nil, or a code in FIXED precedence:
  `bad_uuid → not_owned → locked → favorited → equipped → has_spirit`. `has_spirit` is unexercised
  and deliberate: `SpiritUuid` has no writer yet, and destroying the unit holding one would orphan a
  `Data.Spirits` record silently.
- `EquippedSet(data)` is exposed so `PickDupe` builds it once for its whole loop.
- `Quote(data, uuids)` is the ONE arithmetic the confirm dialog, the refusal and the write all use —
  B9's lesson, stated in `AscensionRules`' header. It also refuses a **repeated uuid**
  (`duplicate_uuid`), which would otherwise be credited twice and destroyed once, and caps a batch at
  `MaxBatch = 100`: a client can send any list it likes, so an unbounded batch is an unbounded write.

**`GrantService.SellUnits` is the only code in the project that deletes a `Data.Units` record.** It
lives in `GrantService` for the reason `Spend` and `SpendItems` do — invariant 1 puts every currency
write there, and the destruction has to sit beside the credit or the two could come apart. It
**credits first and destroys second**, deliberately: `Grant` validates and can refuse, while the
deletion is plain table writes that cannot fail, so the other order could destroy a player's units
and then fail to pay for them. `RS.Remotes.SellUnits` (Remotes 18 → 19) and the thin
`Server.Meta.SellService` are the remote; **the client sends a list of uuids and nothing else.**
Every completed sale prints one `[DATA] SOLD` line naming each uuid and its price — selling is
irreversible, so that log is part of the feature.

**UI: multi-select in the Units screen** (blueprint C3's own words, and the user's explicit call at
B31 over ADR-0010's NPC shape). `Main.Bottom.QuickSellButton` — which **does exist** and always did,
under `Bottom`, not under `SelectedUnitFrame` — is now one button with three states: `Quick Sell` →
`Cancel` (armed, nothing ticked) → `Sell 3 - 285 Silver`. Pressing the third opens the authored
`SellConfirm` panel, which lists every unit by name, tier, level and price; only that panel can fire
the remote, so a destructive action never happens on the click that armed it. Ticked cards stay
popped with their `UIHoverStroke` on (the existing selected-marker rule); ineligible cards are dimmed
via the root ImageButton's own colour and transparency and stay CLICKABLE, because a dim cannot say
why — clicking one writes the reason to `Main.Bottom.SellStatus`. **Nothing is added to
`Kit_UnitIconV2`; it is hashed canon.** The Silver comes back through `ClientEvents.ShowRewards`
unchanged (user decision) — the same reveal every other grant uses, no second path.

Harness: `UnitsGUI.DevSell`. `"uuidA,uuidB"` arms and opens the confirm without selling; a leading
`!` commits. It ticks through `toggleSell`, not straight into the selection set, so it cannot tick a
card the button would refuse.

Note the standing tension with ascension: a Mythic dupe is ALSO the material this system consumes,
which is why its sell price is high enough to make selling one a real decision rather than free money.
