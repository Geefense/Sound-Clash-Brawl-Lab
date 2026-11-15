extends Control
## Workshop HUD: health bars, P1 Crowd Hype bar and a beat pulse.
## UNAPPROVED. Drawn with primitives only — no theme, no art.

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService

const BAR_W := 320.0
const BAR_H := 18.0
const MARGIN := 24.0


func _draw() -> void:
	if p1 == null or p2 == null:
		return
	var width := size.x
	_bar(Vector2(MARGIN, MARGIN), BAR_W, p1.health, float(p1.max_health), Color(0.35, 0.85, 0.45), false)
	_bar(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, p2.health, float(p2.max_health), Color(0.9, 0.4, 0.4), true)
	_hype_bar(Vector2(MARGIN, MARGIN + BAR_H + 8.0))
	_beat_pulse(Vector2(width * 0.5, MARGIN + BAR_H * 0.5))
	_legend(Vector2(width * 0.5 - 210.0, MARGIN + 96.0))


func _bar(pos: Vector2, w: float, value: int, maximum: float, colour: Color, right_aligned: bool) -> void:
	var h := BAR_H
	var ratio := clampf(float(value) / maxf(maximum, 1.0), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var fill := Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0))
	if right_aligned:
		fill.position.x = pos.x + w - 2.0 - fill.size.x
	draw_rect(fill, colour, true)


func _hype_bar(pos: Vector2) -> void:
	var w := 180.0
	var h := 10.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var ratio := clampf(float(p1.hype) / float(BaseFighter.HYPE_MAX), 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0)),
		Color(0.95, 0.78, 0.25), true)
	draw_string(ThemeDB.fallback_font, pos + Vector2(w + 10.0, h),
		"HYPE %d" % p1.hype, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.85, 0.9))


func _beat_pulse(centre: Vector2) -> void:
	if beat == null:
		return
	var j := beat.judge()
	var on_beat := bool(j.get("on_beat", false))
	var colour := Color(0.35, 0.95, 0.5) if on_beat else Color(0.35, 0.4, 0.5)
	draw_circle(centre, 9.0 if on_beat else 6.0, colour)


func _legend(pos: Vector2) -> void:
	var keys := "J jab · K box · L tump · I upper box · T taunt · C crouch · R reset · G dummy guard · M mute"
	draw_string(ThemeDB.fallback_font, pos, keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(0.7, 0.72, 0.78))
