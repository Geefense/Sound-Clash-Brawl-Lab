class_name GroundShadow
extends Node2D
## Skewed, directional contact shadow under one body (AGENTS.md §9 elite stage polish,
## item 41 for the 2.5D pass).
##
## `top_level` keeps it in world space, so it stays glued to the sand while the fighter is
## airborne and shrinks/fades with jump height. Presentation only.
##
## The patch is a sheared ellipse stack, not a circle: a low sunset sun drags the far edge out
## along the sand (a real projected shadow leans away from the light), while the night
## floodlight keeps it short and soft. `light_dir` picks the side, `stretch` the length, and
## `density` the per-phase opacity. The geometry is rebuilt only when one of those changes, so
## a jumping body costs one transform update per frame and no new vertices.

@export var ground_y: float = 600.0
@export var radius: float = 32.0
@export var squash: float = 0.32
@export var jump_apex_height: float = 178.0
@export var air_shrink: float = 0.6
@export var air_fade: float = 0.35
## Belt-and-braces contrast knob (AGENTS.md §9 item 22): multiplies the shadow's opacity so
## the fighters can sit on a heavier grounded contact shadow without a second draw pass.
@export var strength: float = 1.0

## Time-of-day light (AGENTS.md §9 item 23 / item 41). `light_dir` is which way the shadow
## falls (+1 right, −1 left) and `stretch` is how far it is dragged out: a high afternoon sun
## gives a compact patch, a low sunset sun a long one, and the night floodlight a short soft one.
@export var light_dir: float = -1.0
@export var stretch: float = 1.0
## Per-phase opacity multiplier: a long low-sun shadow is also a thinner one.
@export var density: float = 1.0

var _lean: float = -999.0
var _cached_radius: float = -1.0
var _cached_stretch: float = -1.0
var _cached_density: float = -1.0


func _ready() -> void:
	top_level = true
	queue_redraw()


## Screen-space lean of the patch, in pixels of x per pixel of half-height. Exposed so the
## headless check can prove the skew follows the stage light instead of only the offset.
func shadow_lean() -> float:
	return _target_lean()


func _target_lean() -> float:
	# stretch 1.0 (overhead) → 0; 1.95 (low sunset) → ~1.28 px of lean per px of height.
	return light_dir * clampf((maxf(stretch, 0.4) - 1.0) * 1.35, -0.35, 1.6)


func _process(_delta: float) -> void:
	var fighter := get_parent() as Node2D
	if fighter == null:
		return
	var air := clampf((ground_y - fighter.global_position.y) / maxf(jump_apex_height, 1.0), 0.0, 1.0)
	var cast := maxf(stretch, 0.4)
	# A long shadow leans away from the light instead of only widening under the body.
	global_position = Vector2(
		fighter.global_position.x + light_dir * radius * (cast - 1.0) * 0.55, ground_y)
	var shrink := lerpf(1.0, air_shrink, air)
	scale = Vector2(shrink, shrink)
	modulate.a = lerpf(1.0, air_fade, air)

	# Rebuild the sheared geometry only when the light actually changes: the per-frame path
	# stays a position/scale write.
	var want := _target_lean()
	if not is_equal_approx(want, _lean) or not is_equal_approx(radius, _cached_radius) \
			or not is_equal_approx(cast, _cached_stretch) or not is_equal_approx(density, _cached_density):
		_lean = want
		_cached_radius = radius
		_cached_stretch = cast
		_cached_density = density
		queue_redraw()


func _draw() -> void:
	var cast := maxf(stretch, 0.4)
	var lean := _target_lean()
	# Nested sheared ellipses with low alpha give a soft edge without a texture or shader.
	for i in 4:
		var t := 1.0 - float(i) * 0.22
		var r := radius * (0.62 + 0.38 * t)
		var rx := r * cast
		var ry := maxf(r * squash, 0.5)
		var steps := 18
		var pts := PackedVector2Array()
		for s in steps:
			var ang := TAU * float(s) / float(steps)
			var x := cos(ang) * rx
			var y := sin(ang) * ry
			# Shear x by height: the far edge drags out along the sand.
			pts.append(Vector2(x + lean * y, y))
		draw_colored_polygon(pts, Color(0.16, 0.09, 0.04,
			0.085 * strength * clampf(density, 0.0, 1.5)))
