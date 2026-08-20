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
- `save-schema.md` — Profile data shape, versions, migration rules (owner: Game). **v2**
- `teleport.md` — Lobby→Game / Game→Lobby TeleportData payloads (owner: Lobby). **v2**

## design/
- (empty — design pillars/economy docs migrate here from Studio progressively)

## systems/
- `rewards.md` — **AD-Game canon**: match-end payouts (P5, B18). `RewardCalculator`, the
  difficulty→gold curve in the SHARED `RewardScalingConfig`, why the curve is shared rather than
  per-`StageConfig`, and **the two difficulty scales** (UI 1–100 vs WIRE 100–1000, ADR-0011) —
  confusing them pays maximum gold for a normal match, silently. Also records that Insane is
  implemented but UNREACHABLE until teleport v3. Read before touching anything that pays a player.
- `ui-kit.md` — **Place-NEUTRAL** AD-UI canon for the shared UI kit: 6 controllers
  (`RS.Shared.UIKit`, `shared/src` files) + 8 real instance templates (`RS.UITemplates.Kit`, the
  INSTANCE is canon per ADR-0005), the shared hotbar, the configs it depends on, and the rules
  that keep it healthy. Split out of `lobby-ui.md` at A7 once BOTH Places used the kit.
- `ascension.md` — **AD-Gacha canon**: dupe-fed ascension (blueprint C3, B9). The dupe-protection
  rules (locked/favourited/**equipped**, oldest-first), the server-enforced confirm, why
  `AscensionRules` is split from the service, and the one authorised line in `UnitsController`.
  Read before touching anything that destroys a player's unit.
- `gacha.md` — **AD-Gacha canon**: the banner engine (B3). `MetaMath` (shared), `GrantService` (THE
  one grant path), `BannerRegistry` + banner file shape, the exact summon order, pity, the
  empty-pool fallback, and the "remote returns the views" reveal decision. Read before touching
  anything that grants, spends, rotates or rolls.
- `gacha-selection.md` — **AD-Gacha canon**: SELECTION banners only (blueprint B4's other half,
  B30). The `PlayerChoice` config shape, `BannerChoices` (schema v3) and why `ChosenAtDay` is a DAY
  NUMBER and not a timestamp, the pure `BannerRegistry` choice API, `BannerChoiceService` as the ONE
  writer + `ChooseBannerUnit`'s two modes and refusal codes, and the `ChoiceOverlay` UI. Split out
  of `gacha.md` at B30 on its 300-line cap.
- `lobby-ui.md` — the LOBBY's screens only (Units, Items, Collection, Hotbar, CurrencyBar, HUD
  buttons, the legacy script-built four) + the `DevAutoOpen` Studio harness. Split out of
  `places/lobby/CONTEXT.md` at A5 when that file passed its 150-line cap.
- `ui-feedback.md` — **AD-UI canon, BOTH Places**: how the UI answers the player (B32). The
  `UIKitButton` tag as the one wiring mechanism; PANEL-STYLE vs FLAT buttons **detected, not
  configured** (what scales, how the hover stroke grows, whether its gradient spins); `LogoContainer`
  tilt and the click dip/overshoot; **audio, where assigning a sound is pasting a SoundId onto a real
  `Sound` under `SoundService` and never a code change** (name a Sound after an act id to give that
  stage music); and `UIKit.Confirm`'s 2-second grey→green Yes gate. Also records the
  `optionalSibling` rule — a bare `WaitForChild` on a sibling module blocks FOREVER and froze the
  whole UI mid-deploy. Split out of `ui-kit.md` at B32 on its 300-line cap.
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
- `2026-08-20-c4-feeding.md` — AD-Gacha: C4 feeding is **blocked on DATA, not code**. `ItemCatalog`
  has no `FeedValue`, there is no unit XP curve and no writer for `UnitInstance.XP`; every piece of
  machinery it would reuse already exists. Needs food items + a curve + a source of food. OPEN.
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
