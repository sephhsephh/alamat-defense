# Proposal: P7 — the global matchmaking queue (blueprint `playgui.md` §11)

<!-- author: AD-Meta (B22, 2026-08-16) | place: Lobby (design only) | status: OPEN -->
<!-- Outcome of the §11 session: DESIGN LANDED, BUILD DEFERRED. Nothing was wired. -->

## Verdict, up front

**P7 cannot be built in a Lobby-only session, and the reason is a contract one, not a scheduling
one.** `docs/contracts/teleport.md` states the invariant that matchmaking breaks, in its own words:

> Delivery is **reserved (private) servers per party** … so **a match server contains exactly one
> party**.

and it lists, under *Still deferred*:

> Public / matchmaking servers (join strangers) — delivery is reserved-per-party only.

A global queue matches strangers **across lobby servers**. That collides with the shipped delivery
mechanism in two places (§3 below), and the fix is a **teleport contract v3 → v4** change: BOTH
Places, ONE session, synchronised republish. This session is LOBBY-ONLY, and **v3 itself has not
been republished yet** — stacking a v4 on an un-republished v3 would widen an already-live hazard.

Per `blueprints/playgui.md` §9 and CLAUDE.md ("Blocked or convinced it's wrong? STOP →
`docs/proposals/` + ask the user"), this document is the deliverable. The user chose this outcome
explicitly at bootstrap. `FindMatchButton` **stays disabled with its "COMING SOON"
`InactiveOverlay`** and `PlayGUIController`'s `disable()` call was deliberately left untouched — a
half-enabled button is worse than an honest one, and a future session must not read the overlay as
a bug.

## 1. What §11 fixed, and what it left to the builder

§11 is law and already decided the shape. It is repeated here only so the build session does not
have to hold two documents open:

* `MemoryStoreService` sorted-map/queue keyed by `stageId | actId | mode | difficultyBucket`
* party-aware: **a party joins as ONE unit and is NEVER split**
* host election on match
* timeout → **offer** a solo start rather than hanging
* abandonment cleanup
* then the **existing** reserved-server handoff — matchmaking decides *who*, `PartyService` still
  decides *how*. **Do not build a second launch path.**

Everything below is the mechanical detail §11 does not specify. Where this document makes a choice,
it says so and gives the reason; nothing here contradicts §11.

## 2. The queue key, built from the PUBLISHED attributes

§11's key is `stageId | actId | mode | difficultyBucket`. In THIS Place those four things map onto
attributes the UI **already publishes** on `StoryModeFrame.SelectedAct` (P4). The build session
reads them; it does not re-derive them and does not add a second selection channel.

| §11 term           | Actual source                        | Note |
|--------------------|--------------------------------------|------|
| `actId`            | `SelectedActId` (e.g. `Stage1_Act3`) | This is what `RequestLaunch` already calls `StageId`. |
| `stageId`          | `SelectedStageNumber`                | §11's "stage" is the GROUP (Stage 1), not the launch id. Do not invent a new split. |
| `mode`             | `DifficultyMode` (`Normal`/`Insane`) | Same axis the v3 payload carries. |
| `difficultyBucket` | bucket of `DifficultyWire`           | See below. |

**`DifficultyWire` (100–1000) is used VERBATIM, never re-derived from `DifficultyUI`** — ADR-0011,
and `t = (wire-100)/900`, not `/99`. The client sends the wire value untouched, exactly as P6's
`LobbyController` already does for `RequestLaunch`.

**Bucketing.** Matching on an exact wire value would essentially never match — 901 distinct values.
Proposed: `bucket = math.floor((wire - 100) / 100)` → `0..9`, ten bands of 100 wire points
(≈11 UI points each). Two notes the build session must respect:

* **Bucketing is arithmetic on a difficulty number, so it needs ONE greppable home.** It does NOT
  belong in `PlayGUI.DifficultyScale`: that module is *the* UI↔wire **conversion** (ADR-0011), and
  bucketing converts nothing — it partitions. Put it in `MatchmakingService.BucketOf(wire)`,
  **server-side, one call site**, and hold it to the same discipline: grep before anyone adds a
  second.
* **The launched match uses the ELECTED HOST's exact wire value. Do NOT average the members'
  values.** An average invents a difficulty nobody chose and silently moves everyone's payout
  (`RewardScalingConfig.GoldBand` reads the wire directly). The host's number is a real number a
  real player picked. The queue records each member's exact wire so the UI can honestly say
  "you queued at 512, this match runs at 545".

## 3. Why this is a contract v3 → v4 change

Today `PartyService` does all of this in one server, in one function: assemble the local party →
`ReserveServer` → build `Players` → `TeleportAsync`. A matched group spans lobby servers, which
breaks that in exactly two places.

**(a) The `Players` map would be incomplete.** `Players` is assembled from `party.members` that are
`Players:GetPlayerByUserId()`-resolvable **on this server**. If a match spans servers A and B, A
teleports with `Players = {A's players}` and B with `Players = {B's players}` — the Game receives a
payload that does not describe the match roster. The contract says the Game "already expects exactly
these semantics", so this is a semantic change to a shipped v3 field, not an addition.

**(b) The `ReservedServerAccessCode` has to travel between servers.** One elected server reserves;
the others must teleport into the SAME code. Nothing carries it today — the contract is explicit
that there is "no MemoryStore handoff in v1". This is a *delivery-mechanism* change rather than a
payload-field change, but it is part of the same contract document and lands in the same session.

**Why a HARD bump rather than an additive field** — the identical argument that made v3 hard: a Game
that ignores an unknown flag would apply its one-party assumptions to a server full of strangers
(game-speed authority handed to a stranger, end-of-match grouping, any trust the roster implies).
Nothing errors, nothing logs, the behaviour is just wrong. The integer version is what makes that
window impossible.

### The v4 delta (small, and deliberately so)

The roster SHAPE needs no change — `Players[uid].PartyId` is already per-player and optional, so it
already expresses "several parties in one match". The delta is:

1. **NEW `IsMatchmade: boolean`** — `false` for every launch that exists today; `true` when the
   roster was assembled by the queue. This is the flag every one-party assumption branches on.
2. **`HostUserId` semantics widen** from "the party host" to "the elected match host". Same field,
   same type; the doc sentence changes.
3. **The invariant "a match server contains exactly one party" is REPEALED**, and *Still deferred*
   loses its "public / matchmaking servers" line.
4. **Delivery gains a cross-server step**: the reserving server publishes `code` + the single
   authoritative payload to the other participating servers via MemoryStore; each server teleports
   its own players with **identical payload bytes**.

`PayloadVersion` → `4`; `LobbyConfig.MatchLaunchVersion` and `GameConfig.TeleportPayloadVersion`
move together, as always. `DifficultyPercent` keeps its meaning, range and name — ADR-0011 is
untouched by all of this.

### Loadout staleness — an accepted, documented cost

The reserving server builds the ONE authoritative `Players` map from the queue entries' Loadout
snapshots, taken at ENQUEUE. A player who changes loadout while queued teleports with the snapshot.
**Accept it:** the window is bounded by the queue timeout (≤45s), and the Game re-validates
ownership on arrival anyway (`LoadoutValidator`). The alternative — each server rebuilding its own
players' loadouts at teleport time — produces servers sending *different* `Players` maps into one
reserved server, which is strictly worse than a ≤45s-stale one.

## 4. Party-as-one-unit, concretely

**The queue entry is a PARTY, never a player.** One MemoryStore item per party, carrying the full
member roster (`userId`, `Loadout`, exact `DifficultyWire`) plus the party id.

Matching is **atomic bin-packing to `LobbyConfig.MaxPartySize` (= 4)**: accumulate whole entries
until the sizes sum to the target. If a 3-party and a 2-party are the only candidates for four
slots, you take the 3 **or** the 2 — you never take one member out of the 3-party. That is the
whole of "never split", and it is the one clause a build session is most likely to break by
reaching for a player-level queue because it packs better.

**Host election must be deterministic and derivable from the entry data alone**, so every
participating server reaches the same answer with no extra round trip. Proposed: **the lowest
`userId` in the matched group**; that player's lobby server is the one that calls `ReserveServer`
and publishes the handoff. Total-ordered, stable, needs no clock, and no server has to be asked.

## 5. Timeout → offer solo, not hang

After `QueueTimeoutSeconds` (propose **45**) with no match: remove the entry, and **offer** the
player a solo start — §11's word is "offer". A prompt with *Start Solo* / *Keep Waiting* / *Cancel*.
*Start Solo* runs the existing launch on the player's own party, at their own exact `DifficultyWire`
— i.e. precisely what `StartButton` does today, with `IsMatchmade = false`. There is no new launch
path in the timeout branch either.

## 6. Abandonment cleanup

Three independent mechanisms, because any one of them can be the thing that fails:

* **Per-item expiration** on every MemoryStore entry, set slightly above the queue timeout, so a
  crashed lobby server's entry evaporates on its own rather than matching ghosts.
* **Explicit removal** on cancel, on `PlayerRemoving`, and on party membership change (a party that
  gains or loses a member is no longer the unit that was enqueued — remove and re-enqueue).
* **Claim-then-commit** on the match itself, so two servers cannot both claim the same entries.
  A claimed-but-never-launched match must release its entries back, or those players are stuck.

**Short-roster arrival is now routine, not rare.** A matched player whose server dies between claim
and teleport never arrives, and the reserved server starts with fewer players than the payload
lists. Today, with one party, that is an edge case; matchmade it will happen daily. **How the Game
handles it is a Game-side question** (§8).

## 7. The `PartyService` seam — NOT a second launch path

`SSS.Server.Lobby.PartyService` is a **`Script`, not a `ModuleScript`**, so `MatchmakingService`
cannot `require` it. The launch body is currently inline in the `RequestLaunch.OnServerEvent`
handler.

Proposed: extract the launch body (loadout assembly → payload build → reserve → teleport) into a
`ModuleScript` `SSS.Server.Lobby.LaunchService`, required by **both** `PartyService` — which keeps
owning the `RequestLaunch` remote, the host check and the `PartyState` error replies — and
`MatchmakingService`.

**This is the same path with one more caller, not a second path.** `RequestLaunch` remains the only
*client* entry to launching; `MatchmakingService` is a *server* caller. Stating it here because the
next session to read `LaunchService` will otherwise reasonably suspect §12 has been violated.

## 8. Questions only the GAME place can answer (blocking the build)

A Lobby-only session cannot inspect these, and each one can change the design:

1. Does `MatchDirector.StartMatch` / `MatchEntryService` assume one party anywhere — game-speed
   authority keyed on `HostUserId`, end-of-match grouping, anything keyed on a uniform `PartyId`?
2. Does the Game **wait for the full `Players` roster** before starting, and what does it do when a
   listed player never arrives (§6)? A hang here turns a dead lobby server into a dead match.
3. Does anything Game-side need to know the match was matchmade beyond the reward path — e.g. should
   an abandoned matchmade match be scored differently from an abandoned party match?

## 9. What this session actually verified

Small, but it removes one of the three STOP conditions and confirms another permanently:

* **`MemoryStoreService` works from Studio in the Lobby.** Probed read-only in the Edit datamodel:
  `GetSortedMap("AD_Probe_B22"):GetRangeAsync(Ascending, 1)` returned ok with 0 items. **No Studio
  setting needs flipping for MemoryStore** — that STOP condition does not fire.
* **`ReserveServer` returns HTTP 403 in Studio** (recorded at B20 and unchanged). The final step of
  the handoff can therefore **never** be proven in Studio, in any mode. That is a permanent
  verification gap, not a session limitation, and the build session must plan to assert on the
  payload it BUILDS plus a live two-client test — never on a completed teleport.
* **MemoryStore quota is a real design input.** Request quota scales with player count; a queue that
  every lobby server polls costs quota per server per poll. Budget it: poll interval ≥2s, jittered,
  and back off rather than retry tight.

## 10. Recommended shape of the build session

**AD-Integration, both Places open, no sibling chat active on the contract.** In order:

1. Answer §8's three questions against the Game's live code — they may change §3's delta.
2. Contract v3 → v4 in `docs/contracts/teleport.md`: `IsMatchmade`, `HostUserId` semantics, repeal
   the one-party invariant, document the cross-server delivery step, bump both config integers.
3. Lobby: extract `LaunchService` (§7), build `MatchmakingService`, wire `FindMatchButton`, remove
   its `InactiveOverlay` and the `disable()` call in `PlayGUIController`.
4. Game: branch every one-party assumption on `IsMatchmade`; handle short rosters.
5. Verify from REAL Scripts + `get_console_output` in both Places, and say plainly which clauses a
   two-instance test could not reach.
6. **The user republishes BOTH Places together** — v4, like v3, is a hard cutover.
