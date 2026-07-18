# Alamat Defense — Constitution (read first, every session)

This repo is the **single source of truth** for the Alamat Defense Experience (all Places:
Game, Lobby, future Tutorial/Event Worlds). Rules here bind every Claude chat working on
any Place. When this repo and anything else disagree (chat memory, in-Studio docs), **the
repo wins** — except live code in Studio, which is canon for Place-local runtime behavior.

**Canon model:** disk is canon for knowledge, contracts, and shared module source. Studio
is canon for Place-local code and runtime. Git is the ledger.

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
4. Read `CHANGELOG.md` entries newer than your last session — this is the event bus;
   other chats' landings appear here. Adapt to anything that touches your system.
5. **Drift check:** run `tools/hash_shared.luau` via `execute_luau` against your Place;
   compare with `shared/manifest.json`. Mismatch = STOP, reconcile before any work.
6. If `STATE.md` lists a PENDING targeting your Place or system, do that first.
7. **Integration gate (answer it out loud, every session):** after steps 1–6, tell the
   user explicitly either "Run an AD-Integration session BEFORE this task" or "No
   Integration needed — proceeding." Triggers in `tools/checklists.md`; the short form:
   drift-check mismatch, a PENDING that needs the OTHER Place, an undeployed contract or
   shared-module change in the changelog, or a task that spans both Places.

## Multi-chat synchronization (many chats, one truth)

- `CHANGELOG.md` is the event bus: APPEND-only, newest first, one entry per landing.
- **Re-read `STATE.md` + the changelog tail immediately BEFORE landing** — a sibling chat
  may have landed mid-session. Merge your entry on top; never overwrite theirs.
- Single-writer: only the owner (OWNERSHIP.md) edits a system's code/docs/contracts.
  Everyone else writes `docs/proposals/` + a PENDING.
- Two chats must NOT live-edit the same Place at the same time unless their systems are
  disjoint. Contract or shared-module changes: strictly ONE chat at a time, no exceptions.
- On any git conflict or unexpected dirty state: stop, read `git status` + changelog,
  reconcile, then land.

Do not explore the game tree for orientation — the docs are the index. Explore only for
the specific thing you're changing, or when a doc is flagged stale.

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
   either way ("run Integration next" / "no Integration needed yet").
   If a cross-Place dependency is discovered MID-session, surface it immediately — do
   not wait for landing.

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
- Console output lingers across Play sessions — correlate timestamps before trusting it.
- After editing a shared module in Studio, its disk canon + manifest MUST be updated in
  the same session (landing checklist step 2). No exceptions.
- Log prefixes: `[DIAG]` debugging, `[DATA]` persistence, `[CONTRACT]` schema/version
  assertions, `[Test]` dev harness. Keep them grep-able.
- **NEVER generate UI in scripts** (user rule, 2026-07-18). Build ScreenGuis/Frames/labels
  as REAL Instances in StarterGui so the user can edit them in Studio. Dynamic lists use a
  designed `*Template` instance (Visible=false) that scripts clone and fill. Controllers
  only: read data, clone templates, set text/visibility, wire events. Legacy script-built
  screens get converted opportunistically when next touched.

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

CLAUDE.md ≤150 lines · STATE.md ≤100 · CONTEXT.md ≤150 · contract ≤300 · system ≤300.
Over cap → split, register in `docs/INDEX.md`. Current-state docs describe NOW; history
goes to CHANGELOG/ADRs. New durable decision → one-page ADR in `docs/decisions/`.
