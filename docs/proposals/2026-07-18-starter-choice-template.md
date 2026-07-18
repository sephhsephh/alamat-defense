# Proposal: remove the seeded starter Archer from ProfileTemplate
<!-- from: AD-Lobby | to: AD-Game (owner of ProfileTemplate / save schema) | 2026-07-18 -->

## What

Change `shared/src/ProfileTemplate.luau`:

```luau
-- from
Towers = {
    Archer = { MetaLevel = 1, XP = 0 },
},
-- to
Towers = {},
```

and update the comment above it (new players no longer auto-start with an Archer).

## Why

AD-Lobby built the first-join **starter tower choice** (approved by user 2026-07-18):
`StarterChoiceService` + `StarterChoiceScreen` offer 3 towers (dev-editable
`RS.Configs.StarterTowerConfig`, currently Archer/Knight/Mage); the pick is granted into
the profile. Eligibility = profile owns ZERO towers.

While the template seeds Archer, a fresh profile is never towerless, so the picker never
triggers — and ProfileStore's `Reconcile()` re-fills missing template keys each session, so
even a Lobby-side removal of Archer would be undone. The seed must go from the template
itself, in the owner's session.

## Impact / safety

- **No shape change**: `Towers` stays `{ [string]: OwnedTower }`. In AD-Lobby's reading no
  SCHEMA_VERSION bump or migration is required (default-value change only) — owner's call.
- **Existing profiles unaffected**: their `Towers.Archer` is already materialized data;
  removing the template seed does not delete it (Reconcile only ADDS missing keys).
- **Fresh-account safety**: the "always able to field a loadout" guarantee moves from the
  template to the Lobby picker (modal, mandatory, granted before any launch). A fresh
  account that somehow reaches the Game place towerless plays a match with an empty
  hotbar — same as today's pre-fix behavior, and impossible via the normal Lobby entry.
- **Shared-module protocol applies**: rehash `shared/manifest.json`, redeploy BOTH Places
  (or mark the non-deployed Place stale + PENDING per the landing checklist).

## Requested action (AD-Game session)

1. Edit template as above; decide on version bump (AD-Lobby believes none needed).
2. Update `shared/src/` + `manifest.json` hashes; deploy to Game; update
   `docs/contracts/save-schema.md` if it mentions the starter Archer.
3. Add PENDING for Lobby redeploy of ProfileTemplate (AD-Lobby clears it next bootstrap).
