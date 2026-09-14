# movement -- sprint (both Places) + dash (Lobby only)
<!-- owner: AD-Game | scope: shared canon, BOTH Places | added: 2026-09-08 (B54) -->

Sprint and dash, added at the user's request (B54). Two shared-canon modules, no Place branch:
- **`RS.Configs.Global.MovementConfig`** (pure, **`19421017`**) -- every number, plus `DashAllowed(place)`.
  **`9c7cbd32` -> `19421017` at B58:** the USER re-tuned movement feel directly in the LOBBY Studio --
  `SprintSpeed` 26 -> **56** and `DashSpeed` 70 -> **300**, two values and nothing else. The bootstrap
  drift check caught the Lobby at 40/41; the user confirmed the change was theirs and said to keep it,
  so B58 RECORDED it as canon (the B22 `ItemCatalog` precedent: a user-authored value change is
  recorded, never reverted and never "fixed"). `shared/src` was rebuilt from disk canon with exactly
  those two edits and PROVED byte-identical to the live Lobby copy by hash BEFORE anything was written;
  the Game was brought to the same bytes in the same session, so no stale `deployed.<Place>` was left
  behind. All three -- Game, Lobby, disk -- are `19421017`.
- **`StarterPlayer.StarterPlayerScripts.Client.MovementController`** (LocalScript, `e2668274`) -- the
  one consumer. Deployed at an IDENTICAL path in both Places (the `ClientSettings` precedent), which
  is why promotion cost ZERO consumer edits.

| | key | gamepad | mobile | Places |
|---|---|---|---|---|
| Sprint (**TOGGLE**) | LeftShift / RightShift | ButtonL3 | auto touch button | Game + Lobby |
| Dash | Q | ButtonR1 | auto touch button | **Lobby only** |

## One binding serves three platforms
Everything goes through **ContextActionService** -- the FIRST use of CAS in this project. One
`BindAction` takes the keyboard key AND the gamepad button in the same call, and
`createTouchButton = true` generates the mobile button for free. That is why there is no
`if UserInputService.TouchEnabled` branch anywhere in the controller: PC, console and mobile are one
code path, and a fourth platform costs one extra `KeyCode`. The mobile button is tinted from
`paintSprintButton()` so the toggle has a visible state; `GetButton` returns nil on PC/console, so
every use is guarded -- cosmetic, never load-bearing.

`Q` is safe: the GAME binds `Q` to a tower Ability, but the dash is never bound in the Game (see
`MovementConfig.DashPlaces`), so the two never coexist.

## Sprint is a TOGGLE, not a hold (user, B54)
Tap to flip; it stays flipped and survives respawn. `applySpeed()` is the **ONE** place `WalkSpeed` is
written and it always writes an ABSOLUTE value from `MovementConfig`, never a delta -- so nothing else
that touches `WalkSpeed` can strand the player at sprint speed (the classic sprint bug).

The **`AlwaysSprint`** setting (`SettingsConfig`, `2bb4a943`, Category `Game`, Scope Both) **PINS**
sprint on. While pinned the toggle is INERT rather than letting a player fight their own setting, and
`ClientSettings.Changed` re-applies the speed so flipping the setting takes effect immediately.

## Dash
A horizontal burst in the direction the player is MOVING, falling back to the way they FACE when
standing still (a dash that does nothing because you were idle feels broken). It re-asserts the
horizontal `AssemblyLinearVelocity` every Heartbeat for `DashDuration` and **leaves Y alone**, so
gravity still applies and the dash cannot launch anyone off the lobby floor. Deliberately **no
BodyVelocity/LinearVelocity instance**: nothing to leak if the character dies mid-dash.

The Place gate is checked in **TWO** places -- at `BindAction` and at the top of `onDashAction` -- so
the only way to dash where it is forbidden is to change `MovementConfig.DashPlaces`. B54's first Game
verify found the harness dashing through the missing binding; that guard is the fix.

## Why the client owns this
`WalkSpeed` is a client-authoritative Humanoid property in Roblox: a server that "validated" it would
be validating a number the client can set anyway. The Lobby is a social space with nothing to win, and
the Game gets sprint only -- no dash -- so nothing here can cross a placement zone it shouldn't.

## Verifying a change
The `Dev*` attribute harness (`DevSprintToggle` / `DevDash`) runs the SAME functions a real key,
gamepad button or touch button runs -- tooling cannot synthesise a key press
(`VirtualInputManager:SendKeyEvent` is blocked: "lacking capability RobloxScript"). Assert on
`Humanoid.WalkSpeed` and on flat displacement from `HumanoidRootPart.Position`.

**`AlwaysSprint` cannot be flipped from `execute_luau`** -- that VM has its OWN require cache, so its
`ClientSettings` is a DIFFERENT instance from the controller's and `Set` never reaches it (B36's
lesson, again). Click the real row instead: `user_mouse_input` with
`instance_path = "LocalPlayer.PlayerGui.Settings.Panel.Content.AlwaysSprint.Toggle"`.

Animations are a DEFERRED follow-up (user: "I'll add the sprinting and dash animation later").
