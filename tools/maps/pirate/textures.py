# Bakunawa Cove -- painted texture generator (B173). Same recipe as tools/maps/apolaki/textures.py: procedural
# numpy "paint" (soft value noise posterized into cel bands + stamped strokes). Row 0 = top of the image.
# Run: blender.exe -b <BLEND> --python-expr "exec(open(r'<this>').read())"   (ONLY = {"sand", ...} to redo some)
# Output: Downloads/BakunawaCove_Map/tex/<name>.png
import importlib.util
import math
import os
import sys

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)
np = C.np
os.makedirs(C.TEX, exist_ok=True)


def warped(x, y, period, seed, warp=1.4, octaves=5):
    return C.warped(x, y, period, seed, warp, octaves)


def uv01(h, w):
    y, x = np.mgrid[0:h, 0:w]
    return (x + 0.5) / w, (y + 0.5) / h


def solid(h, w, c):
    return np.zeros((h, w, 3)) + np.array(c) / 255.0


# ------------------------------------------------------------------ ground
# ------------------------------------------------------------------ ground
# B173 user: "make it look like this" (an Anime-Vanguards-style map): SMOOTH hand-painted surfaces -- big soft
# low-contrast colour pools, gentle gradients, no busy noise or hard cel blotches. Fine detail comes from 3D
# geometry (grass clumps, bushes, flowers, cobbles), never from texture noise.
def soft(x, y, period, seed, warp=1.0):
    """Low-frequency, very smooth 0..1 field (3 octaves, domain-warped)."""
    return C.warped(x, y, period, seed, warp, 3)


def painted(t, stops, levels=0):
    """Ramp a smooth field; levels > 0 adds VERY soft bands (painterly, not cel)."""
    if levels:
        t = C.posterize(t, levels, 0.95)
    return C.ramp(t, stops)


def grass():
    S = 1024
    x, y = C.grid(S, S, 3)
    big = soft(x, y, 3, 11)
    x2, y2 = C.grid(S, S, 8)
    mid = soft(x2, y2, 8, 12, 0.6)
    t = np.clip(0.75 * big + 0.25 * mid, 0, 1)
    col = painted(t, [(0.0, (70, 132, 60)), (0.4, (82, 146, 64)), (0.75, (98, 160, 70)), (1.0, (116, 172, 78))])
    # a few broad soft brush strokes (lighter), barely there
    cov, _ = C.stamp_ellipses(S, S, 90, 60, 18, seed=15, angle_jitter=0.5)
    col = C.mix(col, np.minimum(col * 1.08 + 0.015, 1), C.blur(cov, 6) * 0.35)
    C.save_png("grass", C.blur(col, 3))


def sand():
    S = 1024
    x, y = C.grid(S, S, 3)
    big = soft(x, y, 3, 21)
    x2, y2 = C.grid(S, S, 10)
    mid = soft(x2, y2, 10, 22, 0.6)
    t = np.clip(0.75 * big + 0.25 * mid, 0, 1)
    col = painted(t, [(0, (214, 182, 132)), (0.5, (232, 204, 154)), (1, (246, 224, 180))])
    cov, _ = C.stamp_ellipses(S, S, 70, 70, 14, seed=24, angle_jitter=0.3)  # soft wind sweeps
    col = C.mix(col, np.minimum(col * 1.05 + 0.02, 1), C.blur(cov, 6) * 0.4)
    C.save_png("sand", C.blur(col, 3))


def cliff():
    """Painted rock wall: v = 0 top (green lip) -> 1 = 24 studs down. Warm terracotta-brown slabs with soft vertical
    light falloff, a few dark crack strokes, a clean green cap that drips a little."""
    W, H = 1024, 1024
    x, y = C.grid(H, W, 4)
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    big = soft(x, y, 4, 33)
    # wide flat facets: quantized + heavily blurred so they read as painted planes
    facets = C.blur(C.posterize(soft(x * 1.5, y * 0.8, 6, 34), 4, 0.2), 10)
    t = np.clip(0.55 * facets + 0.3 * big + 0.25 * (1 - v), 0, 1)
    col = painted(t, [(0.0, (118, 66, 54)), (0.35, (156, 92, 66)), (0.7, (192, 124, 86)), (1.0, (222, 160, 112))])
    col = col * (1.04 - 0.22 * v)[..., None]
    # sparse dark crack strokes (soft)
    cov, _ = C.stamp_ellipses(H, W, 40, 60, 3, seed=35, angle_jitter=0.35)
    col = C.mix(col, col * 0.62, C.blur(cov, 2) * 0.6)
    # green cap with soft drips (tileable along U)
    drip = C.fbm_xy(np.linspace(0, 16, W), np.zeros(W), 16, 2, 36, rotate=False)[None, :]
    lip = 0.07 + 0.12 * drip ** 2
    moss = 1 - C.smoothstep(lip, lip + 0.025, v)
    mossc = painted(soft(x * 2, y * 2, 8, 37), [(0, (66, 128, 60)), (1, (112, 168, 74))])
    col = C.mix(col, mossc, moss)
    rim = np.exp(-((v - lip - 0.03) ** 2) / 0.0003)  # dark contact shadow under the cap
    col = col * (1 - 0.25 * rim[..., None])
    C.save_png("cliff", C.blur(col, 2))


def rock():
    S = 512
    x, y = C.grid(S, S, 3)
    facets = C.blur(C.posterize(soft(x, y, 3, 41), 4, 0.2), 8)
    t = np.clip(0.7 * facets + 0.3 * soft(x * 2, y * 2, 6, 42), 0, 1)
    col = painted(t, [(0, (112, 106, 104)), (0.5, (150, 142, 134)), (1, (190, 182, 166))])
    cov, _ = C.stamp_ellipses(S, S, 30, 40, 2.5, seed=44, angle_jitter=0.6)  # a few painted cracks
    col = C.mix(col, col * 0.6, C.blur(cov, 1) * 0.5)
    moss = C.smoothstep(0.72, 0.85, soft(x * 1.5, y * 1.5, 5, 43))
    col = C.mix(col, np.array([96, 150, 70]) / 255.0 * np.ones_like(col), moss * 0.3)
    C.save_png("rock", C.blur(col, 2))


def cobbles(S, n, seed, stops, mortar, jitter=0.8):
    """Tileable rounded cobblestones (jittered-grid Voronoi), soft-shaded tops, warm mortar."""
    r = C.rng(seed)
    pts = (np.stack(np.meshgrid(np.arange(n), np.arange(n)), -1).reshape(-1, 2) + 0.5
           + (r.random((n * n, 2)) - 0.5) * jitter) / n
    tone = r.random(n * n)
    u, v = uv01(S, S)
    d1 = np.full((S, S), 9.0)
    d2 = np.full((S, S), 9.0)
    idx = np.zeros((S, S), int)
    for ox in (-1, 0, 1):
        for oy in (-1, 0, 1):
            for i, (px, py) in enumerate(pts):
                d = np.hypot(u - px - ox, v - py - oy)
                closer = d < d1
                d2 = np.where(closer, d1, np.minimum(d2, d))
                idx = np.where(closer, i, idx)
                d1 = np.where(closer, d, d1)
    edge = (d2 - d1) * n  # 0 at the joint
    stone = C.smoothstep(0.06, 0.2, edge)
    dome = np.clip(edge * 1.6, 0, 1) ** 0.5
    t = np.clip(0.55 * tone[idx] + 0.45 * dome, 0, 1)
    col = painted(t, stops)
    col = C.mix(np.ones_like(col) * (np.array(mortar) / 255.0), col, stone)
    return col


def path():
    """Cobbled path tread (the reference map's paving): U across, V along (1 tile = 9 studs)."""
    col = cobbles(512, 7, 51, [(0, (150, 104, 96)), (0.5, (184, 132, 116)), (1, (214, 166, 144))], (104, 72, 66))
    C.save_png("path", C.blur(col, 1))


def curb():
    """Rounded path curb: red / cream diagonal candy stripes (pirate rope-paint), U along (1 tile = 4 studs)."""
    S = 256
    u, v = uv01(S, S)
    s = ((u * 2 + v * 0.6) % 1) < 0.5
    col = np.where(s[..., None], np.array([206, 58, 58]) / 255.0, np.array([246, 236, 222]) / 255.0) * np.ones((S, S, 3))
    shade = 0.82 + 0.18 * np.sin(v * math.pi)  # round tube shading across
    col = col * shade[..., None]
    C.save_png("curb", C.blur(col, 1))



def street():
    """Village design paths (NOT the enemy path): packed warm earth with a few flat stones, a darker worn centre and
    a ragged ALPHA edge so the ribbon reads as ground painted into the grass. U across (0..1), V along (8 studs)."""
    S = 512
    u, v = uv01(S, S)
    x, y = C.grid(S, S, 4)
    t = np.clip(0.7 * soft(x, y, 4, 241) + 0.3 * soft(x * 3, y * 3, 12, 242, 0.6), 0, 1)
    col = painted(t, [(0, (150, 112, 74)), (0.5, (178, 138, 94)), (1, (204, 166, 118))])
    col = col * (1 - 0.1 * np.exp(-((u - 0.5) ** 2) / 0.02))[..., None]  # worn centre
    cov, tone = C.stamp_ellipses(S, S, 70, 14, 10, seed=243)  # flat stepping stones
    col = C.mix(col, painted(tone, [(0, (150, 140, 128)), (1, (206, 196, 178))]), C.smoothstep(0.4, 0.6, cov) * 0.85)
    edge = np.minimum(u, 1 - u)
    rag = 0.1 + 0.07 * C.fbm_xy(np.zeros_like(v) + (u > 0.5) * 7.0, v * 8.0, 8, 3, 244, rotate=False)
    alpha = (edge > rag).astype(float)
    fringe = 1 - C.smoothstep(rag, rag + 0.06, edge)
    col = C.mix(col, col * np.array([0.78, 0.86, 0.62]), fringe * 0.7)  # grassy dark fringe
    C.save_png("street", C.blur(col, 1), alpha)


def plaza():
    """Village plaza paving: big pale sandstone cobbles (tiles every 12 studs) -- distinct from the pink enemy path."""
    col = cobbles(512, 6, 251, [(0, (176, 160, 132)), (0.5, (204, 188, 156)), (1, (228, 214, 184))], (120, 104, 84))
    C.save_png("plaza", C.blur(col, 1))


def canvas():
    """Off-white sailcloth for tents + laundry: soft folds, faint seams (tiles every 6 studs)."""
    S = 512
    u, v = uv01(S, S)
    x, y = C.grid(S, S, 4)
    t = np.clip(0.6 * soft(x, y, 4, 261) + 0.4 * (0.5 + 0.5 * np.sin(u * math.pi * 8 + 2 * soft(x, y, 4, 262))), 0, 1)
    col = painted(t, [(0, (196, 184, 160)), (0.5, (222, 212, 190)), (1, (240, 234, 218))])
    seam = (np.abs((u * 3) % 1 - 0.5) > 0.49)
    col = np.where(seam[..., None], col * 0.82, col)
    C.save_png("canvas", C.blur(col, 1))

def sea():
    """Sea gradient: U tiles (x / 48 studs), V = 0 at the shore (foam) -> 1 deep water (~150 studs out)."""
    W, H = 512, 1024
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    x, y = C.grid(H, W, 6, 12)
    n = warped(x, y, 6, 61, warp=1.0, octaves=4)
    depth = np.clip(v + 0.12 * (n - 0.5), 0, 1)
    t = C.posterize(depth, 6, 0.6)
    col = C.ramp(t, [(0, (150, 236, 220)), (0.12, (84, 214, 206)), (0.35, (36, 182, 196)), (0.6, (20, 126, 170)),
                     (1, (16, 78, 138))])
    # foam at the shore (wavy) + one faint outer line
    wav = C.fbm_xy(x * 2, np.zeros_like(x), 12, 3, 63, rotate=False)
    for f0, w, k in ((0.0, 0.03, 0.9), (0.06, 0.008, 0.35)):
        line = 1 - C.smoothstep(w * 0.5, w, np.abs(v - f0 - 0.02 * (wav - 0.5)))
        col = C.mix(col, np.ones_like(col) * 0.98, line * k)
    C.save_png("sea", col)


def falls():
    W, H = 256, 512
    x, y = C.grid(H, W, 4, 1)
    streak = C.fbm_xy(x * 8, y * 0.5, 32, 3, 71, rotate=False)
    t = C.posterize(streak, 4, 0.5)
    col = C.ramp(t, [(0, (90, 190, 210)), (0.5, (170, 230, 236)), (1, (250, 255, 255))])
    a = 0.7 + 0.3 * C.smoothstep(0.3, 0.8, streak)
    C.save_png("falls", col, a)


# ------------------------------------------------------------------ wood + building
def plank():
    """Weathered deck planks: boards run along U (6 boards per tile), dark seams, nail dots."""
    S = 512
    u, v = uv01(S, S)
    boards = 6
    k = np.floor(v * boards)
    r = C.rng(81)
    offs = r.random(boards + 1)
    grain = C.stretch_noise(S, S, 60, 4, seed=82)  # streaks along U
    tone = offs[k.astype(int)][..., None]
    t = C.posterize(np.clip(0.55 * grain + 0.45 * offs[k.astype(int)], 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (118, 80, 50)), (0.5, (160, 114, 72)), (1, (198, 152, 100))])
    col = col * (0.92 + 0.12 * tone)
    seam = np.abs((v * boards) % 1 - 0.0) < 0.035
    seam |= np.abs((v * boards) % 1 - 1.0) < 0.035
    # board ends staggered
    endu = (u + offs[k.astype(int)]) % 0.5
    seam |= endu < 0.008
    col = np.where(seam[..., None], col * 0.45, col)
    nail = (np.abs(endu - 0.03) < 0.006) & (np.abs((v * boards) % 1 - 0.5) < 0.12)
    col = np.where(nail[..., None], col * 0.4, col)
    C.save_png("plank", C.blur(col, 1))


def wood_dark():
    S = 512
    grain = C.stretch_noise(S, S, 5, 70, seed=91)
    t = C.posterize(0.65 * grain + 0.35 * C.fbm(S, S, 8, 3, seed=92), 4, 0.5)
    col = C.ramp(t, [(0, (54, 34, 28)), (0.5, (86, 56, 40)), (1, (124, 84, 56))])
    C.save_png("wood_dark", col)


def thatch():
    S = 512
    y = np.linspace(0, 1, S)[:, None].repeat(S, 1)
    rows = (y * 6) % 1
    strands = C.stretch_noise(S, S, 8, 180, seed=101)
    t = C.posterize(np.clip(0.55 * strands + 0.45 * (1 - rows), 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (120, 84, 44)), (0.5, (186, 142, 76)), (1, (230, 196, 120))])
    C.save_png("thatch", col)


def shingle():
    """Wooden shingles (rows of rounded-bottom tiles) -- fortress + tall-house roofs, terracotta-brown."""
    S = 512
    u, v = uv01(S, S)
    rows = 8
    k = np.floor(v * rows)
    fu = (u * 8 + 0.5 * (k % 2)) % 1
    fv = (v * rows) % 1
    shape = fv + 0.25 * (2 * np.abs(fu - 0.5)) ** 2
    t = C.posterize(np.clip(0.3 + 0.7 * fv + 0.15 * (C.fbm(S, S, 16, 3, seed=111) - 0.5), 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (92, 40, 30)), (0.5, (150, 70, 44)), (1, (196, 112, 70))])
    gap = (np.abs(fu - 0.5) > 0.47) | (shape > 1.12)
    col = np.where(gap[..., None], col * 0.45, col)
    C.save_png("shingle", C.blur(col, 1))


def stone():
    """Fortress ashlar: block courses (4 per tile), pale warm grey, mossy joints."""
    S = 512
    r = C.rng(121)
    u, v = uv01(S, S)
    courses = 4
    k = np.floor(v * courses).astype(int)
    off = r.random(courses + 1)
    fu = (u * 3 + off[k]) % 1
    fv = (v * courses) % 1
    n = C.fbm(S, S, 8, 3, seed=122)
    blockid = np.floor(u * 3 + off[k]).astype(int) * 7 + k * 3
    tone = (np.sin(blockid * 12.9898) * 43758.5453) % 1
    t = C.posterize(np.clip(0.45 + 0.3 * (tone - 0.5) + 0.4 * (n - 0.5) + 0.2 * (0.5 - fv), 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (118, 112, 106)), (0.5, (164, 156, 140)), (1, (206, 198, 176))])
    joint = (np.minimum(fu, 1 - fu) < 0.025) | (np.minimum(fv, 1 - fv) < 0.035)
    col = np.where(joint[..., None], col * 0.5, col)
    x, y = C.grid(S, S, 6)
    moss = C.smoothstep(0.66, 0.8, warped(x, y, 6, 123))
    col = C.mix(col, np.array([90, 140, 66]) / 255.0 * np.ones_like(col), moss * 0.4)
    C.save_png("stone", C.blur(col, 1))


def _stripes(name, c1, c2):
    S = 512
    u, v = uv01(S, S)
    st = (np.floor(u * 4) % 2)[..., None]
    n = C.fbm(S, S, 8, 3, seed=131)
    col = solid(S, S, c1) * (1 - st) + solid(S, S, c2) * st
    col = col * (0.9 + 0.12 * n[..., None])
    C.save_png(name, col)


def awnings():
    _stripes("awning_red", (204, 52, 44), (246, 236, 214))
    _stripes("awning_teal", (36, 150, 140), (246, 236, 214))


def _jolly(S, bg, fg, skull_r):
    """Black cloth with a skull and crossbones in the centre (non-tiling, 0..1)."""
    u, v = uv01(S, S)
    n = C.fbm(S, S, 6, 3, seed=141)
    col = solid(S, S, bg) * (0.85 + 0.25 * n[..., None])
    x, y = (u - 0.5) * 2, (v - 0.47) * 2  # v down
    mask = np.zeros((S, S), bool)
    for sgn in (-1, 1):  # crossed bones
        ca, sa = math.cos(sgn * 0.75), math.sin(sgn * 0.75)
        bu, bv = x * ca + y * sa, -x * sa + (y - skull_r * 0.9) * ca
        mask |= (np.abs(bu) < skull_r * 1.6) & (np.abs(bv) < skull_r * 0.12)
        for e in (-1, 1):
            for side in (-1, 1):
                mask |= np.hypot(bu - e * skull_r * 1.6, bv - side * skull_r * 0.12) < skull_r * 0.16
    cran = np.hypot(x / 1.0, (y + skull_r * 0.15) / 0.95) < skull_r
    jaw = (np.abs(x) < skull_r * 0.55) & (y > 0) & (y < skull_r * 1.05)
    mask |= cran | jaw
    holes = np.zeros((S, S), bool)
    for e in (-1, 1):
        holes |= np.hypot(x - e * skull_r * 0.38, y + skull_r * 0.05) < skull_r * 0.24
    holes |= (np.abs(x) < skull_r * 0.08) & (y > skull_r * 0.3) & (y < skull_r * 0.5)
    teeth = (y > skull_r * 0.72) & (y < skull_r * 1.0) & ((np.floor((x + 1) / (skull_r * 0.18)) % 2) == 0) & (
        np.abs(x) < skull_r * 0.5)
    holes |= teeth & ((np.abs(x / (skull_r * 0.18)) % 1) < 0.15)
    fgcol = solid(S, S, fg) * (0.92 + 0.1 * n[..., None])
    col = np.where((mask & ~holes)[..., None], fgcol, col)
    return col


def sail():
    S = 1024
    col = _jolly(S, (40, 36, 40), (236, 230, 214), 0.34)
    u, v = uv01(S, S)
    seam = (np.abs((u * 5) % 1) < 0.01) * 0.25
    col = col * (1 - seam[..., None])
    C.save_png("sail", col)


def flag():
    C.save_png("flag", _jolly(512, (28, 26, 30), (240, 236, 224), 0.36))


def gold():
    S = 512
    x, y = C.grid(S, S, 6)
    n = warped(x, y, 6, 151)
    t = C.posterize(n, 5, 0.4)
    col = C.ramp(t, [(0, (156, 100, 26)), (0.4, (212, 154, 44)), (0.7, (244, 202, 82)), (1, (255, 244, 170))])
    C.save_png("gold", col)


def iron():
    S = 256
    t = C.posterize(C.fbm(S, S, 6, 3, seed=161), 4, 0.5)
    col = C.ramp(t, [(0, (40, 40, 46)), (0.6, (70, 68, 72)), (1, (110, 100, 92))])
    C.save_png("iron", col)


def rope():
    S = 256
    u, v = uv01(S, S)
    tw = (u * 4 + v * 4) % 1
    t = C.posterize(0.6 + 0.4 * np.sin(tw * math.pi), 3, 0.5)
    col = C.ramp(t, [(0, (126, 96, 56)), (1, (214, 182, 124))])
    C.save_png("rope", col)


def bone():
    S = 512
    x, y = C.grid(S, S, 5)
    t = C.posterize(warped(x, y, 5, 171), 4, 0.5)
    col = C.ramp(t, [(0, (186, 172, 146)), (0.5, (222, 212, 188)), (1, (246, 240, 222))])
    crack = C.smoothstep(0.03, 0.0, np.abs(C.fbm_xy(x * 2, y * 2, 10, 3, 172, rotate=False) - 0.5))
    col = C.mix(col, col * 0.6, crack * 0.6)
    C.save_png("bone", C.blur(col, 1))


def lamp():
    S = 128
    u, v = uv01(S, S)
    d = np.hypot(u - 0.5, v - 0.5) * 2
    col = C.ramp(np.clip(1 - d, 0, 1), [(0, (255, 150, 50)), (1, (255, 236, 170))])
    C.save_png("lamp", col)


# ------------------------------------------------------------------ foliage
def palm_bark():
    """Palm trunk rings: U around, V along (1 tile = ~3 studs: one ring band)."""
    W, H = 256, 256
    u, v = uv01(H, W)
    ring = (v * 2) % 1
    n = C.stretch_noise(H, W, 4, 24, seed=181)
    t = C.posterize(np.clip(0.25 + 0.6 * ring + 0.25 * (n - 0.5), 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (82, 58, 40)), (0.5, (138, 104, 70)), (1, (190, 156, 108))])
    C.save_png("palm_bark", col)


def frond():
    """One palm frond card: rib top -> bottom, leaflets both sides (alpha)."""
    S = 512
    rgb = np.zeros((S, S, 3))
    a = np.zeros((S, S))
    yy, xx = np.mgrid[0:S, 0:S]
    cx = S / 2
    for k in range(44):
        y0 = 18 + k * 11
        length = 150 * math.sin(math.pi * (k + 3) / 50) + 30
        ang = math.radians(32)
        for s in (-1, 1):
            dx = (xx - cx) * s
            dy = yy - y0
            uu = dx * math.cos(ang) + dy * math.sin(ang)
            vv = -dx * math.sin(ang) + dy * math.cos(ang)
            m = (uu > 0) & (uu < length) & (np.abs(vv) < 8 * (1 - uu / max(length, 1)) + 1.5)
            a = np.maximum(a, m.astype(float))
            shade = np.clip(0.35 + 0.65 * (uu / max(length, 1)), 0, 1)
            rgb = np.where(m[..., None], C.ramp(shade, [(0, (30, 92, 40)), (0.6, (66, 140, 56)), (1, (128, 182, 74))]), rgb)
    rib = np.abs(xx - cx) < 3.5
    a = np.maximum(a, rib.astype(float))
    rgb = np.where(rib[..., None], np.array([150, 170, 80]) / 255.0, rgb)
    C.save_png("frond", rgb, a)


def leaves():
    """2x2 atlas of tropical leaf clusters (dark -> sunlit), alpha cutout -- bushes."""
    S = 1024
    rgb = np.zeros((S, S, 3))
    a = np.zeros((S, S))
    tones = [((28, 92, 44), (54, 132, 54)), ((44, 120, 50), (82, 162, 60)), ((70, 150, 56), (124, 192, 70)),
             ((110, 180, 66), (176, 220, 96))]
    for i, (c0, c1) in enumerate(tones):
        h = S // 2
        cov, tone = C.stamp_ellipses(h, h, 220, 44, 17, seed=191 + i, wrap=False)
        yy, xx = np.mgrid[0:h, 0:h]
        rr = np.hypot(xx - h / 2, yy - h / 2) / (h / 2)
        cov = cov * (rr < 0.92)
        col = C.ramp(C.posterize(tone, 3, 0.5), [(0, c0), (1, c1)])
        oy, ox = (i // 2) * h, (i % 2) * h
        rgb[oy:oy + h, ox:ox + h] = col
        a[oy:oy + h, ox:ox + h] = (cov > 0.5).astype(float)
    C.save_png("leaves", rgb, a)


def grass_tuft():
    W, H = 512, 512
    rgb = np.zeros((H, W, 3))
    a = np.zeros((H, W))
    r = C.rng(201)
    yy, xx = np.mgrid[0:H, 0:W]
    for _ in range(70):
        bx = r.uniform(40, W - 40)
        top = r.uniform(30, 260)
        lean = r.uniform(-120, 120)
        wid = r.uniform(7, 14)
        t = np.clip((H - yy) / (H - top), 0, 1)
        cx = bx + lean * t ** 1.6
        m = (np.abs(xx - cx) < wid * (1 - t) + 0.8) & (yy > top)
        a = np.maximum(a, m.astype(float))
        col = C.ramp(t, [(0, (40, 110, 44)), (0.6, (100, 178, 62)), (1, (186, 222, 100))])
        rgb = np.where(m[..., None], col, rgb)
    C.save_png("grass_tuft", rgb, a)




def blade():
    """Smooth leaf gradient for GEOMETRY foliage (grass blades, bush leaves): V = 0 base (deep green) -> 1 tip
    (sunlit yellow-green); U = 4 columns of slightly different greens (pick per leaf for variety)."""
    W, H = 256, 512
    u, v = uv01(H, W)
    t = 1 - v  # row 0 = top of the image = tip
    cols = [[(30, 84, 40), (66, 132, 54), (132, 186, 78)], [(36, 96, 44), (80, 146, 58), (150, 198, 86)],
            [(28, 78, 46), (58, 122, 62), (112, 172, 84)], [(44, 100, 40), (96, 154, 56), (176, 210, 96)]]
    col = np.zeros((H, W, 3))
    for i, (a, b, c) in enumerate(cols):
        m = (np.floor(u * 4) == i)[..., None]
        col = np.where(m, C.ramp(t, [(0, a), (0.55, b), (1, c)]), col)
    C.save_png("blade", col)


def petal():
    """2x2 flower swatches (orange, yellow, pink, white) with a warm centre -- flower-head discs map one quadrant."""
    S = 256
    u, v = uv01(S, S)
    sw = [((255, 140, 40), (255, 200, 90)), ((255, 214, 64), (255, 244, 150)), ((236, 96, 140), (255, 170, 200)),
          ((246, 240, 230), (255, 255, 250))]
    col = np.zeros((S, S, 3))
    for i, (a, b) in enumerate(sw):
        qx, qy = i % 2, i // 2
        lu, lv = u * 2 - qx, v * 2 - qy
        m = ((lu >= 0) & (lu < 1) & (lv >= 0) & (lv < 1))[..., None]
        d = np.clip(np.hypot(lu - 0.5, lv - 0.5) * 2, 0, 1)
        c = C.ramp(d, [(0, (250, 190, 60)), (0.25, a), (1, b)])
        col = np.where(m, c, col)
    C.save_png("petal", col)


def void():
    """Near-black blue-purple for cave mouths, eye sockets, doorways (reads as depth, not as a flat colour)."""
    S = 128
    x, y = C.grid(S, S, 2)
    col = painted(soft(x, y, 2, 211), [(0, (14, 12, 22)), (1, (34, 28, 44))])
    C.save_png("void", col)


def foam():
    """Soft white foam / splash (waterfall base, wave crests)."""
    S = 256
    x, y = C.grid(S, S, 4)
    col = painted(soft(x, y, 4, 221), [(0, (196, 232, 240)), (1, (255, 255, 255))])
    C.save_png("foam", C.blur(col, 2))


def moss():
    """Dark patchy moss for rock tops (Skull Rock crown, boulder caps): deep green with lighter soft clumps."""
    S = 512
    x, y = C.grid(S, S, 4)
    t = np.clip(0.6 * soft(x, y, 4, 231) + 0.4 * C.blur(C.posterize(soft(x * 2, y * 2, 8, 232), 3, 0.3), 4), 0, 1)
    col = painted(t, [(0, (40, 78, 40)), (0.5, (62, 106, 48)), (1, (104, 146, 66))])


# ------------------------------------------------------------------ characters (characters.py)
def skin():
    """Warm sun-tanned skin: soft blush pools, no noise (painted look)."""
    S = 256
    x, y = C.grid(S, S, 2)
    col = painted(soft(x, y, 2, 271), [(0, (200, 140, 104)), (0.5, (220, 162, 124)), (1, (236, 182, 146))])
    C.save_png("skin", C.blur(col, 2))


def coat_red():
    """Captain's coat: deep crimson wool with soft folds (V along the body) + faint woven grain."""
    S = 512
    u, v = uv01(S, S)
    x, y = C.grid(S, S, 4)
    folds = 0.5 + 0.5 * np.sin(u * math.pi * 6 + 2.0 * soft(x, y, 4, 281))
    t = np.clip(0.55 * folds + 0.45 * soft(x * 2, y * 2, 8, 282), 0, 1)
    col = painted(t, [(0, (92, 18, 26)), (0.5, (136, 28, 36)), (1, (176, 48, 50))])
    grain = C.stretch_noise(S, S, 128, 128, seed=283)
    col = col * (0.95 + 0.08 * grain[..., None])
    C.save_png("coat_red", C.blur(col, 1))


def leather():
    """Dark brown-black leather: soft sheen pools + a few creases (boots, hat, belt, eyepatch)."""
    S = 256
    x, y = C.grid(S, S, 3)
    col = painted(soft(x, y, 3, 291), [(0, (30, 22, 20)), (0.6, (54, 38, 30)), (1, (84, 62, 46))])
    cov, _ = C.stamp_ellipses(S, S, 26, 26, 1.6, seed=292, angle_jitter=0.6)
    col = C.mix(col, col * 0.6, C.blur(cov, 1) * 0.6)
    C.save_png("leather", C.blur(col, 1))


def hair():
    """Dark beard / hair: long soft strands (streaks along V)."""
    S = 256
    strands = C.stretch_noise(S, S, 4, 64, seed=301)
    t = C.posterize(np.clip(0.7 * strands + 0.3 * C.fbm(S, S, 6, 3, seed=302), 0, 1), 4, 0.8)
    col = painted(t, [(0, (28, 18, 14)), (0.6, (58, 38, 26)), (1, (96, 66, 42))])
    C.save_png("hair", C.blur(col, 1))


def cloth_dark():
    """Worn dark cloth (trousers, the skeleton's rags): slate-navy with soft wear patches."""
    S = 256
    x, y = C.grid(S, S, 3)
    col = painted(soft(x, y, 3, 311), [(0, (34, 38, 52)), (0.5, (50, 56, 74)), (1, (74, 80, 98))])
    cov, _ = C.stamp_ellipses(S, S, 18, 22, 12, seed=312)
    col = C.mix(col, col * 1.25, C.blur(cov, 4) * 0.4)
    C.save_png("cloth_dark", C.blur(col, 1))


def glow():
    """Ghostly cyan glow (the skeleton's eyes): emission."""
    S = 64
    u, v = uv01(S, S)
    d = np.hypot(u - 0.5, v - 0.5) * 2
    col = painted(np.clip(1 - d, 0, 1), [(0, (40, 220, 200)), (1, (210, 255, 250))])
    C.save_png("glow", col)
    C.save_png("moss", C.blur(col, 2))
ALL = (grass, sand, cliff, rock, path, curb, street, plaza, canvas, skin, coat_red, leather, hair, cloth_dark, glow, blade, petal, void, foam, moss, sea, falls, plank, wood_dark, thatch, shingle, stone, awnings, sail, flag, gold,
       iron, rope, bone, lamp, palm_bark, frond, leaves, grass_tuft)


def run_all(only=None):
    done = []
    for f in ALL:
        if only and f.__name__ not in only:
            continue
        f()
        done.append(f.__name__)
    return done


result = {"textures": run_all(globals().get("ONLY"))}
