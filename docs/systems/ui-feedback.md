# SYSTEM — UI feedback: button motion, audio, and the confirmation dialog

<!-- owner: AD-UI | home Place: BOTH | scope: shared -->
<!-- last-verified: 2026-08-19 (B32, live Play in the Lobby; deploy hash-matched in the Game) -->
<!-- split out of ui-kit.md at B32: that file was at 295/300 and this is three new subsystems -->

How the UI answers the player: what a button does when you touch it, what you hear, and how an
irreversible action asks permission. All three are **shared canon and identical in both Places**,
because a button that feels different in the Game than in the Lobby is a bug you cannot file.

## Buttons: one controller, one tag, zero per-button scripts

Tag any `GuiButton` with the CollectionService tag **`UIKitButton`** and
`StarterPlayerScripts.UIKitBootstrap` attaches `UIKit.Button` to it. That is the whole mechanism —
it predates B32 and is why hover, click, audio and animation could be given to every button in the
project at once. ~55 buttons are tagged in the Lobby.

### PANEL-STYLE vs FLAT is DETECTED, not configured (B32)

The user's rebuilt `HUD.Left.Buttons` put `UICorner` + `UIHoverStroke` **on `Main`** and left the
ROOT bare (aspect constraint only). Every older button does the opposite — corner and stroke on the
root, content inside. That single structural difference decides three behaviours, so it is detected
once rather than configured six times:

| | panel-style (furniture on `Main`) | flat (furniture on the root) |
| --- | --- | --- |
| what scales | **`Main`** | the whole button (B27 rule) |
| hover stroke | **GROWS from 0** to its authored `Thickness` | thickens from base × `HoverStrokeMult` |
| stroke gradient | **SPINS** (`Rotation`) | seamless `Offset` scroll |

Scaling `Main` still honours B27's rule — *"scale the thing that owns the corner and the stroke, or
the button comes apart at its edges"* — because on these buttons that furniture IS on `Main`. It is
also **layout-safe for free**: the instance the `UIListLayout` measures is the untouched root, so no
`Motion.isolate` wrapper is needed. Verified live — hovering `PlayButton` moved its sibling
`InventoryButton` **0 px**.

Detection means the ~55 existing buttons changed behaviour **not at all**. `ButtonStyle`
(`"panel"`/`"flat"`) overrides it.

### The rest of the B32 button spec

- **`LogoContainer` tilts 45°** on hover. It joins the icon lookup *after* `Icon` / `ButtonImgIcon`,
  so no existing button changed which instance it rotates.
- **Click = `Motion.pressPop`**: dip (Quad) → overshoot (Back/Out, the only non-Quint curve in the
  kit) → hand control back via `onComplete`, which re-asserts hover-or-rest. It deliberately does
  **not** guess where to land, because by the time a click finishes the button may have closed the
  screen it lived on. Bound on `Activated`, so it covers mouse, touch and gamepad and is silent on an
  inactive button for free.
- **A panel-style hover stroke thinner than 1px WARNS**, naming the instance and the value. No number
  is invented — the fix is one property in Studio, or the `HoverStrokeThickness` attribute.

Per-button attributes: `HoverSound` · `ClickSound` · `ButtonStyle` · `GradientMode` ·
`GradientSpinPeriod` · `HoverStrokeThickness`, plus everything `UIKit.Button`'s header lists.

New `Motion` primitives (all in `Motion.Tuning`, never per screen): `spinGradient` / `stopSpin`
(base rotation stored in the `UIKitBaseRotation` attribute, idempotent so a re-running controller
cannot stack tweens), `growStroke` (**owns `.Enabled`** — enabled BEFORE growing, disabled only
AFTER shrinking, because a disabled `UIStroke` tweening `Thickness` animates nothing at all: the
B27c hotbar bug), and `pressPop`.

## Audio: assigning a sound is pasting an id in Studio

**There is no audio config file.** Every sound is a real `Sound` instance under `SoundService`, in a
folder named after its category, and `UIKit.Sound` resolves it **by name**:

```
SoundService
  Groups/Master (SoundGroup) > UI · SFX · BGM
  UI  (Folder)   Hover · Click · Confirm · Cancel · Sell · Error · Open · Close
  SFX (Folder)
  BGM (Folder)   Lobby · Default · <actId>    e.g. Stage1_Act1
```

To add or retune a sound: drop a `Sound` in, name it, paste a `SoundId`. **To give a stage its own
music, name a Sound EXACTLY the act id** — `playBGM(actId)` falls back to `BGM.Default`, so an
unnamed stage is silent rather than broken. Act slots are created from `StageRegistry.List()` ids
rather than typed, so a renamed act shows up as a MISSING slot instead of a silently wrong one.

Instances rather than a table because a `Sound` carries Volume / Looped / TimePosition /
PlaybackSpeed as **authored** properties a designer can hear while tuning; a table would push all of
those through code and separate the ids from the volumes. `SoundGroups` because one Volume per
category is exactly what the PENDING unified settings screen needs, and the only way to duck music
under SFX later without touching every Sound.

API: `play(name, category?)` · `playBGM(name, opts?)` · `stopBGM(fade?)` · `currentBGM()` ·
`setCategoryVolume(cat, v)` · `report()`. **Client module** — playing a `Sound` on the server plays
it for nobody in particular.

> **It degrades quietly on purpose.** A missing NAME warns once and no-ops. An EMPTY `SoundId` is
> "not assigned yet" — the normal state of a fresh project — so it is reported once at boot by
> `report()` as a list, not warned about on every click. **All 13 slots are unassigned today**; that
> is work outstanding, not a fault. `StarterPlayerScripts.LobbyAudio` prints the list and starts the
> Lobby track; the Game needs its own equivalent for per-act music (PENDING).

## The confirmation dialog

`UIKit.Confirm.ask{ Title, Text, YesText?, NoText?, Delay? } -> boolean`. It **yields** and returns
a boolean, so a caller reads top-to-bottom instead of splitting across two callbacks; every screen
here already does its remote work inside `task.spawn`, so the yield costs nothing.

The DESIGN is the authored `StarterGui.ConfirmationPopupUI`
(`Background > ConfirmationFrame > Main > ConfirmationLabel / ConfirmationText / YesButton /
NoButton`); the module is only behaviour. Parts resolve **fresh on every ask**, because that
ScreenGui is `ResetOnSpawn`.

**The two-second gate is the point.** `YesButton` starts grey (`92,92,100`) and **not clickable**,
counts down in its own label (`SELL (2)` → `SELL (1)`), then turns green (`76,175,80`) and becomes
clickable. That is a deliberate speed bump on irreversible actions — B31's sell path destroys units
permanently and muscle memory must not carry a player through it. **`NoButton` is live immediately:**
backing out is never the dangerous direction. Verified live, sampled synchronously:

```
t=0.4s  Active=false  grey   'GO (2)'      t=2.0s  Active=true  (mid-tween) 'GO'
t=1.2s  Active=false  grey   'GO (1)'      t=2.4s  Active=true  green       'GO'
```

Re-entrancy is **refused, not queued** (two stacked prompts is how a player answers the wrong one),
and **every failure path returns `false`** — the safe answer to a question nobody could see is no.

B32 renamed the two authored buttons: they were **both** called `SellButton` (duplicate names make
dot access pick an arbitrary one) and were identified by their `ButtonText` to become
`YesButton` / `NoButton`. `DisplayOrder` was raised 10 → 100 so the dialog draws above `PartyScreen`.

## The trap that cost this session an hour

`UIKit.Button` and `UIKit.Confirm` require their siblings through **`optionalSibling`** — a 10-second
`WaitForChild` with a no-op stub — not a bare `WaitForChild`.

A bare `WaitForChild` on a sibling module **blocks forever**. `Button` is attached to every tagged
button at boot, so in a Place caught mid-deploy that does not lose the audio, it **freezes the entire
UI**. Found exactly that way: `Button` reached the Game place before `Sound` did and `require` never
returned. **Deploy order still matters, but it is no longer load-bearing.**
