# CONTEXT — Lobby place (LIVE, booted 2026-07-17)
<!-- owner: lobby | scope: lobby | last-verified: 2026-07-18 -->

The social/meta Place: players land here, view their collection, roll banners, pick a
stage + difficulty, form parties, and teleport into the Game place.

## Current live state

- **Data layer deployed & drift-free.** `ReplicatedStorage.Shared.{Signal, ProfileTemplate}`,
  `ServerScriptService.Server.Data.{ProfileStore, PlayerDataService}` — all four hashes match
  `shared/manifest.json` (Signal 91becf7a, ProfileTemplate 184cdfad, PlayerDataService
  613f0d39, ProfileStore 1e3a6f3f). `Signal` was promoted into `shared/src` this session.
- **Boot:** `Server.Bootstrap` asserts the save contract and runs `PlayerDataService.Init()`.
  Schema v1 profile loads from **Beta1_PlayerDataDev1** (prod store **Beta1_PlayerData**;
  intentional beta reset 2026-07-31; DataStoreState=Access) — the Lobby shares the Game
  place's profile (both Places verified at hash 184cdfad).
- **Scene:** `Workspace.Lobby` blockout hub (plaza + sun emblem, pillars, title wall,
  COLLECTION/PLAY pedestals); spawn on the plaza.
- **Flow (v1):**
  - Collection (`Server.Lobby.LobbyServices` `GetCollection`, `StarterGui.CollectionScreen`) —
    READ-ONLY owned towers from the profile.
  - Stage select + difficulty (`RS.Configs.StageRegistry` mirror, `GetStages`,
    `StarterGui.StageSelectScreen`) — captures (StageId, DifficultyPercent).
  - Parties + reserved-server launch (`Server.Lobby.PartyService`, `RS.Configs.LobbyConfig`,
    `StarterGui.PartyScreen`) — teleport contract **v1**. `GamePlaceId` = **125430066355564**
    (real Game place id, set 2026-07-18); launch path complete and verified.
  - **MatchReturn v1 handling (2026-07-18):** `Server.Lobby.MatchReturnService` reads
    `TeleportData.MatchReturn` on join (validates PayloadVersion==1 / Outcome / stage; drops
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
    controller clones/fills/wires only). Eligibility = profile owns ZERO
    towers → **inert until AD-Game removes the template's seeded Archer** (proposal
    2026-07-18). Grants `{MetaLevel=1, XP=0}`; never clobbers; Studio harness =
    `DevSimulateFirstJoin` attribute (adds a sim-only grant-path card, self-cleaning).
  - **Auto-loadout at launch (2026-07-18):** `PartyService.buildLoadout` sends each player's
    owned towers (highest MetaLevel first, cap `LobbyConfig.MaxLoadoutSize=6`, mirroring the
    Game's LoadoutValidator) — replaces the `Loadout={}` bug that made matches towerless.
    Interim until a loadout-picker UI; `[DIAG]` logs the sent loadout.

Run the constitution's bootstrap ritual + `tools/hash_shared.luau` at the start of every
session; reconcile before any work if a shared hash drifts.

## UI kit + screens (AD-UI, 2026-07-31 — Studio canon; interim on v1 data)

- **`UIKit.Button`** (`ReplicatedStorage.Shared.UIKit.Button`) — ONE reusable controller for
  every button (no per-button scripts). Hover = scale from centre (`centerAnchor` fix) + stroke
  thicken OR `HoverStrokeColor` (e.g. white) + icon rotate; press animation; seamless (tiled)
  animated gradient. All attribute-driven (`HoverScale/HoverStrokeMult/HoverStrokeColor/
  HoverIconRotation/PressScale/TweenTime/GradientAnimate/GradientSpeed/GlowStrokeName/
  StrokeHiddenUntilHover`). API: attach/create/onActivated/onHover/setHovered/setText/setIcon/
  setStrokeColor/setEnabled. **Tag any GuiButton `UIKitButton`** → `StarterPlayerScripts.UIKitBootstrap`
  attaches it (tags copy to clones).
- **Hotbar** (`StarterGui.Hotbar.HotbarController`) — single controller replaces the old
  duplicated per-slot scripts (disabled); glow on hover + `Hotbar.Templates.UnitPreviewTemplate`
  shown above the hovered slot.
- **Units screen** (`StarterGui.UnitsGUI.UnitsController`) — opens from HUD `Left.Buttons.Units`.
  Loads owned units (v1 `GetCollection`); each card's border **and** BG glow the unit's TIER
  colour (animated seamless); hover → white border + scale + a `UITemplates.UnitPreviewTemplate`
  popup on the right (name/tier/DMG-RNG-SPA + model); click → `SelectedUnitFrame` (framed
  viewport + Stats reusing the preview design). Sort: equipped > favourited > tier high→low >
  name. Live SearchBar. Placeholder model `ReplicatedStorage.UnitModels.Placeholder`. Action
  buttons (Quick Sell/Unequip All/Upgrade/Lock/Equip/View Passives) are **animation-only**.
- **Configs (editable, AD-UI):** `RS.Configs.Meta.TierConfig` (tier → colour list; one = solid,
  many = animated gradient; Mythic rainbow, Secret red→dark-red) + `RS.Configs.Meta.UnitCatalog`
  (towerId → Tier + placeholder DMG/RNG/SPA + optional Equipped/Favorited flags).
- **HUD buttons** (`HUD.Left.Buttons.{Play,Units,Inventory,Areas,Summon,Shop}`) tagged +
  animated; `Frame.BorderDesignInside` hidden; hover = white stroke (no thicken).

## v2 candidates (not built)

- Gacha/banners (uses `PlayerInventoryService.GrantTower` semantics + Items tickets) —
  gated on Phase A schema v2 (AD-Game).
- Party polish: cross-server invites / persisted parties (v1 is single-lobby-server, in-memory).
- Currency shop, player-level display, trading hub, loadout picker UI (replaces the
  interim auto-loadout).
- Convert legacy script-built screens to instance trees when next touched (rule 2026-07-18):
  CollectionScreen, StageSelectScreen, PartyScreen, ReturnScreen.

## Open PENDINGs (see STATE.md)

- **AD-UI (deferred, gated on schema v2 / A3):** UnitsGUI + hotbar preview currently use a
  placeholder model + interim `UnitCatalog` stats + shared-catalog Equipped/Favorited flags.
  At v2 wire real per-unit models, resolved DMG/RNG/SPA, real Loadout(equipped)+Favorited, and
  make the action buttons functional. `UIKit`/`TierConfig`/`UnitCatalog` promote to `shared/src`
  at Integration (A7) if the Game place needs them.
- USER: **save + republish the Lobby** after this session (all AD-UI work is in the Studio
  Edit session). LIVE e2e loop verified 2026-07-18.

## Ownership notes

- Lobby owns: teleport contract, shop/banner catalog (when built), lobby UI/scene.
- Lobby consumes (never edits): save schema, tower configs, progression config.
- Currency/XP/tower grants in the Lobby MUST go through the same profile — never a
  second store.
