# Bakunawa Cove -- Kit L: landmarks (B173). Rules: tools/maps/lobby/README.md (split by material, origin
# bottom-centre, FRONT -Y, row along +X, C.zfight_report = 0).
# Pieces: BC_FortTower, BC_FortWall, BC_FortKeep (gate),
#         (Skull Rock moved to kit_skull.py, Kit S) BC_Treasure, BC_Shipwreck, BC_SerpentBones (Bakunawa's spine + skull rising from the sea), BC_Waterfall
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


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def Rz(a):
    return Matrix.Rotation(a, 4, "Z")


def merlons(bm, pts, z0, h, size):
    for (x, y, a) in pts:
        C.block(bm, (x, y, z0 + h / 2), (size, size * 0.8, h), bevel=0.15, rot=(0, 0, a))


def fort_tower(col, man, origin):
    """BC_FortTower d13 x ~42H: battered stone drum, corbel ring, merlons, conical shingle roof, flag."""
    P = C.Piece("BC_FortTower", origin)
    ST, SH = P.bm("Stone"), P.bm("Shingle")
    P.uv_scale["Stone"] = 8.0
    C.drum(ST, (0, 0), 0.0, 27.0, 6.8, r_top=6.0, sides=24, bevel=0.3)
    C.drum(ST, (0, 0), 27.0, 1.6, 7.0, sides=24, bevel=0.25)  # corbel ring
    merlons(ST, [(6.4 * math.cos(a), 6.4 * math.sin(a), a) for a in np.linspace(0, 2 * math.pi, 12, endpoint=False)],
            28.6, 2.0, 1.7)
    C.lathe(SH, C.round_profile([(0.0, 29.2), (7.8, 29.2), (7.6, 29.9), (3.2, 36.5), (0.0, 42.0)], 0.4), 24)
    C.drum(P.bm("WoodDark"), (0, 0), 41.0, 6.0, 0.25, sides=8, bevel=0.05)
    C.flag_card(P.bm("Flag"), (0.2, 0.0, 46.6), 5.0, 3.2)
    for a in (-math.pi / 2, -math.pi / 2 + 1.1, -math.pi / 2 - 1.1, math.pi / 2):  # lit slit windows
        for z in (9.0, 18.0):
            r = 6.8 - (6.8 - 6.0) * (z + 1.5) / 27.0 + 0.05
            M = T(r * math.cos(a), r * math.sin(a), 0) @ Rz(a + math.pi / 2)
            C.box(P.bm("Lamp"), -0.6, -0.3, z, 0.6, 0.3, z + 3.0, bevel=0.05, M=M)
            C.box(P.bm("WoodDark"), -0.95, -0.42, z - 0.35, 0.95, 0.42, z, bevel=0.05, M=M)
    P.smooth["Flag"] = 80.0
    return P.done(col, man)


def fort_wall(col, man, origin):
    """BC_FortWall 24L (X) x 5D x ~17H curtain wall with a walkway and front merlons (tiles along X)."""
    P = C.Piece("BC_FortWall", origin)
    ST = P.bm("Stone")
    P.uv_scale["Stone"] = 8.0
    C.box(ST, -12.0, -2.5, 0.0, 12.0, 2.5, 14.0, bevel=0.3)
    C.box(ST, -11.8, -2.9, 0.0, 11.8, 2.9, 2.0, bevel=0.3)  # plinth (ends kept off the wall ends)
    C.box(ST, -11.9, -2.85, 13.6, 11.9, -1.6, 15.2, bevel=0.2)  # parapet
    merlons(ST, [(x, -2.25, 0.0) for x in np.linspace(-10.5, 10.5, 8)], 15.2, 2.0, 1.6)
    C.box(P.bm("Plank"), -11.95, -1.6, 14.0, 11.95, 2.3, 14.4, bevel=0.06)  # walkway boards
    return P.done(col, man)


def gable(bm, hx, hy, z0, rise, over=1.4, thick=0.7):
    pts = [(-hy - over, z0), (0.0, z0 + rise), (hy + over, z0), (hy + over, z0 - thick),
           (0.0, z0 + rise - thick * 1.4), (-hy - over, z0 - thick)]
    return C.prism(bm, pts, -hx - over, hx + over, bevel=0.2, M=Rz(-math.pi / 2))


def fort_keep(col, man, origin):
    """BC_FortKeep 30W x 22D x ~38H: stone hall, arched gate with a wooden door, lit windows, steep shingle roof,
    corner turrets with cone roofs."""
    P = C.Piece("BC_FortKeep", origin)
    ST, SH, WD = P.bm("Stone"), P.bm("Shingle"), P.bm("WoodDark")
    P.uv_scale["Stone"] = 8.0
    hx, hy = 15.0, 11.0
    C.arch_wall(ST, 2 * hx, 22.0, 1.6, 8.0, 7.5, kind="round", bevel=0.25, n=14, M=T(0, -hy + 0.8, 0.0))
    C.box(ST, -hx, -hy + 1.6, 0.0, hx, hy, 22.0, bevel=0.3)
    C.box(WD, -4.2, -hy + 1.35, 0.0, 4.2, -hy + 1.75, 11.4, bevel=0.06)  # gate leaves in the arch
    for x in (-4.0, 0.0, 4.0):
        C.box(P.bm("Iron"), x - 0.15, -hy + 1.15, 0.5, x + 0.15, -hy + 1.4, 11.0, bevel=0.03)
    C.box(ST, -hx - 0.4, -hy - 0.4, 21.6, hx + 0.4, hy + 0.4, 23.0, bevel=0.25)  # cornice
    gable(SH, hx, hy, 23.0, 13.0, over=1.6, thick=0.9)
    C.prism(ST, [(-hy, 23.0), (0.0, 23.0 + 12.2), (hy, 23.0)], -hx + 0.4, hx - 0.4, bevel=0.1, M=Rz(-math.pi / 2))
    for x in (-10.0, 10.0):
        for z in (6.0, 14.5):
            C.box(P.bm("Lamp"), x - 1.0, -hy - 0.25, z, x + 1.0, -hy + 0.3, z + 3.6, bevel=0.05)
            C.box(WD, x - 1.4, -hy - 0.45, z - 0.4, x + 1.4, -hy + 0.2, z, bevel=0.05)
            C.box(WD, x - 1.4, -hy - 0.45, z + 3.6, x + 1.4, -hy + 0.2, z + 4.0, bevel=0.05)
    for sx in (-1, 1):  # corner turrets
        cx, cy = sx * (hx + 1.0), -hy - 1.0
        C.drum(ST, (cx, cy), 0.0, 28.0, 3.6, r_top=3.2, sides=16, bevel=0.2)
        C.drum(ST, (cx, cy), 28.0, 1.0, 3.8, sides=16, bevel=0.2)
        C.lathe(SH, C.round_profile([(0.0, 28.9), (4.6, 28.9), (4.4, 29.5), (0.0, 38.0)], 0.3), 16,
                center=(cx, cy, 0.0))
        C.drum(WD, (cx, cy), 37.0, 4.5, 0.2, sides=6, bevel=0.03)
        C.flag_card(P.bm("Flag"), (cx + 0.15, cy, 41.3), 3.6, 2.4)
    P.smooth["Flag"] = 80.0
    return P.done(col, man)


def treasure(col, man, origin):
    """BC_Treasure ~12W: gold coin mound, two open chests, a scatter of coins."""
    P = C.Piece("BC_Treasure", origin)
    G, WD = P.bm("Gold"), P.bm("WoodDark")
    C.lathe(G, C.round_profile([(0.0, -0.3), (6.0, -0.3), (4.6, 1.2), (2.2, 2.8), (0.0, 3.3)], 0.5), 20)
    for sx, yaw in ((-4.2, 0.4), (4.4, -0.5)):
        M = T(sx, 1.0, 0.0) @ Rz(yaw)
        C.box(WD, -2.0, -1.3, 0.0, 2.0, 1.3, 2.4, bevel=0.15, M=M)
        C.lathe(G, [(0.0, 0.0), (1.6, 0.0), (1.4, 0.5), (0.0, 0.7)], 12, M=M @ T(0, 0, 2.0))  # spilling gold
        C.drum(WD, (0, 0), -2.0, 4.0, 1.3, sides=12, bevel=0.1,
               M=M @ T(0, 1.3, 2.4) @ Matrix.Rotation(-1.2, 4, "X") @ T(0, -1.3, 0) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
        for x in (-1.6, 1.6):
            C.box(G, x - 0.2, -1.42, 0.15, x + 0.2, 1.42, 2.5, bevel=0.05, M=M)
    r = C.rng(5)
    for _ in range(14):
        a, d = r.uniform(0, 6.28), r.uniform(6.5, 9.0)
        C.drum(G, (d * math.cos(a), d * math.sin(a)), 0.0, 0.18, 0.5, sides=10, bevel=0.04)
    return P.done(col, man)


def shipwreck(col, man, origin):
    """BC_Shipwreck: a smaller hull keeled over ~24 deg, half buried in the sandbar, broken mast + torn sail,
    exposed ribs at the stern. Origin = the sand level."""
    P = C.Piece("BC_Shipwreck", origin)
    WD, PL = P.bm("WoodDark"), P.bm("Plank")
    M = T(0, 0, 1.0) @ Matrix.Rotation(math.radians(-24), 4, "X") @ Matrix.Rotation(math.radians(6), 4, "Y")
    C.ship_hull(WD, PL, 40.0, 13.0, 5.5, 4.0, stern_raise=2.5, bow_raise=1.5, N=18, M=M)
    for k, x in enumerate(np.linspace(-26.0, -20.5, 4)):  # bare U-ribs beyond the broken stern, some snapped short
        a0, a1 = (-1.7, 1.7) if k % 2 == 0 else (-1.7, 0.4 + 0.3 * k)
        rib = [(x, 6.0 * math.sin(a), 5.5 - 6.0 * math.cos(a)) for a in np.linspace(a0, a1, 9)]
        C.tube(WD, rib, [0.45] * 9, sides=6, v_tile=3.0, M=M)
    C.drum(WD, (0, 0), 3.5, 12.0, 0.7, r_top=0.45, sides=10, bevel=0.1,
           M=M @ T(2.0, 0, 0) @ Matrix.Rotation(0.35, 4, "X"))  # broken mast, leaning further
    C.sail(P.bm("Sail"), 0.0, -4.0, 3.0, 0.0, 6.0, belly=0.8, M=M @ T(1.9, 0.8, 9.0) @ Matrix.Rotation(0.5, 4, "X"))
    P.smooth["Sail"] = 80.0
    return P.done(col, man)


def serpent_bones(col, man, origin):
    """BC_SerpentBones ~80L: Bakunawa's bleached spine arching out of the sea in three humps (vertebrae with
    dorsal spikes and rib pairs) and its horned skull rising at the +X end. Origin = sea level (place at SEA_Z)."""
    P = C.Piece("BC_SerpentBones", origin)
    BN = P.bm("Bone")
    pts = []
    for t in np.linspace(0, 1, 120):
        x = -40.0 + 72.0 * t
        z = 13.0 * abs(math.sin(3 * math.pi * t)) * (0.7 + 0.3 * t) - 2.5
        y = 4.0 * math.sin(2 * math.pi * t)
        pts.append(Vector((x, y, z)))
    acc, last = 0.0, None
    for i in range(1, len(pts)):
        acc += (pts[i] - pts[i - 1]).length
        if acc < 2.6:
            continue
        acc = 0.0
        p = pts[i]
        if p.z < -1.5:
            continue
        d = (pts[min(i + 1, len(pts) - 1)] - pts[i - 1]).normalized()
        q = d.to_track_quat("Z", "Y").to_matrix().to_4x4()
        Mv = T(*p) @ q
        C.lathe(BN, C.round_profile([(0.0, -0.9), (1.2, -0.9), (1.5, 0.0), (1.2, 0.9), (0.0, 0.9)], 0.25), 10, M=Mv)
        up = Vector((0, 0, 1)) - d * d.z
        up.normalize()
        C.spike(BN, tuple(p + up * 1.2), tuple(p + up * 4.2), 0.55, sides=6)
        side = d.cross(up).normalized()
        if int(p.x) % 2 == 0 and p.z > 1.0:
            for s in (-1, 1):
                rib = [p + side * s * 1.2, p + side * s * 4.0 - up * 1.0, p + side * s * 4.6 - up * 4.0,
                       p + side * s * 3.4 - up * 6.5]
                C.tube(BN, [tuple(v) for v in rib], [0.45, 0.4, 0.35, 0.2], sides=6, v_tile=3.0)
    # skull at the +X end, rearing up out of the water
    hp = Vector((36.0, 0.0, 6.0))
    Mh = T(*hp) @ Matrix.Rotation(-0.35, 4, "Y")
    C.lathe(BN, C.round_profile([(0.0, -4.0), (3.4, -3.2), (4.2, 0.5), (3.0, 4.5), (1.6, 9.0), (0.0, 10.5)], 0.6), 14,
            M=Mh @ Matrix.Rotation(math.pi / 2, 4, "Y") @ Matrix.Diagonal((1.0, 0.85, 1.0, 1.0)))
    C.lathe(BN, C.round_profile([(0.0, -1.0), (2.6, -0.8), (2.0, 4.0), (0.8, 8.0), (0.0, 8.6)], 0.4), 12,
            M=Mh @ T(0.0, 0.0, -3.4) @ Matrix.Rotation(math.pi / 2 + 0.35, 4, "Y") @ Matrix.Diagonal((1.0, 0.8, 0.6, 1.0)))
    for s in (-1, 1):
        C.spike(BN, tuple(hp + Vector((-2.0, s * 2.4, 3.0))), tuple(hp + Vector((-9.0, s * 5.0, 9.0))), 0.9, sides=8)
        C.spike(BN, tuple(hp + Vector((5.5, s * 1.6, -0.6))), tuple(hp + Vector((6.2, s * 1.6, -3.4))), 0.45, sides=6)
        C.lathe(P.bm("Void"), [(0.0, -1.0)] + [(math.sin(t), -math.cos(t)) for t in np.linspace(0.3, math.pi - 0.3, 5)]
                + [(0.0, 1.0)], 10, M=T(*(hp + Vector((0.5, s * 3.2, 1.6)))) @ Matrix.Diagonal((1.2, 0.6, 0.9, 1.0)))
    return P.done(col, man)


def waterfall(col, man, origin):
    """BC_Waterfall 12W x ~46H: lip rocks at the top, a sheet that arcs out and falls (Falls, alpha -- scrolls in
    Studio), foam blobs at the foot. Origin = the foot (place on the beach/sea), top lip at z 44."""
    import bmesh
    P = C.Piece("BC_Waterfall", origin)
    H = 44.0
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    nu, nv = 6, 14
    V = []
    for j in range(nv + 1):
        t = j / nv
        z = H * (1 - t)
        y = -3.5 * math.sqrt(t) - 0.5 * t
        w = 6.0 + 2.5 * t
        V.append([tmp.verts.new((-w + 2 * w * i / nu, y, z)) for i in range(nu + 1)])
    for j in range(nv):
        for i in range(nu):
            f = tmp.faces.new((V[j][i], V[j + 1][i], V[j + 1][i + 1], V[j][i + 1]))
            for lp, c in zip(f.loops, [(i / nu, 1 - j / nv * 3), (i / nu, 1 - (j + 1) / nv * 3),
                                       ((i + 1) / nu, 1 - (j + 1) / nv * 3), ((i + 1) / nu, 1 - j / nv * 3)]):
                lp[uvl].uv = c
    C._append(P.bm("Falls"), tmp, None, uv=True)
    r = C.rng(17)
    for k in range(9):
        x = r.uniform(-8, 8)
        C.lathe(P.bm("Foam"), C.ellipse_profile(r.uniform(2.0, 3.5), r.uniform(1.6, 3.0), 0.0, 6),
                12, center=(x, -4.0 + r.uniform(-1.5, 1.5), -0.6))
    for k in range(4):
        C.hull_rock(P.bm("Rock"), (-7.5 + k * 5.0, 1.0, H - 1.0), (3.2, 3.0, 2.4), r)
    P.smooth["Falls"] = 80.0
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitL")
    man = {}
    row = C.Row(gap=14.0)
    fort_tower(col, man, row.next(16))
    fort_wall(col, man, row.next(24))
    fort_keep(col, man, row.next(40))
    treasure(col, man, row.next(18))
    shipwreck(col, man, row.next(46))
    serpent_bones(col, man, row.next(80))
    waterfall(col, man, row.next(20))
    C.write_manifest("L", man)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
