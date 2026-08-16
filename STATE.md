# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-16 (B25) -->
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
  = 19 modules + 7 templates.** All 26 PRESENT in the Lobby; the GAME reads 25/26 and that ONE gap is
  EXPECTED, not drift — `MetaMath` stays Lobby-only until Phase D. **B23 cleared the `ItemCatalog`
  drift: `fc4b8023` in BOTH Places** (the user's real icon assetids). Templates hash as INSTANCE
  trees, no `shared/src` file (ADR-0005). `UnitStatsCatalogValidate` is Game-only by design.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **NOT A PENDING — STANDING USER PRACTICE (stated 2026-08-16, B25): the user republishes BOTH
  Places EVERY session.** Never open a "republish" PENDING again. Worth *stating* in an advisory when
  a session bumps a contract (both Places must go out TOGETHER), but treat it as done, not owed.
  Still unconfirmed: a **live two-client run of the v4 queue** (`ReserveServer` = 403 in Studio).
- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), **BOTH Places in ONE
  session** (invariant 5). Plan: `docs/proposals/2026-08-09-selection-banner-choices.md`.
- **PENDING (AD-UI, design): quests/login/codes need a NEW reveal answer** — the return-value trick
  only serves player-INITIATED grants and no server→client push remote exists. Propose before
  building. (The five-item review backlog was **CLEARED at B24** — all five confirmed correct.)
- **PENDING (AD-Game, B24): the V2 unit icon needs PLACEMENT COST + ELEMENT**, neither of which
  exists in the Lobby (`UnitStatsCatalog` is only `{DMG,RNG,SPA}`; tower configs are Game-only).
  Plan: `docs/proposals/2026-08-16-tower-display-fields-for-uniticon-v2.md`. HIDDEN until then.
- **PENDING (AD-Traits, B24): `TraitDefinitions` has NO icon field**, so `UnitIconV2.TraitIcon`
  cannot render. Additive + optional, but shared canon → drift procedure.
  Plan: `docs/proposals/2026-08-16-trait-icons.md`.
- **PENDING (USER then AD-Integration, B25): V2 kit adoption is BLOCKED ON THREE AUTHORED
  INSTANCES.** **DECIDED at B25, do not re-derive: rarity goes on the ROOT `UIGradient`, the tier
  BORDER is dropped** (v1's `BG` + `UIStrokeWithGradient` are absent from V2; `UIHoverStroke` is
  hover-only). **USER must author:** `SlotNumber` on `HotbarSlotV2` (the 1–6 key, used by the SHARED
  `UIKit.Hotbar` in BOTH Places), `CountLabel` on `UnitIconV2`, `UIAspectRatioConstraint` on
  `ItemIconV2`. Gap table + rename map + build order:
  `docs/proposals/2026-08-16-v2-kit-adoption-gaps.md`. **THREE** `Kit.UnitIcon` consumers, not two —
  `AscensionController` is the third.
- **PENDING (USER, design call — B23's v4 survey): GAME SPEED IN A MATCHMADE MATCH.** Speed is
  match-wide and BOTH the authority and the 3× gamepass gate come from the host alone — matchmade,
  that host is an **elected stranger** (lowest userId). B23 changed nothing and logs
  `[CONTRACT] MATCHMADE match: speed authority ...`. Options: leave as-is · disable 3× when
  matchmade · per-player. Your call.
- **PENDING (USER, balance):** `StartingLives` is **3 / 15 / 10** across Acts 1–3 while
  `BaseHealthScale` climbs 1.0/1.6/2.4. Act 1's `3` looks like a leftover test value. P5 fixed only
  Act 2's false comment; changing numbers is a design call.
- **PENDING (AD-Gacha review, ONE user-authorised item):** Integration fixed trait-on-summon in
  `SummonEngine` — the call is `TraitRegistry.Roll(rng)` (no `RollTrait`), `"None"` → nil, failures
  WARN. Verified live.
- **PENDING (AD-Game → AD-Integration → AD-UI): ONE settings system for BOTH Places** (user) — same
  structure + GUI in both, entries scoped `Both`/`GameOnly`/`LobbyOnly`. Plan:
  `docs/proposals/2026-08-09-unified-settings-both-places.md`. Nothing is blocked.
- **PENDING (AD-Game, small): `RewardScalingConfig`'s HEADER COMMENT is stale** (says Insane cannot
  fire); fixing it changes hash `1d789978` → comment-only re-hash + redeploy to BOTH Places.
- **PENDING (AD-UI, small):** HUD `CurrencyBar` does not refresh after a summon (join only), so Gold
  reads stale. Wants a `ClientEvents.CurrencyChanged` — copy B10's `LoadoutChanged` shape.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then
  the Game's 25/26 `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.
- **PENDING (AD-Integration, not urgent):** invariant 1 ("every grant via `GrantService`") holds in
  the **Lobby only** — the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places (`MouseEnter`
  cannot be fired from tooling — same limit will apply to V2's `UIHoverStroke`). Also
  `Kit_ItemHoverCard`'s master/clone split.
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses stored XP** (`ApplyXP` discards
  overflow at max) — cosmetic, but the Units screen shows it.
- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** real-DataStore round-trip for the PLAYER profile (A7 used a scratch key); plus the `ServerStorage.Documentation` → `docs/systems/` migration.
- **PENDING (NEEDS SCHEDULING):** `Data.Items`' only shipping writer is an **INSANE Victory** (v3,
  B20), paying `BannerTicket` + `TraitRerollToken` — so counts stay 0 until someone clears one.
- **NOT a bug:** Units-screen stat NUMBERS are per-TOWER (mid-roll ref), so two instances of one
  tower show equal numbers while GRADE letters differ (ADR-0003). `Data.Loadout` fills LEFT TO RIGHT,
  dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, drift-green in BOTH
  Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON). `Migrations[1]`
  v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v4** (B23, 2026-08-16) — `docs/contracts/teleport.md`. Both sides + both
  directions, ONE session. v4 adds `IsMatchmade`, widens `HostUserId` to the ELECTED match host, and
  **REPEALS "a match server contains exactly one party"** (P7's queue groups strangers across lobby
  servers). v3 added `DifficultyMode`. Hard cutover; **v3 is REJECTED**.
  `LobbyConfig.MatchLaunchVersion` must ALWAYS equal `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION:** changelog `B0…B13` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names. Different sequences, same letters. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — a **live two-client** run of the v4 queue (the republish itself is standing practice).
2. **PLAYGUI — `docs/blueprints/playgui.md` is LAW. P1–P7 ✅ COMPLETE** (B14–B23); detail in §9 and
   `docs/systems/play-menu.md`. The ADR-0011 remap is isolated in `PlayGUI.DifficultyScale` — **the
   ONE conversion; never write a second.** B24 cleared the five-item review backlog and mirrored the
   reward preview into `LobbyFrame`. B25 audited the V2 kit and stopped at its gate.
   **NEXT = the V2 adoption once the user authors the three missing instances**, or a live
   two-client queue test.
3. **Phase B** (`phases-b-f-meta.md`). Landed B0–B8; Selection ⛔ on the `BannerChoices` schema
   PENDING above. **Phase C (B9): C3 ascension ✅**; **B11 moved it to an NPC screen (ADR-0010) —
   C1/C2/C4 copy that shape.** C1+C2 (AD-Traits) and C3's sell-dupes half are UNBLOCKED by B12;
   sell-dupes needs the unwired `QuickSellButton` + a `GrantService` sell path. Row-by-row status
   lives in `docs/ROADMAP.md` — do not duplicate it here.
