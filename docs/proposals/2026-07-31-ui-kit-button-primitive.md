# Proposal: universal Button primitive + PlayerLevelBar for the Phase A icon kit
<!-- from: AD-UI (owner: kit/screens) | to: AD-UI + AD-Game (co-owners of phase-a-foundations.md) | 2026-07-31 -->
<!-- status: FOR REVIEW — blueprint change (LAW); no build until approved AND A1–A3 land -->

## What

Add two things to the Phase A kit spec (`docs/blueprints/phase-a-foundations.md` §5), and
record the modularization the section already implies as an explicit rule:

1. **`Button` primitive** — a base component every clickable in the kit composes, instead of
   each button carrying its own copied LocalScript.
   - Template: `ReplicatedStorage.UITemplates.Kit/Button` — a REAL, user-editable Instance:
     `Button (TextButton) { Label (TextLabel), Stroke (UIStroke) { Grad (UIGradient) },
     Icon (ImageLabel), UIScale }`. Design (colors, gradient keypoints, corner, padding) is
     edited in Studio; the controller never builds visuals (constitution no-UI-in-scripts).
   - Controller: `ReplicatedStorage.Shared.UIKit/Button.luau`, client module.
     `UIKit.Button.Create(parent, opts) -> { SetText, SetIcon, SetEnabled, OnActivated, Destroy, Instance }`.
     `opts = { Text, Icon, Style?, OnActivated? }`.
   - Interaction (tween via TweenService, all magnitudes are attributes on the template so the
     user tunes them without code):
     - Hover in: `Stroke.Thickness` × `HoverStrokeMult` (default 1.6), `UIScale.Scale` ×
       `HoverTextGrow` (default 1.06), `Icon.Rotation` → `HoverIconRotation` (default 45).
     - Hover out: tween back to base.
     - Activated: quick press — `UIScale` down to `PressScale` (default 0.94) then spring back;
       reuse one tween per handle (no per-frame connections).
   - `Style` keys (in a small `UIKit/ButtonStyles` table) only pick which template variant /
     gradient preset to clone; they never inline colors in script.

2. **`PlayerLevelBar` primitive** — the exp bar you described (progress fill + centered
   `"Lv {n} — {cur}/{req} XP"` text).
   - Template: `ReplicatedStorage.UITemplates.Kit/PlayerLevelBar` — `Root (Frame) {
     Fill (Frame), Text (TextLabel) }`.
   - Controller: `UIKit.PlayerLevelBar.Create(parent) -> { SetView, Destroy, Instance }`,
     where `SetView(view)` sets `Fill.Size = UDim2.fromScale(view.Pct, 1)` and the label.
   - `view = { Level, CurXP, ReqXP, Pct }` — a server-built view-model. **The bar is view-only:
     it never computes the curve.** `Level`/`ReqXP` come from the PlayerLevel system
     (owner: AD-PlayerLevel; curve canon `RS.Configs.Global.*`) surfaced through a Lobby
     `LobbyServices.GetPlayerLevel` remote. Clients never read the profile directly (kit rule).

3. **Explicit modularization rule (already the §5 intent — make it law):** kit templates carry
   design ONLY, zero LocalScripts. All behavior lives in `Shared/UIKit/` controllers. `UnitIcon`,
   `ItemIcon`, hotbar slots, and every lobby button are BUILT ON `Button` (compose, don't copy).
   The current per-button `Unit/ItemIconTemplateLocalScript` pattern (one script duplicated into
   each button) is retired in favor of the single controller set during the A4/A6 rebuilds.

## Why

- Your ask ("make that button a universal structure — text, UIStroke with UIGradient, icon;
  hover grows the stroke + text and rotates the icon ~45°; add a click anim") is a **Button
  base component**, which the blueprint's kit (§5) does not currently define — its kit is
  icon-centric (`UnitIcon`/`ItemIcon`/HoverCards/TierBorder). Adding it is a blueprint change,
  so it needs this proposal rather than a freehand build (blueprint discipline).
- Your unit-vs-item instinct already matches the blueprint exactly and needs no change:
  **units** use `UnitIcon` = ViewportFrame + WorldModel (idle anim); **items** use `ItemIcon`
  = ImageLabel only. Both compose `Button` + `TierBorder` + a hover card. So "Unit/ItemIconTemplate"
  → the two existing kit templates, unified by the shared `Button` base and hover behavior,
  differing only in the display surface (viewport vs image). No new data shape.
- "Reduce redundancy / having similar scripts on different buttons is redundant — am I wrong?"
  You're right. One `UIKit` controller set replacing N copied LocalScripts is precisely the
  §5 controllers-in-`Shared/UIKit` design; this proposal just makes the Button base and the
  no-scripts-on-templates rule explicit so A4 builds it that way.

## Hotbar random-glow bug — live inspection findings (2026-07-31, Lobby Studio)

VERIFIED by reading the live tree (`StarterGui.Hotbar`) + the slot script source, not guessed:

1. **Every button embeds its own copy of the same 172-line `Unit/ItemIconTemplateLocalScript`.**
   The live `Hotbar.Slots` contains SIX running copies: `Slot3, Slot4, Slot5, Slot6` plus TWO
   leftover, still-`Visible`/`Active` copies literally named `Unit/ItemIconTemplate` (LayoutOrder
   0 vs the slots' LayoutOrder 1). So the hotbar has six overlapping interactive buttons, each
   independently running the hover logic. (This is the redundancy the user suspected — confirmed.)
2. **All six are structurally identical and complete** — each has `Main.BG.UIStrokeWithGradient`
   (+ its `UIGradient`), `Main.BG.UIGradient`, `Main.BG.UIStroke`, `Main.ViewportFrame`, etc. So
   the glow failing is NOT a missing-instance / early-`return` case; the WaitForChild chain
   resolves for all of them.
3. **Hover is driven by `Button.MouseEnter` / `Button.MouseLeave`** (script lines 153/167), which
   Roblox documents as best-effort: they can fail to fire when the cursor crosses BETWEEN
   overlapping GUI objects or moves quickly. Six overlapping buttons (the two stray duplicates +
   identical `LayoutOrder`) is exactly the overlap condition that makes enter/leave drop — the
   topmost object at a given pixel eats the event, so some slots glow and some don't, per-hover,
   looking "random."
4. **Shared single preview:** all six scripts drive ONE `Hotbar.Templates.UnitPreviewTemplate`
   (each sets its `.Visible`), so they fight over it — a related flicker bug, separate from glow.

**Still to confirm in Play mode** (not yet done — no live hover test this session): watch which
slots glow while hovering + whether enter/leave is the drop point. This is the one piece that
should be reproduced live before the fix is called proven.

**Fix direction (this proposal's whole point):** one `UIKit` controller owns a single robust
hover routine (do not rely on bare MouseEnter/MouseLeave alone — add MouseMoved / hit-tracking or
an InputChanged fallback), templates carry design only, and the leftover duplicate templates are
removed from `Hotbar.Slots` (they belong in a Templates folder, `Visible=false`). Implemented in
A6 (hotbar rebuild) on the kit; the duplicate-removal is a safe cleanup that can happen sooner
with user approval.

## Sequencing / gating (why this can't be built yet)

The hotbar (units-equipped + per-slot rarity glow + stat hover) and the exp bar are Phase A
tasks **A4/A6**, hard-gated on:
- **A1 [AD-Game]** schema v2 → uuid `Units` with `StatRolls` (what the hotbar shows) + `PlayerXP`/`PlayerLevel` (what the exp bar shows).
- **A2 [AD-Integration]** deploy v2 to Lobby + teleport v2.
- **A3 [AD-Game]** `TierConfig` (rarity → glow color), `StatGradeConfig` (hover grades), `ItemCatalog`.

Until A1–A3 land there is no rarity color to glow and no unit/level data to render, so building
the kit now would improvise data shapes the blueprint forbids. This proposal only gets the
Button + PlayerLevelBar additions blessed so A4 implements them correctly.

## Requested action

1. **User:** approve/adjust these two kit additions + the no-scripts-on-templates rule.
2. On approval, **AD-UI** folds them into `phase-a-foundations.md` §5 (Button + PlayerLevelBar
   templates/controllers; add "hotbar slots and all lobby buttons compose Button" to A6/A4 notes).
3. Then normal blueprint order resumes: **A1 → A2 → A3** (AD-Game / AD-Integration), then this
   AD-UI chat builds **A4 → A5 → A6** on the extended kit and verifies live with `[DIAG]`.
4. **When Studio is back online**, before A6, do a read-only pass on the live hotbar slot scripts
   to confirm the glow-bug hypothesis and record the real cause here.
