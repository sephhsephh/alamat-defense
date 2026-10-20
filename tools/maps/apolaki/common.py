# Apolaki Sun Terraces -- shared helpers for the Blender build scripts (B166).
# Run inside Blender (bpy + numpy). Every script does:
#   import sys; sys.path.insert(0, TOOLS); import common; importlib.reload(common)
import math
import os

import numpy as np

BASE = r"C:\Users\Joseph Elton Estilo\Downloads\Apolaki_Map"
TEX = os.path.join(BASE, "tex")
GLB = os.path.join(BASE, "glb")
RENDERS = os.path.join(BASE, "renders")

RNG = np.random.default_rng(1166)


def rng(seed):
    return np.random.default_rng(seed)


# ---------------------------------------------------------------- noise
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
    out = np.zeros(t.shape + (3,))
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
    m = m[..., None] if (m.ndim == a.ndim - 1) else m
    return a * (1 - m) + b * m


# ---------------------------------------------------------------- image IO
def save_png(name, rgb, alpha=None):
    """rgb HxWx3 (0-1, row 0 = TOP of the image). Saves TEX/name.png, returns the path."""
    import bpy
    h, w = rgb.shape[:2]
    a = np.ones((h, w)) if alpha is None else np.clip(alpha, 0, 1)
    rgba = np.dstack([np.clip(rgb, 0, 1), a])[::-1]  # Blender stores bottom row first
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


# ---------------------------------------------------------------- materials / scene
def scene():
    import bpy
    sc = bpy.data.scenes["ApolakiMap"]
    return sc


def collection(name, parent=None):
    import bpy
    col = bpy.data.collections.get(name)
    if col is None:
        col = bpy.data.collections.new(name)
        (parent or scene().collection).children.link(col)
    return col


def clear_collection(name):
    import bpy
    col = bpy.data.collections.get(name)
    if col is None:
        return collection(name)
    for o in list(col.objects):
        me = o.data if o.type == "MESH" else None
        bpy.data.objects.remove(o, do_unlink=True)
        if me is not None and me.users == 0:
            bpy.data.meshes.remove(me)
    return col


def tex_material(name, tex_name, alpha=False, rough=0.9, emission=None):
    """A Principled material reading TEX/<tex_name>.png -- glTF exports it as baseColorTexture."""
    import bpy
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    bsdf = nt.nodes.new("ShaderNodeBsdfPrincipled")
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = load_image(tex_name)
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if alpha:
        nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
        try:
            mat.blend_method = "CLIP"
        except Exception:
            pass
        try:
            mat.surface_render_method = "DITHERED"
        except Exception:
            pass
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = 0.0
    if emission is not None:
        nt.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission
    nt.links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    mat.use_backface_culling = not alpha
    return mat


def mesh_object(name, bm, col, mats=()):
    import bpy
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
