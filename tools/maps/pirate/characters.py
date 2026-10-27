# Bakunawa Cove -- characters (B173): BC_Captain (pirate captain NPC) and BC_SkeletonPirate (Stage 2 enemy).
# Separate work file: Downloads\BakunawaCove_Map\BakunawaCove_Characters.blend (scene BakunawaCove_Characters).
# Run: BLEND_FILE=<that file> sh tools/maps/pirate/run.sh characters.py save
# Same kit rules as the map (split by material <Piece>__<Mat>, origin = between the feet, FRONT -Y, z-fight 0).
# Chunky stylized proportions (big head, ~2.5 heads tall body), 1 unit = 1 stud: captain ~7.2, skeleton ~6.4.
# Static T-free "idle" poses; rigging for Roblox (R15) is a later step.
import importlib.util
import math
import os
import sys

import bmesh
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


def D(sx, sy, sz):
    return Matrix.Diagonal((sx, sy, sz, 1.0))


def ell(bm, c, r, sides=16, rings=8, M=None):
    """Ellipsoid at c with radii r (lathe of a unit circle, scaled)."""
    prof = [(0.0, -1.0)] + [(math.sin(t), -math.cos(t)) for t in np.linspace(PI / rings, PI - PI / rings, rings - 1)] + \
           [(0.0, 1.0)]
    Mx = T(*c) @ D(*r)
    return C.lathe(bm, prof, sides, M=(M @ Mx) if M is not None else Mx)


def ring_strip(bm, rows, th0=0.0, th1=2 * PI, n=32, thick=0.08, ysc=1.0, cy=0.0, jag=0.0, seed=0):
    """Open or closed cloth band around the body (coat skirt, vest, shorts): rows = [(radius, z), ...] top -> bottom,
    swept from angle th0 to th1 (front = -90 deg). Gives it `thick` (inner skin + closed edges). jag = ragged hem."""
    tmp = bmesh.new()
    closed = abs((th1 - th0) - 2 * PI) < 1e-6
    angs = np.linspace(th0, th1, n, endpoint=not closed)
    r = C.rng(seed)
    hem = [r.uniform(-1, 1) * jag for _ in angs]
    outer, inner = [], []
    for i, (rad, z) in enumerate(rows):
        last = i == len(rows) - 1
        o_row, i_row = [], []
        for k, a in enumerate(angs):
            zz = z + (hem[k] if last else 0.0)
            ca, sa = math.cos(a), math.sin(a)
            o_row.append(tmp.verts.new((rad * ca, cy + rad * sa * ysc, zz)))
            i_row.append(tmp.verts.new(((rad - thick) * ca, cy + (rad - thick) * sa * ysc, zz)))
        outer.append(o_row)
        inner.append(i_row)
    K = len(angs)
    kmax = K if closed else K - 1
    for i in range(len(rows) - 1):
        for k in range(kmax):
            k2 = (k + 1) % K
            tmp.faces.new((outer[i][k], outer[i + 1][k], outer[i + 1][k2], outer[i][k2]))
            tmp.faces.new((inner[i][k], inner[i][k2], inner[i + 1][k2], inner[i + 1][k]))
    for row in (0, len(rows) - 1):  # top + hem rims
        for k in range(kmax):
            k2 = (k + 1) % K
            tmp.faces.new((outer[row][k], outer[row][k2], inner[row][k2], inner[row][k]))
    if not closed:  # the two front edges
        for k in (0, K - 1):
            for i in range(len(rows) - 1):
                tmp.faces.new((outer[i][k], inner[i][k], inner[i + 1][k], outer[i + 1][k]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp)


def cutlass(blade, gold, grip, M):
    """Curved cutlass, blade along local +Z from a guard at z 1.1; grip below (local z 0..1.1)."""
    pts = [(0.0, 0.0), (0.34, 0.0)] + [(0.34 + 0.22 * t * t, 3.0 * t) for t in np.linspace(0.2, 1.0, 5)] + \
          [(0.46, 3.32), (0.0, 3.0)]
    C.prism(blade, [(x - 0.17, z + 1.25) for x, z in pts], -0.04, 0.04, bevel=0.0, M=M)
    C.torus(gold, (0.0, 0.0, 1.12), 0.42, 0.07, seg=16, sides=7, axis="Y", M=M)
    C.box(gold, -0.5, -0.1, 1.1, 0.5, 0.1, 1.27, bevel=0.03, M=M)
    C.drum(grip, (0.0, 0.0), 0.05, 1.05, 0.12, sides=8, bevel=0.03, M=M)
    ell(gold, (0.0, 0.0, 0.0), (0.18, 0.18, 0.16), 10, 6, M=M)


def limb(bm, pts, radii, sides=12):
    return C.tube(bm, pts, radii, sides=sides, v_tile=1.5)


# ================================================================ the captain
def captain(col, man, origin):
    """BC_Captain ~7.4H: tricorn with a skull emblem, eyepatch, braided beard, crimson long coat with gold trim and
    epaulettes, cream shirt frill, leather belt + gold buckle, flintlock in the belt, tall cuffed boots, a cutlass in
    the right hand pointing down, the scabbard on the left hip."""
    P = C.Piece("BC_Captain", origin)
    SK, CR, LE, HR, CD = P.bm("Skin"), P.bm("CoatRed"), P.bm("Leather"), P.bm("Hair"), P.bm("ClothDark")
    G, CV, IR, VD, WD, BN = P.bm("Gold"), P.bm("Canvas"), P.bm("Iron"), P.bm("Void"), P.bm("WoodDark"), P.bm("Bone")
    for s in (-1, 1):
        # boots: tall shaft + turned-down cuff + foot
        C.lathe(LE, C.round_profile([(0.0, 0.0), (0.4, 0.0), (0.42, 0.3), (0.38, 1.15), (0.46, 1.5), (0.0, 1.5)], 0.06),
                14, center=(s * 0.48, 0.0, 0.0))
        C.lathe(LE, C.round_profile([(0.0, 1.38), (0.52, 1.38), (0.56, 1.72), (0.0, 1.72)], 0.08), 14,
                center=(s * 0.48, 0.0, 0.0))
        ell(LE, (s * 0.48, -0.32, 0.24), (0.36, 0.56, 0.24))
        # trousers
        limb(CD, [(s * 0.46, 0.0, 1.55), (s * 0.47, -0.04, 2.3), (s * 0.44, 0.0, 3.15)], [0.34, 0.37, 0.42])
    # long coat: skirt open at the front, torso, belt + buckle, lapel trim, buttons
    ring_strip(CR, [(0.96, 3.25), (1.08, 2.5), (1.28, 1.55)], th0=-PI / 2 + 0.55, th1=-PI / 2 - 0.55 + 2 * PI, n=28,
               thick=0.09, ysc=0.78, jag=0.0)
    ell(CR, (0.0, 0.0, 3.95), (0.98, 0.72, 1.05), 20, 10)
    ell(CV, (0.0, -0.52, 4.3), (0.42, 0.26, 0.5), 12, 6)  # shirt frill in the open neck
    C.torus(LE, (0.0, 0.0, 3.2), 0.97, 0.13, seg=28, sides=8, M=D(1.0, 0.78, 1.0))
    C.box(G, -0.26, -0.86, 3.02, 0.26, -0.72, 3.38, bevel=0.05)
    C.box(LE, -0.12, -0.9, 3.12, 0.12, -0.84, 3.28, bevel=0.02)  # buckle hole (dark leather peeking through)
    for s in (-1, 1):
        limb(G, [(s * 0.32, -0.62, 4.62), (s * 0.4, -0.66, 4.0), (s * 0.44, -0.6, 3.35)], [0.06, 0.06, 0.06], 6)
        for z in (3.55, 3.85, 4.15):
            ell(G, (s * 0.6, -0.6 + 0.04 * (z - 3.85), z), (0.07, 0.05, 0.07), 8, 4)
    # flintlock tucked in the belt (right front)
    C.tube(IR, [(0.55, -0.82, 3.55), (0.62, -0.86, 2.75)], [0.07, 0.06], sides=8, v_tile=1.0)
    C.prism(WD, [(0.0, 0.0), (0.42, 0.18), (0.36, 0.42), (0.02, 0.26)], -0.07, 0.07, bevel=0.02,
            M=T(0.52, -0.84, 3.48) @ Matrix.Rotation(-0.2, 4, "Y"))
    # scabbard on the left hip
    C.tube(LE, [(-0.98, -0.25, 3.05), (-1.18, 0.35, 1.55)], [0.12, 0.08], sides=8, v_tile=1.0)
    C.drum(G, (0, 0), -0.05, 0.1, 0.15, sides=8, M=T(-1.18, 0.35, 1.55))
    # arms: coat sleeves, big turned-back cuffs with gold rims, hands
    for s in (-1, 1):
        sh, el = Vector((s * 1.0, 0.0, 4.55)), Vector((s * 1.32, -0.06, 3.6))
        wr = Vector((s * 1.38, -0.28, 2.88))
        limb(CR, [tuple(sh), tuple(el), tuple(wr)], [0.36, 0.31, 0.29])
        d = (wr - el).normalized()
        limb(CR, [tuple(wr - d * 0.35), tuple(wr + d * 0.05)], [0.4, 0.43])
        q = d.to_track_quat("Z", "Y").to_matrix().to_4x4()
        C.torus(G, (0, 0, 0), 0.42, 0.06, seg=18, sides=7, M=T(*(wr + d * 0.05)) @ q)
        ell(SK, tuple(wr + d * 0.32), (0.24, 0.22, 0.28))
        ell(SK, tuple(wr + d * 0.2 + Vector((-s * 0.18, -0.12, 0.0))), (0.08, 0.08, 0.15), 8, 5)  # thumb
        # epaulette + fringe
        ell(G, (s * 0.98, 0.0, 4.86), (0.44, 0.42, 0.13), 16, 6)
        for k in range(7):
            a = (0.0 if s > 0 else PI) + 1.35 * (k - 3) / 3  # around the outer half of the epaulette
            px, py = s * 0.98 + 0.42 * math.cos(a), 0.42 * math.sin(a)
            C.tube(G, [(px, py, 4.82), (px, py, 4.45)], [0.035, 0.03], sides=5, v_tile=1.0)
    # cutlass held in the right hand, blade down and a little forward
    hand = Vector((1.38, -0.28, 2.88)) + (Vector((1.38, -0.28, 2.88)) - Vector((1.32, -0.06, 3.6))).normalized() * 0.3
    cutlass(IR, G, LE, T(*hand) @ Matrix.Rotation(PI - 0.35, 4, "X") @ D(0.62, 0.62, 0.62) @ T(0, 0, -0.55))
    # head: neck, face, ear, nose, eye, eyepatch + strap, brows, beard, moustache, hair + braid
    C.drum(SK, (0.0, 0.0), 4.6, 0.45, 0.3, sides=12, bevel=0.05)
    ell(SK, (0.0, 0.0, 5.55), (0.82, 0.78, 0.88), 20, 10)
    for s in (-1, 1):
        ell(SK, (s * 0.8, 0.05, 5.55), (0.1, 0.16, 0.22), 10, 5)
    ell(SK, (0.0, -0.84, 5.45), (0.13, 0.16, 0.2), 10, 5)
    ell(VD, (0.3, -0.69, 5.72), (0.12, 0.08, 0.15), 10, 5)  # the good eye
    ell(LE, (-0.3, -0.7, 5.74), (0.24, 0.08, 0.22), 12, 5)  # eyepatch
    C.torus(LE, (0.0, 0.0, 0.0), 0.86, 0.035, seg=28, sides=6, M=T(0.0, 0.0, 5.72) @ Matrix.Rotation(-0.42, 4, "Y"))
    for s in (-1, 1):
        C.block(HR, (s * 0.3, -0.74, 5.95), (0.34, 0.08, 0.08), bevel=0.03, rot=(0.0, s * 0.25, 0.0))
    ell(HR, (0.0, -0.42, 5.0), (0.66, 0.48, 0.5), 16, 8)  # beard
    ell(HR, (0.0, -0.56, 4.68), (0.3, 0.28, 0.36), 12, 6)  # braided tip
    C.torus(G, (0.0, -0.58, 4.5), 0.16, 0.05, seg=14, sides=6)  # beard ring
    for s in (-1, 1):
        limb(HR, [(0.0, -0.88, 5.3), (s * 0.28, -0.86, 5.26), (s * 0.5, -0.76, 5.12), (s * 0.62, -0.6, 4.96)],
             [0.08, 0.09, 0.07, 0.04], 8)
    ell(HR, (0.0, 0.22, 5.45), (0.82, 0.68, 0.78), 18, 8)  # hair at the back
    limb(HR, [(0.0, 0.72, 5.3), (0.0, 0.85, 4.9), (0.0, 0.8, 4.4)], [0.16, 0.13, 0.08], 8)
    # tricorn: crown + 3-corner brim (corners front + back sides, the brim between them turned up) + gold edge
    C.lathe(LE, C.round_profile([(0.0, 6.2), (0.86, 6.2), (0.9, 6.62), (0.72, 7.0), (0.0, 7.12)], 0.08), 18,
            center=(0.0, 0.05, 0.0))
    tmp = bmesh.new()
    n = 48
    rows = []
    edge = []
    for spec in (("in_top", 0.82, 0.0), ("out_top", 1.0, 0.0), ("out_bot", 1.0, -0.09), ("in_bot", 0.82, -0.09)):
        row = []
        for k in range(n):
            a = 2 * PI * k / n
            c3 = (1 + math.cos(3 * (a + PI / 2))) / 2  # 1 at the 3 corners (front = -90 deg)
            up = 1 - c3
            ro = 1.0 + 0.62 * c3 + 0.28 * up
            rr = 0.86 if spec[1] < 1 else ro
            z = 6.24 + (0.5 * up ** 1.4 if spec[1] >= 1 else 0.0) + spec[2]
            p = (rr * math.cos(a), 0.05 + rr * math.sin(a), z)
            row.append(tmp.verts.new(p))
            if spec[0] == "out_top":
                edge.append(p)
        rows.append(row)
    for i in range(4):
        A, Bv = rows[i], rows[(i + 1) % 4]
        for k in range(n):
            k2 = (k + 1) % n
            tmp.faces.new((A[k], A[k2], Bv[k2], Bv[k]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    C._append(LE, tmp)
    C.tube(G, edge + [edge[0]], [0.05] * (n + 1), sides=6, v_tile=1.0, cap=False)
    # skull-and-crossbones badge on the front of the crown
    ell(BN, (0.0, -0.84, 6.62), (0.17, 0.08, 0.17), 12, 6)
    for s in (-1, 1):
        C.tube(BN, [(s * -0.24, -0.86, 6.36), (s * 0.24, -0.86, 6.56)], [0.035, 0.035], sides=6, v_tile=1.0)
        ell(VD, (s * 0.06, -0.9, 6.64), (0.04, 0.03, 0.04), 8, 4)
    P.smooth.update({"Skin": 70.0, "CoatRed": 60.0, "Hair": 70.0, "Leather": 50.0})
    return P.done(col, man)


# ================================================================ the skeleton pirate
def skeleton(col, man, origin):
    """BC_SkeletonPirate ~6.4H: grinning skull with glowing cyan eyes + a red bandana, spine, ribcage, pelvis, bony arms
    and legs with knobbed joints, a ragged open vest and torn shorts, belt + buckle, a raised cutlass (right hand)."""
    P = C.Piece("BC_SkeletonPirate", origin)
    BN, VD, GL, AR, CD = P.bm("Bone"), P.bm("Void"), P.bm("Glow"), P.bm("AwningRed"), P.bm("ClothDark")
    LE, G, IR = P.bm("Leather"), P.bm("Gold"), P.bm("Iron")
    # skull
    ell(BN, (0.0, 0.02, 5.62), (0.66, 0.74, 0.7), 18, 9)
    ell(BN, (0.0, -0.36, 5.12), (0.44, 0.38, 0.26), 14, 6)  # maxilla
    ell(BN, (0.0, -0.3, 4.82), (0.4, 0.34, 0.16), 14, 5)  # jaw, dropped open
    for s in (-1, 1):
        ell(BN, (s * 0.42, -0.42, 5.34), (0.18, 0.2, 0.12), 10, 5)  # cheekbones
        ell(VD, (s * 0.25, -0.62, 5.62), (0.19, 0.12, 0.19), 12, 6)  # orbits
        ell(GL, (s * 0.25, -0.73, 5.6), (0.065, 0.04, 0.065), 8, 4)  # glowing pupils
    ell(VD, (0.0, -0.7, 5.36), (0.07, 0.06, 0.11), 8, 4)
    for k in range(7):  # teeth: top row + a few bottom
        x = -0.27 + k * 0.09
        C.block(BN, (x, -0.68 + 0.02 * abs(x) * 4, 5.0), (0.07, 0.06, 0.1), bevel=0.02)
    for k in range(5):
        x = -0.18 + k * 0.09
        C.block(BN, (x, -0.6 + 0.02 * abs(x) * 4, 4.92), (0.07, 0.06, 0.09), bevel=0.02)
    # bandana (double-sided cloth cap) + knot tails at the back
    C.lathe(AR, [(0.73, 5.68), (0.71, 5.95), (0.56, 6.2), (0.3, 6.34), (0.0, 6.38)], 18, cap=False,
            M=T(0.0, 0.02, 0.0) @ D(1.0, 1.1, 1.0))
    ell(AR, (0.0, 0.84, 5.78), (0.16, 0.12, 0.13), 10, 5)
    for s in (-1, 1):
        C.prism(AR, [(0.0, 0.0), (0.18, -0.05), (0.32 * s, -0.75), (0.1 * s, -0.7)], -0.03, 0.03, bevel=0.0,
                M=T(0.0, 0.9, 5.75) @ Matrix.Rotation(PI / 2, 4, "Z"))
    # neck + spine + ribcage + sternum + clavicles + pelvis
    for k in range(4):
        ell(BN, (0.0, 0.05, 4.6 + k * 0.1), (0.12, 0.12, 0.05), 10, 4)
    for k in range(9):
        ell(BN, (0.0, 0.18, 3.05 + k * 0.2), (0.15, 0.13, 0.08), 10, 4)
    for k in range(5):
        z = 4.45 - k * 0.27
        Rr = 0.62 - 0.05 * k
        for s in (-1, 1):
            pts = [(s * Rr * math.sin(a), 0.18 - Rr * 0.95 * (1 - math.cos(a)) * 0.55 - 0.0, z - 0.14 * (a / 2.6))
                   for a in np.linspace(0.15, 2.6, 8)]
            pts = [(x, 0.18 + (y - 0.18) * 1.0, zz) for x, y, zz in pts]
            limb(BN, pts, [0.06] * 8, 6)
    C.block(BN, (0.0, -0.46, 4.15), (0.14, 0.1, 0.75), bevel=0.04)
    for s in (-1, 1):
        limb(BN, [(0.0, -0.4, 4.55), (s * 0.4, -0.2, 4.62), (s * 0.72, 0.0, 4.58)], [0.06, 0.06, 0.06], 6)
    ell(BN, (0.0, 0.05, 2.92), (0.52, 0.32, 0.3), 14, 6)
    # arms: left hanging, right raised holding the cutlass forward
    joints = {
        -1: [(-0.76, 0.0, 4.56), (-0.95, -0.06, 3.72), (-1.02, -0.22, 2.95)],
        1: [(0.76, 0.0, 4.56), (0.98, -0.42, 3.95), (0.9, -1.02, 4.32)],
    }
    for s, (shd, elb, wrs) in joints.items():
        for j in (shd, elb, wrs):
            ell(BN, j, (0.14, 0.14, 0.14), 10, 5)
        limb(BN, [shd, elb], [0.09, 0.08], 8)
        e, w = Vector(elb), Vector(wrs)
        side = (w - e).cross(Vector((0, 0, 1)))
        side = side.normalized() * 0.05 if side.length > 1e-4 else Vector((0.05, 0, 0))
        limb(BN, [tuple(e + side), tuple(w + side)], [0.05, 0.045], 6)
        limb(BN, [tuple(e - side), tuple(w - side)], [0.045, 0.04], 6)
        d = (w - e).normalized()
        palm = w + d * 0.18
        ell(BN, tuple(palm), (0.1, 0.1, 0.12), 8, 4)
        for f in range(4):
            off = Vector((-0.06 + 0.04 * f, 0.0, 0.0)) if s < 0 else Vector((0.0, 0.0, -0.06 + 0.04 * f))
            limb(BN, [tuple(palm + off), tuple(palm + off + d * 0.28)], [0.025, 0.02], 5)
    w = Vector(joints[1][2])
    d = (w - Vector(joints[1][1])).normalized()
    cutlass(IR, G, LE, T(*(w + d * 0.12)) @ d.to_track_quat("Z", "Y").to_matrix().to_4x4() @ D(0.62, 0.62, 0.62)
            @ T(0, 0, -0.6))
    # legs: femur, tibia + fibula, knobbed knees, feet
    for s in (-1, 1):
        hip, knee, ank = Vector((s * 0.32, 0.05, 2.82)), Vector((s * 0.36, -0.06, 1.6)), Vector((s * 0.36, 0.02, 0.28))
        for j in (hip, knee, ank):
            ell(BN, tuple(j), (0.15, 0.15, 0.14), 10, 5)
        limb(BN, [tuple(hip), tuple(knee)], [0.1, 0.09], 8)
        limb(BN, [tuple(knee + Vector((0.05, 0, 0))), tuple(ank + Vector((0.05, 0, 0)))], [0.06, 0.05], 6)
        limb(BN, [tuple(knee - Vector((0.05, 0, 0))), tuple(ank - Vector((0.05, 0, 0)))], [0.045, 0.04], 6)
        ell(BN, (s * 0.36, -0.22, 0.1), (0.17, 0.32, 0.1), 10, 5)
        for f in range(3):
            limb(BN, [(s * 0.36 - 0.08 + 0.08 * f, -0.46, 0.08), (s * 0.36 - 0.08 + 0.08 * f, -0.66, 0.05)],
                 [0.035, 0.03], 5)
    # rags: open vest with a ragged hem, torn shorts, belt
    ring_strip(CD, [(0.66, 4.72), (0.72, 4.2), (0.7, 3.5)], th0=-PI / 2 + 0.75, th1=-PI / 2 - 0.75 + 2 * PI, n=26,
               thick=0.06, ysc=0.8, jag=0.12, seed=3)
    ring_strip(CD, [(0.6, 3.12), (0.66, 2.6), (0.7, 2.05)], n=28, thick=0.06, ysc=0.75, jag=0.16, seed=5)
    C.torus(LE, (0.0, 0.0, 3.08), 0.63, 0.09, seg=24, sides=7, M=D(1.0, 0.78, 1.0))
    C.box(G, -0.18, -0.6, 2.96, 0.18, -0.48, 3.2, bevel=0.04)
    P.smooth.update({"Bone": 60.0, "AwningRed": 70.0, "ClothDark": 70.0})
    return P.done(col, man)


def build():
    import bpy
    col = C.collection("BC_Characters")
    for o in list(col.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    man = {}
    row = C.Row(gap=4.0)
    captain(col, man, row.next(4))
    skeleton(col, man, row.next(4))
    C.write_manifest("C", man)
    info = C.report(col)
    info["zfight"] = C.zfight_report(col)
    if globals().get("PREVIEW", True):
        for name, view in (("char_front", (0.0, -1.0, 0.12)), ("char_34", (-0.75, -1.0, 0.25)),
                           ("char_back", (0.4, 1.0, 0.2))):
            C.preview(col, C.render_path(name), samples=32, lens=50.0, view=view, res=(1280, 1000))
    return info


result = build()
