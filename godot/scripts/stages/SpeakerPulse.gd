class_name SpeakerPulse
extends Node2D
## 132 BPM speaker thump (AGENTS.md §9 elite stage polish).
##
## On each BeatService downbeat the two speaker stacks breathe one soft ring.
## Ring centres are measured from the stage art in its 1280x720 export:
## left stack subwoofers (169, 411), right stack lion cabs (1099, 425).
## Presentation only; it draws behind the fighters so the lane stays readable.

@export var centres: PackedVector2Array = PackedVector2Array([
	Vector2(169, 411),
	Vector2(1099, 425),
])
@export var ring_colour: Color = Color(1.0, 0.92, 0.68, 0.24)
@export var min_radius: float = 12.0
@export var max_radius: float = 78.0
@export var decay: float = 3.4

var _pulse: float = 0.0


func _ready() -> void:
	set_process(false)


func pulse(strength: float = 1.0) -> void:
	set_process(true)
	_pulse = maxf(_pulse, clampf(strength, 0.25, 1.0))
	queue_redraw()


func _process(delta: float) -> void:
	_pulse = maxf(0.0, _pulse - delta * maxf(decay, 0.01))
	if _pulse <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if _pulse <= 0.0:
		return
	var phase := 1.0 - _pulse
	for centre in centres:
		var r := lerpf(min_radius, max_radius, phase)
		var tint := Color(ring_colour.r, ring_colour.g, ring_colour.b, ring_colour.a * _pulse)
		draw_circle(centre, r, Color(tint.r, tint.g, tint.b, tint.a * 0.3))
		draw_arc(centre, r, 0.0, TAU, 48, tint, 2.5, true)
