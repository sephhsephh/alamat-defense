# Proposal — `ObtainRewardsGUI` becomes THE reward-reveal surface; `UIKitRewardPopup` is retired

<!-- author: AD-Game (raised while Studio MCP was down; NOT the owner) -->
<!-- target owner: AD-UI (build) + AD-Integration (the shared-canon retirement) | place: Lobby -->
<!-- raised: 2026-08-08 -->
<!-- status: DECIDED 2026-08-08 (user) on the four questions below. Awaiting AD-UI. -->

## Why this exists and who wrote it

The user built `StarterGui.ObtainRewardsGUI` in the **Lobby** place by hand and described how it
should behave. AD-Game is not the owner of StarterGui screens (`docs/OWNERSHIP.md`: *UI (StarterGui
screens, HUD, panels) → **AD-UI**, both Places*), so per CLAUDE.md's single-writer rule this is a
proposal plus a PENDING, not an implementation. It was written during a session where the Roblox
Studio MCP was disconnected, so **every statement about the GUI's current instance tree is the
user's description, not something verified in Studio.** The implementing session must open the tree
first and reconcile.

## DECISION — 2026-08-08 (user)

1. **`ObtainRewardsGUI` wins. `UIKitRewardPopup` + `Kit_RewardPopup` are RETIRED.** The
   hand-designed screen becomes the real thing.
2. **Place: Lobby only** (gacha pulls, quest claims, daily login all live there).
3. **One grid, MIXED content.** A single popup can show units and items together — a quest paying
   2 gems + 1 unit is one popup, not two.
4. **`UnitTemplate` (child of `RewardsFrame`) replaces `Kit.UnitIcon`** as the unit cell.

## What already exists (verified from the manifest, 2026-08-08)

| Entry | Hash | Kind | Status |
| --- | --- | --- | --- |
| `UIKitRewardPopup` → `RS.Shared.UIKit.RewardPopup` | `82aec138` | module | shared canon, both Places, **NO CALLER** |
| `Kit_RewardPopup` → `RS.UITemplates.Kit.RewardPopup` | `e11a5bf3` | template | shared canon, both Places, **NO CALLER** |
| `Kit_UnitIcon` → `RS.UITemplates.Kit.UnitIcon` | `24281a2b` | template | shared canon, both Places, **PARKED** (ADR-0007) |
| `UIKitItemIcon` / `Kit_ItemIcon` | `b717ebe9` / `ee1ccd33` | module + template | shared canon, **IN USE** by the Lobby Items screen |

`UIKitRewardPopup` was built at A6 explicitly *"for Phase B gacha and was smoke-tested, not wired"*.
Decision 1 means that bet did not pay off — the user designed their own and it is better suited.
That is a normal outcome; the module is retired rather than left as audit noise (the same reasoning
that retired `GetCollection` in ADR-0004).

## This is a SHARED-CANON change — it needs AD-Integration, not a quiet edit

`UIKitRewardPopup` and `Kit_RewardPopup` are deployed **byte-identically in both Places** and are
drift-controlled manifest entries. Deleting them in the Lobby alone is DRIFT. Required order
(`tools/checklists.md`):

1. **Re-grep BOTH Places for callers first.** The manifest says none, and A6/A7 both recorded none —
   confirm it live anyway, exactly as ADR-0004's retirement did, before deleting anything.
2. Delete the controller **and** the template **in both Places**.
3. Remove both entries from `shared/manifest.json`. **Drift goes 24/24 → 22/22.** Update the count
   in `STATE.md`'s Snapshot, `places/*/CONTEXT.md`, and `docs/systems/ui-kit.md`, all of which
   currently say "24 entries = 16 modules + 8 templates".
4. Delete `shared/src/UIKitRewardPopup.luau`.
5. Re-run `tools/hash_shared.luau` in both Places and confirm green at the new count.

**Do not fold this into the AD-UI build session.** Build the screen first against the live
`ObtainRewardsGUI`; retire the kit entries in a separate Integration session once the replacement
is actually working. Retiring first would leave a window with no reveal surface at all.

## `UnitTemplate` → the kit: this is ADR-0007 being fulfilled, not overridden

ADR-0007 parked `Kit_UnitIcon` and said, in terms:

> the question is deferred to **Phase B**, where the gacha summon reveal and the unit index are the
> first features that will genuinely need a unit card — and will therefore tell us what the
> component actually has to do

and that when it is built, **the user's shipping card is lifted into the kit as-is** (the same move
that produced `Kit_HotbarSlot`), with missing kit fields **ADDED to their tree, never used to
replace it**.

The gacha reveal has now arrived and the user has supplied the card. So:

- `UnitTemplate` is lifted into the kit as-is. **Do not redesign it.** If the controller needs a
  field the template lacks, ADD that field to the user's tree.
- Whether it replaces `Kit_UnitIcon` outright or becomes a second template is an **AD-UI call at
  build time**, once both trees are visible side by side. `Kit_UnitIcon` is still PARKED and still
  must not be deleted unilaterally — ADR-0007 stands until a session with Studio access supersedes it.
- Lifting it into the kit makes it shared canon → mirror to the Game place + manifest entry, under
  the same drift procedure as the retirement above. **If AD-UI decides it should stay Lobby-local
  for now, say so explicitly in the changelog** rather than leaving its sharing status ambiguous.

## Layout specification (from the user, 2026-08-08)

`ObtainRewardsGUI.Main.RewardsFrame` sizes itself to its contents.

- **5 columns per row**, always.
- **Width** grows with content: `min(n, 5)` columns wide. Three rewards → a 3-wide frame, not a
  5-wide frame with two gaps.
- **Height** grows with content up to **3 rows**:
  - 1 row → no scrollbar
  - 2 rows → frame expands in Y, still no scrollbar
  - 3 rows → frame expands in Y, still no scrollbar
  - **4+ rows → Y is FROZEN at the 3-row height and the scrollbar appears.** Three rows is the
    maximum visible height, permanently.
- **A small uniform padding** around the grid so the outer cells are not flush to the frame edge.

Derived, for whoever implements it:

```
cols        = min(n, 5)
rows        = ceil(n / 5)
visibleRows = min(rows, 3)

width   = cols        * cellW + (cols        - 1) * gapX + 2 * pad
height  = visibleRows * cellH + (visibleRows - 1) * gapY + 2 * pad

CanvasSize.Y  = rows * cellH + (rows - 1) * gapY + 2 * pad   -- full content, not visible height
scrollbar     = (rows > 3)
```

`cellW` / `cellH` / `gapX` / `gapY` / `pad` must be **read from the designed instances**
(`UnitTemplate.Size`, the `UIGridLayout`'s `CellSize`/`CellPadding`, the `UIPadding`) — never
hardcoded in the controller. That is what keeps the user able to retune spacing in Studio without a
code change.

**The user has explicitly authorised rebuilding `RewardsFrame`'s children** ("I kinda messed around
with the ui childs of rewards frame") — but that permission covers the *container*, **not
`UnitTemplate`**, which is the design being adopted.

## Rules the implementing session must not break

- **NEVER generate UI in scripts** (user rule, 2026-07-18). Every cell is a clone of a REAL
  designed template instance with `Visible = false`. The controller only reads data, clones
  templates, and sets text/visibility/icons.
- The controller takes a **list of reward entries** and picks the unit cell or the item cell per
  entry, since the grid is mixed. Cells must be the same footprint or the 5-column rule breaks.
- Resolve names/icons/tiers from the shared `ItemCatalog` + `TierConfig`, the way
  `UIKitRewardPopup` did — that behaviour was correct and should survive its host. In particular
  **an id missing from the catalog must still render** (fall back to the id, tier Common) rather
  than erroring: a reward the player actually earned must never fail to display.

## DECIDED — 2026-08-08 (user), second round

5. **The ITEM cell is the existing `Kit_ItemIcon`.** No new item template. ⚠ **Footprint risk, and
   it is the first thing to check in Studio:** `Kit_ItemIcon` (`ee1ccd33`) was designed for the
   Lobby's Items *screen*, not for this grid, so its size almost certainly does **not** match
   `UnitTemplate`. A `UIGridLayout` forces one `CellSize` on every child, so a mismatch shows up as
   stretched or letterboxed item art, not as a layout error. Resolve it by sizing the **cell** to
   `UnitTemplate` and letting `Kit_ItemIcon` fit inside it (an inner `UIAspectRatioConstraint` if
   its art must stay square) — **do not resize `Kit_ItemIcon` itself**, it is shared canon in use
   by a shipping screen, and changing it is drift plus a visible change to the Items screen.
6. **Dismiss by clicking anywhere; queue back-to-back grants.** The second popup waits for the
   first rather than merging, so each reward source stays visually distinct. Two consequences to
   build for: the click-catcher must cover the whole screen and must **not** fire on the frame that
   is still animating in (otherwise a fast grinder skips a rare pull with a stray click — put a
   short input-dead period on open), and the caller-facing API is a **queue**, so
   `Show(rewards)` must be safe to call while a popup is already up.

## OPEN — still needs a user answer

1. **Who calls it, and when?** Phase B gacha is the obvious first caller, but quests / daily login /
   codes are all AD-Meta systems that do not exist yet. Recommend AD-UI builds the screen + a
   `Show(rewards)` entry point now, and each system wires itself in as it ships.

## Sequencing

1. **AD-UI (Lobby)** — build the grid controller against the live `ObtainRewardsGUI`; lift
   `UnitTemplate`; answer OPEN #1–#3 with the user. `UIKitRewardPopup` stays in place, unused,
   throughout this step.
2. **AD-Gacha** — first real caller.
3. **AD-Integration** — retire `UIKitRewardPopup` + `Kit_RewardPopup` in both Places, manifest
   24 → 22, and settle the sharing status of the adopted unit card.

**Not blocking B0.** The placement/uuid fix stays the first Phase B task; this is Lobby-side and
independent.
