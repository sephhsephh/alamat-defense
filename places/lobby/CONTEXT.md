# CONTEXT — Lobby place ("Alamat Defense - Lobby")
<!-- owner: lobby | scope: lobby | last-verified: 2026-10-21 (B170) | BUDGET 6,000 chars: what the Place IS NOW.
     No history here -- that is CHANGELOG + archive/lobby-CONTEXT-history.md. -->

The social/meta Place: collection, banners, upgrades, stage + difficulty select, parties, matchmaking and the teleport
into the Game. `Workspace.Lobby` present + `RS.Configs.Towers` ABSENT = the Lobby Place assertion.

## Core paths
- **Read:** `GetUnitViews` is the ONE profile read path (ADR-0004; additive fields free, `GetCollection` retired).
  Clients never read profiles.
- **Write:** `SSS.Server.Meta.GrantService` is the ONE grant/spend path (`Spend` the one debit; `SellUnits` the only
  `Data.Units` delete). Every other service grants through it. `docs/systems/gacha.md`.
- **Boot:** `Server.Bootstrap` asserts the save contract and runs `PlayerDataService.Init()` (schema v11,
  `docs/contracts/save-schema.md`; dev store `Beta1_PlayerDataDev1`, shared with the Game).
- **Launch:** `Server.Lobby.LaunchService` is THE launch body (called by `PartyService` + `MatchmakingService`);
  `Remotes.RequestLaunch` is the only client entry. Teleport v4, `GamePlaceId` 125430066355564 (`teleport.md`).
- **Return:** `MatchReturnService` reads `TeleportData.MatchReturn` and applies BP XP once per join (`teleport.md`).

## Where things live
- Server: `SSS.Server.Meta.*` (Grant, Summon/SummonEngine, BannerChoice, Ascension, Evolution, Feed, Crafting,
  Trait/StatReroll, UnitCapacity, HudCurrency, Shop, Quest, Battlepass, DailyReward, Code, Mail, Receipt, Luck, Buff,
  UnitDiscovery, UnitsChanged, ShinyHunter), `SSS.Server.Lobby.*` (Launch, Party, Matchmaking, LobbyMap),
  `SSS.Server.Admin.*`.
- Configs: `RS.Configs.{Gacha, Banners, Evolutions, Meta (incl. MetaConfig, UnitCapacityConfig, IndexLore),
  StageRegistry (mirror of the Game's stages), Global}`. Shared canon list: `shared/manifest.json`.
- Art: `RS.UnitModels` (full-size rigs, same names as the Game's `TowerModels`), `RS.AlamatUI`, `RS.CharacterFX`.
- Scene: `Workspace.Lobby.Map` (night-island, AI meshes + particle VFX), NPCs routed by `NpcPromptRouter`.
- Client glue: `RS.ClientEvents` (`OpenStageSelect`, `ShowRewards`, `OpenBuffs`, …), `StarterPlayerScripts.HudEntry`,
  `Client.UI.{ScreenFX, MenuMovementLock, ViewportIdle}`.

## Screens → docs (all authored in StarterGui)
HUD (Alamat kit, Command Rails) `alamat-ui.md` · Play menu `play-menu.md` · Units Hero Hall `units-screen.md` ·
Summon `summon-screen.md` + `gacha.md` · Index `collection-index.md` · Items `inventory.md` · Ascension
`ascension.md` · Evolve `evolution.md` · Feed / EXP food `exp-food.md` · Crafting `crafting.md` · Trait reroll
`trait-reroll.md` · Stat reroll `stat-reroll.md` · Shop `shop.md` · Quests `quests.md` · Achievements
`achievements.md` · Events `events.md` · Daily `daily-rewards.md` · Codes `redeem-codes.md` · Inbox `inbox.md` ·
Battlepass `battlepass.md` · Leaderboards `leaderboards.md` · Buffs `buffs.md` · Areas `areas.md` · Settings
`settings.md` · Loading `loading-screen.md` · Rewards reveal `reward-reveal.md` · Confirm/toast/sound
`ui-feedback.md` · Map `lobby-map.md` · Admin `admin.md` · other screens `lobby-ui.md`.

## Hazards (one line each; detail in the linked doc)
- Reveal = the remote's RETURN VALUE for a click; `RewardPush` only for server-decided grants; draining never grants
  (`reward-push.md`). Every reveal goes through `ClientEvents.ShowRewards`, never a rebuild (`reward-reveal.md`).
- Pity = `Data.Pity[ref]`; pulls count on `Counters.Global.GachaPulls`, not `Summons` (ADR-0008, `gacha.md`).
- Unit capacity is enforced ONLY in `SummonService`, before the spend; every other grant overflows
  (`unit-capacity.md`).
- `MetaMath` is the one per-day derivation; stored days are day numbers (`daily-rewards.md`).
- Every redeem code is PUBLIC; the rate limit is security (`redeem-codes.md`).
- Matchmaking: an entry is a PARTY; host = lowest userId; the match runs at the host's exact wire difficulty;
  `MatchmakingRules.BucketOf` is not the ADR-0011 conversion (`teleport.md`).
- Difficulty: PlayGUI's 1–100 is display-only; `PlayGUI.DifficultyScale` is THE ADR-0011 conversion (`play-menu.md`).
- `StageRegistry` mirror goes stale silently on a rename (`lobby-ui.md`).
- Lobby has no `TowerConfig`: prices come from `UnitStatsCatalog` via `UnitCard.paintPrice` (`hotbar.md`); a
  unit missing from `RS.UnitModels` previews as `Placeholder` (CLAUDE.md).
- HUD buttons: names end in `Button`; wire via `HudEntry` (boot race + `ResetOnSpawn`); `ProfileButton` is unwired
  (`lobby-ui.md`).
- Screens slide via `Motion.slideIn/slideOut`; test `Motion.isOpen(main)`, not `gui.Enabled` (`ui-kit.md`).
- Bare `WaitForChild` never times out — use `need()`; never block boot on a streamed Workspace instance
  (`ui-feedback.md`, `studio-testing.md`).
- Never add a `UIScale` to hashed canon (`ObtainRewardsGUI` scales runtime clones only) (`lobby-ui.md`).
- Best-of-N luck rerolls never compare against current values, so a reroll can downgrade (`buffs.md`).
- `ReserveServer` is 403 in Studio; `DevSimulateReturn` fires only on join (`studio-testing.md`).
- Lobby CONSUMES and never edits: save schema, tower/progression/trait configs, `RewardScalingConfig`.
