# Proposal — delete the interim `Towers` / `Currency` compat fields from `LobbyServices.GetCollection`

<!-- author: AD-UI | target owner: AD-Lobby | place: Lobby | raised: 2026-08-03 (A5) -->
<!-- status: RESOLVED 2026-08-06 (A6b, AD-Lobby) — see the resolution note below -->

## RESOLUTION — 2026-08-06 (A6b, AD-Lobby)

All three questions answered; nothing here is still open.

1. **Compat fields DELETED.** Re-grepped first, as this proposal requires: `result.Towers` /
   `result.Currency` had **zero readers** (the only `%.Towers` / `%.Currency` hits in the Place
   are `ProfileTemplate`'s v1→v2 migration, which reads the OLD PROFILE fields and is untouched).
   Removed the `towers` local, the `prev`/highest-MetaLevel block, both trailing return fields,
   and the stale header paragraphs.
2. **`Items` on `GetUnitViews`: reviewed and KEPT AS-IS.** The shape is right — it copies rather
   than aliasing `data.Items`, it is defensive about the field being absent, it is read-only and
   additive, and it type-checks each count. No reshape, so **`ItemsController` needs no change**.
   Confirmed as AD-Lobby canon in the module header.
3. **`GetCollection`'s fate: RETIRE it** — decided, recorded in `docs/decisions/ADR-0004-retire-getcollection.md`.
   The remote now has zero callers of any kind. Execution (handler + RemoteFunction deletion) is
   scheduled for **A7, deliberately after the blocking republish**, so that publish does not also
   carry a remote deletion; Place-local code is Studio-canon, so the published file is the only
   recoverable snapshot. No new readers may be built on it in the meantime.

## Why now

The two fields were added at A2 as a bridge for the two screens that still read schema-v1
shaped, towerId-keyed data. Both readers are now gone:

- **UnitsGUI** moved to `GetUnitViews` at **A4** (2026-08-03, commit `432185b`).
- **CollectionScreen** was rebuilt on `GetUnitViews` at **A5** (this session) — real instances
  + a view-model controller, per the no-UI-in-scripts rule.

`script_grep` for `result.Towers` / `result.Currency` returns **no readers** in the Lobby
place after the A5 rebuild. The fields are dead weight and actively misleading: `Towers`
collapses multiple unit instances into one record per TowerId, which is the exact v1 model
schema v2 exists to replace.

## The change (AD-Lobby canon — AD-UI did not make it)

In `ServerScriptService.Server.Lobby.LobbyServices`, `getCollection.OnServerInvoke`:

1. Delete the `towers` local and the `local prev = towers[rec.TowerId] ... end` block inside
   the `data.Units` loop.
2. Delete the two trailing fields from the returned table:
   ```luau
   -- interim compat (remove at A5):
   Towers = towers,
   Currency = currencies.Gold,
   ```
3. Update the module header: drop the "INTERIM COMPAT layer ... REMOVE both when A5 rebuilds
   those screens" paragraph and the A5 STATUS note AD-UI added below it.

Nothing else changes. `GetCollection` keeps serving `Units` / `Loadout` / `Currencies` /
`PlayerXP` / `PlayerLevel`.

## Contract impact

**None, but confirm the consumer list first.** `GetCollection` is not a versioned contract and
these fields were explicitly documented as interim from the day they landed. Before deleting,
re-run `script_grep` for `Towers` and `.Currency` in the Lobby place — if any screen has been
added since 2026-08-03 that reads them, convert it to `GetUnitViews` in the same session
rather than keeping the fields alive.

Worth deciding at the same time: whether `GetCollection` should survive at all, or whether
`GetUnitViews` should absorb its remaining callers and `GetCollection` be retired. AD-UI has
no opinion to impose here — it is AD-Lobby's call and out of A5's scope.

## Related: the `Items` field AD-UI added to `GetUnitViews` (needs your review)

Separately, and with the **user's explicit authorisation this session**, AD-UI edited
`LobbyServices` to add one additive, read-only field to `GetUnitViews`:

```luau
-- { [itemId] = count } copied out of data.Items, defensive about the field being absent
Items = items,
```

This is AD-Lobby canon and AD-UI would normally have proposed it instead of writing it. It
was authorised because the A5 Items screen has no other quantity source. Please review it and
either keep it as-is or fold it into whatever shape you prefer. Notes:

- It copies rather than handing out `data.Items` by reference.
- No contract version bump: the per-unit `unitView` shape is unchanged and every existing
  consumer ignores the new key.
- **Nothing writes `Data.Items` anywhere in either Place** (`script_grep` for `data.Items`
  returned zero matches before this change). The map is legitimately empty today; the Items
  screen renders the catalog with zero counts until a drop/grant path exists. That writer is
  unscheduled — see STATE.md.
