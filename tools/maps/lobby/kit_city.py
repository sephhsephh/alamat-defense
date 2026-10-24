# Alamat Defense Lobby "Holy Coast" -- Kit F: the CITY (B172 phase 5, user: "arrange them like a real city ... more
# variety of buildings"). Same rules as README.md (split by material, origin bottom-centre, FRONT -Y = the street side,
# row along +X) and the z-fight rule (C.zfight_report must be 0 before export).
# Pieces: AL_RowHouse, AL_CornerHouse, AL_MarketHall, AL_Library, AL_StreetArch, AL_Bathhouse, AL_ClockTower,
# AL_CityFountain.
# Run: blender.exe -b <root>/blend/AL_kitF_city.blend --python-expr "exec(open(r'<this>').read()); print('RESULT', result)"
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


def finial(bm, cx, cy, z0, h, r):
    prof = C.round_profile([(0.0, z0), (r, z0), (r * 0.6, z0 + h * 0.25), (r * 1.1, z0 + h * 0.45),
                            (r * 0.35, z0 + h * 0.75), (0.0, z0 + h)], 0.1)
    return C.lathe(bm, prof, 16, center=(cx, cy, 0.0))


def pyramid(bm, cx, cy, hw, z0, z1):
    return C.lathe(bm, [(0.0, z0), (hw * S2, z0), (0.0, z1)], 4, center=(cx, cy, 0.0), phase=PI / 4)


def gable(bm, hx, hy, z0, rise, over=1.2, M=None):
    """Gable roof: ridge along Y over a footprint of half-widths hx (eaves side) x hy, overhang `over`."""
    return C.prism(bm, [(-hx - over, z0), (hx + over, z0), (0.0, z0 + rise)], -hy - over, hy + over, bevel=0.2, M=M)


def column(P, cx, cy, z0, h, r):
    Mb, G = P.bm("Marble"), P.bm("Gold")
    C.drum(Mb, (cx, cy), z0, 1.0, r * 1.45, sides=20, bevel=0.2)
    C.drum(Mb, (cx, cy), z0 + 1.0, h - 2.6, r, r_top=r * 0.9, sides=20, bevel=0.1)
    C.drum(G, (cx, cy), z0 + h - 1.6, 0.6, r * 1.15, sides=20, bevel=0.15)
    C.drum(Mb, (cx, cy), z0 + h - 1.0, 1.0, r * 1.5, sides=20, bevel=0.2)


def window(P, x, y, z, w, h, face=-1):
    """Capiz window set INTO a wall face at y (face -1 = front): recessed pane, marble frame proud, gold sill."""
    Mb, G, CZ = P.bm("Marble"), P.bm("Gold"), P.bm("Capiz")
    C.box(CZ, x - w / 2, y - 0.25, z, x + w / 2, y + 0.25, z + h, bevel=0.05)
    fy = y + face * 0.45  # frame stands 0.45 proud of the wall
    for sx in (-1, 1):
        C.box(Mb, x + sx * (w / 2 + 0.35) - 0.35, fy - 0.3, z - 0.2, x + sx * (w / 2 + 0.35) + 0.35, fy + 0.3, z + h + 0.2, bevel=0.08)
    C.box(Mb, x - w / 2 - 0.7, fy - 0.3, z + h + 0.2, x + w / 2 + 0.7, fy + 0.3, z + h + 0.9, bevel=0.1)
    C.box(G, x - w / 2 - 0.9, fy + face * 0.2 - 0.35, z - 0.75, x + w / 2 + 0.9, fy + face * 0.2 + 0.35, z - 0.2, bevel=0.08)


def row_house(col, man, origin):
    """AL_RowHouse 16W x 18D x ~36H: 3 storeys -- marble-block ground floor with an arched door, two capiz-windowed
    floors, a gold-railed balcony, teal gable roof (ridge along Y so neighbours in a row line up), chimney."""
    P = C.Piece("AL_RowHouse", origin)
    Mb, MB, G, TT, PV = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Pave")
    hx, hy = 7.8, 9.0
    slab(Mb, 0, 0, hx + 0.4, hy + 0.4, 0.0, 1.0, bevel=0.25)
    C.arch_wall(MB, 2 * hx, 11.0, 1.4, 4.4, 6.5, kind="round", bevel=0.2, n=12, M=T(0, -hy + 0.7, 1.0))
    C.box(MB, -hx, -hy + 1.4, 1.0, hx, hy, 12.0, bevel=0.25)  # the rest of the ground floor (behind the front wall)
    C.box(G, -hx - 0.3, -hy - 0.3, 11.9, hx + 0.3, hy + 0.3, 12.5, bevel=0.1)  # string course (proud on 3 sides)
    C.box(Mb, -hx, -hy, 12.5, hx, hy, 30.0, bevel=0.3)
    for z in (15.0, 23.0):
        for x in (-3.8, 3.8):
            window(P, x, -hy, z, 3.0, 5.0, face=-1)
            window(P, x, hy, z, 3.0, 5.0, face=1)
    # balcony on the 2nd floor front
    C.box(PV, -5.5, -hy - 3.2, 20.6, 5.5, -hy + 0.2, 21.3, bevel=0.15)
    for k in range(7):
        x = -5.2 + k * (10.4 / 6)
        C.box(G, x - 0.18, -hy - 3.0, 21.3, x + 0.18, -hy - 2.64, 23.6, bevel=0.03)
    C.box(G, -5.5, -hy - 3.15, 23.6, 5.5, -hy - 2.5, 24.0, bevel=0.08)
    C.box(Mb, -hx - 0.6, -hy - 0.6, 30.0, hx + 0.6, hy + 0.6, 31.0, bevel=0.25)
    gable(TT, hx, hy, 31.0, 7.5)
    C.box(G, -0.45, -hy - 1.5, 38.1, 0.45, hy + 1.5, 38.9, bevel=0.15)
    slab(MB, 4.6, 4.0, 1.2, 1.2, 33.0, 40.0, bevel=0.2)  # chimney
    slab(G, 4.6, 4.0, 1.45, 1.45, 40.0, 40.6, bevel=0.1)
    return P.done(col, man)


def corner_house(col, man, origin):
    """AL_CornerHouse 26 x 26 x ~46: L-shaped 2-storey block wrapped round a round corner tower with a cone roof."""
    P = C.Piece("AL_CornerHouse", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    slab(Mb, 0, 0, 13.4, 13.4, 0.0, 1.0, bevel=0.25)
    # two wings: along X (front) and along Y (left side)
    C.box(MB, -12.5, -12.5, 1.0, 12.5, -2.5, 11.0, bevel=0.25)
    C.box(MB, -12.5, -2.5, 1.0, -2.5, 12.5, 11.0, bevel=0.25)
    C.box(G, -12.8, -12.8, 10.9, 12.8, -2.2, 11.5, bevel=0.1)
    C.box(G, -12.95, -2.2, 10.8, -2.05, 12.95, 11.6, bevel=0.1)  # taller + wider than the front band: no shared faces
    C.box(Mb, -12.5, -12.5, 11.5, 12.5, -2.5, 21.0, bevel=0.3)
    C.box(Mb, -12.5, -2.5, 11.5, -2.5, 12.5, 21.0, bevel=0.3)
    for x in (-6.5, 0.5, 7.0):
        window(P, x, -12.5, 3.5, 2.6, 5.0, face=-1)
        window(P, x, -12.5, 13.5, 2.6, 5.0, face=-1)
    gable(TT, 5.0, 12.5, 21.0, 6.0, M=T(0, -7.5, 0) @ Rz(PI / 2))  # front wing, ridge along X
    gable(TT, 5.0, 12.5, 21.0, 6.0, M=T(-7.5, 0, 0))
    # corner tower (front-left corner)
    tx, ty = -12.0, -12.0
    C.drum(MB, (tx, ty), 0.0, 30.0, 5.5, sides=32, bevel=0.3)
    C.torus(G, (tx, ty, 12.6), 5.6, 0.35, seg=48, sides=6, uv=4.0)  # above the string course (its hex underside sat flush)
    for k in range(4):
        a = k * PI / 2 + PI / 4
        C.block(P.bm("Capiz"), (tx + math.cos(a) * 5.55, ty + math.sin(a) * 5.55, 23.0), (2.0, 0.6, 4.0), bevel=0.1, rot=(0, 0, a + PI / 2))
    C.drum(Mb, (tx, ty), 30.0, 1.4, 6.4, sides=32, bevel=0.3)
    C.lathe(TT, [(0.0, 31.4), (6.6, 31.4), (0.0, 42.0)], 32, center=(tx, ty, 0.0), uv=6.0)
    finial(G, tx, ty, 41.6, 4.5, 0.7)
    return P.done(col, man)


def market_hall(col, man, origin):
    """AL_MarketHall 62W x 26D x ~30H: open arcade hall -- 5 round arches each long side, 2 on the ends, a clerestory
    band of capiz, a teal gable roof with a gold ridge and cupola."""
    P = C.Piece("AL_MarketHall", origin)
    Mb, MB, G, TT, PV, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Pave"), P.bm("Capiz")
    hx, hy = 30.0, 12.0
    slab(Mb, 0, 0, hx + 1.0, hy + 1.0, 0.0, 1.0, bevel=0.3)
    C.box(PV, -hx + 0.5, -hy + 0.5, 1.0, hx - 0.5, hy - 0.5, 1.3, bevel=0.0)
    for sy in (-1, 1):
        for k in range(5):
            C.arch_wall(Mb, 12.0, 14.0, 1.6, 8.0, 9.0, kind="round", bevel=0.25, n=14, M=T(-24.0 + k * 12.0, sy * (hy - 0.8), 1.0))
    for sx in (-1, 1):
        for k in range(2):
            C.arch_wall(Mb, 11.4, 14.0, 1.6, 7.0, 9.0, kind="round", bevel=0.25, n=14,
                        M=T(sx * (hx - 0.8), -5.7 + k * 11.4, 1.0) @ Rz(PI / 2))
    C.box(G, -hx - 0.4, -hy - 0.4, 14.6, hx + 0.4, hy + 0.4, 15.4, bevel=0.1)
    C.box(MB, -hx, -hy, 15.4, hx, hy, 17.0, bevel=0.2)
    C.box(CZ, -hx + 1.0, -hy + 0.3, 17.0, hx - 1.0, hy - 0.3, 20.0, bevel=0.05)  # clerestory (inset 0.3 from the band)
    C.box(Mb, -hx - 0.3, -hy - 0.3, 20.0, hx + 0.3, hy + 0.3, 21.2, bevel=0.25)
    C.prism(TT, [(-hy - 1.6, 21.2), (hy + 1.6, 21.2), (0.0, 29.0)], -hx - 1.6, hx + 1.6, bevel=0.2, M=Rz(PI / 2))
    C.box(G, -hx - 1.8, -0.5, 28.4, hx + 1.8, 0.5, 29.4, bevel=0.15)
    C.drum(Mb, (0, 0), 28.0, 4.0, 2.6, sides=16, bevel=0.2)
    C.lathe(G, C.ellipse_profile(2.9, 3.4, z0=32.0, n=8), 16, uv=4.0)
    finial(G, 0, 0, 35.2, 3.4, 0.6)
    return P.done(col, man)


def library(col, man, origin):
    """AL_Library 48W x 38D x ~44H: temple-front hall -- stepped podium, 6 columns + pediment, block cella with tall
    capiz windows, gold dome on a drum."""
    P = C.Piece("AL_Library", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    for i, (hx, hy) in enumerate(((24.0, 19.0), (22.5, 17.5), (21.0, 16.0))):
        slab(Mb, 0, 0, hx, hy, i * 1.2, (i + 1) * 1.2, bevel=0.3)
    z0 = 3.6
    C.box(MB, -19.0, -6.0, z0, 19.0, 15.0, z0 + 20.0, bevel=0.3)  # cella (porch in front of y -6)
    for x in (-12.0, 0.0, 12.0):
        window(P, x, -6.0, z0 + 5.0, 4.0, 11.0, face=-1)
    for x in (-15.0, -9.0, -3.0, 3.0, 9.0, 15.0):
        column(P, x, -13.0, z0, 20.0, 1.3)
    C.box(Mb, -20.0, -15.5, z0 + 20.0, 20.0, 15.5, z0 + 22.0, bevel=0.3)  # entablature
    C.box(G, -20.3, -15.8, z0 + 20.6, 20.3, 15.8, z0 + 21.4, bevel=0.1)
    C.prism(Mb, [(-20.6, z0 + 22.0), (20.6, z0 + 22.0), (0.0, z0 + 29.0)], -15.9, -13.9, bevel=0.25)  # pediment front
    C.prism(TT, [(-21.0, z0 + 22.0), (21.0, z0 + 22.0), (0.0, z0 + 29.2)], -13.9, 16.2, bevel=0.2)
    C.drum(Mb, (0, 4.0), z0 + 22.0, 9.0, 7.5, sides=32, bevel=0.3)
    C.torus(G, (0, 4.0, z0 + 30.8), 7.6, 0.4, seg=48, sides=6, uv=4.0)
    C.lathe(G, C.ellipse_profile(7.2, 7.5, z0=z0 + 31.0, n=10), 32, center=(0, 4.0, 0.0), uv=4.0)
    finial(G, 0, 4.0, z0 + 38.3, 4.0, 0.8)
    return P.done(col, man)


def street_arch(col, man, origin):
    """AL_StreetArch 56W x 10D x ~50H: triumphal arch spanning a 34-stud street -- two block piers with engaged
    columns, a round arch, an attic with a gold frieze, a central sun disc and finials."""
    P = C.Piece("AL_StreetArch", origin)
    Mb, MB, G, CR = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("Crystal")
    C.arch_wall(MB, 56.0, 36.0, 10.0, 34.0, 22.0, kind="round", bevel=0.4, n=20)
    for sx in (-1, 1):
        slab(Mb, sx * 25.0, 0, 3.8, 5.6, 0.0, 2.0, bevel=0.3)
        for sy in (-1, 1):
            column(P, sx * 22.5, sy * 6.0, 2.0, 30.0, 1.1)
    C.box(Mb, -28.6, -5.6, 36.0, 28.6, 5.6, 38.0, bevel=0.3)
    C.box(MB, -27.0, -4.8, 38.0, 27.0, 4.8, 46.0, bevel=0.3)
    C.box(G, -27.3, -5.1, 40.5, 27.3, 5.1, 42.0, bevel=0.1)  # frieze band, proud of the attic
    C.box(Mb, -28.0, -5.4, 46.0, 28.0, 5.4, 47.4, bevel=0.3)
    for sy in (-1, 1):
        C.torus(G, (0, sy * 5.3, 41.0), 3.4, 0.5, seg=40, sides=8, axis="Y", uv=4.0)
    for x in (-24.0, -12.0, 0.0, 12.0, 24.0):
        finial(G, x, 0, 47.4, 5.0 if x == 0 else 3.5, 0.9 if x == 0 else 0.6)
    C.crystal(CR, (0, 0, 52.0), 3.0, 8.0, sides=6, waist=0.5)
    return P.done(col, man)


def bathhouse(col, man, origin):
    """AL_Bathhouse 42 x 42 x ~32: square hall with arcaded sides, central gold dome on a drum, 4 corner domelets."""
    P = C.Piece("AL_Bathhouse", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    slab(Mb, 0, 0, 21.0, 21.0, 0.0, 1.2, bevel=0.3)
    for a in (0.0, PI / 2, PI, 3 * PI / 2):
        for k in range(3):
            C.arch_wall(MB, 10.0, 14.0, 2.0, 6.0, 8.0, kind="round", bevel=0.25, n=12, M=Rz(a) @ T(-10.0 + k * 10.0, -19.0, 1.2))
    for sx in (-1, 1):
        for sy in (-1, 1):
            slab(MB, sx * 17.0, sy * 17.0, 3.0, 3.0, 1.2, 15.2, bevel=0.25)
    C.box(Mb, -16.0, -16.0, 1.2, 16.0, 16.0, 14.0, bevel=0.2)
    C.box(G, -20.4, -20.4, 14.6, 20.4, 20.4, 15.4, bevel=0.1)
    C.box(Mb, -20.0, -20.0, 15.4, 20.0, 20.0, 17.0, bevel=0.3)
    C.drum(MB, (0, 0), 17.0, 5.0, 11.0, sides=40, bevel=0.3)
    for k in range(8):
        a = k * PI / 4
        C.block(CZ, (math.cos(a) * 11.05, math.sin(a) * 11.05, 19.5), (2.4, 0.6, 3.0), bevel=0.1, rot=(0, 0, a + PI / 2))
    C.lathe(G, C.ellipse_profile(11.5, 9.0, z0=22.0, n=12), 40, uv=4.0)
    finial(G, 0, 0, 30.6, 4.0, 0.9)
    for sx in (-1, 1):
        for sy in (-1, 1):
            C.lathe(TT, C.ellipse_profile(3.4, 3.4, z0=17.0, n=8), 16, center=(sx * 17.0, sy * 17.0, 0.0), uv=6.0)
            finial(G, sx * 17.0, sy * 17.0, 20.2, 2.4, 0.4)
    return P.done(col, man)


def clock_tower(col, man, origin):
    """AL_ClockTower 20 x 20 x ~96: civic landmark -- block shaft with gold bands, a clock stage with 4 gold clock faces
    (bronze hands), an open arched belfry, a teal spire."""
    P = C.Piece("AL_ClockTower", origin)
    Mb, MB, G, TT, BZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Bronze")
    slab(Mb, 0, 0, 10.0, 10.0, 0.0, 2.0, bevel=0.4)
    slab(MB, 0, 0, 8.0, 8.0, 2.0, 52.0, bevel=0.4)
    for z in (18.0, 35.0):
        slab(G, 0, 0, 8.3, 8.3, z, z + 1.0, bevel=0.15)
    slab(Mb, 0, 0, 9.0, 9.0, 52.0, 62.0, bevel=0.4)  # clock stage
    for a in (0.0, PI / 2, PI, 3 * PI / 2):
        M = Rz(a)
        C.torus(G, (0, -9.4, 57.0), 3.6, 0.4, seg=40, sides=8, axis="Y", uv=4.0, M=M)
        faces = C.lathe(G, [(3.4, 0.0), (0.0, 0.0)], 32, cap=False, M=M @ T(0, -9.25, 57.0) @ Matrix.Rotation(PI / 2, 4, "X"))
        C.box(BZ, -0.2, -9.6, 57.0, 0.2, -9.45, 59.8, bevel=0.0, M=M)  # minute hand
        C.box(BZ, 0.1, -9.75, 56.8, 2.2, -9.55, 57.2, bevel=0.0, M=M)  # hour hand, in front of the minute hand
    slab(G, 0, 0, 9.3, 9.3, 62.0, 62.8, bevel=0.15)
    for a in (0.0, PI / 2, PI, 3 * PI / 2):
        C.arch_wall(Mb, 16.0, 13.0, 1.6, 9.0, 7.0, kind="round", bevel=0.25, n=14, M=Rz(a) @ T(0, -7.2, 62.8))
    C.lathe(G, C.round_profile([(0.0, 73.0), (0.5, 73.0), (2.6, 67.5), (3.0, 65.5), (0.0, 65.5)], 0.2), 24)
    slab(Mb, 0, 0, 8.8, 8.8, 75.8, 77.6, bevel=0.3)
    pyramid(TT, 0, 0, 8.2, 77.6, 92.0)
    finial(G, 0, 0, 91.5, 6.0, 1.0)
    return P.done(col, man)


def city_fountain(col, man, origin):
    """AL_CityFountain d34 x ~22: square civic fountain -- octagonal basin, a raised bowl on a column, a gold obelisk
    finial; the water surface is a separate Crystal disc 0.3 below the rim (Neon in Studio = glowing water)."""
    P = C.Piece("AL_CityFountain", origin)
    Mb, MB, G, CR = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("Crystal")
    C.lathe(MB, [(0.0, 0.0), (17.0 / math.cos(PI / 8), 0.0), (17.0 / math.cos(PI / 8), 2.6), (15.6 / math.cos(PI / 8), 2.6),
                 (15.6 / math.cos(PI / 8), 1.0), (0.0, 1.0)], 8, phase=PI / 8)
    C.torus(G, (0, 0, 2.6), 16.3 / math.cos(PI / 8) * 0.97, 0.35, seg=8, sides=6)
    faces = C.lathe(CR, [(15.4, 1.9), (0.0, 1.9)], 40, cap=False)
    C.drum(Mb, (0, 0), 1.0, 9.0, 1.6, sides=20, bevel=0.15)
    C.lathe(Mb, C.round_profile([(0.0, 10.0), (1.6, 10.0), (6.5, 11.6), (6.8, 12.6), (0.0, 12.0)], 0.3), 32)
    C.lathe(CR, [(6.0, 12.25), (0.0, 12.25)], 32, cap=False)
    C.torus(G, (0, 0, 12.6), 6.7, 0.3, seg=40, sides=6, uv=4.0)
    C.lathe(G, [(0.0, 12.4), (1.2 * S2, 12.4), (0.4 * S2, 20.0), (0.0, 21.5)], 4, phase=PI / 4)
    return P.done(col, man)


PIECES = [(row_house, 18.0), (corner_house, 28.0), (market_hall, 66.0), (library, 50.0), (street_arch, 58.0),
          (bathhouse, 44.0), (clock_tower, 20.0), (city_fountain, 36.0)]

col = C.clear_collection("AL_KitF")
row = C.Row(gap=30.0)
manifest = {}
for build, width in PIECES:
    build(col, manifest, row.next(width))
zf = C.zfight_report(col)
info = C.export_kit(col, "F", manifest)
renders = [] if globals().get("SKIP_RENDER") else [C.preview(col, C.render_path("AL_KitF"))]
bpy.ops.wm.save_mainfile()
result = {"export": info, "zfight": zf, "renders": renders,
          "pieces": {n: {"size": e["size"], "tris": sum(C.tri_count(bpy.data.objects[o]) for o in e["objects"])} for n, e in manifest.items()}}
