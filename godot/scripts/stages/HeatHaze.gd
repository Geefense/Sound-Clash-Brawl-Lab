class_name HeatHaze
extends Node2D
## Midground heat haze and drifting dust motes over the sand (AGENTS.md §9 item 41, 2026-11-20).
##
## The Sunset yard shimmers: a dozen thin translucent streaks drift over the sand line, and a
## small CPUParticles2D cloud of soft golden motes rises through the midground. Presentation
## only — no simulation state is read.
##
## WebGL2 safety: the streaks are twelve `draw_line` calls; the motes are one 16-particle CPU
## emitter with a generated 32×32 radial gradient (no texture file, no shader, no thread).
## Here the whole scene's particle budget is 64, enforced by `TestArena._cap_particles()` and
## asserted by the headless check.

@export var band_top: float = 468.0
@export var band_bottom: float = 606.0
@export var streak_count: int = 11
## 0 = off (Afternoon), 1 = full shimmer (Sunset).
@export var intensity: float = 0.0
## Motes per emitter. Kept at 16 to match the arena-wide per-emitter ceiling.
@export var mote_amount: int = 16

var _time: float = 0.0
var _sunset: float = 0.0
var _night: float = 0.0
var _emitter: CPUParticles2D = null
var _mote_colour: Color = Color(1.0, 0.93, 0.74, 0.30)


func _ready() -> void:
	z_index = -5                      # behind the crowd line, over the stage art
	_build_motes()
	queue_redraw()


func _build_motes() -> void:
	_emitter = CPUParticles2D.new()
	_emitter.name = "DustMotes"
	_emitter.position = Vector2(640.0, 540.0)
	_emitter.amount = mote_amount
	_emitter.lifetime = 7.5
	_emitter.preprocess = 7.5
	_emitter.local_coords = false
	_emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_emitter.emission_rect_extents = Vector2(660.0, 68.0)
	_emitter.direction = Vector2(1.0, -0.3)
	_emitter.spread = 28.0
	_emitter.gravity = Vector2(8.0, -12.0)
	_emitter.initial_velocity_min = 5.0
	_emitter.initial_velocity_max = 20.0
	_emitter.scale_amount_min = 0.5
	_emitter.scale_amount_max = 1.4
	_emitter.color = _mote_colour
	_emitter.texture = _soft_dot()
	_emitter.emitting = intensity > 0.01
	add_child(_emitter)


## 32×32 radial gradient generated at runtime — one tiny texture, no export weight.
func _soft_dot() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	return tex


## `sunset` and `night` are the stage's 0–1 phase weights, so the haze runs gold at Sunset
## and cold blue-violet under the Night moon.
func set_phase(sunset: float, night: float) -> void:
	_sunset = clampf(sunset, 0.0, 1.0)
	_night = clampf(night, 0.0, 1.0)
	_mote_colour = Color(1.0, 0.93, 0.74, 0.30).lerp(Color(0.72, 0.88, 1.0, 0.26), _night)
	if _emitter != null:
		_emitter.color = _mote_colour
	queue_redraw()


func set_intensity(value: float) -> void:
	intensity = clampf(value, 0.0, 1.5)
	if _emitter != null:
		_emitter.emitting = intensity > 0.01
	queue_redraw()


func streaks() -> int:
	return streak_count


func motes() -> int:
	return mote_amount


func _process(delta: float) -> void:
	if intensity <= 0.01:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if intensity <= 0.01 or streak_count <= 0:
		return
	var warm := Color(1.0, 0.87, 0.58)
	var cool := Color(0.66, 0.86, 1.0)
	var pink := Color(1.0, 0.66, 0.84)
	var col := warm.lerp(pink, _sunset * 0.35).lerp(cool, _night * 0.7)
	for i in streak_count:
		var t := float(i) / float(maxi(streak_count, 1))
		var y := lerpf(band_top, band_bottom, t)
		# Each streak drifts on its own speed and phase, so the band breathes instead of
		# sliding as one sheet.
		var drift := sin(_time * (0.32 + t * 0.55) + t * 7.3) * 30.0
		var width := 64.0 + 104.0 * t
		var alpha := (0.11 - 0.055 * t) * intensity
		if alpha <= 0.004:
			continue
		draw_line(Vector2(110.0 + drift, y), Vector2(110.0 + drift + width, y - 2.5),
			Color(col.r, col.g, col.b, alpha), 6.0 - 3.2 * t)
