# Contract: Save Schema
<!-- owner: game | scope: global | version: 1 | last-verified: 2026-07-17 -->

Canonical implementation: `shared/src/ProfileTemplate.luau` (deployed to
`ReplicatedStorage.Shared.ProfileTemplate` in every Place). This doc explains it; the
module IS the contract. Store name: **"PlayerData"**, key `u_<userId>`, one profile per
player for the whole Experience.

## v1 shape

```luau
{
	SchemaVersion: number,            -- always present; drives Migrate()
	PlayerXP: number,                 -- account-level XP
	Currency: number,                 -- soft currency (match rewards, future shop spend)
	Items: { [string]: number },      -- itemId -> count (banner tickets, reroll tokens, drops)
	Towers: { [string]: {             -- towerId -> owned record
		MetaLevel: number,            -- 1..100 (clamped defensively on read)
		XP: number,
		Trait: string?,               -- nil = no trait
	} },
	Settings: { [string]: any },      -- client settings, SettingsConfig.Sanitize'd
}
```

New-profile defaults: template plus starter `Archer = { MetaLevel = 1, XP = 0 }`.

## Access rules

- Only `Server.Data.PlayerDataService` opens/closes sessions. Everything else reaches data
  through it (or through `PlayerInventoryService` / `SettingsService`, which wrap it).
- Mutations write directly into `profile.Data` (autosaved). Never copy-out/copy-in.
- Session locking: exactly one server holds a profile. On teleport the destination's
  `StartSessionAsync` negotiates the handoff automatically; source must not write after
  the player leaves. (Lobby/Game both follow this — no custom handoff code needed.)
- JSON-safe values only (no Instances/userdata/mixed tables).

## Change protocol

Bump `SCHEMA_VERSION` by 1 + add `Migrations[old]` step + update this doc's version line +
PENDING for other Places in `STATE.md`. Never edit or remove an existing migration.

## Version history

- **v1** (2026-07-17): initial adoption. Prior in-memory shape ported 1:1; no live players
  existed, so no migration from pre-ProfileStore data.
