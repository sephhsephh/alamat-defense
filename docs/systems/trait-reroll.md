# SYSTEM — Trait reroll (token-fed trait gacha)

<!-- owner: AD-Traits | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-30 (B44, live Play) | blueprint: docs/blueprints/phases-b-f-meta.md Phase C -->

Blueprint **Phase C task C1**. Built at **B44 (2026-08-30)**. AD-Traits' row (`OWNERSHIP.md`);
ascension (C3) is AD-Gacha's, and **stat reroll (C2) + worthiness are still AD-Traits' and unbuilt**.

Copies **ADR-0010's NPC-opened-screen shape** exactly — the blueprint already specified "NPC → UI" for
C1, so this is the consistent path, the same shape ascension moved to at B11.

## Where everything lives

| Thing | Path | Notes |
|---|---|---|
| `TraitRerollConfig` | `RS.Configs.Meta.TraitRerollConfig` | ModuleScript — the cost (item id + qty). **Lobby-local** |
| `TraitRerollService` | `SSS.Server.Meta.TraitRerollService` | Script — the remote, the spend, the write |
| `TraitRerollController` | `StarterPlayer.StarterPlayerScripts` | LocalScript — the screen's behaviour |
| the screen | `StarterGui.TraitRerollScreen` | Image-based blockout, restylable (ADR-0010) |
| the NPC | `Workspace.Lobby.NPC_TraitReroll` | placeholder model + `ProximityPrompt` ("Trait Weaver") |
| the remote | `RS.Remotes.RerollTrait` | RemoteFunction |
| the roll table | `RS.Configs.Traits.{TraitRegistry,TraitDefinitions}` | **SHARED canon**, owner AD-Traits (read, never edited) |

## The cost is the TOKEN ITEM, not `Currencies.TraitRerolls`

The blueprint and schema both carry a scalar `Currencies.TraitRerolls`, and it is tempting to spend
it. **It has no source** — nothing in the game grants it — so a reroll priced in it would be
unspendable. What the shop, battlepass and quests actually hand out is the ITEM `TraitRerollToken`
(`Kind = "Item"`, lives in `Data.Items`). So this system spends the token via
`GrantService.SpendItems`, and **this is that token's FIRST sink** — before it, `Data.Items` had
grants (B40's shop, the battlepass) but nothing ever consumed a `TraitRerollToken`.
`Currencies.TraitRerolls` is left untouched, a stale blueprint field with still no source. A
deliberate, documented correction of the blueprint — recorded here and in both the config and service
headers.

`TraitRerollConfig` = `{ ItemId = "TraitRerollToken", Cost = 1 }` — both PLACEHOLDER, retune freely.

## The order, and why a reroll can make a trait WORSE

`RerollTrait(uuid)` on the server: **PRE-CHECK owned → SPEND the token → ROLL → WRITE.** Spend before
the write so a shortfall never changes the trait; roll+write after so a paid roll always lands.

`TraitRegistry.Roll()` is a **weighted gacha** — `None` carries weight 1000 against Blitz/Sniper 80,
Deadeye 25, Godly 3. So the overwhelming outcome is `None`, and **a reroll routinely replaces a real
trait with `None`, or `None` with `None`** — the token is still spent, exactly like a gacha pull that
lands the common. That is the table working, not a failure: the UI says "Rerolled." on a `None` result
and celebrates only a real trait. Worthiness (C2's sibling, unbuilt) is the intended future floor
against this.

## Why the service owns the write, and why it is a DISTINCT writer

`SummonService` writes `UnitInstance.Trait` at **creation**; `TraitRerollService` writes it on a
**reroll** — distinct events with distinct rules, the same way `AscensionService` owns the Ascension
write. The reroll is a `RemoteFunction.OnServerInvoke`; it is server-authoritative (**the client sends
only a uuid**), guarded by a per-user in-flight flag, and returns
`{ ok, Uuid, OldTrait, NewTrait, Balance }`. **A reroll grants nothing** (it consumes), so it never
touches `ShowRewards` / the reveal layer — the new trait IS the return value.

Refusal codes: `bad_uuid` (not a string), `not_owned`, `profile_not_loaded`, `busy`, and
`insufficient_tokens` (mapped from `SpendItems`' `insufficient_items_*`). The cost item is checked
against `ItemCatalog` at boot and **warns loudly** if uncatalogued, since otherwise every reroll would
silently refuse.

## The screen (B44 — Image-based blockout, ADR-0010)

`StarterGui.TraitRerollScreen` + `StarterPlayerScripts.TraitRerollController`. **Reachable only by
walking up to `Workspace.Lobby.NPC_TraitReroll` ("Trait Weaver") and using its ProximityPrompt,**
which fires `ClientEvents.OpenTraitReroll`. Full instance contract: `docs/specs/2026-08-30-trait-reroll-screen.md`.

- Frames/backgrounds are **ImageLabel/ImageButton with a blank `Image` and a dark fill**, so the user
  drops art in later without touching the controller. The controller reads only the spec'd names.
- **It owns its own picker** — every owned unit (any tower can be rerolled), `Kit.UnitIconV2` clones
  sorted rarest-first then name then uuid, the level badge repurposed to show the unit's CURRENT trait
  DisplayName. `ResetOnSpawn = false`, so there is nothing to re-bind.
- **The token balance and each unit's current trait both come off `GetUnitViews`** — the single Lobby
  read path (ADR-0004): `res.Items[TraitRerollToken]` and `res.Units[uuid].Trait`. No second read
  path, no second remote. The detail pane shows the current trait (name + description + rarity colour),
  the cost, and the REROLL button, which **disables when the balance is below the cost.**
- After a reroll the picker rebuilds (badge + balance are now stale) keeping the same unit selected,
  and the result line shows `old → new`.
- The NPC is a **placeholder blockout** (cloned from `NPC_Ascension`, retinted). Restyle it freely —
  the controller only looks for a `ProximityPrompt` anywhere under `NPC_TraitReroll`.
- **Studio harness:** `DevOpen` (opens with no walk-up), `DevSelect` (a uuid, through the same
  `select()` a click runs), `DevReroll`. All left OFF/empty.

## Verified live (B44, real Play)

Backend, through the real `RerollTrait` remote invoked from a real client: a reroll spent exactly 1
token (5→4) and wrote the new trait to the profile; further rerolls walked 4→0; **refusals** —
`bad_uuid` (non-string), `not_owned` (fake uuid), `insufficient_tokens` at balance 0 — each changed
nothing. A real **Blitz** landed on one roll and was then rerolled back to `None` (traits can be lost),
confirming both the upgrade path and the weighted table. Screen: opened to 8 units, selecting rendered
the current trait, REROLL spent a token and updated the result live, and the button **disabled at
balance 0**. Boot clean (`TraitRerollService ready`, no uncatalogued-item warning; `TraitRerollController
ready`; NPC prompt wired "Trait Weaver"); watchdog green. Config, service and controller were each
parse-pre-flighted (wrap-and-require) before the run.

Lobby-local; no shared canon changed, **no schema bump** (`Data.Items` and `UnitInstance.Trait` both
pre-existed).
