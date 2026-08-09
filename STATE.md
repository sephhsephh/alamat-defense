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
  **teleport v2 loop live** once. Everything since A7 is Studio canon, not git (ADR-0001), and v2
  has only ever been Studio-verified — a `[CONTRACT]` mismatch would block every launch.

- **PENDING (AD-UI / AD-Gacha):** the unit card stays **Lobby-local not shared** (B1) — revisit at
  the unit INDEX (blueprint B5), which is also when `Kit_UnitIcon`'s fate (ADR-0007, PARKED, do NOT
  delete) gets settled. **B6 gave it its first consumer** (SummonScreen featured chips) but did NOT
  settle that. **Quests / login / codes need a NEW reveal answer:** "the remote returns the views"
  only works for player-INITIATED grants. Do not bolt a push remote onto `SummonService` for them.

- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** — user
  decision 2026-08-09. Same structure + same GUI in both, with each entry scoped `Both`/`GameOnly`/
  `LobbyOnly`, and BOTH preferences (persisted) and actions (`Restart Match`, `Return to Lobby`,
  `TP to Spawn`). The Lobby has NO settings system at all today; the Game's `SettingsService` is
  AD-Game canon. Sequencing, the schema question and one reading to confirm with the user:
  `docs/proposals/2026-08-09-unified-settings-both-places.md`. The blueprint's reveal skip-anim
  toggle waits on this — **nothing is blocked**, since B4's click-to-skip already covers the need.

- **PENDING (AD-UI, small):** the HUD `CurrencyBar` does not refresh after a summon (it refreshes
  on join), so Gold reads stale. SummonScreen's own balance IS correct. Wants a
  `ClientEvents.CurrencyChanged`.

- **PENDING (probably AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`.
  Until then the Game reads 22/23 `MetaMath=MISSING` — EXPECTED, do not "reconcile" it.

- **PENDING (AD-Integration, real but not urgent):** invariant 1 ("every grant flows through
  `GrantService`") holds in the **Lobby only** — the Game still grants via AD-Game's
  `PlayerInventoryService` / `RewardCalculator`. Converging spans both Places + AD-Game's canon.

- **PENDING (AD-Traits, small):** promote the trait rarity table to shared → trait-on-summon
  switches itself on here (chance tuned, RNG draw already consumed). Until then, `Trait = nil`.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places —
  `MouseEnter` cannot be fired from tooling, so it is code-inspection-only. One manual hover in
  each Place closes it. Related: `Kit.UnitPreviewTemplate` has no `UnitLevelBar`, so the preview
  shows no level (intentional, skipped gracefully).

- **PENDING (AD-UI, small/cosmetic):** `Kit_ItemHoverCard`'s master/clone split —
  `ItemsGUI.HoverPreview` is a clone taken at build time, so editing the master does NOT update the
  deployed screen (it caused a stale-size bug at A5). Also `StarterGui.Hotbar.SlotTemplate` (Game)
  is dead — keep or delete when next touched.

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** (Archer Lv100
  went `XP 400 → 0`) — `ApplyXP` discards overflow at max. Cosmetic, but the Units screen shows it.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key),
  plus the progressive `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** still no writer for `Data.Items` in NORMAL PLAY (Items screen
  shows zeroes). `GrantService` CAN write it (verified, incl. the `MaxOwned` cap) but no shipping
  flow grants an item. A banner paying tickets would be the first real writer.

- **NOT a bug, do not "fix" it:** the Units screen's stat NUMBERS are per-TOWER (the catalog's
  mid-roll reference), so two instances of one tower show equal numbers while their GRADE letters
  differ. ADR-0003's accepted trade. Details in `docs/systems/lobby-ui.md`.

- **NOT a bug:** `Data.Loadout` fills **LEFT TO RIGHT with no gaps** — it is a schema-v2
  `{ string }` contract field the match launcher reads, so it must stay a dense list. Fixed slot
  positions need a schema bump + migration under AD-Game's contract protocol (deferred).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v2** — `docs/contracts/teleport.md`. Both sides, both directions. Hard
  cutover, no migration; v1 is rejected with `[CONTRACT]`. `LobbyConfig.MatchLaunchVersion` must
  always equal `GameConfig.TeleportPayloadVersion`. Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION, read this before planning:** the changelog's `B0…B6` are Phase-B SESSION
COUNTERS; the blueprint's `B1…B5` are SESSION-TASK names. Different sequences, same letters.

1. **USER** — republish both Places (everything since A7 is Studio canon, not git), then run the
   teleport v2 loop live once.
2. **Phase B** (`docs/blueprints/phases-b-f-meta.md`). Landed: B0 uuid placement · B1 reveal
   surface · B2 Integration · B3 banner engine (`docs/systems/gacha.md`) · B4 reveal animation ·
   B5 AD-UI review + clip fix · **B6 summon UI** (`docs/systems/lobby-ui.md`).
3. **Next is blueprint B4** — Selection choice flow + Event window. Both types are already
   registered and validated, and refused at summon until then. Then **B5** (Index/Codex), which is
   also where the shared-unit-card / `Kit_UnitIcon` question finally gets settled.
