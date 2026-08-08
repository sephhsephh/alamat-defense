# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-06 (A7) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
two-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/
summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit
instances)**, and a shared UI kit both Places draw from.

- **Game** (Studio: "Alamat Defense - Game") — the match Place. `MatchEntryService` is the
  production entry; `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` are the Studio harnesses.
  Owns tower configs, combat, the stat resolver, match runtime. Hotbar is on the shared kit.
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place. Scene `Workspace.Lobby`;
  flow = collection → stage select + difficulty → party → reserved-server launch, plus MatchReturn,
  the starter picker and (B3) the **gacha banner engine**, `docs/systems/gacha.md`. **`GetUnitViews`
  is its SINGLE profile read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **23 entries = 16 modules + 7 templates**. **Lobby 23/23 GREEN (B3, 2026-08-09).**
  **The Game reads 22/23 and that is EXPECTED, not drift:** `MetaMath` (added B3) is deployed to
  the Lobby only and reports MISSING there until Phase D needs it. Every OTHER entry is
  byte-identical in both Places. Templates are hashed as INSTANCE trees and have no `shared/src`
  file (ADR-0005). Kit detail: `docs/systems/ui-kit.md`. `UnitStatsCatalogValidate` is Game-only
  canon by design — do not "fix" its absence in the Lobby.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **PENDING (USER, BLOCKING, one pass covers both):** **republish BOTH Places**, then run the
  **teleport v2 loop live** once (lobby → reserved match → return → banner). A7/A8/B0/B1/B2/B3 are
  all Studio canon and not in git (ADR-0001). v2 has only ever been Studio-verified; only v1 was
  ever live-verified (2026-07-18), and a `[CONTRACT]` mismatch would block every launch.

- **PENDING (AD-UI / AD-Gacha):** the reveal surface now has its first caller (gacha, B3); the
  remaining thread is the unit card, **Lobby-local not shared** (B1) — revisit when the unit INDEX
  (blueprint B5) is its second consumer, which is also when `Kit_UnitIcon`'s fate (ADR-0007, still
  PARKED, do not delete) gets settled. **Quests / login / codes need a NEW reveal answer:** B3's
  "the remote returns the views" only works for player-INITIATED grants. Do not bolt a push
  remote onto `SummonService` for them.

- **PENDING (whoever needs it FIRST, probably AD-Meta at Phase D):** deploy `MetaMath` to the GAME
  place and flip `deployed.Game` in `shared/manifest.json`. Until then the Game's drift reads
  22/23 with `MetaMath=MISSING`, which is the EXPECTED state — do not "reconcile" it.

- **PENDING (AD-Integration, real but not urgent):** invariant 1 ("every grant flows through
  `GrantService`") holds in the **Lobby only** — the Game still grants via AD-Game's
  `PlayerInventoryService` / `RewardCalculator`. Converging spans both Places + AD-Game's canon.

- **PENDING (AD-Traits, small):** promote the trait rarity table to shared → trait-on-summon
  switches itself on here (chance tuned, RNG draw already consumed). Until then, `Trait = nil`.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places.
  `MouseEnter` cannot be fired from tooling and `VirtualInputManager` is blocked, so "the card
  appears on a real hover" is code-inspection-only. One manual hover in each Place closes it.
  Related: `Kit.UnitPreviewTemplate` has no `UnitLevelBar`, so the hotbar preview shows
  name/tier/stats but not level (intentional, skipped gracefully).

- **PENDING (AD-UI, small/cosmetic):** `Kit_ItemHoverCard`'s master/clone split —
  `ItemsGUI.HoverPreview` is a clone taken once at build time, so editing the master does NOT
  update the deployed screen. Decide whether this needs a real fix (it caused a stale-size bug at
  A5). Also `StarterGui.Hotbar.SlotTemplate` (Game) is dead — keep or delete when next touched.

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** — Archer Lv100
  went `XP 400 → 0` on earning defeat XP, because `ApplyXP` discards overflow at max rather than
  preserving the stored value. Cosmetic, but the Units screen shows that number.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** real-DataStore round-trip test for the PLAYER profile (A7 used a scratch key
  only), plus the progressive `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** still no writer for `Data.Items` in NORMAL PLAY (Items screen
  shows all zeroes). **B3 moved it halfway:** `GrantService` is the first code that CAN write the
  field, verified live including the `MaxOwned` cap — but no SHIPPING flow grants an item. A banner
  paying tickets, or the latent `RewardCalculator` Victory drop, would be the first real writer.

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

**✅ PHASE A IS SIGNED OFF (A9, 2026-08-06).** A1–A9 all landed; every §8 item PASSES, re-verified
live in both Places. The blueprint `docs/blueprints/phase-a-foundations.md` is now history.

1. **USER** — republish both Places (A7's `GetCollection` deletion + A8's and B0's Game service
   changes are Studio canon, not git), then run the teleport v2 loop live once.
2. **Phase B (gacha)** — `docs/blueprints/phases-b-f-meta.md`. Landed so far: **B0** uuid-addressed
   placement (duplicates work), **B1** the reveal surface, **B2** Integration (kit mirrored,
   RewardPopup retired), and **B3 (2026-08-09) the BANNER ENGINE** — the blueprint's B1
   (MetaMath + GrantService + PityConfig) and B2 (banner registry + summon service + 10k odds
   harness) session-tasks together, by user decision. Doc: `docs/systems/gacha.md`.
   **NOTE the label collision:** the changelog's B0/B1/B2/B3 are Phase-B SESSION COUNTERS; the
   blueprint's B1–B5 are SESSION-TASK names. They are different sequences. In blueprint terms the
   next task is **B3: summon UI + reveal wiring** (NPC, banner carousel, x1/x10, skip toggle) —
   the engine under it is done and driven by `RS.Remotes.RequestSummon`.
3. Then blueprint **B4** (Selection choice flow + Event window; both banner types are already
   registered and validated, and refused at summon until then) and **B5** (Index/Codex, which is
   also when the shared-unit-card / `Kit_UnitIcon` question gets settled).
