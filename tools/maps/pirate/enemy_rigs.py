# Bakunawa Cove -- Stage 2 ENEMY RIG PARTS (B175). Run on the characters file AFTER characters.py:
#   BLEND_FILE=<Downloads\BakunawaCove_Map\BakunawaCove_Characters.blend> sh tools/maps/pirate/run.sh enemy_rigs.py save
# Writes glb/BC_EnemyRigs.glb + glb/BC_EnemyRigs.json for tools/enemy_rigs/build_stage2_rigs.luau (Game Place).
#
# RIGID R15 SPLIT: every loose piece (ellipsoid, tube, cloth band...) of a character goes to the R15 body part whose
# bone segment is nearest its centre (score = distance - the bone's radius), then pieces are joined per
# <Char>_<Part>__<Mat>. In Studio each piece is welded to the matching part of a cloned R15 Grunt whose joints are
# MOVED onto this model's joints (the J_* marker cubes), so the Grunt's Walk/Run clips drive the real model.
# Characters (front -Y, origin between the feet, 1 unit = 1 stud; LEFT = +X, the character's own left):
#   SkeletonPirate  (grunt)   = BC_SkeletonPirate from characters.py
#   PirateBrute     (tank)    = BC_Captain from characters.py (English enemy name; the captain look)
#   CursedGull      (flyer)   = built here: wings on the arm bones (Studio turns the arm swing into a flap)
import importlib.util
import json
import math
import os
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
NS = {"__name__": "bc_characters"}
_src = open(os.path.join(PIRATE, "characters.py"), encoding="utf-8").read().replace("result = build()", "")
exec(compile(_src, "characters.py", "exec"), NS)
C, ell, limb, T, D, PI = NS["C"], NS["ell"], NS["limb"], NS["T"], NS["D"], NS["PI"]


def mirror(j):
    """Left joints given on +X -> add the Right (-X) copies."""
    out = dict(j)
    for k, v in j.items():
        if k.startswith("Left"):
            out["Right" + k[4:]] = (-v[0], v[1], v[2])
    return out


def hand_end(j, side, length):
    w, e = Vector(j[side + "Wrist"]), Vector(j[side + "Elbow"])
    j[side + "HandEnd"] = tuple(w + (w - e).normalized() * length)


SEGMENTS = {  # part: [(jointA, jointB)], radius key
    "Head": [("Neck", "HeadTop")], "UpperTorso": [("Waist", "Neck")],
    "LowerTorso": [("Root", "Waist"), ("LeftHip", "RightHip")],
}
for s in ("Left", "Right"):
    SEGMENTS.update({
        s + "UpperArm": [(s + "Shoulder", s + "Elbow")], s + "LowerArm": [(s + "Elbow", s + "Wrist")],
        s + "Hand": [(s + "Wrist", s + "HandEnd")], s + "UpperLeg": [(s + "Hip", s + "Knee")],
        s + "LowerLeg": [(s + "Knee", s + "Ankle")], s + "Foot": [(s + "Ankle", s + "Toe")],
    })
RADIUS = {"Head": 0.45, "UpperTorso": 0.5, "LowerTorso": 0.45, "UpperArm": 0.12, "LowerArm": 0.1, "Hand": 0.1,
          "UpperLeg": 0.12, "LowerLeg": 0.1, "Foot": 0.12}

# ---------------------------------------------------------------- the two pirates (joints read off characters.py)
SKEL = mirror({
    "Root": (0.0, 0.05, 2.92), "Waist": (0.0, 0.15, 3.2), "Neck": (0.0, 0.05, 4.6), "HeadTop": (0.0, 0.0, 6.4),
    "LeftShoulder": (0.76, 0.0, 4.56), "LeftElbow": (0.98, -0.42, 3.95), "LeftWrist": (0.9, -1.02, 4.32),
    "LeftHip": (0.32, 0.05, 2.82), "LeftKnee": (0.36, -0.06, 1.6), "LeftAnkle": (0.36, 0.02, 0.28),
    "LeftToe": (0.36, -0.66, 0.05),
})
SKEL["RightElbow"], SKEL["RightWrist"] = (-0.95, -0.06, 3.72), (-1.02, -0.22, 2.95)  # the hanging arm
hand_end(SKEL, "Left", 0.45)
hand_end(SKEL, "Right", 0.45)

CAPT = mirror({
    "Root": (0.0, 0.0, 3.05), "Waist": (0.0, 0.0, 3.3), "Neck": (0.0, 0.0, 4.65), "HeadTop": (0.0, 0.05, 7.1),
    "LeftShoulder": (1.0, 0.0, 4.55), "LeftElbow": (1.32, -0.06, 3.6), "LeftWrist": (1.38, -0.28, 2.88),
    "LeftHip": (0.44, 0.0, 3.05), "LeftKnee": (0.47, -0.04, 1.75), "LeftAnkle": (0.48, 0.0, 0.3),
    "LeftToe": (0.48, -0.8, 0.12),
})
hand_end(CAPT, "Left", 0.5)
hand_end(CAPT, "Right", 0.5)


def capt_override(c, mat):
    if c.x < -0.85 and c.z < 3.2:
        return "LowerTorso"  # the scabbard on the right hip hangs from the belt
    return None


# ---------------------------------------------------------------- the cursed gull (new, flyer)
GULL_Z = 1.3
GULL = mirror({
    "Root": (0.0, 0.1, 1.15), "Waist": (0.0, 0.35, 1.22), "Neck": (0.0, -0.5, 1.38), "HeadTop": (0.0, -1.0, 1.5),
    "LeftShoulder": (0.3, -0.05, GULL_Z), "LeftElbow": (1.05, 0.0, GULL_Z), "LeftWrist": (1.6, 0.1, GULL_Z),
    "LeftHandEnd": (1.95, 0.15, GULL_Z),
    "LeftHip": (0.12, 0.15, 1.02), "LeftKnee": (0.12, 0.15, 0.88), "LeftAnkle": (0.12, 0.12, 0.74),
    "LeftToe": (0.12, -0.08, 0.68),
})


def gull_override(c, mat):
    if c.y > 0.55:
        return "LowerTorso"  # tail fan
    return None


def gull(col, man, origin):
    """BC_CursedGull: a ghostly bone-white sea gull with glowing eyes, ragged dark wing tips and tail, gold beak.
    Wings lie flat in the XY plane (inner white + outer dark panels share an edge -- no overlap)."""
    P = C.Piece("BC_CursedGull", origin)
    BN, GL, CD, G = P.bm("Bone"), P.bm("Glow"), P.bm("ClothDark"), P.bm("Gold")
    ell(BN, (0.0, 0.0, 1.2), (0.36, 0.72, 0.34), 16, 8)              # body
    ell(BN, (0.0, -0.72, 1.44), (0.25, 0.27, 0.25), 14, 7)           # head
    ell(G, (0.0, -1.04, 1.38), (0.07, 0.2, 0.06), 10, 5)             # beak
    ell(G, (0.0, -1.2, 1.33), (0.05, 0.06, 0.05), 8, 4)              # hooked tip
    for s in (-1, 1):
        ell(GL, (s * 0.19, -0.86, 1.5), (0.05, 0.045, 0.055), 8, 4)  # glowing eyes (stand proud of the head)
        flat = T(0.0, 0.0, GULL_Z) @ Matrix.Rotation(PI / 2, 4, "X") @ D(s, 1.0, 1.0)  # profile (x, -y), z-thick
        C.prism(BN, [(0.28, 0.32), (1.05, 0.26), (1.2, -0.38), (0.28, -0.4)], -0.04, 0.04, bevel=0.0, M=flat)
        C.prism(CD, [(1.05, 0.26), (1.95, -0.12), (1.72, -0.34), (1.45, -0.5), (1.2, -0.38)], -0.04, 0.04,
                bevel=0.0, M=flat)
        ell(G, (s * 0.12, 0.12, 0.72), (0.07, 0.16, 0.05), 8, 4)    # tucked feet
    C.prism(CD, [(-0.18, -0.62), (0.18, -0.62), (0.32, -1.08), (0.0, -0.96), (-0.32, -1.08)], -0.03, 0.03,
            bevel=0.0, M=T(0.0, 0.0, 1.16) @ Matrix.Rotation(PI / 2, 4, "X"))  # tail fan behind the body (+Y)
    P.smooth.update({"Bone": 60.0})
    return P.done(col, man)


# ---------------------------------------------------------------- split + export
def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


def assign(c, joints, override, mat):
    o = override(c, mat) if override else None
    if o:
        return o
    best, bp = 1e9, None
    for part, segs in SEGMENTS.items():
        r = RADIUS[part.replace("Left", "").replace("Right", "")]
        for ja, jb in segs:
            d = seg_dist(c, Vector(joints[ja]), Vector(joints[jb])) - r
            if d < best:
                best, bp = d, part
    return bp


def select_only(objs, active):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = active


def split_character(src, name, origin, joints, override, out_col, report):
    ox = Vector(origin)
    groups = {}
    for ob in [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith(src + "__")]:
        mat = ob.name.split("__", 1)[1]
        dup = ob.copy()
        dup.data = ob.data.copy()
        out_col.objects.link(dup)
        select_only([dup], dup)
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.mesh.separate(type="LOOSE")
        bpy.ops.object.mode_set(mode="OBJECT")
        pieces = [o for o in bpy.context.selected_objects]
        for pc in pieces:
            vs = pc.data.vertices
            c = sum((pc.matrix_world @ v.co for v in vs), Vector()) / max(1, len(vs)) - ox
            part = assign(c, joints, override, mat)
            groups.setdefault((part, mat), []).append(pc)
    for (part, mat), objs in groups.items():
        select_only(objs, objs[0])
        if len(objs) > 1:
            bpy.ops.object.join()
        o = bpy.context.view_layer.objects.active
        o.name = "%s_%s__%s" % (name, part, mat)
        o.data.name = o.name
        report.setdefault(name, {}).setdefault(part, []).append(mat)
    # joint markers (tiny cubes) -- they travel through the importer with the meshes
    for jn, p in list(joints.items()) + [("Front", (0.0, -2.0, joints["Neck"][2]))]:
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=0.08)
        C.mesh_object("%s_J_%s" % (name, jn), bm, out_col, [])
        bpy.data.objects["%s_J_%s" % (name, jn)].location = ox + Vector(p)


def build():
    report = {}
    chars = C.collection("BC_Characters")
    for o in [o for o in chars.objects if o.name.startswith("BC_CursedGull__")]:
        bpy.data.objects.remove(o, do_unlink=True)
    gull(chars, {}, (18.0, 0.0, 0.0))
    out = C.collection("BC_EnemyRigs")
    for o in list(out.objects):
        bpy.data.objects.remove(o, do_unlink=True)
    split_character("BC_SkeletonPirate", "SkeletonPirate", (10.0, 0.0, 0.0), SKEL, None, out, report)
    split_character("BC_Captain", "PirateBrute", (2.0, 0.0, 0.0), CAPT, capt_override, out, report)
    split_character("BC_CursedGull", "CursedGull", (18.0, 0.0, 0.0), GULL, gull_override, out, report)
    zf = C.zfight_report(out)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in out.all_objects:
        o.hide_set(False)
        o.select_set(True)
    path = os.path.join(C.GLB, "BC_EnemyRigs.glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_animations=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="EXPORT", export_image_format="AUTO")
    data = {"origins": {"SkeletonPirate": (10, 0, 0), "PirateBrute": (2, 0, 0), "CursedGull": (18, 0, 0)},
            "joints": {"SkeletonPirate": SKEL, "PirateBrute": CAPT, "CursedGull": GULL}, "parts": report}
    with open(os.path.join(C.GLB, "BC_EnemyRigs.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)
    if globals().get("PREVIEW", True):
        C.preview(out, C.render_path("enemy_rigs"), samples=24, lens=50.0, view=(-0.6, -1.0, 0.2), res=(1400, 800))
    return {"kb": os.path.getsize(path) // 1024, "zfight": zf,
            "parts": {k: sorted(v.keys()) for k, v in report.items()}}


result = build()
