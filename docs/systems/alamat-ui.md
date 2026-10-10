# Alamat UI kit — the brand button system
<!-- owner: AD-UI | scope: Lobby now, Game next (portable) | last-verified: 2026-10-10 (B138) -->

ONE button design for the whole game, so every screen reads as "Alamat Defense": the **Sun-gem** — a
rounded gem with a bevelled **gold rim** (its light travels round), 4 gold **corner studs** with coloured gems,
a deep coloured **core** with a faint engraved **magic seal**, a gloss, the icon, and a night ribbon with a
**gold serif label**. Buttons differ ONLY by `Theme` (colours) and `Variant` (layout). Purple + gold is the
house identity; each button family gets its own palette so the HUD stays colourful.

## Where it lives (portable — copy the folder to the Game for the Game-HUD batch)
`ReplicatedStorage.AlamatUI`
- `Theme` — palettes, the gold rim sequence, label gold, fonts, image VFX ids.
- `AlamatButton` — THE animator (tag `AlamatButton`); builds nothing.
- `Templates.AlamatButton` — the authored master (tools/alamat_ui_build.luau), `Templates.Selector` (gamepad ring).
Not shared canon yet (no manifest entry): promote to `shared/` when the Game adopts it.

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

## VFX art (white on transparent, tinted by a UIGradient named `Tint`) — Creator Store, picked visually
RuneRing 108844775186607 · MagicCircle 113290594421442 · Engraving 95270696231518 · GlowRing 9864075653 ·
Burst 7229481183 · Flare 124607288176561 · Streak 3052949762 · Sparkles 6997866340 / 71639137167582 /
81834701835654. No frame-built VFX (user rule).

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
