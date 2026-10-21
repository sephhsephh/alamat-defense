# White-tint art — generate in WHITE, colour in Studio (user rule, B171 2026-10-21)
<!-- owner: user / AD-UI | scope: both Places | applies to every generated UI image -->

**Rule:** any UI art whose colour should be editable (gems, fills, glows, plates, badges, panel bodies) is made
**white / greyscale on transparent**. In Studio it gets a `UIGradient` child (name it `Tint`), which MULTIPLIES its
colour into every pixel: white → exactly the gradient colour, grey → a darker shade (shading survives), black stays
black. Recolour live in Studio or from a script by editing `Tint.Color` — never re-generate art to change a colour.

## How it works in Roblox
- `ImageLabel` (or `Frame`) + child `UIGradient`: final colour = pixel × `ImageColor3` (or `BackgroundColor3`) ×
  gradient colour at that point. Keep `ImageColor3` / `BackgroundColor3` = white so the gradient is the one control.
- A 2-key `ColorSequence` + `Rotation = 90` = a top→bottom gradient; one colour on both keys = a flat tint.
- The gradient tints the WHOLE element. So **split art into layers** wherever one part must keep its real colour:
  - `*_gold` — metal / real-colour layer, no gradient.
  - `*_gem` / `*_fill` — white layer, with the `Tint` UIGradient.
  - Stack the layers as siblings with identical Size / Position / `ScaleType` / `SliceCenter`, so they line up.
- A plain rectangle fill needs no image: a white `Frame` + `UICorner` + `Tint` UIGradient.

## When generating new art
1. Ask the image AI for the piece with the tintable parts in **pure white / light grey** ("white gemstone",
   "white glow", "white flat panel"), on plain black (keyed off later) or transparent.
2. Or generate in colour and split afterwards: `Claude outputs/play-ui-v3/split_tint_layers.py` pulls purple gems
   into a white `_gem` layer, cuts flat panels into a white `_fill` layer and leaves the gold in `_gold`.
3. Upload each layer; build the stack; add the `Tint` gradient to every white layer.

Related: `docs/systems/alamat-ui.md` (VFX art is already white-on-transparent + `Tint`), `icon-art-style.md`
(icons keep their full colour — this rule is for UI chrome, not item icons).
