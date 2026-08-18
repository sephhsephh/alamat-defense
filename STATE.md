# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-17 (B29) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop as a two-Place vertical
slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons, progression +
match-end rewards, **ProfileStore persistence (schema v2)**, a shared UI kit, and the gacha engine.

- **Game** — the match Place; `MatchEntryService` is the production entry. Owns tower configs,
  combat, the stat resolver, match runtime. Detail: `places/game/CONTEXT.md`.
- **Lobby** — the social/meta Place, scene `Workspace.Lobby`. **`GetUnitViews` is its SINGLE profile
  read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**. `places/lobby/CONTEXT.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`): **27 entries
  = 20 modules + 7 templates**. **B28: BOTH Places are drift-green on all 27 except `MetaMath`**, which is
  PRESENT in the Lobby and MISSING in the Game — EXPECTED, not drift; it stays Lobby-only until Phase D. **B26 adopted the V2 UI kit in BOTH
  Places and RETIRED `Kit_UnitIcon`/`Kit_ItemIcon`/`Kit_HotbarSlot`** (dropped from
  `hash_shared.luau` — do not re-add). Templates hash as INSTANCE trees, no `shared/src` file
  (ADR-0005).

**DRIFT RULE (everyone):** editing a shared controller **or a template** in one Place only is DRIFT.
Change → re-hash → copy to the other Place → update the manifest. **Copying a TEMPLATE across Places
is a USER action** (B26) — pause and ask. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **NOT A PENDING — STANDING PRACTICE (B25): the user republishes BOTH Places EVERY session.** Never
  open a "republish" PENDING; only *state* it when a contract bumps. Still unconfirmed: a **live
  two-client v4 queue run** (`ReserveServer` 403 in Studio).
- **PENDING (AD-Gacha): BUILD THE SELECTION FLOW — the schema half is DONE (B29, v3).**
  `BannerChoices` exists and round-trips in both Places. Remaining, all Lobby-local: a
  `ChooseBannerUnit` remote (server re-checks cooldown + that the TowerId is in the pool — the
  client is a request, never truth), a PER-PLAYER `BannerRegistry.FeaturedFor` (pick + `AutoCount`
  deterministic randoms, excluding the pick), adding `Selection` to `SUPPORTED_TYPES`, and the
  choice UI replacing a Selection card's `ClosedOverlay`. Spec:
  `docs/proposals/2026-08-09-selection-banner-choices.md` §"Then the flow itself".
- **PENDING (AD-UI, design): quests/login/codes need a NEW reveal answer** — the return-value trick
  only serves player-INITIATED grants; no server→client push remote exists. Propose before building.
- **PENDING (AD-Game, B24): `UnitIconV2` needs PLACEMENT COST + ELEMENT** (Lobby has neither; tower
  configs are Game-only). **Prices are TEMPORARILY SHOWN as the template's authored placeholder** —
  `Motion.SHOW_PLACEHOLDER_PRICES = false` reverts every card in both Places. **(AD-Traits, B24):
  `TraitDefinitions` has NO icon field**, so `TraitIcon` stays hidden until it does. Plans:
  `docs/proposals/2026-08-16-{tower-display-fields-for-uniticon-v2,trait-icons}.md`.
- **PENDING (USER, design call — B23): GAME SPEED IN A MATCHMADE MATCH.** Speed is match-wide, and
  both the authority and the 3× gate come from a host who, matchmade, is an **elected stranger**.
  B23 changed nothing. Options: leave as-is · disable 3× matchmade · per-player. Your call.
- **PENDING (USER, balance):** `StartingLives` is **3 / 15 / 10** across Acts 1–3 while
  `BaseHealthScale` climbs 1.0/1.6/2.4 — Act 1's `3` looks like a leftover test value. P5 fixed only
  Act 2's false comment; the numbers are a design call.
- **PENDING (AD-Gacha review):** Integration fixed trait-on-summon in `SummonEngine` —
  `TraitRegistry.Roll(rng)` (there is no `RollTrait`), `"None"`→nil, failures WARN.
- **PENDING (user): ONE settings system for BOTH Places** — same structure + GUI, entries scoped
  `Both`/`GameOnly`/`LobbyOnly`; nothing blocked. `docs/proposals/2026-08-09-unified-settings-both-places.md`.
- **PENDING (AD-Game, small): `RewardScalingConfig`'s HEADER COMMENT is stale** (says Insane cannot
  fire); fixing it re-hashes `1d789978` + redeploys to BOTH Places.
- **PENDING (AD-UI, small):** HUD `CurrencyBar` refreshes on join only — Gold reads stale after a
  summon. Wants `ClientEvents.CurrencyChanged`, shaped like B10's `LoadoutChanged`.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then
  the Game's `MetaMath=MISSING` is EXPECTED — do not "reconcile" it.
- **PENDING (AD-Integration):** invariant 1 ("every grant via `GrantService`") holds in the **Lobby
  only**; the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, user deferred): `UnitIconV2` has FOUR inline consumers** repeating paint/viewport
  code; motion and stroke paint are shared now, the rest is not. **Units should SHAPE the controller.**
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split. **The click TRIGGER is
  CONFIRMED by the user in BOTH Places (B29)** — B27d's `Active` fix is proven end-to-end. **The
  hover race is FIXED (B29a): a hide must now prove it OWNS the preview**; ~70 stale hides were
  logged in one play session, so it was most of a fast sweep, not an occasional glitch. Awaiting the
  user's own sweep to close.
- **NOT A PENDING — B28 note: `PlayGUI` is DELIBERATELY EXCLUDED from the open/close slide.** It opens
  and closes behind a `LoadingScreen` veil with a camera capture; a slide would fight the veil. If a
  transition is ever wanted there, it belongs in that flow, not in a `Motion.slideIn` call.
- **KNOWN REGRESSION (B26, accepted):** V2 has no `ShinyBadge` (`AscensionController` drove it from
  `view.Shiny`) — **shiny is not marked on an ascension card.** Re-add to the template, or drop it.
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses stored XP** (`ApplyXP` discards
  overflow). **(AD-PlayerLevel):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration. (The
  real-DataStore round trip on the PLAYER JOIN path was CONFIRMED at B29, closing A7's scratch-key
  caveat: the live profile migrated v2→v3 on join and a written key survived a stop/start.)

- **PENDING:** `Data.Items`' only shipping writer is an **INSANE Victory** (v3, B20), so item counts
  stay 0 until someone clears one.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (mid-roll ref), so two instances of a tower show
  equal numbers while GRADES differ (ADR-0003). `Data.Loadout` is dense, left-to-right. Difficulty:
  UI 1–100, wire 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v3** (B29) — `shared/src/ProfileTemplate.luau`, hash `72d3944f`, drift-green in BOTH
  Places. Store `Beta1_PlayerData` (Studio `Beta1_PlayerDataDev1`, API access ON). v3 adds
  `BannerChoices` (additive-optional); **`Migrations[2]` is a deliberate NO-OP and must stay one** —
  `Migrate()` warns and STOPS at a missing step, so the gap would strand every later migration.
  `ChosenAtDay` is a `MetaMath.Slot` DAY NUMBER, never a timestamp. Verified live 8 PASS / 0 FAIL: v1
  walks 2 steps, v2 walks 1 non-destructively, and a written entry survived a real DataStore round
  trip. **Forward-tolerant** (Reconcile never prunes), but publish both Places together anyway.
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
   ONE conversion; never write a second.** B25 audited the V2 kit, **B26 ADOPTED it and retired v1**,
   B27a–d did the user's play-test queue; **B28 landed the open/close SLIDE and closed the
   `Kit_HotbarSlotV2` drift.** PlayGUI needs nothing further.
3. **Phase B** (`phases-b-f-meta.md`). Landed B0–B8; Selection ⛔ on the `BannerChoices` PENDING.
   **Phase C (B9): C3 ascension ✅**; **B11 moved it to an NPC screen (ADR-0010) — C1/C2/C4 copy that
   shape.** C1+C2 (AD-Traits) and C3's sell-dupes half are UNBLOCKED by B12; sell-dupes needs the
   unwired `QuickSellButton` + a `GrantService` sell path. Row-by-row status: `docs/ROADMAP.md`.
