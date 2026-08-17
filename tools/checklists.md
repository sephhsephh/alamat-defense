# Operational checklists (expanded from CLAUDE.md)

## Reading the CHANGELOG (and anything else large) without burning the session

`CHANGELOG.md` is ~4.5k lines / ~90k tokens. Reading it whole once costs more than most
sessions' entire useful output. It is **newest-first**, so what you want is at the TOP —
`tail` hands you 2026-07 archaeology. **The `## ` entry headers ARE the index** (each is a
written one-line summary), so there is no second index to maintain or let rot.

Recipes — use one of these, never a whole-file read:

- **Catch up since your last session** (the bootstrap step): `grep -n '^## ' CHANGELOG.md | head -12`,
  find the line where the counter you already know (e.g. `B27d`) starts, then
  `sed -n '1,<that line minus 1>p' CHANGELOG.md`. Nothing older ever enters context.
- **"Did a sibling land while I worked?"** (pre-landing re-read): `sed -n '1,3p' CHANGELOG.md`.
  Three lines is the whole check.
- **Orientation with no detail:** `grep -n '^## ' CHANGELOG.md | head -15`. ~15 lines buys you
  four sessions of history, because the headers are full summaries.
- **History of one subject:** `grep -n -i '<term>' CHANGELOG.md | head`, then `sed -n 'A,Bp'`
  on the ONE entry that matters (find B from the next `^## ` line number).
- **Which landing touched a module:** `grep -n '<ModuleName>' CHANGELOG.md | head`.

Rules that generalise past the changelog:

- An entry is 60–150 lines. Read ONE. Reading five needs a reason you can state.
- **Never `Read`/`cat` any file over ~200 lines to find something.** `grep -n` → `sed -n 'A,Bp'`.
- `docs/ROADMAP.md` (451 lines): `grep -n '<system>' docs/ROADMAP.md` and edit that row. Never
  read the whole board to flip one row.
- `docs/design/ai-kms-architecture.md` is Tier-2 rationale: read it only when CHANGING how the
  doc system works, never for orientation.
- Confirm a size cap with `wc -l`, not by reading the file.
- Escalate cost in this order, and stop as soon as you have the answer: (1) `STATE.md` +
  `places/<place>/CONTEXT.md`, which are current-state by design; (2) `grep` the changelog;
  (3) read ONE changelog entry's line range; (4) a system doc / ADR / proposal — its section,
  not the file. Most questions are answered at step 1 and asked at step 4.

## Integration gate — evaluated by EVERY chat at bootstrap (constitution step 7)

After the bootstrap ritual, the chat MUST tell the user one of, verbatim style:
- **"Run an AD-Integration session BEFORE this task"** — if ANY trigger below fires and
  the task depends on it, and the fix is not something this chat can do alone; or
- **"No Integration needed — proceeding."**

Triggers (any one is enough):
1. `tools/hash_shared.luau` result mismatches `shared/manifest.json` for THIS Place
   (drift), or the manifest shows another Place's `deployed` hash is stale/null and the
   task touches that shared module or its consumers.
2. `STATE.md` has an open PENDING that must be executed in the OTHER Place (or in both)
   before this task's output would be consistent — e.g. an undeployed schema bump,
   an unbuilt contract counterpart, an unset cross-place id.
3. `CHANGELOG.md` shows a contract version bump or shared-module change newer than the
   other Place's last landing (the other side has not adapted yet).
4. The requested task itself spans both Places (build one side + verify the other):
   route it as owner-chat work + an Integration follow-up, and say so.
5. A cross-Place end-to-end flow (teleport loop, profile handoff) has changed since the
   last Integration session and the task builds ON TOP of that flow.

If a trigger fires but the task is fully independent of it (e.g. pure UI polish in this
Place), the chat may proceed — but must still REPORT the pending Integration need in the
bootstrap message AND repeat it in the landing advisory (step 8e).

## GitHub sync (backup remote)

One-time setup is done by the user (see below). After that, ANY chat's landing checklist
may end with `git push` — if it fails for auth reasons in the sandbox, leave the commit
local and note "push pending" in the changelog entry; the user pushes via GitHub Desktop
or terminal. Local commits are the ledger; the remote is backup, never a second canon.

User one-time setup:
1. github.com → New repository → name `alamat-defense`, **Private**, and do NOT add a
   README/.gitignore/license (the repo already has history).
2. Install git for Windows (git-scm.com) or GitHub Desktop if not installed.
3. Terminal in `Documents\alamat-defense`:
   `git remote add origin https://github.com/<your-username>/alamat-defense.git`
   `git push -u origin main`  (browser sign-in prompt appears the first time)
4. Thereafter: `git push` after sessions (or Push origin in GitHub Desktop).

## Deploying a shared module into a Place

1. Read the canonical file from `shared/src/<Module>.luau` (Read tool — exact bytes).
2. Ensure the deploy path's parent folders exist (create via execute_luau, Edit DM).
3. Write the source verbatim onto the target ModuleScript (`.Source =` via execute_luau
   with `[==[ ]==]` delimiters, or multi_edit full-file). NO local modifications, ever —
   Place-specific behavior belongs in Place-local wrappers, not in the shared module.
4. Run `tools/hash_shared.luau`; the hash MUST equal the manifest's file hash.
5. Update `shared/manifest.json` → `deployed.<Place>` with that hash.
6. Changelog entry + commit.

Dependency note: `PlayerDataService` requires `ReplicatedStorage.Shared.Signal` — the
Signal module must exist in the Place first (copy from the Game place; consider promoting
Signal itself into `shared/src` at that moment).

## Deploying a shared TEMPLATE (GuiObject) into a Place

Templates are drift-checked since 2026-08-06 (**ADR-0005**), but they cannot be written from a
text file the way a module can — `shared/src/` holds no copy of them. The Instance itself is the
canon, and the hash is what makes copying it verifiable.

1. In the SOURCE Place, run `tools/hash_shared.luau` and note the template's hash (trailing `*`).
2. **ASK THE USER TO COPY IT. THIS STEP IS A *USER* ACTION, NOT A TOOL ACTION.** An assistant
   cannot copy an Instance from one Place into another: `execute_luau` is scoped to ONE datamodel,
   so `:Clone()` + reparent works *within* a Place and cannot cross Places at all. **PAUSE, tell the
   user the exact source path, the exact destination path and the hash to expect, and wait.** (User
   rule, B26 2026-08-16, stated verbatim: *"if you want to copy the v2 ui kits on game place, tell
   it to me, dont try to copy it ... pause, ask me to copy paste it to other place then ill tell you
   to continue."*) Never rebuild it by hand — that is the divergence this mechanism exists to catch.
   The one assistant-side alternative is an IDENTICAL DETERMINISTIC BUILD SCRIPT run in both Places
   and hash-matched (used once, for `Kit_UnitIcon`); it is strictly harder to get right than asking.
3. Run the tool in the TARGET Place. The hash MUST equal the source's, exactly.
4. Update `shared/manifest.json` → that template's `deployed.<Place>`.
5. If the hashes differ, do NOT "fix it up" by eye: re-copy. A mismatch means the trees really
   differ somewhere in the whitelisted surface.

Note: adding a property to the whitelist in `hash_shared.luau` changes **every** template hash at
once. Treat that like a schema bump — land it in one Integration session, redeploy, and say so in
the changelog so it is not mistaken for drift.

## Editing a shared module (owner only)

1. Confirm you own it (constitution table) and no sibling chat is mid-session on it.
2. Edit in your Studio, verify live.
3. Copy the exact final Source into `shared/src/`, rehash, update manifest (your Place's
   `deployed` = new hash; others keep their old hash → visible drift → add PENDING).
4. If the change is contractual (schema/payload shape): bump version + migration + doc.
5. Changelog + STATE PENDING + commit.

## Integration session agenda (run after any contract change; else ~weekly)

1. `list_roblox_studios` → confirm both Places connected.
2. Drift-check each Place (`set_active_studio` + hash_shared).
3. Deploy any stale shared modules; clear PENDINGs in STATE.md.
4. Cross-Place smoke test (once teleport exists): lobby → launch → match → rewards →
   return; verify `[CONTRACT]` lines on both sides.
5. Land (changelog, STATE, commit).

## Doc-gardening session agenda (~monthly)

1. Check size caps; split violators; update INDEX.md.
2. Find `last-verified` dates older than the last 5 changelog entries touching that
   subject; spot-check those docs against code; fix or re-stamp.
3. Migrate one or two docs from the Game place's ServerStorage.Documentation into
   `docs/systems/` (migrate-on-touch also applies during normal sessions).
4. Trim CHANGELOG: rotate entries older than ~3 months **or beyond ~5k lines, whichever
   comes first**, into `archive/CHANGELOG-<period>.md`. Bootstrap cost scales with this file.
5. Commit.
