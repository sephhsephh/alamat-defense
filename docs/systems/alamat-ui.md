# Alamat UI kit — the brand button system
<!-- owner: AD-UI | scope: Lobby now, Game next (portable) | last-verified: 2026-10-10 (B138) -->

ONE button design for the whole game, so every screen reads as "Alamat Defense": the **Sun-gem** — a
rounded gem with a bevelled **gold rim** (its light travels round), 4 gold **corner studs** with coloured gems,
a deep coloured **core** with a faint engraved **magic seal**, a gloss, the icon, and a night ribbon with a
**gold serif label**. Buttons differ ONLY by `Theme` (colours) and `Variant` (layout). Purple + gold is the
house identity; each button family gets its own palette so the HUD stays colourful.

## THE PLATE — the universal rectangle button (B151, user rule: every rectangle action button uses it)
Equip, Claim, Buy, Summon x1, Teams, Apply, Cancel ... ONE look + ONE motion everywhere, colour per button.
- **Look**: the button ROOT is the colour (`BackgroundColor3`; `Theme` attribute = a palette, or `Custom` = whatever
  colour you set in Studio) with a `Core` luminance gradient; a gold `Rim` stroke whose light travels round; `Inner`
  engraved line, `Gloss`, `Lip` (bevel shadow), `ShineClip.Streak`, `Flash`, `Burst` (tinted), two corner `Sparkles`,
  `Pop` UIScale; labels in the gold-serif Label font with a dark outline (a TextButton's own text is mirrored into
  `PlateText`). Because the colour lives on the root, a script that recolours (green Claim / grey Incomplete) or dims
  (BackgroundTransparency) a button keeps working untouched.
- **Motion** (AlamatButton, Variant `Plate`): hover / gamepad selection lift x1.05 + brighter rim + shine + sparkles;
  press x0.94; Activated white flash + burst + Click sound; idle shine every 4-9 s. `StarterPlayerScripts.AlamatUIBinder`
  binds every tagged button in PlayerGui (both Places). The old UIKit.Button tag / ScreenFX juice step aside (`NoFX`).
- **Palettes for plates**: Gold primary/confirm · Jade claim · Ruby destructive (sell, discard, disband) · Stone
  secondary (cancel, back, reset, filters) · Violet summon/special · Azure navigation · Ember events · Night quiet.
- **Make one**: clone `RS.AlamatUI.Templates.AlamatPlate`, or in Edit:
  `local P = require(game.ServerStorage.DevTools.AlamatPlate:Clone())` then `P.convert(btn, "Jade")` (restyles an existing
  button IN PLACE, keeps its name + the children scripts use) / `P.make(parent, name, text, theme)`. Source:
  `tools/alamat_plate.luau`; the rollout list (every converted button + its theme): `tools/alamat_plate_rollout.luau`.
- Gotchas fixed in the tool: a re-used UIStroke may be `ScaledSize` (thickness = a FRACTION of the button -> a 176 px
  ellipse) -> forced FixedSize; a TextButton whose own text is hidden behind a Label child gets no PlateText.
- **No UIPadding on a plate ROOT (B157, user: "looks like a button inside a button").** A root UIPadding insets the
  plate's own layers, so the colour root shows as a rim around a smaller plate. `P.unpad(btn)` (run first by
  `P.convert`) remaps the button's content children into the padded rect and deletes the padding (skips a button
  that lays out children with a UIGridStyleLayout). Rolled out B157: Lobby 65 + Game 21 plates
  (`ServerStorage._UIBackup_B157`). `convert` now WARNS when it drops a second UIStroke / UIGradient (the PlayGUI
  difficulty `SelectedStroke` died that way in B151; selection is the authored `SelectedRing` overlay now).
- Rolled out B151: Lobby 140 buttons (Units, Quests/Achievements, Silver Shop -- Buy shows the Silver ICON + price, Summon,
  Events, Items, Daily, Battle Pass, Codes, Play menu, Ascension, Evolve, Crafting, Stat/Trait reroll, misc); Game 50
  (Units copy, Quests, Match End, Match HUD right buttons + speed, Wave prep READY, Placement controls, Auto Play
  settings). Tower panel + Unit Manager convert in their B153 rebuild. Backups `ServerStorage._UIBackup_B151`.

## Where it lives (shared canon in BOTH Places since B151; the Game has no Sun-gem HUD yet)
`ReplicatedStorage.AlamatUI`
- `Theme` — palettes, the gold rim sequence, label gold, fonts, image VFX ids.
- `AlamatButton` — THE animator (tag `AlamatButton`); builds nothing.
- `Templates.AlamatButton` — the authored master (tools/alamat_ui_build.luau), `Templates.Selector` (gamepad ring).
`Theme` + `AlamatButton` are SHARED CANON (`shared/src/AlamatTheme.luau`, `AlamatButton.luau`). Templates are tool-built.

## Variants (same parts, different layout) and palettes
| Variant | Use | Notes |
|---|---|---|
| Tile | HUD left grid | square gem + label ribbon |
| Hero | PLAY / SUMMON | bigger, magic seal always turning, glow breathing |
| Banner | live cards | wide; `Main.Texts` holds the lines; core fades colour -> night |
| Gem | utility buttons | round, no label |
| Pill | currency amounts | `IconImage` + `AmountLabel` at the root (CurrencyBarController) |

Palettes (`Theme.Palettes`): Gold (Play, Battle Pass, currency gear), Violet (Summon), Azure (Units, Daily),
Teal (Inventory), Ember (Quests, Events), Indigo (Index), Jade (Shop), Rose (Profile), Night (utilities, pills).

## Motion (AlamatButton)
idle: rim light travels + seal drifts + every 3.5-8.5 s a shine streak and a sparkle (heroes 1.8-3.8 s) ·
hover / gamepad selection: lift x1.08, tilt -2.5 deg, rune ring fades in and turns, icon pops, sparkle burst ·
press: squash 0.92 · activated: glow-ring pulse + radial burst flash + icon pop · attention
(`setAttention`): faster shines + a pulse every 1.6 s · `glint`: silent shine (currency went up) · `flash`.
One Heartbeat loop for all buttons; skipped while their ScreenGui is disabled. Rim / ribbon / text stroke
widths follow each button's on-screen size, so the look is identical on every device; all sizes are scale.
**B140: `Main.ShineClip` is a CanvasGroup + UICorner, not a ClipsDescendants Frame** -- hover tilts Main -2.5 deg and Roblox
stops clipping under a rotated ancestor, so the streak spilled out of the gem. Never go back to a clipping Frame here.

## VFX art (white on transparent, tinted by a UIGradient named `Tint`) — Creator Store, picked visually
RuneRing 108844775186607 · MagicCircle 113290594421442 · Engraving 95270696231518 · GlowRing 9864075653 ·
Burst 7229481183 · Flare 124607288176561 · Streak 3052949762 · Sparkles 6997866340 / 71639137167582 /
81834701835654. No frame-built VFX (user rule) -- B158 swapped every one left (`tools/vfx_images_build.luau`,
`docs/systems/screen-fx.md`). **Burst is NOT white-on-transparent** (dark body): never lay it over a scene.

## The Lobby HUD (tools/alamat_hud_build.luau — "Command Rails", user pick)
- `Left.Buttons` 2x3 tiles: Units, Inventory, Quests, Index, **Shop** (new: ClientEvents.OpenShop), Profile
  ("coming soon" toast — nothing owned it before).
- `Right.Hero`: SUMMON + **PLAY** (moved from Left; PlayController / SummonGUIController / LobbyHotkeys paths updated).
- `Right.Buttons` live cards: Battle Pass (tier + XP bar from GetBattlepass), Events (featured active event +
  countdown from EventQuestConfig.Status), Daily Rewards (DailyRewardsController's ResetTime; attention while claimable).
- `Right.UpperRight` gems: Codes, Leaderboards, Invite, Inbox, Settings. `Top.CurrencyBar`: Night pills that
  COUNT to new amounts and glint when they rise; Gold gem gear.
- Badges (NotificationController) are crimson gems; a visible badge puts its button in attention mode.
- Gamepad: Y cycles `GamepadHud` roots Left (1) -> Hero (2) -> cards (3) -> utilities (4); PLAY is the default.
- `HUD.AlamatHudController` binds + entrance (staggered pop-in after the loading veil) + live cards + Shop/Profile.
Old HUD: `ServerStorage._UIBackup_B138.HUD`.

## Add a button
Clone `Templates.AlamatButton` (or run the builder's `make`), set `Theme` + `Variant` + label + icon,
`AlamatButton.applyTheme(btn, theme)` in Edit, parent it. The HUD controller binds anything tagged.
Icons: placeholders until the user generates them (prompt rows in `docs/design/icon-art-style.md`).
