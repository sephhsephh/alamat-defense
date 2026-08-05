# ADR-0004 — Retire `LobbyServices.GetCollection` in favour of `GetUnitViews`

<!-- decided: 2026-08-06 (A6b, AD-Lobby) | status: ACCEPTED, execution scheduled for A7 -->

## Context

`GetCollection` was the Lobby's original profile read path. Since A4/A5 every screen reads
the `GetUnitViews` view-model instead:

- **UnitsGUI** → `GetUnitViews` at A4
- **CollectionScreen** → rebuilt on `GetUnitViews` at A5
- **ItemsGUI** → `GetUnitViews` (`Items`) at A5

At A6b the interim `Towers` / `Currency` compat fields were deleted (proposal
`2026-08-03-drop-getcollection-compat.md`). A re-grep at that moment found **zero readers of
the fields AND zero callers of the remote itself** — the only remaining references are the
server-side handler registration in `LobbyServices` and historical comments.

So the question the proposal raised is now sharper than "should the compat fields go": the
whole remote is dead code.

## Decision

**Retire `GetCollection`.** `GetUnitViews` is the single Lobby read path.

Two profile read paths against the same schema is a standing hazard: they diverge silently,
only one of them is exercised, and the unexercised one rots. `GetCollection` had already
accumulated exactly that rot in the form of the v1-shaped compat fields. Everything it serves
(`Units` / `Loadout` / `Currencies` / `PlayerXP` / `PlayerLevel`) is available from
`GetUnitViews`, which additionally serves grades, names, tiers, `Equipped`, `Items` and
`MaxLoadout`. The only difference is field naming on the unit record (`MetaLevel` vs `Level`)
and the absence of a raw-record shape — nothing depends on either.

## Execution is scheduled for A7, not A6b

The deletion (handler + the `RS.Remotes.GetCollection` RemoteFunction instance) is deliberately
**not** performed in the session that decided it. The reason is blast radius, not doubt:

- A **USER-BLOCKING republish of both Places** is still open and already carries the entire
  A-phase promotion plus A5 and A6. That single publish is the riskiest pending action in the
  project. Adding a remote deletion to it means a post-publish problem has one more candidate
  cause, and remote deletions are the kind that fail loudly and late (a client that
  `WaitForChild`s a removed remote yields forever rather than erroring).
- Place-local code is **Studio canon, not in git** (ADR-0001). Deleting the handler therefore
  removes the only copy. Doing it after the republish means the published place file is a
  recoverable snapshot of the pre-deletion state.
- There is no cost to waiting: the remote is unread, read-only, and serves nothing an
  authenticated client cannot already get from `GetUnitViews`.

Until then `GetCollection` stays wired and unread. **No new readers may be built on it** — that
constraint is recorded in the `LobbyServices` header so a future session cannot re-grow the
dependency by accident.

## Consequences

- A7 (Integration / Phase A acceptance) removes the handler and the RemoteFunction, then
  verifies every Lobby screen still loads. Tracked as a PENDING in `STATE.md`.
- `GetUnitViews` becomes load-bearing for the whole Lobby UI. It is not versioned today; if a
  future change to it is breaking rather than additive, it needs the contract treatment
  (version + migration note) that `GetCollection` never had.
- The `Items` field AD-UI added to `GetUnitViews` was reviewed in the same session and **kept
  as-is** — copied not aliased, defensive about an absent field, read-only, additive, so no
  contract bump and no change for `ItemsController`.
