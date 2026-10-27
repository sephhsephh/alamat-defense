# Bakunawa Cove -- bake everything the Studio assembly needs into glb/studio_data.json, in ROBLOX coordinates
# relative to the import anchors (Blender (x, y, z) -> Roblox (-x, z + OFFSET, y); a Blender yaw about Z is the same
# angle about Roblox Y; a Blender front -Y is Roblox -Z = LookVector). OFFSET 30 = Stage 1's map height (the Place's
# Baseplate top is 0). Also computes the tower zones (2-stud Ground strips + Hill blocks), the path strips, the
# collision edges and the waypoints, so the Studio side only clones and parents.
# Run: sh tools/maps/pirate/run.sh studio_data.py   (no save needed)
import importlib.util
import json
import math
import os
import sys

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np
OFFSET = 30.0


def R(x, y, z):
    return [round(-float(x), 3), round(float(z) + OFFSET, 3), round(float(y), 3)]


with open(os.path.join(C.GLB, "layout_terrain.json")) as fh:
    TER = json.load(fh)
with open(os.path.join(C.GLB, "layout_props.json")) as fh:
    PROPS = json.load(fh)
MAN = C.load_manifests()
MAN.pop("BC_Captain", None)
MAN.pop("BC_SkeletonPirate", None)

A, B, N = TER["plateau"]["a"], TER["plateau"]["b"], TER["plateau"]["n"]
V = TER["village"]
HALF = TER["path_half"]
pts = TER["path_points"]
PATH = C.rounded_path(pts, 3.4, per_corner=4)
MESAS = [(z["pos"][0], -z["pos"][2], z["size"][0] / 1.7, z["size"][2] / 1.7, z["pos"][1]) for z in TER["zones"]]
STREETS = [(s["half"], C.rounded_path(s["pts"], 6.0, per_corner=6, step=2.5)) for s in TER["streets"]]


def plateau_v(x, y):
    return abs(x / A) ** N + abs(y / B) ** N


def village_v(x, y):
    return abs((x - V["cx"]) / V["a"]) ** V["n"] + abs((y - V["cy"]) / V["b"]) ** V["n"]


out = {"offset": OFFSET}
# ---- protos: piece -> origin (Roblox, relative to its import anchor) + object names
out["protos"] = {k: {"origin": R(*v["origin"]), "objects": v["objects"]} for k, v in MAN.items()}
out["protos"] = {k: dict(v, origin=[v["origin"][0], v["origin"][1] - OFFSET, v["origin"][2]]) for k, v in out["protos"].items()}
# ---- placements (props JSON is in the pre-rotation frame (x, z, -y) -> Blender (x, -p3, p2))
pieces = sorted({p["a"] for p in PROPS})
idx = {a: i for i, a in enumerate(pieces)}
rows = []
footprints = []
for p in PROPS:
    bx, by, bz = p["p"][0], -p["p"][2], p["p"][1]
    s = p["s"]
    s = [s[0], s[2], s[1]] if isinstance(s, list) else s  # Blender (sx, sy, sz) -> Roblox (sx, sz->Y, sy->Z)
    rows.append([idx[p["a"]]] + R(bx, by, bz) + [p["yaw"], s])
    if p["r"] > 0 and abs(bz) < 1.0:
        footprints.append((bx, by, p["r"]))
out["pieces"] = pieces
out["props"] = rows
# ---- waypoints / spawn / base
out["waypoints"] = [R(w[0], -w[2], w[1] + 0.4) for w in TER["waypoints"]]
out["spawn"] = R(pts[0][0], pts[0][1], 0.5)
out["base"] = R(pts[-1][0], pts[-1][1], 0.5)
# ---- path strips (placement blockers for PathClearance), one per waypoint segment
wp = out["waypoints"]
strips = []
for a, b in zip(wp[:-1], wp[1:]):
    dx, dz = b[0] - a[0], b[2] - a[2]
    L = math.hypot(dx, dz)
    if L < 0.05:
        continue
    strips.append([round((a[0] + b[0]) / 2, 3), round((a[2] + b[2]) / 2, 3), round(L + 5.4, 3), round(math.atan2(dx, dz), 4)])
out["pathstrips"] = strips
# ---- Ground zone strips: rows 2 studs apart over the arena, minus rim (2), path band, mesas, streets, footprints
CLEAR = HALF + 0.6 + 0.8
zones = []
xs = np.arange(-A, A + 0.01, 0.5)
for y in np.arange(-B + 1.0, B - 0.99, 2.0):
    ok = []
    d_path = C.seg_dist(xs, np.full(xs.shape, y), PATH)
    d_st = np.full(xs.shape, 1e9)
    for half, cl in STREETS:
        d_st = np.minimum(d_st, C.seg_dist(xs, np.full(xs.shape, y), cl) - half)
    for i, x in enumerate(xs):
        good = plateau_v(x, y) < 0.86 and village_v(x, y) > 1.02 and d_path[i] > CLEAR and d_st[i] > 0.5
        if good:
            for mx, my, hx, hy, _t in MESAS:
                if abs(x - mx) < hx + 1.5 and abs(y - my) < hy + 1.5:
                    good = False
                    break
        if good:
            for fx, fy, fr in footprints:
                if math.hypot(x - fx, y - fy) < fr + 0.6:
                    good = False
                    break
        ok.append(good)
    i = 0
    while i < len(xs):
        if ok[i]:
            j = i
            while j + 1 < len(xs) and ok[j + 1]:
                j += 1
            if xs[j] - xs[i] >= 2.0:
                a, b = R(xs[i], y, 0)[0], R(xs[j], y, 0)[0]
                zones.append([round((a + b) / 2, 3), round(y, 3), round(abs(b - a) + 0.5, 3)])
            i = j + 1
        else:
            i += 1
out["ground"] = zones  # [roblox x centre, roblox z, length]; top = OFFSET + 0.05
out["hills"] = [{"name": n, "x": -mx, "z": my, "top": OFFSET + top + 0.05, "hx": hx, "hy": hy}
                for (mx, my, hx, hy, top), n in zip(MESAS, [z["name"] for z in TER["zones"]])]
# ---- collision edges: arena rim (skip where the village terrace meets it, and the pier landing) + village rim
edges = []


def ring(a, b, cx, cy, n, z0, skip, inset=1.0, count=180):
    pts2 = []
    for k in range(count):
        th = 2 * math.pi * k / count
        c, s = math.cos(th), math.sin(th)
        r = 1.0 / ((abs(c) / a) ** n + (abs(s) / b) ** n) ** (1.0 / n) - inset
        pts2.append((cx + r * c, cy + r * s))
    for (x0, y0), (x1, y1) in zip(pts2, pts2[1:] + pts2[:1]):
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        if skip(mx, my):
            continue
        p0, p1 = R(x0, y0, z0 + 8.0), R(x1, y1, z0 + 8.0)
        L = math.hypot(p1[0] - p0[0], p1[2] - p0[2])
        edges.append([round((p0[0] + p1[0]) / 2, 3), p0[1], round((p0[2] + p1[2]) / 2, 3), round(L + 0.4, 3),
                      round(math.atan2(p1[0] - p0[0], p1[2] - p0[2]), 4)])


ring(A, B, 0.0, 0.0, N, 0.0, lambda x, y: village_v(x, y) < 1.15 or (x < -100 and abs(y + 12) < 9))
ring(V["a"], V["b"], V["cx"], V["cy"], V["n"], V["top"], lambda x, y: plateau_v(x, y) < 1.15)
out["edges"] = edges  # [x, y, z, length, yaw]: 1 x 16 x length walls

path = os.path.join(C.GLB, "studio_data.json")
with open(path, "w") as fh:
    json.dump(out, fh, separators=(",", ":"))
result = {"kb": os.path.getsize(path) // 1024, "pieces": len(pieces), "props": len(rows), "waypoints": len(wp),
          "ground_strips": len(zones), "hills": len(out["hills"]), "edges": len(edges), "pathstrips": len(strips)}
