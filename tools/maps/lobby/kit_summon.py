# Alamat Defense Lobby "Holy Coast" -- Kit E: the Summon Sanctum + new building types (B172 phase 3). Same rules as
# README.md (split by material, origin bottom-centre, front -Y, row along +X).
# Summon Sanctum = SIX separate pieces so each can be animated on its own in Studio (ambient spin/float now, the user's
# summon animation later): AL_SummonDais (static, walkable), AL_SummonRingOuter (horizontal, spins Y),
# AL_SummonRingInner (vertical, spins Look), AL_SummonHeart (floating crystal), AL_SummonCrown (spike ring, spins Y),
# AL_SummonHalo (giant sun halo behind, spins Look).
# Buildings: AL_Pagoda, AL_BahayNaBato, AL_Observatory, AL_Aqueduct, AL_Lighthouse, AL_Stupa.
# Run: blender.exe -b <root>/blend/AL_kitE_summon.blend --python-expr "exec(open(r'<this>').read()); print('RESULT', result)"
import importlib.util
import math
import os
import sys

import bpy
from mathutils import Matrix

LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
_s = importlib.util.spec_from_file_location("al_common", os.path.join(LOBBY, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["al_common"] = C
_s.loader.exec_module(C)
PI = math.pi
S2 = math.sqrt(2.0)


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def Rz(a):
    return Matrix.Rotation(a, 4, "Z")


def slab(bm, cx, cy, hx, hy, z0, z1, bevel=0.3, M=None):
    return C.box(bm, cx - hx, cy - hy, z0, cx + hx, cy + hy, z1, bevel=min(bevel, 0.4 * (z1 - z0)), M=M)


def pyramid(bm, cx, cy, hw, z0, z1):
    return C.lathe(bm, [(0.0, z0), (hw * S2, z0), (0.0, z1)], 4, center=(cx, cy, 0.0), phase=PI / 4)


def finial(bm, cx, cy, z0, h, r):
    prof = C.round_profile([(0.0, z0), (r, z0), (r * 0.6, z0 + h * 0.25), (r * 1.1, z0 + h * 0.45),
                            (r * 0.35, z0 + h * 0.75), (0.0, z0 + h)], 0.1)
    return C.lathe(bm, prof, 16, center=(cx, cy, 0.0))


def flared_roof(bm, cx, cy, hw, z0, rise):
    """4-sided pagoda roof over a square of half-width hw: upturned eaves, closed underside. The profile MUST run
    bottom -> outside -> top (C.lathe's winding); the reverse renders inside-out."""
    p = [(0.0, z0 - 0.6), (hw, z0 - 0.6), (hw + 5.8, z0 - 0.3), (hw + 6.2, z0 + 1.3), (hw + 5.0, z0 + 0.25),
         (hw + 1.0, z0 + 0.7), (0.0, z0 + rise)]
    return C.lathe(bm, [(r * S2, z) for r, z in p], 4, center=(cx, cy, 0.0), phase=PI / 4)


# ================================================================ Summon Sanctum
def summon_dais(col, man, origin):
    """AL_SummonDais d~132 x 62H: three round tiers with gold trims, a 3-step stair on each cardinal side, a sun mandala
    on the top floor, a central altar drum, and 8 crystal-tipped pylons on the middle tier (between the stairs)."""
    P = C.Piece("AL_SummonDais", origin)
    Mb, MB, G, CR, MD = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("Crystal"), P.bm("Mandala")
    tiers = [(0.0, 60.0, Mb), (3.0, 50.0, MB), (6.0, 40.0, Mb)]
    for z0, R, bm in tiers:
        C.drum(bm, (0, 0), z0, 3.0, R, sides=64, bevel=0.35)
        C.torus(G, (0, 0, z0 + 2.9), R + 0.05, 0.35, seg=96, sides=6, uv=4.0)
        for a in (0.0, PI / 2, PI, 3 * PI / 2):  # 2 steps (1 stud each), then the tier top (a 3rd step would be flush = z-fight)
            for j in (1, 2):
                ro = R + (3 - j) * 2.0
                C.box(Mb, -9.0, -ro, z0 + j - 1.0, 9.0, -(R - 1.0), z0 + j, bevel=0.12, M=Rz(a))
            for sx in (-1, 1):  # gold stair cheeks
                C.box(G, sx * 9.0 - 0.5, -(R + 4.2), z0, sx * 9.0 + 0.5, -(R - 1.0), z0 + 3.4, bevel=0.15, M=Rz(a))
    faces = C.lathe(MD, [(32.0, 9.12), (0.0, 9.12)], 64, cap=False)  # 0.12 above the floor: no z-fight at range
    C.disc_uv(MD, faces, (0, 0), 32.0)
    C.drum(MB, (0, 0), 9.0, 3.0, 8.0, sides=32, bevel=0.3)
    C.torus(G, (0, 0, 12.0), 8.0, 0.5, seg=64, sides=8, uv=4.0)
    C.drum(G, (0, 0), 12.0, 0.6, 6.5, sides=32, bevel=0.2)
    for k in range(8):
        a = PI / 8 + k * PI / 4
        x, y = math.sin(a) * 45.0, -math.cos(a) * 45.0
        slab(Mb, x, y, 4.0, 4.0, 6.0, 8.0, bevel=0.4)
        C.lathe(MB, [(0.0, 8.0), (3.2 * S2, 8.0), (2.2 * S2, 46.0), (0.0, 46.0)], 4, center=(x, y, 0.0), phase=PI / 4)
        for z in (18.0, 30.0, 42.0):
            w = 3.2 - (z - 8.0) / 38.0 * 1.0 + 0.25
            slab(G, x, y, w, w, z, z + 0.9, bevel=0.2)
        slab(Mb, x, y, 3.0, 3.0, 46.0, 48.0, bevel=0.3)
        for b in range(4):  # gold claw holding the crystal
            ba = b * PI / 2 + PI / 4
            C.spike(G, (x + math.cos(ba) * 2.2, y + math.sin(ba) * 2.2, 48.0),
                    (x + math.cos(ba) * 1.2, y + math.sin(ba) * 1.2, 53.0), 0.5, sides=6)
        C.crystal(CR, (x, y, 48.5), 3.4, 12.0, sides=6, waist=0.5)
    return P.done(col, man)


def summon_ring_outer(col, man, origin):
    """AL_SummonRingOuter R36 horizontal gyroscope ring: double gold torus, 16 teal rune blocks, 8 outward gold spikes.
    Geometry centred 2 studs above its origin; floats over the dais and spins about Y."""
    P = C.Piece("AL_SummonRingOuter", origin)
    G, TT = P.bm("Gold"), P.bm("TealTile")
    c = (0.0, 0.0, 2.6)
    C.torus(G, c, 36.0, 1.6, seg=128, sides=12, uv=4.0)
    C.torus(G, c, 32.5, 0.6, seg=128, sides=8, uv=4.0)
    for k in range(16):
        a = 2 * PI * k / 16
        C.block(TT, (math.cos(a) * 34.2, math.sin(a) * 34.2, c[2]), (3.0, 2.2, 2.6), bevel=0.3, rot=(0, 0, a))
    for k in range(8):
        a = 2 * PI * k / 8 + PI / 8
        C.spike(G, (math.cos(a) * 37.0, math.sin(a) * 37.0, c[2]), (math.cos(a) * 43.0, math.sin(a) * 43.0, c[2]),
                1.0, sides=6)
    return P.done(col, man)


def summon_ring_inner(col, man, origin):
    """AL_SummonRingInner R24 vertical ring (faces -Y): gold torus + inner band, 4 crystal studs, 12 rune ticks.
    Centre 25 above its origin; spins on its Look axis inside the outer ring."""
    P = C.Piece("AL_SummonRingInner", origin)
    G, CR, TT = P.bm("Gold"), P.bm("Crystal"), P.bm("TealTile")
    c = (0.0, 0.0, 25.0)
    C.torus(G, c, 24.0, 1.3, seg=112, sides=12, axis="Y", uv=4.0)
    C.torus(G, c, 21.0, 0.45, seg=112, sides=8, axis="Y", uv=4.0)
    for k in range(12):
        a = 2 * PI * k / 12
        C.block(TT, (math.cos(a) * 22.5, 0, c[2] + math.sin(a) * 22.5), (1.6, 1.8, 1.6), bevel=0.2, rot=(0, -a, 0))
    for k in range(4):
        a = k * PI / 2
        x, z = math.cos(a) * 26.5, c[2] + math.sin(a) * 26.5
        C.crystal(CR, (x, 0, z - 2.5), 2.2, 5.0, sides=4, rot=(0, -a + PI / 2, 0))
    return P.done(col, man)


def summon_heart(col, man, origin):
    """AL_SummonHeart: the floating summon crystal -- a 24-tall crystal in a gold cradle ring with 6 satellite shards."""
    P = C.Piece("AL_SummonHeart", origin)
    CR, G = P.bm("Crystal"), P.bm("Gold")
    C.crystal(CR, (0, 0, 0.0), 7.0, 24.0, sides=6, waist=0.5)
    C.torus(G, (0, 0, 9.0), 5.2, 0.5, seg=48, sides=8, uv=4.0)
    C.torus(G, (0, 0, 9.0), 6.2, 0.25, seg=48, sides=6, uv=4.0)
    for k in range(6):
        a = 2 * PI * k / 6
        x, y = math.cos(a) * 9.0, math.sin(a) * 9.0
        C.crystal(CR, (x, y, 6.0 + (k % 2) * 4.0), 1.8, 6.0, sides=4, waist=0.45, rot=(0.25 * math.cos(a), 0.25 * math.sin(a), a))
    return P.done(col, man)


def summon_crown(col, man, origin):
    """AL_SummonCrown R28: a floating ring with 12 gold spikes pointing in and down at the heart (spins Y)."""
    P = C.Piece("AL_SummonCrown", origin)
    G, TT = P.bm("Gold"), P.bm("TealTile")
    c = 6.0
    C.torus(G, (0, 0, c), 28.0, 1.0, seg=112, sides=10, uv=4.0)
    for k in range(12):
        a = 2 * PI * k / 12
        x, y = math.cos(a) * 28.0, math.sin(a) * 28.0
        C.spike(G, (x, y, c), (x * 0.72, y * 0.72, c - 6.0), 1.3, sides=6)
        C.spike(G, (x, y, c), (x * 1.04, y * 1.04, c + 5.5), 0.8, sides=6)
        C.block(TT, (x, y, c), (2.2, 2.2, 2.2), bevel=0.25, rot=(0, 0, a))
    return P.done(col, man)


def summon_halo(col, man, origin):
    """AL_SummonHalo R44 vertical sun halo (faces -Y) with 24 alternating rays to R60; floats behind the sanctum."""
    P = C.Piece("AL_SummonHalo", origin)
    G, TT, CR = P.bm("Gold"), P.bm("TealTile"), P.bm("Crystal")
    c = (0.0, 0.0, 61.0)
    C.torus(G, c, 44.0, 2.0, seg=128, sides=12, axis="Y", uv=4.0)
    C.torus(G, c, 39.0, 0.7, seg=128, sides=8, axis="Y", uv=4.0)
    for k in range(24):
        a = 2 * PI * k / 24
        r1 = 60.0 if k % 2 == 0 else 53.0
        C.spike(G, (math.cos(a) * 45.5, 0, c[2] + math.sin(a) * 45.5), (math.cos(a) * r1, 0, c[2] + math.sin(a) * r1),
                1.6 if k % 2 == 0 else 1.0, sides=4)
        if k % 2 == 0:
            C.block(TT, (math.cos(a) * 41.5, 0, c[2] + math.sin(a) * 41.5), (2.4, 2.0, 2.4), bevel=0.25, rot=(0, -a, 0))
    for k in range(4):
        a = PI / 4 + k * PI / 2
        C.crystal(CR, (math.cos(a) * 44.0, 0, c[2] + math.sin(a) * 44.0 - 3.5), 3.0, 7.0, sides=4, rot=(0, -a + PI / 2, 0))
    return P.done(col, man)


# ================================================================ buildings
def pagoda(col, man, origin):
    """AL_Pagoda 34x34x84: stepped plinth + 5 shrinking storeys, each with a capiz window band and an upturned teal roof,
    gold spire with rings."""
    P = C.Piece("AL_Pagoda", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    slab(Mb, 0, 0, 13.0, 13.0, 0.0, 1.5, bevel=0.4)
    slab(Mb, 0, 0, 11.5, 11.5, 1.5, 3.0, bevel=0.4)
    z = 3.0
    for i in range(5):
        hw = 9.0 - i * 1.3
        h = 10.0 - i * 0.8
        slab(MB, 0, 0, hw, hw, z, z + h, bevel=0.4)
        slab(CZ, 0, 0, hw + 0.15, hw + 0.15, z + h * 0.45, z + h * 0.75, bevel=0.1)
        for sx in (-1, 1):  # corner posts in front of the window band
            for sy in (-1, 1):
                slab(G, sx * hw, sy * hw, 0.5, 0.5, z + h * 0.4, z + h * 0.8, bevel=0.1)
        flared_roof(TT, 0, 0, hw, z + h + 0.9, 4.0 - i * 0.3)  # underside 0.3 into the gold band (no flush faces)
        slab(G, 0, 0, hw + 0.3, hw + 0.3, z + h, z + h + 0.4, bevel=0.1)
        z += h + 3.6
    for k in range(5):
        C.drum(G, (0, 0), z + k * 2.2, 1.2, 1.6 - k * 0.22, sides=16, bevel=0.2)
    C.drum(G, (0, 0), z - 0.2, 11.6, 0.45, sides=12, bevel=0.05)  # spire pole: the rings sit on it, never float
    finial(G, 0, 0, z + 11.0, 7.0, 1.0)
    return P.done(col, man)


def bahay_na_bato(col, man, origin):
    """AL_BahayNaBato 28x20x28: Filipino stone house -- arched marble ground floor, overhanging upper floor with capiz
    window panels and gold sills, teal gable roof with gold ridge."""
    P = C.Piece("AL_BahayNaBato", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    slab(Mb, 0, 0, 13.5, 9.5, 0.0, 1.0, bevel=0.3)
    for sy in (-1, 1):  # front + back: 3 arches each
        for k in (-1, 0, 1):
            C.arch_wall(MB, 8.66, 10.0, 1.6, 5.0, 5.0, kind="round", bevel=0.25, n=12,
                        M=T(k * 8.66, sy * 8.2, 1.0))
    for sx in (-1, 1):
        C.box(MB, sx * 13.0 - 0.8, -8.2, 1.0, sx * 13.0 + 0.8, 8.2, 11.0, bevel=0.25)
    C.box(Mb, -13.4, -8.6, 4.0, 13.4, 8.6, 5.0, bevel=0.2)  # mezzanine floor, edges buried in the walls (no flush faces)
    slab(G, 0, 0, 14.6, 10.6, 11.0, 11.6, bevel=0.15)
    C.box(Mb, -14.5, -10.5, 11.6, 14.5, 10.5, 12.6, bevel=0.3)
    for sy in (-1, 1):  # upper floor walls: marble frame + capiz panels
        y = sy * 10.0
        C.box(Mb, -14.5, y - 0.6, 12.6, 14.5, y + 0.6, 13.6, bevel=0.15)
        C.box(Mb, -14.5, y - 0.6, 19.6, 14.5, y + 0.6, 20.6, bevel=0.15)
        for k in range(6):
            x0 = -13.5 + k * 4.6
            C.box(CZ, x0, y - 0.35, 13.6, x0 + 3.8, y + 0.35, 19.6, bevel=0.05)
            C.box(Mb, x0 + 3.8, y - 0.55, 13.6, x0 + 4.6, y + 0.55, 19.6, bevel=0.1)
        C.box(G, -14.8, y - 0.9 * sy - 0.4, 13.2, 14.8, y - 0.9 * sy + 0.4, 13.6, bevel=0.1)  # past the side walls (14.6): no flush ends
    for sx in (-1, 1):
        C.box(Mb, sx * 14.0 - 0.6, -10.0, 12.6, sx * 14.0 + 0.6, 10.0, 20.6, bevel=0.15)
    C.prism(TT, [(-16.5, 20.2), (16.5, 20.2), (0.0, 28.0)], -12.0, 12.0, bevel=0.2)
    C.box(G, -0.5, -12.3, 27.4, 0.5, 12.3, 28.6, bevel=0.15)
    for sy in (-1, 1):
        finial(G, 0, sy * 12.0, 28.2, 3.0, 0.6)
    return P.done(col, man)


def observatory(col, man, origin):
    """AL_Observatory d34 x 44H: round marble hall with a column ring, gold dome with a teal slit, bronze telescope
    and a tilted gold armillary ring."""
    P = C.Piece("AL_Observatory", origin)
    Mb, MB, G, TT, BZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Bronze")
    C.drum(Mb, (0, 0), 0.0, 2.0, 17.0, sides=48, bevel=0.4)
    C.drum(MB, (0, 0), 2.0, 18.0, 12.0, sides=48, bevel=0.3)
    for x, y, a in C.polar(12, 14.8, phase=PI / 12):
        C.drum(Mb, (x, y), 2.0, 0.8, 1.3, sides=12, bevel=0.15)
        C.drum(Mb, (x, y), 2.8, 15.4, 0.8, sides=12, bevel=0.1)
        C.drum(G, (x, y), 18.2, 0.6, 1.1, sides=12, bevel=0.1)
    C.drum(Mb, (0, 0), 18.8, 1.8, 16.0, sides=48, bevel=0.35)
    C.torus(G, (0, 0, 20.6), 12.4, 0.5, seg=64, sides=8, uv=4.0)
    C.lathe(G, C.ellipse_profile(12.2, 13.0, z0=20.6, n=12), 48, uv=4.0)
    C.box(TT, -1.6, -12.6, 20.8, 1.6, 0.0, 33.8, bevel=0.2, M=T(0, 0, 0) @ Matrix.Rotation(-0.35, 4, "X"))
    C.drum(BZ, (0, 0), 0.0, 16.0, 1.4, r_top=1.0, sides=16, bevel=0.15,
           M=T(0, -6.0, 26.0) @ Matrix.Rotation(-0.9, 4, "X"))
    C.torus(G, (0, 0, 0), 15.5, 0.45, seg=96, sides=8, uv=4.0, M=T(0, 0, 27.0) @ Matrix.Rotation(0.5, 4, "X"))
    finial(G, 0, 0, 33.2, 6.0, 1.0)
    return P.done(col, man)


def aqueduct(col, man, origin):
    """AL_Aqueduct 64W x 8D x 42H: two-tier Roman-style arcade (4 big arches, 8 small), gold band, channel on top."""
    P = C.Piece("AL_Aqueduct", origin)
    Mb, MB, G, PV = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("Pave")
    for k in range(4):
        C.arch_wall(MB, 16.0, 26.0, 8.0, 11.0, 15.0, kind="round", bevel=0.35, n=14, M=T(-24.0 + k * 16.0, 0, 0))
    C.box(G, -32.2, -4.3, 26.0, 32.2, 4.3, 26.8, bevel=0.15)
    for k in range(8):
        C.arch_wall(Mb, 8.0, 12.0, 6.0, 5.4, 7.0, kind="round", bevel=0.25, n=12, M=T(-28.0 + k * 8.0, 0, 26.8))
    C.box(Mb, -32.5, -3.6, 38.8, 32.5, 3.6, 40.4, bevel=0.3)
    C.box(PV, -32.5, -2.2, 40.4, 32.5, 2.2, 40.6, bevel=0.0)
    for sy in (-1, 1):
        C.box(Mb, -32.5, sy * 3.0 - 0.6, 40.4, 32.5, sy * 3.0 + 0.6, 42.0, bevel=0.2)
    return P.done(col, man)


def lighthouse(col, man, origin):
    """AL_Lighthouse d22 x 98H: stepped base, tapered block tower with gold bands, gallery with gold rail posts, glowing
    capiz lamp room, gold dome + finial."""
    P = C.Piece("AL_Lighthouse", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    C.drum(Mb, (0, 0), 0.0, 2.0, 11.0, sides=40, bevel=0.4)
    C.drum(Mb, (0, 0), 2.0, 2.0, 9.6, sides=40, bevel=0.4)
    C.drum(MB, (0, 0), 4.0, 66.0, 8.0, r_top=5.6, sides=40, bevel=0.3)
    for z, r in ((20.0, 7.5), (38.0, 6.9), (56.0, 6.3)):
        C.torus(G, (0, 0, z), r, 0.45, seg=64, sides=8, uv=4.0)
    for k in range(3):  # small capiz windows up the shaft
        a = k * 2.1
        z = 26.0 + k * 16.0
        r = 8.0 - (z - 4.0) / 66.0 * 2.4
        C.block(CZ, (math.cos(a) * r, math.sin(a) * r, z), (1.8, 0.8, 3.2), bevel=0.1, rot=(0, 0, a + PI / 2))
    C.drum(Mb, (0, 0), 70.0, 2.0, 8.5, sides=40, bevel=0.35)
    for x, y, a in C.polar(16, 8.0):
        C.drum(G, (x, y), 72.0, 2.4, 0.22, sides=6, bevel=0.0)
    C.torus(G, (0, 0, 74.4), 8.0, 0.22, seg=64, sides=6, uv=4.0)
    C.drum(CZ, (0, 0), 72.0, 8.0, 5.0, sides=24, bevel=0.1)
    for x, y, a in C.polar(6, 5.1):
        C.drum(G, (x, y), 72.0, 8.0, 0.35, sides=6, bevel=0.0)
    C.drum(Mb, (0, 0), 80.0, 1.2, 6.2, sides=32, bevel=0.3)
    C.lathe(G, C.ellipse_profile(5.6, 7.0, z0=81.2, n=10), 32, uv=4.0)
    finial(G, 0, 0, 87.8, 9.0, 1.1)
    return P.done(col, man)


def stupa(col, man, origin):
    """AL_Stupa 34x34x48: three square terraces with stairs, a white bell dome with a gold band, gold harmika and a ringed
    spire, four corner mini-stupas."""
    P = C.Piece("AL_Stupa", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    for i, (hw, z0) in enumerate(((17.0, 0.0), (14.0, 2.5), (11.5, 5.0))):
        slab(MB if i == 1 else Mb, 0, 0, hw, hw, z0, z0 + 2.5, bevel=0.35)
        slab(G, 0, 0, hw + 0.1, hw + 0.1, z0 + 1.9, z0 + 2.25, bevel=0.05)  # below the top: never flush (z-fight)
    for j in range(5):  # front stair
        C.box(Mb, -4.0, -17.0 - (4 - j) * 1.5, j * 1.5, 4.0, -11.5, (j + 1) * 1.5, bevel=0.1)  # ends AT the top terrace face
    C.lathe(Mb, C.round_profile([(0.0, 7.5), (10.0, 7.5), (10.6, 10.0), (10.0, 15.0), (8.2, 19.0), (5.0, 21.8),
                                 (0.0, 22.6)], 0.4), 40)
    C.torus(G, (0, 0, 10.2), 10.6, 0.4, seg=64, sides=8, uv=4.0)
    slab(G, 0, 0, 3.2, 3.2, 22.0, 25.0, bevel=0.3)
    slab(TT, 0, 0, 3.8, 3.8, 25.0, 26.0, bevel=0.3)
    for k in range(9):
        C.drum(G, (0, 0), 26.0 + k * 1.9, 1.0, 2.8 - k * 0.26, sides=20, bevel=0.2)
    C.drum(G, (0, 0), 25.8, 17.6, 0.55, sides=12, bevel=0.05)  # spire pole
    finial(G, 0, 0, 43.0, 5.0, 0.8)
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * 13.5, sy * 13.5
            C.lathe(Mb, C.round_profile([(0.0, 5.0), (1.8, 5.0), (1.9, 6.5), (1.2, 8.2), (0.0, 8.6)], 0.15), 16,
                    center=(x, y, 0.0))
            finial(G, x, y, 8.4, 2.6, 0.4)
    return P.done(col, man)


PIECES = [(summon_dais, 132.0), (summon_ring_outer, 86.0), (summon_ring_inner, 56.0), (summon_heart, 20.0),
          (summon_crown, 60.0), (summon_halo, 122.0), (pagoda, 34.0), (bahay_na_bato, 34.0), (observatory, 34.0),
          (aqueduct, 65.0), (lighthouse, 22.0), (stupa, 34.0)]

col = C.clear_collection("AL_KitE")
row = C.Row(gap=30.0)
manifest = {}
for build, width in PIECES:
    build(col, manifest, row.next(width))
info = C.export_kit(col, "E", manifest)
renders = [] if globals().get("SKIP_RENDER") else [C.preview(col, C.render_path("AL_KitE"))]
bpy.ops.wm.save_mainfile()
result = {"export": info, "renders": renders, "zfight": C.zfight_report(col),
          "pieces": {n: {"size": e["size"], "tris": sum(C.tri_count(bpy.data.objects[o]) for o in e["objects"])} for n, e in manifest.items()}}
