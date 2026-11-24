extends SceneTree
## Prints the running arena's node tree (playtest fix 2026-11-24, issues 2 and 3).
## Used to prove no 2D crowd node and no procedural prop mesh survives in the live scene, and
## to list the five `.glb` prop slots with their expected path. The output is pasted into
## `AGENTS.md`. Run: `godot --headless --path godot --script res://tools/tree_dump.gd`.
func _initialize() -> void:
	var scene := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := scene.instantiate()
	root.add_child(arena)
	for i in 4:
		await process_frame
	print(arena.get_tree_string_pretty())

	# ---- Prop slots and missing models ------------------------------------------------
	var slots: Array[PropLoader] = []
	for node in arena.find_children("*", "PropLoader", true, false):
		slots.append(node as PropLoader)
	print("")
	print("PROP SLOTS (%d)" % slots.size())
	for slot in slots:
		var meshes := slot.find_children("*", "MeshInstance3D", true, false).size()
		print("  %-52s %-40s loaded=%s empty=%s meshes=%d"
			% [str(slot.get_path()), slot.model_path.get_file(), str(not slot.is_empty()),
				str(slot.is_empty()), meshes])
	var missing := PackedStringArray()
	for path in PropLoader.EXPECTED_MODELS:
		if not ResourceLoader.exists(path):
			missing.append(String(path).get_file())
	print("MISSING MODELS (%d of %d): %s"
		% [missing.size(), PropLoader.EXPECTED_MODELS.size(), ", ".join(missing)])
	quit(0)
