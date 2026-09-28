# Tower VFX — authoring effects without writing code (GAME)

<!-- owner: AD-Game + the artist | place: Game | since: B82 (2026-09-25) -->

Every visual moment of an attack is an **authored template** you drop in Studio. No code changes,
ever: the tower config names an effect (or names nothing at all) and the client finds the closest
match in the template tree.

## The tree

```
ReplicatedStorage.VFXTemplates
  Towers
    Bathala/                              <- the tower's Id, exactly as in its config
      Attacks/
        Basic/      Release  Telegraph  Projectile  Impact
        Ultimate/   Release             Projectile  Impact     <- the tier-5 attack swap
      Release  Projectile  Impact                              <- this tower's own defaults
      Placed  Upgraded  Sold                                   <- lifecycle, per tower
    _Default/       Release  Telegraph  Projectile  Impact     <- the house defaults (shipped)
  Shared/           FireImpact  HolySlash  ...                 <- reusable across towers
  TowerLifecycle/   Placed  Upgraded  Sold                     <- the old shared lifecycle folder
```

`Release` plays at the tower the instant the attack lets go · `Projectile` travels to the target ·
`Impact` plays where the hit lands, as damage is dealt · `Telegraph` marks the landing spot on
release, for an attack with no projectile but a delayed impact (the fire-mage rune).

**Impact and Telegraph land at the target's FEET, not at the aim point (B84).** The aim point is the
target's centre of mass, so an effect anchored there hangs at chest height and reads as floating --
the user's words: "make sure the impact vfx plays on the feet of the target. right now its floating".
`AttackSequencer.feetPos()` takes the target model's `GetBoundingBox()` and drops the Y to the bottom
of that box, keeping X/Z from the aim point; **damage still resolves at the aim point**, so this is a
presentation change only, and a target with no model falls back to the aim point unchanged. Every
shipped `Impact` template therefore carries `Offset = (0, 0.25, 0)` -- just clear of the ground -- and
an authored ground effect should keep its Offset small for the same reason. Measured live: impact
0.24-0.25 studs above a Grunt's feet (bounding box 2.02-2.06 studs tall).

## How an effect is chosen

For a hit's `ReleaseVFX = "MageCast"` on Mage's `Cast` attack, first match wins:

1. an id containing a slash is an explicit path — `"Shared/FireImpact"`
2. `Towers/Mage/Attacks/Cast/MageCast`
3. `Towers/Mage/Attacks/Cast/Release`
4. `Towers/Mage/MageCast`
5. `Towers/Mage/Release`
6. `Shared/MageCast`
7. `Towers/_Default/Release`

So **a tower with no folder at all still looks alive** (house defaults), a tower with one folder gets
its own look everywhere, and only an attack that should differ needs its own subfolder. Naming an id
is optional — the folder name alone is enough.

⚠ Because a typo still plays *something*, the boot validator **`TowerVFXValidate`** prints, once:
how many named ids resolved to a template of their own, which fell through to a default, and which
towers have no folder yet. Check that line after adding art.

## What you author

A template is an **invisible anchor** — a Part (or a Model with a PrimaryPart) — holding Attachments
with ParticleEmitters, Beams, Trails, PointLights, Sounds. Nothing about the contents is prescribed:
whatever is inside plays. The anchor is anchored, non-colliding and non-query automatically.

Attributes on the ROOT tune how it is used:

| Attribute | Meaning |
| --- | --- |
| `Attach` | `World` (default, at the point the attack gives) · `Tower` · `Muzzle` (the rig's `Muzzle` attachment) · `Sky` (spawns `SkyHeight` studs above and aims down — meteors) · `Follow` (parented to the tower model, so it rides a melee dash) |
| `Offset` | Vector3, applied in the anchor's own space |
| `Rotation` | Vector3 of degrees (a ground ring is a cylinder at `0,0,90`) |
| `Orient` | `Forward` faces the direction of fire |
| `Duration` | seconds before cleanup (default 2) |
| `Loop` | leave emitters running for the whole Duration (projectile trails) |
| `SkyHeight` | studs for `Attach = "Sky"` (default 60) |
| `Linger` | extra seconds a projectile stays after it arrives (default 0.25) |

Per ParticleEmitter: `EmitCount` (default 16) and `EmitDelay` seconds.

### Impact / Telegraph size follows the attack's shape (B104)

The server sends the radius each hit covers (`AttackShapeRegistry.VisualRadius`: Circle `ShapeRadius`,
Box `(Width + Length) / 4`, Cone `Length / 2`, FullAoe `Range`), and the client scales the clone by
**radius / `BaseRadius`** before it emits -- particle size, speed and acceleration, parts, attachments,
beams, lights. So one effect fits every tier: author it at any size, then set on the ROOT:

| Attribute | Meaning |
| --- | --- |
| `BaseRadius` | the shape radius the art LOOKS right for (default 3). Knight's Slash impact = 5. |
| `ScaleToShape` | `false` = never resize this template |
| `MinScale` / `MaxScale` | clamps, default 0.5 / 4 |

Release and Projectile effects are never scaled. The scale is uniform (a particle cannot stretch on
one axis). The impact still lands at the target's feet.

**Rig attachments beat offsets.** Put an Attachment named `Muzzle` on the tower rig and every
`Attach = "Muzzle"` effect fires from exactly there, per tower, with no numbers in any config.

## THE ONE THING TO GET RIGHT: the folder is named after the ATTACK

The path is built from **the tower's `Id`** and **the attack's name in its config** — the key in the
`Attacks = { ... }` table, not the tower's name, not the animation, not the VFX id.

```lua
-- Configs.Towers.Mage
Attacks = {
    Cast = { ... },        -- THIS name
}
```
```
VFXTemplates.Towers.Mage.Attacks.Cast.Release     -- must match it exactly
```

A folder that matches no attack **never plays** — `Knight/Attacks/Cast` when Knight's attack is
called `Slash` is dead weight. `TowerVFXValidate` prints exactly that at boot, with the tower's real
attack names, so you can rename the folder.

**Nothing is named in the config.** B82 shipped with leftovers like `ReleaseVFX = "MageCast"` from
the old system, which matched no template and made the tree look broken — those are gone (B83). A
config only names an effect to *override* its folder, e.g. `ReleaseVFX = "Shared/HolyFlash"`.

**A tower still on the legacy inline attack has no attack name** (Archer, Necromancer, Warchief).
Its effects go one level up, straight in `Towers/<Id>/{Release, Projectile, Impact}`.

## Adding a new unit's effects — the whole procedure

1. **Read the attack names** in `Configs.Towers.<Id>`: the keys of `Attacks`.
2. **Make the folders** in `ReplicatedStorage.VFXTemplates.Towers`:
   `<Id>/Attacks/<AttackName>` — one per attack the unit has.
3. **Copy a starting point**: duplicate `Towers/_Default/{Release, Projectile, Impact}` (or another
   unit's) into that folder. They already work; nothing else is required to see something in a match.
4. **Replace the art**: open a template, keep the invisible root part, and put *your* emitters,
   beams, meshes and lights under its Attachment. The root is the anchor — never make it the effect.
5. **Set the attributes** that place it (`Attach`, `Offset`, `Rotation`, `Orient`, `Duration`,
   `Loop`) and `EmitCount` on each emitter.
6. **Boot the Place** and read the `[TowerVFX]` line: it tells you what resolved and what did not.

That is the whole loop — **no code, no config edit**, for every unit from here on.

## The tree as it stands (B83)

| Tower | Folder |
| --- | --- |
| Mage | `Mage/Attacks/Cast/{Release, Projectile, Impact}` |
| Knight (melee) | `Knight/Attacks/Slash/{Release, Impact}` — Release is `Attach = "Follow"`, it rides the dash |
| Babaylan (5-tick pulse) | `Babaylan/Attacks/Pulse/{Release, Impact}` |
| Meteor | `Meteor/Attacks/Barrage/{Release, Projectile (Attach = "Sky"), Impact}` and `Meteor/Attacks/Cataclysm/{Release, Telegraph, Impact}` |
| Archer / Necromancer / Warchief | `<Id>/{Release, Projectile, Impact}` — legacy inline attacks, no attack name |
| Farm | none — it never attacks |

## The worked examples that ship

- `Towers/_Default/Release` — gold muzzle burst (`Attach = Muzzle`, `Orient = Forward`)
- `Towers/_Default/Projectile` — glowing bolt with a trail (`Loop`, `Linger`)
- `Towers/_Default/Impact` — bigger burst, sitting 0.25 studs off the ground (B84: it lands at the
  target's feet, so it no longer needs the 1.2-stud lift it shipped with)
- `Towers/_Default/Telegraph` — flat orange ring (a cylinder with `Rotation = 0,0,90`)
- `Towers/Mage/Attacks/Cast/{Release,Projectile,Impact}` — the same three, recoloured purple, as the
  per-tower/per-attack sample to copy

## How the tower types map onto it

| Tower | Authoring |
| --- | --- |
| Mage with a bolt | `Release` at the muzzle + `Projectile` + `Impact` |
| Fire mage, no projectile | `Telegraph` on the ground + `Impact` after `ImpactDelay` |
| Meteor, 3 rocks on 3 enemies | one `Projectile` with `Attach = "Sky"`; the 3 hits clone it to 3 targets |
| Wind mage, 5 ticks | one `Impact` per tick, `Targeting = "Area"` |
| Melee knight | dash trail as `Attach = "Follow"` on the rig, `Impact` at the target |
| Per-tier upgrade look | a second attack profile + its own `Attacks/<Name>` folder |

## The rails

- **Client only.** The server sends ids; templates never replicate and never touch gameplay.
- **Capped**: 60 live effects at once, 8 copies of any one template — over the cap is skipped.
- **Culled** past 260 studs from the camera; `Low Detail` halves every emit count.
- With the VFX setting off, sounds still play — the fight is never muted by a graphics option.

## Where the code lives

| Module | Job |
| --- | --- |
| `RS.Shared.VFXLibrary` | The lookup rules (shared with the validator). Pure. |
| `Client.VFX.VFXPlayer` | Clones a template, anchors it, ignites it, cleans it up. Caps and culling. |
| `Client.VFX.VFXController` | Routes the server's events; keeps the old built-in shapes as fallback. |
| `Server.Networking.VFXBroadcaster` | `AttackVFX(kind, position, ctx)` + `Projectile(..., ctx)`. |
| `ServerScriptService.TowerVFXValidate` | The boot report. |
