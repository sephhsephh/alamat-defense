# tools/maps/lobby/split_heavy.py (B172) -- Roblox meshes cap at 20k tris. Any kit object over LIMIT is split by loose
# parts and re-packed into chunks <= LIMIT named <name>_1.._n (same <Piece>__<Mat> prefix, so Studio grouping holds),
# then the kit is re-exported. Run on a kit .blend:  KIT = "B"; exec(open(r"<repo>/tools/maps/lobby/split_heavy.py").read())
import bpy, bmesh, json, os, sys, importlib.util
LOBBY = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\lobby"
_s = importlib.util.spec_from_file_location("al_common", os.path.join(LOBBY, "common.py"))
C = importlib.util.module_from_spec(_s); sys.modules["al_common"] = C; _s.loader.exec_module(C)
LIMIT = 18000
col = bpy.data.collections["AL_Kit" + KIT]

def tris(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)

split = {}
for ob in [o for o in col.objects if o.type == "MESH"]:
    if tris(ob) <= LIMIT:
        continue
    base = ob.name
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    parts = sorted(bpy.context.selected_objects, key=lambda o: -tris(o))
    bins = []  # first-fit decreasing
    for p in parts:
        for b in bins:
            if b["t"] + tris(p) <= LIMIT:
                b["o"].append(p); b["t"] += tris(p); break
        else:
            bins.append({"o": [p], "t": tris(p)})
    names = []
    for i, b in enumerate(bins, 1):
        for o in bpy.context.view_layer.objects:
            o.select_set(False)
        for o in b["o"]:
            o.select_set(True)
        bpy.context.view_layer.objects.active = b["o"][0]
        if len(b["o"]) > 1:
            bpy.ops.object.join()
        j = bpy.context.view_layer.objects.active
        j.name = j.data.name = f"{base}_{i}"
        names.append((j.name, b["t"]))
    split[base] = names

man = json.load(open(os.path.join(C.GLB, f"AL_Kit{KIT}.json")))
for piece, info in man.items():
    objs = []
    for o in info["objects"]:
        objs += [n for n, _ in split[o]] if o in split else [o]
    info["objects"] = objs
info = C.export_kit(col, KIT, man)
bpy.ops.wm.save_mainfile()
result = {"split": split, "export": info}
