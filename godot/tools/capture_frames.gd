extends SceneTree
## Software-GL capture harness (PART A step 1, 2026-11-26).
##
## Run under Xvfb with Mesa llvmpipe:
##   LIBGL_ALWAYS_SOFTWARE=1 godot --display-driver x11 --rendering-driver opengl3 \
##       --path godot --fixed-fps 60 --disable-vsync \
##       --script res://tools/capture_frames.gd -- --only=knock --out=/tmp/caps
##
## Every knockdown / K.O. / hand still is reached by PLAYING A MATCH: P1 through real
## `InputMap` presses, P2 through the shipped sparring controller. No state is forced, so a
## still can only show a pose the game can actually produce.
##
## These stills prove geometry, orientation and material colour. They are software-rendered
## at whatever rate llvmpipe manages: they say NOTHING about GPU performance.
##
## Stills are written outside the repo by default (`/tmp/caps`). The single committed image
## is the contact sheet this tool composes in `--sheet=` mode.

const QAMatch := preload("res://tools/qa_match.gd")

const FIGHTERS: Array[StringName] = [&"feedback", &"lickshot", &"young_selecta"]
const PARTNER: StringName = &"feedback"

var _out := "/tmp/caps"
var _only := "all"
var _fighter := ""
var _slot := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--only="):
			_only = arg.substr(7)
		elif arg.begins_with("--fighter="):
			_fighter = arg.substr(10)
		elif arg.begins_with("--slot="):
			_slot = arg.substr(7)
	DirAccess.make_dir_recursive_absolute(_out)
	print("CAPTURE out=%s only=%s" % [_out, _only])
	_run()


func _run() -> void:
	if _only == "all" or _only == "knock":
		await _capture_knockdowns()
	if _only == "all" or _only == "hands":
		await _capture_hands()
	if _only == "all" or _only == "props":
		await _capture_props()
	if _only == "sheet" or _only == "all":
		_compose_sheet()
	print("CAPTURE DONE out=%s" % _out)
	quit()


# =========================================================================
# (a) Knockdown and K.O., flat phase, every fighter in both slots
# =========================================================================
func _capture_knockdowns() -> void:
	print("\n== KNOCKDOWN / K.O. STILLS (real match) ==")
	for key in FIGHTERS:
		if _fighter != "" and String(key) != _fighter:
			continue
		for as_p2 in [true, false]:
			if _slot != "" and _slot != ("p2" if as_p2 else "p1"):
				continue
			await _one_knockdown(key, as_p2)


## `as_p2` true: the fighter of interest stands in the P2 slot, P1 does the hitting.
## `as_p2` false: it stands in P1 and P2 does the hitting through the SAME real actions
## (mirrored bindings), because the shipped map only binds `p1_*`.
##
## The match is played in two beats: the attacker walks in and throws once (a real grab and
## forward throw, non-lethal), which is the only knockdown the moveset actually produces; the
## victim gets up, and the attacker then lands heavy strikes until the K.O.
func _one_knockdown(key: StringName, as_p2: bool) -> void:
	QAMatch.mirror_actions()
	var slot := "p2" if as_p2 else "p1"
	var prefix := "p1_" if as_p2 else "p2_"
	var arena: Node = null
	if as_p2:
		arena = await QAMatch.boot(self, PARTNER, key, 0)
	else:
		arena = await QAMatch.boot(self, key, PARTNER, 0)
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get(slot) if arena3d != null else null
	var attacker: BaseFighter = arena.p1 if as_p2 else arena.p2
	var defender: BaseFighter = arena.p2 if as_p2 else arena.p1
	if model == null:
		print("CAPTURE FAIL %s/%s: no 3D model" % [key, slot])
		await QAMatch.close(self, arena)
		return

	var kd_tick := -1
	var ko_tick := -1
	var thrown := false
	var kd_shots := [3, 12, 24, 34]
	var ko_shots := [4, 20, 45]
	var captures: Array = []
	var tick := 0
	QAMatch.set_3d_off(self, true)
	while tick < 1500:
		tick += 1
		if tick % 60 == 0:
			print("   tick %d  A=%s@%.0f  D=%s@%.0f  dx=%.0f  hull=%d  thrown=%s"
				% [tick, BaseFighter.State.keys()[attacker.state], attacker.global_position.x,
					BaseFighter.State.keys()[defender.state], defender.global_position.x,
					absf(dx_debug(attacker, defender)), defender.health, str(thrown)])
		var dx: float = defender.global_position.x - attacker.global_position.x
		var action := ""
		if kd_tick < 0 and not thrown:
			# Close the 3.5 m gap the arena spawns at, then grab once.
			if absf(dx) > 104.0:
				action = prefix + ("right" if dx > 0.0 else "left")
			else:
				action = prefix + "grab"
				thrown = true
		elif ko_tick < 0 and (kd_tick < 0 or tick - kd_tick > 55):
			# After the get-up: heavy strikes until the health bar empties.
			if attacker.state == BaseFighter.State.IDLE and absf(dx) > 96.0:
				action = prefix + ("right" if dx > 0.0 else "left")
			elif attacker.state == BaseFighter.State.IDLE:
				action = prefix + "heavy"

		if action != "":
			# Hold across TWO physics frames: `BaseFighter._latch_local_presses()` reads
			# `Input.is_action_just_pressed`, which a press released inside the same idle gap
			# never reaches. One frame of hold is therefore silently dropped.
			Input.action_press(action)
			await physics_frame
			await physics_frame
			Input.action_release(action)
			await physics_frame
		else:
			await physics_frame

		if kd_tick < 0 and defender.state == BaseFighter.State.KNOCKDOWN:
			kd_tick = tick
			print("\n-- %s in %s: KNOCKDOWN at match tick %d (health %d, thrown=%s)"
				% [key, slot, tick, defender.health, str(thrown)])
		if ko_tick < 0 and defender.state == BaseFighter.State.KO:
			ko_tick = tick
			print("-- %s in %s: K.O. at match tick %d (health %d)" % [key, slot, tick, defender.health])

		if kd_tick > 0 and (tick - kd_tick) in kd_shots:
			QAMatch.set_3d_off(self, false)
			await _shot(arena, model, "knock_%s_%s_kd%02d" % [key, slot, tick - kd_tick], captures)
			QAMatch.set_3d_off(self, true)
		if ko_tick > 0 and (tick - ko_tick) in ko_shots:
			QAMatch.set_3d_off(self, false)
			await _shot(arena, model, "knock_%s_%s_ko%02d" % [key, slot, tick - ko_tick], captures)
			QAMatch.set_3d_off(self, true)
		if ko_tick > 0 and tick - ko_tick >= 50:
			break

	QAMatch.set_3d_off(self, false)
	if kd_tick < 0:
		print("CAPTURE FAIL %s/%s: no knockdown in %d ticks" % [key, slot, tick])
	if ko_tick < 0:
		print("CAPTURE FAIL %s/%s: no K.O. in %d ticks" % [key, slot, tick])
	await QAMatch.close(self, arena)


func dx_debug(a: BaseFighter, b: BaseFighter) -> float:
	return b.global_position.x - a.global_position.x


func _shot(arena, model: Node3D, label: String, into: Array) -> void:
	var m := QAMatch.pose_metrics(model)
	var path := "%s/%s.png" % [_out, label]
	var ok: bool = await QAMatch.capture(self, path)
	into.append(label)
	print("%s  ok=%s  up·y=%+.3f  chest n·y=%+.3f  head−hips Δx=%+.3f  head−feet Δy=%+.3f  "
		% [label, str(ok), float(m.get("up_y", 0.0)), float(m.get("chest_ny", 0.0)),
			float(m.get("head_hips_dx", 0.0)), float(m.get("head_feet_dy", 0.0))]
		+ "drawn low y=%+.3f  fall=%.3f  pivot roll=%+.1f°  seat=%+.3f" %
		[float(m.get("drawn_low_y", 0.0)), float(m.get("fall", 0.0)),
			float(m.get("pivot_rz_deg", 0.0)), float(m.get("visual_seat_y", 0.0))])


# =========================================================================
# (b) Feedback's hands during ACTIVE of J and U
# =========================================================================
func _capture_hands() -> void:
	print("\n== HAND STILLS, ACTIVE of J and U (real match) ==")
	var arena = await QAMatch.boot(self, &"feedback", &"lickshot", 0)
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get("p1") if arena3d != null else null
	if model == null:
		print("CAPTURE FAIL hands: no p1 model")
		await QAMatch.close(self, arena)
		return
	for entry in [["p1_light", "jab"], ["p1_upper_box", "upper_box"]]:
		var action := String(entry[0])
		var tag := String(entry[1])
		var fired := false
		for i in 12:
			Input.action_press(action)
			await physics_frame
			Input.action_release(action)
			if arena.p1.state == BaseFighter.State.ATTACK_ACTIVE:
				fired = true
				break
			await physics_frame
		if not fired:
			print("CAPTURE FAIL %s: attack never reached ACTIVE" % tag)
			continue
		var hand_suffix: String = model.call("hand_bone_name")
		var hand := QAMatch.bone_world(model, hand_suffix)
		var px: Vector2 = arena3d.camera.unproject_position(hand) if arena3d.camera != null else Vector2(640, 360)
		var ok_full: bool = await QAMatch.capture(self, "%s/hand_%s_full.png" % [_out, tag])
		var ok_crop: bool = await QAMatch.capture_crop(self, "%s/hand_%s_zoom.png" % [_out, tag],
			px, Vector2i(360, 260), 3)
		print("hand_%s  active=%s  bone=%s  world=(%.3f, %.3f, %.3f)  screen=(%.0f, %.0f)  "
			% [tag, str(arena.p1.state == BaseFighter.State.ATTACK_ACTIVE), hand_suffix,
				hand.x, hand.y, hand.z, px.x, px.y]
			+ "full=%s zoom=%s" % [str(ok_full), str(ok_crop)])
		# Let the swing finish before the next one.
		for i in 40:
			await physics_frame
			if arena.p1.state == BaseFighter.State.IDLE:
				break
	await QAMatch.close(self, arena)


# =========================================================================
# (c) the speaker, (d) the crowd
# =========================================================================
func _capture_props() -> void:
	print("\n== PROP / CROWD STILLS ==")
	var arena = await QAMatch.boot(self, &"feedback", &"lickshot", 0)
	var arena3d = arena.get("arena3d")
	if arena3d == null:
		print("CAPTURE FAIL props: no Arena3D")
		await QAMatch.close(self, arena)
		return

	# The delivered tower in the left PropLoader slot.
	var stack = arena3d.get_node_or_null("SpeakerStackLeft")
	var prop_root: Node3D = null
	if stack != null:
		prop_root = stack.get("model") as Node3D
	if prop_root != null:
		var centre := prop_root.global_position + Vector3(0.0, 1.6, 0.0)
		var saved: Dictionary = QAMatch.look_at_world(arena3d, centre, 3.2, 1.4)
		await process_frame
		var ok: bool = await QAMatch.capture(self, "%s/speaker_full.png" % _out)
		var ok2: bool = await QAMatch.capture_crop(self, "%s/speaker_zoom.png" % _out,
			arena3d.camera.unproject_position(centre), Vector2i(420, 420), 2)
		print("speaker  ok=%s zoom=%s  centre=(%.2f, %.2f, %.2f)"
			% [str(ok), str(ok2), centre.x, centre.y, centre.z])
		QAMatch.restore_camera(arena3d, saved)
		await process_frame
	else:
		print("CAPTURE FAIL speaker: no delivered model in SpeakerStackLeft")

	# The crowd bank: 20 silhouettes in two loyalty banks.
	var crowd: Node3D = arena3d.get_node_or_null("Crowd3D") as Node3D
	if crowd == null:
		crowd = arena3d.get("crowd3d") as Node3D
	if crowd != null:
		var c: Vector3 = crowd.global_position + Vector3(0.0, 1.2, 0.0)
		var saved2: Dictionary = QAMatch.look_at_world(arena3d, c, 7.5, 2.2)
		await process_frame
		var ok3: bool = await QAMatch.capture(self, "%s/crowd_full.png" % _out)
		print("crowd  ok=%s  centre=(%.2f, %.2f, %.2f)" % [str(ok3), c.x, c.y, c.z])
		QAMatch.restore_camera(arena3d, saved2)
		await process_frame

	# One wide still of the live fight, for the sheet's context tile.
	var ok4: bool = await QAMatch.capture(self, "%s/arena_wide.png" % _out)
	print("arena wide  ok=%s" % str(ok4))
	await QAMatch.close(self, arena)


# =========================================================================
# Contact sheet: ONE committed image, kept small
# =========================================================================
const SHEET_TILES := [
	"knock_feedback_p1_kd24", "knock_feedback_p2_ko20", "knock_lickshot_p1_kd24",
	"knock_lickshot_p2_ko20", "knock_young_selecta_p1_kd24", "knock_young_selecta_p2_ko20",
	"hand_upper_box_zoom", "hand_jab_zoom", "speaker_zoom",
	"crowd_full", "arena_wide",
]
const SHEET_COLS := 3
const SHEET_TILE := Vector2i(320, 180)


func _compose_sheet() -> void:
	var tiles: Array[Image] = []
	for label in SHEET_TILES:
		var path := "%s/%s.png" % [_out, String(label)]
		if not FileAccess.file_exists(path):
			continue
		var img := Image.load_from_file(path)
		if img == null or img.is_empty():
			continue
		img.convert(Image.FORMAT_RGB8)
		# Fit the tile inside the cell without stretching the aspect.
		var scale := minf(float(SHEET_TILE.x) / float(img.get_width()),
			float(SHEET_TILE.y) / float(img.get_height()))
		img.resize(maxi(1, int(img.get_width() * scale)), maxi(1, int(img.get_height() * scale)),
			Image.INTERPOLATE_BILINEAR)
		tiles.append(img)
	if tiles.is_empty():
		print("CAPTURE FAIL sheet: no tiles found in %s" % _out)
		return
	var rows := int(ceil(float(tiles.size()) / float(SHEET_COLS)))
	var sheet := Image.create(SHEET_TILE.x * SHEET_COLS, SHEET_TILE.y * rows, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.06, 0.07, 0.09))
	for i in tiles.size():
		var img := tiles[i]
		var col := i % SHEET_COLS
		var row := int(i / SHEET_COLS)
		var origin := Vector2i(col * SHEET_TILE.x, row * SHEET_TILE.y)
		origin += (SHEET_TILE - img.get_size()) / 2
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), origin)
	var out_path := "%s/contact_sheet.png" % _out
	sheet.save_png(out_path)
	print("sheet  %s  %dx%d  tiles=%d" % [out_path, sheet.get_width(), sheet.get_height(), tiles.size()])
