# Alamat Defense Lobby "Holy Coast" kit -- shared helpers for the Blender build scripts (B172).
# Adapted from tools/maps/apolaki/common.py (the noise / paint helpers are copied verbatim) plus the
# bmesh kit helpers every kit script uses. Runs inside Blender 5.x (bpy + numpy), background or UI.
#
# apolaki ALSO has a module called `common`, so load this one under a unique name:
#   import importlib.util, sys
#   LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
#   _s = importlib.util.spec_from_file_location("al_common", LOBBY + r"\common.py")
#   C = importlib.util.module_from_spec(_s); sys.modules["al_common"] = C; _s.loader.exec_module(C)
#
# Conventions (README.md): 1 Blender unit = 1 stud, Z up, piece origin = bottom-centre, FRONT faces -Y,
# objects are <Piece>__<Mat> with ONE material each. Typical kit script:
#   col = C.clear_collection("AL_KitA"); row = C.Row(); manifest = {}
#   P = C.Piece("AL_Pier", row.next(5))
#   C.box(P.bm("Marble"), -2.5, -2.5, 0, 2.5, 2.5, 30, bevel=0.3)
#   C.drum(P.bm("Gold"), (0, 0), 30, 1, 3.0)
#   P.done(col, manifest)
#   C.export_kit(col, "A", manifest); C.preview(col, C.render_path("kitA"))
#   bpy.ops.wm.save_mainfile()
# Every primitive appends to a bmesh and leaves UVs to Piece.done()/finish(), which box-projects them
# world-scaled by the material (UV_SCALE). Pass uv=<studs per tile> to lathe()/torus() for a wrapped
# (around x along-profile) mapping instead -- use it on TealTile domes, MarbleBlock drums and Gold
# rings (torus uv=4: the gold band runs along the ring like a specular streak). rect_uv() fits one
# tile over a banner / sign; disc_uv() maps the Mandala. Piece.uv_scale / .smooth override per material.
import json
import math
import os

import numpy as np

BASE = r"C:\Users\Joseph Elton Estilo\Downloads\Alamat_Lobby"
TEX = os.path.join(BASE, "tex")
GLB = os.path.join(BASE, "glb")
RENDERS = os.path.join(BASE, "renders")
BLEND = os.path.join(BASE, "blend")
TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
for _d in (TEX, GLB, RENDERS, BLEND):
    os.makedirs(_d, exist_ok=True)

RNG = np.random.default_rng(1172)


def rng(seed):
    return np.random.default_rng(seed)


# ================================================================ noise (verbatim from apolaki)
def _resize_bilinear(a, h, w, wrap=True):
    """Bilinear upsample of a 2-D array to (h, w); wrap=True keeps it tileable."""
    sh, sw = a.shape
    ys = np.linspace(0, sh, h, endpoint=False) if wrap else np.linspace(0, sh - 1, h)
    xs = np.linspace(0, sw, w, endpoint=False) if wrap else np.linspace(0, sw - 1, w)
    y0 = np.floor(ys).astype(int)
    x0 = np.floor(xs).astype(int)
    fy = (ys - y0)[:, None]
    fx = (xs - x0)[None, :]
    # smoothstep the fractions for softer, painterly blobs
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    if wrap:
        y1 = (y0 + 1) % sh
        x1 = (x0 + 1) % sw
        y0 %= sh
        x0 %= sw
    else:
        y1 = np.minimum(y0 + 1, sh - 1)
        x1 = np.minimum(x0 + 1, sw - 1)
    a00 = a[y0][:, x0]
    a01 = a[y0][:, x1]
    a10 = a[y1][:, x0]
    a11 = a[y1][:, x1]
    return (a00 * (1 - fx) + a01 * fx) * (1 - fy) + (a10 * (1 - fx) + a11 * fx) * fy


def value_noise(h, w, cells, seed=0, wrap=True):
    r = rng(seed)
    ch = max(1, int(cells * h / max(h, w)))
    cw = max(1, int(cells * w / max(h, w)))
    return _resize_bilinear(r.random((ch, cw)), h, w, wrap)


def fbm(h, w, base_cells=4, octaves=5, seed=0, gain=0.5, wrap=True):
    out = np.zeros((h, w))
    amp, total, cells = 1.0, 0.0, base_cells
    for o in range(octaves):
        out += amp * value_noise(h, w, cells, seed + o * 101, wrap)
        total += amp
        amp *= gain
        cells *= 2
    return out / total


_LAT = {}


def vnoise_xy(x, y, period, seed=0):
    """Value noise at arbitrary coords (any shape); tileable with integer `period` lattice."""
    P = int(min(period, 512))
    key = (P, seed)
    lat = _LAT.get(key)
    if lat is None:
        lat = rng(seed).random((P, P))
        _LAT[key] = lat
    x = np.asarray(x, dtype=np.float64)
    y = np.asarray(y, dtype=np.float64)
    xi = np.floor(x).astype(np.int64)
    yi = np.floor(y).astype(np.int64)
    fx = x - xi
    fy = y - yi
    fx = fx * fx * fx * (fx * (fx * 6 - 15) + 10)
    fy = fy * fy * fy * (fy * (fy * 6 - 15) + 10)
    x0, x1 = xi % P, (xi + 1) % P
    y0, y1 = yi % P, (yi + 1) % P
    a = lat[y0, x0] * (1 - fx) + lat[y0, x1] * fx
    b = lat[y1, x0] * (1 - fx) + lat[y1, x1] * fx
    return a * (1 - fy) + b * fy


def fbm_xy(x, y, period, octaves=5, seed=0, gain=0.5, rotate=True):
    """Fractal value noise with a rotation + offset per octave (kills grid / plaid artefacts).
    x, y are in lattice units of the FIRST octave; tileable when the rotation is off."""
    out = np.zeros(np.shape(x))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        f = 2 ** o
        if rotate:
            ang = 0.61 * (o + 1) + seed * 0.013
            ca, sa = math.cos(ang), math.sin(ang)
            xx = (x * ca - y * sa) * f + 17.3 * o
            yy = (x * sa + y * ca) * f + 9.1 * o
            per = 512
        else:
            xx, yy, per = x * f, y * f, int(period * f)
        out += amp * vnoise_xy(xx, yy, per, seed + o * 31)
        total += amp
        amp *= gain
    return out / total


def warped(x, y, period, seed, warp=1.4, octaves=5):
    """Tileable, organic (domain-warped) fractal noise in 0..1 (apolaki textures.py)."""
    wx = fbm_xy(x, y, period, 3, seed + 1, rotate=False)
    wy = fbm_xy(x + 5.2, y + 1.3, period, 3, seed + 2, rotate=False)
    n = fbm_xy(x + warp * wx, y + warp * wy, period, octaves, seed, rotate=False)
    return smoothstep(0.18, 0.82, n)


def grid(h, w, sx, sy=None):
    """Coordinate grids in lattice units: sx cells across the width."""
    sy = sx * h / w if sy is None else sy
    y, x = np.mgrid[0:h, 0:w]
    return x / w * sx, y / h * sy


def stretch_noise(h, w, cells_y, cells_x, seed=0, wrap=True):
    """Anisotropic noise (streaks) -- painted strokes / strata."""
    r = rng(seed)
    return _resize_bilinear(r.random((max(1, cells_y), max(1, cells_x))), h, w, wrap)


def blur(a, k=2, wrap=True):
    """Cheap box blur (repeated) on a 2-D or 3-D array."""
    out = a.astype(np.float64)
    for _ in range(k):
        if wrap:
            out = (out + np.roll(out, 1, 0) + np.roll(out, -1, 0) + np.roll(out, 1, 1) + np.roll(out, -1, 1)) / 5.0
        else:
            p = np.pad(out, [(1, 1), (1, 1)] + [(0, 0)] * (out.ndim - 2), mode="edge")
            out = (p[1:-1, 1:-1] + p[:-2, 1:-1] + p[2:, 1:-1] + p[1:-1, :-2] + p[1:-1, 2:]) / 5.0
    return out


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def ramp(t, stops):
    """Colour ramp: stops = [(pos, (r,g,b) 0-255), ...] -> HxWx3 float 0-1."""
    t = np.clip(t, 0, 1)
    pos = np.array([s[0] for s in stops])
    cols = np.array([s[1] for s in stops], dtype=np.float64) / 255.0
    out = np.zeros(np.shape(t) + (3,))
    for c in range(3):
        out[..., c] = np.interp(t, pos, cols[:, c])
    return out


def posterize(t, levels, softness=0.35):
    """Soft cel bands: anime-style stepped tones without hard aliasing."""
    s = t * levels
    f = np.floor(s)
    frac = s - f
    frac = smoothstep(0.5 - softness / 2, 0.5 + softness / 2, frac)
    return (f + frac) / levels


def mix(a, b, m):
    m = m[..., None] if (np.ndim(m) == np.ndim(a) - 1) else m
    return a * (1 - m) + b * m


def rgb(c):
    """(r, g, b) 0-255 -> numpy 0-1 (broadcasts against HxWx3)."""
    return np.array(c, dtype=np.float64) / 255.0


def stamp_ellipses(h, w, n, rx, ry, seed=0, angle_jitter=math.pi, wrap=True, shade=True):
    """Paint n soft ellipses ('leaves' / strokes). Returns (coverage, tone) arrays."""
    r = rng(seed)
    cov = np.zeros((h, w))
    tone = np.zeros((h, w))
    yy, xx = np.mgrid[-int(ry * 2):int(ry * 2) + 1, -int(rx * 2):int(rx * 2) + 1]
    for _ in range(n):
        cx, cy = r.random() * w, r.random() * h
        ang = r.normal(0, angle_jitter)
        ca, sa = math.cos(ang), math.sin(ang)
        u = (xx * ca + yy * sa) / rx
        v = (-xx * sa + yy * ca) / ry
        d = u * u + v * v
        m = np.clip((1.0 - d) * 3.0, 0, 1)
        if not np.any(m):
            continue
        t = r.random() if not shade else np.clip(0.55 - v * 0.35 + r.normal(0, 0.08), 0, 1)
        ys = (yy[:, 0] + int(cy))
        xs = (xx[0, :] + int(cx))
        if wrap:
            ys %= h
            xs %= w
            sub = np.ix_(ys, xs)
        else:
            ok_y = (ys >= 0) & (ys < h)
            ok_x = (xs >= 0) & (xs < w)
            m = m[ok_y][:, ok_x]
            t = t[ok_y][:, ok_x] if np.ndim(t) else t
            sub = np.ix_(ys[ok_y], xs[ok_x])
        cur = cov[sub]
        tone[sub] = np.where(m > 0.05, t * m + tone[sub] * (1 - m), tone[sub])
        cov[sub] = np.maximum(cur, m)
    return cov, tone


# ================================================================ image IO
def save_png(name, rgb_img, alpha=None):
    """rgb HxWx3 (0-1, row 0 = TOP of the image). Saves TEX/name.png, returns the path."""
    import bpy
    h, w = rgb_img.shape[:2]
    a = np.ones((h, w)) if alpha is None else np.clip(alpha, 0, 1)
    rgba = np.dstack([np.clip(rgb_img, 0, 1), a])[::-1]  # Blender stores bottom row first
    img = bpy.data.images.get(name)
    if img is not None and (img.size[0] != w or img.size[1] != h):
        bpy.data.images.remove(img)
        img = None
    if img is None:
        img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(rgba.astype(np.float32).ravel())
    path = os.path.join(TEX, name + ".png")
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    img.reload()
    return path


def load_image(name):
    import bpy
    path = os.path.join(TEX, name + ".png")
    img = bpy.data.images.get(name)
    if img is None:
        img = bpy.data.images.load(path, check_existing=True)
        img.name = name
    return img


# ================================================================ scene / collections
def scene():
    import bpy
    return bpy.context.scene


def collection(name, parent=None):
    import bpy
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
    par = parent or scene().collection
    if col.name not in par.children:
        par.children.link(col)
    return col


def clear_collection(name):
    """Empty (or create) a collection linked to the current scene; returns it."""
    import bpy
    col = collection(name)
    for o in list(col.objects):
        me = o.data if o.type == "MESH" else None
        bpy.data.objects.remove(o, do_unlink=True)
        if me is not None and me.users == 0:
            bpy.data.meshes.remove(me)
    return col


# ================================================================ materials
# name -> texture, roughness, studs per texture tile (None = keep the primitive's own UVs),
# optional emission strength, alpha (clip), double-sided.
MATS = {
    "Marble":      dict(tex="marble", rough=0.55, uv=8.0),
    "MarbleBlock": dict(tex="marble_block", rough=0.6, uv=8.0),
    "Gold":        dict(tex="gold", rough=0.3, uv=4.0),
    "TealTile":    dict(tex="teal_tile", rough=0.35, uv=6.0),
    "Pave":        dict(tex="pave", rough=0.8, uv=8.0),
    "Crystal":     dict(tex="crystal", rough=0.15, uv=6.0, emission=1.2),
    "Capiz":       dict(tex="capiz", rough=0.5, uv=4.0, emission=0.25),
    "Cloth":       dict(tex="cloth", rough=0.9, uv=8.0, double=True),
    "Bronze":      dict(tex="bronze", rough=0.45, uv=4.0),
    "Mandala":     dict(tex="mandala", rough=0.6, uv=None, alpha=True),
}
UV_SCALE = {k: v["uv"] for k, v in MATS.items()}
# edges sharper than this (degrees) stay hard; 0 = faceted (crystals)
SMOOTH_ANGLE = {k: (0.0 if k == "Crystal" else 40.0) for k in MATS}


def tex_material(name, tex_name, alpha=False, rough=0.9, emission=None, double=False):
    """A Principled material reading TEX/<tex_name>.png -- glTF exports it as baseColorTexture."""
    import bpy
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    if mat.node_tree is None:
        mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = load_image(tex_name)
    nt.nodes.active = tex
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha:
        # Math(ROUND) between texture alpha and BSDF alpha = glTF alphaMode MASK (cutout)
        rnd = nt.nodes.new("ShaderNodeMath")
        rnd.operation = "ROUND"
        nt.links.new(tex.outputs["Alpha"], rnd.inputs[0])
        nt.links.new(rnd.outputs[0], bsdf.inputs["Alpha"])
        for attr, val in (("surface_render_method", "DITHERED"), ("blend_method", "CLIP")):
            try:
                setattr(mat, attr, val)
            except Exception:
                pass
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = 0.0
    if emission is not None:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.use_backface_culling = not (alpha or double)
    return mat


def MAT(name):
    """The kit material for one of the 10 MATS names (created on first use as `AL_<name>`)."""
    import bpy
    spec = MATS[name]
    mname = "AL_" + name
    mat = bpy.data.materials.get(mname)
    if mat is not None and mat.node_tree is not None and any(
            n.type == "TEX_IMAGE" and n.image is not None for n in mat.node_tree.nodes):
        return mat
    return tex_material(mname, spec["tex"], alpha=spec.get("alpha", False), rough=spec["rough"],
                        emission=spec.get("emission"), double=spec.get("double", False))


# ================================================================ mesh objects
def mesh_object(name, bm, col, mats=()):
    """bmesh -> new object `name` in col (replaces an older object of that name; frees bm)."""
    import bpy
    old = bpy.data.objects.get(name)
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    me = bpy.data.meshes.get(name)
    if me is not None and me.users == 0:
        bpy.data.meshes.remove(me)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for m in mats:
        me.materials.append(m)
    ob = bpy.data.objects.new(name, me)
    col.objects.link(ob)
    return ob


def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


def report(col):
    """{object: tris} for a collection, plus total and the biggest."""
    tris = {o.name: tri_count(o) for o in col.all_objects if o.type == "MESH"}
    big = max(tris.items(), key=lambda kv: kv[1]) if tris else ("", 0)
    return {"objects": len(tris), "total_tris": sum(tris.values()), "max": list(big),
            "over_20k": [k for k, v in tris.items() if v > 20000]}


def zfight_report(col, tol=0.06, limit=25):
    """Z-fighting check (user rule 2026-10-24: always be wary of z-fighting). Within each kit piece (<Piece>__<Mat>),
    finds axis-aligned faces that face the SAME way, lie within `tol` studs of each other and overlap (one face's centre
    inside the other). Faces sharing a vertex are skipped (fans, bevels). Returns {"count", "hits": [...]}.
    Fix every hit before export: lift/sink one face (>= 0.1), or stop a trim short of the face it would sit flush on."""
    from mathutils import Vector

    def inside(pt, poly):
        x, y = pt
        c = False
        for i in range(len(poly)):
            x1, y1 = poly[i]
            x2, y2 = poly[i - 1]
            if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1 + 1e-12) + x1:
                c = not c
        return c

    faces = {}  # (piece, axis, sign) -> [(coord, poly2d, centre2d, obj, vertkeys)]
    for ob in col.all_objects:
        if ob.type != "MESH" or "__" not in ob.name:
            continue
        piece = ob.name.split("__")[0]
        mw = ob.matrix_world
        rot = mw.to_3x3()
        verts = [mw @ v.co for v in ob.data.vertices]
        for p in ob.data.polygons:
            n = (rot @ p.normal).normalized()
            for axis in range(3):
                if abs(n[axis]) > 0.999:
                    o = [i for i in range(3) if i != axis]
                    pts = [verts[i] for i in p.vertices]
                    poly = [(q[o[0]], q[o[1]]) for q in pts]
                    cen = (sum(q[0] for q in poly) / len(poly), sum(q[1] for q in poly) / len(poly))
                    keys = {(round(q.x, 3), round(q.y, 3), round(q.z, 3)) for q in pts}
                    faces.setdefault((piece, axis, n[axis] > 0), []).append(
                        (sum(q[axis] for q in pts) / len(pts), poly, cen, ob.name, keys, p.area))
                    break
    def covered(piece, axis, sign, f):
        # a face pressed against an opposite-facing coplanar face (a block resting on it, the ground under a base) is
        # buried: its fight can never be seen
        for c in faces.get((piece, axis, not sign), ()):
            if abs(c[0] - f[0]) <= tol and inside(f[2], c[1]):
                return True
        return False

    zmin = {}
    for (piece, axis, sign), lst in faces.items():
        if axis == 2:
            zmin[piece] = min([zmin.get(piece, 1e9)] + [f[0] for f in lst])
    hits = []
    for (piece, axis, sign), lst in faces.items():
        lst.sort(key=lambda f: f[0])
        for i, a in enumerate(lst):
            for b in lst[i + 1:]:
                if b[0] - a[0] > tol:
                    break
                if a[4] & b[4] or min(a[5], b[5]) < 0.02:
                    continue
                if axis == 2 and not sign and a[0] - zmin.get(piece, 0.0) < tol:
                    continue  # bottoms standing on the ground
                if covered(piece, axis, sign, a) or covered(piece, axis, sign, b):
                    continue
                if inside(a[2], b[1]) or inside(b[2], a[1]):
                    hits.append({"piece": piece, "a": a[3], "b": b[3], "axis": "XYZ"[axis] + ("+" if sign else "-"),
                                 "at": round(a[0], 3), "gap": round(b[0] - a[0], 3)})
    return {"count": len(hits), "hits": hits[:limit]}


# ================================================================ bmesh primitives
# All append to `bm` (a bmesh.types.BMesh) and return the new faces. Sizes in studs. Each one is
# built in a scratch bmesh, optionally transformed by a mathutils Matrix `M`, then copied in.
_UVFLAG = "al_uv"  # face int layer: 1 = this face already has its UVs (skip the box pass)


def new_bm():
    import bmesh
    return bmesh.new()


def _flag(bm):
    lay = bm.faces.layers.int.get(_UVFLAG)
    return lay if lay is not None else bm.faces.layers.int.new(_UVFLAG)


def _append(dst, src, M=None, uv=False):
    """Copy src into dst (transformed by M), keeping src UVs + marking them done when uv=True."""
    suv = src.loops.layers.uv.active if uv else None
    duv = dst.loops.layers.uv.verify() if suv is not None else None
    flag = _flag(dst)
    mirror = M is not None and M.determinant() < 0
    vmap = {v: dst.verts.new((M @ v.co) if M is not None else v.co.copy()) for v in src.verts}
    faces = []
    for f in src.faces:
        loops = list(f.loops)
        if mirror:
            loops.reverse()
        try:
            nf = dst.faces.new([vmap[lp.vert] for lp in loops])
        except ValueError:  # duplicate face
            continue
        if suv is not None:
            for lp, nl in zip(loops, nf.loops):
                nl[duv].uv = lp[suv].uv
            nf[flag] = 1
        faces.append(nf)
    src.free()
    return faces


def _matrix(loc=(0, 0, 0), rot=(0, 0, 0), M=None):
    from mathutils import Euler, Matrix, Vector
    T = Matrix.Translation(Vector(loc)) @ Euler(rot, "XYZ").to_matrix().to_4x4()
    return (M @ T) if M is not None else T


def bevel_sharp(bm, offset, segments=2, angle=30.0):
    """Round every edge of bm sharper than `angle` degrees (in place)."""
    import bmesh
    if offset <= 0:
        return
    lim = math.radians(angle)
    edges = [e for e in bm.edges if e.is_manifold and e.calc_face_angle(0.0) > lim]
    if edges:
        bmesh.ops.bevel(bm, geom=edges, offset=offset, offset_type="OFFSET", segments=segments,
                        profile=0.5, affect="EDGES", clamp_overlap=True)


def block(bm, center, size, bevel=0.15, seg=2, rot=(0, 0, 0), M=None):
    """Bevelled box: centre (x, y, z), size (sx, sy, sz), Euler rot (radians)."""
    import bmesh
    from mathutils import Matrix
    tmp = bmesh.new()
    bmesh.ops.create_cube(tmp, size=1.0, matrix=Matrix.Diagonal((size[0], size[1], size[2], 1.0)))
    bevel_sharp(tmp, min(bevel, 0.45 * min(size)), seg)
    return _append(bm, tmp, _matrix(center, rot, M))


def box(bm, x0, y0, z0, x1, y1, z1, bevel=0.15, seg=2, M=None):
    """Bevelled box by extents."""
    return block(bm, ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), (abs(x1 - x0), abs(y1 - y0), abs(z1 - z0)),
                 bevel, seg, M=M)


def prism(bm, pts_xz, y0, y1, bevel=0.15, seg=2, angle=30.0, M=None):
    """Extrude a 2-D outline (x, z) -- convex or not, no holes -- from y0 to y1 (front = -Y).
    Use for spandrels, pediments, flat rays, arch walls, gables."""
    import bmesh
    tmp = bmesh.new()
    front = [tmp.verts.new((x, y0, z)) for x, z in pts_xz]
    back = [tmp.verts.new((x, y1, z)) for x, z in pts_xz]
    tmp.faces.new(front)
    tmp.faces.new(list(reversed(back)))
    n = len(pts_xz)
    for i in range(n):
        j = (i + 1) % n
        tmp.faces.new((front[i], front[j], back[j], back[i]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    bevel_sharp(tmp, bevel, seg, angle)
    return _append(bm, tmp, M)


def arch_curve(span, spring, kind="round", n=12, point=1.35):
    """Intrados of an arch as (x, z) points from the LEFT springer (-span/2, spring) over the crown
    to the RIGHT one. kind 'round' = semicircle; 'pointed' = two arcs of radius point*span/2."""
    h = span / 2.0
    pts = []
    if kind == "round" or point <= 1.0:
        for i in range(n + 1):
            a = math.pi - math.pi * i / n
            pts.append((h * math.cos(a), spring + h * math.sin(a)))
        return pts
    R = point * h
    c = R - h
    top = math.sqrt(R * R - c * c)
    a1 = math.atan2(top, -c)
    half = max(2, n // 2)
    for i in range(half + 1):  # left arc, centre (+c, spring)
        a = math.pi + (a1 - math.pi) * i / half
        pts.append((c + R * math.cos(a), spring + R * math.sin(a)))
    pts[-1] = (0.0, spring + top)
    for i in range(half - 1, -1, -1):  # mirror -> right arc
        x, z = pts[i]
        pts.append((-x, z))
    return pts


def arch_outline(width, height, span, spring, kind="round", n=12, point=1.35):
    """Outline (x, z) of a wall width x height (bottom at z=0) with an arched opening `span` wide,
    open to the floor, whose jambs rise to `spring`. (Windows with a sill: arch_frame + slabs.)"""
    w = width / 2.0
    curve = arch_curve(span, spring, kind, n, point)
    return [(-w, 0.0), (-span / 2, 0.0)] + curve + [(span / 2, 0.0), (w, 0.0), (w, height), (-w, height)]


def arch_wall(bm, width, height, depth, span, spring, kind="round", y0=None, bevel=0.15, n=12, point=1.35, M=None):
    """Wall slab (centred on x, bottom at z=0, from y0 to y0+depth; default centred on y) with an arched
    opening open to the floor -- an arcade bay, a gate, a doorway."""
    y0 = -depth / 2 if y0 is None else y0
    return prism(bm, arch_outline(width, height, span, spring, kind, n, point), y0, y0 + depth, bevel, M=M)


def arch_frame(bm, span, spring, sill, depth, frame=1.0, kind="round", y0=None, bevel=0.12, n=12, point=1.35, M=None):
    """A moulded frame (band `frame` wide) around an arched window opening: jambs from z=sill to
    `spring` plus the arch -- built as two mirrored halves so each outline is hole-free."""
    y0 = -depth / 2 if y0 is None else y0
    inner = arch_curve(span, spring, kind, n, point)
    outer = arch_curve(span + 2 * frame, spring, kind, n, point)
    mid = len(inner) // 2
    faces = []
    for side in (-1, 1):
        if side < 0:
            ii, oo = inner[:mid + 1], outer[:mid + 1]
        else:
            ii, oo = inner[mid:], outer[mid:]
        ii = [(x, z) for x, z in ii]
        oo = [(x, z) for x, z in oo]
        if side < 0:
            pts = [(oo[0][0], sill), (ii[0][0], sill)] + ii + list(reversed(oo))
        else:
            pts = ii + [(ii[-1][0], sill), (oo[-1][0], sill)] + list(reversed(oo))
        faces += prism(bm, pts, y0, y0 + depth, bevel, M=M)
    return faces


def round_profile(pts, radius, seg=2):
    """Round the interior corners of a 2-D polyline (lathe profiles) -> chunky bevelled silhouettes."""
    from mathutils import Vector
    if radius <= 0 or len(pts) < 3:
        return list(pts)
    out = [tuple(pts[0])]
    for i in range(1, len(pts) - 1):
        p0, p1, p2 = Vector(pts[i - 1]), Vector(pts[i]), Vector(pts[i + 1])
        a, b = p1 - p0, p2 - p1
        la, lb = a.length, b.length
        if la < 1e-6 or lb < 1e-6 or a.angle(b, 0.0) < math.radians(6):
            out.append(tuple(p1))
            continue
        r = min(radius, 0.45 * la, 0.45 * lb)
        q0, q2 = p1 - a.normalized() * r, p1 + b.normalized() * r
        for k in range(seg + 1):
            t = k / seg
            q = q0 * (1 - t) ** 2 + p1 * 2 * t * (1 - t) + q2 * t * t
            out.append((q.x, q.y))
    out.append(tuple(pts[-1]))
    return out


def ellipse_profile(r, h, z0=0.0, n=10, tip=0.0):
    """Quarter-ellipse dome profile from (r, z0) to the axis at z0+h (+ an onion `tip` point)."""
    pts = [(r * math.cos(t), z0 + h * math.sin(t)) for t in np.linspace(0, math.pi / 2, n + 1)]
    pts[-1] = (0.0, z0 + h)
    if tip > 0:
        pts[-1] = (r * 0.06, z0 + h * 0.985)
        pts.append((0.0, z0 + h + tip))
    return pts


def lathe(bm, profile, sides=24, center=(0, 0, 0), phase=0.0, uv=None, cap=True, M=None):
    """Revolve a profile [(r, z), ...] (bottom -> outside -> top) about Z: vases, balusters, domes,
    column bases, drums. r == 0 points become poles. uv=<studs per tile> writes wrapped UVs
    (u around, v along the profile) and marks them done; None leaves them to the box pass."""
    import bmesh
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap") if uv else None
    angs = [phase + 2 * math.pi * k / sides for k in range(sides)]
    rings = []
    for r, z in profile:
        if r < 1e-5:
            rings.append([tmp.verts.new((0.0, 0.0, z))])
        else:
            rings.append([tmp.verts.new((r * math.cos(a), r * math.sin(a), z)) for a in angs])
    s = [0.0]
    for (r0, z0), (r1, z1) in zip(profile[:-1], profile[1:]):
        s.append(s[-1] + math.hypot(r1 - r0, z1 - z0))
    rmax = max(r for r, _ in profile)
    nu = max(1, round(2 * math.pi * rmax / uv)) if uv else 1

    def setuv(f, coords):
        if uvl is not None:
            for lp, c in zip(f.loops, coords):
                lp[uvl].uv = c

    for i in range(len(rings) - 1):
        A, B = rings[i], rings[i + 1]
        if len(A) == 1 and len(B) == 1:
            continue
        va, vb = s[i] / uv if uv else 0, s[i + 1] / uv if uv else 0
        for k in range(sides):
            k2 = (k + 1) % sides
            u0, u1 = k / sides * nu, (k + 1) / sides * nu
            if len(A) == 1:
                f = tmp.faces.new((A[0], B[k2], B[k]))
                setuv(f, [((u0 + u1) / 2, va), (u1, vb), (u0, vb)])
            elif len(B) == 1:
                f = tmp.faces.new((A[k], A[k2], B[0]))
                setuv(f, [(u0, va), (u1, va), ((u0 + u1) / 2, vb)])
            else:
                f = tmp.faces.new((A[k], A[k2], B[k2], B[k]))
                setuv(f, [(u0, va), (u1, va), (u1, vb), (u0, vb)])
    if cap:
        sc = uv or 8.0
        if len(rings[0]) > 1:
            f = tmp.faces.new(list(reversed(rings[0])))
            setuv(f, [(lp.vert.co.x / sc, lp.vert.co.y / sc) for lp in f.loops])
        if len(rings[-1]) > 1:
            f = tmp.faces.new(rings[-1])
            setuv(f, [(lp.vert.co.x / sc, lp.vert.co.y / sc) for lp in f.loops])
    return _append(bm, tmp, _matrix(center, (0, 0, 0), M), uv=bool(uv))


def drum(bm, center_xy, z0, h, r, r_top=None, sides=24, bevel=0.15, uv=None, M=None):
    """Bevelled cylinder / frustum from z0 to z0+h (column shafts, plinths, basins, discs)."""
    rt = r if r_top is None else r_top
    prof = round_profile([(0.0, 0.0), (r, 0.0), (rt, h), (0.0, h)], bevel, 2)
    return lathe(bm, prof, sides, (center_xy[0], center_xy[1], z0), uv=uv, M=M)


def torus(bm, center, R, r, seg=48, sides=12, axis="Z", uv=None, M=None):
    """Ring of major radius R, tube radius r. axis 'Z' lies flat, 'Y' stands facing the front
    (halo rings), 'X' stands facing the side."""
    import bmesh
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap") if uv else None
    rings = []
    for i in range(seg):
        a = 2 * math.pi * i / seg
        ca, sa = math.cos(a), math.sin(a)
        ring = []
        for k in range(sides):
            t = 2 * math.pi * k / sides
            rr = R + r * math.cos(t)
            ring.append(tmp.verts.new((rr * ca, rr * sa, r * math.sin(t))))
        rings.append(ring)
    nu = max(1, round(2 * math.pi * R / uv)) if uv else 1
    nv = max(1, round(2 * math.pi * r / uv)) if uv else 1
    for i in range(seg):
        A, B = rings[i], rings[(i + 1) % seg]
        for k in range(sides):
            k2 = (k + 1) % sides
            f = tmp.faces.new((A[k], B[k], B[k2], A[k2]))
            if uvl is not None:
                u0, u1 = i / seg * nu, (i + 1) / seg * nu
                v0, v1 = k / sides * nv, (k + 1) / sides * nv
                for lp, c in zip(f.loops, [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]):
                    lp[uvl].uv = c
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    rot = {"Z": (0, 0, 0), "Y": (math.pi / 2, 0, 0), "X": (0, math.pi / 2, 0)}[axis]
    return _append(bm, tmp, _matrix(center, rot, M), uv=bool(uv))


def spike(bm, base, tip, r, sides=8, r_tip=0.0, M=None):
    """Cone / tapered spike from `base` to `tip` (any direction): rays, finial points, halo spikes."""
    from mathutils import Matrix, Vector
    b, t = Vector(base), Vector(tip)
    d = t - b
    L = d.length
    prof = [(0.0, 0.0), (r, 0.0), (r_tip, L)] + ([(0.0, L)] if r_tip > 0 else [])
    if r_tip <= 0:
        prof[-1] = (0.0, L)
    rot = d.normalized().to_track_quat("Z", "Y").to_matrix().to_4x4()
    T = Matrix.Translation(b) @ rot
    return lathe(bm, prof, sides, (0, 0, 0), M=(M @ T) if M is not None else T)


def crystal(bm, base, width, height, sides=4, waist=0.38, band=0.12, rot=(0, 0, 0), M=None):
    """Elongated bipyramid gem standing on `base` (tip down): an octahedron when sides=4.
    Give the Crystal material (faceted shading)."""
    w = width / 2.0
    prof = [(0.0, 0.0), (w, height * waist), (w * 0.94, height * (waist + band)), (0.0, height)]
    return lathe(bm, prof, sides, (0, 0, 0), phase=math.pi / sides, M=_matrix(base, rot, M))


def polar(n, radius, phase=0.0):
    """[(x, y, angle)] for n points evenly around a circle."""
    return [(radius * math.cos(phase + 2 * math.pi * i / n), radius * math.sin(phase + 2 * math.pi * i / n),
             phase + 2 * math.pi * i / n) for i in range(n)]


def rect_uv(bm, faces, lo, hi, axes="xz"):
    """Fit one texture tile exactly over the rectangle lo..hi of the given faces, projected on two
    axes ('xz' = seen from the front, 'yz' = from the side, 'xy' = from above) -- e.g. a banner, so
    the Cloth trim (image bottom) lands on its hem. Marks the faces done."""
    ia, ib = "xyz".index(axes[0]), "xyz".index(axes[1])
    uvl = bm.loops.layers.uv.verify()
    flag = _flag(bm)
    for f in faces:
        for lp in f.loops:
            p = lp.vert.co
            lp[uvl].uv = ((p[ia] - lo[0]) / (hi[0] - lo[0]), (p[ib] - lo[1]) / (hi[1] - lo[1]))
        f[flag] = 1


def disc_uv(bm, faces, center, radius):
    """Planar-fit UVs 0..1 over a disc of `radius` around center (x, y) -- the Mandala inlay."""
    uvl = bm.loops.layers.uv.verify()
    flag = _flag(bm)
    for f in faces:
        for lp in f.loops:
            p = lp.vert.co
            lp[uvl].uv = ((p.x - center[0]) / (2 * radius) + 0.5, (p.y - center[1]) / (2 * radius) + 0.5)
        f[flag] = 1


# ================================================================ UVs + finishing
def box_uv(bm, scale, faces=None):
    """World-scaled box projection (1 tile = `scale` studs) on faces without UVs yet. Walls and
    floors project on the dominant axis (v = z on walls, so block courses stay level); sloped faces
    (roofs) project along their own up-slope so tiles run downhill on every side."""
    from mathutils import Vector
    uvl = bm.loops.layers.uv.verify()
    flag = _flag(bm)
    bm.normal_update()
    up = Vector((0, 0, 1))
    for f in (faces if faces is not None else bm.faces):
        if f[flag]:
            continue
        n = f.normal
        az = abs(n.z)
        if 0.45 < az < 0.9:  # slope: v along the steepest ascent, u across it
            s = (up - n * n.z).normalized()
            t = s.cross(n).normalized()
            for lp in f.loops:
                p = lp.vert.co
                lp[uvl].uv = (p.dot(t) / scale, p.dot(s) / scale)
            continue
        ax = max(range(3), key=lambda i: abs(n[i]))
        for lp in f.loops:
            p = lp.vert.co
            if ax == 0:
                a, b = (p.y if n.x > 0 else -p.y), p.z
            elif ax == 1:
                a, b = (-p.x if n.y > 0 else p.x), p.z
            else:
                a, b = p.x, (p.y if n.z > 0 else -p.y)
            lp[uvl].uv = (a / scale, b / scale)


def smooth_by_angle(bm, angle=40.0):
    """Smooth faces + hard edges sharper than `angle` (0 = all hard / faceted)."""
    lim = math.radians(angle)
    for f in bm.faces:
        f.smooth = angle > 0
    for e in bm.edges:
        e.smooth = angle > 0 and e.is_manifold and e.calc_face_angle(0.0) <= lim


def finish(name, bm, col, mat, smooth=None, offset=(0, 0, 0), uv_scale=None):
    """bmesh -> one single-material object `name`: box UVs (material scale), translate by offset,
    smooth-by-angle + a Weighted Normal modifier (flat faces stay flat, bevels read round)."""
    import bmesh
    from mathutils import Vector
    sc = UV_SCALE.get(mat) if uv_scale is None else uv_scale
    if sc:
        box_uv(bm, sc)
    else:
        bm.loops.layers.uv.verify()
    lay = bm.faces.layers.int.get(_UVFLAG)
    if lay is not None:
        bm.faces.layers.int.remove(lay)
    if Vector(offset).length > 0:
        bmesh.ops.translate(bm, vec=Vector(offset), verts=bm.verts)
    ang = SMOOTH_ANGLE.get(mat, 40.0) if smooth is None else smooth
    smooth_by_angle(bm, ang)
    ob = mesh_object(name, bm, col, [MAT(mat)])
    if ang > 0:
        wn = ob.modifiers.new("WeightedNormal", "WEIGHTED_NORMAL")
        wn.mode = "FACE_AREA"
        wn.keep_sharp = True
    return ob


class Piece:
    """One kit piece = one object per material, named <name>__<Mat>. Author it around (0, 0, 0)
    = bottom-centre, front -Y; done() moves it to `origin` and records it in the manifest."""

    def __init__(self, name, origin=(0, 0, 0)):
        self.name = name
        self.origin = tuple(float(c) for c in origin)
        self._bms = {}
        self.smooth = {}    # per-material smoothing angle override, e.g. {"Gold": 0}
        self.uv_scale = {}  # per-material studs-per-tile override for the box pass

    def bm(self, mat):
        if mat not in MATS:
            raise KeyError("unknown kit material %r (use one of %s)" % (mat, ", ".join(MATS)))
        if mat not in self._bms:
            self._bms[mat] = new_bm()
        return self._bms[mat]

    def done(self, col, manifest=None):
        lo, hi = [1e9] * 3, [-1e9] * 3
        names = []
        for mat, bm in self._bms.items():
            if not bm.faces:
                bm.free()
                continue
            for v in bm.verts:
                for i in range(3):
                    lo[i] = min(lo[i], v.co[i])
                    hi[i] = max(hi[i], v.co[i])
            ob = finish("%s__%s" % (self.name, mat), bm, col, mat, self.smooth.get(mat), self.origin,
                        self.uv_scale.get(mat))
            names.append(ob.name)
        self._bms = {}
        entry = {"origin": [round(c, 3) for c in self.origin],
                 "size": [round(hi[i] - lo[i], 3) for i in range(3)] if names else [0, 0, 0],
                 "objects": names}
        if manifest is not None:
            manifest[self.name] = entry
        return entry


class Row:
    """Lays pieces out along +X with `gap` studs between them (README: 30-stud gaps)."""

    def __init__(self, gap=30.0, x=0.0):
        self.gap, self.x, self.first = gap, x, True

    def next(self, width):
        if not self.first:
            self.x += self.gap
        self.first = False
        cx = self.x + width / 2.0
        self.x += width
        return (cx, 0.0, 0.0)


# ================================================================ export + preview
def export_kit(col, letter, manifest):
    """Writes GLB/AL_Kit<letter>.glb (every object of col + an AL_Anchor<letter> 0.5-stud cube at
    the origin, Y-up, modifiers applied) and GLB/AL_Kit<letter>.json (the manifest)."""
    import bmesh
    import bpy
    an = "AL_Anchor%s" % letter
    abm = bmesh.new()
    bmesh.ops.create_cube(abm, size=0.5)
    mesh_object(an, abm, col, [])
    vl = bpy.context.view_layer
    for o in vl.objects:
        o.select_set(False)
    for o in col.all_objects:
        o.hide_set(False)
        o.select_set(True)
    path = os.path.join(GLB, "AL_Kit%s.glb" % letter)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_animations=False, export_yup=True, export_normals=True,
                              export_texcoords=True, export_materials="EXPORT", export_image_format="AUTO")
    jpath = os.path.join(GLB, "AL_Kit%s.json" % letter)
    with open(jpath, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)
    info = report(col)
    info.update({"glb": path, "kb": os.path.getsize(path) // 1024, "json": jpath, "pieces": len(manifest)})
    return info


def render_path(name):
    return os.path.join(RENDERS, name + ".png")


def _fit_camera(objs, view, lens, aspect, margin=1.06):
    """Camera (loc, target) looking along -view that frames every object's bounding box."""
    from mathutils import Vector
    pts = [o.matrix_world @ Vector(c) for o in objs for c in o.bound_box]
    lo = Vector([min(p[i] for p in pts) for i in range(3)])
    hi = Vector([max(p[i] for p in pts) for i in range(3)])
    tgt = (lo + hi) / 2
    d = Vector(view).normalized()  # from the target towards the camera
    right = (-d).cross(Vector((0, 0, 1)))
    right = right.normalized() if right.length > 1e-6 else Vector((1, 0, 0))
    up = right.cross(-d).normalized()
    tan_h = 18.0 / lens
    tan_v = tan_h / aspect
    dist = 1.0  # conservative start: everything in front of the camera and inside the frustum
    for p in pts:
        q = p - tgt
        dist = max(dist, q.dot(d) + abs(q.dot(right)) / tan_h, q.dot(d) + abs(q.dot(up)) / tan_v)
    for _ in range(5):  # re-centre + zoom on the projected extents (perspective-correct framing)
        cam = tgt + d * dist
        xs, ys = [], []
        for p in pts:
            q = p - cam
            depth = max(-q.dot(d), 1e-3)
            xs.append(q.dot(right) / depth)
            ys.append(q.dot(up) / depth)
        tgt = tgt + (right * (max(xs) + min(xs)) / 2 + up * (max(ys) + min(ys)) / 2) * dist
        dist *= max((max(xs) - min(xs)) / 2 / tan_h, (max(ys) - min(ys)) / 2 / tan_v) * margin
    return tgt + d * dist, tgt


def _sky_world(sc):
    import bpy
    world = sc.world or bpy.data.worlds.new("AL_PrevWorld")
    sc.world = world
    world.color = (0.62, 0.78, 0.93)
    if world.node_tree is None:
        world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    grad = nt.nodes.new("ShaderNodeTexGradient")
    mapn = nt.nodes.new("ShaderNodeMapping")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    rmp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(tc.outputs["Generated"], mapn.inputs["Vector"])
    mapn.inputs["Rotation"].default_value = (0, math.radians(-90), 0)
    nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
    nt.links.new(grad.outputs["Fac"], rmp.inputs["Fac"])
    rmp.color_ramp.elements[0].color = (1.0, 0.93, 0.80, 1)
    rmp.color_ramp.elements[1].color = (0.40, 0.66, 0.95, 1)
    nt.links.new(rmp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.55
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])


def preview(col, path, engine="CYCLES", cam=None, lens=35.0, res=(1280, 720), samples=24,
            view=(-0.78, -1.0, 0.62)):
    """Render a PNG of only `col` from a 3/4 elevated front-left view (auto-framed) or cam=(loc, target).
    engine: 'CYCLES' (CPU, `samples`, warm sun + sky -- the true look, a few seconds per kit),
    'WORKBENCH' (texture colour + studio light, geometry check) or 'EEVEE'."""
    import bpy
    from mathutils import Vector
    sc = scene()
    keep = set(o.name for o in col.all_objects)
    hidden = {}
    for o in sc.objects:
        if o.type == "MESH":
            hidden[o.name] = o.hide_render
            o.hide_render = o.name not in keep
    co = bpy.data.objects.get("_AL_PrevCam")
    if co is None:
        co = bpy.data.objects.new("_AL_PrevCam", bpy.data.cameras.new("_AL_PrevCam"))
        sc.collection.objects.link(co)
    co.data.lens = lens
    co.data.clip_end = 5000
    meshes = [o for o in col.all_objects if o.type == "MESH" and not o.name.startswith("AL_Anchor")]
    loc, tgt = cam if cam is not None else _fit_camera(meshes, view, lens, res[0] / res[1])
    co.location = Vector(loc)
    co.rotation_mode = "QUATERNION"
    co.rotation_quaternion = (Vector(tgt) - Vector(loc)).to_track_quat("-Z", "Y")
    sc.camera = co
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.render.film_transparent = False
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.4 if engine == "WORKBENCH" else 0.0
    _sky_world(sc)
    if engine == "WORKBENCH":
        sc.render.engine = "BLENDER_WORKBENCH"
        sh = sc.display.shading
        sh.light = "STUDIO"
        sh.color_type = "TEXTURE"
        sh.show_shadows = True
        sh.shadow_intensity = 0.4
        sh.show_cavity = True
        sh.cavity_type = "BOTH"
        sh.show_specular_highlight = True
        try:
            sh.background_type = "WORLD"
        except Exception:
            pass
        sc.display.render_aa = "8"
        sc.display.light_direction = (-0.45, -0.55, 0.7)
    else:
        sun = bpy.data.objects.get("_AL_PrevSun")
        if sun is None:
            sun = bpy.data.objects.new("_AL_PrevSun", bpy.data.lights.new("_AL_PrevSun", "SUN"))
            sc.collection.objects.link(sun)
        sun.data.energy = 2.4
        sun.data.color = (1.0, 0.93, 0.80)
        sun.data.angle = math.radians(4)
        sun.rotation_euler = (math.radians(50), 0, math.radians(-35))
        if engine == "CYCLES":
            sc.render.engine = "CYCLES"
            sc.cycles.device = "CPU"
            sc.cycles.samples = samples
            sc.cycles.use_denoising = True
        else:
            sc.render.engine = "BLENDER_EEVEE"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    for name, h in hidden.items():
        o = bpy.data.objects.get(name)
        if o is not None:
            o.hide_render = h
    return path
