# D2 Challenges — the rotating modifier stage that feeds crafting (needs the Game place)
<!-- from: AD-Meta/AD-Gacha | to: AD-Game (Game place) | status: GAME SIDE SHIPPED B51 (2026-09-04) -- see docs/systems/challenges.md; Lobby tab is the remaining follow-up | 2026-09-02 (B50) -->

## The ask
Build **Phase D / D2 challenges**: a daily-rotating modifier stage, entered from the Lobby, that at
match end drops the **crafting fragments** (and artifacts) — the REAL source that crafting (D1, shipped
B50) was built for. Until this lands, fragments come from an **interim shop source** (7 fragments in
`ShopConfig`, B50); challenges replace/augment that.

## Why this is AD-Game's
It is a MATCH / STAGE / MODIFIER system living in the Game place (their canon). The Lobby half (a stage
select "Challenge" tab + a teleport carrying the chosen modifiers) is small and can be AD-Lobby/AD-Meta,
but applying the modifiers in-match and granting rewards at match end are Game-side.

## Blueprint spec (`phases-b-f-meta.md` Phase D)
`ChallengeConfig.Daily = deterministic pick(slot(86400)) from a pool of { StageId, Modifiers = {...},
Rewards }`. Modifiers reuse **MatchModifiers** (extend ClassicMode to apply: NoFarm, RangeMult, SpaMult,
LivesCap, ...). Entry via the Lobby stage-select "Challenge" tab → normal teleport with `MatchModifiers`;
a completion counter → quests + **fragment/artifact rewards via GrantService at match end**.

## What D1 already provides (so D2 is unblocked on the crafting side)
- **The reward ids exist and are catalogued in BOTH Places** (B50): `Fragment{Red..Violet}` (Rare),
  `Artifact{Red..Violet}` (Epic), `ArtifactRainbow` (Mythic). `ItemCatalog 9be86a5f → 2ee5f976`,
  36/36. So the Game can grant them at match end through `GrantService`/`RewardCalculator` with no new
  catalog work — the same way Insane wins already drop `TraitRerollToken`/`StatRerolls`.
- **The crafting sink is live**: `CraftingService` + `CraftingRecipes` + the screen (`crafting.md`).
- **Deterministic daily pick** has a home: `MetaMath.Slot(86400, ResetOffsetSec)` (shared) — the same
  mechanism the shop/daily/quests already use.

## The pieces D2 needs (Game-side unless noted)
1. `ChallengeConfig` (Game) — the pool of `{ StageId, Modifiers, Rewards }`; `MetaMath.Slot` picks the
   day's challenge. Rewards list drops fragments (e.g. 1-2 of a rotating colour) + occasionally an artifact.
2. **MatchModifiers application** (Game) — extend `ClassicMode`/the match director to honour NoFarm /
   RangeMult / SpaMult / LivesCap, etc.
3. **Match-end grant** (Game) — `RewardCalculator` grants the challenge's `Rewards` through GrantService,
   plus a completion counter for quests (`ChallengeClears` or similar, a new `Counters.Global` key).
4. **The teleport carries the modifiers** — `MatchModifiers` on the teleport payload. This is a payload
   shape change (additive; version bump per `teleport.md` if the Game requires it). Cross-Place — route
   through an AD-Integration touch.
5. **Lobby "Challenge" tab** (AD-Lobby/AD-Meta, small) — a stage-select entry that launches with the
   day's `MatchModifiers`. Can follow after the Game side lands.

## Sequencing
D1 crafting is live and playable now (interim shop fragments). D2 makes the fragment economy real and
adds the modifier-stage content. It is a Game-place session + a small Lobby follow-up + one Integration
touch for the payload. Nothing else blocks on it.
