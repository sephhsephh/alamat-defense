# Apolaki Sun Terraces -- EEVEE preview renders (B166). Set CAM = (location, target) before exec.
import math
import os
import sys

import bpy
from mathutils import Vector

TOOLS = r"C:\Users\Joseph Elton Estilo\Documents\alamat-defense\tools\maps\apolaki"
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)
import common as C  # noqa: E402

sc = C.scene()
bpy.context.window.scene = sc
sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE_NEXT"
sc.render.resolution_x, sc.render.resolution_y = 1280, 720
sc.view_settings.view_transform = "Standard"
sc.view_settings.look = "None"

# golden-hour sun + gradient sky
sun = bpy.data.objects.get("_PrevSun")
if sun is None:
    sun = bpy.data.objects.new("_PrevSun", bpy.data.lights.new("_PrevSun", "SUN"))
    sc.collection.objects.link(sun)
sun.data.energy = 4.0
sun.data.color = (1.0, 0.86, 0.66)
sun.data.angle = math.radians(3)
sun.rotation_euler = (math.radians(58), 0, math.radians(-120))

world = sc.world or bpy.data.worlds.new("_PrevWorld")
sc.world = world
world.use_nodes = True
nt = world.node_tree
nt.nodes.clear()
out = nt.nodes.new("ShaderNodeOutputWorld")
bg = nt.nodes.new("ShaderNodeBackground")
grad = nt.nodes.new("ShaderNodeTexGradient")
mapn = nt.nodes.new("ShaderNodeMapping")
tc = nt.nodes.new("ShaderNodeTexCoord")
ramp = nt.nodes.new("ShaderNodeValToRGB")
nt.links.new(tc.outputs["Generated"], mapn.inputs["Vector"])
mapn.inputs["Rotation"].default_value = (0, math.radians(-90), 0)
nt.links.new(mapn.outputs["Vector"], grad.inputs["Vector"])
nt.links.new(grad.outputs["Fac"], ramp.inputs["Fac"])
ramp.color_ramp.elements[0].color = (1.0, 0.62, 0.36, 1)
ramp.color_ramp.elements[1].color = (0.32, 0.55, 0.85, 1)
nt.links.new(ramp.outputs["Color"], bg.inputs["Color"])
bg.inputs["Strength"].default_value = 1.1
nt.links.new(bg.outputs["Background"], out.inputs["Surface"])

cam = bpy.data.objects.get("_PrevCam")
if cam is None:
    cam = bpy.data.objects.new("_PrevCam", bpy.data.cameras.new("_PrevCam"))
    sc.collection.objects.link(cam)
loc, tgt = globals().get("CAM", ((-70, -60, 22), (0, 5, 0)))
cam.location = Vector(loc)
cam.rotation_mode = "QUATERNION"
cam.rotation_quaternion = (Vector(tgt) - Vector(loc)).to_track_quat("-Z", "Y")
cam.data.lens = globals().get("LENS", 24)
cam.data.clip_end = 3000
sc.camera = cam
# hide the prototype collection (they sit at the origin)
for c in sc.collection.children:
    c.hide_render = (c.name == "AST_Assets")
name = globals().get("SHOT", "preview")
path = os.path.join(C.RENDERS, name + ".png")
sc.render.filepath = path
bpy.ops.render.render(write_still=True)
result = {"path": path}
