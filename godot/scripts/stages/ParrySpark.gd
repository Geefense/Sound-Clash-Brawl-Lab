class_name ParrySpark
extends Node2D
## Electric vinyl-static spark for a Record Static Parry (AGENTS.md §9 item 13).
## Presentation only: drawn with primitives, no texture, no combat effect.

const DURATION := 0.38

var _life: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	z_index = 12
	_phase = randf() * TAU


func _process(delta: float) -> void:
	_life += delta
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var t := clampf(_life / DURATION, 0.0, 1.0)
	var fade := 1.0 - t
	# Two expanding static rings.
	for ring in 2:
		var radius := 10.0 + (44.0 + ring * 16.0) * t
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28,
			Color(0.72, 0.94, 1.0, fade * (0.8 if ring == 0 else 0.45)), 2.0)
	# Crackling spokes.
	for i in 6:
		var ang := _phase + float(i) * TAU / 6.0 + t * 1.6
		var dir := Vector2(cos(ang), sin(ang))
		var from := dir * (8.0 + 10.0 * t)
		var to := dir * (30.0 + 26.0 * t)
		draw_line(from, to, Color(1.0, 1.0, 1.0, fade * 0.95), 1.6)
		draw_line(from.orthogonal() * 0.2, to - dir * 6.0,
			Color(0.85, 0.97, 1.0, fade * 0.6), 1.0)
	# Vinyl disc hint under the static.
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(0.08, 0.08, 0.1, fade * 0.75), 3.0)
	draw_circle(Vector2.ZERO, 3.0, Color(0.95, 0.85, 0.35, fade))
