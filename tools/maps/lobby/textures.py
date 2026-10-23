# Alamat Defense Lobby "Holy Coast" kit -- painted texture generator (B172). Run in Blender:
#   exec(open(r"<repo>/tools/maps/lobby/textures.py").read())        (ONLY = {"gold", ...} to redo some)
# Same recipe as tools/maps/apolaki/textures.py: procedural numpy "paint" -- soft tileable value noise
# posterized into anime cel bands + painted details. Every texture is 1024x1024 and tiles (except the
# Mandala disc). Row 0 = top of the image (= +Z on walls with the kit's box UVs).
# Output: Downloads/Alamat_Lobby/tex/<name>.png + renders/tex_sheet.png (contact sheet).
import importlib.util
import math
import os
import sys

LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
_s = importlib.util.spec_from_file_location("al_common", os.path.join(LOBBY, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["al_common"] = C
_s.loader.exec_module(C)
np = C.np
S = 1024

GOLD_DEEP, GOLD, GOLD_HI = (168, 112, 32), (232, 186, 72), (255, 236, 160)
GOLD_RAMP = [(0.0, GOLD_DEEP), (0.3, (204, 150, 50)), (0.6, GOLD), (0.82, (246, 212, 118)), (1.0, GOLD_HI)]
TEAL_DARK, TEAL_LIGHT = (40, 150, 160), (110, 215, 210)


def uv01(n=S):
    """Pixel-centre coordinates 0..1 (u right, v DOWN -- row 0 = top)."""
    y, x = np.mgrid[0:n, 0:n]
    return (x + 0.5) / n, (y + 0.5) / n


def band(d, w0, w1, soft=1.2):
    """1 inside the distance band [w0, w1] (pixels), soft edges."""
    return C.smoothstep(w0 - soft, w0 + soft, d) * (1 - C.smoothstep(w1 - soft, w1 + soft, d))


# ------------------------------------------------------------------ marble family
def marble_paint(seed, veins=True):
    """Warm-white painted marble: big soft cel blotches, faint cool shadow tones, pale veins."""
    x, y = C.grid(S, S, 4)
    big = C.warped(x, y, 4, seed)
    x2, y2 = C.grid(S, S, 12)
    mid = C.warped(x2, y2, 12, seed + 1, warp=0.9, octaves=3)
    t = C.posterize(np.clip(0.72 * big + 0.28 * mid, 0, 1), 4, 0.7)
    col = C.ramp(t, [(0.0, (222, 220, 226)), (0.35, (234, 230, 224)), (0.7, (244, 238, 226)), (1.0, (251, 248, 240))])
    if veins:
        u, v = uv01()
        turb = C.fbm_xy(x, y, 4, 3, seed + 2, rotate=False)
        fade = C.smoothstep(0.3, 0.7, C.fbm_xy(x * 0.5, y * 0.5, 2, 2, seed + 3, rotate=False))
        # long soft pale-grey veins: a periodic (integer-frequency) diagonal sine bent by low-freq noise
        s1 = np.abs(np.sin(math.pi * (1 * u + 1 * v) + 3.0 * turb))
        halo = (1 - C.smoothstep(0.0, 0.32, s1)) * fade
        col = C.mix(col, col * C.rgb((228, 226, 232)) / C.rgb((244, 238, 226)), halo * 0.45)
        vein1 = (1 - C.smoothstep(0.0, 0.06, s1)) * fade
        col = C.mix(col, col * C.rgb((204, 204, 216)) / C.rgb((244, 238, 226)), vein1 * 0.6)
        # a few thin warm gold-grey veins the other way
        turb2 = C.fbm_xy(x + 3.1, y + 1.7, 4, 3, seed + 4, rotate=False)
        s2 = np.abs(np.sin(math.pi * (2 * u - 1 * v) + 3.2 * turb2))
        vein2 = (1 - C.smoothstep(0.0, 0.04, s2)) * (1 - fade)
        col = C.mix(col, C.rgb((222, 204, 168)) * np.ones_like(col), vein2 * 0.3)
    return col


def marble():
    C.save_png("marble", C.blur(marble_paint(401), 1))


def marble_block():
    """Marble ashlar: 4 courses x 2 studs per 8-stud tile, half-bond blocks 4 studs long,
    recessed joints with a lit top-left bevel and a soft shadow under each block."""
    col = marble_paint(411)
    u, v = uv01()
    courses, per_row = 4, 2
    ch, cw = S / courses, S / per_row
    cy = v * courses
    row = np.floor(cy).astype(int)
    fy = cy - row
    cx = u * per_row + 0.5 * (row % 2)
    bid = np.floor(cx).astype(int) % per_row
    fx = cx - np.floor(cx)
    d_top, d_bot = fy * ch, (1 - fy) * ch
    d_left, d_right = fx * cw, (1 - fx) * cw
    d = np.minimum(np.minimum(d_top, d_bot), np.minimum(d_left, d_right))
    # per-block tone (painted variation) + slightly lighter top of each block
    r = C.rng(412)
    tone = r.uniform(-0.035, 0.035, (courses, per_row))[row % courses, bid]
    shade = 1.0 + tone + 0.03 * (0.5 - fy)
    col = col * shade[..., None]
    jw = 5.0
    hl = np.maximum(band(d_top, jw, jw + 6), band(d_left, jw, jw + 5) * 0.7)
    sh = np.maximum(band(d_bot, jw, jw + 12), band(d_right, jw, jw + 7) * 0.6)
    col = C.mix(col, np.minimum(col * 1.06 + 0.03, 1), hl * 0.8)
    col = C.mix(col, col * C.rgb((214, 210, 214)) / C.rgb((244, 238, 226)), sh * 0.7)
    joint = 1 - C.smoothstep(jw - 1.5, jw + 0.5, d)
    jcol = C.rgb((176, 168, 168)) * np.ones_like(col)
    col = C.mix(col, jcol, joint)
    C.save_png("marble_block", C.blur(col, 1))


# ------------------------------------------------------------------ metals
def metal_bands(seed, stops, bands=2, glint_col=None, lo=0.0):
    """Stylized painted metal: smooth, gently waving horizontal cel bands (tile in v) -- a dark
    reflected band, a broad mid, one narrow bright highlight band -- plus a soft diagonal sheen."""
    u, v = uv01()
    x, y = C.grid(S, S, 2)
    w = C.fbm_xy(x, y, 2, 3, seed, rotate=False)
    x4, y4 = C.grid(S, S, 8)
    fine = C.fbm_xy(x4, y4, 8, 2, seed + 1, rotate=False)
    ph = 2 * math.pi * (bands * v) + 1.1 * (w - 0.5) * 2
    # skewed wave: long mid-tone stretches, a short bright crest, a short dark trough
    wave = 0.5 + 0.38 * np.sin(ph) + 0.12 * np.sin(2 * ph + 0.7)
    t = C.posterize(np.clip(0.92 * wave + 0.08 * fine, 0, 1), 5, 0.22)
    col = C.ramp(lo + (1 - lo) * t, stops)
    if glint_col is not None:
        g = 0.5 + 0.5 * np.sin(2 * math.pi * (1 * u + 1 * v) + 0.8 * w)
        col = C.mix(col, np.minimum(col * 1.12 + 0.04, 1), C.smoothstep(0.82, 0.9, g) * 0.6)
        crest = C.smoothstep(0.86, 0.9, wave) * C.smoothstep(0.9, 0.97, g)
        col = C.mix(col, C.rgb(glint_col) * np.ones_like(col), crest * 0.9)
    return col


def gold():
    # ONE band cycle per 4-stud tile: thin trims read as one smooth gold tone, big faces get a sweep
    col = metal_bands(421, GOLD_RAMP, bands=1, glint_col=(255, 250, 222), lo=0.2)
    # a few soft four-point sparkles -- the "holy" shimmer
    r = C.rng(422)
    yy, xx = np.mgrid[0:S, 0:S]
    spark = np.zeros((S, S))
    for _ in range(9):
        cx, cy, s = r.uniform(0, S), r.uniform(0, S), r.uniform(10, 18)
        dx = (xx - cx + S / 2) % S - S / 2
        dy = (yy - cy + S / 2) % S - S / 2
        star = np.exp(-(np.abs(dx) * np.abs(dy)) / (s * 1.2)) * np.exp(-np.hypot(dx, dy) / (s * 2.2))
        spark = np.maximum(spark, star)
    col = C.mix(col, C.rgb((255, 252, 230)) * np.ones_like(col), C.smoothstep(0.25, 0.7, spark) * 0.9)
    C.save_png("gold", C.blur(col, 1))


def bronze():
    stops = [(0.0, (54, 40, 28)), (0.35, (96, 72, 48)), (0.68, (130, 98, 60)), (0.88, (176, 136, 76)), (1.0, (212, 170, 96))]
    col = metal_bands(431, stops, bands=3, glint_col=(226, 186, 110))
    # soft hammered dents
    cov, tone = C.stamp_ellipses(S, S, 200, 14, 11, seed=432)
    col = C.mix(col, col * (0.9 + 0.22 * tone[..., None]), cov * 0.3)
    C.save_png("bronze", C.blur(col, 1))


# ------------------------------------------------------------------ roof tiles
def teal_tile():
    """Glazed turquoise fish-scale roof tiles: 6 columns x 8 rows per 6-stud tile, each upper row
    overlapping the one below, lighter glazed rims, crisp cel glints."""
    cols, rows = 6, 8
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float64)
    p, w = S / rows, S / cols
    arc = p * 0.6
    tone_tbl = C.rng(441).uniform(0, 1, (rows, cols))

    def geom(rr):
        cu = xx / w - 0.5 * (rr % 2)
        dx = (cu - np.floor(cu)) - 0.5
        cid = np.floor(cu).astype(int) % cols
        bottom = (rr + 1) * p - arc * (1 - np.sqrt(np.clip(1 - (2 * dx) ** 2, 0, 1)))
        return dx, cid, bottom

    c0 = np.floor(yy / p).astype(int)
    dx0, cid0, b0 = geom(c0)
    own = np.where(yy < b0, c0, c0 + 1)
    dx, cid, bottom = geom(own)
    _, _, top = geom(own - 1)
    hgt = np.maximum(bottom - top, 1.0)
    s = np.clip((yy - top) / hgt, 0, 1)  # 0 under the tile above .. 1 at this tile's rim
    dist_b = bottom - yy
    tone = tone_tbl[own % rows, cid]
    t = 0.12 + 0.5 * C.smoothstep(0.0, 0.5, s) + 0.18 * tone - 0.25 * dx
    t = t + 0.22 * (1 - C.smoothstep(10, 16, dist_b))  # glazed lighter rim
    t = C.posterize(np.clip(t, 0, 1), 4, 0.45)
    col = C.ramp(t, [(0.0, (24, 92, 112)), (0.3, TEAL_DARK), (0.6, (72, 186, 190)), (0.85, TEAL_LIGHT), (1.0, (168, 238, 230))])
    # crisp glaze glint high on the left of every tile
    g = np.exp(-(((dx + 0.2) / 0.11) ** 2 + ((s - 0.5) / 0.16) ** 2))
    col = C.mix(col, C.rgb((222, 252, 246)) * np.ones_like(col), C.smoothstep(0.5, 0.62, g) * 0.85)
    # dark outline where a rim sits on the tile below
    col = C.mix(col, col * 0.55, 1 - C.smoothstep(1.0, 3.0, dist_b))
    # faint painterly mottling in the glaze
    x, y = C.grid(S, S, 6)
    n = C.warped(x, y, 6, 442, octaves=3)
    col = col * (0.95 + 0.1 * n)[..., None]
    C.save_png("teal_tile", C.blur(col, 1))


# ------------------------------------------------------------------ plaza paving
def pave():
    """Pale cream flagstones: 4 courses of 2-stud slabs (2-4 studs long) per 8-stud tile, soft
    gold-grey grout, gentle edge bevels, a few faintly gold-grey slabs."""
    studs, rows = 8, 4
    layout = [((3, 2, 3), 0.0), ((2, 4, 2), 1.0), ((4, 2, 2), 2.5), ((3, 3, 2), 1.5)]
    u, v = uv01()
    ys = v * rows
    row = np.floor(ys).astype(int) % rows
    fy = ys - np.floor(ys)
    dl = np.zeros((S, S))
    dr = np.zeros((S, S))
    sid = np.zeros((S, S), dtype=int)
    for i, (widths, shift) in enumerate(layout):
        m = row == i
        xs = (u * studs - shift) % studs
        edges = np.concatenate([[0], np.cumsum(widths)]).astype(float)
        k = np.clip(np.searchsorted(edges, xs, side="right") - 1, 0, len(widths) - 1)
        dl = np.where(m, (xs - edges[k]) * S / studs, dl)
        dr = np.where(m, (edges[k + 1] - xs) * S / studs, dr)
        sid = np.where(m, i * 8 + k, sid)
    dt, db = fy * S / rows, (1 - fy) * S / rows
    d = np.minimum(np.minimum(dl, dr), np.minimum(dt, db))
    r = C.rng(451)
    palette = np.array([(240, 233, 216), (236, 228, 208), (244, 238, 224), (226, 216, 192), (232, 228, 220)]) / 255.0
    pick = r.choice(len(palette), 64, p=[0.3, 0.25, 0.25, 0.12, 0.08])
    base = palette[pick][sid]
    x, y = C.grid(S, S, 8)
    n = C.posterize(C.warped(x, y, 8, 452, octaves=4), 3, 0.7)
    col = base * (0.95 + 0.08 * n)[..., None]
    gw = 4.0
    hl = np.maximum(band(dt, gw, gw + 5), band(dl, gw, gw + 4) * 0.7)
    sh = np.maximum(band(db, gw, gw + 9), band(dr, gw, gw + 6) * 0.7)
    col = C.mix(col, np.minimum(col * 1.05 + 0.02, 1), hl * 0.8)
    col = C.mix(col, col * 0.9, sh * 0.7)
    ao = 1 - C.smoothstep(gw, gw + 26, d)
    col = col * (1 - 0.05 * ao)[..., None]
    grout = 1 - C.smoothstep(gw - 1.2, gw + 0.8, d)
    col = C.mix(col, C.rgb((198, 188, 166)) * np.ones_like(col), grout)
    C.save_png("pave", C.blur(col, 1))


# ------------------------------------------------------------------ glowing / translucent
def crystal():
    """Cyan-white faceted gem: tileable Voronoi facets with planar cel gradients, white edge glints."""
    u, v = uv01()
    r = C.rng(461)
    N = 22
    pts = r.random((N, 2))
    f1 = np.full((S, S), 9.0)
    f2 = np.full((S, S), 9.0)
    idx = np.zeros((S, S), dtype=int)
    for i, (px, py) in enumerate(pts):
        dx = np.abs(u - px)
        dx = np.minimum(dx, 1 - dx)
        dy = np.abs(v - py)
        dy = np.minimum(dy, 1 - dy)
        dd = np.hypot(dx, dy)
        closer = dd < f1
        f2 = np.where(closer, f1, np.minimum(f2, dd))
        idx = np.where(closer, i, idx)
        f1 = np.where(closer, dd, f1)
    ang = r.uniform(0, 2 * math.pi, N)
    base = r.uniform(0.25, 0.85, N)
    ox = (u - pts[idx, 0] + 0.5) % 1 - 0.5
    oy = (v - pts[idx, 1] + 0.5) % 1 - 0.5
    t = base[idx] + 3.2 * (ox * np.cos(ang[idx]) + oy * np.sin(ang[idx]))
    t = C.posterize(np.clip(t, 0, 1), 4, 0.4)
    col = C.ramp(t, [(0.0, (92, 182, 236)), (0.3, (128, 214, 250)), (0.55, (150, 230, 255)), (0.8, (206, 244, 255)), (1.0, (255, 255, 255))])
    edge = 1 - C.smoothstep(0.0025, 0.0055, f2 - f1)
    col = C.mix(col, np.ones_like(col), edge * 0.9)
    x, y = C.grid(S, S, 4)
    glow = C.warped(x, y, 4, 462, octaves=3)
    col = C.mix(col, np.ones_like(col), C.smoothstep(0.7, 0.9, glow) * 0.35)
    C.save_png("crystal", C.blur(col, 1))


def capiz():
    """Capiz-shell window: 4 x 4 pearly warm-white panes per 4-stud tile in a dark wood lattice
    with brass pegs at the crossings (Filipino capiz windows)."""
    n = 4
    cell = S / n
    bar = 15.0
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float64)
    gx, gy = (xx + 0.5) % cell, (yy + 0.5) % cell
    dxb = np.minimum(gx, cell - gx)  # distance to the nearest vertical bar centre
    dyb = np.minimum(gy, cell - gy)
    db = np.minimum(dxb, dyb)
    # pane
    half = cell / 2 - bar
    px, py = (gx - cell / 2) / half, (gy - cell / 2) / half
    rr = np.hypot(px, py)
    x, y = C.grid(S, S, 8)
    irid = C.warped(x, y, 8, 471, octaves=3)
    shell = 0.5 + 0.5 * np.sin(np.hypot(px + 1.1, py + 1.1) * 26 + 3 * irid)
    t = 0.62 + 0.3 * (1 - np.clip(rr, 0, 1.4) ** 2 / 2) + 0.05 * shell - 0.12 * (px + py) / 2
    t = C.posterize(np.clip(t, 0, 1), 4, 0.6)
    pane = C.ramp(t, [(0.0, (214, 204, 188)), (0.5, (240, 232, 214)), (0.8, (250, 244, 230)), (1.0, (255, 252, 244))])
    tint = C.ramp(irid, [(0.0, (252, 228, 232)), (0.5, (250, 242, 222)), (1.0, (226, 244, 250))])
    pane = C.mix(pane, pane * tint / C.rgb((250, 242, 222)), 0.6)
    # bar shadow falling on the top + left inside edge of each pane
    d_top = gy - bar
    d_left = gx - bar
    shadow = np.maximum(1 - C.smoothstep(0, 14, d_top), 0.6 * (1 - C.smoothstep(0, 10, d_left)))
    pane = C.mix(pane, pane * 0.82, np.clip(shadow, 0, 1) * (db > bar))
    # wood lattice: grain runs along each bar
    grain_h = C.stretch_noise(S, S, 64, 6, seed=472)
    grain_v = C.stretch_noise(S, S, 6, 64, seed=473)
    grain = np.where(dyb < dxb, grain_h, grain_v)
    wt = C.posterize(0.55 * grain + 0.45 * C.fbm(S, S, 16, 3, seed=474), 3, 0.5)
    wood = C.ramp(wt, [(0.0, (56, 34, 24)), (0.5, (76, 48, 32)), (1.0, (98, 64, 42))])
    side = np.where(dyb < dxb, (gy + bar) % cell, (gx + bar) % cell)  # 0 at the bar's top/left edge .. 2*bar
    wood = C.mix(wood, C.rgb((132, 92, 60)) * np.ones_like(wood), (1 - C.smoothstep(3.0, 6.0, side)) * 0.85)
    wood = C.mix(wood, wood * 0.6, C.smoothstep(2 * bar - 6, 2 * bar - 2.5, side) * 0.8)
    in_bar = 1 - C.smoothstep(bar - 1.0, bar + 0.8, db)
    col = C.mix(pane, wood, in_bar)
    # brass pegs at the crossings, lit from the top-left
    sgx, sgy = (gx + cell / 2) % cell - cell / 2, (gy + cell / 2) % cell - cell / 2  # signed, from the crossing
    pd = np.hypot(sgx, sgy)
    pegc = C.ramp(np.clip(1.0 - np.hypot(sgx + 3, sgy + 3) / 12, 0, 1), [(0, (150, 98, 34)), (0.6, (214, 166, 72)), (1, (244, 210, 120))])
    col = C.mix(col, pegc, 1 - C.smoothstep(7.5, 9.0, pd))
    col = C.mix(col, C.rgb((255, 246, 210)) * np.ones_like(col), (1 - C.smoothstep(1.2, 2.6, np.hypot(sgx + 3, sgy + 3))) * 0.8)
    C.save_png("capiz", C.blur(col, 1))


# ------------------------------------------------------------------ cloth
def cloth():
    """White cloth with soft vertical folds; a royal-blue + gold trim band along the BOTTOM edge
    (v = 1) with gold diamonds. Tiles in u."""
    u, v = uv01()
    x, y = C.grid(S, S, 4)
    w = C.fbm_xy(x, y, 4, 3, 481, rotate=False)
    folds = 0.6 * np.sin(2 * math.pi * 3 * u + 1.8 * w) + 0.4 * np.sin(2 * math.pi * 7 * u + 2.4 * w + 1.3)
    t = C.posterize(np.clip(0.55 + 0.45 * folds, 0, 1), 3, 0.65)
    col = C.ramp(t, [(0.0, (206, 210, 226)), (0.5, (236, 236, 242)), (1.0, (253, 251, 246))])
    weave = C.fbm_xy(x * 32, y * 32, 128, 1, 482, rotate=False)
    col = col * (0.985 + 0.03 * weave)[..., None]
    shade = (0.9 + 0.1 * (0.5 + 0.5 * folds))[..., None]
    blue = C.ramp(C.posterize(np.clip(0.5 + 0.4 * folds, 0, 1), 3, 0.6), [(0, (30, 58, 128)), (0.5, (44, 82, 166)), (1, (66, 110, 196))])
    goldc = C.ramp(C.posterize(np.clip(0.5 + 0.45 * folds, 0, 1), 3, 0.6), [(0, GOLD_DEEP), (0.5, GOLD), (1, GOLD_HI)])
    aa = 1.5 / S
    in_band = lambda a, b: C.smoothstep(a - aa, a + aa, v) * (1 - C.smoothstep(b - aa, b + aa, v))  # noqa: E731
    col = C.mix(col, goldc, in_band(0.815, 0.84))
    col = C.mix(col, blue, in_band(0.84, 0.955))
    col = C.mix(col, goldc, in_band(0.955, 0.982))
    col = C.mix(col, blue * 0.8, in_band(0.982, 1.01))
    # gold diamonds + dots along the blue band (16 per tile)
    k = 16
    du = ((u * k) % 1 - 0.5) / k
    dv = v - 0.8975
    dia = np.abs(du) / 0.022 + np.abs(dv) / 0.038
    col = C.mix(col, goldc, (1 - C.smoothstep(0.9, 1.0, dia)) * in_band(0.84, 0.955))
    dots = np.hypot(((u * k + 0.5) % 1 - 0.5) / k, dv) / 0.0065
    col = C.mix(col, goldc, (1 - C.smoothstep(0.8, 1.0, dots)))
    col = col * np.where(v[..., None] > 0.81, shade, 1.0)
    C.save_png("cloth", C.blur(col, 1))


# ------------------------------------------------------------------ mandala (non-tiling disc)
def _bez(p0, p1, p2, p3, n=10):
    t = np.linspace(0, 1, n)[:, None]
    p0, p1, p2, p3 = (np.array(p, dtype=float) for p in (p0, p1, p2, p3))
    return (1 - t) ** 3 * p0 + 3 * (1 - t) ** 2 * t * p1 + 3 * (1 - t) * t * t * p2 + t ** 3 * p3


# baybayin-like glyph strokes in a unit box (x right, y up); each = list of cubic beziers + dots
GLYPHS = [
    ([((-0.7, -0.55), (-0.6, 0.9), (0.0, 0.7), (0.05, -0.1)), ((0.05, -0.1), (0.1, 0.7), (0.7, 0.9), (0.7, -0.55))], [(0.0, 0.95)]),
    ([((-0.55, 0.7), (-0.75, -0.75), (0.55, -0.85), (0.6, 0.0)), ((0.6, 0.0), (0.62, 0.4), (0.15, 0.45), (0.1, 0.15))], []),
    ([((0.0, -0.7), (-1.0, -0.1), (-0.5, 0.95), (0.0, 0.25)), ((0.0, 0.25), (0.5, 0.95), (1.0, -0.1), (0.0, -0.7))], [(0.0, -0.98)]),
    ([((-0.8, 0.25), (-0.5, 0.95), (-0.1, 0.4), (0.0, 0.05)), ((0.0, 0.05), (0.15, 0.6), (0.6, 0.95), (0.75, 0.2)), ((0.75, 0.2), (0.85, -0.2), (0.6, -0.5), (0.4, -0.7))], []),
    ([((-0.8, -0.3), (-0.5, 0.9), (0.5, -0.9), (0.8, 0.3))], [(0.0, 0.92), (0.0, -0.92)]),
    ([((-0.1, 0.1), (-0.9, 0.7), (-0.9, -0.7), (-0.1, -0.2)), ((-0.1, -0.2), (0.3, 0.1), (0.5, 0.6), (0.8, 0.65))], [(0.55, -0.6)]),
]


def mandala():
    """Plaza inlay disc (NOT tiling, transparent outside): gold split-tone sun rays on cream around a
    gold sun, a turquoise ring, a ring of 24 baybayin-like gold glyphs, gold bands, cream lotus petals
    on turquoise, gold rim."""
    yy, xx = np.mgrid[0:S, 0:S].astype(np.float64)
    c = S / 2 - 0.5
    X, Y = xx - c, yy - c
    d = np.hypot(X, Y) / (S / 2)
    th = np.arctan2(Y, X)
    aa = 1.6 / (S / 2)

    def ring(a, b):
        return C.smoothstep(a - aa, a + aa, d) * (1 - C.smoothstep(b - aa, b + aa, d))

    cream = C.rgb((246, 238, 220))
    col = np.ones((S, S, 3)) * cream
    col = C.mix(col, C.rgb((255, 248, 230)) * np.ones_like(col), 1 - C.smoothstep(0.1, 0.5, d))
    gdeep, gmid, glight, ghi = C.rgb(GOLD_DEEP), C.rgb((210, 156, 54)), C.rgb((246, 212, 118)), C.rgb(GOLD_HI)
    teal_d, teal_l = C.rgb(TEAL_DARK), C.rgb(TEAL_LIGHT)

    def paint(mask, color):
        nonlocal col
        col = C.mix(col, np.ones_like(col) * color if np.ndim(color) == 1 else color, np.clip(mask, 0, 1))

    # --- sun rays (32: long / short alternating), split-tone with a deep-gold outline
    nr = 32
    for long_pass in (False, True):
        for k in range(nr):
            is_long = (k % 2 == 0)
            if is_long != long_pass:
                continue
            phi = 2 * math.pi * k / nr
            along = (X * math.cos(phi) + Y * math.sin(phi)) / (S / 2)
            across = (-X * math.sin(phi) + Y * math.cos(phi)) / (S / 2)
            d0, d1 = 0.12, (0.475 if is_long else 0.38)
            hw0 = 0.05 if is_long else 0.032
            hw = hw0 * np.clip((d1 - along) / (d1 - d0), 0, 1)
            inside = (along > d0 - 0.02) & (along < d1)
            e = (hw - np.abs(across)) * (S / 2)  # px inside the edge
            m = C.smoothstep(-1.0, 1.0, e) * inside
            fill = np.where((across > 0)[..., None], glight, gmid)
            paint(m, gdeep)
            paint(C.smoothstep(1.5, 3.5, e) * inside * (along < d1 - 0.012), fill)
    # --- central sun: radial gold, deep ring, 8-point star, white-gold heart
    paint(1 - C.smoothstep(0.135 - aa, 0.135 + aa, d), gdeep)
    sun = C.ramp(C.posterize(np.clip(1 - d / 0.13, 0, 1), 3, 0.5), [(0, GOLD), (0.6, (248, 214, 120)), (1, GOLD_HI)])
    paint(1 - C.smoothstep(0.122 - aa, 0.122 + aa, d), sun)
    star = d / 0.1 < 0.45 + 0.55 * (0.5 + 0.5 * np.cos(th * 8)) ** 6
    paint(ring(0.0, 0.1) * star, ghi)
    paint(1 - C.smoothstep(0.035 - aa, 0.035 + aa, d), C.rgb((255, 252, 236)))
    # --- turquoise ring with gold borders and cream diamonds
    paint(ring(0.485, 0.62), gdeep)
    paint(ring(0.493, 0.612), C.rgb(GOLD))
    tr = C.ramp(C.posterize(np.clip((d - 0.5) / 0.1, 0, 1), 2, 0.4), [(0, teal_d * 255), (1, teal_l * 255)])
    paint(ring(0.502, 0.603), tr)
    nd = 40
    a_loc = ((th / (2 * math.pi) * nd) % 1 - 0.5) * (2 * math.pi / nd) * d
    dia = np.abs(a_loc) / 0.014 + np.abs(d - 0.5525) / 0.03
    paint((1 - C.smoothstep(0.85, 1.0, dia)), C.rgb((250, 244, 228)))
    # --- glyph band: cream between gold rules, 24 glyphs reading outward + gold dot separators
    paint(ring(0.632, 0.645), C.rgb(GOLD))
    paint(ring(0.795, 0.808), C.rgb(GOLD))
    ng, R, size = 24, 0.72, 0.062
    rr = C.rng(491)
    order = rr.permutation(np.arange(ng) % len(GLYPHS))
    for k in range(ng):
        phi = 2 * math.pi * k / ng
        cxp, cyp = c + R * (S / 2) * math.cos(phi), c + R * (S / 2) * math.sin(phi)
        half = int(size * (S / 2) * 1.6) + 4
        x0, x1 = int(cxp) - half, int(cxp) + half
        y0, y1 = int(cyp) - half, int(cyp) + half
        sx, sy = xx[y0:y1, x0:x1] - cxp, yy[y0:y1, x0:x1] - cyp
        # glyph frame: up = radial outward, right = (-sin, cos)
        gx = (sx * -math.sin(phi) + sy * math.cos(phi)) / (size * S / 2)
        gy = (sx * math.cos(phi) + sy * math.sin(phi)) / (size * S / 2)
        curves, dots = GLYPHS[order[k]]
        dist = np.full(gx.shape, 9.0)
        for cv in curves:
            pts = _bez(*cv, n=14)
            for a, b in zip(pts[:-1], pts[1:]):
                ab = b - a
                tt = np.clip(((gx - a[0]) * ab[0] + (gy - a[1]) * ab[1]) / max(ab @ ab, 1e-9), 0, 1)
                dist = np.minimum(dist, np.hypot(gx - a[0] - tt * ab[0], gy - a[1] - tt * ab[1]))
        for p in dots:
            dist = np.minimum(dist, np.hypot(gx - p[0], gy - p[1]) - 0.06)
        px_d = dist * size * S / 2  # pixels from the stroke centre line
        sub = col[y0:y1, x0:x1]
        sub = C.mix(sub, np.ones_like(sub) * gdeep, 1 - C.smoothstep(6.0, 7.5, px_d))
        sub = C.mix(sub, np.ones_like(sub) * C.rgb((226, 170, 60)), 1 - C.smoothstep(3.5, 5.0, px_d))
        col[y0:y1, x0:x1] = sub
        # separator dot between glyphs
        phs = phi + math.pi / ng
        dd = np.hypot(X - R * (S / 2) * math.cos(phs), Y - R * (S / 2) * math.sin(phs))
        paint(1 - C.smoothstep(4.0, 5.5, dd), C.rgb(GOLD))
    # --- gold band, then cream lotus petals on turquoise, then the rim
    paint(ring(0.815, 0.86), gdeep)
    paint(ring(0.822, 0.853), C.ramp(C.posterize(np.clip((d - 0.822) / 0.031, 0, 1), 2, 0.4), [(0, GOLD), (1, GOLD_HI)]))
    paint(ring(0.86, 0.965), teal_d)
    npet = 36
    a = ((th / (2 * math.pi) * npet) % 1 - 0.5) * 2  # -1..1 across each petal
    tip = 0.86 + 0.1 * (1 - np.abs(a) ** 1.6)
    e = (tip - d) * (S / 2)
    petal = C.smoothstep(-1.0, 1.0, e) * (d > 0.855)
    paint(petal, C.rgb(GOLD))
    pfill = C.ramp(C.posterize(np.clip(0.5 + 0.6 * a, 0, 1), 2, 0.4), [(0, (236, 226, 204)), (1, (252, 248, 236))])
    paint(C.smoothstep(1.5, 3.5, e) * (d > 0.866), pfill)
    paint(ring(0.966, 1.0), gdeep)
    paint(ring(0.972, 0.992), C.ramp(np.clip((d - 0.972) / 0.02, 0, 1), [(0, GOLD), (1, GOLD_HI)]))
    alpha = 1 - C.smoothstep(1.0 - aa, 1.0, d)
    C.save_png("mandala", col, alpha)


# ------------------------------------------------------------------ contact sheet
def contact_sheet(names):
    """renders/tex_sheet.png: every texture at 256 px (mandala over a dark tile to show its alpha)."""
    import bpy
    tiles = []
    for nm in names:
        img = bpy.data.images.load(os.path.join(C.TEX, nm + ".png"), check_existing=False)
        w, h = img.size
        px = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        px = px.reshape(h, w, 4)[::-1]
        bpy.data.images.remove(img)
        small = px.reshape(256, h // 256, 256, w // 256, 4).mean(axis=(1, 3))
        bg = np.ones((256, 256, 3)) * np.array([0.16, 0.2, 0.26])
        tiles.append(small[..., :3] * small[..., 3:] + bg * (1 - small[..., 3:]))
    cols = 5
    rows = (len(tiles) + cols - 1) // cols
    sheet = np.ones((rows * 260, cols * 260, 3)) * 0.1
    for i, t in enumerate(tiles):
        r0, c0 = (i // cols) * 260 + 2, (i % cols) * 260 + 2
        sheet[r0:r0 + 256, c0:c0 + 256] = t
    h, w = sheet.shape[:2]
    img = bpy.data.images.new("_tex_sheet", w, h, alpha=False)
    img.pixels.foreach_set(np.dstack([sheet, np.ones((h, w))])[::-1].astype(np.float32).ravel())
    img.filepath_raw = os.path.join(C.RENDERS, "tex_sheet.png")
    img.file_format = "PNG"
    img.save()
    bpy.data.images.remove(img)
    return os.path.join(C.RENDERS, "tex_sheet.png")


ALL = (marble, marble_block, gold, teal_tile, pave, crystal, capiz, cloth, bronze, mandala)


def run_all(only=None):
    done = []
    for f in ALL:
        if only and f.__name__ not in only:
            continue
        f()
        done.append(f.__name__)
    return done


_done = run_all(globals().get("ONLY"))
result = {"textures": _done, "dir": C.TEX,
          "missing": [f.__name__ for f in ALL if not os.path.exists(os.path.join(C.TEX, f.__name__ + ".png"))],
          "sheet": contact_sheet([f.__name__ for f in ALL])}
