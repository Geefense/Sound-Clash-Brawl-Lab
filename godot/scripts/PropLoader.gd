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
const TARGET_HEIGHT_M := {
	"jamaican_speaker": 2.6,
	"rasta_speaker": 2.6,
	"dj_booth": 1.15,
	"wireless_mic": 0.0,
	"mic_stand": 0.0,
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

## The instanced model, or null while the file is missing.
var model: Node3D = null
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
	# the tower stays seated on Y = 0 at any yaw.
	if not is_zero_approx(yaw_degrees):
		var turned := node.rotation_degrees
		node.rotation_degrees = Vector3(turned.x, turned.y + yaw_degrees, turned.z)
	# Same cel/ink treatment the fighters and crowd wear, with a white tint and the shader's
	# shadow bias off, so the delivered albedo renders at full brightness. `apply_cel` skips
	# any surface the exporter left without a texture and warns about it; the model stays.
	var textured := CharacterModelSlots.apply_cel(node, Color.WHITE, Color.WHITE, 900, 0.0, "",
		double_sided)
	if textured == 0:
		push_warning("PropLoader: %s has no textured surface — left as imported" % model_path)
	return true


## True while the slot is empty. Used by the headless check and the tree dump.
func is_empty() -> bool:
	return not is_instance_valid(model)


## The target height this slot resolves to: the export override when above zero, else the
## per-slot table entry, else 0.0 (keep the delivered scale).
func resolved_target_height() -> float:
	if target_height_m > 0.0:
		return target_height_m
	return target_height_for(model_path)


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


## One measure-then-place pass at load: uniform scale to the target height, then the lowest
## vertex flushed to Y = 0.0. The AABB is measured once, from the real meshes, in the slot's
## local space; nothing here runs per frame.
func _seat_model(node: Node3D) -> void:
	measured_aabb = _local_mesh_bounds(node)
	if measured_aabb.size == Vector3.ZERO:
		return
	var target := resolved_target_height()
	var s := seat_scale_for(measured_aabb, target)
	if not is_equal_approx(s, 1.0):
		node.scale = node.scale * s
	seat_scale_applied = s
	if auto_ground_y:
		var p := node.position
		p.y += seat_offset_y(measured_aabb, s)
		node.position = p
		seat_offset_applied = seat_offset_y(measured_aabb, s)


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
