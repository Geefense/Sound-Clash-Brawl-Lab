extends Control
## Workshop HUD: health bars, P1 Crowd Hype bar, a beat pulse and the P2 AI mode banner.
## UNAPPROVED. Drawn with primitives only — no theme, no art.

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var sparring: SparringController
var rounds: RoundController

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
	_ai_banner(Vector2(width * 0.5 - 150.0, MARGIN + 40.0))
	_legend(Vector2(width * 0.5 - 210.0, MARGIN + 96.0))
	_round_pips(width)
	_surge_banner(Vector2(width * 0.5, size.y * 0.34))
	_round_banner(width)


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


## Active P2 sparring AI mode. Y cycles it; G stays a manual guard override in every mode.
func _ai_banner(pos: Vector2) -> void:
	if sparring == null:
		return
	var box := Rect2(pos, Vector2(300, 36))
	draw_rect(box, Color(0.08, 0.08, 0.1, 0.72), true)
	draw_rect(box, Color(0.55, 0.75, 0.95, 0.5), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(10, 16),
		"P2 AI %d · %s" % [sparring.mode_index(), sparring.mode_name()],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.95, 0.95, 1.0))
	draw_string(ThemeDB.fallback_font, pos + Vector2(10, 30),
		"%s · Y switch · G guard" % sparring.mode_tag(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.78, 0.9))


## Round-win pips: two per fighter, filled as rounds are taken.
func _round_pips(width: float) -> void:
	if rounds == null:
		return
	for side in 2:
		for i in rounds.rounds_to_win:
			var filled: bool = rounds.wins[side] > i
			var pos := Vector2(MARGIN + 10.0 + float(i) * 18.0, MARGIN + BAR_H + 30.0)
			if side == 1:
				pos.x = width - MARGIN - 10.0 - float(i) * 18.0
			draw_circle(pos, 5.0,
				Color(0.95, 0.78, 0.25) if filled else Color(0.24, 0.24, 0.3, 0.9))


## Round / K.O. / rematch banner published by the round controller.
func _round_banner(width: float) -> void:
	if rounds == null or rounds.banner == "" or rounds.banner_alpha <= 0.01:
		return
	var alpha: float = rounds.banner_alpha
	var y := size.y * 0.19
	var box := Rect2(Vector2(width * 0.5 - 330.0, y - 30.0), Vector2(660.0, 58.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.66 * alpha), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.75 * alpha), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(box.position.x + 30.0, y + 10.0), rounds.banner,
		HORIZONTAL_ALIGNMENT_CENTER, 600.0, 28, Color(1.0, 0.95, 0.84, alpha))


## 100% Crowd Hype Surge callout. Flashes while either fighter's surge boost is live.
func _surge_banner(centre: Vector2) -> void:
	var who := ""
	if p1 != null and p1.is_hype_surging():
		who = "P1"
	elif p2 != null and p2.is_hype_surging():
		who = "P2"
	if who == "":
		return
	var flash := int(Time.get_ticks_msec() / 140) % 2 == 0
	var box := Rect2(centre - Vector2(270.0, 48.0), Vector2(540.0, 96.0))
	draw_rect(box, Color(0.06, 0.04, 0.06, 0.72), true)
	draw_rect(box, Color(1.0, 0.82, 0.2, 0.9 if flash else 0.35), false, 3.0)
	var colour := Color(1.0, 0.92, 0.28) if flash else Color(1.0, 0.98, 0.86)
	draw_string(ThemeDB.fallback_font, centre + Vector2(-250.0, -4.0), "FORWARD!",
		HORIZONTAL_ALIGNMENT_CENTER, 500.0, 34, colour)
	draw_string(ThemeDB.fallback_font, centre + Vector2(-250.0, 34.0),
		"PULL UP! · %s 100%% HYPE" % who, HORIZONTAL_ALIGNMENT_CENTER, 500.0, 20,
		Color(1.0, 1.0, 1.0, 0.9))


func _legend(pos: Vector2) -> void:
	var keys := "J jab · K box · L tump · I upper box · U grab/tech · T taunt · C crouch · Y AI mode · B bird · N time of day · R reset · G dummy guard · M mute"
	draw_string(ThemeDB.fallback_font, pos, keys, HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
		Color(0.7, 0.72, 0.78))
