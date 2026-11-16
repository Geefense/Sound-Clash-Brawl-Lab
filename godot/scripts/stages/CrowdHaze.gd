class_name CrowdHaze
extends Node2D
## Cool atmospheric wash over the crowd band only (AGENTS.md §9 item 22).
##
## The reference footage separates the fight from the onlookers with haze, not blur: the
## crowd sits a value step back and loses a little saturation, while the fighters keep full
## contrast. This draws that step — a soft blue wash over y 404–566 with a sine falloff at
## both edges, so it has no visible seam — and nothing else. It sits at **z −4**: above the
## crowd rows (−5 / −6), below the `YardBarrier` (also −4, but declared after this node) and
## far below the fighters (0).
##
## Presentation only. No texture, no shader, no particles: twelve `draw_rect` calls once.

@export var band_top: float = 404.0
@export var band_bottom: float = 566.0
@export var wash_colour: Color = Color(0.47, 0.60, 0.87, 1.0)
@export var wash_alpha: float = 0.26
@export var steps: int = 12


func _ready() -> void:
	z_index = -4
	queue_redraw()


func _draw() -> void:
	var height := band_bottom - band_top
	if height <= 0.0 or steps <= 0:
		return
	var slice := height / float(steps)
	for i in steps:
		var t := (float(i) + 0.5) / float(steps)
		# sin() gives 0 at both edges and 1 in the middle: a soft band, not a box.
		var falloff := sin(PI * t)
		draw_rect(
			Rect2(-8.0, band_top + slice * float(i), 1296.0, slice + 1.0),
			Color(wash_colour.r, wash_colour.g, wash_colour.b, wash_alpha * falloff))
