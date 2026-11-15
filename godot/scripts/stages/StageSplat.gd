class_name StageSplat
extends Node2D
## Comedic bird splatter decal (AGENTS.md §9: rare bird interference).
##
## Presentation only: it never touches combat state. Parented to a fighter it rides
## along at head height; parented to the stage it sits on the sand. Holds at full
## opacity, then fades out and frees itself.

@export var radius: float = 18.0
@export var life_sec: float = 4.5
@export var hold_ratio: float = 0.55

var _life: float = 0.0
var _blobs: Array[Dictionary] = []


func _ready() -> void:
	_life = maxf(life_sec, 0.1)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 5 + rng.randi() % 3:
		var angle := rng.randf() * TAU
		var offset := Vector2(cos(angle), sin(angle) * 0.55) * rng.randf_range(0.0, radius * 0.8)
		_blobs.append({
			"offset": offset,
			"r": rng.randf_range(radius * 0.26, radius * 0.6),
		})
	queue_redraw()


func _process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	var fade_from := maxf(life_sec * (1.0 - hold_ratio), 0.1)
	modulate.a = clampf(_life / fade_from, 0.0, 1.0)


func _draw() -> void:
	var rim := Color(0.90, 0.87, 0.74, 0.5)
	var body := Color(0.99, 0.98, 0.93, 0.82)
	for b in _blobs:
		var o: Vector2 = b["offset"]
		draw_circle(o, float(b["r"]) * 1.2, rim)
	for b in _blobs:
		var o: Vector2 = b["offset"]
		draw_circle(o, float(b["r"]), body)
