# Kit A "arcade" -- Lobby Holy Coast kit (B172). README.md in this folder is the spec.
# Pieces: AL_ArcBay, AL_ArcBayTall, AL_Pier, AL_Column, AL_Balustrade, AL_BridgeSpan, AL_WallSeg.
# Each piece = one object per material (<Piece>__<Mat>), origin bottom-centre, front -Y, laid out
# along +X with 30-stud gaps in collection AL_KitA; writes glb/AL_KitA.glb + .json and
# renders/AL_KitA.png. Run in a background Blender 5.x on blend/AL_kitA_arcade.blend:
#   blender.exe -b AL_kitA_arcade.blend --python-expr "exec(open(r'<this file>').read());
#       import bpy; bpy.ops.wm.save_mainfile(); print('RESULT', result)"
# Set CHECK = True before the exec to also render tiling checks (renders/AL_KitA_check_*.png).
#
# Tiling: every piece that tiles (bays, bridge, wall, balustrade) has FLAT, un-bevelled end faces
# exactly on its tiling planes, so neighbours butt without a groove: ArcBay/WallSeg at x = +-7,
# BridgeSpan at y = +-15 (its half-piers + half-cutwaters complete each other), Balustrade at x = +-6.
import importlib.util
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
_s = importlib.util.spec_from_file_location("al_common", os.path.join(LOBBY, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["al_common"] = C
_s.loader.exec_module(C)

I4 = Matrix.Identity(4)
# prism() outline given as (y, z) and run along X (cornices, rails, parapets)
SWAP_XY = Matrix(((0, 1, 0, 0), (1, 0, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1)))
# prism() outline given as (x, y) in plan and extruded up Z (cutwaters)
PLAN_UP = Matrix(((1, 0, 0, 0), (0, 0, 1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
# the bridge is authored with its span along local X, then turned so the span runs along Y
RZ90 = Matrix.Rotation(math.pi / 2, 4, "Z")


def face_frame(y, sign):
    """Frame on a wall face at world y: local (x, y) = world (x, z), local +z = out of the face
    (towards -Y for the front, sign < 0; towards +Y for the back)."""
    R = Matrix(((1, 0, 0, 0), (0, 0, float(sign), 0), (0, 1, 0, 0), (0, 0, 0, 1)))
    return Matrix.Translation((0, y, 0)) @ R


# ================================================================ helpers common.py lacks
def bevel_except(bm, offset, seg=2, planes=(), angle=30.0):
    """Bevel every sharp edge of bm EXCEPT those lying in one of `planes` [(axis, value)] -- the
    tiling joints and the ground stay crisp so neighbouring pieces butt without a groove."""
    if offset <= 0:
        return

    def on_plane(e):
        return any(all(abs(v.co[ax] - val) < 1e-4 for v in e.verts) for ax, val in planes)

    lim = math.radians(angle)
    edges = [e for e in bm.edges if e.is_manifold and e.calc_face_angle(0.0) > lim and not on_plane(e)]
    if edges:
        bmesh.ops.bevel(bm, geom=edges, offset=offset, offset_type="OFFSET", segments=seg,
                        profile=0.5, affect="EDGES", clamp_overlap=True)


def jbox(bm, lo, hi, bevel=0.2, planes=(), M=I4):
    """Box lo..hi (corner tuples) bevelled everywhere except on `planes` (local coords)."""
    tmp = bmesh.new()
    size = [hi[i] - lo[i] for i in range(3)]
    ctr = [(hi[i] + lo[i]) / 2 for i in range(3)]
    bmesh.ops.create_cube(tmp, size=1.0, matrix=Matrix.Translation(ctr) @ Matrix.Diagonal((*size, 1.0)))
    bevel_except(tmp, min(bevel, 0.45 * min(size)), 2, planes)
    return C._append(bm, tmp, M)


def jprism(bm, pts, y0, y1, bevel=0.2, planes=(), M=I4):
    """common.prism() (outline (x, z), extruded y0..y1) bevelled except on `planes` (prism coords)."""
    tmp = bmesh.new()
    C.prism(tmp, pts, y0, y1, bevel=0.0)
    bevel_except(tmp, bevel, 2, planes)
    return C._append(bm, tmp, M)


def round_loop(pts, r, seg=2):
    """Round EVERY corner of a closed polygon (common.round_profile skips the two end points)."""
    out = C.round_profile([pts[-1]] + list(pts) + [pts[0]], r, seg)
    return out[1:-1]


def sweep(bm, path, profile, closed=False, M=I4):
    """Moulding: sweep a profile [(out, z)] along a 2-D path [(x, y)]. `out` is measured to the
    RIGHT of travel (outward on a counter-clockwise loop). The profile closes on itself, so its
    last -> first edge should sit inside the wall. Open paths get flat end caps perpendicular to
    the path (seamless tiling joints); closed paths make a ring (plinths around a pier)."""
    tmp = bmesh.new()
    P = [Vector((p[0], p[1])) for p in path]
    n = len(P)
    N = []
    for i in range(n):
        if closed:
            a, b = P[i] - P[i - 1], P[(i + 1) % n] - P[i]
        else:
            a = P[i] - P[i - 1] if i > 0 else P[1] - P[0]
            b = P[i + 1] - P[i] if i < n - 1 else P[i] - P[i - 1]
        na = Vector((a.y, -a.x)).normalized()
        nb = Vector((b.y, -b.x)).normalized()
        m = na + nb
        m = m.normalized() if m.length > 1e-6 else na
        N.append(m / max(0.35, m.dot(na)))  # mitre: keep the offset distance on both sides
    rings = [[tmp.verts.new((P[i].x + N[i].x * o, P[i].y + N[i].y * o, z)) for i in range(n)]
             for o, z in profile]
    k = len(rings)
    segs = n if closed else n - 1
    for j in range(k):
        A, B = rings[j], rings[(j + 1) % k]
        for i in range(segs):
            i2 = (i + 1) % n
            try:
                tmp.faces.new((A[i], A[i2], B[i2], B[i]))
            except ValueError:
                pass
    if not closed:
        tmp.faces.new([r[0] for r in rings])
        tmp.faces.new([r[-1] for r in rings])
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp, M)


def rosette(bm, center, normal_axis, r, depth, sides=16, M=I4):
    """Small round boss (a sun rosette) on a face: drum of radius r sticking `depth` out of the
    face along normal_axis ('-Y', '+Y', '+X', '-X')."""
    rot = {"-Y": Matrix.Rotation(math.pi / 2, 4, "X"), "+Y": Matrix.Rotation(-math.pi / 2, 4, "X"),
           "+X": Matrix.Rotation(math.pi / 2, 4, "Y"), "-X": Matrix.Rotation(-math.pi / 2, 4, "Y")}[normal_axis]
    T = M @ Matrix.Translation(Vector(center)) @ rot
    prof = C.round_profile([(0.0, -0.1), (r, -0.1), (r, depth * 0.55), (r * 0.6, depth), (0.0, depth)], 0.08)
    return C.lathe(bm, prof, sides, (0, 0, 0), M=T)


# ================================================================ moulding profiles (out, z)
def plinth_prof(z0, h, out=0.85):
    """Base block + torus roll + cove up to the pilaster plane (out 0.36)."""
    k = h / 2.0
    pts = [(-0.2, 0.0), (out, 0.0), (out, 0.9), (out - 0.25, 0.95), (out - 0.1, 1.15), (out - 0.25, 1.38),
           (0.42, 1.5), (0.36, 1.85), (0.36, 2.0), (-0.2, 2.0)]
    return C.round_profile([(o, z0 + z * k) for o, z in pts], 0.08)


def band_prof(z0, k=1.0):
    """Gold astragal band (half-round roll), 0.6 tall."""
    pts = [(-0.2, 0.0), (0.4, 0.0), (0.55, 0.12), (0.62, 0.3), (0.55, 0.48), (0.4, 0.6), (-0.2, 0.6)]
    return [(o * k, z0 + z * k) for o, z in pts]


def impost_prof(z0, k=1.0):
    """Impost / capital moulding: fillet, cavetto flare, square abacus; 1.2 tall, out 1.0."""
    pts = [(-0.2, 0.0), (0.4, 0.0), (0.45, 0.15), (0.6, 0.4), (0.85, 0.7), (1.0, 0.82), (1.0, 1.2), (-0.2, 1.2)]
    return C.round_profile([(o * k, z0 + z * k) for o, z in pts], 0.08)


def cornice_half(fy, D, z0, h):
    """FRONT half (y < 0) of a cornice section (y, z): fascia on the wall face fy, a cyma flare,
    the corona out to D, rounded top at z0 + h. Listed bottom-inner -> top-outer."""
    p = D - fy
    pts = [(fy + 0.05, 0.0), (fy + 0.05, 0.35), (fy + 0.05 + 0.25 * p, 0.38), (fy + 0.05 + 0.55 * p, 0.46),
           (D - 0.12, 0.6), (D, 0.65), (D, 0.91), (D - 0.15, 1.0)]
    return [(-y, z0 + z * h) for y, z in pts]


def cornice_sym(fy, D, z0, h=2.0):
    half = cornice_half(fy, D, z0, h)
    return C.round_profile(half + [(-y, z) for y, z in reversed(half)], 0.1)


def pier_path(s, hw, r, fy):
    """U-path round a half-pier (x from s*r to the joint s*hw): back face, jamb, front face; the
    right-hand side of travel is outward everywhere; flat ends on the joint plane x = s*hw."""
    return [(s * hw, s * fy), (s * r, s * fy), (s * r, -s * fy), (s * hw, -s * fy)]


# ================================================================ shared arch parts
def archivolt(P, span, spring, fy, band=1.35, proud=0.65, bead=0.32, M=I4, n=20):
    """Marble archivolt band + gold bead round the arch on both faces (ends sink 0.6 into the impost)."""
    h = span / 2.0
    curve = C.arch_curve(span, spring, "round", n)
    path = [(h, spring - 0.6)] + list(reversed(curve)) + [(-h, spring - 0.6)]  # right-hand = outward
    prof = C.round_profile([(0.2, -0.2), (0.2, proud - 0.2), (0.4, proud), (band - 0.3, proud),
                            (band, proud - 0.3), (band, -0.2)], 0.1)
    bead_p = [(bead * math.cos(t), 0.12 + bead * math.sin(t)) for t in
              [2 * math.pi * i / 10 for i in range(10)]]
    for sg in (-1, 1):
        F = M @ face_frame(sg * fy, sg)
        sweep(P.bm("Marble"), path, prof, M=F)
        sweep(P.bm("Gold"), path, bead_p, M=F)


def keystone(P, crown, kt, yd, wb, wt, gem=(1.0, 1.6), M=I4):
    """Tapered gold keystone through the wall (y +-yd) hanging 0.35 below the crown, with a
    crystal set half into each face."""
    kb = crown - 0.35
    jprism(P.bm("Gold"), [(-wb, kb), (wb, kb), (wt, kt), (-wt, kt)], -yd, yd, bevel=0.2, M=M)
    zc = (kb + kt) / 2
    for sg in (-1, 1):
        C.crystal(P.bm("Crystal"), (0, sg * yd, zc - gem[1] / 2), gem[0], gem[1], M=M)


def spandrel_pts(s, r_in, x_out, z_bot, z_top, x_k, spring, n=10):
    """Outline (x, z) of one spandrel inlay: outer edge x_out, top z_top, inner edge = circle r_in
    round the arch centre (0, spring), from beside the keystone (x_k) down to z_bot."""
    x_k = max(x_k, math.sqrt(max(0.0, r_in * r_in - (z_top - spring) ** 2)) + 0.05)
    a1 = math.acos(min(1.0, x_k / r_in))
    a0 = math.asin(min(1.0, (z_bot - spring) / r_in))
    pts = [(x_out, z_bot), (x_out, z_top), (x_k, z_top)]
    for i in range(n + 1):
        a = a1 + (a0 - a1) * i / n
        pts.append((r_in * math.cos(a), spring + r_in * math.sin(a)))
    if s < 0:
        pts = [(-x, z) for x, z in reversed(pts)]
    return pts


def spandrels(P, fy, r_in, x_out, z_bot, z_top, x_k, spring, M=I4):
    """Turquoise tile inlays in the four spandrels (both faces), 0.12 proud of the wall."""
    for s in (-1, 1):
        pts = spandrel_pts(s, r_in, x_out, z_bot, z_top, x_k, spring)
        for sg in (-1, 1):
            y0, y1 = sorted((sg * (fy - 0.05), sg * (fy + 0.12)))
            jprism(P.bm("TealTile"), pts, y0, y1, bevel=0.05, M=M)


def dentils(P, x_half, fy, z0, step=1.4, w=0.7, h=0.6, d=0.5, M=I4):
    """A course of marble dentils under a cornice on both faces, spaced so it continues across joints."""
    n = int(round(2 * x_half / step))
    for i in range(n):
        x = -x_half + step * (i + 0.5)
        for sg in (-1, 1):
            y0, y1 = sorted((sg * (fy - 0.1), sg * (fy + d + 0.05)))
            C.box(P.bm("Marble"), x - w / 2, y0, z0 + 0.05, x + w / 2, y1, z0 + 0.05 + h, bevel=0.1, M=M)


# ================================================================ pieces
def arc_bay(name, origin, H, spring, plinth_h, col, man, mid_band=False):
    """Arcade bay 14W x 7D x H: two half-piers (plinth, pilasters, gold band, impost = capital
    3.5W), round arch (opening 9, springs at `spring`), archivolt + gold bead, gold keystone with
    crystals, teal spandrel inlays, gold frieze line, dentils, cornice H-2..H. Symmetric front/back;
    flat joints at x = +-7 so bays tile side by side or round a polygon."""
    HW, FY, SPAN = 7.0, 2.5, 9.0
    R = SPAN / 2
    top = H - 2.0
    fr0 = top - 0.6
    P = C.Piece(name, origin)
    jprism(P.bm("MarbleBlock"), C.arch_outline(2 * HW, top, SPAN, spring, "round", 20), -FY, FY,
           bevel=0.3, planes=[(0, -HW), (0, HW), (2, 0.0), (2, top)])
    z_imp = spring - 1.2
    z_band = z_imp - 0.6
    for s in (-1, 1):
        path = C.round_profile(pier_path(s, HW, R, FY), 0.35)
        sweep(P.bm("Marble"), path, plinth_prof(0.0, plinth_h))
        sweep(P.bm("Gold"), path, band_prof(z_band))
        sweep(P.bm("Marble"), path, impost_prof(z_imp))
        if mid_band:
            sweep(P.bm("Gold"), path, band_prof(round((plinth_h + z_band) / 2 - 0.3, 2)))
        x0, x1 = sorted((s * (R + 0.4), s * HW))
        for sg in (-1, 1):
            y0, y1 = sorted((sg * (FY - 0.1), sg * (FY + 0.35)))
            jbox(P.bm("Marble"), (x0, y0, plinth_h - 0.1), (x1, y1, z_band + 0.1), 0.15, planes=[(0, s * HW)])
    archivolt(P, SPAN, spring, FY)
    keystone(P, spring + R, fr0 + 0.05, FY + 0.95, 0.75, 1.2)
    spandrels(P, FY, R + 1.35 + 0.2, HW - 0.6, spring + 0.6, fr0 - 0.35, 1.45, spring)
    jbox(P.bm("Gold"), (-HW, -(FY + 0.25), fr0), (HW, FY + 0.25, top), 0.12, planes=[(0, -HW), (0, HW)])
    dentils(P, HW, FY, top)
    C.prism(P.bm("Marble"), cornice_sym(FY, 3.5, top), -HW, HW, bevel=0.0, M=SWAP_XY)
    return P.done(col, man)


def pier(origin, col, man):
    """Free-standing square pier 5x5x30: marble plinth, gold torus base, MarbleBlock shaft, gold
    bell capital with a crystal on each face, marble abacus."""
    P = C.Piece("AL_Pier", origin)
    sq = round_loop([(2.0, -2.0), (2.0, 2.0), (-2.0, 2.0), (-2.0, -2.0)], 0.35)  # CCW: right = outward
    C.box(P.bm("MarbleBlock"), -2.0, -2.0, 0.5, 2.0, 2.0, 28.6, bevel=0.3)
    sweep(P.bm("Marble"), sq, C.round_profile([(-0.2, 0.0), (0.5, 0.0), (0.5, 0.85), (0.38, 1.05),
                                               (0.3, 1.25), (-0.2, 1.25)], 0.1), closed=True)
    sweep(P.bm("Gold"), sq, band_prof(1.2, 0.75), closed=True)
    sweep(P.bm("Gold"), sq, band_prof(25.2, 0.75), closed=True)
    sweep(P.bm("Gold"), sq, C.round_profile([(-0.2, 25.6), (0.08, 25.6), (0.12, 26.0), (0.24, 27.0),
                                             (0.42, 27.8), (0.48, 28.25), (-0.2, 28.25)], 0.12), closed=True)
    sweep(P.bm("Marble"), sq, C.round_profile([(-0.2, 28.2), (0.42, 28.2), (0.5, 28.4), (0.5, 29.55),
                                               (0.38, 29.85), (0.25, 30.0), (-0.2, 30.0)], 0.1), closed=True)
    for ax, (x, y) in (("-Y", (0, -2.2)), ("+Y", (0, 2.2)), ("+X", (2.2, 0)), ("-X", (-2.2, 0))):
        rot = (0, 0, math.atan2(y, x))
        C.crystal(P.bm("Crystal"), (x, y, 26.35), 0.9, 1.4, rot=rot)
    return P.done(col, man)


def fluted_shaft(bm, z0, z1, r0, r1, flutes=12, depth=0.17, per=6, fade=0.6, rings=6):
    """Column shaft with `flutes` rounded grooves (fading out at both ends) and a slight taper."""
    tmp = bmesh.new()
    sides = flutes * per
    zs = [z0, z0 + fade * 0.5, z0 + fade] + [z0 + fade + (z1 - z0 - 2 * fade) * i / rings for i in range(1, rings)]
    zs += [z1 - fade, z1 - fade * 0.5, z1]
    rows = []
    for z in zs:
        t = (z - z0) / (z1 - z0)
        R = r0 + (r1 - r0) * t + 0.05 * math.sin(math.pi * t)  # entasis
        f = float(C.smoothstep(0.0, fade, min(z - z0, z1 - z)))
        row = []
        for k in range(sides):
            a = 2 * math.pi * k / sides
            g = 0.5 - 0.5 * math.cos(flutes * a)  # 0 on the ridge, 1 in the groove
            rr = R - depth * f * g
            row.append(tmp.verts.new((rr * math.cos(a), rr * math.sin(a), z)))
        rows.append(row)
    for A, B in zip(rows[:-1], rows[1:]):
        for k in range(sides):
            k2 = (k + 1) % sides
            tmp.faces.new((A[k], A[k2], B[k2], B[k]))
    tmp.faces.new(list(reversed(rows[0])))
    tmp.faces.new(rows[-1])
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp)


def column(origin, col, man):
    """Ionic column d4 x 22: marble attic base with a gold torus, fluted marble shaft, gold
    necking + echinus + two volute bolsters, marble abacus."""
    P = C.Piece("AL_Column", origin)
    C.lathe(P.bm("Marble"), C.round_profile([(0, 0), (2.0, 0), (2.0, 0.5), (1.85, 0.56), (1.92, 0.8),
                                             (1.85, 1.04), (1.6, 1.14), (1.5, 1.34), (1.5, 1.5), (0, 1.5)],
                                            0.06), 32)
    C.torus(P.bm("Gold"), (0, 0, 1.62), 1.42, 0.3, seg=40, sides=10, uv=4.0)
    fluted_shaft(P.bm("Marble"), 1.6, 19.45, 1.42, 1.28)
    C.torus(P.bm("Gold"), (0, 0, 19.45), 1.3, 0.3, seg=40, sides=10, uv=4.0)
    C.lathe(P.bm("Gold"), C.round_profile([(0, 19.5), (1.3, 19.5), (1.42, 19.75), (1.68, 20.15), (1.85, 20.5),
                                           (1.85, 20.8), (0, 20.8)], 0.08), 32)
    for sx in (-1, 1):
        roll = Matrix.Translation((sx * 1.38, 0, 20.32)) @ Matrix.Rotation(math.pi / 2, 4, "X")
        C.drum(P.bm("Gold"), (0, 0), -1.95, 3.9, 0.64, sides=20, bevel=0.2, M=roll)
        for sg in (-1, 1):  # volute eyes
            rosette(P.bm("Gold"), (sx * 1.38, sg * 1.95, 20.32), "+Y" if sg > 0 else "-Y", 0.34, 0.16, 12)
    C.box(P.bm("Marble"), -2.0, -2.0, 20.75, 2.0, 2.0, 22.0, bevel=0.25)
    return P.done(col, man)


def balustrade(origin, col, man):
    """Balustrade 12L x 1.6D x 4H: base + top rail, six vase balusters at 1.5 spacing, end posts
    (flat outer faces on the joints x = +-6) with gold caps, ball finials and rosettes."""
    P = C.Piece("AL_Balustrade", origin)
    HL, PX = 6.0, 4.4  # half length, inner face of the end posts
    base = C.round_profile([(0.0, 0.0), (0.75, 0.0), (0.75, 0.3), (0.6, 0.42), (0.5, 0.5), (-0.5, 0.5),
                            (-0.6, 0.42), (-0.75, 0.3), (-0.75, 0.0)], 0.08)
    rail = C.round_profile([(0.0, 2.7), (0.5, 2.7), (0.6, 2.8), (0.75, 2.95), (0.75, 3.05), (0.6, 3.2),
                            (-0.6, 3.2), (-0.75, 3.05), (-0.75, 2.95), (-0.6, 2.8), (-0.5, 2.7)], 0.08)
    C.prism(P.bm("Marble"), base, -PX - 0.05, PX + 0.05, bevel=0.0, M=SWAP_XY)
    C.prism(P.bm("Marble"), rail, -PX - 0.05, PX + 0.05, bevel=0.0, M=SWAP_XY)
    vase = C.round_profile([(0, 0.45), (0.42, 0.45), (0.42, 0.66), (0.28, 0.78), (0.46, 1.12), (0.5, 1.34),
                            (0.4, 1.66), (0.22, 2.04), (0.2, 2.2), (0.33, 2.3), (0.38, 2.48), (0.38, 2.75),
                            (0, 2.75)], 0.07)
    for i in range(6):
        C.lathe(P.bm("Marble"), vase, 12, (-3.75 + 1.5 * i, 0, 0))
    for s in (-1, 1):
        x0, x1 = sorted((s * PX, s * HL))
        jbox(P.bm("Marble"), (x0, -0.8, 0.0), (x1, 0.8, 3.3), 0.15, planes=[(0, s * HL), (2, 0.0)])
        x0, x1 = sorted((s * (PX - 0.1), s * HL))
        jbox(P.bm("Gold"), (x0, -0.88, 3.25), (x1, 0.88, 3.6), 0.12, planes=[(0, s * HL)])
        cx = s * (PX + HL) / 2
        C.lathe(P.bm("Gold"), C.round_profile([(0, 3.55), (0.32, 3.55), (0.32, 3.62), (0.5, 3.76),
                                               (0.42, 3.92), (0.2, 3.99), (0, 4.0)], 0.05), 16, (cx, 0, 0))
        for sg in (-1, 1):
            rosette(P.bm("Gold"), (cx, sg * 0.8, 1.75), "+Y" if sg > 0 else "-Y", 0.4, 0.15, 14)
    return P.done(col, man)


def bridge_span(origin, col, man):
    """Bridge span 24W(X) x 30L(Y) x 39H: MarbleBlock viaduct with a round arch (opening 22,
    springs at 19) under a Pave deck (top Z=36), half-piers at both ends with gold band + impost
    and half-cutwaters with marble hoods (the next span completes them), archivolt + bead, gold
    keystone with crystals, teal spandrels, gold frieze, dentils, cornice, marble parapets 3 high
    with gold coping. Authored with the span along local X, then turned 90 deg (M = RZ90)."""
    M = RZ90
    HL, FY, SPAN, SPRING = 15.0, 10.0, 22.0, 19.0
    R = SPAN / 2
    deck0, deck = 35.4, 36.0
    fr0, cz = 32.8, 33.4
    P = C.Piece("AL_BridgeSpan", origin)
    jprism(P.bm("MarbleBlock"), C.arch_outline(2 * HL, deck0, SPAN, SPRING, "round", 28), -FY, FY,
           bevel=0.35, planes=[(0, -HL), (0, HL), (2, 0.0), (2, deck0)], M=M)
    for s in (-1, 1):
        for sg in (-1, 1):  # half-cutwater wedge + hood on each face at each end
            tri = [(s * 12.2, sg * (FY - 0.2)), (s * HL, sg * (FY + 2.0)), (s * HL, sg * (FY - 0.2))]
            jprism(P.bm("MarbleBlock"), tri, 0.0, 14.0, 0.3, planes=[(0, s * HL), (1, 0.0)], M=M @ PLAN_UP)
            hood = bmesh.new()
            lip = [(s * 11.9, sg * (FY - 0.2)), (s * HL, sg * (FY + 2.3)), (s * HL, sg * (FY - 0.2))]
            vs = [hood.verts.new((x, y, z)) for x, y in lip for z in (13.9, 14.3)]
            vs.append(hood.verts.new((s * HL, sg * (FY - 0.2), 16.65)))
            bmesh.ops.convex_hull(hood, input=vs)
            bmesh.ops.dissolve_limit(hood, angle_limit=0.01, verts=hood.verts[:], edges=hood.edges[:])
            bevel_except(hood, 0.15, 2, planes=[(0, s * HL), (1, sg * (FY - 0.2))])
            C._append(P.bm("Marble"), hood, M)
    k = 1.3
    z_imp = SPRING - 1.2 * k
    z_band = z_imp - 0.6 * k
    for s in (-1, 1):
        path = C.round_profile(pier_path(s, HL, R, FY), 0.45)
        sweep(P.bm("Gold"), path, band_prof(z_band, k), M=M)
        sweep(P.bm("Marble"), path, impost_prof(z_imp, k), M=M)
    archivolt(P, SPAN, SPRING, FY, band=1.8, proud=0.85, bead=0.42, M=M, n=28)
    keystone(P, SPRING + R, fr0 + 0.05, FY + 1.2, 1.0, 1.6, gem=(1.3, 2.2), M=M)
    spandrels(P, FY, R + 1.8 + 0.3, HL - 0.7, SPRING + 0.6, fr0 - 0.4, 1.95, SPRING, M=M)
    jbox(P.bm("Gold"), (-HL, -(FY + 0.3), fr0), (HL, FY + 0.3, cz), 0.12, planes=[(0, -HL), (0, HL)], M=M)
    dentils(P, HL, FY, cz, step=1.5, w=0.75, h=0.75, d=0.6, M=M)
    inner = 10.6  # parapet inner face = deck edge
    for sg in (-1, 1):
        pts = cornice_half(FY, 12.0, cz, deck - cz) + [(-inner, deck), (-inner, deck0), (-(FY - 0.6), deck0),
                                                        (-(FY - 0.6), cz)]
        body = [(-11.2, deck), (-11.8, deck), (-11.8, deck + 0.3), (-11.62, deck + 0.5), (-11.62, 38.3),
                (-10.75, 38.3), (-10.75, deck + 0.5), (-inner, deck + 0.3), (-inner, deck)]
        coping = round_loop([(-11.95, 38.25), (-10.45, 38.25), (-10.45, 39.0), (-11.95, 39.0)], 0.22)
        for outline, mat in ((C.round_profile(pts, 0.1), "Marble"), (C.round_profile(body, 0.08), "Marble"),
                             (coping, "Gold")):
            if sg > 0:
                outline = [(-y, z) for y, z in outline]
            C.prism(P.bm(mat), outline, -HL, HL, bevel=0.0, M=M @ SWAP_XY)
    C.box(P.bm("Pave"), -HL, -inner, deck0, HL, inner, deck, bevel=0.0, M=M)
    return P.done(col, man)


def wall_seg(origin, col, man):
    """Retaining wall 14W x 3D x 12H (front -Y, flat back on the terrace at y = +1.5): marble
    plinth, MarbleBlock body, half-pilasters on the joints, a blind arch niche with a teal inlay,
    gold keystone + crystal, gold line, cornice 10..12. Tiles along X (flat joints at x = +-7)."""
    HW, FB, BK = 7.0, 0.8, 1.5  # half width, body front face at y = -FB, back face y = +BK
    P = C.Piece("AL_WallSeg", origin)
    plinth = C.round_profile([(BK, 0.0), (-1.4, 0.0), (-1.4, 0.85), (-1.15, 1.0), (-1.15, 1.2),
                              (-(FB + 0.05), 1.5), (BK, 1.5)], 0.1)
    C.prism(P.bm("Marble"), plinth, -HW, HW, bevel=0.0, M=SWAP_XY)
    C.box(P.bm("MarbleBlock"), -HW, -FB, 1.5, HW, BK, 10.0, bevel=0.0)
    for s in (-1, 1):
        x0, x1 = sorted((s * 5.6, s * HW))
        jbox(P.bm("Marble"), (x0, -(FB + 0.35), 1.0), (x1, -(FB - 0.1), 9.45), 0.15, planes=[(0, s * HW)])
    # blind arch niche: marble frame + sill, turquoise inlay, gold keystone with a crystal
    C.arch_frame(P.bm("Marble"), 5.0, 6.2, 2.4, 0.45, frame=0.55, y0=-(FB + 0.4))
    C.box(P.bm("Marble"), -3.3, -(FB + 0.5), 1.95, 3.3, -(FB - 0.1), 2.45, bevel=0.12)
    niche = [(-2.5, 2.45)] + C.arch_curve(5.0, 6.2, "round", 16) + [(2.5, 2.45)]
    jprism(P.bm("TealTile"), niche, -(FB + 0.12), -(FB - 0.05), bevel=0.05)
    jprism(P.bm("Gold"), [(-0.45, 8.45), (0.45, 8.45), (0.72, 9.5), (-0.72, 9.5)], -(FB + 0.7), -(FB - 0.1), 0.15)
    C.crystal(P.bm("Crystal"), (0, -(FB + 0.7), 8.5), 0.75, 1.0)
    jbox(P.bm("Gold"), (-HW, -(FB + 0.25), 9.4), (HW, BK - 0.2, 10.0), 0.12, planes=[(0, -HW), (0, HW)])
    cor = C.round_profile(cornice_half(FB, 1.55, 10.0, 2.0) + [(BK, 12.0), (BK, 10.0)], 0.1)
    C.prism(P.bm("Marble"), cor, -HW, HW, bevel=0.0, M=SWAP_XY)
    return P.done(col, man)


# ================================================================ tiling check renders
def place(dst, man, piece, T, rz=0.0):
    """Copy a built piece (its objects share the mesh) to world position T, turned rz about Z."""
    org = Vector(man[piece]["origin"])
    W = Matrix.Translation(Vector(T)) @ Matrix.Rotation(rz, 4, "Z") @ Matrix.Translation(-org)
    for nm in man[piece]["objects"]:
        ob = bpy.data.objects[nm].copy()
        ob.matrix_world = W
        dst.objects.link(ob)


def check_renders(man):
    """Tiling checks (not exported): a straight arcade + wall run + two bridge spans, and a
    15-degree ring of tall bays at radius ~53. The check collection is deleted afterwards."""
    out = []
    chk = C.clear_collection("AL_KitA_Check")
    for i in (-1, 0, 1):
        place(chk, man, "AL_ArcBay", (i * 14.0, 0, 0))
    for i in range(2):
        place(chk, man, "AL_WallSeg", (-28.0 - 14.0 * i, -2.0, 0))
        place(chk, man, "AL_Balustrade", (-28.0 - 14.0 * i, -1.0, 12.0))
    for j in range(2):
        place(chk, man, "AL_BridgeSpan", (45.0, 10.0 + 30.0 * j, 0))
    place(chk, man, "AL_Column", (24.0, -6.0, 0))
    place(chk, man, "AL_Pier", (31.0, -6.0, 0))
    out.append(C.preview(chk, C.render_path("AL_KitA_check_run")))
    C.clear_collection("AL_KitA_Check")
    apo = 53.6
    for k in range(-3, 4):
        a = math.radians(15.0 * k)
        place(chk, man, "AL_ArcBayTall", (apo * math.sin(a), apo - apo * math.cos(a), 0), a)
    out.append(C.preview(chk, C.render_path("AL_KitA_check_ring"), view=(-0.3, -1.0, 0.45)))
    C.clear_collection("AL_KitA_Check")
    bpy.data.collections.remove(chk)
    return out


# ================================================================ build
def build(check=False):
    col = C.clear_collection("AL_KitA")
    row = C.Row(gap=30.0)
    man = {}
    arc_bay("AL_ArcBay", row.next(14), 24.0, 15.0, 2.0, col, man)
    arc_bay("AL_ArcBayTall", row.next(14), 40.0, 28.0, 3.0, col, man, mid_band=True)
    pier(row.next(5), col, man)
    column(row.next(4), col, man)
    balustrade(row.next(12), col, man)
    bridge_span(row.next(24), col, man)
    wall_seg(row.next(14), col, man)
    info = C.export_kit(col, "A", man)
    renders = [C.preview(col, C.render_path("AL_KitA"))]
    if check:
        renders += check_renders(man)
    tris = {o.name: C.tri_count(o) for o in col.all_objects if o.type == "MESH"}
    pieces = {k: dict(v, tris=sum(tris.get(o, 0) for o in v["objects"])) for k, v in man.items()}
    return {"export": info, "pieces": pieces, "renders": renders}


result = build(check=globals().get("CHECK", False))
