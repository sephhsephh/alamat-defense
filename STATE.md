# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-14 (B21) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop, as a two-Place
vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons,
progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**,
a shared UI kit, and the gacha banner engine + summon UI.

- **Game** ("Alamat Defense - Game") — the match Place; `MatchEntryService` is the production entry.
  Owns tower configs, combat, the stat resolver, match runtime. Detail: `places/game/CONTEXT.md`.
- **Lobby** ("Alamat Defense - Lobby") — the social/meta Place, scene `Workspace.Lobby`.
  **`GetUnitViews` is its SINGLE profile read path** (ADR-0004); **`GrantService` is its SINGLE
  grant/spend path**. Detail: `places/lobby/CONTEXT.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`): **26 entries
  = 19 modules + 7 templates. The LOBBY is 26/26 GREEN since B20; the GAME reads 25/26 and that ONE
  gap is EXPECTED, not drift** — `MetaMath` stays Lobby-only until Phase D. Templates hash as
  INSTANCE trees, no `shared/src` file (ADR-0005). `UnitStatsCatalogValidate` is Game-only by
  design — do not "fix" its absence.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **PENDING (USER, BLOCKING + NOW URGENT):** **republish BOTH Places TOGETHER**, then run the
  **teleport v3 loop live** once. B20 bumped the contract to **v3** and **v2/v3 do not interoperate**
  — a PARTIAL publish breaks EVERY launch with `[CONTRACT] PayloadVersion mismatch`.
- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), **BOTH Places in
  ONE session** (invariant 5). Plan + the rejected `Counters.Global` shortcut:
  `docs/proposals/2026-08-09-selection-banner-choices.md`. Selection is one line after.
- **PENDING (AD-UI review, five user-authorised items):** **B7** `SummonController` →
  `BannerRegistry.BlockedReason` · **B8** `RATES / INDEX` button on `SummonScreen` · **B9**
  `UnitsController.selectUnit` publishes the selected uuid · **B10** equip/unequip wiring +
  `LoadoutChanged` listener in `HotbarController` · **B11** equip colours + one-per-family client
  guard, `AscensionPanel` out of `SelectedUnitFrame` (ADR-0010). **Quests/login/codes still need a
  NEW reveal answer** — the return-value trick only serves player-INITIATED grants.
- **PENDING (USER, balance):** `StartingLives` is **3 / 15 / 10** across Acts 1–3 while
  `BaseHealthScale` climbs 1.0/1.6/2.4. Act 1's `3` looks like a leftover test value. P5 fixed only
  Act 2's false comment; changing numbers is a design call.
- **PENDING (AD-Gacha review, ONE user-authorised item):** Integration fixed trait-on-summon in
  `SummonEngine`: the call is now `TraitRegistry.Roll(rng)` (it assumed a non-existent `RollTrait`
  since B3 and, inside a pcall, failed SILENTLY); `"None"` → **nil**; failures WARN. Verified live.
- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** (user) — same
  structure + GUI in both, entries scoped `Both`/`GameOnly`/`LobbyOnly`, preferences AND actions.
  Plan: `docs/proposals/2026-08-09-unified-settings-both-places.md`. Nothing is blocked.
- **PENDING (AD-Game, small): `RewardScalingConfig`'s HEADER COMMENT is stale** (says Insane cannot
  fire). Fixing it changes the hash `1d789978` → comment-only re-hash + redeploy to BOTH Places.
- **PENDING (AD-UI, small):** HUD `CurrencyBar` does not refresh after a summon (join only), so Gold
  reads stale. Wants a `ClientEvents.CurrencyChanged` — copy B10's `LoadoutChanged` shape.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then
  the Game's 25/26 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.
- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant flows through `GrantService`")
  holds in the **Lobby only** — the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places (`MouseEnter`
  cannot be fired from tooling). Also `Kit_ItemHoverCard`'s build-time-clone master/clone split.
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** — `ApplyXP`
  discards overflow at max. Cosmetic, but the Units screen shows it.
- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key); plus
  the `ServerStorage.Documentation` → `docs/systems/` migration.
- **PENDING (NEEDS SCHEDULING):** `Data.Items` finally HAS a shipping writer — an **INSANE Victory**
  (v3, B20) pays `BannerTicket` + `TraitRerollToken`. Nothing else does (B7 pays Gold, B9 costs no
  items), so counts stay 0 until someone clears an Insane run.
- **NOT a bug:** Units-screen stat NUMBERS are per-TOWER (catalog mid-roll ref), so two instances of
  one tower show equal numbers while GRADE letters differ (ADR-0003). `Data.Loadout` fills **LEFT TO
  RIGHT, dense** (schema-v2 `{ string }`; fixed slots need a bump). Difficulty: UI 1–100, wire
  100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v3** (B20, 2026-08-14) — `docs/contracts/teleport.md`. Both sides + both
  directions, deployed in ONE session. v3 adds `DifficultyMode` ("Normal"/"Insane"), which is what
  makes P5's Insane rewards reachable. Hard cutover, no migration; **v2 is REJECTED**.
  `LobbyConfig.MatchLaunchVersion` must ALWAYS equal `GameConfig.TeleportPayloadVersion`.
  Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION:** changelog `B0…B13` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names. Different sequences, same letters. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — republish both Places TOGETHER (v3 is a hard cutover), then run the loop live once.
2. **PLAYGUI (user priority 2026-08-09)** — `docs/blueprints/playgui.md` is LAW. **P1–P6 ✅ DONE**
   (B14–B19); detail in the blueprint's §9 and `docs/systems/play-menu.md`. The ADR-0011 remap is
   isolated in `PlayGUI.DifficultyScale` — **the ONE conversion; never write a second.**
   **B20 did the Integration half** (curve copied here; teleport v3 = Insane is live-reachable) and
   **B21 closed both AD-UI items**: `OpenStageSelect` has a shipping-path listener again (CONTINUE
   works) and the reward preview reads `RewardScalingConfig.GoldBand` and TRACKS the slider.
   **NEXT = P7** [AD-Meta] — the global queue, §11 — or the five-item AD-UI review backlog.
3. **Phase B** (`phases-b-f-meta.md`). Landed B0–B8; Selection ⛔ on the `BannerChoices` schema
   PENDING above. **Phase C (B9): C3 ascension ✅**; **B11 moved it to an NPC screen (ADR-0010) —
   C1/C2/C4 copy that shape.** C1+C2 (AD-Traits) and C3's sell-dupes half are UNBLOCKED by B12;
   sell-dupes needs the unwired `QuickSellButton` + a `GrantService` sell path. Row-by-row status
   lives in `docs/ROADMAP.md` — do not duplicate it here.
