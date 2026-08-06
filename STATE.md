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
  stat resolver, match runtime. **Has NO UI kit** (Lobby-only — see the blocked PENDING below).
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place, live. Scene
  `Workspace.Lobby`; flow = collection → stage select + difficulty → party → reserved-server
  launch, plus the MatchReturn banner and first-join starter picker. Serves **`GetUnitViews`**
  (per-uuid tier/level/grades/equipped/favorited + `Items`) and the soon-retired `GetCollection`.
  UI: Units + Items + Collection on the kit / view-model — see `docs/systems/lobby-ui.md`.
- **Shared canon** (`shared/src` + `manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **9 modules** — `ProfileTemplate`, `PlayerDataService`, `ProfileStore`, `Signal`, `TierConfig`,
  `StatGradeConfig`, `AscensionConfig`, `ItemCatalog` (2026-08-01), and `UnitStatsCatalog`
  (A6, 2026-08-03; deployed to the Lobby A6b 2026-08-06). **All 9 drift GREEN 9/9 in BOTH
  Places** — byte-identical everywhere. Note `UnitStatsCatalogValidate` is Game-only canon by
  design (the Lobby has no tower configs to validate against); do not "fix" its absence.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only).

- **PENDING (USER):** run the **teleport v2 loop live** — lobby → reserved match → return → banner.
  v2 has only ever been Studio-verified; only v1 was ever live-verified (2026-07-18). Both Places
  are now published on v2, so a `[CONTRACT]` mismatch would block every launch. (The A-phase
  republish itself is DONE 2026-08-06.)

- **PENDING (AD-Integration, BLOCKING A6's Game half):** teach `tools/hash_shared.luau` to hash
  **GuiObject subtrees**. It only hashes `inst.Source` today, so the kit's TEMPLATES cannot be
  drift-checked — only its ModuleScript controllers can — and mirroring templates into the Game
  place would create invisible divergence (it already bit once at A5). User decided 2026-08-06:
  fix the tooling FIRST, document the canonical format in an ADR. Full analysis + rejected
  alternatives: `docs/proposals/2026-08-06-kit-promotion-blocks-a6.md`.

- **PENDING (AD-UI, blocked on the above):** promote the kit (controllers **and** templates) to
  `shared/src` + `manifest.json`, deploy both Places; THEN blueprint §9 A6's Game half (hotbar on
  the kit + `RewardPopup` + `CurrencyBar`). The kit is **Lobby-only** — `RS.UITemplates.Kit`,
  `RS.Shared.UIKit` and `UIKitBootstrap` are all ABSENT in the Game place.

- **PENDING (A7 / AD-Integration — retire `GetCollection`):** ADR-0004 decided it. The remote has
  **zero callers of any kind**; delete the handler in `LobbyServices` AND the
  `RS.Remotes.GetCollection` RemoteFunction, then re-verify every Lobby screen loads.
  **UNBLOCKED 2026-08-06** — it was sequenced after the republish, which has now happened.
  Meanwhile: **no new readers may be built on `GetCollection`** — use `GetUnitViews`.

- **PENDING (NEEDS SCHEDULING — two profile fields have no WRITER):**
  - `Data.Loadout` — nothing ever writes it, so `Equipped` is always false and launches always
    fall through to auto-loadout (top 6 by MetaLevel). Needs a loadout picker UI.
  - `Data.Items` — nothing writes it either (no drop/grant/shop path). The A5 Items screen
    therefore shows every catalog item at count 0. Correct, but the screen is inert until an
    item economy exists.

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

1. **AD-Integration: teach `tools/hash_shared.luau` to hash instance trees** — BLOCKS everything
   below it. Then AD-UI promotes the kit, then A6's Game half (hotbar + `RewardPopup` +
   `CurrencyBar`) can finally run. A6's Lobby half is done (Units number slots, 2026-08-06).
2. ~~**A4 + A5 [AD-UI]**~~ **DONE 2026-08-03** — Units, Items and Collection screens all run on
   the kit + `GetUnitViews`; `UIKit.ItemIcon` + `UIKit.FilterPanel` added; templates consolidated
   into `RS.UITemplates.Kit`; `UnitCatalog` and `StarterGui.UITemplates` deleted. Details in
   `docs/systems/lobby-ui.md`. Compat-field removal handed to AD-Lobby (PENDING above).
3. ~~**A6**~~ **DONE** — AD-Game 2026-08-03 (UnitStatsCatalog + validator, hotfix review,
   cold-profile harness); AD-Lobby 2026-08-06 (A6b: deployed to the Lobby, drift 9/9, compat
   fields dropped, ADR-0004). Remaining A6 work is **AD-UI's**: fill the Units `--` number slots
   from `UnitStatsCatalog.Get` (unblocked now) + rebuild the hotbar on the kit.
4. Then A7 (full Phase A acceptance, Integration) → Phase B gacha. A7 also retires
   `GetCollection` (ADR-0004) and promotes the UI kit to `shared/src`.
5. Unscheduled but wanted: loadout picker (equipping), an item economy that writes `Data.Items`,
   real art/anim asset ids.

