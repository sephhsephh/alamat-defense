# Alamat Defense Lobby "Holy Coast" -- Kit D: wonders (B172 phase 2). Same rules as README.md (split by material,
# origin bottom-centre, front -Y, row along +X). Builds AL_StoryGate, AL_PortalRing, AL_PortalVeil, AL_GemShard,
# AL_ShardObelisk, AL_BellTower, AL_GardenShrine, AL_Colonnade, AL_LanternArch, AL_Watchtower -> glb/AL_KitD.glb,
# plus white tintable VFX textures (portal, glow, sparkle, ray, rune) on carrier planes -> glb/AL_VfxCarrier.glb
# (mesh DATA names AL_Vfx_<name>, which is what the 3D Importer names the parts).
# Run: blender.exe -b <root>/blend/AL_kitD_wonders.blend --python-expr "exec(open(r'<this>').read()); print('RESULT', result)"
import importlib.util
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix

LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
_s = importlib.util.spec_from_file_location("al_common", os.path.join(LOBBY, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["al_common"] = C
_s.loader.exec_module(C)
np = C.np
PI = math.pi


def T(x=0.0, y=0.0, z=0.0):
    return Matrix.Translation((x, y, z))


def slab(bm, cx, cy, hx, hy, z0, z1, bevel=0.3, M=None):
    return C.box(bm, cx - hx, cy - hy, z0, cx + hx, cy + hy, z1, bevel=min(bevel, 0.4 * (z1 - z0)), M=M)


def pyramid(bm, cx, cy, hw, z0, z1):
    s = math.sqrt(2.0)
    return C.lathe(bm, [(0.0, z0), (hw * s, z0), (0.0, z1)], 4, center=(cx, cy, 0.0), phase=PI / 4)


def finial(bm, cx, cy, z0, h, r):
    prof = C.round_profile([(0.0, z0), (r, z0), (r * 0.6, z0 + h * 0.25), (r * 1.1, z0 + h * 0.45),
                            (r * 0.35, z0 + h * 0.75), (0.0, z0 + h)], 0.1)
    return C.lathe(bm, prof, 16, center=(cx, cy, 0.0))


def column(P, cx, cy, z0, h, r):
    Mb, G = P.bm("Marble"), P.bm("Gold")
    C.drum(Mb, (cx, cy), z0, 1.0, r * 1.45, sides=20, bevel=0.2)
    C.drum(Mb, (cx, cy), z0 + 1.0, h - 2.6, r, r_top=r * 0.9, sides=20, bevel=0.1)
    C.drum(G, (cx, cy), z0 + h - 1.6, 0.6, r * 1.15, sides=20, bevel=0.15)
    C.drum(Mb, (cx, cy), z0 + h - 1.0, 1.0, r * 1.5, sides=20, bevel=0.2)


def story_gate(col, man, origin):
    """AL_StoryGate ~92W x 16D x 120H: two massive block pylons with gold bands, teal pyramid caps and gold spikes, a
    pointed-arch bridge between them; the spinning AL_PortalRing + AL_PortalVeil are separate pieces."""
    P = C.Piece("AL_StoryGate", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    for sx in (-1, 1):
        cx = sx * 38.0
        slab(Mb, cx, 0, 9.0, 9.0, 0.0, 3.0, bevel=0.5)
        slab(MB, cx, 0, 7.5, 7.5, 3.0, 92.0, bevel=0.6)
        for z in (18.0, 46.0, 74.0):
            slab(G, cx, 0, 7.9, 7.9, z, z + 1.4, bevel=0.3)
        slab(Mb, cx, 0, 8.6, 8.6, 92.0, 96.0, bevel=0.5)
        pyramid(TT, cx, 0, 8.0, 96.0, 110.0)
        finial(G, cx, 0, 109.0, 12.0, 1.8)
        for a in (0.0, PI):
            C.spike(G, (cx + 0.0, math.cos(a) * -8.0, 60.0), (cx, math.cos(a) * -13.0, 66.0), 1.0, M=None)
    C.arch_wall(MB, 62.0, 24.0, 10.0, 46.0, 4.0, kind="pointed", bevel=0.4, n=18, point=1.25, M=T(0, 0, 76.0))
    C.box(G, -31.0, -5.4, 99.4, 31.0, 5.4, 100.6, bevel=0.2)
    C.box(Mb, -31.5, -5.6, 100.6, 31.5, 5.6, 103.0, bevel=0.4)
    for x in (-24.0, -12.0, 0.0, 12.0, 24.0):
        finial(G, x, 0, 103.0, 6.0, 1.0)
    return P.done(col, man)


def portal_ring(col, man, origin):
    """AL_PortalRing: gold ring R30 (vertical, faces -Y) with 12 teal rune blocks and 4 crystal points; spins in Studio."""
    P = C.Piece("AL_PortalRing", origin)
    G, TT, CR = P.bm("Gold"), P.bm("TealTile"), P.bm("Crystal")
    c = (0.0, 0.0, 31.0)
    C.torus(G, c, 30.0, 1.8, seg=96, sides=12, axis="Y", uv=4.0)
    C.torus(G, c, 26.0, 0.6, seg=96, sides=8, axis="Y", uv=4.0)
    for k in range(12):
        a = 2 * PI * k / 12
        x, z = math.cos(a) * 28.0, c[2] + math.sin(a) * 28.0
        C.block(TT, (x, 0, z), (3.0, 2.4, 3.0), bevel=0.3, rot=(0, -a, 0))
    for k in range(4):
        a = PI / 4 + PI * k / 2
        x, z = math.cos(a) * 33.5, c[2] + math.sin(a) * 33.5
        C.crystal(CR, (x, 0, z - 3.0), 2.4, 6.0, sides=4, rot=(0, -a + PI / 2, 0))
    return P.done(col, man)


def portal_veil(col, man, origin):
    """AL_PortalVeil: a flat disc d52 (faces -Y) that takes the portal swirl texture in Studio."""
    P = C.Piece("AL_PortalVeil", origin)
    bm = P.bm("Mandala")
    faces = C.lathe(bm, [(26.0, 0.0), (0.0, 0.0)], 48, cap=False, M=T(0, 0, 31.0) @ Matrix.Rotation(PI / 2, 4, "X"))
    C.disc_uv(bm, faces, (0, 0), 26.0)
    return P.done(col, man)


def gem_shard(col, man, origin):
    P = C.Piece("AL_GemShard", origin)
    C.crystal(P.bm("Crystal"), (0, 0, 0), 4.0, 14.0, sides=6, waist=0.55)
    return P.done(col, man)


def shard_obelisk(col, man, origin):
    """AL_ShardObelisk 10x10x44: stepped plinth, tapered obelisk with gold bands and teal tip; shards float above it."""
    P = C.Piece("AL_ShardObelisk", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    slab(Mb, 0, 0, 5.5, 5.5, 0.0, 1.5, bevel=0.4)
    slab(Mb, 0, 0, 4.6, 4.6, 1.5, 3.0, bevel=0.35)
    C.lathe(MB, [(0.0, 3.0), (3.4 * math.sqrt(2), 3.0), (2.0 * math.sqrt(2), 36.0), (0.0, 36.0)], 4, phase=PI / 4)
    for z in (10.0, 22.0, 33.0):
        w = 3.4 - (z - 3.0) / 33.0 * 1.4 + 0.25
        slab(G, 0, 0, w, w, z, z + 0.9, bevel=0.2)
    pyramid(TT, 0, 0, 2.3, 36.0, 42.0)
    finial(G, 0, 0, 41.5, 3.0, 0.6)
    return P.done(col, man)


def bell_tower(col, man, origin):
    """AL_BellTower 18x18x64: block base, open arched belfry on 4 sides with a gold bell, teal pyramid roof + finial."""
    P = C.Piece("AL_BellTower", origin)
    Mb, MB, G, TT = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile")
    slab(Mb, 0, 0, 9.0, 9.0, 0.0, 2.0, bevel=0.4)
    slab(MB, 0, 0, 7.5, 7.5, 2.0, 34.0, bevel=0.5)
    slab(G, 0, 0, 7.8, 7.8, 34.0, 35.0, bevel=0.2)
    for a in (0.0, PI / 2, PI, 3 * PI / 2):
        M = Matrix.Rotation(a, 4, "Z") @ T(0, -6.8, 35.0)
        C.arch_wall(Mb, 15.0, 14.0, 1.4, 9.0, 6.0, kind="round", bevel=0.25, n=14, M=M)
    slab(Mb, 0, 0, 8.4, 8.4, 49.0, 51.0, bevel=0.4)
    C.lathe(G, C.round_profile([(0.0, 46.0), (0.6, 46.0), (2.6, 40.0), (3.2, 38.0), (0.0, 38.0)], 0.2), 24)
    pyramid(TT, 0, 0, 8.6, 51.0, 62.0)
    finial(G, 0, 0, 61.5, 6.0, 1.0)
    return P.done(col, man)


def garden_shrine(col, man, origin):
    """AL_GardenShrine 16x16x22: plinth, 4 columns, teal hip roof with gold ridge finial, altar with a gold sun bowl."""
    P = C.Piece("AL_GardenShrine", origin)
    Mb, G, TT = P.bm("Marble"), P.bm("Gold"), P.bm("TealTile")
    slab(Mb, 0, 0, 8.0, 8.0, 0.0, 1.2, bevel=0.35)
    for x in (-5.8, 5.8):
        for y in (-5.8, 5.8):
            column(P, x, y, 1.2, 11.0, 0.65)
    slab(Mb, 0, 0, 7.6, 7.6, 12.2, 13.6, bevel=0.35)
    slab(G, 0, 0, 7.75, 7.75, 12.0, 12.4, bevel=0.1)
    pyramid(TT, 0, 0, 8.4, 13.6, 20.0)
    finial(G, 0, 0, 19.6, 3.4, 0.7)
    slab(Mb, 0, 0, 2.2, 1.6, 1.2, 4.6, bevel=0.3)
    C.lathe(G, C.round_profile([(0.0, 4.6), (1.6, 4.6), (2.0, 5.6), (0.0, 5.3)], 0.15), 20)
    return P.done(col, man)


def colonnade(col, man, origin):
    """AL_Colonnade 30x8x22: ruined stoa -- base, 3 columns, a lintel over two of them (the third broken short)."""
    P = C.Piece("AL_Colonnade", origin)
    Mb, G = P.bm("Marble"), P.bm("Gold")
    slab(Mb, 0, 0, 15.0, 4.0, 0.0, 1.5, bevel=0.4)
    column(P, -10.0, 0, 1.5, 18.0, 1.3)
    column(P, 0.0, 0, 1.5, 18.0, 1.3)
    C.drum(Mb, (10.0, 0), 1.5, 9.0, 1.3, sides=20, bevel=0.1)
    C.box(Mb, -13.5, -2.4, 19.5, 3.5, 2.4, 22.0, bevel=0.35)
    C.box(G, -13.4, -2.55, 19.3, 3.4, 2.55, 19.7, bevel=0.1)
    C.block(Mb, (12.0, 3.5, 2.4), (5.0, 3.0, 1.8), bevel=0.3, rot=(0.15, 0, 0.6))
    return P.done(col, man)


def lantern_arch(col, man, origin):
    """AL_LanternArch 20W x 3D x 22H: twin posts and a round arch over a path, two hanging capiz lanterns."""
    P = C.Piece("AL_LanternArch", origin)
    Mb, G, CZ = P.bm("Marble"), P.bm("Gold"), P.bm("Capiz")
    for sx in (-1, 1):
        slab(Mb, sx * 9.0, 0, 1.4, 1.4, 0.0, 14.0, bevel=0.3)
        slab(G, sx * 9.0, 0, 1.55, 1.55, 13.6, 14.2, bevel=0.1)
    C.arch_frame(Mb, 18.0, 14.0, 0.0, 2.4, frame=1.6, kind="round", bevel=0.25, n=18)
    finial(G, 0, 0, 23.4, 3.0, 0.7)
    for sx in (-1, 1):
        C.box(G, sx * 4.0 - 0.1, -0.1, 15.0, sx * 4.0 + 0.1, 0.1, 18.5, bevel=0.02)
        C.box(CZ, sx * 4.0 - 1.0, -1.0, 12.0, sx * 4.0 + 1.0, 1.0, 15.0, bevel=0.15)
        pyramid(G, sx * 4.0, 0, 1.3, 15.0, 16.3)
    return P.done(col, man)


def watchtower(col, man, origin):
    """AL_Watchtower d16 x 70H: round block tower, gold bands, crenellated walk, capiz window ring, teal cone roof."""
    P = C.Piece("AL_Watchtower", origin)
    Mb, MB, G, TT, CZ = P.bm("Marble"), P.bm("MarbleBlock"), P.bm("Gold"), P.bm("TealTile"), P.bm("Capiz")
    C.drum(Mb, (0, 0), 0.0, 2.5, 8.6, sides=32, bevel=0.4)
    C.drum(MB, (0, 0), 2.5, 44.0, 7.0, r_top=6.4, sides=32, bevel=0.3)
    for z in (16.0, 32.0):
        C.torus(G, (0, 0, z), 6.8 if z < 30 else 6.6, 0.4, seg=64, sides=8, uv=4.0)
    C.drum(CZ, (0, 0), 38.0, 5.0, 6.66, sides=32, bevel=0.1)  # proud of the shaft (r ~6.5): 6.45 was buried (B172 p3)
    C.drum(Mb, (0, 0), 46.5, 3.0, 8.4, sides=32, bevel=0.4)
    for x, y, a in C.polar(10, 7.8):
        C.block(Mb, (x, y, 50.6), (2.2, 1.6, 2.2), bevel=0.25, rot=(0, 0, a))
    C.lathe(TT, [(0.0, 49.5), (8.0, 49.5), (0.0, 64.0)], 32, uv=6.0)
    finial(G, 0, 0, 63.5, 6.0, 1.0)
    return P.done(col, man)


PIECES = [(story_gate, 92.0), (portal_ring, 72.0), (portal_veil, 54.0), (gem_shard, 5.0), (shard_obelisk, 11.0),
          (bell_tower, 18.0), (garden_shrine, 16.0), (colonnade, 30.0), (lantern_arch, 21.0), (watchtower, 17.0)]


def vfx_textures():
    """White-on-alpha 512 textures (tinted in Studio): portal swirl, soft glow, 4-point sparkle, light ray, rune ring."""
    S = 512
    y, x = np.mgrid[0:S, 0:S] / (S - 1) * 2 - 1
    r = np.sqrt(x * x + y * y)
    ang = np.arctan2(y, x)
    out = {}
    swirl = 0.5 + 0.5 * np.sin(ang * 5 + r * 14.0)
    out["portal"] = np.clip((1 - r) * 1.4, 0, 1) * (0.45 + 0.55 * swirl) + np.clip(1 - r * 3, 0, 1) * 0.6
    out["glow"] = np.clip(1 - r, 0, 1) ** 2.2
    star = np.clip(1 - np.minimum(np.abs(x) * 9, 1) - r * 0.6, 0, 1) + np.clip(1 - np.minimum(np.abs(y) * 9, 1) - r * 0.6, 0, 1)
    out["sparkle"] = np.clip(star + np.clip(1 - r * 4, 0, 1), 0, 1)
    out["ray"] = np.clip(1 - np.abs(x) * 1.6, 0, 1) ** 1.5 * np.clip((y + 1) / 2, 0, 1)
    ring = np.exp(-((r - 0.78) / 0.04) ** 2) + np.exp(-((r - 0.55) / 0.025) ** 2)
    ticks = (np.abs(np.sin(ang * 12)) > 0.92) * np.exp(-((r - 0.665) / 0.06) ** 2)
    out["rune"] = np.clip(ring + ticks, 0, 1)
    paths = {}
    for k, a in out.items():
        rgb = np.ones((S, S, 3))
        paths[k] = C.save_png("vfx_" + k, rgb, alpha=np.clip(a, 0, 1))
    return paths


def vfx_carrier(paths):
    col = C.clear_collection("AL_VfxCarrier")
    for i, (k, p) in enumerate(paths.items()):
        mat = bpy.data.materials.new("AL_Vfx_" + k + "_Mat")
        mat.use_nodes = True
        nt = mat.node_tree
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(p, check_existing=True)
        nt.links.new(tex.outputs["Color"], nt.nodes["Principled BSDF"].inputs["Base Color"])
        nt.links.new(tex.outputs["Alpha"], nt.nodes["Principled BSDF"].inputs["Alpha"])
        bm = bmesh.new()
        bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=2.0, calc_uvs=True)
        ob = C.mesh_object("AL_Vfx_" + k, bm, col, [mat])
        ob.data.name = "AL_Vfx_" + k
        ob.location = (i * 6.0, 0, 0)
    for o in bpy.context.view_layer.objects:
        o.select_set(o.name in col.objects)
    path = os.path.join(C.GLB, "AL_VfxCarrier.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_yup=True)
    return path


col = C.clear_collection("AL_KitD")
row = C.Row(gap=30.0)
manifest = {}
for build, width in PIECES:
    build(col, manifest, row.next(width))
info = C.export_kit(col, "D", manifest)
vpaths = vfx_textures()
carrier = vfx_carrier(vpaths)
renders = [] if globals().get("SKIP_RENDER") else [C.preview(col, C.render_path("AL_KitD"))]
bpy.ops.wm.save_mainfile()
result = {"export": info, "carrier": carrier, "renders": renders,
          "pieces": {n: {"size": e["size"], "tris": sum(C.tri_count(bpy.data.objects[o]) for o in e["objects"])} for n, e in manifest.items()}}
