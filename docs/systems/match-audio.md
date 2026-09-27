# Match audio (GAME)

<!-- owner: AD-Game | place: Game | since: B81 (2026-09-22) -->

Every sound is a real `Sound` under `SoundService` — swapping one is pasting a SoundId in Studio.
**All B81 ids are PLACEHOLDERS from the Creator Store** (attribute `Placeholder = true`, and
`PlaysWhen` says when each fires); every one was preloaded and confirmed playable.

## Match events — `SoundService.SFX.*` (flat, 2D)

| Sound | Plays when | Where |
| --- | --- | --- |
| `WaveTick` | each second of the last 5 before a wave (build phase + intermission) | `Client.Audio.MatchAudio` |
| `NextWave` | a wave starts | `MatchAudio` |
| `BossWarning` | the intermission preview shows a boss in the next wave — or a boss appears unannounced | `MatchAudio` |
| `Victory` / `Defeat` | the match ends | `MatchAudio` |
| `EnemyKilled` | an enemy's Health hits 0 (a leak is not a kill), throttled 0.05 s | `MatchAudio` |
| `CashWave` | wave-start or wave-complete cash lands | `MatchAudio` |
| `CashFarm` | farm income lands | `MatchAudio` |
| `UnitPlaced` | your placement succeeds | `PlacementController` |
| `UnitInvalid` | you try to place on a red ghost, or the server refuses | `PlacementController` |

Cash sounds need to know **why** cash moved, so `EconomyManager.AddCash` takes an optional reason
(`"WaveStart" | "WaveReward" | "Farm" | "Kill"`) that rides `Remotes.Economy.CashChanged` as a second
argument. Cosmetic only — nothing server-side branches on it.

## Boss music — `SoundService.BGM.Boss`

While any enemy with `IsBoss` is alive, `MatchAudio` plays `BGM.Boss` through `UIKit.Sound.playBGM`
(cross-fade); when the last boss dies or leaves it hands back to the act's track. Proven live both
ways with a probe boss.

## Attack sounds (per tower, 3D)

On any hit in a tower's attack profile (see `tower-authoring.md`):

```lua
ReleaseSound = "Atk_MagicCast",                                  -- at the tower, on release
Projectile   = { Speed = 60, VFX = "MageOrb", Sound = "Atk_Fireball" }, -- flies WITH the bolt
ImpactSound  = "Atk_Explosion",                                  -- where the hit lands
```

A value is either the **name** of a Sound under `SoundService.SFX` (recommended — the id then lives in
one place and Volume is tuned in Studio) or an **asset id** (number, `"123"` or `"rbxassetid://123"`).
`ProjectileSound` on the hit is the same as `Projectile.Sound`. `Client.Audio.GameSfx` plays them as
positional sounds in the SFX group, capped at 6 overlapping copies each. **Sounds play even with the
VFX setting off** — turning off particles must not mute the fight. The Mage carries all three as the
worked example.
