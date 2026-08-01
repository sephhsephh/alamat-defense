# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-07-18 -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
single-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/
abilities/summons, progression + match-end rewards, **ProfileStore persistence (schema v1)**.
Multi-Place split (Lobby + Game) is the current initiative; this repo was created 2026-07-17
as the source of truth for it.

## Places

- **Game** (Studio: "Alamat Defense - Game") — the playable match Place. Healthy.
  Persistence live; Studio saves go to the separate **PlayerData_Dev** store (verified
  with API access ON, DataStoreState=Access). **Production entry receiver `MatchEntryService`
  built 2026-07-18** (reads `TeleportData.MatchLaunch` v1 → StartMatch); `MatchLifecycleSmokeTest`
  is now the Studio fallback (stands down when a MatchLaunch payload is present). `ReturnToLobby`
  now sends `MatchReturn` v1 + teleports to the Lobby — **`GameConfig.LobbyPlaceId` set
  (83342803778137, verified vs live Lobby PlaceId, 2026-07-18 Integration)**.
- **Lobby** (Studio: "Alamat Defense - Lobby") — **v1 built 2026-07-17**. Data layer drift-free
  (`RS.Shared.{Signal,ProfileTemplate}`, `SSS.Server.Data.{ProfileStore,PlayerDataService}`) +
  `Server.Bootstrap`. Scene: `Workspace.Lobby` blockout hub. Flow: read-only collection screen
  (`LobbyServices` GetCollection/GetStages), stage select + difficulty (`RS.Configs.StageRegistry`
  mirror), party system + reserved-server teleport (`PartyService`, `RS.Configs.LobbyConfig`,
  teleport contract **v1**), **GamePlaceId set (125430066355564, 2026-07-18)**. **MatchReturn v1
  handling built 2026-07-18** (`MatchReturnService` + `ReturnScreen` banner + StageSelect
  pre-select of `SuggestNextActId`; verified via `[Test]` sim + `[DIAG]`). **Starter tower
  choice + launch-loadout fix 2026-07-18** (`StarterTowerConfig` [dev-editable] +
  `StarterChoiceService` + modal picker, inert until the ProfileTemplate PENDING lands;
  `PartyService` now sends up to 6 owned towers instead of `Loadout={}`).

## Open PENDINGs

- ~~PENDING (Game / AD-Game): remove the seeded starter Archer from `ProfileTemplate`.~~
  **DONE 2026-07-18** — `Towers = {}` deployed to **BOTH Places** (hash `376e717d → 8ac5d3e9`,
  verified byte-identical in Game + Lobby + `shared/src/`); no `SCHEMA_VERSION` bump
  (default-value change, no migration). `manifest.json` `deployed` = both `8ac5d3e9`; drift-clean.
  User chose the standalone unblock over folding into blueprint A1 (A1 re-touches this at schema v2).

- ~~PENDING (Lobby): deploy shared modules on creation.~~ **DONE 2026-07-17** — all four
  shared modules deployed drift-free; manifest `deployed.Lobby` current.
- ~~PENDING (Lobby, USER ACTION): set `LobbyConfig.GamePlaceId`.~~ **DONE 2026-07-18** —
  set to 125430066355564; real launches now reach ReserveServer + TeleportAsync.
- ~~PENDING (Game / AD-Game): build the production entry receiver.~~ **DONE 2026-07-18** —
  `MatchEntryService` reads `TeleportData.MatchLaunch` v1 → validate → `MatchDirector.StartMatch`
  (smoke test now Studio fallback). `ReturnToLobby` sends `MatchReturn` v1 + teleports back.
- ~~PENDING (Game, USER ACTION): set `GameConfig.LobbyPlaceId`.~~ **DONE 2026-07-18
  (Integration)** — found set to 83342803778137, verified equal to the live Lobby
  instance's `game.PlaceId`; stale STUB comment cleaned. Teleport loop config-complete.
- ~~PENDING (USER ACTION): first LIVE end-to-end teleport test.~~ **DONE 2026-07-18** —
  user ran the full loop in the production client: lobby → reserved match → return →
  Defeat banner shown. (The defeat itself exposed the empty-Loadout bug, fixed same day —
  re-publish the Lobby and re-run to confirm towers appear in-match.)
- **PENDING (Game):** persistence round-trip test — play, earn rewards, stop, play again,
  confirm the PlayerData_Dev profile restored (API access already ON; writes verified).
- **PENDING (Game):** in-Studio `ServerStorage.Documentation` is still the richer doc set;
  migrate its contents into `docs/systems/` progressively (doc-gardening sessions), then
  retire it to a pointer.

- ~~PENDING (AD-Game + USER, CRITICAL — split-brain risk): verify Game store name.~~
  **RESOLVED 2026-07-31** — store renamed `PlayerData → Beta1_PlayerData` (dev `→ Beta1_PlayerDataDev1`),
  intentional beta reset (user). Verified hash **`184cdfad`** live in **BOTH** Places + disk +
  `manifest.deployed` (byte-identical) — no split-brain. No `SCHEMA_VERSION` bump. `save-schema.md`
  note stands (owner AD-Game may formally re-verify the contract doc wording at leisure).

- **PENDING (AD-UI, DEFERRED — gated on schema v2 / A3):** the AD-UI kit shipped interim on v1
  data (built + verified live 2026-07-31 — `UIKit.Button`, hotbar preview, UnitsGUI, TierConfig/
  UnitCatalog; see CHANGELOG + `places/lobby/CONTEXT.md`). At v2 wire: real per-unit models
  (replace `ReplicatedStorage.UnitModels.Placeholder`), resolved DMG/RNG/SPA (replace UnitCatalog
  placeholders), real Loadout(equipped)+UnitInstance.Favorited (replace UnitCatalog interim flags
  driving the grid sort + hotbar-preview data), and functional action buttons (Quick Sell/Unequip
  All/Upgrade/Lock/Equip/View Passives). Promote `UIKit`/`TierConfig`/`UnitCatalog` to `shared/src`
  at Integration (A7) if the Game place needs them.

- **PENDING (USER):** save + republish the **Lobby** — all AD-UI work is Studio-canon (Lobby
  Edit session), not in git; commit only covers the disk docs.

- ~~PENDING (AD-UI, USER REVIEW): approve UI-kit Button proposal.~~ **IMPLEMENTED interim
  2026-07-31** (user-directed). Proposal `docs/proposals/2026-07-31-ui-kit-button-primitive.md`
  built as `UIKit.Button` (+ tag bootstrap); glow bug root-caused live (duplicated per-slot
  scripts + overlap) and fixed by the single controller. PlayerLevelBar not yet needed (exp bar
  already exists). Folding the extended kit spec into `phase-a-foundations.md` §5 stays for a
  formal A-phase pass.

## Contracts (current versions)

- Save schema: **v1** (`shared/src/ProfileTemplate.luau`) — store "PlayerData". Starter
  `Towers.Archer` seed removed 2026-07-18 (`Towers = {}`); still v1 (default change, hash
  `8ac5d3e9`, deployed to both Places, drift-clean).
- Teleport payload: **v1** (`docs/contracts/teleport.md`) — implemented BOTH sides + BOTH
  directions: Lobby sends `MatchLaunch` and consumes `MatchReturn` (banner + next-act pre-select);
  Game receives `MatchLaunch` and returns `MatchReturn`. Config-complete BOTH sides and
  **LIVE-VERIFIED end-to-end in the production client (user, 2026-07-18)**.

## Current focus

1. **USER: republish both Places** — the starter-seed removal LANDED to both Game + Lobby
   (drift-clean, hash `8ac5d3e9`) 2026-07-18. Republish, then re-run the live loop: fresh
   accounts get the starter picker, and towers should appear in-match (loadout fix).
2. Lobby v2 candidates: gacha/banners (gated on Phase A schema v2), party polish, currency
   shop, player-level display, loadout picker UI (replaces the interim auto-loadout).
3. Real art/anim asset ids for tower attacks (Game chat).
4. Progressive doc migration from Studio to this repo.

<!-- Shared canon note: Signal promoted to shared/src + manifest 2026-07-17 (AD-Lobby),
     byte-identical to the live Game module; drift check now covers all four shared modules. -->

