# Alamat Defense — Constitution (read first, every session)

This repo is the **single source of truth** for the Alamat Defense Experience (all Places: Game, Lobby, future
Tutorial/Event Worlds). Rules here bind every chat on any Place.

**Canon model:** disk is canon for knowledge, contracts and shared module source; Studio is canon for Place-local
code and runtime; git is the ledger. The repo beats chat memory and in-Studio docs on everything except live
Place-local runtime behaviour.

## Identity & Place binding

Chats are bound to a SYSTEM, not a Place. Core chats: **AD-Game** (match runtime), **AD-Lobby** (lobby scene/flow),
**AD-Integration** (cross-Place only). Subsystem chats (AD-UI, AD-Gacha, AD-PlayerLevel, AD-TowerModels, AD-Enemies,
AD-Traits, ...) own the systems in `docs/OWNERSHIP.md`. Every chat mounts this repo.

**Place binding is resolved at every bootstrap, never assumed:**
1. `list_roblox_studios` → instances are named "Alamat Defense - Game" and "Alamat Defense - Lobby".
2. Decide the task's Place (your system's home Place in OWNERSHIP.md, plus the task). `set_active_studio`, then
   CONFIRM the returned name before ANY write.
3. Needed Place not open? Ask the user to open it — never work on the wrong instance.
4. Task spans both Places? Follow the Integration rules (`tools/checklists.md`).

## Bootstrap ritual (mandatory, in order)

1. Read this file.
2. Read `STATE.md` (project snapshot + open PENDINGs).
3. Resolve Place binding (above), then read `places/<place>/CONTEXT.md`.
4. Read the **newest 3 entries** of `CHANGELOG.md` (newest-FIRST: entry 1 starts at line 3):
   `grep -n '^## ' CHANGELOG.md | head -4`, then `sed -n '1,<4th hit minus 1>p'`. Read further only to reach the
   session counter you already know. Never read it whole; never open `archive/`.
5. **Drift check:** run `tools/hash_shared.luau` via `execute_luau` (paste it inline — `require` is dead there,
   `docs/systems/studio-testing.md`) against your Place; compare with `shared/manifest.json`. Mismatch = STOP,
   reconcile before any work.
6. If `STATE.md` lists a PENDING targeting your Place or system, do that first.
7. **Integration gate (say it out loud, every session):** after 1–6, tell the user either "Run an AD-Integration
   session BEFORE this task" or "No Integration needed — proceeding." Triggers (full list `tools/checklists.md`):
   drift mismatch, a PENDING needing the OTHER Place, an undeployed contract/shared change, a task spanning both.

## Reading budget (the usage limit is a real constraint — user rule, 2026-08-17)

- **Bootstrap reads ONLY the four files in steps 1–4.** Nothing else is "orientation".
- **Never read a file over ~200 lines whole to find something** — `grep -n`, then `sed -n 'A,Bp'` on the hit's
  range. `archive/*`, `docs/ROADMAP.md` and `docs/design/ai-kms-architecture.md` are NEVER read whole. Recipes:
  `tools/checklists.md`.
- `docs/INDEX.md` is the map: open a system/ADR/proposal doc only when the task touches it, and read the section,
  not the file. Don't explore the game tree for orientation — the docs are the index. Explore only the thing you're
  changing, or a doc flagged stale.
- Prove with `script_grep`/`script_search` before `script_read`; print the ONE asserted value.

## Multi-chat synchronization (many chats, one truth)

- `CHANGELOG.md` is the event bus: APPEND-only, newest first, one entry per landing. It keeps the newest 10;
  older entries move verbatim to `archive/CHANGELOG-archive.md` (newest first).
- **Immediately BEFORE landing, re-read `STATE.md` + the changelog's FIRST entry only** (`sed -n '1,3p'`; "tail"
  hands you the OLDEST). A sibling may have landed mid-session. Merge your entry on top; never overwrite theirs.
- Single-writer: only the owner (OWNERSHIP.md) edits a system's code/docs/contracts. Everyone else writes
  `docs/proposals/` + a PENDING.
- Two chats must NOT live-edit the same Place at once unless their systems are disjoint. Contract or shared-module
  changes: strictly ONE chat at a time, no exceptions.
- On any git conflict or unexpected dirty state: stop, read `git status` + changelog, reconcile, then land.

## Landing checklist (mandatory at session end + after each verified milestone)

1. Update `places/<my-place>/CONTEXT.md` (current state only) and any touched system docs.
2. Shared module changed? → update `shared/src/`, rehash, update `manifest.json`, set other Places' `deployed` to
   their now-stale hash (leave as-is) and add a PENDING.
3. Contract changed? → bump its version, document old→new + migration, PENDING in the contract doc AND `STATE.md`.
4. Add a `CHANGELOG.md` entry on top (date, place, what, contract impact, open threads; ≤600 chars); if over 10
   entries, move the oldest to the top of `archive/CHANGELOG-archive.md`.
5. Refresh `STATE.md` if the project-level picture moved; flip your rows in `docs/ROADMAP.md` (status board).
6. `git add -A && git commit -m "[<place>] <summary>"`. **NO attribution trailers** — no `Co-Authored-By:`, no
   `Generated with`, no session link (user rule 2026-09-16).
7. The in-Studio `Documentation_Retired` set is read-only history (retired B123) — never mirror into it; the repo is the only doc set.
8. **User advisory (never skip):** end by telling the user, in plain terms: (a) any NEW PENDINGs and exactly which
   chat/Place must act BEFORE dependent work continues; (b) whether the other Place is now stale and should be
   updated first; (c) that the commit is local — recommend `git push` (or "push pending"); (d) anything the user
   must do personally (publish a Place, set an id, buy nothing); (e) whether the NEXT session should be
   AD-Integration — say it either way; (f) **a NEXT SESSION PROMPT only when HANDING OFF to a different chat**
   (user rules 2026-08-08 / 08-19): last in the reply, ONE copy-paste block — chat identity + Place, the ONE task,
   the facts/paths/hazards it must not re-derive, bootstrap + landing needs. **If THIS chat continues, write no
   prompt — just ask whether to carry on.** A cross-Place dependency found MID-session: surface it at once.

## Ownership (single writer per system)

Registry: `docs/OWNERSHIP.md` (system → owning chat → home Place → canon location). Non-owners never edit another
system's canon: write `docs/proposals/<date>-<topic>.md` + a PENDING in `STATE.md`; the owner picks it up. Unlisted
new system → add it to OWNERSHIP.md as part of building it.

## Editing rules (hard-won; violating these has caused real data loss)

- `execute_luau` runs in a SEPARATE VM with its own require cache: NEVER verify live service state through it
  (required modules are empty copies that mimic data-loss bugs). Verify with `[DIAG]` prints in a real Script +
  `get_console_output`. Reading `.Source` / instance properties IS safe. More traps: `docs/systems/studio-testing.md`.
- Write WHOLE module files (multi_edit for targeted diffs, `.Source =` for rewrites). Never chain `gsub` edits;
  `%` in gsub replacements fails silently.
- All persistent edits in the **Edit** datamodel. Play mode is read-only observation.
- **Standing permission (user, 2026-08-06/09): any chat may run `start_stop_play` itself when verification needs
  it. Studio AUTOSAVES — never ask the user to save first, just Play.** Stop when done; leave every `Dev*` harness
  attribute OFF.
- Console output lingers across Play sessions — correlate timestamps. A Play session dying in ~1s with
  `Server Kick Message: Error 500` is an ENVIRONMENT fault (an inserted free model, 2026-08-06) — say so, don't
  "fix" code.
- After editing a shared module in Studio, its disk canon + manifest MUST be updated the same session (landing 2).
- Log prefixes: `[DIAG]` debugging, `[DATA]` persistence, `[CONTRACT]` schema/version, `[Test]` harness. Grep-able.
- **ONLY THE CLOSE BUTTON CLOSES A UI (user, 2026-10-02).** No click-outside / scrim / dim / overlay dismiss, ever
  (gamepad B = the close button). Reveal overlays saying "click anywhere to continue" are the one exception.
- **NEVER generate UI in scripts (user, 2026-07-18).** ScreenGuis/Frames/labels are REAL Instances in StarterGui
  the user can edit. Dynamic lists clone a designed `*Template` (Visible=false). Controllers only read data, clone
  templates, set text/visibility, wire events. Convert legacy script-built screens when next touched.
- **NEVER RE-LAYOUT UI LIVE FROM A SCRIPT (user, 2026-10-15).** Position / Size / parenting are authored in STUDIO
  (Edit) only — no PC/phone layout swaps, no resize hooks moving frames; motion tweens return to the AUTHORED
  values. Parent every element to the frame it sits in (no full-screen layer frames).
- **Every rectangle action button = the Alamat PLATE** (user, 2026-10-14): `DevTools.AlamatPlate` convert /
  `Templates.AlamatPlate` — `alamat-ui.md`.
- **Looks changed or unusual? ASK THE USER whether they did it** (user, 2026-08-16); never "fix" it.
- **EVERY NEW FEATURE SHIPS FOR PC + CONSOLE + MOBILE (user, 2026-09-27; PC is main).** No mouse-only or key-only
  interaction: bind through ContextActionService / gamepad UI selection too (foundation: the console batch).
- **A NEW UNIT LIVES IN BOTH PLACES (user, 2026-09-19).** The rig goes in the GAME's `RS.TowerModels` *and* the
  LOBBY's `RS.UnitModels`, same name (+ optional `GameScale`), stored at FULL R15 size (the game shrinks it,
  `tower-authoring.md` §6); idle = the GAME config's `Idle.Anim` + the SAME id as the LOBBY rig's `IdleAnim`
  attribute. The Lobby has no TowerConfig, so a unit missing there previews as `Placeholder` everywhere.
  **REMIND THE USER OF THIS whenever a new unit is created**, in either Place.

## Blueprint discipline (how lesser sessions stay on the rails)

- `docs/blueprints/` holds implementation blueprints. For a feature they cover, the blueprint is LAW, like a
  contract — read it BEFORE designing anything. Implement exactly ONE blueprint session-task per session.
- Never improvise a different data shape, module name or algorithm than specified. Blocked or convinced it's
  wrong? STOP → `docs/proposals/` + ask the user.
- Copy the cited reference modules' style. Prefer boring code. No refactors beyond scope. Uncertain? Ask, never invent.

## Contract-change protocol

1. Only the owner changes a contract, in a session where no sibling chat is active on it.
2. Bump the integer version (e.g. `SCHEMA_VERSION`), add a migration, never edit old migrations.
3. Deploy + verify in the owner's Place.
4. Add `PENDING: <other place> must deploy <module> vN` to `STATE.md`.
5. The consumer chat clears the PENDING at its next bootstrap before other work.

## Doc size budgets (CHARACTERS — lines hid paragraph bloat; keep bootstrap under ~25k chars)

CLAUDE.md ≤12k · STATE.md ≤6k · each CONTEXT.md ≤6k · a CHANGELOG entry ≤600 chars (at most 5 short lines; the
detail goes in the system doc) · contract / system docs ≤300 lines. Check with `wc -m`.
**History never goes in STATE/CONTEXT; it goes in CHANGELOG (and `archive/`).** STATE/CONTEXT describe NOW.
Over budget → delete resolved items, move detail into the system doc, register new docs in `docs/INDEX.md`.
New durable decision → one-page ADR in `docs/decisions/`. **`STATE.md` stays ONE file (ADR-0006)**: delete resolved
PENDINGs (the changelog is their record); strikethrough `~~DONE~~` in the PENDING list is banned.
