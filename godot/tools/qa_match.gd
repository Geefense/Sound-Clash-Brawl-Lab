extends RefCounted
## Shared driver for the QA capture tools (2026-11-26, PART A step 1).
##
## Every scenario these helpers serve boots the REAL `TestArena.tscn` — round controller,
## 3D yard, Mixamo bodies, hitboxes and all — and reaches its state by PLAYING A MATCH:
## P1 is driven by real `InputMap` actions, or P2 is driven by the sparring controller the
## game already ships. Nothing here assigns `state`, calls `change_state` or toggles a
## private flag, so a still can never show a pose the game cannot actually produce.
##
## The only non-match camera move is `look_at_world()`, used for prop/crowd stills where the
## subject is not the fight; it is restored by `restore_camera()` before the next capture.

const PX_PER_M := 140.0
const CENTER_PX := 640.0
const FLOOR_PX := 600.0


## Boot one arena. `ai_mode` is `MatchSetup.ai_mode` (0 dummy, 1 counter-puncher,
## 2 riddim rusher, 3 spacing baiter); mode 2 makes P2 attack without any player input.
static func boot(tree: SceneTree, a: StringName, b: StringName, ai_mode: int = 0,
		rounds: bool = false) -> Node:
	var setup = tree.root.get_node_or_null("MatchSetup")
	if setup == null:
		return null
	setup.commit_match(a, b)
	setup.ai_mode = ai_mode
	var packed := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := packed.instantiate()
	var rc := arena.get_node_or_null("RoundController")
	if rc != null and not rounds:
		rc.enabled = false
	tree.root.add_child(arena)
	await tree.process_frame
	await tree.physics_frame
	# Settle: the 3D layer builds in _ready and the animation player needs a frame to pose.
	for i in 6:
		await tree.physics_frame
	arena.p1.input_locked = false
	arena.p2.input_locked = false
	return arena


static func close(tree: SceneTree, arena) -> void:
	if arena == null:
		return
	arena.queue_free()
	await tree.process_frame
	await tree.process_frame


## Give P2 the same bindings P1 has. The shipped InputMap only registers `p1_*` actions
## (`BaseFighter._ensure_default_actions` returns early for any other prefix), so a QA run
## that wants to play P2 by hand has to register the mirror itself. This is exactly the
## binding a second local player would get: same actions, same events, same code path.
static func mirror_actions() -> int:
	var added := 0
	for action in InputMap.get_actions():
		var name := String(action)
		if not name.begins_with("p1_"):
			continue
		var mirrored := "p2_" + name.substr(3)
		if InputMap.has_action(mirrored):
			continue
		InputMap.add_action(mirrored)
		for event in InputMap.action_get_events(action):
			InputMap.action_add_event(mirrored, event)
		added += 1
	return added


## One human press: down, `hold` physics ticks, up, one settle tick.
static func press(tree: SceneTree, action: String, hold: int = 1) -> void:
	if not InputMap.has_action(action):
		return
	Input.action_press(action)
	for i in hold:
		await tree.physics_frame
	Input.action_release(action)
	await tree.physics_frame


# =========================================================================
# Capture
# =========================================================================
## llvmpipe spends nearly all of a match-driving tick rasterising the 3D yard. Toggling the
## viewport's `disable_3d` while no still is being taken makes a 20-second approach cost two
## seconds, without changing physics, input, combat or the skeleton pose (all CPU-side).
static func set_3d_off(tree: SceneTree, off: bool) -> void:
	tree.root.get_viewport().disable_3d = off


## Save the whole window (the 3D yard composited under the 2D HUD).
static func capture(tree: SceneTree, path: String) -> bool:
	await RenderingServer.frame_post_draw
	var tex := tree.root.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.is_empty():
		return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return img.save_png(path) == OK


## Save a zoomed crop around a screen point, for close inspection of a hand or a prop.
static func capture_crop(tree: SceneTree, path: String, centre_px: Vector2,
		size_px: Vector2i, zoom: int = 2) -> bool:
	await RenderingServer.frame_post_draw
	var tex := tree.root.get_texture()
	if tex == null:
		return false
	var img := tex.get_image()
	if img == null or img.is_empty():
		return false
	var full := Rect2i(Vector2i.ZERO, img.get_size())
	var rect := Rect2i(Vector2i(centre_px) - size_px / 2, size_px).intersection(full)
	if rect.size.x < 8 or rect.size.y < 8:
		return false
	var sub := img.get_region(rect)
	if zoom > 1:
		sub.resize(rect.size.x * zoom, rect.size.y * zoom, Image.INTERPOLATE_BILINEAR)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return sub.save_png(path) == OK


## Point the QA camera at a world position from `distance` metres away on +Z, remembering
## the look the match was using so `restore_camera()` can put it back.
static func look_at_world(arena3d, target: Vector3, distance: float = 4.0,
		height: float = 1.2) -> Dictionary:
	var cam: Camera3D = arena3d.camera
	if cam == null:
		return {}
	var saved := {"xf": cam.global_transform, "fov": cam.fov, "current": cam.current}
	cam.global_position = target + Vector3(0.0, height, distance)
	cam.look_at(target, Vector3.UP)
	return saved


static func restore_camera(arena3d, saved: Dictionary) -> void:
	if saved.is_empty() or arena3d == null or arena3d.camera == null:
		return
	arena3d.camera.global_transform = saved["xf"]
	arena3d.camera.fov = float(saved["fov"])


# =========================================================================
# Measurement
# =========================================================================
static func skeleton_of(model: Node3D) -> Skeleton3D:
	if model == null:
		return null
	return model.get("skeleton") as Skeleton3D


static func bone_index(skel: Skeleton3D, suffix: String) -> int:
	if skel == null:
		return -1
	for i in skel.get_bone_count():
		if String(skel.get_bone_name(i)).ends_with(suffix):
			return i
	return -1


## The toe line, foot->toe on both feet, flattened: the same direction the runtime facing pin
## uses, so "the way this body faces" means one thing everywhere.
static func toe_vector(model: Node3D) -> Vector3:
	var v := Vector3.ZERO
	for side in ["Left", "Right"]:
		var toe := bone_world(model, side + "ToeBase")
		var foot := bone_world(model, side + "Foot")
		if toe != Vector3.ZERO and foot != Vector3.ZERO:
			v += toe - foot
	if v == Vector3.ZERO:
		for pair in [["Toe.L", "Foot.L"], ["Toe.R", "Foot.R"]]:
			var toe2 := bone_world(model, pair[0])
			var foot2 := bone_world(model, pair[1])
			if toe2 != Vector3.ZERO and foot2 != Vector3.ZERO:
				v += toe2 - foot2
	v.y = 0.0
	return v.normalized() if v.length() > 0.0001 else Vector3.ZERO


static func bone_world(model: Node3D, suffix: String) -> Vector3:
	var skel := skeleton_of(model)
	var index := bone_index(skel, suffix)
	if index < 0:
		return Vector3.ZERO
	return (skel.global_transform * skel.get_bone_global_pose(index)).origin


static func bone_basis(model: Node3D, suffix: String) -> Basis:
	var skel := skeleton_of(model)
	var index := bone_index(skel, suffix)
	if index < 0:
		return Basis.IDENTITY
	return (skel.global_transform * skel.get_bone_global_pose(index)).basis.orthonormalized()


## Everything a downed-pose judgement needs, in world space, plus the presentation state
## that produced it. `up` is hips→head; `chest_n` is the Spine2 bone's own up axis.
static func pose_metrics(model: Node3D, face_hint: Vector3 = Vector3.ZERO) -> Dictionary:
	var skel := skeleton_of(model)
	var out := {"ok": false}
	if skel == null or model == null:
		return out
	var hips := bone_world(model, "Hips")
	var head := bone_world(model, "Head")
	var spine := bone_world(model, "Spine2")
	var foot_l := bone_world(model, "LeftFoot")
	var foot_r := bone_world(model, "RightFoot")
	if foot_l == Vector3.ZERO:
		foot_l = bone_world(model, "Foot.L")
	if foot_r == Vector3.ZERO:
		foot_r = bone_world(model, "Foot.R")
	var up: Vector3 = (head - hips).normalized() if (head - hips).length() > 0.0001 else Vector3.UP
	# The chest NORMAL is the chest's own outward direction, built from the shoulder line and
	# the spine, oriented to agree with the toe line: `up x side`. A standing body has it
	# horizontal (chest faces forward) and a body on its back has it on world up, which is
	# exactly what the knockdown acceptance means by "chest up".
	#
	# PART A4: this replaced `Spine2`'s local +Z. That axis is a rig convention, not a chest:
	# it measured +0.99 on one delivered body and -0.98 on another for the same lying pose
	# (Mixamo and Tripo disagree about which way a spine faces), so it could not be an
	# acceptance for all three. The shoulder line is anatomy and every rig has it.
	var chest_n: Vector3 = Vector3.UP
	var shoulder_l := bone_world(model, "LeftShoulder")
	var shoulder_r := bone_world(model, "RightShoulder")
	if shoulder_l != Vector3.ZERO and shoulder_r != Vector3.ZERO:
		var n := up.cross(shoulder_l - shoulder_r)
		if n.length() > 0.0001:
			chest_n = n.normalized()
			# The SIGN of `up × side` is a rig constant — measured standing, it points BACKWARD on
			# all three delivered bodies — so it is not re-decided per frame. The previous rule
			# flipped the normal toward the facing, which decides nothing once the body is lying
			# (the facing is perpendicular to the normal there): a supine Feedback scored -0.84
			# with its chest plainly up. Upright, the facing flip is kept so a rig that authors its
			# shoulders the other way round still reads correctly.
			var ref := face_hint if face_hint != Vector3.ZERO else toe_vector(model)
			if absf(up.y) > 0.5:
				if ref != Vector3.ZERO and chest_n.dot(ref) < 0.0:
					chest_n = -chest_n
			else:
				chest_n = -chest_n
	var bounds := skinned_bounds(model)
	out["ok"] = true
	out["hips"] = hips
	out["head"] = head
	out["spine2"] = spine
	out["foot_l"] = foot_l
	out["foot_r"] = foot_r
	out["up_y"] = up.y
	out["chest_ny"] = chest_n.y
	out["head_hips_dx"] = head.x - hips.x
	out["head_feet_dy"] = head.y - minf(foot_l.y, foot_r.y)
	out["low"] = bounds[0]
	out["high"] = bounds[1]
	out["drawn_low_y"] = bounds[0].y
	# The same measurement through the OTHER bone order, so a report can name the error
	# instead of inheriting it.
	out["drawn_low_y_unmapped"] = skinned_bounds(model, false)[0].y
	# Presentation state: the fall blend, the pose pivot's roll (the only fall rotation the
	# runtime applies today) and the downed-seat offset, so a still can be tied to its cause.
	out["fall"] = float(model.get("_fall"))
	out["pivot_rz_deg"] = rad_to_deg(_rotation_z_of(model.get("_pivot")))
	out["visual_yaw_deg"] = rad_to_deg(_rotation_y_of(model.get("_visual_pivot")))
	out["visual_seat_y"] = _position_y_of(model.get("_visual_pivot"))
	out["height"] = bounds[1].y - bounds[0].y if bounds[1].y > bounds[0].y else 0.0
	return out


static func _rotation_z_of(node) -> float:
	return float(node.rotation.z) if node is Node3D else 0.0


static func _rotation_y_of(node) -> float:
	return float(node.rotation.y) if node is Node3D else 0.0


static func _position_y_of(node) -> float:
	return float(node.position.y) if node is Node3D else 0.0


static func first_mesh(model: Node3D) -> MeshInstance3D:
	if model == null:
		return null
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null and mi.mesh.get_surface_count() > 0 and mi.skin != null:
			return mi
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi2 := child as MeshInstance3D
		if mi2 != null and mi2.mesh != null and mi2.mesh.get_surface_count() > 0:
			return mi2
	return null


## Live skinned-mesh bounds in world space — what the renderer actually draws.
##
## `skin` indices are SKIN BIND indices, not skeleton bone indices (`FighterModel3D`
## documents this: assuming the two orders match reports a body that never goes below its
## own foot bones, which is how Feedback came out "floating 72 cm"). Both readings are
## computed so a report can show the mapped one and the wrong one side by side.
static func skinned_bounds(model: Node3D, _mapped: bool = true) -> Array:
	# PART A2: one sampler for the runtime, the capture tools and every audit.
	return DrawnBounds.bounds(model)
