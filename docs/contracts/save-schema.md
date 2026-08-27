# Contract: Save Schema
<!-- owner: game | scope: global | version: 4 | last-verified: 2026-08-27 (B39) -->

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

## v4 shape (current)

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
	EventLoginStreaks: { [string]: { Day: number, LastClaimDayNumber: number } },  -- v4: eventId -> streak
	RedeemedCodes: { [string]: number },   -- v4: UPPERCASED code -> the DAY NUMBER it was redeemed on
	PendingReveals: { Queue: { any }, Dropped: number },  -- v4: reveals owed to an ABSENT player
	BannerChoices: { [string]: {     -- v3: bannerId -> this player's Selection-banner pick
		TowerId: string,
		ChosenAtDay: number,          -- a MetaMath.Slot DAY NUMBER, *not* a timestamp (see below)
	} },
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

**Migration 2→3** (`Migrations[2]`, B29 2026-08-17): adds `BannerChoices` — the Selection banner's
per-player stored pick, which blueprint task B4 needs and B7 shipped the Event half without.

- **The step is a DELIBERATE NO-OP, and must stay one.** `BannerChoices` is an additive-optional
  key and `Reconcile()` runs *before* `Migrate()`, so the key is already an empty table by the time
  the step executes. It exists anyway because **`Migrate()` warns and STOPS at a missing step** — a
  silent gap at v2→v3 would strand every migration added after it. Never delete it, never repurpose
  it for a later change.
- **`ChosenAtDay` is a `MetaMath.Slot(86400, MetaConfig.ResetOffsetSec)` day number, not a
  timestamp.** That is what makes `Featured.ChoiceCooldown` agree across servers with no stored
  clock (cross-phase invariant 3). The cooldown test is `currentDay - ChosenAtDay >= cooldownDays`.
- **This bump is FORWARD-TOLERANT, unlike teleport v4.** `Reconcile()` only fills missing keys and
  never prunes, and `Migrate()`'s loop does not run when `data.SchemaVersion` already exceeds a
  Place's `SCHEMA_VERSION` — so a v2 server reading a v3 profile leaves `BannerChoices` intact
  rather than destroying it. Both Places were still deployed in ONE session (invariant 5), and both
  must still be republished together; the tolerance is a safety net, not a licence to split.
- Verified live (B29, 8 PASS / 0 FAIL from a real server Script): a v1 table walks **2 steps** to
  v3 with `Currencies.Gold` and its migrated unit intact; a v2 table walks **1 step**
  non-destructively; the live dev profile logged `[DATA] Migrated ... forward 1 step(s) to v3` on a
  real DataStore (`DataStoreState=Access`); and a written `BannerChoices` entry **survived a
  stop/start round trip**.

**Migration 3→4** (`Migrations[3]`, B39 2026-08-27): adds `EventLoginStreaks`, `RedeemedCodes` and
`PendingReveals` — the profile fields behind event daily rewards, promo codes and the offline reveal
queue respectively.

- **ONE BUMP FOR THREE SYSTEMS, ON PURPOSE.** Each field is individually free; what a schema bump
  actually costs is the **both-Places publish**. Three bumps would have meant three migration steps
  and three publishes for three changes that could ship together. If a fourth system needs a field
  before v4 ships, **add it to v4** rather than opening v5.
- **The step is a DELIBERATE NO-OP**, for exactly the reason `Migrations[2]` is: all three are
  additive-optional top-level keys and `Reconcile()` runs *before* `Migrate()`, so each is already
  present with its default when the step executes. It exists because `Migrate()` warns and **STOPS**
  at a missing step.
- **`EventLoginStreaks` is a separate TOP-LEVEL key, not nested inside `LoginStreak`.** A top-level
  additive key is unambiguously covered by `Reconcile()`, which is what keeps the migration a no-op.
  `LastClaimDayNumber` is a **`MetaMath.Slot` day number**, never a timestamp (invariant 3).
- **`RedeemedCodes` values are DAY NUMBERS too**, and keys are the **uppercased** code, so casing
  cannot let one code be redeemed twice.
- **`PendingReveals` is PRESENTATION ONLY.** The grant it describes has *already happened* and is
  already reflected in the balances; **draining the queue must never grant anything**. `Dropped`
  counts rows the cap refused so the drain can say "+N more" rather than lying by omission.
- **Forward-tolerant, same as v3.** `Reconcile()` never prunes and `Migrate()`'s loop does not run
  when `data.SchemaVersion` already exceeds a Place's `SCHEMA_VERSION`, so a v3 server reading a v4
  profile leaves the new keys intact. **Both Places must still be republished together** — the
  tolerance is a safety net, not a licence to split.
- Verified on a **fresh clone** of the module, because `execute_luau` caches requires and returns the
  pre-edit copy (it did exactly that on the first attempt, reporting `SCHEMA_VERSION=3` against a
  source that already said 4). Results: all three keys present with correct types,
  `Migrations[1..3]` all present, a reconciled v3 profile walks **1 step** to v4, and a v1 profile
  still walks the **full 3-step** chain with `Currencies.Gold = 500` and its migrated unit intact.

The *flow* on top — the `ChooseBannerUnit` remote, a per-player `BannerRegistry.FeaturedFor`, and
adding `Selection` to `SUPPORTED_TYPES` — is AD-Gacha's work and is NOT part of this bump. Until it
lands, Selection banners stay validated-but-refused (`banner_type_not_supported_yet`).

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

- **v4** (2026-08-27, B39): `EventLoginStreaks` + `RedeemedCodes` + `PendingReveals` in one bump.
  `Migrations[3]` is a deliberate no-op. ProfileTemplate hash `72d3944f → 8e4224b9`, deployed and
  hash-matched in **both** Places the same session (invariant 5). **Both Places must be republished
  together.**

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
