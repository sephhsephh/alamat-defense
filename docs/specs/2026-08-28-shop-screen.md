# Build spec — `StarterGui.ShopGUI` + `Workspace.Lobby.NPC_Shop` (B42)

<!-- owner: user (art) + AD-Gacha (controller) | scope: lobby | for: the Lobby place only -->

**The controller reads ONLY the names below.** Same rule as Quests / DailyRewards: art cannot be
scripted across a Place, so positions, sizes, colours, fonts, images and layout are entirely the
user's — the controller needs only the **names**, the **classes**, and the flags in bold.

Server contract (B40, additive, already live):

```
GetShopStock()      -> { ok=true, Day, Currency="Silver", Balance, SecondsUntilRestock,
                         Items = { { Slot, Id, Qty, Price, Bought, Name, Tier }, ... } }
                       | { ok=false, reason }
BuyShopItem(slot)   -> { ok=true, Slot, Balance, Rewards = views }   -- reveal is the RETURN VALUE (B37)
                       | { ok=false, reason, Balance? }
```

The **client sends only the slot INDEX** — id, quantity and above all PRICE come from the server's own
re-roll. Reason codes: `bad_slot` `no_such_slot` `already_bought` `insufficient_funds`
`item_not_catalogued` `grant_failed_refunded` `profile_not_loaded` `busy`. A refusal **toasts**
(`UIKit.Notify`) and re-syncs; a durable condition (`already_bought`) also reads on the slot via
`SoldOutOverlay`.

---

## The screen tree

```
StarterGui.ShopGUI                      ScreenGui
│   Enabled = false          <- BOLD: the controller opens it; a screen that boots visible flashes
│   ResetOnSpawn = false     <- BOLD: or it re-clones on every respawn and loses its state
│   IgnoreGuiInset = true
│   DisplayOrder = 9         (same band as Quests/DailyRewards; ObtainRewardsGUI 100 stays on top)
│
├── Overlay                             TextButton   full-screen dim; clicking it closes the screen
└── Main                                Frame        the panel. Motion.slideIn/slideOut animates THIS
    ├── UICorner                        UICorner
    ├── Title                           TextLabel    e.g. "SHOP"
    ├── CloseButton                     TextButton   tag: UIKitButton
    ├── Balance                         TextLabel    I write "Silver: 1,270" (Currency + Balance)
    ├── RestockTime                     TextLabel    I write "Restock in 07:59:12"
    ├── EmptyLabel                      TextLabel    OPTIONAL — I show it if the day rolls zero slots
    │
    └── Grid                            ScrollingFrame (or Frame) the slot cards go into
        ├── UIGridLayout                UIGridLayout (or UIListLayout — your call, either works)
        └── ShopSlotTemplate            Frame
            │   Visible = false         <- BOLD: I CLONE this. Visible = a stray extra card forever.
            ├── UICorner                UICorner
            ├── UIStrokeWithGradient    UIStroke     + a UIGradient child — I paint the item's tier here
            ├── ItemIcon                ImageLabel   I set .Image from ItemCatalog
            ├── ItemName                TextLabel    I write the item Name
            ├── QtyLabel                TextLabel    I write "x250"
            ├── PriceLabel              TextLabel    I write "300 Silver"
            ├── BuyButton               TextButton   tag: UIKitButton   e.g. "BUY"
            └── SoldOutOverlay          Frame/ImageLabel  Visible = false — I show it on a bought slot
```

## What the controller does to each named part

| you build | the controller does |
|---|---|
| `Overlay` / `CloseButton` | close on click |
| `Main` | `Motion.slideIn` / `slideOut`; open tested with `Motion.isOpen(Main)`, never `gui.Enabled` |
| `Balance` | `"Silver: N"` from the server's `Currency` + `Balance`, re-read after each buy |
| `RestockTime` | live countdown to the daily restock, ticking every second |
| `Grid.ShopSlotTemplate` | cloned once per slot in today's stock, filled, parented to `Grid` |
| slot `ItemIcon`/`ItemName`/`QtyLabel`/`PriceLabel` | icon, name, `xQty`, `Price Silver`; tier on `UIStrokeWithGradient` |
| slot `BuyButton` | buys that slot (`BuyShopItem(Slot)`); dimmed when bought or unaffordable |
| slot `SoldOutOverlay` | shown when the slot is `Bought` |

**Do NOT create `ShopController`.** AD-Gacha writes and places it.

## The entry point — an NPC (user decision, B42; the AscensionScreen/ADR-0010 shape)

`Workspace.Lobby.NPC_Shop` (a Model) with a **`ProximityPrompt`** anywhere inside it. The controller
finds it with `FindFirstChildWhichIsA("ProximityPrompt", true)` and fires `ClientEvents.OpenShop` on
`Triggered` — the prompt has **no special privilege**, so a second NPC or a HUD button is a drop-in
later (identical to `NPC_Ascension`). The controller creates the `OpenShop` BindableEvent if missing
and toggles the screen on it.

**B42 placed a BLOCKOUT `NPC_Shop`** (a plain part + prompt) so the shop is reachable now. Replace it
with your own model — keep the name `NPC_Shop` and give it a `ProximityPrompt`, and the controller
needs zero edits. Reposition it wherever it belongs; the blockout sits near `NPC_Ascension`.

## If a name is wrong

Every lookup is **bounded** (`need()`, B33) and prints the exact missing path. A missing part costs
that part, never the screen; a missing `Main`/remote/template disables the screen with one warning.

## ⚠ STATUS (B42): BUILT AS BLOCKOUT

Both the server and this contract were finished and only art was blocking, so B42 scripted a plain
`ShopGUI` tree + a blockout `NPC_Shop` and wired them. The scripted tree uses these exact names and
flags; authoring your own is a **replace, not a rewrite** — keep the names, delete the scripted
ScreenGui and NPC, and the controller needs zero edits.
