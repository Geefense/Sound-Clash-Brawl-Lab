extends SceneTree
## Rigid-fall internals for both slots: which axis was chosen, which way the head went, and what
## the seat thinks the drawn low is versus what the metric reads. Measurement only.

const QAMatch := preload("res://tools/qa_match.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	for slot in ["p1", "p2"]:
		await _one(slot)
	quit(0)


func _one(slot: String) -> void:
	var as_p2 := slot == "p2"
	var arena = await QAMatch.boot(self, &"feedback" if as_p2 else &"lickshot",
		&"lickshot" if as_p2 else &"feedback", 0)
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get(slot)
	var defender: BaseFighter = arena.p2 if as_p2 else arena.p1
	var attacker: BaseFighter = arena.p1 if as_p2 else arena.p2
	defender.change_state(BaseFighter.State.KNOCKDOWN)
	print("\n== %s ==" % slot)
	for tick in 40:
		await physics_frame
		if tick % 4 != 0:
			continue
		var face_hint := Vector3(signf(attacker.global_position.x - defender.global_position.x), 0.0, 0.0)
		var m := QAMatch.pose_metrics(model, face_hint)
		print("t%02d axis(%+.2f %+.2f %+.2f) flat %+.1f° angle_active=%s fall=%.2f up(%+.2f %+.2f %+.2f) hips.x %+.2f head.x %+.2f opp.x %+.2f low %+.3f seat %+.3f pred_low %+.3f" % [
			tick, model._rigid_axis.x, model._rigid_axis.y, model._rigid_axis.z,
			rad_to_deg(model._rigid_flat_rad), str(model._rigid), float(m["fall"]),
			m["up_y"], 0.0, 0.0, m["hips"].x, m["head"].x,
			attacker.global_position.x, float(m["drawn_low_y"]), model._rigid_seat,
			model._rigid_low])
	await QAMatch.close(self, arena)
