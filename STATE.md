# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-10-21 (B170) -->
<!-- BUDGET: 6,000 chars. CURRENT state only -- history goes in CHANGELOG (+ archive/). A resolved PENDING is
     DELETED (the changelog is its record), never struck through. Old long-form STATE: archive/STATE-history.md -->

## Snapshot
- Roblox tower defense, Filipino myth theme; two Places + shared canon (`shared/manifest.json`, 68 entries).
- **Game** = match Place (`MatchEntryService` is the production entry; configs, combat, stat resolver).
  `places/game/CONTEXT.md`.
- **Lobby** = meta/social Place (`Workspace.Lobby`). `GetUnitViews` = its ONE profile read path (ADR-0004);
  `GrantService` = its ONE grant/spend path. `places/lobby/CONTEXT.md`.
- Content: Stage 1 (3 acts) on map ApolakiSunTerraces; ~49 tower configs across 9 tiers incl. evolved forms
  (`docs/design/unit-roster.md`); passives/abilities/summons; gacha (Standard/Event/Selection), ascension, rerolls,
  evolution, crafting, shop, quests, battlepass, events, inbox, leaderboards, admin.
- Contracts: save schema **v11** (`docs/contracts/save-schema.md`), teleport payload **v4** (`teleport.md`;
  `LobbyConfig.MatchLaunchVersion` must equal `GameConfig.TeleportPayloadVersion`).
- Phases A, B, C signed off; Phase D crafting + challenges live. Roadmap board: `docs/ROADMAP.md`.

## Open PENDINGs
- **PENDING (AD-UI, GAME, user B139): Alamat art style on the Game HUD.** RS.AlamatUI + Plates are in (B151). LEFT:
  rebuild the Game HUD's own buttons (bottom-left settings/emote/party/quests gems, top-right) as Sun-gem buttons
  (scale-only, image VFX, no frame-built VFX; `Templates.AlamatButton` not in the Game yet). `alamat-ui.md`,
  `docs/design/icon-art-style.md`.
- **PENDING (USER, B32, art):** `SellButtons.CancelButton` nearly overlaps `QuickSellButton`; `PlayButton` wears the
  Shop logo.
- **PENDING (USER, balance, B33):** L50 = 627,540 XP while `LoadoutConfig` gates slot 6 there.
- **PENDING (AD-Integration / USER, B34): C4 feeding blocked on DATA, not code** — no `FeedValue`, no unit XP
  curve, no writer for `UnitInstance.XP`. `docs/proposals/2026-08-20-c4-feeding.md`. (B108 pt9 shipped FeedService /
  EXP food — confirm with the user whether this is now closed.)
- **PENDING (USER, B73): paste trait logo asset ids** into `TraitDefinitions.Icon` (empty shows the name). (B108 pt12
  recorded the user's ids, `8535ac61` — confirm, then delete.)
- **TOOLING, EVERY SESSION (B64):** `require` from `execute_luau` is dead — run the drift check by pasting
  `tools/hash_shared.luau` inline. Detail: `docs/systems/studio-testing.md`.

## Open threads (from recent landings, not yet PENDINGs)
- B167: kit template drift found, NOT caused by B167 — `Kit_ItemIconV2` (Lobby 98544bdf vs 1cd8e184) and
  `Kit_HotbarSlotV2` (Lobby 6f14cfb6, Game f5a7f240, manifest cd5a2aa0). Asked the user; copying a template
  across Places is a USER action.

## Standing user rules (not in CLAUDE.md)
- The user republishes BOTH Places every session; state it only when a contract bumps.
- Empty SoundIds are DELIBERATE (filled at release); the 0.05 `UIHoverStroke.Thickness` is deliberate. Don't raise.
- Settled design: 3 lives every act, Act 3 is a boss wall, ascension is THE power axis, abort pays nothing
  (`balance.md`). Not bugs.
- Weekend Rush window is UTC+8 (Asia/Manila); x2 on Victory only, incl. every drop (`buffs.md`).
- Worthiness reaching 100 is tuning (`PointsPerKill` 0.02, user), not a missing writer.

## Standing patterns (one writer each — never add a second)
- `BannerChoiceService`→`BannerChoices` · `GrantService.SellUnits`→the only `Data.Units` delete ·
  `UnitConsumeRules`= the one "may this be destroyed" rule · `UnitFlagsService`→`Favorited`/`Locked` ·
  `SettingsService`→`Settings` · `DailyRewardService`→`LoginStreak`+`EventLoginStreaks` · `CodeService`→
  `RedeemedCodes` · `PendingReveals` · `ShopService`→`ShopStock` · `QuestService`→`Quests` · `BattlepassService`→
  `Battlepass` (the Game never writes it) · `ReceiptService`→`ProcessReceipt`+`Purchases` · `UnitCapacityService`→
  `UnitSlotsPurchased` · `HudCurrencyService`→`HudCurrencies`.
- Pure `*Config`/`*Registry` + ONE service owning remote, grant and write; per-day state DERIVED
  (`MetaMath`), stored days are DAY NUMBERS. Check the schema for an existing unwritten field before a bump
  (`Titles` still unwritten).
- GRANT FIRST, MARK SECOND (daily, event, codes, shop, quests, mail). A drop routes by its `ItemCatalog` `Kind`.
- Drift: editing a shared module or template in one Place only is DRIFT — change, re-hash, mirror, update the
  manifest (`tools/checklists.md`).
- Labels: changelog `B<n>` are session counters; blueprint `B1…B5` are session-task names; PlayGUI uses `P1…P7`.

## History
Everything older: `CHANGELOG.md` (newest 10) → `archive/` (STATE-history, CONTEXT histories, CHANGELOG-archive).
Never read archive/ at bootstrap; grep it for one subject.
