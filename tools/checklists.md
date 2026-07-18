# Operational checklists (expanded from CLAUDE.md)

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
4. Trim CHANGELOG (rotate entries older than ~3 months to `archive/`).
5. Commit.
