# Alamat Defense Lobby "Holy Coast" -- Kit C (ground / plaza props), B172.
# Builds AL_Stairs, AL_Dais, AL_Mandala, AL_LampPost, AL_Parasol, AL_Planter, AL_Banner, AL_MarketStall,
# AL_Fountain (README.md piece specs) into collection AL_KitC, one object per material
# (<Piece>__<Mat>), origin = bottom-centre, front = -Y, laid out along +X with 30-stud gaps.
# Writes glb/AL_KitC.glb + glb/AL_KitC.json and renders/AL_KitC.png (+ close-ups AL_KitC_<a|b|c>.png).
#
# Run (background Blender 5.2, from Git Bash):
#   "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b <root>/blend/AL_kitC_ground.blend
#     --python-expr "exec(open(r'<repo>/tools/maps/lobby/kit_ground.py').read()); import bpy;
#                    bpy.ops.wm.save_mainfile(); print('RESULT', result)"
# Set DETAIL = False before the exec to skip the three close-up renders; RENDER = False skips all renders.
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

PI = math.pi
TRIM = 0.185  # the Cloth texture's blue + gold trim fills v = 0 .. 0.185 (bottom of the image)


# ================================================================ kit-local helpers
def round_loop(pts, radius, seg=2):
    """C.round_profile for a CLOSED (r, z) loop: every corner rounded."""
    mid = ((pts[0][0] + pts[-1][0]) / 2, (pts[0][1] + pts[-1][1]) / 2)
    return C.round_profile([mid] + list(pts) + [mid], radius, seg)[:-1]


def ring_solid(bm, loop, sides=24, center=(0, 0, 0), phase=0.0):
    """Revolve a CLOSED (r, z) loop about Z -> a solid ring (inlay band, rim, collar) with no caps.
    UVs are left to the box pass."""
    tmp = bmesh.new()
    angs = [phase + 2 * PI * k / sides for k in range(sides)]
    rings = [[tmp.verts.new((r * math.cos(a), r * math.sin(a), z)) for a in angs] for r, z in loop]
    n = len(rings)
    for i in range(n):
        A, B = rings[i], rings[(i + 1) % n]
        for k in range(sides):
            k2 = (k + 1) % sides
            tmp.faces.new((A[k], A[k2], B[k2], B[k]))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp, C._matrix(center))


def sheet(bm, grid, offs, uvs=None, wrap=False):
    """Thick cloth shell from a grid of outer-surface points (rows x cols). offs[i][j] = vector from the
    outer to the inner skin. uvs[i][j] = (u, v) per point (rows need cols+1 entries when wrap=True, the
    last one closing the seam); the faces are then marked done. wrap=True closes the columns (parasol)."""
    tmp = bmesh.new()
    uvl = tmp.loops.layers.uv.new("UVMap") if uvs is not None else None
    nr, nc = len(grid), len(grid[0])
    A = [[tmp.verts.new(Vector(p)) for p in row] for row in grid]
    B = [[tmp.verts.new(Vector(p) + Vector(o)) for p, o in zip(row, orow)] for row, orow in zip(grid, offs)]
    span = nc if wrap else nc - 1

    def U(i, j):
        return uvs[i][j] if uvs is not None else (0.0, 0.0)

    def face(vs, cs):
        try:
            f = tmp.faces.new(vs)
        except ValueError:
            return
        if uvl is not None:
            for lp, c in zip(f.loops, cs):
                lp[uvl].uv = c

    for i in range(nr - 1):
        for j in range(span):
            j2 = (j + 1) % nc
            face((A[i][j], A[i][j2], A[i + 1][j2], A[i + 1][j]), (U(i, j), U(i, j + 1), U(i + 1, j + 1), U(i + 1, j)))
            face((B[i + 1][j], B[i + 1][j2], B[i][j2], B[i][j]), (U(i + 1, j), U(i + 1, j + 1), U(i, j + 1), U(i, j)))
    for i in (0, nr - 1):  # edge strips along the first / last rows
        for j in range(span):
            j2 = (j + 1) % nc
            face((A[i][j], B[i][j], B[i][j2], A[i][j2]), (U(i, j), U(i, j), U(i, j + 1), U(i, j + 1)))
    if not wrap:  # edge strips along the first / last columns
        for j in (0, nc - 1):
            for i in range(nr - 1):
                face((A[i][j], A[i + 1][j], B[i + 1][j], B[i][j]), (U(i, j), U(i + 1, j), U(i + 1, j), U(i, j)))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp, None, uv=uvs is not None)


def tube(bm, pts, r, sides=8, cap=True):
    """Round tube along a polyline (ribs, struts, rods, crossbars); UVs by the box pass."""
    tmp = bmesh.new()
    P = [Vector(p) for p in pts]
    n = len(P)
    angs = [2 * PI * k / sides for k in range(sides)]
    rings, u = [], None
    for i in range(n):
        d = (P[min(i + 1, n - 1)] - P[max(i - 1, 0)]).normalized()
        if u is None:
            a = Vector((1, 0, 0)) if abs(d.x) < 0.9 else Vector((0, 1, 0))
            u = d.cross(a).normalized()
        else:
            u = (u - d * u.dot(d)).normalized()
        w = d.cross(u).normalized()
        rings.append([tmp.verts.new(P[i] + (u * math.cos(t) + w * math.sin(t)) * r) for t in angs])
    for R0, R1 in zip(rings[:-1], rings[1:]):
        for k in range(sides):
            k2 = (k + 1) % sides
            tmp.faces.new((R0[k], R0[k2], R1[k2], R1[k]))
    if cap:
        tmp.faces.new(rings[0])
        tmp.faces.new(list(reversed(rings[-1])))
    bmesh.ops.recalc_face_normals(tmp, faces=tmp.faces)
    return C._append(bm, tmp)


def ball(bm, center, r, sides=10, squash=1.0):
    """Small lathed sphere (rib tips, crossbar ends, studs)."""
    prof = [(r * math.sin(t), -r * squash * math.cos(t)) for t in [PI * k / 6 for k in range(7)]]
    prof[0], prof[-1] = (0.0, -r * squash), (0.0, r * squash)
    return C.lathe(bm, prof, sides, center)


def sun_emblem(bm, y0, y1, r_disc, r_in, r_long, r_short, n=12, half_w=0.2, bevel=0.05, M=None):
    """The sun-halo motif as a flat relief in the XZ plane (centre at the origin, faces -Y): a disc of
    r_disc plus n triangular rays from r_in, alternating r_long / r_short, extruded y0..y1.
    M places it (translate / rotate about Z for other facings)."""
    M = M if M is not None else Matrix()
    C.drum(bm, (0, 0), y0, y1 - y0, r_disc, sides=24, bevel=min(bevel * 1.5, (y1 - y0) * 0.45),
           M=M @ Matrix.Rotation(-PI / 2, 4, "X"))
    for k in range(n):
        a = PI / 2 + 2 * PI * k / n
        ro = r_long if k % 2 == 0 else r_short
        d, t = (math.cos(a), math.sin(a)), (-math.sin(a), math.cos(a))
        pts = [(r_in * d[0] - half_w * t[0], r_in * d[1] - half_w * t[1]), (ro * d[0], ro * d[1]),
               (r_in * d[0] + half_w * t[0], r_in * d[1] + half_w * t[1])]
        C.prism(bm, pts, y0, y1, bevel=bevel, M=M)


def lantern(P, x, y, z0, s=1.0, drop=False):
    """Hexagonal capiz lantern standing on z0 (flat face to -Y): gold base plate, capiz body, gold corner
    posts, flared gold roof with a finial. Height 3.5*s; drop=True adds a gold drop below (hanging)."""
    g, cz = P.bm("Gold"), P.bm("Capiz")

    def sc(pts):
        return [(r * s, z * s) for r, z in pts]

    C.lathe(g, C.round_profile(sc([(0, 0), (1.3, 0), (1.3, 0.3), (0, 0.3)]), 0.08 * s), 6, (x, y, z0))
    C.lathe(cz, sc([(0, 0.3), (0.95, 0.3), (0.95, 1.72), (0, 1.72)]), 6, (x, y, z0))
    for k in range(6):
        a = 2 * PI * k / 6
        C.drum(g, (x + 0.97 * s * math.cos(a), y + 0.97 * s * math.sin(a)), z0 + 0.28 * s, 1.46 * s,
               max(0.15, 0.16 * s), sides=6, bevel=0.03)
    roof = [(0, 1.7), (1.5, 1.7), (1.5, 1.95), (0.95, 2.3), (0.4, 2.75), (0.42, 2.9), (0.3, 3.0), (0.36, 3.15),
            (0, 3.5)]
    C.lathe(g, C.round_profile(sc(roof), 0.07 * s), 6, (x, y, z0))
    if drop:
        C.lathe(g, sc([(0, -0.75), (0.3, -0.38), (0.78, -0.04), (0.78, 0.02), (0, 0.02)]), 6, (x, y, z0))


# ================================================================ pieces
def build_stairs(row, col, man):
    """24W x 18D x 12H: 8 marble steps of 1.5 with gold nosings + teal riser tiles, MarbleBlock cheek
    walls with gold coping, newel posts with gold flame finials at the foot."""
    P = C.Piece("AL_Stairs", row.next(24.8))
    m, mb, g, t = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    n, rise, depth = 8, 1.5, 18.0
    run = depth / n
    for i in range(n):
        y0, z0, z1 = -depth / 2 + run * i, rise * i, rise * (i + 1)
        C.box(m, -10.25, y0, z0, 10.25, depth / 2, z1, bevel=0.22)
        C.box(g, -9.75, y0 - 0.14, z1 - 0.42, 9.75, y0 + 0.4, z1 + 0.04, bevel=0.12)   # gold nosing
        C.box(t, -9.1, y0 - 0.07, z0 + 0.3, 9.1, y0 + 0.3, z0 + 0.92, bevel=0.08)      # teal riser tiles
    # cheek walls: side profile (y, z) extruded along X (Rz90 maps local x -> world y, local y -> world -x)
    k = rise / run
    zf, ztop = 3.4, 13.6
    yb = -depth / 2 + (ztop - zf) / k
    prof = [(-depth / 2, 0.0), (depth / 2, 0.0), (depth / 2, ztop), (yb, ztop), (-depth / 2, zf)]
    Mz = Matrix.Rotation(PI / 2, 4, "Z")
    yc = -7.0
    zc = zf + k * (yc + depth / 2)
    cop = [(yc, zc - 0.06), (yb, ztop - 0.06), (depth / 2 + 0.15, ztop - 0.06), (depth / 2 + 0.15, ztop + 0.5),
           (yb, ztop + 0.5), (yc, zc + 0.5)]
    for sx in (-1, 1):
        b0, b1 = (10.0, 12.0) if sx < 0 else (-12.0, -10.0)
        C.prism(mb, prof, b0, b1, bevel=0.25, M=Mz)
        C.prism(g, cop, b0 - 0.2, b1 + 0.2, bevel=0.14, M=Mz)
        xc = sx * 10.9
        C.box(mb, xc - 1.3, -9.6, 0, xc + 1.3, -6.7, 5.0, bevel=0.3)                    # newel
        C.box(m, xc - 1.5, -9.8, 0, xc + 1.5, -6.5, 0.6, bevel=0.2)                     # newel plinth
        C.box(m, xc - 1.45, -9.75, 4.3, xc + 1.45, -6.55, 4.75, bevel=0.15)             # newel collar
        C.box(g, xc - 1.5, -9.8, 4.95, xc + 1.5, -6.5, 5.45, bevel=0.15)                # gold cap slab
        flame = [(0, 0), (0.95, 0), (0.95, 0.3), (0.55, 0.55), (1.0, 1.25), (0.6, 2.0), (0, 2.7)]
        C.lathe(g, C.round_profile(flame, 0.15), 16, (xc, -8.15, 5.45))
    P.done(col, man)


def build_dais(row, col, man):
    """Octagon d26 x 3H in 2 steps: gold inlay ring on the lower tread, gold band on the upper riser, a
    teal rune ring with gold glyphs + borders on top and a gold 8-point star at the centre."""
    P = C.Piece("AL_Dais", row.next(26))
    m, g, t = P.bm("Marble"), P.bm("Gold"), P.bm("TealTile")
    ph = PI / 8  # flat octagon face to the front
    C.lathe(m, C.round_profile([(0, 0), (13.0, 0), (13.0, 1.5), (0, 1.5)], 0.3), 8, phase=ph)
    C.lathe(m, C.round_profile([(0, 1.4), (10.4, 1.4), (10.4, 3.0), (0, 3.0)], 0.3), 8, phase=ph)
    ring_solid(g, [(11.2, 1.44), (12.1, 1.44), (12.1, 1.57), (11.2, 1.57)], 8, phase=ph)
    ring_solid(g, [(10.3, 1.95), (10.52, 1.95), (10.52, 2.45), (10.3, 2.45)], 8, phase=ph)
    # rune ring on top
    ring_solid(t, [(6.4, 2.97), (8.6, 2.97), (8.6, 3.07), (6.4, 3.07)], 48)
    ring_solid(g, round_loop([(5.9, 2.97), (6.4, 2.97), (6.4, 3.13), (5.9, 3.13)], 0.04), 48)
    ring_solid(g, round_loop([(8.6, 2.97), (9.1, 2.97), (9.1, 3.13), (8.6, 3.13)], 0.04), 48)
    for i, (x, y, a) in enumerate(C.polar(16, 7.5, PI / 16)):
        rd, tg = Vector((math.cos(a), math.sin(a), 0)), Vector((-math.sin(a), math.cos(a), 0))
        c = Vector((x, y, 3.11))
        if i % 2 == 0:  # diamond
            C.block(g, c, (0.85, 0.85, 0.12), bevel=0.04, rot=(0, 0, a + PI / 4))
        else:  # baybayin-like "U" glyph + dot
            C.block(g, c - rd * 0.22, (0.32, 1.0, 0.12), bevel=0.04, rot=(0, 0, a))
            for st in (-1, 1):
                C.block(g, c + rd * 0.12 + tg * st * 0.34, (0.66, 0.32, 0.12), bevel=0.04, rot=(0, 0, a))
            C.block(g, c + rd * 0.62, (0.34, 0.34, 0.12), bevel=0.04, rot=(0, 0, a + PI / 4))
    star = []
    for i in range(16):
        r = 2.7 if i % 2 == 0 else 1.2
        a = PI / 2 + PI * i / 8
        star.append((r * math.cos(a), r * math.sin(a)))
    C.prism(g, star, 2.97, 3.12, bevel=0.04, M=Matrix.Rotation(PI / 2, 4, "X"))  # outline (x, z) -> XY plane
    C.drum(t, (0, 0), 2.97, 0.22, 0.75, sides=16, bevel=0.06)
    P.done(col, man)


def build_mandala(row, col, man):
    """Disc d60 x 0.4 plaza inlay: Mandala-textured top on a marble core, chunky gold rim with 8 studs."""
    P = C.Piece("AL_Mandala", row.next(60))
    r_in = 29.3
    C.lathe(P.bm("Marble"), [(0, 0), (r_in, 0), (r_in, 0.38), (0, 0.38)], 64)
    f = C.lathe(P.bm("Mandala"), [(r_in, 0.4), (0, 0.4)], 96, cap=False)
    C.disc_uv(P.bm("Mandala"), f, (0, 0), r_in / 0.988)  # edge lands on the painted gold rim
    ring_solid(P.bm("Gold"), round_loop([(29.0, 0.0), (30.0, 0.0), (30.0, 0.55), (29.0, 0.55)], 0.2), 96)
    for x, y, a in C.polar(8, 29.5, 0.0):
        C.lathe(P.bm("Gold"), C.ellipse_profile(0.5, 0.32, 0.5, n=5), 12, (x, y, 0))
    P.done(col, man)


def build_lamppost(row, col, man):
    """14H: marble plinth + pedestal, gold collar, tapered bronze post with gold rings, gold crown cup and a
    hexagonal capiz lantern with a gold roof."""
    P = C.Piece("AL_LampPost", row.next(3.0))
    m, b, g = P.bm("Marble"), P.bm("Bronze"), P.bm("Gold")
    C.box(m, -1.4, -1.4, 0, 1.4, 1.4, 0.8, bevel=0.25)
    C.lathe(m, C.round_profile([(0, 0.8), (1.1, 0.8), (1.1, 1.2), (0.75, 1.6), (0.7, 2.6), (0.95, 2.9),
                                (0.95, 3.2), (0, 3.2)], 0.15), 16)
    C.drum(g, (0, 0), 3.2, 0.5, 0.8, r_top=0.55, sides=16, bevel=0.12)
    C.drum(b, (0, 0), 3.6, 6.2, 0.42, r_top=0.34, sides=12, bevel=0.08)
    for z in (5.4, 7.6):
        C.torus(g, (0, 0, z), 0.42 - (z - 3.6) / 6.2 * 0.08, 0.17, seg=16, sides=8)
    C.lathe(g, C.round_profile([(0, 9.6), (0.45, 9.6), (0.55, 9.85), (1.05, 10.15), (1.35, 10.3), (1.35, 10.45),
                                (0, 10.45)], 0.08), 12)
    lantern(P, 0, 0, 10.45, 1.0)
    P.uv_scale["Capiz"] = 2.0  # ~2 panes per lantern face
    P.done(col, man)


def build_parasol(row, col, man):
    """d10 x 9H: 8-rib parasol, white Cloth canopy (panels sag between gold ribs) with a scalloped valance
    carrying the blue + gold trim, bronze pole + struts, marble weighted base, gold finial."""
    P = C.Piece("AL_Parasol", row.next(10.4))
    m, b, g, cl = P.bm("Marble"), P.bm("Bronze"), P.bm("Gold"), P.bm("Cloth")
    R, ribs, sub = 5.0, 8, 6
    nc = ribs * sub
    z_apex, z_hem = 8.05, 6.55
    ph = PI / 8  # ribs at 22.5 + k*45 deg -> a panel faces the front
    ts = [0.07, 0.25, 0.45, 0.65, 0.85, 1.0]

    def th(j):
        return ph + 2 * PI * j / nc

    def sag(j):
        return math.sin(PI * (j % sub) / sub)

    def cpt(t, j):
        r = R * t * (1 - 0.04 * sag(j))
        z = z_hem + (z_apex - z_hem) * (1 - t ** 1.6) - 0.25 * sag(j) * t
        return Vector((r * math.cos(th(j)), r * math.sin(th(j)), z))

    grid = [[cpt(t, j) for j in range(nc)] for t in ts]
    offs = [[(0, 0, -0.16)] * nc for _ in ts]
    uvs = [[(4.0 * j / nc, TRIM + 0.005 + (1 - TRIM - 0.01) * (1 - t)) for j in range(nc + 1)] for t in ts]
    sheet(cl, grid, offs, uvs, wrap=True)
    # scalloped valance: deepest mid-panel; u = 4 studs/tile so the trim keeps its proportions
    vg, vo, vu = [], [], []
    for fr in (0.0, 0.5, 1.0):
        rowp, rowo, rowu = [], [], []
        for j in range(nc):
            top = cpt(1.0, j)
            h = 0.55 + 0.55 * sag(j)
            rr = Vector((top.x, top.y, 0)).length + 0.12 * fr
            rowp.append((rr * math.cos(th(j)), rr * math.sin(th(j)), top.z + 0.04 - fr * h))
            rowo.append((-0.12 * math.cos(th(j)), -0.12 * math.sin(th(j)), 0.0))
        for j in range(nc + 1):
            rowu.append((8.0 * j / nc, TRIM * (1 - fr)))
        vg.append(rowp)
        vo.append(rowo)
        vu.append(rowu)
    sheet(cl, vg, vo, vu, wrap=True)
    # gold ribs on top, gold tips, bronze struts underneath
    for kk in range(ribs):
        j = kk * sub
        tube(g, [cpt(t, j) + Vector((0, 0, 0.1)) for t in ts], 0.15, 6)
        ball(g, cpt(1.0, j) + Vector((0, 0, 0.02)), 0.28, 8)
        a = th(j)
        tube(b, [(0.25 * math.cos(a), 0.25 * math.sin(a), 5.25), cpt(0.55, j) - Vector((0, 0, 0.18))], 0.15, 6)
    # pole, base, runner collar, finial
    C.lathe(m, C.round_profile([(0, 0), (1.5, 0), (1.5, 0.35), (1.0, 0.6), (0.55, 0.95), (0.45, 1.3), (0, 1.3)],
                               0.15), 20)
    C.drum(b, (0, 0), 1.0, 7.3, 0.22, sides=10, bevel=0.06)
    C.drum(g, (0, 0), 5.0, 0.55, 0.36, sides=12, bevel=0.1)
    C.drum(g, (0, 0), 1.2, 0.35, 0.5, sides=12, bevel=0.1)
    C.lathe(g, C.round_profile([(0, 7.95), (0.62, 7.95), (0.62, 8.15), (0.3, 8.35), (0.42, 8.6), (0, 9.05)], 0.08),
            12)
    P.done(col, man)


def build_planter(row, col, man):
    """Marble urn d4 x 4: footed baluster profile, teal glazed belly band between gold rings, gold lip ring,
    bronze soil top (plants are placed in Studio)."""
    P = C.Piece("AL_Planter", row.next(4.3))
    m, t, g, b = P.bm("Marble"), P.bm("TealTile"), P.bm("Gold"), P.bm("Bronze")
    low = [(0, 0), (1.35, 0), (1.35, 0.32), (0.95, 0.55), (0.72, 0.85), (0.8, 1.05), (1.3, 1.3), (1.6, 1.5)]
    band = [(1.6, 1.5), (1.85, 1.8), (1.97, 2.2), (1.9, 2.6), (1.78, 2.8)]
    top = [(1.78, 2.8), (1.5, 3.1), (1.42, 3.3), (1.7, 3.55), (2.0, 3.65), (2.0, 3.95), (1.68, 3.95), (1.62, 3.6),
           (0, 3.6)]
    C.lathe(m, C.round_profile(low, 0.12), 24, cap=False)
    C.lathe(t, band, 24, cap=False, uv=3.0)
    C.lathe(m, C.round_profile(top, 0.1), 24, cap=False)
    C.torus(g, (0, 0, 1.5), 1.6, 0.15, seg=32, sides=8)
    C.torus(g, (0, 0, 2.8), 1.78, 0.15, seg=32, sides=8)
    C.torus(g, (0, 0, 3.8), 1.95, 0.17, seg=32, sides=8)
    C.lathe(b, [(1.64, 3.58), (1.2, 3.68), (0.6, 3.74), (0, 3.76)], 20, cap=False)
    P.done(col, man)


def build_banner(row, col, man):
    """Post + hanging cloth 3W x 10H: marble foot, bronze pole, gold crossbar on a bracket, white Cloth with
    the blue + gold trim at the hem, gold sun emblem (both faces), gold tassels, spear + halo finial."""
    P = C.Piece("AL_Banner", row.next(4.8))
    m, b, g, cl = P.bm("Marble"), P.bm("Bronze"), P.bm("Gold"), P.bm("Cloth")
    C.box(m, -1.2, -1.2, 0, 1.2, 1.2, 0.6, bevel=0.2)
    C.lathe(m, C.round_profile([(0, 0.6), (0.9, 0.6), (0.9, 0.95), (0.55, 1.3), (0.5, 1.6), (0, 1.6)], 0.12), 16)
    C.drum(g, (0, 0), 1.55, 0.35, 0.45, sides=12, bevel=0.1)
    C.drum(b, (0, 0), 1.8, 11.9, 0.28, r_top=0.24, sides=10, bevel=0.06)
    C.torus(g, (0, 0, 12.6), 0.25, 0.15, seg=16, sides=8)
    yc = -0.62  # cloth centre plane, in front of the pole
    C.box(g, -0.32, yc - 0.18, 12.85, 0.32, -0.05, 13.35, bevel=0.1)       # bracket
    tube(g, [(-1.95, yc, 13.1), (1.95, yc, 13.1)], 0.2, 10)                 # crossbar
    for sx in (-1, 1):
        ball(g, (sx * 2.1, yc, 13.1), 0.32, 10)
    zt, zb = 12.95, 2.95
    hem = TRIM * 4.5  # trim height for a 4.5-stud tile across the 3-stud width (undistorted)
    zs = [zb, zb + hem, zb + 3.0, zb + 5.5, zb + 8.0, zt]
    xs = [-1.5, -0.75, 0.0, 0.75, 1.5]

    def vz(z):
        if z <= zb + hem + 1e-6:
            return TRIM * (z - zb) / hem
        return TRIM + (1 - TRIM - 0.01) * (z - zb - hem) / (zt - zb - hem)

    grid = [[(x, yc - 0.06, z) for x in xs] for z in zs]
    offs = [[(0, 0.12, 0)] * len(xs) for _ in zs]
    uvs = [[((x + 1.5) / 4.5, vz(z)) for x in xs] for z in zs]
    sheet(cl, grid, offs, uvs)
    for y0, y1 in ((yc - 0.16, yc - 0.04), (yc + 0.04, yc + 0.16)):  # sun emblem on both faces
        sun_emblem(g, y0, y1, 0.62, 0.7, 1.38, 1.05, n=12, half_w=0.2, M=Matrix.Translation((0, 0, 9.2)))
    for x in (-1.3, 0.0, 1.3):  # tassels
        C.lathe(g, [(0, -0.8), (0.16, -0.62), (0.27, -0.32), (0.2, -0.08), (0.12, 0.02), (0, 0.06)], 8, (x, yc, zb))
    C.lathe(g, C.round_profile([(0, 13.6), (0.42, 13.6), (0.42, 13.85), (0.22, 14.0), (0.4, 14.35), (0, 15.3)],
                               0.08), 10)
    C.torus(g, (0, 0, 14.45), 0.75, 0.15, seg=24, sides=8, axis="Y")
    P.done(col, man)


def build_stall(row, col, man):
    """14W x 10D x 12H: marble counter (teal tile panels, gold trim + rosettes), back table, 4 marble posts
    with gold capitals, beam frame, gable canopy of white Cloth / Gold stripes with scalloped valances,
    gold ridge roll + finials, gable sun emblems, 2 hanging capiz lanterns."""
    P = C.Piece("AL_MarketStall", row.next(14.6))
    m, g, cl, t = P.bm("Marble"), P.bm("Gold"), P.bm("Cloth"), P.bm("TealTile")
    px, py = 6.15, 4.2
    for sx in (-1, 1):
        for sy in (-1, 1):
            x, y = sx * px, sy * py
            C.lathe(m, C.round_profile([(0, 0), (0.8, 0), (0.8, 0.45), (0.52, 0.7), (0.45, 8.3), (0, 8.3)], 0.12),
                    12, (x, y, 0))
            C.torus(g, (x, y, 0.72), 0.5, 0.15, seg=16, sides=8)
            C.drum(g, (x, y), 8.25, 0.55, 0.5, r_top=0.75, sides=12, bevel=0.1)
    ze, zr, ye = 9.6, 11.3, 5.35  # eave height, ridge height, eave half-depth
    C.box(m, -6.95, -py - 0.6, 8.8, 6.95, -py + 0.6, ze, bevel=0.2)
    C.box(m, -6.95, py - 0.6, 8.8, 6.95, py + 0.6, ze, bevel=0.2)
    for sx in (-1, 1):
        C.box(m, sx * (px - 0.55), -py + 0.5, 8.8, sx * (px + 0.55), py - 0.5, ze, bevel=0.2)
        C.box(g, sx * (px - 0.2), -0.2, ze - 0.05, sx * (px + 0.2), 0.2, zr - 0.1, bevel=0.06)  # king post
        sun_emblem(g, -0.12, 0.04, 0.42, 0.48, 0.95, 0.72, n=12, half_w=0.15, bevel=0.04,
                   M=Matrix.Translation((sx * (px + 0.2), 0, 10.35)) @ Matrix.Rotation(sx * PI / 2, 4, "Z"))
    # counter + back table
    C.box(m, -5.95, -4.85, 0, 5.95, -2.35, 0.45, bevel=0.15)
    C.box(m, -5.75, -4.6, 0.3, 5.75, -2.6, 3.2, bevel=0.25)
    C.box(g, -5.85, -4.72, 2.9, 5.85, -2.48, 3.22, bevel=0.1)
    C.box(m, -6.1, -4.95, 3.2, 6.1, -2.3, 3.7, bevel=0.2)
    for cx in (-3.8, 0.0, 3.8):
        C.box(t, cx - 1.5, -4.68, 0.8, cx + 1.5, -4.5, 2.5, bevel=0.08)
        C.block(g, (cx, -4.74, 1.65), (0.62, 0.16, 0.62), bevel=0.05, rot=(0, PI / 4, 0))
    C.box(m, -5.4, 2.75, 0, 5.4, 4.0, 2.6, bevel=0.2)
    C.box(m, -5.6, 2.6, 2.6, 5.6, 4.2, 3.0, bevel=0.15)
    # canopy: 8 stripes across X, alternating white Cloth and Gold
    ns, x0 = 8, -7.15
    w = -2 * x0 / ns
    fs = [-1.0, -0.5, 0.0, 0.5, 1.0]
    ps = [k / 6 for k in range(7)]
    slope = math.hypot(ye, zr - ze)

    def cpt(x, f, p):
        z = ze + (zr - ze) * (1 - abs(f)) - 0.14 * math.sin(PI * abs(f)) + 0.07 * math.sin(PI * p)
        return (x, f * ye, z)

    for i in range(ns):
        xa = x0 + i * w
        cloth = i % 2 == 0
        bmx = cl if cloth else g
        xs = [xa + p * w for p in ps]
        grid = [[cpt(x, f, p) for x, p in zip(xs, ps)] for f in fs]
        offs = [[(0, 0, -0.14)] * len(ps) for _ in fs]
        if cloth:
            uvs = [[(p * w / 4.0, TRIM + 0.005 + (1 - TRIM - 0.01) * (1 - abs(f))) for p in ps] for f in fs]
        else:
            uvs = [[(x / 4.0, abs(f) * slope / 4.0) for x in xs] for f in fs]
        sheet(bmx, grid, offs, uvs)
        for side in (-1, 1):  # scalloped valances, front and back
            vg, vo, vu = [], [], []
            for fr in (0.0, 0.5, 1.0):
                rowp, rowu = [], []
                for x, p in zip(xs, ps):
                    d = 0.6 + 0.45 * math.sin(PI * p)
                    z = ze + 0.06 - fr * d
                    rowp.append((x, side * (ye + 0.03), z))
                    rowu.append((p * w / 4.0, TRIM * (1 - fr)) if cloth else (x / 4.0, z / 4.0))
                vg.append(rowp)
                vo.append([(0, -side * 0.12, 0)] * len(ps))
                vu.append(rowu)
            sheet(bmx, vg, vo, vu)
    tube(g, [(-7.3, 0, zr + 0.07), (7.3, 0, zr + 0.07)], 0.24, 10)  # ridge roll
    for sx in (-1, 1):
        C.lathe(g, C.round_profile([(0, -0.35), (0.38, -0.15), (0.42, 0.15), (0.2, 0.4), (0.3, 0.55), (0, 1.05)],
                                   0.06), 10, (sx * 7.3, 0, zr + 0.07))
    for x in (-3.3, 3.3):  # hanging capiz lanterns
        s = 0.62
        z0 = 8.25 - 3.5 * s
        C.drum(g, (x, -py), z0 + 3.4 * s, 8.8 - (z0 + 3.4 * s), 0.15, sides=8, bevel=0.03)
        lantern(P, x, -py, z0, s, drop=True)
    P.uv_scale["Capiz"] = 1.4
    P.done(col, man)


def build_fountain(row, col, man):
    """d18 x 10H: MarbleBlock basin wall with gold sun medallions + seam rings, chunky marble rim, teal-tiled
    pool, baluster pedestal with 4 gold spouts, upper bowl (teal inside, gold rim + drops), gold sunburst
    finial. Water is added in Studio."""
    P = C.Piece("AL_Fountain", row.next(18.2))
    m, mb, g, t = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    S = 48
    ring_solid(m, round_loop([(8.3, 0.0), (9.0, 0.0), (9.0, 0.32), (8.62, 0.5), (8.3, 0.5)], 0.12), S)  # skirt
    C.lathe(mb, [(8.6, 0.45), (8.6, 2.0)], S, cap=False, uv=4.0)
    ring_solid(m, round_loop([(7.55, 1.95), (8.6, 1.95), (9.1, 2.05), (9.1, 2.55), (7.55, 2.55)], 0.2), S)  # rim
    C.lathe(t, [(7.6, 2.0), (7.6, 0.55), (0, 0.55)], S, cap=False, uv=6.0)
    C.torus(g, (0, 0, 1.98), 8.62, 0.16, seg=S, sides=8)
    C.torus(g, (0, 0, 0.5), 8.62, 0.14, seg=S, sides=8)
    for k in range(8):
        a = PI / 8 + 2 * PI * k / 8
        M = Matrix.Rotation(a + PI / 2, 4, "Z") @ Matrix.Translation((0, 0, 1.24))
        sun_emblem(g, -8.74, -8.56, 0.32, 0.38, 0.68, 0.52, n=8, half_w=0.15, bevel=0.03, M=M)
    # pedestal + spouts
    ped = [(0, 0.55), (2.2, 0.55), (2.2, 1.0), (1.6, 1.4), (1.1, 2.2), (0.9, 3.4), (1.1, 4.3), (1.7, 4.9), (1.7, 5.3),
           (0, 5.3)]
    C.lathe(m, C.round_profile(ped, 0.2), 24)
    C.torus(g, (0, 0, 3.4), 0.92, 0.18, seg=24, sides=8)
    for k in range(4):
        a = PI / 4 + PI / 2 * k
        ca, sa = math.cos(a), math.sin(a)
        C.spike(g, (0.85 * ca, 0.85 * sa, 3.95), (2.1 * ca, 2.1 * sa, 3.6), 0.32, sides=8, r_tip=0.15)
    # upper bowl: marble outside, teal inside, gold rim ring + drops
    C.lathe(m, C.round_profile([(0, 5.2), (1.6, 5.2), (3.0, 5.55), (4.0, 6.05), (4.45, 6.7), (4.45, 7.0), (3.9, 7.05),
                                (3.8, 6.85)], 0.15), 32, cap=False)
    C.lathe(t, [(3.8, 6.85), (2.6, 6.4), (0, 6.2)], 32, cap=False, uv=3.0)
    C.torus(g, (0, 0, 6.85), 4.45, 0.18, seg=32, sides=8)
    for x, y, a in C.polar(12, 4.2, PI / 12):
        C.lathe(g, [(0, -0.55), (0.14, -0.4), (0.24, -0.18), (0.2, 0.0), (0, 0.05)], 8, (x, y, 6.3))
    # top pedestal + sunburst finial
    C.lathe(m, C.round_profile([(0, 6.1), (0.9, 6.1), (0.9, 6.4), (0.55, 6.8), (0.5, 7.6), (0.75, 7.9), (0.75, 8.1),
                                (0, 8.1)], 0.1), 16)
    C.lathe(g, C.round_profile([(0, 8.05), (0.6, 8.05), (0.62, 8.2), (0.3, 8.45), (0, 8.45)], 0.06), 12)
    ball(g, (0, 0, 8.95), 0.62, 16)  # sun orb
    for rz in (0.0, PI / 2):
        sun_emblem(g, -0.12, 0.12, 0.0001, 0.6, 1.05, 0.82, n=12, half_w=0.17, bevel=0.04,
                   M=Matrix.Translation((0, 0, 8.95)) @ Matrix.Rotation(rz, 4, "Z"))
    P.done(col, man)


# ================================================================ build, export, render
def detail_render(col, names, tag):
    """Close-up render of a subset of pieces (temporary collection, removed afterwards)."""
    sub = bpy.data.collections.new("_AL_KitC_" + tag)
    C.scene().collection.children.link(sub)
    for o in col.objects:
        if o.name.split("__")[0] in names:
            sub.objects.link(o)
    path = C.preview(sub, C.render_path("AL_KitC_" + tag))
    C.scene().collection.children.unlink(sub)
    bpy.data.collections.remove(sub)
    return path


def build():
    col = C.clear_collection("AL_KitC")
    row = C.Row(gap=30.0)
    man = {}
    build_stairs(row, col, man)
    build_dais(row, col, man)
    build_mandala(row, col, man)
    build_lamppost(row, col, man)
    build_parasol(row, col, man)
    build_planter(row, col, man)
    build_banner(row, col, man)
    build_stall(row, col, man)
    build_fountain(row, col, man)
    info = C.export_kit(col, "C", man)
    tris = {o.name: C.tri_count(o) for o in col.objects if o.type == "MESH"}
    renders = []
    if globals().get("RENDER", True):
        renders.append(C.preview(col, C.render_path("AL_KitC")))
        if globals().get("DETAIL", True):
            renders.append(detail_render(col, {"AL_Stairs", "AL_Dais", "AL_Fountain"}, "a"))
            renders.append(detail_render(col, {"AL_LampPost", "AL_Parasol", "AL_Planter", "AL_Banner"}, "b"))
            renders.append(detail_render(col, {"AL_MarketStall", "AL_Mandala"}, "c"))
    return {"export": info, "manifest": man, "tris": tris, "renders": renders}


result = build()
