# Apolaki Sun Terraces -- painted texture generator (B166). Run in Blender:
#   exec(open(r"<repo>/tools/maps/apolaki/textures.py").read())
# Every texture is procedural numpy "paint": soft value noise, posterized into anime cel bands,
# with stamped strokes. Row 0 = top of the image. Output: Downloads/Apolaki_Map/tex/*.png
import importlib
import math
import sys

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

importlib.reload(C)
np = C.np


def warped(x, y, period, seed, warp=1.4, octaves=5):
    """Tileable, organic (domain-warped) fractal noise in 0..1."""
    wx = C.fbm_xy(x, y, period, 3, seed + 1, rotate=False)
    wy = C.fbm_xy(x + 5.2, y + 1.3, period, 3, seed + 2, rotate=False)
    n = C.fbm_xy(x + warp * wx, y + warp * wy, period, octaves, seed, rotate=False)
    return C.smoothstep(0.18, 0.82, n)


def grass():
    S = 1024
    x, y = C.grid(S, S, 6)
    big = warped(x, y, 6, 11)
    x2, y2 = C.grid(S, S, 24)
    small = warped(x2, y2, 24, 12, warp=0.8, octaves=3)
    t = C.posterize(np.clip(0.72 * big + 0.28 * small, 0, 1), 5, 0.6)
    col = C.ramp(t, [(0.0, (30, 92, 54)), (0.28, (52, 128, 56)), (0.55, (86, 162, 60)), (0.8, (132, 194, 70)), (1.0, (184, 214, 96))])
    # warm sun-kissed patches
    x3, y3 = C.grid(S, S, 4)
    warm = C.smoothstep(0.62, 0.8, warped(x3, y3, 4, 14))
    col = C.mix(col, np.minimum(col * np.array([1.16, 1.06, 0.74]), 1), warm * 0.55)
    # short multi-directional strokes: dark clumps + bright blades
    cov, _ = C.stamp_ellipses(S, S, 1500, 6, 2.2, seed=15, angle_jitter=0.9)
    col = C.mix(col, col * 0.80, cov * 0.45)
    cov, _ = C.stamp_ellipses(S, S, 2600, 4.5, 1.2, seed=16, angle_jitter=0.9)
    col = C.mix(col, np.minimum(col * 1.22 + 0.04, 1), cov * 0.45)
    C.save_png("grass", C.blur(col, 1))


def cliff():
    W, H = 1024, 1024  # tiles in U; V = 0 top (grass lip) -> 1 bottom (32 studs)
    x, y = C.grid(H, W, 8)
    warp = C.fbm_xy(x, y, 8, 4, 21, rotate=False)
    blot = warped(x, y, 8, 23)
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    bands = 0.5 + 0.5 * np.sin((v * 9 + 1.6 * warp) * 2 * math.pi)  # wavy strata
    t = C.posterize(np.clip(0.45 * bands + 0.55 * blot, 0, 1), 5, 0.5)
    col = C.ramp(t, [(0.0, (78, 40, 44)), (0.3, (116, 60, 52)), (0.6, (152, 88, 64)), (0.85, (186, 122, 82)), (1.0, (212, 156, 104))])
    # lit top, shadowed base
    col = col * (1.10 - 0.42 * v)[..., None]
    # a few dark cracks following the strata
    crack = C.smoothstep(0.035, 0.0, np.abs(bands - 0.5) * (0.6 + blot)) * C.smoothstep(0.55, 0.7, C.fbm_xy(x * 2, y, 16, 3, 24, rotate=False))
    col = C.mix(col, col * 0.5, crack * 0.7)
    # mossy grass lip dripping down from the top edge (tileable in U)
    drip = C.fbm_xy(np.linspace(0, 32, W), np.zeros(W), 32, 3, 25, rotate=False)[None, :]
    lip = 0.05 + 0.12 * drip ** 2
    moss = 1 - C.smoothstep(lip, lip + 0.03, v)
    mossc = C.ramp(warped(x * 3, y * 3, 24, 26, octaves=3), [(0, (52, 122, 52)), (1, (126, 186, 70))])
    col = C.mix(col, mossc, moss)
    C.save_png("cliff", C.blur(col, 1))


def path():
    W, H = 512, 512  # U across the width (with rims), V along the length (tiles)
    u = np.linspace(0, 1, W)[None, :].repeat(H, 0)
    n = C.fbm(H, W, 8, 4, seed=31)
    base = C.ramp(C.posterize(n, 4, 0.5), [(0, (182, 136, 104)), (0.5, (212, 168, 128)), (1, (232, 196, 152))])
    # pebbles
    cov, tone = C.stamp_ellipses(H, W, 260, 7, 5, seed=32)
    base = C.mix(base, base * (0.82 + 0.25 * tone[..., None]), cov * 0.6)
    # wheel-worn darker centre lines
    lines = np.exp(-((u - 0.36) ** 2) / 0.002) + np.exp(-((u - 0.64) ** 2) / 0.002)
    base = base * (1 - 0.10 * lines[..., None])
    # dark rims (outer 14% each side) with a lighter bevel line inside them
    rim = 1 - C.smoothstep(0.10, 0.15, np.minimum(u, 1 - u))
    rimc = C.ramp(C.fbm(H, W, 10, 3, seed=33), [(0, (58, 34, 32)), (1, (92, 56, 44))])
    col = C.mix(base, rimc, rim)
    bevel = np.exp(-((np.minimum(u, 1 - u) - 0.155) ** 2) / 0.00015)
    col = np.minimum(col + 0.10 * bevel[..., None], 1)
    C.save_png("path", col)


def stone_wall():
    """Dry-stacked terrace wall: rounded stones in courses, lit top-left, mossy joints."""
    S = 512
    r = C.rng(41)
    yy, xx = np.mgrid[0:S, 0:S]
    col = np.zeros((S, S, 3)) + np.array([58, 46, 44]) / 255.0
    courses = 6
    ch = S / courses
    for row in range(courses):
        x = r.uniform(-40, 0)
        while x < S:
            w = r.uniform(60, 110)
            cx, cy = x + w / 2, row * ch + ch / 2 + r.normal(0, 3)
            for dx in (-S, 0, S):  # wrap horizontally
                u = (xx - cx - dx) / (w / 2 - 3)
                v = (yy - cy) / (ch / 2 - 3)
                d = np.maximum(np.abs(u), np.abs(v)) * 0.55 + np.hypot(u, v) * 0.45  # rounded box
                m = d < 1
                if not m.any():
                    continue
                lit = np.clip(0.62 - 0.32 * v - 0.12 * u - 0.25 * d ** 4 + r.normal(0, 0.06), 0, 1)
                c = C.ramp(C.posterize(lit, 4, 0.6), [(0, (92, 80, 74)), (0.5, (146, 128, 108)), (1, (198, 180, 150))])
                col = np.where(m[..., None], c, col)
            x += w + r.uniform(2, 6)
    x, y = C.grid(S, S, 6)
    moss = C.smoothstep(0.66, 0.78, warped(x, y, 6, 42))
    col = C.mix(col, np.array([84, 134, 58]) / 255.0 * np.ones_like(col), moss * 0.45)
    C.save_png("stone_wall", C.blur(col, 1))


def bamboo():
    W, H = 256, 512  # V along the culm: two nodes per tile
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    u = np.linspace(0, 1, W)[None, :].repeat(H, 0)
    x, y = C.grid(H, W, 4)
    shade = 0.55 + 0.35 * np.sin(u * math.pi * 2) + 0.15 * (warped(x, y, 4, 181) - 0.5)
    col = C.ramp(C.posterize(np.clip(shade, 0, 1), 4, 0.5), [(0, (96, 128, 40)), (0.5, (150, 180, 60)), (1, (214, 222, 120))])
    node = np.exp(-(((v * 2) % 1) - 0.5) ** 2 / 0.0012)
    col = col * (1 - 0.35 * node)[..., None] + np.array([0.08, 0.06, 0.0]) * node[..., None]
    C.save_png("bamboo", col)


def paddy():
    S = 512
    y = np.linspace(0, 1, S)[:, None].repeat(S, 1)
    gx, gy = C.grid(S, S, 6)
    rows = 0.5 + 0.5 * np.sin(y * math.pi * 2 * 16 + warped(gx, gy, 6, 51) * 2)
    bx, by = C.grid(S, S, 64)
    blades = C.fbm_xy(bx, by * 0.4, 64, 2, 52, rotate=False)
    t = C.posterize(0.6 * rows + 0.4 * blades, 4, 0.5)
    col = C.ramp(t, [(0, (64, 132, 46)), (0.5, (118, 182, 58)), (1, (176, 214, 86))])
    water = C.smoothstep(0.88, 0.95, 1 - rows) * C.smoothstep(0.4, 0.6, C.fbm(S, S, 10, 3, seed=53))
    col = C.mix(col, np.array([150, 200, 210]) / 255.0 * np.ones_like(col), water * 0.6)
    C.save_png("paddy", C.blur(col, 1))


def water():
    S = 512
    n = C.fbm(S, S, 4, 4, seed=61)
    w1 = C.stretch_noise(S, S, 60, 8, seed=62)
    t = C.posterize(0.6 * n + 0.4 * w1, 4, 0.5)
    col = C.ramp(t, [(0, (40, 110, 140)), (0.5, (70, 160, 180)), (1, (130, 210, 215))])
    glint = C.smoothstep(0.86, 0.93, C.stretch_noise(S, S, 90, 14, seed=63))
    col = C.mix(col, np.array([255, 236, 176]) / 255.0 * np.ones_like(col), glint * 0.8)
    C.save_png("water", col)


def rock():
    W, H = 512, 512  # V = 0 top -> 1 bottom (UV v from rock height)
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    x, y = C.grid(H, W, 5)
    n = warped(x, y, 5, 71)
    t = C.posterize(np.clip(0.78 - 0.6 * v + 0.4 * (n - 0.5), 0, 1), 5, 0.45)
    col = C.ramp(t, [(0, (84, 70, 82)), (0.35, (128, 110, 108)), (0.7, (176, 156, 136)), (1, (222, 204, 170))])
    moss = C.smoothstep(0.55, 0.68, warped(x * 2, y * 2, 10, 72, octaves=3)) * (1 - C.smoothstep(0.12, 0.35, v))
    col = C.mix(col, np.array([96, 156, 64]) / 255.0 * np.ones_like(col), moss * 0.9)
    C.save_png("rock", C.blur(col, 1))


def bark():
    W, H = 256, 512
    t = C.posterize(0.6 * C.stretch_noise(H, W, 6, 40, seed=81) + 0.4 * C.fbm(H, W, 8, 3, seed=82), 4, 0.5)
    col = C.ramp(t, [(0, (58, 38, 34)), (0.5, (96, 64, 48)), (1, (138, 98, 68))])
    C.save_png("bark", col)


def leaves():
    """2x2 atlas of leafy clumps: TL dark, TR mid, BL light, BR sunlit. Alpha-cut."""
    S, T = 1024, 512
    rgb = np.zeros((S, S, 3))
    alpha = np.zeros((S, S))
    tones = [
        [(0, (26, 70, 40)), (1, (52, 108, 50))],
        [(0, (44, 104, 46)), (1, (82, 150, 58))],
        [(0, (72, 140, 54)), (1, (126, 186, 70))],
        [(0, (110, 170, 62)), (1, (196, 216, 104))],
    ]
    yy, xx = np.mgrid[0:T, 0:T]
    for i, stops in enumerate(tones):
        r = C.rng(91 + i)
        a = np.zeros((T, T))
        tone = np.zeros((T, T))
        # almond leaves radiating from the clump centre, back-to-front so later = on top
        for k in range(520):
            ang = r.uniform(0, 2 * math.pi)
            rad = T * 0.40 * math.sqrt(r.random())
            cx = T / 2 + rad * math.cos(ang)
            cy = T / 2 + rad * math.sin(ang) * 0.85
            la = ang + r.normal(0, 0.5)              # leaf points outward
            L, Wd = r.uniform(22, 34), r.uniform(7, 11)
            ca, sa = math.cos(la), math.sin(la)
            x0, x1 = int(max(cx - L - 2, 0)), int(min(cx + L + 2, T))
            y0, y1 = int(max(cy - L - 2, 0)), int(min(cy + L + 2, T))
            if x1 <= x0 or y1 <= y0:
                continue
            sx, sy = xx[y0:y1, x0:x1] - cx, yy[y0:y1, x0:x1] - cy
            u = (sx * ca + sy * sa) / L                # -1..1 along the leaf
            v = (-sx * sa + sy * ca) / Wd
            m = (np.abs(u) < 1) & (np.abs(v) < (1 - u * u) ** 0.8)
            # light from the top-left: leaves high in the clump are brighter, each leaf gets a midrib shade
            lit = 0.55 + 0.35 * (1 - cy / T) + 0.15 * (cx < T / 2) - 0.25 * (v > 0) + r.normal(0, 0.05)
            tone[y0:y1, x0:x1] = np.where(m, np.clip(lit, 0, 1), tone[y0:y1, x0:x1])
            a[y0:y1, x0:x1] = np.maximum(a[y0:y1, x0:x1], m.astype(float))
        c = C.ramp(C.posterize(tone, 4, 0.6), stops)
        r0, c0 = (i // 2) * T, (i % 2) * T
        rgb[r0:r0 + T, c0:c0 + T] = c
        alpha[r0:r0 + T, c0:c0 + T] = a
    # bleed colour under transparent pixels so mip-maps never fringe black
    C.save_png("leaves", rgb, alpha)


def frond():
    S = 512
    rgb = np.zeros((S, S, 3))
    a = np.zeros((S, S))
    yy, xx = np.mgrid[0:S, 0:S]
    cx = S / 2
    for k in range(46):  # leaflets along the rib (rib runs top->bottom)
        y0 = 20 + k * 10.5
        side = -1 if k % 2 else 1
        length = 140 * math.sin(math.pi * (k + 2) / 50) + 30
        ang = math.radians(28)
        for s in (-1, 1) if k % 2 == 0 else (side,):
            dx = (xx - cx) * s
            dy = (yy - y0)
            u = dx * math.cos(ang) + dy * math.sin(ang)
            v = -dx * math.sin(ang) + dy * math.cos(ang)
            m = (u > 0) & (u < length) & (np.abs(v) < 7 * (1 - u / max(length, 1)) + 1.5)
            a = np.maximum(a, m.astype(float))
            shade = np.clip(0.4 + 0.6 * (u / max(length, 1)), 0, 1)
            rgb = np.where(m[..., None], C.ramp(shade, [(0, (52, 112, 44)), (1, (150, 196, 74))]), rgb)
    rib = np.abs(xx - cx) < 3
    a = np.maximum(a, rib.astype(float))
    rgb = np.where(rib[..., None], np.array([120, 150, 70]) / 255.0, rgb)
    C.save_png("frond", rgb, a)


def grass_tuft():
    W, H = 512, 512
    rgb = np.zeros((H, W, 3))
    a = np.zeros((H, W))
    r = C.rng(101)
    yy, xx = np.mgrid[0:H, 0:W]
    for _ in range(70):
        bx = r.uniform(40, W - 40)
        top = r.uniform(30, 260)
        lean = r.uniform(-120, 120)
        wid = r.uniform(7, 14)
        t = np.clip((H - yy) / (H - top), 0, 1)  # 0 at base, 1 at tip
        cx = bx + lean * t ** 1.6
        m = (np.abs(xx - cx) < wid * (1 - t) + 0.8) & (yy > top)
        a = np.maximum(a, m.astype(float))
        col = C.ramp(t, [(0, (40, 98, 40)), (0.6, (96, 166, 58)), (1, (178, 214, 96))])
        rgb = np.where(m[..., None], col, rgb)
    C.save_png("grass_tuft", rgb, a)


def flowers():
    S = 512
    rgb, a = np.zeros((S, S, 3)), np.zeros((S, S))
    r = C.rng(111)
    yy, xx = np.mgrid[0:S, 0:S]
    palette = [(255, 196, 64), (255, 150, 60), (255, 236, 150), (240, 120, 150), (255, 255, 236)]
    for _ in range(26):
        fx, fy = r.uniform(40, S - 40), r.uniform(60, 300)
        stem = (np.abs(xx - fx) < 2.5) & (yy > fy) & (yy < S)
        a = np.maximum(a, stem.astype(float))
        rgb = np.where(stem[..., None], np.array([70, 130, 50]) / 255.0, rgb)
        pc = np.array(palette[r.integers(len(palette))]) / 255.0
        rad = r.uniform(12, 22)
        ang = np.arctan2(yy - fy, xx - fx)
        d = np.hypot(xx - fx, yy - fy) / (rad * (0.75 + 0.25 * np.cos(ang * 5)))
        m = d < 1
        a = np.maximum(a, m.astype(float))
        rgb = np.where(m[..., None], pc * (0.85 + 0.15 * (1 - d))[..., None], rgb)
        core = d < 0.3
        rgb = np.where(core[..., None], np.array([150, 90, 30]) / 255.0, rgb)
    C.save_png("flowers", rgb, a)


def mountain():
    W, H = 512, 1024  # V = 0 summit -> 1 base
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    x, y = C.grid(H, W, 4)
    n = warped(x, y, 4, 121)
    streak = C.fbm_xy(x * 6, y * 0.6, 24, 3, 122, rotate=False)
    t = C.posterize(np.clip(v + 0.25 * (n - 0.5) + 0.12 * (streak - 0.5), 0, 1), 6, 0.45)
    col = C.ramp(t, [(0, (196, 178, 196)), (0.25, (150, 150, 176)), (0.5, (96, 132, 118)), (0.75, (64, 118, 74)), (1, (46, 96, 56))])
    C.save_png("mountain", C.blur(col, 1))


def wood():
    W, H = 512, 512
    grain = C.stretch_noise(H, W, 4, 90, seed=131)
    planks = (np.floor(np.linspace(0, 6, W))[None, :] % 2).repeat(H, 0)
    t = C.posterize(0.7 * grain + 0.3 * C.fbm(H, W, 8, 3, seed=132), 4, 0.5)
    col = C.ramp(t, [(0, (92, 58, 40)), (0.5, (140, 94, 60)), (1, (184, 132, 84))])
    col = col * (0.92 + 0.08 * planks)[..., None]
    seams = (np.abs((np.linspace(0, 6, W) % 1) - 0.0) < 0.02)[None, :].repeat(H, 0)
    col = np.where(seams[..., None], col * 0.55, col)
    C.save_png("wood", col)


def thatch():
    S = 512
    y = np.linspace(0, 1, S)[:, None].repeat(S, 1)
    rows = (y * 8) % 1
    strands = C.stretch_noise(S, S, 8, 180, seed=141)
    t = C.posterize(np.clip(0.55 * strands + 0.45 * (1 - rows), 0, 1), 4, 0.5)
    col = C.ramp(t, [(0, (110, 76, 40)), (0.5, (176, 132, 70)), (1, (222, 184, 110))])
    C.save_png("thatch", col)


def shrine_stone():
    S = 512
    n = C.fbm(S, S, 6, 4, seed=151)
    blocks_y = (np.linspace(0, 4, S) % 1)[:, None].repeat(S, 1)
    off = (np.floor(np.linspace(0, 4, S)) % 2)[:, None] * 0.5
    blocks_x = (np.linspace(0, 3, S)[None, :] + off) % 1
    seam = (np.minimum(blocks_y, 1 - blocks_y) < 0.03) | (np.minimum(blocks_x, 1 - blocks_x) < 0.02)
    t = C.posterize(n, 4, 0.5)
    col = C.ramp(t, [(0, (196, 170, 130)), (0.5, (226, 204, 160)), (1, (244, 228, 190))])
    col = np.where(seam[..., None], col * 0.7, col)
    C.save_png("shrine_stone", col)


def gold():
    S = 256
    v = np.linspace(0, 1, S)[:, None].repeat(S, 1)
    t = C.posterize(np.clip(1 - v + 0.2 * (C.fbm(S, S, 4, 3, seed=161) - 0.5), 0, 1), 5, 0.5)
    col = C.ramp(t, [(0, (150, 84, 20)), (0.5, (230, 160, 40)), (0.85, (255, 214, 96)), (1, (255, 246, 196))])
    C.save_png("gold", col)


def sun_emblem():
    S = 512
    yy, xx = np.mgrid[0:S, 0:S]
    c = S / 2
    d = np.hypot(xx - c, yy - c) / c
    ang = np.arctan2(yy - c, xx - c)
    rays = 0.5 + 0.5 * np.cos(ang * 16)
    ray_mask = (d < 0.55 + 0.42 * rays ** 3) & (d > 0.4)
    disc = d < 0.42
    ring = (d > 0.30) & (d < 0.36)
    a = (ray_mask | disc).astype(float)
    col = C.ramp(np.clip(1 - d, 0, 1), [(0, (220, 120, 30)), (0.5, (255, 190, 60)), (1, (255, 244, 180))])
    col = np.where(ring[..., None], np.array([200, 110, 30]) / 255.0, col)
    C.save_png("sun_emblem", col, a)


def cloth():
    W, H = 256, 512
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    u = np.linspace(0, 1, W)[None, :].repeat(H, 0)
    col = C.ramp(C.posterize(C.fbm(H, W, 4, 3, seed=171), 3, 0.5), [(0, (150, 30, 36)), (1, (196, 48, 46))])
    border = (u < 0.08) | (u > 0.92)
    col = np.where(border[..., None], np.array([236, 176, 60]) / 255.0, col)
    d = np.hypot((u - 0.5) * W, (v - 0.32) * H) / (W * 0.3)
    ang = np.arctan2((v - 0.32) * H, (u - 0.5) * W)
    sun = (d < 0.55) | ((d < 1.0) & (np.cos(ang * 12) > 0.6))
    col = np.where(sun[..., None], np.array([250, 196, 70]) / 255.0, col)
    # swallow-tail cut at the bottom
    cut = v > 0.86 + 0.14 * np.abs(u - 0.5) * 2
    C.save_png("cloth", col, (~cut).astype(float))


def flame():
    """Teardrop flame for torch particles (white-hot core, orange body), alpha."""
    S = 256
    yy, xx = np.mgrid[0:S, 0:S]
    u = (xx - S / 2) / (S / 2)
    v = yy / S  # 0 top -> 1 bottom
    width = 0.15 + 0.55 * np.sin(np.clip(v, 0, 1) * math.pi * 0.85) ** 1.4
    d = np.abs(u) / np.maximum(width, 1e-3)
    a = (1 - C.smoothstep(0.75, 1.0, d)) * C.smoothstep(0.0, 0.18, v) * (1 - C.smoothstep(0.92, 1.0, v))
    heat = np.clip(1 - d * 0.9, 0, 1) * C.smoothstep(0.3, 0.9, v)
    col = C.ramp(heat, [(0, (255, 110, 30)), (0.6, (255, 190, 70)), (1, (255, 250, 220))])
    C.save_png("fx_flame", col, a)


def petal():
    S = 128
    yy, xx = np.mgrid[0:S, 0:S]
    u = (xx - S / 2) / (S * 0.42)
    v = (yy - S / 2) / (S * 0.24)
    d = u * u + v * v
    a = 1 - C.smoothstep(0.85, 1.0, d)
    col = C.ramp(np.clip(0.5 - v * 0.4, 0, 1), [(0, (255, 200, 110)), (1, (255, 236, 170))])
    C.save_png("fx_petal", col, a)


def falls():
    """Vertical water streaks for the waterfall beams (tiles along the beam)."""
    W, H = 256, 512
    x, y = C.grid(H, W, 16, 2)
    streak = C.fbm_xy(x, y, 16, 3, 191, rotate=False)
    t = C.smoothstep(0.35, 0.75, streak)
    col = C.ramp(t, [(0, (120, 200, 230)), (0.6, (200, 240, 250)), (1, (255, 255, 255))])
    a = 0.35 + 0.6 * t
    C.save_png("fx_falls", col, a)


def stone_block():
    """Sandstone for real block geometry (no painted seams): warm cream, soft weathering."""
    S = 512
    x, y = C.grid(S, S, 6)
    n = warped(x, y, 6, 201)
    x2, y2 = C.grid(S, S, 24)
    fine = C.fbm_xy(x2, y2, 24, 3, 202, rotate=False)
    t = C.posterize(np.clip(0.65 * n + 0.35 * fine, 0, 1), 5, 0.55)
    col = C.ramp(t, [(0, (176, 146, 112)), (0.35, (206, 180, 140)), (0.7, (228, 208, 168)), (1, (244, 230, 196))])
    stain = C.smoothstep(0.62, 0.8, warped(x * 0.5, y * 0.5, 3, 203))
    col = C.mix(col, col * np.array([0.86, 0.84, 0.8]), stain * 0.6)
    C.save_png("stone_block", C.blur(col, 1))


def fieldstone():
    """Weathered grey-brown fieldstone for the terrace walls and rock piles (moss patches)."""
    S = 512
    x, y = C.grid(S, S, 5)
    n = warped(x, y, 5, 211)
    x2, y2 = C.grid(S, S, 20)
    fine = C.fbm_xy(x2, y2, 20, 3, 212, rotate=False)
    t = C.posterize(np.clip(0.6 * n + 0.4 * fine, 0, 1), 5, 0.5)
    col = C.ramp(t, [(0, (92, 82, 84)), (0.35, (128, 116, 108)), (0.7, (162, 150, 134)), (1, (196, 186, 164))])
    moss = C.smoothstep(0.66, 0.78, warped(x * 1.5, y * 1.5, 8, 213))
    col = C.mix(col, np.array([92, 140, 62]) / 255.0 * np.ones_like(col), moss * 0.7)
    C.save_png("fieldstone", C.blur(col, 1))


def ray():
    """God-ray shaft: soft vertical streaks, brightest in the middle, fades at both ends."""
    W, H = 256, 512
    u = np.linspace(0, 1, W)[None, :].repeat(H, 0)
    v = np.linspace(0, 1, H)[:, None].repeat(W, 1)
    x, y = C.grid(H, W, 12, 1)
    streak = C.fbm_xy(x, y * 0.2, 12, 3, 221, rotate=False)
    core = np.exp(-((u - 0.5) ** 2) / 0.05)
    a = core * (0.45 + 0.55 * streak) * C.smoothstep(0.0, 0.25, v) * (1 - C.smoothstep(0.7, 1.0, v))
    col = np.ones((H, W, 3)) * np.array([1.0, 0.93, 0.78])
    C.save_png("fx_ray", col, np.clip(a, 0, 1))


def run_all(only=None):
    done = []
    for f in (grass, cliff, path, stone_wall, paddy, water, rock, bark, leaves, frond, grass_tuft,
              flowers, mountain, wood, thatch, shrine_stone, gold, sun_emblem, cloth, bamboo, flame, petal, falls, stone_block, fieldstone, ray):
        if only and f.__name__ not in only:
            continue
        f()
        done.append(f.__name__)
    return done


result = {"textures": run_all(globals().get("ONLY"))}
