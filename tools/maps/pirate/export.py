# Bakunawa Cove -- GLB export (B173). Writes glb/BC_Terrain.glb (anchor BC_AnchorT) and glb/BC_Kit<X>.glb for every
# kit collection (anchor BC_Anchor<X>, + its manifest). Run AFTER build_all.sh: the Studio assembly reads the kit
# manifests + layout_terrain.json + layout_props.json written by the build, and finds each file's import offset
# from its anchor cube. KITS = ["N", ...] exports a subset.
import importlib.util
import os
import sys

import bmesh
import bpy

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)


def export_collection(col, file_name, anchor_name):
    old = bpy.data.objects.get(anchor_name)
    if old is not None:
        bpy.data.objects.remove(old, do_unlink=True)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.5)
    C.mesh_object(anchor_name, bm, col, [])
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in col.all_objects:
        o.hide_set(False)
        o.select_set(True)
    path = os.path.join(C.GLB, file_name)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_animations=False, export_yup=True, export_normals=True, export_texcoords=True,
                              export_materials="EXPORT", export_image_format="AUTO")
    tris = C.report(col)
    return {"kb": os.path.getsize(path) // 1024, "objects": tris["objects"], "max_tris": tris["max"],
            "over_20k": tris["over_20k"]}


result = {}
result["BC_Terrain.glb"] = export_collection(bpy.data.collections["BC_Terrain"], "BC_Terrain.glb", "BC_AnchorT")
for letter in globals().get("KITS", ["N", "H", "V", "W", "L", "S"]):
    col = bpy.data.collections.get("BC_Kit" + letter)
    if col is not None:
        result["BC_Kit%s.glb" % letter] = export_collection(col, "BC_Kit%s.glb" % letter, "BC_Anchor" + letter)
