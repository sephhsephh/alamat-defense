# ROADMAP — feature status for the whole Experience
<!-- owner: all (any chat updates its own system's rows at landing) | scope: global -->
<!-- last-verified: 2026-08-16 (B25) -->

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

- 🟡 **PlayGUI (user priority, blueprinted 2026-08-09 — `docs/blueprints/playgui.md`)**: Play button
  → loading screen → menu camera → MainMenu → StoryMode (stage/act lists, difficulty slider, reward
  preview) → LobbyFrame → launch. The GUI is BUILT by the user; P1–P7 wire it.
  **✅ P1 [AD-Lobby] (B14, 2026-08-09)** — the `StageRegistry` mirror now carries
  `StageNumber`/`StageName`/`ActNumber`/`ActName` (Stage 1 "The Farm"; acts "Protecting the Fields",
  "The Scarecrow Awakens", "Harvest of Ruin", verbatim from AD-Game's configs) and
  `Workspace.PlayGUICamera` is invisible/non-colliding.
  **✅ P2 [AD-UI] (B15, 2026-08-13)** — the SHELL works: new `StarterGui.LoadingScreen`
  (DisplayOrder 200, `Show(reason)`/`Hide()`), `HUD.Left.Buttons.Play` → veil → every other
  ScreenGui hidden → `PlayGUI` on `MainMenu`, `LeaveButton` reverses it; menu camera Scriptable at
  `PlayGUICamera` with clamped lerped cursor parallax, released on exit AND on death/respawn; the
  three frames transition with a `GroupTransparency` fade + 24px slide and always land on their
  authored values; Challenge/Raids/Events + `FindMatchButton` render visibly disabled. 40/40 live
  asserts.
  **✅ P3 [AD-UI] (B16, 2026-08-13)** — StoryModeFrame is populated: stages grouped from P1's data
  (one row, "The Farm"), all three acts with their correct `ActName`, and `SelectedAct` filled +
  publishing `SelectedActId`/`SelectedStageNumber`/`RecommendedDifficultyWire` for P4/P6. Labels
  with no data source are HIDDEN, not zeroed, and the reward panel is plumbing that renders zero
  cells until P5. 29/29 live asserts. The user cleared blockers B-3 and B-4's rename first.
  **✅ P4 [AD-UI] (B17, 2026-08-13)** — difficulty slider + Normal/Insane, with the ADR-0011 remap
  isolated in a `DifficultyScale` ModuleScript (UI 1–100 → wire 100–1000; the wire scale is
  asserted unmoved). Publishes `DifficultyUI`/`DifficultyWire`/`DifficultyMode` for P6's launch.
  27/27 live asserts. The slider Fill/Handle were authored this session (user-delegated).
  **✅ P5 [AD-GAME] (B18, 2026-08-13)** — Victory gold now scales with difficulty: band
  `lerp(100,300,t)`–`lerp(300,500,t)`, rolled server-side; a DEFEAT keeps its flat consolation.
  The curve is the SHARED `RewardScalingConfig` (`1d789978`) — NOT per-`StageConfig`, because the
  Lobby's StageRegistry mirror carries structure only and has no drift check, so §8's "both sides
  read the same curve" needs real shared canon. Each act NAMES a curve. The Game does its own
  **wire→t** conversion (`t=(wire-100)/900`, clamped) — the wire is 100–1000, the UI 1–100, and
  confusing them pays max gold for a normal match. 24/24 live asserts + a real end-to-end match.
  **Insane was coded but UNREACHABLE at P5 — teleport v3 (B20) made it live.**
  **✅ P6 [AD-LOBBY] (B19, 2026-08-13)** — the `PlayersFrame` roster (one cloned row per party
  member, avatars via non-yielding `rbxthumb://`), `InviteButton` → the existing `PartyScreen` (new
  `OpenRequest` seam; DisplayOrder 0 → 30), and `StartButton` → LoadingScreen → the **EXISTING**
  `RequestLaunch`/`PartyService` reserved-server path — **no second launch path**. It uses P4's
  published `DifficultyWire` VERBATIM and REFUSES to launch if it is absent rather than re-deriving
  it (proven live: the server probe saw `DifficultyPercent=545` for UI 50%). **30/30 live asserts.**
  The B-4 row template was authored this session (user-delegated: one of four copy-pasted `ItemIcon`
  cards repurposed; the other three HIDDEN, not deleted). **`StageSelectScreen` DELETED** — callers
  re-grepped first, `GetStages` survives. (`ClientEvents.OpenStageSelect` lost its only listener here
  and `ReturnScreen`'s CONTINUE went inert — **fixed at B21**.)
  **✅ INTEGRATION FOLLOW-UP [AD-Integration] (B20, 2026-08-14)** — P5's two dangling threads closed
  in ONE cross-Place session. `RewardScalingConfig` copied BYTE-IDENTICAL to the Lobby (`1d789978`,
  drift there now **26/26 GREEN, no gaps**), so the preview and the server payout can read the SAME
  curve — proven in both Places at wire 100 → `100-300`, 550 → `200-400`, 1000 → `300-500`. And
  **teleport contract v2 → v3**: `MatchLaunch` now carries `DifficultyMode`, so **Insane is
  live-reachable** and is the first shipping writer of `Data.Items`. 37 live asserts, 0 failures.
  The preview UI was left unwired for AD-UI (`renderRewards` could not render a min–max BAND and
  re-ran only on act select while the slider kept moving) — proposal filed, **closed at B21**.
  **✅ AD-UI FOLLOW-UPS [AD-UI] (B21, 2026-08-14)** — both open proposals closed in one session.
  **`OpenStageSelect` has a shipping-path listener again**, so `ReturnScreen`'s CONTINUE opens
  PlayGUI on the suggested act; the hop is a real authored `PlayGUI.Commands.SelectAct`
  BindableEvent, deliberately NOT the `DevGoto`/`DevSelectAct` harness. **The reward preview is
  LIVE**: it reads the shared `RewardScalingConfig.GoldBand` off the published `DifficultyWire` and
  re-renders on every slider move, so it can never contradict the payout — a new optional `QtyText`
  lets a cell show a BAND (`100-300`) instead of `x<qty>`, and Insane adds exactly 2 item cells
  without changing the band. **19/19 live asserts**, on observed transitions.
  **✅ P7 BUILT [AD-Integration] (B23, 2026-08-16)** — the global queue (§11) ships on teleport
  **v4**. B22 designed it and stopped at the scope gate (correctly: matching strangers across lobby
  servers repeals the contract's "one match server = one party"); B23 executed that design in a
  both-Places session. New `LaunchService` is the launch body shared by `PartyService` AND
  `MatchmakingService` — **one path with one more caller, not a second path** (§12); new
  `MatchmakingRules` holds the pure bucket/pack/elect logic so it is harness-testable.
  `FindMatchButton` is LIVE. **37 live asserts, 0 failures.** **PlayGUI P1–P7 COMPLETE.**
  **✅ AD-UI REVIEW + MIRROR [AD-UI] (B24, 2026-08-16)** — the **five-item review backlog is CLEARED**:
  B7/B8/B9/B10/B11 all read from source and all confirmed CORRECT, nothing needed changing. (B7's old
  hardcoded `BannerType ~= "Standard"` still greps — it is a history COMMENT on line 183, not live
  code.) `LobbyFrame.RewardsFrame` now **mirrors the Story panel off ONE `GoldBand` computation**
  (`renderRewards` factored into `renderInto`; a second call site is how the two would drift), and
  its `ItemIcon` got B16's authoring fix. **9/9 live asserts.** Two doc-vs-reality findings recorded:
  `QuickSellButton` does **not** exist despite Phase C's note, and `LockUnitButon` (sic) is authored
  but unwired.
  🟡 **V2 kit — AUDITED at B25, adoption BLOCKED ON THE USER.** `Kit.{UnitIconV2, ItemIconV2,
  HotbarSlotV2}` are ADDITIONS beside the v1s (drift stays green), Lobby-only, not in the manifest.
  **✅ Rarity is DECIDED: it goes on the ROOT `UIGradient` and the tier BORDER is dropped** — v1's
  `BG` + `UIStrokeWithGradient` exist in no V2 template and `UIHoverStroke` is hover-only. The
  restyle is accepted; do not "restore" the border.
  ⛔ **Three instances the USER must author before the migration can run:** `SlotNumber` on
  `HotbarSlotV2` (the 1–6 key, used by the SHARED `UIKit.Hotbar` in **both** Places), `CountLabel` on
  `UnitIconV2`, `UIAspectRatioConstraint` on `ItemIconV2`. Gap table + rename map + build order:
  `docs/proposals/2026-08-16-v2-kit-adoption-gaps.md`.
  **`Kit.UnitIcon` has THREE consumers, not two** — B25 found `AscensionController`'s dupe picker.
  Three requested FIELDS still have no data source (cost/element = AD-Game, trait icon = AD-Traits;
  proposals filed) and render HIDDEN. Favourite/Lock stay read-only. Adoption is **cross-Place**.
- ✅ **Global matchmaking queue — BUILT at B23** on teleport v4. MemoryStore sorted map keyed
  `actId|stageNumber|mode|difficultyBucket`; **a queue entry is a PARTY, never a player** and packing
  only adds whole entries, so "never split a party" holds by construction; host = lowest userId, so
  every server elects identically with no round trip; **the match runs at the host's EXACT wire
  value, never an average**; 45s timeout **OFFERS** solo. `FindMatchButton` is live.
  🔲 **Still unproven and it needs a LIVE two-client run:** `ReserveServer` is **HTTP 403 in
  Studio**, so the cross-server handoff can never be shown here, and one Studio client is one server
  — the claim-then-commit race, the timeout prompt and abandonment cleanup were exercised as code
  paths only. (MemoryStore itself works from Studio, verified B22.)

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
- ✅ **Equipping — server 2026-08-06, REACHABLE BY A PLAYER only at B10 (2026-08-09).**
  `Server.Lobby.LoadoutService` (`SetLoadoutSlot`) is the first writer of `Data.Loadout`; slots fill
  LEFT TO RIGHT as a dense uuid list (a contract the match launcher reads). A7 verified the full
  chain live — equip in the Lobby → the Game starts a match from those exact uuids — **but that ran
  through a test harness, and no client code ever called the remote.** `UN/EquipButton` sat
  unreferenced by any script for three days while the docs read "✅ Equipping". **B10 wired it:**
  EQUIP / UNEQUIP / LOADOUT FULL, `loadUnits()` on change so the grid and sort follow, and a new
  `ClientEvents.LoadoutChanged` the hotbar listens to. Equipping into a full loadout is refused
  client-side rather than letting LoadoutService's dense-list clamp silently drop the last unit.
  Verified live incl. unequipping the MIDDLE slot closing the list up with no hole.
  **Lesson worth keeping: "verified live" and "reachable by a player" are different claims.**
  **B11 added: ONE UNIT PER FAMILY** — equipping a unit whose family is already equipped REPLACES
  the incumbent in its slot, and an evolved form counts as the same unit (`Warchief` /
  `Warchief(Warlord)`) via the new Lobby-local `UnitFamilyConfig`. Enforced server-side in
  `LoadoutService`; the response carries `ReplacedUuid` so the UI can say what was swapped. Also
  B11: the button is GREEN for EQUIP / RED for UNEQUIP.
  Still animation-only: the `Upgrade` / `Lock` / `ViewPassives` buttons beside it.
- 🟡 Item economy: `Data.Items` got its FIRST shipping writer at B20 — an **INSANE Victory** pays
  `BannerTicket` + `TraitRerollToken` through the Game's `RewardCalculator` (verified live). Nothing
  else grants an item yet, so counts stay 0 until someone clears an Insane run.

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
- ✅ **Teleport v4** (B23, 2026-08-16): `MatchLaunch` carries `IsMatchmade`, `HostUserId` widens to
  the ELECTED match host, and **"a match server contains exactly one party" is REPEALED** — P7's
  queue groups strangers across lobby servers. Hard cutover; v3 is rejected. A survey of the Game
  found exactly ONE one-party assumption with teeth (game speed + the 3× gate come from the host
  alone) — **left unchanged on purpose and raised as a user design call**. It also caught a real bug:
  the in-match economy multiplier counted the payload ROSTER, so a lone survivor of a 4-player launch
  played at 0.8× cash; it now counts who actually ARRIVED. **USER must republish BOTH Places
  together — again.**
- ✅ **Teleport v3** (B20, 2026-08-14): `MatchLaunch` carries `DifficultyMode` ("Normal"/"Insane"),
  `PayloadVersion = 3` both sides + both directions, deployed in ONE session. A HARD bump, not an
  additive field — the Places publish separately, and a Game ignoring an unknown mode while the
  Lobby believed it sent Insane would pay the wrong rewards SILENTLY. Verified live: v3 Insane
  reaches `matchState.DifficultyMode` and commits the Insane items; v2 is rejected with
  `[CONTRACT]`; unknown/missing modes fail SAFE to Normal. **USER must republish BOTH Places
  together — v2 and v3 do not interoperate.**
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
- ✅ **`UIKit.Motion` — the kit's ONE animation home (B27c, 2026-08-16)**: hover/press scaling, the
  45° 9s idle sheen, `isolate()`'s fixed-size wrapper (a UIScale on a layout child re-flows the row —
  measured 30px of shove) and `lift()`. Retune the kit's feel in `Motion.Tuning`, never per screen.
- ✅ **Open/close SLIDE — BOTH Places' shared module, wired in the Lobby (B28, 2026-08-17)**: the last
  item of the user's B27 play-test queue. `Motion.slideIn`/`slideOut`/`isOpen` on `UnitsGUI`,
  `ItemsGUI`, `SummonScreen`, `IndexScreen`. Enable-before-animate, parent-relative scale (never a
  measured pixel), the authored rest captured once into `UIKitRestPosition`, and a per-frame token so
  a fast open/close/open cannot strand a screen enabled-but-off-screen. 12/12 live asserts.
  🔲 `AscensionScreen` — its controller does not live under that ScreenGui, so it was left alone.
  ❌ `PlayGUI` — deliberately excluded; it opens behind the LoadingScreen veil.
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
- ✅ **B7 — EVENT banners are LIVE (AD-Gacha, 2026-08-09).** Blueprint B4's Event half.
  An Event banner is just a banner with a `Window`, so **running an event is editing two numbers**
  and a second event is a second file — no scheduler, no MessagingService, no deploy.
  `BannerRegistry.SUPPORTED_TYPES` is now the ONE source of truth for what is summonable (read by
  the server AND the screen, so they cannot disagree); `WindowState` gives `Open`/`NotStarted`/
  `Ended`, and `SummonService` refuses with `banner_not_started` (+ `SecondsUntilOpen`) or
  `banner_ended` rather than one flat code. Shipped **`EventFirstLight`** — Gold 120/pull, 2 daily
  featured, richer top-end rates, and the **first CURATED pool** (`Pool = { [tier] = { ids } }` had
  never executed before; Farm excluded on purpose). **Fixed while adding the first daily rotation:**
  `FeaturedFor` used slot offset `0` instead of `MetaConfig.ResetOffsetSec`, so a daily rotation
  would have flipped at 00:00 UTC instead of the game's 16:00 UTC day boundary — Standard's featured
  trio shifted once as an accepted cosmetic side effect. Verified live incl. both refusal paths.
  One authorised change to `SummonController` (AD-UI canon) delegating banner-type policy to the
  registry — **AD-UI review PENDING**.
- 🟡 **Selection banners (blueprint B4's other half) — THE CONTRACT BLOCKER IS GONE (B29).**
  **Schema v3 adds `BannerChoices`, deployed to BOTH Places in one session** (invariant 5) and
  verified across a real DataStore round trip. What remains is the FLOW, and it is all Lobby-local
  AD-Gacha work: a `ChooseBannerUnit` remote (the server re-checks cooldown + pool membership — the
  client is a request, never truth), a PER-PLAYER `BannerRegistry.FeaturedFor` (the pick plus
  `AutoCount` deterministic randoms, excluding the pick so it cannot appear twice), adding
  `Selection` to `SUPPORTED_TYPES`, and the choice UI replacing a Selection card's `ClosedOverlay`.
  Spec: `docs/proposals/2026-08-09-selection-banner-choices.md`. They stay registered, validated and
  refused (`banner_type_not_supported_yet`) until then; turning them on afterwards is one line.
- ✅ **Hover preview no longer blanks on a fast sweep (B29a, 2026-08-17)** — user-reported. Roblox
  does not guarantee `MouseLeave(previous)` before `MouseEnter(next)`, so a stale leave blanked the
  preview the new slot had just shown. A hide must now prove it OWNS the preview. Fixed in
  `UIKit.Hotbar` (shared, both Places) AND `UnitsController` (Lobby). **~70 suppressions logged in
  one play session** — it was most of a fast sweep, not an occasional glitch.
- ✅ **B8 — the UNIT INDEX / CODEX (AD-Gacha, 2026-08-09).** Blueprint B5, all four requirements
  DERIVED not typed: every `ItemCatalog` Tower, obtained silhouettes (own ANY instance, via
  `GetUnitViews`), source text from the banner pools, and **exact per-banner rates computed from
  configs** — `P = (tierWeight/total) × (unitWeight/inTierTotal)`, where featured ids carry
  `Boost`. Quoting the TIER rate as the UNIT rate is the classic disclosure bug; every number was
  re-derived independently in the harness and matched. Standard's chances sum to `0.999950` —
  exactly 1 minus Secret's empty-pool weight. **Honesty rules:** unobtainable units say so rather
  than showing 0%; closed/unsupported banners still list their odds, dimmed; tiers with no
  catalogued tower produce no entries at all. Opens from a `RATES / INDEX` button on SummonScreen
  via `ClientEvents.OpenIndex` — **and B8 changed no AD-UI controller code**, because the index
  wires that button from its own controller.
- ✅ **`Kit_UnitIcon` ADOPTED — ADR-0009 un-parks ADR-0007 (user, 2026-08-09).** Two real consumers
  (B6 chips, B8 index), **no `UIKit.UnitIcon` controller** (both clone-and-fill and hide different
  fields), and **no byte changed** — still `24281a2b` in both Places. It is an ICON, not the unit
  CARD; ADR-0007 clause 3 (the user's shipping design wins for a CARD) still stands.
- 🔲 Trait-on-summon — **inert, not missing**: the chance is tuned and the RNG draw is already
  consumed, but the trait rarity table is AD-Traits canon in the GAME place. Promoting it switches
  this on with no Lobby change. (Shiny-on-summon IS live: 0.870% measured vs 1% configured.)
- 🔲 No Secret / Exclusive / Bathala tower exists, so those tiers are unreachable content. A
  Secret roll falls down to the nearest stocked tier and is logged; `Validate()` reports it as a
  content-gap NOTE, not an error.

### Phase C — Unit depth

**Ownership split (blueprint's own header):** trait/stat rerolls + worthiness are **AD-Traits**;
**ascension is AD-Gacha**. C1 and C2 are also BLOCKED — see below.

- ✅ **B9 — ASCENSION (AD-Gacha, 2026-08-09).** Blueprint C3's ascension half.
  `docs/systems/ascension.md`. Mythic+ only (`AscensionConfig.MinTier`), max A3, one duplicate per
  level, `Ascension += 1`. **The dupe rule is the dangerous part and is server-authoritative:** skips
  the unit itself, and anything Locked / Favorited / **in `Data.Loadout`** (equipped was added beyond
  the blueprint — eating the unit you are about to play with is the same mistake), then takes the
  OLDEST by `ObtainedAt` with uuid as a stable tiebreak. **Confirm is enforced server-side** — the
  commit re-derives its own pick and refuses `dupe_changed` rather than destroying a different unit
  than the one shown. Items are spent BEFORE the dupe, so a shortfall cannot eat it for nothing.
  `AscensionRules` is split from the service because `OnServerInvoke` is write-only and "which unit
  do we destroy" must be harness-testable. New `GrantService.SpendItems` (all-or-nothing; zero
  stores `nil`). ONE authorised line in `UnitsController` publishes the selected uuid — **AD-UI
  review PENDING**. Verified live end-to-end incl. every protection and the maxed-unit display.
  **NOTE the config, not the blueprint, is authoritative on cost:** `AscensionConfig` ships
  `{ Dupes = 1, Items = {} }` and has **no Silver field**; adding one is AD-Game's shared-canon call.
- ✅ **B11 — ascension moved to its OWN NPC-opened screen (ADR-0010).** `StarterGui.AscensionScreen`
  + `Workspace.Lobby.NPC_Ascension` (the Lobby's FIRST NPC and ProximityPrompt). Deliberate
  deviation from C3's "UI in Units screen detail pane" — and it makes Phase C consistent, since the
  blueprint already says "NPC → UI" for C1 and C2. **C1/C2 should copy this shape.** It also retired
  three B9 problems: no dependency on AD-UI's selection, no ResetOnSpawn re-binding, and no "reopen
  Units to refresh" caveat (the screen owns its own picker). Server unchanged.
- 🔲 **Sell dupes (C3's other half) — UNBLOCKED B12 (2026-08-09).** `TierConfig.SellValueByTier` +
  `GetSellValue(tier)` are shared canon in BOTH Places (Silver: Common 10 → Bathala 3000; unknown
  tier pays 0 by design so it can never mint currency). Still to build: wire the unwired
  `UnitsGUI.QuickSellButton` + a `GrantService` sell path, with Locked/Favorited/in-Loadout
  unselectable. Copy B11's NPC-screen shape (ADR-0010), not a pane in the Units frame.
- 🔲 **Trait reroll (C1) + Stat reroll (C2) — UNBLOCKED B12, still AD-TRAITS' ROW (not AD-Gacha's).**
  The trait rarity table (`TraitRegistry` + `TraitDefinitions`) is now shared canon in both Places.
  **API is `TraitRegistry.Roll(rng)` — there is NO `RollTrait`;** `SummonEngine` assumed that name
  from B3 and, inside a pcall, failed SILENTLY until B12 fixed it. Trait-on-summon is now LIVE.
- 🔲 Worthiness meter (kills → 100% = guaranteed A-floor + boosted top-grade odds; resets on reroll).
- 🔲 Feeding (C4) — per-stage exp food via catalog; mass-feed w/ protections. Check `FeedValue` in
  `ItemCatalog` and the `AddTowerXP` path actually exist in the Lobby before committing to it.

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
