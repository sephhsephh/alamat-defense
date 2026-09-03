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
it — but B48 chose a permanent gamepass, so keeping `Owned` is correct). Rolling the season is a content edit here.

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

## ✅ MONETIZATION WIRED (B48, AD-Meta) — the paid track is a permanent gamepass unlock
The Paid track unlocks by owning the **Alamat Pass gamepass**. AD-Meta's call: a **gamepass** (permanent),
not a per-season dev product — it matches the SeasonId rule that keeps `Owned` across seasons, so a
one-time buy unlocks the paid track for good. Ownership is **authoritative** via `MarketplaceService`;
`Data.Battlepass.Owned` is a cache `BattlepassService` keeps in sync, and the service stays THE one writer:
- On `ProfileLoaded` (+ a boot-race sweep) → `UserOwnsGamePassAsync` → `setOwned` (authoritative: a
  refund flips it back on the next join).
- On server-side `MarketplaceService.PromptGamePassPurchaseFinished` → `setOwned(true)` immediately.
- The client PurchaseButton / AlamatPassButton call `PromptGamePassPurchase`; the screen re-syncs on
  completion so the paid slots unlock without a rejoin. `GetBattlepass` now returns `GamePassId`.
`BattlepassConfig.GamePassId` is the one knob. **`0` = NOT configured: every purchase/ownership path
no-ops — safe in Studio and in production until the id is set.** THE USER creates the gamepass (Creator
Dashboard → Monetization → Passes), sets its price there (the art shows 799 R$), and pastes the id into
`BattlepassConfig.GamePassId`. Verified B48: boots clean with the wiring logged, `GamePassId=0` safely
no-ops (no web calls, no errors), `GetBattlepass` exposes `GamePassId`; the live purchase/ownership sync
needs the published gamepass and follows the standard MarketplaceService pattern.
**Level-skip products (5/10/50) remain unbuilt** — a separate dev-product `ProcessReceipt` flow.

## Verified live (Lobby Play, B42)
| case | result |
|---|---|
| `addXP 250` via the server channel | XP=250, level 3 |
| `GetBattlepass` | SeasonId Season1, 50 tiers, Owned false, tiers 1–3 unlocked |
| claim tier 1 Free | ok, Silver x100; again → `already_claimed` |
| claim tier 1 Paid (Owned false) | `not_owned` |
| claim tier 5 Free (level 3) | `not_unlocked` |
| claim tier 11 / tier 1 `"Bogus"` | `bad_tier` / `bad_track` |
| set Owned, claim tier 2 Paid | ok, Silver x200; again → `already_claimed` |
| force stale SeasonId, re-Get | XP=0, level 1, claims cleared, **Owned kept** |

Content (`XPPerTier`, tiers, rewards) is **PLACEHOLDER**, labelled in the file. The blueprint's **50
tiers now ship** (B44) via a compact generator in the file — Free/Paid per tier, a rotating ITEM
milestone every 5th tier, a tier-50 finale; edit the rule or override a single tier after the loop.
Every reward Id is validated against `ItemCatalog` at boot.

## The screen (B42)
Built as **BLOCKOUT** to `docs/specs/2026-08-28-battlepass-screen.md` (Quests/Shop pattern).
`StarterGui.BattlePassGUI` + `BattlePassController`; `HUD.Right.Buttons.BattlePassButton` fires
`ClientEvents.OpenBattlepass` (self-wired). Horizontal tier track (Free/Paid slots per column), XP bar,
lock + claimed states, `Owned` gate on the paid track; claim → `ShowRewards`. Verified live (Level 4/10,
tiers 5+ LOCKED; Free/Paid claims; not_unlocked; already_claimed). The spec is the CONTRACT: re-author
keeping the names, zero controller edits.

## Still not built
**Level-skip products** (5/10/50) — a dev-product `ProcessReceipt` flow. The paid-track unlock landed
at B48 (gamepass) and the match-end XP source at B43, so the core loop is complete; what remains is the
user creating the Alamat Pass gamepass and pasting its id into `BattlepassConfig.GamePassId`.
