# crafting — fragments -> artifacts -> rainbow (Lobby meta, AD-Meta/AD-Gacha)
<!-- owner: AD-Meta/AD-Gacha | scope: lobby (items shared) | added: 2026-09-02 (B50, Phase D/D1) -->

Blueprint Phase D / D1. Combine crafting **fragments** into colour **artifacts** (2:1), then all 7
colour artifacts into the **Rainbow** artifact.

## The items (shared ItemCatalog bump, B50)
15 new `Kind="Item"` entries, added to the SHARED `ItemCatalog` and deployed byte-identical to BOTH
Places (`9be86a5f → 2ee5f976`, 36/36 verified; **user republishes both**):
- `Fragment{Red,Orange,Yellow,Green,Blue,Indigo,Violet}` — Rare.
- `Artifact{Red..Violet}` — Epic.
- `ArtifactRainbow` — Mythic.
Icons are PLACEHOLDER `rbxassetid://0` (author later), like StatRerolls. **Artifacts are OWNED ITEMS;
their gameplay effect is DEFERRED** — what an artifact *does* (equip, bonus, cosmetic) is a later design
decision, so today they are craftable + owned but otherwise unexercised (like Titles/Spirits).

## Pieces (all Lobby-local except the shared items)
| piece | what |
|---|---|
| `RS.Configs.Meta.CraftingRecipes` | PURE, replicated. `{ Out={Id,Qty}, In={{Id,Qty}} }` list: 7× (2 fragments → 1 colour artifact) + (7 colour artifacts → 1 Rainbow). The screen requires it directly for the recipe list. |
| `SSS.Server.Meta.CraftingService` | validates the recipe, then **spends inputs + grants output through `GrantService`** (the one grant/spend path). Owns `GetCraftInfo` + `Craft`. |
| `RS.Remotes.{GetCraftInfo, Craft}` | authored RemoteFunctions (Remotes 38 → 40). |
| `StarterGui.Crafting` + `CraftingController` | blockout screen (recipe rows); opens from `Workspace.Lobby.NPC_Craft`'s ProximityPrompt (a clone of NPC_Ascension, the reroll pattern, ADR-0010) + `ClientEvents.OpenCrafting`. |

## The order: PRE-CHECK → SPEND → GRANT
`Craft(outId)` collapses the recipe inputs into an `{ [itemId]=qty }` map and calls
`GrantService.SpendItems` — **all-or-nothing** (every input checked affordable before any is taken), so
a shortfall takes nothing (`insufficient_items_<id>`). Then `GrantService.Grant` gives the output; it is
a catalogued Item so it cannot refuse, but a refusal is surfaced, not swallowed. Reveal = the return
value (`ShowRewards`), like every other grant.

## Server contract
```
GetCraftInfo() -> { ok, Items = { [id]=count } } | { ok=false, reason }
Craft(outId)   -> { ok, Out={Id,Qty}, Rewards=views } | { ok=false, reason }
```
Reasons: `no_such_recipe` · `insufficient_items_<id>` · `grant_failed` · `profile_not_loaded` · `bad_request`.

## Fragment source
- **NOW (interim, B50):** 7 fragments in `ShopConfig` (100 Silver, weight 3 each) — closes a loop:
  sell dupes → Silver → buy fragments → craft. Placeholder price/weight.
- **LATER (the real source):** the D2 challenge stage (Game place) drops fragments at match end —
  `docs/proposals/2026-09-02-d2-challenges.md`. The reward ids are already catalogued in both Places,
  so the Game grants them with no new catalog work.

## Screen contract (controller reads ONLY these names)
`Main` · `Overlay` · `Main.CloseButton` · `Main.List` (ScrollingFrame) · `Main.List.RecipeTemplate`
(Visible=false) with `OutputLabel` / `InputsLabel` / `CraftButton` · `Main.EmptyLabel`.

## Verified live (B50)
`ItemCatalog.Validate` clean (29 entries), 8 recipes correct. Granted fragments → `Craft("ArtifactRed")`
spent 2 FragmentRed and granted 1 ArtifactRed; crafting again with 0 fragments refused
`insufficient_items_FragmentRed` (nothing taken); the 7-input Rainbow refused a missing colour. The
screen rendered the recipe list with per-recipe "have N" affordability and craft buttons.

## Cross-refs
`docs/contracts/save-schema.md` (Items map) · `gacha.md` (GrantService — the spend/grant path) ·
`shop.md` (the interim fragment source) · `docs/proposals/2026-09-02-d2-challenges.md` (the real source).
