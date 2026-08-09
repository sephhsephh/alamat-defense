# Doc index (one line each — read only what the task needs)

## root-level
- `OWNERSHIP.md` — system → owning chat → home Place → canon location (single-writer registry)
- `ROADMAP.md` — one-glance feature status board: done / partial / planned / ideas (all chats update)

## blueprints/ (implementation law for the meta systems — read before building)
- `phase-a-foundations.md` — schema v2 exact shape + migration, ItemCatalog, Tier/StatGrade/
  Ascension configs, base-stat ranges + resolver, icon kit, session plan A1–A7
- `phases-b-f-meta.md` — gacha/rerolls/economy/seasonal/endgame: algorithms (summon order,
  deterministic rotation, GrantService), config shapes, session plans, cross-phase invariants

## contracts/
- `save-schema.md` — Profile data shape, versions, migration rules (owner: Game). **v2**
- `teleport.md` — Lobby→Game / Game→Lobby TeleportData payloads (owner: Lobby). **v2**

## design/
- (empty — design pillars/economy docs migrate here from Studio progressively)

## systems/
- `ui-kit.md` — **Place-NEUTRAL** AD-UI canon for the shared UI kit: 6 controllers
  (`RS.Shared.UIKit`, `shared/src` files) + 8 real instance templates (`RS.UITemplates.Kit`, the
  INSTANCE is canon per ADR-0005), the shared hotbar, the configs it depends on, and the rules
  that keep it healthy. Split out of `lobby-ui.md` at A7 once BOTH Places used the kit.
- `gacha.md` — **AD-Gacha canon**: the banner engine (B3). `MetaMath` (shared), `GrantService` (THE
  one grant path), `BannerRegistry` + banner file shape, the exact summon order, pity, the
  empty-pool fallback, and the "remote returns the views" reveal decision. Read before touching
  anything that grants, spends, rotates or rolls.
- `lobby-ui.md` — the LOBBY's screens only (Units, Items, Collection, Hotbar, CurrencyBar, HUD
  buttons, the legacy script-built four) + the `DevAutoOpen` Studio harness. Split out of
  `places/lobby/CONTEXT.md` at A5 when that file passed its 150-line cap.
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
- `ADR-0009-kit-uniticon-adopted.md` — **supersedes ADR-0007's PARKED status**: `Kit_UnitIcon` is
  ADOPTED as the shared unit ICON after two real consumers (B6 chips, B8 index), with **no
  controller** and **no byte changed**. It is an icon, not the unit CARD (ADR-0007 clause 3 stands)
- `ADR-0007-kit-uniticon-parked.md` — `Kit_UnitIcon` is PARKED (not adopted, not deleted) until
  Phase B; §8's "renders through the kit" reads pragmatically so the Units screen PASSES; and when
  a shared unit card IS built, **the user's shipping design is lifted into the kit**, not replaced
  by the kit's (USER, 2026-08-06)

## proposals/
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
