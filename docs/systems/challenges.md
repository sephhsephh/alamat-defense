# challenges — the daily challenge stage (Game meta, AD-Game)
<!-- owner: AD-Game | scope: game + lobby (ChallengeConfig/MatchModifiersConfig/MetaMath/MetaConfig shared) | added: 2026-09-04 (B51 Game side, B52 Lobby tab), Phase D/D2 -->

Blueprint Phase D / D2. A **daily-rotating challenge**: a harder match (modifiers) whose Victory
drops the crafting **fragments** — the real SOURCE the crafting loop (D1, B50) was built for. Until
this landed, fragments came only from an interim shop source; challenges are the intended faucet.

## The shape (all Game-side except two promoted shared modules)
A challenge is a **Classic match plus modifiers plus a fragment reward**. Three moving parts:
- **`RS.Configs.Global.ChallengeConfig`** (pure) — the challenge POOL + the deterministic daily pick.
- **`RS.Configs.Global.MatchModifiersConfig`** (pure) — the modifier registry + `Resolve`.
- **`SSS.Server.GameModes.Challenge`** — a thin GameMode over Classic, registered in `GameModeRegistry`.

## Server-authoritative, always
The Lobby only asks to launch "the challenge" (`GameMode = "Challenge"` on the teleport payload — an
**additive, forward-tolerant** field, no version bump). The **Game** resolves the day's stage,
modifiers AND reward from `ChallengeConfig` off the day Slot, **never from the (client-forgeable)
payload**. `MatchEntryService` overrides the payload's `StageId`/`MatchModifiers` with the day's
values and stashes `ChallengeDaySlot`. Verified: a payload naming a junk `StageId` is ignored and the
real challenge stage is used. So a forged payload cannot pick an easier stage, drop the modifiers, or
choose the reward.

## The daily pick (needs MetaMath + MetaConfig in the Game — promoted at B51)
`ChallengeConfig.GetDaily()` is `GetForSlot(MetaMath.Slot(86400, MetaConfig.ResetOffsetSec))` — the
SAME deterministic daily boundary the Lobby's shop/daily/quests use. This is why B51 **deployed
MetaMath to the Game** (it was Lobby-only "until Phase D", exactly as its manifest note anticipated)
and **promoted MetaConfig to shared canon** (byte-identical, `5166d377`, both Places) — challenges are
the first Game-side consumer of both. B52 then promoted `ChallengeConfig` (`c000ba58`) and
`MatchModifiersConfig` (`6b209b22`) to shared canon too, so the Lobby reads the SAME `GetDaily()` the Game
resolves. Drift is now 39/39 in both Places.

- `GetForSlot(slot)` rotates the POOL by `slot % #POOL` and derives the reward from the slot, so entry
  and match-end agree even minutes apart. `RewardsForSlot(slot)` is a pure `RngForSlot`-seeded pick of
  a rotating fragment **colour** (2, sometimes 3), with a ~10% bonus artifact of that colour.
- The `DaySlot` is stashed on the match config at ENTRY and re-read at grant, so a match that
  **straddles the daily reset still pays the day it STARTED**.

## Modifiers (`MatchModifiersConfig`)
Opaque string ids (the teleport contract's `MatchModifiers: {string}`) resolved to a small effects
table. Modifiers only ever make a match **HARDER**, so an unknown id doing nothing is safe (it can
only remove difficulty, never invent a reward). Applied in **`MatchDirector.buildValidatedMatchState`
— the ONE place**, a GENERIC step that runs for any match carrying modifiers (the Challenge GameMode
itself stays free of modifier math):

| effect | applied to | live modifier ids |
|---|---|---|
| `EnemyHpMult` | folded into `matchState.EnemyHealthScale` (every enemy at spawn) | `EnemyHpX1_5`, `EnemyHpX2` |
| `LivesMult` | multiplies the resolved starting lives | `HalfLives` |
| `LivesCap` | hard minimum on starting lives (floored at 1 — never 0) | `OneLife` |

`Resolve(list)` folds a list: HP/lives mults MULTIPLY, LivesCap takes the MIN. Verified live: a
challenge on Stage1_Act1 (base 3 lives) with `EnemyHpX2 + HalfLives` ran at **1 life, 2x enemy HP**.

**NOT-YET-APPLIED, named for the roadmap** (deliberately absent from every live modifier so nothing
silently claims to do something it doesn't): `RangeMult` / `SpaMult` (need a tower-stat seam) and
`NoFarm` (needs an EconomyManager seam). Add one **here AND at its seam together**.

## The reward + counter (`RewardCalculator`)
On a **challenge Victory**, `GrantForPlayer` appends the day's `RewardsForSlot(ChallengeDaySlot)` to
`drops`, so the fragments flow through the SAME `ItemCatalog`-Kind routing (Fragment/Artifact are
`Kind="Item"` -> `AddItem`) and the SAME end-screen path as any other drop. It also increments
**`Counters.Global.ChallengeClears`** — LIFETIME + MONOTONIC, the same cross-Place counter-name
contract as `Clears`/`InsaneVictories`, so a Lobby quest can read it as a baseline delta. Verified
live: a challenge Victory committed `FragmentGreen` +2 and `ChallengeClears` 0->1.

## The Lobby Challenge tab (B52)
Built at B52. `ChallengeConfig`/`MatchModifiersConfig` are now SHARED (see above), so the Lobby reads
`ChallengeConfig.GetDaily()` directly to DISPLAY and LAUNCH today's challenge -- no Game->Lobby remote.
- **`StarterGui.Challenge` + `ChallengeController`** -- a blockout screen showing the day's name, its
  modifiers (`MatchModifiersConfig.Describe`) and reward (`ItemCatalog` names). Opened from
  `Workspace.Lobby.NPC_Challenge` (the "Challenge Master" ProximityPrompt, ADR-0010 NPC-screen shape) or
  `ClientEvents.OpenChallenge`. Its **Start** button fires the EXISTING `Remotes.RequestLaunch` with
  `GameMode="Challenge"` + the day's `StageId` + `DifficultyPercent=100` (the modifiers, not the slider,
  are the difficulty) and shows the SAME `LoadingScreen` veil the StartButton uses. It reinvents no
  launch path -- one more CALLER of the one remote (blueprint sec 11/12).
- **`GameMode` on the wire** -- `PartyService` honours a `req.GameMode=="Challenge"` override (only that
  one) and passes it to `LaunchService.BuildPayload`, which adds `GameMode` to the `MatchLaunch` payload.
  ADDITIVE + forward-tolerant (an older Game ignores it), so NO teleport-version bump. Absent for a normal
  launch. The Game re-resolves the challenge server-authoritatively, so the payload is only a request.
  Verified live: the Lobby screen rendered "Brutal Fields / 2x HP + half lives / 2x Violet Fragment",
  Start built `MatchLaunch v4 ... gameMode=Challenge stage=Stage1_Act1` (ReserveServer is 403 in Studio,
  so the assertion is on the payload BUILT, as with every teleport-contract check).

## What's still open (follow-ups)
- **Varied base stages + bespoke challenge wave content** — the pool currently bases every entry on
  `Stage1_Act1`; the challenge is the modifiers + reward, not new waves yet. Tuning follow-up.
- **`RangeMult`/`SpaMult`/`NoFarm`** modifiers — see the seams noted above.

## Verifying a change
`ChallengeConfig.Validate()` checks every template names a stage-shaped id + known modifiers and every
colour's reward ids are catalogued. `MatchModifiersConfig.Resolve`/`ApplyLives` are pure and unit-testable.
For the match path, assert on the profile DELTA (`FragmentColour`, `ChallengeClears`) from a real
`RewardCalculator.GrantForPlayer` on a fabricated challenge `matchState`, and peek `GetActiveMatchState()`
after a `StartMatch` for the modifier-applied `Lives`/`EnemyHealthScale`. The `execute_luau` require-cache
trap applies — verify from a fresh Play server VM.
