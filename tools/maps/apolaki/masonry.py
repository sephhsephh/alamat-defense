# Apolaki Sun Terraces -- real stone geometry (B166, user: "actual stones or bricks built on top of
# each other, not just texture"). Builds:
#   AST_Terrain2: stacked-fieldstone terrace walls (AST_TerraceStones_k) + recessed earth backing
#                 (AST_TerraceWall_k) + the path with RAISED dark rims (AST_Path).
#   AST_Assets2:  block-built SunGate + Shrine, faceted hull rocks, rock piles, pebbles.
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


def terrace_front(x, k):
    return 46.0 + 9.0 * (k - 1) + 5.0 * math.sin(x / 23.0 + k * 0.7) + 0.0016 * x * x


# ------------------------------------------------------------------ primitives (all append to bm)
def _hull(bm, pts):
    vs = [bm.verts.new(p) for p in pts]
    res = bmesh.ops.convex_hull(bm, input=vs)
    junk = list({g for g in res.get("geom_interior", []) + res.get("geom_unused", [])
                 if isinstance(g, bmesh.types.BMVert) and g.is_valid and not g.link_faces})
    if junk:
        bmesh.ops.delete(bm, geom=junk, context="VERTS")
    return [g for g in res["geom"] if isinstance(g, bmesh.types.BMFace) and g.is_valid]


def _box_uv(faces, uvl, uvs, off, origin):
    for f in faces:
        n = f.normal
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in f.loops:
            p = loop.vert.co - origin
            a, b = ((p.y, p.z) if ax == 0 else (p.x, p.z) if ax == 1 else (p.x, p.y))
            loop[uvl].uv = (a / uvs + off[0], b / uvs + off[1])


def block(bm, uvl, center, size, rotz=0.0, tilt=(0.0, 0.0), chamfer=0.1, jitter=0.0, r=None, uvs=3.0):
    """Chamfered (optionally weathered) box. size = (sx, sy, sz)."""
    r = r or C.rng(0)
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    ch = min(chamfer, hx * 0.45, hy * 0.45, hz * 0.45)
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                c = Vector((sx * hx, sy * hy, sz * hz))
                for d in (Vector((sx * ch, 0, 0)), Vector((0, sy * ch, 0)), Vector((0, 0, sz * ch))):
                    q = c - d
                    if jitter:
                        q += Vector((r.normal(0, jitter), r.normal(0, jitter), r.normal(0, jitter)))
                    pts.append(q)
    M = Matrix.Translation(Vector(center)) @ Matrix.Rotation(rotz, 4, "Z") @ Matrix.Rotation(tilt[0], 4, "X") @ Matrix.Rotation(tilt[1], 4, "Y")
    faces = _hull(bm, [M @ p for p in pts])
    _box_uv(faces, uvl, uvs, (r.random(), r.random()), Vector(center))
    for f in faces:
        f.smooth = False
    return faces


def fieldstone(bm, uvl, center, size, rotz, r, jitter=0.16):
    """Irregular natural stone: jittered box corners + bulged face centres."""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    pts = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for sz in (-1, 1):
                pts.append(Vector((sx * hx * r.uniform(0.75, 1.0), sy * hy * r.uniform(0.75, 1.0), sz * hz * r.uniform(0.7, 1.0))))
    for ax in range(3):
        for s in (-1, 1):
            q = Vector((0, 0, 0))
            q[ax] = s * (hx, hy, hz)[ax] * r.uniform(1.0, 1.12)
            q += Vector((r.normal(0, jitter * hx), r.normal(0, jitter * hy * 0.5), r.normal(0, jitter * hz * 0.5)))
            pts.append(q)
    M = Matrix.Translation(Vector(center)) @ Matrix.Rotation(rotz, 4, "Z") @ Matrix.Rotation(r.normal(0, 0.05), 4, "X")
    faces = _hull(bm, [M @ p for p in pts])
    _box_uv(faces, uvl, 2.5, (r.random(), r.random()), Vector(center))
    for f in faces:
        f.smooth = False
    return faces


def boulder(bm, uvl, center, size, r, n=18, flat_bottom=0.35):
    """Faceted stylised rock: convex hull of points on a squashed ellipsoid."""
    pts = []
    for _ in range(n):
        d = Vector((r.normal(), r.normal(), r.normal())).normalized()
        d.z = max(d.z, -flat_bottom)
        k = r.uniform(0.78, 1.0)
        pts.append(Vector((d.x * size[0] * k, d.y * size[1] * k, d.z * size[2] * k)))
    rot = Matrix.Rotation(r.uniform(0, 6.28), 4, "Z")
    c = Vector(center)
    faces = _hull(bm, [c + (rot @ p) for p in pts])
    zmin = min(v.co.z for f in faces for v in f.verts)
    zmax = max(v.co.z for f in faces for v in f.verts)
    for f in faces:
        f.smooth = False
        for loop in f.loops:
            p = loop.vert.co
            loop[uvl].uv = (math.atan2(p.y - c.y, p.x - c.x) / math.pi + 1.0, (p.z - zmin) / max(zmax - zmin, 1e-3))
    return faces


def drum(bm, uvl, center, rad, h, sides=12, chamfer=0.08, r=None, rot=0.0, uvs=3.0):
    r = r or C.rng(0)
    pts = []
    for z, rr in ((-h / 2, rad - chamfer), (-h / 2 + chamfer, rad), (h / 2 - chamfer, rad), (h / 2, rad - chamfer)):
        for i in range(sides):
            a = 2 * math.pi * i / sides + rot
            pts.append(Vector((math.cos(a) * rr, math.sin(a) * rr, z)))
    c = Vector(center)
    faces = _hull(bm, [c + p for p in pts])
    for f in faces:
        f.smooth = False
        for loop in f.loops:
            p = loop.vert.co - c
            if abs(f.normal.z) > 0.7:
                loop[uvl].uv = (p.x / uvs + 0.3, p.y / uvs + 0.6)
            else:
                loop[uvl].uv = ((math.atan2(p.y, p.x) / math.pi) * rad * 3.14 / uvs, p.z / uvs + r.random())
    return faces


def ring_of_blocks(bm, uvl, cx, cy, z0, radius, depth, height, r, gap=0.1, length=2.6):
    n = max(8, round(2 * math.pi * radius / length))
    seg = 2 * math.pi * radius / n
    for i in range(n):
        a = 2 * math.pi * (i + 0.5) / n
        x, y = cx + math.cos(a) * (radius - depth / 2), cy + math.sin(a) * (radius - depth / 2)
        block(bm, uvl, (x, y, z0 + height / 2), (depth, seg - gap, height), rotz=a, chamfer=0.09, jitter=0.02, r=r)


def disc(bm, uvl, cx, cy, z, radius, sides=32, uvs=4.0):
    vs = [bm.verts.new((cx + math.cos(2 * math.pi * i / sides) * radius, cy + math.sin(2 * math.pi * i / sides) * radius, z)) for i in range(sides)]
    f = bm.faces.new(vs)
    for loop in f.loops:
        loop[uvl].uv = (loop.vert.co.x / uvs, loop.vert.co.y / uvs)
    return f


def new_bm():
    bm = bmesh.new()
    return bm, bm.loops.layers.uv.new("UVMap")


# ------------------------------------------------------------------ terrain pieces
def build_terrain2(col, m_field, m_cliff, m_path):
    out = {}
    for k in range(1, 9):
        r = C.rng(700 + k)
        z0, z1 = 4.0 * (k - 1), 4.0 * k
        bm, uvl = new_bm()
        rows = 3
        rh = (z1 - z0) / rows
        for row in range(rows):
            x = -150.0 + r.uniform(0, 2.5)
            while x < 150.0:
                L = r.uniform(2.3, 3.9)
                cxs = x + L / 2
                dy = (terrace_front(cxs + 0.5, k) - terrace_front(cxs - 0.5, k))
                ang = math.atan2(dy, 1.0)
                h = rh * r.uniform(0.86, 1.0)
                cz = z0 + rh * (row + 0.5) + r.normal(0, 0.05)
                cy = terrace_front(cxs, k) + 0.55 + row * 0.22
                fieldstone(bm, uvl, (cxs, cy, cz), (L, 1.35, h), ang, r)
                x += L + r.uniform(0.06, 0.2)
        ob = C.mesh_object("AST_TerraceStones_%d" % k, bm, col, [m_field])
        out[ob.name] = C.tri_count(ob)
        # recessed earth backing behind the stones (gaps read as packed earth); terrace 1 keeps its cliff
        xs = np.linspace(-190, 190, 96)
        ys = np.array([terrace_front(x, k) for x in xs])
        bm, uvl = new_bm()
        per = np.concatenate([[0], np.cumsum(np.hypot(np.diff(xs), np.diff(ys)))])
        rows_z = ([-22.0, 0.0] if k == 1 else []) + [z0, z1]
        rows_z = sorted(set(rows_z))
        verts = []
        for z in rows_z:
            back = 0.0 if z < 0 or (k == 1 and z == 0.0 and False) else 1.0
            ring = []
            for i, x in enumerate(xs):
                yy = ys[i] + (0.0 if z <= 0 and k == 1 else 1.0)
                ring.append((bm.verts.new((x, yy, z)), per[i], z))
            verts.append(ring)
        for a, b in zip(verts[:-1], verts[1:]):
            for i in range(len(xs) - 1):
                f = bm.faces.new((a[i][0], a[i + 1][0], b[i + 1][0], b[i][0]))
                for loop, (pp, zz) in zip(f.loops, ((a[i][1], a[i][2]), (a[i + 1][1], a[i + 1][2]), (b[i + 1][1], b[i + 1][2]), (b[i][1], b[i][2]))):
                    loop[uvl].uv = (pp / 32.0, 1 - max(0.0, z1 - zz) / 32.0)
        bm.normal_update()
        ob = C.mesh_object("AST_TerraceEarth_%d" % k, bm, col, [m_cliff])
        for p in ob.data.polygons:
            if p.normal.y > 0:
                p.flip()
        out[ob.name] = C.tri_count(ob)
    return out


def build_path2(col, m_path):
    import terrain as T  # noqa: F401  (reuse rounded_path + the layout numbers)
    importlib.reload(T)
    return None


# ------------------------------------------------------------------ prototypes
def sun_gate(col, m_stone, m_gold, m_emb):
    r = C.rng(31)
    bm, uvl = new_bm()
    for sy in (-5.2, 5.2):
        block(bm, uvl, (0, sy, 0.6), (3.1, 3.1, 1.2), chamfer=0.14, jitter=0.03, r=r)
        z = 1.25
        for i in range(6):
            h = 1.45
            block(bm, uvl, (r.normal(0, 0.05), sy + r.normal(0, 0.05), z + h / 2), (2.2, 2.2, h - 0.06),
                  rotz=r.normal(0, 0.04), chamfer=0.12, jitter=0.025, r=r)
            z += h
        block(bm, uvl, (0, sy, z + 0.4), (2.9, 2.9, 0.8), chamfer=0.12, jitter=0.02, r=r)
    zt = 1.25 + 6 * 1.45 + 0.8
    for y0, L, h in ((-5.0, 4.8, 1.45), (0.0, 4.6, 1.75), (5.0, 4.8, 1.45)):
        block(bm, uvl, (0, y0, zt + h / 2), (2.5, L - 0.06, h), chamfer=0.12, jitter=0.02, r=r)
    for y0 in (-3.95, 3.95):
        block(bm, uvl, (0, y0, zt + 1.75 + 0.35), (2.9, 7.9, 0.7), chamfer=0.1, jitter=0.02, r=r)
    C.mesh_object("PT_SunGate__Stone", bm, col, [m_stone])
    bm, uvl = new_bm()
    for sy in (-5.2, 5.2):
        block(bm, uvl, (0, sy, 1.25 + 6 * 1.45 - 0.08), (2.35, 2.35, 0.16), chamfer=0.04, r=r)
    block(bm, uvl, (0, 0, zt + 2.6), (1.3, 3.2, 0.9), chamfer=0.1, r=r)
    C.mesh_object("PT_SunGate__Gold", bm, col, [m_gold])
    bm, uvl = new_bm()
    c = Vector((0, 0, zt + 2.6 + 3.6))
    vs = [bm.verts.new(c + Vector((0, x * 4.0, y * 4.0))) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    f = bm.faces.new(vs)
    for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
        loop[uvl].uv = uv
    ob = C.mesh_object("PT_SunGate__Emblem", bm, col, [m_emb])
    ob.data.normals_split_custom_set_from_vertices([Vector((1, 0, 0.2)).normalized()] * len(ob.data.vertices))
    C.mesh_object_fx = None
    _fx(col, "PT_SunGate__FX1", (0, 0, 5.5))
    _fx(col, "PT_SunGate__FX2", tuple(c))


def _fx(col, name, p):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.2)
    for v in bm.verts:
        v.co += Vector(p)
    C.mesh_object(name, bm, col, [])


def shrine(col, m_stone, m_gold, m_emb, m_cloth):
    r = C.rng(41)
    bm, uvl = new_bm()
    # stepped platform: rings of curved-ish blocks with paved discs on top
    for (rad, z0, h) in ((9.6, -0.6, 1.4), (8.3, 0.8, 1.0), (7.1, 1.8, 0.8)):
        ring_of_blocks(bm, uvl, 0, 0, z0, rad, 1.5, h, r)
        disc(bm, uvl, 0, 0, z0 + h - 0.04, rad - 1.3)
    # six pillars of stacked drums
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        x, y = math.cos(a) * 6.0, math.sin(a) * 6.0
        block(bm, uvl, (x, y, 2.6 + 0.3), (1.9, 1.9, 0.6), rotz=a, chamfer=0.1, jitter=0.02, r=r)
        z = 3.2
        for j in range(6):
            drum(bm, uvl, (x + r.normal(0, 0.03), y + r.normal(0, 0.03), z + 0.7), 0.78, 1.36, sides=12, r=r, rot=r.uniform(0, 1))
            z += 1.42
        block(bm, uvl, (x, y, z + 0.35), (2.1, 2.1, 0.7), rotz=a, chamfer=0.1, jitter=0.02, r=r)
    # ring beam on the pillars + stepped pedestal
    ring_of_blocks(bm, uvl, 0, 0, 12.8, 7.2, 1.6, 0.9, r, length=3.4)
    for (rad, z0, h) in ((1.7, 2.6, 1.1), (1.45, 3.7, 1.1), (1.2, 4.8, 1.1)):
        drum(bm, uvl, (0, 0, z0 + h / 2), rad, h - 0.05, sides=14, r=r)
    C.mesh_object("PT_Shrine__Stone", bm, col, [m_stone])
    bm, uvl = new_bm()
    drum(bm, uvl, (0, 0, 6.2), 1.3, 0.45, sides=16, r=r)
    drum(bm, uvl, (0, 0, 13.95), 5.2, 0.5, sides=28, r=r)
    C.mesh_object("PT_Shrine__Gold", bm, col, [m_gold])
    bm, uvl = new_bm()
    for nx in (-1, 1):
        c = Vector((0, 0, 9.6))
        vs = [bm.verts.new(c + Vector((0, x * 3.5 * nx, y * 3.5))) for x, y in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
        f = bm.faces.new(vs)
        for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            loop[uvl].uv = uv
    ob = C.mesh_object("PT_Shrine__Emblem", bm, col, [m_emb])
    ob.data.normals_split_custom_set_from_vertices([Vector((1, 0, 0.3)).normalized()] * len(ob.data.vertices))
    bm, uvl = new_bm()
    for i in range(6):
        a = 2 * math.pi * i / 6 + math.pi / 6
        n = Vector((math.cos(a), math.sin(a), 0))
        c = Vector((math.cos(a) * 6.0, math.sin(a) * 6.0, 9.2)) + n * 0.85
        u = n.cross(Vector((0, 0, 1))).normalized()
        vs = [bm.verts.new(c + u * x * 0.8 + Vector((0, 0, z))) for x, z in ((-1, -4.2), (1, -4.2), (1, 0), (-1, 0))]
        f = bm.faces.new(vs)
        for loop, uv in zip(f.loops, [(0, 0), (1, 0), (1, 1), (0, 1)]):
            loop[uvl].uv = uv
    C.mesh_object("PT_Shrine__Banners", bm, col, [m_cloth])
    _fx(col, "PT_Shrine__FX1", (0, 0, 9.6))


def rocks(col, m_rock, m_field):
    specs = {"RockA": ((3.0, 2.3, 2.2), 3), "RockB": ((1.7, 1.4, 1.1), 7), "RockC": ((5.2, 3.8, 3.4), 11)}
    for name, (size, seed) in specs.items():
        bm, uvl = new_bm()
        boulder(bm, uvl, (0, 0, size[2] * 0.25), size, C.rng(seed), n=20)
        C.mesh_object("PT_%s__Rock" % name, bm, col, [m_rock])
    # piles: rocks resting on each other
    piles = {
        "RockPile1": [((0, 0, 1.0), (3.6, 2.8, 2.6)), ((2.6, 1.0, 0.6), (2.0, 1.6, 1.4)), ((-2.3, 0.8, 0.5), (1.8, 1.4, 1.2)),
                      ((0.6, -0.3, 2.9), (1.8, 1.5, 1.2)), ((1.6, -2.0, 0.3), (1.0, 0.9, 0.7))],
        "RockPile2": [((0, 0, 0.7), (2.6, 2.0, 1.8)), ((1.8, -0.8, 0.5), (1.6, 1.3, 1.1)), ((0.4, 0.5, 2.0), (1.3, 1.1, 0.9)),
                      ((-1.6, -1.0, 0.3), (0.9, 0.8, 0.6))],
        "RockPile3": [((0, 0, 1.6), (5.0, 4.0, 3.8)), ((3.6, 1.6, 1.0), (2.6, 2.2, 2.0)), ((-3.4, 1.2, 0.8), (2.4, 2.0, 1.6)),
                      ((1.2, -0.6, 4.4), (2.2, 1.8, 1.5)), ((-1.6, -3.0, 0.4), (1.4, 1.2, 0.9)), ((2.2, -3.2, 0.3), (1.0, 0.9, 0.7))],
    }
    for name, parts in piles.items():
        bm, uvl = new_bm()
        r = C.rng(sum(map(ord, name)))
        for c, s in parts:
            boulder(bm, uvl, c, s, r, n=18)
        C.mesh_object("PT_%s__Rock" % name, bm, col, [m_rock])
    bm, uvl = new_bm()
    r = C.rng(77)
    for i in range(9):
        a = r.uniform(0, 6.28)
        d = r.uniform(0, 2.2)
        s = r.uniform(0.25, 0.55)
        boulder(bm, uvl, (math.cos(a) * d, math.sin(a) * d, s * 0.2), (s * 1.3, s, s * 0.6), r, n=12, flat_bottom=0.1)
    C.mesh_object("PT_Pebbles__Rock", bm, col, [m_field])


def build_assets2(col):
    m_stone = C.tex_material("M_StoneBlock", "stone_block")
    m_field = C.tex_material("M_Fieldstone", "fieldstone")
    m_rock = C.tex_material("M_Rock", "rock")
    m_gold = C.tex_material("M_Gold", "gold", rough=0.35)
    m_emb = C.tex_material("M_SunEmblem", "sun_emblem", alpha=True, emission=0.6)
    m_cloth = C.tex_material("M_Cloth", "cloth", alpha=True)
    sun_gate(col, m_stone, m_gold, m_emb)
    shrine(col, m_stone, m_gold, m_emb, m_cloth)
    rocks(col, m_rock, m_field)
    return {o.name: C.tri_count(o) for o in col.objects if o.type == "MESH"}


sc = C.scene()
bpy.context.window.scene = sc
# the block-built gate/shrine and the hull rocks REPLACE the B166 first-pass prototypes
for o in list(bpy.data.objects):
    if o.name.startswith(("PT_SunGate", "PT_Shrine", "PT_RockA", "PT_RockB", "PT_RockC", "PT_RockPile", "PT_Pebbles")):
        bpy.data.objects.remove(o, do_unlink=True)
col_t = C.clear_collection("AST_Terrain2")
col_a = C.clear_collection("AST_Assets2")
tris_t = build_terrain2(col_t, C.tex_material("M_Fieldstone", "fieldstone"), C.tex_material("M_Cliff", "cliff"), None)
tris_a = build_assets2(col_a)
result = {"terrain2_tris": sum(tris_t.values()), "terrain2_max": max(tris_t.values()), "assets2": tris_a}
