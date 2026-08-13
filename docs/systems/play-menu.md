# SYSTEM — Play menu (PlayGUI + LoadingScreen)
<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-13 (B16/P3) -->

Split out of `docs/systems/lobby-ui.md` at B15 when that file passed its 300-line cap (ADR-0006
governs STATE.md only; every other doc splits). Implementation law is `docs/blueprints/playgui.md`
— read it before changing anything here. Session tasks P1–P7 live in its §9.

## `LoadingScreen` — the game-wide veil (P2/B15). Blueprint `playgui.md` §4

`StarterGui.LoadingScreen`: `DisplayOrder = 200` (above ObtainRewardsGUI's 100),
`IgnoreGuiInset = true`, **`ResetOnSpawn = false`**. Real instances only —
`Root` (CanvasGroup, the one property the whole veil fades on) → `Backdrop` (`Active = true`, sinks
input) + `TitleLabel` + `TipLabel` + `ProgressTrack.Fill` (indeterminate sweep) + `Spinner`.
API is the child ModuleScript **`LoadingScreenController`**: `Show(reason: string?)` / `Hide()` /
`IsShown()` / `SetTitle()`. Both calls RETURN IMMEDIATELY and wait on their own thread, so a button
handler is never yielded. A `generation` counter makes overlapping Show/Hide safe — a stale thread
drops its result instead of stranding the veil half-faded and swallowing input forever.
**Lobby-local by deliberate decision** (§4) — NOT in `RS.Shared.UIKit` / `RS.UITemplates.Kit` and
NOT under drift control. Because the module lives inside the ScreenGui, "promoting" it later is
just copying the ScreenGui. Tunables are ScreenGui attributes: `FadeInTime`, `FadeOutTime`,
`SpinnerPeriod`, `SweepPeriod`, `MinShowTime`.

## `PlayGUI` — the Play menu shell (P2/B15). Blueprint `playgui.md` §3/§5/§6/§10/§11

`StarterGui.PlayGUI` + `PlayGUIController`. ScreenGui is now `Enabled = false`,
**`ResetOnSpawn = false`** (it was `true`, the UnitsGUI stale-reference trap), `DisplayOrder = 20`,
`IgnoreGuiInset = true`.

- **Entry/exit (§3):** `HUD.Left.Buttons.Play` → `LoadingScreen.Show` → snapshot + disable every
  other ScreenGui → `PlayGUI.Enabled = true` → `Main.MainMenu` → camera → `Hide`. `LeaveButton`
  reverses it and restores each screen to its REMEMBERED state, not blanket-true.
- **The three frames are `CanvasGroup`s, not `Frame`s.** §10 specifies the fade as
  `GroupTransparency`, which only a CanvasGroup has, so P2 converted `MainMenu`/`StoryModeFrame`/
  `LobbyFrame` in the **Edit** datamodel. Every carried property, every child and the child order
  came across unchanged (captured before/after), so all of §7/§8's paths still resolve. Side effect
  to know: a CanvasGroup rasterises its descendants, so descendant `ZIndex` is local to the group
  and anything outside the group's rect is clipped.
- **Transitions (§10):** `GroupTransparency` 0↔1 + a 24px slide, `0.22s` Quart/Out, the two halves
  overlapping by half. **Each frame's authored `Position` is captured ONCE at startup and every
  transition ends by force-assigning it** — offsets are never accumulated. Input is ignored while a
  transition is in flight (`DiagTransitionCount` proves the double-fire guard fired).
- **Camera (§5):** Scriptable at `Workspace.PlayGUICamera.CFrame`. That CFrame is the USER'S
  framing — it is **READ, never written**. Parallax is a cursor-derived rotation clamped to
  `ParallaxMaxDegrees` and LERPED, applied as `baseCF * CFrame.Angles(...)`, so the camera's
  POSITION never moves. Released (Custom + Humanoid) on exit **and unconditionally on
  `CharacterAdded`** — dying in the menu must never strand a Scriptable camera.
- **Respawn:** `HUD`/`Hotbar`/`ExpBar`/`UnitsGUI` are `ResetOnSpawn = true`, so they come back
  Enabled. The controller re-hides newcomers via `PlayerGui.ChildAdded` while the menu is open, and
  re-binds the Play button to the re-cloned HUD.
- **Visibly disabled (§6/§11):** `ChallengeModeButton`, `RaidsModeButton`, `EventsModeButton` and
  `FindMatchButton` each got a real `InactiveOverlay` (the DifficultyButtons pattern) with a
  `ComingSoonLabel`, plus `Active`/`Interactable`/`AutoButtonColor = false`. Not a silent no-op.
- **NOT wired, on purpose:** `StartButton` and `InviteButton` are P6 and must use the EXISTING
  `PartyService` reserved-server flow — do not grow a second launch path.

## `StoryModeFrame` — stage/act lists + SelectedAct (P3/B16). Blueprint `playgui.md` §7

`StarterGui.PlayGUI.StoryModeController` (a SECOND LocalScript under PlayGUI). It owns the frame's
CONTENTS only — `PlayGUIController` still owns the frame's visibility, position and transitions, and
this controller never writes `Position`/`GroupTransparency`/`Visible` on `StoryModeFrame`.

- **The three templates are reparented to the controller at runtime** (`StageButtonTemplate`,
  `ActButtonTemplate`, `ItemIconTemplate`) — the SummonController pattern. They stay exactly where
  the user authored them, editable in Studio, and can never render as a stray row. `Spacer`
  (`LayoutOrder = 99`) and both `UIListLayout`s are untouched, so the spacer stays last.
- **Stages are GROUPED from the flat act list** by `StageNumber`. All three acts are Stage 1, so
  today there is exactly ONE stage row, "The Farm". Clicking a stage rebuilds the Acts list;
  clicking an act fills `SelectedAct`. Boot selects stage 1 / act 1.
- **`ActName` gets `ActName`, never `DisplayName`.** Act 1 is DisplayName "The First Alamat" AND
  ActName "Protecting the Fields". Collapsing them ships three wrong titles no test would catch.
- **Labels with no data source are HIDDEN, not zeroed.** The Lobby has NO clear tracking and NO
  reward table: `StageRegistry` carries structure only and `GetStages` returns just that. So
  `LevelsClearedLabel`, `ProgressPercentLabel`, `TotalClearsLabel` and `ClearTimeLabel` are hidden.
  **A zero is a claim; a hidden label is not.** Unhide them when a clear-tracking system lands —
  do not invent one in the UI.
- **The reward preview is PLUMBING ONLY.** `renderRewards(list)` clones `ItemIconTemplate` per
  entry (icon via `UIKit.ItemIcon.ImageFor`, tier paint via `TierConfig`), but the shipping call
  passes an EMPTY list, so the panel renders no cells. Reward numbers are **P5 (AD-GAME)** —
  §8 is explicit that the preview shows what the server will actually pay, so a plausible-looking
  gold figure here would be a lie to the player. The `DevFakeRewards` harness exercises the clone
  path with a synthetic list and is never used by the shipping path.
- **`SelectedDifficultyLable` is deliberately NOT filled.** Filling it needs the ADR-0011 1–100
  display remap, which is P4's named deliverable; writing a second remap here is exactly the
  duplicate-conversion bug ADR-0011 exists to prevent. It keeps its authored "Normal" until P4.
  (A recorded, narrow deviation from §7's literal fill list.)
- **`StageBGImage` is left at its authored image** — no per-act art source exists in the mirror or
  any config. Wiring it needs an art field someone must author first.
- **The selection is published as attributes on `SelectedAct`** — `SelectedActId`,
  `SelectedStageNumber`, and `RecommendedDifficultyWire` (**WIRE scale 1–1000**, ADR-0011; P4
  converts, not this file). This mirrors B9's "publish the selected uuid" pattern and is the ONLY
  coupling P4/P6 need. Read it; do not add a second selection channel.
- Selected rows carry a `Selected` **attribute** and tint their authored `UIStrokeInner`
  (highlight colour overridable via the `SelectionStrokeColor` attribute on PlayGUI). Restyle off
  the attribute rather than editing the controller.
- Harness (all left OFF/""): `DevSelectStage` (a number), `DevSelectAct` (an act id),
  `DevFakeRewards` — each runs the SAME function a real click runs.

### Authoring fixes the user cleared at B16 (blueprint §2 B-3/B-4)

`SelectedAct` had **three** children named `StageNameLabel`. They were not duplicates — they were
three different labels copy-pasted without renaming, so "delete two" would have thrown away real
content. Renamed by their text: `"Total Clears : 0"` → **`TotalClearsLabel`**,
`"Clear Time : 00:00:00"` → **`ClearTimeLabel`**; the real `"Stage Name"` one kept its name.
`RewardsScrollingFrame.ItemIcon` (an **ImageButton**, not a label) → **`ItemIconTemplate`**,
`Visible = false`.

