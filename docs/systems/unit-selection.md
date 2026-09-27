# The selected-unit panel (GAME)

<!-- owner: AD-UI + AD-Game | scope: game | added: B86 -->

Click a placed tower and this is what opens. Built at **B86** from the user's reference screenshots,
replacing the plain text panel that shipped with the original selection UI (that one is still in the
tree, hidden and tagged `RetiredB86`).

All of it is **authored instances** under `StarterGui.TowerSelection.Root`, everything tagged
`B86Built`. `Client.UI.TowerSelectionUI` only ever reads and fills them — no GUI is built in script,
and the three templates under `TowerSelection.Templates` mean one edit in Studio changes every clone.

## What is on it

| Region | Shows |
| --- | --- |
| `PortraitCard.Viewport` | the unit's rig, playing its idle, framed like a hotbar slot (B87) |
| `PortraitCard.Badges` | trait and element, hidden when the unit has neither |
| `PortraitCard.IconStrip` | range toggle (real), VFX toggle and info (placeholders) |
| `PortraitCard.PriorityRow` | Unit Priority with prev/next arrows |
| `PortraitCard.SellButton` / `UpgradeButton` | both carrying their price |
| `StatsCard.StatRows` | DMG / SPA / RNG / CRIT% / CRIT DMG / INC, each `current -> next` |
| `TilesRow` | TOTAL DMG, TAKEDOWNS, DPS, eDPS |
| `AbilityColumn` | the ability + its auto-cast, hidden for units without one |
| `UpgradeBar` | one clickable segment per tier |
| `HotkeyRow` | E / T / Z reminders |

The portrait reuses the **shared** `UIKit.UnitCard.viewport` + `playIdle` rather than growing a third
viewport implementation, so it frames and animates exactly like the hotbar and every Lobby screen.
The rig is re-cloned only when the selected **tower type** changes — re-cloning per repaint would
restart the idle every time a stat ticked.

## DPS is theoretical; eDPS is measured

This catches people out, and the reference does the same thing:

- **DPS** = damage / SPA, straight off the resolved stats (crit included). A property of the build.
  No server involvement — asking for it would be a round trip for arithmetic the client can already do.
- **eDPS** = `TotalDamage / CombatTime / EnemiesHit`. What the unit has actually achieved, spread
  across every distinct enemy it has touched. It *falls* as a match goes on, which is the point: it
  answers "is this unit still earning its slot", where DPS only answers "how hard does it hit on paper".

## `Server.Towers.TowerCombatStats` — the live numbers

A pure observer, like `MatchStatsTracker` next door: it subscribes to signals combat already fires and
never calls into them. It publishes four attributes on each tower model, five times a second:
`TotalDamage`, `Takedowns`, `EnemiesHit`, `CombatTime` (VIRTUAL seconds since its first hit, so the
3x speed button cannot inflate a rate). It also publishes `SellValue`, because the refund is a share
of TotalInvested and the client cannot know that once auto-upgrade or a queue has bought a tier
behind the player's back.

**It is not `MatchStatsTracker`.** That one is the end-of-match scoreboard: per player, started and
stopped by `MatchEndPresenter`, and its per-tower kills are *estimated* at the end by splitting the
player's kills by damage share. Fine for a results screen, useless for a live tile.

**Takedown credit without touching any damage path:** `EnemySpawner.EnemyDied` carries the killing
PLAYER but not the killing TOWER, and threading a tower through every damage call (direct hits,
splash, burn ticks) to fix that would be a change to combat code for a UI tile. So this file
remembers the **last tower to damage each enemy** and credits that one when the enemy dies. Same
answer, zero blast radius. The last-damager table is weak-keyed so a despawned enemy is not pinned in
memory for the session.

It resets between matches without subscribing to the match lifecycle at all: the flush loop drops any
entry whose tower is no longer live.

## The upgrade bar

One segment per tier, sized `1/maxTier` so the bar always fills its width — 3 today, more when the
configs grow, with no code change and no magic number for the count.

### The colour code (the user's)

| Colour | Means |
| --- | --- |
| **BLUE** | the base tier — always segment 1 |
| **GREEN** | a normal upgrade you have bought |
| **ORANGE** | an upgrade you have bought that **changed the attack** |
| **BROWN** | an attack change you have **not** bought yet |
| **GREY** | a normal upgrade not bought yet |

A warm segment always means "the attack changes here", bought or not — you can read where a unit's
behaviour turns over without hovering anything.

⚠ **A tier with no `Attack` of its own INHERITS the one below it** (B78's rule), so "does the attack
change here" cannot be read off a single tier — the effective attack is walked up from tier 1 first.
Without that a Meteor's Cataclysm tier would look identical to a plain stat bump.

⚠ **Not `(26, 26, 34)` for the locked colour** — that is the panel's own background, and an unbought
tier rendered invisible against it. The bar looked like it had one segment instead of three.

### Click buys, hold queues

Exactly what the reference's own footer promises: *"Click to upgrade | Hold to queue auto-upgrade"*.
Both go through one remote, `Towers.RequestUpgradeTo(model, targetTier, queueOnly)`.

- **Click** (`queueOnly` false) buys every upgrade between here and the tier you picked, in one action.
- **Hold** (0.35 s) sets `UpgradeTarget` and `UpgradeQueueService` climbs toward it as cash arrives.

⚠ **THE PURCHASE IS ATOMIC.** The cumulative cost is summed first and spent in ONE `TrySpend`, so a
player who can afford 3 of the 4 steps buys **nothing** rather than landing somewhere they did not ask
for with an empty wallet. The tooltip already showed them the full price; charging most of it for part
of the jump would be a small theft.

**`UpgradeQueueService` is deliberately not part of `AutoUpgradeService`.** Auto-upgrade is a standing
"spend spare cash on this tower forever, up to max", ordered across a player's whole board by
`UpgradePriority`. A queued target is one tower, one destination, and it is DONE when it arrives.
Folding them together would mean teaching the priority scheduler about per-tower destinations, and a
tower with auto-upgrade OFF would still have needed the loop. Both spend through the same atomic
`TrySpend`, so they cannot fight; one step per half virtual-second each, so neither can drain a wallet
inside a frame when a wave reward lands.

## The tooltip system (`Client.UI.Tooltip`)

One shared tooltip, not one per widget — the panel has a tooltip on every stat tile, every icon and
every segment, and a frame each would mean a dozen copies of the same off-screen-clamping arithmetic
and a dozen chances for two to show at once. The frame is authored
(`StarterGui.TowerSelection.Tooltip`); the module only fills and positions it.

**The text is a callback, not a string.** Every interesting tooltip here is live — the cost to reach a
tier, whether a segment is reached, what a trait is doing right now — so `Tooltip.bind(widget, supplier)`
asks for fresh text on hover and again on every repaint. A fixed string would be stale the first time a
wave paid out. A supplier returning nil means "nothing to say", which is how a segment with no cost
stays quiet.

`HideFor(owner)` hides only if that widget is the one showing: the pointer leaving A and entering B can
arrive in either order, and a naive hide would blank the newcomer.

The trait tooltip is built from the trait's **own `StatMultipliers`**, not a written-out description, so
a retune in `TraitDefinitions` can never leave it quietly lying about the numbers.

## Proven live (B86)

Placed Archer, Knight, Farm and Necromancer across two matches:

- Portrait rig framed and animating; badges `G` (Godly) + `F` (Fire) on the Archer, both correctly
  hidden on the trait-less, element-less Knight.
- Stat rows `270 -> 450`, `4.8s -> 4s`, `33.0 -> 36.3`, `10% -> 16%`, with trait chips `(4x)` on DMG
  and `(1.5x)` on RNG; all six rows showing `MAX` in gold at top tier.
- Tiles live: TOTAL DMG climbing 1.90K -> 4.53K -> 6.29K, TAKEDOWNS, DPS 62/s (crit-adjusted
  270 x 1.1 / 4.8) and eDPS diverging from it as the match ran (62 -> 21 -> 18/s).
- Segment tooltip: **"Cost until Upgrade [3]" / "$225" / "Click to upgrade | Hold to queue auto-upgrade"**
  — 75 + 150, the cumulative cost.
- Click-to-jump: tier 1 -> 3 in one action, segments 2 and 3 turning green, `SellValue` 60 -> 195.
- **Atomic spend proven four times**, each deducting exactly the cumulative total: Archer 225
  (570 -> 345), Knight 380 (800 -> 420 and 1425 -> 1045), Necromancer 950 (990 -> 40).
- Hold-to-queue distinguished from a click: immediately after the hold the tower was still **tier 1
  with `UpgradeTarget = 3`** and nothing spent; 2.5 s later it was **tier 3 with the target cleared**.
- Refusals leave the tower alone: target 9 -> `AlreadyMaxTier`, target 1 -> `AlreadyAtTier`, tier
  unchanged both times.

## Not proven live, and why

- **The ORANGE / BROWN segments.** Only the Meteor changes attack (tier 3, Barrage -> Cataclysm) and
  it sits in hotbar slot 5, which is locked at the test account's level — so no Meteor could be
  placed. The rule itself is walked from the config and the other three colours are proven. Click a
  Meteor once slot 5 is unlocked.
- **The insufficient-funds refusal.** Wave income refilled the wallet faster than it could be spent
  down — four jumps in a row turned out affordable. The branch is one line using the same `TrySpend`
  as the existing single-tier upgrade, and the other two refusal reasons are proven.

## Known gaps

- **`VfxToggle` and `InfoButton` are honest placeholders**, tagged `PlaceholderB86`, and their
  tooltips say so. A button that does nothing silently is worse than one that admits it. The info
  button has nothing to show because **there is no passive system in this game** — the reference's
  Passives panel (Unit / Memoria tabs) would be a system from scratch.
- **The ability column holds one ability.** Only Meteor and Warchief have one at all; the reference's
  4-5 icon column needs an ability LIST per tower first.
- **Currency is the peso sign everywhere** since B87 (`CURRENCY`, one constant at the top of the
  controller). The dollar sign is gone from every screen that prints money.
- Every tower has exactly **3 tiers**, so the bar is three segments wide. It grows on its own.


## The unit's name (B87)

The header shows the unit's **bare display name**. The parenthesis is **reserved for an evolved
form** — `Bathala (Awakened)` — and is *not* the trait. B86 put the trait there, which read as though
Godly were a different unit rather than a roll on this one; the trait lives on its badge, with the
full multiplier breakdown in its tooltip.

Nothing fills the parenthesis yet: there is **no evolution, awakening, variant or form concept
anywhere in either Place** (`Ascension` is the dupe-fed stat multiplier, not a second form). When one
exists, `paintPortrait` is the single line that learns about it.

## Viewport framing (B87)

`UIKit.UnitCard.viewport` no longer solves a whole-body fit — it reproduces the hotbar's baked
close-up on every rig preview in both Places. See `hotbar.md` for the framing itself.

⚠ **Roblox's field of view is VERTICAL, so the frame's SHAPE still changes how it reads.** With the
camera byte-identical, this panel still looked different from a hotbar slot because its viewport was
a wide box (aspect 1.39 against the slot's 0.83) — the same unit, just more empty room beside it. The
fix was one `UIAspectRatioConstraint` on the viewport, not a camera change. Delete it if you prefer
the wide frame.
