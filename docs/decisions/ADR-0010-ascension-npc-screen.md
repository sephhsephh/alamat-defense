# ADR-0010 — Ascension is its own NPC-opened screen, not a pane in the Units GUI

<!-- decided: 2026-08-09 (USER, via AD-Gacha at B11) | status: ACCEPTED -->
<!-- deviates from: docs/blueprints/phases-b-f-meta.md, Phase C task C3 -->

## Context

Blueprint C3 says, verbatim: *"**Ascension:** UI in Units screen detail pane (Mythic+ only)…"*.
B9 built exactly that — an `AscensionPanel` inside `UnitsGUI…SelectedUnitFrame`, reading the
selected uuid that B9 also had `UnitsController` publish.

It worked, but it carried costs that only became visible once it existed:

- The pane could only act on whatever the Units screen happened to have selected, so it needed a
  one-line change to **AD-UI's** `UnitsController` to publish that selection at all.
- `UnitsGUI.ResetOnSpawn = true` — the only meta screen set that way — so the controller had to
  re-bind on every character spawn or silently stop working.
- Ascending destroys a duplicate the Units grid is still displaying, and the pane could not refresh
  AD-UI's list, so it shipped with a *"reopen Units to refresh the list"* caveat.
- It made the Units detail pane the home of a second, unrelated system.

## Decision (USER, 2026-08-09)

**Ascension moves to `StarterGui.AscensionScreen`, reachable only by walking up to
`Workspace.Lobby.NPC_Ascension` and using its `ProximityPrompt`.** The pane is removed from
`UnitsGUI` entirely.

**This makes Phase C internally consistent rather than breaking from it.** The blueprint already
specifies *"NPC → UI"* for the trait reroll (C1) and the stat reroll (C2). Ascension was the odd one
out, specified as an in-pane widget. After this, all three Phase C interactions are NPC-driven, and
the Lobby has a reusable pattern for the two that are still blocked.

## Consequences

- **The screen owns its own picker** (Mythic+ only, sorted by ascension level then name), so it no
  longer depends on another screen's selection — and after ascending it just rebuilds its own list.
  **The B9 "reopen Units to refresh" caveat is gone.**
- **No re-binding.** `AscensionScreen.ResetOnSpawn = false`, so the instance persists for the
  session; the `UnitsGUI` re-bind machinery is deleted with the pane.
- **AD-UI's `UnitsController` is no longer involved at all.** The one-line selection publish B9 added
  (`selectedFrame:SetAttribute("Uuid"/"TowerId")`) **stays** — it is now unused by ascension, but
  C2's stat-reroll and C4's feeding panes will want exactly that, and removing it would only mean
  re-adding it later.
- **This is the Lobby's first NPC and first `ProximityPrompt`** — there was no NPC system at all
  before. The prompt has no special privilege: it fires `ClientEvents.OpenAscension`, so a second
  NPC, a HUD button or a teleport pad is a drop-in with no change to the controller.
- The NPC is a **placeholder blockout** (pedestal + neon body + halo + nametag) matching the rest of
  `Workspace.Lobby`. Restyle or replace the model freely — the controller only looks for a
  `ProximityPrompt` anywhere under `NPC_Ascension`.
- **The server did not change.** `AscensionService` / `AscensionRules` and both remotes are
  untouched; this is purely where the client puts the interaction.

## Note for whoever builds C1 / C2

Copy this shape: one NPC, one `ProximityPrompt`, one `ClientEvents.Open*` event, one screen that
owns its own unit picker. Do **not** put a reroll pane back into the Units detail frame.
