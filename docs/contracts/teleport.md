# Contract: Teleport Payloads (Lobby ⇄ Game)
<!-- owner: lobby | scope: global | version: 3 | last-verified: 2026-08-14 (B20) -->

Version 3 (2026-08-14, B20 Integration) — implemented and deployed on BOTH sides in ONE session.
Delivery is **reserved (private) servers per party**: a launch reserves a fresh Game server and
teleports only the party's members into it, so a match server contains exactly one party.

**v3 changes exactly one thing:** `MatchLaunch` carries `DifficultyMode` (`"Normal"` / `"Insane"`),
and `PayloadVersion = 3`. Everything else (delivery, security stance, `MatchReturn` shape, failure
handling) is unchanged from v2.

**Why this is a HARD version bump and not a quiet additive field.** Insane pays extra ITEM rewards
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
	HostUserId: number,         -- party host; game-speed authority (re-checked Game-side)
	DifficultyPercent: number,  -- 1..1000 (sanitized both sides: StageRegistry.SanitizeDifficulty / DifficultyConfig)
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

## Game → Lobby: `MatchReturn` (v2)

Shape unchanged from v1 — only the version integer moved (one version covers both directions).

```luau
{
	PayloadVersion: number,     -- = 2
	LastStageId: string,
	Outcome: "Victory" | "Defeat" | "Abandoned",
	SuggestNextActId: string?,  -- so the Lobby can pre-select "continue"
}
```

Rewards are NOT in this payload — they were already committed to the profile by
`RewardCalculator` before teleport (profile session-lock handles the save handoff).

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
