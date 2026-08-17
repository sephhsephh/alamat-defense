# Alamat Defense — Constitution (read first, every session)

This repo is the **single source of truth** for the Alamat Defense Experience (all Places:
Game, Lobby, future Tutorial/Event Worlds). Rules here bind every chat on any Place.

**Canon model:** disk is canon for knowledge, contracts and shared module source; Studio is
canon for Place-local code and runtime; git is the ledger. The repo beats chat memory and
in-Studio docs on everything except live Place-local runtime behaviour.

## Identity & Place binding

Chats are bound to a SYSTEM, not to a Place. Core chats: **AD-Game** (match runtime),
**AD-Lobby** (lobby scene/flow), **AD-Integration** (cross-Place only). Subsystem chats
(AD-UI, AD-Gacha, AD-PlayerLevel, AD-TowerModels, AD-Enemies, AD-Traits, ...) own the
systems listed in `docs/OWNERSHIP.md`. Every chat mounts this repo.

**Place binding is resolved at every bootstrap, never assumed:**
1. `list_roblox_studios` → open instances are named "Alamat Defense - Game" and
   "Alamat Defense - Lobby".
2. Decide which Place the task lives in (your system's home Place in OWNERSHIP.md, plus
   the task itself). `set_active_studio`, then CONFIRM the returned name before ANY write.
3. Needed Place not open? Ask the user to open it — never work on the wrong instance.
4. Task spans both Places? Follow the Integration rules (`tools/checklists.md`).

## Bootstrap ritual (mandatory, in order)

1. Read this file.
2. Read `STATE.md` (project snapshot + open PENDINGs).
3. Resolve Place binding (above), then read `places/<place>/CONTEXT.md`.
4. Read `CHANGELOG.md` **TOP-DOWN, stopping at the session counter you already know** — it is
   newest-FIRST, so the newest entry starts at line 3, not at the end. **NEVER read it whole:**
   ~4.5k lines ≈ 90k tokens to learn what the first ~70 say. Recipes: `tools/checklists.md`.
5. **Drift check:** run `tools/hash_shared.luau` via `execute_luau` against your Place;
   compare with `shared/manifest.json`. Mismatch = STOP, reconcile before any work.
6. If `STATE.md` lists a PENDING targeting your Place or system, do that first.
7. **Integration gate (say it out loud, every session):** after 1–6, tell the user either
   "Run an AD-Integration session BEFORE this task" or "No Integration needed — proceeding."
   Short form of the triggers (full list in `tools/checklists.md`): drift mismatch, a PENDING
   needing the OTHER Place, an undeployed contract/shared change, a task spanning both Places.

## Reading budget (the usage limit is a real constraint — user rule, 2026-08-17)

- **Bootstrap reads ONLY the four files in steps 1–4.** Nothing else is "orientation".
- **Never read a file over ~200 lines whole to find something** — `grep -n` for it, then
  `sed -n 'A,Bp'` on the hit's range. `CHANGELOG.md` (4.5k lines), `docs/ROADMAP.md` (450)
  and `docs/design/ai-kms-architecture.md` are NEVER read whole. Recipes in `tools/checklists.md`.
- `docs/INDEX.md` is the map: open a system/ADR/proposal doc only when the task touches it,
  and read the section, not the file. Do not explore the game tree for orientation — the docs
  are the index. Explore only the thing you're changing, or a doc flagged stale.
- Prove with `script_grep`/`script_search` before `script_read`; print the ONE asserted value.

## Multi-chat synchronization (many chats, one truth)

- `CHANGELOG.md` is the event bus: APPEND-only, newest first, one entry per landing.
- **Immediately BEFORE landing, re-read `STATE.md` + the changelog's FIRST entry only**
  (`sed -n '1,3p'`; "tail" would hand you the OLDEST). A sibling chat may have landed
  mid-session. Merge your entry on top; never overwrite theirs.
- Single-writer: only the owner (OWNERSHIP.md) edits a system's code/docs/contracts.
  Everyone else writes `docs/proposals/` + a PENDING.
- Two chats must NOT live-edit the same Place at the same time unless their systems are
  disjoint. Contract or shared-module changes: strictly ONE chat at a time, no exceptions.
- On any git conflict or unexpected dirty state: stop, read `git status` + changelog,
  reconcile, then land.

## Landing checklist (mandatory at session end + after each verified milestone)

1. Update `places/<my-place>/CONTEXT.md` and any touched system docs.
2. Shared module changed? → update `shared/src/`, rehash, update `manifest.json`,
   set other Places' `deployed` to their now-stale hash (leave as-is) and add a PENDING.
3. Contract changed? → bump its version, document old→new + migration, add PENDING
   in the contract doc AND in `STATE.md`.
4. Append a `CHANGELOG.md` entry (date, place, what, contract impact, open threads).
5. Refresh `STATE.md` if the project-level picture moved; flip your rows in
   `docs/ROADMAP.md` (the done/partial/planned status board).
6. `git add -A && git commit -m "[<place>] <summary>"`.
7. Mirror the essentials into the Place's `ServerStorage.Documentation` (AIState +
   RecentChanges) until that in-Studio doc set is fully retired.
8. **User advisory (never skip):** end the session by telling the user, in plain terms:
   (a) any NEW PENDINGs and exactly which chat/Place must act on them BEFORE dependent
   work continues; (b) whether the other Place is now stale and should be updated first;
   (c) that the commit is local — recommend `git push` (or note "push pending");
   (d) anything the user must do personally (publish a Place, set an id, buy nothing);
   (e) whether the user's NEXT session should be AD-Integration — state it explicitly
   either way ("run Integration next" / "no Integration needed yet");
   (f) **a ready-to-paste NEXT SESSION PROMPT** (user rule, 2026-08-08) — ALWAYS, last in the
   reply, ONE copy-paste block: chat identity + Place, the ONE session-task, and the specific
   facts/paths/hazards it must not re-derive, plus bootstrap + landing requirements. Never end
   a session with only prose about what comes next.
   Discover a cross-Place dependency MID-session? Surface it at once, don't wait for landing.

## Ownership (single writer per system)

The full registry lives in `docs/OWNERSHIP.md` (system → owning chat → home Place →
canon location). Non-owners never edit another system's canon. Need a change? Write
`docs/proposals/<date>-<topic>.md` and add a PENDING to `STATE.md`; the owner picks it
up next session. Unlisted new system → add it to OWNERSHIP.md as part of building it.

## Editing rules (hard-won; violating these has caused real data loss)

- `execute_luau` runs in a SEPARATE VM with its own require cache. NEVER verify live
  service state through it — externally-required modules are empty copies that mimic
  data-loss bugs. Canonical verification: `[DIAG]` prints inside a real Script +
  `get_console_output`. Reading `.Source` / instance properties IS safe.
- Write WHOLE module files (multi_edit for targeted diffs, `.Source =` for rewrites).
  Never chain `gsub` edits; `%` in gsub replacements fails silently.
- All persistent edits in the **Edit** datamodel. Play mode is read-only observation.
- **Standing permission (user rule, 2026-08-06; extended 2026-08-09): any chat may run
  `start_stop_play` itself when verification needs it.** **Studio AUTOSAVES — do NOT ask the user
  to save first, just Play.** Stop when done and leave every `Dev*` harness attribute OFF.
- Console output lingers across Play sessions — correlate timestamps before trusting it.
  A Play session that dies in ~1s with `Server Kick Message: Error 500` is an ENVIRONMENT
  fault (an inserted free model caused it 2026-08-06), not your code — say so, don't "fix" code.
- After editing a shared module in Studio, its disk canon + manifest MUST be updated in
  the same session (landing checklist step 2). No exceptions.
- Log prefixes: `[DIAG]` debugging, `[DATA]` persistence, `[CONTRACT]` schema/version
  assertions, `[Test]` dev harness. Keep them grep-able.
- **NEVER generate UI in scripts** (user rule, 2026-07-18). Build ScreenGuis/Frames/labels
  as REAL Instances in StarterGui so the user can edit them in Studio. Dynamic lists use a
  designed `*Template` instance (Visible=false) that scripts clone and fill. Controllers
  only: read data, clone templates, set text/visibility, wire events. Legacy script-built
  screens get converted opportunistically when next touched.
- **Looks changed or unusual? ASK THE USER whether they did it** (user rule, 2026-08-16); never "fix" it.

## Blueprint discipline (how lesser sessions stay on the rails)

- `docs/blueprints/` contains implementation blueprints. For any feature they cover,
  the blueprint is LAW — like a contract. Read it BEFORE designing anything.
- Implement exactly ONE blueprint session-task per session. Do not batch ahead.
- Never improvise a different data shape, module name, or algorithm than the blueprint
  specifies. Blocked or convinced it's wrong? STOP → `docs/proposals/` + ask the user.
- Copy the cited reference modules' style. Prefer boring code. No refactors beyond the
  task's scope. When uncertain, ask the user — never invent.

## Contract-change protocol

1. Only the owner changes a contract, in a session where no sibling chat is active on it.
2. Bump the integer version (e.g. `SCHEMA_VERSION`), add migration, never edit old
   migrations.
3. Deploy + verify in the owner's Place.
4. Add `PENDING: <other place> must deploy <module> vN` to `STATE.md`.
5. The consumer chat clears the PENDING at its next bootstrap before other work.

## Doc size caps (keep bootstrap under ~3k tokens forever)

CLAUDE.md ≤150 lines · STATE.md ≤120 · CONTEXT.md ≤150 · contract ≤300 · system ≤300.
Over cap → split, register in `docs/INDEX.md`. Current-state docs describe NOW; history goes
to CHANGELOG/ADRs. New durable decision → one-page ADR in `docs/decisions/`.
**`STATE.md` is the documented exception to "split" (ADR-0006):** the bootstrap reads it for
PENDINGs, so it stays ONE file. Over 120 → **delete resolved PENDINGs** (their record is the
changelog); strikethrough `~~DONE~~` in the PENDING list is banned.
