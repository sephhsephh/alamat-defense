# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-01 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the match Place. Healthy, live.
  Persistence on **Beta1_PlayerData** (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `MatchEntryService` is the production entry (reads `TeleportData.MatchLaunch`, waits for
  profiles, then `StartMatch`); `MatchLifecycleSmokeTest` is the Studio fallback and stands down
  when a payload is present. `ReturnToLobby` sends `MatchReturn`. Cross-place ids set both ways
  (`LobbyPlaceId` 83342803778137). Owns tower configs, combat, the stat resolver, match runtime.
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place, live.
  Scene `Workspace.Lobby`; flow = collection → stage select + difficulty → party →
  reserved-server launch, plus `MatchReturn` welcome-back banner + next-act pre-select and the
  first-join starter picker. Serves `GetCollection` (legacy + interim compat) and
  **`GetUnitViews`** (the A4/A5 per-uuid contract: tier, level, grades, equipped, favorited).
  `PartyService.buildLoadout` sends unit uuids.
- **Shared canon** (`shared/src` + `manifest.json`, drift-checked by `tools/hash_shared.luau`):
  8 modules — `ProfileTemplate`, `PlayerDataService`, `ProfileStore`, `Signal`, and since
  2026-08-01 `TierConfig`, `StatGradeConfig`, `AscensionConfig`, `ItemCatalog`.
  **Drift GREEN in both Places** as of 2026-08-01.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only).

- **PENDING (USER, BLOCKING):** republish **BOTH** Places — the entire A-phase promotion
  (4 shared Meta configs, the reconciled multi-colour `TierConfig`, `GetUnitViews`) is Studio
  canon and not in git. Live currently runs the pre-promotion build.

- **PENDING (AD-Game, review):** the 2026-08-01 empty-hotbar hotfix touched AD-Game canon
  (`MatchEntryService`, `PlayerInventoryService`) from the AD-Integration chat — user-directed,
  live-blocking; fix confirmed working live. Review it and decide whether the profile wait
  belongs in `MatchDirector.StartMatch` (protecting every caller) rather than only the entry
  path. **Structural lesson:** every Studio verification runs through `MatchLifecycleSmokeTest`,
  which pre-seeds units synchronously, so the production cold-profile path is never exercised
  before a live run — two live-only failures have come from that blind spot. Add a Studio
  harness that starts a match WITHOUT dev-seeding, ideally before A6.

- ~~PENDING (AD-Game — grade/roll system INERT).~~ **DONE 2026-08-03 (AD-Game grant paths)** —
  `PlayerInventoryService.GrantUnit` (explicit `opts.StatRolls` wins) and `DevSetOwnedTowers` now
  call `StatGradeConfig.RollAll(rng)` off one persistent `Random`. Verified live: rolls differ per
  unit, land in 0..1, spread of grades, override wins, two same-tower instances resolve to different
  DMG/RNG/SPA. Existing units + the v1→v2 migration stay grandfathered at 0.5 (append-only).
- ~~PENDING (AD-Lobby — starter grant still writes 0.5).~~ **DONE 2026-08-03** —
  `StarterChoiceService` rolls via shared `StatGradeConfig.RollAll` off one module-level
  `Random`, shape re-checked against `GrantUnit`. Verified live: varied rolls run-to-run
  (D/C/B spread). ALL grant paths now roll; only pre-existing units stay grandfathered at 0.5.

- **PENDING (NEEDS SCHEDULING — equipping does not exist):** nothing ever WRITES `Data.Loadout`.
  The template inits it `{}`, the migration sets `{}`, the Lobby only reads it. So `Equipped` is
  always false and launches always fall through to auto-loadout (top 6 by MetaLevel). The
  unitView carries the flag, but a loadout picker (the writer) is not scheduled anywhere.

- **PENDING (AD-Game + AD-Integration — deferred NUMBERS decision, due at A6):** the Lobby serves
  grades but NOT resolved DMG/RNG/SPA. `TowerStatResolver.Resolve` needs a whole towerConfig plus
  MetaScalingConfig/TraitRegistry/TraitDefinitions, so Lobby-side numbers mean ~12 modules (incl.
  all 8 tower configs) under drift control. Deferred by the user 2026-08-01. When A6 needs real
  numbers pick: (a) promote the full stat stack, or (b) AD-Game exports a slim generated
  `UnitStatsCatalog` + a boot validator asserting it matches live configs. **(b) recommended.**

- **PENDING (A5, cleanup):** remove the interim `Towers`/`Currency` compat fields on
  `LobbyServices.GetCollection` (AD-Lobby canon) once **CollectionScreen** is rebuilt on the
  view-model. ~~UnitCatalog deletion~~ **DONE (A4, 2026-08-03)** — the Units screen reads
  `GetUnitViews`; `UnitCatalog` deleted (no readers). CollectionScreen is now the only
  `Towers`/`Currency` reader left.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** persistence round-trip test (never run; profile shape has changed since it
  was raised) and progressive `ServerStorage.Documentation` → `docs/systems/` migration.

## Contracts (current versions)

- Save schema: **v2** (`shared/src/ProfileTemplate.luau`, hash `63a0c98a`) — store
  "Beta1_PlayerData"/"Beta1_PlayerDataDev1". v2 (A1, 2026-08-01) = uuid unit `Units` +
  `Currencies` map + meta fields; `Migrations[1]` converts v1→v2. **Deployed + drift-green in
  BOTH Places** (Game A1, Lobby A2 — both `63a0c98a`).
- Teleport payload: **v2** (`docs/contracts/teleport.md`) — implemented BOTH sides + BOTH
  directions: Lobby sends `MatchLaunch` and consumes `MatchReturn` (banner + next-act pre-select);
  Game receives `MatchLaunch` and returns `MatchReturn`. v2 (A2, 2026-08-01) = `Loadout` carries
  unit uuids; **hard cutover, no migration** — v1 is rejected with `[CONTRACT]`. Version lives in
  `LobbyConfig.MatchLaunchVersion` == `GameConfig.TeleportPayloadVersion` (must always be equal).
  Verified in Studio both sides; both Places **published 2026-08-01** — live re-verification of
  the v2 loop is the open user action (v1 was live-verified end-to-end 2026-07-18).

## Current focus

1. **USER: republish both Places** (A-phase promotion is Studio canon). Live is fine on the
   previous build — the hotfix run was confirmed working — so this is not urgent, but nothing
   from this session reaches players until it happens.
2. ~~**A4 [AD-UI]**~~ **DONE 2026-08-03** — `UnitsController` reads `GetUnitViews` (uuid cards,
   shared multi-colour `TierConfig` borders, D..Apex grade letters, real Equipped/Favorited sort,
   real Level/XP); `UnitCatalog` deleted; live-verified (varied grades). Absolute stat NUMBERS
   still absent by design (A6). `HotbarController` view-model wire deferred to the A6 hotbar rebuild.
3. **A5 [AD-UI]:** Items screen on the kit + FilterPanel; rebuild CollectionScreen on the
   view-model so `GetCollection`'s `Towers`/`Currency` compat can be removed (AD-Lobby).
4. **A6 [AD-UI/AD-Game]:** hotbar rebuild in the Game place — settle the numbers decision first,
   and land the no-dev-seed Studio harness before this.
5. Then A7 (full Phase A acceptance, Integration) → Phase B gacha.
6. Unscheduled but wanted: loadout picker (equipping), stat-roll wiring, real art/anim asset ids.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

