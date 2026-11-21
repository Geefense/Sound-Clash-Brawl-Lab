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
## One model source is wired:
##   * `feedback_fighting_idle_rigged.fbx` — the owner's uploaded 40 000-triangle mesh with
##     the 25-bone Mixamo rig and its baked 3.30 s `mixamo_com` idle clip. The baked clip
##     drives the neutral/walk base, and the eight fight states are layered additively on
##     the skeleton (procedural stances) until per-state Mixamo tracks arrive.
##     Both P1 and P2 use it, so the default FEEDBACK vs FEEDBACK showcase is a true mirror
##     match; P2 gets the cool/gold alternate accent below so the two rigs stay readable.
##   * `lickshot_placeholder_static.fbx` is **archived for reference only** and is no longer
##     assigned to anyone. L!ckshot renders as a `FighterBillboard3D` from his approved 2D
##     sprites until his own rigged model is uploaded.
##
## Materials are the toon/cel shader with an inverted-hull ink `next_pass`; both are
## WebGL2-safe. The outfit texture is the owner's baked albedo (also used by the billboard).

const TOON_SHADER := preload("res://assets/shaders/toon_cel.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/toon_outline.gdshader")

## Mirror-match accents. P1 keeps the owner's warm cream rim; P2 gets a cool jacket tint and
## a gold rim, so two identical Feedback rigs read as two players instead of one clone.
const MIRROR_TINT := Color(0.80, 0.90, 1.10, 1.0)
const MIRROR_HUE := 0.030
const MIRROR_RIM := Color(1.0, 0.70, 0.26, 1.0)

## Per-fighter model wiring. `height` is the on-screen fighting height in world metres
## (the arena uses 140 px = 1 m, so 1.55 m reads between 55 % and 65 % of the 720 px frame
## at the neutral camera). `yaw_offset` turns the model's +Z face onto the fighting axis.
const MODEL_SOURCES := {
	&"feedback": {
		"path": "res://assets/models/fighters/feedback_fighting_idle_rigged.fbx",
		"albedo": "res://assets/models/fighters/feedback_fitted_jacket_albedo.jpg",
		"label": "Feedback — rigged Mixamo idle",
		"height": 1.55,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"hue_shift": 0.0,
		"yaw_offset": 0.0,
		"ink": Color(0.022, 0.016, 0.030, 1.0),
		"rim": Color(1.0, 0.88, 0.62, 1.0),
	},
}
## `lickshot_placeholder_static.fbx` (the static bake of the same mesh) stays archived in
## `assets/models/fighters/` for reference; it is intentionally not a selectable model.

var fighter: BaseFighter = null
var fighter_key: StringName = &""
var model_root: Node3D = null
var skeleton: Skeleton3D = null
var animation: AnimationPlayer = null
var meshes: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []

var model_height: float = 1.55
var mirror_variant: bool = false
var triangles: int = 0
var bone_count: int = 0
var has_rig: bool = false
var facing_sign: int = 1
var base_yaw: float = 0.0
var feet_offset: float = 0.0

var _pivot: Node3D = null
var _yaw: Node3D = null
var _clock: float = 0.0
var _lean: float = 0.0
var _lunge: float = 0.0
var _squash: float = 1.0
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
	base_yaw = float(src["yaw_offset"])

	_pivot = Node3D.new()
	_pivot.name = "PosePivot"
	add_child(_pivot)
	_yaw = Node3D.new()
	_yaw.name = "Facing"
	_pivot.add_child(_yaw)
	model_root = inst
	_yaw.add_child(inst)

	_collect(inst)
	_normalize(inst)
	_apply_materials(src)
	_play_baked_idle()
	facing_sign = target.facing if target != null else 1
	_last_facing = facing_sign
	_apply_facing()
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
	}


func triangle_count() -> int:
	return triangles


func model_source_label() -> String:
	if not MODEL_SOURCES.has(fighter_key):
		return ""
	return String(MODEL_SOURCES[fighter_key]["label"])


## Player 2 in a mirror match: a cool jacket tint and gold rim so two identical Feedback
## rigs are still distinguishable. Presentation only — no material, tint or shader value
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


## Scale/seat the mesh from its own measured bounds so neither upload's authored unit scale
## (the rig is ~1.9 m, the static mesh is authored 100× smaller) can leak into the arena.
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
		height_units = maxf(top - bottom, 0.01)
		lowest = bottom
	else:
		var aabb := AABB()
		var first := true
		for mi in meshes:
			if first:
				aabb = mi.mesh.get_aabb()
				first = false
			else:
				aabb = aabb.merge(mi.mesh.get_aabb())
		height_units = maxf(aabb.size.y, 0.0001)
		lowest = aabb.position.y
	var factor := model_height / height_units
	inst.scale *= Vector3.ONE * factor
	feet_offset = -lowest * factor
	inst.position.y = feet_offset


func _apply_materials(src: Dictionary) -> void:
	var texture := load(String(src["albedo"])) as Texture2D
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
	var names := animation.get_animation_list()
	if names.is_empty():
		return
	var pick := String(names[0])
	var anim := animation.get_animation(pick)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	animation.play(pick)


func _apply_facing() -> void:
	if _yaw == null or fighter == null:
		return
	facing_sign = 1 if fighter.facing >= 0 else -1
	# The uploaded rig faces +Z with its left hand on +X; turning +90° about Y puts that
	# face on +X, which is the fighter's right-facing side on the 2.5D plane.
	_yaw.rotation.y = facing_sign * PI * 0.5 + base_yaw


func _process(delta: float) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	_clock += delta
	_apply_facing()
	_animate_pose(delta)
	_animate_rig()
	_push_flash()


# =========================================================================
# Whole-body procedural stance (works for rigged and static uploads)
# =========================================================================
func _animate_pose(delta: float) -> void:
	var state: int = fighter.state
	var bob := sin(_clock * TAU * 1.12) * 0.012 + sin(_clock * TAU * 2.24) * 0.004
	var lean_target := 0.0
	var lunge_target := 0.0
	var squash_target := 1.0
	var fall_target := 0.0
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
			lean_target = -0.085
			lunge_target = -0.06
		BaseFighter.State.ATTACK_ACTIVE:
			var attack_id: StringName = fighter._attack_id
			var heavy := attack_id in BaseFighter.HEAVY_ATTACK_IDS
			lean_target = 0.20 if heavy else 0.14
			lunge_target = 0.34 if heavy else 0.22
			squash_target = 1.035
		BaseFighter.State.ATTACK_RECOVERY:
			lean_target = 0.05
			lunge_target = 0.08
		BaseFighter.State.HITSTUN:
			lean_target = -0.20
			lunge_target = -0.09
			squash_target = 0.97
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
			bob = sin(_clock * TAU * 1.9) * 0.028
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

	var face := float(facing_sign)
	_pivot.position = Vector3(_lunge * face, bob, 0.0)
	_pivot.scale = Vector3(1.0, _squash, 1.0)
	_pivot.rotation.z = -_lean * face - _fall * face * PI * 0.5 * 0.94 + _spin_angle


func _approach(value: float, target: float, speed: float, delta: float) -> float:
	# Exponential smoothing that behaves at any frame rate.
	return lerpf(value, target, 1.0 - exp(-speed * delta))


# =========================================================================
# Additive skeletal fight stances (rigged upload only)
# =========================================================================
func _animate_rig() -> void:
	if skeleton == null or animation == null or not animation.is_playing():
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
	# two-tick window so hit confirmation reads identically.
	var target := 1.0 if fighter._impact_flash_ticks > 0 else 0.0
	if is_equal_approx(target, _flash):
		return
	_flash = target
	for mat in materials:
		mat.set_shader_parameter("flash_amount", _flash)
