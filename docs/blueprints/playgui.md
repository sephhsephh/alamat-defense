# BLUEPRINT — PlayGUI (main menu → story mode → lobby → launch)

<!-- owner: AD-UI (screens/controllers) + AD-Lobby (flow/launch) + AD-Game (reward scaling) -->
<!-- scope: LOBBY place | status: READY TO IMPLEMENT | blueprints are LAW: deviations need docs/proposals/ -->
<!-- authored 2026-08-09 by AD-Integration from the user's spec + a live audit of the built tree -->

Rules for the implementing chat: do NOT redesign anything here. Implement ONE session-task (§9) per
session. The GUI **already exists** in `StarterGui.PlayGUI` — the user built it. You are wiring it,
not authoring it.

## 1. The user's rule, restated because it governs everything below

> **NEVER initialise a GUI from a script.** Design it in `StarterGui` or `RS.UITemplates` so devs can
> edit it and see the real output in Studio.

Controllers may only: read data, **clone a designed `*Template` instance**, set text/image/visibility,
and wire events. If you need a new visual element, **create it as a real Instance in the Edit
datamodel** (persisted, editable) — never `Instance.new` at runtime.

## 2. Blockers found in the live audit — fix these FIRST or the screen cannot be filled

**B-1. ✅ RESOLVED at P1 (2026-08-09).** `StageRegistry.List()` now carries `StageNumber`,
`StageName`, `ActNumber` and `ActName` on all three acts, alongside the untouched `Id`,
`DisplayName`, `ActLabel`, `NextActId`, `Recommended`. Values are **verbatim from the Game's
`StageConfig`s** (read-only lookup): all three are Stage 1 **"The Farm"**; acts are
1 **"Protecting the Fields"**, 2 **"The Scarecrow Awakens"**, 3 **"Harvest of Ruin"**.
**`DisplayName` is NOT `ActName`** — Act 1 is DisplayName "The First Alamat" *and* ActName
"Protecting the Fields". Do not collapse them. Nothing validates these NAMES cross-Place (only the
`Id` is re-checked Game-side), so if AD-Game renames an act the mirror goes stale **silently**.

**B-2. ✅ RESOLVED at P1 (2026-08-09).** `Workspace.PlayGUICamera` is now `Transparency = 1`,
`CanCollide = false`, `CastShadow = false`, `Anchored = true`. Still a Part; its CFrame/Size were
**not** touched — the framing is the user's.

**B-3. ✅ RESOLVED at P3 (2026-08-13, user-authorised).** `SelectedAct` had THREE children named
`StageNameLabel`. **They were not duplicates** — they were three distinct labels copy-pasted without
renaming, so the original "delete the two extras" advice would have destroyed real content. Renamed
by their text: `"Total Clears : 0"` → `TotalClearsLabel`, `"Clear Time : 00:00:00"` →
`ClearTimeLabel`; the genuine `"Stage Name"` one kept its name. Exactly one `StageNameLabel` now.

**B-4. Missing template instances** (must be authored as real Instances, `Visible = false`):
- ✅ **RESOLVED at P4 (2026-08-13, user-delegated):** `Fill` + `Handle` authored under
  `SelectedAct.DifficultyGradient`. **Note that `DifficultyGradient` does not read like a groove** —
  it is a full-width frame 78% of the panel tall at `ZIndex 0` with a vertical black→lime gradient,
  i.e. a backdrop. The parts were authored plain and functional (`Fill` grows on `Size.X.Scale`,
  `Handle` moves on `Position.X.Scale`, both at `ZIndex 2/3` so they are visible above the
  ZIndex-0 track) and placed at local Y `0.2316` — the clear gap between `SelectedDifficultyLable`
  (ends 0.229) and `DifficultyButtons` (starts 0.570). The controller reads their AUTHORED geometry,
  so **restyle or reposition them freely in Studio; no code change is needed.**
- ✅ **RESOLVED at P6 (2026-08-13, user-delegated):** the **player row template** under
  `LobbyFrame.SelectedAct.PlayersFrame.PlayersFrame`. There was no `*Template` — just four
  copy-pasted `ItemIcon` cards. One was repurposed as `PlayerRowTemplate` (`Visible = false`):
  `QtyBadge` → `HostBadge` (a quantity badge is meaningless on a player), its label → `HostBadgeLabel`
  = "HOST", `IconImage` = the avatar, and a `NameLabel` added — the only genuinely new instance.
  **The other three were HIDDEN (`Visible = false`), not deleted** — B-3's precedent, and they are the
  user's content. Authored plain and functional; the controller reads its geometry, so restyle freely.
- ✅ **RESOLVED at P3:** `RewardsFrame.RewardsScrollingFrame.ItemIcon` (an **ImageButton**) renamed
  to **`ItemIconTemplate`** with `Visible = false`.

**B-5. ✅ RESOLVED at P6 (2026-08-13).** `StarterGui.StageSelectScreen` (100% script-built — one
`Controller` LocalScript, 1 descendant) is **DELETED**. Callers were re-grepped first: `GetStages`
survives (`ReturnScreen` still calls it, `LobbyServices` still serves it), but
`ClientEvents.OpenStageSelect` lost its only listener — see the P6 row in §9.

**NOT a blocker — `HUD.Top.CurrencyBar` already complies.** It is a designed Frame with a
`CurrencyTemplate` child that the controller clones. That is the sanctioned pattern, not
script-built UI. **Do not "convert" it.** (The user's request to convert "the currencies" was based
on the assumption it was script-built; the audit says otherwise.)

**Correction to the spec:** the Play button is **`HUD.Left.Buttons.Play`**, not `HUD.Right`.
`HUD.Right.Buttons` holds `Event`, `Profile`, `Quests`.

## 3. The flow (exact paths)

```
HUD.Left.Buttons.Play
  -> LoadingScreen covers the whole screen        (new, §4)
  -> Camera = CFrame of Workspace.PlayGUICamera   (Scriptable; parallax with cursor, §5)
  -> every other ScreenGui hidden; PlayGUI.Enabled = true
  -> PlayGUI.Main.MainMenu visible                 (§6)
       StoryModeButton -> StoryModeFrame           (§7)
         CreateButton  -> LobbyFrame               (§8)
           StartButton -> LoadingScreen -> teleport (existing PartyService path)
```

Frames are siblings under `PlayGUI.Main`: `MainMenu`, `StoryModeFrame`, `LobbyFrame`. Exactly one is
active at a time; switching is a **transition** (§10), never a bare `Visible` toggle.

## 4. LoadingScreen (new, reusable across the whole game)

A NEW `StarterGui.LoadingScreen` ScreenGui — authored as real Instances, `DisplayOrder` above
everything, `IgnoreGuiInset = true`, `ResetOnSpawn = false`. Minimum contents: full-bleed backdrop,
a title/tip label, and a progress or spinner element. Controller API, callable from either Place:

```
LoadingScreen.Show(reason: string?)   -- fades in, blocks input
LoadingScreen.Hide()                  -- fades out
```

It is **Lobby-local for now**. Promote it to shared canon the day the Game place needs it — do not
pre-emptively make it shared (same call made for `CurrencyBar`; a single-Place widget under drift
control costs a cross-Place sync forever).

## 5. Camera

On enter: `Camera.CameraType = Scriptable`, `Camera.CFrame = Workspace.PlayGUICamera.CFrame`.
Parallax: offset the camera by a small rotation derived from the cursor's normalised offset from
screen centre — clamp to a few degrees and **lerp**, never snap. On exit: restore
`CameraType = Custom` and re-attach to the character. Restore on death/respawn too, or a player who
dies in the menu is left with a stuck camera.

## 6. MainMenu

`GameModesFrame` holds `StoryModeButton`, `ChallengeModeButton`, `RaidsModeButton`,
`EventsModeButton`. **Only StoryMode is in scope.** The other three must render **visibly disabled**
(their `InactiveOverlay`/stroke pattern) and do nothing — not silently no-op.
Each mode button carries `ModeNameLabel`, `ProgressPercentLabel` and mode-specific labels
(`StagesClearedLabel`, `DailyRefreshCountdownLabel`, `WeeklyRefreshCountdownLabel`); fill what real
data exists and hide the rest. `LeaveButton` returns to the lobby scene (reverse of §3).

## 7. StoryModeFrame

- **`Stage/Act.Stages`** — clone `StageButtonTemplate` per stage. Fields: `StageLabel`,
  `LevelsClearedLabel`, `ProgressPercentLabel`. Keep the existing `Spacer`; keep `UIListLayout`.
- **`Stage/Act.Acts`** — clone `ActButtonTemplate` per act of the selected stage. Fields: `ActLabel`,
  `ActName`.
- **`SelectedAct`** — fill `StageBGImage`, `StageNameLabel` (see B-3), `ActNumberActNameLabel`,
  `SelectedDifficultyLable`, and `RewardsFrame` (§8).
- **`DifficultyButtons`** — `NormalButton` / `InsaneButton`, each with `Icon`, `InactiveOverlay`,
  `SelectedDifficultyLable`. Selection drives the overlay; exactly one active.
- **`DifficultyGradient`** — the slider track (needs Fill + Handle, B-4). **Reads 1–100.**
- `CreateButton` → LobbyFrame. `FindMatchButton` → **disabled + "coming soon"** (§11).

**Difficulty semantics are ADR-0011 and are NOT negotiable here:** the slider is 1–100 for display
only; the controller converts to the existing 100–1000 `DifficultyPercent` at the payload boundary
via one function. **1% = the act's normal difficulty.** Normal/Insane is a separate axis from the
slider — an act is at its normal difficulty at slider 1% under BOTH.

## 8. Reward preview + scaling

`RewardsFrame.RewardsScrollingFrame` clones `ItemIconTemplate` (B-4) per previewed reward.

Scaling is defined on the **UI 1–100 scale** (ADR-0011), linear:

| Mode | slider 1% | slider 100% | extra |
| --- | --- | --- | --- |
| Normal | Gold **100–300** | Gold **300–500** | — |
| Insane | same curve | same curve | **plus item rewards** |

So `goldMin = lerp(100, 300, t)` and `goldMax = lerp(300, 500, t)` where `t = (ui - 1) / 99`.

**The preview must not invent numbers.** The panel shows what the server will actually pay, so the
curve belongs in a config both sides can read, and the **server remains the only thing that grants**
(invariant 1: every grant flows through `GrantService` in the Lobby; the Game still pays match-end
rewards through `RewardCalculator`).
→ **P5 is AD-GAME's row**: `StageConfig.Rewards` currently has flat `Victory.Currency` /
`Defeat.Currency` numbers and a `DropTable`. Extending them to a difficulty curve is a change to
AD-Game's canon and must not be improvised by a UI session.

## 9. Session plan (ONE per session; owner in brackets)

- **P1 [AD-Lobby] ✅ DONE 2026-08-09** — `StageRegistry` mirror carries `StageNumber`/`StageName`/
  `ActNumber`/`ActName` (B-1) and `PlayGUICamera`'s part properties are fixed (B-2). Verified from a
  real Script: 3 entries, all four fields populated, existing keys intact, chain
  Act1→Act2→Act3→nil, wire difficulty scale unmoved at 1/1000/100.
- **P2 [AD-UI] ✅ DONE 2026-08-13 (B15)** — `LoadingScreen` (§4) + the Play-button entry, camera
  swap + parallax (§5), GUI hide/show, the MainMenu ↔ StoryModeFrame ↔ LobbyFrame **transitions**
  (§10), and the disabled mode buttons + `FindMatchButton` (§6/§11). Verified from a real
  LocalScript: 40 asserts, 0 failures. **§10 required a CanvasGroup, so the three frames were
  CONVERTED Frame → CanvasGroup in the Edit datamodel** (authoring; every property, child and the
  child order carried across unchanged, so every path in §7/§8 still resolves). No stage data yet.
- **P3 [AD-UI] ✅ DONE 2026-08-13 (B16)** — StoryModeFrame lists: stages grouped from P1's data,
  acts per stage, `SelectedAct` fill (§7). B-3 and B-4's rename were cleared at the top of the
  session (see §2). Verified from a real LocalScript: 29 asserts, 0 failures.
  **Three recorded narrowings of §7's fill list, all for honesty or scope:** labels with no data
  source (`LevelsClearedLabel`, `ProgressPercentLabel`, `TotalClearsLabel`, `ClearTimeLabel`) are
  HIDDEN rather than zeroed — nothing in this Place tracks clears; `StageBGImage` keeps its
  authored image because no per-act art source exists; and `SelectedDifficultyLable` is left to
  **P4**, because filling it needs the ADR-0011 remap and a second remap is the exact bug that ADR
  exists to prevent. The reward panel is PLUMBING only and renders zero cells until **P5**.
- **P4 [AD-UI] ✅ DONE 2026-08-13 (B17)** — difficulty slider (Fill/Handle authored at the top of
  the session, user-delegated) + Normal/Insane + the ADR-0011 remap, which lives in the
  `DifficultyScale` **ModuleScript** so "exactly one conversion" is greppable and P6 cannot
  re-derive it. Publishes `DifficultyUI`/`DifficultyWire`/`DifficultyMode` on `SelectedAct`.
  Verified from a real LocalScript: 27 asserts, 0 failures.
  **The live reward preview is NOT part of this** — it needs P5's config, which does not exist yet.
  P4 shipped without it, exactly as §9 allows ("P4 may ship with the preview reading the config as
  soon as it exists"). Wiring it later is a call to the existing `renderRewards(list)` from P3.
- **P5 [AD-GAME] ✅ DONE 2026-08-13 (B18)** — reward scaling by difficulty (§8). Victory gold is
  rolled from `lerp(100,300,t)`–`lerp(300,500,t)`; a DEFEAT keeps its flat consolation (scaling a
  loss would make losing on max difficulty the best gold/minute). The curve went into a SHARED
  `RS.Configs.Global.RewardScalingConfig` rather than into each `StageConfig.Rewards`, because §8
  requires the preview and the server to read the SAME curve and the Lobby's StageRegistry is a
  structure-only mirror with no drift check; each act NAMES a curve instead of copying endpoints.
  The Game does its OWN wire→t conversion (`t=(wire-100)/99` would be the UI mistake — it is
  `(wire-100)/900`), clamped, in one function. Canon: `docs/systems/rewards.md`.
  **⚠ TWO FOLLOW-UPS, both PENDING in `STATE.md`:** the Lobby must be sent `RewardScalingConfig`
  (`deployed.Lobby = null`) before the **preview** can read true numbers, and **Insane is coded but
  UNREACHABLE** — the `MatchLaunch` payload carries no mode field, so making it live is a teleport
  contract v2→v3 change (both Places, ONE session, synchronised republish).
- **P6 [AD-LOBBY] ✅ DONE 2026-08-13 (B19)** — LobbyFrame: the `PlayersFrame` roster, `InviteButton`,
  `StartButton` → LoadingScreen → the EXISTING `PartyService` reserved-server launch, plus the
  deletion of `StarterGui.StageSelectScreen` (B-5). Verified from a real LocalScript + a temporary
  server probe on `RequestLaunch`: **30 asserts, 0 failures**.
  **B-4's row template was authored at the top of the session (user-delegated):** the gate was
  reported first, exactly as B17 did — `PlayersFrame.PlayersFrame` held four copy-pasted `ItemIcon`
  cards and no `*Template`. The user chose "repurpose one", so one became `PlayerRowTemplate`
  (`QtyBadge` → `HostBadge`, `NameLabel` added, `IconImage` = avatar); the other three were HIDDEN,
  not deleted. The controller reads its AUTHORED geometry, so restyling needs no code change.
  **P6 reads P4's published `DifficultyWire` and performs no arithmetic on it** — proven live, the
  server probe saw `DifficultyPercent=545` for UI 50%, byte-for-byte what P4 published. A missing
  attribute REFUSES the launch rather than re-deriving it.
  **`InviteButton` opens the existing `PartyScreen`** (user decision) through a new `OpenRequest`
  attribute seam, rather than authoring a second invite list; `PartyScreen.DisplayOrder` 0 → 30.
  **⚠ ONE KNOWN CONSEQUENCE:** deleting `StageSelectScreen` orphaned `ClientEvents.OpenStageSelect`
  (its only listener), so `ReturnScreen`'s CONTINUE is inert. Replacing it touches AD-UI's
  controllers, so P6 filed `docs/proposals/2026-08-13-openstageselect-after-stageselectscreen.md`
  and a PENDING instead of editing them.
- **P7 [AD-Meta, deferred]** — the global queue (§11). Not before P6.

## 10. Transitions (required, not decoration)

Frame switches must animate. Use `TweenService` on properties of the REAL instances — never rebuild
the frame. House pattern: outgoing frame fades (`GroupTransparency` 0→1 via a `CanvasGroup`) and
slides ~24px in the travel direction; incoming does the inverse, `~0.22s`, `Enum.EasingStyle.Quart`,
`EasingDirection.Out`, overlapping by about half. Guard against double-fire: ignore input while a
transition is in flight, and always land on the exact authored `Position`/`Transparency` rather than
accumulating offsets — an interrupted tween that never resets is how frames drift out of place.

## 11. Global queue — DESIGNED, NOT BUILT (user decision, 2026-08-09)

`FindMatchButton` ships **disabled with a visible "coming soon" state** until P7.

Intended shape when built: `MemoryStoreService` sorted-map/queue keyed by
`stageId | actId | mode | difficultyBucket`; party-aware (a party joins as one unit and is never
split); host election on match; timeout → offer a solo start rather than hanging; abandonment
cleanup; then the **existing** reserved-server handoff — matchmaking decides *who*, `PartyService`
still decides *how* to launch. **Do not build a second launch path.**
It cannot be meaningfully verified in a single Studio instance, which is the main reason it is its
own session rather than a corner of P6.

## 12. What must NOT change

- `GetUnitViews` stays the single profile read path (ADR-0004). No second read path.
- `DifficultyPercent`'s wire meaning, range and name (ADR-0011).
- `GrantService` stays the Lobby's single grant/spend path.
- No server→client push remote for rewards.
- `Kit_UnitIcon` is adopted (ADR-0009) — use it, do not edit or delete it.
- Ascension/C1/C2 screens follow the NPC-opened shape (ADR-0010), not panes in a frame.
