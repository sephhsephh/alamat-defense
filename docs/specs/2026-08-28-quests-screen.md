# Build spec — `StarterGui.QuestsGUI` (B42)

<!-- owner: user (art) + AD-Gacha (controller) | scope: lobby | for: the Lobby place only -->

**The controller reads ONLY the names below.** This is the B26 rule: art cannot be scripted across a
Place, and a ScreenGui is the user's. Nothing here is a design instruction — **positions, sizes,
colours, fonts, images and layout are entirely the user's.** The controller needs only the **names**,
the **classes**, and the flags called out in bold. Same deal as `2026-08-27-daily-rewards-screen.md`.

Server contract (B40, additive, already live):

```
GetQuests()        -> { ok=true, Day, SecondsUntilReset,
                        Quests = { { Id, Name, Counter, Target, Progress, Complete,
                                     Claimed, CanClaim, Reward = {{Id,Qty},...} }, ... } }
                      | { ok=false, reason }
ClaimQuest(id)     -> { ok=true, Id, Rewards = views }        -- reveal is the RETURN VALUE (B37)
                      | { ok=false, reason, Progress? }
```

Reason codes: `bad_quest_id` `not_assigned_today` `already_claimed` `not_complete` `grant_failed`
`profile_not_loaded` `busy`. The screen shows a refusal as a **toast** (`UIKit.Notify`) and re-syncs;
a durable condition (`already_claimed`) also reads on the card itself via `ClaimedTick`.

---

## The tree

```
StarterGui.QuestsGUI                    ScreenGui
│   Enabled = false          <- BOLD: the controller opens it; a screen that boots visible flashes
│   ResetOnSpawn = false     <- BOLD: or it re-clones on every respawn and loses its state
│   IgnoreGuiInset = true
│   DisplayOrder = 9         (Settings 7, DailyRewards 8; ObtainRewardsGUI is 100 and stays on top)
│
├── Overlay                             TextButton   full-screen dim; clicking it closes the screen
│                                                    (same job as DailyRewards.Overlay)
└── Main                                Frame        the panel. Motion.slideIn/slideOut animates THIS
    ├── UICorner                        UICorner
    ├── Title                           TextLabel    e.g. "DAILY QUESTS"
    ├── CloseButton                     TextButton   tag: UIKitButton
    ├── ResetTime                       TextLabel    I write "Resets in 11:29:53"
    ├── EmptyLabel                      TextLabel    OPTIONAL — I show it if the day has no quests
    │
    └── List                            ScrollingFrame (or Frame) the quest rows go into
        ├── UIListLayout                UIListLayout FillDirection = Vertical
        └── QuestCardTemplate           Frame
            │   Visible = false         <- BOLD: I CLONE this. If it is visible it renders as a
            │                              stray extra card forever. Same rule as CurrencyTemplate.
            ├── UICorner                UICorner
            ├── UIStrokeWithGradient    UIStroke     + a UIGradient child — I paint the reward tier here
            ├── QuestName               TextLabel    I write the quest name, e.g. "Summon 3 times"
            ├── ProgressBar             Frame        the bar track
            │   ├── UICorner            UICorner
            │   └── Fill                Frame        I set .Size X-scale = Progress/Target (0..1)
            │       └── UICorner        UICorner
            ├── ProgressLabel           TextLabel    I write "2 / 3"
            ├── RewardIcon              ImageLabel   I set .Image from ItemCatalog (the first reward)
            ├── RewardQty               TextLabel    I write "x300" (+" +1" when the quest pays more)
            ├── ClaimButton             TextButton   tag: UIKitButton   e.g. "CLAIM"
            └── ClaimedTick             ImageLabel   Visible = false — I show it on a claimed quest
```

---

## What the controller does to each named part

| you build | the controller does |
|---|---|
| `Overlay` | close on click |
| `Main` | `Motion.slideIn` / `slideOut`; open state tested with `Motion.isOpen(Main)`, never `gui.Enabled` |
| `Title` | left alone |
| `CloseButton` | close on click |
| `ResetTime` | live countdown to the daily reset, ticking every second |
| `List.QuestCardTemplate` | cloned once per quest in today's set, filled, parented to `List` |
| card `QuestName` | quest name |
| card `ProgressBar.Fill` | width scaled to `Progress/Target`, clamped 0..1 |
| card `ProgressLabel` | `"Progress / Target"` |
| card `RewardIcon` / `RewardQty` | first reward's icon + `"xQty"`; `UIStrokeWithGradient` painted by its tier |
| card `ClaimButton` | claims the quest; present-but-dimmed when not claimable (never removed) |
| card `ClaimedTick` | shown when the quest is claimed today |

**Do NOT create `QuestsController`.** The controller is written and placed by AD-Gacha.

## Entry point

`HUD.Left.Buttons.QuestsButton` (already tagged `UIKitButton`) fires `ClientEvents.OpenQuests` on
click; the controller creates that BindableEvent if it is missing and toggles the screen on it. Same
shape as `OpenSummon` / `OpenDailyRewards` — neither script needs the other to exist.

## If a name is wrong

Nothing breaks silently. Every lookup is **bounded** (`need()`, the B33 rule) and prints the exact
missing path. A missing part costs that part, never the screen; a missing `Main`/remote/template
disables the screen with one named warning and the HUD button still says so.

## Optional, only if you want them

- `EmptyLabel` under `Main` — shown when today rolls zero assignable quests. Skip it and the list is
  just empty.
- Extra parts inside `QuestCardTemplate` are fine and left alone. The controller only touches the
  names listed.

---

## ⚠ STATUS (B42): BUILT AS BLOCKOUT, not left waiting

Same call as DailyRewards at B40: both the server and this contract were finished and only art was
blocking, so B42 **scripted a plain version of this tree and wired it**, and it is live now.

**This spec is still the contract.** The scripted tree uses these exact names and flags and the
controller reads nothing else, so authoring your own version is a **replace, not a rewrite**: build it
however you like, keep the names, delete the scripted `QuestsGUI`, and the controller needs **zero**
edits. If you add a part you want driven, add it here first.
