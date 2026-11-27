extends SceneTree
## Knockdown timeline: what the runtime actually does, tick by tick, after the state changes.
## Measurement only — asserts nothing.
##
##   godot --headless --path . --script res://tools/diag_fall.gd

const QAMatch := preload("res://tools/qa_match.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	for state_name in ["KNOCKDOWN", "KO"]:
		var arena = await QAMatch.boot(self, &"feedback", &"lickshot", 0)
		var arena3d = arena.get("arena3d")
		var model: Node3D = arena3d.models.get("p1")
		var defender: BaseFighter = arena.p1
		var attacker: BaseFighter = arena.p2
		defender.change_state(BaseFighter.State[state_name])
		print("\n== %s ==" % state_name)
		for tick in 90:
			await physics_frame
			var face_hint := Vector3(signf(attacker.global_position.x - defender.global_position.x), 0.0, 0.0)
			var m := QAMatch.pose_metrics(model, face_hint)
			print("t%02d state=%s fall=%.3f up_y=%+.3f chest_ny=%+.3f low=%+.3f seat=%+.3f" % [
				tick, BaseFighter.State.keys()[defender.state], float(m["fall"]),
				float(m["up_y"]), float(m["chest_ny"]), float(m["drawn_low_y"]),
				float(m["visual_seat_y"])])
		await QAMatch.close(self, arena)
	quit(0)
