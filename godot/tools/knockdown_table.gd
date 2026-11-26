extends SceneTree
## PART A3 — the downed-body table, one row per fighter x slot x state.
##
##   godot --headless --path godot --script res://tools/knockdown_table.gd
##
## Two paths, same numbers or the argument is not settled:
##   forced — `change_state(KNOCKDOWN/KO)` on the defender, then the fall is allowed to settle;
##   played — a real match: the attacker walks in and throws heavy strikes until the defender
##            reaches the state, then the defender is left alone to settle.
##
## Columns are the acceptance ones: `up_y` (hips->head, nearly horizontal = |y| <= 0.3),
## `chest_ny` (Spine2 forward axis, >= 0.7), head away from the opponent, and the lowest drawn
## vertex ([-0.02, +0.03] m). `d_up`/`d_chest`/`d_low` are forced minus played, which the
## harness contract keeps inside 1 cm and 3 degrees.

const QAMatch := preload("res://tools/qa_match.gd")
const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]
const STATES := {"KNOCKDOWN": BaseFighter.State.KNOCKDOWN, "KO": BaseFighter.State.KO}
const SETTLE := 70

var _rows: Array[Dictionary] = []
## The played path needs the three-piece finisher to put a body on the floor, so it is opt-in
## (`-- --played`) while the forced matrix is the one the acceptance measures.
var _with_played := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--played":
			_with_played = true
	_run()


func _run() -> void:
	QAMatch.mirror_actions()
	for key in FIGHTERS:
		for slot in ["p1", "p2"]:
			for state_name in STATES:
				var forced: Dictionary = await _probe(key, slot, StringName(state_name), true)
				var played: Dictionary = {"ok": false, "note": "skipped"}
				if _with_played:
					played = await _probe(key, slot, StringName(state_name), false)
				_rows.append({"fighter": key, "slot": slot, "state": state_name,
					"forced": forced, "played": played})
	print("\n== TABLE ==")
	for row in _rows:
		_report(row)
	await process_frame
	quit(0)


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
		# Real match: close the gap, throw heavies, stop the moment the state is reached.
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
				Input.action_press(action)
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
		var m := QAMatch.pose_metrics(model)
		var hips: Vector3 = m["hips"]
		var head: Vector3 = m["head"]
		var opp_x: float = attacker.global_position.x
		ticks.append({"fall": float(m["fall"]), "up": float(m["up_y"]),
			"chest": float(m["chest_ny"]), "low": float(m["drawn_low_y"]),
			# Head away from the opponent: the head is on the far side of the hips.
			"away": 1 if (head.x - hips.x) * (hips.x - opp_x) < 0.0 else 0})
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
	var away := int(pick["away"])
	var out := {"ok": true, "up": float(pick["up"]), "chest": float(pick["chest"]),
		"low": float(pick["low"]), "away": away, "samples": 1, "fall": float(pick["fall"])}
	await QAMatch.close(self, arena)
	return out


func _report(row: Dictionary) -> void:
	var f: Dictionary = row["forced"]
	var p: Dictionary = row["played"]
	if not bool(f.get("ok", false)):
		print("%-14s %s %-9s forced FAILED: %s" % [row["fighter"], row["slot"],
			row["state"], str(f.get("note", "?"))])
		return
	if not bool(p.get("ok", false)):
		print("%-14s %s %-9s up_y %+.3f chest_ny %+.3f head_away %d/%d low %+.3f fall %.2f"
			% [row["fighter"], row["slot"], row["state"], f["up"], f["chest"],
				f["away"], f["samples"], f["low"], f["fall"]]
			+ "  (played: %s)" % str(p.get("note", "?")))
		return
	var d_up: float = absf(float(f["up"]) - float(p["up"]))
	var d_chest: float = absf(float(f["chest"]) - float(p["chest"]))
	var d_low: float = absf(float(f["low"]) - float(p["low"]))
	var degrees: float = rad_to_deg(acos(clampf(1.0 - (d_up * d_up + d_chest * d_chest) * 0.5,
		-1.0, 1.0)))
	print("%-14s %s %-9s up_y %+.3f/%+.3f chest_ny %+.3f/%+.3f head_away %d/%d of %d "
		% [row["fighter"], row["slot"], row["state"], f["up"], p["up"], f["chest"], p["chest"],
			f["away"], p["away"], f["samples"]]
		+ "low %+.3f/%+.3f  d_up %.3f d_chest %.3f d_deg %.1f d_low %.3f"
		% [f["low"], p["low"], d_up, d_chest, degrees, d_low])
