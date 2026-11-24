"""Export only the armature + take from a Mixamo FBX (no meshes, no textures).

Every uploaded fighter take carries a full copy of the fighter mesh and its textures, so shipping
all 38 of them as-is would put ~150 MB of duplicate geometry in the web export. Dropping the meshes
and images first leaves an armature with the take, ~0.45 MB per clip, which is all
`MixamoClips` needs — it re-points the tracks at the body that is already in the scene.

Usage:
    blender --background --factory-startup --python godot/tools/strip_anim.py -- <src.fbx> <dst.fbx>
"""
import os
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if len(argv) < 2:
    raise SystemExit("usage: strip_anim.py -- <src.fbx> <dst.fbx>")
src, dst = argv[0], argv[1]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.abspath(src))

for obj in list(bpy.context.scene.objects):
    if obj.type == "MESH":
        bpy.data.objects.remove(obj, do_unlink=True)
for img in list(bpy.data.images):
    bpy.data.images.remove(img)

bpy.ops.export_scene.fbx(
    filepath=os.path.abspath(dst),
    use_selection=False,
    object_types={"ARMATURE"},
    apply_scale_options="FBX_SCALE_ALL",
    bake_anim=True,
    bake_anim_use_all_actions=True,
    bake_anim_force_startend_keying=True,
    add_leaf_bones=False,
    path_mode="AUTO",
    embed_textures=False,
    mesh_smooth_type="FACE",
)
print("STRIP_OK %s bytes=%d actions=%s" % (os.path.basename(dst), os.path.getsize(dst),
                                           [a.name for a in bpy.data.actions]))
