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
- 🔲 Loadout picker UI (player chooses their 6; replaces auto-loadout) — also the missing
  `Data.Loadout` WRITER, so `Equipped` is false everywhere until it exists
- 🔲 Item economy: nothing writes `Data.Items` in either Place (no drop/grant/shop path yet)

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
- 🔲 Counters pipeline: Game commits per-match counters (kills/uuid, clears, waves) →
  feeds quests, worthiness, evolution takedowns

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
  Still 🔲: UnitIcon formalised as a kit controller, UnitHoverCard, RewardPopup, CurrencyBar,
  ViewportPreview, NPCPrompt; promotion of the kit to `shared/src` (A7).
- 🟡 Hotbar rebuilt on kit (lobby — glow + hover preview via one controller, 2026-07-31; game 🔲)
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
- ✅ **`GetCollection` compat fields deleted (A6b)** — zero readers re-confirmed first;
  `GetUnitViews.Items` reviewed and kept as-is. 🔲 **Retire `GetCollection` entirely at A7**
  (handler + RemoteFunction) per `docs/decisions/ADR-0004-retire-getcollection.md`.

### Phase B — Gacha
- 🔲 Banner engine: one config file per banner (auto-scanned); Standard (3 mythics/hour,
  deterministic rotation), Selection (player-chosen featured, 24h lock, +2 daily
  randoms), Event (EventTokens, start/end, drop-in file per update)
- 🔲 Rates + pity (config: 0/50 leg, 0/400 mythic, 0/15000 secret ~0.005%; per-banner-type
  counters in profile; carry across rotations; luck-multiplier hook)
- 🔲 Shiny on summon + trait-on-summon (trait rarity table applies)
- 🔲 Summon UX: x1/x10, skip toggle, rarity reveal; Summon NPC + teleport button
- 🔲 Unit Index/Codex: all units, obtained silhouettes, sources, full rates disclosure

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
