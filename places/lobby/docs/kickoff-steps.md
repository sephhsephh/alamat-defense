# Lobby kickoff — user steps (do these in order)
<!-- owner: lobby | scope: lobby | last-verified: 2026-07-17 -->

## One-time setup (you, ~10 minutes)

1. **Publish the Game place now** (Studio, the "Alamat Defense" window: File → Publish to
   Roblox) so today's ProfileStore work is saved to Roblox.
2. **Create the Lobby place INSIDE the same Experience** — this is critical: Places in one
   Experience share DataStores, which is what lets one profile serve both Places.
   → create.roblox.com → Creations → Alamat Defense → Places → **Create Place** →
   name it "Alamat Defense - Lobby".
3. **Make the Lobby the start place** (players must land in the Lobby, not the Game):
   on the same Places page, set the Lobby as the Experience's start place. (If the
   dashboard doesn't allow switching, do it later — not blocking for development.)
4. **Enable Studio API access** (once per Experience, needed for real save tests):
   Game place Studio → File → Game Settings → Security → "Enable Studio Access to API
   Services" → ON → Save.
5. **Open the Lobby place in a second Studio window**: File → Open from Roblox →
   Alamat Defense - Lobby. Keep both Studio windows open.
6. **Start a new Claude chat** (this is the AD-Lobby chat — keep it long-lived):
   - Connect the same `alamat-defense` folder to it.
   - Make sure the Roblox Studio MCP is available in that chat.
7. **Paste this as the first message of the new chat** (updated 2026-07-17, post
   constitution v2 — this is the canonical AD-Lobby kickoff prompt):

   > You are the **AD-Lobby** chat for the Alamat Defense project (owner of the Lobby
   > scene/flow and the teleport contract — see docs/OWNERSHIP.md). The connected folder
   > `alamat-defense` is the project's single source of truth. Follow the bootstrap
   > ritual in `CLAUDE.md` EXACTLY, in order, before doing anything else. Resolve Place
   > binding to the Studio instance named "Alamat Defense - Lobby" and confirm the name
   > before any write. Then execute the first-session steps in `places/lobby/CONTEXT.md`:
   > clear the PENDING in STATE.md by deploying the shared modules from `shared/src/`
   > (plus the Signal dependency from the Game place — copy it via the repo, not by
   > guessing), verify hashes with `tools/hash_shared.luau` against `shared/manifest.json`,
   > update the manifest's `deployed.Lobby` column, build the minimal boot script, verify
   > `[DATA] [CONTRACT]` lines in Play mode (expect store=PlayerData_Dev), then LAND
   > (changelog + ROADMAP + commit) per the landing checklist. After landing, continue
   > with Lobby v1 in this order from docs/ROADMAP.md: blockout spawn area → read-only
   > collection screen (proves profile sharing end-to-end) → stage select + difficulty →
   > teleport handoff (finalize docs/contracts/teleport.md v0→v1, coordinate the Game-side
   > receiver as a PENDING for AD-Game). Ask me before any contract-affecting decision.

## What the AD-Lobby chat will do from there (no action from you)

Deploy shared canon → verify drift-free → minimal boot → then v1 scope from
`places/lobby/CONTEXT.md` (collection screen, stage select, teleport per
`docs/contracts/teleport.md`, which that chat owns and will finalize to v1).

## Rules of the road once two chats exist

- Parallel sessions are fine for Place-local work; contract/shared-module changes happen
  in ONE chat at a time (constitution: contract-change protocol).
- This chat (AD-Game) keeps owning the save schema; AD-Lobby owns the teleport contract.
- After the teleport handoff exists, run the first Integration session
  (`tools/checklists.md`) to test lobby → match → return end-to-end.
