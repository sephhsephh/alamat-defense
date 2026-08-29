# Build spec — `StarterGui.BattlePassGUI` (B42)

<!-- owner: user (art) + AD-Meta | scope: lobby | for: the Lobby place only -->

**The controller reads ONLY the names below.** Same rule as Quests / Shop: positions, sizes, colours,
fonts, images and layout are entirely the user's — the controller needs only the **names**, the
**classes**, and the flags in bold.

Server contract (B42, additive, live):

```
GetBattlepass()            -> { ok, SeasonId, XP, Level, MaxTier, XPPerTier, Owned,
                                Tiers = { { Tier, Free={{Id,Qty}}, Paid={{Id,Qty}}, Unlocked,
                                           ClaimedFree, ClaimedPaid }, ... } }
ClaimBattlepassTier(tier,track)  -> { ok, Tier, Track, Rewards } | { ok=false, reason }
```

`track` is `"Free"` or `"Paid"`. Reason codes: `bad_tier` `bad_track` `no_such_tier` `not_unlocked`
`not_owned` `already_claimed` `nothing_to_claim` `grant_failed` `profile_not_loaded` `busy`. A refusal
**toasts** (`UIKit.Notify`); durable state (claimed) reads on each slot's `ClaimedTick`.

> **XP source + monetization are NOT built yet** (see `docs/systems/battlepass.md`). The screen shows
> the `Owned` state but has **no purchase button** — wiring a Robux product is a deferred business
> decision. The paid Claim buttons exist; clicking one while un-owned just toasts `not_owned`.

---

## The tree

```
StarterGui.BattlePassGUI                ScreenGui
│   Enabled = false          <- BOLD    ResetOnSpawn = false  <- BOLD
│   IgnoreGuiInset = true                DisplayOrder = 9
│
├── Overlay                             TextButton   full-screen dim; clicking it closes
└── Main                                Frame        the panel. Motion.slideIn/slideOut animates THIS
    ├── UICorner                        UICorner
    ├── Title                           TextLabel    e.g. "BATTLE PASS"
    ├── CloseButton                     TextButton   tag: UIKitButton
    ├── SeasonLabel                     TextLabel    I write the SeasonId
    ├── LevelLabel                      TextLabel    I write "Level 3"
    ├── OwnedLabel                      TextLabel    I write "Premium: Owned" / "Premium: locked"
    ├── XPBar                           Frame        the XP bar track
    │   ├── UICorner                    UICorner
    │   └── Fill                        Frame        I set .Size X-scale = progress to next tier (0..1)
    │       └── UICorner                UICorner
    ├── XPLabel                         TextLabel    I write "50 / 100" (XP within the level) or "MAX"
    │
    └── Track                           ScrollingFrame (or Frame) the tier columns go into
        ├── UIListLayout                UIListLayout FillDirection = Horizontal
        └── TierCardTemplate            Frame
            │   Visible = false         <- BOLD: I CLONE this once per tier. Visible = a stray column.
            ├── UICorner                UICorner
            ├── TierNumber              TextLabel    I write the tier number
            ├── FreeSlot                Frame        the FREE-track reward
            │   ├── Icon                ImageLabel   I set from ItemCatalog
            │   ├── Qty                 TextLabel    I write "xN"
            │   ├── ClaimButton         TextButton   tag: UIKitButton — claims Free
            │   └── ClaimedTick         ImageLabel   Visible = false — I show it when claimed
            ├── PaidSlot                Frame        the PAID-track reward (same four children)
            │   ├── Icon                ImageLabel
            │   ├── Qty                 TextLabel
            │   ├── ClaimButton         TextButton   tag: UIKitButton — claims Paid
            │   └── ClaimedTick         ImageLabel   Visible = false
            └── LockOverlay             Frame        Visible = false — I show it when the tier is LOCKED
```

## What the controller does to each named part

| you build | the controller does |
|---|---|
| `Overlay` / `CloseButton` | close on click |
| `Main` | `Motion.slideIn` / `slideOut`; open tested with `Motion.isOpen(Main)` |
| `SeasonLabel` / `LevelLabel` / `OwnedLabel` | the season, `"Level N"`, and the premium state |
| `XPBar.Fill` / `XPLabel` | progress **within the current level** (XP mod XPPerTier), or full + "MAX" at the top |
| `Track.TierCardTemplate` | cloned once per tier, filled, parented to `Track` |
| card `TierNumber` | the tier number |
| each slot `Icon`/`Qty` | first reward's icon + `"xQty"`; empty track → slot hidden |
| each slot `ClaimButton` | claims that track (`ClaimBattlepassTier(tier, track)`); dimmed when claimed, locked, or (Paid) un-owned |
| each slot `ClaimedTick` | shown when that track's tier is claimed |
| card `LockOverlay` | shown when `Unlocked == false` (Level < tier) |

**Do NOT create `BattlePassController`.** AD-Meta writes and places it.

## Entry point
`HUD.Right.Buttons.BattlePassButton` (already tagged `UIKitButton`) fires `ClientEvents.OpenBattlepass`
on click; the controller creates that BindableEvent if missing and toggles the screen. Same shape as
`OpenQuests` / `OpenShop`.

## If a name is wrong
Every lookup is **bounded** (`need()`, B33) and prints the exact missing path. A missing part costs
that part, never the screen.

## ⚠ STATUS (B42): BUILT AS BLOCKOUT
The backend + this contract are finished and only art blocks, so B42 scripted a plain `BattlePassGUI`
and wired it. The scripted tree uses these exact names and flags; authoring your own is a **replace,
not a rewrite** — keep the names, delete the scripted ScreenGui, and the controller needs zero edits.
