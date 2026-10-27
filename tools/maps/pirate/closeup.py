# Bakunawa Cove -- close-up render of some kit pieces (z-fight / inside-out check, user rule 2026-10-24).
# PIECES = ["BC_Bush", ...] (from the kit manifests); NAME = output png name; VIEW = direction toward the camera.
import importlib.util
import os
import sys

import bpy

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)

man = C.load_manifests()
tmp = C.clear_collection("_BC_Closeup")
for i, p in enumerate(PIECES):
    C.instance(p, man, tmp, (0.0, 0.0, 0.0) if len(PIECES) == 1 else (i * globals().get("GAP", 8.0), 0.0, 0.0))
path = C.preview(tmp, C.render_path(globals().get("NAME", "closeup")), samples=24, view=globals().get("VIEW", (-0.78, -1.0, 0.62)))
C.clear_collection("_BC_Closeup")
bpy.data.collections.remove(tmp)
result = path
