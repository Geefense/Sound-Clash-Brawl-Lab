extends SceneTree
## Overnight props diag: what each PropLoader actually ended up with. Measurement only.


func _initialize() -> void:
	_run()


func _run() -> void:
	var setup = root.get_node_or_null("MatchSetup")
	setup.commit_match(&"feedback", &"lickshot")
	setup.ai_mode = 0
	var packed := load("res://scenes/TestArena.tscn") as PackedScene
	var arena = packed.instantiate()
	var rounds = arena.get_node_or_null("RoundController")
	if rounds != null:
		rounds.enabled = false
	root.add_child(arena)
	for i in 8:
		await physics_frame
	for node in arena.find_children("*", "PropLoader", true, false):
		var slot := node as PropLoader
		var meshes := slot.find_children("*", "MeshInstance3D", true, false).size()
		print("slot %-46s empty=%s meshes=%d native=%s two=%s ground=%s longest=%.3f len=%.4f" % [
			str(slot.get_path()), str(slot.is_empty()), meshes, str(slot.native_material),
			str(slot.double_sided), str(slot.auto_ground_y), slot.resolved_target_longest(),
			_longest(slot)])
		if slot.model != null:
			print("      rot %s  basis.z %s" % [str(slot.model.rotation_degrees),
				str(slot.model.global_transform.basis.z)])
			print("      front_yaw %.1f  aabb %s" % [slot.front_yaw_degrees(), str(slot.measured_aabb.size)])
	quit(0)


func _longest(slot: PropLoader) -> float:
	if slot.model == null:
		return 0.0
	var box := AABB()
	var first := true
	for child in slot.model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi != null and mi.mesh != null:
			box = mi.mesh.get_aabb() if first else box.merge(mi.mesh.get_aabb())
			first = false
	return maxf(box.size.x, maxf(box.size.y, box.size.z)) \
		* slot.model.global_transform.basis.get_scale().y
