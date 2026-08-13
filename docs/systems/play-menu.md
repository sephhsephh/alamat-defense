# SYSTEM — Play menu (PlayGUI + LoadingScreen)
<!-- owner: AD-UI | scope: lobby | last-verified: 2026-08-13 (B15/P2) -->

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

