# Bakunawa Cove -- terrain generator (B173). Blender: Z up, 1 unit = 1 stud, plateau top z = 0, sea z = C.SEA_Z.
# The playable ground is a grass island plateau with low cliffs standing on a sand beach that slopes into a
# turquoise sea. Enemies land on the HARBOUR PIER (west, -x), wind across the plateau past three rock mesas
# (Hill zones) and end at the SKULL ROCK treasure cave (north-east). Behind: the Fortress Rock (north) with the
# waterfall; islets + a sandbar (shipwreck) in the sea.
# Builds collection "BC_Terrain" and writes glb/layout_terrain.json (frame: header of common.py).
import importlib.util
import json
import math
import os
import sys

import bpy

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np

# ------------------------------------------------------------------ layout numbers (the design)
# B173 user: "expand the main map, that pathing is too short" -> island 1.5x (was a 84 x b 52, path 303 incl. pier),
# a long serpentine with four switchbacks: ~570 studs incl. the 36-stud pier (~530 on land).
PLATEAU = dict(a=124.0, b=78.0, n=4.0)
PATH_POINTS = [(-160, -12), (-90, -12), (-90, -50), (-48, -50), (-48, 32), (-6, 32), (-6, -50), (36, -50), (36, 32),
               (84, 32), (84, 72)]
PIER_END_X = -122.0  # the plateau path ribbon starts here; west of it the enemies walk the pier deck (kit piece)
PATH_HALF = 2.4
CORNER_R = 3.4
MESAS = [  # name, cx, cy, half-x, half-y, height (Hill zones) -- one inside each switchback
    ("MesaWest", -69.0, -10.0, 8.0, 10.0, 5.0),
    ("MesaMidWest", -27.0, -8.0, 8.0, 10.0, 5.0),
    ("MesaMidEast", 15.0, -8.0, 8.0, 10.0, 5.0),
    ("MesaEast", 60.0, -10.0, 10.0, 9.0, 6.0),
]
FORT_ROCK = dict(a=60.0, b=30.0, cx=-55.0, cy=236.0, n=3.0, top=42.0)  # behind the village terrace
# B173 pt3 (user: "expand the map more, much structured layout of village, paths from village"): a raised VILLAGE
# TERRACE (z 3) north of the arena, between it and the Fortress Rock; streets + a plaza are DESIGN paths (packed earth
# ribbons with ragged alpha edges, sandstone plaza) and never touch the enemy path.
VILLAGE = dict(a=105.0, b=62.0, cx=-55.0, cy=136.0, n=3.4, top=3.0)
PLAZA = (-46.0, 140.0, 18.0)  # centre x, y, radius (on the terrace)
STREETS = [  # (name, half-width, terrace?, points) -- terrace streets sit on z 3, arena roads on z 0
    ("Harbour", 3.0, False, [(-114, 0), (-112, 36), (-94, 56), (-62, 62), (-46, 64), (-46, 74)]),
    ("MainSouth", 3.5, True, [(-46, 72), (-46, 124)]),
    ("MainNorth", 3.5, True, [(-46, 156), (-50, 196)]),
    ("CrossWest", 3.0, True, [(-150, 142), (-110, 138), (-62, 140)]),
    ("CrossEast", 3.0, True, [(-30, 140), (8, 136), (36, 130)]),
    ("BackWest", 2.5, True, [(-122, 176), (-90, 174), (-48, 172)]),
    ("BackEast", 2.5, True, [(-48, 172), (-14, 170), (16, 164)]),
    ("Garden", 2.5, False, [(-46, 64), (-20, 60), (10, 54), (40, 50)]),
]
SKULL_BASE = dict(a=30.0, b=24.0, cx=88.0, cy=96.0, n=3.0, top=0.6)  # the skull rock (kit) stands on it
ISLETS = [(-232, 100, 20, 15, 16), (232, -110, 15, 12, 10), (-140, -188, 12, 10, 8), (310, 72, 28, 20, 24),
          (58, -232, 10, 9, 6), (-330, -58, 22, 16, 18), (174, 218, 30, 18, 28),
          (-520, 460, 110, 70, 80), (480, 520, 130, 80, 105), (-640, -80, 80, 60, 60), (650, 140, 90, 70, 70)]  # far isles
SANDBAR = (162, -122, 34, 24)  # cx, cy, rx, ry -- the shipwreck rests on it
BEACH_Z = -3.0
SEA_TILE = 48.0
GRASS_TILE = 72.0  # studs per grass texture repeat (big, so the soft colour pools never read as a grid)


def beach_width(theta):
    """Beach width (studs) per outline angle: narrow at the harbour (west), wide on the south + east."""
    w = 40.0 + 10.0 * math.sin(theta) * -1  # south (-y) wider
    w -= 18.0 * max(0.0, -math.cos(theta)) ** 2  # west (harbour) narrow
    return w


def beach_z(d, w):
    """Height of the beach `d` studs out from the cliff foot (w = beach width to z = -15)."""
    t = np.clip(d / w, 0, 1.2)
    return BEACH_Z - 12.0 * t ** 1.25


def build_path(col, m_tread, m_curb):
    """Cobbled tread between two rounded candy-striped curbs (B173 user reference)."""
    pts = [p for p in PATH_POINTS]
    pts[0] = (PIER_END_X - 4.0, pts[0][1])
    cl = C.rounded_path(pts, CORNER_R)
    K = len(cl)
    t = np.gradient(cl, axis=0)
    t /= np.linalg.norm(t, axis=1, keepdims=True)
    nrm = np.stack([-t[:, 1], t[:, 0]], 1)
    H = PATH_HALF
    # half-round curb ~1.1 wide x 0.8 tall; the tread sits 0.16-0.2 above the grass
    left = [(-0.55, -0.1), (-0.52, 0.3), (-0.35, 0.62), (0.0, 0.8), (0.35, 0.62), (0.52, 0.3), (0.55, 0.16)]
    prof = [(-H - 0.1 + a, z) for a, z in left] + [(0.0, 0.2)] + \
           [(H + 0.1 - a, z) for a, z in reversed(left)]
    nc = len(left)  # quads 0..nc-2 = left curb, nc-1..nc = tread, the rest = right curb
    length = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(cl, axis=0), axis=1))])
    R = len(prof)
    P = np.zeros((K, R, 3))
    UV = np.zeros((K, R, 2))
    tread_w = prof[nc + 1][0] - prof[nc - 1][0]
    for j, (a, z) in enumerate(prof):
        P[:, j, 0] = cl[:, 0] + nrm[:, 0] * a
        P[:, j, 1] = cl[:, 1] + nrm[:, 1] * a
        P[:, j, 2] = z
        if nc - 1 <= j <= nc + 1:
            UV[:, j, 0] = (a - prof[nc - 1][0]) / tread_w
            UV[:, j, 1] = length / 9.0
        else:
            k = j if j < nc else R - 1 - j
            UV[:, j, 0] = length / 4.0
            UV[:, j, 1] = k / (nc - 1)
    ob = C.grid_mesh("BC_Path", P, UV, col, [m_tread, m_curb], flip=True,
                     mat_index=lambda r, k: 0 if nc - 1 <= k <= nc else 1)
    return ob, cl, float(length[-1])




def build():
    col = C.clear_collection("BC_Terrain")
    m = {k: C.MAT(k) for k in ("Grass", "Sand", "Cliff", "PathSand", "Curb", "Water")}
    info = {}

    # --- island plateau: grass top + low cliff skirt standing on the beach
    outline = C.superellipse(PLATEAU["a"], PLATEAU["b"], 0, 0, n=PLATEAU["n"], count=260, seed=3, wobble=2.0)
    C.polygon_cap("BC_PlateauTop", outline, 0.0, col, m["Grass"], GRASS_TILE)
    C.cliff_skirt("BC_PlateauCliff", outline, 0.0, BEACH_Z - 2.0, col, m["Cliff"], seed=5, bulge=1.0, lip=0.3)

    # --- beach ring: from under the cliff foot out to the sea floor (rows = distance out, cols = outline)
    out = np.array(outline)
    nrm = C.outline_normals(out)
    theta = np.arctan2(out[:, 1], out[:, 0])
    ds = [-3.0, 0.0, 3.0, 7.0, 12.0, 18.0, 25.0, 33.0, 42.0, 52.0]
    P = np.zeros((len(ds), len(out), 3))
    UV = np.zeros_like(P[..., :2])
    for r, d in enumerate(ds):
        for k in range(len(out)):
            w = beach_width(theta[k])
            n1 = C.vnoise_xy(np.array([k / 9.0]), np.array([d / 10.0]), 4096, 11)[0] - 0.5
            dd = d + (6.0 * n1 if d > 0 else 0)
            x = out[k, 0] + nrm[k, 0] * dd
            y = out[k, 1] + nrm[k, 1] * dd
            z = float(beach_z(max(d, 0.0), w)) + (0.5 * n1 if d > 0 else 0)
            P[r, k] = (x, y, z)
            UV[r, k] = (x / 20.0, y / 20.0)
    C.grid_mesh("BC_Beach", P, UV, col, [m["Sand"]], closed_u=True, flip=True)

    # --- Hill zones: rock mesas with grass tops
    zones = []
    for name, cx, cy, hx, hy, h in MESAS:
        pts = C.superellipse(hx, hy, cx, cy, n=3.2, count=72, seed=sum(map(ord, name)) % 97, wobble=0.5)
        C.polygon_cap(name + "_Top", pts, h, col, m["Grass"], GRASS_TILE)
        C.cliff_skirt(name + "_Cliff", pts, h, -1.0, col, m["Cliff"], seed=sum(map(ord, name)) % 53, bulge=0.6,
                      lip=0.25, tile=12.0)
        zones.append({"name": name, "type": "Hill", "cx": cx, "cy": cy, "sx": hx * 1.7, "sy": hy * 1.7, "top": h})

    # --- village terrace (z 3) + its design streets and plaza
    V = VILLAGE
    vpts = C.superellipse(V["a"], V["b"], V["cx"], V["cy"], n=V["n"], count=200, seed=31, wobble=2.5)
    C.polygon_cap("BC_VillageTop", vpts, V["top"], col, m["Grass"], GRASS_TILE)
    C.cliff_skirt("BC_VillageCliff", vpts, V["top"], -12.0, col, m["Cliff"], seed=33, bulge=1.2, lip=0.3, tile=16.0)
    m_st, m_pz = C.MAT("Street"), C.MAT("Plaza")
    streets_info = []
    for i, (nm, half, terrace, pts) in enumerate(STREETS):
        z = (V["top"] if terrace else 0.0) + 0.12 + 0.1 * (i % 4)  # >= 0.1 apart where ribbons overlap (z-fight rule)
        cl = C.rounded_path(pts, 6.0, per_corner=6, step=2.5)
        t = np.gradient(cl, axis=0)
        t /= np.linalg.norm(t, axis=1, keepdims=True)
        nrm = np.stack([-t[:, 1], t[:, 0]], 1)
        L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(cl, axis=0), axis=1))])
        wob = 1 + 0.12 * (C.vnoise_xy(L / 9.0, np.zeros_like(L), 4096, 70 + i) - 0.5)
        P = np.zeros((len(cl), 3, 3))
        UV = np.zeros((len(cl), 3, 2))
        for j, a in enumerate((-1.0, 0.0, 1.0)):
            P[:, j, 0] = cl[:, 0] + nrm[:, 0] * a * half * wob
            P[:, j, 1] = cl[:, 1] + nrm[:, 1] * a * half * wob
            P[:, j, 2] = z
            UV[:, j, 0] = (a + 1) / 2
            UV[:, j, 1] = L / 8.0
        C.grid_mesh("BC_Street_" + nm, P, UV, col, [m_st], flip=True)
        streets_info.append({"name": nm, "half": half, "z": round(z, 2), "pts": [list(map(float, p)) for p in pts]})
    px, py, pr = PLAZA
    disc = [(px + pr * math.cos(a) * (1 + 0.04 * math.sin(5 * a)), py + pr * math.sin(a) * (1 + 0.04 * math.sin(5 * a)))
            for a in np.linspace(0, 2 * math.pi, 72, endpoint=False)]
    C.polygon_cap("BC_Plaza", disc, V["top"] + 0.6, col, m_pz, 12.0)
    C.cliff_skirt("BC_PlazaKerb", disc, V["top"] + 0.6, V["top"] - 0.4, col, m["Cliff"], seed=35, bulge=0.05, lip=0.0,
                  tile=6.0)
    # --- Fortress Rock (north backdrop) + the skull rock's footing (north-east, the path's end)
    for nm, R, seed in (("BC_FortRock", FORT_ROCK, 21), ("BC_SkullBase", SKULL_BASE, 23)):
        pts = C.superellipse(R["a"], R["b"], R["cx"], R["cy"], n=R["n"], count=140, seed=seed, wobble=3.0)
        C.polygon_cap(nm + "_Top", pts, R["top"], col, m["Grass"], GRASS_TILE)
        C.cliff_skirt(nm + "_Cliff", pts, R["top"], -14.0, col, m["Cliff"], seed=seed, bulge=2.2, lip=0.4)

    # --- islets (rock stacks with grass caps) + the sandbar
    for i, (cx, cy, a, b, h) in enumerate(ISLETS):
        pts = C.superellipse(a, b, cx, cy, n=2.6, count=64, seed=40 + i, wobble=2.5)
        C.polygon_cap("BC_Islet%d_Top" % i, pts, h, col, m["Grass"], GRASS_TILE)
        C.cliff_skirt("BC_Islet%d_Cliff" % i, pts, h, -16.0, col, m["Cliff"], seed=40 + i, bulge=2.0, lip=0.3)
    cx, cy, rx, ry = SANDBAR
    ang = np.linspace(0, 2 * math.pi, 48, endpoint=False)
    rings = np.linspace(0, 1, 8)
    P = np.zeros((len(rings), len(ang), 3))
    UV = np.zeros_like(P[..., :2])
    for r, t in enumerate(rings):
        for k, a in enumerate(ang):
            wob = 1 + 0.15 * (C.vnoise_xy(np.array([k / 5.0]), np.array([0.0]), 4096, 61)[0] - 0.5)
            x = cx + rx * max(t, 0.02) * math.cos(a) * wob
            y = cy + ry * max(t, 0.02) * math.sin(a) * wob
            P[r, k] = (x, y, C.SEA_Z + 4.0 - 10.0 * t ** 2)
            UV[r, k] = (x / 20.0, y / 20.0)
    C.grid_mesh("BC_Sandbar", P, UV, col, [m["Sand"]], closed_u=True, flip=True)

    # --- sea: one grid at SEA_Z; V = distance past the shoreline (foam at 0 -> deep at 1 = 150 studs)
    N = 96
    g = np.linspace(-820, 820, N)
    X, Y = np.meshgrid(g, g)
    a, b, n = PLATEAU["a"], PLATEAU["b"], PLATEAU["n"]
    th = np.arctan2(Y, X)
    rr = np.hypot(X, Y)
    c, s = np.cos(th), np.sin(th)
    r_out = 1.0 / ((np.abs(c) / a) ** n + (np.abs(s) / b) ** n) ** (1.0 / n)
    shore = np.zeros_like(X)
    for i in range(N):
        for j in range(N):
            w = beach_width(th[i, j])
            shore[i, j] = w * (5.0 / 12.0) ** (1 / 1.25)  # where beach_z crosses SEA_Z
    dist = rr - r_out - shore
    # foam around the sandbar + islets too
    for (ix, iy, ia, ib, _h) in ISLETS:
        dist = np.minimum(dist, np.hypot((X - ix) / ia, (Y - iy) / ib) * min(ia, ib) - min(ia, ib) - 3)
    dist = np.minimum(dist, np.hypot((X - cx) / rx, (Y - cy) / ry) * min(rx, ry) - min(rx, ry) * 0.75)
    V = 1 - np.clip(dist / 150.0, 0.0, 0.999)  # glTF/Blender v=1 = image top (the foam row)
    P = np.dstack([X, Y, np.full_like(X, C.SEA_Z)])
    UV = np.dstack([X / SEA_TILE, V])
    C.grid_mesh("BC_Sea", P, UV, col, [m["Water"]], flip=False)

    # --- the enemy path
    path_ob, centerline, plen = build_path(col, m["PathSand"], m["Curb"])

    # waypoints (incl. the pier), sparse on straights
    wps = C.rounded_path(PATH_POINTS, CORNER_R, per_corner=3)
    keep = [wps[0]]
    for p in wps[1:]:
        if np.linalg.norm(p - keep[-1]) > 0.9:
            keep.append(p)
    full_len = float(np.sum(np.linalg.norm(np.diff(np.array(keep), axis=0), axis=1)))
    info["waypoints"] = [C.rbx(p[0], p[1], 0.2) for p in keep]
    info["path_length"] = round(full_len, 1)
    info["path_half"] = PATH_HALF
    info["path_points"] = PATH_POINTS
    info["zones"] = [{"name": z["name"], "type": "Hill", "pos": C.rbx(z["cx"], z["cy"], z["top"]),
                      "size": [z["sx"], 1.0, z["sy"]]} for z in zones]
    info["plateau"] = dict(PLATEAU, outline=[C.rbx(x, y, 0) for x, y in outline[::2]])
    info["spawn"] = C.rbx(PATH_POINTS[0][0], PATH_POINTS[0][1], 0.2)
    info["base"] = C.rbx(PATH_POINTS[-1][0], PATH_POINTS[-1][1], 0.2)
    info["sea_z"] = C.SEA_Z
    info["village"] = VILLAGE
    info["plaza"] = PLAZA
    info["streets"] = streets_info
    info["fort_rock"] = FORT_ROCK
    os.makedirs(C.GLB, exist_ok=True)
    with open(os.path.join(C.GLB, "layout_terrain.json"), "w") as f:
        json.dump(info, f, indent=1)
    tris = {o.name: C.tri_count(o) for o in col.objects}
    return {"objects": len(col.objects), "max_tris": max(tris.items(), key=lambda kv: kv[1]),
            "total_tris": sum(tris.values()), "path_length": info["path_length"], "waypoints": len(info["waypoints"])}


result = build()
