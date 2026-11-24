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

## Where the model lives, e.g. `res://assets/models/props/jamaican_speaker.glb`.
@export var model_path: String = ""
## Transform applied to the instanced model inside this slot. Leave it at identity and use
## the slot node's own `position` / `rotation_degrees` / `scale` for placement; use this when
## the model's own pivot needs an offset that the slot's placement should not carry.
@export var place_transform: Transform3D = Transform3D.IDENTITY
## Marks a slot the scene cannot look finished without (the speakers, the booth). It changes
## nothing about loading — a required prop that is missing still draws nothing — it only makes
## the intent explicit for whoever drops the art in.
@export var required: bool = false

## The instanced model, or null while the file is missing.
var model: Node3D = null


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
	# Same cel/ink treatment the fighters and crowd wear, with a white tint and the shader's
	# shadow bias off, so the delivered albedo renders at full brightness. `apply_cel` skips
	# any surface the exporter left without a texture and warns about it; the model stays.
	var textured := CharacterModelSlots.apply_cel(node, Color.WHITE, Color.WHITE, 900)
	if textured == 0:
		push_warning("PropLoader: %s has no textured surface — left as imported" % model_path)
	return true


## True while the slot is empty. Used by the headless check and the tree dump.
func is_empty() -> bool:
	return not is_instance_valid(model)


func _missing(what: String) -> void:
	push_warning("PropLoader: missing %s" % what)
