# Doc index (one line each — read only what the task needs)

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
