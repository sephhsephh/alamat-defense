# ADR-0006 — `STATE.md` stays ONE file; the cap is 120 lines and resolved PENDINGs leave immediately

<!-- decided: 2026-08-06 (A7, AD-Integration) | status: ACCEPTED, applied in the same session -->

## Context

`CLAUDE.md`'s doc-size caps say `STATE.md ≤ 100` and "over cap → split, register in
`docs/INDEX.md`". `STATE.md` has been over that cap for four sessions (134 lines at A7) and every
session noticed it and deferred it, because the obvious remedy is wrong:

**The bootstrap ritual reads `STATE.md` for open PENDINGs (step 2).** Splitting the PENDINGs into a
second file means every chat must now read two files or silently miss a PENDING targeting its
Place. A PENDING that nobody reads is worse than a long file — the whole multi-chat
synchronisation model rests on that one read.

So the question is not "how do we split it" but "why does it grow".

## What actually made it grow

Not the number of live PENDINGs. At A7 the file held **five** open PENDINGs and **four
struck-through, already-resolved ones** (`~~PENDING: template hashing~~ **DONE**`, the kit
promotion, the Game hotbar, `Data.Loadout`'s missing writer). Those four cost ~30 lines — roughly
the entire overage — and each one duplicated a `CHANGELOG.md` entry written the same day.

They were kept for a good reason (a reader can see that a thing they remember is now done) and a
bad one (nobody wanted to delete another session's work). But `STATE.md`'s own header already says
"Resolved PENDINGs live in `CHANGELOG.md` (this list is CURRENT-state only)". The file was
violating its own rule.

## Decision

1. **`STATE.md` is NOT split.** It stays the single file the bootstrap ritual reads. The ritual is
   unchanged, so no chat has to learn a new procedure.
2. **The cap moves 100 → 120 lines**, updated in `CLAUDE.md`. 100 was set before schema v2, the UI
   kit and 24 drift entries existed; 120 is honest headroom for the project's actual current-state
   surface, and still well inside the ~3k-token bootstrap budget.
3. **A resolved PENDING is DELETED from `STATE.md` in the session that resolves it**, not struck
   through. Its record is the `CHANGELOG.md` entry, which is append-only and is already read at
   bootstrap step 4. Strikethrough entries are banned in the PENDING list.
4. **Sections that duplicate a canon doc carry a pointer, not a copy.** Contract detail lives in
   `docs/contracts/*.md`; `STATE.md` carries version numbers and store names only. Feature status
   lives in `docs/ROADMAP.md`; `STATE.md` carries only what the NEXT session should pick up.

## Consequences

- The next chat over 120 lines has a cheap first move that is now explicitly sanctioned: delete
  resolved PENDINGs (they are in the changelog) before considering anything structural.
- Some history becomes one hop away instead of visible in `STATE.md`. Accepted: `CHANGELOG.md` is
  append-only and read at every bootstrap anyway, so nothing is lost, only relocated.
- If `STATE.md` ever exceeds 120 with genuinely open PENDINGs, that is a signal about the PROJECT
  (too much unfinished work in flight), not about the document — and the right response is to
  close PENDINGs, not to split the file. Revisit this ADR only if that happens.
- The generic "over cap → split" rule in `CLAUDE.md` still applies to every other capped doc
  (`CONTEXT.md`, contract, system docs). `STATE.md` is the documented exception because the
  bootstrap ritual depends on its single-file identity.
