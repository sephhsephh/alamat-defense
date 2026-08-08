# STATE — Alamat Defense
<!-- owner: all | scope: global | last-verified: 2026-08-06 (A7) -->
<!-- SIZE RULE (ADR-0006): ONE file, cap 120 lines. A RESOLVED pending is DELETED (the changelog
     is its record) -- never struck through. Sections that duplicate a canon doc keep a pointer. -->

## Snapshot

Data-driven Roblox tower defense (Filipino myth theme). ~70% of the core loop done as a
two-Place vertical slice: full match lifecycle (Stage 1, Acts 1–3), 8 towers, passives/abilities/
summons, progression + match-end rewards, **ProfileStore persistence (schema v2: uuid unit
instances)**, and a shared UI kit both Places draw from.

- **Game** (Studio: "Alamat Defense - Game") — the match Place. `MatchEntryService` is the
  production entry; `MatchLifecycleSmokeTest` / `ColdProfileMatchTest` are the Studio harnesses.
  Owns tower configs, combat, the stat resolver, match runtime. Hotbar is on the shared kit.
- **Lobby** (Studio: "Alamat Defense - Lobby") — the social/meta Place. Scene `Workspace.Lobby`;
  flow = collection → stage select + difficulty → party → reserved-server launch, plus the
  MatchReturn banner and first-join starter picker. **`GetUnitViews` is its SINGLE profile read
  path** (`GetCollection` retired A7, ADR-0004). Screens: `docs/systems/lobby-ui.md`.
- **Shared canon** (`shared/manifest.json`, drift-checked by `tools/hash_shared.luau`):
  **24 entries = 16 modules + 8 templates**. **23 are GREEN in both Places; `Kit_ItemIcon` is
  intentionally NOT** — canon bumped to `c5e81264` from the Lobby at B1, Game stale (PENDING below).
  Templates are hashed as INSTANCE trees and have no `shared/src` file (ADR-0005). Kit detail:
  `docs/systems/ui-kit.md`. `UnitStatsCatalogValidate` is Game-only canon by design — do not
  "fix" its absence in the Lobby.

**DRIFT RULE (applies to everyone):** editing a shared controller **or a template** in one Place
only is DRIFT. Change → re-hash → copy to the other Place → update the manifest. Copy templates,
never rebuild them by hand. Both procedures: `tools/checklists.md`.

## Open PENDINGs

Resolved PENDINGs live in `CHANGELOG.md`. This list is CURRENT-state only.

- **PENDING (USER):** run the **teleport v2 loop live** — lobby → reserved match → return →
  banner. v2 has only ever been Studio-verified; only v1 was ever live-verified (2026-07-18).
  Both Places are published on v2, so a `[CONTRACT]` mismatch would block every launch.

- **PENDING (USER):** **republish BOTH Places** — A7's `GetCollection` deletion is Lobby Studio
  canon and is not in git (ADR-0001).

- **PENDING (AD-Integration) — `Kit_ItemIcon` canon bumped, the GAME is STALE.** B1 (2026-08-08)
  found the Lobby's copy diverged in 7 properties across 3 nodes; the **user confirmed all of it
  intentional** after being shown each change, so canon moved `ee1ccd33` → **`c5e81264`** with the
  LOBBY as source. Copy Lobby → Game, then set `deployed.Game = c5e81264`. **Until that lands the
  GAME reads 23/24 and the LOBBY reads 24/24 — that is EXPECTED, not new drift.** Do not "fix" it
  in the Game by editing the template; copy it.

- **PENDING (AD-Integration) — retire `UIKitRewardPopup` + `Kit_RewardPopup`.** Unblocked: the
  replacement (`ObtainRewardsGUI`) is BUILT and verified live as of B1, so the "leave no reveal
  surface" objection is gone. Re-grep BOTH Places for callers first (ADR-0004's procedure), delete
  controller + template in both, drop both manifest entries (**24 → 22**), delete
  `shared/src/UIKitRewardPopup.luau`, and fix the "24 entries" line in `STATE.md`, both
  `CONTEXT.md`s and `docs/systems/ui-kit.md`. Best done in the SAME session as the `Kit_ItemIcon`
  mirror above, since both touch the Game's kit.

- **PENDING (AD-Gacha / AD-Meta, when those ship) — nothing calls `ObtainRewardsGUI` yet.** The
  screen + its `RS.ClientEvents.ShowRewards` entry point are BUILT and verified; by user decision
  each system wires ITSELF in as it ships (gacha first, then quests / daily login / codes). The
  adopted unit card stays **Lobby-local, not shared canon** (AD-UI's call, B1) — revisit when the
  unit index becomes its second consumer, which is also when `Kit_UnitIcon`'s fate (ADR-0007,
  still PARKED, still not to be deleted) should finally be settled.

- **PENDING (AD-UI, small):** the hotbar **hover TRIGGER** is unverified in BOTH Places.
  `MouseEnter` cannot be fired from tooling and `VirtualInputManager` is blocked, so "the card
  appears on a real hover" is code-inspection-only. One manual hover in each Place closes it.
  Related: `Kit.UnitPreviewTemplate` has no `UnitLevelBar`, so the hotbar preview shows
  name/tier/stats but not level (intentional, skipped gracefully).

- **PENDING (AD-UI, small/cosmetic):** `Kit_ItemHoverCard`'s master/clone split —
  `ItemsGUI.HoverPreview` is a clone taken once at build time, so editing the master does NOT
  update the deployed screen. Decide whether this needs a real fix (it caused a stale-size bug at
  A5). Also `StarterGui.Hotbar.SlotTemplate` (Game) is dead — keep or delete when next touched.

- **PENDING (AD-Game, small):** a unit at `MAX_META_LEVEL` **loses its stored XP** — Archer Lv100
  went `XP 400 → 0` on earning defeat XP, because `ApplyXP` discards overflow at max rather than
  preserving the stored value. Cosmetic, but the Units screen shows that number.

- **PENDING (AD-PlayerLevel, small):** promote `TowerProgressionConfig` to shared so the Lobby can
  compute `XpPct` for a real XP bar. The unitView sends raw `XP` + `Level` only.

- **PENDING (Game):** real-DataStore persistence round-trip test for the PLAYER profile (A7 did a
  real round trip on a scratch key only), and the progressive
  `ServerStorage.Documentation` → `docs/systems/` migration.

- **PENDING (NEEDS SCHEDULING):** no writer for `Data.Items` in normal play, so the Items screen
  shows every count at 0. A latent path exists (`RewardCalculator` → `AddItem` on a Victory drop
  roll) but has never fired. Correct, not a bug — inert until an item economy exists.

- **NOT a bug, do not "fix" it:** the Units screen's stat NUMBERS are per-TOWER (the catalog's
  mid-roll reference), so two instances of one tower show equal numbers while their GRADE letters
  differ. ADR-0003's accepted trade. Details in `docs/systems/lobby-ui.md`.

- **NOT a bug:** `Data.Loadout` fills **LEFT TO RIGHT with no gaps** — it is a schema-v2
  `{ string }` contract field the match launcher reads, so it must stay a dense list. Fixed slot
  positions need a schema bump + migration under AD-Game's contract protocol (deferred).

## Contracts (versions only — detail in `docs/contracts/`)

- **Save schema v2** — `shared/src/ProfileTemplate.luau`, hash `63a0c98a`, deployed + drift-green
  in BOTH Places. Store `Beta1_PlayerData` (Studio: `Beta1_PlayerDataDev1`, API access ON).
  `Migrations[1]` v1→v2 re-verified live at A7 on a real ProfileStore round trip.
- **Teleport payload v2** — `docs/contracts/teleport.md`. Both sides, both directions. Hard
  cutover, no migration; v1 is rejected with `[CONTRACT]`. `LobbyConfig.MatchLaunchVersion` must
  always equal `GameConfig.TeleportPayloadVersion`. Live e2e re-verification is still open (USER).

## Next up

**✅ PHASE A IS SIGNED OFF (A9, 2026-08-06).** A1–A9 all landed; every §8 item PASSES, re-verified
live in both Places. The blueprint `docs/blueprints/phase-a-foundations.md` is now history.

1. **USER** — republish both Places (A7's `GetCollection` deletion + A8's and B0's Game service
   changes are Studio canon, not git), then run the teleport v2 loop live once.
2. **Phase B (gacha)** — `docs/blueprints/phases-b-f-meta.md`. **B0 landed 2026-08-08: placement is
   uuid-addressed, so duplicates now work and banners are unblocked. B1 landed 2026-08-08: the
   reveal surface (`ObtainRewardsGUI`) is BUILT and verified live.** Next is the banner engine —
   and it is the first system that should call `RS.ClientEvents.ShowRewards`.
3. **An AD-Integration session is now owed** (see the two PENDINGs above): mirror `Kit_ItemIcon`
   into the Game, and retire `UIKitRewardPopup` + `Kit_RewardPopup` now that the replacement works.
   Schema v2 already carries `Pity`/`Currencies`/`Items`, so gacha inherits those free.
