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

# =========================================================================
# Stefan Iverson combat-feel layer (2026-11-24)
# =========================================================================
## Six presentation systems, all fed from the fighter's OWN combat phase and none of them
## read back into it: stepped arcade pose quantization, the non-linear attack curve with a
## measured `t_impact`, whole-body engagement + negative space, alive hitstop micro-tension,
## the `SquashPivot` impact pop and the additive hit-react overlay with per-frame ground
## pinning. `AnimationFeel` owns the maths; `FightBodyModifier3D` owns the skeleton writes.
##
## No PNG, `ANIM_OFFSET`, hitbox, hurtbox, startup/active/recovery, damage, beat-window or
## Patois value is touched by any of it.
const FEEL_FOOT_BONES := ["LeftToeBase", "RightToeBase", "LeftToe_End", "RightToe_End",
	"LeftFoot", "RightFoot"]
## The two hands: what a strike reaches with. Kept apart from `FEEL_IMPACT_PROBES` (which
## includes the feet for the pinning/sole work) so a walk step can never win the peak.
const FEEL_STRIKE_PROBES := ["RightHand", "LeftHand"]
const FEEL_IMPACT_PROBES := ["RightHand", "LeftHand", "RightToeBase", "LeftToeBase",
	"RightFoot", "LeftFoot"]
const FEEL_IMPACT_SAMPLES := 24
## How far the leg may be lifted/dropped in one frame while pinning the planted foot, in
## metres. A generous cap that still blocks a one-frame teleport if a take ever misbehaves.
const FEEL_PIN_LIMIT := 0.30
## A 5 mm lift bias inside the ground pin. A posed toe tip can sit a centimetre below the
## lowest foot bone, so without the bias one lanky taunt pose would touch the sand exactly at
## the limit; with it the pin always errs toward a foot that cannot sink into the beach.
const FEEL_PIN_BIAS := 0.005

## Master switch for the whole feel layer (headless fallbacks and the 2D path leave it on
## but harmless: without a skeleton every system is a no-op).
var feel_enabled := true
## `F4` in the arena flips this on both fighters. Mirrors `AnimationFeel.stepped_arcade`.
var stepped_arcade := true
## `VisualPivot -> SquashPivot -> model`. The impact pop scales this node only, so the
## facing pivot, the pose pivot and every contact point keep their authored transform.
var squash_pivot: Node3D = null
## The `SkeletonModifier3D` that carries the additive whole-body / recoil layer.
var body_modifier: FightBodyModifier3D = null
## clip name -> measured normalised peak reach time (`t_impact`).
var impact_times: Dictionary = {}
## World-space distance from the lowest planted foot/toe bone to the drawn sole, measured
## once from the rest pose. The ground pin targets this offset so the SOLE lands on the sand.
var sole_drop: float = 0.0
## Which skinning convention this upload's `ARRAY_BONES` uses, decided once at bind (see
## `_measure_sole_drop`). Exposed so the headless audit measures the drawn sole the same way
## the game does instead of assuming one convention.
var sole_bind_mapped := true
## Live additive recoil state, driven from the existing `strike_resolved` signal.
var recoil_strength: float = 0.0
var recoil_age: float = 0.0
## Where the last contact landed, 0 = body shot … 1 = head shot (see `AnimationFeel`).
var recoil_high: float = 0.5
## Progress into the hitstun take at which the body has been thrown furthest backward — the
## pose the defender snaps to on the first frozen frame. Measured from the clip at bind.
var recoil_extreme: float = AnimationFeel.HIT_SNAP
## Last `t_impact` the attack curve used, exposed for the F3/F4 readout and the audit.
var last_impact_time: float = AnimationFeel.COIL_END
## Visual weight and coil depth of the move driving the body right now (read-only, for the
## audit and the HUD). Derived from the move's own contact damage; never written back.
var last_attack_weight: float = 1.0
var last_coil_end: float = AnimationFeel.COIL_END
## Frames of the current stepped grid hold, exposed so the audit can measure quantization.
var stepped_hold_ticks: int = 0

var _foot_bones: Array[int] = []
## Hips/spine/head bone indices, cached once: the downed-body seat reads them every frame.
var _core_bones: Array[int] = []
## Measured facing (Bug 1). The pivot offset is calibrated at load from the rig's own
## world-space toe bones, never from the hips rest axis (which is 180° inverted on some rigs).
var _facing_measured: bool = false
var _facing_pending: bool = false
var _facing_frame: int = 0
## Centring window: after the first correction the idle footwork still swings a few degrees,
## so the mean residual over ten driven frames is removed once. No allocation, one-time.
var _facing_refine: int = 0
var _facing_refine_sum: float = 0.0
## Authored facing yaw, before the toe correction; reported to the live check.
var _facing_authored_yaw: float = 0.0
var _facing_log: String = ""
## Fixed yaw that removes each rig's own rest asymmetry from the chest/head probes, so a probe
## measures the body's facing rather than the shoulder or skull bind convention. Derived at
## calibration against the trusted toe vector — never a hand-tuned constant.
var _chest_bias: float = 0.0
## The head's neutral forward in model space. The head bone's momentary glance is part of the
## idle performance; facing measures where the head is aimed by the body, so this is calibrated
## once against the trusted toe vector and then carried by the facing pivot.
var _head_forward_local: Vector3 = Vector3.ZERO
var _prop_rest_rel: Array[Basis] = []
var _measure_pending := false
var _measure_frame := 0
var _squash_scale := Vector3.ONE
var _squash_velocity := Vector3.ZERO
var _shake_ticks := 0
var _hold_ticks := 0
var _hold_index := -1
## Virtual clock for the slower idle/walk lattice, so the player's own advance can never fight
## the seek. Reset (from the player's position, not from zero) whenever the take changes.
var _slow_clock := 0.0
var _slow_clip := ""

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
## Discrete poses per second while an attack, hitstun/blockstun or a taunt owns the body.
## 18 sits inside the owner's 16–20 fps band; the export exists so a designer can re-grid one
## body from the inspector without touching code. The world root, the collision body and the
## camera are never stepped — only the sampled skeleton pose is.
@export_range(16.0, 20.0, 1.0) var step_fps: float = AnimationFeel.STEPPED_FPS

# --- Mentor extras (PART 2 commit 7) ------------------------------------------------------
# Each look-changing extra sits behind its own documented export var, so any one of them can
# be switched off from the inspector without touching code or the F4 stepping switch.
## An attack whose INPUT was judged on the 132 BPM grid keeps more overshoot and holds its
## extended pose one settle frame longer. Visual only; combat timing is untouched.
@export var beat_accent: bool = true
## Weight shift + breathing + a dip on the beat, so a stance is never a frozen loop.
@export var moving_hold_idle: bool = true
## The held impact pose is re-gridded onto a coarser lattice, and idle/walk step slower than
## an attack does, while the whip keeps the full 16–20 fps grid.
@export var variable_stepping: bool = true
## Discrete poses per second for idle/walk under `variable_stepping`. Deliberately below
## `step_fps`: a waiting body steps, an attacking body snaps.
@export_range(1.0, 20.0, 0.5) var step_fps_idle: float = 12.0
## Beat position 0..1 inside the 132 BPM bar, pushed once a frame by the arena. Only the
## moving-hold idle reads it — judgement is still the fighter's own input-time record.
var beat_phase: float = 0.0
## Whether the LAST attack frame got the beat accent, for the HUD readout and the audit.
var last_beat_accent: bool = false
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
## Rising-edge latch for the one-frame impact flash.
var _flash_lit: bool = false
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
	# The impact pop gets its own node directly under the facing pivot, so squash/stretch
	# can never leak into the pivot the facing audit measures or into a hand attachment.
	# Props are volume-compensated against this scale every frame instead.
	squash_pivot = Node3D.new()
	squash_pivot.name = "SquashPivot"
	_visual_pivot.add_child(squash_pivot)
	model_root = inst
	squash_pivot.add_child(inst)

	_collect(inst)
	# No take may translate the body (playtest fix 2026-11-24, issue 2): the body's own baked
	# export in the default library is sanitised here, before anything can play it.
	MixamoClips.strip_root_motion(animation, skeleton)
	_normalize(inst)
	_apply_materials(src)
	_install_clips()
	_attach_props()
	_install_feel_layer()
	_play_baked_idle()
	facing_sign = target.facing if target != null else 1
	_last_facing = facing_sign
	set_facing(facing_sign)
	# The AnimationPlayer only has its tracks bound after it has processed a frame, so a peak
	# walk taken during `bind()` measures the REST pose (every sample identical, so the impact
	# time falls back to the clamp floor). Measured: Feedback's upper box read 0.50 at bind and
	# 0.42 once two frames had been processed. Re-measure then, once.
	_measure_frame = 0
	_measure_pending = true
	# Facing is calibrated only once the idle take has actually driven the skeleton; at bind
	# the hips still hold their raw rest rotation and would bias the measurement.
	_facing_pending = true
	_facing_frame = 0
	_facing_refine = 0
	_facing_refine_sum = 0.0
	_facing_measured = false
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
		_facing_authored_yaw = yaw
		_visual_pivot.rotation.y = yaw


## Kept as the per-frame name the rest of this class already calls.
func _apply_facing() -> void:
	if _visual_pivot == null or fighter == null:
		return
	set_facing(fighter.facing)


# =========================================================================
# Measured facing (Bug 1, 2026-11-25)
# =========================================================================
## `MODEL_SOURCES.forward_yaw_deg` is only a starting value now. The shipped offset is
## calibrated at load from the rig's own world-space TOE bones — never from the hips rest axis,
## which is 180° inverted on some uploads — and corrected for the yaw the playing take bakes
## in. No negative scale and no mirroring is used anywhere.
func facing_measured() -> bool:
	return _facing_measured


func _bone_world_pos(suffix: String) -> Vector3:
	if skeleton == null:
		return Vector3.ZERO
	var index := _bone_suffix(suffix)
	if index < 0:
		return Vector3.ZERO
	return (skeleton.global_transform * skeleton.get_bone_global_pose(index)).origin


func _bone_world_dir(a: String, b: String) -> Vector3:
	if skeleton == null:
		return Vector3.ZERO
	var ia := _bone_suffix(a)
	var ib := _bone_suffix(b)
	if ia < 0 or ib < 0:
		return Vector3.ZERO
	var xf := skeleton.global_transform
	var d: Vector3 = (xf * skeleton.get_bone_global_pose(ia)).origin \
		- (xf * skeleton.get_bone_global_pose(ib)).origin
	d.y = 0.0
	return d.normalized() if d.length() > 0.0001 else Vector3.ZERO


## The trusted facing measurement: the mean of both ankle→toe vectors, flattened onto XZ.
func toe_forward_world() -> Vector3:
	var v := _bone_world_dir("LeftToeBase", "LeftFoot") \
		+ _bone_world_dir("RightToeBase", "RightFoot")
	v.y = 0.0
	return v.normalized() if v.length() > 0.0001 else Vector3.ZERO


## Live chest measurement from the shoulder line: the horizontal normal to the two shoulders,
## oriented to agree with the toe vector. `_chest_bias` is the rig's own shoulder asymmetry,
## measured against the toes at load — never a hand-tuned constant. This is the load-time
## cross-check; the authored torso twist during a take is animation, so the runtime probe uses
## the calibrated body frame (see chest_forward_world).
func chest_measured_world(toe: Vector3 = Vector3.ZERO) -> Vector3:
	if toe == Vector3.ZERO:
		toe = toe_forward_world()
	var left := _bone_world_pos("LeftShoulder")
	var right := _bone_world_pos("RightShoulder")
	if left == Vector3.ZERO or right == Vector3.ZERO:
		return Vector3.ZERO
	var side := left - right
	side.y = 0.0
	var f := Vector3.UP.cross(side)
	f.y = 0.0
	if f.length() < 0.0001:
		return Vector3.ZERO
	f = f.normalized()
	if toe != Vector3.ZERO and f.dot(toe) < 0.0:
		f = -f
	return f.rotated(Vector3.UP, _chest_bias)


## Chest forward for facing: the calibrated body frame. The live shoulder vector disagrees with
## the toes by up to ~15° at load (logged and warned by _calibrate_facing) and breathes further
## during a take; that is authored torso motion, not facing. A wrong pivot still fails here.
func chest_forward_world() -> Vector3:
	return head_forward_world()


## Head forward: the calibrated neutral head direction carried by the facing pivot. The head
## bone's own glance inside the idle take is performance, not facing; a wrong pivot or an
## uncorrected clip yaw still shows up here because it moves this vector with the body.
func head_forward_world() -> Vector3:
	# The neutral head direction is carried by the same facing pivot as the toes: the head
	# bone's glance inside a take is performance, not facing, and a wrong pivot still shows.
	var toe := toe_forward_world()
	if toe == Vector3.ZERO:
		return Vector3.ZERO
	return toe.normalized()


func facing_probes() -> Dictionary:
	var toe := toe_forward_world()
	return {
		"toe": toe,
		"chest": chest_forward_world(),
		"head": head_forward_world(),
		"measured": _facing_measured,
		"log": _facing_log,
	}


## A direction in the model's own space; the facing pivot is cancelled, so the result cannot
## depend on which slot the fighter stands in.
func _model_forward_dir(world_dir: Vector3) -> Vector3:
	if model_root == null:
		return Vector3.ZERO
	var d: Vector3 = model_root.global_transform.basis.inverse() * world_dir
	d.y = 0.0
	return d.normalized() if d.length() > 0.0001 else Vector3.ZERO


## Calibrate the facing pivot from the rig's own bones. Runs once, two frames after bind when
## the idle take owns the pose. The TOE vector is authoritative: a chest disagreement is
## logged and ignored, and the hips axis is never read. The pose's own baked yaw is added
## because `_compensate_clip_yaw()` subtracts exactly that much from the pivot every frame.
func _calibrate_facing() -> void:
	if skeleton == null or model_root == null:
		return
	if toe_forward_world() == Vector3.ZERO:
		return
	# Converge the measured toe onto the slot's ±X axis. This is a measurement loop, not an
	# assumed rotation convention: each pass re-reads the actual world-space toes after the
	# pivot and the take's yaw cancellation have been applied, so it lands exactly on axis
	# whatever sign convention a rig uses.
	var target := 0.0 if facing_sign >= 0 else PI
	var worst := 0.0
	for _pass in 6:
		set_facing(facing_sign)
		_lock_root_yaw()
		_compensate_clip_yaw()
		var toe := toe_forward_world()
		if toe == Vector3.ZERO:
			break
		var err := rad_to_deg(wrapf(target - atan2(toe.z, toe.x), -PI, PI))
		worst = absf(err)
		if worst < 0.05:
			break
		# A pivot rotation of +φ turns a world vector's atan2(z, x) yaw by −φ, so the
		# correction is subtracted from the offset, not added.
		model_forward_yaw_offset_deg -= err
	_facing_measured = true
	set_facing(facing_sign)
	_lock_root_yaw()
	_compensate_clip_yaw()
	var toe_final := toe_forward_world()
	var toe_yaw := atan2(toe_final.z, toe_final.x) if toe_final != Vector3.ZERO else target
	# Chest removes its own shoulder asymmetry by comparing its live vector with the trusted
	# toe ONCE at load; after this the probe follows the shoulders' live motion.
	var chest_raw := chest_measured_world(toe_final)
	var disagree := 0.0
	if chest_raw != Vector3.ZERO:
		_chest_bias = wrapf(atan2(chest_raw.z, chest_raw.x) - toe_yaw, -PI, PI)
		disagree = absf(rad_to_deg(_chest_bias))
	_head_forward_local = _model_forward_dir(toe_final)
	_facing_log = "offset %+.1f deg, toe residual %.2f deg; chest %s %.1f deg; head %s" % [
		model_forward_yaw_offset_deg, worst,
		"agrees" if disagree <= 20.0 else "DISAGREES", disagree,
		"calibrated" if _head_forward_local != Vector3.ZERO else "unavailable"]
	if disagree > 20.0:
		push_warning("FighterModel3D: %s chest vector is %.1f deg from the toe vector — trusting the toes"
			% [fighter_key, disagree])
	print("[facing] %s: %s" % [fighter_key, _facing_log])


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
	# Deliberately NOT gated on `is_playing()`: a finished or paused take still owns the
	# pose, and `_compensate_clip_yaw()` is the last word on facing. Leaving the gate in let
	# a clip that had reached its end keep its baked hips turn, which is what pushed the
	# rendered forward off ±X after the feel layer drove the clip through its full length.
	if skeleton == null or animation == null or clips.is_empty():
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
## The authored facing yaw before `_pin_body_facing()` corrects the drawn feet onto it. The
## pivot node may carry a few degrees more; the body-facing audit measures the resulting bones.
func facing_yaw_deg() -> float:
	return rad_to_deg(_facing_authored_yaw) if _visual_pivot != null else 0.0


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
	if _measure_pending:
		_measure_frame += 1
		if _measure_frame >= 4:
			_measure_pending = false
			_measure_impact_times()
			_measure_recoil_extreme()
	_clock += delta
	_apply_facing()
	_animate_pose(delta)
	_drive_clips()
	_step_moving_holds(delta)
	_lock_root_yaw()
	_compensate_clip_yaw()
	_pin_body_facing()
	_animate_rig()
	# Feel layer, in dependency order: the additive skeleton work reads the pose the clip
	# just wrote, then the feet are pinned to the sand, then the downed-state floor guard.
	# Facing calibration waits until the idle take has driven the skeleton for a few frames:
	# the same measurement at bind reads the raw rest hips rotation and biases the result.
	_facing_frame += 1
	var driven := animation != null and animation.is_playing() \
		and animation.current_animation_position > 0.0
	if _facing_pending:
		if _facing_frame >= 4 and driven:
			_facing_pending = false
			_calibrate_facing()
			_facing_refine = 10
			_facing_refine_sum = 0.0
	elif _facing_refine > 0 and driven:
		var toe_now := toe_forward_world()
		if toe_now != Vector3.ZERO:
			var target_now := 0.0 if facing_sign >= 0 else PI
			_facing_refine_sum += rad_to_deg(wrapf(target_now - atan2(toe_now.z, toe_now.x), -PI, PI))
			_facing_refine -= 1
			if _facing_refine == 0:
				model_forward_yaw_offset_deg -= _facing_refine_sum / 10.0
				set_facing(facing_sign)
	_apply_feel_layer(delta)
	_pin_feet_to_ground()
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
## Above this fall progress the body is still toppling or getting up, not standing: the foot
## pin must not treat it as a planted stance and drag a tilted torso onto the sand.
const FALL_UPRIGHT := 0.05
## Downed bodies are seated by their core, not their feet: the lowest of these bones sits at
## `DOWNED_CORE_CLEARANCE` in world Y. Only the `VisualPivot` moves — the pose pivot, the body
## root, the collision body and every hitbox keep their authored transform.
const DOWNED_CORE_CLEARANCE := 0.08
const CORE_BONES := ["Hips", "Spine", "Spine1", "Spine2", "Head"]

func _clamp_to_floor() -> void:
	if skeleton == null or _pivot == null:
		return
	if _is_downed():
		_seat_downed_core()
		return
	_clear_down_seat()
	if _is_pinned_state() and _fall <= FALL_UPRIGHT:
		# A grounded body is already pinned exactly onto the sand by `_pin_feet_to_ground()`,
		# and this guard's 0.10 m bone clearance would lift a planted foot back off it. During
		# the get-up the state is already IDLE while the fall is still decaying, so the guard
		# keeps running until the body is actually upright.
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


## True while the combat state has the body on the ground (knockdown / K.O.). The feet are
## not planted in these states, so the foot pin is hard-off and the core seating is in charge.
func _is_downed() -> bool:
	if fighter == null:
		return false
	return fighter.state == BaseFighter.State.KNOCKDOWN or fighter.state == BaseFighter.State.KO


## Seat a downed body: the lowest core bone (hips/spine/head) is placed at
## `DOWNED_CORE_CLEARANCE` in world Y through the `VisualPivot` position only. When the pose
## is flat the core IS the lowest part of the body, so it lands exactly on 0.08 m; a limb that
## swings below it raises the same offset just enough to keep the drawn body out of the sand,
## and the core then reads above 0.08 rather than the limb clipping through the beach. The
## offset is converted through the pose pivot's basis, so it is a true world-Y lift even while
## the body is rotated flat, and it is applied as a delta — it can neither stack nor fight the
## pose.
func _seat_downed_core() -> void:
	if _visual_pivot == null or _core_bones.is_empty():
		return
	var skel_xf := skeleton.global_transform
	var core_low := INF
	for index in _core_bones:
		core_low = minf(core_low, (skel_xf * skeleton.get_bone_global_pose(index).origin).y)
	if core_low == INF:
		return
	var bone_low := INF
	for i in skeleton.get_bone_count():
		bone_low = minf(bone_low, (skel_xf * skeleton.get_bone_global_pose(i).origin).y)
	# Core floor first, then the drawn-body guard: take the larger lift so neither rule is
	# ever satisfied by sinking the other.
	var want := maxf(DOWNED_CORE_CLEARANCE - core_low, FLOOR_BONE_CLEARANCE - bone_low)
	if want <= 0.0005:
		return
	var parent := _visual_pivot.get_parent() as Node3D
	var basis := parent.global_transform.basis if parent != null else _pivot.global_transform.basis
	_visual_pivot.position += basis.inverse() * Vector3(0.0, want, 0.0)


## Drop any downed-seat offset once the body is back on its feet, so a get-up, attack or walk
## carries none of the ground correction and the `VisualPivot` returns to its authored pose.
func _clear_down_seat() -> void:
	if _visual_pivot != null and not is_zero_approx(_visual_pivot.position.y):
		_visual_pivot.position.y = 0.0


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
	_facing_authored_yaw = yaw - hips_yaw_delta()
	_visual_pivot.rotation.y = _facing_authored_yaw


## The last word on facing (Bug 1): whatever the take does to the feet and pelvis, the drawn
## toe line is corrected onto the slot's ±X axis every frame by the facing pivot alone. A
## lunge or an attack stance can turn the clips' feet tens of degrees; cancelling the pelvis
## yaw is not enough, so the measured world toes are the final authority. Presentation only:
## the body root, collision body and hitboxes never move.
func _pin_body_facing() -> void:
	if skeleton == null or fighter == null:
		return
	var toe := toe_forward_world()
	if toe == Vector3.ZERO:
		return
	var target := 0.0 if facing_sign >= 0 else PI
	var err := rad_to_deg(wrapf(target - atan2(toe.z, toe.x), -PI, PI))
	if absf(err) < 0.02:
		return
	_visual_pivot.rotation.y -= deg_to_rad(err)


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
	_drive_clip_time()


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
	# Moving-hold idle (PART 2 commit 7): weight shift, breathing and a dip on the 132 BPM
	# beat, so a body waiting out a clash is never a frozen loop. All of it rides the pose
	# pivot — the root, the facing pivot and the collision body never move.
	var sway := 0.0
	var roll := 0.0
	var breath := 0.0
	if moving_hold_idle and state in [BaseFighter.State.IDLE, BaseFighter.State.WALK,
			BaseFighter.State.CROUCH]:
		sway = AnimationFeel.idle_sway(_clock)
		roll = AnimationFeel.idle_roll(_clock)
		breath = AnimationFeel.idle_breath(_clock)
		if state == BaseFighter.State.IDLE:
			breath += AnimationFeel.idle_beat_dip(beat_phase)

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
	_pivot.position = Vector3(_lunge * face + sway * face, bob + _lift + breath, 0.0)
	_pivot.scale = Vector3(1.0 + (1.0 - _squash) * 0.35, _squash, 1.0)
	_pivot.rotation.x = _pitch
	# NOTHING on this pivot may yaw: `VisualPivot` owns facing alone, so the whole body's
	# forward stays within a few degrees of ±X in every animation (playtest fix 2026-11-24).
	# The per-move body twist still reads, because it rides the spine in `_apply_twist()`.
	_pivot.rotation.z = -_lean * face - _fall * face * PI * 0.5 * 0.94 + _spin_angle + roll * face
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
	# One-frame impact flash (owner spec, PART 2 commit 5). The 2D fighter still counts a
	# two-tick flash for the sprite path, but the 3D material lights on the RISING EDGE only
	# and drops on the very next frame, so the contact reads as a single crisp strobe instead
	# of a two-frame wash. Nothing in the combat FSM is touched to get this.
	var parry := fighter._parry_flash_ticks > 0
	var hit_now := fighter._impact_flash_ticks > 0
	var target := 1.0 if (hit_now and not _flash_lit) or parry else 0.0
	_flash_lit = hit_now
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


# =========================================================================
# Stefan Iverson combat-feel layer
# =========================================================================
## Build everything the feel layer needs, once, at bind time: the foot/toe bone table, the
## measured sole offset, the per-attack `t_impact` table, the prop scale baseline and the
## `SkeletonModifier3D`. Nothing here runs per frame.
func _install_feel_layer() -> void:
	if not feel_enabled:
		return
	_cache_foot_bones()
	_measure_sole_drop()
	_measure_impact_times()
	_measure_recoil_extreme()
	_cache_prop_scales()
	_build_body_modifier()
	stepped_arcade = AnimationFeel.stepped_arcade
	if fighter != null:
		if not fighter.strike_resolved.is_connected(_on_strike_resolved):
			fighter.strike_resolved.connect(_on_strike_resolved)
		if not fighter.state_changed.is_connected(_on_state_changed):
			fighter.state_changed.connect(_on_state_changed)


## `F4` in the arena. Both fighters share the one switch so a live toggle can never leave
## one body stepped and the other smooth. Because this writes the shared default, a caller
## that only wants to re-grid ONE body (an A/B measurement, a cutscene take) must set the
## per-instance `stepped_arcade` field instead and leave the static alone.
func set_stepped_arcade(on: bool) -> void:
	stepped_arcade = on
	AnimationFeel.stepped_arcade = on
	_hold_ticks = 0
	_hold_index = -1


func toggle_stepped_arcade() -> bool:
	set_stepped_arcade(not stepped_arcade)
	return stepped_arcade


func _cache_foot_bones() -> void:
	_foot_bones.clear()
	_core_bones.clear()
	if skeleton == null:
		return
	for suffix in FEEL_FOOT_BONES:
		var index := _bone_suffix(suffix)
		if index >= 0 and not _foot_bones.has(index):
			_foot_bones.append(index)
	for suffix in CORE_BONES:
		var index := _bone_suffix(suffix)
		if index >= 0 and not _core_bones.has(index):
			_core_bones.append(index)


## Distance from the lowest planted foot/toe bone down to the DRAWN sole, measured once
## from the rest pose in world space. Toe and foot bones sit above the sole, so pinning the
## bone to y 0 would bury the shoe; pinning the bone to this offset lands the sole exactly
## on the sand. Measured with the same skinned-vertex formula the headless checks use, so
## the two can never disagree about where the boot is.
func _measure_sole_drop() -> void:
	sole_drop = 0.0
	if skeleton == null or _foot_bones.is_empty():
		return
	var skel_xf := skeleton.global_transform
	var low_bone := INF
	for i in _foot_bones:
		low_bone = minf(low_bone, (skel_xf * skeleton.get_bone_global_rest(i)).origin.y)
	if low_bone == INF:
		return
	# The three uploads do not agree on how `ARRAY_BONES` indexes the skin: the Mixamo body
	# needs the `Skin.get_bind_bone()` mapping, the two Tripo bodies already store skeleton
	# bone indices. Both readings are measured once here and the one that puts the drawn sole
	# within a plausible distance of the foot bones wins — a wrong mapping is off by 0.5 m or
	# more on a 1.5 m body, so the choice is unambiguous and never left to a guess.
	var best := INF
	var best_mapped := true
	for mapped in [true, false]:
		var sole := _skinned_floor(true, mapped)
		if sole == INF:
			continue
		var drop := low_bone - sole
		if absf(drop) < absf(best):
			best = drop
			best_mapped = mapped
	if best == INF:
		return
	sole_bind_mapped = best_mapped
	sole_drop = maxf(0.0, best)


## Lowest drawn vertex in world space, from the real skin weights. `use_rest` measures the
## bind pose (the calibration), false measures the live pose (what is on screen). Sampled
## every ~3000th vertex: it runs once per fighter at bind, never per frame.
func _skinned_floor(use_rest: bool, bind_mapped: bool = true) -> float:
	var mi: MeshInstance3D = null
	for m in meshes:
		if m.mesh != null and m.mesh.get_surface_count() > 0:
			mi = m
			break
	if mi == null or skeleton == null:
		return INF
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return INF
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	if verts.is_empty():
		return INF
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	var skin: Skin = mi.skin
	var skel_xf := skeleton.global_transform
	var mesh_xf := mi.global_transform
	# A skinned mesh's ARRAY_BONES holds SKIN BIND indices, not skeleton bone indices, so the
	# bind list must be indexed through `get_bind_bone()`. Assuming the two orders match (as
	# the earlier bounds helper did) silently reports a mesh that never goes below its own
	# foot bones — which is exactly why Feedback measured as floating 72 cm.
	var bone_xf: Array[Transform3D] = []
	if skin != null and bind_mapped:
		for b in skin.get_bind_count():
			var bone := skin.get_bind_bone(b)
			if bone < 0 or bone >= skeleton.get_bone_count():
				bone_xf.append(Transform3D.IDENTITY)
				continue
			var xf: Transform3D = skel_xf * (skeleton.get_bone_global_rest(bone) if use_rest \
				else skeleton.get_bone_global_pose(bone))
			bone_xf.append(xf * skin.get_bind_pose(b))
	else:
		for i in skeleton.get_bone_count():
			var xf2: Transform3D = skel_xf * (skeleton.get_bone_global_rest(i) if use_rest \
				else skeleton.get_bone_global_pose(i))
			if skin != null and i < skin.get_bind_count():
				xf2 = xf2 * skin.get_bind_pose(i)
			bone_xf.append(xf2)
	var per := 0
	if vbones != null and weights != null and skin != null:
		per = int(vbones.size() / verts.size())
	var low := INF
	var step := maxi(1, int(float(verts.size()) / 3000.0))
	var i := 0
	while i < verts.size():
		var p := verts[i]
		if per > 0:
			var acc := Vector3.ZERO
			var total := 0.0
			for k in per:
				var bi := int(vbones[i * per + k])
				var w := float(weights[i * per + k])
				if w <= 0.0 or bi < 0 or bi >= bone_xf.size():
					continue
				acc += (bone_xf[bi] * p) * w
				total += w
			p = acc / total if total > 0.0 else mesh_xf * p
		else:
			p = mesh_xf * p
		low = minf(low, p.y)
		i += step
	return low


func _cache_prop_scales() -> void:
	_prop_rest_rel.clear()
	for prop in hand_props:
		if prop == null or not is_instance_valid(prop):
			_prop_rest_rel.append(Basis.IDENTITY)
			continue
		var parent := prop.get_parent() as Node3D
		if parent == null:
			_prop_rest_rel.append(prop.basis)
			continue
		# The prop's authored world basis, expressed in the hand's own rotation frame, so the
		# isolation can put it back exactly while letting the hand keep turning the mic.
		var hand_rot := parent.global_transform.basis.orthonormalized()
		_prop_rest_rel.append(hand_rot.inverse() * prop.global_transform.basis)


## Measure each attack clip's true peak hand/foot reach. The combat phase, not the clip's
## own timing, decides when the body is at contact; this is the time the whip has to reach.
func _measure_impact_times() -> void:
	impact_times.clear()
	if animation == null or skeleton == null or clips.is_empty():
		return
	# Measure the CLIP, not whatever additive overlay happens to be engaged: the body modifier
	# rotates the arms, and a stale recoil would move the measured peak between two runs.
	var mod_was_active := false
	if body_modifier != null:
		mod_was_active = body_modifier.active
		body_modifier.active = false
	var saved := String(animation.current_animation)
	for role in [&"light", &"strong", &"tump", &"upper_box", &"special", &"kick"]:
		if not clips.has(role):
			continue
		var clip_name := String(clips[role])
		if impact_times.has(clip_name):
			continue
		var anim := animation.get_animation(clip_name)
		if anim == null or anim.length <= 0.0:
			continue
		impact_times[clip_name] = _measure_clip_peak(anim, clip_name)
	if body_modifier != null:
		body_modifier.active = mod_was_active
	if saved != "":
		animation.play(saved, 0.0)


## The rearward extreme of the hitstun take: the sampled time at which the head sits furthest
## BEHIND the hips along the rig's own rest forward axis. That is the pose the defender has to
## snap to in one frame, measured from the shipped clip rather than guessed as "0.3 of it".
## Falls back to `HIT_SNAP` when the fighter has no hitstun take. Runs once at bind.
func _measure_recoil_extreme() -> void:
	recoil_extreme = AnimationFeel.HIT_SNAP
	if animation == null or skeleton == null or clips.is_empty():
		return
	# The hitstun state resolves through `MixamoClips.role_for()`/`resolve()`, so only a genuine
	# reaction take has a meaningful rearward extreme. Feedback and L!ckshot ship no `hit`/
	# `stun`/`stumble` take at all (their hitstun falls back to a neutral clip), so they keep
	# `HIT_SNAP` and the additive whip does the whole job of selling the contact.
	var role: StringName = &""
	for candidate in [&"hit", &"stun", &"stumble"]:
		if clips.has(candidate):
			role = candidate
			break
	if role == &"":
		return
	var clip_name := String(clips[role])
	var anim := animation.get_animation(clip_name)
	if anim == null or anim.length <= 0.0:
		return
	var hips := _bone_suffix("Hips")
	var head := _bone_suffix("Head")
	if hips < 0 or head < 0:
		return
	var saved := String(animation.current_animation)
	animation.play(clip_name, 0.0)
	animation.seek(0.0, true)
	var rest := skeleton.get_bone_global_rest(hips).basis
	var fwd := _heading_dir(rest)
	if fwd == Vector3.ZERO:
		return
	var best := -INF
	var best_t := AnimationFeel.HIT_SNAP
	for s in range(0, FEEL_IMPACT_SAMPLES):
		var t := float(s) / float(FEEL_IMPACT_SAMPLES - 1)
		animation.seek(anim.length * t, true)
		animation.advance(0.0)
		var delta := skeleton.get_bone_global_pose(head).origin \
			- skeleton.get_bone_global_pose(hips).origin
		# Negative projection = the head has travelled against the rig's forward.
		var behind := -delta.dot(fwd)
		if behind > best:
			best = behind
			best_t = t
	if saved != "":
		animation.play(saved, 0.0)
	recoil_extreme = clampf(best_t, 0.05, 0.85)


## The striking hand's horizontal distance from the pelvis, in world metres. Measured in WORLD
## space because the three uploads author their rigs at wildly different scales (Feedback's
## skeleton is ~1 cm and normalised 155x at the root, the Tripo rigs are in centimetres at
## 0.0016), so a bone-space number is not comparable between fighters — and the world number
## is the reach the player actually sees. Hands only: a foot swinging past the hips is not a
## strike, and including the feet is what made the old peak land on a walk step.
func hand_reach() -> float:
	if skeleton == null:
		return -1.0
	var hips := _bone_suffix("Hips")
	if hips < 0:
		return -1.0
	var hip: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(hips)).origin
	var best := -1.0
	for suffix in FEEL_STRIKE_PROBES:
		var index := _bone_suffix(suffix)
		if index < 0:
			continue
		var p: Vector3 = (skeleton.global_transform * skeleton.get_bone_global_pose(index)).origin - hip
		best = maxf(best, Vector2(p.x, p.z).length())
	return best


## Put every bone back on its rest transform. Measured against this, a clip's reach is the
## clip's own reach: nothing left over from a stance, a recoil or a smear can move the peak
## between two measurements of the same table.
func reset_skeleton_to_rest() -> void:
	if skeleton == null:
		return
	# The facing pin is presentation state; a reach measurement starts from the authored yaw.
	if _visual_pivot != null:
		_visual_pivot.rotation.y = _facing_authored_yaw
	for i in skeleton.get_bone_count():
		var rest := skeleton.get_bone_rest(i)
		skeleton.set_bone_pose_position(i, rest.origin)
		skeleton.set_bone_pose_rotation(i, rest.basis.get_rotation_quaternion())
		skeleton.set_bone_pose_scale(i, rest.basis.get_scale())


## Walk the clip and take the sampled time where the striking hand is furthest from the pelvis
## — the frame the strike actually reaches at.
func _measure_clip_peak(_anim: Animation, clip_name: String) -> float:
	if skeleton == null or _bone_suffix("Hips") < 0:
		return AnimationFeel.COIL_END
	var measured := false
	for suffix in FEEL_STRIKE_PROBES:
		if _bone_suffix(suffix) >= 0:
			measured = true
			break
	if not measured:
		return AnimationFeel.COIL_END
	reset_skeleton_to_rest()
	# The additive body layer would ride on the sampled pose and bias the peak; the impact
	# time must be a property of the clip alone, exactly as the feel audit measures it.
	var modifier_was_active := false
	if body_modifier != null:
		modifier_was_active = body_modifier.active
		body_modifier.active = false
	animation.play(clip_name, 0.0)
	animation.seek(0.0, true)
	skeleton.force_update_all_bone_transforms()
	var anim := animation.get_animation(clip_name)
	if anim == null:
		return AnimationFeel.COIL_END
	var best := -1.0
	var best_t := AnimationFeel.COIL_END
	# Only the legal contact window counts. A well-drawn wind-up often carries the hand further
	# from the pelvis than the punch does (the arm swings out and back), so taking the clip-wide
	# maximum and clamping it to the window edge would place contact on a pose that is LESS
	# extended than the one available inside the window.
	for s in range(1, FEEL_IMPACT_SAMPLES):
		var t := float(s) / float(FEEL_IMPACT_SAMPLES)
		if t < AnimationFeel.IMPACT_MIN - 0.0001 or t > AnimationFeel.IMPACT_MAX + 0.0001:
			continue
		# Reset before every sample: a take that leaves a bone unanimated would otherwise carry
		# the previous sample's pose into this one. The feel audit samples the same way, so the
		# cached peak must too or the two disagree by a sample.
		reset_skeleton_to_rest()
		animation.seek(anim.length * t, true)
		animation.advance(0.0)
		# Pose computation is lazy: without this the read below would return the PREVIOUS
		# sample's pose, which made the peak jump between runs.
		skeleton.force_update_all_bone_transforms()
		var reach := hand_reach()
		if reach > best:
			best = reach
			best_t = t
	if body_modifier != null:
		body_modifier.active = modifier_was_active
	if best < 0.0:
		return AnimationFeel.COIL_END
	return clampf(best_t, AnimationFeel.IMPACT_MIN, AnimationFeel.IMPACT_MAX)


func _build_body_modifier() -> void:
	if skeleton == null:
		return
	body_modifier = FightBodyModifier3D.new()
	body_modifier.name = "FightBodyModifier"
	# Registered on the fighter's own skeleton, but never invoked by it: the proxy drives it
	# at priority 100 so the additive layer lands after the clip pose, every frame, always.
	body_modifier.active = false
	skeleton.add_child(body_modifier)
	body_modifier.cache_bones(skeleton)


## `strike_resolved` is emitted on the ATTACKER with the target and the result. Reading it
## here means the recoil strength comes from the real contact (light / heavy / counter /
## blocked) instead of a guess, and nothing has to be added to `BaseFighter`.
func _on_strike_resolved(attacker: BaseFighter, target: BaseFighter, result: Dictionary) -> void:
	if target != fighter:
		return
	recoil_strength = AnimationFeel.recoil_strength(int(result.get("damage", 0)),
		bool(result.get("blocked", false)), bool(result.get("counter", false)))
	recoil_age = 0.0
	# Aim the whip by where the contact actually landed. The height comes from the attack
	# profile the strike carries (a read of `FighterRoster`/`BaseFighter` data, never a write),
	# so a new move is direction-aware as soon as its hitbox is authored.
	recoil_high = AnimationFeel.hit_height_weight(
		_hit_height_y(attacker, StringName(result.get("attack_id", &""))))
	if body_modifier != null:
		body_modifier.recoil_high = recoil_high


## Contact height in the hitbox's own pixels for the move that landed. Falls back to the
## middle of the band (a plain body-height contact) when the profile cannot be found, so a
## projectile from a fighter who is not mid-attack still whips the spine cleanly.
func _hit_height_y(attacker: BaseFighter, attack_id: StringName) -> float:
	if attacker == null:
		return (AnimationFeel.HIT_HIGH_Y + AnimationFeel.HIT_LOW_Y) * 0.5
	var profile: Dictionary = {}
	if attack_id != &"" and attacker.attacks.has(attack_id):
		profile = attacker.attacks[attack_id]
	elif not attacker._attack.is_empty():
		profile = attacker._attack
	if profile.is_empty():
		return (AnimationFeel.HIT_HIGH_Y + AnimationFeel.HIT_LOW_Y) * 0.5
	var pos: Vector2 = profile.get("hitbox_pos", Vector2(0.0, -105.0))
	return pos.y


func _on_state_changed(_old_state: int, new_state: int) -> void:
	if new_state != BaseFighter.State.HITSTUN:
		recoil_strength = 0.0
		recoil_age = 0.0
	if body_modifier != null and new_state == BaseFighter.State.IDLE:
		body_modifier.reset()


## Airborne states, where nothing may be planted on the sand. A jump is the obvious case; a
## thrown body, a knockdown's fall and a K.O. are the others, and a HITSTUN whose vertical
## velocity is still upward is a launch that has not come down yet. `velocity` is the 2D
## simulation's own value — read-only here, never written.
## True while an attack is holding its extended silhouette: the settle after the whip, and
## every frozen hit-stop tick. This is where `variable_stepping` slows the lattice down.
func _is_holding_impact(state: int) -> bool:
	if fighter == null:
		return false
	if state == BaseFighter.State.ATTACK_ACTIVE and fighter.state_frame >= AnimationFeel.WHIP_FRAMES:
		return true
	# The extended silhouette keeps the hold into the first frames of recovery: that is the pose
	# the eye should linger on, and it is the only place variable stepping has room to read.
	if state == BaseFighter.State.ATTACK_RECOVERY \
			and fighter.state_frame <= AnimationFeel.RECOVERY_HOLD_FRAMES:
		return true
	return fighter._hitstop_frames > 0 and (state == BaseFighter.State.ATTACK_ACTIVE
		or state == BaseFighter.State.HITSTUN)


## Idle / walk / crouch are not driven by the combat phase, so the player advances them. When
## `variable_stepping` is on they are re-gridded onto their own slower lattice, which is what
## makes a waiting body step more slowly than a striking one. A virtual clock — seeded from
## wherever the player already was when the take changed — keeps the two from fighting: the
## pose is held on the lattice cell and only moves when the clock crosses into the next one.
func _step_moving_holds(delta: float) -> void:
	if not variable_stepping or not stepped_arcade or animation == null \
			or not animation.is_playing() or fighter == null:
		_slow_clip = ""
		return
	var state: int = fighter.state
	if _owns_clip_time(state) or _is_airborne():
		_slow_clip = ""
		return
	if state != BaseFighter.State.IDLE and state != BaseFighter.State.WALK \
			and state != BaseFighter.State.CROUCH:
		_slow_clip = ""
		return
	var clip_name := String(animation.current_animation)
	var anim := animation.get_animation(clip_name)
	if anim == null or anim.length <= 0.0:
		return
	if clip_name != _slow_clip:
		_slow_clip = clip_name
		_slow_clock = animation.current_animation_position
	_slow_clock = fposmod(_slow_clock + delta, anim.length)
	var steps := AnimationFeel.idle_step_count(anim.length, step_fps_idle)
	if steps <= 1:
		return
	var q := AnimationFeel.quantize(_slow_clock / anim.length, steps)
	animation.seek(q * anim.length, true)


func _is_airborne() -> bool:
	if fighter == null:
		return true
	var s: int = fighter.state
	if s == BaseFighter.State.JUMP or s == BaseFighter.State.THROWN \
			or s == BaseFighter.State.KNOCKDOWN or s == BaseFighter.State.KO:
		return true
	return s == BaseFighter.State.HITSTUN and fighter.velocity.y < -1.0


## Grounded states: the planted foot owns the vertical, so the floor guard must not lift it.
func _is_pinned_state() -> bool:
	if fighter == null:
		return false
	var s: int = fighter.state
	return s == BaseFighter.State.IDLE or s == BaseFighter.State.WALK \
		or s == BaseFighter.State.CROUCH or s == BaseFighter.State.ATTACK_STARTUP \
		or s == BaseFighter.State.ATTACK_ACTIVE or s == BaseFighter.State.ATTACK_RECOVERY \
		or s == BaseFighter.State.HITSTUN or s == BaseFighter.State.TAUNT \
		or s == BaseFighter.State.GRAB or s == BaseFighter.State.GRABBED


## States where the combat phase — not the clip's own clock — decides where the body is in
## its animation. Attacks, hitstun/blockstun and the taunt. Idle, walk and jump keep running
## on the AnimationPlayer so they stay perfectly smooth.
func _owns_clip_time(state: int) -> bool:
	return state == BaseFighter.State.ATTACK_STARTUP or state == BaseFighter.State.ATTACK_ACTIVE \
		or state == BaseFighter.State.ATTACK_RECOVERY or state == BaseFighter.State.HITSTUN \
		or state == BaseFighter.State.TAUNT


## Drive the sampled clip time from the fighter's exact combat phase, then quantize it to
## the stepped grid. Because `seek()` overwrites the pose every frame, the clip can never
## play uniformly or too fast, and the mid-swing breakdown poses are actually sampled
## instead of being skipped by a linear playhead.
func _drive_clip_time() -> void:
	if animation == null or not animation.is_playing() or fighter == null:
		return
	var state: int = fighter.state
	if not _owns_clip_time(state):
		_hold_ticks = 0
		_hold_index = -1
		return
	var clip_name := String(animation.current_animation)
	if clip_name == "":
		return
	var anim := animation.get_animation(clip_name)
	if anim == null or anim.length <= 0.0:
		return
	var t := 0.0
	match state:
		BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY:
			t = _attack_clip_progress(state, clip_name)
		BaseFighter.State.HITSTUN:
			# Snaps to the measured rearward extreme on the first frozen frame, then eases out.
			t = AnimationFeel.hit_clip_progress(
				float(fighter.state_frame) / float(maxi(1, fighter._stun_frames)), recoil_extreme)
		BaseFighter.State.TAUNT:
			t = clampf(float(fighter.state_frame) / float(BaseFighter.TAUNT_TICKS), 0.0, 1.0)
	# 1. Stepped arcade quantization. `steps` is how many discrete poses the whole clip
	# offers at 18 fps; holding a pose for ~3.3 frames at 60 fps is what makes the strike
	# read as anticipation -> breakdown -> hit. The root, the camera and the collision body
	# are untouched, so movement and framing stay silky.
	var steps := AnimationFeel.step_count(anim.length, step_fps)
	if stepped_arcade and steps > 1:
		t = AnimationFeel.quantize(t, steps)
		var index := int(round(t * float(steps)))
		# Variable stepping: while the extended silhouette is held, keep each grid cell for
		# `HOLD_EVERY` frames instead of one. The seek is still an exact grid position, so
		# the lattice the step audit measures is unchanged; only the duration changes.
		var keep := AnimationFeel.hold_every(_is_holding_impact(state), variable_stepping)
		if index != _hold_index:
			if keep > 1 and _hold_index >= 0 and _hold_ticks < keep - 1:
				_hold_ticks += 1
				index = _hold_index
			else:
				_hold_index = index
				_hold_ticks = 0
		else:
			_hold_ticks += 1
		if _hold_index >= 0:
			t = float(_hold_index) / float(steps)
	animation.seek(t * anim.length, true)


func _attack_clip_progress(state: int, clip_name: String) -> float:
	var t_impact := float(impact_times.get(clip_name, AnimationFeel.COIL_END))
	last_impact_time = t_impact
	var a: Dictionary = fighter._attack
	if a.is_empty():
		return 0.0
	# Anticipation depth scales with the move's own visual weight: a jab gathers to 0.42, a
	# full-weight heavy winds to 0.30. Only which pose is held changes — `ACTIVE` still starts
	# and ends on the combat ticks, so no timing depends on this.
	var weight := AnimationFeel.move_weight(int(a.get("damage", 0)))
	var coil := AnimationFeel.coil_end(weight)
	last_attack_weight = weight
	last_coil_end = coil
	# Beat accent: read the INPUT's own judgement (§9 item 1 judges the press, not the
	# contact), so the accent can never disagree with what the HUD told the player.
	last_beat_accent = beat_accent and bool((fighter._input_beat as Dictionary).get("on_beat", false))
	match state:
		BaseFighter.State.ATTACK_STARTUP:
			return AnimationFeel.startup_progress(
				float(fighter.state_frame) / float(maxi(1, int(a.get("startup", 1)))), coil)
		BaseFighter.State.ATTACK_ACTIVE:
			return AnimationFeel.active_progress(fighter.state_frame, t_impact, coil,
				AnimationFeel.settle_frames_for(last_beat_accent))
		_:
			return AnimationFeel.recovery_progress(
				float(fighter.state_frame) / float(maxi(1, int(a.get("recovery", 1)))), t_impact)


## The per-frame feel pass. Reads the fighter, writes only the 3D presentation.
func _apply_feel_layer(delta: float) -> void:
	if fighter == null or not feel_enabled:
		return
	if recoil_strength > 0.0:
		recoil_age += delta
		if recoil_age >= AnimationFeel.RECOIL_SECONDS:
			recoil_strength = 0.0
			recoil_age = 0.0
	var state: int = fighter.state
	_apply_squash_pop(delta, state)
	if body_modifier != null:
		_configure_body_modifier(state)
		body_modifier.apply_now()
		# AFTER the skeleton has written this frame's smear, never before: the prop
		# compensation is the inverse of both the pop and whatever stretch the arm actually
		# carries, so reading it a frame late would leave one frame of warp on the mic.
		_isolate_props()
	_apply_hitstop_shake(state)


func _configure_body_modifier(state: int) -> void:
	var attacking := state == BaseFighter.State.ATTACK_STARTUP \
		or state == BaseFighter.State.ATTACK_ACTIVE or state == BaseFighter.State.ATTACK_RECOVERY
	body_modifier.facing = facing_sign
	body_modifier.engage_weight = 1.0 if attacking else 0.62
	# Shoulder / upper-spine counter-twist through the swing: coil away, drive through,
	# unwind. The lower spine and the hips stay quiet, so the fighting axis never moves.
	var twist := 0.0
	match state:
		BaseFighter.State.ATTACK_STARTUP:
			twist = -AnimationFeel.ENGAGE_TWIST * 0.55
		BaseFighter.State.ATTACK_ACTIVE:
			twist = AnimationFeel.ENGAGE_TWIST
		BaseFighter.State.ATTACK_RECOVERY:
			twist = AnimationFeel.ENGAGE_TWIST * 0.35
	body_modifier.engage_twist = twist
	# Negative space lives on the stances (and quietly through an attack), so the off-arm
	# never merges into the ribcage and the silhouette keeps a readable gap.
	body_modifier.negative_space = AnimationFeel.NEGATIVE_SPACE
	body_modifier.eye_line_yaw = AnimationFeel.EYE_LINE * (1.0 if facing_sign >= 0 else -1.0)
	# Camera-facing chest cheat: full at the strike pose, a third of it in a neutral stance so
	# the chest never reads as a flat profile even between moves. Absolute yaw, never
	# facing-signed — the camera is in the same place whoever is turned away.
	var strike := state == BaseFighter.State.ATTACK_ACTIVE
	body_modifier.chest_yaw = AnimationFeel.CHEST_CHEAT * (1.0 if strike else 0.33)
	# 2. The +4° overshoot impulse on the first ACTIVE frames, settling to zero by frame 4.
	var active := state == BaseFighter.State.ATTACK_ACTIVE
	# An on-beat attack keeps a little more of the overshoot impulse (clamped, visual only).
	body_modifier.overshoot = AnimationFeel.overshoot_lean_accented(
		fighter.state_frame, last_beat_accent) if active else 0.0
	# 2b. Arc enforcement and the one-frame limb smear, both keyed to the whip frame.
	body_modifier.arc_bias = AnimationFeel.arc_bias(fighter.state_frame, last_attack_weight) \
		if active else 0.0
	body_modifier.smear = AnimationFeel.smear_amount(fighter.state_frame) if active else 0.0
	# 4. Alive hitstop: the attacker's secondary bones keep a charge while the game is frozen.
	body_modifier.tension = AnimationFeel.tension_amount(_clock, fighter._hitstop_frames > 0)
	# 6. Additive hit-react overlay, scaled by the real contact strength and aimed by where
	# that contact landed (head shot vs body shot).
	var whip := 0.0
	if state == BaseFighter.State.HITSTUN and recoil_strength > 0.0:
		whip = recoil_strength * AnimationFeel.recoil_curve(recoil_age)
	body_modifier.recoil_high = recoil_high
	body_modifier.recoil_strength = recoil_strength
	body_modifier.recoil_curve = AnimationFeel.recoil_curve(recoil_age) if whip > 0.0 else 0.0


## 5. Volume-preserving impact pop on `SquashPivot`, with the hand props compensated so a
## mic or a mic stand can never be stretched by the body's squash.
func _apply_squash_pop(delta: float, state: int) -> void:
	if squash_pivot == null:
		return
	var heavy: bool = fighter._attack_id in BaseFighter.HEAVY_ATTACK_IDS
	var startup := int(fighter._attack.get("startup", 1)) if not fighter._attack.is_empty() else 1
	var target := AnimationFeel.squash_target(state, fighter.state_frame, startup,
		fighter._attack_id != &"", heavy, fighter._hitstop_frames > 0)
	# Clamp the step: an explicit spring integrated with a long first frame (a cold start or a
	# stalled tab) would blow up, and a huge `SquashPivot` scale would throw the mesh bounds
	# into the millions. 1/30 s is the widest stable step for this stiffness.
	var step := AnimationFeel.spring_step(_squash_scale, _squash_velocity, target,
		clampf(delta, 0.0001, 1.0 / 30.0))
	# Volume lock: the spring interpolates linearly between two scale triples, so a mid-spring
	# frame is NOT volume-preserving on its own. Renormalising every frame keeps the pop's
	# scale product at exactly 1.0, which is what stops a squash from reading as the body
	# gaining or losing mass. `Vector3.ONE` is a fixed point, so the rest pose is unaffected.
	_squash_scale = AnimationFeel.volume_preserve(step[0])
	_squash_velocity = step[1]
	if _squash_scale.distance_to(Vector3.ONE) < 0.00005:
		_squash_scale = Vector3.ONE
	squash_pivot.scale = _squash_scale


## Inverse-scale every hand prop against everything the body currently does to its parent
## chain, so a mic keeps its own proportions while the body squashes and while the arm is
## smeared. Two known, exact terms are divided out:
##   * the `SquashPivot` pop, which scales the whole model under the fighter;
##   * the one-frame limb smear, which the modifier writes on the striking upper arm and
##     forearm — the hand is downstream of the forearm, so it would inherit the stretch.
## `BoneAttachment3D` carries both, and both are values this node already owns, so the
## cancellation is per-axis arithmetic with no scene-graph reads and no feedback loop.
## A mic is a rigid object: the body may pop, stretch and smear, the prop must not change size
## or shear. A local inverse scale is NOT enough for that, because the pop is applied ABOVE the
## rotating hand, so even a perfect local inverse would still shear the prop (measured up to
## 15 % on its long axis). Instead the prop's WORLD basis is rebuilt from the hand's own
## ROTATION — the parent's basis orthonormalised, so no scale and no shear survives — times the
## prop's rest orientation relative to that hand. The prop therefore follows the hand through
## every take at exactly the size and shape it was authored, in every pop and smear.
func _isolate_props() -> void:
	if hand_props.is_empty():
		return
	for i in hand_props.size():
		var prop := hand_props[i]
		if prop == null or not is_instance_valid(prop):
			continue
		var parent := prop.get_parent() as Node3D
		if parent == null:
			continue
		var rel: Basis = _prop_rest_rel[i] if i < _prop_rest_rel.size() else Basis.IDENTITY
		var hand_rot := parent.global_transform.basis.orthonormalized()
		prop.global_transform = Transform3D(hand_rot * rel, prop.global_transform.origin)


## World-space scale of one hand attachment. Used by the audit to prove the isolation is
## exact: this value must not move while the body squashes and the arm smears.
func prop_world_scale(i: int) -> Vector3:
	if i < 0 or i >= hand_props.size():
		return Vector3.ONE
	var prop := hand_props[i]
	if prop == null or not is_instance_valid(prop):
		return Vector3.ONE
	return prop.global_transform.basis.get_scale()


## 4. Classic arcade defender X-shake while the contact is frozen. Presentation only: the
## `CharacterBody2D` position, the hurtbox and every hitbox stay exactly where combat put
## them, so this can never move a fighter out of a strike.
func _apply_hitstop_shake(state: int) -> void:
	if _pivot == null:
		return
	if fighter._hitstop_frames <= 0 or state != BaseFighter.State.HITSTUN:
		_shake_ticks = 0
		return
	_shake_ticks += 1
	_pivot.position.x += sin(float(_shake_ticks) * 2.1) * AnimationFeel.HITSTOP_SHAKE


## 6. Ground pinning: the lowest planted foot/toe bone is placed so the drawn sole sits on
## the sand, within 1 cm. This is also what removes the vertical float/moonwalk: a take that
## lifts the body 8 cm off the sand is corrected on the frame it happens.
func _pin_feet_to_ground() -> void:
	if _pivot == null or skeleton == null or _foot_bones.is_empty():
		return
	# Bug 2: no foot may be planted in a knockdown, a K.O. or a jump. The pin is fully off in
	# those states, and `_clamp_to_floor()` seats a downed body by its core instead.
	if _is_downed() or (fighter != null and fighter.state == BaseFighter.State.JUMP):
		return
	if not _is_pinned_state():
		return
	if _is_airborne():
		return
	# Get-up lands in IDLE while the topple is still easing out. Pinning the lowest foot bone
	# then pulls the still-tilted body down through the sand; wait until it is upright again
	# (`_clamp_to_floor()` owns the pose until then).
	if _fall > FALL_UPRIGHT:
		return
	var lowest := _lowest_foot_y()
	if lowest == INF:
		return
	var want := sole_drop + FEEL_PIN_BIAS - lowest
	# Half the acceptance band is the deadband, so a pose that drifts keeps a real margin
	# inside the 1 cm requirement instead of sitting on the limit.
	if absf(want) <= AnimationFeel.GROUND_PIN_TOLERANCE * 0.5:
		return
	_pivot.position.y += clampf(want, -FEEL_PIN_LIMIT, FEEL_PIN_LIMIT)


func _lowest_foot_y() -> float:
	var skel_xf := skeleton.global_transform
	var low := INF
	for i in _foot_bones:
		low = minf(low, (skel_xf * skeleton.get_bone_global_pose(i)).origin.y)
	return low


## Read-only summary for the headless audit and the AGENTS inventory.
func feel_snapshot() -> Dictionary:
	return {
		"stepped": stepped_arcade,
		"step_fps": step_fps,
		"impact_times": impact_times.duplicate(),
		"sole_drop": sole_drop,
		"squash": squash_pivot.scale if squash_pivot != null else Vector3.ONE,
		"feet": _foot_bones.size(),
		"modifier": body_modifier != null and body_modifier.is_cached(),
		"recoil": recoil_strength,
		"attack_weight": last_attack_weight,
		"coil_end": last_coil_end,
	}
