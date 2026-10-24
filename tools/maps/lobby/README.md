# Lobby "Holy Coast" kit -- Blender build (B172)

The new Lobby (user B172: "a holy version" of their coastline + island reference, built the way
`docs/design/stylized-environment.md` says) uses a MODULAR kit made here in Blender, imported once
with the Studio 3D Importer, then copied/scaled/rotated in Studio. Same pipeline as
`tools/maps/apolaki` (read `docs/systems/maps-apolaki.md` for importer gotchas).

## Rules every script follows
- **1 Blender unit = 1 stud.** Blender is Z-up; Roblox Y = Blender Z. Origin of every PIECE = its
  bottom-centre; its FRONT faces Blender -Y.
- **Split by material**: each piece is several objects named `<Piece>__<Mat>` (e.g. `AL_SunGate__Gold`),
  one material each, so each becomes one MeshPart. Mats: `Marble`, `MarbleBlock`, `Gold`, `TealTile`,
  `Pave`, `Crystal`, `Capiz`, `Cloth`, `Bronze`, `Mandala`. Object names must be globally unique.
- Chunky stylized shapes: bevels (2-3 segments) on every hard edge, slightly exaggerated proportions,
  no tiny detail below 0.3 studs. <= 20k tris per object (aim 1-6k).
- UVs: box-projected, world-scaled (1 texture tile = 8 studs for Marble/MarbleBlock/Pave, 6 for
  TealTile, 4 for Gold; Mandala is a single non-tiling disc 0..1).
- Holy palette: warm white marble 244,238,226; gold 232,186,72 (deep 168,112,32, hi 255,236,160);
  turquoise tile 40,150,160..110,215,210; crystal cyan-white 150,230,255; bronze 96,72,48.
- Pieces laid out in a row along +X in each kit file with 30-stud gaps; each kit writes
  `<root>/glb/AL_Kit<X>.json` = `{piece: {"origin":[x,y,z], "size":[w,d,h], "objects":[...]}}` and
  exports `<root>/glb/AL_Kit<X>.glb` with an `AL_Anchor<X>` 0.5-stud cube at (0,0,0).
- `<root>` = `C:\Users\Joseph Elton Estilo\Downloads\Alamat_Lobby` (tex, glb, renders, blend). Outside
  the repo; regenerable from these scripts.

## Files
| File | Writes |
|---|---|
| `common.py` | paths, noise/paint helpers (from apolaki), materials, bmesh helpers, export, preview render |
| `textures.py` | `tex/*.png`: marble, marble_block, gold, teal_tile, pave, crystal, capiz, cloth, bronze, mandala |
| `kit_arcade.py` (Kit A) | ArcBay, ArcBayTall, Pier, Column, Balustrade, BridgeSpan, WallSeg |
| `kit_sacred.py` (Kit B) | SunGate, DomePavilion, Temple, SpireTower, HaloRing, Finial, SunDisc, Crystal |
| `kit_ground.py` (Kit C) | Stairs, Dais, Mandala, LampPost, Parasol, Planter, Banner, MarketStall, Fountain |

## Piece specs (studs; W along X, D along Y, H along Z)
- **AL_ArcBay** 14W x 7D x 24H: two half-piers (3.5W) with plinth + capital, semicircular arch
  (opening 9W, springs at 15), spandrel to 22, projecting cornice 22-24; gold capital band + keystone +
  cornice line. Tiles side by side (straight) and around a polygon (15 deg steps at radius ~53).
- **AL_ArcBayTall** 14W x 7D x 40H: same, opening springs at 28 (rotunda lower tier standing in water).
- **AL_Pier** 5x5x30, base + capital gold. **AL_Column** d4 x 22, base, fluted shaft, gold capital.
- **AL_Balustrade** 12L x 1.6D x 4H: vase balusters every 1.5, top rail, end posts with gold caps.
- **AL_BridgeSpan** 24W(X) x 30L(Y) x 36H: deck top at Z=36, arch underneath (22 opening), half-piers
  at both ends (tiles along Y), parapets 3 high with gold coping.
- **AL_WallSeg** 14W x 3D x 12H retaining wall with cornice + gold line, tiles along X.
- **AL_SunGate** 56W x 12D x 72H: two pylons (8x8x56, gold spike finials), pointed arch between, a halo
  ring (torus R22, tube 1.6) with 16 radiating gold rays, gold sun disc d10 at centre, a hanging
  crystal (elongated octahedron 6x14) = `__Crystal`.
- **AL_DomePavilion** d22 x 30H: round stepped plinth (2.5), 6 columns (d2 x 14), entablature ring,
  ribbed dome (TealTile shell + Gold ribs) to 24, gold finial to 30.
- **AL_Temple** (Summon) 96W x 60D x 84H: base block 64x40x24, drum d36 x 20, big dome (TealTile +
  Gold ribs) to 70, lantern + finial to 84, front portico (4 columns, pediment with gold sun emblem),
  two flanking towers 12x12x50 + gold spires to 66, big arched doorway (dark inner plane `__Bronze`).
- **AL_SpireTower** 18x18 x 96H: stepped square tower, arched Capiz windows, gold conical spire,
  halo ring near the top.
- **AL_HaloRing** torus R10 + 12 spikes (Gold). **AL_Finial** 2x2x12 (Gold). **AL_SunDisc** d8 emblem
  with rays (Gold). **AL_Crystal** cluster of 5 elongated octahedra ~6x6x10 (Crystal).
- **AL_Stairs** 24W x 18D x 12H (8 steps of 1.5), side cheek walls 2W with gold caps.
- **AL_Dais** octagon d26 x 3H (2 steps), gold inlay ring, teal/gold rune ring on top.
- **AL_Mandala** disc d60 x 0.4 (Mandala texture: gold sun rays on cream, teal ring) -- plaza inlay.
- **AL_LampPost** 14H: marble base, bronze/gold post, capiz lantern head with gold roof.
- **AL_Parasol** d10 x 9H scalloped Cloth canopy + pole. **AL_Planter** marble urn d4 x 4.
  **AL_Banner** post + hanging cloth 3W x 10H (white, gold sun, blue trim).
- **AL_MarketStall** 14W x 10D x 12H: marble counter, 4 posts, striped Cloth canopy, 2 capiz lanterns.
- **AL_Fountain** d18 x 10H: basin, pedestal, upper bowl, gold sun finial (water added in Studio).

## Z-fighting rule (user, 2026-10-24)
Every kit script returns `C.zfight_report(col)` and must show **0 hits** before export (same-facing coplanar overlapping
faces within a piece; buried contacts and ground bottoms are skipped). Also render close-ups of new pieces: a lathe
profile that does not run bottom -> outside -> top comes out inside-out (Kit E pagoda roof, fixed).
Older kits were audited (B172 p3) and fixed IN STUDIO on the protos + every placed copy (attribute `ZFightFixed` /
`CapizRingFixed` guards re-runs): mandala discs +0.12, Temple capiz -0.1 back, Sun Gate marble +0.35 X, lantern-arch
gold +0.3 X, watchtower capiz ring x1.032. Sources patched for the mandalas + watchtower; Temple/SunGate/LanternArch
sources still have the flush faces -- fix them in Blender before any re-export of Kits A/B/D.
