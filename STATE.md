# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-06 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit instances)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

Per-Place detail lives in `places/<place>/CONTEXT.md` — this is the one-glance version.

- **Game** (Studio: "Alamat Defense - Game") — the match Place. Healthy, live. Persistence on
  **Beta1_PlayerData** (Studio `Beta1_PlayerDataDev1`, API access ON). `MatchEntryService` is the
  production entry; `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` are the Studio harnesses.
  Cross-place ids set both ways (`LobbyPlaceId` 83342803778137). Owns tower configs, combat, the
  stat resolver, match runtime. **Has the UI kit since 2026-08-06 but no screen uses it yet** —
  that is A6's Game half.
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place, live. Scene
  `Workspace.Lobby`; flow = collection → stage select + difficulty → party → reserved-server
  launch, plus the MatchReturn banner and first-join starter picker. Serves **`GetUnitViews`**
  (per-uuid tier/level/grades/equipped/favorited + `Items`) and the soon-retired `GetCollection`.
  UI: Units + Items + Collection on the kit / view-model — see `docs/systems/lobby-ui.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **21 entries = 14 modules + 7 templates**, all **GREEN 21/21 in BOTH Places** (byte-identical).
  Modules: `ProfileTemplate`, `PlayerDataService`, `ProfileStore`, `Signal`, `TierConfig`,
  `StatGradeConfig`, `AscensionConfig`, `ItemCatalog`, `UnitStatsCatalog`, and the kit's
  `UIKitButton`/`UIKitItemIcon`/`UIKitFilterPanel`/`UIKitBootstrap` (2026-08-06).
  Templates (instance trees, ADR-0005, no `shared/src` file): `Kit_Button`, `Kit_ItemIcon`,
  `Kit_ItemHoverCard`, `Kit_FilterPanel`, `Kit_UnitPreviewTemplate`, `Kit_UnitIcon` (A6).
  `UnitStatsCatalogValidate` is Game-only canon by design (the Lobby has no tower configs to
  validate against); do not "fix" its absence.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only).

- **PENDING (USER):** run the **teleport v2 loop live** — lobby → reserved match → return → banner.
  v2 has only ever been Studio-verified; only v1 was ever live-verified (2026-07-18). Both Places
  are now published on v2, so a `[CONTRACT]` mismatch would block every launch. (The A-phase
  republish itself is DONE 2026-08-06.)

- ~~PENDING: template hashing (AD-Integration) + kit promotion (AD-UI).~~ **BOTH DONE 2026-08-06**
  — ADR-0005 + the 18/18 shared canon above. Deploy procedures live in `tools/checklists.md`.

- ~~PENDING (AD-UI): rebuild the Game hotbar on the kit.~~ **DONE 2026-08-06** — slots are
  `Kit.UnitIcon` clones with real per-tower viewport models, `UIKit.Button` behaviour, and a
  **tier-coloured** border (was trait rarity; the trait moved to the corner dot, not dropped).
  `Unit/ItemIconTemplate` renamed → `Kit_UnitIcon` `24281a2b`, now the 19th drift-controlled entry.

- ~~PENDING (AD-UI): `RewardPopup` + `CurrencyBar`.~~ **DONE 2026-08-06 — A6 IS COMPLETE.**
  `Kit_RewardPopup` + `UIKitRewardPopup` are shared canon in both Places (no caller yet by design —
  MatchEnd keeps its list; this is for Phase B gacha, smoke-tested not wired). `CurrencyBar` is
  **Lobby-local on purpose** (`HUD.Top.CurrencyBar` + controller) — a single-Place widget under
  drift control would cost a cross-Place sync forever; the header says to promote it into the Kit
  if the Game place ever wants one.

- **PENDING (AD-UI, small/cosmetic):** two now-DEAD templates neither deleted unilaterally, since
  both may be designs worth keeping: `StarterGui.Hotbar.SlotTemplate` (Game — zero readers since
  the hotbar moved to `Kit.UnitIcon`). Decide keep-or-delete when next touching either screen.

- **DRIFT RULE (new, applies to everyone):** the kit is shared now. Editing a controller **or a
  template** in one Place only is DRIFT. Change → re-hash → copy to the other Place → update the
  manifest. Templates have NO `shared/src` file — the INSTANCE is the canon (ADR-0005); copy it,
  never rebuild it by hand. Both procedures are in `tools/checklists.md`.

- **PENDING (A7 / AD-Integration — retire `GetCollection`):** ADR-0004 decided it. The remote has
  **zero callers of any kind**; delete the handler in `LobbyServices` AND the
  `RS.Remotes.GetCollection` RemoteFunction, then re-verify every Lobby screen loads.
  **UNBLOCKED 2026-08-06** — it was sequenced after the republish, which has now happened.
  Meanwhile: **no new readers may be built on `GetCollection`** — use `GetUnitViews`.

- ~~PENDING: `Data.Loadout` has no writer.~~ **CLEARED 2026-08-06** — `Server.Lobby.LoadoutService`
  (`SetLoadoutSlot`) is the first writer; `Equipped` is now really true for equipped units.
  **Slots fill LEFT TO RIGHT with no gaps** — `Data.Loadout` is a schema-v2 `{ string }` contract
  field the match launcher reads, so it must stay a dense list. Fixed slot positions (leave slot 1
  empty, keep a unit in slot 3) need a **schema bump + migration under AD-Game's contract
  protocol** — deliberately deferred, not smuggled in.

- ~~PENDING: shared hotbar in both Places.~~ **DONE 2026-08-06.** The user copied the Lobby's whole
  `StarterGui.Hotbar` into the Game, so both Places hold the SAME screen; the Game got its own
  controller (placement) and the old `StarterPlayerScripts.Client.UI.Hotbar` was disabled +
  renamed `Hotbar_RETIRED_2026-08-06` (it would have double-bound keys 1-6). Both hotbars are ONE component
  (`UIKitHotbar` + `Kit_HotbarSlot`, the user's own design): same slots, hover and animation;
  the only difference is `OnActivated` — **Lobby** opens the Units screen on that unit, **Game**
  starts placement. Always 6 slots, states filled/empty/locked.
  **Locks are a LOBBY concern:** the Game shows none, because you equip in the Lobby and the Game
  has no `PlayerLevel` (`LoadoutAssigned` carries TowerId/MetaLevel/Trait only). In-match, slots
  you did not bring are EMPTY. Real in-match locks would need AD-Game to send `PlayerLevel`.

- **PENDING (NEEDS SCHEDULING):** `Data.Items` has no writer (no drop/grant/shop path), so the A5
  Items screen shows every catalog item at count 0. Correct, but inert until an item economy exists.

- **NOT a bug, do not "fix" it:** the Units screen's stat NUMBERS are per-TOWER (the catalog's
  mid-roll reference), so two instances of one tower show equal numbers while their GRADE letters
  differ. ADR-0003's accepted trade; per-unit numbers would need the Min/Max ranges promoted too.
  Details in `docs/systems/lobby-ui.md`. (Slots filled 2026-08-06; that PENDING is closed.)

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** persistence round-trip test (never run; profile shape has changed since it
  was raised) and progressive `ServerStorage.Documentation` → `docs/systems/` migration.

## Contracts (current versions)

- Save schema: **v2** (`shared/src/ProfileTemplate.luau`, hash `63a0c98a`) — store
  "Beta1_PlayerData"/"Beta1_PlayerDataDev1". v2 (A1, 2026-08-01) = uuid unit `Units` +
  `Currencies` map + meta fields; `Migrations[1]` converts v1→v2. **Deployed + drift-green in
  BOTH Places** (Game A1, Lobby A2 — both `63a0c98a`).
- Teleport payload: **v2** (`docs/contracts/teleport.md`) — implemented BOTH sides + BOTH
  directions: Lobby sends `MatchLaunch` and consumes `MatchReturn` (banner + next-act pre-select);
  Game receives `MatchLaunch` and returns `MatchReturn`. v2 (A2, 2026-08-01) = `Loadout` carries
  unit uuids; **hard cutover, no migration** — v1 is rejected with `[CONTRACT]`. Version lives in
  `LobbyConfig.MatchLaunchVersion` == `GameConfig.TeleportPayloadVersion` (must always be equal).
  Verified in Studio both sides; both Places **republished together 2026-08-06**, so v2 is now the
  LIVE build in both. **Live e2e re-verification of the v2 loop is still the open user action** —
  publishing it is not the same as running it (v1 was live-verified end-to-end 2026-07-18).

## Current focus

1. **A7 [AD-Integration]** — Phase A acceptance (blueprint §8) + retire `GetCollection` (ADR-0004).
   The hotbar + equipping work is DONE, so A7 signs off a bigger surface than the blueprint
   assumed: equipping, the shared hotbar, and 24 drift-controlled entries.
2. **A7 [AD-Integration]:** full Phase A acceptance (blueprint §8) + retire `GetCollection`
   (ADR-0004, zero callers, already unblocked).
3. **USER:** run the teleport v2 loop live once — published is not the same as verified.
4. Then Phase B (gacha). Schema v2 already carries `Pity`, `Currencies`, `Items`.
5. Unscheduled but wanted: loadout picker (`Data.Loadout` has no writer, so nothing is ever
   "equipped"), an item economy (`Data.Items` has no writer either), real art/anim asset ids.

