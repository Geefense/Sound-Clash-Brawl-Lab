class_name ImpactFrame
extends Node2D
## Black-and-gold comic impact frame (AGENTS.md §9 item 41, 2026-11-20).
##
## Three frames of high-contrast ink on a big counter-hit or a 100 % Hype Surge, then a fast
## fade. Fatal Fury / Marvel Tōkon presentation: the contact is punctuated by a graphic
## frame instead of only a particle burst.
##
## WebGL2 safety: a full-rect fill plus one 24-point polygon and ten lines, for about 0.1 s,
## at most one instance alive at a time. It follows the camera's visible rect, so it covers
## the frame at any zoom, and it sits at z 30 — above BirdHazard, below the HUD CanvasLayer.

const HOLD: float = 0.05        # ~3 frames at 60 Hz, the "impact frame"
const FADE: float = 0.055

## `counter` = the black-and-gold counter-hit frame; `surge` = the 100 % Hype Surge burst.
@export var kind: StringName = &"counter"
@export var facing: int = 1

var _life: float = 0.0
var _phase: float = 0.0
var _screen: Vector2 = Vector2(1280.0, 720.0)
var _centre: Vector2 = Vector2(640.0, 360.0)


func _ready() -> void:
	top_level = true
	z_index = 30
	_phase = randf() * TAU
	_update_screen()
	queue_redraw()


func _update_screen() -> void:
	var vp := get_viewport()
	var vs := get_viewport_rect().size
	var cam: Camera2D = vp.get_camera_2d() if vp != null else null
	if cam == null:
		_screen = vs
		global_position = Vector2.ZERO
	else:
		var zoom := Vector2(maxf(cam.zoom.x, 0.01), maxf(cam.zoom.y, 0.01))
		_screen = vs / zoom
		global_position = cam.get_screen_center_position() - _screen * 0.5
	_centre = _screen * 0.5


func _process(delta: float) -> void:
	_life += delta
	_update_screen()
	queue_redraw()
	if _life >= HOLD + FADE:
		queue_free()


func _draw() -> void:
	var fade := 1.0 if _life <= HOLD else clampf(1.0 - (_life - HOLD) / FADE, 0.0, 1.0)
	if fade <= 0.01:
		return
	var gold := Color(1.0, 0.80, 0.24)
	if kind == &"surge":
		gold = Color(0.42, 0.96, 1.0).lerp(Color(1.0, 0.45, 0.95), 0.5)

	# The ink frame: the whole view goes near-black for three frames.
	draw_rect(Rect2(Vector2.ZERO, _screen), Color(0.02, 0.01, 0.02, 0.72 * fade))

	# Gold star burst centred on the contact.
	var points := PackedVector2Array()
	var spokes := 12
	for i in spokes * 2:
		var ang := _phase + float(i) * PI / float(spokes)
		var radius := _screen.y * (0.54 if i % 2 == 0 else 0.18)
		radius *= 0.86 + 0.14 * sin(_phase + float(i))
		points.append(_centre + Vector2(cos(ang), sin(ang)) * radius)
	draw_colored_polygon(points, Color(gold.r, gold.g, gold.b, 0.30 * fade))

	# Radial speed lines driving out of the contact.
	for i in 10:
		var ang := _phase + float(i) * TAU / 10.0 + 0.15
		var dir := Vector2(cos(ang), sin(ang))
		draw_line(_centre + dir * _screen.y * 0.20, _centre + dir * _screen.y * 0.78,
			Color(gold.r, gold.g, gold.b, 0.48 * fade), 3.0)

	# A black band along the bottom keeps the frame graphic rather than washed-out.
	draw_rect(Rect2(0.0, _screen.y * 0.88, _screen.x, _screen.y * 0.12),
		Color(0.0, 0.0, 0.0, 0.55 * fade))
