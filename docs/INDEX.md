# Doc index (one line each — read only what the task needs)

## root-level
- `OWNERSHIP.md` — system → owning chat → home Place → canon location (single-writer registry)
- `ROADMAP.md` — one-glance feature status board: done / partial / planned / ideas (all chats update)

## blueprints/ (implementation law for the meta systems — read before building)
- `phase-a-foundations.md` — schema v2 exact shape + migration, ItemCatalog, Tier/StatGrade/
  Ascension configs, base-stat ranges + resolver, icon kit, session plan A1–A7
- `phases-b-f-meta.md` — gacha/rerolls/economy/seasonal/endgame: algorithms (summon order,
  deterministic rotation, GrantService), config shapes, session plans, cross-phase invariants

## contracts/
- `save-schema.md` — Profile data shape, versions, migration rules (owner: Game). **v1**
- `teleport.md` — Lobby→Game / Game→Lobby TeleportData payloads (owner: Lobby). **v0 draft**

## design/
- (empty — design pillars/economy docs migrate here from Studio progressively)

## systems/
- (empty — richer system docs still live in the Game place's `ServerStorage.Documentation`
  [Architecture, SystemIndex, GameplaySystems, Networking, GameFlow, HowTo, CodingStandards,
  MCPWorkflow]; migrate on touch: whenever a session works on a system, move its doc here)

## decisions/
- `ADR-0001-hybrid-canon.md` — why disk-canon for shared/contracts but Studio-canon for Place code
- `ADR-0002-profilestore.md` — why ProfileStore, schema ownership, session-lock/teleport rules

## proposals/
- (empty)
