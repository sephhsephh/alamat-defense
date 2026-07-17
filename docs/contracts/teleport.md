# Contract: Teleport Payloads (Lobby ⇄ Game)
<!-- owner: lobby | scope: global | version: 1 | last-verified: 2026-07-17 -->

Version 1 — implemented Lobby-side (2026-07-17). Delivery is **reserved (private) servers per
party**: a launch reserves a fresh Game server and teleports only the party's members into it,
so a match server contains exactly one party. The Game side must read `TeleportData.MatchLaunch`
and start the match from it (PENDING for AD-Game — see STATE.md).

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

`GamePlaceId` lives in `ReplicatedStorage.Configs.LobbyConfig` and is **currently stubbed `0`**
(user to fill with the real Game place id). While it is `0`, the Lobby logs `[Teleport]` and
skips the actual teleport so nothing errors — everything up to the reserve call is exercised.

## Lobby → Game: `MatchLaunch` (v1)

```luau
{
	PayloadVersion: number,     -- = 1; Game logs [CONTRACT] on mismatch
	StageId: string,            -- e.g. "Stage1_Act1" (validated vs the Game's StageRegistry)
	HostUserId: number,         -- party host; game-speed authority (re-checked Game-side)
	DifficultyPercent: number,  -- 1..1000 (sanitized both sides: StageRegistry.SanitizeDifficulty / DifficultyConfig)
	IsPrivate: boolean,         -- always true in v1 (reserved server)
	Players: { [string]: {      -- key = tostring(userId) (JSON keys must be strings)
		Loadout: { string },    -- chosen towerIds (validated vs profile ownership Game-side)
		PartyId: string?,       -- shared party id for this launch
	} },
	MatchModifiers: { string }?,
	CustomSettings: { [string]: any }?,
}
```

Maps to `MatchDirector.StartMatch` (which already expects exactly these semantics — the dev
harness `MatchLifecycleSmokeTest` fakes this payload today). Party assembly travels **in the
payload** (assembled at launch from `PartyService`); no MemoryStore handoff in v1.

## Game → Lobby: `MatchReturn` (v1)

```luau
{
	PayloadVersion: number,     -- = 1
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

## Deferred to v2

- Public / matchmaking servers (join strangers) — v1 is reserved-per-party only.
- Party persistence across a rejoin, cross-server party invites (MemoryStore) — v1 parties are
  single-lobby-server, in-memory only.
- Rejoining an in-progress reserved match.

## Version history

- **v1** (2026-07-17): first implemented version. Reserved-server-per-party delivery, party
  assembly in payload, `PayloadVersion = 1`. No migration (v0 was an unimplemented draft).
- **v0** (draft): shape sketched ahead of the Lobby build; never shipped.
