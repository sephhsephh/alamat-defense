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
  **25 entries = 18 modules + 7 templates. Lobby 25/25 GREEN.** **The Game reads 24/25 and that is
  EXPECTED, not drift:** `MetaMath` is Lobby-only until Phase D needs it. Every other entry is
  byte-identical in both. Templates hash as INSTANCE trees with no `shared/src` file (ADR-0005).
  `UnitStatsCatalogValidate` is Game-only by design — do not "fix" its absence in the Lobby.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **PENDING (USER, BLOCKING):** **republish BOTH Places**, then run the **teleport v2 loop live**
  once. Everything since A7 is Studio canon, not git; a `[CONTRACT]` mismatch blocks every launch.

- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), **BOTH Places in
  ONE session** (invariant 5). Plan + the rejected `Counters.Global` shortcut:
  `docs/proposals/2026-08-09-selection-banner-choices.md`. Selection is one line after.

- **PENDING (AD-UI review, five user-authorised items):** **B7** `SummonController` →
  `BannerRegistry.BlockedReason` · **B8** `RATES / INDEX` button instance on `SummonScreen` · **B9**
  `UnitsController.selectUnit` publishes the selected uuid · **B10** equip/unequip wiring +
  `LoadoutChanged` listener in `HotbarController` · **B11** equip colours + one-per-family client
  guard, `AscensionPanel` removed from `SelectedUnitFrame` (ADR-0010).
  **Quests/login/codes still need a NEW reveal answer** — the return-value trick only serves
  player-INITIATED grants; do not bolt a push remote onto `SummonService`.

- **PENDING (USER, blocks PlayGUI P2/P3):** three authoring fixes only you should make —
  `StoryModeFrame.SelectedAct` has **THREE** children named `StageNameLabel` (delete/rename two);
  rename `RewardsScrollingFrame.ItemIcon` → `ItemIconTemplate` + `Visible=false`; author the slider
  Fill/Handle under `DifficultyGradient` and a player-row template in `LobbyFrame.PlayersFrame`.
  Detail: `docs/blueprints/playgui.md` §2. `HUD.Top.CurrencyBar` is **already compliant** — it
  clones a designed `CurrencyTemplate`; do NOT "convert" it.

- **PENDING (AD-Gacha review, ONE user-authorised item):** Integration fixed trait-on-summon in
  `SummonEngine` (its canon): call is now `TraitRegistry.Roll(rng)` (it assumed a non-existent
  `RollTrait` since B3 and, inside a pcall, failed SILENTLY); a `"None"` roll normalises to **nil**
  so summons match every other grant path; the pcall failure now WARNS once. Verified live.

- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** (user) — same
  structure + GUI in both, entries scoped `Both`/`GameOnly`/`LobbyOnly`, preferences AND actions.
  Plan: `docs/proposals/2026-08-09-unified-settings-both-places.md`. **Nothing is blocked.**

- **PENDING (AD-UI, small):** HUD `CurrencyBar` does not refresh after a summon (join only), so Gold
  reads stale. Wants a `ClientEvents.CurrencyChanged` — copy B10's `LoadoutChanged` shape.

- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then
  the Game's 24/25 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.

- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant flows through `GrantService`")
  holds in the **Lobby only** — the Game still grants via `PlayerInventoryService`/`RewardCalculator`.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places (`MouseEnter`
  cannot be fired from tooling). Also `Kit_ItemHoverCard`'s build-time-clone master/clone split.

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** — `ApplyXP`
  discards overflow at max. Cosmetic, but the Units screen shows it.
- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key); plus
  the `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** still no writer for `Data.Items` in NORMAL PLAY. `GrantService`
  CAN write it (and B9 added `SpendItems`), but no shipping flow grants an item — B7's Event banner
  pays Gold, and B9's ascension costs list no items.

- **NOT a bug:** Units-screen stat NUMBERS are per-TOWER (catalog mid-roll ref), so two instances of
  one tower show equal numbers while their GRADE letters differ (ADR-0003). And `Data.Loadout` fills
  **LEFT TO RIGHT, dense** — a schema-v2 `{ string }` the match launcher reads; fixed slot positions
  would need a schema bump. Difficulty numbers: UI is 1–100, wire is 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v2** — `docs/contracts/teleport.md`. Both sides, both directions. Hard
  cutover, no migration; v1 is rejected with `[CONTRACT]`. `LobbyConfig.MatchLaunchVersion` must
  always equal `GameConfig.TeleportPayloadVersion`. Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION:** changelog `B0…B13` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names. Different sequences, same letters. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — republish both Places, then run the teleport v2 loop live once.
2. **PLAYGUI (new, user priority 2026-08-09)** — `docs/blueprints/playgui.md` is LAW for it.
   7 session-tasks P1–P7 across AD-Lobby / AD-UI / AD-Game. **P1 [AD-Lobby] is the gate:** the Lobby's
   `StageRegistry` mirror has no `StageNumber/StageName/ActNumber/ActName`, so the screen cannot be
   filled. Difficulty is **display-only 1–100** (ADR-0011); the wire format does NOT change.
3. **Phase B** (`phases-b-f-meta.md`). Landed: B0 uuid placement · B1 reveal · B2 Integration ·
   B3 banner engine · B4 reveal anim · B5 AD-UI review · B6 summon UI · B7 EVENT · **B8 INDEX**.
   Blueprint B4 half done — Event ✅, Selection ⛔ (schema PENDING above). B5 ✅ (B8).
4. **Phase C (B9): C3 ascension ✅** (`ascension.md`); **B11 moved it to an NPC screen (ADR-0010) —
   C1/C2/C4 copy that shape.** **C1+C2 (AD-Traits) and C3's sell-dupes half are all UNBLOCKED** by
   B12; sell-dupes needs the unwired `QuickSellButton` + a `GrantService` sell path. **C4** needs
   `FeedValue` + `AddTowerXP` checked first.
