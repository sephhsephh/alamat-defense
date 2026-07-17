# Alamat Defense — AI Knowledge Management System (AI-KMS)

**Architecture proposal for a multi-Place Roblox Experience developed primarily through Claude Desktop + Roblox Studio MCP.**
Version 1.0 — 2026-07-17

---

## 0. Problem analysis

Before proposing anything, it's worth naming what actually breaks when a single-Place, single-chat project becomes a multi-Place, multi-chat project.

**The chat is not the project.** Today, project knowledge lives in three fragile places: the conversation history (evaporates), Claude's per-project memory (summarized, lossy, single-project-scoped), and the live DataModel (authoritative for code, but expensive to rediscover — every "what does PlayerInventoryService do?" costs a tree search and several script reads). None of these can be shared between two chats pointed at two different Studio instances.

**Two Places create a distributed-systems problem.** The moment Lobby and Game exist separately, you have two mutating replicas of shared concepts (save schema, economy, tower configs, teleport payloads) with no shared memory between the agents editing them. Without a designed synchronization layer, drift is not a risk — it's a certainty. The failure mode is silent: Game changes the profile schema, Lobby keeps writing the old shape, and you discover it as a data-loss bug weeks later.

**Token economics dominate long-lived AI development.** Over months, the largest recurring cost is *rediscovery*: re-explaining architecture, re-searching the game tree, re-learning MCP gotchas (your `execute_luau` VM-cache trap alone has burned multiple sessions). A KMS succeeds or fails on whether a fresh chat can become productive from ~3k tokens of reading instead of ~50k tokens of exploration.

**The DataModel cannot be the single source of truth for the Experience.** It's the source of truth for *what runs in one Place*, but it can't hold cross-Place contracts, design intent, decision history, or anything the other Place needs to know. Conversely, Markdown docs can't be trusted to describe code unless something mechanically checks that they still do.

These four observations drive the whole design.

### Core architectural principle

**Disk is canon for knowledge and contracts. Studio is canon for runtime. Git is the ledger. Every chat is a Place-scoped worker governed by the same small constitution.**

Concretely: one local git repository on your machine holds all documentation, all cross-Place contracts, and the canonical source of every *shared* Luau module. Every Claude Desktop chat — Lobby chat, Game chat, future Tutorial chat — mounts this same folder. Each Studio instance holds a *deployed copy* of the shared modules, and a manifest of content hashes lets any chat mechanically detect when a Place has drifted from canon.

This is deliberately **not** a full Rojo/git migration. The professional default for Roblox studios is "all code lives on disk, Rojo syncs it in" — and if you were a team of human engineers I'd recommend exactly that. But your development interface is MCP writing directly into Studio, and that live-editing loop (edit → Play → `[DIAG]` → `get_console_output`) is your core productivity advantage. Forcing every edit through a disk→Rojo→Studio pipeline would add friction to 100% of edits to solve a problem that only affects the ~15% of code that is shared. The hybrid — disk-canon for shared modules and contracts, Studio-canon for Place-local code — captures almost all of the safety at almost none of the cost. If the project later gains human collaborators or CI, the repo structure below upgrades cleanly to full Rojo.

---

## 1. Where canonical knowledge lives

A single local git repository, e.g. `D:\Dev\alamat-defense\` (any stable path). It contains four kinds of canon:

1. **The constitution** (`CLAUDE.md`) — how any Claude chat must behave in this project: bootstrap ritual, landing checklist, editing rules, MCP gotchas.
2. **Contracts** (`docs/contracts/`) — the interfaces between Places and between client/server: save schema, remote events, teleport payloads, MessagingService topics, economy constants.
3. **Shared source** (`shared/src/`) — canonical `.luau` files for every module that exists in more than one Place, plus a manifest of deployment hashes.
4. **State and history** (`STATE.md`, `CHANGELOG.md`, `docs/decisions/`) — current snapshot, append-only session log, architecture decision records.

Do **not** use per-chat project knowledge, Claude memory, or the outputs folder as canon. Memory is a useful cache of *working style* (keep it), but it is lossy, unversioned, and invisible to other chats. Your current `alamat-defense-architecture.md` in the outputs folder migrates into this repo as seed content.

Optionally add a private GitHub remote for backup and history browsing. Not required for the system to work — everything below functions with local git alone.

## 2. How multiple Places access the knowledge

Every Claude Desktop chat connects the *same* repo folder. A chat's identity is then defined by two bindings:

- **Folder binding:** the `alamat-defense` repo (identical for all chats).
- **Studio binding:** which Roblox Studio instance it drives via `set_active_studio` (Lobby chat → Lobby Studio, Game chat → Game Studio).

The Lobby chat "always understands the current state of the Game" not by reading the Game's DataModel, but by reading `places/game/CONTEXT.md` and `STATE.md` — documents the Game chat is obligated (by the constitution) to keep current. This is the crucial inversion: **chats never inspect each other's Places; they read each other's published state.** Cheap, token-bounded, and it works even when the other Studio isn't open.

One useful exception: your MCP server supports `list_roblox_studios` / `set_active_studio`, so a single chat *can* drive both Studios. Reserve this for a dedicated **Integration session** (§13) rather than everyday work.

## 3. Versioning

Git, with Claude as the committer. Rules:

- Claude commits at the end of every session (and after any contract change) with a structured message: `[game] Add MatchEnd rewards; bump SaveSchema v3→v4`.
- Contract documents and the save schema carry explicit integer versions inside the file (`SCHEMA_VERSION = 4`), independent of git history — code checks versions at runtime; git is for humans and archaeology.
- Every doc has a small frontmatter header: `owner` (which Place/chat maintains it), `scope` (global | lobby | game), `last-verified` (date a chat last confirmed it matches reality).
- No branches. Single `main`, linear history. Branching is for parallel humans; your parallelism is handled by the ownership model (§9), and branch merges of prose are pure overhead here.

## 4. How documentation changes synchronize

Because all chats share one physical folder, synchronization of the *documents* is automatic — there is nothing to replicate. The real synchronization problem is **write conflicts** (two chats editing the same file in overlapping sessions) and **awareness** (chat B learning that chat A changed something). Both are solved by convention, enforced by the constitution:

- **Ownership writes:** a Place chat freely writes only its own `places/<place>/` docs and appends to `CHANGELOG.md`. Global docs and contracts are modified only through the contract-change protocol (§9).
- **Append-only changelog as the event bus:** every session ends by appending a dated entry. Because it's append-only, concurrent appends can't corrupt meaning, and reading entries newer than your own `last-seen` marker is how a chat catches up in a few hundred tokens.
- **Bootstrap always reads the tail of the changelog**, so awareness is guaranteed at session start without any push mechanism.

## 5. Stale-documentation detection

Docs rot when reality changes and the doc doesn't. Three mechanisms, cheapest first:

1. **Deployment manifest (mechanical).** `shared/manifest.json` maps every shared module to `{ sha1, deployedTo: { Lobby: sha1, Game: sha1 } }`. At bootstrap, the chat runs one `execute_luau` snippet that hashes the deployed shared modules in its Place and compares against the manifest (source hashing is a *read* of `.Source`, so the VM-cache trap doesn't apply). Any mismatch = drift, flagged before work begins. This turns the scariest failure (silent shared-code divergence) into a mechanical check costing one tool call.
2. **`last-verified` frontmatter (statistical).** Any doc whose `last-verified` predates the last N changelog entries touching its subject is suspect. The bootstrap ritual tells Claude to distrust and spot-check such docs before relying on them.
3. **Contract version assertions (runtime).** Shared modules embed their contract version; a startup script in each Place logs `[CONTRACT] SaveSchema v4` so mismatched deployments announce themselves in the console you already read via `get_console_output`.

## 6. Global vs Place-specific knowledge

**Global (in `docs/` and `shared/`):** save schema & ProfileStore template, economy constants and currency rules, tower/enemy config data shapes, inventory & loadout formats, remote/networking contracts, teleport payload contracts, MessagingService topics, design pillars, naming conventions, coding standards, the MCP gotcha list, ADRs.

**Place-specific (in `places/<place>/`):** scene/DataModel structure, Place-only services (MatchDirector, RewardCalculator in Game; matchmaking UI, shop browsing in Lobby), UI layouts, map data, Place-local known issues and TODOs.

**Litmus test:** *if the other Place's chat could ever make a wrong decision by not knowing this, it's global.* When in doubt, global — the cost of an unnecessary global doc is a few tokens; the cost of a wrongly-local one is drift.

## 7. Bootstrap protocol (minimal-context startup)

Three-tier progressive disclosure. A fresh chat reads Tier 0 unconditionally (~2–3k tokens) and pulls deeper tiers only when the task demands:

- **Tier 0 (always):** `CLAUDE.md` (constitution, ≤150 lines) → `STATE.md` (current snapshot, ≤100 lines) → `places/<my-place>/CONTEXT.md` (≤150 lines) → tail of `CHANGELOG.md` since last session. Then run the manifest drift check (§5).
- **Tier 1 (task-relevant):** the specific contract or system doc the task touches, located via one-line summaries in `docs/INDEX.md`. Never read all docs.
- **Tier 2 (archival, rarely):** ADRs, old changelog, session journals. Exists so history is *recoverable*, not so it's *read*.

The result: a brand-new chat is fully productive — knows the architecture, the other Place's state, the pending contract changes, and the live drift status — for under 5k tokens and about four file reads plus one MCP call. No game-tree exploration, ever, except when docs are flagged stale.

## 8. Automatic documentation updates ("landing checklist")

Documentation maintenance is made Claude's job by embedding it in the constitution as a mandatory end-of-session ritual. Because every chat reads `CLAUDE.md` at bootstrap, every chat inherits the obligation:

1. Update `places/<place>/CONTEXT.md` and any system docs touched by this session's work.
2. If a shared module changed: update `shared/src/`, recompute hashes, update `manifest.json`, note un-deployed Places.
3. If a contract changed: bump its version, record the change in the contract doc, add a `PENDING` notice (§9).
4. Append a `CHANGELOG.md` entry: date, place, what changed, contract impacts, open threads.
5. Refresh `STATE.md` if the project-level picture moved.
6. `git add -A && git commit`.

Your only manual duty is saying "let's land this" (or ending sessions cleanly); Claude does the rest. Mid-session, after any *milestone* (verified feature), Claude should do a micro-land (changelog entry + commit) so a crashed Studio or abandoned chat loses minutes, not a session.

## 9. Conflict resolution between Places

Prevent structurally, detect mechanically, resolve procedurally:

- **Single-writer ownership.** Every shared system has exactly one *owning* Place listed in its doc header (e.g., save schema → Game, shop catalog → Lobby). Only the owner's chat edits the canonical file. The other Place *consumes* via the contract doc. Most "conflicts" disappear because two writers never exist.
- **Contract-change protocol.** When the owner must change a shared contract: bump version → document old→new and migration notes → mark `PENDING: awaiting Lobby deploy` in the contract doc and changelog → deploy to its own Place. The consumer chat sees the PENDING flag at next bootstrap (guaranteed by Tier 0) and performs its side before other work. `STATE.md` lists all open PENDINGs so nothing lingers invisibly.
- **Non-owner needs a change?** It writes a short proposal to `docs/proposals/`, and you (or the owning chat next session) accept it. This is the one place a human decision is occasionally needed — appropriately, since cross-cutting contract changes are exactly what you'd want to see anyway.
- **Backstop:** if both chats somehow edit one file in overlapping sessions, git's dirty state makes it visible at commit time, and the changelog shows who did what. Resolution is a five-minute reconciliation, not archaeology.
- **Serialize when it matters.** For sessions that will touch contracts, work one chat at a time. Parallel chats are safe for Place-local work, which is most work.

## 10. Keeping shared systems synchronized

Shared *code* (not just shared knowledge) gets the strongest guarantee in the system:

- **One canonical file per shared module** in `shared/src/` (e.g., `SaveSchema.luau`, `EconomyConfig.luau`, `TowerConfig.luau`, `Net.luau` remote definitions, future `ProfileTemplate.luau`). Places contain byte-identical deployed copies under `ReplicatedStorage/Shared/`.
- **Deployment is a script, not a vibe.** `tools/deploy_shared.luau` is an `execute_luau` snippet that writes canonical source into the active Studio's `ReplicatedStorage/Shared` and reports resulting hashes; Claude then updates `manifest.json`. Deploying to the other Place is either that Place's chat running the same tool at next bootstrap (it sees the stale hash), or one Integration session driving both Studios.
- **ProfileStore fit (future).** ProfileStore's core artifact — the profile template plus reconciliation — is *exactly* a shared contract: define `ProfileTemplate.luau` with `SCHEMA_VERSION` and append-only migration functions in `shared/src`, document it in `docs/contracts/save-schema.md`, give ownership to Game. Both Places require the same deployed module, so `Profile.Data` shape can never diverge between Lobby (reads/shop writes) and Game (match rewards). Session-locking semantics (one Place owns the profile at a time) get their own contract doc section, since teleport handoff is where ProfileStore bugs live.
- **Cross-Place messaging** (TeleportData payloads, MessagingService topics) is defined only in `docs/contracts/` with versioned payload shapes; both Places validate the version field at the boundary and log `[CONTRACT]` mismatches loudly.
- **Roblox Packages alternative:** Roblox's native Package system can also distribute shared modules across Places with update notifications. It's a reasonable *deployment* mechanism, but it makes the canonical source live inside Roblox's opaque versioning instead of your git repo, and MCP can't diff package versions the way it can diff files. Use Packages for shared *assets* (tower rigs, VFX) where git can't hold the content anyway; keep shared *code* canon on disk.

## 11. Recommended folder structure

**The repo (single source of truth):**

```
alamat-defense/
├── CLAUDE.md                  # Constitution: bootstrap ritual, landing checklist,
│                              #   editing rules, MCP gotchas. ≤150 lines. Rarely changes.
├── STATE.md                   # Live snapshot: current focus, open PENDINGs,
│                              #   per-Place one-paragraph status. ≤100 lines.
├── CHANGELOG.md               # Append-only session ledger (rotate yearly to archive/).
├── docs/
│   ├── INDEX.md               # One line per doc; Tier-1 lookup table.
│   ├── design/                # pillars.md, economy.md, progression.md, stages-acts.md
│   ├── contracts/             # save-schema.md, remotes.md, teleport.md,
│   │                          #   messaging.md, economy-constants.md
│   ├── systems/               # One doc per major system: towers.md, inventory.md,
│   │                          #   match-flow.md, rewards.md ...
│   ├── decisions/             # ADR-0001-hybrid-canon.md, ADR-0002-profilestore.md ...
│   └── proposals/             # Cross-place change requests awaiting acceptance.
├── shared/
│   ├── src/                   # Canonical .luau for every multi-Place module.
│   └── manifest.json          # module → {sha1, deployedTo: {Lobby, Game}}
├── places/
│   ├── lobby/
│   │   ├── CONTEXT.md         # Bootstrap doc: services, scene layout, conventions,
│   │   │                      #   known issues, current TODOs. ≤150 lines.
│   │   └── docs/              # Deeper lobby-only docs as needed.
│   └── game/
│       ├── CONTEXT.md
│       └── docs/
├── tools/
│   ├── deploy_shared.luau     # execute_luau: write canon → ReplicatedStorage/Shared.
│   ├── hash_shared.luau       # execute_luau: hash deployed modules for drift check.
│   └── checklists.md          # Landing checklist, contract-change protocol, expanded.
└── archive/                   # Rotated changelogs, session journals, superseded docs.
```

Adding a Place (Tutorial, Trading Hub, Event World) = `mkdir places/tutorial`, write its `CONTEXT.md`, add a column to `manifest.json` deploy targets, open a new chat bound to its Studio. Nothing else changes — the system is O(1) per new Place.

**In-Studio structure (each Place, mirrored conventions):**

```
ReplicatedStorage/
├── Shared/          # Deployed copies of shared/src — never hand-edited here;
│                    #   edits happen in canon and are re-deployed.
├── Config/          # Place-local config modules.
└── Remotes/         # Instances per docs/contracts/remotes.md naming.
ServerScriptService/
├── Services/        # Place-local services (Game: MatchDirector, RewardCalculator…)
└── Bootstrap/       # Startup + [CONTRACT] version logging.
StarterGui / StarterPlayerScripts …   # per Place, documented in its CONTEXT.md
```

The parallel conventions matter: a chat that has worked in one Place already knows how to navigate the other, which cuts rediscovery when you eventually cross-train chats.

## 12. Documentation structure (per-document rules)

Six document types, each with a job and a size cap — caps are what keep Tier-0 bootstrap under 3k tokens forever:

| Type | Job | Cap | Update cadence |
|---|---|---|---|
| Constitution (`CLAUDE.md`) | How chats behave | 150 lines | Rarely; treat edits like law changes |
| Snapshot (`STATE.md`) | What's true *now* | 100 lines | Every landing |
| Context (`places/*/CONTEXT.md`) | Bootstrap a Place chat | 150 lines | Every landing that touched the Place |
| Contract (`docs/contracts/*`) | Exact interface + version + history | 300 lines | Only via contract-change protocol |
| System (`docs/systems/*`) | How one system works & why | 300 lines | When the system changes |
| ADR (`docs/decisions/*`) | Why we chose X over Y | 1 page, immutable | Written once |

Formatting rules baked into the constitution: frontmatter on every doc (`owner / scope / last-verified`); current-state docs describe *now* and push history into ADRs/changelog (docs that accrete history become unreadable and token-expensive); code shapes shown as typed Luau snippets, not prose; when a doc hits its cap, split it and register both halves in `INDEX.md`.

## 13. Development workflow

**Standard solo session (one Place):**
1. Open the Place's chat → Tier-0 bootstrap (§7) → drift check.
2. If PENDING contract work targets this Place, do it first.
3. Work the feature via the existing MCP loop (edit in `Edit` datamodel → Play → `[DIAG]` → `get_console_output`).
4. Micro-land after each verified milestone; full landing checklist (§8) at session end.

**Parallel sessions (Lobby + Game simultaneously):** allowed whenever both sessions are Place-local. Both append to the changelog; neither touches `docs/contracts/` or `shared/`. If mid-session one chat discovers it needs a contract change, it writes a proposal and continues with local work — it does not hot-edit shared canon while a sibling is live.

**Contract-change session (serialized):** run in the owning Place's chat alone. Change canon → bump version → deploy locally → verify → mark PENDING for other Places → land. The consumer chat picks up the PENDING at its next bootstrap.

**Integration session (weekly-ish, or after big contract changes):** one chat, both Studios open, using `list_roblox_studios`/`set_active_studio`. Agenda: drift-check both Places, deploy any stale shared modules, run the cross-Place flow end-to-end (lobby → teleport → match → rewards → return), verify `[CONTRACT]` logs on both sides, clear PENDINGs, land. This session is the system's immune response — it guarantees drift never survives longer than one integration cycle.

**Doc-gardening session (monthly):** Claude sweeps for cap violations, stale `last-verified` dates, contradictions between docs and code, and changelog rot; consolidates and commits. This is what makes the system viable over *years*, not months — knowledge bases don't die from missing entries, they die from unpruned ones.

## 14. Roblox Studio MCP limitations & workarounds

| Limitation | Consequence | Workaround (encode all of these in `CLAUDE.md`) |
|---|---|---|
| `execute_luau` runs in a separate VM with its own `require` cache | External reads of live services return empty/stale instances that mimic data-loss bugs (has burned multiple sessions) | Never verify live state via `execute_luau` requires. Canonical path: `[DIAG]` prints inside real Scripts + `get_console_output`. Reading `.Source` and instance properties is safe. |
| `gsub` replacement strings choke on `%`; chained partial edits have silently reverted | Corrupted or lost source edits | Write whole module files; for anchored insertion use `find` + concat. Shared modules additionally get hash-verified after write. |
| Edit vs Server datamodel split; stopping Play discards server-side edits | Work done in the wrong datamodel evaporates | All persistent edits in `Edit` datamodel; treat Play as read-only observation. |
| Stale console output lingers across Play sessions | Misdiagnosis from old logs | Timestamp-correlate `[DIAG]` output; explicit waits before reads. |
| No transactionality — a multi-step change can be half-applied when Studio hiccups or a chat dies | Inconsistent Place state | Micro-landings; `manifest.json` hashes make half-deployed shared modules detectable; Bootstrap `[CONTRACT]` logs make them loud. |
| MCP sees one Studio's DataModel at a time; no cross-Place queries | A chat can't directly inspect the sibling Place | By design: chats read each other's *published docs*, never each other's DataModels (§2). Integration sessions cover the rare need for both. |
| No git/file awareness inside Studio; no reliable full-place export | Place-local *code* isn't in version control | Accepted trade-off of the hybrid (§0). Roblox's own version history + published Places are the backstop for Place-local code; everything shared or contractual *is* in git. Optionally, gardening sessions can snapshot key Place-local services' `.Source` into `places/*/docs/src-snapshots/` for reference-grade (not canonical) history. |
| Tree searches and bulk script reads are token-expensive | Rediscovery cost balloons | The entire Tier-0/manifest design exists to make exploration the exception. Docs are the index; the DataModel is consulted surgically. |

## 15. Additional recommendations

**Adopt ProfileStore before the Place split ships, not after.** Retrofitting a save-schema contract onto two live Places is far harder than splitting Places on top of an already-contractual schema. Define `ProfileTemplate.luau` + `SCHEMA_VERSION` + migration convention now, while there's still one Place.

**Give every log line a grep-able prefix** (`[DIAG]`, `[CONTRACT]`, `[ECON]`, `[SAVE]`) and document the vocabulary in the constitution. `get_console_output` is your primary sensor; structured logs make it dramatically cheaper to use.

**Seed `docs/systems/` from your existing architecture doc** rather than writing fresh — the current `alamat-defense-architecture.md` becomes the first gardening session's raw material, split into capped system docs.

**Keep Claude memory, but demote it.** Memory should hold durable *working-style* knowledge (your preferences, the MCP gotchas as reflex). Project *facts* belong in the repo where all chats see them. When memory and repo disagree, the repo wins — state this in the constitution.

**Name chats by binding** ("AD-Lobby", "AD-Game", "AD-Integration") and keep them long-lived rather than starting fresh chats casually; bootstrap is cheap but not free.

**Write ADRs for exactly the decisions you'd otherwise re-litigate.** The first three: this hybrid canon model, the ProfileStore ownership/session-lock design, and the teleport payload contract. Six months from now, "why don't we just use Packages for code?" gets answered by a one-page read instead of a re-derivation.

**Plan for a test/staging Place** once ProfileStore lands: a copy of Game pointed at a separate DataStore scope, so schema migrations get rehearsed by an Integration session before touching real player data. It slots into the system as just another `places/` entry.

---

## Summary of guarantees

If the constitution is followed, the system guarantees: any chat reaches full productivity in ~5k tokens with zero DataModel exploration; shared-code divergence between Places is mechanically detectable in one tool call and cannot silently persist past an integration cycle; every contract change is versioned, attributed, and visibly PENDING until every Place deploys it; all knowledge survives any chat, any Studio crash, and any amount of elapsed time; and your manual workload reduces to directing features, approving cross-place proposals, and saying "land it."
