class_name ParrySpark
extends Node2D
## Electric vinyl-static spark for a Record Static Parry (AGENTS.md §9 item 13).
## Presentation only: drawn with primitives, no texture, no combat effect.

const DURATION := 0.38
const HIT_DURATION := 0.24

## `parry` = electric vinyl static (Record Static Parry / throw break).
## `hit` = white/gold contact burst. `hit_onbeat` = green/gold contact judged on the beat.
## AGENTS.md §9 item 21 (closes backlog item B4). Same primitive-only drawing and the same
## 4-spark cap, so no new texture group and no extra export weight.
@export var style: StringName = &"parry"

var _life: float = 0.0
var _phase: float = 0.0
var _duration: float = DURATION


func _ready() -> void:
	z_index = 12
	_phase = randf() * TAU
	if style != &"parry":
		_duration = HIT_DURATION


func _process(delta: float) -> void:
	_life += delta
	queue_redraw()
	if _life >= _duration:
		queue_free()


func _draw() -> void:
	if style != &"parry":
		_draw_hit_burst()
		return
	var t := clampf(_life / _duration, 0.0, 1.0)
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


## Contact burst for a resolved strike: a crisp four-point star, a fast ring and six shards.
## White/gold for a normal contact, vibrant green/gold when the **input** was on the beat
## (§9 item 1 — the beat judges the input, not the contact). No texture, no shader.
func _draw_hit_burst() -> void:
	var t := clampf(_life / _duration, 0.0, 1.0)
	var fade := 1.0 - t
	var on_beat := style == &"hit_onbeat"
	var core := Color(0.36, 1.0, 0.46) if on_beat else Color(1.0, 0.99, 0.92)
	var warm := Color(1.0, 0.86, 0.28) if on_beat else Color(1.0, 0.86, 0.45)

	# Tight ring that snaps outward in the first third of the life.
	var ring := 8.0 + 34.0 * sqrt(t)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 20, Color(core.r, core.g, core.b, fade * 0.75), 2.0)

	# Four-point star, longest along the impact axis.
	var long := (34.0 if on_beat else 28.0) * (0.45 + 0.55 * fade)
	var short := long * 0.36
	for i in 4:
		var ang := _phase + float(i) * TAU / 4.0
		var dir := Vector2(cos(ang), sin(ang))
		var side := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([
			dir * long,
			side * short,
			-dir * short * 0.5,
			-side * short,
		]), Color(core.r, core.g, core.b, fade * (0.9 if i % 2 == 0 else 0.55)))

	# Star shards flying clear of the star.
	for i in 6:
		var ang := _phase + float(i) * TAU / 6.0 + 0.4
		var dir := Vector2(cos(ang), sin(ang))
		var from := dir * (14.0 + 22.0 * t)
		var to := from + dir * (7.0 + 9.0 * fade)
		draw_line(from, to, Color(warm.r, warm.g, warm.b, fade * 0.85), 1.8)

	# Hot centre, so the contact point stays readable at 1× zoom.
	draw_circle(Vector2.ZERO, 4.5 + 3.0 * fade, Color(warm.r, warm.g, warm.b, fade))
