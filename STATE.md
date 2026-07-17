# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-07-17 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v1)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** ("Alamat Defense" in Studio) — the playable match Place. Healthy. Persistence
  live (mock-verified in Studio; real-DataStore save/rejoin test still to do). Dev harness
  (`MatchLifecycleSmokeTest`, Studio-gated) auto-starts Stage1_Act1 ~3s after join.
- **Lobby** — DOES NOT EXIST YET. Next major build. See `places/lobby/CONTEXT.md` for the
  planned scope and `docs/contracts/teleport.md` (draft v0) for the handoff contract.

## Open PENDINGs

- **PENDING (Lobby, blocked-on-creation):** deploy shared modules v-current
  (ProfileTemplate 29a2e7b6, PlayerDataService d1d34aef, ProfileStore 1e3a6f3f) when the
  Lobby place is created.
- **PENDING (Game):** real-DataStore persistence test — enable Studio API access, play,
  rejoin, confirm profile round-trip.
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
