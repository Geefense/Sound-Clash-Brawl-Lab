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
			built.append(_slot(skeleton, bone, MIC_MODEL, "MicInHand", MIC_PLACE))
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
static func _slot(skeleton: Skeleton3D, bone: String, path: String, label: String,
		offset: Vector3) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = label
	attachment.bone_name = bone
	attachment.position = offset
	skeleton.add_child(attachment)
	var loader := PropLoader.new()
	loader.name = label + "Slot"
	loader.model_path = path
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
