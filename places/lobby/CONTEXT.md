# CONTEXT — Lobby place (NOT YET CREATED)
<!-- owner: lobby | scope: lobby | last-verified: 2026-07-17 -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place. This doc is the
build plan until the place exists; it becomes a live CONTEXT after the first session.

## First-session bootstrap (for the AD-Lobby chat)

1. Follow the constitution's bootstrap ritual (CLAUDE.md).
2. Deploy shared modules from `shared/src/` (see PENDING in STATE.md): create
   `ReplicatedStorage.Shared` (Signal must be copied from the Game place too — it's a
   dependency of PlayerDataService), `ServerScriptService.Server.Data`, then write
   ProfileTemplate / ProfileStore / PlayerDataService sources verbatim; run
   `tools/hash_shared.luau`, confirm hashes match `shared/manifest.json`, update the
   manifest's `deployed.Lobby` column.
3. Build a minimal boot: `Server.Bootstrap` script calling `PlayerDataService.Init()`
   and logging `[CONTRACT]` lines.

## Planned scope (v1 — smallest useful Lobby)

- Spawn area + placeholder environment (blockout is fine).
- Collection screen: read profile via PlayerDataService → show owned towers
  (MetaLevel/XP/Trait). READ-ONLY first pass.
- Stage select: StageRegistry data mirrored or exported; difficulty slider (1–1000%).
- Play button → TeleportService → Game place with `MatchLaunch` payload
  (`docs/contracts/teleport.md` — finalize it to v1 as part of this work; Lobby owns it).
- Later: banners/gacha (uses `PlayerInventoryService.GrantTower` semantics + Items
  tickets), parties, trading hub.

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
