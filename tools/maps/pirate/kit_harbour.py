# Bakunawa Cove -- Kit H: harbour (B173). Rules: tools/maps/lobby/README.md (split by material, front -Y, row along
# +X, C.zfight_report = 0). Origins: bottom-centre, EXCEPT boats (origin = WATERLINE centre, place at z = SEA_Z)
# and the pier (origin = pier top level: deck top at +0.2 = the path tread, piles reach z -16).
# Pieces: BC_PierSeg (12 x 10, tiles along X), BC_PirateShip (galleon, Bakunawa figurehead), BC_Rowboat, BC_Crane,
#         BC_Barrel, BC_Crate, BC_Cannon
import importlib.util
import math
import os
import sys

from mathutils import Matrix, Vector

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np
PI = math.pi


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def pier_seg(col, man, origin):
    """12 (X, along the walk) x 10 deck of boards running across, two stringers, 4 piles; rope rails on both sides."""
    P = C.Piece("BC_PierSeg", origin)
    PL, WD, RP = P.bm("Plank"), P.bm("WoodDark"), P.bm("Rope")
    r = C.rng(5)
    for i in range(12):
        x0 = -6 + i * 1.0 + 0.04
        dz = r.uniform(-0.06, 0.04)
        C.box(PL, x0, -5.0 + r.uniform(-0.15, 0.15), -0.25 + dz, x0 + 0.92, 5.0 + r.uniform(-0.15, 0.15), 0.2 + dz,
              bevel=0.08)
    for y in (-3.6, 3.6):
        C.box(WD, -6.0, y - 0.45, -1.4, 6.0, y + 0.45, -0.25, bevel=0.1)
    for x in (-3.0, 3.0):
        for y in (-4.7, 4.7):
            C.drum(WD, (x, y), -16.0, 18.0, 0.55, r_top=0.48, sides=10, bevel=0.15)
            C.drum(RP, (x, y), 1.1, 0.35, 0.62, sides=10, bevel=0.1)  # rope lashing
    for y in (-4.7, 4.7):  # sagging rope rail between the posts, continuing to the neighbours
        pts = [(x, y, 1.3 - 0.35 * math.sin(math.pi * ((x + 3.0) % 6.0) / 6.0)) for x in np.linspace(-6, 6, 13)]
        C.tube(RP, pts, [0.14] * len(pts), sides=6, v_tile=1.0, cap=False)
    return P.done(col, man)


def bakunawa_head(bm, M):
    """Serpent-dragon figurehead (Bakunawa): curling neck, long snout, horns, a back fin. Local frame: +X forward."""
    neck = [(0, 0, 0), (2.0, 0, 1.6), (3.6, 0, 3.8), (4.4, 0, 6.2), (5.6, 0, 7.6), (7.2, 0, 7.9)]
    C.tube(bm, neck, [1.3, 1.25, 1.1, 0.95, 0.9, 0.85], sides=10, v_tile=2.0, M=M)
    head = C.round_profile([(0.0, 0.0), (1.2, 0.4), (1.3, 1.8), (0.8, 3.4), (0.35, 4.4), (0.0, 4.7)], 0.3)
    C.lathe(bm, head, 12, M=M @ Matrix.Translation((6.6, 0, 7.9)) @ Matrix.Rotation(math.pi / 2 - 0.15, 4, "Y")
            @ Matrix.Diagonal((1.0, 0.8, 1.0, 1.0)))
    for s in (-1, 1):  # horns + whisker fins
        C.spike(bm, (7.0, 0.5 * s, 8.8), (5.2, 1.6 * s, 11.2), 0.35, M=M)
        C.spike(bm, (9.6, 0.6 * s, 7.4), (10.6, 2.4 * s, 6.4), 0.18, M=M)
    for k in range(5):  # dorsal fin spikes down the neck
        p = Vector(neck[k + 1])
        C.spike(bm, (p.x - 0.4, 0, p.z + 0.6), (p.x - 1.4, 0, p.z + 2.0 - 0.2 * k), 0.4, sides=6, M=M)


def pirate_ship(col, man, origin):
    """BC_PirateShip ~78 long incl. bowsprit, beam 18, masts to ~52 above the waterline. Black Jolly Roger sails,
    stern castle with lit windows, cannons, rigging, a gold Bakunawa figurehead."""
    P = C.Piece("BC_PirateShip", origin)
    WD, PL, SA, FL = P.bm("WoodDark"), P.bm("Plank"), P.bm("Sail"), P.bm("Flag")
    G, IR, RP, LP = P.bm("Gold"), P.bm("Iron"), P.bm("Rope"), P.bm("Lamp")
    L, W, D = 64.0, 18.0, 7.0
    C.ship_hull(WD, PL, L, W, D, 6.0, stern_raise=4.0, bow_raise=2.5)
    # gold rub-rail stripes (proud tube along each side at 60% freeboard)
    for s in (-1, 1):
        pts = []
        for xn in np.linspace(-0.98, 0.9, 20):
            w = W / 2 * (1 - max(0.0, xn) ** 2.2) ** 0.55 * (1 - 0.12 * max(0.0, -xn) ** 2)
            h = D + 2.5 * max(0.0, xn) ** 2 + 4.0 * max(0.0, -xn - 0.45) / 0.55
            pts.append((xn * L / 2, s * (w * 1.03 + 0.12), h * 0.55))
        C.tube(G, pts, [0.32] * len(pts), sides=6, v_tile=4.0)
    # stern castle (aft cabin) sits on the raised stern deck
    sx0, sx1 = -L / 2 + 1.5, -L / 2 + 13.0
    deck_z = D + 4.0 - 1.6
    C.box(WD, sx0, -6.4, deck_z - 0.3, sx1, 6.4, deck_z + 7.0, bevel=0.3)
    C.box(PL, sx0 - 0.4, -6.9, deck_z + 7.0, sx1 + 0.4, 6.9, deck_z + 7.6, bevel=0.15)  # roof deck
    for s in (-1, 1):
        for x in np.linspace(sx0 + 2.0, sx1 - 2.0, 3):
            C.box(LP, x - 0.8, s * 6.4 - 0.25, deck_z + 2.5, x + 0.8, s * 6.4 + 0.25, deck_z + 4.8, bevel=0.05)
            C.box(G, x - 1.1, s * 6.55 - 0.2, deck_z + 2.2, x + 1.1, s * 6.55 + 0.2, deck_z + 2.5, bevel=0.05)
    for y in np.linspace(-4.0, 4.0, 4):  # stern gallery windows (facing -X)
        C.box(LP, sx0 - 0.25, y - 0.7, deck_z + 2.5, sx0 + 0.25, y + 0.7, deck_z + 5.0, bevel=0.05)
    C.drum(G, (sx0 + 0.2, 0), deck_z + 8.2, 0.6, 1.6, sides=12)  # gold stern lantern base
    C.lathe(LP, [(0.0, 0.0), (0.9, 0.2), (1.0, 1.8), (0.0, 2.4)], 10, center=(sx0 + 0.2, 0, deck_z + 8.8))
    # masts, yards, sails, crow's nest, flags
    for mx, mh, sw in ((15.0, 44.0, 15.0), (0.0, 54.0, 18.0), (-14.0, 40.0, 13.0)):
        base = D - 1.6 if mx > -14 else D
        C.drum(WD, (mx, 0), base - 1.0, mh - base + 1.0, 0.9, r_top=0.55, sides=12, bevel=0.1)
        y0 = base + 6.0
        for k, (zs, frac) in enumerate(((0.0, 1.0), (0.42, 0.78))):
            z0 = y0 + (mh - y0) * zs
            z1 = z0 + (mh - y0) * 0.38
            hw = sw / 2 * frac
            C.sail(SA, mx + 0.9, -hw, hw, z0 + 0.3, z1 - 0.3, belly=1.4 * frac + 0.4)
            C.tube(WD, [(mx + 0.9, -hw - 1.0, z1), (mx + 0.9, hw + 1.0, z1)], [0.35, 0.35], sides=8, v_tile=4.0)
        C.drum(WD, (mx, 0), mh - 9.0, 1.4, 2.2, sides=14, bevel=0.2)  # crow's nest
        C.flag_card(FL, (mx + 0.3, 0.0, mh + 4.0), 5.0, 3.2)
        C.drum(WD, (mx, 0), mh, 4.2, 0.3, sides=8, bevel=0.05)
        for s in (-1, 1):  # shrouds to the rails
            C.tube(RP, [(mx, 0, mh - 8.0), (mx - 2.0, s * (W / 2 - 0.4), D + 0.2)], [0.12, 0.12], sides=5, v_tile=1.0)
    # stays: bowsprit + fore stay, main -> mizzen
    bow = Vector((L / 2 - 0.5, 0, D + 2.2))
    tip = bow + Vector((13.0, 0, 6.0))
    C.tube(WD, [tuple(bow - Vector((3, 0, 1.2))), tuple(tip)], [0.7, 0.35], sides=10, v_tile=4.0)
    C.tube(RP, [tuple(tip), (15.0, 0, 42.0)], [0.14, 0.14], sides=5, v_tile=1.0)
    C.tube(RP, [(0.0, 0, 52.0), (-14.0, 0, 38.0)], [0.14, 0.14], sides=5, v_tile=1.0)
    # cannons out of the gun ports
    for s in (-1, 1):
        for x in (-6.0, 2.0, 10.0, 18.0):
            xn = x / (L / 2)
            w = W / 2 * (1 - max(0.0, xn) ** 2.2) ** 0.55
            C.tube(IR, [(x, s * (w - 0.6), 3.9), (x, s * (w + 2.0), 3.9)], [0.55, 0.42], sides=10, v_tile=2.0)
            C.torus(IR, (x, s * (w + 1.9), 3.9), 0.5, 0.14, seg=12, sides=6, axis="Y")
    # Bakunawa figurehead under the bowsprit
    bakunawa_head(G, Matrix.Translation((L / 2 - 1.5, 0, D - 2.5)) @ Matrix.Diagonal((0.9, 0.9, 0.9, 1.0)))
    galleon_details(P, L, W, D)
    P.smooth["Sail"] = 80.0
    P.smooth["Flag"] = 80.0
    return P.done(col, man)



def hull_at(x, L, W, D, stern_raise=4.0, bow_raise=2.5):
    """(half-beam, sheer height) of C.ship_hull at x -- the detail pass hugs the real hull."""
    xn = max(-1.0, min(0.985, x / (L / 2)))
    w = W / 2 * (1 - max(0.0, xn) ** 2.2) ** 0.55 * (1 - 0.12 * max(0.0, -xn) ** 2)
    h = D + bow_raise * max(0.0, xn) ** 2 + stern_raise * max(0.0, -xn - 0.45) / 0.55
    return w, h


def side_y(w, z, h):
    """Outer skin offset at height z (the hull bulges 3 % at mid-freeboard)."""
    return w * (1 + 0.03 * math.sin(math.pi * max(0.0, min(1.0, z / h))))


def mini_anchor(bm, M):
    C.tube(bm, [(0, 0, 0.6), (0, 0, 5.2)], [0.22, 0.2], sides=8, v_tile=2.0, M=M)
    C.tube(bm, [(-1.6, 0, 4.4), (1.6, 0, 4.4)], [0.16, 0.16], sides=6, v_tile=2.0, M=M)
    arm = [(-2.0, 0, 2.0), (-1.7, 0, 1.0), (-0.9, 0, 0.45), (0, 0, 0.35), (0.9, 0, 0.45), (1.7, 0, 1.0), (2.0, 0, 2.0)]
    C.tube(bm, arm, [0.18] * len(arm), sides=6, v_tile=2.0, M=M)
    C.torus(bm, (0, 0, 5.6), 0.45, 0.1, seg=12, sides=5, axis="Y", M=M)


def galleon_details(P, L, W, D):
    """HERO pass (most detailed asset of the map): raised hull strakes, framed gun ports with open lids, a balustered
    rail along both gunwales, a stern gallery balcony, quarterdeck rail + ship's wheel, stern lanterns, a gold
    Bakunawa-coil transom carving, catheads with hanging anchors, capstan, hatch grates, deck cargo, ratlines."""
    WD, PL, G, IR, RP, LP, VD = (P.bm("WoodDark"), P.bm("Plank"), P.bm("Gold"), P.bm("Iron"), P.bm("Rope"),
                                 P.bm("Lamp"), P.bm("Void"))
    xs = np.linspace(-L / 2 + 0.8, L / 2 - 4.0, 30)
    # raised plank strakes (light Plank bands on the dark hull)
    for s in (-1, 1):
        for f in (0.22, 0.82):
            pts = []
            for x in xs:
                w, h = hull_at(x, L, W, D)
                z = h * f
                pts.append((x, s * (side_y(w, z, h) + 0.1), z))
            C.tube(PL, pts, [0.2] * len(pts), sides=6, v_tile=4.0)
    # gun ports: dark opening + plank frame + a lid propped open above (cannons already poke out at z 3.9)
    for s in (-1, 1):
        for x in (-6.0, 2.0, 10.0, 18.0):
            w, h = hull_at(x, L, W, D)
            y = s * (side_y(w, 3.9, h))
            M = T(x, y, 0.0)
            C.box(VD, -0.85, -0.12, 3.05, 0.85, 0.12, 4.75, bevel=0.03, M=M)
            for zz in (2.85, 4.75):
                C.box(PL, -1.15, -0.2, zz, 1.15, 0.2, zz + 0.2, bevel=0.03, M=M)
            for xx in (-1.15, 0.95):
                C.box(PL, xx, -0.2, 3.05, xx + 0.2, 0.2, 4.75, bevel=0.03, M=M)
            C.box(PL, -1.0, -0.08, 0.0, 1.0, 0.08, 1.7, bevel=0.03,
                  M=M @ T(0, s * 0.25, 4.95) @ Matrix.Rotation(-s * 1.05, 4, "X"))
    # balustered rail along both gunwales (waist only; the castle has its own)
    for s in (-1, 1):
        top = []
        for x in np.arange(-17.0, L / 2 - 6.0, 1.6):
            w, h = hull_at(x, L, W, D)
            y = s * (w - 0.35)
            C.lathe(WD, C.round_profile([(0.0, 0.0), (0.18, 0.0), (0.26, 0.5), (0.14, 1.0), (0.2, 1.3), (0.0, 1.3)],
                                        0.05), 6, center=(x, y, h))
            top.append((x, y, h + 1.35))
        C.tube(PL, top, [0.17] * len(top), sides=6, v_tile=4.0)
    # stern castle: balcony gallery off the transom + quarterdeck rail + the ship's wheel + lanterns
    sx0, sx1 = -L / 2 + 1.5, -L / 2 + 13.0
    deck_z = D + 4.0 - 1.6
    roof = deck_z + 7.6
    C.box(PL, sx0 - 3.2, -5.2, deck_z + 1.8, sx0 - 0.1, 5.2, deck_z + 2.3, bevel=0.08)  # gallery floor
    for y in np.linspace(-4.9, 4.9, 9):
        C.drum(WD, (sx0 - 2.9, y), deck_z + 2.3, 1.4, 0.13, sides=6, bevel=0.02)
    C.box(WD, sx0 - 3.15, -5.2, deck_z + 3.7, sx0 - 2.65, 5.2, deck_z + 4.0, bevel=0.05)
    for y in (-4.4, 4.4):
        C.tube(WD, [(sx0 - 0.2, y, deck_z + 0.2), (sx0 - 2.8, y, deck_z + 1.8)], [0.18, 0.18], sides=6, v_tile=2.0)
    for x in np.arange(sx0 + 0.6, sx1, 1.5):
        for y in (-6.5, 6.5):
            C.drum(WD, (x, y), roof, 1.3, 0.13, sides=6, bevel=0.02)
    for y in (-6.5, 6.5):
        C.box(PL, sx0 + 0.3, y - 0.25, roof + 1.3, sx1 - 0.3, y + 0.25, roof + 1.6, bevel=0.05)
    wheel = T(sx1 - 2.5, 0.0, roof + 0.0)
    C.box(WD, -0.4, -0.5, 0.0, 0.4, 0.5, 2.6, bevel=0.06, M=wheel)
    C.torus(WD, (0.0, 0.0, 3.4), 1.3, 0.12, seg=20, sides=7, axis="X", M=wheel @ T(0.6, 0, 0))  # 7 sides: no face flush with the spokes
    for k in range(8):
        a = PI * k / 4
        C.tube(WD, [(0.6, 0.35 * math.cos(a), 3.4 + 0.35 * math.sin(a)), (0.6, 1.75 * math.cos(a), 3.4 + 1.75 * math.sin(a))], [0.08, 0.06], sides=5, cap=False,
               v_tile=1.0, M=wheel)
    C.drum(G, (0.0, 0.0), -0.3, 0.6, 0.3, sides=10, bevel=0.03, M=wheel @ T(0.6, 0, 3.4) @ Matrix.Rotation(PI / 2, 4, "Y"))
    for y in (-6.6, 6.6):  # stern lanterns on iron arms
        C.tube(IR, [(sx0 + 0.4, y, roof + 1.6), (sx0 - 1.2, y * 1.1, roof + 3.4)], [0.1, 0.1], sides=5, v_tile=1.0)
        C.lathe(LP, [(0.0, 0.0), (0.55, 0.2), (0.6, 1.4), (0.0, 1.9)], 8, center=(sx0 - 1.3, y * 1.1, roof + 1.6))
        C.lathe(G, [(0.0, 1.85), (0.7, 1.95), (0.0, 2.6)], 8, center=(sx0 - 1.3, y * 1.1, roof + 1.6))
    # gold Bakunawa coil carved on the transom, above the gallery windows
    tr = T(sx0 - 0.35, 0.0, deck_z + 5.9) @ Matrix.Rotation(PI / 2, 4, "Y")
    C.torus(G, (0, 0, 0), 2.2, 0.3, seg=28, sides=8, M=tr)
    C.torus(G, (0, 0, 0.0), 1.2, 0.22, seg=20, sides=6, M=tr @ T(0, 0, -0.1))
    for k in range(10):
        a = 2 * PI * k / 10
        C.spike(G, (2.4 * math.cos(a), 2.4 * math.sin(a), 0.0), (3.3 * math.cos(a), 3.3 * math.sin(a), -0.2), 0.22,
                sides=5, M=tr)
    # catheads + anchors hanging at the bow
    for s in (-1, 1):
        w, h = hull_at(24.0, L, W, D)
        C.box(WD, 23.4, s * (w - 0.5) - 0.4, h - 0.2, 24.6, s * (w + 1.6) + 0.4, h + 0.6, bevel=0.08)
        mini_anchor(IR, T(24.0, s * (w + 1.25), h - 6.4))
        C.tube(RP, [(24.0, s * (w + 1.25), h - 0.2), (24.0, s * (w + 1.25), h - 0.6)], [0.09, 0.09], sides=5,
               v_tile=1.0)
    # capstan, hatch grates, deck cargo
    _w, hc = hull_at(6.0, L, W, D)
    dz = hc - 1.6
    C.drum(WD, (6.0, 0.0), dz, 2.4, 0.9, r_top=0.7, sides=12, bevel=0.1)
    for k in range(6):
        a = PI * k / 3
        C.tube(WD, [(6.0, 0.0, dz + 2.0), (6.0 + 2.4 * math.cos(a), 2.4 * math.sin(a), dz + 2.0)], [0.1, 0.1], sides=5,
               v_tile=1.0)
    for x0 in (-8.0, 10.0):
        _w, hh = hull_at(x0, L, W, D)
        z0 = hh - 1.6
        C.box(PL, x0 - 2.0, -1.6, z0, x0 + 2.0, 1.6, z0 + 0.6, bevel=0.06)
        for k in range(5):
            C.box(WD, x0 - 1.7 + k * 0.85 - 0.1, -1.5, z0 + 0.6, x0 - 1.7 + k * 0.85 + 0.1, 1.5, z0 + 0.75, bevel=0.0)
    r = C.rng(64)
    for x, y in ((-12.0, -4.0), (-11.0, -2.6), (-12.2, 4.2), (14.0, 3.5)):
        _w, hh = hull_at(x, L, W, D)
        C.lathe(PL, C.round_profile([(0.0, 0.0), (0.6, 0.0), (0.75, 0.9), (0.6, 1.8), (0.0, 1.8)], 0.08), 10,
                center=(x, y, hh - 1.6))
    for x, y in ((-2.0, 4.6), (16.0, -4.2)):
        _w, hh = hull_at(x, L, W, D)
        for k in range(3):
            C.torus(RP, (x, y, hh - 1.4 + k * 0.32), 0.9 - 0.08 * k, 0.16, seg=16, sides=6)
    # ratlines: a rope ladder on each main + fore shroud pair
    for mx, mh in ((15.0, 44.0), (0.0, 54.0)):
        for s in (-1, 1):
            a0 = Vector((mx - 0.8, 0.0, mh - 8.0))
            b0 = Vector((mx - 2.8, s * (W / 2 - 0.4), D + 0.2))
            a1 = Vector((mx + 0.8, 0.0, mh - 8.0))
            b1 = Vector((mx - 1.2, s * (W / 2 - 0.4), D + 0.2))
            C.tube(RP, [tuple(a1), tuple(b1)], [0.1, 0.1], sides=5, v_tile=1.0)
            for k in range(1, 14):
                t = k / 14.0
                p, q = a0.lerp(b0, t), a1.lerp(b1, t)
                C.tube(RP, [tuple(p), tuple(q)], [0.06, 0.06], sides=4, v_tile=1.0)
        C.torus(WD, (mx, 0, mh - 7.2), 2.2, 0.12, seg=20, sides=6)  # crow's nest rail

def rowboat(col, man, origin):
    P = C.Piece("BC_Rowboat", origin)
    C.ship_hull(P.bm("WoodDark"), P.bm("Plank"), 11.0, 4.4, 1.5, 1.0, stern_raise=0.3, bow_raise=0.6, wall=0.3,
                bulwark=0.9, N=14)
    for x in (-1.6, 1.6):  # thwarts
        C.box(P.bm("Plank"), x - 0.5, -1.8, 0.9, x + 0.5, 1.8, 1.2, bevel=0.06)
    for s in (-1, 1):  # oars resting across
        C.tube(P.bm("Plank"), [(-0.5, s * 0.6, 1.4), (1.5, s * 4.4, 0.0)], [0.12, 0.12], sides=6, v_tile=2.0)
        C.block(P.bm("Plank"), (1.65, s * 4.75, -0.05), (0.7, 1.4, 0.12), bevel=0.04,
                rot=(0, 0, math.atan2(3.8, 2.0) * s))
    return P.done(col, man)


def crane(col, man, origin):
    """Wooden dock hoist: post on a cross base, braced arm over the water, rope, hanging crate."""
    P = C.Piece("BC_Crane", origin)
    WD, PL, RP = P.bm("WoodDark"), P.bm("Plank"), P.bm("Rope")
    C.box(WD, -2.2, -0.5, 0.0, 2.2, 0.5, 0.8, bevel=0.15)
    C.box(WD, -0.5, -2.2, 0.05, 0.5, 2.2, 0.75, bevel=0.15)
    C.box(WD, -0.6, -0.6, 0.8, 0.6, 0.6, 15.0, bevel=0.15)
    C.box(WD, -0.5, -0.5, 13.6, 10.0, 0.5, 14.6, bevel=0.15)  # arm toward +X
    C.tube(WD, [(0.3, 0, 8.0), (5.0, 0, 13.7)], [0.32, 0.32], sides=8, v_tile=3.0)
    C.drum(WD, (0, 0), 15.0, 0.8, 0.9, sides=10)
    C.tube(RP, [(9.5, 0, 13.6), (9.5, 0, 6.6)], [0.13, 0.13], sides=6, v_tile=1.0)
    C.tube(RP, [(9.5, 0, 13.6), (0.0, 0.7, 6.0)], [0.1, 0.1], sides=5, v_tile=1.0)
    C.drum(RP, (0.0, 0.0), 5.6, 0.9, 0.85, sides=12, bevel=0.1)  # rope drum on the post
    C.torus(P.bm("Iron"), (9.5, 0, 6.3), 0.35, 0.1, seg=12, sides=6, axis="Y")
    crate_into(P, (9.5, 0, 2.8), 2.6)
    return P.done(col, man)


def crate_into(P, c, s):
    """Plank box with a dark frame: corner posts (0.26 proud), edge boards along X (0.18) and Y (0.18 / z 0.3) --
    every frame face sits >= 0.08 off its neighbours (no coplanar overlaps)."""
    PL, WD = P.bm("Plank"), P.bm("WoodDark")
    x, y, z = c
    h = s / 2
    C.box(PL, x - h, y - h, z, x + h, y + h, z + s, bevel=0.08)
    for sx in (-1, 1):
        for sy in (-1, 1):
            C.box(WD, x + sx * h - 0.26, y + sy * h - 0.26, z - 0.06, x + sx * h + 0.26, y + sy * h + 0.26, z + s + 0.06,
                  bevel=0.05)
    for sz in (0, 1):
        zc = z + sz * s
        for sy in (-1, 1):
            C.box(WD, x - h - 0.06, y + sy * h - 0.18, zc - 0.18, x + h + 0.06, y + sy * h + 0.18, zc + 0.18, bevel=0.05)
        for sx in (-1, 1):
            C.box(WD, x + sx * h - 0.18, y - h - 0.06, zc - 0.3, x + sx * h + 0.18, y + h + 0.06, zc + 0.3, bevel=0.05)


def crate(col, man, origin):
    P = C.Piece("BC_Crate", origin)
    crate_into(P, (0, 0, 0.06), 3.0)
    return P.done(col, man)


def barrel(col, man, origin):
    P = C.Piece("BC_Barrel", origin)
    prof = C.round_profile([(0.0, 0.0), (1.15, 0.0), (1.45, 1.8), (1.15, 3.6), (0.0, 3.6)], 0.15)
    C.lathe(P.bm("Plank"), prof, 16)
    for z, rr in ((0.45, 1.28), (1.3, 1.44), (2.3, 1.44), (3.15, 1.28)):
        C.torus(P.bm("Iron"), (0, 0, z), rr, 0.1, seg=20, sides=6)
    return P.done(col, man)


def cannon(col, man, origin):
    """Shore cannon on a wooden carriage, barrel toward -Y (the front)."""
    P = C.Piece("BC_Cannon", origin)
    WD, IR = P.bm("WoodDark"), P.bm("Iron")
    C.box(WD, -1.4, -1.8, 0.6, 1.4, 2.2, 1.8, bevel=0.15)
    for x in (-1.6, 1.6):
        for y in (-1.2, 1.6):
            C.drum(WD, (0, 0), -0.7, 0.4, 0.75, sides=12, bevel=0.1,
                   M=Matrix.Translation((x, y, 0.75)) @ Matrix.Rotation(math.pi / 2, 4, "Y"))
    C.tube(IR, [(0, 2.6, 2.3), (0, -3.6, 2.6)], [0.9, 0.62], sides=12, v_tile=2.0)
    C.torus(IR, (0, -3.5, 2.6), 0.62, 0.16, seg=14, sides=6, axis="Y")
    C.lathe(IR, [(0.0, 0.0), (0.55, 0.1), (0.0, 0.9)], 10, M=Matrix.Translation((0, 2.6, 2.3)) @ Matrix.Rotation(-math.pi / 2, 4, "X"))
    return P.done(col, man)


def build():
    col = C.collection_hidden("BC_KitH")
    man = {}
    row = C.Row(gap=12.0)
    pier_seg(col, man, row.next(12))
    pirate_ship(col, man, row.next(80))
    rowboat(col, man, row.next(12))
    crane(col, man, row.next(12))
    crate(col, man, row.next(4))
    barrel(col, man, row.next(3))
    cannon(col, man, row.next(4))
    C.write_manifest("H", man)
    if globals().get("PREVIEW", True):
        C.kit_preview(col, "kitH", samples=16)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    return info


result = build()
