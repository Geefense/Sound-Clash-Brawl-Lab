#!/usr/bin/env python3
"""Skin a static fighter upload onto a Mixamo rig and export a game-ready FBX.

The three owner fighter uploads (``feedback_v2.fbx``, ``lickshot.fbx``,
``likkle_moore.fbx``) are single-surface Tripo exports: one mesh, one material,
UVs, and **no armature, no vertex groups, no animation**. The 38 Mixamo
animation clips are all ``With Skin`` exports of the same 68-bone
``mixamorig`` skeleton, so the clips can only drive a fighter that carries that
skeleton.

This tool bridges the two:

  1. imports the static fighter mesh and applies its root transform,
  2. imports a donor Mixamo export and keeps only its armature,
  3. scales the donor armature to the fighter's own height and seats its feet
     on the mesh's floor line,
  4. binds the mesh to the armature (bone-heat automatic weights, with a
     distance-falloff solver as the fallback for meshes bone heat cannot solve),
  5. exports an FBX that keeps the fighter's UVs, material and embedded atlas,
     with the armature named ``Armature`` so Godot's importer produces the same
     ``Armature/Skeleton3D:mixamorig_*`` track paths the clips use.

Usage (Blender 4.2+; the game itself never depends on Blender):

  blender --background --factory-startup --python godot/tools/retarget_mixamo_blender.py -- \
      <fighter_mesh.fbx> <donor_rig.fbx> <out.fbx> [height_metres] [auto|falloff]

Everything here is a build step. The exported FBX is what the game loads.
"""

import os
import sys

import bpy
from mathutils import Vector


def parse_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    if len(argv) < 3:
        raise SystemExit("usage: retarget_mixamo_blender.py <mesh.fbx> <donor.fbx> <out.fbx> "
                         "[height] [auto|falloff]")
    mesh, donor, out = argv[0], argv[1], argv[2]
    height = float(argv[3]) if len(argv) > 3 else 0.0
    mode = argv[4] if len(argv) > 4 else "auto"
    return mesh, donor, out, height, mode


def world_bbox(objects):
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for obj in objects:
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            lo = Vector((min(lo.x, point.x), min(lo.y, point.y), min(lo.z, point.z)))
            hi = Vector((max(hi.x, point.x), max(hi.y, point.y), max(hi.z, point.z)))
    return lo, hi


def armature_bbox(arm):
    """Rest-pose bounds from every bone head/tail in world space."""
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    for bone in arm.data.bones:
        for point in (arm.matrix_world @ bone.head_local, arm.matrix_world @ bone.tail_local):
            lo = Vector((min(lo.x, point.x), min(lo.y, point.y), min(lo.z, point.z)))
            hi = Vector((max(hi.x, point.x), max(hi.y, point.y), max(hi.z, point.z)))
    return lo, hi


def apply_transform(obj):
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def falloff_weights(mesh_obj, arm, max_influences=4, power=3.0):
    """Distance-to-bone-segment weighting; used when bone heat fails."""
    import mathutils

    bones = [b for b in arm.data.bones if b.use_deform]
    segments = []
    for bone in bones:
        head = arm.matrix_world @ bone.head_local
        tail = arm.matrix_world @ bone.tail_local
        segments.append((bone.name, head, tail))

    for group in list(mesh_obj.vertex_groups):
        mesh_obj.vertex_groups.remove(group)
    groups = {name: mesh_obj.vertex_groups.new(name=name) for name, _, _ in segments}

    mesh = mesh_obj.data
    for vert in mesh.vertices:
        point = mesh_obj.matrix_world @ vert.co
        scored = []
        for name, head, tail in segments:
            axis = tail - head
            length_sq = axis.length_squared
            if length_sq < 1e-9:
                dist = (point - head).length
            else:
                t = max(0.0, min(1.0, (point - head).dot(axis) / length_sq))
                dist = (point - (head + axis * t)).length
            scored.append((1.0 / ((dist + 0.01) ** power), name))
        scored.sort(reverse=True)
        top = scored[:max_influences]
        total = sum(w for w, _ in top) or 1.0
        for weight, name in top:
            groups[name].add([vert.index], weight / total, "REPLACE")
    return len(segments)


def main():
    mesh_path, donor_path, out_path, target_height, mode = parse_args()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.abspath(mesh_path))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in %s" % mesh_path)
    for obj in meshes:
        apply_transform(obj)

    # Join the fighter's surfaces into one skinned body so the runtime sees one mesh.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    body = meshes[0]
    bpy.context.view_layer.objects.active = body
    if len(meshes) > 1:
        bpy.ops.object.join()
    body.name = "Body"
    body.data.name = "BodyMesh"
    body_lo, body_hi = world_bbox([body])
    body_height = body_hi.z - body_lo.z
    print("BODY bbox=%s..%s height=%.4f tris=%d" % (
        [round(v, 4) for v in body_lo], [round(v, 4) for v in body_hi], body_height,
        sum(len(p.vertices) - 2 for p in body.data.polygons)))

    # Donor: keep the armature only.
    bpy.ops.import_scene.fbx(filepath=os.path.abspath(donor_path))
    arms = [o for o in bpy.context.scene.objects if o.type == "ARMATURE"]
    if not arms:
        raise SystemExit("no armature in %s" % donor_path)
    arm = arms[0]
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj not in meshes:
            bpy.data.objects.remove(obj, do_unlink=True)
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)

    arm_lo, arm_hi = armature_bbox(arm)
    arm_height = arm_hi.z - arm_lo.z
    if arm_height <= 1e-6:
        raise SystemExit("donor armature has zero height")

    wanted = target_height if target_height > 0.0 else body_height
    scale = wanted / arm_height
    arm.scale = (arm.scale.x * scale, arm.scale.y * scale, arm.scale.z * scale)
    bpy.context.view_layer.update()

    arm_lo, arm_hi = armature_bbox(arm)
    offset = Vector((
        (body_lo.x + body_hi.x) * 0.5 - (arm_lo.x + arm_hi.x) * 0.5,
        (body_lo.y + body_hi.y) * 0.5 - (arm_lo.y + arm_hi.y) * 0.5,
        body_lo.z - arm_lo.z,
    ))
    arm.location = arm.location + offset
    bpy.context.view_layer.update()
    apply_transform(arm)
    arm.name = "Armature"
    arm.data.name = "Armature"

    def parent_with(weight_mode):
        bpy.ops.object.select_all(action="DESELECT")
        body.select_set(True)
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        if weight_mode == "auto":
            bpy.ops.object.parent_set(type="ARMATURE_AUTO")
        else:
            bpy.ops.object.parent_set(type="ARMATURE_NAME")
            made = falloff_weights(body, arm)
            print("FALLOFF bones=%d" % made)
            if not any(m.type == "ARMATURE" for m in body.modifiers):
                mod = body.modifiers.new("Armature", "ARMATURE")
                mod.object = arm

    if mode == "falloff":
        parent_with("falloff")
    else:
        try:
            parent_with("auto")
            groups = len(body.vertex_groups)
            print("AUTO groups=%d" % groups)
            if groups < 20:
                print("AUTO_TOO_FEW -> falloff")
                parent_with("falloff")
        except RuntimeError as exc:  # bone heat failure
            print("AUTO_FAILED %s -> falloff" % exc)
            parent_with("falloff")

    deform = sum(1 for b in arm.data.bones if b.use_deform)
    weighted = sum(1 for v in body.data.vertices if len(v.groups) > 0)
    total_weight = sum(g.weight for v in body.data.vertices for g in v.groups)
    print("RIG bones=%d deform=%d groups=%d weighted=%d/%d weightsum=%.2f" % (
        len(arm.data.bones), deform, len(body.vertex_groups), weighted,
        len(body.data.vertices), total_weight))

    # Mixamo's own exports hang the skinned mesh off the Hips bone, and that is what makes
    # Godot's FBX importer mount the mesh under the Skeleton3D with a real Skin. Parenting to
    # the armature object instead leaves the mesh as a plain sibling with no skin at all.
    hips = None
    for bone in arm.data.bones:
        if bone.name.endswith("Hips"):
            hips = bone
            break
    if hips is not None:
        bpy.ops.object.select_all(action="DESELECT")
        body.select_set(True)
        arm.select_set(True)
        bpy.context.view_layer.objects.active = arm
        arm.data.bones.active = hips
        bpy.ops.object.parent_set(type="BONE", keep_transform=True)
        print("BONE_PARENT %s" % hips.name)

    if bpy.data.images:
        bpy.ops.file.pack_all()

    bpy.ops.export_scene.fbx(
        filepath=os.path.abspath(out_path),
        use_selection=False,
        object_types={"ARMATURE", "MESH"},
        apply_scale_options="FBX_SCALE_ALL",
        bake_anim=False,
        add_leaf_bones=False,
        path_mode="COPY",
        embed_textures=True,
        mesh_smooth_type="FACE",
    )
    print("RETARGET_OK %s bytes=%d" % (os.path.basename(out_path), os.path.getsize(out_path)))


if __name__ == "__main__":
    main()
