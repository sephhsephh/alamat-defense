# ROADMAP — feature status for the whole Experience
<!-- owner: all (any chat updates its own system's rows at landing) | scope: global -->
<!-- last-verified: 2026-07-17 -->

Status legend: ✅ done · 🟡 partial/placeholder · 🔲 planned · 💭 idea (not committed)

## Game place — core loop

- ✅ Match lifecycle state machine (WaitingForData→…→Cleanup), Classic mode, win/lose
- ✅ Stage/Act campaign structure (Stage 1, Acts 1–3, NextActId chaining)
- ✅ Waves: overlapping schedule, intermissions, skip votes, auto-advance on clear
- ✅ Difficulty: per-act BaseHealthScale × player slider (1–1000%) × per-wave scaling
- ✅ Economy: kill/wave rewards, wave income, sell/upgrade, Farm income passives
- ✅ Towers: placement (ghost/zones/validation), per-tier attacks, 9 targeting modes,
  traits, meta-level scaling, auto-upgrade + Unit Manager, sell/upgrade UI
- ✅ Abilities: passives (FarmIncome/AllyDamageAura/BonusVsStatus/SummonOnKill),
  actives (Nuke/TempStatBuff/StatusBurst) + Q/C UI, summons (Charger/Fighter)
- ✅ Status effects (Slow/Burn/Stun/Weaken) + elements (Fire/Water/Nature/Light/Dark/…)
- ✅ Game speed 1×/2×/3× on a virtual clock (3× behind gamepass flag)
- ✅ Match end: stats (MVP, per-tower damage/kills, clear time, perfect), rewards commit,
  tower XP/level-ups screen, Next Act validation
- ✅ Persistence: ProfileStore schema v1, session-locked, dev store in Studio
- ✅ Settings (VFX/detail/SFX/auto-skip) persisted in profile
- 🟡 Art: attack anim/VFX/sound asset ids are placeholders; weapon grips approximate
- 🟡 Monetization: MonetizationConfig + 3× gamepass check exist; purchase path unwired
- 🟡 Content: 1 map, 2 enemies, 8 towers, 1 stage — pipeline proven, content thin
- 🔲 Enemy behaviors (Flying/Splitting/Shielding — empty extension point)
- 🔲 More modes (Endless, BossRush — enum'd, not implemented)
- 🔲 Persistence round-trip test (PENDING in STATE.md)
- 💭 Spatial partitioning for enemy queries (only if 20-player counts demand it)

## Lobby place (booted 2026-07-17)

- ✅ v1: shared-module deploy + boot (Signal/ProfileTemplate/ProfileStore/PlayerDataService
  deployed drift-free; `Server.Bootstrap` verified: schema v1 profile from PlayerData_Dev)
- ✅ v1: spawn area / blockout environment (`Workspace.Lobby` hub)
- ✅ v1: collection screen (read-only owned towers from the shared profile — proven end-to-end)
- ✅ v1: stage select + difficulty slider (`StageRegistry` mirror)
- 🟡 v1: Play → teleport to Game — teleport contract v1 + reserved-server-per-party done
  Lobby-side; blocked on `LobbyConfig.GamePlaceId` (user) + Game receiver (AD-Game)
- 🟡 v1: parties (invite/accept/leave, host launch, max 4) — in-memory, single-lobby-server;
  cross-server/persisted parties are v2
- 🔲 v2: gacha/banners (tickets in Items, GrantTower, pity — needs AD-Gacha design)
- 🔲 v2: player level display, currency shop
- 💭 Trading hub, leaderboards, daily quests, battle pass

## Cross-Place

- ✅ Save schema contract v1 shared by all Places (deployed to Game + Lobby)
- 🟡 Teleport handoff: contract v1 finalized; Lobby→Game reserved-server launch built
  (Lobby-side). Game→Lobby return + Game receiver still pending.
- 🔲 Game-side production entry: read MatchLaunch TeleportData (v1) → StartMatch
  (replaces the Studio-gated smoke test as the non-Studio path) — PENDING for AD-Game
- 🔲 First Integration session: lobby → match → rewards → return, end-to-end
- 💭 Tutorial place; event worlds

## How to update this file

At landing, flip the rows your session changed (✅/🟡/🔲), add new planned rows where
they belong, and keep 💭 ideas at the bottom of each section. Detail lives in system
docs/CONTEXT files — this is the one-glance status board.
