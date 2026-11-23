class_name CharacterModelSlots
extends RefCounted
## Drop-in slots for real rigged characters (owner playtest, 2026-11-23).
##
## Drop Mixamo-style exports straight into:
##   `res://assets/models/dj/`    — 3D DJ / selector characters
##   `res://assets/models/crowd/` — 3D crowd characters
##
## Any `.fbx`, `.glb` or `.gltf` found there is imported by Godot on the next project scan
## and instanced at run time: the loader fits each model to the requested world height,
## puts its feet on the layer's floor line, starts its first animation, and the caller
## hides the 2.5D stand-in silhouette for that slot. Until files exist the folders are
## empty (just a README) and the silhouette fallback stays on screen, so the build never
## depends on art that has not been delivered.
##
## This is a file-system contract, not a rig contract: no bone names, no animation names
## and no scale are assumed. A model that is authored facing +Z (Mixamo's default) will
## face the arena camera; rotate it in the DCC tool, not here.

const DJ_DIR := "res://assets/models/dj/"
const CROWD_DIR := "res://assets/models/crowd/"
const EXTENSIONS := ["fbx", "glb", "gltf"]
## Mixamo exports arrive at centimetre scale and vary wildly; the loader only ever uses the
## model's own bounding box, so this is a sanity clamp, not a magic number.
const HEIGHT_RANGE := Vector2(0.3, 6.0)


## Every loadable character source in a slot folder, sorted for a stable assignment.
static func model_paths(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	if not DirAccess.dir_exists_absolute(dir_path):
		return found
	for raw in DirAccess.get_files_at(dir_path):
		var file := String(raw)
		if file.ends_with(".remap"):
			file = file.trim_suffix(".remap")
		if file.ends_with(".import"):
			file = file.trim_suffix(".import")
		var lower := file.to_lower()
		var is_model := false
		for ext in EXTENSIONS:
			if lower.ends_with("." + ext):
				is_model = true
				break
		if not is_model:
			continue
		var path := dir_path + file
		if not found.has(path):
			found.append(path)
	found.sort()
	return found


## Instance up to `count` characters from a slot folder. Returns what was actually built;
## an empty array means "no art delivered yet, keep the silhouette".
static func spawn_into(parent: Node3D, dir_path: String, count: int, height: float,
		facing_degrees: float = 0.0) -> Array[Node3D]:
	var built: Array[Node3D] = []
	if parent == null or count <= 0:
		return built
	var paths := model_paths(dir_path)
	if paths.is_empty():
		return built
	for i in count:
		var node := spawn_one(parent, paths[i % paths.size()], height, facing_degrees)
		if node == null:
			continue
		node.name = "Model%02d" % i
		built.append(node)
	return built


## Instance one specific character file into `parent`. Returns null when the source is
## missing or is not an importable 3D scene, so the caller keeps its silhouette.
static func spawn_one(parent: Node3D, path: String, height: float,
		facing_degrees: float = 0.0) -> Node3D:
	if parent == null or path == "" or not ResourceLoader.exists(path):
		return null
	var packed := load(path) as PackedScene
	if packed == null:
		return null
	var instance := packed.instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		return null
	var node := instance as Node3D
	node.rotation_degrees.y = facing_degrees
	parent.add_child(node)
	fit_height(node, height)
	autoplay(node)
	return node


## Scale so the model's own mesh bounds stand `height` metres tall, feet on y 0.
static func fit_height(node: Node3D, height: float) -> void:
	if node == null:
		return
	var bounds := mesh_bounds(node)
	if bounds.size.y <= 0.0001:
		return
	var scale_factor := clampf(height, HEIGHT_RANGE.x, HEIGHT_RANGE.y) / bounds.size.y
	node.scale = node.scale * scale_factor
	node.position.y -= bounds.position.y * scale_factor


## World-space bounds merged from every mesh under the node (works for imported scenes).
static func mesh_bounds(root: Node3D) -> AABB:
	var merged := AABB()
	var first := true
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box := mi.global_transform * mi.get_aabb()
		merged = box if first else merged.merge(box)
		first = false
	return merged


## Start the character's own idle: the first animation if the exporter named none.
static func autoplay(root: Node3D) -> void:
	for child in root.find_children("*", "AnimationPlayer", true, false):
		var player := child as AnimationPlayer
		if player == null:
			continue
		var names := player.get_animation_list()
		if names.is_empty():
			continue
		if player.autoplay == "":
			player.autoplay = names[0]
			player.play(names[0])
		player.active = true


static func slot_summary(dir_path: String) -> String:
	var paths := model_paths(dir_path)
	if paths.is_empty():
		return "empty"
	var names: Array[String] = []
	for path in paths:
		names.append(path.get_file())
	return ", ".join(names)
