# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-07-18 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v1)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the playable match Place. Healthy.
  Persistence live; Studio saves go to the separate **PlayerData_Dev** store (verified
  with API access ON, DataStoreState=Access). **Production entry receiver `MatchEntryService`
  built 2026-07-18** (reads `TeleportData.MatchLaunch` v1 → StartMatch); `MatchLifecycleSmokeTest`
  is now the Studio fallback (stands down when a MatchLaunch payload is present). `ReturnToLobby`
  now sends `MatchReturn` v1 + teleports to the Lobby — **`GameConfig.LobbyPlaceId` set
  (83342803778137, verified vs live Lobby PlaceId, 2026-07-18 Integration)**.
- **Lobby** (Studio: "Alamat Defense - Lobby") — **v1 built 2026-07-17**. Data layer drift-free
  (`RS.Shared.{Signal,ProfileTemplate}`, `SSS.Server.Data.{ProfileStore,PlayerDataService}`) +
  `Server.Bootstrap`. Scene: `Workspace.Lobby` blockout hub. Flow: read-only collection screen
  (`LobbyServices` GetCollection/GetStages), stage select + difficulty (`RS.Configs.StageRegistry`
  mirror), party system + reserved-server teleport (`PartyService`, `RS.Configs.LobbyConfig`,
  teleport contract **v1**), **GamePlaceId set (125430066355564, 2026-07-18)**. **MatchReturn v1
  handling built 2026-07-18** (`MatchReturnService` + `ReturnScreen` banner + StageSelect
  pre-select of `SuggestNextActId`; verified via `[Test]` sim + `[DIAG]`).

## Open PENDINGs

- ~~PENDING (Lobby): deploy shared modules on creation.~~ **DONE 2026-07-17** — all four
  shared modules deployed drift-free; manifest `deployed.Lobby` current.
- ~~PENDING (Lobby, USER ACTION): set `LobbyConfig.GamePlaceId`.~~ **DONE 2026-07-18** —
  set to 125430066355564; real launches now reach ReserveServer + TeleportAsync.
- ~~PENDING (Game / AD-Game): build the production entry receiver.~~ **DONE 2026-07-18** —
  `MatchEntryService` reads `TeleportData.MatchLaunch` v1 → validate → `MatchDirector.StartMatch`
  (smoke test now Studio fallback). `ReturnToLobby` sends `MatchReturn` v1 + teleports back.
- ~~PENDING (Game, USER ACTION): set `GameConfig.LobbyPlaceId`.~~ **DONE 2026-07-18
  (Integration)** — found set to 83342803778137, verified equal to the live Lobby
  instance's `game.PlaceId`; stale STUB comment cleaned. Teleport loop config-complete.
- **PENDING (USER ACTION):** first LIVE end-to-end teleport test — publish BOTH Places,
  then in the Roblox client: lobby → stage select → reserved match → play → return →
  banner + next-act pre-select. Studio cannot run real teleports; both sides' harnesses
  are verified (this session), so remaining risk is live-only (reserved servers, join data).
- **PENDING (Game):** persistence round-trip test — play, earn rewards, stop, play again,
  confirm the PlayerData_Dev profile restored (API access already ON; writes verified).
- **PENDING (Game):** in-Studio `ServerStorage.Documentation` is still the richer doc set;
  migrate its contents into `docs/systems/` progressively (doc-gardening sessions), then
  retire it to a pointer.

## Contracts (current versions)

- Save schema: **v1** (`shared/src/ProfileTemplate.luau`) — store "PlayerData"
- Teleport payload: **v1** (`docs/contracts/teleport.md`) — implemented BOTH sides + BOTH
  directions: Lobby sends `MatchLaunch` and consumes `MatchReturn` (banner + next-act pre-select);
  Game receives `MatchLaunch` and returns `MatchReturn`. Config-complete BOTH sides
  (2026-07-18); awaiting the first LIVE end-to-end test (publish + client run, user action).

## Current focus

1. **First LIVE end-to-end teleport test:** all code + config done both sides; drift-free
   and `[CONTRACT]`-verified in Studio (2026-07-18 Integration). USER: publish both Places,
   run lobby → reserved match → return → banner in the client, report console output.
2. Lobby v2 candidates: gacha/banners, real party polish, currency shop, player-level display.
3. Real art/anim asset ids for tower attacks (Game chat).
4. Progressive doc migration from Studio to this repo.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

