# Contract: Save Schema
<!-- owner: game | scope: global | version: 2 | last-verified: 2026-08-01 -->

Canonical implementation: `shared/src/ProfileTemplate.luau` (deployed to
`ReplicatedStorage.Shared.ProfileTemplate` in every Place). This doc explains it; the
module IS the contract. Store name: **"Beta1_PlayerData"** in production, **"Beta1_PlayerDataDev1"**
whenever `RunService:IsStudio()` (via `ProfileTemplate.GetStoreName()`), so playtests and
dev seeds never touch live player data. Key `u_<userId>`, one profile per player for the
whole Experience.

> **Store name (beta reset, 2026-07-31):** `"PlayerData"`/`"PlayerData_Dev"` →
> `"Beta1_PlayerData"`/`"Beta1_PlayerDataDev1"`. **AD-Game confirmed the Game place uses this
> exact store 2026-08-01** (drift check during the v2 work) — no split-brain. Store target only,
> unrelated to the schema version.

## v2 shape (current)

```luau
{
	SchemaVersion: number,            -- always present; drives Migrate()
	PlayerXP: number,                 -- account-level XP
	PlayerLevel: number,              -- account level (loadout slot gating etc.)
	Currencies: {                     -- all soft currencies (was the v1 scalar Currency)
		Gold: number,                 -- gacha/banner roll currency (v1 Currency -> Gold)
		Silver: number, TraitRerolls: number, StatRerolls: number,
		EventTokens: { [string]: number },
	},
	Items: { [string]: number },      -- itemId -> count (caps via ItemCatalog.MaxOwned, A3)
	Units: { [string]: {              -- uuid -> owned unit INSTANCE (was towerId-keyed Towers)
		TowerId: string,
		MetaLevel: number,            -- 1..100 (clamped defensively on read)
		XP: number,
		Trait: string?,
		Shiny: boolean,
		StatRolls: { DMG: number, RNG: number, SPA: number }, -- 0..1 position in range (A3 resolver)
		Ascension: number,            -- 0..3, Mythic+ only (phase C)
		Worthiness: number,           -- 0..100 (phase C)
		Locked: boolean, Favorited: boolean,
		SpiritUuid: string?, ObtainedAt: number,
	} },
	Loadout: { string },              -- up to 6 unit uuids (slot gating by PlayerLevel later)
	Pity: { [string]: { Legendary: number, Mythic: number, Secret: number } },
	Counters: { Global: { [string]: any }, PerUnit: { [string]: { [string]: number } } },
	Quests, LoginStreak, ShopStock, Titles, Spirits, Battlepass, -- exact shapes in ProfileTemplate
	Settings: { [string]: any },      -- client settings, SettingsConfig.Sanitize'd
}
```

New-profile defaults: `Units = {}` (empty) — a fresh account owns NO units; the Lobby's
first-join starter choice grants the first unit (eligibility = zero owned). uuid =
`HttpService:GenerateGUID(false)`.

**Migration 1→2** (`Migrations[1]`): `Currency` → `Currencies.Gold`; each `Towers[towerId]` →
a new `Units[uuid]` instance (mid stat rolls 0.5, Ascension 0, not shiny, ObtainedAt now);
`Loadout = {}` (auto-loadout rebuilds it). `Reconcile()` fills every other new v2 key. Existing
account XP / items / settings are preserved.

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
- **v1 default change** (2026-07-18): removed the seeded starter `Towers.Archer` (now `{}`) so
  the Lobby starter choice can trigger. Default-value only — shape unchanged, version stays **1**,
  no migration. ProfileTemplate hash `376e717d → 8ac5d3e9`; deployed to both Places (drift-clean).
- **v1 store rename** (2026-07-31): store target `PlayerData → Beta1_PlayerData` (dev
  `→ Beta1_PlayerDataDev1`), intentional beta reset. No shape change, version stays **1**. Hash
  `8ac5d3e9 → 184cdfad`.
- **v2** (2026-08-01, blueprint A1): unit INSTANCES (uuid-keyed `Units`, was towerId `Towers`) +
  `Currencies` map (was scalar `Currency`) + `PlayerLevel`/`Loadout`/`Pity`/`Counters`/`Quests`/
  `LoginStreak`/`ShopStock`/`Titles`/`Spirits`/`Battlepass`. `Migrations[1]` converts v1→v2
  (verified on a v1 profile). ProfileTemplate hash `184cdfad → 63a0c98a`. Deployed + verified in
  GAME; **Lobby deploy PENDING (A2)**. Game services (PlayerInventoryService / LoadoutValidator /
  RewardCalculator / DevSeed) refactored to uuids the same session; combat/placement unchanged.
