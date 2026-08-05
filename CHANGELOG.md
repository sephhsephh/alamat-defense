# CHANGELOG (append-only; newest first)

## 2026-08-06 [user] BOTH Places republished — the A-phase is live; blocking PENDING cleared

Bookkeeping entry (no code change). The **USER, BLOCKING** republish PENDING that had been open
since 2026-08-01 is **CLEARED**: the user republished both Places together, so everything that
was Studio-only canon is now the live build — the 4 shared Meta configs, the reconciled
multi-colour `TierConfig`, `GetUnitViews` (+`Items`), the A5 UI (Items screen, FilterPanel,
ItemIcon, rebuilt CollectionScreen, kit consolidated into `RS.UITemplates.Kit`), and A6/A6b
(`UnitStatsCatalog` `3bb9b140` + the Game-side validator, compat fields dropped).

Verified in the Lobby before clearing it (AD-UI, place-asserted):

- Drift **GREEN 9/9**, `UnitStatsCatalog=3bb9b140` matching `shared/manifest.json`
  (`deployed.Lobby` and `deployed.Game` both `3bb9b140`).
- `LobbyServices`: `Towers = towers` and `Currency = currencies.Gold` **absent** (A6b's removal
  really landed), `Items = items` **present** (kept per the A6b review).
- `RS.Remotes.GetCollection` still **present** — correct: ADR-0004 sequences its deletion for A7.

- **Still open (user):** live e2e re-verification of the **teleport v2 loop** (lobby → reserved
  match → return → banner). Publishing v2 is not the same as running it; v2 has only ever been
  Studio-verified, and only v1 was ever live-verified end-to-end (2026-07-18). Worth one run now
  that both Places are on v2, since a `[CONTRACT]` mismatch would be a launch-blocker.
- **Unblocked by this:** the A7 `GetCollection` retirement (ADR-0004) was deliberately sequenced
  after the republish so that publish would not also carry a remote deletion.
- **Next:** AD-UI fills the Units `--` number slots from `UnitStatsCatalog.Get` — the last piece
  of A6. No Integration needed until A7.

## 2026-08-06 [lobby] A6b (AD-Lobby): UnitStatsCatalog deployed (drift 9/9), GetCollection compat fields deleted, GetCollection retirement decided (ADR-0004)

Bootstrap drift **8/9 with `UnitStatsCatalog=MISSING`** exactly as A6 documented; all 8 other
hashes matched the manifest. Integration gate: **No Integration needed — proceeding** (triggers 1
and 2 fire, but the trigger IS this task and deploying a shared module into my own Place is
ordinary owner-chat work — nothing required the Game Place to act).

- **`UnitStatsCatalog` DEPLOYED to the Lobby.** `shared/src/UnitStatsCatalog.luau` written
  VERBATIM (2474 bytes, zero local modifications) to `RS.Configs.Meta.UnitStatsCatalog`; the
  module did not previously exist and was created. Hash came back **`3bb9b140`** — equal to the
  manifest on the first write, no reconciliation needed. `manifest.json` →
  `modules.UnitStatsCatalog.deployed.Lobby = "3bb9b140"`. **Drift re-run: GREEN 9/9 in the Lobby**,
  now byte-identical with the Game in all nine shared modules. The load-bearing validator
  (`UnitStatsCatalogValidate`) was deliberately NOT ported — it is Game canon and the Lobby has no
  tower configs to validate against (noted in the manifest comment so nobody "fixes" the omission).
- **`GetCollection` compat fields DELETED** (proposal `2026-08-03-drop-getcollection-compat.md`).
  Re-grepped BEFORE deleting, as the proposal demands: `result.Towers` / `result.Currency` had
  **zero readers**. The only `%.Towers` / `%.Currency` hits in the Place are `ProfileTemplate`'s
  v1→v2 migration reading the OLD PROFILE fields — a different thing entirely, left untouched.
  Removed the `towers` local, the `prev`/highest-MetaLevel block, both trailing return fields and
  the stale header paragraphs. `GetCollection` still serves `Units`/`Loadout`/`Currencies`/
  `PlayerXP`/`PlayerLevel`.
- **`GetUnitViews.Items` REVIEWED → KEPT AS-IS.** AD-UI's user-authorised addition is the right
  shape: it copies rather than aliasing `data.Items`, is defensive about the field being absent,
  type-checks each count, and is read-only + additive. **No reshape, so `ItemsController` needs no
  change.** Confirmed as AD-Lobby canon in the module header.
- **`GetCollection` fate DECIDED: retire it — `docs/decisions/ADR-0004-retire-getcollection.md`.**
  The re-grep found the remote now has **zero callers of any kind** (every screen reads
  `GetUnitViews`); the only references left are its own handler registration and comments. Two
  profile read paths against one schema is a standing rot hazard — the compat cruft deleted above
  is exactly that rot. **Execution (handler + RemoteFunction deletion) is scheduled for A7,
  deliberately AFTER the blocking republish**: that publish is already the riskiest open action and
  carries all of A-phase + A5 + A6, remote deletions fail late and silently (a client
  `WaitForChild`ing a removed remote yields forever), and Place-local code is Studio-canon
  (ADR-0001) so the published file is the only recoverable snapshot. Until then it stays wired and
  unread — **no new readers may be built on it**, recorded in the `LobbyServices` header.
- **Contract impact: none.** No shared-module EDIT (a deploy of an unchanged module), no schema or
  teleport change. `GetCollection` is not a versioned contract and both deleted fields were
  documented as interim from the day they landed. ADR-0004 does note that `GetUnitViews` is now
  load-bearing for the entire Lobby UI and would need contract treatment if ever changed breakingly.

**Verified live (Play, dev store, Lobby)** — canonical method per CLAUDE.md (`[DIAG]` prints from
real Scripts + `get_console_output`, plus instance-property reads; no service state via
`execute_luau`). Studio was restarted mid-session, so every edit was re-verified from the saved
file afterwards (drift 9/9, zero compat remnants) before landing:

- Boot clean: `[CONTRACT] Lobby boot: save-schema v2`, `[DATA] LobbyServices ready`, profile v2
  loaded, `CollectionScreen`/`HotbarController`/`UnitsController`/`ItemsController` all ready.
  **No errors or warnings under any of our log prefixes.** `LobbyServices ready` is the module's
  LAST line, so the edited module compiled and both handlers registered.
- Collection loads with the compat fields gone: `[DIAG] CollectionScreen loaded 8 unit view(s)`,
  **8 cards, 0 stray templates**, meta line `8 unit(s) | Gold: 240 | Silver: 0 | Account Lv 1
  (360 XP)`, first cards Necromancer/Mythic/Lv 20, Meteor/Legendary, Warchief/Legendary,
  Babaylan/Epic — real grades throughout. Verified via the `DevAutoOpen` harness (A5 pattern),
  **left OFF on all three screens at landing**.
- `UnitStatsCatalog` requires cleanly from a client context (the exact thing AD-UI needs next):
  8 towers, `Get` is a function, all values match A6's published set (Archer 15/20/6, Knight
  35/10/1.4, Mage 30/18/2, **Farm RNG-only, no DMG/SPA**, Babaylan 20/22/2.5, Meteor 30/24/1.4,
  Warchief 25/18/1, Necromancer 28/22/1.1), `Get("NotATower")` → nil, REFERENCE tier 1 / ML 1 /
  asc 0. (Pure data module, no services — a compile+shape check, not a live-service-state check.)
- **Environment note:** four Play attempts died within ~1s to `Server Kick Message: Error 500`.
  Cause was a **free model the user had inserted**; after the user removed it and restarted
  Studio, Play was stable and every check above passed. Not a code defect — but see the advisory:
  inserted free models are a known backdoor-script vector and the Place should be swept.
- **PENDINGs:** the TWO this session owned are **CLEARED** (deploy `UnitStatsCatalog` to the Lobby;
  the A5 `GetCollection` handoff). **NEW (A7 / AD-Integration):** delete the `GetCollection` handler
  + RemoteFunction per ADR-0004, after the republish. **AD-UI is now UNBLOCKED** to fill the Units
  `--` slots from `UnitStatsCatalog.Get`. Unchanged: **USER republish both Places** (now also
  covering A5 + A6 + this session), no `Data.Loadout` writer, no `Data.Items` writer,
  `TowerProgressionConfig` promotion for `XpPct`, Game round-trip test.
- Commit is **local** (`push pending` — the remote-tracking ref shows main level with origin
  through A6, but this session's commit is unpushed).

## 2026-08-03 [game] A6 (AD-Game): UnitStatsCatalog + load-bearing validator, profile-wait moved to StartMatch, cold-profile harness

Bootstrap drift **GREEN 8/8** at start. Integration gate: **No Integration needed — proceeding**
(the new shared module deploys to Game now; the Lobby deploy is a follow-up PENDING). Three items,
per the session brief.

- **`UnitStatsCatalog` (new, 9th shared module; ADR-0003).** `shared/src/UnitStatsCatalog.luau` →
  `RS.Configs.Meta.UnitStatsCatalog`, hash **`3bb9b140`**, `deployed.Game` only (**Lobby=null**).
  A GENERATED cache of each tower's resolver-PRODUCED base DMG/RNG/SPA at the reference tier 1 /
  ML 1 / no-trait / mid-roll (0.5) / asc 0 — SPA inverted, not raw BaseStats. Lets the Lobby fill
  the A5 Units `Stats.BaseStatsFrame.{DMG,RNG,SPA}` number slots WITHOUT the ~12-module full stat
  stack. `manifest.json` + `tools/hash_shared.luau` now cover **9** modules. Values (Archer 15/20/6,
  Knight 35/10/1.4, Mage 30/18/2, Farm –/18/–, Babaylan 20/22/2.5, Meteor 30/24/1.4, Warchief
  25/18/1, Necromancer 28/22/1.1).
- **Load-bearing validator** `SSS.Server.UnitStatsCatalogValidate` (Game canon, runs in ALL contexts):
  regenerates from the live tower configs at boot and `error()`s LOUDLY on any drift (a stale cache
  lying about damage is worse than `--`; ADR-0003). Verified: green when correct, and it caught an
  injected `Archer.DMG 15→99` with a red boot error that did NOT brick the runtime.
- **Empty-hotbar hotfix review → wait moved to the choke point.** The profile-wait that guarded the
  cold-profile race MOVED from `MatchEntryService` into `MatchDirector.StartMatch` (the one place
  that validates loadouts), so it now protects EVERY caller — teleport entry, restart/next-act, the
  harness, and any future relaunch — not just the entry path. `StartMatch` claims `isRunning` before
  yielding so a second concurrent start can't slip through the wait; `MatchEntryService` simplified
  (its `waitForProfiles` + `PlayerDataService` require removed). No circular require (MatchDirector
  already reaches PlayerDataService via LoadoutValidator→PlayerInventoryService).
- **No-dev-seed Studio harness** `ColdProfileMatchTest` (Studio-only, attribute `Enabled` default OFF;
  the smoke test stands down when it is on): waits for the REAL profile and builds the loadout from
  the player's ACTUAL owned units (no `DevSetOwnedTowers`), then `StartMatch`. Closes the blind spot
  behind two live-only failures. Verified: read the real profile (8 units), built a 6-uuid loadout,
  match started with **no dev-seed line** and no empty hotbar; smoke test stood down.
- **Contract impact:** none (save/teleport unchanged). **Shared-module ADD** — Lobby must deploy
  `UnitStatsCatalog` (below). All other A6 code (validator, harness, MatchDirector, MatchEntryService,
  smoke test) is Game Studio canon.
- **PENDINGs:** the 3 A6-Game PENDINGs CLEARED (UnitStatsCatalog, hotfix review, cold harness). NEW
  (AD-Lobby / AD-Integration): **deploy `UnitStatsCatalog` `3bb9b140` to the Lobby** — its drift check
  FAILS until then — after which AD-UI fills the Units `--` number slots. USER republish PENDING now
  also covers this session's Game changes.

## 2026-08-03 [lobby] A5: Items screen + FilterPanel on the kit, CollectionScreen rebuilt on the view-model, kit moved to RS.UITemplates.Kit

Blueprint phase-a §9 A5 (AD-UI). Bootstrap drift **GREEN 8/8**, unchanged at landing (no shared
module touched). Integration gate answered "No Integration needed — proceeding."

- **Kit relocated to the blueprint §5 home.** `ReplicatedStorage.UITemplates.Kit` now holds every
  editable template: the moved `Button` / `UnitPreviewTemplate` / `Unit/ItemIconTemplate` plus the
  new `ItemIcon`, `ItemHoverCard`, `FilterPanel`. **`StarterGui.UITemplates` emptied and deleted.**
  `UIKit.Button` already probed the Kit path first, so nothing needed rewiring. *(User chose this
  over keeping the split — it follows the blueprint literally.)*
- **`UIKit.ItemIcon`** (new, `RS.Shared.UIKit.ItemIcon`) — flat `IconImage` ImageLabel, **no
  ViewportFrame** (items have no model), `QtyBadge` that hides at qty 0 and dims the icon, tier
  border + BG from the shared multi-colour `TierConfig`, hover/press scale + white border.
  `create/attach/onHover/onActivated/setQty/setSelected/destroy` + `ImageFor(id)` (falls back to
  the Studio placeholder while every catalog icon is still `rbxassetid://0`).
- **`UIKit.FilterPanel`** (new) — the reusable component the blueprint specifies: `GroupTemplate`
  + `ToggleTemplate` + Apply/Reset/Cancel, pending-vs-applied state, `handle.selected(groupId)`
  returning nil for an unconstrained group. **Used by BOTH screens**: Units (tier + equipped/
  favourited/locked) and Items (tier/kind/owned-only).
- **Items screen** (`StarterGui.ItemsGUI` + `ItemsController`) — chrome cloned from the Units
  screen so the design language matches. Lists every `ItemCatalog` entry of `Kind` Item/Currency;
  counts from `GetUnitViews`. Hover card, selected panel, search, filters; sort owned→tier→name.
- **CollectionScreen REBUILT on real instances** (`Panel.Grid.CardTemplate`, editable in Studio)
  reading `GetUnitViews` — uuid cards, tier border/BG, `Lv N`, the three GRADE letters, a status
  line, and a meta line with Gold/Silver/account level. The old script-built UI is gone
  (convert-on-touch rule). **It was the LAST reader of `GetCollection`'s `Towers`/`Currency`.**
- **Units stat rows are now dual-slot** (user added a `Grade` TextLabel to `DMG/RNG/SPA`
  mid-session): the GRADE letter goes in `Grade`, the NUMBER slot shows `--` instead of the
  template's stale `99.9k`, and A6 fills it with real values. Rows WITHOUT a `Grade` child
  (the hover preview's Attack/Element/MaxPlacement) keep the A4 behaviour.
- **`LobbyServices.GetUnitViews` now also returns `Items`** — the profile's `{ [itemId] = count }`
  map, copied and defensive if absent. **This is AD-Lobby canon edited by AD-UI**, done only
  because the user explicitly authorised it this session when told the alternative; flagged for
  AD-Lobby review in the proposal below. Additive + read-only, so **no contract bump**.
- **Fixed en route:** the legacy `Unit/ItemIconTemplateLocalScript` had a **syntax error on line
  30** (`ocal Preview = ...`) and had been erroring every time that template replicated into
  PlayerGui. Deleted — superseded by `UIKit.Button`.
- **Docs:** `places/lobby/CONTEXT.md` passed its 150-line cap → the UI section split out to the
  new **`docs/systems/lobby-ui.md`** (AD-UI canon, the doc `OWNERSHIP.md` already anticipated),
  registered in `docs/INDEX.md`. CONTEXT is back to 112 lines. Also corrected a long-standing doc
  error: the sixth HUD button is `Store`, not `Shop`.

**Verified live (Play, dev store, Lobby):** `VirtualInputManager` is blocked for tooling
(no `RobloxScript` capability) and `user_mouse_input` / `get_console_output` / `screen_capture`
kept routing to the GAME Studio window mid-session, so verification ran through a new
`DevAutoOpen` **attribute harness** on each screen (same pattern as `DevSimulateReturn`) plus
place-asserted property reads in the Client datamodel:

- Items: 5 cards (BannerTicket/Gold/GoldenSeed/Silver/TraitRerollToken), every qty 0 → badges
  hidden + icons dimmed (correct — nothing writes `Data.Items`); selected = Golden Seed,
  Legendary, "Owned: 0 / 9999", description filled.
- FilterPanel: built from the templates, 4 tier + 2 kind + 1 show toggles on Items, 8 tier + 3
  show on Units, **no stray `GroupTemplate` left in the layout** on either.
- Collection: 8 uuid cards, first = Necromancer / Mythic / Lv 20 / DMG B RNG B SPA B, meta line
  "8 unit(s) | Gold: 0 | Silver: 0 | Account Lv 1 (0 XP)", no stray template.
- Units: `Grade` labels read B/B/B (matching Necromancer) with the number slot at `--`.
- `applyFilters` exercised end-to-end via the search path: ""→8, "mage"→1, "necro"→1, "zzz"→0, ""→8.
- Boot clean: `[DIAG] ItemsController ready`, `[DIAG] CollectionScreen ready`, no errors;
  `UIKitBootstrap` picked up 33 tagged buttons. Harness attributes left **OFF** on all three.

**Hover geometry — closed same session (follow-up pass).** Verified by deriving the real
viewport from a full-screen probe rect (`CurrentCamera.ViewportSize` reads `1,1` from the
tooling VM) and replaying the placement maths against every real card rect. Three findings, all
fixed:

- **A4's `showPreview` assumed the preview was `0.2 × 0.36` of the viewport.** The Units preview
  is really ~`0.19 × 0.19`, so the flip-to-left triggered about twice as early as needed and the
  vertical clamp reserved double the margin. Both controllers now **measure** `AbsoluteSize`
  (scale constants kept as the zero fallback).
- **`math.clamp` errors when max < min** — reachable whenever the preview is taller than the
  viewport, and hit for real during verification. Now guarded (falls back to vertical centre);
  the horizontal position is clamped on-screen too.
- **Template/instance size drift:** `ItemsGUI.HoverPreview` was cloned from `ItemHoverCard`
  *before* that template was resized, so the deployed copy kept the old ~38%-of-screen footprint
  while the template said 20%. Re-synced; a sweep confirmed both `FilterPanel` clones match.

Re-verified at 1920×1078: Items preview 384×367 (20%×34%), Units 368×201 (19%×19%), **0 flips,
0 off-screen** across all 13 cards, well inside the viewport. Harness attributes left OFF.

- **Contract impact:** none. No shared module, schema or teleport change; drift surface unchanged
  (GREEN 8/8 at both bootstrap and landing). `GetUnitViews` gained one additive read-only field.
- **PENDINGs:** A5 cleanup PENDING **handed to AD-Lobby** —
  `docs/proposals/2026-08-03-drop-getcollection-compat.md` covers both deleting the now-unread
  `Towers`/`Currency` compat fields AND reviewing AD-UI's `Items` addition. Unchanged: **USER
  republish both Places** (this session is Studio canon too), A6 numbers decision + hotbar,
  `Data.Loadout` writer (`Equipped` always false), **no `Data.Items` writer** (every item count
  is 0 by design until an item economy exists), `TowerProgressionConfig` promotion for `XpPct`,
  Game round-trip test + no-dev-seed harness.

## 2026-08-03 [lobby] A4: Units screen wired to the GetUnitViews view-model (real tiers/grades) + UnitCatalog deleted

Blueprint phase-a §9 A4 (AD-UI). Re-bootstrapped onto the post-A1/A2/A3 world (drift GREEN 8/8,
`ProfileTemplate 63a0c98a`, schema v2).

- **`UnitsController` now consumes `LobbyServices.GetUnitViews`** (was `GetCollection` + the
  interim `UnitCatalog`). Cards are keyed by **uuid** (one per unit instance). Each card renders
  from the view: `Name`+`Tier` (ItemCatalog), tier border + BG from the shared multi-colour
  `TierConfig`, per-stat **GRADE** letters (`view.Grades`, from `StatGradeConfig`) in the Stats
  panel + hover preview, real `Level`/`XP` on the preview level bar, `Favorited`/`Equipped`
  driving the sort (equipped > favourited > tier high→low > name), search by `Name`.
- **`fillStats` hardened:** stat rows resolve by `DMG/RNG/SPA` OR the template's
  `Attack/Element/MaxPlacement` names (the hover preview kept the original template names, so it
  showed stale `99.9k` defaults until now); the preview's fake element chips (`InformationFrame`)
  are hidden until real element data exists.
- **`RS.Configs.Meta.UnitCatalog` DELETED** — the retired-in-place interim config (A2 left it as
  the only placeholder source) has no readers left. Confirmed via `script_grep` before deleting.
- **Resolved DMG/RNG/SPA NUMBERS still deferred to A6** (per the 2026-08-01 user decision —
  `TowerStatResolver` is not in the Lobby). A4 ships **grades**, which need only the roll.
- **Verified live (Play, dev store):** 8 units load via `GetUnitViews`, no errors; grades vary
  per unit and stat (e.g. Mage D/SS/C, Knight A/C/C, Necromancer B/B/B — no longer flat); tier
  sort puts Necromancer (Mythic) first (auto-previewed on open); hover preview shows the unit's
  grades + real `LVL: 20`, element chips hidden; rainbow/Legendary/etc. borders render.
- **Contract impact:** none (read-only consumer of the existing `GetUnitViews`; no shared-module
  or schema change; drift surface unchanged).
- **PENDINGs:** UnitCatalog-deletion PENDING CLEARED. Remaining for A5/A6: rebuild CollectionScreen
  on the view-model so `LobbyServices.GetCollection`'s interim `Towers`/`Currency` compat can be
  removed (AD-Lobby); Items screen + FilterPanel (A5); resolved stat NUMBERS + hotbar rebuild (A6);
  `Data.Loadout` writer / equip UI so `Equipped` is ever true; real per-unit models. **USER: republish
  both Places** (Studio canon).

## 2026-08-03 [lobby] Starter grant rolls real quality: StarterChoiceService calls StatGradeConfig.RollAll

- **PENDING (AD-Lobby starter rolls) CLEARED** — per AD-Game's proposal
  (`docs/proposals/2026-08-03-starter-grant-rolls.md`): `StarterChoiceService.newUnitInstance`
  now writes `StatRolls = StatGradeConfig.RollAll(statRng)` instead of the hardcoded
  `{0.5,0.5,0.5}` midpoints. `StatGradeConfig` required from its shared deploy path
  (`RS.Configs.Meta.StatGradeConfig`, drift-green 49a6edfd); ONE module-level `Random`
  (same rationale + pattern as `PlayerInventoryService` — per-grant `Random.new()` can
  correlate same-frame). Every other UnitInstance field byte-matches `GrantUnit`'s shape
  (re-read from Game canon this session). Grant log now prints rolls + grades.
- **Verified live (Play, dev store, DevSimulateFirstJoin harness):** two grants across
  separate runs rolled DMG=0.370/D RNG=0.652/B SPA=0.341/D then DMG=0.764/B RNG=0.598/C
  SPA=0.509/C — varied run-to-run, all in 0..1, grade spread D/C/B, boundary case correct
  (0.652 → B, just past C's 0.65 max). Sim tower auto-cleaned on the non-sim boot; sim left
  OFF; dev profile clean.
- **A4 caveat lifted:** "every grade reads C" no longer applies to any grant path — all
  paths (GrantUnit, DevSetOwnedTowers, starter) now roll. Only pre-existing/migrated units
  remain grandfathered at 0.5 by design.
- **Contract impact:** none — value-only change inside the v2 `UnitInstance`; no schema
  bump, no shared-module edit, no drift surface. Drift GREEN 8/8 at bootstrap.
- **PENDINGs:** starter-rolls PENDING cleared. Unchanged: USER republish both Places (this
  change is Studio canon too and joins that publish), Loadout writer, A6 numbers decision,
  A4/A5 cleanup, TowerProgressionConfig promotion, Game round-trip test.

## 2026-08-03 [game] Stat rolls actually roll: GrantUnit + DevSetOwnedTowers call StatGradeConfig.RollAll

- **The fix:** `PlayerInventoryService` (Game canon) now requires shared `StatGradeConfig` and rolls
  real per-unit `StatRolls` instead of the hardcoded `{0.5,0.5,0.5}`. `GrantUnit` uses
  `o.StatRolls or StatGradeConfig.RollAll(statRng)` — an explicit `opts.StatRolls` still wins, so
  deterministic tests and the future gacha (which inherits this canonical entry point) keep working.
  `DevSetOwnedTowers` rolls each seeded unit too (with an optional per-tower `value.StatRolls`
  override for deterministic Studio tests). Both draw from ONE module-level `Random` (`statRng`) —
  `Random.new()` per grant can correlate within a frame and hand out identical rolls; the shared
  `StatGradeConfig` is left untouched (rng passed in).
- **Left alone (correct):** `Migrations[1]` (append-only; already ran live — existing units stay
  grandfathered at 0.5), `GetUnit`'s defensive `record.StatRolls or {0.5..}` read-guard.
- **Not mine — handed off:** the Lobby's `StarterChoiceService` still writes 0.5 (AD-Lobby canon).
  Wrote `docs/proposals/2026-08-03-starter-grant-rolls.md` + a STATE PENDING; `StatGradeConfig` is
  shared, so that chat calls `RollAll(rng)` directly.
- **Verified live** (real `[Test]` Script + `get_console_output`, NOT execute_luau — grants mutate
  the profile): 6 Archers + 3 Mages rolled distinct values in 0..1 (0.027–0.997), grade spread
  D/C/B/A/SSS (no longer all "C"), explicit override returned exactly `{1,0,0.5}`, and two Archer
  instances at ML50 resolved to different DMG/SPA/RNG (37.8/32.4 DMG) — the quality multiplier doing
  something for the first time. Temp harness removed after.
- **Balance note (flagged, not silently shipped):** with real rolls the BaseStats pilots vary
  unit-to-unit. Estimated single-unit DPS swing (DMG × SPA-inversion): **Archer ≈ 0.78×–1.24×**
  (~1.6× best/worst), **Mage ≈ 0.72×–1.32×** (~1.83× best/worst, from its wider ±20% DMG range).
  Not broken — worst-roll units are still functional — but Mage's spread is on the wide side with no
  stat-reroll system yet (phase C). Recommend tightening Mage `BaseStats.DMG` (e.g. {0.88,1.12})
  or revisit at reroll balancing; left as-is pending the user's call.
- **Contract impact:** none. `PlayerInventoryService` is Game Studio canon (no shared-module/manifest
  change); it only *requires* the already-shared, drift-green `StatGradeConfig`. No Integration needed.
- **PENDINGs:** AD-Game roll wiring CLEARED; NEW AD-Lobby starter-grant PENDING (above). USER
  republish PENDING now also covers this `PlayerInventoryService` change (Studio canon, not git).

## 2026-08-01 [integration] Meta configs promoted to shared canon + TierConfig multi-colour reconcile + LobbyServices unitView — A4/A5 unblocked

Executes `docs/proposals/2026-08-01-a4-promote-meta-and-tierconfig-multicolor.md` §1–§4, with one
scoped decision and two scope corrections (below). Hotfix from earlier today confirmed live by the
user first (empty-hotbar bug gone), so this session started from a healthy live game.

- **Promoted to `shared/src` + deployed byte-identical to BOTH Places** (all hashes verified
  in-Studio == disk == manifest, drift GREEN in both):
  `TierConfig a0d6e3a3` · `StatGradeConfig 49a6edfd` · `AscensionConfig 59aa8e15` ·
  `ItemCatalog 789dca4b`. `tools/hash_shared.luau` now covers all EIGHT shared modules.
- **TierConfig reconciled** (A3 shape as base + the Lobby's multi-colour, per §2): 8-tier `Order`
  with `SortOrder` and the PascalCase API from A3; `Colors` LIST per tier plus
  `get`/`colorSequence`/`seamlessSequence`/`isMultiColor` lifted verbatim from the Lobby interim
  module. **Mythic rainbow (6 colours) and Secret red→dark-red preserved**; Common..Secret keep the
  Lobby's tuned on-screen values, Exclusive + Bathala keep A3's. `.Color` is DERIVED from
  `Colors[1]` so there is one authored source per tier and A3's `GetColor` contract still holds.
  Verified live: `isMultiColor("Mythic")=true` (6 colours), `seamlessSequence` returns 13
  keypoints with first == last (the seamless scroll wrap intact).
- **`LobbyServices.GetUnitViews`** (new RemoteFunction) — the A4/A5 contract. Per owned uuid:
  `Uuid, TowerId, Name, Tier` (both from ItemCatalog), `Level, XP, Trait, Shiny, Ascension,
  Worthiness, Locked, Favorited, Equipped` (uuid ∈ `Loadout`), raw `StatRolls`, and
  `Grades = {DMG,RNG,SPA}` letters from `StatGradeConfig`. Plus `Loadout`, `Currencies`,
  `PlayerXP/PlayerLevel`, `MaxLoadout`. Clients never read profiles (blueprint §5).
  Verified live: 8 units returned with correct tiers/levels/grades.

**DECISION (user, this session) — resolved stat NUMBERS deferred.** §1 assumed promoting
`TowerStatResolver` was a one-module move. It is not: `Resolve()` takes a whole **towerConfig**
(`Upgrades[tier]`, `BaseStats`, `Attack`) and internally requires `MetaScalingConfig` +
`TraitRegistry` + `TraitDefinitions` — so making the Lobby resolve numbers means putting ~12
modules including all 8 tower configs (AD-Game's most-tuned files) under drift control. Options
put to the user were (a) full stat stack, (b) a Game-generated slim stats catalog + boot
validator, (c) ship grades now / decide numbers at A6. **User chose (c).** Grades need nothing
but the roll, so A4/A5 get tiers, grades, borders and equipped state with ZERO new drift surface.
`TowerStatResolver` was therefore NOT promoted and stays Game canon.

**Scope corrections vs the proposal:**
1. **`UnitCatalog` was NOT deleted** (§3 said delete). Its deletion was contingent on §4 supplying
   real stats; with numbers deferred it is still the only source of the Units-screen DMG/RNG/SPA
   placeholders, so deleting it would have blanked that panel. It is **retired in place**: header
   rewritten to mark Name/Tier as duplicates of ItemCatalog (do not edit), delete outright at
   A4/A5. The interim Lobby `TierConfig` WAS fully replaced as specified.
2. **`ItemCatalog` needed a code change to be shareable** — it hard-required
   `TowerConfigRegistry`, which does not exist in the Lobby and would have failed to load there.
   That require is now lazy + optional; `Validate()` returns `(ok, errors, notes)` and reports the
   skipped Tower→TowerConfig cross-check in Places without tower configs. The Game still runs the
   full check — verified: `[Test] MetaConfig OK: ItemCatalog valid (13 entries), 8 tiers`.
   Also added `GetName`/`GetTier`.
- **`XpPct` not served:** the Lobby has no `TowerProgressionConfig`, so the XP curve is unknown
  there. Raw `XP` + `Level` are sent instead. Promoting that config (owner **AD-PlayerLevel**) is
  a small follow-up if a real XP bar is wanted — new PENDING.

**TWO INERT-SYSTEM FINDINGS (surfaced by verification, not fixed here):**
1. **Nothing ever calls `StatGradeConfig.RollAll`/`RollStat`.** Every unit in existence has
   hardcoded `StatRolls = {0.5, 0.5, 0.5}` — from the v1→v2 migration, `GrantUnit`'s default,
   `DevSetOwnedTowers`, and the Lobby starter grant. So **every grade in the game is "C"** and
   every quality multiplier is exactly the midpoint. A3 built the roller; no grant path wired it
   in. Until that lands, grades and BaseStats ranges are decorative. → PENDING (AD-Game).
2. **Nothing ever writes `Data.Loadout`.** Template inits it `{}`, migration sets `{}`, the Lobby
   only READS it. So `Equipped` is always false and `buildLoadout` always falls through to
   auto-loadout (top 6 by MetaLevel). **Equipping does not exist yet** — the unitView now carries
   the flag, but nothing can set it. → needs scheduling (see STATE).

- **Contract impact:** none — no save-schema or teleport change. Four NEW shared modules under
  drift control (manifest 4 → 8 entries); `OWNERSHIP.md` row for ItemCatalog/TierConfig (AD-UI)
  now points at `shared/src`.
- **PENDINGs:** A2-followup Integration promotion CLEARED. NEW: numbers decision at A6 (AD-Game +
  Integration), stat-roll wiring (AD-Game), `Data.Loadout` writer / equip UI (needs scheduling),
  TowerProgressionConfig promotion for XpPct (AD-PlayerLevel), UnitCatalog deletion at A4/A5.
  **USER: republish BOTH Places** — all of this is Studio canon.

## 2026-08-01 [integration/hotfix] LIVE BUG: empty hotbar in production matches — profile-load race before loadout validation

**Symptom (user, first live teleport-v2 run):** teleported into the match with NO units in any
hotbar slot, could not place anything, lost the match.

**Root cause — a race, not bad data.** `MatchEntryService` waited only for the party to be
*present* (`Players:GetPlayerByUserId`) and then called `MatchDirector.StartMatch`, which
validates loadouts SYNCHRONOUSLY via `LoadoutValidator` → `PlayerInventoryService.GetUnit` →
`getData(userId)`. When a profile has not finished loading, `getData` returns a deep copy of the
EMPTY `ProfileTemplate.Template` (`Units = {}`) — indistinguishable from "this player owns
nothing". So every loadout uuid was dropped as `NotOwned` and the player entered with an empty
hotbar. In a **reserved server the players are already present when the service boots**, while
ProfileStore still needs a DataStore round-trip — so losing this race is the DEFAULT live
outcome, not an edge case.

**Why Studio never caught it (A1/A2/A3 all passed):** the Studio entry path is
`MatchLifecycleSmokeTest`, which calls `DevSetOwnedTowers` — that populates the in-memory
stand-in synchronously *before* starting, so the profile is never actually raced. Every Studio
verification exercised a pre-seeded path. The production path had never once run with a real
cold profile. Note this is the SECOND live-only failure of the same symptom (2026-07-18 was
`Loadout={}` from the Lobby); both were invisible to Studio for the same structural reason.

- **Fix (`MatchEntryService`):** new `waitForProfiles(userIds)` runs AFTER `waitForParty` and
  BEFORE `StartMatch`, awaiting `PlayerDataService.WaitForData` per player
  (`PROFILE_LOAD_TIMEOUT = 20`). Logs `[MatchEntry] [DATA] All N profile(s) loaded (waited Xs)`.
  On timeout it does NOT wedge the match — it starts anyway but `warn`s loudly with the affected
  userIds (old behavior, now audible).
- **Fix (`PlayerInventoryService.getData`):** the silent empty-template fallback now `warn`s
  once per userId outside Studio (`profile NOT loaded … ownership check WILL report zero units`),
  so this failure class can never be invisible again. Diagnostic only — no behavior change; the
  Studio dev-seed path deliberately still uses the fallback.
- **Verified (Studio):** Game boots clean, `MetaConfig OK`, smoke-test path unchanged (the new
  wait is only on the MatchLaunch entry path), match reaches Countdown, no errors. **The real
  proof is the next live run** — Studio structurally cannot reproduce the race.
- **OWNERSHIP NOTE:** `MatchEntryService` + `PlayerInventoryService` are **AD-Game** canon
  (`Match lifecycle` row). Edited from the AD-Integration chat on explicit user instruction
  ("fix that") because the bug was blocking live play and was surfaced by the v2 rollout this
  chat landed. **PENDING for AD-Game: review this hotfix.** Design question left open for the
  owner: whether the wait belongs in `MatchDirector.StartMatch` itself (protecting every caller)
  rather than only the production entry path.
- **Contract impact:** none. No schema, payload, or shared-module change; manifest untouched.
- **Studio noise seen once:** client `WaitForChild` "Infinite yield possible" lines on one Play
  start; all ten StarterGui screens verified present + Enabled — Studio replication lag, not a
  regression.

## 2026-08-01 [game] Schema v2 wiring (blueprint A3): Meta configs + BaseStats pilots + resolver reads StatRolls

- **New `RS.Configs.Meta` (Game canon; promote to shared at A7):** `TierConfig` (Common→…→Bathala
  order + colors/sortorder), `StatGradeConfig` (D C B A S SS SSS Apex thresholds + `RollStat`/`RollAll`),
  `AscensionConfig` (MaxLevel 3, MinTier Mythic, absolute per-level DMG mults A1 ×1.05 → A3 ×3 +
  `PerTower` override + `GetMult`/`GetCost`), `ItemCatalog` (13 entries: 8 towers tier-assigned +
  Gold/Silver + BannerTicket/TraitRerollToken/GoldenSeed, `Tradeable=false`, `Validate()`).
  New Studio-only `MetaConfigTest` runs `ItemCatalog.Validate()` at boot.
- **BaseStats pilots:** Archer + Mage gain top-level `BaseStats = { DMG/RNG/SPA = {Min,Max} }`
  quality-multiplier ranges (strength; higher = stronger). Other towers have none (flat 1.0).
- **`TowerStatResolver` reads rolls (the A3 fix):** new optional `statRolls` + `ascension` params.
  For DMG/RNG/SPA it folds a per-unit quality multiplier `rollStrength (Min+(Max-Min)*roll) ×
  AscensionMult` into the existing tier×meta×trait pipeline — multiplied for normal stats, DIVIDED
  for the inverted SPA (so roll 1.0 = fastest). Default (no BaseStats / nil roll / asc 0) = 1.0, so
  scalar towers are byte-identical. Threaded: `LoadoutValidator` entry (+Uuid already; now +StatRolls
  +Ascension from the unit) → `PlacementValidator` → `TowerManager.PlaceTower` → `TowerController`
  (stored; re-resolved on upgrade). `ResolveNextTier` passes them through.
- **Scope (blueprint-faithful):** compose model chosen with the user = quality multiplier (least
  invasive, preserves balance). NOT in A3 (later phases): teleport/loadout already v2 (A2); Counters/
  Worthiness increments; UI kit wiring (A4–A6) — so client stat PREVIEWS still resolve at rollMult 1.0
  for now (server gameplay is roll-correct). Combat/placement/`MatchStatsTracker` unchanged (§7).
- **Verified:** resolver unit tests — scalar tower (Knight) asc 0 byte-identical with/without rolls;
  Archer roll 0.5 == old; roll 0/1 moves DMG ±15% and SPA (roll 1 faster); ascension 3 = ×3 DMG;
  Necromancer asc 2 = ×1.5 DMG; `ItemCatalog.Validate` ok (0 errors). Play-test — `schema v2` boot,
  `[Test] MetaConfig OK (13 entries, 8 tiers)`, profile v2 loaded, match to Countdown, no errors.
- **Contract impact:** none — save schema stays **v2** (StatRolls already in the v2 shape; A3 only
  reads them). No shared-module (manifest) change; all A3 code is Game Studio canon.
- **PENDINGs:** A3 CLEARED. Next: A4/A5 (AD-UI) wire the kit to resolved stats + real rolls. The
  BLOCKING user publish PENDING now also covers A3's Game changes (publish Game + Lobby together).

## 2026-08-01 [integration] A2: schema v2 to the Lobby + teleport contract v2 (uuid loadouts) — Phase A unblocked

Blueprint `phase-a-foundations.md` §2 + §9 A2. Both Places driven in one session (AD-Integration).

- **ProfileTemplate v2 → Lobby:** deployed verbatim from `shared/src` (`184cdfad → 63a0c98a`,
  hash computed in-Studio == manifest == Game). `manifest.deployed.Lobby` updated;
  **drift check now GREEN in BOTH Places** for all four shared modules.
- **Lobby v2 reads (Studio canon):**
  - `LobbyServices.GetCollection` serves uuid-keyed `Units` (TowerId/MetaLevel/XP/Trait/Shiny/
    StatRolls/Ascension/Worthiness/Locked/Favorited/ObtainedAt), `Loadout`, `Currencies` and
    `PlayerLevel`. **Interim compat:** it also still returns `Towers` (collapsed to the highest-
    MetaLevel instance per TowerId) and `Currency` (= Gold) so the not-yet-rebuilt CollectionScreen
    + UnitsGUI keep working — **remove both at A5** (new PENDING; they are the only readers).
  - `StarterChoiceService`: eligibility is now `Units` empty; the grant writes a uuid
    `UnitInstance` mirroring the Game's `PlayerInventoryService.GrantUnit` (mid rolls 0.5 until
    A3), returns the `Uuid`, and the sim-tower self-heal scans by `TowerId`.
  - `PartyService.buildLoadout`: returns **uuids** — the saved profile `Loadout` filtered to
    still-owned uuids (deduped, capped at `MaxLoadoutSize`), else auto-loadout by MetaLevel desc.
- **Teleport contract v1 → v2** (`docs/contracts/teleport.md`, version history + shapes updated).
  Only change: `Players[uid].Loadout` carries unit uuids. `LobbyConfig.MatchLaunchVersion = 2`
  and `GameConfig.TeleportPayloadVersion = 2`; `MatchReturnService` now READS its expected version
  from `LobbyConfig` instead of a hardcoded `1` (one integer covers both directions).
  **Hard cutover, no migration:** both Places deploy together, so v1 is rejected, never fallen back
  to. Game-side code needed no logic change — `MatchEntryService` already passed `Loadout` through
  to `LoadoutValidator` (uuid-aware since A1); only the version constant + comments moved.
- **Verified (Studio, both Places):**
  - Game boot: `[DATA] PlayerDataService ready (schema v2)`, `[CONTRACT] Profile v2 loaded`
    (Beta1_PlayerDataDev1, Access), `[MatchEntry] Ready`, match reaches Countdown, no errors.
  - `BuildRawConfig` unit tests: v2 accepted (uuids preserved, string→numeric userId keys), **v1
    rejected** (`[CONTRACT] PayloadVersion mismatch: got 1, expected 2`), unknown stage rejected,
    difficulty 999999 → 1000.
  - Lobby boot: `[CONTRACT] Lobby boot: save-schema v2`, `MatchReturn v2 receiver`, `teleport
    contract v2`, UI kit + hotbar + Units controllers all init clean, no compile errors.
  - Live remote reads: `GetCollection` → 8 uuid Units (rolls present) + compat layer intact;
    real `RequestLaunch` → `[DIAG] Launch loadout: [6 uuids]` then `[Teleport] launch failed:
    HTTP 403` (expected — Studio cannot ReserveServer).
  - Starter grant path (`DevSimulateFirstJoin`): offer eligible → granted uuid
    `945f74d5-…` with the exact GrantUnit field set; next clean boot self-healed the sim unit
    (`[Test] removed leftover SimTestTower`) and correctly reported ineligible. Sim attribute OFF.
- **Contract impact:** teleport **v1 → v2** (no migration — atomic cutover). Save schema
  unchanged at v2; shared module deployed, not edited (manifest `deployed.Lobby` only).
- **PENDINGs:** A2 CLEARED. NEW — **USER must publish BOTH Places together** (live is mid-cutover;
  a partial publish breaks launches with a version mismatch). NEW — A5 removes the compat fields.
  Carried: A3 (resolver reads StatRolls), persistence round-trip, Studio-doc migration.
- **Note:** STATE.md was over its 100-line cap; resolved PENDINGs were trimmed out (history lives
  here) — now 102 lines.

## 2026-08-01 [game] Schema v2 (blueprint A1): uuid unit instances + Currencies map + migration

- **Contract change — save schema v1 → v2** (owner AD-Game, `docs/blueprints/phase-a-foundations.md`
  A1). `ProfileTemplate` (SCHEMA_VERSION=2): towerId-keyed `Towers` → uuid-keyed `Units`
  (UnitInstance: TowerId/MetaLevel/XP/Trait/Shiny/StatRolls/Ascension/Worthiness/Locked/Favorited/
  SpiritUuid/ObtainedAt); scalar `Currency` → `Currencies` map (Gold/Silver/TraitRerolls/StatRerolls/
  EventTokens); added PlayerLevel/Loadout/Pity/Counters/Quests/LoginStreak/ShopStock/Titles/Spirits/
  Battlepass. `Migrations[1]` converts v1→v2 (Currency→Gold, each Towers entry→a Units instance with
  mid rolls 0.5, Loadout={}); Reconcile fills the rest; account XP/items/settings preserved. STORE_NAME
  stays Beta1_PlayerData(Dev1).
- **Game service uuid refactor (Studio canon):** `PlayerInventoryService` now Units/uuid-keyed
  (`GetUnit`/`GetAllUnits`/`GrantUnit`/`GetFirstUnitId`, `Owns` by TowerId across instances,
  `AddTowerXP(userId, uuid)`, `AddCurrency`→`Currencies.Gold`, `DevSetOwnedTowers` seeds instances +
  returns a towerId→uuid map; back-compat `GetOwnedTower`/`GrantTower` shims kept). `LoadoutValidator`
  validates **uuid** lists (entry now carries `Uuid`; `FindEntry` stays by TowerId). `RewardCalculator`
  commits tower XP by **uuid** + reads `Currencies.Gold`. Smoke test + `MatchActionHandler` build uuid
  loadouts; `MatchEndVerify` updated. **Combat / placement / MatchStatsTracker unchanged** (§7): stats
  stay towerId-keyed and the uuid is resolved from the loadout at the commit boundary.
- **NOT in A1 (later phases, by blueprint):** StatRolls resolver + BaseStats ranges (A3), teleport v2
  uuid loadouts (A2), Counters/Worthiness increments + UI (later). StatRolls persist now but the
  resolver ignores them until A3.
- **Deploy/verify:** drift-clean before edit (Game+disk `184cdfad`). ProfileTemplate edited Studio +
  `shared/src` byte-identical → new hash **`63a0c98a`** (python fnv1a == Studio). `manifest.json`:
  hash + `deployed.Game` → `63a0c98a`; **`deployed.Lobby` left `184cdfad` (STALE)**. Verified:
  migration unit test (Currency 80→Gold 80, 2 Towers→2 Units mid-rolls, Loadout={}, XP/items kept);
  Play-test — `[DATA] PlayerDataService ready (schema v2)`, smoke seeded 8 Units, `[DIAG]` loadout
  5 uuids → 5 validated / 0 rejected, `AddTowerXP` by uuid ok, match to Countdown, no errors. Temp
  `[DIAG]` removed after.
- **Contract impact:** save schema **v1 → v2** (migration shipped).
- **PENDINGs:** NEW (A2 / AD-Integration): deploy ProfileTemplate v2 to Lobby (Lobby drift FAILS
  until then), fix Lobby compile to read Units/Loadout, flip teleport v2 (uuid loadouts) both sides,
  e2e. THEN USER republishes both Places. Note: Game service refactors are Studio-canon (not git) —
  **USER must save/publish the Game place**.

## 2026-07-31 [lobby] AD-UI: reusable Button kit + hotbar preview + Units screen + Tier system

- **`UIKit.Button`** (`ReplicatedStorage.Shared.UIKit.Button`, client) — ONE reusable button
  controller replacing per-button scripts. Hover (scale from centre via `centerAnchor`, stroke
  thicken OR `HoverStrokeColor`, icon rotate), press animation, seamless (tiled) animated
  gradient. Attribute-driven; API attach/create/onActivated/onHover/setHovered/setText/setIcon/
  setStrokeColor/setEnabled. Tag-based bootstrap `StarterPlayerScripts.UIKitBootstrap` attaches
  any `UIKitButton`-tagged GuiButton (tags copy to clones).
- **Hotbar** rebuilt on the kit (`Hotbar.HotbarController`): single controller, old duplicated
  per-slot scripts disabled; fixes the random-glow bug (root cause: N copied scripts + overlap).
  Shows `Hotbar.Templates.UnitPreviewTemplate` on hover.
- **Units screen** (`StarterGui.UnitsGUI.UnitsController`): opens from HUD Units; loads owned
  units (v1 `GetCollection`); tier-coloured card border + BG (animated seamless); hover → white
  border + centre-scale + right-side `UnitPreviewTemplate` popup (name/tier/DMG-RNG-SPA + model);
  click → `SelectedUnitFrame` framed viewport + Stats (reusing the preview design); sort
  equipped>favourited>tier(high→low)>name; live search; placeholder model
  `ReplicatedStorage.UnitModels.Placeholder`. Action buttons animation-only.
- **Tier system (editable):** `RS.Configs.Meta.TierConfig` (tier → colour list; one = solid,
  many = seamless animated gradient — Mythic rainbow, Secret red→dark-red) + `UnitCatalog`
  (towerId → Tier + placeholder DMG/RNG/SPA + optional Equipped/Favorited). Verified live in Play.
- **HUD buttons** (`HUD.Left.Buttons.*`) tagged + animated; `Frame.BorderDesignInside` hidden;
  hover = white stroke (no thicken).
- **Constitution compliance:** all UI is REAL instances (Studio-editable); controllers only
  clone/fill/wire. UI kit + configs are **Studio (Lobby) canon** for now (per hybrid model);
  documented here + in `places/lobby/CONTEXT.md`. Proposal `docs/proposals/2026-07-31-ui-kit-button-primitive.md`
  (Button primitive) is now IMPLEMENTED interim; user-directed (approved live).
- **Contract impact:** none (no schema/teleport change; reads existing `GetCollection`).
- **PENDINGs:** deferred to schema v2 / A3 — real per-unit models, resolved DMG/RNG/SPA, real
  Loadout(equipped)+Favorited, functional action buttons; promote `UIKit`/`TierConfig`/`UnitCatalog`
  to `shared/src` at Integration if the Game place needs them. **USER: save + republish the Lobby.**
- **Open threads:** commit is LOCAL (push pending). Studio place must be saved by the user
  (Studio-canon code is not in git).

## 2026-07-31 [lobby] Drift reconcile: ProfileTemplate store rename (Beta1 reset) — Lobby+disk done, Game PENDING

- **Bootstrap drift check (AD-UI session, Lobby active) caught a mismatch:** live Lobby
  `ProfileTemplate` = `184cdfad`, disk/manifest = `8ac5d3e9`. STOPPED per constitution.
- **Cause (user-confirmed):** intentional **beta data reset** — `STORE_NAME` changed
  `"PlayerData" → "Beta1_PlayerData"` and the Studio dev suffix `"_Dev" → "Dev1"` (dev store
  `PlayerData_Dev → Beta1_PlayerDataDev1`), done directly in the Lobby Studio. No other diff;
  `SCHEMA_VERSION` stays 1, `Towers = {}` unchanged — store target change, no data-shape
  change, no migration.
- **Reconciled the ledger to reality:** disk `shared/src/ProfileTemplate.luau` edited to the
  beta store name (re-hashed to **`184cdfad`**, python fnv1a32 == the Studio drift hash, i.e.
  byte-identical to the live Lobby source). `manifest.json` hash → `184cdfad`,
  `deployed.Lobby → 184cdfad`. `docs/contracts/save-schema.md` store-name line updated with a
  dated note. `deployed.Game` LEFT at `8ac5d3e9` (stale) on purpose — see below.
- **Ownership note:** `ProfileTemplate` is AD-Game canon; this reconcile was done by the AD-UI
  chat under an explicit user directive ("do whatever prevents future problems") to correct a
  stale/dangerous ledger. AD-Game still owns the formal contract re-verification.
- **Contract impact:** save schema stays **v1** (store target only). **CRITICAL PENDING
  (AD-Game + USER):** the Game place was NOT connected this session, so its store name is
  UNVERIFIED. If Game still points at `PlayerData` while Lobby points at `Beta1_PlayerData`,
  the two Places read DIFFERENT stores (split-brain — lobby and match see different profiles).
  AD-Game must open the Game place, deploy the same store name, verify `184cdfad`, set
  `manifest.deployed.Game = 184cdfad`.
- **Open threads:** UI-kit Button/PlayerLevelBar proposal (2026-07-31) still FOR REVIEW.
  Hotbar glow bug not yet investigated (read-only inspection to follow this reconcile).

## 2026-07-18 [game] ProfileTemplate: remove seeded starter Archer (Towers = {}) — starter choice unblocked

- **Shared-module change (owner AD-Game):** `ProfileTemplate.Template.Towers` seed
  `{ Archer = { MetaLevel = 1, XP = 0 } }` → `{}`, per proposal
  `docs/proposals/2026-07-18-starter-choice-template.md`. Fresh accounts now own zero towers, so
  the Lobby's first-join starter choice (eligibility = zero owned) actually fires.
- **No `SCHEMA_VERSION` bump** — default-value change only, no shape change, no migration.
  Existing profiles keep their `Towers.Archer` (`Reconcile()` only ADDS missing keys, never removes).
- **Scope decision:** the blueprint (phase-a A1) had folded this into the schema-v2 session and
  marked the standalone proposal "superseded"; **user explicitly chose the standalone unblock now**
  (this session). A1 will re-touch `Towers` when it migrates to uuid `Units` — no conflict.
- **Drift/deploy:** disk canon + `manifest.json` updated to new hash **`8ac5d3e9`**; source edited
  byte-identical in both Places. Deployed to **BOTH Game and Lobby** (both live sources verified
  `8ac5d3e9` via `.Source`; cache-free "no Archer seed / `Towers = {}`" source check on Game).
  `manifest.json` `deployed` = both `8ac5d3e9`; drift-clean, no stale Place.
  - **Place-binding note (process):** the Studio instances had restarted between sessions and the
    active instance was **Lobby** at the start of this task; the first edit landed on the Lobby
    before I re-resolved binding. Caught via the doc-mirror step, re-confirmed both instances by
    name + PlaceId, then deployed the identical change to Game. Net result is a valid both-Places
    deploy (AD-Game owns shared-module deploys to both), so no rework beyond correcting the manifest
    `deployed` map. Lesson: re-resolve Place binding at the TOP of every task, not just first boot.
- **Docs:** `save-schema.md` new-profile defaults + version history updated (still v1).
- **Contract impact:** save schema stays **v1** (default change only).
- **PENDINGs:** starter-seed PENDING CLEARED. No Lobby redeploy needed (already deployed).
  USER: republish both Places + re-run the live loop (fresh-account picker + towers-in-match).

## 2026-07-18 [repo] Implementation blueprints for all meta phases + blueprint discipline

- NEW `docs/blueprints/phase-a-foundations.md`: schema v2 EXACT shape (unit instances,
  Currencies, Counters, ...) + 1→2 migration steps + starter-seed removal folded in +
  teleport v2 + TierConfig/StatGradeConfig/AscensionConfig/ItemCatalog shapes + base-stat
  ranges & resolver formula (SPA inverted) + icon-kit templates/controller APIs + counters
  pipeline + phase acceptance + session plan A1–A7 with owners.
- NEW `docs/blueprints/phases-b-f-meta.md`: MetaMath (deterministic slot rotation),
  GrantService (single grant pipeline), exact summon algorithm order, per-phase config
  shapes + session plans (B1–F5) + cross-phase invariants checked at Integration.
- Constitution: new "Blueprint discipline" section (blueprints are law; one session-task
  per session; no improvisation; proposal when blocked). Feature prompt updated to match.
- ROADMAP + INDEX link the blueprints.
- **Contract impact:** none yet — blueprints PRE-authorize schema v2 & teleport v2 shapes;
  the A1/A2 sessions execute them under the normal contract protocol.
- **Open threads:** starter-seed PENDING is folded into blueprint task A1 (supersedes the
  standalone proposal); persistence round-trip test still open.

## 2026-07-18 [lobby+repo] Constitution: no UI in scripts; StarterChoiceScreen rebuilt as instances

- **New constitution rule (USER-ordered; recorded here as the authorization for an AD-Lobby
  session touching AD-Integration's repo canon):** NEVER generate UI in scripts. UI = real
  Instances in StarterGui (Studio-editable); dynamic lists = designed `*Template` instance
  (Visible=false) cloned by the controller; controllers do behavior only. Added to
  CLAUDE.md editing rules. Legacy script-built screens are converted when next touched.
- **StarterChoiceScreen converted first:** static tree now real instances —
  `Root{Dim, Panel{Title, Subtitle, CardsRow{CardTemplate}, ConfirmButton}}`; CardTemplate
  is the designed card (NameLabel/TaglineLabel/DescLabel/SelectButton + Sel stroke).
  Controller rewritten to clone/fill/wire only (no Instance.new for visuals).
- **Verified live (Play):** sim ON — Root visible, 4 cards cloned from template
  (Archer/Knight/Mage/SimTestTower), grant path OK; sim OFF — silent boot, sim tower
  auto-cleaned. Sim left OFF.
- **Legacy screens still script-built** (convert when next touched): CollectionScreen,
  StageSelectScreen, PartyScreen, ReturnScreen (Lobby); Game-place screens per AD-Game/AD-UI.
- **Contract impact:** none. **PENDINGs:** unchanged (AD-Game ProfileTemplate starter-seed
  removal still open — user confirmed live test still auto-grants Archer, as expected).

## 2026-07-18 [lobby] Starter tower choice (first join) + launch loadout fix; LIVE e2e confirmed by user

- **LIVE e2e CONFIRMED (user, production client):** lobby → reserved match → return →
  MatchReturn Defeat banner all worked. The Integration session's live-e2e USER PENDING is
  **CLEARED**. The defeat exposed a real bug (below).
- **Launch loadout fix:** `PartyService` sent `Loadout = {}` in every `MatchLaunch`, so
  players entered matches with ZERO placeable towers (Game-side the loadout is the hotbar
  cap — LoadoutValidator, max 6, read-only peek at Game). Now `buildLoadout(userId)` sends
  owned towers (highest MetaLevel first, then alphabetical), capped by new
  `LobbyConfig.MaxLoadoutSize = 6`. Interim until a loadout-picker UI lands. `[DIAG]` logs
  each player's sent loadout at launch.
- **Starter tower choice (first join):** new dev-editable `RS.Configs.StarterTowerConfig`
  (Archer/Knight/Mage; edit that one file to change the offer), new
  `SSS.Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`,
  new modal `StarterGui.StarterChoiceScreen` (3 cards, select + confirm, no dismiss).
  Eligibility = profile owns ZERO towers. Grants `{MetaLevel=1, XP=0}` straight into the
  shared profile; never clobbers an existing record; rejects ineligible/unknown picks.
- **[Test] harness:** `DevSimulateFirstJoin` attribute forces the offer in Studio + adds a
  sim-only "SimTestTower" card to exercise the real grant path; leftover sim tower is
  auto-removed on any non-sim boot. Left OFF.
- **Verified live (Play, dev store):** sim ON — offer shown (4 cards), SimTestTower granted
  (`[DATA] granted starter`), owned Archer pick skipped (no clobber), out-of-offer
  Necromancer rejected, launch `[DIAG]` loadout = 6 towers (Archer first), real teleport
  attempt failed handled in Studio (expected). Sim OFF — silent boot, leftover sim tower
  auto-removed (`[Test]`).
- **Contract impact:** none — teleport stays v1 (payload shape unchanged; Loadout now
  actually populated). Save schema untouched THIS session, but see PENDING.
- **PENDINGs:** NEW (AD-Game): remove seeded starter Archer from `ProfileTemplate`
  (`docs/proposals/2026-07-18-starter-choice-template.md`) — until it lands, fresh accounts
  auto-own Archer and the picker stays inert (by design, data-driven eligibility).
  Integration live-e2e PENDING cleared (above).

## 2026-07-18 [integration] First Integration session: drift-clean both Places, LobbyPlaceId verified, teleport loop config-complete

- **Drift check BOTH Places:** all four shared modules (ProfileTemplate, PlayerDataService,
  ProfileStore, Signal) hash-match `shared/manifest.json` in Game AND Lobby. Zero drift.
- **PENDING cleared — `GameConfig.LobbyPlaceId`:** found already set to **83342803778137**
  in the Game Place; verified equal to the live Lobby instance's `game.PlaceId`. Stale
  "STUBBED 0" comment cleaned (comment-only edit, mirrors last session's Lobby cleanup).
  Teleport loop is now CONFIG-COMPLETE on both sides (Game=125430066355564, Lobby=83342803778137).
- **`[CONTRACT]` verification, Game (Play):** `[MatchEntry] Ready (waiting for MatchLaunch
  teleport data)`, smoke-test fallback single-started Stage1_Act1, `[DATA] [CONTRACT] Profile
  v1 loaded` (PlayerData_Dev, DataStoreState=Access), no contract warnings.
- **`[CONTRACT]` verification, Lobby (Play, DevSimulateReturn ON→OFF):** `[CONTRACT] Lobby
  boot: save-schema v1`, `[DATA] [CONTRACT] MatchReturn v1 accepted (Victory Stage1_Act1 →
  suggest Stage1_Act2)`, ReturnScreen banner + StageSelect pre-select `[DIAG]`s all fired.
  Sim attribute returned to OFF.
- **Cross-Place e2e:** NOT run — real TeleportAsync is impossible in Studio. New USER-ACTION
  PENDING: publish both Places, run the live loop in the Roblox client (lobby → reserved
  match → return → banner).
- **Note (Game, Studio Play):** with LobbyPlaceId set, pressing Lobby in Studio Play now
  attempts a real teleport and fails handled (pcall + TeleportInitFailed) — expected.
- **Contract impact:** none. Teleport stays v1; no shared-module changes; manifest untouched.
- **Open threads:** live e2e (user, above); persistence round-trip test (Game); progressive
  Studio-doc migration. Push pending (commit is local).

## 2026-07-18 [lobby] MatchReturn v1 handling + GamePlaceId set (teleport loop Lobby-side complete)

- **GamePlaceId set:** `RS.Configs.LobbyConfig.GamePlaceId = 125430066355564` (found already set
  in Studio this session — stale STUB comment cleaned). The Lobby-side USER-ACTION PENDING is
  **CLEARED**; real launches now go all the way through ReserveServer + TeleportAsync.
- **MatchReturn v1 receiver:** new `SSS.Server.Lobby.MatchReturnService` (Script). Reads
  `Player:GetJoinData().TeleportData.MatchReturn` on join, validates PayloadVersion==1 /
  LastStageId / Outcome∈{Victory,Defeat,Abandoned} (`[CONTRACT]` warn + ignore on mismatch),
  drops `SuggestNextActId` unknown to the Lobby's StageRegistry mirror (stale mirror fails
  safe), serves per-player via new `Remotes.GetMatchReturn` RemoteFunction. Display-only:
  never mutates the profile (rewards were committed Game-side per the contract).
- **Welcome-back UI:** new `StarterGui.ReturnScreen` banner — outcome (Victory/Defeat/
  Abandoned), stage name, CONTINUE button (only on Victory with a valid successor) + BACK TO
  LOBBY. CONTINUE fires new client bus `RS.ClientEvents.OpenStageSelect` (BindableEvent).
- **StageSelect pre-select:** `StageSelectScreen.Controller` now listens to `OpenStageSelect`
  (opens panel + selects stage) and silently pre-selects `SuggestNextActId` after loading
  stages, so the picker lands on "continue the campaign".
- **Studio harness:** `DevSimulateReturn` attribute on MatchReturnService fabricates a
  Victory/Stage1_Act1→Act2 payload in Studio (`[Test]` log) since real return teleports can't
  happen in Studio. Left OFF.
- **Verified live (Play):** with sim ON — `[Test]` + `[DATA] [CONTRACT] MatchReturn v1 accepted`,
  `[DIAG] StageSelect: pre-selected suggested next act Stage1_Act2`, `[DIAG] ReturnScreen:
  showing MatchReturn banner (Victory)`; CONTINUE path → `[DIAG] StageSelect: OpenStageSelect
  pre-selecting Stage1_Act2`, panel visible, button text "CONTINUE: Rising Legend (Stage 1 -
  Act 2)". With sim OFF — clean boot, no banner, no [DIAG] (silent path confirmed).
- **Contract impact:** none — teleport stays **v1** (Lobby now consumes `MatchReturn`; no shape
  change). No shared-module change; manifest untouched (drift check clean at bootstrap).
- **PENDINGs:** Lobby GamePlaceId CLEARED. Remaining for end-to-end: USER sets
  `GameConfig.LobbyPlaceId` (Game side), then the first AD-Integration session
  (lobby → reserved match → return → banner).

## 2026-07-18 [game] Teleport handoff Game-side: MatchLaunch receiver + real ReturnToLobby

- **Production entry receiver:** new `SSS.Server.MatchEntryService` (ModuleScript, booted by
  `ReplicationBridge` after the data services). Reads `TeleportData.MatchLaunch` (teleport
  contract **v1**) off join data, validates PayloadVersion==1 / StageId∈StageRegistry / Players,
  converts JSON string userId keys → numeric, sanitizes DifficultyPercent (`DifficultyConfig`),
  resolves map/mode/difficulty from the stage, waits for the party to assemble (10s timeout),
  and calls `MatchDirector.StartMatch` **exactly once**. Trust stance per contract: TeleportData
  is a request — loadout ownership + host authority are re-checked downstream (LoadoutValidator /
  MatchDirector). Pure `BuildRawConfig(payload)` exported + unit-tested (valid/reject/clamp cases).
- **Smoke test → Studio fallback:** `MatchLifecycleSmokeTest` still auto-starts Stage1_Act1 in
  Studio, but now stands down when a MatchLaunch payload is present, so the two never double-start.
- **Real ReturnToLobby:** `MatchActionHandler` now builds the `MatchReturn` v1 payload
  (PayloadVersion, LastStageId, Outcome, SuggestNextActId — next act only on a Victory with a
  successor) and `TeleportService:TeleportAsync` back to the Lobby. Guarded on
  `GameConfig.LobbyPlaceId==0` (logs `[Teleport]` + skips, mirroring the Lobby's GamePlaceId guard);
  wrapped in pcall + listens to `TeleportInitFailed`.
- **New `RS.Configs.Global.GameConfig`** — cross-Place counterpart to LobbyConfig:
  `TeleportPayloadVersion=1`, `LobbyPlaceId=0` (stubbed), `HasLobbyPlace()`.
- **Verified:** BuildRawConfig unit tests pass (string→numeric keys, [CONTRACT] rejects for bad
  version / unknown stage / no players, difficulty clamp 999999→1000 & nil→100, MatchReturn
  next-act rule). Play-test: `MatchEntryService` boots + stands down with no teleport data, smoke
  fallback starts the match, single start, no warnings.
- **This Game place id = `125430066355564`** (for the Lobby's `LobbyConfig.GamePlaceId`).
- **Contract impact:** none — teleport stays **v1** (Game is the consumer; no shape change).
- **PENDINGs:** receiver PENDING CLEARED. NEW (USER ACTION): set `GameConfig.LobbyPlaceId` to the
  real Lobby place id. Still open: user sets `LobbyConfig.GamePlaceId=125430066355564` (Lobby side);
  persistence round-trip test; Studio Documentation migration.

## 2026-07-18 [repo] Meta-systems design approved + ROADMAP v2 + constitution advisory

- Meta-systems proposal (docs/proposals/2026-07-18-meta-systems-design.md) reviewed and
  APPROVED with decisions: apex tier **Bathala**; secret rate ~0.005%; dupes → **Ascension**
  (1 dupe + artifacts, or sell for Silver); stat grades **D C B A S SS SSS + Apex**;
  everything untradeable at launch.
- ROADMAP.md rewritten: current Game/Lobby/Cross-Place status + phased meta roadmap
  (A Foundations: schema v2/unit instances + ItemCatalog + icon kit → B Gacha → C Unit
  depth → D Economy loops → E Seasonal → F Endgame/social).
- OWNERSHIP.md: added AD-UI (ItemCatalog/TierConfig/icon kit), AD-Meta, expanded
  AD-Gacha/AD-Traits rows.
- CLAUDE.md landing checklist step 8: mandatory session-end USER ADVISORY (new PENDINGs +
  which chat acts next, other-Place staleness, git push reminder, user personal actions).
- **Contract impact:** none yet — but Phase A = schema v2 + teleport v2 (unit-instance
  uuids); AD-Game owns that migration; no meta work may start before it lands.
- **Open threads:** MatchLaunch receiver + GamePlaceId PENDINGs still open (unchanged).

## 2026-07-17 [lobby] Lobby v1 scene/flow: blockout, collection, stage select, party teleport

- **Blockout:** `Workspace.Lobby` hub (gold plaza + "alamat" sun emblem, pillars, title wall,
  COLLECTION/PLAY wayfinding pedestals); spawn repositioned onto the plaza; modest lighting/atmosphere.
- **Read-only collection screen** (proves profile sharing end-to-end): `Server.Lobby.LobbyServices`
  wires `GetCollection`/`GetStages` RemoteFunctions (READ-ONLY against the profile). Client
  `StarterGui.CollectionScreen` lists owned towers (MetaLevel/XP/Trait). Verified live: returned the
  same PlayerData_Dev profile the Game seeded (8 towers incl. Archer Lv100/Godly, Mage/Blitz, ...).
- **Stage select + difficulty:** Lobby-local mirror `RS.Configs.StageRegistry` (Stage1_Act1..Act3,
  NextActId chaining, difficulty 1–1000). `StarterGui.StageSelectScreen` = stage list + draggable
  difficulty slider capturing (StageId, DifficultyPercent).
- **Teleport handoff (contract v1):** finalized `docs/contracts/teleport.md` v0→v1 — reserved
  (private) server per party, party assembly carried in the `MatchLaunch` payload, `PayloadVersion=1`.
  `RS.Configs.LobbyConfig.GamePlaceId` **stubbed 0** (user to fill). `Server.Lobby.PartyService`:
  in-memory parties (invite/accept/leave, host-only launch, max 4) + `ReserveServer` +
  `TeleportToPrivateServerAsync`; guarded on GamePlaceId==0. `StarterGui.PartyScreen` = party UI
  (members, invite, incoming-invite prompt, leave). Verified live: solo party assembles, launch
  path validates stage + sanitizes difficulty and hits the guard (logs `[Teleport]` would-launch).
- **Contract impact:** teleport payload **v0 draft → v1** (owner AD-Lobby). Save schema unchanged (v1).
- **PENDINGs opened:** (1) user sets `LobbyConfig.GamePlaceId`; (2) AD-Game builds the production
  receiver: read `TeleportData.MatchLaunch` (v1) → validate → `MatchDirector.StartMatch` (replaces
  the Studio-gated smoke test as the non-Studio entry path).

## 2026-07-17 [lobby] First AD-Lobby session: shared-module deploy + boot + Signal promotion

- **Shared deploy (Lobby):** created `ReplicatedStorage.Shared` (Signal, ProfileTemplate) and
  `ServerScriptService.Server.Data` (ProfileStore, PlayerDataService). Sources deployed
  verbatim from `shared/src/`; hashes verified against the manifest via `tools/hash_shared.luau`
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39, ProfileStore 1e3a6f3f, Signal 91becf7a).
  `manifest.json` `deployed.Lobby` filled for all four. No drift.
- **Signal promoted to shared canon:** Signal (a `PlayerDataService` dependency) previously
  lived only in the Game place. Added `shared/src/Signal.luau` (byte-identical to the live
  Game source, 91becf7a), registered it in `manifest.json` (owner: game, covered by the
  shared/src deploys row in OWNERSHIP.md), and added it to `tools/hash_shared.luau`'s MODULE
  list so drift checks now cover it. Game already runs this exact Signal (deployed 91becf7a,
  re-verified live this session).
- **Boot:** new `Server.Bootstrap` (Script) requires ProfileTemplate + PlayerDataService,
  asserts the save contract, and calls `PlayerDataService.Init()`. Verified live in Play mode:
  `[CONTRACT] Lobby boot: save-schema v1, store=PlayerData_Dev` and
  `[DATA] [CONTRACT] Profile v1 loaded for SuperiorBeing_S (store=PlayerData_Dev, DataStoreState=Access)`.
  Confirms the Lobby shares the same schema-v1 profile + dev store as the Game place.
- **Contract impact:** none — save schema still v1 (no shape change); teleport still v0 draft.
- **Open threads:** Lobby v1 scene work next (blockout spawn → read-only collection screen →
  stage select + difficulty → teleport handoff, which finalizes `teleport.md` v0→v1 and adds a
  PENDING for the AD-Game receiver). The Lobby shared-module deploy PENDING is now CLEARED.

## 2026-07-17 [game+repo] Dev-store separation + multi-chat constitution + GitHub prep

- **Dev store:** `ProfileTemplate.GetStoreName()` → "PlayerData_Dev" whenever
  `RunService:IsStudio()`; PlayerDataService uses it. Studio playtests/dev seeds can no
  longer touch production data. Verified live with API access ON:
  `store=PlayerData_Dev, DataStoreState=Access`. Shared canon + manifest rehashed
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39; Game deployed, Lobby still PENDING).
- **Constitution v2:** chats now bound to SYSTEMS (not Places); Place binding resolved at
  bootstrap via `list_roblox_studios` + name confirmation ("Alamat Defense - Game" /
  "Alamat Defense - Lobby"); new multi-chat sync rules (changelog = event bus, re-read
  STATE+changelog before landing, single-writer, no simultaneous same-Place editing).
  New `docs/OWNERSHIP.md` registry (UI, Gacha, PlayerLevel, TowerModels, Enemies, Traits...).
- **Places:** Lobby place created on Roblox (empty); Studios renamed accordingly.
- **Contract impact:** save-schema doc updated with the dev-store rule (still v1 — shape
  unchanged, only store selection).
- **Open threads:** Lobby shared-module deploy still PENDING; persistence round-trip test.

## 2026-07-17 [game] ProfileStore adoption (schema v1) + bug fixes + repo bootstrap

- **Persistence:** adopted ProfileStore (loleris). New `Shared.ProfileTemplate` (SCHEMA_VERSION=1,
  store "PlayerData"; Data = {SchemaVersion, PlayerXP, Currency, Items, Towers, Settings};
  starter Archer Lv1). New `Server.Data.PlayerDataService` (session lock, Reconcile+Migrate,
  ProfileLoaded/Released signals, kick on failed session). `PlayerInventoryService` and
  `SettingsService` rewritten profile-backed with unchanged public APIs; new
  `GrantTower(userId, towerId, trait?)`. Old `PlayerSettings_v1` DataStore retired.
  `ReplicationBridge` boots data services first. Verified live (mock store; clean boot,
  dev-seed merge, match start).
- **Fixes:** MatchDirector `---__--!strict` typo (strict now active); WaveDirector
  unknown-PathId now releases `waveOutstanding` + ForceResolve (auto-advance can't wedge);
  `MatchLifecycleSmokeTest` gated `RunService:IsStudio()`.
- **Cleanup:** Workspace clutter (sample rigs, template, imports) → `ServerStorage.Archive`;
  ProfileStore module Workspace → `Server.Data`.
- **Repo bootstrap:** this repository created; shared canon seeded (ProfileTemplate,
  PlayerDataService, ProfileStore) with verified matching hashes (see `shared/manifest.json`);
  constitution, contracts, contexts, ADRs 0001–0002 written.
- **Contract impact:** save schema v1 established (first version — no migration needed).
  PENDING: Lobby deploy on creation; real-DataStore round-trip test.
- **Open threads:** in-Studio Documentation set still to migrate; teleport contract at v0 draft.
