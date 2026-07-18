# BLUEPRINT — Phase A: Foundations (schema v2, catalog, icon kit)
<!-- owner: AD-Game (schema/teleport/resolver) + AD-UI (kit/screens) | scope: global -->
<!-- status: READY TO IMPLEMENT | blueprints are LAW: deviations require docs/proposals/ -->

Rules for the implementing chat: do NOT redesign anything here. If something is ambiguous
or won't work, STOP and write a proposal — never improvise a different shape. Implement
ONE session-task (§9) per session. Copy the style of existing modules (ProfileTemplate,
StageRegistry, TowerConfigRegistry are the reference patterns). Verify with [DIAG] before
landing. UI = real Instances + Visible=false templates per the constitution rule.

## 1. Schema v2 (ProfileTemplate — SCHEMA_VERSION = 2)

```luau
Data = {
	SchemaVersion = 2,
	PlayerXP = 0, PlayerLevel = 1,
	Currencies = { Gold = 0, Silver = 0, TraitRerolls = 0, StatRerolls = 0,
		EventTokens = {} },              -- { [eventId]: count }
	Items = {},                          -- { [itemId]: count } caps via ItemCatalog.MaxOwned
	Units = {},                          -- { [uuid]: UnitInstance } (see below)
	Loadout = {},                        -- { uuid } max 6 (slot gating by PlayerLevel)
	Pity = {},                           -- { [bannerTypeId]: { Legendary=0, Mythic=0, Secret=0 } }
	Counters = { Global = {}, PerUnit = {} }, -- Global: {Clears=0, Summons=0, ...}; PerUnit: {[uuid]={Kills=0}}
	Quests = { Progress = {}, Claimed = {}, PinnedQuestId = nil },
	LoginStreak = { Day = 0, LastClaimDayNumber = 0 },
	ShopStock = { DayNumber = 0, Bought = {} }, -- auto-resets when DayNumber changes
	Titles = { Owned = {}, Equipped = nil },
	Spirits = {},                        -- { [uuid]: { SpiritId, ObtainedAt } }
	Battlepass = { SeasonId = "", XP = 0, Owned = false, ClaimedFree = {}, ClaimedPaid = {} },
	Settings = {},
}

UnitInstance = {
	TowerId: string, MetaLevel: number, XP: number,
	Trait: string?, Shiny: boolean,
	StatRolls: { DMG: number, RNG: number, SPA: number }, -- each 0..1 position in range
	Ascension: number,        -- 0..3, Mythic+ only (AscensionConfig)
	Worthiness: number,       -- 0..100
	Locked: boolean, Favorited: boolean,
	SpiritUuid: string?, ObtainedAt: number,
}
```

uuid = `HttpService:GenerateGUID(false)`. JSON-safe only (no mixed tables).

**Migration 1→2** (`Migrations[1]`), exact steps:
1. `Currencies = { Gold = data.Currency or 0, Silver = 0, TraitRerolls = 0, StatRerolls = 0, EventTokens = {} }`; `data.Currency = nil`.
2. For each `towerId, rec` in old `data.Towers`: create uuid → `Units[uuid] = { TowerId = towerId, MetaLevel = rec.MetaLevel or 1, XP = rec.XP or 0, Trait = rec.Trait, Shiny = false, StatRolls = { DMG = 0.5, RNG = 0.5, SPA = 0.5 }, Ascension = 0, Worthiness = 0, Locked = false, Favorited = false, SpiritUuid = nil, ObtainedAt = os.time() }`. Then `data.Towers = nil`.
3. `Loadout = {}` (auto-loadout rebuilds it). All other new keys come from Reconcile().
4. Template `Towers` key is REMOVED from the template (starter choice covers new players —
   fold the open starter-seed PENDING into this same change if still open).

**Ripple (same phase, Game place):** `PlayerInventoryService` API moves from towerId-keyed
to uuid-keyed: keep `Owns(userId, towerId)` (any instance), add `GetUnit(userId, uuid)`,
`GetAllUnits`, `GrantUnit(userId, towerId, opts) -> uuid`. `LoadoutValidator` validates
uuid lists (ownership + PlayerLevel slot count + no duplicate uuid; then resolves each to
TowerId + effective stats). `RewardCalculator`/`MatchStatsTracker` key tower XP by uuid.
`AddTowerXP(userId, uuid, xp)`. DevSetOwnedTowers seeds instances (mid rolls).

## 2. Teleport contract v2 (owner: AD-Lobby; land only AFTER schema v2 in both Places)

Only change: `Players[uid].Loadout = { uuid, ... }` (was towerIds); `PayloadVersion = 2`.
Game's `MatchEntryService` accepts v2; reject v1 with a `[CONTRACT]` warn (both Places
deploy within one Integration session, so no dual-version window is needed).

## 3. Config modules (all in `RS.Configs.Meta/`, Game place canon, mirrored to Lobby via
shared/src when Lobby needs them — promote to shared canon at first Lobby use)

```luau
-- TierConfig
Order = { "Common","Rare","Epic","Legendary","Mythic","Secret","Exclusive","Bathala" }
Tiers = { Common = { Color = Color3..., SortOrder = 1 }, ... }  -- border style key later
-- StatGradeConfig  (roll = 0..1; grade from thresholds, ascending)
Grades = { {Name="D",Max=0.40,Color=...}, {Name="C",Max=0.65}, {Name="B",Max=0.82},
  {Name="A",Max=0.92}, {Name="S",Max=0.975}, {Name="SS",Max=0.995},
  {Name="SSS",Max=0.9995}, {Name="Apex",Max=1.0} }  -- tune freely; order is law
RollStat = function(rng, luck) ...  -- uniform 0..1 for now; luck reserved
-- AscensionConfig
MaxLevel = 3; MinTier = "Mythic"
Levels = { [1]={Cost={Dupes=1,Items={...}},Mults={DMG=1.05}}, [2]={...,{DMG=1.5}}, [3]={...,{DMG=3}} }
-- per-tower override table allowed: PerTower = { [towerId] = {Levels={...}} }
```

**ItemCatalog** (`RS.Configs.Meta.ItemCatalog`): `{ [id] = { Kind = "Tower"|"Item"|
"Currency"|"Spirit"|"Title"|"Skin", Tier, Name, Description, Icon = { Image = assetId }
| { Model = {"TowerModels","Archer"} }, MaxOwned?, Tradeable = false, FeedValue?,
EventId? } }` + `ItemCatalog.Validate()` (asserts every Tower entry has a TowerConfig,
every icon resolves; run from a `[Test]` script at boot in Studio).

Tier assignment for existing towers (starting point, user-tunable): Archer/Knight Common,
Mage Rare, Babaylan Epic, Farm Rare, Meteor Legendary, Warchief Legendary,
Necromancer Mythic.

## 4. Base-stat ranges + resolver (Game)

Tower configs gain `BaseStats = { DMG = {Min,Max}, RNG = {Min,Max}, SPA = {Min,Max} }`.
Legacy configs keep scalar fields → loader treats scalar `x` as `{Min=x, Max=x}` (no
config rewrite required on day one). `TowerStatResolver`:
`base = Min + (Max-Min)*StatRolls[stat]`, then `* AscensionMult(stat)`, then the EXISTING
meta-level/trait/tier pipeline unchanged. SPA note: lower is better — roll 1.0 must map
to Min (best); use `base = Max - (Max-Min)*roll` for SPA only. Add a `[Test]` harness
print comparing old vs new outputs on a mid-roll unit (must be identical for scalar
configs with roll 0.5 — that's the regression check).

## 5. Icon kit (AD-UI; templates in `ReplicatedStorage.UITemplates.Kit/`, controllers in
`ReplicatedStorage.Shared.UIKit/` — client modules, shared canon once Lobby uses them)

Templates (real Instances, Visible=false; user-editable design; controllers only clone/
fill/wire): `UnitIcon` (ViewportFrame + LevelBadge TL + CostLabel BM + ElementStack TR +
TraitBadge TR + ShinyBadge + TierBorder frame), `ItemIcon` (ImageLabel + QtyBadge +
TierBorder), `UnitHoverCard` (name, tier, element, trait, level+progress bar, grades
D..Apex per stat, placement limit), `ItemHoverCard` (name, tier, description, owned x/max),
`RewardPopup` (dark overlay + grid + `RewardItemTemplate`), `FilterPanel` (GroupTemplate +
ToggleTemplate + Apply/Reset/Cancel), `ViewportPreview`, `CurrencyBar`, `NPCPrompt`.

Controller API (each returns a handle): `UIKit.UnitIcon.Create(parent, unitView) ->
{ SetSelected, Destroy, Instance }`, `UIKit.ItemIcon.Create(parent, itemId, qty)`,
`UIKit.RewardPopup.Show(rewards: {catalogId|unitView})`, `UIKit.Hover.Attach(icon, view)`.
`unitView` = server-built plain table (uuid, TowerId, name, tier, level, xp pct, trait,
shiny, grades, cost, elements) — clients NEVER read profiles directly; LobbyServices/
match remotes serve views. Viewport idle anim: clone display rig, AnimationController,
play idle if id present else static pose (tolerate nil — same rule as RigAnimator).

## 6. Counters pipeline (Game → profile; feeds C/D phases)

`Counters.Global` increments: match end (Clears, ClearsByStage[stageId], Waves), summon
service (Summons). `Counters.PerUnit[uuid].Kills` += at match end from MatchStatsTracker
(NOT live per-kill — one commit at match end keeps saves small). Worthiness += config
points per kill at the same commit, capped 100.

## 7. What does NOT change in Phase A

MatchDirector, WaveDirector, combat, economy-in-match, settings, party/teleport delivery
mechanics (only the Loadout payload type), the shared data layer (ProfileStore/
PlayerDataService untouched except template).

## 8. Acceptance for the WHOLE phase

Fresh profile (dev store): starter picker → unit instance with rolls; hotbar + units +
items screens all render through the kit; match plays with resolver stats; match end
commits XP/counters/worthiness by uuid; old v1 dev profile migrates cleanly ([DATA] logs
v1→v2, all towers present as instances); drift check green in BOTH Places.

## 9. Session plan (one per session; owner in brackets; land + advisory each time)

- **A1 [AD-Game]** Schema v2 + migration + template starter-seed removal + PlayerInventoryService/LoadoutValidator/Reward/Stats uuid refactor + DevSeed update. Verify migration on a v1 dev profile. (Biggest session; if it strains, split A1a schema+migration / A1b service refactor.)
- **A2 [AD-Integration]** Deploy ProfileTemplate v2 to Lobby; Lobby-side compile fixes (LobbyServices/PartyService read Units+Loadout); teleport v2 flip both sides; e2e in Studio + live.
- **A3 [AD-Game]** TierConfig + StatGradeConfig + AscensionConfig + ItemCatalog + Validate + tier assignment + BaseStats ranges on 2 pilot towers + TowerStatResolver change + regression harness.
- **A4 [AD-UI]** Kit templates + UnitIcon/ItemIcon/Hover controllers in the LOBBY place first (view-model remotes in LobbyServices). Static icons OK; viewport anim last.
- **A5 [AD-UI]** Units screen + Items screen rebuilt on kit (+FilterPanel). Convert legacy CollectionScreen per the convert-on-touch rule.
- **A6 [AD-UI]** Hotbar rebuild on kit in GAME place (+ lobby hotbar mirror) + RewardPopup + CurrencyBar.
- **A7 [AD-Integration]** Full-phase acceptance (§8), promote kit/config modules used by both Places into shared/src + manifest, ROADMAP flips, republish both Places (USER).
