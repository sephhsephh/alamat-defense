# Alamat Defense — Icon Art Style (image-generator prompts)
<!-- owner: user / AD-UI | scope: both | last-verified: 2026-10-10 (B137) -->

The ONE style every generated icon follows. Reuse this file for any future icon batch: paste **Block A** once to
start a chat with the image AI, then send one **Block C** line per icon. Only the item changes, never the style.
Tweaks for a new family (stats, currencies, materials...) go in a new **Block B** module, not in Block A.

---

## THE ONE-SHOT PROMPT (user's preferred, B137) — send it whole every time, edit only the top box

```
=== ICON TO MAKE (edit only this box) ===
ICON NAME: [e.g. Element_Fire]
ICON TYPE: [ITEM = a physical collectible object | SYMBOL = a tiny emblem badge shown at 24-32 px]
SUBJECT: [what to draw, e.g. "a stylized living flame shaped like a rising sun's tongue of fire"]
DOMINANT COLOURS: [e.g. "ember orange-red, golden-yellow core"]
EXTRA DETAILS: [optional tweaks, e.g. "slightly brighter glow", "three-quarter view", or "none"]
=========================================

Create ONE game icon for ALAMAT DEFENSE, a Filipino-mythology Roblox tower defense game, in the fixed
ALAMAT ICON STYLE below. This style is identical for every icon in the game — only the subject changes.
If I attach a previous Alamat icon, match its rendering, lighting, outline and colour treatment exactly.

ART STYLE (never change)
- Premium stylized fantasy game icon, mobile/Roblox UI quality: cartoon/anime-inspired, NOT photoreal,
  NOT realistic 3D, NOT manga, NOT pixel art, NOT flat vector clip-art, NOT childish.
- Chunky, slightly exaggerated shapes and one bold, instantly readable silhouette.
- Smooth painterly rendering: soft gradients, strong dimensional shading, bright specular highlights
  on the important surfaces.
- Clean outline in a dark warm colour (deep brown / deep indigo, never pure black), medium weight,
  slightly thicker on the outer silhouette than inside.
- Lighting: key light from the TOP-LEFT, soft warm rim light on the right edge, gentle ambient occlusion.
- Palette: rich but controlled saturation; warm GOLD trim (#FFCA5C to #BE782C) is the signature accent,
  deep violet (#965FFF) the secondary accent, used only where it fits the subject. The DOMINANT COLOURS
  above lead.
- Magic glow only where the subject is magical; the glow hugs the object, never fills the canvas.
- Filipino-myth identity comes from the overall feel (gold, sun motifs, carved wood, brass, shell) when it
  makes sense — never forced ornaments.

BY ICON TYPE
- ITEM: draw it as an official Alamat Defense inventory collectible; readable at 48 px; controlled detail.
- SYMBOL: an emblem, not a scene — one bold motif, thick silhouette, very little internal detail, maximum
  contrast, readable at 24-32 px; one dominant colour + gold accent + a soft inner glow of its own colour;
  same visual weight as every other Alamat symbol icon.

COMPOSITION
- ONE subject only, centred, front or three-quarter view (whichever reads best), slight tilt allowed.
- It fills about 80% of a square 1:1 1024 x 1024 canvas, with even padding on every side.
- No hands, characters, pedestal, ground plane, scene, or environment.

BACKGROUND — CRITICAL
- TRUE TRANSPARENT background with real alpha. Not white, not black, not a gradient, and not a
  checkerboard painted into the image. Only the subject (and glow hugging it) has pixels.
  (If true transparency is impossible, use a perfectly flat solid #FF00FF background with no shadow on it.)

NEVER INCLUDE
- No text, letters, numbers, logos, watermark, border, frame, card, badge, circular container, or UI.

Output: one high-resolution standalone icon, ready to import into Roblox UI.
```

The 12 element/placement subjects for the box are in the Block C table below (SUBJECT = the text after the key,
ICON TYPE = SYMBOL; for the three terrain ones add EXTRA DETAILS: "small floating terrain chunk, grass top, rocky
underside tapering to a point, high three-quarter angle, gold-capped placement pin").

---

## Block A — STYLE LOCK (paste once, at the start of the chat)

```
You are my icon artist for ALAMAT DEFENSE, a Filipino-mythology Roblox tower defense game.
For the rest of this chat, remember the style below as "THE ALAMAT ICON STYLE". I will send ONE icon per
message. Draw only that icon, in exactly this style, every time. Do not redesign the style between icons —
only the subject changes. If I say "match the approved icon", copy its rendering, lighting, outline and
colour treatment exactly.

THE ALAMAT ICON STYLE
- Premium stylized fantasy GAME ICON (mobile/Roblox UI quality): cartoon/anime-inspired, NOT photoreal,
  NOT realistic 3D, NOT manga, NOT pixel art, NOT flat vector clip-art, NOT childish.
- Chunky, slightly exaggerated shapes and one bold, instantly readable silhouette.
- Must still read clearly at 48 px: few large shapes, controlled detail, no tiny clutter.
- Smooth painterly rendering: soft gradients, strong dimensional shading, bright specular highlights
  on the important surfaces.
- Clean outline in a dark warm colour (deep brown / deep indigo, never pure black), medium weight,
  slightly thicker on the outer silhouette than inside.
- LIGHTING (fixed for every icon): key light from the TOP-LEFT, a soft warm rim light on the
  right edge, a gentle ambient occlusion in creases.
- PALETTE: rich but controlled saturation; warm GOLD trim (#FFCA5C -> #BE782C) is the signature accent
  and a deep violet (#965FFF) the secondary accent, used only where it fits the subject.
- Magic glow only where the subject is magical; the glow hugs the object, it never fills the canvas.
- Filipino-myth identity comes from the overall feel (gold, sun motifs, carved-wood / brass / shell
  materials when they make sense) — never forced ornaments.

COMPOSITION (every icon)
- ONE subject only, centred, front or three-quarter view (whichever reads best), a slight dynamic tilt
  allowed. It fills about 80% of the canvas, with even padding on all sides.
- Square 1:1 canvas, 1024 x 1024.
- No hands, characters, pedestal, ground plane, scene, or environment.

BACKGROUND — CRITICAL
- TRUE TRANSPARENT background (real alpha). Not white, not black, not a gradient, not a checkerboard
  pattern painted into the image. Only the subject (and glow hugging it) has pixels.

NEVER INCLUDE
- No text, letters, numbers, logos, watermark, border, frame, card, badge, circular container, or UI.

Reply "Style locked." and wait for the first icon.
```

---

## Block B — FAMILY MODULES (paste once per family, after Block A)

### B1 · ITEM icons (currencies, tokens, food, materials, chests)
```
FAMILY: ITEM ICONS. Each icon is a physical collectible object, drawn as an official Alamat Defense
inventory item. Follow THE ALAMAT ICON STYLE exactly.
```

### B2 · SYMBOL icons (elements, placement types, stats — tiny UI badges)
```
FAMILY: SYMBOL ICONS. These sit as tiny badges on unit cards (as small as 24-32 px), so they are
EMBLEMS, not scenes: one bold symbolic motif, thick silhouette, very little internal detail, maximum
contrast. Follow THE ALAMAT ICON STYLE exactly, plus:
- Every symbol in this family has the SAME visual weight, the SAME outline, the SAME top-left lighting
  and fills the SAME ~80% of the canvas, so a row of them looks like one set.
- Each symbol has ONE dominant colour (given per icon) + the gold accent + a soft inner glow of its own
  colour. No background shape behind it (no circle, shield or tile container).
```

### B2a · PLACEMENT sub-set (Ground / Hill / Hybrid / Max Placement)
```
SUB-SET: PLACEMENT. Build these three on the SAME base: a small stylized floating terrain chunk
(grass top, earthy rock underside tapering to a point, like a tiny floating island), seen from a
high three-quarter angle. Only the terrain shape and the marker change between them. The marker is a
small gold-capped tower-placement pin standing on the terrain.
```

---

## Block C — ONE LINE PER ICON (send one message each)

Send them one at a time. After the FIRST one you like, start every next message with
**"Match the approved icon's style exactly."**

### Elements (Block B2)
| Asset key | Message to send |
|---|---|
| `Element_Fire` | `Element_Fire: a stylized living flame shaped like a rising sun's tongue of fire. Dominant colour ember orange-red, golden-yellow core.` |
| `Element_Water` | `Element_Water: a single swirling sea droplet with a curling wave inside it (Magwayen's sea). Dominant colour deep ocean blue, aqua highlights.` |
| `Element_Nature` | `Element_Nature: a young sprout of two broad leaves curling from a seed, a tiny glowing bud between them. Dominant colour vivid leaf green.` |
| `Element_Light` | `Element_Light: a radiant eight-ray sun star (Philippine-sun inspired), bright white-gold centre. Dominant colour warm light yellow.` |
| `Element_Dark` | `Element_Dark: a crescent moon being swallowed by a serpent's shadow (the Bakunawa eclipse). Dominant colour deep purple-black, violet glow edge.` |
| `Element_Holy` | `Element_Holy: a glowing halo ring with two small feathered wings, soft divine light. Dominant colour ivory white and pale gold.` |
| `Element_Cosmic` | `Element_Cosmic: a small spiral galaxy with a ringed star at its heart, tiny twinkles. Dominant colour magenta-to-indigo, starlight white.` |
| `Element_Neutral` | `Element_Neutral: a balanced cut gemstone in a simple brass setting, calm and plain. Dominant colour cool silver-grey, subtle steel blue.` |

### Placement (Blocks B2 + B2a)
| Asset key | Message to send |
|---|---|
| `Placement_Ground` | `Placement_Ground: the floating terrain chunk with a FLAT grassy top; the placement pin stands on the flat ground. Dominant colour grass green and earth brown.` |
| `Placement_Hill` | `Placement_Hill: the same floating terrain chunk, but its top rises into a steep rocky hill/cliff peak; the placement pin stands on the summit. Dominant colour stone grey-brown with a green cap.` |
| `Placement_Hybrid` | `Placement_Hybrid: the same floating terrain chunk split in two halves — left half flat grass, right half a rocky hill — with one placement pin on each half. Dominant colours green and stone grey.` |
| `MaxPlacement` | `MaxPlacement: three identical gold-capped tower placement pins standing in a row, the third one topped by a small gold limit bar/crown above them, showing "maximum reached" without any numbers. Dominant colour gold and deep violet.` |

---

## Consistency workflow (any generator)

1. **One chat per family.** Paste Block A, then the family's Block B, then the first Block C line.
2. **Lock a reference.** Regenerate the first icon until it is right; that image is the "approved icon".
   If the tool takes image references, attach it to every later message.
3. **One icon per message**, each starting "Match the approved icon's style exactly." — never batch several
   icons in one image (styles drift and they come out as a sheet).
4. **Same settings every time**: 1:1, 1024 px, same model/quality, same seed if the tool exposes one.
5. **If transparency fails** (some tools paint a checkerboard or white): ask for "a perfectly flat, solid pure
   magenta #FF00FF background, no shadow on it" and key it out (use #00FF00 for purple/pink subjects).
6. **Check at game size** before importing: shrink to 48 px (32 px for symbol icons) — if it stops reading, ask
   for "bolder silhouette, less internal detail".
7. **Future icons**: reuse Block A untouched; add a new Block B module for a new family; write new Block C lines.
   Small tweaks ("a bit brighter", "thicker outline") go in the Block C line, never in Block A.

## Where icons are used in-game
Elements / placement ids live in the unit-card icon map (`Element_*`, `Placement_*`, `MaxPlacement` asset ids);
item icons in `ItemCatalog` (`Icon.Image`). Upload the PNG to Roblox, then paste the new `rbxassetid://` into the
same key.
