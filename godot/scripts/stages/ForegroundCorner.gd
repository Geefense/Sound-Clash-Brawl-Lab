class_name ForegroundCorner
extends Node2D
## Soft shadow wash behind the near-camera spectator (AGENTS.md §9 item 22).
##
## The flat hat-and-shoulders primitive that used to live here looked like cardboard next to
## the illustrated crowd, so the corner is now carried by a real darkened sprite
## (`Foreground/BottomCard`, an existing crowd texture) standing on this wash. The wash just
## grounds that card: a radial darkening in the bottom-left of the *screen*, so the card has
## something to sit in instead of being pasted onto bright sand.
##
## Screen space, in its own `CanvasLayer` (layer 1, below the HUD), so the tracking camera
## never drags or scales it. Primitives only.

const CORNER := Vector2(10.0, 726.0)      # bottom-left of the 1280 × 720 logical viewport
const STEPS := 14

@export var radius: float = 430.0
@export var strength: float = 0.36
@export var tint: Color = Color(0.03, 0.035, 0.055, 1.0)


func _ready() -> void:
	z_index = 9                            # the sprite card sits at 10, above this
	queue_redraw()


func _draw() -> void:
	for i in STEPS:
		var t := float(i) / float(STEPS - 1)
		var r := radius * (1.0 - t * 0.92)
		var a := strength * pow(1.0 - t, 2.0) * 0.42
		draw_circle(CORNER, r, Color(tint.r, tint.g, tint.b, a))
