# Ownership registry (single writer per system)
<!-- owner: all (append rows; changing an existing row needs the current owner's session) -->
<!-- last-verified: 2026-07-17 -->

Rules: the OWNER chat is the only writer of that system's code, docs, and contracts.
"Home Place" is where the system's runtime lives (a chat may still *read* anywhere).
Cross-cutting work (e.g. UI inside both Places) binds to whichever Place the specific
task touches — resolved at bootstrap per the constitution.

| System | Owner chat | Home Place | Canon location |
|---|---|---|---|
| Save schema / ProfileTemplate | AD-Game | Game | `shared/src/ProfileTemplate.luau` + `docs/contracts/save-schema.md` |
| PlayerDataService / ProfileStore deploys | AD-Game | both | `shared/src/` + `shared/manifest.json` |
| Match lifecycle (MatchDirector, waves, modes) | AD-Game | Game | Studio (Game) `SSS.Server` |
| Economy (EconomyManager, EconomyConfig) | AD-Game | Game | Studio (Game) until exported |
| Rewards / match stats | AD-Game | Game | Studio (Game) `Server.Rewards`, `Server.Stats` |
| Teleport payload contract | AD-Lobby | both | `docs/contracts/teleport.md` |
| Lobby scene & flow (stage select, parties) | AD-Lobby | Lobby | Studio (Lobby) |
| Shop / banner catalog (future) | AD-Gacha | Lobby | TBD when built |
| Gacha / banners / pity (future) | AD-Gacha | Lobby | TBD when built |
| UI (StarterGui screens, HUD, panels) | AD-UI | both | Studio (per Place) StarterGui + `docs/systems/ui.md` (when migrated) |
| PlayerLevel / progression curves | AD-PlayerLevel | Game | Studio (Game) `RS.Configs.Global.TowerProgressionConfig`, `MetaScalingConfig` |
| Tower models / rigs / animations | AD-TowerModels | Game | Studio (Game) `RS.TowerModels`, `ServerStorage.Archive` sources |
| Tower configs & combat (targeting, attacks, passives, abilities, summons) | AD-Game | Game | Studio (Game) `RS.Configs.Towers`, `Server.Towers`, `Server.Summons` |
| Enemies (configs, controller, behaviors) | AD-Enemies | Game | Studio (Game) `RS.Configs.Enemies`, `Server.Enemies` |
| Traits | AD-Traits | Game | Studio (Game) `RS.Configs.Traits` |
| Maps / stages / waves content | AD-Game | Game | Studio (Game) `RS.Configs.{Maps,Stages,Waves}`, `ServerStorage.Maps` |
| Settings (client settings pipeline) | AD-Game | both | Studio (Game) `Server.Settings` + profile `Settings` field |
| Repo / constitution / tooling | AD-Integration | — | this repo root + `tools/` |

Notes:
- A "chat" here is a persistent named conversation; one human can of course run only a
  few at once — the constitution's sync rules are what make any number of them safe.
- Splitting a row (e.g. combat out of AD-Game into AD-Towers) = edit this table in the
  current owner's session + changelog entry.
