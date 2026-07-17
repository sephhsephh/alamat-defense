# ADR-0002: ProfileStore for persistence; Game owns the schema

**Date:** 2026-07-17 · **Status:** Accepted

## Decision

Persistence uses ProfileStore (loleris) with one store ("PlayerData"), one profile per
player for the whole Experience. `ProfileTemplate` (SCHEMA_VERSION + append-only
migrations) is a shared contract module owned by the Game place. `PlayerDataService` is
the sole session owner; domain services (`PlayerInventoryService`, `SettingsService`) are
facades over `profile.Data`. Adopted BEFORE the Lobby split, deliberately.

## Why

- Session locking solves the exact failure mode a multi-Place experience creates: two
  servers (Lobby + Game) writing one player's data across a teleport. StartSessionAsync's
  handoff negotiation replaces custom save/load choreography.
- Retrofitting a schema contract onto two live Places is far harder than splitting Places
  on top of an existing contract.
- Keeping domain-service APIs unchanged meant zero changes to callers (rewards, loadout
  validation, match end screen).
- One profile (not per-Place stores) because Currency/Towers/Items must be identical in
  both Places by definition.

## Consequences

- Every future Place deploys the same three modules (manifest-tracked).
- Settings moved into the profile; the old `PlayerSettings_v1` store is retired (no
  migration needed — pre-launch).
- Dev seeding writes into the (mock) profile; with Studio API access ON it writes real
  data — acceptable, loudly warned in logs.
- Schema changes follow the contract-change protocol (constitution) — the single most
  important discipline in the whole system.
