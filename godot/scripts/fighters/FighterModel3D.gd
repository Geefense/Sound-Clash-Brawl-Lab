class_name FighterModel3D
extends Node3D
## 3D cel-shaded presentation proxy for one fighter (AGENTS.md §9 item 43).
##
## This node never owns combat state. It reads the authoritative 2D `BaseFighter` every
## frame (state, attack id, facing, impact flash) and mirrors it onto a 3D model, so
## hitboxes, hurtboxes, input buffering, beat judgement, round timers and Patois callouts
## stay exactly as they were. The whole 3D layer can be switched off without touching a
## single combat value.
##
## Three model sources are wired (owner uploads, 2026-11-22):
##   * `feedback_v2.fbx`    — 29 025 tris, faces +Z
##   * `lickshot.fbx`       — 270 074 tris, faces +X
##   * `likkle_moore.fbx`   — 246 654 tris, faces +X
## All three are static GLB→FBX bakes: no skeleton, no Mixamo clip. Their whole-body
## stance (idle bob, walk lean, strike lunge, hit recoil, knockdown/spin) is procedural on
## `PosePivot`, so they are immediately playable without per-state animation tracks. The
## additive skeleton layer below is kept for a future rigged upload but idles out here.
## Both P1 and P2 can select the same fighter, so a mirror match gives **P2** the cool/gold
## alternate accent below to keep two identical meshes readable.
##
## `feedback_fighting_idle_rigged.fbx` and `lickshot_placeholder_static.fbx` stay archived
## in the same folder for reference only; neither is assigned to a fighter.
##
## Materials are the toon/cel shader with an inverted-hull ink `next_pass`; both are
## WebGL2-safe. The albedo is the owner's baked texture, extracted from the upload's
## embedded PNG and imported as uncompressed RGBA (no VRAM compression).

const TOON_SHADER := preload("res://assets/shaders/toon_cel.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/toon_outline.gdshader")

## Mirror-match accents. P1 keeps the owner's warm cream rim; P2 gets a cool jacket tint and
## a gold rim, so two identical fighters read as two players instead of one clone.
const MIRROR_TINT := Color(0.80, 0.90, 1.10, 1.0)
const MIRROR_HUE := 0.030
const MIRROR_RIM := Color(1.0, 0.70, 0.26, 1.0)
const PARRY_RIM := Color(1.0, 0.86, 0.24, 1.0)

## Per-move whole-body profiles (2026-11-22). Every fighter shares the same FSM, so the 3D
## differentiation lives here: `w_` is the startup coil, `s_` the contact drive. Lean and
## lunge are the 2.5D plane; lift, depth pitch and yaw twist give each strike a distinct
## silhouette even though the uploads are static meshes. No hitbox or timing reads these.
const MOVE_STYLES := {
	&"feedback": {
		&"jab": {"w_lean": -0.03, "w_lunge": -0.02, "s_lean": 0.18, "s_lunge": 0.26,
			"s_pitch": 0.04, "s_twist": 0.10, "s_squash": 1.03},
		&"strong": {"w_lean": -0.12, "w_lunge": -0.08, "s_lean": 0.27, "s_lunge": 0.46,
			"s_pitch": 0.14, "s_twist": -0.28, "s_squash": 1.06},
		&"tump": {"w_lean": 0.10, "w_lunge": -0.05, "s_lean": -0.26, "s_lunge": 0.28,
			"s_pitch": -0.16, "s_lift": 0.20, "s_twist": 0.40, "s_squash": 0.98},
		&"upper_box": {"w_lean": -0.16, "w_lunge": -0.06, "s_lean": 0.06, "s_lunge": 0.32,
			"s_pitch": -0.22, "s_lift": 0.24, "s_twist": -0.16, "s_squash": 1.04},
	},
	&"lickshot": {
		&"jab": {"w_lean": -0.02, "w_lunge": 0.02, "s_lean": 0.14, "s_lunge": 0.20,
			"s_pitch": 0.02, "s_twist": 0.20, "s_squash": 1.02},
		&"upper_box": {"w_lean": -0.22, "w_lunge": -0.10, "s_lean": 0.32, "s_lunge": 0.50,
			"s_pitch": 0.18, "s_twist": 0.48, "s_squash": 1.05},
		&"strong": {"w_lean": 0.18, "w_lunge": -0.12, "w_squash": 0.90, "s_lean": 0.08,
			"s_lunge": 0.16, "s_pitch": -0.06, "s_lift": 0.30, "s_twist": 0.0, "s_squash": 1.08},
		&"tump": {"w_lean": 0.12, "w_lunge": -0.08, "w_squash": 0.94, "s_lean": -0.12,
			"s_lunge": 0.42, "s_pitch": -0.30, "s_lift": 0.34, "s_twist": 0.22, "s_squash": 1.0},
	},
	&"young_selecta": {
		&"jab": {"w_lean": -0.04, "w_lunge": -0.02, "s_lean": 0.12, "s_lunge": 0.30,
			"s_pitch": 0.02, "s_twist": 0.08, "s_squash": 1.02},
		&"upper_box": {"w_lean": -0.30, "w_lunge": -0.12, "w_twist": -0.55, "w_squash": 0.95,
			"s_lean": 0.22, "s_lunge": 0.30, "s_pitch": 0.10, "s_twist": 1.15, "s_squash": 1.02},
		&"strong": {"w_lean": 0.22, "w_lunge": -0.06, "w_pitch": -0.14, "w_lift": 0.18,
			"s_lean": 0.40, "s_lunge": 0.34, "s_pitch": 0.30, "s_squash": 0.94},
		&"tump": {"w_lean": 0.16, "w_lunge": -0.04, "w_squash": 0.84, "s_lean": -0.16,
			"s_lunge": 0.30, "s_pitch": -0.18, "s_twist": -1.30, "s_squash": 0.80},
	},
}

## Per-fighter model wiring. `height` is the on-screen fighting height in world metres
## (the arena uses 140 px = 1 m, so 1.55 m reads between 55 % and 65 % of the 720 px frame
## at the neutral camera). `forward_yaw_deg` is the pivot rotation that puts the upload's
## own authored face onto the fighting +X axis, and it is a MEASURED value, not a guess.
## L!kkle Moore keeps the roster's 82 % kid height (1.55 × 0.82 ≈ 1.27 m).
##
## Facing audit (2026-11-24, `tools/diag_playtest.gd`, rest pose, no clips). Each model's
## forward came from its own mesh: per foot, the vertex furthest from that foot's centroid
## is the toe, so the mean of the two centroid→toe vectors is the authored face. The method
## reproduces the one independently known case — Feedback is documented +Z and measures
## −1.4° off +Z — so it is trustworthy for the other two:
##   feedback           authored +Z  (−1.4° from +Z)  -> pivot +90°
##   lickshot           authored +X  (+92.0° from +Z) -> pivot 0°
##   young_selecta      authored +X  (+94.4° from +Z) -> pivot 0°
## Both Tripo-derived bodies (L!ckshot, L!kkle Moore) are the same owner mesh family and
## `MODELS.md` independently records their source uploads as +X, so the two agree.
## NOTE: the `mixamorig_Hips` rest axis disagrees for those two (−60° / −51°). That is the
## rig's bind pose, which the inverse bind matrices compensate for; the rendered mesh is the
## authority for which way a character looks, so the mesh numbers above are used.
const MODEL_SOURCES := {
	&"feedback": {
		"path": "res://assets/models/fighters/feedback_rigged.fbx",
		"albedo": "res://assets/models/fighters/feedback_v2_albedo.png",
		"label": "Feedback — Mixamo-rigged 3D upload (feedback_rigged)",
		"height": 1.55,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"hue_shift": 0.0,
		"forward_yaw_deg": 90.0,
		"ink": Color(0.022, 0.016, 0.030, 1.0),
		"rim": Color(1.0, 0.88, 0.62, 1.0),
	},
	&"lickshot": {
		"path": "res://assets/models/fighters/lickshot_rigged.fbx",
		"albedo": "res://assets/models/fighters/lickshot_albedo.png",
		"label": "L!ckshot — Mixamo-rigged 3D upload (lickshot_rigged)",
		"height": 1.58,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"hue_shift": 0.0,
		"forward_yaw_deg": 0.0,
		"ink": Color(0.022, 0.016, 0.030, 1.0),
		"rim": Color(1.0, 0.82, 0.38, 1.0),
	},
	&"young_selecta": {
		"path": "res://assets/models/fighters/likkle_moore_rigged.fbx",
		"albedo": "res://assets/models/fighters/likkle_moore_albedo.png",
		"label": "L!kkle Moore — Mixamo-rigged 3D upload (likkle_moore_rigged)",
		"height": 1.27,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"hue_shift": 0.0,
		"forward_yaw_deg": 0.0,
		"ink": Color(0.022, 0.016, 0.030, 1.0),
		"rim": Color(1.0, 0.90, 0.70, 1.0),
	},
}
## `feedback_fighting_idle_rigged.fbx`, `lickshot_placeholder_static.fbx` and
## `feedback_fitted_jacket_albedo.jpg` stay archived in `assets/models/fighters/` for
## reference; none of them is a selectable model.

var fighter: BaseFighter = null
var fighter_key: StringName = &""
var model_root: Node3D = null
var skeleton: Skeleton3D = null
var animation: AnimationPlayer = null
var meshes: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
## role -> animation name for the owner's Mixamo takes (2026-11-24). Empty when the fighter
## has no uploaded clips, in which case the whole-body procedural stance stays in charge.
var clips: Dictionary = {}
var clip_role: StringName = &""
## BoneAttachment3D props riding the right hand (mic, or stand + dictionary).
var hand_props: Array[BoneAttachment3D] = []

var model_height: float = 1.55
var mirror_variant: bool = false
var triangles: int = 0
var bone_count: int = 0
var has_rig: bool = false
var albedo_texture: Texture2D = null
var albedo_size: Vector2i = Vector2i.ZERO
var facing_sign: int = 1
## Per-fighter facing constant (playtest fix 2026-11-24). The pivot yaw that makes this
## upload face +X; loaded from MODEL_SOURCES and kept exported so a designer can re-tune a
## future upload from the inspector without touching the facing code.
@export var model_forward_yaw_offset_deg: float = 0.0
var feet_offset: float = 0.0

## The fighter root (this node) is never rotated and only ever follows the fighter's X.
## ALL facing lives on this one child pivot, with the model under it.
var _pivot: Node3D = null
var _visual_pivot: Node3D = null
var _clock: float = 0.0
var _lean: float = 0.0
var _lunge: float = 0.0
var _squash: float = 1.0
var _pitch: float = 0.0
var _twist: float = 0.0
var _lift: float = 0.0
var _parry_lit: bool = false
var _fall: float = 0.0
var _spin: float = 0.0
var _spin_angle: float = 0.0
var _flash: float = 0.0
var _last_facing: int = 1
var _base_tint: Color = Color.WHITE
var _base_hue: float = 0.0
var _base_rim: Color = Color.WHITE


func _ready() -> void:
	# Run after the AnimationPlayer has written this frame's baked pose, so the additive
	# fight-stance offsets layer on top instead of being overwritten.
	process_priority = 100


## Build the model. Returns false when the roster key has no 3D source, so the arena can
## fall back to the 2D billboard without breaking.
func bind(target: BaseFighter, key: StringName) -> bool:
	if not MODEL_SOURCES.has(key):
		return false
	var src: Dictionary = MODEL_SOURCES[key]
	var packed := load(String(src["path"])) as PackedScene
	if packed == null:
		push_warning("FighterModel3D: could not load %s" % src["path"])
		return false
	var inst := packed.instantiate() as Node3D
	if inst == null:
		push_warning("FighterModel3D: %s did not instantiate as Node3D" % src["path"])
		return false

	fighter = target
	fighter_key = key
	model_height = float(src["height"])
	_base_tint = src["tint"]
	_base_hue = float(src["hue_shift"])
	_base_rim = src["rim"]
	model_forward_yaw_offset_deg = float(src["forward_yaw_deg"])

	_pivot = Node3D.new()
	_pivot.name = "PosePivot"
	add_child(_pivot)
	_visual_pivot = Node3D.new()
	_visual_pivot.name = "VisualPivot"
	_pivot.add_child(_visual_pivot)
	model_root = inst
	_visual_pivot.add_child(inst)

	_collect(inst)
	# No take may translate the body (playtest fix 2026-11-24, issue 2): the body's own baked
	# export in the default library is sanitised here, before anything can play it.
	MixamoClips.strip_root_motion(animation, skeleton)
	_normalize(inst)
	_apply_materials(src)
	_install_clips()
	_attach_props()
	_play_baked_idle()
	facing_sign = target.facing if target != null else 1
	_last_facing = facing_sign
	set_facing(facing_sign)
	return true


## Read-only summary for the headless verification and AGENTS inventory.
func describe() -> Dictionary:
	return {
		"key": String(fighter_key),
		"triangles": triangles,
		"bones": bone_count,
		"rigged": has_rig,
		"height": model_height,
		"feet": feet_offset,
		"materials": materials.size(),
		"albedo": albedo_size,
		"has_albedo": has_albedo_texture(),
	}


func triangle_count() -> int:
	return triangles


## Real assembled crown-to-sole height in metres, measured from the live mesh AABBs and
## every ancestor transform. The headless check compares this with the authored height, so a
## model whose ×1000 GLB→FBX root scale escaped normalisation fails instead of looking huge.
func measured_height() -> float:
	var low := INF
	var high := -INF
	# Stop at the facing node: the PosePivot squash/lean is a live pose, not the model's
	# authored size, and must not change the measurement.
	var top: Node3D = _visual_pivot if _visual_pivot != null else self
	if has_rig and skeleton != null:
		# Skinned bounds come from the rest bones through the skeleton's own unit scale — the
		# same quantity `_normalize()` scaled against, so the two can never disagree.
		var to_top := _relative_transform(skeleton, top)
		for i in skeleton.get_bone_count():
			var origin: Vector3 = (to_top * skeleton.get_bone_global_rest(i)).origin
			low = minf(low, origin.y)
			high = maxf(high, origin.y)
	else:
		for mi in meshes:
			var box: AABB = _relative_transform(mi, top) * mi.mesh.get_aabb()
			low = minf(low, box.position.y)
			high = maxf(high, box.position.y + box.size.y)
	if low == INF or high == -INF:
		return 0.0
	return high - low


## True when the model has both a decoded albedo and a real (non-1×1) texture size.
## The headless check asserts this for all three fighters, so a skipped/missing upload
## fails the build instead of quietly rendering a grey mesh.
func has_albedo_texture() -> bool:
	return albedo_texture != null and albedo_size.x > 1 and albedo_size.y > 1


func model_source_label() -> String:
	if not MODEL_SOURCES.has(fighter_key):
		return ""
	return String(MODEL_SOURCES[fighter_key]["label"])


## Player 2 in a mirror match: a cool jacket tint and gold rim so two identical fighter
## meshes are still distinguishable. Presentation only — no material, tint or shader value
## reaches the combat simulation.
func set_mirror_variant(enabled: bool) -> void:
	if enabled == mirror_variant:
		return
	mirror_variant = enabled
	_apply_variant()


func is_mirror_variant() -> bool:
	return mirror_variant


func shader_tint() -> Color:
	if materials.is_empty():
		return _base_tint
	return materials[0].get_shader_parameter("tint") as Color


func _apply_variant() -> void:
	var tint := MIRROR_TINT if mirror_variant else _base_tint
	var hue := MIRROR_HUE if mirror_variant else _base_hue
	var rim := MIRROR_RIM if mirror_variant else _base_rim
	for mat in materials:
		mat.set_shader_parameter("tint", tint)
		mat.set_shader_parameter("hue_shift", hue)
		mat.set_shader_parameter("rim_colour", rim)



func _collect(inst: Node3D) -> void:
	for node in inst.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		meshes.append(mi)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for surface in mi.mesh.get_surface_count():
			var arrays := mi.mesh.surface_get_arrays(surface)
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices != null:
				triangles += int(indices.size() / 3)
			else:
				var verts = arrays[Mesh.ARRAY_VERTEX]
				if verts != null:
					triangles += int(verts.size() / 3)
	for node in inst.find_children("*", "Skeleton3D", true, false):
		skeleton = node as Skeleton3D
		break
	if skeleton != null:
		bone_count = skeleton.get_bone_count()
		has_rig = bone_count > 0
	for node in inst.find_children("*", "AnimationPlayer", true, false):
		animation = node as AnimationPlayer
		break


## Scale/seat the mesh from its own measured bounds so no upload's authored unit scale leaks
## into the arena: a Mixamo rig may measure ~1.9 m, while these GLB→FBX bakes carry a ×1000
## root scale and assemble to 1 m.
func _normalize(inst: Node3D) -> void:
	var height_units := 0.0
	var lowest := 0.0
	if has_rig:
		var top := -INF
		var bottom := INF
		for i in skeleton.get_bone_count():
			var name := skeleton.get_bone_name(i)
			if name.ends_with("HeadTop_End") or name.ends_with("Head"):
				top = maxf(top, skeleton.get_bone_global_rest(i).origin.y)
			if name.ends_with("Toe_End") or name.ends_with("ToeBase"):
				bottom = minf(bottom, skeleton.get_bone_global_rest(i).origin.y)
		if top == -INF or bottom == INF:
			for i in skeleton.get_bone_count():
				var y := skeleton.get_bone_global_rest(i).origin.y
				top = maxf(top, y)
				bottom = minf(bottom, y)
		# Bone rest positions are in skeleton space; the Skeleton3D node carries the export's
		# unit scale (0.01 for the centimetre Mixamo exports, 1.0 for Feedback). Without this
		# factor a 1.58 m fighter is normalised 100× too small.
		var chain := _relative_transform(skeleton, inst).basis.get_scale().y
		height_units = maxf((top - bottom) * chain, 0.01)
		lowest = bottom * chain
	else:
		# Measure through the upload's own node transforms, not the mesh AABB alone: the
		# GLB→FBX bakes carry a ×1000 root scale, so the raw AABB is 1 mm tall while the
		# assembled model is 1 m tall. Ignoring the ancestors would normalise it 1000× too
		# large. The arena owns the returned scale, so this is still one shared height rule.
		var aabb := AABB()
		var first := true
		for mi in meshes:
			var xf := _relative_transform(mi, inst)
			var box: AABB = xf * mi.mesh.get_aabb()
			if first:
				aabb = box
				first = false
			else:
				aabb = aabb.merge(box)
		height_units = maxf(aabb.size.y, 0.0001)
		lowest = aabb.position.y
	var factor := model_height / height_units
	inst.scale *= Vector3.ONE * factor
	feet_offset = -lowest * factor
	inst.position.y = feet_offset


## Compose one mesh's transform up to (not including) `ancestor`. Node3D.transform is
## local, so walking to the scene root is exact and independent of when the node enters
## the tree; `global_transform` is unavailable during `_ready` ordering.
func _relative_transform(node: Node3D, ancestor: Node3D) -> Transform3D:
	var xf := Transform3D.IDENTITY
	var cursor: Node = node
	while cursor != null and cursor != ancestor:
		if cursor is Node3D:
			xf = (cursor as Node3D).transform * xf
		cursor = cursor.get_parent()
	return xf


func _apply_materials(src: Dictionary) -> void:
	var texture := load(String(src["albedo"])) as Texture2D
	if texture == null:
		push_warning("FighterModel3D: missing albedo %s" % src["albedo"])
	else:
		albedo_texture = texture
		albedo_size = texture.get_size()
	for mi in meshes:
		var mat := ShaderMaterial.new()
		mat.shader = TOON_SHADER
		mat.set_shader_parameter("albedo_texture", texture)
		mat.set_shader_parameter("tint", src["tint"])
		mat.set_shader_parameter("hue_shift", float(src["hue_shift"]))
		mat.set_shader_parameter("rim_colour", src["rim"])
		mat.set_shader_parameter("flash_amount", 0.0)
		var ink := ShaderMaterial.new()
		ink.shader = OUTLINE_SHADER
		ink.set_shader_parameter("ink_colour", src["ink"])
		mat.next_pass = ink
		materials.append(mat)
		for surface in mi.mesh.get_surface_count():
			mi.set_surface_override_material(surface, mat)


func _play_baked_idle() -> void:
	if animation == null:
		return
	# The installed Mixamo library is the only thing allowed to drive a rigged fighter
	# (playtest fix 2026-11-24, issue 1). `get_animation_list()` also lists library entries,
	# so this used to restart an arbitrary role — `mixamo/getup` for Feedback — or the body's
	# raw baked export, whose own root translation put the fighter ~76 m above the sand and
	# out of frame. That is what made an opponent look missing.
	if not clips.is_empty():
		return
	var names := animation.get_animation_list()
	if names.is_empty():
		return
	var pick := String(names[0])
	var anim := animation.get_animation(pick)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	animation.play(pick)


## THE one facing function (playtest fix 2026-11-24). `dir` is +1 to face +X, −1 to face
## −X. It rotates the pivot — never the root, never the AnimationPlayer targets, and never
## a mirror (negative scale or `flip_h`), so the mic stays in the same hand on both sides.
func set_facing(dir: int) -> void:
	facing_sign = 1 if dir >= 0 else -1
	if _visual_pivot != null:
		var yaw := deg_to_rad(model_forward_yaw_offset_deg)
		if facing_sign < 0:
			yaw += PI
		_visual_pivot.rotation.y = yaw


## Kept as the per-frame name the rest of this class already calls.
func _apply_facing() -> void:
	if _visual_pivot == null or fighter == null:
		return
	set_facing(fighter.facing)


## The upload's own authored forward, in the model's local space. Derived from the measured
## pivot offset: rotating this by `model_forward_yaw_offset_deg` must land exactly on +X.
func authored_forward() -> Vector3:
	var yaw := deg_to_rad(model_forward_yaw_offset_deg)
	return Vector3(cos(yaw), 0.0, sin(yaw))


## World-space forward of the RENDERED body, flattened onto the fighting plane. Two honest
## halves: the authored forward turned by the pivot that actually shipped, plus the turn the
## PLAYING take adds on top of the rig's own rest pose (`pose_turn_yaw()`). A clip that baked
## in its own heading, or a pivot that failed to apply, therefore shows up here.
func world_forward() -> Vector3:
	var fwd := authored_forward()
	if _visual_pivot != null:
		fwd = _visual_pivot.global_transform.basis * fwd
	fwd.y = 0.0
	if fwd.length() < 0.0001:
		return Vector3.RIGHT
	fwd = fwd.normalized()
	var turn := pose_turn_yaw()
	if not is_zero_approx(turn):
		fwd = fwd.rotated(Vector3.UP, turn)
	return fwd.normalized()


## How far the playing take has turned the body away from its own rest pose, about the world
## up axis, in radians. Both headings come from the pelvis' horizontal reference axis in
## SKELETON space, so the facing pivot cancels out and this is the pose's contribution alone.
## A rest-referenced difference is essential here: the pelvis bind basis of the two
## Tripo-derived rigs is rotated 30°–40° about Y (L!ckshot measures (−0.87, 0.50) at rest),
## while their meshes face +X, so comparing either raw bone axis to ±X reports a turn that is
## not there. Zero without a rig, so a sprite-only body never reads as turned.
func pose_turn_yaw() -> float:
	if skeleton == null:
		return 0.0
	var hips := _bone_suffix("Hips")
	if hips < 0:
		return 0.0
	var rest_dir := _heading_dir(skeleton.get_bone_global_rest(hips).basis)
	var pose_dir := _heading_dir(skeleton.get_bone_global_pose(hips).basis)
	if rest_dir == Vector3.ZERO or pose_dir == Vector3.ZERO:
		return 0.0
	# R_y(θ) applied to rest gives pose: sin θ = rest × pose (Y), cos θ = rest · pose.
	var sin_t := rest_dir.z * pose_dir.x - rest_dir.x * pose_dir.z
	var cos_t := rest_dir.x * pose_dir.x + rest_dir.z * pose_dir.z
	if absf(sin_t) < 0.0001 and cos_t > 0.0:
		return 0.0
	return wrapf(atan2(sin_t, cos_t), -PI, PI)


## How far the playing clip has turned the body away from the rig's own rest pose, in
## radians. Measured from the hip-socket axis rather than from a quaternion, because the
## Hips rest rotation is an arbitrary rig convention (it reads −60° on L!ckshot while his
## mesh faces +X). Comparing the POSED hip axis with the REST hip axis cancels that
## convention out, so a zero result really means "the take did not turn the character".
## Zero whenever no clip is driving the body, so a procedural stance never reads as a turn.
## The pose's heading change, and the value `_compensate_clip_yaw()` cancels. It used to be
## the Y term of `pose * rest-inverse` in YXZ order, which is not a heading: on rigs whose
## pelvis carries a large bind yaw a few degrees of pitch/roll leaked into that Euler term and
## reported a phantom 30°–40° turn, which the pivot then applied for real. Kept as the
## per-frame name the class already calls; the measurement now lives in `pose_turn_yaw()`.
func hips_yaw_delta() -> float:
	if skeleton == null or animation == null or not animation.is_playing() or clips.is_empty():
		return 0.0
	return pose_turn_yaw()


## The pelvis' horizontal reference axis, whichever of its two basis axes still has a
## resolvable projection. A body standing on its head has no usable X, so Z covers it.
func _heading_dir(basis: Basis) -> Vector3:
	for axis in [basis.x, basis.z]:
		var flat := Vector3(axis.x, 0.0, axis.z)
		if flat.length() > 0.2:
			return flat.normalized()
	return Vector3.ZERO


## Current animation name, for the F3 readout. The imported take owns the AnimationPlayer
## when a clip is installed; otherwise the 2D FSM's own state name is the honest answer.
func current_animation_name() -> String:
	if animation != null and animation.is_playing():
		return animation.current_animation
	if clips.has("player") and clips["player"] != null:
		var p := clips["player"] as AnimationPlayer
		if p.is_playing():
			return p.current_animation
	return ""


## Yaw of the facing pivot in degrees (the authored offset plus the −1 flip).
func facing_yaw_deg() -> float:
	return rad_to_deg(_visual_pivot.rotation.y) if _visual_pivot != null else 0.0


func _bone_suffix(suffix: String) -> int:
	if skeleton == null:
		return -1
	for i in skeleton.get_bone_count():
		if skeleton.get_bone_name(i).ends_with(suffix):
			return i
	return -1


func _process(delta: float) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	_clock += delta
	_apply_facing()
	_animate_pose(delta)
	_drive_clips()
	_lock_root_yaw()
	_compensate_clip_yaw()
	_animate_rig()
	_clamp_to_floor()
	_push_flash()


## Nothing the fighter draws may end up under the sand (playtest fix 2026-11-24, issue 2).
## With the clips' root translation stripped, a knockdown take that lays the body flat pivots
## it about the standing pelvis, which can push a shoulder or a head below world y 0 — the
## body visibly sank into the beach. This lifts the pose pivot by exactly the amount needed,
## using the posed bone origins (65 transforms, no vertex work, same cost every frame). It
## only ever lifts, so a standing fighter is untouched and no animation gains a fake offset.
## Presentation only: `CharacterBody2D` position, the 2D sprite and every hitbox are unchanged.
## `_animate_pose()` rebuilds `_pivot.position` from scratch every frame, so the correction is
## added fresh each frame and can never stack.
const FLOOR_BONE_CLEARANCE := 0.10

func _clamp_to_floor() -> void:
	if skeleton == null or _pivot == null:
		return
	var lowest := INF
	var skel_xf := skeleton.global_transform
	for i in skeleton.get_bone_count():
		lowest = minf(lowest, (skel_xf * skeleton.get_bone_global_pose(i).origin).y)
	if lowest == INF:
		return
	var want := FLOOR_BONE_CLEARANCE - lowest
	if want > 0.0:
		_pivot.position.y += want


## Facing is authoritative (playtest fix 2026-11-24). A few delivered takes (stun, stumble,
## knocked-out, getting-up) throw the pelvis far enough that no single bone lock can keep the
## heading on ±X. Whatever heading the take adds is therefore cancelled on `VisualPivot`, so
## the body always points the way the fight says it does while the take keeps every degree of
## its topple, lean and get-up. This is the last word on facing: `world_forward()` is ±X by
## construction once this has run.
func _compensate_clip_yaw() -> void:
	if _visual_pivot == null or clips.is_empty():
		return
	var yaw := deg_to_rad(model_forward_yaw_offset_deg) + (0.0 if facing_sign > 0 else PI)
	_visual_pivot.rotation.y = yaw - hips_yaw_delta()


## Root motion disabled, enforced every frame (playtest fix 2026-11-24, issue 1 step 6).
## The takes bake their own heading into the Hips: `fighting-idle-3` carries −72° there, and
## the melee/KO takes 45°–155°. `MixamoClips` already flattens those tracks, but a clip can
## still arrive through a cached library, so the pose is pinned to the rig's own rest yaw
## here as well. Only the Y angle is touched — pitch and roll keep the lean, punch twist,
## topple and get-up exactly as authored. `VisualPivot` is then the sole owner of facing.
func _lock_root_yaw() -> void:
	# Deliberately not gated on `is_playing()`: a paused/seeking player still owns the pose,
	# and the heading must stay pinned whenever a take is driving the body.
	if skeleton == null or animation == null or clips.is_empty():
		return
	if String(animation.current_animation) == "":
		return
	var index := _bone_suffix("Hips")
	if index < 0:
		return
	var rest := skeleton.get_bone_rest(index).basis.get_euler(EULER_ORDER_YXZ)
	var now := Basis(skeleton.get_bone_pose_rotation(index)).get_euler(EULER_ORDER_YXZ)
	if absf(wrapf(now.y - rest.y, -PI, PI)) < 0.0005:
		return
	skeleton.set_bone_pose_rotation(index,
		Basis.from_euler(Vector3(now.x, rest.y, now.z), EULER_ORDER_YXZ).get_rotation_quaternion())


# =========================================================================
# Real Mixamo takes (2026-11-24)
# =========================================================================
## Mount every uploaded take on this fighter's AnimationPlayer. The body is one of the
## owner's own Mixamo exports, so the clip tracks already target `Armature/Skeleton3D`.
func _install_clips() -> void:
	var skeleton_path := "Armature/Skeleton3D"
	if model_root != null and skeleton != null:
		skeleton_path = String(model_root.get_path_to(skeleton))
	clips = MixamoClips.install_for(animation, fighter_key, skeleton_path)
	if clips.is_empty():
		return
	clip_role = &""
	_play_role(&"idle")


func _play_role(role: StringName) -> void:
	if clips.is_empty() or animation == null:
		return
	var resolved := MixamoClips.resolve(clips, role)
	if resolved == &"":
		return
	var anim_name := String(clips[resolved])
	# Compare the animation that is ACTUALLY playing, not merely the role last requested
	# (playtest fix 2026-11-24, issue 3). A base clip left on the player used to leave the
	# body frozen on the wrong take while every state change was short-circuited here, so a
	# punch changed the combat state but nothing appeared on screen.
	if resolved == clip_role and animation.current_animation == anim_name and animation.is_playing():
		return
	clip_role = resolved
	animation.play(anim_name, MixamoClips.CROSSFADE)


## Follow the fighter state with crossfades. Combat resolution is untouched: this reads
## `state`, `_attack_id` and `_celebrate_ticks` after the tick has already decided them.
func _drive_clips() -> void:
	if clips.is_empty() or fighter == null:
		return
	_play_role(MixamoClips.role_for(fighter))


func _attach_props() -> void:
	hand_props.clear()
	if skeleton == null:
		return
	hand_props = FighterProps.attach_for(model_root, skeleton, fighter_key)


## Read-only clip/prop inventory for the headless check and the AGENTS ledger.
func clip_roles() -> Array:
	var out: Array = clips.keys()
	out.sort()
	return out


func clip_count() -> int:
	return clips.size()


func current_clip() -> StringName:
	return clip_role


func hand_prop_count() -> int:
	return hand_props.size()


func hand_bone_name() -> String:
	return FighterProps.hand_bone(skeleton)


# =========================================================================
# Whole-body procedural stance (works for rigged and static uploads)
# =========================================================================
func _move_style() -> Dictionary:
	var table: Dictionary = MOVE_STYLES.get(fighter_key, {})
	return table.get(fighter._attack_id, {})


func _animate_pose(delta: float) -> void:
	var state: int = fighter.state
	var bob := sin(_clock * TAU * 1.12) * 0.012 + sin(_clock * TAU * 2.24) * 0.004
	var lean_target := 0.0
	var lunge_target := 0.0
	var squash_target := 1.0
	var fall_target := 0.0
	var pitch_target := 0.0
	var twist_target := 0.0
	var lift_target := 0.0
	var style: Dictionary = {}
	if state in [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE,
			BaseFighter.State.ATTACK_RECOVERY]:
		style = _move_style()
	match state:
		BaseFighter.State.WALK:
			bob = sin(_clock * TAU * 1.85) * 0.030
			lean_target = 0.05
		BaseFighter.State.JUMP:
			bob = 0.0
			lean_target = 0.07
		BaseFighter.State.CROUCH:
			bob *= 0.35
			squash_target = 0.82
			lean_target = 0.04
		BaseFighter.State.ATTACK_STARTUP:
			lean_target = -0.085 + float(style.get("w_lean", 0.0))
			lunge_target = -0.06 + float(style.get("w_lunge", 0.0))
			pitch_target = float(style.get("w_pitch", 0.0))
			twist_target = float(style.get("w_twist", 0.0))
			lift_target = float(style.get("w_lift", 0.0))
			squash_target = float(style.get("w_squash", 0.93))
		BaseFighter.State.ATTACK_ACTIVE:
			var attack_id: StringName = fighter._attack_id
			var heavy := attack_id in BaseFighter.HEAVY_ATTACK_IDS
			lean_target = float(style.get("s_lean", 0.20 if heavy else 0.14))
			lunge_target = float(style.get("s_lunge", 0.34 if heavy else 0.22))
			pitch_target = float(style.get("s_pitch", 0.0))
			twist_target = float(style.get("s_twist", 0.0))
			lift_target = float(style.get("s_lift", 0.0))
			squash_target = float(style.get("s_squash", 1.035))
		BaseFighter.State.ATTACK_RECOVERY:
			lean_target = 0.05 + float(style.get("s_lean", 0.0)) * 0.22
			lunge_target = 0.08 + float(style.get("s_lunge", 0.0)) * 0.22
			pitch_target = float(style.get("s_pitch", 0.0)) * 0.22
			twist_target = float(style.get("s_twist", 0.0)) * 0.22
			lift_target = float(style.get("s_lift", 0.0)) * 0.22
		BaseFighter.State.HITSTUN:
			lean_target = -0.20
			lunge_target = -0.09
			squash_target = 0.97
		BaseFighter.State.GRAB:
			# Collar-snatch lunge: weight forward, then the hold plants.
			lean_target = 0.13
			lunge_target = 0.18
		BaseFighter.State.GRABBED:
			lean_target = -0.12
			lunge_target = -0.05
		BaseFighter.State.THROWN:
			_spin = 7.5
		BaseFighter.State.KNOCKDOWN, BaseFighter.State.KO:
			fall_target = 1.0
			lean_target = 0.0
			lunge_target = 0.0
		BaseFighter.State.TAUNT:
			# Three different skanks: Feedback's lean-back groove, L!ckshot's deeper selector
			# lean with a slow shoulder turn, and the kid's bouncy footwork.
			bob = sin(_clock * TAU * 1.9) * 0.028
			if fighter_key == &"lickshot":
				lean_target = -0.24
				twist_target = sin(_clock * TAU * 0.66) * 0.32
				lift_target = absf(sin(_clock * TAU * 1.9)) * 0.02
			elif fighter_key == &"young_selecta":
				lean_target = 0.04
				bob = absf(sin(_clock * TAU * 2.5)) * 0.055
				twist_target = sin(_clock * TAU * 1.25) * 0.42
			else:
				lean_target = -0.07
		_:
			bob += sin(_clock * TAU * 0.5) * 0.003
	if _spin > 0.0 and state != BaseFighter.State.THROWN:
		_spin = move_toward(_spin, 0.0, 10.0 * delta)
	if state == BaseFighter.State.THROWN:
		_spin_angle += _spin * delta
	else:
		_spin_angle = move_toward(_spin_angle, 0.0, 9.0 * delta)

	_lean = _approach(_lean, lean_target, 14.0, delta)
	_lunge = _approach(_lunge, lunge_target, 18.0, delta)
	_squash = _approach(_squash, squash_target, 16.0, delta)
	_fall = _approach(_fall, fall_target, 7.5 if fall_target > 0.0 else 12.0, delta)
	_pitch = _approach(_pitch, pitch_target, 14.0, delta)
	_twist = _approach(_twist, twist_target, 16.0, delta)
	_lift = _approach(_lift, lift_target, 18.0, delta)

	var face := float(facing_sign)
	_pivot.position = Vector3(_lunge * face, bob + _lift, 0.0)
	_pivot.scale = Vector3(1.0 + (1.0 - _squash) * 0.35, _squash, 1.0)
	_pivot.rotation.x = _pitch
	# NOTHING on this pivot may yaw: `VisualPivot` owns facing alone, so the whole body's
	# forward stays within a few degrees of ±X in every animation (playtest fix 2026-11-24).
	# The per-move body twist still reads, because it rides the spine in `_apply_twist()`.
	_pivot.rotation.z = -_lean * face - _fall * face * PI * 0.5 * 0.94 + _spin_angle
	_apply_twist(face)


## The retired body-yaw twist, now spent on the torso instead of the facing axis. A strike
## still visibly turns through the shoulders/hips without moving the character's heading.
## No skeleton (a future static upload) simply means no visible twist — never a yawed body.
func _apply_twist(face: float) -> void:
	if skeleton == null or is_zero_approx(_twist):
		return
	# Only while a clip owns the body; otherwise `_animate_rig()` already spends the twist
	# inside its own additive stance set.
	if clips.is_empty() or animation == null or not animation.is_playing():
		return
	# Spine only. The Hips bone is deliberately left to the clip, so `hips_yaw_delta()`
	# keeps measuring the take's own turn rather than our cosmetic twist.
	_add_bone("mixamorig_Spine1", Vector3.UP, _twist * face)


func _approach(value: float, target: float, speed: float, delta: float) -> float:
	# Exponential smoothing that behaves at any frame rate.
	return lerpf(value, target, 1.0 - exp(-speed * delta))


# =========================================================================
# Additive skeletal fight stances (rigged upload only)
# =========================================================================
func _animate_rig() -> void:
	if skeleton == null or animation == null or not animation.is_playing():
		return
	# Once the owner's takes own the skeleton, the hand-authored additive stances would
	# fight them; the real animation is the authority for the pose.
	if not clips.is_empty():
		return
	var state: int = fighter.state
	# Mixamo bones point along local +Y, so local X is the forward/back bend axis. Angles are
	# deliberately small and additive on top of the baked idle: they read as stance changes
	# without inventing a second animation system in front of the owner's tracks.
	match state:
		BaseFighter.State.WALK:
			var stride := sin(_clock * TAU * 1.85) * 0.22
			_add_bone("mixamorig_LeftUpLeg", Vector3.RIGHT, stride)
			_add_bone("mixamorig_RightUpLeg", Vector3.RIGHT, -stride)
			_add_bone("mixamorig_LeftArm", Vector3.RIGHT, -stride * 0.45)
			_add_bone("mixamorig_RightArm", Vector3.RIGHT, stride * 0.45)
		BaseFighter.State.ATTACK_STARTUP:
			_add_bone("mixamorig_Spine1", Vector3.RIGHT, -0.10)
			_add_bone("mixamorig_RightArm", Vector3.BACK, 0.30)
		BaseFighter.State.ATTACK_ACTIVE:
			_add_bone("mixamorig_Spine1", Vector3.RIGHT, 0.20)
			_add_bone("mixamorig_RightArm", Vector3.BACK, -0.55)
			_add_bone("mixamorig_RightForeArm", Vector3.RIGHT, -0.30)
			_add_bone("mixamorig_Head", Vector3.RIGHT, 0.10)
		BaseFighter.State.HITSTUN:
			_add_bone("mixamorig_Spine1", Vector3.RIGHT, -0.22)
			_add_bone("mixamorig_Head", Vector3.RIGHT, -0.16)
		BaseFighter.State.CROUCH:
			_add_bone("mixamorig_LeftUpLeg", Vector3.RIGHT, 0.34)
			_add_bone("mixamorig_RightUpLeg", Vector3.RIGHT, 0.34)
			_add_bone("mixamorig_LeftLeg", Vector3.RIGHT, -0.55)
			_add_bone("mixamorig_RightLeg", Vector3.RIGHT, -0.55)
		BaseFighter.State.TAUNT:
			_add_bone("mixamorig_LeftArm", Vector3.BACK, 1.15)
			_add_bone("mixamorig_LeftForeArm", Vector3.BACK, 0.35)
			_add_bone("mixamorig_Spine1", Vector3.RIGHT, -0.08)
	if fighter.guarding and state in [BaseFighter.State.IDLE, BaseFighter.State.CROUCH,
			BaseFighter.State.WALK, BaseFighter.State.HITSTUN]:
		_add_bone("mixamorig_LeftArm", Vector3.BACK, 0.75)
		_add_bone("mixamorig_RightArm", Vector3.BACK, -0.75)
		_add_bone("mixamorig_LeftForeArm", Vector3.RIGHT, 0.90)
		_add_bone("mixamorig_RightForeArm", Vector3.RIGHT, 0.90)
	if fighter._celebrate_ticks > 0:
		_add_bone("mixamorig_LeftArm", Vector3.BACK, 1.35)
		_add_bone("mixamorig_RightArm", Vector3.BACK, -1.35)


func _add_bone(bone_name: String, axis: Vector3, angle: float) -> void:
	var index := skeleton.find_bone(bone_name)
	if index < 0:
		return
	var base := skeleton.get_bone_pose_rotation(index)
	skeleton.set_bone_pose_rotation(index, base * Quaternion(axis, angle))


func _push_flash() -> void:
	# The 2D fighter counts its own impact-flash ticks; the 3D material follows the same
	# two-tick window so hit confirmation reads identically. A Record Static Parry lights the
	# same flash plus a gold rim, which is the 3D half of the vinyl-static read.
	var parry := fighter._parry_flash_ticks > 0
	var target := 1.0 if fighter._impact_flash_ticks > 0 or parry else 0.0
	if parry != _parry_lit:
		_parry_lit = parry
		var rim := PARRY_RIM if parry else (MIRROR_RIM if mirror_variant else _base_rim)
		for mat in materials:
			mat.set_shader_parameter("rim_colour", rim)
	if is_equal_approx(target, _flash):
		return
	_flash = target
	for mat in materials:
		mat.set_shader_parameter("flash_amount", _flash)
