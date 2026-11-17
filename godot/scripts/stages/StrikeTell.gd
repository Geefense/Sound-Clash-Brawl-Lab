class_name StrikeTell
extends Node2D
## Strike smear over the attack's own hit volume (AGENTS.md §9 item 23).
##
## Why it exists: a roster fighter can ship with a single portrait (Lickshot), so his jab, BOX
## and kick played no pose at all — the CPU dealt damage out of a standing frame. The smear is
## drawn for exactly the volume `BaseFighter._hitbox_rect()` resolves contact with, so what the
## player sees and what lands are the same shape and the same moment. It is spawned by
## `TestArena` when a fighter enters `ATTACK_ACTIVE`, i.e. on the first active tick.
##
## Presentation only: no collision, no state, no damage. Primitives only, no texture — same
## house style as `ParrySpark`, under the same 4-effect cap in the arena.

const DURATION := 0.19          # a readable trail, longer than the 3–4 tick active window
const HEAVY_EXTRA := 7.0

## Direction the strike travels (+1 right, −1 left), latched from the attacker's facing.
@export var facing: int = 1
## Half-length of the volume plus a little overshoot, in world pixels.
@export var reach: float = 60.0
## Half-height of the volume; sets the arc's thickness.
@export var radius: float = 24.0
## BOX / kick get a wider, brighter smear than the jab.
@export var heavy: bool = false

var _life: float = 0.0


func _ready() -> void:
	z_index = 3                  # over the fighters (0), under the HUD CanvasLayer
	queue_redraw()


func _process(delta: float) -> void:
	_life += delta
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var t := clampf(_life / DURATION, 0.0, 1.0)
	var fade := 1.0 - t
	var f := float(facing)
	var core := Color(1.0, 0.97, 0.86)
	var warm := Color(1.0, 0.82, 0.42)
	var half := maxf(radius, 10.0)
	var tip := reach * (0.86 + 0.24 * t)        # the smear travels forward as it fades
	var tail := -half * 0.5

	# Tapered wedge: wide at the strike end, thin at the shoulder, so it reads as a swing.
	draw_colored_polygon(PackedVector2Array([
		Vector2(tail * f, -half * 0.22),
		Vector2(tip * f, -half),
		Vector2((tip + (HEAVY_EXTRA if heavy else 0.0)) * f, 0.0),
		Vector2(tip * f, half),
		Vector2(tail * f, half * 0.22),
	]), Color(core.r, core.g, core.b, fade * (0.34 if heavy else 0.26)))

	# Two arc edges give the swing an outline instead of a flat polygon.
	for s in [-1.0, 1.0]:
		var start := Vector2(tail * f, s * half * 0.22)
		var end := Vector2(tip * f, s * half)
		draw_line(start, end, Color(warm.r, warm.g, warm.b, fade * 0.85), 2.2 if heavy else 1.8)

	# Contact spark at the leading edge: the point the hitbox actually reaches.
	draw_circle(Vector2(tip * f, 0.0), (5.0 if heavy else 3.5) * (0.4 + fade * 0.6),
		Color(1.0, 1.0, 1.0, fade * 0.9))
