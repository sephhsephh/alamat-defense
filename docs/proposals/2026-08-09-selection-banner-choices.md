# PROPOSAL — `BannerChoices`: the Selection banner's stored pick

<!-- author: AD-Gacha (B7, 2026-08-09) | status: SCHEMA HALF EXECUTED B29 2026-08-17 (AD-Integration) -->
<!-- blocks: blueprint task B4's Selection half. The Event half shipped at B7 without it. -->

> **THE CONTRACT HALF IS DONE (B29, 2026-08-17, AD-Integration).** Steps 1–4 of "Recommended route"
> below are executed exactly as written: `BannerChoices` + the `BannerChoice` type are in
> `ProfileData` and `Template`, `SCHEMA_VERSION` is **3**, `Migrations[2]` is the deliberate no-op
> with the comment saying so, and `ProfileTemplate` (`63a0c98a` → **`72d3944f`**) is deployed to
> BOTH Places in ONE session per invariant 5. Verified live, 8 PASS / 0 FAIL from a real server
> Script: a v1 table walks 2 steps to v3, a v2 table walks 1 non-destructively, the live dev profile
> logged `Migrated ... forward 1 step(s) to v3` on a real DataStore, and a written entry survived a
> stop/start round trip.
>
> **WHAT IS LEFT IS THE FLOW — §"Then the flow itself" — and it is AD-Gacha's, all Lobby-local.**
> Nothing blocks it now. Selection banners stay validated-but-refused until it lands.

## Why this is a proposal and not just code

Blueprint task B4 is *"Selection banner choice flow + Event banner window"*. **B7 shipped the Event
half and stopped at Selection**, because Selection needs somewhere to persist each player's chosen
featured unit and **schema v2 has no such field**. The only mention of `BannerChoices` anywhere in
the repo is the blueprint line that specifies it.

Adding it is a contract change, and the blueprint's own cross-phase invariant 5 ends with:

> *"Never both Places out of schema sync across a session boundary."*

B7 was a Lobby-only session under instructions not to touch the Game place. Bumping
`SCHEMA_VERSION` there would have left the Game on v2 and the Lobby on v3 **while both Places share
one live ProfileStore** — precisely what that invariant forbids. So the field was not added, and
`Selection` remains registered, validated, and refused (`banner_type_not_supported_yet`).

## What is needed

A new top-level profile field. Blueprint shape, unchanged:

```lua
BannerChoices = {
  [bannerId] = { TowerId = "Necromancer", ChosenAtDay = 20670 },
}
```

`ChosenAtDay` is a `MetaMath.Slot(86400, MetaConfig.ResetOffsetSec)` day number, **not** a
timestamp — that is what makes `Featured.ChoiceCooldown` agree across servers with no stored clock
(cross-phase invariant 3). The cooldown check is then `currentDay - ChosenAtDay >= cooldownDays`.

## Recommended route: additive-optional key

Invariant 5 says *"additive-optional keys = Reconcile + version bump; shape changes = migration
step."* `BannerChoices` is additive-optional, so:

1. Add `BannerChoices: { [string]: { TowerId: string, ChosenAtDay: number } }` to `ProfileData`
   and `BannerChoices = {}` to `ProfileTemplate.Template`.
2. Bump `SCHEMA_VERSION` 2 → 3.
3. Add `Migrations[2] = function(data) end` — **a deliberate no-op with a comment saying so.**
   `Reconcile()` runs before `Migrate()` and has already filled the new key, so there is genuinely
   nothing to migrate. Add the step anyway: `Migrate()` warns and stops at a missing step, and a
   silent gap at v2→v3 would strand every later migration.
4. Re-hash `shared/src/ProfileTemplate.luau`, update `shared/manifest.json`, **deploy to BOTH
   Places in the same session**, and re-verify a real ProfileStore round trip.

**Owner:** `ProfileTemplate` is AD-Game canon (`docs/OWNERSHIP.md`), so AD-Game or AD-Integration
runs the bump. AD-Gacha then builds the flow on top.

## Then the flow itself (AD-Gacha, Lobby, after the bump)

Config shape is already the blueprint's and `BannerRegistry` already parses it:

```lua
Featured = { PlayerChoice = true, ChoiceCooldown = 86400, AutoCount = 2, AutoRotation = 86400 }
```

- `BannerRegistry.FeaturedFor` currently returns `{}` for `PlayerChoice = true` banners and says so
  in a comment. It gains a per-player variant, because a Selection banner's featured set is
  **player-specific** — the first thing in this system that is not derivable from config + clock
  alone. The existing pure function must keep working for the `AutoCount` randoms.
- Featured = the player's pick **plus** `AutoCount` deterministic randoms drawn with
  `RngForSlot(slot(AutoRotation), bannerId)`, excluding the pick so it cannot appear twice.
- A new remote (`ChooseBannerUnit`) writes the pick; the server re-checks the cooldown and that the
  chosen `TowerId` is in the banner's pool. **The client is a request, never truth** — same rule
  `LoadoutService` follows.
- Turning it on is then one line: add `Selection` to `SUPPORTED_TYPES` in `BannerRegistry`. The
  summon screen needs no change, because B7 moved the "is this banner pullable" policy into
  `BannerRegistry.BlockedReason`, which both the server and the screen already read.
- The choice UI replaces the `ClosedOverlay` on a Selection card.

## Alternative that was considered and rejected

**Store it in `Counters.Global`** (an open `{ [string]: any }` map already in schema v2, so no bump
— the ADR-0008 precedent). Rejected: a banner choice is not a counter, Phase D's quest system
iterates that map by design, and ADR-0008 exists precisely because overloading one key with two
meanings corrupted a verified counter. Buying a day's convenience with that is a bad trade.

## Until this lands

Selection banners are safe to ship as config files: `BannerRegistry.Validate()` accepts them,
`BlockedReason` renders *"Selection banners are coming soon"* on the card, and `SummonService`
refuses them with `banner_type_not_supported_yet`. Nothing half-serves them.
