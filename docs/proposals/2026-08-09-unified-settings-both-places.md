# Proposal — ONE settings system shared by the Game and the Lobby

<!-- author: AD-UI (raised while building the summon UI; NOT the owner of the Game's SettingsService) -->
<!-- target owner: AD-Game (owns SettingsService) + AD-UI (owns the screen) + AD-Integration (shared canon) -->
<!-- raised: 2026-08-09 (B6) | status: PROPOSED, awaiting a session -->

## Why this exists

Blueprint Phase B task B3 (summon UI) asks for a **skip-anim toggle in Settings**. The Lobby has
**no settings system at all** — no service, no screen, no persisted field (verified live at B6:
zero instances matching `setting` anywhere in `ServerScriptService`, `ReplicatedStorage` or
`StarterPlayer`). The Game place *does* have one: `SettingsService`, profile-backed, which prints
`[SettingsService] Ready (profile-backed)` at boot.

Asked how to resolve it, the **user's answer was to unify rather than duplicate**:

> "I have a Settings System in the Game place, I want to use it too. So technically there will be
> one settings system for both game and lobby. But some settings will only be available while in
> game, and some only in lobby. But both should use same structure, same gui."

That is a bigger and better idea than a Lobby-local toggle, and it is **not** summon-UI work, so
B6 deferred it and raised this instead of half-building a settings system inside a gacha screen.

## The user's own example (recorded verbatim-ish, with one reading flagged)

> "In the Game place there will be a button for 'Restart Match' and 'Return to lobby' and 'TP to
> Spawn', but only 'TP to spawn'."

**Reading:** the Game shows all three (`Restart Match`, `Return to Lobby`, `TP to Spawn`); the
Lobby shows only `TP to Spawn`. The sentence is slightly clipped, so **confirm this with the user
before building** — it is the whole point of the Place-scoping requirement and worth ten seconds.

## What it has to be

1. **One structure, one GUI.** The same screen design and the same entry schema in both Places, so
   a player sees the same settings screen wherever they are.
2. **Per-entry Place scope.** Each entry declares where it applies — `Both` / `GameOnly` /
   `LobbyOnly` — and the screen simply does not render entries out of scope. This is the part that
   makes one system serve two Places instead of two systems drifting apart.
3. **Two kinds of entry, which should not be conflated:**
   - **Preferences** — persist on the profile (e.g. skip-anim). These need a schema field.
   - **Actions** — fire and forget, persist nothing (`Restart Match`, `Return to Lobby`,
     `TP to Spawn`). The user's own example is mostly *actions*, so an entry schema that only
     models booleans will not fit.
4. **The reveal skip toggle is a preference**, `Both`-scoped in principle but only meaningful where
   a reveal happens (Lobby today).

## Why this is NOT a quiet edit

- `SettingsService` is **AD-Game canon** (`docs/OWNERSHIP.md`). AD-UI must not rewrite it; hence a
  proposal plus a PENDING, exactly as `2026-08-08-obtain-rewards-gui.md` was raised by AD-Game for
  an AD-UI screen.
- "Same structure, same GUI in both Places" means a **shared config module + a shared template**,
  i.e. new `shared/manifest.json` entries and the full drift procedure in `tools/checklists.md`.
  That is **AD-Integration** work, and it spans both Places.
- A persisted preference is a **save-schema change** → the contract protocol (bump
  `SCHEMA_VERSION`, add a migration, never edit old migrations, PENDING for the other Place).
  Check first whether the Game's existing settings already have a home in the v2 profile — if they
  do, reuse it and **no bump is needed**, which would make this dramatically cheaper.

## Suggested sequencing (one session-task each)

1. **AD-Game** — document what `SettingsService` currently is: entry shape, where it persists,
   whether it already has a profile field. Nobody should design against a guess.
2. **AD-Game + user** — agree the unified entry schema (`Id`, `Kind = Preference|Action`, `Scope =
   Both|GameOnly|LobbyOnly`, `Default`, label) and confirm the Restart/Return/TP reading above.
3. **AD-Integration** — promote the config + template to shared canon, deploy to both Places,
   manifest + drift green in both.
4. **AD-UI** — build the one settings screen against the shared template; it renders whatever is
   in scope for its Place, so it needs no Place-specific branches beyond `Scope`.
5. **AD-UI** — add the reveal skip-anim preference and have `ObtainRewardsController` read it.

## Until then

`ObtainRewardsGUI` already supports **click-to-skip** (B4): click 1 skips the reveal, click 2
closes. So the *functional* need the blueprint's toggle serves is largely met already — what is
missing is only the persisted preference. Nothing is blocked on this.
