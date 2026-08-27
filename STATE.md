# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-27 (B39) -->
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
- **Shared canon** (`shared/manifest.json`): **35 entries = 28 modules + 7 templates**, drift-checked every session start AND end by
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
  **The live two-client v4 queue run is VERIFIED (user, B38)** — open since B23; do not re-raise it.
- **NOT A PENDING — ONE WRITER EACH, do not add a second:** `BannerChoiceService`→`BannerChoices` · `GrantService.SellUnits`→the only
  `Data.Units` delete · `UnitConsumeRules`= the ONE "may this be destroyed" rule · `UnitFlagsService`→`Favorited`/`Locked` ·
  `SettingsService`→`Data.Settings` · `DailyRewardService`→`LoginStreak`+`EventLoginStreaks` · `CodeService`→`RedeemedCodes` ·
  `PendingReveals`→`PendingReveals`. **`ChosenAtDay`, `LastClaimDayNumber` and every `RedeemedCodes` value are DAY NUMBERS.**
- **NOT A PENDING — B32/B33:** `UIKit.Sound` + `UIKit.Confirm` (2s gate); `Button` DETECTS panel vs flat; siblings use `optionalSibling`
  (10s+stub). `Remotes`=**27** (B39). `CurrencyChanged` is a server→client PING with **no payload** (a balance on the wire = a second source of
  truth beside ADR-0004's `GetUnitViews`), debounced by `GrantService`. **TOAST EVENTS, LABEL STATE.**
- **PENDING (USER, B32): PASTE THE 13 SOUND IDS** into `SoundService.{UI.*, BGM.*}` — the game is silent. **Also copy
  `StarterGui.ConfirmationPopupUI` into the GAME** (B26); till then `Confirm.ask` there auto-answers **NO**.
- **PENDING (USER, B32, art/layout):** `SellButtons.CancelButton` (x≈475) nearly overlaps `QuickSellButton` (x≈513); `PlayButton`
  still wears the **Shop** logo. **NOT a pending: the 0.05 `UIHoverStroke.Thickness` is DELIBERATE (user, B35) — do not re-raise.**
- **PENDING (USER, B33): the new `StarterGui.Summon` is UNFINISHED — do NOT touch.** `HUD.Right`'s `DailyRewardsButton` is WIRED (B38);
  `BattlePassButton` / `EventButton` are not.
- **PENDING (USER, B33, NOT built): nothing grants `Data.PlayerXP`,** so the ExpBar reads 0 forever — not its bug. Intent: small/wave,
  decent/stage clear, big FIRST clear; owner = the GAME's match-end path, and it MUST roll over via `PlayerLevelConfig.ApplyXP`.
- **PENDING (B33, balance): the XP curve may be too steep.** `100 × 1.15^(level-1)` → L50 = **627,540** (~12,500 stage clears) while
  `LoadoutConfig` gates slot 6 at L50. `PlayerLevelConfig` is **LOBBY-LOCAL**; promote it to shared the day the Game grants XP.
- **NOT A PENDING — B34:** `UIKit.Notify` + `UIKit.UnitCard` are canon. **The 334 bare `WaitForChild` were deliberately NOT swept** —
  the watchdog names hangs instead. `ui-feedback.md`.
- **PENDING (AD-Integration / USER, B34): C4 FEEDING IS BLOCKED ON DATA, NOT CODE** — `ItemCatalog` has no `FeedValue`, no unit XP
  curve, no writer for `UnitInstance.XP`. `docs/proposals/2026-08-20-c4-feeding.md`.
- **PENDING (AD-Game, B32): the GAME has no audio owner** — `UIKit.Sound` + the `SoundService` tree are deployed but nothing calls
  `playBGM(actId)`. Copy `LobbyAudio`'s shape; per-act slots exist.
- **NOT A PENDING — B37's PUSH PATH + B39's QUEUE. FULL DOC: `reward-push.md`.** **OPT-IN — `GrantService` NEVER pushes.** **Click →
  RETURN VALUE; server decided → `RewardPush`.** **B37's "grant made while AWAY" gap WAS MIS-STATED:** an offline player has no loaded
  profile, so `Grant` cannot write — *there is no offline grant to reveal*. B39 fixes the LEAVE-BETWEEN-GRANT-AND-PUSH race; **true
  offline delivery needs ProfileStore `MessageAsync`** and owns a grant path — do NOT improvise it in a reveal queue. **DRAINING MUST
  NEVER GRANT** (enumerated: zero `GrantService` refs on the drain path). The drain is a CLIENT-ANNOUNCED handshake because
  `FireClient` does not queue for a client that is not listening yet.
- **NOT A PENDING — B39 SHIPPED REDEEM CODES (server side).** **Every code is PUBLIC** (the registry replicates) — a code is a
  convenience, never a secret. **The rate limit is SECURITY** (1.5s, 20 failures/session): without it the remote enumerates the code
  space. Success and `already_redeemed` do NOT count as failures. `redeem-codes.md`.
- **NOT A PENDING — B39 SHIPPED THE EVENT DAILY TRACK.** `EventDailyConfig` is a DATE WINDOW, **not a banner** — coupling them would
  delete a ladder when a banner ends. `DailyRewardService` was extended **ADDITIVELY** so the deployed B38 controller kept working
  (verified live). Event ladders **do NOT wrap** at the last rung; missing a day still resets to 1. `daily-rewards.md`.
- **PENDING (AD-UI, features): Inbox / Quests / BattlePass / Event are still UNBUILT.** **PENDING (USER, B39): two SCREENS are the only
  thing left on DailyRewards and RedeemCodes — both servers are DONE and tested.** Specs: `docs/specs/2026-08-27-*.md`.
- **NOT A PENDING — B38 SHIPPED DAILY REWARDS.** **7-day cycle, MISS A DAY = RESET TO 1** (user); **table is PLACEHOLDER BALANCE**.
  **GRANT FIRST, MARK SECOND** (Grant can refuse, the mark cannot) — now the rule for daily, event AND codes. A claim is a CLICK, so it
  reveals via the RETURN VALUE, **not `RewardPush`**. `daily-rewards.md`.
- **PENDING (AD-Game, B24): `UnitIconV2` needs PLACEMENT COST + ELEMENT** (Game-only); prices are the template placeholder —
  `Motion.SHOW_PLACEHOLDER_PRICES=false` reverts both Places. **(AD-Traits)** `TraitDefinitions` has NO icon field.
- **PENDING (USER, design — B23): GAME SPEED IN A MATCHMADE MATCH** — match-wide; authority and the 3× gate come from an **elected
  stranger**. leave as-is · disable 3× · per-player.
- **PENDING (USER, balance):** `StartingLives` **3 / 15 / 10** across Acts 1–3 while `BaseHealthScale` climbs 1.0/1.6/2.4 — Act 1's `3`
  looks like a leftover test value. A design call.
- **NOT A PENDING — B35's UNIFIED SETTINGS, BOTH PLACES HASH-MATCHED** (`SettingsConfig` `5f0dc44d`, `SettingsService` `8b3b1a72`,
  `ClientSettings` `a3a9d32f`, `SettingsUI` `7e5a736a`) at IDENTICAL paths, so it cost ZERO consumer edits. `Scope`+`Kind`, never a
  branch. **`Sanitize` is Scope-BLIND ON PURPOSE** — one profile serves both Places. `settings.md`.
- **NOT A PENDING — B36: the Lobby settings screen is LIVE** (6 rows / 5 tabs vs the Game's 11, same file). **Tidy:** the dev profile
  still carries a dead `BannerChoices["B29ProbeBanner"]`.
- **NOT A PENDING — B36 FIXED THE WATCHDOG, WHICH HAD NEVER RUN. THE LESSON: testing a copy of the code in a MORE PRIVILEGED context
  is not testing the code** (`execute_luau` has plugin capability AND its own require cache — clone a module to exercise a fresh copy).
  Paired markers; **the start marker goes AFTER `--!strict`** or Luau silently drops strict mode. `ui-feedback.md`.
- **NOT A PENDING — B39 REPAIRED THAT DRIFT.** `UIKitBootstrap` `f930ff7b` → **`9c9539c0`** in repo + BOTH Places (B36 had marked only
  the Lobby's copy of a SHARED module). **Drift is 35/35 and was VERIFIED FIELD-BY-FIELD against the manifest** — comparing each live
  hash to both `hash` and `deployed.<Place>` is what caught it after two sessions of the same run "looking green". Do that, not a glance.
- **PENDING (AD-Game, B35): the Game's three settings ACTIONS have no handler** (`RestartMatch`/`ReturnToLobby`/`TeleportToSpawn` render
  disabled) — wire via `ClientSettings.RegisterAction(id, fn)`; `ReturnToLobby` must respect teleport v4, which is why it was left.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; till then its `MetaMath=MISSING` is EXPECTED.
  **(AD-Integration):** invariant 1 is **Lobby-only** — the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split; its hover race is FIXED (B29a), awaiting the user's fast-sweep confirmation to close.
- **PENDING (AD-Game, small):** `RewardScalingConfig`'s header comment is stale (a fix re-hashes `1d789978`) · a unit at
  `MAX_META_LEVEL` **loses stored XP** · promote `TowerProgressionConfig` to shared for per-unit XP.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration. `Data.Items`' only shipping writer is an **INSANE Victory** (B20).
- **NOT A PENDING — B28: `PlayGUI` is EXCLUDED from the open/close slide** (the veil would fight it). **KNOWN REGRESSION (B26, accepted):** V2 has no `ShinyBadge`.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (mid-roll ref) — two copies show equal numbers while GRADES differ (ADR-0003).
  `Data.Loadout` is dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).
- **Save schema v4** (B39) — `ProfileTemplate` **`8e4224b9`**, hash-matched BOTH Places. v3→v4 added `EventLoginStreaks` +
  `RedeemedCodes` + `PendingReveals` in **ONE bump** — the cost of a bump is the both-Places PUBLISH, not the field, so add a fourth
  field to v4 rather than opening v5. **`Migrations[2]` AND `[3]` are DELIBERATE NO-OPs and must stay ones** (`Reconcile()` runs BEFORE
  `Migrate()`); never delete one — `Migrate()` warns and STOPS at a missing step, stranding every later one. Store `Beta1_PlayerData`
  (Studio `Beta1_PlayerDataDev1`, API ON). **Forward-tolerant**, but publish both Places together anyway.
- **Teleport payload v4** (B23) — `docs/contracts/teleport.md`. Hard cutover, **v3 REJECTED**; v4 REPEALS
  "one party per match server" (P7 groups strangers). `LobbyConfig.MatchLaunchVersion` must ALWAYS equal
  `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** **LABEL COLLISION:** changelog `B0…B39` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK names
— same letters, different sequences. PlayGUI uses `P1…P7` to avoid a third.

1. **PLAYGUI — P1–P7 ✅ COMPLETE** (`docs/blueprints/playgui.md` is LAW; detail in `play-menu.md`). ADR-0011's remap is isolated in
   `PlayGUI.DifficultyScale` — **the ONE conversion.** HUD entry: `HUD.Left.Buttons.PlayButton`.
2. **Phase B** (`phases-b-f-meta.md`): B0–B8 + **B30 Selection ✅ → B4 COMPLETE.** **Phase C: C3
   COMPLETE** (ascension B9, **selling B31**); B11 moved ascension to an NPC screen (ADR-0010) —
   **C1/C2 copy that shape, selling deliberately did not** (blueprint C3 says "in Units screen").
   **C1+C2 are AD-TRAITS' and unblocked since B12.** Row-by-row: `docs/ROADMAP.md`.
