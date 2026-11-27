extends SceneTree
## PART A3 — the downed-body table, one row per fighter x slot x state, and its acceptance.
##
##   godot --headless --path . --script res://tools/knockdown_table.gd            # forced only
##   godot --headless --path . --script res://tools/knockdown_table.gd -- --played  # + played
##
## Two paths, same numbers or the argument is not settled:
##   forced — `change_state(KNOCKDOWN/KO)` on the defender, then the fall is allowed to settle;
##   played — a real match: the attacker walks in and throws heavy strikes until the defender
##            reaches the state, then the defender is left alone to settle.
##
## Every measurement goes through `qa_match.pose_metrics()` -> `DrawnBounds`, i.e. the same
## sampler the runtime seat uses. Columns are the acceptance ones: `up_y` (hips->head, nearly
## horizontal = |y| <= 0.3), `chest_ny` (the chest normal the acceptance names, >= 0.7), head
## away from the opponent, and the lowest DRAWN vertex at +0.015 m (-0.02 / +0.02).
## `d_up`/`d_low`/`d_deg` are forced minus played, which must stay inside 1 cm and 3 degrees.

const QAMatch := preload("res://tools/qa_match.gd")
const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
const STATES := {"KNOCKDOWN": BaseFighter.State.KNOCKDOWN, "KO": BaseFighter.State.KO}
const SETTLE := 70

const UP_MAX := 0.30
const CHEST_MIN := 0.70
const LOW_TARGET := 0.015
const LOW_SLACK := 0.02
const AGREE_LOW := 0.01
const AGREE_DEG := 3.0

var _rows: Array[Dictionary] = []
var _with_played := false
var _pass := 0
var _fail := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--played":
			_with_played = true
	_run()


func _run() -> void:
	QAMatch.mirror_actions()
	print("\n== TABLE ==")
	for key in FIGHTERS:
		for slot in ["p1", "p2"]:
			for state_name in STATES:
				var forced: Dictionary = await _probe(key, slot, StringName(state_name), true)
				var played: Dictionary = {"ok": false, "note": "skipped"}
				if _with_played:
					played = await _probe(key, slot, StringName(state_name), false)
				var row := {"fighter": key, "slot": slot, "state": state_name,
					"forced": forced, "played": played}
				_rows.append(row)
				# Printed as each cell lands, so a long played run still shows progress.
				_report(row)
	print("\n%d cells pass, %d fail" % [_pass, _fail])
	await process_frame
	quit(0 if _fail == 0 else 1)


func _probe(key: StringName, slot: String, state_name: StringName, forced: bool) -> Dictionary:
	var as_p2 := slot == "p2"
	var arena = await QAMatch.boot(self, &"feedback" if as_p2 else key,
		key if as_p2 else &"feedback", 0 if forced else 2)
	if arena == null:
		return {"ok": false}
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get(slot) if arena3d != null else null
	var defender: BaseFighter = arena.p2 if as_p2 else arena.p1
	var attacker: BaseFighter = arena.p1 if as_p2 else arena.p2
	var state: int = STATES[state_name]
	if model == null:
		return {"ok": false}
	defender.input_locked = false
	if forced:
		defender.change_state(state)
	else:
		var prefix := "p1_" if as_p2 else "p2_"
		attacker.use_local_input = true
		var guard := 0
		while defender.state != state and guard < 1400:
			guard += 1
			var dx: float = defender.global_position.x - attacker.global_position.x
			var action := ""
			if absf(dx) > 96.0:
				action = prefix + ("right" if dx > 0.0 else "left")
			elif attacker.state == BaseFighter.State.IDLE:
				action = prefix + "heavy"
			if action != "":
				_hold(action)
				await physics_frame
				await physics_frame
				Input.action_release(action)
				await physics_frame
			else:
				await physics_frame
		if defender.state != state:
			await QAMatch.close(self, arena)
			return {"ok": false, "note": "never reached %s" % state_name}
	# Sample EVERY tick of the window and report the frame of maximum fall. A knockdown holds
	# its flat pose only briefly before the get-up starts, so sampling a fixed number of ticks
	# later measures a standing body (that mistake put `fall 0.00` in this table once).
	var ticks: Array[Dictionary] = []
	for i in SETTLE + 60:
		await physics_frame
		var face_hint := Vector3(signf(attacker.global_position.x - defender.global_position.x), 0.0, 0.0)
		var m := QAMatch.pose_metrics(model, face_hint)
		var hips: Vector3 = m["hips"]
		var head: Vector3 = m["head"]
		var opp_x: float = attacker.global_position.x
		ticks.append({"fall": float(m["fall"]), "up": float(m["up_y"]),
			"chest": float(m["chest_ny"]), "low": float(m["drawn_low_y"]),
			"seat": float(m["visual_seat_y"]), "pivot": float(m["pivot_rz_deg"]),
			# Head away from the opponent: `head - hips` points the other way from the
			# opponent's side of the hips. (The first version of this line multiplied by
			# `hips - opp` instead of `opp - hips` and so scored "away" for a head that had
			# fallen TOWARDS the opponent — a sign error in the test, fixed here.)
			"away": 1 if (head.x - hips.x) * (opp_x - hips.x) < 0.0 else 0})
	# KO holds its flat pose, so the settled frame is the LAST near-peak one; a knockdown does
	# not, so its settled frame is the FIRST near-peak one before the get-up pulls it back.
	var peak := 0.0
	for t in ticks:
		peak = maxf(peak, float(t["fall"]))
	var pick: Dictionary = {}
	if state == BaseFighter.State.KO:
		for t in ticks:
			if float(t["fall"]) >= peak - 0.01:
				pick = t
	else:
		for t in ticks:
			if float(t["fall"]) >= peak - 0.01:
				pick = t
				break
	var out := {"ok": true, "up": float(pick["up"]), "chest": float(pick["chest"]),
		"low": float(pick["low"]), "away": int(pick["away"]), "samples": 1,
		"fall": float(pick["fall"]), "seat": float(pick["seat"]),
		"pivot": float(pick["pivot"])}
	await QAMatch.close(self, arena)
	return out


func _hold(action: String) -> void:
	if InputMap.has_action(action):
		Input.action_press(action)


func _cell_ok(f: Dictionary) -> bool:
	if not bool(f.get("ok", false)):
		return false
	return absf(float(f["up"])) <= UP_MAX and float(f["chest"]) >= CHEST_MIN \
		and int(f["away"]) == 1 \
		and absf(float(f["low"]) - LOW_TARGET) <= LOW_SLACK


func _report(row: Dictionary) -> void:
	var f: Dictionary = row["forced"]
	var p: Dictionary = row["played"]
	var label := "%-14s %s %-9s" % [row["fighter"], row["slot"], row["state"]]
	if not bool(f.get("ok", false)):
		print("%s forced FAILED: %s" % [label, str(f.get("note", "?"))])
		_fail += 1
		return
	var verdict := "PASS" if _cell_ok(f) else "FAIL"
	if verdict == "FAIL":
		_fail += 1
	else:
		_pass += 1
	var line := "%s %s up_y %+.3f chest_ny %+.3f head_away %d low %+.3f fall %.2f seat %+.3f roll %+.1f" % [
		label, verdict, f["up"], f["chest"], f["away"], f["low"], f["fall"], f["seat"], f["pivot"]]
	if bool(p.get("ok", false)):
		var d_up: float = absf(float(f["up"]) - float(p["up"]))
		var d_low: float = absf(float(f["low"]) - float(p["low"]))
		var d_chest: float = absf(float(f["chest"]) - float(p["chest"]))
		var dot := clampf(1.0 - (d_up * d_up + d_chest * d_chest) * 0.5, -1.0, 1.0)
		var degrees: float = rad_to_deg(acos(clampf(dot, -1.0, 1.0)))
		var agree := d_up <= AGREE_LOW and d_low <= AGREE_LOW and degrees <= AGREE_DEG
		line += "  | played up_y %+.3f chest_ny %+.3f low %+.3f  d_up %.3f d_low %.3f d_deg %.1f %s" % [
			p["up"], p["chest"], p["low"], d_up, d_low, degrees, "AGREE" if agree else "DISAGREE"]
		if not agree:
			_fail += 1
	else:
		line += "  | played: %s" % str(p.get("note", "?"))
	print(line)
