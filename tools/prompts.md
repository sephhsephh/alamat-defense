# Reusable session prompts
<!-- Copy, fill the <PLACEHOLDERS>, send. Keep this file's prompts in sync with CLAUDE.md. -->

## Start a feature (AD-Game or AD-Lobby — the everyday prompt)

> You are the **<AD-Game | AD-Lobby>** chat for the Alamat Defense project. The connected
> `alamat-defense` folder is the single source of truth. Run the bootstrap ritual in
> `CLAUDE.md` exactly and in order — including the drift check and the **Integration
> gate**: before starting, tell me plainly either "Run an AD-Integration session BEFORE
> this task" or "No Integration needed — proceeding," and resolve any PENDINGs targeting
> your Place first. Then implement this feature:
>
> **<DESCRIBE THE FEATURE — what it does, where it lives, how I'll know it works>**
>
> Respect ownership (docs/OWNERSHIP.md): if any part belongs to another chat's system or
> requires a contract change, stop and ask me before touching it (proposal + PENDING
> instead). Verify live with [DIAG] prints + console before calling it done. Then land
> per the landing checklist and give me the full user advisory — new PENDINGs and who
> acts on them, other-Place staleness, git push status, anything I must do personally,
> and whether my next session should be AD-Integration.

## Integration session (AD-Integration)

> You are the **AD-Integration** chat — the only chat allowed to drive BOTH Studio
> instances. You reconcile, you don't build features. Run the bootstrap ritual in
> `CLAUDE.md`, then the Integration session agenda in `tools/checklists.md`: drift-check
> BOTH Places, deploy anything stale, clear every mechanical PENDING in STATE.md, verify
> [CONTRACT] logs on both sides, run the cross-Place end-to-end test if a flow changed,
> then land with the full user advisory.

## New subsystem chat (first message of AD-<System>)

> You are the **AD-<SYSTEM>** chat for the Alamat Defense project, owner of the systems
> listed for you in docs/OWNERSHIP.md (add your row if missing, as part of your first
> landing). The connected `alamat-defense` folder is the source of truth. Run the
> bootstrap ritual in `CLAUDE.md` exactly, resolve Place binding by task, state the
> Integration gate result, then: **<FIRST TASK>**. Land per the landing checklist with
> the full user advisory.
