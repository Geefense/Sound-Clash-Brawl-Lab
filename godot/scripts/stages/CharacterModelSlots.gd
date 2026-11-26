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
## Same look, `cull_disabled` (PART 3 commit 8). A delivered prop whose glTF material is
## `doubleSided: true` and whose mesh is an open shell must keep its imported culling.
const TOON_SHADER_DOUBLE_SIDED := preload("res://assets/shaders/toon_cel_double_sided.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/toon_outline.gdshader")
## PART B commit 5 — the shared shading contract, applied to every cel material this file builds
## (fighters, DJs, crowd and cel props alike). `SHADING_FLOOR` is the unlit share of the delivered
## albedo, so nothing ever draws below 55 % of its texture in a shadow band; `BAND_SOFTNESS` is
## the width the engine's `diffuse_toon` smoothstep runs over (band = 2 × this). Both are read by
## the roster check straight off the materials.
const SHADING_FLOOR := 0.55
const BAND_SOFTNESS := 0.86
## Cel accent defaults shared by every slot user. `CROWD_TINT` is the luma-preserving palette
## mix the crowd wears (fighters leave the shader's crowd tint at 0).
const RIM_STRENGTH := 0.52
const ACCENT_STRENGTH := 0.9
const CROWD_TINT := 0.22
const CROWD_TINT_MAX := 0.25

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
## Shared geometry (owner playtest, 2026-11-24 PART 2). Twenty-two spectators cycle seven
## characters; instancing a PackedScene normally shares its sub-resources, but that is an
## importer detail, not a guarantee. This cache binds the FIRST instance's Mesh to every
## later instance by node path, so the crowd's GPU memory is seven meshes, not twenty-two.
static var _mesh_cache: Dictionary = {}
## The delivered diffuse atlas per source file, resolved once (`<model>_0.png`).
static var _atlas_cache: Dictionary = {}
## Shared cel materials for a whole bank (Bug 4c, 2026-11-25). Keyed by source file + atlas,
## so every rig wearing the same character reuses ONE ShaderMaterial and takes its palette
## from the per-instance uniform instead of owning a material of its own.
static var _shared_cel: Dictionary = {}


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
	share_meshes(node, path)
	fit_height(node, height)
	autoplay(node)
	return node


## Bind the cached Mesh for every node path under `path` onto this instance, caching the
## first instance's meshes on the way through. Returns how many surfaces reused cached
## geometry (0 on the first instance of a file, which is what seeds the cache).
static func share_meshes(node: Node3D, path: String) -> int:
	if node == null:
		return 0
	var cache: Dictionary = _mesh_cache.get(path, {})
	var reused := 0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var key := String(node.get_path_to(mi))
		if cache.has(key):
			mi.mesh = cache[key]
			reused += 1
		else:
			cache[key] = mi.mesh
	_mesh_cache[path] = cache
	return reused


## How many modes of distinct geometry the cache holds for one model file.
static func cached_mesh_count(path: String) -> int:
	var cache: Dictionary = _mesh_cache.get(path, {})
	return cache.size()


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
## `double_sided` swaps in the `cull_disabled` variant for an open-shell prop: the imported
## culling is only overridden when the caller has verified the mesh is a closed solid.
static func apply_cel(node: Node3D, tint: Color, rim: Color, variant: int = 0,
		hue_shift: float = 0.0, source_path: String = "", double_sided: bool = false) -> int:
	var applied := 0
	var fallback := delivered_atlas(source_path)
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
			if texture == null:
				# Some delivered female FBX exports arrive with their body/clothing material
				# unbound even though the character's own diffuse atlas was extracted beside it
				# (`<model>_0.png`). Bind that delivered atlas instead of leaving an untextured
				# surface or dropping the character — no invented art, and no empty slot.
				texture = fallback
			if texture == null:
				# With no delivered diffuse either, the surface keeps the material the exporter
				# shipped and the caller is told the instance is short.
				push_warning("CharacterModelSlots: %s surface %d has no albedo texture — left as imported"
					% [node.name, surface])
				continue
			# One material per character: the key carries the character's own id, so no two
			# characters can ever share (and therefore tint, dim or recolour) a material.
			# Every surface of one upload draws from the same atlas, which also keeps the draw
			# state cheap on a Chromebook.
			var key := "%s_%d%s" % [node.get_instance_id(), variant, "_ds" if double_sided else ""]
			var material: ShaderMaterial = _cel_materials.get(key)
			if material == null:
				material = ShaderMaterial.new()
				material.shader = TOON_SHADER_DOUBLE_SIDED if double_sided else TOON_SHADER
				material.set_shader_parameter("albedo_texture", texture)
				material.set_shader_parameter("tint", tint)
				material.set_shader_parameter("hue_shift", hue_shift)
				material.set_shader_parameter("rim_colour", rim)
				material.set_shader_parameter("rim_strength", 0.52)
				# No global darkening: the shadow band is the albedo's own colour at full
				# brightness, so a crowd body shows exactly the texture it was delivered with.
				material.set_shader_parameter("shadow_tint_amount", 0.0)
				# PART B commit 5: 55 % unlit floor and the engine's smoothstep toon band.
				material.set_shader_parameter("albedo_floor", SHADING_FLOOR)
				material.set_shader_parameter("band_softness", BAND_SOFTNESS)
				var ink := ShaderMaterial.new()
				ink.shader = OUTLINE_SHADER
				ink.set_shader_parameter("ink_width", 0.0026)
				material.next_pass = ink
				_cel_materials[key] = material
			mi.set_surface_override_material(surface, material)
			applied += 1
	return applied


## Cel treatment for a whole bank of characters sharing one material (Bug 4c, 2026-11-25).
##
## The crowd cannot afford one material per rig, so every rig wearing the same delivered atlas
## binds the SAME ShaderMaterial and takes its dancehall palette from the shader's per-instance
## `instance_accent` uniform. `rim` is the phase rim colour the arena already owns; `accent` is
## this rig's own palette accent. Only emission is per-instance — ALBEDO stays the delivered
## texture at full brightness, so a Web build that drops the instance buffer cannot black a body.
static func apply_cel_shared(node: Node3D, source_path: String, rim: Color, accent: Color,
		rim_strength: float = RIM_STRENGTH, accent_strength: float = ACCENT_STRENGTH,
		tint_strength: float = CROWD_TINT) -> int:
	var applied := 0
	var fallback := delivered_atlas(source_path)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for surface in mi.mesh.get_surface_count():
			var texture: Texture2D = null
			var source := mi.mesh.surface_get_material(surface)
			if source is BaseMaterial3D:
				texture = (source as BaseMaterial3D).albedo_texture
			if texture == null:
				texture = fallback
			if texture == null:
				push_warning("CharacterModelSlots: %s surface %d has no albedo texture — left as imported"
					% [node.name, surface])
				continue
			var key := "%s|%d" % [source_path, texture.get_instance_id()]
			var material: ShaderMaterial = _shared_cel.get(key)
			if material == null:
				material = ShaderMaterial.new()
				material.shader = TOON_SHADER
				material.set_shader_parameter("albedo_texture", texture)
				material.set_shader_parameter("tint", Color.WHITE)
				material.set_shader_parameter("rim_colour", rim)
				material.set_shader_parameter("rim_strength", rim_strength)
				material.set_shader_parameter("accent_strength", accent_strength)
				material.set_shader_parameter("shadow_tint_amount", 0.0)
				# Same floor as the fighters: a crowd body never falls below 55 % of its atlas.
				material.set_shader_parameter("albedo_floor", SHADING_FLOOR)
				material.set_shader_parameter("band_softness", BAND_SOFTNESS)
				# PART B commit 7: a luma-preserving palette mix, never a multiplicative tint.
				material.set_shader_parameter("crowd_tint_strength",
					clampf(tint_strength, 0.0, CROWD_TINT_MAX))
				var ink := ShaderMaterial.new()
				ink.shader = OUTLINE_SHADER
				ink.set_shader_parameter("ink_width", 0.0026)
				material.next_pass = ink
				_shared_cel[key] = material
			mi.set_surface_override_material(surface, material)
			mi.set_instance_shader_parameter("instance_accent", accent)
			mi.set_instance_shader_parameter("instance_tint", accent)
			applied += 1
	return applied


## Distinct shared cel materials built so far — twenty-two rigs must not mean twenty-two.
static func shared_cel_material_count() -> int:
	return _shared_cel.size()


## Height of one character in its own unscaled space times its fit scale, ignoring any yaw the
## parent anchor applies. `mesh_bounds()` is world space and would inflate with a rotated
## anchor, so the crowd's scale audit needs this instead.
static func local_height(node: Node3D) -> float:
	if node == null:
		return 0.0
	var inverse := node.global_transform.affine_inverse()
	var merged := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = inverse * mi.global_transform * mi.get_aabb()
		merged = box if first else merged.merge(box)
		first = false
	if first:
		return 0.0
	return merged.size.y * node.scale.y


## The character's own extracted diffuse atlas: `<model>_0.png` beside the source file.
## Godot's FBX importer extracts embedded images in source order, and every delivered
## crowd/DJ set keeps its diffuse map at index 0 (index 1 is the normal map), so this is the
## character's own delivered art, cached once per source. Null when the set was not delivered.
static func delivered_atlas(source_path: String) -> Texture2D:
	if source_path == "":
		return null
	if _atlas_cache.has(source_path):
		return _atlas_cache[source_path]
	var atlas: Texture2D = null
	var candidate := source_path.get_basename() + "_0.png"
	if ResourceLoader.exists(candidate):
		atlas = load(candidate) as Texture2D
	_atlas_cache[source_path] = atlas
	return atlas


## Per-instance albedo diagnostic (playtest fix 2026-11-24, issue 2). Prints the model name,
## its material count and the albedo texture every character surface is bound to, and returns
## how many surfaces ended up with nothing bound. A non-zero return is a broken loader slot:
## the model must then be left out rather than drawn untextured.
##
## Hand props parented under a `BoneAttachment3D` are skipped: a flag, a lighter or an airhorn
## is painted geometry with its own plain material, not part of the character's albedo.
static func report_albedo(tag: String, node: Node3D) -> int:
	var missing := 0
	var parts := PackedStringArray()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or _under_hand_prop(mi):
			continue
		for surface in mi.mesh.get_surface_count():
			var texture := surface_albedo(mi, surface)
			var path := texture.resource_path if texture != null else "<none>"
			if texture == null:
				missing += 1
			parts.append("%s#%d=%s" % [mi.name, surface, path])
	print("[albedo] %s %s materials=%d %s" % [tag, node.name, parts.size(), ", ".join(parts)])
	return missing


## The albedo actually in force for one surface, whether it comes from the cel override or
## from the material the exporter shipped.
static func surface_albedo(mi: MeshInstance3D, surface: int) -> Texture2D:
	var material := mi.get_surface_override_material(surface)
	if material is ShaderMaterial:
		return (material as ShaderMaterial).get_shader_parameter("albedo_texture") as Texture2D
	if mi.material_override is BaseMaterial3D:
		return (mi.material_override as BaseMaterial3D).albedo_texture
	var source := mi.mesh.surface_get_material(surface) if mi.mesh != null else null
	if source is BaseMaterial3D:
		return (source as BaseMaterial3D).albedo_texture
	return null


## True for prop geometry riding a character's hand rather than the character itself.
static func _under_hand_prop(node: Node) -> bool:
	var walk := node.get_parent()
	while walk != null:
		if walk is BoneAttachment3D:
			return true
		walk = walk.get_parent()
	return false


## The cel materials actually bound to one character, so a caller can move its rim highlight
## with the arena palette without ever touching albedo. Rim is additive light, not tint.
static func collect_cel_materials(node: Node3D, into: Array[ShaderMaterial]) -> void:
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var material := mi.get_surface_override_material(surface)
			if material is ShaderMaterial and not into.has(material as ShaderMaterial):
				into.append(material as ShaderMaterial)


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
