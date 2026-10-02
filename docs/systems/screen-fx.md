# screen-fx — the shared juice layer for the NPC screens (B108 pt13c, AD-UI, Lobby)

`StarterPlayer.StarterPlayerScripts.Client.UI.ScreenFX` (ModuleScript) + authored `StarterGui.ScreenFXLayer`
(DisplayOrder 30: `Flash` + hidden `Templates/{Burst, Spark, Charge, ResultText}`) + authored `Lighting.ScreenFXBlur`.
Used by StatReroll, SilverShop, Evolve, Ascension and Crafting. The controllers keep ALL their logic; every
ScreenFX call is guarded (`if ScreenFX then`), so a screen still works without the module.

## API
| call | what it does |
|---|---|
| `open(gui, panels, {Dim, NoBlur})` | blur the world (ref-counted), fade the overlay in, drop each panel in from below with an alternating tilt, staggered; closes any OTHER registered screen |
| `close(gui, panels, done?)` | quick shrink + drop, then `gui.Enabled = false`, blur released |
| `register(gui, closeFn)` | one NPC screen at a time |
| `juice(root)` | hover 1.05 / press 0.92 / gamepad-select springs on every GuiButton (skips `UIKitButton`-tagged, scrims, `NoFX` attr) |
| `gradients(root)` | animates every UIGradient with `Anim` = `Loop`/`Spin` (+`Period`) via UIKit.Motion |
| `watchGrid(container)` | freshly rendered cards pop in, staggered; a card re-rendered under the same name within 4s does not pop again |
| `popOnShow(frames)` | a popup slides + untilts in when its controller makes it Visible |
| `charge(anchor, tier?) -> stop` | pulsing ring around a slot while a remote is in flight |
| `success(anchor, {Text, Tier|Color, Big, Shake, Sound})` | burst (ring + rays + glow) + sparks + screen flash + floating big text + pop (+ panel shake) |
| `fail(anchor)` / `shake(obj)` / `pop(obj)` | red shake / jitter / one scale punch |

## Rules learned
- **Never UIScale a panel on OPEN.** Controllers size grids from `AbsoluteSize` while rendering on open, and a
  scaled-down panel made the Silver Shop lay out shrunken cards. Open = Position + Rotation only; popups the same.
- Templates are authored `Visible = false`; `template()` turns the clone on (a Folder does not hide GuiObjects).
- The only instance made in code is the `FXScale` UIScale (Motion.isolate precedent).

## Per screen
- **Stat Reroll:** a better grade bursts on its GradeBox in the grade colour with "S!", a worse one shakes the row,
  same grade pops; refusal shakes the panel. Panels: Panel, Packs, Tabs, InfoStrip.
- **Silver Shop:** buy -> burst on the card "PURCHASED!" (reward reveal delayed 0.6s), multi-buy "BOUGHT xN!" + shake,
  unit slots "+SLOTS!", refusal shakes the card. Panels: Main, Packs, Restock, UnitSlotsButton.
- **Evolve:** base slot shakes + result slot charges during the call (min 0.45s), then "EVOLVED!" big burst in the new
  tier's colours + panel shake; the reward reveal waits 1.1s. Quick craft bursts/shakes its button.
- **Ascension:** same ceremony, "ASCENDED!" gold-violet-cyan, stars pop one by one, the earned bonus card bursts.
- **Crafting:** the ring charges, "CRAFTED xN!" big burst in the item's tier (reveal waits 1s); dismantle "DISMANTLED!".
  No blur here (the layout shows the player in the ring).
- **Restyle (authored):** every top-level panel stroke got an animated theme `FXStrokeGradient` (green / gold / orange /
  violet-cyan / rainbow), banner gradients and button gradients loop, banner titles got an `FXShimmer`.
- **Layouts kept** (they are the user's own references and every feature works as-is).
