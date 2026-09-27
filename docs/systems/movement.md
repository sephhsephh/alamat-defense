# movement -- sprint, dash, double jump + the character's own animations (both Places)
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

## Character animations (B91)
Ids live in the shared **`CharacterAnimConfig`** (`RS.Configs.Global`), ONE `Id` field per clip:
Walk / Run / Jump / Fall / Idle / DoubleJump / Dash. Empty = Roblox default (Animate slots) or nothing
(Run / DoubleJump / Dash). To change a clip: edit that one field, re-hash, copy to the other Place.
- **Walk -> `walk.WalkAnim` AND `run.RunAnim`.** Stock R15 Animate plays its RUN slot at our speed 16
  (walk only below ~6.7 studs/s), so Walk has to fill both to be seen (user, B91: "Walk = normal").
- **Run = the SPRINT clip**, played by `MovementController` (looped, `Action2`) only while sprinting,
  grounded and moving -- at its own `Speed`, not Animate's ~3.7x time-warp.
- **DoubleJump / Dash** are one-shots at `Action3`, fired by `tryDoubleJump` / `doDash` (so the `Dev*`
  harness drives them). `FitToDash` scales the dash clip to `DashDuration`.
- Writes happen on every `CharacterAdded`. Animate listens to each Animation's `Changed`, so a late
  write still takes (measured). Animate plays its clips at `Core` whatever they were published at.
- Every id is preloaded; a failed id falls back and warns ONCE per session. Rig must be R15 (both Places).
- Verify: the `[DIAG] CharacterAnim ready (R15): Walk=custom, ...` line, then
  `Animator.AnimationPlayed` (names `AD_Run` / `AD_DoubleJump` / `AD_Dash`, and their `Priority`).

## Movement FX (B92)
`RS.CharacterFX.<Jump|DoubleJump|Dash>` (authored, BOTH Places -- copy after editing): a `Sound`
(empty SoundId = silent) + a `VFX` folder, cloned per trigger. Attachment `Part` attribute picks the body
part (default HumanoidRootPart); emitter `EmitCount` = burst, otherwise on for the folder's `ActiveTime`;
Trails/Beams on for `ActiveTime`. Jump's `MuteStockSound = "Jumping"` silences Roblox's jump sound while a
custom one is set. Dash's placeholder Trail needs `FaceCamera = true` (edge-on to the camera otherwise).
Other players: client plays locally, then `RS.Remotes.CharacterFX` -> shared `CharacterFXRelay`
(rate-limited, three action names only) -> every other client.
