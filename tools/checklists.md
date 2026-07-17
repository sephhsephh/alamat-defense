# Operational checklists (expanded from CLAUDE.md)

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
