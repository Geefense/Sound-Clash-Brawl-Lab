class_name PropLoader
extends Node3D
## One empty slot for a delivered `.glb` prop (playtest fix 2026-11-24, issue 3).
##
## The arena no longer builds speakers, the DJ booth, microphones, a mic stand, a dictionary,
## flags, lighters or airhorns out of `BoxMesh`/`CylinderMesh` primitives. Every one of those
## was programmer art. Each one is now a slot that names the model it expects and shows
## **nothing at all** until that model exists.
##
## A missing file is not an error and never draws a substitute: the slot logs one warning and
## stays empty. Drop the model into `res://assets/models/props/` and it appears with no code
## change. See `assets/models/props/README.md` for the expected scale, pivot and facing.
##
## Presentation only — no prop here is read by the combat simulation or derives a hitbox.

## The five files this project expects in `res://assets/models/props/`, in slot order. The
## tree dump and the headless check read this list, so a renamed slot can never drift from the
## README.
const EXPECTED_MODELS := [
	"res://assets/models/props/jamaican_speaker.glb",
	"res://assets/models/props/rasta_speaker.glb",
	"res://assets/models/props/dj_booth.glb",
	"res://assets/models/props/wireless_mic.glb",
	"res://assets/models/props/mic_stand.glb",
]

## Per-slot target height in metres, keyed by the model's file stem (PART 2, commit 6).
## `0.0` means "keep the delivered scale" — the mic and the stand are handheld props whose
## real size the export already carries, so they are never rescaled.
## PART M (2026-11-27): the beach set is now a FULL-SIZE arcade stage, so the two wide slots
## carry real shack/tower dimensions instead of table-top placeholders. The proportions are
## the delivered files' own: the thatched hut is authored 0.947 × 0.659 × 0.630, so seating it
## at 2.45 m tall makes it 3.52 m wide and 2.34 m deep — inside the brief's 2.35–2.55 ×
## 3.4–3.7 window without a single non-uniform scale. The tower is authored 1.682 × 1.899 ×
## 0.575, so 2.50 m tall makes it 2.21 m wide; the brief's 2.3–2.7 m band is the height.
const TARGET_HEIGHT_M := {
	"jamaican_speaker": 2.5,
	"rasta_speaker": 2.5,
	"dj_booth": 2.45,
	"wireless_mic": 0.0,
	"mic_stand": 0.0,
}
## Per-slot target LONGEST dimension in metres, keyed by the model's file stem (overnight props
## pass, 2026-11-27). A handheld wireless mic is sized by how long it is, not how tall, and it
## hangs off a hand bone whose space the rig's own `fit_height` factor has already scaled — so
## this mode measures in WORLD metres and divides that ancestor scale back out.
## `0.0`/absent keeps the height table above: no other slot changes behaviour.
const TARGET_LONGEST_M := {
	"wireless_mic": 0.24,
}
## Below this the measured AABB is treated as degenerate and no seating is attempted.
const SEAT_EPSILON := 0.0005

## Where the model lives, e.g. `res://assets/models/props/jamaican_speaker.glb`.
@export var model_path: String = ""
## Seat the delivered model on the sand and scale it to its target height (commit 6). Off leaves
## the export exactly as authored — position `place_transform`, delivered scale.
@export var auto_ground_y: bool = true
## Overrides the per-slot table for this slot when it is above 0.0. `0.0` uses the table.
@export var target_height_m: float = 0.0
## Transform applied to the instanced model inside this slot. Leave it at identity and use
## the slot node's own `position` / `rotation_degrees` / `scale` for placement; use this when
## the model's own pivot needs an offset that the slot's placement should not carry.
@export var place_transform: Transform3D = Transform3D.IDENTITY
## Marks a slot the scene cannot look finished without (the speakers, the booth). It changes
## nothing about loading — a required prop that is missing still draws nothing — it only makes
## the intent explicit for whoever drops the art in.
@export var required: bool = false
## Yaw about the model's own Y axis, in degrees (PART 3 commit 8). Positive turns the delivered
## +Z front toward +X. The left speaker slot runs +12° so its painted wall angles into the
## yard; the right slot would run −12°. Rotation only: a prop is never negative-scaled to
## mirror it, because that flips its winding and its normals.
@export var yaw_degrees: float = 0.0
## Keep the model's imported two-sided culling (PART 3 commit 8). The delivered
## `jamaican_speaker.glb` is an open shell — 2 626 of 5 240 edges are boundary edges and its
## glTF material is `doubleSided: true` — so it must not be forced onto the fighters'
## `cull_back` cel material. Off uses the standard toon material; on uses the `cull_disabled`
## variant of the same family.
@export var double_sided: bool = false
## Render the delivered model with its OWN imported materials instead of the fighters' cel
## shader (PART A step 3, 2026-11-26). The owner reported the tower looking "made by code":
## the cel pass quantised a 2048 px photographic albedo into a green poster, which is what a
## toon ramp does to photographic detail. On this path the albedo is kept, roughness is 1,
## metallic is 0, specular is off and the imported two-sided culling is preserved, with
## mipmaps and anisotropic filtering so 12 m of texture stops shimmering at distance.
@export var native_material: bool = false
## Which LOCAL axis of the delivered model the artwork faces: `"+z"`, `"-z"`, `"+x"` or
## `"-x"`. The arena camera looks along −Z from +Z, so a prop whose painted front is not +Z is
## turned to meet the stage by `front_yaw_degrees()`. Measured, not guessed: both delivered
## props were rendered from +Z, −Z, +X and −X before this was set.
@export var front_axis: StringName = &"+z"
## Owner override: flip the front 180° without re-exporting the model.
@export var front_flip: bool = false
## Overrides the per-slot longest-dimension table for this slot when it is above 0.0. `0.0`
## uses the table, which is what every slot except the mic does.
@export var target_longest_m: float = 0.0

## The instanced model, or null while the file is missing.
var model: Node3D = null
## Every `StandardMaterial3D` the native path built, so the stage can push its preset rim
## through one loop instead of walking the meshes again. Empty on the cel path.
var native_materials: Array[StandardMaterial3D] = []
## What the seating pass measured and applied, for the headless audit. `seat_scale` is 1.0 and
## `seat_offset_y` is 0.0 on an empty slot or when `auto_ground_y` is off.
var measured_aabb := AABB()
var seat_scale_applied: float = 1.0
var seat_offset_applied: float = 0.0


func _ready() -> void:
	load_model()


## Instantiate the prop if the file exists. Safe to call more than once.
## Returns true when a model is in the tree.
func load_model() -> bool:
	if is_instance_valid(model):
		return true
	if model_path == "":
		_missing("(no path set)")
		return false
	if not ResourceLoader.exists(model_path):
		_missing(model_path)
		return false
	var packed := load(model_path) as PackedScene
	if packed == null:
		_missing(model_path + " (not a PackedScene)")
		return false
	var instanced := packed.instantiate()
	if not (instanced is Node3D):
		push_warning("PropLoader: %s is not a 3D scene" % model_path)
		instanced.queue_free()
		return false
	var node := instanced as Node3D
	node.name = "Model"
	node.transform = place_transform
	add_child(node)
	model = node
	_seat_model(node)
	# Placement yaw (PART 3 commit 8): an aim, not a mirror. The seat pass above measured the
	# unturned box, and a Y rotation cannot change the model's height or its lowest vertex, so
	# the tower stays seated on Y = 0 at any yaw. The turn is the delivered front axis plus the
	# slot's own aim, so a prop painted on −Z faces the stage without a second export.
	var turn := front_yaw_degrees()
	if not is_zero_approx(turn):
		var turned := node.rotation_degrees
		node.rotation_degrees = Vector3(turned.x, turned.y + turn, turned.z)
	# Same cel/ink treatment the fighters and crowd wear, with a white tint and the shader's
	# shadow bias off, so the delivered albedo renders at full brightness. `apply_cel` skips
	# any surface the exporter left without a texture and warns about it; the model stays.
	if native_material:
		var native := _apply_native_materials(node)
		if native == 0:
			push_warning("PropLoader: %s has no surface to keep native" % model_path)
		return true
	var textured := CharacterModelSlots.apply_cel(node, Color.WHITE, Color.WHITE, 900, 0.0, "",
		double_sided)
	if textured == 0:
		push_warning("PropLoader: %s has no textured surface — left as imported" % model_path)
	return true


## PART M: the PBR values the whole beach set now wears (crisp PBR default). A painted
## wooden cabinet with a lacquered paper cone is matte with a broad, weak highlight: 0.55
## roughness, no metal, a 0.35 dielectric specular and a rim band that keeps the silhouette
## off the illustrated sky. All four are ordinary StandardMaterial3D fields — nothing here
## is a shader, so the Compatibility renderer draws the exact same surface.
const PBR_ROUGHNESS := 0.55
const PBR_SPECULAR := 0.35
const PBR_RIM_TINT := 0.85
const PBR_METALLIC := 0.0

## Keep the delivered look: one `StandardMaterial3D` per surface built from whatever the
## importer bound, with the physical values a printed speaker cabinet actually has. Returns
## the number of surfaces it touched.
func _apply_native_materials(root: Node3D) -> int:
	var touched := 0
	native_materials.clear()
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for surface in mi.mesh.get_surface_count():
			var source := mi.get_active_material(surface)
			var std := StandardMaterial3D.new()
			var albedo: Texture2D = null
			if source is BaseMaterial3D:
				albedo = (source as BaseMaterial3D).albedo_texture
			elif source is ShaderMaterial:
				var shader_tex = (source as ShaderMaterial).get_shader_parameter("albedo_texture")
				if shader_tex is Texture2D:
					albedo = shader_tex
			std.albedo_texture = albedo
			std.albedo_color = Color.WHITE
			# PART M (intentional change): the delivered surface used to be a fully diffuse
			# (roughness 1.0, specular disabled) card. It is now a tuned PBR material, which is
			# what makes the painted cabinets read as physical objects under the key light.
			std.roughness = PBR_ROUGHNESS
			std.metallic = PBR_METALLIC
			std.metallic_specular = PBR_SPECULAR
			std.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
			# Clean material rim: the same "lift the edge off the sky" band the fighters wear,
			# built into the material instead of a second shader pass.
			std.rim_enabled = true
			std.rim = PBR_RIM_TINT
			std.rim_tint = 0.30
			# Mipmaps + anisotropic: the tower is read at 6-12 m, where an unfiltered 2048
			# albedo aliases into noise on a Chromebook.
			std.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			if double_sided:
				std.cull_mode = BaseMaterial3D.CULL_DISABLED
			if not native_materials.has(std):
				native_materials.append(std)
			mi.set_surface_override_material(surface, std)
			# The tower is stage dressing: it must not write into the shadow map the
			# fighters' contact shadows are drawn from (the cel path relies on the
			# shared slab for this, the native path has to say it).
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			touched += 1
	return touched


## Push the stage preset's rim colour onto every native material this slot built. Albedo,
## roughness and the delivered texture are never touched, so the tower keeps its print.
func set_rim(colour: Color, strength: float) -> void:
	var band := clampf(PBR_RIM_TINT * strength, 0.0, 1.0)
	for material in native_materials:
		# Godot 4's StandardMaterial3D carries the rim as an AMOUNT (`rim`) plus an
		# albedo-bleed factor (`rim_tint`); the colour argument is kept in the signature
		# because the toon path does use it, and the PBR band is a white edge.
		material.rim_enabled = band > 0.0
		material.rim = clampf(band, 0.0, 1.0)
		material.rim_tint = 0.30


## True while the slot is empty. Used by the headless check and the tree dump.
func is_empty() -> bool:
	return not is_instance_valid(model)


## The target height this slot resolves to: the export override when above zero, else the
## per-slot table entry, else 0.0 (keep the delivered scale).
func resolved_target_height() -> float:
	if target_height_m > 0.0:
		return target_height_m
	return target_height_for(model_path)


## The target longest dimension in metres: the export override, else the per-slot table entry,
## else 0.0 (height mode).
func resolved_target_longest() -> float:
	if target_longest_m > 0.0:
		return target_longest_m
	return float(TARGET_LONGEST_M.get(model_path.get_file().get_basename(), 0.0))


## Total yaw this slot applies to the model: the delivered front turned to +Z, the owner flip,
## then the slot's own aim. Degrees, all about the model's Y axis.
func front_yaw_degrees() -> float:
	var yaw := 0.0
	match front_axis:
		&"-z":
			yaw = 180.0
		&"+x":
			yaw = -90.0
		&"-x":
			yaw = 90.0
		_:
			yaw = 0.0
	if front_flip:
		yaw += 180.0
	return yaw + yaw_degrees


## Table lookup by file stem, so a slot never has to repeat its height.
static func target_height_for(path: String) -> float:
	return float(TARGET_HEIGHT_M.get(path.get_file().get_basename(), 0.0))


## Uniform scale that brings a model of `box.size.y` to `target_height`. Data only: no mesh,
## no scene, no node. 1.0 when the height is 0 (keep native scale) or the box is degenerate.
static func seat_scale_for(box: AABB, target_height: float) -> float:
	if target_height <= 0.0 or box.size.y <= SEAT_EPSILON:
		return 1.0
	return target_height / box.size.y


## The Y offset that puts the box's lowest vertex on the ground after a uniform scale about
## the model's own origin. Meshy exports arrive with a centred origin, so `box.position.y` is
## negative for a standing prop and this lifts it by exactly that much.
static func seat_offset_y(box: AABB, uniform_scale: float) -> float:
	return -box.position.y * uniform_scale


## Uniform scale that brings the model's LONGEST axis to `target_longest` metres. `box` is in
## slot-local units and `world_scale` is how many metres one of those units is worth, so a prop
## hanging off a scaled rig still ends up the size a hand can hold. 1.0 on a 0.0 target or a
## degenerate box.
static func longest_scale_for(box: AABB, target_longest: float, world_scale: float) -> float:
	if target_longest <= 0.0 or world_scale <= SEAT_EPSILON:
		return 1.0
	var longest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	if longest <= SEAT_EPSILON:
		return 1.0
	return target_longest / (longest * world_scale)


## One measure-then-place pass at load: uniform scale to the target height, then the lowest
## vertex flushed to Y = 0.0. The AABB is measured once, from the real meshes, in the slot's
## local space; nothing here runs per frame.
func _seat_model(node: Node3D) -> void:
	measured_aabb = _local_mesh_bounds(node)
	if measured_aabb.size == Vector3.ZERO:
		return
	var longest := resolved_target_longest()
	var s := seat_scale_for(measured_aabb, resolved_target_height()) if longest <= 0.0 \
		else longest_scale_for(measured_aabb, longest, inherited_scale(node))
	if not is_equal_approx(s, 1.0):
		node.scale = node.scale * s
	seat_scale_applied = s
	if auto_ground_y:
		var p := node.position
		p.y += seat_offset_y(measured_aabb, s)
		node.position = p
		seat_offset_applied = seat_offset_y(measured_aabb, s)


## Metres per slot-local unit, taken from the scale the slot inherits from its ancestors. A
## hand prop hangs off a Mixamo rig that `CharacterModelSlots.fit_height()` has already scaled
## (a centimetre export lands near 0.01), so a measurement in slot-local units is not a
## measurement in metres. 1.0 when the chain is unscaled.
func inherited_scale(node: Node3D) -> float:
	var scale := node.global_transform.basis.get_scale()
	var mean := (scale.x + scale.y + scale.z) / 3.0
	return mean if mean > SEAT_EPSILON else 1.0


## Union of the model's mesh boxes in this slot's local space.
func _local_mesh_bounds(node: Node3D) -> AABB:
	var out := AABB()
	var first := true
	var to_local := node.global_transform.affine_inverse()
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		var box: AABB = (to_local * mi.global_transform) * mi.mesh.get_aabb()
		out = box if first else out.merge(box)
		first = false
	return out


## Lowest point of the seated model in slot space (0.0 when empty).
func seated_bottom() -> float:
	if measured_aabb.size == Vector3.ZERO:
		return 0.0
	return measured_aabb.position.y * seat_scale_applied + seat_offset_applied


## Height the seated model ends up with, after the uniform scale.
func seated_height() -> float:
	return measured_aabb.size.y * seat_scale_applied


func _missing(what: String) -> void:
	push_warning("PropLoader: missing %s" % what)
