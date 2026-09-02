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
- **Shared canon** (`shared/manifest.json`): **36 entries = 29 modules + 7 templates**; B45 re-hashed `ItemCatalog`->**`9be86a5f`** + `RewardScalingConfig`->**`e0a3bc2d`**. Checked start AND end by
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
  `PendingReveals`→`PendingReveals` · `ShopService`→`ShopStock` · `QuestService`→`Quests` · `BattlepassService`→`Battlepass`. **Every stored day is a DAY NUMBER, never a
  timestamp** (`ChosenAtDay`, `LastClaimDayNumber`, `RedeemedCodes` values, `ShopStock.DayNumber`, quest `Progress[].Day`).
- **NOT A PENDING — B41, THE GAME PLACE CAUGHT UP.** The three settings ACTIONS are wired (`GameSettingsActions`; `ReturnToLobby`/
  `RestartMatch` go through `RequestMatchAction` so the SERVER keeps the teleport-v4 stamp — a client teleport would bypass the contract).
  The Game has an audio owner (`GameAudio`, per-act BGM off the new `MatchStateChanged.StageId`). **⚠ `MatchDirector.AbortMatch` PAYS
  NOTHING (USER, B41): `MatchEnded` is never fired, so no XP/gold/drops/counters and no result — deliberately NOT a Defeat, whose
  consolation would make the restart button farmable.** Restarting a live match aborts it first; the flag is consumed by the match LOOP,
  never the caller's thread.
- **B32/B33:** `UIKit.Sound` + `UIKit.Confirm` (2s gate); `Button` DETECTS panel vs flat; siblings use `optionalSibling` (10s+stub).
  `Remotes`=**36** (B47 +`GetLeaderboard`; B44 +`RerollTrait`/`RerollStats`). `CurrencyChanged` is a server→client PING with **no payload** (a balance on the wire = a second source of truth
  beside ADR-0004's `GetUnitViews`). **TOAST EVENTS, LABEL STATE.**
- **NOT A PENDING — DO NOT RE-RAISE (USER, B40): the empty SoundIds are DELIBERATE** — the user fills all 13 slots **at release**;
  silence in development is expected. Same standing class as the 0.05 `UIHoverStroke.Thickness`. **STILL UNCONFIRMED — ASK THE USER:
  `ConfirmationPopupUI` IS in the GAME** (23-descendant tree, every part `UIKit.Confirm` needs). B41's settings actions now CALL
  `Confirm.ask` there. Confirm the user copied it, then delete this line.
- **PENDING (USER, B32, art):** `SellButtons.CancelButton` nearly overlaps `QuickSellButton`; `PlayButton` wears the **Shop** logo.
- **PENDING (USER, B33): the new `StarterGui.Summon` is UNFINISHED — do NOT touch.**
- **NOT A PENDING — LEVELLING WORKS (B41).** `AddPlayerXP` applies `PlayerLevelConfig.ApplyXP` (SHARED CANON `2e99d041`) and writes BOTH
  fields; it is the ONE account-XP path. **`PlayerLevel` is authoritative; `PlayerXP` is progress WITHIN the level, NEVER a lifetime
  total.** **No migration and no v5** — `ApplyXP` self-heals a backlog on the next grant. **PENDING (USER, balance, B33):** L50 =
  **627,540** XP while `LoadoutConfig` gates slot 6 there.
- **B34:** `UIKit.Notify` + `UIKit.UnitCard` are canon; the 334 bare `WaitForChild` were deliberately NOT swept.
- **PENDING (AD-Integration / USER, B34): C4 FEEDING IS BLOCKED ON DATA, NOT CODE** — no `FeedValue`, no unit XP curve, no writer for
  `UnitInstance.XP`. `docs/proposals/2026-08-20-c4-feeding.md`.
- **NOT A PENDING — THE REVEAL LAYER (B37/B39/B40), `reward-push.md`.** **OPT-IN — `GrantService` NEVER pushes. Click → RETURN VALUE;
  server decided → `RewardPush`. DRAINING MUST NEVER GRANT.** Drain needs client-announced AND profile-loaded, either order.
- **NOT A PENDING — REDEEM CODES (B39/B40).** **Every code is PUBLIC** (the registry replicates) — never a secret. **The rate limit is
  SECURITY**: without it the remote enumerates the code space. `redeem-codes.md`.
- **NOT A PENDING — B39's EVENT TRACK: `EventDailyConfig` is a DATE WINDOW, not a banner**; extended ADDITIVELY.
- **NOT A PENDING — B40's FOUR SYSTEMS.** Docs: `reward-push.md`, `shop.md`, `quests.md`, `daily-rewards.md`. Rules that bite: **specs
  are the CONTRACT** · **HUD button names END IN `Button`** · **MAIL: GRANT FIRST, THEN `processed()`** — same save, which makes
  at-least-once deliver exactly once; reveal via **`ToOrQueue`** · **SHOP is the FIRST Silver sink**, stock DERIVED, **PRE-CHECK → SPEND →
  GRANT → MARK**, **client sends a slot INDEX, never a price** · **QUESTS = a DELTA vs a baseline.**
- **B42 (AD-GACHA/AD-UI): QUESTS, SHOP and BATTLEPASS screens are live**, all BLOCKOUT to specs (`docs/specs/2026-08-28-*`; specs are the
  CONTRACT, re-author = zero code). QUESTS: B41's one-line edit LANDED (`Clears` + `InsaneVictories` in `LiveCounters`; **`ClearThree` reads
  `Clears`, NOT `ActsCleared`**), 6/6 assignable, 0 orphans. SHOP: **NPC-opened** (ADR-0010 shape), buy verified live. BATTLEPASS backend +
  screen, Remotes 31→33; **XP source LANDED B43** (below), **monetization still pending**. **PENDING (AD-UI):** `Inbox` needs a
  backend (a v5 field). `LeaderBoards` backend LANDED B47 (global level board, `leaderboards.md`).
- **NOT A PENDING — B45: A DROP IS ROUTED BY ITS CATALOGUE `Kind`, never assumed to be an Item.** A CURRENCY lives in
  `Data.Currencies[id]`, not `Data.Items[id]` — routing it wrong puts it where nothing reads it and the faucet merely LOOKS wired.
  **An uncatalogued drop id is refused loudly and written NOWHERE** (invariant 4's stance). **`StatRerolls` is catalogued + drops from
  Insane wins** — C2's faucet, the same one `TraitRerollToken` uses. ⚠ `PlayerInventoryService.SCALAR_CURRENCIES` is MIRRORED from
  `GrantService`'s and CANNOT be shared across Places — **add a scalar currency and BOTH lists must learn it.** Icon is a PLACEHOLDER
  `rbxassetid://0` (USER). `Currencies.TraitRerolls` is a DEAD field. `rewards.md`.
- **NOT A PENDING — B43: THE BATTLEPASS IS A REAL LOOP.** `RewardCalculator` (compute + ACCUMULATE, never grant) ->
  `MatchReturn.BattlepassXP` -> `MatchReturnService` -> `BattlepassAddXP` -> `BattlepassService`, **which stays the ONE writer of
  `Data.Battlepass`.** Rule = Game-local `BattlepassXpConfig` (PLACEHOLDER: 50 + 5/wave, loss x0.4, x1.0-2.0 via the ONE `TFromWire`);
  Abandoned pays NOTHING (B41's rule). **`MatchReturnService` is no longer strictly display-only** — it applies this ONE thing and must
  never write the field. **GUARDED BOTH ENDS:** Game clears only after `TeleportAsync` SUCCEEDS; Lobby applies ONCE per join and only after
  `WaitForData` (**`PlayerAdded` fires BEFORE the profile loads** — that silently refused every grant until it was run). `teleport.md`.
- **B43: the in-match hotbar draws REAL LOCKS** -- `LoadoutAssigned` carries `PlayerLevel` (server-read). It exposed an upstream bug (**FIXED B44**): the Lobby's auto-loadout FALLBACK (`LaunchService.BuildLoadout`, used when `Data.Loadout` is empty) filled to `MaxLoadoutSize` ignoring `LoadoutConfig` unlocks. Now capped to `LoadoutConfig.UnlockedSlots(PlayerLevel)` (verified L1 8-owned -> 3); the saved-Loadout path was already unlock-respecting.
- **NOT A PENDING — DAILY REWARDS (B38/B39/B40).** **7-day cycle, MISS A DAY = RESET TO 1**; event ladders do NOT wrap. **GRANT FIRST, MARK SECOND** — the rule for daily, event, codes, shop AND quests. `daily-rewards.md`.
- **PENDING (AD-Game, B24):** `UnitIconV2` needs PLACEMENT COST + ELEMENT; **(AD-Traits)** `TraitDefinitions` has NO icon field.
- **PENDING (USER, design — B23): GAME SPEED IN A MATCHMADE MATCH** — authority and the 3× gate come from an **elected stranger**.
- **PENDING (USER, balance):** `StartingLives` **3 / 15 / 10** across Acts 1–3 — Act 1's `3` looks like a leftover test value.
- **NOT A PENDING — B35's UNIFIED SETTINGS, BOTH PLACES HASH-MATCHED**, at IDENTICAL paths, which is why it cost ZERO consumer edits. `Scope`+`Kind`, never a branch. **`Sanitize` is Scope-BLIND ON PURPOSE** — one profile serves both Places. `settings.md`.
- **B36: the Lobby settings screen is LIVE.** **Tidy (USER):** the dev profile carries a dead `BannerChoices["B29ProbeBanner"]`.
- **NOT A PENDING — B36's LESSON:** `execute_luau` has plugin capability AND its own require cache — **clone a module to exercise a fresh copy**, and prove behaviour from a REAL Script. **The boot marker goes AFTER `--!strict`** or Luau silently drops strict mode.
- **B39 REPAIRED B36's `UIKitBootstrap` DRIFT** (→ `9c9539c0`). Comparing each live hash to BOTH `hash` AND `deployed.<Place>` **in code** is what caught it after two sessions of "looking green" — B41 and B43 both ran that way, 36/36.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`. **Invariant 1 is Lobby-only.**
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split (hover race FIXED B29a; awaiting confirmation).
- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses stored XP** · promote `TowerProgressionConfig` to shared for per-unit XP.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration. `Data.Items`' only writer is an **INSANE Victory**.
- **B28:** `PlayGUI` is EXCLUDED from the slide (the veil fights it). **KNOWN REGRESSION (B26):** V2 has no `ShinyBadge`.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (ADR-0003) — two copies show equal numbers while GRADES differ. `Data.Loadout` is dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).
- **Save schema v4** (B39, PUBLISHED B40) — `ProfileTemplate` **`8e4224b9`**, hash-matched BOTH Places. **v4 IS SHIPPED, so a new field now costs v5.** **`Migrations[2]` AND `[3]` are DELIBERATE NO-OPs and must stay ones** (`Reconcile()` runs BEFORE `Migrate()`); never delete one — `Migrate()` warns and STOPS at a missing step, stranding every later one. Store `Beta1_PlayerData` (Studio `Beta1_PlayerDataDev1`, API ON).
- **Teleport payload v4** (B23) — `docs/contracts/teleport.md`. Hard cutover, **v3 REJECTED**. `LobbyConfig.MatchLaunchVersion` must ALWAYS equal `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** **LABEL COLLISION:** changelog `B0…B40` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK names
— same letters, different sequences. PlayGUI uses `P1…P7` to avoid a third.

1. **PLAYGUI — P1–P7 ✅ COMPLETE** (`playgui.md` is LAW). ADR-0011's remap is isolated in `PlayGUI.DifficultyScale` — **the ONE conversion.**
2. **Phase B** (`phases-b-f-meta.md`): B0–B8 + **B30 Selection ✅ → B4 COMPLETE.** **Phase C: DONE** — ascension B9 + selling B31 (C3),
   trait reroll C1 + stat reroll C2 B44 (`trait-reroll.md`/`stat-reroll.md`), all NPC-opened (ADR-0010). C1 spends the `TraitRerollToken` ITEM;
   C2 spends `Currencies.StatRerolls` — **FAUCET B45 (Insane) + EVERYDAY SOURCES B46** (daily/shop/BP-free/quest; `economy-map.md`), floors at grade A at Worthiness 100.
   **⚠ THE WORTHINESS METER WAS NEVER MISSING** — `CommitUnitKills`→`WorthinessConfig.Apply` has run since A8, verified at A8 AND A9.
   Reaching 100 is TUNING, not a gap: `PointsPerKill` 0.02 (user's call, reaffirmed B45) = ~5,000 kills, ~25-50 matches for a favourite.
3. **B41 CLEARED THE GAME-PLACE BLOCKER** (levelling, the counters, the settings actions, the audio owner). What the Lobby's meta layer
   now waits on is **UI**, not the match: Shop/Quests/BattlePass screens all shipped B42 (BattlePass + Daily Rewards then re-laid-out to the user's UI reference, Image-based frames); Inbox still needs a backend (LeaderBoards landed B47); BattlePass needs only monetization now (B43 landed its XP source). Mostly AD-UI's, not AD-Game's.
