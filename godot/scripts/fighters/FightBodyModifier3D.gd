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
## Chest cheat toward camera, radians (absolute, never facing-signed).
var chest_yaw := 0.0
## Lateral arc bias of the swing, radians (signed toward the fighting side).
var arc_bias := 0.0
## Visual reach extension of the striking fist, metres, driven by `AnimationFeel.reach_boost()`
## from the move's own measured contact reach on ACTIVE frames. Consumed ONLY as a
## length-preserving rotation of the shoulder and upper arm (`AnimationFeel.reach_angle`): the
## hand bone is never translated and no bone is ever scaled, so the glove keeps its authored
## shape. No hitbox, hurtbox or root moves.
var reach_boost := 0.0
## `ACTIVE` overshoot impulse on the upper spine, radians.
var overshoot := 0.0
## 0–1.35 additive recoil whip strength (see `AnimationFeel.recoil_strength`).
var recoil_strength := 0.0
## 0–1 decay curve of that whip.
var recoil_curve := 0.0
## Where the contact landed, 0 = body shot … 1 = head shot. Selects which bone table the
## whip uses, so a jab to the jaw and a tump to the ribs do not produce the same bend.
var recoil_high := 0.5
## Micro-tension while a contact is held frozen, radians.
var tension := 0.0
## Facing sign, so the counter-twist and the off-arm clearance follow the fighting side.
var facing := 1
## Pose steps into `ACTIVE` this frame is, or -1 when no attack owns the body. Drives the
## per-link whip lag: the hips lead, the upper spine and then the striking hand follow.
var whip_step := -1
## 0–1 share of the strike the upper torso carries this step (see `AnimationFeel.whip_weight`).
## The hips are never written here, so the facing authority stays untouched.
var spine_lag := 1.0
## Forward coil of the startup, metres along ±X. The model writes it on the `VisualPivot`;
## this copy is the one authoritative value the audit reads.
var anticipation := 0.0
## Non-linear recovery dip, radians (positive folds forward, negative is the overshoot back).
var recovery_dip := 0.0
## Per-bone mask of the bones no layer may write (hands, fingers, feet, toes), built once in
## `cache_bones()`. `_extremity_mask[id] != 0` means that bone is off limits — every write in
## this modifier goes through `_add()`, which refuses it.
var _extremity_mask := PackedByteArray()
## Shoulder-to-hand distance of the striking arm at rest, metres. The reach rotation is solved
## from it, so the extension is a real lever arc rather than a tuned angle.
var _arm_length := 0.0
## Bound bone indices, resolved once. No per-frame `find_bone()` calls.
var _spine1 := -1
var _spine2 := -1
var _neck := -1
var _head := -1
var _shoulder_l := -1
var _shoulder_r := -1
var _arm_l := -1
var _arm_r := -1
var _forearm_l := -1
var _forearm_r := -1
var _hand_l := -1
var _hand_r := -1
var _applied_frame := -1
## Yaw spent this frame, so the layer can never exceed `AnimationFeel.INFLUENCE_CAP`.
var _yaw_spent := 0.0
## Per-bone yaw already written this frame, one slot per cached bone (allocated once).
var _yaw_budget := PackedFloat32Array()
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
	_forearm_l = _find(skel, "LeftForeArm")
	_forearm_r = _find(skel, "RightForeArm")
	_hand_l = _find(skel, "LeftHand")
	_hand_r = _find(skel, "RightHand")
	# Extremity mask: hands, fingers, feet and toes are read-only for this layer. Built once
	# from the bone names, so no per-frame string work and no call site can forget it.
	_extremity_mask.resize(skel.get_bone_count())
	_extremity_mask.fill(0)
	for i in skel.get_bone_count():
		if AnimationFeel.is_extremity_bone(skel.get_bone_name(i)):
			_extremity_mask[i] = 1
	# Lever length: shoulder -> hand along the rest pose of the striking arm.
	var shoulder := _shoulder_r if _shoulder_r >= 0 else _shoulder_l
	var hand := _hand_r if _hand_r >= 0 else _hand_l
	_arm_length = 0.0
	if shoulder >= 0 and hand >= 0:
		# Bone rest positions are in skeleton space, which the exporter scales (0.01 for the
		# centimetre Mixamo uploads). The reach is authored in metres, so the lever is scaled
		# into the same units before the arc is solved — otherwise a 7 cm reach on a
		# centimetre rig is a tenth of a degree.
		var chain := skel.global_transform.basis.get_scale().y
		_arm_length = skel.get_bone_global_rest(shoulder).origin.distance_to(
			skel.get_bone_global_rest(hand).origin) * chain
	_yaw_budget.resize(8)
	_yaw_budget.fill(0.0)
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
	_yaw_spent = 0.0
	_yaw_budget.fill(0.0)

	# Camera-facing chest cheat: the chest opens a few degrees out of profile at the strike
	# pose so the contact silhouette still reads on a phone. Absolute yaw — the camera does
	# not move when the fighter turns around.
	if not is_zero_approx(chest_yaw):
		_add(_spine2, Vector3.UP, chest_yaw)

	# --- 3. Move everything in the body -----------------------------------------------
	# Shoulder / upper-spine counter-twist: the striking side turns through the torso while
	# the lower spine stays quiet, so no limb or torso goes dead during a swing. The
	# `spine_lag` share is the C → S → reverse-C whip: the hips have already gone, the torso
	# arrives 1–2 pose steps behind them, and the striking hand behind that.
	var twist := engage_twist * engage * clampf(spine_lag, 0.0, 1.0)
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
	# 5. Non-linear recovery settle: a hip-dip fold through the upper spine, then a smaller
	# overshoot back past neutral. Never a linear slide to the idle.
	if not is_zero_approx(recovery_dip):
		_add(_spine1, Vector3.RIGHT, recovery_dip)
		_add(_spine2, Vector3.RIGHT, recovery_dip * 0.6)
		_add(_shoulder_r if face > 0.0 else _shoulder_l, Vector3.RIGHT, recovery_dip * 0.25)

	# --- 3b. Arc enforcement: the swing travels a curve, not a straight line ---------
	# The striking shoulder leads outward, the upper arm follows and the forearm lags, so the
	# limb traces an arc through the swing. On the whip frames the arc pushes a hair PAST the
	# target (the lateral half of the overshoot), which is what makes the contact snap.
	if not is_zero_approx(arc_bias):
		var lead_shoulder := _shoulder_r if face > 0.0 else _shoulder_l
		var lead_arm := _arm_r if face > 0.0 else _arm_l
		var lead_forearm := _forearm_r if face > 0.0 else _forearm_l
		_add(lead_shoulder, Vector3.UP, arc_bias * face)
		_add(lead_arm, Vector3.UP, arc_bias * 0.55 * face)
		_add(lead_forearm, Vector3.BACK, arc_bias * 0.7)
	# Strike silhouette (2026-11-26): the striking arm reaches a little further along the
	# fighting axis, solved as a rotation of the shoulder and upper arm from the move's own
	# measured reach. Nothing here translates or scales a bone — the earlier hand-bone
	# translation stretched the glove's skin weights and is gone for good.
	if not is_zero_approx(reach_boost):
		var angle := AnimationFeel.reach_angle(reach_boost, _arm_length)
		if angle > 0.0:
			_add(_shoulder_r if face > 0.0 else _shoulder_l, Vector3.UP, angle * 0.45 * face)
			_add(_arm_r if face > 0.0 else _arm_l, Vector3.UP, angle * 0.55 * face)

	# --- 4. Alive hitstop -----------------------------------------------------------------
	if not is_zero_approx(tension):
		_add(_spine2, Vector3.UP, tension)
		_add(_head, Vector3.UP, -tension * 1.6)

	# --- 6. Additive hit-react bone overlay -----------------------------------------------
	# Instant spine -> neck -> head whip on hitstun and blockstun, scaled by contact strength
	# AND aimed by contact height: a high shot throws the neck/head hardest, a low shot folds
	# the spine and lets the head trail. Mixamo bones point along local +Y, so local X is the
	# back-bend axis; the negative sign throws the torso away from the strike. The hips are
	# never written here, so the facing authority stays untouched.
	if recoil_strength > 0.0 and recoil_curve > 0.0:
		var whip := recoil_strength * recoil_curve
		var pitch := AnimationFeel.recoil_pitch(recoil_high)
		_add(_spine1, Vector3.RIGHT, -pitch.x * whip)
		_add(_spine2, Vector3.RIGHT, -pitch.y * whip)
		_add(_neck, Vector3.RIGHT, -pitch.z * whip)
		_add(_head, Vector3.RIGHT, -pitch.w * whip)
		# A head contact also turns the head off-axis, which is what sells a jaw shot.
		_add(_head, Vector3.UP, AnimationFeel.recoil_head_yaw(recoil_high) * whip * face)


## True when this bone index belongs to a hand, finger, foot or toe and must not be written.
func is_extremity(index: int) -> bool:
	return index >= 0 and index < _extremity_mask.size() and _extremity_mask[index] != 0


## Measured shoulder-to-hand distance of the striking arm, metres.
func arm_length() -> float:
	return _arm_length


## Number of bones this layer may never write, for the audit.
func extremity_count() -> int:
	var total := 0
	for flag in _extremity_mask:
		if flag != 0:
			total += 1
	return total


## Additive rotation on one cached bone. `index < 0` is a no-op, so a future upload that
## renames a bone loses the layer's nuance instead of erroring.
func _add(index: int, axis: Vector3, angle: float) -> void:
	if index < 0 or is_zero_approx(angle):
		return
	# Extremity exclusion (2026-11-26): hands, fingers, feet and toes are never written by any
	# presentation layer. This guard is the single choke point, so a future system cannot
	# reintroduce the hand translation or the 1.08× foreshortening that mutilated the glove.
	if is_extremity(index):
		return
	# Influence cap: yaw is what could ever read as a turn, so it is what is budgeted — per bone
	# cumulatively, then per frame. Two systems writing the same spine may not add up past
	# `MAX_BONE_YAW` between them, and the frame may not spend more than `INFLUENCE_CAP`; past
	# either the garnish is clipped or dropped rather than applied. The hips are not in the
	# table at all, so they can never be a target.
	if axis.is_equal_approx(Vector3.UP):
		var slot := _yaw_slot(index)
		if slot < 0:
			return
		var room := AnimationFeel.MAX_BONE_YAW - _yaw_budget[slot]
		if room <= 0.00001:
			return
		angle = clampf(angle, -room, room)
		var spend := absf(angle)
		if _yaw_spent + spend > AnimationFeel.INFLUENCE_CAP:
			return
		_yaw_spent += spend
		_yaw_budget[slot] += spend
	var base: Quaternion = _skel.get_bone_pose_rotation(index)
	_skel.set_bone_pose_rotation(index, base * Quaternion(axis, angle))


## Yaw spent by the last applied frame, for the audit and the HUD debug readout.
func yaw_spent() -> float:
	return _yaw_spent


## Yaw written to one cached bone this frame.
func yaw_spent_on(name: String) -> float:
	var slot := _yaw_slot(int(bone_indices().get(name, -1)))
	return _yaw_budget[slot] if slot >= 0 else 0.0


## Slot of a bone in `_yaw_budget`, or -1 when the bone is not one the layer may turn.
func _yaw_slot(index: int) -> int:
	if index < 0:
		return -1
	if index == _spine1:
		return 0
	if index == _spine2:
		return 1
	if index == _neck:
		return 2
	if index == _head:
		return 3
	if index == _shoulder_l:
		return 4
	if index == _shoulder_r:
		return 5
	if index == _arm_l:
		return 6
	if index == _arm_r:
		return 7
	return -1


## Reset every additive input so a new round or a new take starts from a clean pose.
func reset() -> void:
	engage_weight = 1.0
	engage_twist = 0.0
	negative_space = 0.0
	eye_line_yaw = 0.0
	arc_bias = 0.0
	chest_yaw = 0.0
	reach_boost = 0.0
	recovery_dip = 0.0
	anticipation = 0.0
	whip_step = -1
	spine_lag = 1.0
	overshoot = 0.0
	recoil_strength = 0.0
	recoil_curve = 0.0
	recoil_high = 0.5
	tension = 0.0
