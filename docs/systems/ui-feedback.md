# SYSTEM — UI feedback: button motion, audio, and the confirmation dialog

<!-- owner: AD-UI | home Place: BOTH | scope: shared -->
<!-- last-verified: 2026-08-20 (B34: UIKit.Notify + UIKit.UnitCard promoted, watchdog proven live) -->
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

## Toasts (B33, Lobby) — and the rule for when NOT to use one

The user copied the Game's toast system into the Lobby — `StarterGui.Notifications` (the authored
`Container` + `CardTemplate`) and `StarterPlayerScripts.NotificationController` — and asked for it
across the whole Lobby. **It is NOT shared canon and NOT in the manifest**, so the Lobby and Game
copies are free to diverge; unifying them is a PENDING, not a fact.

API: `Notify.Error / Success / Warning / Info(msg)`, or `Notify.Notify(msg, kind)`. Cards pop in,
stack in a `UIListLayout` so they never overlap, cap at 5, and **auto-dismiss after 3.5 s**.
Colour is the kind: Error `255,90,90` · Success `110,225,140` · Warning `255,190,70` · Info
`110,190,255`. Require it from `Players.LocalPlayer.PlayerScripts`.

**THE RULE: TOAST EVENTS, LABEL STATE.** A toast erases itself after 3.5 s. That makes it right for
something that **happened** — refused, failed, sold, ascended — and actively wrong for something that
**is true**: "this banner is blocked", "this unit cannot ascend", "this DESTROYS a duplicate". Wiping
a still-current condition off the screen after 3.5 s is worse than never having shown it.

So each adopting screen keeps ONE funnel and the CALL SITE decides:

| screen | funnel | behaviour |
|---|---|---|
| `UnitsGUI` | `setSellStatus(txt, kind?)` | toasts by default — `SellStatus` was a pure transient hint label, which is the one the user pointed at |
| `SummonScreen` | `setSummonStatus(txt, kind?)` | label always; toast **only** when a `kind` is named |
| `AscensionController` | `setAscStatus(txt, kind?)` | same — `AscStatus` carries persistent per-unit state |

Every funnel still writes its label, so a Place with the toast GUI deleted degrades to exactly the
old behaviour. **`SummonController` already had an unrelated local `setStatus`** inside the B30
Selection-choice closure, writing a different label — hence `setSummonStatus`, not a second
`setStatus` shadowing it.

## The bare `WaitForChild` hazard, second occurrence — now a rule

B32 lost an hour to a shared module waiting forever on an undeployed sibling. **B33 lost the entire
Units screen to the same pattern**, and the sequence is worth keeping because nothing looked wrong:

1. B32 retired `SellConfirm` and reported it to the user as "unused and deletable".
2. The user deleted it — correctly.
3. Six bare `WaitForChild("SellConfirm")` calls in `UnitsController` were still there.
4. A bare `WaitForChild` **never times out**. The controller stopped at its first declaration.
5. No error. No stack. The Units screen simply never finished booting — no grid, no equip, no sell.

**The rule.** A bare `WaitForChild` is acceptable ONLY on instances whose absence makes the screen
meaningless anyway (`Main`, `Bottom`, `UnitsContainer`, the remotes folder). For anything a
**designer is actively editing**, use a bounded lookup that warns with the full path:

```lua
local function need(parent, name, className)   -- UnitsController's form
    local inst = parent:FindFirstChild(name)
    if inst == nil and parent:IsDescendantOf(game) then inst = parent:WaitForChild(name, 5) end
    if inst == nil then
        table.insert(sellMissing, parent:GetFullName() .. "." .. name)
        local stub = Instance.new(className); stub.Name = name; return stub   -- DETACHED
    end
    return inst
end
```

Two details that matter. The **detached stand-in** means `.Visible = false` on a missing frame is a
harmless no-op instead of a crash, so one deleted instance costs one feature rather than the screen.
The **`IsDescendantOf(game)` guard** stops a stand-in's children from each burning the full timeout —
without it, one missing frame costs 5 s per child it was supposed to contain.

The feature then **refuses to arm** (`sellEnabled`) and names every missing instance in one warn
line, so "why is Quick Sell dead?" is answered by the console instead of by diffing the Explorer
against the script. `NotificationController`'s own three lookups were hardened the same way when the
Lobby started depending on it: **a missing toast system must cost toasts, never a screen.**

**Still outstanding:** a scan at B33 found **334 bare `WaitForChild` calls against 23 timed** across
Lobby scripts. Most are on infrastructure and are fine. They were NOT swept — a 334-site mechanical
rewrite risks more than it fixes — so this is a PENDING, and the rule above applies to anything
touched from here.

## B34 — the toasts became canon, and the fork closed

`UIKit.Notify` is shared canon (`5e2b09d4`, both Places, manifest entry 30). B33 left the toast
system **forked**: the Game's original at `Client.UI.NotificationController`, the Lobby's copy at
`StarterPlayerScripts.NotificationController`, in *different paths*, in *neither manifest*, with only
the Lobby's hardened. That is the exact failure the shared-canon system exists to prevent, so it did
not get to survive a session.

Both copies are retired by **rename** (`*_RETIRED_2026-08-20`, the `Hotbar_RETIRED_2026-08-06`
convention — deleting a file is the user's call, and a renamed module stays visible in the Explorer).
All five consumers were repointed: Lobby `UnitsController` / `SummonController` /
`AscensionController`, Game `PlacementController` / `TowerSelectionUI`. **The API did not change**, so
repointing was ONE line per consumer and the ~20 call sites were untouched.

Same split as `UIKit.Confirm`: the **module** is canon, the **GUI** (`StarterGui.Notifications` —
`Container` + `CardTemplate`) stays per-Place authored art. It is a CLIENT module; a server require
warns and degrades to print-only rather than erroring.

`UIKit.UnitCard` (`bd2421c5`, entry 31) landed the same way, for the four screens that each carried
their own `setViewportModel` and `paintTier`. The duplication was **measured, not assumed**: three of
each were byte-identical, and Units differed only in where the model came from (`viewport()` takes the
model) and in two behaviours (`paintTier(root, tier, {Idle, StrokeOff})`). Four copies of a camera
formula is four places for it to drift, and that drift is silent — a card framed differently on one
screen just reads as an art bug.

## The watchdog: why 334 bare `WaitForChild` were NOT swept

The obvious response to B33 was to give all 334 a timeout. That was costed at B34 and **rejected**:
it means rewriting ~100 authored-instance lookups across 14 working files, and then making every
downstream use nil-tolerant. Bigger diff, bigger risk, than the bug it prevents.

**The real defect at B33 was never the missing timeout — it was that the failure was SILENT.** A
screen died and the only evidence was one `Infinite yield possible` line in a wall of healthy boot
output. So instead of changing 100 lookups:

- every boot script ends with `script:SetAttribute("BootComplete", true)` (18 of them, one line each);
- **`StarterPlayerScripts.ScreenBootWatchdog`** waits 15s, then NAMES every script that carries the
  marker but never reached it — one `warn` each, because a single combined line is what gets scrolled
  past;
- scripts that *should* be instrumented but aren't (`*Controller` with no marker) are reported too,
  since an uninstrumented script is invisible to the check;
- Roblox's own injected `LocalScript`s (`FreecamScript`, `PlayerScriptsLoader`, `RbxCharacterSounds`)
  are filtered by name — **a watchdog that cries wolf every boot is one everybody learns to ignore.**

Verified live: clean baseline (19/19, zero false positives), and clearing one script's marker to
simulate a hang produced exactly one named STUCK report.

**This is diagnosability chosen over prevention, deliberately.** A screen can still hang. It can no
longer hang *quietly*, and it catches hangs from causes a timeout sweep never would — a remote that
never returns, a yield in a future script nobody has written yet. The `need()` rule still applies to
anything touched from here; see the section above.
