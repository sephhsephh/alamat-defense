# Alamat Defense — Constitution (read first, every session)

This repo is the **single source of truth** for every Alamat Defense Place (Game, Lobby, future worlds); its rules
bind every chat on any Place. **Canon:** disk for knowledge, contracts, shared module source; Studio for
Place-local code + runtime; git is the ledger. The repo beats chat memory and in-Studio docs on everything but live
Place-local runtime behaviour.

## Identity & Place binding
Chats bind to a SYSTEM, not a Place: **AD-Game** (match runtime), **AD-Lobby** (lobby scene/flow),
**AD-Integration** (cross-Place only), subsystem chats (AD-UI, AD-Gacha, AD-PlayerLevel, AD-TowerModels,
AD-Enemies, AD-Traits, ...) per `docs/OWNERSHIP.md`. All mount this repo. Resolve the Place EVERY bootstrap:
1. `list_roblox_studios` → "Alamat Defense - Game" / "Alamat Defense - Lobby".
2. Pick the Place (your system's home Place + the task); `set_active_studio`; CONFIRM the name before ANY write.
3. Needed Place not open? Ask the user to open it — never work on the wrong instance.
4. Task spans both Places? Integration rules (`tools/checklists.md`).

## Bootstrap ritual (mandatory, in order)
1. Read this file.
2. Read `STATE.md` (snapshot + open PENDINGs).
3. Resolve the Place, then read `places/<place>/CONTEXT.md`.
4. Read the **newest 3** `CHANGELOG.md` entries (newest-FIRST, entry 1 at line 3): `grep -n '^## ' CHANGELOG.md |
   head -4`, then `sed -n '1,<4th hit − 1>p'`; further only to reach the session counter you know. Never read it
   whole; never open `archive/`.
5. **Drift check:** paste `tools/hash_shared.luau` inline into `execute_luau` on your Place (`require` is dead there,
   `docs/systems/studio-testing.md`); compare with `shared/manifest.json`. Mismatch = STOP, reconcile first.
6. A `STATE.md` PENDING targeting your Place or system comes first.
7. **Integration gate, said out loud every session:** "Run an AD-Integration session BEFORE this task" or "No
   Integration needed — proceeding." Triggers (all: `tools/checklists.md`): drift mismatch, a PENDING needing the
   OTHER Place, an undeployed contract/shared change, a task spanning both Places.

## Reading budget (the usage limit is real — user rule, 2026-08-17)
- Bootstrap reads ONLY steps 1–4 — no other "orientation"; the docs are the index. Explore only what you change,
  or a doc flagged stale.
- Never read a file over ~200 lines whole to find something: `grep -n`, then `sed -n 'A,Bp'`. `archive/*`,
  `docs/ROADMAP.md`, `docs/design/ai-kms-architecture.md`: NEVER whole. Recipes: `tools/checklists.md`.
- `docs/INDEX.md` is the map: open a doc only when the task touches it; read the section, not the file.
- Prove with `script_grep`/`script_search` before `script_read`; print the ONE asserted value.

## Multi-chat sync & ownership
- `CHANGELOG.md` = the event bus: APPEND-only, newest first, one entry per landing, newest 10 kept; older ones move
  verbatim to the top of `archive/CHANGELOG-archive.md`.
- **Right BEFORE landing, re-read `STATE.md` + the changelog's FIRST entry** (`sed -n '1,3p'`; "tail" = the
  OLDEST) — a sibling may have landed. Put your entry on top; never overwrite theirs.
- Single writer: only the owner in `docs/OWNERSHIP.md` edits a system's code/docs/contracts; others write
  `docs/proposals/<date>-<topic>.md` + a `STATE.md` PENDING for the owner. A new system joins OWNERSHIP.md as it is built.
- No two chats live-edit one Place at once unless their systems are disjoint. Contract or shared-module changes:
  strictly ONE chat at a time.
- Git conflict or unexpected dirty state: stop, read `git status` + changelog, reconcile, then land.

## Landing checklist (session end + after each verified milestone)
1. Update `places/<my-place>/CONTEXT.md` (current state only) + touched system docs.
2. Shared module changed → `shared/src/`, rehash, `manifest.json`; leave other Places' `deployed` at their now-stale
   hash; add a PENDING.
3. Contract changed → bump its version, document old→new + migration, PENDING in the contract doc AND `STATE.md`.
4. CHANGELOG entry on top (date, place, what, contract impact, open threads; ≤600 chars; keep 10, see above).
5. Refresh `STATE.md` if the project picture moved; flip your `docs/ROADMAP.md` rows.
6. `git add -A && git commit -m "[<place>] <summary>"` — **NO attribution trailers** (no `Co-Authored-By:`,
   `Generated with` or session link; user rule 2026-09-16).
7. In-Studio `Documentation_Retired` (B123) is read-only history; never mirror into it — the repo is the only doc set.
8. **User advisory (never skip), plainly:** (a) NEW PENDINGs + which chat/Place acts BEFORE dependent work; (b) is
   the other Place stale, update it first?; (c) the commit is local — recommend `git push` (or "push pending");
   (d) what the user must do (publish, set an id, buy nothing); (e) should the NEXT session be AD-Integration — say
   either way; (f) **only when HANDING OFF to another chat** (user rules 2026-08-08/19), last: ONE copy-paste NEXT
   SESSION PROMPT — identity + Place, the ONE task, facts/paths/hazards not to re-derive, bootstrap + landing
   needs. **If THIS chat continues: no prompt — ask whether to carry on.** Surface a cross-Place dependency found
   mid-session at once.

## Editing rules (hard-won; breaking them has lost real data)
- `execute_luau` is a SEPARATE VM with its own require cache: NEVER verify live service state through it
  (required modules are empty copies that mimic data-loss bugs). Verify via `[DIAG]` prints in a real Script +
  `get_console_output`; reading `.Source`/properties IS safe. More: `studio-testing.md`.
- Write WHOLE module files (multi_edit for diffs, `.Source =` for rewrites); never chain `gsub` edits (`%` in a
  replacement fails silently).
- Persistent edits in the **Edit** datamodel only; Play mode is read-only observation.
- **Standing permission (user, 2026-08-06/09): any chat may `start_stop_play` when verification needs it. Studio
  AUTOSAVES — never ask the user to save first.** Stop when done; leave every `Dev*` attribute OFF.
- Console output lingers across Plays — correlate timestamps. Play dying in ~1s with `Server Kick Message: Error
  500` is an ENVIRONMENT fault (inserted free model, 2026-08-06): say so, don't "fix" code.
- A shared module edited in Studio gets disk canon + manifest updated the same session (landing 2).
- Grep-able log prefixes: `[DIAG]` debug, `[DATA]` persistence, `[CONTRACT]` schema/version, `[Test]` harness.

## UI + content rules (user rules; date = when set)
- **ONLY THE CLOSE BUTTON CLOSES A UI** (2026-10-02): no click-outside/scrim/dim/overlay dismiss, ever (gamepad B
  = close). Sole exception: reveal overlays saying "click anywhere to continue".
- **NEVER generate UI in scripts** (2026-07-18): UI is REAL StarterGui Instances the user can edit; dynamic lists
  clone a designed `*Template` (Visible=false); controllers only read data, clone, set text/visibility, wire
  events. Convert legacy script-built screens when next touched.
- **NEVER re-layout UI live from a script** (2026-10-15): Position/Size/parenting are authored in Studio (Edit)
  only — no PC/phone swaps, no resize hooks moving frames; tweens return to AUTHORED values. Parent each element to
  the frame it sits in (no full-screen layer frames).
- **Every rectangle action button = the Alamat PLATE** (2026-10-14): `DevTools.AlamatPlate` / `Templates.AlamatPlate`.
- **Tintable art is generated WHITE** (2026-10-21): gems / fills / glows white-on-transparent, coloured in Studio by a
  `UIGradient` child named `Tint`; real-colour parts (gold) on a separate untinted layer (`docs/design/white-tint-art.md`).
- **Looks changed or unusual? ASK THE USER whether they did it** (2026-08-16); never "fix" it.
- **Every new feature ships for PC + console + mobile** (2026-09-27; PC is main): no mouse- or key-only input;
  bind via ContextActionService / gamepad UI selection too (foundation: the console batch).
- **A new unit lives in BOTH Places** (2026-09-19): rig in the Game's `RS.TowerModels` AND the Lobby's
  `RS.UnitModels`, same name (+ optional `GameScale`), FULL R15 size (game shrinks it, `tower-authoring.md` §6);
  Lobby rig's `IdleAnim` attribute = the Game config's `Idle.Anim`. Missing in the Lobby (no TowerConfig there) =
  `Placeholder` everywhere. **REMIND THE USER whenever a unit is created**, in either Place.

## Blueprints (`docs/blueprints/`)
LAW for what they cover, like a contract: read BEFORE designing; ONE session-task per session. Never improvise a
different data shape, module name or algorithm; blocked or think it's wrong → STOP, `docs/proposals/` + ask. Copy
the cited modules' style; boring code; no refactors beyond scope; unsure → ask.

## Contract-change protocol
Owner only, no sibling chat active on it → bump the integer version (e.g. `SCHEMA_VERSION`) + add a migration (never
edit old ones) → deploy + verify in the owner's Place → `PENDING: <other place> must deploy <module> vN` in
`STATE.md` → the consumer chat clears it at its next bootstrap, before other work.

## Doc budgets (CHARACTERS, `wc -m`; bootstrap target ~25k)
CLAUDE.md ≤12k · STATE.md ≤6k · each CONTEXT.md ≤6k · CHANGELOG entry ≤600 (≤5 short lines; detail in the system
doc) · contract/system docs ≤300 lines. **History never goes in STATE/CONTEXT; it goes in CHANGELOG (and
`archive/`).** Over budget → delete resolved items, move detail to the system doc, register new docs in
`docs/INDEX.md`. Durable decision → one-page ADR, `docs/decisions/`. **`STATE.md` stays ONE file (ADR-0006):**
delete resolved PENDINGs (the changelog is their record); `~~DONE~~` strikethrough is banned.
