# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-27 (B40) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop as a two-Place vertical
slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons, progression +
match-end rewards, **ProfileStore persistence (schema v4)**, a shared UI kit + **audio/confirm layer**,
and the gacha engine (Standard + Event + Selection banners; ascension AND selling dupes both live).

- **Game** — the match Place; `MatchEntryService` is the production entry. Owns tower configs,
  combat, the stat resolver, match runtime. Detail: `places/game/CONTEXT.md`.
- **Lobby** — the social/meta Place, scene `Workspace.Lobby`. **`GetUnitViews` is its SINGLE profile
  read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**. `places/lobby/CONTEXT.md`.
- **Shared canon** (`shared/manifest.json`): **36 entries = 29 modules + 7 templates** (B41 promoted `PlayerLevelConfig`), checked start AND end by
  `ServerStorage.DevTools.HashShared` in each Place (two lines to run) — **compare each live hash to BOTH `hash` and `deployed.<Place>`,
  field by field; a glance missed real drift for two sessions.** `MetaMath` is Lobby-only until Phase D: **EXPECTED, not drift.** B26
  adopted the V2 kit in BOTH Places and RETIRED `Kit_UnitIcon`/`Kit_ItemIcon`/`Kit_HotbarSlot` (do not re-add). Templates hash as
  INSTANCE trees, no `shared/src` file (ADR-0005).

**DRIFT RULE (everyone):** editing a shared controller **or a template** in one Place only is DRIFT.
Change → re-hash → copy to the other Place → update the manifest. **Copying a TEMPLATE across Places
is a USER action** (B26) — pause and ask. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **NOT A PENDING — STANDING PRACTICE (B25): the user republishes BOTH Places EVERY session.** Only *state* it when a contract bumps.
  **Schema v4 IS PUBLISHED to both Places (user, B40).** **The live two-client v4 queue run is VERIFIED (user, B38)** — do not re-raise.
- **NOT A PENDING — THE PATTERN B38-B40 ALL USED:** a pure `*Config`/`*Registry` (rules; per-day state DERIVED from
  `MetaMath.Slot`/`RngForSlot`, never stored) + ONE service owning the remote, the grant and the write. **Check whether the profile
  field ALREADY EXISTS before designing** — `LoginStreak`/`Quests`/`ShopStock`/`Battlepass` were all in the schema since v2 unwritten,
  which made three bumps unnecessary. Still unwritten: **`Titles`, `Battlepass`**.
- **NOT A PENDING — ONE WRITER EACH, do not add a second:** `BannerChoiceService`→`BannerChoices` · `GrantService.SellUnits`→the only
  `Data.Units` delete · `UnitConsumeRules`= the ONE "may this be destroyed" rule · `UnitFlagsService`→`Favorited`/`Locked` ·
  `SettingsService`→`Settings` · `DailyRewardService`→`LoginStreak`+`EventLoginStreaks` · `CodeService`→`RedeemedCodes` ·
  `PendingReveals`→`PendingReveals` · `ShopService`→`ShopStock` · `QuestService`→`Quests`. **Every stored day is a DAY NUMBER, never a
  timestamp** (`ChosenAtDay`, `LastClaimDayNumber`, `RedeemedCodes` values, `ShopStock.DayNumber`, quest `Progress[].Day`).
- **NOT A PENDING — B41, THE GAME PLACE CAUGHT UP.** The three settings ACTIONS are wired (`GameSettingsActions`; `ReturnToLobby`/
  `RestartMatch` go through `RequestMatchAction` so the SERVER keeps the teleport-v4 stamp — a client teleport would bypass the contract).
  The Game has an audio owner (`GameAudio`, per-act BGM off the new `MatchStateChanged.StageId`). **⚠ `MatchDirector.AbortMatch` PAYS
  NOTHING (USER, B41): `MatchEnded` is never fired, so no XP/gold/drops/counters and no result — deliberately NOT a Defeat, whose
  consolation would make the restart button farmable.** Restarting a live match aborts it first; the flag is consumed by the match LOOP,
  never the caller's thread.
- **NOT A PENDING — B32/B33:** `UIKit.Sound` + `UIKit.Confirm` (2s gate); `Button` DETECTS panel vs flat; siblings use `optionalSibling`
  (10s+stub). `Remotes`=**31** (B40). `CurrencyChanged` is a server→client PING with **no payload** (a balance on the wire = a second
  source of truth beside ADR-0004's `GetUnitViews`). **TOAST EVENTS, LABEL STATE.**
- **NOT A PENDING — DO NOT RE-RAISE (USER, B40): the empty SoundIds are DELIBERATE** — the user fills all 13 slots **at release**;
  silence in development is expected. Same standing class as the 0.05 `UIHoverStroke.Thickness`. **STILL UNCONFIRMED — ASK THE USER:
  `ConfirmationPopupUI` IS in the GAME** (23-descendant tree, every part `UIKit.Confirm` needs). B41's settings actions now CALL
  `Confirm.ask` there. Confirm the user copied it, then delete this line.
- **PENDING (USER, B32, art):** `SellButtons.CancelButton` nearly overlaps `QuickSellButton`; `PlayButton` wears the **Shop** logo.
- **PENDING (USER, B33): the new `StarterGui.Summon` is UNFINISHED — do NOT touch.**
- **NOT A PENDING — LEVELLING WORKS (B41).** `AddPlayerXP` applies `PlayerLevelConfig.ApplyXP` and writes BOTH fields; it is the ONE
  account-XP path. **`PlayerLevel` is authoritative; `PlayerXP` is progress WITHIN the level, NEVER a lifetime total.** `PlayerLevelConfig`
  is SHARED CANON (`2e99d041`, **36 entries**). **No migration and no v5:** `ApplyXP` drains a pre-B41 backlog on the next grant and is a
  no-op on a consistent profile (verified L1/5000xp → L16/240xp, conserving exactly). **PENDING (USER, balance, B33):** L50 = **627,540**
  XP while `LoadoutConfig` gates slot 6 there.
- **B34:** `UIKit.Notify` + `UIKit.UnitCard` are canon; the 334 bare `WaitForChild` were deliberately NOT swept.
- **PENDING (AD-Integration / USER, B34): C4 FEEDING IS BLOCKED ON DATA, NOT CODE** — no `FeedValue`, no unit XP curve, no writer for
  `UnitInstance.XP`. `docs/proposals/2026-08-20-c4-feeding.md`.
- **NOT A PENDING — THE REVEAL LAYER (B37/B39/B40). FULL DOC: `reward-push.md`.** **OPT-IN — `GrantService` NEVER pushes. Click → RETURN
  VALUE; server decided → `RewardPush`. DRAINING MUST NEVER GRANT.** The drain needs client-announced AND profile-loaded, either order.
- **NOT A PENDING — REDEEM CODES (B39/B40).** **Every code is PUBLIC** (the registry replicates) — never a secret. **The rate limit is
  SECURITY**: without it the remote enumerates the code space. `redeem-codes.md`.
- **NOT A PENDING — B39's EVENT TRACK: `EventDailyConfig` is a DATE WINDOW, not a banner**; extended ADDITIVELY.
- **NOT A PENDING — B40's FOUR SYSTEMS.** (a) **The two screens are BLOCKOUT ART I scripted** to the published specs (user reversed
  "you author it"); the specs stay the CONTRACT, so replacing the art costs ZERO code. **`DailyRewardsButton` OPENS the screen now —
  it no longer claims.** **HUD button names all END IN `Button`** (B40 lost a live run on that). (b) **MAIL closes B37's gap for real**
  via ProfileStore `MessageAsync` — no remote, no schema field, no shared-canon edit. **GRANT FIRST, THEN `processed()`**: both persist
  in the SAME save, which is what makes at-least-once deliver exactly once. Reveal via **`ToOrQueue`** — mail often reaches someone who
  IS online. (c) **SHOP is the game's FIRST Silver sink** (verified: nothing spent it, B31 mints it). Stock DERIVED, never stored;
  **PRE-CHECK → SPEND → GRANT → MARK**; **the client sends a slot INDEX, never a price.** (d) **QUESTS measure a DELTA against a
  baseline** taken at assignment, written ONCE per quest per day. Docs: `reward-push.md`, `shop.md`, `quests.md`, `daily-rewards.md`.
- **B42 (AD-GACHA/AD-UI): the QUESTS SCREEN is live** — `StarterGui.QuestsGUI` + `QuestsController`, BLOCKOUT to
  `docs/specs/2026-08-28-quests-screen.md` (spec is the CONTRACT, re-author = zero code). The B41 one-line edit LANDED: `Clears` +
  `InsaneVictories` in `QuestRegistry.LiveCounters`, `ClearThree` reads **`Clears`** (NOT `ActsCleared`), `WinInsane` shipped — 6 assignable,
  0 orphans, claim verified live (PullOne → Silver x120). **PENDING (AD-UI): SHOP has no UI** (blueprint wants an NPC);
  `BattlePass`/`Event`/`LeaderBoards`/`InviteFriends`/`Inbox` unwired. **Inbox as a SCREEN needs a v5 field.**
- **NOT A PENDING — DAILY REWARDS (B38/B39/B40).** **7-day cycle, MISS A DAY = RESET TO 1**; event ladders do NOT wrap. **GRANT FIRST,
  MARK SECOND** — the rule for daily, event, codes, shop AND quests. `daily-rewards.md`.
- **PENDING (AD-Game, B24):** `UnitIconV2` needs PLACEMENT COST + ELEMENT; **(AD-Traits)** `TraitDefinitions` has NO icon field.
- **PENDING (USER, design — B23): GAME SPEED IN A MATCHMADE MATCH** — authority and the 3× gate come from an **elected stranger**.
- **PENDING (USER, balance):** `StartingLives` **3 / 15 / 10** across Acts 1–3 — Act 1's `3` looks like a leftover test value.
- **NOT A PENDING — B35's UNIFIED SETTINGS, BOTH PLACES HASH-MATCHED**, at IDENTICAL paths, which is why it cost ZERO consumer edits.
  `Scope`+`Kind`, never a branch. **`Sanitize` is Scope-BLIND ON PURPOSE** — one profile serves both Places. `settings.md`.
- **B36: the Lobby settings screen is LIVE.** **Tidy (USER):** the dev profile carries a dead `BannerChoices["B29ProbeBanner"]`.
- **NOT A PENDING — B36's LESSON:** `execute_luau` has plugin capability AND its own require cache — **clone a module to exercise a fresh
  copy**, and prove behaviour from a REAL Script. **The boot marker goes AFTER `--!strict`** or Luau silently drops strict mode.
- **NOT A PENDING — B39 REPAIRED B36's `UIKitBootstrap` DRIFT** (→ **`9c9539c0`**). Comparing each live hash to BOTH `hash` and
  `deployed.<Place>` **in code** is what caught it after two sessions of "looking green". B41 ran the same way: **36/36, 0 issues.**
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`. **Invariant 1 is Lobby-only.**
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split (hover race FIXED B29a; awaiting confirmation).
- **PENDING (AD-Game, small):** `RewardScalingConfig`'s header comment is stale (a fix re-hashes `1d789978`; B41 fixed the DUPLICATE of
  that claim in `RewardCalculator`, which is not canon) · a unit at `MAX_META_LEVEL` **loses stored XP** · promote `TowerProgressionConfig`.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration. `Data.Items`' only writer is an **INSANE Victory**.
- **B28:** `PlayGUI` is EXCLUDED from the slide (the veil fights it). **KNOWN REGRESSION (B26):** V2 has no `ShinyBadge`.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (ADR-0003) — two copies show equal numbers while GRADES differ. `Data.Loadout` is
  dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).
- **Save schema v4** (B39, PUBLISHED B40) — `ProfileTemplate` **`8e4224b9`**, hash-matched BOTH Places. **v4 IS SHIPPED, so a new field
  now costs v5** — no more free additions. **`Migrations[2]` AND `[3]` are DELIBERATE NO-OPs and must stay ones** (`Reconcile()` runs
  BEFORE `Migrate()`); never delete one — `Migrate()` warns and STOPS at a missing step, stranding every later one. Store
  `Beta1_PlayerData` (Studio `Beta1_PlayerDataDev1`, API ON). **Forward-tolerant**, but publish both Places together anyway.
- **Teleport payload v4** (B23) — `docs/contracts/teleport.md`. Hard cutover, **v3 REJECTED**. `LobbyConfig.MatchLaunchVersion` must
  ALWAYS equal `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** **LABEL COLLISION:** changelog `B0…B40` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK names
— same letters, different sequences. PlayGUI uses `P1…P7` to avoid a third.

1. **PLAYGUI — P1–P7 ✅ COMPLETE** (`playgui.md` is LAW). ADR-0011's remap is isolated in `PlayGUI.DifficultyScale` — **the ONE conversion.**
2. **Phase B** (`phases-b-f-meta.md`): B0–B8 + **B30 Selection ✅ → B4 COMPLETE.** **Phase C: C3 COMPLETE** (ascension B9, selling B31);
   B11 moved ascension to an NPC screen (ADR-0010) — **C1/C2 copy that shape, selling deliberately did not.** **C1+C2 are AD-TRAITS' and
   unblocked since B12.** Row-by-row: `docs/ROADMAP.md`.
3. **B41 CLEARED THE GAME-PLACE BLOCKER** (levelling, the counters, the settings actions, the audio owner). What the Lobby's meta layer
   now waits on is **UI**, not the match: Shop has no screen (Quests shipped B42), and five HUD buttons are unwired. That is AD-UI's, not AD-Game's.
