# CHANGELOG (append-only; newest first)

## 2026-08-09 [lobby] B6 (AD-UI) — the SUMMON UI. Banner carousel + x1/x10, config-driven. Drift untouched.

Bootstrap drift **23/23 GREEN**, unchanged at landing — **no shared module or template was
touched**. Integration gate: **"No Integration needed — proceeding."** This is the blueprint's
Phase-B task **B3, "summon UI + RewardPopup wiring"** (changelog counter B6 — the two sequences
reuse the same letters; `STATE.md` now warns about that up front).

**THE SESSION OPENED BY ASKING, because three parts of the blueprint had no foundation here.**
Grep and inspection first, then the user decided:

1. **"Summon NPC (NPCPrompt)"** — the Lobby has **zero ProximityPrompts** and no NPC rig at all.
   The HUD already has a `Summon` button. User: use the button now, **but make an NPC a drop-in
   later**. So the entry point is an EVENT, not a call: `RS.ClientEvents.OpenSummon:Fire()`. The
   HUD button fires exactly that and gets no other privilege — an NPC's prompt will fire the same
   event with **zero changes to the screen**. That indirection is the whole point of the decision.
2. **"skip-anim toggle (Settings)"** — the Lobby has **no settings system whatsoever** (verified:
   nothing matching `setting` in `ServerScriptService`, `ReplicatedStorage` or `StarterPlayer`).
   The user wants something bigger than a toggle: **ONE settings system for BOTH Places**, same
   structure and same GUI, entries scoped per Place. That is cross-Place shared canon and
   `SettingsService` is AD-Game's, so it was raised properly instead of bolted onto a gacha screen
   → **`docs/proposals/2026-08-09-unified-settings-both-places.md`** + a PENDING. Nothing is
   blocked: B4's click-to-skip already covers the functional need.
3. **Who designs the screen** — every good-looking screen here was hand-designed by the user. They
   chose: **AD-UI authors a plain but functional real-instance tree, user restyles later** (the
   `StarterChoiceScreen` precedent). Restyling is safe because the controller reads its metrics off
   the instances.

**What was built** — `StarterGui.SummonScreen` + `SummonController`, and
`RS.ClientEvents.OpenSummon`.

**It is config-driven, which is the part that matters for maintenance.** Nothing on screen is
typed out:

| On screen | Derived from |
| --- | --- |
| which banners exist + order | `BannerRegistry.List()` (auto-scans its folder) |
| featured units this rotation | `BannerRegistry.FeaturedFor(cfg)` — clock + config only |
| open / closed | `BannerRegistry.IsOpen(cfg)` |
| the rates table | `cfg.Rates`, normalised |
| how many pull buttons | `GachaConfig.AllowedPullCounts` |

Ship a banner file and it appears; add `100` to `AllowedPullCounts` and a third button appears.
Neither needs code. **No new remote was added** — `BannerRegistry` is in ReplicatedStorage for
exactly this, and the client deriving the same featured set is not a trust problem because the
server re-derives at pull time. This screen's entire authority is a banner id and a pull count.

- **The reveal is consumed, never modified.** `RequestSummon` returns the views;
  `ShowRewards:Fire(result.Rewards)` **unchanged**. x10 = ONE call, ONE reveal.
- **Featured chips are clones of the SHARED `Kit.UnitIcon`** (cross-phase invariant 2). That gives
  the template its **first real consumer** — but it **does NOT settle ADR-0007**; whether the
  reveal/index card is `Kit_UnitIcon` or the user's `UnitTemplate` is still blueprint B5's call,
  and is recorded as still-open. No `UIKit.UnitIcon` controller was built (ui-kit.md forbids
  building one speculatively); chips are cloned and filled locally, exactly as
  `ObtainRewardsController` does with `Kit_ItemIcon`. Chip size reads from `FeaturedRow`'s
  attributes.
- **Balance uses `GetUnitViews`**, the Lobby's SINGLE profile read path (ADR-0004) — no second read
  path for a currency number — then `result.Currencies` after a pull, so success costs no extra
  round trip.
- **Refusals surface rather than swallow.** Reason codes map to readable text; an UNKNOWN code
  prints the raw code instead of a friendly lie, so a new server reason stays visible.

**Verified LIVE in Play through the REAL remote** (a `DevPull` attribute routes through the same
`doPull()` a button press runs, because `MouseButton1` cannot be fired from tooling — the
`DevDismiss` convention B4 established and B5 approved):

| Check | Result |
| --- | --- |
| carousel renders from config | **PASS** — "Alamat Standard", type Standard, `ClosedOverlay` off |
| featured chips | **PASS** — Archer / Babaylan / Warchief, 120×120, viewport models loaded |
| client featured == server featured | **PASS** — server logged `FEATURED` on exactly those ids |
| rates from weights | **PASS** — 60/25/10/4/1.00/**0.0050%** (Secret needs 4dp, not 2) |
| x1 | **PASS** — Gold 48800 → 48700, reveal 1 cell |
| x10 | **PASS** — Gold → 47700, reveal 10 cells, frame `812×338`, 2 rows, no scroll |
| disallowed count (x7) | **PASS** — refused server-side, "That pull count is not allowed", **balance unchanged** |
| totals | **PASS** — 21 pulls × 100 = 2100; 48800 → 46700 exactly |
| prev/next with 1 banner | **PASS** — hidden, not dead |

**Contract impact: NONE.** No schema, no teleport payload, no shared module, no template. One new
client-side BindableEvent and one new Lobby-local screen.

**PENDINGs: 3 NEW, 0 cleared.** (1) the unified settings system (proposal above); (2) the HUD
`CurrencyBar` does not refresh after a summon — SummonScreen's own balance IS correct, but the HUD
reads stale Gold until rejoin, and it wants a `ClientEvents.CurrencyChanged`; (3) recorded on the
existing entry: `Kit_UnitIcon` now has a consumer but ADR-0007 is still open. `STATE.md` was
trimmed back to **120/120** to fit them (ADR-0006) — the "Next up" history moved into this file,
where it belongs.

**USER must republish the LOBBY** — B6, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B5 (AD-UI) — B4's animation REVIEWED + APPROVED. Fixed a clipped level badge that predated it.

Bootstrap drift **23/23 GREEN**, unchanged at landing. Integration gate: **"No Integration needed —
proceeding."** This session touched **zero shared canon and zero code** — the only change is one
container property. Clearing the AD-UI half of the `ObtainRewardsGUI` PENDING.

**The review.** B4 was written by AD-Gacha inside AD-UI's canon on the user's explicit
authorisation, and left a PENDING asking the owner to check it. Every claim was **re-tested live
rather than read**, from a temporary harness driven through the controller's own `DevDismiss` hook
so the real `advance()` path ran:

| Claim | Verdict | Evidence |
| --- | --- | --- |
| Cells reveal one at a time | **PASS** | visible-count progression `1-2-3-4-5-6-7-8-9-10` |
| Hiding cells does not reflow | **PASS** | cell 1's `AbsolutePosition` never moved |
| Back/Out overshoot stays small | **PASS** | peak `UIScale` **1.0398** — B4 predicted ≈1.04 |
| Skip is instant, NOT gated | **PASS** | n=15: 2 visible → 15, all at scale 1.000, still open |
| Close IS gated, from reveal END | **PASS** | refused inside the dead period, accepted after |
| Animation disturbs no layout | **PASS** | n=20 still `806×482`, canvas 640, `CanvasPosition` 0 |
| n=1 edge case | **PASS** | `166×166`, one cell, full scale |
| Shared canon untouched | **PASS** | drift 23/23; `Kit_ItemIcon` still `5623f4b4` |
| Click catcher intact | **PASS** | `Main.Active=true`, Pos `0,0`, Size `1,1` |

**Approved as written.** The `UIScale`-on-the-clone decision is correct, and putting it on `Main`
rather than the grid-positioned root is the right call for exactly the reason B4 gave.

**Two honest caveats on the review itself, recorded rather than glossed:**

1. **The queue-race test was badly built and did NOT isolate what it claimed.** The harness sent two
   dismisses; the second skipped batch 2, so the stale-loop race was never exercised. Reading the
   code, that race is in fact **unreachable** — the only route to the next batch is `dismiss()`,
   which requires `not revealing` — so `revealToken` is belt-and-braces, not load-bearing. Correct
   either way, but proven by inspection, not by the run.
2. **`startReveal` has no `pcall`.** If it ever threw mid-loop, `revealing` would stick `true` and
   `dismiss()` would be blocked — but `advance()` → `finishReveal()` still fires, so a single click
   recovers it. Self-healing; left alone deliberately rather than adding a guard nothing needs yet.

**THE REAL FINDING — a clipped level badge, and it is B1's defect, not B4's.**
`UnitTemplate.UnitLevel` sits at x `−0.072`: the badge **overflows its own 150px cell by 10.8px to
the left**, and by 14.2px at peak overshoot. With `RewardsFrame` at 8px padding and
`ClipsDescendants = true`, the leftmost column's badge was **permanently cut by 2.8px at rest** and
**6.2px during the pop**. B1 shipped that; B4's animation only made an existing cut briefly wider,
and its own ≈1.04 estimate was accurate.

- **Fixed on the CONTAINER: `UIPadding` 8px → 15px.** Not on `UnitTemplate` — that is the user's
  design, adopted as-is under ADR-0007, and redesigning it to suit the frame would be backwards.
  The controller already reads `UIPadding` off the instance, so **this is a zero-code-change fix**
  and stays retunable in Studio, which is the whole point of B1's read-from-the-instances rule.
- **Verified live after:** worst clip **−4.2px at rest** and **−0.8px sampled through the entire
  reveal** (negative = clearance), peak scale `1.0400`. Frame for n=7 measured `812×338`, matching
  `5·150 + 4·8 + 2·15` and `2·150 + 8 + 2·15` exactly. A full 5×3 grid needs `820×496`, inside the
  `900×600` `UISizeConstraint`.
- **Do not drop the padding back below ~15px**, and re-measure if `RevealStartScale` is lowered or
  the easing strengthened. Written into `docs/systems/lobby-ui.md` with the numbers.

**NEW USER RULE (2026-08-09), now in `CLAUDE.md`: Studio AUTOSAVES — do NOT ask the user to save
before `start_stop_play`, just Play.** The standing-permission line said "ask the user to SAVE
first"; that instruction is retired. Stop when done and leave every `Dev*` attribute OFF as before.

**Contract impact: NONE.** No schema, no teleport payload, no shared module, no template, no code.
One `UIPadding` value on a Lobby-local screen.

**PENDINGs: the AD-UI review half is CLEARED** (deleted from the `ObtainRewardsGUI` entry per
ADR-0006; this entry is its record). Still open in that entry: the unit card's shared-vs-local
status at the unit INDEX, and the reveal answer for quests/login/codes. Nothing new. Untouched:
hotbar hover trigger, `Kit_ItemHoverCard` master/clone, `MetaMath` → Game, `Data.Items` writer,
max-level XP loss, GrantService convergence, trait rarity table.

**USER must republish the LOBBY** — B5, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B4 — reward reveal ANIMATES (one cell at a time) + two-stage click. Drift untouched.

Bootstrap drift **23/23 GREEN**, unchanged at landing — **this session touched ZERO shared canon**,
which was the main constraint to respect rather than a happy accident (below). Integration gate:
**"No Integration needed — proceeding."**

**CROSS-OWNERSHIP, ON THE USER'S EXPLICIT INSTRUCTION.** `ObtainRewardsGUI` /
`ObtainRewardsController` are **AD-UI canon** (`docs/OWNERSHIP.md`), and this is the AD-Gacha chat —
the previous session's own next-session prompt said "do not touch it". The user asked for the
change directly, which is the authorisation, and the repo already has precedent for exactly this
(`LoadoutService` and `GetUnitViews.Items` were both written cross-ownership with the user's
sign-off and recorded loudly). **A PENDING asks AD-UI to review it.** Recording it rather than
quietly editing another chat's system is the whole point of the single-writer rule.

**What changed.** Cells used to appear all at once. Now they reveal **one at a time** (pop-in,
`UIScale` 0.6 → 1, Back/Out), and the click behaviour became two-stage: **click 1 = SKIP, click 2 =
CLOSE**.

**The click-timing decision, which is the part with actual judgement in it.** The old rule was one
click, dead-period gated, so a fast grinder could not stray-click past a rare pull. With a skip step
that rule no longer fits: a click during the reveal only ever shows you *more*. So the user chose —
**skip is instant and NOT gated; close IS gated, measured from when the reveal FINISHED rather than
from when the popup opened.** With an animation, "seen" happens at the end of the reveal, so the
original protection is preserved exactly where it still means something, and the popup feels
responsive instead of dead for 0.35s while cells are visibly still arriving. Letting the animation
finish on its own lands in the identical state as a skip, because both routes go through one
`finishReveal()`, and one `advance()` decides skip-vs-close for both real input and the harness —
so the two can never drift apart.

**Three constraints the implementation had to work around, none of them optional:**

- **`UIGridLayout` FORCES `CellSize` onto every child**, so tweening a cell's `Size` is overwritten
  every frame. `UIScale` is the only size animation that survives a grid.
- **`Kit_ItemIcon` is hashed SHARED canon** (`5623f4b4`, also used by the Items screen). Adding a
  `UIScale` to it would be drift in both Places for a Lobby-only animation. The `UIScale` is
  therefore created on the runtime **CLONE** — which is not a new pattern, it is exactly what this
  controller already does for `UIGradient`, `WorldModel` and `Camera`. **Verified at landing: both
  templates are untouched and `Kit_ItemIcon` still hashes `5623f4b4`.**
- **Popping from the centre without breaking the grid.** The `UIScale` goes on the cell's `Main`
  child after re-anchoring it to `(0.5,0.5)` at position `(0.5,0.5)` — geometrically identical
  coverage, since `Main` is `{1,0},{1,0}` at anchor `(0,0)`. The grid-positioned **root is never
  re-anchored**; that would shift the cell out of its slot. And the overshoot is kept small on
  purpose: `RewardsFrame.ClipsDescendants` is TRUE with 8px padding, so Back/Out from 0.6 peaks at
  ≈1.04 (≈3px per side on a 150px cell) and fits. A lower start scale WILL clip.

**One claim in a code comment that was PROVEN rather than asserted.** Hiding cells until their turn
sounds like it should reflow, because `UIGridLayout` skips invisible children. It does not — cells
reveal in ascending `LayoutOrder`, so each lands in the next free slot and the ones already shown do
not move. Rather than reason about it and hope, the harness sampled cell 1's `AbsolutePosition`
throughout the whole reveal: **it never moved, at n=10 or n=20.**

**Queue safety:** a `revealToken` is bumped on every render, and an in-flight reveal loop from a
previous batch checks it and bails — so clicking through the queue quickly cannot leave an old loop
animating the new batch's cells.

**Tunables are ScreenGui ATTRIBUTES**, matching B1's read-everything-from-the-instances philosophy:
`RevealStaggerSeconds` (0.08), `RevealPopSeconds` (0.22), `RevealStartScale` (0.60),
`RevealMaxTotalSeconds` (1.20 — caps the whole stagger so a 20-cell batch compresses instead of
crawling for 1.6s). Retune the feel in Studio, no code change.

**Verified LIVE in Play from a temporary harness (since deleted), driven through the controller's
own `DevDismiss` hook so the real `advance()` path was exercised, not a simulation:**

- n=10 progression `0→1→2→…→10` — genuinely one at a time; cell 1 never moved; all at full scale.
- **Skip:** at n=15, clicked at 2 cells visible → all 15 instantly at scale 1.000, **still open**.
- **Close refused during the dead period**, then accepted after it. Hint label stays hidden until
  closing is actually possible, so it never invites a click that does something else.
- Queue (3 then 6): both batches animate; n=1 edge case fine.
- **n=20, the only case with a scrollbar** — no auto-scroll (`CanvasPosition` 0,0 throughout), no
  resize mid-reveal, and the off-screen rows 4+ all end at full scale.
- **Layout is byte-for-byte what B1 measured**: n=10 `798×324`, n=15 `798×482`, n=3 `482×166`,
  n=1 `166×166`, n=20 `806×482` canvas 640 with the last cell's bottom at 599 inside a frame bottom
  of 607. The animation disturbed nothing.

**Docs: the `ObtainRewardsGUI` block MOVED from `places/lobby/CONTEXT.md` to
`docs/systems/lobby-ui.md`**, where `docs/INDEX.md` already said Lobby SCREENS belong. That also
closes the cap overrun B3 flagged and declined to fix: **CONTEXT.md is back to exactly 150/150** and
STATE.md holds at 120/120.

**Contract impact: NONE.** No schema, no teleport payload, no shared module, no template. Client-side
Lobby-local behaviour only.

**PENDINGs: 1 NEW (AD-UI to review this), 0 cleared.** Everything else stands.

**USER must republish BOTH Places** — B4, like A7/A8/B0/B1/B2/B3, is Studio canon and not in git.

## 2026-08-09 [lobby] B3 — the BANNER ENGINE. `MetaMath` promoted to shared; Lobby drift 23/23 GREEN.

Bootstrap drift **22/22 GREEN**, exactly as expected (15 modules + 7 templates, `Kit_ItemIcon` at
`5623f4b4`). Integration gate: **"No Integration needed — proceeding."** At landing the Lobby reads
**23/23 GREEN** — one entry ADDED, nothing drifted.

**THE SESSION OPENED BY STOPPING.** The prompt asked for "the banner engine". The blueprint's Phase
B session list is `B1 MetaMath+GrantService+PityConfig · B2 banner registry+summon service+odds
harness · B3 summon UI · B4 Selection/Event · B5 Index`. **None of B1 existed** — grep found no
`MetaMath`, no `GrantService`, no `PityConfig`, no `RS.Configs.Banners`. And B2's algorithm calls
into B1 at nearly every step: `Pick` and the deterministic featured rotation are specified as living
in `MetaMath`, the pity override reads `PityConfig`, banners carry `PityRef`, and the grant step is
`GrantService`, which cross-phase invariant 1 makes mandatory. Building B2 first meant either
improvising those inline (breaking invariant 1 and "never improvise a module name or data shape") or
doing two session-tasks at once. **The user was asked and chose both in one session.**

Worth recording because it will confuse the next reader: **the changelog's `B0/B1/B2/B3` are Phase-B
SESSION COUNTERS; the blueprint's `B1–B5` are SESSION-TASK names.** Two different sequences reusing
the same letters. In blueprint terms this session did B1 + B2, and the next task is the summon UI.

**What was built** — `RS.Shared.MetaMath` (SHARED) + `RS.Configs.{Meta.MetaConfig,
Gacha.{PityConfig,GachaConfig}, Banners.{BannerRegistry,Standard}}` + `SSS.Server.Meta.{GrantService,
SummonEngine, SummonService}` + `RS.Remotes.RequestSummon` (Remotes 12 → 13). Full doc:
**`docs/systems/gacha.md`**.

- **`MetaMath` is the one shared-canon addition**, `6badac1d`, disk and Studio byte-identical at
  4705 bytes. Deterministic `Slot` + weighted `Pick`, pure (no services, no state, no config reads —
  the reset-hour knob is passed IN, which is what keeps it Place-neutral). **Deployed to the LOBBY
  ONLY, deliberately**: nothing in the Game reads it until Phase D challenges, so `deployed.Game` is
  `null` and the Game's drift check now reads **22/23 with `MetaMath=MISSING`, which is the EXPECTED
  state, not drift.** A PENDING says so in as many words, because a future session WILL see that
  number and reach for the reconcile procedure.
- **One non-blueprint addition to `MetaMath`, and it is load-bearing:** `RngForSlot` takes a `salt`.
  The blueprint says "seeded picks: `Random.new(slot)`" — with one banner that is fine, but two
  banners sharing a `RotationPeriod` would then draw the *identical* featured set every rotation
  forever. Salted with the banner id. Verified: same salt stable, different salts differ.
- **`GrantService` is THE one grant path** and `Spend()` lives there too — invariant 1 greps for
  direct `Currencies.` writes, so putting the debit anywhere else breaks it on day one. Validation
  is **all-or-nothing**: every entry is checked before anything is written, verified by a
  `(good, bad)` pair leaving a gold delta of exactly 0. An uncatalogued id is REFUSED rather than
  silently creating a profile field (invariant 4, enforced rather than merely stated).
- **`SummonEngine` was split out of `SummonService`** so the blueprint's mandatory 10k odds harness
  can assert the REAL algorithm — a Script is not requireable, and the alternative is a harness that
  is a second copy of the logic and drifts from it.

**Three real conflicts surfaced. None were papered over.**

1. **A counter-key collision, and the blueprint lost.** The blueprint says gacha increments
   `Counters.Global.Summons`. **A8 already owns that key** for in-match minion summons — it read
   `1152` on the live dev profile. Writing pulls there would have made A8's verified totals stop
   meaning what they were verified to mean and would have let a banner pull complete a "summon 100
   minions" quest. User chose a new key: **`Counters.Global.GachaPulls`**, recorded as **ADR-0008**.
   No schema bump — `Counters.Global` is an open map. Verified: 11 pulls moved `GachaPulls` absent
   → 11 while `Summons` held at 1152.
2. **Trait-on-summon cannot work in this Place and was NOT faked.** The trait rarity table is
   AD-Traits canon in the GAME place; the Lobby has none. The step is a lazy+optional lookup that
   finds nothing and grants `Trait = nil` — exactly what `StarterChoiceService` has always done, so
   summoned units are not a special case. **The RNG draw is still consumed** so the stream will not
   shift the day the table lands. A local trait table would have been the easy wrong answer.
3. **There is no Secret-tier tower**, so a Secret roll has nowhere to land. It falls to the nearest
   **lower** stocked tier; `Validate()` reports it as a content-gap NOTE, not an error. The subtle
   part: **the pity ledger records the AWARDED tier, pre-fallback** — otherwise the Secret counter
   could never reset and every subsequent pull would re-trigger it forever.

**`LuckMult` is an interpretation, flagged as one.** The blueprint declares the key without
semantics. Multiplying every weight is a no-op (`Pick` normalises), so it multiplies the PITY tiers
only. Shipped at `1` = inert, so nothing observable depends on it — but confirm before shipping a
banner with `LuckMult ~= 1`.

**Reveal transport — a decision, not an invention.** Gacha resolves server-side; `ShowRewards` is a
client-side Bindable and B1 chose client-side-only. Rather than quietly adding a push remote, the
user was asked and chose: **`RequestSummon` is a RemoteFunction that RETURNS the views**, and the
client fires the existing `ShowRewards` with `result.Rewards` unchanged. No new remote surface,
`ObtainRewardsGUI`/`ObtainRewardsController` consumed and never modified. **This does not solve
unsolicited grants** (quests, daily login, codes) — they have no requester to return to, and that is
now a named PENDING rather than a trap.

**Acceptance — verified LIVE in Play from temporary harnesses, deleted at landing.**

- **10k dry rolls, `0` distribution failures**, every tier inside 4σ: Common 5967/6000, Rare
  2557/2500, Epic 992/1000, Legendary 404/400, Mythic 80/99.5, Secret 0/0.5 (tolerance floored at 5
  so an ultra-rare tier is not asserted into noise). Shiny 0.870% vs 1.000% configured.
- GrantService: currency; item; **`MaxOwned` cap** (99999 tickets → granted 9996, total 9999,
  `Capped=true`); tower with opts (L40 shiny Necromancer); **duplicates in one call** (Archer ×2,
  distinct uuids — B0's uuid work paying off); uncatalogued id, negative qty and non-atomic batch
  all refused; spend + `insufficient_funds`.
- Pity: forced 49/50 upgraded a **Rare** roll to **Legendary**; all-three-due awarded **Secret** and
  fell back to the Mythic pool; `ApplyPity` 10/20/30 → 11/0/31 → 12/1/32 (blueprint's "reset the hit
  tier, increment the others", taken literally — a Mythic does NOT reset Legendary).
- End-to-end through the REAL remote: x1 and x10 → real reveal.
  `ObtainRewards SHOW n=10 cols=5 rows=2 scrollbar=false` — one popup, 10 entries, 2 rows, no
  scroll, matching B1's measured behaviour. Client-derived featured matched the server's exactly
  (`Babaylan/Archer/Meteor`). Refusals: unknown banner, count 7, count 999999.
- Persisted: units 8 → 22, Gold 50000 → 48800, `GachaPulls` 11, `Pity.Default` L11/M11/S11.

**A tuning observation the user should see:** `Featured.Boost = 5` is aggressive. With 2 Commons and
Archer featured, Archer takes ~83% of its tier — **49.6% of ALL pulls** over 10k. It is one number
in the banner file.

**Contract impact: NONE.** No schema bump — `Pity`, `Currencies`, `Items` and the open
`Counters.Global` map were all already in schema v2, which is the A1 investment paying out. No
teleport payload change. One shared module ADDED (a drift-procedure item, not a contract item).

**PENDINGs: 4 NEW, 1 revised, 0 cleared.** New: deploy `MetaMath` to the Game when something needs
it; AD-Integration to converge the Game's grant paths (invariant 1 is Lobby-only today); AD-Traits
to promote the trait table; a reveal answer for unsolicited grants. Revised: `Data.Items` now HAS
code that can write it, verified — but **no shipping flow grants an item, so that note is NOT
closed.** Also trimmed `STATE.md` and `places/lobby/CONTEXT.md` back under their caps (both had
drifted over): removed a resolved B2 PENDING, collapsed the retired-`GetCollection` block, and
corrected two stale counts (kit "6+8" → 5+7, Remotes 12 → 13).

**USER must republish BOTH Places** — B3's work, like A7/A8/B0/B1/B2's, is Studio canon, not git.

## 2026-08-08 [integration] B2 — kit mirrored + RewardPopup RETIRED (24 → 22). Both Places 22/22 GREEN.

Cleared BOTH of B1's Integration PENDINGs in one session, as B1 recommended (they both touch the
Game's kit). Bootstrap drift: **Lobby 24/24, Game 23/24** with `Kit_ItemIcon = ee1ccd33` — the
expected, documented mismatch, not a surprise. At landing both Places read **22/22 GREEN,
byte-identical, zero mismatches against the manifest.**

**Half 1 — `Kit_ItemIcon` mirrored Lobby → Game.** The two Studio instances are separate processes,
so a cross-Place `:Clone()` is impossible and Studio copy/paste is the checklist's normal route.
Instead the 7 diverged properties were written onto the Game's tree from the Lobby's full-precision
values **and then proved by hash**: the Game re-hashed to **`c5e81264` exactly**, which is the same
equality test step 3 of the template-deploy checklist uses. Recorded caveat: the hash covers the
whitelisted surface only, so a difference in an unhashed property would not be caught — acceptable
here because both trees were byte-identical at `ee1ccd33` and only the Lobby was ever edited.

**Half 2 — `UIKitRewardPopup` + `Kit_RewardPopup` RETIRED.** ADR-0004's procedure, in order:

- **Re-grepped BOTH Places for callers FIRST.** Zero in each: the only hits were the module's own
  source, doc modules, and one stale comment in `ObtainRewardsController` (corrected).
- Controller AND template deleted in **both** Places. `RS.Shared.UIKit` 5 → 4 children,
  `RS.UITemplates.Kit` 8 → 7, identically in each.
- Both manifest entries dropped (**24 → 22 = 15 modules + 7 templates**), both entries removed from
  `tools/hash_shared.luau`, and `shared/src/UIKitRewardPopup.luau` DELETED.
- **Both Places re-verified LOADING afterwards** — a removed module fails at `require`/
  `WaitForChild` time, not at boot, so a clean boot alone would not prove this (A7's lesson).
  Game: full match boot, `MatchEndPresenter`/`HUD`/`MatchEndUI`/hotbar (5 units, 6 slots) all up,
  wave 1 started, no errors, no `Infinite yield`. Lobby: all 7 screen controllers ready, same.
- **An independent confirmation the template really went:** the Lobby's `UIKitBootstrap` tagged-
  button count dropped **34 → 33** — that is `Kit_RewardPopup`'s `CloseButton`. Nothing else moved.

**A REAL DEFECT SURFACED, and it was B1's user-confirmed change, not the retirement.** The live
reveal showed only one quantity badge, on the WRONG card. Measured rather than eyeballed: every
`QtyBadge` sat at offset **`(−72, −99)`** from its own 150×150 cell, `INSIDE_ITS_CELL=false` on all
four — `x7` (TraitRerollToken) painted on the **Necromancer** card, `x500` and `x2` pushed past the
frame edge and clipped away entirely. Cause: the `(0.8565, −150), (0.96, −210)` position B1 recorded
as intentional. **Negative PIXEL offsets do not scale with the card** — fine at the size it was
dragged at, broken in a 150×150 grid cell. This is exactly the risk flagged to the user before they
confirmed it; with evidence in hand they chose to revert.

- `QtyBadge.Position` reverted to `(0.96, 0), (0.96, 0)` in **BOTH** Places in this same session, so
  no drift window ever existed. **`QtyBadge.Size` keeps the user's smaller `0.3365`** — only the
  position was touched. The other three B1 changes (root `Size`/`Position`, `Visible`,
  `IconImage.Image`) are untouched and remain canon.
- `Kit_ItemIcon` canon therefore moved twice today: `ee1ccd33` → `c5e81264` (B1) → **`5623f4b4`**
  (B2, current). Both Places re-hashed to `5623f4b4` independently and matched.
- **Re-verified live:** all four badges now measure `(94, 111)` inside a 150×150 cell,
  `INSIDE=true`, showing `x500 / x2 / x12 / x7` each on its own card.

**Lesson worth keeping (now in `docs/systems/ui-kit.md`):** a scale-anchored element carrying large
negative pixel offsets looks correct at the footprint it was dragged at and breaks at every other
one. On a template reused at different sizes, prefer scale offsets.

**Contract impact:** NONE. No schema bump, no teleport payload change. Two shared entries removed
and one template hash moved — drift-procedure items, not contract items.

**PENDINGs: TWO CLEARED, ZERO NEW.** Both of B1's Integration items are done and DELETED from
`STATE.md` per ADR-0006 (this entry is their record). Untouched and still open: nothing calls
`ObtainRewardsGUI` yet (gacha wires in first), hotbar hover trigger, `Kit_ItemHoverCard`
master/clone, `Data.Items` writer, max-level XP loss, teleport v2 live loop + republish (USER).
`Kit_UnitIcon` remains PARKED (ADR-0007) and untouched at `24281a2b`.

**USER must republish BOTH Places** — B2's deletions are Studio canon in each, not git.

## 2026-08-08 [lobby] B1 — the reward-reveal surface is BUILT. `Kit_ItemIcon` canon bumped; Game now stale.

Bootstrap drift check **23/24**, and the one mismatch was the story of the session (below). At
landing the hashes are **byte-identical to bootstrap** — this session touched ZERO shared canon.
Integration gate: **run an AD-Integration session AFTER this task** (trigger 1 fired, but the build
is independent of the drifted properties, so the checklist's "trigger fired / task independent"
clause applied and it was reported instead of blocking).

**The drift, and why it became a canon bump rather than a revert.** `Kit_ItemIcon` read
`c5e81264` in the Lobby against the manifest's `ee1ccd33`. The Game still held `ee1ccd33`
(confirmed by a read-only trip into that Place — no writes while bound there), so the LOBBY was the
side that moved. A full serialisation diff isolated it to **7 properties on 3 nodes**: root
`Size`/`Position`/`Visible`, `QtyBadge` `Size`/`Position` (including −150/−210 *pixel* offsets on a
bottom-right-anchored badge), and `IconImage` `Image`(→`rbxassetid://101838893546724`)/`Position`.
It looked like an accidental drag, so it was NOT assumed either way: the user was shown each change
with its specific risk and **confirmed all four groups intentional**. Canon therefore moved
`ee1ccd33` → **`c5e81264` with the LOBBY as source**, per the "owner edits shared canon" checklist
(manifest hash + `deployed.Lobby` updated, `deployed.Game` LEFT stale, PENDING raised) rather than
by re-copying from the Game. `Kit_ItemIcon` has no `shared/src` file — the instance is the canon
(ADR-0005) — so there was no file to rewrite.

**Contract impact:** none. No schema bump, no teleport payload change, no shared MODULE touched.
One shared TEMPLATE's canon hash moved, which is a drift-procedure item, not a contract item.

**What was built —** `StarterGui.ObtainRewardsGUI` + `ObtainRewardsController` (LocalScript).

- **Entry point** `RS.ClientEvents.ShowRewards` (new BindableEvent), matching the house pattern
  (`OpenUnitsWithUuid`, `OpenStageSelect`). `Fire({ { Id = "Archer", Level = 12 }, { Id = "Gold",
  Qty = 250 } })`; a bare string id also works. **User decision: client-side only, no caller wired
  this session** — gacha, quests, daily login and codes each wire themselves in as they ship.
- **Mixed cells.** Kind is inferred from `ItemCatalog` (`Kind == "Tower"` → unit cell) and can be
  forced with an explicit `Kind`. An id absent from the catalog **still renders** (name falls back
  to the id, tier Common) — `UIKitRewardPopup`'s correct behaviour, carried over to its successor.
- **The footprint trap was real but defused cheaply.** `UnitTemplate` carries its own
  `UISizeConstraint` at Min = Max = **150×150**, so the cell size was READ off the user's design
  rather than invented, and `UIGridLayout.CellSize` was set to match. `Kit_ItemIcon` already
  carries `UIAspectRatioConstraint AR=1 FitWithinMaxSize`, so in a **square** cell that constraint
  is a no-op instead of a letterbox. **The shared icon was never resized** — the CELL was sized to
  the unit card. Measured at every batch size: unit `150×150`, item `150×150`, `match=true`.
- **Item cells are cloned FRESH from the shared master on every show**, deliberately not baked in
  at build time — that is exactly what produced `Kit_ItemHoverCard`'s known stale-master PENDING.
- **No UI is generated in scripts.** Every cell is a clone of a real designed instance, and every
  metric is read from one: `UIGridLayout.CellSize`/`CellPadding`/`FillDirectionMaxCells`,
  `UIPadding`, `RewardsFrame:GetAttribute("MaxVisibleRows")` (3),
  `ObtainRewardsGUI:GetAttribute("InputDeadSeconds")` (0.35). Retune spacing in Studio, no code change.
- **Container rebuilt** (user-authorised, container only — `UnitTemplate` itself untouched except
  `Visible = false`, which a template requires): `UIListLayout` (wrapping, non-deterministic column
  count) → `UIGridLayout` at 5 cells/row; `UIPadding` 1px → 8px uniform; `AutomaticSize` and
  `AutomaticCanvasSize` turned OFF so the controller owns the formula. `Main` became the
  full-screen click catcher (`Active = true`) and its **0.3% offset was zeroed** — a
  dismiss-anywhere catcher cannot have a gap along the top/left edge.

**Acceptance — every case verified LIVE in Play from a temporary harness, not by reading code.**
Frame sizes are measured `AbsoluteSize`; canvas is measured `AbsoluteCanvasSize` vs
`AbsoluteWindowSize`. All batches MIXED units + items (alternating).

| n | cols | rows | visible | frame | canvasY / window | scrollbar | verdict |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 1 | 166×166 | 166 / 166 | no | **PASS** |
| 3 | **3** | 1 | 1 | **482**×166 | 166 / 166 | no | **PASS** — 3 wide, not 5 with gaps |
| 5 | 5 | 1 | 1 | 798×166 | 166 / 166 | no | **PASS** |
| 6 | 5 | 2 | 2 | 798×**324** | 324 / 324 | no | **PASS** — row 2 grew Y |
| 11 | 5 | 3 | 3 | 798×**482** | 482 / 482 | no | **PASS** — row 3 grew Y, still no bar |
| 15 | 5 | 3 | 3 | 798×482 | 482 / 482 | no | **PASS** |
| 20 | 5 | **4** | 3 | 806×**482** | **640** / 482 | **yes** | **PASS** — Y FROZEN, bar appeared |

- **Rows 1→3 grow, row 4 does not:** height went 166 → 324 → 482 and then **stayed 482** at n=20
  while `rows` went 3 → 4. Width grew by 8px (798 → 806) purely because the scrollbar took its inset.
- **`CanvasSize` still covers every row:** at n=20 canvas 640 vs window 482; scrolled to the end,
  the last cell's bottom measured **599** against a frame bottom of **607** — fully visible.
- **Click-anywhere dismissal + dead period: PASS.** Dismissing 0.05s after open left the popup
  OPEN; dismissing at 0.65s CLOSED it. Both went through the same `dismiss()` the click path uses.
- **Queueing, not merging: PASS.** Three batches fired back to back (2, then 7 and 4 while open)
  showed **2 → 7 → 4 cells in order**, then closed on the third dismiss. `Show` is safe to call
  while a popup is up.
- **Unknown id: PASS.** `NotInCatalog_XYZ` rendered as an item cell beside a real Archer.

**Decisions stated plainly, per the session brief:**

1. **The adopted unit card stays LOBBY-LOCAL — NOT promoted to shared canon, no manifest entry.**
   The reveal screen is Lobby-only by user decision, so promoting it would add a 25th
   drift-controlled entry plus a permanent mirror obligation into a Place with no consumer.
   ADR-0007's own logic says the component gets built when a real consumer needs it — promote on
   the SECOND consumer (the unit index), which is also the moment to settle `Kit_UnitIcon`.
2. **`Kit_UnitIcon` was NOT deleted and NOT adopted — it stays PARKED alongside the shipped card.**
   ADR-0007 stands. The user asked for it to be kept and it is untouched (`24281a2b`, unchanged).

**Notes for whoever is next:**

- **The harness is DELETED** (`StarterPlayerScripts.ObtainRewardsHarness`), no stray `Reward_` cells
  remain in the Edit datamodel, and every `Dev*` attribute is OFF. `DevDismiss` is a *hook* on the
  controller, not a stored attribute — it does nothing unless something sets it.
- `MouseButton1` still cannot be fired from tooling, which is why `DevDismiss` exists at all; it
  routes through the real `dismiss()` so the dead-period check is genuinely exercised. The one
  thing NOT proven by machine is that a literal mouse click lands — same limitation as the hotbar
  hover trigger PENDING. One manual click closes it.
- `UISizeConstraint` on `RewardsFrame` is 900×600, which clears the 806×482 a full 5×3 grid needs.
  If `CellSize` is ever raised, raise that too — and note `UnitTemplate`'s own 150×150
  `UISizeConstraint` would then fight the grid. That is the one coupling in the design.

- **PENDINGs:** **TWO NEW, both AD-Integration.** (1) mirror `Kit_ItemIcon` Lobby → Game and set
  `deployed.Game = c5e81264`; **until then the GAME reads 23/24 and that is EXPECTED, not new
  drift.** (2) retire `UIKitRewardPopup` + `Kit_RewardPopup` (24 → 22) — now UNBLOCKED, since a
  working replacement exists. Best done in one session; both touch the Game's kit. Untouched:
  hotbar hover trigger, `Kit_ItemHoverCard` master/clone, `Data.Items` writer, max-level XP loss,
  teleport v2 live loop + republish (USER).
- **USER must republish the LOBBY place** — all of B1 is Studio canon, not git.

## 2026-08-08 [game] B0 — PLACEMENT IS uuid-ADDRESSED. The last Phase A correctness defect is closed.

Drift **24/24 GREEN** at bootstrap and at landing, byte-identical both times — including
`UIKitHotbar=616b06bf`, which is the number that proves the shared controller was never touched.
Integration gate: **no Integration needed**, and it held. Verified with a temporary real Script
(`SSS.Server.B0Placement`, since DELETED) plus a client-VM invoke of the real remote — never
`execute_luau` for service state.

**The defect:** `RequestPlace` carried only a `towerId`, and `PlacementValidator` resolved it via
`LoadoutValidator.FindEntry`, which returned the FIRST loadout entry with that TowerId. A player
bringing TWO instances of one tower therefore had only the first ever enter the match — its
MetaLevel/StatRolls/Ascension drove every copy placed — while `RewardCalculator` granted BOTH
entries the same aggregate XP. Fixed before gacha because gacha makes duplicates routine.

**Two findings that made this smaller and stranger than the plan assumed:**

1. **Step 1 was already done at the wire level.** `ReplicationBridge` fires the whole validated
   `LoadoutEntry`, which has carried `Uuid` (and `StatRolls`, `Ascension`) since schema v2. The
   "`LoadoutAssigned` carries TowerId/MetaLevel/Trait only" comment in `HotbarController` — and the
   PENDING that quoted it — had been **stale for seven sessions**. The real gap was that the
   controller *dropped* the uuid when calling `PlacementController.Start`. Comments corrected.
2. **`UIKit.Hotbar` needed no change, verified rather than hoped.** Line 271 passes the raw entry
   table straight to `OnActivated`; `setData` stores it without copying or stripping; `paint()`
   only reads `TowerId`/`Trait`/`Tier`. So the Game reads `entry.Uuid` with zero edits to shared
   canon. **This is why B0 required no Integration session.**

**The change, in the mandated order:**

- `LoadoutValidator.FindEntry(loadout, towerId)` → **`FindByUuid(loadout, uuid)`**. One caller.
- `RequestPlace` now takes `(uuid, position)`. The uuid is a REQUEST, never truth — resolved
  against the player's OWN validated loadout, with TowerId read off the server's entry. This is
  strictly **safer** than before: there is no longer any client-supplied field a forged request
  could use to pick which of the player's instances to impersonate.
- Placement limits count **per uuid** (`TowerManager.CountPlayerTowersOfUnit`). The limit VALUE
  still comes from config + trait; only the count changed.
- `TowerController.Uuid` + a `UnitUuid` attribute carry the instance into combat;
  `AttackResolver.DamageDealt` and `StatusEffectManager.EffectTicked` both emit it (so a Burn's DoT
  lands on the instance that lit it).
- `MatchStatsTracker.Towers` is **keyed by uuid**, with TowerId kept as a display field.
- `RewardCalculator` reads per-uuid damage/kills, and **A8's `killsCredited` first-entry rule is
  DELETED** — it was correct only while placement was towerId-addressed.
- Client: `HotbarController` passes `entry.Uuid` through; `PlacementController` carries and sends
  it, and refuses to fire a request with no uuid rather than sending one that can only be rejected.
  `PlacementCountsChanged` is keyed by uuid (a TowerId key would grey out BOTH slots when one capped).

**Acceptance — two full Stage1_Act1 runs with TWO Archers in one loadout (ML100/rolls .95 vs
ML5/rolls .05) and a Necromancer as the single-instance control. All PASS.**

| Test | Verdict | Evidence (run 1) |
| --- | --- | --- |
| Both instances validate + place | **PASS** | server saw `Archer c1baf563 ML100` AND `Archer 57a45c23 ML5` as separate slots; both PLACED |
| Each resolves stats from ITS OWN uuid | **PASS** | `DMG 306.45 / RNG 34.48 / SPA 4.478` vs `DMG 14.27 / RNG 19.18 / SPA 6.403` — a 21× damage gap. Pre-B0 both would have read 306.45 |
| Limits count per uuid | **PASS** | STRONG (Godly) `1/1 canPlaceMore=false` while WEAK `1/4 canPlaceMore=true` — capping one did NOT cap the other, and the two even carry *different limits* because they carry different traits |
| Each uuid earns from its own work | **PASS** | kills **215 / 6 / 60**, every one matching `MatchStatsTracker`; XP `0 / +84 / +615`; worthiness `4.30 / 0.12 / 1.20` = kills × 0.02 exactly. **No double-grant** |
| A8's invariant survives | **PASS** | `sum(PerUnit kills) = 281` vs tracker total `283`; the gap of 2 is `estimateTowerKills`' pre-existing `math.floor` truncation, same as A8 recorded |
| Single-instance unchanged (regression) | **PASS** | Necromancer behaved exactly as at A8/A9 — 60 kills, 1.20 worthiness, +615 XP |

Run 2 independently reproduced all six with different rolls and a shorter match (58 / 1 / 14 kills).

**The remote BINDING was tested separately, because the server function passing is not the same
thing as a player being able to place.** Tests 1–3 call `PlacementValidator.Validate` directly,
which skips the bound remote — and the remote's parameter signature is exactly what B0 changed. So
a third run invoked the real `RequestPlace` from the CLIENT datamodel (invoking a RemoteFunction is
an instance operation, not a module read, so the separate-VM hazard does not apply):

- real WEAK uuid → **`Success=true, TowerId=Archer, Uuid=ad3d4491`** — the instance that was
  unplaceable before B0, placed through the real client path
- bare `"Archer"` (the pre-B0 wire format) → **`NotOwned`** — no silent fallback
- forged uuid → **`NotOwned`** · numeric arg → **blocked by the remote's Validate predicate**

**Notes for whoever is next:**

- `DevSetOwnedTowers` takes a `{ [towerId] = ... }` MAP, so it can only ever seed ONE instance per
  tower. **A duplicate-tower test built on it passes while the bug is fully present** — that is how
  this survived A1–A8. Grant the second instance explicitly with `GrantUnit`.
- `MatchLifecycleSmokeTest` was `Disabled = true` for these runs (same reason) and is **RESTORED to
  false**. All `Dev*` attributes OFF, harness deleted, its `B0_*` scratch attributes cleared.
- Archer STRONG showed `XP 0 → 0` at ML100. That is the **known max-level PENDING** (`ApplyXP`
  discards overflow at `MAX_META_LEVEL`), untouched and not a B0 regression.

- **Contract impact:** NONE. No schema bump, no teleport-payload change, no shared module, no
  template. `Data.Loadout` is still a dense `{ string }` of uuids. **The Lobby is NOT stale** and
  needs no change — nothing it reads or sends moved.
- **PENDINGs:** **CLEARED — placement is not uuid-aware** (deleted from `STATE.md` per ADR-0006;
  this entry is its record). None new. Untouched: max-level XP loss, `Data.Items` writer,
  `ObtainRewardsGUI`/`Kit_UnitIcon` (AD-UI), teleport v2 live loop + republish (USER).
- **USER must republish the GAME place** — all of B0 is Studio canon, not git.

## 2026-08-08 [game] B0 NOT STARTED — Studio MCP was down. Spec'd `ObtainRewardsGUI` to disk instead.

**No code changed in any Place. No drift check was run.** The Roblox Studio MCP server disconnected
before Place binding, so `list_roblox_studios` / `set_active_studio` / `script_read` / `multi_edit` /
`execute_luau` / `start_stop_play` were all unavailable. CLAUDE.md requires Place binding before any
write and a drift check at bootstrap; neither was possible, so **B0 (placement uuid-awareness) was
not attempted** and remains the first Phase B task, untouched. Bootstrap steps 1–4 (disk reads) were
completed: `CLAUDE.md`, `STATE.md`, `places/game/CONTEXT.md`, and the A9 entry below.

Since the session could not touch Studio, it was spent capturing a user request as a proposal —
the documented mechanism for a non-owner (`docs/OWNERSHIP.md` puts StarterGui screens under **AD-UI**,
and this screen is **Lobby**-side, so AD-Game must not build it).

- **NEW `docs/proposals/2026-08-08-obtain-rewards-gui.md`.** The user hand-built
  `StarterGui.ObtainRewardsGUI` in the Lobby. Four decisions taken: (1) it **WINS** —
  `UIKitRewardPopup` + `Kit_RewardPopup` are to be **RETIRED**; (2) Lobby only; (3) ONE grid with
  **MIXED** units + items; (4) its `UnitTemplate` becomes the unit cell, replacing `Kit.UnitIcon`'s
  role. Layout spec recorded in full (5 columns; rows 1–3 expand the frame; row 4+ freezes Y at the
  3-row height and shows a scrollbar; padding and cell metrics read from the designed instances,
  never hardcoded).
- **This fulfils ADR-0007 rather than overriding it.** ADR-0007 parked `Kit_UnitIcon` and said the
  first real Phase B consumer would define the component, and that the USER'S shipping card gets
  lifted into the kit **as-is** with missing fields ADDED to their tree. That consumer has now
  arrived and the user supplied the card. `Kit_UnitIcon` stays PARKED — **still not to be deleted
  unilaterally** — until a session with Studio access can see both trees side by side.
- **Flagged as a SHARED-CANON change, deliberately not folded into the AD-UI build.** Both retirement
  targets are deployed byte-identically in both Places and are drift-controlled, so removing them is
  **AD-Integration** work: re-grep both Places for callers first (as ADR-0004 did), delete in both,
  drop both manifest entries (**24/24 → 22/22**), delete `shared/src/UIKitRewardPopup.luau`, and fix
  the "24 entries" line in `STATE.md`, both `CONTEXT.md`s and `docs/systems/ui-kit.md`. Sequenced
  AFTER the replacement works, so there is never a window with no reveal surface.
- **Two of the three OPEN questions were answered the same session.** ITEM cell = the existing
  `Kit_ItemIcon`, no new template — with a flagged risk: it was designed for the Lobby's Items
  *screen*, so its footprint almost certainly does not match `UnitTemplate`, and a `UIGridLayout`
  forces one `CellSize` on every child, so a mismatch shows up as stretched art rather than as an
  error. Fix by sizing the CELL to `UnitTemplate` and fitting the icon inside it — **never by
  resizing `Kit_ItemIcon`**, which is shared canon in use by a shipping screen. Dismissal =
  click anywhere, and back-to-back grants **QUEUE** rather than merge, so `Show(rewards)` must be
  safe to call while a popup is already up and needs a short input-dead period on open so a fast
  grinder cannot stray-click past a rare pull. **Still OPEN: who calls the screen.**

- **Contract impact:** NONE. No schema, no teleport payload, no shared module, no template —
  nothing in any Place was touched. The Lobby is **NOT** stale.
- **PENDINGs:** the existing "unit-card component" PENDING was **merged** with this one rather than
  added alongside it (`STATE.md` was at 118/120 — the merge keeps it at 118). **B0's placement/uuid
  PENDING is untouched and is still the first Phase B task.**
- **Everything the USER already owed still stands:** republish BOTH Places, and one live run of the
  teleport v2 loop. Since B0 will need its own republish afterwards, doing the live teleport check
  on the CURRENT build first is the cheaper order.

## 2026-08-06 [integration] A9 — §8 re-check. ✅ **PHASE A IS SIGNED OFF.**

Drift **24/24 GREEN in BOTH Places** at bootstrap and at landing. Integration gate: this IS the
Integration session. Verified in-engine with a temporary real Script (`SSS.Server.A9SignoffCheck`,
since DELETED) — **A8's own report was not taken on trust; the counters/worthiness path was
re-observed from scratch.**

**Every §8 item now PASSES.** Full table in `docs/blueprints/phase-a-foundations.md`. What I
verified myself this session:

- **Counters commit, independently reproduced** across three complete Stage1_Act1 runs (15 waves,
  speed 10, all Victories): `Waves +15` per match (60 → 75 → 90 → 105), `Clears +1` and
  `ClearsByStage.Stage1_Act1 +1` **on Victory only**, `Summons +139` on real Necromancer raises.
- **Worthiness is exact.** Archer 198 kills → `3.96`, Necromancer 86 → `1.72` — the harness
  recomputed `WorthinessConfig.Apply(before, kills)` per unit and every one matched to 4 dp.
- **PERSISTENCE, not just accumulation.** Each run's committed totals were read back at the NEXT
  boot's snapshot through a real ProfileStore round trip (`DataStoreState=Access`): predicted
  `Clears 3→4, ClearsByStage 3→4, Waves 60→75, Summons 526→662` and observed exactly that.
- **XP by uuid did not regress under A8's changes** — Necromancer +620, Warchief +60, Meteor +60;
  only loadout units moved.
- **The cross-Place payoff, verified in the Lobby:** A8 wrote `Worthiness` in the GAME place and
  never touched the Lobby, yet `GetUnitViews` now serves real values because the field was already
  in the contract — Archer `1d6c4076` = **3.96** and Necromancer `035673d9` = **1.72**, the exact
  uuids and values the Game committed, read back in the other Place with zero Lobby changes.
- **Lobby still healthy after A7's remote deletion:** 7/7 screens present, all five read remotes
  round-trip `ok=true`, hotbar 6/6 kit-shaped, `GetCollection` absent, no `Dev*` attribute on.

**A harness bug worth recording, because it cost three runs and will bite the next author:**
`Signal:Fire` invokes handlers **SEQUENTIALLY on one thread**, so a `MatchEnded` handler that
YIELDS blocks every later handler — including `MatchEndPresenter`, which is what drives the
reward/counter commit. My first three attempts "observed" the commit arriving ~16s late and
reported all-zero deltas; in fact *my own handler was holding the commit up*. Fixed by
`task.spawn`-ing the body and returning immediately. **Never yield inside a `Signal` handler in
this codebase** unless you intend to delay everyone behind you.

**Judgement call, stated openly — the placement/uuid defect does NOT block sign-off.**
`RequestPlace` carries a towerId and `LoadoutValidator.FindEntry` returns the FIRST matching entry,
so a player bringing two instances of one tower has only the first ever enter the match, and the XP
path grants both the same aggregate. It is real, but: §8 never required multi-instance correctness,
"commits by uuid" is satisfied (the commit IS uuid-keyed and was verified), and §1's "Ripple" never
listed the placement remote — so it is out of Phase A's scope, not a Phase A regression.
**However:** Phase B is gacha, which turns duplicates from an edge case into the normal state of a
player's inventory. **This should be the first thing fixed in Phase B, before banners ship.**
Recorded that way in `STATE.md` and the blueprint rather than left as a generic backlog item.

- **Contract impact:** NONE. No shared module, template or schema touched — drift unchanged at
  **24/24**, so neither Place is stale. Docs-and-verification only.
- **PENDINGs:** the A9 re-check PENDING is CLEARED. Carried: placement/uuid (now flagged as a Phase
  B blocker), max-level XP loss, hotbar hover trigger, `Kit_ItemHoverCard` clone split, `Data.Items`
  writer, `TowerProgressionConfig` promotion, teleport v2 live loop (USER), republish (USER).
- **PHASE A IS COMPLETE.** A1–A9 all landed. Next is **Phase B (gacha)** —
  `docs/blueprints/phases-b-f-meta.md`.

## 2026-08-06 [integration] USER DECISION — `Kit_UnitIcon` PARKED (ADR-0007). Phase A is now unblocked.

**Docs only. No code, no template, no Studio change, no drift impact, nothing to republish for this.**

A7 left one §8 item PARTIAL: the Lobby's Units screen renders screen-local cards rather than
`Kit.UnitIcon` clones, which is why that template has no consumer. Once A8 closed the
counters/worthiness ❌, this was the LAST thing between the project and Phase A sign-off. It was put
to the user rather than decided unilaterally — the template carries a rig and the user had
previously asked for it to be kept.

**The user's decision, four parts (full reasoning in `docs/decisions/ADR-0007-kit-uniticon-parked.md`):**

1. **PARK the template** — not adopted, not deleted, no code change. `Kit_UnitIcon` stays
   drift-controlled canon in both Places. The question moves to **Phase B**, whose gacha summon
   reveal and unit index are the first features that will actually need a unit card and will
   therefore define what the component must do. Designing it now against zero consumers is how you
   get a component that fits nothing.
2. **§8 reads PRAGMATICALLY — the Units screen PASSES.** "Renders through the kit" is satisfied by
   the shared `FilterPanel` and the shared `TierConfig`/`StatGradeConfig`/`UnitStatsCatalog` stack.
   The card exception is RECORDED, not pretended away.
3. **If a shared unit card is ever built, the USER'S design wins.** `Kit_UnitIcon` is explicitly
   NOT the reference: the Units screen's shipping card is lifted into the kit as-is — the same move
   that produced `Kit_HotbarSlot` — and any fields the kit icon has that it lacks (`ShinyBadge`,
   `CostLabel`, `KeyLabel`/`CountLabel`) are **ADDED to the user's tree**, never used as grounds to
   replace it. This is now the standing rule for kit promotion generally, not a one-off.
4. **Collection screen stays OUT OF SCOPE** — it keeps its own `CardTemplate` and adopts a shared
   card only opportunistically under the convert-on-touch rule. Folding two working screens into a
   Phase-A closing task was rejected as unnecessary blast radius.

**Two standing instructions now recorded in the manifest, `ui-kit.md` and ADR-0007:** do NOT delete
`Kit_UnitIcon` without a fresh user decision, and do NOT build a `UIKit.UnitIcon` controller
speculatively — its absence is intentional, and the first real consumer designs it.

- Also corrected a **stale ROADMAP claim** that `Kit_UnitIcon` "is the Game hotbar's slot". It was,
  until the shared-hotbar work replaced it with `Kit_HotbarSlot`; that line had been reading ✅ for a
  fact that stopped being true the same day.
- **Contract impact:** none. Drift unchanged at **24/24** — no hash moved, because nothing was touched.
- **PENDINGs:** the AD-UI "needs a USER decision" PENDING is CLOSED and replaced by a Phase B one.
  **Phase A has no blockers left** — next is a short AD-Integration §8 re-check to sign it off.

## 2026-08-06 [game] A8 — Counters pipeline + Worthiness commit (blueprint §6). **The A7 ❌ is closed.**

Drift **24/24 GREEN** at bootstrap and again at landing — no shared module or template was touched,
so the Lobby is NOT stale. Integration gate: **no Integration needed**, and that held (see
"Contract impact"). Verified by a temporary real Script (`SSS.Server.A8Counters`, since DELETED)
plus `get_console_output` across TWO complete matches — never `execute_luau` for service state.

**What was built (exactly §6, nothing more):**

- **`RS.Configs.Global.WorthinessConfig`** (new, Game-owned, NOT shared canon). `PointsPerKill`,
  `Max = 100`, and a pure `Apply(current, kills)` that clamps AND rounds. **Where it lives was the
  one genuine ambiguity in §6** — it sits next to `TowerProgressionConfig` because it is the same
  kind of thing: a per-unit progression rate the Game computes and the Lobby merely displays. The
  cap lives inside `Apply`, not at the call site, so a future second caller cannot bypass it.
  **Rate 0.02/kill (5,000 kills to cap) — the USER chose this** from four options; retune in that
  one file.
- **`PlayerInventoryService`** — new counters section: `IncrementGlobalCounter`,
  `IncrementStageClears` (its own function because `ClearsByStage` is a nested map a careless
  caller would clobber with a number), `CommitUnitKills` (kills + worthiness in ONE write) and
  `GetCounters` (a deep COPY, same rule as `GetUnit`).
- **`RewardCalculator.GrantForPlayer`** — the match-end commit, beside the existing tower-XP
  commit so both walk the loadout once. `Clears` + `ClearsByStage[stageId]` move **on Victory
  only** — "a defeat is not a clear", and a counter that lies is worse than a missing one. `Waves`
  moves on any outcome.
- **`SummonManager.SpawnForTower`** — `Counters.Global.Summons`, the one LIVE increment, after the
  spawn actually succeeds. A summon is a discrete event with no match-end aggregate to recover it
  from; it is an in-memory `profile.Data` write, not a DataStore call.

**NO SCHEMA BUMP, and none was needed** — `Counters = { Global, PerUnit }` and
`UnitInstance.Worthiness` have existed since v2. `ProfileTemplate` was not opened. **The Lobby was
not touched**: `GetUnitViews` already serves `Worthiness`, so real values appear there for free.

**THE HAZARD A7 FLAGGED — resolved deliberately, and it turned out to be bigger than stated.**
A7 warned that `MatchStatsTracker` keys towers by TowerId, not uuid. True — but **so does
PLACEMENT**: `RequestPlace` carries no uuid at all, and `PlacementValidator` resolves it through
`LoadoutValidator.FindEntry`, which returns the **FIRST** loadout entry matching the TowerId. So
when a player brings two instances of one tower, the second **never enters the match** — every copy
placed already runs on the first instance's MetaLevel/StatRolls/Ascension. Making the tracker
uuid-aware inside A8 would have been building attribution for an identity the runtime never
establishes. **Decision: credit the aggregate to the FIRST loadout entry per TowerId, zero to
later ones.** That is not a compromise — it is what actually happened, and it keeps
`sum(PerUnit kills)` equal to the tracked total instead of inflating it.
**Discovered while doing it (NOT fixed, new PENDING): the XP path does the wrong thing here** —
`RewardCalculator` gives every same-TowerId entry the same aggregate damage/kills, so a duplicate
tower is granted XP twice for one tower's work. Pre-existing, invisible in the single-instance case
A7 tested, and out of A8's scope. Real fix is upstream: uuid on the placement remote → `FindEntry`
by uuid → per-uuid limits → uuid-keyed tracker → drop A8's first-entry rule.

**Acceptance — two complete Stage1_Act1 runs (15 waves, speed 10), PASS/FAIL as observed:**

| Item | Verdict | Evidence |
| --- | --- | --- |
| `Counters.PerUnit[uuid].Kills` commits | **PASS** | Run 1 (Defeat): Archer `e90feb6c` 0→**171**, Necromancer `9c7d5c0b` 0→**66**, Warchief `98db8383` 0→**34**, Meteor `c0903607` 0→**10** |
| deltas match the match's ACTUAL kills | **PASS** | tracker reported 171 / 66 / 34 / 10 for those same towers — every unit printed `<= MATCHES tracker`. Committed total 281 vs 283 player kills; the 2 missing are `estimateTowerKills`' pre-existing `math.floor` truncation across 4 towers |
| `Worthiness` commits, same pass | **PASS** | 171×0.02 = **3.42**, 66×0.02 = **1.32**, 34×0.02 = **0.68**, 10×0.02 = **0.20** — exact |
| Worthiness capped at 100 | **PASS** | contrived: two back-to-back `CommitUnitKills(uuid, 999999)` on a non-loadout Mage → `0.00 → 100.00 → 100.00`. Kills kept accumulating (1,999,998) — only Worthiness is capped, which is the intent |
| `Counters.Global.Waves` | **PASS** | 15 after run 1, **30** after run 2 — accumulates across matches |
| `Counters.Global.Clears` / `ClearsByStage` | **PASS** | run 1 was a Defeat and correctly moved NEITHER; run 2 (Victory) gave `Clears = 1` and `ClearsByStage = { Stage1_Act1 = 1 }` |
| `Counters.Global.Summons` moves on a real raise | **PASS** | Necromancer was in the loadout and actually raised Chargers: **111** after run 1, **255** after run 2 |
| equipped-only XP still correct (must not regress) | **PASS** | only loadout units moved; Mage/Knight/Babaylan stayed 0/0 in both runs until the contrived cap test |

- **Run 1 Defeat** (leaked at wave 15/15, 95,860 dmg, 283 kills) and **run 2 Victory** (15/15,
  144,882 dmg, 285 kills, towers stacked to force a win so the Victory-only branch was exercised
  for real rather than argued for on paper).
- **Bonus:** run 2's BEFORE snapshot read `Summons 111 / Waves 15` — run 1's values, recovered from
  the profile through a real ProfileStore round trip (`DataStoreState=Access`) across two Play
  sessions. The counters persist, not just accumulate in memory.
- **Placement note for future sessions:** towers were placed at **z ≈ −250** beside the real
  `Path_Main`. `AutoPlaceForEndScreenTest`'s z = +12 is ~260 studs off and is why A7's first match
  dealt 0 damage. It is still `ENABLED=false`; its coordinates were left alone.
- **Studio artifact, not a bug:** `DevSetOwnedTowers` mints new uuids every Play, so the dev
  profile's `Counters.PerUnit` accumulates orphan entries from previous runs. Real play has stable
  uuids. Not worth pruning.

- **Contract impact:** **NONE.** No schema bump, no shared module, no template — drift **24/24
  GREEN** in the Game at landing, and the Lobby is untouched and therefore **NOT stale**.
- **PENDINGs:** **NEW — AD-Game: placement is not uuid-aware** (detail in `STATE.md`); it also
  causes duplicate-tower XP double-granting. **CLEARED — A8.** Carried unchanged: `Kit_UnitIcon`
  consumerless (USER decision), max-level XP loss, teleport v2 live loop (USER), republish (USER).
- **Phase A is NOT being declared done here, and that is deliberate.** §6 is done and the counters
  ❌ is closed, but §8's "units screen renders through the kit" is still PARTIAL and resolving it is
  a **USER decision**, not AD-Game's call. Sign-off now waits on exactly that plus a short
  AD-Integration re-check — no AD-Game work is outstanding.
- **USER must republish the Game place** — these are service changes, Studio canon, not git.

## 2026-08-06 [integration] A7 — Phase A acceptance run + `GetCollection` RETIRED. **Phase A is NOT signed off.**

The blueprint §8 acceptance, walked live in BOTH Places. Drift **24/24 GREEN in both** at bootstrap
and again at landing (16 modules + 8 templates, byte-identical). Integration gate: this IS the
Integration session. Verified by a temporary in-engine harness (`SSS.Server.A7Acceptance`, since
DELETED) plus real client→server remote round trips — never `execute_luau` module reads.

**§8 acceptance, item by item:**

| § 8 item | Verdict | Evidence |
| --- | --- | --- |
| Starter picker → unit instance with real rolls | **PASS\*** | `GetStarterOffer` → 4 choices; `ChooseStarterTower` granted uuid `8704564d` with rolls **0.1305 / 0.2418 / 0.3901** — NOT the legacy hardcoded 0.5 |
| Hotbar renders through the kit | **PASS** | 6 slots, all `Kit_HotbarSlot`-shaped, 3 filled with correct tier colours, 3 locked Lv5/20/50, **0 scripts in any viewport** |
| Items screen renders through the kit | **PASS** | 5 cards, all `UIKit.ItemIcon` (`IconImage`+`QtyBadge`), **0 ViewportFrames** |
| Units screen renders through the kit | **PARTIAL** | FilterPanel + TierConfig/StatGrade/UnitStatsCatalog are the kit's; the **CARDS are screen-local, not `Kit.UnitIcon`** |
| Match plays with resolver stats | **PASS** | 7 waves, **46,375 damage**; per-unit resolve, e.g. Knight DMG roll 0.771 → 39.38 vs Mage 0.025 → 26.73 |
| Match end commits **XP** by uuid | **PASS** | Mage `16e224f7` **+358**, Knight `82acb182` **+97**; unequipped units that gained XP: **0** |
| Match end commits **counters** by uuid | **FAIL** | `Counters.Global` EMPTY, `Counters.PerUnit` **0 entries** after a real match |
| Match end commits **worthiness** by uuid | **FAIL** | every unit `Worthiness 0 → 0` |
| Old v1 dev profile migrates cleanly | **PASS** | real ProfileStore round trip on a scratch key: `[DATA] Migrated … 1 step(s): v1 -> v2`, 3/3 towers as uuid instances, `Currency 250 → Currencies.Gold 250`, old `Towers` removed, PlayerXP preserved |
| Drift green in BOTH Places | **PASS** | 24/24 both, at bootstrap and at landing |

\* eligibility was forced by the `DevSimulateFirstJoin` harness (the dev profile owns 8 units), so
the *grant path and rolls* are proven but "a zero-unit profile is offered the picker" is still
inspection-only — it shares the same `isEligible` function and `ProfileTemplate.Template.Units`
ships empty.

- **BONUS, and the strongest result of the session — the EQUIP → LAUNCH → MATCH chain is real.**
  Equipped 3 units in the LOBBY via `SetLoadoutSlot`, stopped, then booted the GAME place: it read
  **the same 3 uuids** out of `Data.Loadout` and started the match from exactly them
  (`Mage 16e224f7`, `Knight 82acb182`, `Archer e0633351`). One shared profile, two Places, no
  auto-loadout fallback. Gold moved 120 → 135 → 150 across the Places as rewards committed.

**Why Phase A is NOT signed off: blueprint §6 (Counters pipeline) was never implemented.** It has
no writer anywhere in either Place — `script_grep` for `Counters` / `Worthiness` returns only the
template definition and the zero-initialisers — and, checking §9, **no session task A1–A7 was ever
assigned to it.** It is a hole in the session plan, not a regression. §8 explicitly requires
counters + worthiness, so A7 cannot sign the phase off. Needs an **A8 [AD-Game]**.

**`GetCollection` RETIRED (ADR-0004) — executed.**

- **Re-grepped BOTH Places FIRST:** zero callers of the remote, zero readers of its fields. The
  only `%.Towers` / `%.Currency` hits were `ProfileTemplate`'s v1→v2 migration (reads OLD profile
  fields) — **left untouched**, as instructed.
- Deleted the handler in `Server.Lobby.LobbyServices` **and** the `RS.Remotes.GetCollection`
  RemoteFunction instance. `RS.Remotes` went 13 → 12.
- **Re-verified all 7 Lobby screens load after the deletion** — Units, Items, Collection,
  StageSelect, Party, Return, StarterChoice: all present, all controllers enabled, **no errors and
  no "Infinite yield" warning** (the failure mode a removed remote actually produces). All five
  read remotes round-tripped `ok=true`. `ReturnScreen` has 0 GuiObjects on a normal boot by design
  (it builds only on a `MatchReturn` payload) — not a fault.
- `GetUnitViews` is now the Lobby's SINGLE profile read path, recorded in the `LobbyServices` header.

**Other findings worth keeping:**

- **A max-meta-level unit LOSES stored XP.** Archer (Lv100 = `MAX_META_LEVEL`) went `XP 400 → 0`
  when it earned defeat XP — `ApplyXP` discards overflow at max level rather than clamping the
  stored value. Cosmetic, but it silently destroys a number the Units screen shows.
- **A Game-place dev seed orphans the Lobby's saved loadout.** `DevSetOwnedTowers` replaces
  `data.Units` wholesale with new uuids, so `Data.Loadout` was holding 2 uuids that resolved to
  nothing; the hotbar logged "2 equipped" while drawing 2 EMPTY slots. It **fails safe** —
  `LoadoutService.clean()` drops unowned uuids on the next write and `PartyService.buildLoadout`
  filters them — so this is a misleading count, not corruption.
- `Data.Items` genuinely empty, confirming the "no writer" note. There IS a latent path
  (`RewardCalculator` → `AddItem`) but it only fires on a **Victory** drop roll, which never landed.
- **§9 A7's "promote kit/config modules into shared/src + manifest" verified, not redone:** 16/16
  modules have `shared/src` files, 8 templates, all 24 `deployed` in both Places.

**Housekeeping settled (both were raised repeatedly):**

- **ADR-0006** — `STATE.md` stays ONE file (the ritual reads it); cap **100 → 120**; a resolved
  PENDING is **deleted**, not struck through. The real cause of the overage was 4 struck-through
  DONE entries (~30 lines) duplicating changelog entries. `CLAUDE.md` updated.
- **`docs/systems/ui-kit.md`** — the kit half of `lobby-ui.md` split out into a Place-neutral doc
  (it serves both Places now); `lobby-ui.md` slimmed to the Lobby's screens.

- **Contract impact:** NONE. No shared module or template changed — drift stays **24/24 GREEN**.
  The `GetCollection` deletion is Lobby-local Studio canon.
- **PENDINGs:** **NEW — A8 [AD-Game]: implement blueprint §6** (counters + worthiness commit).
  Phase A stays OPEN until it lands. Carried: hotbar hover TRIGGER unverified in both Places;
  `Kit_UnitIcon` still consumerless (user decision); teleport v2 live loop (USER).
- **BOTH Places need republishing** — the `GetCollection` deletion is Studio canon.

## 2026-08-06 [integration] Hotbar hover preview RESTORED (a regression I introduced) + dead-template audit

User chose to skip A7 for now and do AD-UI cleanup. The audit turned up something worse than dead
templates: **my `UIKit.Hotbar` rewrite had silently dropped the Lobby hotbar's hover preview.**
The old `HotbarController` popped `Hotbar.Templates.UnitPreviewTemplate` above the hovered slot;
the shared controller never implemented one, so the feature vanished when the hotbar was rebuilt.
The user had explicitly asked for "same hover functions" — this was a loss, not a simplification.

- **Hover preview restored in the SHARED controller**, so both Places get it from one place. It
  clones **`Kit.UnitPreviewTemplate`** — which also gives that template a real runtime consumer for
  the first time (the audit had just flagged it as referenced by nobody).
- Shown **only for a FILLED, UNLOCKED slot** — hovering an empty or locked slot must not pop a card
  full of stale data. Positioned above the slot and clamped to the screen on both edges.
- Fills defensively from whatever the Place's entry carries: the Lobby passes a unitView
  (Name/Tier/Level/Grades), the Game passes a loadout row (TowerId/MetaLevel/Trait). **Grade rows
  are left untouched when absent** rather than blanked, so the Game does not wipe rows the designer
  filled in.
- `UIKitHotbar` `be2873bb` → **`616b06bf`**, deployed to BOTH Places as the same 5-hunk diff;
  hashes verified equal on both sides and `require` OK. Drift **24/24 GREEN**.

**Dead-template audit (user chose "keep, but write down why") — recorded in the manifest:**

- **`Kit_UnitIcon` — NO CONSUMER.** The Game hotbar used it until the move to `Kit_HotbarSlot`;
  the only remaining mention is the *disabled* `Hotbar_RETIRED` script. Kept deliberately (it is
  the blueprint §5 UnitIcon and carries a rig) with a "do not delete without asking" note — twice
  now an "obviously dead" thing here turned out to be worth keeping.
- **`Kit_ItemHoverCard` — no runtime lookup.** `ItemsGUI.HoverPreview` is a clone taken once at
  build time, so **editing the master does not update the deployed screen**. This master/clone
  split is a real sharp edge of template canon — it already caused the stale-size bug at A5.

**Verified live (Play, Lobby):** preview instance created from the shared template, **hidden at
rest**, carrying UnitName / TierName / BaseStatsFrame / ViewportFrame; module hash matches disk in
both Places.

- **NOT verified, stated plainly:** the hover *trigger* itself. `MouseEnter` cannot be fired from
  tooling and `VirtualInputManager` is blocked, so the preview appearing on a real hover is
  code-inspection-only. Worth one manual hover when you next open the Lobby.
- **Known gap:** `Kit.UnitPreviewTemplate` has **no `UnitLevelBar`** (the Lobby's separate
  `UnitsGUI.HoverPreview` does), so the hotbar preview shows name/tier/stats but **not level**. The
  code skips it gracefully rather than printing nil. Add one to that template if level is wanted.
- **Contract impact:** none. **PENDINGs:** none new; A7 still open.

## 2026-08-06 [integration] Hotbar slot BACKGROUND now follows the unit's tier (was stuck red)

User-reported: every hotbar slot's background gradient stayed reddish regardless of which unit sat
in it. Correct — `UIKit.Hotbar.paint()` only ever set the **stroke's** gradient, so `BG`'s own
`UIGradient` kept the colour authored on the template.

- **Root cause, worth remembering:** a slot has **TWO different `UIGradient` instances** —
  `BG.UIGradient` (the background) and `BG.UIStrokeWithGradient.UIGradient` (the border). Setting
  only the second leaves the first frozen at whatever the designer painted. Confirmed in Studio
  that they are genuinely separate instances (`bgGrad == strokeGrad` is **false**).
- Both are now driven from one `tierSeq`, so border and background always agree. Empty and locked
  slots get a neutral grey instead of a stale tier colour.
- The lookup deliberately uses `BG:FindFirstChildOfClass("UIGradient")` — **not** a recursive find,
  which would return the stroke's gradient and make the two fight over one instance. Commented in
  the module so it does not get "simplified" later.
- `UIKitHotbar` `9d8d4b19` → **`be2873bb`**, deployed to BOTH Places as a targeted diff (not a
  re-emit), hashes verified equal on both sides. Drift **24/24 GREEN**.

**Verified live (Play, Lobby):** equipped three units of deliberately different tiers and read the
actual gradient keypoints back — Archer/Common `(205,205,215)`, Mage/Rare `(55,130,255)`,
Necromancer/Mythic `(255,60,60)`, each **exactly** matching `TierConfig` for that tier; empty slots
`(70,66,82)`. **4 distinct colours across 6 slots** (1 would have meant still stuck).

- **Contract impact:** none — shared-module value change only, both Places redeployed together.
- **PENDINGs:** none new. Both Places need republishing.

## 2026-08-06 [game] Game hotbar now IS the Lobby's ScreenGui (user-copied), driven by the shared kit

The user copied `StarterGui.Hotbar` wholesale from the Lobby into the Game place, so both Places
literally hold the same screen. This session made that copy actually work in the Game.

- **Replaced the pasted controller.** The copy brought the LOBBY's `HotbarController` with it,
  which calls `GetUnitViews` and fires `ClientEvents.OpenUnitsWithUuid` — **neither exists in the
  Game place**, so it would have errored on every join. Swapped for a Game controller that runs the
  same shared `UIKit.Hotbar` but whose `OnActivated` starts **placement**.
- **Retired the old hotbar script.** `StarterPlayerScripts.Client.UI.Hotbar` was still enabled and
  looked for a `Container` that the pasted ScreenGui does not have. Worse, both it and the new
  controller bind keys **1-6**, so every keypress would have fired placement twice. Disabled and
  renamed `Hotbar_RETIRED_2026-08-06` rather than deleted, so it is recoverable.
- **Controller now lives inside the ScreenGui**, mirroring the Lobby, so the two Places are
  structured the same way as well as looking the same.
- The pasted `Slot1..Slot6` are replaced at runtime by `Kit.HotbarSlot` clones. Intentional: the
  hand-made slots have only `BG / TraitIcon / ViewportFrame` and **lack the `LockOverlay` and
  `SlotNumber`** the kit slot carries. Rebuilding from the kit is what guarantees both Places draw
  the same thing — and restyling `Kit.HotbarSlot` still changes both at once.

**Verified live (Play, Game, place-asserted):** exactly **6 slots** · 5 real models (Archer,
Necromancer, Warchief, Farm, Meteor) · slot 6 EMPTY · **every slot has the lock part** (kit clones,
not the pasted ones) · 0 scripts in any viewport · **only ONE controller live** (retired script
present and `Disabled=true`, no stray `Hotbar` script) · `[Hotbar] Initialized (GAME, shared
UIKit.Hotbar on the copied Lobby design)` · no errors.

- **CORRECTION (same day).** This entry originally claimed the old Game hotbar was gone. **That was
  wrong.** It is present as **`"Hotbar - old"`** (spaces + dash); the earlier check searched for the
  literal string `"Hotbar Old"`, found nothing, and reported it missing far too confidently. The
  user's rename did stick and their old design was never lost. Lesson: when verifying a rename,
  LIST the children — never probe a guessed name and treat absence as proof.
  It was left `Enabled=true` (harmless — `Container` held only a `UIListLayout` and `SlotTemplate`
  is `Visible=false`, so nothing rendered) and is now **`Enabled=false`, kept as a backup**, with
  `RetiredOn` / `RetiredReason` attributes so a later session knows why it is off.
- **Contract impact:** none. No shared module or template changed — drift stays **24/24 GREEN**.
- **PENDINGs:** none new. Next is **A7 [AD-Integration]**. Both Places need republishing.

## 2026-08-06 [integration] Both hotbars are now ONE component — same look, different action (drift 24/24)

Finishes the user's request: the Lobby and Game hotbars are the same shared component with the
same slot design, hover and animation; only the click behaviour differs. Drift **24/24 GREEN in
both Places** (16 modules + 8 templates).

- **`Kit_HotbarSlot` `8c562d59` deployed to the Game** — the user's copy landed **exactly**, hash
  matched first try, and **0 scripts inside** (the broken legacy per-slot script did not ride
  along). `UIKitHotbar` `9d8d4b19` deployed alongside it; both `deployed.Game` filled in.
- **Game hotbar rebuilt on `UIKit.Hotbar`.** It previously used `Kit.UnitIcon` with its own logic,
  which is exactly why the two hotbars looked different. Now both clone the same
  `Kit.HotbarSlot`, so restyling that one template changes both.
- **Game action = start placement**; Lobby action = open the Units screen on that unit. That single
  `OnActivated` callback is the only difference between the two hotbars.
- Affordability / placement-limit feedback preserved, still distinguishing the two failure reasons
  by colour (at-limit vs too-poor), now layered on top of the shared slot rather than replacing it.

- **DESIGN CALL — locks are a LOBBY concern, and the Game shows none.** You equip in the Lobby, not
  mid-match, so a "Lv 5" padlock on a match hotbar is noise the player cannot act on. The Game also
  genuinely has no `PlayerLevel` to hand — `LoadoutAssigned` carries TowerId/MetaLevel/Trait only.
  So in-match, slots the player did not bring render **EMPTY, not LOCKED**. Wiring real locks there
  would need the server to send `PlayerLevel`, which is an AD-Game payload change, not a UI fix —
  recorded in the module header rather than faked with a guess.

**Verified live (Play, Game place, place-asserted):** exactly **6 slots** drawn · 5 units with
their real models (Archer, Necromancer, Warchief, Farm, Meteor) · **slot 6 EMPTY, not locked**, as
designed · **0 scripts inside any viewport** · `[Hotbar] 5 unit(s) on the shared kit hotbar
(6 slots drawn)` · `UIKit.Hotbar` byte-identical to the Lobby's (7999) and requires cleanly ·
`[DIAG] UIKitBootstrap: 6 'UIKitButton' button(s)` · no errors, match booted normally.

- **Contract impact:** none. Drift surface unchanged at 24 entries; the two pending Game deploys
  are now filled.
- **PENDINGs:** hotbar work COMPLETE both Places. Next is **A7 [AD-Integration]** — Phase A
  acceptance + retire `GetCollection`. Both Places need republishing (Studio canon).

## 2026-08-06 [lobby] Shared hotbar: one component, both Places — Lobby half wired and verified

Second half of the equipping work. **Lobby is done; the GAME half is blocked on the user copying
`Kit_HotbarSlot` into that Place** (its `deployed.Game` is `null`, and so is `UIKitHotbar`'s).
User confirmed both Places republished and all commits pushed before this session.

- **`UIKitHotbar` `9d8d4b19`** (new shared controller) — ONE hotbar so both Places look and feel
  identical: same slot design, hover, press animation, and locked/empty states. A Place supplies
  only `OnActivated`. That is the whole point of the user's request ("same animation and structure
  and hover functions", different action).
- **Always draws 6 slots**, never hides one. Three states: **FILLED** (model in viewport, tier
  border, trait dot) · **EMPTY** (viewport cleared, per-unit details hidden — deliberately not left
  showing stale data) · **LOCKED** (dark overlay + lock + "Lv N", and genuinely not clickable, not
  just visually dimmed).
- **Lobby action wired:** click or key 1-6 fires `ClientEvents.OpenUnitsWithUuid`, and
  `UnitsController` opens the Units screen focused on that unit. An **empty** slot fires with `nil`
  and opens Units unselected, so the click always goes somewhere useful (user decision).
- Slot models come from the loadout the server now actually saves, so the hotbar reflects real
  equipping rather than the old auto-loadout guess.

**Verified live (Play, Lobby):** exactly **6 slots** · slots 1-3 unlocked, **4/5/6 locked showing
"Lv 5" / "Lv 20" / "Lv 50" with `Active=false`** (really unclickable) · equipping two units filled
slots 1 and 2 with models · firing for Mage, Archer and Necromancer each selected the right unit ·
closing the screen and firing again re-opened it on the right unit.

- **Honest note on the first test run:** an early reading showed the wrong unit selected. Re-testing
  against a settled profile showed all four selections correct, including the closed→open path. It
  was a race in the *test* (two equip calls landing at the same instant as the fire), not a bug in
  the controller — recorded as re-verified rather than as a fix, because nothing was changed.
- **Contract impact:** none. Drift surface 23 → 24 entries; **two await the Game deploy.**
- **PENDINGs:** user copies `Kit_HotbarSlot` (`8c562d59`) into the Game place; then `UIKitHotbar`
  deploys there and the Game hotbar gets rebuilt on it with placement as its action.

## 2026-08-06 [lobby] EQUIPPING EXISTS — `Data.Loadout` finally has a writer; shared slot template + unlock config

New feature, NOT in the Phase A blueprint. User asked for a matching hotbar in both Places with
different actions, plus real equipping; they chose to do it before A7 and authorised AD-UI to write
the AD-Lobby server half. **This is a checkpoint — the two hotbar controllers are NOT built yet.**

- **`Server.Lobby.LoadoutService` — the FIRST EVER writer of `Data.Loadout`.** Since A1 the field
  was created empty by the template, set empty by the migration, and read by everyone: which is
  precisely why `Equipped` was permanently `false` and every launch fell back to auto-loadout.
  `SetLoadoutSlot(slotIndex, uuid?)` re-checks everything server-side — profile loaded, slot within
  `MaxSlots`, slot unlocked at the player's CURRENT level, uuid actually owned, no duplicate (moving
  a unit vacates its old slot). AD-Lobby canon, written by AD-UI with the user's authorisation.
- **CAUGHT BEFORE SHIPPING — a silent contract break.** The first draft stored slots as a
  fixed-length array with `false` for empty. `Data.Loadout` is a **schema-v2 contract field
  documented as `{ string }`** (a dense uuid list) and **the Game's match launcher reads it**, so
  writing `false` into it could have broken starting a match — live. Rewritten to only ever write a
  dense uuid list, with a header explaining why and saying "do NOT just write false into the array".
  **Consequence, accepted by the user:** slots fill LEFT TO RIGHT, no gaps. True fixed positions
  need a schema bump + migration under AD-Game's contract protocol — logged, not smuggled in.
- **`LoadoutConfig` `5ac9b8c0`** (new shared module, 15th): `MaxSlots = 6`,
  `SlotUnlockLevel = {1,1,1,5,20,50}`, plus `UnlockedSlots` / `IsSlotUnlocked` / `RequiredLevel`.
  SHARED because both Places must agree on how many slots exist — a Place-local copy is exactly how
  two hotbars end up disagreeing. Deployed to BOTH Places, verified Lv1→3, Lv5→4, Lv20→5, Lv50→6.
- **`Kit_HotbarSlot` `8c562d59`** — the **user's own Lobby slot design**, lifted into the kit so
  both Places draw an identical slot (their design is the source of truth, per their instruction).
  Added `LockOverlay` (dark + lock icon + "Lv N") and `SlotNumber`. **Lobby only so far — the Game
  deploy is the user's copy/paste step**, which is why its `deployed.Game` is `null`.
- **Fixed a live bug found on the way:** all 6 Lobby hotbar slots still contained
  `Unit/ItemIconTemplateLocalScript`, the script with the `ocal Preview` typo on line 30. It was
  removed from the kit template at A5 but never from the live slots, so it had been throwing 6×
  on every Lobby load ever since. **8 stale scripts stripped.**

**Verified live (Play, Lobby, real remote calls — not `execute_luau` module reads):**
equip slot 1 → ok, 1 equipped · equip slot 2 → ok, 2 equipped · re-equip the SAME unit into another
slot → **moves it, 0 duplicates** · unowned uuid → `not_owned` · slot 99 → `bad_slot` · slot 4 at
level 1 → `slot_locked` (need Lv5, have 1) · clear → ok ·
**`GetUnitViews` now reports `Equipped=true` (Farm, Knight) — the first time that flag has ever
been true in this project.**

- **Contract impact:** none — `Data.Loadout` keeps its documented `{ string }` shape. Drift surface
  21 → 23 entries (15 modules + 8 templates).
- **PENDINGs:** `Kit_HotbarSlot` needs the user's copy into the Game place. Then the shared
  `UIKit.Hotbar` controller + wiring both Places (Lobby: open Units with that unit selected;
  Game: start placement). The long-standing "`Data.Loadout` has no writer" PENDING is **CLEARED**.

## 2026-08-06 [integration] A6 COMPLETE — RewardPopup (shared) + CurrencyBar (Lobby-local); drift 21/21

Blueprint §9 A6's last two items, finishing the phase. Drift **21/21 GREEN in BOTH Places** at
landing. Integration gate: **No Integration needed — proceeding** (A7 is the Integration session).

- **`Kit_RewardPopup` `e11a5bf3` + `UIKitRewardPopup` `82aec138`** — shared canon, both Places.
  Dark `Overlay` (clicking it closes) + `Panel` with `Title`/`Subtitle` + `Grid` +
  `RewardItemTemplate` + a kit-tagged `CloseButton`, per blueprint §5.
  **Rewards are addressed by CATALOG ID**, so callers supply no art or naming: name, tier and icon
  all resolve through the shared `ItemCatalog` + `TierConfig`, same as every other kit card.
- **Deliberate robustness:** an id that is NOT in the catalog still renders (falls back to the id
  itself, tier Common) instead of erroring. A reward the player actually earned must never fail to
  display because a catalog entry was missed — the popup degrades, it does not vanish.
- **`CurrencyBar` — built LOBBY-LOCAL, not shared.** Per the user's "Lobby only" decision, and
  because putting a single-Place widget under drift control would cost a cross-Place sync forever
  for something the Game place never renders. `StarterGui.HUD.Top.CurrencyBar` +
  `CurrencyBarController`; the module header says explicitly to promote it into the Kit the day the
  Game place wants one. Consistent with the same call made for `UIKit.UnitIcon` last session.
- **CurrencyBar refresh is deliberately one-shot on join** — nothing in the Lobby SPENDS Gold or
  Silver yet, so there is no change event to subscribe to. The header says to wire a RemoteEvent
  when a shop or gacha lands, and explicitly says **not to poll**.
- Amounts abbreviate (`12.3K`, `1.2M`) — a currency bar is glanced at, not audited.

**Verified live (Play, both Places, place-asserted):**

- **RewardPopup (Game):** 5 cards from deliberately MIXED input — table form, bare-string form,
  a tower id, and **an id that does not exist in the catalog**. All 5 rendered:
  `Banner Ticket/x2 | Gold/x250 | Necromancer/x1 | NotARealThing/x7 | Silver/x1`. Title/subtitle
  set, **no stray `RewardItemTemplate` left in the Grid**, `hide()` works, `destroy()` clean.
- **CurrencyBar (Lobby):** 2 pills in order, `Gold=0 Silver=0` **cross-checked against the server
  view-model** (`GetUnitViews.Currencies`), icons set, no stray `CurrencyTemplate`.
- **Kit intact after all changes:** `Button, FilterPanel, ItemHoverCard, ItemIcon, RewardPopup,
  UnitIcon, UnitPreviewTemplate`; all four shared controllers `require` cleanly in both Places.
- **`CurrencyBar` confirmed ABSENT from the Game place** — it is Lobby-local by design, not an
  oversight.

- **Contract impact:** none. Drift surface 19 → 21 entries (14 modules + 7 templates).
- **A6 IS NOW COMPLETE:** Lobby stat numbers (2026-08-06) · Game hotbar on the kit (2026-08-06) ·
  RewardPopup · CurrencyBar. Next is **A7 [AD-Integration]**: full Phase A acceptance (blueprint
  §8) + retire `GetCollection` (ADR-0004).
- **PENDINGs:** A6 cleared. **Both Places need republishing** — all of this is Studio canon.
  Two dead templates still awaiting a call: `StarterGui.Hotbar.SlotTemplate` (Game) and the
  Lobby's `UnitsGUI` slot design, neither deleted unilaterally.

## 2026-08-06 [game] A6: Game hotbar rebuilt on the shared kit + `Kit_UnitIcon` formalised (drift 19/19)

Blueprint §9 A6, Game half — the hotbar. Bootstrap drift GREEN; **19/19 GREEN in both Places** at
landing. Integration gate: **No Integration needed — proceeding** (A7 is the Integration session).

- **`Kit.Unit/ItemIconTemplate` → `Kit.UnitIcon`**, formalised as the blueprint §5 UnitIcon and
  finally given a job. Added `LevelBadge`, `CostLabel`, `NameLabel`, `ShinyBadge` (hidden) and
  `KeyLabel`/`CountLabel` (hidden by default — the hotbar turns those two on; other consumers
  leave them off, per the kit's degrade-gracefully convention). Now **under drift control** as
  `Kit_UnitIcon` `24281a2b`, 19th manifest entry.
- **Built by running ONE identical deterministic script in BOTH Places, then hash-matching** —
  no copy/paste needed. The base tree was verified identical first (`be620746`, 268 descendants in
  both) so the transform started from the same place. This is now recorded in `templatesNote` as a
  second sanctioned way to deploy a template alongside Studio copy/paste.
- **Hotbar (`StarterPlayerScripts.Client.UI.Hotbar`) rebuilt on the kit:** clones `Kit.UnitIcon`
  instead of the Place-local text-only `SlotTemplate`, and behaviour comes from `UIKit.Button`
  instead of hand-rolled styling. Slots now show the **real per-tower model** from
  `RS.TowerModels` in the viewport (the Game place has all 8; the Lobby only has a placeholder).
- **BORDER now encodes UNIT TIER** (user decision) via shared `ItemCatalog.GetTier` +
  `TierConfig.seamlessSequence`, so a tower reads identically here and on the Lobby's screens,
  multi-colour Mythic/Secret included.
- **The trait was NOT dropped in the process.** The border used to encode **trait rarity** — a
  different axis from unit tier, and swapping one for the other naively would have silently
  destroyed information mid-match. The trait moved to the corner `TraitIcon`, tinted by rarity and
  shown only when the unit actually has one. `TRAIT_RARITY_COLORS` stays a local table **on
  purpose** (there is no shared config for trait rarity) with a comment saying not to "unify" it.
- **Viewport rigs are stripped of scripts on clone** — a display rig must not run code inside a
  ViewportFrame. Verified 0 `LuaSourceContainer`s inside every slot's model.
- The affordability/limit greying is preserved, including its two distinct failure colours, and
  now also drives `UIKit.Button.setEnabled`.

**Verified live (Play, Game place, place-asserted):** 5 slots built from `Kit.UnitIcon` ·
`[Hotbar] built 5 slot(s) on the shared kit` · keys 1–5 · names incl. the `DisplayName` override
("Meteor Mage") · costs $100–$400 · levels · counts `0/1`…`0/6` · tiers Common/Rare/Legendary/
Mythic correct · **real models loaded** (Archer, Necromancer, Warchief, Farm, Meteor) ·
**0 scripts inside any viewport** · trait dot visible only on the one unit that has a trait ·
`[DIAG] UIKitBootstrap: 5 'UIKitButton' button(s)` · no errors, match booted normally.

- **SCOPE — deliberately NOT done this session:** `RewardPopup` and `CurrencyBar` (blueprint §9
  A6's other two items). Each new shared component needs authoring + promotion + cross-Place sync
  + verification; batching four into one session would have made the verification thin. Decisions
  already taken for them: RewardPopup = a NEW reusable component, MatchEnd's working rewards list
  left alone; CurrencyBar = **Lobby only** (mid-match the player cares about Cash, which
  `MatchHUD.TopRight` already shows).
- **`StarterGui.Hotbar.SlotTemplate` is now DEAD** (zero readers) but deliberately NOT deleted —
  same call as `Unit/ItemIconTemplate`: it may be a design worth keeping, and silently binning a
  user's design is worse than flagging it. Decide it alongside `RewardPopup`.
- **Contract impact:** none — no schema, teleport or module change. Drift surface 18 → 19 entries.
- **PENDINGs:** A6's hotbar item done. Remaining A6: `RewardPopup` + `CurrencyBar`. **Both Places
  need republishing** — `Kit.UnitIcon` changed in both and the Game hotbar is Studio canon.

## 2026-08-06 [integration] UI kit promoted to shared canon — 4 controllers + 5 templates, drift 18/18 GREEN in both Places

AD-UI, spanning BOTH Places (the promotion is inherently cross-Place, so this is logged as an
integration-shaped landing). Clears the A6 blocker raised earlier today. Bootstrap drift GREEN in
both; **18/18 GREEN in both at landing.**

- **Controllers → `shared/src` + manifest** (`kind: "module"`, owner `ui`): `UIKitButton`
  `4968d8c3`, `UIKitItemIcon` `b717ebe9`, `UIKitFilterPanel` `72b49660`, `UIKitBootstrap`
  `f930ff7b`. `UIKitBootstrap` is a **LocalScript**, not a ModuleScript — still hashed as source,
  and without it in a Place every `UIKitButton`-tagged button is inert, so it belongs in the kit.
- **Templates → manifest** (`kind: "template"`, no `shared/src` file — the INSTANCE is the canon,
  ADR-0005): `Kit_Button` `812d0780`, `Kit_ItemIcon` `ee1ccd33`, `Kit_ItemHoverCard` `0c9d7818`,
  `Kit_FilterPanel` `0170b0e9`, `Kit_UnitPreviewTemplate` `55e17da8`. `TEMPLATES` uncommented in
  `tools/hash_shared.luau` **in this same session**, as the manifest note required — the tool and
  the manifest must never disagree.
- **The 4 controller files were transcribed into `shared/src` and proven byte-exact by hash**
  (12505/8430/7766/1554 bytes, tab counts included) rather than assumed correct.
- **Templates were COPIED, never rebuilt** (`tools/checklists.md`): `:Clone()` cannot cross
  datamodels, so the user did one Studio copy/paste of `RS.UITemplates`, `RS.Shared.UIKit` and
  `StarterPlayerScripts.UIKitBootstrap` from Lobby → Game. All 9 new hashes then matched the Lobby
  **exactly, first try, zero mismatches** — including the 5 `UIKitButton` CollectionService tags,
  which the hash covers and which are the entire wiring mechanism.
- **Independently reproduced AD-Integration's template hashes** from a fresh session before
  copying anything — good evidence the canonical serialisation is stable over time, not just
  within one run.

**Verified at runtime in the GAME place (Play, place-asserted):** `require` succeeds for all three
modules (`ItemIcon` pulls `ItemCatalog` + `TierConfig`, both already shared) ·
`[DIAG] UIKitBootstrap: 5 'UIKitButton' button(s) at start` · `Button.create` OK ·
`ItemIcon.create("BannerTicket", 3)` renders badge `x3` · `FilterPanel.create` builds its group
with 1 toggle · scratch ScreenGui cleaned up · no errors, match booted normally,
`[Test] UnitStatsCatalog OK: 8 towers match live configs` still green.

- **`Kit.Unit/ItemIconTemplate` deliberately left OUT of drift control** — zero code readers (the
  only hits are a stale comment in `HotbarController` and the docs), and it carries a
  268-instance rig inside a ViewportFrame. Recorded in the manifest note and in the tool. A6
  either formalises it as the blueprint §5 `UnitIcon` or deletes it; not binned unilaterally
  because it may be a design the user wants.
- **NEW STANDING RULE:** the kit is shared now, so editing a controller **or a template** in one
  Place only is drift. Change → re-hash → copy → update the manifest.
- **Also corrected `places/game/CONTEXT.md`** — it was `last-verified 2026-08-01` and wrong in
  three ways (publish still listed BLOCKING, Lobby starter grant still described as writing 0.5,
  `UnitStatsCatalog` still "Game-only"). Flagged last session, unfixed since; a chat bootstrapping
  off it would start with three false beliefs. AD-Game's other content left untouched and the edit
  is annotated in the file header.
- **Contract impact:** none — no save-schema or teleport change. The drift SURFACE grew from 9 to
  18 entries, which is the point.
- **PENDINGs:** kit-promotion PENDING **CLEARED**. A6's Game half is now unblocked. **Both Places
  need republishing** — the kit is Studio canon in both and not in git.

## 2026-08-06 [integration] Drift tooling now hashes UI templates (instance trees) — ADR-0005; A6's blocker cleared

Executes the blocking PENDING from `docs/proposals/2026-08-06-kit-promotion-blocks-a6.md`
(user decision: option B, fix the tooling before promoting the kit). **Tooling only — no game
code, no shared module, no Place behaviour changed.** Drift measured 9/9 GREEN in BOTH Places at
bootstrap AND after landing; both Places left byte-identical (every probe reverted, verified).

- **`tools/hash_shared.luau` gained a TEMPLATE half.** GuiObject subtrees are serialised to a
  canonical string and hashed with the same `fnv1a32`. Format (ADR-0005): one line per instance,
  `depth|ClassName|Name|props|{attributes}|[tags]`; properties from a single by-NAME whitelist,
  `pcall`-read and sorted; children serialised recursively then **sorted by their serialised
  text** so Studio's child order is irrelevant; numbers at `%.4f` and Color3 as 0–255 ints so
  float round-tripping cannot flip a hash. Template hashes print with a trailing `*`.
- **Attributes and CollectionService tags are hashed** — the kit is attribute-driven
  (`HoverScale`, `HoverStrokeColor`, …) and the `UIKitButton` tag is what wires a button to the
  kit at all, so both carry real design intent.
- **ViewportFrame 3D contents are deliberately excluded.** The kit's viewports hold display rigs
  (Humanoid, MeshParts, 112 Attachments, 150 Vector3Values — **679 instances across the kit, vs
  167 once excluded**). Those rigs are AD-TowerModels canon, swapped at runtime by the
  controllers; hashing them would make UI drift trip on every unrelated rig change. The
  ViewportFrame's own properties are hashed.
- **Module hashing is untouched** — every historical module hash stays valid.

**Verified in Studio (Lobby; every probe reverted, final baseline re-matched):** re-run stable ·
`Size` +1px moves the hash · a `UIStroke.Color` nested deep in the tree moves it · adding an
attribute moves it · adding a tag moves it · **reparenting a child does NOT move it** (order
independence, as designed) · renaming a child moves it. **All 9 module hashes matched the manifest
exactly** in both Places (no regression), and the 5 kit templates correctly reported `MISSING` in
the Game place — confirming both that the absent-path works and that the kit really is Lobby-only.
Measured Lobby template hashes: `Button=812d0780` `ItemIcon=ee1ccd33` `ItemHoverCard=0c9d7818`
`FilterPanel=0170b0e9` `UnitPreviewTemplate=55e17da8`.

- **`shared/manifest.json`:** entries now carry `"kind"` (`module` | `template`); the comment
  documents both hashing modes; a `templatesNote` records the measured kit hashes and says AD-UI
  must add the manifest entries AND uncomment `TEMPLATES` in the tool **in the same session**.
  No template entries added yet — nothing is deployed to two Places yet, so there is nothing to
  compare, and a manifest entry that no Place satisfies would just read as permanent drift.
- **`tools/checklists.md`:** new "Deploying a shared TEMPLATE (GuiObject) into a Place" section —
  copy the Instance (never rebuild by hand), hash both sides, re-copy on mismatch rather than
  eyeballing a fix.
- **ADR-0005** documents the format, the whitelist rationale, what is excluded and why, and the
  honest limits: the whitelist IS the contract (an unlisted property is invisible), 3D content is
  unverified by construction, and **adding a property to the whitelist changes every template
  hash at once** — treat that like a schema bump, not drift.
- **Contract impact:** none. No save-schema, teleport, or shared-module change; manifest gained
  metadata only, no hash moved.
- **PENDINGs:** the blocking AD-Integration tooling PENDING is **CLEARED**. AD-UI is unblocked to
  promote the kit (controllers + templates) and then do A6's Game half. Nothing to republish —
  `tools/` never ships to a Place.

## 2026-08-06 [game] A6 Game half BLOCKED — the kit is Lobby-only and the drift tooling cannot hash templates (no code written)

AD-UI bootstrapped into the **Game place** for the first time (place-asserted via
`RS.Configs.Towers` + `SSS.Server.MatchDirector`). Drift **GREEN 9/9** at bootstrap and unchanged
at landing — **nothing was written to the Game place.** Integration gate: **Run an AD-Integration
session BEFORE this task** (see below).

**The blocker.** Blueprint §9 A6 says "hotbar rebuild **on kit** in GAME place", but verified in
Studio: `ReplicatedStorage.UITemplates.Kit` **ABSENT**, `ReplicatedStorage.Shared.UIKit` **ABSENT**,
`StarterPlayerScripts.UIKitBootstrap` **ABSENT**. The kit is Lobby-only (built at A4/A5); the Game
place's UI is entirely Place-local and script-era (`Hotbar.SlotTemplate`, `MatchEnd.RewardRowTemplate`,
`Notifications.CardTemplate`, ...). Blueprint §9 **A7** is the step that promotes the kit to
`shared/src` — **so A6 depends on A7** and the session plan's ordering cannot be executed as written.

**The deeper problem.** `tools/hash_shared.luau` hashes `inst.Source` and returns `MISSING` for
anything that is not a `LuaSourceContainer`. The kit is half ModuleScript controllers (hashable —
`Button`, `ItemIcon`, `FilterPanel`) and half **GuiObject templates** (`Kit.Button`, `Kit.ItemIcon`,
`Kit.ItemHoverCard`, `Kit.FilterPanel`, `Kit.UnitPreviewTemplate` — NOT hashable). Copying templates
into the Game place would create a divergence surface **invisible to the drift check** — the exact
failure class this repo exists to prevent, and one that already bit once at A5 (`ItemsGUI.HoverPreview`
silently kept a stale size after its template was resized; caught only by manual comparison). The
no-UI-in-scripts rule means it cannot be dodged by generating templates from code either.

- **DECISION (user, this session): option B — fix the tooling FIRST.** Extend `hash_shared.luau` to
  serialise + hash GuiObject subtrees so templates become first-class manifest entries; document the
  canonical format in an ADR. The hand-mirrored shortcut was explicitly rejected. Rationale accepted:
  `RewardPopup`, `CurrencyBar`, `UnitHoverCard`, `ViewportPreview` and `NPCPrompt` are all still
  unbuilt and all carry the same problem, so the mechanism is worth fixing once.
- **Sequencing:** AD-Integration (tooling) → AD-UI (promote kit, both halves) → AD-UI (A6 Game half).
- **Contract impact:** none. No code, no shared-module, no manifest change. Drift untouched 9/9.
- **PENDINGs:** TWO new — AD-Integration (hash instance trees, blocking) and AD-UI (promote the kit,
  blocked on it). Analysis in `docs/proposals/2026-08-06-kit-promotion-blocks-a6.md`.
- **Doc staleness spotted (not mine to edit — AD-Game's canon):** `places/game/CONTEXT.md` is
  `last-verified: 2026-08-01` and now wrong in three places — it still lists the USER publish as
  BLOCKING (done 2026-08-06), still says the Lobby's `StarterChoiceService` writes `0.5` (fixed
  2026-08-03), and still says `UnitStatsCatalog` is "Game-deployed only until the Lobby deploys it"
  (the Lobby deployed it at A6b). Worth a pass by AD-Game or the next Integration session.

## 2026-08-06 [lobby] A6 (AD-UI): Units stat NUMBERS filled from UnitStatsCatalog — the `--` slots are gone

Bootstrap drift **GREEN 9/9** (`UnitStatsCatalog=3bb9b140` matching the manifest, deployed by A6b),
unchanged at landing — no shared module touched. Integration gate: **No Integration needed —
proceeding** (Integration is A7).

- **`UnitsController.fillStats` now reads `UnitStatsCatalog.Get(view.TowerId)`** and writes the
  value into each `Stats.BaseStatsFrame.{DMG,RNG,SPA}` row's `TextLabel`, beside the existing
  `Grade` letter. Closes the last Lobby-side piece of A6 (ADR-0003). The `NUMBER_PENDING = "--"`
  constant is gone.
- **`formatStat`** trims decimals (`15`, `20`, `1.4`, `2.5` — never `2.0`) and returns `--` for a
  non-number, so a support tower or an unrecognised towerId **never prints "nil"**.
- **Farm handled by construction:** it has no `DMG`/`SPA` keys at all, so `stats and stats.DMG`
  yields nil → `--`. An unknown towerId makes `Get()` return nil and every slot reads `--`.

**Verified live (Play, dev store, place-asserted reads):**

- Auto-selected Necromancer rendered **DMG=28 (B), RNG=22 (C), SPA=1.1 (D)** — numbers match
  `UnitStatsCatalog` exactly, grades still vary per unit alongside them.
- Formatter checked against all 8 catalog entries: Archer 15/20/6, Knight 35/10/1.4, Mage 30/18/2,
  **Farm --/18/--**, Babaylan 20/22/2.5, Meteor 30/24/1.4, Warchief 25/18/1, Necromancer 28/22/1.1.
  Unknown id → `Get()` nil → `--`.
- **Zero TextLabels anywhere in UnitsGUI render the string "nil".** Harness left OFF.
- NOT verified: only the auto-selected unit was rendered — clicking through all 8 cards needs a
  real mouse (`VirtualInputManager` is blocked for tooling). The towerId→stats lookup is the same
  code path for every card.

**Design note carried into the docs (not a bug):** the number is **per-TOWER, not per-unit**. Two
instances of one tower show identical numbers while their grade letters differ, because the grade
comes from the unit's roll and the number is fixed at the catalog's mid-roll reference. That is
ADR-0003's accepted trade — per-unit numbers would require promoting the Min/Max ranges as well,
which the ADR deliberately rejected. Recorded in `docs/systems/lobby-ui.md` so a future session
does not "fix" it.

- **Contract impact:** none — read-only consumer of an already-deployed shared module. No schema,
  teleport, manifest or drift-surface change.
- **PENDINGs:** the AD-UI number-slot PENDING is CLEARED. Remaining A6 work is the **hotbar rebuild
  in the GAME place** + `RewardPopup` + `CurrencyBar` (blueprint §9). Unchanged: A7 `GetCollection`
  retirement (ADR-0004, unblocked), no writer for `Data.Loadout` or `Data.Items`,
  `TowerProgressionConfig` promotion, Game round-trip test, and the **live teleport v2 e2e run**.

## 2026-08-06 [user] BOTH Places republished — the A-phase is live; blocking PENDING cleared

Bookkeeping entry (no code change). The **USER, BLOCKING** republish PENDING that had been open
since 2026-08-01 is **CLEARED**: the user republished both Places together, so everything that
was Studio-only canon is now the live build — the 4 shared Meta configs, the reconciled
multi-colour `TierConfig`, `GetUnitViews` (+`Items`), the A5 UI (Items screen, FilterPanel,
ItemIcon, rebuilt CollectionScreen, kit consolidated into `RS.UITemplates.Kit`), and A6/A6b
(`UnitStatsCatalog` `3bb9b140` + the Game-side validator, compat fields dropped).

Verified in the Lobby before clearing it (AD-UI, place-asserted):

- Drift **GREEN 9/9**, `UnitStatsCatalog=3bb9b140` matching `shared/manifest.json`
  (`deployed.Lobby` and `deployed.Game` both `3bb9b140`).
- `LobbyServices`: `Towers = towers` and `Currency = currencies.Gold` **absent** (A6b's removal
  really landed), `Items = items` **present** (kept per the A6b review).
- `RS.Remotes.GetCollection` still **present** — correct: ADR-0004 sequences its deletion for A7.

- **Still open (user):** live e2e re-verification of the **teleport v2 loop** (lobby → reserved
  match → return → banner). Publishing v2 is not the same as running it; v2 has only ever been
  Studio-verified, and only v1 was ever live-verified end-to-end (2026-07-18). Worth one run now
  that both Places are on v2, since a `[CONTRACT]` mismatch would be a launch-blocker.
- **Unblocked by this:** the A7 `GetCollection` retirement (ADR-0004) was deliberately sequenced
  after the republish so that publish would not also carry a remote deletion.
- **Next:** AD-UI fills the Units `--` number slots from `UnitStatsCatalog.Get` — the last piece
  of A6. No Integration needed until A7.

## 2026-08-06 [lobby] A6b (AD-Lobby): UnitStatsCatalog deployed (drift 9/9), GetCollection compat fields deleted, GetCollection retirement decided (ADR-0004)

Bootstrap drift **8/9 with `UnitStatsCatalog=MISSING`** exactly as A6 documented; all 8 other
hashes matched the manifest. Integration gate: **No Integration needed — proceeding** (triggers 1
and 2 fire, but the trigger IS this task and deploying a shared module into my own Place is
ordinary owner-chat work — nothing required the Game Place to act).

- **`UnitStatsCatalog` DEPLOYED to the Lobby.** `shared/src/UnitStatsCatalog.luau` written
  VERBATIM (2474 bytes, zero local modifications) to `RS.Configs.Meta.UnitStatsCatalog`; the
  module did not previously exist and was created. Hash came back **`3bb9b140`** — equal to the
  manifest on the first write, no reconciliation needed. `manifest.json` →
  `modules.UnitStatsCatalog.deployed.Lobby = "3bb9b140"`. **Drift re-run: GREEN 9/9 in the Lobby**,
  now byte-identical with the Game in all nine shared modules. The load-bearing validator
  (`UnitStatsCatalogValidate`) was deliberately NOT ported — it is Game canon and the Lobby has no
  tower configs to validate against (noted in the manifest comment so nobody "fixes" the omission).
- **`GetCollection` compat fields DELETED** (proposal `2026-08-03-drop-getcollection-compat.md`).
  Re-grepped BEFORE deleting, as the proposal demands: `result.Towers` / `result.Currency` had
  **zero readers**. The only `%.Towers` / `%.Currency` hits in the Place are `ProfileTemplate`'s
  v1→v2 migration reading the OLD PROFILE fields — a different thing entirely, left untouched.
  Removed the `towers` local, the `prev`/highest-MetaLevel block, both trailing return fields and
  the stale header paragraphs. `GetCollection` still serves `Units`/`Loadout`/`Currencies`/
  `PlayerXP`/`PlayerLevel`.
- **`GetUnitViews.Items` REVIEWED → KEPT AS-IS.** AD-UI's user-authorised addition is the right
  shape: it copies rather than aliasing `data.Items`, is defensive about the field being absent,
  type-checks each count, and is read-only + additive. **No reshape, so `ItemsController` needs no
  change.** Confirmed as AD-Lobby canon in the module header.
- **`GetCollection` fate DECIDED: retire it — `docs/decisions/ADR-0004-retire-getcollection.md`.**
  The re-grep found the remote now has **zero callers of any kind** (every screen reads
  `GetUnitViews`); the only references left are its own handler registration and comments. Two
  profile read paths against one schema is a standing rot hazard — the compat cruft deleted above
  is exactly that rot. **Execution (handler + RemoteFunction deletion) is scheduled for A7,
  deliberately AFTER the blocking republish**: that publish is already the riskiest open action and
  carries all of A-phase + A5 + A6, remote deletions fail late and silently (a client
  `WaitForChild`ing a removed remote yields forever), and Place-local code is Studio-canon
  (ADR-0001) so the published file is the only recoverable snapshot. Until then it stays wired and
  unread — **no new readers may be built on it**, recorded in the `LobbyServices` header.
- **Contract impact: none.** No shared-module EDIT (a deploy of an unchanged module), no schema or
  teleport change. `GetCollection` is not a versioned contract and both deleted fields were
  documented as interim from the day they landed. ADR-0004 does note that `GetUnitViews` is now
  load-bearing for the entire Lobby UI and would need contract treatment if ever changed breakingly.

**Verified live (Play, dev store, Lobby)** — canonical method per CLAUDE.md (`[DIAG]` prints from
real Scripts + `get_console_output`, plus instance-property reads; no service state via
`execute_luau`). Studio was restarted mid-session, so every edit was re-verified from the saved
file afterwards (drift 9/9, zero compat remnants) before landing:

- Boot clean: `[CONTRACT] Lobby boot: save-schema v2`, `[DATA] LobbyServices ready`, profile v2
  loaded, `CollectionScreen`/`HotbarController`/`UnitsController`/`ItemsController` all ready.
  **No errors or warnings under any of our log prefixes.** `LobbyServices ready` is the module's
  LAST line, so the edited module compiled and both handlers registered.
- Collection loads with the compat fields gone: `[DIAG] CollectionScreen loaded 8 unit view(s)`,
  **8 cards, 0 stray templates**, meta line `8 unit(s) | Gold: 240 | Silver: 0 | Account Lv 1
  (360 XP)`, first cards Necromancer/Mythic/Lv 20, Meteor/Legendary, Warchief/Legendary,
  Babaylan/Epic — real grades throughout. Verified via the `DevAutoOpen` harness (A5 pattern),
  **left OFF on all three screens at landing**.
- `UnitStatsCatalog` requires cleanly from a client context (the exact thing AD-UI needs next):
  8 towers, `Get` is a function, all values match A6's published set (Archer 15/20/6, Knight
  35/10/1.4, Mage 30/18/2, **Farm RNG-only, no DMG/SPA**, Babaylan 20/22/2.5, Meteor 30/24/1.4,
  Warchief 25/18/1, Necromancer 28/22/1.1), `Get("NotATower")` → nil, REFERENCE tier 1 / ML 1 /
  asc 0. (Pure data module, no services — a compile+shape check, not a live-service-state check.)
- **Environment note:** four Play attempts died within ~1s to `Server Kick Message: Error 500`.
  Cause was a **free model the user had inserted**; after the user removed it and restarted
  Studio, Play was stable and every check above passed. Not a code defect — but see the advisory:
  inserted free models are a known backdoor-script vector and the Place should be swept.
- **PENDINGs:** the TWO this session owned are **CLEARED** (deploy `UnitStatsCatalog` to the Lobby;
  the A5 `GetCollection` handoff). **NEW (A7 / AD-Integration):** delete the `GetCollection` handler
  + RemoteFunction per ADR-0004, after the republish. **AD-UI is now UNBLOCKED** to fill the Units
  `--` slots from `UnitStatsCatalog.Get`. Unchanged: **USER republish both Places** (now also
  covering A5 + A6 + this session), no `Data.Loadout` writer, no `Data.Items` writer,
  `TowerProgressionConfig` promotion for `XpPct`, Game round-trip test.
- Commit is **local** (`push pending` — the remote-tracking ref shows main level with origin
  through A6, but this session's commit is unpushed).

## 2026-08-03 [game] A6 (AD-Game): UnitStatsCatalog + load-bearing validator, profile-wait moved to StartMatch, cold-profile harness

Bootstrap drift **GREEN 8/8** at start. Integration gate: **No Integration needed — proceeding**
(the new shared module deploys to Game now; the Lobby deploy is a follow-up PENDING). Three items,
per the session brief.

- **`UnitStatsCatalog` (new, 9th shared module; ADR-0003).** `shared/src/UnitStatsCatalog.luau` →
  `RS.Configs.Meta.UnitStatsCatalog`, hash **`3bb9b140`**, `deployed.Game` only (**Lobby=null**).
  A GENERATED cache of each tower's resolver-PRODUCED base DMG/RNG/SPA at the reference tier 1 /
  ML 1 / no-trait / mid-roll (0.5) / asc 0 — SPA inverted, not raw BaseStats. Lets the Lobby fill
  the A5 Units `Stats.BaseStatsFrame.{DMG,RNG,SPA}` number slots WITHOUT the ~12-module full stat
  stack. `manifest.json` + `tools/hash_shared.luau` now cover **9** modules. Values (Archer 15/20/6,
  Knight 35/10/1.4, Mage 30/18/2, Farm –/18/–, Babaylan 20/22/2.5, Meteor 30/24/1.4, Warchief
  25/18/1, Necromancer 28/22/1.1).
- **Load-bearing validator** `SSS.Server.UnitStatsCatalogValidate` (Game canon, runs in ALL contexts):
  regenerates from the live tower configs at boot and `error()`s LOUDLY on any drift (a stale cache
  lying about damage is worse than `--`; ADR-0003). Verified: green when correct, and it caught an
  injected `Archer.DMG 15→99` with a red boot error that did NOT brick the runtime.
- **Empty-hotbar hotfix review → wait moved to the choke point.** The profile-wait that guarded the
  cold-profile race MOVED from `MatchEntryService` into `MatchDirector.StartMatch` (the one place
  that validates loadouts), so it now protects EVERY caller — teleport entry, restart/next-act, the
  harness, and any future relaunch — not just the entry path. `StartMatch` claims `isRunning` before
  yielding so a second concurrent start can't slip through the wait; `MatchEntryService` simplified
  (its `waitForProfiles` + `PlayerDataService` require removed). No circular require (MatchDirector
  already reaches PlayerDataService via LoadoutValidator→PlayerInventoryService).
- **No-dev-seed Studio harness** `ColdProfileMatchTest` (Studio-only, attribute `Enabled` default OFF;
  the smoke test stands down when it is on): waits for the REAL profile and builds the loadout from
  the player's ACTUAL owned units (no `DevSetOwnedTowers`), then `StartMatch`. Closes the blind spot
  behind two live-only failures. Verified: read the real profile (8 units), built a 6-uuid loadout,
  match started with **no dev-seed line** and no empty hotbar; smoke test stood down.
- **Contract impact:** none (save/teleport unchanged). **Shared-module ADD** — Lobby must deploy
  `UnitStatsCatalog` (below). All other A6 code (validator, harness, MatchDirector, MatchEntryService,
  smoke test) is Game Studio canon.
- **PENDINGs:** the 3 A6-Game PENDINGs CLEARED (UnitStatsCatalog, hotfix review, cold harness). NEW
  (AD-Lobby / AD-Integration): **deploy `UnitStatsCatalog` `3bb9b140` to the Lobby** — its drift check
  FAILS until then — after which AD-UI fills the Units `--` number slots. USER republish PENDING now
  also covers this session's Game changes.

## 2026-08-03 [lobby] A5: Items screen + FilterPanel on the kit, CollectionScreen rebuilt on the view-model, kit moved to RS.UITemplates.Kit

Blueprint phase-a §9 A5 (AD-UI). Bootstrap drift **GREEN 8/8**, unchanged at landing (no shared
module touched). Integration gate answered "No Integration needed — proceeding."

- **Kit relocated to the blueprint §5 home.** `ReplicatedStorage.UITemplates.Kit` now holds every
  editable template: the moved `Button` / `UnitPreviewTemplate` / `Unit/ItemIconTemplate` plus the
  new `ItemIcon`, `ItemHoverCard`, `FilterPanel`. **`StarterGui.UITemplates` emptied and deleted.**
  `UIKit.Button` already probed the Kit path first, so nothing needed rewiring. *(User chose this
  over keeping the split — it follows the blueprint literally.)*
- **`UIKit.ItemIcon`** (new, `RS.Shared.UIKit.ItemIcon`) — flat `IconImage` ImageLabel, **no
  ViewportFrame** (items have no model), `QtyBadge` that hides at qty 0 and dims the icon, tier
  border + BG from the shared multi-colour `TierConfig`, hover/press scale + white border.
  `create/attach/onHover/onActivated/setQty/setSelected/destroy` + `ImageFor(id)` (falls back to
  the Studio placeholder while every catalog icon is still `rbxassetid://0`).
- **`UIKit.FilterPanel`** (new) — the reusable component the blueprint specifies: `GroupTemplate`
  + `ToggleTemplate` + Apply/Reset/Cancel, pending-vs-applied state, `handle.selected(groupId)`
  returning nil for an unconstrained group. **Used by BOTH screens**: Units (tier + equipped/
  favourited/locked) and Items (tier/kind/owned-only).
- **Items screen** (`StarterGui.ItemsGUI` + `ItemsController`) — chrome cloned from the Units
  screen so the design language matches. Lists every `ItemCatalog` entry of `Kind` Item/Currency;
  counts from `GetUnitViews`. Hover card, selected panel, search, filters; sort owned→tier→name.
- **CollectionScreen REBUILT on real instances** (`Panel.Grid.CardTemplate`, editable in Studio)
  reading `GetUnitViews` — uuid cards, tier border/BG, `Lv N`, the three GRADE letters, a status
  line, and a meta line with Gold/Silver/account level. The old script-built UI is gone
  (convert-on-touch rule). **It was the LAST reader of `GetCollection`'s `Towers`/`Currency`.**
- **Units stat rows are now dual-slot** (user added a `Grade` TextLabel to `DMG/RNG/SPA`
  mid-session): the GRADE letter goes in `Grade`, the NUMBER slot shows `--` instead of the
  template's stale `99.9k`, and A6 fills it with real values. Rows WITHOUT a `Grade` child
  (the hover preview's Attack/Element/MaxPlacement) keep the A4 behaviour.
- **`LobbyServices.GetUnitViews` now also returns `Items`** — the profile's `{ [itemId] = count }`
  map, copied and defensive if absent. **This is AD-Lobby canon edited by AD-UI**, done only
  because the user explicitly authorised it this session when told the alternative; flagged for
  AD-Lobby review in the proposal below. Additive + read-only, so **no contract bump**.
- **Fixed en route:** the legacy `Unit/ItemIconTemplateLocalScript` had a **syntax error on line
  30** (`ocal Preview = ...`) and had been erroring every time that template replicated into
  PlayerGui. Deleted — superseded by `UIKit.Button`.
- **Docs:** `places/lobby/CONTEXT.md` passed its 150-line cap → the UI section split out to the
  new **`docs/systems/lobby-ui.md`** (AD-UI canon, the doc `OWNERSHIP.md` already anticipated),
  registered in `docs/INDEX.md`. CONTEXT is back to 112 lines. Also corrected a long-standing doc
  error: the sixth HUD button is `Store`, not `Shop`.

**Verified live (Play, dev store, Lobby):** `VirtualInputManager` is blocked for tooling
(no `RobloxScript` capability) and `user_mouse_input` / `get_console_output` / `screen_capture`
kept routing to the GAME Studio window mid-session, so verification ran through a new
`DevAutoOpen` **attribute harness** on each screen (same pattern as `DevSimulateReturn`) plus
place-asserted property reads in the Client datamodel:

- Items: 5 cards (BannerTicket/Gold/GoldenSeed/Silver/TraitRerollToken), every qty 0 → badges
  hidden + icons dimmed (correct — nothing writes `Data.Items`); selected = Golden Seed,
  Legendary, "Owned: 0 / 9999", description filled.
- FilterPanel: built from the templates, 4 tier + 2 kind + 1 show toggles on Items, 8 tier + 3
  show on Units, **no stray `GroupTemplate` left in the layout** on either.
- Collection: 8 uuid cards, first = Necromancer / Mythic / Lv 20 / DMG B RNG B SPA B, meta line
  "8 unit(s) | Gold: 0 | Silver: 0 | Account Lv 1 (0 XP)", no stray template.
- Units: `Grade` labels read B/B/B (matching Necromancer) with the number slot at `--`.
- `applyFilters` exercised end-to-end via the search path: ""→8, "mage"→1, "necro"→1, "zzz"→0, ""→8.
- Boot clean: `[DIAG] ItemsController ready`, `[DIAG] CollectionScreen ready`, no errors;
  `UIKitBootstrap` picked up 33 tagged buttons. Harness attributes left **OFF** on all three.

**Hover geometry — closed same session (follow-up pass).** Verified by deriving the real
viewport from a full-screen probe rect (`CurrentCamera.ViewportSize` reads `1,1` from the
tooling VM) and replaying the placement maths against every real card rect. Three findings, all
fixed:

- **A4's `showPreview` assumed the preview was `0.2 × 0.36` of the viewport.** The Units preview
  is really ~`0.19 × 0.19`, so the flip-to-left triggered about twice as early as needed and the
  vertical clamp reserved double the margin. Both controllers now **measure** `AbsoluteSize`
  (scale constants kept as the zero fallback).
- **`math.clamp` errors when max < min** — reachable whenever the preview is taller than the
  viewport, and hit for real during verification. Now guarded (falls back to vertical centre);
  the horizontal position is clamped on-screen too.
- **Template/instance size drift:** `ItemsGUI.HoverPreview` was cloned from `ItemHoverCard`
  *before* that template was resized, so the deployed copy kept the old ~38%-of-screen footprint
  while the template said 20%. Re-synced; a sweep confirmed both `FilterPanel` clones match.

Re-verified at 1920×1078: Items preview 384×367 (20%×34%), Units 368×201 (19%×19%), **0 flips,
0 off-screen** across all 13 cards, well inside the viewport. Harness attributes left OFF.

- **Contract impact:** none. No shared module, schema or teleport change; drift surface unchanged
  (GREEN 8/8 at both bootstrap and landing). `GetUnitViews` gained one additive read-only field.
- **PENDINGs:** A5 cleanup PENDING **handed to AD-Lobby** —
  `docs/proposals/2026-08-03-drop-getcollection-compat.md` covers both deleting the now-unread
  `Towers`/`Currency` compat fields AND reviewing AD-UI's `Items` addition. Unchanged: **USER
  republish both Places** (this session is Studio canon too), A6 numbers decision + hotbar,
  `Data.Loadout` writer (`Equipped` always false), **no `Data.Items` writer** (every item count
  is 0 by design until an item economy exists), `TowerProgressionConfig` promotion for `XpPct`,
  Game round-trip test + no-dev-seed harness.

## 2026-08-03 [lobby] A4: Units screen wired to the GetUnitViews view-model (real tiers/grades) + UnitCatalog deleted

Blueprint phase-a §9 A4 (AD-UI). Re-bootstrapped onto the post-A1/A2/A3 world (drift GREEN 8/8,
`ProfileTemplate 63a0c98a`, schema v2).

- **`UnitsController` now consumes `LobbyServices.GetUnitViews`** (was `GetCollection` + the
  interim `UnitCatalog`). Cards are keyed by **uuid** (one per unit instance). Each card renders
  from the view: `Name`+`Tier` (ItemCatalog), tier border + BG from the shared multi-colour
  `TierConfig`, per-stat **GRADE** letters (`view.Grades`, from `StatGradeConfig`) in the Stats
  panel + hover preview, real `Level`/`XP` on the preview level bar, `Favorited`/`Equipped`
  driving the sort (equipped > favourited > tier high→low > name), search by `Name`.
- **`fillStats` hardened:** stat rows resolve by `DMG/RNG/SPA` OR the template's
  `Attack/Element/MaxPlacement` names (the hover preview kept the original template names, so it
  showed stale `99.9k` defaults until now); the preview's fake element chips (`InformationFrame`)
  are hidden until real element data exists.
- **`RS.Configs.Meta.UnitCatalog` DELETED** — the retired-in-place interim config (A2 left it as
  the only placeholder source) has no readers left. Confirmed via `script_grep` before deleting.
- **Resolved DMG/RNG/SPA NUMBERS still deferred to A6** (per the 2026-08-01 user decision —
  `TowerStatResolver` is not in the Lobby). A4 ships **grades**, which need only the roll.
- **Verified live (Play, dev store):** 8 units load via `GetUnitViews`, no errors; grades vary
  per unit and stat (e.g. Mage D/SS/C, Knight A/C/C, Necromancer B/B/B — no longer flat); tier
  sort puts Necromancer (Mythic) first (auto-previewed on open); hover preview shows the unit's
  grades + real `LVL: 20`, element chips hidden; rainbow/Legendary/etc. borders render.
- **Contract impact:** none (read-only consumer of the existing `GetUnitViews`; no shared-module
  or schema change; drift surface unchanged).
- **PENDINGs:** UnitCatalog-deletion PENDING CLEARED. Remaining for A5/A6: rebuild CollectionScreen
  on the view-model so `LobbyServices.GetCollection`'s interim `Towers`/`Currency` compat can be
  removed (AD-Lobby); Items screen + FilterPanel (A5); resolved stat NUMBERS + hotbar rebuild (A6);
  `Data.Loadout` writer / equip UI so `Equipped` is ever true; real per-unit models. **USER: republish
  both Places** (Studio canon).

## 2026-08-03 [lobby] Starter grant rolls real quality: StarterChoiceService calls StatGradeConfig.RollAll

- **PENDING (AD-Lobby starter rolls) CLEARED** — per AD-Game's proposal
  (`docs/proposals/2026-08-03-starter-grant-rolls.md`): `StarterChoiceService.newUnitInstance`
  now writes `StatRolls = StatGradeConfig.RollAll(statRng)` instead of the hardcoded
  `{0.5,0.5,0.5}` midpoints. `StatGradeConfig` required from its shared deploy path
  (`RS.Configs.Meta.StatGradeConfig`, drift-green 49a6edfd); ONE module-level `Random`
  (same rationale + pattern as `PlayerInventoryService` — per-grant `Random.new()` can
  correlate same-frame). Every other UnitInstance field byte-matches `GrantUnit`'s shape
  (re-read from Game canon this session). Grant log now prints rolls + grades.
- **Verified live (Play, dev store, DevSimulateFirstJoin harness):** two grants across
  separate runs rolled DMG=0.370/D RNG=0.652/B SPA=0.341/D then DMG=0.764/B RNG=0.598/C
  SPA=0.509/C — varied run-to-run, all in 0..1, grade spread D/C/B, boundary case correct
  (0.652 → B, just past C's 0.65 max). Sim tower auto-cleaned on the non-sim boot; sim left
  OFF; dev profile clean.
- **A4 caveat lifted:** "every grade reads C" no longer applies to any grant path — all
  paths (GrantUnit, DevSetOwnedTowers, starter) now roll. Only pre-existing/migrated units
  remain grandfathered at 0.5 by design.
- **Contract impact:** none — value-only change inside the v2 `UnitInstance`; no schema
  bump, no shared-module edit, no drift surface. Drift GREEN 8/8 at bootstrap.
- **PENDINGs:** starter-rolls PENDING cleared. Unchanged: USER republish both Places (this
  change is Studio canon too and joins that publish), Loadout writer, A6 numbers decision,
  A4/A5 cleanup, TowerProgressionConfig promotion, Game round-trip test.

## 2026-08-03 [game] Stat rolls actually roll: GrantUnit + DevSetOwnedTowers call StatGradeConfig.RollAll

- **The fix:** `PlayerInventoryService` (Game canon) now requires shared `StatGradeConfig` and rolls
  real per-unit `StatRolls` instead of the hardcoded `{0.5,0.5,0.5}`. `GrantUnit` uses
  `o.StatRolls or StatGradeConfig.RollAll(statRng)` — an explicit `opts.StatRolls` still wins, so
  deterministic tests and the future gacha (which inherits this canonical entry point) keep working.
  `DevSetOwnedTowers` rolls each seeded unit too (with an optional per-tower `value.StatRolls`
  override for deterministic Studio tests). Both draw from ONE module-level `Random` (`statRng`) —
  `Random.new()` per grant can correlate within a frame and hand out identical rolls; the shared
  `StatGradeConfig` is left untouched (rng passed in).
- **Left alone (correct):** `Migrations[1]` (append-only; already ran live — existing units stay
  grandfathered at 0.5), `GetUnit`'s defensive `record.StatRolls or {0.5..}` read-guard.
- **Not mine — handed off:** the Lobby's `StarterChoiceService` still writes 0.5 (AD-Lobby canon).
  Wrote `docs/proposals/2026-08-03-starter-grant-rolls.md` + a STATE PENDING; `StatGradeConfig` is
  shared, so that chat calls `RollAll(rng)` directly.
- **Verified live** (real `[Test]` Script + `get_console_output`, NOT execute_luau — grants mutate
  the profile): 6 Archers + 3 Mages rolled distinct values in 0..1 (0.027–0.997), grade spread
  D/C/B/A/SSS (no longer all "C"), explicit override returned exactly `{1,0,0.5}`, and two Archer
  instances at ML50 resolved to different DMG/SPA/RNG (37.8/32.4 DMG) — the quality multiplier doing
  something for the first time. Temp harness removed after.
- **Balance note (flagged, not silently shipped):** with real rolls the BaseStats pilots vary
  unit-to-unit. Estimated single-unit DPS swing (DMG × SPA-inversion): **Archer ≈ 0.78×–1.24×**
  (~1.6× best/worst), **Mage ≈ 0.72×–1.32×** (~1.83× best/worst, from its wider ±20% DMG range).
  Not broken — worst-roll units are still functional — but Mage's spread is on the wide side with no
  stat-reroll system yet (phase C). Recommend tightening Mage `BaseStats.DMG` (e.g. {0.88,1.12})
  or revisit at reroll balancing; left as-is pending the user's call.
- **Contract impact:** none. `PlayerInventoryService` is Game Studio canon (no shared-module/manifest
  change); it only *requires* the already-shared, drift-green `StatGradeConfig`. No Integration needed.
- **PENDINGs:** AD-Game roll wiring CLEARED; NEW AD-Lobby starter-grant PENDING (above). USER
  republish PENDING now also covers this `PlayerInventoryService` change (Studio canon, not git).

## 2026-08-01 [integration] Meta configs promoted to shared canon + TierConfig multi-colour reconcile + LobbyServices unitView — A4/A5 unblocked

Executes `docs/proposals/2026-08-01-a4-promote-meta-and-tierconfig-multicolor.md` §1–§4, with one
scoped decision and two scope corrections (below). Hotfix from earlier today confirmed live by the
user first (empty-hotbar bug gone), so this session started from a healthy live game.

- **Promoted to `shared/src` + deployed byte-identical to BOTH Places** (all hashes verified
  in-Studio == disk == manifest, drift GREEN in both):
  `TierConfig a0d6e3a3` · `StatGradeConfig 49a6edfd` · `AscensionConfig 59aa8e15` ·
  `ItemCatalog 789dca4b`. `tools/hash_shared.luau` now covers all EIGHT shared modules.
- **TierConfig reconciled** (A3 shape as base + the Lobby's multi-colour, per §2): 8-tier `Order`
  with `SortOrder` and the PascalCase API from A3; `Colors` LIST per tier plus
  `get`/`colorSequence`/`seamlessSequence`/`isMultiColor` lifted verbatim from the Lobby interim
  module. **Mythic rainbow (6 colours) and Secret red→dark-red preserved**; Common..Secret keep the
  Lobby's tuned on-screen values, Exclusive + Bathala keep A3's. `.Color` is DERIVED from
  `Colors[1]` so there is one authored source per tier and A3's `GetColor` contract still holds.
  Verified live: `isMultiColor("Mythic")=true` (6 colours), `seamlessSequence` returns 13
  keypoints with first == last (the seamless scroll wrap intact).
- **`LobbyServices.GetUnitViews`** (new RemoteFunction) — the A4/A5 contract. Per owned uuid:
  `Uuid, TowerId, Name, Tier` (both from ItemCatalog), `Level, XP, Trait, Shiny, Ascension,
  Worthiness, Locked, Favorited, Equipped` (uuid ∈ `Loadout`), raw `StatRolls`, and
  `Grades = {DMG,RNG,SPA}` letters from `StatGradeConfig`. Plus `Loadout`, `Currencies`,
  `PlayerXP/PlayerLevel`, `MaxLoadout`. Clients never read profiles (blueprint §5).
  Verified live: 8 units returned with correct tiers/levels/grades.

**DECISION (user, this session) — resolved stat NUMBERS deferred.** §1 assumed promoting
`TowerStatResolver` was a one-module move. It is not: `Resolve()` takes a whole **towerConfig**
(`Upgrades[tier]`, `BaseStats`, `Attack`) and internally requires `MetaScalingConfig` +
`TraitRegistry` + `TraitDefinitions` — so making the Lobby resolve numbers means putting ~12
modules including all 8 tower configs (AD-Game's most-tuned files) under drift control. Options
put to the user were (a) full stat stack, (b) a Game-generated slim stats catalog + boot
validator, (c) ship grades now / decide numbers at A6. **User chose (c).** Grades need nothing
but the roll, so A4/A5 get tiers, grades, borders and equipped state with ZERO new drift surface.
`TowerStatResolver` was therefore NOT promoted and stays Game canon.

**Scope corrections vs the proposal:**
1. **`UnitCatalog` was NOT deleted** (§3 said delete). Its deletion was contingent on §4 supplying
   real stats; with numbers deferred it is still the only source of the Units-screen DMG/RNG/SPA
   placeholders, so deleting it would have blanked that panel. It is **retired in place**: header
   rewritten to mark Name/Tier as duplicates of ItemCatalog (do not edit), delete outright at
   A4/A5. The interim Lobby `TierConfig` WAS fully replaced as specified.
2. **`ItemCatalog` needed a code change to be shareable** — it hard-required
   `TowerConfigRegistry`, which does not exist in the Lobby and would have failed to load there.
   That require is now lazy + optional; `Validate()` returns `(ok, errors, notes)` and reports the
   skipped Tower→TowerConfig cross-check in Places without tower configs. The Game still runs the
   full check — verified: `[Test] MetaConfig OK: ItemCatalog valid (13 entries), 8 tiers`.
   Also added `GetName`/`GetTier`.
- **`XpPct` not served:** the Lobby has no `TowerProgressionConfig`, so the XP curve is unknown
  there. Raw `XP` + `Level` are sent instead. Promoting that config (owner **AD-PlayerLevel**) is
  a small follow-up if a real XP bar is wanted — new PENDING.

**TWO INERT-SYSTEM FINDINGS (surfaced by verification, not fixed here):**
1. **Nothing ever calls `StatGradeConfig.RollAll`/`RollStat`.** Every unit in existence has
   hardcoded `StatRolls = {0.5, 0.5, 0.5}` — from the v1→v2 migration, `GrantUnit`'s default,
   `DevSetOwnedTowers`, and the Lobby starter grant. So **every grade in the game is "C"** and
   every quality multiplier is exactly the midpoint. A3 built the roller; no grant path wired it
   in. Until that lands, grades and BaseStats ranges are decorative. → PENDING (AD-Game).
2. **Nothing ever writes `Data.Loadout`.** Template inits it `{}`, migration sets `{}`, the Lobby
   only READS it. So `Equipped` is always false and `buildLoadout` always falls through to
   auto-loadout (top 6 by MetaLevel). **Equipping does not exist yet** — the unitView now carries
   the flag, but nothing can set it. → needs scheduling (see STATE).

- **Contract impact:** none — no save-schema or teleport change. Four NEW shared modules under
  drift control (manifest 4 → 8 entries); `OWNERSHIP.md` row for ItemCatalog/TierConfig (AD-UI)
  now points at `shared/src`.
- **PENDINGs:** A2-followup Integration promotion CLEARED. NEW: numbers decision at A6 (AD-Game +
  Integration), stat-roll wiring (AD-Game), `Data.Loadout` writer / equip UI (needs scheduling),
  TowerProgressionConfig promotion for XpPct (AD-PlayerLevel), UnitCatalog deletion at A4/A5.
  **USER: republish BOTH Places** — all of this is Studio canon.

## 2026-08-01 [integration/hotfix] LIVE BUG: empty hotbar in production matches — profile-load race before loadout validation

**Symptom (user, first live teleport-v2 run):** teleported into the match with NO units in any
hotbar slot, could not place anything, lost the match.

**Root cause — a race, not bad data.** `MatchEntryService` waited only for the party to be
*present* (`Players:GetPlayerByUserId`) and then called `MatchDirector.StartMatch`, which
validates loadouts SYNCHRONOUSLY via `LoadoutValidator` → `PlayerInventoryService.GetUnit` →
`getData(userId)`. When a profile has not finished loading, `getData` returns a deep copy of the
EMPTY `ProfileTemplate.Template` (`Units = {}`) — indistinguishable from "this player owns
nothing". So every loadout uuid was dropped as `NotOwned` and the player entered with an empty
hotbar. In a **reserved server the players are already present when the service boots**, while
ProfileStore still needs a DataStore round-trip — so losing this race is the DEFAULT live
outcome, not an edge case.

**Why Studio never caught it (A1/A2/A3 all passed):** the Studio entry path is
`MatchLifecycleSmokeTest`, which calls `DevSetOwnedTowers` — that populates the in-memory
stand-in synchronously *before* starting, so the profile is never actually raced. Every Studio
verification exercised a pre-seeded path. The production path had never once run with a real
cold profile. Note this is the SECOND live-only failure of the same symptom (2026-07-18 was
`Loadout={}` from the Lobby); both were invisible to Studio for the same structural reason.

- **Fix (`MatchEntryService`):** new `waitForProfiles(userIds)` runs AFTER `waitForParty` and
  BEFORE `StartMatch`, awaiting `PlayerDataService.WaitForData` per player
  (`PROFILE_LOAD_TIMEOUT = 20`). Logs `[MatchEntry] [DATA] All N profile(s) loaded (waited Xs)`.
  On timeout it does NOT wedge the match — it starts anyway but `warn`s loudly with the affected
  userIds (old behavior, now audible).
- **Fix (`PlayerInventoryService.getData`):** the silent empty-template fallback now `warn`s
  once per userId outside Studio (`profile NOT loaded … ownership check WILL report zero units`),
  so this failure class can never be invisible again. Diagnostic only — no behavior change; the
  Studio dev-seed path deliberately still uses the fallback.
- **Verified (Studio):** Game boots clean, `MetaConfig OK`, smoke-test path unchanged (the new
  wait is only on the MatchLaunch entry path), match reaches Countdown, no errors. **The real
  proof is the next live run** — Studio structurally cannot reproduce the race.
- **OWNERSHIP NOTE:** `MatchEntryService` + `PlayerInventoryService` are **AD-Game** canon
  (`Match lifecycle` row). Edited from the AD-Integration chat on explicit user instruction
  ("fix that") because the bug was blocking live play and was surfaced by the v2 rollout this
  chat landed. **PENDING for AD-Game: review this hotfix.** Design question left open for the
  owner: whether the wait belongs in `MatchDirector.StartMatch` itself (protecting every caller)
  rather than only the production entry path.
- **Contract impact:** none. No schema, payload, or shared-module change; manifest untouched.
- **Studio noise seen once:** client `WaitForChild` "Infinite yield possible" lines on one Play
  start; all ten StarterGui screens verified present + Enabled — Studio replication lag, not a
  regression.

## 2026-08-01 [game] Schema v2 wiring (blueprint A3): Meta configs + BaseStats pilots + resolver reads StatRolls

- **New `RS.Configs.Meta` (Game canon; promote to shared at A7):** `TierConfig` (Common→…→Bathala
  order + colors/sortorder), `StatGradeConfig` (D C B A S SS SSS Apex thresholds + `RollStat`/`RollAll`),
  `AscensionConfig` (MaxLevel 3, MinTier Mythic, absolute per-level DMG mults A1 ×1.05 → A3 ×3 +
  `PerTower` override + `GetMult`/`GetCost`), `ItemCatalog` (13 entries: 8 towers tier-assigned +
  Gold/Silver + BannerTicket/TraitRerollToken/GoldenSeed, `Tradeable=false`, `Validate()`).
  New Studio-only `MetaConfigTest` runs `ItemCatalog.Validate()` at boot.
- **BaseStats pilots:** Archer + Mage gain top-level `BaseStats = { DMG/RNG/SPA = {Min,Max} }`
  quality-multiplier ranges (strength; higher = stronger). Other towers have none (flat 1.0).
- **`TowerStatResolver` reads rolls (the A3 fix):** new optional `statRolls` + `ascension` params.
  For DMG/RNG/SPA it folds a per-unit quality multiplier `rollStrength (Min+(Max-Min)*roll) ×
  AscensionMult` into the existing tier×meta×trait pipeline — multiplied for normal stats, DIVIDED
  for the inverted SPA (so roll 1.0 = fastest). Default (no BaseStats / nil roll / asc 0) = 1.0, so
  scalar towers are byte-identical. Threaded: `LoadoutValidator` entry (+Uuid already; now +StatRolls
  +Ascension from the unit) → `PlacementValidator` → `TowerManager.PlaceTower` → `TowerController`
  (stored; re-resolved on upgrade). `ResolveNextTier` passes them through.
- **Scope (blueprint-faithful):** compose model chosen with the user = quality multiplier (least
  invasive, preserves balance). NOT in A3 (later phases): teleport/loadout already v2 (A2); Counters/
  Worthiness increments; UI kit wiring (A4–A6) — so client stat PREVIEWS still resolve at rollMult 1.0
  for now (server gameplay is roll-correct). Combat/placement/`MatchStatsTracker` unchanged (§7).
- **Verified:** resolver unit tests — scalar tower (Knight) asc 0 byte-identical with/without rolls;
  Archer roll 0.5 == old; roll 0/1 moves DMG ±15% and SPA (roll 1 faster); ascension 3 = ×3 DMG;
  Necromancer asc 2 = ×1.5 DMG; `ItemCatalog.Validate` ok (0 errors). Play-test — `schema v2` boot,
  `[Test] MetaConfig OK (13 entries, 8 tiers)`, profile v2 loaded, match to Countdown, no errors.
- **Contract impact:** none — save schema stays **v2** (StatRolls already in the v2 shape; A3 only
  reads them). No shared-module (manifest) change; all A3 code is Game Studio canon.
- **PENDINGs:** A3 CLEARED. Next: A4/A5 (AD-UI) wire the kit to resolved stats + real rolls. The
  BLOCKING user publish PENDING now also covers A3's Game changes (publish Game + Lobby together).

## 2026-08-01 [integration] A2: schema v2 to the Lobby + teleport contract v2 (uuid loadouts) — Phase A unblocked

Blueprint `phase-a-foundations.md` §2 + §9 A2. Both Places driven in one session (AD-Integration).

- **ProfileTemplate v2 → Lobby:** deployed verbatim from `shared/src` (`184cdfad → 63a0c98a`,
  hash computed in-Studio == manifest == Game). `manifest.deployed.Lobby` updated;
  **drift check now GREEN in BOTH Places** for all four shared modules.
- **Lobby v2 reads (Studio canon):**
  - `LobbyServices.GetCollection` serves uuid-keyed `Units` (TowerId/MetaLevel/XP/Trait/Shiny/
    StatRolls/Ascension/Worthiness/Locked/Favorited/ObtainedAt), `Loadout`, `Currencies` and
    `PlayerLevel`. **Interim compat:** it also still returns `Towers` (collapsed to the highest-
    MetaLevel instance per TowerId) and `Currency` (= Gold) so the not-yet-rebuilt CollectionScreen
    + UnitsGUI keep working — **remove both at A5** (new PENDING; they are the only readers).
  - `StarterChoiceService`: eligibility is now `Units` empty; the grant writes a uuid
    `UnitInstance` mirroring the Game's `PlayerInventoryService.GrantUnit` (mid rolls 0.5 until
    A3), returns the `Uuid`, and the sim-tower self-heal scans by `TowerId`.
  - `PartyService.buildLoadout`: returns **uuids** — the saved profile `Loadout` filtered to
    still-owned uuids (deduped, capped at `MaxLoadoutSize`), else auto-loadout by MetaLevel desc.
- **Teleport contract v1 → v2** (`docs/contracts/teleport.md`, version history + shapes updated).
  Only change: `Players[uid].Loadout` carries unit uuids. `LobbyConfig.MatchLaunchVersion = 2`
  and `GameConfig.TeleportPayloadVersion = 2`; `MatchReturnService` now READS its expected version
  from `LobbyConfig` instead of a hardcoded `1` (one integer covers both directions).
  **Hard cutover, no migration:** both Places deploy together, so v1 is rejected, never fallen back
  to. Game-side code needed no logic change — `MatchEntryService` already passed `Loadout` through
  to `LoadoutValidator` (uuid-aware since A1); only the version constant + comments moved.
- **Verified (Studio, both Places):**
  - Game boot: `[DATA] PlayerDataService ready (schema v2)`, `[CONTRACT] Profile v2 loaded`
    (Beta1_PlayerDataDev1, Access), `[MatchEntry] Ready`, match reaches Countdown, no errors.
  - `BuildRawConfig` unit tests: v2 accepted (uuids preserved, string→numeric userId keys), **v1
    rejected** (`[CONTRACT] PayloadVersion mismatch: got 1, expected 2`), unknown stage rejected,
    difficulty 999999 → 1000.
  - Lobby boot: `[CONTRACT] Lobby boot: save-schema v2`, `MatchReturn v2 receiver`, `teleport
    contract v2`, UI kit + hotbar + Units controllers all init clean, no compile errors.
  - Live remote reads: `GetCollection` → 8 uuid Units (rolls present) + compat layer intact;
    real `RequestLaunch` → `[DIAG] Launch loadout: [6 uuids]` then `[Teleport] launch failed:
    HTTP 403` (expected — Studio cannot ReserveServer).
  - Starter grant path (`DevSimulateFirstJoin`): offer eligible → granted uuid
    `945f74d5-…` with the exact GrantUnit field set; next clean boot self-healed the sim unit
    (`[Test] removed leftover SimTestTower`) and correctly reported ineligible. Sim attribute OFF.
- **Contract impact:** teleport **v1 → v2** (no migration — atomic cutover). Save schema
  unchanged at v2; shared module deployed, not edited (manifest `deployed.Lobby` only).
- **PENDINGs:** A2 CLEARED. NEW — **USER must publish BOTH Places together** (live is mid-cutover;
  a partial publish breaks launches with a version mismatch). NEW — A5 removes the compat fields.
  Carried: A3 (resolver reads StatRolls), persistence round-trip, Studio-doc migration.
- **Note:** STATE.md was over its 100-line cap; resolved PENDINGs were trimmed out (history lives
  here) — now 102 lines.

## 2026-08-01 [game] Schema v2 (blueprint A1): uuid unit instances + Currencies map + migration

- **Contract change — save schema v1 → v2** (owner AD-Game, `docs/blueprints/phase-a-foundations.md`
  A1). `ProfileTemplate` (SCHEMA_VERSION=2): towerId-keyed `Towers` → uuid-keyed `Units`
  (UnitInstance: TowerId/MetaLevel/XP/Trait/Shiny/StatRolls/Ascension/Worthiness/Locked/Favorited/
  SpiritUuid/ObtainedAt); scalar `Currency` → `Currencies` map (Gold/Silver/TraitRerolls/StatRerolls/
  EventTokens); added PlayerLevel/Loadout/Pity/Counters/Quests/LoginStreak/ShopStock/Titles/Spirits/
  Battlepass. `Migrations[1]` converts v1→v2 (Currency→Gold, each Towers entry→a Units instance with
  mid rolls 0.5, Loadout={}); Reconcile fills the rest; account XP/items/settings preserved. STORE_NAME
  stays Beta1_PlayerData(Dev1).
- **Game service uuid refactor (Studio canon):** `PlayerInventoryService` now Units/uuid-keyed
  (`GetUnit`/`GetAllUnits`/`GrantUnit`/`GetFirstUnitId`, `Owns` by TowerId across instances,
  `AddTowerXP(userId, uuid)`, `AddCurrency`→`Currencies.Gold`, `DevSetOwnedTowers` seeds instances +
  returns a towerId→uuid map; back-compat `GetOwnedTower`/`GrantTower` shims kept). `LoadoutValidator`
  validates **uuid** lists (entry now carries `Uuid`; `FindEntry` stays by TowerId). `RewardCalculator`
  commits tower XP by **uuid** + reads `Currencies.Gold`. Smoke test + `MatchActionHandler` build uuid
  loadouts; `MatchEndVerify` updated. **Combat / placement / MatchStatsTracker unchanged** (§7): stats
  stay towerId-keyed and the uuid is resolved from the loadout at the commit boundary.
- **NOT in A1 (later phases, by blueprint):** StatRolls resolver + BaseStats ranges (A3), teleport v2
  uuid loadouts (A2), Counters/Worthiness increments + UI (later). StatRolls persist now but the
  resolver ignores them until A3.
- **Deploy/verify:** drift-clean before edit (Game+disk `184cdfad`). ProfileTemplate edited Studio +
  `shared/src` byte-identical → new hash **`63a0c98a`** (python fnv1a == Studio). `manifest.json`:
  hash + `deployed.Game` → `63a0c98a`; **`deployed.Lobby` left `184cdfad` (STALE)**. Verified:
  migration unit test (Currency 80→Gold 80, 2 Towers→2 Units mid-rolls, Loadout={}, XP/items kept);
  Play-test — `[DATA] PlayerDataService ready (schema v2)`, smoke seeded 8 Units, `[DIAG]` loadout
  5 uuids → 5 validated / 0 rejected, `AddTowerXP` by uuid ok, match to Countdown, no errors. Temp
  `[DIAG]` removed after.
- **Contract impact:** save schema **v1 → v2** (migration shipped).
- **PENDINGs:** NEW (A2 / AD-Integration): deploy ProfileTemplate v2 to Lobby (Lobby drift FAILS
  until then), fix Lobby compile to read Units/Loadout, flip teleport v2 (uuid loadouts) both sides,
  e2e. THEN USER republishes both Places. Note: Game service refactors are Studio-canon (not git) —
  **USER must save/publish the Game place**.

## 2026-07-31 [lobby] AD-UI: reusable Button kit + hotbar preview + Units screen + Tier system

- **`UIKit.Button`** (`ReplicatedStorage.Shared.UIKit.Button`, client) — ONE reusable button
  controller replacing per-button scripts. Hover (scale from centre via `centerAnchor`, stroke
  thicken OR `HoverStrokeColor`, icon rotate), press animation, seamless (tiled) animated
  gradient. Attribute-driven; API attach/create/onActivated/onHover/setHovered/setText/setIcon/
  setStrokeColor/setEnabled. Tag-based bootstrap `StarterPlayerScripts.UIKitBootstrap` attaches
  any `UIKitButton`-tagged GuiButton (tags copy to clones).
- **Hotbar** rebuilt on the kit (`Hotbar.HotbarController`): single controller, old duplicated
  per-slot scripts disabled; fixes the random-glow bug (root cause: N copied scripts + overlap).
  Shows `Hotbar.Templates.UnitPreviewTemplate` on hover.
- **Units screen** (`StarterGui.UnitsGUI.UnitsController`): opens from HUD Units; loads owned
  units (v1 `GetCollection`); tier-coloured card border + BG (animated seamless); hover → white
  border + centre-scale + right-side `UnitPreviewTemplate` popup (name/tier/DMG-RNG-SPA + model);
  click → `SelectedUnitFrame` framed viewport + Stats (reusing the preview design); sort
  equipped>favourited>tier(high→low)>name; live search; placeholder model
  `ReplicatedStorage.UnitModels.Placeholder`. Action buttons animation-only.
- **Tier system (editable):** `RS.Configs.Meta.TierConfig` (tier → colour list; one = solid,
  many = seamless animated gradient — Mythic rainbow, Secret red→dark-red) + `UnitCatalog`
  (towerId → Tier + placeholder DMG/RNG/SPA + optional Equipped/Favorited). Verified live in Play.
- **HUD buttons** (`HUD.Left.Buttons.*`) tagged + animated; `Frame.BorderDesignInside` hidden;
  hover = white stroke (no thicken).
- **Constitution compliance:** all UI is REAL instances (Studio-editable); controllers only
  clone/fill/wire. UI kit + configs are **Studio (Lobby) canon** for now (per hybrid model);
  documented here + in `places/lobby/CONTEXT.md`. Proposal `docs/proposals/2026-07-31-ui-kit-button-primitive.md`
  (Button primitive) is now IMPLEMENTED interim; user-directed (approved live).
- **Contract impact:** none (no schema/teleport change; reads existing `GetCollection`).
- **PENDINGs:** deferred to schema v2 / A3 — real per-unit models, resolved DMG/RNG/SPA, real
  Loadout(equipped)+Favorited, functional action buttons; promote `UIKit`/`TierConfig`/`UnitCatalog`
  to `shared/src` at Integration if the Game place needs them. **USER: save + republish the Lobby.**
- **Open threads:** commit is LOCAL (push pending). Studio place must be saved by the user
  (Studio-canon code is not in git).

## 2026-07-31 [lobby] Drift reconcile: ProfileTemplate store rename (Beta1 reset) — Lobby+disk done, Game PENDING

- **Bootstrap drift check (AD-UI session, Lobby active) caught a mismatch:** live Lobby
  `ProfileTemplate` = `184cdfad`, disk/manifest = `8ac5d3e9`. STOPPED per constitution.
- **Cause (user-confirmed):** intentional **beta data reset** — `STORE_NAME` changed
  `"PlayerData" → "Beta1_PlayerData"` and the Studio dev suffix `"_Dev" → "Dev1"` (dev store
  `PlayerData_Dev → Beta1_PlayerDataDev1`), done directly in the Lobby Studio. No other diff;
  `SCHEMA_VERSION` stays 1, `Towers = {}` unchanged — store target change, no data-shape
  change, no migration.
- **Reconciled the ledger to reality:** disk `shared/src/ProfileTemplate.luau` edited to the
  beta store name (re-hashed to **`184cdfad`**, python fnv1a32 == the Studio drift hash, i.e.
  byte-identical to the live Lobby source). `manifest.json` hash → `184cdfad`,
  `deployed.Lobby → 184cdfad`. `docs/contracts/save-schema.md` store-name line updated with a
  dated note. `deployed.Game` LEFT at `8ac5d3e9` (stale) on purpose — see below.
- **Ownership note:** `ProfileTemplate` is AD-Game canon; this reconcile was done by the AD-UI
  chat under an explicit user directive ("do whatever prevents future problems") to correct a
  stale/dangerous ledger. AD-Game still owns the formal contract re-verification.
- **Contract impact:** save schema stays **v1** (store target only). **CRITICAL PENDING
  (AD-Game + USER):** the Game place was NOT connected this session, so its store name is
  UNVERIFIED. If Game still points at `PlayerData` while Lobby points at `Beta1_PlayerData`,
  the two Places read DIFFERENT stores (split-brain — lobby and match see different profiles).
  AD-Game must open the Game place, deploy the same store name, verify `184cdfad`, set
  `manifest.deployed.Game = 184cdfad`.
- **Open threads:** UI-kit Button/PlayerLevelBar proposal (2026-07-31) still FOR REVIEW.
  Hotbar glow bug not yet investigated (read-only inspection to follow this reconcile).

## 2026-07-18 [game] ProfileTemplate: remove seeded starter Archer (Towers = {}) — starter choice unblocked

- **Shared-module change (owner AD-Game):** `ProfileTemplate.Template.Towers` seed
  `{ Archer = { MetaLevel = 1, XP = 0 } }` → `{}`, per proposal
  `docs/proposals/2026-07-18-starter-choice-template.md`. Fresh accounts now own zero towers, so
  the Lobby's first-join starter choice (eligibility = zero owned) actually fires.
- **No `SCHEMA_VERSION` bump** — default-value change only, no shape change, no migration.
  Existing profiles keep their `Towers.Archer` (`Reconcile()` only ADDS missing keys, never removes).
- **Scope decision:** the blueprint (phase-a A1) had folded this into the schema-v2 session and
  marked the standalone proposal "superseded"; **user explicitly chose the standalone unblock now**
  (this session). A1 will re-touch `Towers` when it migrates to uuid `Units` — no conflict.
- **Drift/deploy:** disk canon + `manifest.json` updated to new hash **`8ac5d3e9`**; source edited
  byte-identical in both Places. Deployed to **BOTH Game and Lobby** (both live sources verified
  `8ac5d3e9` via `.Source`; cache-free "no Archer seed / `Towers = {}`" source check on Game).
  `manifest.json` `deployed` = both `8ac5d3e9`; drift-clean, no stale Place.
  - **Place-binding note (process):** the Studio instances had restarted between sessions and the
    active instance was **Lobby** at the start of this task; the first edit landed on the Lobby
    before I re-resolved binding. Caught via the doc-mirror step, re-confirmed both instances by
    name + PlaceId, then deployed the identical change to Game. Net result is a valid both-Places
    deploy (AD-Game owns shared-module deploys to both), so no rework beyond correcting the manifest
    `deployed` map. Lesson: re-resolve Place binding at the TOP of every task, not just first boot.
- **Docs:** `save-schema.md` new-profile defaults + version history updated (still v1).
- **Contract impact:** save schema stays **v1** (default change only).
- **PENDINGs:** starter-seed PENDING CLEARED. No Lobby redeploy needed (already deployed).
  USER: republish both Places + re-run the live loop (fresh-account picker + towers-in-match).

## 2026-07-18 [repo] Implementation blueprints for all meta phases + blueprint discipline

- NEW `docs/blueprints/phase-a-foundations.md`: schema v2 EXACT shape (unit instances,
  Currencies, Counters, ...) + 1→2 migration steps + starter-seed removal folded in +
  teleport v2 + TierConfig/StatGradeConfig/AscensionConfig/ItemCatalog shapes + base-stat
  ranges & resolver formula (SPA inverted) + icon-kit templates/controller APIs + counters
  pipeline + phase acceptance + session plan A1–A7 with owners.
- NEW `docs/blueprints/phases-b-f-meta.md`: MetaMath (deterministic slot rotation),
  GrantService (single grant pipeline), exact summon algorithm order, per-phase config
  shapes + session plans (B1–F5) + cross-phase invariants checked at Integration.
- Constitution: new "Blueprint discipline" section (blueprints are law; one session-task
  per session; no improvisation; proposal when blocked). Feature prompt updated to match.
- ROADMAP + INDEX link the blueprints.
- **Contract impact:** none yet — blueprints PRE-authorize schema v2 & teleport v2 shapes;
  the A1/A2 sessions execute them under the normal contract protocol.
- **Open threads:** starter-seed PENDING is folded into blueprint task A1 (supersedes the
  standalone proposal); persistence round-trip test still open.

## 2026-07-18 [lobby+repo] Constitution: no UI in scripts; StarterChoiceScreen rebuilt as instances

- **New constitution rule (USER-ordered; recorded here as the authorization for an AD-Lobby
  session touching AD-Integration's repo canon):** NEVER generate UI in scripts. UI = real
  Instances in StarterGui (Studio-editable); dynamic lists = designed `*Template` instance
  (Visible=false) cloned by the controller; controllers do behavior only. Added to
  CLAUDE.md editing rules. Legacy script-built screens are converted when next touched.
- **StarterChoiceScreen converted first:** static tree now real instances —
  `Root{Dim, Panel{Title, Subtitle, CardsRow{CardTemplate}, ConfirmButton}}`; CardTemplate
  is the designed card (NameLabel/TaglineLabel/DescLabel/SelectButton + Sel stroke).
  Controller rewritten to clone/fill/wire only (no Instance.new for visuals).
- **Verified live (Play):** sim ON — Root visible, 4 cards cloned from template
  (Archer/Knight/Mage/SimTestTower), grant path OK; sim OFF — silent boot, sim tower
  auto-cleaned. Sim left OFF.
- **Legacy screens still script-built** (convert when next touched): CollectionScreen,
  StageSelectScreen, PartyScreen, ReturnScreen (Lobby); Game-place screens per AD-Game/AD-UI.
- **Contract impact:** none. **PENDINGs:** unchanged (AD-Game ProfileTemplate starter-seed
  removal still open — user confirmed live test still auto-grants Archer, as expected).

## 2026-07-18 [lobby] Starter tower choice (first join) + launch loadout fix; LIVE e2e confirmed by user

- **LIVE e2e CONFIRMED (user, production client):** lobby → reserved match → return →
  MatchReturn Defeat banner all worked. The Integration session's live-e2e USER PENDING is
  **CLEARED**. The defeat exposed a real bug (below).
- **Launch loadout fix:** `PartyService` sent `Loadout = {}` in every `MatchLaunch`, so
  players entered matches with ZERO placeable towers (Game-side the loadout is the hotbar
  cap — LoadoutValidator, max 6, read-only peek at Game). Now `buildLoadout(userId)` sends
  owned towers (highest MetaLevel first, then alphabetical), capped by new
  `LobbyConfig.MaxLoadoutSize = 6`. Interim until a loadout-picker UI lands. `[DIAG]` logs
  each player's sent loadout at launch.
- **Starter tower choice (first join):** new dev-editable `RS.Configs.StarterTowerConfig`
  (Archer/Knight/Mage; edit that one file to change the offer), new
  `SSS.Server.Lobby.StarterChoiceService` + `Remotes.{GetStarterOffer,ChooseStarterTower}`,
  new modal `StarterGui.StarterChoiceScreen` (3 cards, select + confirm, no dismiss).
  Eligibility = profile owns ZERO towers. Grants `{MetaLevel=1, XP=0}` straight into the
  shared profile; never clobbers an existing record; rejects ineligible/unknown picks.
- **[Test] harness:** `DevSimulateFirstJoin` attribute forces the offer in Studio + adds a
  sim-only "SimTestTower" card to exercise the real grant path; leftover sim tower is
  auto-removed on any non-sim boot. Left OFF.
- **Verified live (Play, dev store):** sim ON — offer shown (4 cards), SimTestTower granted
  (`[DATA] granted starter`), owned Archer pick skipped (no clobber), out-of-offer
  Necromancer rejected, launch `[DIAG]` loadout = 6 towers (Archer first), real teleport
  attempt failed handled in Studio (expected). Sim OFF — silent boot, leftover sim tower
  auto-removed (`[Test]`).
- **Contract impact:** none — teleport stays v1 (payload shape unchanged; Loadout now
  actually populated). Save schema untouched THIS session, but see PENDING.
- **PENDINGs:** NEW (AD-Game): remove seeded starter Archer from `ProfileTemplate`
  (`docs/proposals/2026-07-18-starter-choice-template.md`) — until it lands, fresh accounts
  auto-own Archer and the picker stays inert (by design, data-driven eligibility).
  Integration live-e2e PENDING cleared (above).

## 2026-07-18 [integration] First Integration session: drift-clean both Places, LobbyPlaceId verified, teleport loop config-complete

- **Drift check BOTH Places:** all four shared modules (ProfileTemplate, PlayerDataService,
  ProfileStore, Signal) hash-match `shared/manifest.json` in Game AND Lobby. Zero drift.
- **PENDING cleared — `GameConfig.LobbyPlaceId`:** found already set to **83342803778137**
  in the Game Place; verified equal to the live Lobby instance's `game.PlaceId`. Stale
  "STUBBED 0" comment cleaned (comment-only edit, mirrors last session's Lobby cleanup).
  Teleport loop is now CONFIG-COMPLETE on both sides (Game=125430066355564, Lobby=83342803778137).
- **`[CONTRACT]` verification, Game (Play):** `[MatchEntry] Ready (waiting for MatchLaunch
  teleport data)`, smoke-test fallback single-started Stage1_Act1, `[DATA] [CONTRACT] Profile
  v1 loaded` (PlayerData_Dev, DataStoreState=Access), no contract warnings.
- **`[CONTRACT]` verification, Lobby (Play, DevSimulateReturn ON→OFF):** `[CONTRACT] Lobby
  boot: save-schema v1`, `[DATA] [CONTRACT] MatchReturn v1 accepted (Victory Stage1_Act1 →
  suggest Stage1_Act2)`, ReturnScreen banner + StageSelect pre-select `[DIAG]`s all fired.
  Sim attribute returned to OFF.
- **Cross-Place e2e:** NOT run — real TeleportAsync is impossible in Studio. New USER-ACTION
  PENDING: publish both Places, run the live loop in the Roblox client (lobby → reserved
  match → return → banner).
- **Note (Game, Studio Play):** with LobbyPlaceId set, pressing Lobby in Studio Play now
  attempts a real teleport and fails handled (pcall + TeleportInitFailed) — expected.
- **Contract impact:** none. Teleport stays v1; no shared-module changes; manifest untouched.
- **Open threads:** live e2e (user, above); persistence round-trip test (Game); progressive
  Studio-doc migration. Push pending (commit is local).

## 2026-07-18 [lobby] MatchReturn v1 handling + GamePlaceId set (teleport loop Lobby-side complete)

- **GamePlaceId set:** `RS.Configs.LobbyConfig.GamePlaceId = 125430066355564` (found already set
  in Studio this session — stale STUB comment cleaned). The Lobby-side USER-ACTION PENDING is
  **CLEARED**; real launches now go all the way through ReserveServer + TeleportAsync.
- **MatchReturn v1 receiver:** new `SSS.Server.Lobby.MatchReturnService` (Script). Reads
  `Player:GetJoinData().TeleportData.MatchReturn` on join, validates PayloadVersion==1 /
  LastStageId / Outcome∈{Victory,Defeat,Abandoned} (`[CONTRACT]` warn + ignore on mismatch),
  drops `SuggestNextActId` unknown to the Lobby's StageRegistry mirror (stale mirror fails
  safe), serves per-player via new `Remotes.GetMatchReturn` RemoteFunction. Display-only:
  never mutates the profile (rewards were committed Game-side per the contract).
- **Welcome-back UI:** new `StarterGui.ReturnScreen` banner — outcome (Victory/Defeat/
  Abandoned), stage name, CONTINUE button (only on Victory with a valid successor) + BACK TO
  LOBBY. CONTINUE fires new client bus `RS.ClientEvents.OpenStageSelect` (BindableEvent).
- **StageSelect pre-select:** `StageSelectScreen.Controller` now listens to `OpenStageSelect`
  (opens panel + selects stage) and silently pre-selects `SuggestNextActId` after loading
  stages, so the picker lands on "continue the campaign".
- **Studio harness:** `DevSimulateReturn` attribute on MatchReturnService fabricates a
  Victory/Stage1_Act1→Act2 payload in Studio (`[Test]` log) since real return teleports can't
  happen in Studio. Left OFF.
- **Verified live (Play):** with sim ON — `[Test]` + `[DATA] [CONTRACT] MatchReturn v1 accepted`,
  `[DIAG] StageSelect: pre-selected suggested next act Stage1_Act2`, `[DIAG] ReturnScreen:
  showing MatchReturn banner (Victory)`; CONTINUE path → `[DIAG] StageSelect: OpenStageSelect
  pre-selecting Stage1_Act2`, panel visible, button text "CONTINUE: Rising Legend (Stage 1 -
  Act 2)". With sim OFF — clean boot, no banner, no [DIAG] (silent path confirmed).
- **Contract impact:** none — teleport stays **v1** (Lobby now consumes `MatchReturn`; no shape
  change). No shared-module change; manifest untouched (drift check clean at bootstrap).
- **PENDINGs:** Lobby GamePlaceId CLEARED. Remaining for end-to-end: USER sets
  `GameConfig.LobbyPlaceId` (Game side), then the first AD-Integration session
  (lobby → reserved match → return → banner).

## 2026-07-18 [game] Teleport handoff Game-side: MatchLaunch receiver + real ReturnToLobby

- **Production entry receiver:** new `SSS.Server.MatchEntryService` (ModuleScript, booted by
  `ReplicationBridge` after the data services). Reads `TeleportData.MatchLaunch` (teleport
  contract **v1**) off join data, validates PayloadVersion==1 / StageId∈StageRegistry / Players,
  converts JSON string userId keys → numeric, sanitizes DifficultyPercent (`DifficultyConfig`),
  resolves map/mode/difficulty from the stage, waits for the party to assemble (10s timeout),
  and calls `MatchDirector.StartMatch` **exactly once**. Trust stance per contract: TeleportData
  is a request — loadout ownership + host authority are re-checked downstream (LoadoutValidator /
  MatchDirector). Pure `BuildRawConfig(payload)` exported + unit-tested (valid/reject/clamp cases).
- **Smoke test → Studio fallback:** `MatchLifecycleSmokeTest` still auto-starts Stage1_Act1 in
  Studio, but now stands down when a MatchLaunch payload is present, so the two never double-start.
- **Real ReturnToLobby:** `MatchActionHandler` now builds the `MatchReturn` v1 payload
  (PayloadVersion, LastStageId, Outcome, SuggestNextActId — next act only on a Victory with a
  successor) and `TeleportService:TeleportAsync` back to the Lobby. Guarded on
  `GameConfig.LobbyPlaceId==0` (logs `[Teleport]` + skips, mirroring the Lobby's GamePlaceId guard);
  wrapped in pcall + listens to `TeleportInitFailed`.
- **New `RS.Configs.Global.GameConfig`** — cross-Place counterpart to LobbyConfig:
  `TeleportPayloadVersion=1`, `LobbyPlaceId=0` (stubbed), `HasLobbyPlace()`.
- **Verified:** BuildRawConfig unit tests pass (string→numeric keys, [CONTRACT] rejects for bad
  version / unknown stage / no players, difficulty clamp 999999→1000 & nil→100, MatchReturn
  next-act rule). Play-test: `MatchEntryService` boots + stands down with no teleport data, smoke
  fallback starts the match, single start, no warnings.
- **This Game place id = `125430066355564`** (for the Lobby's `LobbyConfig.GamePlaceId`).
- **Contract impact:** none — teleport stays **v1** (Game is the consumer; no shape change).
- **PENDINGs:** receiver PENDING CLEARED. NEW (USER ACTION): set `GameConfig.LobbyPlaceId` to the
  real Lobby place id. Still open: user sets `LobbyConfig.GamePlaceId=125430066355564` (Lobby side);
  persistence round-trip test; Studio Documentation migration.

## 2026-07-18 [repo] Meta-systems design approved + ROADMAP v2 + constitution advisory

- Meta-systems proposal (docs/proposals/2026-07-18-meta-systems-design.md) reviewed and
  APPROVED with decisions: apex tier **Bathala**; secret rate ~0.005%; dupes → **Ascension**
  (1 dupe + artifacts, or sell for Silver); stat grades **D C B A S SS SSS + Apex**;
  everything untradeable at launch.
- ROADMAP.md rewritten: current Game/Lobby/Cross-Place status + phased meta roadmap
  (A Foundations: schema v2/unit instances + ItemCatalog + icon kit → B Gacha → C Unit
  depth → D Economy loops → E Seasonal → F Endgame/social).
- OWNERSHIP.md: added AD-UI (ItemCatalog/TierConfig/icon kit), AD-Meta, expanded
  AD-Gacha/AD-Traits rows.
- CLAUDE.md landing checklist step 8: mandatory session-end USER ADVISORY (new PENDINGs +
  which chat acts next, other-Place staleness, git push reminder, user personal actions).
- **Contract impact:** none yet — but Phase A = schema v2 + teleport v2 (unit-instance
  uuids); AD-Game owns that migration; no meta work may start before it lands.
- **Open threads:** MatchLaunch receiver + GamePlaceId PENDINGs still open (unchanged).

## 2026-07-17 [lobby] Lobby v1 scene/flow: blockout, collection, stage select, party teleport

- **Blockout:** `Workspace.Lobby` hub (gold plaza + "alamat" sun emblem, pillars, title wall,
  COLLECTION/PLAY wayfinding pedestals); spawn repositioned onto the plaza; modest lighting/atmosphere.
- **Read-only collection screen** (proves profile sharing end-to-end): `Server.Lobby.LobbyServices`
  wires `GetCollection`/`GetStages` RemoteFunctions (READ-ONLY against the profile). Client
  `StarterGui.CollectionScreen` lists owned towers (MetaLevel/XP/Trait). Verified live: returned the
  same PlayerData_Dev profile the Game seeded (8 towers incl. Archer Lv100/Godly, Mage/Blitz, ...).
- **Stage select + difficulty:** Lobby-local mirror `RS.Configs.StageRegistry` (Stage1_Act1..Act3,
  NextActId chaining, difficulty 1–1000). `StarterGui.StageSelectScreen` = stage list + draggable
  difficulty slider capturing (StageId, DifficultyPercent).
- **Teleport handoff (contract v1):** finalized `docs/contracts/teleport.md` v0→v1 — reserved
  (private) server per party, party assembly carried in the `MatchLaunch` payload, `PayloadVersion=1`.
  `RS.Configs.LobbyConfig.GamePlaceId` **stubbed 0** (user to fill). `Server.Lobby.PartyService`:
  in-memory parties (invite/accept/leave, host-only launch, max 4) + `ReserveServer` +
  `TeleportToPrivateServerAsync`; guarded on GamePlaceId==0. `StarterGui.PartyScreen` = party UI
  (members, invite, incoming-invite prompt, leave). Verified live: solo party assembles, launch
  path validates stage + sanitizes difficulty and hits the guard (logs `[Teleport]` would-launch).
- **Contract impact:** teleport payload **v0 draft → v1** (owner AD-Lobby). Save schema unchanged (v1).
- **PENDINGs opened:** (1) user sets `LobbyConfig.GamePlaceId`; (2) AD-Game builds the production
  receiver: read `TeleportData.MatchLaunch` (v1) → validate → `MatchDirector.StartMatch` (replaces
  the Studio-gated smoke test as the non-Studio entry path).

## 2026-07-17 [lobby] First AD-Lobby session: shared-module deploy + boot + Signal promotion

- **Shared deploy (Lobby):** created `ReplicatedStorage.Shared` (Signal, ProfileTemplate) and
  `ServerScriptService.Server.Data` (ProfileStore, PlayerDataService). Sources deployed
  verbatim from `shared/src/`; hashes verified against the manifest via `tools/hash_shared.luau`
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39, ProfileStore 1e3a6f3f, Signal 91becf7a).
  `manifest.json` `deployed.Lobby` filled for all four. No drift.
- **Signal promoted to shared canon:** Signal (a `PlayerDataService` dependency) previously
  lived only in the Game place. Added `shared/src/Signal.luau` (byte-identical to the live
  Game source, 91becf7a), registered it in `manifest.json` (owner: game, covered by the
  shared/src deploys row in OWNERSHIP.md), and added it to `tools/hash_shared.luau`'s MODULE
  list so drift checks now cover it. Game already runs this exact Signal (deployed 91becf7a,
  re-verified live this session).
- **Boot:** new `Server.Bootstrap` (Script) requires ProfileTemplate + PlayerDataService,
  asserts the save contract, and calls `PlayerDataService.Init()`. Verified live in Play mode:
  `[CONTRACT] Lobby boot: save-schema v1, store=PlayerData_Dev` and
  `[DATA] [CONTRACT] Profile v1 loaded for SuperiorBeing_S (store=PlayerData_Dev, DataStoreState=Access)`.
  Confirms the Lobby shares the same schema-v1 profile + dev store as the Game place.
- **Contract impact:** none — save schema still v1 (no shape change); teleport still v0 draft.
- **Open threads:** Lobby v1 scene work next (blockout spawn → read-only collection screen →
  stage select + difficulty → teleport handoff, which finalizes `teleport.md` v0→v1 and adds a
  PENDING for the AD-Game receiver). The Lobby shared-module deploy PENDING is now CLEARED.

## 2026-07-17 [game+repo] Dev-store separation + multi-chat constitution + GitHub prep

- **Dev store:** `ProfileTemplate.GetStoreName()` → "PlayerData_Dev" whenever
  `RunService:IsStudio()`; PlayerDataService uses it. Studio playtests/dev seeds can no
  longer touch production data. Verified live with API access ON:
  `store=PlayerData_Dev, DataStoreState=Access`. Shared canon + manifest rehashed
  (ProfileTemplate 376e717d, PlayerDataService 613f0d39; Game deployed, Lobby still PENDING).
- **Constitution v2:** chats now bound to SYSTEMS (not Places); Place binding resolved at
  bootstrap via `list_roblox_studios` + name confirmation ("Alamat Defense - Game" /
  "Alamat Defense - Lobby"); new multi-chat sync rules (changelog = event bus, re-read
  STATE+changelog before landing, single-writer, no simultaneous same-Place editing).
  New `docs/OWNERSHIP.md` registry (UI, Gacha, PlayerLevel, TowerModels, Enemies, Traits...).
- **Places:** Lobby place created on Roblox (empty); Studios renamed accordingly.
- **Contract impact:** save-schema doc updated with the dev-store rule (still v1 — shape
  unchanged, only store selection).
- **Open threads:** Lobby shared-module deploy still PENDING; persistence round-trip test.

## 2026-07-17 [game] ProfileStore adoption (schema v1) + bug fixes + repo bootstrap

- **Persistence:** adopted ProfileStore (loleris). New `Shared.ProfileTemplate` (SCHEMA_VERSION=1,
  store "PlayerData"; Data = {SchemaVersion, PlayerXP, Currency, Items, Towers, Settings};
  starter Archer Lv1). New `Server.Data.PlayerDataService` (session lock, Reconcile+Migrate,
  ProfileLoaded/Released signals, kick on failed session). `PlayerInventoryService` and
  `SettingsService` rewritten profile-backed with unchanged public APIs; new
  `GrantTower(userId, towerId, trait?)`. Old `PlayerSettings_v1` DataStore retired.
  `ReplicationBridge` boots data services first. Verified live (mock store; clean boot,
  dev-seed merge, match start).
- **Fixes:** MatchDirector `---__--!strict` typo (strict now active); WaveDirector
  unknown-PathId now releases `waveOutstanding` + ForceResolve (auto-advance can't wedge);
  `MatchLifecycleSmokeTest` gated `RunService:IsStudio()`.
- **Cleanup:** Workspace clutter (sample rigs, template, imports) → `ServerStorage.Archive`;
  ProfileStore module Workspace → `Server.Data`.
- **Repo bootstrap:** this repository created; shared canon seeded (ProfileTemplate,
  PlayerDataService, ProfileStore) with verified matching hashes (see `shared/manifest.json`);
  constitution, contracts, contexts, ADRs 0001–0002 written.
- **Contract impact:** save schema v1 established (first version — no migration needed).
  PENDING: Lobby deploy on creation; real-DataStore round-trip test.
- **Open threads:** in-Studio Documentation set still to migrate; teleport contract at v0 draft.
