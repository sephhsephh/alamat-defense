# Apolaki Sun Terraces -- terrain generator (B166). Blender: Z up, 1 unit = 1 stud.
# JSON layouts are written as (x, z, -y); the 3D Importer turns the scene 180 deg about Y, so the Studio
# assembly rotates every placement 180 deg about the map origin -> real Roblox = (-x, z, y). Meadow top z = 0.
# Builds collection "AST_Terrain" and writes glb/layout_terrain.json (path waypoints, zone boxes, spawn, base).
import importlib
import json
import math
import os
import sys

import bmesh
import bpy

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

importlib.reload(C)
np = C.np

GRASS_TILE = 44.0  # studs per grass texture repeat

# ------------------------------------------------------------------ layout numbers (the design)
PATH_POINTS = [(-64, 8), (-52, 8), (-32, 8), (-32, -12), (-10, -12), (-10, 14), (10, 14), (10, -12),
               (32, -12), (32, 8), (52, 8), (60, 8)]
PATH_HALF = 2.3
CORNER_R = 3.2
MESAS = [  # name, cx, cy, half-x, half-y, height  (Hill zones)
    ("MesaWest", -21.0, 3.0, 6.0, 5.0, 5.0),
    ("MesaEast", 21.0, 3.0, 6.0, 5.0, 5.0),
    ("SunRock", 0.0, 31.0, 8.0, 5.5, 6.0),
]
MEADOW_A, MEADOW_B, MEADOW_CY = 82.0, 50.0, -2.0
TERRACE_STEPS = 8
TERRACE_RISE = 4.0
TERRACE_DEPTH = 9.0
VALLEY_Z = -16.0


def terrace_front(x, k):
    """Front edge (y) of terrace step k (k = 1 is the first wall behind the meadow)."""
    return 46.0 + TERRACE_DEPTH * (k - 1) + 5.0 * math.sin(x / 23.0 + k * 0.7) + 0.0016 * x * x


# ------------------------------------------------------------------ mesh helpers
def grid_mesh(name, P, UV, col, mats, closed_u=False, mat_index=None, flip=False):
    """P: (R, K, 3) rows x columns of points; UV: (R, K, 2). Quads between neighbours."""
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    R, K = P.shape[0], P.shape[1]
    verts = [[bm.verts.new(tuple(P[r, k])) for k in range(K)] for r in range(R)]
    kmax = K if closed_u else K - 1
    for r in range(R - 1):
        for k in range(kmax):
            k2 = (k + 1) % K
            quad = [verts[r][k], verts[r][k2], verts[r + 1][k2], verts[r + 1][k]]
            uvs = [UV[r, k], UV[r, k2] if (k2 != 0 or not closed_u) else UV[r, k] + (UV[r, 1] - UV[r, 0]),
                   UV[r + 1, k2] if (k2 != 0 or not closed_u) else UV[r + 1, k] + (UV[r + 1, 1] - UV[r + 1, 0]),
                   UV[r + 1, k]]
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
    return C.mesh_object(name, bm, col, mats)


def polygon_cap(name, pts, z, col, mat, uv_scale):
    """Flat top polygon (CCW pts xy) at height z, planar tiling UV."""
    bm = bmesh.new()
    uvl = bm.loops.layers.uv.new("UVMap")
    vs = [bm.verts.new((x, y, z)) for x, y in pts]
    edges = [bm.edges.new((vs[i], vs[(i + 1) % len(vs)])) for i in range(len(vs))]
    res = bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=edges)
    for f in bm.faces:
        if f.normal.z < 0:
            f.normal_flip()
        for loop in f.loops:
            co = loop.vert.co
            loop[uvl].uv = (co.x / uv_scale, co.y / uv_scale)
    bm.normal_update()
    return C.mesh_object(name, bm, col, [mat])


def cliff_skirt(name, pts, z_top, z_bot, col, mat, seed, bulge=1.4, lip=0.35, closed=True):
    """Vertical cliff hanging from a CCW outline: noisy bulges + strata, cliff texture (v = depth)."""
    pts = np.array(pts, dtype=float)
    K = len(pts)
    seg = np.linalg.norm(np.roll(pts, -1, 0) - pts, axis=1)
    per = np.concatenate([[0], np.cumsum(seg)[:-1]])
    nxt = np.roll(pts, -1, 0)
    prv = np.roll(pts, 1, 0)
    t = nxt - prv
    t /= np.linalg.norm(t, axis=1, keepdims=True) + 1e-9
    nrm = np.stack([t[:, 1], -t[:, 0]], 1)  # outward for a CCW outline
    depth = z_top - z_bot
    zs = [z_top + 0.25, z_top - 0.05, z_top - 0.9, z_top - 2.5]
    zz = z_top - 2.5
    while zz > z_bot:
        zz = max(z_bot, zz - max(2.5, depth / 7))
        zs.append(zz)
    R = len(zs)
    P = np.zeros((R, K, 3))
    UV = np.zeros((R, K, 2))
    for r, z in enumerate(zs):
        d = (z_top - z)
        # outward offset: a rounded grass lip, then noisy strata bulges that lean in toward the base
        n1 = C.vnoise_xy(per / 7.0, np.full(K, d / 3.0) + seed, 4096, seed)
        n2 = C.vnoise_xy(per / 2.5, np.full(K, d / 1.5) + seed * 2, 4096, seed + 7)
        off = lip * (1 if r == 0 else 0) + (bulge * (n1 - 0.5) * 2 + 0.45 * (n2 - 0.5) * 2) * min(1.0, d / 1.5)
        off -= 0.06 * d  # slight batter
        P[r, :, 0] = pts[:, 0] + nrm[:, 0] * off
        P[r, :, 1] = pts[:, 1] + nrm[:, 1] * off
        P[r, :, 2] = z
        UV[r, :, 0] = per / 32.0
        UV[r, :, 1] = 1 - (max(0.0, z_top - z) / 32.0)  # glTF flips V: Blender v=1 is the image top
    return grid_mesh(name, P, UV, col, [mat], closed_u=closed, flip=True)


def superellipse(a, b, cy, n=4.0, count=220, seed=0, wobble=2.5):
    pts = []
    for i in range(count):
        th = 2 * math.pi * i / count
        c, s = math.cos(th), math.sin(th)
        x = a * math.copysign(abs(c) ** (2 / n), c)
        y = b * math.copysign(abs(s) ** (2 / n), s)
        w = wobble * (C.vnoise_xy(np.array([th * 6.0]), np.array([seed * 1.0]), 4096, seed)[0] - 0.5) * 2
        r = math.hypot(x, y) + w
        ang = math.atan2(y, x)
        pts.append((r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


# ------------------------------------------------------------------ path
def rounded_path(points, radius, per_corner=5):
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
    # resample long straights so the ribbon follows the ground evenly
    res = [out[0]]
    for q in out[1:]:
        p = res[-1]
        L = np.linalg.norm(q - p)
        n = max(1, int(L / 3.0))
        for j in range(1, n + 1):
            res.append(p + (q - p) * j / n)
    return np.array(res)


def build_path(col, mat):
    cl = rounded_path(PATH_POINTS, CORNER_R)
    K = len(cl)
    t = np.gradient(cl, axis=0)
    t /= np.linalg.norm(t, axis=1, keepdims=True)
    nrm = np.stack([-t[:, 1], t[:, 0]], 1)
    # cross-section (across, height, u): outer foot, rim top, inner rim, tread, mirrored
    H = PATH_HALF
    # B166 (user): the dark side rims stand clearly proud of the tread
    prof = [(-H - 0.3, -0.05, 0.0), (-H - 0.12, 0.58, 0.06), (-H + 0.22, 0.66, 0.12), (-H + 0.5, 0.2, 0.16),
            (0, 0.18, 0.5),
            (H - 0.5, 0.2, 0.84), (H - 0.22, 0.66, 0.88), (H + 0.12, 0.58, 0.94), (H + 0.3, -0.05, 1.0)]
    length = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(cl, axis=0), axis=1))])
    R = len(prof)
    P = np.zeros((K, R, 3))
    UV = np.zeros((K, R, 2))
    for j, (a, z, u) in enumerate(prof):
        P[:, j, 0] = cl[:, 0] + nrm[:, 0] * a
        P[:, j, 1] = cl[:, 1] + nrm[:, 1] * a
        P[:, j, 2] = z
        UV[:, j, 0] = u
        UV[:, j, 1] = length / 9.0
    ob = grid_mesh("AST_Path", P, UV, col, [mat], flip=True)
    return ob, cl, float(length[-1])


# ------------------------------------------------------------------ build
def build():
    col = C.clear_collection("AST_Terrain")
    m_grass = C.tex_material("M_Grass", "grass")
    m_cliff = C.tex_material("M_Cliff", "cliff")
    m_path = C.tex_material("M_Path", "path")
    m_wall = C.tex_material("M_StoneWall", "stone_wall")
    m_paddy = C.tex_material("M_Paddy", "paddy")
    m_water = C.tex_material("M_Water", "water", rough=0.2)
    m_mount = C.tex_material("M_Mountain", "mountain")
    info = {}

    # --- meadow plateau: top + cliff skirt (front/sides); its back edge is buried under terrace 1
    outline = superellipse(MEADOW_A, MEADOW_B, MEADOW_CY, n=4.5, count=240, seed=3)
    polygon_cap("AST_MeadowTop", outline, 0.0, col, m_grass, GRASS_TILE)
    cliff_skirt("AST_MeadowCliff", outline, 0.0, VALLEY_Z - 6, col, m_cliff, seed=5)

    # --- mesas (Hill zones): flat grass top + cliff skirt
    zones = []
    for name, cx, cy, hx, hy, h in MESAS:
        pts = [(cx + p[0], p[1]) for p in superellipse(hx, hy, cy, n=3.2, count=72, seed=sum(map(ord, name)) % 97, wobble=0.6)]
        polygon_cap(name + "_Top", pts, h, col, m_grass, GRASS_TILE)
        cliff_skirt(name + "_Cliff", pts, h, -1.0, col, m_cliff, seed=sum(map(ord, name)) % 53, bulge=0.6, lip=0.25)
        zones.append({"name": name, "type": "Hill", "cx": cx, "cy": cy, "sx": hx * 1.7, "sy": hy * 1.7, "top": h})

    # --- rice terraces behind the meadow: stone walls + paddy tops, first wall reaches the valley
    xs = np.linspace(-190, 190, 96)
    for k in range(1, TERRACE_STEPS + 1):
        z0 = TERRACE_RISE * (k - 1)
        z1 = TERRACE_RISE * k
        ys = np.array([terrace_front(x, k) for x in xs])
        bottom = VALLEY_Z - 6 if k == 1 else z0
        rows = [bottom, z0, z1] if k == 1 else [z0, z1]
        P = np.zeros((len(rows), len(xs), 3))
        UV = np.zeros_like(P[..., :2])
        per = np.concatenate([[0], np.cumsum(np.hypot(np.diff(xs), np.diff(ys)))])
        for r, z in enumerate(rows):
            inset = 0.0 if z <= z0 else 0.7
            P[r, :, 0] = xs
            P[r, :, 1] = ys + inset
            P[r, :, 2] = z
            UV[r, :, 0] = per / 12.0
            UV[r, :, 1] = z / 12.0
        grid_mesh("AST_TerraceWall_%d" % k, P, UV, col, [m_wall, m_cliff], flip=False,
                  mat_index=(lambda r, kk, k=k: 1 if (k == 1 and r == 0) else 0))
        # paddy top from this wall back to the next wall
        ys2 = np.array([terrace_front(x, k + 1) for x in xs]) + 0.2
        T = np.zeros((2, len(xs), 3))
        TU = np.zeros_like(T[..., :2])
        T[0, :, 0] = xs
        T[0, :, 1] = ys + 0.7
        T[1, :, 0] = xs
        T[1, :, 1] = ys2
        T[:, :, 2] = z1
        TU[..., 0] = T[..., 0] / 20.0
        TU[..., 1] = T[..., 1] / 20.0
        grid_mesh("AST_TerracePaddy_%d" % k, T, TU, col, [m_paddy], flip=False)

    # --- valley floor (grass banks) with the river channel dug into it
    river = np.array([(-118, 60), (-112, 20), (-104, -20), (-84, -62), (-40, -82), (10, -86), (60, -78),
                      (100, -56), (122, -14), (138, 30), (170, 60)], dtype=float)

    def river_dist(x, y):
        d = np.full(x.shape, 1e9)
        for a, b in zip(river[:-1], river[1:]):
            ab = b - a
            t = np.clip(((x - a[0]) * ab[0] + (y - a[1]) * ab[1]) / (ab @ ab), 0, 1)
            px, py = a[0] + ab[0] * t, a[1] + ab[1] * t
            d = np.minimum(d, np.hypot(x - px, y - py))
        return d

    N = 92
    gx = np.linspace(-260, 260, N)
    gy = np.linspace(-260, 200, N)
    X, Y = np.meshgrid(gx, gy)
    hills = (C.fbm_xy(X / 60.0, Y / 60.0, 4096, 4, 77) - 0.5) * 7
    rd = river_dist(X, Y)
    channel = np.clip(1 - rd / 12.0, 0, 1) ** 1.5 * 6.5
    outer = np.clip((np.hypot(X, Y + 30) - 170) / 80.0, 0, 1) * 18  # rises toward the far ring
    Z = VALLEY_Z + hills - channel + outer
    P = np.dstack([X, Y, Z])
    UV = np.dstack([X / GRASS_TILE, Y / GRASS_TILE])
    grid_mesh("AST_Valley", P, UV, col, [m_grass], flip=False)

    # river water ribbon
    rv = np.array(river)
    dense = [rv[0]]
    for a, b in zip(rv[:-1], rv[1:]):
        n = int(np.linalg.norm(b - a) / 4) + 1
        for j in range(1, n + 1):
            dense.append(a + (b - a) * j / n)
    dense = np.array(dense)
    t = np.gradient(dense, axis=0)
    t /= np.linalg.norm(t, axis=1, keepdims=True)
    nr = np.stack([-t[:, 1], t[:, 0]], 1)
    L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(dense, axis=0), axis=1))])
    W = np.zeros((2, len(dense), 3))
    WU = np.zeros_like(W[..., :2])
    for r, s in enumerate((-11.0, 11.0)):
        W[r, :, 0] = dense[:, 0] + nr[:, 0] * s
        W[r, :, 1] = dense[:, 1] + nr[:, 1] * s
        W[r, :, 2] = VALLEY_Z - 1.6
        WU[r, :, 0] = r * 1.0
        WU[r, :, 1] = L / 22.0
    grid_mesh("AST_River", W, WU, col, [m_water], flip=False)

    # --- path ribbon
    path_ob, centerline, plen = build_path(col, m_path)

    # --- mountain ring (far backdrop)
    peaks = [(-40, 470, 210, 150), (190, 400, 170, 120), (-260, 380, 180, 130), (420, 120, 160, 120),
             (-440, 60, 170, 120), (330, -330, 150, 100), (-330, -360, 160, 110), (40, -520, 190, 120),
             (520, -120, 140, 90), (-520, -140, 150, 95)]
    for i, (px, py, rad, ht) in enumerate(peaks):
        RN, KN = 16, 40
        P = np.zeros((RN, KN, 3))
        UV = np.zeros((RN, KN, 2))
        for r in range(RN):
            rr = r / (RN - 1)
            for k in range(KN):
                th = 2 * math.pi * k / KN
                ridge = 0.35 * (C.vnoise_xy(np.array([th * 3 + i]), np.array([rr * 3.0]), 4096, 300 + i)[0] - 0.5)
                h = ht * (1 - rr) ** 1.7 * (1 + ridge) if r < RN - 1 else -40
                rad_r = rad * (0.03 + rr) * (1 + 0.25 * (C.vnoise_xy(np.array([th * 2 + i]), np.array([0.5]), 4096, 400 + i)[0] - 0.5))
                P[r, k] = (px + rad_r * math.cos(th), py + rad_r * math.sin(th), h - 10)
                UV[r, k] = (k / KN * 3.0, 1 - min(1.0, rr * 1.2))
        grid_mesh("AST_Mountain_%02d" % i, P, UV, col, [m_mount], closed_u=True, flip=True)

    # --- waterfall rock (left back corner): tall rock wall the falls pour down
    wf = superellipse(16, 9, 0, n=2.6, count=60, seed=91, wobble=1.5)
    wf = [(x - 112, y + 62) for x, y in wf]
    polygon_cap("AST_FallsRock_Top", wf, 30.0, col, m_grass, GRASS_TILE)
    cliff_skirt("AST_FallsRock_Cliff", wf, 30.0, VALLEY_Z - 4, col, m_cliff, seed=93, bulge=1.8)

    # pre-rotation frame for the Studio script: (x, z, -y) -- the assembly then turns it 180 deg (header)
    def rbx(x, y, z):
        return [round(float(x), 3), round(float(z), 3), round(float(-y), 3)]

    wps = rounded_path(PATH_POINTS, CORNER_R, per_corner=3)
    # keep waypoints sparse on straights (enemies walk straight between them)
    keep = [wps[0]]
    for p in wps[1:]:
        if np.linalg.norm(p - keep[-1]) > 0.9:
            keep.append(p)
    info["waypoints"] = [rbx(p[0], p[1], 0.0) for p in keep]
    info["path_length"] = plen
    info["path_half"] = PATH_HALF
    info["zones"] = [{"name": z["name"], "type": "Hill", "pos": rbx(z["cx"], z["cy"], z["top"]),
                      "size": [z["sx"], 1.0, z["sy"]]} for z in zones]
    info["meadow"] = {"a": MEADOW_A, "b": MEADOW_B, "cy": MEADOW_CY, "outline": [rbx(x, y, 0) for x, y in outline[::2]]}
    info["spawn"] = rbx(PATH_POINTS[0][0], PATH_POINTS[0][1], 0.0)
    info["base"] = rbx(PATH_POINTS[-1][0], PATH_POINTS[-1][1], 0.0)
    info["river_z"] = VALLEY_Z - 1.6
    with open(os.path.join(C.GLB, "layout_terrain.json"), "w") as f:
        json.dump(info, f, indent=1)
    tris = {o.name: C.tri_count(o) for o in col.objects}
    return {"objects": len(col.objects), "max_tris": max(tris.items(), key=lambda kv: kv[1]), "total_tris": sum(tris.values()),
            "path_length": round(plen, 1), "waypoints": len(info["waypoints"])}


sc = C.scene()
bpy.context.window.scene = sc
result = build()
