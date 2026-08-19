# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-19 (B32) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop as a two-Place vertical
slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons, progression +
match-end rewards, **ProfileStore persistence (schema v3)**, a shared UI kit + **audio/confirm layer**,
and the gacha engine (Standard + Event + Selection banners; ascension AND selling dupes both live).

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

- **NOT A PENDING — STANDING PRACTICE (B25): the user republishes BOTH Places EVERY session.** Only
  *state* it when a contract bumps. Still unconfirmed: a **live two-client v4 queue run** (403 in Studio).
- **NOT A PENDING — SELECTION BANNERS LIVE (B30, B4 ✅), SELL DUPES LIVE (B31, C3 ✅).** ONE writer each:
  `BannerChoiceService`→`BannerChoices`, `GrantService.SellUnits`→the only `Data.Units` delete,
  **`UnitConsumeRules`= the ONE "may this be destroyed" rule** (ascension delegates). `ChosenAtDay` is a
  DAY NUMBER. Docs: `docs/systems/{gacha-selection,ascension}.md`.
- **PENDING (USER, tidy):** the dev profile carries `BannerChoices["B29ProbeBanner"]` — B29's probe, a
  banner id that does not exist, so nothing reads it. Keep it or clear it.
- **NOT A PENDING — B32 SHIPPED THE SHARED FEEDBACK LAYER, BOTH PLACES HASH-MATCHED.** `UIKit.Sound`
  (audio) + `UIKit.Confirm` (one confirmation dialog, 2s grey→green Yes gate) are NEW shared canon;
  `UIKit.Button` now DETECTS panel-style vs flat buttons and `Kit_UnitIconV2` gained
  `SelectedToSellOverlay` (`0bf1a11e`→**`bf39c6c8`**, identical deterministic script in both Places).
  `RS.Remotes`=**20**; **`UnitFlagsService` is THE ONE writer of `Favorited`/`Locked`** (nothing could set
  them before). Doc: `docs/systems/ui-feedback.md`. **Sibling requires use `optionalSibling` (10s+stub):
  a bare `WaitForChild` on a sibling module blocks FOREVER and froze the whole UI mid-deploy.**
- **PENDING (USER, B32): PASTE THE SOUND IDS** into `SoundService.{UI.*, BGM.*}` — all **13** slots are empty, so the game is silent. Nothing else is needed.
- **PENDING (USER, B32): copy `StarterGui.ConfirmationPopupUI` into the GAME's StarterGui** (art cannot
  be scripted — B26 copy/paste rule). Until then `Confirm.ask` there warns once and auto-answers **NO**.
- **PENDING (USER, B32, art/layout):** the six HUD buttons' `UIHoverStroke.Thickness` is **0.05** —
  animates perfectly, invisible (it warns at boot; raise it or set `HoverStrokeThickness`).
  `SellButtons.CancelButton` (x≈475) nearly overlaps `QuickSellButton` (x≈513), and `PlayButton` still
  wears the old **Shop** logo.
- **PENDING (AD-Game, B32): the GAME has no audio owner.** `UIKit.Sound` + the `SoundService` tree are
  deployed there but nothing calls `playBGM(actId)`. Copy `LobbyAudio`'s shape; per-act slots exist.
- **PENDING (AD-UI, design): quests/login/codes need a NEW reveal answer** — the return-value trick only
  serves player-INITIATED grants; no push remote exists. Propose first.
- **PENDING (AD-Game, B24): `UnitIconV2` needs PLACEMENT COST + ELEMENT** (Game-only configs). Prices are
  TEMPORARILY the template placeholder — `Motion.SHOW_PLACEHOLDER_PRICES=false` reverts both Places.
  **(AD-Traits): `TraitDefinitions` has NO icon field.** `docs/proposals/2026-08-16-{tower-display-fields-for-uniticon-v2,trait-icons}.md`.
- **PENDING (USER, design call — B23): GAME SPEED IN A MATCHMADE MATCH.** Speed is match-wide and both
  the authority and the 3× gate come from an **elected stranger**. leave as-is · disable 3× · per-player.
- **PENDING (USER, balance):** `StartingLives` **3 / 15 / 10** across Acts 1–3 while `BaseHealthScale`
  climbs 1.0/1.6/2.4 — Act 1's `3` looks like a leftover test value. A design call.
- **PENDING (user): ONE settings system for BOTH Places**, entries scoped `Both`/`GameOnly`/`LobbyOnly`;
  nothing blocked (audio now has SoundGroups to drive). `docs/proposals/2026-08-09-unified-settings-both-places.md`.
- **PENDING (AD-Game, small): `RewardScalingConfig`'s HEADER COMMENT is stale**; fixing re-hashes `1d789978`.
- **PENDING (AD-UI, small):** HUD `CurrencyBar` refreshes on join only — Gold/Silver read stale after a
  summon or a sale. Wants `ClientEvents.CurrencyChanged`, shaped like B10's `LoadoutChanged`.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; until then the
  Game's `MetaMath=MISSING` is EXPECTED — never "reconcile" it.
- **PENDING (AD-Integration):** invariant 1 ("every grant via `GrantService`") holds in the **Lobby only**;
  the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, user deferred): `UnitIconV2` has FOUR inline consumers** repeating paint/viewport code.
  **Units should SHAPE the controller.**
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split. The hover race is FIXED (B29a):
  a hide must prove it OWNS the preview. Awaiting the user's own fast-sweep confirmation to close.
- **NOT A PENDING — B28: `PlayGUI` is DELIBERATELY EXCLUDED from the open/close slide.** It opens behind
  a `LoadingScreen` veil with a camera capture; a slide would fight the veil.
- **KNOWN REGRESSION (B26, accepted):** V2 has no `ShinyBadge` — **shiny is unmarked on an ascension
  card.** Re-add it to the template or drop it deliberately.
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses stored XP** (`ApplyXP` discards it).
  **(AD-PlayerLevel):** promote `TowerProgressionConfig` to shared for a real XP bar.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING:** `Data.Items`' only shipping writer is an **INSANE Victory** (B20) — counts stay 0 till then.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (mid-roll ref), so two copies show equal numbers while
  GRADES differ (ADR-0003). `Data.Loadout` is dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).

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
2. **PLAYGUI — `docs/blueprints/playgui.md` is LAW. P1–P7 ✅ COMPLETE** (B14–B23); detail in
   `docs/systems/play-menu.md`. The ADR-0011 remap is isolated in `PlayGUI.DifficultyScale` — **the ONE
   conversion; never write a second.** PlayGUI needs nothing further. **B32 note: its HUD entry is now
   `HUD.Left.Buttons.PlayButton`** (renamed from the user's `ShopButton` placeholder; `Play` was gone).
3. **Phase B** (`phases-b-f-meta.md`): B0–B8 + **B30 Selection ✅ → B4 COMPLETE.** **Phase C: C3
   COMPLETE** (ascension B9, **selling B31**); B11 moved ascension to an NPC screen (ADR-0010) —
   **C1/C2 copy that shape, selling deliberately did not** (blueprint C3 says "in Units screen").
   **C1+C2 are AD-TRAITS' and unblocked since B12.** Row-by-row: `docs/ROADMAP.md`.
