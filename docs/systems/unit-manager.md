# The Unit Manager (GAME)

<!-- owner: AD-UI + AD-Game | scope: game | rebuilt: B87 -->

Opens with **F** or the HUD's UNIT MANAGER button. Every unit this player has placed on the current
map, as a grid of cards, so they can be managed without hunting for them in the world.

Rebuilt at **B87** from the user's reference screenshots. The old row list is still in the tree,
hidden and tagged `RetiredB87`. All of it is authored instances under `StarterGui.UnitManager.Root`
(everything tagged `B87Built`) plus a `CardTemplate` — edit the template once and every clone
follows. `Client.UI.UnitManagerUI` only reads and fills them.

## A card

| Part | Shows / does |
| --- | --- |
| `Viewport` | the unit's rig, framed like a hotbar slot (shared `UIKit.UnitCard.viewport`) |
| `LevelBadge` | its Lobby level |
| `NameLabel` | the unit's name |
| `UpgradeLabel` | `Upgrade [1/2]`, or `Upgrade [Max]` |
| `ButtonRow.LockButton` | protect from Sell All |
| `ButtonRow.PriorityButton` | the chevron — bumps **upgrade priority** |
| `ButtonRow.SellButton` | sell this one |
| `AutoRow.AutoToggle` | Auto Upgrade on/off |
| `AutoRow.PriorityValue` | the priority number the chevron changes |
| `TargetButton` | opens the targeting dropdown (all nine modes) |
| `SelectButton` | an invisible overlay on the portrait — selects the unit on the map via `SelectionBus` |

`UpgradeLabel` counts **upgrades bought, not tiers**: a fresh unit reads `[0/2]`, not `[1/3]`. That is
what the reference does and it is the more useful number — it answers "how much is left to buy".

## Locking

A locked unit is **skipped by Sell All** and nothing else. Selling it directly still works — a lock
that also blocked the deliberate single sell would just be a second confirmation dialog.

It exists because Sell All is pressed in a hurry between waves, and losing the one unit you spent the
whole match building is not something an "are you sure?" popup prevents; that popup just asks twice
and gets clicked through just as fast.

The button carries it through honestly: the subtitle reads `3 units placed - 1 locked`, and the
**Sell All button itself relabels to `Sell All (2)`** when some are locked. "Sell All" that quietly
spares three units is a lie the player only catches after pressing it.

Server-side: `Towers.RequestSetLocked(model, locked)` sets a `Locked` attribute, and the `RequestSellAll`
handler filters on it and reports `Locked = <count>` back alongside the refund.

## Automation — four saved settings, not match state

The bottom row writes **`SettingsConfig` preferences** (GameOnly, `Kind = "Preference"`), not
match-scoped flags. A standing rule that forgets itself every match is worse than not having one, and
"Auto-Upgrade New Units" resetting every wave would be actively annoying.

Because they are real settings they also appear as rows in the **Settings screen**, under the same
saved keys — so the two surfaces can never disagree. (⚠ A Preference absent from
`SettingsConfig.Schema` is dropped by `Sanitize`, so both the `Defaults` entry and the `Schema` row
are required for one to persist at all.)

| Setting | What it changes |
| --- | --- |
| **Strict Upgrade Order** | `AutoUpgradeService` stops skipping. Off, it buys the first upgrade the player can *afford* down the priority list, so a temporarily expensive priority-1 unit is passed over. On, the highest-priority unit is the **only** candidate and the cash is saved toward it. |
| **Strict Queue Order** | `UpgradeQueueService` serves queued targets **one unit at a time**, oldest queue first, instead of every queued unit climbing in parallel. Parallel is the wrong answer for someone who queued a carry and then a filler — it gets the filler halfway instead of the carry there. |
| **Auto-Upgrade New Units** | a newly placed unit arrives with Auto Upgrade already on. |
| **Auto Abilities on New Units** | a newly placed unit arrives with auto-cast on — only if it *has* an ability; a silent no-op on a Farm is how a setting gets blamed for not working. |

**More Settings** opens the real Settings screen rather than being a fifth toggle pretending to be one.

### Where the "new units" settings are applied

In **`PlacementValidator.TryPlace`** — THE placement path, which both the `RequestPlace` remote and
Auto Play go through (B81). A unit cannot reach the field without passing that point. Doing it in
`TowerController`'s constructor instead would mean a tower reading a player's profile, which is a
tower knowing about settings for no good reason.

### Ordering under Strict Queue Order

`_queuedAt` is stamped on the controller when a target is set, so "oldest" means **the order the
player asked in** — not wherever the tower happens to sit in the placement array, which is a
different thing and would look arbitrary.

## The client is optimistic, the server is the boundary

A toggle flips its local copy and repaints immediately, then the save rides behind it —
`SettingsService` sanitises and is the trust boundary. A rejected save simply never comes back, and
the next open re-reads the truth (`pullSettings` runs on every open, because the Settings screen
writes the same four keys).

⚠ A failed `GetSettings` falls back to `SettingsConfig.Sanitize({})` — **defaults**, not a blank
table. A blank table would read as "everything off" and then save that over the player's real
preferences on their next click.

## Proven live (B87)

- Three cards rendered with portraits, levels, `Upgrade [0/2]`, and each unit's own targeting mode.
- Toggled **Strict Upgrade Order** and **Auto-Upgrade New Units** on; `GetSettings` round-tripped
  from the server showing exactly those two `true` and the other two `false`.
- Locked the Archer: button turned gold, subtitle read `2 units placed - 1 locked`, and the Sell All
  button relabelled to `Sell All (1)`.
- Ran Sell All: `count=1 lockedSkipped=1 refund=90` — **the Archer survived, the Knight was sold.**
- Placed a unit *after* enabling Auto-Upgrade New Units: it arrived `autoUpgrade=true` and had
  climbed to tier 3, while the Archer placed *before* the toggle stayed `false`. An A/B in one match.
- The targeting dropdown opens from a card button with all nine modes.
- `SettingsService` reports **16 preferences in scope** (was 12) and the Settings screen renders 16 rows.

## Not proven live

- **Strict Upgrade Order and Strict Queue Order changing the spending pattern.** Both are one-line
  branches on a setting that is confirmed to reach the server, but watching auto-upgrade actually
  hold cash for a priority-1 unit needs a match arranged so the next upgrade is unaffordable — the
  same wave income that defeated the B86 refusal test gets in the way.
