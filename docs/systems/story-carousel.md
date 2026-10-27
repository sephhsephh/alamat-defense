# Story stage carousel ("UI Scroller") — LOBBY (B174)
<!-- owner: AD-UI (look) + AD-Lobby (PlayController entries) | scope: lobby | last-verified: 2026-10-28 (B174, live Play) -->

Story Mode in the Play menu (`PlayGUI.Main.Content.StoryMap`) is a horizontal carousel of ornate stage cards, built
from the user's concept sheet "Alamat Defense UI Scroller". Figma: UI Kit v2 file `HM7CHKVeG00STpf2h7RHJp`, design
board node `23:1420` (the selected glow there is the pre-review strength; the user asked for it softer, now built).
It replaced the vertical island list (backup: `ServerStorage._UIBackup_B174.StoryMap_Maps`).

## Where things are
- **Instances** (authored, scale-only): `StoryMap.Carousel`, built by `tools/story_carousel_build.luau` (Edit
  datamodel, re-run = rebuild). `Stage.Slot_m3..Slot_p3` = the ONLY positions/sizes a card takes (attributes `Z`,
  `Dim` = GroupColor brightness, `Fade` = GroupTransparency). `Stage.StageCardTemplate` (CanvasGroup, Visible=false),
  `Themes.<Gold|Purple|Blue|Red>` (`BodyColor`, `GemColor`; `Themes` also has `SelectedGemColor`, `LockedArtColor`),
  `ArrowLeft/Right`, `Track` (+ `Studs.StudTemplate`), `EnterButton` (Alamat Plate, Gold).
- **Code**: `PlayGUI.PlayController.StoryCarousel` (ModuleScript) = all motion + input; it builds nothing.
  `PlayController` STORY MAP block only builds the entry list (`V3.carousel`, no new top-level locals — the 200-local
  hazard, `play-menu-v3.md`).
- **Data**: `RS.Configs.PlayConfig.Maps[i].CardArt` / `.CardTheme`; `PlayConfig.UpcomingMaps` = DISPLAY-ONLY locked
  cards after the real maps (Bakunawa Cove "Coming soon", then the `Teaser` "???" card). Never read by the server.
- **Art**: `Claude outputs/story-carousel/` — `raw/` (Figma AI originals), `roblox/` (upload set + `asset_ids.txt`),
  scripts `split_card.py`, `split_parts.py`, `plain_track.py`, `make_card_art.py`, `compose_board.py`, `board.html`.

## Card layers (back → front; white-tint rule, `docs/design/white-tint-art.md`)
Glow (white halo, `Tint` orange) · Flame (white tongues, `Tint` yellow→orange + transparency bands) · Frame:
Art (stage art PRE-MASKED to the window) · Shade (window silhouette, `Tint` dark; locked dim) · InfoShade · Body
(enamel + cloth, `Tint` = theme BodyColor) · Gems (`Tint` = theme GemColor) · Gold (never tinted) · Info (Stage /
Name / ProgressBar / ProgressLabel) · Lock (IconCatalog `Lock`) · Sparkles (4 white stars, `Tint`) · Hit (button) ·
SelectionCue (empty frame = `Hit.SelectionImageObject`, so the glow is the gamepad cue, not the blue box).
Glow/Flame fill the CanvasGroup; the Frame is `683/896 × 1024/1237` of it (room for the halo).

## States + motion (Roblox images can't glow → separate glow sprites, tweened)
- **Idle**: Glow 1 (off), Pop 1. **Hover** (mouse; side card): Glow .72, Pop 1.05, dim lifted +.3, sparkles.
- **Selected** (centred): Glow pulses .42–.58, Flame .30–.42 flicker + `Tint.Offset` scroll, gems → SelectedGemColor,
  sparkles twinkle. (User B174: "tone down the glow, not that solid" — the glow art is a soft falloff, keep it so.)
- **Scroll**: 0.38 s Quint to the target slot; art inside every window kicks 1.8% against the scroll and settles
  (parallax). Arrows pulse their Glow while they can move, dim to .55 at the ends. The selected track stud lights.
- **Locked**: Shade .72 + LockedArtColor + Lock icon; ENTER reads LOCKED; entering → Notify ("Clear the previous
  island first." / "<Name> is coming soon." / "More islands are coming soon.").

## Input (PC + console + mobile)
- PC: arrows, `A`/`D`, `←`/`→`, mouse wheel over the stage, drag; click a side card = scroll to it; click the centred
  card / ENTER / `Return` = open its StagePanel (unchanged PlayController flow, first unfinished act).
- Console: D-pad ←/→, LB/RB, left stick (latched: one step per push) — bound via `ContextActionService` at High
  priority ONLY while the Story page is up and no modal is open; A = the selected centred card; up/down = native
  selection (ENTER). The stick is sunk while bound (vertical stick nav off on this page; D-pad still works).
- Mobile: swipe on the stage (one step per 13% of its width dragged), tap a side card / the centred card / ENTER.
- Gamepad selection always sits on the centred card's `Hit` (`openStoryMap` → `V3.carousel.focus()`).

## Adding a stage card
1. Paint/generate portrait art (1024×1536), then `py -I make_card_art.py <story-carousel> <src> art_<id>` and upload.
2. Playable stage: add `CardArt` + `CardTheme` to its `PlayConfig.Maps` entry (and delete its `UpcomingMaps` row).
   Not playable yet: an `UpcomingMaps` row. New colour scheme: add a `Themes` child with the two attributes.

## Verified (B174, Studio Play, 1149×731 window)
Opens from Story Mode; 3 cards; arrow click, `D`/`←`/`→`, RB, D-pad, wheel and mouse drag each step exactly once;
gamepad selection follows the centre, no blue box; hover zoom/glow; ENTER on Stage 1 opens the StagePanel at the next
uncleared act; drag-release does not activate a card. NOT verified: real touch input (no touch emulation from the
tools — same code path as the mouse drag) and a physical controller's stick.
