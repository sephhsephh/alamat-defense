# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-07-17 -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place.

## Current live state

- **Data layer deployed & drift-free.** `ReplicatedStorage.Shared.{Signal, ProfileTemplate}`,
  `ServerScriptService.Server.Data.{ProfileStore, PlayerDataService}` — all four hashes match
  `shared/manifest.json` (Signal 91becf7a, ProfileTemplate 376e717d, PlayerDataService
  613f0d39, ProfileStore 1e3a6f3f). `Signal` was promoted into `shared/src` this session.
- **Boot:** `Server.Bootstrap` asserts the save contract and runs `PlayerDataService.Init()`.
  Schema v1 profile loads from **PlayerData_Dev** (DataStoreState=Access) — the Lobby shares
  the Game place's profile.
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza.
- **Flow (v1):**
  - Collection (`Server.Lobby.LobbyServices` `GetCollection`, `StarterGui.CollectionScreen`) —
    READ-ONLY owned towers from the profile.
  - Stage select + difficulty (`RS.Configs.StageRegistry` mirror, `GetStages`,
    `StarterGui.StageSelectScreen`) — captures (StageId, DifficultyPercent).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`) — teleport contract **v1**. `GamePlaceId` is **stubbed 0**
    (set it to enable real teleport); the launch path is otherwise complete and verified.

Run the constitution's bootstrap ritual + `tools/hash_shared.luau` at the start of every
session; reconcile before any work if a shared hash drifts.

## v2 candidates (not built)

- Gacha/banners (uses `PlayerInventoryService.GrantTower` semantics + Items tickets).
- Party polish: cross-server invites / persisted parties (v1 is single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub, `MatchReturn` handling on return.

## Open PENDINGs (see STATE.md)

- USER: set `RS.Configs.LobbyConfig.GamePlaceId` to the real Game place id.
- AD-Game: build the `MatchLaunch` v1 receiver (`TeleportData.MatchLaunch` → StartMatch).

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
