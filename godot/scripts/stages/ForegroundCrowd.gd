class_name ForegroundCrowd
extends Node2D
## Foreground clash crowd (AGENTS.md §9 item 41, 2026-11-20).
##
## The camera now sits *inside* the packed yard: a darkened, out-of-focus band of heads,
## raised hands, waving rags and the odd flickering lighter runs along the very bottom of the
## frame, in front of the fighters (z 8 > fighter 0, below BirdHazard 20 and ImpactFrame 30).
##
## It is drawn from primitives — no sprite sheet, no shader, no texture — so it costs the same
## at 1.0× and 1.12× zoom and adds nothing to the Web export. `top_level` plus a per-frame
## visible-rect read keeps it pinned to the bottom screen edge at any camera zoom, which is
## what makes it read as the near side of the crowd rather than scenery at a fixed y.
##
## Presentation only: it reads no fighter state and never touches the simulation.

@export var figure_count: int = 11
## How far the heads reach up from the bottom edge, in screen pixels.
@export var band_height: float = 108.0
## 0 = off (the vendor truck is hidden at Afternoon), 1 = full foreground stack.
@export var intensity: float = 1.0
@export var seed_value: int = 20261120

const HAIR := Color(0.03, 0.02, 0.05)
const SHOULDER := Color(0.055, 0.04, 0.075)

var _time: float = 0.0
var _sunset: float = 0.0
var _night: float = 0.0
var _screen: Vector2 = Vector2(1280.0, 720.0)
var _figures: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	top_level = true
	z_index = 8
	_rng.seed = seed_value
	_build_figures()
	_update_screen()
	queue_redraw()


func _build_figures() -> void:
	_figures.clear()
	for i in figure_count:
		var roll := _rng.randf()
		var act := "hands"
		if roll < 0.34:
			act = "lighter"
		elif roll < 0.60:
			act = "rag"
		_figures.append({
			"x": _rng.randf_range(0.02, 0.98),
			"scale": _rng.randf_range(0.82, 1.28),
			"phase": _rng.randf_range(0.0, TAU),
			"rate": _rng.randf_range(0.55, 1.20),
			"act": act,
			"lit": act == "lighter",
			"timer": _rng.randf_range(1.0, 4.5),
		})


## `sunset` / `night` are the stage's 0–1 phase weights: the near-crowd rim runs gold at
## Sunset, cold cyan at Night, with a magenta spill under the festival lights.
func set_phase(sunset: float, night: float) -> void:
	_sunset = clampf(sunset, 0.0, 1.0)
	_night = clampf(night, 0.0, 1.0)
	queue_redraw()


func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.5)
	visible = intensity > 0.01
	queue_redraw()


## How many foreground lighters are currently up. The headless check asserts at least one, so
## the "Lightah!" silhouette never disappears entirely.
func lighter_count() -> int:
	var lit := 0
	for f in _figures:
		if String(f["act"]) == "lighter" and bool(f["lit"]):
			lit += 1
	return lit


func lighter_slots() -> int:
	var slots := 0
	for f in _figures:
		if String(f["act"]) == "lighter":
			slots += 1
	return slots


func screen_size() -> Vector2:
	return _screen


## Pin the band to the camera's visible rect. Called every frame: the zoom can breathe, and
## the near-crowd must never drift away from the bottom edge.
func _update_screen() -> void:
	var vp := get_viewport()
	var vs := get_viewport_rect().size
	var cam: Camera2D = vp.get_camera_2d() if vp != null else null
	if cam == null:
		_screen = vs
		global_position = Vector2.ZERO
		return
	var zoom := Vector2(maxf(cam.zoom.x, 0.01), maxf(cam.zoom.y, 0.01))
	var visible := vs / zoom
	_screen = visible
	global_position = cam.get_screen_center_position() - visible * 0.5


func _process(delta: float) -> void:
	if intensity <= 0.01:
		return
	_time += delta
	_update_screen()
	for f in _figures:
		if String(f["act"]) != "lighter":
			continue
		# A lighter goes up, burns for a few seconds, gutters out, comes back: the timing is
		# seeded per person so the band never flickers in unison.
		f["timer"] = float(f["timer"]) - delta
		if float(f["timer"]) <= 0.0:
			f["lit"] = not bool(f["lit"])
			f["timer"] = _rng.randf_range(1.2, 3.8) if bool(f["lit"]) else _rng.randf_range(0.8, 4.6)
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.01:
		return
	var rim := Color(1.0, 0.82, 0.44).lerp(Color(0.40, 0.94, 1.0), _night)
	rim = rim.lerp(Color(1.0, 0.52, 0.88), _night * 0.45)
	var haze := Color(0.05, 0.04, 0.08, 0.20 * intensity)
	var body := Color(SHOULDER.r, SHOULDER.g, SHOULDER.b, 0.90 * intensity)
	var head := Color(HAIR.r, HAIR.g, HAIR.b, 0.93 * intensity)
	# A soft dark gradient along the bottom edge sells the out-of-focus stack.
	draw_rect(Rect2(0.0, _screen.y - 26.0, _screen.x, 30.0), haze)
	for f in _figures:
		_draw_figure(f, body, head, rim)


func _draw_figure(f: Dictionary, body: Color, head: Color, rim: Color) -> void:
	var s: float = float(f["scale"])
	var x: float = float(f["x"]) * _screen.x
	var rate: float = float(f["rate"])
	var phase: float = float(f["phase"])
	var bob := sin(_time * rate * 1.7 + phase) * 4.5
	var ground := _screen.y + 34.0
	var head_y := _screen.y - band_height * 0.20 + bob - (s - 0.85) * 34.0
	var head_r := 15.0 * s
	var body_w := 60.0 * s

	# Out-of-focus halo: a wider, much fainter copy behind every solid shape.
	draw_circle(Vector2(x, head_y), head_r * 1.65, Color(body.r, body.g, body.b, 0.22 * intensity))

	var torso := PackedVector2Array([
		Vector2(x - body_w * 0.50, ground),
		Vector2(x - body_w * 0.34, head_y + head_r * 1.15),
		Vector2(x + body_w * 0.34, head_y + head_r * 1.15),
		Vector2(x + body_w * 0.50, ground),
	])
	draw_colored_polygon(torso, body)
	draw_circle(Vector2(x, head_y), head_r, head)

	# Rim light catches the crown and the near shoulder only: enough to separate the
	# silhouette from the fighters, never enough to read as a second crowd row.
	draw_circle(Vector2(x - head_r * 0.28, head_y - head_r * 0.30), head_r * 0.58,
		Color(rim.r, rim.g, rim.b, 0.17 * intensity))
	var shoulder_y := head_y + head_r * 1.15
	draw_line(Vector2(x - body_w * 0.30, shoulder_y), Vector2(x - body_w * 0.12, shoulder_y),
		Color(rim.r, rim.g, rim.b, 0.14 * intensity), 2.0)

	var act := String(f["act"])
	var sway := sin(_time * rate * 2.3 + phase)
	if act == "rag":
		_draw_rag(x, head_y - head_r * 1.6, s, sway, rim)
	elif act == "lighter":
		_draw_raised_arms(x, head_y, s, sway, head)
		if bool(f["lit"]):
			_draw_lighter(Vector2(x + body_w * 0.30, head_y - head_r * 1.15), s, phase)
	else:
		_draw_raised_arms(x, head_y, s, sway, head)


## Two arms up, hands bobbing independently — the universal "forward!" yard gesture.
func _draw_raised_arms(x: float, head_y: float, s: float, sway: float, head: Color) -> void:
	for side in [-1.0, 1.0]:
		var hand := Vector2(x + side * (26.0 * s + sway * 3.0),
			head_y - 30.0 * s + sway * side * 5.0)
		draw_line(Vector2(x + side * 16.0 * s, head_y + 20.0 * s), hand,
			Color(head.r, head.g, head.b, head.a * 0.92), 3.4 * s)
		draw_circle(hand, 4.2 * s, head)


## A waving rag: a parallelogram whose far corners follow the sway.
func _draw_rag(x: float, y: float, s: float, sway: float, rim: Color) -> void:
	draw_line(Vector2(x, y + 10.0 * s), Vector2(x + 20.0 * s, y - 6.0 * s),
		Color(rim.r, rim.g, rim.b, 0.55 * intensity), 3.0 * s)
	var cloth := PackedVector2Array([
		Vector2(x + 20.0 * s, y - 6.0 * s),
		Vector2(x + 52.0 * s + sway * 6.0, y - 26.0 * s + sway * 3.0),
		Vector2(x + 46.0 * s + sway * 6.0, y - 4.0 * s + sway * 3.0),
		Vector2(x + 22.0 * s, y + 8.0 * s),
	])
	draw_colored_polygon(cloth, Color(rim.r, rim.g, rim.b, 0.24 * intensity))


## A flickering lighter flame: a warm teardrop plus a bright core.
func _draw_lighter(at: Vector2, s: float, phase: float) -> void:
	var flicker := 0.72 + 0.28 * sin(_time * 17.0 + phase) * sin(_time * 6.3 + phase * 2.0)
	var h := 13.0 * s * flicker
	draw_circle(at + Vector2(0.0, -h * 0.25), h * 0.55, Color(1.0, 0.58, 0.16, 0.80 * intensity))
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-h * 0.30, 0.0),
		at + Vector2(h * 0.30, 0.0),
		at + Vector2(0.0, -h),
	]), Color(1.0, 0.86, 0.38, 0.86 * intensity))
	draw_circle(at + Vector2(0.0, -h * 0.30), h * 0.22, Color(1.0, 0.98, 0.86, 0.92 * intensity))
