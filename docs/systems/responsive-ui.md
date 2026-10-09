# Responsive UI + console hints -- every screen on every device (BOTH Places)

<!-- owner: AD-UI | scope: lobby+game | since: B127 (2026-10-07) -->

User (B127): "fix all ui to look good in all devices, make sure console controls are also included".
Screens are authored at 1080p on PC (the main platform). Runtime adapts them; authors only follow the rules below.

## B131 RULE: SCALE ONLY, NEVER OFFSET (user, 2026-10-08)
User: "use all scale, not offset, never use offset so ui will look same on all device". Every authored
Size / Position / UICorner / UIPadding / list & grid padding is SCALE; a shape that must stay square gets a
UIAspectRatioConstraint; fixed text is TextScaled + a UITextSizeConstraint cap (`AD_TextCap`, its 1080p size in
attribute AD_BaseTextSize -- SettingsUI grows the cap on taller screens). Convert an offset screen with
`tools/ui_to_scale.luau` (`ServerStorage.DevTools.UIToScale`, both Places): `Run(name, {dry=true})` -> `Run(name)`
backs up to `ServerStorage._UIBackup_B131`, converts, and proves the 1080p layout did not move; `Restore(name)`.
Left in offset by design: items placed directly in a ScrollingFrame / UIGridLayout, anything under an
AutomaticSize frame, `*Template*` roots, panels with a `Responsive` UIScale (DailyRewards, TraitReroll fit
themselves), Hotbar (never touched), ScreenFXLayer, UIStroke thickness, UISizeConstraint limits.
**The phone DEVICE boost below is OFF since B131 (DEVICE_MAX = 1)** -- it is what made the UI look zoomed.

## How a screen is scaled (shared `SettingsUI`, UI SCALE section)
- **Effective scale = the UI Scale setting x a DEVICE factor.** Device factor = `560 / short side` clamped to
  1..1.4 (phones only; tablets and PCs are x1, so at 100 % on PC nothing is created at all). Recomputed on
  `ViewportSize` change (rotation, window resize).
- Each top-level panel gets a UIScale `AD_UIScale`, re-anchored INWARD first (`AD_Anchored`). A panel that owns
  its own (animated) UIScale is scaled by Size instead (`AD_BaseSize`). UIScales named `Responsive` are a screen's
  own fit (DailyRewards, TraitReroll) -- left alone. **B134 fits** (authored at 1080p, `s` clamped 0.45..1.6):
  TraitReroll `s = min(H/1080, 0.47 W / reach, 0.9 H / 640)`, `reach` = the IndexPanel's right edge from centre
  (755 px), `Main.Size = 1/s` -- so "Show chances" never leaves the screen (s = 1 at 1920x1080). DailyRewards
  `min(1.2 H/1080, 0.86 W/1080, 0.62 H/300)`.
- **FIT:** a scaled panel never outgrows the screen -- its factor is capped (below 1 if needed) to 96 % of the
  screen, and on an IgnoreGuiInset screen it also clears the Roblox top bar (centred). Last measure kept in
  `AD_BasePx` for panels on hidden screens.
- Hidden screens (never laid out) are scaled the moment they first lay out (`whenLaidOut`).

## Author attributes
| Attribute | On | Effect |
|---|---|---|
| `AD_ScaleGroup` (string) | HUD panels that sit near each other, across screens | the group scales as ONE rigid block about its anchor corner (thirds of the group box), gaps grow too -- members never collide |
| `AD_GroupPivot` (UDim2, screen space) | one member | overrides the group's pivot (the match's bottom row pivots on the hotbar's bottom edge) |
| `AD_ScaleMax` (number) | a panel | caps its scale (1 = keeps its designed size on phones) |
| `B127Responsive` (string) | converted elements | record of the old offset Position (pure scale now) |

Match HUD groups: `HUD.Top` (StatBar pivot, status, banner, vote panel, countdown, boss bar, toasts),
`HUD.Right` (stage tag, right buttons, speed), `HUD.Bottom` (cash, next-wave income, placement bar),
`HUD.BottomLeft` (emote/players/favourite + J/K), `HUD.TopRight`. Hotbar + XP bar are NOT grouped.
**Position HUD elements in SCALE** (an offset from the centre lands in a different place on every screen).

## Console + touch hints (shared `GamepadMenus` + `InputMode`)
- Tag a keycap TextLabel `KeyHint`: keyboard = its text, pad = its `Pad` attribute (missing = hidden), touch =
  hidden; `HideParent = true` hides the whole chip. Game `KeyHints` paints the BOUND key into the label's
  `Keyboard` attribute (so a rebind survives a pad round-trip).
- Tag a menu root `GamepadMenu` (focus on open). Tag HUD button groups `GamepadHud`: **Y** focuses the first,
  Y again steps to the next in `GamepadHudOrder` order, then leaves (the match: right buttons -> J/K corner).
- Every control needs a pad route: a pad button (see the pad map) or a `GamepadMenu`/`GamepadHud` root.
  D-pad Up is reserved by Roblox CoreGui -- do not bind it.
- Pad map (match): A place/upgrade, X sell/rotate, B close/cancel, Y HUD focus / targeting, L1 Unit Manager,
  L2 Stage Info, R1 dash, L3 sprint, R2 (tower panel), D-pad L/R hotbar.

## Tools (Studio, `ServerStorage.DevTools`, run from execute_luau in Edit)
- `UIAudit` (`tools/ui_audit.luau`, both Places): `require(DevTools.UIAudit:Clone()).Run({ hud = {...} })` --
  lays every screen out at 7 device sizes, reports OFF / CLIP / TINY / TOP / OVER (by-design skips in the header).
  Its numbers are at x1 (before the phone boost and FIT). Known false positives: placeholder chip texts,
  SummonReveal rays, BossWarning stripes, the Notifications container box.
- `UIPhonePreview` (`tools/ui_phone_preview.luau`, Game): `.Show(667, 375)` draws the match HUD at phone size
  in the Edit viewport, scaled exactly like runtime (grab it with screen_capture); `.Hide()` removes it.
