# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-07-17 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v1)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the playable match Place. Healthy.
  Persistence live; Studio saves go to the separate **PlayerData_Dev** store (verified
  with API access ON, DataStoreState=Access). Dev harness (`MatchLifecycleSmokeTest`,
  Studio-gated) auto-starts Stage1_Act1 ~3s after join.
- **Lobby** (Studio: "Alamat Defense - Lobby") — place CREATED 2026-07-17, still empty.
  First AD-Lobby session: follow `places/lobby/CONTEXT.md` + `docs/lobby/kickoff-steps.md`
  (in `places/lobby/docs/`). Handoff contract: `docs/contracts/teleport.md` (draft v0).

## Open PENDINGs

- **PENDING (Lobby, blocked-on-creation):** deploy shared modules v-current
  (ProfileTemplate 29a2e7b6, PlayerDataService d1d34aef, ProfileStore 1e3a6f3f) when the
  Lobby place is created.
- **PENDING (Game):** persistence round-trip test — play, earn rewards, stop, play again,
  confirm the PlayerData_Dev profile restored (API access already ON; writes verified).
- **PENDING (Game):** in-Studio `ServerStorage.Documentation` is still the richer doc set;
  migrate its contents into `docs/systems/` progressively (doc-gardening sessions), then
  retire it to a pointer.

## Contracts (current versions)

- Save schema: **v1** (`shared/src/ProfileTemplate.luau`) — store "PlayerData"
- Teleport payload: **v0 draft** (`docs/contracts/teleport.md`) — not yet implemented

## Current focus

1. Lobby place creation + teleport handoff (Lobby chat, once created).
2. Real art/anim asset ids for tower attacks (Game chat).
3. Progressive doc migration from Studio to this repo.
