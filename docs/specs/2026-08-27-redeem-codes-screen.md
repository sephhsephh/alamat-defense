# Build spec — `StarterGui.RedeemCodes` (B39)

<!-- owner: user (art) + AD-Gacha (controller) | scope: lobby -->

**The server side is finished and tested** (`docs/systems/redeem-codes.md`). This is the only thing
left. Same deal as the daily-rewards screen: you build the tree, I write the controller. Names and
the flags in **bold** are the contract; everything visual is yours.

Three codes work right now for testing: **`ALAMAT`**, **`FIRSTLIGHT`**, and **`EXPIREDTEST`**
(deliberately dead, so you can see the failure path).

## The tree

```
StarterGui.RedeemCodes                  ScreenGui
│   Enabled = false          <- BOLD
│   ResetOnSpawn = false     <- BOLD
│   IgnoreGuiInset = true
│   DisplayOrder = 8
│
├── Overlay                             TextButton   full-screen dim; click closes
└── Main                                Frame        the panel; Motion slides THIS
    ├── UICorner                        UICorner
    ├── Title                           TextLabel    e.g. "REDEEM CODE"
    ├── CloseButton                     TextButton   tag: UIKitButton
    ├── CodeBox                         TextBox      where they type
    │       ClearTextOnFocus = false    <- BOLD: pasting is how most codes are entered;
    │                                      clearing on focus makes paste-then-click lose the text
    ├── SubmitButton                    TextButton   tag: UIKitButton
    │   └── Label                       TextLabel    e.g. "REDEEM"
    └── StatusLabel                     TextLabel    I write the result here
```

That is the whole thing. It is a small screen.

## What I do

| you build | I do |
|---|---|
| `CodeBox` | read it, submit on Enter too, and clear it on a successful redeem |
| `SubmitButton` | invoke `Remotes.RedeemCode`; disable while a call is in flight |
| `StatusLabel` | **the state** — the reason a code failed, or "Redeemed!" |
| `Overlay` / `CloseButton` | close |

Rewards reveal through the existing `ObtainRewardsGUI`, so there is nothing to build for that.

## ⚠ One thing that is my job, not yours: the label is the STATE

Every failure reason lands on `StatusLabel` and **stays there** — "already redeemed", "expired",
"that code doesn't exist", "too many attempts, try again later". It does not toast. A toast erases
itself after 3.5 seconds, and a player staring at a box wondering why nothing happened is exactly the
case where the message has to still be on screen. (`ui-feedback.md`: toast events, label state.)

## Optional

- A `RewardsPreview` frame — I could list what a code gave. Skip it unless you want it; the reveal
  screen already shows that.
- If you want the button to look disabled mid-request, give it a `Disabled` attribute or a second
  colour and tell me which property to drive.

## If a name is wrong

Nothing breaks silently — every lookup is bounded and prints the exact missing path (`need()`, B33).

## Entry point

`HUD.Right.UpperRight.RedeemCodes` — already tagged `UIKitButton`, currently unwired. I wire it to
open this screen once the tree exists.

---

## ⚠ STATUS (B40): this screen was BUILT AS BLOCKOUT, not left waiting

The user's call at B40 reversed the earlier "you author it, I wire it": both servers were finished
and only art was blocking them, so B40 **scripted a plain version of this tree and wired it**, and it
is live now.

**This spec is still the contract.** The scripted tree uses these exact names and flags, and the
controller reads nothing else. So authoring your own version is a **replace, not a rewrite**: build
it however you like, keep the names, delete the scripted ScreenGui, and the controller needs **zero**
edits. If you add a part you want driven, add it here first.
