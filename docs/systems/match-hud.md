# Match HUD, Auto Play and placement rules (GAME)

<!-- owner: AD-UI (layout) + AD-Game (Auto Play, placement) | place: Game | since: B81 (2026-09-22) -->

The match HUD follows the user's reference screenshot (B81): a four-pill stat bar across the top, a
wave banner, pinned quests on the left, the stage tag and three big buttons on the right, the cash
with next-wave income above the hotbar, and the account XP bar under it. **The hotbar itself is the
user's own GUI (`StarterGui.Hotbar`, see `hotbar.md`) and was not touched.**

## Layout (all authored instances, tag `B81Built`)

| Where | Instance | Driven by |
| --- | --- | --- |
| Top centre | `MatchHUD.StatBar` — `HealthPill` / `WavePill` / `EnemiesPill` / `TimePill` (`Icon`, `Value`, `Caption`) | `Client.UI.HUD` |
| Under it | `MatchHUD.StatusLine` — "Next Wave - 24s", "Build Phase", "VICTORY!" | `HUD` |
| Below | `MatchHUD.WaveBanner` (`Title`, `Subtitle`, `UIScale`) — pops for 2.5 s on each new wave | `HUD` |
| Top left | `Settings.OpenButton` (moved) + `MatchHUD.TopLeftButtons` (Emote / Players / Favorite) | `SettingsUI` / placeholders |
| Top right | `MatchHUD.TopRightButtons` (Trophy / News / Update) | placeholders |
| Left | `MatchHUD.PinnedQuests` | `Client.UI.HudPanels` |
| Left, under it | `WavePrep.Preview` (moved) — the intermission "WAVE N / Incoming" card | `WavePrepUI` |
| Right | `MatchHUD.StageTag` — "STORY  The Farm - Act 1" / "Normal Mode" | `HudPanels` |
| Right | `MatchHUD.RightButtons` — `UnitManagerButton` (F), `StageInfoButton` (C), `AutoPlayButton` | `UnitManagerUI` / `HudPanels` |
| Right, under | `MatchHUD.SpeedControl` (moved), `WavePrep.Root` skip/ready vote (moved) | unchanged scripts |
| Above hotbar | `MatchHUD.TopRight.CashValue` (unchanged) + `MatchHUD.NextWaveIncome` | `HUD` |
| Under hotbar | `StarterGui.XPBarGui.XPBar` (own ScreenGui, DisplayOrder 1 — see below) | `HudPanels` |
| Bottom left | `MatchHUD.BottomLeftButtons` — `JButton`, `KButton` | placeholders |
| Centre (modal) | `MatchHUD.StageInfoPanel` (`Content.Body`, RichText) | `HudPanels` |

**Retired, hidden, NOT deleted:** `MatchHUD.TopLeft`, `TopCenter`, `Clock`, `BottomRight` carry the
attribute `RetiredB81`. Delete them by hand once you are happy. `UnitManager.OpenTab` is hidden for
good — the UNIT MANAGER button replaces it.

**Why the XP bar has its own ScreenGui:** `MatchHUD` and `Hotbar` both use DisplayOrder 0, so the
hotbar drew over the bar. `XPBarGui` is DisplayOrder 1.

## The placed-unit counter (B83)

`HotbarSlot1.PlacedUnitCounter` is the user's own label; the other five slots get a **copy of it**
the first time the controller runs, so there is one design to edit. It is hidden except while that
exact unit is being placed, and it reads `current/limit` — **white** while another one may be
placed, **red** at the limit. It repaints live from `PlacementCountsChanged`, so placing your last
one turns it red while the ghost is still up.

It follows `PlacementController.StateChanged` (new), which fires for every route into placement —
the slot click, the 1-6 keys, and every cancel (E/X/Esc/right-click/the on-screen buttons).

## Placeholders

Every button with the attribute `Placeholder = true` shows a "Coming soon" toast (J and K keys too).
To give one a job: connect to the button in a script and **remove the attribute**.

## Pinned Quests + XP bar (read-only)

`Server.Meta.HudInfoService` answers `Remotes.Match.GetHudInfo` with the player's level/XP and
today's quests. It reads the profile and the **shared** `QuestRegistry` (promoted to canon at B81 so
both Places roll the same day's set) and **writes nothing** — the Lobby's `QuestService` stays the
one writer of `Data.Quests`. The panel shows the pinned quest, else the first unfinished one, plus
"+N more". A quest the player has not opened in the Lobby today shows 0 progress (no baseline yet —
the honest answer). The client retries for ~30 s because the profile can still be loading when the
HUD boots. Refreshed again 2 s after Victory/Defeat.

### The drawer (B90)

A `<` tab on the panel's right edge (`PinnedQuests.CollapseButton`, tagged `B90Built`) slides the
whole panel off to the left; the tab flips to `>` and brings it back. 0.28 s `Quart Out`.

**The closed X is derived from the panel's own width**, and that is what keeps the tab reachable.
This panel is anchored on its LEFT edge, so it has to travel exactly its own width to clear the
screen — the mirror of the rule the two right-side panels follow (`unit-manager.md`). The tab is
parented *at* the panel's right edge (`Position {1, 0}`), so that one width lands it flush on
`x = 0`: the panel is gone, the tab is still there. A tab that left with the panel would be a
one-way door.

It deliberately does **not** take B89's `Visible = false` rule. The tab is a child of the panel, so
hiding the panel would hide the only way back — and it does not need to, because a parked panel's
right edge lands exactly on `x = 0`, leaving nothing on screen to eat a click.

The toggle reads a `questOpen` flag, never the panel's `Position`: a toggle that tests the thing the
tween is still moving fights its own animation.

## Stage Info (button or C)

Built from configs the client already has: `StageRegistry`, `WaveListRegistry`, `EnemyConfigRegistry`.
Shows stage/act, mode, lives, wave count, the enemy roster (bosses marked with their waves) and the
act's rewards + drop chances. **C is shared with the selected tower's auto-cast:** with a tower
selected (the TowerSelection panel visible) C belongs to the tower; otherwise it opens Stage Info.

The snapshot gained `Difficulty`, `GameMode` and `DifficultyPercent` (MatchDirector) for the stage tag.

## Auto Play (`Server.Placement.AutoPlayService`)

While `Player:GetAttribute("AutoPlay")` is true (set only through `Remotes.Match.SetAutoPlay`), once
per **virtual** second it takes ONE action for that player:

1. **Place** the cheapest affordable unit — a unit with **none** on the field goes first — from the
   player's loadout, **only from UNLOCKED hotbar slots** (the Lobby's auto-loadout can over-fill; a
   locked slot cannot be clicked, so Auto Play must not use it either).
2. Otherwise **upgrade** the cheapest affordable tower.

Spots are sampled along the map's path waypoints, 3 / 4.5 / 6.5 studs to either side, dropped onto
the ground with a raycast. Damage units take the spot whose range covers the most path; economy
units (IncomePerWave, no damage) take the spot farthest from the path.

**It has no power a click does not have.** Placement goes through `PlacementValidator.TryPlace` — the
same function the RequestPlace remote now calls — so zone, path, overlap, limit and cash are the same
checks in the same order. Upgrades use `TrySpend` + `tower:Upgrade()` like the upgrade remote. It
never sells. Proven live: Archer, Knight, Farm, Necromancer placed beside the path (none on it), then
upgrades; Meteor (locked slot 5) correctly skipped.

## No building on the path (`RS.Shared.PathClearance`)

User rule: units may not be placed on the map's `PathDesigns`. `PathClearance.Blocks(position, radius)`
tests the tower's footprint circle against every BasePart under `ActiveMap.PathDesigns`, each as its
own oriented box on the XZ plane (Y checked loosely, ±6 studs). **One module, required by both the
client ghost and the server `PlacementValidator`,** so the red "Can't place on the path" preview and
the server's `OnPath` refusal can never disagree. A map without `PathDesigns` blocks nothing.

## Placement ghost

- Plays the unit's **idle** while you place it (`Idle.Anim`, else the rig's `IdleAnim`, else the stock
  idle). Only the root part is anchored now — an anchored limb ignores its Motor6D.
- A **FullAoe** tower anchored on itself shows its attack shape as a circle from the tower out to its
  Range (placement ghost and selected tower alike). A FullAoe anchored on the target with a radius is
  drawn as a circle at the target.

## Boss health — the screen bar AND the billboard (B84)

A boss is tracked by `Client.UI.BossHealthUI`, which now draws it **twice**:

- **The screen bar** (`StarterGui.BossHealth`, the user's authored image layout — see B80): one row
  per live boss, pinned under the stat bar. Unchanged.
- **A billboard over the boss's head** (B84, user request: "add boss health billboard gui for the
  bosses with its name"). The template is the authored
  **`ReplicatedStorage.UITemplates.BossHealthbar`** (a `BillboardGui`, everything tagged `B84Built`):
  `BossName` over a `BarBG` holding `DamageTrail` / `Fill` / `HealthText`. **It is authored art, not
  built in script** — restyle it in Studio and the game picks it up.

The billboard is cloned per boss, adorned to the model's `PrimaryPart` (else `HumanoidRootPart`), and
lifted by the model's own height (`GetBoundingBox().Y * 0.5 + 2.5`) so a tall boss does not wear its
bar on its chest. `AlwaysOnTop`, `MaxDistance 400`. It gets **its own `HealthBarFX`** instance, so the
damage-trail flash runs on the billboard and the screen bar independently. `BossName` shows the
model's `DisplayName` attribute; `HealthText` shows `NumberFormat.Short(current) / Short(max)`.

Cleanup rides on the existing bar lifecycle: `removeBar` destroys the billboard with the row, so a
dead boss leaves nothing behind.

## B110 -- Alamat HUD overhaul (2026-10-04, user: bold original, violet/gold, juicy, hotbar untouched)
- **Theme kit:** `ServerStorage.DevTools.AlamatTheme` (edit-time only): violet glass (white BG x UIGradient), gold
  shimmer stroke (UIGradient tagged `AlamatShimmer`), press-animated buttons (tag `AlamatPress`, UIScale `Press`).
- **Motion:** `Client.UI.HudFX` (shimmer, wirePress, pop, bump, countTo, slam/slamOut, shake, flash, float, pulse) +
  `Client.UI.HudFXBoot` (wires tags, incl. clones). Player attribute `ReducedMotion = true` disables shake/flash.
  ONE UIScale per object (HudFX reuses an existing one -- two UIScales fight).
- **Layout:** stat rail top-centre (LIVES / WAVE + progress / ENEMIES / TIME); Ready/Skip under it (WavePrep.Root);
  next-wave preview under TIME; boss bars below that (y 0.2); BossWarning band; cash pill above the hotbar; right
  column UNIT MANAGER / STAGE INFO / AUTO PLAY (+ GearButton -> Auto Play Settings) / speed. Right panels (Stage Info,
  Unit Manager, Auto Play Settings) are 0.32 x 0.98 full height; < 900 px wide = full-screen sheet; they yield to
  each other via SidePanelBus.
- **Harnesses (Studio):** `MatchHUD.BossWarning` attr `DevPreview = "<name>"`; `MatchEnd` attr `DevReveal = true`;
  `AutoPlaySettings` attr `DevOpen = true`; server `RS DevInfernalForce = true`.
- Auto Play Settings data + rules: see the AutoPlayService header (`Counters.Global.AutoPlay`).

## B113 -- enemy name above the floating bar
`RS.UITemplates.EnemyHealthbar` canvas is now 4 x 1.25 studs (StudsOffset 2.95, bar centre unchanged at 2.6):
`Background` on the bottom 44 % (AnchorPoint 0,1), `NameText` (bold, dark outline) in the top half. Before,
NameText sat ABOVE a 0.55-stud canvas, and a BillboardGui only draws inside its own size, so the name was
never visible. `FloatingHealthbars` sets the text from the enemy's `DisplayName`; Simplify Health Bar hides it.

## B116 -- wave flow rebuilt (user's spec)
Timeline (`WavePrepConfig`, virtual seconds): READY phase -- a WAIT, not a build phase (B125: NOTHING can be placed until the match starts; it waits for players still arriving through the teleport and for loadout changes on the Units screen) -- B124: NO timer until someone votes (solo: READY / Auto Vote Start starts at once; party: the first vote starts the 30s `InitialCountdown`, everyone voting ends it early; `PrepWaiting` in the snapshot, `RunPrep{ WaitForFirstVote }`) -> per wave:
**5s COUNTDOWN** (`WaveCountdown`, prep label `Countdown`; the counter still shows the previous wave, 0 / 15
first) -> wave starts (counter up, income paid, enemies spawn -- one instant) -> **+10s NEXT-WAVE INFO**
(`NextWaveInfoDelay`; WavePrep.Preview "NEXT: WAVE N+1", income + enemy chips; data = `WavePreview`, now
pushed from `WaveDirector.UpcomingWave` for the NEXT wave) -> **+15s SKIP WAVE** (`SkipVoteDelay`) with a
**30s timer** (`SkipWindow`; WavePrep.Root TimerLabel + draining TimerBar) -> skip (unanimous) / timer /
wave fully cleared -> both hide -> next COUNTDOWN. Last wave: no skip phase.
- `WavePrepService` replicates `PrepDuration` (client derives elapsed). Widgets: WavePrep.Countdown
  ("WAVE N INCOMING" + big number, pulses each second), Root (skip), Preview (info); all animate in (Back pop)
  and out (shrink, then hide) via `setShown`.
- MatchHUD.StatusLine: only "Build Phase - Ns", Preparing, VICTORY / DEFEAT -- hidden otherwise (the old
  "Next Wave - Ns" / "Wave N in Ns" text is gone). MatchAudio boss warning fires with the info popup.
- **Auto Play zone rings** (AutoPlaySettingsUI): the unit RangeIndicator (animated dashed ring) -- GREEN =
  Normal (units) range, PINK = Farm range; follow the aim while picking; stay on the zone while the panel is
  open or Auto Play is ON; local player only. Replaces the flat ZoneMarker part.

## B117 -- enemy healthbar look + random wave-banner lines
- `RS.UITemplates.EnemyHealthbar` (4.4 x 1.35 studs, bar centre still 2.6 studs up): violet glass bar
  (`Glass` gradient) + gold `Edge` stroke, red fill with `Shade` gradient and a `Shine` strip, 3 quarter
  `Ticks`, cream `DamageTrail`, heavy outlined HP text, cream outlined name. Shared with summon bars (green).
- **Simplify Health Bar = the optimized mode:** `FloatingHealthbars.applyDetail` turns every decoration off
  (gradients/stroke disabled, shine/ticks/trail hidden, flat dark background, name + HP text hidden) ONCE per
  mode change; the fill snaps (no tweens). Normal mode keeps the tweened fill + trailing damage.
- Wave banner subtitle: `RS.Configs.Global.WaveBannerLines` (pools First / Boss / Final / General --
  motivational, memes, provocations; edit freely, keep lines ~32 chars). `Pick` never repeats the last line;
  boss detection uses the previous next-wave preview.

## B118 -- stage tag difficulty + animated XP bar
- MatchDirector now pushes `Difficulty` = the PLAYER'S choice ("Hard" when `DifficultyMode` is "Insane" --
  the Lobby's Hard -- else "Normal"); before it pushed the stage's own label, always "Normal". HudPanels
  colours the StageTag ModeLine (Hard red, Normal green); the Stage Info "Mode" row / pill follow.
- XP bar (Game `XPBarGui.XPBar`, HudPanels `animateXP`; Lobby `ExpBar`, ExpBarController `render`): fill
  slides (Quint), XP number rolls up, level-up = fill to 100% -> gold "LEVEL UP!" pop -> refill from 0,
  sheen (`Fill.Sheen.Sweep` gradient) sweeps every 4 s, first paint animates from empty. Harness attribute
  `DevXP` ("level,xp,need" Game / "level,xp" Lobby) plays it without touching data.
