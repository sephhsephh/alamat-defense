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
  **teleport v2 loop live** once. Everything since A7 is Studio canon, not git; a `[CONTRACT]`
  mismatch would block every launch.

- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), deployed to **BOTH
  Places in ONE session** — invariant 5. Plan + the rejected `Counters.Global` shortcut:
  `docs/proposals/2026-08-09-selection-banner-choices.md`. Turning Selection on afterwards is one
  line (`SUPPORTED_TYPES`); the summon screen needs no change.

- **PENDING (AD-UI review, three user-authorised items):** **B7** `SummonController` delegates its
  banner-type test to `BannerRegistry.BlockedReason` · **B8** a `RATES / INDEX` button INSTANCE on
  `SummonScreen` (no code changed) · **B9** ONE line in `UnitsController.selectUnit` publishing
  `selectedFrame:SetAttribute("Uuid"/"TowerId")` — Phase C's stat-reroll and feeding panes need it.
  **Quests / login / codes still need a NEW reveal answer:** the return-value trick only serves
  player-INITIATED grants; do not bolt a push remote onto `SummonService`.

- **PENDING (AD-UI + both Places): `SellValueByTier` in `TierConfig`** — blocks C3's SELL-DUPES half.
  Shared canon, so it spans both Places. `UnitsGUI.QuickSellButton` exists, unwired, waiting.

- **PENDING (AD-Traits, BLOCKS blueprint C1+C2):** the trait rarity table is AD-Traits canon in the
  GAME place and **does not exist in the Lobby at all** — trait reroll cannot be built here and
  trait-on-summon stays inert. Promoting it is an Integration task. `SummonEngine` ASSUMES the API
  is `TraitTable.RollTrait(rng)` — unverified since B3; check when promoting. C1/C2 are AD-Traits' ROW.

- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** (user,
  2026-08-09) — same structure + GUI in both, entries scoped `Both`/`GameOnly`/`LobbyOnly`, covering
  preferences AND actions. The Lobby has none; the Game's `SettingsService` is AD-Game canon. Plan:
  `docs/proposals/2026-08-09-unified-settings-both-places.md`. **Nothing is blocked** — B4's
  click-to-skip covers the reveal toggle.

- **PENDING (AD-UI, small):** the HUD `CurrencyBar` does not refresh after a summon (only on join),
  so Gold reads stale. SummonScreen's own balance IS correct. Wants `ClientEvents.CurrencyChanged`.

- **PENDING (probably AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`;
  until then the Game's 22/23 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.

- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant flows through `GrantService`")
  holds in the **Lobby only** — the Game still grants via `PlayerInventoryService` /
  `RewardCalculator`. Converging spans both Places.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places (`MouseEnter`
  cannot be fired from tooling). Also `Kit_ItemHoverCard`'s build-time-clone master/clone split.

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** (Archer Lv100 went
  `XP 400 → 0`) — `ApplyXP` discards overflow at max. Cosmetic, but the Units screen shows it.
- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key), plus
  the `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** still no writer for `Data.Items` in NORMAL PLAY. `GrantService`
  CAN write it (and B9 added `SpendItems`), but no shipping flow grants an item — B7's Event banner
  pays Gold, and B9's ascension costs list no items.

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

**LABEL COLLISION:** the changelog's `B0…B8` are Phase-B SESSION COUNTERS; the blueprint's `B1…B5`
are SESSION-TASK names. Different sequences, same letters.

1. **USER** — republish both Places, then run the teleport v2 loop live once.
2. **Phase B** (`docs/blueprints/phases-b-f-meta.md`). Landed: B0 uuid placement · B1 reveal
   surface · B2 Integration · B3 banner engine · B4 reveal animation · B5 AD-UI review + clip fix ·
   B6 summon UI · B7 EVENT banners · **B8 unit INDEX**. Docs: `gacha.md`, `lobby-ui.md`.
3. **Blueprint B4 HALF DONE** — Event ✅, Selection ⛔ (schema PENDING above). **B5 ✅ (B8)**, which
   also settled `Kit_UnitIcon` — ADOPTED, ADR-0009.
4. **Phase C started (B9): blueprint C3 ascension ✅** (`docs/systems/ascension.md`); its sell-dupes
   half is blocked on `SellValueByTier`. **C1 + C2 are AD-TRAITS' row AND blocked** (no trait table
   in this Place). **C4 feeding** is the next AD-Gacha-adjacent option — check `FeedValue` in
   `ItemCatalog` and the `AddTowerXP` path exist here before committing to it.
