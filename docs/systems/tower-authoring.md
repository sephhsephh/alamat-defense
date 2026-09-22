# Tower authoring — attacks, animations, VFX and upgrades (B78)

**Read this before adding or editing a tower.** Copy `RS.Configs.Towers._Template` to start a new one.
Everything below is DATA. Adding a tower — however its attack behaves — should never need new code.

**Owner:** AD-Game. **Place:** Game (configs + runner). The Lobby only previews units (idle in viewports).

---

## 1. The model in one page

A tower has **stats per upgrade tier** and **attacks declared once**. A tier says which attack it uses:

```lua
Idle = { Anim = nil, FadeTime = 0.2 },

Attacks = {
    Basic     = { Anim = ..., AnimLength = 1.0, Hits = { ... } },
    Empowered = { Anim = ..., AnimLength = 1.4, Hits = { ... } },
},

Upgrades = {
    [1] = { Attack = "Basic",     Damage = 30,  ... },
    [2] = {                       Damage = 50,  ... },   -- inherits "Basic"
    [5] = { Attack = "Empowered", Damage = 900, ... },   -- the attack CHANGES here
    [6] = {                       Damage = 1500, ... },  -- inherits "Empowered"
}
```

A tier names an `Attack` **only when it changes it**. Every later tier inherits the last one named.
That is the whole mechanism for "on upgrade 5 it becomes a different attack".

**An attack is a list of HITS.** One hit = one moment damage is dealt. Weights **must sum to 1.0**:
one attack always deals one attack's worth of the tower's damage, however many hits it is cut into,
so the damage number on the card keeps meaning what it says.

### The life of one hit

```
animation marker fires  ->  ReleaseVFX at the tower
                            |
                            +-- Projectile?   fly to the aim point (travel = distance / Speed)
                            +-- ImpactDelay?  wait that many seconds
                            +-- neither?      land immediately
                            |
                            v
                        ImpactVFX at the landing point + damage inside the tier's shape
```

---

## 2. Field reference

### Attack profile (`Attacks.<Name>`)

| Field | Meaning |
| --- | --- |
| `Anim` | Animation id. A raw number or `rbxassetid://...` both work. nil = no animation (still fires). |
| `AnimLength` | Seconds. **The cadence floor** — the tower cannot attack again until this elapses, even at SPA 0. |
| `Element` | Optional. Overrides the tower's element for this attack only (a fire mage's bolt). |
| `Movement` | Optional, melee. `{ Style = "Dash"\|"Teleport", Speed, StandOff, HoldTime? }` — see §4. |
| `Hits` | The hit list, below. |

### One hit (`Hits[n]`)

| Field | Meaning |
| --- | --- |
| `Marker` | Animation event name. Repeat the same name in the clip for repeat hits: the Nth firing runs the Nth hit that names it. |
| `At` | Seconds into the animation. **The fallback** if the marker never fires — always set it. |
| `Weight` | This hit's share of the tower's damage. All weights in one attack sum to 1.0. |
| `Targeting` | `"Primary"` the tower's target · `"Fresh"` a different enemy per hit · `"Area"` no aim target, the shape anchors on the tower. |
| `ReleaseVFX` / `ReleaseSound` | Played at the TOWER, the instant the marker fires. |
| `Projectile` | `{ Speed, VFX, ArcHeight }` or nil. Present = damage lands on arrival. |
| `ImpactDelay` | Seconds between release and impact when there is no projectile. |
| `ImpactVFX` / `ImpactSound` | Played where the hit LANDS, the instant damage is dealt. |
| `Shape` | Optional per-hit shape override, same fields as a tier's shape. |

### Tier (`Upgrades[n]`)

`Attack` (when it changes) · `Damage` · `Range` · `SPA` (seconds per attack, floored by `AnimLength`)
· `CritChance` / `CritMultiplier` · `AttackShape` + its size fields · `ShapeOrigin` (`"Target"`/`"Tower"`)
· `ShapeFalloff` (damage multiplier for non-primary targets) · `OnHitEffects` · `UpgradeCost` (nil on the last tier).

Shapes and their required fields: **Circle** `ShapeRadius` · **Box** `ShapeWidth`+`ShapeLength` ·
**Cone** `ShapeAngle`+`ShapeLength` · **FullAoe** (uses the tower's `Range`).

---

## 3. The animation contract

- The **animation is the clock.** Author a marker (Roblox calls it a KeyframeMarker) on the frame
  where the tower lets go, and name it in the hit. The project's convention is `ProjectileRelease`
  for a thrown attack, `Hit` for a melee connect, `Tick` for a repeating pulse.
- **Repeat the marker** for repeated hits: three meteors = the same `ProjectileRelease` marker three
  times in one clip.
- **Every marker-driven hit also needs `At`.** If the clip has no markers yet (or one is missing) the
  timer fires the hit anyway. A tower with no animation at all still attacks correctly — it just does
  not visibly animate. This is deliberate: ids are authored late here.
- Animations play at **game speed**, so a clip stays in step with the virtual clock at 2x/3x.
- **Idle** loops whenever the tower is not mid-attack (nothing in range, and the gap between swings).
  Author it at Idle priority; attacks at Action priority play over it.

---

## 4. Melee: dash out, dash home

`Movement` on the profile moves the **model** only. The tower's placement never changes:
`TowerController.HomeCFrame` is captured once and `GetPosition()` always answers from it — so range,
auras, selling, the placement grid and the client's range ring all behave as if the tower never left.
A knight that lunges 10 studs does **not** gain 10 studs of range.

The dash stops `StandOff` studs short of the enemy and faces it. The whole trip (out, hold, back) is
fitted inside `AnimLength`, so the tower is home before it may fire again. `Style = "Teleport"` is the
same trip with no travel time.

---

## 5. Five worked examples

| Tower | Shape of the attack |
| --- | --- |
| **Mage** (`Attacks.Cast`) | 1 hit, weight 1.0, `Projectile { Speed = 60 }`. Release VFX at the hand, orb flies, impact where it lands. The plain case. |
| **Fire mage** | 1 hit, **no projectile**, `ImpactDelay = 0.5`. Rune lights under the enemy on release, flame erupts half a second later. A delay is honest; an invisible fast projectile was not. |
| **Meteor** (`Barrage`) | 3 hits, weights 0.34/0.33/0.33, `Targeting = "Fresh"` — three rocks on three different enemies, chosen by the tower's own targeting mode, reusing the primary if the wave is thinner. |
| **Meteor** (`Cataclysm`, top tier) | 1 hit, weight 1.0, `Targeting = "Area"`, `ImpactDelay = 0.45`, per-hit `Shape = FullAoe`. The same tower, a different attack, from one `Attack = "Cataclysm"` line. |
| **Babaylan** (`Pulse`) | 5 hits × 0.20, `Targeting = "Area"` — one spin, five ticks, the field re-scanned each tick so a latecomer eats ticks 3-5. |
| **Knight** (`Slash`) | 1 hit + `Movement` — dashes to the target, swings on the `Hit` marker, dashes home. |

---

## 6. Adding a new tower — checklist

1. **Copy `_Template`** to `RS.Configs.Towers.<Id>`; the module name, `Id` and the `ItemCatalog`
   entry must all match.
2. **Register it** in `TowerConfigRegistry`.
3. **Add the rig IN BOTH PLACES — this is a user rule (B79).** The Game needs it at
   `ModelStoragePath` (`RS.TowerModels`) to spawn the tower; the LOBBY needs the same rig in
   `RS.UnitModels` or every card, hotbar slot and preview of that unit draws `Placeholder` instead.
   **A new unit is not done until it exists in both.** Give it a `PrimaryPart` and an
   `AnimationController` or `Humanoid`, and stamp the same `IdleAnim` attribute on both copies.
4. **Fill `Attacks`**: one profile per distinct attack, each with its hit list. Weights sum to 1.
5. **Fill `Upgrades`**: numbers per tier; name an `Attack` on tier 1 and again wherever it changes.
6. **Author the clips** and put the marker names from step 4 in them. Set `IdleAnim` on the display
   rig (an attribute) so previews animate.
7. **Price it** in `UnitStatsCatalog` (`Costs`) — the validator at boot checks the cache against the
   live config, so a mismatch is caught immediately.
8. **Boot the Place.** `[TowerValidate]` prints one line: either OK, or exactly what is wrong.

### Debugging a tower that feels wrong

Set `ServerStorage:SetAttribute("DevDebugAttacks", true)` and watch the output:

```
[Attack] Meteor/Barrage hit 1/3 weight 0.34 -> 73.4 dmg (Fresh)
[Attack] Babaylan/Pulse hit 3/5 weight 0.20 -> 28.8 dmg (Area)
```

One line per landed hit: which tower, which attack, which hit of how many, its weight, the damage it
produced and how it picked its target.

---

## 7. Where the code lives

| Module | Job |
| --- | --- |
| `Server.Towers.AttackProfile` | Resolves tier → profile (+ the legacy inline shape), normalises the hit list, and answers "is this a sequenced attack?" |
| `Server.Towers.AttackSequencer` | Plays the animation and runs the hit list: markers, projectiles, delays, VFX. |
| `Server.Towers.AttackResolver` | All damage math. Anchors the shape, finds who is inside, rolls crit once per hit. |
| `Server.Towers.MeleeMover` | The dash. Model only, never the placement. |
| `Server.Towers.TargetingSystem` | `SelectTarget` (one) and `SelectTargets` (N, for `Fresh` hits). |
| `Server.Towers.RigAnimator` | The only place that touches Animators. Accepts number or string ids. |
| `ServerScriptService.TowerAttackValidate` | Boot-time check of every config. |
| `Shared.UIKit.UnitCard.playIdle` | Plays a model's `IdleAnim` inside a ViewportFrame (both Places) and STEPS its Animator every frame; falls back to `UnitCard.DefaultIdleAnim`. |

## 8. Gotchas paid for in blood

- **The router asks the profile, not the tier.** It used to check `stats.Anim or stats.Projectile`;
  the moment an attack moved into a named profile those tier fields vanished and the tower silently
  fell back to the instant path — no animation, no multi-hit, no VFX. It now asks `AttackProfile.Has`.
- **A `Camera` inside `StarterGui` does not replicate** (B77) — viewport framing rides as attributes.
- **A ViewportFrame RENDERS but does not SIMULATE** (B79). Loading and playing an idle track on a rig
  inside one is not enough: nothing advances the Animator, so the rig stands frozen on frame 0 — the
  user saw this as "the units in viewport frames are just standing". `UnitCard.playIdle` now calls
  `Animator:StepAnimations(dt)` every `RenderStepped` for as long as the rig is in the DataModel.
  Anything else that animates a rig inside a viewport must do the same.
- **A rig with no `IdleAnim` falls back to `UnitCard.DefaultIdleAnim`** (stock R15 idle, B79), so an
  unauthored unit previews as a breathing character rather than a statue. Authoring `IdleAnim`
  replaces it; there is no third state.
- **Weights that do not sum to 1** make a tower quietly stronger or weaker than its card. The
  validator catches it at boot.
- **A hit with neither `Marker` nor `At` never fires.** The validator catches that too.
