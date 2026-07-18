# Proposal: Meta-systems design (gacha, evolution, rerolls, quests, BP, lobby UI)
<!-- status: APPROVED 2026-07-18 (decisions below) — folded into ROADMAP.md -->
<!-- source: user design brief 2026-07-18 + AD-Game review -->

## 0. The two architectural decisions everything else depends on

### 0.1 Unit INSTANCES, not unit IDs (schema v2 — biggest change)

Shiny, per-unit stat grades, worthiness, and "towers can't stack" all mean a player can
own several copies of the same tower with different rolls. The current schema
(`Towers = { [towerId]: {...} }`) cannot represent that. Schema v2 must key units by UUID:

```luau
Units = { [uuid]: {
	TowerId: string,        -- "Necromancer"
	MetaLevel: number, XP: number,
	Trait: string?,
	Shiny: boolean,
	StatGrades: { DMG: number, RNG: number, SPA: number }, -- roll % (grade letter derived)
	Worthiness: number,     -- 0..100, resets on stat reroll
	Locked: boolean, Favorited: boolean,
	SpiritUuid: string?,    -- attached spirit
	ObtainedAt: number,
} }
Loadout = { uuid, ... }     -- up to 6, gated by PlayerLevel slots
```

Also in v2: `Currencies = { Gold, Silver, TraitRerolls, StatRerolls, EventTokens = {...} }`
(migrating the single `Currency` field), `PlayerLevel/PlayerXP`, `Pity = { [bannerType]: n }`,
`Quests`, `LoginStreak`, `ShopStock`, `Titles/EquippedTitle`, `Spirits`, `BattlepassXP/Tier`,
`Counters` (takedowns per tower id, clears, summons — feeds quests/evolution/worthiness).
**This migration must land before ANY gacha work.** One migration step, heavily tested on
the dev store.

### 0.2 One ItemCatalog + one icon component library (the reuse you asked for)

A single registry, `Configs/ItemCatalog`, describes EVERY grantable thing once:
`{ Id, Kind = "Tower"|"Item"|"Currency"|"Spirit"|"Title"|"Skin", Tier, Name, Description,
Icon = { Image = assetId } | { Model = path (viewport) }, MaxOwned?, Tradeable? }`.

Then a shared UI kit (owner: AD-UI; used by hotbar, unit inventory, item inventory, shop,
quests, battlepass, summon results, obtainment popup — ALL of them):

- `UnitIcon` — viewport preview playing idle anim, tier-colored border (swappable for
  your future animated borders), level top-left, cost bottom-center, element+trait stack
  top-right, shiny sparkle badge, hover → `UnitHoverCard`.
- `ItemIcon` — image, qty badge, tier border, hover → `ItemHoverCard` (name, tier,
  description, owned x/max).
- `HoverCard` (two variants above), `RewardPopup` (the darkened-background obtainment
  grid — one component reused by summons/claims/drops), `FilterPanel` (config-driven
  toggle groups + Apply/Reset/Cancel), `ViewportPreview` (the big inspect pane),
  `CurrencyBar`, `NPCPrompt` (ProximityPrompt → opens a registered UI).

Rule: **no system builds its own icon**. If a screen needs an icon it calls the kit with
a catalog id. Unit inventory and item inventory stay separate SCREENS but share the kit.

### 0.3 Deterministic rotation (no cross-server sync needed)

Hourly standard-banner rotation, daily shop stock, daily selection-banner randoms, login
reset: derive from `os.time()` → hour/day number → seeded RNG → same result on EVERY
server, no MessagingService. Reset boundary = config (`ResetOffsetHours`, default = 8am
PST equivalent, stored as UTC offset).

## 1. Per-system review (your spec + improvements)

**Tiers.** Ladder: Common, Rare, Epic, Legendary, Mythic, Secret, Exclusive, and for the
evolution-only apex tier: **"Bathala"** (supreme deity of Filipino myth — on-theme, reads
as above everything; alternatives: Diwata, Anito). Assign tiers to the existing 8 towers
as part of this work. Tier → border color/gradient in one `TierConfig` (your animated
borders drop in later).

**Banners.** Your three types are genre-correct. Make `Configs/Banners/` a folder of
config modules — one file per banner (`Standard.luau`, `Selection.luau`,
`Event_PreRelease.luau`); adding an event banner = add one file (auto-scanned registry,
same pattern as maps). Each: pool (by tier or explicit ids), rates table, featured logic,
rotation schedule, currency, pity table ref, start/end time (event banners expire
automatically). Suggestions you didn't spec: **x1/x10 summon** with skip-animation
toggle; rarity-reveal flash colors; per-banner AND global "luck multiplier" hook (for 2x
luck weekends — trivial now, painful later); secret odds as config (0.005 = 0.5% is very
high for a "secret" — genre secrets sit near 0.004–0.01%; your call, it's one number).
Pity: per-banner-type counters stored in profile, carry across rotations within the same
banner type, reset on hitting the tier; all thresholds in one `PityConfig`.

**Roll-with-trait + shiny.** Both are just post-roll modifiers in the summon service:
`ShinyChance`, `TraitOnSummonChance` (then normal trait rarity table applies). One config.

**Evolution.** Recipe-driven: `Configs/Evolutions/<TowerId>.luau` = list of requirements
(catalog item + qty, counters like Takedowns via `Counters`, currency) + result
(`TowerId .. "_Awakened"` as a REAL tower config in the Game place with its own stats/
passives/tiers). Evolution consumes the unit instance and grants a new instance,
**preserving Trait/Shiny/StatGrades/Worthiness** (spec this explicitly — players riot
otherwise). Locked units can't be consumed as materials.

**Currencies.** Good split. Add now (cheap): `EventTokens` as a MAP keyed by event id —
"Pre-Release Tokens" is just `EventTokens.PreRelease`, and every future event reuses the
system. Gold/Silver stay top-level.

**Crafting.** Fine as spec'd. Put recipes in `Configs/CraftingRecipes.luau` (input ids +
qty → output id + qty); caps live in ItemCatalog `MaxOwned`. Craft UI = same kit icons.
Missing piece you referenced but didn't spec: **Challenges** (artifact obtainment says
"Challenges") — see §2.

**Trait reroll.** Spec is complete and good (filter-protect + confirm, hold-to-reroll,
index with odds, viewport select). One addition: an **auto-stop on filtered trait** while
holding (stop the instant a protected trait lands) — this is the genre-standard QoL.

**Stat reroll.** Grades: recommend `D C B A S SS` + apex symbol **"Bathala grade"** (or a
sun glyph) instead of Z-above-A (Z between A and top reads confusingly; if you want Z,
put it as the apex). Grade = derived from roll % ranges in one `StatGradeConfig`
(ranges, odds, colors). Worthiness: great original hook — also show it on the unit hover
card, and track kills into it Game-side via match-end commit (`Counters` per uuid).

**Exp food / feeding.** Per-stage food items via ItemCatalog + `FeedValue`; feeding UI in
the Units screen (mass-feed with locked/favorited protection). Note: tower XP from
matches already exists — feeding is a second input to the SAME `MetaLevel/XP` fields.

**Player level / slots.** Slots 3→6 at levels 10/20/30 — enforce Game-side in
`LoadoutValidator` (server-trusted, from profile PlayerLevel). `LevelRewardsConfig` for
milestone claims.

**Daily login.** 7-day repeating cycle, `LoginRewardsConfig`, deterministic day boundary
(§0.3). Track `LoginStreak + LastClaimDay` in profile.

**Quests.** Config-driven quest defs (`QuestConfig`: id, tasks [counter key + target],
rewards, repeat = daily/once). Progress = read `Counters` deltas — the SAME counter
pipeline worthiness and evolution takedowns use (build the counter system once). Pinned
quest id in profile; pinned tracker widget in both Places (shared kit component).

**Shop.** Per-player daily stock in profile (`ShopStock` keyed by day number — auto
resets by key change, no timers), `ShopConfig` for items/prices/stock. Same icon kit.

**Spirits.** Fine as v1: spirit instances in profile, attach = `SpiritUuid` on a unit,
stat boosts + optional passive id resolved Game-side at match load. Keep obtainment
(specific acts) in stage configs' drop tables.

**Battlepass.** `Configs/Battlepass/Season1.luau` (seasonal file = your "easily
modifiable"): 50 tiers, free/paid tracks, xp-per-match rule, level-skip products.
BP XP committed at match end alongside rewards.

**Lobby UI shell.** Left/bottom button rail: Store, Units, Items, Quests, Battlepass,
Index (see §2), Settings + NPC-teleport buttons (Summon, Evolve, Trait, Stat, Shop).
Hotbar spec as you wrote (viewport idle anim, tier border, level, cost, element/trait
stack, hover card) — all from the §0.2 kit, so the SAME icon appears in hotbar, units
screen, and summon results.

## 2. What you're missing (vs. current anime-TD chart games)

1. **Unit Index / Codex** — every tower, obtained-or-not silhouettes, obtainment source,
   full rates disclosure. (Also satisfies Roblox's paid-random-item odds-disclosure
   expectations once Robux touches summon currency.) You spec'd an index for traits only.
2. **Challenges** — you reference them as an obtainment source but never spec them.
   Rotating daily challenge (fixed stage + modifiers, e.g. "no Farm, x0.5 range") with
   artifact rewards. This closes your crafting loop.
3. **Endless mode + leaderboards** — endless is enum'd but unbuilt; your daily quest
   "reach wave 25 on endless" depends on it. Global leaderboards (endless waves, summons,
   level) are a core retention feature in every chart game.
4. **Dupe handling** — with unit instances, decide dupes' purpose: genre standard is a
   limit-break/"potential" system (consume dupes of the same TowerId to push max level or
   small stat bumps) plus mass-sell for Silver. Without this, inventories silt up fast.
5. **Codes system** — promo codes (`CodesConfig`: code → rewards, expiry, one-per-player).
   Standard growth lever, trivial to build on the grant pipeline.
6. **AFK rewards** — AFK chamber or offline-time trickle (Gold/Silver). Cheap retention.
7. **Skins & Titles as systems** — you award them (BP, quests) but there's no equip/
   render spec. Titles: profile list + equipped + overhead billboard. Skins: catalog
   entries mapping TowerId → alt model/texture, applied at spawn in both Places.
8. **Team presets** — 2–3 saved loadouts, one tap to swap. Small, loved.
9. **Match QoL flags** — auto-replay vote, auto-next-act, auto-use-ability toggles
   already exist; surface them as a "match settings" panel.
10. **News/update board + rotating banner showcase on join** — where you advertise the
    current event banner; pairs with your "easily modifiable every update" goal.
11. **Group/social rewards** — Roblox group membership bonus, like-milestone rewards.
12. **VIP / luck / x2 XP gamepasses + Robux gold packs** — your Store button needs a
    `MonetizationConfig` expansion; wire through the existing purchase-path debt item.
13. **Trading** — keep 💭 (you already have it) but decide NOW which things are
    `Tradeable` in ItemCatalog, because retrofitting untradeable flags after launch is a
    balance disaster. Ship v1 with everything untradeable.

## 3. Cross-Place contract impact (what must be coordinated)

- **Save schema v2** (owner AD-Game): §0.1. One migration. Everything above waits on it.
- **Counters pipeline** (new contract): Game commits per-match counters (kills per uuid,
  clears, waves, summons happen Lobby-side) → quests/worthiness/evolution read them.
- **ItemCatalog + TierConfig + StatGradeConfig + kit components** become shared canon
  (`shared/src/`) — both Places render the same icons.
- **Tower configs gain Tier** (+ future `_Awakened` configs, skins map) — Game canon.
- Teleport contract: unchanged (loadout of uuids replaces loadout of towerIds → that IS
  a payload change → teleport v2 alongside schema v2).

## 4. Suggested build order (each phase playable/testable)

- **A. Foundations:** schema v2 (unit instances + currencies + counters) + ItemCatalog +
  TierConfig + icon kit (hotbar + units screen rebuilt on it). ← unblocks everything
- **B. Gacha:** banner configs + summon service + pity + shiny/trait-on-roll + summon UX
  + obtainment popup + unit index w/ rates.
- **C. Unit depth:** trait reroll NPC/UI, stat reroll + worthiness, feeding, dupes
  (limit-break/sell), locks.
- **D. Economy loops:** crafting + challenges + shop + daily login + quests/pins + codes.
- **E. Seasonal:** battlepass + event banner/event tokens + news board + titles/skins.
- **F. Endgame/social:** evolution + spirits + endless + leaderboards + AFK + monetization
  store. (Evolution sits here because it needs challenges/crafting/counters mature.)

## 5. Decisions (RESOLVED 2026-07-18)

1. Apex tier name: **Bathala** (evolution-only, above Exclusive).
2. Secret rate: **~0.005%** (config), 0/15000 pity.
3. Dupes: **"Ascension" system** — ascending a unit consumes 1 duplicate of that unit +
   artifact materials; dupes can also be sold for Silver. (Replaces the generic
   limit-break idea; spec Ascension effects per tier — stat cap raise / bonus.)
4. Stat grade ladder: **D C B A S SS SSS + Apex** (Apex = themed top grade; odds per
   grade in StatGradeConfig).
5. Tradeable flags: everything `Tradeable = false` at launch (default assumption; flip
   per-item when trading ships).
