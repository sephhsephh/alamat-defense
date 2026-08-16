# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-16 (B23) -->
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

- **PENDING (USER, BLOCKING + URGENT): republish BOTH Places TOGETHER — AGAIN, for v4.** The user
  confirmed at B23 that the **v3** republish was done. B23 then bumped the contract to **v4** (P7),
  so Studio is ahead of live again and **v3/v4 do not interoperate** — a PARTIAL publish breaks EVERY
  launch with `[CONTRACT] PayloadVersion mismatch`. A live run of the loop is still unconfirmed.
- **PENDING (AD-Game/AD-Integration, BLOCKS the Selection banner): add `BannerChoices` to the save
  schema** (v2→v3, additive-optional = Reconcile + bump + no-op `Migrations[2]`), **BOTH Places in
  ONE session** (invariant 5). Plan + the rejected `Counters.Global` shortcut:
  `docs/proposals/2026-08-09-selection-banner-choices.md`. Selection is one line after.
- **PENDING (AD-UI, design): quests/login/codes need a NEW reveal answer** — the return-value trick
  only serves player-INITIATED grants, and no server→client push remote exists. Design work: propose
  before building. (The five-item review backlog was **CLEARED at B24** — all five confirmed correct.)
- **PENDING (AD-Game, from B24): the V2 unit icon needs PLACEMENT COST + ELEMENT** and neither exists
  in the Lobby — `UnitStatsCatalog` is only `{DMG,RNG,SPA}` and tower configs are Game-only. Plan:
  `docs/proposals/2026-08-16-tower-display-fields-for-uniticon-v2.md`. Fields are HIDDEN until then.
- **PENDING (AD-Traits, from B24): `TraitDefinitions` has NO icon field**, so `UnitIconV2.TraitIcon`
  cannot render. Additive + optional, but it is shared canon → drift procedure. Plan:
  `docs/proposals/2026-08-16-trait-icons.md`.
- **PENDING (AD-UI, from B24): adopt the V2 kit templates.** The user authored `Kit.UnitIconV2` /
  `ItemIconV2` / `HotbarSlotV2`; the user chose **replace v1 outright**, which migrates the GAME's
  hotbar too, so it is a **cross-Place, both-Places-one-session** job — not a Lobby-only task.
  Favourite/Lock render read-only (no remote writes them; `LockUnitButon` is authored but unwired).
- **PENDING (USER, design call — surfaced by B23's v4 survey): GAME SPEED IN A MATCHMADE MATCH.**
  Speed is match-wide and BOTH the authority to change it and the 3× gamepass entitlement come from
  the host alone. Matchmade, that host is an **elected stranger** (lowest userId), so a stranger's
  purchase decides whether everyone gets 3× and a stranger holds the control. B23 changed NOTHING
  here deliberately and logs `[CONTRACT] MATCHMADE match: speed authority ...` so it is visible.
  Options: leave as-is · disable 3× when matchmade · per-player speed. Your call.
- **PENDING (USER, balance):** `StartingLives` is **3 / 15 / 10** across Acts 1–3 while
  `BaseHealthScale` climbs 1.0/1.6/2.4. Act 1's `3` looks like a leftover test value. P5 fixed only
  Act 2's false comment; changing numbers is a design call.
- **PENDING (AD-Gacha review, ONE user-authorised item):** Integration fixed trait-on-summon in
  `SummonEngine` — the call is `TraitRegistry.Roll(rng)` (there is no `RollTrait`), `"None"` → nil,
  failures WARN. Verified live.
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
- **PENDING (NEEDS SCHEDULING):** `Data.Items`' only shipping writer is an **INSANE Victory** (v3,
  B20), paying `BannerTicket` + `TraitRerollToken` — so counts stay 0 until someone clears one.
- **NOT a bug:** Units-screen stat NUMBERS are per-TOWER (catalog mid-roll ref), so two instances of
  one tower show equal numbers while GRADE letters differ (ADR-0003). `Data.Loadout` fills LEFT TO
  RIGHT, dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v4** (B23, 2026-08-16) — `docs/contracts/teleport.md`. Both sides + both
  directions, deployed in ONE session. v4 adds `IsMatchmade`, widens `HostUserId` to the ELECTED
  match host, and **REPEALS "a match server contains exactly one party"** (P7's queue groups
  strangers across lobby servers). v3 added `DifficultyMode`. Hard cutover, no migration; **v3 is
  REJECTED**. `LobbyConfig.MatchLaunchVersion` must ALWAYS equal `GameConfig.TeleportPayloadVersion`.
  Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A SIGNED OFF (A9).** Blueprint `phase-a-foundations.md` is history; detail in CHANGELOG.

**LABEL COLLISION:** changelog `B0…B13` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names. Different sequences, same letters. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — republish both Places TOGETHER (v4 is a hard cutover), then run the loop live once.
2. **PLAYGUI — `docs/blueprints/playgui.md` is LAW. P1–P7 ✅ COMPLETE** (B14–B23); detail in §9 and
   `docs/systems/play-menu.md`. The ADR-0011 remap is isolated in `PlayGUI.DifficultyScale` — **the
   ONE conversion; never write a second.** B24 cleared the five-item review backlog and mirrored the
   reward preview into `LobbyFrame`. **NEXT = the V2 kit adoption (cross-Place)**, or a live
   two-client queue test once the user republishes.
3. **Phase B** (`phases-b-f-meta.md`). Landed B0–B8; Selection ⛔ on the `BannerChoices` schema
   PENDING above. **Phase C (B9): C3 ascension ✅**; **B11 moved it to an NPC screen (ADR-0010) —
   C1/C2/C4 copy that shape.** C1+C2 (AD-Traits) and C3's sell-dupes half are UNBLOCKED by B12;
   sell-dupes needs the unwired `QuickSellButton` + a `GrantService` sell path. Row-by-row status
   lives in `docs/ROADMAP.md` — do not duplicate it here.
