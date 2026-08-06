# Proposal — A6's Game-place hotbar is blocked by A7's kit promotion, and the drift tooling cannot hash UI templates

<!-- author: AD-UI | target owner: AD-Integration (tools/) then AD-UI (kit) | place: both | raised: 2026-08-06 -->
<!-- status: DECIDED 2026-08-06 (user) — option B: fix the tooling FIRST. Awaiting AD-Integration. -->

## DECISION — 2026-08-06 (user)

**Option B: extend the drift tooling to cover instance trees BEFORE promoting the kit.**
Templates must be first-class, drift-checked manifest entries — the hand-mirrored shortcut
(option A) was explicitly rejected. Rationale accepted: `RewardPopup`, `CurrencyBar`,
`UnitHoverCard`, `ViewportPreview` and `NPCPrompt` are all still unbuilt and all carry the same
problem, so fixing the mechanism once is worth a session.

Sequencing now:
1. **AD-Integration** — extend `tools/hash_shared.luau` to hash GuiObject subtrees; decide and
   document the canonical serialisation format (an ADR is the right home for it).
2. **AD-UI** — promote the kit (controllers **and** templates) to `shared/src` + `manifest.json`,
   deploy to both Places, drift-check green.
3. **AD-UI** — then blueprint §9 A6's Game half: hotbar on the kit + `RewardPopup` + `CurrencyBar`.

A6's Game half stays BLOCKED until step 1 lands.

## The blocker

Blueprint §9 **A6 [AD-UI]** reads: *"Hotbar rebuild on kit in GAME place (+ lobby hotbar mirror)
+ RewardPopup + CurrencyBar."*

Verified in the Game place this session (drift GREEN 9/9, place-asserted):

- `ReplicatedStorage.UITemplates.Kit` — **ABSENT**
- `ReplicatedStorage.Shared.UIKit` — **ABSENT**
- `StarterPlayer.StarterPlayerScripts.UIKitBootstrap` — **ABSENT**

The kit exists only in the Lobby, where A4/A5 built it. The Game place's UI is entirely
Place-local and script-era, with its own unrelated templates (`Hotbar.SlotTemplate`,
`MatchEnd.RewardRowTemplate`, `Notifications.CardTemplate`, ...).

Blueprint §9 **A7 [AD-Integration]** is the step that *"promote[s] kit/config modules used by both
Places into `shared/src` + manifest"*. **So A6 depends on A7.** The session plan's ordering does
not work as written. This is not a judgement call about style — A6 literally cannot be executed
in the stated order.

## The deeper problem: half the kit is not hashable

`tools/hash_shared.luau` computes `fnv1a` over `inst.Source` and reports `MISSING` for anything
that is not a `LuaSourceContainer`. The whole drift system — `shared/manifest.json`, the bootstrap
drift check, the deploy checklist — is **source-text based**.

The kit is two different kinds of thing:

| Part | Examples | Hashable? |
|---|---|---|
| Controllers (ModuleScripts) | `UIKit.Button`, `UIKit.ItemIcon`, `UIKit.FilterPanel` | **Yes** — promote exactly like the 9 existing modules |
| Templates (GuiObjects) | `Kit.Button`, `Kit.ItemIcon`, `Kit.ItemHoverCard`, `Kit.FilterPanel`, `Kit.UnitPreviewTemplate` | **No** — they are Frames/ImageButtons, not scripts |

So "promote the kit to `shared/src`" cannot mean the same thing for both halves. If the templates
are simply copied into the Game place, the two copies are **invisible to the drift check** and will
silently diverge the first time either is edited in Studio — which is exactly the failure class this
repo was built to prevent, and exactly what already happened once at A5 (`ItemsGUI.HoverPreview`
kept a stale size after its template was resized; caught only by manual comparison).

The no-UI-in-scripts rule (2026-07-18) means this cannot be dodged by generating the templates from
code, either.

## Options

**A. Split A6: promote the CONTROLLERS now, rebuild the hotbar next session.**
Move `UIKit.{Button,ItemIcon,FilterPanel}` into `shared/src` + `manifest.json` (AD-UI owns the kit
per `docs/OWNERSHIP.md`), deploy to both Places, drift-check to 12/12. Templates get copied to the
Game place with an explicit, documented "mirrored by hand, NOT drift-checked" status and a
`docs/systems/` note listing every mirrored instance. Honest about the gap; unblocks A6 quickly.
Cost: a real untracked-drift surface exists until option B lands.

**B. Extend the drift tooling to cover instance trees first (AD-Integration, `tools/` canon).**
Serialise a GuiObject subtree to a canonical string (sorted children, sorted whitelisted properties)
and hash that, so templates become first-class manifest entries. Then promote the whole kit properly.
This is the durable fix and closes the failure class permanently. Cost: a tooling session before any
A6 UI work, and `tools/` is AD-Integration's canon, not AD-UI's.

**C. Keep the Game hotbar Place-local — do not use the shared kit there yet.**
Rebuild the Game hotbar on a Game-local controller written in the kit's style, and unify at A7.
Avoids the promotion question entirely today. Cost: A6 does not actually deliver "on kit", and two
hotbar implementations exist simultaneously — the divergence risk is in code instead of instances,
which is at least visible to `script_grep`.

**D. Reorder the blueprint: run A7's promotion step as its own session before A6.**
Cleanest sequencing and matches what the dependency graph actually is, but A7 is AD-Integration's
session and bundles Phase A acceptance + the `GetCollection` retirement (ADR-0004), so it is a
larger unit of work than just the promotion.

## Recommendation

**B then A** if there is appetite for a tooling session: fixing the hash mechanism first means the
kit is promoted once, correctly, with every part drift-checked — and it retires a whole class of
silent bug for every future shared UI component (RewardPopup, CurrencyBar, UnitHoverCard,
ViewportPreview and NPCPrompt are all still unbuilt and all have the same problem).

If speed matters more, **A** is acceptable *provided* the untracked template mirror is written down
loudly rather than assumed — an undocumented manual mirror is how this bites.

**Not recommended: C.** Two hotbar implementations is the thing A6 exists to remove.

## What was NOT done

No code was written in the Game place this session. Drift there is GREEN 9/9 and untouched.
