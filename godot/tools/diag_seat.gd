extends SceneTree
## Feedback in the p1 slot, tick by tick: does the rigid seat converge for a Mixamo body, and
## does `pred_low` ever disagree with the drawn low the metric reads? Measurement only.

const QAMatch := preload("res://tools/qa_match.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	var arena = await QAMatch.boot(self, &"feedback", &"lickshot", 0)
	var arena3d = arena.get("arena3d")
	var model: Node3D = arena3d.models.get("p1")
	arena.p1.change_state(BaseFighter.State.KNOCKDOWN)
	for tick in 60:
		await physics_frame
		var m := QAMatch.pose_metrics(model, Vector3.RIGHT)
		if tick % 2 != 0:
			continue
		print("t%02d fall=%.2f low %+.4f pred %+.4f seat %+.4f state_t=%d" % [
			tick, float(m["fall"]), float(m["drawn_low_y"]), model._rigid_low,
			model._rigid_seat, arena.p1.state_ticks])
	await QAMatch.close(self, arena)
	quit(0)
