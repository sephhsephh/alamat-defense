# Match end — item preview, results screen, Replay/Next votes (B75)

**Owner:** AD-Game. **Place:** Game only. No shared canon, no schema change, no teleport bump.

## Flow

1. `MatchDirector.MatchEnded` -> `RewardCalculator.GrantForPlayer` commits payouts, then returns
   `Items = { {Id, Name, Tier, Description, Count, Owned}, ... }` (Gold first, then drops; `Owned` read
   after the commit from `account.Currencies` / `account.Items`).
2. `MatchEndPresenter` sends the result payload. B75 fields: `StageName`, `ActName`, `ActNumber`,
   `DifficultyMode`, `IsChallenge`, `VotesNeeded`, `MyUnitsPlaced`, `MyCashEarned`, `MyDamage`, `MyKills`.
   A Challenge result has `NextActId`/`NextActTitle` = nil.
3. Client `MatchEndUI`:
   - **Item preview** (`MatchEnd.RewardPreview`): one item at a time — big icon pop, name, rarity,
     "Owned: Nx", description; a top strip gains a tile per item. Click anywhere advances. No items -> skipped.
   - **Results** (`MatchEnd.Results.Window`): outcome banner, act card (act / difficulty / stage name),
     six stat cards (Units Placed, Total Damage, Play Time, Money Earned, Takedowns, Waves Completed),
     reward tiles, buttons, UNIT XP list (portrait, tier, level, animated bar, level-up badge), player tag.
     X hides the window and shows `ShowResultsButton`. Keys after the preview: L lobby / R replay / E next.
   - A new match (`State` Preparing / Countdown / InProgress) hides everything.

## Stats sources (`MatchStatsTracker`)

- `UnitsPlaced` — `TowerManager.TowerPlaced` -> `RecordTowerPlaced` (was never called before B75).
  Towers placed BEFORE `Tracker.Start` (the harness does this) are not counted; real placements are.
- `CashEarned` — every positive `EconomyManager.CashChanged` delta, **including sell refunds**.

## Replay / Next (`MatchActionHandler`)

Why they were dead before B75: the old `startStage` put EVERY owned unit in the loadout (Schema rejects > 6),
and `NextAct` called `StartMatch` while the finished match was still `IsRunning` (~4s teardown).

Now:
- On `MatchEnded` the handler keeps `ended = {Config (deep copy), StageId, Outcome, IsChallenge, Eligible, Votes, Starting}`.
- `VoteReplay` / `VoteNext` (legacy `Restart`+payload / `NextAct` map onto them). One ballot per player.
- A vote resolves only when **every eligible player still present** voted the same way (solo = one click).
  `PlayerRemoving` re-resolves. Counts go out on **`Remotes.Match.MatchEndVotes`**
  `{Replay, Next, Needed, NextAvailable, Starting}`; buttons read "Replay (n/need)" / "Next (n/need)".
- `startFromConfig` waits (<= 20s) for `IsRunning() == false`, deep-copies the finished config (same
  loadouts, difficulty mode, modifiers, host), swaps `StageId`/`MapId`/`Difficulty`, drops absent players,
  clears a departed host. A refused start resets the votes.
- **Next** exists only on a Victory with a `NextActId`, never in a Challenge (the reference's
  "Change Stage" is implemented as Next).
- Settings-panel `Restart` (no payload, mid-match) aborts (pays nothing, B41) and replays the active config.

Proven live (Studio): Replay restarted Stage1_Act1 and hit `[MapLoader] Reusing RESIDENT map` (first proof
of B71's reuse branch); Replay kept Insane; Next moved Act1 -> Act2; preview showed 4 items; results showed
4 reward tiles + 5 unit rows; Close / Show Results work; Lobby button reaches the server (teleport fails in Studio, expected).

## UI authoring

`StarterGui.MatchEnd` is built by an idempotent Edit-mode builder (tag `B75Built`, 140 instances);
`ZIndexBehavior = Sibling` (Global hid cloned kit tiles), `DisplayOrder = 30`. Kit tiles inside
ScrollingFrames are sized in **pixels** (scale collapses under AutomaticCanvasSize). The old `Panel`,
`RewardRowTemplate`, `TowerRowTemplate` are hidden, not deleted — the user may delete them by hand.
