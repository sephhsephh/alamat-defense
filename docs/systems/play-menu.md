# SYSTEM — Play menu (PlayGUI + LoadingScreen)
<!-- owner: AD-UI (screens/controllers) + AD-Lobby (flow/launch) | scope: lobby | last-verified: 2026-08-13 (B19/P6) -->

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
- **`StartButton`/`InviteButton` were wired at P6 (B19)** — see the LobbyFrame section below. They
  use the EXISTING `PartyService` reserved-server flow; there is still only one launch path.

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
- **The reward preview is LIVE since B21** — see its own section below. (It was plumbing-only from
  P3 until then, because the curve did not exist in this Place.)
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

## The reward preview (B21). Blueprint §8 · curve owned by AD-Game

`StoryModeController.refreshRewards()` reads the SHARED `RS.Configs.Global.RewardScalingConfig`
(deployed here at B20) and renders the band the Game's `RewardCalculator` actually rolls inside.
**One curve, both sides** — the preview cannot show a number the server would not pay.

- **It reads `DifficultyWire`, never `DifficultyUI`.** ADR-0011: `DifficultyScale` is the one
  UI↔wire conversion in this Place. The curve takes the WIRE value (100–1000); feeding it a UI
  1–100 value pays MAX gold for a normal match. **Grep before adding any arithmetic on a
  difficulty number.**
- **`curveId` is `nil` on purpose.** The Lobby's `StageRegistry` mirror carries structure only, so
  there is no per-act `GoldCurve` here; `nil` resolves to `DefaultCurve = "Standard"`, which all
  three acts name today. If a future act names a different curve, add that ONE field to the mirror
  then — do not invent it now.
- **A band is not a quantity.** `renderRewards` paints `"x" .. qty`, which cannot express
  "Gold 100–300": `Qty = min` understates the payout, `Qty = max` overstates it, and two Gold cells
  reading `x100`/`x300` render as *two* rewards. So an entry may carry an optional **`QtyText`**
  that overrides the badge outright; item cells keep the existing `x<qty>` behaviour untouched.
- **It TRACKS the slider.** `refreshRewards` is called from `fillSelectedAct` **and** from
  `GetAttributeChangedSignal` on `SelectedAct`'s `DifficultyWire` and `DifficultyMode`. Wired at the
  act-selection site alone the panel would freeze at the act's opening difficulty and then
  contradict the slider the player is dragging — exactly what §8 exists to prevent, and worse than
  the blank panel it replaced.
- **Insane ADDS cells; it does not change the band.** `RewardScalingConfig.ItemsForMode(mode)`
  returns `BannerTicket` + `TraitRerollToken` on Insane and an empty list on Normal. Mode is a
  separate axis from the slider, so the gold curve is identical under both.
- **A missing `DifficultyWire` renders BLANK, not a normal band.** `DifficultyController` publishes
  on its own boot, but script order between the two controllers is not guaranteed; a band not tied
  to a real difficulty would be a claim. `refreshRewards()` is also called once at connect time to
  pick up anything published before the listeners existed.
- Verified live at B21: wire 100 → `100-300`, 545 → `199-399`, 1000 → `300-500`, matching
  `GoldBand` exactly; the panel re-rendered as the slider moved; Insane added exactly 2 cells with
  the band unchanged.

## `OpenStageSelect` — the shipping-path way in (B21)

`ClientEvents.OpenStageSelect:Fire(actId)` **opens PlayGUI on StoryModeFrame with that act
selected.** `PlayGUIController` is its listener and **this is PlayGUI's public open event.**

- **Why it exists:** P6 deleted `StageSelectScreen` at B19 and that screen's Controller was the
  event's ONLY listener, so `ReturnScreen`'s CONTINUE button had been firing into nothing since —
  no error, no warning, the button simply did nothing.
- **Why no new event was invented:** `lobby-ui.md` recorded that PlayGUI had no Open event and to
  add one "the day a second thing needs to open it". That day is ReturnScreen — and
  `OpenStageSelect` already exists and already carries exactly the right argument, so a near-
  duplicate `OpenPlayMenu` would have been pure surface area.
- **`PlayGUI.Commands.SelectAct`** (a real authored `BindableEvent`) is the hop from the shell to
  the story lists: `selectAct` is a local in `StoryModeController` and `openMenu`/`goTo` are locals
  in `PlayGUIController`, so neither file reaches into the other. **It is a COMMAND, not a second
  source of truth** — `SelectedActId`/`SelectionSerial` remain the only answer to "what is
  selected". The handler switches STAGE first if the act belongs to a different one, or its button
  would not exist in the Acts list yet.
- **Deliberately NOT routed through `DevGoto`/`DevSelectAct`.** Those are test fixtures; wiring
  product behaviour through them would make the harness load-bearing and impossible to remove.
- **Closed menu → it lands directly on the target frame under the veil** (`openMenuTo`), so the
  player never sees MainMenu flash past. **Already open → it animates across** via the normal
  `goTo`. An unknown act id is refused with a warn and changes nothing.

### Authoring fixes the user cleared at B16 (blueprint §2 B-3/B-4)

`SelectedAct` had **three** children named `StageNameLabel`. They were not duplicates — they were
three different labels copy-pasted without renaming, so "delete two" would have thrown away real
content. Renamed by their text: `"Total Clears : 0"` → **`TotalClearsLabel`**,
`"Clear Time : 00:00:00"` → **`ClearTimeLabel`**; the real `"Stage Name"` one kept its name.
`RewardsScrollingFrame.ItemIcon` (an **ImageButton**, not a label) → **`ItemIconTemplate`**,
`Visible = false`.

## Difficulty — slider + Normal/Insane (P4/B17). Blueprint §7, **ADR-0011 is law**

`StarterGui.PlayGUI.DifficultyController` + the `DifficultyScale` **ModuleScript** beside it.

- **`DifficultyScale` is THE one conversion.** ADR-0011 requires the UI↔wire remap to live in
  exactly one function; making it a ModuleScript makes that greppable and makes P6's launch path
  physically unable to re-derive it. `ToWire(ui)` / `ToUI(wire)` / `Format(ui, mode)`, formula
  verbatim from the ADR: `wire = 100 + (ui - 1) * 900 / 99`, so **UI 1% → wire 100 (normal)** and
  **UI 100% → wire 1000**. Both clamp rather than extrapolate. **Never write a second conversion** —
  redefining the wire field instead is a silent 10×-enemy-health bug across a partial republish.
- **The two scales:** player-facing **UI 1–100**; `DifficultyPercent` on the wire stays **100–1000**.
  `StageRegistry.DifficultyMin/Default/Max` are unchanged at 1/100/1000 and asserted so in the test.
- **Mode is a SEPARATE axis.** An act sits at its normal difficulty at slider 1% under BOTH Normal
  and Insane; mode never enters the conversion. It changes REWARDS (§8) — **P5's row**, not read here.
- **Slider:** click anywhere on `DifficultyGradient` or drag `Handle`. The controller captures the
  AUTHORED geometry once and drives exactly one number on each — `Fill.Size.X.Scale` and
  `Handle.Position.X.Scale` — so restyling or repositioning them in Studio needs no code change.
- **`SelectedAct.SelectedDifficultyLable` is looked up NON-RECURSIVELY, and that is load-bearing.**
  Three instances share that name: the panel's own (a direct child) plus one inside each mode
  button. A recursive `FindFirstChild` returns an arbitrary one and would silently rewrite a
  button's caption — the same class of bug as the triple `StageNameLabel` (B-3). The test asserts
  both button captions still read "Normal"/"Insane" after the panel label is written.
- **The track is TINTED by the active mode — that is what `DifficultyGradient`'s own `UIGradient`
  is for** (user, 2026-08-13): green while Normal is selected, red while Insane is. The colour is
  **copied from the mode button's own `UIGradient` at runtime**, never hardcoded, so restyling a
  button in Studio restyles the track with it and the two cannot disagree. Only `.Color` is copied —
  the track keeps its authored `Transparency` ramp (1 at the top → 0 at the bottom) and `Rotation`.
  The lookup is `FindFirstChildOfClass` (direct children only) because both buttons also carry
  `UIStroke`s that could hold a gradient. **The tint is runtime-only; the authored colour in the
  Edit datamodel is untouched, and that is the one you edit.**
- **Publishes for P6:** `DifficultyUI` (1–100), `DifficultyWire` (100–1000, produced by the one
  conversion — the launch path reads it and MUST NOT convert again) and `DifficultyMode`.
- **Follows P3 via `SelectionSerial`, not `SelectedActId`.** Selecting an act resets the slider to
  that act's `Recommended` (wire 100/150/200 → UI 1/7/12; integer quantisation is expected).
- Harness: `DevSetDifficulty` (a UI 1–100 number), `DevSetMode` ("Normal"/"Insane").

### Two bugs the first P4 run caught — do not reintroduce

- **A stale `dragging` flag hijacked the slider.** Press on the track and release outside the
  window and `InputEnded` never arrives, so bare cursor motion kept driving the value (a set 25%
  was overwritten to 2% on the next mouse move). The mouse branch now re-checks
  `IsMouseButtonPressed` and self-heals the flag. There is a regression test that a set value is
  still set 1.5s later.
- **Re-selecting the SAME act did not re-sync the difficulty.** `SetAttribute` with an unchanged
  value fires no `GetAttributeChangedSignal`, so edge-triggering on `SelectedActId` silently missed
  it. `StoryModeController` now bumps a monotonic **`SelectionSerial`** last in `fillSelectedAct`
  and P4 listens to that. `SelectedActId` remains the single source of truth for *which* act.
  **Anything else that needs to react to a selection should use `SelectionSerial` too.**

## `LobbyFrame` — roster, Invite, LAUNCH (P6/B19). Blueprint §3 tail + §11. Owner: AD-Lobby

`StarterGui.PlayGUI.LobbyController` (the FOURTH script under PlayGUI). It owns the roster, the two
buttons and this frame's three headline labels — nothing else. `PlayGUIController` still owns the
frame's visibility/position/transitions; P6 never writes them.

- **It does NOT reinvent the launch.** `StartButton` fires the EXISTING `Remotes.RequestLaunch`;
  `Server.Lobby.PartyService` does the reserved-server teleport exactly as before. §11's rule that a
  second launch path must never exist is intact — matchmaking (P7) will decide *who*, PartyService
  still decides *how*.
- **It reads `DifficultyWire` and performs NO arithmetic on it.** P4 publishes that number from THE
  one conversion; P6 puts it on the wire unchanged. If the attribute is ever absent the launch is
  **REFUSED** rather than re-derived — a wrong difficulty is a silent 10× enemy-health match
  (ADR-0011). `DifficultyScale` is required only for `.Format`, which renders text and converts
  nothing.
- **TWO name collisions make every lookup non-recursive, and that is load-bearing.**
  (1) `SelectedAct` exists under BOTH `StoryModeFrame` and `LobbyFrame` — the ATTRIBUTES live on the
  Story one, the roster and mirrored labels on the Lobby one. (2) `PlayersFrame` contains a
  ScrollingFrame **also named `PlayersFrame`**, so `FindFirstChild(name, true)` returns the outer
  panel. Same class of bug as the triple `StageNameLabel` (§2 B-3).
- **The lobby panel MIRRORS the story panel** (`StageNameLabel`, `ActNameLabel`,
  `SelectedDifficultyLable`), driven off the published attributes and `SelectionSerial`. This frame
  is the last thing a player reads before committing, so it must not describe a different match from
  the one it launches. **Note the label names differ between the two panels** — Story has
  `ActNumberActNameLabel`, Lobby has `ActNameLabel`. Do not "unify" them in code.
- **`RewardsFrame` on THIS frame is still untouched, and the reason CHANGED at B21.** B19's reason
  ("`RewardScalingConfig` is not deployed here") expired at B20 — the curve is deployed and the
  STORY panel's preview is live. What is left is a scope call: this is `LobbyFrame`, and B21 wired
  only the Story panel the proposal named. Mirroring it here is a small follow-up — reuse
  `refreshRewards`'s shape, read the SAME published `DifficultyWire`/`DifficultyMode`, and do not
  write a second `GoldBand` call site that could drift from the story panel's.
- **`InviteButton` opens the existing `PartyScreen`** (user decision, 2026-08-13) rather than growing
  a second invite path in a frame that has no authored player list. `PartyScreen.DisplayOrder` was
  raised **0 → 30** so it renders above PlayGUI (20) and below LoadingScreen (200). It opens through
  a new **`OpenRequest` attribute seam** on `PartyScreen.Controller`, which runs the same
  `refresh()` the PARTY toggle runs — without that the invite list would show whatever it held when
  the panel was last opened. A fresh value is written every time, because an unchanged attribute
  fires no signal (the trap `SelectionSerial` exists for). PartyScreen remains script-built legacy;
  converting it is its own session.
- **The veil is tied to the server's answer, not to a timer.** `LoadingScreen.Show` on press,
  `Hide` on any `PartyState` `error`. PartyService reports party-full, non-host, unset `GamePlaceId`
  and teleport failure all that way, so the player is never stranded behind a veil.
- Harness (all left OFF/0): `DevRefreshRoster`, `DevFakeRoster` (a count), `DevStart`, `DevInvite`.

### The player-row template (blueprint §2 B-4) — authored at B19, user-delegated

`PlayersFrame.PlayersFrame` held **four copy-pasted `ItemIcon` cards** and no `*Template`. P6 stopped
at the gate and the user chose "repurpose one" over authoring from scratch. So ONE was renamed
**`PlayerRowTemplate`** (`Visible = false`), its `QtyBadge` → **`HostBadge`** (a quantity badge is
meaningless on a player; the authored badge design is reused as-is) with its label → `HostBadgeLabel`
= "HOST", and a **`NameLabel`** was added — the one genuinely new instance, because no player row can
work without a name. `IconImage` carries the avatar.

**The other three copies were HIDDEN, not deleted** (`Visible = false`, reversible). They are the
user's instances and B-3's precedent says look-alike siblings are not automatically junk — but left
visible they would paint as permanent ghost cards beside the real members.

The template is reparented to the controller at runtime (the SummonController/P3 pattern) and the
controller sets **only** Text, Image, Visible, LayoutOrder and two attributes — never `Size` or
`Position`. **Restyle or reposition it freely in Studio; no code change follows.**

Avatars use **`rbxthumb://type=AvatarHeadShot&id=<uid>&w=150&h=150`**, not
`Players:GetUserThumbnailAsync`, which YIELDS — rows are built inside a remote handler and a yield
there stalls the render for every member after the first.

### `StageSelectScreen` RETIRED at B19 (blueprint §2 B-5)

`StarterGui.StageSelectScreen` (100% script-built, 1 descendant) is **deleted**; PlayGUI now covers
stage select, difficulty and launch. Callers were re-grepped first (the A7 `GetCollection`
precedent): no script referenced it by path, and **`GetStages` survives** — `ReturnScreen` still
calls it and `LobbyServices` still serves it, so `RS.Remotes` stays at 15 entries.

**⚠ ONE KNOWN CONSEQUENCE, deliberately not patched here:** `StageSelectScreen.Controller` was the
**only listener** on `RS.ClientEvents.OpenStageSelect`, which `ReturnScreen`'s CONTINUE button fires
after a victory. That signal now has no listener, so **CONTINUE is inert**. Replacing it means giving
PlayGUI a shipping-path "open on this act" entry, which touches `PlayGUIController` and
`StoryModeController` — **AD-UI's canon**, so P6 wrote a proposal instead of editing them:
`docs/proposals/2026-08-13-openstageselect-after-stageselectscreen.md`, plus a PENDING in `STATE.md`.

