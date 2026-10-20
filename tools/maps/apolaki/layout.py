# Apolaki Sun Terraces -- prop layout (B166). Places linked copies of the PT_* prototypes in
# collection "AST_Layout" (Blender preview) and writes glb/layout_props.json with Roblox-space
# placements: {"a": asset, "p": [x, y, z], "yaw": radians, "s": scale}.
import importlib
import json
import math
import os
import sys

import bpy

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

importlib.reload(C)
np = C.np
R = C.rng(4242)

# keep in sync with terrain.py
PATH_POINTS = [(-64, 8), (-52, 8), (-32, 8), (-32, -12), (-10, -12), (-10, 14), (10, 14), (10, -12),
               (32, -12), (32, 8), (52, 8), (60, 8)]
MESAS = [(-21.0, 3.0, 6.0, 5.0, 5.0), (21.0, 3.0, 6.0, 5.0, 5.0), (0.0, 31.0, 8.0, 5.5, 6.0)]
MEADOW_A, MEADOW_B, MEADOW_CY = 82.0, 50.0, -2.0
VALLEY_Z = -16.0
RIVER = np.array([(-118, 60), (-112, 20), (-104, -20), (-84, -62), (-40, -82), (10, -86), (60, -78),
                  (100, -56), (122, -14), (138, 30), (170, 60)], dtype=float)


def terrace_front(x, k):
    return 46.0 + 9.0 * (k - 1) + 5.0 * math.sin(x / 23.0 + k * 0.7) + 0.0016 * x * x


def seg_dist(px, py, pts):
    d = 1e9
    for a, b in zip(pts[:-1], pts[1:]):
        a = np.array(a, float)
        b = np.array(b, float)
        ab = b - a
        t = max(0.0, min(1.0, ((px - a[0]) * ab[0] + (py - a[1]) * ab[1]) / (ab @ ab)))
        d = min(d, math.hypot(px - a[0] - ab[0] * t, py - a[1] - ab[1] * t))
    return d


def in_meadow(x, y, margin=0.0):
    n = 4.5
    v = (abs(x) / (MEADOW_A - margin)) ** n + (abs(y - MEADOW_CY) / (MEADOW_B - margin)) ** n
    return v < 1.0


def on_mesa(x, y, pad=1.0):
    for cx, cy, hx, hy, h in MESAS:
        if abs(x - cx) < hx + pad and abs(y - cy) < hy + pad:
            return True
    return False


def valley_z(x, y):
    X, Y = np.array([[x]]), np.array([[y]])
    hills = (C.fbm_xy(X / 60.0, Y / 60.0, 4096, 4, 77) - 0.5) * 7
    rd = seg_dist(x, y, RIVER)
    channel = max(0.0, 1 - rd / 12.0) ** 1.5 * 6.5
    outer = min(1.0, max(0.0, (math.hypot(x, y + 30) - 170) / 80.0)) * 18
    return float(VALLEY_Z + hills[0, 0] - channel + outer)


def terrace_at(x, y):
    """(step k, top z) if (x, y) is on a terrace top, else None."""
    for k in range(1, 9):
        f0 = terrace_front(x, k) + 1.2
        f1 = terrace_front(x, k + 1) - 0.6
        if f0 < y < f1:
            return k, 4.0 * k
    return None


placements = []


def put(asset, x, y, z, yaw=None, s=1.0):
    yaw = R.uniform(0, 2 * math.pi) if yaw is None else yaw
    placements.append({"a": asset, "bx": x, "by": y, "bz": z, "yaw": yaw, "s": s})


def scatter():
    # ---- landmarks
    put("SunGate", -62.0, 8.0, 0.0, yaw=0.0)
    put("Shrine", 70.0, 8.0, 0.0, yaw=0.0)
    for sy in (-10.5, 10.5):
        put("Banner", -60.0, 8.0 + sy, 0.0, yaw=0.0)
        put("Banner", 60.0, 8.0 + sy, 0.0, yaw=math.pi)
    # torches along the path, alternating sides
    cl = []
    for a, b in zip(PATH_POINTS[:-1], PATH_POINTS[1:]):
        a, b = np.array(a, float), np.array(b, float)
        n = int(np.linalg.norm(b - a) / 2)
        for j in range(n):
            cl.append(a + (b - a) * j / n)
    side = 1
    for i in range(10, len(cl) - 6, 13):
        p = cl[i]
        q = cl[min(i + 1, len(cl) - 1)]
        t = (q - p) / (np.linalg.norm(q - p) + 1e-9)
        nrm = np.array([-t[1], t[0]]) * side
        x, y = p + nrm * 4.0
        if not on_mesa(x, y, 0.5):
            put("Torch", float(x), float(y), 0.0, yaw=0.0)
        side *= -1

    # ---- meadow rim: trees, bushes, rocks (outside the path, not in the centre field)
    for i in range(70):
        th = R.uniform(0, 2 * math.pi)
        inset = R.uniform(3.0, 11.0)
        x = (MEADOW_A - inset) * math.copysign(abs(math.cos(th)) ** (2 / 4.5), math.cos(th))
        y = MEADOW_CY + (MEADOW_B - inset) * math.copysign(abs(math.sin(th)) ** (2 / 4.5), math.sin(th))
        if seg_dist(x, y, PATH_POINTS) < 7 or on_mesa(x, y, 2) or y > 40 or abs(x) > 54 and abs(y - 8) < 14:
            continue
        r = R.random()
        if y < -22 and abs(x) < 58 and r < 0.45:  # keep the front rim low: the camera looks over it
            r = 0.5
        if r < 0.32:
            put("TreeBroad" if R.random() < 0.6 else "TreeBroad2", x, y, 0.0, s=R.uniform(0.85, 1.15))
        elif r < 0.45:
            put("TreeTall", x, y, 0.0, s=R.uniform(0.85, 1.1))
        elif r < 0.75:
            put("Bush" if R.random() < 0.6 else "BushSmall", x, y, 0.0, s=R.uniform(0.8, 1.3))
        else:
            put(["RockA", "RockB", "RockC"][R.integers(3)], x, y, 0.0, s=R.uniform(0.7, 1.2))

    # ---- meadow ground cover: tufts + flowers + small rocks everywhere except path / mesas
    for _ in range(420):
        x, y = R.uniform(-80, 80), R.uniform(-50, 46)
        if not in_meadow(x, y, 2.0) or seg_dist(x, y, PATH_POINTS) < 3.4:
            continue
        z = 0.0
        for cx, cy, hx, hy, h in MESAS:
            if abs(x - cx) < hx - 0.8 and abs(y - cy) < hy - 0.8:
                z = h
            elif abs(x - cx) < hx + 1.0 and abs(y - cy) < hy + 1.0:
                z = None
        if z is None:
            continue
        r = R.random()
        if r < 0.72:
            put("GrassTuft", x, y, z, s=R.uniform(0.8, 1.4))
        elif r < 0.93:
            put("Flowers", x, y, z, s=R.uniform(0.8, 1.3))
        elif z == 0.0:
            put("RockB", x, y, z, s=R.uniform(0.4, 0.8))

    # ---- terraces: palms, bamboo, huts, bushes, tufts
    huts = 0
    for _ in range(900):
        x, y = R.uniform(-170, 170), R.uniform(46, 130)
        t = terrace_at(x, y)
        if t is None:
            continue
        k, z = t
        r = R.random()
        if r < 0.05:
            put("Palm", x, y, z, s=R.uniform(0.9, 1.2))
        elif r < 0.09:
            put("Bamboo", x, y, z, s=R.uniform(0.8, 1.1))
        elif r < 0.105 and huts < 4 and 2 <= k <= 6 and abs(x) > 30:
            put("Hut", x, y, z, yaw=math.pi / 2 + R.uniform(-0.3, 0.3))
            huts += 1
        elif r < 0.14:
            put("TreeBroad2", x, y, z, s=R.uniform(0.8, 1.0))
        elif r < 0.3:
            put("Bush", x, y, z, s=R.uniform(0.7, 1.1))
        elif r < 0.45:
            put("GrassTuft", x, y, z, s=R.uniform(1.0, 1.5))

    # ---- valley + far bank: forest around the river (outside the meadow cliff)
    placed = 0
    for _ in range(4000):
        if placed >= 150:
            break
        x, y = R.uniform(-240, 240), R.uniform(-240, 140)
        if in_meadow(x, y, -6.0) or seg_dist(x, y, RIVER) < 15:
            continue
        if y > 40 and terrace_front(x, 1) < y:
            continue
        if math.hypot(x + 112, y - 62) < 22:  # waterfall rock
            continue
        z = valley_z(x, y)
        r = R.random()
        if r < 0.38:
            put("TreeBroad", x, y, z, s=R.uniform(0.9, 1.4))
        elif r < 0.6:
            put("TreeTall", x, y, z, s=R.uniform(0.9, 1.3))
        elif r < 0.72:
            put("Palm", x, y, z, s=R.uniform(0.9, 1.3))
        elif r < 0.86:
            put("Bush", x, y, z, s=R.uniform(1.0, 1.6))
        else:
            put(["RockA", "RockC"][R.integers(2)], x, y, z, s=R.uniform(0.8, 1.6))
        placed += 1
    # river-side rocks
    for i in range(24):
        j = R.uniform(0, len(RIVER) - 1.01)
        a = RIVER[int(j)]
        b = RIVER[int(j) + 1]
        p = a + (b - a) * (j - int(j))
        t = (b - a) / np.linalg.norm(b - a)
        nrm = np.array([-t[1], t[0]]) * (1 if R.random() < 0.5 else -1)
        x, y = p + nrm * R.uniform(9, 13)
        if in_meadow(x, y, -4):
            continue
        put(["RockA", "RockC"][R.integers(2)], float(x), float(y), valley_z(x, y) - 0.5, s=R.uniform(0.6, 1.2))


def instantiate():
    col = C.clear_collection("AST_Layout")
    protos = {}
    for o in bpy.data.collections["AST_Assets"].objects:
        if o.type != "MESH" or "__FX" in o.name:
            continue
        asset = o.name[3:].split("__")[0]
        protos.setdefault(asset, []).append(o)
    for i, pl in enumerate(placements):
        for src in protos.get(pl["a"], []):
            ob = bpy.data.objects.new("L%04d_%s" % (i, src.name[3:]), src.data)  # linked copy
            ob.location = (pl["bx"], pl["by"], pl["bz"])
            ob.rotation_euler = (0, 0, pl["yaw"])
            ob.scale = (pl["s"],) * 3
            col.objects.link(ob)
    return len(col.objects)


def write_json():
    out = []
    for pl in placements:
        out.append({"a": pl["a"], "p": [round(pl["bx"], 3), round(pl["bz"], 3), round(-pl["by"], 3)],
                    "yaw": round(pl["yaw"], 4), "s": round(pl["s"], 3)})
    with open(os.path.join(C.GLB, "layout_props.json"), "w") as f:
        json.dump(out, f)
    counts = {}
    for pl in placements:
        counts[pl["a"]] = counts.get(pl["a"], 0) + 1
    return counts


placements.clear()
scatter()
n = instantiate()
result = {"placements": len(placements), "objects": n, "counts": write_json()}
