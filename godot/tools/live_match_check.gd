extends SceneTree
## Live-match verification (2026-11-24 playtest, PART 1).
## Run with: godot --headless --path godot --script res://tools/live_match_check.gd
##
## Boots the REAL `TestArena.tscn` — round controller, 3D yard, Mixamo bodies and all — for
## every roster pairing and asserts the three failures the owner reported:
##
##   (a) BOTH fighters render: the 3D proxy is visible, has at least one mesh with at least
##       one surface, and its live skinned-mesh bounds project inside the camera's viewport.
##       Bounds are evaluated from the animated skeleton pose and the mesh skin weights, so a
##       body thrown 76 m into the air (the actual "invisible opponent" cause) cannot pass on
##       a nominal 1.55 m height alone.
##   (b) L!kkle Moore (and both other fighters) stay on the sand through knockdown and get-up:
##       the live skinned lowest point never drops below Y −0.05 m and the body never drifts
##       more than 0.5 m from its own root X.
##   (c) Attack presses are not swallowed: pressing J / K / L / I (and U for the grab) on the
##       real InputMap transitions the fighter out of IDLE into its attack state, including a
##       press thrown while hitstop has the tick frozen.
##   Plus the facing the render shows: the posed body forward must be within 5° of +X for P1
##   and −X for P2, measured from the live skeleton (Foot → ToeBase), not from the pivot.
##
## PART 1 commit 1 adds two more contracts, measured on the same live arena:
##   (d) every attack/guard action answers on the PRESS FRAME (one physics tick with the press
##       already visible), not merely "within a few frames" as the polling check above allows.
##   (e) the presentation contract: all five PropLoader slots stay empty and draw no
##       procedural stand-in, the yard keeps 18–24 spectators drawn from all seven delivered
##       Mixamo crowd models, and Afternoon/Sunset/Night are three distinct rigs that each keep
##       a crisp directional fighter shadow.
##
## Exit code is non-zero when any assertion fails.

const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
const TOLERANCE_DEG := 5.0
const FLOOR_TOLERANCE := -0.05        # metres below world y 0 the body may never go
const DRIFT_LIMIT := 0.5              # metres of horizontal drift allowed while downed
const PX_PER_M := 140.0
const FLOOR_PX := 600.0
const CENTER_PX := 640.0

## Press action -> the state the press must reach.
const PRESSES := [
	["p1_light", "J jab", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_heavy", "K box", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_tump", "L tump", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_upper_box", "I upper box", [BaseFighter.State.ATTACK_STARTUP, BaseFighter.State.ATTACK_ACTIVE, BaseFighter.State.ATTACK_RECOVERY]],
	["p1_grab", "U grab", [BaseFighter.State.GRAB]],
]

var _checks := 0
var _fails := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("\n=== LIVE MATCH CHECK (real TestArena.tscn) ===")
	for a in FIGHTERS:
		for b in FIGHTERS:
			await _check_pair(a, b)
	await _check_knockdowns()
	await _check_camera_framing()
	await _check_camera_stage_clearance()
	await _check_strike_silhouette()
	for a in FIGHTERS:
		await _check_presses(a)
	await _check_press_frame()
	await _check_arcade_vfx()
	await _check_crowd_eruption()
	await _check_arena_integrity()
	print("\n%d checks, %d FAIL%s" % [_checks, _fails, "" if _fails == 0 else "S"])
	print("ALL LIVE MATCH CHECKS PASSED" if _fails == 0 else "LIVE MATCH CHECKS FAILED")
	quit(1 if _fails > 0 else 0)


func _check(ok: bool, label: String, detail: String = "") -> void:
	_checks += 1
	var line := "%s%s" % [label, (" — " + detail) if detail != "" else ""]
	if not ok:
		_fails += 1
		print("FAIL  %s" % line)
	else:
		print("PASS  %s" % line)


func _spawn(p1_key: StringName, p2_key: StringName, rounds_enabled: bool = false):
	var setup = root.get_node_or_null("MatchSetup")
	setup.commit_match(p1_key, p2_key)
	setup.ai_mode = 0
	var packed := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := packed.instantiate()
	var rounds := arena.get_node_or_null("RoundController")
	if rounds != null and not rounds_enabled:
		rounds.enabled = false
	root.add_child(arena)
	await process_frame
	await physics_frame
	# Settle: the 3D layer builds in _ready and the animation player needs a frame to pose.
	for i in 6:
		await physics_frame
	return arena


func _free(arena) -> void:
	arena.queue_free()
	await process_frame
	await process_frame


func _check_pair(a: StringName, b: StringName) -> void:
	var arena = await _spawn(a, b)
	var arena3d = arena.get("arena3d")
	var tag := "%s vs %s" % [a, b]
	print("\n-- %s" % tag)
	if arena3d == null:
		_check(false, "%s: no Arena3D layer" % tag)
		await _free(arena)
		return
	var cam: Camera3D = arena3d.camera
	var rect := root.get_visible_rect()
	for side in ["p1", "p2"]:
		var fighter: BaseFighter = arena.p1 if side == "p1" else arena.p2
		var model: Node3D = arena3d.models.get(side)
		if model == null:
			_check(false, "%s: %s has no 3D model" % [tag, side.to_upper()])
			continue
		var meshes := 0
		var surfaces := 0
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			if mi == null or mi.mesh == null:
				continue
			meshes += 1
			surfaces += mi.mesh.get_surface_count()
		_check(model.visible, "%s: %s model is visible" % [tag, side.to_upper()])
		_check(meshes > 0 and surfaces > 0,
			"%s: %s has real geometry (%d mesh, %d surface)" % [tag, side.to_upper(), meshes, surfaces])
		var bounds := _skinned_bounds(model)
		var low: Vector3 = bounds[0]
		var high: Vector3 = bounds[1]
		var low_screen := cam.unproject_position(low)
		var high_screen := cam.unproject_position(high)
		var in_frustum := cam.is_position_in_frustum(low) and cam.is_position_in_frustum(high)
		var on_screen := _rect_overlap(low_screen, high_screen, rect)
		_check(in_frustum and on_screen,
			"%s: %s renders inside the camera view (frustum=%s screen=%s)" %
			[tag, side.to_upper(), str(in_frustum), str(on_screen)])
		_check(low.y >= FLOOR_TOLERANCE,
			"%s: %s stands on the sand (lowest drawn y %+.3f)" % [tag, side.to_upper(), low.y])
		# The pivot must carry exactly the facing, and the playing take must not add a turn of
		# its own — together that is the direction the body is drawn facing.
		var offset := deg_to_rad(float(model.get("model_forward_yaw_offset_deg")))
		var expected := offset + (0.0 if side == "p1" else PI)
		var want_dir := Vector3(cos(offset), 0.0, sin(offset)).rotated(Vector3.UP, expected)
		var pivot_err := absf(rad_to_deg(wrapf(
			deg_to_rad(float(model.call("facing_yaw_deg"))) - expected, -PI, PI)))
		var fwd := _rendered_forward(model)
		var err := rad_to_deg(acos(clampf(absf(fwd.x), 0.0, 1.0)))
		var wants := 1.0 if side == "p1" else -1.0
		_check(pivot_err <= 0.5 and err <= TOLERANCE_DEG and signf(fwd.x) == wants,
			"%s: %s faces %s (pivot off by %.2f deg, rendered forward (%+.2f, %+.2f), %4.1f deg off ±X)" %
			[tag, side.to_upper(), "right" if wants > 0 else "left", pivot_err, fwd.x, fwd.z, err])
	await _free(arena)


## Press responsiveness, on the real InputMap and the real arena.
func _check_presses(a: StringName) -> void:
	var arena = await _spawn(a, &"lickshot", true)
	var tag := "P1 %s" % a
	var fighter: BaseFighter = arena.p1
	for entry in PRESSES:
		await _settle(fighter)
		var done := await _press(entry[0], entry[2], fighter)
		var state := String(BaseFighter.State.keys()[fighter.state])
		_check(done, "%s: %s starts an attack on press (state %s)" % [tag, entry[1], state])
		await _settle(fighter)
	# Block / guard is a HELD action, not a latched press.
	await _settle(fighter)
	Input.action_press("p1_guard")
	var guarded := false
	for i in 8:
		await physics_frame
		if fighter.guarding:
			guarded = true
			break
	Input.action_release("p1_guard")
	_check(guarded, "%s: holding S raises the guard" % tag)
	await _settle(fighter)
	# A press thrown while hitstop has the tick frozen must still fire.
	await _settle(fighter)
	fighter._hitstop_frames = 6
	var frozen := await _press("p1_light", PRESSES[0][2], fighter, 14)
	_check(frozen, "%s: a jab pressed during hitstop still fires (%s)" %
		[tag, String(BaseFighter.State.keys()[fighter.state])])
	fighter._hitstop_frames = 0
	await _free(arena)


## Press-frame responsiveness (PART 1 commit 1). `_check_presses` above polls for up to 8 ticks,
## so a one- or two-tick lag would still pass it. Here the press goes down, the fighter is given
## exactly ONE physics tick in which the press is already visible, and the state must have
## changed by the end of that same tick — the buttons answer on the press frame.
func _check_press_frame() -> void:
	for key in FIGHTERS:
		var arena = await _spawn(key, &"lickshot", true)
		var fighter: BaseFighter = arena.p1
		for entry in PRESSES:
			await _settle(fighter)
			var before: int = fighter.state
			Input.action_press(entry[0])
			# Frame A begins with the press already down; frame B begins once frame A (and its
			# single `_physics_process`) has finished. No second chance is given.
			await physics_frame
			await physics_frame
			Input.action_release(entry[0])
			var got: int = fighter.state
			_check(got in entry[2],
				"%s: %s answers on the press frame (state %s)" % [key, entry[1],
					String(BaseFighter.State.keys()[got])])
			_check(before == BaseFighter.State.IDLE or got in entry[2],
				"%s: %s was pressed from a settled stance" % [key, entry[1]])
			await _settle(fighter)
		# Guard is held, not latched: it must be up on the tick after the press as well.
		Input.action_press("p1_guard")
		await physics_frame
		await physics_frame
		var up: bool = fighter.guarding
		Input.action_release("p1_guard")
		_check(up, "%s: S raises the guard on the press frame" % key)
		await _settle(fighter)
		await _free(arena)


## Commit 4: the arcade FX layer with no sheets delivered. Nothing is drawn, each missing sheet
## is reported exactly once, and 600 presented frames add no node to the arena.
func _check_arcade_vfx() -> void:
	print("\n-- ARCADE VFX: no sheets delivered, 600 frames")
	var arena = await _spawn(&"feedback", &"lickshot")
	var vfx: ArcadeVFX2D = arena.get("arcade_vfx")
	var layer: CanvasLayer = arena.get("vfx_layer")
	_check(vfx != null and layer != null and vfx.get_parent() == layer,
		"the arcade FX layer sits on its own CanvasLayer")
	if vfx == null:
		await _free(arena)
		return
	var expected := {
		&"hit_spark": "hit_spark_sheet.png",
		&"bass_shockwave": "bass_shockwave_sheet.png",
		&"clash_callout": "clash_callout_sheet.png",
		&"ko_callout": "ko_callout_sheet.png",
	}
	var paths_ok := true
	var missing := 0
	for kind in expected:
		var want := "res://assets/sprites/arcade_fx/" + String(expected[kind])
		if vfx.sheet_path(kind) != want:
			paths_ok = false
		if not vfx.has_sheet(kind):
			missing += 1
	_check(paths_ok, "all four sheet paths follow assets/sprites/arcade_fx/<name>_sheet.png")
	_check(missing == 4, "no arcade FX sheet is delivered in this build", "%d missing" % missing)
	_check(vfx.warning_count() == 4,
		"exactly one warning per missing sheet", "%d warnings" % vfx.warning_count())
	var each_once := true
	for kind in expected:
		if vfx.warned(kind) == vfx.has_sheet(kind):
			each_once = false
	_check(each_once, "each sheet is reported independently, and only once")
	_check(vfx.sprite_count() == 0,
		"no sprite pool exists without a sheet", "%d sprites" % vfx.sprite_count())
	var before := arena.find_children("*", "Node", true, false).size()
	# Poke every trigger: a missing sheet must stay a no-op, never a node factory.
	for i in 40:
		vfx.play_at_world(&"hit_spark", Vector3.ZERO)
		vfx.play_at_world(&"bass_shockwave", Vector3.ZERO)
		vfx.play_at_world(&"clash_callout", Vector3.ZERO)
		vfx.play_at_world(&"ko_callout", Vector3.ZERO)
	_check(vfx.playing_count() == 0, "nothing plays when no sheet exists")
	# The layer holds exactly one node — `ArcadeVFX2D` itself — and that node holds no sprite.
	var layer_sprites: int = layer.find_children("*", "Sprite2D", true, false).size()
	_check(layer_sprites == 0 and vfx.get_child_count() == 0,
		"the FX layer creates no sprite without a sheet",
		"%d sprites, %d children" % [layer_sprites, vfx.get_child_count()])
	for i in 600:
		await process_frame
	var after := arena.find_children("*", "Node", true, false).size()
	# Never grows. A single expired transient (a spark or note trail the fight itself created)
	# can leave the count one lower; only a list of new nodes is a leak.
	_check(after <= before, "600 frames add no node to the arena", "%d → %d" % [before, after])
	_check(vfx.warning_count() == 4,
		"600 frames add no further warning", "%d" % vfx.warning_count())
	_check(vfx.playing_count() == 0, "still nothing playing after 600 frames")
	await _free(arena)


## Commit 5: the sound-clash eruption. It must fire on the owned cues, scale with the hype
## readout without writing it, ripple by row tier, stay bounded, add no light, and leave the
## crowd's node count unchanged across a full eruption.
func _check_crowd_eruption() -> void:
	print("\n-- CROWD ERUPTION: cues, hype scale, row wave, bounds, 300 frames")
	var arena = await _spawn(&"feedback", &"lickshot")
	var arena3d = arena.get("arena3d")
	if arena3d == null or arena3d.crowd3d == null:
		_check(false, "no crowd for the eruption audit")
		await _free(arena)
		return
	var crowd: CrowdController3D = arena3d.crowd3d
	_check(crowd.member_count() == 22,
		"the eruption covers the full crowd", "%d rigs" % crowd.member_count())
	_check(crowd.row_delay(0) < crowd.row_delay(1) and crowd.row_delay(1) < crowd.row_delay(2),
		"the wave is ordered ringside → mid → back",
		"%.2f / %.2f / %.2f s" % [crowd.row_delay(0), crowd.row_delay(1), crowd.row_delay(2)])
	var lights_before: int = arena3d.light_count()
	var spots_before: int = arena3d.stage_spot_count()
	var crowd_nodes: int = crowd.node_count()
	# Energy is the hype reading: a big impact still erupts at zero hype (the wave fires, the
	# jump is zero), 50 hype is half, 100 hype is full and never more than full.
	arena.p1.hype = 0
	arena3d.notify_combat_event(&"heavy_hit", 0)
	_check(crowd.eruption_active() and is_zero_approx(crowd.eruption_energy()),
		"a big impact erupts even with empty hype meters",
		"energy %.2f" % crowd.eruption_energy())
	arena.p1.hype = int(BaseFighter.HYPE_MAX / 2)
	arena3d.notify_combat_event(&"hype", -1)
	_check(absf(crowd.eruption_energy() - 0.5) < 0.01,
		"the eruption energy follows the hype readout", "%.2f at half hype" % crowd.eruption_energy())
	arena.p1.hype = BaseFighter.HYPE_MAX
	arena3d.notify_combat_event(&"ko", 0)
	_check(absf(crowd.eruption_energy() - 1.0) < 0.01,
		"full hype is full energy and never past it", "%.2f" % crowd.eruption_energy())
	_check(arena3d.light_pump() >= 0.0 and arena3d.light_pump() <= 1.0,
		"the light pump stays inside 0–1", "%.2f" % arena3d.light_pump())
	_check(arena3d.light_count() == lights_before and arena3d.stage_spot_count() == spots_before,
		"the eruption adds no light and keeps the stage spots",
		"%d lights, %d spots" % [arena3d.light_count(), arena3d.stage_spot_count()])
	# Row wave, measured on the crowd's own clock so the arena cannot interleave a tick.
	# 0.12 s clears the ringside tier's own delay (row 0 + lateral stagger + jitter, worst ≈
	# 0.15 s at the bank's far end) while the back tier is still at 0.22 s and up.
	crowd.tick(0.12)
	_check(crowd.row_reacting(0) > 0 and crowd.row_reacting(2) == 0,
		"the ringside tier answers before the back tier",
		"row0 %d, row2 %d" % [crowd.row_reacting(0), crowd.row_reacting(2)])
	crowd.tick(0.45)
	var joined: int = crowd.row_reacting(0) + crowd.row_reacting(1) + crowd.row_reacting(2)
	_check(joined == 22, "all 22 spectators join the eruption", "%d of 22" % joined)
	# Settling, measured on the crowd's own clock and immediately, because the live match
	# keeps firing its own eruption cues as the frames run.
	crowd.erupt(1.0)
	var full_energy := crowd.eruption_energy()
	crowd.tick(crowd.ERUPT_PEAK_SECONDS + 0.6)
	_check(crowd.eruption_energy() < full_energy - 0.2 and crowd.eruption_energy() >= 0.0,
		"the eruption decays after its peak",
		"%.2f → %.2f" % [full_energy, crowd.eruption_energy()])
	var peak_lift := 0.0
	for i in 90:
		await process_frame
		peak_lift = maxf(peak_lift, crowd.max_lift())
	_check(peak_lift > 0.02 and peak_lift < 0.30,
		"the beat-locked jump is visible and bounded", "%.3f m" % peak_lift)
	for i in 240:
		await process_frame
	_check(crowd.node_count() == crowd_nodes,
		"300 frames of eruption add no crowd node", "%d → %d" % [crowd_nodes, crowd.node_count()])
	_check(crowd.eruption_energy() >= 0.0 and crowd.eruption_energy() <= 1.0,
		"the eruption energy stays bounded through a whole settle",
		"energy %.3f" % crowd.eruption_energy())
	await _free(arena)


## The live arena's non-combat presentation contract: none of the five prop slots may draw a
## procedural stand-in, the yard keeps all seven delivered crowd models, and the three light
## phases are genuinely different rigs with a crisp fighter shadow in every one.
func _check_arena_integrity() -> void:
	var arena = await _spawn(&"feedback", &"lickshot", false)
	var slots := arena.find_children("*", "PropLoader", true, false)
	_check(slots.size() == 5, "the arena carries the five PropLoader slots (%d)" % slots.size())
	var empty := 0
	var stray_meshes := 0
	var paths: Array[String] = []
	for node in slots:
		var slot := node as PropLoader
		if slot.is_empty():
			empty += 1
		paths.append(slot.model_path.get_file())
		for child in slot.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				stray_meshes += 1
	_check(empty == slots.size(), "every prop slot is empty while no .glb is delivered",
		"%d of %d" % [empty, slots.size()])
	_check(stray_meshes == 0, "no prop slot draws a procedural stand-in mesh",
		"%d stray meshes" % stray_meshes)
	var wanted := ["jamaican_speaker.glb", "rasta_speaker.glb", "dj_booth.glb"]
	var stage_slots := 0
	for file in wanted:
		if paths.has(file):
			stage_slots += 1
	_check(stage_slots == 3, "the yard's three environment slots are live",
		", ".join(paths))
	_check(paths.count("wireless_mic.glb") == 2,
		"both adult fighters mount a wireless-mic slot",
		"%d wireless_mic.glb" % paths.count("wireless_mic.glb"))

	var stage3d = arena.get_node_or_null("Arena3D")
	if stage3d != null:
		var crowd = stage3d.crowd3d
		_check(crowd != null and crowd.count() >= 18 and crowd.count() <= 24,
			"the packed yard stands 18–24 spectators",
			"%d" % (crowd.count() if crowd != null else -1))
		if crowd != null:
			var models := {}
			for m in crowd._models:
				if m != null:
					models[m.scene_file_path] = true
			_check(models.size() == 7, "all seven delivered Mixamo crowd models are on stage",
				"%d distinct" % models.size())
		# Three phases, three genuinely different rigs, one crisp shadow throughout.
		var rigs: Array[String] = []
		var crisp := true
		for phase in [0, 1, 2]:
			stage3d.apply_phase(phase, 0.0)
			await physics_frame
			var sun: DirectionalLight3D = stage3d.sun
			if not sun.shadow_enabled or sun.light_angular_distance > 0.001:
				crisp = false
			rigs.append("%.2f/%.2f/%.2f" % [sun.light_energy,
				stage3d.fill.light_energy, stage3d.rim.light_energy])
		_check(crisp, "the key light casts a crisp fighter shadow in every phase")
		var distinct := {}
		for r in rigs:
			distinct[r] = true
		_check(distinct.size() == 3, "Afternoon / Sunset / Night are three distinct light rigs",
			", ".join(rigs))
		stage3d.apply_phase(0, 0.0)
	await _free(arena)
	# L!kkle Moore is the only fighter who asks for the mic stand, so his slot only exists in a
	# match he is in. Checked in its own arena rather than inferred.
	var moore = await _spawn(&"young_selecta", &"feedback", false)
	var moore_paths: Array[String] = []
	var moore_empty := 0
	var moore_stray := 0
	for node in moore.find_children("*", "PropLoader", true, false):
		var slot := node as PropLoader
		moore_paths.append(slot.model_path.get_file())
		if slot.is_empty():
			moore_empty += 1
		for child in slot.find_children("*", "MeshInstance3D", true, false):
			var mi := child as MeshInstance3D
			if mi != null and mi.mesh != null:
				moore_stray += 1
	_check(moore_paths.has("mic_stand.glb"),
		"L!kkle Moore's mic-stand slot is present and empty",
		", ".join(moore_paths))
	_check(moore_empty == moore_paths.size() and moore_stray == 0,
		"his mic stand and dictionary draw nothing without a .glb")
	await _free(moore)


## Wait for a controllable, grounded, idle fighter without forcing state by hand.
func _settle(fighter: BaseFighter, limit: int = 120) -> void:
	fighter.input_locked = false
	var guard := 0
	while guard < limit:
		guard += 1
		if fighter.state == BaseFighter.State.IDLE and fighter.is_on_floor() \
				and fighter._hitstop_frames == 0:
			fighter.velocity = Vector2.ZERO
			await physics_frame
			if fighter.state == BaseFighter.State.IDLE and fighter.is_on_floor():
				return
		await physics_frame


## Press one action and poll a few ticks for the expected state.
func _press(action: String, wanted: Array, fighter: BaseFighter, limit: int = 8) -> bool:
	if not InputMap.has_action(action):
		return false
	Input.action_press(action)
	var hit := false
	var guard := 0
	while guard < limit:
		guard += 1
		Input.action_release(action)
		await physics_frame
		if fighter.state in wanted:
			hit = true
			break
	Input.action_release(action)
	return hit


## Knockdown / get-up floor and drift audit for every fighter, as P2 the CPU cannot interrupt.
func _check_knockdowns() -> void:
	print("\n-- KNOCKDOWN / GET-UP FLOOR + DRIFT")
	for key in FIGHTERS:
		var arena = await _spawn(&"feedback", key)
		var arena3d = arena.get("arena3d")
		var fighter: BaseFighter = arena.p2
		var model: Node3D = arena3d.models.get("p2") if arena3d != null else null
		if model == null:
			_check(false, "%s: no 3D model for the knockdown audit" % key)
			await _free(arena)
			continue
		var root_x: float = fighter.global_position.x
		var lowest := INF
		var body_drift := 0.0
		var anchor_gap := 0.0
		fighter.input_locked = false
		var knocked := fighter.change_state(BaseFighter.State.KNOCKDOWN)
		# 36 fall ticks + the get-up, plus slack.
		for tick in 200:
			await physics_frame
			lowest = minf(lowest, _skinned_bounds(model)[0].y)
			# The body itself must not teleport, and the render must stay anchored to the body:
			# the pelvis is expected to travel ~a body length away when the fighter topples,
			# so only these two are drift measures.
			body_drift = maxf(body_drift, absf(fighter.global_position.x - root_x))
			anchor_gap = maxf(anchor_gap, absf(model.global_position.x - _world_x(fighter.global_position.x)))
		_check(knocked, "%s: a knockdown was accepted" % key)
		_check(lowest >= FLOOR_TOLERANCE,
			"%s: stays on the sand through knockdown and get-up (lowest %+.3f m)" % [key, lowest])
		_check(body_drift <= DRIFT_LIMIT and anchor_gap <= 0.02,
			"%s: no horizontal teleport while downed (body %.3f m, render anchor off by %.3f m)"
			% [key, body_drift, anchor_gap])
		_check(_no_root_motion_tracks(model),
			"%s: no installed take animates Hips/Root position — every clip plays in place" % key)
		await _free(arena)


## Bug 3 (2026-11-25): the camera may lean a few degrees toward the exchange, but it may
## never crop a fighter. Every pairing is checked at the playable spread with the lean held
## at both extremes; head, hips and both feet have to be inside the frustum and on screen.
func _check_camera_framing() -> void:
	print("\n-- CAMERA: 9 pairings at max spacing, ±4° exchange lean, accent peak")
	var view := _view_size()
	for a in FIGHTERS:
		for b in FIGHTERS:
			var arena = await _spawn(a, b)
			var arena3d = arena.get("arena3d")
			if arena3d == null:
				_check(false, "%s vs %s: no 3D camera for the framing audit" % [a, b])
				await _free(arena)
				continue
			arena.p1.global_position = Vector2(390.0, 600.0)
			arena.p2.global_position = Vector2(890.0, 600.0)
			for i in 45:
				await process_frame
			# PART 1 commit 3: the cinematic accent (K.O. blow / special activation) pulls the
			# lens in and leans it at its peak. Held centred first, then with its own ±2° yaw
			# at each side, so the accent's ANGLE is exercised against the frustum and not just
			# its dolly. Both fighters must stay fully framed in all three. Measured before the
			# exchange-lean cases so each hold starts from the same settled neutral framing.
			var accent_cases := [[0, "centred"], [1, "leaning toward P1"], [-1, "leaning toward P2"]]
			var accent_yaws := {}
			for accent_case in accent_cases:
				arena3d.hold_cinematic_accent(1.0, 8, int(accent_case[0]))
				await process_frame
				await process_frame
				accent_yaws[int(accent_case[0])] = rad_to_deg(arena3d.camera.rotation.y)
				var accent := _framing_ok(arena3d, arena, view)
				_check(bool(accent[0]), "%s vs %s: both fighters fully framed at the accent peak %s %s"
					% [a, b, String(accent_case[1]), String(accent[1])])
			# Proof the framing cases above are not vacuous: the side really reaches the lens,
			# leaning opposite ways by roughly twice the accent's 2° yaw.
			_check(signf(float(accent_yaws[1])) > 0.0 and signf(float(accent_yaws[-1])) < 0.0
					and absf(float(accent_yaws[1]) - float(accent_yaws[-1])) > 3.0,
				"%s vs %s: the accent leans the lens both ways (%+.2f° / %+.2f°)"
					% [a, b, float(accent_yaws[1]), float(accent_yaws[-1])])
			for yaw in [-4.0, 4.0]:
				arena3d.hold_exchange_yaw(yaw, 5)
				await process_frame
				var lean := _framing_ok(arena3d, arena, view)
				_check(bool(lean[0]), "%s vs %s: both fighters fully framed at %+.0f° lean %s"
					% [a, b, yaw, String(lean[1])])
			await _free(arena)


## Head, hips and both feet of both fighters inside the frustum and at least `margin` px on
## screen (4 px for the lean and accent-peak checks, a wider band for the stacked yard case).
## Returns `[ok, detail]`.
func _framing_ok(arena3d, arena, view: Vector2, margin: float = 4.0) -> Array:
	for fighter in [arena.p1, arena.p2]:
		var model = arena3d.model_for(fighter)
		if model == null:
			return [false, "no model"]
		for bone in ["Head", "Hips", "LeftFoot", "RightFoot"]:
			var point := _bone_world(model, bone)
			if not arena3d.camera.is_position_in_frustum(point):
				return [false, "%s frustum (%.2f,%.2f,%.2f)" % [bone, point.x, point.y, point.z]]
			var on_screen: Vector2 = arena3d.camera.unproject_position(point)
			if on_screen.x < margin or on_screen.y < margin \
					or on_screen.x > view.x - margin or on_screen.y > view.y - margin:
				return [false, "%s screen (%.1f,%.1f) of (%.0f,%.0f)"
					% [bone, on_screen.x, on_screen.y, view.x, view.y]]
	return [true, ""]


const YARD_MARGIN_PX := 12.0
## The lens body is a point plus this radius: the camera's near plane sits 0.05 m out and the
## audit should flag a rail or a chest that is merely grazing it, not only a dead centre hit.
const CAMERA_BODY_RADIUS := 0.12
## Everything the lens can carry at once, stacked: the accent's 0.85 dolly and ±2° yaw, the ±4°
## exchange lean, and the hit-stop punch at its 1.6 ceiling. At max spacing this is the tightest
## the frame ever gets, so it is the case where a crop, a clipped backdrop edge or a camera
## inside the crowd would actually show.
func _check_camera_stage_clearance() -> void:
	print("\n-- CAMERA vs YARD: accent + lean + punch at max, 9 pairings, max spacing")
	var view := _view_size()
	for a in FIGHTERS:
		for b in FIGHTERS:
			var arena = await _spawn(a, b)
			var arena3d = arena.get("arena3d")
			if arena3d == null:
				_check(false, "%s vs %s: no 3D camera for the yard clearance audit" % [a, b])
				await _free(arena)
				continue
			arena.p1.global_position = Vector2(390.0, 600.0)
			arena.p2.global_position = Vector2(890.0, 600.0)
			for i in 45:
				await process_frame
			# PART 2 commit 5: the clearance must hold with the crowd at its ERUPTION PEAK, so
			# the yard is erupting before the obstacle boxes are measured and stays erupting
			# (0.9 s peak) across all four stacks.
			if arena3d.crowd3d != null:
				arena3d.crowd3d.erupt(1.0)
				for i in 2:
					await process_frame
				_check(arena3d.crowd3d.eruption_active() and arena3d.crowd3d.max_lift() > 0.0,
					"%s vs %s: the yard clearance runs with the crowd erupting" % [a, b])
			var obstacles: Array = arena3d.camera_obstacles()
			var sky_centre: Vector3 = arena3d.backdrop_centre()
			var sky_half: Vector2 = arena3d.backdrop_half_extent()
			var stacked_angle := 0.0
			var stacked_punch := 0.0
			for yaw in [-4.0, 4.0]:
				for side in [-1, 1]:
					var cam: Camera3D = arena3d.camera
					# Re-pin every frame: the punch and accent springs decay every presented frame,
					# and the case is "all three at their maximum", not "one frame after".
					for step in 2:
						arena3d.hold_camera_pressure(yaw, 1.0, side, AnimationFeel.CAMERA_PUNCH_MAX, 4)
						await process_frame
					stacked_angle = rad_to_deg(cam.rotation.y)
					stacked_punch = float(arena3d.camera_punch)
					var label := "%s vs %s: %+.0f° lean, accent side %+d" % [a, b, yaw, side]
					# (1) The lens body never enters the yard's own furniture.
					var cam_pos: Vector3 = cam.global_position
					var intruder := ""
					for box in obstacles:
						if (box as AABB).grow(CAMERA_BODY_RADIUS).has_point(cam_pos):
							intruder = "inside a %.1f×%.1f×%.1f box at (%.2f, %.2f, %.2f)" % [
								(box as AABB).size.x, (box as AABB).size.y, (box as AABB).size.z,
								cam_pos.x, cam_pos.y, cam_pos.z]
							break
					_check(intruder == "" and cam_pos.y > 0.2,
						"%s: lens body clear of every crowd rig, barrier, prop slot and booth" % label,
						intruder if intruder != "" else "%d boxes, y %.2f" % [obstacles.size(), cam_pos.y])
					# (2) No corner of the frame looks past the yard's backdrop.
					var void_detail := _void_corner(cam, view, sky_centre, sky_half)
					_check(void_detail == "",
						"%s: all four view corners land on the sky backdrop" % label, void_detail)
					# (3) Both fighters fully framed, with margin to spare.
					var framed := _framing_ok(arena3d, arena, view, YARD_MARGIN_PX)
					_check(bool(framed[0]),
						"%s: both fighters framed with %.0f px margin" % [label, YARD_MARGIN_PX],
						String(framed[1]))
			# The stack is real: lean + accent yaw must actually reach the lens ceiling, and the
		# punch must still be pinned there, or the three checks above prove nothing.
			_check(absf(stacked_angle) > 5.0 and stacked_punch > 1.55,
				"%s vs %s: the max stack reaches the lens (%.2f°, punch %.2f)" % [a, b, stacked_angle, stacked_punch])
			await _free(arena)


## Empty when every viewport corner's ray lands inside the sky backdrop rect; otherwise the
## first corner that escapes it — the void the owner would see past the yard.
func _void_corner(cam: Camera3D, view: Vector2, centre: Vector3, half: Vector2) -> String:
	var corners := [Vector2(0.0, 0.0), Vector2(view.x, 0.0),
		Vector2(0.0, view.y), Vector2(view.x, view.y)]
	for corner in corners:
		var origin: Vector3 = cam.project_ray_origin(corner)
		var dir: Vector3 = cam.project_ray_normal(corner)
		if absf(dir.z) < 0.00001:
			return "corner (%.0f,%.0f) runs parallel to the backdrop" % [corner.x, corner.y]
		var t: float = (centre.z - origin.z) / dir.z
		if t <= 0.0:
			return "corner (%.0f,%.0f) never reaches the backdrop" % [corner.x, corner.y]
		var hit: Vector3 = origin + dir * t
		if absf(hit.x - centre.x) > half.x or absf(hit.y - centre.y) > half.y:
			return "corner (%.0f,%.0f) exits the backdrop at (%.1f, %.1f) of ±(%.1f, %.1f)" % [
				corner.x, corner.y, hit.x, hit.y, half.x, half.y]
	return ""


## Bug 3: the strike silhouette. On ACTIVE the camera-side fist must reach further across
## the frame than it does at idle, and the facing pivot must stay inside its 5° band.
func _check_strike_silhouette() -> void:
	print("\n-- STRIKE SILHOUETTE: camera-side fist extent")
	for key in FIGHTERS:
		var arena = await _spawn(key, &"feedback")
		var arena3d = arena.get("arena3d")
		var model = arena3d.models.get("p1") if arena3d != null else null
		if model == null:
			_check(false, "%s: no 3D model for the strike-silhouette audit" % key)
			await _free(arena)
			continue
		for i in 24:
			await process_frame
		var idle_extent := _fist_extent(arena3d, model)
		var p1: BaseFighter = arena.p1
		p1._attack_id = &"jab"
		p1._attack = p1.attacks[&"jab"]
		p1.state = BaseFighter.State.ATTACK_ACTIVE
		p1.state_frame = 2
		for i in 2:
			await process_frame
		var active_extent := _fist_extent(arena3d, model)
		_check(active_extent > idle_extent + 0.002,
			"%s: camera-side fist reaches further on ACTIVE (%.3f → %.3f of frame width)"
			% [key, idle_extent, active_extent])
		# Step 0 (2026-11-25): the drawn toe line, which is the axis `_pin_body_facing()` owns
		# and the only one this assertion ever meant. It used to read `world_forward()`, the
		# mesh axis: that legitimately turns with the take's own pelvis twist during a boosted
		# strike (16.6° on Feedback while the feet stay on ±X), so it reported animation as a
		# facing error and swung between 1.9° and 16.6° with whichever blend frame the sample
		# landed on. The 5° tolerance is untouched.
		var forward: Vector3 = model.toe_forward_world()
		var facing_off := absf(rad_to_deg(atan2(forward.z, forward.x)))
		_check(forward != Vector3.ZERO and facing_off <= 5.0,
			"%s: facing pivot keeps the drawn toes inside 5° through the boosted strike" % key,
			"%.2f°" % facing_off)
		await _free(arena)


## Horizontal screen distance from the pelvis to the striking hand, as a fraction of the
## frame width. Projection only; nothing here reads a hitbox.
func _fist_extent(arena3d, model: Node3D) -> float:
	var cam: Camera3D = arena3d.camera
	var hand := _bone_world(model, "RightHand")
	var hips := _bone_world(model, "Hips")
	var view := _view_size()
	return absf(cam.unproject_position(hand).x - cam.unproject_position(hips).x) / maxf(view.x, 1.0)


func _view_size() -> Vector2:
	# The window object is 64×64 headlessly, but the camera projects through the project's
	# 1280×720 viewport; the audit must measure in that space.
	return root.get_visible_rect().size


func _bone_world(model: Node3D, suffix: String) -> Vector3:
	var skel: Skeleton3D = model.get("skeleton")
	if skel == null:
		return Vector3.ZERO
	var index := _bone(skel, suffix)
	if index < 0:
		return Vector3.ZERO
	return (skel.global_transform * skel.get_bone_global_pose(index)).origin


func _world_x(px: float) -> float:
	return (px - CENTER_PX) / PX_PER_M


## Root motion removal, asserted directly on the clips that are installed: no take may
## animate the position of the root node, the Hips or a Root bone.
func _no_root_motion_tracks(model: Node3D) -> bool:
	var player: AnimationPlayer = model.get("animation")
	if player == null:
		return true
	for lib_name in player.get_animation_library_list():
		var lib := player.get_animation_library(lib_name)
		if lib == null:
			continue
		for anim_name in lib.get_animation_list():
			var anim := lib.get_animation(anim_name)
			if anim == null:
				continue
			for track in anim.get_track_count():
				if anim.track_get_type(track) != Animation.TYPE_POSITION_3D:
					continue
				var path := String(anim.track_get_path(track))
				var bone := path.split(":")[1] if path.contains(":") else ""
				if bone == "" or bone.ends_with("Hips") or bone.ends_with("Root"):
					return false
	return true


func _rect_overlap(low: Vector2, high: Vector2, rect: Rect2) -> bool:
	var left := minf(low.x, high.x)
	var right := maxf(low.x, high.x)
	var top := minf(low.y, high.y)
	var bottom := maxf(low.y, high.y)
	return right > 0.0 and left < rect.size.x and bottom > 0.0 and top < rect.size.y


## Live skinned-mesh bounds in world space, evaluated from the animated skeleton pose and the
## mesh skin weights. This is what the renderer draws.
func _skinned_bounds(model: Node3D) -> Array:
	var mi := _first_mesh(model)
	var skel: Skeleton3D = model.get("skeleton")
	if mi == null or skel == null or mi.mesh.get_surface_count() == 0:
		return [Vector3.ZERO, Vector3.UP]
	var arrays := mi.mesh.surface_get_arrays(0)
	if arrays.is_empty():
		return [Vector3.ZERO, Vector3.UP]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var vbones = arrays[Mesh.ARRAY_BONES]
	var weights = arrays[Mesh.ARRAY_WEIGHTS]
	var skin: Skin = mi.skin
	var bone_xf: Array[Transform3D] = []
	for i in skel.get_bone_count():
		var xf: Transform3D = skel.global_transform * skel.get_bone_global_pose(i)
		if skin != null and i < skin.get_bind_count():
			xf = xf * skin.get_bind_pose(i)
		bone_xf.append(xf)
	var low := Vector3(INF, INF, INF)
	var high := Vector3(-INF, -INF, -INF)
	var step := maxi(1, int(float(verts.size()) / 4000.0))
	var per := 0
	if vbones != null and weights != null and verts.size() > 0:
		per = int(vbones.size() / verts.size())
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
			p = acc / total if total > 0.0 else mi.global_transform * p
		else:
			p = mi.global_transform * p
		low = Vector3(minf(low.x, p.x), minf(low.y, p.y), minf(low.z, p.z))
		high = Vector3(maxf(high.x, p.x), maxf(high.y, p.y), maxf(high.z, p.z))
		i += step
	return [low, high]


## Forward the body is drawn facing: the authored forward turned by the pivot that shipped,
## then by however far the playing take has turned the pelvis away from its own REST pose.
## The rest reference matters — the two Tripo rigs carry a 30°–40° pelvis bind yaw that their
## skin compensates for, so comparing a raw bone axis to ±X reports a turn that is not there.
func _rendered_forward(model: Node3D) -> Vector3:
	var offset := deg_to_rad(float(model.get("model_forward_yaw_offset_deg")))
	var pivot := deg_to_rad(float(model.call("facing_yaw_deg")))
	var fwd := Vector3(cos(offset), 0.0, sin(offset)).rotated(Vector3.UP, pivot)
	var skel: Skeleton3D = model.get("skeleton")
	if skel != null:
		var hips := _bone(skel, "Hips")
		if hips >= 0:
			var rest := _heading(skel.get_bone_global_rest(hips).basis)
			var pose := _heading(skel.get_bone_global_pose(hips).basis)
			if rest != Vector3.ZERO and pose != Vector3.ZERO:
				var sin_t := rest.z * pose.x - rest.x * pose.z
				var cos_t := rest.x * pose.x + rest.z * pose.z
				fwd = fwd.rotated(Vector3.UP, atan2(sin_t, cos_t))
	fwd.y = 0.0
	return fwd.normalized() if fwd.length() > 0.0001 else Vector3.RIGHT


## A basis' horizontal reference axis, whichever of its two axes still projects.
func _heading(basis: Basis) -> Vector3:
	for axis in [basis.x, basis.z]:
		var flat := Vector3(axis.x, 0.0, axis.z)
		if flat.length() > 0.2:
			return flat.normalized()
	return Vector3.ZERO


func _bone(skel: Skeleton3D, suffix: String) -> int:
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with(suffix):
			return i
	return -1


func _first_mesh(model: Node3D) -> MeshInstance3D:
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi != null and mi.mesh != null:
			return mi
	return null
