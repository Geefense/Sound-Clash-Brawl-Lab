class_name FightBodyModifier3D
extends SkeletonModifier3D
## Whole-body engagement + Wolverine negative space + additive hit-react overlay
## (Stefan Iverson systems 3, 4 and 6).
##
## This is the `SkeletonModifier3D` the overhaul calls for: a modifier whose whole job is to
## sit on top of the playing Mixamo take and add the parts of the performance a baked clip
## cannot know about — the shoulder counter-twist of the striking side, the off-arm carried
## clear of the ribcage, a few degrees of head/eye-line awareness, the +4° overshoot at
## contact and the instant spine/neck whip of a hit reaction.
##
## It is registered on the fighter's own `Skeleton3D` but with `active = false`, and it is
## driven explicitly by `FighterModel3D` at process priority 100. That ordering is the
## point: the additive layer must land *after* the AnimationPlayer has written this frame's
## pose, every frame, at a known moment. Letting `Skeleton3D` invoke it would apply it at a
## point in the frame that depends on node order, which is how an additive layer ends up
## silently overwritten on one machine and doubled on another.
##
## Nothing here is read by the combat simulation. Hips and the facing pivot are never
## touched, so the ±X facing audit and the hips-yaw lock stay exactly as they were.

## Whether this modifier contributes at all. Set false for a body with no rig.
var enabled := true
## 0–1 blend of the whole-body engagement (it eases in/out with the state, never snaps).
var engage_weight := 1.0
## Shoulder / upper-spine counter-twist on a strike, radians.
var engage_twist := 0.0
## Off-arm/elbow clearance from the ribcage, radians.
var negative_space := 0.0
## Head / eye-line awareness toward camera, radians.
var eye_line_yaw := 0.0
## `ACTIVE` overshoot impulse on the upper spine, radians.
var overshoot := 0.0
## 0–1.35 additive recoil whip strength (see `AnimationFeel.recoil_strength`).
var recoil_strength := 0.0
## 0–1 decay curve of that whip.
var recoil_curve := 0.0
## Micro-tension while a contact is held frozen, radians.
var tension := 0.0
## Facing sign, so the counter-twist and the off-arm clearance follow the fighting side.
var facing := 1
## Bound bone indices, resolved once. No per-frame `find_bone()` calls.
var _spine1 := -1
var _spine2 := -1
var _neck := -1
var _head := -1
var _shoulder_l := -1
var _shoulder_r := -1
var _arm_l := -1
var _arm_r := -1
var _applied_frame := -1
var _cached := false
## `SkeletonModifier3D` exposes its skeleton through `get_skeleton()`, not a property.
## Cached once in `cache_bones()` so no per-frame scene-tree walk happens.
var _skel: Skeleton3D = null


## `Skeleton3D` never invokes this: `active` is false and the proxy drives `apply_now()` at a
## deterministic point in the frame. Kept explicit so the class is a real modifier.
func _process_modification() -> void:
	pass


## Resolve every bone this modifier writes, once, from the skeleton's own names.
func cache_bones(skel: Skeleton3D) -> void:
	if skel == null:
		skel = get_skeleton()
	_skel = skel
	if skel == null:
		return
	_spine1 = _find(skel, "Spine1")
	_spine2 = _find(skel, "Spine2")
	_neck = _find(skel, "Neck")
	_head = _find(skel, "Head")
	_shoulder_l = _find(skel, "LeftShoulder")
	_shoulder_r = _find(skel, "RightShoulder")
	_arm_l = _find(skel, "LeftArm")
	_arm_r = _find(skel, "RightArm")
	_cached = true


## True once the bone table is populated, so the headless audit can assert the cache rather
## than trusting that a name matched.
func is_cached() -> bool:
	return _cached and _spine1 >= 0 and _spine2 >= 0 and _neck >= 0 and _head >= 0


func bone_indices() -> Dictionary:
	return {
		"spine1": _spine1, "spine2": _spine2, "neck": _neck, "head": _head,
		"shoulder_l": _shoulder_l, "shoulder_r": _shoulder_r,
		"arm_l": _arm_l, "arm_r": _arm_r,
	}


## Suffix match: some exports keep an exporter tag on the bone (`mixamorig8_RightHand`),
## so an exact `find_bone("mixamorig_Spine1")` is not portable across the three uploads.
func _find(skel: Skeleton3D, suffix: String) -> int:
	if skel == null:
		return -1
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with(suffix):
			return i
	return -1


## Apply the whole layer to the skeleton's current pose. Called exactly once per frame by
## `FighterModel3D._process` (priority 100, i.e. after the AnimationPlayer wrote the clip
## pose). Idempotent inside one frame so a stray extra call can never double the rotation.
## `force` exists for the headless audit, which has to apply the layer several times inside
## one frame to measure each contact strength. Runtime always leaves it false.
func apply_now(force: bool = false) -> void:
	if not enabled or _skel == null or not _cached:
		return
	var frame := Engine.get_process_frames()
	if not force and _applied_frame == frame:
		return
	_applied_frame = frame
	var face := float(1 if facing >= 0 else -1)
	var engage := clampf(engage_weight, 0.0, 1.0)

	# --- 3. Move everything in the body -----------------------------------------------
	# Shoulder / upper-spine counter-twist: the striking side turns through the torso while
	# the lower spine stays quiet, so no limb or torso goes dead during a swing.
	var twist := engage_twist * engage
	if not is_zero_approx(twist):
		_add(_spine1, Vector3.UP, twist * face)
		_add(_spine2, Vector3.UP, twist * 0.55 * face)
		_add(_shoulder_r if face > 0.0 else _shoulder_l, Vector3.BACK, twist * 0.35)
		_add(_shoulder_l if face > 0.0 else _shoulder_r, Vector3.BACK, -twist * 0.22)
	# Negative space: the off-arm and elbow ride clear of the ribcage so the silhouette
	# keeps an open, readable gap at gameplay size (Wolverine's small-screen trick).
	var gap := negative_space * engage
	if not is_zero_approx(gap):
		_add(_arm_l, Vector3.BACK, -gap)
		_add(_arm_r, Vector3.BACK, gap)
		_add(_shoulder_l, Vector3.BACK, -gap * 0.45)
		_add(_shoulder_r, Vector3.BACK, gap * 0.45)
	# Head / eye-line awareness toward camera. A few degrees only — the hips and the
	# fighting axis never move, so this cannot leave the ±5° facing band.
	if not is_zero_approx(eye_line_yaw):
		_add(_neck, Vector3.UP, eye_line_yaw * 0.6)
		_add(_head, Vector3.UP, eye_line_yaw * 0.4)
	# Contact overshoot: the +4° impulse that makes the hit pose snap past its target.
	if not is_zero_approx(overshoot):
		_add(_spine2, Vector3.RIGHT, overshoot)
		_add(_shoulder_r if face > 0.0 else _shoulder_l, Vector3.RIGHT, overshoot * 0.6)

	# --- 4. Alive hitstop -----------------------------------------------------------------
	if not is_zero_approx(tension):
		_add(_spine2, Vector3.UP, tension)
		_add(_head, Vector3.UP, -tension * 1.6)

	# --- 6. Additive hit-react bone overlay -----------------------------------------------
	# Instant spine -> neck -> head whip on hitstun and blockstun, scaled by contact
	# strength. Mixamo bones point along local +Y, so local X is the back-bend axis; the
	# negative sign throws the torso away from the strike.
	if recoil_strength > 0.0 and recoil_curve > 0.0:
		var whip := recoil_strength * recoil_curve
		_add(_spine1, Vector3.RIGHT, -0.055 * whip)
		_add(_spine2, Vector3.RIGHT, -0.085 * whip)
		_add(_neck, Vector3.RIGHT, -0.105 * whip)
		_add(_head, Vector3.RIGHT, -0.135 * whip)
		# A heavy contact also turns the head off-axis, which is what sells a jaw shot.
		_add(_head, Vector3.UP, 0.045 * whip * face)


## Additive rotation on one cached bone. `index < 0` is a no-op, so a future upload that
## renames a bone loses the layer's nuance instead of erroring.
func _add(index: int, axis: Vector3, angle: float) -> void:
	if index < 0 or is_zero_approx(angle):
		return
	var base: Quaternion = _skel.get_bone_pose_rotation(index)
	_skel.set_bone_pose_rotation(index, base * Quaternion(axis, angle))


## Reset every additive input so a new round or a new take starts from a clean pose.
func reset() -> void:
	engage_weight = 1.0
	engage_twist = 0.0
	negative_space = 0.0
	eye_line_yaw = 0.0
	overshoot = 0.0
	recoil_strength = 0.0
	recoil_curve = 0.0
	tension = 0.0
