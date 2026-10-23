# Alamat Defense Lobby "Holy Coast" -- Kit B: sacred architecture (B172). Builds, per README.md:
#   AL_SunGate, AL_DomePavilion, AL_Temple (Summon), AL_SpireTower, AL_HaloRing, AL_Finial,
#   AL_SunDisc, AL_Crystal
# into collection AL_KitB (one object per material, <Piece>__<Mat>; origin bottom-centre, front -Y,
# a row along +X with 30-stud gaps), exports <root>/glb/AL_KitB.glb + AL_KitB.json and renders
# <root>/renders/AL_KitB.png (+ AL_KitB_detail1..3.png close-ups).
#
# Run in a background Blender 5.2 on <root>/blend/AL_kitB_sacred.blend (the script saves the file):
#   "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b <root>/blend/AL_kitB_sacred.blend
#       --python-expr "exec(open(r'<this file>').read()); print('RESULT', result)"
# Optional globals set before the exec: SKIP_RENDER=True (export only), NO_DETAIL=True (main render only).
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
np = C.np

PI = math.pi
SQ2 = math.sqrt(2.0)


# ================================================================ small matrix helpers
def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def RX(a):
    return Matrix.Rotation(a, 4, "X")


def RY(a):
    return Matrix.Rotation(a, 4, "Y")


def RZ(a):
    return Matrix.Rotation(a, 4, "Z")


def _M(M):
    return M if M is not None else Matrix()


# ================================================================ kit-B helpers (common.py lacks these)
def slab(bm, cx, cy, hx, hy, z0, z1, bevel=0.3, M=None):
    """Bevelled box centred on (cx, cy), half-sizes hx / hy, from z0 to z1 (mouldings, cornices)."""
    return C.box(bm, cx - hx, cy - hy, z0, cx + hx, cy + hy, z1, bevel=min(bevel, 0.4 * (z1 - z0)), M=M)


def sq_frustum(bm, cx, cy, hw0, hw1, z0, z1, M=None):
    """Square frustum (hw1 > 0) or pyramid (hw1 = 0) as a 4-sided lathe: hip roofs, tower skirts."""
    prof = [(0.0, z0), (hw0 * SQ2, z0), (hw1 * SQ2, z1)]
    if hw1 > 0:
        prof.append((0.0, z1))
    else:
        prof[-1] = (0.0, z1)
    return C.lathe(bm, prof, 4, center=(cx, cy, 0.0), phase=PI / 4, M=M)


def hip_ribs(bm, cx, cy, hw0, hw1, z0, z1, r=0.32, M=None):
    """Gold rods along the four hips of a sq_frustum roof."""
    for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        C.spike(bm, (cx + sx * hw0, cy + sy * hw0, z0), (cx + sx * hw1, cy + sy * hw1, z1), r, sides=6,
                r_tip=r, M=M)


def bar(bm, p0, p1, r, sides=8, M=None):
    """Capped round rod from p0 to p1 (spokes, chains)."""
    return C.spike(bm, p0, p1, r, sides=sides, r_tip=r, M=M)


_ORB = [(0.95 * math.cos(t), 3.95 + 0.95 * math.sin(t)) for t in np.radians([-58, -35, -12, 12, 35, 58])]
FINIAL = ([(0.0, 0.0), (1.0, 0.0), (1.0, 0.45), (0.62, 0.9), (0.46, 1.8), (0.78, 2.1), (0.78, 2.45),
           (0.48, 2.75)] + _ORB +
          [(0.76, 5.0), (0.76, 5.4), (0.48, 5.65), (0.36, 7.4), (0.56, 8.0), (0.56, 8.5), (0.26, 9.2),
           (0.0, 12.0)])


def finial_profile(z0, h, r):
    """AL_Finial silhouette (base, neck, orb, lotus collar, budded spike) from z0, height h, radius r."""
    k = h / 12.0
    return C.round_profile([(x * r, z0 + z * k) for x, z in FINIAL], 0.08 * min(r, k))


def finial(bm, cx, cy, z0, h, r, sides=16, M=None):
    return C.lathe(bm, finial_profile(z0, h, r), sides, center=(cx, cy, 0.0), M=M)


def sweep_rib(bm, profile, ang, w=0.8, t=0.45, sink=0.15, center=(0, 0, 0), taper_r=0.0, M=None):
    """A rib of rectangular section (w wide, t proud) riding a lathe profile [(r, z)] at angle `ang`:
    the gold ribs of a dome. Narrows below radius taper_r so ribs do not pile up at the crown."""
    tmp = bmesh.new()
    ca, sa = math.cos(ang), math.sin(ang)
    side = Vector((-sa, ca, 0.0))
    n = len(profile)
    rings = []
    for i, (r, z) in enumerate(profile):
        r0, z0 = profile[max(i - 1, 0)]
        r1, z1 = profile[min(i + 1, n - 1)]
        L = math.hypot(r1 - r0, z1 - z0) or 1.0
        nr, nz = (z1 - z0) / L, -(r1 - r0) / L          # outward normal of the profile
        base = Vector((r * ca, r * sa, z))
        nrm = Vector((nr * ca, nr * sa, nz))
        hw = w / 2 * (min(1.0, r / taper_r) if taper_r > 0 else 1.0)
        hw = max(hw, 0.18)
        lo, hi = base - nrm * sink, base + nrm * t
        rings.append([tmp.verts.new(lo - side * hw), tmp.verts.new(lo + side * hw),
                      tmp.verts.new(hi + side * hw), tmp.verts.new(hi - side * hw)])
    for A, B in zip(rings[:-1], rings[1:]):
        for k in range(4):
            k2 = (k + 1) % 4
            tmp.faces.new((A[k], A[k2], B[k2], B[k]))
    tmp.faces.new(list(reversed(rings[0])))
    tmp.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp, C._matrix(center, (0, 0, 0), M))


def fluted_shaft(bm, cx, cy, z0, z1, r, r_top=None, n=12, depth=0.13):
    """Column shaft with n chunky flutes (flat fillet + V groove), tapering to r_top (entasis)."""
    rt = r if r_top is None else r_top
    tmp = bmesh.new()
    step = 2 * PI / n
    rings = []
    for z, rr in ((z0, r), (z1, rt)):
        d = depth * rr / r
        ring = []
        for k in range(n):
            c = step * k
            for a, rad in ((c - 0.17 * step, rr), (c + 0.17 * step, rr), (c + 0.5 * step, rr - d)):
                ring.append(tmp.verts.new((cx + rad * math.cos(a), cy + rad * math.sin(a), z)))
        rings.append(ring)
    A, B = rings
    m = len(A)
    for k in range(m):
        k2 = (k + 1) % m
        tmp.faces.new((A[k], A[k2], B[k2], B[k]))
    tmp.faces.new(list(reversed(A)))
    tmp.faces.new(B)
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp)


def column(P, cx, cy, z0, h, r, fluted=False, sides=20):
    """Holy column, total height h from z0: marble base moulding, (fluted) marble shaft with entasis,
    gold flared capital, marble square abacus."""
    zb = z0 + 0.9 * r
    zt = z0 + h
    zc = zt - 1.25 * r
    base = C.round_profile([(0.0, z0), (1.5 * r, z0), (1.5 * r, z0 + 0.32 * r), (1.22 * r, z0 + 0.5 * r),
                            (1.22 * r, z0 + 0.68 * r), (1.04 * r, zb), (0.0, zb)], 0.12 * r)
    C.lathe(P.bm("Marble"), base, sides, center=(cx, cy, 0.0))
    if fluted:
        fluted_shaft(P.bm("Marble"), cx, cy, zb - 0.05, zc + 0.05, r, r_top=0.9 * r)
    else:
        C.drum(P.bm("Marble"), (cx, cy), zb - 0.05, zc - zb + 0.1, r, r_top=0.9 * r, sides=sides, bevel=0.0)
    cap = C.round_profile([(0.0, zc), (0.95 * r, zc), (1.08 * r, zc + 0.16 * r), (0.95 * r, zc + 0.32 * r),
                           (1.0 * r, zc + 0.45 * r), (1.5 * r, zc + 0.85 * r), (0.0, zc + 0.85 * r)], 0.1 * r)
    C.lathe(P.bm("Gold"), cap, sides, center=(cx, cy, 0.0))
    a = 1.6 * r
    C.box(P.bm("Marble"), cx - a, cy - a, zc + 0.85 * r, cx + a, cy + a, zt, bevel=0.15 * r)


def sun_disc(bm, center, r, thick, both=True, M=None, sides=40):
    """Gold sun disc in the XZ plane facing the front (-Y): plate, rim bead, domed boss (both faces
    when `both`, for free-standing suns)."""
    F = _M(M) @ T(*center) @ RX(PI / 2)  # local +Z -> world -Y
    rr = max(0.3, thick * 0.55)
    C.drum(bm, (0, 0), -thick / 2, thick, r - rr * 0.6, sides=sides, bevel=min(0.25, thick * 0.3), M=F)
    C.torus(bm, (0, 0, 0), r - rr, rr, seg=sides, sides=10, axis="Z", uv=4.0, M=F)
    boss = C.round_profile([(0.0, 0.0), (0.7 * r, 0.0), (0.68 * r, 0.1 * r), (0.5 * r, 0.2 * r),
                            (0.25 * r, 0.25 * r), (0.0, 0.26 * r)], 0.08 * r)
    for flip in ((False, True) if both else (False,)):
        Mf = F @ RX(PI) if flip else F
        C.lathe(bm, boss, sides, center=(0, 0, thick / 2 - 0.05), M=Mf)


def sun_rays(bm, center, r0, r_long, r_short, n=16, w_long=2.4, w_short=1.6, t=0.8, phase=PI / 2, M=None):
    """n flat bevelled rays in the XZ plane radiating from center: even = long kite blades, odd =
    short triangles. Ray k points at angle phase + 2 pi k / n (phase pi/2 = straight up)."""
    base = _M(M) @ T(*center)
    for k in range(n):
        phi = phase + 2 * PI * k / n
        if k % 2 == 0:
            L = r_long - r0
            pts = [(-w_long * 0.3, r0), (w_long * 0.3, r0), (w_long / 2, r0 + 0.32 * L), (0.0, r_long),
                   (-w_long / 2, r0 + 0.32 * L)]
            tt = t
        else:
            pts = [(-w_short / 2, r0), (w_short / 2, r0), (0.0, r_short)]
            tt = t * 0.75
        C.prism(bm, pts, -tt / 2, tt / 2, bevel=min(0.18, tt * 0.3), M=base @ RY(PI / 2 - phi))


def window(P, w, sill, spring, wall_y, M=None, frame=0.55, depth=0.6, kind="round", point=1.3):
    """Arched Capiz window on a wall face at local y = wall_y (front -Y), centred on local x = 0:
    glowing pane (0.15 proud), gold arch frame (0.4 proud), marble sill, gold keystone.
    M places it (T(x, y, 0) @ RZ(a) for another position / face)."""
    n = 10
    curve = C.arch_curve(w, spring, kind, n, point)
    pane = [(-w / 2, sill), (w / 2, sill)] + list(reversed(curve))
    C.prism(P.bm("Capiz"), pane, wall_y - 0.15, wall_y + depth, bevel=0.05, M=M)
    C.arch_frame(P.bm("Gold"), w, spring, sill, depth + 0.4, frame=frame, kind=kind, y0=wall_y - 0.4,
                 bevel=0.1, n=n, point=point, M=M)
    C.box(P.bm("Marble"), -w / 2 - frame - 0.35, wall_y - 0.75, sill - 0.55, w / 2 + frame + 0.35, wall_y + 0.3,
          sill + 0.05, bevel=0.15, M=M)
    crown = max(z for _, z in C.arch_curve(w + 2 * frame, spring, kind, n, point))
    C.prism(P.bm("Gold"), [(-0.42, crown - frame - 0.15), (0.42, crown - frame - 0.15), (0.68, crown + 0.45),
                           (-0.68, crown + 0.45)], wall_y - 0.55, wall_y + 0.3, bevel=0.08, M=M)


def pylon_panel(P, M, face=-4.0, z0=9.0, z1=34.0, hw=2.0):
    """Teal-tile inlay in a gold frame with a gold lozenge, on a pylon face at local y = face."""
    TT, G = P.bm("TealTile"), P.bm("Gold")
    C.box(TT, -hw, face - 0.3, z0, hw, face + 0.2, z1, bevel=0.12, M=M)
    f = 0.6
    for x0, x1 in ((-hw - f, -hw), (hw, hw + f)):
        C.box(G, x0, face - 0.45, z0 - f, x1, face + 0.2, z1 + f, bevel=0.14, M=M)
    for za, zb in ((z0 - f, z0), (z1, z1 + f)):
        C.box(G, -hw - f, face - 0.45, za, hw + f, face + 0.2, zb, bevel=0.14, M=M)
    C.block(G, (0, face - 0.4, (z0 + z1) / 2), (1.8, 0.5, 1.8), bevel=0.15, rot=(0, PI / 4, 0), M=M)


def tier(P, hw, z0, z1, win, pil, mat="MarbleBlock", faces=4):
    """Square tower stage: walls (hw half-width) from z0 to z1, marble corner pilasters `pil` wide
    (0.5 proud), one arched capiz window win=(w, sill, spring) centred on each face."""
    slab(P.bm(mat), 0, 0, hw, hw, z0, z1, bevel=0.4)
    c = hw - pil / 2 + 0.5
    for sx, sy in ((1, 1), (1, -1), (-1, 1), (-1, -1)):
        slab(P.bm("Marble"), sx * c, sy * c, pil / 2, pil / 2, z0, z1, bevel=0.3)
    w, sill, spring = win
    for a in (0.0, PI / 2, PI, -PI / 2)[:faces]:
        window(P, w, sill, spring, -hw, M=RZ(a))


# ================================================================ pieces
def sun_gate(col, man, origin):
    """AL_SunGate 56W x 12D x 72H: two pylons with teal caps + gold finials, a pointed-arch doorway in
    a block wall, a halo sun-wheel (torus R22) threaded through the pylons with 16 rays and a gold
    sun disc d10, and a crystal hanging from the keystone."""
    P = C.Piece("AL_SunGate", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    RC = 46.0  # halo centre height
    for sx in (-1, 1):
        cx = sx * 24.0
        slab(Mb, cx, 0, 4.7, 4.7, 0.0, 1.6, bevel=0.4)
        slab(Mb, cx, 0, 4.4, 4.4, 1.6, 3.2, bevel=0.35)
        slab(G, cx, 0, 4.2, 4.2, 3.2, 3.7, bevel=0.15)
        slab(MB, cx, 0, 4.0, 4.0, 3.0, 50.0, bevel=0.45)
        slab(G, cx, 0, 4.25, 4.25, 49.6, 50.6, bevel=0.25)
        slab(Mb, cx, 0, 4.45, 4.45, 50.6, 52.8, bevel=0.35)
        slab(G, cx, 0, 4.65, 4.65, 52.8, 53.3, bevel=0.15)
        slab(Mb, cx, 0, 4.85, 4.85, 53.3, 56.0, bevel=0.45)
        sq_frustum(TT, cx, 0, 4.4, 0.9, 56.0, 61.8)
        hip_ribs(G, cx, 0, 4.4, 0.9, 56.0, 61.8, r=0.3)
        C.drum(G, (cx, 0), 61.3, 0.9, 1.5, r_top=1.25, sides=16, bevel=0.2)
        finial(G, cx, 0, 62.0, 10.0, 1.35)
        for a in (0.0, PI, sx * PI / 2):  # front, back, outer side
            M = T(cx, 0, 0) @ RZ(a)
            pylon_panel(P, M, face=-4.0)
            sun_disc(G, (0, -4.3, 43.0), 1.3, 0.5, both=False, M=M, sides=24)
            sun_rays(G, (0, -4.2, 43.0), 1.1, 2.7, 2.1, n=12, w_long=1.1, w_short=0.8, t=0.4, M=M)
    # wall with the pointed doorway (span 26, springs at 7.5 -> crown ~22.9)
    span, spring, point = 26.0, 7.5, 1.2
    crown = max(z for _, z in C.arch_curve(span, spring, "pointed", 16, point))
    C.arch_wall(MB, 41.0, 30.0, 6.0, span, spring, kind="pointed", bevel=0.35, n=16, point=point)
    for sx in (-1, 1):
        C.box(Mb, sx * 13.4, -3.5, 0.0, sx * 20.5, 3.5, 1.6, bevel=0.35)
    C.box(Mb, -20.6, -3.7, 29.6, 20.6, 3.7, 31.2, bevel=0.35)
    C.box(G, -20.5, -3.85, 31.2, 20.5, 3.85, 31.7, bevel=0.15)
    C.box(Mb, -20.4, -3.5, 31.7, 20.4, 3.5, 33.0, bevel=0.35)
    for y0 in (-3.6, 2.8):
        C.arch_frame(G, span, spring, 0.0, 0.8, frame=1.3, kind="pointed", y0=y0, bevel=0.15, n=16, point=point)
    C.prism(G, [(-1.2, crown - 1.2), (1.2, crown - 1.2), (1.8, crown + 2.8), (-1.8, crown + 2.8)], -3.9, 3.9,
            bevel=0.2)
    # halo sun-wheel: outer ring R22 (threads through both pylons), inner ring, 16 rays, sun disc d10
    C.torus(G, (0, 0, RC), 22.0, 1.6, seg=96, sides=14, axis="Y", uv=4.0)
    C.torus(G, (0, 0, RC), 13.2, 0.55, seg=64, sides=8, axis="Y", uv=4.0)
    sun_rays(G, (0, 0, RC), 4.6, 20.8, 15.2, n=16, w_long=2.8, w_short=1.9, t=0.9)
    sun_disc(G, (0, 0, RC), 5.0, 1.6, both=True)
    # hanging crystal (6 x 14) under the keystone, in a gold cap
    top = crown - 2.2
    C.lathe(G, C.round_profile([(0.0, top - 1.2), (1.5, top - 0.9), (1.15, top + 0.1), (0.75, top + 0.6),
                                (0.75, crown - 1.0), (0.0, crown - 1.0)], 0.15), 16)
    C.crystal(P.bm("Crystal"), (0, 0, top - 14.0), 6.0, 14.0, sides=4, waist=0.62, band=0.1, rot=(0, 0, PI / 4))
    return P.done(col, man)


def dome_pavilion(col, man, origin):
    """AL_DomePavilion d22 x 30H: stepped round plinth with a mandala floor, 6 columns, entablature
    ring with small finials, ribbed teal dome with gold ribs, gold finial."""
    P = C.Piece("AL_DomePavilion", origin)
    Mb, G, TT = P.bm("Marble"), P.bm("Gold"), P.bm("TealTile")
    C.drum(Mb, (0, 0), 0.0, 1.25, 11.0, sides=48, bevel=0.35)
    C.drum(Mb, (0, 0), 1.25, 1.25, 9.9, sides=48, bevel=0.35)
    C.torus(G, (0, 0, 1.25), 10.45, 0.3, seg=64, sides=8, uv=4.0)
    mf = C.lathe(P.bm("Mandala"), [(7.4, 2.53), (0.0, 2.53)], 48, cap=False)
    C.disc_uv(P.bm("Mandala"), mf, (0, 0), 7.4)
    for x, y, a in C.polar(6, 7.6, 0.0):
        column(P, x, y, 2.5, 14.0, 1.0)
    C.lathe(Mb, C.round_profile([(0.0, 16.5), (9.0, 16.5), (9.0, 17.4), (9.75, 17.85), (9.75, 18.9),
                                 (0.0, 18.9)], 0.25), 48)
    C.torus(G, (0, 0, 17.3), 9.05, 0.38, seg=64, sides=8, uv=4.0)
    for x, y, a in C.polar(6, 9.1, 0.0):
        finial(G, x, y, 18.8, 2.6, 0.55, sides=12)
    dprof = C.ellipse_profile(8.5, 5.8, 18.9, n=14)
    C.lathe(TT, dprof, 48, uv=6.0)
    C.torus(G, (0, 0, 19.05), 8.5, 0.45, seg=64, sides=8, uv=4.0)
    rib = [p for p in dprof if p[0] > 1.2]
    for k in range(8):
        sweep_rib(G, rib, PI / 8 + 2 * PI * k / 8, w=0.75, t=0.38, taper_r=3.0)
    C.drum(G, (0, 0), 24.2, 0.8, 1.6, r_top=1.2, sides=16, bevel=0.2)
    finial(G, 0, 0, 24.9, 5.1, 0.95)
    return P.done(col, man)


def temple(col, man, origin):
    """AL_Temple (Summon) 96W x 60D x 84H: podium + steps, block base 64x40x24 with capiz windows,
    drum d36 x 20 with windows, tall teal dome with gold ribs to 70, capiz lantern + finial to 84,
    4-column portico with a teal-roofed pediment + gold sun, bronze doorway, corner pinnacles and two
    flanking towers 12x12x50 with gold spires to 66."""
    P = C.Piece("AL_Temple", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    CP, BR, PV = P.bm("Capiz"), P.bm("Bronze"), P.bm("Pave")
    YC, HD = 8.0, 20.0  # base block centre y + half depth: y -12 .. 28
    # podium + front steps
    C.box(Mb, -20.0, -30.0, 0.0, 20.0, -26.6, 1.5, bevel=0.35)
    C.box(Mb, -34.0, -27.0, 0.0, 34.0, 30.0, 2.7, bevel=0.45)
    C.box(PV, -33.4, -26.4, 2.5, 33.4, 29.4, 3.0, bevel=0.15)
    # base block
    slab(Mb, 0, YC, 32.6, HD + 0.6, 2.9, 4.6, bevel=0.4)
    slab(G, 0, YC, 32.3, HD + 0.3, 4.6, 5.0, bevel=0.12)
    slab(MB, 0, YC, 32.0, HD, 3.0, 21.6, bevel=0.45)
    slab(Mb, 0, YC, 32.4, HD + 0.4, 21.4, 22.4, bevel=0.3)
    slab(G, 0, YC, 32.55, HD + 0.55, 22.4, 22.8, bevel=0.12)
    slab(Mb, 0, YC, 33.0, HD + 1.0, 22.8, 24.0, bevel=0.4)
    win = (5.0, 9.5, 16.5)
    for x in (-24.0, 24.0):
        window(P, *win, wall_y=-HD, M=T(x, YC, 0))
    for u in (-18.0, 0.0, 18.0):
        window(P, *win, wall_y=-HD, M=T(0, YC, 0) @ RZ(PI) @ T(u, 0, 0))
    for a in (PI / 2, -PI / 2):
        for u in (-11.0, 0.0, 11.0):
            window(P, *win, wall_y=-32.0, M=T(0, YC, 0) @ RZ(a) @ T(u, 0, 0))
    # corner pinnacles on the roof
    for x in (-29.5, 29.5):
        for y in (-9.0, 25.0):
            C.drum(Mb, (x, y), 24.0, 2.6, 1.9, sides=16, bevel=0.3)
            C.drum(G, (x, y), 26.6, 0.4, 2.0, sides=16, bevel=0.1)
            C.lathe(TT, C.ellipse_profile(1.8, 1.8, 27.0, n=6, tip=0.5), 16, center=(x, y, 0), uv=6.0)
            finial(G, x, y, 28.9, 3.4, 0.5, sides=12)
    # drum d36 x 20 (z 24..44) with 8 arched capiz windows
    C.lathe(Mb, C.round_profile([(0.0, 23.8), (19.2, 23.8), (19.2, 25.0), (18.4, 25.6), (0.0, 25.6)], 0.3), 48,
            center=(0, YC, 0))
    C.lathe(MB, [(0.0, 25.4), (18.0, 25.4), (18.0, 41.6), (0.0, 41.6)], 48, center=(0, YC, 0), uv=8.0)
    C.lathe(Mb, C.round_profile([(0.0, 41.4), (18.3, 41.4), (19.0, 42.0), (19.4, 42.6), (19.4, 43.4),
                                 (18.2, 44.2), (0.0, 44.2)], 0.25), 48, center=(0, YC, 0))
    C.torus(G, (0, YC, 41.3), 18.05, 0.42, seg=72, sides=8, uv=4.0)
    C.torus(G, (0, YC, 25.7), 18.1, 0.35, seg=72, sides=8, uv=4.0)
    for k in range(8):
        window(P, 4.2, 28.0, 34.6, wall_y=-18.0, M=T(0, YC, 0) @ RZ(k * PI / 4), depth=0.9)
    # big dome to 70 (teal + 12 gold ribs)
    dprof = C.ellipse_profile(17.6, 24.6, 44.0, n=18, tip=1.6)
    C.lathe(TT, dprof, 48, center=(0, YC, 0), uv=6.0)
    C.torus(G, (0, YC, 44.35), 17.6, 0.55, seg=72, sides=8, uv=4.0)
    rib = [p for p in dprof if p[1] < 67.6]
    for k in range(12):
        sweep_rib(G, rib, PI / 12 + 2 * PI * k / 12, w=1.1, t=0.5, sink=0.2, center=(0, YC, 0), taper_r=6.0)
    # lantern + finial to 84
    C.drum(Mb, (0, YC), 66.6, 1.4, 5.0, r_top=4.4, sides=24, bevel=0.3)
    C.drum(G, (0, YC), 67.8, 0.5, 4.5, sides=24, bevel=0.15)
    C.drum(CP, (0, YC), 68.2, 4.9, 2.6, sides=16, bevel=0.0)
    for x, y, a in C.polar(6, 3.2, PI / 6):
        C.drum(Mb, (x, y + YC), 68.2, 4.9, 0.55, sides=10, bevel=0.1)
    C.drum(Mb, (0, YC), 73.0, 1.0, 4.0, sides=24, bevel=0.3)
    C.lathe(TT, C.ellipse_profile(3.6, 2.8, 74.0, n=8), 24, center=(0, YC, 0), uv=6.0)
    C.drum(G, (0, YC), 76.4, 0.7, 1.25, sides=16, bevel=0.15)
    finial(G, 0, YC, 77.0, 7.0, 1.1)
    # portico: 4 fluted columns, entablature, pediment with teal roof, gold eaves + sun emblem
    for x in (-14.5, -7.0, 7.0, 14.5):
        column(P, x, -24.2, 3.0, 18.0, 1.5, fluted=True)
    C.box(Mb, -17.0, -27.0, 21.0, 17.0, -12.0, 23.0, bevel=0.3)
    C.box(G, -16.6, -27.25, 21.9, 16.6, -26.8, 22.4, bevel=0.12)
    C.box(Mb, -17.6, -27.8, 23.0, 17.6, -12.0, 24.2, bevel=0.3)
    ex, ez0, ez1 = 17.4, 24.2, 31.4
    C.prism(Mb, [(-ex, ez0), (ex, ez0), (0.0, ez1)], -27.5, -12.0, bevel=0.3)
    al = math.atan2(ez1 - ez0, ex)
    L = math.hypot(ez1 - ez0, ex) + 1.4
    for s in (-1, 1):
        mx, mz = s * ex / 2, (ez0 + ez1) / 2
        nx, nz = s * math.sin(al), math.cos(al)
        C.block(TT, (mx + nx * 0.55, -19.95, mz + nz * 0.55), (L, 16.5, 0.9), bevel=0.25, rot=(0, s * al, 0))
        C.block(G, (mx + nx * 0.6, -28.0, mz + nz * 0.6), (L + 0.2, 0.7, 1.1), bevel=0.2, rot=(0, s * al, 0))
    C.block(G, (0, -19.9, ez1 + 1.2), (1.1, 16.9, 1.1), bevel=0.2, rot=(0, PI / 4, 0))
    finial(G, 0, -28.0, ez1 + 1.4, 3.6, 0.65, sides=12)
    for s in (-1, 1):
        finial(G, s * (ex + 0.4), -28.0, ez0 + 0.4, 2.6, 0.5, sides=12)
    sun_disc(G, (0, -27.75, 27.3), 1.7, 0.6, both=False, sides=32)
    sun_rays(G, (0, -27.6, 27.3), 1.5, 3.25, 2.6, n=12, w_long=1.25, w_short=0.9, t=0.5)
    # bronze doorway with marble + gold surround (front wall y = -12)
    dw, dsill, dspring = 10.0, 3.0, 11.0
    door = [(-dw / 2, dsill), (dw / 2, dsill)] + list(reversed(C.arch_curve(dw, dspring, "round", 14)))
    C.prism(BR, door, -12.2, -11.6, bevel=0.05)
    C.arch_frame(Mb, dw, dspring, dsill, 1.2, frame=1.5, kind="round", y0=-12.9, bevel=0.25, n=14)
    C.arch_frame(G, dw, dspring, dsill, 0.5, frame=0.45, kind="round", y0=-13.1, bevel=0.1, n=14)
    C.prism(G, [(-0.8, 15.6), (0.8, 15.6), (1.25, 18.6), (-1.25, 18.6)], -13.4, -11.8, bevel=0.12)
    C.box(G, -0.3, -12.45, dsill, 0.3, -12.0, 15.9, bevel=0.1)
    for z in (6.5, 10.5):
        C.box(G, -dw / 2 + 0.2, -12.4, z, dw / 2 - 0.2, -12.0, z + 0.45, bevel=0.1)
    # flanking towers 12x12x50 + gold spires to 66, wing walls to the base block
    TY = -4.0
    for sx in (-1, 1):
        tx = sx * 41.5
        slab(Mb, tx, TY, 6.6, 6.6, 0.0, 1.6, bevel=0.4)
        slab(Mb, tx, TY, 6.3, 6.3, 1.6, 3.0, bevel=0.35)
        slab(G, tx, TY, 6.15, 6.15, 3.0, 3.4, bevel=0.12)
        slab(MB, tx, TY, 6.0, 6.0, 2.8, 37.0, bevel=0.45)
        slab(G, tx, TY, 6.25, 6.25, 33.4, 34.0, bevel=0.15)
        slab(Mb, tx, TY, 6.4, 6.4, 36.6, 37.6, bevel=0.3)
        slab(G, tx, TY, 6.55, 6.55, 37.6, 38.0, bevel=0.12)
        slab(Mb, tx, TY, 6.9, 6.9, 38.0, 39.2, bevel=0.35)
        slab(Mb, tx, TY, 5.0, 5.0, 39.0, 46.4, bevel=0.35)
        slab(Mb, tx, TY, 5.4, 5.4, 46.2, 47.2, bevel=0.3)
        slab(G, tx, TY, 5.55, 5.55, 47.2, 47.6, bevel=0.12)
        slab(Mb, tx, TY, 5.9, 5.9, 47.6, 48.8, bevel=0.35)
        sq_frustum(TT, tx, TY, 5.6, 1.2, 48.8, 53.6)
        hip_ribs(G, tx, TY, 5.6, 1.2, 48.8, 53.6, r=0.3)
        C.drum(G, (tx, TY), 53.2, 0.8, 1.5, r_top=1.2, sides=16, bevel=0.2)
        finial(G, tx, TY, 53.8, 12.2, 1.3)
        for a in (0.0, PI / 2, PI, -PI / 2):
            window(P, 4.0, 16.0, 26.0, wall_y=-6.0, M=T(tx, TY, 0) @ RZ(a))
            window(P, 3.2, 40.4, 44.0, wall_y=-5.0, M=T(tx, TY, 0) @ RZ(a), frame=0.45)
        wx0, wx1 = (31.5, 36.0) if sx > 0 else (-36.0, -31.5)
        C.box(Mb, wx0, -9.6, 0.0, wx1, 1.6, 3.0, bevel=0.35)
        C.box(MB, wx0, -9.0, 2.8, wx1, 1.0, 15.0, bevel=0.35)
        C.box(G, wx0, -9.2, 14.6, wx1, 1.2, 15.0, bevel=0.1)
        C.box(Mb, wx0, -9.5, 15.0, wx1, 1.5, 16.3, bevel=0.35)
    return P.done(col, man)


def spire_tower(col, man, origin):
    """AL_SpireTower 18x18 x 96H: three stepped square stages (block, block, marble) with corner
    pilasters, arched capiz windows, teal skirts, an octagonal gold spire to 96 with a halo ring."""
    P = C.Piece("AL_SpireTower", origin)
    Mb, G, TT = P.bm("Marble"), P.bm("Gold"), P.bm("TealTile")
    slab(Mb, 0, 0, 9.0, 9.0, 0.0, 1.6, bevel=0.45)
    slab(Mb, 0, 0, 8.5, 8.5, 1.6, 3.0, bevel=0.4)
    slab(G, 0, 0, 7.75, 7.75, 3.0, 3.4, bevel=0.12)
    tier(P, 7.5, 2.8, 34.0, (5.0, 16.0, 26.0), 2.2)
    slab(Mb, 0, 0, 7.9, 7.9, 33.6, 34.6, bevel=0.3)
    slab(G, 0, 0, 8.05, 8.05, 34.6, 35.0, bevel=0.12)
    slab(Mb, 0, 0, 8.6, 8.6, 35.0, 36.4, bevel=0.4)
    sq_frustum(TT, 0, 0, 8.4, 6.4, 36.4, 38.6)
    hip_ribs(G, 0, 0, 8.4, 6.4, 36.4, 38.6, r=0.3)
    tier(P, 6.0, 36.2, 58.0, (4.0, 42.0, 50.0), 1.8)
    slab(Mb, 0, 0, 6.4, 6.4, 57.6, 58.6, bevel=0.3)
    slab(G, 0, 0, 6.55, 6.55, 58.6, 59.0, bevel=0.12)
    slab(Mb, 0, 0, 7.0, 7.0, 59.0, 60.2, bevel=0.4)
    sq_frustum(TT, 0, 0, 6.8, 4.9, 60.2, 62.0)
    hip_ribs(G, 0, 0, 6.8, 4.9, 60.2, 62.0, r=0.28)
    tier(P, 4.5, 60.0, 70.0, (3.0, 62.6, 66.6), 1.4, mat="Marble")
    slab(Mb, 0, 0, 4.9, 4.9, 69.6, 70.6, bevel=0.3)
    slab(G, 0, 0, 5.05, 5.05, 70.6, 71.0, bevel=0.12)
    slab(Mb, 0, 0, 5.4, 5.4, 71.0, 72.0, bevel=0.35)
    spire = [(0.0, 71.8), (4.6, 71.8), (4.6, 72.6), (4.0, 73.0), (4.0, 74.2), (4.5, 74.6), (4.5, 75.2),
             (3.7, 75.6), (3.0, 80.5), (2.4, 84.6), (2.9, 85.0), (2.9, 85.7), (2.2, 86.1), (1.55, 89.5),
             (1.0, 91.2), (1.4, 91.7), (1.4, 92.3), (0.9, 92.8), (0.42, 94.6), (0.0, 96.0)]
    C.lathe(G, spire, 8, phase=PI / 8)
    hz = 88.0
    C.torus(G, (0, 0, hz), 5.4, 0.5, seg=48, sides=8, uv=4.0)
    for x, y, a in C.polar(4, 1.0, PI / 4):
        bar(G, (1.4 * math.cos(a), 1.4 * math.sin(a), hz), (5.0 * math.cos(a), 5.0 * math.sin(a), hz), 0.3)
    for x, y, a in C.polar(8, 1.0, 0.0):
        C.spike(G, (5.7 * math.cos(a), 5.7 * math.sin(a), hz), (7.4 * math.cos(a), 7.4 * math.sin(a), hz + 0.6),
                0.38, sides=6)
    return P.done(col, man)


def halo_ring(col, man, origin):
    """AL_HaloRing: standing gold torus R10 (faces -Y) + inner bead ring + 12 alternating spikes."""
    P = C.Piece("AL_HaloRing", origin)
    G = P.bm("Gold")
    cz = 14.0
    C.torus(G, (0, 0, cz), 10.0, 1.0, seg=72, sides=12, axis="Y", uv=4.0)
    C.torus(G, (0, 0, cz), 8.55, 0.4, seg=64, sides=8, axis="Y", uv=4.0)
    for k in range(12):
        a = PI / 2 + 2 * PI * k / 12
        r1, rb = (14.0, 0.8) if k % 2 == 0 else (12.6, 0.6)
        C.spike(G, (10.5 * math.cos(a), 0, cz + 10.5 * math.sin(a)), (r1 * math.cos(a), 0, cz + r1 * math.sin(a)),
                rb, sides=6)
    return P.done(col, man)


def finial_piece(col, man, origin):
    """AL_Finial 2x2x12 gold finial."""
    P = C.Piece("AL_Finial", origin)
    finial(P.bm("Gold"), 0, 0, 0.0, 12.0, 1.0)
    return P.done(col, man)


def sun_disc_piece(col, man, origin):
    """AL_SunDisc: d8 wall emblem (flat back) -- disc + boss + 16 alternating rays."""
    P = C.Piece("AL_SunDisc", origin)
    G = P.bm("Gold")
    c = (0.0, 0.0, 4.0)
    sun_disc(G, c, 2.3, 0.8, both=False, sides=32)
    sun_rays(G, c, 1.9, 4.0, 3.2, n=16, w_long=1.5, w_short=1.1, t=0.55)
    return P.done(col, man)


def crystal_cluster(col, man, origin):
    """AL_Crystal: cluster of 5 elongated octahedra ~6x6x10, leaning out from a common root."""
    P = C.Piece("AL_Crystal", origin)
    X = P.bm("Crystal")
    spec = [  # x, y, tilt deg, lean direction deg, width, height, spin
        (0.0, 0.0, 0.0, 0.0, 3.0, 10.0, 0.35),
        (0.8, 0.3, 22.0, 15.0, 2.2, 6.6, 0.1),
        (-0.7, 0.6, 25.0, 145.0, 2.0, 5.6, 0.7),
        (0.2, -0.8, 19.0, 265.0, 2.4, 7.2, 0.25),
        (-0.6, -0.5, 32.0, 205.0, 1.7, 4.4, 0.9),
    ]
    for x, y, tilt, d, w, h, spin in spec:
        a = math.radians(d)
        axis = Vector((-math.sin(a), math.cos(a), 0.0))
        M = T(x, y, 0.0) @ Matrix.Rotation(math.radians(tilt), 4, axis)
        C.crystal(X, (0, 0, 0), w, h, sides=4, waist=0.24, band=0.3, rot=(0, 0, spin), M=M)
    return P.done(col, man)


# ================================================================ build, export, render
PIECES = [  # (builder, row width)
    (sun_gate, 58.0), (dome_pavilion, 22.0), (temple, 96.0), (spire_tower, 18.0), (halo_ring, 28.0),
    (finial_piece, 2.0), (sun_disc_piece, 8.0), (crystal_cluster, 7.0),
]


def detail_render(col, names, path, view=(-0.78, -1.0, 0.62)):
    """Render only the objects of the named pieces (temporary, unlinked collection)."""
    tmp = bpy.data.collections.new("_AL_ViewB")
    for o in col.objects:
        if o.name.split("__")[0] in names:
            tmp.objects.link(o)
    try:
        C.preview(tmp, path, view=view)
    finally:
        bpy.data.collections.remove(tmp)
    return path


col = C.clear_collection("AL_KitB")
row = C.Row(gap=30.0)
manifest = {}
for build, width in PIECES:
    build(col, manifest, row.next(width))
info = C.export_kit(col, "B", manifest)
renders = []
if not globals().get("SKIP_RENDER"):
    renders.append(C.preview(col, C.render_path("AL_KitB")))
    if not globals().get("NO_DETAIL"):
        renders.append(detail_render(col, {"AL_SunGate", "AL_DomePavilion"}, C.render_path("AL_KitB_detail1")))
        renders.append(detail_render(col, {"AL_Temple"}, C.render_path("AL_KitB_detail2")))
        renders.append(detail_render(col, {"AL_SpireTower", "AL_HaloRing", "AL_Finial", "AL_SunDisc", "AL_Crystal"},
                                     C.render_path("AL_KitB_detail3")))
bpy.ops.wm.save_mainfile()
pieces = {}
for name, e in manifest.items():
    tris = sum(C.tri_count(bpy.data.objects[o]) for o in e["objects"])
    pieces[name] = {"size": e["size"], "objects": e["objects"], "tris": tris}
result = {"export": info, "pieces": pieces, "renders": renders}
