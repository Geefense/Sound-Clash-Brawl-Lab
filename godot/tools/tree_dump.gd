extends SceneTree
## Prints the running arena's node tree (playtest fix 2026-11-24, issue 2, step 6).
## Used to prove no 2D crowd node survives in the live scene; the output is pasted into
## `AGENTS.md`. Run: `godot --headless --path godot --script res://tools/tree_dump.gd`.
func _initialize() -> void:
	var scene := load("res://scenes/TestArena.tscn") as PackedScene
	var arena := scene.instantiate()
	root.add_child(arena)
	for i in 4:
		await process_frame
	print(arena.get_tree_string_pretty())
	quit(0)
