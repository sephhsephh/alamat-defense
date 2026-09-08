# Contract: Save Schema
<!-- owner: game | scope: global | version: 5 | last-verified: 2026-09-02 (B48) -->

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

## v6 shape (current)

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
	Inbox: { Messages: { {Id,Title,Body,Rewards?,Day,Read} } }, -- v5: CAPPED received-message history
	LuckBuff: { Percent: number, ExpiresAtUtc: number },        -- v6: ONE timed Luck buff; 0/0 = none
	AutoSell: { [tierName]: true },                             -- v6: Auto Summon toggles; SPARSE, absent = off
	Purchases: { Ids: { string } },                             -- v6: CAPPED granted-receipt ledger (no double-grant)
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

**Migration 4→5** (`Migrations[4]`, B48 2026-09-02): adds `Inbox` — the stored message history
for the Inbox screen.

- **The FIRST genuinely necessary bump since v4.** Unlike `LoginStreak`/`Quests`/`ShopStock`/
  `Battlepass` (all on the schema since v2, unwritten), there was NO inbox/mail/history field — a
  listable history must be persisted, so it could not ride an existing key.
- **The step is a DELIBERATE NO-OP**, same reason as `[2]`/`[3]`: `Inbox` is an additive-optional
  top-level key and `Reconcile()` runs *before* `Migrate()`, so it is already `{ Messages = {} }` when
  the step runs. It exists because `Migrate()` warns and **STOPS** at a missing step.
- `Data.Inbox = { Messages = { {Id, Title, Body, Rewards?, Day, Read} } }`, **CAPPED** (newest 30;
  oldest dropped) so the profile cannot grow without bound. `Day` is a `MetaMath.Slot` day number
  (invariant 3). `InboxService` is THE one writer; mail records into it in the same save as its grant.
- **Forward-tolerant, same as v3/v4.** A v4 server reading a v5 profile leaves `Inbox` intact. **Both
  Places must still be republished together** — the tolerance is a safety net, not a licence to split.
- ProfileTemplate hash `8e4224b9 → 91ffab78`, deployed byte-identical to BOTH Places in one session,
  manifest updated, **36/36 verified in both**. Verified live: the dev profile migrated **1 step** v4→v5
  on a real DataStore, and `Data.Inbox` survived a stop/start round trip.

The *flow* on top — the `ChooseBannerUnit` remote, a per-player `BannerRegistry.FeaturedFor`, and
adding `Selection` to `SUPPORTED_TYPES` — is AD-Gacha's work and is NOT part of this bump. Until it
lands, Selection banners stay validated-but-refused (`banner_type_not_supported_yet`).

**Migration 5→6** (`Migrations[5]`, B55 2026-09-08): adds `LuckBuff`, `AutoSell` and `Purchases` —
the timed Luck buff a gem pack grants, the Auto Summon panel's per-tier auto-sell toggles, and the
Developer Product receipt ledger.

- **Three systems, ONE bump, on purpose** — the v3→v4 precedent. The cost of a bump is the
  both-Places PUBLISH, not the field. `Purchases` was in fact added to v6 *after* `LuckBuff` and
  `AutoSell`, in the same session, by following exactly that rule. If a fourth system needs a field
  before v6 ships, add it to **v6**.
- **The step is a DELIBERATE NO-OP**, same reason as `[2]`/`[3]`/`[4]`: both are additive-optional
  top-level keys and `Reconcile()` runs *before* `Migrate()`, so both already hold their template
  defaults when the step runs. It exists because `Migrate()` warns and **STOPS** at a missing step.
- `Data.LuckBuff = { Percent, ExpiresAtUtc }`. `Percent` is a WHOLE number (25 = +25%);
  `ExpiresAtUtc` is an absolute `os.time()` second. **Expiry is a COMPARISON, never a scheduled
  write** — an expired buff and no buff are the SAME state, so a buff cannot outlive its window just
  because no server was up to clear it, and the migration needs no pass over existing data. ONE buff
  at a time: buying while one is live keeps the **higher** percent and refreshes the timer (user).
- `Data.AutoSell = { [tierName] = true }`, **SPARSE** — never write `false`. Absent means off, so a
  tier added to the game later defaults to KEPT, which is the safe direction.
- `Data.Purchases = { Ids = { purchaseId } }`, **CAPPED** (newest 50). **This is what stops a player
  being charged twice.** Roblox re-delivers a Developer Product receipt until `ProcessReceipt`
  returns `PurchaseGranted`, and may re-deliver one it already accepted — so the ledger must live in
  the PROFILE, not in server memory, because the retry usually arrives on a *different server*.
  `ReceiptService` is THE one writer; it records the id in the SAME profile as the grant.
- **Forward-tolerant, same as v3/v4/v5.** A v5 server reading a v6 profile leaves both keys intact.
  **Both Places must still be republished together** — the tolerance is a safety net, not a licence
  to split.
- ProfileTemplate hash `91ffab78 → 83633e44`, deployed byte-identical to BOTH Places in one session,
  manifest updated, **41/41 verified in both**.

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

- **v6** (2026-09-08, B55): `LuckBuff` + `AutoSell` + `Purchases` in one bump — the timed gem-pack
  Luck buff, the Auto Summon auto-sell toggles, and the Developer Product receipt ledger.
  `Migrations[5]` is a deliberate no-op; expiry is a comparison, so no data pass was needed.
  ProfileTemplate hash `91ffab78 → 83633e44`, deployed + hash-matched in
  **both** Places the same session (41/41). Forward-tolerant, but **both Places must be republished
  together.**
- **v5** (2026-09-02, B48): `Inbox` — a CAPPED received-message history for the Inbox screen. The
  first bump since v4 that truly needed a new field. `Migrations[4]` is a deliberate no-op. ProfileTemplate
  hash `8e4224b9 → 91ffab78`, deployed + hash-matched in **both** Places the same session (36/36). Forward-
  tolerant, but **both Places must be republished together.**
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
