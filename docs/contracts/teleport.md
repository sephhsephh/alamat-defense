# Contract: Teleport Payloads (Lobby ⇄ Game)
<!-- owner: lobby | scope: global | version: 4 | last-verified: 2026-08-16 (B23) -->

Version 4 (2026-08-16, B23 Integration) — implemented and deployed on BOTH sides in ONE session.
Delivery is **reserved (private) servers**: a launch reserves a fresh Game server and teleports only
the matched players into it.

**⚠ THE "ONE MATCH SERVER = ONE PARTY" INVARIANT IS REPEALED AT v4.** It held for v1–v3 and a great
deal of reasoning was built on it. Since P7 (the global matchmaking queue) a reserved server can
hold **several parties, or strangers with no party at all**, assembled ACROSS lobby servers. Code
that still needs the old guarantee must branch on `IsMatchmade`, never on `PartyId` (which is
per-player, optional, and read by nothing Game-side).

**v4 changes exactly one field and one sentence:** `MatchLaunch` carries `IsMatchmade`, and
`HostUserId` widens from "the party host" to "the **elected match host**". `PayloadVersion = 4`.
Everything else (delivery, security stance, `MatchReturn` shape, failure handling, every v3 field)
is unchanged.

**v3 changed exactly one thing:** `MatchLaunch` carries `DifficultyMode` (`"Normal"` / `"Insane"`).

**Why v4 is a HARD version bump and not a quiet additive field.** A Game that ignored an unknown
flag would apply its one-party assumptions to a server full of strangers — speed authority and the
3× entitlement handed to an elected stranger, and any trust the roster implies. Nothing errors,
nothing logs, the behaviour is simply wrong. The integer version is what makes that window
impossible.

**Why v3 was a HARD version bump and not a quiet additive field.** Insane pays extra ITEM rewards
on top of the same gold curve (`docs/systems/rewards.md`). The two Places publish SEPARATELY, so an
additive field creates a window where the Lobby sends `Insane` and an older Game silently ignores
it — the player is charged the harder match and paid the easier rewards, with nothing erroring and
no log line to find it by. The integer version is what makes that window impossible: a v2 sender is
REJECTED outright.

The version is a single integer covering BOTH directions and is read from config, never
hardcoded: Lobby `RS.Configs.LobbyConfig.MatchLaunchVersion`, Game
`RS.Configs.Global.GameConfig.TeleportPayloadVersion`. **They must always be equal** — both
Places deploy in the same Integration session, so no dual-version window exists and a mismatch
is a hard reject (`[CONTRACT]` warn), never a fallback.

The Lobby's `MatchReturnService` reads its expected version from the SAME `MatchLaunchVersion`
constant, so one integer really does cover both directions — bumping the launch version bumps the
return version with it, automatically. Verified at B20: the Lobby logged `MatchReturn v3 receiver`
with no separate edit.

## Security stance (already enforced Game-side)

TeleportData is **client-forgeable**. The Game treats it as a *request*, never a truth:
tower levels/traits/XP always come from the player's profile via `PlayerInventoryService`
(`LoadoutValidator` re-validates every loadout). The payload only says *what the player
chose*, never *what they have*. `HostUserId` and party membership are likewise re-checked
Game-side where they matter (e.g. game-speed authority).

## Delivery mechanism (v1)

Lobby, on the host's launch request:

1. Assemble the party from `PartyService` (host + accepted members present in the lobby).
2. `code, privateServerId = TeleportService:ReserveServer(LobbyConfig.GamePlaceId)`.
3. Build the `MatchLaunch` payload (below); wrap it as `TeleportData = { MatchLaunch = payload }`
   inside `TeleportOptions`.
4. `TeleportService:TeleportToPrivateServerAsync(GamePlaceId, code, players, nil, nil, options)`.

Reserved servers are private: only players carried in this call (with the access code) can join,
which is what guarantees "only the party is in that match". `IsPrivate` in the payload is always
`true` for v1 (public/solo servers were considered and deferred).

`GamePlaceId` lives in `ReplicatedStorage.Configs.LobbyConfig` (set 2026-07-18 =
`125430066355564`); its Game-side counterpart is `GameConfig.LobbyPlaceId` (`83342803778137`).
If either is `0`, that side logs `[Teleport]` and skips the actual teleport so nothing errors —
everything up to the reserve/teleport call is still exercised.

## Lobby → Game: `MatchLaunch` (v2)

```luau
{
	PayloadVersion: number,     -- = 2; Game logs [CONTRACT] + REJECTS on mismatch
	StageId: string,            -- e.g. "Stage1_Act1" (validated vs the Game's StageRegistry)
	HostUserId: number,         -- v4: the ELECTED MATCH HOST (for a party launch that is still the
	                            -- party host). Game-speed authority + the 3x gamepass gate, both
	                            -- re-checked Game-side. Election is the LOWEST userId in the matched
	                            -- group -- deterministic and derivable from the queue entries alone,
	                            -- so every participating lobby server elects the same player with no
	                            -- extra round trip. The Game independently falls back to lowest-userId
	                            -- when HostUserId is not in ValidatedPlayers, so both sides agree by
	                            -- construction rather than by coincidence.
	DifficultyPercent: number,  -- 1..1000 (sanitized both sides: StageRegistry.SanitizeDifficulty / DifficultyConfig)
	IsMatchmade: boolean,       -- v4: TRUE only when the global QUEUE assembled this roster.
	                            -- FALSE for every launch that existed before v4 (party + solo).
	                            -- This is the flag every one-party assumption branches on.
	                            -- Absent or non-boolean is read as FALSE on arrival -- the
	                            -- conservative default, keeping existing one-party behaviour.
	DifficultyMode: string,     -- v3: "Normal" | "Insane". A SEPARATE AXIS from DifficultyPercent --
	                            -- it does NOT scale enemy health and never enters the ADR-0011
	                            -- UI<->wire conversion. It selects the Game's Insane reward branch.
	                            -- Anything unrecognised FAILS SAFE to "Normal" on BOTH sides.
	IsPrivate: boolean,         -- always true (reserved server)
	Players: { [string]: {      -- key = tostring(userId) (JSON keys must be strings)
		Loadout: { string },    -- v2: unit UUIDS (schema-v2 Data.Units keys), max LobbyConfig.MaxLoadoutSize;
		                        -- re-resolved + ownership-checked Game-side by LoadoutValidator
		PartyId: string?,       -- shared party id for this launch
	} },
	MatchModifiers: { string }?,
	CustomSettings: { [string]: any }?,
}
```

**Mode source (Lobby):** `DifficultyController` (P4) publishes `DifficultyMode` as an attribute on
`StoryModeFrame.SelectedAct`; `LobbyController` (P6) reads that attribute and passes it through
`Remotes.RequestLaunch` **verbatim, doing no arithmetic on it**; `PartyService` validates it and is
what actually puts it on the wire. The Game normalises it AGAIN on arrival (`MatchEntryService`),
mirroring how `DifficultyPercent` is sanitized at both ends — a client request is never truth.
"Normal" is the safe default on both sides because it is the branch that pays NO bonus items, so an
unknown value can never mint rewards.

**Loadout source (Lobby, `PartyService.buildLoadout`):** the player's saved `Data.Loadout`,
filtered to uuids they still own and capped; if that is empty (no picker UI yet, or a
fresh/migrated profile) it falls back to auto-loadout = owned units, highest `MetaLevel` first.

Maps to `MatchDirector.StartMatch` (which already expects exactly these semantics — the dev
harness `MatchLifecycleSmokeTest` fakes this payload today). Party assembly travels **in the
payload** (assembled at launch from `PartyService`); no MemoryStore handoff in v1.

## Game → Lobby: `MatchReturn`

Shape unchanged from v1 except for B43's additive field — the version integer moves with
`MatchLaunch` (one version covers both directions).

```luau
{
	PayloadVersion: number,     -- tracks MatchLaunch; = 4 today
	LastStageId: string,
	Outcome: "Victory" | "Defeat" | "Abandoned",
	SuggestNextActId: string?,  -- so the Lobby can pre-select "continue"
	BattlepassXP: number?,      -- B43: ADDITIVE. Battlepass XP earned, for the LOBBY to apply.
}
```

Rewards are NOT in this payload — they were already committed to the profile by
`RewardCalculator` before teleport (profile session-lock handles the save handoff).

### ⚠ `BattlepassXP` is the ONE exception, and it is not a reward (B43)

It is a **number to apply**, not something already granted. Every other match reward can be
committed Game-side because the Game owns the field. `Data.Battlepass` is owned by the **Lobby's**
`BattlepassService`, which is its **one writer** — so the Game computes the XP
(`Configs.Global.BattlepassXpConfig`, a Game-local rule) and the Lobby applies it through the
existing `ServerStorage.BattlepassAddXP` channel. Granting it Game-side would mean a second writer
for one field, which is exactly what the one-writer rule prevents.

**This is why `MatchReturnService` is no longer strictly display-only.** It applies this one thing
and nothing else; it does not write `Data.Battlepass` itself.

### Why this did NOT need a hard version bump, when v3 and v4 did

v3 and v4 were hard bumps because a reader that ignored the new field would behave **wrongly** —
silently paying Normal rewards for an Insane match, or treating a matchmade roster as one party.
`BattlepassXP` has no such failure mode. It is additive and forward-tolerant in both directions:

| situation | result |
|---|---|
| new Game → old Lobby | field ignored, no XP applied |
| old Game → new Lobby | field absent, sanitizes to 0, no XP applied |

Both degrade to **"no XP"**, never to wrong data — and both Places republish together anyway, so the
window does not exist in practice. A field whose worst case is "the feature doesn't happen" is the
kind that rides an existing version; a field whose worst case is "the wrong thing happens" is not.

### Delivery guarantees, both ends

The number is **accumulated per player across chained acts** (Act 1 → Next Act → Act 2 returns once)
and travels on the single return.

- **Game:** `RewardCalculator.PeekPendingBattlepassXP` builds the payload; the accumulator is cleared
  only **after `TeleportAsync` succeeds**. A failed teleport leaves the player in the Game to retry
  (§ Retry/failure) and the retry must carry the same XP, not nothing.
- **Lobby:** applied **once per join**, guarded, because `onAdded` runs from both the startup loop
  and `PlayerAdded` and a player joining between them would otherwise be credited twice. The channel
  itself is *not* idempotent — verified — so the guard is load-bearing.
- **Lobby:** applied only **after the profile loads** (`WaitForData`). `PlayerAdded` fires first, and
  the first wiring of this was refused with `profile_not_loaded` on every return — found by running
  it, not by reading it.
- Sanitized like any wire value: absent, non-numeric, negative or NaN → 0, and clamped to a
  blast-radius cap far above what the curve can pay.

**KNOWN LIMIT, ACCEPTED:** XP that is never carried back is lost — a player who closes the game
instead of returning to the Lobby drops what that session accumulated. Persisting it properly needs
a stored field (a **v5** schema bump) or a second writer; neither is worth it for a placeholder
economy. Stated here so it is a known limit rather than a surprise.

## Cross-server delivery (v4, matchmade launches only)

A queued match spans lobby servers, so one server must reserve and the others must teleport into the
SAME reserved server. v1–v3 had "no MemoryStore handoff"; v4 adds exactly one:

1. Every queued party is one MemoryStore sorted-map item under the key
   `actId | stageNumber | mode | difficultyBucket`. **The entry is a PARTY, never a player.**
2. The server holding the **elected host's** entry (lowest userId) calls `ReserveServer` and builds
   the ONE authoritative payload.
3. It publishes `{ Code, Payload }` to a second sorted map. Every participating server teleports its
   OWN players with **identical payload bytes** — rebuilding per server is how rosters diverge.
4. Entries carry a per-item expiration above the queue timeout, so a crashed lobby server's entry
   evaporates rather than matching ghosts.

**The match runs at the elected host's EXACT `DifficultyPercent`.** Members queue in the same
difficulty *bucket*, not at the same value; averaging their values would invent a difficulty nobody
chose and silently move everyone's `RewardScalingConfig.GoldBand` payout. Bucketing is arithmetic on
a difficulty number and lives in exactly one place, `MatchmakingRules.BucketOf` — it is **not** the
ADR-0011 UI↔wire conversion (`PlayGUI.DifficultyScale`), which converts and does not partition.

**Loadout snapshots are taken at ENQUEUE and may be ≤ the queue timeout stale.** Accepted: the Game
re-validates ownership on arrival (`LoadoutValidator`), and the alternative — each server rebuilding
its own players' loadouts at teleport time — makes different servers send *different* `Players` maps
into one reserved server, which is strictly worse.

**SHORT ROSTERS ARE ROUTINE AT v4, NOT AN EDGE CASE.** A player whose lobby server dies between
claim and teleport never arrives, and the reserved server starts with fewer players than the payload
lists. The Game does **not** hang: `MatchEntryService` waits out its assemble timeout and starts with
whoever is present. Since B23 it also scales the in-match economy on **players who actually
arrived**, not on the payload roster — counting the roster taxed a lone survivor of a 4-player launch
at the 4-player multiplier (0.8×) for the whole match.

## Retry / failure behavior (v1)

`ReserveServer` and `TeleportToPrivateServerAsync` are wrapped in `pcall`; the Lobby also
listens to `TeleportService.TeleportInitFailed`. On any failure the party is kept in the lobby,
told to retry, and no lobby/party state is consumed. Repeated failures back off and surface a
`[Teleport]` warning.

## Still deferred (not tied to a version number)

- Public / matchmaking servers (join strangers) — delivery is reserved-per-party only.
- Party persistence across a rejoin, cross-server party invites (MemoryStore) — parties are
  single-lobby-server, in-memory only.
- Rejoining an in-progress reserved match.

## Version history

- **v4** (2026-08-16, B23 Integration): `MatchLaunch` gains `IsMatchmade`; `HostUserId` widens to the
  ELECTED match host; the "one match server = one party" invariant is **REPEALED**; cross-server
  MemoryStore delivery is documented above. `PayloadVersion = 4`. **Migration: none — a hard
  cutover**, the same stance as v2 and v3. Both Places deployed in the SAME session, so no v3 sender
  can exist; the Game rejects v3 with `[CONTRACT] PayloadVersion mismatch: got 3, expected 4`.
  **Old → new for a consumer:** a v3 reader assumed every roster was one party. A v4 reader gets
  `rawConfig.IsMatchmade` → `matchState.IsMatchmade` and branches on it. Nothing else moved:
  `DifficultyPercent` and `DifficultyMode` keep their meaning, range and names (ADR-0011 untouched).
  **A survey of this Place found exactly ONE one-party assumption with teeth** — game speed. Speed is
  match-wide, and both the authority to change it and the 3× gamepass entitlement come from the host
  alone; matchmade, that host is an elected stranger. **B23 deliberately did not change it** (a
  design call for the user, not something to alter inside a contract bump); it is logged with
  `[CONTRACT] MATCHMADE match: speed authority ...` so it is visible and greppable. `PartyId` is read
  by nothing Game-side, and end-of-match handling is per-player, so neither needed a change.
  **Verified live, both Places, ONE session (37 asserts, 0 failures):** v3 and v2 rejected; v4 with
  `IsMatchmade=true` reaching `matchState`; absent/non-boolean defaulting FALSE; one payload carrying
  two different `PartyId`s plus a player with none; the queue's bucket/pack/elect rules including
  "never split a party" and lowest-userId election; and a 4-name roster arriving with 1 player
  scaling the economy on 1 (multiplier 1.0) instead of 4 (0.8×).
  `ReserveServer` is **HTTP 403 in Studio**, so the cross-server handoff's final step is a permanent
  verification gap — assertions are on the payload BUILT, never on a completed teleport.
- **v3** (2026-08-14, B20 Integration): `MatchLaunch` gains `DifficultyMode` (`"Normal"`/`"Insane"`);
  `PayloadVersion = 3`. **Migration: none — a hard cutover**, the same stance as v2. Both Places were
  deployed in the SAME session, so no v2 sender can exist; the Game rejects v2 with
  `[CONTRACT] PayloadVersion mismatch: got 2, expected 3`.
  **Old → new for a consumer:** a v2 reader saw no mode at all and `RewardCalculator` defaulted to
  Normal, which is why P5's Insane item rewards could never fire live. A v3 reader gets the mode on
  `rawConfig.DifficultyMode` → `matchState.DifficultyMode` → the Insane branch in
  `RewardCalculator.GrantForPlayer`. Nothing else moved: `DifficultyPercent` keeps its meaning,
  range (1–1000) and name (ADR-0011 untouched).
  **Verified live, both Places, ONE session (37 asserts, 0 failures):** the Lobby built
  `MatchLaunch v3 ... difficulty=545 mode=Insane` from P4's published attribute with no
  re-derivation; the Game accepted a v3 Insane payload and it reached `matchState.DifficultyMode`,
  rejected a v2 payload with `[CONTRACT]`, failed unrecognised and missing modes SAFE to Normal, and
  Insane actually committed the two Insane items (`BannerTicket` 0→1, `TraitRerollToken` 0→1) while
  Normal committed none — both runs inside the SAME gold band, proving mode does not scale gold.
  Reserved-server teleports cannot complete from Studio (`ReserveServer` = **HTTP 403**), so the
  assertions are on the payload the server RECEIVES and BUILDS, never on a completed teleport; that
  403 doubles as the error-path proof (the veil lifted on its own).
- **v2** (2026-08-01, A2 Integration): `Players[uid].Loadout` = unit **uuids** (save schema v2)
  instead of towerIds; `PayloadVersion = 2`. **Migration: none — a hard cutover.** Both Places
  were deployed in the same session, so no v1 sender can exist; the Game rejects v1 with
  `[CONTRACT] PayloadVersion mismatch: got 1, expected 2`. Verified: v2 payload accepted
  (uuids preserved, numeric userId keys), v1 rejected, unknown stage rejected, difficulty
  clamp intact; Lobby built a real 6-uuid launch payload live.
- **v1** (2026-07-17): first implemented version. Reserved-server-per-party delivery, party
  assembly in payload, `PayloadVersion = 1`. No migration (v0 was an unimplemented draft).
- **v0** (draft): shape sketched ahead of the Lobby build; never shipped.
