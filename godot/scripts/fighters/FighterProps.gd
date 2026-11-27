class_name FighterProps
extends RefCounted
## Hand-prop slots for the three roster fighters (owner request, 2026-11-24; procedural
## geometry removed in the playtest fix of the same date).
##
## The fighter bodies are the owner's own Mixamo exports, so they carry a real
## `mixamorig_RightHand` bone. Each prop is a `PropLoader` under a `BoneAttachment3D` on that
## bone, which means it follows every take — jab, hook, block, stumble, knockout — and keeps
## the same hand whichever way the fighter faces: nothing here mirrors.
##
## Feedback and L!ckshot hold a wireless stage microphone; L!kkle Moore holds his microphone
## stand in the same hand he used to swing with. The models are **not** built in code any
## more: a missing `.glb` leaves the hand empty and logs one warning.
##
## Presentation only: no prop is read by the combat simulation, no hitbox is derived from it,
## and removing one changes nothing but the picture.

const MIC_MODEL := "res://assets/models/props/wireless_mic.glb"
const STAND_MODEL := "res://assets/models/props/mic_stand.glb"

const HAND_BONE := "mixamorig_RightHand"
## Fallback bone names, in order, if an export ever renames the right hand.
const HAND_ALIASES: Array[String] = [
	"mixamorig_RightHand", "mixamorig:RightHand", "mixamorigRightHand", "RightHand",
]

## Where the model sits inside the hand, in metres. A wireless mic hangs a little past the
## grip; the stand is held at the pole. Tuned against the delivered hand bone, not measured
## from art that does not exist yet.
const MIC_PLACE := Vector3(0.0, 0.11, 0.02)

## Fix pass commit 5. The mic used to hang from that fixed offset, which reads as a sticker on the
## outside of the fist: nothing tied it to the hand's own shape. It is now mounted from the
## skeleton instead - the handle centreline runs along the fist hollow axis (index proximal ->
## pinky proximal), passes through the palm point (the mean of the four finger proximal origins,
## pushed toward the palm side by the handle radius) with its head toward the thumb and at most
## `MIC_TILT_DEG` of tilt, so the fist visibly closes around the handle. The 0.24 m model scale is
## untouched: this is a mount, not a resize.
const MIC_TILT_DEG := 12.0
const HANDLE_RADIUS := 0.02
const FINGER_SUFFIXES: Array[String] = ["Index", "Middle", "Ring", "Pinky"]
const THUMB_SUFFIX := "Thumb"


## The mount, in the hand bone's own space. `fist_axis` is index -> pinky proximal, `thumb_dir`
## points at the thumb; the mic's long axis is its local +Y, so the returned basis puts +Y on the
## fist axis and tilts it by at most MIC_TILT_DEG toward the thumb. Pure maths, so the audit can
## check the contract with synthetic points instead of a rigged upload.
static func grip_basis(fist_axis: Vector3, thumb_dir: Vector3, tilt_deg: float = MIC_TILT_DEG) -> Basis:
	var axis := fist_axis.normalized()
	if axis.is_zero_approx():
		return Basis.IDENTITY
	var side := thumb_dir.normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	# Tilt the handle a few degrees toward the thumb side, clamped: the hand is not a clamp.
	var tilt := clampf(tilt_deg, 0.0, MIC_TILT_DEG)
	var tilted := axis.rotated(side.cross(axis).normalized(), deg_to_rad(tilt))
	if tilted.is_zero_approx():
		tilted = axis
	var x := tilted.cross(side)
	if x.is_zero_approx():
		x = tilted.cross(Vector3.UP)
	x = x.normalized()
	var z := x.cross(tilted).normalized()
	return Basis(x, tilted, z)


## Palm point of the fist: mean of the finger proximal origins, moved toward the palm side by the
## handle radius so the handle's centreline sits inside the hollow, not on the skin.
static func grip_point(finger_points: Array[Vector3], palm_normal: Vector3) -> Vector3:
	if finger_points.is_empty():
		return MIC_PLACE
	var mean := Vector3.ZERO
	for point in finger_points:
		mean += point
	mean /= float(finger_points.size())
	return mean + palm_normal.normalized() * HANDLE_RADIUS


## Reads the mount off a real skeleton. Falls back to the tuned offset when the hand or its finger
## bones are not in this upload, so a re-export can never leave the mic floating.
static func grip_transform(skeleton: Skeleton3D, hand_bone_name: String) -> Transform3D:
	var fallback := Transform3D(Basis.IDENTITY, MIC_PLACE)
	if skeleton == null:
		return fallback
	var hand := skeleton.find_bone(hand_bone_name)
	if hand < 0:
		return fallback
	var points: Array[Vector3] = []
	for suffix in FINGER_SUFFIXES:
		var bone := _finger_bone(skeleton, hand_bone_name, suffix)
		if bone >= 0:
			points.append(skeleton.get_bone_global_pose(bone).origin)
	if points.size() < 2:
		return fallback
	var thumb := _finger_bone(skeleton, hand_bone_name, THUMB_SUFFIX)
	var thumb_dir := Vector3.RIGHT
	if thumb >= 0:
		thumb_dir = skeleton.get_bone_global_pose(thumb).origin - points[0]
	var palm_normal := thumb_dir.cross(points[points.size() - 1] - points[0])
	var world_basis := grip_basis(points[points.size() - 1] - points[0], thumb_dir)
	var world_point := grip_point(points, palm_normal)
	# The attachment lives in the hand bone's space: undo the bone's own transform.
	var bone_xform := skeleton.get_bone_global_pose(hand)
	var local_point := bone_xform.affine_inverse() * world_point
	var local_basis := bone_xform.basis.inverse() * world_basis
	return Transform3D(local_basis, local_point)


## First bone under the hand whose name carries `suffix` (`mixamorig_RightHandIndex1` etc).
static func _finger_bone(skeleton: Skeleton3D, hand_bone_name: String, suffix: String) -> int:
	if skeleton == null:
		return -1
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if bone_name.contains(suffix) and bone_name.contains("Hand"):
			var parent := skeleton.get_bone_parent(i)
			if parent >= 0 and skeleton.get_bone_name(parent) == hand_bone_name:
				return i
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if bone_name.ends_with(suffix + "1") or bone_name.ends_with(suffix):
			return i
	return -1
const STAND_PLACE := Vector3(0.0, 0.12, 0.0)


## Attach the prop slot this fighter should carry. Returns the attachments actually built, so
## the headless check can assert the bone and the slot.
static func attach_for(model: Node3D, skeleton: Skeleton3D, key: StringName) -> Array[BoneAttachment3D]:
	var built: Array[BoneAttachment3D] = []
	if model == null or skeleton == null:
		return built
	var bone := hand_bone(skeleton)
	if bone == "":
		push_warning("FighterProps: no right-hand bone on %s" % key)
		return built
	match key:
		&"feedback", &"lickshot":
			built.append(_slot(skeleton, bone, MIC_MODEL, "MicInHand", MIC_PLACE, true))
		&"young_selecta":
			built.append(_slot(skeleton, bone, STAND_MODEL, "MicStandInHand", STAND_PLACE))
	return built


## Right-hand bone name. Some FBX writers keep a numeric tag on the bone names
## (`mixamorig8_RightHand`), so an exact-name lookup is not enough and a suffix match is the
## only rule that holds across every upload.
static func hand_bone(skeleton: Skeleton3D) -> String:
	if skeleton == null:
		return ""
	for candidate in HAND_ALIASES:
		if skeleton.find_bone(candidate) >= 0:
			return candidate
	for i in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(i)
		if bone_name.ends_with("RightHand"):
			return bone_name
	return ""


## One `BoneAttachment3D` + `PropLoader` pair. The loader does the rest: it instances the
## model when the file exists and warns once when it does not.
##
## `delivered_hand_prop` is the wireless mic's contract (overnight props pass, 2026-11-27): its
## own photographic albedo instead of the cel ramp, its own two-sided culling (it is an open
## shell — 198 of 3 331 edges are boundary edges — and the glTF material says `doubleSided`),
## and NO ground seat, because a hand prop's floor is the grip: the model is centred on the hand
## bone so the midpoint sits inside the fist, where seating it at Y = 0 would push half its
## length out of the bottom of the hand. It must be set BEFORE `add_child()`, because the
## loader builds its materials in `_ready`.
static func _slot(skeleton: Skeleton3D, bone: String, path: String, label: String,
		offset: Vector3, delivered_hand_prop: bool = false) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = label
	attachment.bone_name = bone
	if delivered_hand_prop:
		# Fix pass commit 5: a hand prop is mounted from the fist, not from a constant offset.
		attachment.transform = grip_transform(skeleton, bone)
	else:
		attachment.position = offset
	skeleton.add_child(attachment)
	var loader := PropLoader.new()
	loader.name = label + "Slot"
	loader.model_path = path
	if delivered_hand_prop:
		loader.native_material = true
		loader.double_sided = true
		loader.auto_ground_y = false
	attachment.add_child(loader)
	return attachment


## Prop slots under one model, so a check can read what each fighter expects.
static func slots(model: Node3D) -> Array[PropLoader]:
	var found: Array[PropLoader] = []
	if model == null:
		return found
	for child in model.find_children("*", "PropLoader", true, false):
		found.append(child as PropLoader)
	return found


## Total triangles of every delivered hand prop under a model (props are excluded from the
## character budget on purpose). Zero while the files are missing.
static func prop_triangles(model: Node3D) -> int:
	var total := 0
	if model == null:
		return total
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var cursor: Node = mi.get_parent()
		while cursor != null and cursor != model:
			if cursor is BoneAttachment3D:
				total += int(mi.mesh.get_faces().size() / 3)
				break
			cursor = cursor.get_parent()
	return total
