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

## Cel treatment for dropped-in characters (2026-11-23): the same Spatial Toon shader and
## inverted-hull ink `next_pass` the fighters use, so a real Mixamo model reads as part of
## the same inked world instead of a stock asset.
const TOON_SHADER := preload("res://assets/shaders/toon_cel.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/toon_outline.gdshader")

## Acting clips. Every Mixamo upload is one take on the same 68-bone `mixamorig` skeleton,
## and every imported scene uses identical node paths (`Armature/Skeleton3D:mixamorig_*`),
## so a clip can be installed on any of the characters unchanged. The role is read from the
## uploaded filename; the file that has no role words becomes that character's own base
## loop. Nothing here assumes a clip that has not been delivered.
const ACT_NEUTRAL := &"neutral"
const ACT_CHEER := &"cheer"
const ACT_DISBELIEF := &"disbelief"
const ACT_HYPE := &"hype"
const ACT_FADE := 0.12

static var _act_clips: Dictionary = {}
static var _act_scan_done := false
static var _cel_materials: Dictionary = {}
static var _plain_texture: Texture2D = null


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


# =========================================================================
# Mixamo acting clips (2026-11-23)
# =========================================================================
## The character's own AnimationPlayer, from an instantiated import.
static func animation_player(node: Node3D) -> AnimationPlayer:
	if node == null:
		return null
	for child in node.find_children("*", "AnimationPlayer", true, false):
		return child as AnimationPlayer
	return null


## First clip name of the import (the character's own loop).
static func base_clip(node: Node3D) -> String:
	var player := animation_player(node)
	if player == null:
		return ""
	var names := player.get_animation_list()
	return String(names[0]) if not names.is_empty() else ""


## One shared Animation per act, read from the uploaded filenames. The scene is
## instantiated only long enough to borrow its take, then freed; the Animation resource
## survives in the cache and is shared by every character.
static func scan_act_clips() -> void:
	if _act_scan_done:
		return
	_act_scan_done = true
	var paths: Array[String] = model_paths(CROWD_DIR)
	for path in model_paths(DJ_DIR):
		if not paths.has(path):
			paths.append(path)
	for path in paths:
		var lower := path.get_file().to_lower()
		var act: StringName = &""
		if lower.contains("cheer"):
			act = ACT_CHEER
		elif lower.contains("angry"):
			act = ACT_DISBELIEF
		elif lower.contains("rally"):
			act = ACT_HYPE
		if act == &"" or _act_clips.has(act):
			continue
		var packed := load(path) as PackedScene
		if packed == null:
			continue
		var instance := packed.instantiate()
		var player := animation_player(instance as Node3D)
		if player != null and not player.get_animation_list().is_empty():
			var source := player.get_animation(player.get_animation_list()[0])
			if source != null:
				var clip := source.duplicate() as Animation
				clip.loop_mode = Animation.LOOP_LINEAR
				_act_clips[act] = clip
		instance.free()


## Install the shared acting clips on one character. Returns
## `{base, cheer, disbelief, hype, player}`; acts that were not delivered are absent and
## `play_act()` falls back to the character's own loop.
static func install_act_clips(node: Node3D) -> Dictionary:
	var out := {"base": "", "player": null}
	var player := animation_player(node)
	if player == null:
		return out
	out["player"] = player
	var base := base_clip(node)
	if base != "":
		out["base"] = base
		var own := player.get_animation(base)
		if own != null:
			own.loop_mode = Animation.LOOP_LINEAR
	scan_act_clips()
	var library := player.get_animation_library(&"")
	if library == null:
		library = AnimationLibrary.new()
		player.add_animation_library(&"", library)
	for act in _act_clips:
		var clip_name := "mixamo_" + String(act)
		if not player.has_animation(clip_name):
			library.add_animation(clip_name, _act_clips[act])
		out[act] = clip_name
	return out


## Crossfade to an act. Unknown acts use the character's own loop, so a partial upload
## set still animates instead of freezing.
static func play_act(node: Node3D, acts: Dictionary, act: StringName,
		fade: float = ACT_FADE) -> String:
	if acts.is_empty():
		return ""
	var player = acts.get("player")
	if player == null:
		return ""
	var clip_name := String(acts.get(act, acts.get(ACT_NEUTRAL, acts.get("base", ""))))
	if clip_name == "":
		return ""
	if player.current_animation != clip_name:
		player.play(clip_name, fade)
	return clip_name


## Convert every surface to the cel shader + ink outline, keeping the upload's own albedo.
## `variant` keeps a cached material per look (warm left bank, cool right bank, gold booth).
static func apply_cel(node: Node3D, tint: Color, rim: Color, variant: int = 0,
		hue_shift: float = 0.0) -> int:
	var applied := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mi.mesh.get_surface_count():
			var source := mi.mesh.surface_get_material(surface)
			var texture: Texture2D = null
			if source is BaseMaterial3D:
				texture = (source as BaseMaterial3D).albedo_texture
			var key := "%s_%d" % [str(source.get_instance_id()) if source != null else "none",
				variant]
			var material: ShaderMaterial = _cel_materials.get(key)
			if material == null:
				material = ShaderMaterial.new()
				material.shader = TOON_SHADER
				material.set_shader_parameter("albedo_texture", texture if texture != null
					else _white_texture())
				material.set_shader_parameter("tint", tint)
				material.set_shader_parameter("hue_shift", hue_shift)
				material.set_shader_parameter("rim_colour", rim)
				material.set_shader_parameter("rim_strength", 0.52)
				var ink := ShaderMaterial.new()
				ink.shader = OUTLINE_SHADER
				ink.set_shader_parameter("ink_width", 0.0026)
				material.next_pass = ink
				_cel_materials[key] = material
			mi.set_surface_override_material(surface, material)
			applied += 1
	return applied


static func _white_texture() -> Texture2D:
	if _plain_texture == null:
		var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_plain_texture = ImageTexture.create_from_image(image)
	return _plain_texture


## True when a surface of this character already carries the cel shader and ink pass.
static func cel_surfaces(node: Node3D) -> int:
	var count := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var material := mi.get_surface_override_material(surface)
			if material is ShaderMaterial and (material as ShaderMaterial).next_pass != null:
				count += 1
	return count


## Triangles in one instantiated character, measured from its own meshes. Hand props
## parented under a BoneAttachment3D are not part of the character budget.
static func character_triangles(node: Node3D) -> int:
	var total := 0
	if node == null:
		return total
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var cursor: Node = mi.get_parent()
		var hand_prop := false
		while cursor != null and cursor != node:
			if cursor is BoneAttachment3D:
				hand_prop = true
				break
			cursor = cursor.get_parent()
		if hand_prop:
			continue
		total += int(mi.mesh.get_faces().size() / 3)
	return total


## Bone count of one instantiated character (0 when it has no skeleton).
static func character_bones(node: Node3D) -> int:
	if node == null:
		return 0
	for child in node.find_children("*", "Skeleton3D", true, false):
		return (child as Skeleton3D).get_bone_count()
	return 0
