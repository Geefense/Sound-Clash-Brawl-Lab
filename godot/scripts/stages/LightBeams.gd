class_name LightBeams
extends Node2D
## Volumetric stage beams (AGENTS.md §9 item 41, 2026-11-20).
##
## Two or three soft cones sweeping down from the Sunset sky or the Night festival trusses,
## across the speaker stacks and the fighters. Presentation only: it reads no fighter state
## and never touches the simulation.
##
## WebGL2 safety: each beam is a stack of six flat quads with an alpha gradient (additive
## blend, no texture, no shader, no screen reads). That is 18 tiny polygons per frame — the
## same order of cost as the HUD's own bars — and nothing here allocates per frame.

@export var beam_count: int = 3
@export var strength: float = 0.0
## Seconds for one full sweep. Slow enough to read as drifting light, not a strobe.
@export var sweep_seconds: float = 13.0
@export var top_y: float = -90.0
@export var bottom_y: float = 700.0
## Vertical slices per beam: more slices, smoother fade, more draw calls.
@export var slices: int = 6

var _time: float = 0.0
var _sweep: float = 0.0
var _colour_a: Color = Color(1.0, 0.84, 0.46)
var _colour_b: Color = Color(1.0, 0.60, 0.26)


func _ready() -> void:
	z_index = 4                      # over the fighters (0), under BirdHazard (20)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	visible = strength > 0.01
	queue_redraw()


## Sunset: warm gold pair. Night: cyan + magenta (the truss rig), passed in by TestArena.
func set_palette(a: Color, b: Color) -> void:
	_colour_a = a
	_colour_b = b
	queue_redraw()


## 0 hides the node entirely, so an afternoon round pays nothing for it.
func set_intensity(value: float) -> void:
	strength = clampf(value, 0.0, 1.5)
	visible = strength > 0.01
	queue_redraw()


func _process(delta: float) -> void:
	if strength <= 0.01:
		return
	_time += delta
	_sweep = fposmod(_time / maxf(sweep_seconds, 0.5), 1.0)
	queue_redraw()


func _draw() -> void:
	if strength <= 0.01 or beam_count <= 0:
		return
	var count := maxi(slices, 1)
	for i in beam_count:
		var t := float(i) / float(maxi(beam_count, 1))
		# Each beam runs its own phase offset, so they never sweep as one block.
		var swing := sin((_sweep + t * 0.37) * TAU) * 0.5 + 0.5
		var source_x := 180.0 + t * 520.0 + swing * 80.0
		var target_x := source_x + (swing - 0.5) * 560.0
		var source_half := 15.0 + 9.0 * swing
		var target_half := 130.0 + 70.0 * (1.0 - swing)
		var colour := _colour_a if i % 2 == 0 else _colour_b
		for s in count:
			var t0 := float(s) / float(count)
			var t1 := float(s + 1) / float(count)
			var y0 := lerpf(top_y, bottom_y, t0)
			var y1 := lerpf(top_y, bottom_y, t1)
			var x0 := lerpf(source_x, target_x, t0)
			var x1 := lerpf(source_x, target_x, t1)
			var h0 := lerpf(source_half, target_half, t0)
			var h1 := lerpf(source_half, target_half, t1)
			# Alpha fades down the cone: bright at the source, gone where it meets the sand.
			var a0 := (0.20 * (1.0 - t0 * t0)) * strength
			var a1 := (0.20 * (1.0 - t1 * t1)) * strength
			if a1 <= 0.001:
				continue
			var pts := PackedVector2Array([
				Vector2(x0 - h0, y0),
				Vector2(x0 + h0, y0),
				Vector2(x1 + h1, y1),
				Vector2(x1 - h1, y1),
			])
			draw_colored_polygon(pts, Color(colour.r, colour.g, colour.b, (a0 + a1) * 0.5))
