# ADR-0011 — Difficulty is remapped for DISPLAY only; the wire format stays 100–1000

<!-- decided: 2026-08-09 (USER, via AD-Integration during the PlayGUI blueprint) | status: ACCEPTED -->

## Context

The PlayGUI difficulty slider should read **1% – 100%**, where **1% is the act's normal/default
difficulty** and 100% is the hardest. The user's words: *"fix the difficulty meter to just be
1% - 100% ... in order for us to not get confused."*

What exists today:

| | value | meaning |
| --- | --- | --- |
| `StageRegistry.DifficultyMin` | `1` | |
| `StageRegistry.DifficultyDefault` | `100` | **normal** |
| `StageRegistry.DifficultyMax` | `1000` | 10× |
| `StageConfig.Recommended` | `100` | normal |

`DifficultyPercent` is not a display value. It is a **field in the teleport `MatchLaunch` payload
(contract v2)**, sanitised by the Game's `MatchEntryService`, and consumed as
`finalEnemyHP = baseHP × StageConfig.BaseHealthScale × (DifficultyPercent / 100)`.

## The failure mode that forced this decision

Redefining the existing field so `1` means normal and `100` means hardest is a **silent,
live-breaking change**. The two Places publish separately, so there is a window where a republished
Lobby sends `DifficultyPercent = 100` meaning *"hardest"* to a Game still reading `100` as
*"normal"*. Nothing errors. No `[CONTRACT]` line fires, because the field is present, numeric and in
range. Every match in that window silently runs at **10× enemy health**.

That is strictly worse than the `v1 → v2` teleport cutover, which at least failed LOUDLY: a v1
payload is rejected with a `[CONTRACT]` warn precisely because the version integer moved.

## Decision

**Remap in the UI. Do not touch the wire format.**

- The slider, the labels and everything the player reads use **1–100**.
- The PlayGUI controller converts at the boundary, immediately before building the launch payload:

```
payloadPercent = 100 + (uiPercent - 1) * (1000 - 100) / (100 - 1)
```

  so `UI 1% → 100` (normal) and `UI 100% → 1000` (max), linear in between. The inverse is used when
  rendering a payload value back into the UI (e.g. the MatchReturn banner).

- **`DifficultyPercent` keeps its current meaning, range and name.** `StageRegistry.DifficultyMin/
  Default/Max` are unchanged. `MatchEntryService`, `EnemySpawner` and the teleport contract are
  **untouched**, so no version bump and no synchronised republish.

## Consequences

- **Zero contract risk.** An un-republished Place and a republished one still agree on every number
  on the wire, because no number on the wire changed.
- **The conversion lives in exactly ONE function**, in the PlayGUI controller. Anything that needs
  the player-facing number calls it; nothing else in either Place learns about 1–100. If this ever
  needs to become real, that one function is the seam to cut at.
- **Accepted downside, stated plainly:** the confusion is *moved*, not removed. Players and the
  PlayGUI speak 1–100; configs, `StageRegistry`, the payload, the Game's math and every existing doc
  still speak 100–1000. A dev reading `Recommended = 100` and a player reading `1%` are looking at
  the same difficulty. **Every doc that mentions a difficulty number must say which scale it is on.**
- Reward scaling (blueprint `playgui.md`) is defined against the **UI 1–100 scale**, because that is
  what the player is choosing and what the rewards panel must preview.
- If a later session wants the wire format to genuinely change, it is a **teleport contract v2 → v3**
  under the contract-change protocol: version bump, both Places deployed in ONE session, and a
  synchronised republish. Do not attempt it as a "quick rename" — see the failure mode above.
