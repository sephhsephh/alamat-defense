# Build spec — `StarterGui.StatRerollScreen` + `Workspace.Lobby.NPC_StatReroll` (B44)

<!-- owner: user (art) + AD-Traits (controller) | scope: lobby | for: the Lobby place only -->

**The controller reads ONLY the names below.** Same rule as the trait reroll / Shop / Quests: art
cannot be scripted across a Place, so positions, sizes, colours, fonts, images and layout are the
user's — the controller needs the **names**, the **classes**, and the flags in bold. Frames and
backgrounds are **ImageLabel / ImageButton with a blank `Image`** so you can drop art onto them.

Server contract (B44, Lobby-local):

```
RerollStats(uuid) -> { ok=true, Uuid, OldRolls, NewRolls, OldGrades, NewGrades, Worthy, Balance }
                     | { ok=false, reason }
```

`OldGrades`/`NewGrades` are `{ DMG=<letter>, RNG=<letter>, SPA=<letter> }`. The **client sends only
the uuid.** The server pre-checks ownership, SPENDS one `StatRerolls` (`GrantService.Spend`), ROLLS
all three `StatRolls` (`StatGradeConfig.RollAll`, floored at grade A when `Worthiness>=100`), WRITES
them and resets Worthiness to 0. Reason codes: `bad_uuid` `not_owned` `profile_not_loaded` `busy`
`insufficient_rerolls`. The balance, each unit's grades and its Worthiness are read from
**`GetUnitViews`** (`res.Currencies.StatRerolls`, `res.Units[uuid].StatRolls` / `.Worthiness`) — no
second remote. **Letters + colours come from `StatGradeConfig` only.**

---

## The screen tree (what B44 built; re-author the art, keep the names)

```
StarterGui.StatRerollScreen              ScreenGui
│   Enabled = false          <- BOLD: the controller opens it
│   ResetOnSpawn = false     <- BOLD: survives respawns, keeps its state
│   IgnoreGuiInset = true
│   DisplayOrder = 8
│
└── Main                                 Frame        full-screen scrim; clicking OUTSIDE Panel closes
    └── Panel                            ImageLabel   panel bg — blank Image, dark fill (restyle)
        ├── Title                        TextLabel    e.g. "STAT REROLL"
        ├── Subtitle                     TextLabel    I write "N unit(s)"
        ├── RerollLabel                  TextLabel    I write "Stat Rerolls: N" (the balance)
        ├── CloseButton                  ImageButton  I close on click (child "X" TextLabel cosmetic)
        ├── EmptyLabel                   TextLabel    I show it when the player owns no units
        ├── Grid                         ScrollingFrame  the unit cards go here
        │   ├── UIGridLayout             UIGridLayout
        │   └── UIPadding                UIPadding
        └── Detail                       ImageLabel   right pane — blank Image, dark fill (restyle)
            ├── UnitName                 TextLabel    selected unit's Name (tier-coloured)
            ├── StatDMG                  TextLabel    I write "DMG:  <grade>" (grade-coloured)
            ├── StatRNG                  TextLabel    I write "RNG:  <grade>"
            ├── StatSPA                  TextLabel    I write "SPA:  <grade>"
            ├── WorthinessLabel          TextLabel    I write the meter + the "FLOORED at A" hint at 100
            ├── CostLabel                TextLabel    I write "Reroll costs 1 Stat Reroll(s). You have N."
            ├── ResultLabel              TextLabel    I write "DMG a->b   RNG a->b   SPA a->b"
            ├── StatusLabel              TextLabel    I write refusals / "Rerolled." / the worthiness note
            └── RerollButton             ImageButton  I reroll on click (child "Label" TextLabel cosmetic)
```

The cards in `Grid` are **clones of `RS.UITemplates.Kit.UnitIconV2`** (shared icon canon, ADR-0005 —
nothing added to it). The level badge (`UnitLevel`) is repurposed to show the unit's **DMG grade**.

## What the controller does to each named part

| you build | the controller does |
|---|---|
| `Main` (outside `Panel`) / `CloseButton` | close |
| `Subtitle` / `RerollLabel` | picker count / `"Stat Rerolls: N"` from `GetUnitViews.Currencies`, re-read after each reroll |
| `Grid` | one `UnitIconV2` clone per owned unit, rarest-first, click selects |
| `UnitName` / `StatDMG` / `StatRNG` / `StatSPA` | name (tier colour) + the three grades (grade colours from `StatGradeConfig`) |
| `WorthinessLabel` | `Worthiness N/100`; at 100, the "next reroll is FLOORED at grade A" hint |
| `CostLabel` / `RerollButton` | the cost + balance; reroll the selected unit, **dimmed and inactive when balance < cost** |
| `ResultLabel` / `StatusLabel` | per-stat `old->new` + the outcome / refusal / worthiness message |

**Do NOT create `StatRerollController`.** AD-Traits writes and places it.

## The entry point — an NPC (ADR-0010)

`Workspace.Lobby.NPC_StatReroll` (a Model) with a **`ProximityPrompt`** anywhere inside it. The
controller finds it with `FindFirstChildWhichIsA("ProximityPrompt", true)` and fires
`ClientEvents.OpenStatReroll` on `Triggered` — no special privilege, so a second NPC or a HUD button
is a drop-in later. **B44 placed a BLOCKOUT `NPC_StatReroll`** (cloned from `NPC_Ascension`, retinted,
prompt "Stat Diviner" / "Reroll stats"). Replace it with your own model — keep the name and a
`ProximityPrompt`, and the controller needs zero edits.

## ⚠ STATUS (B44): BUILT AS BLOCKOUT

Server and contract finished; only art is blocking. B44 scripted a plain `StatRerollScreen` tree
(Image-based frames) + a blockout `NPC_StatReroll` and wired them, verified live. Authoring your art
is a **replace, not a rewrite** — keep the names and flags, restyle the `Panel`/`Detail` ImageLabels
and the two ImageButtons, and the controller needs zero edits.

> **NOTE — the economy is dormant:** nothing grants `StatRerolls` yet (see `docs/systems/stat-reroll.md`),
> so in a normal session the balance is 0 and the button stays disabled until a source lands.
