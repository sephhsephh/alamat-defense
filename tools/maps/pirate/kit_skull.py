# Bakunawa Cove -- Kit S: Skull Rock (B173 v2, user refs: a weathered stone skull embedded in a rocky outcrop,
# deep dark orbits under a heavy brow, nasal cavity, cave mouth with broken teeth, rough faceted rock, moss on top).
# Built the Blender way: anatomical parts (cranium, brow, cheekbones, maxilla, buried jaw) joined -> voxel remesh
# (union) -> boolean-cut orbits / nose / cave mouth -> remesh -> rough displacement -> decimate into hard facets.
# Faces inside the cavities become Void (dark), upward faces on the crown become Grass (moss); teeth are Bone
# hulls snapped to the surface with a BVH ray. Rubble hulls (Rock) pile around the base.
# Rules: tools/maps/lobby/README.md (split by material, origin bottom-centre, front -Y, zfight_report = 0).
import importlib.util
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np

PARTS = [  # skull volumes: centre, radii, rotation about Y (rad)
    ((0.0, 3.0, 31.0), (25.0, 27.0, 23.0), 0.0),     # cranium
    ((0.0, -14.0, 19.0), (18.0, 12.0, 14.0), 0.0),   # face / maxilla
    ((0.0, -19.0, 31.0), (22.0, 8.5, 6.5), 0.0),     # brow ridge (overhangs the orbits)
    ((18.0, -11.0, 20.0), (7.0, 10.0, 5.5), -0.3),   # cheekbones
    ((-18.0, -11.0, 20.0), (7.0, 10.0, 5.5), 0.3),
    ((0.0, -9.0, 4.0), (19.0, 15.0, 10.0), 0.0),     # jaw, buried in the rubble
]
CUTS = [  # name, centre, radii, rotation about Y, "behind" y (faces deeper than this go dark)
    ("eyeL", (-10.0, -27.0, 23.5), (7.0, 14.0, 7.0), 0.35, -22.5),
    ("eyeR", (10.0, -27.0, 23.5), (7.0, 14.0, 7.0), -0.35, -22.5),
    ("nose", (0.0, -28.5, 18.0), (3.2, 12.0, 4.6), 0.0, -24.0),
    ("mouth", (0.0, -27.0, 2.5), (12.5, 19.0, 9.0), 0.0, -21.0),
]


def ellipsoid(name, c, r, rot, col):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=32, v_segments=20, radius=1.0)
    M = Matrix.Translation(c) @ Matrix.Rotation(rot, 4, "Y") @ Matrix.Diagonal((r[0], r[1], r[2], 1.0))
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)
    return C.mesh_object(name, bm, col)


def inside(p, c, r, rot, grow=1.0):
    q = Matrix.Rotation(-rot, 4, "Y") @ (Vector(p) - Vector(c))
    return (q.x / (r[0] * grow)) ** 2 + (q.y / (r[1] * grow)) ** 2 + (q.z / (r[2] * grow)) ** 2 < 1.0


def sculpt(col):
    """The remesh / boolean / displace / decimate stack -> one evaluated Mesh (world space)."""
    # skull volume
    bm = bmesh.new()
    for i, (c, r, rot) in enumerate(PARTS):
        tmp = bmesh.new()
        bmesh.ops.create_uvsphere(tmp, u_segments=40, v_segments=24, radius=1.0)
        bmesh.ops.transform(tmp, matrix=Matrix.Translation(c) @ Matrix.Rotation(rot, 4, "Y")
                            @ Matrix.Diagonal((r[0], r[1], r[2], 1.0)), verts=tmp.verts)
        C._append(bm, tmp)
    sk = C.mesh_object("_BC_SkullSculpt", bm, col)
    # cutter = orbits + nose + mouth + a slab under the ground
    cb = bmesh.new()
    for _n, c, r, rot, _b in CUTS:
        tmp = bmesh.new()
        bmesh.ops.create_uvsphere(tmp, u_segments=32, v_segments=20, radius=1.0)
        bmesh.ops.transform(tmp, matrix=Matrix.Translation(c) @ Matrix.Rotation(rot, 4, "Y")
                            @ Matrix.Diagonal((r[0], r[1], r[2], 1.0)), verts=tmp.verts)
        C._append(cb, tmp)
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0, matrix=Matrix.Translation((0, 0, -9.0)) @ Matrix.Diagonal((90, 90, 12, 1)))
    C._append(cb, tmp)
    cut = C.mesh_object("_BC_SkullCut", cb, col)
    cut.hide_render = True
    m = sk.modifiers.new("union", "REMESH")
    m.mode, m.voxel_size = "VOXEL", 1.1
    m = sk.modifiers.new("cut", "BOOLEAN")
    m.operation, m.object = "DIFFERENCE", cut
    m.use_self = True  # the cutter is several overlapping closed shells
    try:
        m.solver = "EXACT"
    except Exception:
        pass
    m = sk.modifiers.new("smooth", "REMESH")
    m.mode, m.voxel_size = "VOXEL", 0.8
    tex = bpy.data.textures.get("_BC_SkullNoise") or bpy.data.textures.new("_BC_SkullNoise", "VORONOI")
    tex.noise_scale = 7.0
    tex.distance_metric = "DISTANCE"
    m = sk.modifiers.new("rough", "DISPLACE")
    m.texture, m.strength, m.mid_level, m.texture_coords = tex, 2.2, 0.5, "GLOBAL"
    tex2 = bpy.data.textures.get("_BC_SkullNoise2") or bpy.data.textures.new("_BC_SkullNoise2", "CLOUDS")
    tex2.noise_scale = 3.0
    m = sk.modifiers.new("rough2", "DISPLACE")
    m.texture, m.strength, m.mid_level, m.texture_coords = tex2, 1.2, 0.5, "GLOBAL"
    m = sk.modifiers.new("facets", "DECIMATE")
    m.ratio = 0.3
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(sk.evaluated_get(dg))
    bpy.data.objects.remove(sk, do_unlink=True)
    bpy.data.objects.remove(cut, do_unlink=True)
    return me


def skull(col, man, origin):
    P = C.Piece("BC_SkullRock", origin)
    P.smooth["Rock"] = 28.0
    P.uv_scale["Rock"] = 30.0
    me = sculpt(col)
    src = bmesh.new()
    src.from_mesh(me)
    bpy.data.meshes.remove(me)
    src.normal_update()
    r = C.rng(7)

    def kind(f):
        p = f.calc_center_median()
        for _n, c, rr, rot, behind in CUTS:
            if p.y > behind and inside(p, c, rr, rot, 1.12):
                return "Void"
        moss = C.vnoise_xy(np.array([p.x / 14.0]), np.array([p.y / 14.0]), 4096, 31)[0]
        if p.z > 44.5 + 8.0 * (moss - 0.5) and f.normal.z > 0.3:
            return "Moss"  # a moss cap with a soft wavy edge (no per-face speckle)
        return "Rock"

    kinds = {f.index: kind(f) for f in src.faces}
    for k in ("Rock", "Void", "Moss"):
        bm = src.copy()
        bm.faces.ensure_lookup_table()
        dead = [f for f in bm.faces if kinds[f.index] != k]
        bmesh.ops.delete(bm, geom=dead, context="FACES")
        C._append(P.bm(k), bm)
    # broken teeth under the maxilla, snapped onto the surface with a ray from the front
    bvh = BVHTree.FromBMesh(src)
    for k, x in enumerate(np.linspace(-9.5, 9.5, 8)):
        if k in (2, 6):
            continue  # missing teeth
        z = 12.6 - 0.03 * x * x  # the upper jaw, just above the cave lip
        hit = bvh.ray_cast(Vector((x, -60.0, z)), Vector((0, 1, 0)))
        if hit[0] is None:
            continue
        h = r.uniform(3.6, 5.2)
        C.hull_rock(P.bm("Bone"), (x, hit[0].y + 1.2, z - 1.4), (1.7, 1.4, h * 0.55), r, n=12, flat_bottom=1.0)
    for x in np.linspace(-7.0, 7.0, 5):  # lower teeth poking out of the rubble
        hit = bvh.ray_cast(Vector((x, -60.0, 1.0)), Vector((0, 1, 0)))
        if hit[0] is not None:
            C.hull_rock(P.bm("Bone"), (x, hit[0].y - 0.6, 0.6), (0.9, 0.8, 1.4), r, n=10)
    src.free()
    # rubble outcrop: big boulders hugging the base and sides, small ones spilling forward
    for i in range(16):
        a = r.uniform(-0.2, math.pi + 0.2) + math.pi  # around the front half + sides
        if abs(math.cos(a)) < 0.35 and math.sin(a) < 0:
            continue  # keep the cave mouth clear
        d = r.uniform(21.0, 30.0)
        s = r.uniform(5.0, 9.0)
        C.hull_rock(P.bm("Rock"), (d * math.cos(a), d * math.sin(a) * 0.9, s * 0.15 - r.uniform(0.0, 2.0)), (s, s * 0.85, s * 0.8), r, n=18, flat_bottom=1.0)
    for i in range(10):
        a = r.uniform(0, 2 * math.pi)
        d = r.uniform(24.0, 36.0)
        x, y = d * math.cos(a), d * math.sin(a)
        if y < -20 and abs(x) < 14:
            continue
        s = r.uniform(2.0, 4.0)
        C.hull_rock(P.bm("Rock"), (x, y, 0.0), (s, s * 0.9, s * 0.7), r, n=14, flat_bottom=1.0)
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitS")
    man = {}
    skull(col, man, (0.0, 0.0, 0.0))
    C.write_manifest("S", man)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
