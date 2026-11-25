extends SceneTree
## Stefan Iverson combat-feel audit (2026-11-24).
## Run with: godot --headless --path godot --script res://tools/animation_feel_audit.gd
##
## Verifies the six presentation systems on the REAL `FighterModel3D` bound to the real
## `BaseFighter`, for all three roster fighters and both facings:
##
##   1. Stepped arcade pose quantization — the sampled clip time is held on an 18 fps grid
##      (discrete holds of ~3 frames at 60 fps), and F4's OFF state is smooth again.
##   2. The non-linear attack curve — a measured `t_impact` per attack clip inside the
##      0.36–0.62 band, a coil ending at 0.35, a 1–2 frame whip onto `t_impact`, a settle
##      that holds the extended pose, and a recovery that eases back to the stance.
##      Plus the +4° overshoot impulse present on ACTIVE frames 1–2 and gone by frame 4.
##   3. Whole-body engagement / negative space — Spine1/Spine2/Neck/Head/Shoulder bone
##      deltas are nonzero while the Hips are untouched, so the ±X facing is preserved.
##   4. Alive hitstop micro-tension — the attacker's secondary bones move while frozen.
##   5. `SquashPivot` — a real node under `VisualPivot`, the two authored presets, a spring
##      that returns to exactly `Vector3.ONE`, and hand props counter-scaled.
##   6. Additive hit-react overlay — light < heavy < counter recoil, scaled bone deltas, and
##      per-frame ground pinning with the drawn sole within 1 cm of world y 0.
##
## PART 1 commits 2–4 are covered too: the `step_fps` export re-grids a body onto 16 fps, the
## coil depth scales with the move's weight, the swing arc rotates the striking shoulder/arm,
## the one-frame limb smear is a volume-preserving bone stretch restored the next frame, the
## chest turns toward camera at the strike pose, and the influence cap clips a runaway request
## while the full strike stack still fits. The body layer is asserted to be a child of the
## skeleton that the skeleton never invokes itself — the ordering "after the curve, before the
## foot pin" is therefore structural.
##
## It also re-hashes `scripts/BaseFighter.gd` and `scripts/FighterRoster.gd`, so a frame-data
## or Patois edit is caught here instead of surviving until the next playtest.
##
## Exit code is non-zero when any check fails.

const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
## The two files whose combat data must not move. Hashes are of the committed files.
const COMBAT_FILES := {
	"res://scripts/BaseFighter.gd":
		"d69c8d859855c6ab9d6565135e2c884d7ba2faeb78d765f2e7a2cb39df70f675",
	"res://scripts/fighters/FighterRoster.gd":
		"25b9d82111e6ebacb4cfa02561ce85fc0b2953f5f16e76e43e954dc0c2ac6adb",
}
const PIN_TOLERANCE := 0.01
const FACING_TOLERANCE_DEG := 5.0

var _checks := 0
var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("\n=== ANIMATION FEEL AUDIT (Stefan Iverson overhaul) ===")
	_audit_combat_files()
	await _audit_static_curves()
	for key in FIGHTERS:
		await _audit_fighter(key)
	print("\n%d checks, %d FAIL%s" % [_checks, _fails, "" if _fails == 0 else "S"])
	print("ALL ANIMATION FEEL CHECKS PASSED" if _fails == 0 else "ANIMATION FEEL CHECKS FAILED")
	quit(1 if _fails > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("FAIL  %s%s" % [label, (" — " + detail) if detail != "" else ""])
	else:
		print("PASS  %s%s" % [label, (" — " + detail) if detail != "" else ""])


## Combat data guard: `BaseFighter.gd` carries the FSM, the frame tables, the beat windows,
## `ANIM_OFFSET` and the 31 Patois entries; `FighterRoster.gd` carries the per-fighter moves
## and the roster name styling. Neither may change for a presentation overhaul.
func _audit_combat_files() -> void:
	print("\n-- COMBAT DATA UNTOUCHED")
	for path in COMBAT_FILES:
		var sha := _sha256(path)
		_check(sha == String(COMBAT_FILES[path]), "%s is byte-identical" % path,
			"sha256 %s" % sha)


func _sha256(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "<missing>"
	var bytes := FileAccess.get_file_as_bytes(path)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


## The pure curves, before any model is bound, so a broken constant fails loudly instead of
## only showing up as "the animation looks a bit odd".
func _audit_static_curves() -> void:
	print("\n-- CURVES (pure)")

	# 1. Quantization grid.
	_check(AnimationFeel.STEPPED_FPS >= 16.0 and AnimationFeel.STEPPED_FPS <= 20.0,
		"stepped rate sits in the owner's 16–20 fps band",
		"%.1f fps" % AnimationFeel.STEPPED_FPS)
	var steps := AnimationFeel.step_count(1.2)
	var on_grid := true
	var distinct := {}
	for i in range(0, 60):
		var t := float(i) / 60.0
		var q := AnimationFeel.quantize(t, steps)
		if absf(q * float(steps) - round(q * float(steps))) > 0.0001:
			on_grid = false
		distinct[snappedf(q, 0.00001)] = true
	_check(on_grid, "quantize() only ever returns grid positions")
	_check(distinct.size() <= steps + 2,
		"a 1 s span holds at most %d distinct poses (18 fps + both endpoints)" % (steps + 2),
		"%d distinct" % distinct.size())

	# 2. Attack curve: coil -> whip -> settle -> recovery.
	var t_impact := 0.48
	var coil := AnimationFeel.startup_progress(1.0)
	_check(absf(coil - AnimationFeel.COIL_END) < 0.0001,
		"STARTUP ends the coil at %.2f of the clip" % AnimationFeel.COIL_END, "%.3f" % coil)
	_check(AnimationFeel.startup_progress(0.5) < coil * 0.5,
		"STARTUP compresses into the coil instead of running linear")
	var a0 := AnimationFeel.active_progress(0, t_impact)
	var a1 := AnimationFeel.active_progress(1, t_impact)
	var a2 := AnimationFeel.active_progress(2, t_impact)
	var a6 := AnimationFeel.active_progress(6, t_impact)
	_check(absf(a0 - AnimationFeel.COIL_END) < 0.0001,
		"ACTIVE frame 0 is still the coiled pose", "%.3f" % a0)
	_check(a1 > AnimationFeel.COIL_END and a1 >= AnimationFeel.COIL_END
		+ (t_impact - AnimationFeel.COIL_END) * 0.7,
		"ACTIVE frame 1 has already whipped ≥70% of the way to impact", "%.3f" % a1)
	_check(absf(a2 - t_impact) < 0.0001,
		"ACTIVE frame 2 is on the measured impact pose", "%.3f" % a2)
	_check(a6 >= t_impact and a6 - t_impact <= AnimationFeel.SETTLE_DRIFT + 0.0001,
		"ACTIVE holds the extended silhouette across the settle", "%.3f" % a6)
	var r0 := AnimationFeel.recovery_progress(0.0, t_impact)
	var r1 := AnimationFeel.recovery_progress(1.0, t_impact)
	_check(absf(r0 - t_impact) < 0.0001 and absf(r1 - 1.0) < 0.0001,
		"RECOVERY eases t_impact -> 1.0 back to stance", "%.3f -> %.3f" % [r0, r1])
	_check(AnimationFeel.overshoot_lean(0) > 0.0
		and absf(AnimationFeel.overshoot_lean(1) - deg_to_rad(4.0)) < 0.0001
		and AnimationFeel.overshoot_lean(4) == 0.0,
		"+4° overshoot on ACTIVE frames 1–2, settled to 0 by frame 4",
		"f1 %.2f deg" % rad_to_deg(AnimationFeel.overshoot_lean(1)))

	# 3. Move-weight coil, arc enforcement and the one-frame smear.
	var coil_light := AnimationFeel.coil_end(AnimationFeel.move_weight(8))
	var coil_heavy := AnimationFeel.coil_end(AnimationFeel.move_weight(15))
	_check(coil_heavy < coil_light and coil_light <= AnimationFeel.COIL_END_LIGHT
		and coil_heavy >= AnimationFeel.COIL_END_HEAVY,
		"a heavier move winds deeper than a jab",
		"light %.3f vs heavy %.3f" % [coil_light, coil_heavy])
	_check(absf(AnimationFeel.startup_progress(1.0, coil_heavy) - coil_heavy) < 0.0001,
		"STARTUP lands on its own weight-scaled coil", "%.3f" % coil_heavy)
	_check(AnimationFeel.arc_bias(0, 1.0) == 0.0
		and AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0) > 0.0
		and AnimationFeel.arc_bias(4, 1.0) == 0.0,
		"the swing arc peaks on the whip frame and unwinds by the hold",
		"%.3f rad" % AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0))
	var arc_heavy := AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0)
	var arc_light := AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 0.35)
	_check(arc_heavy > arc_light, "the arc carries the lateral overshoot and scales with weight",
		"%.3f vs %.3f rad" % [arc_heavy, arc_light])
	var smear_scale := AnimationFeel.smear_scale(1.0)
	_check(AnimationFeel.smear_amount(0) == 0.0
		and AnimationFeel.smear_amount(AnimationFeel.WHIP_FRAME) == 1.0
		and AnimationFeel.smear_amount(AnimationFeel.WHIP_FRAME + 1) == 0.0,
		"the limb smear exists on exactly one frame")
	_check(absf(smear_scale.x * smear_scale.y * smear_scale.z - 1.0) < 0.001
		and smear_scale.y > 1.0,
		"the smear stretch preserves the limb's volume",
		"(%.3f, %.3f, %.3f)" % [smear_scale.x, smear_scale.y, smear_scale.z])

	# 6. Recoil strength ladder.
	var light := AnimationFeel.recoil_strength(8, false, false)
	var heavy := AnimationFeel.recoil_strength(15, false, false)
	var counter := AnimationFeel.recoil_strength(8, false, true)
	var blocked := AnimationFeel.recoil_strength(4, true, false)
	_check(blocked < light and light < heavy and heavy < counter,
		"recoil ladder blocked < light < heavy < counter",
		"%.2f / %.2f / %.2f / %.2f" % [blocked, light, heavy, counter])
	_check(AnimationFeel.recoil_curve(0.0) == 1.0
		and AnimationFeel.recoil_curve(AnimationFeel.RECOIL_SECONDS) == 0.0,
		"recoil whip is instant then decays to zero over %.2fs" % AnimationFeel.RECOIL_SECONDS)

	# 5. Squash presets and the spring. The contract is the VOLUME, not a hand-copied triple:
	# every preset must preserve it to within `SQUASH_VOLUME_TOLERANCE`, which is a stronger
	# requirement than any particular set of numbers.
	for preset in [["anticipation / landing squash", AnimationFeel.SQUASH_POP],
			["heavy / special stretch", AnimationFeel.SQUASH_STRETCH],
			["crouch / knockdown compression", AnimationFeel.SQUASH_LANDING]]:
		var s: Vector3 = preset[1]
		var vol := AnimationFeel.squash_volume(s)
		_check(absf(vol - 1.0) <= AnimationFeel.SQUASH_VOLUME_TOLERANCE,
			"%s preserves volume" % preset[0],
			"(%.3f, %.3f, %.3f) -> product %.4f" % [s.x, s.y, s.z, vol])
	_check(AnimationFeel.SQUASH_POP.x > 1.0 and AnimationFeel.SQUASH_POP.y < 1.0,
		"the squash preset is wider and shorter", "(%.3f, %.3f, %.3f)" % [
			AnimationFeel.SQUASH_POP.x, AnimationFeel.SQUASH_POP.y, AnimationFeel.SQUASH_POP.z])
	_check(AnimationFeel.SQUASH_STRETCH.x > 1.0 and AnimationFeel.SQUASH_STRETCH.z < 1.0,
		"the stretch preset is taller/wider and thinner", "(%.3f, %.3f, %.3f)" % [
			AnimationFeel.SQUASH_STRETCH.x, AnimationFeel.SQUASH_STRETCH.y,
			AnimationFeel.SQUASH_STRETCH.z])
	# A tripled non-unit scale must come straight back out of the renorm helper, and the
	# half-way frame of an interpolation must be renormalised too (that is the real bug the
	# helper exists for — the linear lerp of two unit-product triples is NOT unit-product).
	var mid := AnimationFeel.volume_preserve(Vector3.ONE.lerp(AnimationFeel.SQUASH_POP, 0.5))
	_check(absf(AnimationFeel.squash_volume(mid) - 1.0) < 0.0001,
		"volume_preserve() fixes a mid-spring interpolation",
		"product %.6f" % AnimationFeel.squash_volume(mid))
	var raw_mid := Vector3.ONE.lerp(AnimationFeel.SQUASH_POP, 0.5)
	_check(absf(AnimationFeel.squash_volume(raw_mid) - 1.0) > 0.0005,
		"the raw interpolation really does drift, so the lock is load-bearing",
		"raw product %.6f" % AnimationFeel.squash_volume(raw_mid))
	var cur := AnimationFeel.SQUASH_STRETCH
	var vel := Vector3.ZERO
	var settled := false
	for i in 240:
		var step: Array = AnimationFeel.spring_step(cur, vel, Vector3.ONE, 1.0 / 60.0)
		cur = step[0]
		vel = step[1]
		if cur == Vector3.ONE and vel == Vector3.ZERO:
			settled = true
			break
	_check(settled, "the squash spring decays cleanly back to Vector3.ONE",
		"after %d frames" % 240)


func _audit_fighter(key: StringName) -> void:
	print("\n-- %s" % key)
	var fighter := await _make_fighter(key)
	var model := FighterModel3D.new()
	root.add_child(model)
	if not model.bind(fighter, key):
		_check(false, "%s: could not bind a 3D model" % key)
		fighter.queue_free()
		return
	await process_frame
	model.set_stepped_arcade(true)
	# Freeze the fighter's own tick for the whole audit: every measurement below sets an exact
	# combat phase by hand, and a live physics tick would advance the attack behind it.
	fighter.set_physics_process(false)

	var snap := model.feel_snapshot()
	_check(bool(snap["feet"]) and int(snap["feet"]) >= 2,
		"%s found its foot/toe bones" % key, "%d bones" % int(snap["feet"]))
	_check(bool(snap["modifier"]), "%s has a cached SkeletonModifier3D" % key)
	_check(is_equal_approx(model.step_fps, AnimationFeel.STEPPED_FPS)
		and model.step_fps >= 16.0 and model.step_fps <= 20.0,
		"%s exports step_fps at the default inside the 16–20 band" % key,
		"%.1f fps" % model.step_fps)
	_check(model.squash_pivot != null and model.squash_pivot.get_parent() == model._visual_pivot,
		"%s SquashPivot sits directly under VisualPivot" % key)
	_check(model.sole_drop >= 0.0 and model.sole_drop <= 0.35,
		"%s sole offset is physically plausible" % key,
		"%.4f m (bind-mapped=%s)" % [model.sole_drop, str(model.sole_bind_mapped)])

	# --- 2. t_impact measured per attack clip -------------------------------------------
	var times: Dictionary = snap["impact_times"]
	_check(not times.is_empty(), "%s measured t_impact for its attack clips" % key,
		"%d clips" % times.size())
	for clip_name in times:
		var t := float(times[clip_name])
		_check(t >= AnimationFeel.IMPACT_MIN - 0.0001 and t <= AnimationFeel.IMPACT_MAX + 0.0001,
			"%s %s t_impact inside the %.2f–%.2f band" % [key, clip_name,
				AnimationFeel.IMPACT_MIN, AnimationFeel.IMPACT_MAX], "%.3f" % t)

	# --- 1. Stepped quantization on the live clip --------------------------------------
	await _audit_stepping(model, fighter, key)

	# --- 3/4/6. Skeleton layer --------------------------------------------------------
	await _audit_body_layer(model, fighter, key)

	# --- 4. Camera-facing chest cheat + the influence cap ------------------------------
	await _audit_influence(model, fighter, key)

	# --- 2/3. Weight-scaled coil, arc and smear on the live body ----------------------
	await _audit_attack_curve(model, fighter, key)

	# --- 5. Squash pop ---------------------------------------------------------------
	await _audit_squash(model, fighter, key)

	# --- 6. Ground pinning -----------------------------------------------------------
	await _audit_pinning(model, fighter, key)

	# Facing must still be exact after every one of the above. Replay the neutral take
	# first, so this measures the shipped idle rather than whatever pose the audits left.
	fighter.state = BaseFighter.State.IDLE
	fighter._attack_id = &""
	model._play_role(&"idle")
	await process_frame
	for facing in [1, -1]:
		model.set_facing(facing)
		model._lock_root_yaw()
		model._compensate_clip_yaw()
		var fwd := model.world_forward()
		var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
		_check(err <= FACING_TOLERANCE_DEG,
			"%s still faces ±X with the feel layer running (facing %+d)" % [key, facing],
			"%.1f deg off" % err)

	model.queue_free()
	fighter.queue_free()
	await process_frame


func _make_fighter(key: StringName) -> BaseFighter:
	var scene := load("res://scenes/BaseFighter.tscn") as PackedScene
	var f := scene.instantiate() as BaseFighter
	f.use_local_input = false
	root.add_child(f)
	await process_frame
	f.set_3d_presentation(true)
	f.apply_fighter_profile(key)
	f.input_locked = true
	return f


## Force one attack and sample the clip position the driver actually seeks to, frame by
## frame. The stepped grid is asserted directly on those numbers.
func _audit_stepping(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	if model.clips.is_empty():
		return
	var clip_name := String(model.clips.get(&"light", ""))
	if clip_name == "":
		return
	fighter._attack_id = &"jab"
	fighter._attack = fighter.attacks[&"jab"]
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	model._play_role(&"light")
	await process_frame
	var anim := model.animation.get_animation(clip_name)
	if anim == null or anim.length <= 0.0:
		return
	var steps := AnimationFeel.step_count(anim.length)
	var samples: Array[float] = []
	var holds := 0
	var last := -1.0
	for frame in range(0, 14):
		fighter.state_frame = frame
		model._drive_clip_time()
		var t: float = model.animation.current_animation_position / anim.length
		samples.append(t)
		if last >= 0.0 and is_equal_approx(t, last):
			holds += 1
		last = t
	var on_grid := true
	for t in samples:
		if absf(t * float(steps) - round(t * float(steps))) > 0.0005:
			on_grid = false
	_check(on_grid, "%s stepped mode only seeks to the 18 fps grid" % key,
		"%d steps over %.2fs" % [steps, anim.length])
	_check(holds >= 6, "%s holds each pose for multiple frames" % key,
		"%d repeated frames of 14" % holds)
	var distinct := {}
	for t in samples:
		distinct[snappedf(t, 0.00001)] = true
	_check(distinct.size() < samples.size(), "%s pose advances discretely, not linearly" % key,
		"%d distinct of %d frames" % [distinct.size(), samples.size()])

	# F4 OFF: the same span must now be smooth (no grid snapping). The per-instance flag is
	# used here on purpose — `set_stepped_arcade()` is the shared F4 switch and would leave
	# the static default off for every later fighter in this run.
	model.stepped_arcade = false
	var off_grid := 0
	var smooth: Array[float] = []
	for frame in range(0, 14):
		fighter.state_frame = frame
		model._drive_clip_time()
		var t: float = model.animation.current_animation_position / anim.length
		smooth.append(t)
		if absf(t * float(steps) - round(t * float(steps))) > 0.0005:
			off_grid += 1
	_check(off_grid >= 6, "%s F4 OFF restores smooth playback" % key,
		"%d of 14 frames off the grid" % off_grid)
	model.stepped_arcade = AnimationFeel.stepped_arcade

	# The export must actually drive the grid: re-grid this one body to 16 fps and require the
	# seeks to land on the 16 fps lattice and NOT on the 18 fps one.
	model.step_fps = 16.0
	var steps16 := AnimationFeel.step_count(anim.length, 16.0)
	var on_16 := true
	var differed := 0
	for frame in range(0, 10):
		fighter.state_frame = frame
		model._drive_clip_time()
		var t: float = model.animation.current_animation_position / anim.length
		if absf(t * float(steps16) - round(t * float(steps16))) > 0.0005:
			on_16 = false
		if absf(t * float(steps) - round(t * float(steps))) > 0.0005:
			differed += 1
	_check(on_16, "%s step_fps=16 re-grids the clip onto the 16 fps lattice" % key,
		"%d steps" % steps16)
	_check(differed > 0, "%s the 16 fps lattice is genuinely different from 18" % key,
		"%d of 10 frames off the 18 fps grid" % differed)
	model.step_fps = AnimationFeel.STEPPED_FPS


## Systems 3, 4 and 6: the additive layer must move the upper body, must scale with the
## contact, and must never touch the hips (the facing authority).
func _audit_body_layer(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var mod := model.body_modifier
	if mod == null or model.skeleton == null:
		_check(false, "%s has no body modifier to inspect" % key)
		return
	var bones := mod.bone_indices()
	for wanted in ["spine1", "spine2", "neck", "head"]:
		_check(int(bones[wanted]) >= 0, "%s cached the %s bone" % [key, wanted])

	# --- 3. Whole-body engagement / negative space ------------------------------------
	mod.reset()
	mod.engage_weight = 1.0
	mod.engage_twist = AnimationFeel.ENGAGE_TWIST
	mod.negative_space = AnimationFeel.NEGATIVE_SPACE
	mod.eye_line_yaw = AnimationFeel.EYE_LINE
	mod.facing = 1
	var before := _bone_rotations(model.skeleton, bones)
	# `apply_now(true)` because the audit measures several strengths inside one frame; the
	# runtime path never forces and applies exactly once per frame.
	var hips_before := model.skeleton.get_bone_pose_rotation(int(bones.get("hips", -1))) \
		if bones.has("hips") else model.skeleton.get_bone_pose_rotation(model._bone_suffix("Hips"))
	mod.apply_now(true)
	var after := _bone_rotations(model.skeleton, bones)
	var moved := 0
	for name in after:
		if not before.has(name):
			continue
		if (after[name] as Quaternion).angle_to(before[name]) > 0.002:
			moved += 1
	_check(moved >= 5, "%s whole-body engagement moves shoulder/spine/neck/head" % key,
		"%d bones changed" % moved)
	var hips_after := model.skeleton.get_bone_pose_rotation(model._bone_suffix("Hips"))
	_check(hips_before.angle_to(hips_after) < 0.01,
		"%s hips untouched by the engagement layer (facing stays exact)" % key,
		"%.5f rad" % hips_before.angle_to(hips_after))

	# --- 4. Alive hitstop micro-tension -------------------------------------------------
	mod.reset()
	var still := _bone_rotations(model.skeleton, bones)
	mod.tension = AnimationFeel.tension_amount(0.1, true)
	mod.apply_now(true)
	var tense := _bone_rotations(model.skeleton, bones)
	var tension_moved := 0
	for name in tense:
		if not still.has(name):
			continue
		if (tense[name] as Quaternion).angle_to(still[name]) > 0.0005:
			tension_moved += 1
	_check(tension_moved > 0, "%s hitstop keeps a charged micro-tension" % key,
		"%d bones" % tension_moved)
	_check(is_zero_approx(AnimationFeel.tension_amount(0.1, false)),
		"%s micro-tension is silent outside hitstop" % key)

	# --- 6. Recoil scaled by contact strength -------------------------------------------
	var deltas: Array[float] = []
	for strength in [AnimationFeel.RECOIL_LIGHT, AnimationFeel.RECOIL_HEAVY,
			AnimationFeel.RECOIL_COUNTER]:
		mod.reset()
		var base := _bone_rotations(model.skeleton, bones)
		mod.recoil_strength = strength
		mod.recoil_curve = 1.0
		mod.apply_now(true)
		var hit := _bone_rotations(model.skeleton, bones)
		var total := 0.0
		for name in hit:
			if base.has(name):
				total += (hit[name] as Quaternion).angle_to(base[name])
		deltas.append(total)
	_check(deltas.size() == 3 and deltas[0] > 0.0 and deltas[0] < deltas[1] and deltas[1] < deltas[2],
		"%s recoil whip scales light < heavy < counter" % key,
		"%.3f / %.3f / %.3f rad" % [deltas[0], deltas[1], deltas[2]])

	# The real signal path: a landed strike must arm the recoil on the model.
	fighter.state = BaseFighter.State.IDLE
	model.recoil_strength = 0.0
	fighter.strike_resolved.emit(fighter, fighter, {"damage": 15, "blocked": false, "counter": false})
	_check(is_equal_approx(model.recoil_strength, AnimationFeel.RECOIL_HEAVY),
		"%s strike_resolved arms a heavy recoil", "%.2f" % model.recoil_strength)
	# ...but only for a strike that lands on THIS fighter.
	model.recoil_strength = 0.0
	var other := await _make_fighter(&"feedback")
	fighter.strike_resolved.emit(fighter, other, {"damage": 15, "blocked": false, "counter": false})
	_check(is_zero_approx(model.recoil_strength),
		"%s ignores a strike that lands on the opponent" % key)
	other.queue_free()
	mod.reset()


## Commit-4 refinements: the chest cheat really turns the chest, the influence cap clips a
## pathological request instead of applying it, and the layer is driven at a known point in the
## frame — a child of the skeleton that the skeleton never invokes itself — which is what makes
## the order "after the curve, before the foot pin" a property instead of a hope.
func _audit_influence(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var mod := model.body_modifier
	if mod == null or model.skeleton == null:
		return
	var parent := mod.get_parent()
	_check(parent == model.skeleton and not mod.active,
		"%s body layer is driven explicitly, never by the skeleton's own pass" % key,
		"parent %s, active %s" % [parent.name if parent != null else "-", str(mod.active)])
	var bones := mod.bone_indices()
	var spine2 := int(bones["spine2"])
	if spine2 < 0:
		return

	# Camera-facing chest cheat: the chest comes out of profile at the strike pose.
	model.set_facing(1)
	mod.reset()
	var chest_before := model.skeleton.get_bone_pose_rotation(spine2)
	mod.chest_yaw = AnimationFeel.CHEST_CHEAT
	mod.apply_now(true)
	var chest_delta := chest_before.angle_to(model.skeleton.get_bone_pose_rotation(spine2))
	_check(chest_delta > 0.02,
		"%s the chest turns toward camera at the strike pose" % key,
		"%.1f deg" % rad_to_deg(chest_delta))

	# A pathological request is clipped: one bone never takes more than `MAX_BONE_YAW`.
	mod.reset()
	var pre := model.skeleton.get_bone_pose_rotation(spine2)
	mod.chest_yaw = 2.0
	mod.engage_twist = 2.0
	mod.apply_now(true)
	var applied := pre.angle_to(model.skeleton.get_bone_pose_rotation(spine2))
	_check(applied <= AnimationFeel.MAX_BONE_YAW + 0.02,
		"%s one bone never takes more than the %.0f° ceiling" % [key,
			rad_to_deg(AnimationFeel.MAX_BONE_YAW)], "%.1f deg" % rad_to_deg(applied))
	_check(mod.yaw_spent() <= AnimationFeel.INFLUENCE_CAP + 0.0001,
		"%s the influence cap bounds a runaway frame" % key,
		"%.2f of %.2f rad" % [mod.yaw_spent(), AnimationFeel.INFLUENCE_CAP])

	# Every system at its own maximum at once, as a real strike frame would ask: the budget holds
	# and the ±X facing the audit depends on is untouched.
	mod.reset()
	mod.engage_weight = 1.0
	mod.engage_twist = AnimationFeel.ENGAGE_TWIST
	mod.negative_space = AnimationFeel.NEGATIVE_SPACE
	mod.eye_line_yaw = AnimationFeel.EYE_LINE
	mod.chest_yaw = AnimationFeel.CHEST_CHEAT
	mod.overshoot = AnimationFeel.overshoot_lean(AnimationFeel.WHIP_FRAME)
	mod.arc_bias = AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0)
	mod.tension = AnimationFeel.TENSION_PEAK
	mod.recoil_strength = AnimationFeel.RECOIL_COUNTER
	mod.recoil_curve = 1.0
	mod.apply_now(true)
	_check(mod.yaw_spent() <= AnimationFeel.INFLUENCE_CAP + 0.0001,
		"%s the full strike stack fits inside the influence cap" % key,
		"%.2f of %.2f rad" % [mod.yaw_spent(), AnimationFeel.INFLUENCE_CAP])
	var fwd := model.world_forward()
	var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
	_check(err <= FACING_TOLERANCE_DEG,
		"%s facing stays ±X under maximum influence" % key, "%.1f deg off" % err)
	mod.reset()


## Commit-3 refinements, measured on the real body: the coil depth follows the move's weight,
## the swing arc actually rotates the striking shoulder/arm, and the smear is exactly one
## frame of bone scale that is fully restored the next frame.
func _audit_attack_curve(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var clip := String(model.clips.get(&"light", ""))
	if clip == "":
		return
	# --- coil depth by move weight --------------------------------------------------
	fighter.state = BaseFighter.State.ATTACK_STARTUP
	fighter._attack = fighter.attacks[&"jab"]
	fighter._attack_id = &"jab"
	fighter.state_frame = int(fighter._attack.get("startup", 1))
	var light := model._attack_clip_progress(BaseFighter.State.ATTACK_STARTUP, clip)
	fighter._attack = fighter.attacks[&"upper_box"]
	fighter._attack_id = &"upper_box"
	fighter.state_frame = int(fighter._attack.get("startup", 1))
	var heavy := model._attack_clip_progress(BaseFighter.State.ATTACK_STARTUP, clip)
	_check(heavy < light,
		"%s winds deeper for a heavy than for a jab (visual only)" % key,
		"%.3f vs %.3f" % [heavy, light])

	# --- arc enforcement on the real bones ------------------------------------------
	var mod := model.body_modifier
	if mod == null:
		return
	var bones := mod.bone_indices()
	mod.reset()
	var base := _bone_rotations(model.skeleton, bones)
	mod.arc_bias = AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0)
	mod.facing = 1
	mod.apply_now(true)
	var arced := _bone_rotations(model.skeleton, bones)
	var arc_moved := 0
	for name in arced:
		if base.has(name) and (arced[name] as Quaternion).angle_to(base[name]) > 0.002:
			arc_moved += 1
	_check(arc_moved >= 2, "%s the swing arc rotates the striking shoulder and arm" % key,
		"%d bones" % arc_moved)

	# --- one-frame smear -------------------------------------------------------------
	mod.reset()
	# The hips may legitimately carry a non-unit scale from the upload's own bind pose (the
	# Tripo bodies ship a 0.01 unit scale), so the contract is "the layer does not change it",
	# not "it is one".
	var hips := model._bone_suffix("Hips")
	var hips_before: Vector3 = model.skeleton.get_bone_pose_scale(hips) \
		if hips >= 0 else Vector3.ONE
	mod.smear = 1.0
	mod.facing = 1
	mod.apply_now(true)
	var arm_index := int(bones["arm_r"])
	var scaled: Vector3 = model.skeleton.get_bone_pose_scale(arm_index) \
		if arm_index >= 0 else Vector3.ONE
	_check(mod.is_smeared() and scaled.y > 1.0,
		"%s the whip stretches the striking arm for one frame" % key,
		"scale (%.3f, %.3f, %.3f)" % [scaled.x, scaled.y, scaled.z])
	mod.smear = 0.0
	mod.apply_now(true)
	var restored: Vector3 = model.skeleton.get_bone_pose_scale(arm_index) \
		if arm_index >= 0 else Vector3.ONE
	_check(not mod.is_smeared() and restored == Vector3.ONE,
		"%s the smear is fully restored on the next frame" % key,
		"scale (%.3f, %.3f, %.3f)" % [restored.x, restored.y, restored.z])
	var hips_after: Vector3 = model.skeleton.get_bone_pose_scale(hips) \
		if hips >= 0 else Vector3.ONE
	_check(hips < 0 or hips_after.is_equal_approx(hips_before),
		"%s the smear never scales the hips" % key,
		"%.4f -> %.4f" % [hips_before.y, hips_after.y])
	mod.reset()


func _bone_rotations(skel: Skeleton3D, bones: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	var seen: Array[int] = []
	for name in bones:
		var index := int(bones[name])
		if index < 0 or seen.has(index):
			continue
		seen.append(index)
		out[name] = skel.get_bone_pose_rotation(index)
	return out


## System 5: the pop must exist as a node, use the two authored presets and come back to
## exactly `Vector3.ONE`, with the hand props counter-scaled so they cannot be stretched.
func _audit_squash(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	if model.squash_pivot == null:
		return
	fighter._attack_id = &"strong"
	fighter._attack = fighter.attacks[&"strong"]
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._hitstop_frames = 0
	model._squash_scale = Vector3.ONE
	model._squash_velocity = Vector3.ZERO
	var peak := Vector3.ONE
	for i in 24:
		model._apply_squash_pop(1.0 / 60.0, BaseFighter.State.ATTACK_ACTIVE)
		var s := model.squash_pivot.scale
		if s.length() > peak.length():
			peak = s
	_check(peak.x > 1.0 and peak.z < 1.0,
		"%s heavy contact stretches the SquashPivot" % key,
		"peak (%.3f, %.3f, %.3f)" % [peak.x, peak.y, peak.z])

	# A leap reaction compresses instead (wider and shorter).
	fighter.state = BaseFighter.State.KNOCKDOWN
	peak = Vector3.ONE
	for i in 24:
		model._apply_squash_pop(1.0 / 60.0, BaseFighter.State.KNOCKDOWN)
		var s := model.squash_pivot.scale
		if absf(s.y - 1.0) > absf(peak.y - 1.0):
			peak = s
	_check(peak.y < 1.0 and peak.x > 1.0,
		"%s landing/knockdown squashes the SquashPivot" % key,
		"peak (%.3f, %.3f, %.3f)" % [peak.x, peak.y, peak.z])

	# Prop isolation: the attachment's local scale must cancel the parent's pop.
	if not model.hand_props.is_empty() and model.hand_props[0] != null:
		model._squash_scale = Vector3(1.07, 1.04, 0.95)
		model._isolate_props()
		var prop_scale := model.hand_props[0].scale
		_check(prop_scale.x < prop_scale.z,
			"%s hand prop is counter-scaled against the pop" % key,
			"(%.3f, %.3f, %.3f)" % [prop_scale.x, prop_scale.y, prop_scale.z])

	# Back to rest: the spring must land exactly on one, never drift.
	fighter.state = BaseFighter.State.IDLE
	for i in 300:
		model._apply_squash_pop(1.0 / 60.0, fighter.state)
		if model.squash_pivot.scale == Vector3.ONE:
			break
	_check(model.squash_pivot.scale == Vector3.ONE,
		"%s squash returns exactly to Vector3.ONE" % key,
		"(%.3f, %.3f, %.3f)" % [model.squash_pivot.scale.x, model.squash_pivot.scale.y,
			model.squash_pivot.scale.z])


## System 6: the planted foot must sit on the sand within 1 cm, in every grounded state and
## both facings, measured from the REAL skinned mesh — not from the bone table.
func _audit_pinning(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var states := {
		"IDLE": BaseFighter.State.IDLE,
		"WALK": BaseFighter.State.WALK,
		"ATTACK_ACTIVE": BaseFighter.State.ATTACK_ACTIVE,
		"HITSTUN": BaseFighter.State.HITSTUN,
		"TAUNT": BaseFighter.State.TAUNT,
	}
	fighter._attack_id = &"jab"
	fighter._attack = fighter.attacks[&"jab"]
	for facing in [1, -1]:
		model.set_facing(facing)
		for label in states:
			fighter.state = states[label]
			model._animate_pose(1.0 / 60.0)
			for i in 6:
				model._pin_feet_to_ground()
			var sole := _skinned_lowest(model)
			_check(absf(sole) <= PIN_TOLERANCE,
				"%s %s facing %+d keeps the sole on the sand" % [key, label, facing],
				"lowest drawn y %+.4f m" % sole)


## Lowest drawn point of the live skinned mesh, in world space.
func _skinned_lowest(model: FighterModel3D) -> float:
	var mi: MeshInstance3D = null
	for m in model.meshes:
		if m.mesh != null and m.mesh.get_surface_count() > 0:
			mi = m
			break
	var skel := model.skeleton
	if mi == null or skel == null:
		return INF
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return INF
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	var skin: Skin = mi.skin
	# Measure the drawn sole the same way the game does: the three uploads disagree on how
	# `ARRAY_BONES` indexes the skin, and the model decides that once at bind.
	var mapped: bool = bool(model.sole_bind_mapped)
	var bone_xf: Array[Transform3D] = []
	if skin != null and mapped:
		for b in skin.get_bind_count():
			var bone := skin.get_bind_bone(b)
			if bone < 0 or bone >= skel.get_bone_count():
				bone_xf.append(Transform3D.IDENTITY)
				continue
			bone_xf.append(skel.global_transform * skel.get_bone_global_pose(bone)
				* skin.get_bind_pose(b))
	else:
		for i in skel.get_bone_count():
			var xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(i)
			if skin != null and i < skin.get_bind_count():
				xf = xf * skin.get_bind_pose(i)
			bone_xf.append(xf)
	var per := 0
	if vbones != null and weights != null and verts.size() > 0:
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
			if total > 0.0:
				p = acc / total
		low = minf(low, p.y)
		i += step
	return low
