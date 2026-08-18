# SYSTEM — Gacha: Selection banners (the per-player featured set)

<!-- owner: AD-Gacha | home Place: Lobby | scope: lobby -->
<!-- last-verified: 2026-08-18 (B30, live Play) | split from gacha.md at B30 (doc size cap) -->
<!-- read with: docs/systems/gacha.md (the engine this sits on) -->

Blueprint task **B4's Selection half**, shipped B30. Spec:
`docs/proposals/2026-08-09-selection-banner-choices.md` §"Then the flow itself". The engine, the
grant path, pity, rates and the reveal are all `docs/systems/gacha.md`; only what is *specific to a
`PlayerChoice` banner* lives here.

## Where the Selection-only pieces live

| Thing | Path | Canon |
|---|---|---|
| `BannerChoiceService` | `SSS.Server.Meta.BannerChoiceService` | Lobby-local (Script) — **the ONE writer of `Data.BannerChoices`** |
| remote | `RS.Remotes.ChooseBannerUnit` | RemoteFunction (Remotes 17 → 18) |
| the pure rules | `RS.Configs.Banners.BannerRegistry` | Lobby-local — `ChoiceState`, `ChoicePool`, `FeaturedForPlayer`, `CurrentDay` |
| shipped banner | `RS.Configs.Banners.SelectionAncestors` | Lobby-local |
| UI | `StarterGui.SummonScreen…BannerCardTemplate.{ChoiceOverlay,ChooseButton}` | authored instances + `SummonController` |
| stored field | profile `BannerChoices` | save schema **v3** (AD-Game canon, landed B29) |

## Selection banners (B30) — the one featured set NOT derivable from the clock

`Featured = { PlayerChoice = true, ChoiceCooldown = 86400, AutoCount = 2, AutoRotation = 86400, Boost = 4 }`
is the whole declaration. Everything else about a Selection banner is ordinary; what is special is
that its featured set contains **the player's own pick**, stored as save-schema **v3**'s
`BannerChoices[bannerId] = { TowerId = "Necromancer", ChosenAtDay = 20682 }` (landed B29).

> **`ChosenAtDay` is a `MetaMath.Slot(86400, MetaConfig.ResetOffsetSec)` DAY NUMBER, never a
> timestamp** — that is what makes `ChoiceCooldown` agree across servers with no stored clock
> (invariant 3). The test is `currentDay - ChosenAtDay >= cooldownDays`. Never `os.time()`.

Registry API, all **pure** and all shared by the server (which enforces) and the screen (which
explains), so a greyed button and a refusal cannot disagree — the `BlockedReason` pattern:
`CurrentDay` (the day number, ONE place) · `ChoiceCooldownDays` (seconds → whole days, **rounded
up**, so a sub-day value never becomes a free change) · `IsPlayerChoice` · `ChoicePool` (flat,
SORTED, Secret excluded — the same list the screen renders and the server tests against) ·
`IsChoosable` · `ChoiceState` → `{ TowerId, ChosenAtDay, CanChange, DaysLeft }` ·
**`FeaturedForPlayer`** = the pick FIRST, then `AutoCount` deterministic randoms from
`RngForSlot(slot(AutoRotation), bannerId)` **excluding the pick** so it cannot appear twice (a
non-`PlayerChoice` banner falls through to `FeaturedFor`, so callers need not know the type).
`FeaturedFor` is untouched and still returns `{}` for `PlayerChoice`; both draw through one
extracted private `drawFeatured`, so there is ONE draw, not two that can drift.

**`Server.Meta.BannerChoiceService` is THE ONE WRITER of `Data.BannerChoices`** (the single-writer
shape `GrantService` has for grants). `RS.Remotes.ChooseBannerUnit` has two modes — `(bannerId)`
READS pick + eligibility, `(bannerId, towerId)` WRITES. One remote because the spec names one: the
read is a few fields only this system wants, so it neither joins `GetUnitViews` (the COLLECTION read
path, ADR-0004) nor earns a second remote. **The client is a request, never truth:** the handler
re-checks existence, type, support, window, pool membership and cooldown. Re-picking the unit you
already have is a **no-op** (`Unchanged = true`) that does NOT rewrite `ChosenAtDay`, so a stray
click cannot restart the cooldown. Refusals: `not_a_selection_banner` · `not_in_pool` ·
`choice_on_cooldown` (+`DaysLeft`). `SummonService` refuses a pull with **`choice_required`** when
nothing is stored (a premium price for pure auto-randoms is the half-serve B7 declined to ship) and
`choice_no_longer_in_pool` if a re-curated banner orphaned a pick; otherwise it passes the list to
`SummonEngine.BuildContext(cfg, nowSec, featuredOverride)` — the engine's only non-pure input, and a
LIST, so it still never learns what a profile is.

**Shipped: `SelectionAncestors` ("Call of the Ancestors")** — Gold 130/pull, curated pool of 7 (Farm
excluded, as in the event), `Boost = 4`, one-day cooldown, 2 daily autos, `PityRef = "Default"`,
always open. Rates are deliberately worse at the top than the event's (Mythic 1.5% vs 2%): the value
is aiming the Boost, not a better curve.

**UI:** `ChoiceOverlay` + `ChooseButton`, real authored instances on `BannerCardTemplate`. The
overlay **replaces `ClosedOverlay`'s role** on a Selection card — with no pick the chooser *is* the
card, and once a pick exists `ChooseButton` brings it back. Option chips are clones of the shared
`Kit.UnitIconV2` master filled by `SummonController`'s own helpers (invariant 2), and the authored
`UIHoverStroke` doubles as the selected marker on `hovering or selected` — the rule
`UIKit.ItemIcon` and the Units grid already use. Harness: set the ScreenGui's **`DevChoose`** to a
towerId to run the real confirm path (a chip click cannot be fired from tooling). Leave it `""`.
