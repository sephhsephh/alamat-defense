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

## ⚠ TWO THINGS ARE DELIBERATELY NOT BUILT (open decisions)
1. **THE XP SOURCE.** Blueprint: BP XP is committed **AT MATCH END**, `f(waves, outcome)` — a GAME
   place change (`RewardCalculator`), a cross-Place contract (Game → MatchReturn → Lobby). Until it
   lands, XP moves ONLY through `ServerStorage.BattlepassAddXP` (a **BindableFunction** so no client
   can reach it — BP XP is earned, never requested). Nothing calls it yet: the same state Quests was
   in before B41 wrote its counters. The service warns at boot.
2. **MONETIZATION.** Blueprint: the Paid track unlocks via a **gamepass/dev product**, plus level-skip
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

## Not built
The **screen** (blockout to a spec, the Quests/Shop pattern) — `HUD.Right.Buttons.BattlePassButton`
is still unwired. Plus the two deferred decisions above (match-end XP source; monetization).
