# Apolaki Sun Terraces -- prop / foliage prototypes (B166). Every prototype is authored at the origin
# (base on z = 0) and named PT_<Asset>__<part>; the Studio assembly groups parts by <Asset>.
# A part named PT_<Asset>__FX<n> is a VFX anchor (the Studio script turns it into an Attachment).
import importlib
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

importlib.reload(C)
np = C.np
R = C.rng(2026)

TILES = {0: (0.0, 0.5), 1: (0.5, 0.5), 2: (0.0, 0.0), 3: (0.5, 0.0)}  # atlas tile -> (u0, v0)


# ------------------------------------------------------------------ primitives
def tube(bm, uvl, pts, radii, sides=8, v_scale=8.0, cap=True, u_rep=2.0):
    """Tapered tube along a polyline (list of Vector). Returns the last ring."""
    rings = []
    length = 0.0
    for i, p in enumerate(pts):
        if i < len(pts) - 1:
            d = (pts[i + 1] - p).normalized()
        else:
            d = (p - pts[i - 1]).normalized()
        if i > 0:
            length += (p - pts[i - 1]).length
        a = Vector((1, 0, 0)) if abs(d.z) > 0.9 else Vector((0, 0, 1))
        u = d.cross(a).normalized()
        w = d.cross(u).normalized()
        ring = []
        for k in range(sides):
            th = 2 * math.pi * k / sides
            ring.append(bm.verts.new(p + (u * math.cos(th) + w * math.sin(th)) * radii[i]))
        rings.append((ring, length))
    for (r0, l0), (r1, l1) in zip(rings[:-1], rings[1:]):
        for k in range(sides):
            k2 = (k + 1) % sides
            f = bm.faces.new((r0[k], r0[k2], r1[k2], r1[k]))
            for loop, uv in zip(f.loops, [(k / sides * u_rep, l0 / v_scale), ((k + 1) / sides * u_rep, l0 / v_scale),
                                          ((k + 1) / sides * u_rep, l1 / v_scale), (k / sides * u_rep, l1 / v_scale)]):
                loop[uvl].uv = uv
    if cap:
        try:
            f = bm.faces.new(rings[-1][0])
            for loop in f.loops:
                loop[uvl].uv = (0.5, 0.5)
        except ValueError:
            pass
    return rings[-1][0]


def card(bm, uvl, center, normal, size, tile, spin=0.0, aspect=1.0):
    n = Vector(normal).normalized()
    a = Vector((0, 0, 1)) if abs(n.z) < 0.95 else Vector((1, 0, 0))
    u = n.cross(a).normalized()
    v = n.cross(u).normalized()
    rot = Matrix.Rotation(spin, 3, n)
    u, v = rot @ u, rot @ v
    hs = size / 2
    corners = [center - u * hs - v * hs * aspect, center + u * hs - v * hs * aspect,
               center + u * hs + v * hs * aspect, center - u * hs + v * hs * aspect]
    vs = [bm.verts.new(c) for c in corners]
    f = bm.faces.new(vs)
    u0, v0 = TILES[tile] if isinstance(tile, int) else tile
    for loop, uv in zip(f.loops, [(u0, v0), (u0 + 0.5, v0), (u0 + 0.5, v0 + 0.5), (u0, v0 + 0.5)]):
        loop[uvl].uv = uv
    return vs


def finish(name, bm, col, mats, custom_normals=None, smooth=True):
    ob = C.mesh_object(name, bm, col, mats)
    me = ob.data
    if smooth:
        for p in me.polygons:
            p.use_smooth = True
    if custom_normals is not None:
        normals = [custom_normals(ob, v) for v in me.vertices]
        me.normals_split_custom_set_from_vertices(normals)
    return ob


def clump_normals(centers):
    """Custom vertex normal = from the nearest clump centre (soft 'blob' shading)."""
    cs = [Vector(c) for c in centers]

    def fn(ob, v):
        p = v.co
        c = min(cs, key=lambda q: (q - p).length)
        n = (p - c)
        n.z += 0.35 * n.length  # bias up a little: canopies read lit from the sky
        return n.normalized()
    return fn


# ------------------------------------------------------------------ foliage
def foliage_clumps(bm, uvl, clumps, cards_per, card_size, height_range):
    zlo, zhi = height_range
    for (cx, cy, cz, rad) in clumps:
        c = Vector((cx, cy, cz))
        for _ in range(cards_per):
            d = Vector((R.normal(), R.normal(), R.normal() * 0.8)).normalized()
            p = c + d * rad * (0.35 + 0.65 * R.random() ** 0.5)
            hfrac = (p.z - zlo) / max(1e-3, zhi - zlo)
            # tone by height + facing the sun (+x, +z): darker underneath, sunlit on top
            lit = hfrac * 0.7 + max(0.0, d.x) * 0.25 + max(0.0, d.z) * 0.25 + R.normal(0, 0.12)
            tile = 0 if lit < 0.35 else 1 if lit < 0.6 else 2 if lit < 0.85 else 3
            nrm = d.lerp(Vector((R.normal(), R.normal(), R.normal())).normalized(), 0.6)
            card(bm, uvl, p, nrm, card_size * R.uniform(0.8, 1.25), tile, spin=R.uniform(0, 6.28))


def tree_broad(col, m_bark, m_leaf, name="PT_TreeBroad", height=21.0, spread=8.5, seed=0):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    # trunk with a lean and three limbs
    trunk = [Vector((0, 0, -0.6)), Vector((0.2, 0, 3)), Vector((0.6, 0.3, 7)), Vector((0.4, 0.2, 10.5))]
    tube(bm, uvl, trunk, [1.25, 0.95, 0.75, 0.62], sides=9)
    ends = []
    for i in range(3):
        ang = i * 2.1 + seed
        tip = Vector((math.cos(ang) * spread * 0.55, math.sin(ang) * spread * 0.55, height * 0.68 + R.uniform(-1, 1.5)))
        mid = (trunk[-1] + tip) / 2 + Vector((0, 0, 1.2))
        tube(bm, uvl, [trunk[-1], mid, tip], [0.6, 0.42, 0.25], sides=6)
        ends.append(tip)
    finish(name + "__Trunk", bm, col, [m_bark])
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    clumps = [(e.x, e.y, e.z + 1.5, 4.2) for e in ends]
    clumps += [(0.3, 0.2, height * 0.86, 5.0), (R.uniform(-2, 2), R.uniform(-2, 2), height * 0.62, 3.6)]
    for i in range(3):
        a = i * 2.1 + 1.0 + seed
        clumps.append((math.cos(a) * spread * 0.8, math.sin(a) * spread * 0.8, height * 0.6, 3.4))
    foliage_clumps(bm, uvl, clumps, 46, 5.2, (height * 0.45, height + 3))
    finish(name + "__Leaves", bm, col, [m_leaf], clump_normals([c[:3] for c in clumps]))


def tree_tall(col, m_bark, m_leaf, name="PT_TreeTall", height=30.0):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    trunk = [Vector((0, 0, -0.6)), Vector((0.3, 0, 6)), Vector((-0.2, 0.3, 13)), Vector((0.2, 0, 20)), Vector((0, 0, height * 0.86))]
    tube(bm, uvl, trunk, [1.1, 0.85, 0.65, 0.48, 0.3], sides=8)
    finish(name + "__Trunk", bm, col, [m_bark])
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    clumps = []
    for i in range(7):
        z = height * (0.45 + 0.08 * i)
        r = 4.6 - 0.45 * i
        a = i * 2.4
        clumps.append((math.cos(a) * 2.2, math.sin(a) * 2.2, z, max(2.2, r)))
    clumps.append((0, 0, height * 0.98, 2.6))
    foliage_clumps(bm, uvl, clumps, 34, 4.6, (height * 0.4, height + 2))
    finish(name + "__Leaves", bm, col, [m_leaf], clump_normals([c[:3] for c in clumps]))


def bush(col, m_leaf, name="PT_Bush", rad=2.4):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    clumps = [(0, 0, rad * 0.8, rad), (rad * 0.7, 0.3, rad * 0.6, rad * 0.7), (-rad * 0.6, -0.4, rad * 0.55, rad * 0.75)]
    foliage_clumps(bm, uvl, clumps, 30, rad * 1.25, (0, rad * 2))
    finish(name + "__Leaves", bm, col, [m_leaf], clump_normals([c[:3] for c in clumps]))


def palm(col, m_bark, m_frond, name="PT_Palm", height=19.0):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    pts = [Vector((0.6 * math.sin(t * 1.6) * t * 2.2, 0, t * height)) for t in np.linspace(0, 1, 9)]
    pts[0].z = -0.6
    top = tube(bm, uvl, pts, list(np.linspace(0.75, 0.42, 9)), sides=8, v_scale=3.0)
    finish(name + "__Trunk", bm, col, [m_bark])
    crown = pts[-1]
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for i in range(10):
        ang = 2 * math.pi * i / 10 + R.uniform(-0.15, 0.15)
        dirv = Vector((math.cos(ang), math.sin(ang), 0))
        side = Vector((-dirv.y, dirv.x, 0))
        L = R.uniform(7.0, 8.5)
        segs = 5
        prev = None
        for s in range(segs + 1):
            t = s / segs
            p = crown + dirv * L * t + Vector((0, 0, 1.6 * t - 4.2 * t * t))
            wdt = 1.9 * math.sin(math.pi * min(0.98, t * 0.85 + 0.1))
            a = bm.verts.new(p - side * wdt)
            b = bm.verts.new(p + side * wdt)
            if prev:
                f = bm.faces.new((prev[0], prev[1], b, a))
                for loop, uv in zip(f.loops, [(0, 1 - (s - 1) / segs), (1, 1 - (s - 1) / segs), (1, 1 - t), (0, 1 - t)]):
                    loop[uvl].uv = uv
            prev = (a, b)
    finish(name + "__Fronds", bm, col, [m_frond], lambda ob, v: (Vector(v.co) - crown + Vector((0, 0, 3))).normalized())


def bamboo(col, m_bamboo, m_leaf, name="PT_Bamboo"):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    tops = []
    for i in range(7):
        a = R.uniform(0, 6.28)
        r = R.uniform(0.3, 1.8)
        base = Vector((math.cos(a) * r, math.sin(a) * r, -0.5))
        h = R.uniform(14, 21)
        lean = Vector((math.cos(a), math.sin(a), 0)) * R.uniform(1.0, 3.0)
        pts = [base + lean * (t ** 2) + Vector((0, 0, h * t)) for t in np.linspace(0, 1, 6)]
        tube(bm, uvl, pts, [0.32] * 6, sides=6, v_scale=3.0, u_rep=1.0)
        tops.append(pts[-1])
    finish(name + "__Culms", bm, col, [m_bamboo])
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    clumps = [(t.x, t.y, t.z - 2.0, 2.4) for t in tops]
    foliage_clumps(bm, uvl, clumps, 16, 3.4, (8, 22))
    finish(name + "__Leaves", bm, col, [m_leaf], clump_normals([c[:3] for c in clumps]))


def crossed_cards(col, mat, name, w, h, count=3, tile=None):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for i in range(count):
        a = math.pi * i / count + R.uniform(-0.2, 0.2)
        d = Vector((math.cos(a), math.sin(a), 0))
        vs = [bm.verts.new(c) for c in (-d * w / 2, d * w / 2, d * w / 2 + Vector((0, 0, h)), -d * w / 2 + Vector((0, 0, h)))]
        f = bm.faces.new(vs)
        for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            loop[uvl].uv = uv
    finish(name, bm, col, [mat], lambda ob, v: Vector((0, 0, 1)))


def rock(col, mat, name, size, seed):
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=1.0)
    r = C.rng(seed)
    for v in bm.verts:
        n = v.co.normalized()
        k = 1 + 0.28 * (C.vnoise_xy(np.array([n.x * 2 + seed]), np.array([n.y * 2 + n.z]), 512, seed)[0] - 0.5) * 2
        v.co = Vector((n.x * size[0], n.y * size[1], max(n.z, -0.25) * size[2])) * k
    for v in bm.verts:
        if v.co.z < 0:
            v.co.z *= 0.3
    uvl = bm.loops.layers.uv.new("UVMap")
    zmax = max(v.co.z for v in bm.verts)
    for f in bm.faces:
        f.smooth = False
        for loop in f.loops:
            co = loop.vert.co
            loop[uvl].uv = (math.atan2(co.y, co.x) / math.pi + 1.0, co.z / max(zmax, 1e-3))
    finish(name, bm, col, [mat], smooth=False)


def box(bm, uvl, cx, cy, z0, sx, sy, sz, uvs=6.0):
    res = bmesh.ops.create_cube(bm, size=1.0)
    vs = res["verts"]
    for v in vs:
        v.co = Vector((cx + v.co.x * sx, cy + v.co.y * sy, z0 + (v.co.z + 0.5) * sz))
    faces = {f for v in vs for f in v.link_faces}
    for f in faces:
        n = f.normal
        for loop in f.loops:
            co = loop.vert.co
            if abs(n.z) > 0.5:
                loop[uvl].uv = (co.x / uvs, co.y / uvs)
            elif abs(n.x) > 0.5:
                loop[uvl].uv = (co.y / uvs, co.z / uvs)
            else:
                loop[uvl].uv = (co.x / uvs, co.z / uvs)


def cylinder(bm, uvl, cx, cy, z0, rad, h, sides=16, rad_top=None, uvs=6.0):
    rad_top = rad if rad_top is None else rad_top
    pts = [Vector((cx, cy, z0)), Vector((cx, cy, z0 + h))]
    tube(bm, uvl, pts, [rad, rad_top], sides=sides, v_scale=uvs, u_rep=max(1.0, 2 * math.pi * rad / uvs))
    # bottom cap is never seen; top cap added by tube


def disc_card(bm, uvl, center, normal, size):
    return card(bm, uvl, Vector(center), normal, size, (0.0, 0.0), spin=0.0) if False else _disc(bm, uvl, center, normal, size)


def _disc(bm, uvl, center, normal, size):
    n = Vector(normal).normalized()
    up = Vector((0, 0, 1))
    u = n.cross(up).normalized()
    v = up
    hs = size / 2
    c = Vector(center)
    vs = [bm.verts.new(c + u * x * hs + v * y * hs) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop[uvl].uv = uv


def fx_anchor(col, name, p):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.2)
    for v in bm.verts:
        v.co += Vector(p)
    C.mesh_object(name, bm, col, [])


def sun_gate(col, m_stone, m_gold, m_emblem):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for sy in (-5.2, 5.2):  # pillars either side of the path (gate faces +x along the path)
        box(bm, uvl, 0, sy, 0, 2.6, 2.6, 1.2)
        box(bm, uvl, 0, sy, 1.2, 2.0, 2.0, 9.6)
        box(bm, uvl, 0, sy, 10.8, 2.6, 2.6, 0.8)
    box(bm, uvl, 0, 0, 11.6, 2.4, 14.0, 1.4)   # lintel
    box(bm, uvl, 0, 0, 13.0, 1.6, 15.6, 0.7)   # cornice
    finish("PT_SunGate__Stone", bm, col, [m_stone], smooth=False)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    box(bm, uvl, 0, 0, 13.7, 1.2, 3.0, 0.9)  # gold mount the emblem stands on
    for sy in (-5.2, 5.2):
        box(bm, uvl, 0, sy, 10.5, 2.2, 2.2, 0.3)
    finish("PT_SunGate__Gold", bm, col, [m_gold], smooth=False)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    _disc(bm, uvl, (0, 0, 17.2), (1, 0, 0), 8.0)
    finish("PT_SunGate__Emblem", bm, col, [m_emblem], lambda ob, v: Vector((1, 0, 0.2)).normalized())
    fx_anchor(col, "PT_SunGate__FX1", (0, 0, 5.5))   # the portal between the pillars
    fx_anchor(col, "PT_SunGate__FX2", (0, 0, 17.2))  # the emblem glow


def shrine(col, m_stone, m_gold, m_emblem, m_cloth):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    cylinder(bm, uvl, 0, 0, -0.5, 9.5, 1.3, sides=28)
    cylinder(bm, uvl, 0, 0, 0.8, 8.3, 1.0, sides=28)
    cylinder(bm, uvl, 0, 0, 1.8, 7.2, 0.8, sides=28)
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        x, y = math.cos(a) * 6.0, math.sin(a) * 6.0
        cylinder(bm, uvl, x, y, 2.6, 0.75, 9.5, sides=10)
        box(bm, uvl, x, y, 12.1, 2.0, 2.0, 0.7)
    cylinder(bm, uvl, 0, 0, 12.8, 7.2, 0.9, sides=28, rad_top=6.4)
    cylinder(bm, uvl, 0, 0, 2.6, 1.6, 3.4, sides=12, rad_top=1.2)  # pedestal
    finish("PT_Shrine__Stone", bm, col, [m_stone], smooth=False)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    cylinder(bm, uvl, 0, 0, 6.0, 1.3, 0.6, sides=16)
    cylinder(bm, uvl, 0, 0, 13.7, 5.0, 0.6, sides=24, rad_top=3.6)
    finish("PT_Shrine__Gold", bm, col, [m_gold], smooth=False)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    _disc(bm, uvl, (0, 0, 9.6), (-1, 0, 0), 7.0)   # faces the incoming path (-x)
    _disc(bm, uvl, (0, 0, 9.6), (1, 0, 0), 7.0)
    finish("PT_Shrine__Emblem", bm, col, [m_emblem], lambda ob, v: Vector((-1 if v.co.x <= 0 else 1, 0, 0.3)).normalized())
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        x, y = math.cos(a) * 6.0, math.sin(a) * 6.0
        n = Vector((x, y, 0)).normalized()
        c = Vector((x, y, 8.6)) + n * 0.8
        _disc_banner(bm, uvl, c, n)
    finish("PT_Shrine__Banners", bm, col, [m_cloth], lambda ob, v: Vector((v.co.x, v.co.y, 0)).normalized())
    fx_anchor(col, "PT_Shrine__FX1", (0, 0, 9.6))


def _disc_banner(bm, uvl, c, n, w=1.6, h=4.2):
    u = n.cross(Vector((0, 0, 1))).normalized()
    vs = [bm.verts.new(c + u * x * w / 2 + Vector((0, 0, z))) for x, z in ((-1, -h), (1, -h), (1, 0), (-1, 0))]
    f = bm.faces.new(vs)
    for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop[uvl].uv = uv


def hut(col, m_wood, m_thatch, m_bamboo):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for x in (-3.4, 3.4):
        for y in (-3.4, 3.4):
            box(bm, uvl, x, y, -0.5, 0.6, 0.6, 4.0)
    box(bm, uvl, 0, 0, 3.4, 8.2, 8.2, 0.5)  # floor
    for (x, y, sx, sy) in ((0, -3.6, 7.6, 0.3), (0, 3.6, 7.6, 0.3), (-3.6, 0, 0.3, 7.6), (3.6, 0.5, 0.3, 6.6)):
        box(bm, uvl, x, y, 3.9, sx, sy, 3.6)
    box(bm, uvl, 4.6, -2.2, 0.0, 2.0, 1.6, 0.25)  # ladder base step
    finish("PT_Hut__Wood", bm, col, [m_wood], smooth=False)
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    # steep hipped roof
    base = [Vector((-5.4, -5.4, 7.2)), Vector((5.4, -5.4, 7.2)), Vector((5.4, 5.4, 7.2)), Vector((-5.4, 5.4, 7.2))]
    ridge = [Vector((-1.6, 0, 12.5)), Vector((1.6, 0, 12.5))]
    vb = [bm.verts.new(p) for p in base]
    vr = [bm.verts.new(p) for p in ridge]
    faces = [(vb[0], vb[1], vr[1], vr[0]), (vb[2], vb[3], vr[0], vr[1]), (vb[1], vb[2], vr[1]), (vb[3], vb[0], vr[0])]
    for fv in faces:
        f = bm.faces.new(fv)
        for loop in f.loops:
            co = loop.vert.co
            loop[uvl].uv = ((co.x + co.y) / 6.0, co.z / 3.0)
    finish("PT_Hut__Roof", bm, col, [m_thatch], smooth=False)


def fence(col, m_wood):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    for x in (-3.0, 3.0):
        box(bm, uvl, x, 0, -0.4, 0.45, 0.45, 3.4, uvs=3)
    for z in (1.2, 2.4):
        box(bm, uvl, 0, 0, z, 6.6, 0.25, 0.35, uvs=3)
    finish("PT_Fence__Wood", bm, col, [m_wood], smooth=False)


def torch(col, m_bamboo, m_wood):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    tube(bm, uvl, [Vector((0, 0, -0.5)), Vector((0, 0, 6.5))], [0.22, 0.2], sides=6, v_scale=3.0, u_rep=1.0)
    finish("PT_Torch__Pole", bm, col, [m_bamboo])
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    tube(bm, uvl, [Vector((0, 0, 6.3)), Vector((0, 0, 7.2))], [0.35, 0.6], sides=8, v_scale=2.0, u_rep=1.0)
    finish("PT_Torch__Bowl", bm, col, [m_wood], smooth=False)
    fx_anchor(col, "PT_Torch__FX1", (0, 0, 7.4))


def banner(col, m_bamboo, m_cloth):
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    tube(bm, uvl, [Vector((0, 0, -0.5)), Vector((0, 0, 9.0))], [0.2, 0.17], sides=6, v_scale=3.0, u_rep=1.0)
    tube(bm, uvl, [Vector((0, -0.1, 8.6)), Vector((0, 2.4, 8.6))], [0.1, 0.1], sides=5, v_scale=3.0, u_rep=1.0)
    finish("PT_Banner__Pole", bm, col, [m_bamboo])
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    _disc_banner(bm, uvl, Vector((0, 1.25, 8.5)), Vector((1, 0, 0)), w=2.2, h=4.8)
    finish("PT_Banner__Cloth", bm, col, [m_cloth], lambda ob, v: Vector((1, 0, 0)))


def build():
    col = C.clear_collection("AST_Assets")
    m_bark = C.tex_material("M_Bark", "bark")
    m_leaf = C.tex_material("M_Leaves", "leaves", alpha=True)
    m_frond = C.tex_material("M_Frond", "frond", alpha=True)
    m_tuft = C.tex_material("M_GrassTuft", "grass_tuft", alpha=True)
    m_flow = C.tex_material("M_Flowers", "flowers", alpha=True)
    m_rock = C.tex_material("M_Rock", "rock")
    m_stone = C.tex_material("M_ShrineStone", "shrine_stone")
    m_gold = C.tex_material("M_Gold", "gold", rough=0.35)
    m_emb = C.tex_material("M_SunEmblem", "sun_emblem", alpha=True, emission=0.6)
    m_wood = C.tex_material("M_Wood", "wood")
    m_thatch = C.tex_material("M_Thatch", "thatch")
    m_bamboo = C.tex_material("M_Bamboo", "bamboo")
    m_cloth = C.tex_material("M_Cloth", "cloth", alpha=True)

    tree_broad(col, m_bark, m_leaf, "PT_TreeBroad", 21.0, 8.5, 0.0)
    tree_broad(col, m_bark, m_leaf, "PT_TreeBroad2", 17.0, 7.0, 1.3)
    tree_tall(col, m_bark, m_leaf)
    palm(col, m_bark, m_frond)
    bamboo(col, m_bamboo, m_leaf)
    bush(col, m_leaf, "PT_Bush", 2.4)
    bush(col, m_leaf, "PT_BushSmall", 1.5)
    crossed_cards(col, m_tuft, "PT_GrassTuft__Blades", 2.6, 2.2, 3)
    crossed_cards(col, m_flow, "PT_Flowers__Petals", 2.0, 1.8, 2)
    rock(col, m_rock, "PT_RockA__Rock", (3.2, 2.4, 2.4), 3)
    rock(col, m_rock, "PT_RockB__Rock", (1.8, 1.5, 1.2), 7)
    rock(col, m_rock, "PT_RockC__Rock", (5.5, 4.0, 3.6), 11)
    sun_gate(col, m_stone, m_gold, m_emb)
    shrine(col, m_stone, m_gold, m_emb, m_cloth)
    hut(col, m_wood, m_thatch, m_bamboo)
    fence(col, m_wood)
    torch(col, m_bamboo, m_wood)
    banner(col, m_bamboo, m_cloth)
    tris = {o.name: C.tri_count(o) for o in col.objects if o.type == "MESH"}
    return {"objects": len(col.objects), "total_tris": sum(tris.values()), "max": max(tris.items(), key=lambda kv: kv[1])}


sc = C.scene()
bpy.context.window.scene = sc
result = build()
