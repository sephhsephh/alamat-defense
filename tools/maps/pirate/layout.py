# Bakunawa Cove -- prop layout (B173; pt3: village terrace + streets, themed islets, enemy-path clearance). Places kit pieces around the terrain (terrain.py numbers) as linked
# duplicates in collection "BC_Placed" (renders) and writes glb/layout_props.json for the Studio assembly:
#   [{"a": piece, "p": [x, y, z] (pre-rotation frame, header of common.py), "yaw": radians about Y, "s": scale,
#     "r": footprint radius on the ground (Studio keeps tower zones out of it)}]
# Style target (README.md): DENSE edges -- village, harbour, fortress and foliage crowd the island rim -- while the
# lawns between the path legs stay open for towers. Trees are sunk 6 % of their height + 1.5 studs.
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
R = C.rng(4343)
PI = math.pi

with open(os.path.join(C.GLB, "layout_terrain.json")) as fh:
    TER = json.load(fh)
PATH = C.rounded_path(TER["path_points"], 3.4, per_corner=4)
A, B, N = TER["plateau"]["a"], TER["plateau"]["b"], TER["plateau"]["n"]
MESAS = [(z["pos"][0], -z["pos"][2], z["size"][0] / 1.7, z["size"][2] / 1.7) for z in TER["zones"]]
TREE_H = {"BC_Palm1": 26.0, "BC_Palm2": 20.0, "BC_Palm3": 32.0}
FOOT = {"BC_Palm1": 1.6, "BC_Palm2": 1.6, "BC_Palm3": 1.6, "BC_Bush": 3.0, "BC_BushBig": 5.0, "BC_GrassClump": 0.0,
        "BC_GrassClumpBig": 0.0, "BC_FlowerPatch": 0.0, "BC_Rock1": 5.0, "BC_Rock2": 3.6, "BC_Rock3": 7.0,
        "BC_Rock4": 2.0, "BC_Shack": 9.0, "BC_ShackTall": 10.0, "BC_StallRed": 7.0, "BC_StallTeal": 7.0,
        "BC_LampPost": 1.0, "BC_FlagPole": 1.5, "BC_Fence": 0.5, "BC_Barrel": 1.5, "BC_Crate": 2.0, "BC_Cannon": 3.5,
        "BC_Crane": 2.5, "BC_Tavern": 16.0, "BC_Well": 4.0, "BC_Tent": 5.0, "BC_Watchtower": 6.0, "BC_Lighthouse": 9.0,
        "BC_MarketCart": 4.0, "BC_TableSet": 3.6, "BC_Bench": 3.0, "BC_WeaponRack": 3.5, "BC_Anchor": 4.0,
        "BC_Campfire": 3.0, "BC_LaundryLine": 1.0, "BC_Signpost": 1.0, "BC_Chest": 2.2, "BC_CannonballPile": 2.2,
        "BC_RopeCoil": 1.4}
V = TER["village"]
STREETS = [(s["half"], C.rounded_path(s["pts"], 6.0, per_corner=6, step=2.5)) for s in TER["streets"]]
PX, PY, PR = TER["plaza"]
VZ = V["top"]  # terrace ground
PZ = VZ + 0.6  # plaza top
PLACED = []


def path_d(x, y):
    return float(C.seg_dist(np.array([x]), np.array([y]), PATH)[0])


def plateau_r(x, y):
    """>0 inside the plateau outline: 1 - superellipse value (0 at the rim)."""
    return 1.0 - (abs(x / A) ** N + abs(y / B) ** N)


def edge_dist(x, y):
    """Approx studs from the plateau rim (positive inside)."""
    th = math.atan2(y, x)
    c, s = math.cos(th), math.sin(th)
    r_out = 1.0 / ((abs(c) / A) ** N + (abs(s) / B) ** N) ** (1.0 / N)
    return r_out - math.hypot(x, y)


def on_mesa(x, y, pad=2.0):
    return any(abs(x - mx) < hx + pad and abs(y - my) < hy + pad for mx, my, hx, hy in MESAS)


def beach_width(theta):  # mirror of terrain.py
    w = 40.0 + 10.0 * math.sin(theta) * -1
    w -= 18.0 * max(0.0, -math.cos(theta)) ** 2
    return w


def beach_z(x, y):
    """Ground height on the beach ring outside the plateau (mirror of terrain.py)."""
    d = -edge_dist(x, y)
    w = beach_width(math.atan2(y, x))
    t = min(max(d / w, 0.0), 1.2)
    return -3.0 - 12.0 * t ** 1.25


def free(x, y, r):
    """No overlap with already placed footprints."""
    for q in PLACED:
        if q["r"] > 0 and math.hypot(q["x"] - x, q["y"] - y) < q["r"] + r:
            return False
    return True


def put(a, x, y, z, yaw=None, s=1.0, r=None):
    yaw = R.uniform(0, 2 * PI) if yaw is None else yaw
    if a in TREE_H:
        z -= TREE_H[a] * s * 0.06 + 1.5
    rr = FOOT.get(a, 0.0) * s if r is None else r
    PLACED.append({"a": a, "x": x, "y": y, "z": z, "yaw": yaw, "s": s, "r": rr})


def lawn_ok(x, y, r, path_clear=6.0):
    """A spot on the plateau, clear of the path band, the mesas and other footprints."""
    return plateau_r(x, y) > 0.0 and path_d(x, y) > path_clear + r and not on_mesa(x, y) and free(x, y, r)




def street_d(x, y):
    """Distance past the nearest design-street edge (negative = on a street) -- props never sit on streets."""
    d = 1e9
    for half, cl in STREETS:
        d = min(d, float(C.seg_dist(np.array([x]), np.array([y]), cl)[0]) - half)
    return min(d, math.hypot(x - PX, y - PY) - PR)


def village_r(x, y):
    return 1.0 - (abs((x - V["cx"]) / V["a"]) ** V["n"] + abs((y - V["cy"]) / V["b"]) ** V["n"])


# ------------------------------------------------------------------ hero set pieces
def harbour():
    for x in (-164.0, -152.0, -140.0, -128.0):  # the landing pier: deck under the spawn waypoint (x -160) too, or
        # RigGrounding.GroundY at waypoint 1 misses the deck and every enemy walks at beach height (B173)
        put("BC_PierSeg", x, -12.0, 0.0, 0.0, r=0)
    for y in (0.0, 12.0, 24.0):  # a side jetty to the north
        put("BC_PierSeg", -152.0, y, 0.0, PI / 2, r=0)
    put("BC_PirateShip", -180.0, -32.0, C.SEA_Z, 0.0, r=0)
    put("BC_PirateShip", -228.0, 40.0, C.SEA_Z, 0.35, 0.9, r=0)
    put("BC_Rowboat", -136.0, -24.0, C.SEA_Z, 0.4, r=0)
    put("BC_Rowboat", -165.0, 12.0, C.SEA_Z, -1.2, r=0)
    put("BC_Crane", -122.0, 22.0, 0.0, PI)
    put("BC_FlagPole", -120.0, -24.0, 0.0, 0.0)
    put("BC_Anchor", -118.0, -34.0, 0.0, 0.6)
    put("BC_CannonballPile", -110.0, -36.0, 0.0)
    put("BC_RopeCoil", -124.0, 8.0, 0.0)
    put("BC_RopeCoil", -146.0, 18.0, 0.2, r=0)
    for (x, y, a) in ((-114, -24, "BC_Crate"), (-111, -25.5, "BC_Barrel"), (-114, -27.5, "BC_Barrel"),
                      (-117.5, -26, "BC_Crate"), (-106, 14, "BC_Barrel"), (-103, 16.5, "BC_Crate")):
        put(a, x, y, 0.0)
    put("BC_Crate", -114.0, -24.0, 3.12, 0.3, r=0)  # stacked


def village():
    """Houses line the streets and face them; a plaza with a well + market ring; the tavern on the plaza corner."""
    houses = [  # piece, x, y, yaw (front -Y turned to face its street)
        ("BC_Shack", -64, 92, PI / 2), ("BC_ShackTall", -64, 112, PI / 2),           # Main street, west side
        ("BC_ShackTall", -28, 92, -PI / 2), ("BC_Shack", -28, 110, -PI / 2),         # Main street, east side
        ("BC_Shack", -142, 157, 0.0), ("BC_ShackTall", -124, 158, 0.0), ("BC_Shack", -106, 157, 0.0),  # Cross W, N
        ("BC_ShackTall", -140, 122, PI), ("BC_Shack", -120, 124, PI), ("BC_ShackTall", -100, 122, PI),  # Cross W, S
        ("BC_ShackTall", -14, 154, 0.0), ("BC_Shack", 8, 153, 0.0), ("BC_ShackTall", 28, 148, 0.0),    # Cross E, N
        ("BC_Shack", -8, 121, PI), ("BC_ShackTall", 14, 118, PI),                                      # Cross E, S
    ]
    for a, x, y, yaw in houses:
        put(a, x, y, VZ, yaw + R.uniform(-0.04, 0.04))
    put("BC_Tavern", -78.0, 163.0, VZ, 0.0)
    # the arena's north strip: two shacks behind the garden road + the stairs up to the terrace
    put("BC_Shack", 10.0, 69.0, 0.0, 0.0)
    put("BC_Shack", 27.0, 68.0, 0.0, 0.05)
    put("BC_Stairs", -46.0, 69.0, 0.0, 0.0, (1.0, 0.6, 0.25), r=0)
    # plaza: well in the middle, a ring of stalls facing it, carts, benches
    put("BC_Well", PX, PY, PZ, 0.3)
    for k, a in enumerate((PI / 4, 5 * PI / 4)):  # two stalls on the diagonals (streets enter at N/S/E/W)
        put(("BC_StallRed", "BC_StallTeal")[k], PX + 12.0 * math.cos(a), PY + 12.0 * math.sin(a), PZ, a - PI / 2)
    put("BC_MarketCart", PX + 10.0 * math.cos(3 * PI / 4), PY + 10.0 * math.sin(3 * PI / 4), PZ, 3 * PI / 4)
    put("BC_MarketCart", PX + 10.0 * math.cos(7 * PI / 4), PY + 10.0 * math.sin(7 * PI / 4), PZ, -PI / 4)
    for a in (0.0, PI):
        put("BC_Bench", PX + 6.5 * math.cos(a + PI / 2), PY + 6.5 * math.sin(a + PI / 2), PZ, a)
    # tavern yard + village life
    put("BC_TableSet", -60.0, 160.0, VZ, 0.2)
    put("BC_TableSet", -60.0, 170.0, VZ, -0.1)
    put("BC_Barrel", -95.0, 152.0, VZ)
    put("BC_Barrel", -93.0, 150.0, VZ)
    for x, y, yaw in ((-124, 172, 0.0), (-100, 172, 0.1), (10, 166, -0.2), (-150, 140, PI / 2)):
        put("BC_LaundryLine", x, y, VZ, yaw)
    for x, y, yaw in ((-39, 128, 0.8), (-56, 152, -2.4), (-52, 80, 0.0), (-114, 30, 0.0)):
        put("BC_Signpost", x, y, VZ if y > 74 else 0.0, yaw)
    put("BC_WeaponRack", -60.0, 188.0, VZ, PI)
    put("BC_Watchtower", -150.0, 170.0, VZ, 0.4)
    put("BC_Chest", -62.0, 192.0, VZ, 0.4)
    put("BC_Bench", -40.0, 192.0, VZ, PI)
    put("BC_FlagPole", -48.0, 199.0, VZ, 0.0)
    # lamps along the streets (just off the edge, alternating sides)
    for half, cl in STREETS:
        L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(cl, axis=0), axis=1))])
        side = 1
        for target in np.arange(6.0, L[-1] - 4, 18.0):
            i = int(np.searchsorted(L, target))
            p, q = cl[i], cl[min(i + 1, len(cl) - 1)]
            t = (q - p) / (np.linalg.norm(q - p) + 1e-9)
            n = np.array([-t[1], t[0]]) * side
            x, y = p + n * (half + 1.6)
            z = VZ if village_r(x, y) > 0.0 else 0.0
            if free(x, y, 1.0) and street_d(x, y) > 0.5:
                put("BC_LampPost", float(x), float(y), z, math.atan2(-n[0], n[1]) + PI, r=1.0)
            side = -side
    # enemy-path lamps (5.4 studs off the centreline, alternating sides)
    L = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(PATH, axis=0), axis=1))])
    side = 1
    for target in np.arange(14.0, L[-1] - 10, 30.0):
        i = int(np.searchsorted(L, target))
        p, q = PATH[i], PATH[min(i + 1, len(PATH) - 1)]
        t = (q - p) / (np.linalg.norm(q - p) + 1e-9)
        n = np.array([-t[1], t[0]]) * side
        x, y = p + n * 5.4
        if plateau_r(x, y) > 0.02 and not on_mesa(x, y, 1.0):
            put("BC_LampPost", float(x), float(y), 0.0, math.atan2(-n[0], n[1]) + PI, r=1.0)
        side = -side
    # cannons on the south rim, aiming out to sea, with shot piles
    for x in (-70.0, -27.0, 15.0, 58.0):
        y = -B * (1 - abs(x / A) ** N) ** (1 / N) + 6.0
        put("BC_Cannon", x, y, 0.0, R.uniform(-0.25, 0.25))
        put("BC_CannonballPile", x + 4.5, y + 1.5, 0.0, r=0)
    # barrels + crates by the houses
    for a, x, y, yaw in houses:
        for _ in range(2):
            xx, yy = x + R.uniform(-9, 9), y + R.uniform(-9, 9)
            if village_r(xx, yy) > 0.02 and street_d(xx, yy) > 1.0 and free(xx, yy, 1.6):
                put(R.choice(["BC_Barrel", "BC_Crate"]), xx, yy, VZ)


def fortress():
    z = 42.0
    put("BC_FortKeep", -55.0, 240.0, z, 0.0)
    for x, y in ((-93.0, 222.0), (-17.0, 222.0), (-87.0, 250.0), (-23.0, 250.0)):
        put("BC_FortTower", x, y, z, R.uniform(0, PI))
    for x in (-77.0, -53.0, -29.0):
        put("BC_FortWall", x, 221.0, z, 0.0)
    put("BC_Waterfall", -90.0, 207.5, -4.0, 0.0, 1.05)
    put("BC_Waterfall", -20.0, 207.5, -4.0, 0.12, 1.05)
    put("BC_Footbridge", -55.0, 202.0, -3.0, PI / 2, r=0)  # over the channel under the falls (decor)


def skull_cove():
    put("BC_SkullRock", 84.0, 94.0, 0.0, 0.0, 1.3)  # the finale: scaled up so it reads over the 1.5x island
    put("BC_Treasure", 84.0, 79.0, 0.2, 0.0, 0.9, r=0)
    for x, y in ((112, 64), (60, 60)):
        put("BC_Chest", x, y, 0.0, R.uniform(-0.5, 0.5))


def sea_set():
    put("BC_Shipwreck", 162.0, -122.0, -5.0, 0.6)
    put("BC_Chest", 150.0, -112.0, -4.2, 0.4, r=0)
    put("BC_Anchor", 172.0, -132.0, -4.6, 1.2, r=0)
    put("BC_SerpentBones", 60.0, -185.0, C.SEA_Z, 0.25, r=0)
    put("BC_SerpentBones", -215.0, -140.0, C.SEA_Z, 2.4, 0.8, r=0)
    for (x, y, s) in ((-240, -96, 1.4), (-196, 102, 1.1), (218, -30, 1.6), (130, 174, 1.3), (-88, -182, 1.0),
                      (276, -160, 1.8), (-334, 58, 2.0)):
        put("BC_SeaStack", x, y, C.SEA_Z - 4.0, None, s, r=0)


ISLETS = [(-232, 100, 20, 15, 16), (232, -110, 15, 12, 10), (-140, -188, 12, 10, 8), (310, 72, 28, 20, 24),
          (58, -232, 10, 9, 6), (-330, -58, 22, 16, 18), (174, 218, 30, 18, 28)]  # mirror of terrain.py
FAR = [(-520, 460, 110, 70, 80), (480, 520, 130, 80, 105), (-640, -80, 80, 60, 60), (650, 140, 90, 70, 70)]


def islets():
    """No empty island (user): every islet gets a little story."""
    def on(i, fx, fy):
        cx, cy, a, b, h = ISLETS[i]
        return cx + fx * a, cy + fy * b, h
    # 0: lighthouse islet with a jetty + rowboat
    x, y, z = on(0, 0.0, 0.1)
    put("BC_Lighthouse", x, y, z, PI / 2, r=0)
    put("BC_Dock", -232.0 + 27.0, 100.0, C.SEA_Z + 1.8, PI / 2, r=0)
    put("BC_Rowboat", -232.0 + 30.0, 108.0, C.SEA_Z, 0.3, r=0)
    # 1: castaway camp
    for fx, fy, a, yaw in ((-0.2, 0.1, "BC_Tent", 0.6), (0.3, -0.2, "BC_Campfire", 0.0), (0.35, 0.35, "BC_Chest", 0.9),
                           (-0.45, -0.4, "BC_Barrel", 0.0)):
        x, y, z = on(1, fx, fy)
        put(a, x, y, z, yaw, r=0)
    # 2: buried treasure: chest, an old anchor, a shot pile
    for fx, fy, a in ((0.0, 0.0, "BC_Chest"), (-0.35, 0.3, "BC_Anchor"), (0.35, -0.3, "BC_CannonballPile")):
        x, y, z = on(2, fx, fy)
        put(a, x, y, z, R.uniform(0, 6), r=0)
    # 3: lookout: watchtower, cannon + shot, flag
    for fx, fy, a, yaw in ((0.0, 0.1, "BC_Watchtower", 0.3), (-0.4, -0.3, "BC_Cannon", PI + 0.6),
                           (-0.25, -0.45, "BC_CannonballPile", 0.0), (0.45, -0.3, "BC_FlagPole", 0.0)):
        x, y, z = on(3, fx, fy)
        put(a, x, y, z, yaw, r=0)
    # 4: tiny rock of flotsam (barrels, crate, rope)
    for fx, fy, a in ((0.0, 0.0, "BC_Barrel"), (0.3, 0.2, "BC_Crate"), (-0.3, -0.1, "BC_RopeCoil")):
        x, y, z = on(4, fx, fy)
        put(a, x, y, z, R.uniform(0, 6), r=0)
    # 5: fisher's hut with washing + jetty
    for fx, fy, a, yaw in ((0.0, 0.15, "BC_Shack", 0.4), (0.4, -0.35, "BC_LaundryLine", 0.2),
                           (-0.45, -0.3, "BC_RopeCoil", 0.0), (-0.35, 0.4, "BC_TableSet", 1.0)):
        x, y, z = on(5, fx, fy)
        put(a, x, y, z, yaw, r=0)
    put("BC_Dock", -330.0 + 31.0, -58.0, C.SEA_Z + 1.8, -PI / 2, r=0)
    # 6: ruined fort tower
    for fx, fy, a, s in ((0.0, 0.1, "BC_FortTower", 0.8), (0.4, -0.3, "BC_FortWall", 0.6), (-0.4, -0.3, "BC_Cannon", 1.0)):
        x, y, z = on(6, fx, fy)
        put(a, x, y, z, R.uniform(-0.4, 0.4), s, r=0)
    # palms + bushes + rocks on every islet, big groves (and a far tower) on the far isles
    for (cx, cy, a, b, h) in ISLETS:
        for k in range(int(a * b / 60) + 2):
            ang, rad = R.uniform(0, 2 * PI), R.uniform(0.42, 0.7)  # a ring: the centre belongs to the islet's story prop
            put(R.choice(list(TREE_H)), cx + rad * a * math.cos(ang), cy + rad * b * math.sin(ang), h, None,
                R.uniform(0.8, 1.1), r=0)
        for k in range(int(a * b / 25) + 3):
            ang = R.uniform(0, 2 * PI)
            put(R.choice(["BC_Bush", "BC_GrassClumpBig", "BC_FlowerPatch", "BC_Rock4"]),
                cx + 0.75 * a * math.cos(ang), cy + 0.75 * b * math.sin(ang), h, None, R.uniform(0.9, 1.3), r=0)
    for (cx, cy, a, b, h) in FAR:
        for k in range(14):
            put(R.choice(list(TREE_H)), cx + R.uniform(-0.6, 0.6) * a, cy + R.uniform(-0.6, 0.6) * b, h, None,
                R.uniform(1.6, 2.2), r=0)
    put("BC_FortTower", 480.0 + 26.0, 520.0, 105.0, 0.0, 1.4, r=0)


# ------------------------------------------------------------------ scatter
BACK_Y = 70.0  # north of this the village terrace / skull own the rim


def palms():
    n = 0
    tries = 0
    while n < 72 and tries < 6000:  # arena beach ring + rim
        tries += 1
        th = R.uniform(0, 2 * PI)
        out = R.uniform(-6.0, 20.0)
        c, s = math.cos(th), math.sin(th)
        r_out = 1.0 / ((abs(c) / A) ** N + (abs(s) / B) ** N) ** (1.0 / N)
        x, y = (r_out + out) * c, (r_out + out) * s
        if y > BACK_Y - 20 or (x < -118 and abs(y + 12) < 16):  # keep the pier landing + north strip clear
            continue
        if y < -30 and abs(x) < 80 and out < 12:  # the camera looks in over the south rim: keep it low there
            continue
        if out < 0:
            if not lawn_ok(x, y, 1.6, 7.0) or street_d(x, y) < 2.0:
                continue
            z = 0.0
        else:
            z = beach_z(x, y)
            if z < -7.0 or not free(x, y, 1.6):
                continue
        put(R.choice(list(TREE_H)), x, y, z, None, R.uniform(0.85, 1.2))
        n += 1
    n = 0
    tries = 0
    while n < 46 and tries < 6000:  # village terrace: palms in the yards + along its rim
        tries += 1
        x, y = V["cx"] + R.uniform(-1, 1) * V["a"], V["cy"] + R.uniform(-1, 1) * V["b"]
        if village_r(x, y) < 0.0 or street_d(x, y) < 3.0 or not free(x, y, 2.0):
            continue
        put(R.choice(list(TREE_H)), x, y, VZ, None, R.uniform(0.85, 1.15))
        n += 1
    for x, y in ((-67, 258), (-39, 260), (-101, 240), (-11, 242)):  # on the fort rock
        put(R.choice(list(TREE_H)), x, y, 42.0, None, R.uniform(0.9, 1.15), r=0)


def foliage():
    # along the enemy-path curbs (refs: plants hug the path) -- 5+ studs out so nothing leans over the curb
    for i in range(0, len(PATH), 2):
        p, q = PATH[i], PATH[min(i + 1, len(PATH) - 1)]
        t = (q - p) / (np.linalg.norm(q - p) + 1e-9)
        for side in (-1, 1):
            if R.random() > 0.5:
                continue
            nn = np.array([-t[1], t[0]]) * side
            x, y = p + nn * R.uniform(5.0, 6.4) + t * R.uniform(-1, 1)
            if plateau_r(x, y) > 0.01 and path_d(x, y) > 4.9 and not on_mesa(x, y, 0.5) and street_d(x, y) > 0.5:
                put(R.choice(["BC_GrassClump", "BC_GrassClump", "BC_FlowerPatch"]), float(x), float(y), 0.0, None,
                    R.uniform(0.8, 1.1), r=0)
    # along the design streets: flowers + clumps on both edges (garden-lane feel)
    for half, cl in STREETS:
        for i in range(0, len(cl), 2):
            p, q = cl[i], cl[min(i + 1, len(cl) - 1)]
            t = (q - p) / (np.linalg.norm(q - p) + 1e-9)
            for side in (-1, 1):
                if R.random() > 0.45:
                    continue
                nn = np.array([-t[1], t[0]]) * side
                x, y = p + nn * (half + R.uniform(0.6, 1.6))
                z = VZ if village_r(x, y) > 0.0 else 0.0
                if street_d(x, y) > 0.3 and free(x, y, 0.8) and path_d(x, y) > 6.0:
                    put(R.choice(["BC_FlowerPatch", "BC_GrassClump", "BC_Bush"]), float(x), float(y), z, None,
                        R.uniform(0.7, 1.0), r=0)
    # bushes at every mesa foot
    for mx, my, hx, hy in MESAS:
        for k in range(10):
            a = 2 * PI * k / 10 + R.uniform(-0.2, 0.2)
            x, y = mx + (hx + 1.2) * math.cos(a), my + (hy + 1.2) * math.sin(a)
            if path_d(x, y) > 6.0:
                put(R.choice(["BC_Bush", "BC_GrassClumpBig", "BC_FlowerPatch"]), x, y, 0.0, None, R.uniform(0.8, 1.1), r=0)
    # arena rim band: dense bushes / clumps / flowers / rocks
    n = 0
    tries = 0
    while n < 420 and tries < 14000:
        tries += 1
        x, y = R.uniform(-A, A), R.uniform(-B, B)
        e = edge_dist(x, y)
        if e < 1.0 or e > 13.0 or path_d(x, y) < 7.0 or on_mesa(x, y) or street_d(x, y) < 1.0:
            continue
        if x < -118 and abs(y + 12) < 14:
            continue
        a = R.choice(["BC_Bush", "BC_BushBig", "BC_GrassClump", "BC_GrassClumpBig", "BC_FlowerPatch", "BC_GrassClump",
                      "BC_Rock4", "BC_Rock1"])
        rr = FOOT[a] * 0.6
        if not free(x, y, rr):
            continue
        put(a, x, y, 0.0 if not a.startswith("BC_Rock") else -0.6, None, R.uniform(0.8, 1.25), r=rr)
        n += 1
    # village terrace: yards and rim (between houses, never on streets)
    n = 0
    tries = 0
    while n < 300 and tries < 12000:
        tries += 1
        x, y = V["cx"] + R.uniform(-1, 1) * V["a"], V["cy"] + R.uniform(-1, 1) * V["b"]
        if village_r(x, y) < 0.01 or street_d(x, y) < 0.8:
            continue
        a = R.choice(["BC_Bush", "BC_GrassClump", "BC_GrassClumpBig", "BC_FlowerPatch", "BC_FlowerPatch", "BC_Rock4"])
        rr = FOOT[a] * 0.6
        if not free(x, y, max(rr, 0.8)):
            continue
        put(a, x, y, VZ, None, R.uniform(0.8, 1.2), r=rr)
        n += 1
    # lone clumps + flower patches on the arena lawns (no footprint: towers may stand beside them)
    n = 0
    while n < 140:
        x, y = R.uniform(-A, A), R.uniform(-B, B)
        if plateau_r(x, y) > 0.05 and path_d(x, y) > 6.0 and not on_mesa(x, y, 0.5) and street_d(x, y) > 0.5:
            put(R.choice(["BC_GrassClump", "BC_FlowerPatch"]), x, y, 0.0, None, R.uniform(0.7, 1.0), r=0)
            n += 1
    # beach rocks along the arena cliff foot
    n = 0
    while n < 80:
        th = R.uniform(0, 2 * PI)
        c, s = math.cos(th), math.sin(th)
        r_out = 1.0 / ((abs(c) / A) ** N + (abs(s) / B) ** N) ** (1.0 / N)
        x, y = (r_out + R.uniform(0.5, 6.0)) * c, (r_out + R.uniform(0.5, 6.0)) * s
        if y > BACK_Y or (x < -118 and abs(y + 12) < 14):
            continue
        put(R.choice(["BC_Rock1", "BC_Rock2", "BC_Rock3", "BC_Rock4"]), x, y, beach_z(x, y) - 0.8, None,
            R.uniform(0.7, 1.6), r=0)
        n += 1


# ------------------------------------------------------------------ the enemy path must stay clear (user rule)
CLEAR = TER["path_half"] + 0.6 + 0.4  # tread half + curb + margin, from the centreline


def clear_path(man):
    """Drop every placement whose ground footprint (manifest size x scale) reaches into the enemy path band. The
    pier (the path deck) and the skull cave + treasure (the path ends inside the mouth) are exempt. Returns what was dropped (layout keeps its distance, so ~0)."""
    keep, dropped = [], []
    for q in PLACED:
        if q["a"] in ("BC_PierSeg", "BC_SkullRock", "BC_Treasure") or q["a"] not in man:  # the path deck / its goal
            keep.append(q)
            continue
        size = man[q["a"]]["size"]
        s = q["s"] if not isinstance(q["s"], (tuple, list)) else max(q["s"][:2])
        rad = 0.5 * max(size[0], size[1]) * s * (0.25 if q["a"] in TREE_H else 0.8)  # palms: the trunk, fronds overhead
        if q["z"] > 6.0 or q["z"] < -2.0:  # up on rocks / out at sea: no conflict with the ground path
            keep.append(q)
            continue
        if path_d(q["x"], q["y"]) < CLEAR + rad:
            dropped.append(str(q["a"]))
        else:
            keep.append(q)
    PLACED[:] = keep
    return dropped


def instantiate(man):
    col = C.clear_collection("BC_Placed")
    col.hide_render = False
    missing = set()
    for i, q in enumerate(PLACED):
        if q["a"] not in man:
            missing.add(q["a"])
            continue
        C.instance(q["a"], man, col, (q["x"], q["y"], q["z"]), q["yaw"], q["s"], tag=".%d" % i)
    return sorted(missing)


def write_json():
    out = [{"a": str(q["a"]), "p": C.rbx(q["x"], q["y"], q["z"]), "yaw": round(float(q["yaw"]), 4),
            "s": list(q["s"]) if isinstance(q["s"], (tuple, list)) else round(float(q["s"]), 3),
            "r": round(float(q["r"]), 2)} for q in PLACED]
    with open(os.path.join(C.GLB, "layout_props.json"), "w") as fh:
        json.dump(out, fh, indent=0)
    return len(out)


harbour()
skull_cove()
fortress()
village()
sea_set()
islets()
palms()
foliage()
MAN = C.load_manifests()
dropped = clear_path(MAN)
missing = instantiate(MAN)
count = write_json()
pieces = sorted({str(q["a"]) for q in PLACED})
result = {"placed": count, "missing": missing, "dropped_for_path": dropped, "unique_pieces": len(pieces)}
# design streets are paint only, but they must never touch the enemy path either (smallest edge-to-edge gap, studs)
result["street_gap_to_enemy_path"] = round(min(
    float(np.min(C.seg_dist(cl[:, 0], cl[:, 1], PATH))) - half - CLEAR for half, cl in STREETS), 2)
