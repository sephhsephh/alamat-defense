# Alamat Defense — Constitution (read first, every session)

This repo is the **single source of truth** for the Alamat Defense Experience (all Places:
Game, Lobby, future Tutorial/Event Worlds). Rules here bind every Claude chat working on
any Place. When this repo and anything else disagree (chat memory, in-Studio docs), **the
repo wins** — except live code in Studio, which is canon for Place-local runtime behavior.

**Canon model:** disk is canon for knowledge, contracts, and shared module source. Studio
is canon for Place-local code and runtime. Git is the ledger.

## Identity

Each chat is bound to ONE Place and this ONE repo:
- **AD-Game** → Studio "Alamat Defense" (the Game place) + this repo
- **AD-Lobby** → Studio Lobby place + this repo
- **AD-Integration** → BOTH Studios (shared-module deploys and cross-Place testing only)

## Bootstrap ritual (mandatory, in order)

1. Read this file.
2. Read `STATE.md` (project snapshot + open PENDINGs).
3. Read `places/<my-place>/CONTEXT.md`.
4. Read `CHANGELOG.md` entries newer than your last session.
5. **Drift check:** run `tools/hash_shared.luau` via `execute_luau` against your Place;
   compare with `shared/manifest.json`. Mismatch = STOP, reconcile before any work.
6. If `STATE.md` lists a PENDING targeting your Place, do that first.

Do not explore the game tree for orientation — the docs are the index. Explore only for
the specific thing you're changing, or when a doc is flagged stale.

## Landing checklist (mandatory at session end + after each verified milestone)

1. Update `places/<my-place>/CONTEXT.md` and any touched system docs.
2. Shared module changed? → update `shared/src/`, rehash, update `manifest.json`,
   set other Places' `deployed` to their now-stale hash (leave as-is) and add a PENDING.
3. Contract changed? → bump its version, document old→new + migration, add PENDING
   in the contract doc AND in `STATE.md`.
4. Append a `CHANGELOG.md` entry (date, place, what, contract impact, open threads).
5. Refresh `STATE.md` if the project-level picture moved.
6. `git add -A && git commit -m "[<place>] <summary>"`.
7. Mirror the essentials into the Place's `ServerStorage.Documentation` (AIState +
   RecentChanges) until that in-Studio doc set is fully retired.

## Ownership (single writer per shared system)

| System | Owner | Canon location |
|---|---|---|
| Save schema / ProfileTemplate | Game | `shared/src/ProfileTemplate.luau` + `docs/contracts/save-schema.md` |
| PlayerDataService / ProfileStore | Game | `shared/src/` |
| Teleport payload contract | Lobby | `docs/contracts/teleport.md` |
| Economy constants, tower/progression configs | Game | Studio (Game) until exported to `shared/` |
| Shop/banner catalog (future) | Lobby | TBD when built |

Non-owners never edit shared canon. Need a change? Write `docs/proposals/<date>-<topic>.md`
and add a PENDING to `STATE.md`; the owner picks it up next session.

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
