# CHANGELOG (append-only; newest first)

## 2026-08-28 [lobby] B42 — AD-Gacha/AD-UI: **the Quests and Shop screens, and the two match quests unblocked** — the Lobby meta-UI blocker comes down.

No shared canon touched, so **no drift and no manifest change** (`TOOLVERSION B41-1`, 36/36, `MetaMath = MISSING` in the Game as expected). All Lobby-local; the user republishes.

### The Quests screen (BLOCKOUT, the DailyRewards deal)

`StarterGui.QuestsGUI` + `QuestsController` were scripted as blockout art to a published spec
(`docs/specs/2026-08-28-quests-screen.md`) — the same reversal the user made for DailyRewards at B40:
the server (B40) and the spec were finished and only art was blocking, so the art is scripted and the
spec stays the CONTRACT. Re-authoring the tree keeping the names costs **zero** controller edits.

The controller reads only spec'd names, `need()`-bounds every lookup, clones a `QuestCardTemplate`
per daily quest (name · progress bar · first reward icon+qty with `+N` · Claim · ClaimedTick), opens
and closes on `UIKit.Motion`, toasts refusals via `UIKit.Notify`, and reveals a claim through
`ClientEvents.ShowRewards` (return value, B37). `HUD.Left.Buttons.QuestsButton` fires
`ClientEvents.OpenQuests`, self-wired the SummonController way. `DisplayOrder = 9`. Boot markers in;
ScreenBootWatchdog **26/26 green**.

### The two match quests, unblocked (the B41 one-line pending)

`QuestRegistry.LiveCounters` gained `Clears` + `InsaneVictories`; `ClearThree` (Target 3) reads
**`Clears`, NOT a new `ActsCleared`** (user's call, B41 — two stored numbers for one event is the
drift the one-writer rule prevents), and `WinInsane` (Target 1) reads `InsaneVictories`. **6
assignable of 6, 0 orphans** — the QuestService boot orphan-warning is now silent. Placeholder
rewards/weights, labelled.

### Verified live (Lobby Play)

`GetQuests` renders 3 cards including the new **WinInsane**; the panel sits centred and enabled
(`AbsPos 679,261` · `560×440` in 1919×1079). Claim end-to-end via a real Server Script + the client
remote: a counter bump made `PullOne` **CanClaim=true**, `ClaimQuest` returned `ok` with
`Rewards=[Silver x120]` (Total 1280→1400), and the re-read showed **Claimed=true** — grant-first,
mark-second. The button→`claim()`→`ShowRewards` line is parse-verified and identical to the shipped
DailyRewards claim (a real click is not tool-fireable — the project's standing `Activated` limitation).

### The Battlepass BACKEND (Phase E, no schema bump)

`RS.Configs.Meta.BattlepassConfig` + `SSS.Server.Meta.BattlepassService` (**the one writer of
`Data.Battlepass`**) build the blueprint's seasonal ladder — a FREE and a PAID track, `Level =
floor(XP/XPPerTier)+1`. **No schema bump:** `Data.Battlepass { SeasonId, XP, Owned, ClaimedFree,
ClaimedPaid }` was in the template since v2, unwritten — the `Quests`/`ShopStock` free ride. Remotes
**31 → 33** (`GetBattlepass`, `ClaimBattlepassTier`). SeasonId is a **static string**: when the
stored one differs the service resets XP + claims for the new season (blueprint keying) but keeps
`Owned`. Claims are GRANT-FIRST-MARK-SECOND; Paid requires `Owned`; reveal = return value (B37).

**Two things deliberately NOT built** (both flagged in the config/service headers and
`docs/systems/battlepass.md`): (1) **the XP source** — blueprint commits BP XP at MATCH END, a GAME
change; until then XP moves only through the server-only `ServerStorage.BattlepassAddXP`
BindableFunction, which nothing calls yet (the pre-B41 Quests-counter state). (2) **monetization** —
the paid unlock + level-skips are a gamepass/dev-product decision; `Owned` gates the paid track and
nothing sets it. Content (XPPerTier, 10 placeholder tiers vs the blueprint's 50, rewards) is
PLACEHOLDER, labelled.

**Verified live:** addXP 250 → level 3; Free tier 1 → Silver x100 (again `already_claimed`); Paid
tier 1 while un-owned → `not_owned`; tier 5 while level 3 → `not_unlocked`; `bad_tier`/`bad_track`;
after setting Owned, Paid tier 2 → Silver x200; forcing a stale SeasonId reset XP→0/claims-cleared
while **Owned survived**. Boot clean, no catalogue warnings (all reward ids valid), watchdog 29/29.

### The Battlepass SCREEN (blockout)

`StarterGui.BattlePassGUI` + `BattlePassController`, BLOCKOUT to `docs/specs/2026-08-28-battlepass-screen.md`,
self-wiring `HUD.Right.Buttons.BattlePassButton` → `ClientEvents.OpenBattlepass`. A horizontal tier
track: one column per tier with a FREE (top) and PAID (bottom) reward slot, a header XP bar showing
within-level progress + `Level N / MaxTier` + the `Owned` state, `LockOverlay` on locked tiers, and
the paid Claim gated on `Owned` (the server is the authority — a dim button still clicks and toasts
the reason). Claim → `ShowRewards` (B37). Verified live at Level 4/10: 10 tier cards, tiers 5+ LOCKED,
Free tier 1 → Silver x100, Paid tier 1 → Gold x100 (Owned), Free tier 4 → Gold x75, tier 5 →
`not_unlocked`, re-claim → `already_claimed`; CurrencyBar updated live; watchdog **30/30 green**.

### Two HUD buttons wired (no new backend)

`HUD.Right.Buttons.EventButton` now **deep-links to the DailyRewards EVENT tab** — no event backend of
its own: the DailyRewards screen (B40) already owns both tracks and its controller accepts
`ClientEvents.OpenDailyRewards:Fire("Event")` (its own comment named this button as the intended
source). `HUD.Right.UpperRight.InviteFriendsButton` opens the Roblox game-invite prompt
(`SocialService:PromptGameInvite`, client-only, guarded — the prompt is limited in Studio, distinct
from the in-lobby PARTY invite). Two small additive controllers (`EventButtonController`,
`InviteFriendsController`), no shipped script touched. Verified: both boot, ScreenBootWatchdog **29/29
green**, and `OpenDailyRewards("Event")` opens DailyRewards with the event tab active. The remaining
three HUD buttons (`BattlePass`, `LeaderBoards`, `Inbox`) have **no backend** and are future sessions —
Inbox needs a v5 mail-history field.

### The Shop screen (NPC-opened, BLOCKOUT)

`StarterGui.ShopGUI` + `ShopController`, and a blockout `Workspace.Lobby.NPC_Shop` (Model +
Body/Halo/Root + a `ProximityPrompt`) — the **NPC entry point was the user's call** (the
AscensionScreen/ADR-0010 shape, not a HUD button). The prompt fires `ClientEvents.OpenShop` and is
found via `FindFirstChildWhichIsA("ProximityPrompt")`, so any model named `NPC_Shop` with a prompt
works and a HUD button is a drop-in later. Spec: `docs/specs/2026-08-28-shop-screen.md`. The controller
reads only spec'd names, `need()`-bounded, clones a `ShopSlotTemplate` per slot (icon · name · qty ·
price · Buy · SoldOutOverlay), tier-paints the stroke, shows the Silver balance + a restock countdown,
and reveals a buy through `ShowRewards`. `DisplayOrder = 9`.

**Verified live:** `GetShopStock` rendered the 4 daily slots (Golden Seed, Trait Reroll Token, Gold
x250, Gold x600) with the user's authored icons; the NPC prompt wired (`Shop NPC prompt wired
(Shopkeeper)`); buying slot 3 debited **Silver 1400→1100** and granted **Gold +250** (`Rewards=[Gold
x250]`, the HUD CurrencyBar updated live), the slot marked bought, and a re-buy refused
`already_bought` — PRE-CHECK → SPEND → GRANT → MARK. ScreenBootWatchdog **27/27 green**.

## 2026-08-27 [game] B41 — AD-Game: **the levelling loop, the match quest counters, the three settings actions and an audio owner** — and the pending that had been steering work since B33 was, again, not what it said.

`PlayerLevelConfig` promoted to shared canon (manifest **35 → 36**, `TOOLVERSION B36-1 → B41-1`).
Verified **36/36, 0 issues, both Places**, comparing each live hash to BOTH `hash` and
`deployed.<Place>` in code. Two harnesses, both REAL `Script`s: **17/17** and **10/10**.

### The headline: `PlayerLevel` was frozen at 1, and the fix needed no schema bump

B40 had already corrected the claim that "nothing grants `Data.PlayerXP`" — the Game grants it fine.
The real break was that `AddPlayerXP` was three lines (`data.PlayerXP += xp`) and **never touched
`PlayerLevel`**, because the rollover — `PlayerLevelConfig.ApplyXP` — lived in a **Lobby-only**
module the Game could not require. Every account sat at level 1 forever, and `LoadoutConfig`'s
level-gated hotbar slots (5 at Lv20, **6 at Lv50**) were unreachable by construction.

So: `PlayerLevelConfig` is now shared canon at `2e99d041`, deployed to **identical paths** in both
Places and hash-matched byte-for-byte across repo / Lobby / Game (4721 bytes each). Identical paths
are why this, like B35's settings promotion, cost **zero consumer edits**. The promotion rewrote the
header that argued for it being Lobby-local, which is the whole reason the hash moved off `3d321740`;
the body is byte-unchanged.

`AddPlayerXP` now routes through `ApplyXP` and writes both fields. It remains the **one** place
account XP is applied — the same rule as `GrantService` in the Lobby.

**⚠ THE CONTRACT, restated because two stored fields can otherwise disagree:** `PlayerLevel` is
authoritative; `PlayerXP` is **progress within the current level**, never a lifetime total.

### Old profiles need no migration, which is why v4 survived

`v4` is published, so a new field would have cost a **v5** plus a both-Places publish. It did not
come to that. `ApplyXP` re-reads the stored pair on every call, so a profile that banked a backlog
while the rollover was unreachable **drains it on its next grant** and lands where it always should
have been; a consistent profile is untouched. Proven in the harness: a synthetic `L1 / 5000xp`
profile resolved to `L16 / 240xp` conserving XP exactly (`4760 spent + 240 = 5000`), while
`L1 / 30xp` — the dev profile's shape — did not move. **Nothing was run over live profiles.**

### The quest counters: one of the two already existed under another name

`docs/systems/quests.md` said everything match-shaped "is the GAME place's to write, and none of it
exists". That was **wrong when written**. `RewardCalculator` has incremented `Clears`,
`ClearsByStage` and `Waves` since A8, and `SummonManager` increments `Summons` live.

And a `StageConfig` **is** an act — `Stage1_Act1..3`, chained by `NextActId` — so `Clears` already
**is** "acts cleared". The Lobby's commented-out `ClearThree` wants a counter named `ActsCleared`;
the user's call was that it should **read `Clears`** rather than have the Game write a second key for
an event already counted. Two stored numbers for one event is exactly the drift the one-writer rule
exists to prevent. Only `InsaneVictories` genuinely had to be built (Victory **and** Insane — losing
on Insane is not a win, winning on Normal is not an Insane win).

Shipping both quests is now a one-line Lobby edit. **Counter names are a cross-Place contract:** a
baseline delta needs a lifetime, monotonic counter, and renaming one strands every baseline already
written against the old key — which is why `Clears` was not renamed to match the quest's wording.

### The three settings actions, and why they go through the server

Open since B35, rendering disabled because nothing registered them. `GameSettingsActions` now
registers all three — **no edit to `SettingsUI`**, which is shared canon at `7e5a736a`. That
zero-cost integration is the entire point of `Kind = "Action"`.

`ReturnToLobby` and `RestartMatch` fire the existing `RequestMatchAction` remote rather than calling
`TeleportService` on the client. The teleport contract is a **server** concern: `MatchActionHandler`
builds the `MatchReturn` payload and stamps `GameConfig.TeleportPayloadVersion`. A client-side
teleport would ship an unversioned payload and bypass v4 entirely. One teleport path, one stamp.

Verified from the **rendered UI**, not from a probe: all three rows now read `RUN` with
`Active = true`. (A probe that required `ClientSettings` inside `execute_luau` reported
`hasHandler = false` — a second, empty copy from that VM's own require cache. Exactly the trap the
brief warns about, and worth recording because it looked like a real failure for a moment.)

### `AbortMatch`: an abort pays NOTHING (user's decision)

`Restart` mid-match used to fall through to `startStage(player, nil)` and die on "Unknown stage:
nil" — a button that looked wired and did nothing. Restarting a live match must tear it down first,
because `StartMatch` refuses while `isRunning`.

**The user chose: an aborted run grants nothing at all.** `MatchDirector.AbortMatch` never fires
`MatchEnded`, so `RewardCalculator` is never reached — no XP, gold, drops or counters — and no result
is recorded, so an aborted act cannot then be replayed or continued from. Deliberately **not** a
Defeat: a Defeat pays a consolation, and a restart button that pays a consolation is farmable.

The flag is **consumed by the match loop**, never by the caller's thread: the lifecycle owns every
`Stop`/`ClearAll` and the `isRunning` flag, and two threads racing that teardown is how a wave of
enemies leaks into the next match. Verified live, 10/10: `MatchEnded` never fired, XP/level/gold/
counters all unmoved across the abort, the abort flag did not leak, and a fresh match started
cleanly afterwards.

### The Game finally has an audio owner (open since B32)

`UIKit.Sound` and the whole `SoundService` tree were deployed here and **nothing ever called
`playBGM`**. `GameAudio` is the sibling of `LobbyAudio` and deliberately the same shape: the shared
kit is the machinery, the script only says what this Place plays and when.

Per-act music needs the act id on the client, which was not on the wire, so `MatchStateChanged`
gained **`StageId`** (added to both the snapshot table and `Reset()`). `GameAudio` dedupes on it, so
the many pushes a match produces cost one `playBGM` call per act change — verified in the log:
`Default` at join, `Stage1_Act1` when the match started, back to `Default` on cleanup, once each.

**All 13 SoundIds are still empty, and that is a standing user decision, not a gap** — they are
filled at release. The caller now exists so pasting an id is the only remaining step.

### Two stale comments, one fixed and one deliberately not

`RewardCalculator` claimed the teleport payload "(v2) has NO mode field, so in production this is
always Normal and this branch does not fire". Untrue since **v3** (B20, verified live end-to-end),
and it directly contradicted the `InsaneVictories` counter added a few lines below it. That file is
not shared canon, so the fix cost no hash and no redeploy. The **`RewardScalingConfig`** header
carries the same stale claim and remains open — it *is* canon at `1d789978`, so correcting it
re-hashes and needs a both-Place redeploy.

### The lesson, again, and it is the same one

B40's was "a pending is a claim, and claims go stale". B41 found two more: `quests.md` said counters
did not exist when three did, and `CONTEXT.md` still described the schema as v3. Both were a minute
to check. The corrected pendings are DELETED from `STATE.md` per ADR-0006, not struck through.

### Landing

`shared/manifest.json` (36), `tools/hash_shared.luau` (`B41-1`), `HashShared` re-deployed in BOTH
Places — note it is a **compacted transcription** of the repo tool, not a byte copy, so it was
patched in place rather than overwritten with the repo file. Docs: `STATE.md` (120/120),
`places/game/CONTEXT.md` (150/150), `rewards.md`, `settings.md`, `quests.md`, `ROADMAP`.
**Republish BOTH Places — promoting a shared module is a canon change.**


## 2026-08-27 [lobby] B40 — AD-Gacha: **the two screens, mail, the shop, and quests** — four systems, no schema bump, because three of the fields were already there.

`RS.Remotes` **27 → 31**. Schema stays **v4** (published by the user this session). Shared canon
untouched at 35, verified field-by-field at session start and end.

### No schema bump, for the third time, and it is now a rule

`ShopStock` and `Quests` were **both** in the template since v2 with no writer — exactly like
`LoginStreak` before B38. Checking the schema before designing has now saved three bumps. It is
recorded in `STATE.md` as the pattern to follow, along with what is still unwritten (`Titles`,
`Battlepass`).

That matters more now than it did: **v4 is shipped, so the next new field costs a v5.**

## The two screens

The user reversed the earlier "you author it, I wire it": both servers were finished and only art was
blocking them, so B40 **scripted blockout versions** of `StarterGui.DailyRewards` (two tabs) and
`StarterGui.RedeemCodes` and wired both.

**The published specs are still the contract.** The scripted trees use exactly the names and flags in
`docs/specs/2026-08-27-*.md` and the controllers read nothing else, so authoring real art later is a
**replace, not a rewrite** — keep the names and the controllers need zero edits. Both spec files now
say so at the top.

### `DailyRewardsButton` no longer claims — it opens the screen

At B38 there was no screen, so click-to-claim was the whole feature. With a screen that owns both
tracks, two ways to claim one reward from one button is a coin-flip about which fires. The claim
**moved** rather than being deleted — the screen runs the identical `ClaimDaily` → `ShowRewards`
sequence — and the HUD script keeps only the countdown label, because a countdown you have to open
something to read is useless.

They talk through `ClientEvents.OpenDailyRewards`, resolved **lazily at click time**: the two
controllers boot in an unspecified order and the screen is the one that creates the event, so looking
it up at click removes the race instead of guessing who wins. The event takes an optional tab, so the
HUD's `EventButton` can later deep-link to the event ladder.

### ⚠ A name I got wrong, and the doc that misled me

The HUD button is **`RedeemCodesButton`**. `places/lobby/CONTEXT.md` listed those five abbreviated
(`RedeemCodes`/`LeaderBoards`/…), I looked up the abbreviation, and the first live run said
`no HUD RedeemCodes button found`. The bounded lookup did its job — named the miss and stood down
instead of hanging — and the doc is corrected with a note that **every HUD button name ends in
`Button`**.

### A run where half the screens vanished, and why it was not a defect

One play session reported `6/7 boot script(s) finished`, `StarterGui.Settings is not in this Place`,
and `AscensionController STARTED BUT NEVER FINISHED`. All of it was a transient replication miss
after a fast stop→start: the Edit datamodel still held all 19 ScreenGuis, and a re-run with the same
code came back clean at **25/25**. Worth recording because the failure looked catastrophic and was
not, and because the bounded-lookup machinery from B33/B34 is exactly what made it legible.

## Mail — offline delivery, which finally closes B37's gap for real

`MailService` (module) + `MailDeliveryService` (boot Script) + `DevMail` (harness). No new remote, no
schema field, **and no shared-canon edit**.

B39 established that a grant to a genuinely offline player *cannot happen* — no loaded profile, so
`Grant` has nothing to write to. So this was never a reveal problem; it is a **grant-later** problem.
ProfileStore's `MessageAsync` writes onto the profile **key** (no session needed) and a
`MessageHandler` gets it on the next load — **the grant runs then.**

### ⚠ Why at-least-once does not double-grant

Messages redeliver until `processed()`. That is safe here for one checkable reason: **`processed()`
marks the update locked and ProfileStore persists the profile's data and that lock in the same save.**
Grant and acknowledgement land together or not at all. **So: grant first, then `processed()`** — the
reverse drops mail on the floor when a grant fails. A *validation* failure is acknowledged and
discarded loudly instead, because retrying a config bug every load would warn forever.

`PlayerDataService` is drift-controlled, so this deliberately does not edit it: sending uses its own
`ProfileStore.New` handle, and handlers attach through the already-public `ProfileLoaded` signal.

### Two things the live run corrected

**I assumed mail always arrives mid-join with the client not yet listening. It does not.** ProfileStore
hands over a global update shortly after the profile loads, which for a player who was already online
is a live, fully-booted client — so enqueueing the reveal meant the grant landed and the reveal sat in
the queue until their *next* join. It now uses **`RewardPush.ToOrQueue`**: push if they can receive it,
persist if they cannot. Both cases are real, which is why neither half alone was right. `ToOrQueue`
already existed for exactly this shape.

**And it exposed a B39 bug of mine.** `RevealDrainService` shipped as "client announces → wait 20s for
the profile", quietly assuming the profile always wins that race. A slow DataStore proved otherwise:
the wait expired, the drain gave up, and an owed reveal sat until the next join even though the
profile loaded seconds later. It now records **both** facts and drains when the **second** lands,
whichever it is — no timeout to tune, no ordering assumption to be wrong about.

## The shop — and the economy hole it closes

`ShopConfig` (pure) + `ShopService` (**the one writer of `Data.ShopStock`**), `Remotes` +2.

**Nothing in this game has ever spent Silver.** That was checked, not assumed: every banner costs Gold
(`CostPerPull = 100`), and `GrantService.Spend` — the one debit path — was never called with
`"Silver"` anywhere in the server tree, while B31's dupe-selling **mints** it. A currency with a
faucet and no drain only inflates, and a reward that buys nothing is not a reward.

Stock is **derived, not stored**: `MetaMath.RngForSlot(day, "Shop:"..userId)`, so every server agrees
with no stored roll — the use MetaMath's own header names. Only `Bought` persists, and it **resets**
on rollover rather than merging, because slot 2 yesterday and slot 2 today are different items.

Ordering is four steps and each earns its place: **pre-check the id against `ItemCatalog`** (finding a
typo *after* the debit would charge for nothing), **spend**, **grant**, **then mark bought** — with a
refund through `GrantService` and a loud warning on the unreachable failure, because a silent refund
looks like theft. **The client sends a slot index and nothing else**; the price comes from the
server's own re-roll.

## Quests — built on the two counters that actually exist

`QuestRegistry` (pure) + `QuestService` (**the one writer of `Data.Quests`**), `Remotes` +2.

**Progress is a delta against a baseline**, not a counter read. `Counters.Global.*` are *lifetime*
totals, so a daily quest reading one directly would be instantly complete for any established player,
forever. Assignment records the counter's value as a `Baseline`; progress is `current - baseline`.
That is what makes quests work **today against counters nobody wrote for quests**, with no change to
any service that owns one and nothing added to a hot path. Baselines are written **once per quest per
day** — re-baselining on read would reset progress every time the screen opened, and stay invisible
until someone reported it.

⚠ **Only `GachaPulls` and `Ascensions` exist.** Everything match-shaped is the Game place's to write.
A quest naming a counter with no writer would sit at 0 forever and read as a bug in the quest system,
so `QuestService` **refuses to assign it and names it at boot**, and the two obvious match quests sit
commented out in the registry rather than shipped broken.

## The Game place is now the biggest single blocker

Player XP, every match-shaped quest counter, and the Game's three settings actions all wait on
AD-Game. The Lobby's meta layer has run ahead of what the match feeds it. Recorded in `STATE.md`'s
Next up rather than left implicit.

## Verified live

| system | evidence |
|---|---|
| screens | 25/25 boot scripts; DAILY renders 7 rungs `100/150/1/300/1/500/3` with 1–3 ticked and the button dimmed; EVENT renders `Harvest Moon`, 5 rungs, `Ends in 89d`; tabs switch; `RedeemCodes wired to ...RedeemCodesButton` |
| mail, recipient mid-load | `Mail SENT` → `Mail DELIVERED`, Gold +500 / BannerTicket +2, reveal queued |
| the drain fix | next join: `received 2 reveal(s) owed from a previous session` → `ObtainRewards SHOW` |
| mail, recipient online | pushed immediately, Silver 1050 → 1450, queue `0 queued, 0 dropped` |
| shop | Silver **1450 → 1150**, Gold +250; `already_bought`; `no_such_slot`; `bad_slot`; **insufficient funds left the balance untouched** |
| shop determinism | same user+day identical, other user differs, next day differs, slots distinct |
| quests | established profile starts **0/N**; one real summon advanced all three by exactly 1; claim paid Silver x120; `already_claimed` / `not_assigned_today` / `bad_quest_id` all refused |
| drain path still cannot grant | re-enumerated after every edit: **0** non-comment `GrantService` refs |

## Placeholders, stated plainly

Shop prices and catalogue, quest content and rewards, the three codes, the `HarvestMoon` event, and
B38's 7-day table. All labelled in their files. None is a considered economy decision, and shop
prices in particular should eventually be set against `TierConfig.GetSellValue`, which is what pays
Silver in.

### Two stale pendings found by checking, at the very end of the session

The user asked whether the Game place warranted its own session. Checking rather than answering from
the docs turned up two things the docs had wrong:

**1. "Nothing grants `Data.PlayerXP`" — carried since B33 — is FALSE.** The Game *does* grant it
(`RewardCalculator:113` → `PlayerInventoryService.AddPlayerXP`), and the dev profile really holds 30
XP. The actual break is sharper and worse: `AddPlayerXP` is three lines
(`data.PlayerXP += xp; return data.PlayerXP`) and **never touches `PlayerLevel`**, because the
rollover — `PlayerLevelConfig.ApplyXP` — lives in a module that is **Lobby-only** (`3d321740`, not
shared canon) and is **absent from the Game**.

So `PlayerLevel` is **frozen at 1 forever**, and `LoadoutConfig` gates loadout slot 6 at level 50 —
level-gated slots can never unlock. That is a broken core progression loop that has been mis-filed as
"not built" for seven sessions. The fix needs `PlayerLevelConfig` promoted to shared canon
(manifest **35 → 36**), which is why it is a Game-place session and not a continuation here.

**2. `StarterGui.ConfirmationPopupUI` is already in the Game** — a complete 23-descendant tree with
every part `UIKit.Confirm` looks for. `STATE.md` still listed copying it as a user pending. Flagged
for the user to confirm rather than silently resolved, per their standing rule.

Both corrected in `STATE.md`. The lesson is the cheap one: **a pending is a claim, and claims go
stale.** Neither was expensive to check.

### Handoff

`claude/B41-next-session-prompt-AD-GAME.md` (in the project). B41 is an **AD-GAME** session: the
levelling fix, the match quest counters that unblock B40's quest system, the three settings actions
open since B35, and the Game's missing audio owner.

## Standing instructions recorded this session

- **The empty SoundIds are DELIBERATE and are no longer a pending** (user, B40): all 13 get filled at
  **release**. Silence in development is expected. Same standing class as the 0.05
  `UIHoverStroke.Thickness` — do not re-raise either.
- **Schema v4 is published to both Places** (user, B40).

## Still outstanding

- **AD-Game:** player XP, match quest counters, the three settings actions, the Game's audio owner.
- Shop and Quests have **no UI**; `BattlePass`/`Event`/`LeaderBoards`/`InviteFriends`/`Inbox` unwired.
  An Inbox **screen** needs a stored message history, which is a **v5** field — mail itself does not.
- C4 feeding still blocked on data.
- `StarterGui.Summon` is the user's unfinished work — **do not touch**.
- `SellButtons.CancelButton` overlaps `QuickSellButton`; `PlayButton` wears the Shop logo.
- The dev profile still carries a dead `BannerChoices["B29ProbeBanner"]`.

## 2026-08-27 [both] B39 — AD-Gacha: **event dailies, redeem codes, and the pending-reveal queue** — on one schema bump, after repairing a drift two of my own sessions walked past.

Four things the user picked in one go. Everything below is Lobby-local except the schema, which is
shared canon and deployed to both Places. `RS.Remotes` **25 → 27** (`ReadyForReveals`, `RedeemCode`).
The B39a commit (`dc0e0a5`) carries the drift repair and the bump; this entry covers the systems
built on top.

### The drift repair, first, because it was mine

`UIKitBootstrap` hashed `9c9539c0` in the Lobby and `f930ff7b` in the Game **and the manifest**.
Diffed, the delta was exactly **B36's paired `BootComplete` marker block**: B36 instrumented the
Lobby's 21 boot scripts, **one of which is shared canon**, and neither mirrored it into the Game nor
re-hashed the manifest. B36 and B37 then both closed reporting "drift green 35/35".

Mirrored; all three copies (repo file, Lobby, Game) now hash `9c9539c0` byte-for-byte. The marker is
inert in the Game — it has no `ScreenBootWatchdog` and the marker only sets an attribute — so this is
a hash repair, not a behaviour change.

**What actually caught it was changing how the check is read.** The same tool run had "looked green"
for two sessions. This time each entry's live hash was compared to **both** `hash` and
`deployed.<Place>`, field by field, in code. A drift check you eyeball is a drift check that passes.

### One schema bump, three systems

`EventLoginStreaks` + `RedeemedCodes` + `PendingReveals`, v3 → v4, `ProfileTemplate`
`72d3944f → 8e4224b9`, hash-matched in both Places the same session. `Migrations[3]` is a deliberate
no-op for the same reason `[2]` is: `Reconcile()` runs before `Migrate()`.

Three separate bumps would have meant three migration steps and three both-Places publishes. **The
cost of a schema bump is the publish, not the field.** If a fourth system needs a field before v4
ships, it goes into v4 rather than opening v5.

Verified on a **fresh clone** of the module, because `execute_luau` caches requires and returned the
pre-edit copy on the first attempt — reporting `SCHEMA_VERSION=3` against a source that already said
4. Then verified live: `Migrated ... forward 1 step(s) to v4`, `DataStoreState=Access`, the three keys
at their defaults, and Gold 465 / Silver 400 / `LoginStreak Day 2` / 8 units untouched.

## The pending-reveal queue — and a correction to B37

`PendingReveals` (**the one writer of `Data.PendingReveals`**), `RewardPush.ToOrQueue` / `.Drain`,
`RevealDrainService`, `Remotes.ReadyForReveals`. Doc: `docs/systems/reward-push.md`.

### ⚠ B37's "known gap" was mis-stated, and correcting it changes what can be claimed

B37 recorded it as *"a grant made while the player is AWAY is never revealed"*. Reading the data layer
shows that cannot happen: `PlayerDataService.profiles` only ever holds players in **this** server, so
`GetData(userId)` is nil for anyone else and **`GrantService.Grant` has nothing to write to**. There
is no unrevealed offline grant to recover, because there is no offline grant.

So B39 does not close that gap as worded. What it fixes is real but narrower: the player **leaves
between the grant and the push**, the push fails for a transport reason, or the push is attempted
before the client is listening. Delivering to a player in **no** server needs ProfileStore's
**`MessageAsync`** channel — the grant itself would run on their next load. That is mail, it owns a
grant path, and it is not built.

I would rather record a smaller true claim than a larger one that reads well.

### ⚠ Draining must never grant, and that is enumerated

Every queued row describes a grant that already happened and is already in the player's balances. If
the drain ever calls `GrantService`, rejoining pays twice. `PendingReveals`, `RewardPush`,
`RevealDrainService` and `RewardPushReceiver` contain **zero** non-comment `GrantService` references;
the only server modules that require it are `AscensionService`, `DailyRewardService`, `SellService`,
`SummonService` and two Studio harnesses. One grep, re-checkable, worth more than the assertion.

### ⚠ The drain is a client-announced handshake, not a `ProfileLoaded` hook

The obvious implementation is wrong and silently so. `RewardPushReceiver` connects
`PushRewards.OnClientEvent` during the client's boot, and **`FireClient` does not queue for a client
that is not yet listening**. Draining on profile load would push into nothing, report success, clear
the queue, and show the player nothing — the exact failure the feature exists to prevent,
reintroduced at the last step. So the client fires `ReadyForReveals` **after** its connect, and only
then does the server deliver. In the receiver that `FireServer()` sits below the connect on purpose.

`RewardPush.To` is unchanged and still owns no storage, because B37 promised that and it is
load-bearing. Overflow **refuses** new rows rather than evicting old ones (`MaxQueued = 100`), and
`Dropped` records the refusals so the drain can say "+N more" instead of lying by omission. Drain
pushes **first** and clears second, restoring the rows if the push fails.

Verified live across a real session boundary: grant+queue moved the balances with **no reveal shown**;
a flood offered 115, stored 98, refused 17; the rejoin produced
`RewardPush -> ... (reason=pending_reveals)` → `ObtainRewards SHOW n=2` → `REVEALED`; the queue then
read `0 queued, 0 dropped`.

## Redeem codes (server side)

`CodeRegistry` (pure) + `CodeService` (**the one writer of `Data.RedeemedCodes`**) +
`Remotes.RedeemCode`. Doc: `docs/systems/redeem-codes.md`.

### ⚠ Every code is public, and that is a design constraint rather than a bug

`CodeRegistry` replicates, so any client can read the codes, rewards and windows. A code is a
**convenience, never a secret** — it is the same string for everyone and gets posted publicly the day
it ships; its only real protection is the per-player "redeemed once" record. If a reward must not be
obtainable by everyone who reads the client, it does not belong in a code. Moving the module server
side would hide the strings, change nothing about that, and cost the client the ability to grey out an
expired code without a round trip.

### ⚠ The rate limit is security, not UX

A redeem box is a remote that takes an arbitrary string and pays out on a match — an unlimited one is
a code-space enumerator answering thousands of guesses a second. **1.5s between attempts** makes
guessing cost wall-clock time; **20 failures per session** caps what patience buys. A *successful*
redeem does not count (ten valid codes must all be enterable), and neither does `already_redeemed` —
re-pasting a used code is the most common thing that will ever happen to this remote, not a guess.

`Normalize` is the one place typing becomes a key: trimmed, uppercased, refused past 32 characters
because **the result becomes a profile key** and without a bound a client could grow a player's own
save with junk. GRANT FIRST, MARK SECOND — marking first would consume the one redemption and pay
nothing.

Verified live: `"  alamat  "` normalised and granted; the same code again refused; **still refused
after a server restart**; expired refused; unknown refused; a second code immediately hit `too_fast`
and then succeeded after the gap.

## The event daily track

`EventDailyConfig` + `DailyRewardService` extended (now **also the one writer of
`Data.EventLoginStreaks`**). Doc: `docs/systems/daily-rewards.md`.

### ⚠ Additive on the wire, because a live screen was already reading it

The B38 HUD controller is deployed and working. It reads `CanClaim` / `Day` / `SecondsUntilReset` at
the **top level** and invokes `ClaimDaily` with **no arguments**. So every top-level field still means
the permanent track, the event hangs off a new `Event` sub-table, and `ClaimDaily("Event")` is the
opt-in. Reshaping into `{ Normal = ..., Event = ... }` would have been tidier and broken a live screen
for no player-visible gain. Checked rather than assumed: with the event track live the deployed label
still read `"Resets in 09:53:33"` and the top-level fields still described the permanent ladder.

### A date window, not a banner (the user's call)

Driving the event off the live gacha banner would mean an event ladder cannot exist without a banner,
and that **ending a banner silently deletes a ladder players are part-way through**. Only one event
may be live, and that is enforced: `ActiveEvent` sorts ids, returns the first live one and **warns by
name** if another overlaps, because two ladders sharing one claim button have no defined answer to
"which am I claiming". Sorted ids mean every server picks the same event with no coordination.

**Event ladders do not wrap.** The permanent one repeats `(day % 7) + 1` forever; an event stops at
its last rung, or a limited-time event pays its final row every day until it expires. Missing a day
still resets to 1, kept identical to the permanent track so players do not learn the rule twice.

Verified live: `active event = HarvestMoon (5 rungs, 89 day(s) left)`; claim → day 1/5, Silver x200;
double-claim refused; **the permanent track unchanged at `Day=3 Streak=3`** — the ladders are
independent; last rung stays put with `Complete=true`; missed days and a corrupt streak both reset.

### A syntax error the pre-flight caught before it ran

`;(readyForReveals :: RemoteEvent):FireServer()` as the **first** statement of an `if` block —
"Expected identifier when parsing expression, got ';'". The same trap that took the B35 deploy down,
caught this time by the parse-only probe (wrap the source in `return function() ... end`, which
compiles without running) rather than by a broken client.

## Placeholders, stated plainly

The three codes, the `HarvestMoon` event and its rewards, and B38's 7-day table are all **placeholder
content**, labelled as such in their files. None is a considered economy decision.

## Not built: the two screens

`StarterGui.DailyRewards` and `StarterGui.RedeemCodes`. Both servers are complete and tested; both
screens need authored art (B26 — art cannot be scripted across). Specs written and handed over:
`docs/specs/2026-08-27-daily-rewards-screen.md` and `docs/specs/2026-08-27-redeem-codes-screen.md`.
Once `StarterGui.DailyRewards` exists, `HUD.Right.Buttons.DailyRewardsButton` changes from
claim-on-click to open-the-screen, and claiming moves to its `ClaimButton`.

## Docs

`reward-push.md` and `redeem-codes.md` are **new**; `rewards.md` was over its 300-line cap again, so
the B37+B39 push material moved out of it — that file is AD-Game's match-end payout contract and the
push path is Lobby machinery. Same split `gacha.md` took at B30 and `daily-rewards.md` at B38.
`INDEX.md`, `STATE.md`, `ROADMAP.md`, `save-schema.md` and `places/lobby/CONTEXT.md` updated; every
capped file re-measured and back within cap.

## Still outstanding

- **10 of 13 SoundIds are still empty** — the game is silent.
- **AD-Game must register the Game's three settings actions.**
- C4 feeding is blocked on data.
- `BattlePass` / `Event` / `LeaderBoards` / `InviteFriends` / `Inbox` unwired.
- `StarterGui.Summon` is the user's unfinished work — **do not touch**.
- `SellButtons.CancelButton` overlaps `QuickSellButton`; `PlayButton` wears the Shop logo.
- The dev profile still carries a dead `BannerChoices["B29ProbeBanner"]`.

## 2026-08-27 [lobby] B38 — AD-Gacha: **daily rewards.** The first of B37's four unblocked buttons to ship — and the worked example of when *not* to use B37's push path.

**Place asserted before every write.** Everything added is **Lobby-local** — B38 touched no shared
canon path, nothing was re-hashed. `RS.Remotes` **23 → 25**. Save schema unchanged at **v3**.
⚠ The end-of-session drift check came back **34/35, not 35/35** — see *Drift found* below. It is not
B38's doing and it is not the user's.

### ⚠ Drift found at the end-of-session check: `UIKitBootstrap`

The Lobby's copy hashes **`9c9539c0`**; the Game's copy and the manifest both say **`f930ff7b`**.
Diffing the two, the delta is **exactly B36's paired boot-marker block**.

So: B36 instrumented the Lobby's 21 boot scripts with `BootComplete` markers. **One of those 21 is
shared canon** — `UIKitBootstrap` — and B36 neither mirrored the change into the Game nor re-hashed
the manifest. B36's own entry says "manifest stays at 35; one shared file re-hashed, `SettingsUI`".
That was wrong: **two** shared files were re-hashed and only one was noticed.

Recording it rather than fixing it here, for two reasons. `UIKitBootstrap` is **AD-UI's** module, and
a Lobby session must not deploy into the Game unilaterally (the same rule that stopped B22 from
pushing `ItemCatalog` across). The fix is mechanical — mirror the marker block into the Game's copy,
confirm both hash `9c9539c0`, then update the manifest's `hash` and both `deployed` entries — and it
belongs to AD-UI or an Integration session. Logged in `STATE.md`.

Worth stating plainly: **this is a bug two of my own sessions walked past.** B36 and B37 both recorded
"drift green 35/35" at their close. The check that caught it is the same one they ran; what changed is
that this time it was diffed against the manifest field by field instead of eyeballed.

### Four pieces

| piece | what it is |
|---|---|
| `RS.Configs.Meta.DailyRewardConfig` | PURE rules: the 7-day table, the day number, the streak arithmetic |
| `SSS.Server.Meta.DailyRewardService` | **THE one writer of `Data.LoginStreak`**; owns `GetDailyState` + `ClaimDaily` |
| `StarterGui.HUD.DailyRewardsController` | the button: live countdown, click to claim, reveal |
| `SSS.Server.Meta.DevDailyRewind` | Studio-gated harness; rewinds `LastClaimDayNumber` and nothing else |

### Reading the schema first deleted the biggest piece of work

The obvious plan was a `LoginStreak` field, a v3 → v4 migration, a `Migrations` step and a
publish of **both** Places. None of that was needed. `ProfileTemplate` has carried
`LoginStreak = { Day = 0, LastClaimDayNumber = 0 }` **since v2, with no writer at all** — the field
was added and then never used.

So B38 is a Lobby-local feature on an unchanged schema. The general lesson is not "check the
template"; it is that **designing before reading invents work that the codebase has already done**,
and a schema bump is expensive enough to be worth ten minutes of reading to avoid.

### ⚠ It deliberately does NOT use `RewardPush`

I pitched this session partly as *finally giving B37's push path a real caller*. It is not one, and
the honest thing was to say so rather than bend the design to justify last session's work.

The user chose **claim from the button**. B37's own rule then decides it: *player's own click → the
**return value**; server decided → **`RewardPush`***. A claim is a click. So `ClaimDaily` returns
`Rewards = views` and the **client** fires `ShowRewards` — the same path summon and sell already use.
Pushing here would reveal the same rewards twice the day anything else starts pushing.

**Consequence, recorded plainly: the push path still has no production caller.** Its first real one
will be something the player did not initiate — a login grant, an inbox gift, a redeemed code.

### The rules live in the config, not the service

`DailyRewardConfig` is pure and total, so the service, the HUD countdown and a future 7-day track
screen cannot disagree about which day a player is on.

- **The day number is `MetaMath.Slot(Daily, ResetOffsetSec)`** — cross-phase invariant 3, the same
  call `BannerRegistry.CurrentDay()` makes. The client never computes it: a client that disagreed
  would show "ready" against a server saying "already claimed".
- **Miss a day and the streak resets to 1** (the user's call). `NextDay` returns `(day % 7) + 1` only
  when `last == today - 1`. Every other case returns 1 — which also covers a first claim *and* a
  corrupt stored streak, because a bad value must not be able to hand out day 7 forever.
- **The reward table is PLACEHOLDER BALANCE**, marked as such in the file. The user accepted it to
  unblock the build and will retune it. It is not a considered economy decision and should not be
  quoted as one.

### GRANT FIRST, MARK SECOND

`Grant` validates and can refuse; the mark cannot. Marking first would let a refused grant still burn
the player's day. Same ordering rule as `GrantService.SellUnits` (credit before destroy): **do the
fallible thing first.** An `inFlight` guard is belt-and-braces — `Grant` is documented non-yielding,
so the check → grant → write window cannot interleave today; the guard exists so that if a yield is
ever introduced there, a double-click becomes a *refusal* rather than a double grant.

### A bug the verification found, which reading would not have

`stateFor` returned `NextDay(...)` unconditionally. For a player who has **already claimed today**
that reports **1**, whatever day they actually took.

`NextDay` is not wrong — it is answering a different question. Its `last == today - 1` test cannot
hold when `last == today`, so a same-day call legitimately falls through to "start the cycle over".
That is the right answer to *what comes next* and the wrong answer to *which day am I on*. A 7-day
track screen reading it would have lit day 1 for a player who had just claimed day 5.

`Day` now means **the day the track should highlight**. It was invisible in the source and showed up
only as a live `{Streak: 2, ClaimedToday: true, Day: 1}`.

### The harness had to be a real server Script

`DevDailyRewind` rewinds `LastClaimDayNumber` **only** — never `Day`, never a grant, never a claim
mark — so every rule under test still comes from the config and the service.

It could not be done from `execute_luau`. That runs in a separate Lua VM with its **own require
cache**, so requiring `PlayerDataService` there returns a second, empty copy holding no profiles —
`GetData` sat at `nil` for twenty seconds before I recognised it. Rewinding that copy would have been
testing a re-implementation: the B36 mistake exactly, one session later, in a new disguise.

The same VM boundary explains the session's first scare. The initial `DailyRewardService` probe
reported `parse-clean=false`, which looked like a syntax error in a freshly written 122-line file. It
was not: the probe required the source as a **ModuleScript**, and `OnServerInvoke` cannot be assigned
outside a real server. Re-probing with the source wrapped in `return function() ... end` **compiles
without running** — that separates a parse error from a runtime one, and it came back clean.

### Verified live, through the real server

| case | result |
|---|---|
| first claim | day 1, Gold x100, Gold 265 → 365, reveal ran |
| double claim | `{ok=false, reason="already_claimed"}` |
| streak advance (claimed yesterday) | day 1 → **day 2**, Silver x150, `Streak` 2 |
| **missed a day** (streak was 2) | resets to **day 1**, Gold x100 |
| `Day` after the fix | `{Streak: 2, ClaimedToday: true, Day: 2}` |
| deployed label | `"Ready to claim!"` on a claimable join; `"Resets in 11:30:18"` → `11:30:15` 3s later |
| watchdog | `23/23 boot script(s) finished` — the new controller is instrumented and counted |

The **day-7 → day-1 wrap** is verified at the config layer only (`NextDay(7, today-1, today) = 1`).
Walking a live profile through seven consecutive days was not worth the round trips and the service
passes `streak.Day` straight through — recorded here rather than left to look like full coverage.

### RESOLVED (user, B38): the live two-client v4 queue run

Open since **B23** — the longest-standing unknown in the project. `ReserveServer` is 403 in Studio,
so the cross-server handoff could never be proven from here. The user confirms it is verified. The
pending is deleted from `STATE.md` and from `Next up`.

### Still outstanding

- **10 of 13 SoundIds are still empty** (`UI.Hover`/`Click`/`Open` assigned; the rest and all five
  BGM slots empty) — the game is silent.
- **AD-Game must register the Game's three settings actions** (`RestartMatch`/`ReturnToLobby`/
  `TeleportToSpawn` render disabled; `ReturnToLobby` must respect teleport contract v4).
- C4 feeding is blocked on data (`docs/proposals/2026-08-20-c4-feeding.md`).
- `HUD.Right` still unwired: `BattlePass`, `Event`; and `RedeemCodes`, `LeaderBoards`,
  `InviteFriends`, `Inbox` under `UpperRight`.
- `StarterGui.Summon` is the user's unfinished work — **do not touch**.
- `SellButtons.CancelButton` overlaps `QuickSellButton`; `PlayButton` still wears the Shop logo.
- The dev profile still carries a dead `BannerChoices["B29ProbeBanner"]`.

### Docs

`docs/systems/daily-rewards.md` is **new** — split out of `rewards.md`, which was on its 300-line
cap and is AD-Game's match-end payout doc anyway (the same split `gacha.md` took at B30).
`INDEX.md`, `STATE.md`, `ROADMAP.md` and `places/lobby/CONTEXT.md` updated; all four back within cap.

## 2026-08-21 [lobby] B37 — AD-Gacha: **the push-reveal path.** The server could grant a player anything and had no way to show them. Four buttons were blocked on that one missing direction.

**Place asserted before every write.** Drift green **35/35** at session start and end. Everything
added is **Lobby-local** — shared canon did not change, nothing was re-hashed, the Game is not stale.
`RS.Remotes` **22 → 23**. Save schema unchanged at v3.

### The gap, stated precisely

Every reveal in the game worked the same way, and it was easy to miss why that was a limitation: the
**client** invoked a remote, the remote **returned** reward views, and the client fired
`ClientEvents.ShowRewards` with them. Summon, sell and ascension all do exactly this, and it is a
good design for a grant the player *asked for*.

It cannot serve anything the **server** starts. A daily reward, a redeemed code, a completed quest, a
gift in an inbox — none of them have an invocation to return from. There was no push remote and no
server-side reveal path of any kind. That is why `RedeemCodes`, `Inbox`, `DailyRewards` and `Quests`
were all sitting in the HUD unwired: not four separate missing features, **one missing direction**.

### Three small pieces

| piece | what it is |
|---|---|
| `RS.Remotes.PushRewards` | RemoteEvent, server → client |
| `Server.Meta.RewardPush` | `RewardPush.To(player \| userId, views, reason?) -> ok, why?` |
| `StarterPlayerScripts.RewardPushReceiver` | listens, fires `ClientEvents.ShowRewards`, nothing else |

### ⚠ Opt-in, and why that was the important decision

The tempting design is to have `GrantService` reveal every grant automatically — one line, every
caller gets it free. It was put to the user and rejected, and the reasoning is worth keeping:
**summon and sell would then reveal twice**, once from the return value they already use and once
from the push. Fixing that needs a suppression flag on every existing caller, and *a suppression flag
someone forgets is a double popup in front of a player*.

Opt-in makes the double reveal **impossible by construction rather than by discipline**. That
distinction is the whole point — a rule enforced by structure survives people forgetting it, and a
rule enforced by remembering does not.

It was then **verified by enumeration rather than asserted**: the only live reference to
`RewardPush.To` in the entire server tree was the test harness, with `SummonService` still revealing
through `Rewards = views` exactly as before. That is a claim the next session can re-check in one
grep, which matters more than my saying it holds.

**The rule, and it greps:** if the player's own click caused the grant, the **return value** reveals
it. If the server decided, call **`RewardPush`**.

### `ObtainRewardsGUI` did not change at all, and that was the goal

A server-initiated reward is not a new *kind* of reveal — it is the same reveal with a different
origin. So the correct amount of new code inside the reveal surface is **zero**. The receiver is a
pure adapter: remote in, BindableEvent out. The surface keeps its B4 contract ("fire it, never
rebuild it") and has no idea a network exists.

It also already **queued** batches, so a push arriving mid-reveal was safe for free — a case I would
otherwise have written handling for and probably got subtly wrong.

### Rules `RewardPush` enforces

- **Grant first, push second**, and callers hand over the **same `views` array `Grant` returned**,
  unchanged. One view shape, one producer. `RewardPush` builds no reward rows and must not start.
- **Never reveal a grant that failed** — demonstrated rather than assumed (below).
- **Oversized lists are split, never truncated** (`MaxPerMessage = 25`). Silently dropping rewards a
  player has already been granted would leave them permanently unaware of something they own.
- **Malformed rows are dropped loudly**, naming the caller's `reason`: a row needs a string `Id` and
  `Kind`, or the popup opens on a blank cell — a bug that reads as the game's fault, not the caller's.

### The harness, and why it had to exist

There is no daily reward or code system yet, so there was **no real caller to test with**. The lazy
option is to call `RewardPush` from tooling — and that is precisely the mistake that cost B34 a
watchdog which never ran and two sessions of false confidence, because `execute_luau` is a separate,
more privileged VM. Testing a fresh copy of a module in a different VM is not testing the deployed
one.

So `Server.Meta.DevRewardPush` (Studio-gated) performs the real flow from inside the real server:
grant through `GrantService`, then push the returned views. What gets exercised is the actual module,
the actual remote and the actual receiver.

**It earned its keep on the first run** by catching my own wrong assumption. I had read `Grant`'s
*internals* (`p.id`, `p.kind`, `p.qty`) and built the harness against those. The public contract,
documented in the comment directly above the function, is `{ Id = "Gold", Qty = 250 }` — capitalised,
with `kind` derived from `ItemCatalog` and never passed. `Grant` returned `bad_grant_id_1` and
**nothing was pushed**, which incidentally proved the refusal path works: a reveal for a grant that
did not happen is a lie to the player.

One more thing worth writing down because it wasted a cycle: an attribute a **client** writes on
`ReplicatedStorage` does not replicate to the server. The first harness trigger looked completely
inert for exactly that reason.

### Verified live

A server-initiated grant moved **Gold 15 → 265** and **Silver 0 → 100** on the real profile, and the
reveal opened showing `Gold x250` and `Silver x100`, with the CurrencyBar updating off B33's
`CurrencyChanged` ping at the same time.

- **Contract impact:** `RS.Remotes` **22 → 23** (`PushRewards`). Shared canon **unchanged** at 35
  entries — everything here is Lobby-local. Save schema unchanged at **v3**.
- **Known gap, deliberately not built:** a grant made while the player is **away** is never revealed.
  `RewardPush` returns `player_not_in_server`; the grant is already safe on the profile and they will
  see the balance next time they look. Persisting unseen reveals needs a queue on the profile (a
  schema change) plus an overflow rule, and must not be improvised inside `RewardPush`, which is
  presentation transport and owns no storage.
- **Now unblocked but unbuilt:** DailyRewards, RedeemCodes, Inbox, Quests — each still needs its own
  data (a reward table, a code registry, per-player redemption tracking).
- **Open threads (`STATE.md`):** AD-Game's three settings actions still render disabled · 10 of 13
  sound ids empty · C4 feeding blocked on data · `StarterGui.Summon` untouched, as asked.

## 2026-08-21 [lobby+game] B36 — AD-Gacha: **B35 proven in the Lobby, and a correction that matters more than the fix.** The watchdog built at B34 had never run once, and the reason it went unnoticed was a bad verification, not a subtle bug.

**Places asserted before every write.** Drift green **35/35** at session start. `SettingsUI` re-hashed
(shared canon), manifest stays at 35, `TOOLVERSION B35-1 → B36-1`, both Places byte-identical.

### The Lobby settings screen came alive

The user copied `StarterGui.Settings` into the Lobby — the one thing B35 could not do, because
copying a ScreenGui between Places is a user action (B26). Everything else had been deployed and
waiting, so nothing needed writing to make it work. It built on the next boot:

```
[SettingsService] Ready (profile-backed, Lobby place, 6 preference(s) in scope).
[LobbySettingsActions] Ready (1 action registered: TeleportToSpawn).
[SettingsUI] HUD SettingsButton wired.
[SettingsUI] Initialized (Lobby place, 6 row(s), 5 categor(ies)).
```

**6 rows here against the Game's 11, from the same file**, with no Place-specific branch anywhere —
which was the whole design claim, now observed rather than argued. `TeleportToSpawn` rendered
**enabled**, which also proves the repaint-on-open fix: the registrar is a *separate* script, so a
build-time-only paint would have left it reading "N/A". And `MusicVolume` showed **25%** — the value
set in the **Game** last session. The cross-Place round trip works in both directions.

### The correction: a watchdog that never ran, and a verification that never tested it

The console carried a line that had been there since B34:

```
The current thread cannot read 'Source' (lacking capability PluginOrOpenCloud)
Script 'Players.<name>.PlayerScripts.ScreenBootWatchdog', Line 59
```

`ScreenBootWatchdog` classified scripts by reading `script.Source`. **A LocalScript cannot read
`Source` at runtime** — it needs plugin/Open Cloud capability. So the script threw on that line at
*every boot* from B34 until now, and reported nothing at all. The mechanism built specifically to
make silent failures loud was itself failing silently.

**The B34 changelog claims "Verified live: clean baseline at 19/19 with zero false positives, and
clearing one script's marker to simulate a hang produced exactly one named STUCK report." That was
true, and it was worthless.** The check ran inside an `execute_luau` VM — *which has plugin
capability*. What got verified was a **re-implementation of the logic in a more privileged context**,
not the deployed script. The deployed script was never executed successfully even once.

**Testing a copy of the code somewhere more privileged is not testing the code.** That is the durable
lesson, and it generalises past this project: any verification that re-implements the thing under
test is measuring the re-implementation. The tell was available the whole time — a warning in the
console on every single boot, in the same output that was read repeatedly across three sessions.

### The fix is smaller and better than what it replaces

Two markers instead of one, and no `Source` read anywhere:

- `script:SetAttribute("BootComplete", false)` as the **first executable line**.
- `script:SetAttribute("BootComplete", true)` as the **last**.

The watchdog then reads a tri-state that a LocalScript is always allowed to read: **nil** = never
instrumented · **false** = started and hung · **true** = finished. That is strictly *more* precise
than the old marker-scan, because `false` is positive evidence the script actually began executing,
where "carries the marker in its source" only ever proved it had been edited.

### The second trap, caught by checking instead of assuming

The first sweep prepended the marker block to all 21 scripts — **above `--!strict`**. The mode
directive must stay on line 1 or Luau silently drops strict mode across the whole file. Nothing
errors; the file just quietly stops being strict.

It was caught by verifying the edit rather than trusting it — counting how many instrumented scripts
still had the directive on line 1, and getting **0 of 21**. Reverted and re-inserted *after* the
directive, then re-verified: 21 of 21 correct. Worth stating plainly because it is the same class of
mistake as the watchdog itself — an edit that appears to succeed while silently removing a guarantee.

`SettingsUI` is shared canon, so its start marker re-hashed it `8e899dab` → `7e5a736a`; applied to
the repo and both Places and confirmed byte-identical, with the deployed drift tool re-run in each.

### Result

```
[DIAG] ScreenBootWatchdog: 21/21 boot script(s) finished after 15s.
```

First time that line has ever appeared. Zero false positives — Roblox's own injected LocalScripts
(`FreecamScript`, `PlayerScriptsLoader`, `RbxCharacterSounds`) are correctly ignored, and the three
"uninstrumented" and "stuck" buckets are both empty.

- **Contract impact:** none. Manifest stays at **35**; `SettingsUI` `8e899dab` → `7e5a736a` in both
  Places, `TOOLVERSION B36-1`. Save schema unchanged at v3, `RS.Remotes` unchanged at 22.
- **Resolved:** B35's "copy `StarterGui.Settings` into the Lobby" (the user did it) and the B34
  watchdog defect.
- **Open threads (`STATE.md`):** AD-Game still needs to register the Game's three settings actions
  (`RestartMatch` / `ReturnToLobby` / `TeleportToSpawn` render disabled there; `ReturnToLobby` must
  respect teleport v4) · 10 of 13 sound ids still empty · C4 feeding blocked on data ·
  `HUD.Right`'s six unwired buttons · `StarterGui.Summon` remains the user's unfinished work,
  untouched.

## 2026-08-20 [lobby+game] B35 — AD-Gacha: **one settings system for both Places.** A proposal that had been open since B6 turns out to have been cheap all along — and building it surfaced two bugs that had been quietly live the whole time.

**Places asserted before every write.** Shared canon changed: `shared/manifest.json` **31 → 35**,
`TOOLVERSION B34-1 → B35-1`, both Places re-deployed and hash-matched byte-for-byte. Drift green at
session start and end. Resolves `docs/proposals/2026-08-09-unified-settings-both-places.md`.

### The proposal's own first step was "do not design against a guess"

That instruction earned its keep immediately. The proposal worried that a persisted preference would
mean a **save-schema bump** — the contract protocol, a migration, a PENDING for the other Place. It
also flagged one sentence of the user's as ambiguous and said to confirm it before building.

Reading first settled both, and both landed on the cheap side:

- **`Data.Settings` has been `{ [string]: any }` since v1.** New keys are additive by construction,
  so there is **no bump, no migration, nothing to publish in lockstep.** The most expensive-looking
  part of the job did not exist.
- The clipped sentence — *"there will be a button for 'Restart Match' and 'Return to lobby' and 'TP
  to Spawn', but only 'TP to spawn'"* — meant what the proposal guessed: the Game shows all three,
  the Lobby shows only Teleport to Spawn. Ten seconds of asking, as promised.

### Identical paths are the whole trick

The Game already had all four pieces. The instinct was to move them somewhere tidier —
`ReplicatedStorage.Shared` — but **five Game scripts require `ClientSettings` by a relative path**
(`script.Parent.Parent.Settings.ClientSettings`): `VFXController`, `WavePrepUI`, `EnemyHealthbars`,
`SummonHealthbars`, `SettingsUI`. Moving it meant editing five working files in another owner's Place
for no behaviour change at all.

So nothing moved. Every module was promoted **exactly where it already sat**, and the Lobby grew the
same `Client/Settings` and `Client/UI` folders to match:

| module | path (identical in both) | hash |
|---|---|---|
| `SettingsConfig` | `ReplicatedStorage.Configs.Global.SettingsConfig` | `5f0dc44d` |
| `SettingsService` | `ServerScriptService.Server.Settings.SettingsService` | `8b3b1a72` |
| `ClientSettings` | `StarterPlayer…Client.Settings.ClientSettings` | `a3a9d32f` |
| `SettingsUI` | `StarterPlayer…Client.UI.SettingsUI` (LocalScript) | `8e899dab` |

Promotion cost **zero consumer edits**. `SettingsUI` is a LocalScript hashed as source — the
`UIKitBootstrap` precedent, already established at B6.

The one genuine code change promotion required: `SettingsService` required `PlayerDataService` by a
*relative* path that only resolves in the Game's folder layout. It is now absolute, which works in
both Places because `PlayerDataService` is itself canon at a fixed path.

### `Scope` and `Kind`, and the line that matters most

Two fields per schema entry carry the user's whole requirement. **`Scope`** (`Both` / `GameOnly` /
`LobbyOnly`) decides where an entry is *shown*; **`Kind`** (`Preference` / `Action`) decides whether
it *persists*.

The consequence is the part worth stating: **`SettingsUI` contains no Place-specific branch
anywhere.** It asks `SettingsConfig.EntriesFor("All", place)` and draws the answer. A Place
difference is a config field, permanently. Verified live: the Game renders 11 rows across 5 tabs, the
Lobby renders 6, from the same file.

**⚠ And then the trap, which is the single most important line in the system.**

One profile serves both Places. The obvious implementation of `Scope` is to filter in `Sanitize` —
and it would have been a data-loss bug of the worst kind. The moment a player changed *any* setting
in the Lobby, every `GameOnly` preference they had — `AutoSkipWave`, `ShowHealthBar`, `EnableVFX`,
`SimplifyHealthBar` — would be sanitized out of the payload and **permanently lost**. And the reverse
in the Game. Silent, gradual, and irreversible.

So `Sanitize` processes **every** `Preference` regardless of `Scope`, always. `Scope` is a rendering
concern and nothing else. It is commented as such in the file, in the manifest, and in the system
doc, because it is exactly the kind of thing a future reader would "optimise".

It is proven rather than asserted. Down the real remote, from the real client: a Game-side save left
the `LobbyOnly` `SkipRevealAnim` intact, and a `MusicVolume` of 0.25 set in the **Game** was read
back and applied in the **Lobby**. That round trip is the system working.

The same test threw a hostile payload at it — an out-of-range number, a wrong type, an Action key and
an unknown key. Clamped to 1, defaulted to 1, and both junk keys dropped.

### Two bugs that were already live

**The volume slider controlled nothing.** `ClientSettings` drove a SoundGroup named `MasterSFX`.
That group has never existed in either Place — B32 created `SoundService.Groups.Master > UI/SFX/BGM`.
Confirmed by looking rather than assuming: `SoundService:FindFirstChild("MasterSFX")` is nil and the
`SFXVolume` attribute it published was nil too. There are now three sliders, one per real group, and
a missing group is **skipped rather than created** — inventing audio routing behind the player's back
is worse than a slider that visibly does nothing.

**Settings silently reverted to defaults on join.** The client fetches once at boot and caches the
answer for the session. That fetch regularly landed *before* ProfileStore finished loading, `Get()`
fell through to `Sanitize(nil)`, and the player spent the whole session with their real settings on
the server and default ones on screen — which is experienced as *"my settings reset every time I
join"*, with nothing in the log to explain it. `OnServerInvoke` now calls `WaitForData` first.

This one was caught by a number that did not match: the server reported `MusicVolume 0.25` while the
BGM group sat at `0.5`. Both halves were individually plausible; only the comparison showed the bug.

### Actions

An Action is a button, not a preference — it persists nothing, and `Sanitize` skips it, because
storing a button press as a preference is how a "Restart Match" ends up saved to a profile.

*What* an action does is Place-specific, so the config **declares** actions and each Place
**supplies** behaviour via `ClientSettings.RegisterAction`. An action with no handler renders
**disabled** and says "N/A". The Lobby registers `TeleportToSpawn`, aimed at the real
`SpawnLocation` found at call time rather than a coordinate written down here that would stop
matching the moment the scene moved.

The Game's three are deliberately **not** registered by this session. `ReturnToLobby` has to respect
teleport contract v4, and inventing that is precisely the kind of cross-owner guess this project's
proposal protocol exists to prevent. They render disabled, honestly, until AD-Game wires them.

A subtle ordering bug got fixed before it shipped: action buttons were painted once at build, but
handlers are registered by *separate* scripts and LocalScript run order is not guaranteed — so a
registrar running second would leave the button reading "N/A" forever. They repaint on every open.

### Two syntax lessons, learned the hard way

The first deploy took down both the service and the panel, and both were my own style:

- A statement beginning with `(` parses as a **call to the previous line**. Luau reports "ambiguous
  syntax" and refuses to load the module — which took the entire settings service down with it.
- A leading `;` is **not a legal way to start a block** in Luau at all, unlike Lua 5.4.

Both are now avoided by binding typed locals once, and both are commented in the file so the next
person does not rediscover them. A compile pre-flight (require a `ModuleScript` copy and read the
error) now runs before deploy rather than after.

- **Contract impact:** shared canon 31 → 35, both Places, `TOOLVERSION B35-1`. `RS.Remotes` **21 →
  22** (a `Settings` folder holding `GetSettings` + `SaveSettings`). **Save schema UNCHANGED at v3.**
  New system doc `docs/systems/settings.md`; the B6 proposal is marked RESOLVED.
- **Also this session:** the five `HUD.Right.UpperRight` buttons the user added (`RedeemCodes`,
  `LeaderBoards`, `InviteFriends`, `Inbox`, `Settings`) are tagged `UIKitButton` at their request, so
  they hover, click and sound like every other button. Only `Settings` is wired.
- **User decision recorded:** the six/nine HUD buttons' `UIHoverStroke.Thickness` of `0.05` is
  **deliberate** — "disregard it, its fine". It is no longer a pending and should not be re-raised.
- **Open threads (`STATE.md`):** the user copies `StarterGui.Settings` into the Lobby (art is a user
  action) · AD-Game registers the Game's three actions · the 13 sound ids are still 10 empty (Hover,
  Click and Open now have ids) · C4 feeding still blocked on data · `StarterGui.Summon` is the user's
  unfinished work and was not touched.

## 2026-08-20 [lobby+game] B34 — AD-Gacha: **two kit modules promoted, and a watchdog instead of a 334-site sweep.** The toast fork B33 created lasted exactly one session, four copies of a camera-framing formula became one, and the fix for silent boot hangs turned out not to be timeouts.

**Places asserted before every write** (ids had rotated again; neither was active at bootstrap).
Shared canon **DID** change: `shared/manifest.json` **29 → 31**, `TOOLVERSION B32-2 → B34-1`, both
Places re-deployed and hash-matched byte-for-byte. Drift green at session start and end.

### The fork closed after one session, on purpose

B33 ended with `NotificationController` existing **twice**: the Game's original at
`Client.UI.NotificationController` (used by `PlacementController` and `TowerSelectionUI`), and the
Lobby's copy at `StarterPlayerScripts.NotificationController` (used by Units, Summon, Ascension).
Different paths. Neither in the manifest. **Only the Lobby's hardened.**

That is not a small untidiness — it is precisely the failure the shared-canon system exists to
prevent, and it was left open with a PENDING rather than fixed at the time. A fork that survives one
session survives ten: the two copies had already diverged in hardening, and the next divergence would
have been behavioural.

**`UIKit.Notify` (`5e2b09d4`, manifest entry 30)** is now the one. Both copies are retired by
**rename** — `*_RETIRED_2026-08-20`, following the existing `Hotbar_RETIRED_2026-08-06` convention —
rather than deleted: deleting the user's file is the user's call, and a renamed module stays visible
in the Explorer instead of vanishing from a session's mental model.

**The API was deliberately not changed**, and that is what made this cheap: repointing all five
consumers was ONE line each, and roughly twenty `Notify.Error(...)` / `Notify.Success(...)` call
sites were never touched. Keeping the local variable name `NotificationController` in the two Game
scripts meant their thirteen call sites did not move either.

It takes `UIKit.Confirm`'s shape exactly: the **module** is shared canon, the **GUI** it drives
(`StarterGui.Notifications` — `Container` + `CardTemplate`) stays per-Place authored art, because art
cannot be scripted and copying a ScreenGui between Places is a user action (B26). It is a CLIENT
module, so a server require warns and degrades to print-only rather than erroring — a misplaced
require should cost a toast, never a boot.

### `UIKit.UnitCard`: the duplication was measured, not assumed

Four screens each carried their own `setViewportModel` and `paintTier`: Units, Summon, Index,
Ascension. The standing PENDING said "Units should shape the controller", which is a design opinion.
Before acting on it, the four copies were extracted and diffed:

- **`setViewportModel`** — Summon, Index and Ascension were **byte-identical to each other**. Units
  differed in exactly one way: the *source* of the model (its own `modelFor` helper, which handles
  ascended forms, instead of an inline clone).
- **`paintTier`** — again byte-identical across those three. Units additionally ran the idle sheen and
  forced the hover stroke off.

So the shared function takes the **model** rather than a tower id, and the differences that were real
became two flags: `paintTier(root, tier, {Idle, StrokeOff})`. Everything else merged exactly.
**`UIKit.UnitCard` (`bd2421c5`, entry 31)**, −104 lines across the four consumers, and the local
wrapper functions kept their names so no call site changed.

The point is not line count. Four copies of a camera-framing formula is four places for it to drift,
and **that drift is silent**: a card framed slightly differently on one screen doesn't error, it just
reads as an art bug nobody files. `Framing{FieldOfView, DistancePadding, DistanceBias,
HeightFraction}` is now the single place to retune it.

Two details preserved from the originals because they were load-bearing: the WorldModel is cleared
**before** the nil check (a recycled card must not keep showing the previous unit even when there is
no new model), and the UIGradient lookup stays **direct-child** (V2 nests further gradients under
`UnitLevel` / `PlacementPrice` / `TraitIcon`, so a recursive find repaints the wrong thing).

### Why 334 bare `WaitForChild` were NOT given timeouts

This was the session's most consequential decision, and it went against the obvious answer.

B33 lost the entire Units screen to a bare `WaitForChild` pointing at a deleted instance. The
follow-up written into STATE was "334 bare vs 23 timed, NOT swept" — and the tempting B34 task was to
sweep them. It was costed instead: ~100 of those are authored-instance lookups across 14 *working*
files, every one of which would then need its downstream uses made nil-tolerant. That is a larger
diff, and a larger regression surface, than the bug it prevents — in files that currently work.

**And it would have been aimed at the wrong thing.** The defect at B33 was never the missing timeout.
It was that the failure was **silent**: no error, no stack, one `Infinite yield possible` line buried
in a wall of healthy boot output, and it was missed. A timeout sweep would have converted a silent
hang into a silent *nil dereference* in most of those files.

So the fix targets silence:

- 18 boot scripts each end with `script:SetAttribute("BootComplete", true)` — one line, appended
  after their existing final statement, no logic touched.
- **`StarterPlayerScripts.ScreenBootWatchdog`** waits 15 seconds, then emits **one `warn` per script**
  that carries the marker and never reached it. One warn each, not a combined line, because a
  combined line is exactly the kind of thing that gets scrolled past.
- Scripts named `*Controller` with **no** marker are reported separately — an uninstrumented script is
  invisible to the check, and a check with a blind spot nobody knows about is worse than no check.
- Roblox's own injected LocalScripts (`FreecamScript`, `PlayerScriptsLoader`, `RbxCharacterSounds`)
  are filtered by name. **A watchdog that cries wolf on every boot is a watchdog everybody learns to
  ignore**, and that failure mode is quiet too.

The list of candidates is **discovered, not hardcoded** — a hardcoded list rots the first time someone
adds a screen, and a rotted list reports nothing while looking healthy.

This is diagnosability chosen over prevention, knowingly. A screen can still hang. It can no longer
hang *quietly* — and it now catches hangs from causes a timeout sweep never would: a remote that
never returns, a yield in a script nobody has written yet. The `need()` rule from B33 still governs
anything touched from here.

Verified live: clean baseline at **19/19** with **zero** false positives, and clearing one script's
marker to simulate a hang produced exactly one named STUCK report, then restored cleanly.

### C4 feeding: a proposal, not a skeleton

The session's fourth task was to build a feeding skeleton. Scouting killed it, and the honest output
is `docs/proposals/2026-08-20-c4-feeding.md` rather than code: `ItemCatalog` has **no** `FeedValue`,
there is **no** unit XP curve anywhere, and **nothing writes** `UnitInstance.XP`. Every piece of
machinery feeding would reuse already exists (`UnitConsumeRules`, `GrantService.SpendItems`, the
multi-select UI, `Confirm`, `Notify`) — the missing part is entirely data.

Building the service now would mean a remote that refuses every call because its config is empty, and
a config whose *shape* is a guess: is food per-tier, per-stage, flat, or diminishing? Each answer
implies a different table, so the skeleton would be rewritten the moment the real shape arrived. The
proposal records the design, the reuse, and one thing worth flagging: feeding makes the standing
"a unit at `MAX_META_LEVEL` loses stored XP" bug **reachable by a player** rather than theoretical.

Also noted there: the protections asymmetry. Selling destroys the unit; feeding destroys the *items*.
Reusing `UnitConsumeRules.IsConsumable` unchanged would wrongly block feeding a locked or favourited
unit, so feeding needs a narrower predicate — the kind of thing that is cheap to get right on paper
and expensive to discover after shipping.

- **Contract impact:** shared canon 29 → 31 (`UIKitNotify` `5e2b09d4`, `UIKitUnitCard` `bd2421c5`),
  both Places carry both, `TOOLVERSION B34-1`. `RS.Remotes` unchanged at **21**. Save schema unchanged
  at **v3**. No Place-specific behaviour changed for any existing user-visible feature.
- **Retired (renamed, not deleted):** `StarterPlayer.StarterPlayerScripts.Client.UI.NotificationController`
  (Game) and `StarterPlayer.StarterPlayerScripts.NotificationController` (Lobby).
- **Open threads (`STATE.md`):** C4 blocked on data · no XP granter and the 627k level-50 curve
  (B33) · the user's `StarterGui.Summon` is unfinished and untouched · `HUD.Right`'s three buttons
  unwired · and the three B32 asset items still outstanding, which the user has asked to be reminded
  of every session: **the 13 sound ids** (the game is silent), **`ConfirmationPopupUI` into the Game**,
  and the **nine `UIHoverStroke.Thickness` values still at 0.05**.

## 2026-08-20 [lobby] B33 — AD-Gacha: **the Units screen was dead.** A deletion I had recommended, six lookups that could not fail safely, and no error message anywhere. Plus toasts across the Lobby, a live currency bar, and the exp bar wired to a real curve.

**Place asserted before every write:** `PlaceId 83342803778137` + `Workspace.Lobby` present. Studio ids
had rotated again and NEITHER instance was active, so `list_roblox_studios` + `set_active_studio` came
first. **NOTHING SHARED CHANGED THIS SESSION** — the drift report was taken at the start AND at the end
and is byte-identical, all 29 entries (`MetaMath` Game = null, expected). No re-hash, no manifest edit,
**the Game is not stale by this session.** Everything below is Lobby-local.

### The failure, in order, because every step looked reasonable

1. B32 retired B31's itemised `SellConfirm` panel — the global `ConfirmationPopupUI` replaced it.
2. B32's closing advisory told the user it was "now unused and deletable".
3. The user deleted it. Correctly. They were doing exactly what they were told was safe.
4. Six `gui:WaitForChild("SellConfirm")` calls were still sitting at the top of `UnitsController`.
5. **A bare `WaitForChild` never times out.** The controller stopped at declaration one.
6. The entire Units screen never finished booting — no grid, no equip, no favourite, no sell.

There was no error. No stack. No red text. `UnitsController ready` simply never printed, and the only
evidence in a wall of healthy-looking boot output was a single `Infinite yield possible` line.

**The lesson is not "add timeouts".** It is that *recommending a deletion without grepping for the
readers is half an advisory*. B32 checked that nothing USED the panel functionally and missed that six
lines still LOOKED FOR it. Those are different questions and only one of them got asked.

### `need()` — and why a detached stand-in beats a nil check

Authored-instance lookups in `UnitsController` now go through one helper:

```lua
local function need(parent, name, className)
    local inst = parent:FindFirstChild(name)
    if inst == nil and parent:IsDescendantOf(game) then inst = parent:WaitForChild(name, 5) end
    if inst == nil then
        table.insert(sellMissing, parent:GetFullName() .. "." .. name)
        local stub = Instance.new(className); stub.Name = name; return stub   -- DETACHED
    end
    return inst
end
```

Three decisions in there worth stating. The **stand-in** means a missing frame turns
`.Visible = false` into a harmless no-op instead of an `attempt to index nil` — the alternative was
nil-guarding ~30 use sites across a 1,476-line file, which is a bigger diff and a bigger risk than the
bug. The **`IsDescendantOf(game)` guard** stops a stand-in's children from each burning the full
timeout; without it one missing frame costs 5s per child it was meant to contain. And `sellMissing`
collects every failure so ONE warn line names them all — the answer to "why is Quick Sell dead?" belongs
in the console, not in a diff of the Explorer against the script.

The feature then **refuses to arm** (`sellEnabled`) rather than half-working. A sell UI that is missing
its Cancel button should say so, not let a player into a mode they cannot leave.

**Deliberately NOT done:** a scan found **334 bare `WaitForChild` calls against 23 timed** across Lobby
scripts. They were not swept. Most sit on infrastructure whose absence means the screen is meaningless
anyway (`Main`, `Bottom`, the remotes folder), and a 334-site mechanical rewrite of working boot code
risks more than it fixes. The count is recorded as a PENDING and the rule applies to anything touched
from here. Scope honestly stated beats a sweep nobody can review.

### Toasts: adopted Lobby-wide, with one rule that stops them being wrong

The user copied the Game's toast system into the Lobby — the authored `StarterGui.Notifications` plus
`StarterPlayerScripts.NotificationController` — and asked for it "in the whole lobby ... instead of the
'hint' text label". `Notify.Error / Success / Warning / Info`, cards stack in a `UIListLayout`, cap at 5,
auto-dismiss at 3.5s.

`UnitsGUI` was the easy half: `setSellStatus` was already the ONE funnel all 17 sell messages went
through, so **changing its body moved every one of them onto toasts without editing a single call site.**
That is precisely why it was a function instead of 17 inline label writes, and it is the second time this
session that a past decision about single-definition paid for itself.

`SummonScreen` and `AscensionController` needed a judgement call, and it became a rule:

> **TOAST EVENTS, LABEL STATE.** A toast erases itself after 3.5 seconds. That is right for something
> that HAPPENED — refused, failed, sold, ascended — and actively wrong for something that IS TRUE.
> "This banner is blocked" and "this DESTROYS 1 duplicate" are conditions; wiping them off the screen
> after 3.5s is worse than never having shown them.

So those two screens toast only when the call site names a `kind`, and always write their label. Every
funnel still writes the label, so a Place with the toast GUI deleted degrades to the old behaviour
exactly. `NotificationController`'s own three lookups were hardened the same way as `need()` when the
Lobby started depending on it: **a missing toast system must cost toasts, never a screen.**

One landmine found while patching: `SummonController` **already had** a local `setStatus`, declared
inside the B30 Selection-choice closure and writing a different label. Lua scoping resolves both
correctly, but two same-named functions writing different labels in one 850-line file is a trap, so mine
is `setSummonStatus`.

### The currency bar's own comment asked for this fix months ago

`CurrencyBarController` carried this since it was written: *"When a shop or gacha lands, give it a
RemoteEvent and call `refresh()` from that — do not poll."* Both landed. Summoning spends and selling
credits, so "nothing spends Gold or Silver" had quietly stopped being true and the bar read stale until
the next rejoin.

`Remotes.CurrencyChanged` (**20 → 21**) is a server→client ping with **no payload**. That is the load-
bearing choice: ADR-0004 makes `GetUnitViews` the single Lobby profile read path, so shipping a balance
on this event would create a second source of truth free to disagree with it. The event says "something
changed"; the client re-reads through the one path.

It lives in **`GrantService`** for the same reason `Spend` does — invariant 1 puts every currency write
there, so it is the only place an announcement can live without adding a second thing to grep for. Put
it in the callers and the day someone adds a third write site the bar goes stale again and nothing says
so. **Debounced per user via `task.defer`**, so a `Grant` writing several currencies in one loop sends
ONE ping; deferring also means it lands *after* the write, which is what makes the client's re-read see
the new value instead of the old one.

Verified live: Silver **385 → 395 within 0.6s** of a sale, no rejoin.

### The exp bar, and the two numbers I refused to invent

The user's authored `ExpBar` is now driven by real data: `Data.PlayerLevel` and `Data.PlayerXP`, both
already served by `GetUnitViews` since A5 and never displayed until now.

The curve did not exist anywhere in the project. The authored label read `Level 1 (0 / 100)XP` and that
100 was a designer placeholder, so I stopped and asked rather than picking a number — inventing balance
data is exactly what this project's placeholder-price episode was about. The user chose a gentle
exponential, and **`Configs.Meta.PlayerLevelConfig`** is now the ONE definition:
`100 × 1.15^(level-1)`, rounded to 10, retunable by three constants.

It is **Lobby-local on purpose.** `LoadoutConfig` is shared because both Places must agree which hotbar
slots are unlocked — but they key that off the STORED `Data.PlayerLevel`, not off a curve, and nothing
in the Game reads one because nothing anywhere grants player XP. Promoting a config with exactly one
consumer buys a permanent drift obligation for no present benefit; it gets promoted the day the Game
awards XP. `ApplyXP` is there, uncalled, so that when a granter arrives the rollover rule already has
one definition instead of being invented at the call site.

Two consequences recorded rather than smoothed over:

- **The bar reads 0 forever.** Nothing writes `PlayerXP` — verified, the only assignments anywhere are
  the ProfileTemplate defaults. That is not a bug in the bar. The user's intent is filed: small XP per
  wave cleared, decent per stage clear, big for a first clear, smaller for repeats, owned by the Game's
  match-end path.
- **Level 50 may be unreachable.** The chosen curve costs **627,540 XP** cumulatively to reach it —
  ~12,500 stage clears at ~50 XP each — and `LoadoutConfig` gates the 6th hotbar slot at exactly level
  50. Flagged as a balance PENDING rather than silently shipped; three numbers fix it.

- **Contract impact:** `RS.Remotes` **20 → 21** (`CurrencyChanged`). Save schema UNCHANGED at v3.
  Nothing shared changed, so no re-hash and no manifest edit. New Lobby-local
  `Configs.Meta.PlayerLevelConfig`; new `StarterGui.ExpBar.ExpBarController`.
- **Also:** `HUD.Right`'s second `EventButton` renamed to **`DailyRewardsButton`** at the user's request,
  matched by its label TEXT and never by child order — the two shared a name, which is what makes dot
  access pick an arbitrary one. Two stale `-- CURRENT ####` markers left on the B28 section of BOTH
  Places' `ServerStorage.Documentation.AIState` by earlier sessions were demoted; each file had been
  claiming two current states.
- **Open threads (`STATE.md`):** no XP granter · the 627k level-50 curve · promote `PlayerLevelConfig`
  when the Game grants XP · `NotificationController` now exists in both Places, in different paths, in
  neither manifest, with only the Lobby copy hardened · 334 bare `WaitForChild` · the user's new
  `StarterGui.Summon` is UNFINISHED and must not be touched · `HUD.Right`'s three buttons are unwired ·
  and all of B32's user-side items still stand (13 sound ids, `ConfirmationPopupUI` into the Game, the
  0.05 hover strokes, the `CancelButton` overlap, `PlayButton`'s Shop logo, the Game's missing audio owner).

## 2026-08-19 [lobby+game] B32 — AD-Gacha: **the shared feedback layer.** Hover, click, sound and confirmation became kit-level concerns instead of per-screen ones, and the Lobby's sell UI moved onto instances the user can edit without running the game.

**Place asserted before every write:** `PlaceId 83342803778137` + `Workspace.Lobby` present for Lobby
writes; absence of `Workspace.Lobby` + `RS.Configs.Towers` present for the Game. Studio's ids had
rotated again and **neither instance was active at bootstrap**, so `list_roblox_studios` +
`set_active_studio` came first. **Shared canon DID change this session** (5 entries), so both Places
were re-deployed and re-hashed: `shared/manifest.json` 27 → 29 entries, `TOOLVERSION B29-1 → B32-2`.
Every changed entry proven **byte-identical across repo / Lobby / Game**: `UIKitMotion`
`a104e59d → 2d217ede`, `UIKitButton` `9728e897 → 30da2e10`, **new** `UIKitSound` `108ef36e`, **new**
`UIKitConfirm` `999c40f3`, `Kit_UnitIconV2` `0bf1a11e → bf39c6c8`.

### Detection beat configuration

The user rebuilt `HUD.Left.Buttons` from scratch as rectangle panels, which renamed every screen's
entry point: **`UnitsButton` / `SummonButton` / `PlayButton` / `InventoryButton` / `QuestsButton` /
`ProfileButton`**. `Play` had simply vanished and `ShopButton` had taken its place, so for part of the
session the Play menu had **no entry point at all** and PlayGUI said exactly that in the console —
which is the only reason it was caught rather than shipped.

The new feel is: hover grows `Main.UIHoverStroke` to its authored thickness, an idle `UIGradient`
rotation spins continuously while shown or hovered, `Main` scales up slightly, `LogoContainer` tilts
45°, and a click dips then pops. The obvious implementation is a config table listing which buttons
are "the new kind". That was rejected. **`UIKit.Button` DETECTS panel-style instead**: if the content
root carries the `UICorner`/`UIStroke` furniture that the button itself lacks, the button is a panel
and the CONTENT ROOT is what scales. The consequence is the point — the **~55 already-tagged buttons
changed behaviour not at all**, while the six new ones get the whole treatment with zero per-button
setup. `ButtonStyle` ("panel") and `HoverStrokeThickness` attributes override the guess when the
heuristic is wrong, so detection is a default and never a trap.

`Main` scaling without disturbing its `UIListLayout` siblings is `Motion.isolate` doing the job it was
built for at B27. Verified by measurement, not by eye: on hover `Main.UIScale` read **1.07** while the
next button's `AbsolutePosition` stayed at `0, 517.142517` — unchanged to the decimal.

### Three primitives, and why `growStroke` owns `.Enabled`

The constitution forbids a fourth animation dialect, so everything with a curve went into
`UIKitMotion`: **`pressPop`**, **`spinGradient`/`stopSpin`**, **`growStroke`** — plus `StrokeGrowTime`,
`GradientSpinPeriod`, and the four click-timing values in `Motion.Tuning`, which stays the one place to
retune feel.

`growStroke` owning `UIStroke.Enabled` is the load-bearing detail: it enables the stroke **before**
growing and disables it only **after** shrinking. A disabled `UIStroke` tweening `Thickness` animates
nothing at all — that was the B27c hotbar bug, and it is now written down in `ui-feedback.md` as a
hazard rather than remembered.

`spinGradient` caches the authored base rotation in a `UIKitBaseRotation` attribute and is idempotent,
so re-entering hover cannot stack tweens. Verified live at ≈4s per turn: `462 → 504 → 192 → 240 → 282`.

### Audio with no config file

`UIKit.Sound` deliberately has **no configuration module**. It resolves real `Sound` instances **by
name** under `SoundService`, so "assign the lobby BGM" means pasting a SoundId onto an instance in the
Explorer — the thing the user asked for, and the thing that does not require a code change per track.
`play(name, category?)`, `playBGM(name, opts?)`, `stopBGM`, `setCategoryVolume`, and a `report()` that
prints what resolved and what did not. `playBGM` **no-ops if that track is already playing** (so a
re-entry cannot restart the music), cross-fades otherwise, and falls back to `BGM.Default` when the
requested name is missing. Base volume is cached in `UIKitBaseVolume` so a fade cannot become the new
volume. The tree is authored in both Places: `Groups/Master > UI/SFX/BGM`, 8 UI sounds, and BGM slots
`Lobby` / `Default` / `Stage1_Act1-3`. `UIKit.Button` plays `HoverSound` on `MouseEnter` and
`ClickSound` on `Activated`, so every tagged button in the game is already wired.

### One confirmation dialog for two Places

The user authored `ConfirmationPopupUI` and asked for it to be used **globally, including in the Game**,
so `UIKit.Confirm` is shared canon rather than a Lobby screen. `Confirm.ask{Title, Text, YesText?,
NoText?, Delay?}` yields and returns a boolean. The 2-second gate is the specified behaviour: Yes is
grey and inactive, counting down in its own label (`GO (2)`, `GO (1)`), then turns green and becomes
clickable. Re-entrancy is **refused, not queued** — a second `ask` while one is open returns false
rather than stacking dialogs over each other — and **every failure path returns false**, because a
confirmation that fails open is worse than one that fails closed. Parts are resolved fresh on each
`ask`, since the ScreenGui is `ResetOnSpawn`.

**A note on measurement, because it nearly produced a false bug report.** Driving the dialog with one
tool call and sampling with the next showed Yes already green "at t~0.3s" — inter-tool round trips take
seconds, so the clock had moved far more than the transcript suggested. Driving `ask` and sampling
**inside a single `execute_luau`** proved the gate exactly. The general form of this is worth keeping:
when the thing under test is sub-second, the harness cannot be the tool boundary.

### `UnitFlagsService` — the one writer of `Favorited` / `Locked`

The user added a favourite button, and the docs had said "nothing writes `Locked`/`Favorited`" since
B24. Rather than let a screen write profile fields, **`Server.Meta.UnitFlagsService` is the only writer**,
behind `RS.Remotes.SetUnitFlags` (Remotes **19 → 20**). It whitelists exactly `{Favorited, Locked}`,
refuses non-booleans (`bad_value_*`) and non-whitelisted fields (`bad_field_*`), and **returns the
STORED values** rather than echoing the request, so the client cannot end up painting a state the
profile does not hold. 7/7 live cases passed, including a `MetaLevel` write attempt being refused —
which matters more than the happy paths, since a field whitelist that isn't tested is a field
whitelist that isn't there.

This closes the loop with `UnitConsumeRules` from B31: the predicate that protects a unit from being
destroyed and the service that sets the protecting flag are now each singular.

### The sell UI became authored instances

The user's constraint was explicit — **put it in StarterGui, do not build it from a script**, so it can
be edited without running the game. `QuickSellButton` now reveals the authored **`SellButtons`** row,
and "select all by rarity" opens **`RaritySelect`**, whose buttons are `RarityButtonTemplate` clones
walked in `TierConfig.Order` and labelled with live sellable counts and Silver values. Selection paints
`Main.SelectedToSellOverlay` on the card — added to the shared `Kit.UnitIconV2` (the user's call) by an
**identical deterministic script run in both Places**, the manifest's sanctioned second route for
template canon, hash-matching at `bf39c6c8`. Two deliberate deviations from the authored copy:
`Visible = false` at rest, and `ZIndex = 20` because at 1 it drew underneath `TraitIcon`, `CountLabel`
and the flag strip.

Confirmation routes through `UIKit.Confirm`, which retires the screen-local `SellConfirm` panel.
Verified live: the rarity picker selected **exactly its own tier** (Meteor + Warchief, 300 Silver), and
a real sale took units **8 → 6** and Silver **0 → 300** with the reveal firing.

**A real bug the live run found:** after a completed sale, `SellButtons` and `RaritySelect` stayed
visible, because `doSell` cleared `sellMode`/`sellSet` inline instead of calling the teardown that also
hides the panels. Two code paths for "leave sell mode" is the same class of mistake B31 spent its whole
session removing from the destroy predicate. Now there is one: `exitSellMode()`.

### Hazard: a `WaitForChild` with no timeout in a shared module

`require(UIKitButton)` hung for **60 seconds in the Game** — because it did
`script.Parent:WaitForChild("Sound")` with no timeout and `Sound` had not been deployed there yet. In a
shared module this is not a slow path, it is a **deadlock the other Place inherits at boot**. Both new
modules now go through an `optionalSibling` helper: 10-second timeout, `pcall(require)`, and a no-op
stub on failure, so a missing sibling degrades to silence instead of a hung client. Recorded as a
first-class hazard in `ui-feedback.md`.

- **Contract impact:** shared canon changed (5 entries, manifest 27 → 29, `TOOLVERSION B32-2`) and BOTH
  Places carry it. `RS.Remotes` 19 → 20 (`SetUnitFlags`). Save schema UNCHANGED at v3 — `Favorited` and
  `Locked` were already fields; B32 only gave them a writer. New system doc
  **`docs/systems/ui-feedback.md`** (132 lines), registered in `docs/INDEX.md`; `ui-kit.md` points to it.
- **Scope note:** the user explicitly allowed a one-time constitution bypass to do all of B32 in one
  session ("do what can be done or must be done first, then list all the others as pending"). Every
  requested feature landed; the leftovers below are authoring and asset tasks, not code.
- **Open threads (PENDINGs in `STATE.md`):** the 13 `Sound` instances need real SoundIds pasted;
  `ConfirmationPopupUI` must be copied into the **Game's** StarterGui; the six buttons'
  `UIHoverStroke.Thickness` is `0.05` and needs raising (the kit animates to the authored value and
  warns rather than inventing one); `SellButtons.CancelButton` overlaps `QuickSellButton`; `PlayButton`
  still wears the Shop logo; the **Game has no audio owner** for per-act BGM; the pre-existing
  `hash_shared.luau` repo-vs-deployed divergence is still unreconciled (new entries added to BOTH, per
  the ask-first rule); `UnitsGUI.SellConfirm` is now unused and deletable; HUD.Left's `QuestsButton` and
  `ProfileButton` duplicate HUD.Right's and are unwired.

## 2026-08-19 [lobby] B31 — AD-Gacha: **sell dupes.** Blueprint task C3 is complete, and the rule "which unit may we permanently destroy" now has exactly one definition instead of two.

**Place asserted before every write:** `PlaceId 83342803778137` + `Workspace.Lobby` present. Worth
noting how that mattered this session: Studio's instance ids had rotated and **the ACTIVE instance
was the GAME**, so the first `script_read` failed. Resolving by NAME and re-asserting is not
ceremony — it is the only reason nothing was written into the wrong Place.
Drift at boot and at landing: **27/27 GREEN**, every hash byte-identical to B29/B30
(`MetaMath` Game = null, expected), `TOOLVERSION B29-1`. **Nothing shared changed, so nothing was
re-hashed and the Game is not stale.** No Integration needed; stated at bootstrap.

### The interesting part is not the selling, it is the de-duplication

Two systems in this project permanently destroy a player's unit: ascension eats a duplicate (B9) and
now selling converts one to Silver. Until this session the protections — Locked, Favorited, in
`Data.Loadout` — were an **inline condition inside `AscensionRules.PickDupe`**. That was fine with one
consumer. Adding a second consumer with its own copy is exactly how "locked means safe" quietly stops
being true on one of the two paths, and nobody notices until a player loses something.

So the predicate moved out first, and **both destroyers now call it**:

**`Server.Meta.UnitConsumeRules`** (new ModuleScript, pure — no writes, no yields, no remotes):

- `Reason(data, uuid, equipped?)` → nil, or a code in FIXED precedence:
  `bad_uuid → not_owned → locked → favorited → equipped → has_spirit`. The precedence is fixed so the
  message a player sees cannot change with table iteration order.
- **`has_spirit` is deliberately unexercised.** `UnitInstance.SpiritUuid` is a schema field with no
  writer (there is no `Kind = "Spirit"` catalog entry), so nothing can carry one today — but the day
  spirits ship, destroying the unit holding one would silently orphan a `Data.Spirits` record.
  Refusing now costs three lines; discovering it later costs a player's spirit.
- `EquippedSet(data)` is exposed rather than rebuilt inside `Reason`, because `PickDupe` walks every
  owned unit and would otherwise rebuild the whole set per candidate.
- **`Quote(data, uuids)` is the ONE arithmetic** the confirm dialog, the refusal and the write all
  share. That is B9's lesson restated: a preview and a commit that each work it out for themselves can
  show a player one thing and charge them another. It also refuses a **repeated uuid**
  (`duplicate_uuid`) — which would be credited twice and destroyed once — and caps a batch at
  **`MaxBatch = 100`**, because a client can send any list it likes and an unbounded batch is an
  unbounded write.
- It is REQUIREABLE for the same reason `AscensionRules` is split from its Script:
  `RemoteFunction.OnServerInvoke` is write-only, so a rule inside a handler cannot be called from a
  `[Test]` harness — and this is the last rule in the project that should only be reachable via a remote.

`AscensionRules.PickDupe` lost its inline condition and gained `UnitConsumeRules.Reason(...) == nil`.
Re-verified live and unchanged afterwards, including `BuildInfo` on a locked Epic still reporting
`TierEligible=false / "Mythic+ units only"`.

### `GrantService.SellUnits` — and why it credits BEFORE it destroys

**The only code in the project that deletes a `Data.Units` record.** It sits in `GrantService` for the
reason `Spend` and `SpendItems` do: invariant 1 puts every currency write there, and the destruction
has to sit beside the credit or the two can come apart.

The order is the load-bearing decision. `Grant` VALIDATES and can refuse; the deletion is plain table
writes that cannot. Credit-then-destroy means a failure leaves the player whole. Destroy-then-credit
could take a player's units and then fail to pay for them — the one outcome with no recovery.

It also asserts (and warns rather than assumes) that no sold uuid survives in `Data.Loadout` — that
list is DENSE and the match launcher reads it. It cannot happen, because `UnitConsumeRules` refuses an
equipped unit; the assertion exists so that if it ever does, it says so instead of breaking a launch.
`Counters.PerUnit` needs no cleanup: it is a schema field with **no writer anywhere**, noted in the
code so whoever writes one first knows to drop keys here.

`RS.Remotes.SellUnits` (**Remotes 18 → 19**) + `Server.Meta.SellService`, deliberately thin: it owns
the remote and nothing else. **The client sends a list of uuids; that is the whole of its authority.**
Every completed sale prints one `[DATA] SOLD` line naming each uuid and its price — selling is
irreversible, so if a player ever reports losing a unit that line is the only record.

### The UI: multi-select, which is C3's own wording

The user chose the blueprint's letter over this row's old "copy B11's NPC-screen shape" note, and the
blueprint agrees with them: *"multi-select in Units screen"*. So the deviation recorded in
`docs/ROADMAP.md` is deliberate and now says so.

**`QuickSellButton` exists and always did.** B24 recorded that it did not, having looked in
`SelectedUnitFrame`; it is at `UnitsGUI.Main.Bottom.QuickSellButton`, authored with a `ButtonText`
child and unwired since whenever it was drawn. Three ROADMAP/AIState notes repeated that error for
seven sessions. Corrected.

One button, three states, so there is no second control to keep in step with the selection:
`Quick Sell` → `Cancel` (armed, nothing ticked) → `Sell 3 - 285 Silver`. Pressing the third opens the
authored **`SellConfirm`** panel (mirroring `FilterPanel`'s exact language: centred, gold 2px stroke,
12px corner, `Title` / scroller / `Buttons`), which lists **every** unit by name, tier, level and price
above a total. **Only that panel can fire the remote** — a destructive action never happens on the
click that armed it. `CANCEL` closes the panel and LEAVES the selection intact; the button's own
`Cancel` state is what disarms.

Two card-visual decisions worth keeping:

- A ticked card **stays popped with its `UIHoverStroke` on** — the existing "this is the selected card"
  marker, reused rather than a second visual language invented for sell mode. Outside sell mode the
  stroke still means "the detail pane is describing this"; the two states never overlap.
- An ineligible card is **dimmed but stays CLICKABLE**, because a dim cannot say *why*. Clicking one
  writes the reason to the new `Main.Bottom.SellStatus`. The dim moves the root ImageButton's own
  `ImageColor3`/`ImageTransparency` and restores the authored values on exit — the root `UIGradient`
  multiplies with `ImageColor3`, so the tier paint dims with it, ONE surface (B25's rule).
  **Nothing is added to `Kit_UnitIconV2`: it is hashed canon and gains no child, ever.**

The Silver returns through `ClientEvents.ShowRewards` **unchanged** (user decision) — `SellUnits`
hands back `GrantService.Grant`'s own views, so selling needed no reveal surface of its own and
nothing inside `ObtainRewardsGUI` was touched.

> **The client's eligibility predicate IS a second copy, and that is admitted in the code.**
> `UnitConsumeRules` reads a PROFILE and lives in ServerScriptService, so a client cannot require it
> (clients never read profiles, ADR-0004). The client copy decides which cards LOOK sellable from the
> fields `GetUnitViews` already publishes plus the SHARED `TierConfig.GetSellValue`, and it returns the
> SAME reason codes — so a disagreement surfaces as the server refusing something the grid offered, and
> `doSell` prints exactly that rather than letting it read as a generic failure. Same arrangement as
> `BannerRegistry.BlockedReason`.

### Verified live — real Play, real remote, real profile, values printed not flags

`UnitConsumeRules.Quote` was called **directly** from a real server Script, which is the whole reason
it is requireable:

| Assertion | Result |
| --- | --- |
| `Quote{}` / `Quote"nope"` | `nothing_selected` / `bad_request` |
| Locked unit · Favorited unit | `locked` / `favorited`, each naming the offending uuid |
| Equipped unit (a REAL equipped Necromancer, not a forced one) | `equipped` |
| Same uuid twice | `duplicate_uuid` |
| Unknown uuid | `not_owned` |
| 101 uuids | `too_many` (`MaxBatch = 100`) |
| `AscensionRules.PickDupe` after the refactor | unchanged; `BuildInfo(locked Epic)` → `TierEligible=false`, `"Mythic+ units only"` |

Then the same eight cases through the REMOTE, as a client that ignores its own grey-out — **all
refused, nothing destroyed, units still 18, Silver still 0.** `clean + locked` refused the WHOLE batch,
which is all-or-nothing proven rather than asserted.

UI state, read off the live instances: armed with 5 uuids of which 3 were protected → **2 ticked**
(`Sell 2 - 20 Silver`), confirm panel listing `Archer Common LVL 1 — 10 Silver` twice and
`TOTAL 20 Silver (2 units)`; ticked cards `color=1,1,1 transp=0.00 stroke=true scale=1.070`, protected
cards `color=0.42 transp=0.35 stroke=false scale=1.000`, an untouched eligible card
`color=1,1,1 stroke=false scale=1.000`.

Real sale of 3 (2× Archer + 1 Warchief):
`[DATA] SOLD 3 unit(s): +170 Silver (now 170)` with every uuid and price named ·
`client previewed 170 Silver, server paid 170` **MATCH** · units **18 → 15** · grid rebuilt to 15 ·
`Loadout` 1 entry, all still owned · reveal fired `n=1` · sell mode exited ·
`SellStatus = "Sold 3 unit(s) for 170 Silver"`. Then a **real stop/start round trip**: 15 units,
Silver 170, and the three sold uuids gone for good.

New harness `UnitsGUI.DevSell`: `"uuidA,uuidB"` arms and opens the confirm **without selling** (so
every visual state can be inspected), a leading `!` commits. It ticks **through `toggleSell`**, not
straight into the selection set — a harness that can tick a card the button would refuse is a second
copy of the eligibility rule and would hide the bug it exists to catch. The temporary `B31Verify`
server harness was **deleted** before landing.

### Docs, and three stale claims corrected in passing

`docs/systems/ascension.md` 144 → 185 (cap 300); its "Deferred" section became the shipped one.
`STATE.md` 120/120 and `places/lobby/CONTEXT.md` 150/150, both at cap — room was made by deleting two
CONTEXT bullets that duplicated `STATE.md` verbatim, which that file's own rule already forbade.

Corrected:

1. **`QuickSellButton` does exist** (ROADMAP + three AIState/RecentChanges notes said otherwise).
2. **`CONTEXT.md` claimed Units cards are screen-local, not `Kit.UnitIconV2` clones (ADR-0009), and
   asked for a migration that had already happened at B27b.** The controller has resolved the SHARED
   master since then and destroys any stray copy in `UnitsContainer` at boot. Flagged to the user as a
   possible hand-edit first, per the 2026-08-16 ask-first rule; the changelog answered it instead.
3. `STATE.md`'s snapshot still said "schema v2" (fixed at B30) and `CONTEXT.md` still said
   "26/26 shared canon (19 modules)" against a manifest that has had 27/20 since B28.

`CLAUDE.md` step 8(f) now says a paste-ready NEXT SESSION PROMPT is for **handing off to a different
chat**; when the same chat continues, ask whether to carry on instead (user rule, 2026-08-19).

### Open threads

- **Not exercised, reasoned only:** `has_spirit` (no writer for `SpiritUuid` exists) and
  `credit_failed` (reachable only if `"Silver"` left `ItemCatalog`, which would break far more).
- Nothing writes `Locked` or `Favorited` — **no remote does** — so the only way to test those
  protections was a harness setting them directly. It left one unit Locked and one Favorited in the
  dev profile, which is useful; the user can clear them. `LockUnitButon` (sic) is still unwired, and
  wiring it is the natural next AD-UI/AD-Gacha step now that Locked actually protects something.
- `UnitsController` is now **1265 lines** — the largest client script in the project. Place-local, so
  no doc cap applies, but the sell flow is a coherent ~230-line block if AD-UI ever wants it split.
- Selling and ascension compete for the same Mythic dupes by design; `SellValueByTier` is the one knob.

## 2026-08-18 [lobby] B30 — AD-Gacha: **SELECTION banners are live.** Blueprint task B4 is complete, and the first featured set in this game that config + the clock cannot produce.

**Place asserted before every write:** `PlaceId 83342803778137` + `Workspace.Lobby` present.
Drift at boot and at landing: **27/27 GREEN** in the Lobby against `shared/manifest.json`
(`MetaMath` Game = null, expected), `HashShared TOOLVERSION B29-1`. **Nothing shared changed, so
nothing was re-hashed and the Game is not stale.** No Integration needed; stated at bootstrap.

### The one line B7 promised, and the four pieces underneath it

B7 shipped the Event half of blueprint B4 and stopped, because Selection needs a per-player stored
pick and schema v2 had nowhere to put one. B29 landed `BannerChoices` in v3 in both Places. So the
switch really was one line — `Selection` into `BannerRegistry.SUPPORTED_TYPES` — and neither
`SummonService`'s refusal path nor the summon card needed a change, because B7 had already moved
banner-type policy into `BannerRegistry.BlockedReason`, which both of them read. That is the design
paying off two sessions later.

Built exactly to `docs/proposals/2026-08-09-selection-banner-choices.md` §"Then the flow itself":

**1. `BannerRegistry` grew a per-player featured path, and the pure one is untouched.** The
deterministic draw was extracted into a private `drawFeatured(cfg, count, period, nowSec, excludeId)`
that BOTH paths call, so there is one draw rather than two that can drift. `FeaturedFor` still
returns `{}` for a `PlayerChoice` banner and still produces Standard's and the event's sets from the
clock alone — verified unchanged (`Standard` = Warchief/Babaylan/Meteor, `EventFirstLight` =
Mage/Meteor, before and after). New and all **pure**: `CurrentDay`, `ChoiceCooldownDays` (seconds →
whole days, **rounded up**, so a sub-day config can never round down to a free change),
`IsPlayerChoice`, `ChoicePool` (flat, SORTED, Secret excluded), `IsChoosable`, `ChoiceState` →
`{ TowerId, ChosenAtDay, CanChange, DaysLeft }`, and **`FeaturedForPlayer`** = the pick FIRST, then
`AutoCount` randoms from `RngForSlot(slot(AutoRotation), bannerId)` **excluding the pick** so it
cannot appear twice. `Validate()` now also rejects a Selection banner with no `PlayerChoice`, a
negative `ChoiceCooldown`, an `AutoCount > 0` with no positive `AutoRotation` (which would ask
`MetaMath.Slot` for a zero period and silently draw nothing forever), or an empty choice pool.

> **Why every one of those is pure and shared:** the server ENFORCES the cooldown and the screen
> EXPLAINS it. Two copies of that arithmetic is how a greyed-out button and a server refusal come to
> disagree — the exact failure `BlockedReason` was created to prevent at B7.

**2. `SSS.Server.Meta.BannerChoiceService` — the ONE writer of `Data.BannerChoices`**, the same
single-writer shape `GrantService` has for grants. `RS.Remotes.ChooseBannerUnit` (**Remotes 17 → 18**)
is a RemoteFunction with two modes: `(bannerId)` READS pick + eligibility + options + resolved
featured, `(bannerId, towerId)` WRITES. One remote, not two, because the spec names one — and the read
is a few fields only this system wants, so it does not join `GetUnitViews` either (that is the
COLLECTION read path, ADR-0004, and a banner-policy field does not belong in it). **The client is a
request, never truth:** the handler re-derives that the banner exists, is a supported Selection
banner, is inside its window, that the id is in *that* banner's pool, and that the cooldown elapsed.
Two decisions worth keeping: **re-picking the unit you already have is a no-op** (`Unchanged = true`)
that deliberately does NOT rewrite `ChosenAtDay`, so a stray double-click cannot restart a one-day
cooldown; and a pick that has fallen out of a re-curated pool is refused rather than boosted.

**3. `SummonEngine.BuildContext(cfg, nowSec, featuredOverride)`** — a third optional argument, and
the only non-pure input that module has. It is a **LIST**, not a profile or a player, so the engine
still knows nothing about persistence and the 10k odds harness still calls it the old way.
`SummonService` resolves `FeaturedForPlayer` and refuses a Selection pull with **`choice_required`**
when nothing is stored: charging 130 Gold for a featured set of pure auto-randoms is precisely the
half-serve B7 declined to ship.

**4. The choice UI, as REAL authored instances** (user rule, 2026-07-18 — nothing generated in
script). `ChoiceOverlay` (Title/Subtitle/`ChoiceRow` ScrollingFrame/Status/Confirm/Cancel) and
`ChooseButton` on `BannerCardTemplate`, matching the card's authored language (gold `#C49E5C`,
GothamBlack, `TextScaled`, `UICorner 8`). It **replaces `ClosedOverlay`'s role** on a Selection card:
with no pick the chooser *is* the card; once a pick exists `ChooseButton` brings it back. Option
chips are clones of the shared `Kit.UnitIconV2` master filled by `SummonController`'s existing
helpers (invariant 2 — no new inline consumer of the kit was written and no unit-icon controller was
built, which is still the user's deferred call), and the authored `UIHoverStroke` doubles as the
selected marker on `hovering or selected` — the rule `UIKit.ItemIcon` and the Units grid already use.

**Shipped `RS.Configs.Banners.SelectionAncestors` ("Call of the Ancestors")** — Gold 130/pull,
curated pool of 7 (Farm excluded, same reasoning as the event), `Boost = 4`, `ChoiceCooldown = 86400`,
`AutoCount = 2` on a daily `AutoRotation`, `PityRef = "Default"`, always open. Rates are deliberately
*worse* at the top than the event's (Mythic 1.5% vs 2%): the value is aiming the Boost, not the curve.

### Verified live — real Play, real remote, real profile, values printed not flags

`ChosenAtDay` is a day number, so the whole cooldown is only testable if the stored value is printed.
It was. `MetaMath.Slot(86400, -57600)` = **day 20682** on 2026-08-18.

| Assertion | Result |
| --- | --- |
| Pull with nothing stored | `ok=false reason=choice_required` (server, before any spend) |
| Pick `Farm` (not in the pool) | `not_in_pool`, plus a `[DIAG]` naming player + id + banner |
| Pick `Necromancer` | `nil → Necromancer at day 20682`, `Changed=true`, `CanChange=false`, `DaysLeft=1` |
| Did it reach the PROFILE? | `[Test] POLL: BannerChoices['SelectionAncestors'] = { TowerId = Necromancer, ChosenAtDay = 20682 }` |
| Re-pick `Necromancer` | `Unchanged=true`, `ChosenAtDay` **still 20682** — the cooldown did not restart |
| Pick `Mage` the same day | `choice_on_cooldown`, `TowerId=Necromancer`, `DaysLeft=1` |
| Client vs server featured | **MATCH** on all four reads: `[Necromancer/Warchief/Archer]` both sides |
| Pick FIRST, never duplicated | `Necromancer/Warchief/Archer`; pick=Archer draws `Archer/Warchief/Babaylan` (the exclusion shifts the draw, as designed) |
| `ChoiceState` day maths | today → `CanChange=false DaysLeft=1`; yesterday → `CanChange=true DaysLeft=0`; half-written record (no day) → changeable, not locked out forever |
| Real x10 Selection pull | Gold **3000 → 1700** (130 × 10), 10 uuids granted, `FEATURED` tagged on the boosted ids, reveal `n=10 cols=5 rows=2 scrollbar=false` |
| UI state machine | no pick → overlay ON / ChooseButton OFF / Cancel OFF / pulls greyed; after the pick → overlay OFF / ChooseButton ON / Cancel ON / pulls ACTIVE |
| Chips | 7 built from the sorted pool, 104px from the row's authored `ChipWidth`, laid out and spaced; selected chip's `UIHoverStroke` ON and only that one |
| No regression on the other cards | `Standard` trio unchanged, `EventFirstLight` still "Ends in 13d", `ChoiceOverlay`/`ChooseButton` stay hidden on both, all three pages price + gate correctly |

New Studio harness, same convention as `DevPull`: set `SummonScreen`'s **`DevChoose`** to a towerId to
run the real chip-then-CONFIRM path (a chip click cannot be fired from tooling). Left at `""`; the
temporary `B30Verify` server harness was **deleted** before landing.

### Docs

`docs/systems/gacha.md` hit its 300-line cap, so the Selection material was **split** into
**`docs/systems/gacha-selection.md`** (71 lines) and registered in `docs/INDEX.md`, per CLAUDE.md's
"over cap → split". `gacha.md` came back to 264 by also condensing two history-only blocks (B3's
verification figures and the B7 rotation fix) down to pointers at this changelog — current-state docs
describe NOW. `STATE.md` is at 120/120 with the Selection PENDING **deleted** (ADR-0006; its record is
this entry) along with the AD-Gacha trait-on-summon review PENDING, which was discharged by reading
`SummonEngine`: `TraitRegistry.Roll(rng)`, `"None"` → nil, failure WARNs once — all present and
correct. `places/lobby/CONTEXT.md` is at 149/150. Also corrected two stale numbers found in passing:
`STATE.md`'s snapshot still said "schema v2", and `CONTEXT.md` still said "26/26 shared canon
(19 modules)" when the manifest has had 27 (20 modules) since B28.

### Open threads

- **Not exercised, reasoned only:** `choice_no_longer_in_pool`. Reaching it needs a banner re-curated
  underneath a player who had already chosen, and banner configs are required and cached at boot, so
  it cannot be provoked mid-Play without editing config during a session. The branch is three lines
  and shares `IsChoosable` with the write path that *was* exercised.
- **The dev profile still carries `BannerChoices["B29ProbeBanner"]`** from B29's probe — a banner id
  that does not exist, so nothing reads it. Left alone (user rule: ask before "fixing" something that
  looks odd). It is also the surviving evidence of B29's round trip.
- `Boost = 4` on a curated pool where **Necromancer is the only Mythic** means the pick's in-tier
  boost is unobservable when the pick is Necromancer. The mechanism is proven by the `FEATURED` tags
  on Archer/Warchief and by the printed `ctx.FeaturedList`; a second Mythic would make it visible.
- `SummonController` is now **841 lines**. Place-local, so no doc cap applies, but it is the largest
  screen controller in the Lobby and the choice flow is a coherent ~230-line block if AD-UI ever
  wants it in its own script.

## 2026-08-17 [both] B29 — AD-Integration: **save schema v2 → v3.** `BannerChoices` lands, Selection banners stop being contract-blocked, and the hover race turns out to be ~70 events per play session.

### The bump (blueprint B4's blocker, open since B7)

`Selection` banners have been registered, validated and *refused* since B7 for one reason: schema v2
had nowhere to store a player's chosen featured unit, and cross-phase invariant 5 forbids leaving the
two Places out of schema sync across a session boundary — so the Lobby-only B7 session correctly
refused to start the bump. This is the both-Places session it was waiting for.

Executed exactly as `docs/proposals/2026-08-09-selection-banner-choices.md` specifies, with no
improvisation on the shape:

```luau
BannerChoices: { [bannerId]: { TowerId: string, ChosenAtDay: number } }
```

- `SCHEMA_VERSION` **2 → 3**; `BannerChoices = {}` in `Template`; a new exported `BannerChoice` type.
- **`ChosenAtDay` is a `MetaMath.Slot(86400, ResetOffsetSec)` DAY NUMBER, not a timestamp.** That is
  the whole point: it makes `Featured.ChoiceCooldown` agree across servers with no stored clock
  (invariant 3). The module says so in a comment ending "do not 'improve' this into `os.time()`".
- **`Migrations[2]` is a deliberate no-op.** `Reconcile()` runs before `Migrate()`, so the key is
  already an empty table by the time the step executes — there is genuinely nothing to convert. The
  step exists because **`Migrate()` warns and STOPS at a missing step**, so a silent gap at v2→v3
  would strand every migration added after it.
- `ProfileTemplate` `63a0c98a` → **`72d3944f`**, deployed to BOTH Places in this session,
  hash-matched to `shared/src` byte-for-byte (7,094 bytes).

**A property worth knowing before the next contract change: this bump is FORWARD-TOLERANT, unlike
teleport v4.** `Reconcile()` only fills missing keys and never prunes, and `Migrate()`'s loop does
not run when `data.SchemaVersion` already exceeds a Place's `SCHEMA_VERSION`. So a v2 server reading
a v3 profile leaves `BannerChoices` intact rather than destroying it. Both Places were still deployed
together and must still be republished together — the tolerance is a safety net, not a licence.

### Verified 8 PASS / 0 FAIL, from a real server Script

`execute_luau` runs in a separate VM whose externally-required modules are empty copies that *mimic
data-loss bugs*, so a schema claim proven there would be worthless. This ran as a real `Script`:

```
PASS SCHEMA_VERSION is 3 | PASS Migrations[2] exists -- typeof=function
PASS v2 -> v3 applies exactly 1 step -- steps=1 SchemaVersion=3
PASS v2 -> v3 is NON-DESTRUCTIVE -- PlayerLevel=7 Units.abc.TowerId=Kapre
PASS v1 walks ALL THE WAY to v3 (the gap the no-op step prevents) -- steps=2 Currencies.Gold=250 units=1
[DATA] Migrated SuperiorBeing_S's profile forward 1 step(s) to v3
[DATA] [CONTRACT] Profile v3 loaded (store=Beta1_PlayerDataDev1, DataStoreState=Access)
PASS real profile is at v3 | PASS BannerChoices exists and is a table
PASS PROBE SURVIVED A REAL DATASTORE ROUND TRIP -- read back TowerId=Necromancer ChosenAtDay=20670
```

The probe test is two Play sessions on purpose: write, stop (ProfileStore autosaves on `EndSession`),
start, read back. That is what separates "Reconcile filled a key in memory" from "the field
persists". The `v1 → v3` case is the regression guard the no-op step exists for — it fails loudly the
day someone deletes `Migrations[2]`.

**This also closes A7's outstanding caveat:** the real-DataStore round trip had only ever been done
on a *scratch key*, never the player join path. B29 did it on the join path.

### The hover race — user-reported, and far bigger than "sometimes"

The user, confirming the B27d click fix: *"both work but the hover preview sometiems bugs, it doesnt
show even when mouse is still hovered on the card ... especially when moving fast in between slots
and cards."* Full diagnosis and fix in **B29a** below. What belongs here is the measurement:

**One instrumented play session logged ~70 suppressed stale hides.** The race is not an occasional
glitch — it is *most of a fast sweep*, and every one of those events would previously have blanked
the preview. The "sometimes" in the report was the tell that this was a race; the count is what
showed how badly it was losing.

That volume is also why the `[DIAG]` line is now **throttled** (first occurrence, then every 50th):
70 unthrottled lines bury every other message in the console, which is its own bug.
`UIKitHotbar` `3e905bc9` → **`ef691df9`** for the throttle; `UnitsController` got the same treatment.

### Cheaper bootstraps: `ServerStorage.DevTools.HashShared`

The mandatory drift check meant pasting the 278-line `tools/hash_shared.luau` through `execute_luau`
**once per Place, every session** — ~8k tokens of input for 27 lines of output. It is now an in-Place
module (`TOOLVERSION B29-1`) wrapped in `return function() ... end`, so the check is four lines. The
wrapper is not decoration: a ModuleScript returning the report directly would be memoised by
`require`'s cache and hand back a stale reading on a second call.

It reproduced all 27 known-good hashes in both Places on its first run, which is the only reason to
trust a compacted transcription. **The repo tool stays canon** — edit `tools/hash_shared.luau`,
especially its `PROPS` whitelist, and you MUST re-deploy this and bump `TOOLVERSION`, or the check
passes against an old definition and real drift becomes invisible. That hazard is written at the top
of the module itself, where the next session will actually read it.

### Closed this session

- **The B27d click TRIGGER is CONFIRMED by the user in BOTH Places** — Units grid selects, Game
  hotbar placement fires. `Active = false → true` is proven end-to-end, two sessions after the fix.
- **Real-DataStore round trip on the player join path** (A7's scratch-key caveat).
- **The `BannerChoices` schema PENDING** — replaced by an AD-Gacha PENDING for the flow itself.

### Open threads

The flow on top of v3 — a `ChooseBannerUnit` remote (server re-checks cooldown *and* pool membership;
the client is a request, never truth), a per-player `BannerRegistry.FeaturedFor`, `Selection` into
`SUPPORTED_TYPES`, and the choice UI replacing a Selection card's `ClosedOverlay` — is **AD-Gacha's
next session**, all Lobby-local, and nothing blocks it.

The user's own fast-sweep confirmation of the hover fix is still outstanding; the ~70-event log is
strong evidence the race was real and is now caught, but the eye test is theirs.

## 2026-08-17 [both] B29a — AD-Integration: the hover preview's hide is now OWNED. A user-reported flicker turns out to be an out-of-order `MouseLeave`, in two surfaces at once.

The user, confirming the B27d click fix: *"both work but the hover preview sometiems bugs, it doesnt
show even when mouse is still hovered on the card, the previewtemplate doesnt show on the screen,
especially when moving fast in between slots and cards."*

**Roblox does not guarantee `MouseLeave(previous)` fires before `MouseEnter(next)`.** Sweeping the row
quickly delivers them out of order often enough to see, and both hover surfaces hid the preview
*unconditionally* on leave. The losing sequence:

1. `MouseEnter(slot 4)` → `showPreview` → `preview.Visible = true`
2. `MouseLeave(slot 3)` → `hidePreview()` → `preview.Visible = false`

The stale leave wins, and the preview stays hidden while the mouse sits on a real, hovered slot. The
"sometimes" in the report is the tell: a race, not a broken lookup.

**Fix — a hide must prove it still OWNS the preview.** `hidePreview(requester)` drops the call when a
different element owns the preview; `showPreview` claims ownership BEFORE any fill work, so a leave
from the slot just vacated is already recognisable as stale when it lands. **The guard cannot strand
the preview visible**, because the current owner's own leave still hides normally — the only calls it
ever drops are ones that were already wrong.

Two surfaces, same defect, same shape:

- **`UIKit.Hotbar`** (shared canon, BOTH Places) — `dae52036` → **`3e905bc9`**, deployed to both and
  hash-matched to `shared/src` byte-for-byte (19,297 bytes).
- **`UnitsController`** (Lobby-local) — `card.MouseLeave` did `hoverPreview.Visible = false` with no
  ownership test at all. Its `close()` now calls `hidePreview()` with no requester, which is exactly
  what "close the whole screen" should mean.

**A suppressed stale hide PRINTS.** `[DIAG] hotbar hover: suppressed a stale hide from <slot> (preview
owned by <slot>)` — that line appearing IS the race caught in the act. The bug is therefore provable
from the running game rather than argued from the source, which matters because the trigger
(`MouseEnter`/`MouseLeave`) is one of the two things in this project that tooling cannot fire.

Boot verified clean in the Lobby: 6 slots build, both preview instances present, no errors. The
sweep itself is with the user — the same reason B27d's click fix needed a human.

### Also this session

**`ServerStorage.DevTools.HashShared` deployed to BOTH Places (TOOLVERSION `B29-1`).** The drift check
meant pasting the 278-line `tools/hash_shared.luau` through `execute_luau` once per Place every
session — ~8k tokens of input for 27 lines of output. It is now a module wrapped in
`return function() ... end` (a bare return would be memoised by `require`'s cache and hand back a
stale reading), so a bootstrap drift check is four lines. It reproduced all 27 known-good hashes in
both Places on first run, which is the only reason to trust a compacted transcription.
**The repo tool stays canon:** edit `tools/hash_shared.luau` — especially its `PROPS` whitelist — and
you MUST re-deploy this and bump `TOOLVERSION`, or the check silently passes against an old
definition and real drift becomes invisible. That hazard is written at the top of the module itself.

### Closed

**PENDING (AD-UI): the click TRIGGER is confirmed by the user in BOTH Places** — Units grid selects,
Game hotbar placement fires. B27d's `Active = false → true` is proven end-to-end. The hover TRIGGER
half of that PENDING stays open until the sweep above is confirmed.

## 2026-08-17 [both] B28 — AD-Integration: the `Kit_HotbarSlotV2` drift closed on ONE property, and the open/close SLIDE lands on `UIKit.Motion` — the last item of the user's B27 queue.

### The drift was half the size B27d recorded

B27d handed this session two divergent properties. **Only one of them was still real**, which is why
the first thing B28 did was re-measure both Places instead of trusting the briefing:

| Property | Lobby | Game (before) | Verdict |
| --- | --- | --- | --- |
| root `Size` | `{1,0},{1,0}` | `{0.225,0},{0.399,0}` | **REAL** — the whole hash gap |
| `UIHoverStroke.Thickness` | 0.035 | **0.035** | **already matched** — B27d's "0.0 in the Game" no longer held |

Nothing was written to `Thickness`; the value was asserted, not set. Had this session "reconciled"
from the briefing it would have written a value that was already correct and reported a fix that
fixed nothing — the exact failure the "measure, do not assume" rule exists to prevent.

**User decision: the LOBBY is canonical.** Taken via the deterministic-edit path (`checklists.md`
step 2's exception, the same route as B27b's `CanvasGroup` → `EXPLevelBar` rename) rather than a
cross-Place copy — one property, so it was cheaper and safer than asking the user to paste a tree.

**Why `{1,1}` is safe in the Game, established BEFORE the write, not after:** `UIKit.Hotbar.attach`
CLONES this master `MaxSlots` times and never overrides `Size` (line 214); both Places'
`StarterGui.Hotbar.Slots` are the identical `{0.420723,0},{0.157785,0}` Frame under a horizontal
`UIListLayout`; and the master carries a `UIAspectRatioConstraint` (1.0034, FitWithinMaxSize, Width)
which is what actually clamps a slot. So `{1,1}` resolves to the same square the Lobby already draws.
**The Game's slots now render BIGGER — that is the fix, not a regression.** The authored
`Slot1..Slot6` sitting in the Game's `StarterGui` needed no edit: `attach()` destroys and re-clones
them on every boot.

Result: `Kit_HotbarSlotV2 = cd5a2aa0` in BOTH Places. **All 27 manifest entries now agree across both
Places except `MetaMath`** (Lobby `6badac1d`, Game MISSING — expected until Phase D).

### The slide: `Motion.slideIn` / `slideOut` / `isOpen` / `restPosition` / `forgetSlide`

User's ask, verbatim: *"I also need animations when opening in closing, Like sliding up, not just
popping visible and invisible."* Built on `UIKit.Motion` (27th manifest entry) so a fourth animation
dialect is not born. `Tuning` gains `SlideInTime = 0.34`, `SlideOutTime = 0.20`, `SlideDistance = 0.35`
— opening is the unhurried leg, closing gets out of the way faster than it arrived.

Three traps, each handled once in the module so no screen repeats them:

1. **Enable before you animate.** Every screen toggles `ScreenGui.Enabled`, and a disabled ScreenGui
   does not lay out — everything under it reads `AbsoluteSize = 0`. `slideIn` enables FIRST;
   `slideOut` disables only after the tween completes. The screens call `slideIn` **before** cloning
   their cards, or every card would be built against a zero-size parent.
2. **The travel is parent-relative SCALE, never measured pixels.** A measured slide would have to
   wait a frame for `AbsoluteSize` to go non-zero — and "a harness that reports 0 or 0x0 is usually
   the harness" is this project's most repeated false alarm. Scale cannot be fooled by a disabled gui.
3. **The authored resting Position is canon.** Captured ONCE into the `UIKitRestPosition` attribute
   (UDim2 is a real attribute type, so it is visible in Studio and survives a reload); every tween
   runs to or from that value, and `slideOut` restores it on completion so a hard `Enabled = true`
   elsewhere still shows the panel in place rather than parked off-screen.

**The screens ask `Motion.isOpen(main)`, not `gui.Enabled`.** This is a real bug avoided, not a
stylistic choice: during a close tween the gui is STILL Enabled, so the old `if gui.Enabled and
main.Visible` toggle read that as "open" and would have closed a second time — swallowing the click
of a player reopening mid-slide. Re-entrancy is a per-frame token; a completion callback holding a
stale token does nothing, which is what stops a late `slideOut` from disabling a gui just reopened.

`close()` also stopped clearing `main.Visible`: a hidden frame cannot be seen sliding.

Wired in the Lobby: **`UnitsGUI`, `ItemsGUI`, `SummonScreen`, `IndexScreen`** — including
`UnitsController`'s `OpenUnitsWithUuid` route (the hotbar's "open on this unit") and every
`ClientEvents.ScreenOpened` close, so a screen dismissed by a sibling's announcement runs the same
slide-out rather than a hard hide. `ItemsController` gained the `Motion` require it never had.

**Boot teardown must NOT slide** — `SummonController` and `IndexController` call `close()` at the end
of their boot, and sliding there would flash the screen for a fifth of a second on every join. Both
now call a new `hideInstant()`. `PlayGUI` is excluded as specified (its `LoadingScreen` veil).
`AscensionScreen` was left alone: its controller does not live under that ScreenGui, so it did not
"read naturally" and inventing a wiring for it was not this session's call.

### Verified from a real LocalScript — 12 PASS / 0 FAIL

`execute_luau` runs in a separate VM with its own require cache, so a `Motion` required there is not
the module the controllers hold. The harness was a real `LocalScript` driving the controllers through
the BindableEvents they already listen to (`Activated` cannot be fired from tooling), and it printed
VALUES, not flags — the lesson B26's "LVL 100" placeholder bug taught for the third time:

```
authored rest Position = {0.5000,0},{0.4500,0} | gui.Enabled=false
PASS open: gui is ENABLED before the tween finishes -- gui.Enabled=true at t=0.06
PASS open: panel starts BELOW rest and is moving -- pos={0.5000,0},{0.5644,0} (dY.Scale=+0.1144)
PASS open: settled EXACTLY on the authored rest -- pos={0.5000,0},{0.4500,0}
PASS close: gui stays ENABLED during the slide-out -- a hard hide would already read false
PASS close: an announcement runs the SLIDE, not a hard hide -- dY.Scale=+0.3045
PASS close: gui disabled only AFTER the tween | authored Position RESTORED
PASS re-entrancy: NOT stranded enabled-but-off-screen (open/close/open inside both tweens)
PASS restPosition attribute == authored rest
===== B28 SLIDE RESULT: 12 PASS / 0 FAIL =====
```

Harness deleted, all `Dev*` attributes confirmed OFF, and `StarterGui` confirmed free of stray
`UIKitRestPosition` attributes (the runtime writes them onto the `PlayerGui` clone, which is discarded).

### Canon

`UIKitMotion` `ed800bf3` → **`a104e59d`**, deployed to BOTH Places in this session and hash-matched
against `shared/src/UIKitMotion.luau` byte-for-byte (18,485 bytes). `Kit_HotbarSlotV2` `deployed.Game`
`9ca7a958` → `cd5a2aa0`. `docs/systems/ui-kit.md` gains a `UIKit.Motion` section — and its controller
table, which still said **5** manifest entries, is corrected to **6**: `UIKitMotion` was added at B27c
and never registered in the doc.

### Open threads

**Not done this session** (the user chose the drift + the slide): TASK 3, real-click confirmation of
B27d's `Active = false → true` fix. `Activated` still cannot be fired from tooling, so it needs a
human click on one card in each Place. The PENDING stays open.

## 2026-08-17 [integration] B28a — AD-Integration: the bootstrap was quietly billing ~90k tokens a session for a file nobody needed whole. Reading budget is now constitutional.

### The finding (user question, 2026-08-17)

The user asked whether the docs already forbid reading the whole `CHANGELOG.md` every session.
**Partially, and the one line that mattered was wrong.**

- CLAUDE.md step 4 did say "entries newer than your last session" — an intent, with no method.
  A chat with no recipe reaches for `Read CHANGELOG.md`, and the file is **4,511 lines /
  349 KB / ~90k tokens**: a third of a session's budget spent before any work starts, to learn
  what the first ~70 lines say.
- **Line 45 was an active trap:** "re-read `STATE.md` + the changelog **tail**". The file is
  newest-**first**. Its tail is 2026-07 archaeology; a chat obeying that line literally read the
  oldest entries to check whether a sibling had just landed. Now: `sed -n '1,3p'`.
- Nothing anywhere forbade whole-file reads of the other large docs — `docs/ROADMAP.md` (451
  lines, edited every session to flip ONE row) and `ai-kms-architecture.md` (Tier-2 rationale).
- The Tier-0/1/2 read budget existed **only** inside `ai-kms-architecture.md` §Bootstrap — a
  document no chat reads at bootstrap. A budget nobody reads is not a budget.

### What landed

- **CLAUDE.md — new `## Reading budget` section** (user rule, 2026-08-17): bootstrap reads only
  the four files of steps 1–4; never read a file over ~200 lines whole to find something
  (`grep -n` then `sed -n 'A,Bp'`); `INDEX.md` is the map; `script_grep` before `script_read`;
  print the ONE asserted value. Absorbs the old "don't explore the game tree for orientation".
- **CLAUDE.md step 4 rewritten** to state the method and the direction: TOP-DOWN, stop at the
  counter you already know, the newest entry starts at **line 3**, never read it whole.
- **CLAUDE.md multi-chat rule** now says the pre-landing check is the changelog's FIRST entry
  (`sed -n '1,3p'`), and names "tail" as the wrong direction.
- **The B26 user rule is now constitutional** — "looks changed or unusual? ASK THE USER whether
  they did it; never 'fix' it" was only ever in session prompts.
- **`tools/checklists.md` — new first section, "Reading the CHANGELOG ... without burning the
  session"**: five copy-paste recipes, and the cost-escalation order (STATE/CONTEXT → grep →
  one entry's range → a doc's section) with the observation that most questions are answered
  at step 1 and asked at step 4.
- **No index file was created.** The `## ` entry headers are already written as full one-line
  summaries, so `grep -n '^## ' CHANGELOG.md | head -15` IS the index — one that cannot rot,
  costs ~15 lines, and buys four sessions of history.
- Doc-gardening step 4 now rotates the changelog at **~3 months OR ~5k lines, whichever first**.

### Measured, not asserted

Catching up from B26 under the new recipe reads **279 lines instead of 4,511 — a 94% cut**.
The pre-landing sibling check went from a whole-file read to **3 lines**. CLAUDE.md is 150/150
after compressing five over-long passages to pay for the new section; `tools/checklists.md` 145.

### Boot anomalies found and NOT "fixed" (user rule, B26)

1. **`git diff HEAD --stat` reported `shared/src/UIKitMotion.luau` deleted (251 lines).** It is
   not. The file is on disk and `git hash-object` gives `149c5267…`, **byte-identical to
   `HEAD:shared/src/UIKitMotion.luau`**. The repo's *index* was missing the entry (71 entries vs
   72 in HEAD's tree) — an artifact of B27c/d committing through a temp `GIT_INDEX_FILE`, which
   is the documented workaround for this mount. Repaired by rebuilding the index from HEAD; zero
   bytes of content changed. **This is the known trap's cost: the index lies, the blobs don't.**
2. **`.git/HEAD.lock` was stuck** from the B27d landing; parked to `.git/_parked/` (device_bash
   cannot delete). That directory now holds 13 parked locks and wants a sweep by the user.
3. `git log origin/main..HEAD` returns 0 because no `origin/main` remote-tracking ref has ever
   been fetched — the 8 unpushed commits are real; the count just cannot be derived that way.

### Open threads

Untouched this session, still the B28 queue: the `Kit_HotbarSlotV2` cross-Place drift (USER
decision on which Place is canonical), the open/close SLIDE on `UIKit.Motion`, and real-click
confirmation of the B27d `Active` fix.

## 2026-08-16 [both] B27d — AD-Integration: **`Active = false` had killed every click on a V2 card since B26.** Plus HUD.Left mutual exclusion, multi-colour hover strokes, and one unresolved template drift.

### The click regression, and how much bigger it was than reported

The user reported the Units grid not selecting on click. The card was not covered by anything —
`GetGuiObjectsAtPosition` at the card's centre returned the card itself, third in a clean stack. The
card simply read **`Active = false`**, and **`GuiButton.Activated` does not fire on an inactive
button**.

All three V2 masters ship `Active = false`. So this was never a Units bug: **every `Activated`
connection on a V2 card has been dead since the B26 adoption** — `IndexController`'s detail open,
`AscensionController`'s dupe picker, `UIKit.ItemIcon.onActivated` (the Items grid), and **both
hotbars' slot activation, which in the Game means placement**. Flipped to `true` on all three
masters in both Places. `UIKitButton.setEnabled` still drives `Active` per-slot, so locked hotbar
slots stay genuinely unclickable.

Worth noting what made it invisible for two sessions: hover worked perfectly the whole time.
`MouseEnter` does not require `Active`, so the cards looked alive.

### Hover strokes: 3+ colour tiers use all their colours

User rule. A tier on the **two-colour minimum** (an authored main plus the derived dark) still
collapses to the single brightest colour — the dark half is only a shadow, and a stroke drawn in it
reads as a smudge. A tier with **three or more authored colours** now outlines in **all of them**,
as a child `UIGradient` on the stroke, drifting on the same 45° 9s idle as the card. Flattening
Mythic's rainbow to one colour threw away the thing that identifies the tier.

The decision lives in `TierConfig.HoverStrokePaint` (pure — returns a colour *or* a sequence, never
touches an Instance) and the application in `Motion.paintHoverStroke`. Two Instance-level traps it
handles: `stroke.Color` is forced to **white** in the gradient case, because a UIStroke *multiplies*
its Color with a child gradient and the old tier colour would tint the whole rainbow; and a stale
gradient is **destroyed** when a tier falls back to two colours, or a card recycled from Mythic to
Rare would keep outlining in rainbow forever. Empty/locked hotbar slots clear it for the same reason.

### One HUD.Left screen at a time

New `ClientEvents.ScreenOpened`. Each HUD.Left screen announces its own name when it opens and
closes itself on anyone else's announcement — so the outgoing screen runs **its own `close()`** (its
real teardown: camera, filters, selection) rather than being blanket-hidden by whoever opened next.
PlayGUI announces but deliberately does **not** listen: it already blanks every other GUI, and its
close path runs through a loading veil that must not be triggered by another screen. Its announcement
is fired *before* `hideOtherGuis` — that order matters, because `hideOtherGuis` snapshots what it hid
so `leaveMenu` can restore it, and a merely-hidden Units screen would pop back open on leaving Play.

### ⚠ Unresolved: `Kit_HotbarSlotV2` disagrees across Places

After flipping `Active` in both, the two copies still hash differently — **Lobby `cd5a2aa0`, Game
`9ca7a958`**. Diffed rather than guessed; two real differences, neither caused by the flip:

- root `Size` is `{1,0},{1,0}` in the Lobby and `{0.225,0},{0.399,0}` in the Game
- **`UIHoverStroke.Thickness` is `0.035` in the Lobby and `0.0` in the Game**

The second matters beyond the hash: a zero-thickness stroke renders as **nothing**, so the Game's
hotbar hover outline stays invisible even now that `.Enabled` is driven. Both copies matched
`41c3c9e3` at B26, so one Place was edited afterwards. **Which is canonical is a user design call**,
and reconciling a template across Places is a user copy — so nothing was overwritten.
`deployed.Game` records the divergent hash on purpose, so the drift check keeps reporting it.

### Acceptance — live Lobby

8/8 Units cards `Active = true`; Necromancer (Mythic, 6 colours) outlines via a **13-stop child
gradient at 45° with a white stroke**, while every two-colour tier outlines flat in its brightest
colour and carries **no** gradient; firing `ScreenOpened("ItemsGUI")` closed the open UnitsGUI.
All four shared modules and two of the three templates verified byte-identical in both Places.

The click *trigger* itself still cannot be fired from tooling — `Activated` is in the same boat as
`MouseEnter` — so what is proven is the precondition (`Active`), the connection, and that
`selectUnit` fills the panel. That limit is the standing PENDING, now widened to cover clicks.

## 2026-08-16 [both] B27c — AD-Integration: **`UIKit.Motion`**, the kit's one motion home. Hovering a card no longer shoves its neighbours, the hotbar has a hover for the first time, and prices are temporarily visible by user override.

Seven things from a play session. The first two turned out to be the same root cause seen from two
angles, and fixing them properly meant the shared animation helper flagged two sessions ago.

### The sibling shove — and why a wrapper, not a smaller scale

**A `UIScale` on a child of a `UIListLayout`/`UIGridLayout` changes that child's MEASURED size**, so
the layout re-flows and every sibling slides while you hover one card. Measured before designing
anything: a 150px card at scale 1.2 pushed its neighbour **30px**.

`Motion.isolate()` puts a fixed-size wrapper between the layout and the card and moves the UIScale
onto the card inside it. Re-measured with the wrapper: the neighbour moved **0px** while the card
still grew 150 → 195. B27's rule survives intact — the WHOLE card scales, carrying its `UICorner`
and `UIHoverStroke` with it — it just costs the neighbours nothing now. Two traps the wrapper had to
learn: it must never set `ClipsDescendants` (it would crop the growth it exists to allow), and it
must **clone the card's `UIAspectRatioConstraint`** — the first cut produced a 175×**405** slot for a
175×175 card and left every card floating in vertical dead space. Because the wrapper is now what
the layout sees, visibility/order/disposal go through `Motion.setVisible` / `setLayoutOrder` /
`destroy`, or a filtered-out card leaves an empty slot padding the row.

### The hotbar had no hover at all — and the reason is worth remembering

`UIKitButton` animated the stroke's **Thickness and Transparency** and never touched **`.Enabled`**.
V2's `UIHoverStroke` ships authored `Enabled = false`. So on every V2 slot the hover faithfully
tweened a stroke that was switched off, and nothing appeared. A stroke that starts disabled is now
detected as hover-only from its authored state — no new Attribute demanded of every template.

### The rest

- **Idle gradient**: 3s → **9s** and tilted **45°**. Three seconds reads as a nervous flicker on a
  card you are staring at; nine is a slow sheen. Diagonal reads as light falling across the card,
  where horizontal reads as a loading bar.
- **Curves**: one Quint ease-out for the whole kit — hover 0.26s, press 0.09s, **rest 0.30s**. Rest
  is deliberately the slowest leg so nothing snaps back; a press is the fastest so it feels immediate.
  `lift()` raises a hovered card's ZIndex so its growth is never drawn *under* the next sibling.
- **`SecondaryValueScale` 0.32 → 0.62.** The user's verdict was "too dark". At 0.32 Rare's secondary
  was `(18,42,82)` — close enough to black that the card read as a fade-to-nothing. At 0.62 it is
  `(34,81,158)`: the same blue, in shadow.
- **Prices are visible, and they are not real.** The standing rule is hide-never-invent; the user
  explicitly suspended it *"just to see it visually when testing"*. `PlacementPrice` renders the
  **template's authored placeholder** on unit cards and on filled hotbar slots (never on an empty
  slot — a price floating on nothing is noise on top of fiction). `Motion.SHOW_PLACEHOLDER_PRICES`
  is the single switch that puts every card in both Places back to honest.

`UIKitMotion` is the **27th manifest entry** (20 modules + 7 templates) and is registered in
`tools/hash_shared.luau` — an unregistered module is silently skipped by the drift check, which
would be a worse bug than anything above.

### Acceptance — live Lobby

A first run reported **"Units cards wrapped by Motion = 0"**: `loadUnits` called `setupCard` (which
isolates) *before* parenting the card, so the wrapper was built under a nil parent and the following
`card.Parent = container` pulled the card straight back out of it. Ordering fixed and re-run:
**8/8 cards wrapped, 0 strays; hover grew the card 175→188 with the neighbour moving 0px; wrapper
175×175 matching the card exactly; gradient Rotation 45; price visible; hotbar 6/6 wrapped, slot
161×161, stroke off at rest in the tier's brightest colour.** All five shared modules verified
byte-identical in both Places and on disk.

### Still open (1 of 7)

`HUD.Left` mutual exclusion and slide open/close. Build them on `Motion` — the point of this session
was to stop a fourth animation dialect being born.

## 2026-08-16 [both] B27b — AD-Integration: `Data.Loadout` prunes on load, the Units screen moves onto `UnitIconV2` + the shared preview, and a level bar that has **never once filled** starts working.

The user fixed the templates themselves (Units cards are `UnitIconV2` now, and they dropped a copy
of `Kit.UnitPreviewTemplate` in as the hover preview) and asked for the wiring, with a standing rule
for the fields: **render what the data actually has, hide the rest — but write the hidden ones so
they light up on their own the day their source lands.** Three decisions were put to them first.

### `Data.Loadout` no longer keeps dangling uuids

`LoadoutService.clean()` has always dropped uuids the player no longer owns — but it **only ever ran
inside `SetLoadoutSlot`**. A profile whose units vanished any other way kept dead uuids forever,
because nothing re-examined the list until the player happened to equip something. Live, that read
as: three loadout entries against **one** surviving `Data.Units` record, so the hotbar drew three
EMPTY slots while its own diagnostic said *"3 equipped"*. Every screen was correct; the data was not.

The prune now runs on `ProfileLoaded` (plus a one-shot sweep for players already in the server, so a
Studio reload is covered). It lives in `LoadoutService` **deliberately, not in
`LobbyServices.GetUnitViews`** — that service is documented as the first and only writer of
`Data.Loadout`, and making a READ path write would trade the invariant away for a tidy-up. It only
removes entries with no surviving unit; it never reorders survivors, never adds, and **deliberately
does not** drop entries past the level-gated `UnlockedSlots` — silently unequipping a real unit
because a level read oddly would be worse than the bug being fixed. Verified live:
`Loadout pruned for <user>: 3 -> 0 entries`, and the hotbar now honestly reports `0 equipped`.

### A level bar that never filled, in two different screens

The bar is named three different things: the Kit master shipped it as **`CanvasGroup`**, the user's
copy called it **`EXPLevelBar`**, and **both** `UIKit.Hotbar`'s preview and `UnitsController.fillStats`
looked for **`UnitLevelBar`** — which existed in neither. So the hotbar's hover preview has shown the
authored placeholder level since the preview was restored at B6, and the Units preview never filled
either. Same class of latent dead branch as `IndexController`'s `CountLabel` at B26.

**User's call: rename the master.** `CanvasGroup` → `EXPLevelBar` in BOTH Places, both readers
repointed. `Kit_UnitPreviewTemplate` `55e17da8` → `2b423401`, `UIKitHotbar` `5b8b1609` → `69ba6ed1`.
The old name is **not** kept as a fallback — nothing ever had it, so a fallback would only preserve
the illusion that it once worked. **No cross-Place paste was needed:** renaming an instance is a
within-Place operation, so the identical edit was applied in each Place and hash-matched — the
`checklists.md` "identical deterministic build" path rather than the copy path.

### The Units screen

**Cards** now clone the shared `Kit.UnitIconV2` master (not a screen-local template), matching
Summon/Index/Ascension. **The hover preview** clones `Kit.UnitPreviewTemplate` at runtime exactly as
`UIKit.Hotbar` does — the user's local copy was verified **identical to the master across every
hashed property except that one rename**, so it was deleted rather than kept as a second source of
truth. Field wiring, per the user's rule:

| Field | Behaviour | Why |
| --- | --- | --- |
| `UnitName`, `ViewportFrame`, `UnitLevel` | filled | the view carries them |
| `EquippedIcon` / `FavoriteIcon` / `LockedIcon` | shown per flag, **read-only** | B24: no remote writes Favorited/Locked, and `AscensionRules` treats both as protection from being eaten as a dupe — making them clickable is a gameplay change |
| `TraitIcon` | reads `TraitRegistry.Get(view.Trait).Icon`, hides when absent | the trait EXISTS; only the icon does not. Lights up with no code change the day `TraitDefinitions` gains `Icon` |
| `PlacementPrice`, `ElementIcons` | hidden | Game-only tower-config data. Never invent a price |
| `CountLabel` | hidden | **not missing data — meaningless here.** Every card is ONE unit instance keyed by uuid, so a count is always 1. Index counts because its cards are per-TOWER |

The card also picks up B27's kit rules: rarity on the root gradient, hover stroke in the tier's
brightest colour, and the **whole card** scaling. Selection reuses the hover stroke (`hovering or
selected`), with the outgoing card explicitly repainted — without that the highlight accumulates and
every card ever clicked stays outlined.

### Acceptance — live Lobby

8 cards rendered, no leftover sample in the container. Sample (Necromancer, Mythic): `UnitName`
'Necromancer', `UnitLevel` 'LVL 20', root gradient 13 stops, hover stroke `250,240,60` (Mythic's
yellow), UIScale on the root, centre-anchored. Equip/favourite/lock, `TraitIcon`, `PlacementPrice`,
`ElementIcons` and `CountLabel` all hidden. **Exactly one** card carried the stroke and it was the
selected one. Levels across all eight matched the dev seed exactly (100/100/100/20/20/20/6/5) —
proving the writes are real and not the `LVL 100` placeholder that bit B26. `HoverPreview` present
with `EXPLevelBar`. Both Places hash-identical on both changed entries.

### Decision logged, not taken

`UnitIconV2` now has FOUR inline consumers each repeating paint/hover/viewport code. The user chose
to keep Units inline for now rather than extract a `UIKit.UnitIcon` controller mid-session; Units is
the screen that would shape it, since it is the only one needing equip/favourite/lock. PENDING.

## 2026-08-16 [both] B27 (partial) — AD-Integration: **no tier is a single colour any more**, hover strokes take the tier's brightest colour, and the WHOLE button scales instead of just its artwork. 3 of the user's 7 play-test fixes; 4 remain.

The user played the build and came back with seven fixes. Three of them are shared canon and had to
land first because everything else reads them; the other four are Lobby screen work and are queued.

### (1) Every tier has at least two colours — `TierConfig` `490f1f9d` → `7d5850c1`

*"there should not be a single colored tier, There will be minimum of two colors each rarity. A Main
color and a secondary color, the secondary color is a much darker version of the main color when it
only has 1 color."*

A tier that authors ONE colour now gets its second entry **derived at load** rather than hand-typed,
so the authored table stays the single source of truth and nobody has to keep a light/dark pair in
sync by eye. `TierConfig.Darken` works in HSV and **scales only VALUE, preserving hue and
saturation** — a "much darker" Rare has to still read as blue, and dropping saturation too would
slide every tier toward the same charcoal. One knob: `SecondaryValueScale = 0.32`.

The derived colour is **appended into `Colors`**, not added as a separate field, and that is the
whole point: `colorSequence`, `seamlessSequence` and `isMultiColor` are untouched, every tier now
animates instead of sitting flat, and there were **zero call-site changes in either Place**.
Mythic's rainbow and Secret's authored red→dark-red are **left exactly as authored** — they already
satisfied the rule. `GetColor` still returns `Colors[1]`, the MAIN colour, so nothing that read
`.Color` moved. `isMultiColor` is now true for every tier; it had no callers outside the module.

### (2) Hover strokes take the tier's BRIGHTEST colour

New `TierConfig.BrightestColor`, wired into `UIKit.ItemIcon`, `UIKit.Hotbar` and the three screen
controllers' `paintTier` (tinting there, not in `wireHover`, keeps the tier in one place —
`wireHover` only ever knew how to toggle `Enabled`).

**Brightness is RELATIVE LUMINANCE, not HSV value, and the difference is not academic:** by HSV
value Mythic's red, orange and blue all tie at 1.0 and whichever is first wins arbitrarily; by
luminance the yellow correctly wins, which is what the eye calls the brightest one. Never
`Colors[1]` and never the new dark secondary — a stroke in the dark shade reads as a shadow rather
than a highlight. An **empty or locked hotbar slot keeps a neutral outline**, for the same reason
its gradient falls back to grey: no unit, no tier.

### (3) The whole button scales, not just the image inside

`UIKitButton` `4968d8c3` → `6cc33829`, `UIKitItemIcon` `cf5e57cd` → `5cc07ce2`. The UIScale moved
from `Frame`/`Main` to the **ROOT**. The old arrangement grew the artwork while the button's own
`UICorner` and `UIHoverStroke` — which live on the root and size themselves from it — stayed exactly
where they were, so the card came apart at its edges on every hover.

**Centre-anchoring the root is layout-safe, and that was MEASURED rather than assumed.** A
`UIGridLayout` child and a `UIListLayout` child were both sampled before and after setting
`AnchorPoint` to `(0.5, 0.5)`: **neither moved** — a layout overrides the anchor offset when it
assigns `Position`. For a free-positioned button `centerAnchor` compensates `Position` itself. Any
UIScale a template shipped on the inner content is reset to 1 so the two cannot multiply.

### Acceptance — real LocalScript, live Lobby

**13 PASS / 1 FAIL, and the FAIL was the harness, not the product:** it measured `AbsoluteSize` on a
card parented to a **disabled** ScreenGui, where nothing lays out and everything reads `0x0`. Re-run
with the ScreenGui enabled and the holder parked off-screen, a card in a `UIGridLayout` went
**150×150 → 158×158 with its centre unmoved**, `UIHoverStroke` parented to the root and coloured
`255,205,55`. Also proven: 8/8 tiers ≥ 2 colours; Rare's derived secondary keeps hue `0.604` and
drops value `1.00 → 0.32`; Mythic brightest = `250,240,60` (its yellow, not its red); Secret
brightest = the red, not the dark red; an empty slot outlines `150,150,165`.

All four modules verified **byte-identical in both Places and on disk** before landing.

### Still queued (4 of 7)

`UnitsGUI.Main.Bottom.UnitsContainer` still uses its own unit template and wants `UnitIconV2`;
`HUD.Left` buttons must become mutually exclusive (opening one closes the open one); open/close
wants a **slide**, not a visible-toggle pop; and `UIGradient` colour changes want smooth tweening.

## 2026-08-16 [both] B26 — AD-Integration: **the V2 kit is ADOPTED in BOTH Places and v1 is RETIRED.** Six consumers migrated, three instances authored, one placeholder-as-truth bug caught by the acceptance run.

B25 stopped at the gate with three missing instances and one design question. The user answered
both — **rarity on the root `UIGradient`, no tier border** (B25) and **"yes, I author them"** (B26) —
so this session did the whole adoption end to end.

### The user copied the templates; the assistant could not

**USER RULE, stated verbatim this session:** *"if you want to copy the v2 ui kits on game place,
tell it to me, dont try to copy it because afaik you cant copy paste an instance to another place,
pause, ask me to copy paste it to other place then ill tell you to continue."* The rule is correct
and is now written into `tools/checklists.md` step 2, which previously said "Studio copy/paste"
without saying **who**. `execute_luau` is scoped to one datamodel; nothing an assistant can call
crosses Places. The session paused, published the exact paths + expected hashes, waited, and then
verified the paste **byte-for-byte by hash** rather than by eye.

### Three instances authored (user-delegated), each fixing something that was silently broken

- **`SlotNumber`** on `HotbarSlotV2` — `UIKit.Hotbar` does `setText(btn, "SlotNumber", i)`. Without
  it every slot loses its 1–6 key number **in both Places**.
- **`CountLabel`** on `UnitIconV2`, as a real **TextLabel**. v1's was a **Frame**, while
  `IndexController` guards on `IsA("TextLabel")` — so the index owned-count had **never rendered
  once**. The acceptance run proved the branch is now live: 7 index cells had their text
  overwritten (authored placeholder `x1` → written `x0`), which a Frame could never have done.
- **`UIAspectRatioConstraint`** on `ItemIconV2` (1 / FitWithinMaxSize / Width) — `ObtainRewards`
  documents it twice as the reason reward art is not stretched in the 150×150 grid.

### Migrated

`UIKit.ItemIcon` and `UIKit.Hotbar` (shared, written into BOTH Places, verified byte-identical),
`SummonController`, `IndexController`, `AscensionController`, `ObtainRewardsController`.
The three screen controllers shared an identical `paintTier`; it is now `paintTier` +
`wireHover` in each. Renames applied: `NameLabel`→`UnitName`, `LevelBadge`→`UnitLevel`,
`CostLabel`→`PlacementPrice`, `IconImage`→`ItemIcon`, `QtyBadge`→`Amount`.
`ObtainRewardsController`'s `paintTier` deliberately handles **both** shapes, because it also paints
the user's Lobby-local `UnitTemplate`, which is still v1-shaped and was not part of this migration.

**Two paint surfaces collapsed to one.** v1 painted a border (`UIStrokeWithGradient`) *and* a
background (`BG`'s own gradient) and carried a long comment warning not to confuse them. Neither
instance exists in V2, so the hazard is **deleted, not re-created**. `UIHoverStroke` is hover-only.
`FindFirstChildOfClass` on the ROOT is load-bearing everywhere: V2 nests `UIGradient`s under
`UnitLevel` / `PlacementPrice` / `TraitIcon`, and a recursive find repaints the wrong one.

**Nothing was invented.** `PlacementPrice`, `ElementIcons` and `TraitIcon` render **HIDDEN** — they
have no data source (the two B24 proposals are still open). `UnitLevel` shows only when the entry
actually carries a level. **Known regression, recorded not papered over:** V2 has no `ShinyBadge`,
which `AscensionController` drove from `view.Shiny` — shiny is no longer marked on an ascension card.

### The acceptance run caught a real bug — a placeholder rendered as truth

`UIKit.Hotbar` wrote the level with `setText(levelFrame, levelFrame.Name, ...)`. `setText` does
`root:FindFirstChild(name, true)`, which walks **descendants only and never matches `root` itself** —
so it found nothing, returned silently, and left `HotbarSlotV2`'s **authored placeholder `"LVL 100"`
on screen for every unit, in both Places**. Fixed to `setText(btn, "UnitLevel", ...)` from the slot
root. `UIKitHotbar` `78328bb4` → **`baec9162`** in both Places and in `shared/src`.

Two things about this are worth keeping. First, **an assertion that only checked `.Visible` passed
it** — printing the TEXT is what exposed it. Second, it was **invisible in the Game**: that Place's
dev seed happens to run Archer/Babaylan/Farm at MetaLevel **100**, identical to the placeholder. It
only surfaced in the Lobby, against a synthetic entry with `MetaLevel = 7`.

### Acceptance — from a REAL LocalScript in EACH Place

**LOBBY 39 PASS / 0 FAIL** then **8 PASS / 0 FAIL** on the fix re-run; **GAME 18 PASS / 0 FAIL.**
Proven with real data, not mocks: item cards fill `ItemIcon`/`ItemName`/`Amount` (`Amount` hides at
qty 0); rarity on the root gradient is **value-equal** to `TierConfig.seamlessSequence(tier)`,
including Mythic's 13-keypoint rainbow; empty slots fall back to neutral grey rather than a stale
tier; `SlotNumber` reads 1–6; `UnitLevel` renders `LVL 7` / `LVL 42` and **hides** with no level;
`PlacementPrice` and `Placed/MaxPlacement` are present-but-hidden. Live screens: Items grid 5 cards,
reward grid 3 cards, index 32 cards, summon 20 chips, both hotbars 6 slots.

**Hover honesty.** `MouseEnter` still cannot be fired from tooling, so what is proven is that
`paintStroke()` — *the same function both `MouseEnter` and `MouseLeave` call* — toggles
`UIHoverStroke` on and off, and that the stroke is authored `Enabled = false` at rest. The live
Items grid showed **exactly one** card with the stroke on, and it was the **selected** one
(`paintStroke` is `hovering or selected`). The end-to-end trigger stays on the existing PENDING.

### Not our bug, found on the way

The Lobby dev profile's `Data.Loadout` holds **3 uuids that no longer exist in `Data.Units`**
(`Units` has 1 entry), so the Lobby hotbar correctly renders three EMPTY slots for "3 equipped".
Nothing prunes a loadout entry when its unit instance goes. New PENDING.

Manifest: still **26 entries**, `Kit_UnitIcon`/`Kit_ItemIcon`/`Kit_HotbarSlot` **retired** the way
the RewardPopup pair went at B2 — deleted in both Places, dropped from `hash_shared.luau`, **do not
re-add**. Both Kits now hold 7 children. **LOBBY 26/26, GAME 25/26** (`MetaMath`, expected).

## 2026-08-16 [both] B25 — AD-Integration: the V2 kit adoption **STOPPED AT ITS GATE**. Every consumer audited, one blocking design question **answered by the user**, three still open. **Nothing migrated, nothing touched.**

Both Studio ids had rotated **again** — six sessions running (B19–B25) — and neither instance came
back active. Each Place was resolved by NAME and every `execute_luau` opened with the aborting
two-way assertion. `PlaceId` confirmed on both: Lobby `83342803778137`, Game `125430066355564`.

Bootstrap drift, checked **value-by-value against the manifest** rather than for presence:
**LOBBY 26/26 matching, 0 mismatched, 0 missing. GAME 25/26, the only gap `MetaMath`** (expected
until Phase D). The V2 templates hash `UnitIconV2 e9fc62ed` / `ItemIconV2 b04997f6` /
`HotbarSlotV2 2d9e528e` and are **Lobby-only additions**, which is exactly why drift is green with
them present. Integration gate: **this IS the Integration session** and the work is shared canon
spanning both Places — proceeding. `STATE.md` + the changelog tail re-read immediately before
landing; **no sibling had landed** (clean tree, `f7026e6` still HEAD).

**THIS SESSION WROTE NOTHING TO EITHER PLACE.** No template, no consumer, no manifest entry, no
instance. Both Places end exactly as they began. That is the outcome, not a shortfall — see below.

### The brief's stop condition fired, on all three templates

*"STOP AND ASK IF the migration turns out to need a v1 field the V2 template lacks, or if any
consumer would visibly regress — a proposal + PENDING is the correct outcome over a half-migration."*

**The blocker is structural, not cosmetic: v1 paints rarity onto TWO instances and V2 has neither.**
`BG` (an ImageLabel whose `UIGradient` is the tier fill) and `UIStrokeWithGradient` (the tier border)
are referenced by **every single consumer** — `SummonController`, `IndexController`,
`AscensionController`, `UIKit.ItemIcon`, `ObtainRewardsController` and `UIKit.Hotbar`. The V2
templates have one root `UIGradient` and a `UIHoverStroke` that is authored `Enabled = false` and
reserved for hover. `UIKit.Hotbar` even carries a comment warning not to confuse the root
`UIStrokeWithGradient` with the one nested under `BG` — v1 deliberately uses two.

There is no honest mechanical mapping from two paint surfaces onto one, and painting rarity onto the
hover stroke would collide with the hover behaviour the brief asked for. **So it was put to the user
rather than invented.**

### ✅ THE USER ANSWERED IT — recorded so no future session re-derives it

**Rarity colour goes on the ROOT `UIGradient`. The tier BORDER is dropped.** One paint surface, one
`TierConfig.seamlessSequence` call site, no second gradient animator. The absence of a tier border in
V2 is an **accepted, deliberate visible restyle** across summon chips, index entries, the items grid,
the reward grid and both hotbars — it is not a bug and must not be "fixed" by re-adding a stroke.

That decision removes the largest unknown from the adoption. **Three smaller blockers remain**, and
each needs an instance the USER authors, because inventing UI in script is banned (rule 2026-07-18):

| Template | Missing | The exact call that needs it |
| --- | --- | --- |
| `HotbarSlotV2` | **`SlotNumber`** | `UIKit.Hotbar`: `setText(btn, "SlotNumber", tostring(i))` — the **1–6 key number on every hotbar slot in BOTH Places**, including the Game's placement hotbar |
| `UnitIconV2` | **`CountLabel`** | `IndexController`: `cell:FindFirstChild("CountLabel", true)` — the owned-count on every codex entry |
| `ItemIconV2` | **`UIAspectRatioConstraint`** | `ObtainRewardsController` documents it **twice** as the reason reward art is never stretched in the 150×150 grid |

### What the audit turned up that the brief did not have

- **`Kit.UnitIcon` has THREE consumers, not two.** The brief listed the summon chips and the index
  entries. **`StarterPlayerScripts.AscensionController` clones it too** for the dupe-picker grid
  (its line 199) and reads `LevelBadge`. A migration that missed it would have broken the ascension
  flow silently, since that screen only opens from an NPC prompt.
- **`ObtainRewardsController` clones `Kit.ItemIcon` directly** rather than going through the
  `UIKit.ItemIcon` controller — so the item card has two independent consumers, not one.
- **`StoryModeController` is NOT a consumer** and needs no migration: its `ItemIconTemplate` is a
  screen-local instance and it only calls `UIKit.ItemIcon.ImageFor`, a function.
- **The rename map is otherwise mechanical:** `CostLabel`→`PlacementPrice`, `LevelBadge`→`UnitLevel`,
  `NameLabel`→`UnitName`, `IconImage`→`ItemIcon`, `QtyBadge`→`Amount`. **`ShinyBadge` has no
  consumer at all** and is safe to drop.
- `HotbarSlotV2.Placed/MaxPlacement` **has a `/` in its instance name**, so it needs `FindFirstChild`
  and can never be reached by dot notation. Recorded before it bites someone.

### Deliberately NOT done, and why

- **The V2 templates were NOT copied to the Game.** The user chose "proposal + PENDING, stop". Copying
  them early would put unused instances in a second Place and invite a manifest that describes a kit
  neither Place actually uses. The copy belongs in the same session as the migration.
- **No half-migration.** Every consumer is blocked on the same rarity surface, so there was no
  meaningful subset that was "clean" — a partial adoption would have left the kit split across two
  designs mid-flight.
- **`SlotNumber` / `CountLabel` / the aspect constraint were NOT authored by this session.** The user
  was offered that delegation (the B17/B19 precedent) and chose to stop instead. Authoring into
  someone's design without that authorisation is what the user rule exists to prevent.

### Verification

**Nothing was built, so there is nothing to prove from a real Script — and none was written.** What
WAS established, all from safe reads (`.Source` and instance properties via `execute_luau`, which
CLAUDE.md sanctions):

- Drift **value-by-value** in both Places (above), plus a full `Kit` child listing: **Lobby 10
  children** (7 v1 + 3 V2), **Game 7** (v1 only).
- The complete child inventory of all three V2 templates and all three v1 templates they replace.
- Every `FindFirstChild`/`WaitForChild` string literal in all six consumers, then the **exact source
  lines** for the contested names — which is how `SlotNumber`, `CountLabel` and the aspect constraint
  were confirmed as real uses rather than name-grep false positives.
- **Not proven and not implied:** that any V2 template renders correctly under any consumer. None has
  ever been cloned by anything.

- **Contract impact: NONE.** No shared module, template or contract touched. Drift identical before
  and after in both Places: Lobby 26/26, Game 25/26.
- **PENDINGs: ONE REPLACED** (B24's "adopt the V2 kit" → B25's precise, blocked-on-the-user version
  carrying the rarity decision), **ONE RETIRED AS A CONCEPT** (see below). Nothing else moved.
- **STANDING PRACTICE RECORDED (user, this session): they republish BOTH Places EVERY session.** The
  "republish" PENDING is **deleted and must never be re-opened** — `STATE.md` now says so in as many
  words. A session that bumps a contract should still *state* it in its advisory, because both Places
  must go out together, but it is not something the user owes.
- **Docs:** `docs/systems/ui-kit.md` gained the full V2 section (the canon home), both
  `CONTEXT.md` files updated and compressed back to **150/150**, `STATE.md` **120/120**,
  new proposal `docs/proposals/2026-08-16-v2-kit-adoption-gaps.md`.

## 2026-08-16 [lobby] B24 — AD-UI: the five-item review backlog **CLEARED** (all five correct), the reward preview mirrored into `LobbyFrame`, and the V2 kit audited — **three of its fields have no data source at all.**

Bootstrap: **Lobby 26/26 matching, 0 drifted, 0 missing** (checked against the manifest value-by-value,
not just for presence). Integration gate: **No Integration needed — proceeding** for everything that
landed. **The active instance was the GAME again and BOTH ids had rotated** (the B19–B23 hazard, now
5 sessions running), so the Lobby was resolved by NAME and every `execute_luau` opened with the
aborting assertion.

**THE FIVE-ITEM REVIEW BACKLOG IS CLEARED — all five confirmed CORRECT, nothing needed changing.**
These were written by OTHER chats inside AD-UI's canon under the user's authorisation; this is the
review AD-UI was owed. Read from source, not from the changelog's claims about it:
- **B7** — `SummonController.blockedReason` delegates to `BannerRegistry.BlockedReason` and falls
  back to `EndsInText`. ✅ **A grep for the old hardcoded `BannerType ~= "Standard"` DOES still hit —
  on line 183, inside the comment that explains what it used to do.** Confirmed comment-only; the
  live path is one delegating line. Worth recording so the next grep does not raise a false alarm.
- **B8** — `IndexButton` exists on `SummonScreen.Main.Panel`; `IndexController` wires it itself and
  listens on `OpenIndex`. `SummonController` does not mention it at all — which is the POINT: B8
  changed no AD-UI controller code. ✅
- **B9** — `selectUnit` publishes `Uuid` + `TowerId` as attributes on `SelectedUnitFrame`, the same
  idiom `loadUnits` already uses per card. No second read path. ✅
- **B10** — `doEquipToggle` computes a slot INDEX and asks; **the server's answer is taken as truth**
  (`loadoutList = res.Loadout`), the dense-list contract is respected, and `LoadoutChanged` is fired
  for the hotbar. ✅
- **B11** — EQUIP/UNEQUIP gradient AND stroke are **set on every refresh rather than toggled**, so the
  button cannot strand on the wrong colour; the one-per-family guard correctly EXEMPTS a same-family
  swap from the "loadout full" block (a swap does not grow the list). `AscensionPanel` is absent from
  `SelectedUnitFrame` and `UnitsController` does not mention Ascension at all — ADR-0010 held. ✅

**TWO INCIDENTAL FINDINGS the review turned up, recorded rather than silently fixed:**
- **`QuickSellButton` does not exist.** Phase C's sell-dupes note in `STATE.md`/`ROADMAP` says it
  "needs the unwired `QuickSellButton`" — `SelectedUnitFrame` has no such child. The doc describes a
  button that was never authored.
- **`LockUnitButon`** (sic — missing an `n`) IS authored in `SelectedUnitFrame` and is **unwired**.
  Directly relevant to the Lock feature below.

**`LobbyFrame.RewardsFrame` now mirrors the Story panel — off ONE `GoldBand` computation.**
B21's follow-up. `LobbyFrame` is the last thing a player reads before committing, so the two panels
disagreeing about the payout would be worse than one of them being blank.
- **Its `ItemIcon` was still unrenamed and `Visible = true`** — the exact authoring state the Story
  panel had before B16's fix. Renamed to `ItemIconTemplate` + `Visible = false`, mirroring B16.
- `renderRewards` was **factored into `renderInto(scroll, template, list)`**, and the single
  `refreshRewards` (one `GoldBand` call) renders the SAME list into BOTH panels. **A second
  `GoldBand` call site is exactly how the two would silently drift**, which is why the brief banned
  it and why this is a factoring rather than a copy.
- The Lobby path is spelled out NON-RECURSIVELY on purpose: `SelectedAct` exists under BOTH frames,
  so `FindFirstChild("SelectedAct", true)` returns an arbitrary one.

**THE V2 KIT: AUDITED, NOT ADOPTED — and the audit is the deliverable.** The user authored
`Kit.{UnitIconV2, ItemIconV2, HotbarSlotV2}` and asked for equip/favourite/lock plus placement price,
name, element icons, trait icon and level.
- **They are ADDITIONS, not edits** — the v1 templates still hash to their manifest values, which is
  why drift reads 26/26. Nothing was broken by their arrival.
- **Three of the requested fields have NO data source in this Place, and no UI work fixes that:**
  `UnitStatsCatalog` is literally `Archer = { DMG = 15, RNG = 20, SPA = 6 }` — **no cost, no
  element**; `ItemCatalog` has neither; `RS.Configs.Towers` does not exist here by design.
  `TraitDefinitions` has **no `Icon`/`Image`/`assetid` field at all**. Proposals filed:
  `docs/proposals/2026-08-16-tower-display-fields-for-uniticon-v2.md` (AD-Game) and
  `2026-08-16-trait-icons.md` (AD-Traits), each with the exact shape needed. **Same precedent as the
  reward curve before B20:** the rendering is AD-UI's, the numbers are not, and a fabricated ₱67,000
  is the identical class of lie §8 exists to prevent.
- **Favourite and Lock are READ-ONLY.** `Favorited`/`Locked` are in the profile and the view, but
  **none of the 17 remotes writes them**. Making them togglable needs a new remote + server writer —
  and `AscensionRules` already treats both flags as protection from being consumed as a dupe, so
  that is a gameplay change, not a UI one. The user chose display-only for now.
- **Adoption is CROSS-PLACE and was NOT started.** The user chose "replace v1 outright", which
  migrates the GAME's hotbar (it consumes `Kit_HotbarSlot` through the shared `UIKitHotbar`
  controller) and rewrites the manifest for both Places. **That cannot land from a Lobby-only
  session**, so this session stopped at the boundary rather than leave the manifest describing a
  state that is not true in the Game. Recorded as a PENDING with the constraint spelled out.

**Verified live from a REAL LocalScript + `get_console_output`** — never `execute_luau` for
behaviour. `StarterPlayerScripts.B24Harness` **DELETED at landing**.
**`[Test] B24 RESULT: PASS (9 pass, 0 fail)`**: at UI 1% / 50% / 100% both panels showed the
identical band (`100-300`, `199-399`, `300-500`) matching `GoldBand`; Insane added the SAME 2 cells
to BOTH (`Reward_BannerTicket`, `Reward_TraitRerollToken`) with the band unchanged; returning to
Normal dropped both to the identical set; leave still closes. The `[DIAG]` line now reports
`rendered: N cell(s) into 2 panel(s)`. All `Dev*` attributes swept OFF, no stray cells left in Edit.

- **Contract impact: NONE.** No shared module, template or contract touched — the V2 templates were
  READ, never adopted. Drift **26/26** before and after.
- **PENDINGs: the five-item review backlog DELETED** (ADR-0006). **Three added:** AD-Game's display
  fields, AD-Traits' trait icon, and AD-UI's cross-Place V2 adoption. The quests/login/codes reveal
  answer was split out as its own design PENDING rather than staying buried in the review item.
- **Push status:** `origin/main` was already current at bootstrap (the user pushes often), so this
  session started at 0 unpushed and adds one.

## 2026-08-16 [both] B23 — AD-Integration: teleport **v3 → v4** and **P7, the global matchmaking queue, SHIPPED**. `ItemCatalog` drift cleared. **PlayGUI P1–P7 COMPLETE.**

Both Studio ids had rotated **again** — five sessions running now (B19–B23) — so each Place was
resolved by NAME and re-confirmed on every switch, and every `execute_luau` opened with the aborting
two-way assertion. `PlaceId` confirmed on both sides: Lobby `83342803778137`, Game `125430066355564`.

Bootstrap drift was **exactly what the brief predicted, which is itself the point**: Lobby 26/26
hash-green; Game 25/26 with `MetaMath` MISSING (expected until Phase D) **plus the real `ItemCatalog`
mismatch B22 left on purpose**. Nothing had to be investigated. `STATE.md` + the changelog tail were
re-read immediately before landing; **no sibling had landed** (clean tree, `3aad4fc` still HEAD).

### The STOP condition fired first, and the answer changed the session

The brief said: do not stack a v4 on an un-republished v3. `STATE.md` still listed the v3 republish
as an open USER blocker, and B22's proposal had refused to build on exactly that basis. **So the
session stopped and asked before touching the contract.** The user confirmed **the v3 republish is
done**, which cleared the block — and that stale PENDING is now corrected rather than left to scare
off a third session. The user also chose the full §10 build over a contract-only bump.

### TASK 1 — `ItemCatalog` copied to the GAME (drift cleared)

The five icon lines only: Gold `128910310881167`, Silver `119213648374305`, BannerTicket
`6731922404`, TraitRerollToken `12590248124`, GoldenSeed `124757602236693`. **Copied, never
re-authored** — the module is AD-UI's canon and the ids are the user's own uploads. Re-hashed in the
Game to **`fc4b8023`**, 6520 bytes, byte-identical to the Lobby and to `shared/src`, with **zero
`rbxassetid://0` remaining**. `deployed.Game` flipped. Those five icons no longer render blank in the
Game. PENDING **deleted** per ADR-0006.

### §8 — the three Game-side questions, answered against live code. One of them found a bug.

The proposal said these could change the v4 delta. Two were clean; the third was not.

**Q1 — does the Game assume one party anywhere?** Almost nowhere. `PartyId` is carried onto
`matchState.ValidatedPlayers[uid].PartyId` and **read by nothing** (grep: three hits, all writes or
type declarations), so there is no uniform-`PartyId` assumption to break. End-of-match handling
(`MatchEndPresenter`, `MatchActionHandler`) iterates players individually. **Exactly one assumption
has teeth: GAME SPEED.** It is match-wide, and both the authority to change it *and* the 3× gamepass
entitlement come from `matchState.HostUserId` alone — so matchmade, a stranger elected by lowest
userId decides whether everyone gets 3×. **B23 deliberately did not change this.** Altering a
monetisation-adjacent rule inside a contract bump is exactly the kind of silent design decision this
project keeps refusing to make; it is now **logged** (`[CONTRACT] MATCHMADE match: speed authority
+ x3 entitlement come from the ELECTED host …`) and raised as a USER decision.
A happy accident worth recording: `MatchDirector` already falls back to **lowest userId** when
`HostUserId` is absent from `ValidatedPlayers` — the same rule the proposal picked for election, so
the two sides agree **by construction**, not by coincidence.

**Q2 — does it wait for the full roster, and what if someone never arrives?** It does **not hang**:
`MatchEntryService.waitForParty` waits ≤10s then starts with whoever is present, and `MatchDirector`
separately warns that missing profiles get an EMPTY loadout. Both fail forward. **But the survey
found a real bug, and it is not cosmetic.** `ValidatedPlayers` is built from the PAYLOAD, and
`playerCount = #userIds` over it feeds `EconomyManager`'s reward multiplier for **every kill and
every wave**. The curve is `{1=1.0, 2=0.9, 3=0.85, 4=0.8}`, fallback `0.75`. So **a lone survivor of
a 4-player launch played the entire match at 0.8× cash** — a silent 20% economy nerf paid for players
who were not there. Tolerable while one party launched together; the proposal itself says short
arrival becomes a **daily** event once matchmade. **Fixed:** `matchState.PresentUserIds` is now a
distinct list, the economy scales on it (floor 1), and the Ready-phase vote and `GrantWaveReward`
take it too — a listed-but-absent player can never cast a unanimous ready vote, which would have held
every matchmade Ready phase open to its timeout. Logged as `[CONTRACT] SHORT ROSTER: n of m`.

**Q3 — does anything need to know it was matchmade beyond rewards?** Only Q1's speed gate. Small
blast radius, which is why `IsMatchmade` earns its place as one boolean rather than a bag of fields.

### Contract v3 → v4

`IsMatchmade` added; `HostUserId` widened to the **elected match host**; **the "a match server
contains exactly one party" invariant is REPEALED**; the cross-server MemoryStore handoff documented.
Both integers moved together (`LobbyConfig.MatchLaunchVersion` / `GameConfig.TeleportPayloadVersion`
→ `4`). **Hard cutover** for the same reason v3 was: a Game that ignored an unknown flag would apply
one-party assumptions to a server full of strangers, and nothing would error. `IsMatchmade` is read
as **FALSE** when absent or non-boolean — the conservative default that preserves every existing
behaviour, and the correct stance for a client-forgeable payload. `DifficultyPercent` and
`DifficultyMode` keep their meaning, range and names; ADR-0011 is untouched.

### P7 — the queue

**`LaunchService` (new ModuleScript) is the launch body**, required by BOTH `PartyService` and
`MatchmakingService`. `PartyService` is a `Script` and cannot be `require`d, so the only alternative
was to COPY the reserve/teleport body — which is precisely the second launch path §12 forbids. **This
is one path with one more caller.** `Remotes.RequestLaunch` is still the only *client* entry;
`MatchmakingService` is a *server* caller. `PartyService` keeps all the policy (the remote, the host
check, the `PartyState` replies) and now reaches the Game through the same code the queue does.

**`MatchmakingRules` (new ModuleScript) holds the pure half** — `BucketOf` / `KeyFor` / `PackGroup` /
`ElectHost` — split out for the same reason B9 split `AscensionRules` out of `AscensionService`: this
service's only entry points are a remote handler and a MemoryStore poll, neither of which returns
anything a harness can assert on. "Which parties get grouped" and "who hosts" must be testable
directly. (A first pass exposed them via `_G` for the harness; that was wrong and was replaced.)

The three design calls were taken from the proposal unchanged. **Bucketing lives in
`MatchmakingRules.BucketOf` and nowhere else**, explicitly NOT in `PlayGUI.DifficultyScale` — that
module *converts* between the UI and wire scales (ADR-0011) and this one *partitions* an already-wire
value; two jobs, one greppable home each. **The match runs at the elected host's EXACT wire value**,
never an average. **A queue entry is a PARTY, never a player**, and `PackGroup` can only ever add a
complete entry, so "never split" holds by construction rather than by a check someone could delete.

**One design point the proposal left ambiguous, resolved and recorded:** "you take the 3 or the 2"
could mean *require an exact fill* or *allow an under-full match*. Requiring an exact fill starves
every 3-party until a solo happens to appear. So `PackGroup` returns a group when it either fills
`MaxPartySize` **or** joins at least two separate entries — and a single entry alone is explicitly
**not** a match, because that is just the party playing by itself, which `StartButton` already does.

`FindMatchButton` (under **StoryModeFrame**, not MainMenu) is live: the `disable()` call in
`PlayGUIController` is gone and the new `MatchmakingController` — the fifth PlayGUI script — owns it.
Its `InactiveOverlay` stays authored but hidden, so re-disabling is one call, not a re-author.
`RS.Remotes` **15 → 17**.

### Acceptance — 37 asserts, 0 failures, from REAL Scripts in BOTH Places

| § | Item | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Game hashes `ItemCatalog` at `fc4b8023` | **PASS** | 6520 bytes, `MATCH=true`, 0 × `rbxassetid://0` |
| v4 | both integers = 4 | **PASS** | `LobbyConfig.MatchLaunchVersion=4`, `GameConfig.TeleportPayloadVersion=4` |
| v4 | **v3 REJECTED** | **PASS** | `[CONTRACT] PayloadVersion mismatch: got 3, expected 4`; v2 rejected too |
| v4 | `IsMatchmade` survives to `matchState` | **PASS** | payload → `rawConfig` → `matchState.IsMatchmade=true` |
| v4 | absent / non-boolean → FALSE | **PASS** | `nil` → false, `"yes please"` → false (never truthy-coerced) |
| v4 | one payload, SEVERAL parties | **PASS** | 3 players across two `PartyId`s **plus one with none**, accepted |
| v4 | v3 fields intact | **PASS** | `wire=545 mode=Insane` unchanged; junk mode still fails safe to Normal |
| §6 | **short roster ⇒ economy counts ARRIVALS** | **PASS** | 4-name roster, 1 arrival → `SHORT ROSTER: 1 of 4`, multiplier **1.0 not 0.8** |
| §11 | bucket partitions, is not a conversion | **PASS** | 100→0, 545→4, 1000→9; 100 and 199 share bucket 0 |
| §11 | key separates act and mode | **PASS** | Normal ≠ Insane, Act1 ≠ Act2; wire 512 and 545 share one key |
| §11 | **a party is never split** | **PASS** | 3+2 for 4 slots → took the 3 whole or nothing, never 3+1 |
| §11 | packs whole entries; solo ≠ a match | **PASS** | 2+2 → full; 3+1 → full; a lone entry returns nil |
| §11 | host election deterministic | **PASS** | lowest userId **across both parties**, order-independent |
| §11 | host's EXACT wire carried | **PASS** | host entry's `HostWire=545` used, not an average |

**Reward asserts are on DELTAS and the short-roster proof used a real `StartMatch`** through the
production `BuildRawConfig` path. `MatchLifecycleSmokeTest` was temporarily `Disabled` for a
deterministic start and **restored**; both harnesses are DELETED and every `Dev*` attribute on the
authored `PlayGUI` verified OFF/0/"".

### What a single Studio instance CANNOT prove — stated per clause, not implied

- **The cross-server handoff. Permanently unprovable in Studio**: `ReserveServer` returns **HTTP
  403** there, in any mode. Every assertion above is on the payload **BUILT**, never on a completed
  teleport. (MemoryStore itself *does* work from Studio — B22 probed it; not re-checked.)
- **Two parties on two different lobby servers actually meeting.** One Studio client is one server,
  so the matcher's claim-then-commit, the `ServerId` ownership check and the handoff publish were
  exercised only as code paths, never as a race.
- **Timeout → offer solo, end to end.** The 45s branch and its client prompt were not driven live.
- **Abandonment cleanup under real failure** — expiry, and a server dying mid-claim.
- **`PlayerRemoving` / party-change removal** with a real second player.

- **Contract impact: TELEPORT v3 → v4, deployed BOTH Places in this ONE session.** No schema bump.
- **Shared canon:** `ItemCatalog` `deployed.Game` `789dca4b` → `fc4b8023`. Manifest still 26 entries.
  **Drift at landing: Lobby 26/26, Game 25/26 (`MetaMath` only).**
- **PENDINGs: TWO DELETED** (ItemCatalog copy, P7-is-v4 — both resolved outright, ADR-0006),
  **ONE CORRECTED** (the v3 republish, which the user had already done), **TWO ADDED** (the v4
  republish, and the matchmade game-speed design call).
- **Doc sizes:** `STATE.md` 116/120, both `CONTEXT.md` at 150/150, `teleport.md` 234/300.
- **USER, URGENT: republish BOTH Places TOGETHER again, for v4.** v3/v4 do not interoperate.

## 2026-08-16 [lobby] B22 — AD-Meta: P7 stopped at the scope gate (the global queue is contract **v4**, not a Lobby session) + the user's real icon assetids recorded as canon. **Nothing was wired.**

Two things happened and neither was the task as briefed. Both are recorded here rather than being
quietly absorbed, because a future session reading only the ROADMAP would otherwise mis-read the
still-disabled `FindMatchButton` as a bug and the `ItemCatalog` hash change as corruption.

Place binding: **both Studio ids had rotated again** (the B19/B20/B21 hazard, now four sessions
running), so the Lobby was resolved by NAME (`99d9dfa2…`) and every `execute_luau` opened with the
aborting two-way assertion — `Workspace.Lobby` PRESENT, `RS.Configs.Towers` ABSENT. Confirmed
`PlaceId=83342803778137`. `STATE.md` + the changelog tail were re-read immediately before landing;
**no sibling had landed** (working tree held only this session's files).

### ITEM 1 — bootstrap drift check caught a REAL mismatch, and it was the USER's

**26/26 PRESENT, but `ItemCatalog` read `fc4b8023` against the manifest's `789dca4b`.** B21 had
confirmed every entry matching on 2026-08-14, so this landed inside two days. **The session STOPPED
and asked before any write** (CLAUDE.md: "Mismatch = STOP, reconcile before any work", plus the
user's standing rule of 2026-08-16 — *when something looks changed, ask whether the dev did it*).
**The user confirmed it was theirs.**

- **The diff is exactly five lines**: the icon `rbxassetid://0` placeholders now carry real uploaded
  assetids — Gold `128910310881167`, Silver `119213648374305`, BannerTicket `6731922404`,
  TraitRerollToken `12590248124`, GoldenSeed `124757602236693`. Every other byte identical.
- **AD-Meta did NOT author this and does not own `ItemCatalog` (owner: AD-UI).** What B22 did was
  RECORD it: `shared/src/ItemCatalog.luau` was updated to the live Lobby bytes and re-hashed.
  **Byte-identity was PROVEN, not assumed** — 6459 → 6520 bytes (+61, exactly the five id-length
  deltas) and fnv1a `fc4b8023`, matching the deployed Lobby copy exactly. Substitutions were
  asserted unique before applying and no `rbxassetid://0` survived.
- **`deployed.Game` was LEFT at the stale `789dca4b` on purpose** (landing checklist step 2). The
  GAME still has the placeholders, so it is now genuinely DRIFTED and those five icons render blank
  there. **New PENDING for AD-Integration** to copy the bytes across — a Lobby-only session must not.
- Manifest hash `789dca4b` → `fc4b8023`, `deployed.Lobby` likewise, with the provenance in its
  comment so nobody later reads it as an unexplained edit.

### ITEM 2 — P7: designed in full, built not at all, and that is the correct outcome

The brief's own STOP-AND-ASK list fired on its first clause. §11's queue matches strangers **across
lobby servers**; `docs/contracts/teleport.md` says, in its own words, that delivery is reserved
servers per party so **"a match server contains exactly one party"**, and lists *"public /
matchmaking servers (join strangers)"* under **Still deferred**. Concretely, two things break:

- **`Players` would be incomplete.** `PartyService` assembles it from `party.members` resolvable
  **on this server**; a match spanning servers A and B has A sending `Players = {A's players}` and B
  sending `{B's players}`. That is a semantic change to a shipped v3 field.
- **The `ReservedServerAccessCode` has nowhere to travel.** One server reserves, the others must
  teleport into the SAME code, and the contract is explicit that there is "no MemoryStore handoff".

→ **teleport contract v3 → v4: BOTH Places, ONE session, synchronised republish** — and **v3 itself
is still un-republished**, so stacking a v4 on it would widen a live hazard. The user chose
**design-only**. Full design in **`docs/proposals/2026-08-16-p7-global-queue.md`**: the key mapped
onto the attributes this Place actually publishes (`SelectedActId` / `SelectedStageNumber` /
`DifficultyMode` / bucketed `DifficultyWire`), atomic bin-packing so a party is never split,
lowest-userId host election (deterministic, no extra round trip), 45s timeout → *offer* solo,
three-layer abandonment cleanup, the exact v4 delta, and the three questions only the Game can answer.

Three design calls worth not re-deriving: **bucketing is arithmetic on a difficulty number**, so it
gets ONE greppable home in `MatchmakingService.BucketOf` — and explicitly NOT in
`PlayGUI.DifficultyScale`, which is the ADR-0011 UI↔wire *conversion* and converts nothing here.
**The match runs at the elected HOST's exact wire value; members' values are never averaged** — an
average invents a difficulty nobody chose and silently moves everyone's `GoldBand` payout.
And **`PartyService` is a `Script`, not a `ModuleScript`**, so the build needs a `LaunchService`
module required by both it and `MatchmakingService` — **the same path with one more caller, not a
second launch path** (§12); said out loud because the next reader will reasonably suspect otherwise.

**Deliberately untouched:** `FindMatchButton`'s `InactiveOverlay` and `PlayGUIController`'s
`disable()` call on it. A half-enabled button is worse than an honest "COMING SOON", and both
`play-menu.md` and `CONTEXT.md` now say so in as many words.

### Verification — small, honest, and one STOP condition cleared

No behaviour was built, so there was nothing to prove from a real Script. What WAS established:

- **`MemoryStoreService` works from Studio in the Lobby.** Read-only probe in the Edit datamodel:
  `GetSortedMap("AD_Probe_B22"):GetRangeAsync(Ascending, 1)` → ok, 0 items. **No Studio setting
  needs flipping** — that STOP condition does not fire, and the build session should not re-check it.
- **`ReserveServer` = HTTP 403 in Studio** (unchanged since B20). The handoff's final step can
  **never** be proven in Studio in any mode — a permanent gap, not a session limitation.
- **Drift re-verified after the manifest edit: Lobby 26/26 GREEN, 0 MISSING, 0 mismatches.**
- **Not proven, and not implied:** every §11 acceptance clause — party-as-one-unit, host election,
  timeout→solo, the v3 payload surviving a matchmade handoff. None of it exists yet.

- **Contract impact: NONE CHANGED, ONE IDENTIFIED.** Teleport stays v3; B22 wrote no code. The v4
  delta is specified in the proposal for AD-Integration to execute.
- **Shared canon: `ItemCatalog` `789dca4b` → `fc4b8023`** (recorded, not authored). Manifest 26
  entries, unchanged in count.
- **PENDINGs: TWO ADDED, ZERO DELETED.** Nothing was resolved outright this session, so ADR-0006's
  delete rule had nothing to act on. Added: the `ItemCatalog` → Game copy, and P7 = contract v4.
- **Doc sizes after landing:** `STATE.md` 120/120 and `places/lobby/CONTEXT.md` 150/150 — **both AT
  cap**; `play-menu.md` 295/300. Room was made by compressing resolved history into the changelog
  (the B19 "CONTINUE is inert" warning, B21 fixed it; the B19 row-template authoring story; the
  CONTEXT PENDING list, which duplicated `STATE.md` and is now a pointer). **The next session to add
  a line to STATE.md or CONTEXT.md must compress first.**
- **Push status: 1 unpushed at bootstrap** (B21's `35e2cdd`; `origin/main` at B20's `3cd697a`),
  **2 after this landing.**

## 2026-08-14 [lobby] B21 — AD-UI: CONTINUE works again, and the reward preview shows the REAL band and tracks the slider. Both B19/B20 proposals closed.

Bootstrap drift **Lobby 26/26 GREEN, 0 MISSING** — the "25/26 is expected" note died at B20 and this
run confirms it: every entry present, `RewardScalingConfig=1d789978` included. Integration gate:
**No Integration needed — proceeding** (both items are Place-local AD-UI controllers; no shared
module, kit template or contract touched). **BOTH Studio ids had rotated again** — the B19/B20
hazard — so the Lobby was resolved by NAME and every `execute_luau` opened with the aborting
assertion (`Workspace.Lobby` present, `RS.Configs.Towers` absent).

**ITEM 1 — `ClientEvents.OpenStageSelect` has a listener again, so `ReturnScreen`'s CONTINUE works.**
P6 deleted `StageSelectScreen` at B19 and that screen's Controller was the event's ONLY listener, so
CONTINUE had been firing into nothing ever since: no error, no warning, the button simply did
nothing. Closes `docs/proposals/2026-08-13-openstageselect-after-stageselectscreen.md`.
- **`PlayGUIController` is the listener, and `OpenStageSelect` IS PlayGUI's public open event.**
  `lobby-ui.md` recorded that PlayGUI had no Open event and to add one "the day a second thing needs
  to open it" — that day is ReturnScreen. **No new event was invented:** `OpenStageSelect` already
  exists and already carries exactly the right argument, so an `OpenPlayMenu` would have been a
  near-duplicate.
- **`PlayGUI.Commands.SelectAct`** — a REAL authored `BindableEvent` (not `Instance.new`'d) — is the
  hop from the shell to the story lists. `selectAct` is a local in `StoryModeController` and
  `openMenu`/`goTo` are locals in `PlayGUIController`, so neither file reaches into the other.
  **It is a COMMAND path in, not a second source of truth:** `SelectedActId`/`SelectionSerial`
  remain the only answer to "what is selected".
- **Deliberately NOT routed through `DevGoto`/`DevSelectAct`.** Those are test fixtures; wiring
  product behaviour through them would make the harness load-bearing and impossible to remove —
  the same mistake both proposals explicitly declined to make.
- **Closed menu lands DIRECTLY on the target frame under the veil** (`openMenu` was refactored into
  `openMenuTo(frameName)`), so the player never sees MainMenu flash past on the way to Story Mode.
  **Already open → it animates across** via the normal `goTo`. The handler switches STAGE first if
  the act belongs to a different one, or its button would not exist in the Acts list yet — a no-op
  today (all three acts are Stage 1) but a Stage 2 suggestion from MatchReturn would have selected
  nothing.
- **A Luau ambiguity trap was caught in review, not by the runtime.** The `SelectAct` connection was
  first written as a statement starting with `(gui:WaitForChild(...) :: BindableEvent).Event:...`
  directly after a `refreshRewards()` call — Luau parses that as `refreshRewards()(gui:...)`. The
  only symptom would have been the script silently never running. Rewritten with a local.

**ITEM 2 — the reward preview is LIVE, reads the shared curve, and TRACKS the slider.** Closes
`docs/proposals/2026-08-14-reward-preview-wiring.md`. Both of that proposal's objections were real
and both needed fixing before a single number could be shown:
- **A band is not a quantity.** `renderRewards` painted `"x" .. qty`, which cannot express
  "Gold 100–300": `Qty = min` understates the payout, `Qty = max` overstates it, and two Gold cells
  reading `x100`/`x300` render as *two rewards*. An entry may now carry an optional **`QtyText`**
  that overrides the badge outright; item cells keep the existing `x<qty>` path untouched.
- **The call site was on the wrong edge.** `renderRewards` ran only from `fillSelectedAct` (act
  selection) while `DifficultyController.publish()` rewrites `DifficultyWire`/`DifficultyMode` on
  EVERY slider move. Wired there alone the panel would have frozen at the act's opening difficulty
  and then sat there contradicting the slider — worse than the blank panel it replaced. New
  `refreshRewards()` is called from `fillSelectedAct` **and** from `GetAttributeChangedSignal` on
  both attributes.
- **It reads `DifficultyWire`, never re-derives it from `DifficultyUI`** (ADR-0011 — `t` is
  `(wire-100)/900`, and the `/99` mistake pays MAX gold for a normal match).
- **`curveId` is `nil` on purpose** → `DefaultCurve = "Standard"`, which all three acts name today.
  The Lobby's mirror carries structure only, so there is no per-act `GoldCurve` here to read. No
  field was invented.
- **A missing `DifficultyWire` renders BLANK, not a normal band** — script order between the two
  controllers is not guaranteed, and a band not tied to a real difficulty is a claim.
  `refreshRewards()` also runs once at connect time to catch anything published earlier.
- **Insane ADDS cells; the band is identical.** `ItemsForMode` returns `BannerTicket` +
  `TraitRerollToken` on Insane, empty on Normal. All four ids were confirmed present in the shared
  `ItemCatalog` before wiring, so no cell renders a broken icon.

**Verified live (Play, Lobby) from a REAL LocalScript + `get_console_output`** — never
`execute_luau` for behaviour. **Assertions are on OBSERVED TRANSITIONS**, recorded from signals as
they happen (`DiagCurrentFrame`, `SelectionSerial`, `PlayGUI.Enabled`, `rewardsScroll.ChildAdded`),
not polled after the fact — the B19 lesson. `StarterPlayerScripts.B21AcceptanceHarness` was
**DELETED at landing** (all five historical harnesses confirmed absent).
**`[Test] B21 RESULT: PASS (19 pass, 0 fail)`**:
- (1) firing `OpenStageSelect("Stage1_Act3")` on a CLOSED menu: `Enabled` observed going `true`,
  frame observed landing on `StoryModeFrame`, act observed selecting `Stage1_Act3` — one frame
  event, no MainMenu flash. Firing again while OPEN switched to `Stage1_Act1` with zero new frame
  events. An unknown id (`Stage9_ActNope`) warned and changed nothing.
- (1) **the real CONTINUE button**, proven in a second run with `MatchReturnService
  .DevSimulateReturn` set in the EDIT datamodel (it only fires on JOIN — setting it mid-session
  does nothing, which cost one run): banner built, `ContinueButton` present, `Active=true`, text
  `"CONTINUE: Rising Legend (Stage 1 - Act 2)"`. Tooling cannot synthesise a click, so the last
  link — Roblox firing `Activated` — is the only unproven one, and it is not our code.
- (2) driving the SLIDER: UI 1% → wire 100 → badge `100-300`; UI 50% → wire 545 → `199-399`;
  UI 100% → wire 1000 → `300-500`, each matching `GoldBand` exactly. Endpoints re-asserted against
  the config: 100→`100-300`, 550→`200-400`, 1000→`300-500`.
- (2) tracking proven by OBSERVATION: cells were added *during* a slider move, and the band
  changed `100-300` → `300-500`. Insane added exactly 2 cells (`Reward_BannerTicket`,
  `Reward_TraitRerollToken`) with the band unchanged at `199-399`.
- (R) leave still closes and restores 14 GUIs; 16 ScreenGuis present after the round trip; no
  `Infinite yield`, no errors.

- **Contract impact: NONE.** No shared module, template, schema or teleport change. Drift **26/26**
  before and after. `RewardScalingConfig` was READ, never edited — its stale header comment is
  AD-Game's PENDING and was left alone.
- **PENDINGs: two DELETED outright** (ADR-0006 — the changelog is their record): the `OpenStageSelect`
  listener and the reward-preview rendering decision. **One small follow-up recorded instead of
  silently skipped:** `LobbyFrame.RewardsFrame` still shows nothing. B19's stated reason (the curve
  is not deployed here) EXPIRED at B20 — the real reason now is scope, since B21 wired only the
  Story panel the proposal named. Mirror `refreshRewards` off the SAME published attributes; do not
  add a second `GoldBand` call site that could drift.
- **Push status: everything is already on origin.** The brief said five commits were unpushed; the
  user had pushed in the meantime (`origin/main` = `3cd697a` = B20 at bootstrap), so this session
  started at 0 unpushed and adds exactly one.

## 2026-08-14 [both] B20 — AD-Integration: `RewardScalingConfig` copied to the LOBBY, and teleport **v2 → v3** puts the difficulty MODE on the wire. **Insane is reachable.**

A genuine cross-Place session: both of P5's dangling threads closed together, which is exactly why
they were Integration's and not AD-Game's or AD-Lobby's. **Studio ids had rotated again** — the
prompt's warning held — so `list_roblox_studios` → `set_active_studio` → confirm-by-name ran before
every write, and every `execute_luau` opened with a two-way Place assertion that ABORTS on mismatch
(`Workspace.Lobby` PRESENT + `RS.Configs.Towers` ABSENT for the Lobby, and the inverse for the Game).

Bootstrap drift was **exactly the predicted state, zero surprises**: Lobby 25/26 with
`RewardScalingConfig=MISSING`, Game 25/26 with `MetaMath=MISSING`, every other entry matching the
manifest byte for byte. Integration gate, answered out loud: **this IS the Integration session, and
both items are contract/shared-canon work — strictly one chat at a time.** `STATE.md` and the
changelog tail were re-read immediately before landing; no sibling had landed.

### ITEM 1 — the reward curve reached the Lobby

`RewardScalingConfig` was **COPIED, never re-authored**: 6870 bytes, re-hashed in the Lobby to
**`1d789978`**, identical to the Game's deployed copy and to `shared/src`. Its deployPath needed a
`RS.Configs.Global` **folder that did not exist in that Place** — created, then the module written.
`deployed.Lobby` flipped in the manifest. **Lobby drift is now 26/26 GREEN with no gaps at all**;
the GAME is the one still at 25/26, `MetaMath` being Lobby-only until Phase D.

**Both Places proven to compute the SAME band from the SAME function** — wire 100 → `100-300`,
550 → `200-400`, 1000 → `300-500`, on the `Standard` curve `Stage1_Act1.Rewards.GoldCurve` actually
names. 500 server rolls at wire 550 all landed inside the previewed band. The `(wire-100)/99` UI
mistake was re-asserted against in the LOBBY too: it resolves 550 to a clamped `1.0` and would pay
top-band gold for a mid match.

### ITEM 1's second half — the preview is NOT wired, and that is a reported gate

The brief allowed ONE call to `StoryModeController`'s existing `renderRewards(list)` and said to
propose if it needed more. **It needs more, for two independent reasons**, so a proposal was written
instead of a half-edit to AD-UI's canon:

1. **`renderRewards` cannot express a BAND.** It sets the quantity badge from `tonumber(r.Qty)` as
   `"x" .. qty`. §8's preview is a RANGE. `Qty = goldMin` understates the payout, `goldMax`
   overstates it, and two Gold cells read as two separate rewards. Rendering a range means editing
   `renderRewards` itself.
2. **The call site is on the wrong edge.** `renderRewards` is called once, from `fillSelectedAct` —
   **on act selection only** — while `DifficultyController.publish()` rewrites `DifficultyWire` and
   `DifficultyMode` on **every slider move**. Wired only at act-select, the panel would show the
   act's opening difficulty and then sit there contradicting the slider the player is dragging.
   **That is worse than the current blank panel**, and is precisely the lie §8 exists to prevent.

`renderRewards` is a `local function`, so nothing outside the file can drive it, and routing the
shipping path through the `DevFakeRewards` harness attribute would make a test fixture load-bearing
— the same mistake B19's `OpenStageSelect` proposal declined to make. Plan:
**`docs/proposals/2026-08-14-reward-preview-wiring.md`**.

### ITEM 2 — teleport contract v3: the difficulty MODE is on the wire

Insane was fully coded at P5 and **completely unreachable**: `RewardCalculator` read
`matchState.DifficultyMode` and defaulted to Normal, but no mode field existed on the payload.

**Treated as a HARD contract bump, not a quiet additive change**, which was the whole point. The two
Places publish separately; an additive field creates a window where the Lobby sends `Insane` and an
older Game silently ignores it — the player is charged the harder match and paid the easier rewards,
with nothing erroring and no log line to find it by. The integer version makes that window
impossible: **v2 is now REJECTED with `[CONTRACT]`**.

The chain, and the one thing worth not re-deriving: **the mode joins the payload in `PartyService`,
not in the UI.** P4 publishes `DifficultyMode` on `SelectedAct` → P6's `LobbyController` passes it
through `RequestLaunch` **verbatim, doing no arithmetic on it** (one field added to an existing
call) → `PartyService` validates and BUILDS the payload → `MatchEntryService` normalises it onto
`rawConfig` → `MatchDirector` puts it on `matchState` → `RewardCalculator` branches on it.

- `LobbyConfig.MatchLaunchVersion` 2 → **3**, `GameConfig.TeleportPayloadVersion` 2 → **3**.
- **Mode is normalised at BOTH ends**, deliberately mirroring how `DifficultyPercent` is already
  sanitized twice. Anything that is not exactly `"Insane"` becomes `"Normal"` — the branch that pays
  NO bonus items, so an unknown value can never mint rewards. The Game warns `[CONTRACT]` when it
  falls back, rather than rejecting the match: dropping a party's whole match over a mode typo would
  be the worse failure, and the version integer is what guarantees the field is there at all.
- **`DifficultyPercent`'s meaning, range and name were NOT touched** (ADR-0011). Mode is a SEPARATE
  axis: it does not scale enemy health and never enters the wire→t conversion — asserted live, with
  `EnemyHealthScale` shown to still equal `BaseHealthScale × wire/100`.
- **`MatchReturnService` moved to v3 with no edit**, because it reads its expected version from
  `LobbyConfig.MatchLaunchVersion`. One integer really does cover both directions.

### Acceptance — 37 asserts, 0 failures, from REAL Scripts in BOTH Places. Never `execute_luau` for behaviour.

| § | Item | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Lobby hashes `RewardScalingConfig` at `1d789978` | **PASS** | 6870 bytes, `MATCH=true`; drift **26/26 GREEN** |
| 1 | Lobby + Game agree on the band at 3 wires | **PASS** | both: 100→`100-300`, 550→`200-400`, 1000→`300-500`, curve `Standard` |
| 1 | the band is what the server ROLLS | **PASS** | 500 rolls at wire 550, **0** outside `200-400` |
| 1 | the `/99` UI mistake cannot creep in | **PASS** | `t(550)=0.5000`; `/99` gives a clamped `1.0` = max gold |
| 1 | wire clamps, never extrapolates | **PASS** | wire 1 → t 0, wire 5000 → t 1 |
| 2 | **a v2 payload is REJECTED** | **PASS** | `[CONTRACT] PayloadVersion mismatch: got 2, expected 3`; a v2 payload *carrying* a mode is rejected too — the version gate comes first |
| 2 | v3 + `Insane` accepted, mode survives | **PASS** | `rawConfig.DifficultyMode=Insane`, `DifficultyPercent=545` untouched |
| 2 | unknown / missing mode FAILS SAFE | **PASS** | `"SuperInsane"` → Normal, `nil` → Normal, both with a `[CONTRACT]` warn |
| 2 | **mode reaches `matchState`** | **PASS** | real path `BuildRawConfig` → `StartMatch`: `matchState.DifficultyMode=Insane`, wire 545 |
| 2 | mode is not in the health scale | **PASS** | `EnemyHealthScale=5.4500` = `BaseHealthScale 1.00 × 545/100` |
| 2 | **Insane changes the reward branch** | **PASS** | Insane Victory committed `BannerTicket` 0→1 + `TraitRerollToken` 0→1; Normal Victory committed **neither** |
| 2 | Insane does NOT change gold | **PASS** | gold delta Normal **+308**, Insane **+324**, both inside the wire-545 band |
| 2 | **the LOBBY builds a v3 Insane payload** | **PASS** | `[CONTRACT] MatchLaunch v3 built: stage=Stage1_Act1 difficulty=545 mode=Insane players=1` |
| 2 | the wire value is P4's, not re-derived | **PASS** | server probe on `RequestLaunch`: `DifficultyPercent=545 (number) DifficultyMode=Insane (string)` for UI 50% |

**Reserved-server teleports cannot be tested from Studio** (`ReserveServer` = **HTTP 403**), so every
launch-side assertion is on the payload the server RECEIVES and BUILDS, never on a completed
teleport — and that 403 doubles as the error-path proof: the failure came back through `PartyState`
and `LoadingScreen` lifted on its own. The probe was **armed before the click** and asserts on the
observed request, not on a poll afterwards (B19's lost run).

Reward-branch asserts are on item and gold **DELTAS**, not absolutes, so a dirty dev profile cannot
make a red test look green — the P5/B18 precedent. `MatchLifecycleSmokeTest` was temporarily
`Disabled` so the match start was deterministic, and **restored at cleanup**; both harnesses
(`SSS.B20ContractVerify`, `SSS.B20LaunchVerify` + `StarterPlayerScripts.B20LaunchDriver`) are
DELETED, and every `Dev*` attribute on the authored `PlayGUI` verified OFF/0/"".

**One harness lesson, recorded because it will recur:** a runtime Script **cannot read `.Source`** —
it errors with `lacking capability PluginOrOpenCloud` and kills the script at that line. Hash/source
proofs belong in tooling (`execute_luau` in the Edit datamodel, which CLAUDE.md already sanctions as
safe for `.Source`); the real Script proves BEHAVIOUR. The first Lobby run died on exactly this.

- **Contract impact:** **TELEPORT v2 → v3, deployed BOTH Places in this ONE session.**
  `docs/contracts/teleport.md` bumped, old→new + "migration: none, hard cutover" documented, version
  history entry added. No schema bump. **`shared/src/RewardScalingConfig.luau` was NOT modified** —
  byte-identity at `1d789978` was the acceptance criterion.
- **⚠ ONE STALE COMMENT, deliberately not edited:** `RewardScalingConfig`'s own header still says the
  payload "(v2) carries NO mode field" and that Insane cannot fire live. It is shared canon; fixing
  the comment changes the hash and needs a re-deploy to both Places. Filed as a small **AD-Game**
  PENDING — the CODE is correct, only the comment is out of date.
- **Docs:** both `places/*/CONTEXT.md` (each compressed back UNDER its 150 cap — the Game's was
  already 151 on arrival), `docs/systems/rewards.md`, `docs/contracts/teleport.md`,
  `shared/manifest.json` (`deployed.Lobby` → `1d789978`), ROADMAP rows flipped, the new proposal
  registered in `docs/INDEX.md`.
- **`STATE.md` is UNDER CAP for the first time in three sessions: 130 → 114 of 120.** Both PENDINGs
  this session resolved were DELETED outright (ADR-0006 — the changelog is their record, and
  strikethrough entries are banned). No other chat's PENDING was removed; the blank separators
  inside the PENDING list were collapsed, which is formatting, not content.
- **Open threads:** the reward PREVIEW needs a rendering decision (proposal, AD-UI); `OpenStageSelect`
  still has no listener (B19, AD-UI); `StartingLives` balance is still the user's call.
- **USER, now URGENT: republish BOTH Places TOGETHER.** v2 and v3 do not interoperate, so a partial
  publish breaks EVERY launch with `[CONTRACT] PayloadVersion mismatch`. **FIVE commits unpushed.**

## 2026-08-13 [lobby] B19 — PlayGUI **P6**: the party roster, Invite and the LAUNCH. `StageSelectScreen` retired. **PlayGUI P1–P6 complete.**

**The active Studio instance WAS the Game** — B18 was a Game session and left it selected, exactly as
the prompt predicted. Caught by `list_roblox_studios`, re-set explicitly, and every `execute_luau`
opened with a two-way assertion (`Workspace.Lobby` PRESENT **and** `RS.Configs.Towers` ABSENT) that
ABORTS rather than writing to the wrong Place.

Bootstrap drift **Lobby 25/26 with `RewardScalingConfig=MISSING`** — the expected state (B18 deployed
it Game-only), `MetaMath` PRESENT, zero mismatches. Integration gate: **No Integration needed —
proceeding.** Re-run at landing: **still 25/26, byte-identical.** No shared module, kit template,
`ProfileTemplate` or contract was touched, so that answer held.

### The gate came first, and it was NOT satisfied

§2 B-4 owed a **player-row template** in `LobbyFrame.SelectedAct.PlayersFrame.PlayersFrame`. There was
none. What was there: **four ImageButtons all named `ItemIcon`**, identical copies of the Kit
item-card design (`Main.BG`/`IconImage`/`QtyBadge`), same `Position`, `Visible = true`, no `*Template`
anywhere. Not player rows — no name label, no host marker, and a *quantity badge*, which is
meaningless on a party member. **Work stopped and the gate was reported before any write**, the B17
precedent. A second gap was reported with it: `InviteButton` needs a target userId and PlayGUI has no
authored invite list.

**The user chose "repurpose one" and "InviteButton opens the existing PartyScreen".** Both authored
under that delegation and both flagged as such below.

### What P6 does

- **Roster.** `LobbyController` (the fourth script under PlayGUI) clones `PlayerRowTemplate` once per
  party member from `GetLobbyState` / `PartyState`. Avatars use the **`rbxthumb://` content scheme,
  not `GetUserThumbnailAsync`, which YIELDS** — rows are built inside a remote handler and a yield
  there stalls the render for every member after the first (the A9 lesson, applied before it bit).
- **Launch.** `StartButton` → `LoadingScreen.Show` → the **EXISTING** `Remotes.RequestLaunch`;
  `PartyService` does the reserved-server teleport exactly as it already did. **No second launch
  path** (§11).
- **The difficulty is P4's number, untouched.** `DifficultyWire` is read and put on the wire verbatim.
  **If the attribute is ever absent the launch is REFUSED rather than re-derived** — ADR-0011 exists
  because a wrong difficulty is a silent 10×-enemy-health match that nothing errors on. There is no
  arithmetic on a difficulty value anywhere in the file; `DifficultyScale` is required only for
  `.Format`, which renders text.
- **The lobby panel now mirrors the story panel** (`StageNameLabel`, `ActNameLabel`,
  `SelectedDifficultyLable`) off the published attributes. This frame is the last thing a player reads
  before committing, and a confirmation screen that names a different act from the one it launches is
  a lie. `RewardsFrame` here stays untouched — the preview needs `RewardScalingConfig`, which is not
  in this Place yet, and §8 bans inventing numbers.
- **Invite.** `InviteButton` opens `PartyScreen` through a new **`OpenRequest` attribute seam** that
  runs the same `refresh()` the PARTY toggle runs — without it the invite list would show whatever it
  held when the panel was last opened. `PartyScreen.DisplayOrder` **0 → 30** so it renders above
  PlayGUI (20) and below LoadingScreen (200). PartyScreen stays script-built legacy; converting it is
  its own session.

**TWO NAME COLLISIONS made every lookup non-recursive, and that is load-bearing.** `SelectedAct`
exists under **both** StoryModeFrame and LobbyFrame — the attributes are on the Story one, the roster
on the Lobby one. And `PlayersFrame` contains a ScrollingFrame **also named `PlayersFrame`**, so
`FindFirstChild(name, true)` returns the outer panel. Same class of bug as the triple `StageNameLabel`
(B-3) and the triple `SelectedDifficultyLable` (B17).

### The template (authored under delegation)

One `ItemIcon` → **`PlayerRowTemplate`** (`Visible = false`); `Main.QtyBadge` → **`HostBadge`** with
its label → `HostBadgeLabel` = "HOST" (the authored badge design reused rather than rebuilt);
`IconImage` = the avatar; **`NameLabel` added** — the one genuinely new instance, because no player row
works without a name. Authored **plain and functional**, and the controller sets only Text/Image/
Visible/LayoutOrder — never `Size` or `Position` — so **restyling it in Studio needs no code change.**

**The other three copies were HIDDEN (`Visible = false`), NOT deleted.** They are the user's
instances and B-3's precedent is explicit that look-alike siblings are not automatically junk. Left
visible they would paint as permanent ghost cards beside the real members; hiding is reversible,
deleting is not.

### `StageSelectScreen` retired (§2 B-5)

Deleted — 100% script-built, 1 descendant. **Callers were re-grepped FIRST** (the A7 `GetCollection`
precedent): no script referenced it by path, and **`GetStages` SURVIVES** because `ReturnScreen` still
invokes it and `LobbyServices` still serves it, so `RS.Remotes` stays at **15** entries.

**⚠ ONE CONSEQUENCE, found by that grep and deliberately NOT patched here:**
`StageSelectScreen.Controller` was the **only listener** on `ClientEvents.OpenStageSelect`, which
`ReturnScreen`'s CONTINUE fires after a victory. **That button is now inert.** Fixing it needs a
shipping-path "open PlayGUI on act X" seam in `PlayGUIController` + `StoryModeController` — **AD-UI's
canon**, both private locals, and routing it through the `DevGoto`/`DevSelectAct` harness attributes
would make a test fixture load-bearing. So P6 wrote
**`docs/proposals/2026-08-13-openstageselect-after-stageselectscreen.md`** + a PENDING instead of
editing another chat's files. Surfaced here rather than buried because it is a real, user-visible
regression.

### Acceptance — 30/30 from a REAL LocalScript + a temporary server probe. Never `execute_luau` for behaviour.

| § | Item | Verdict | Evidence |
| --- | --- | --- | --- |
| A | template is a real instance, parked, hidden | **PASS** | ImageButton under `LobbyController`, `Visible=false`, absent from the layout; NameLabel/HostBadge/IconImage all present |
| B | **solo renders EXACTLY ONE row** | **PASS** | `rows=1`, named `SuperiorBeing_S`, `IsHost=true`, HostBadge visible, avatar `rbxthumb://...id=1746652074` |
| C | **one row PER member** | **PASS** | 3 synthetic members → `rows=3`; host badge ON for row 1, OFF for 2 and 3; each row its own name |
| D | re-render CLEARS stale rows | **PASS** | 3 → back to `rows=1`, no accumulation |
| E | panel mirrors the act + difficulty | **PASS** | UI 50 → wire **545**; panel reads "Normal  50%" and "Act 1 : Protecting the Fields" |
| F | **StartButton reaches PartyService with P4's number** | **PASS** | server probe: `StageId=Stage1_Act1 DifficultyPercent=545 (type number)` — identical to the published attribute, not re-derived |
| F | veil shows, then LIFTS on a server error | **PASS** | observed `Enabled` → true → false; `IsShown()` false at the end |
| G | `StageSelectScreen` gone, everything else loads | **PASS** | absent; **all 15 remaining screens present**, no `Infinite yield` warning anywhere in the run |
| H | InviteButton opens PartyScreen | **PASS** | `Enabled=true`, panel open, `DisplayOrder 30 > 20` |

**Run 1 read 29/30 and the one FAIL was the HARNESS, not the product.** `F1` polled
`LoadingScreen.IsShown()` 0.6s after the click; Studio's `ReserveServer` fails almost instantly
(**HTTP 403** — reserved servers are not available from Studio), so Show *and* Hide had both already
happened inside the sample window. Polling a deliberately transient state is the test's bug. Rewritten
to **observe the `Enabled` transitions** with a connection armed before the click; run 2 = **30/30**.
Recorded because "assert it later" is a trap this harness will hit again. The 403 is also what proves
the error path: a real failure came back through `PartyState` and the veil lifted on its own.

Both harnesses (`SSS.P6LaunchProbe`, `StarterPlayerScripts.P6Verify`) are **DELETED**; every `Dev*`
attribute in StarterGui verified OFF/0/"".

- **Contract impact:** NONE. No schema bump, no teleport change, no shared module or template touched
  — drift re-verified byte-identical at landing.
- **Docs:** `places/lobby/CONTEXT.md` + `docs/systems/play-menu.md` updated (both compressed back
  under cap), P6/B-4/B-5 ticked in `docs/blueprints/playgui.md`, ROADMAP flipped.
- **Open threads:** `OpenStageSelect` has no listener (PENDING + proposal); the reward preview still
  waits on `RewardScalingConfig`; Insane still unreachable without teleport v3.

## 2026-08-13 [game] B18 — PlayGUI **P5**: match rewards scale with difficulty. One new SHARED config, and the scale trap defused.

First GAME-place session since B0; the last four were Lobby. **The active Studio instance WAS the
Lobby** — caught by `list_roblox_studios` and re-set explicitly, exactly as the prompt warned. Every
`execute_luau` opened with a two-way assertion (`RS.Configs.Towers` PRESENT **and** `Workspace.Lobby`
ABSENT), so a mid-session flip would abort rather than write to the wrong Place.

Bootstrap drift **Game 24/25 with `MetaMath=MISSING`, zero mismatches** — the expected state, not
drift. Integration gate: **No Integration needed — proceeding**, with the caveat called out up front
that a shared config would create an Integration FOLLOW-UP (it did; see PENDINGs).

**What P5 does.** Victory gold is now rolled from a difficulty-scaled band —
`min = lerp(100,300,t)`, `max = lerp(300,500,t)` — instead of a flat per-act number.
`Victory.Currency` survives in every act as **FALLBACK ONLY**.

**A DEFEAT deliberately keeps its flat consolation.** §8's curve describes what a CLEAR pays;
scaling the loss reward would make losing on max difficulty the best gold-per-minute in the game.

**THE SCALE TRAP, which was the whole risk of P5.** §8 defines the curve on the **UI 1–100** scale,
but the payload field that reaches this Place is **wire 100–1000** (ADR-0011). So the Game does its
own conversion, `t = (wire - 100) / 900`, in ONE named function (`RewardScalingConfig.TFromWire`)
with a header naming both scales. It **clamps and never extrapolates** — the legal wire range is
actually 1–1000 (`DifficultyConfig.MinPercent = 1`), wider than the 100–1000 the slider can produce,
so sub-100 values must land on t = 0 rather than going negative. The Lobby's `DifficultyScale` was
**not** imported: it is Lobby-local by decision, and a client UI module has no business being
required by a server reward path. There is now one conversion per Place and neither can drift into
the other. An explicit test asserts that a UI `100` ("hardest") mistaken for a wire value still
resolves to the **NORMAL** band — the failure mode that would otherwise pay max gold, silently.

**THE DESIGN CALL — the curve is SHARED CANON, not per-`StageConfig`. Reasoning, since the prompt
asked for it in writing:**

1. §8 is explicit: *"the curve belongs in a config both sides can read."*
2. `docs/systems/play-menu.md` records that the Lobby's `StageRegistry` is a hand-maintained MIRROR
   carrying **structure only — no reward table**, deliberately. Putting gold in `StageConfig` would
   force reward numbers into that mirror: two copies of the same figures in two Places with **no
   drift check on them**. That is precisely what the manifest exists to prevent.
3. The curve is **identical for all three acts**. Triplicating it buys no tuning and creates three
   places to desync.
4. `WorthinessConfig` is the obvious counter-example and it does **not** apply: the Lobby reads
   worthiness as a **stored result** off the profile. A pre-match preview has nothing stored to read.

Per-act tuning is preserved without duplicating numbers — `StageConfig.Rewards.GoldCurve` **names**
a curve, so a future act points at a different one.

**Shared-module procedure followed in full, not halfway:** new
`RS.Configs.Global.RewardScalingConfig` deployed to the Game; `shared/src/RewardScalingConfig.luau`
written and **verified byte-identical** (6870 bytes, `1d789978`, hashed independently on both sides);
manifest **25 → 26** with `deployed.Lobby = null`; added to `tools/hash_shared.luau`; PENDING raised.
Drift re-read at landing: **Game 25/26, no mismatches.**

**INSANE: implemented, and FLAGGED LOUDLY rather than sneaked in.** §8 gives Insane the same gold
curve plus item rewards. **The `MatchLaunch` payload (v2) has no mode field**, so this Place always
sees Normal and the branch cannot fire in production. `RewardCalculator` reads
`matchState.DifficultyMode` and defaults to Normal — failing SAFE, because the opposite default
would pay bonus items to every caller that forgot the argument. Making it reachable is a teleport
contract **v2 → v3**: both Places, ONE session, synchronised republish. **`DifficultyPercent`'s
meaning, range and name were not touched**, and a test asserts `DifficultyConfig` is still 1/100/1000
and still means enemy health.

**Acceptance — 24/24 live asserts from a REAL Script (`SSS.Server.P5Rewards`, since DELETED), plus a
real end-to-end match. Never `execute_luau` for behaviour.**

| § | Item | Verdict | Evidence |
| --- | --- | --- | --- |
| (a) | Victory at wire 100 pays the NORMAL band | **PASS** | band `100-300`, Gold **+300** committed |
| (a) | Victory at wire 1000 pays the TOP band | **PASS** | band `300-500`, Gold **+403** committed |
| (b) | wire→t at both ends + a midpoint | **PASS** | 100→`0.0000`, 550→`0.5000` (band 200-400), 1000→`1.0000`; wire 1 and 5000 clamp |
| (b) | cannot be confused with the UI scale | **PASS** | UI `100` fed in as wire → band `100-300` (NORMAL), not 300-500 |
| (c) | Insane adds items, Normal does not | **PASS** | Insane 3 drops incl. both guaranteed; `BannerTicket` **2 → 4** actually committed to `Data.Items`; same gold band both modes |
| (d) | `DifficultyPercent` unchanged, contract validates | **PASS** | `1 / 100 / 1000`; 100→1×, 1000→10×; `Schema.ValidateMatchConfig` Ok |
| (e) | a match still completes end to end | **PASS** | smoke test ran Stage1_Act1, Defeat at wave 2/15, `[DATA] Rewards: outcome=Defeat mode=Normal wire=100 t=0.000 band=100-300 -> gold 15` |
| — | no `matchState` fails SAFE | **PASS** | band `100-300`, Gold +109 — not the top band |
| — | a DEFEAT is not scaled | **PASS** | Gold +15 = the flat consolation, 0 drops even at wire 1000 Insane |

Asserts are on the **gold DELTA**, not the absolute, so a dirty dev profile cannot make a red test
look green. Direct `GrantForPlayer` calls were used for the matrix rather than six 15-wave matches —
they run the REAL commit path (`AddCurrency`/`AddItem`) in the real server VM, and a full match still
covered (e).

**Also fixed, flagged at B14 and left unresolved since:** `Stage1_Act2` said `StartingLives = 15
-- less margin than Act 1`, but Act 1 starts on **3**. The **COMMENT** was corrected, not the number:
changing starting lives is a balance decision, not a doc fix. **Raised for the user** — 3 / 15 / 10
across Acts 1–3 against `BaseHealthScale` 1.0 / 1.6 / 2.4 is not a progression, and Act 1's `3` looks
like a leftover test value.

- **NEW: `docs/systems/rewards.md`** (registered in `docs/INDEX.md`) — nothing owned rewards before.
- **Contract impact:** NONE. No schema bump, no teleport change. `StageConfig` gained an additive
  optional `GoldCurve`; `GrantForPlayer` gained an optional trailing arg.
- **PENDINGs:** **3 NEW** — (1) AD-Integration must copy `RewardScalingConfig` to the Lobby before
  the preview can show true numbers; (2) teleport v2→v3 for Insane; (3) USER balance call on
  `StartingLives`. Invariant 1 still holds in the Lobby only — untouched, not made worse.
- **`STATE.md` is over its 120-line cap (see the advisory)** — it entered this session AT 120, and
  the three new PENDINGs will not fit. Trimming needs an owner to say which resolved PENDINGs may go;
  deleting another chat's entry on a guess is exactly what the single-writer rule forbids.
- **USER must republish the GAME place** — all of P5 is Studio canon, not git.

## 2026-08-13 [lobby] B17 — PlayGUI **P4**: difficulty slider + Normal/Insane, with the ADR-0011 remap isolated in ONE module. Two real bugs caught by the first run.

Bootstrap drift **Lobby 25/25 GREEN**, re-checked byte-identical at landing. Integration gate:
**No Integration needed — proceeding** (no shared module, template or contract touched; nothing
added to the kit). Place binding: the active instance WAS the Lobby, checked and re-set explicitly
rather than trusted, and every `execute_luau` opened with the aborting Lobby assertion.

**THE GATE BLOCKED FIRST, THEN THE USER DELEGATED IT.** `SelectedAct.DifficultyGradient` still held
only a `UIGradient` — no `Fill`, no `Handle` — so the session stopped and reported before any work,
as B-4 requires. The user then asked for the parts to be authored here. Two things worth recording:
- **`DifficultyGradient` does not read like a groove.** It is a full-width frame **78% of the panel
  tall** at **`ZIndex 0`** carrying a vertical black→lime gradient — a backdrop, not a track. The
  blueprint calls it "the slider track" and that is still workable, but anyone expecting a thin bar
  will be surprised.
- **Its vertical centre lands inside `DifficultyButtons`.** Local Y 0.5 = SelectedAct Y 0.609, and
  the buttons occupy 0.570–0.745. The parts were therefore placed at local Y **0.2316** — SelectedAct
  Y 0.400, the clear gap between `SelectedDifficultyLable` (ends 0.229) and the buttons (start
  0.570) — and given `ZIndex 2/3` so they draw above the ZIndex-0 track. Authored PLAIN and
  functional per the house rule; **the controller reads their AUTHORED geometry, so restyling or
  repositioning them in Studio needs no code change.**

**`DifficultyScale` — a ModuleScript, and that is the point.** ADR-0011 requires the UI↔wire remap
to live in exactly ONE function. Making it a module rather than a local makes that **greppable** and
makes P6's launch path physically unable to re-derive it. Formula verbatim from the ADR,
`wire = 100 + (ui - 1) * 900 / 99`: **UI 1% → 100 (normal)**, **UI 100% → 1000**. `ToUI` is the
inverse; both **clamp instead of extrapolating**. Verified by grep that the formula appears in
exactly one file and every other reference calls `ToWire`/`ToUI`.
- **Mode is a separate axis and never enters the conversion.** Asserted live: wire at slider 1% is
  100 under BOTH Normal and Insane. Insane changes REWARDS (§8) — **P5's row** — not difficulty.
- **`StageRegistry.DifficultyMin/Default/Max` are asserted STILL 1/100/1000.** ADR-0011 exists
  because redefining the wire field instead is a SILENT, live-breaking change: the Places publish
  separately, so a republished Lobby sending `DifficultyPercent = 100` meaning "hardest" to a Game
  still reading 100 as "normal" runs every match at 10× enemy health with nothing erroring.
- Publishes on `SelectedAct`: `DifficultyUI` (1–100), `DifficultyWire` (produced by the one
  conversion) and `DifficultyMode`. **P6 reads `DifficultyWire` and must not convert again.**

**`DifficultyController`.** Click anywhere on the track or drag the `Handle`; the controller drives
exactly one number on each part (`Fill.Size.X.Scale`, `Handle.Position.X.Scale`) and always lands on
the exact value for the chosen percent. `NormalButton`/`InsaneButton` drive their existing
`InactiveOverlay` — exactly one active, and the authored default (Normal active) was already right.

**THE `SelectedDifficultyLable` NAME COLLISION IS LOAD-BEARING.** There are **three** instances with
that name in the subtree: the panel's own (a direct child of `SelectedAct`) plus one inside EACH
mode button. P3's text helper uses a RECURSIVE `FindFirstChild`, which returns an arbitrary match —
so a naive fill would have silently rewritten a button's caption instead of the panel label, the
same class of bug as the triple `StageNameLabel` (B-3). Every lookup in this controller is
deliberately non-recursive, and the test asserts both button captions still read "Normal"/"Insane"
after the panel label is written.

**TWO REAL BUGS, CAUGHT BY THE FIRST RUN (23 pass / 3 fail) AND FIXED.** Both were genuine defects,
not test artefacts:
- **A stale `dragging` flag hijacked the slider.** `DevSetDifficulty(25)` was overwritten to **2%**
  by a phantom "drag" on the very next mouse move. Cause: `dragging` is set by a press on the track
  and cleared by `InputEnded`, but if the player releases outside the window that event never
  arrives and bare cursor motion keeps driving the value forever. The mouse branch now re-checks
  `UserInputService:IsMouseButtonPressed` and **self-heals the flag**. Regression test added: a set
  value must still be set 1.5 s later.
- **Re-selecting the SAME act did not re-sync the difficulty.** `SetAttribute` with an UNCHANGED
  value fires no `GetAttributeChangedSignal`, so edge-triggering on `SelectedActId` silently missed
  the case (re-picking Act 1 left the slider at 42%). `StoryModeController` now bumps a monotonic
  **`SelectionSerial`** LAST in `fillSelectedAct` and P4 listens to that. `SelectedActId` remains
  the single source of truth for WHICH act — this is the same channel made reliable, not a second
  one. **Anything else that must react to a selection should use `SelectionSerial`.**

**Verified live (Play, Lobby) from a REAL LocalScript + `get_console_output`** — never
`execute_luau`. The temporary `StarterPlayerScripts.P4AcceptanceHarness` drove the same functions a
real drag/click runs and was **DELETED at landing** (all three P2/P3/P4 harnesses confirmed absent).
**`[Test] P4 RESULT: PASS (27 pass, 0 fail)`** on the re-run:
- (a) exactly one mode active, the other overlaid, both directions; mode published.
- (b) UI 1/25/50/100 each landed `Fill.Size.X.Scale` and `Handle.Position.X.Scale` on `(ui-1)/99`
  with the authored Y preserved, and the published wire matched `ToWire(ui)` every time.
- (c) panel label read `"Insane  42%"` while both button captions stayed untouched.
- (d) `ToWire(1)=100`, `ToWire(100)=1000`, `ToUI(100)=1`, `ToUI(1000)=100`, out-of-range clamped,
  wire scale unmoved, and 1% = normal under both modes.
- (e) each act re-synced the slider to its `Recommended` (wire 100/150/200 → UI 1/7/12; integer
  quantisation is expected), **including re-selecting the already-selected act**; P3's act rows
  still render and P2's transition + Leave still work.
- Every `Dev*` attribute across all nine harness hosts swept OFF; the authored resting state
  (`Fill`/`Handle` present, panel label "Normal", Normal active) confirmed after the Play round trip.

- **Contract impact: NONE.** No shared module, template, schema or teleport change. Drift **25/25**
  before and after; the Game's 24/25 `MetaMath=MISSING` untouched and still expected.
- **PENDINGs:** the USER-authoring PENDING is narrowed again — only the **P6 player-row template**
  is left.
- **Note for P4's own scope:** §9 lists a "live reward preview reading P5's config" under P4. P5
  does not exist, so the preview stays empty; §9 explicitly permits shipping P4 without it. Wiring
  it later is one call to P3's existing `renderRewards(list)`.
**FOLLOW-UP, same session (user request):** **the mode now TINTS the track.** That is what
`DifficultyGradient`'s own `UIGradient` was always for — green while Normal is selected, red while
Insane is. The colour is **copied from the mode button's own `UIGradient` at runtime** rather than
hardcoded, so restyling a button in Studio restyles the track with it and the two can never
disagree. Only `.Color` is copied: the track keeps its authored `Transparency` ramp (1 at the top →
0 at the bottom) and its `Rotation = 90`. The lookup is `FindFirstChildOfClass` — **direct children
only**, because both buttons also carry `UIStroke`s that could hold their own gradient. A fallback
restores the authored colour if a button ever loses its gradient, so the track can never strand on
the previous mode's paint. **The tint is runtime-only; the authored colour in the Edit datamodel is
untouched (still black → lime), and that is the one to edit.** Verified live, **7 pass / 0 fail**:
green and red each matched their button's sequence exactly, switching back restored green, the two
tints differ, the transparency ramp and rotation survived, and P4's mode/overlay/slider behaviour
was re-asserted unchanged (`UI 50 → wire 545`). Harness deleted, all `Dev*` swept OFF.

- **PUSH STATUS CHANGED MID-SESSION — the long "N unpushed" streak is over.** The USER pushed while
  B17 was landing: `refs/remotes/origin/main` moved `ae65343 → d614b6c` ("update by push",
  2026-08-13), so the seven commits B13–B17 that every entry since B12 called "unpushed" are now
  **on origin**. Only the follow-up commit above is local. Verified from
  `.git/logs/refs/remotes/origin/main`, not assumed — the count first showed up as a suspicious
  `1` and was chased down rather than written off.
- Housekeeping: `.git/_stale_locks_*` dirs going back to A8 cannot be unlinked on this mount. They
  are harmless (git ignores unknown dirs under `.git`); the tree verifies clean.

## 2026-08-13 [lobby] B16 — PlayGUI **P3**: StoryModeFrame is populated. Stage/act lists, SelectedAct fill, and the two authoring blockers cleared.

Bootstrap drift **Lobby 25/25 GREEN**, re-checked byte-identical at landing. Integration gate:
**No Integration needed — proceeding** (no shared module, template or contract touched; nothing was
added to the kit). Place binding: the active instance WAS the Lobby, checked and re-set explicitly
rather than trusted, and every `execute_luau` opened with the aborting Lobby assertion. Blueprint
`playgui.md` session-task **P3**, section 7.

**FIRST — the two blockers were real, and one of them was worse than the blueprint thought.**
The session stopped at the gate before any work, as instructed. Both were still open:
- **B-3: `SelectedAct` had THREE children named `StageNameLabel` — but they were NOT duplicates.**
  The audit read their text: `"Stage Name"`, `"Total Clears : 0"`, `"Clear Time : 00:00:00"`. They
  are three DIFFERENT labels the user copy-pasted without renaming. **The blueprint's standing
  advice ("delete or rename the two extras") would, taken literally as "delete", have destroyed two
  labels the screen clearly wants.** Reported to the user with that finding; the user authorised
  the renames. Renamed BY TEXT (asserting exactly one match each first, so the wrong label could
  not be hit): → **`TotalClearsLabel`**, → **`ClearTimeLabel`**. The genuine one kept its name.
- **B-4: `RewardsScrollingFrame.ItemIcon`** → **`ItemIconTemplate`**, `Visible = false`. Note it is
  an **ImageButton**, not an ImageLabel — a first attempt at the rename script died reading `.Text`
  off it, which is also why the label renames landed before the icon one did.
Blueprint §2 now records B-3 as RESOLVED with the "they were not duplicates" reason, so the wrong
advice cannot be followed later. B-4's other two items (slider Fill/Handle, player-row template)
remain OPEN and are re-tagged to the sessions that actually need them: **P4** and **P6**.

**THE WORK — `StarterGui.PlayGUI.StoryModeController`** (a SECOND LocalScript under PlayGUI; P2's
`PlayGUIController` still owns visibility/position/transitions and this one never writes them).
- **Stages are GROUPED from the flat act list** by `StageNumber`. All three acts are Stage 1, so
  there is exactly ONE stage row today — "The Farm". Clicking a stage rebuilds the Acts list;
  clicking an act fills `SelectedAct`; boot selects stage 1 / act 1.
- **All three templates are reparented to the controller at runtime** (the SummonController
  pattern) so they can never render as a stray row, while staying exactly where the user authored
  them and editable in Studio. `Spacer` (`LayoutOrder = 99`) and both `UIListLayout`s untouched.
- **`ActName` gets `ActName`, never `DisplayName`** — the P1 trap. Asserted explicitly per act.

**THREE NARROWINGS OF §7's FILL LIST, ALL RECORDED IN THE BLUEPRINT.** §7 says to fill the panel;
three of its fields had nothing honest to fill from:
- **Labels with no data source are HIDDEN, not zeroed.** `StageRegistry` carries STRUCTURE ONLY and
  `GetStages` returns just that — there is no clear tracking anywhere in this Place (a grep for it
  finds nothing in the schema or the server) and no reward table. So `LevelsClearedLabel`,
  `ProgressPercentLabel`, `TotalClearsLabel` and `ClearTimeLabel` are hidden. **A zero is a claim;
  a hidden label is not.** This is section 6's "fill what real data exists and hide the rest"
  applied to section 7, and matches the IndexScreen's honesty rule.
- **The reward panel is PLUMBING ONLY and renders ZERO cells.** `renderRewards(list)` clones
  `ItemIconTemplate` (icon via `UIKit.ItemIcon.ImageFor`, tier paint via `TierConfig`), but the
  shipping call passes an empty list. **Reward numbers are P5's, and §8 is explicit that the
  preview shows what the server will ACTUALLY pay** — a plausible gold figure invented here would
  be a lie to the player. The clone path is proven by a `DevFakeRewards` harness with a synthetic
  list that the shipping path never uses.
- **`SelectedDifficultyLable` was deliberately left alone.** Filling it needs the ADR-0011 1–100
  display remap, which is **P4's named deliverable**; writing a second remap here is precisely the
  duplicate-conversion bug ADR-0011 exists to prevent. It keeps its authored "Normal".
- `StageBGImage` keeps its authored image: no per-act art source exists in the mirror or any config.

**Selection is published as attributes on `SelectedAct`** — `SelectedActId`, `SelectedStageNumber`
and `RecommendedDifficultyWire` (**WIRE scale 1–1000**, ADR-0011; P4 converts, not this file). This
mirrors B9's "publish the selected uuid" pattern and is the ONLY coupling P4/P6 need — do not add a
second selection channel. Selected rows also carry a `Selected` attribute and tint their authored
`UIStrokeInner`, so the look can be restyled in Studio without touching the controller.

**Verified live (Play, Lobby) from a REAL LocalScript + `get_console_output`** — never
`execute_luau`, whose VM caches requires and served B7 a stale module. The temporary
`StarterPlayerScripts.P3AcceptanceHarness` drove the same functions a click runs and was **DELETED
at landing** (confirmed absent, as is B15's). **`[Test] P3 RESULT: PASS (29 pass, 0 fail)`**:
- (a) one Stages row, `Name=Stage_1`, `StageLabel="The Farm"`; `LevelsClearedLabel` and
  `ProgressPercentLabel` both `Visible=false`; `Spacer` kept at LayoutOrder 99; `UIListLayout` kept;
  `StageButtonTemplate` absent from the list.
- (b) three Act rows, each asserted against the **hardcoded P1 canon** (independent of the module):
  ActName "Protecting the Fields"/"The Scarecrow Awakens"/"Harvest of Ruin" AND `~=` the
  DisplayName it would have been ("The First Alamat"/"Rising Legend"/"Myth's End").
- (c) every act selected in turn filled `StageNameLabel="The Farm"` and
  `ActNumberActNameLabel="Act N : <ActName>"`, and published the right
  `SelectedActId`/`SelectedStageNumber`/`RecommendedDifficultyWire` (100/150/200, wire scale).
  Exactly ONE `StageNameLabel` remains; `SelectedDifficultyLable` still reads the authored "Normal".
- (d) shipping path renders **0** reward cells; `ItemIconTemplate` is out of the list and still
  `Visible=false`; `DevFakeRewards` produced 2 real clones (`Reward_Gold`, `Reward_Silver`) with
  their `IconImage`; re-selecting an act cleared them back to 0.
- **P2 regression re-checked in the same run:** a transition still completes and `LeaveButton` still
  closes the menu. Boot clean; every `Dev*` attribute across all nine harness hosts swept OFF after
  the Play round trip, and the templates confirmed back in place in the Edit datamodel with no
  stray runtime clones left behind.

- **Contract impact: NONE.** No shared module, template, schema or teleport change. Drift **25/25**
  before and after; the Game's 24/25 `MetaMath=MISSING` untouched and still expected.
- **PENDINGs:** the USER-authoring PENDING is NARROWED — its two P3 items are cleared, and it now
  blocks **P4** (slider Fill/Handle) and **P6** (player-row template) only.
- **New standing note for whoever adds clear tracking:** the four hidden labels are the consumers.
  Unhide them in `StoryModeController`; do not invent a clear counter in the UI.
- Commit is **local — push pending**. **Six unpushed now** (origin/main is still at B12's `ae65343`).
- Housekeeping: `.git/_stale_locks_P2/` still cannot be unlinked on this mount (zero-byte leftovers,
  harmless — git ignores unknown dirs under `.git`). A `_stale_locks_P3/` joins it this session.

## 2026-08-13 [lobby] B15 — PlayGUI **P2**: the menu SHELL works. New LoadingScreen, Play entry, menu camera + parallax, CanvasGroup transitions, disabled mode buttons.

Bootstrap drift **Lobby 25/25 GREEN** (re-run at landing: still 25/25, byte-identical). Integration
gate: **No Integration needed — proceeding** (P2 touches no shared module, no template and no
contract; the LoadingScreen is deliberately Lobby-local per blueprint §4, so the "a kit addition
changes this answer" clause never fired). Blueprint `playgui.md` session-task **P2**, all four parts
plus the §6/§11 cheap items. Every `execute_luau` opened with the Lobby assertion (`Workspace.Lobby`
+ `SSS.Server.Lobby.LobbyServices` present, `RS.Configs.Towers` ABSENT) that aborts on mismatch;
**this time the active instance WAS already the Lobby** — the B13/B14 flip did not recur, but it was
checked before any read and re-set explicitly rather than trusted.

**PART A — `StarterGui.LoadingScreen` is new (§4).** Authored as REAL Instances in the Edit
datamodel, never `Instance.new` at runtime. `DisplayOrder = 200` (ObtainRewardsGUI's 100 was the
previous ceiling), `IgnoreGuiInset = true`, **`ResetOnSpawn = false`**. Tree: `Root` (a CanvasGroup,
so the whole veil fades on ONE property) → `Backdrop` (`Active = true`, sinks input) + `TitleLabel`
+ `TipLabel` + `ProgressTrack.Fill` (indeterminate sweep) + `Spinner`. The API is the child
ModuleScript `LoadingScreenController`: `Show(reason)` / `Hide()` / `IsShown()` / `SetTitle()`.
- **Both calls return IMMEDIATELY** and do their waiting on an internal thread, so a caller can use
  them from a button handler without yielding it.
- **A `generation` counter is the double-fire guard.** Any Show/Hide thread that finishes and finds
  the number has moved on drops its result. Without it an overlapping Hide can strand the veil
  half-faded — and because the backdrop sinks input, that would swallow every click permanently.
- **Kept Lobby-local on purpose**, per §4: NOT added to `RS.Shared.UIKit` / `RS.UITemplates.Kit` and
  NOT under drift control. Because the module lives INSIDE the ScreenGui, promoting it to the Game
  later is just copying the ScreenGui — the API travels with it.

**PART B — the Play entry (§3).** `HUD.Left.Buttons.Play` (**not** `HUD.Right`, which holds
Event/Profile/Quests) → veil → hide every other ScreenGui → `PlayGUI.Enabled = true` → `MainMenu`.
`LeaveButton` reverses it. **The hide SNAPSHOTS each screen's `Enabled` and restores that remembered
value**, rather than blanket re-enabling — otherwise leaving the menu would pop open every screen
that was legitimately closed (ItemsGUI, SummonScreen, IndexScreen and AscensionScreen are all
`Enabled = false` at rest). 15 screens hidden and 15 restored, verified.
- **`PlayGUI` itself was misconfigured and is now fixed:** it shipped `Enabled = true` and
  **`ResetOnSpawn = true`** — the exact UnitsGUI trap the brief warns about, where Roblox re-clones
  the ScreenGui every spawn and every reference captured at startup goes stale. Now `Enabled = false`,
  `ResetOnSpawn = false`, `DisplayOrder = 20`, `IgnoreGuiInset = true`.
- **Respawn is handled, not hoped for.** `HUD`/`Hotbar`/`ExpBar`/`UnitsGUI` DO have
  `ResetOnSpawn = true`, so they come back Enabled and their Play button is a NEW instance. The
  controller re-hides newcomers through `PlayerGui.ChildAdded` while the menu is open and re-binds
  the Play button to the re-cloned HUD (`[DIAG] PlayGUI re-bound to the respawned HUD's Play button`).

**PART C — camera (§5).** Scriptable at `Workspace.PlayGUICamera.CFrame` on enter; Custom +
Humanoid on exit. **That CFrame is the USER'S framing and is only ever READ** — P1 set the part's
properties and left the CFrame alone, and this session kept it that way (asserted unchanged at
`(-935.44, 5.643, -158.721)`). Parallax is a cursor-derived rotation clamped to
`ParallaxMaxDegrees` (2.5°) and LERPED toward its target every RenderStepped, applied as
`baseCF * CFrame.Angles(pitch, yaw, 0)` — **rotation about the camera's own origin, so the camera's
POSITION never moves** and `|camera − PlayGUICamera| = 0.000000` studs even mid-parallax.
- **Released on `CharacterAdded` unconditionally**, not just on Leave. §5 is explicit that a player
  who dies in the menu must not be left with a stuck camera; a menu-open-only guard would have
  missed exactly that case.

**PART D — transitions (§10).** `MainMenu` ↔ `StoryModeFrame` ↔ `LobbyFrame`, `GroupTransparency`
0↔1 plus a 24px slide, `0.22s` Quart/Out, the two halves overlapping by half.
- **§10 specifies `GroupTransparency`, which only a CanvasGroup has, and all three frames were
  `Frame`s.** There is no way to add a CanvasGroup that fades a frame's own background AND keeps
  `PlayGUI.Main.MainMenu.GameModesFrame…` resolving — wrapping reparents the children and breaks
  every path §7/§8 depends on. So the three frames were **CONVERTED Frame → CanvasGroup in the Edit
  datamodel** (authoring, which is AD-UI's canon, and pre-authorised in the brief). 20 carried
  properties captured BEFORE and AFTER and diffed: identical on all three, including
  `StoryModeFrame`/`LobbyFrame`'s odd authored `Position` of `{-0.00052083336, 0},{0, 0}`. Children
  and child ORDER preserved (the frames are equal-ZIndex siblings, so order IS draw order), and all
  10 spot-checked blueprint paths still resolve. **Known side effect, written into the doc:** a
  CanvasGroup rasterises its descendants, so descendant `ZIndex` becomes local to the group and
  anything outside the group's rect is clipped. All three are full-screen, so nothing overflows.
- **Every frame's authored `Position` is captured ONCE at startup and force-assigned at the end of
  every transition.** Offsets are never accumulated — §10's stated failure mode is an interrupted
  tween that never resets, which drifts frames permanently out of place.
- Input is ignored while a transition is in flight; `DiagTransitionCount` makes that observable.

**PART E — visibly disabled buttons (§6/§11).** `ChallengeModeButton`, `RaidsModeButton`,
`EventsModeButton` and `FindMatchButton` each got a real `InactiveOverlay` authored in the Edit
datamodel, **copying the pattern the DifficultyButtons already use** (black Frame, BGTrans 0.5,
`Active`/`Selectable` false, matching `UICorner`) plus a `ComingSoonLabel` reading "COMING SOON".
The controller shows the overlay and sets `Active`/`Interactable`/`AutoButtonColor` false —
`Interactable = false` also stops the `UIKitButton` hover animation, **which mattered because
`FindMatchButton` is the only one of the four carrying that tag** (the three mode buttons are
untagged). Not a silent no-op: they read as disabled and take no input.

**Verified live (Play, Lobby) from a REAL LocalScript + `get_console_output`** — not
`execute_luau`, whose VM caches requires and served B7 a stale pre-edit module. Tooling cannot
synthesise clicks, so a temporary `StarterPlayerScripts.P2AcceptanceHarness` drove the SAME
functions a click runs via `DevAutoOpen`/`DevGoto`/`DevLeave`; it was **DELETED at landing**
(confirmed absent). **`[Test] P2 RESULT: PASS (40 pass, 0 fail)`**:
- (a) veil observed `Enabled = true` during entry then back to false; `PlayGUI.Enabled = true`,
  `Main.Visible = true`, landed on `MainMenu` at its authored position with `GroupTransparency 0`;
  **all 15 other ScreenGuis hidden**, and after Leave all 15 restored to their remembered values.
- (b) `CameraType = Scriptable` on enter, `|camera − PlayGUICamera| = 0.000000` studs,
  `PlayGUICamera` CFrame unmoved; `Custom` + `subject=Humanoid` after a real **death/respawn taken
  while the menu was open**, and `Custom` again after Leave.
- (c) all four edges (MainMenu→Story→Lobby→Story→MainMenu) completed; after each one **all three**
  frames asserted at their exact authored Position and correct `GroupTransparency`/`Visible`; a
  second `DevGoto` fired 0.02s into a transition moved `DiagTransitionCount` by **+1, not +2**.
- (d) all four unavailable buttons: overlay visible, label "COMING SOON",
  `Active`/`Interactable`/`AutoButtonColor` all false — and `StoryModeButton` still live.
- Boot otherwise clean; `UIKitBootstrap` tagged 45 buttons. Every `Dev*` attribute across all nine
  harness hosts swept and confirmed OFF/0/"" after the Play round trip.

- **Contract impact: NONE.** No shared module, template, schema or teleport change. Drift re-checked
  at landing: **Lobby 25/25**, byte-identical to bootstrap; the Game's 24/25 `MetaMath=MISSING` is
  untouched and still expected.
- **Docs:** `docs/systems/lobby-ui.md` hit its 300-line cap, so PlayGUI + LoadingScreen were **split
  into the new `docs/systems/play-menu.md`** and registered in `docs/INDEX.md` (lobby-ui.md back to
  299, CONTEXT.md compressed back under 150). ROADMAP's PlayGUI row and blueprint §9's P2 both flipped.
- **PENDINGs:** no new ones. **The standing USER-authoring PENDING now blocks P3 specifically** —
  P2 needed none of it, P3 needs the triple `StageNameLabel` and the `ItemIconTemplate` rename.
- Commit is **local — push pending**. **Five unpushed now** (origin/main is still at B12's `ae65343`).

## 2026-08-09 [lobby] B14 — PlayGUI **P1**: the StageRegistry mirror gets its stage/act structure back, camera part fixed. Both B13 blockers closed.

Bootstrap drift **Lobby 25/25 GREEN**. Integration gate: **No Integration needed — proceeding**
(P1 touches no shared module, no template and no contract). Blueprint `playgui.md` session-task
**P1**, both parts. **The active Studio instance was the GAME at bootstrap** — the B9/B13 hazard,
caught by `list_roblox_studios` before any read, and every `execute_luau` this session opened with a
Lobby assertion (`Workspace.Lobby` + `SSS.Server.Lobby.LobbyServices` present, `RS.Configs.Towers`
ABSENT) that aborts on mismatch.

**PART A — `RS.Configs.StageRegistry` now carries `StageNumber`/`StageName`/`ActNumber`/`ActName`.**
This was blueprint blocker **B-1**, and it gated the whole feature: without it PlayGUI cannot group
acts under a stage or fill `StageNameLabel` / `ActNumberActNameLabel`.

- **The names could not be derived, only copied.** The repo recorded exactly TWO of them — Stage 1
  "The Farm" and Act 1 "Protecting the Fields", both captured in B13's audit prose. Acts 2 and 3 had
  no name anywhere in the repo OR the Lobby (`script_grep` for "Protecting"/"The Farm" in the Lobby:
  zero matches). The brief forbade inventing them and forbade reaching into the Game place, so the
  session **stopped and asked** rather than guessing. The user authorised a **read-only** lookup.
- **Read-only Game lookup, then straight back.** `set_active_studio` → Game → `script_grep ActName` +
  three `script_read`s → `set_active_studio` → Lobby → re-assert. **Zero writes in the Game place.**
  Canon: all three acts are Stage 1 **"The Farm"**; ActNames are 1 **"Protecting the Fields"**,
  2 **"The Scarecrow Awakens"**, 3 **"Harvest of Ruin"**.
- **`DisplayName` is NOT `ActName`, and conflating them was the tempting wrong answer.** The mirror
  already had `DisplayName` = "The First Alamat"/"Rising Legend"/"Myth's End", which look like act
  names. They are not: Act 1 is DisplayName "The First Alamat" *and* ActName "Protecting the Fields".
  Reusing `DisplayName` would have shipped three wrong titles that no test would catch. The module
  header now says so explicitly, and `StageInfo` groups the two sets of fields under separate comments.
- Existing keys untouched (`StageSelectScreen` still reads them until P6): `Id`, `DisplayName`,
  `ActLabel`, `NextActId`, `Recommended`, plus `Get`/`IsValid`/`SanitizeDifficulty`/`List`.
- **Difficulty was NOT rescaled** (ADR-0011). `DifficultyMin/Max/Default` stay `1`/`1000`/`100`. The
  header now names BOTH scales, per B13's rule that every doc quoting a difficulty number says which
  scale it means: WIRE 1–1000 here, UI 1–100 in PlayGUI only, converted at the payload boundary.
- **New standing hazard, written into the module:** nothing validates these NAMES cross-Place — the
  Game re-checks only the `Id` — so if AD-Game renames an act, this mirror goes stale **silently and
  shows players the wrong title**. Id drift fails safe; name drift does not.

**PART B — `Workspace.PlayGUICamera`** (blocker **B-2**): `Transparency 0 → 1`,
`CanCollide true → false`, `CastShadow true → false`, `Anchored` already true and left true. It stays
a **Part** (a CFrame source is what PlayGUI wants). **CFrame and Size were captured before and after
and are byte-identical** — the framing is the user's and was not touched.

**Verified live (Play, Lobby) from a REAL Script + `get_console_output`** — not `execute_luau`, whose
VM caches requires and served B7 a stale pre-edit module that looked exactly like a real failure. A
temporary `SSS.P1AcceptanceHarness` printed the evidence and was **DELETED at landing** (confirmed
absent):

- `StageRegistry.List()` → **3 entries**, each printing all four new fields AND all existing keys:
  `[1] Stage1_Act1 | Stage 1 "The Farm" | Act 1 "Protecting the Fields" | DisplayName "The First
  Alamat" | ActLabel "Stage 1 - Act 1" | NextActId Stage1_Act2 | Recommended 100`; `[2] Stage1_Act2
  … Act 2 "The Scarecrow Awakens" … NextActId Stage1_Act3 | 150`; `[3] Stage1_Act3 … Act 3 "Harvest
  of Ruin" … NextActId **nil** | 200`.
- Structure asserted, not just printed: 3 acts, every `StageNumber == 1`, `ActNumber` 1/2/3 in order,
  chain `Act1→Act2→Act3→nil` intact, `Get("Stage1_Act2").ActName` survives, `IsValid("Nope")` false.
- Wire difficulty scale re-asserted `Min=1 Max=1000 Default=100`.
- Camera: `ClassName=Part Transparency=1 CanCollide=false CastShadow=false Anchored=true`.
- `[Test] P1 RESULT: **PASS**`. Boot otherwise clean — no errors, no warnings.
- Both edits re-verified from the saved file AFTER the Play round-trip (4/4 fields, 4/4 canon names).
  Every `Dev*` harness attribute swept and confirmed OFF.

- **Contract impact: NONE.** No shared module, template, schema or teleport change; drift still
  **25/25** (Lobby) and the Game's 24/25 `MetaMath=MISSING` is untouched and still expected.
- **PENDINGs:** P1's half of the PlayGUI PENDING is **CLEARED**. **Correction to the standing
  USER-authoring PENDING: it blocks P3/P4/P6, NOT P2.** The three fixes are the triple
  `StageNameLabel` (P3), the `ItemIconTemplate` rename (P3), and the slider Fill/Handle (P4) +
  player-row template (P6). **P2 [AD-UI] needs none of them and is unblocked now.**
- **Observation for AD-Game, not touched here:** `Stage1_Act2` has `StartingLives = 15` with the
  comment "less margin than Act 1", but Act 1 has `StartingLives = 3`. Either the number or the
  comment is wrong. Read-only observation from the name lookup; AD-Game's canon, AD-Game's call.
- Commit is **local — push pending**. Four unpushed now (origin/main is still at B12's `ae65343`).

## 2026-08-09 [integration] B13 — PlayGUI BLUEPRINTED (not built). ADR-0011 kills a silent 10×-difficulty landmine.

**Docs only — no Studio writes, so drift is untouched: Lobby 25/25, Game 24/25 (`MetaMath`, expected).**
The user asked for the whole PlayGUI feature; I stopped and blueprinted it instead, because it spans
**four owner chats** and contained two contract changes. They chose: blueprint now, difficulty as a
display-only remap, queue designed but not built.

**FIRST: the active Studio instance had silently flipped to the Game, and the ids had changed.**
Caught it because a `StarterGui` search returned `MatchHUD`/`TowerSelection`/`WavePrep` — Game
screens. This is the B9 hazard, and it is why every write in this project re-lists the studios first.
Re-verified B12 survived the restart: `TraitRegistry eca681ad`, `TraitDefinitions 56e81e37`,
`TierConfig 490f1f9d`, `SummonEngine` calling `Roll(rng)`, harness gone, doc mirrors intact. The
`RollTrait` string still in `SummonEngine` is **comment-only** — the sole live call is `.Roll(rng)`.

**ADR-0011 — difficulty is remapped for DISPLAY only; the wire format does not move.**
The ask was a 1%–100% meter where 1% = normal. Today `DifficultyPercent` is **1–1000 with 100 =
normal**, it rides in the teleport v2 payload, and the Game computes
`enemyHP × BaseHealthScale × DifficultyPercent/100`. Redefining it in place is **silent and
live-breaking**: the two Places publish separately, so a republished Lobby sending `100` meaning
*max* to a Game still reading `100` as *normal* runs every match at **10× enemy health** with no
error — no `[CONTRACT]` line fires, because the field is present, numeric and in range. Strictly
worse than the v1→v2 cutover, which at least failed loudly on the version integer.
So: the UI reads 1–100, one function converts at the payload boundary
(`100 + (ui-1)*900/99`), and `DifficultyPercent` keeps its name, range and meaning. Zero contract
risk, zero republish coupling, one seam to cut if it ever needs to become real. The honest cost is
that the confusion MOVES rather than vanishes — players see 1–100, configs and docs still say
100–1000 — so every doc quoting a difficulty number must now name its scale.

**`docs/blueprints/playgui.md` — written from a LIVE AUDIT of the tree, not from the description.**
That audit is most of the value, because four things in the spec did not match reality:

- **The Play button is `HUD.Left.Buttons.Play`**, not `HUD.Right` (Right holds Event/Profile/Quests).
- **`Workspace.PlayGUICamera` is a visible, solid Part** — `Transparency = 0`, `CanCollide = true`.
  Players can walk into it and it renders in-world.
- **`HUD.Top.CurrencyBar` is NOT script-built** and must not be "converted". It is a designed Frame
  cloning a `CurrencyTemplate` child — the sanctioned pattern. The request to convert the currencies
  rested on an assumption the audit contradicts. **`StageSelectScreen` genuinely is** script-built:
  one child, a `Controller` LocalScript, 1 total descendant. That one gets deleted at P6.
- **The blocker that stops everything: the Lobby's `StageRegistry` mirror has no stage/act
  structure.** `List()` gives `Id`/`DisplayName`/`ActLabel`/`NextActId`/`Recommended`;
  `StageNumber`, `StageName`, `ActNumber`, `ActName` are all **nil**. The Game's configs have them
  (Stage 1 "The Farm" / Act 1 "Protecting the Fields"); the mirror dropped them. **The stage and act
  lists cannot be populated at all until that is fixed** — which is why it is P1 and why a UI
  session starting on P2/P3 first would have stalled.

Also flagged for the user to fix in Studio (authoring, not code): **`StoryModeFrame.SelectedAct` has
THREE children named `StageNameLabel`** — `FindFirstChild` returns an arbitrary one, so a controller
would look correct and update the wrong label; `RewardsScrollingFrame.ItemIcon` wants renaming to
`ItemIconTemplate` + `Visible=false`; and the slider Fill/Handle and the lobby player-row template
do not exist yet (`DifficultyGradient` holds only a `UIGradient`).

- **Session plan P1–P7** by owner: P1 AD-Lobby (registry + camera part), P2 AD-UI (loading screen,
  camera, transitions), P3 AD-UI (stage/act lists), P4 AD-UI (slider + reward preview), P5 **AD-Game**
  (reward scaling — `StageConfig.Rewards` is its canon, not a UI session's to improvise), P6 AD-Lobby
  (LobbyFrame + launch, then delete `StageSelectScreen`), P7 deferred queue.
- Reward curve fixed on the UI scale: Normal `Gold lerp(100→300)` min / `lerp(300→500)` max across
  1→100%; Insane same curve plus items.
- **Queue designed, not built** (§11): MemoryStore keyed by stage|act|mode|difficulty, party-aware,
  timeout → solo fallback, handing off to the **existing** `PartyService` launch — not a second
  launch path. `FindMatchButton` ships disabled meanwhile.

- **Contract impact:** NONE. No schema, payload, shared module or template touched.
- **PENDINGs:** NEW — USER authoring fixes (blocks P2/P3); PlayGUI P1–P7. Carried: republish + live
  teleport loop (USER), `BannerChoices` v2→v3, AD-Gacha review of B12's `SummonEngine` edit, the
  AD-UI B7–B11 backlog, `MetaMath` at Phase D.
- **B13 did NOT do the `BannerChoices` schema bump** it was originally prompted for — the user
  redirected. It remains the top contract item. Push pending (sandbox auth).

## 2026-08-09 [integration] B12 — both-places backlog: `SellValueByTier` + the TRAIT TABLE promoted. Trait-on-summon was silently dead since B3.

Bootstrap drift as expected: **Lobby 23/23 GREEN, Game 22/23 with `MetaMath=MISSING`.**
Integration gate: **"Integration IS the task — proceeding."** User picked items **1 + 4** of the
four-item backlog (2 = the v2→v3 schema bump and 3 = the MetaMath deploy were deliberately NOT
taken; see "Not done"). Shared canon **23 → 25 entries (18 modules + 7 templates)**; at landing
**Lobby 25/25 GREEN, Game 24/25** (`MetaMath` still Lobby-only, still expected).

**1. `SellValueByTier` + `GetSellValue(tier)` in `TierConfig`** — unblocks blueprint C3's sell-dupes
half. `a0d6e3a3 → 490f1f9d`, deployed and **hash-matched in BOTH Places**.

- Silver by tier, ~×2.5 per step: Common 10 · Rare 25 · Epic 60 · Legendary 150 · Mythic 400 ·
  Secret 1000 · Exclusive 1500 · Bathala 3000. **Retune that one table, never the callers.**
- **`GetSellValue` falls back to 0, NOT to Common** — deliberately unlike `GetColor`/`get`, which
  fall back so the UI cannot nil-error. This one pays CURRENCY: an unknown or typo'd tier quietly
  minting Silver is far worse than one that pays nothing, and a 0 payout is visible and reportable.
- Numbers are mine, not the blueprint's (it specifies only the name, location and "Silver by tier").
  Nothing consumes them yet — `UnitsGUI.QuickSellButton` is still unwired — so they are safe to
  change. Flagged for the user rather than asked about, since no shipping flow depends on them.

**2. The TRAIT RARITY TABLE is now shared canon** — `TraitRegistry eca681ad` + `TraitDefinitions
56e81e37`, byte-identical in both Places. This unblocks **C1 (trait reroll)** and **C2 (stat
reroll)** and switched **trait-on-summon LIVE with no other Lobby change**.

- **Two entries, not one:** `TraitRegistry` requires its sibling via `script.Parent`, so they
  promote and deploy TOGETHER — one without the other is a broken require.
- The Game's copies were the SOURCE and were **not modified**; disk canon was proven a byte-exact
  reproduction by hash + length before either Place was touched.
- `TraitRegistry`'s own header already said the roll lives there "so the Game place and Lobby share
  ONE definition of trait rarity". The intent was written down long ago; only the sharing was missing.

**3. THE FIND: `SummonEngine` has been calling a function that does not exist, since B3.**

The prompt asked me to verify the assumed `TraitTable.RollTrait(rng)` API. It is **wrong**, and worse
than wrong — the module lookup was correct all along (`RS.Configs.Traits.TraitRegistry`), so only the
FUNCTION name was bad: the real API is **`Roll(rng)`**. Because the call sits inside a `pcall`, it
**failed silently**: every summoned unit got `Trait = nil` and nothing anywhere reported a problem.
Had the table been promoted without checking, trait-on-summon would have stayed dead and looked fine.

- Fixed to `ctx.TraitTable.Roll(rng)`; the pcall failure path now **`warn`s once per server** rather
  than shrugging, so the next API drift is loud instead of invisible.
- **Measured live over 20,000 rolls:** 15.15% of summons enter the trait branch (matching
  `TraitOnSummonChance = 0.15`), but the table is ~84% `None`, so a REAL trait lands on **2.43% of
  all summons** — Blitz 213, Sniper 198, Deadeye 66, Godly 9. Anyone tuning `TraitOnSummonChance`
  should know it is multiplied by that ~16%, not applied to the real-trait rate directly.
- **`"None"` is normalised to nil, not stored.** Fixing the call surfaced a second problem I had just
  created: ~12.7% of ALL summons would have persisted the sentinel STRING `"None"` into the profile,
  while every other grant path — starter choice, `DevSetOwnedTowers`, `GrantUnit`'s default — writes
  nil. Two spellings of "no trait" in one field is how `Trait ~= nil` silently stops meaning "has a
  trait". Gameplay is identical either way (`TraitRegistry.Get` maps both to the None definition);
  this is about the profile staying honest. Re-ran on the same seed afterwards: identical real-trait
  counts (213/198/66/9), so the normalisation dropped only the `"None"` writes and did not shift the
  RNG stream.

**Verification.** A temporary real Script (`A9IntegrationCheck`, since DELETED) + `get_console_output`
— never `execute_luau` for module behaviour, which caches requires and served B7 a stale module.
All 8 sell values exact, unknown tier → 0; `Roll` present and `RollTrait` confirmed absent; roll
distribution within band on 20k samples; trait-on-summon PASS. Every `Dev*` attribute swept and
confirmed off.

**Not done, deliberately:** item 2 (the `BannerChoices` v2→v3 schema bump) and item 3 (deploying
`MetaMath` to the Game). The user chose "prefer fewer, fully verified". **A schema bump deserves a
session where it is the only risky thing** — invariant 5 means a half-finished one strands the two
Places on different `SCHEMA_VERSION`s across a session boundary. Item 3 remains optional housekeeping
by `STATE.md`'s own account (`MetaMath=MISSING` in the Game is EXPECTED until Phase D). The AD-UI
B7–B11 review backlog was stretch work and was not reached.

- **Contract impact:** NONE. No schema bump, no template change, no version moved. Two shared-module
  ADDITIONS + one shared-module EDIT, all deployed to both Places in this session.
- **PENDINGs:** CLEARED — `SellValueByTier`, and the AD-Traits trait-table promotion. NEW — AD-Gacha
  should review Integration's `SummonEngine` edit (user-authorised). Carried: republish + live
  teleport loop (USER), `BannerChoices` v2→v3, `MetaMath` at Phase D, the B7–B11 AD-UI review.
- Push pending (sandbox git auth); commit is local.

## 2026-08-09 [lobby] B11 — four user fixes: equip colours, ONE UNIT PER FAMILY, ascension moves to an NPC.

Bootstrap drift **23/23 GREEN**, unchanged at landing. Integration gate: **"No Integration needed —
proceeding."** All four changes are Lobby-local; `UIKitHotbar` is shared canon and was **not**
touched (only the Lobby-local `HotbarController`).

**1. The equip button is GREEN for EQUIP, RED for UNEQUIP.** Gradient AND stroke are set on every
refresh rather than toggled, so it cannot strand on the wrong colour. Green runs **dark first** as
asked — `0 = rgb(0,62,0)` → `1 = rgb(0,170,0)`, stroke `rgb(0,170,0)`; red keeps its designed
`rgb(170,0,0)` → `rgb(62,0,0)`. Note the green's stop order is the *mirror* of the red's
bright→dark; both constants sit together at the top of `refreshEquipButton` if you want them to run
the same way.

**2. ONE UNIT PER FAMILY, and an evolved form counts as the same unit.** Equipping a unit whose
family is already equipped **replaces the incumbent in its slot** rather than being refused —
"equip this one instead" is what the player means.

- Enforced **server-side in `LoadoutService`**, because that service is the only writer of
  `Data.Loadout`; a client check alone would be advisory. The response now carries `ReplacedUuid`
  so the UI can say a unit was swapped rather than the player noticing one vanish from the hotbar.
- The newcomer takes the **incumbent's slot**, so a swap looks like a swap.
- **Family resolution is `RS.Configs.Meta.UnitFamilyConfig`** (new, Lobby-local): explicit overrides
  first, then a naming convention (everything before `(` or `_`), then the id itself. That is why
  `Warchief(Warlord)` groups with `Warchief` **before any evolved tower is catalogued**.
  Evolutions are Phase F, so the real base→evolved data does not exist yet; putting the map here
  rather than in `ItemCatalog` kept this a Lobby-only session, since `ItemCatalog` is SHARED canon.
  **When Phase F lands, point `FamilyOf` at the Evolutions registry and delete `Overrides`** — every
  caller already goes through that one function.
- The client's "loadout full" guard now **exempts a same-family swap**, since a swap does not grow
  the list. Otherwise a full bar would have blocked the very replacement the rule exists to allow.

**3. Ascension moved OUT of the Units GUI into its own NPC-opened screen — ADR-0010.** The blueprint
put it in the Units detail pane and B9 built it there. It is now `StarterGui.AscensionScreen`,
reachable only by walking up to **`Workspace.Lobby.NPC_Ascension`** and using its ProximityPrompt —
**the Lobby's first NPC and first prompt; there was no NPC system at all before.**

Worth saying plainly: **this makes Phase C more consistent, not less.** The blueprint already
specifies *"NPC → UI"* for the trait reroll (C1) and the stat reroll (C2); ascension was the odd one
out. C1/C2 should now copy this shape.

It also retired three problems B9 had shipped with:

- the pane needed AD-UI's `UnitsController` to publish its selection just to know what to act on
- it had to re-bind on every spawn because `UnitsGUI.ResetOnSpawn = true`
- it could not refresh AD-UI's grid after destroying a duplicate, so it shipped a *"reopen Units to
  refresh"* caveat — **gone**, because the screen now owns its own picker and just rebuilds it

B9's one-line selection publish **stays**: unused by ascension now, but C2's and C4's panes want
exactly it, and removing it would only mean re-adding it.

**4. Two mistakes of mine, both caught by the harness rather than by reading.**

- **`;(expr)` is not valid Luau.** I used the `;(cell :: GuiButton).Activated:Connect(...)` idiom in
  the picker loop; it fails to compile and the ONLY symptom is the whole controller silently never
  running. **This is the second time this exact idiom has cost a session** (B8's harness was the
  first), so it is now written into the code as a warning rather than left as folklore.
- **Writing a full replacement with an empty `old_string` onto an EXISTING script APPENDS instead of
  replacing.** `AscensionController` ended up 27,174 bytes containing both the new B11 version and
  the whole B9 one — two `ready` prints, an orphaned `[AscensionPane] AscensionPanel missing`
  warning, and B9's code still hunting for a pane B11 had deleted. Found because the console showed
  the controller reporting ready twice. Truncated at the new version's final line and re-verified:
  16,351 bytes, one `ready`, zero `[AscensionPane]`.

**Acceptance — verified LIVE in Play, harness since deleted, all `Dev*` OFF/empty:**
`FamilyOf` correct for `Warchief` / `Warchief(Warlord)` / `Warchief_Warlord` / unrelated towers ·
equipping a second Archer **replaced the first, took its slot 1, left the list size at 2, stayed
dense, and left the unrelated unit untouched** · re-equipping the same uuid produced no duplicate ·
button read `UNEQUIP` + red for an equipped unit and `EQUIP` + green (dark first) for an unequipped
one · `AscensionPanel` gone from `UnitsGUI` · `AscensionScreen` present at `DisplayOrder 70`, closed
by default · NPC + prompt present (range 12, *"Ascend a unit"*) · opening listed **4 eligible
Mythic+ units** with the detail pane reading `A3 / A3  DMG x3.00`.

**Contract impact: NONE.** No schema, no shared module, no template. One new Lobby-local config, one
new screen, one new BindableEvent, one new NPC model.

**PENDINGs: 0 new, 1 amended** (AD-UI review → five items). Docs: new `ADR-0010`, `ascension.md`
rewritten around the new screen, `lobby-ui.md` updated and trimmed back under its cap.

**USER must republish the LOBBY** — B11, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B10 — EQUIPPING WORKS. A button nobody had ever connected.

Bootstrap drift **23/23 GREEN**, unchanged at landing. Integration gate: **"No Integration needed —
proceeding."** No shared canon touched — `UIKitHotbar` is shared, so only the Lobby-local
`HotbarController` was edited.

**THE FINDING THAT PROMPTED THIS SESSION.** `Server.Lobby.LoadoutService` + `Remotes.SetLoadoutSlot`
shipped **2026-08-06**, and **A7 proved the whole chain live** — equip in the Lobby, and the Game
place starts a match from those exact uuids. That proof ran through a **test harness**. A grep for
callers of `SetLoadoutSlot` returned the service itself and nothing else: `UN/EquipButton` sat in the
Units detail pane **unreferenced by any script**. For three days the loadout system was complete,
verified, documented as done — and **no player could equip anything**, because the last button was
never connected. The docs said "✅ Equipping" and meant it about the plumbing.

Worth keeping as a lesson: *"verified live"* and *"reachable by a player"* are different claims, and
a harness that drives a remote directly cannot tell them apart.

**What shipped.** `UnitsController` now wires the button: EQUIP / UNEQUIP / **LOADOUT FULL** derived
from the selected unit, a call to `SetLoadoutSlot`, then `loadUnits()` so `Equipped`, the sort order
(equipped first) and every card update — and a new **`ClientEvents.LoadoutChanged`** that
`HotbarController` listens to.

Nice detail: `HotbarController` already carried `-- Re-read after the Units screen closes: equipping
there changes what belongs in the slots`, hooked to `OpenUnitsWithUuid`. **That refresh was written
in 2026-08-06 anticipating exactly this, back when nothing could equip.** It stays (it still covers
a loadout changed by anything else), but the real signal is now a dedicated event rather than
reusing an "open screen" ping as a refresh — that ping also re-opens and re-selects, which is a side
effect nobody wanted here.

**Two rules the implementation had to respect, both of them other people's:**

- **`Data.Loadout` must stay DENSE.** It is a schema-v2 `{ string }` the MATCH LAUNCHER reads.
  Unequipping the middle slot makes the list close up; re-equipping appends at the end. Verified
  explicitly — the harness asserts no holes and no duplicates after every single operation, because
  a hole here breaks match launches in the *other* Place.
- **Equipping into a full loadout is refused CLIENT-SIDE rather than sent.** `LoadoutService` would
  clamp the insert and silently drop whoever holds the last slot. Reading its code, that clamp is a
  dense-list SAFETY rail, not a designed swap — so relying on it would mean a player loses a unit
  they never chose to unequip. The button reads `LOADOUT FULL` and goes inactive instead. **No
  server behaviour was changed**; the guard is purely additive.

**Ownership, raised before writing anything.** Equip is **AD-Lobby canon** (`LoadoutService`) inside
**AD-UI's screen** (`UnitsGUI`) — it is not AD-Gacha's row on either axis, exactly like B9's refusal
of C1. The user was asked and chose "do it properly, editing `UnitsController`" over a zero-touch
workaround that would have left the grid showing stale `Equipped` state. Precedent for the
cross-ownership edit is `LoadoutService` itself, which AD-UI wrote into AD-Lobby's canon in
2026-08-06 with the same kind of sign-off. **AD-UI's review PENDING now lists four items.**

**Acceptance — verified LIVE in Play, harness since deleted, driven through the real button path
(`DevEquip` runs the same `doEquipToggle()` a press runs, since `GuiButton.Activated` cannot be
fired from tooling):**

- equip A, B, C → `[1:A 2:B 3:C]`, order preserved, **dense after every step**
- **unequip the MIDDLE one → the list CLOSES UP** to `[1:A 2:C]`, no hole
- re-equip → appends at the END, not back into the gap
- at the 3/3 cap with a spare selected: label reads **`LOADOUT FULL`**, button **inactive**, and a
  press leaves the loadout **byte-identical** — nobody silently dropped
- direct write to **locked slot 4** → `slot_locked`, `RequiredLevel = 5`
- **unowned uuid** → `not_owned`
- **hotbar filled slots == `#Data.Loadout`** (3 == 3) after the dust settled

**Contract impact: NONE.** No schema, no shared module, no template. One new client-side
BindableEvent.

**PENDINGs: 0 new, 1 amended** (AD-UI review → four items). Docs: `docs/systems/lobby-ui.md` gained
the equip section plus a `ClientEvents` list, and was trimmed back to exactly its 300-line cap.

**USER must republish the LOBBY** — B10, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B9 — ASCENSION (blueprint C3). The session opened by refusing its own task.

Bootstrap drift **23/23 GREEN**, unchanged at landing. Integration gate: **"No Integration needed —
proceeding."**

**THE ASSIGNED TASK WAS C1 (trait reroll). IT WAS REFUSED, FOR THREE REASONS.**

1. **No trait table exists in the Lobby.** `RS.Configs.Traits` is absent and nothing trait-shaped is
   in `shared/src`. A repo-wide grep found the concept only in comments explaining its absence.
2. **Its shape is unknowable from here** — it lives in the Game place, which this session may not
   open. Worth recording: `SummonEngine` has ASSUMED `TraitTable.RollTrait(rng)` since B3 and that
   guess has never been checked against the real module.
3. **C1 is not AD-Gacha's system.** The blueprint's own Phase C header reads *"[AD-Traits
   rerolls/worthiness; **AD-Gacha ascension**; home Lobby]"*, and `OWNERSHIP.md` assigns "Trait &
   stat rerolls / worthiness" to AD-Traits. Building it would have been a single-writer violation on
   top of a blocked dependency.

Meanwhile **C3 Ascension is AD-Gacha's row and was fully unblocked**: `AscensionConfig` shared and
drift-green, uuid duplicates since B0, `GrantService` for spending, and consuming a dupe is just
removing a `Data.Units[uuid]` — no schema change. User chose to switch. **That is the whole reason
this session shipped anything.**

**THE CONFIG DISAGREES WITH THE BLUEPRINT, AND THE CONFIG WON.** The blueprint says the cost is
*"1 dupe … + items + Silver via AscensionConfig"*. The shipped config carries
`Cost = { Dupes = 1, Items = {} }` and **has no Silver field at all**. `AscensionConfig` is SHARED
canon owned by AD-Game, so adding Silver would be a cross-Place change this session cannot make.
Implemented the config; the Items path works and is tested but is unexercised because every level
ships `Items = {}`.

**The dupe rule is the dangerous part, and it got the most attention.** Ascending PERMANENTLY
DESTROYS a unit. `AscensionRules.PickDupe` skips the unit being ascended, anything of a different
`TowerId`, and anything **Locked**, **Favorited** or **currently in `Data.Loadout`** — the blueprint
names only locked+unfavourited; **equipped was added** because eating the unit someone is about to
play with is the same class of mistake. Among survivors it takes the **oldest by `ObtainedAt`** with
**uuid as a stable tiebreak**, so the pick cannot differ between preview and commit.

**Confirmation is enforced server-side.** `RequestAscend(uuid, expectedDupeUuid)` re-derives its own
pick and refuses with `dupe_changed` if it no longer matches what the player was shown; omitting it
gives `confirm_required`. The client's uuid is never trusted, only compared. On commit, **items are
spent before the dupe is destroyed** so a material shortfall cannot leave the duplicate already gone.

**`AscensionRules` is split out of `AscensionService`** because **`RemoteFunction.OnServerInvoke` is
write-only** — logic inside a remote handler cannot be reached by a harness, and "which unit do we
destroy" must be testable directly. Same split, same reason, as `SummonEngine`/`SummonService`. It
also guarantees ONE implementation shared by the preview and the commit.

**`GrantService.SpendItems` added** — the inverse of an Item grant, living in `GrantService` for the
same reason `Spend()` does (invariant 1 greps for writes that bypass it). All-or-nothing; spending
to zero stores **`nil`, not `0`**.

**ONE line was added to AD-UI's `UnitsController`** (user-authorised): `selectUnit` now publishes
`selectedFrame:SetAttribute("Uuid"/"TowerId")`. `selectedId` was a private local, so no pane could
know which unit was on screen. It is the same idiom `loadUnits` already uses on every card, and it
pays for Phase C's remaining panes. **The controller itself lives in `StarterPlayerScripts`**, so
AD-UI's ScreenGui holds no AD-Gacha script — B8's split, reused.

**THREE FAILURES WORTH RECORDING, because two were mine and one was procedural.**

- **The active Studio silently switched to the GAME place mid-session.** Two `start_stop_play` calls
  timed out, and the console that came back was `MatchDirector`/`WaveDirector` — a *match*. Nothing
  was written (Play is a sandbox and no edit followed), but the Place binding was re-resolved and
  re-asserted before continuing. This is exactly what the constitution's "resolve Place binding at
  every bootstrap, never assume" rule is defending against, and it fired for real.
- **`local a, b: T?, T?` is a syntax error in Luau** — one type per declaration. It stopped
  `AscensionController` compiling, and the ONLY symptom was a pane that silently never appeared. I
  had already diagnosed a plausible-but-wrong cause (`ResetOnSpawn`) and rewritten for it before the
  compile error surfaced in the log. The rebind was KEPT because `UnitsGUI.ResetOnSpawn = true` is
  real — it is the only meta screen set that way — and the live run shows `bound to UnitsGUI`
  printing twice, so it does real work. But it was **not** the fix, and the changelog should not
  pretend it was.
- **A bug in my own code that would have read as "ascension does nothing":** `BuildInfo` returned
  early at max level *before* computing `CurrentMult`, so a fully-ascended unit displayed
  **`DMG x1.00`** instead of x3.00. Found only because the harness printed the pane's actual text.

**A harness that passed vacuously, and why that matters.** The first protection run "passed" while
testing nothing: the dev profile carries Necromancers from earlier sessions, and a previous run of
this same harness had left some at `ObtainedAt = 1000`, so the picker kept correctly choosing a
leftover while the harness locked units that were never candidates. Fixed by normalising every
pre-existing unit to "now" first. **A green test on a dirty profile is not evidence.**

**Acceptance — verified LIVE in Play (server + client harnesses, since deleted):**
oldest-first · **Locked skipped** · **Favorited skipped** · **equipped skipped** · never the unit
itself · Common refused *"Mythic+ units only"* · **stale confirm → `dupe_changed` with the dupe
still alive** · missing confirm → `confirm_required` · real ascend consumed **exactly** the previewed
uuid · A1→A2→A3 then *"Fully ascended"* · consumed units gone from `GetUnitViews` · unit count −3 ·
`Counters.Global.Ascensions` incremented · `SpendItems` partial / insufficient-unchanged /
atomic-unchanged / zero-stores-nil · pane renders for a Mythic, **hidden for a Common**, and a maxed
unit reads **`DMG x3.00`**.

**Contract impact: NONE.** No schema bump, no shared module, no template. `Counters.Global` is an
open map (the ADR-0008 precedent), so `Ascensions` is purely additive.

**PENDINGs: 2 NEW** (`SellValueByTier` in shared `TierConfig`, which blocks C3's sell-dupes half;
AD-Traits' trait table, which blocks C1+C2 entirely), **1 amended** (the AD-UI review now covers
three items). Docs: new `docs/systems/ascension.md`; `OWNERSHIP.md` Ascension row filled in.

**USER must republish the LOBBY** — B9, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B8 — the UNIT INDEX (blueprint B5). `Kit_UnitIcon` ADOPTED after 3 days parked.

Bootstrap drift **23/23 GREEN**, unchanged at landing. Integration gate: **"No Integration needed —
proceeding."** Blueprint task **B5 is done**, which leaves Selection as the only unfinished Phase-B
blueprint task — and it is contract-blocked, not effort-blocked.

**`StarterGui.IndexScreen` + `IndexController`.** The blueprint's four requirements, all DERIVED,
none typed out: iterate `ItemCatalog` Towers · obtained silhouettes (own ANY instance) · source
text · exact per-banner rates computed from configs.

**THE RATE MATHS IS THE ACTUAL DELIVERABLE, and it is two rolls, not one.**

```
P(unit on banner) = (tierWeight / totalTierWeight) × (unitWeight / totalWeightInTier)
```

`unitWeight` is `Featured.Boost` for a featured id and 1 otherwise. Getting this wrong is the
classic gacha-disclosure bug: quoting the TIER rate as if it were the UNIT rate overstates a
specific unit by the size of its tier's pool. **Verified by re-deriving every number independently
inside the harness and comparing to what the screen renders** — a wrong formula cannot pass by
agreeing with itself. Two structural checks came out exactly right and are worth keeping:

- **Standard's per-unit chances sum to `0.999950`** — precisely 1 minus Secret's `0.00005` weight,
  which is the *empty-pool tier being honestly excluded*, visible in the arithmetic.
- **EventFirstLight's sum to `1.000000`** exactly (its curated pool has no empty tier).
- Archer on Standard = **30.00%**, not 50%: Common is 60%, but BOTH Commons happened to be featured
  this rotation, so the boost cancels within the tier. Farm on Standard = **20.83%** (Rare 25% ×
  5/6, featured against an unfeatured Mage). Both matched the independent derivation to 4dp.

**Pity is deliberately NOT folded in.** It is a floor on TIER across many pulls, not a per-pull
probability; blending them yields a number that is honest about neither.

**Honesty rules, because a codex that flatters is worse than none.**

- A tower in NO pool reads *"Not currently obtainable"*. `0%` would imply merely rare.
- A banner that cannot be pulled right now **still lists its rates**, dimmed and tagged with
  `BlockedReason`. Hiding it would misrepresent the odds a player meets when it opens.
- `Secret`/`Exclusive`/`Bathala` have no catalogued towers, so they produce **no entries at all** —
  confirmed live. The screen never implies content exists that doesn't.
- Rates reuse `SummonController`'s sub-0.01% formatting, so Secret's 0.005% never prints as 0.01%.
- Source text is derived from the SAME pass that builds the rates rows, so the two cannot drift —
  and it visibly reflects B7's curation: **Farm shows only `Alamat Standard`**, because the Event
  banner deliberately excludes support towers.

**`Kit_UnitIcon` IS ADOPTED — ADR-0009, un-parking ADR-0007 after three days.** ADR-0007 parked it
with no consumer and said Phase B would *"tell us what the component actually has to do"*. It has:
B1 declined it as the reveal card, B6 used it for featured chips, and this index is its **second
real consumer**. Both consumers clone-and-fill and **neither wanted a controller** — and they hide
*different* fields, so a controller would have to be configured into doing nothing two ways.
Decision: adopted, still **no `UIKit.UnitIcon` controller**, revisit only on a third consumer
wanting the same BEHAVIOUR. **Adoption changed no bytes** — it means being USED, not edited;
`Kit_UnitIcon` still hashes `24281a2b` in both Places, verified at landing. Zero drift, no
Integration. ADR-0007 clause 3 is untouched: this is an ICON, not the unit CARD.

The silhouette costs nothing: **`ViewportFrame.ImageColor3` → black** turns a clone into a
silhouette with one property. No second template, no model mutation.

**NO AD-UI CONTROLLER CODE WAS TOUCHED, by design.** The user chose to open the index from
SummonScreen. Rather than edit `SummonController`, `IndexController` **wires the button itself** —
the same reach-across `SummonController` already uses for the HUD's Summon button. So AD-UI's screen
gained one new real instance (`RATES / INDEX`) and zero lines of changed code. Entry point is
`ClientEvents.OpenIndex`, so an NPC or HUD button can open it later with no change here.

**Two harness bugs worth recording, because both are traps rather than typos.**

- `table.insert(t, string.gsub(...))` — `gsub` returns **(string, count)**, so the count arrived as
  `insert`'s third argument and threw *"number expected, got string"*. Needs parens.
- **`GuiButton:Activate()` does not exist** and `Activated` cannot be fired from tooling, so entry
  selection could not be clicked. Added a `DevSelect` hook routing through the SAME `renderDetail()`
  a click runs — the established convention (`DevDismiss`, `DevPull`).

**A gap I closed rather than waved past:** this dev profile owns **all 8** towers, so the first run
only ever exercised the *obtained* branch — the silhouette, the headline feature, was untested and
would have passed trivially. Added `DevFakeUnobtained` (same category as `DevSimulateFirstJoin`: a
hook for a state you cannot otherwise reach) and verified the whole chain — `ImageColor3 = 0,0,0`,
name `"???"`, summary `7 / 8`, detail `NOT YET OBTAINED`, **and rates still listed while unobtained**
(odds must be visible BEFORE you own it) — then restored and re-checked `1,1,1` / `8 / 8`.

**Acceptance — verified LIVE in Play, harness since deleted, all `Dev*` OFF/empty:**
8 catalogued Towers = 8 entries, exact id match · **0 silhouette-state mismatches** against the
profile · summary `8 / 8` · both rate sums as above · per-unit rates matching independent derivation
· source text correct incl. Farm's single source · empty tiers producing no entries ·
`DisplayOrder 60` (above SummonScreen 50, below the reveal 100).

**Contract impact: NONE.** No schema, no shared module, no template byte. Drift 23/23 GREEN.

**PENDINGs: 0 new, 1 amended** (the AD-UI review now covers B7's `SummonController` delegation and
B8's button instance — B8 changed no controller code). `Data.Items` still has no writer in normal
play; nothing here changes that.

**USER must republish the LOBBY** — B8, like everything since A7, is Studio canon and not in git.

## 2026-08-09 [lobby] B7 — EVENT banners are live. Selection deferred on a CONTRACT wall, not on effort.

Bootstrap drift **23/23 GREEN**, unchanged at landing — zero shared canon touched. Integration gate:
**"No Integration needed — proceeding."** Blueprint task **B4** ("Selection banner choice flow +
Event banner window") is now **half done, deliberately**.

**THE SESSION'S REAL FINDING, BEFORE ANY CODE.** `BannerChoices` — where the blueprint says a
Selection banner stores the player's pick — **does not exist in schema v2**. A repo-wide grep found
exactly one mention: the blueprint line specifying it. Adding a top-level profile field is a
contract change, and the blueprint's own cross-phase invariant 5 ends with *"Never both Places out
of schema sync across a session boundary."* This was a **Lobby-only** session forbidden from
touching the Game place, and both Places share ONE live ProfileStore. So the compliant move was to
**stop and ask**, not to bump the schema half-way and leave a live risk window over the boundary.

The user chose: **ship Event now, defer Selection with a proposal**
(`docs/proposals/2026-08-09-selection-banner-choices.md`, which also records the rejected
`Counters.Global` shortcut and why — a banner choice is not a counter, and ADR-0008 exists precisely
because overloading one key with two meanings corrupted a verified counter).

**Event banners needed NO schema change at all**, which is what made the split clean: an Event
banner is just a banner with a `Window`, and `Window` was already in the config shape.

**What shipped.**

- **`BannerRegistry.SUPPORTED_TYPES`** — ONE source of truth for which banner types are summonable,
  read by BOTH `SummonService` (to refuse) and `SummonController` (to grey a card out). The server
  and the screen can no longer disagree about what is pullable.
- **`WindowState(cfg, nowSec?)`** → `Open` / `NotStarted` / `Ended` plus seconds-to-next-change;
  `IsOpen` is now a wrapper on it. `SummonService` refuses with **`banner_not_started`** (carrying
  `SecondsUntilOpen`) or **`banner_ended`** — two genuinely different situations to a player, so two
  codes instead of one flat `banner_closed`.
- **`BlockedReason(cfg)`** — the single player-facing "why not" string, and **`EndsInText(cfg)`**
  for an open, time-limited banner's *"Ends in 22d"*.
- **`Validate()`** now rejects a malformed window at boot (non-number bounds, `EndUtc <= StartUtc`)
  and NOTES a valid banner sitting outside its own window — which otherwise looks identical to a
  broken one.
- **`EventFirstLight` ("Festival of First Light")** — Gold at 120/pull, 2 featured on a **daily**
  rotation, `PityRef = "Default"` shared with Standard on purpose (a player grinding an event should
  not have hard-pity progress stranded when it ends), window 2026-08-01 → 2026-09-01. **Running an
  event is editing two numbers.** Dropping in another file makes a second event.
- **It is also the first CURATED pool.** Standard is `"AllSummonable"`, so the explicit
  `Pool = { [tier] = { ids } }` form had **never actually executed** until now. It does, and
  **Farm is excluded on purpose** — a support tower is a dud as an event prize.

**A latent bug found and fixed while adding the first daily rotation.** `FeaturedFor` passed
`0` as the slot offset instead of `MetaConfig.ResetOffsetSec`. That was invisible while every banner
rotated hourly, but a DAILY rotation would have flipped at **00:00 UTC while the game's day boundary
is 16:00 UTC**. Invariant 3 makes `MetaMath.Slot` the one rotation primitive and `ResetOffsetSec`
the knob it is meant to read. Verified flipping at 16:00 UTC. **Accepted cosmetic side effect,
predicted before the run and confirmed by it:** Standard's featured trio moved once
(`Babaylan/Archer/Meteor` → `Farm/Archer/Knight`) because the slot NUMBER shifted and the slot is the
seed. Hourly boundaries themselves did not move.

**ONE change to AD-UI's canon, authorised and minimal.** `SummonController` hardcoded
`BannerType ~= "Standard"`, so an Event banner would have read "coming soon" forever no matter what
the server did — no config value could flip it. With the user's authorisation the local
`blockedReason()` now delegates to `BannerRegistry.BlockedReason`, plus the `Reason` label falls back
to the countdown and three refusal codes were added to the `FRIENDLY` map. That is the whole diff.
It makes the screen MORE config-driven, which was B6's stated goal: **adding a banner type is now a
registry change and nothing else.** AD-UI review is a PENDING.

**THE `execute_luau` REQUIRE-CACHE HAZARD BIT, AND IS WORTH RECORDING AS EVIDENCE.** A pure-config
probe reported the registry had only `Standard` and that `IsSupported` was `nil` — while the same
probe confirmed the SOURCE was 13,466 bytes and contained both `IsSupported` and `BlockedReason`,
and that `EventFirstLight` required cleanly as an `Event` banner. The MCP's Luau VM had served a
**cached pre-edit copy** of the module. Nothing was wrong with the code. This is exactly what
CLAUDE.md warns about, and the fix was to stop probing and verify from a REAL Script, which is what
the rule says to do in the first place.

**Acceptance — verified LIVE in Play from temporary harnesses (server + client), since deleted.**

- Registry: both banners registered; `Validate` ok with only Standard's pre-existing Secret
  empty-pool note; `IsSupported` Standard/Event true, Selection false;
  `BlockedReason(Selection)` = *"Selection banners are coming soon"*.
- Curated pool: **7 ids, Farm excluded**.
- Window at synthetic times — before start → `NotStarted` *"Opens in 1h"*; exactly start → `Open`;
  mid → `Open` *"Ends in 15d"*; **exactly end → `Ended`** (boundary is exclusive, as intended);
  after → `Ended`. Standard (no window) → `Open`, never blocked.
- Featured: Standard hourly `Farm/Archer/Knight`, Event daily `Warchief/Necromancer`; two synthetic
  banners on the SAME period drew different sets, so the salt is doing its job. Daily flip at
  **16:00 UTC**.
- **The new banner FILE reached the summon screen with no UI registration work**: 2 cards incl.
  `Banner_EventFirstLight`, `ClosedOverlay.Visible = false`, `Reason` = *"Ends in 22d"*.
- Real pulls through the real remote: Event x1 (120 Gold) and x10 (1200 Gold, featured Warchief
  hit), Standard x1 unaffected.
- **Real refusals**: window forced ENDED → `banner_ended` while **Standard kept working**; forced
  NOT-STARTED → `banner_not_started` with `untilOpen=99992`; restored → OK again; unknown banner →
  `unknown_banner`. The harness mutated the SERVER VM's cached config only — the shipped file was
  confirmed intact at cleanup.

**Contract impact: NONE.** No schema bump, no shared module, no template. That was the point.

**Docs:** `docs/systems/gacha.md` was **stale** — it still said *"there is no gacha UI at all yet"*
three sessions after B6 built one. Corrected and brought current as part of this landing, since it
is AD-Gacha's doc. `places/lobby/CONTEXT.md` untouched (at its 150-line cap); STATE.md additions
paid for by compressing existing entries, per ADR-0006.

**PENDINGs: 1 NEW (the `BannerChoices` schema bump, which BLOCKS Selection), 1 amended (AD-UI to
review the `SummonController` delegation), 0 cleared.** Note for the standing `Data.Items` item:
B7's Event banner pays **Gold**, so it is still not the first writer.

**USER must republish the LOBBY** — B7, like everything since A7, is Studio canon and not in git.

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
