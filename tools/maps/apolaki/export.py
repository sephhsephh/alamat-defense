# Apolaki Sun Terraces -- GLB export (B166). Writes glb/AST_Terrain.glb and glb/AST_Assets.glb,
# each with an "AST_Anchor" cube at the origin so the Studio assembly can find the import offset.
import os
import sys

import bmesh
import bpy

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402


def anchor(col, name):
    ob = bpy.data.objects.get(name)
    if ob is not None:
        bpy.data.objects.remove(ob, do_unlink=True)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=0.5)
    return C.mesh_object(name, bm, col, [])


def export(col_name, file_name, anchor_name):
    col = bpy.data.collections[col_name]
    anchor(col, anchor_name)
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    for o in col.objects:
        o.select_set(True)
    path = os.path.join(C.GLB, file_name)
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True, export_apply=True,
                              export_animations=False, export_yup=True, export_normals=True,
                              export_image_format="AUTO", export_materials="EXPORT")
    return path, os.path.getsize(path) // 1024


sc = C.scene()
bpy.context.window.scene = sc
result = {}
for col_name, fname, an in (("AST_Terrain", "AST_Terrain.glb", "AST_AnchorT"), ("AST_Assets", "AST_Assets.glb", "AST_AnchorA")):
    p, kb = export(col_name, fname, an)
    result[fname] = kb
