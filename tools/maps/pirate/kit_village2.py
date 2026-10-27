# Bakunawa Cove -- Kit W: village life + islet props (B173 pt3, user: "add more assets to make the map feel more
# alive ... no empty island"). Rules: tools/maps/lobby/README.md (split by material, origin bottom-centre, FRONT -Y,
# row along +X, C.zfight_report = 0).
# Pieces: BC_Tavern, BC_Lighthouse, BC_Watchtower, BC_Well, BC_Signpost, BC_TableSet, BC_Bench, BC_WeaponRack,
#         BC_CannonballPile, BC_Anchor, BC_RopeCoil, BC_Campfire, BC_Tent, BC_LaundryLine, BC_Dock, BC_MarketCart,
#         BC_Footbridge, BC_Chest
import importlib.util
import math
import os
import sys

from mathutils import Matrix, Vector

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np
PI = math.pi


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def Rz(a):
    return Matrix.Rotation(a, 4, "Z")


def gable(bm, hx, hy, z0, rise, over=1.4, thick=0.7):
    pts = [(-hy - over, z0), (0.0, z0 + rise), (hy + over, z0), (hy + over, z0 - thick),
           (0.0, z0 + rise - thick * 1.4), (-hy - over, z0 - thick)]
    return C.prism(bm, pts, -hx - over, hx + over, bevel=0.2, M=Rz(-PI / 2))


def egg(bm, c, r, sides=10):
    prof = [(0.0, -r)] + [(r * math.sin(t), -r * math.cos(t)) for t in np.linspace(0.35, PI - 0.35, 5)] + [(0.0, r)]
    return C.lathe(bm, prof, sides, center=c)


def lit_window(P, x, y, z, w, h, face=-1):
    LP, WD = P.bm("Lamp"), P.bm("WoodDark")
    C.box(LP, x - w / 2, y - 0.2, z, x + w / 2, y + 0.2, z + h, bevel=0.05)
    fy = y + face * 0.35
    C.box(WD, x - w / 2 - 0.4, fy - 0.2, z - 0.4, x + w / 2 + 0.4, fy + 0.2, z, bevel=0.06)
    C.box(WD, x - w / 2 - 0.4, fy - 0.2, z + h, x + w / 2 + 0.4, fy + 0.2, z + h + 0.4, bevel=0.06)
    C.box(WD, x - 0.12, fy - 0.15, z, x + 0.12, fy + 0.15, z + h, bevel=0.03)


def tavern(col, man, origin):
    """BC_Tavern 28W x 20D x ~38H ("The Serpent's Rest"): stone ground floor with an arched door, plank upper floor,
    steep shingle roof with two dormers, chimney, a hanging painted sign board, porch with posts."""
    P = C.Piece("BC_Tavern", origin)
    ST, PL, WD, SH = P.bm("Stone"), P.bm("Plank"), P.bm("WoodDark"), P.bm("Shingle")
    hx, hy = 14.0, 10.0
    C.box(ST, -hx - 0.5, -hy - 0.5, 0.0, hx + 0.5, hy + 0.5, 1.0, bevel=0.25)
    C.arch_wall(ST, 2 * hx, 12.0, 1.4, 5.0, 7.5, kind="round", bevel=0.2, n=12, M=T(0, -hy + 0.7, 1.0))
    C.box(ST, -hx, -hy + 1.4, 1.0, hx, hy, 13.0, bevel=0.25)
    C.box(WD, -2.4, -hy + 1.25, 1.0, 2.4, -hy + 1.55, 9.0, bevel=0.05)  # door leaves in the arch
    for x in (-9.0, 9.0):
        lit_window(P, x, -hy, 5.0, 3.6, 4.0)
    C.box(WD, -hx - 1.2, -hy - 1.2, 13.0, hx + 1.2, hy + 1.2, 14.0, bevel=0.2)  # jetty beam
    C.box(PL, -hx - 0.8, -hy - 0.8, 14.0, hx + 0.8, hy + 0.8, 25.0, bevel=0.25)
    for x in (-hx - 0.8, hx + 0.8):
        for y in (-hy - 0.8, hy + 0.8):
            C.box(WD, x - 0.5, y - 0.5, 14.0, x + 0.5, y + 0.5, 25.3, bevel=0.1)
    for x in (-8.5, 0.0, 8.5):
        lit_window(P, x, -hy - 0.8, 17.5, 3.0, 4.0)
    gable(SH, hx + 0.8, hy + 0.8, 25.0, 12.0, over=1.8, thick=0.9)
    C.prism(PL, [(-hy - 0.8, 25.0), (0.0, 25.0 + 11.2), (hy + 0.8, 25.0)], -hx - 0.5, hx + 0.5, bevel=0.1,
            M=Rz(-PI / 2))
    for x in (-7.0, 7.0):  # dormers on the front slope
        C.box(PL, x - 2.2, -hy - 0.2, 27.0, x + 2.2, -hy + 3.0, 31.0, bevel=0.15)
        lit_window(P, x, -hy - 0.2, 27.6, 2.2, 2.6)
        C.prism(SH, [(-2.9, 30.8), (0.0, 33.4), (2.9, 30.8), (2.9, 30.3), (0.0, 32.8), (-2.9, 30.3)], -hy - 0.6, -hy + 3.4,
                bevel=0.1, M=T(x, 0, 0))
    C.box(ST, 7.0, 3.0, 28.0, 10.0, 6.0, 40.0, bevel=0.2)  # chimney
    # porch roof on posts + the hanging sign
    C.box(WD, -hx, -hy - 5.0, 9.6, hx, -hy - 0.4, 10.2, bevel=0.1)
    for x in (-hx + 0.5, -4.5, 4.5, hx - 0.5):
        C.drum(WD, (x, -hy - 4.6), 0.0, 9.7, 0.4, sides=8, bevel=0.08)
    C.tube(WD, [(-6.0, -hy - 5.0, 9.4), (-6.0, -hy - 8.0, 9.4)], [0.25, 0.25], sides=6, v_tile=3.0)
    C.tube(P.bm("Rope"), [(-6.0, -hy - 7.6, 9.3), (-6.0, -hy - 7.6, 7.8)], [0.08, 0.08], sides=5, v_tile=1.0)
    C.box(WD, -6.2, -hy - 9.8, 5.0, -5.8, -hy - 5.6, 7.8, bevel=0.1)  # sign board (faces the street both ways)
    C.lathe(P.bm("Gold"), [(0.0, -0.1), (1.0, -0.1), (1.0, 0.1), (0.0, 0.1)], 16,
            M=T(-6.35, -hy - 7.7, 6.4) @ Matrix.Rotation(PI / 2, 4, "Y"))  # gold coin emblem
    return P.done(col, man)


def lighthouse(col, man, origin):
    """BC_Lighthouse d12 x ~46H: tapered stone tower with a red-shingle band, gallery with iron rail, glowing lantern
    room, cone roof, a small keeper's hut at the foot."""
    P = C.Piece("BC_Lighthouse", origin)
    ST, SH, IR, LP, WD = P.bm("Stone"), P.bm("Shingle"), P.bm("Iron"), P.bm("Lamp"), P.bm("WoodDark")
    P.uv_scale["Stone"] = 8.0
    C.drum(ST, (0, 0), 0.0, 2.0, 7.2, sides=24, bevel=0.3)
    C.drum(ST, (0, 0), 2.0, 32.0, 6.2, r_top=4.4, sides=24, bevel=0.2)
    C.drum(SH, (0, 0), 14.0, 4.0, 5.55 + 0.2, r_top=5.1 + 0.2, sides=24, bevel=0.1)  # red band, proud of the tower
    C.drum(ST, (0, 0), 34.0, 1.2, 6.0, sides=24, bevel=0.2)  # gallery floor
    C.torus(IR, (0, 0, 36.6), 5.6, 0.12, seg=36, sides=6)
    for x, y, a in C.polar(16, 5.6):
        C.drum(IR, (x, y), 35.2, 1.4, 0.1, sides=6, bevel=0.0)
    C.drum(LP, (0, 0), 35.2, 4.6, 3.2, sides=12, bevel=0.1)  # lantern room glass
    for x, y, a in C.polar(8, 3.35, PI / 8):
        C.drum(IR, (x, y), 35.2, 4.6, 0.18, sides=6, bevel=0.0)
    C.lathe(SH, C.round_profile([(0.0, 39.8), (4.4, 39.8), (4.2, 40.3), (0.0, 46.0)], 0.3), 16)
    C.lathe(IR, [(0.0, 45.8), (0.4, 46.0), (0.0, 47.6)], 8)
    for z, a in ((8.0, PI / 2), (20.0, -PI / 2 + 0.6), (26.0, PI / 2 - 0.3)):
        r = 6.2 - (6.2 - 4.4) * (z - 2) / 32 + 0.05
        M = T(r * math.cos(a), r * math.sin(a), 0) @ Rz(a + PI / 2)
        C.box(LP, -0.7, -0.3, z, 0.7, 0.3, z + 2.4, bevel=0.05, M=M)
    C.box(P.bm("Plank"), 6.5, -4.0, 0.0, 14.5, 4.0, 6.0, bevel=0.2)  # keeper's hut
    C.prism(P.bm("Thatch"), [(-5.2, 6.0), (0.0, 9.5), (5.2, 6.0), (5.2, 5.4), (0.0, 8.9), (-5.2, 5.4)], 5.8, 15.2,
            bevel=0.1, M=Rz(-PI / 2))
    C.box(WD, 6.3, -1.2, 0.0, 6.6, 1.2, 4.6, bevel=0.05)
    return P.done(col, man)


def watchtower(col, man, origin):
    """BC_Watchtower 8x8 x ~22H: four braced posts, platform with a plank rail, thatch roof, ladder, a flag."""
    P = C.Piece("BC_Watchtower", origin)
    WD, PL, TH = P.bm("WoodDark"), P.bm("Plank"), P.bm("Thatch")
    for x in (-3.4, 3.4):
        for y in (-3.4, 3.4):
            C.tube(WD, [(x * 1.2, y * 1.2, -0.5), (x, y, 20.0)], [0.45, 0.38], sides=8, v_tile=3.0)
    for z0, z1 in ((1.0, 8.0), (8.0, 14.0)):  # X braces on two sides
        for s in (-1, 1):
            C.tube(WD, [(-3.8, s * 3.9, z0), (3.8, s * 3.9, z1)], [0.22, 0.22], sides=6, v_tile=3.0)
            C.tube(WD, [(s * 3.9, -3.8, z1), (s * 3.9, 3.8, z0)], [0.22, 0.22], sides=6, v_tile=3.0)
    C.box(PL, -4.6, -4.6, 13.6, 4.6, 4.6, 14.3, bevel=0.1)
    for s in (-1, 1):
        C.box(PL, -4.6, s * 4.4 - 0.15, 14.3, 4.6, s * 4.4 + 0.15, 16.4, bevel=0.06)
        C.box(PL, s * 4.4 - 0.15, -4.25, 14.3, s * 4.4 + 0.15, 4.25, 16.4, bevel=0.06)
    C.lathe(TH, C.round_profile([(0.0, 19.8), (6.4, 19.8), (6.2, 20.4), (0.0, 25.0)], 0.3), 4, phase=PI / 4)
    for i in range(10):  # ladder on the front
        C.tube(WD, [(-1.0, -4.6, 1.2 + i * 1.3), (1.0, -4.6, 1.2 + i * 1.3)], [0.12, 0.12], sides=5, v_tile=2.0)
    for x in (-1.1, 1.1):
        C.tube(WD, [(x, -4.7, 0.0), (x, -4.7, 14.0)], [0.16, 0.16], sides=6, v_tile=3.0)
    C.drum(WD, (3.6, 3.6), 20.0, 6.0, 0.15, sides=6, bevel=0.0)
    C.flag_card(P.bm("Flag"), (3.75, 3.6, 25.8), 3.4, 2.2)
    P.smooth["Flag"] = 80.0
    return P.done(col, man)


def well(col, man, origin):
    P = C.Piece("BC_Well", origin)
    ST, WD, RP = P.bm("Stone"), P.bm("WoodDark"), P.bm("Rope")
    P.uv_scale["Stone"] = 4.0
    C.lathe(ST, C.round_profile([(2.4, 0.0), (3.4, 0.0), (3.4, 3.0), (2.4, 3.0), (2.4, 0.4)], 0.2), 20, cap=False)
    C.drum(P.bm("Void"), (0, 0), 0.4, 1.8, 2.45, sides=20, bevel=0.0)  # dark water far down the shaft
    for x in (-3.0, 3.0):
        C.box(WD, x - 0.3, -0.3, 2.6, x + 0.3, 0.3, 8.0, bevel=0.08)
    C.tube(WD, [(-3.2, 0, 6.6), (3.2, 0, 6.6)], [0.3, 0.3], sides=8, v_tile=2.0)
    C.drum(RP, (0, 0), -0.9, 1.8, 0.45, sides=10, bevel=0.05, M=T(0, 0, 6.6) @ Matrix.Rotation(PI / 2, 4, "Y"))
    C.tube(RP, [(0, 0.3, 6.2), (0, 0.3, 4.4)], [0.07, 0.07], sides=5, v_tile=1.0)
    C.lathe(WD, C.round_profile([(0.0, 3.2), (0.7, 3.2), (0.85, 4.3), (0.0, 4.3)], 0.08), 10, center=(0, 0.3, 0.0))
    C.prism(P.bm("Shingle"), [(-3.6, 7.6), (0.0, 10.2), (3.6, 7.6), (3.6, 7.0), (0.0, 9.6), (-3.6, 7.0)], -3.6, 3.6,
            bevel=0.1)
    return P.done(col, man)


def signpost(col, man, origin):
    P = C.Piece("BC_Signpost", origin)
    WD, PL = P.bm("WoodDark"), P.bm("Plank")
    C.drum(WD, (0, 0), 0.0, 9.0, 0.3, sides=8, bevel=0.05)
    for z, a, L in ((7.8, 0.2, 4.0), (6.6, 2.4, 3.6), (5.4, -1.3, 3.2)):
        M = T(0, 0, z) @ Rz(a)
        C.prism(PL, [(0.3, -0.5), (L, -0.5), (L + 0.8, 0.0), (L, 0.5), (0.3, 0.5)], -0.12, 0.12, bevel=0.04, M=M)
    C.lathe(WD, [(0.0, 9.0), (0.45, 9.0), (0.0, 9.6)], 8)
    return P.done(col, man)


def table_set(col, man, origin):
    """BC_TableSet: rough plank table, two benches, a rum bottle, mugs and a candle."""
    P = C.Piece("BC_TableSet", origin)
    PL, WD = P.bm("Plank"), P.bm("WoodDark")
    C.box(PL, -3.0, -1.4, 2.6, 3.0, 1.4, 3.1, bevel=0.08)
    for x in (-2.4, 2.4):
        C.box(WD, x - 0.25, -1.0, 0.0, x + 0.25, 1.0, 2.6, bevel=0.06)
    for y in (-2.6, 2.6):
        C.box(PL, -2.8, y - 0.55, 1.4, 2.8, y + 0.55, 1.75, bevel=0.06)
        for x in (-2.2, 2.2):
            C.box(WD, x - 0.2, y - 0.4, 0.0, x + 0.2, y + 0.4, 1.4, bevel=0.04)
    C.lathe(P.bm("Iron"), C.round_profile([(0.0, 3.1), (0.45, 3.1), (0.5, 4.1), (0.18, 4.6), (0.16, 5.2), (0.0, 5.2)],
                                          0.06), 10, center=(-1.2, 0.2, 0.0))
    for x, y in ((0.6, -0.5), (1.8, 0.4)):
        C.lathe(WD, [(0.0, 3.1), (0.4, 3.1), (0.42, 4.0), (0.0, 4.0)], 10, center=(x, y, 0.0), cap=True)
    C.drum(P.bm("Bone"), (-2.2, -0.6), 3.1, 0.9, 0.18, sides=8, bevel=0.03)
    egg(P.bm("Lamp"), (-2.2, -0.6, 4.25), 0.22, 8)
    return P.done(col, man)


def bench(col, man, origin):
    P = C.Piece("BC_Bench", origin)
    C.box(P.bm("Plank"), -3.0, -0.7, 1.5, 3.0, 0.7, 1.9, bevel=0.06)
    C.box(P.bm("Plank"), -3.0, 0.5, 2.6, 3.0, 0.8, 4.0, bevel=0.06)
    for x in (-2.5, 2.5):
        C.box(P.bm("WoodDark"), x - 0.2, -0.5, 0.0, x + 0.2, 0.5, 1.5, bevel=0.04)
        C.box(P.bm("WoodDark"), x - 0.2, 0.6, 1.5, x + 0.2, 0.7, 4.2, bevel=0.03)
    return P.done(col, man)


def cutlass(bm_blade, bm_gold, bm_grip, M):
    """A curved cutlass standing point-up in local Z (blade 3.6, basket guard, grip)."""
    pts = [(0.0, 0.0), (0.42, 0.0)] + [(0.42 + 0.25 * t * t, 3.4 * t) for t in np.linspace(0.2, 1.0, 5)] + \
          [(0.55, 3.75), (0.0, 3.4)]
    C.prism(bm_blade, [(x - 0.2, z + 1.4) for x, z in pts], -0.05, 0.05, bevel=0.0, M=M)
    C.torus(bm_gold, (0.0, 0.0, 1.25), 0.5, 0.08, seg=16, sides=6, axis="Y", M=M)
    C.box(bm_gold, -0.6, -0.12, 1.25, 0.6, 0.12, 1.45, bevel=0.03, M=M)
    C.drum(bm_grip, (0.0, 0.0), 0.0, 1.25, 0.14, sides=8, bevel=0.03, M=M)
    C.lathe(bm_gold, [(0.0, -0.3), (0.22, -0.15), (0.0, 0.05)], 8, M=M)


def weapon_rack(col, man, origin):
    """BC_WeaponRack: A-frame rack with three cutlasses, a boarding axe and a flintlock musket."""
    P = C.Piece("BC_WeaponRack", origin)
    WD, IR, G = P.bm("WoodDark"), P.bm("Iron"), P.bm("Gold")
    for x in (-3.0, 3.0):
        C.box(WD, x - 0.25, -0.25, 0.0, x + 0.25, 0.25, 5.0, bevel=0.06)
        C.tube(WD, [(x, -1.4, 0.0), (x, -0.2, 3.6)], [0.18, 0.18], sides=6, v_tile=2.0)
    C.box(WD, -3.4, -0.35, 4.6, 3.4, 0.35, 5.2, bevel=0.06)
    C.box(WD, -3.4, -0.9, 0.8, 3.4, -0.3, 1.2, bevel=0.06)
    for i, x in enumerate((-2.0, -0.7, 0.6)):
        cutlass(IR, G, WD, T(x, -0.6, 1.1) @ Matrix.Rotation(-0.12, 4, "X") @ Rz(0.1 * i))
    # boarding axe
    C.tube(WD, [(1.8, -0.6, 1.1), (1.9, -0.4, 5.4)], [0.13, 0.13], sides=6, v_tile=2.0)
    C.prism(IR, [(0.0, 0.0), (1.1, -0.5), (1.3, 0.7), (0.0, 0.5)], -0.06, 0.06, bevel=0.0, M=T(1.95, -0.42, 4.6))
    # musket
    C.tube(IR, [(2.6, -0.5, 2.0), (2.75, -0.35, 5.8)], [0.1, 0.1], sides=6, v_tile=2.0)
    C.prism(WD, [(0.0, 0.0), (0.5, 0.0), (0.35, 2.0), (0.05, 2.0)], -0.15, 0.15, bevel=0.03,
            M=T(2.35, -0.55, 0.9))
    return P.done(col, man)


def cannonball_pile(col, man, origin):
    P = C.Piece("BC_CannonballPile", origin)
    IR = P.bm("Iron")
    r = 0.55
    z = r
    for layer, n in enumerate((4, 3, 2, 1)):
        for i in range(n):
            for j in range(n):
                egg(IR, ((i - (n - 1) / 2) * 2 * r, (j - (n - 1) / 2) * 2 * r, z), r, 10)
        z += r * 1.41
    return P.done(col, man)


def anchor(col, man, origin):
    """BC_Anchor ~9H: big iron anchor leaning on a rock, ring + rope."""
    P = C.Piece("BC_Anchor", origin)
    IR = P.bm("Iron")
    M = T(0, 0, 0.0) @ Matrix.Rotation(0.35, 4, "X")
    C.tube(IR, [(0, 0, 1.0), (0, 0, 8.4)], [0.4, 0.34], sides=10, v_tile=3.0, M=M)
    C.tube(IR, [(-2.6, 0, 7.2), (2.6, 0, 7.2)], [0.28, 0.28], sides=8, v_tile=3.0, M=M)  # stock
    arm = [(-3.4, 0, 3.6), (-3.2, 0, 2.2), (-2.4, 0, 1.2), (-1.2, 0, 0.6), (0, 0, 0.5), (1.2, 0, 0.6), (2.4, 0, 1.2),
           (3.2, 0, 2.2), (3.4, 0, 3.6)]
    C.tube(IR, arm, [0.3] * len(arm), sides=8, v_tile=3.0, M=M)
    for s in (-1, 1):
        C.prism(IR, [(0.0, 0.0), (0.9, -0.4), (0.3, 1.4)], -0.18, 0.18, bevel=0.03,
                M=M @ T(s * 3.4, 0, 3.4) @ Rz(0 if s > 0 else PI))
    C.torus(IR, (0, 0, 9.0), 0.75, 0.16, seg=16, sides=6, axis="Y", M=M)
    C.hull_rock(P.bm("Rock"), (0, 3.2, 1.0), (2.6, 2.2, 2.4), C.rng(9), n=16)
    return P.done(col, man)


def rope_coil(col, man, origin):
    P = C.Piece("BC_RopeCoil", origin)
    for k in range(4):
        C.torus(P.bm("Rope"), (0, 0, 0.25 + k * 0.42), 1.3 - 0.08 * k, 0.22, seg=24, sides=8)
    return P.done(col, man)


def campfire(col, man, origin):
    """BC_Campfire: stone ring, crossed logs, glowing flame cones, a spit with a pot (smoke/fire VFX in Studio)."""
    P = C.Piece("BC_Campfire", origin)
    r = C.rng(11)
    for x, y, a in C.polar(9, 2.2):
        C.hull_rock(P.bm("Rock"), (x, y, 0.2), (0.75, 0.6, 0.55), r, n=12)
    for a in (0.3, 1.4, 2.5):
        C.tube(P.bm("WoodDark"), [(1.6 * math.cos(a), 1.6 * math.sin(a), 0.2), (-1.6 * math.cos(a), -1.6 * math.sin(a),
                                                                               0.9)], [0.25, 0.22], sides=7, v_tile=2.0)
    for (x, y, h, rr) in ((0, 0, 2.6, 0.75), (0.5, 0.3, 1.8, 0.5), (-0.5, -0.2, 2.0, 0.55)):
        C.lathe(P.bm("Lamp"), [(0.0, 0.5), (rr, 0.7), (rr * 0.5, 0.5 + h * 0.6), (0.0, 0.5 + h)], 7, center=(x, y, 0))
    for s in (-1, 1):
        C.tube(P.bm("WoodDark"), [(s * 2.6, 0, 0.0), (s * 2.4, 0, 3.4)], [0.14, 0.14], sides=5, v_tile=2.0)
    C.tube(P.bm("WoodDark"), [(-2.7, 0, 3.3), (2.7, 0, 3.3)], [0.1, 0.1], sides=5, v_tile=2.0)
    return P.done(col, man)


def tent(col, man, origin):
    """BC_Tent 7W x 9D x 5.5H: canvas A-frame tent on poles, guy ropes, open front flap."""
    P = C.Piece("BC_Tent", origin)
    CV, WD, RP = P.bm("Canvas"), P.bm("WoodDark"), P.bm("Rope")
    for s in (-1, 1):  # the two roof slopes (thin slabs), ridge along Y
        C.prism(CV, [(0.0, 0.0), (3.5 * s, -5.2), (3.5 * s + 0.12 * s, -5.1), (0.12 * s, 0.1)], -4.5, 4.5,
                bevel=0.0, M=T(0, 0, 5.4))
    C.prism(CV, [(-3.4, 0.2), (0.0, 5.2), (3.4, 0.2)], 4.3, 4.45, bevel=0.0)  # closed back wall
    for y in (-4.6, 4.6):
        C.drum(WD, (0, y), 0.0, 5.8, 0.14, sides=6, bevel=0.0)
    C.tube(WD, [(0, -4.8, 5.5), (0, 4.8, 5.5)], [0.12, 0.12], sides=6, v_tile=2.0)
    for s in (-1, 1):
        C.tube(RP, [(0, s * 4.7, 5.6), (0, s * 7.4, 0.0)], [0.05, 0.05], sides=4, v_tile=1.0)
    return P.done(col, man)


def laundry_line(col, man, origin):
    """BC_LaundryLine 14 long: two posts, a sagging rope, shirts and cloths drying (canvas / striped)."""
    P = C.Piece("BC_LaundryLine", origin)
    for x in (-7.0, 7.0):
        C.drum(P.bm("WoodDark"), (x, 0), 0.0, 8.0, 0.22, sides=7, bevel=0.04)
    pts = [(x, 0, 7.6 - 0.9 * (1 - (x / 7.0) ** 2)) for x in np.linspace(-7, 7, 11)]
    C.tube(P.bm("Rope"), pts, [0.06] * 11, sides=5, v_tile=1.0)
    r = C.rng(15)
    for i, x in enumerate(np.linspace(-5.2, 5.0, 5)):
        z = 7.6 - 0.9 * (1 - (x / 7.0) ** 2)
        mat = ("Canvas", "AwningRed", "Canvas", "AwningTeal", "Canvas")[i]
        w, h = r.uniform(1.4, 2.0), r.uniform(1.8, 2.8)
        C.prism(P.bm(mat), [(-w / 2, 0.0), (w / 2, 0.0), (w / 2 * 0.9, -h), (-w / 2 * 0.9, -h)], -0.04, 0.04,
                bevel=0.0, M=T(x, 0, z - 0.05) @ Rz(r.uniform(-0.15, 0.15)))
    P.smooth.update({"Canvas": 80.0, "AwningRed": 80.0, "AwningTeal": 80.0})
    return P.done(col, man)


def dock(col, man, origin):
    """BC_Dock 6W x 18L: small islet jetty (deck top +0.2, piles to -12), a bollard and a lantern post at the end."""
    P = C.Piece("BC_Dock", origin)
    PL, WD = P.bm("Plank"), P.bm("WoodDark")
    r = C.rng(21)
    for i in range(18):
        y0 = -9 + i + 0.04
        dz = r.uniform(-0.05, 0.04)
        C.box(PL, -3.0 + r.uniform(-0.1, 0.1), y0, -0.25 + dz, 3.0 + r.uniform(-0.1, 0.1), y0 + 0.92, 0.2 + dz, bevel=0.06)
    for x in (-2.6, 2.6):
        C.box(WD, x - 0.35, -9.0, -1.2, x + 0.35, 9.0, -0.25, bevel=0.08)
        for y in (-8.0, 0.0, 8.0):
            C.drum(WD, (x, y), -12.0, 13.2, 0.42, sides=8, bevel=0.1)
    C.drum(WD, (2.2, -8.2), 0.2, 1.6, 0.4, sides=8, bevel=0.1)
    C.torus(P.bm("Rope"), (2.2, -8.2, 1.2), 0.5, 0.12, seg=14, sides=5)
    C.drum(WD, (-2.4, -8.4), 0.2, 7.0, 0.22, sides=7, bevel=0.03)
    C.lathe(P.bm("Lamp"), [(0.0, 5.6), (0.5, 5.7), (0.55, 6.6), (0.0, 7.0)], 8, center=(-2.4, -8.4, 0.0))
    return P.done(col, man)


def market_cart(col, man, origin):
    """BC_MarketCart: two-wheeled wooden cart heaped with fruit + a barrel, handles resting on the ground."""
    P = C.Piece("BC_MarketCart", origin)
    PL, WD = P.bm("Plank"), P.bm("WoodDark")
    M = T(0, 0, 0) @ Matrix.Rotation(-0.12, 4, "X")
    C.box(PL, -2.2, -3.0, 1.9, 2.2, 3.0, 2.4, bevel=0.08, M=M)
    for s in (-1, 1):
        C.box(PL, s * 2.2 - 0.15, -3.0, 2.4, s * 2.2 + 0.15, 3.0, 3.6, bevel=0.05, M=M)
    C.box(PL, -2.05, 2.85, 2.4, 2.05, 3.15, 3.6, bevel=0.05, M=M)
    for s in (-1, 1):
        C.drum(WD, (0, 0), -0.25, 0.5, 1.6, sides=16, bevel=0.1, M=T(s * 2.65, 0.6, 1.6) @ Matrix.Rotation(PI / 2, 4, "Y"))
        C.tube(WD, [(s * 1.6, -3.0, 2.0), (s * 1.6, -7.0, 0.2)], [0.18, 0.15], sides=6, v_tile=2.0)
    C.tube(WD, [(-3.05, 0.6, 1.6), (3.05, 0.6, 1.6)], [0.18, 0.18], sides=6, v_tile=2.0)
    r = C.rng(31)
    for _ in range(14):
        egg(P.bm("Petal") if r.random() < 0.5 else P.bm("Gold"),
            (r.uniform(-1.6, 1.6), r.uniform(-2.2, 2.2), 2.9 + r.uniform(0, 0.8)), r.uniform(0.4, 0.55), 8)
    return P.done(col, man)


def footbridge(col, man, origin):
    """BC_Footbridge 6W x 22L: arched plank bridge with rope rails (decor over the beach channels). Ends at z 0."""
    P = C.Piece("BC_Footbridge", origin)
    PL, WD, RP = P.bm("Plank"), P.bm("WoodDark"), P.bm("Rope")
    n = 22
    for i in range(n):
        y0 = -11.0 + i
        z = 2.2 * math.sin(PI * (i + 0.5) / n)
        C.box(PL, -3.0, y0 + 0.04, z - 0.35, 3.0, y0 + 0.96, z + 0.1, bevel=0.05)
    for s in (-1, 1):
        beam = [(s * 2.4, y, 2.2 * math.sin(PI * (y + 11.0) / 22.0) - 0.7) for y in np.linspace(-11, 11, 12)]
        C.tube(WD, beam, [0.3] * 12, sides=6, v_tile=3.0)
        posts = np.linspace(-10.5, 10.5, 6)
        for y in posts:
            z = 2.2 * math.sin(PI * (y + 11.0) / 22.0)
            C.drum(WD, (s * 3.0, y), z - 1.0, 4.0, 0.22, sides=7, bevel=0.04)
        rail = [(s * 3.0, y, 2.2 * math.sin(PI * (y + 11.0) / 22.0) + 2.6) for y in np.linspace(-10.5, 10.5, 12)]
        C.tube(RP, rail, [0.09] * 12, sides=5, v_tile=1.0)
    return P.done(col, man)


def chest(col, man, origin):
    """BC_Chest: closed treasure chest -- dark wood, gold bands + lock, a few coins spilling out."""
    P = C.Piece("BC_Chest", origin)
    WD, G = P.bm("WoodDark"), P.bm("Gold")
    C.box(WD, -1.8, -1.2, 0.0, 1.8, 1.2, 1.9, bevel=0.12)
    C.drum(WD, (0, 0), -1.7, 3.4, 1.2, sides=14, bevel=0.1, M=T(0, 0, 1.9) @ Matrix.Rotation(PI / 2, 4, "Y"))
    for x in (-1.25, 1.25):
        C.box(G, x - 0.18, -1.32, 0.2, x + 0.18, 1.32, 1.78, bevel=0.04)
        C.torus(G, (x, 0, 1.9), 1.32, 0.12, seg=20, sides=6, axis="X")
    C.box(G, -0.35, -1.42, 1.3, 0.35, -1.2, 2.2, bevel=0.06)
    r = C.rng(41)
    for _ in range(6):
        a, d = r.uniform(-1.2, 1.2) - PI / 2, r.uniform(1.6, 2.6)
        C.drum(G, (d * math.cos(a), d * math.sin(a)), 0.0, 0.16, 0.42, sides=10, bevel=0.03)
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitW")
    man = {}
    row = C.Row(gap=8.0)
    tavern(col, man, row.next(32))
    lighthouse(col, man, row.next(30))
    watchtower(col, man, row.next(12))
    well(col, man, row.next(8))
    signpost(col, man, row.next(8))
    table_set(col, man, row.next(7))
    bench(col, man, row.next(7))
    weapon_rack(col, man, row.next(8))
    cannonball_pile(col, man, row.next(5))
    anchor(col, man, row.next(8))
    rope_coil(col, man, row.next(3))
    campfire(col, man, row.next(6))
    tent(col, man, row.next(8))
    laundry_line(col, man, row.next(15))
    dock(col, man, row.next(7))
    market_cart(col, man, row.next(7))
    footbridge(col, man, row.next(7))
    chest(col, man, row.next(5))
    C.write_manifest("W", man)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
