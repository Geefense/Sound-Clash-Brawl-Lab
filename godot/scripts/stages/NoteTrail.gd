class_name NoteTrail
extends Node2D
## Musical-note swing trail (AGENTS.md §9 item 41, 2026-11-20; §9 item 37 ambition).
##
## Vibrant, varied-size notes (♩ ♪ ♫ ♬ shapes) arc along a heavy strike instead of a generic
## slash line. Light jabs stay clean — the arena only spawns this for heavy attacks, on-beat
## contacts and counters, so a fast exchange is never buried in confetti.
##
## WebGL2 safety: four drawing calls per note, no texture font, no glyph atlas, no shader.
## The arena caps live trails at three, so a long brawl never accumulates nodes.

const DURATION: float = 0.52
const PALETTE := [
	Color(1.0, 0.84, 0.30),      # gold
	Color(0.35, 0.95, 1.0),      # cyan
	Color(1.0, 0.42, 0.85),      # magenta
	Color(0.55, 1.0, 0.55),      # green
	Color(1.0, 0.58, 0.28),      # orange
]

## Direction the strike travels (+1 right, −1 left), latched from the attacker's facing.
@export var facing: int = 1
## Heavy strikes throw more, larger notes; on-beat light hits throw a smaller pair.
@export var heavy: bool = true
@export var note_count: int = 5

var _life: float = 0.0
var _phase: float = 0.0


func _ready() -> void:
	z_index = 5                       # over the fighters, under the HUD CanvasLayer
	_phase = randf() * TAU
	queue_redraw()


func _process(delta: float) -> void:
	_life += delta
	queue_redraw()
	if _life >= DURATION:
		queue_free()


func _draw() -> void:
	var t := clampf(_life / DURATION, 0.0, 1.0)
	var fade := 1.0 - t
	if fade <= 0.01:
		return
	var f := float(facing)
	var count := maxi(note_count, 1)
	for i in count:
		# Every note follows the same arc on a small delay, so the trail reads as a swing
		# rather than a line of identical stickers.
		var lead := t * 1.65 - float(i) * 0.15
		if lead <= 0.0:
			continue
		var lt := clampf(lead, 0.0, 1.0)
		var arc := sin(lt * PI)
		var pos := Vector2(
			f * (16.0 + 118.0 * lt + float(i) * 9.0),
			-24.0 - arc * 56.0 - float(i) * 7.0)
		var size := (6.0 + float(i % 3) * 2.2) * (1.18 if heavy else 0.92)
		var col: Color = PALETTE[i % PALETTE.size()]
		col.a = clampf(fade * 1.35, 0.0, 1.0) * (0.92 if heavy else 0.78)
		_draw_note(pos, size, col, f * (0.18 + 0.12 * sin(_phase + float(i))))
		draw_circle(pos + Vector2(-f * 11.0, 9.0), maxf(1.2, size * 0.15),
			Color(col.r, col.g, col.b, col.a * 0.45))


## One note glyph. `variant` picks quarter / eighth / beamed-sixteenth so a trail mixes ♩ ♪ ♫.
func _draw_note(pos: Vector2, size: float, col: Color, tilt: float) -> void:
	var variant := int(round(size)) % 3
	# Oval head: a circle drawn under a non-uniform transform.
	draw_set_transform(pos, tilt, Vector2(1.0, 0.72))
	draw_circle(Vector2.ZERO, size * 0.55, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var stem_base := Vector2(size * 0.46, 0.0)
	var stem_top := Vector2(size * 0.46, -size * 2.3)
	draw_line(stem_base, stem_top, col, maxf(1.1, size * 0.17))
	if variant != 0:
		# Eighth-note flag.
		draw_line(stem_top, stem_top + Vector2(size * 0.88, size * 0.52), col,
			maxf(1.1, size * 0.15))
	if variant == 2:
		# Second flag: a beamed pair.
		draw_line(stem_top + Vector2(0.0, size * 0.62),
			stem_top + Vector2(size * 0.88, size * 1.14), col, maxf(1.0, size * 0.13))
