class_name MixamoClips
extends RefCounted
## Real Mixamo takes for the three roster fighters (owner request, 2026-11-24).
##
## The owner exported every fighter's clip from Mixamo, so each of the 38 uploaded
## animations already carries **our own fighter mesh** skinned to the same 65-bone
## `mixamorig` skeleton (`Armature/Skeleton3D:mixamorig_*`). The game body for each
## fighter is one of those exports, decimated back to the 28 000-triangle budget, and
## every other clip ships as an armature-plus-take file in `assets/models/mixamo/clips/`.
##
## Because all 38 takes share one skeleton, a clip only has to be re-pointed at the
## fighter's own skeleton path; no retarget maths and no bone-name guessing. The role
## table below is the only place a filename becomes a fight state, so a re-export that
## renames a take is a one-line change here.
##
## Nothing in this file touches combat: it reads `BaseFighter.state`, `_attack_id` and
## `_celebrate_ticks` and picks an animation. Damage, hitboxes and timing still resolve
## in `BaseFighter`.

const ROOT := "res://assets/models/mixamo/clips/"
## Owner-specified crossfade band: 0.08 s – 0.12 s between every state.
const CROSSFADE := 0.10
const LOOPING: Array[StringName] = [&"idle", &"walk", &"crouch_walk", &"block", &"taunt"]

## role -> clip stem. A take may serve two roles (Feedback's `warrior-idle` is both the
## taunt and the victory strut); the loader caches one Animation per file either way.
const ROLE_FILES := {
	&"feedback": {
		&"idle": "fighting-idle-3",
		&"walk": "drunk-walk",
		&"light": "jab-cross",
		&"strong": "right-hook",
		&"upper_box": "elbow-uppercut-combo",
		&"tump": "body-jab-cross",
		&"special": "bencao",
		&"taunt": "warrior-idle",
		&"victory": "warrior-idle",
		&"knockdown": "knocked-out-1",
		&"getup": "getting-up",
	},
	&"lickshot": {
		&"idle": "fight-idle",
		&"walk": "strut-walking",
		&"light": "lead-jab",
		&"strong": "hook-punch",
		&"upper_box": "surprise-uppercut",
		&"tump": "zombie-kicking",
		&"special": "medium-step-forward",
		&"block": "center-block",
		&"taunt": "bouncing-fight-idle",
		&"victory": "bouncing-fight-idle",
		&"knockdown": "falling-back-death",
		&"getup": "getting-up",
	},
	&"young_selecta": {
		&"idle": "idle",
		&"walk": "walking",
		&"crouch_walk": "crouched-walking",
		&"light": "jab-to-elbow-punch",
		&"strong": "punch-combo",
		&"upper_box": "back-flip-to-uppercut",
		&"tump": "kicking",
		&"kick": "standing-melee-kick",
		&"special": "flying-knee-punch-combo",
		&"block": "standing-block-react-large",
		&"stun": "stunned",
		&"stumble": "stumble-backwards",
		&"knockdown": "stumble-backwards",
		&"taunt": "2hand-idle",
		&"victory": "quad-punch",
		&"getup": "back-flip-to-uppercut-1",
	},
}

## Role used when a fighter has no take for the state it is in. Ordered: the first
## available entry wins, so a fighter with only an idle still animates.
const FALLBACKS := {
	&"hit": [&"stun", &"stumble", &"block", &"idle"],
	&"stun": [&"hit", &"stumble", &"idle"],
	&"knockdown": [&"stumble", &"getup", &"idle"],
	&"getup": [&"idle"],
	&"block": [&"idle"],
	&"crouch_walk": [&"walk", &"idle"],
	&"walk": [&"idle"],
}

static var _libraries: Dictionary = {}


static func roles_for(key: StringName) -> Dictionary:
	return ROLE_FILES.get(key, {})


## Every clip shipped for one fighter, sorted, for the headless inventory.
static func clip_files(key: StringName) -> Array[String]:
	var found: Array[String] = []
	var dir_path := ROOT + String(key) + "/"
	if not DirAccess.dir_exists_absolute(dir_path):
		return found
	for raw in DirAccess.get_files_at(dir_path):
		var file := String(raw)
		if file.ends_with(".remap"):
			file = file.trim_suffix(".remap")
		if file.ends_with(".import"):
			file = file.trim_suffix(".import")
		if file.to_lower().ends_with(".fbx") and not found.has(file):
			found.append(file)
	found.sort()
	return found


## Build (and cache) the role -> Animation library for one fighter. Each source scene is
## instantiated just long enough to borrow its take, then freed.
##
## `skeleton_path` is the fighter's own skeleton path relative to its model root. It is not
## constant across the uploads (Feedback's body nests its skeleton at `Skeleton3D`, the two
## Tripo-derived bodies at `Armature/Skeleton3D`), so the caller measures it and every clip
## track is re-pointed there.
static func library_for(key: StringName, skeleton_path: String = "Armature/Skeleton3D") -> Dictionary:
	var cache_key := "%s|%s" % [key, skeleton_path]
	if _libraries.has(cache_key):
		return _libraries[cache_key]
	var out: Dictionary = {}
	var roles := roles_for(key)
	var skeletons: Dictionary = {}
	for role in roles:
		var stem := String(roles[role])
		if not skeletons.has(stem):
			skeletons[stem] = _read_clip(key, stem, skeleton_path)
		var clip: Animation = skeletons[stem]
		if clip == null:
			continue
		var copy := clip.duplicate() as Animation
		copy.loop_mode = Animation.LOOP_LINEAR if LOOPING.has(role) else Animation.LOOP_NONE
		out[role] = copy
	_libraries[cache_key] = out
	return out


static func _read_clip(key: StringName, stem: String, skeleton_path: String) -> Animation:
	var path := ROOT + String(key) + "/" + stem + ".fbx"
	if not ResourceLoader.exists(path):
		push_warning("MixamoClips: missing clip %s" % path)
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var node := packed.instantiate()
	var player: AnimationPlayer = null
	for child in node.find_children("*", "AnimationPlayer", true, false):
		player = child as AnimationPlayer
		if player != null and not player.get_animation_list().is_empty():
			break
	var anim: Animation = null
	if player != null and not player.get_animation_list().is_empty():
		anim = player.get_animation(player.get_animation_list()[0])
		if anim != null:
			anim = anim.duplicate() as Animation
			for track in anim.get_track_count():
				var track_path := String(anim.track_get_path(track))
				var bone := track_path.split(":")[1] if track_path.contains(":") else ""
				if bone != "":
					anim.track_set_path(track, NodePath(skeleton_path + ":" + bone))
			_strip_root_yaw(anim, node as Node3D)
			_strip_root_translation(anim)
	node.free()
	return anim


## Root motion disabled (playtest fix 2026-11-24, issue 1 step 6). Every delivered take
## bakes its own turn into the hips: the melee and KO takes measured **45°–108° of hips
## yaw**, which is what was swinging the fighters off the fighting axis mid-animation, and
## why L!kkle Moore read as "stuck" even with the pivot facing right. Strip the yaw, keep
## everything else — lean, bob, punch twist, fall and get-up all survive, only the heading
## goes. `VisualPivot` then owns the direction a fighter looks, alone.
## Tracks on the model node itself (no `bone` part) are flattened too, because an exported
## scene-level rotation track has the same effect.
static func _strip_root_yaw(anim: Animation, node: Node3D) -> void:
	var skeleton: Skeleton3D = null
	if node != null:
		for child in node.find_children("*", "Skeleton3D", true, false):
			skeleton = child as Skeleton3D
			break
	_strip_root_yaw_bones(anim, skeleton)


## The bone-level half of `_strip_root_yaw`, so a caller that already holds the skeleton
## (for example `strip_root_motion`) does not have to search for it again.
static func _strip_root_yaw_bones(anim: Animation, skeleton: Skeleton3D) -> void:
	for track in anim.get_track_count():
		if anim.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var path := String(anim.track_get_path(track))
		var bone := path.split(":")[1] if path.contains(":") else ""
		var is_root_node := bone == ""
		if not is_root_node and not (bone.ends_with("Hips") or bone.ends_with("Root")):
			continue
		# The yaw to KEEP is the bone's own rest yaw, not zero. Two of the three rigs carry a
		# non-identity Hips rest (L!ckshot's is −59.6°), and a track value is the pose's final
		# local rotation, so flattening to 0 would rotate the body by exactly that rest yaw.
		# Flattening to the rest yaw leaves the take's steel frame in its bind orientation.
		var rest_yaw := 0.0
		if not is_root_node and skeleton != null:
			var idx := skeleton.find_bone(bone)
			if idx >= 0:
				rest_yaw = skeleton.get_bone_rest(idx).basis.get_euler(EULER_ORDER_YXZ).y
		for k in anim.track_get_key_count(track):
			var q: Quaternion = anim.track_get_key_value(track, k)
			# YXZ keeps the yaw on its own axis, so pinning it to the rest yaw removes the
			# turn without touching the pitch/roll that carries the body's lean and fall.
			var e := Basis(q).get_euler(EULER_ORDER_YXZ)
			var flat := Basis.from_euler(Vector3(e.x, rest_yaw, e.z), EULER_ORDER_YXZ)
			anim.track_set_key_value(track, k, flat.get_rotation_quaternion())


## Root translation disabled (playtest fix 2026-11-24, issue 2). The delivered takes animate
## `mixamorig_Hips` **position** as well as rotation, and those keys are in the source rig's
## own units. Played on a 1.55 m body they threw the fighter about **76 m into the air** —
## completely outside the camera, which is what read as an "invisible opponent" — and on a
## knockdown they pushed the pelvis roughly 0.4 m through the sand and slid it sideways,
## which is the sinking / teleporting. Every take must therefore play strictly in place: the
## `CharacterBody2D` owns where the body is, the clip owns only the pose. The whole track is
## removed rather than flattened, so the bone simply keeps its rest translation and the clip
## still supplies lean, twist, topple and get-up.
##
## Only POSITION tracks on the root/Hips are touched. Rotation is handled by
## `_strip_root_yaw`, and every other bone's motion is untouched.
static func _strip_root_translation(anim: Animation) -> void:
	# Backwards: removing a track shifts every index after it.
	for track in range(anim.get_track_count() - 1, -1, -1):
		if anim.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		var path := String(anim.track_get_path(track))
		var bone := path.split(":")[1] if path.contains(":") else ""
		var is_root_node := bone == ""
		if not is_root_node and not (bone.ends_with("Hips") or bone.ends_with("Root")):
			continue
		anim.remove_track(track)


## Sanitise EVERY take on one fighter's player, including the body's own baked export that
## ships in the FBX's default library (playtest fix 2026-11-24, issue 2). `_read_clip`
## already does this for the shared library; this closes the same hole for any clip that
## reaches the player by another route, so no animation can translate the body. Both passes
## are idempotent, so a cached library costs nothing.
static func strip_root_motion(player: AnimationPlayer, skeleton: Skeleton3D) -> void:
	if player == null or skeleton == null:
		return
	for lib_name in player.get_animation_library_list():
		var lib := player.get_animation_library(lib_name)
		if lib == null:
			continue
		for anim_name in lib.get_animation_list():
			var anim := lib.get_animation(anim_name)
			if anim == null:
				continue
			_strip_root_yaw_bones(anim, skeleton)
			_strip_root_translation(anim)


## Install the library on one fighter's AnimationPlayer. Returns `{role: anim_name}` with
## the animation-library prefix already applied, or an empty dictionary when the fighter
## has no takes (the static-mesh path then keeps its procedural stance).
static func install_for(player: AnimationPlayer, key: StringName,
		skeleton_path: String = "Armature/Skeleton3D") -> Dictionary:
	var out: Dictionary = {}
	if player == null:
		return out
	var clips := library_for(key, skeleton_path)
	if clips.is_empty():
		return out
	var lib: AnimationLibrary = null
	if player.has_animation_library(&"mixamo"):
		lib = player.get_animation_library(&"mixamo")
	if lib == null:
		lib = AnimationLibrary.new()
		player.add_animation_library(&"mixamo", lib)
	for role in clips:
		var name := String(role)
		if not lib.has_animation(name):
			lib.add_animation(name, clips[role])
		out[role] = "mixamo/" + name
	return out


## Role for the fighter's current state. Attack roles come from the move id the combat
## layer already publishes (`jab`, `strong`, `tump`, `upper_box`).
static func role_for(fighter) -> StringName:
	if fighter == null:
		return &"idle"
	var state: int = fighter.state
	if state == BaseFighter.State.IDLE or state == BaseFighter.State.JUMP:
		if fighter._celebrate_ticks > 0:
			return &"victory"
		if fighter.guarding:
			return &"block"
		return &"idle"
	match state:
		BaseFighter.State.WALK:
			return &"walk"
		BaseFighter.State.CROUCH:
			return &"crouch_walk"
		BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, \
				BaseFighter.State.ATTACK_RECOVERY:
			return _attack_role(fighter._attack_id)
		BaseFighter.State.TAUNT:
			return &"taunt"
		BaseFighter.State.HITSTUN:
			return &"hit"
		BaseFighter.State.KNOCKDOWN, BaseFighter.State.KO:
			return &"knockdown"
		BaseFighter.State.GRAB, BaseFighter.State.GRABBED, BaseFighter.State.THROWN:
			return &"light"
	if fighter._celebrate_ticks > 0:
		return &"victory"
	return &"idle"


static func _attack_role(attack_id: StringName) -> StringName:
	match attack_id:
		&"jab":
			return &"light"
		&"strong":
			return &"strong"
		&"tump":
			return &"tump"
		&"upper_box":
			return &"upper_box"
	return &"light"


## Resolve a role against what this fighter actually shipped, walking the fallback chain.
static func resolve(installed: Dictionary, role: StringName) -> StringName:
	if installed.is_empty():
		return &""
	if installed.has(role):
		return role
	for candidate in FALLBACKS.get(role, [&"idle"]):
		if installed.has(candidate):
			return candidate
	return &"idle" if installed.has(&"idle") else &""
