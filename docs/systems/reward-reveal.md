# Reward reveal -- `ObtainRewardsGUI` (Lobby)
<!-- owner: AD-UI | scope: Lobby | last-verified: 2026-10-10 (B135) -->

THE reward-reveal surface for every grant in the Lobby (summon, quests, daily, codes, shop, craft, BP, events,
evolve, mail/RewardPush). **Rebuilt from scratch at B135** (user: "more Alamat Defense style, best UI/UX,
animations, effects"). The B1-B4 screen is in `ServerStorage._UIBackup_B135.ObtainRewardsGUI`.

## Entry point (unchanged since B1 -- every caller keeps working)
`RS.ClientEvents.ShowRewards:Fire({ { Id = "Gold", Qty = 250 }, { Id = "Handyong", Kind = "Unit", Level = 12 } })`
Fields: `Id`, `Qty`, `Kind` ("Unit"/"Item", else inferred: `ItemCatalog` `Kind == "Tower"`), `Level`, `Shiny`,
`Trait`, `AutoSold`. A bare string id works. An id the catalog does not know still renders (name = id, Common).
**Batches QUEUE, never merge.** `gui.Enabled` is true exactly while a reveal is up (DailyRewards' auto-open waits on it).

## Look (authored instances -- `tools/obtain_rewards_build.luau`; the controller builds NO UI)
- `Main.Dim` night backdrop (vignette gradient, Active = blocks the screens below) -> `Main.Rays` gold sunburst
  (8 bars = 16 rays + 3 glow discs) behind the board -> `Main.Header`: 8-ray Philippine-sun emblem, gold serif
  "REWARDS OBTAINED", divider with a violet gem, count line -> `Main.Board`: dark panel, gold/violet gradient frame
  (rotates), gold corner gems, `RewardsFrame` (ScrollingFrame + `Grid`) -> `Main.Hint`.
- **`Main.Templates.RewardCard`** (Folder = never rendered): `Burst` ring + `Main` card: tier `Wash`, moving
  `TierStroke`, `Glow` disc, `Icon` (items, tagged `ItemId` -> the shared ItemInfo hover card) or `Viewport`
  (units: `UnitCard.viewport` + `playIdle`, idle capped at the first 12), `TierTag`, `ShinyTag`, `Amount`
  ("x2,500" / "Lv. 12"), `TraitTag`, `NameStrip`, `Shine`, `Sold` ("AUTO-SOLD"), `Flash`.
- Square elements use a **wide X box** (`Size = (50, h)`) + `UIAspectRatioConstraint` (DominantAxis Height): the
  constraint can only SHRINK, so an X of 0 collapses the element to nothing (B135 bug, fixed).

## Motion
Intro: dim fades in, sunburst scales up (Back), header drops + title punch, board pops. Cards reveal one by one:
pop 0.35 -> 1 with a +/-9 deg tilt, white flash, shine sweep; **Epic+** adds the burst ring + pulsing glow
(`TraitLand`), **Legendary+** also kicks the sunburst (`TraitGoodReveal`); Common/Rare tick (`TraitReelTick`,
first 14 only). Open: sunburst/sun/frame gradient turn, hint breathes, a random card shimmers every 1.6 s.
Outro: everything shrinks/fades (0.2 s), then the next queued batch (board re-pops) or close.

## Input -- PC / console / mobile
Click / tap anywhere, Space / Enter, gamepad A / B (ContextActionService, sinks so Space/A do not jump).
**Press 1 during the reveal = SKIP** (never gated); after the reveal + `InputDeadSeconds` a press **CONTINUES**.
The hint shows which, per input device ("Click to skip" / "Press A to continue" / "Tap anywhere to continue").
This is the reveal-overlay "click anywhere to continue" exception to the close-button-only rule. Presses are
ignored while the ItemInfo obtainment popup (DisplayOrder 200) is open. Gamepad selection is parked and restored.

## Layout
Balanced rows (`rows = ceil(n / MaxColumns)`, `cols = ceil(n / rows)`: 7 -> 4 + 3, last row centred). Card
height = a share of the SCREEN height (34 % for 1, 29 % for <= 3, 26 % one row, 24 % two), then shrunk to fit
92 % of the width / 58 % of the height. `MaxVisibleRows` rows show; more scroll (gold scrollbar). Grid
`CellSize`/`CellPadding` are pixels **derived from the screen** (the grid-cell exception in `responsive-ui.md`);
board size, padding and canvas are scale. Re-laid out on resize.

## Tunables (ScreenGui attributes) + harness
`InputDeadSeconds` 0.35 · `RevealStaggerSeconds` 0.09 · `RevealPopSeconds` 0.38 · `RevealMaxTotalSeconds` 1.6
(a big batch compresses) · `MaxColumns` 6 · `MaxVisibleRows` 2. **`DevDismiss` = true** does exactly one press
(skip, then continue). Leave it off. Verified B135: n = 7 (4+3) and n = 20 (5 x 4, 2 visible, scroll), Epic burst,
Legendary kick, AUTO-SOLD, Shiny + Trait tags, queue close, no errors.
