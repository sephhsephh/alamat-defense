# Build spec — `StarterGui.DailyRewards` (B39)

<!-- owner: user (art) + AD-Gacha (controller) | scope: lobby | for: the Lobby place only -->

**You build the tree. I write `DailyRewardsController` against it.** This is the B26 rule: art cannot
be scripted across, and a ScreenGui is yours. Nothing below is a design instruction — **positions,
sizes, colours, fonts, images and layout are entirely yours.** The only thing I need is the **names**,
the **classes**, and the four flags called out in bold.

---

## The tree

```
StarterGui.DailyRewards                 ScreenGui
│   Enabled = false          <- BOLD: the controller opens it; a screen that boots visible flashes
│   ResetOnSpawn = false     <- BOLD: or it re-clones on every respawn and loses its state
│   IgnoreGuiInset = true
│   DisplayOrder = 8         (Settings is 7, ObtainRewardsGUI is 100 and must stay on top)
│
├── Overlay                             TextButton    full-screen dim; clicking it closes the screen
│                                                     (same job as UnitsGUI.Overlay)
└── Main                                Frame         the panel. Motion.slideIn/slideOut animates THIS
    ├── UICorner                        UICorner
    ├── Title                           TextLabel     e.g. "DAILY REWARDS"
    ├── CloseButton                     TextButton    tag: UIKitButton
    │
    ├── Tabs                            Frame
    │   ├── UIListLayout                UIListLayout  FillDirection = Horizontal
    │   ├── NormalTab                   TextButton    tag: UIKitButton   e.g. Text "DAILY"
    │   └── EventTab                    TextButton    tag: UIKitButton   e.g. Text "EVENT"
    │
    ├── EventHeader                     Frame         I show/hide this with the EVENT tab
    │   ├── EventName                   TextLabel     I write the event's name here
    │   └── EventEnds                   TextLabel     I write "Ends in 3d 04:12:55" here
    │
    ├── Track                           Frame         the row/grid the day cards go into
    │   ├── UIGridLayout                UIGridLayout  (or UIListLayout — your call, either works)
    │   └── DayCardTemplate             Frame
    │       │   Visible = false         <- BOLD: I CLONE this. If it is visible it renders as a
    │       │                              stray 8th card forever. Same rule as CurrencyTemplate.
    │       ├── UICorner                UICorner
    │       ├── UIStrokeWithGradient    UIStroke      + a UIGradient child — I paint the tier here
    │       ├── DayLabel                TextLabel     I write "DAY 1"
    │       ├── IconImage               ImageLabel    I set .Image from ItemCatalog
    │       ├── QtyLabel                TextLabel     I write "x100"
    │       ├── ClaimedTick             ImageLabel    Visible = false — I show it on claimed days
    │       └── ReadyGlow               UIStroke      Enabled = false — I enable it on today's card
    │
    ├── ClaimButton                     TextButton    tag: UIKitButton
    │   └── Label                       TextLabel     e.g. "CLAIM"
    └── ResetTime                       TextLabel     I write "Resets in 11:29:53"
```

---

## What I do to each named part

| you build | I do |
|---|---|
| `Overlay` | close on click |
| `Main` | `Motion.slideIn` / `slideOut`; open state tested with `Motion.isOpen(Main)`, never `gui.Enabled` |
| `Tabs.NormalTab` / `EventTab` | switch tracks; I do not restyle them, so give the selected state its own look if you want one — tell me the property and I will drive it |
| `EventHeader` | hidden on the DAILY tab; hidden entirely when no event is running |
| `Track.DayCardTemplate` | cloned once per day in the cycle, filled, parented to `Track` |
| `ClaimButton` | claims the visible track's reward; disabled-looking when nothing is claimable |
| `ResetTime` | live countdown, ticking every second |

**Do NOT create `DailyRewardsController`.** I write and place that.

## Optional, only if you want them

- A `NoEventFrame` under `Main` (any TextLabel saying "No event running") — I show it on the EVENT
  tab when no event is live. If you skip it I just hide the track and say it on `ResetTime`.
- Extra parts inside `DayCardTemplate` are fine and I will leave them alone. I only touch the six
  names listed.

## If a name is wrong

Nothing breaks silently. Every lookup in the controller is **bounded** and prints the exact missing
path — that is the `need()` rule from B33, when a deleted instance made a whole screen never boot
because a bare `WaitForChild` never times out. A missing part costs that part, never the screen.

## One consequence to be aware of

Right now (B38) `HUD.Right.Buttons.DailyRewardsButton` **claims directly** on click. Once this screen
exists that button will instead **open this screen**, and claiming moves to `ClaimButton`. The HUD
button's own `ResetTime` label keeps its countdown either way.

---

## ⚠ STATUS (B40): this screen was BUILT AS BLOCKOUT, not left waiting

The user's call at B40 reversed the earlier "you author it, I wire it": both servers were finished
and only art was blocking them, so B40 **scripted a plain version of this tree and wired it**, and it
is live now.

**This spec is still the contract.** The scripted tree uses these exact names and flags, and the
controller reads nothing else. So authoring your own version is a **replace, not a rewrite**: build
it however you like, keep the names, delete the scripted ScreenGui, and the controller needs **zero**
edits. If you add a part you want driven, add it here first.
