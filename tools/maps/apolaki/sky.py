# Apolaki Sun Terraces -- painted golden-hour skybox (B166). Writes tex/sky_{Bk,Dn,Ft,Lf,Rt,Up}.png.
# Seam-safe by construction: colour comes from each pixel's true elevation, and the side faces'
# left/right edges blend into one shared cloud band, so the faces match whatever order or mirroring
# Roblox applies to them. The sun itself is Roblox's (Sky.SunTextureId), not painted.
import importlib
import math
import sys

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

importlib.reload(C)
np = C.np
S = 1024

ZEN = np.array([96, 156, 228]) / 255.0
MID = np.array([164, 204, 244]) / 255.0
HOR = np.array([255, 214, 168]) / 255.0
GLOW = np.array([255, 186, 138]) / 255.0
BELOW = np.array([226, 196, 188]) / 255.0
C_LIT = np.array([255, 244, 226]) / 255.0
C_MID = np.array([246, 206, 196]) / 255.0
C_SHD = np.array([196, 164, 204]) / 255.0
C_RIM = np.array([255, 216, 150]) / 255.0


def sky_color(el):
    """el in radians (-pi/2..pi/2) -> RGB."""
    e = np.degrees(el)
    out = np.zeros(e.shape + (3,))
    t1 = C.smoothstep(0, 6, e)          # glow -> horizon
    t2 = C.smoothstep(4, 26, e)         # horizon -> mid
    t3 = C.smoothstep(22, 75, e)        # mid -> zenith
    col = GLOW[None, None, :] * (1 - t1[..., None]) + HOR[None, None, :] * t1[..., None]
    col = col * (1 - t2[..., None]) + MID[None, None, :] * t2[..., None]
    col = col * (1 - t3[..., None]) + ZEN[None, None, :] * t3[..., None]
    below = C.smoothstep(0, -8, e)
    col = col * (1 - below[..., None]) + BELOW[None, None, :] * below[..., None]
    return col


def cloud_density(u, el, seed):
    """u 0..1 across a side face, el radians. Clouds live in a band 2..34 degrees."""
    e = np.degrees(el)
    band = C.smoothstep(1.5, 6, e) * (1 - C.smoothstep(18, 36, e))
    y = e / 6.0                              # vertical lattice units (flattened toward the horizon)
    face = C.fbm_xy(u * 6.0, y, 6, 5, seed, rotate=False)
    seam = C.fbm_xy(np.zeros_like(u) + 0.37, y, 6, 5, 999, rotate=False)
    w = C.smoothstep(0.0, 0.18, np.minimum(u, 1 - u))  # 0 at the edges -> shared seam pattern
    n = seam * (1 - w) + face * w
    big = C.fbm_xy(u * 2.0 + seed, y * 0.5, 512, 3, seed + 5)
    d = C.smoothstep(0.50, 0.62, n * 0.75 + big * 0.35) * band
    return d


def side_face(seed):
    v, u = np.mgrid[0:S, 0:S]
    u = (u + 0.5) / S
    v = (v + 0.5) / S
    x = u * 2 - 1
    y = 1 - v * 2                   # +1 at the top of the image
    el = np.arctan2(y, np.sqrt(x * x + 1))
    col = sky_color(el)
    d = cloud_density(u, el, seed)
    # self-shadowing: density a little ABOVE this pixel lights it; density below shades it
    d_up = cloud_density(u, el + np.radians(1.4), seed)
    lit = np.clip(0.55 + (d - d_up) * 1.6, 0, 1)
    lit = C.posterize(lit, 3, 0.55)
    cc = C_SHD[None, None] * (1 - lit[..., None]) + C_MID[None, None] * lit[..., None]
    cc = cc * (1 - C.smoothstep(0.6, 0.95, lit)[..., None]) + C_LIT[None, None] * C.smoothstep(0.6, 0.95, lit)[..., None]
    rim = C.smoothstep(0.05, 0.25, d) * (1 - C.smoothstep(0.25, 0.6, d))
    cc = cc * (1 - rim[..., None] * 0.5) + C_RIM[None, None] * (rim[..., None] * 0.5)
    return col * (1 - d[..., None]) + cc * d[..., None]


def cap_face(up=True):
    v, u = np.mgrid[0:S, 0:S]
    x = (u + 0.5) / S * 2 - 1
    z = (v + 0.5) / S * 2 - 1
    el = np.arctan2(np.ones_like(x), np.sqrt(x * x + z * z))
    if not up:
        el = -el
    return sky_color(el)


def build():
    names = {}
    for i, face in enumerate(("Ft", "Rt", "Bk", "Lf")):
        names[face] = C.save_png("sky_" + face, side_face(500 + i * 17))
    names["Up"] = C.save_png("sky_Up", cap_face(True))
    names["Dn"] = C.save_png("sky_Dn", cap_face(False))
    return names


result = build()
