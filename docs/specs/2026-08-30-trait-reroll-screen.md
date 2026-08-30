# Build spec — `StarterGui.TraitRerollScreen` + `Workspace.Lobby.NPC_TraitReroll` (B44)

<!-- owner: user (art) + AD-Traits (controller) | scope: lobby | for: the Lobby place only -->

**The controller reads ONLY the names below.** Same rule as Shop / Quests / DailyRewards: art cannot
be scripted across a Place, so positions, sizes, colours, fonts, images and layout are entirely the
user's — the controller needs only the **names**, the **classes**, and the flags in bold. Frames and
backgrounds are **ImageLabel / ImageButton with a blank `Image`** so you can drop art straight onto
them.

Server contract (B44, Lobby-local):

```
RerollTrait(uuid)  -> { ok=true, Uuid, OldTrait, NewTrait, Balance }   -- the reveal is the RETURN VALUE
                      | { ok=false, reason }
```

The **client sends only the unit uuid.** The server pre-checks ownership, SPENDS one
`TraitRerollToken` (`GrantService.SpendItems`), ROLLS (`TraitRegistry.Roll`) and WRITES the trait.
Reason codes: `bad_uuid` `not_owned` `profile_not_loaded` `busy` `insufficient_tokens`. The token
balance and each unit's current trait are read from **`GetUnitViews`** (ADR-0004's single Lobby read
path: `res.Items.TraitRerollToken`, `res.Units[uuid].Trait`) — there is no second remote.

---

## The screen tree (what B44 built; re-author the art, keep the names)

```
StarterGui.TraitRerollScreen             ScreenGui
│   Enabled = false          <- BOLD: the controller opens it; a screen that boots visible flashes
│   ResetOnSpawn = false     <- BOLD: or it re-clones on every respawn and loses its state
│   IgnoreGuiInset = true
│   DisplayOrder = 8         (below ObtainRewardsGUI 100, which stays on top)
│
└── Main                                 Frame        full-screen scrim; clicking OUTSIDE Panel closes
    └── Panel                            ImageLabel   the panel bg — blank Image, dark fill (restyle)
        ├── Title                        TextLabel    e.g. "TRAIT REROLL"
        ├── Subtitle                     TextLabel    I write "N unit(s)"
        ├── TokenLabel                   TextLabel    I write "Trait Reroll Token: N" (the balance)
        ├── CloseButton                  ImageButton  I close on click (child "X" TextLabel is cosmetic)
        ├── EmptyLabel                   TextLabel    I show it when the player owns no units
        ├── Grid                         ScrollingFrame  the unit cards go here
        │   ├── UIGridLayout             UIGridLayout
        │   └── UIPadding                UIPadding
        └── Detail                       ImageLabel   the right pane — blank Image, dark fill (restyle)
            ├── UnitName                 TextLabel    I write the selected unit's Name (tier-coloured)
            ├── CurrentTrait             TextLabel    I write "Current trait: <DisplayName>"
            ├── TraitDesc                TextLabel    I write the trait's Description
            ├── CostLabel                TextLabel    I write "Reroll costs 1 Trait Reroll Token. You have N."
            ├── ResultLabel              TextLabel    I write "old -> new" after a reroll
            ├── StatusLabel              TextLabel    I write refusals / "Rerolled." / "New trait: X"
            └── RerollButton             ImageButton  I reroll on click (child "Label" TextLabel is cosmetic)
```

The unit cards in `Grid` are **clones of `RS.UITemplates.Kit.UnitIconV2`** (the shared icon, ADR-0005
canon — nothing is added to it), exactly as the Ascension picker does. The level badge (`UnitLevel`)
is repurposed to show the unit's current trait DisplayName; the card is otherwise painted by tier.

## What the controller does to each named part

| you build | the controller does |
|---|---|
| `Main` (outside `Panel`) / `CloseButton` | close on click / hit-test outside the Panel |
| `Subtitle` | `"N unit(s)"` — the picker count |
| `TokenLabel` | `"Trait Reroll Token: N"` from `GetUnitViews.Items`, re-read after each reroll |
| `Grid` | one `UnitIconV2` clone per owned unit, rarest-first, click selects |
| `EmptyLabel` | shown when the player owns no units |
| `UnitName` / `CurrentTrait` / `TraitDesc` | selected unit's name (tier colour) + current trait name/desc (rarity colour) |
| `CostLabel` | the token cost and the current balance |
| `RerollButton` | rerolls the selected unit; **dimmed and inactive when the balance is below the cost** |
| `ResultLabel` / `StatusLabel` | `old -> new` and the outcome / refusal message |

**Do NOT create `TraitRerollController`.** AD-Traits writes and places it.

## The entry point — an NPC (ADR-0010, the AscensionScreen shape)

`Workspace.Lobby.NPC_TraitReroll` (a Model) with a **`ProximityPrompt`** anywhere inside it. The
controller finds it with `FindFirstChildWhichIsA("ProximityPrompt", true)` and fires
`ClientEvents.OpenTraitReroll` on `Triggered` — the prompt has **no special privilege**, so a second
NPC or a HUD button is a drop-in later (identical to `NPC_Ascension`).

**B44 placed a BLOCKOUT `NPC_TraitReroll`** (cloned from `NPC_Ascension`, retinted, prompt "Trait
Weaver" / "Reroll a trait") near the Ascension NPC. Replace it with your own model — keep the name and
give it a `ProximityPrompt`, and the controller needs zero edits.

## ⚠ STATUS (B44): BUILT AS BLOCKOUT

Both the server and this contract are finished; only art is blocking. B44 scripted a plain
`TraitRerollScreen` tree (Image-based frames) + a blockout `NPC_TraitReroll` and wired them, verified
live. Authoring your own art is a **replace, not a rewrite** — keep the names and flags, restyle the
`Panel`/`Detail` ImageLabels and the two ImageButtons, and the controller needs zero edits.
