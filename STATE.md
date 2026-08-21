# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-20 (B35) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop as a two-Place vertical
slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/summons, progression +
match-end rewards, **ProfileStore persistence (schema v3)**, a shared UI kit + **audio/confirm layer**,
and the gacha engine (Standard + Event + Selection banners; ascension AND selling dupes both live).

- **Game** — the match Place; `MatchEntryService` is the production entry. Owns tower configs,
  combat, the stat resolver, match runtime. Detail: `places/game/CONTEXT.md`.
- **Lobby** — the social/meta Place, scene `Workspace.Lobby`. **`GetUnitViews` is its SINGLE profile
  read path** (ADR-0004); **`GrantService` is its SINGLE grant/spend path**. `places/lobby/CONTEXT.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`): **35 entries
  = 28 modules + 7 templates** (B34 `UIKitNotify`+`UIKitUnitCard`; B35 the four SETTINGS modules). **BOTH
  Places drift-green on all 35 except `MetaMath`** (re-verified every session start AND end), which is
  PRESENT in the Lobby and MISSING in the Game — EXPECTED, not drift; it stays Lobby-only until Phase D. **B26 adopted the V2 UI kit in BOTH
  Places and RETIRED `Kit_UnitIcon`/`Kit_ItemIcon`/`Kit_HotbarSlot`** (dropped from
  `hash_shared.luau` — do not re-add). Templates hash as INSTANCE trees, no `shared/src` file
  (ADR-0005).

**DRIFT RULE (everyone):** editing a shared controller **or a template** in one Place only is DRIFT.
Change → re-hash → copy to the other Place → update the manifest. **Copying a TEMPLATE across Places
is a USER action** (B26) — pause and ask. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **NOT A PENDING — STANDING PRACTICE (B25): the user republishes BOTH Places EVERY session.** Only *state* it when a contract bumps.
  Still unconfirmed: a **live two-client v4 queue run** (403 in Studio).
- **NOT A PENDING — ONE WRITER EACH, do not add a second:** `BannerChoiceService`→`BannerChoices` (Selection banners live, B30, B4 ✅) ·
  `GrantService.SellUnits`→the only `Data.Units` delete (C3 ✅, B31) · **`UnitConsumeRules`= the ONE "may this be destroyed" rule**
  (ascension delegates) · `UnitFlagsService`→`Favorited`/`Locked` (B32). `ChosenAtDay` is a DAY NUMBER, never a timestamp. Docs:
  `docs/systems/{gacha-selection,ascension,ui-feedback}.md`.
- **NOT A PENDING — B32/B33:** `UIKit.Sound` + `UIKit.Confirm` (2s gate); `Button` DETECTS panel vs flat; siblings use `optionalSibling`
  (10s+stub). `Remotes`=**22** (B35 added the `Settings` folder). `CurrencyChanged` is a server→client PING with **no payload** (a balance
  on the wire = a second source of truth beside ADR-0004's `GetUnitViews`), fired debounced by `GrantService`. **Toast rule: TOAST EVENTS,
  LABEL STATE** — toasts self-erase at 3.5s, so conditions stay on their label.
- **PENDING (USER, B32): PASTE THE 13 SOUND IDS** into `SoundService.{UI.*, BGM.*}` — all empty, the game is silent. **Also copy
  `StarterGui.ConfirmationPopupUI` into the GAME** (B26: art cannot be scripted); till then `Confirm.ask` there auto-answers **NO**.
- **PENDING (USER, B32, art/layout):** `SellButtons.CancelButton` (x≈475) nearly overlaps `QuickSellButton` (x≈513), and `PlayButton`
  still wears the **Shop** logo. **NOT a pending: the 0.05 `UIHoverStroke.Thickness` is DELIBERATE** — the user reviewed it at B35 and
  said leave it. Do not "fix" it, and do not re-raise it.
- **PENDING (USER, B33): the new `StarterGui.Summon` is UNFINISHED — do NOT touch.** It replaces `SummonScreen` when the user says so.
  `HUD.Right` gained `BattlePassButton` / `EventButton` / `DailyRewardsButton` (renamed at their request) — **none are wired.**
- **PENDING (USER, B33, their design, NOT built): nothing grants `Data.PlayerXP`,** so the ExpBar reads 0 forever and that is not its bug.
  Intent: small/wave, decent/stage clear, big FIRST clear, smaller repeats; owner = the GAME's match-end path, and it MUST roll over via
  `PlayerLevelConfig.ApplyXP`.
- **PENDING (B33, balance): the curve may be too steep.** User's pick `100 × 1.15^(level-1)` → level 5 = **490** XP, 20 = **8,830**, 50 =
  **627,540** (~12,500 stage clears) while `LoadoutConfig` gates slot 6 at level 50. Three numbers retune it. `PlayerLevelConfig` is
  **LOBBY-LOCAL on purpose** (the Game reads no curve); **promote it to shared the day the Game grants XP** or the Places will disagree.
- **NOT A PENDING — B34:** `UIKit.Notify` + `UIKit.UnitCard` are canon (old copies retired `*_RETIRED_2026-08-20`). **The 334 bare
  `WaitForChild` were deliberately NOT swept** — instead every boot script sets `BootComplete` and **`ScreenBootWatchdog`** NAMES whatever
  never finished, because B33's real defect was SILENCE, not a missing timeout. Rationale: `ui-feedback.md`.
- **PENDING (AD-Integration / USER, B34): C4 FEEDING IS BLOCKED ON DATA, NOT CODE** — `docs/proposals/2026-08-20-c4-feeding.md`.
  `ItemCatalog` has NO `FeedValue`, there is no unit XP curve and no writer for `UnitInstance.XP`. Needs food items + a curve + a decision
  on how food is obtained (nothing grants items today but an INSANE victory). Every piece of machinery it reuses already exists.
- **PENDING (AD-Game, B32): the GAME has no audio owner.** `UIKit.Sound` + the `SoundService` tree are deployed there but nothing calls
  `playBGM(actId)`. Copy `LobbyAudio`'s shape; per-act slots exist.
- **PENDING (AD-UI, design): quests/login/codes still need a reveal answer** — `ShowRewards`' return-value trick only serves
  player-INITIATED grants; B33's toasts are a *message* surface, not a reveal. Propose. **(B35 note: `HUD.Right.UpperRight` now has
  `RedeemCodes`/`LeaderBoards`/`InviteFriends`/`Inbox` buttons, tagged and styled but UNWIRED — the same reveal question gates them.)**
- **PENDING (AD-Game, B24): `UnitIconV2` needs PLACEMENT COST + ELEMENT** (Game-only). Prices are TEMPORARILY the template placeholder —
  `Motion.SHOW_PLACEHOLDER_PRICES=false` reverts both Places. **(AD-Traits): `TraitDefinitions` has NO icon field.** Proposals:
  `2026-08-16-{tower-display-fields-for-uniticon-v2,trait-icons}.md`.
- **PENDING (USER, design — B23): GAME SPEED IN A MATCHMADE MATCH** — match-wide, and both the authority and the 3× gate come from an
  **elected stranger**. leave as-is · disable 3× · per-player.
- **PENDING (USER, balance):** `StartingLives` **3 / 15 / 10** across Acts 1–3 while `BaseHealthScale` climbs 1.0/1.6/2.4 — Act 1's `3`
  looks like a leftover test value. A design call.
- **NOT A PENDING — B35 SHIPPED THE UNIFIED SETTINGS SYSTEM, BOTH PLACES HASH-MATCHED.** 4 new shared entries at IDENTICAL paths in
  both Places (`SettingsConfig` `5f0dc44d`, `SettingsService` `8b3b1a72`, `ClientSettings` `a3a9d32f`, `SettingsUI` `8e899dab`), so it
  cost ZERO consumer edits. Entries declare **`Scope`** (`Both`/`GameOnly`/`LobbyOnly`) + **`Kind`** (`Preference`/`Action`) — a Place
  difference is a config field, never a branch (Game 11 rows, Lobby 6). **`Sanitize` is Scope-BLIND ON PURPOSE:** one profile serves
  both Places, so dropping out-of-scope keys would permanently lose the other Place's prefs. NO schema bump. Doc: `settings.md`.
- **PENDING (USER, B35): copy `StarterGui.Settings` into the LOBBY** (B26: art is a user action). Everything else is deployed and waiting
  — until it lands, `SettingsUI` warns once and stands down, so the Lobby has no settings screen. **Tidy:** the dev profile still carries
  a dead `BannerChoices["B29ProbeBanner"]`.
- **PENDING (AD-Game, B35): the Game's three settings ACTIONS have no handler** (`RestartMatch`/`ReturnToLobby`/`TeleportToSpawn` render
  disabled) — wire via `ClientSettings.RegisterAction(id, fn)`; `ReturnToLobby` must respect teleport v4, which is why it was left.
- **PENDING (AD-Meta at Phase D):** deploy `MetaMath` to the GAME + flip `deployed.Game`; till then its `MetaMath=MISSING` is EXPECTED.
  **(AD-Integration):** invariant 1 is **Lobby-only** — the Game still grants via `PlayerInventoryService`/`RewardCalculator`.
- **PENDING (AD-UI, small):** `Kit_ItemHoverCard`'s master/clone split; its hover race is FIXED (B29a), awaiting the user's fast-sweep
  confirmation to close. *(The "four inline `UnitIconV2` consumers" pending was RESOLVED at B34 by `UIKit.UnitCard`.)*
- **PENDING (AD-Game, small):** `RewardScalingConfig`'s header comment is stale (a fix re-hashes `1d789978`) · a unit at `MAX_META_LEVEL`
  **loses stored XP** · **(AD-PlayerLevel)** promote `TowerProgressionConfig` to shared for per-unit XP.
- **PENDING (Game):** the `ServerStorage.Documentation` → `docs/systems/` migration. **PENDING:** `Data.Items`' only shipping writer is an
  **INSANE Victory** (B20) — counts stay 0 till then.
- **NOT A PENDING — B28: `PlayGUI` is EXCLUDED from the open/close slide** (a `LoadingScreen` veil would fight it). **KNOWN REGRESSION
  (B26, accepted):** V2 has no `ShinyBadge` — shiny is unmarked on an ascension card; re-add or drop it deliberately.
- **NOT a bug:** Units stat NUMBERS are per-TOWER (mid-roll ref), so two copies show equal numbers while GRADES differ (ADR-0003).
  `Data.Loadout` is dense. Difficulty: UI 1–100, wire 100–1000 (ADR-0011).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v3** (B29) — `ProfileTemplate` `72d3944f`, drift-green BOTH Places. Store
  `Beta1_PlayerData` (Studio `Beta1_PlayerDataDev1`, API access ON). **`Migrations[2]` is a deliberate
  NO-OP and must stay one** — `Migrate()` warns and STOPS at a missing step, stranding every later one.
  **Forward-tolerant** (Reconcile never prunes), but publish both Places together anyway.
- **Teleport payload v4** (B23) — `docs/contracts/teleport.md`. Hard cutover, **v3 REJECTED**; v4 REPEALS
  "one party per match server" (P7 groups strangers). `LobbyConfig.MatchLaunchVersion` must ALWAYS equal
  `GameConfig.TeleportPayloadVersion`.

## Next up

**✅ PHASE A SIGNED OFF (A9).** `phase-a-foundations.md` is history; detail in CHANGELOG.
**LABEL COLLISION:** changelog `B0…B26` are SESSION COUNTERS; blueprint `B1…B5` are SESSION-TASK
names — same letters, different sequences. PlayGUI uses `P1…P7` to avoid a third collision.

1. **USER** — a **live two-client** run of the v4 queue (the republish itself is standing practice).
2. **PLAYGUI — P1–P7 ✅ COMPLETE, needs nothing further** (`docs/blueprints/playgui.md` is LAW; detail in
   `play-menu.md`). ADR-0011's remap is isolated in `PlayGUI.DifficultyScale` — **the ONE conversion.**
   Its HUD entry is `HUD.Left.Buttons.PlayButton` (B32 rename; the old `Play` was gone).
3. **Phase B** (`phases-b-f-meta.md`): B0–B8 + **B30 Selection ✅ → B4 COMPLETE.** **Phase C: C3
   COMPLETE** (ascension B9, **selling B31**); B11 moved ascension to an NPC screen (ADR-0010) —
   **C1/C2 copy that shape, selling deliberately did not** (blueprint C3 says "in Units screen").
   **C1+C2 are AD-TRAITS' and unblocked since B12.** Row-by-row: `docs/ROADMAP.md`.
