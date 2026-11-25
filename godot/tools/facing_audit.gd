extends SceneTree
## Facing + clip audit (playtest fix 2026-11-24, issue 1 steps 6 and 8).
## Run with: godot --headless --path godot --script res://tools/facing_audit.gd
##
## For every roster fighter, every uploaded Mixamo take and both facings, this measures:
##   * the `VisualPivot` yaw,
##   * the body's world forward (pivot facing composed with the take's own hips yaw),
##   * the hips yaw the take bakes in (the "root/hips rotation" audit of step 6),
##   * the angle between the forward and the nearest ±X axis.
## A take whose body forward leaves the ±5° band fails, so a clip with baked root rotation
## cannot hide behind a correct pivot. Finally it checks all 9 pairings (including the three
## mirror matches) put the two fighters on opposite facings.
## Exit code is non-zero when any check fails.

const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
## The acceptance set from the playtest brief, by roster role.
const ROLES := [&"idle", &"walk", &"crouch_walk", &"light", &"strong", &"tump", &"upper_box",
	&"special", &"block", &"hit", &"stun", &"stumble", &"taunt", &"knockdown", &"getup", &"victory"]
## Samples inside each take: enough to catch a turn that happens mid-clip.
const SAMPLES := 8
const TOLERANCE_DEG := 5.0

var _fails := 0
var _checks := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await _audit_fighters()
	await _audit_pairings()
	await _audit_pairing_probes()
	print("\n%d checks, %d FAIL%s" % [_checks, _fails, "" if _fails == 0 else "S"])
	print("ALL FACING CHECKS PASSED" if _fails == 0 else "FACING CHECKS FAILED")
	quit(1 if _fails > 0 else 0)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("FAIL  %s" % label)


func _make_fighter(key: StringName) -> BaseFighter:
	var scene := load("res://scenes/BaseFighter.tscn") as PackedScene
	var f := scene.instantiate() as BaseFighter
	f.use_local_input = false
	root.add_child(f)
	await process_frame
	f.set_3d_presentation(true)
	f.apply_fighter_profile(key)
	return f


func _audit_fighters() -> void:
	print("=== FACING AUDIT: 3 fighters x every take x both facings ===")
	for key in FIGHTERS:
		var fighter := await _make_fighter(key)
		var model := FighterModel3D.new()
		root.add_child(model)
		if not model.bind(fighter, key):
			print("FAIL  %s: could not bind a 3D model" % key)
			_fails += 1
			continue
		await process_frame
		print("\n-- %s  pivot offset = %+.1f deg  authored forward = (%+.2f, %+.2f)"
			% [key, model.model_forward_yaw_offset_deg,
				model.authored_forward().x, model.authored_forward().z])
		for role in ROLES:
			var clip: String = String(model.clips.get(role, ""))
			if clip == "":
				continue
			var anim := model.animation.get_animation(clip)
			if anim == null:
				_checks += 1
				_fails += 1
				print("FAIL  %s / role %s: no animation named %s" % [key, role, clip])
				continue
			for facing in [1, -1]:
				model.set_facing(facing)
				model.animation.play(clip, 0.0)
				model.animation.advance(0.0)
				var worst := 0.0
				var worst_hips := 0.0
				var worst_at := 0.0
				for s in SAMPLES:
					var t := anim.length * (float(s) / float(SAMPLES))
					model.animation.seek(t, true)
					model.animation.advance(0.0)
					# The game does this every frame in `_process`; the sampler has to do it too
					# or it would measure the raw take instead of the shipped result.
					model._lock_root_yaw()
					model._compensate_clip_yaw()
					var fwd := model.world_forward()
					var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
					if err > worst:
						worst = err
						worst_at = t
					worst_hips = maxf(worst_hips, absf(rad_to_deg(model.hips_yaw_delta())))
				var ok := worst <= TOLERANCE_DEG
				print("   %-11s %-26s facing=%+d  worst off±X=%5.1f deg @%.2fs  hips_yaw=%5.1f deg  %s"
					% [String(role), clip, facing, worst, worst_at, worst_hips, "OK" if ok else "WRONG"])
				_check(ok, "%s / %s / facing %+d left the ±5° band (%.1f deg)" % [key, clip, facing, worst])
		# Pivot invariants: neither the 3D root nor the pose pivot may carry facing.
		_check(is_zero_approx(model.rotation.y), "%s: 3D fighter root was rotated" % key)
		_check(is_zero_approx(model._pivot.rotation.y), "%s: PosePivot carried yaw" % key)
		model.set_facing(-1)
		var neg := model.facing_yaw_deg()
		model.set_facing(1)
		var pos := model.facing_yaw_deg()
		_check(absf(wrapf(absf(neg - pos) - 180.0, -360.0, 360.0)) < 0.01,
			"%s: facing flip is not exactly 180° (%.1f vs %.1f)" % [key, pos, neg])
		model.queue_free()
		fighter.queue_free()
	await process_frame


## Bug 1 (2026-11-25): the RENDERED body must point at the opponent, measured from the rig's
## own world-space bones, in both slots of all nine matchups — idle, after an attack, after a
## hitstop, and after the sides swap. The toe is the trusted live vector; the chest is the
## live shoulder normal; the head is the calibrated neutral head direction. Each probe is
## averaged over six frames so the idle's footwork and head glance cannot make a single
## frame decide the result.
func _audit_pairing_probes() -> void:
	print("\n=== BONE-FACING PROBES: 9 pairings x both slots x 4 moments ===")
	for i in FIGHTERS.size():
		for j in FIGHTERS.size():
			var a := await _make_fighter(FIGHTERS[i])
			var b := await _make_fighter(FIGHTERS[j])
			a.position = Vector2(420, 600)
			b.position = Vector2(860, 600)
			a.duel_opponent = b
			b.duel_opponent = a
			a.state = BaseFighter.State.IDLE
			b.state = BaseFighter.State.IDLE
			a.set_facing(1)
			b.set_facing(-1)
			a._face_opponent()
			b._face_opponent()
			var am := FighterModel3D.new()
			var bm := FighterModel3D.new()
			root.add_child(am)
			root.add_child(bm)
			am.bind(a, FIGHTERS[i])
			bm.bind(b, FIGHTERS[j])
			for n in 20:
				await process_frame
			var tag := "%s vs %s" % [FIGHTERS[i], FIGHTERS[j]]
			await _probe_slot(tag + " idle", a, am)
			await _probe_slot(tag + " idle", b, bm)
			for pair in [[a, am], [b, bm]]:
				var f: BaseFighter = pair[0]
				f._attack_id = &"jab"
				f._attack = f.attacks[&"jab"]
				f.change_state(BaseFighter.State.ATTACK_STARTUP)
			for n in 36:
				await physics_frame
			await _probe_slot(tag + " after attack", a, am)
			await _probe_slot(tag + " after attack", b, bm)
			a._hitstop_frames = 3
			b._hitstop_frames = 3
			for n in 5:
				await physics_frame
			await _probe_slot(tag + " after hitstop", a, am)
			await _probe_slot(tag + " after hitstop", b, bm)
			a.position = Vector2(860, 600)
			b.position = Vector2(420, 600)
			a._face_opponent()
			b._face_opponent()
			for n in 8:
				await process_frame
			await _probe_slot(tag + " after slot swap", a, am)
			await _probe_slot(tag + " after slot swap", b, bm)
			am.queue_free()
			bm.queue_free()
			a.queue_free()
			b.queue_free()
			await process_frame


## Average the three live probes for one fighter, then require each to point at the
## opponent's side inside the ±5° band. `fighter.facing` is the expected sign, so a slot swap
## is checked the same way as the opening stance.
func _probe_slot(tag: String, fighter: BaseFighter, model: FighterModel3D) -> void:
	var toe_sum := Vector3.ZERO
	var chest_sum := Vector3.ZERO
	var head_sum := Vector3.ZERO
	for n in 6:
		await physics_frame
		var p: Dictionary = model.facing_probes()
		toe_sum += p["toe"]
		chest_sum += p["chest"]
		head_sum += p["head"]
	var expected := Vector3(float(fighter.facing), 0.0, 0.0)
	var limit := cos(deg_to_rad(TOLERANCE_DEG))
	for entry in [["toe", toe_sum], ["chest", chest_sum], ["head", head_sum]]:
		var v: Vector3 = entry[1]
		var ok := v.length() > 0.0001 and v.normalized().dot(expected) >= limit
		_checks += 1
		if not ok:
			_fails += 1
			print("FAIL  %s: %s forward (%+.2f, %+.2f) is not within %.0f° of %+dX"
				% [tag, entry[0], v.x, v.z, TOLERANCE_DEG, fighter.facing])


## All 9 pairings, mirror matches included: the two fighters must stand on opposite ±X.
func _audit_pairings() -> void:
	print("\n=== PAIRINGS: 9 fighter combinations ===")
	for i in FIGHTERS.size():
		for j in FIGHTERS.size():
			var a := await _make_fighter(FIGHTERS[i])
			var b := await _make_fighter(FIGHTERS[j])
			a.position = Vector2(420, 600)
			b.position = Vector2(860, 600)
			a.duel_opponent = b
			b.duel_opponent = a
			a.state = BaseFighter.State.IDLE
			b.state = BaseFighter.State.IDLE
			# Spawn facing, then the auto-face rule that runs every tick.
			a.set_facing(1)
			b.set_facing(-1)
			a._face_opponent()
			b._face_opponent()
			var rule_ok := a.facing == 1 and b.facing == -1
			var am := FighterModel3D.new()
			var bm := FighterModel3D.new()
			root.add_child(am)
			root.add_child(bm)
			am.bind(a, FIGHTERS[i])
			bm.bind(b, FIGHTERS[j])
			await process_frame
			am.set_facing(a.facing)
			bm.set_facing(b.facing)
			var af := am.world_forward()
			var bf := bm.world_forward()
			var facing_ok := af.x > 0.99 and bf.x < -0.99
			print("   %-14s vs %-14s  P1=(%+.2f,%+.2f) P2=(%+.2f,%+.2f)  %s"
				% [FIGHTERS[i], FIGHTERS[j], af.x, af.z, bf.x, bf.z,
					"OK" if (rule_ok and facing_ok) else "WRONG"])
			_check(rule_ok and facing_ok,
				"pairing %s vs %s did not face each other" % [FIGHTERS[i], FIGHTERS[j]])
			am.queue_free()
			bm.queue_free()
			a.queue_free()
			b.queue_free()
			await process_frame
