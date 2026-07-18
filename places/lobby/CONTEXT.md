# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-07-18 -->

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
    `StarterGui.PartyScreen`) — teleport contract **v1**. `GamePlaceId` = **125430066355564**
    (real Game place id, set 2026-07-18); launch path complete and verified.
  - **MatchReturn v1 handling (2026-07-18):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (validates PayloadVersion==1 / Outcome / stage; drops
    unknown `SuggestNextActId` — stale mirror fails safe), serves it via `Remotes.GetMatchReturn`
    (read-only). `StarterGui.ReturnScreen` = welcome-back banner (outcome + stage; CONTINUE on
    Victory-with-successor fires `RS.ClientEvents.OpenStageSelect`). `StageSelectScreen` listens
    and pre-selects the suggested next act (also silently on load). Studio harness: toggle the
    `DevSimulateReturn` attribute on MatchReturnService (`[Test]` log).

Run the constitution's bootstrap ritual + `tools/hash_shared.luau` at the start of every
session; reconcile before any work if a shared hash drifts.

## v2 candidates (not built)

- Gacha/banners (uses `PlayerInventoryService.GrantTower` semantics + Items tickets) —
  gated on Phase A schema v2 (AD-Game).
- Party polish: cross-server invites / persisted parties (v1 is single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub.

## Open PENDINGs (see STATE.md)

- None targeting the Lobby. (Both sides config-complete 2026-07-18; next: USER publishes
  both Places and runs the first LIVE end-to-end — lobby → reserved match → return.)

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
