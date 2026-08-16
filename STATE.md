# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-16 (B27) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop as a two-Place vertical
slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons, progression +
match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**, a shared UI kit,
and the gacha banner engine + summon UI.

- **Game** — the match Place; `MatchEntryService` is the production entry. Owns tower configs,
  combat, the stat resolver, match runtime. Detail: `places/game/CONTEXT.md`.
- **Lobby** — the social/meta Place, scene `Workspace.Lobby`. **`GetUnitViews` is its SINGLE profile
  read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**. `places/lobby/CONTEXT.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`): **27 entries
  = 20 modules + 7 templates** (`UIKitMotion` added B27c). All 26 PRESENT in the Lobby; the GAME reads 25/26 and that ONE gap is
  EXPECTED, not drift — `MetaMath` stays Lobby-only until Phase D. **B26 adopted the V2 UI kit in BOTH
  Places and RETIRED `Kit_UnitIcon`/`Kit_ItemIcon`/`Kit_HotbarSlot`** (dropped from
  `hash_shared.luau` — do not re-add). Templates hash as INSTANCE trees, no `shared/src` file
  (ADR-0005).

**DRIFT RULE (everyone):** editing a shared controller **or a template** in one Place only is DRIFT.
Change → re-hash → copy to the other Place → update the manifest. **Copying a TEMPLATE across Places
is a USER action** (B26) — pause and ask. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **NOT A PENDING — STANDING USER PRACTICE (B25): the user republishes BOTH Places EVERY session.**
  Never open a "republish" PENDING again; only *state* it when a session bumps a contract (both go
  out together). Still unconfirmed: a **live two-client v4 queue run** (`ReserveServer` 403 in Studio).
- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), **BOTH Places, ONE
  session** (invariant 5). Plan: `docs/proposals/2026-08-09-selection-banner-choices.md`.
- **PENDING (AD-UI, design): quests/login/codes need a NEW reveal answer** — the return-value trick
  only serves player-INITIATED grants; there is no server→client push remote. Propose before building.
- **PENDING (AD-Game, B24): `UnitIconV2` needs PLACEMENT COST + ELEMENT**, neither of which exists
  in the Lobby (`UnitStatsCatalog` is `{DMG,RNG,SPA}`; tower configs are Game-only) — rendered HIDDEN
  until then. **(AD-Traits, B24): `TraitDefinitions` has NO icon field**, so `UnitIconV2.TraitIcon`
  cannot render; additive+optional but shared canon → drift procedure. Plans:
  `docs/proposals/2026-08-16-{tower-display-fields-for-uniticon-v2,trait-icons}.md`.
- **PENDING (USER, design call — B23's v4 survey): GAME SPEED IN A MATCHMADE MATCH.** Speed is
  match-wide; both the authority and the 3× gamepass gate come from the host, who matchmade is an
  **elected stranger** (lowest userId). B23 changed nothing, logs `[CONTRACT] MATCHMADE match:
  speed authority ...`. Options: leave as-is · disable 3× matchmade · per-player. Your call.
- **PENDING (USER, balance):** `StartingLives` is **3 / 15 / 10** across Acts 1–3 while
  `BaseHealthScale` climbs 1.0/1.6/2.4 — Act 1's `3` looks like a leftover test value. P5 fixed only
  Act 2's false comment; the numbers are a design call.
- **PENDING (AD-Gacha review, ONE user-authorised item):** Integration fixed trait-on-summon in
  `SummonEngine` — `TraitRegistry.Roll(rng)` (there is no `RollTrait`), `"None"`→nil, failures WARN.
- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** (user) — same
  structure + GUI, entries scoped `Both`/`GameOnly`/`LobbyOnly`; nothing is blocked. Plan:
  `docs/proposals/2026-08-09-unified-settings-both-places.md`.
- **PENDING (AD-Game, small): `RewardScalingConfig`'s HEADER COMMENT is stale** (says Insane cannot
  fire); fixing it re-hashes `1d789978` (comment-only) + redeploy to BOTH Places.
- **PENDING (AD-UI, small):** HUD `CurrencyBar` refreshes on join only, so Gold reads stale after a
  summon. Wants `ClientEvents.CurrencyChanged`, shaped like B10's `LoadoutChanged`.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then
  the Game's 25/26 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.
- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant via `GrantService`") holds in
  the **Lobby only**; the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, B27 — user deferred): `UnitIconV2` has FOUR inline consumers** (Summon, Index,
  Ascension, Units) repeating paint/viewport code — motion is now shared, the rest is not. **Units
  should SHAPE the controller**: it alone needs equip/favourite/lock.
- **PENDING (AD-UI, small):** the **hover TRIGGER** is unverified in BOTH Places — `MouseEnter` cannot
  be fired from tooling. B26 proved `paintStroke()` (the fn both handlers call) toggles
  `UIHoverStroke`; only the engine-side trigger is unproven. Also `Kit_ItemHoverCard`'s clone split.
- **PENDING (USER-REQUESTED, B27 QUEUE): 6 of 7 DONE, ONE REMAINS.**
  ✅ done (5/7): two-colour minimum per tier (`TierConfig` 7d5850c1, derived dark secondary, hue kept);
  hover strokes tinted from `TierConfig.BrightestColor` (relative luminance, NOT HSV value); the
  **whole button** scales, UIScale moved to the ROOT (centre-anchoring verified layout-safe by
  measurement); Units screen migrated onto `UnitIconV2` + the shared `Kit.UnitPreviewTemplate`.
  B27c added **`UIKit.Motion`** (27th manifest entry) — the kit's one motion home: `isolate()`'s
  fixed-size wrapper (a UIScale on a layout child re-flows the row; measured 30px of shove), the
  Quint curve, the 45° 9s idle sheen, and `lift()`. ⬜ REMAINING: **(e)** `HUD.Left` buttons
  **mutually exclusive** + **slide** open/close — build it on `Motion`, do not start a fourth
  animation dialect.
- **KNOWN REGRESSION (B26, accepted):** V2 has no `ShinyBadge` (`AscensionController` drove it from
  `view.Shiny`) — **shiny is not marked on an ascension card.** Re-add to the template, or drop it.
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses stored XP** (`ApplyXP` discards
  overflow) — cosmetic, but the Units screen shows it. **(AD-PlayerLevel, small):** promote
  `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key); plus
  the `ServerStorage.Documentation` → `docs/systems/` migration.
- **PENDING (NEEDS SCHEDULING):** `Data.Items`' only shipping writer is an **INSANE Victory** (v3,
  B20) paying `BannerTicket`+`TraitRerollToken`, so counts stay 0 until someone clears one.
- **NOT a bug:** Units-screen stat NUMBERS are per-TOWER (mid-roll ref), so two instances of one
  tower show equal numbers while GRADE letters differ (ADR-0003). `Data.Loadout` fills LEFT TO RIGHT,
  dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, drift-green in BOTH Places.
  Store `Beta1_PlayerData` (Studio `Beta1_PlayerDataDev1`, API access ON); `Migrations[1]` v1→v2
  re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v4** (B23) — `docs/contracts/teleport.md`. Both sides + both directions, ONE
  session. v4 adds `IsMatchmade`, widens `HostUserId` to the ELECTED match host, and **REPEALS "a
  match server contains exactly one party"** (P7 groups strangers across lobby servers); v3 added
  `DifficultyMode`. Hard cutover, **v3 REJECTED**. `LobbyConfig.MatchLaunchVersion` must ALWAYS
  equal `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** `phase-a-foundations.md` is history; detail in CHANGELOG.
**LABEL COLLISION:** changelog `B0…B26` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names — same letters, different sequences. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — a **live two-client** run of the v4 queue (the republish itself is standing practice).
2. **PLAYGUI — `docs/blueprints/playgui.md` is LAW. P1–P7 ✅ COMPLETE** (B14–B23); detail in §9 and
   `docs/systems/play-menu.md`. The ADR-0011 remap is isolated in `PlayGUI.DifficultyScale` — **the
   ONE conversion; never write a second.** B24 cleared the review backlog; B25 audited the V2 kit;
   **B26 ADOPTED it in both Places and retired v1. NEXT = the B27 queue of seven user-found UI
   fixes above**, or a live two-client queue test.
3. **Phase B** (`phases-b-f-meta.md`). Landed B0–B8; Selection ⛔ on the `BannerChoices` PENDING.
   **Phase C (B9): C3 ascension ✅**; **B11 moved it to an NPC screen (ADR-0010) — C1/C2/C4 copy that
   shape.** C1+C2 (AD-Traits) and C3's sell-dupes half are UNBLOCKED by B12; sell-dupes needs the
   unwired `QuickSellButton` + a `GrantService` sell path. Row-by-row status: `docs/ROADMAP.md`.
