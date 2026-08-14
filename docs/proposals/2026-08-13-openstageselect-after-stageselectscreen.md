# PROPOSAL — `ClientEvents.OpenStageSelect` has no listener after B19

<!-- author: AD-Lobby (B19, P6) | for: AD-UI (owner of PlayGUI's controllers) | 2026-08-13 -->

## What happened

PlayGUI **P6** deleted `StarterGui.StageSelectScreen` — blueprint `playgui.md` §2 B-5 mandates it at
exactly this session-task, and the screen was 100% script-built with 1 descendant.

Callers were re-grepped before the deletion (the A7 `GetCollection` retirement precedent). Two
findings:

1. **`GetStages` survives.** `ReturnScreen.Controller` still invokes it and
   `Server.Lobby.LobbyServices` still serves it. `RS.Remotes` stays at 15 entries. Nothing to do.
2. **`RS.ClientEvents.OpenStageSelect` is now orphaned.** `StageSelectScreen.Controller` line 176 was
   its **only** listener. `ReturnScreen.Controller` line 66 still FIRES it, on the CONTINUE button
   shown after a victory with a `SuggestNextActId`.

**Net effect: ReturnScreen's CONTINUE button is inert.** It fires into a BindableEvent nobody is
listening to. Nothing errors and nothing warns — the button simply does nothing.

## Why P6 did not just fix it

The replacement behaviour is "open the Play menu on `StoryModeFrame` with act X pre-selected". Every
piece needed for that is private to **AD-UI's** files:

- `PlayGUIController` (P2) holds `openMenu()` and `goTo(name)` as locals.
- `StoryModeController` (P3) holds `selectAct(actId)` as a local.

There is no shipping-path seam into either. The only existing entry points are the `DevGoto` /
`DevSelectAct` **harness attributes**, and those are test fixtures — P3's own header says the harness
"runs the SAME function a real click runs", but wiring product behaviour through a Dev attribute
would make the harness load-bearing and impossible to remove.

CLAUDE.md's single-writer rule is explicit: a non-owner writes a proposal plus a PENDING rather than
editing another system's canon. So that is what this is.

## Proposed shape (AD-UI's call, not a specification)

Add ONE shipping-path entry to `PlayGUIController`, e.g. a `BindableFunction`/`ModuleScript` seam
`OpenTo(frameName: string, actId: string?)` that:

1. runs the existing `openMenu()` (veil → hide other GUIs → camera),
2. `goTo("StoryModeFrame")`,
3. and, when `actId` is given, asks `StoryModeController` to select it.

Step 3 needs `StoryModeController` to expose `selectAct` — the smallest version is a `BindableEvent`
under `PlayGUI` that the controller listens on, which keeps the two files decoupled exactly the way
the `SelectedAct` attribute channel already does.

Then `LobbyController`/`PlayGUIController` (whichever AD-UI prefers) listens to `OpenStageSelect` and
calls `OpenTo("StoryModeFrame", actId)`.

**Do NOT add a second selection channel.** `SelectedActId` + `SelectionSerial` on
`StoryModeFrame.SelectedAct` remain the only coupling; this proposal adds a COMMAND path in, not a
second source of truth about what is selected.

## Interim options if this is not scheduled soon

- **Leave it.** The button is dead but harmless; MatchReturn's banner still shows the outcome, and
  the player can reach the next act through Play → Story Mode in two clicks.
- **Hide CONTINUE** when nothing can consume it. That is a change to `ReturnScreen`, also AD-UI's,
  and it trades a dead button for a missing one — probably worse than waiting for the real fix.

P6 recommends leaving it and doing the real fix in an AD-UI session.
