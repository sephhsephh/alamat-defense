# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-06 (A7) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop, as a two-Place
vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons,
progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**,
a shared UI kit, and the gacha banner engine + summon UI.

- **Game** ("Alamat Defense - Game") — the match Place. `MatchEntryService` is the production
  entry; `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` are the Studio harnesses. Owns tower
  configs, combat, the stat resolver, match runtime. Hotbar is on the shared kit.
- **Lobby** ("Alamat Defense - Lobby") — the social/meta Place. Scene `Workspace.Lobby`; flow =
  collection → stage select → party → reserved-server launch, plus MatchReturn, the starter picker
  and gacha (`docs/systems/gacha.md`, `docs/systems/lobby-ui.md`). **`GetUnitViews` is its SINGLE
  profile read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **23 entries = 16 modules + 7 templates. Lobby 23/23 GREEN.** **The Game reads 22/23 and that is
  EXPECTED, not drift:** `MetaMath` is Lobby-only until Phase D needs it. Every other entry is
  byte-identical in both. Templates hash as INSTANCE trees with no `shared/src` file (ADR-0005).
  `UnitStatsCatalogValidate` is Game-only by design — do not "fix" its absence in the Lobby.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **PENDING (USER, BLOCKING, one pass covers both):** **republish BOTH Places**, then run the
  **teleport v2 loop live** once. Everything since A7 is Studio canon, not git (ADR-0001); v2 is
  Studio-verified only, and a `[CONTRACT]` mismatch would block every launch.

- **PENDING (AD-Game or AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the
  save schema** (v2→v3, additive-optional = Reconcile + bump + a no-op `Migrations[2]`), deployed to
  **BOTH Places in one session** — invariant 5 forbids leaving them out of sync, which is exactly
  why B7 shipped Event and stopped at Selection. Full plan + the rejected `Counters.Global`
  shortcut: `docs/proposals/2026-08-09-selection-banner-choices.md`. Then AD-Gacha builds the flow;
  turning it on is one line (`SUPPORTED_TYPES`), and the summon screen needs no change.

- **PENDING (AD-UI / AD-Gacha):** the unit card stays **Lobby-local not shared** (B1) — revisit at
  the unit INDEX (blueprint B5), which also settles `Kit_UnitIcon`'s fate (ADR-0007, PARKED, do NOT
  delete). B6 gave it a consumer but did NOT settle it. **Quests / login / codes need a NEW reveal
  answer:** "the remote returns the views" only serves player-INITIATED grants; do not bolt a push
  remote onto `SummonService`. **B7 also changed `SummonController` (AD-UI canon) — please review:**
  its hardcoded banner-type test now delegates to `BannerRegistry.BlockedReason`.

- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** — user
  decision 2026-08-09. Same structure + GUI in both, entries scoped `Both`/`GameOnly`/`LobbyOnly`,
  covering preferences (persisted) AND actions. The Lobby has none today; the Game's
  `SettingsService` is AD-Game canon. Plan:
  `docs/proposals/2026-08-09-unified-settings-both-places.md`. The reveal skip-anim toggle waits on
  it — **nothing is blocked**, B4's click-to-skip covers the need.

- **PENDING (AD-UI, small):** the HUD `CurrencyBar` does not refresh after a summon (only on join),
  so Gold reads stale. SummonScreen's own balance IS correct. Wants `ClientEvents.CurrencyChanged`.

- **PENDING (probably AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`;
  until then the Game's 22/23 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.

- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant flows through `GrantService`")
  holds in the **Lobby only** — the Game still grants via `PlayerInventoryService` /
  `RewardCalculator`. Converging spans both Places + AD-Game's canon.

- **PENDING (AD-Traits, small):** promote the trait rarity table to shared → trait-on-summon
  switches on here (chance tuned, RNG draw consumed). Until then, `Trait = nil`.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places
  (`MouseEnter` cannot be fired from tooling) — one manual hover each closes it. Also
  `Kit_ItemHoverCard`'s master/clone split: `ItemsGUI.HoverPreview` is a build-time clone, so
  editing the master does NOT update the screen (caused a stale-size bug at A5).

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** (Archer Lv100
  went `XP 400 → 0`) — `ApplyXP` discards overflow at max. Cosmetic, but the Units screen shows it.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key),
  plus the progressive `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** still no writer for `Data.Items` in NORMAL PLAY (Items screen
  shows zeroes). `GrantService` CAN write it (verified incl. `MaxOwned`) but no shipping flow grants
  an item — a banner paying TICKETS would be the first. B7's Event banner pays Gold, so not yet.

- **NOT a bug, do not "fix" it:** the Units screen's stat NUMBERS are per-TOWER (the catalog's
  mid-roll reference), so two instances of one tower show equal numbers while their GRADE letters
  differ. ADR-0003's accepted trade. Details in `docs/systems/lobby-ui.md`.

- **NOT a bug:** `Data.Loadout` fills **LEFT TO RIGHT with no gaps** — a schema-v2 `{ string }`
  contract field the match launcher reads, so it must stay dense. Fixed slots = schema bump.

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v2** — `docs/contracts/teleport.md`. Both sides, both directions. Hard
  cutover, no migration; v1 is rejected with `[CONTRACT]`. `LobbyConfig.MatchLaunchVersion` must
  always equal `GameConfig.TeleportPayloadVersion`. Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION:** the changelog's `B0…B7` are Phase-B SESSION COUNTERS; the blueprint's `B1…B5`
are SESSION-TASK names. Different sequences, same letters.

1. **USER** — republish both Places, then run the teleport v2 loop live once.
2. **Phase B** (`docs/blueprints/phases-b-f-meta.md`). Landed: B0 uuid placement · B1 reveal
   surface · B2 Integration · B3 banner engine (`docs/systems/gacha.md`) · B4 reveal animation ·
   B5 AD-UI review + clip fix · B6 summon UI (`docs/systems/lobby-ui.md`) · **B7 EVENT banners**.
3. **Blueprint B4 is HALF DONE.** Event ✅ (`EventFirstLight`, window-gated, live-verified).
   **Selection ⛔ — blocked on the schema PENDING above, not on effort.**
4. **Next is blueprint B5** (Index/Codex) — unblocked, and where the shared-unit-card /
   `Kit_UnitIcon` question finally gets settled. Selection lands whenever the schema bump does.
