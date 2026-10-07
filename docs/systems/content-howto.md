# Content how-to (GAME place) -- rigs, passives, abilities, support, summons, enemies, maps

<!-- owner: AD-Game | scope: game (+ Lobby UnitModels) | migrated B123 (2026-10-07) from the retired
     in-Studio ServerStorage.Documentation.HowTo (2026-07). ADDING A TOWER and its ATTACKS is
     tower-authoring.md (canon since B78) -- this file covers everything around it. -->

## Rig from an avatar copy
Towers / enemies / summons are prepped copies of a Roblox avatar. Delete what fights the game systems:
`Health` + `Animate` scripts, `AudioEmitter`, `CollisionPart`, any other Script / LocalScript. Keep the
HumanoidRootPart (as PrimaryPart), the R15 parts, BodyColors / clothing / accessories.
Then: `PrimaryPart = HumanoidRootPart`; anchor ONLY the root; `PivotOffset = CFrame.identity` (the pivot
rule, `match-architecture.md`); every other part `CanCollide = false` + `Massless = true`.
- Animation: the early rule was "delete the Humanoid, add AnimationController + Animator" (an anchored
  root plus a Humanoid's balance controller launched rigs skyward). Today both kinds exist -- e.g.
  Bantong / Handyong carry a Humanoid with AnimationConstraint joints -- and `RigAnimator` /
  `UnitCard.playIdle` accept either. If a rig rises on attack, the Humanoid is the first suspect.
- Placement: towers in the Game's `RS.TowerModels.<Id>` **and** the Lobby's `RS.UnitModels.<Id>`, same
  name, same `IdleAnim` attribute (user rule -- remind the user every time). Enemies:
  `ServerStorage.Enemies.<...>`; summons: `ServerStorage.SummonModels.<Name>`. Bosses ~1.35x scale.

## Elements
`Element = "Fire"` on a TowerConfig (Fire / Water / Nature / Light / Dark / Holy / Cosmic / Neutral) and on
enemy configs. Strong x1.5, weak x0.75, else 1.0; absent / Neutral = 1.0. One file tunes it all:
`RS.Configs.Global.ElementConfig`. (VFX also follow the element -- `tower-vfx.md`.)

## Passives (always-on)
Reuse (config only): `Passives = { { Id = "AllyDamageAura", Params = { Stat = "Damage", Mult = 1.1, Range = 20 } } }`.
The full shipped catalogue + params is `tower-authoring.md` section 10b.
New passive (a little code): `SSS.Towers.Passives.<Name>` returning any of the OPTIONAL hooks
`OnPlaced(ctx)`, `OnStep(ctx, dt)`, `ModifyOutgoingDamage(ctx, enemy, damage) -> damage`,
`OnWaveIncome(ctx, waveIndex, waveConfig)`, `OnKill(ctx, enemy)`, `OnRemoved(ctx)` + one
`PassiveRegistry` line. `ctx = { Tower, Params, State }`. Runtime stat changes:
`ctx.Tower:AddBuff(source, stat, { Mult =, Add =, Duration = })` -- never mutate resolved stats. Require
other systems LAZILY inside hooks to avoid load-time require cycles.

## Active abilities
Reuse: `Abilities = { { Id = "Nuke", DisplayName = "Meteor Strike", Cooldown = 15, AutoActivate = true, Params = { Scope = "Map", Mult = 6 } } }`
(B114: several per tower, optional `Icon` / `Description`, `CooldownScope = "Global"|"Local"`; the
pre-B114 single `Ability = { ... }` still reads as a list of one -- every shipped tower uses it today;
`RS.Shared.AbilityList` is the one reader). New ability: `SSS.Towers.Abilities.<Name>` with `Activate(ctx)` and optional
`CanActivate(ctx)` / `ShouldAutoActivate(ctx)` + one `AbilityRegistry` line. Cooldowns run on the
virtual clock; readiness is mirrored to Attributes for the panel.

## Support / farm towers
`Role = "Support"` (never targets or fires). Tier `Range` (meta-scaled) and `IncomePerWave` (TIER-only,
in `TowerStatResolver.NEVER_SCALED`). `Passives = { { Id = "FarmIncome" } }` pays the owner each wave;
add `AllyDamageAura` to buff neighbours.

## Summons (summon-on-kill)
`Passives = { { Id = "SummonOnKill", Params = { SummonId = "Charger", HealthMode = "EnemyHealthPct",
HealthValue = 0.6, Chance = 1.0, MaxAlive = 25 } } }`. HealthMode `EnemyHealthPct` (fraction of the
killed enemy's max HP) or `TowerDamagePct`. Charger = HP is a damage pool that rams through enemies;
Fighter = stops to attack in range. They walk the REVERSED path from the base; proximity, no physics.
New summon type: duplicate `RS.Configs.Summons.Charger/Fighter` + a `SummonConfigRegistry` line + a rig.
Kills are credited to the last DIRECT hitter (a DoT-only kill credits the last tower that hit it).

## Enemies
1. Duplicate a config under `RS.Configs.Enemies` (Health, Speed, Damage, Armor, Resistances, Immunities,
   Behaviors, ModelStoragePath, Animations.Walk, KillReward; optional Element, IsBoss, TurnSpeed, flying).
2. Register it in `EnemyConfigRegistry`. 3. Rig under `ServerStorage.Enemies`. 4. Use it from a wave's
   SpawnGroup `{ EnemyId, Count, Interval, Delay, PathId }` in `RS.Configs.Waves`.

## Status effects
A config under `RS.Configs.StatusEffects` (StatMultipliers, TickInterval, DamagePerTick, StackMode,
MaxStacks, DefaultDuration) + a registry line; apply it from an attack's on-hit effects, a
BonusVsStatus-style passive or a StatusBurst ability.

## Maps
Duplicate `ServerStorage.Maps._Template` + `RS.Configs.Maps._TemplateMap` (set Id + ModelStoragePath;
auto-registers, no registry line). Folders: `Paths/Path_<Id>/` waypoints walked in NAME order (01, 02...),
`TowerZones/` (parts are Ground unless `ZoneType = "Hill"`; a MODEL there is a zone made of all its
parts, inheriting its ZoneType -- B120; decor elsewhere is never placeable -- B121), `SpawnPoints/`
(part Name = Id), optional `Lighting/` (cloned into game.Lighting on load, removed on unload) + Music.
Walkable ground `CanCollide = true`, marker parts `CanCollide = false`.

## Verifying
Author in Edit, then Play. Prove runtime behaviour with `[DIAG]` prints in a REAL Script + the output
log -- never by requiring a live service from execute_luau (separate VM, see CLAUDE.md editing rules).
