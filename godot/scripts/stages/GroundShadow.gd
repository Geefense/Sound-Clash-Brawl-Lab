class_name GroundShadow
extends Node2D
## Soft contact shadow under one fighter's feet (AGENTS.md §9 elite stage polish).
##
## `top_level` keeps it in world space, so it stays glued to the sand while the
## fighter is airborne and shrinks/fades with jump height. Presentation only.

@export var ground_y: float = 600.0
@export var radius: float = 32.0
@export var squash: float = 0.32
@export var jump_apex_height: float = 178.0
@export var air_shrink: float = 0.6
@export var air_fade: float = 0.35
## Belt-and-braces contrast knob (AGENTS.md §9 item 22): multiplies the shadow's opacity so
## the fighters can sit on a heavier grounded contact shadow without a second draw pass.
@export var strength: float = 1.0


func _ready() -> void:
	top_level = true


func _process(_delta: float) -> void:
	var fighter := get_parent() as Node2D
	if fighter == null:
		return
	var air := clampf((ground_y - fighter.global_position.y) / maxf(jump_apex_height, 1.0), 0.0, 1.0)
	global_position = Vector2(fighter.global_position.x, ground_y)
	var shrink := lerpf(1.0, air_shrink, air)
	scale = Vector2(shrink, shrink * squash)
	modulate.a = lerpf(1.0, air_fade, air)


func _draw() -> void:
	# Nested ellipses with low alpha give a soft edge without a texture or shader.
	for i in 4:
		var t := 1.0 - float(i) * 0.22
		draw_circle(Vector2.ZERO, radius * (0.62 + 0.38 * t),
			Color(0.16, 0.09, 0.04, 0.085 * strength))
