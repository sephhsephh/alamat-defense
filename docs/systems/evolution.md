# Evolution (evolved forms) — B106 S-Evo
<!-- owner: AD-Gacha (Lobby) + AD-Game (the evolved tower configs) | built B106 -->

An evolved form is its OWN tower (`Mayari_LunarEclipse`, shown `Mayari (Lunar Eclipse)`), reached only by
evolving the base unit at the **Evolve NPC** (`Workspace.Lobby.NPC_Evolve`) — never pulled from a banner.
Blueprint: `docs/blueprints/phases-b-f-meta.md` Phase F (this build EXTENDS its `Requires` with the user's
B106 gates, approved in the design session).

## Pieces

| Where | What |
| --- | --- |
| Game `RS.Configs.Towers.<Base>_<Form>` | The evolved config: a copy of the base with +30% Damage per tier + one new mechanic. Registered in `TowerConfigRegistry`, rig in `RS.TowerModels` (placeholder). |
| Shared `ItemCatalog` | Evolved entries carry `Summonable = false` + `EvolvedFrom`; relic item `ScarecrowCrown`. |
| Lobby `RS.Configs.Banners.BannerRegistry` | `AllSummonable` skips `Summonable = false`. |
| Lobby `RS.Configs.Evolutions/<Base>` | One recipe per base: `{ BaseTowerId, ResultTowerId, Requires = { Items, Counters = { PerUnitKills }, OwnsTowerId, Sacrifice = { MinTier }, MaxLevel, Silver } }`. |
| Lobby `RS.Configs.Evolutions.EvolutionRegistry` | Auto-scans the folder; **`Check(data, uuid, sacrificeUuid)` is THE rule** (screen and server both call it). |
| Lobby `GrantService.EvolveUnit` | **THE write**: re-Check -> sacrifice must pass `UnitConsumeRules.Reason` -> `SpendItems` (+Silver) -> new record PRESERVING trait (active + stored + pity), shiny, rolls, level/XP, ascension, worthiness, lock/favourite -> new uuid replaces the old IN PLACE in `Data.Loadout` -> base (and sacrifice) deleted. |
| Lobby `SSS.Server.Meta.EvolutionService` | Remotes `GetEvolutionInfo` / `EvolveUnit(uuid, sacrificeUuid?)`; one evolve in flight per player. |
| Lobby `StarterGui.Evolution` + `EvolutionController` | A clone of the authored Crafting screen (`EvolveTemplate` rows); `Main` tagged `GamepadMenu`. Auto-picks the lowest eligible sacrifice and confirms (`UIKit.Confirm`). A row whose requirements are not met does NOT open the confirm: it shows `Not ready yet -- <have/need>` (the server re-checks regardless). |

**Takedowns** have no per-unit kill counter in the save; they are read from `Worthiness` x
`EvolutionRegistry.KILLS_PER_WORTHINESS` (50, mirrors the Game's `WorthinessConfig.PointsPerKill` 0.02), so the
proxy caps at 5,000. **Max level** = `EvolutionRegistry.MAX_META_LEVEL` (100). Change both if the Game's do.

## Current recipes (all: Rainbow Artifact x1 + fragments + Scarecrow Crown)

| Base -> form | Fragments | Crowns | Gate | New mechanic |
| --- | --- | --- | --- | --- |
| Mayari -> Lunar Eclipse | Violet x20 | 1 | owns Apolaki | crits Weaken 3 s |
| Apolaki -> Zenith | Orange x20 | 1 | max level | Rising Sun 8%/wave to +80% |
| Bathala -> Ascended | Yellow x30 | 3 | sacrifice a Mythic+ | all your towers SPA x0.9 |
| Bakunawa -> Eclipse | Blue x30 | 2 | 5,000 takedowns | Eclipse every 5th attack |

`ScarecrowCrown` drops from `Stage1_Act3` (15%, the only boss act); later stages should add their own relics.

## Adding one
1. Game: copy the base config to `<Base>_<Form>`, change Id/DisplayName/ModelStoragePath, apply the change, register it, add a rig (both Places).
2. Shared: `ItemCatalog` entry with `Summonable = false, EvolvedFrom = "<Base>"` + `UnitStatsCatalog` rows; re-hash both Places + manifest.
3. Lobby: `RS.Configs.Evolutions/<Base>` recipe. Nothing else — the registry, service and screen pick it up.
