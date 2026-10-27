# Bakunawa Cove -- Kit V: shanty village (B173). Rules: tools/maps/lobby/README.md (split by material, origin
# bottom-centre, FRONT -Y, row along +X, C.zfight_report = 0). Chunky, 2x scale: door 10, storey ~12.
# Pieces: BC_Shack (stilt hut, thatch), BC_ShackTall (2 storeys, shingle roof, balcony), BC_StallRed, BC_StallTeal,
#         BC_LampPost, BC_FlagPole, BC_Stairs, BC_Fence
import importlib.util
import math
import os
import sys

from mathutils import Matrix

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np


def gable_roof(bm, hx, hy, z0, rise, over=1.4, thick=0.6):
    """Thick gable roof, ridge along X (eaves on the front/back), overhanging every side."""
    pts = [(-hy - over, z0), (0.0, z0 + rise), (hy + over, z0), (hy + over, z0 - thick),
           (0.0, z0 + rise - thick * 1.4), (-hy - over, z0 - thick)]
    # prism extrudes (x, z) along Y -> build it along X by turning 90 deg
    return C.prism(bm, pts, -hx - over, hx + over, bevel=0.2, M=Matrix.Rotation(-math.pi / 2, 4, "Z"))


def window(P, x, y, z, w, h, face=-1):
    """Lit window recessed in a wall at y (face -1 = front): glow pane 0.3 inside, dark frame proud, shutters."""
    LP, WD = P.bm("Lamp"), P.bm("WoodDark")
    C.box(LP, x - w / 2, y - 0.2, z, x + w / 2, y + 0.2, z + h, bevel=0.05)
    fy = y + face * 0.35
    C.box(WD, x - w / 2 - 0.4, fy - 0.2, z - 0.4, x + w / 2 + 0.4, fy + 0.2, z, bevel=0.06)
    C.box(WD, x - w / 2 - 0.4, fy - 0.2, z + h, x + w / 2 + 0.4, fy + 0.2, z + h + 0.4, bevel=0.06)
    C.box(WD, x - 0.12, fy - 0.15, z, x + 0.12, fy + 0.15, z + h, bevel=0.03)  # mullion
    for s in (-1, 1):  # open shutters
        x0 = x + w / 2 + 0.4 if s > 0 else x - w / 2 - 1.3
        C.box(P.bm("Plank"), x0, fy + face * 0.25 - 0.12, z - 0.1, x0 + 0.9, fy + face * 0.25 + 0.12, z + h + 0.1, bevel=0.05)


def door(P, x, y, w, h, z0=0.0, face=-1):
    WD = P.bm("WoodDark")
    C.box(WD, x - w / 2, y - 0.2, z0, x + w / 2, y + 0.2, z0 + h, bevel=0.08)  # door leaf (inset)
    fy = y + face * 0.35
    for s in (-1, 1):
        C.box(WD, x + s * (w / 2 + 0.3) - 0.3, fy - 0.25, z0, x + s * (w / 2 + 0.3) + 0.3, fy + 0.25, z0 + h + 0.6, bevel=0.08)
    C.box(WD, x - w / 2 - 0.6, fy - 0.25, z0 + h, x + w / 2 + 0.6, fy + 0.25, z0 + h + 0.6, bevel=0.08)
    C.drum(P.bm("Gold"), (x + w * 0.3, y + face * 0.3), z0 + h * 0.45, 0.4, 0.25, sides=8, bevel=0.05,
           M=None)


def stilts(P, hx, hy, z_floor):
    WD = P.bm("WoodDark")
    for x in (-hx + 0.6, hx - 0.6):
        for y in (-hy + 0.6, hy - 0.6):
            C.drum(WD, (x, y), -1.0, z_floor + 1.0, 0.55, sides=8, bevel=0.1)


def shack(col, man, origin):
    """BC_Shack 14W x 12D: raised plank hut on stilts (floor 3), front porch + steps, thatch gable, lit windows."""
    P = C.Piece("BC_Shack", origin)
    PL, WD, TH = P.bm("Plank"), P.bm("WoodDark"), P.bm("Thatch")
    hx, hy, zf = 6.0, 5.0, 3.0
    stilts(P, hx, hy, zf)
    C.box(WD, -hx - 0.3, -hy - 3.5, zf - 0.6, hx + 0.3, hy + 0.3, zf, bevel=0.15)  # floor platform + porch
    C.box(PL, -hx, -hy, zf, hx, hy, zf + 10.0, bevel=0.2)  # walls
    for x in (-hx, hx):  # corner posts proud of the walls
        for y in (-hy, hy):
            C.box(WD, x - 0.45, y - 0.45, zf, x + 0.45, y + 0.45, zf + 10.3, bevel=0.1)
    door(P, -2.0, -hy, 3.4, 7.0, zf)
    window(P, 2.8, -hy, zf + 3.6, 3.0, 3.0)
    gable_roof(TH, hx, hy, zf + 10.0, 5.5, over=1.6, thick=0.8)
    C.prism(PL, [(-hy, zf + 10.0), (0.0, zf + 10.0 + 5.0), (hy, zf + 10.0)], -hx + 0.3, hx - 0.3, bevel=0.1,
            M=Matrix.Rotation(-math.pi / 2, 4, "Z"))  # gable ends under the roof
    for i in range(4):  # steps down from the porch
        z = zf - 0.6 - (i + 1) * 0.6
        C.box(PL, -4.0, -hy - 3.5 - (i + 1) * 0.9, z, 0.0, -hy - 3.5 - i * 0.9, z + 0.6, bevel=0.08)
    for x in (-hx, hx):  # porch posts holding the roof edge
        C.drum(WD, (x * 0.9, -hy - 3.0), zf, 8.6, 0.35, sides=8, bevel=0.08)
    return P.done(col, man)


def shack_tall(col, man, origin):
    """BC_ShackTall 16W x 14D x ~34H: stone-skirted ground floor, jettied plank upper, balcony, shingle roof."""
    P = C.Piece("BC_ShackTall", origin)
    PL, WD, ST, SH = P.bm("Plank"), P.bm("WoodDark"), P.bm("Stone"), P.bm("Shingle")
    hx, hy = 7.0, 6.0
    C.box(ST, -hx, -hy, 0.0, hx, hy, 11.0, bevel=0.3)
    door(P, 0.0, -hy, 4.0, 8.0, 0.0)
    for x in (-4.6, 4.6):
        window(P, x, -hy, 4.0, 2.4, 3.2)
    C.box(WD, -hx - 1.4, -hy - 1.4, 11.0, hx + 1.4, hy + 1.4, 12.0, bevel=0.2)  # jetty beam
    C.box(PL, -hx - 1.0, -hy - 1.0, 12.0, hx + 1.0, hy + 1.0, 23.0, bevel=0.25)
    for x in (-hx - 1.0, hx + 1.0):
        for y in (-hy - 1.0, hy + 1.0):
            C.box(WD, x - 0.5, y - 0.5, 12.0, x + 0.5, y + 0.5, 23.3, bevel=0.1)
    for x in (-3.8, 3.8):
        window(P, x, -hy - 1.0, 15.5, 2.6, 3.6)
    # balcony on the front
    C.box(WD, -5.5, -hy - 4.4, 11.4, 5.5, -hy - 1.0, 12.2, bevel=0.15)
    for x in np.linspace(-5.2, 5.2, 8):
        C.box(WD, x - 0.15, -hy - 4.2, 12.2, x + 0.15, -hy - 3.9, 14.6, bevel=0.04)
    C.box(WD, -5.5, -hy - 4.4, 14.6, 5.5, -hy - 3.7, 15.1, bevel=0.1)
    for s in (-1, 1):
        C.tube(WD, [(s * 5.0, -hy - 1.2, 8.0), (s * 5.0, -hy - 4.0, 11.4)], [0.3, 0.3], sides=6, v_tile=3.0)
    gable_roof(SH, hx + 1.0, hy + 1.0, 23.0, 8.5, over=1.6, thick=0.8)
    C.prism(PL, [(-hy - 1.0, 23.0), (0.0, 23.0 + 7.8), (hy + 1.0, 23.0)], -hx - 0.7, hx + 0.7, bevel=0.1,
            M=Matrix.Rotation(-math.pi / 2, 4, "Z"))
    C.box(ST, 2.5, 1.0, 26.0, 5.0, 3.5, 34.0, bevel=0.2)  # chimney
    return P.done(col, man)


def stall(col, man, name, origin, awning):
    """Market stall 12W x 8D x ~10H: plank counter, 4 posts, sloped striped awning with a scalloped valance, goods."""
    P = C.Piece(name, origin)
    PL, WD, AW = P.bm("Plank"), P.bm("WoodDark"), P.bm(awning)
    C.box(PL, -5.5, -3.6, 0.0, 5.5, -1.6, 3.6, bevel=0.15)  # counter
    C.box(WD, -5.9, -3.9, 3.6, 5.9, -1.4, 4.1, bevel=0.1)  # counter top
    for x in (-5.6, 5.6):
        for y, h in ((-3.6, 9.0), (3.4, 10.6)):
            C.box(WD, x - 0.3, y - 0.3, 0.0, x + 0.3, y + 0.3, h, bevel=0.08)
    # awning: thin sloped slab front low (9) -> back high (10.8), striped along X
    C.prism(AW, [(4.6, 8.8), (-4.2, 10.7), (-4.2, 11.0), (4.6, 9.1)], -6.6, 6.6, bevel=0.05,
            M=Matrix.Rotation(-math.pi / 2, 4, "Z"))
    for i in range(11):  # scalloped valance hanging from the front edge
        x = -6.0 + i * 1.2
        C.prism(AW, [(-0.6, 0.0), (0.6, 0.0), (0.0, -1.3)], -0.06, 0.06, bevel=0.0,
                M=Matrix.Translation((x, -4.7, 8.85)))
    r = C.rng(sum(map(ord, name)))
    for i in range(5):  # fruit / goods on the counter
        C.lathe(P.bm("Petal") if i % 2 else P.bm("Gold"), [(0.0, 0.0)] +
                [(0.5 * math.sin(t), 0.5 - 0.5 * math.cos(t)) for t in np.linspace(0.3, math.pi - 0.3, 5)] + [(0.0, 1.0)],
                10, center=(-4.0 + i * 2.0, -2.6 + r.uniform(-0.3, 0.3), 4.1))
    C.box(PL, -1.4, 1.0, 0.0, 1.4, 3.8, 2.8, bevel=0.1)  # crate behind
    return P.done(col, man)


def lamp_post(col, man, origin):
    """Harbour lamp: wooden post, iron bracket arm, hanging glowing lantern."""
    P = C.Piece("BC_LampPost", origin)
    WD, IR, LP = P.bm("WoodDark"), P.bm("Iron"), P.bm("Lamp")
    C.drum(WD, (0, 0), 0.0, 0.8, 0.9, sides=10, bevel=0.15)
    C.drum(WD, (0, 0), 0.8, 11.2, 0.45, r_top=0.38, sides=10, bevel=0.08)
    C.tube(IR, [(0, 0, 10.6), (0, -2.6, 10.6), (0, -2.6, 9.9)], [0.13, 0.13, 0.13], sides=6, v_tile=1.0)
    C.tube(IR, [(0, 0, 9.4), (0, -1.5, 10.6)], [0.1, 0.1], sides=6, v_tile=1.0)
    C.lathe(IR, [(0.0, 9.9), (0.9, 9.5), (0.0, 9.2)], 6, center=(0, -2.6, 0))  # lantern cap
    C.lathe(LP, [(0.0, 7.6), (0.55, 7.7), (0.65, 8.6), (0.5, 9.25), (0.0, 9.3)], 8, center=(0, -2.6, 0))
    C.lathe(IR, [(0.0, 7.3), (0.75, 7.35), (0.75, 7.62), (0.0, 7.62)], 6, center=(0, -2.6, 0))
    return P.done(col, man)


def flag_pole(col, man, origin):
    P = C.Piece("BC_FlagPole", origin)
    C.drum(P.bm("Stone"), (0, 0), 0.0, 1.2, 1.4, sides=8, bevel=0.2)
    C.drum(P.bm("WoodDark"), (0, 0), 1.2, 18.0, 0.35, r_top=0.25, sides=8, bevel=0.05)
    C.lathe(P.bm("Gold"), [(0.0, 0.0), (0.5, 0.3), (0.0, 0.9)], 8, center=(0, 0, 19.2))
    C.flag_card(P.bm("Flag"), (0.3, 0.0, 18.8), 7.0, 4.5, wave=0.8)
    P.smooth["Flag"] = 80.0
    return P.done(col, man)


def stairs(col, man, origin):
    """Wooden switchback flight 6W x 16 run x 12 rise (10 steps on stringers, rope rail one side), climbs toward +Y."""
    P = C.Piece("BC_Stairs", origin)
    PL, WD, RP = P.bm("Plank"), P.bm("WoodDark"), P.bm("Rope")
    n = 10
    for i in range(n):
        y0 = -8.0 + i * 1.6
        z = (i + 1) * 1.2
        C.box(PL, -3.0, y0, z - 0.35, 3.0, y0 + 1.75, z, bevel=0.06)
    for x in (-2.7, 2.7):
        C.prism(WD, [(-8.0, 0.0), (8.0, 11.8), (8.0, 10.6), (-6.2, -0.0)], x - 0.25, x + 0.25, bevel=0.06,
                M=Matrix.Rotation(-math.pi / 2, 4, "Z") @ Matrix.Rotation(math.pi, 4, "Z"))
    for i in range(0, n + 1, 2):
        y = -8.0 + i * 1.6
        C.drum(WD, (3.2, y), 0.0, i * 1.2 + 3.4, 0.3, sides=8, bevel=0.05)
    C.tube(RP, [(3.2, -8.0, 3.2), (3.2, 8.0, 15.2)], [0.13, 0.13], sides=6, v_tile=1.0)
    return P.done(col, man)


def fence(col, man, origin):
    """Driftwood fence 12 long: 5 posts, two rope runs (tiles along X)."""
    P = C.Piece("BC_Fence", origin)
    for x in np.linspace(-6.0, 6.0, 5)[:-1] + 1.5:
        C.drum(P.bm("WoodDark"), (x, 0), 0.0, 3.4, 0.3, r_top=0.25, sides=7, bevel=0.06)
    for z in (1.6, 2.8):
        pts = [(x, 0, z - 0.25 * math.sin(math.pi * ((x + 4.5) % 3.0) / 3.0)) for x in np.linspace(-6, 6, 13)]
        C.tube(P.bm("Rope"), pts, [0.11] * 13, sides=5, v_tile=1.0, cap=False)
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitV")
    man = {}
    row = C.Row(gap=10.0)
    shack(col, man, row.next(16))
    shack_tall(col, man, row.next(20))
    stall(col, man, "BC_StallRed", row.next(14), "AwningRed")
    stall(col, man, "BC_StallTeal", row.next(14), "AwningTeal")
    lamp_post(col, man, row.next(4))
    flag_pole(col, man, row.next(8))
    stairs(col, man, row.next(7))
    fence(col, man, row.next(12))
    C.write_manifest("V", man)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
