# Loading screen -- one veil for both Places
<!-- owner: AD-UI | scope: both | last-verified: 2026-10-10 (B136) -->

`StarterGui.LoadingScreen` (ScreenGui, DisplayOrder 200, ResetOnSpawn false) is the SAME in the Lobby and the Game:
identical instances (`tools/loading_screen_build.luau`) + identical `LoadingScreenController` (checksum-verified at
B136). **Change one, copy it to the other** (re-run the build tool in both and paste the same module source).
Each Place has its own `LoadingBoot` LocalScript beside it. Not shared canon (no manifest entry) -- two Place-local
copies kept in step by hand, like `XPBarGui`.

## API (`require(PlayerGui.LoadingScreen.LoadingScreenController)`)
`Show(reason?, info?)` -- fade in; `reason` = status line (old one-argument callers still work); `info =
{ Kicker, Title, Subtitle, Chips = { ... } }` (no info = plain "LOADING"). `SetInfo(info)`, `SetStatus(text)`
(a trailing "..." animates), `SetProgress(0..1 | nil)` (nil = indeterminate sweep; determinate shows a %),
`SetTitle(text)`, `Hide()` (lands the bar on 100 %, honours MinShowTime, fades out), `IsShown()`.
Attributes: `FadeInTime` 0.35, `FadeOutTime` 0.45, `MinShowTime` 0.6, `TipPeriod` 4.5.

## Look + motion
The user's key-art `BackgroundImage` (slow zoom) under a night shade, a faint rotating gold sunburst, a dark band
behind the centre text, a spinning Philippine-sun emblem with an orbiting arc, kicker / gold serif title /
subtitle, chips that pop in, a divider gem, an animated status line, a gold -> violet progress bar with a shine and
a % counter, and rotating gameplay TIPS (list in the controller).

## Seamless teleports
Every `Show` arms `TeleportService:SetTeleportGui` with a script-free copy of the veil, so a Place change shows
OUR screen. `ReplicatedFirst.ArrivingLoadingScreen` (both Places) catches it on arrival
(`GetArrivingTeleportGui`, `RemoveDefaultLoadingScreen`), and the Place's `LoadingBoot` destroys it once the live
veil is up (failsafe 30 s).

## Where it shows
- **Lobby join** (`LoadingBoot`): TELEPORTING TO LOBBY / RETURNING FROM BATTLE, THE THOUSAND ISLANDS, real
  progress (game loaded -> character -> HUD), min 2.6 s. DailyRewards' auto-open waits for it.
- **Lobby travel**: `Server.Lobby.LobbyMapService` fires `Remotes.LobbyTravel` `{Phase="begin", Kicker, Title,
  Subtitle}` -> waits 0.55 s -> streams + teleports -> 0.45 s -> `{Phase="end"}`. Waystones: TRAVELING TO
  <district> / <service>; water rescue: WASHED ASHORE / ARRIVAL PLAZA.
- **Lobby launches** (`PlayController.stageVeil`): Start = STORY MODE / CHALLENGE / INFINITE + stage, act,
  difficulty; matchmaking = MATCH FOUND; Play-menu open/close veils; Challenge NPC = TODAY'S CHALLENGE.
- **Game first load** (`LoadingBoot`): headline from the teleport payload (`MatchLaunch.StageId`,
  `DifficultyMode`), refined from `GetMatchSnapshot` (StageId, Difficulty, GameMode, TotalWaves, MaxLives):
  kicker STORY MODE / INFINITE MODE / CHALLENGE, stage name, "Act N - name", chips (difficulty, Insane, waves,
  lives); steps Connecting -> Loading map -> Summoning the enemy waves -> Rallying your units; hides once the match
  leaves `WaitingForData` and the character exists (min 3.2 s, 30 s timeout).
- **Game -> Lobby** (`MatchEndUI.goLobby`, `GameSettingsActions` ReturnToLobby): RETURNING TO / THE THOUSAND
  ISLANDS; hidden again if the teleport fails (always in Studio).
