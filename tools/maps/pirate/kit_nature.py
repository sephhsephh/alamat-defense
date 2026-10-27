# Bakunawa Cove -- Kit N: nature (B173). Same rules as tools/maps/lobby/README.md: split by material
# (<Piece>__<Mat>), origin bottom-centre, front -Y, row along +X, C.zfight_report must be 0.
# Foliage is GEOMETRY (user reference B173: dense leafy clumps, no noisy grass texture): grass clumps, leafy bushes,
# flower patches use the smooth Blade gradient; palm fronds keep an alpha card.
# Pieces: BC_Palm1..3, BC_GrassClump, BC_GrassClumpBig, BC_FlowerPatch, BC_Bush, BC_BushBig, BC_Rock1..4, BC_SeaStack
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


def palm(col, man, name, origin, height, lean, fronds, seed):
    """Curved ringed trunk (Bark), drooping frond cards (Frond, alpha), coconuts (WoodDark)."""
    r = C.rng(seed)
    P = C.Piece(name, origin)
    pts = []
    for t in np.linspace(0, 1, 10):
        pts.append((lean * height * (0.6 * t * t + 0.15 * math.sin(t * 3.0)), 0.0, -1.5 + t * (height + 1.5)))
    radii = list(np.linspace(1.15, 0.6, 10))
    radii[0] = 1.5
    C.tube(P.bm("Bark"), pts, radii, sides=10, v_tile=3.0, cap=True)
    crown = Vector(pts[-1])
    C.drum(P.bm("Bark"), (crown.x, crown.y), crown.z - 0.6, 1.4, 0.75, r_top=0.35, sides=10, bevel=0.2)
    # coconuts
    for k in range(4):
        a = 2 * math.pi * k / 4 + 0.4
        c = crown + Vector((0.75 * math.cos(a), 0.75 * math.sin(a), -0.9))
        prof = [(0.0, -0.6)] + [(0.6 * math.cos(t), 0.6 * math.sin(t)) for t in np.linspace(-1.3, 1.3, 7)] + [(0.0, 0.6)]
        C.lathe(P.bm("WoodDark"), prof, 10, center=tuple(c))
    # fronds: each a bending strip of 6 segments, card UV u 0..1 across, v along (glTF top = rib base)
    import bmesh
    for i in range(fronds):
        tmp = bmesh.new()
        uvl = tmp.loops.layers.uv.new("UVMap")
        ang = 2 * math.pi * i / fronds + r.uniform(-0.2, 0.2)
        dirv = Vector((math.cos(ang), math.sin(ang), 0))
        side = Vector((-dirv.y, dirv.x, 0))
        L = r.uniform(0.42, 0.52) * height
        rise = r.uniform(0.1, 0.35) * L
        prev = None
        for s in range(7):
            t = s / 6
            p = crown + dirv * L * t + Vector((0, 0, rise * t - (rise + 0.38 * L) * t * t))
            w = 0.24 * L * math.sin(math.pi * min(0.98, t * 0.85 + 0.1))
            # slight V fold: the rib sits higher than the leaflet edges
            a = tmp.verts.new(p - side * w + Vector((0, 0, -0.12 * w)))
            m = tmp.verts.new(p)
            b = tmp.verts.new(p + side * w + Vector((0, 0, -0.12 * w)))
            if prev:
                for (q0, q1, n0, n1, u0, u1) in ((prev[0], prev[1], a, m, 0.0, 0.5), (prev[1], prev[2], m, b, 0.5, 1.0)):
                    f = tmp.faces.new((q0, q1, n1, n0))
                    v0, v1 = 1 - (s - 1) / 6, 1 - t
                    for lp, c in zip(f.loops, [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]):
                        lp[uvl].uv = c
            prev = (a, m, b)
        C._append(P.bm("Frond"), tmp, None, uv=True)
    P.smooth["Frond"] = 80.0
    return P.done(col, man)


def clump(col, man, name, origin, rad, height, blades, seed, flowers=0):
    """Dense grass / leaf clump: blades fanning out from a small base, tallest in the middle."""
    r = C.rng(seed)
    P = C.Piece(name, origin)
    B = P.bm("Blade")
    for i in range(blades):
        a = r.uniform(0, 2 * math.pi)
        d0 = r.uniform(0, rad * 0.45)
        base = (d0 * math.cos(a), d0 * math.sin(a), -0.15)
        tilt = r.uniform(0.35, 1.0)
        dirv = Vector((math.cos(a) * tilt, math.sin(a) * tilt, r.uniform(1.0, 1.6)))
        L = height * r.uniform(0.6, 1.1) * (1.15 - 0.5 * d0 / max(rad, 1e-3))
        C.leaf(B, base, dirv, L, r.uniform(0.22, 0.4) * height, int(r.integers(4)), bend=r.uniform(0.2, 0.45))
    for i in range(flowers):
        a = r.uniform(0, 2 * math.pi)
        d0 = r.uniform(0.2, 0.9) * rad
        z = height * r.uniform(0.55, 0.95)
        C.leaf(B, (d0 * 0.3 * math.cos(a), d0 * 0.3 * math.sin(a), -0.1),
               (math.cos(a) * d0 * 0.7, math.sin(a) * d0 * 0.7, z), math.hypot(d0 * 0.7, z), 0.12, 0, bend=0.0, segs=1)
        C.flower_head(P.bm("Petal"), (d0 * math.cos(a), d0 * math.sin(a), z), r.uniform(0.35, 0.55), int(r.integers(4)))
    P.smooth["Blade"] = 80.0
    return P.done(col, man)


def bush(col, man, name, origin, rad, height, leaves, seed, flowers=0):
    """Leafy bush (the reference's big-leaf shrubs): broad leaves on a dome, pointing outwards + up."""
    r = C.rng(seed)
    P = C.Piece(name, origin)
    B = P.bm("Blade")
    for i in range(leaves):
        a = r.uniform(0, 2 * math.pi)
        el = r.uniform(0.0, 1.35)
        n = Vector((math.cos(a) * math.cos(el), math.sin(a) * math.cos(el), math.sin(el)))
        base = Vector((n.x * rad * 0.45, n.y * rad * 0.45, height * 0.18 + n.z * height * 0.4))
        d = (n + Vector((0, 0, 0.5))).normalized()
        L = r.uniform(0.55, 0.8) * rad
        col_u = int(min(3, max(0, round(el / 1.35 * 3 + r.normal(0, 0.6)))))
        C.leaf(B, base, d, L, L * r.uniform(0.45, 0.6), col_u, bend=r.uniform(0.25, 0.5), segs=3)
    for i in range(flowers):
        a = r.uniform(0, 2 * math.pi)
        el = r.uniform(0.3, 1.2)
        p = (math.cos(a) * math.cos(el) * rad * 0.95, math.sin(a) * math.cos(el) * rad * 0.95,
             height * 0.2 + math.sin(el) * height * 0.75)
        C.flower_head(P.bm("Petal"), p, r.uniform(0.4, 0.6), int(r.integers(2)))
    P.smooth["Blade"] = 80.0
    return P.done(col, man)


def rock(col, man, name, origin, size, seed, n=22):
    P = C.Piece(name, origin)
    C.hull_rock(P.bm("Rock"), (0, 0, size[2] * 0.3), size, C.rng(seed), n=n)
    return P.done(col, man)


def sea_stack(col, man, origin):
    """Tall layered rock pillar for the sea (3 hulls stacked, narrowing) -- islet + harbour silhouettes."""
    P = C.Piece("BC_SeaStack", origin)
    r = C.rng(77)
    C.hull_rock(P.bm("Rock"), (0, 0, 10), (9, 8, 14), r, n=30)  # one leaning spire: two hulls overlapping heavily
    C.hull_rock(P.bm("Rock"), (1.2, 0.6, 22), (6, 5.5, 10), r, n=26)
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitN")
    man = {}
    row = C.Row(gap=10.0)
    palm(col, man, "BC_Palm1", row.next(20), 26.0, 0.18, 11, 1)
    palm(col, man, "BC_Palm2", row.next(20), 20.0, -0.28, 10, 2)
    palm(col, man, "BC_Palm3", row.next(24), 32.0, 0.1, 12, 3)
    clump(col, man, "BC_GrassClump", row.next(4), 1.6, 2.2, 34, 11)
    clump(col, man, "BC_GrassClumpBig", row.next(6), 2.6, 3.4, 60, 12)
    clump(col, man, "BC_FlowerPatch", row.next(6), 2.4, 2.4, 40, 13, flowers=9)
    bush(col, man, "BC_Bush", row.next(6), 3.0, 4.0, 46, 24)
    bush(col, man, "BC_BushBig", row.next(10), 5.0, 6.5, 80, 22, flowers=8)
    rock(col, man, "BC_Rock1", row.next(10), (5.0, 4.2, 4.0), 31)
    rock(col, man, "BC_Rock2", row.next(8), (3.6, 2.6, 5.5), 32)
    rock(col, man, "BC_Rock3", row.next(14), (7.0, 5.5, 3.0), 33)
    rock(col, man, "BC_Rock4", row.next(5), (2.0, 1.8, 1.6), 34, n=16)
    sea_stack(col, man, row.next(18))
    C.write_manifest("N", man)
    if globals().get("PREVIEW", True):
        C.kit_preview(col, "kitN", samples=16)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
