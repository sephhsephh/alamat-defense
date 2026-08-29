# Battlepass — the seasonal tier ladder (Lobby meta, AD-Meta/AD-Gacha)

<!-- owner: lobby | scope: lobby | last-verified: 2026-08-28 (B42) -->

A per-season ladder with a **FREE** and a **PAID** track, earned by playing (no currency). Blueprint
Phase E (`docs/blueprints/phases-b-f-meta.md`).

| piece | what it is |
|---|---|
| `RS.Configs.Meta.BattlepassConfig` | PURE: the active season's `SeasonId`, `XPPerTier`, and `Tiers[i] = {Free, Paid}`. |
| `SSS.Server.Meta.BattlepassService` | **THE one writer of `Data.Battlepass`**; owns `GetBattlepass` + `ClaimBattlepassTier`, and the XP granter `addXP` reached via `ServerStorage.BattlepassAddXP`. |

`RS.Remotes` **31 → 33** (`GetBattlepass`, `ClaimBattlepassTier`). **No schema bump:**
`Battlepass { SeasonId, XP, Owned, ClaimedFree, ClaimedPaid }` has been in the template since v2 with
no writer — the same free ride `LoginStreak`/`Quests`/`ShopStock` got.

## The data
`Data.Battlepass = { SeasonId, XP, Owned, ClaimedFree[tier]=true, ClaimedPaid[tier]=true }`.
`Level = floor(XP / XPPerTier) + 1`, clamped to `MaxTier`. A tier is **unlocked** when `Level ≥ tier`.

## ⚠ SeasonId is a STATIC string, not a time slot
Blueprint: "season rollover = new file + SeasonId switch (old claims keyed by SeasonId — no wipe)".
When the stored `SeasonId` ≠ the config's, the service **RESETS** XP + both Claimed maps for the new
season. **`Owned` is NOT reset** (a gamepass-style permanent unlock; a per-season product would reset
it — part of the deferred monetization decision). Rolling the season is a content edit here.

## Claiming: GRANT FIRST, MARK SECOND
Free always (once unlocked); **Paid requires `Owned`**. Validate tier/track → `Level ≥ tier` →
(Paid) `Owned` → not already claimed → `GrantService.Grant` → mark. Reveal is the RETURN VALUE (B37).
Reason codes: `bad_tier` · `bad_track` · `no_such_tier` · `not_unlocked` · `not_owned` ·
`already_claimed` · `nothing_to_claim` · `grant_failed` · `profile_not_loaded` · `busy`.

## ✅ THE XP SOURCE IS WIRED (B43, AD-Game)

BP XP is committed **at match end**, `f(waves, outcome, difficulty)`, and travels
**Game → `MatchReturn` → Lobby**:

`RewardCalculator` (compute + accumulate) → `MatchReturn.BattlepassXP` → `MatchReturnService` →
`ServerStorage.BattlepassAddXP` → `BattlepassService` (**still the one and only writer**).

The rule lives in the **Game's** `Configs.Global.BattlepassXpConfig` — placeholder values, the shape
is the user's call (B43): `50 base + 5/wave`, a Defeat pays 40% of what it earned, all scaled
1.0→2.0 by wire difficulty. A 15-wave Victory on Normal is 125 XP, about 1.25 tiers here.
An **Abandoned** run pays nothing, matching B41's rule that an aborted match grants nothing.

**Nothing in this Place changed to receive it.** `BattlepassAddXP` was built at B42 for exactly this
caller, and it is still a `BindableFunction` so no client can reach it — BP XP is earned, never
requested. Full contract, both delivery guards and the known limit: `docs/contracts/teleport.md`.

## ⚠ ONE THING IS STILL DELIBERATELY NOT BUILT (open decision)
1. **MONETIZATION.** Blueprint: the Paid track unlocks via a **gamepass/dev product**, plus level-skip
   products (5/10/50). No purchase is built; `Owned` gates the paid track and nothing sets it. Wiring
   a Robux product is a business decision, deliberately left out.

## Verified live (Lobby Play, B42)
| case | result |
|---|---|
| `addXP 250` via the server channel | XP=250, level 3 |
| `GetBattlepass` | SeasonId Season1, 10 tiers, Owned false, tiers 1–3 unlocked |
| claim tier 1 Free | ok, Silver x100; again → `already_claimed` |
| claim tier 1 Paid (Owned false) | `not_owned` |
| claim tier 5 Free (level 3) | `not_unlocked` |
| claim tier 11 / tier 1 `"Bogus"` | `bad_tier` / `bad_track` |
| set Owned, claim tier 2 Paid | ok, Silver x200; again → `already_claimed` |
| force stale SeasonId, re-Get | XP=0, level 1, claims cleared, **Owned kept** |

Content (`XPPerTier`, tiers, rewards) is **PLACEHOLDER**, labelled in the file. Blueprint target is
**50 tiers** (ships 10). Every reward Id is validated against `ItemCatalog` at boot.

## The screen (B42)
Built as **BLOCKOUT** to `docs/specs/2026-08-28-battlepass-screen.md` (Quests/Shop pattern).
`StarterGui.BattlePassGUI` + `BattlePassController`; `HUD.Right.Buttons.BattlePassButton` fires
`ClientEvents.OpenBattlepass` (self-wired). Horizontal tier track (Free/Paid slots per column), XP bar,
lock + claimed states, `Owned` gate on the paid track; claim → `ShowRewards`. Verified live (Level 4/10,
tiers 5+ LOCKED; Free/Paid claims; not_unlocked; already_claimed). The spec is the CONTRACT: re-author
keeping the names, zero controller edits.

## Still not built
**Monetization** — the paid unlock + level-skips; `Owned` gates the paid track and nothing sets it.
The match-end XP source, the other half of this pair, landed at B43.
