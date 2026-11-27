extends SceneTree
## Which way each delivered rig's shoulder line points, standing and downed. The knockdown
## acceptance's chest normal is `up × (LeftShoulder − RightShoulder)` oriented by the facing, so
## a rig that names its shoulders the other way round inverts that column. Measurement only.

const QAMatch := preload("res://tools/qa_match.gd")
const FIGHTERS := [&"feedback", &"lickshot", &"young_selecta"]


func _initialize() -> void:
	_run()


func _run() -> void:
	for key in FIGHTERS:
		var arena = await QAMatch.boot(self, key, &"feedback", 0)
		var arena3d = arena.get("arena3d")
		var model: Node3D = arena3d.models.get("p1")
		_dump("%-14s standing" % key, model)
		arena.p1.change_state(BaseFighter.State.KNOCKDOWN)
		for i in 40:
			await physics_frame
		_dump("%-14s downed  " % key, model)
		await QAMatch.close(self, arena)
	quit(0)


func _dump(label: String, model: Node3D) -> void:
	var hips := QAMatch.bone_world(model, "Hips")
	var head := QAMatch.bone_world(model, "Head")
	var sl := QAMatch.bone_world(model, "LeftShoulder")
	var sr := QAMatch.bone_world(model, "RightShoulder")
	var toe := QAMatch.toe_vector(model)
	var up: Vector3 = (head - hips).normalized()
	var side: Vector3 = (sl - sr).normalized()
	var raw: Vector3 = up.cross(side).normalized()
	print("%s up (%+.2f %+.2f %+.2f) side (%+.2f %+.2f %+.2f) raw×side (%+.2f %+.2f %+.2f) toe (%+.2f %+.2f %+.2f)" % [
		label, up.x, up.y, up.z, side.x, side.y, side.z, raw.x, raw.y, raw.z,
		toe.x, toe.y, toe.z])
	print("      names L='%s' R='%s'" % [_bone_name(model, "LeftShoulder"),
		_bone_name(model, "RightShoulder")])


func _bone_name(model: Node3D, suffix: String) -> String:
	var skel: Skeleton3D = QAMatch.skeleton_of(model)
	if skel == null:
		return "-"
	for i in skel.get_bone_count():
		if skel.get_bone_name(i).ends_with(suffix):
			return skel.get_bone_name(i)
	return "-"
