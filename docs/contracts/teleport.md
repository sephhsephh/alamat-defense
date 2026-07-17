# Contract: Teleport Payloads (Lobby ⇄ Game)
<!-- owner: lobby | scope: global | version: 0 (DRAFT — not implemented) | last-verified: 2026-07-17 -->

Drafted ahead of the Lobby build so the Game side can validate against a stable shape.
The Lobby chat owns and finalizes this when implementing the handoff.

## Security stance (already enforced Game-side)

TeleportData is **client-forgeable**. The Game treats it as a *request*, never a truth:
tower levels/traits/XP always come from the player's profile via `PlayerInventoryService`
(`LoadoutValidator` re-validates every loadout). The payload only says *what the player
chose*, never *what they have*.

## Lobby → Game: `MatchLaunch` (v0 draft)

```luau
{
	PayloadVersion: number,     -- this contract's version; Game logs [CONTRACT] on mismatch
	StageId: string,            -- e.g. "Stage1_Act1" (validated against StageRegistry)
	HostUserId: number,         -- lobby creator; game-speed authority
	DifficultyPercent: number,  -- 1..1000 slider (sanitized by DifficultyConfig)
	IsPrivate: boolean,
	Players: { [string]: {      -- key = tostring(userId) (JSON keys must be strings)
		Loadout: { string },    -- chosen towerIds (validated vs profile ownership)
		PartyId: string?,
	} },
	MatchModifiers: { string }?,
	CustomSettings: { [string]: any }?,
}
```

Maps to `MatchDirector.StartMatch` (which already expects exactly these semantics — the
dev harness `MatchLifecycleSmokeTest` fakes this payload today).

## Game → Lobby: `MatchReturn` (v0 draft)

```luau
{
	PayloadVersion: number,
	LastStageId: string,
	Outcome: "Victory" | "Defeat" | "Abandoned",
	SuggestNextActId: string?,  -- so the Lobby can pre-select "continue"
}
```

Rewards are NOT in this payload — they were already committed to the profile by
`RewardCalculator` before teleport (profile session-lock handles the save handoff).

## Open questions for v1 (decide at implementation)

- Reserved servers per party vs public match servers.
- Party assembly data (who's in the lobby group) — payload vs MemoryStore.
- Retry/timeout behavior when TeleportAsync fails mid-party.
