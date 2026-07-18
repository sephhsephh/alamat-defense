# BLUEPRINT — Phases B–F: meta systems (compact specs)
<!-- owner: per-phase (OWNERSHIP.md) | scope: global | blueprints are LAW: deviate only via proposal -->
<!-- Prereq: Phase A landed (docs/blueprints/phase-a-foundations.md). Implement one session-task at a time. -->

Shared algorithms used everywhere (implement ONCE in Phase B, module `Shared.MetaMath`):
- **Deterministic slot:** `slot(period, offsetSec) = math.floor((os.time() + offsetSec) / period)`;
  seeded picks: `Random.new(slot)` → same result on every server, no MessagingService.
  Config: `MetaConfig.ResetOffsetSec` (your "8am PST" knob, one number).
- **Weighted roll:** `pick(rng, {{v=x,w=n},...})` — used by tiers, featured, traits.
- **Grant pipeline:** ONE server function `GrantService.Grant(userId, grants)` where
  `grants = { {Id=catalogId, Qty=n} | {TowerId=..., opts} }` — checks MaxOwned caps,
  routes Tower→GrantUnit / Item→Items / Currency→Currencies / Title/Spirit accordingly,
  returns granted views for RewardPopup. EVERY system (summons, quests, login, shop, BP,
  codes, drops) grants through this ONE function. Never grant inline.

## Phase B — Gacha [AD-Gacha; home Lobby]

`RS.Configs.Banners/` one module per banner, auto-scanned registry (pattern: MapConfigRegistry):
`{ Id, BannerType = "Standard"|"Selection"|"Event", Currency = "Gold"|{Event=id},
CostPerPull, Pool = { [tier] = {towerIds} } | "AllSummonable", Rates = { [tier] = weight },
Featured = { Count=3, RotationPeriod=3600, Boost=mult } | { PlayerChoice=true,
ChoiceCooldown=86400, AutoCount=2, AutoRotation=86400 }, PityRef = "Default",
Window = {StartUtc?, EndUtc?}, LuckMult = 1 }`. `PityConfig.Default = { Legendary=50,
Mythic=400, Secret=15000 }`. Secret weight ≈ 0.00005 (~0.005%); secrets excluded from Featured.

**Summon algorithm (server, exact order):** validate currency+window → spend →
roll tier (weights × luck) → pity override check (Secret then Mythic then Legendary: if
counter+1 ≥ threshold and rolled tier is lower, upgrade to that tier) → pick unit in tier
(featured get ×Boost weight; Selection banner: player's stored choice from
`profile.Quests`-style field `BannerChoices[bannerId] = {TowerId, ChosenAtDay}`) → roll
Shiny (`GachaConfig.ShinyChance`) → roll trait-on-summon (`TraitOnSummonChance` then the
existing trait rarity table) → roll StatRolls via StatGradeConfig → `GrantService` →
update pity (reset hit tier's counter, increment others) → increment `Counters.Global.Summons`.
x10 = loop of 10 in one remote call, one RewardPopup. All RNG server-side; client gets views.

UI: Summon NPC (NPCPrompt) + teleport button; banner carousel screen (config-driven);
x1/x10, skip-anim toggle (Settings); rarity flash colors from TierConfig. **Index/Codex
screen:** iterate ItemCatalog Towers → obtained silhouettes (own any instance), source
text, exact per-banner rates table (computed from configs, not hand-written).

Sessions: B1 MetaMath+GrantService+PityConfig · B2 banner registry+summon service+[Test]
odds harness (10k dry rolls, assert distribution) · B3 summon UI+RewardPopup wiring ·
B4 Selection banner choice flow + Event banner window · B5 Index/Codex.

## Phase C — Unit depth [AD-Traits rerolls/worthiness; AD-Gacha ascension; home Lobby]

- **Trait reroll:** NPC → UI (unit picker = UnitIcon grid; filter panel = trait toggles;
  Reroll button hold-to-repeat ~4/s; if current trait is toggled-protected → confirm
  popup; AUTO-STOP the instant a protected trait is rolled; index tab = odds from trait
  config). Server: spend `Currencies.TraitRerolls`, roll trait table, write instance.
- **Stat reroll:** NPC → UI (unit picker; shows current grades D..Apex per stat with
  colors; reroll spends `StatRerolls`, rerolls all three StatRolls; Worthiness meter shown;
  at Worthiness==100: floor each roll at the "A" threshold + `TopGradeBoost` luck mult;
  ANY reroll sets Worthiness=0). Letter derivation + colors: StatGradeConfig only.
- **Ascension:** UI in Units screen detail pane (Mythic+ only): shows next level cost
  (1 dupe of same TowerId — pick oldest unlocked unfavorited automatically, show it,
  require confirm — + items + Silver via AscensionConfig); consumes dupe instance;
  `Ascension += 1`. Sell-dupes flow: multi-select in Units screen → Silver by tier
  (`SellValueByTier` in TierConfig); Locked/Favorited/in-Loadout units unselectable.
- **Feeding:** Units detail pane: feed items with `FeedValue` (catalog) → `AddTowerXP`
  path (same level-up math as match XP); mass-feed slider; protections as above.

Sessions: C1 trait reroll svc+UI · C2 stat reroll svc+UI+worthiness commit check ·
C3 ascension+sell · C4 feeding.

## Phase D — Economy loops [AD-Meta; home Lobby unless noted]

- **Crafting:** `CraftingRecipes = { {Out={Id,Qty}, In={{Id,Qty},...}} }` (fragments→
  artifact 2:1, all-7-colors→Rainbow). UI = recipe list of ItemIcons + craft button.
- **Challenges [AD-Game]:** `ChallengeConfig.Daily = deterministic pick(slot(86400)) from
  a pool of {StageId, Modifiers={...}, Rewards}`; Modifiers reuse MatchModifiers (extend
  ClassicMode to apply: NoFarm, RangeMult, SpaMult, LivesCap...). Entry via Lobby stage
  select "Challenge" tab → normal teleport with `MatchModifiers`; completion counter →
  quests + artifact rewards via GrantService at match end.
- **Shop:** `ShopConfig = { {Id, Qty, PriceSilver, DailyStock} }`; profile `ShopStock`
  resets when `DayNumber ~= slot(86400)`. NPC + UI (ItemIcon grid, stock badges).
- **Daily login:** `LoginRewardsConfig = { [1..7] = grants }`; claim if
  `slot(86400) > LastClaimDayNumber`; Day cycles 1..7. UI popup on join + claim button.
- **Quests:** `QuestConfig = { [questId] = { Name, Repeat = "Once"|"Daily",
  Tasks = { {Counter="ClearsByStage.Stage1_Act1"|"Summons"|..., Target=n} }, Rewards } }`.
  Progress = snapshot Counters at accept/day-reset, delta vs now (NO per-task event
  wiring — counters are the single source). Pin: `PinnedQuestId` + tracker widget both
  Places (kit component). Daily quests re-roll at day slot.
- **Codes:** `CodesConfig = { [code] = { Rewards, ExpiresUtc? } }`; profile `RedeemedCodes`;
  settings-screen text box → server validate → GrantService.

Sessions: D1 crafting · D2 challenges (Game side) · D3 shop · D4 login+codes · D5 quests+pin tracker.

## Phase E — Seasonal & presentation [AD-Meta]

- **Battlepass:** `Configs/Battlepass/Season1.luau` = { SeasonId, XPPerTier, Tiers[1..50] =
  {Free=grants, Paid=grants} }; BP XP granted at match-end commit (rule in config:
  f(waves, outcome)); paid flag via gamepass/dev product; level-skip products (5/10/50);
  UI: track view with ItemIcons, claim buttons, XP bar. Season rollover = new file +
  SeasonId switch (old claims keyed by SeasonId — no wipe needed).
- **Event framework:** `Configs/Events/<EventId>.luau` = { Window, TokenId, Banner?,
  Quests?, ShopEntries? } — the banner/quests/shop systems all accept an optional EventId
  filter; "add an event" = one config file (your one-file-per-update goal).
- **News board:** `NewsConfig` list (title, body, image, banner showcase ref) + on-join
  popup with "don't show again this slot".
- **Titles:** equip UI in profile screen; overhead BillboardGui (both Places, kit
  template). **Skins:** catalog Kind="Skin" → `SkinsConfig = { [skinId] = {TowerId,
  ModelPath} }`; equipped per-unit (`SkinId` field, additive schema change v2→v3 via
  Reconcile only — no migration needed for optional additive keys, still bump version).

Sessions: E1 BP · E2 event framework (retro-fit banner/quests/shop filters) · E3 news +
titles · E4 skins (+model swap in TowerManager/Lobby preview).

## Phase F — Endgame & social

- **Evolution [AD-Gacha]:** `Configs/Evolutions/<TowerId>.luau` = { Requires = {
  Items={{Id,Qty}}, Counters={PerUnitKills=n}, Silver=n }, ResultTowerId } (result =
  REAL tower config, Bathala tier). Consumes unit → grants result instance PRESERVING
  Trait/Shiny/StatRolls/Worthiness/Ascension. Per-act rare drops (e.g. Necromancer's
  Cloak 0.1% w/ 0/20 pity) live in stage config drop tables with per-drop pity counters
  in `Counters.Global.DropPity[itemId]`.
- **Spirits [AD-Gacha]:** `SpiritConfig = { [SpiritId] = {Name, Tier, StatMults, PassiveId?} }`;
  attach/detach in Units pane; Game resolver applies mults after Ascension mults.
- **Endless [AD-Game]:** new GameMode (the interface exists): generated waves f(index),
  no win condition, leaderboard commit at defeat. **Leaderboards:** OrderedDataStore
  (separate `_Dev` suffix rule!), top-100 boards (EndlessWaves, Summons, PlayerLevel),
  lobby board UI; write on relevant commits, read cached 60s.
- **AFK rewards [AD-Meta]:** lobby AFK zone → Silver/min capped; **Team presets:** 3 saved
  Loadout arrays in profile; **Group/like rewards:** one-time grants gated on
  GroupService check.
- **Monetization [AD-Meta]:** MonetizationConfig expansion (VIP, x2XP, LuckPass, gold
  dev-products); ProcessReceipt in ONE `PurchaseService` (Lobby) granting via
  GrantService; idempotent receipt handling (store ReceiptIds in profile).

Sessions: F1 evolution · F2 spirits · F3 endless+leaderboards · F4 AFK/presets/social ·
F5 monetization.

## Cross-phase invariants (checked at every Integration session)

1. Every grant flows through GrantService (grep for direct `Currencies.` writes outside it).
2. Every icon renders through the kit (no ad-hoc ImageLabels for items/units).
3. Every reset/rotation uses MetaMath.slot (no os.date math anywhere else).
4. Every new grantable id exists in ItemCatalog (Validate() in the [Test] boot).
5. Schema changes: additive-optional keys = Reconcile + version bump; shape changes =
   migration step. Never both Places out of schema sync across a session boundary.
