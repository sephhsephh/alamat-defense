# Doc index (one line each — read only what the task needs)

## root-level
- `OWNERSHIP.md` — system → owning chat → home Place → canon location (single-writer registry)
- `ROADMAP.md` — one-glance feature status board: done / partial / planned / ideas (all chats update)

## blueprints/ (implementation law for the meta systems — read before building)
- `phase-a-foundations.md` — schema v2 exact shape + migration, ItemCatalog, Tier/StatGrade/
  Ascension configs, base-stat ranges + resolver, icon kit, session plan A1–A7
- `phases-b-f-meta.md` — gacha/rerolls/economy/seasonal/endgame: algorithms (summon order,
  deterministic rotation, GrantService), config shapes, session plans, cross-phase invariants

- `playgui.md` — the PlayGUI main-menu → story-mode → lobby → launch flow: exact instance paths in
  the user's built `StarterGui.PlayGUI`, the loading screen, camera + parallax, transitions, reward
  scaling, the deferred matchmaking queue, and session tasks P1–P7 by owner chat. **Read §2 first —
  it lists the blockers that stop the screen being fillable at all.**

## contracts/
- `save-schema.md` — Profile data shape, versions, migration rules (owner: Game). **v5**
- `teleport.md` — Lobby→Game / Game→Lobby TeleportData payloads (owner: Lobby). **v2**

## design/
- `icon-art-style.md` — **THE icon art style** (B137): image-generator prompts — style lock (Block A), family modules (items / symbols / placement), one line per icon, consistency workflow. Reuse for every future icon batch.
- `unit-roster.md` — **B106 DRAFT, the unit roadmap**: 27 new Philippine-myth units per tier, balance bands, passive catalogue (C/P/S tags), evolved forms, new systems + build order, and the B106 renames of the 8 old towers.

## systems/
- `evolution.md` — **B106, AD-Gacha + AD-Game, BOTH Places**: evolved forms, the recipe registry (`Check` = the rule), `GrantService.EvolveUnit` (the write), the Evolve NPC screen, how to add a form.
- `tower-authoring.md` — **AD-Game canon, READ BEFORE ADDING A TOWER**: attack profiles, the hit list,
  the animation-marker contract, melee movement, five worked examples and the add-a-tower checklist (B78).
- `hotbar.md` — **AD-UI canon, BOTH Places**: the user's authored hotbar (B77) and the 9-tier palette it
  brought with it. Read before touching `TierConfig` colours or `UIKit.Hotbar`.
- `stage-info.md` — **AD-UI + AD-Game, GAME**: the B88 sectioned Stage Info — session vs profile lifetimes,
  the enemies-seen index (no schema bump), why enemy portraits are blank, and why there is no stage pity.
  **B89: it slides in from the right like the Unit Manager, and the two are mutually exclusive.**
- `unit-manager.md` — **AD-UI + AD-Game, GAME**: the B87 card grid — per-card lock / priority / sell,
  Auto Upgrade with its priority number, the targeting dropdown, and the Automation row (four saved
  SettingsConfig preferences, not match state). Read before touching Sell All or auto-upgrade order.
  **Also THE side-panel rules (B88/B89): a right-anchored panel's closed position is derived from its own
  width, and `SidePanelBus` keeps one panel open at a time. Read before adding a right-side panel.**
- `unit-selection.md` — **AD-UI + AD-Game, GAME**: the selected-unit panel (B86) — portrait viewport, current-to-next
  stat rows, the live combat tiles (and why DPS is theoretical while eDPS is measured), the clickable upgrade bar
  with its colour code and click-buys/hold-queues rule, and the shared tooltip system.
- `match-hud.md` — **AD-UI + AD-Game, GAME**: the B81 reference-layout match HUD (stat bar, wave banner, pinned quests,
  stage tag, Stage Info, placeholders), **Auto Play**, the no-building-on-`PathDesigns` rule, the placement ghost
  and the **boss health billboard** (B84, authored `RS.UITemplates.BossHealthbar`).
- `tower-vfx.md` — **AD-Game + art, GAME**: the per-tower VFX template tree (B82) — Release / Telegraph /
  Projectile / Impact per tower and per attack, the attach modes, the fallback order, and why Impact/Telegraph
  anchor at the target's FEET (B84). Read before authoring effects.
- `match-audio.md` — **AD-Game, GAME**: every match sound (B81) — wave tick, next wave, boss warning + boss BGM, kills,
  cash, placement — and the per-hit `ReleaseSound` / `Projectile.Sound` / `ImpactSound` attack sounds.
- `hud-currencies.md` — **AD-UI, LOBBY**: the configurable HUD currency bar (B76) — what may be pinned,
  the 3-slot cap, `HudCurrencyConfig`/`HudCurrencyService`, and why an item grant now pings `CurrencyChanged`.
- `match-end.md` — **AD-Game, GAME**: the B75 match-end item preview + results screen, the stats it reads, and
  Replay/Next as VOTES over the finished match's own config (`MatchEndVotes`). Read before touching `MatchActionHandler`.
- `rewards.md` — **AD-Game canon**: match-end payouts (P5, B18). `RewardCalculator`, the
  difficulty→gold curve in the SHARED `RewardScalingConfig`, why the curve is shared rather than
  per-`StageConfig`, and **the two difficulty scales** (UI 1–100 vs WIRE 100–1000, ADR-0011) —
  confusing them pays maximum gold for a normal match, silently. Also records that Insane is
  implemented but UNREACHABLE until teleport v3. Read before touching anything that pays a player.
- `ui-spacing.md` — **BOTH Places**: the B115 spacing rules (card margins, row gaps, 14 px grid gaps, button insets) + `tools/ui_breathing.luau`. Read before building any screen.
- `responsive-ui.md` — **BOTH Places**: B127 device scaling (device factor, FIT, `AD_ScaleGroup` / `AD_GroupPivot` / `AD_ScaleMax`), console + touch key hints (`KeyHint`, `GamepadHud` Y-cycling), the pad map, and the `UIAudit` / `UIPhonePreview` dev tools.
- `ui-kit.md` — **Place-NEUTRAL** AD-UI canon for the shared UI kit: 6 controllers
  (`RS.Shared.UIKit`, `shared/src` files) + 8 real instance templates (`RS.UITemplates.Kit`, the
  INSTANCE is canon per ADR-0005), the shared hotbar, the configs it depends on, and the rules
  that keep it healthy. Split out of `lobby-ui.md` at A7 once BOTH Places used the kit.
- `ascension.md` — **AD-Gacha canon**: dupe-fed ascension (blueprint C3, B9). The dupe-protection
  rules (locked/favourited/**equipped**, oldest-first), the server-enforced confirm, why
  `AscensionRules` is split from the service, and the one authorised line in `UnitsController`.
  Read before touching anything that destroys a player's unit.
- `trait-reroll.md` — **AD-Traits, LOBBY**: trait reroll (C1, B44). Cost is the `TraitRerollToken` ITEM (not `Currencies.TraitRerolls`). PRE-CHECK→SPEND→ROLL→WRITE. NPC-opened (ADR-0010).
- `unit-capacity.md` — **AD-Game (Lobby-local), LOBBY**: unit cap 200 +50 per 50k Silver (B72, schema v8). SUMMON-only refusal; other grants overflow. `BuyUnitSlots` + `GetUnitViews.UnitCapacity`.
- `stat-reroll.md` — **AD-Traits, LOBBY**: stat reroll (C2, B44). Rerolls all 3 StatRolls for `Currencies.StatRerolls` (sources: `economy-map.md`); Worthiness>=100 floors each roll at grade A + resets. NPC-opened.
- `economy-map.md` — **AD-Meta/AD-Gacha canon, LOBBY**: the faucet↔sink map for every spendable resource (Gold, Silver, TraitRerollToken, StatRerolls, EventTokens) — what grants each and what spends it, in one table. Read before any economy tuning. `Currencies.TraitRerolls` is documented-dead here.
- `leaderboards.md` — **AD-Meta/AD-Gacha canon, LOBBY**: the global top-N account-LEVEL board (B47). OrderedDataStore keyed by userId, published on ProfileLoaded (Lobby-only, no schema/Game change); `GetLeaderboard` remote + blockout screen. Read before touching the board or adding a ranked metric.
- `inbox.md` — **AD-Meta/AD-Gacha canon, LOBBY**: the stored message-history screen (B48, schema **v5**). `Data.Inbox` (NEW v5 field) + `InboxService` (one writer) + `GetInbox`/`MarkInboxRead` + blockout screen; mail records in the SAME save as its grant. Read before touching the Inbox or the save schema.
- `gacha.md` — **AD-Gacha canon**: the banner engine (B3). `MetaMath` (shared), `GrantService` (THE
  one grant path), `BannerRegistry` + banner file shape, the exact summon order, pity, the
  empty-pool fallback, and the "remote returns the views" reveal decision. Read before touching
  anything that grants, spends, rotates or rolls.
- `summon-screen.md` — **AD-UI + AD-Gacha canon, LOBBY**: the B55 summon-screen rebuild to the user's reference (3 tabs mapped by banner TYPE: Special=Selection, Standard, Limited=Event; the B6 carousel is GONE, old controller parked at `ServerStorage.SummonController_B54_backup` — DELETE once confirmed) **plus the three systems it needed**: the timed **Luck** buff (`LuckConfig` pure + `LuckService`; expiry is a COMPARISON, never a scheduled write; `BuildContext` gained a 4th arg `luckBonusMult`), **gem packs on Robux Developer Products** (`GemPackConfig` + `GemPackService`; **USER must paste 4 ProductIds**) over **`ReceiptService`** — THE one owner of `ProcessReceipt`, a REGISTRY so the battlepass level-skips can plug in, idempotent via `Data.Purchases` — and **auto-sell** (`AutoSellConfig` derives its tier list; selling is SummonService step 12 via `GrantService.SellUnits`). Show Chances recomputes the engine's own maths incl. live Luck. Read before touching the summon screen, Luck, packs, receipts or auto-sell.
- `screen-fx.md` — **AD-UI, LOBBY (B108 pt13c)**: the shared juice layer (`Client.UI.ScreenFX` + `StarterGui.ScreenFXLayer` + `Lighting.ScreenFXBlur`) used by StatReroll/SilverShop/Evolve/Ascension/Crafting: blur + drop-in open, button springs, grid pop-in, charge ring + success burst ceremonies, one NPC screen at a time. **Never UIScale a panel on open** (grids size from AbsoluteSize). B108 pt13 summon rebuild: see the pt13 section of `summon-screen.md`.
- `buffs.md` — **AD-Meta canon (UI surfaces AD-UI's), LOBBY**: the active-buff layer (B57). `BuffService.GetActiveBuffs` (READ-ONLY: Luck + Weekend Rush) + HUD `BuffStrip` (top-3 + View All) + `BuffsScreen` cards; `WeekendRushConfig` (Fri–Mon UTC) is DISPLAY-ONLY (the Game does the x2). Read before touching buffs or Weekend Rush.
- `admin.md` — **AD-Meta, LOBBY (+ Game listener)**: owner-only admin panel + "Admin Abuse" (B108 pt12). Security model (panel/remote exist only in the admin's PlayerGui, frozen UserId allowlist, per-call re-auth, validation, rate limit, DataStore audit), actions, global announcements/buffs/gifts via shared `AdminGlobal` (MessagingService + MemoryStore). Read before touching admin, LuckService/BuffService admin hooks or RewardCalculator's multiplier.
- `gacha-selection.md` — **AD-Gacha canon**: SELECTION banners only (blueprint B4's other half,
  B30). The `PlayerChoice` config shape, `BannerChoices` (schema v3) and why `ChosenAtDay` is a DAY
  NUMBER and not a timestamp, the pure `BannerRegistry` choice API, `BannerChoiceService` as the ONE
  writer + `ChooseBannerUnit`'s two modes and refusal codes, and the `ChoiceOverlay` UI. Split out
  of `gacha.md` at B30 on its 300-line cap.
- `reward-push.md` — **AD-Gacha canon, LOBBY**: how the SERVER reveals a grant nobody asked for (B37)
  + the `PendingReveals` queue when it can't reach the player (B39). The opt-in rule (`GrantService`
  never pushes), the client-announced-handshake drain, and why an OFFLINE grant can't happen at all.
- `redeem-codes.md` — **AD-Gacha canon, LOBBY**: promo codes (B39). `CodeRegistry` (pure) +
  `CodeService` (**THE one writer of `Data.RedeemedCodes`**). Read the two warnings before touching
  it: every code in the registry is **PUBLIC** because the module replicates, and the rate limit is
  **security, not UX** — without it the remote is a code-space enumerator.
- `exp-food.md` — **AD-Meta, LOBBY**: EXP food items (B108), `FeedService` / `FeedUnit`, Feed popup on the Units screen.
- `shop.md` — **AD-Gacha canon, LOBBY**: the daily shop (B40), and **the game's first and only Silver
  sink** — B31 minted Silver and nothing ever spent it. Read it for the derived-not-stored stock
  (`MetaMath.RngForSlot`), and for the PRE-CHECK → SPEND → GRANT → MARK ordering with a refund on the
  unreachable failure. The client sends a slot INDEX and never a price.
- `achievements.md` — **LOBBY**: B109 achievements (categories, milestones, `GoalEval` lifetime goal types).
- `quests.md` — **LOBBY + shared rules**: B109 Daily / Weekly / daily Infinite map quests, the Quests window,
  baseline-delta progress, the cross-Place counter list. Spec: `docs/specs/2026-10-03-quests-events-overhaul.md`.
- `battlepass.md` — **AD-Meta/AD-Gacha canon, LOBBY**: the seasonal tier ladder (B42) + match-end XP (B43)
  + gamepass monetization (B48). Read it for the SeasonId-keyed reset (Owned kept across seasons) and the free/paid gates.
- `daily-rewards.md` — **AD-Gacha canon, LOBBY**: the login streak (B38). The pure `DailyRewardConfig`
  (7-day table, `MetaMath` day number, miss-a-day-resets-to-1), `DailyRewardService` as **THE one
  writer of `Data.LoginStreak`**, the HUD button, and the `DevDailyRewind` harness. Read it for the
  worked example of **why a click-to-claim reward must NOT use `RewardPush`**, and for `Day` vs
  `NextDay` — a bug that was invisible to reading. Split out of `rewards.md` at B38 on its cap.
- `lobby-ui.md` — the LOBBY's screens only (Units, Items, Collection, Hotbar, CurrencyBar, HUD buttons,
  the legacy script-built four) + the `DevAutoOpen` harness. Split from `lobby/CONTEXT.md` at A5.
- `loading-screen.md` — **AD-UI canon, BOTH Places** (B136): the one `LoadingScreen` veil (same instances + module in
  both), its API, seamless teleports (`SetTeleportGui` + `ReplicatedFirst.ArrivingLoadingScreen`), every place it shows.
- `reward-reveal.md` — **AD-UI canon, LOBBY** (B135 rebuild): `ObtainRewardsGUI`, THE reward reveal behind
  `ClientEvents.ShowRewards` -- look, motion, PC/console/mobile input, layout, tunables, `DevDismiss` harness.
- `lobby-map.md` — **AD-Lobby canon, LOBBY** (B134): the night-island map -- districts + NPC homes, travel
  waystones + water rescue (`LobbyMapService`), plaza seating, lighting/terrain values, the `tools/lobby_map` builders.
- `notifications.md` — **AD-Meta/AD-Gacha canon, LOBBY**: the HUD "new/claimable" count badges (B49). Reads authoritative counts from existing remotes (Inbox/Daily/Event/Quests/BP), `NotificationController` + `NotifBadgeTemplate` + `RefreshBadges`; no server code. Read before adding a badge.
- `crafting.md` — **AD-Meta/AD-Gacha canon, LOBBY** (B128: fragment items DELETED; live crafting = Mutya, B108): fragments→artifacts→Rainbow crafting (B50, Phase D/D1). 15 SHARED `ItemCatalog` items (both Places `2ee5f976`); `CraftingRecipes` (pure) + `CraftingService` (SpendItems→Grant, ONE path) + `GetCraftInfo`/`Craft` + NPC screen; fragments from an interim shop source until D2. Read before touching recipes or the item catalog.
- `challenges.md` — **AD-Game canon, GAME (+ MetaMath/MetaConfig shared)**: the daily CHALLENGE stage (B51 Game, B52 Lobby tab; Phase D/D2) — a harder match whose Victory drops crafting fragments (the real source). SERVER-AUTHORITATIVE `ChallengeConfig.GetDaily()`; `MatchModifiersConfig` (EnemyHp/lives applied in MatchDirector); reward + `ChallengeClears` in RewardCalculator; `Challenge` GameMode. **Lobby tab (B52):** `StarterGui.Challenge` + `NPC_Challenge` read the SHARED `ChallengeConfig`/`MatchModifiersConfig` and launch via `RequestLaunch` `GameMode="Challenge"`. Read before touching the challenge, its modifiers, or the match-modifier seam.
- `movement.md` — **AD-Game canon, BOTH Places**: sprint (a TOGGLE, both Places) + dash (Q, LOBBY only), B54. Shared `MovementConfig` (`9c7cbd32`) + `MovementController` LocalScript (`e2668274`, identical path both Places). The project's FIRST ContextActionService use — one `BindAction` carries keyboard + gamepad + a generated mobile touch button, so there is NO per-platform branch. `AlwaysSprint` setting PINS sprint on (toggle goes inert). Dash gated in TWO places (`BindAction` + `onDashAction`). Read before touching WalkSpeed, CAS bindings, or adding a movement ability. Animations DEFERRED. **B91: + the player character's own animations (shared `CharacterAnimConfig`, one field per clip).** **B92: + jump/double-jump/dash sounds + VFX (authored `RS.CharacterFX`, shared `CharacterFXRelay`).**
- `settings.md` — **AD-Game + AD-UI canon, BOTH Places**: the ONE settings system (B35). `Scope`
  (Both/GameOnly/LobbyOnly) + `Kind` (Preference/Action) mean the shared screen builder has no
  Place branch at all. Read the `Sanitize`-is-Scope-blind warning before touching it: one profile
  serves both Places, so scope-filtering persistence would permanently lose the other Place's keys.
- `ui-feedback.md` — **AD-UI canon, BOTH Places**: how the UI answers the player (B32). The
  `UIKitButton` tag as the one wiring mechanism; PANEL-STYLE vs FLAT buttons **detected, not
  configured**; `LogoContainer` tilt, the click dip/overshoot; **audio = pasting a SoundId onto a real
  `Sound` under `SoundService`, never a code change** (name a Sound after an act id for stage music);
  `UIKit.Confirm`'s 2s grey→green gate; and the `optionalSibling` rule — a bare `WaitForChild` on a
  sibling module blocks FOREVER and froze the whole UI mid-deploy. Split from `ui-kit.md` at B32.
- `play-menu.md` — **AD-UI canon for `PlayGUI` + `LoadingScreen`** (P2/B15): the Play-button entry
  and GUI hide/restore, the veil's `Show`/`Hide` module API, the menu camera + cursor parallax and
  its respawn release, and the CanvasGroup frame transitions. **Says why `MainMenu`/`StoryModeFrame`/
  `LobbyFrame` are CanvasGroups rather than Frames.** Split out of `lobby-ui.md` at B15 on its cap.
- (otherwise — richer system docs still live in the Game place's `ServerStorage.Documentation`
  [Architecture, SystemIndex, GameplaySystems, Networking, GameFlow, HowTo, CodingStandards,
  MCPWorkflow]; migrate on touch: whenever a session works on a system, move its doc here)

## decisions/
- `ADR-0001-hybrid-canon.md` — why disk-canon for shared/contracts but Studio-canon for Place code
- `ADR-0002-profilestore.md` — why ProfileStore, schema ownership, session-lock/teleport rules
- `ADR-0003-lobby-stat-numbers.md` — the Lobby gets resolved DMG/RNG/SPA from a GENERATED
  `UnitStatsCatalog` + boot validator, not by promoting the full stat stack (user, 2026-08-03)
- `ADR-0004-retire-getcollection.md` — `GetUnitViews` is the Lobby's single profile read path;
  `GetCollection` is dead code. ACCEPTED 2026-08-06 (AD-Lobby), **EXECUTED at A7 the same day**
- `ADR-0005-instance-tree-hashing.md` — GuiObject subtrees are drift-controlled canon: the format,
  the property whitelist, and why ViewportFrame 3D contents are excluded
- `ADR-0008-gacha-pull-counter-key.md` — gacha pulls count on `Counters.Global.GachaPulls`, NOT
  `Summons` (A8 already owns that key for in-match minion summons). Recorded deviation from the
  blueprint's literal wording (user, 2026-08-09)
- `ADR-0006-state-md-cap.md` — `STATE.md` stays ONE file (the bootstrap ritual reads it), cap
  100→120, and a resolved PENDING is DELETED rather than struck through (AD-Integration, A7)
- `ADR-0010-ascension-npc-screen.md` — ascension is its OWN NPC-opened screen, not a pane in the
  Units GUI. Deliberate deviation from blueprint C3 (user, 2026-08-09) that makes Phase C consistent,
  since C1/C2 are already specified "NPC → UI". **C1/C2 should copy this shape.**
- `ADR-0009-kit-uniticon-adopted.md` — **supersedes ADR-0007's PARKED status**: `Kit_UnitIcon` is
  ADOPTED as the shared unit ICON after two real consumers (B6 chips, B8 index), with **no
  controller** and **no byte changed**. It is an icon, not the unit CARD (ADR-0007 clause 3 stands)
- `ADR-0007-kit-uniticon-parked.md` — `Kit_UnitIcon` is PARKED (not adopted, not deleted) until
  Phase B; §8's "renders through the kit" reads pragmatically so the Units screen PASSES; and when
  a shared unit card IS built, **the user's shipping design is lifted into the kit**, not replaced
  by the kit's (USER, 2026-08-06)

- `ADR-0011-difficulty-display-remap.md` — the difficulty slider reads 1–100 for DISPLAY only; the
  `DifficultyPercent` wire format stays 100–1000. Redefining it in place would silently run matches
  at 10× enemy health during the window where one Place is republished and the other is not (USER,
  2026-08-09)

## proposals/
- `2026-09-10-weekend-rush-game-doubling.md` — AD-Meta→AD-Game: apply Weekend Rush **x2** to rewards+exp (GAME); promote `WeekendRushConfig` to shared; confirm tz + whether BP XP doubles. OPEN.
- `2026-09-10-luck-on-rerolls.md` — AD-Meta→AD-Traits: make Luck bias trait+stat rerolls; weight-bias (shared canon) vs best-of-N (Lobby-local); magnitude is the user's call. OPEN.
- `2026-08-20-c4-feeding.md` — AD-Gacha: C4 feeding is **blocked on DATA, not code** — no `FeedValue`
  in `ItemCatalog`, no unit XP curve, no `UnitInstance.XP` writer. Needs food + a curve + a source. OPEN.
- `2026-09-02-inbox-v5.md` — AD-Meta/AD-Gacha → AD-Game: the Inbox screen needs a **v5 schema bump** (a new `Data.Inbox` history field + both-Place publish — the first genuinely necessary bump since v4). Migration + build sketch. OPEN.
- `2026-09-02-d2-challenges.md` — AD-Meta/AD-Gacha → AD-Game: **D2 challenges** — the rotating modifier stage that DROPS crafting fragments (the real source D1 was built for; interim shop source until then). SHIPPED B51 (Game) + B52 (Lobby tab).
- `2026-08-14-reward-preview-wiring.md` — AD-Integration→AD-UI: `RewardScalingConfig` is deployed in
  the Lobby (B20) so the preview has real numbers, but `renderRewards` cannot express a min–max BAND
  and re-runs only on act select while the slider keeps moving. Needs a rendering decision + a
  difficulty listener in `StoryModeController`. OPEN.
- `2026-08-06-kit-promotion-blocks-a6.md` — AD-UI→AD-Integration: A6's Game hotbar needs the kit,
  which is Lobby-only, and `hash_shared.luau` cannot hash GuiObject templates (only ModuleScripts).
  **DECIDED: extend the tooling first.** BLOCKS A6's Game half.
- `2026-08-03-drop-getcollection-compat.md` — AD-UI→AD-Lobby: delete the now-unread
  `Towers`/`Currency` compat fields from `GetCollection`, and review the `Items` field AD-UI
  added to `GetUnitViews` (user-authorised edit to AD-Lobby canon). OPEN.
- `2026-08-01-a4-promote-meta-and-tierconfig-multicolor.md` — AD-UI→AD-Integration: promote
  resolver + Meta configs to shared, reconcile TierConfig (A3 shape + multi-colour), retire Lobby
  interim UnitCatalog, spec LobbyServices unitView. BLOCKS A4/A5.
- `2026-07-31-ui-kit-button-primitive.md` — AD-UI: add a universal Button primitive +
  PlayerLevelBar to the Phase A kit (§5); no-scripts-on-templates rule; hotbar glow-bug
  hypothesis. FOR REVIEW; gated on A1–A3.
- `systems/match-architecture.md` -- GAME match big picture: principles, subsystem ownership, boot order, lifecycle, extension points, conventions (migrated B123 from the retired in-Studio docs).
- `systems/match-modules.md` -- GAME module + folder index (what lives where, stable APIs).
- `systems/match-networking.md` -- GAME remotes, every one, + the security model.
- `systems/content-howto.md` -- recipes: rig prep, elements, passives, abilities, support, summons, enemies, status effects, maps.
- `systems/units-screen.md` -- Lobby Units screen (B108 pt14 rebuild: hero-left, upgrade path, tooltips, inspect, teams, select-by-filter) + the Game copy on J (B123: loadout only, until wave 1).
