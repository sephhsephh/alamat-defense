# ROADMAP — feature status for the whole Experience
<!-- owner: all (any chat updates its own system's rows at landing) | scope: global -->
<!-- last-verified: 2026-08-30 (B45) -->

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
- ✅ **Account levelling (B41).** `AddPlayerXP` applies `PlayerLevelConfig.ApplyXP` and writes BOTH
  `PlayerXP` and `PlayerLevel` — the ONE account-XP path. `PlayerLevelConfig` promoted to shared canon
  (manifest **35 → 36**, `2e99d041`, `TOOLVERSION B41-1`). Broken since B33: the rollover was
  Lobby-only, so `PlayerLevel` was frozen at 1 and `LoadoutConfig`'s level-gated slots (5 at Lv20,
  6 at Lv50) could never unlock. **No migration, no v5** — `ApplyXP` is self-healing on the next grant.
  🟡 **BALANCE, USER'S CALL:** L50 costs **627,540** XP while slot 6 unlocks there.
- ✅ **Match quest counters (B41).** `InsaneVictories` added (Victory AND Insane). `Clears` already
  **was** "acts cleared" — a `StageConfig` IS an act — so no duplicate key was written.
- ✅ **The three settings actions (B41, open since B35)** — `GameSettingsActions` registers
  `RestartMatch`/`ReturnToLobby`/`TeleportToSpawn`; no edit to shared-canon `SettingsUI`. Both match
  actions go through `RequestMatchAction` so the SERVER keeps the teleport-v4 stamp.
- ✅ **`MatchDirector.AbortMatch` (B41)** — an abort **pays nothing** (user's call): `MatchEnded` is
  never fired, so no XP/gold/drops/counters, and deliberately not a Defeat (whose consolation would
  make restart farmable). Restarting a live match aborts it first. `MatchStateChanged` gains `StageId`.
- ✅ **Drops route by catalogue `Kind` (B45)** — a `Currency`-kind drop is credited to
  `Data.Currencies` via `AddScalarCurrency`, an `Item` to `Data.Items`, and an **uncatalogued id is
  refused loudly and written nowhere** (the stance of `GrantService`'s invariant 4). Before B45 every
  drop went to `AddItem`, so C2's currency faucet would have landed in a field nothing reads.
  ⚠ `SCALAR_CURRENCIES` is mirrored in both Places and cannot be shared — add one, teach both.
- ✅ **Battlepass XP at match end (B43)** — computed from `Configs.Global.BattlepassXpConfig` and
  **accumulated**, never granted here: `Data.Battlepass`'s one writer is Lobby-side, so the number
  rides `MatchReturn.BattlepassXP` and the Lobby applies it. Cleared only after `TeleportAsync`
  succeeds; applied once per join, after the profile loads. `docs/contracts/teleport.md`.
- ✅ **In-match hotbar locks (B43)** — `LoadoutAssigned` carries server-read `PlayerLevel`, so both
  Places draw the same `LoadoutConfig` locks. 🔲 Exposed: the Lobby's auto-loadout fallback ignores
  slot unlocks and can hand a level-1 player more units than they have slots for (AD-Lobby).
- ✅ **`RewardScalingConfig` stale header fixed (B43)** — `1d789978` → `5a4cf793`, comment-only,
  mirrored byte-identical to both Places, manifest updated, 36/36 re-verified.
- ✅ **The Game has an audio owner (B41, open since B32)** — `GameAudio` plays per-act BGM off
  `MatchStateChanged.StageId`, falling back to `BGM.Default`. All 13 SoundIds stay empty until
  release by standing user decision; the caller exists so pasting an id is the only remaining step.
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
  its `ItemIcon` got B16's authoring fix. **9/9 live asserts.** Two doc-vs-reality findings recorded,
  **one of which was itself wrong and is corrected at B31: `QuickSellButton` DOES exist** — at
  `UnitsGUI.Main.Bottom.QuickSellButton`, not under `SelectedUnitFrame`, which is where B24 looked.
  It was unwired until B31 wired it. `LockUnitButon` (sic) + `FavoriteButton` were wired at B32.
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
- ✅ **THE SHARED FEEDBACK LAYER — hover/click/sound/confirm (AD-Gacha, BOTH Places, 2026-08-19, B32).
  FULL DOC: `docs/systems/ui-feedback.md`; read it before touching any button, sound or confirm.** The
  user rebuilt `HUD.Left.Buttons` into rectangle panels, so all six entry points renamed
  (`UnitsButton`/`SummonButton`/`PlayButton`/`InventoryButton`/`QuestsButton`/`ProfileButton`; `Play`
  had vanished and `ShopButton` became it — PlayGUI had NO entry point for a while and said so in the
  console). Rather than a per-button config, **`UIKit.Button` DETECTS panel-style** (a content root
  carrying the `UICorner`/`UIStroke` the button itself lacks) and scales THAT, so the ~55 existing
  tagged buttons changed behaviour not at all while the six new ones get stroke-grow + a continuously
  spinning `UIGradient` + a 45° `LogoContainer` tilt + a press dip/pop with zero setup;
  `ButtonStyle`/`HoverStrokeThickness` attributes override the guess. Three new `Motion` primitives
  (`pressPop`, `spinGradient`/`stopSpin`, `growStroke`) keep every curve in the ONE dialect —
  `growStroke` owns `.Enabled` because a disabled `UIStroke` tweening Thickness animates nothing (the
  B27c hotbar bug, now a documented hazard). **Audio has NO config file: `UIKit.Sound` resolves real
  `Sound` instances by name under `SoundService`**, so assigning a track is pasting a SoundId in the
  Explorer; BGM cross-fades and no-ops when the same track is already playing. **`UIKit.Confirm` is
  the ONE confirmation dialog for both Places** (the user's authored `ConfirmationPopupUI`): 2-second
  grey/inactive gate counting down in the button text, then green and clickable; re-entrancy is
  refused, not queued, and every failure path returns false. Also B32: **`Server.Meta.UnitFlagsService`
  is THE ONE writer of `Favorited`/`Locked`** (`SetUnitFlags`, Remotes 19 → 20, whitelisted fields
  only, returns the STORED values), the authored `SellButtons` + `RaritySelect` rarity picker replace
  the script-built confirm, and `Kit.UnitIconV2` gained `SelectedToSellOverlay` (hash-matched in both
  Places). **Hazard learned the hard way: a `WaitForChild` with no timeout in a shared module hangs
  `require` forever in the Place where the sibling isn't deployed yet** — both new modules now use a
  10s-timeout optional-sibling helper with a no-op stub.

- ✅ **B33 (AD-Gacha, Lobby, 2026-08-20) — THE UNITS SCREEN WAS DEAD, TOASTS ARE IN, THE EXP BAR IS WIRED.
  NOTHING SHARED CHANGED** (drift byte-identical at session start AND end), so the Game is not stale.
  **The repair is the headline, and it is a process failure worth keeping:** B32 retired B31's itemised
  `SellConfirm` panel, reported it to the user as "unused and deletable", the user deleted it — and six
  bare `WaitForChild("SellConfirm")` calls were still sitting in `UnitsController`. A bare `WaitForChild`
  **never times out**, so the controller stopped dead at its first declaration and the ENTIRE Units screen
  silently never booted: no grid, no equip, no favourite, no sell, no error, no stack trace. Advising a
  deletion without grepping for the readers is what caused it. Authored-instance lookups now go through
  **`need()`** — bounded wait, one warn naming every missing full path, and a **detached stand-in** so
  `.Visible = false` on a missing frame is a no-op rather than a crash — and the feature **refuses to arm**
  (`sellEnabled`) instead of half-working. A scan found **334 bare `WaitForChild` vs 23 timed** across
  Lobby scripts; they were deliberately NOT swept (a 334-site mechanical rewrite risks more than it fixes)
  and the count is a PENDING. **TOASTS:** the user copied the Game's `Notifications` GUI +
  `NotificationController` into the Lobby and asked for it Lobby-wide, so `UnitsGUI`, `SummonScreen` and
  `AscensionController` now route messages through one funnel each under the rule **TOAST EVENTS, LABEL
  STATE** — a toast self-erases after 3.5s, which is right for "sold 1 unit for 25 Silver" and actively
  wrong for "this banner is blocked", so persistent conditions stay on their label. `UnitsGUI`'s 17 sell
  messages moved onto toasts by changing ONE function body, which is the whole reason it was a funnel.
  **CURRENCY BAR:** `Remotes.CurrencyChanged` (20 → 21) is a server→client PING with **no payload** —
  ADR-0004 makes `GetUnitViews` the single read path, so a balance on the wire would be a second source of
  truth — fired **debounced per user** by `GrantService`, the one module that writes `Currencies`. Verified
  live: Silver 385 → 395 within 0.6s of a sale, no rejoin (it had needed one since the bar was written; its
  own header comment asked for exactly this fix). **EXP BAR:** the user's authored `ExpBar` is wired to
  real `PlayerLevel`/`PlayerXP` through the new Lobby-local **`PlayerLevelConfig`** — the ONE XP-per-level
  curve, user's call: `100 × 1.15^(level-1)` rounded to 10. It is Lobby-local **on purpose** (nothing in
  the Game reads a curve because nothing anywhere grants player XP yet) and gets promoted the day that
  changes. Two honest consequences recorded rather than hidden: the bar reads **0 forever** until a granter
  exists, and level 50 — where `LoadoutConfig` gates the 6th hotbar slot — costs **627,540** XP total,
  which at ~50 XP a stage clear is ~12,500 clears and probably wants retuning. Also: `HUD.Right`'s second
  `EventButton` renamed to **`DailyRewardsButton`** at the user's request (identified by its label text,
  never by child order, since the two shared a name). Doc: `docs/systems/ui-feedback.md`.


- ✅ **B34 (AD-Gacha, BOTH Places, 2026-08-20) — TWO KIT MODULES PROMOTED, AND A WATCHDOG INSTEAD OF A
  334-SITE SWEEP.** Manifest **29 → 31**, `TOOLVERSION B34-1`, both Places hash-matched byte-for-byte.
  **`UIKit.Notify` (`5e2b09d4`)** ends the fork B33 created: the Game's original
  (`Client.UI.NotificationController`, used by `PlacementController` + `TowerSelectionUI`) and the Lobby's
  copy (`StarterPlayerScripts.*`, used by Units/Summon/Ascension) sat in **different paths, in neither
  manifest, with only the Lobby's hardened** — a fork with no drift control, which is the exact failure the
  shared-canon system exists to prevent. Both retired by rename (`*_RETIRED_2026-08-20`); the API was
  unchanged, so repointing all five consumers was ONE line each and ~20 call sites were untouched. Same
  split as `UIKit.Confirm`: module is canon, `StarterGui.Notifications` stays per-Place authored art.
  **`UIKit.UnitCard` (`bd2421c5`)** ends the four-copy `setViewportModel`/`paintTier` duplication across
  Units / Summon / Index / Ascension. The duplication was **measured before extracting**: three of each
  were byte-identical, and Units differed only in where the model came from (so `viewport()` takes the
  model) and in two behaviours (so `paintTier` takes `{Idle, StrokeOff}`). −104 lines from the consumers,
  one definition of the camera framing. **THE 334 BARE `WaitForChild` WERE DELIBERATELY NOT SWEPT** —
  giving them all timeouts means rewriting ~100 authored lookups across 14 working files and then making
  every downstream use nil-tolerant, a bigger diff and risk than the bug. B33's real defect was that the
  failure was **silent**, so the fix targets that instead: 18 boot scripts each set `BootComplete`, and
  **`ScreenBootWatchdog`** names whatever never finished, one warn per script, with Roblox's own injected
  LocalScripts filtered out because a watchdog that cries wolf every boot is one everybody ignores.
  Diagnosability over prevention, chosen knowingly: a screen can still hang, it just cannot hang quietly —
  and this catches causes a timeout sweep never would. Verified live in both Places: Game boots clean to
  wave 1, all four Lobby card screens render (viewports framed, tiers painted, idle sheen on Units only),
  toasts fire through the shared module, watchdog clean at 19/19 and correctly caught a simulated hang.
  🔲 **C4 Feeding is SCOPED and BLOCKED ON DATA, not code** —
  `docs/proposals/2026-08-20-c4-feeding.md`. `ItemCatalog` has no `FeedValue`, there is no unit XP curve
  and no writer for `UnitInstance.XP`; the machinery it would reuse (`UnitConsumeRules`,
  `GrantService.SpendItems`, multi-select, `Confirm`, `Notify`) all exists. Needs food items, a curve, and
  a decision on how food is obtained — nothing grants items today but an INSANE victory.


- ✅ **B35 (AD-Gacha, BOTH Places, 2026-08-20) — THE UNIFIED SETTINGS SYSTEM. Resolves
  `docs/proposals/2026-08-09-unified-settings-both-places.md`; full doc `docs/systems/settings.md`.**
  Manifest **31 → 35**, `TOOLVERSION B35-1`, both Places hash-matched byte-for-byte:
  `SettingsConfig` `5f0dc44d`, `SettingsService` `8b3b1a72`, `ClientSettings` `a3a9d32f`,
  `SettingsUI` `8e899dab`. **All four deploy at IDENTICAL paths in both Places, which is the whole
  trick** — five Game scripts require `ClientSettings` by a relative path, so keeping every path put
  meant promotion cost **zero consumer edits** and the Lobby simply grew the same folders.
  Each schema entry now declares **`Scope`** (`Both`/`GameOnly`/`LobbyOnly`) and **`Kind`**
  (`Preference`/`Action`), so **`SettingsUI` contains no Place-specific branch anywhere** — it asks
  the config what is in scope and draws it (Game 11 rows / 5 tabs, Lobby 6 rows, verified live).
  ⚠ **`Sanitize` ignores `Scope` on purpose:** one profile serves both Places, so dropping
  out-of-scope keys would mean a Lobby save permanently destroying every `GameOnly` preference. That
  is the single most important line in the system, and it is proven — a Game-side save left the
  `LobbyOnly` `SkipRevealAnim` intact, and `MusicVolume` set in the Game was read back and applied in
  the Lobby. **No save-schema bump was needed**: `Data.Settings` has been free-form since v1.
  **Two real bugs fixed on the way.** (1) The volume slider controlled *nothing* — it drove a
  SoundGroup named `MasterSFX` that has never existed in either Place; it now drives B32's
  `Groups.Master > UI/SFX/BGM` with one slider each for Music/SFX/UI. (2) Settings silently reverted
  to defaults on join: the client fetches once and caches, and that fetch regularly beat the profile
  load, so `Get()` fell through to defaults and the player ran the whole session with real settings
  on the server and default ones on screen. `OnServerInvoke` now waits for the profile.
  Actions are declared centrally but supplied per Place (`ClientSettings.RegisterAction`), and an
  unregistered action renders **disabled**, never silently inert. `Remotes` **21 → 22**.
  🔲 **Two follow-ups, both named in `STATE.md`:** the user must copy `StarterGui.Settings` into the
  LOBBY (B26 — art is a user action; until then `SettingsUI` warns once and stands down), and
  **AD-Game must register the Game's three actions** (`RestartMatch` / `ReturnToLobby` /
  `TeleportToSpawn`), which render disabled there. `ReturnToLobby` must respect teleport contract v4,
  which is exactly why AD-Gacha did not invent it.


- ✅ **B36 (AD-Gacha, BOTH Places, 2026-08-21) — B35 PROVEN IN THE LOBBY, AND THE B34 WATCHDOG
  CORRECTED AFTER IT TURNED OUT NEVER TO HAVE RUN.** The user copied `StarterGui.Settings` across, so
  B35's deployed-and-waiting code finally built in the Lobby: **6 rows / 5 tabs**, against the Game's
  11 from the *same file*, with `TeleportToSpawn` enabled (proving the separate registrar script is
  picked up) and `MusicVolume` set in the **Game** showing 25% here. The cross-Place settings claim is
  now demonstrated in both directions rather than argued.
  ⚠ **`ScreenBootWatchdog` read `script.Source` at runtime. A LocalScript cannot** — that needs
  plugin/Open Cloud capability — **so it threw on that line at every boot from B34 until B36 and
  reported nothing at all.** The B34 entry's "verified live, 19/19 clean, simulated hang caught" was
  worthless: that check ran inside an `execute_luau` VM, **which has plugin capability**, so a
  re-implementation of the logic was tested rather than the deployed script. **Testing a copy of the
  code in a more privileged context is not testing the code** — and the console line that exposed it
  had been printing the whole time.
  The fix removes the `Source` read entirely, using **two markers instead of one**:
  `BootComplete = false` as the first executable line and `true` as the last, giving a tri-state —
  nil (never instrumented) / false (started and hung) / true (finished) — that is strictly *more*
  precise than the old scan, because `false` proves the script actually began executing.
  A second trap caught by checking rather than assuming: **the start marker must go AFTER
  `--!strict`.** The mode directive has to stay on line 1 or Luau silently drops strict mode;
  prepending the block broke all 21 instrumented scripts at once. `SettingsUI` is shared canon so it
  re-hashed `8e899dab` → **`7e5a736a`** in both Places; manifest stays at 35, `TOOLVERSION B36-1`.
  First run of the real script, in the real client: `ScreenBootWatchdog: 21/21 boot script(s)
  finished after 15s` — a line that had never once appeared.


- ✅ **B37 (AD-Gacha, Lobby, 2026-08-21) — THE PUSH-REVEAL PATH. The server can finally show a
  player something they never asked for.** Full doc: `docs/systems/rewards.md`.
  Every reveal until now needed the **client** to invoke a remote and get views **back**. Nothing the
  **server** starts — daily rewards, redeemed codes, quest completions, inbox gifts — has an
  invocation to return from, and that single gap is why four of the HUD's buttons could not be built.
  Three Lobby-local pieces close it: **`RS.Remotes.PushRewards`** (Remotes **22 → 23**),
  **`Server.Meta.RewardPush`**, and **`StarterPlayerScripts.RewardPushReceiver`**. **Shared canon did
  not change** — manifest stays at 35.
  ⚠ **It is OPT-IN: `GrantService` never pushes.** Auto-push was considered and rejected (the user's
  call): summon and sell would then reveal *twice*, once from the return value and once from the
  push, so every existing caller would need a suppression flag — and a flag someone forgets is a
  double popup in a player's face. Opt-in makes the double reveal **impossible by construction rather
  than by discipline**, and that was verified by enumeration rather than asserted: the only live
  caller of `RewardPush.To` in the whole server tree was the test harness, with `SummonService` still
  revealing through `Rewards = views` exactly as before.
  **The rule, and it greps:** player's own click → the **return value**; server decided → **`RewardPush`**.
  **`ObtainRewardsGUI` needed zero changes**, which was the design goal: a server-initiated reward is
  not a new *kind* of reveal, just the same reveal with a different origin, so the receiver is a pure
  adapter (remote in, `ClientEvents.ShowRewards` out) and the surface keeps its B4 contract of "fire
  it, never rebuild it". The surface already queues, so a push landing mid-reveal was safe for free.
  Verified live end to end: a server-initiated grant moved Gold 15 → 265 and Silver 0 → 100 and the
  reveal opened showing `Gold x250` / `Silver x100`. The harness also proved the refusal path — when
  `GrantService` rejected a malformed grant, **nothing was pushed**, because a reveal for a grant that
  did not happen is a lie to the player.
  🔲 **Known gap, deliberately not built:** a grant made while the player is **away** is never
  revealed — `RewardPush` returns `player_not_in_server` and the grant stays safe on the profile.
  Persisting unseen reveals needs a queue on the profile (a schema change) plus an overflow rule, and
  must not be improvised inside `RewardPush`, which owns no storage.
  🔲 **Now unblocked but unbuilt:** DailyRewards, RedeemCodes, Inbox and Quests. Each still needs its
  own data — a reward table, a code registry, per-player redemption tracking — before it can be built.


- ✅ **B38 (AD-Gacha, Lobby, 2026-08-27) — DAILY REWARDS. The first of those four buttons to ship,
  and the worked example of when NOT to use B37's push path.** Full doc:
  `docs/systems/daily-rewards.md`. Four Lobby-local pieces: **`RS.Configs.Meta.DailyRewardConfig`**
  (pure rules), **`SSS.Server.Meta.DailyRewardService`** (**THE one writer of `Data.LoginStreak`**),
  **`StarterGui.HUD.DailyRewardsController`**, and the Studio harness **`Server.Meta.DevDailyRewind`**.
  `RS.Remotes` **23 → 25** (`GetDailyState`, `ClaimDaily`). **Shared canon unchanged at 35.**
  ⚠ **No schema bump, and that was found by reading rather than assumed.** `ProfileTemplate` has
  carried `LoginStreak = { Day, LastClaimDayNumber }` **since v2 with no writer at all**. Designing
  first would have produced a pointless v3 → v4 migration and a both-Places publish for a field that
  was already there. Schema stays **v3**.
  ⚠ **It deliberately does NOT use `RewardPush`.** B38 was pitched partly as that path's first real
  caller. The user chose **click-to-claim**, and B37's own rule then decides it: a claim is a *click*,
  so `ClaimDaily` returns `Rewards = views` and the client fires `ShowRewards`, exactly like summon
  and sell. **The push path therefore still has no production caller** — a login grant, an inbox gift
  or a redeemed code will be its first.
  Rules (user's calls): **7-day cycle**, **miss a day → reset to day 1**, day number from
  `MetaMath.Slot` so the client never computes it. **`GRANT FIRST, MARK SECOND`** — `Grant` validates
  and can refuse, the mark cannot, so marking first would let a refused grant burn the player's day.
  **The reward table is PLACEHOLDER BALANCE** and is labelled as such in the file; the user accepted
  it to unblock the build and will retune it.
  Verified live through the real server: first claim (day 1, Gold x100, 265 → 365, reveal ran),
  **double claim refused** (`already_claimed`), **streak advance** (day 1 → 2, Silver x150), and
  **a missed day resetting a streak of 2 back to day 1**. The deployed label read `Ready to claim!`
  on a claimable join and counted down `11:30:18` → `11:30:15` when claimed.
  🐛 **A bug the verification found:** `stateFor` returned `NextDay(...)` unconditionally, which
  reports **1** for a player who already claimed today whatever day they took — a 7-day track screen
  would have lit day 1 for someone who had just claimed day 5. `NextDay` is correct and answering a
  different question. Invisible to reading; it showed up only as a live
  `{Streak: 2, ClaimedToday: true, Day: 1}`.
  🔲 **Still unblocked but unbuilt:** RedeemCodes, Inbox, Quests, BattlePass, Event.


- ✅ **B39 (AD-Gacha, BOTH PLACES for the schema, 2026-08-27) — EVENT DAILIES + REDEEM CODES + THE
  PENDING-REVEAL QUEUE, on ONE schema bump.** Docs: `daily-rewards.md`, `redeem-codes.md`,
  `reward-push.md`. `RS.Remotes` **25 → 27**.
  ⚠ **Drift repaired first, and it was mine.** `UIKitBootstrap` was `9c9539c0` in the Lobby but
  `f930ff7b` in the Game and the manifest — exactly B36's boot-marker block, added to the Lobby's copy
  of a SHARED module and never mirrored, after which B36 and B37 both closed reporting "35/35 green".
  All three copies now hash `9c9539c0`. **What caught it was comparing each live hash to both `hash`
  and `deployed.<Place>` in code instead of eyeballing the tool output.**
  ⚠ **SCHEMA v3 → v4** (`72d3944f → 8e4224b9`, hash-matched both Places): `EventLoginStreaks` +
  `RedeemedCodes` + `PendingReveals`. `Migrations[3]` is a deliberate no-op like `[2]`. **One bump for
  three systems on purpose — the cost of a bump is the both-Places PUBLISH, not the field.**
  ⚠ **B37's "known gap" was MIS-STATED and is corrected here.** A grant to a genuinely offline player
  cannot happen: their profile is not loaded, so `Grant` has nothing to write to. B39 fixes the
  leave-between-grant-and-push race, not offline delivery — which needs ProfileStore `MessageAsync`
  and owns a grant path. **Draining must never grant** (enumerated: zero `GrantService` refs on the
  drain path), and the drain is a **client-announced handshake** because `FireClient` does not queue
  for a client that is not yet listening.
  ⚠ **Codes: every code is PUBLIC** (the registry replicates) and **the rate limit is SECURITY, not
  UX** — an unlimited redeem remote is a code-space enumerator. Success and `already_redeemed`
  deliberately do not count as failures.
  ⚠ **The event track is a DATE WINDOW, not a banner** — ending a banner would delete a ladder players
  are part-way through. Event ladders **do not wrap** at the last rung. The service was extended
  **additively** so the deployed B38 HUD controller kept working, verified live rather than assumed.
  🔲 **Not built: the two SCREENS** (`StarterGui.DailyRewards`, `StarterGui.RedeemCodes`). Both
  servers are complete and tested; both need authored art (B26). Specs in `docs/specs/`.
  🔲 **Still unbuilt:** Inbox, Quests, BattlePass, Event; offline delivery via `MessageAsync`.


- ✅ **B40 (AD-Gacha, Lobby, 2026-08-27) — THE TWO SCREENS, MAIL, THE SHOP, AND QUESTS.** Docs:
  `shop.md`, `quests.md`, `reward-push.md`, `daily-rewards.md`. `RS.Remotes` **27 → 31**, schema
  stays v4.
  ⚠ **No schema bump for the third time, and it is now a recorded rule.** `ShopStock` and `Quests`
  were both in the template since v2 with no writer, like `LoginStreak` before B38. **Check the
  schema before designing.** Still unwritten: `Titles`, `Battlepass`. **v4 is published, so the next
  new field costs a v5.**
  **SCREENS:** the user reversed "you author it" — B40 scripted BLOCKOUT versions of
  `StarterGui.DailyRewards` (two tabs) and `StarterGui.RedeemCodes` to the published specs and wired
  them. **The specs stay the contract**, so real art later is a replace, not a rewrite.
  **`DailyRewardsButton` now OPENS the screen rather than claiming** — the claim MOVED to the screen;
  the HUD keeps the countdown. Resolved lazily at click time because the controllers boot in an
  unspecified order.
  **MAIL** closes B37's gap for real via ProfileStore `MessageAsync`: the grant runs on the next
  profile load. **GRANT FIRST, THEN `processed()`** — both persist in the same save, which is what
  makes an at-least-once channel deliver exactly once. No shared-canon edit.
  ⚠ **Two live-run corrections.** Mail often reaches a player who IS online, so the reveal goes
  through `ToOrQueue`, not a bare Enqueue. And B39's drain assumed the profile always won its race
  with the client's announcement — it now drains when BOTH have landed, either order.
  **SHOP** is the game's **first Silver sink** — verified that nothing spent Silver while B31 mints
  it. Stock DERIVED from `MetaMath.RngForSlot`, never stored. **PRE-CHECK → SPEND → GRANT → MARK**,
  refund on the unreachable failure. **The client sends a slot INDEX, never a price.**
  **QUESTS** measure a **DELTA against a baseline** taken at assignment (a lifetime counter read
  would finish every quest instantly for an established player), written once per quest per day.
  ✅ **AD-Game cleared that blocker at B41** — see the Game-place rows. The two match quests now need
  only a one-line Lobby edit: add `Clears` + `InsaneVictories` to `QuestRegistry.LiveCounters` and
  uncomment them. **`ClearThree` reads `Clears`, NOT a new `ActsCleared`** (user's call, B41).
  🔲 **Still unbuilt:** Shop and Quests UI; BattlePass, Event, LeaderBoards, InviteFriends; an Inbox
  SCREEN (needs a v5 field for message history — mail itself does not).


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
- ✅ **SELECTION banners are LIVE (AD-Gacha, Lobby, 2026-08-18, B30). Blueprint task B4 is now
  COMPLETE** (Event half B7, Selection half B30). Schema v3's `BannerChoices` (B29) gave the pick
  somewhere to live, and everything B30 added is Lobby-local: `Selection` into `SUPPORTED_TYPES` (the
  one line B7 promised), a pure per-player `BannerRegistry.FeaturedForPlayer` (**the pick FIRST**,
  then `AutoCount` deterministic randoms from `RngForSlot(slot(AutoRotation), bannerId)` EXCLUDING
  the pick, sharing one extracted `drawFeatured` with the untouched `FeaturedFor`), the pure
  `ChoiceState`/`ChoicePool`/`CurrentDay`/`ChoiceCooldownDays` rules that the server ENFORCES and the
  screen EXPLAINS, `SSS.Server.Meta.BannerChoiceService` as **the ONE writer of `Data.BannerChoices`**
  behind `RS.Remotes.ChooseBannerUnit` (READ `(bannerId)` / WRITE `(bannerId, towerId)`, Remotes
  17 → 18), `SummonEngine.BuildContext`'s third `featuredOverride` argument, and the authored
  `ChoiceOverlay` + `ChooseButton` that replace `ClosedOverlay`'s role on a Selection card. Shipped
  **`SelectionAncestors`** (Gold 130/pull, curated pool of 7, Boost 4, 1-day choice cooldown, 2 daily
  autos). Verified live: `choice_required` before a pick, `not_in_pool`, a real write landing in the
  PROFILE at day 20682, a re-pick returning `Unchanged` WITHOUT restarting the cooldown,
  `choice_on_cooldown DaysLeft=1`, client/server featured lists MATCH, and a real x10 for 1300 Gold.
  Docs: `docs/systems/gacha-selection.md` (split from `gacha.md` on its 300-line cap).
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
- ✅ **SELL DUPES SHIPPED (AD-Gacha, Lobby, 2026-08-19, B31) — blueprint task C3 is COMPLETE**
  (ascension B9/B11, selling B31). Prices were already shared canon (`TierConfig.SellValueByTier`,
  Common 10 → Bathala 3000; unknown tier pays 0 by design so it can never mint currency), so
  **nothing shared changed and nothing was re-hashed.** New: **`Server.Meta.UnitConsumeRules`, THE ONE
  definition of "may this unit be destroyed"** — `AscensionRules.PickDupe` carried that condition
  inline since B9 and now delegates to it, so the two destroyers cannot drift; its `Quote` is the ONE
  arithmetic the confirm dialog, the refusal and the write all share, and it also refuses a repeated
  uuid (credited twice, destroyed once) and caps a batch at 100. **`GrantService.SellUnits`** is the
  only code in the project that deletes a `Data.Units` record; it **credits first and destroys
  second**, because `Grant` can refuse and the deletion cannot. `RS.Remotes.SellUnits` (Remotes
  18 → 19) + the thin `Server.Meta.SellService`. UI is **multi-select in the Units screen** — the
  blueprint's own wording and the user's explicit call at B31, so this row's old "copy B11's
  NPC-screen shape" note is deliberately NOT followed: `QuickSellButton` is one button with three
  states, and only an authored confirm panel can fire the remote (B32 moved that to `UIKit.Confirm`
  and `SellConfirm` is now unused). Silver
  returns through `ClientEvents.ShowRewards` unchanged. Verified live: 8/8 malicious-client refusals
  destroying nothing, a real 3-unit sale (18 → 15 units, Silver 0 → 170) with client preview and
  server payment **MATCHing**, and the deletions surviving a real DataStore stop/start.
  Docs: `docs/systems/ascension.md`.
- ✅ **Trait reroll (C1) — AD-Traits, B44.** `docs/systems/trait-reroll.md`. Pick a unit, spend one
  `TraitRerollToken`, reroll its `Trait`. **The cost is the ITEM token, not `Currencies.TraitRerolls`**
  — that scalar has no source, so a reroll priced in it would be unspendable; the token is what the
  shop/battlepass/quests hand out, and this is its FIRST sink (spent via `GrantService.SpendItems`).
  `TraitRerollService` is the ONE reroll writer of `UnitInstance.Trait`, distinct from `SummonService`
  (which writes it at creation), like `AscensionService` owns the Ascension write. Server order
  **PRE-CHECK owned → SPEND → ROLL → WRITE**; a reroll grants nothing (no reveal — the new trait is the
  return value); `TraitRegistry.Roll` is weighted (None 1000 vs Blitz/Sniper 80, Deadeye 25, Godly 3),
  so it routinely lands `None` and spends anyway. **NPC-opened, Image-based blockout screen** copying
  ADR-0010 (the B11 ascension shape); token + current trait read off `GetUnitViews`, no second remote.
  Verified live incl. every refusal and a real Blitz landing then rerolling back to None. Lobby-local,
  no schema bump. **The rarity table (`TraitRegistry` + `TraitDefinitions`) is shared canon; API is
  `TraitRegistry.Roll(rng)` — there is NO `RollTrait`** (`SummonEngine` assumed that name and failed
  silently in a pcall until B12; trait-on-summon is LIVE).
- ✅ **Stat reroll (C2) — AD-Traits, B44.** `docs/systems/stat-reroll.md`. Pick a unit, spend one
  `StatReroll`, reroll all three `StatRolls` (DMG/RNG/SPA); grades + colours from `StatGradeConfig`
  only. **Priced in `Currencies.StatRerolls` (the blueprint's word), via `GrantService.Spend`** — a
  SCALAR_CURRENCY, so it debits with NO ItemCatalog/shared-canon change (where C1 needed a token).
  `StatRerollService` is the ONE reroll writer of `UnitInstance.StatRolls`. ✅ **FAUCET OPENED B45:**
  `StatRerolls` is catalogued (`Kind="Currency"`, `ItemCatalog` → `9be86a5f`) and drops from **Insane
  wins** (`RewardScalingConfig` → `e0a3bc2d`) — the same faucet `TraitRerollToken` uses, which was the
  only reason C1 was reachable and C2 was not. Its icon is a placeholder for the user to author.
  NPC-opened, Image-based blockout (ADR-0010). Verified live incl. the Worthiness floor and every
  refusal; button disables at balance 0. Lobby-local, no schema bump.
- ✅ **Worthiness — BOTH halves are built, and the meter always was.** The stat reroll reads
  `Worthiness` and at `>=100` floors every rolled stat at grade **A**, then resets to 0 on ANY reroll
  (C2, B44). **⚠ CORRECTED B45: the METER (kills → `Worthiness`) is NOT unbuilt** — it has committed
  once per match since **A8** via `CommitUnitKills` → `WorthinessConfig.Apply`, verified at A8 and
  re-verified independently at A9 (Archer 198 kills → 3.96). This row and `stat-reroll.md` both said
  otherwise, and that claim is what drove B45's agenda. Reaching 100 is **tuning**, not a gap:
  `PointsPerKill` 0.02 (user's call at A8, reaffirmed B45) ≈ 25–50 matches for a favourite.
  🔲 `TopGradeBoost` stays dormant until `StatGradeConfig.RollStat` honours its `luck` arg (the FLOOR
  is the concrete effect).
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
- 🟡 Battlepass — **backend + screen B42, BP XP AT MATCH END LANDED B43.** `RewardCalculator` →
  `MatchReturn.BattlepassXP` → Lobby `MatchReturnService` → `BattlepassAddXP` → `BattlepassService`
  (still the one writer of `Data.Battlepass`; the Game never writes it). Rule in the Game's
  `BattlepassXpConfig`: placeholder `50 + 5/wave`, loss ×0.4, ×1.0–2.0 by difficulty. Still 10
  placeholder tiers against the blueprint's 50. 🔲 **Monetization** (paid unlock + level skips) is
  the remaining gap — `Owned` gates the paid track and nothing sets it.
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
