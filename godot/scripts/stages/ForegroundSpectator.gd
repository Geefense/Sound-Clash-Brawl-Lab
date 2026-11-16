class_name ForegroundSpectator
extends Node2D
## One cropped, near-camera spectator in the bottom-left corner (AGENTS.md §9 item 21).
##
## The reference footage sells "public showdown" by putting a spectator *in front of* the
## camera, cropped by the frame edge, on top of the crowd behind the fight. That is the
## fifth depth plane this arena was missing.
##
## Lives in its own `CanvasLayer` (layer 1, below the HUD's) so the tracking camera never
## drags or scales it — it behaves like the corner of a camera lens, not a stage prop.
## Drawn with primitives only: no texture, no export weight, alpha 0.85.

const ALPHA := 0.85
const BODY := Color(0.055, 0.065, 0.085, ALPHA)
const BODY_SOFT := Color(0.075, 0.086, 0.110, ALPHA)
const RIM := Color(1.0, 0.86, 0.52, 0.22)      # warm stage light catching the hat brim
const HAT_CROWN := Color(0.040, 0.048, 0.062, ALPHA)


func _ready() -> void:
	z_index = 10
	queue_redraw()


func _draw() -> void:
	# Local space: x 0–300, y 0–280, with y = 0 at the top of the hat. The node sits low
	# enough (TestArena.tscn) that only the hat and shoulders are in frame.
	# Shoulder mass, cropped by both screen edges.
	var shoulders := PackedVector2Array([
		Vector2(-8.0, 280.0),
		Vector2(-8.0, 176.0),
		Vector2(38.0, 132.0),
		Vector2(104.0, 104.0),
		Vector2(150.0, 96.0),
		Vector2(196.0, 104.0),
		Vector2(252.0, 128.0),
		Vector2(304.0, 170.0),
		Vector2(308.0, 280.0),
	])
	draw_colored_polygon(shoulders, BODY)
	# A faintly lighter front shoulder so the mass is not one flat silhouette.
	var front := PackedVector2Array([
		Vector2(150.0, 96.0),
		Vector2(196.0, 104.0),
		Vector2(252.0, 128.0),
		Vector2(304.0, 170.0),
		Vector2(308.0, 280.0),
		Vector2(214.0, 280.0),
		Vector2(206.0, 150.0),
		Vector2(166.0, 112.0),
	])
	draw_colored_polygon(front, BODY_SOFT)
	# Neck and head.
	draw_rect(Rect2(152.0, 62.0, 44.0, 44.0), BODY)
	draw_circle(Vector2(174.0, 40.0), 35.0, BODY)
	# Bucket hat: brim plus a truncated crown, the same silhouette Feedback wears.
	draw_colored_polygon(PackedVector2Array([
		Vector2(118.0, 22.0),
		Vector2(230.0, 22.0),
		Vector2(242.0, 34.0),
		Vector2(108.0, 34.0),
	]), HAT_CROWN)
	draw_colored_polygon(PackedVector2Array([
		Vector2(144.0, 24.0),
		Vector2(204.0, 24.0),
		Vector2(198.0, 0.0),
		Vector2(150.0, 0.0),
	]), HAT_CROWN)
	# Rim light along the brim and the crown's forward edge.
	draw_line(Vector2(110.0, 33.0), Vector2(240.0, 33.0), RIM, 1.8)
	draw_line(Vector2(196.0, 3.0), Vector2(203.0, 23.0), RIM, 1.4)
	# One raised forearm at the edge, as if holding a drink up out of frame.
	draw_colored_polygon(PackedVector2Array([
		Vector2(284.0, 150.0),
		Vector2(300.0, 146.0),
		Vector2(308.0, 214.0),
		Vector2(292.0, 218.0),
	]), BODY)
