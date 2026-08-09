# ROADMAP — feature status for the whole Experience
<!-- owner: all (any chat updates its own system's rows at landing) | scope: global -->
<!-- last-verified: 2026-08-06 -->

Status legend: ✅ done · 🟡 partial/placeholder · 🔲 planned · 💭 idea (not committed)
Meta-systems detail + rationale: `docs/proposals/2026-07-18-meta-systems-design.md`
(approved; decisions: apex tier **Bathala**, secret rate ~0.005%, dupes → **Ascension**
(1 dupe + artifacts) or sell for Silver, stat grades **D C B A S SS SSS + Apex**,
everything untradeable at launch).

## Game place — core loop

- ✅ Match lifecycle state machine (WaitingForData→…→Cleanup), Classic mode, win/lose
- ✅ Stage/Act campaign structure (Stage 1, Acts 1–3, NextActId chaining)
- ✅ Waves: overlapping schedule, intermissions, skip votes, auto-advance on clear
- ✅ Difficulty: per-act BaseHealthScale × player slider (1–1000%) × per-wave scaling
- ✅ Economy: kill/wave rewards, wave income, sell/upgrade, Farm income passives
- ✅ Towers: placement, per-tier attacks, 9 targeting modes, traits, meta-level scaling,
  auto-upgrade + Unit Manager, sell/upgrade UI
- ✅ Abilities: passives, actives + Q/C UI, summons · ✅ status effects + elements
- ✅ Game speed 1×/2×/3× virtual clock (3× behind gamepass flag)
- ✅ Match end: stats/MVP, rewards commit, tower XP screen, Next Act validation
- ✅ Persistence: ProfileStore schema v1, session-locked, dev store in Studio
- ✅ Settings persisted in profile
- 🟡 Art: attack anim/VFX/sound ids placeholder; weapon grips approximate
- 🟡 Monetization: config + 3× gamepass check exist; purchase path unwired
- 🟡 Content: 1 map, 2 enemies, 8 towers, 1 stage — pipeline proven, content thin
- 🔲 Enemy behaviors (Flying/Splitting/Shielding) · 🔲 Endless + BossRush modes
- 🔲 Persistence round-trip test (PENDING in STATE.md)
- 💭 Spatial partitioning for enemy queries

## Lobby place

- ✅ v1: shared-module deploy + boot (drift-free; profile from PlayerData_Dev)
- ✅ v1: blockout hub (`Workspace.Lobby`) · ✅ collection screen (read-only, end-to-end)
- ✅ v1: stage select + difficulty slider
- ✅ v1: Play → teleport (contract v1, reserved-server-per-party; `GamePlaceId` set 2026-07-18)
- ✅ v1: MatchReturn handling (welcome-back banner + next-act pre-select in stage select)
- ✅ v1: auto-loadout in launch payload (owned towers, cap 6; interim until loadout picker UI)
- ✅ First-join starter tower choice (starter seed removed from ProfileTemplate 2026-07-18;
  picker now active for fresh accounts)
- ✅ Collection screen rebuilt on real instances + the `GetUnitViews` view-model (A5, 2026-08-03)
- ✅ Items screen (A5, 2026-08-03) — catalog-driven; real counts land when an item economy does
- 🟡 v1: parties (in-memory, single-server; cross-server/persisted = later phase)
- ✅ **Equipping (2026-08-06)** — `Server.Lobby.LoadoutService` (`SetLoadoutSlot`) is the FIRST
  writer of `Data.Loadout`, so `Equipped` is finally real. Slots fill LEFT TO RIGHT (dense uuid
  list — a contract requirement). The shared hotbar is the picker UI. **A7 verified the full chain
  live: equip in the Lobby → the Game place starts a match from those exact uuids.**
- 🔲 Item economy: nothing writes `Data.Items` in normal play (a latent Victory-drop path exists
  in the Game's `RewardCalculator`, but it has never fired), so every count is 0

## Cross-Place

- ✅ Save schema v1 shared + deployed to both Places
- ✅ Teleport handoff: contract v1 done BOTH sides + BOTH directions; config-complete
  (both place ids set) and LIVE-verified in the production client (user, 2026-07-18)
- ✅ Game-side production entry: TeleportData.MatchLaunch → StartMatch (`MatchEntryService`)
- ✅ Game→Lobby return: `ReturnToLobby` builds `MatchReturn` v1 + teleports (guarded on LobbyPlaceId)
- ✅ First e2e run: lobby → reserved match → return → banner (Integration session in Studio
  2026-07-18 + user's live production run same day)
- ✅ **Schema v2**: done BOTH Places — uuid unit `Units`, `Currencies` map, PlayerLevel, Pity,
  Quests, LoginStreak, ShopStock, Titles, Spirits, BP, Counters; `Migrations[1]` v1→v2 verified
  (hash `63a0c98a`, drift-green in Game + Lobby). Game A1 2026-08-01, Lobby A2 2026-08-01.
- ✅ **Teleport v2** (A2, 2026-08-01): `Loadout` carries unit uuids, `PayloadVersion = 2` both
  sides, hard cutover (v1 rejected). Studio-verified; live re-run pending the user's republish.
- ✅ **Counters pipeline (blueprint §6)** — done at **A8 [AD-Game], 2026-08-06**. Match end commits
  `Counters.PerUnit[uuid].Kills` + `Worthiness` (one commit, capped 100) and
  `Counters.Global.{Clears, ClearsByStage[stageId], Waves}`; `Counters.Global.Summons` increments
  live from `SummonManager`. Verified across two real 15-wave matches (Defeat + Victory) with
  per-uuid deltas matching `MatchStatsTracker` exactly. Rate lives in
  `RS.Configs.Global.WorthinessConfig` (0.02/kill). **No schema bump** — v2 already had the fields.
  Lobby needed no change: `GetUnitViews` already serves `Worthiness`. Feeds quests + evolution
  takedowns later.

## Meta-systems (phased; each phase ships playable)

**IMPLEMENTATION BLUEPRINTS (read before building anything below — they are law):**
Phase A: `docs/blueprints/phase-a-foundations.md` (schema v2 exact shape, migration,
catalog/configs, icon kit, session plan A1–A7). Phases B–F:
`docs/blueprints/phases-b-f-meta.md` (algorithms, config shapes, session plans, invariants).

### Phase A — Foundations (first; everything depends on it)
- ✅ Schema v2 (A1 Game + A2 Lobby, hash `63a0c98a`) + teleport v2 (A2) — see above
- ✅ ItemCatalog registry (A3, 2026-08-01): `RS.Configs.Meta.ItemCatalog` — 13 entries (8 towers
  tiered + Gold/Silver + BannerTicket/TraitRerollToken/GoldenSeed), `Tradeable=false`, `Validate()`
  runs at boot (`MetaConfigTest`). Placeholder icon assetids until A4.
- ✅ TierConfig (A3): `RS.Configs.Meta.TierConfig` — Common→…→**Bathala** order + colors +
  tier assignment for the 8 towers. (+StatGradeConfig D..Apex, +AscensionConfig 3 levels.)
  A Lobby interim TierConfig/UnitCatalog exists (2026-07-31) → reconcile at A7 promotion to shared.
- ✅ Tower base-stat RANGES + resolver (A3): `BaseStats` quality ranges on the Archer + Mage
  pilots; `TowerStatResolver` folds `StatRolls × Ascension` into DMG/RNG/SPA (SPA inverted).
  Scalar/no-BaseStats towers byte-identical (regression verified). Client stat PREVIEWS still flat
  (rollMult 1.0) until the UI wire-up (A4–A6); server gameplay is roll-correct.
- 🟡 Shared icon/UI kit (AD-UI): **`UIKit.Button` (2026-07-31) + `UIKit.ItemIcon` and
  `UIKit.FilterPanel` (A5, 2026-08-03)**, all in `RS.Shared.UIKit`, cloning REAL instance
  templates from **`RS.UITemplates.Kit`** (the blueprint §5 home — `StarterGui.UITemplates`
  was emptied into it at A5). Tier-coloured borders via the shared `TierConfig`.
  ✅ **Kit PROMOTED to shared canon 2026-08-06**, pulled forward from A7 because A6's Game hotbar
  depends on it. Now **6 controllers + 8 templates**, deployed byte-identically to BOTH Places —
  **drift 24/24 GREEN**, re-verified at A7. Place-neutral doc: `docs/systems/ui-kit.md`.
  🟡 **`Kit_UnitIcon`** (A6) — the blueprint §5 UnitIcon. It WAS the Game hotbar's slot until the
  shared-hotbar work replaced it with `Kit_HotbarSlot`, so it now has **no consumer**. **PARKED by
  user decision (ADR-0007)**: not adopted, not deleted, revisited in Phase B. Do not delete it and
  do not build a controller for it speculatively.
  ❌ **`RewardPopup`** (A6) — **RETIRED at B2 (2026-08-08).** `Kit_RewardPopup` + `UIKitRewardPopup`
  were catalog-id driven shared canon in both Places but were never wired to a caller; the Lobby's
  `ObtainRewardsGUI` superseded them at B1. Deleted in both Places, manifest **24 → 22**,
  `shared/src` file deleted. Its catalog-resolution behaviour — including "an id absent from the
  catalog still renders" — was carried over to `ObtainRewardsController`. Do not re-add.
  ✅ **`CurrencyBar`** (A6) — built **Lobby-local** (`HUD.Top.CurrencyBar`), not shared: a
  single-Place widget under drift control costs a cross-Place sync forever.
  Still 🔲: UnitHoverCard, ViewportPreview, NPCPrompt; a `UIKit.UnitIcon` controller (deferred —
  one consumer today, so `UIKit.Button` + the template suffice).
- ✅ **Hotbar rebuilt on kit — BOTH Places (2026-08-06)**: ONE component (`UIKitHotbar` +
  `Kit_HotbarSlot`, the user's own design), same look/hover/animation; only `OnActivated` differs
  (Lobby opens Units on that unit, Game starts placement). Always 6 slots, filled/empty/locked;
  locks are Lobby-only by design. 🔲 the hover TRIGGER is still unverified in both Places
  (`MouseEnter` cannot be fired from tooling) — one manual hover each closes it.
- ✅ **Units screen on kit + view-model (Lobby; A4 2026-08-03, A5 filters 2026-08-03)** —
  uuid cards from `GetUnitViews`, shared multi-colour tier borders, per-stat GRADE letters in
  the designed `Grade` labels, real Level/XP, sort (equipped>favourited>tier>name), live search,
  and the shared FilterPanel (tier + equipped/favourited/locked). ✅ **Resolved stat NUMBERS —
  COMPLETE:** AD-Game's `UnitStatsCatalog` `3bb9b140` + validator (A6, 2026-08-03, ADR-0003),
  Lobby deploy (A6b, 2026-08-06, drift 9/9), and **AD-UI filled the slots (2026-08-06)** —
  `UnitStatsCatalog.Get`, decimals trimmed, `--` for Farm's absent DMG/SPA, never "nil".
  Numbers are per-TOWER at the mid-roll reference, not per-unit (ADR-0003's accepted trade).
  Real per-unit models + functional action buttons still 🔲.
- ✅ **Items screen on kit (Lobby, A5 2026-08-03)** — `UIKit.ItemIcon` cards (flat ImageLabel,
  no viewport), QtyBadge, tier borders, hover card, selected panel, search + FilterPanel
  (tier/kind/owned-only). Counts come from `GetUnitViews.Items`. 🔲 blocked on there being an
  item economy at all: **nothing writes `Data.Items`**, so every count is legitimately 0.
- ✅ **FilterPanel kit component (A5)** — GroupTemplate + ToggleTemplate + Apply/Reset/Cancel,
  pending-vs-applied state; shared by the Units and Items screens.
- ✅ **CollectionScreen converted to real instances (A5)** — was script-built, now
  `Panel.Grid.CardTemplate` + a controller on `GetUnitViews`. This removed the last reader of
  `GetCollection`'s interim `Towers`/`Currency` compat fields.
- ✅ **`UnitStatsCatalog` deployed to the Lobby (A6b, 2026-08-06)** — 9th shared module,
  `3bb9b140`, **drift GREEN 9/9 in both Places**; verified requireable from a client context.
- ✅ **`GetCollection` RETIRED entirely (A7, 2026-08-06)** — handler + the `RS.Remotes` instance
  deleted per ADR-0004, after re-grepping BOTH Places for readers (zero) and re-verifying all 7
  Lobby screens still load with no errors and no infinite-yield. `GetUnitViews` is now the Lobby's
  single profile read path.

### Phase A acceptance (§8) — run at A7, counters closed at A8, both 2026-08-06.
**Every §8 item now passes except one PARTIAL. Sign-off waits on a USER decision, not on code.**

- ✅ starter grant with real rolls · ✅ hotbar + Items on the kit · ✅ match plays with resolver
  stats (7 waves, 46,375 dmg) · ✅ **match-end XP committed by uuid** · ✅ v1→v2 migration on a real
  ProfileStore round trip · ✅ drift 24/24 in both Places · ✅ **equip → launch → match uses that
  loadout, across Places**
- ✅ **counters + worthiness committed by uuid (A8)** — was the ❌ at A7. Two real 15-wave matches:
  Defeat gave `Waves 15`, `Summons 111`, per-uuid kills Archer 171 / Necromancer 66 / Warchief 34 /
  Meteor 10, each exactly matching `MatchStatsTracker`; Victory then gave `Clears 1`,
  `ClearsByStage.Stage1_Act1 1`, `Waves 30` (cumulative), `Summons 255`. Worthiness = kills × 0.02
  on every unit; the 100 cap held against two contrived 999,999-kill commits.
- ✅ **Units screen — PASSES with a recorded exception (ADR-0007, USER 2026-08-06).** It renders
  through the kit's FilterPanel and the shared TierConfig/StatGradeConfig/UnitStatsCatalog; its
  CARDS are screen-local by design. §8 reads pragmatically, `Kit_UnitIcon` is PARKED for Phase B,
  and the Collection screen stays out of scope. The exception is recorded, not pretended away.

**✅ SIGNED OFF 2026-08-06 (A9, AD-Integration).** Every §8 item PASSES, re-verified live in both
Places — counters/worthiness re-observed from scratch rather than taken from A8's report, and each
run's totals read back at the next boot through a real ProfileStore round trip. Full table in
`docs/blueprints/phase-a-foundations.md`. **PHASE A IS COMPLETE (A1–A9).**

**Carried out of Phase A deliberately, then FIXED as the first Phase B task:** placement was not
uuid-aware, so a duplicate tower never fought and was granted XP twice.

### Phase B — Gacha

- ✅ **B0 — placement is uuid-addressed (AD-Game, 2026-08-08). Duplicates work; banners unblocked.**
  `RequestPlace` carries a unit uuid; `LoadoutValidator.FindByUuid` resolves it against the server's
  own validated loadout; placement limits count per uuid; `MatchStatsTracker` keys by uuid; each
  uuid earns XP + counters from its own damage/kills, and A8's first-entry rule is gone. Verified
  live with TWO Archers in one loadout at deliberately different levels/rolls: resolved DMG
  **306.45 vs 14.27**, limits **1/1 (Godly) vs 1/4**, kills **215 vs 6** each matching the tracker,
  and the real `RequestPlace` remote accepted the uuid while rejecting a bare TowerId, a forged
  uuid and a non-string. No shared module touched — drift stayed 24/24 and the Lobby needed nothing.
- ✅ **B1 — the reward-reveal surface is BUILT (AD-UI, Lobby, 2026-08-08).**
  `StarterGui.ObtainRewardsGUI` + `ObtainRewardsController`, driven by
  `RS.ClientEvents.ShowRewards`. ONE grid, MIXED units + items; unit cell = the user's own
  `UnitTemplate` (150×150, adopted as-is per ADR-0007, kept **Lobby-local**), item cell = a fresh
  clone of shared `Kit.ItemIcon` — same footprint, no distortion. 5 columns; rows 1–3 grow the
  frame, row 4+ freezes Y and scrolls with `CanvasSize` still covering every row. Click-anywhere
  dismiss after a 0.35s dead period; back-to-back grants QUEUE. Verified live at n = 1/3/5/6/11/15/
  20 plus queue, dead-period and unknown-id cases. **First caller = gacha (B3).**
- ✅ **B4 — the reveal ANIMATES (2026-08-09).** Cells pop in ONE AT A TIME (`UIScale` 0.6→1,
  Back/Out) instead of all at once, and the click became two-stage: **click 1 = SKIP** (instant, not
  gated — skipping only shows you more), **click 2 = CLOSE** (gated by `InputDeadSeconds` measured
  from when the reveal FINISHED, so a reward can never be clicked away before it is seen). Stagger /
  pop / start-scale / total-duration cap are ScreenGui attributes. The pop `UIScale` is created on
  runtime CLONES — `Kit_ItemIcon` is hashed shared canon and was verified untouched at `5623f4b4`.
  Verified live at n=1/3/6/10/15/20 incl. the scrollbar case; cell 1 never reflows; layout numbers
  identical to B1's. Written by AD-Gacha inside AD-UI's canon on the user's authorisation —
  **AD-UI review PENDING**. Doc moved to `docs/systems/lobby-ui.md`.
- ✅ **B3 — the BANNER ENGINE (AD-Gacha, Lobby, 2026-08-09).** The blueprint's B1 + B2
  session-tasks together (user decision). `docs/systems/gacha.md`.
  **`RS.Shared.MetaMath`** is new shared canon (`6badac1d`, Lobby-only — the Game reports MISSING
  and that is expected): deterministic `Slot` rotations + weighted `Pick`, cross-phase invariant 3.
  **`GrantService.Grant/Spend`** is THE one grant path (invariant 1) — all-or-nothing, routes by
  `ItemCatalog.Kind`, refuses uncatalogued ids (invariant 4), caps `MaxOwned`; it is also the
  first code that can write `Data.Items`. **`BannerRegistry`** auto-scans `RS.Configs.Banners`.
  **`SummonEngine`** is the pure roll half, split out precisely so the odds harness can assert the
  REAL algorithm. Verified live: **10k dry rolls, 0 distribution failures**, every tier inside 4σ;
  pity forced/priority/reset; x1 + x10 through the real remote into the real reveal
  (`n=10 cols=5 rows=2`, no scroll); units 8→22, Gold spent, `Pity.Default` persisted.
- 🟡 **Summon UX (blueprint B3) — BUILT at B6 (2026-08-09), two pieces deliberately deferred.**
  `StarterGui.SummonScreen` + `SummonController`: banner carousel, x1/x10, featured chips, rates
  table, refusal handling — all **config-driven** from `BannerRegistry` + `GachaConfig`, so a new
  banner file or a new allowed pull count needs no code. Verified live through the real remote
  (Gold 48800 → 46700 over 21 pulls; x7 refused with the balance untouched).
  **Opened by firing `RS.ClientEvents.OpenSummon`**, never by calling the screen — which is what
  makes the two deferred pieces cheap:
  - 🔲 **Summon NPC** — the Lobby has no NPC or ProximityPrompt system at all, so the HUD `Summon`
    button ships first. Adding an NPC later means firing the same event; **no screen change**.
  - 🔲 **Skip-anim toggle** — deferred into the bigger **unified settings system** the user asked
    for (`docs/proposals/2026-08-09-unified-settings-both-places.md`). Not blocking: B4's
    click-to-skip already covers the need.
  - Rarity colours come from `TierConfig` throughout (chips, rates, and the reveal's own painting).
- 🔲 Selection + Event banners (blueprint B4) — both types are already registered and validated,
  and deliberately REFUSED at summon (`banner_type_not_supported_yet`) until their flows exist.
- 🔲 Unit Index/Codex (blueprint B5): all units, obtained silhouettes, sources, full rates
  disclosure. Also the point at which `Kit_UnitIcon`'s fate (ADR-0007) gets settled.
- 🔲 Trait-on-summon — **inert, not missing**: the chance is tuned and the RNG draw is already
  consumed, but the trait rarity table is AD-Traits canon in the GAME place. Promoting it switches
  this on with no Lobby change. (Shiny-on-summon IS live: 0.870% measured vs 1% configured.)
- 🔲 No Secret / Exclusive / Bathala tower exists, so those tiers are unreachable content. A
  Secret roll falls down to the nearest stocked tier and is logged; `Validate()` reports it as a
  content-gap NOTE, not an error.

### Phase C — Unit depth
- 🔲 Trait reroll NPC/UI (filter-protect + confirm + auto-stop on filtered, hold-to-
  reroll, trait index w/ odds, viewport select)
- 🔲 Stat reroll NPC/UI (D C B A S SS SSS + Apex; StatGradeConfig odds/ranges/colors)
- 🔲 Worthiness meter (kills → 100% = guaranteed A-floor + boosted top-grade odds;
  resets on reroll; shown on hover card)
- 🔲 **Ascension**: Mythic+ only, max 3 levels; 1 duplicate + artifact materials per
  level; per-level stat multipliers in AscensionConfig (e.g. A1 ×1.05 → A3 ×3);
  dupes sellable for Silver; locked/favorited protection
- 🔲 Feeding (per-stage exp food via catalog; mass-feed w/ protections)

### Phase D — Economy loops
- 🔲 Crafting (fragments→artifacts→rainbow; CraftingRecipes config; caps via catalog)
- 🔲 Challenges (rotating daily modifiers stage; artifact rewards — closes crafting loop)
- 🔲 Shop NPC (per-player daily stock keyed by day number; ShopConfig; Silver prices)
- 🔲 Daily login (7-day repeating cycle, deterministic reset hour config)
- 🔲 Quests + pinned-quest tracker in both Places (QuestConfig; progress via Counters;
  Beginner's Path + Dailies first)
- 🔲 Codes system (CodesConfig: rewards, expiry, one-per-player)

### Phase E — Seasonal & presentation
- 🔲 Battlepass (seasonal config file; 50 tiers free/paid; BP XP at match end; level skips)
- 🔲 Event framework (event banner + EventTokens + event quests bundle; Pre-Release first)
- 🔲 News/update board + banner showcase on join
- 🔲 Titles (equip UI + overhead) · 🔲 Skins (catalog → model swap both Places)

### Phase F — Endgame & social
- 🔲 Evolution NPC/UI (recipe per tower: artifacts + tower-specific drops w/ pity +
  Takedowns counter + Silver → "(Awakened)" instance preserving Trait/Shiny/Stats;
  Bathala-tier results) — needs C+D mature
- 🔲 Spirits (attach to units, stat boosts + passives; act-specific drops)
- 🔲 Endless mode + global leaderboards (waves/summons/level)
- 🔲 AFK rewards · 🔲 Team presets · 🔲 Group/like milestone rewards
- 🔲 Monetization store (VIP/luck/x2XP passes, gold packs, BP; purchase path)
- 💭 Trading hub (all items untradeable until then) · 💭 Tutorial place · 💭 Event worlds

## How to update this file

At landing, flip the rows your session changed, add new planned rows where they belong,
keep 💭 at section bottoms. Detail lives in system docs/CONTEXT/proposals — this is the
one-glance status board.
