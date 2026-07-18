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
  now sends `MatchReturn` v1 + teleports to the Lobby (guarded on `GameConfig.LobbyPlaceId==0`).
- **Lobby** (Studio: "Alamat Defense - Lobby") — **v1 built 2026-07-17**. Data layer drift-free
  (`RS.Shared.{Signal,ProfileTemplate}`, `SSS.Server.Data.{ProfileStore,PlayerDataService}`) +
  `Server.Bootstrap`. Scene: `Workspace.Lobby` blockout hub. Flow: read-only collection screen
  (`LobbyServices` GetCollection/GetStages), stage select + difficulty (`RS.Configs.StageRegistry`
  mirror), party system + reserved-server teleport (`PartyService`, `RS.Configs.LobbyConfig`,
  teleport contract **v1**). Verified in Play: profile from PlayerData_Dev, collection shows owned
  towers, launch validates + hits the GamePlaceId=0 guard.

## Open PENDINGs

- ~~PENDING (Lobby): deploy shared modules on creation.~~ **DONE 2026-07-17** — all four
  shared modules deployed drift-free; manifest `deployed.Lobby` current.
- **PENDING (Lobby, USER ACTION):** set `ReplicatedStorage.Configs.LobbyConfig.GamePlaceId`
  to the real "Alamat Defense - Game" place id. While 0, launch logs `[Teleport]` + skips the
  actual teleport (everything up to ReserveServer is exercised).
- ~~PENDING (Game / AD-Game): build the production entry receiver.~~ **DONE 2026-07-18** —
  `MatchEntryService` reads `TeleportData.MatchLaunch` v1 → validate → `MatchDirector.StartMatch`
  (smoke test now Studio fallback). `ReturnToLobby` sends `MatchReturn` v1 + teleports back.
- **PENDING (Game, USER ACTION):** set `ReplicatedStorage.Configs.Global.GameConfig.LobbyPlaceId`
  to the real "Alamat Defense - Lobby" place id (counterpart to the Lobby's `GamePlaceId`). While
  `0`, `ReturnToLobby` logs `[Teleport]` + skips the actual teleport (everything up to
  `TeleportAsync` is exercised).
- **PENDING (Game):** persistence round-trip test — play, earn rewards, stop, play again,
  confirm the PlayerData_Dev profile restored (API access already ON; writes verified).
- **PENDING (Game):** in-Studio `ServerStorage.Documentation` is still the richer doc set;
  migrate its contents into `docs/systems/` progressively (doc-gardening sessions), then
  retire it to a pointer.

## Contracts (current versions)

- Save schema: **v1** (`shared/src/ProfileTemplate.luau`) — store "PlayerData"
- Teleport payload: **v1** (`docs/contracts/teleport.md`) — implemented BOTH sides: Lobby sends
  `MatchLaunch` (reserved server per party); Game receives it (`MatchEntryService`) and returns
  `MatchReturn` (`ReturnToLobby`). End-to-end blocked only on the two place-id user actions.

## Current focus

1. **Wire the teleport end-to-end:** both receivers now exist (Lobby send + Game receive/return).
   Remaining = two USER place-id actions (`LobbyConfig.GamePlaceId` = 125430066355564;
   `GameConfig.LobbyPlaceId` = the Lobby place id). Then first Integration session: lobby →
   reserved match → return.
2. Lobby v2 candidates: gacha/banners, real party polish, currency shop, player-level display.
3. Real art/anim asset ids for tower attacks (Game chat).
4. Progressive doc migration from Studio to this repo.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

