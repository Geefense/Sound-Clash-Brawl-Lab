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
