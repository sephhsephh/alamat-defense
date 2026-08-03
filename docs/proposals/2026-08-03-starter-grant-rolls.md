# Proposal: roll StatRolls in the Lobby's starter grant

<!-- from: AD-Game | to: AD-Lobby (owner of StarterChoiceService) | 2026-08-03 -->

## What

In `StarterChoiceService` (Lobby canon), when granting the first-join starter unit, roll its
`StatRolls` instead of leaving the hardcoded midpoints. Mirror what `PlayerInventoryService.GrantUnit`
now does (AD-Game, 2026-08-03):

```luau
-- StatGradeConfig is shared canon (RS.Configs.Meta.StatGradeConfig) as of 2026-08-01,
-- so the Lobby can require + call it directly.
local StatGradeConfig = require(ReplicatedStorage.Configs.Meta.StatGradeConfig)

-- one persistent Random at module scope (NOT Random.new() per grant -- same-frame calls can
-- correlate and hand out identical rolls):
local statRng = Random.new()

-- in the grant:
StatRolls = StatGradeConfig.RollAll(statRng),
```

Keep every other field of the granted UnitInstance exactly as it is today — this only changes the
`StatRolls` value from `{DMG=0.5, RNG=0.5, SPA=0.5}` to a real roll.

## Why

AD-Game wired the roller into its own grant paths (`GrantUnit`, `DevSetOwnedTowers`) on 2026-08-03,
so gacha/reward/dev-seeded units now roll real quality. The Lobby's starter grant is the **one
remaining path** that still writes the hardcoded midpoints, so a brand-new player's first unit is
always grade "C" / exact-midpoint stats while everything they get afterwards varies. Fixing it here
makes the very first unit consistent with the rest of the game.

## Impact / safety

- **No contract or shape change.** `StatRolls` is already part of the v2 `UnitInstance`; this only
  changes the value written. No `SCHEMA_VERSION` bump, no migration, no drift surface.
- **Shared module already deployed.** `StatGradeConfig` is drift-green in both Places (hash
  `49a6edfd`), so the Lobby requires it with no new deploy.
- **Existing starter units are grandfathered** at 0.5 (append-only; we do not rewrite saved data),
  exactly like AD-Game's migration decision.
- **Ownership:** `StarterChoiceService` is AD-Lobby canon — AD-Game must not edit it, hence this
  proposal rather than a direct change.

## Requested action (AD-Lobby session)

1. Add the `StatGradeConfig` require + a module-level `statRng`.
2. Change the starter grant's `StatRolls` to `StatGradeConfig.RollAll(statRng)`.
3. Verify live (real grant, not `execute_luau`): the starter unit's rolls differ run-to-run and
   land in 0..1; `GetUnitViews` now shows a non-"C" grade sometimes.
4. Clear the PENDING in `STATE.md`.
