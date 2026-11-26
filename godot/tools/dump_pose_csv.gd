extends SceneTree
## Per-tick pose dump for the downed body (PART A step 1).
##
##   godot --headless --path godot --script res://tools/dump_pose_csv.gd -- \
##       --fighter=feedback --slot=p2 --out=/tmp/caps/feedback_p2.csv
##
## Plays a real match (walk in, heavy strikes until the K.O.), then writes one row per
## physics tick from the last few standing frames through the whole flat phase: world-space
## hips / head / chest / feet, the drawn skinned bounds BOTH ways (mapped skin-bind indices
## and the raw bone order), and the presentation state that produced them (`_fall`, the pose
## pivot's roll, the downed-seat offset). It exists so a pose argument is settled with a
## table instead of an eyeball.

const QAMatch := preload("res://tools/qa_match.gd")

var _fighter := "feedback"
var _slot := "p2"
var _out := "/tmp/caps/pose.csv"
var _after_ko := 90


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fighter="):
			_fighter = arg.substr(10)
		elif arg.begins_with("--slot="):
			_slot = arg.substr(7)
		elif arg.begins_with("--out="):
			_out = arg.substr(6)
		elif arg.begins_with("--ticks="):
			_after_ko = int(arg.substr(8))
	_run()


func _run() -> void:
	QAMatch.mirror_actions()
	var key := StringName(_fighter)
	var as_p2 := _slot == "p2"
	var prefix := "p1_" if as_p2 else "p2_"
	var arena = await QAMatch.boot(self, &"feedback" if as_p2 else key,
		key if as_p2 else &"feedback", 0)
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get(_slot) if arena3d != null else null
	var attacker: BaseFighter = arena.p1 if as_p2 else arena.p2
	var defender: BaseFighter = arena.p2 if as_p2 else arena.p1
	if model == null:
		print("CSV FAIL: no model for %s/%s" % [_fighter, _slot])
		quit(1)
		return

	var lines: Array[String] = []
	lines.append("tick,state,fall,pivot_rz_deg,visual_yaw_deg,seat_y,hips_x,hips_y,hips_z,"
		+ "head_x,head_y,head_z,spine2_x,spine2_y,spine2_z,footl_x,footl_y,footl_z,"
		+ "footr_y,up_y,chest_ny,head_hips_dx,head_feet_dy,"
		+ "drawn_low_y_mapped,drawn_low_y_raw,drawn_high_y,draw_height,health")
	var ko_tick := -1
	var capture_from := -1
	var tick := 0
	QAMatch.set_3d_off(self, true)
	while tick < 1200:
		tick += 1
		var dx: float = defender.global_position.x - attacker.global_position.x
		var action := ""
		if ko_tick < 0:
			if absf(dx) > 96.0:
				action = prefix + ("right" if dx > 0.0 else "left")
			elif attacker.state == BaseFighter.State.IDLE:
				action = prefix + "heavy"
		else:
			action = ""
		if action != "":
			Input.action_press(action)
			await physics_frame
			await physics_frame
			Input.action_release(action)
			await physics_frame
		else:
			await physics_frame

		if ko_tick < 0 and defender.state == BaseFighter.State.KO:
			ko_tick = tick
			capture_from = maxi(1, tick - 6)

		if capture_from > 0 and tick >= capture_from:
			var m := QAMatch.pose_metrics(model)
			var hips: Vector3 = m["hips"]
			var head: Vector3 = m["head"]
			var spine: Vector3 = m["spine2"]
			var fl: Vector3 = m["foot_l"]
			var fr: Vector3 = m["foot_r"]
			var cells: Array[String] = [
				str(tick), String(BaseFighter.State.keys()[defender.state]),
				"%.4f" % float(m["fall"]), "%.2f" % float(m["pivot_rz_deg"]),
				"%.2f" % float(m["visual_yaw_deg"]), "%.4f" % float(m["visual_seat_y"]),
				"%.4f" % hips.x, "%.4f" % hips.y, "%.4f" % hips.z,
				"%.4f" % head.x, "%.4f" % head.y, "%.4f" % head.z,
				"%.4f" % spine.x, "%.4f" % spine.y, "%.4f" % spine.z,
				"%.4f" % fl.x, "%.4f" % fl.y, "%.4f" % fl.z, "%.4f" % fr.y,
				"%.4f" % float(m["up_y"]), "%.4f" % float(m["chest_ny"]),
				"%.4f" % float(m["head_hips_dx"]), "%.4f" % float(m["head_feet_dy"]),
				"%.4f" % float(m["drawn_low_y"]), "%.4f" % float(m["drawn_low_y_unmapped"]),
				"%.4f" % (m["high"] as Vector3).y, "%.4f" % float(m["height"]),
				str(defender.health),
			]
			lines.append(",".join(cells))
		if ko_tick > 0 and tick - ko_tick >= _after_ko:
			break

	QAMatch.set_3d_off(self, false)
	DirAccess.make_dir_recursive_absolute(_out.get_base_dir())
	var f := FileAccess.open(_out, FileAccess.WRITE)
	if f == null:
		print("CSV FAIL: cannot write %s" % _out)
		quit(1)
		return
	for line in lines:
		f.store_line(line)
	f.close()
	print("CSV %s  rows=%d  ko_tick=%d  fighter=%s slot=%s"
		% [_out, lines.size() - 1, ko_tick, _fighter, _slot])
	await QAMatch.close(self, arena)
	quit()
