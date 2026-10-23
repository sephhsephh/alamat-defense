# Proposal (AD-Lobby -> AD-UI): SettingsUI gives up too early on a slow join

<!-- from: AD-Lobby B172 | to: AD-UI (owner of the unified settings system, shared canon) | 2026-10-23 -->

## What happens
`StarterPlayer.StarterPlayerScripts.Client.UI.SettingsUI` (shared canon, both Places) waits
`playerGui:WaitForChild("Settings", 10)`. If the StarterGui clone has not arrived in 10 s it warns
"StarterGui.Settings is not in this Place yet" and returns -- the settings panel is dead for the whole session.

After the B172 Lobby rebuild (bigger map, more meshes streaming in around spawn) a Studio join takes ~6.7-9 s and
PlayerGui fills late: SettingsUI hit the 10 s timeout in 2 of 3 Play runs (B172), although `StarterGui.Settings`
exists. Slow phones will hit it more. `UIKit.Notify` printed a similar "missing" once (B172 run 1).

## Proposed change (owner to decide)
- Wait much longer (e.g. 60 s) or without a timeout but non-blocking: `task.spawn` the rest of the boot after a
  `WaitForChild("Settings")` with a long timeout, and keep `BootComplete` honest for ScreenBootWatchdog.
- Same audit for other boot-time `WaitForChild(..., <=10)` on PlayerGui screens (UIKit.Notify's Notifications check).
- Shared canon: re-hash, update `shared/manifest.json`, deploy to the Game too (PENDING per the contract protocol).

## Not changed by AD-Lobby
Nothing was edited (single-writer rule). Lobby-side mitigation done in B172: shared kit textures (22 -> 11),
backdrop StreamingMesh LOD, fewer trees -> join veil 9.3 s -> 6.7 s.
