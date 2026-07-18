# ROADMAP — feature status for the whole Experience
<!-- owner: all (any chat updates its own system's rows at landing) | scope: global -->
<!-- last-verified: 2026-07-18 -->

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
- 🟡 First-join starter tower choice (built + verified 2026-07-18; INERT until AD-Game
  removes the ProfileTemplate starter seed — proposal 2026-07-18)
- 🟡 v1: parties (in-memory, single-server; cross-server/persisted = later phase)
- 🔲 Loadout picker UI (player chooses their 6; replaces auto-loadout)

## Cross-Place

- ✅ Save schema v1 shared + deployed to both Places
- ✅ Teleport handoff: contract v1 done BOTH sides + BOTH directions; config-complete
  (both place ids set) and LIVE-verified in the production client (user, 2026-07-18)
- ✅ Game-side production entry: TeleportData.MatchLaunch → StartMatch (`MatchEntryService`)
- ✅ Game→Lobby return: `ReturnToLobby` builds `MatchReturn` v1 + teleports (guarded on LobbyPlaceId)
- ✅ First e2e run: lobby → reserved match → return → banner (Integration session in Studio
  2026-07-18 + user's live production run same day)
- 🔲 **Schema v2**: unit INSTANCES (uuid: TowerId/Trait/Shiny/StatRolls/Ascension/
  Worthiness/Locked/Spirit), Currencies map (Gold/Silver/rerolls/EventTokens), PlayerLevel, Pity,
  Quests, LoginStreak, ShopStock, Titles, Spirits, BP, Counters — one migration, tested
  on dev store. **Gates all meta phases below.** Teleport v2 (uuid loadouts) rides along.
- 🔲 Counters pipeline: Game commits per-match counters (kills/uuid, clears, waves) →
  feeds quests, worthiness, evolution takedowns

## Meta-systems (phased; each phase ships playable)

**IMPLEMENTATION BLUEPRINTS (read before building anything below — they are law):**
Phase A: `docs/blueprints/phase-a-foundations.md` (schema v2 exact shape, migration,
catalog/configs, icon kit, session plan A1–A7). Phases B–F:
`docs/blueprints/phases-b-f-meta.md` (algorithms, config shapes, session plans, invariants).

### Phase A — Foundations (first; everything depends on it)
- 🔲 Schema v2 + teleport v2 (above)
- 🔲 ItemCatalog registry (every grantable: towers/items/currencies/spirits/titles/skins;
  icon ref, tier, description, MaxOwned, Tradeable=false)
- 🔲 TierConfig (Common→Legendary→Mythic→Secret→Exclusive→**Bathala**; border colors,
  animated borders slot in later) + tier assignment for the existing 8 towers
- 🔲 Tower configs gain base-stat RANGES (DMG/RNG/SPA min–max) + TowerStatResolver reads
  rolled StatRolls × Ascension multiplier (Game canon change, part of schema v2 work)
- 🔲 Shared icon/UI kit (AD-UI): UnitIcon (viewport idle anim, tier border, level, cost,
  element/trait stack, shiny badge, hover card), ItemIcon, HoverCards, RewardPopup
  (obtainment grid), FilterPanel, ViewportPreview, CurrencyBar, NPCPrompt
- 🔲 Hotbar rebuilt on kit (lobby + game) · 🔲 Units screen + Items screen rebuilt on kit
  (separate screens, shared kit; filters: rarity/element/shiny/favorited/locked/trait)

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
