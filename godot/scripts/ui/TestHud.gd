extends Control
## Workshop HUD: health bars, P1 Crowd Hype bar, a beat pulse, the P2 AI mode banner,
## round banners, and the deadpan Patois subtitle pill.
## UNAPPROVED. Primitives plus the Bungee / Chakra Petch OFL fonts (AGENTS.md §9 item 19).

var p1: BaseFighter
var p2: BaseFighter
var beat: BeatService
var sparring: SparringController
var rounds: RoundController

const BAR_W := 320.0
const BAR_H := 18.0
const MARGIN := 24.0

# Bungee family (SIL OFL) + Chakra Petch Bold for the deadpan subtitles.
const FONT_BUNGEE := preload("res://assets/fonts/Bungee-Regular.ttf")
const FONT_INLINE := preload("res://assets/fonts/BungeeInline-Regular.ttf")
const FONT_SHADE := preload("res://assets/fonts/BungeeShade-Regular.ttf")
const FONT_SUB := preload("res://assets/fonts/ChakraPetch-Bold.ttf")

# Subtitle pill (AGENTS.md §9 item 19): one line at a time, 4 s cooldown, 1.8 s fade.
const SUBTITLE_SECONDS := 1.8
const SUBTITLE_COOLDOWN_SECONDS := 4.0
const SUBTITLE_Y := 655.0
const SUBTITLE_FADE := 0.45

var subtitles_enabled: bool = true

var _sub: String = ""              # Patois shout
var _sub_translation: String = ""  # deadpan English
var _sub_life: float = 0.0
var _sub_cooldown: float = 0.0


func _process(delta: float) -> void:
	if _sub_life > 0.0:
		_sub_life = maxf(0.0, _sub_life - delta)
		if _sub_life == 0.0:
			_sub = ""
			_sub_translation = ""
	_sub_cooldown = maxf(0.0, _sub_cooldown - delta)


# =========================================================================
# Subtitle API (TestArena triggers these)
# =========================================================================
## A big-moment callout. Returns false (and shows nothing) while the cooldown runs or
## while subtitles are off, so a burst of triggers can never stack pills.
func announce_subtitle(patois: String, translation: String) -> bool:
	if not subtitles_enabled or _sub_cooldown > 0.0:
		return false
	_sub = patois
	_sub_translation = translation
	_sub_life = SUBTITLE_SECONDS
	_sub_cooldown = SUBTITLE_COOLDOWN_SECONDS
	queue_redraw()
	return true


## V toggle. Turning subtitles off clears the pill immediately.
func toggle_subtitles() -> bool:
	subtitles_enabled = not subtitles_enabled
	if not subtitles_enabled:
		_sub = ""
		_sub_translation = ""
		_sub_life = 0.0
	return subtitles_enabled


func has_subtitle() -> bool:
	return _sub_life > 0.0


func subtitle_text() -> String:
	return _sub


func subtitle_cooldown_left() -> float:
	return _sub_cooldown


# =========================================================================
# Draw
# =========================================================================
func _draw() -> void:
	if p1 == null or p2 == null:
		return
	var width := size.x
	_bar(Vector2(MARGIN, MARGIN), BAR_W, p1.health, float(p1.max_health), Color(0.35, 0.85, 0.45), false)
	_bar(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, p2.health, float(p2.max_health), Color(0.9, 0.4, 0.4), true)
	_fighter_name(Vector2(MARGIN, MARGIN), BAR_W, "P1", false)
	_fighter_name(Vector2(width - MARGIN - BAR_W, MARGIN), BAR_W, "P2", true)
	_hype_bar(Vector2(MARGIN, MARGIN + BAR_H + 8.0))
	_beat_pulse(Vector2(width * 0.5, MARGIN + BAR_H * 0.5))
	_ai_banner(Vector2(width * 0.5 - 150.0, MARGIN + 40.0))
	_legend(Vector2(width * 0.5 - 210.0, MARGIN + 96.0))
	_round_pips(width)
	_surge_banner(Vector2(width * 0.5, size.y * 0.34))
	_round_banner(width)
	_subtitle_pill(width)


## Every label draws a drop shadow, a dark outline and then the crisp face, so the
## typography stays readable over sky, sand and the night tint.
func _text(pos: Vector2, text: String, font: Font, font_size: int, colour: Color,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	if text == "":
		return
	var outline := maxi(2, int(round(float(font_size) * 0.16)))
	draw_string(font, pos + Vector2(2.0, 3.0), text, align, width, font_size,
		Color(0.0, 0.0, 0.0, 0.45 * colour.a))
	draw_string_outline(font, pos, text, align, width, font_size, outline,
		Color(0.03, 0.02, 0.05, 0.9 * colour.a))
	draw_string(font, pos, text, align, width, font_size, colour)


## Shrink the size until the string fits the box (Bungee is a very wide face).
func _fit_size(font: Font, text: String, preferred: int, max_width: float) -> int:
	var size := preferred
	while size > 9:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
		size -= 1
	return size


func _bar(pos: Vector2, w: float, value: int, maximum: float, colour: Color, right_aligned: bool) -> void:
	var h := BAR_H
	var ratio := clampf(float(value) / maxf(maximum, 1.0), 0.0, 1.0)
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var fill := Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0))
	if right_aligned:
		fill.position.x = pos.x + w - 2.0 - fill.size.x
	draw_rect(fill, colour, true)


## Bungee fighter tag inside the health bar (above it clips the viewport edge).
func _fighter_name(bar_pos: Vector2, bar_w: float, name: String, right_aligned: bool) -> void:
	var w := 70.0
	var x := bar_pos.x + bar_w - w - 8.0 if right_aligned else bar_pos.x + 8.0
	_text(Vector2(x, bar_pos.y + BAR_H - 5.0), name, FONT_BUNGEE, 13,
		Color(1.0, 0.99, 0.94, 0.95),
		HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT, w)


func _hype_bar(pos: Vector2) -> void:
	var w := 180.0
	var h := 10.0
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.08, 0.08, 0.1, 0.85), true)
	var ratio := clampf(float(p1.hype) / float(BaseFighter.HYPE_MAX), 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2((w - 4.0) * ratio, h - 4.0)),
		Color(0.95, 0.78, 0.25), true)
	_text(pos + Vector2(w + 10.0, h), "HYPE %d" % p1.hype, FONT_SUB, 12,
		Color(0.85, 0.85, 0.9))


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
	var box := Rect2(pos, Vector2(300, 38))
	draw_rect(box, Color(0.08, 0.08, 0.1, 0.72), true)
	draw_rect(box, Color(0.55, 0.75, 0.95, 0.5), false, 1.0)
	var title := "P2 AI %d · %s" % [sparring.mode_index(), sparring.mode_name()]
	_text(pos + Vector2(10, 16), title, FONT_SUB,
		_fit_size(FONT_SUB, title, 13, 280.0), Color(0.95, 0.95, 1.0))
	_text(pos + Vector2(10, 31), "%s · Y switch · G guard" % sparring.mode_tag(), FONT_SUB, 11,
		Color(0.7, 0.78, 0.9))


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


## Round / K.O. / rematch banner published by the round controller. The face carries the
## weight of the moment: Shade for the K.O., Inline for the rematch, Bungee otherwise.
func _round_banner(width: float) -> void:
	if rounds == null or rounds.banner == "" or rounds.banner_alpha <= 0.01:
		return
	var alpha: float = rounds.banner_alpha
	var text: String = rounds.banner
	var font: Font = FONT_BUNGEE
	var preferred := 26
	var max_width := 640.0
	if text.begins_with("K.O."):
		font = FONT_SHADE
		preferred = 64
		max_width = 420.0
	elif text.begins_with("WHEEL AND COME AGAIN"):
		font = FONT_INLINE
		preferred = 34
		max_width = 900.0
	var font_size := _fit_size(font, text, preferred, max_width)
	var box_w := clampf(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		+ 76.0, 320.0, width - 2.0 * MARGIN)
	var y := size.y * 0.19
	var box := Rect2(Vector2(width * 0.5 - box_w * 0.5, y - 34.0),
		Vector2(box_w, 66.0 if text.begins_with("K.O.") else 58.0))
	draw_rect(box, Color(0.05, 0.04, 0.07, 0.66 * alpha), true)
	draw_rect(box, Color(1.0, 0.86, 0.32, 0.75 * alpha), false, 2.0)
	_text(Vector2(box.position.x, box.position.y + box.size.y * 0.5 + font_size * 0.36), text,
		font, font_size, Color(1.0, 0.95, 0.84, alpha), HORIZONTAL_ALIGNMENT_CENTER, box_w)


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
	_text(centre + Vector2(-250.0, -4.0), "FORWARD!", FONT_INLINE,
		_fit_size(FONT_INLINE, "FORWARD!", 34, 500.0), colour, HORIZONTAL_ALIGNMENT_CENTER, 500.0)
	_text(centre + Vector2(-250.0, 34.0), "PULL UP! · %s 100%% HYPE" % who, FONT_SUB, 20,
		Color(1.0, 1.0, 1.0, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 500.0)


## Patois shout + deadpan translation in a compact translucent pill, under the sand lane.
func _subtitle_pill(width: float) -> void:
	if not subtitles_enabled or _sub == "" or _sub_life <= 0.0:
		return
	var fade := clampf(_sub_life / SUBTITLE_FADE, 0.0, 1.0)
	var shout_size := _fit_size(FONT_BUNGEE, _sub, 19, width - 140.0)
	var sub_size := 12
	var shout_w := FONT_BUNGEE.get_string_size(_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, shout_size).x
	var trans_w := FONT_SUB.get_string_size(_sub_translation, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size).x
	var pill_w := clampf(maxf(shout_w, trans_w) + 44.0, 240.0, width - 2.0 * MARGIN)
	var h := 50.0
	var origin := Vector2(width * 0.5 - pill_w * 0.5, SUBTITLE_Y - h * 0.5)
	var bg := Color(0.04, 0.03, 0.06, 0.72 * fade)
	draw_rect(Rect2(origin, Vector2(pill_w, h)), bg, true)
	draw_circle(origin + Vector2(0.0, h * 0.5), h * 0.5, bg)
	draw_circle(origin + Vector2(pill_w, h * 0.5), h * 0.5, bg)
	draw_rect(Rect2(origin + Vector2(0.0, -1.0), Vector2(pill_w, 2.0)),
		Color(1.0, 0.86, 0.32, 0.5 * fade), true)
	_text(Vector2(origin.x, origin.y + 22.0), _sub, FONT_BUNGEE, shout_size,
		Color(1.0, 0.96, 0.85, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)
	_text(Vector2(origin.x, origin.y + 41.0), _sub_translation, FONT_SUB, sub_size,
		Color(0.78, 0.82, 0.9, fade), HORIZONTAL_ALIGNMENT_CENTER, pill_w)


func _legend(pos: Vector2) -> void:
	var keys := "J jab · K box · L tump · I upper box · U grab/tech · T taunt · C crouch · Y AI mode · B bird · N time of day · V subtitles · R reset · G dummy guard · M mute"
	_text(pos, keys, FONT_SUB, _fit_size(FONT_SUB, keys, 12, size.x - 2.0 * MARGIN),
		Color(0.72, 0.75, 0.82))
