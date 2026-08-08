# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-08-09 (B3) -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place.

## Current live state

- **Shared canon deployed & drift-free — 23/23 GREEN at B3 (2026-08-09).** Exact hashes live in
  `shared/manifest.json`; do not duplicate them here. 16 modules + 7 templates, all byte-identical
  to the manifest. **`MetaMath` (B3) is Lobby-only so far** — the Game reports MISSING for it and
  that is EXPECTED, not drift; every OTHER entry must match in both Places.
- **`UnitStatsCatalog`** is a GENERATED read-only cache of each tower's resolved base DMG/RNG/SPA
  at tier 1 / ML 1 / no trait / mid-roll / asc 0 — **SPA is already inverted, these are not raw
  BaseStats**. Owner is AD-Game; the Lobby only consumes it. `Get(towerId)` returns nil for unknown
  ids and **Farm has no DMG/SPA keys** (support tower). Its validator is Game-only canon by design
  — the Lobby has no tower configs to validate against, so do NOT port it here. See ADR-0003.
- **Boot:** `Server.Bootstrap` asserts the save contract and runs `PlayerDataService.Init()`.
  **Schema v2** profile loads from **Beta1_PlayerDataDev1** (prod store **Beta1_PlayerData**;
  intentional beta reset 2026-07-31; DataStoreState=Access) — the Lobby shares the Game
  place's profile (both Places verified at hash 63a0c98a, A2 2026-08-01).
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza.
- **Flow:**
  - **`GetUnitViews` (2026-08-01, the A4/A5 contract):** per owned uuid the server sends
    `Uuid, TowerId, Name, Tier` (both from the shared `ItemCatalog`), `Level, XP, Trait, Shiny,
    Ascension, Worthiness, Locked, Favorited, Equipped` (uuid in `Loadout`), raw `StatRolls` and
    `Grades = {DMG,RNG,SPA}` letters from `StatGradeConfig` — plus `Loadout`, `Currencies`,
    `PlayerXP/PlayerLevel`, `MaxLoadout`. **No resolved DMG/RNG/SPA and no XpPct** (deferred —
    see STATE PENDINGs). Clients never read profiles; render this view only.
  - **`GetUnitViews.Items` (A5, 2026-08-03):** the same remote also returns the profile's
    `{ [itemId] = count }` map (copied, defensive if absent) for the Items screen. Additive and
    read-only; no contract bump. **Nothing WRITES `Data.Items` in either Place**, so it is
    legitimately empty today. Added by AD-UI with the user's authorisation; **AD-Lobby reviewed
    it at A6b and KEPT IT AS-IS** — the shape is right, so `ItemsController` needs no change.
    `GetUnitViews` is now the Lobby's SINGLE profile read path and load-bearing for every
    screen: additive changes are free, but a breaking one needs contract treatment (ADR-0004).
  - **`GetCollection` — RETIRED A7 (2026-08-06, ADR-0004)**, handler + RemoteFunction both GONE.
    **Do not add a second profile read path.** `RS.Remotes` holds **13** entries (+RequestSummon, B3).
  - Stage select + difficulty (`RS.Configs.StageRegistry` mirror, `GetStages`,
    `StarterGui.StageSelectScreen`) — captures (StageId, DifficultyPercent).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`) — teleport contract **v2** (A2, 2026-08-01: `Loadout` carries unit
    **uuids**; version from `LobbyConfig.MatchLaunchVersion`, must equal the Game's
    `GameConfig.TeleportPayloadVersion`). `buildLoadout` = saved profile `Loadout` filtered to
    still-owned uuids, else auto by MetaLevel desc, capped at `MaxLoadoutSize`.
    `GamePlaceId` = **125430066355564** (set 2026-07-18); launch path complete and verified.
  - **MatchReturn handling (2026-07-18; v2 since A2):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (expected version read from `LobbyConfig`, not hardcoded;
    validates version / Outcome / stage; drops
    unknown `SuggestNextActId` — stale mirror fails safe), serves it via `Remotes.GetMatchReturn`
    (read-only). `StarterGui.ReturnScreen` = welcome-back banner (outcome + stage; CONTINUE on
    Victory-with-successor fires `RS.ClientEvents.OpenStageSelect`). `StageSelectScreen` listens
    and pre-selects the suggested next act (also silently on load). Studio harness: toggle the
    `DevSimulateReturn` attribute on MatchReturnService (`[Test]` log).
  - **Starter tower choice (2026-07-18):** dev-editable `RS.Configs.StarterTowerConfig`
    (currently Archer/Knight/Mage — edit that file to change the offer),
    `Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`,
    modal `StarterGui.StarterChoiceScreen` (no dismiss; REAL instance tree per the
    no-UI-in-scripts rule — `Root.Panel.CardsRow.CardTemplate` is the editable card design,
    controller clones/fills/wires only). Eligibility = profile owns ZERO **units** (v2 template
    ships no starter, so fresh accounts always see it). Grants a uuid `UnitInstance` mirroring
    the Game's `PlayerInventoryService.GrantUnit` (MetaLevel/XP from config; **StatRolls via
    shared `StatGradeConfig.RollAll` off one module-level Random, 2026-08-03** — grant log
    prints rolls + grades) and returns its `Uuid`; never clobbers an existing instance;
    Studio harness = `DevSimulateFirstJoin` attribute (sim-only grant-path card,
    self-cleaning by TowerId).
    The auto path is interim until a loadout-picker UI writes `Data.Loadout`; `[DIAG]` logs
    the loadout actually sent. `MaxLoadoutSize = 6`.

Run the constitution's bootstrap ritual + `tools/hash_shared.luau` at the start of every
session; reconcile before any work if a shared hash drifts.

## UI kit + screens (AD-UI)

Two docs since A7 (2026-08-06): **`docs/systems/ui-kit.md`** is the Place-neutral kit (5 shared
controllers in `RS.Shared.UIKit` + 7 real instance templates in `RS.UITemplates.Kit`, all under
drift control — was 6+8 until B2 retired the RewardPopup pair);
**`docs/systems/lobby-ui.md`** is this Place's SCREENS — **Units** (uuid cards +
grades + numbers + filters), **Items** (catalog + counts + filters), **Collection**, **Hotbar**
(the shared component), **CurrencyBar** (Lobby-local by design), plus the legacy script-built
StageSelect / Party / Return / StarterChoice. `StarterGui.UITemplates` was emptied into the Kit
and deleted. Each of Units/Items/Collection honours a `DevAutoOpen` Studio harness (all left OFF).
**A7 finding:** the Units screen's cards are screen-local, NOT `Kit.UnitIcon` clones — see
`lobby-ui.md`; that template still has no consumer and its fate is a user decision.

**`ObtainRewardsGUI` — the reward-reveal surface (B1 2026-08-08; animated B4 2026-08-09).**
**Detail lives in `docs/systems/lobby-ui.md` — moved there at B4.** Fire it, never rebuild it:
`RS.ClientEvents.ShowRewards:Fire({ { Id = "Archer", Level = 12 }, { Id = "Gold", Qty = 250 } })`.
Mixed units + items, 5 cols, rows 1–3 grow / row 4+ scrolls, grants QUEUE. Cells reveal ONE AT A
TIME (pop-in), then **click 1 = SKIP, click 2 = CLOSE** (skip instant; close gated from reveal END).
Tunables are ScreenGui attributes. The pop `UIScale` is made on runtime CLONES only — **never add
one to `Kit_ItemIcon`, it is hashed shared canon.** First production caller = gacha (B3).

## Gacha — banner ENGINE built (B3, 2026-08-09). **Full doc: `docs/systems/gacha.md` — read it**

Server-complete, **no UI at all yet**. `SSS.Server.Meta.{GrantService, SummonEngine, SummonService}`
+ `RS.Configs.{Gacha.*, Banners.*, Meta.MetaConfig}`, driven by `RS.Remotes.RequestSummon`
(Remotes 12 → 13). The five things a Lobby session must not get wrong:

- **`GrantService` is THE one grant path** (invariant 1) — never grant or write `Currencies`
  inline. Its unit record stays byte-compatible with `StarterChoiceService` + the Game's `GrantUnit`.
- **`RS.Shared.MetaMath` is new SHARED canon** (`6badac1d`). **Not deployed to the Game** — it
  reports MISSING there and that is EXPECTED, not drift.
- **Reveal = the remote's RETURN VALUE** (client fires the existing `ShowRewards` with
  `result.Rewards`). No push remote exists; `ObtainRewardsGUI` was consumed, never modified.
- Pity uses the schema-v2 `Data.Pity[ref]` field — **no schema bump**. Pulls count on
  `Counters.Global.GachaPulls`, NOT `Summons` (ADR-0008 — A8 already owns that key).
- Trait-on-summon is **inert here** (no trait table in this Place); Selection/Event refused till B4.

## v2 candidates (not built)

- Gacha UI: summon NPC + banner carousel + x1/x10 buttons (blueprint B3), Selection/Event
  flows (B4), Index/Codex (B5). The engine underneath them is done.
- Party polish: cross-server invites / persisted parties (currently single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub, loadout picker UI (replaces the
  interim auto-loadout).
- Convert legacy script-built screens to instance trees when next touched (rule 2026-07-18):
  ~~CollectionScreen~~ (done A5), StageSelectScreen, PartyScreen, ReturnScreen.

## Phase A: SIGNED OFF (A9, 2026-08-06)

Nothing outstanding. Evidence in the A9 changelog entry + `docs/ROADMAP.md`.

## Open PENDINGs (see STATE.md — this is the Lobby-relevant subset)

- **AD-UI:** real per-unit models (everything uses `UnitModels.Placeholder`) and functional Units
  action buttons (animation-only today). `Kit_UnitIcon` has no consumer — user decision.
- **AD-UI (small):** the hotbar hover TRIGGER is unverified (tooling cannot fire `MouseEnter`);
  `Kit_ItemHoverCard`'s master/clone split means editing the master does not update the screen.
- **USER (BLOCKING):** save + **republish BOTH Places** — A7 deleted `GetCollection` here, which
  is Studio canon and not in git. Schema v2 + teleport v2 also do not interoperate with v1, so a
  partial publish breaks live launches with `[CONTRACT] PayloadVersion mismatch`.
- **USER:** run the teleport v2 loop LIVE once (only v1 was ever live-verified, 2026-07-18).
- **Unscheduled:** still no writer for `Data.Items` in NORMAL PLAY, so the Items screen shows all
  zeroes. `GrantService` (B3) is the first code that CAN write it and is verified doing so, but no
  shipping flow grants an item yet — a banner paying tickets would be the first.
  (`Data.Loadout` now HAS a writer — `LoadoutService`, 2026-08-06 — so `Equipped` is real.)
- **AD-Integration:** the Game place still grants through its own `PlayerInventoryService` /
  `RewardCalculator`, so cross-phase invariant 1 ("every grant flows through GrantService") holds
  in the Lobby only. Converging them is a real cross-Place task, not a Lobby one.
- **AD-Traits:** promoting the trait rarity table to shared would switch on trait-on-summon here.

## Ownership notes

- Lobby owns: teleport contract, lobby UI/scene. **AD-Gacha owns the banner catalog + grant
  pipeline** (`docs/systems/gacha.md`), home Place Lobby, built B3.
- Lobby consumes (never edits): save schema, tower configs, progression config, trait configs.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a second store —
  and since B3, through **`GrantService`**, never inline.
