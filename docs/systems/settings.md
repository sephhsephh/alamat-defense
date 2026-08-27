# Settings — one system, two Places

<!-- owner: AD-Game (service + config) + AD-UI (screen) | scope: BOTH PLACES -->
<!-- last-verified: 2026-08-20 (B35, live in both Places) -->

Shipped at B35 against `docs/proposals/2026-08-09-unified-settings-both-places.md`, which is now
**resolved**. The user's requirement, verbatim:

> "I have a Settings System in the Game place, I want to use it too. So technically there will be one
> settings system for both game and lobby. But some settings will only be available while in game,
> and some only in lobby. But both should use same structure, same gui."

## The four modules, all shared canon, all at identical paths

| module | path (identical in BOTH Places) | hash |
|---|---|---|
| `SettingsConfig` | `ReplicatedStorage.Configs.Global.SettingsConfig` | `5f0dc44d` |
| `SettingsService` | `ServerScriptService.Server.Settings.SettingsService` | `8b3b1a72` |
| `ClientSettings` | `StarterPlayer.StarterPlayerScripts.Client.Settings.ClientSettings` | `a3a9d32f` |
| `SettingsUI` | `StarterPlayer.StarterPlayerScripts.Client.UI.SettingsUI` (LocalScript) | `8e899dab` |

**The identical paths are the whole trick.** All four already existed in the Game; five Game scripts
require `ClientSettings` by a relative path, and moving it would have meant editing five working
files in another owner's Place for no behaviour change. Keeping every path exactly where it was made
promotion cost **zero consumer edits** — the Lobby simply grew the same `Client/Settings` and
`Client/UI` folders. `SettingsUI` is a LocalScript hashed as source, the `UIKitBootstrap` precedent.

## Scope and Kind — how one system serves two Places

Every schema entry declares two things:

- **`Scope`** — `Both` (default) / `GameOnly` / `LobbyOnly`. Decides where the entry is **shown**.
- **`Kind`** — `Preference` (default) / `Action`. Decides whether it **persists**.

Consequence worth stating plainly: **`SettingsUI` contains no Place-specific branch anywhere.** It
asks `SettingsConfig.EntriesFor("All", place)` and draws the answer. A Place difference is a config
field. Verified live — the Game renders 11 rows across 5 tabs, the Lobby renders 6.

`CategoriesFor()` hides tabs that would be empty in this Place, so neither Place draws a dead tab.

## ⚠ `Sanitize` ignores `Scope`, and that is deliberate

**One profile serves both Places.** If `Sanitize` dropped out-of-scope keys, then the moment a player
changed any setting in the Lobby, every `GameOnly` preference they had — `AutoSkipWave`,
`ShowHealthBar`, `EnableVFX`, `SimplifyHealthBar` — would be sanitized out of the payload and
**permanently lost**. And the reverse in the Game.

So `Sanitize` processes **every** `Preference` regardless of `Scope`, always. `Scope` is a rendering
concern and nothing else. Do not "optimise" it into `Sanitize`.

Proven live at B35: a Game-side save left the `LobbyOnly` `SkipRevealAnim` intact, and a
`MusicVolume` set in the Game was read back and applied in the Lobby.

## Actions

An Action is a button, not a preference: it fires and persists nothing, and `Sanitize` skips it
entirely — storing a button press as a preference is how a "Restart Match" ends up saved to a profile.

**What** an action does is Place-specific, so the config *declares* actions and each Place *supplies*
behaviour through `ClientSettings.RegisterAction(id, fn)`. An action with no registered handler
renders **disabled** and says "N/A", because a button that silently does nothing is worse than one
that visibly cannot be pressed.

Scoping, confirmed with the user at B35: the **Game** shows `Restart Match`, `Return to Lobby` and
`Teleport to Spawn`; the **Lobby** shows only `Teleport to Spawn`.

**All three Game actions are WIRED as of B41** (`StarterPlayerScripts.GameSettingsActions`, the
sibling of the Lobby's `LobbySettingsActions`). They rendered disabled from B35 purely because
nothing registered them. Registering a handler needs **no edit to `SettingsUI`**, which is shared
canon at `7e5a736a` — that zero-cost integration is the entire point of `Kind = "Action"`.

**⚠ `ReturnToLobby` and `RestartMatch` go through the SERVER, not `TeleportService` on the client.**
The teleport contract (v4) is a server concern: `MatchActionHandler` builds the `MatchReturn`
payload, stamps `GameConfig.TeleportPayloadVersion` and calls `TeleportAsync`. A client-side teleport
here would ship an unversioned payload and bypass the contract entirely. So both actions fire the
existing `Remotes.Match.RequestMatchAction` and let the server decide — the same path the match-end
screen's buttons already use. **One teleport path, one place the version is stamped.** Both ask
`UIKit.Confirm` first, because both are destructive mid-match.

`RestartMatch` deliberately sends **no payload**: the client does not get to name a stage. The server
resolves the act from the live match (or the one just played), which is what stops a client
restarting into an act it never played.

Action buttons repaint on every **open**, not just at build. Handlers are registered by separate
scripts and LocalScript run order is not guaranteed, so a build-time-only paint would show "N/A"
forever whenever the registrar happened to run second.

## Two real bugs this system fixed

**1. The volume slider controlled nothing.** `ClientSettings` drove a SoundGroup named `MasterSFX`,
which has never existed in either Place — B32 created `SoundService.Groups.Master > UI/SFX/BGM`. It
now drives those, with one slider each for Music / SFX / UI. A missing group is skipped rather than
created: inventing audio routing behind the player's back is worse than a slider that visibly does
nothing.

**2. Settings silently reverted to defaults on join.** The client fetches once at boot and caches the
answer for the whole session. That fetch regularly landed **before** ProfileStore finished loading,
`Get()` fell through to `Sanitize(nil)` = defaults, and the player spent the session with real
settings on the server and default ones on screen — experienced as *"my settings reset every time I
join"*, with nothing in the log to explain it. `OnServerInvoke` now calls
`PlayerDataService.WaitForData(userId, 20)` first. **That wait is not optional.**

Caught in the Lobby by noticing the server held `MusicVolume 0.25` while the BGM group sat at `0.5`.

## What is NOT canon

**`StarterGui.Settings` is per-place authored ART** — the same split as `UIKit.Confirm`'s
`ConfirmationPopupUI`. Copying a ScreenGui between Places is a **user action** (B26), so `SettingsUI`
degrades to one clear warning and stands down when the art is not there. That is the Lobby's state
until the user copies it across; everything else is deployed and waiting.

## Adding a setting

One config edit. Add a `Defaults` entry and a `Schema` row (with `Scope`/`Kind` if not the default);
the panel builds itself. **Never rename `SoundVolume` to `SFXVolume`** — it shipped as the only volume
key and players have saved values under it, so a rename silently resets everyone. The label changed
at B35; the key did not.

No save-schema bump is needed for new keys: `Data.Settings` has been free-form `{[string]: any}`
since v1.
