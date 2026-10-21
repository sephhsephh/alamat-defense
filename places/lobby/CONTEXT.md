# CONTEXT — Lobby place ("Alamat Defense - Lobby")
<!-- owner: lobby | last-verified: 2026-10-21 (B170) | BUDGET 6k chars: what the Place IS NOW; history lives in
     CHANGELOG + archive/lobby-CONTEXT-history.md -->

The social/meta Place: collection, banners, upgrades, stage select, parties, matchmaking, teleport into the Game.
`Workspace.Lobby` present + `RS.Configs.Towers` ABSENT = the Lobby Place assertion.

## Core paths
- Read: `GetUnitViews` is the ONE profile read path (ADR-0004; additive fields free; `GetCollection` retired).
- Write: `SSS.Server.Meta.GrantService` is the ONE grant/spend path (`Spend` the one debit, `SellUnits` the only
  `Data.Units` delete) (`gacha.md`).
- Boot: `Server.Bootstrap` asserts the save contract, runs `PlayerDataService.Init()` (schema v11; dev store
  `Beta1_PlayerDataDev1`, shared with the Game).
- Launch: `Server.Lobby.LaunchService` is THE launch body (for `PartyService` + `MatchmakingService`);
  `Remotes.RequestLaunch` the only client entry; teleport v4, `GamePlaceId` 125430066355564 (`teleport.md`).
- Return: `MatchReturnService` reads `MatchReturn`, applies BP XP once per join (`teleport.md`).

## Where things live
- Server: `SSS.Server.Meta.*` (Grant, Summon, Ascension, Evolution, Feed, Crafting, rerolls, Shop, Quest,
  Battlepass, DailyReward, Code, Mail, Receipt, Luck, Buff, ...), `SSS.Server.Lobby.*` (Launch, Party,
  Matchmaking, LobbyMap), `SSS.Server.Admin.*`.
- Configs: `RS.Configs.{Gacha, Banners, Evolutions, Meta, StageRegistry (Game mirror), Global}`; canon list
  `shared/manifest.json`.
- Art: `RS.UnitModels` (full-size rigs, Game names), `RS.AlamatUI`, `RS.CharacterFX`; scene `Workspace.Lobby.Map`
  (NPCs via `NpcPromptRouter`).
- Client glue: `RS.ClientEvents`, `StarterPlayerScripts.HudEntry`, `Client.UI.{ScreenFX, MenuMovementLock, ViewportIdle}`.

## Screens → docs (authored in StarterGui)
HUD `alamat-ui.md` · Play `play-menu.md` · Units `units-screen.md` · Summon `summon-screen.md` · Index
`collection-index.md` · Items `inventory.md` · Ascension · Evolve `evolution.md` · Feed `exp-food.md` · Crafting ·
Trait/Stat reroll · Shop · Quests · Achievements · Events · Daily `daily-rewards.md` · Codes `redeem-codes.md` ·
Inbox · Battlepass · Leaderboards · Buffs · Areas · Settings · Loading `loading-screen.md` · Rewards
`reward-reveal.md` · feedback `ui-feedback.md` · map `lobby-map.md` · Admin · the rest `lobby-ui.md`. Unnamed
docs = the lower-cased screen name (`ascension.md`, `shop.md`, ...).

## Hazards (detail in the linked doc)
- A click's reveal is the remote's RETURN VALUE; `RewardPush` only for server-decided grants; draining never grants
  (`reward-push.md`); every reveal fires `ClientEvents.ShowRewards`.
- Pity = `Data.Pity[ref]`; pulls count on `Counters.Global.GachaPulls` (ADR-0008, `gacha.md`).
- Unit capacity: only `SummonService`, before the spend; other grants overflow (`unit-capacity.md`).
- Per-day state via `MetaMath`; stored days are day numbers. Redeem codes are PUBLIC; the rate limit is security.
- Matchmaking: an entry is a PARTY; host = lowest userId at their exact wire difficulty (`teleport.md`).
- PlayGUI's 1–100 is display-only; `PlayGUI.DifficultyScale` is THE ADR-0011 conversion (`play-menu.md`).
- `StageRegistry` mirror goes stale silently on a rename (`lobby-ui.md`).
- No `TowerConfig` here: prices via `UnitCard.paintPrice` (`hotbar.md`); a unit missing from `RS.UnitModels`
  previews as `Placeholder`.
- HUD buttons end in `Button` and wire via `HudEntry`; `ProfileButton` is unwired (`lobby-ui.md`).
- Screens slide via `Motion.slideIn/slideOut`; test `Motion.isOpen(main)` (`ui-kit.md`).
- Bare `WaitForChild` never times out — `need()`; never block boot on a streamed instance (`studio-testing.md`).
- Never add a `UIScale` to hashed canon (`lobby-ui.md`).
- Best-of-N luck rerolls can still downgrade (`buffs.md`).
- `ReserveServer` 403 in Studio; `DevSimulateReturn` fires on join only (`studio-testing.md`).
- Lobby CONSUMES, never edits: save schema, tower/progression/trait configs, `RewardScalingConfig`.
