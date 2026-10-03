# Achievements (Lobby) -- B109 M2

<!-- owner: lobby | scope: lobby | last-verified: 2026-10-03 (B109 M2) -->

Decisions: `docs/specs/2026-10-03-quests-events-overhaul.md` (refs = the user's Achievements screenshots).

| piece | where | job |
|---|---|---|
| `Configs.Meta.AchievementConfig` | RS (Lobby) | **Edit here.** Categories (Id, Name, Color, Milestones `{Pct, Reward}`, List) + achievements (Id, Name, Desc with one `{link}`, Link, Goal, Reward, Hidden). |
| `Configs.Meta.GoalEval` | RS (Lobby) | THE lifetime-goal evaluator (Counter, Level, StageClear, **HardActs**, Stars(+Acts), **InfiniteBest**, UnitsOwned, **UnitsDistinct**, UnitLevel, **Shiny**, **Ascension**, Equipped, Codes). Pure. Events adopt it at M3. |
| `Server.Meta.QuestService` | SSS | Still the ONE `Data.Quests` writer: `Data.Quests.Ach = { Claimed = {[id]=true}, Milestones = {[catId]={[i]=true}} }`. Remotes `GetAchievements`, `ClaimAchievement(id)`, `ClaimAllAchievements(catId?)`, `ClaimAchievementMilestones(catId)`; pins are `SetQuestPin("A:<id>")`. `GetQuests` also returns `Achievements` (flat) for the HUD badge + toast. |
| `StarterGui.AchievementsGUI` + `AchievementsController` | StarterGui | AUTHORED window (CategoryTemplate / RowTemplate / MarkerTemplate cloned). |

## Rules
- Categories (user): **Story** (per map: all acts on **Hard** = `HardClearsByStage`, Game-written), **The Collector**,
  **Infinite + Challenge**, **Secrets** (`Hidden` -> "???" until complete). Rewards: items/currency only.
- Goals are LIFETIME; a player who already did it can claim at once. One claim per achievement, never reset.
- **Category progress = achievements CLAIMED / total.** Milestones (25/50/75/100%; Secrets 50/100) are claimed
  from the gift button -- every reached, unclaimed one at once. The box shows the NEXT unclaimed milestone's rewards.
- GRANT FIRST, MARK SECOND; claiming unpins. Reveal = return value (`ShowRewards`).
- Window: sidebar categories (claimable badge = achievements + milestones) + Claim All (every category);
  per-category theme; rows sorted claimable -> in progress -> claimed (strike + check); X / Claim / check status
  button; pin; `{link}` opens Play/Summon/Units. "Quests" returns to the Quests window. Gamepad B close,
  L1/R1 category, Y Claim All; window tagged `GamepadMenu`. Harness: `AchievementsGUI` attribute `DevOpen = "<catId>"`.

## Verified live (B109 M2, Lobby, real clicks)
Quests -> Achievements; Story + Collector themes; Claim All claimed 6 (Gold/Silver rose); Collector 4/6 (67%),
gift green -> claimed 25% + 50% milestones, next shows "at 75%"; claimed row strike + check.
