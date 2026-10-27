# STATE — Alamat Defense
<!-- owner: all | last-verified: 2026-10-28 (B174) | BUDGET 6k chars, CURRENT state only (history: CHANGELOG +
     archive/). A resolved PENDING is DELETED, never struck through. -->

## Snapshot
- Roblox tower defense, Filipino myth theme; two Places + shared canon (`shared/manifest.json`, 68 entries).
- **Game** = match Place (entry `MatchEntryService`; configs, combat, stat resolver) — `places/game/CONTEXT.md`.
- **Lobby** = meta Place; ONE read path `GetUnitViews` (ADR-0004), ONE grant/spend path `GrantService` —
  `places/lobby/CONTEXT.md`.
- Content: Stage 1 (3 acts, map ApolakiSunTerraces); Stage 2 MAP BakunawaCove built (no acts yet); ~49 tower configs over 9 tiers incl. evolved forms
  (`docs/design/unit-roster.md`); the full meta loop (gacha, ascension, rerolls, evolution, crafting, shop, quests,
  battlepass, events, inbox, leaderboards, admin). Status board: `docs/ROADMAP.md`.
- Contracts: save schema **v11** (`save-schema.md`), teleport **v4** (`teleport.md`;
  `LobbyConfig.MatchLaunchVersion` must equal `GameConfig.TeleportPayloadVersion`).

## Open PENDINGs
- **PENDING (AD-UI, GAME, user B139): Alamat art style on the Game HUD.** RS.AlamatUI + Plates are in (B151). LEFT:
  the Game HUD's own buttons (bottom-left settings/emote/party/quests, top-right) as Sun-gem buttons (scale-only,
  image VFX; `Templates.AlamatButton` not in the Game yet). `alamat-ui.md`, `docs/design/icon-art-style.md`.
- **PENDING (USER, B32, art):** `SellButtons.CancelButton` nearly overlaps `QuickSellButton`; `PlayButton` wears
  the Shop logo.
- **PENDING (USER, balance, B33):** L50 = 627,540 XP while `LoadoutConfig` gates slot 6 there.
- **PENDING (AD-Integration / USER, B34): C4 feeding blocked on DATA** — no `FeedValue`, unit XP curve or
  `UnitInstance.XP` writer (`docs/proposals/2026-08-20-c4-feeding.md`). B108 pt9 shipped FeedService — confirm closed?
- **PENDING (USER, B73): paste trait logo asset ids** into `TraitDefinitions.Icon`. B108 pt12 recorded ids
  (`8535ac61`) — confirm, then delete.
- **PENDING (AD-UI, BOTH, B172): SettingsUI gives up after 10 s** (`WaitForChild("Settings", 10)`) on a slow join -> settings
  panel dead for the session (hit in 2/3 Lobby Plays after the rebuild). `docs/proposals/2026-10-23-settingsui-boot-timeout.md`.
- **PENDING (AD-Game + AD-Integration, BOTH, B173): Stage 2 content.** Map `BakunawaCove` is in the Game; no Stage 2
  acts/waves/enemies use it. Needs StageConfigs (`MapId = "BakunawaCove"`), waves for a 556-stud path, the Skeleton
  Pirate enemy (model in `BakunawaCove_Characters.blend`, unrigged), Bakunawa boss, + the Lobby `StageRegistry` mirror;
  then move its `PlayConfig.UpcomingMaps` row (carousel card, B174) into `PlayConfig.Maps` with the acts.
- **TOOLING, EVERY SESSION (B64):** `require` from `execute_luau` is dead — paste `tools/hash_shared.luau` inline
  (`docs/systems/studio-testing.md`).

## Open threads (not yet PENDINGs)
- B172 Lobby rebuild (Holy Coast) built + verified (`lobby-map.md`); follow-ups in `tools/lobby_map/B172_PLAN.md`:
  phases 2-5 done (Story Gate, Star Sanctum + summon cutscene, Lumina city, map-wide VFX, bigger map; join 3.8 s);
  Areas card images to retake, optional waystones. User publishes the Lobby.
- B167 kit drift, not caused by B167: `Kit_ItemIconV2` (Lobby 98544bdf vs 1cd8e184), `Kit_HotbarSlotV2` (Lobby
  6f14cfb6, Game f5a7f240, manifest cd5a2aa0). Waiting on the user.

## Standing user rules (not in CLAUDE.md)
- The user republishes BOTH Places every session; mention it only when a contract bumps.
- Empty SoundIds (filled at release) and the 0.05 `UIHoverStroke.Thickness` are deliberate — don't raise them.
- Settled design, not bugs: 3 lives every act, Act 3 is a boss wall, ascension is THE power axis, abort pays
  nothing (`balance.md`); Weekend Rush is UTC+8, x2 on Victory incl. drops (`buffs.md`); Worthiness 100 is tuning.

## Standing patterns
- ONE writer each: `BannerChoiceService`→`BannerChoices` · `GrantService.SellUnits`→the only `Data.Units` delete ·
  `UnitConsumeRules` = "may this be destroyed" · `UnitFlagsService`→`Favorited`/`Locked` · `SettingsService` ·
  `DailyRewardService`→`LoginStreak`+`EventLoginStreaks` · `CodeService`→`RedeemedCodes` · `PendingReveals` ·
  `ShopService`→`ShopStock` · `QuestService`→`Quests` · `BattlepassService`→`Battlepass` (never the Game) ·
  `ReceiptService`→`ProcessReceipt`+`Purchases` · `UnitCapacityService` · `HudCurrencyService`.
- Pure `*Config`/`*Registry` + ONE service owning remote, grant, write; per-day state DERIVED via `MetaMath`;
  stored days are DAY NUMBERS. Check the schema for an unwritten field before a bump (`Titles` still unwritten).
- GRANT FIRST, MARK SECOND. A drop routes by its `ItemCatalog` `Kind`. Editing shared canon in one Place only is
  DRIFT: re-hash, mirror, update the manifest; copying a TEMPLATE across Places is a USER action (`tools/checklists.md`).
- Labels: changelog `B<n>` = session counters; blueprint `B1…B5` = session-task names; PlayGUI `P1…P7`.

History: `CHANGELOG.md` (newest 10) → `archive/`; grep it for one subject, never read it at bootstrap.
