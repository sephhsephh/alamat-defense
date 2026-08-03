# Proposal: promote Meta configs + resolver to shared, reconcile TierConfig (multi-color) — unblocks A4/A5
<!-- from: AD-UI | to: AD-Integration (execute) + AD-Game (owns resolver/StatGrade/BaseStats) | 2026-08-01 -->
<!-- status: EXECUTED 2026-08-01 (AD-Integration). A4/A5 UNBLOCKED. See CHANGELOG for the landing. -->

> **EXECUTED 2026-08-01 — with three deviations, all recorded in the CHANGELOG entry:**
> 1. **`TowerStatResolver` was NOT promoted.** §1 assumed a one-module move; `Resolve()` actually
>    takes a whole towerConfig and pulls in MetaScaling/Traits, so Lobby-side numbers would put
>    ~12 modules (incl. all 8 tower configs) under drift control. User chose to **ship grades now
>    and defer the numbers decision to A6** — grades need only the roll. The other 4 modules were
>    promoted and are drift-green in both Places.
> 2. **`UnitCatalog` was retired in place, not deleted** (§3). Its deletion assumed §4 replaced the
>    stat numbers; with numbers deferred it is still the only source of the Units-screen
>    placeholders. Name/Tier there are now dead duplicates of ItemCatalog. Delete at A4/A5.
> 3. **`ItemCatalog` needed a code change to be shareable** — its `TowerConfigRegistry` require is
>    now lazy + optional (that module exists only in the Game), and `Validate()` returns
>    `(ok, errors, notes)`.
>
> §4's unitView shipped as `LobbyServices.GetUnitViews`, minus resolved DMG/RNG/SPA (above) and
> minus `XpPct` (the Lobby has no `TowerProgressionConfig` — raw XP + Level are sent instead).

## Why

A4/A5 (AD-UI) must show **resolved** DMG/RNG/SPA + tiers/grades in the Lobby (Units screen +
hotbar preview), replacing the interim `UnitCatalog` placeholders. Verified 2026-08-01 (drift
green, `ProfileTemplate 63a0c98a`): the Lobby already receives uuid `Units` **with raw StatRolls**
via `LobbyServices.GetCollection`, but the modules that turn rolls → stats/grades/tier live
**only in the Game place** (A3 built them as "Game canon, promote to shared at A7"):
`TowerStatResolver`, `StatGradeConfig`, `AscensionConfig`, `ItemCatalog` — all **ABSENT in the
Lobby**. So the Lobby cannot resolve anything yet. This is a shared-canon change (deploy both
Places) → one Integration session, per the constitution. User chose "Run AD-Integration first"
and "A3's TierConfig canonical + add multi-color" (2026-08-01).

## 1. Promote to `shared/src` (deploy BOTH Places; rehash + manifest per landing checklist)

Move these from Game `RS.Configs.Meta` / Game canon into shared canon, deployed to Game + Lobby:

- `TierConfig`  (reconciled per §2)
- `StatGradeConfig`
- `AscensionConfig`
- `ItemCatalog`
- `TowerStatResolver`  (AD-Game owns it — AD-Game/Integration performs the move)

Note the resolver also needs each tower's `BaseStats` ranges to resolve. Decide with AD-Game:
either (a) the resolver reads BaseStats from tower configs that are Lobby-readable, or (b)
LobbyServices resolves server-side using a slim BaseStats table promoted alongside. Keep the
resolver's public signature (`statRolls`, `ascension` optional params) unchanged.

After promotion: add each to `shared/manifest.json` (hash + `deployed` for both Places), verify
drift green in BOTH, add the standard "other Place deploy" PENDINGs if not deployed same session.

## 2. TierConfig reconciliation — A3 shape as base, ADD multi-color (do not lose rainbow)

Canonical = A3's `TierConfig` (Order `Common → … → Bathala`, per-tier `SortOrder`). EXTEND its
per-tier entry so a tier may declare **one or many** colours, and add helpers (ported from the
AD-UI interim `TierConfig`):

- Per-tier entry: keep `Color = Color3` (single) OR add `Colors = { Color3, ... }` (list). A tier
  with a list animates a gradient; a single colour is solid. Single-colour tiers unchanged.
- Multi-colour palettes to seed (user's spec): **Mythic = rainbow**
  `{255,60,60},{255,170,40},{250,240,60},{70,220,90},{60,150,255},{170,80,240}`;
  **Secret = red + dark red** `{255,45,45},{90,0,0}`. Others stay single-colour
  (Rare blue `{55,130,255}`, Epic purple `{168,70,235}`, Legendary yellow `{255,205,55}`, …).
- Helpers to add: `get(tier)`, `colorSequence(tier)` (flat if 1 colour), `seamlessSequence(tier)`
  (tiled+wrapped so an Offset scroll loops perfectly — needed for the rainbow), `isMultiColor(tier)`.
  These exist verbatim in the Lobby's interim `TierConfig` — lift them.

Result: one shared `TierConfig` that keeps A3's tier order/assignment semantics AND supports the
animated multi-colour borders the UI already uses.

## 3. Retire the interim Lobby configs

- **Delete** Lobby `RS.Configs.Meta.UnitCatalog` (interim). Tier per unit now comes from
  `ItemCatalog` (entry `.Tier`); placeholder DMG/RNG/SPA are replaced by resolved stats (§4).
- **Replace** Lobby `RS.Configs.Meta.TierConfig` (interim) with the promoted shared one (§2).

## 4. LobbyServices unitView (enables A4/A5; AD-UI builds the client, server view is the contract)

Once §1 lands, `LobbyServices.GetCollection` (or a new `GetUnitViews`) returns, per owned uuid, a
plain **unitView**: `{ Uuid, TowerId, Name (ItemCatalog), Tier, Level (MetaLevel), XpPct, Trait,
Shiny, Favorited, Locked, Equipped (uuid ∈ Loadout), DMG, RNG, SPA (TowerStatResolver with the
unit's StatRolls+Ascension), Grades = { DMG, RNG, SPA } (StatGradeConfig from the rolls),
Cost, Elements }`. Clients never read the profile directly (blueprint §5). This is what "pass the
real rolls to the client / fix the flat previews" resolves to — the server resolves, the client
renders. **Remove the interim `Towers` / `Currency` compat fields** from `GetCollection` here
(the open A5 PENDING) once CollectionScreen + UnitsGUI consume the unitView.

## 5. Then A4/A5 (AD-UI, next AD-UI session, after this lands)

- `UnitsController` + `HotbarController` read the unitView: real DMG/RNG/SPA + grades in the
  stats panel / hover preview (replaces `UnitCatalog`), tier border from the shared `TierConfig`
  (multi-colour intact), real `Equipped`/`Favorited` drive the grid sort (replace interim flags),
  real per-unit models when available (replace `UnitModels.Placeholder`).
- Formalise the kit templates (UnitIcon/ItemIcon/HoverCard/FilterPanel) per blueprint §5 as A5.

## Requested action (AD-Integration session)

1. Execute §1–§3 as a shared-module change (single chat): promote the 5 modules, reconcile
   TierConfig with multi-color, retire the Lobby interim configs, rehash + manifest, deploy +
   drift-green BOTH Places, changelog.
2. Land §4 (LobbyServices unitView) — coordinate with AD-Lobby (its canon) or do it in the same
   Integration session; document the unitView shape in `places/lobby/CONTEXT.md`.
3. Clear the AD-UI A4/A5 PENDING so the next AD-UI session wires the kit.
4. Reminder: the BLOCKING user publish PENDING (both Places together) still stands.
