#!/usr/bin/env python3
"""Weight-aware Mixamo FBX decimator for crowd/DJ characters.

The crowd and DJ uploads are Mixamo *With Skin* exports (FBX 7.7): a 68-bone
``mixamorig`` armature, skinned mesh, embedded textures and one animation take.
The repo's ``decimate_fbx.py`` rebuilds static geometry only, so it would drop
the skin clusters and break the rig. This tool uses headless Blender instead:

  1. imports the FBX (armature, skin weights, materials, textures, action),
  2. applies a COLLAPSE Decimate modifier, which interpolates vertex groups so
     the skinning survives the collapse,
  3. packs the embedded images and re-exports FBX with the armature, skinned
     mesh, materials and the baked take.

Usage (needs a Blender 4.2+ binary; the game itself does not depend on Blender):

  blender --background --factory-startup --python godot/tools/decimate_mixamo_blender.py -- \
      <src.fbx> <dst.fbx> <target_triangles>

The output is intended to be imported into the Godot project; verify with
``godot --headless --path godot --script res://tools/probe_mixamo.gd``.
"""

import os
import sys

import bpy


def triangle_count(obj) -> int:
    mesh = obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def main() -> None:
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    if len(argv) != 3:
        raise SystemExit("usage: decimate_mixamo_blender.py <src.fbx> <dst.fbx> <target>")
    src, dst, target_raw = argv[0], argv[1], argv[2]
    target = int(target_raw)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.abspath(src))

    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    armatures = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    if not meshes:
        raise SystemExit("no mesh in %s" % src)

    before = sum(triangle_count(o) for o in meshes)
    ratio = min(1.0, float(target) / float(before))
    print("DECIMATE %s: %d tris -> target %d (ratio %.4f), %d bones"
          % (os.path.basename(src), before, target, ratio,
             len(armatures[0].data.bones) if armatures else 0))

    for obj in meshes:
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        modifier = obj.modifiers.new("MixamoDecimate", "DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = ratio
        modifier.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)

    after = sum(triangle_count(o) for o in meshes)
    for poly in meshes:
        poly.data.update()

    if bpy.data.images:
        bpy.ops.file.pack_all()

    bpy.ops.export_scene.fbx(
        filepath=os.path.abspath(dst),
        use_selection=False,
        apply_scale_options="FBX_SCALE_ALL",
        bake_anim=True,
        bake_anim_use_all_actions=True,
        bake_anim_force_startend_keying=True,
        add_leaf_bones=False,
        path_mode="COPY",
        embed_textures=True,
        mesh_smooth_type="FACE",
        object_types={"ARMATURE", "MESH"},
    )

    print("RESULT %s: %d -> %d tris, %d verts, actions %s, bytes %d"
          % (os.path.basename(dst), before, after,
             sum(len(o.data.vertices) for o in meshes),
             [a.name for a in bpy.data.actions], os.path.getsize(dst)))


if __name__ == "__main__":
    main()
