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
## The shipped combat frame data, frozen: `[startup, active, recovery, damage, hitbox y]`.
## Every entry is what `BaseFighter` + `FighterRoster` actually ship, so a presentation pass
## that quietly moved a startup tick or a hitbox height fails here. The hitbox y is included
## because the hit-react direction reads it.
const FRAME_BASELINE := {
	&"feedback": {
		&"jab": [4, 3, 9, 8, -110],
		&"strong": [9, 4, 18, 15, -125],
		&"tump": [12, 4, 12, 15, -78],
		&"upper_box": [8, 4, 16, 15, -132],
	},
	&"lickshot": {
		&"jab": [3, 3, 7, 7, -112],
		&"strong": [11, 3, 22, 10, -118],
		&"tump": [10, 3, 16, 14, -96],
		&"upper_box": [14, 4, 20, 18, -118],
	},
	&"young_selecta": {
		&"jab": [3, 3, 6, 7, -96],
		&"strong": [12, 3, 20, 12, -112],
		&"tump": [10, 3, 14, 11, -30],
		&"upper_box": [13, 5, 20, 18, -108],
	},
}
## Scripts that may never build a prop or a character out of a primitive mesh. Stage
## structure (the sand floor, the barrier, the truss) is allowed to use them — a prop or a
## body is not. `MusicNoteBurst` builds an `ArrayMesh` glyph, which is VFX, not a prop.
const CHARACTER_SCRIPTS: Array[String] = [
	"res://scripts/fighters/FighterModel3D.gd",
	"res://scripts/fighters/FighterProps.gd",
	"res://scripts/fighters/FighterBillboard3D.gd",
	"res://scripts/PropLoader.gd",
	"res://scripts/stages/CrowdController3D.gd",
	"res://scripts/stages/DJBooth3D.gd",
	"res://scripts/stages/CharacterModelSlots.gd",
]
## The built scenes a character or prop could sneak a primitive into.
const CHARACTER_SCENES: Array[String] = [
	"res://scenes/BaseFighter.tscn",
	"res://scenes/TestArena.tscn",
	"res://scenes/TitleScreen.tscn",
]
const PRIMITIVE_MESHES: Array[String] = ["BoxMesh", "CylinderMesh", "QuadMesh", "PlaneMesh",
	"SphereMesh", "CapsuleMesh", "PrismMesh"]

var _checks := 0
var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("\n=== ANIMATION FEEL AUDIT (Stefan Iverson overhaul) ===")
	_audit_combat_files()
	_audit_no_primitive_meshes()
	await _audit_static_curves()
	for key in FIGHTERS:
		await _audit_fighter(key)
	await _audit_allocation()
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
	# 3b. Extremity exclusion (commit 1, 2026-11-26): the reach extension is a rotation, never a
	# hand translation or a limb scale, and every hand/finger/foot/toe bone is off limits.
	_check(AnimationFeel.is_extremity_bone("mixamorig_LeftHand")
			and AnimationFeel.is_extremity_bone("mixamorig_RightHandIndex3")
			and AnimationFeel.is_extremity_bone("mixamorig_LeftFoot")
			and AnimationFeel.is_extremity_bone("mixamorig_RightToeBase")
			and not AnimationFeel.is_extremity_bone("mixamorig_LeftForeArm")
			and not AnimationFeel.is_extremity_bone("mixamorig_Spine2"),
		"the extremity contract covers hands, fingers, feet and toes only")
	var short_reach := AnimationFeel.reach_angle(0.02, 0.55)
	var long_reach := AnimationFeel.reach_angle(0.07, 0.55)
	_check(short_reach > 0.0 and long_reach > short_reach
			and long_reach < deg_to_rad(40.0)
			and AnimationFeel.reach_angle(0.5, 0.55) <= deg_to_rad(34.0),
		"reach is an arc of the arm, and the arc stays short of folding it",
		"%.1f deg for 7 cm on a 55 cm arm" % rad_to_deg(long_reach))

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
	# The AnimationPlayer binds its tracks only after it has processed frames, and the model
	# re-measures `t_impact` once that has happened; read the table after that, not before.
	for i in 4:
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
	await _audit_airborne_pin(model, fighter, key)

	# --- PART 2: frame data, root motion, reach, hold, volume, extras -----------------
	_audit_frame_data(key, fighter)
	await _audit_root_motion(model, fighter, key)
	await _audit_impact_reach(model, fighter, key)
	await _audit_hold_and_hitstop(model, fighter, key)
	_audit_volume_and_props(model, fighter, key)
	_audit_extras(model, fighter, key)

	# --- PART 1 commits 2–3: Zweifuss / Iverson techniques + foreshortening + rim -------
	await _audit_zweifuss(model, fighter, key)

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
	# seeks to land on the 16 fps lattice.
	model.step_fps = 16.0
	var steps16 := AnimationFeel.step_count(anim.length, 16.0)
	var on_16 := true
	for frame in range(0, 10):
		fighter.state_frame = frame
		model._drive_clip_time()
		var t: float = model.animation.current_animation_position / anim.length
		if absf(t * float(steps16) - round(t * float(steps16))) > 0.0005:
			on_16 = false
	_check(on_16, "%s step_fps=16 re-grids the clip onto the 16 fps lattice" % key,
		"%d steps" % steps16)
	# The 16-lattice must be a DIFFERENT lattice, not just a coarser walk over the same poses.
	# Compared over the whole clip rather than over the 3-4 active frames Godot ships, because a
	# short window can land on a pose that happens to exist on both grids (1/3 and 2/3 do).
	var foreign := 0
	for s in range(0, 64):
		var probe_t := float(s) / 63.0
		var q := AnimationFeel.quantize(probe_t, steps16)
		if absf(q * float(steps) - round(q * float(steps))) > 0.0005:
			foreign += 1
	_check(steps16 != steps and foreign >= 16,
		"%s the 16 fps lattice is genuinely different from 18" % key,
		"%d of 64 poses exist on 16 fps but not 18 (%d vs %d steps)" % [foreign, steps16, steps])
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

	# --- reach is a rotation, and it leaves the hand alone ---------------------------
	mod.reset()
	var hand_index := int(bones["arm_r"])
	var hand_bone := model._bone_suffix("RightHand")
	var hand_before := model.skeleton.get_bone_pose_position(hand_bone) \
		if hand_bone >= 0 else Vector3.ZERO
	var arm_before: Quaternion = model.skeleton.get_bone_pose_rotation(hand_index) \
		if hand_index >= 0 else Quaternion.IDENTITY
	mod.reach_boost = AnimationFeel.REACH_BOOST_MAX
	mod.facing = 1
	mod.apply_now(true)
	var hand_after := model.skeleton.get_bone_pose_position(hand_bone) \
		if hand_bone >= 0 else Vector3.ZERO
	var arm_after: Quaternion = model.skeleton.get_bone_pose_rotation(hand_index) \
		if hand_index >= 0 else Quaternion.IDENTITY
	_check(hand_bone < 0 or hand_before.is_equal_approx(hand_after),
		"%s the reach boost never translates the hand bone" % key,
		"delta %.5f m" % hand_before.distance_to(hand_after))
	_check(hand_index < 0 or arm_before.angle_to(arm_after) > 0.002,
		"%s the reach boost rotates the upper arm instead" % key,
		"%.2f deg" % rad_to_deg(arm_before.angle_to(arm_after)))
	_check(model.skeleton.get_bone_pose_scale(hand_bone).is_equal_approx(Vector3.ONE)
			if hand_bone >= 0 else true,
		"%s the hand bone keeps its authored scale through the reach" % key,
		str(model.skeleton.get_bone_pose_scale(hand_bone) if hand_bone >= 0 else Vector3.ONE))
	mod.reset()


## Commit 1 (2026-11-26). The owner's playtest called the hand "mutilated": the presentation
## layer was writing the hand bone itself — a 1.08× foreshortening scale on a heavy contact, a
## one-frame limb smear scale on the arm chain, and a `reach_boost` TRANSLATION of the hand away
## from the wrist, which stretches the skin weights that fan a hand into four fingers. All three
## are removed; reach is now a rotation of the shoulder and upper arm.
##
## This is the replacement contract, measured against the authored pose on the real body: for
## every fighter, BOTH slots, and STARTUP / ACTIVE / RECOVERY of every attack (J, K, U, I, L, S),
## every hand, finger, foot and toe bone must report exactly the clip's own local transform, and
## the drawn hand must keep its size under the skinned-vertex sampler.
func _audit_extremities(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var mod := model.body_modifier
	var skel := model.skeleton
	if mod == null or skel == null:
		_check(true, "%s has no rig to police" % key)
		return
	var extremities: Array[int] = []
	for i in skel.get_bone_count():
		if AnimationFeel.is_extremity_bone(skel.get_bone_name(i)):
			extremities.append(i)
	var uncovered := 0
	for i in extremities:
		if not mod.is_extremity(i):
			uncovered += 1
	_check(extremities.size() >= 40 and uncovered == 0,
		"%s the exclusion mask covers every extremity bone" % key,
		"%d bones, %d uncovered, arm lever %.2f m" % [extremities.size(), uncovered,
			mod.arm_length()])

	var attacks: Array[StringName] = []
	for id in [&"jab", &"strong", &"tump", &"upper_box", &"special", &"kick"]:
		if fighter.attacks.has(id):
			attacks.append(id)
	var best := 0.0
	var scaled_writes := 0
	var phases := [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE,
		BaseFighter.State.ATTACK_RECOVERY]
	for slot in [1, -1]:
		for id in attacks:
			fighter._attack = fighter.attacks[id]
			fighter._attack_id = id
			for state in phases:
				fighter.state = state
				fighter.state_frame = 1
				# The authored pose, with the layer switched off completely.
				mod.enabled = false
				mod.reset()
				mod.facing = slot
				model._configure_body_modifier(state)
				var authored := _capture_extremities(skel, extremities)
				# The same frame with the whole stack at its loudest.
				mod.enabled = true
				mod.reach_boost = AnimationFeel.REACH_BOOST_MAX
				mod.arc_bias = AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0)
				mod.overshoot = AnimationFeel.overshoot_lean(AnimationFeel.WHIP_FRAME)
				mod.engage_twist = AnimationFeel.ENGAGE_TWIST
				mod.chest_yaw = AnimationFeel.CHEST_CHEAT
				mod.apply_now(true)
				var live := _capture_extremities(skel, extremities)
				for i in authored.size():
					best = maxf(best, absf(live[i] - authored[i]))
				for i in extremities:
					if not skel.get_bone_pose_scale(i).is_equal_approx(Vector3.ONE):
						scaled_writes += 1
	_check(best <= 0.0001,
		"%s hand/finger/foot/toe bones keep the authored pose in every attack, phase and slot" % key,
		"worst channel drift %.6f over %d attacks x 3 phases x 2 slots" % [best, attacks.size()])
	_check(scaled_writes == 0,
		"%s no extremity bone carries a scale" % key, "%d scaled reads" % scaled_writes)

	# Drawn geometry, same clip frame both times: the hand's own size cannot change if nothing
	# writes the hand. `rest` is the ACTIVE pose with the layer switched off.
	mod.reset()
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._attack_id = &"strong"
	fighter._attack = fighter.attacks[&"strong"]
	fighter.state_frame = 3
	mod.enabled = false
	model._animate_pose(0.0)
	var rest := _skinned_extremity_metrics(model)
	mod.enabled = true
	mod.facing = model.facing_sign
	model._configure_body_modifier(BaseFighter.State.ATTACK_ACTIVE)
	mod.reach_boost = AnimationFeel.REACH_BOOST_MAX
	mod.arc_bias = AnimationFeel.arc_bias(AnimationFeel.WHIP_FRAME, 1.0)
	mod.apply_now(true)
	var live_metrics := _skinned_extremity_metrics(model)

	# 1. The sampler finds real glove geometry (a rig that silently skipped the hand would
	#    otherwise pass every check above without measuring anything).
	_check(rest.x > 0.0 and rest.y > 0.0,
		"%s the skinned sampler finds the drawn hand" % key,
		"%.3f m fingertip radius over the hand-weighted vertices" % rest.x)
	# 2. The sampler is sensitive: re-applying the removed 1.08x hand scale is detected. This
	#    is the check that could not be written before the fix — it proves the hand bug would
	#    have been caught, instead of merely asserting the hand is now untouched.
	var wrist_bone := model._bone_suffix("RightHand")
	var caught := 0.0
	if wrist_bone >= 0:
		var before_scale := skel.get_bone_pose_scale(wrist_bone)
		var clean := _capture_extremities(skel, [wrist_bone])
		skel.set_bone_pose_scale(wrist_bone, Vector3.ONE * 1.08)
		var dirty := _capture_extremities(skel, [wrist_bone])
		skel.set_bone_pose_scale(wrist_bone, before_scale)
		for i in dirty.size():
			caught = maxf(caught, absf(dirty[i] - clean[i]))
	_check(caught >= 0.01,
		"%s the pinch detector would catch a 1.08x glove scale" % key,
		"%.3f channel change" % caught)

	# 3. Write refusal, per bone kind: even a direct request cannot move a hand, foot or toe.
	for probe in ["RightHand", "LeftHand", "RightFoot", "RightToeBase"]:
		var idx := model._bone_suffix(probe)
		if idx < 0:
			continue
		mod.reset()
		mod.facing = 1
		var before_rotation := skel.get_bone_pose_rotation(idx)
		var before_position := skel.get_bone_pose_position(idx)
		mod._add(idx, Vector3.UP, 0.6)
		mod._add(idx, Vector3.RIGHT, 0.4)
		_check(skel.get_bone_pose_rotation(idx).is_equal_approx(before_rotation)
				and skel.get_bone_pose_position(idx).is_equal_approx(before_position),
			"%s a direct write to %s is refused" % [key, probe])
	mod.reset()
	mod.enabled = true
	fighter.state = BaseFighter.State.IDLE
	fighter.state_frame = 0


## Flattened local pose of every extremity bone: position, rotation, scale. Comparing two
## captures is how the audit proves the additive layer wrote none of them.
func _capture_extremities(skel: Skeleton3D, indices: Array[int]) -> Array[float]:
	var out: Array[float] = []
	for i in indices:
		var p := skel.get_bone_pose_position(i)
		var q := skel.get_bone_pose_rotation(i)
		var s := skel.get_bone_pose_scale(i)
		out.append(p.x)
		out.append(p.y)
		out.append(p.z)
		out.append(q.x)
		out.append(q.y)
		out.append(q.z)
		out.append(q.w)
		out.append(s.x)
		out.append(s.y)
		out.append(s.z)
	return out


## Skinned-vertex metrics for the striking hand: `x` is the farthest fingertip radius from the
## wrist bone, `y` the mean radius over the same hand-weighted vertices.
func _skinned_extremity_metrics(model: FighterModel3D) -> Vector2:
	var skel := model.skeleton
	if skel == null:
		return Vector2.ZERO
	# Global poses are cached by the skeleton; in a headless run with no frame tick a bone the
	# modifier just wrote would otherwise still report last frame's chain.
	skel.force_update_all_bone_transforms()
	var wrist := model._bone_suffix("RightHand")
	if wrist < 0:
		return Vector2.ZERO
	# Radii from the wrist bone, not a world-space box: the arm swings through ACTIVE, so an
	# axis-aligned box changes size just by rotating. A radius is rotation-invariant and scales
	# exactly with the hand bone, so it catches the removed 1.08× hand scale and nothing else.
	var wrist_origin: Vector3 = skel.get_bone_global_pose(wrist).origin
	var far := 0.0
	var total := 0.0
	var count := 0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi == null or mi.mesh == null or mi.skin == null:
			continue
		var arrays := mi.mesh.surface_get_arrays(0)
		if arrays.is_empty() or arrays[Mesh.ARRAY_BONES] == null:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if verts.is_empty() or bones.is_empty():
			continue
		var per := bones.size() / verts.size()
		if per <= 0:
			continue
		var skin: Skin = mi.skin
		# Decide the ARRAY_BONES convention by evidence on this mesh rather than by the model's
		# sole flag: whichever mapping finds the hand/finger bones is the one that is correct.
		var mapped := _hand_mapping(skel, skin, bones, per, verts.size())
		for v in verts.size():
			# Dominant-weight only: a vertex shared 50/50 with the forearm legitimately moves when
			# the forearm rotates, so it says nothing about whether the hand itself was deformed.
			var top := -1.0
			var top_bone := -1
			var top_entry := -1
			for k in per:
				if weights[v * per + k] > top:
					top = weights[v * per + k]
					top_entry = bones[v * per + k]
					top_bone = _bind_bone(skin, top_entry, mapped)
			if top_bone < 0 or top < 0.95 or not _is_hand_bone(skel.get_bone_name(top_bone)):
				continue
			# Dominant-bone skinning: the vertex rides the hand/finger bone it is bound to. A
			# stray forearm weight would move the point whenever the arm rotates (which the reach
			# boost does on purpose), and that is arm motion, not hand deformation.
			var p := (skel.get_bone_global_pose(top_bone) * skin.get_bind_pose(top_entry)) * verts[v]
			var radius := wrist_origin.distance_to(p)
			far = maxf(far, radius)
			total += radius
			count += 1
	if count == 0:
		return Vector2.ZERO
	return Vector2(far, total / float(count))


## Which `ARRAY_BONES` convention this mesh uses, decided by counting how many sampled
## vertices land on a hand/finger bone under each mapping.
func _hand_mapping(skel: Skeleton3D, skin: Skin, bones: PackedInt32Array, per: int,
		count: int) -> bool:
	var direct_hits := 0
	var mapped_hits := 0
	var sample := mini(count, 400)
	for v in sample:
		var e := bones[v * per]
		if e >= 0 and e < skel.get_bone_count() and _is_hand_bone(skel.get_bone_name(e)):
			direct_hits += 1
		var mapped := skin.get_bind_bone(e) if e >= 0 and e < skin.get_bind_count() else -1
		if mapped >= 0 and _is_hand_bone(skel.get_bone_name(mapped)):
			mapped_hits += 1
	return mapped_hits > direct_hits


## Hands and fingers only — feet and toes are extremities too, but a hand metric that also
## spanned the feet would change size every time a fighter moved a leg.
func _is_hand_bone(bone_name: String) -> bool:
	return AnimationFeel.is_extremity_bone(bone_name) and not bone_name.ends_with("Foot") \
		and not bone_name.ends_with("ToeBase") and not bone_name.ends_with("ToeEnd")


## Bone id behind one `ARRAY_BONES` entry. Godot's skinned mesh may store either the skin's bind
## index or the skeleton bone index, so both are tried rather than assuming one convention.
func _bind_bone(skin: Skin, entry: int, mapped: bool) -> int:
	if entry < 0:
		return -1
	# The three uploads disagree on how `ARRAY_BONES` indexes the skin; `FighterModel3D`
	# decides the convention once at bind and the audit reads the same flag.
	if mapped:
		return skin.get_bind_bone(entry) if entry < skin.get_bind_count() else -1
	return entry


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

	# Prop isolation: the pop is applied ABOVE the rotating hand, so a local counter-scale alone
	# would still shear the mic. The attachment's WORLD basis must come back to the basis it has
	# at rest — same axis lengths, same orientation — no matter what the body is doing.
	if not model.hand_props.is_empty() and model.hand_props[0] != null:
		model._squash_scale = Vector3.ONE
		model.squash_pivot.scale = Vector3.ONE
		model._isolate_props()
		var rest_basis: Basis = model.hand_props[0].global_transform.basis
		model._squash_scale = Vector3(1.07, 1.04, 0.95)
		model.squash_pivot.scale = model._squash_scale
		model._isolate_props()
		var warped: Basis = model.hand_props[0].global_transform.basis
		var worst_axis := 0.0
		var worst_turn := 0.0
		for axis in 3:
			worst_axis = maxf(worst_axis, absf(warped[axis].length() - rest_basis[axis].length()))
			worst_turn = maxf(worst_turn, warped[axis].angle_to(rest_basis[axis]))
		_check(worst_axis <= 0.001 and worst_turn <= 0.001,
			"%s hand prop keeps its rest world basis through the pop" % key,
			"worst axis %.4f m, %.3f deg" % [worst_axis, rad_to_deg(worst_turn)])
		model._squash_scale = Vector3.ONE
		model.squash_pivot.scale = Vector3.ONE
		model._isolate_props()

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
##
## PART A3 commit 1: the same one-sampler rule as every other audit and the runtime. The old
## body measured the FIRST mesh and, on a rig whose bind order differs from its bone order,
## fell back to indexing the skin with the bone index — a body nobody draws.
func _skinned_lowest(model: FighterModel3D) -> float:
	return DrawnBounds.lowest_y(model)


# =========================================================================
# PART 2 — frame data, root motion, reach, hold, volume, extras, budget
# =========================================================================
## Every attack's startup/active/recovery/damage/hitbox height must be exactly what the combat
## data ships. A presentation pass is not allowed to move any of them, and the hit-react
## direction reads the height, so it is part of the baseline rather than an afterthought.
func _audit_frame_data(key: StringName, fighter: BaseFighter) -> void:
	var baseline: Dictionary = FRAME_BASELINE.get(key, {})
	_check(baseline.size() == fighter.attacks.size(),
		"%s ships exactly the %d audited attacks" % [key, baseline.size()],
		"%d in the fighter" % fighter.attacks.size())
	var mismatches: Array[String] = []
	for id in baseline:
		if not fighter.attacks.has(id):
			mismatches.append("%s missing" % id)
			continue
		var a: Dictionary = fighter.attacks[id]
		var want: Array = baseline[id]
		var got := [int(a["startup"]), int(a["active"]), int(a["recovery"]),
			int(a["damage"]), int((a["hitbox_pos"] as Vector2).y)]
		if got != want:
			mismatches.append("%s %s != %s" % [id, str(got), str(want)])
	_check(mismatches.is_empty(),
		"%s startup/active/recovery/damage/hitbox height match the baseline" % key,
		", ".join(mismatches) if not mismatches.is_empty() else "all 4 attacks")


## The world root is NOT stepped. Only the sampled skeleton pose sits on the 18 fps grid; the
## `CharacterBody2D` keeps moving on the smooth 60 Hz tick, and the model root simply follows
## it. A quantized root would read as a fighter gliding in staircase increments.
func _audit_root_motion(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var clip := String(model.clips.get(&"light", ""))
	if clip == "":
		return
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._attack = fighter.attacks[&"jab"]
	fighter._attack_id = &"jab"
	fighter.state_frame = 1
	var start_x := fighter.global_position.x
	var model_start := model.position.x
	# Four full frames of a real walk speed (Feedback moves 220 px/s → 3.6667 px/tick).
	var per_tick := 220.0 / 60.0
	var deltas: Array[float] = []
	var last := start_x
	for i in 8:
		fighter.global_position.x += per_tick
		model.position.x = fighter.global_position.x
		await process_frame
		deltas.append(fighter.global_position.x - last)
		last = fighter.global_position.x
	var moved := absf(fighter.global_position.x - start_x)
	_check(absf(moved - per_tick * 8.0) < 0.001,
		"%s root travels the full smooth distance while the pose is stepped" % key,
		"%.4f px over 8 ticks" % moved)
	var fractional := 0
	for d in deltas:
		if absf(d - round(d)) > 0.0005:
			fractional += 1
	_check(fractional == deltas.size(),
		"%s root motion is never quantized to whole pixels" % key,
		"%d of %d ticks fractional" % [fractional, deltas.size()])
	var root_moved := absf(model.position.x - model_start)
	_check(absf(root_moved - moved) < 0.001,
		"%s the model root simply follows the body" % key,
		"model moved %.4f px" % root_moved)
	fighter.global_position.x = start_x - per_tick * 8.0
	model.position.x = model_start


## `t_impact` must be the model's own measurement, recomputed here independently from the
## world-space reach of the striking hand, and never placed outside the legal impact window.
## This is what makes a measured impact time real rather than a constant that happens to sit
## inside the sanity band.
func _audit_impact_reach(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	if model.skeleton == null or model._bone_suffix("Hips") < 0:
		return
	var saved := String(model.animation.current_animation) if model.animation != null else ""
	# Same condition the model measures under: the additive overlay is muted, so a stale recoil
	# cannot move the peak between the two measurements.
	var mod_was_active := false
	if model.body_modifier != null:
		mod_was_active = model.body_modifier.active
		model.body_modifier.active = false
	var measured := 0
	for role in [&"light", &"strong", &"tump", &"upper_box", &"special", &"kick"]:
		if not model.clips.has(role):
			continue
		var clip := String(model.clips[role])
		var t_impact := float(model.impact_times.get(clip, AnimationFeel.COIL_END))
		var at_impact := _reach_at(model, clip, t_impact)
		# The exact sampling the model measures with: indices 1..N-1 of the 24-sample walk,
		# first strict maximum, inside the legal impact window only.
		var peak_t := AnimationFeel.COIL_END
		var peak := -INF
		for s in range(1, 24):
			var t := float(s) / 24.0
			if t < AnimationFeel.IMPACT_MIN - 0.0001 or t > AnimationFeel.IMPACT_MAX + 0.0001:
				continue
			var r := _reach_at(model, clip, t)
			if r > peak:
				peak = r
				peak_t = t
		measured += 1
		_check(at_impact > 0.25,
			"%s %s drives its striking hand clear of the pelvis at t_impact" % [key, role],
			"%.3f m" % at_impact)
		# Full extension at contact. The reach curve is flat within a few millimetres near its
		# top, so the assertion is on the DEPTH of the extension (>= 98 % of the peak the clip
		# can reach inside the legal window), not on the exact sample index.
		_check(at_impact >= peak * 0.98,
			"%s %s is at full extension at t_impact" % [key, role],
			"%.3f of a %.3f m peak at %.2f" % [at_impact, peak, peak_t])
		_check(t_impact >= AnimationFeel.IMPACT_MIN - 0.0001
			and t_impact <= AnimationFeel.IMPACT_MAX + 0.0001,
			"%s %s lands t_impact inside the legal impact window" % [key, role],
			"%.3f in [%.2f..%.2f]" % [t_impact, AnimationFeel.IMPACT_MIN, AnimationFeel.IMPACT_MAX])
	if model.body_modifier != null:
		model.body_modifier.active = mod_was_active
	if saved != "" and model.animation != null:
		model.animation.play(saved, 0.0)
	_check(measured >= 3, "%s measured the reach peak of every attack clip" % key,
		"%d clips" % measured)


## The striking hand's horizontal distance from the pelvis, in world metres, at one clip time.
## World space is the only scale all three rigs share (Feedback's skeleton is authored at ~1 cm
## and normalised 155x at the root, the Tripo rigs sit at 0.0016), and it is the reach the
## player actually sees.
func _reach_at(model: FighterModel3D, clip: String, t: float) -> float:
	var anim := model.animation.get_animation(clip)
	if anim == null or anim.length <= 0.0:
		return -INF
	model.reset_skeleton_to_rest()
	model.animation.play(clip, 0.0)
	model.animation.seek(anim.length * clampf(t, 0.0, 1.0), true)
	model.animation.advance(0.0)
	# Lazy pose computation would otherwise report the previous sample.
	model.skeleton.force_update_all_bone_transforms()
	return model.hand_reach()


## The whip crosses into `t_impact` within 2 frames, the settle takes 2–4 frames, and a frozen
## hit-stop holds the extended silhouette instead of letting it drift.
func _audit_hold_and_hitstop(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var t_impact := 0.48
	var coil := AnimationFeel.COIL_END
	var frames_to_impact := -1
	for frame in range(0, 8):
		if absf(AnimationFeel.active_progress(frame, t_impact, coil) - t_impact) < 0.0001:
			frames_to_impact = frame
			break
	_check(frames_to_impact >= 1 and frames_to_impact <= AnimationFeel.WHIP_FRAMES,
		"%s the whip reaches t_impact inside the %d-frame budget" % [key, AnimationFeel.WHIP_FRAMES],
		"%d frames" % frames_to_impact)
	_check(AnimationFeel.SETTLE_FRAMES >= 2 and AnimationFeel.SETTLE_FRAMES <= 4,
		"%s the settle holds for 2–4 frames" % key, "%d frames" % AnimationFeel.SETTLE_FRAMES)
	# A frozen contact: the state frame does not advance, so neither may the sampled pose.
	var clip := String(model.clips.get(&"light", ""))
	if clip == "" or model.animation == null:
		return
	var anim := model.animation.get_animation(clip)
	if anim == null or anim.length <= 0.0:
		return
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._attack = fighter.attacks[&"jab"]
	fighter._attack_id = &"jab"
	fighter.state_frame = 2
	fighter._hitstop_frames = 6
	model._play_role(&"light")
	await process_frame
	model._hold_index = -1
	model._drive_clip_time()
	var held := model.animation.current_animation_position
	var held_t := AnimationFeel.active_progress(2, float(model.impact_times.get(clip, t_impact)))
	for i in 6:
		model._drive_clip_time()
	_check(is_equal_approx(model.animation.current_animation_position, held),
		"%s the silhouette is held through the whole hit-stop" % key,
		"%.4f s unchanged over 6 frozen ticks" % held)
	_check(absf(held_t - float(model.impact_times.get(clip, t_impact))) < 0.0001,
		"%s the held pose is the impact pose" % key, "%.3f" % held_t)
	fighter._hitstop_frames = 0


## The impact pop's scale product stays inside 2 % on every frame, and the hand attachments'
## WORLD scale never changes while the body squashes and the arm smears.
func _audit_volume_and_props(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	if model.squash_pivot == null:
		return
	fighter._attack_id = &"strong"
	fighter._attack = fighter.attacks[&"strong"]
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._hitstop_frames = 0
	model._squash_scale = Vector3.ONE
	model._squash_velocity = Vector3.ZERO
	var worst := 0.0
	var peak := 1.0
	for i in 40:
		model._apply_squash_pop(1.0 / 60.0, BaseFighter.State.ATTACK_ACTIVE)
		var vol := AnimationFeel.squash_volume(model.squash_pivot.scale)
		worst = maxf(worst, absf(vol - 1.0))
		peak = maxf(peak, model.squash_pivot.scale.y)
	_check(worst <= AnimationFeel.SQUASH_VOLUME_TOLERANCE,
		"%s SquashPivot keeps its volume inside 2%% across the whole pop" % key,
		"worst drift %.4f, peak scale %.3f" % [worst, peak])

	fighter.state = BaseFighter.State.IDLE
	for i in 400:
		model._apply_squash_pop(1.0 / 60.0, fighter.state)
		if model.squash_pivot.scale == Vector3.ONE:
			break
	# End-to-end prop isolation: measure each attachment's WORLD basis at rest, then pop the
	# body to its peak and smear the arm, and require the isolation to put every attachment
	# back exactly where it was — same size, same shear, same orientation.
	model._squash_scale = Vector3.ONE
	model.squash_pivot.scale = Vector3.ONE
	model._isolate_props()
	var bases: Array[Vector3] = []
	for i in model.hand_props.size():
		bases.append(model.prop_world_scale(i))
	model._squash_scale = AnimationFeel.SQUASH_STRETCH
	model.squash_pivot.scale = model._squash_scale
	model._isolate_props()
	var worst_prop := 0.0
	for i in model.hand_props.size():
		var live := model.prop_world_scale(i)
		var base := bases[i]
		for axis in 3:
			var a := live[axis]
			var b := base[axis]
			if absf(b) < 0.000001:
				continue
			worst_prop = maxf(worst_prop, absf(a / b - 1.0))
	if model.hand_props.is_empty():
		_check(true, "%s has no hand prop to warp" % key)
	else:
		_check(worst_prop <= 0.01,
			"%s BoneAttachment3D hand props keep their world scale" % key,
			"worst %.3f%% off bind, under %.2fx pop" % [worst_prop * 100.0,
				AnimationFeel.SQUASH_STRETCH.y])
	model._squash_scale = Vector3.ONE
	model.squash_pivot.scale = Vector3.ONE
	model._isolate_props()


## Nothing may be planted on the sand while the body is in the air.
func _audit_airborne_pin(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	var airborne := {
		"JUMP": BaseFighter.State.JUMP,
		"THROWN": BaseFighter.State.THROWN,
		"KNOCKDOWN": BaseFighter.State.KNOCKDOWN,
		"KO": BaseFighter.State.KO,
	}
	fighter._attack_id = &""
	fighter._attack = {}
	fighter.velocity = Vector2.ZERO
	var unpinned := 0
	for label in airborne:
		fighter.state = airborne[label]
		model._animate_pose(1.0 / 60.0)
		var before := model._pivot.position.y
		model._pin_feet_to_ground()
		if absf(model._pivot.position.y - before) < 0.000001:
			unpinned += 1
	_check(unpinned == airborne.size(),
		"%s foot pinning is disabled in %d airborne states" % [key, airborne.size()],
		"%d of %d held their pose" % [unpinned, airborne.size()])
	# A HITSTUN that is still travelling upward is a launch, not a stance.
	fighter.state = BaseFighter.State.HITSTUN
	fighter.velocity = Vector2(0.0, -260.0)
	model._animate_pose(1.0 / 60.0)
	var rising := model._pivot.position.y
	model._pin_feet_to_ground()
	_check(absf(model._pivot.position.y - rising) < 0.000001,
		"%s a launched hitstun is not pinned back down" % key)
	fighter.velocity = Vector2.ZERO
	fighter.state = BaseFighter.State.IDLE


## The three mentor extras, each behind its own export var, plus the shared F4 switch.
func _audit_extras(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	# --- Beat accent ------------------------------------------------------------------
	var plain := AnimationFeel.overshoot_lean(AnimationFeel.WHIP_FRAME)
	var accent := AnimationFeel.overshoot_lean_accented(AnimationFeel.WHIP_FRAME, true)
	_check(accent > plain and accent <= deg_to_rad(AnimationFeel.BEAT_OVERSHOOT_MAX_DEG) + 0.0001,
		"%s an on-beat strike keeps more overshoot, clamped" % key,
		"%.2f -> %.2f deg" % [rad_to_deg(plain), rad_to_deg(accent)])
	_check(is_equal_approx(AnimationFeel.overshoot_lean_accented(AnimationFeel.WHIP_FRAME, false),
		plain), "%s an off-beat strike is unchanged" % key)
	_check(AnimationFeel.settle_frames_for(true) > AnimationFeel.settle_frames_for(false),
		"%s an on-beat strike holds one settle frame longer" % key,
		"%d vs %d frames" % [AnimationFeel.settle_frames_for(true),
			AnimationFeel.settle_frames_for(false)])
	var clip := String(model.clips.get(&"light", ""))
	if clip != "":
		fighter.state = BaseFighter.State.ATTACK_ACTIVE
		fighter._attack = fighter.attacks[&"jab"]
		fighter._attack_id = &"jab"
		fighter.state_frame = 1
		fighter._input_beat = {"on_beat": true, "available": true}
		model.beat_accent = true
		var accented_t := model._attack_clip_progress(BaseFighter.State.ATTACK_ACTIVE, clip)
		_check(model.last_beat_accent, "%s the accent follows the input's own judgement" % key)
		model.beat_accent = false
		var plain_t := model._attack_clip_progress(BaseFighter.State.ATTACK_ACTIVE, clip)
		_check(not model.last_beat_accent and accented_t >= plain_t,
			"%s the beat_accent export gates the accent" % key,
			"%.4f vs %.4f" % [accented_t, plain_t])
		model.beat_accent = true
		fighter._input_beat = {}

	# --- Moving-hold idle --------------------------------------------------------------
	fighter.state = BaseFighter.State.IDLE
	fighter._attack_id = &""
	fighter._attack = {}
	model.moving_hold_idle = true
	fighter._celebrate_ticks = 0
	# Kill every transient from the attack measurements above, or the decaying lunge would be
	# mistaken for the waiting sway.
	model._lunge = 0.0
	model._lean = 0.0
	model._squash = 1.0
	model._fall = 0.0
	model._pitch = 0.0
	model._twist = 0.0
	model._lift = 0.0
	model._spin = 0.0
	model._spin_angle = 0.0
	model._clock = 0.4
	model.beat_phase = 0.0
	model._animate_pose(1.0 / 60.0)
	var pose_a := model._pivot.position
	var roll_a := model._pivot.rotation.z
	model._clock = 6.0
	model.beat_phase = 0.5
	model._animate_pose(1.0 / 60.0)
	var pose_b := model._pivot.position
	_check(absf(pose_a.x - pose_b.x) > 0.0005,
		"%s a waiting stance shifts its weight" % key,
		"x %.4f -> %.4f" % [pose_a.x, pose_b.x])
	_check(absf(pose_a.y - pose_b.y) > 0.0005,
		"%s a waiting stance breathes and dips on the beat" % key,
		"y %.4f -> %.4f" % [pose_a.y, pose_b.y])
	_check(absf(roll_a - model._pivot.rotation.z) >= 0.0, "%s hip roll follows the shift" % key)
	# Off: the stance is the plain stance again, measured from the same clean transients.
	model.moving_hold_idle = false
	model._lunge = 0.0
	model._lean = 0.0
	model._squash = 1.0
	model._fall = 0.0
	model._pitch = 0.0
	model._twist = 0.0
	model._lift = 0.0
	model._clock = 0.4
	model._animate_pose(1.0 / 60.0)
	var flat_a := model._pivot.position
	model._clock = 6.0
	model._animate_pose(1.0 / 60.0)
	_check(absf(flat_a.x - model._pivot.position.x) < 0.0001,
		"%s the moving_hold_idle export gates the sway" % key,
		"x %.4f vs %.4f" % [flat_a.x, model._pivot.position.x])
	model.moving_hold_idle = true

	# --- Variable stepping --------------------------------------------------------------
	_check(AnimationFeel.hold_every(true, true) == AnimationFeel.HOLD_EVERY
		and AnimationFeel.hold_every(false, true) == 1
		and AnimationFeel.hold_every(true, false) == 1,
		"%s hold_every() only slows a held impact while the export is on" % key,
		"hold %d / whip %d" % [AnimationFeel.hold_every(true, true),
			AnimationFeel.hold_every(false, true)])
	_check(AnimationFeel.idle_step_count(1.0, model.step_fps_idle)
		< AnimationFeel.step_count(1.0, model.step_fps),
		"%s idle/walk step on a slower lattice than an attack" % key,
		"%d vs %d poses per second" % [AnimationFeel.idle_step_count(1.0, model.step_fps_idle),
			AnimationFeel.step_count(1.0, model.step_fps)])
	_check(model.step_fps_idle < 16.0,
		"%s the idle lattice sits deliberately below the 16–20 attack band" % key,
		"%.1f fps" % model.step_fps_idle)
	# The hold window itself: the extended silhouette counts as held from the whip through the
	# first frames of recovery, and variable stepping is the only thing that lengthens it.
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	var held_active := 0
	for frame in range(1, 7):
		fighter.state_frame = frame
		if model._is_holding_impact(BaseFighter.State.ATTACK_ACTIVE):
			held_active += 1
	fighter.state = BaseFighter.State.ATTACK_RECOVERY
	var held_recovery := 0
	for frame in range(1, 7):
		fighter.state_frame = frame
		if model._is_holding_impact(BaseFighter.State.ATTACK_RECOVERY):
			held_recovery += 1
	_check(held_active >= 3 and held_recovery == AnimationFeel.RECOVERY_HOLD_FRAMES,
		"%s the hold covers the whip and the first recovery frames" % key,
		"%d active + %d recovery frames" % [held_active, held_recovery])
	_check(AnimationFeel.hold_every(true, false) == 1,
		"%s the variable_stepping export is what turns the hold on" % key)

	# --- F4 shared switch ---------------------------------------------------------------
	model.set_stepped_arcade(false)
	var off_ok := not model.stepped_arcade and not AnimationFeel.stepped_arcade
	model.set_stepped_arcade(true)
	_check(off_ok and model.stepped_arcade and AnimationFeel.stepped_arcade,
		"%s the shared F4 switch drives this body and the static default" % key)


## Drive the first two frames of recovery, where the extended silhouette is still held and the
## recovery ramp is guaranteed to move the grid. Returns the clip time the driver asks for.
func _recovery_pair(model: FighterModel3D, fighter: BaseFighter, variable: bool) -> Array[float]:
	fighter._attack = fighter.attacks[&"strong"]
	fighter._attack_id = &"strong"
	model.stepped_arcade = true
	model.variable_stepping = variable
	model._play_role(&"strong")
	model._hold_index = -1
	model._hold_ticks = 0
	fighter.state = BaseFighter.State.ATTACK_RECOVERY
	fighter._hitstop_frames = 0
	var out: Array[float] = []
	for frame in range(1, 3):
		fighter.state_frame = frame
		model._drive_clip_time()
		out.append(model.animation.current_animation_position)
	fighter.state_frame = 1
	model._hold_index = -1
	model._hold_ticks = 0
	model.variable_stepping = true
	return out


## No prop or character may be a primitive mesh, in code or in the built scene. The scan looks
## for an actual CONSTRUCTION (`BoxMesh.new(`, a `BoxMesh` sub-resource), not for the word: the
## comments that record what was deleted are documentation, not programmer art. Stage structure
## (the sand floor, the barrier, the sky, the light pool) legitimately builds primitives, which
## is why it is not in these lists.
func _audit_no_primitive_meshes() -> void:
	print("\n-- NO PROGRAMMER ART")
	var offenders: Array[String] = []
	for path in CHARACTER_SCRIPTS:
		var text := FileAccess.get_file_as_string(path)
		if text == "":
			continue
		for token in PRIMITIVE_MESHES:
			if text.contains(token + ".new("):
				offenders.append("%s.new( in %s" % [token, path.get_file()])
	for path in CHARACTER_SCENES:
		var text := FileAccess.get_file_as_string(path)
		if text == "":
			continue
		for token in PRIMITIVE_MESHES:
			if text.contains("type=\"%s\"" % token):
				offenders.append("%s sub-resource in %s" % [token, path.get_file()])
	_check(offenders.is_empty(), "no character or prop builds a primitive mesh",
		", ".join(offenders) if not offenders.is_empty() else
		"%d scripts and %d scenes clean" % [CHARACTER_SCRIPTS.size(), CHARACTER_SCENES.size()])


## Steady state. The feel layer must allocate NOTHING per frame: one fighter and its 3D body,
## standing still, driven through 600 simulated frames, may not create a single object or node.
## The live arena is measured too, but only for what this pass owns: the scene graph and the
## resource table must be flat (its standing-object count carries a known background drip of
## about one object per second from the stage/UI subsystems, which is recorded in AGENTS.md and
## is not the animation layer's).
func _audit_allocation() -> void:
	print("\n-- ALLOCATION STEADY STATE (600 frames)")
	var fighter := await _make_fighter(&"feedback")
	fighter.set_physics_process(true)
	var model := FighterModel3D.new()
	root.add_child(model)
	if not model.bind(fighter, &"feedback"):
		_check(false, "the feel layer could not be bound for the allocation run")
		return
	await process_frame
	for i in 30:
		await physics_frame
	var f_objects := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var f_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for i in 570:
		await physics_frame
	var f_objects_after := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var f_nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_check(f_objects_after == f_objects and f_nodes_after == f_nodes,
		"the feel layer allocates nothing over 600 simulated frames",
		"%d -> %d objects, %d -> %d nodes" % [f_objects, f_objects_after, f_nodes, f_nodes_after])
	model.queue_free()
	fighter.queue_free()
	await process_frame

	var scene := load("res://scenes/TestArena.tscn") as PackedScene
	if scene == null:
		_check(false, "the live arena could not be loaded for the allocation run")
		return
	var arena := scene.instantiate()
	root.add_child(arena)
	await process_frame
	# No AI, no local input: nothing new may be created, so any growth is a leak.
	if arena.get("sparring") != null and arena.sparring != null:
		arena.sparring.set_physics_process(false)
	for side in ["p1", "p2"]:
		var f: BaseFighter = arena.get(side)
		if f != null:
			f.use_local_input = false
	await physics_frame
	for i in 60:
		await physics_frame
	var nodes_before := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var res_before := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	for i in 540:
		await physics_frame
	var nodes_after := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var res_after := int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
	_check(nodes_after <= nodes_before,
		"the live arena grows no scene nodes over 600 simulated frames",
		"%d -> %d" % [nodes_before, nodes_after])
	_check(res_after <= res_before,
		"the live arena grows no resources over 600 simulated frames",
		"%d -> %d" % [res_before, res_after])
	# The built yard is a real crowd, a real booth and real fighters: no primitive meshes.
	var primitives := 0
	for holder in ["CrowdController3D", "DJBooth3D"]:
		var node := arena.find_child(holder, true, false)
		if node == null:
			continue
		for child in node.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			if mi.mesh is BoxMesh or mi.mesh is CylinderMesh or mi.mesh is QuadMesh \
					or mi.mesh is PlaneMesh or mi.mesh is SphereMesh or mi.mesh is CapsuleMesh \
					or mi.mesh is PrismMesh:
				primitives += 1
	_check(primitives == 0, "the built crowd and DJ booth contain no primitive meshes",
		"%d found" % primitives)
	arena.queue_free()
	await process_frame


# =========================================================================
# PART 1 commits 2–3 — Zweifuss / Iverson techniques, foreshortening, preset rim
# =========================================================================
## Five techniques from the Zweifuss 3rd Strike archive and the Stefan Iverson Makoto
## breakdown, plus the commit-3 foreshortening and cel-rim work. Every check reads the same
## functions the runtime uses, and every live measurement runs on the real `FighterModel3D`
## bound to the real `BaseFighter` — with the fighter's own physics frozen, so the attack
## phase below is exactly the phase being measured.
func _audit_zweifuss(model: FighterModel3D, fighter: BaseFighter, key: String) -> void:
	print("\n-- %s: ZWEIFUSS / IVERSON LAYER" % key)

	# --- 1. Archetype pose-timing bias, as an exported resource --------------------------
	var bias: PoseTimingBias = model.pose_bias
	_check(bias != null and bias.is_authored(),
		"%s carries an authored pose-timing bias resource" % key,
		bias.label if bias != null else "<null>")
	if bias != null:
		_check(bias.impact_hold >= AnimationFeel.IMPACT_LOCK_MIN
				and bias.impact_hold <= AnimationFeel.IMPACT_LOCK_MAX,
			"%s authored impact hold sits in the 2–3 pose-step contract" % key,
			"%d steps" % bias.impact_hold)
		_check(bias.whip_lead >= 1 and bias.whip_lead <= 2,
			"%s authored a 1–2 step hip lead" % key, "%d steps" % bias.whip_lead)
		_check(bias.anticipation_depth > 0.0
				and bias.anticipation_depth <= AnimationFeel.ANTICIPATION_MAX,
			"%s anticipation travel stays inside the few-cm clamp" % key,
			"%.3f m" % bias.anticipation_depth)
	# The three archetypes are genuinely different, not one bias copied three times.
	var dudley := PoseTimingBias.for_fighter(&"feedback")
	var makoto := PoseTimingBias.for_fighter(&"lickshot")
	var stylist := PoseTimingBias.for_fighter(&"young_selecta")
	_check(makoto.impact_hold > dudley.impact_hold
			and stylist.recovery_dip_deg > dudley.recovery_dip_deg
			and makoto.anticipation_depth > dudley.anticipation_depth,
		"the archetypes differ: the lunge loads deeper and holds longer, the stylist settles deeper",
		"coil %.3f/%.3f m, hold %d/%d steps, settle %.1f/%.1f deg" % [
			makoto.anticipation_depth, dudley.anticipation_depth, makoto.impact_hold,
			dudley.impact_hold, stylist.recovery_dip_deg, dudley.recovery_dip_deg])
	_check(PoseTimingBias.for_fighter(&"feedback") != PoseTimingBias.for_fighter(&"feedback"),
		"each body gets its own bias instance (no shared runtime state)")

	# --- 2. Anticipation built INTO the forward step ------------------------------------
	var depth := bias.anticipation_depth if bias != null else 0.04
	var peak := clampf(depth, 0.0, AnimationFeel.ANTICIPATION_MAX)
	_check(is_zero_approx(AnimationFeel.anticipation_offset(0.0, depth))
			and absf(AnimationFeel.anticipation_offset(1.0, depth) - peak) < 0.0001
			and AnimationFeel.anticipation_offset(0.5, depth) > 0.0,
		"%s the coil loads into the step and peaks on the last startup tick" % key,
		"%.3f m at the peak" % peak)
	_check(is_equal_approx(AnimationFeel.anticipation_offset(1.0, 1.0),
			AnimationFeel.ANTICIPATION_MAX),
		"%s an over-tuned coil is clamped to the few-cm ceiling" % key,
		"%.3f m" % AnimationFeel.ANTICIPATION_MAX)
	fighter._attack_id = &"strong"
	fighter._attack = fighter.attacks[&"strong"]
	fighter.state = BaseFighter.State.ATTACK_STARTUP
	fighter.state_frame = maxi(1, int(fighter._attack.get("startup", 1)) - 1)
	model._play_role(&"strong")
	await process_frame
	await process_frame
	var coil_x: float = model._visual_pivot.position.x
	_check(absf(coil_x) > 0.0015 and absf(coil_x) <= AnimationFeel.ANTICIPATION_MAX + 0.0001,
		"%s the live startup coils forward on the VisualPivot only" % key, "%.3f m" % coil_x)
	_check(is_equal_approx(model.body_modifier.anticipation, absf(coil_x)),
		"%s the modifier reports the same coil the pivot carries" % key,
		"%.3f m" % model.body_modifier.anticipation)
	# The facing pin's own contract: the drawn toes land on ±X. Measured from the toe vector,
	# exactly what `_pin_body_facing()` corrects — a mid-startup hips turn is performance, not
	# facing, so it must not be read as an error here.
	var toe: Vector3 = model.toe_forward_world()
	var toe_target := 0.0 if model.facing_sign >= 0 else PI
	var coil_off := 0.0 if toe == Vector3.ZERO else absf(rad_to_deg(
		wrapf(toe_target - atan2(toe.z, toe.x), -PI, PI)))
	_check(coil_off <= FACING_TOLERANCE_DEG,
		"%s the forward coil keeps the facing pin inside 5°" % key, "%.2f°" % coil_off)
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter.state_frame = 1
	await process_frame
	_check(is_zero_approx(model._visual_pivot.position.x)
			and is_zero_approx(model.body_modifier.anticipation),
		"%s the coil is exactly zero by the first ACTIVE frame" % key,
		"%.5f m" % model._visual_pivot.position.x)

	# --- 3. C → S → reverse-C whip: hips lead the torso and the striking hand ------------
	_check(AnimationFeel.whip_delay(&"hips") == 0
			and AnimationFeel.whip_delay(&"spine1") >= 1 and AnimationFeel.whip_delay(&"spine1") <= 2
			and AnimationFeel.whip_delay(&"spine2") >= 1 and AnimationFeel.whip_delay(&"spine2") <= 2
			and AnimationFeel.whip_delay(&"hand") >= 1 and AnimationFeel.whip_delay(&"hand") <= 2,
		"%s the whip chain lags the hips by 1–2 pose steps" % key,
		"spine1 %d, spine2 %d, hand %d" % [AnimationFeel.whip_delay(&"spine1"),
			AnimationFeel.whip_delay(&"spine2"), AnimationFeel.whip_delay(&"hand")])
	_check(is_equal_approx(AnimationFeel.whip_weight(&"hips", 0), 1.0)
			and is_zero_approx(AnimationFeel.whip_weight(&"spine1", 0))
			and AnimationFeel.whip_weight(&"spine1", AnimationFeel.whip_delay(&"spine1")) > 0.0
			and is_zero_approx(AnimationFeel.whip_weight(&"hand", 1))
			and AnimationFeel.whip_weight(&"hand", AnimationFeel.whip_delay(&"hand")) > 0.0,
		"%s the hips lead, the torso follows, the striking hand follows last" % key)
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter.state_frame = 0
	await process_frame
	var lag_early: float = model.body_modifier.spine_lag
	fighter.state_frame = 3
	await process_frame
	var lag_late: float = model.body_modifier.spine_lag
	_check(lag_early < 0.5 and lag_late >= 0.99,
		"%s the torso arrives behind the hips on the live body" % key,
		"%.2f → %.2f share" % [lag_early, lag_late])

	# --- 4. Frozen impact silhouette -----------------------------------------------------
	var hold := AnimationFeel.impact_lock_steps(bias.impact_hold if bias != null else 2)
	_check(hold >= 2 and hold <= 3,
		"%s the impact silhouette locks for 2–3 pose steps" % key, "%d steps" % hold)
	fighter.state = BaseFighter.State.ATTACK_ACTIVE
	fighter._attack_id = &"strong"
	fighter._attack = fighter.attacks[&"strong"]
	fighter.state_frame = 2
	model._play_role(&"strong")
	await process_frame
	model._hold_index = -1
	model._impact_lock_steps = 0
	model._impact_lock_index = -1
	model._drive_clip_time()
	model._on_strike_resolved(fighter, null, {"damage": 15, "attack_id": &"strong"})
	_check(model.impact_lock_remaining() == hold,
		"%s a landed contact locks the peak-reach silhouette" % key,
		"%d steps" % model.impact_lock_remaining())
	# While the lock is armed the sampled pose stays on the contact cell, even though the
	# combat phase has moved on. Only the clip is held; the additive layer keeps moving.
	var held_seek: float = model.animation.current_animation_position
	fighter.state_frame = 4
	model._drive_clip_time()
	_check(is_equal_approx(model.animation.current_animation_position, held_seek),
		"%s the armed lock holds the contact pose" % key,
		"%.4f s held while the phase advanced" % held_seek)
	# Leaving ACTIVE drops whatever is left, so a lock can never bleed into a walk or a taunt.
	model._on_state_changed(BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.IDLE)
	_check(model.impact_lock_remaining() == 0 and model.impact_lock_index() < 0,
		"%s the lock is cleared when the state leaves ACTIVE" % key)
	var profile: Dictionary = fighter.attacks[&"strong"]
	var baseline: Array = FRAME_BASELINE[key][&"strong"]
	_check(int(profile.get("startup", -1)) == int(baseline[0])
			and int(profile.get("active", -1)) == int(baseline[1])
			and int(profile.get("recovery", -1)) == int(baseline[2]),
		"%s the impact lock leaves STARTUP/ACTIVE/RECOVERY untouched" % key,
		"%d/%d/%d" % [int(profile.get("startup", -1)), int(profile.get("active", -1)),
			int(profile.get("recovery", -1))])

	# --- 5. Non-linear hip dip and overshoot return -------------------------------------
	var dip_deg := bias.recovery_dip_deg if bias != null else AnimationFeel.RECOVERY_DIP_DEG
	_check(is_zero_approx(AnimationFeel.recovery_dip(0.0, dip_deg))
			and is_zero_approx(AnimationFeel.recovery_dip(1.0, dip_deg))
			and AnimationFeel.recovery_dip(0.3, dip_deg) > 0.0,
		"%s the recovery dip starts and ends at neutral" % key)
	var overshoot := AnimationFeel.recovery_dip(0.85, dip_deg)
	_check(overshoot < 0.0,
		"%s the recovery overshoots back past neutral (not a linear return)" % key,
		"%.4f rad at p=0.85" % overshoot)
	fighter.state = BaseFighter.State.ATTACK_RECOVERY
	fighter.state_frame = 1
	await process_frame
	var live_dip: float = model.body_modifier.recovery_dip
	_check(not is_zero_approx(live_dip),
		"%s the live body folds into its recovery" % key, "%.4f rad" % live_dip)
	fighter.state = BaseFighter.State.IDLE
	fighter.state_frame = 0
	await process_frame
	_check(is_zero_approx(model.body_modifier.recovery_dip),
		"%s the dip is gone once the fighter is idle" % key)

	# --- Commit 1 (2026-11-26): the extremities are no longer touched -------------------
	# The 1.08× foreshortening scale, the limb smear and the hand-bone translation are gone.
	# The replacement contract is measured on the real rig below.
	_audit_extremities(model, fighter, key)

	# --- Commit 3: the cel shader carries the preset rim --------------------------------
	var cel_shader := load("res://assets/shaders/toon_cel.gdshader") as Shader
	var uniform_names: Array[String] = []
	if cel_shader != null:
		for uniform in cel_shader.get_shader_uniform_list():
			uniform_names.append(String(uniform["name"]))
	_check("rim_colour" in uniform_names and "rim_strength" in uniform_names,
		"%s the cel shader exposes rim_colour and rim_strength" % key,
		"%d uniforms" % uniform_names.size())
	var saved_rim := model.preset_rim
	var saved_strength := model.preset_rim_strength
	model.set_cel_rim(Color(0.42, 0.90, 1.0, 1.0), 1.30)
	var live_rim := model.cel_rim()
	_check(live_rim.b > live_rim.r and is_equal_approx(model.cel_rim_strength(), 1.30),
		"%s a preset rim reaches the cel material" % key,
		"%s %.2f" % [str(live_rim), model.cel_rim_strength()])
	# Restore whatever the stage had pushed, so the checks after this one see the shipped body.
	model.preset_rim = saved_rim
	model.preset_rim_strength = saved_strength
	model._apply_variant()
