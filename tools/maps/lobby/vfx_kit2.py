# Alamat Defense Lobby -- VFX kit 2 (B172 phase 4, user: "more cooler vfx around the map everywhere ... make all vfx
# noticeable"). White-on-alpha textures (tinted in Studio, docs/design/white-tint-art.md), 512 px; flipbooks are 2x2
# grids (ParticleEmitter.FlipbookLayout Grid2x2). Written to <BASE>/tex/vfx2_<name>.png, then uploaded with the Studio
# MCP upload_image tool (served over a local http server) -- no 3D import needed.
# Run: blender.exe -b --python-expr "exec(open(r'<this>').read()); print('RESULT', result)"
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
S = 512


def grid(n=S):
    y, x = np.mgrid[0:n, 0:n] / (n - 1) * 2 - 1
    return x, -y  # +y up


def soft(a, k=1.0):
    return np.clip(a, 0, 1) ** k


def rot(x, y, a):
    c, s = math.cos(a), math.sin(a)
    return x * c - y * s, x * s + y * c


def petal(n=S):
    """Sakura petal: teardrop with a notch at the tip, soft edge, slight inner shading."""
    x, y = grid(n)
    x, y = rot(x, y, 0.5)
    r = np.sqrt((x / 0.55) ** 2 + ((y + 0.1) / 0.85) ** 2)
    body = soft((1 - r) * 6)
    notch = np.exp(-((x / 0.12) ** 2 + ((y - 0.72) / 0.18) ** 2))
    a = np.clip(body - notch * 1.2, 0, 1)
    return a * (0.8 + 0.2 * np.clip(1 - r, 0, 1))


def leaf(n=S):
    """Pointed leaf with a midrib."""
    x, y = grid(n)
    x, y = rot(x, y, -0.6)
    w = 0.42 * np.clip(1 - y * y, 0, 1) ** 0.8
    body = soft((w - np.abs(x)) * 18)
    rib = np.exp(-(x / 0.025) ** 2) * (np.abs(y) < 0.9)
    return np.clip(body * (1 - 0.35 * rib), 0, 1)


def firefly(n=S):
    """Bright core + wide soft halo (reads at distance with LightEmission)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    return np.clip(np.exp(-(r / 0.08) ** 2) + 0.55 * np.clip(1 - r, 0, 1) ** 3, 0, 1)


def wisp(n=S):
    """A curling spirit streak: a bright comma-shaped trail fading along its length."""
    x, y = grid(n)
    t = (y + 1) / 2  # 0 tail .. 1 head
    cx = 0.35 * np.sin(t * math.pi * 1.6) * (1 - t)
    w = 0.04 + 0.16 * t ** 2
    a = np.exp(-((x - cx) / w) ** 2) * soft(t, 1.4)
    head = np.exp(-((x - cx) ** 2 + (y - 0.75) ** 2) / 0.02)
    return np.clip(a + head, 0, 1)


def godray(n=S):
    """Wide soft light shaft (v along the beam) with streaky noise; fades at both ends."""
    x, y = grid(n)
    streak = 0.65 + 0.35 * C.fbm(n, n, base_cells=6, octaves=3, seed=21, wrap=True)
    streak = np.clip(streak, 0, 1)
    across = np.clip(1 - np.abs(x), 0, 1) ** 1.6
    along = np.clip(1 - np.abs(y) ** 3, 0, 1)
    return np.clip(across * along * streak, 0, 1)


def pulse_ring(n=S):
    """Thin bright ring with a soft inner glow (expanding shockwave particle)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    return np.clip(np.exp(-((r - 0.86) / 0.035) ** 2) + 0.35 * np.exp(-((r - 0.8) / 0.12) ** 2), 0, 1)


def mist(n=S):
    """Soft cloud puff (fbm inside a round falloff)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    f = C.fbm(n, n, base_cells=4, octaves=5, seed=7, wrap=True)
    return np.clip((0.55 + 0.6 * f) * np.clip(1 - r, 0, 1) ** 1.8, 0, 1)


def flare(n=S):
    """Lens glint: 6-point star + halo ring."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    spikes = np.clip(np.abs(np.cos(ang * 3)) ** 40, 0, 1) * np.clip(1 - r, 0, 1) ** 2
    core = np.exp(-(r / 0.07) ** 2)
    ring = 0.4 * np.exp(-((r - 0.55) / 0.02) ** 2)
    return np.clip(spikes + core + ring, 0, 1)


def glyph_sun(n=S):
    """Sun glyph circle: double ring, 16 rays between, 8 dots (station floor rune)."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    rings = np.exp(-((r - 0.9) / 0.018) ** 2) + np.exp(-((r - 0.62) / 0.014) ** 2) + np.exp(-((r - 0.3) / 0.012) ** 2)
    rays = (np.abs(np.sin(ang * 8)) > 0.97) * (r > 0.34) * (r < 0.6)
    dots = np.zeros_like(r)
    for k in range(8):
        a = k * math.pi / 4 + math.pi / 8
        dots += np.exp(-(((x - math.cos(a) * 0.76) ** 2 + (y - math.sin(a) * 0.76) ** 2) / 0.0012))
    core = np.exp(-(r / 0.1) ** 2) * 0.8
    return np.clip(rings + rays * 0.9 + dots + core, 0, 1)


def glyph_hex(n=S):
    """Hexagram ring: outer ring + two triangles + inner ring."""
    x, y = grid(n)
    r = np.sqrt(x * x + y * y)
    out = np.exp(-((r - 0.92) / 0.016) ** 2) + np.exp(-((r - 0.42) / 0.014) ** 2)
    tri = np.zeros_like(r)
    for flip in (0.0, math.pi):
        for k in range(3):
            a = flip + k * 2 * math.pi / 3 + math.pi / 2
            nx, ny = math.cos(a), math.sin(a)
            d = x * nx + y * ny  # distance along the edge normal
            tri += np.exp(-((d + 0.43) / 0.014) ** 2) * (r < 0.86)
    return np.clip(out + tri, 0, 1)


def flipbook(frames):
    """4 frames -> one 2x2 grid image (Grid2x2: left->right, top->bottom)."""
    h = frames[0].shape[0]
    out = np.zeros((h * 2, h * 2))
    for i, f in enumerate(frames):
        r, c = divmod(i, 2)
        out[r * h:(r + 1) * h, c * h:(c + 1) * h] = f
    return out


def butterfly_frame(open_k, n=256):
    """Top-down butterfly; open_k 1 = wings spread, 0.15 = nearly closed (edge-on)."""
    x, y = grid(n)
    ax = np.abs(x) / max(open_k, 0.12)
    up = np.exp(-(((ax - 0.42) / 0.36) ** 2 + ((y - 0.2) / 0.38) ** 2) * 2.2)
    lo = np.exp(-(((ax - 0.3) / 0.26) ** 2 + ((y + 0.32) / 0.26) ** 2) * 2.2)
    wings = np.clip((up + lo) * 1.6, 0, 1) * (ax < 1.0)
    body = np.exp(-((x / 0.035) ** 2 + (y / 0.5) ** 4))
    return np.clip(wings * 0.95 + body, 0, 1)


def bird_frame(phase, n=256):
    """Seabird silhouette (side/front 'M'), wings at a flap phase (-1 down .. 1 up)."""
    x, y = grid(n)
    a = np.zeros_like(x)
    lift = 0.35 * phase
    for sx in (-1, 1):
        # wing = a thick curve from the body to the tip
        t = np.clip(sx * x / 0.85, 0, 1)
        cy = lift * t ** 1.3 - 0.12 * np.sin(t * math.pi)
        a += np.exp(-((y - cy) / (0.05 * (1 - t) + 0.015)) ** 2) * (sx * x > 0) * (np.abs(x) < 0.85)
    a += np.exp(-((x / 0.09) ** 2 + ((y + 0.02) / 0.06) ** 2))
    return np.clip(a, 0, 1)


TEXTURES = {
    "petal": petal, "leaf": leaf, "firefly": firefly, "wisp": wisp, "godray": godray, "pulse": pulse_ring,
    "mist": mist, "flare": flare, "glyph_sun": glyph_sun, "glyph_hex": glyph_hex,
}
paths = {}
for k, fn in TEXTURES.items():
    a = fn()
    paths[k] = C.save_png("vfx2_" + k, np.ones(a.shape + (3,)), alpha=a)
bf = flipbook([butterfly_frame(o) for o in (1.0, 0.6, 0.18, 0.6)])
paths["butterfly"] = C.save_png("vfx2_butterfly", np.ones(bf.shape + (3,)), alpha=bf)
bd = flipbook([bird_frame(p) for p in (1.0, 0.3, -0.7, 0.3)])
paths["bird"] = C.save_png("vfx2_bird", np.ones(bd.shape + (3,)), alpha=bd)
result = paths
