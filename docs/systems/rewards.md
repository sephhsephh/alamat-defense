# Rewards — match-end payouts (AD-Game canon)

<!-- owner: game | scope: game (+ one SHARED config the Lobby preview reads) | last-verified: 2026-08-14 (B20) -->

Everything a player earns for finishing a match. **The server is the only thing that grants** —
the client is shown the outcome and never performs a roll. Rolling drops client-side would let
anyone reroll until a Legendary landed.

## The pieces

| Thing | Where | Owns |
| --- | --- | --- |
| `RewardCalculator` | `SSS.Server.Rewards` | computes AND commits everything below |
| `MatchEndPresenter` | `SSS.Server` | calls it once per player on `MatchEnded`, then fires `MatchResults` |
| `StageConfig.Rewards` | `RS.Configs.Stages.Stage1.*` | per-act XP, defeat consolation, drop table, and the **name** of a gold curve |
| `RewardScalingConfig` | `RS.Configs.Global` — **SHARED CANON** | the difficulty→gold curve, the wire→t conversion, the Insane item table |
| `TowerProgressionConfig` | `RS.Configs.Global` | per-unit XP from damage/kills |
| `WorthinessConfig` | `RS.Configs.Global` | worthiness per kill (A8) |

## Gold scales with difficulty (P5, blueprint `playgui.md` §8)

`goldMin = lerp(100, 300, t)`, `goldMax = lerp(300, 500, t)`, and the server rolls an integer
inside that band. Victory only.

**A DEFEAT keeps its flat `StageConfig.Rewards.Defeat.Currency`.** §8's curve describes what a
CLEAR pays; scaling the loss reward would make losing on max difficulty the best gold-per-minute in
the game.

`Victory.Currency` still exists in every act but is **FALLBACK ONLY** — used only if the named
curve cannot be resolved. Do not tune it expecting it to be what players receive.

## ⚠ THE TWO DIFFICULTY SCALES

This is the single most dangerous thing in this file.

| Scale | Range | Where | Meaning |
| --- | --- | --- | --- |
| **UI** | 1–100 | PlayGUI slider, Lobby only | 1 = normal, 100 = hardest |
| **WIRE** | 100–1000 | `DifficultyPercent` in the teleport `MatchLaunch` payload (v2) | 100 = normal (1× enemy HP), 1000 = 10× |

ADR-0011: the 1–100 remap is **DISPLAY-ONLY** and the wire format never changed. The Lobby converts
UI→wire in exactly one module (`StarterGui.PlayGUI.DifficultyScale`).

**The Game only ever receives the WIRE value**, so it does its own conversion in exactly one
function: `RewardScalingConfig.TFromWire`, `t = (wire - 100) / 900`, **clamped, never
extrapolating** (the legal wire range is 1–1000, wider than the 100–1000 the slider can produce, so
values below 100 must land on t = 0 rather than going negative).

Getting this backwards is silent and expensive: treating an incoming wire `100` as if it were UI
`100` reads **normal as hardest** and pays maximum gold for an easy match. There is no error, no
`[CONTRACT]` line — just wrong numbers forever. Do not add a second conversion anywhere.

`RewardCalculator` reads the difficulty from `matchState.DifficultyPercent` (sanitised by
`MatchDirector`). The `matchState` argument is **optional and fails SAFE**: absent, the match is
treated as normal (t = 0, bottom of the band). The opposite default would pay maximum gold to every
caller that forgot to pass it.

## Why the curve is SHARED and not in `StageConfig`

§8: *"the preview must not invent numbers … the curve belongs in a config both sides can read."*
The Lobby's reward preview must show what the server will actually pay.

**The curve reached the Lobby at B20** (`deployed.Lobby = 1d789978`, copied byte-identical, drift
**26/26 GREEN** in that Place). Both Places were proven to compute the SAME band from the SAME
function at wire 100 → `100-300`, 550 → `200-400`, 1000 → `300-500`, and 500 server rolls all landed
inside the previewed band.

**The preview UI itself is still NOT wired**, and that is a reported gate rather than an oversight:
`StoryModeController.renderRewards()` renders `x<qty>` per cell so it cannot express a min–max BAND,
and it only re-runs on act selection while P4 republishes `DifficultyWire` on every slider move — so
a one-call wiring would freeze at the act's opening difficulty and then contradict the slider, which
is exactly the lie §8 bans. That file is AD-UI canon, so B20 filed
`docs/proposals/2026-08-14-reward-preview-wiring.md` instead of editing it.

It could **not** live in `StageConfig.Rewards`, for three reasons:

1. The Lobby's `StageRegistry` is a hand-maintained **MIRROR carrying structure only** — no reward
   table, and nothing drift-checks it (`docs/systems/play-menu.md`). Gold numbers there would be
   two uncheckable copies of the same figures in two Places.
2. The curve is **identical for every act**. Triplicating it buys no tuning and creates three
   places to desync.
3. `WorthinessConfig` is the obvious counter-example and it does **not** apply: the Lobby reads
   worthiness as a **stored result** off the profile. A pre-match preview has nothing stored to
   read. This is a genuine cross-Place read, which is what shared canon is for.

Per-act tuning survives without duplicating numbers: `StageConfig.Rewards.GoldCurve` **names** a
curve, so a future act points at a different one instead of copying endpoints.

## Insane mode — REACHABLE since teleport v3 (B20, 2026-08-14)

§8: Insane runs the **same** gold curve and adds item rewards on top. Mode is a separate axis from
the slider and never enters the difficulty conversion.

**The `MatchLaunch` payload carries `DifficultyMode` as of contract v3** (`docs/contracts/teleport.md`).
The chain is: `DifficultyController` (P4) publishes `DifficultyMode` on `SelectedAct` →
`LobbyController` (P6) passes it through `RequestLaunch` verbatim → `PartyService` validates it and
puts it on the wire → `MatchEntryService` normalises it onto `rawConfig` → `MatchDirector` puts it on
`matchState` → `RewardCalculator` reads `matchState.DifficultyMode`. It was bumped as a HARD version
change, not an additive field: a Game that ignored an unknown mode while the Lobby believed it sent
Insane would pay the wrong rewards silently, so v2 and v3 do not interoperate.

**It still fails SAFE at every hop.** `matchState` is optional and an absent or unrecognised mode
resolves to Normal — the branch that pays NO bonus items. The opposite default would pay bonus items
to every caller that forgot the argument.

**Insane is now the first real writer for `Data.Items` in normal play** (see the standing PENDING) —
before this, only the Victory drop-roll could write items, and nothing triggered it. Verified live at
B20: an Insane Victory committed `BannerTicket` 0→1 and `TraitRerollToken` 0→1; the same Victory on
Normal committed neither, and both landed inside the same gold band.

**⚠ ONE STALE COMMENT, deliberately NOT edited.** `RewardScalingConfig`'s own header still says the
payload "(v2) carries NO mode field" and that Insane cannot fire live. That module is SHARED CANON at
hash `1d789978` and B20's whole job was to copy it byte-identical, so correcting the comment would
have changed the hash and required a re-deploy to both Places inside a session that was already
doing a contract bump. It is **AD-Game's** module; the fix is a comment-only re-hash + both-Place
redeploy in a future AD-Game session. The CODE is correct — only the comment is out of date.

**⚠ RESOLVED AT B43 — the note above is now history, kept for the lesson.** `RewardScalingConfig`'s
header was corrected (`1d789978` → **`5a4cf793`**, comment-only, 6870 → 7437 bytes, mirrored
byte-identical to both Places with the manifest updated). It had been deferred three times because
correcting a comment in shared canon costs a re-hash and a both-Place redeploy — and in the meantime
two sessions read it and believed it. **The cost of leaving a wrong comment in canon is that it keeps
being believed; the cost of fixing it is one deliberate deploy.**

**B41 fixed the OTHER copy of that same stale claim.** `RewardCalculator` carried its own version of
it ("the payload (v2) has NO mode field, so this branch does not fire in production"). That file is
**not** shared canon, so correcting it cost no hash and no redeploy — and it mattered, because the
sentence directly contradicted the `InsaneVictories` counter added in the same file. The shared
`RewardScalingConfig` header remains the one still to fix.

## Order of operations in `GrantForPlayer`

1. XP + gold (gold scaled; defeat flat) → `PerfectClearBonus` if the clear was flawless
2. Drop-table roll (Victory only) → plus Insane items if the mode says so
3. Commit account rewards: `AddPlayerXP`, `AddCurrency` (Gold), then each drop **routed by its
   catalogue `Kind`** — Currency → `AddScalarCurrency`, Item → `AddItem` (B45)
4. Per-unit tower XP **by uuid**, from that unit's own damage/kills (B0)
5. `CommitUnitKills` per unit — `Counters.PerUnit[uuid].Kills` + worthiness, one write (A8)
6. Global counters: `Clears` + `ClearsByStage` **on Victory only**, `Waves` on any outcome,
   `InsaneVictories` **on a Victory that was also Insane** (B41)
7. Battlepass XP: computed and **accumulated**, never granted here (B43 — see below)

Steps 4–6 are covered by `docs/blueprints/phase-a-foundations.md` §6 and the A8/A9/B0 changelog
entries; do not change their attribution rules without reading those.

## Player levelling — `AddPlayerXP` is the ONE application path (B41)

`AddPlayerXP` applies the account XP curve through `PlayerLevelConfig.ApplyXP` and writes **both**
`Data.PlayerXP` and `Data.PlayerLevel`. Do not add a second XP path: it is to account XP what
`GrantService` is to Lobby grants.

**⚠ THE CONTRACT.** `PlayerLevel` is authoritative — `LoadoutConfig` keys hotbar slot unlocks off it.
`PlayerXP` is **progress within the current level**, never a lifetime total. Writing `PlayerXP`
without running it through `ApplyXP` puts the two fields into disagreement and the ExpBar starts
lying. `AccountTotals.PlayerXP` on the match-end payload therefore travels with `PlayerLevel`; the
payload also carries `LevelUp` (nil unless a level was actually gained).

**What was broken, B33 → B41.** `AddPlayerXP` was three lines — `data.PlayerXP += xp` — and never
touched `PlayerLevel`, because the rollover lived in `PlayerLevelConfig`, which was **Lobby-only**.
So every account sat at level 1 forever however much XP it banked, and the level-gated slots (5 at
Lv20, 6 at Lv50) were unreachable. B41 promoted `PlayerLevelConfig` to shared canon (manifest
**35 → 36**) specifically so the Game could call it. `STATE.md` had recorded this as "nothing grants
`PlayerXP`" since B33, which was false and pointed seven sessions at the wrong repair.

**No migration was needed, and none should be added.** `ApplyXP` re-reads the stored pair every
call, so a profile that banked a backlog while the rollover was unreachable drains it on its next
grant and lands where it always should have been; a consistent profile is untouched. Verified: a
synthetic `L1 / 5000xp` profile resolved to `L16 / 240xp` conserving XP exactly, while `L1 / 30xp`
(the dev profile's shape) did not move. This is why the fix cost **no v5 field**.

**⚠ BALANCE, OPEN — the user's call, not this file's.** `100 × 1.15^(level-1)` puts level 50 at
**627,540 lifetime XP** (~12,500 act clears) while `LoadoutConfig` gates slot 6 there. Surfaced, not
retuned.

## Battlepass XP is EARNED here and APPLIED in the Lobby (B43)

The one match reward this Place cannot commit. `Data.Battlepass` is owned by the **Lobby's**
`BattlepassService`, its single writer, so `RewardCalculator` computes a number and hands it to the
return teleport instead of granting anything:

`RewardCalculator` → `MatchReturn.BattlepassXP` → Lobby `MatchReturnService` →
`ServerStorage.BattlepassAddXP` → `BattlepassService`.

**The Game must never write `Data.Battlepass`.** Granting it here would be a second writer for one
field — the same mistake the one-writer rule exists to prevent, and the harness asserts it explicitly.

The rule is `Configs.Global.BattlepassXpConfig` (Game-local: the Game is the only Place that knows
how a match went). **Placeholder numbers, the user's shape (B43):** `Base 50 + 5/wave`, a Defeat
paying `0.4` of what it earned, scaled `1.0 → 2.0` by wire difficulty **through
`RewardScalingConfig.TFromWire`** — the one wire→t conversion, never a second one. An `Abandoned`
outcome pays 0, consistent with B41's rule that an aborted match grants nothing; any unrecognised
outcome fails SAFE to 0, the same stance as an unknown mode failing safe to Normal.

**Accumulated, not overwritten**, because chained acts return to the Lobby once — and cleared only
after `TeleportAsync` succeeds, so a failed teleport does not destroy earned XP. Both delivery
guards, and the known limit (XP never carried back is lost), are in `docs/contracts/teleport.md`.

## A drop is routed by its catalogue Kind, never assumed to be an item (B45)

Every drop used to go to `AddItem`, which writes `Data.Items[id]`. That was correct while every
droppable id really was an Item — but a **Currency lives in `Data.Currencies[id]`**, and crediting
one into `Data.Items` puts it in a field nothing reads and nothing spends. The faucet would look
wired and the currency would never arrive.

`ItemCatalog` is the one place that knows which an id is, so `GrantForPlayer` asks it:

| catalogue `Kind` | written to |
|---|---|
| `Currency` | `Data.Currencies[id]` via `PlayerInventoryService.AddScalarCurrency` |
| anything else | `Data.Items[id]` via `AddItem` |
| **uncatalogued** | **nothing — refused loudly** |

Refusing an uncatalogued id is the same stance as `GrantService.Grant`'s invariant 4 in the Lobby: a
typo in a drop table must never silently invent a profile field.

`AddScalarCurrency` guards its own name list, mirrored from `GrantService.SCALAR_CURRENCIES`. **The
two Places cannot share that list** — `GrantService` is Lobby-local and `PlayerInventoryService` is
the Game's account writer — so if a scalar currency is ever added to the schema, **both lists must
learn it**. Kept short and explicit rather than derived, so a divergence shows up in a diff.

### `StatRerolls` — C2's faucet (B45)

C2's stat reroll (B44) spends `Currencies.StatRerolls`, but nothing could mint it: the id was not in
`ItemCatalog`, so `Grant` refused it. B45 catalogued it as `Kind="Currency"` (`fc4b8023` →
`9be86a5f`) and added it to `RewardScalingConfig.InsaneItems` (`5a4cf793` → `e0a3bc2d`) — the same
faucet `TraitRerollToken` has always used, which is the only reason C1 was reachable and C2 was not.
Both are shared canon, mirrored byte-identical to both Places. **Its icon is a placeholder
(`rbxassetid://0`) for the user to author.**

## Worthiness — the meter has existed since A8, and is NOT a gap

`CommitUnitKills` advances `UnitInstance.Worthiness` through `WorthinessConfig.Apply` once per match,
in the same pass that commits `Counters.PerUnit[uuid].Kills`. Verified at A8 and re-verified
independently at A9 (Archer 198 kills → 3.96, Necromancer 86 → 1.72). The cap is enforced **inside
`Apply`**, so no future caller can bypass it.

Several later docs described this as unbuilt — `stat-reroll.md` said so in the paragraph directly
below one that said the opposite. It is built. Whether a player *reaches* 100 is a **tuning**
question: `PointsPerKill` is `0.02` (the user's choice at A8, reaffirmed at B45), so ~5,000 kills
caps a unit and a favourite maxes over roughly 25–50 matches — the intended long-term goal. Retune in
`WorthinessConfig`, never at a call site.

## Invariant 1 does NOT hold here yet

Every grant in the **Lobby** flows through `GrantService`. The **Game** still grants through
`PlayerInventoryService` / `RewardCalculator`. Converging them is a separate cross-Place task
(standing PENDING) — do not start it inside a rewards change, but do not make it worse either.

## Verifying a change

`execute_luau` caches requires and will happily report a stale pre-edit module. Verify from a REAL
Script + `get_console_output`. `RewardCalculator` prints one `[DATA] Rewards:` line per grant with
outcome, mode, wire, t, band and the rolled gold — that line is usually all the evidence you need.
Assert on the **gold delta**, not the absolute, so a dirty dev profile cannot make a red test green.

## The server-initiated reveal path lives in its own doc

`docs/systems/reward-push.md` (B37 + B39). Moved out of this file at B39 on its 300-line cap: it is
**Lobby** machinery and this file is AD-Game's **match-end payout** contract. It covers `RewardPush`,
why the push is opt-in, the `PendingReveals` queue, and the correction to B37's "known gap".
