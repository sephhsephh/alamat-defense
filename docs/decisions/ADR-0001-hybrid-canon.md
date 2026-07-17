# ADR-0001: Hybrid canon (disk for shared/contracts, Studio for Place-local code)

**Date:** 2026-07-17 · **Status:** Accepted

## Decision

The repo is canon for documentation, cross-Place contracts, and the source of shared
modules (hash-manifested, deployed into each Place). Each Place's Studio DataModel stays
canon for its Place-local code. We do NOT migrate to full Rojo/git-managed source.

## Why

Development runs through Claude Desktop + Roblox Studio MCP; the live loop (edit in Edit
DM → Play → `[DIAG]` → console) is the core productivity advantage. Full Rojo would tax
100% of edits to protect the ~15% of code that is shared. Only shared code and contracts
can silently diverge between Places — so only they get the disk-canon + hash-drift-check
guarantee. Docs must live on disk regardless: they're the only medium every chat can see.

## Consequences

- Place-local code has no git history; Roblox version history + published places are the
  backstop. Gardening sessions may snapshot key `.Source` files as reference (non-canon).
- Every shared-module edit requires the manifest update in the same session (constitution).
- Upgrade path to full Rojo stays open: `shared/src` is already Rojo-shaped.
