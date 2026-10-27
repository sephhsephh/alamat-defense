# Bakunawa Cove -- map preview renders (B173). Renders BC_Terrain + BC_Placed (kit collections stay hidden).
# SHOTS = ["overview", ...] picks named cameras below (default: all); ENGINE = "EEVEE" | "CYCLES"; RES = (w, h).
# Output: Downloads/BakunawaCove_Map/renders/<shot>.png
import importlib.util
import math
import os
import sys

import bpy
from mathutils import Vector

PIRATE = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\pirate"
_s = importlib.util.spec_from_file_location("bc_common", os.path.join(PIRATE, "common.py"))
C = importlib.util.module_from_spec(_s)
sys.modules["bc_common"] = C
_s.loader.exec_module(C)

CAMS = {  # name: (location, target, lens)
    "overview": ((-60, -370, 240), (0, 20, 0), 30),
    "top": ((0, 5, 760), (0, 8, 0), 32),
    "harbour": ((-200, -80, 34), (-140, -6, 2), 28),
    "skull": ((46, 20, 24), (88, 92, 16), 26),
    "fortress": ((4, 40, 44), (-24, 124, 48), 24),
    "village": ((-46, 70, 30), (-46, 150, 6), 26),
    "plaza": ((-16, 108, 40), (-46, 140, 4), 26),
    "islets": ((-150, -40, 60), (-232, 100, 10), 30),
    "wreck": ((110, -180, 26), (162, -122, 2), 30),
    "player": ((0, -150, 105), (0, 0, 0), 30),
}


def setup(engine):
    sc = C.scene()
    for col in bpy.data.collections:
        if col.name.startswith("BC_Kit"):
            col.hide_render = True
    sc.render.resolution_x, sc.render.resolution_y = globals().get("RES", (1600, 900))
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = 0.0
    if engine == "CYCLES":
        sc.render.engine = "CYCLES"
        sc.cycles.device = "CPU"
        sc.cycles.samples = 32
        sc.cycles.use_denoising = True
    else:
        sc.render.engine = "BLENDER_EEVEE"
        try:
            sc.eevee.taa_render_samples = 32
            sc.eevee.use_shadows = True
        except Exception:
            pass
    sun = bpy.data.objects.get("_BC_Sun")
    if sun is None:
        sun = bpy.data.objects.new("_BC_Sun", bpy.data.lights.new("_BC_Sun", "SUN"))
        sc.collection.objects.link(sun)
    sun.data.energy = 3.6
    sun.data.color = (1.0, 0.93, 0.80)
    sun.data.angle = math.radians(3)
    sun.rotation_euler = (math.radians(42), 0, math.radians(-38))
    world = sc.world or bpy.data.worlds.new("_BC_World")
    sc.world = world
    if world.node_tree is None:
        world.use_nodes = True
    nt = world.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputWorld")
    bg = nt.nodes.new("ShaderNodeBackground")
    grad = nt.nodes.new("ShaderNodeTexGradient")
    mapn = nt.nodes.new("ShaderNodeMapping")
    tc = nt.nodes.new("ShaderNodeTexCoord")
    rmp = nt.nodes.new("ShaderNodeValToRGB")
    nt.links.new(tc.outputs["Generated"], mapn.inputs["Vector"])
    mapn.inputs["Rotation"].default_value = (0, math.radians(-90), 0)
    nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
    nt.links.new(grad.outputs["Fac"], rmp.inputs["Fac"])
    rmp.color_ramp.elements[0].color = (0.98, 0.90, 0.78, 1)
    rmp.color_ramp.elements[1].color = (0.30, 0.58, 0.95, 1)
    nt.links.new(rmp.outputs["Color"], bg.inputs["Color"])
    bg.inputs["Strength"].default_value = 0.9
    nt.links.new(bg.outputs["Background"], out.inputs["Surface"])
    # optional haze (HAZE > 0): a world volume fills ALL space and also dims the sun, so keep it tiny (~0.0002).
    # The real haze is the Studio Atmosphere (README).
    if globals().get("HAZE", 0.0) <= 0:
        return sc
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Color"].default_value = (0.72, 0.86, 0.95, 1)
    vol.inputs["Density"].default_value = HAZE
    nt.links.new(vol.outputs["Volume"], out.inputs["Volume"])
    return sc


def shoot(sc, name):
    loc, tgt, lens = CAMS[name]
    cam = bpy.data.objects.get("_BC_Cam")
    if cam is None:
        cam = bpy.data.objects.new("_BC_Cam", bpy.data.cameras.new("_BC_Cam"))
        sc.collection.objects.link(cam)
    cam.data.lens = lens
    cam.data.clip_end = 4000
    cam.location = Vector(loc)
    cam.rotation_mode = "QUATERNION"
    cam.rotation_quaternion = (Vector(tgt) - Vector(loc)).to_track_quat("-Z", "Y")
    sc.camera = cam
    path = os.path.join(C.RENDERS, name + ".png")
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    return path


sc = setup(globals().get("ENGINE", "EEVEE"))
result = [shoot(sc, n) for n in globals().get("SHOTS", list(CAMS))]
