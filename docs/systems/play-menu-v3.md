# Play menu v3 — ornate look (B171, LOBBY)
<!-- owner: AD-UI (look) + AD-Lobby (PlayController) | scope: lobby | last-verified: 2026-10-21 (B171, live Play) -->

The user's reference (Figma `HM7CHKVeG00STpf2h7RHJp`, node 17:1420) built as REAL instances by
`tools/playui_v3_build.luau` (Edit datamodel; backs up to `ServerStorage._UIBackup_B171`, re-run = rebuild).
Behaviour is still `PlayController` (`play-menu.md`); only the Modes page look, the party styling and the player
card are new. Art: AI-painted (Figma image AI), keyed + split by `Claude outputs/play-ui-v3/*.py`.

## Layout (scale-only, authored at 1920×1080)
- `Main.PlayerCard` (top-left): Avatar headshot, NameLabel (DisplayName), LevelLabel, XPLabel, XPBar.Fill —
  `V3.renderPlayerCard()` from `GetPlayState` (`PlayerLevel`, **`PlayerXP` added B171**) + `PlayerLevelConfig`.
- `Main.PartyPreview` moved to (0.02, 0.2, 0.36, 0.66): `PartyHeader` divider; Spot `PlusButton` = hex invite slot
  (HexFill/HexGold/HexGem + "Invite"); `NameTag` = dark pill + gold stroke. Max 4. Each spot plays its OWN idle
  (`V3.POSES`: Superhero / Mage / Knight / Ninja catalog idles).
- `Main.Content` moved to (0.448, 0.1, 0.536, 0.71); `TopBanner` to top-centre of the right column.
- `Content.Modes.Cards`: `Card_Story`, `Card_Raid`, `Card_Challenge`, `Card_Expedition` (TextButtons). Each:
  `Fill` (+Tint), `Art` (ImageLabel, empty = paste card art), `ArtGlow`, `BorderGold`/`BorderGem`, `CrestTop/Bottom`,
  `TitleRibbon`, labels, `PlayButton` (Alamat Plate; same action as clicking the card). Story/Challenge keep the
  controller's names (`MapLabel`, `ClearedLabel`, `ProgressLabel`, `ProgressBar.Fill`, `Timer.Label`, `Rewards`).
- Raid / Expedition = `Enabled = false` in `PlayConfig.Modes` → PLAY/ENTER fires `Notify.Info("<Mode> is coming soon.")`.
- `Content.Modes.SpecialEvents.List.EventCardTemplate` — ONE template (Visible=false), cloned by `V3.renderEvents()`
  per live `EventQuestConfig.Events` entry (max 3, Featured first): TitleLabel = TypeLabel, DescLabel = Name,
  TimerLabel = Label / "Ends in" / Permanent, Art = event Art, Fill/gem tinted from the event Color. Click = leave the
  menu, then `ClientEvents.OpenEvents:Fire(id)`.
- Reward icons = the shared kit `ItemIcon` clones (`fillRewards`), unchanged. Big PLAY button and top bar: removed (user).

## Tint layers (white-tint rule, `docs/design/white-tint-art.md`)
Every white layer has a `UIGradient` named `Tint`: card/ribbon fills, gems (`BorderGem`, `RibbonGem`, `HexGem`),
`HexFill`, `ArtGlow`, XP/progress fills. Gold layers (`BorderGold`, `RibbonGold`, `HexGold`, crests) are never tinted.

## Ornate borders
- `BorderGold` = `rbxassetid://93434482949078`, `BorderGem` = `126509180564408`: ScaleType Slice, SliceCenter
  `(210,210,814,814)`; the image is larger than the card by the art's overflow (49 px × SliceScale).
- Crests are separate (`107894179347515` top, `110147531554593` bottom) so the 9-slice never stretches them.
- Ribbon `91279820451744` / gem `127179845630114`: fixed 1024:212 (UIAspectRatioConstraint). Hex `70674120323568` /
  gem `134933819566915` / fill `118196360703535`. Divider halves `112213643824322` / `135816570577245`.
- **`StarterPlayerScripts.OrnateSliceScaler`**: tag `OrnateSlice` + attribute `BaseSliceScale` (1080p value) →
  SliceScale = base × screenHeight/1080. Art detail only; never Position/Size/parent. New ornate frames reuse it.

## Story page (B174)
The island list is replaced by the stage carousel: `story-carousel.md` (`StoryMap.Carousel` + `PlayController.StoryCarousel`).

## Hazards
- `PlayController` sits at Luau's **200-local limit** ("Out of local registers" killed boot once): add new state
  to the `V3` table or inside `do` blocks, never as new top-level locals.
- `RS.AlamatUI.Templates.AlamatPlate` is authored `Visible=false` and the plate colour is the ROOT
  `BackgroundColor3` (`Theme.plateColor(theme)`), not the `Theme` attribute alone — set both on a clone.
- `ClientEvents.OpenStageSelect` opens the menu on the STORY MAP page (existing behaviour); Back shows the cards.
