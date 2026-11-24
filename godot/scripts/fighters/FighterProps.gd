class_name FighterProps
extends RefCounted
## Cel-shaded hand props for the three roster fighters (owner request, 2026-11-24).
##
## The fighter bodies are the owner's own Mixamo exports, so they carry a real
## `mixamorig_RightHand` bone. Each prop is parented to a `BoneAttachment3D` on that bone,
## which means it follows every take — jab, hook, block, stumble, knockout — instead of
## being hand-animated per state.
##
## Feedback and L!ckshot hold a wireless stage microphone. L!kkle Moore holds his
## microphone stand in the same hand as the dictionary he swings, so the stand travels with
## the swing.
##
## Presentation only: no prop is read by the combat simulation, no hitbox is derived from
## it, and removing one changes nothing but the picture.

const TOON_SHADER := preload("res://assets/shaders/toon_cel.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/toon_outline.gdshader")

const HAND_BONE := "mixamorig_RightHand"
## Fallback bone names, in order, if an export ever renames the right hand.
const HAND_ALIASES: Array[String] = [
	"mixamorig_RightHand", "mixamorig:RightHand", "mixamorigRightHand", "RightHand",
]

const INK := Color(0.022, 0.016, 0.030, 1.0)
const MIC_BODY := Color(0.10, 0.10, 0.12, 1.0)
const MIC_GOLD := Color(0.95, 0.74, 0.30, 1.0)
const STAND_METAL := Color(0.22, 0.23, 0.27, 1.0)
const PAPER := Color(0.93, 0.89, 0.78, 1.0)

static var _white: ImageTexture = null


## Attach every prop this fighter should carry. Returns the attachments actually built, so
## the headless check can assert the bone, the prop mesh and the cel material.
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
			built.append(_attach(skeleton, bone, _mic(), "MicInHand", Vector3(0.0, 0.11, 0.02)))
		&"young_selecta":
			built.append(_attach(skeleton, bone, _mic_stand(), "MicStandInHand",
				Vector3(0.0, 0.12, 0.0)))
			built.append(_attach(skeleton, bone, _dictionary(), "DictionaryInHand",
				Vector3(0.02, 0.06, 0.07)))
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


static func _attach(skeleton: Skeleton3D, bone: String, prop: Node3D, label: String,
		offset: Vector3) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.name = label
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	attachment.position = offset
	prop.name = label + "Prop"
	attachment.add_child(prop)
	return attachment


## Wireless stage microphone: black body, gold grille, gold band at the grip.
static func _mic() -> Node3D:
	var root := Node3D.new()
	root.add_child(_cylinder(0.021, 0.030, 0.135, MIC_BODY, "Body", Vector3.ZERO))
	root.add_child(_cylinder(0.030, 0.030, 0.016, MIC_GOLD, "Band", Vector3(0, 0.062, 0)))
	var head := _sphere(0.038, MIC_GOLD, "Grille", Vector3(0, 0.088, 0))
	root.add_child(head)
	return root


## Microphone stand: heavy base, pole and a clip, scaled to a 1.27 m fighter.
static func _mic_stand() -> Node3D:
	var root := Node3D.new()
	root.add_child(_cylinder(0.090, 0.100, 0.022, STAND_METAL, "Base", Vector3(0, -0.30, 0)))
	root.add_child(_cylinder(0.014, 0.016, 0.720, STAND_METAL, "Pole", Vector3(0, 0.05, 0)))
	root.add_child(_cylinder(0.028, 0.028, 0.030, MIC_GOLD, "Clip", Vector3(0, 0.40, 0.01)))
	return root


## Heavy dictionary: cream pages, burgundy cover, gold spine band.
static func _dictionary() -> Node3D:
	var root := Node3D.new()
	var cover := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.030, 0.210, 0.150)
	cover.mesh = box
	cover.material_override = _toon(Color(0.36, 0.05, 0.09, 1.0))
	cover.name = "Cover"
	root.add_child(cover)
	var pages := MeshInstance3D.new()
	var page_mesh := BoxMesh.new()
	page_mesh.size = Vector3(0.024, 0.196, 0.138)
	pages.mesh = page_mesh
	pages.material_override = _toon(PAPER)
	pages.name = "Pages"
	pages.position = Vector3(0.004, 0, 0)
	root.add_child(pages)
	var spine := MeshInstance3D.new()
	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.034, 0.030, 0.154)
	spine.mesh = spine_mesh
	spine.material_override = _toon(MIC_GOLD)
	spine.name = "Spine"
	spine.position = Vector3(0, 0.088, 0)
	root.add_child(spine)
	return root


static func _cylinder(top: float, bottom: float, height: float, colour: Color,
		label: String, offset: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 1
	mi.mesh = mesh
	mi.material_override = _toon(colour)
	mi.name = label
	mi.position = offset
	return mi


static func _sphere(radius: float, colour: Color, label: String, offset: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 10
	mi.mesh = mesh
	mi.material_override = _toon(colour)
	mi.name = label
	mi.position = offset
	return mi


## Same Spatial Toon + inverted-hull ink treatment the fighters and crowd wear.
static func _toon(colour: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = TOON_SHADER
	material.set_shader_parameter("albedo_texture", _white_texture())
	material.set_shader_parameter("tint", colour)
	material.set_shader_parameter("hue_shift", 0.0)
	material.set_shader_parameter("rim_colour", MIC_GOLD)
	material.set_shader_parameter("rim_strength", 0.45)
	material.set_shader_parameter("flash_amount", 0.0)
	var ink := ShaderMaterial.new()
	ink.shader = OUTLINE_SHADER
	ink.set_shader_parameter("ink_colour", INK)
	material.next_pass = ink
	return material


static func _white_texture() -> Texture2D:
	if _white == null:
		var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(image)
	return _white


## Total triangles of every hand prop under a model (they are excluded from the
## character budget on purpose).
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
