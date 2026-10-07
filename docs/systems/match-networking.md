# Match networking (GAME place) -- every remote

<!-- owner: AD-Game | scope: game | migrated B123 (2026-10-07) from the retired in-Studio
     ServerStorage.Documentation.Networking (2026-07) and brought up to date from the live
     RS.Remotes tree. Architecture: match-architecture.md. -->

## Security model
Client asks, server decides. Handlers re-validate ownership / funds / zone / state on every call and
never trust a client's MetaLevel, Trait, loadout membership or cash. `NetworkService.BindRemoteEvent /
BindRemoteFunction` add a per-player rate limit + a shape check; failures warn and return a safe value.
RemoteFunctions answer with a result table (`{ Success, Reason }` or `{ ok, reason }`), never an error.

## RS.Remotes.Placement
- `RequestPlace` (RF) `(uuid, position)` -- PlacementValidator: state (Countdown / InProgress), the uuid is
  in the player's VALIDATED match loadout, trait-aware placement limit, zone + terrain (B120/B121: a real
  zone surface), path clearance, footprint overlap, funds. Returns `{ Success, Reason, Uuid, TowerId }`.
- `PlacementCountsChanged` (RE, s->c) -- per-uuid placed counts / limits for the hotbar.

## RS.Remotes.Towers (every one re-checks that the player OWNS the tower instance)
`RequestSell`, `RequestUpgrade`, `RequestUpgradeTo(model, tier, queueOnly)` (B86 buy-through / queue),
`RequestTargetingChange`, `RequestAutoUpgradeToggle`, `RequestUpgradePriority` (1..6),
`RequestAutoUpgradeAll`, `RequestSellAll`, `RequestActivateAbility(model, index?)` (B114 multi-ability),
`RequestAbilityAutoToggle`, `RequestSetLocked` (B87; honoured by Sell All only).

## RS.Remotes.Match
- `MatchStateChanged` (RE, s->all) -- the MatchReplicator snapshot (state, lives, wave, speed, clock,
  wave preview, prep / vote state, host, x3, difficulty...). `GetMatchSnapshot` (RF) -- late-joiner pull.
- `LoadoutAssigned` (RE, s->c) `(validatedLoadout, accountLevel)` -- at Countdown, and again whenever the
  Units screen changes the loadout (B123). `GetLoadout` (RF) -- the hotbar's pull.
- `MatchResults` (RE, s->c) -- end-screen payload. `RequestMatchAction` (RE) -- ReturnToLobby / Restart /
  Replay / Next votes, server-validated.
- `RequestWaveSkipVote` (RE) -- ready / skip vote. `RequestGameSpeed` (RE) -- host only; 3x gated.
- `GetHudInfo` (RF, read-only level / XP / quests), `SetAutoPlay` (RF), `GetStageInfo` (RF).

## Top-level RS.Remotes (B123: the copied Lobby screens)
- Units screen (`Server.Units.UnitsScreenService`): `GetUnitViews`, `SetLoadoutSlot`, `SetLoadout`,
  `GetUnitTeams`, `SaveUnitTeam`, `LoadUnitTeam`, `RenameUnitTeam` (writes refuse `match_running` while a
  wave runs); `SetUnitFlags`, `SellUnits`, `BuyUnitSlots`, `SwapTraitSlots` always refuse `lobby_only`.
- Quests screen (`Server.Meta.MatchQuestService`): `GetQuests`, `ClaimQuest`, `ClaimAllQuests`,
  `SetQuestPin`.
- `CharacterFX` (RE, dash / double-jump relay), `EnemyKilled` (RE), `AdminBroadcast` (RE).

## RS.Remotes.Economy / Combat / Settings
- `Economy.CashChanged` (RE, s->c) -- this player's wallet only, never broadcast.
- `Combat.VFXEvent` (RE, s->all) -- cosmetic only, first arg is the event type (TowerFired, AttackShape,
  DamageNumber, AttackVFX / Projectile, TowerLifecycle...). Carries no authority.
- `Settings.GetSettings` (RF) / `Settings.SaveSettings` (RE) -- shared settings (`settings.md`).

## Not a remote
- Enemy health: an Instance Attribute written by EnemyController, read directly by the client.
- `RS.ClientEvents` (Game, B123): client-only BindableEvents the copied screens talk through
  (ToggleUnits, ToggleQuests, OpenUnitsWithUuid, OpenQuests, ScreenOpened, LoadoutChanged, ShowRewards,
  PinsChanged).
