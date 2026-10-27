# Bakunawa Cove (Stage 2 map, AD-Game) -- shared helpers for the Blender build scripts (B173).
# The Lobby kit helpers (tools/maps/lobby/common.py: noise/paint, bmesh primitives, Piece/Row, export_kit,
# zfight_report, preview) are EXECUTED into this module, then the paths and the material table are swapped for
# the pirate ones. On top: the terrain helpers from tools/maps/apolaki/terrain.py and kit instancing.
#
# Load it under a unique name (apolaki + lobby also have a `common`):
#   import importlib.util, sys
#   PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
#   _s = importlib.util.spec_from_file_location("bc_common", PIRATE + r"\common.py")
#   C = importlib.util.module_from_spec(_s); sys.modules["bc_common"] = C; _s.loader.exec_module(C)
#
# Frame: Blender Z up, 1 unit = 1 stud, plateau top z = 0, sea z = SEA_Z. JSON layouts are written as (x, z, -y)
# like Stage 1 (the 3D Importer turns the scene 180 deg about Y; maps-apolaki.md).
import math
import os

_LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby\common.py"
with open(_LOBBY, encoding="utf-8") as _fh:
    exec(compile(_fh.read(), _LOBBY, "exec"), globals())

BASE = r"C:\Users\Joseph Elton Estilo\Downloads\BakunawaCove_Map"
TEX = os.path.join(BASE, "tex")
GLB = os.path.join(BASE, "glb")
RENDERS = os.path.join(BASE, "renders")
BLEND = os.path.join(BASE, "BakunawaCove.blend")
TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
RNG = np.random.default_rng(1173)

SEA_Z = -8.0

# name -> texture, roughness, studs per tile (None = the primitive's own UVs), emission, alpha, double-sided
MATS = {
    "Grass":     dict(tex="grass", rough=0.9, uv=24.0),
    "Sand":      dict(tex="sand", rough=0.95, uv=20.0),
    "Cliff":     dict(tex="cliff", rough=0.9, uv=None),
    "Rock":      dict(tex="rock", rough=0.85, uv=10.0),
    "PathSand":  dict(tex="path", rough=0.95, uv=None),
    "Curb":      dict(tex="curb", rough=0.6, uv=None),
    "Street":    dict(tex="street", rough=0.95, uv=None, alpha=True),
    "Plaza":     dict(tex="plaza", rough=0.9, uv=12.0),
    "Canvas":    dict(tex="canvas", rough=0.9, uv=6.0, double=True),
    "Skin":      dict(tex="skin", rough=0.6, uv=4.0),
    "CoatRed":   dict(tex="coat_red", rough=0.85, uv=3.0),
    "Leather":   dict(tex="leather", rough=0.5, uv=2.0),
    "Hair":      dict(tex="hair", rough=0.8, uv=1.5),
    "ClothDark": dict(tex="cloth_dark", rough=0.9, uv=3.0),
    "Glow":      dict(tex="glow", rough=0.3, uv=1.0, emission=4.0),
    "Plank":     dict(tex="plank", rough=0.85, uv=8.0),
    "WoodDark":  dict(tex="wood_dark", rough=0.8, uv=6.0),
    "Thatch":    dict(tex="thatch", rough=0.95, uv=8.0),
    "Shingle":   dict(tex="shingle", rough=0.8, uv=8.0),
    "Stone":     dict(tex="stone", rough=0.85, uv=10.0),
    "AwningRed": dict(tex="awning_red", rough=0.9, uv=6.0, double=True),
    "AwningTeal": dict(tex="awning_teal", rough=0.9, uv=6.0, double=True),
    "Sail":      dict(tex="sail", rough=0.9, uv=None, double=True),
    "Flag":      dict(tex="flag", rough=0.9, uv=None, double=True),
    "Gold":      dict(tex="gold", rough=0.3, uv=4.0),
    "Iron":      dict(tex="iron", rough=0.5, uv=4.0),
    "Rope":      dict(tex="rope", rough=0.9, uv=2.0),
    "Bone":      dict(tex="bone", rough=0.7, uv=6.0),
    "Bark":      dict(tex="palm_bark", rough=0.9, uv=None),
    "Frond":     dict(tex="frond", rough=0.8, uv=None, alpha=True, double=True),
    "Leaves":    dict(tex="leaves", rough=0.8, uv=None, alpha=True, double=True),
    "Tuft":      dict(tex="grass_tuft", rough=0.9, uv=None, alpha=True, double=True),
    "Blade":     dict(tex="blade", rough=0.8, uv=None, double=True),
    "Petal":     dict(tex="petal", rough=0.8, uv=None, double=True),
    "Water":     dict(tex="sea", rough=0.15, uv=None),
    "Falls":     dict(tex="falls", rough=0.2, uv=None, alpha=True, double=True, emission=0.3),
    "Lamp":      dict(tex="lamp", rough=0.5, uv=4.0, emission=2.0),
    "Void":      dict(tex="void", rough=1.0, uv=8.0),
    "Foam":      dict(tex="foam", rough=0.6, uv=8.0),
    "Moss":      dict(tex="moss", rough=0.95, uv=10.0),
}
UV_SCALE = {k: v["uv"] for k, v in MATS.items()}
SMOOTH_ANGLE = {k: 40.0 for k in MATS}
SMOOTH_ANGLE.update({"Rock": 0.0, "Cliff": 55.0})


def MAT(name):
    """The kit material `BC_<name>` (created on first use)."""
    import bpy
    spec = MATS[name]
    mname = "BC_" + name
    mat = bpy.data.materials.get(mname)
    if mat is not None and mat.node_tree is not None and any(
            n.type == "TEX_IMAGE" and n.image is not None for n in mat.node_tree.nodes):
        return mat
    return tex_material(mname, spec["tex"], alpha=spec.get("alpha", False), rough=spec["rough"],
                        emission=spec.get("emission"), double=spec.get("double", False))


def collection_hidden(name, parent=None):
    """A kit collection: kept out of the map renders (pieces sit in a row at the origin)."""
    col = clear_collection(name)
    if parent is not None:
        import bpy
        for p in bpy.data.collections:
            if col.name in p.children and p is not parent:
                p.children.unlink(col)
        if col.name not in parent.children:
            sc_col = scene().collection
            if col.name in sc_col.children:
                sc_col.children.unlink(col)
            parent.children.link(col)
    col.hide_render = True
    return col


def export_kit(col, letter, manifest):
    """GLB/BC_Kit<letter>.glb (every object of col + a BC_Anchor<letter> 0.5-stud cube at the origin, Y-up,
    modifiers applied) + GLB/BC_Kit<letter>.json (the manifest)."""
    import json
    import bmesh
    import bpy
    an = "BC_Anchor%s" % letter
    abm = bmesh.new()
    bmesh.ops.create_cube(abm, size=0.5)
    mesh_object(an, abm, col, [])
    vl = bpy.context.view_layer
    for o in vl.objects:
        o.select_set(False)
    for o in col.all_objects:
        o.hide_set(False)
        o.select_set(True)
    path = os.path.join(GLB, "BC_Kit%s.glb" % letter)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_animations=False, export_yup=True, export_normals=True,
                              export_texcoords=True, export_materials="EXPORT", export_image_format="AUTO")
    jpath = os.path.join(GLB, "BC_Kit%s.json" % letter)
    with open(jpath, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)
    info = report(col)
    info.update({"glb": path, "kb": os.path.getsize(path) // 1024, "pieces": len(manifest)})
    return info


def write_manifest(letter, manifest):
    """Kit manifest only (no GLB) -- the build writes these; export.py writes the GLBs after approval."""
    import json
    with open(os.path.join(GLB, "BC_Kit%s.json" % letter), "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)


def save():
    import bpy
    bpy.ops.wm.save_as_mainfile(filepath=BLEND)


# ================================================================ terrain helpers (from apolaki/terrain.py)
def grid_mesh(name, P, UV, col, mats, closed_u=False, mat_index=None, flip=False):
    """P: (R, K, 3) rows x columns of points; UV: (R, K, 2). Quads between neighbours."""
    import bmesh
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    R, K = P.shape[0], P.shape[1]
    verts = [[bm.verts.new(tuple(P[r, k])) for k in range(K)] for r in range(R)]
    kmax = K if closed_u else K - 1
    for r in range(R - 1):
        for k in range(kmax):
            k2 = (k + 1) % K
            wrap = closed_u and k2 == 0
            quad = [verts[r][k], verts[r][k2], verts[r + 1][k2], verts[r + 1][k]]
            du0 = UV[r, 1] - UV[r, 0]
            du1 = UV[r + 1, 1] - UV[r + 1, 0]
            uvs = [UV[r, k], UV[r, k] + du0 if wrap else UV[r, k2],
                   UV[r + 1, k] + du1 if wrap else UV[r + 1, k2], UV[r + 1, k]]
            if flip:
                quad.reverse()
                uvs.reverse()
            try:
                f = bm.faces.new(quad)
            except ValueError:
                continue
            for loop, uv in zip(f.loops, uvs):
                loop[uvl].uv = (float(uv[0]), float(uv[1]))
            if mat_index is not None:
                f.material_index = mat_index(r, k)
    bm.normal_update()
    ob = mesh_object(name, bm, col, mats)
    for p in ob.data.polygons:
        p.use_smooth = True
    return ob


def polygon_cap(name, pts, z, col, mat, uv_scale):
    """Flat top polygon (CCW pts xy) at height z, planar tiling UV."""
    import bmesh
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new((x, y, z)) for x, y in pts]
    edges = [bm.edges.new((vs[i], vs[(i + 1) % len(vs)])) for i in range(len(vs))]
    bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=edges)
    for f in bm.faces:
        if f.normal.z < 0:
            f.normal_flip()
        for loop in f.loops:
            co = loop.vert.co
            loop[uvl].uv = (co.x / uv_scale, co.y / uv_scale)
    bm.normal_update()
    return mesh_object(name, bm, col, [mat])


def outline_normals(pts):
    pts = np.array(pts, dtype=float)
    t = np.roll(pts, -1, 0) - np.roll(pts, 1, 0)
    t /= np.linalg.norm(t, axis=1, keepdims=True) + 1e-9
    return np.stack([t[:, 1], -t[:, 0]], 1)  # outward for a CCW outline


def cliff_skirt(name, pts, z_top, z_bot, col, mat, seed, bulge=1.4, lip=0.35, closed=True, tile=24.0):
    """Rock wall hanging from a CCW outline: noisy bulges + strata (cliff texture, v = depth, 1 tile = `tile`)."""
    pts = np.array(pts, dtype=float)
    K = len(pts)
    seg = np.linalg.norm(np.roll(pts, -1, 0) - pts, axis=1)
    per = np.concatenate([[0], np.cumsum(seg)[:-1]])
    nrm = outline_normals(pts)
    depth = z_top - z_bot
    zs = [z_top + 0.25, z_top - 0.05, z_top - 0.9, z_top - 2.5]
    zz = z_top - 2.5
    while zz > z_bot:
        zz = max(z_bot, zz - max(2.5, depth / 9))
        zs.append(zz)
    P = np.zeros((len(zs), K, 3))
    UV = np.zeros((len(zs), K, 2))
    for r, z in enumerate(zs):
        d = z_top - z
        n1 = vnoise_xy(per / 7.0, np.full(K, d / 3.0) + seed, 4096, seed)
        n2 = vnoise_xy(per / 2.5, np.full(K, d / 1.5) + seed * 2, 4096, seed + 7)
        off = lip * (1 if r == 0 else 0) + (bulge * (n1 - 0.5) * 2 + 0.45 * (n2 - 0.5) * 2) * min(1.0, d / 1.5)
        off += 0.04 * d  # flares out toward the base
        P[r, :, 0] = pts[:, 0] + nrm[:, 0] * off
        P[r, :, 1] = pts[:, 1] + nrm[:, 1] * off
        P[r, :, 2] = z
        UV[r, :, 0] = per / tile
        UV[r, :, 1] = 1 - (max(0.0, d) / tile)
    return grid_mesh(name, P, UV, col, [mat], closed_u=closed, flip=True)


def superellipse(a, b, cx=0.0, cy=0.0, n=4.0, count=220, seed=0, wobble=2.5):
    pts = []
    for i in range(count):
        th = 2 * math.pi * i / count
        c, s = math.cos(th), math.sin(th)
        x = a * math.copysign(abs(c) ** (2 / n), c)
        y = b * math.copysign(abs(s) ** (2 / n), s)
        w = wobble * (vnoise_xy(np.array([th * 6.0]), np.array([seed * 1.0]), 4096, seed)[0] - 0.5) * 2
        r = math.hypot(x, y) + w
        ang = math.atan2(y, x)
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


def inside_superellipse(x, y, a, b, cx=0.0, cy=0.0, n=4.0, margin=0.0):
    return (np.abs((x - cx) / (a - margin)) ** n + np.abs((y - cy) / (b - margin)) ** n) < 1.0


def rounded_path(points, radius, per_corner=5, step=3.0):
    pts = [np.array(p, dtype=float) for p in points]
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        p0, p1, p2 = pts[i - 1], pts[i], pts[i + 1]
        d1 = (p1 - p0) / np.linalg.norm(p1 - p0)
        d2 = (p2 - p1) / np.linalg.norm(p2 - p1)
        a = p1 - d1 * radius
        b = p1 + d2 * radius
        for j in range(per_corner + 1):
            t = j / per_corner
            out.append((1 - t) ** 2 * a + 2 * (1 - t) * t * p1 + t * t * b)
    out.append(pts[-1])
    res = [out[0]]
    for q in out[1:]:
        p = res[-1]
        L = np.linalg.norm(q - p)
        n = max(1, int(L / step))
        for j in range(1, n + 1):
            res.append(p + (q - p) * j / n)
    return np.array(res)


def seg_dist(px, py, pts):
    """Distance from points (arrays) to a polyline."""
    px = np.asarray(px, dtype=float)
    py = np.asarray(py, dtype=float)
    d = np.full(px.shape, 1e9)
    pts = np.asarray(pts, dtype=float)
    for a, b in zip(pts[:-1], pts[1:]):
        ab = b - a
        t = np.clip(((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / max(ab @ ab, 1e-9), 0, 1)
        d = np.minimum(d, np.hypot(px - a[0] - ab[0] * t, py - a[1] - ab[1] * t))
    return d


def rbx(x, y, z):
    """Blender (x, y, z) -> the JSON pre-rotation frame (x, z, -y)."""
    return [round(float(x), 3), round(float(z), 3), round(float(-y), 3)]


# ================================================================ kit instancing (renders + layout JSON)
def load_manifests():
    import json
    man = {}
    for f in sorted(os.listdir(GLB)):
        if f.startswith("BC_Kit") and f.endswith(".json"):
            with open(os.path.join(GLB, f), encoding="utf-8") as fh:
                man.update(json.load(fh))
    return man


def instance(piece, man, col, loc, yaw=0.0, s=1.0, tag=""):
    """Linked duplicates of every object of kit `piece`, placed bottom-centre at loc, turned `yaw` (radians)."""
    import bpy
    from mathutils import Matrix
    e = man[piece]
    sv = (s, s, s) if not isinstance(s, (tuple, list)) else s
    M = (Matrix.Translation(loc) @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Diagonal((sv[0], sv[1], sv[2], 1.0))
         @ Matrix.Translation([-c for c in e["origin"]]))
    obs = []
    for name in e["objects"]:
        src = bpy.data.objects.get(name)
        if src is None:
            continue
        ob = bpy.data.objects.new("%s%s" % (name, tag), src.data)
        ob.matrix_world = M
        col.objects.link(ob)
        obs.append(ob)
    return obs


# ================================================================ shape helpers shared by the kits
def tube(bm, pts, radii, sides=8, v_tile=3.0, u_rep=1.0, cap=True, M=None):
    """Tapered tube along a polyline of (x, y, z) with wrapped UVs (u around, v = length / v_tile). Palm trunks,
    masts, ropes, curved spines. Appends to bm (UVs marked done)."""
    import bmesh
    from mathutils import Vector
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    P = [Vector(p) for p in pts]
    rings, length = [], 0.0
    for i, p in enumerate(P):
        d = (P[i + 1] - p) if i < len(P) - 1 else (p - P[i - 1])
        d.normalize()
        if i > 0:
            length += (p - P[i - 1]).length
        a = Vector((1, 0, 0)) if abs(d.z) > 0.9 else Vector((0, 0, 1))
        u = d.cross(a).normalized()
        w = d.cross(u).normalized()
        ring = [tmp.verts.new(p + (u * math.cos(2 * math.pi * k / sides) + w * math.sin(2 * math.pi * k / sides))
                              * radii[i]) for k in range(sides)]
        rings.append((ring, length))
    for (r0, l0), (r1, l1) in zip(rings[:-1], rings[1:]):
        for k in range(sides):
            k2 = (k + 1) % sides
            f = tmp.faces.new((r0[k], r0[k2], r1[k2], r1[k]))
            for lp, c in zip(f.loops, [(k / sides * u_rep, l0 / v_tile), ((k + 1) / sides * u_rep, l0 / v_tile),
                                       ((k + 1) / sides * u_rep, l1 / v_tile), (k / sides * u_rep, l1 / v_tile)]):
                lp[uvl].uv = c
    if cap:
        for ring, _l in (rings[0], rings[-1]):
            try:
                f = tmp.faces.new(ring)
                for lp in f.loops:
                    lp[uvl].uv = (0.5, 0.5)
            except ValueError:
                pass
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return _append(bm, tmp, M, uv=True)


def hull_rock(bm, center, size, r, n=22, flat_bottom=0.3, M=None):
    """Faceted stylised boulder: convex hull of jittered points on a squashed ellipsoid (box UVs later)."""
    import bmesh
    from mathutils import Matrix, Vector
    tmp = bmesh.new()
    for _ in range(n):
        d = Vector((r.normal(), r.normal(), r.normal())).normalized()
        d.z = max(d.z, -flat_bottom)
        k = r.uniform(0.8, 1.0)
        tmp.verts.new((d.x * size[0] * k, d.y * size[1] * k, d.z * size[2] * k))
    bmesh.ops.convex_hull(tmp, input=tmp.verts)
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    T = Matrix.Translation(Vector(center)) @ Matrix.Rotation(r.uniform(0, 6.28), 4, "Z")
    return _append(bm, tmp, (M @ T) if M is not None else T)


def leaf(bm, base, direction, length, width, col_u, bend=0.35, segs=3, M=None):
    """One geometry leaf / grass blade: a tapered, bending strip from `base` along `direction` (Blade material:
    v = 0 base -> 1 tip, u inside column `col_u` 0..3 of the blade atlas). Double-sided material, no alpha."""
    import bmesh
    from mathutils import Vector
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    d = Vector(direction).normalized()
    side = d.cross(Vector((0, 0, 1)))
    side = side.normalized() if side.length > 1e-4 else Vector((1, 0, 0))
    b = Vector(base)
    rows = []
    for s in range(segs + 1):
        t = s / segs
        p = b + d * length * t + Vector((0, 0, -bend * length * t * t))
        w = width * (math.sin(math.pi * min(1.0, 0.15 + t * 0.85)) if t < 1 else 0.0) + (0.02 if t < 1 else 0)
        if s == segs:
            rows.append((tmp.verts.new(p), None, t))
        else:
            rows.append((tmp.verts.new(p - side * w / 2), tmp.verts.new(p + side * w / 2), t))
    u0, u1 = (col_u + 0.2) / 4.0, (col_u + 0.8) / 4.0
    for (a0, b0, t0), (a1, b1, t1) in zip(rows[:-1], rows[1:]):
        if b1 is None:
            f = tmp.faces.new((a0, b0, a1))
            uvs = [(u0, t0), (u1, t0), ((u0 + u1) / 2, t1)]
        else:
            f = tmp.faces.new((a0, b0, b1, a1))
            uvs = [(u0, t0), (u1, t0), (u1, t1), (u0, t1)]
        for lp, c in zip(f.loops, uvs):
            lp[uvl].uv = c
    return _append(bm, tmp, M, uv=True)


def flower_head(bm, center, radius, swatch, petals=6, M=None):
    """Flat star flower facing up (Petal material, one swatch quadrant 0..3), a tiny cone so it reads from the side."""
    import bmesh
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    qx, qy = swatch % 2, swatch // 2
    cx, cy, cz = center
    mid = tmp.verts.new((cx, cy, cz + radius * 0.25))
    ring = []
    for k in range(petals * 2):
        a = 2 * math.pi * k / (petals * 2)
        rr = radius if k % 2 == 0 else radius * 0.45
        ring.append((tmp.verts.new((cx + rr * math.cos(a), cy + rr * math.sin(a), cz)), math.cos(a) * rr / radius,
                     math.sin(a) * rr / radius))
    for k in range(len(ring)):
        a, b = ring[k], ring[(k + 1) % len(ring)]
        f = tmp.faces.new((mid, a[0], b[0]))
        for lp, (du, dv) in zip(f.loops, [(0, 0), (a[1], a[2]), (b[1], b[2])]):
            lp[uvl].uv = ((qx + 0.5 + 0.45 * du) / 2, 1 - (qy + 0.5 - 0.45 * dv) / 2)
    return _append(bm, tmp, M, uv=True)


def kit_preview(col, name, **kw):
    """Render one kit collection on its own (Cycles, auto-framed): renders/<name>.png."""
    col.hide_render = False
    try:
        return preview(col, render_path(name), **kw)
    finally:
        col.hide_render = True


def ship_hull(hull_bm, deck_bm, L, W, D, K, stern_raise=3.0, bow_raise=2.0, wall=0.7, bulwark=1.6, N=26, M=None):
    """Wooden ship hull around the WATERLINE origin (z = 0), bow toward +X. L long, W beam, D freeboard amidships,
    K keel depth. Outer skin + rim + inner bulwark go to hull_bm; the (sheered) deck to deck_bm. Box UVs later."""
    import bmesh
    hb, db = bmesh.new(), bmesh.new()
    stations = []
    for i in range(N + 1):
        xn = -1.0 + 2.0 * i / N
        xn = min(xn, 0.985)
        w = W / 2 * (1 - max(0.0, xn) ** 2.2) ** 0.55 * (1 - 0.12 * max(0.0, -xn) ** 2)
        w = max(w, 0.35)
        h = D + bow_raise * max(0.0, xn) ** 2 + stern_raise * max(0.0, -xn - 0.45) / 0.55
        k = K * (1 - abs(xn) ** 6)
        x = xn * L / 2
        wi = max(w - wall, 0.1)
        prof = [(-wi, h - bulwark), (-wi, h), (-w, h), (-w * 1.03, h * 0.5), (-w, 0.0), (-w * 0.82, -k * 0.5),
                (-w * 0.42, -k * 0.9), (0.0, -k)]
        prof = prof + [(-y, z) for y, z in reversed(prof[:-1])]
        stations.append([hb.verts.new((x, y, z)) for y, z in prof])
    for a, b in zip(stations[:-1], stations[1:]):
        for j in range(len(a) - 1):
            try:
                hb.faces.new((a[j], a[j + 1], b[j + 1], b[j]))
            except ValueError:
                pass
    for ring in (stations[0], stations[-1]):  # transom + stem caps (the deck closes the top)
        outer = ring[1:-1]
        try:
            hb.faces.new(outer)
        except ValueError:
            pass
    bmesh.ops.recalc_face_normals(hb, faces=hb.faces)
    # deck: port inner-bottom -> starboard inner-bottom, 4 strips across
    rows = []
    for ring in stations:
        p0, p1 = ring[0].co, ring[-1].co
        rows.append([db.verts.new(p0.lerp(p1, t)) for t in np.linspace(0, 1, 5)])
    for a, b in zip(rows[:-1], rows[1:]):
        for j in range(4):
            db.faces.new((a[j], b[j], b[j + 1], a[j + 1]))
    bmesh.ops.recalc_face_normals(db, faces=db.faces)
    for f in db.faces:
        if f.normal.z < 0:
            f.normal_flip()
    _append(hull_bm, hb, M)
    _append(deck_bm, db, M)
    return stations


def sail(bm, x, y0, y1, z0, z1, belly=1.6, nu=5, nv=5, M=None):
    """Square sail across the ship (YZ plane at x) bellied toward +X; UVs 0..1 = the whole Jolly Roger image."""
    import bmesh
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    V = [[None] * (nu + 1) for _ in range(nv + 1)]
    for j in range(nv + 1):
        for i in range(nu + 1):
            u, v = i / nu, j / nv
            b = belly * math.sin(math.pi * u) * math.sin(math.pi * (0.15 + 0.85 * v))
            V[j][i] = tmp.verts.new((x + b, y0 + (y1 - y0) * u, z0 + (z1 - z0) * v))
    for j in range(nv):
        for i in range(nu):
            f = tmp.faces.new((V[j][i], V[j][i + 1], V[j + 1][i + 1], V[j + 1][i]))
            for lp, c in zip(f.loops, [(i / nu, j / nv), ((i + 1) / nu, j / nv), ((i + 1) / nu, (j + 1) / nv),
                                       (i / nu, (j + 1) / nv)]):
                lp[uvl].uv = (1 - c[0], c[1])
    return _append(bm, tmp, M, uv=True)


def flag_card(bm, base, w, h, wave=0.5, M=None):
    """Waving flag from a pole top at `base` (x, y, z) flying toward +X (UV 0..1)."""
    import bmesh
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap")
    nu, nv = 6, 2
    V = [[tmp.verts.new((base[0] + w * i / nu, base[1] + wave * math.sin(i / nu * 5.0) * (i / nu),
                         base[2] - h + h * j / nv)) for i in range(nu + 1)] for j in range(nv + 1)]
    for j in range(nv):
        for i in range(nu):
            f = tmp.faces.new((V[j][i], V[j][i + 1], V[j + 1][i + 1], V[j + 1][i]))
            for lp, c in zip(f.loops, [(i / nu, j / nv), ((i + 1) / nu, j / nv), ((i + 1) / nu, (j + 1) / nv),
                                       (i / nu, (j + 1) / nv)]):
                lp[uvl].uv = c
    return _append(bm, tmp, M, uv=True)
